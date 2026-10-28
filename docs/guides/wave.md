# Integrate with Wave

The maintained Wave binding is `bindings/wave/hmath.wave`. It calls the same
C ABI used by Python. Build the native library first using the
[source-build guide](build.md).

The compiler tested by CI is Wave `v0.2.1-pre-beta`. With `wavec` on `PATH`,
run the checked-in integration client:

```sh
python tools/run_wave.py --library builddir/libhmath.so
```

The client exercises scalar addition, vector and matrix construction,
arbitrary-rank tensors, matrix multiplication, errors, cloning, and cleanup.

## A scalar call

From a Wave source file placed beside `bindings/wave/hmath.wave`:

```wave
import("./hmath")::{scalar_add};

fun main() -> i32 {
    var result: f64 = 0.0;
    if (scalar_add(2.0, 3.0, &result) != 0 || result != 5.0) {
        return 1;
    }
    return 0;
}
```

To integrate your application, copy the binding beside your source or adjust
its import path, and link `hmath` from the native build directory. The
checked-in `tools/run_wave.py` shows the tested compiler and linker flags.

Wave does not provide Python's automatic tensor cleanup. Call `tensor_close`
on every owned tensor, including error paths. See the
[Wave API reference](../reference/wave.md).
