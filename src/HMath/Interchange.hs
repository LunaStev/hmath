-- SPDX-License-Identifier: MPL-2.0

{- | Checked fixed-width numerical serialization and array exchange. The
binary/text/NumPy formats are independently versioned from HMath's package
version. Binary/raw formats preserve IEEE bit patterns; text preserves
numerical values and signed zero, but not NaN payloads. Foreign objects and
arbitrary code/pickles are never deserialized. DLPack uses the native C API
declared in @hmath_dlpack.h@; optional HDF5/Arrow/ONNX conversion is provided
by the explicitly selected @tools/interchange_adapters.py@ adapters.
-}
module HMath.Interchange (
    module HMath.Interchange.Array,
    module HMath.Interchange.Binary,
    module HMath.Interchange.Text,
    module HMath.Interchange.Numpy,
    module HMath.Interchange.Compression,
    module HMath.Interchange.IO,
) where

import HMath.Interchange.Array hiding (boundedInt, byteOffsets, checkLimits, guardI)
import HMath.Interchange.Binary hiding (runDecoder)
import HMath.Interchange.Compression
import HMath.Interchange.IO
import HMath.Interchange.Numpy
import HMath.Interchange.Text
