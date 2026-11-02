# SPDX-License-Identifier: MPL-2.0
"""Generate original Signal, Fourier and Interpolation structured adapters."""

import argparse
import json
from pathlib import Path

import generate_numerical_bindings as engine

ROOT = Path(__file__).resolve().parent.parent
TYPES = {
    "Filter": ("signal", "S.Filter", 360, ["filterCoefficients", "filterState"]),
    "FilterFamily": ("signal", "S.FilterFamily", 361, []),
    "FilterBand": ("signal", "S.FilterBand", 362, []),
    "Window": ("signal", "S.Window", 363, []),
    "Peak": (
        "signal",
        "S.Peak",
        364,
        ["peakIndex", "peakHeight", "peakProminence", "peakWidth"],
    ),
    "Wavelet": ("signal", "S.Wavelet", 365, []),
    "WaveletTree": (
        "signal",
        "S.WaveletTree",
        366,
        ["waveletApproximation", "waveletDetails"],
    ),
    "MotherWavelet": ("signal", "S.MotherWavelet", 367, []),
    "WaveletPacket": ("signal", "S.WaveletPacket", 368, ["packetBands"]),
    "Extrapolation": ("interpolation", "I.Extrapolation", 369, []),
    "InterpolationMethod": ("interpolation", "I.InterpolationMethod", 370, []),
    "SplineBoundary": ("interpolation", "I.SplineBoundary", 371, []),
    "PiecewisePolynomial": (
        "interpolation",
        "I.PiecewisePolynomial",
        372,
        ["piecewiseKnots"],
    ),
    "BSpline": ("interpolation", "I.BSpline", 373, []),
    "RadialKernel": ("interpolation", "I.RadialKernel", 374, []),
    "RBF": ("interpolation", "I.RBF", 375, []),
    "Approximation": (
        "interpolation",
        "I.Approximation",
        376,
        ["approximationCoefficients", "approximationError", "approximationIterations"],
    ),
    "Direction": ("fourier", "F.Direction", 377, []),
    "FFTAlgorithm": ("fourier", "F.FFTAlgorithm", 378, []),
    "FFTPlan": ("fourier", "F.FFTPlan", 379, []),
    "TransformType": ("fourier", "F.TransformType", 380, []),
    "STFT": ("fourier", "F.STFT", 381, ["stftFrames"]),
}


def generate():
    entries = json.loads(
        (ROOT / "bindings/schema/spectral-functions.json").read_text()
    )["functions"]
    original_types, original_modules = engine.TYPES, engine.MODULES
    try:
        engine.TYPES = TYPES
        engine.MODULES = {"signal": "S", "interpolation": "I", "fourier": "F"}
        outputs = engine.generate(
            [e for e in entries if e["name"] != "fftInPlace"], aliases=False
        )
    finally:
        engine.TYPES, engine.MODULES = original_types, original_modules
    result = {}
    for name, text in outputs.items():
        for namespace in ("signal", "interpolation", "fourier"):
            text = text.replace(
                "hmath_" + namespace + "_", "hmath_" + namespace + "_value_"
            )
        text = text.replace(
            "generate_numerical_bindings.py", "generate_spectral_bindings.py"
        )
        text = text.replace("HMATH_NUMERICAL_H", "HMATH_SPECTRAL_H").replace(
            "hmath_numerical.h", "hmath_spectral.h"
        )
        text = text.replace("hm_numerical_apply", "hm_spectral_apply")
        text = text.replace(
            "HMath.FFI.NumericalAll where", "HMath.FFI.SpectralAll where"
        )
        if name.endswith("NumericalAll.hs"):
            text = text.replace(
                "import qualified HMath.Calculus as C\nimport qualified HMath.Root as R\nimport qualified HMath.ODE as O\nimport qualified HMath.PDE as P\n",
                "import qualified HMath.Signal as S\nimport qualified HMath.Interpolation as I\nimport qualified HMath.Fourier as F\nimport HMath.FFI.NumericalAll ()\nimport Data.Complex (Complex)\n",
            )
            text = text.replace(
                "apply F.fftShift values",
                "apply (F.fftShift :: [V.Value] -> [V.Value]) values",
            )
            text = text.replace(
                "apply F.ifftShift values",
                "apply (F.ifftShift :: [V.Value] -> [V.Value]) values",
            )
            text += "\ninstance From S.GaussianState where from = unbox 140\ninstance To S.GaussianState where\n    to value = pure (box 140 value [to (S.stateMean value),to (S.stateCovariance value)])\n"
            text += '\nforeign export ccall "hm_spectral_fft_in_place" rawFFT :: StablePtr V.Value -> Ptr (Complex Double) -> CPtrdiff -> IO CInt\nrawFFT :: StablePtr V.Value -> Ptr (Complex Double) -> CPtrdiff -> IO CInt\nrawFFT input pointer count = B.boundary $ do\n    plan <- deRefStablePtr input >>= from\n    outcome <- F.fftInPlace plan pointer (fromIntegral count)\n    B.checked outcome (const (pure ()))\n'
            text += '\nforeign export ccall "hm_spectral_describe" describe :: StablePtr V.Value -> Ptr (StablePtr V.Value) -> IO CInt\ndescribe :: StablePtr V.Value -> Ptr (StablePtr V.Value) -> IO CInt\ndescribe input out = B.boundary $ do\n    value <- deRefStablePtr input\n    rendered <- case value of\n'
            for _ns, typ, tag, _fields in TYPES.values():
                text += f"        V.Opaque {tag} _ _ _ _ -> show <$> (from value :: IO {typ})\n"
            text += '        V.Opaque 140 _ _ _ _ -> show <$> (from value :: IO S.GaussianState)\n        _ -> V.invalid "expected a spectral-domain object"\n    B.checked (Right ()) (const (V.publish (V.Text rendered) out))\n'
        if name.endswith("numerical.c"):
            text += '\nextern int hm_spectral_fft_in_place(void *,void *,ptrdiff_t);\nhmath_status hmath_fourier_value_fft_in_place(hmath_context *context,const hmath_value *plan,double *interleaved,ptrdiff_t count) {\n    if (!plan) return hm_error(HMATH_INVALID_ARGUMENT,"NULL FFT plan");\n    hmath_status status=hm_enter(context);\n    if(status)return status;\n    int code=hm_spectral_fft_in_place(hm_value_stable(plan),interleaved,count);\n    hm_leave();\n    return (hmath_status)code;\n}\n'
            text += '\nextern int hm_spectral_describe(void *,void **);\nhmath_status hmath_spectral_describe(hmath_context *context,const hmath_value *value,hmath_value **out) {\n    if (!value || !out) return hm_error(HMATH_INVALID_ARGUMENT,"NULL spectral description argument");\n    hmath_value *temporary=NULL;\n    hmath_status status=hm_value_begin(context,&temporary);\n    if(status)return status;\n    return hm_value_finish(temporary,hm_spectral_describe(hm_value_stable(value),&temporary->stable),out);\n}\n'
        if name.endswith("hmath_numerical.h"):
            marker = "#ifdef __cplusplus\n}\n#endif\n#endif\n"
            addition = "/* Original fftInPlace: borrowed writable interleaved real/imaginary Double\n * storage for count complex values, aligned for Double. The original checks\n * NULL/count/finite values and changes storage only after successful execution.\n * No wrapper copy; caller keeps storage alive and excludes concurrent writers. */\nHMATH_API hmath_status hmath_fourier_value_fft_in_place(hmath_context *context,const hmath_value *plan,double *interleaved,ptrdiff_t count);\n"
            addition += "/* Original Show representation as an owned codepoint String value. */\nHMATH_API hmath_status hmath_spectral_describe(hmath_context *context,const hmath_value *value,hmath_value **out);\n"
            text = text.replace(marker, addition + marker)
        if name.endswith("fourier.py"):
            for operation in ("fft_shift", "ifft_shift"):
                text = text.replace(
                    "def " + operation + "(xs):",
                    "def "
                    + operation
                    + '(xs, *, dtype=None):\n    if dtype not in (None, "float64"):\n        raise ValueError("legacy dtype must be float64; generic elements retain their own types")',
                )
            text += "\n\nfrom ._spectral_base import fft_in_place as fft_in_place\n"
        if name.endswith("signal.py"):
            text += "\n\nfrom .timeseries import GaussianState as GaussianState, gaussian_state as gaussian_state, state_mean as state_mean, state_covariance as state_covariance\n"
        if name.endswith(("signal.py", "fourier.py", "interpolation.py")):
            text += '\n\ndef describe(value):\n    """Return the original Haskell Show representation of a spectral object."""\n    return _invoke("hmath_spectral_describe", [["Value"]], [value])\n'
        target = (
            name.replace("hmath_numerical.h", "hmath_spectral.h")
            .replace("cbits/numerical.c", "cbits/spectral.c")
            .replace("FFI/NumericalAll.hs", "FFI/SpectralAll.hs")
            .replace("numerical-objects.json", "spectral-objects.json")
            .replace("numerical-solvers.md", "spectral-bindings.md")
        )
        for namespace in ("signal", "interpolation", "fourier"):
            target = target.replace(
                "/" + namespace + ".py", "/" + namespace + "_values.py"
            )
        result[target] = text
    schema = json.loads(result["bindings/schema/spectral-objects.json"])
    generic_symbols = {"HMath.Fourier.fftShift", "HMath.Fourier.ifftShift"}
    generic = [item for item in schema["bindings"] if item["symbol"] in generic_symbols]
    schema["bindings"] = [
        item for item in schema["bindings"] if item["symbol"] not in generic_symbols
    ]
    result["bindings/schema/spectral-generic-objects.json"] = (
        json.dumps(
            {"schema": 1, "extends": "numeric.json", "bindings": generic}, indent=2
        )
        + "\n"
    )
    schema["bindings"].append(
        {
            "symbol": "HMath.Fourier.fftInPlace",
            "c": ["hmath_fourier_value_fft_in_place"],
            "python": "hmath.fourier.fft_in_place",
            "specializations": [
                "original in-place binary64 complex buffer with borrowed lifetime"
            ],
        }
    )
    result["bindings/schema/spectral-objects.json"] = (
        json.dumps(schema, indent=2) + "\n"
    )
    docs = result["docs/reference/spectral-bindings.md"]
    docs = (
        "# Signal, Fourier and interpolation bindings\n\nPython uses `hmath.signal`, `hmath.fourier` and `hmath.interpolation`. C includes `hmath_spectral.h` and uses immutable owned [structured values](values.md). Existing scalar entry points remain available. Every operation calls the original implementation.\n\nForward Fourier exponents are negative; inverse transforms divide by N. DCT/DST retain the original orthonormal type I–IV definitions. Plans retain the original bounded reference algorithms and are reusable immutable objects. They do not substitute a different transform provider.\n\nInterpolation preserves strictly increasing unique finite samples, exact extrapolation choices and ascending local polynomial coefficients. Error values remain the source's sampled estimates. Signal filters preserve state continuation, window definitions, boundary conventions, Kalman updates and wavelet coefficient ordering. Source work/shape/iteration limits remain in force.\n\nInputs are borrowed for a synchronous call and successful C outputs own one reference. Output pointers remain untouched on failure. Immutable objects support concurrent readers retaining references and using independent output addresses. Function arguments use kind101 callbacks from `hmath_linear_callback`, with a tuple of flattened positional arguments. Python accepts ordinary callables and retains their owners; exceptions are re-raised after native cleanup. Source MathError returns status11 with a lossless payload. Cancellation is checked before entry.\n\n"
        + docs[docs.index("## ") :]
    )
    docs += "## `fourier.fft_in_place`\n\n`fourier.fft_in_place(plan, buffer)` mutates a writable, one-dimensional, native-endian, C-contiguous NumPy `complex128` array using the original `fftInPlace`. The wrapper borrows its storage; the original routine stages and validates input before writing the result. Keep the buffer alive and exclude concurrent access during the call. Invalid lengths and nonfinite input follow the original MathError contract; storage is unchanged on failure. C takes a borrowed `double *` with interleaved real/imaginary components and a signed `ptrdiff_t` complex-element count.\n\n```c\nhmath_status hmath_fourier_value_fft_in_place(hmath_context *context, const hmath_value *plan, double *interleaved, ptrdiff_t count);\n```\n"
    docs += "\n## `describe`\n\n`signal.describe(value)`, `fourier.describe(value)` and `interpolation.describe(value)` return the original Haskell Show representation of a domain object. C uses `hmath_spectral_describe(context, value, out)` and receives an owned String value.\n"
    result["docs/reference/spectral-bindings.md"] = docs
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for name, content in generate().items():
        path = ROOT / name
        if args.check:
            if not path.exists() or path.read_text() != content:
                parser.exit(1, "Stale spectral binding: " + name + "\n")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)


if __name__ == "__main__":
    main()
