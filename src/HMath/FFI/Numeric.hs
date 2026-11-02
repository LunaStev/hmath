{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated; do not edit.
module HMath.FFI.Numeric where
import Control.Exception (bracketOnError, evaluate)
import Data.Coerce (coerce)
import Data.Complex (Complex ((:+)), realPart, imagPart)
import Data.Ratio (numerator, denominator, (%))
import Foreign
import Foreign.C
import HMath.FFI.Boundary
import qualified HMath.API.Algebra as APIAlgebra
import qualified HMath.Algorithms as Algorithms
import qualified HMath.Basic as Basic
import qualified HMath.Combinatorics as Combinatorics
import qualified HMath.Complex as Complex
import qualified HMath.Constants as Constants
import qualified HMath.DataStructure as DataStructure
import qualified HMath.DeepLearning.Core as DeepLearningCore
import qualified HMath.DeepLearning.Metrics as DeepLearningMetrics
import qualified HMath.DeepLearning.Precision as DeepLearningPrecision
import qualified HMath.Discrete as Discrete
import qualified HMath.Fourier as Fourier
import qualified HMath.Geometry.Primitives as GeometryPrimitives
import qualified HMath.Graph.Core as GraphCore
import qualified HMath.Image.Color as ImageColor
import qualified HMath.Interpolation as Interpolation
import qualified HMath.Linear as Linear
import qualified HMath.NumberTheory as NumberTheory
import qualified HMath.Numeric as Numeric
import qualified HMath.Optimization.Common as OptimizationCommon
import qualified HMath.Probability as Probability
import qualified HMath.Random as Random
import qualified HMath.Scalar as Scalar
import qualified HMath.Signal as Signal
import qualified HMath.Special as Special
import qualified HMath.Statistics as Statistics
import qualified HMath.Statistics.Advanced as StatisticsAdvanced
import qualified HMath.Tensor as Tensor
import qualified HMath.TimeSeries.Core as TimeSeriesCore
import qualified HMath.TimeSeries.Diagnostics as TimeSeriesDiagnostics
import qualified HMath.Trigonometry as Trigonometry
import qualified HMath.Units as Units

complexPairs :: [a] -> [Complex a]
complexPairs [] = []
complexPairs (a : b : rest) = (a :+ b) : complexPairs rest
complexPairs _ = error "invalid complex transport"

rationalPairs :: [Integer] -> [Rational]
rationalPairs [] = []
rationalPairs (a : b : rest) = (a % b) : rationalPairs rest
rationalPairs _ = error "invalid Rational transport"

foreign export ccall "hm_numeric_basic_factorial" ffiBasicFactorial :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiBasicFactorial :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiBasicFactorial vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (Right (Basic.factorial
        vNValue)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_basic_fibonacci" ffiBasicFibonacci :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiBasicFibonacci :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiBasicFibonacci vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (Right (Basic.fibonacci
        vNValue)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_basic_is_prime" ffiBasicIsPrime :: 
    CString ->
    Ptr CInt ->
    IO CInt
ffiBasicIsPrime :: 
    CString ->
    Ptr CInt ->
    IO CInt
ffiBasicIsPrime vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (Right (Basic.isPrime
        vNValue)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (if strict0 then 1 else 0)

foreign export ccall "hm_numeric_basic_clamp_f32" ffiBasicClampF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiBasicClampF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiBasicClampF32 vLow vHigh vValue out0 = boundary $ do
    checked (Right (Basic.clamp
        (coerce vLow :: Float)
        (coerce vHigh :: Float)
        (coerce vValue :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_basic_clamp_f64" ffiBasicClampF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiBasicClampF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiBasicClampF64 vLow vHigh vValue out0 = boundary $ do
    checked (Right (Basic.clamp
        (coerce vLow :: Double)
        (coerce vHigh :: Double)
        (coerce vValue :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_basic_clamp_rational" ffiBasicClampRational :: 
    CString ->
    CString ->
    CString ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiBasicClampRational :: 
    CString ->
    CString ->
    CString ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiBasicClampRational vLowNumerator vLowDenominator vHighNumerator vHighDenominator vValueNumerator vValueDenominator out0 out1 = boundary $ do
    vLowN <- readInteger vLowNumerator
    vLowD <- readInteger vLowDenominator
    vHighN <- readInteger vHighNumerator
    vHighD <- readInteger vHighDenominator
    vValueN <- readInteger vValueNumerator
    vValueD <- readInteger vValueDenominator
    checked (Right (Basic.clamp
        (vLowN % vLowD)
        (vHighN % vHighD)
        (vValueN % vValueD))) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_basic_clamp_integer" ffiBasicClampInteger :: 
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiBasicClampInteger :: 
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiBasicClampInteger vLow vHigh vValue out0 = boundary $ do
    vLowValue <- readInteger vLow
    vHighValue <- readInteger vHigh
    vValueValue <- readInteger vValue
    checked (Right (Basic.clamp
        vLowValue
        vHighValue
        vValueValue)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_basic_clamp_i8" ffiBasicClampI8 :: 
    Int8 ->
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiBasicClampI8 :: 
    Int8 ->
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiBasicClampI8 vLow vHigh vValue out0 = boundary $ do
    checked (Right (Basic.clamp
        (vLow :: Int8)
        (vHigh :: Int8)
        (vValue :: Int8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_basic_clamp_i16" ffiBasicClampI16 :: 
    Int16 ->
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiBasicClampI16 :: 
    Int16 ->
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiBasicClampI16 vLow vHigh vValue out0 = boundary $ do
    checked (Right (Basic.clamp
        (vLow :: Int16)
        (vHigh :: Int16)
        (vValue :: Int16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_basic_clamp_i32" ffiBasicClampI32 :: 
    Int32 ->
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiBasicClampI32 :: 
    Int32 ->
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiBasicClampI32 vLow vHigh vValue out0 = boundary $ do
    checked (Right (Basic.clamp
        (vLow :: Int32)
        (vHigh :: Int32)
        (vValue :: Int32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_basic_clamp_i64" ffiBasicClampI64 :: 
    Int64 ->
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiBasicClampI64 :: 
    Int64 ->
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiBasicClampI64 vLow vHigh vValue out0 = boundary $ do
    checked (Right (Basic.clamp
        (vLow :: Int64)
        (vHigh :: Int64)
        (vValue :: Int64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_basic_clamp_u8" ffiBasicClampU8 :: 
    Word8 ->
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiBasicClampU8 :: 
    Word8 ->
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiBasicClampU8 vLow vHigh vValue out0 = boundary $ do
    checked (Right (Basic.clamp
        (vLow :: Word8)
        (vHigh :: Word8)
        (vValue :: Word8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_basic_clamp_u16" ffiBasicClampU16 :: 
    Word16 ->
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiBasicClampU16 :: 
    Word16 ->
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiBasicClampU16 vLow vHigh vValue out0 = boundary $ do
    checked (Right (Basic.clamp
        (vLow :: Word16)
        (vHigh :: Word16)
        (vValue :: Word16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_basic_clamp_u32" ffiBasicClampU32 :: 
    Word32 ->
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiBasicClampU32 :: 
    Word32 ->
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiBasicClampU32 vLow vHigh vValue out0 = boundary $ do
    checked (Right (Basic.clamp
        (vLow :: Word32)
        (vHigh :: Word32)
        (vValue :: Word32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_basic_clamp_u64" ffiBasicClampU64 :: 
    Word64 ->
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiBasicClampU64 :: 
    Word64 ->
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiBasicClampU64 vLow vHigh vValue out0 = boundary $ do
    checked (Right (Basic.clamp
        (vLow :: Word64)
        (vHigh :: Word64)
        (vValue :: Word64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_basic_clamp_int" ffiBasicClampInt :: 
    Int ->
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiBasicClampInt :: 
    Int ->
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiBasicClampInt vLow vHigh vValue out0 = boundary $ do
    checked (Right (Basic.clamp
        (vLow :: Int)
        (vHigh :: Int)
        (vValue :: Int))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_basic_clamp_word" ffiBasicClampWord :: 
    Word ->
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiBasicClampWord :: 
    Word ->
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiBasicClampWord vLow vHigh vValue out0 = boundary $ do
    checked (Right (Basic.clamp
        (vLow :: Word)
        (vHigh :: Word)
        (vValue :: Word))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_basic_lerp_f32" ffiBasicLerpF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiBasicLerpF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiBasicLerpF32 vA vB vT out0 = boundary $ do
    checked (Right (Basic.lerp
        (coerce vA :: Float)
        (coerce vB :: Float)
        (coerce vT :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_basic_lerp_f64" ffiBasicLerpF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiBasicLerpF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiBasicLerpF64 vA vB vT out0 = boundary $ do
    checked (Right (Basic.lerp
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vT :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_basic_lerp_rational" ffiBasicLerpRational :: 
    CString ->
    CString ->
    CString ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiBasicLerpRational :: 
    CString ->
    CString ->
    CString ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiBasicLerpRational vANumerator vADenominator vBNumerator vBDenominator vTNumerator vTDenominator out0 out1 = boundary $ do
    vAN <- readInteger vANumerator
    vAD <- readInteger vADenominator
    vBN <- readInteger vBNumerator
    vBD <- readInteger vBDenominator
    vTN <- readInteger vTNumerator
    vTD <- readInteger vTDenominator
    checked (Right (Basic.lerp
        (vAN % vAD)
        (vBN % vBD)
        (vTN % vTD))) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_basic_lerp_c64" ffiBasicLerpC64 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiBasicLerpC64 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiBasicLerpC64 vA0 vA1 vB0 vB1 vT0 vT1 out0 out1 = boundary $ do
    checked (Right (Basic.lerp
        ((coerce vA0 :: Float) :+ (coerce vA1 :: Float))
        ((coerce vB0 :: Float) :+ (coerce vB1 :: Float))
        ((coerce vT0 :: Float) :+ (coerce vT1 :: Float)))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_basic_lerp_c128" ffiBasicLerpC128 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiBasicLerpC128 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiBasicLerpC128 vA0 vA1 vB0 vB1 vT0 vT1 out0 out1 = boundary $ do
    checked (Right (Basic.lerp
        ((coerce vA0 :: Double) :+ (coerce vA1 :: Double))
        ((coerce vB0 :: Double) :+ (coerce vB1 :: Double))
        ((coerce vT0 :: Double) :+ (coerce vT1 :: Double)))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_scalar_add_f32" ffiScalarAddF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarAddF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarAddF32 vA vB out0 = boundary $ do
    checked (Right (Scalar.add
        (coerce vA :: Float)
        (coerce vB :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_add_f64" ffiScalarAddF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarAddF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarAddF64 vA vB out0 = boundary $ do
    checked (Right (Scalar.add
        (coerce vA :: Double)
        (coerce vB :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_add_rational" ffiScalarAddRational :: 
    CString ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarAddRational :: 
    CString ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarAddRational vANumerator vADenominator vBNumerator vBDenominator out0 out1 = boundary $ do
    vAN <- readInteger vANumerator
    vAD <- readInteger vADenominator
    vBN <- readInteger vBNumerator
    vBD <- readInteger vBDenominator
    checked (Right (Scalar.add
        (vAN % vAD)
        (vBN % vBD))) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_scalar_add_integer" ffiScalarAddInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarAddInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarAddInteger vA vB out0 = boundary $ do
    vAValue <- readInteger vA
    vBValue <- readInteger vB
    checked (Right (Scalar.add
        vAValue
        vBValue)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_add_i8" ffiScalarAddI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarAddI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarAddI8 vA vB out0 = boundary $ do
    checked (Right (Scalar.add
        (vA :: Int8)
        (vB :: Int8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_scalar_add_i16" ffiScalarAddI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarAddI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarAddI16 vA vB out0 = boundary $ do
    checked (Right (Scalar.add
        (vA :: Int16)
        (vB :: Int16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_scalar_add_i32" ffiScalarAddI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarAddI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarAddI32 vA vB out0 = boundary $ do
    checked (Right (Scalar.add
        (vA :: Int32)
        (vB :: Int32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_scalar_add_i64" ffiScalarAddI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarAddI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarAddI64 vA vB out0 = boundary $ do
    checked (Right (Scalar.add
        (vA :: Int64)
        (vB :: Int64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_scalar_add_u8" ffiScalarAddU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarAddU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarAddU8 vA vB out0 = boundary $ do
    checked (Right (Scalar.add
        (vA :: Word8)
        (vB :: Word8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_scalar_add_u16" ffiScalarAddU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarAddU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarAddU16 vA vB out0 = boundary $ do
    checked (Right (Scalar.add
        (vA :: Word16)
        (vB :: Word16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_scalar_add_u32" ffiScalarAddU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarAddU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarAddU32 vA vB out0 = boundary $ do
    checked (Right (Scalar.add
        (vA :: Word32)
        (vB :: Word32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_scalar_add_u64" ffiScalarAddU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarAddU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarAddU64 vA vB out0 = boundary $ do
    checked (Right (Scalar.add
        (vA :: Word64)
        (vB :: Word64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_scalar_add_int" ffiScalarAddInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarAddInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarAddInt vA vB out0 = boundary $ do
    checked (Right (Scalar.add
        (vA :: Int)
        (vB :: Int))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_scalar_add_word" ffiScalarAddWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarAddWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarAddWord vA vB out0 = boundary $ do
    checked (Right (Scalar.add
        (vA :: Word)
        (vB :: Word))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_scalar_add_c64" ffiScalarAddC64 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarAddC64 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarAddC64 vA0 vA1 vB0 vB1 out0 out1 = boundary $ do
    checked (Right (Scalar.add
        ((coerce vA0 :: Float) :+ (coerce vA1 :: Float))
        ((coerce vB0 :: Float) :+ (coerce vB1 :: Float)))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_scalar_add_c128" ffiScalarAddC128 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarAddC128 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarAddC128 vA0 vA1 vB0 vB1 out0 out1 = boundary $ do
    checked (Right (Scalar.add
        ((coerce vA0 :: Double) :+ (coerce vA1 :: Double))
        ((coerce vB0 :: Double) :+ (coerce vB1 :: Double)))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_scalar_subtract_scalar_f32" ffiScalarSubtractScalarF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarSubtractScalarF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarSubtractScalarF32 vA vB out0 = boundary $ do
    checked (Right (Scalar.subtractScalar
        (coerce vA :: Float)
        (coerce vB :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_subtract_scalar_f64" ffiScalarSubtractScalarF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarSubtractScalarF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarSubtractScalarF64 vA vB out0 = boundary $ do
    checked (Right (Scalar.subtractScalar
        (coerce vA :: Double)
        (coerce vB :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_subtract_scalar_rational" ffiScalarSubtractScalarRational :: 
    CString ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarSubtractScalarRational :: 
    CString ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarSubtractScalarRational vANumerator vADenominator vBNumerator vBDenominator out0 out1 = boundary $ do
    vAN <- readInteger vANumerator
    vAD <- readInteger vADenominator
    vBN <- readInteger vBNumerator
    vBD <- readInteger vBDenominator
    checked (Right (Scalar.subtractScalar
        (vAN % vAD)
        (vBN % vBD))) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_scalar_subtract_scalar_integer" ffiScalarSubtractScalarInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarSubtractScalarInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarSubtractScalarInteger vA vB out0 = boundary $ do
    vAValue <- readInteger vA
    vBValue <- readInteger vB
    checked (Right (Scalar.subtractScalar
        vAValue
        vBValue)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_subtract_scalar_i8" ffiScalarSubtractScalarI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarSubtractScalarI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarSubtractScalarI8 vA vB out0 = boundary $ do
    checked (Right (Scalar.subtractScalar
        (vA :: Int8)
        (vB :: Int8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_scalar_subtract_scalar_i16" ffiScalarSubtractScalarI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarSubtractScalarI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarSubtractScalarI16 vA vB out0 = boundary $ do
    checked (Right (Scalar.subtractScalar
        (vA :: Int16)
        (vB :: Int16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_scalar_subtract_scalar_i32" ffiScalarSubtractScalarI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarSubtractScalarI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarSubtractScalarI32 vA vB out0 = boundary $ do
    checked (Right (Scalar.subtractScalar
        (vA :: Int32)
        (vB :: Int32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_scalar_subtract_scalar_i64" ffiScalarSubtractScalarI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarSubtractScalarI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarSubtractScalarI64 vA vB out0 = boundary $ do
    checked (Right (Scalar.subtractScalar
        (vA :: Int64)
        (vB :: Int64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_scalar_subtract_scalar_u8" ffiScalarSubtractScalarU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarSubtractScalarU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarSubtractScalarU8 vA vB out0 = boundary $ do
    checked (Right (Scalar.subtractScalar
        (vA :: Word8)
        (vB :: Word8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_scalar_subtract_scalar_u16" ffiScalarSubtractScalarU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarSubtractScalarU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarSubtractScalarU16 vA vB out0 = boundary $ do
    checked (Right (Scalar.subtractScalar
        (vA :: Word16)
        (vB :: Word16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_scalar_subtract_scalar_u32" ffiScalarSubtractScalarU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarSubtractScalarU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarSubtractScalarU32 vA vB out0 = boundary $ do
    checked (Right (Scalar.subtractScalar
        (vA :: Word32)
        (vB :: Word32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_scalar_subtract_scalar_u64" ffiScalarSubtractScalarU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarSubtractScalarU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarSubtractScalarU64 vA vB out0 = boundary $ do
    checked (Right (Scalar.subtractScalar
        (vA :: Word64)
        (vB :: Word64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_scalar_subtract_scalar_int" ffiScalarSubtractScalarInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarSubtractScalarInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarSubtractScalarInt vA vB out0 = boundary $ do
    checked (Right (Scalar.subtractScalar
        (vA :: Int)
        (vB :: Int))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_scalar_subtract_scalar_word" ffiScalarSubtractScalarWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarSubtractScalarWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarSubtractScalarWord vA vB out0 = boundary $ do
    checked (Right (Scalar.subtractScalar
        (vA :: Word)
        (vB :: Word))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_scalar_subtract_scalar_c64" ffiScalarSubtractScalarC64 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarSubtractScalarC64 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarSubtractScalarC64 vA0 vA1 vB0 vB1 out0 out1 = boundary $ do
    checked (Right (Scalar.subtractScalar
        ((coerce vA0 :: Float) :+ (coerce vA1 :: Float))
        ((coerce vB0 :: Float) :+ (coerce vB1 :: Float)))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_scalar_subtract_scalar_c128" ffiScalarSubtractScalarC128 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarSubtractScalarC128 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarSubtractScalarC128 vA0 vA1 vB0 vB1 out0 out1 = boundary $ do
    checked (Right (Scalar.subtractScalar
        ((coerce vA0 :: Double) :+ (coerce vA1 :: Double))
        ((coerce vB0 :: Double) :+ (coerce vB1 :: Double)))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_scalar_multiply_f32" ffiScalarMultiplyF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarMultiplyF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarMultiplyF32 vA vB out0 = boundary $ do
    checked (Right (Scalar.multiply
        (coerce vA :: Float)
        (coerce vB :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_multiply_f64" ffiScalarMultiplyF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarMultiplyF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarMultiplyF64 vA vB out0 = boundary $ do
    checked (Right (Scalar.multiply
        (coerce vA :: Double)
        (coerce vB :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_multiply_rational" ffiScalarMultiplyRational :: 
    CString ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarMultiplyRational :: 
    CString ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarMultiplyRational vANumerator vADenominator vBNumerator vBDenominator out0 out1 = boundary $ do
    vAN <- readInteger vANumerator
    vAD <- readInteger vADenominator
    vBN <- readInteger vBNumerator
    vBD <- readInteger vBDenominator
    checked (Right (Scalar.multiply
        (vAN % vAD)
        (vBN % vBD))) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_scalar_multiply_integer" ffiScalarMultiplyInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarMultiplyInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarMultiplyInteger vA vB out0 = boundary $ do
    vAValue <- readInteger vA
    vBValue <- readInteger vB
    checked (Right (Scalar.multiply
        vAValue
        vBValue)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_multiply_i8" ffiScalarMultiplyI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarMultiplyI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarMultiplyI8 vA vB out0 = boundary $ do
    checked (Right (Scalar.multiply
        (vA :: Int8)
        (vB :: Int8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_scalar_multiply_i16" ffiScalarMultiplyI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarMultiplyI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarMultiplyI16 vA vB out0 = boundary $ do
    checked (Right (Scalar.multiply
        (vA :: Int16)
        (vB :: Int16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_scalar_multiply_i32" ffiScalarMultiplyI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarMultiplyI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarMultiplyI32 vA vB out0 = boundary $ do
    checked (Right (Scalar.multiply
        (vA :: Int32)
        (vB :: Int32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_scalar_multiply_i64" ffiScalarMultiplyI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarMultiplyI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarMultiplyI64 vA vB out0 = boundary $ do
    checked (Right (Scalar.multiply
        (vA :: Int64)
        (vB :: Int64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_scalar_multiply_u8" ffiScalarMultiplyU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarMultiplyU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarMultiplyU8 vA vB out0 = boundary $ do
    checked (Right (Scalar.multiply
        (vA :: Word8)
        (vB :: Word8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_scalar_multiply_u16" ffiScalarMultiplyU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarMultiplyU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarMultiplyU16 vA vB out0 = boundary $ do
    checked (Right (Scalar.multiply
        (vA :: Word16)
        (vB :: Word16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_scalar_multiply_u32" ffiScalarMultiplyU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarMultiplyU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarMultiplyU32 vA vB out0 = boundary $ do
    checked (Right (Scalar.multiply
        (vA :: Word32)
        (vB :: Word32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_scalar_multiply_u64" ffiScalarMultiplyU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarMultiplyU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarMultiplyU64 vA vB out0 = boundary $ do
    checked (Right (Scalar.multiply
        (vA :: Word64)
        (vB :: Word64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_scalar_multiply_int" ffiScalarMultiplyInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarMultiplyInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarMultiplyInt vA vB out0 = boundary $ do
    checked (Right (Scalar.multiply
        (vA :: Int)
        (vB :: Int))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_scalar_multiply_word" ffiScalarMultiplyWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarMultiplyWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarMultiplyWord vA vB out0 = boundary $ do
    checked (Right (Scalar.multiply
        (vA :: Word)
        (vB :: Word))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_scalar_multiply_c64" ffiScalarMultiplyC64 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarMultiplyC64 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarMultiplyC64 vA0 vA1 vB0 vB1 out0 out1 = boundary $ do
    checked (Right (Scalar.multiply
        ((coerce vA0 :: Float) :+ (coerce vA1 :: Float))
        ((coerce vB0 :: Float) :+ (coerce vB1 :: Float)))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_scalar_multiply_c128" ffiScalarMultiplyC128 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarMultiplyC128 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarMultiplyC128 vA0 vA1 vB0 vB1 out0 out1 = boundary $ do
    checked (Right (Scalar.multiply
        ((coerce vA0 :: Double) :+ (coerce vA1 :: Double))
        ((coerce vB0 :: Double) :+ (coerce vB1 :: Double)))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_scalar_minimum_scalar_f32" ffiScalarMinimumScalarF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarMinimumScalarF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarMinimumScalarF32 vA vB out0 = boundary $ do
    checked (Right (Scalar.minimumScalar
        (coerce vA :: Float)
        (coerce vB :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_minimum_scalar_f64" ffiScalarMinimumScalarF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarMinimumScalarF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarMinimumScalarF64 vA vB out0 = boundary $ do
    checked (Right (Scalar.minimumScalar
        (coerce vA :: Double)
        (coerce vB :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_minimum_scalar_rational" ffiScalarMinimumScalarRational :: 
    CString ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarMinimumScalarRational :: 
    CString ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarMinimumScalarRational vANumerator vADenominator vBNumerator vBDenominator out0 out1 = boundary $ do
    vAN <- readInteger vANumerator
    vAD <- readInteger vADenominator
    vBN <- readInteger vBNumerator
    vBD <- readInteger vBDenominator
    checked (Right (Scalar.minimumScalar
        (vAN % vAD)
        (vBN % vBD))) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_scalar_minimum_scalar_integer" ffiScalarMinimumScalarInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarMinimumScalarInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarMinimumScalarInteger vA vB out0 = boundary $ do
    vAValue <- readInteger vA
    vBValue <- readInteger vB
    checked (Right (Scalar.minimumScalar
        vAValue
        vBValue)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_minimum_scalar_i8" ffiScalarMinimumScalarI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarMinimumScalarI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarMinimumScalarI8 vA vB out0 = boundary $ do
    checked (Right (Scalar.minimumScalar
        (vA :: Int8)
        (vB :: Int8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_scalar_minimum_scalar_i16" ffiScalarMinimumScalarI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarMinimumScalarI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarMinimumScalarI16 vA vB out0 = boundary $ do
    checked (Right (Scalar.minimumScalar
        (vA :: Int16)
        (vB :: Int16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_scalar_minimum_scalar_i32" ffiScalarMinimumScalarI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarMinimumScalarI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarMinimumScalarI32 vA vB out0 = boundary $ do
    checked (Right (Scalar.minimumScalar
        (vA :: Int32)
        (vB :: Int32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_scalar_minimum_scalar_i64" ffiScalarMinimumScalarI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarMinimumScalarI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarMinimumScalarI64 vA vB out0 = boundary $ do
    checked (Right (Scalar.minimumScalar
        (vA :: Int64)
        (vB :: Int64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_scalar_minimum_scalar_u8" ffiScalarMinimumScalarU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarMinimumScalarU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarMinimumScalarU8 vA vB out0 = boundary $ do
    checked (Right (Scalar.minimumScalar
        (vA :: Word8)
        (vB :: Word8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_scalar_minimum_scalar_u16" ffiScalarMinimumScalarU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarMinimumScalarU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarMinimumScalarU16 vA vB out0 = boundary $ do
    checked (Right (Scalar.minimumScalar
        (vA :: Word16)
        (vB :: Word16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_scalar_minimum_scalar_u32" ffiScalarMinimumScalarU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarMinimumScalarU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarMinimumScalarU32 vA vB out0 = boundary $ do
    checked (Right (Scalar.minimumScalar
        (vA :: Word32)
        (vB :: Word32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_scalar_minimum_scalar_u64" ffiScalarMinimumScalarU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarMinimumScalarU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarMinimumScalarU64 vA vB out0 = boundary $ do
    checked (Right (Scalar.minimumScalar
        (vA :: Word64)
        (vB :: Word64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_scalar_minimum_scalar_int" ffiScalarMinimumScalarInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarMinimumScalarInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarMinimumScalarInt vA vB out0 = boundary $ do
    checked (Right (Scalar.minimumScalar
        (vA :: Int)
        (vB :: Int))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_scalar_minimum_scalar_word" ffiScalarMinimumScalarWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarMinimumScalarWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarMinimumScalarWord vA vB out0 = boundary $ do
    checked (Right (Scalar.minimumScalar
        (vA :: Word)
        (vB :: Word))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_scalar_maximum_scalar_f32" ffiScalarMaximumScalarF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarMaximumScalarF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarMaximumScalarF32 vA vB out0 = boundary $ do
    checked (Right (Scalar.maximumScalar
        (coerce vA :: Float)
        (coerce vB :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_maximum_scalar_f64" ffiScalarMaximumScalarF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarMaximumScalarF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarMaximumScalarF64 vA vB out0 = boundary $ do
    checked (Right (Scalar.maximumScalar
        (coerce vA :: Double)
        (coerce vB :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_maximum_scalar_rational" ffiScalarMaximumScalarRational :: 
    CString ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarMaximumScalarRational :: 
    CString ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarMaximumScalarRational vANumerator vADenominator vBNumerator vBDenominator out0 out1 = boundary $ do
    vAN <- readInteger vANumerator
    vAD <- readInteger vADenominator
    vBN <- readInteger vBNumerator
    vBD <- readInteger vBDenominator
    checked (Right (Scalar.maximumScalar
        (vAN % vAD)
        (vBN % vBD))) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_scalar_maximum_scalar_integer" ffiScalarMaximumScalarInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarMaximumScalarInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarMaximumScalarInteger vA vB out0 = boundary $ do
    vAValue <- readInteger vA
    vBValue <- readInteger vB
    checked (Right (Scalar.maximumScalar
        vAValue
        vBValue)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_maximum_scalar_i8" ffiScalarMaximumScalarI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarMaximumScalarI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarMaximumScalarI8 vA vB out0 = boundary $ do
    checked (Right (Scalar.maximumScalar
        (vA :: Int8)
        (vB :: Int8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_scalar_maximum_scalar_i16" ffiScalarMaximumScalarI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarMaximumScalarI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarMaximumScalarI16 vA vB out0 = boundary $ do
    checked (Right (Scalar.maximumScalar
        (vA :: Int16)
        (vB :: Int16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_scalar_maximum_scalar_i32" ffiScalarMaximumScalarI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarMaximumScalarI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarMaximumScalarI32 vA vB out0 = boundary $ do
    checked (Right (Scalar.maximumScalar
        (vA :: Int32)
        (vB :: Int32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_scalar_maximum_scalar_i64" ffiScalarMaximumScalarI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarMaximumScalarI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarMaximumScalarI64 vA vB out0 = boundary $ do
    checked (Right (Scalar.maximumScalar
        (vA :: Int64)
        (vB :: Int64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_scalar_maximum_scalar_u8" ffiScalarMaximumScalarU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarMaximumScalarU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarMaximumScalarU8 vA vB out0 = boundary $ do
    checked (Right (Scalar.maximumScalar
        (vA :: Word8)
        (vB :: Word8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_scalar_maximum_scalar_u16" ffiScalarMaximumScalarU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarMaximumScalarU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarMaximumScalarU16 vA vB out0 = boundary $ do
    checked (Right (Scalar.maximumScalar
        (vA :: Word16)
        (vB :: Word16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_scalar_maximum_scalar_u32" ffiScalarMaximumScalarU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarMaximumScalarU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarMaximumScalarU32 vA vB out0 = boundary $ do
    checked (Right (Scalar.maximumScalar
        (vA :: Word32)
        (vB :: Word32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_scalar_maximum_scalar_u64" ffiScalarMaximumScalarU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarMaximumScalarU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarMaximumScalarU64 vA vB out0 = boundary $ do
    checked (Right (Scalar.maximumScalar
        (vA :: Word64)
        (vB :: Word64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_scalar_maximum_scalar_int" ffiScalarMaximumScalarInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarMaximumScalarInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarMaximumScalarInt vA vB out0 = boundary $ do
    checked (Right (Scalar.maximumScalar
        (vA :: Int)
        (vB :: Int))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_scalar_maximum_scalar_word" ffiScalarMaximumScalarWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarMaximumScalarWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarMaximumScalarWord vA vB out0 = boundary $ do
    checked (Right (Scalar.maximumScalar
        (vA :: Word)
        (vB :: Word))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_scalar_absolute_f32" ffiScalarAbsoluteF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarAbsoluteF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarAbsoluteF32 vX out0 = boundary $ do
    checked (Right (Scalar.absolute
        (coerce vX :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_absolute_f64" ffiScalarAbsoluteF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarAbsoluteF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarAbsoluteF64 vX out0 = boundary $ do
    checked (Right (Scalar.absolute
        (coerce vX :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_absolute_rational" ffiScalarAbsoluteRational :: 
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarAbsoluteRational :: 
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarAbsoluteRational vXNumerator vXDenominator out0 out1 = boundary $ do
    vXN <- readInteger vXNumerator
    vXD <- readInteger vXDenominator
    checked (Right (Scalar.absolute
        (vXN % vXD))) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_scalar_absolute_integer" ffiScalarAbsoluteInteger :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarAbsoluteInteger :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarAbsoluteInteger vX out0 = boundary $ do
    vXValue <- readInteger vX
    checked (Right (Scalar.absolute
        vXValue)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_absolute_i8" ffiScalarAbsoluteI8 :: 
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarAbsoluteI8 :: 
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarAbsoluteI8 vX out0 = boundary $ do
    checked (Right (Scalar.absolute
        (vX :: Int8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_scalar_absolute_i16" ffiScalarAbsoluteI16 :: 
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarAbsoluteI16 :: 
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarAbsoluteI16 vX out0 = boundary $ do
    checked (Right (Scalar.absolute
        (vX :: Int16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_scalar_absolute_i32" ffiScalarAbsoluteI32 :: 
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarAbsoluteI32 :: 
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarAbsoluteI32 vX out0 = boundary $ do
    checked (Right (Scalar.absolute
        (vX :: Int32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_scalar_absolute_i64" ffiScalarAbsoluteI64 :: 
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarAbsoluteI64 :: 
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarAbsoluteI64 vX out0 = boundary $ do
    checked (Right (Scalar.absolute
        (vX :: Int64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_scalar_absolute_u8" ffiScalarAbsoluteU8 :: 
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarAbsoluteU8 :: 
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarAbsoluteU8 vX out0 = boundary $ do
    checked (Right (Scalar.absolute
        (vX :: Word8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_scalar_absolute_u16" ffiScalarAbsoluteU16 :: 
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarAbsoluteU16 :: 
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarAbsoluteU16 vX out0 = boundary $ do
    checked (Right (Scalar.absolute
        (vX :: Word16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_scalar_absolute_u32" ffiScalarAbsoluteU32 :: 
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarAbsoluteU32 :: 
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarAbsoluteU32 vX out0 = boundary $ do
    checked (Right (Scalar.absolute
        (vX :: Word32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_scalar_absolute_u64" ffiScalarAbsoluteU64 :: 
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarAbsoluteU64 :: 
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarAbsoluteU64 vX out0 = boundary $ do
    checked (Right (Scalar.absolute
        (vX :: Word64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_scalar_absolute_int" ffiScalarAbsoluteInt :: 
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarAbsoluteInt :: 
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarAbsoluteInt vX out0 = boundary $ do
    checked (Right (Scalar.absolute
        (vX :: Int))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_scalar_absolute_word" ffiScalarAbsoluteWord :: 
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarAbsoluteWord :: 
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarAbsoluteWord vX out0 = boundary $ do
    checked (Right (Scalar.absolute
        (vX :: Word))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_scalar_absolute_c64" ffiScalarAbsoluteC64 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarAbsoluteC64 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarAbsoluteC64 vX0 vX1 out0 out1 = boundary $ do
    checked (Right (Scalar.absolute
        ((coerce vX0 :: Float) :+ (coerce vX1 :: Float)))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_scalar_absolute_c128" ffiScalarAbsoluteC128 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarAbsoluteC128 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarAbsoluteC128 vX0 vX1 out0 out1 = boundary $ do
    checked (Right (Scalar.absolute
        ((coerce vX0 :: Double) :+ (coerce vX1 :: Double)))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_scalar_sign_f32" ffiScalarSignF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarSignF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarSignF32 vX out0 = boundary $ do
    checked (Right (Scalar.sign
        (coerce vX :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_sign_f64" ffiScalarSignF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarSignF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarSignF64 vX out0 = boundary $ do
    checked (Right (Scalar.sign
        (coerce vX :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_sign_rational" ffiScalarSignRational :: 
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarSignRational :: 
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarSignRational vXNumerator vXDenominator out0 out1 = boundary $ do
    vXN <- readInteger vXNumerator
    vXD <- readInteger vXDenominator
    checked (Right (Scalar.sign
        (vXN % vXD))) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_scalar_sign_integer" ffiScalarSignInteger :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarSignInteger :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarSignInteger vX out0 = boundary $ do
    vXValue <- readInteger vX
    checked (Right (Scalar.sign
        vXValue)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_sign_i8" ffiScalarSignI8 :: 
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarSignI8 :: 
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarSignI8 vX out0 = boundary $ do
    checked (Right (Scalar.sign
        (vX :: Int8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_scalar_sign_i16" ffiScalarSignI16 :: 
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarSignI16 :: 
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarSignI16 vX out0 = boundary $ do
    checked (Right (Scalar.sign
        (vX :: Int16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_scalar_sign_i32" ffiScalarSignI32 :: 
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarSignI32 :: 
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarSignI32 vX out0 = boundary $ do
    checked (Right (Scalar.sign
        (vX :: Int32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_scalar_sign_i64" ffiScalarSignI64 :: 
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarSignI64 :: 
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarSignI64 vX out0 = boundary $ do
    checked (Right (Scalar.sign
        (vX :: Int64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_scalar_sign_u8" ffiScalarSignU8 :: 
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarSignU8 :: 
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarSignU8 vX out0 = boundary $ do
    checked (Right (Scalar.sign
        (vX :: Word8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_scalar_sign_u16" ffiScalarSignU16 :: 
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarSignU16 :: 
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarSignU16 vX out0 = boundary $ do
    checked (Right (Scalar.sign
        (vX :: Word16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_scalar_sign_u32" ffiScalarSignU32 :: 
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarSignU32 :: 
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarSignU32 vX out0 = boundary $ do
    checked (Right (Scalar.sign
        (vX :: Word32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_scalar_sign_u64" ffiScalarSignU64 :: 
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarSignU64 :: 
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarSignU64 vX out0 = boundary $ do
    checked (Right (Scalar.sign
        (vX :: Word64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_scalar_sign_int" ffiScalarSignInt :: 
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarSignInt :: 
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarSignInt vX out0 = boundary $ do
    checked (Right (Scalar.sign
        (vX :: Int))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_scalar_sign_word" ffiScalarSignWord :: 
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarSignWord :: 
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarSignWord vX out0 = boundary $ do
    checked (Right (Scalar.sign
        (vX :: Word))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_scalar_sign_c64" ffiScalarSignC64 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarSignC64 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarSignC64 vX0 vX1 out0 out1 = boundary $ do
    checked (Right (Scalar.sign
        ((coerce vX0 :: Float) :+ (coerce vX1 :: Float)))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_scalar_sign_c128" ffiScalarSignC128 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarSignC128 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarSignC128 vX0 vX1 out0 out1 = boundary $ do
    checked (Right (Scalar.sign
        ((coerce vX0 :: Double) :+ (coerce vX1 :: Double)))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_scalar_divide_f32" ffiScalarDivideF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarDivideF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarDivideF32 vA vB out0 = boundary $ do
    checked (Scalar.divide
        (coerce vA :: Float)
        (coerce vB :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_divide_f64" ffiScalarDivideF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarDivideF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarDivideF64 vA vB out0 = boundary $ do
    checked (Scalar.divide
        (coerce vA :: Double)
        (coerce vB :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_power_f32" ffiScalarPowerF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarPowerF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarPowerF32 vA vB out0 = boundary $ do
    checked (Scalar.power
        (coerce vA :: Float)
        (coerce vB :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_power_f64" ffiScalarPowerF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarPowerF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarPowerF64 vA vB out0 = boundary $ do
    checked (Scalar.power
        (coerce vA :: Double)
        (coerce vB :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_hypot_f32" ffiScalarHypotF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarHypotF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarHypotF32 vA vB out0 = boundary $ do
    checked (Scalar.hypot
        (coerce vA :: Float)
        (coerce vB :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_hypot_f64" ffiScalarHypotF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarHypotF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarHypotF64 vA vB out0 = boundary $ do
    checked (Scalar.hypot
        (coerce vA :: Double)
        (coerce vB :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_clamp_checked_f32" ffiScalarClampCheckedF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarClampCheckedF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarClampCheckedF32 vLow vHigh vValue out0 = boundary $ do
    checked (Scalar.clampChecked
        (coerce vLow :: Float)
        (coerce vHigh :: Float)
        (coerce vValue :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_clamp_checked_f64" ffiScalarClampCheckedF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarClampCheckedF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarClampCheckedF64 vLow vHigh vValue out0 = boundary $ do
    checked (Scalar.clampChecked
        (coerce vLow :: Double)
        (coerce vHigh :: Double)
        (coerce vValue :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_lerp_checked_f32" ffiScalarLerpCheckedF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarLerpCheckedF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarLerpCheckedF32 vA vB vT out0 = boundary $ do
    checked (Scalar.lerpChecked
        (coerce vA :: Float)
        (coerce vB :: Float)
        (coerce vT :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_lerp_checked_f64" ffiScalarLerpCheckedF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarLerpCheckedF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarLerpCheckedF64 vA vB vT out0 = boundary $ do
    checked (Scalar.lerpChecked
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vT :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_inverse_lerp_f32" ffiScalarInverseLerpF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarInverseLerpF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarInverseLerpF32 vA vB vX out0 = boundary $ do
    checked (Scalar.inverseLerp
        (coerce vA :: Float)
        (coerce vB :: Float)
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_inverse_lerp_f64" ffiScalarInverseLerpF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarInverseLerpF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarInverseLerpF64 vA vB vX out0 = boundary $ do
    checked (Scalar.inverseLerp
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_smoothstep_f32" ffiScalarSmoothstepF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarSmoothstepF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarSmoothstepF32 vA vB vX out0 = boundary $ do
    checked (Scalar.smoothstep
        (coerce vA :: Float)
        (coerce vB :: Float)
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_smoothstep_f64" ffiScalarSmoothstepF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarSmoothstepF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarSmoothstepF64 vA vB vX out0 = boundary $ do
    checked (Scalar.smoothstep
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_smootherstep_f32" ffiScalarSmootherstepF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarSmootherstepF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarSmootherstepF32 vA vB vX out0 = boundary $ do
    checked (Scalar.smootherstep
        (coerce vA :: Float)
        (coerce vB :: Float)
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_smootherstep_f64" ffiScalarSmootherstepF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarSmootherstepF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarSmootherstepF64 vA vB vX out0 = boundary $ do
    checked (Scalar.smootherstep
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_remap_f32" ffiScalarRemapF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarRemapF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarRemapF32 vA vB vC vD vX out0 = boundary $ do
    checked (Scalar.remap
        (coerce vA :: Float)
        (coerce vB :: Float)
        (coerce vC :: Float)
        (coerce vD :: Float)
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_remap_f64" ffiScalarRemapF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarRemapF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarRemapF64 vA vB vC vD vX out0 = boundary $ do
    checked (Scalar.remap
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vC :: Double)
        (coerce vD :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_step_f32" ffiScalarStepF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarStepF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarStepF32 vEdge vX out0 = boundary $ do
    checked (Scalar.step
        (coerce vEdge :: Float)
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_step_f64" ffiScalarStepF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarStepF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarStepF64 vEdge vX out0 = boundary $ do
    checked (Scalar.step
        (coerce vEdge :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_sqrt_checked_f32" ffiScalarSqrtCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarSqrtCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarSqrtCheckedF32 vX out0 = boundary $ do
    checked (Scalar.sqrtChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_sqrt_checked_f64" ffiScalarSqrtCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarSqrtCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarSqrtCheckedF64 vX out0 = boundary $ do
    checked (Scalar.sqrtChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_cube_root_f32" ffiScalarCubeRootF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarCubeRootF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarCubeRootF32 vX out0 = boundary $ do
    checked (Scalar.cubeRoot
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_cube_root_f64" ffiScalarCubeRootF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarCubeRootF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarCubeRootF64 vX out0 = boundary $ do
    checked (Scalar.cubeRoot
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_reciprocal_sqrt_f32" ffiScalarReciprocalSqrtF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarReciprocalSqrtF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarReciprocalSqrtF32 vX out0 = boundary $ do
    checked (Scalar.reciprocalSqrt
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_reciprocal_sqrt_f64" ffiScalarReciprocalSqrtF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarReciprocalSqrtF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarReciprocalSqrtF64 vX out0 = boundary $ do
    checked (Scalar.reciprocalSqrt
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_exp_checked_f32" ffiScalarExpCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarExpCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarExpCheckedF32 vX out0 = boundary $ do
    checked (Scalar.expChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_exp_checked_f64" ffiScalarExpCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarExpCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarExpCheckedF64 vX out0 = boundary $ do
    checked (Scalar.expChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_log_checked_f32" ffiScalarLogCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarLogCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarLogCheckedF32 vX out0 = boundary $ do
    checked (Scalar.logChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_log_checked_f64" ffiScalarLogCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarLogCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarLogCheckedF64 vX out0 = boundary $ do
    checked (Scalar.logChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_expm1_f32" ffiScalarExpm1F32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarExpm1F32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarExpm1F32 vX out0 = boundary $ do
    checked (Scalar.expm1
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_expm1_f64" ffiScalarExpm1F64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarExpm1F64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarExpm1F64 vX out0 = boundary $ do
    checked (Scalar.expm1
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_log1p_f32" ffiScalarLog1PF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarLog1PF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarLog1PF32 vX out0 = boundary $ do
    checked (Scalar.log1p
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_log1p_f64" ffiScalarLog1PF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarLog1PF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarLog1PF64 vX out0 = boundary $ do
    checked (Scalar.log1p
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_integer_power_f32" ffiScalarIntegerPowerF32 :: 
    CFloat ->
    CString ->
    Ptr CFloat ->
    IO CInt
ffiScalarIntegerPowerF32 :: 
    CFloat ->
    CString ->
    Ptr CFloat ->
    IO CInt
ffiScalarIntegerPowerF32 vA vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (Scalar.integerPower
        (coerce vA :: Float)
        vNValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_integer_power_f64" ffiScalarIntegerPowerF64 :: 
    CDouble ->
    CString ->
    Ptr CDouble ->
    IO CInt
ffiScalarIntegerPowerF64 :: 
    CDouble ->
    CString ->
    Ptr CDouble ->
    IO CInt
ffiScalarIntegerPowerF64 vA vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (Scalar.integerPower
        (coerce vA :: Double)
        vNValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_nth_root_f32" ffiScalarNthRootF32 :: 
    CPtrdiff ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarNthRootF32 :: 
    CPtrdiff ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarNthRootF32 vN vX out0 = boundary $ do
    checked (Scalar.nthRoot
        (fromIntegral vN)
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_nth_root_f64" ffiScalarNthRootF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarNthRootF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarNthRootF64 vN vX out0 = boundary $ do
    checked (Scalar.nthRoot
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_round_digits_f32" ffiScalarRoundDigitsF32 :: 
    CPtrdiff ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarRoundDigitsF32 :: 
    CPtrdiff ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarRoundDigitsF32 vN vX out0 = boundary $ do
    checked (Scalar.roundDigits
        (fromIntegral vN)
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_round_digits_f64" ffiScalarRoundDigitsF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarRoundDigitsF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarRoundDigitsF64 vN vX out0 = boundary $ do
    checked (Scalar.roundDigits
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_absolute_error_f32" ffiScalarAbsoluteErrorF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarAbsoluteErrorF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarAbsoluteErrorF32 vActual vExpected out0 = boundary $ do
    checked (Scalar.absoluteError
        (coerce vActual :: Float)
        (coerce vExpected :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_absolute_error_f64" ffiScalarAbsoluteErrorF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarAbsoluteErrorF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarAbsoluteErrorF64 vActual vExpected out0 = boundary $ do
    checked (Scalar.absoluteError
        (coerce vActual :: Double)
        (coerce vExpected :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_relative_error_f32" ffiScalarRelativeErrorF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarRelativeErrorF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarRelativeErrorF32 vActual vExpected out0 = boundary $ do
    checked (Scalar.relativeError
        (coerce vActual :: Float)
        (coerce vExpected :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_relative_error_f64" ffiScalarRelativeErrorF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarRelativeErrorF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarRelativeErrorF64 vActual vExpected out0 = boundary $ do
    checked (Scalar.relativeError
        (coerce vActual :: Double)
        (coerce vExpected :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_fused_multiply_add_f32" ffiScalarFusedMultiplyAddF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarFusedMultiplyAddF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarFusedMultiplyAddF32 vA vB vC out0 = boundary $ do
    checked (Scalar.fusedMultiplyAdd
        (coerce vA :: Float)
        (coerce vB :: Float)
        (coerce vC :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_fused_multiply_add_f64" ffiScalarFusedMultiplyAddF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarFusedMultiplyAddF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarFusedMultiplyAddF64 vA vB vC out0 = boundary $ do
    checked (Scalar.fusedMultiplyAdd
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vC :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_checked_float_multiply_f32" ffiScalarCheckedFloatMultiplyF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarCheckedFloatMultiplyF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiScalarCheckedFloatMultiplyF32 vA vB out0 = boundary $ do
    checked (Scalar.checkedFloatMultiply
        (coerce vA :: Float)
        (coerce vB :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_scalar_checked_float_multiply_f64" ffiScalarCheckedFloatMultiplyF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarCheckedFloatMultiplyF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiScalarCheckedFloatMultiplyF64 vA vB out0 = boundary $ do
    checked (Scalar.checkedFloatMultiply
        (coerce vA :: Double)
        (coerce vB :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_floor_checked_f32" ffiScalarFloorCheckedF32 :: 
    CFloat ->
    Ptr CString ->
    IO CInt
ffiScalarFloorCheckedF32 :: 
    CFloat ->
    Ptr CString ->
    IO CInt
ffiScalarFloorCheckedF32 vX out0 = boundary $ do
    checked (Scalar.floorChecked
        (coerce vX :: Float)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_floor_checked_f64" ffiScalarFloorCheckedF64 :: 
    CDouble ->
    Ptr CString ->
    IO CInt
ffiScalarFloorCheckedF64 :: 
    CDouble ->
    Ptr CString ->
    IO CInt
ffiScalarFloorCheckedF64 vX out0 = boundary $ do
    checked (Scalar.floorChecked
        (coerce vX :: Double)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_ceil_checked_f32" ffiScalarCeilCheckedF32 :: 
    CFloat ->
    Ptr CString ->
    IO CInt
ffiScalarCeilCheckedF32 :: 
    CFloat ->
    Ptr CString ->
    IO CInt
ffiScalarCeilCheckedF32 vX out0 = boundary $ do
    checked (Scalar.ceilChecked
        (coerce vX :: Float)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_ceil_checked_f64" ffiScalarCeilCheckedF64 :: 
    CDouble ->
    Ptr CString ->
    IO CInt
ffiScalarCeilCheckedF64 :: 
    CDouble ->
    Ptr CString ->
    IO CInt
ffiScalarCeilCheckedF64 vX out0 = boundary $ do
    checked (Scalar.ceilChecked
        (coerce vX :: Double)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_round_checked_f32" ffiScalarRoundCheckedF32 :: 
    CFloat ->
    Ptr CString ->
    IO CInt
ffiScalarRoundCheckedF32 :: 
    CFloat ->
    Ptr CString ->
    IO CInt
ffiScalarRoundCheckedF32 vX out0 = boundary $ do
    checked (Scalar.roundChecked
        (coerce vX :: Float)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_round_checked_f64" ffiScalarRoundCheckedF64 :: 
    CDouble ->
    Ptr CString ->
    IO CInt
ffiScalarRoundCheckedF64 :: 
    CDouble ->
    Ptr CString ->
    IO CInt
ffiScalarRoundCheckedF64 vX out0 = boundary $ do
    checked (Scalar.roundChecked
        (coerce vX :: Double)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_truncate_checked_f32" ffiScalarTruncateCheckedF32 :: 
    CFloat ->
    Ptr CString ->
    IO CInt
ffiScalarTruncateCheckedF32 :: 
    CFloat ->
    Ptr CString ->
    IO CInt
ffiScalarTruncateCheckedF32 vX out0 = boundary $ do
    checked (Scalar.truncateChecked
        (coerce vX :: Float)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_truncate_checked_f64" ffiScalarTruncateCheckedF64 :: 
    CDouble ->
    Ptr CString ->
    IO CInt
ffiScalarTruncateCheckedF64 :: 
    CDouble ->
    Ptr CString ->
    IO CInt
ffiScalarTruncateCheckedF64 vX out0 = boundary $ do
    checked (Scalar.truncateChecked
        (coerce vX :: Double)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_bankers_round_f32" ffiScalarBankersRoundF32 :: 
    CFloat ->
    Ptr CString ->
    IO CInt
ffiScalarBankersRoundF32 :: 
    CFloat ->
    Ptr CString ->
    IO CInt
ffiScalarBankersRoundF32 vX out0 = boundary $ do
    checked (Scalar.bankersRound
        (coerce vX :: Float)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_bankers_round_f64" ffiScalarBankersRoundF64 :: 
    CDouble ->
    Ptr CString ->
    IO CInt
ffiScalarBankersRoundF64 :: 
    CDouble ->
    Ptr CString ->
    IO CInt
ffiScalarBankersRoundF64 vX out0 = boundary $ do
    checked (Scalar.bankersRound
        (coerce vX :: Double)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_integer_fraction_f32" ffiScalarIntegerFractionF32 :: 
    CFloat ->
    Ptr CString ->
    Ptr CFloat ->
    IO CInt
ffiScalarIntegerFractionF32 :: 
    CFloat ->
    Ptr CString ->
    Ptr CFloat ->
    IO CInt
ffiScalarIntegerFractionF32 vX out0 out1 = boundary $ do
    checked (Scalar.integerFraction
        (coerce vX :: Float)) $ \(first, second) -> do
        strict1 <- evaluate (second)
        writeStrings [show (first)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_scalar_integer_fraction_f64" ffiScalarIntegerFractionF64 :: 
    CDouble ->
    Ptr CString ->
    Ptr CDouble ->
    IO CInt
ffiScalarIntegerFractionF64 :: 
    CDouble ->
    Ptr CString ->
    Ptr CDouble ->
    IO CInt
ffiScalarIntegerFractionF64 vX out0 out1 = boundary $ do
    checked (Scalar.integerFraction
        (coerce vX :: Double)) $ \(first, second) -> do
        strict1 <- evaluate (second)
        writeStrings [show (first)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_scalar_quotient_remainder" ffiScalarQuotientRemainder :: 
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarQuotientRemainder :: 
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarQuotientRemainder vA vB out0 out1 = boundary $ do
    vAValue <- readInteger vA
    vBValue <- readInteger vB
    checked (Scalar.quotientRemainder
        vAValue
        vBValue) $ \(first, second) -> do
        writeStrings [show (first), show (second)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_scalar_euclidean_division" ffiScalarEuclideanDivision :: 
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarEuclideanDivision :: 
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarEuclideanDivision vA vB out0 out1 = boundary $ do
    vAValue <- readInteger vA
    vBValue <- readInteger vB
    checked (Scalar.euclideanDivision
        vAValue
        vBValue) $ \(first, second) -> do
        writeStrings [show (first), show (second)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_scalar_positive_modulo_integer" ffiScalarPositiveModuloInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarPositiveModuloInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarPositiveModuloInteger vA vModulus out0 = boundary $ do
    vAValue <- readInteger vA
    vModulusValue <- readInteger vModulus
    checked (Scalar.positiveModulo
        vAValue
        vModulusValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_positive_modulo_i8" ffiScalarPositiveModuloI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarPositiveModuloI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarPositiveModuloI8 vA vModulus out0 = boundary $ do
    checked (Scalar.positiveModulo
        (vA :: Int8)
        (vModulus :: Int8)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_scalar_positive_modulo_i16" ffiScalarPositiveModuloI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarPositiveModuloI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarPositiveModuloI16 vA vModulus out0 = boundary $ do
    checked (Scalar.positiveModulo
        (vA :: Int16)
        (vModulus :: Int16)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_scalar_positive_modulo_i32" ffiScalarPositiveModuloI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarPositiveModuloI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarPositiveModuloI32 vA vModulus out0 = boundary $ do
    checked (Scalar.positiveModulo
        (vA :: Int32)
        (vModulus :: Int32)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_scalar_positive_modulo_i64" ffiScalarPositiveModuloI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarPositiveModuloI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarPositiveModuloI64 vA vModulus out0 = boundary $ do
    checked (Scalar.positiveModulo
        (vA :: Int64)
        (vModulus :: Int64)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_scalar_positive_modulo_u8" ffiScalarPositiveModuloU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarPositiveModuloU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarPositiveModuloU8 vA vModulus out0 = boundary $ do
    checked (Scalar.positiveModulo
        (vA :: Word8)
        (vModulus :: Word8)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_scalar_positive_modulo_u16" ffiScalarPositiveModuloU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarPositiveModuloU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarPositiveModuloU16 vA vModulus out0 = boundary $ do
    checked (Scalar.positiveModulo
        (vA :: Word16)
        (vModulus :: Word16)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_scalar_positive_modulo_u32" ffiScalarPositiveModuloU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarPositiveModuloU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarPositiveModuloU32 vA vModulus out0 = boundary $ do
    checked (Scalar.positiveModulo
        (vA :: Word32)
        (vModulus :: Word32)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_scalar_positive_modulo_u64" ffiScalarPositiveModuloU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarPositiveModuloU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarPositiveModuloU64 vA vModulus out0 = boundary $ do
    checked (Scalar.positiveModulo
        (vA :: Word64)
        (vModulus :: Word64)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_scalar_positive_modulo_int" ffiScalarPositiveModuloInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarPositiveModuloInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarPositiveModuloInt vA vModulus out0 = boundary $ do
    checked (Scalar.positiveModulo
        (vA :: Int)
        (vModulus :: Int)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_scalar_positive_modulo_word" ffiScalarPositiveModuloWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarPositiveModuloWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarPositiveModuloWord vA vModulus out0 = boundary $ do
    checked (Scalar.positiveModulo
        (vA :: Word)
        (vModulus :: Word)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_scalar_positive_modulo" ffiScalarPositiveModulo :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarPositiveModulo :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarPositiveModulo vA vModulus out0 = boundary $ do
    vAValue <- readInteger vA
    vModulusValue <- readInteger vModulus
    checked (Scalar.positiveModulo
        vAValue
        vModulusValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_modular_power" ffiScalarModularPower :: 
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarModularPower :: 
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarModularPower vA vN vModulus out0 = boundary $ do
    vAValue <- readInteger vA
    vNValue <- readInteger vN
    vModulusValue <- readInteger vModulus
    checked (Scalar.modularPower
        vAValue
        vNValue
        vModulusValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_factorial_checked" ffiScalarFactorialChecked :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarFactorialChecked :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarFactorialChecked vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (Scalar.factorialChecked
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_double_factorial" ffiScalarDoubleFactorial :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarDoubleFactorial :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarDoubleFactorial vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (Scalar.doubleFactorial
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_fibonacci_checked" ffiScalarFibonacciChecked :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarFibonacciChecked :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarFibonacciChecked vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (Scalar.fibonacciChecked
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_lucas" ffiScalarLucas :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarLucas :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarLucas vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (Scalar.lucas
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_catalan" ffiScalarCatalan :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarCatalan :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarCatalan vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (Scalar.catalan
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_rising_factorial" ffiScalarRisingFactorial :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarRisingFactorial :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarRisingFactorial vX vN out0 = boundary $ do
    vXValue <- readInteger vX
    vNValue <- readInteger vN
    checked (Scalar.risingFactorial
        vXValue
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_falling_factorial" ffiScalarFallingFactorial :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarFallingFactorial :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarFallingFactorial vX vN out0 = boundary $ do
    vXValue <- readInteger vX
    vNValue <- readInteger vN
    checked (Scalar.fallingFactorial
        vXValue
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_permutations" ffiScalarPermutations :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarPermutations :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarPermutations vN vK out0 = boundary $ do
    vNValue <- readInteger vN
    vKValue <- readInteger vK
    checked (Scalar.permutations
        vNValue
        vKValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_combinations" ffiScalarCombinations :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarCombinations :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiScalarCombinations vN vK out0 = boundary $ do
    vNValue <- readInteger vN
    vKValue <- readInteger vK
    checked (Scalar.combinations
        vNValue
        vKValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_scalar_bernoulli" ffiScalarBernoulli :: 
    CPtrdiff ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarBernoulli :: 
    CPtrdiff ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarBernoulli vN out0 out1 = boundary $ do
    checked (Scalar.bernoulli
        (fromIntegral vN)) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_scalar_harmonic" ffiScalarHarmonic :: 
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarHarmonic :: 
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiScalarHarmonic vN out0 out1 = boundary $ do
    vNValue <- readInteger vN
    checked (Scalar.harmonic
        vNValue) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_scalar_cumulative_sum_f32" ffiScalarCumulativeSumF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    IO CInt
ffiScalarCumulativeSumF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    IO CInt
ffiScalarCumulativeSumF32 vValues vValuesCount out0 _outCapacity = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Float)
    checked (Right (Scalar.cumulativeSum
        vValuesValue)) $ \value -> do
        strict0 <- mapM evaluate value
        pokeArray (castPtr out0 :: Ptr Float) strict0

foreign export ccall "hm_numeric_scalar_cumulative_sum_f64" ffiScalarCumulativeSumF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    IO CInt
ffiScalarCumulativeSumF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    IO CInt
ffiScalarCumulativeSumF64 vValues vValuesCount out0 _outCapacity = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    checked (Right (Scalar.cumulativeSum
        vValuesValue)) $ \value -> do
        strict0 <- mapM evaluate value
        pokeArray (castPtr out0 :: Ptr Double) strict0

foreign export ccall "hm_numeric_scalar_cumulative_sum_rational" ffiScalarCumulativeSumRational :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumRational :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumRational vValues vValuesCount outData outCount = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) vValues >>= mapM readInteger
    let vValuesValue = rationalPairs vValuesRaw
    checked (Right (Scalar.cumulativeSum vValuesValue)) $ \value -> do
        writeStrings (concatMap (\r -> [show (numerator r), show (denominator r)]) value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_scalar_cumulative_sum_integer" ffiScalarCumulativeSumInteger :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumInteger :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumInteger vValues vValuesCount outData outCount = boundary $ do
    vValuesRaw <- peekArray (fromIntegral vValuesCount) vValues
    vValuesValue <- mapM readInteger vValuesRaw
    checked (Right (Scalar.cumulativeSum vValuesValue)) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_scalar_cumulative_sum_i8" ffiScalarCumulativeSumI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr (Ptr Int8) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr (Ptr Int8) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumI8 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int8])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_sum_i16" ffiScalarCumulativeSumI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr (Ptr Int16) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr (Ptr Int16) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumI16 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int16])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_sum_i32" ffiScalarCumulativeSumI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr (Ptr Int32) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr (Ptr Int32) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumI32 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int32])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_sum_i64" ffiScalarCumulativeSumI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr (Ptr Int64) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr (Ptr Int64) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumI64 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int64])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_sum_u8" ffiScalarCumulativeSumU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr (Ptr Word8) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr (Ptr Word8) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumU8 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word8])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_sum_u16" ffiScalarCumulativeSumU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr (Ptr Word16) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr (Ptr Word16) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumU16 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word16])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_sum_u32" ffiScalarCumulativeSumU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr (Ptr Word32) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr (Ptr Word32) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumU32 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word32])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_sum_u64" ffiScalarCumulativeSumU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr (Ptr Word64) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr (Ptr Word64) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumU64 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word64])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_sum_int" ffiScalarCumulativeSumInt :: 
    Ptr Int ->
    CSize ->
    Ptr (Ptr Int) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumInt :: 
    Ptr Int ->
    CSize ->
    Ptr (Ptr Int) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumInt vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_sum_word" ffiScalarCumulativeSumWord :: 
    Ptr Word ->
    CSize ->
    Ptr (Ptr Word) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumWord :: 
    Ptr Word ->
    CSize ->
    Ptr (Ptr Word) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumWord vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_sum_c64" ffiScalarCumulativeSumC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumC64 vValues vValuesCount outData outCount = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) (castPtr vValues :: Ptr Float)
    let vValuesValue = complexPairs vValuesRaw
    checked (Right (Scalar.cumulativeSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_scalar_cumulative_sum_c128" ffiScalarCumulativeSumC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeSumC128 vValues vValuesCount outData outCount = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    let vValuesValue = complexPairs vValuesRaw
    checked (Right (Scalar.cumulativeSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_scalar_cumulative_product_f32" ffiScalarCumulativeProductF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    IO CInt
ffiScalarCumulativeProductF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    IO CInt
ffiScalarCumulativeProductF32 vValues vValuesCount out0 _outCapacity = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Float)
    checked (Right (Scalar.cumulativeProduct
        vValuesValue)) $ \value -> do
        strict0 <- mapM evaluate value
        pokeArray (castPtr out0 :: Ptr Float) strict0

foreign export ccall "hm_numeric_scalar_cumulative_product_f64" ffiScalarCumulativeProductF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    IO CInt
ffiScalarCumulativeProductF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    IO CInt
ffiScalarCumulativeProductF64 vValues vValuesCount out0 _outCapacity = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    checked (Right (Scalar.cumulativeProduct
        vValuesValue)) $ \value -> do
        strict0 <- mapM evaluate value
        pokeArray (castPtr out0 :: Ptr Double) strict0

foreign export ccall "hm_numeric_scalar_cumulative_product_rational" ffiScalarCumulativeProductRational :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductRational :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductRational vValues vValuesCount outData outCount = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) vValues >>= mapM readInteger
    let vValuesValue = rationalPairs vValuesRaw
    checked (Right (Scalar.cumulativeProduct vValuesValue)) $ \value -> do
        writeStrings (concatMap (\r -> [show (numerator r), show (denominator r)]) value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_scalar_cumulative_product_integer" ffiScalarCumulativeProductInteger :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductInteger :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductInteger vValues vValuesCount outData outCount = boundary $ do
    vValuesRaw <- peekArray (fromIntegral vValuesCount) vValues
    vValuesValue <- mapM readInteger vValuesRaw
    checked (Right (Scalar.cumulativeProduct vValuesValue)) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_scalar_cumulative_product_i8" ffiScalarCumulativeProductI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr (Ptr Int8) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr (Ptr Int8) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductI8 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeProduct vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int8])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_product_i16" ffiScalarCumulativeProductI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr (Ptr Int16) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr (Ptr Int16) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductI16 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeProduct vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int16])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_product_i32" ffiScalarCumulativeProductI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr (Ptr Int32) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr (Ptr Int32) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductI32 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeProduct vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int32])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_product_i64" ffiScalarCumulativeProductI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr (Ptr Int64) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr (Ptr Int64) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductI64 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeProduct vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int64])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_product_u8" ffiScalarCumulativeProductU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr (Ptr Word8) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr (Ptr Word8) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductU8 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeProduct vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word8])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_product_u16" ffiScalarCumulativeProductU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr (Ptr Word16) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr (Ptr Word16) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductU16 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeProduct vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word16])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_product_u32" ffiScalarCumulativeProductU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr (Ptr Word32) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr (Ptr Word32) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductU32 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeProduct vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word32])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_product_u64" ffiScalarCumulativeProductU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr (Ptr Word64) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr (Ptr Word64) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductU64 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeProduct vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word64])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_product_int" ffiScalarCumulativeProductInt :: 
    Ptr Int ->
    CSize ->
    Ptr (Ptr Int) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductInt :: 
    Ptr Int ->
    CSize ->
    Ptr (Ptr Int) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductInt vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeProduct vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_product_word" ffiScalarCumulativeProductWord :: 
    Ptr Word ->
    CSize ->
    Ptr (Ptr Word) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductWord :: 
    Ptr Word ->
    CSize ->
    Ptr (Ptr Word) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductWord vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.cumulativeProduct vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_cumulative_product_c64" ffiScalarCumulativeProductC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductC64 vValues vValuesCount outData outCount = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) (castPtr vValues :: Ptr Float)
    let vValuesValue = complexPairs vValuesRaw
    checked (Right (Scalar.cumulativeProduct vValuesValue)) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_scalar_cumulative_product_c128" ffiScalarCumulativeProductC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiScalarCumulativeProductC128 vValues vValuesCount outData outCount = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    let vValuesValue = complexPairs vValuesRaw
    checked (Right (Scalar.cumulativeProduct vValuesValue)) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_scalar_prefix_sum_f32" ffiScalarPrefixSumF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    IO CInt
ffiScalarPrefixSumF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    IO CInt
ffiScalarPrefixSumF32 vValues vValuesCount out0 _outCapacity = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Float)
    checked (Right (Scalar.prefixSum
        vValuesValue)) $ \value -> do
        strict0 <- mapM evaluate value
        pokeArray (castPtr out0 :: Ptr Float) strict0

foreign export ccall "hm_numeric_scalar_prefix_sum_f64" ffiScalarPrefixSumF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    IO CInt
ffiScalarPrefixSumF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    IO CInt
ffiScalarPrefixSumF64 vValues vValuesCount out0 _outCapacity = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    checked (Right (Scalar.prefixSum
        vValuesValue)) $ \value -> do
        strict0 <- mapM evaluate value
        pokeArray (castPtr out0 :: Ptr Double) strict0

foreign export ccall "hm_numeric_scalar_prefix_sum_rational" ffiScalarPrefixSumRational :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumRational :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumRational vValues vValuesCount outData outCount = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) vValues >>= mapM readInteger
    let vValuesValue = rationalPairs vValuesRaw
    checked (Right (Scalar.prefixSum vValuesValue)) $ \value -> do
        writeStrings (concatMap (\r -> [show (numerator r), show (denominator r)]) value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_scalar_prefix_sum_integer" ffiScalarPrefixSumInteger :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumInteger :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumInteger vValues vValuesCount outData outCount = boundary $ do
    vValuesRaw <- peekArray (fromIntegral vValuesCount) vValues
    vValuesValue <- mapM readInteger vValuesRaw
    checked (Right (Scalar.prefixSum vValuesValue)) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_scalar_prefix_sum_i8" ffiScalarPrefixSumI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr (Ptr Int8) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr (Ptr Int8) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumI8 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.prefixSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int8])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_prefix_sum_i16" ffiScalarPrefixSumI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr (Ptr Int16) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr (Ptr Int16) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumI16 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.prefixSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int16])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_prefix_sum_i32" ffiScalarPrefixSumI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr (Ptr Int32) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr (Ptr Int32) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumI32 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.prefixSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int32])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_prefix_sum_i64" ffiScalarPrefixSumI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr (Ptr Int64) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr (Ptr Int64) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumI64 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.prefixSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int64])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_prefix_sum_u8" ffiScalarPrefixSumU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr (Ptr Word8) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr (Ptr Word8) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumU8 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.prefixSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word8])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_prefix_sum_u16" ffiScalarPrefixSumU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr (Ptr Word16) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr (Ptr Word16) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumU16 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.prefixSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word16])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_prefix_sum_u32" ffiScalarPrefixSumU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr (Ptr Word32) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr (Ptr Word32) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumU32 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.prefixSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word32])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_prefix_sum_u64" ffiScalarPrefixSumU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr (Ptr Word64) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr (Ptr Word64) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumU64 vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.prefixSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word64])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_prefix_sum_int" ffiScalarPrefixSumInt :: 
    Ptr Int ->
    CSize ->
    Ptr (Ptr Int) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumInt :: 
    Ptr Int ->
    CSize ->
    Ptr (Ptr Int) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumInt vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.prefixSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_prefix_sum_word" ffiScalarPrefixSumWord :: 
    Ptr Word ->
    CSize ->
    Ptr (Ptr Word) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumWord :: 
    Ptr Word ->
    CSize ->
    Ptr (Ptr Word) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumWord vValues vValuesCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) vValues
    checked (Right (Scalar.prefixSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Word])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_scalar_prefix_sum_c64" ffiScalarPrefixSumC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumC64 vValues vValuesCount outData outCount = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) (castPtr vValues :: Ptr Float)
    let vValuesValue = complexPairs vValuesRaw
    checked (Right (Scalar.prefixSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_scalar_prefix_sum_c128" ffiScalarPrefixSumC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiScalarPrefixSumC128 vValues vValuesCount outData outCount = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    let vValuesValue = complexPairs vValuesRaw
    checked (Right (Scalar.prefixSum vValuesValue)) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_trigonometry_sin_checked_f32" ffiTrigonometrySinCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySinCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySinCheckedF32 vX out0 = boundary $ do
    checked (Trigonometry.sinChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_sin_checked_f64" ffiTrigonometrySinCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySinCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySinCheckedF64 vX out0 = boundary $ do
    checked (Trigonometry.sinChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_cos_checked_f32" ffiTrigonometryCosCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryCosCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryCosCheckedF32 vX out0 = boundary $ do
    checked (Trigonometry.cosChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_cos_checked_f64" ffiTrigonometryCosCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryCosCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryCosCheckedF64 vX out0 = boundary $ do
    checked (Trigonometry.cosChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_tan_checked_f32" ffiTrigonometryTanCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryTanCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryTanCheckedF32 vX out0 = boundary $ do
    checked (Trigonometry.tanChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_tan_checked_f64" ffiTrigonometryTanCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryTanCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryTanCheckedF64 vX out0 = boundary $ do
    checked (Trigonometry.tanChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_asin_checked_f32" ffiTrigonometryAsinCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAsinCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAsinCheckedF32 vX out0 = boundary $ do
    checked (Trigonometry.asinChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_asin_checked_f64" ffiTrigonometryAsinCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAsinCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAsinCheckedF64 vX out0 = boundary $ do
    checked (Trigonometry.asinChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_acos_checked_f32" ffiTrigonometryAcosCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAcosCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAcosCheckedF32 vX out0 = boundary $ do
    checked (Trigonometry.acosChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_acos_checked_f64" ffiTrigonometryAcosCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAcosCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAcosCheckedF64 vX out0 = boundary $ do
    checked (Trigonometry.acosChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_atan_checked_f32" ffiTrigonometryAtanCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAtanCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAtanCheckedF32 vX out0 = boundary $ do
    checked (Trigonometry.atanChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_atan_checked_f64" ffiTrigonometryAtanCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAtanCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAtanCheckedF64 vX out0 = boundary $ do
    checked (Trigonometry.atanChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_sec_f32" ffiTrigonometrySecF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySecF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySecF32 vX out0 = boundary $ do
    checked (Trigonometry.sec
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_sec_f64" ffiTrigonometrySecF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySecF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySecF64 vX out0 = boundary $ do
    checked (Trigonometry.sec
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_csc_f32" ffiTrigonometryCscF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryCscF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryCscF32 vX out0 = boundary $ do
    checked (Trigonometry.csc
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_csc_f64" ffiTrigonometryCscF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryCscF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryCscF64 vX out0 = boundary $ do
    checked (Trigonometry.csc
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_cot_f32" ffiTrigonometryCotF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryCotF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryCotF32 vX out0 = boundary $ do
    checked (Trigonometry.cot
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_cot_f64" ffiTrigonometryCotF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryCotF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryCotF64 vX out0 = boundary $ do
    checked (Trigonometry.cot
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_asec_f32" ffiTrigonometryAsecF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAsecF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAsecF32 vX out0 = boundary $ do
    checked (Trigonometry.asec
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_asec_f64" ffiTrigonometryAsecF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAsecF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAsecF64 vX out0 = boundary $ do
    checked (Trigonometry.asec
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_acsc_f32" ffiTrigonometryAcscF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAcscF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAcscF32 vX out0 = boundary $ do
    checked (Trigonometry.acsc
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_acsc_f64" ffiTrigonometryAcscF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAcscF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAcscF64 vX out0 = boundary $ do
    checked (Trigonometry.acsc
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_acot_f32" ffiTrigonometryAcotF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAcotF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAcotF32 vX out0 = boundary $ do
    checked (Trigonometry.acot
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_acot_f64" ffiTrigonometryAcotF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAcotF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAcotF64 vX out0 = boundary $ do
    checked (Trigonometry.acot
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_sinh_checked_f32" ffiTrigonometrySinhCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySinhCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySinhCheckedF32 vX out0 = boundary $ do
    checked (Trigonometry.sinhChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_sinh_checked_f64" ffiTrigonometrySinhCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySinhCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySinhCheckedF64 vX out0 = boundary $ do
    checked (Trigonometry.sinhChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_cosh_checked_f32" ffiTrigonometryCoshCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryCoshCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryCoshCheckedF32 vX out0 = boundary $ do
    checked (Trigonometry.coshChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_cosh_checked_f64" ffiTrigonometryCoshCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryCoshCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryCoshCheckedF64 vX out0 = boundary $ do
    checked (Trigonometry.coshChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_tanh_checked_f32" ffiTrigonometryTanhCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryTanhCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryTanhCheckedF32 vX out0 = boundary $ do
    checked (Trigonometry.tanhChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_tanh_checked_f64" ffiTrigonometryTanhCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryTanhCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryTanhCheckedF64 vX out0 = boundary $ do
    checked (Trigonometry.tanhChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_asinh_checked_f32" ffiTrigonometryAsinhCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAsinhCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAsinhCheckedF32 vX out0 = boundary $ do
    checked (Trigonometry.asinhChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_asinh_checked_f64" ffiTrigonometryAsinhCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAsinhCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAsinhCheckedF64 vX out0 = boundary $ do
    checked (Trigonometry.asinhChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_acosh_checked_f32" ffiTrigonometryAcoshCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAcoshCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAcoshCheckedF32 vX out0 = boundary $ do
    checked (Trigonometry.acoshChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_acosh_checked_f64" ffiTrigonometryAcoshCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAcoshCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAcoshCheckedF64 vX out0 = boundary $ do
    checked (Trigonometry.acoshChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_atanh_checked_f32" ffiTrigonometryAtanhCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAtanhCheckedF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAtanhCheckedF32 vX out0 = boundary $ do
    checked (Trigonometry.atanhChecked
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_atanh_checked_f64" ffiTrigonometryAtanhCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAtanhCheckedF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAtanhCheckedF64 vX out0 = boundary $ do
    checked (Trigonometry.atanhChecked
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_sech_f32" ffiTrigonometrySechF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySechF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySechF32 vX out0 = boundary $ do
    checked (Trigonometry.sech
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_sech_f64" ffiTrigonometrySechF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySechF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySechF64 vX out0 = boundary $ do
    checked (Trigonometry.sech
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_csch_f32" ffiTrigonometryCschF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryCschF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryCschF32 vX out0 = boundary $ do
    checked (Trigonometry.csch
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_csch_f64" ffiTrigonometryCschF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryCschF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryCschF64 vX out0 = boundary $ do
    checked (Trigonometry.csch
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_coth_f32" ffiTrigonometryCothF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryCothF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryCothF32 vX out0 = boundary $ do
    checked (Trigonometry.coth
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_coth_f64" ffiTrigonometryCothF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryCothF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryCothF64 vX out0 = boundary $ do
    checked (Trigonometry.coth
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_asech_f32" ffiTrigonometryAsechF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAsechF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAsechF32 vX out0 = boundary $ do
    checked (Trigonometry.asech
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_asech_f64" ffiTrigonometryAsechF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAsechF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAsechF64 vX out0 = boundary $ do
    checked (Trigonometry.asech
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_acsch_f32" ffiTrigonometryAcschF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAcschF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAcschF32 vX out0 = boundary $ do
    checked (Trigonometry.acsch
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_acsch_f64" ffiTrigonometryAcschF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAcschF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAcschF64 vX out0 = boundary $ do
    checked (Trigonometry.acsch
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_acoth_f32" ffiTrigonometryAcothF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAcothF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAcothF32 vX out0 = boundary $ do
    checked (Trigonometry.acoth
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_acoth_f64" ffiTrigonometryAcothF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAcothF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAcothF64 vX out0 = boundary $ do
    checked (Trigonometry.acoth
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_normalize_angle_f32" ffiTrigonometryNormalizeAngleF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryNormalizeAngleF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryNormalizeAngleF32 vX out0 = boundary $ do
    checked (Trigonometry.normalizeAngle
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_normalize_angle_f64" ffiTrigonometryNormalizeAngleF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryNormalizeAngleF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryNormalizeAngleF64 vX out0 = boundary $ do
    checked (Trigonometry.normalizeAngle
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_normalize_signed_angle_f32" ffiTrigonometryNormalizeSignedAngleF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryNormalizeSignedAngleF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryNormalizeSignedAngleF32 vX out0 = boundary $ do
    checked (Trigonometry.normalizeSignedAngle
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_normalize_signed_angle_f64" ffiTrigonometryNormalizeSignedAngleF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryNormalizeSignedAngleF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryNormalizeSignedAngleF64 vX out0 = boundary $ do
    checked (Trigonometry.normalizeSignedAngle
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_versine_f32" ffiTrigonometryVersineF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryVersineF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryVersineF32 vX out0 = boundary $ do
    checked (Trigonometry.versine
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_versine_f64" ffiTrigonometryVersineF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryVersineF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryVersineF64 vX out0 = boundary $ do
    checked (Trigonometry.versine
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_haversine_f32" ffiTrigonometryHaversineF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryHaversineF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryHaversineF32 vX out0 = boundary $ do
    checked (Trigonometry.haversine
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_haversine_f64" ffiTrigonometryHaversineF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryHaversineF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryHaversineF64 vX out0 = boundary $ do
    checked (Trigonometry.haversine
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_sinc_f32" ffiTrigonometrySincF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySincF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySincF32 vX out0 = boundary $ do
    checked (Trigonometry.sinc
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_sinc_f64" ffiTrigonometrySincF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySincF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySincF64 vX out0 = boundary $ do
    checked (Trigonometry.sinc
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_cosc_f32" ffiTrigonometryCoscF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryCoscF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryCoscF32 vX out0 = boundary $ do
    checked (Trigonometry.cosc
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_cosc_f64" ffiTrigonometryCoscF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryCoscF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryCoscF64 vX out0 = boundary $ do
    checked (Trigonometry.cosc
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_atan2_checked_f32" ffiTrigonometryAtan2CheckedF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAtan2CheckedF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAtan2CheckedF32 vY vX out0 = boundary $ do
    checked (Trigonometry.atan2Checked
        (coerce vY :: Float)
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_atan2_checked_f64" ffiTrigonometryAtan2CheckedF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAtan2CheckedF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAtan2CheckedF64 vY vX out0 = boundary $ do
    checked (Trigonometry.atan2Checked
        (coerce vY :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_sincos_f32" ffiTrigonometrySincosF32 :: 
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySincosF32 :: 
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySincosF32 vX out0 out1 = boundary $ do
    checked (Trigonometry.sincos
        (coerce vX :: Float)) $ \(first, second) -> do
        strict0 <- evaluate (first)
        strict1 <- evaluate (second)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_sincos_f64" ffiTrigonometrySincosF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySincosF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySincosF64 vX out0 out1 = boundary $ do
    checked (Trigonometry.sincos
        (coerce vX :: Double)) $ \(first, second) -> do
        strict0 <- evaluate (first)
        strict1 <- evaluate (second)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_wrap_f32" ffiTrigonometryWrapF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryWrapF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryWrapF32 vLow vHigh vX out0 = boundary $ do
    checked (Trigonometry.wrap
        (coerce vLow :: Float)
        (coerce vHigh :: Float)
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_wrap_f64" ffiTrigonometryWrapF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryWrapF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryWrapF64 vLow vHigh vX out0 = boundary $ do
    checked (Trigonometry.wrap
        (coerce vLow :: Double)
        (coerce vHigh :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_angle_difference_f32" ffiTrigonometryAngleDifferenceF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAngleDifferenceF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryAngleDifferenceF32 vA vB out0 = boundary $ do
    checked (Trigonometry.angleDifference
        (coerce vA :: Float)
        (coerce vB :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_angle_difference_f64" ffiTrigonometryAngleDifferenceF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAngleDifferenceF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryAngleDifferenceF64 vA vB out0 = boundary $ do
    checked (Trigonometry.angleDifference
        (coerce vA :: Double)
        (coerce vB :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_great_circle_angle_f32" ffiTrigonometryGreatCircleAngleF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryGreatCircleAngleF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryGreatCircleAngleF32 vA0 vA1 vB0 vB1 out0 = boundary $ do
    checked (Trigonometry.greatCircleAngle
        ((coerce vA0 :: Float), (coerce vA1 :: Float))
        ((coerce vB0 :: Float), (coerce vB1 :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_great_circle_angle_f64" ffiTrigonometryGreatCircleAngleF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryGreatCircleAngleF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryGreatCircleAngleF64 vA0 vA1 vB0 vB1 out0 = boundary $ do
    checked (Trigonometry.greatCircleAngle
        ((coerce vA0 :: Double), (coerce vA1 :: Double))
        ((coerce vB0 :: Double), (coerce vB1 :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_great_circle_distance_f32" ffiTrigonometryGreatCircleDistanceF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryGreatCircleDistanceF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryGreatCircleDistanceF32 vRadius vA0 vA1 vB0 vB1 out0 = boundary $ do
    checked (Trigonometry.greatCircleDistance
        (coerce vRadius :: Float)
        ((coerce vA0 :: Float), (coerce vA1 :: Float))
        ((coerce vB0 :: Float), (coerce vB1 :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_great_circle_distance_f64" ffiTrigonometryGreatCircleDistanceF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryGreatCircleDistanceF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryGreatCircleDistanceF64 vRadius vA0 vA1 vB0 vB1 out0 = boundary $ do
    checked (Trigonometry.greatCircleDistance
        (coerce vRadius :: Double)
        ((coerce vA0 :: Double), (coerce vA1 :: Double))
        ((coerce vB0 :: Double), (coerce vB1 :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_spherical_side_f32" ffiTrigonometrySphericalSideF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySphericalSideF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySphericalSideF32 vA vB vIncluded out0 = boundary $ do
    checked (Trigonometry.sphericalSide
        (coerce vA :: Float)
        (coerce vB :: Float)
        (coerce vIncluded :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_spherical_side_f64" ffiTrigonometrySphericalSideF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySphericalSideF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySphericalSideF64 vA vB vIncluded out0 = boundary $ do
    checked (Trigonometry.sphericalSide
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vIncluded :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_spherical_angles_f32" ffiTrigonometrySphericalAnglesF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySphericalAnglesF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySphericalAnglesF32 vA vB vC out0 out1 out2 = boundary $ do
    checked (Trigonometry.sphericalAngles
        (coerce vA :: Float)
        (coerce vB :: Float)
        (coerce vC :: Float)) $ \(first, second, third) -> do
        strict0 <- evaluate (first)
        strict1 <- evaluate (second)
        strict2 <- evaluate (third)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)
        poke out2 (coerce strict2 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_spherical_angles_f64" ffiTrigonometrySphericalAnglesF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySphericalAnglesF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySphericalAnglesF64 vA vB vC out0 out1 out2 = boundary $ do
    checked (Trigonometry.sphericalAngles
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vC :: Double)) $ \(first, second, third) -> do
        strict0 <- evaluate (first)
        strict1 <- evaluate (second)
        strict2 <- evaluate (third)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)
        poke out2 (coerce strict2 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_spherical_excess_f32" ffiTrigonometrySphericalExcessF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySphericalExcessF32 :: 
    CFloat ->
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometrySphericalExcessF32 vA vB vC out0 = boundary $ do
    checked (Trigonometry.sphericalExcess
        (coerce vA :: Float)
        (coerce vB :: Float)
        (coerce vC :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_spherical_excess_f64" ffiTrigonometrySphericalExcessF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySphericalExcessF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometrySphericalExcessF64 vA vB vC out0 = boundary $ do
    checked (Trigonometry.sphericalExcess
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vC :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_complex_sin_f32" ffiTrigonometryComplexSinF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexSinF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexSinF32 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexSin
        ((coerce vZ0 :: Float) :+ (coerce vZ1 :: Float))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_complex_sin_f64" ffiTrigonometryComplexSinF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexSinF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexSinF64 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexSin
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_complex_cos_f32" ffiTrigonometryComplexCosF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexCosF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexCosF32 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexCos
        ((coerce vZ0 :: Float) :+ (coerce vZ1 :: Float))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_complex_cos_f64" ffiTrigonometryComplexCosF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexCosF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexCosF64 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexCos
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_complex_tan_f32" ffiTrigonometryComplexTanF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexTanF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexTanF32 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexTan
        ((coerce vZ0 :: Float) :+ (coerce vZ1 :: Float))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_complex_tan_f64" ffiTrigonometryComplexTanF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexTanF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexTanF64 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexTan
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_complex_asin_f32" ffiTrigonometryComplexAsinF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexAsinF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexAsinF32 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexAsin
        ((coerce vZ0 :: Float) :+ (coerce vZ1 :: Float))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_complex_asin_f64" ffiTrigonometryComplexAsinF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexAsinF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexAsinF64 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexAsin
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_complex_acos_f32" ffiTrigonometryComplexAcosF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexAcosF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexAcosF32 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexAcos
        ((coerce vZ0 :: Float) :+ (coerce vZ1 :: Float))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_complex_acos_f64" ffiTrigonometryComplexAcosF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexAcosF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexAcosF64 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexAcos
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_complex_atan_f32" ffiTrigonometryComplexAtanF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexAtanF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexAtanF32 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexAtan
        ((coerce vZ0 :: Float) :+ (coerce vZ1 :: Float))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_complex_atan_f64" ffiTrigonometryComplexAtanF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexAtanF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexAtanF64 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexAtan
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_complex_sinh_f32" ffiTrigonometryComplexSinhF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexSinhF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexSinhF32 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexSinh
        ((coerce vZ0 :: Float) :+ (coerce vZ1 :: Float))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_complex_sinh_f64" ffiTrigonometryComplexSinhF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexSinhF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexSinhF64 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexSinh
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_complex_cosh_f32" ffiTrigonometryComplexCoshF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexCoshF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexCoshF32 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexCosh
        ((coerce vZ0 :: Float) :+ (coerce vZ1 :: Float))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_complex_cosh_f64" ffiTrigonometryComplexCoshF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexCoshF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexCoshF64 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexCosh
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_complex_tanh_f32" ffiTrigonometryComplexTanhF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexTanhF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexTanhF32 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexTanh
        ((coerce vZ0 :: Float) :+ (coerce vZ1 :: Float))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_complex_tanh_f64" ffiTrigonometryComplexTanhF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexTanhF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexTanhF64 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexTanh
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_complex_asinh_f32" ffiTrigonometryComplexAsinhF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexAsinhF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexAsinhF32 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexAsinh
        ((coerce vZ0 :: Float) :+ (coerce vZ1 :: Float))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_complex_asinh_f64" ffiTrigonometryComplexAsinhF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexAsinhF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexAsinhF64 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexAsinh
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_complex_acosh_f32" ffiTrigonometryComplexAcoshF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexAcoshF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexAcoshF32 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexAcosh
        ((coerce vZ0 :: Float) :+ (coerce vZ1 :: Float))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_complex_acosh_f64" ffiTrigonometryComplexAcoshF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexAcoshF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexAcoshF64 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexAcosh
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_complex_atanh_f32" ffiTrigonometryComplexAtanhF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexAtanhF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryComplexAtanhF32 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexAtanh
        ((coerce vZ0 :: Float) :+ (coerce vZ1 :: Float))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_complex_atanh_f64" ffiTrigonometryComplexAtanhF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexAtanhF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryComplexAtanhF64 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Trigonometry.complexAtanh
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_periodic_sawtooth_f32" ffiTrigonometryPeriodicSawtoothF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryPeriodicSawtoothF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryPeriodicSawtoothF32 vPeriod vX out0 = boundary $ do
    checked (Trigonometry.periodicSawtooth
        (coerce vPeriod :: Float)
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_periodic_sawtooth_f64" ffiTrigonometryPeriodicSawtoothF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryPeriodicSawtoothF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryPeriodicSawtoothF64 vPeriod vX out0 = boundary $ do
    checked (Trigonometry.periodicSawtooth
        (coerce vPeriod :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_periodic_triangle_f32" ffiTrigonometryPeriodicTriangleF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryPeriodicTriangleF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryPeriodicTriangleF32 vPeriod vX out0 = boundary $ do
    checked (Trigonometry.periodicTriangle
        (coerce vPeriod :: Float)
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_periodic_triangle_f64" ffiTrigonometryPeriodicTriangleF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryPeriodicTriangleF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryPeriodicTriangleF64 vPeriod vX out0 = boundary $ do
    checked (Trigonometry.periodicTriangle
        (coerce vPeriod :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_trigonometry_periodic_square_f32" ffiTrigonometryPeriodicSquareF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryPeriodicSquareF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiTrigonometryPeriodicSquareF32 vPeriod vX out0 = boundary $ do
    checked (Trigonometry.periodicSquare
        (coerce vPeriod :: Float)
        (coerce vX :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_trigonometry_periodic_square_f64" ffiTrigonometryPeriodicSquareF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryPeriodicSquareF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiTrigonometryPeriodicSquareF64 vPeriod vX out0 = boundary $ do
    checked (Trigonometry.periodicSquare
        (coerce vPeriod :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_mean_f32" ffiStatisticsMeanF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiStatisticsMeanF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiStatisticsMeanF32 vValues vValuesCount out0 = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Float)
    checked (Right (Statistics.mean
        vValuesValue)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_statistics_mean_f64" ffiStatisticsMeanF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsMeanF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsMeanF64 vValues vValuesCount out0 = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    checked (Right (Statistics.mean
        vValuesValue)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_mean_rational" ffiStatisticsMeanRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiStatisticsMeanRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiStatisticsMeanRational vValues vValuesCount out0 out1 = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) vValues >>= mapM readInteger
    let vValuesValue = rationalPairs vValuesRaw
    checked (Right (Statistics.mean
        vValuesValue)) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_statistics_mean_c64" ffiStatisticsMeanC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiStatisticsMeanC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiStatisticsMeanC64 vValues vValuesCount out0 out1 = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) (castPtr vValues :: Ptr Float)
    let vValuesValue = complexPairs vValuesRaw
    checked (Right (Statistics.mean
        vValuesValue)) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_statistics_mean_c128" ffiStatisticsMeanC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsMeanC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsMeanC128 vValues vValuesCount out0 out1 = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    let vValuesValue = complexPairs vValuesRaw
    checked (Right (Statistics.mean
        vValuesValue)) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_statistics_variance_f32" ffiStatisticsVarianceF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiStatisticsVarianceF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiStatisticsVarianceF32 vValues vValuesCount out0 = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Float)
    checked (Right (Statistics.variance
        vValuesValue)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_statistics_variance_f64" ffiStatisticsVarianceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsVarianceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsVarianceF64 vValues vValuesCount out0 = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    checked (Right (Statistics.variance
        vValuesValue)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_variance_rational" ffiStatisticsVarianceRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiStatisticsVarianceRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiStatisticsVarianceRational vValues vValuesCount out0 out1 = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) vValues >>= mapM readInteger
    let vValuesValue = rationalPairs vValuesRaw
    checked (Right (Statistics.variance
        vValuesValue)) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_statistics_variance_c64" ffiStatisticsVarianceC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiStatisticsVarianceC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiStatisticsVarianceC64 vValues vValuesCount out0 out1 = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) (castPtr vValues :: Ptr Float)
    let vValuesValue = complexPairs vValuesRaw
    checked (Right (Statistics.variance
        vValuesValue)) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_statistics_variance_c128" ffiStatisticsVarianceC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsVarianceC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsVarianceC128 vValues vValuesCount out0 out1 = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    let vValuesValue = complexPairs vValuesRaw
    checked (Right (Statistics.variance
        vValuesValue)) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_statistics_standard_deviation_f32" ffiStatisticsStandardDeviationF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiStatisticsStandardDeviationF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiStatisticsStandardDeviationF32 vValues vValuesCount out0 = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Float)
    checked (Right (Statistics.standardDeviation
        vValuesValue)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_statistics_standard_deviation_f64" ffiStatisticsStandardDeviationF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsStandardDeviationF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsStandardDeviationF64 vValues vValuesCount out0 = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    checked (Right (Statistics.standardDeviation
        vValuesValue)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_standard_deviation_c64" ffiStatisticsStandardDeviationC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiStatisticsStandardDeviationC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiStatisticsStandardDeviationC64 vValues vValuesCount out0 out1 = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) (castPtr vValues :: Ptr Float)
    let vValuesValue = complexPairs vValuesRaw
    checked (Right (Statistics.standardDeviation
        vValuesValue)) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_statistics_standard_deviation_c128" ffiStatisticsStandardDeviationC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsStandardDeviationC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsStandardDeviationC128 vValues vValuesCount out0 out1 = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    let vValuesValue = complexPairs vValuesRaw
    checked (Right (Statistics.standardDeviation
        vValuesValue)) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_statistics_median_f32" ffiStatisticsMedianF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiStatisticsMedianF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiStatisticsMedianF32 vValues vValuesCount out0 = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Float)
    checked (Right (Statistics.median
        vValuesValue)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_statistics_median_f64" ffiStatisticsMedianF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsMedianF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsMedianF64 vValues vValuesCount out0 = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    checked (Right (Statistics.median
        vValuesValue)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_median_rational" ffiStatisticsMedianRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiStatisticsMedianRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiStatisticsMedianRational vValues vValuesCount out0 out1 = boundary $ do
    vValuesRaw <- peekArray (2 * fromIntegral vValuesCount) vValues >>= mapM readInteger
    let vValuesValue = rationalPairs vValuesRaw
    checked (Right (Statistics.median
        vValuesValue)) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_constants_pi_constant_f32" ffiConstantsPiConstantF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsPiConstantF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsPiConstantF32 out0 = boundary $ do
    checked (Right (Constants.piConstant :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_constants_pi_constant_f64" ffiConstantsPiConstantF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsPiConstantF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsPiConstantF64 out0 = boundary $ do
    checked (Right (Constants.piConstant :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_constants_e_constant_f32" ffiConstantsEConstantF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsEConstantF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsEConstantF32 out0 = boundary $ do
    checked (Right (Constants.eConstant :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_constants_e_constant_f64" ffiConstantsEConstantF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsEConstantF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsEConstantF64 out0 = boundary $ do
    checked (Right (Constants.eConstant :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_constants_tau_f32" ffiConstantsTauF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsTauF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsTauF32 out0 = boundary $ do
    checked (Right (Constants.tau :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_constants_tau_f64" ffiConstantsTauF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsTauF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsTauF64 out0 = boundary $ do
    checked (Right (Constants.tau :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_constants_golden_ratio_f32" ffiConstantsGoldenRatioF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsGoldenRatioF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsGoldenRatioF32 out0 = boundary $ do
    checked (Right (Constants.goldenRatio :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_constants_golden_ratio_f64" ffiConstantsGoldenRatioF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsGoldenRatioF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsGoldenRatioF64 out0 = boundary $ do
    checked (Right (Constants.goldenRatio :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_constants_euler_mascheroni_f32" ffiConstantsEulerMascheroniF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsEulerMascheroniF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsEulerMascheroniF32 out0 = boundary $ do
    checked (Right (Constants.eulerMascheroni :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_constants_euler_mascheroni_f64" ffiConstantsEulerMascheroniF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsEulerMascheroniF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsEulerMascheroniF64 out0 = boundary $ do
    checked (Right (Constants.eulerMascheroni :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_constants_catalan_constant_f32" ffiConstantsCatalanConstantF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsCatalanConstantF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsCatalanConstantF32 out0 = boundary $ do
    checked (Right (Constants.catalanConstant :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_constants_catalan_constant_f64" ffiConstantsCatalanConstantF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsCatalanConstantF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsCatalanConstantF64 out0 = boundary $ do
    checked (Right (Constants.catalanConstant :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_constants_apery_constant_f32" ffiConstantsAperyConstantF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsAperyConstantF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsAperyConstantF32 out0 = boundary $ do
    checked (Right (Constants.aperyConstant :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_constants_apery_constant_f64" ffiConstantsAperyConstantF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsAperyConstantF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsAperyConstantF64 out0 = boundary $ do
    checked (Right (Constants.aperyConstant :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_constants_sqrt2_f32" ffiConstantsSqrt2F32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsSqrt2F32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsSqrt2F32 out0 = boundary $ do
    checked (Right (Constants.sqrt2 :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_constants_sqrt2_f64" ffiConstantsSqrt2F64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsSqrt2F64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsSqrt2F64 out0 = boundary $ do
    checked (Right (Constants.sqrt2 :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_constants_sqrt3_f32" ffiConstantsSqrt3F32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsSqrt3F32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsSqrt3F32 out0 = boundary $ do
    checked (Right (Constants.sqrt3 :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_constants_sqrt3_f64" ffiConstantsSqrt3F64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsSqrt3F64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsSqrt3F64 out0 = boundary $ do
    checked (Right (Constants.sqrt3 :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_constants_ln2_f32" ffiConstantsLn2F32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsLn2F32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsLn2F32 out0 = boundary $ do
    checked (Right (Constants.ln2 :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_constants_ln2_f64" ffiConstantsLn2F64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsLn2F64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsLn2F64 out0 = boundary $ do
    checked (Right (Constants.ln2 :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_constants_ln10_f32" ffiConstantsLn10F32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsLn10F32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsLn10F32 out0 = boundary $ do
    checked (Right (Constants.ln10 :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_constants_ln10_f64" ffiConstantsLn10F64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsLn10F64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsLn10F64 out0 = boundary $ do
    checked (Right (Constants.ln10 :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_constants_infinity_f32" ffiConstantsInfinityF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsInfinityF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsInfinityF32 out0 = boundary $ do
    checked (Right (Constants.infinity :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_constants_infinity_f64" ffiConstantsInfinityF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsInfinityF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsInfinityF64 out0 = boundary $ do
    checked (Right (Constants.infinity :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_constants_nan_f32" ffiConstantsNanF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsNanF32 :: 
    Ptr CFloat ->
    IO CInt
ffiConstantsNanF32 out0 = boundary $ do
    checked (Right (Constants.nan :: Float)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_constants_nan_f64" ffiConstantsNanF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsNanF64 :: 
    Ptr CDouble ->
    IO CInt
ffiConstantsNanF64 out0 = boundary $ do
    checked (Right (Constants.nan :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_multinomial" ffiScalarMultinomial :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiScalarMultinomial :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiScalarMultinomial vKs vKsCount out0 = boundary $ do
    vKsRaw <- peekArray (fromIntegral vKsCount) vKs
    vKsValue <- mapM readInteger vKsRaw
    checked (Scalar.multinomial
        vKsValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_gcd_integer" ffiNumbertheoryGcdInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryGcdInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryGcdInteger vArgument1 vArgument2 out0 = boundary $ do
    vArgument1Value <- readInteger vArgument1
    vArgument2Value <- readInteger vArgument2
    checked (Right (NumberTheory.gcdInteger
        vArgument1Value
        vArgument2Value)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_lcm_integer" ffiNumbertheoryLcmInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryLcmInteger :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryLcmInteger vArgument1 vArgument2 out0 = boundary $ do
    vArgument1Value <- readInteger vArgument1
    vArgument2Value <- readInteger vArgument2
    checked (Right (NumberTheory.lcmInteger
        vArgument1Value
        vArgument2Value)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_extended_g_c_d" ffiNumbertheoryExtendedGCD :: 
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryExtendedGCD :: 
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryExtendedGCD vA vB out0 out1 out2 = boundary $ do
    vAValue <- readInteger vA
    vBValue <- readInteger vB
    checked (Right (NumberTheory.extendedGCD
        vAValue
        vBValue)) $ \(first, second, third) -> do
        writeStrings [show (first), show (second), show (third)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)
            poke out2 (textPointers !! 2)

foreign export ccall "hm_numeric_numbertheory_bezout" ffiNumbertheoryBezout :: 
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryBezout :: 
    CString ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryBezout vA vB out0 out1 = boundary $ do
    vAValue <- readInteger vA
    vBValue <- readInteger vB
    checked (Right (NumberTheory.bezout
        vAValue
        vBValue)) $ \(first, second) -> do
        writeStrings [show (first), show (second)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_numbertheory_mod_pow" ffiNumbertheoryModPow :: 
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryModPow :: 
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryModPow vA vE vM out0 = boundary $ do
    vAValue <- readInteger vA
    vEValue <- readInteger vE
    vMValue <- readInteger vM
    checked (NumberTheory.modPow
        vAValue
        vEValue
        vMValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_mod_inverse" ffiNumbertheoryModInverse :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryModInverse :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryModInverse vA vM out0 = boundary $ do
    vAValue <- readInteger vA
    vMValue <- readInteger vM
    checked (NumberTheory.modInverse
        vAValue
        vMValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_integer_square_root" ffiNumbertheoryIntegerSquareRoot :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryIntegerSquareRoot :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryIntegerSquareRoot vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (NumberTheory.integerSquareRoot
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_is_prime_exact" ffiNumbertheoryIsPrimeExact :: 
    CPtrdiff ->
    CString ->
    Ptr CInt ->
    IO CInt
ffiNumbertheoryIsPrimeExact :: 
    CPtrdiff ->
    CString ->
    Ptr CInt ->
    IO CInt
ffiNumbertheoryIsPrimeExact vBudget vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (NumberTheory.isPrimeExact
        (fromIntegral vBudget)
        vNValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (if strict0 then 1 else 0)

foreign export ccall "hm_numeric_numbertheory_next_prime" ffiNumbertheoryNextPrime :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryNextPrime :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryNextPrime vBudget vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (NumberTheory.nextPrime
        (fromIntegral vBudget)
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_miller_rabin" ffiNumbertheoryMillerRabin :: 
    Ptr CString ->
    CSize ->
    CString ->
    Ptr CInt ->
    IO CInt
ffiNumbertheoryMillerRabin :: 
    Ptr CString ->
    CSize ->
    CString ->
    Ptr CInt ->
    IO CInt
ffiNumbertheoryMillerRabin vBases vBasesCount vN out0 = boundary $ do
    vBasesRaw <- peekArray (fromIntegral vBasesCount) vBases
    vBasesValue <- mapM readInteger vBasesRaw
    vNValue <- readInteger vN
    checked (NumberTheory.millerRabin
        vBasesValue
        vNValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (if strict0 then 1 else 0)

foreign export ccall "hm_numeric_numbertheory_baillie_p_s_w" ffiNumbertheoryBailliePSW :: 
    CString ->
    Ptr CInt ->
    IO CInt
ffiNumbertheoryBailliePSW :: 
    CString ->
    Ptr CInt ->
    IO CInt
ffiNumbertheoryBailliePSW vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (NumberTheory.bailliePSW
        vNValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (if strict0 then 1 else 0)

foreign export ccall "hm_numeric_numbertheory_sieve_eratosthenes" ffiNumbertheorySieveEratosthenes :: 
    CPtrdiff ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiNumbertheorySieveEratosthenes :: 
    CPtrdiff ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiNumbertheorySieveEratosthenes vBound outData outCount = boundary $ do
    checked (Right (NumberTheory.sieveEratosthenes (fromIntegral vBound))) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_numbertheory_sieve_atkin" ffiNumbertheorySieveAtkin :: 
    CPtrdiff ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiNumbertheorySieveAtkin :: 
    CPtrdiff ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiNumbertheorySieveAtkin vBound outData outCount = boundary $ do
    checked (Right (NumberTheory.sieveAtkin (fromIntegral vBound))) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_numbertheory_segmented_sieve" ffiNumbertheorySegmentedSieve :: 
    CString ->
    CString ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiNumbertheorySegmentedSieve :: 
    CString ->
    CString ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiNumbertheorySegmentedSieve vLo vHi outData outCount = boundary $ do
    vLoValue <- readInteger vLo
    vHiValue <- readInteger vHi
    checked (NumberTheory.segmentedSieve vLoValue vHiValue) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_numbertheory_pollard_rho" ffiNumbertheoryPollardRho :: 
    CPtrdiff ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryPollardRho :: 
    CPtrdiff ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryPollardRho vBudget vSeed vN out0 = boundary $ do
    vSeedValue <- readInteger vSeed
    vNValue <- readInteger vN
    checked (NumberTheory.pollardRho
        (fromIntegral vBudget)
        vSeedValue
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_pollard_p_minus_one" ffiNumbertheoryPollardPMinusOne :: 
    CPtrdiff ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryPollardPMinusOne :: 
    CPtrdiff ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryPollardPMinusOne vBound vBase vN out0 = boundary $ do
    vBaseValue <- readInteger vBase
    vNValue <- readInteger vN
    checked (NumberTheory.pollardPMinusOne
        (fromIntegral vBound)
        vBaseValue
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_fermat_factor" ffiNumbertheoryFermatFactor :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryFermatFactor :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryFermatFactor vBudget vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (NumberTheory.fermatFactor
        (fromIntegral vBudget)
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_divisors" ffiNumbertheoryDivisors :: 
    CPtrdiff ->
    CString ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiNumbertheoryDivisors :: 
    CPtrdiff ->
    CString ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiNumbertheoryDivisors vBudget vN outData outCount = boundary $ do
    vNValue <- readInteger vN
    checked (NumberTheory.divisors (fromIntegral vBudget) vNValue) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_numbertheory_divisor_sum" ffiNumbertheoryDivisorSum :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryDivisorSum :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryDivisorSum vBudget vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (NumberTheory.divisorSum
        (fromIntegral vBudget)
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_divisor_count" ffiNumbertheoryDivisorCount :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryDivisorCount :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryDivisorCount vBudget vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (NumberTheory.divisorCount
        (fromIntegral vBudget)
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_euler_totient" ffiNumbertheoryEulerTotient :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryEulerTotient :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryEulerTotient vBudget vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (NumberTheory.eulerTotient
        (fromIntegral vBudget)
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_carmichael" ffiNumbertheoryCarmichael :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryCarmichael :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryCarmichael vBudget vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (NumberTheory.carmichael
        (fromIntegral vBudget)
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_mobius" ffiNumbertheoryMobius :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryMobius :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryMobius vBudget vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (NumberTheory.mobius
        (fromIntegral vBudget)
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_liouville" ffiNumbertheoryLiouville :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryLiouville :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryLiouville vBudget vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (NumberTheory.liouville
        (fromIntegral vBudget)
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_multiplicative_order" ffiNumbertheoryMultiplicativeOrder :: 
    CPtrdiff ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryMultiplicativeOrder :: 
    CPtrdiff ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryMultiplicativeOrder vBudget vA vM out0 = boundary $ do
    vAValue <- readInteger vA
    vMValue <- readInteger vM
    checked (NumberTheory.multiplicativeOrder
        (fromIntegral vBudget)
        vAValue
        vMValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_primitive_root" ffiNumbertheoryPrimitiveRoot :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryPrimitiveRoot :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryPrimitiveRoot vBudget vM out0 = boundary $ do
    vMValue <- readInteger vM
    checked (NumberTheory.primitiveRoot
        (fromIntegral vBudget)
        vMValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_discrete_log" ffiNumbertheoryDiscreteLog :: 
    CPtrdiff ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryDiscreteLog :: 
    CPtrdiff ->
    CString ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryDiscreteLog vBudget vA vB vM out0 = boundary $ do
    vAValue <- readInteger vA
    vBValue <- readInteger vB
    vMValue <- readInteger vM
    checked (NumberTheory.discreteLog
        (fromIntegral vBudget)
        vAValue
        vBValue
        vMValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_legendre_symbol" ffiNumbertheoryLegendreSymbol :: 
    CPtrdiff ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryLegendreSymbol :: 
    CPtrdiff ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryLegendreSymbol vBudget vA vP out0 = boundary $ do
    vAValue <- readInteger vA
    vPValue <- readInteger vP
    checked (NumberTheory.legendreSymbol
        (fromIntegral vBudget)
        vAValue
        vPValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_jacobi_symbol" ffiNumbertheoryJacobiSymbol :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryJacobiSymbol :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryJacobiSymbol vA vN out0 = boundary $ do
    vAValue <- readInteger vA
    vNValue <- readInteger vN
    checked (NumberTheory.jacobiSymbol
        vAValue
        vNValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_kronecker_symbol" ffiNumbertheoryKroneckerSymbol :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryKroneckerSymbol :: 
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryKroneckerSymbol vA vN out0 = boundary $ do
    vAValue <- readInteger vA
    vNValue <- readInteger vN
    checked (Right (NumberTheory.kroneckerSymbol
        vAValue
        vNValue)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_tonelli_shanks" ffiNumbertheoryTonelliShanks :: 
    CPtrdiff ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryTonelliShanks :: 
    CPtrdiff ->
    CString ->
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryTonelliShanks vBudget vA vP out0 = boundary $ do
    vAValue <- readInteger vA
    vPValue <- readInteger vP
    checked (NumberTheory.tonelliShanks
        (fromIntegral vBudget)
        vAValue
        vPValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_continued_fraction" ffiNumbertheoryContinuedFraction :: 
    CString ->
    CString ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiNumbertheoryContinuedFraction :: 
    CString ->
    CString ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiNumbertheoryContinuedFraction vRNumerator vRDenominator outData outCount = boundary $ do
    vRN <- readInteger vRNumerator
    vRD <- readInteger vRDenominator
    checked (Right (NumberTheory.continuedFraction (vRN % vRD))) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_numbertheory_from_continued_fraction" ffiNumbertheoryFromContinuedFraction :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryFromContinuedFraction :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryFromContinuedFraction vArgument1 vArgument1Count out0 out1 = boundary $ do
    vArgument1Raw <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument1Value <- mapM readInteger vArgument1Raw
    checked (NumberTheory.fromContinuedFraction
        vArgument1Value) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_numbertheory_convergents" ffiNumbertheoryConvergents :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiNumbertheoryConvergents :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiNumbertheoryConvergents vXs vXsCount outData outCount = boundary $ do
    vXsRaw <- peekArray (fromIntegral vXsCount) vXs
    vXsValue <- mapM readInteger vXsRaw
    checked (NumberTheory.convergents vXsValue) $ \value -> do
        writeStrings (concatMap (\r -> [show (numerator r), show (denominator r)]) value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_numbertheory_farey" ffiNumbertheoryFarey :: 
    CString ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiNumbertheoryFarey :: 
    CString ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiNumbertheoryFarey vN outData outCount = boundary $ do
    vNValue <- readInteger vN
    checked (NumberTheory.farey vNValue) $ \value -> do
        writeStrings (concatMap (\r -> [show (numerator r), show (denominator r)]) value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_numbertheory_pell_fundamental" ffiNumbertheoryPellFundamental :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryPellFundamental :: 
    CPtrdiff ->
    CString ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryPellFundamental vBudget vD out0 out1 = boundary $ do
    vDValue <- readInteger vD
    checked (NumberTheory.pellFundamental
        (fromIntegral vBudget)
        vDValue) $ \(first, second) -> do
        writeStrings [show (first), show (second)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_numbertheory_is_perfect_number" ffiNumbertheoryIsPerfectNumber :: 
    CPtrdiff ->
    CString ->
    Ptr CInt ->
    IO CInt
ffiNumbertheoryIsPerfectNumber :: 
    CPtrdiff ->
    CString ->
    Ptr CInt ->
    IO CInt
ffiNumbertheoryIsPerfectNumber vBudget vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (NumberTheory.isPerfectNumber
        (fromIntegral vBudget)
        vNValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (if strict0 then 1 else 0)

foreign export ccall "hm_numeric_numbertheory_are_amicable" ffiNumbertheoryAreAmicable :: 
    CPtrdiff ->
    CString ->
    CString ->
    Ptr CInt ->
    IO CInt
ffiNumbertheoryAreAmicable :: 
    CPtrdiff ->
    CString ->
    CString ->
    Ptr CInt ->
    IO CInt
ffiNumbertheoryAreAmicable vBudget vA vB out0 = boundary $ do
    vAValue <- readInteger vA
    vBValue <- readInteger vB
    checked (NumberTheory.areAmicable
        (fromIntegral vBudget)
        vAValue
        vBValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (if strict0 then 1 else 0)

foreign export ccall "hm_numeric_numbertheory_partition_count" ffiNumbertheoryPartitionCount :: 
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryPartitionCount :: 
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryPartitionCount vN out0 = boundary $ do
    checked (NumberTheory.partitionCount
        (fromIntegral vN)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numbertheory_fibonacci_fast" ffiNumbertheoryFibonacciFast :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryFibonacciFast :: 
    CString ->
    Ptr CString ->
    IO CInt
ffiNumbertheoryFibonacciFast vN out0 = boundary $ do
    vNValue <- readInteger vN
    checked (Right (NumberTheory.fibonacciFast
        vNValue)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_permutations_count" ffiCombinatoricsPermutationsCount :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsPermutationsCount :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsPermutationsCount vN vK out0 = boundary $ do
    checked (Combinatorics.permutationsCount
        (fromIntegral vN)
        (fromIntegral vK)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_combinations_count" ffiCombinatoricsCombinationsCount :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsCombinationsCount :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsCombinationsCount vN vK out0 = boundary $ do
    checked (Combinatorics.combinationsCount
        (fromIntegral vN)
        (fromIntegral vK)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_multinomial" ffiCombinatoricsMultinomial :: 
    Ptr CPtrdiff ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsMultinomial :: 
    Ptr CPtrdiff ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsMultinomial vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Raw <- peekArray (fromIntegral vArgument1Count) vArgument1
    let vArgument1Value = map fromIntegral vArgument1Raw
    checked (Combinatorics.multinomial
        vArgument1Value) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_rank_permutation" ffiCombinatoricsRankPermutation :: 
    Ptr CPtrdiff ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsRankPermutation :: 
    Ptr CPtrdiff ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsRankPermutation vP vPCount out0 = boundary $ do
    vPRaw <- peekArray (fromIntegral vPCount) vP
    let vPValue = map fromIntegral vPRaw
    checked (Combinatorics.rankPermutation
        vPValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_unrank_permutation" ffiCombinatoricsUnrankPermutation :: 
    CPtrdiff ->
    CString ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiCombinatoricsUnrankPermutation :: 
    CPtrdiff ->
    CString ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiCombinatoricsUnrankPermutation vN vR outData outCount = boundary $ do
    vRValue <- readInteger vR
    checked (Combinatorics.unrankPermutation (fromIntegral vN) vRValue) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (map (fromIntegral :: Int -> CPtrdiff) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_combinatorics_rank_combination" ffiCombinatoricsRankCombination :: 
    CPtrdiff ->
    Ptr CPtrdiff ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsRankCombination :: 
    CPtrdiff ->
    Ptr CPtrdiff ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsRankCombination vN vXs vXsCount out0 = boundary $ do
    vXsRaw <- peekArray (fromIntegral vXsCount) vXs
    let vXsValue = map fromIntegral vXsRaw
    checked (Combinatorics.rankCombination
        (fromIntegral vN)
        vXsValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_unrank_combination" ffiCombinatoricsUnrankCombination :: 
    CPtrdiff ->
    CPtrdiff ->
    CString ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiCombinatoricsUnrankCombination :: 
    CPtrdiff ->
    CPtrdiff ->
    CString ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiCombinatoricsUnrankCombination vN vK vR outData outCount = boundary $ do
    vRValue <- readInteger vR
    checked (Combinatorics.unrankCombination (fromIntegral vN) (fromIntegral vK) vRValue) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (map (fromIntegral :: Int -> CPtrdiff) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_combinatorics_derangement_count" ffiCombinatoricsDerangementCount :: 
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsDerangementCount :: 
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsDerangementCount vN out0 = boundary $ do
    checked (Combinatorics.derangementCount
        (fromIntegral vN)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_stirling_first" ffiCombinatoricsStirlingFirst :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsStirlingFirst :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsStirlingFirst vArgument1 vArgument2 out0 = boundary $ do
    checked (Combinatorics.stirlingFirst
        (fromIntegral vArgument1)
        (fromIntegral vArgument2)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_stirling_second" ffiCombinatoricsStirlingSecond :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsStirlingSecond :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsStirlingSecond vArgument1 vArgument2 out0 = boundary $ do
    checked (Combinatorics.stirlingSecond
        (fromIntegral vArgument1)
        (fromIntegral vArgument2)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_bell_number" ffiCombinatoricsBellNumber :: 
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsBellNumber :: 
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsBellNumber vN out0 = boundary $ do
    checked (Combinatorics.bellNumber
        (fromIntegral vN)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_eulerian_number" ffiCombinatoricsEulerianNumber :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsEulerianNumber :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsEulerianNumber vArgument1 vArgument2 out0 = boundary $ do
    checked (Combinatorics.eulerianNumber
        (fromIntegral vArgument1)
        (fromIntegral vArgument2)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_lah_number" ffiCombinatoricsLahNumber :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsLahNumber :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsLahNumber vN vK out0 = boundary $ do
    checked (Combinatorics.lahNumber
        (fromIntegral vN)
        (fromIntegral vK)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_catalan_number" ffiCombinatoricsCatalanNumber :: 
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsCatalanNumber :: 
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsCatalanNumber vArgument1 out0 = boundary $ do
    checked (Combinatorics.catalanNumber
        (fromIntegral vArgument1)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_fibonacci" ffiCombinatoricsFibonacci :: 
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsFibonacci :: 
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsFibonacci vN out0 = boundary $ do
    checked (Combinatorics.fibonacci
        (fromIntegral vN)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_lucas" ffiCombinatoricsLucas :: 
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsLucas :: 
    CPtrdiff ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsLucas vN out0 = boundary $ do
    checked (Combinatorics.lucas
        (fromIntegral vN)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_inclusion_exclusion" ffiCombinatoricsInclusionExclusion :: 
    CPtrdiff ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsInclusionExclusion :: 
    CPtrdiff ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsInclusionExclusion vN vSizes vSizesCount out0 = boundary $ do
    vSizesRaw <- peekArray (fromIntegral vSizesCount) vSizes
    vSizesValue <- mapM readInteger vSizesRaw
    checked (Combinatorics.inclusionExclusion
        (fromIntegral vN)
        vSizesValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_multiset_count_f32" ffiCombinatoricsMultisetCountF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsMultisetCountF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsMultisetCountF32 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Combinatorics.multisetCount
        vArgument1Value) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_multiset_count_f64" ffiCombinatoricsMultisetCountF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsMultisetCountF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiCombinatoricsMultisetCountF64 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Combinatorics.multisetCount
        vArgument1Value) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_combinatorics_linear_recurrence" ffiCombinatoricsLinearRecurrence :: 
    CPtrdiff ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiCombinatoricsLinearRecurrence :: 
    CPtrdiff ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiCombinatoricsLinearRecurrence vN vCs vCsCount vInitial vInitialCount outData outCount = boundary $ do
    vCsRaw <- peekArray (fromIntegral vCsCount) vCs
    vCsValue <- mapM readInteger vCsRaw
    vInitialRaw <- peekArray (fromIntegral vInitialCount) vInitial
    vInitialValue <- mapM readInteger vInitialRaw
    checked (Combinatorics.linearRecurrence (fromIntegral vN) vCsValue vInitialValue) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_combinatorics_convolve_series" ffiCombinatoricsConvolveSeries :: 
    CPtrdiff ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiCombinatoricsConvolveSeries :: 
    CPtrdiff ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiCombinatoricsConvolveSeries vN vA vACount vB vBCount outData outCount = boundary $ do
    vARaw <- peekArray (fromIntegral vACount) vA
    vAValue <- mapM readInteger vARaw
    vBRaw <- peekArray (fromIntegral vBCount) vB
    vBValue <- mapM readInteger vBRaw
    checked (Combinatorics.convolveSeries (fromIntegral vN) vAValue vBValue) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_combinatorics_finite_sum_f32" ffiCombinatoricsFiniteSumF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiCombinatoricsFiniteSumF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiCombinatoricsFiniteSumF32 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Combinatorics.finiteSum
        vArgument1Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_combinatorics_finite_sum_f64" ffiCombinatoricsFiniteSumF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiCombinatoricsFiniteSumF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiCombinatoricsFiniteSumF64 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Combinatorics.finiteSum
        vArgument1Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_linear_dot_f32" ffiLinearDotF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiLinearDotF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiLinearDotF32 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_linear_dot_f64" ffiLinearDotF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiLinearDotF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiLinearDotF64 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_linear_dot_rational" ffiLinearDotRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiLinearDotRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiLinearDotRational vArgument1 vArgument1Count vArgument2 vArgument2Count out0 out1 = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) vArgument1 >>= mapM readInteger
    let vArgument1Value = rationalPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) vArgument2 >>= mapM readInteger
    let vArgument2Value = rationalPairs vArgument2Raw
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_linear_dot_integer" ffiLinearDotInteger :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiLinearDotInteger :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiLinearDotInteger vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Raw <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument1Value <- mapM readInteger vArgument1Raw
    vArgument2Raw <- peekArray (fromIntegral vArgument2Count) vArgument2
    vArgument2Value <- mapM readInteger vArgument2Raw
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_linear_dot_i8" ffiLinearDotI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr Int8 ->
    CSize ->
    Ptr Int8 ->
    IO CInt
ffiLinearDotI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr Int8 ->
    CSize ->
    Ptr Int8 ->
    IO CInt
ffiLinearDotI8 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_linear_dot_i16" ffiLinearDotI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr Int16 ->
    CSize ->
    Ptr Int16 ->
    IO CInt
ffiLinearDotI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr Int16 ->
    CSize ->
    Ptr Int16 ->
    IO CInt
ffiLinearDotI16 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_linear_dot_i32" ffiLinearDotI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr Int32 ->
    CSize ->
    Ptr Int32 ->
    IO CInt
ffiLinearDotI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr Int32 ->
    CSize ->
    Ptr Int32 ->
    IO CInt
ffiLinearDotI32 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_linear_dot_i64" ffiLinearDotI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr Int64 ->
    CSize ->
    Ptr Int64 ->
    IO CInt
ffiLinearDotI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr Int64 ->
    CSize ->
    Ptr Int64 ->
    IO CInt
ffiLinearDotI64 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_linear_dot_u8" ffiLinearDotU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr Word8 ->
    CSize ->
    Ptr Word8 ->
    IO CInt
ffiLinearDotU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr Word8 ->
    CSize ->
    Ptr Word8 ->
    IO CInt
ffiLinearDotU8 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_linear_dot_u16" ffiLinearDotU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr Word16 ->
    CSize ->
    Ptr Word16 ->
    IO CInt
ffiLinearDotU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr Word16 ->
    CSize ->
    Ptr Word16 ->
    IO CInt
ffiLinearDotU16 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_linear_dot_u32" ffiLinearDotU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr Word32 ->
    CSize ->
    Ptr Word32 ->
    IO CInt
ffiLinearDotU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr Word32 ->
    CSize ->
    Ptr Word32 ->
    IO CInt
ffiLinearDotU32 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_linear_dot_u64" ffiLinearDotU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr Word64 ->
    CSize ->
    Ptr Word64 ->
    IO CInt
ffiLinearDotU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr Word64 ->
    CSize ->
    Ptr Word64 ->
    IO CInt
ffiLinearDotU64 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_linear_dot_int" ffiLinearDotInt :: 
    Ptr Int ->
    CSize ->
    Ptr Int ->
    CSize ->
    Ptr Int ->
    IO CInt
ffiLinearDotInt :: 
    Ptr Int ->
    CSize ->
    Ptr Int ->
    CSize ->
    Ptr Int ->
    IO CInt
ffiLinearDotInt vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_linear_dot_word" ffiLinearDotWord :: 
    Ptr Word ->
    CSize ->
    Ptr Word ->
    CSize ->
    Ptr Word ->
    IO CInt
ffiLinearDotWord :: 
    Ptr Word ->
    CSize ->
    Ptr Word ->
    CSize ->
    Ptr Word ->
    IO CInt
ffiLinearDotWord vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_linear_dot_c64" ffiLinearDotC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiLinearDotC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiLinearDotC64 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 out1 = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    let vArgument1Value = complexPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    let vArgument2Value = complexPairs vArgument2Raw
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_linear_dot_c128" ffiLinearDotC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiLinearDotC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiLinearDotC128 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 out1 = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    let vArgument1Value = complexPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    let vArgument2Value = complexPairs vArgument2Raw
    checked (Right (Linear.dot
        vArgument1Value
        vArgument2Value)) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_linear_dot_checked_f32" ffiLinearDotCheckedF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiLinearDotCheckedF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiLinearDotCheckedF32 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_linear_dot_checked_f64" ffiLinearDotCheckedF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiLinearDotCheckedF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiLinearDotCheckedF64 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_linear_dot_checked_rational" ffiLinearDotCheckedRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiLinearDotCheckedRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    Ptr CString ->
    IO CInt
ffiLinearDotCheckedRational vArgument1 vArgument1Count vArgument2 vArgument2Count out0 out1 = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) vArgument1 >>= mapM readInteger
    let vArgument1Value = rationalPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) vArgument2 >>= mapM readInteger
    let vArgument2Value = rationalPairs vArgument2Raw
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        writeStrings [show (numerator value), show (denominator value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)
            poke out1 (textPointers !! 1)

foreign export ccall "hm_numeric_linear_dot_checked_integer" ffiLinearDotCheckedInteger :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiLinearDotCheckedInteger :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiLinearDotCheckedInteger vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Raw <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument1Value <- mapM readInteger vArgument1Raw
    vArgument2Raw <- peekArray (fromIntegral vArgument2Count) vArgument2
    vArgument2Value <- mapM readInteger vArgument2Raw
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_linear_dot_checked_i8" ffiLinearDotCheckedI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr Int8 ->
    CSize ->
    Ptr Int8 ->
    IO CInt
ffiLinearDotCheckedI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr Int8 ->
    CSize ->
    Ptr Int8 ->
    IO CInt
ffiLinearDotCheckedI8 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_linear_dot_checked_i16" ffiLinearDotCheckedI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr Int16 ->
    CSize ->
    Ptr Int16 ->
    IO CInt
ffiLinearDotCheckedI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr Int16 ->
    CSize ->
    Ptr Int16 ->
    IO CInt
ffiLinearDotCheckedI16 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_linear_dot_checked_i32" ffiLinearDotCheckedI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr Int32 ->
    CSize ->
    Ptr Int32 ->
    IO CInt
ffiLinearDotCheckedI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr Int32 ->
    CSize ->
    Ptr Int32 ->
    IO CInt
ffiLinearDotCheckedI32 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_linear_dot_checked_i64" ffiLinearDotCheckedI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr Int64 ->
    CSize ->
    Ptr Int64 ->
    IO CInt
ffiLinearDotCheckedI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr Int64 ->
    CSize ->
    Ptr Int64 ->
    IO CInt
ffiLinearDotCheckedI64 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_linear_dot_checked_u8" ffiLinearDotCheckedU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr Word8 ->
    CSize ->
    Ptr Word8 ->
    IO CInt
ffiLinearDotCheckedU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr Word8 ->
    CSize ->
    Ptr Word8 ->
    IO CInt
ffiLinearDotCheckedU8 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_linear_dot_checked_u16" ffiLinearDotCheckedU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr Word16 ->
    CSize ->
    Ptr Word16 ->
    IO CInt
ffiLinearDotCheckedU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr Word16 ->
    CSize ->
    Ptr Word16 ->
    IO CInt
ffiLinearDotCheckedU16 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_linear_dot_checked_u32" ffiLinearDotCheckedU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr Word32 ->
    CSize ->
    Ptr Word32 ->
    IO CInt
ffiLinearDotCheckedU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr Word32 ->
    CSize ->
    Ptr Word32 ->
    IO CInt
ffiLinearDotCheckedU32 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_linear_dot_checked_u64" ffiLinearDotCheckedU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr Word64 ->
    CSize ->
    Ptr Word64 ->
    IO CInt
ffiLinearDotCheckedU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr Word64 ->
    CSize ->
    Ptr Word64 ->
    IO CInt
ffiLinearDotCheckedU64 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_linear_dot_checked_int" ffiLinearDotCheckedInt :: 
    Ptr Int ->
    CSize ->
    Ptr Int ->
    CSize ->
    Ptr Int ->
    IO CInt
ffiLinearDotCheckedInt :: 
    Ptr Int ->
    CSize ->
    Ptr Int ->
    CSize ->
    Ptr Int ->
    IO CInt
ffiLinearDotCheckedInt vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_linear_dot_checked_word" ffiLinearDotCheckedWord :: 
    Ptr Word ->
    CSize ->
    Ptr Word ->
    CSize ->
    Ptr Word ->
    IO CInt
ffiLinearDotCheckedWord :: 
    Ptr Word ->
    CSize ->
    Ptr Word ->
    CSize ->
    Ptr Word ->
    IO CInt
ffiLinearDotCheckedWord vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_linear_dot_checked_c64" ffiLinearDotCheckedC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiLinearDotCheckedC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiLinearDotCheckedC64 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 out1 = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    let vArgument1Value = complexPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    let vArgument2Value = complexPairs vArgument2Raw
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_linear_dot_checked_c128" ffiLinearDotCheckedC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiLinearDotCheckedC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiLinearDotCheckedC128 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 out1 = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    let vArgument1Value = complexPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    let vArgument2Value = complexPairs vArgument2Raw
    checked (Linear.dotChecked
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_linear_magnitude_f32" ffiLinearMagnitudeF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiLinearMagnitudeF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiLinearMagnitudeF32 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Linear.magnitude
        vArgument1Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_linear_magnitude_f64" ffiLinearMagnitudeF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiLinearMagnitudeF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiLinearMagnitudeF64 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Linear.magnitude
        vArgument1Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_linear_magnitude_c64" ffiLinearMagnitudeC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiLinearMagnitudeC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    Ptr CFloat ->
    IO CInt
ffiLinearMagnitudeC64 vArgument1 vArgument1Count out0 out1 = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    let vArgument1Value = complexPairs vArgument1Raw
    checked (Right (Linear.magnitude
        vArgument1Value)) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CFloat)
        poke out1 (coerce strict1 :: CFloat)

foreign export ccall "hm_numeric_linear_magnitude_c128" ffiLinearMagnitudeC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiLinearMagnitudeC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiLinearMagnitudeC128 vArgument1 vArgument1Count out0 out1 = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    let vArgument1Value = complexPairs vArgument1Raw
    checked (Right (Linear.magnitude
        vArgument1Value)) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_linear_normalize_f32" ffiLinearNormalizeF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearNormalizeF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearNormalizeF32 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Linear.normalize vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_normalize_f64" ffiLinearNormalizeF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearNormalizeF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearNormalizeF64 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Linear.normalize vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_normalize_c64" ffiLinearNormalizeC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearNormalizeC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearNormalizeC64 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    let vArgument1Value = complexPairs vArgument1Raw
    checked (Right (Linear.normalize vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_normalize_c128" ffiLinearNormalizeC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearNormalizeC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearNormalizeC128 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    let vArgument1Value = complexPairs vArgument1Raw
    checked (Right (Linear.normalize vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_add_f32" ffiLinearAddF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddF32 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_f64" ffiLinearAddF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddF64 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_rational" ffiLinearAddRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddRational vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) vArgument1 >>= mapM readInteger
    let vArgument1Value = rationalPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) vArgument2 >>= mapM readInteger
    let vArgument2Value = rationalPairs vArgument2Raw
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        writeStrings (concatMap (\r -> [show (numerator r), show (denominator r)]) value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_add_integer" ffiLinearAddInteger :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddInteger :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddInteger vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument1Value <- mapM readInteger vArgument1Raw
    vArgument2Raw <- peekArray (fromIntegral vArgument2Count) vArgument2
    vArgument2Value <- mapM readInteger vArgument2Raw
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_add_i8" ffiLinearAddI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr Int8 ->
    CSize ->
    Ptr (Ptr Int8) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr Int8 ->
    CSize ->
    Ptr (Ptr Int8) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddI8 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Int8])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_i16" ffiLinearAddI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr Int16 ->
    CSize ->
    Ptr (Ptr Int16) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr Int16 ->
    CSize ->
    Ptr (Ptr Int16) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddI16 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Int16])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_i32" ffiLinearAddI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr Int32 ->
    CSize ->
    Ptr (Ptr Int32) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr Int32 ->
    CSize ->
    Ptr (Ptr Int32) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddI32 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Int32])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_i64" ffiLinearAddI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr Int64 ->
    CSize ->
    Ptr (Ptr Int64) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr Int64 ->
    CSize ->
    Ptr (Ptr Int64) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddI64 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Int64])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_u8" ffiLinearAddU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr Word8 ->
    CSize ->
    Ptr (Ptr Word8) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr Word8 ->
    CSize ->
    Ptr (Ptr Word8) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddU8 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Word8])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_u16" ffiLinearAddU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr Word16 ->
    CSize ->
    Ptr (Ptr Word16) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr Word16 ->
    CSize ->
    Ptr (Ptr Word16) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddU16 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Word16])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_u32" ffiLinearAddU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr Word32 ->
    CSize ->
    Ptr (Ptr Word32) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr Word32 ->
    CSize ->
    Ptr (Ptr Word32) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddU32 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Word32])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_u64" ffiLinearAddU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr Word64 ->
    CSize ->
    Ptr (Ptr Word64) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr Word64 ->
    CSize ->
    Ptr (Ptr Word64) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddU64 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Word64])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_int" ffiLinearAddInt :: 
    Ptr Int ->
    CSize ->
    Ptr Int ->
    CSize ->
    Ptr (Ptr Int) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddInt :: 
    Ptr Int ->
    CSize ->
    Ptr Int ->
    CSize ->
    Ptr (Ptr Int) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddInt vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_word" ffiLinearAddWord :: 
    Ptr Word ->
    CSize ->
    Ptr Word ->
    CSize ->
    Ptr (Ptr Word) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddWord :: 
    Ptr Word ->
    CSize ->
    Ptr Word ->
    CSize ->
    Ptr (Ptr Word) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddWord vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Word])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_c64" ffiLinearAddC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddC64 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    let vArgument1Value = complexPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    let vArgument2Value = complexPairs vArgument2Raw
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_add_c128" ffiLinearAddC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddC128 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    let vArgument1Value = complexPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    let vArgument2Value = complexPairs vArgument2Raw
    checked (Right (Linear.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_add_checked_f32" ffiLinearAddCheckedF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedF32 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_checked_f64" ffiLinearAddCheckedF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedF64 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_checked_rational" ffiLinearAddCheckedRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedRational vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) vArgument1 >>= mapM readInteger
    let vArgument1Value = rationalPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) vArgument2 >>= mapM readInteger
    let vArgument2Value = rationalPairs vArgument2Raw
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        writeStrings (concatMap (\r -> [show (numerator r), show (denominator r)]) value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_add_checked_integer" ffiLinearAddCheckedInteger :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedInteger :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedInteger vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument1Value <- mapM readInteger vArgument1Raw
    vArgument2Raw <- peekArray (fromIntegral vArgument2Count) vArgument2
    vArgument2Value <- mapM readInteger vArgument2Raw
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_add_checked_i8" ffiLinearAddCheckedI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr Int8 ->
    CSize ->
    Ptr (Ptr Int8) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr Int8 ->
    CSize ->
    Ptr (Ptr Int8) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedI8 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Int8])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_checked_i16" ffiLinearAddCheckedI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr Int16 ->
    CSize ->
    Ptr (Ptr Int16) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr Int16 ->
    CSize ->
    Ptr (Ptr Int16) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedI16 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Int16])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_checked_i32" ffiLinearAddCheckedI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr Int32 ->
    CSize ->
    Ptr (Ptr Int32) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr Int32 ->
    CSize ->
    Ptr (Ptr Int32) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedI32 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Int32])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_checked_i64" ffiLinearAddCheckedI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr Int64 ->
    CSize ->
    Ptr (Ptr Int64) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr Int64 ->
    CSize ->
    Ptr (Ptr Int64) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedI64 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Int64])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_checked_u8" ffiLinearAddCheckedU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr Word8 ->
    CSize ->
    Ptr (Ptr Word8) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr Word8 ->
    CSize ->
    Ptr (Ptr Word8) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedU8 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Word8])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_checked_u16" ffiLinearAddCheckedU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr Word16 ->
    CSize ->
    Ptr (Ptr Word16) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr Word16 ->
    CSize ->
    Ptr (Ptr Word16) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedU16 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Word16])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_checked_u32" ffiLinearAddCheckedU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr Word32 ->
    CSize ->
    Ptr (Ptr Word32) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr Word32 ->
    CSize ->
    Ptr (Ptr Word32) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedU32 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Word32])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_checked_u64" ffiLinearAddCheckedU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr Word64 ->
    CSize ->
    Ptr (Ptr Word64) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr Word64 ->
    CSize ->
    Ptr (Ptr Word64) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedU64 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Word64])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_checked_int" ffiLinearAddCheckedInt :: 
    Ptr Int ->
    CSize ->
    Ptr Int ->
    CSize ->
    Ptr (Ptr Int) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedInt :: 
    Ptr Int ->
    CSize ->
    Ptr Int ->
    CSize ->
    Ptr (Ptr Int) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedInt vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_checked_word" ffiLinearAddCheckedWord :: 
    Ptr Word ->
    CSize ->
    Ptr Word ->
    CSize ->
    Ptr (Ptr Word) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedWord :: 
    Ptr Word ->
    CSize ->
    Ptr Word ->
    CSize ->
    Ptr (Ptr Word) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedWord vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Word])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_add_checked_c64" ffiLinearAddCheckedC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedC64 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    let vArgument1Value = complexPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    let vArgument2Value = complexPairs vArgument2Raw
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_add_checked_c128" ffiLinearAddCheckedC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearAddCheckedC128 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    let vArgument1Value = complexPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    let vArgument2Value = complexPairs vArgument2Raw
    checked (Linear.addChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_subtract_checked_f32" ffiLinearSubtractCheckedF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedF32 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_subtract_checked_f64" ffiLinearSubtractCheckedF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedF64 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_subtract_checked_rational" ffiLinearSubtractCheckedRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedRational :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedRational vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) vArgument1 >>= mapM readInteger
    let vArgument1Value = rationalPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) vArgument2 >>= mapM readInteger
    let vArgument2Value = rationalPairs vArgument2Raw
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        writeStrings (concatMap (\r -> [show (numerator r), show (denominator r)]) value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_subtract_checked_integer" ffiLinearSubtractCheckedInteger :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedInteger :: 
    Ptr CString ->
    CSize ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedInteger vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument1Value <- mapM readInteger vArgument1Raw
    vArgument2Raw <- peekArray (fromIntegral vArgument2Count) vArgument2
    vArgument2Value <- mapM readInteger vArgument2Raw
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_subtract_checked_i8" ffiLinearSubtractCheckedI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr Int8 ->
    CSize ->
    Ptr (Ptr Int8) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedI8 :: 
    Ptr Int8 ->
    CSize ->
    Ptr Int8 ->
    CSize ->
    Ptr (Ptr Int8) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedI8 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Int8])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_subtract_checked_i16" ffiLinearSubtractCheckedI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr Int16 ->
    CSize ->
    Ptr (Ptr Int16) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedI16 :: 
    Ptr Int16 ->
    CSize ->
    Ptr Int16 ->
    CSize ->
    Ptr (Ptr Int16) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedI16 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Int16])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_subtract_checked_i32" ffiLinearSubtractCheckedI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr Int32 ->
    CSize ->
    Ptr (Ptr Int32) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedI32 :: 
    Ptr Int32 ->
    CSize ->
    Ptr Int32 ->
    CSize ->
    Ptr (Ptr Int32) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedI32 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Int32])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_subtract_checked_i64" ffiLinearSubtractCheckedI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr Int64 ->
    CSize ->
    Ptr (Ptr Int64) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedI64 :: 
    Ptr Int64 ->
    CSize ->
    Ptr Int64 ->
    CSize ->
    Ptr (Ptr Int64) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedI64 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Int64])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_subtract_checked_u8" ffiLinearSubtractCheckedU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr Word8 ->
    CSize ->
    Ptr (Ptr Word8) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedU8 :: 
    Ptr Word8 ->
    CSize ->
    Ptr Word8 ->
    CSize ->
    Ptr (Ptr Word8) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedU8 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Word8])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_subtract_checked_u16" ffiLinearSubtractCheckedU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr Word16 ->
    CSize ->
    Ptr (Ptr Word16) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedU16 :: 
    Ptr Word16 ->
    CSize ->
    Ptr Word16 ->
    CSize ->
    Ptr (Ptr Word16) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedU16 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Word16])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_subtract_checked_u32" ffiLinearSubtractCheckedU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr Word32 ->
    CSize ->
    Ptr (Ptr Word32) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedU32 :: 
    Ptr Word32 ->
    CSize ->
    Ptr Word32 ->
    CSize ->
    Ptr (Ptr Word32) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedU32 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Word32])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_subtract_checked_u64" ffiLinearSubtractCheckedU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr Word64 ->
    CSize ->
    Ptr (Ptr Word64) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedU64 :: 
    Ptr Word64 ->
    CSize ->
    Ptr Word64 ->
    CSize ->
    Ptr (Ptr Word64) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedU64 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Word64])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_subtract_checked_int" ffiLinearSubtractCheckedInt :: 
    Ptr Int ->
    CSize ->
    Ptr Int ->
    CSize ->
    Ptr (Ptr Int) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedInt :: 
    Ptr Int ->
    CSize ->
    Ptr Int ->
    CSize ->
    Ptr (Ptr Int) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedInt vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_subtract_checked_word" ffiLinearSubtractCheckedWord :: 
    Ptr Word ->
    CSize ->
    Ptr Word ->
    CSize ->
    Ptr (Ptr Word) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedWord :: 
    Ptr Word ->
    CSize ->
    Ptr Word ->
    CSize ->
    Ptr (Ptr Word) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedWord vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Word])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_subtract_checked_c64" ffiLinearSubtractCheckedC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedC64 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedC64 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    let vArgument1Value = complexPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    let vArgument2Value = complexPairs vArgument2Raw
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_subtract_checked_c128" ffiLinearSubtractCheckedC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedC128 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearSubtractCheckedC128 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (2 * fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    let vArgument1Value = complexPairs vArgument1Raw
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    let vArgument2Value = complexPairs vArgument2Raw
    checked (Linear.subtractChecked vArgument1Value vArgument2Value) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_scale_f32" ffiLinearScaleF32 :: 
    CFloat ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleF32 :: 
    CFloat ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleF32 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    checked (Right (Linear.scale (coerce vArgument1 :: Float) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_scale_f64" ffiLinearScaleF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleF64 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (Right (Linear.scale (coerce vArgument1 :: Double) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_scale_rational" ffiLinearScaleRational :: 
    CString ->
    CString ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleRational :: 
    CString ->
    CString ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleRational vArgument1Numerator vArgument1Denominator vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1N <- readInteger vArgument1Numerator
    vArgument1D <- readInteger vArgument1Denominator
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) vArgument2 >>= mapM readInteger
    let vArgument2Value = rationalPairs vArgument2Raw
    checked (Right (Linear.scale (vArgument1N % vArgument1D) vArgument2Value)) $ \value -> do
        writeStrings (concatMap (\r -> [show (numerator r), show (denominator r)]) value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_scale_integer" ffiLinearScaleInteger :: 
    CString ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleInteger :: 
    CString ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleInteger vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- readInteger vArgument1
    vArgument2Raw <- peekArray (fromIntegral vArgument2Count) vArgument2
    vArgument2Value <- mapM readInteger vArgument2Raw
    checked (Right (Linear.scale vArgument1Value vArgument2Value)) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_scale_i8" ffiLinearScaleI8 :: 
    Int8 ->
    Ptr Int8 ->
    CSize ->
    Ptr (Ptr Int8) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleI8 :: 
    Int8 ->
    Ptr Int8 ->
    CSize ->
    Ptr (Ptr Int8) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleI8 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.scale (vArgument1 :: Int8) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Int8])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_scale_i16" ffiLinearScaleI16 :: 
    Int16 ->
    Ptr Int16 ->
    CSize ->
    Ptr (Ptr Int16) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleI16 :: 
    Int16 ->
    Ptr Int16 ->
    CSize ->
    Ptr (Ptr Int16) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleI16 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.scale (vArgument1 :: Int16) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Int16])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_scale_i32" ffiLinearScaleI32 :: 
    Int32 ->
    Ptr Int32 ->
    CSize ->
    Ptr (Ptr Int32) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleI32 :: 
    Int32 ->
    Ptr Int32 ->
    CSize ->
    Ptr (Ptr Int32) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleI32 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.scale (vArgument1 :: Int32) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Int32])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_scale_i64" ffiLinearScaleI64 :: 
    Int64 ->
    Ptr Int64 ->
    CSize ->
    Ptr (Ptr Int64) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleI64 :: 
    Int64 ->
    Ptr Int64 ->
    CSize ->
    Ptr (Ptr Int64) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleI64 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.scale (vArgument1 :: Int64) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Int64])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_scale_u8" ffiLinearScaleU8 :: 
    Word8 ->
    Ptr Word8 ->
    CSize ->
    Ptr (Ptr Word8) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleU8 :: 
    Word8 ->
    Ptr Word8 ->
    CSize ->
    Ptr (Ptr Word8) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleU8 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.scale (vArgument1 :: Word8) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Word8])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_scale_u16" ffiLinearScaleU16 :: 
    Word16 ->
    Ptr Word16 ->
    CSize ->
    Ptr (Ptr Word16) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleU16 :: 
    Word16 ->
    Ptr Word16 ->
    CSize ->
    Ptr (Ptr Word16) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleU16 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.scale (vArgument1 :: Word16) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Word16])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_scale_u32" ffiLinearScaleU32 :: 
    Word32 ->
    Ptr Word32 ->
    CSize ->
    Ptr (Ptr Word32) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleU32 :: 
    Word32 ->
    Ptr Word32 ->
    CSize ->
    Ptr (Ptr Word32) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleU32 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.scale (vArgument1 :: Word32) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Word32])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_scale_u64" ffiLinearScaleU64 :: 
    Word64 ->
    Ptr Word64 ->
    CSize ->
    Ptr (Ptr Word64) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleU64 :: 
    Word64 ->
    Ptr Word64 ->
    CSize ->
    Ptr (Ptr Word64) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleU64 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.scale (vArgument1 :: Word64) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Word64])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_scale_int" ffiLinearScaleInt :: 
    Int ->
    Ptr Int ->
    CSize ->
    Ptr (Ptr Int) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleInt :: 
    Int ->
    Ptr Int ->
    CSize ->
    Ptr (Ptr Int) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleInt vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.scale (vArgument1 :: Int) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_scale_word" ffiLinearScaleWord :: 
    Word ->
    Ptr Word ->
    CSize ->
    Ptr (Ptr Word) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleWord :: 
    Word ->
    Ptr Word ->
    CSize ->
    Ptr (Ptr Word) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleWord vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) vArgument2
    checked (Right (Linear.scale (vArgument1 :: Word) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Word])
        bracketOnError (newArray (strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_linear_scale_c64" ffiLinearScaleC64 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleC64 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleC64 vArgument10 vArgument11 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    let vArgument2Value = complexPairs vArgument2Raw
    checked (Right (Linear.scale ((coerce vArgument10 :: Float) :+ (coerce vArgument11 :: Float)) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_linear_scale_c128" ffiLinearScaleC128 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleC128 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiLinearScaleC128 vArgument10 vArgument11 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Raw <- peekArray (2 * fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    let vArgument2Value = complexPairs vArgument2Raw
    checked (Right (Linear.scale ((coerce vArgument10 :: Double) :+ (coerce vArgument11 :: Double)) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (concatMap (\z -> [realPart z, imagPart z]) value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_special_gamma_f64" ffiSpecialGammaF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialGammaF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialGammaF64 vX out0 = boundary $ do
    checked (Special.gamma
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_log_gamma_f64" ffiSpecialLogGammaF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialLogGammaF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialLogGammaF64 vX out0 = boundary $ do
    checked (Special.logGamma
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_log_beta_f64" ffiSpecialLogBetaF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialLogBetaF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialLogBetaF64 vA vB out0 = boundary $ do
    checked (Special.logBeta
        (coerce vA :: Double)
        (coerce vB :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_beta_f64" ffiSpecialBetaF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBetaF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBetaF64 vA vB out0 = boundary $ do
    checked (Special.beta
        (coerce vA :: Double)
        (coerce vB :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_gamma_p_f64" ffiSpecialGammaPF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialGammaPF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialGammaPF64 vA vX out0 = boundary $ do
    checked (Special.gammaP
        (coerce vA :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_gamma_q_f64" ffiSpecialGammaQF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialGammaQF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialGammaQF64 vA vX out0 = boundary $ do
    checked (Special.gammaQ
        (coerce vA :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_incomplete_gamma_f64" ffiSpecialIncompleteGammaF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialIncompleteGammaF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialIncompleteGammaF64 vA vX out0 = boundary $ do
    checked (Special.incompleteGamma
        (coerce vA :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_beta_i_f64" ffiSpecialBetaIF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBetaIF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBetaIF64 vA vB vX out0 = boundary $ do
    checked (Special.betaI
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_incomplete_beta_f64" ffiSpecialIncompleteBetaF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialIncompleteBetaF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialIncompleteBetaF64 vA vB vX out0 = boundary $ do
    checked (Special.incompleteBeta
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_digamma_f64" ffiSpecialDigammaF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialDigammaF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialDigammaF64 vX out0 = boundary $ do
    checked (Special.digamma
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_trigamma_f64" ffiSpecialTrigammaF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialTrigammaF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialTrigammaF64 vArgument1 out0 = boundary $ do
    checked (Special.trigamma
        (coerce vArgument1 :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_polygamma_f64" ffiSpecialPolygammaF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialPolygammaF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialPolygammaF64 vN vX out0 = boundary $ do
    checked (Special.polygamma
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_erf_f64" ffiSpecialErfF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialErfF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialErfF64 vX out0 = boundary $ do
    checked (Special.erf
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_erfc_f64" ffiSpecialErfcF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialErfcF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialErfcF64 vX out0 = boundary $ do
    checked (Special.erfc
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_erfcx_f64" ffiSpecialErfcxF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialErfcxF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialErfcxF64 vX out0 out1 = boundary $ do
    checked (Special.erfcx
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_normal_c_d_f_f64" ffiSpecialNormalCDFF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialNormalCDFF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialNormalCDFF64 vX out0 = boundary $ do
    checked (Special.normalCDF
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_normal_quantile_f64" ffiSpecialNormalQuantileF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialNormalQuantileF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialNormalQuantileF64 vP out0 = boundary $ do
    checked (Special.normalQuantile
        (coerce vP :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_inverse_erf_f64" ffiSpecialInverseErfF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialInverseErfF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialInverseErfF64 vX out0 = boundary $ do
    checked (Special.inverseErf
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_dawson_f64" ffiSpecialDawsonF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialDawsonF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialDawsonF64 vX out0 out1 = boundary $ do
    checked (Special.dawson
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_exponential_integral_f64" ffiSpecialExponentialIntegralF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialExponentialIntegralF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialExponentialIntegralF64 vN vX out0 out1 = boundary $ do
    checked (Special.exponentialIntegral
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_logarithmic_integral_f64" ffiSpecialLogarithmicIntegralF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialLogarithmicIntegralF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialLogarithmicIntegralF64 vX out0 out1 = boundary $ do
    checked (Special.logarithmicIntegral
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_sine_integral_f64" ffiSpecialSineIntegralF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialSineIntegralF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialSineIntegralF64 vX out0 out1 = boundary $ do
    checked (Special.sineIntegral
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_cosine_integral_f64" ffiSpecialCosineIntegralF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialCosineIntegralF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialCosineIntegralF64 vX out0 out1 = boundary $ do
    checked (Special.cosineIntegral
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_fresnel_f64" ffiSpecialFresnelF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialFresnelF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialFresnelF64 vX out0 out1 out2 out3 = boundary $ do
    checked (Special.fresnel
        (coerce vX :: Double)) $ \(first, second) -> do
        strict0 <- evaluate (Special.sfValue first)
        strict1 <- evaluate (Special.sfError first)
        strict2 <- evaluate (Special.sfValue second)
        strict3 <- evaluate (Special.sfError second)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)
        poke out2 (coerce strict2 :: CDouble)
        poke out3 (coerce strict3 :: CDouble)

foreign export ccall "hm_numeric_special_elliptic_f_f64" ffiSpecialEllipticFF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialEllipticFF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialEllipticFF64 vPhi vM out0 out1 = boundary $ do
    checked (Special.ellipticF
        (coerce vPhi :: Double)
        (coerce vM :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_elliptic_e_f64" ffiSpecialEllipticEF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialEllipticEF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialEllipticEF64 vPhi vM out0 out1 = boundary $ do
    checked (Special.ellipticE
        (coerce vPhi :: Double)
        (coerce vM :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_elliptic_pi_f64" ffiSpecialEllipticPiF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialEllipticPiF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialEllipticPiF64 vN vPhi vM out0 out1 = boundary $ do
    checked (Special.ellipticPi
        (coerce vN :: Double)
        (coerce vPhi :: Double)
        (coerce vM :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_jacobi_elliptic_f64" ffiSpecialJacobiEllipticF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialJacobiEllipticF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialJacobiEllipticF64 vU vM out0 out1 out2 = boundary $ do
    checked (Special.jacobiElliptic
        (coerce vU :: Double)
        (coerce vM :: Double)) $ \(first, second, third) -> do
        strict0 <- evaluate (first)
        strict1 <- evaluate (second)
        strict2 <- evaluate (third)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)
        poke out2 (coerce strict2 :: CDouble)

foreign export ccall "hm_numeric_special_bessel_j_f64" ffiSpecialBesselJF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBesselJF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBesselJF64 vN vX out0 = boundary $ do
    checked (Special.besselJ
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_bessel_y_f64" ffiSpecialBesselYF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBesselYF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBesselYF64 vN vX out0 = boundary $ do
    checked (Special.besselY
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_bessel_i_f64" ffiSpecialBesselIF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBesselIF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBesselIF64 vN vX out0 out1 = boundary $ do
    checked (Special.besselI
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_scaled_bessel_i_f64" ffiSpecialScaledBesselIF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialScaledBesselIF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialScaledBesselIF64 vN vX out0 out1 = boundary $ do
    checked (Special.scaledBesselI
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_bessel_k_f64" ffiSpecialBesselKF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBesselKF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBesselKF64 vN vX out0 out1 = boundary $ do
    checked (Special.besselK
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_scaled_bessel_k_f64" ffiSpecialScaledBesselKF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialScaledBesselKF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialScaledBesselKF64 vN vX out0 out1 = boundary $ do
    checked (Special.scaledBesselK
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_spherical_bessel_j_f64" ffiSpecialSphericalBesselJF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialSphericalBesselJF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialSphericalBesselJF64 vN vX out0 = boundary $ do
    checked (Special.sphericalBesselJ
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_spherical_bessel_y_f64" ffiSpecialSphericalBesselYF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialSphericalBesselYF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialSphericalBesselYF64 vN vX out0 = boundary $ do
    checked (Special.sphericalBesselY
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_airy_f64" ffiSpecialAiryF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialAiryF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialAiryF64 vX out0 out1 out2 out3 out4 out5 out6 out7 = boundary $ do
    checked (Special.airy
        (coerce vX :: Double)) $ \(first, second, third, fourth) -> do
        strict0 <- evaluate (Special.sfValue first)
        strict1 <- evaluate (Special.sfError first)
        strict2 <- evaluate (Special.sfValue second)
        strict3 <- evaluate (Special.sfError second)
        strict4 <- evaluate (Special.sfValue third)
        strict5 <- evaluate (Special.sfError third)
        strict6 <- evaluate (Special.sfValue fourth)
        strict7 <- evaluate (Special.sfError fourth)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)
        poke out2 (coerce strict2 :: CDouble)
        poke out3 (coerce strict3 :: CDouble)
        poke out4 (coerce strict4 :: CDouble)
        poke out5 (coerce strict5 :: CDouble)
        poke out6 (coerce strict6 :: CDouble)
        poke out7 (coerce strict7 :: CDouble)

foreign export ccall "hm_numeric_special_struve_f64" ffiSpecialStruveF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialStruveF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialStruveF64 vNu vX out0 out1 = boundary $ do
    checked (Special.struve
        (coerce vNu :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_hypergeometric_f64" ffiSpecialHypergeometricF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialHypergeometricF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialHypergeometricF64 vAs vAsCount vBs vBsCount vZ out0 out1 = boundary $ do
    vAsValue <- peekArray (fromIntegral vAsCount) (castPtr vAs :: Ptr Double)
    vBsValue <- peekArray (fromIntegral vBsCount) (castPtr vBs :: Ptr Double)
    checked (Special.hypergeometric
        vAsValue
        vBsValue
        (coerce vZ :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_hypergeometric1_f1_f64" ffiSpecialHypergeometric1F1F64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialHypergeometric1F1F64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialHypergeometric1F1F64 vA vB vZ out0 out1 = boundary $ do
    checked (Special.hypergeometric1F1
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vZ :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_hypergeometric2_f1_f64" ffiSpecialHypergeometric2F1F64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialHypergeometric2F1F64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialHypergeometric2F1F64 vA vB vC vZ out0 out1 = boundary $ do
    checked (Special.hypergeometric2F1
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vC :: Double)
        (coerce vZ :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_legendre_f64" ffiSpecialLegendreF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialLegendreF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialLegendreF64 vN vX out0 = boundary $ do
    checked (Special.legendre
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_associated_legendre_f64" ffiSpecialAssociatedLegendreF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialAssociatedLegendreF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialAssociatedLegendreF64 vL vM vX out0 = boundary $ do
    checked (Special.associatedLegendre
        (fromIntegral vL)
        (fromIntegral vM)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_hurwitz_zeta_f64" ffiSpecialHurwitzZetaF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialHurwitzZetaF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialHurwitzZetaF64 vS vQ out0 out1 = boundary $ do
    checked (Special.hurwitzZeta
        (coerce vS :: Double)
        (coerce vQ :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_riemann_zeta_f64" ffiSpecialRiemannZetaF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialRiemannZetaF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialRiemannZetaF64 vS out0 out1 = boundary $ do
    checked (Special.riemannZeta
        (coerce vS :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_polylogarithm_f64" ffiSpecialPolylogarithmF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialPolylogarithmF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialPolylogarithmF64 vS vZ out0 out1 = boundary $ do
    checked (Special.polylogarithm
        (coerce vS :: Double)
        (coerce vZ :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_dilogarithm_f64" ffiSpecialDilogarithmF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialDilogarithmF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialDilogarithmF64 vX out0 out1 = boundary $ do
    checked (Special.dilogarithm
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_lambert_w_f64" ffiSpecialLambertWF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialLambertWF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialLambertWF64 vBranch vX out0 out1 = boundary $ do
    checked (Special.lambertW
        (fromIntegral vBranch)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_debye_f64" ffiSpecialDebyeF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialDebyeF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialDebyeF64 vN vX out0 out1 = boundary $ do
    checked (Special.debye
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_clausen_f64" ffiSpecialClausenF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialClausenF64 :: 
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialClausenF64 vTheta out0 out1 = boundary $ do
    checked (Special.clausen
        (coerce vTheta :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_fermi_dirac_f64" ffiSpecialFermiDiracF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialFermiDiracF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialFermiDiracF64 vOrder vEta out0 out1 = boundary $ do
    checked (Special.fermiDirac
        (coerce vOrder :: Double)
        (coerce vEta :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_bose_einstein_f64" ffiSpecialBoseEinsteinF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBoseEinsteinF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBoseEinsteinF64 vOrder vEta out0 out1 = boundary $ do
    checked (Special.boseEinstein
        (coerce vOrder :: Double)
        (coerce vEta :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_coulomb_wave_f64" ffiSpecialCoulombWaveF64 :: 
    CPtrdiff ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialCoulombWaveF64 :: 
    CPtrdiff ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialCoulombWaveF64 vL vEta vRho out0 out1 out2 out3 = boundary $ do
    checked (Special.coulombWave
        (fromIntegral vL)
        (coerce vEta :: Double)
        (coerce vRho :: Double)) $ \(first, second) -> do
        strict0 <- evaluate (Special.sfValue first)
        strict1 <- evaluate (Special.sfError first)
        strict2 <- evaluate (Special.sfValue second)
        strict3 <- evaluate (Special.sfError second)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)
        poke out2 (coerce strict2 :: CDouble)
        poke out3 (coerce strict3 :: CDouble)

foreign export ccall "hm_numeric_special_gegenbauer_f64" ffiSpecialGegenbauerF64 :: 
    CPtrdiff ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialGegenbauerF64 :: 
    CPtrdiff ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialGegenbauerF64 vN vA vX out0 = boundary $ do
    checked (Special.gegenbauer
        (fromIntegral vN)
        (coerce vA :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_parabolic_cylinder_f64" ffiSpecialParabolicCylinderF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialParabolicCylinderF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialParabolicCylinderF64 vNu vX out0 out1 = boundary $ do
    checked (Special.parabolicCylinder
        (coerce vNu :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (Special.sfValue value)
        strict1 <- evaluate (Special.sfError value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_mathieu_f64" ffiSpecialMathieuF64 :: 
    CInt ->
    CPtrdiff ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialMathieuF64 :: 
    CInt ->
    CPtrdiff ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialMathieuF64 vEvenMode vN vQ vX out0 out1 out2 = boundary $ do
    checked (Special.mathieu
        (vEvenMode /= 0)
        (fromIntegral vN)
        (coerce vQ :: Double)
        (coerce vX :: Double)) $ \(first, second) -> do
        strict0 <- evaluate (first)
        strict1 <- evaluate (Special.sfValue second)
        strict2 <- evaluate (Special.sfError second)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)
        poke out2 (coerce strict2 :: CDouble)

foreign export ccall "hm_numeric_special_bernoulli_polynomial_f64" ffiSpecialBernoulliPolynomialF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBernoulliPolynomialF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialBernoulliPolynomialF64 vN vX out0 = boundary $ do
    checked (Special.bernoulliPolynomial
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_euler_polynomial_f64" ffiSpecialEulerPolynomialF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialEulerPolynomialF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialEulerPolynomialF64 vN vX out0 = boundary $ do
    checked (Special.eulerPolynomial
        (fromIntegral vN)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_wigner3j_f64" ffiSpecialWigner3JF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    IO CInt
ffiSpecialWigner3JF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    IO CInt
ffiSpecialWigner3JF64 vJ1 vJ2 vJ3 vM1 vM2 vM3 out0 = boundary $ do
    checked (Special.wigner3j
        (fromIntegral vJ1)
        (fromIntegral vJ2)
        (fromIntegral vJ3)
        (fromIntegral vM1)
        (fromIntegral vM2)
        (fromIntegral vM3)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_wigner6j_f64" ffiSpecialWigner6JF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    IO CInt
ffiSpecialWigner6JF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    IO CInt
ffiSpecialWigner6JF64 vA vB vC vD vE vF out0 = boundary $ do
    checked (Special.wigner6j
        (fromIntegral vA)
        (fromIntegral vB)
        (fromIntegral vC)
        (fromIntegral vD)
        (fromIntegral vE)
        (fromIntegral vF)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_wigner9j_f64" ffiSpecialWigner9JF64 :: 
    Ptr CPtrdiff ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiSpecialWigner9JF64 :: 
    Ptr CPtrdiff ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiSpecialWigner9JF64 vJs vJsCount out0 = boundary $ do
    vJsRaw <- peekArray (fromIntegral vJsCount) vJs
    let vJsValue = map fromIntegral vJsRaw
    checked (Special.wigner9j
        vJsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_special_clebsch_gordan_f64" ffiSpecialClebschGordanF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    IO CInt
ffiSpecialClebschGordanF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    IO CInt
ffiSpecialClebschGordanF64 vJ1 vM1 vJ2 vM2 vJ vM out0 = boundary $ do
    checked (Special.clebschGordan
        (fromIntegral vJ1)
        (fromIntegral vM1)
        (fromIntegral vJ2)
        (fromIntegral vM2)
        (fromIntegral vJ)
        (fromIntegral vM)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_complex_to_polar_f64" ffiComplexToPolarF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexToPolarF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexToPolarF64 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Complex.toPolar
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \(first, second) -> do
        strict0 <- evaluate (first)
        strict1 <- evaluate (second)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_probability_gamma_poisson_update_f64" ffiProbabilityGammaPoissonUpdateF64 :: 
    CDouble ->
    CDouble ->
    Ptr CPtrdiff ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiProbabilityGammaPoissonUpdateF64 :: 
    CDouble ->
    CDouble ->
    Ptr CPtrdiff ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiProbabilityGammaPoissonUpdateF64 vShapePrior vRatePrior vXs vXsCount out0 out1 = boundary $ do
    vXsRaw <- peekArray (fromIntegral vXsCount) vXs
    let vXsValue = map fromIntegral vXsRaw
    checked (Probability.gammaPoissonUpdate
        (coerce vShapePrior :: Double)
        (coerce vRatePrior :: Double)
        vXsValue) $ \(first, second) -> do
        strict0 <- evaluate (first)
        strict1 <- evaluate (second)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_probability_normal_normal_update_f64" ffiProbabilityNormalNormalUpdateF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiProbabilityNormalNormalUpdateF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiProbabilityNormalNormalUpdateF64 vMu vPriorVariance vObservationVariance vXs vXsCount out0 out1 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Probability.normalNormalUpdate
        (coerce vMu :: Double)
        (coerce vPriorVariance :: Double)
        (coerce vObservationVariance :: Double)
        vXsValue) $ \(first, second) -> do
        strict0 <- evaluate (first)
        strict1 <- evaluate (second)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_probability_conditional_probability_f64" ffiProbabilityConditionalProbabilityF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiProbabilityConditionalProbabilityF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiProbabilityConditionalProbabilityF64 vJoint vGiven out0 = boundary $ do
    checked (Probability.conditionalProbability
        (coerce vJoint :: Double)
        (coerce vGiven :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_probability_bayes_f64" ffiProbabilityBayesF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiProbabilityBayesF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiProbabilityBayesF64 vPriors vPriorsCount vLikelihoods vLikelihoodsCount outData outCount = boundary $ do
    vPriorsValue <- peekArray (fromIntegral vPriorsCount) (castPtr vPriors :: Ptr Double)
    vLikelihoodsValue <- peekArray (fromIntegral vLikelihoodsCount) (castPtr vLikelihoods :: Ptr Double)
    checked (Probability.bayes vPriorsValue vLikelihoodsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_probability_multinomial_p_m_f_f64" ffiProbabilityMultinomialPMFF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CPtrdiff ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiProbabilityMultinomialPMFF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CPtrdiff ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiProbabilityMultinomialPMFF64 vPs vPsCount vCounts vCountsCount out0 = boundary $ do
    vPsValue <- peekArray (fromIntegral vPsCount) (castPtr vPs :: Ptr Double)
    vCountsRaw <- peekArray (fromIntegral vCountsCount) vCounts
    let vCountsValue = map fromIntegral vCountsRaw
    checked (Probability.multinomialPMF
        vPsValue
        vCountsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_probability_dirichlet_density_f64" ffiProbabilityDirichletDensityF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiProbabilityDirichletDensityF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiProbabilityDirichletDensityF64 vAs vAsCount vXs vXsCount out0 = boundary $ do
    vAsValue <- peekArray (fromIntegral vAsCount) (castPtr vAs :: Ptr Double)
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Probability.dirichletDensity
        vAsValue
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_complex_complex_f64" ffiComplexComplexF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexComplexF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexComplexF64 vReal vImaginary out0 out1 = boundary $ do
    checked (Complex.complex
        (coerce vReal :: Double)
        (coerce vImaginary :: Double)) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_complex_reciprocal_f64" ffiComplexReciprocalF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexReciprocalF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexReciprocalF64 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Complex.reciprocal
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_complex_add_f64" ffiComplexAddF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexAddF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexAddF64 vA0 vA1 vB0 vB1 out0 out1 = boundary $ do
    checked (Complex.add
        ((coerce vA0 :: Double) :+ (coerce vA1 :: Double))
        ((coerce vB0 :: Double) :+ (coerce vB1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_complex_subtract_complex_f64" ffiComplexSubtractComplexF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexSubtractComplexF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexSubtractComplexF64 vA0 vA1 vB0 vB1 out0 out1 = boundary $ do
    checked (Complex.subtractComplex
        ((coerce vA0 :: Double) :+ (coerce vA1 :: Double))
        ((coerce vB0 :: Double) :+ (coerce vB1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_complex_multiply_f64" ffiComplexMultiplyF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexMultiplyF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexMultiplyF64 vA0 vA1 vB0 vB1 out0 out1 = boundary $ do
    checked (Complex.multiply
        ((coerce vA0 :: Double) :+ (coerce vA1 :: Double))
        ((coerce vB0 :: Double) :+ (coerce vB1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_complex_divide_f64" ffiComplexDivideF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexDivideF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexDivideF64 vA0 vA1 vB0 vB1 out0 out1 = boundary $ do
    checked (Complex.divide
        ((coerce vA0 :: Double) :+ (coerce vA1 :: Double))
        ((coerce vB0 :: Double) :+ (coerce vB1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_complex_power_f64" ffiComplexPowerF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexPowerF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexPowerF64 vA0 vA1 vB0 vB1 out0 out1 = boundary $ do
    checked (Complex.power
        ((coerce vA0 :: Double) :+ (coerce vA1 :: Double))
        ((coerce vB0 :: Double) :+ (coerce vB1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_complex_from_polar_f64" ffiComplexFromPolarF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexFromPolarF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexFromPolarF64 vRadius vAngle out0 out1 = boundary $ do
    checked (Complex.fromPolar
        (coerce vRadius :: Double)
        (coerce vAngle :: Double)) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_complex_rotate_f64" ffiComplexRotateF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexRotateF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiComplexRotateF64 vAngle vZ0 vZ1 out0 out1 = boundary $ do
    checked (Complex.rotate
        (coerce vAngle :: Double)
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_hankel_f64" ffiSpecialHankelF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialHankelF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialHankelF64 vKind vOrder vX out0 out1 = boundary $ do
    checked (Special.hankel
        (fromIntegral vKind)
        (fromIntegral vOrder)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_spherical_harmonic_f64" ffiSpecialSphericalHarmonicF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialSphericalHarmonicF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialSphericalHarmonicF64 vDegree vOrder vTheta vPhi out0 out1 = boundary $ do
    checked (Special.sphericalHarmonic
        (fromIntegral vDegree)
        (fromIntegral vOrder)
        (coerce vTheta :: Double)
        (coerce vPhi :: Double)) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_special_complex1_f1_f64" ffiSpecialComplex1F1F64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialComplex1F1F64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiSpecialComplex1F1F64 vA0 vA1 vB0 vB1 vZ0 vZ1 out0 out1 = boundary $ do
    checked (Special.complex1F1
        ((coerce vA0 :: Double) :+ (coerce vA1 :: Double))
        ((coerce vB0 :: Double) :+ (coerce vB1 :: Double))
        ((coerce vZ0 :: Double) :+ (coerce vZ1 :: Double))) $ \value -> do
        strict0 <- evaluate (realPart value)
        strict1 <- evaluate (imagPart value)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_api_algebra_inner_product_f32" ffiApiAlgebraInnerProductF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiApiAlgebraInnerProductF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiApiAlgebraInnerProductF32 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    checked (APIAlgebra.innerProduct
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_api_algebra_inner_product_f64" ffiApiAlgebraInnerProductF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiApiAlgebraInnerProductF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiApiAlgebraInnerProductF64 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (APIAlgebra.innerProduct
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_algorithms_lower_bound_f32" ffiAlgorithmsLowerBoundF32 :: 
    CFloat ->
    Ptr CFloat ->
    CSize ->
    Ptr CPtrdiff ->
    IO CInt
ffiAlgorithmsLowerBoundF32 :: 
    CFloat ->
    Ptr CFloat ->
    CSize ->
    Ptr CPtrdiff ->
    IO CInt
ffiAlgorithmsLowerBoundF32 vX vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Float)
    checked (Algorithms.lowerBound
        (coerce vX :: Float)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (fromIntegral strict0)

foreign export ccall "hm_numeric_algorithms_lower_bound_f64" ffiAlgorithmsLowerBoundF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CPtrdiff ->
    IO CInt
ffiAlgorithmsLowerBoundF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CPtrdiff ->
    IO CInt
ffiAlgorithmsLowerBoundF64 vX vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Algorithms.lowerBound
        (coerce vX :: Double)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (fromIntegral strict0)

foreign export ccall "hm_numeric_algorithms_upper_bound_f32" ffiAlgorithmsUpperBoundF32 :: 
    CFloat ->
    Ptr CFloat ->
    CSize ->
    Ptr CPtrdiff ->
    IO CInt
ffiAlgorithmsUpperBoundF32 :: 
    CFloat ->
    Ptr CFloat ->
    CSize ->
    Ptr CPtrdiff ->
    IO CInt
ffiAlgorithmsUpperBoundF32 vX vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Float)
    checked (Algorithms.upperBound
        (coerce vX :: Float)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (fromIntegral strict0)

foreign export ccall "hm_numeric_algorithms_upper_bound_f64" ffiAlgorithmsUpperBoundF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CPtrdiff ->
    IO CInt
ffiAlgorithmsUpperBoundF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CPtrdiff ->
    IO CInt
ffiAlgorithmsUpperBoundF64 vX vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Algorithms.upperBound
        (coerce vX :: Double)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (fromIntegral strict0)

foreign export ccall "hm_numeric_algorithms_quickselect_f32" ffiAlgorithmsQuickselectF32 :: 
    CPtrdiff ->
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiAlgorithmsQuickselectF32 :: 
    CPtrdiff ->
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiAlgorithmsQuickselectF32 vK vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Float)
    checked (Algorithms.quickselect
        (fromIntegral vK)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_algorithms_quickselect_f64" ffiAlgorithmsQuickselectF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiAlgorithmsQuickselectF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiAlgorithmsQuickselectF64 vK vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Algorithms.quickselect
        (fromIntegral vK)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_algorithms_introselect_f32" ffiAlgorithmsIntroselectF32 :: 
    CPtrdiff ->
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiAlgorithmsIntroselectF32 :: 
    CPtrdiff ->
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiAlgorithmsIntroselectF32 vK vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Float)
    checked (Algorithms.introselect
        (fromIntegral vK)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_algorithms_introselect_f64" ffiAlgorithmsIntroselectF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiAlgorithmsIntroselectF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiAlgorithmsIntroselectF64 vK vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Algorithms.introselect
        (fromIntegral vK)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_algorithms_partial_sort_f32" ffiAlgorithmsPartialSortF32 :: 
    CPtrdiff ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsPartialSortF32 :: 
    CPtrdiff ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsPartialSortF32 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    checked (Algorithms.partialSort (fromIntegral vArgument1) vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_partial_sort_f64" ffiAlgorithmsPartialSortF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsPartialSortF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsPartialSortF64 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (Algorithms.partialSort (fromIntegral vArgument1) vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_merge_sort_f32" ffiAlgorithmsMergeSortF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsMergeSortF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsMergeSortF32 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Algorithms.mergeSort vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_merge_sort_f64" ffiAlgorithmsMergeSortF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsMergeSortF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsMergeSortF64 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Algorithms.mergeSort vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_quicksort_f32" ffiAlgorithmsQuicksortF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsQuicksortF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsQuicksortF32 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Algorithms.quicksort vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_quicksort_f64" ffiAlgorithmsQuicksortF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsQuicksortF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsQuicksortF64 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Algorithms.quicksort vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_heapsort_f32" ffiAlgorithmsHeapsortF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsHeapsortF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsHeapsortF32 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Algorithms.heapsort vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_heapsort_f64" ffiAlgorithmsHeapsortF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsHeapsortF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsHeapsortF64 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Algorithms.heapsort vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_introsort_f32" ffiAlgorithmsIntrosortF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsIntrosortF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsIntrosortF32 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Algorithms.introsort vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_introsort_f64" ffiAlgorithmsIntrosortF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsIntrosortF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsIntrosortF64 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Algorithms.introsort vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_counting_sort" ffiAlgorithmsCountingSort :: 
    CPtrdiff ->
    Ptr CPtrdiff ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsCountingSort :: 
    CPtrdiff ->
    Ptr CPtrdiff ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsCountingSort vBudget vXs vXsCount outData outCount = boundary $ do
    vXsRaw <- peekArray (fromIntegral vXsCount) vXs
    let vXsValue = map fromIntegral vXsRaw
    checked (Algorithms.countingSort (fromIntegral vBudget) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (map (fromIntegral :: Int -> CPtrdiff) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_radix_sort" ffiAlgorithmsRadixSort :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsRadixSort :: 
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsRadixSort vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Raw <- peekArray (fromIntegral vArgument1Count) vArgument1
    vArgument1Value <- mapM readInteger vArgument1Raw
    checked (Right (Algorithms.radixSort vArgument1Value)) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_algorithms_bucket_sort_f64" ffiAlgorithmsBucketSortF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsBucketSortF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsBucketSortF64 vBuckets vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Algorithms.bucketSort (fromIntegral vBuckets) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_argsort_f32" ffiAlgorithmsArgsortF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsArgsortF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsArgsortF32 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Algorithms.argsort vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (map (fromIntegral :: Int -> CPtrdiff) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_argsort_f64" ffiAlgorithmsArgsortF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsArgsortF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsArgsortF64 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Algorithms.argsort vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (map (fromIntegral :: Int -> CPtrdiff) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_top_k_f32" ffiAlgorithmsTopKF32 :: 
    CPtrdiff ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsTopKF32 :: 
    CPtrdiff ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsTopKF32 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    checked (Algorithms.topK (fromIntegral vArgument1) vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_top_k_f64" ffiAlgorithmsTopKF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsTopKF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsTopKF64 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (Algorithms.topK (fromIntegral vArgument1) vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_quantile_select_f64" ffiAlgorithmsQuantileSelectF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiAlgorithmsQuantileSelectF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiAlgorithmsQuantileSelectF64 vQ vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Algorithms.quantileSelect
        (coerce vQ :: Double)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_algorithms_deduplicate_f32" ffiAlgorithmsDeduplicateF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsDeduplicateF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsDeduplicateF32 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Algorithms.deduplicate vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_deduplicate_f64" ffiAlgorithmsDeduplicateF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsDeduplicateF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsDeduplicateF64 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Algorithms.deduplicate vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_prefix_sums_f32" ffiAlgorithmsPrefixSumsF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsPrefixSumsF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsPrefixSumsF32 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Algorithms.prefixSums vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_prefix_sums_f64" ffiAlgorithmsPrefixSumsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsPrefixSumsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsPrefixSumsF64 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Algorithms.prefixSums vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_suffix_sums_f32" ffiAlgorithmsSuffixSumsF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsSuffixSumsF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsSuffixSumsF32 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Algorithms.suffixSums vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_suffix_sums_f64" ffiAlgorithmsSuffixSumsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsSuffixSumsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsSuffixSumsF64 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Algorithms.suffixSums vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_difference_array_f32" ffiAlgorithmsDifferenceArrayF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsDifferenceArrayF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsDifferenceArrayF32 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Algorithms.differenceArray vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_difference_array_f64" ffiAlgorithmsDifferenceArrayF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsDifferenceArrayF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsDifferenceArrayF64 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Algorithms.differenceArray vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_apply_differences_f32" ffiAlgorithmsApplyDifferencesF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsApplyDifferencesF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsApplyDifferencesF32 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Algorithms.applyDifferences vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_apply_differences_f64" ffiAlgorithmsApplyDifferencesF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsApplyDifferencesF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsApplyDifferencesF64 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Algorithms.applyDifferences vArgument1Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_algorithms_binary_lift" ffiAlgorithmsBinaryLift :: 
    Ptr CPtrdiff ->
    CSize ->
    CString ->
    CPtrdiff ->
    Ptr CPtrdiff ->
    IO CInt
ffiAlgorithmsBinaryLift :: 
    Ptr CPtrdiff ->
    CSize ->
    CString ->
    CPtrdiff ->
    Ptr CPtrdiff ->
    IO CInt
ffiAlgorithmsBinaryLift vNext vNextCount vSteps vStart out0 = boundary $ do
    vNextRaw <- peekArray (fromIntegral vNextCount) vNext
    let vNextValue = map fromIntegral vNextRaw
    vStepsValue <- readInteger vSteps
    checked (Algorithms.binaryLift
        vNextValue
        vStepsValue
        (fromIntegral vStart)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (fromIntegral strict0)

foreign export ccall "hm_numeric_algorithms_polynomial_hash" ffiAlgorithmsPolynomialHash :: 
    CString ->
    CString ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiAlgorithmsPolynomialHash :: 
    CString ->
    CString ->
    Ptr CString ->
    CSize ->
    Ptr CString ->
    IO CInt
ffiAlgorithmsPolynomialHash vBase vModulus vXs vXsCount out0 = boundary $ do
    vBaseValue <- readInteger vBase
    vModulusValue <- readInteger vModulus
    vXsRaw <- peekArray (fromIntegral vXsCount) vXs
    vXsValue <- mapM readInteger vXsRaw
    checked (Algorithms.polynomialHash
        vBaseValue
        vModulusValue
        vXsValue) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_algorithms_rolling_hashes" ffiAlgorithmsRollingHashes :: 
    CString ->
    CString ->
    CPtrdiff ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsRollingHashes :: 
    CString ->
    CString ->
    CPtrdiff ->
    Ptr CString ->
    CSize ->
    Ptr (Ptr CString) ->
    Ptr CSize ->
    IO CInt
ffiAlgorithmsRollingHashes vBase vModulus vWidth vXs vXsCount outData outCount = boundary $ do
    vBaseValue <- readInteger vBase
    vModulusValue <- readInteger vModulus
    vXsRaw <- peekArray (fromIntegral vXsCount) vXs
    vXsValue <- mapM readInteger vXsRaw
    checked (Algorithms.rollingHashes vBaseValue vModulusValue (fromIntegral vWidth) vXsValue) $ \value -> do
        writeStrings (map show value) $ \textPointers ->
            bracketOnError (newArray textPointers) free $ \pointer -> do
                poke outData pointer
                poke outCount (fromIntegral (length value))

foreign export ccall "hm_numeric_datastructure_monotonic_minima_f32" ffiDatastructureMonotonicMinimaF32 :: 
    CPtrdiff ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiDatastructureMonotonicMinimaF32 :: 
    CPtrdiff ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiDatastructureMonotonicMinimaF32 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    checked (DataStructure.monotonicMinima (fromIntegral vArgument1) vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_datastructure_monotonic_minima_f64" ffiDatastructureMonotonicMinimaF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDatastructureMonotonicMinimaF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDatastructureMonotonicMinimaF64 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (DataStructure.monotonicMinima (fromIntegral vArgument1) vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_deeplearning_core_log_softmax_f64" ffiDeeplearningCoreLogSoftmaxF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDeeplearningCoreLogSoftmaxF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDeeplearningCoreLogSoftmaxF64 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (DeepLearningCore.logSoftmax vArgument1Value) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_deeplearning_core_softmax_f64" ffiDeeplearningCoreSoftmaxF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDeeplearningCoreSoftmaxF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDeeplearningCoreSoftmaxF64 vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (DeepLearningCore.softmax vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_deeplearning_core_sparsemax_f64" ffiDeeplearningCoreSparsemaxF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDeeplearningCoreSparsemaxF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDeeplearningCoreSparsemaxF64 vArgument1 vArgument1Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (DeepLearningCore.sparsemax vArgument1Value) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_deeplearning_core_gated_linear_unit_f64" ffiDeeplearningCoreGatedLinearUnitF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDeeplearningCoreGatedLinearUnitF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDeeplearningCoreGatedLinearUnitF64 vValues vValuesCount vGate vGateCount outData outCount = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    vGateValue <- peekArray (fromIntegral vGateCount) (castPtr vGate :: Ptr Double)
    checked (DeepLearningCore.gatedLinearUnit vValuesValue vGateValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_deeplearning_core_categorical_cross_entropy_logits_f64" ffiDeeplearningCoreCategoricalCrossEntropyLogitsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningCoreCategoricalCrossEntropyLogitsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningCoreCategoricalCrossEntropyLogitsF64 vTarget vTargetCount vLogits vLogitsCount out0 = boundary $ do
    vTargetValue <- peekArray (fromIntegral vTargetCount) (castPtr vTarget :: Ptr Double)
    vLogitsValue <- peekArray (fromIntegral vLogitsCount) (castPtr vLogits :: Ptr Double)
    checked (DeepLearningCore.categoricalCrossEntropyLogits
        vTargetValue
        vLogitsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_deeplearning_core_regularization_f64" ffiDeeplearningCoreRegularizationF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningCoreRegularizationF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningCoreRegularizationF64 vL1 vL2 vWeights vWeightsCount out0 = boundary $ do
    vWeightsValue <- peekArray (fromIntegral vWeightsCount) (castPtr vWeights :: Ptr Double)
    checked (DeepLearningCore.regularization
        (coerce vL1 :: Double)
        (coerce vL2 :: Double)
        vWeightsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_deeplearning_core_contrastive_loss_f64" ffiDeeplearningCoreContrastiveLossF64 :: 
    CDouble ->
    CInt ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningCoreContrastiveLossF64 :: 
    CDouble ->
    CInt ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningCoreContrastiveLossF64 vMargin vSimilar vA vACount vB vBCount out0 = boundary $ do
    vAValue <- peekArray (fromIntegral vACount) (castPtr vA :: Ptr Double)
    vBValue <- peekArray (fromIntegral vBCount) (castPtr vB :: Ptr Double)
    checked (DeepLearningCore.contrastiveLoss
        (coerce vMargin :: Double)
        (vSimilar /= 0)
        vAValue
        vBValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_deeplearning_core_triplet_loss_f64" ffiDeeplearningCoreTripletLossF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningCoreTripletLossF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningCoreTripletLossF64 vMargin vAnchor vAnchorCount vPositive vPositiveCount vNegative vNegativeCount out0 = boundary $ do
    vAnchorValue <- peekArray (fromIntegral vAnchorCount) (castPtr vAnchor :: Ptr Double)
    vPositiveValue <- peekArray (fromIntegral vPositiveCount) (castPtr vPositive :: Ptr Double)
    vNegativeValue <- peekArray (fromIntegral vNegativeCount) (castPtr vNegative :: Ptr Double)
    checked (DeepLearningCore.tripletLoss
        (coerce vMargin :: Double)
        vAnchorValue
        vPositiveValue
        vNegativeValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_deeplearning_core_focal_loss_f64" ffiDeeplearningCoreFocalLossF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningCoreFocalLossF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningCoreFocalLossF64 vAlpha vGamma vTarget vTargetCount vPrediction vPredictionCount out0 = boundary $ do
    vTargetValue <- peekArray (fromIntegral vTargetCount) (castPtr vTarget :: Ptr Double)
    vPredictionValue <- peekArray (fromIntegral vPredictionCount) (castPtr vPrediction :: Ptr Double)
    checked (DeepLearningCore.focalLoss
        (coerce vAlpha :: Double)
        (coerce vGamma :: Double)
        vTargetValue
        vPredictionValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_deeplearning_core_dice_loss_f64" ffiDeeplearningCoreDiceLossF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningCoreDiceLossF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningCoreDiceLossF64 vSmooth vTarget vTargetCount vPrediction vPredictionCount out0 = boundary $ do
    vTargetValue <- peekArray (fromIntegral vTargetCount) (castPtr vTarget :: Ptr Double)
    vPredictionValue <- peekArray (fromIntegral vPredictionCount) (castPtr vPrediction :: Ptr Double)
    checked (DeepLearningCore.diceLoss
        (coerce vSmooth :: Double)
        vTargetValue
        vPredictionValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_deeplearning_core_iou_loss_f64" ffiDeeplearningCoreIouLossF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningCoreIouLossF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningCoreIouLossF64 vSmooth vTarget vTargetCount vPrediction vPredictionCount out0 = boundary $ do
    vTargetValue <- peekArray (fromIntegral vTargetCount) (castPtr vTarget :: Ptr Double)
    vPredictionValue <- peekArray (fromIntegral vPredictionCount) (castPtr vPrediction :: Ptr Double)
    checked (DeepLearningCore.iouLoss
        (coerce vSmooth :: Double)
        vTargetValue
        vPredictionValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_deeplearning_metrics_perplexity_f64" ffiDeeplearningMetricsPerplexityF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningMetricsPerplexityF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningMetricsPerplexityF64 vLogs vLogsCount out0 = boundary $ do
    vLogsValue <- peekArray (fromIntegral vLogsCount) (castPtr vLogs :: Ptr Double)
    checked (DeepLearningMetrics.perplexity
        vLogsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_deeplearning_metrics_margin_ranking_loss_f64" ffiDeeplearningMetricsMarginRankingLossF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningMetricsMarginRankingLossF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningMetricsMarginRankingLossF64 vMargin vLabels vLabelsCount vLeft vLeftCount vRight vRightCount out0 = boundary $ do
    vLabelsValue <- peekArray (fromIntegral vLabelsCount) (castPtr vLabels :: Ptr Double)
    vLeftValue <- peekArray (fromIntegral vLeftCount) (castPtr vLeft :: Ptr Double)
    vRightValue <- peekArray (fromIntegral vRightCount) (castPtr vRight :: Ptr Double)
    checked (DeepLearningMetrics.marginRankingLoss
        (coerce vMargin :: Double)
        vLabelsValue
        vLeftValue
        vRightValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_deeplearning_precision_gradient_norm_f64" ffiDeeplearningPrecisionGradientNormF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningPrecisionGradientNormF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiDeeplearningPrecisionGradientNormF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (DeepLearningPrecision.gradientNorm
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_deeplearning_precision_clip_gradients_f64" ffiDeeplearningPrecisionClipGradientsF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDeeplearningPrecisionClipGradientsF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDeeplearningPrecisionClipGradientsF64 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (DeepLearningPrecision.clipGradients (coerce vArgument1 :: Double) vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_discrete_set_union_f32" ffiDiscreteSetUnionF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSetUnionF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSetUnionF32 vA vACount vB vBCount outData outCount = boundary $ do
    vAValue <- peekArray (fromIntegral vACount) (castPtr vA :: Ptr Float)
    vBValue <- peekArray (fromIntegral vBCount) (castPtr vB :: Ptr Float)
    checked (Right (Discrete.setUnion vAValue vBValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_discrete_set_union_f64" ffiDiscreteSetUnionF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSetUnionF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSetUnionF64 vA vACount vB vBCount outData outCount = boundary $ do
    vAValue <- peekArray (fromIntegral vACount) (castPtr vA :: Ptr Double)
    vBValue <- peekArray (fromIntegral vBCount) (castPtr vB :: Ptr Double)
    checked (Right (Discrete.setUnion vAValue vBValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_discrete_set_intersection_f32" ffiDiscreteSetIntersectionF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSetIntersectionF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSetIntersectionF32 vA vACount vB vBCount outData outCount = boundary $ do
    vAValue <- peekArray (fromIntegral vACount) (castPtr vA :: Ptr Float)
    vBValue <- peekArray (fromIntegral vBCount) (castPtr vB :: Ptr Float)
    checked (Right (Discrete.setIntersection vAValue vBValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_discrete_set_intersection_f64" ffiDiscreteSetIntersectionF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSetIntersectionF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSetIntersectionF64 vA vACount vB vBCount outData outCount = boundary $ do
    vAValue <- peekArray (fromIntegral vACount) (castPtr vA :: Ptr Double)
    vBValue <- peekArray (fromIntegral vBCount) (castPtr vB :: Ptr Double)
    checked (Right (Discrete.setIntersection vAValue vBValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_discrete_set_difference_f32" ffiDiscreteSetDifferenceF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSetDifferenceF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSetDifferenceF32 vA vACount vB vBCount outData outCount = boundary $ do
    vAValue <- peekArray (fromIntegral vACount) (castPtr vA :: Ptr Float)
    vBValue <- peekArray (fromIntegral vBCount) (castPtr vB :: Ptr Float)
    checked (Right (Discrete.setDifference vAValue vBValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_discrete_set_difference_f64" ffiDiscreteSetDifferenceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSetDifferenceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSetDifferenceF64 vA vACount vB vBCount outData outCount = boundary $ do
    vAValue <- peekArray (fromIntegral vACount) (castPtr vA :: Ptr Double)
    vBValue <- peekArray (fromIntegral vBCount) (castPtr vB :: Ptr Double)
    checked (Right (Discrete.setDifference vAValue vBValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_discrete_symmetric_difference_f32" ffiDiscreteSymmetricDifferenceF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSymmetricDifferenceF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr (Ptr CFloat) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSymmetricDifferenceF32 vA vACount vB vBCount outData outCount = boundary $ do
    vAValue <- peekArray (fromIntegral vACount) (castPtr vA :: Ptr Float)
    vBValue <- peekArray (fromIntegral vBCount) (castPtr vB :: Ptr Float)
    checked (Right (Discrete.symmetricDifference vAValue vBValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Float])
        bracketOnError (newArray (map (coerce :: Float -> CFloat) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_discrete_symmetric_difference_f64" ffiDiscreteSymmetricDifferenceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSymmetricDifferenceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiDiscreteSymmetricDifferenceF64 vA vACount vB vBCount outData outCount = boundary $ do
    vAValue <- peekArray (fromIntegral vACount) (castPtr vA :: Ptr Double)
    vBValue <- peekArray (fromIntegral vBCount) (castPtr vB :: Ptr Double)
    checked (Right (Discrete.symmetricDifference vAValue vBValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_fourier_frequencies_f64" ffiFourierFrequenciesF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierFrequenciesF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierFrequenciesF64 vN vSpacing outData outCount = boundary $ do
    checked (Fourier.frequencies (fromIntegral vN) (coerce vSpacing :: Double)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_fourier_fft_shift_f64" ffiFourierFftShiftF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierFftShiftF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierFftShiftF64 vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Right (Fourier.fftShift vXsValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_fourier_ifft_shift_f64" ffiFourierIfftShiftF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierIfftShiftF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierIfftShiftF64 vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Right (Fourier.ifftShift vXsValue)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_fourier_hartley_f64" ffiFourierHartleyF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierHartleyF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierHartleyF64 vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Fourier.hartley vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_fourier_periodogram_f64" ffiFourierPeriodogramF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierPeriodogramF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierPeriodogramF64 vRate vWindow vWindowCount vXs vXsCount outData outCount = boundary $ do
    vWindowValue <- peekArray (fromIntegral vWindowCount) (castPtr vWindow :: Ptr Double)
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Fourier.periodogram (coerce vRate :: Double) vWindowValue vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_fourier_welch_f64" ffiFourierWelchF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierWelchF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierWelchF64 vRate vWindow vWindowCount vHop vXs vXsCount outData outCount = boundary $ do
    vWindowValue <- peekArray (fromIntegral vWindowCount) (castPtr vWindow :: Ptr Double)
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Fourier.welch (coerce vRate :: Double) vWindowValue (fromIntegral vHop) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_fourier_cepstrum_f64" ffiFourierCepstrumF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierCepstrumF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierCepstrumF64 vFloorValue vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Fourier.cepstrum (coerce vFloorValue :: Double) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_fourier_hilbert_f64" ffiFourierHilbertF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierHilbertF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiFourierHilbertF64 vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Fourier.hilbert vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_geometry_primitives_hamming_distance_f32" ffiGeometryPrimitivesHammingDistanceF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr CPtrdiff ->
    IO CInt
ffiGeometryPrimitivesHammingDistanceF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    CSize ->
    Ptr CPtrdiff ->
    IO CInt
ffiGeometryPrimitivesHammingDistanceF32 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Float)
    checked (GeometryPrimitives.hammingDistance
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (fromIntegral strict0)

foreign export ccall "hm_numeric_geometry_primitives_hamming_distance_f64" ffiGeometryPrimitivesHammingDistanceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CPtrdiff ->
    IO CInt
ffiGeometryPrimitivesHammingDistanceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CPtrdiff ->
    IO CInt
ffiGeometryPrimitivesHammingDistanceF64 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (GeometryPrimitives.hammingDistance
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (fromIntegral strict0)

foreign export ccall "hm_numeric_geometry_primitives_jaccard_distance_f64" ffiGeometryPrimitivesJaccardDistanceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiGeometryPrimitivesJaccardDistanceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiGeometryPrimitivesJaccardDistanceF64 vArgument1 vArgument1Count vArgument2 vArgument2Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (GeometryPrimitives.jaccardDistance
        vArgument1Value
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_graph_core_finite_f64" ffiGraphCoreFiniteF64 :: 
    CDouble ->
    Ptr CInt ->
    IO CInt
ffiGraphCoreFiniteF64 :: 
    CDouble ->
    Ptr CInt ->
    IO CInt
ffiGraphCoreFiniteF64 vX out0 = boundary $ do
    checked (Right (GraphCore.finite
        (coerce vX :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (if strict0 then 1 else 0)

foreign export ccall "hm_numeric_image_color_srgb_to_linear_f64" ffiImageColorSrgbToLinearF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiImageColorSrgbToLinearF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiImageColorSrgbToLinearF64 vX out0 = boundary $ do
    checked (ImageColor.srgbToLinear
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_image_color_linear_to_srgb_f64" ffiImageColorLinearToSrgbF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiImageColorLinearToSrgbF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiImageColorLinearToSrgbF64 vX out0 = boundary $ do
    checked (ImageColor.linearToSrgb
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_interpolation_evaluate_chebyshev_f64" ffiInterpolationEvaluateChebyshevF64 :: 
    Ptr CDouble ->
    CSize ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiInterpolationEvaluateChebyshevF64 :: 
    Ptr CDouble ->
    CSize ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiInterpolationEvaluateChebyshevF64 vCs vCsCount vA vB vX out0 = boundary $ do
    vCsValue <- peekArray (fromIntegral vCsCount) (castPtr vCs :: Ptr Double)
    checked (Interpolation.evaluateChebyshev
        vCsValue
        (coerce vA :: Double)
        (coerce vB :: Double)
        (coerce vX :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_numeric_next_after_f32" ffiNumericNextAfterF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiNumericNextAfterF32 :: 
    CFloat ->
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiNumericNextAfterF32 vArgument1 vArgument2 out0 = boundary $ do
    checked (Right (Numeric.nextAfter
        (coerce vArgument1 :: Float)
        (coerce vArgument2 :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_numeric_next_after_f64" ffiNumericNextAfterF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiNumericNextAfterF64 :: 
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiNumericNextAfterF64 vArgument1 vArgument2 out0 = boundary $ do
    checked (Right (Numeric.nextAfter
        (coerce vArgument1 :: Double)
        (coerce vArgument2 :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_numeric_ldexp_f32" ffiNumericLdexpF32 :: 
    CFloat ->
    CPtrdiff ->
    Ptr CFloat ->
    IO CInt
ffiNumericLdexpF32 :: 
    CFloat ->
    CPtrdiff ->
    Ptr CFloat ->
    IO CInt
ffiNumericLdexpF32 vArgument1 vArgument2 out0 = boundary $ do
    checked (Right (Numeric.ldexp
        (coerce vArgument1 :: Float)
        (fromIntegral vArgument2))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_numeric_ldexp_f64" ffiNumericLdexpF64 :: 
    CDouble ->
    CPtrdiff ->
    Ptr CDouble ->
    IO CInt
ffiNumericLdexpF64 :: 
    CDouble ->
    CPtrdiff ->
    Ptr CDouble ->
    IO CInt
ffiNumericLdexpF64 vArgument1 vArgument2 out0 = boundary $ do
    checked (Right (Numeric.ldexp
        (coerce vArgument1 :: Double)
        (fromIntegral vArgument2))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_numeric_ulp_distance_f64" ffiNumericUlpDistanceF64 :: 
    CDouble ->
    CDouble ->
    Ptr CString ->
    IO CInt
ffiNumericUlpDistanceF64 :: 
    CDouble ->
    CDouble ->
    Ptr CString ->
    IO CInt
ffiNumericUlpDistanceF64 vA vB out0 = boundary $ do
    checked (Numeric.ulpDistance
        (coerce vA :: Double)
        (coerce vB :: Double)) $ \value -> do
        writeStrings [show (value)] $ \textPointers -> do
            poke out0 (textPointers !! 0)

foreign export ccall "hm_numeric_numeric_within_u_l_ps_f64" ffiNumericWithinULPsF64 :: 
    CString ->
    CDouble ->
    CDouble ->
    Ptr CInt ->
    IO CInt
ffiNumericWithinULPsF64 :: 
    CString ->
    CDouble ->
    CDouble ->
    Ptr CInt ->
    IO CInt
ffiNumericWithinULPsF64 vN vA vB out0 = boundary $ do
    vNValue <- readInteger vN
    checked (Right (Numeric.withinULPs
        vNValue
        (coerce vA :: Double)
        (coerce vB :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (if strict0 then 1 else 0)

foreign export ccall "hm_numeric_numeric_kahan_sum_f32" ffiNumericKahanSumF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiNumericKahanSumF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiNumericKahanSumF32 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Numeric.kahanSum
        vArgument1Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_numeric_kahan_sum_f64" ffiNumericKahanSumF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiNumericKahanSumF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiNumericKahanSumF64 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Numeric.kahanSum
        vArgument1Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_numeric_neumaier_sum_f32" ffiNumericNeumaierSumF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiNumericNeumaierSumF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiNumericNeumaierSumF32 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Numeric.neumaierSum
        vArgument1Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_numeric_neumaier_sum_f64" ffiNumericNeumaierSumF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiNumericNeumaierSumF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiNumericNeumaierSumF64 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Numeric.neumaierSum
        vArgument1Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_numeric_pairwise_sum_f32" ffiNumericPairwiseSumF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiNumericPairwiseSumF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiNumericPairwiseSumF32 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Right (Numeric.pairwiseSum
        vArgument1Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_numeric_pairwise_sum_f64" ffiNumericPairwiseSumF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiNumericPairwiseSumF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiNumericPairwiseSumF64 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Right (Numeric.pairwiseSum
        vArgument1Value)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_numeric_logsumexp_f32" ffiNumericLogsumexpF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiNumericLogsumexpF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiNumericLogsumexpF32 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Numeric.logsumexp
        vArgument1Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_numeric_logsumexp_f64" ffiNumericLogsumexpF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiNumericLogsumexpF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiNumericLogsumexpF64 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Numeric.logsumexp
        vArgument1Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_numeric_sum_error_bound_f32" ffiNumericSumErrorBoundF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiNumericSumErrorBoundF32 :: 
    Ptr CFloat ->
    CSize ->
    Ptr CFloat ->
    IO CInt
ffiNumericSumErrorBoundF32 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Float)
    checked (Numeric.sumErrorBound
        vArgument1Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_numeric_sum_error_bound_f64" ffiNumericSumErrorBoundF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiNumericSumErrorBoundF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiNumericSumErrorBoundF64 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (Numeric.sumErrorBound
        vArgument1Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_optimization_common_dot_f64" ffiOptimizationCommonDotF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiOptimizationCommonDotF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiOptimizationCommonDotF64 vA vACount vB vBCount out0 = boundary $ do
    vAValue <- peekArray (fromIntegral vACount) (castPtr vA :: Ptr Double)
    vBValue <- peekArray (fromIntegral vBCount) (castPtr vB :: Ptr Double)
    checked (Right (OptimizationCommon.dot
        vAValue
        vBValue)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_optimization_common_norm_f64" ffiOptimizationCommonNormF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiOptimizationCommonNormF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiOptimizationCommonNormF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Right (OptimizationCommon.norm
        vXsValue)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_optimization_common_add_f64" ffiOptimizationCommonAddF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiOptimizationCommonAddF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiOptimizationCommonAddF64 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (Right (OptimizationCommon.add vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_optimization_common_sub_f64" ffiOptimizationCommonSubF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiOptimizationCommonSubF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiOptimizationCommonSubF64 vArgument1 vArgument1Count vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (Right (OptimizationCommon.sub vArgument1Value vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_optimization_common_scale_f64" ffiOptimizationCommonScaleF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiOptimizationCommonScaleF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiOptimizationCommonScaleF64 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (Right (OptimizationCommon.scale (coerce vArgument1 :: Double) vArgument2Value)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_random_importance_f64" ffiRandomImportanceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiRandomImportanceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiRandomImportanceF64 vValues vValuesCount vWeights vWeightsCount out0 = boundary $ do
    vValuesValue <- peekArray (fromIntegral vValuesCount) (castPtr vValues :: Ptr Double)
    vWeightsValue <- peekArray (fromIntegral vWeightsCount) (castPtr vWeights :: Ptr Double)
    checked (Random.importance
        vValuesValue
        vWeightsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_random_halton_f64" ffiRandomHaltonF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiRandomHaltonF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiRandomHaltonF64 vDimension vIndex outData outCount = boundary $ do
    checked (Random.halton (fromIntegral vDimension) (fromIntegral vIndex)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_random_sobol_f64" ffiRandomSobolF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiRandomSobolF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiRandomSobolF64 vDimension vIndex outData outCount = boundary $ do
    checked (Random.sobol (fromIntegral vDimension) (fromIntegral vIndex)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_random_faure_f64" ffiRandomFaureF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiRandomFaureF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiRandomFaureF64 vD vIx outData outCount = boundary $ do
    checked (Random.faure (fromIntegral vD) (fromIntegral vIx)) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_convolution_f64" ffiSignalConvolutionF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalConvolutionF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalConvolutionF64 vXs vXsCount vYs vYsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    vYsValue <- peekArray (fromIntegral vYsCount) (castPtr vYs :: Ptr Double)
    checked (Signal.convolution vXsValue vYsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_circular_convolution_f64" ffiSignalCircularConvolutionF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalCircularConvolutionF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalCircularConvolutionF64 vX vXCount vY vYCount outData outCount = boundary $ do
    vXValue <- peekArray (fromIntegral vXCount) (castPtr vX :: Ptr Double)
    vYValue <- peekArray (fromIntegral vYCount) (castPtr vY :: Ptr Double)
    checked (Signal.circularConvolution vXValue vYValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_correlation_f64" ffiSignalCorrelationF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalCorrelationF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalCorrelationF64 vX vXCount vY vYCount outData outCount = boundary $ do
    vXValue <- peekArray (fromIntegral vXCount) (castPtr vX :: Ptr Double)
    vYValue <- peekArray (fromIntegral vYCount) (castPtr vY :: Ptr Double)
    checked (Signal.correlation vXValue vYValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_autocorrelation_f64" ffiSignalAutocorrelationF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalAutocorrelationF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalAutocorrelationF64 vX vXCount outData outCount = boundary $ do
    vXValue <- peekArray (fromIntegral vXCount) (castPtr vX :: Ptr Double)
    checked (Signal.autocorrelation vXValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_overlap_add_f64" ffiSignalOverlapAddF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalOverlapAddF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalOverlapAddF64 vBlock vKernel vKernelCount vXs vXsCount outData outCount = boundary $ do
    vKernelValue <- peekArray (fromIntegral vKernelCount) (castPtr vKernel :: Ptr Double)
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.overlapAdd (fromIntegral vBlock) vKernelValue vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_overlap_save_f64" ffiSignalOverlapSaveF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalOverlapSaveF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalOverlapSaveF64 vFftLength vKernel vKernelCount vXs vXsCount outData outCount = boundary $ do
    vKernelValue <- peekArray (fromIntegral vKernelCount) (castPtr vKernel :: Ptr Double)
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.overlapSave (fromIntegral vFftLength) vKernelValue vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_moving_average_f64" ffiSignalMovingAverageF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalMovingAverageF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalMovingAverageF64 vCount vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.movingAverage (fromIntegral vCount) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_median_filter_f64" ffiSignalMedianFilterF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalMedianFilterF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalMedianFilterF64 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (Signal.medianFilter (fromIntegral vArgument1) vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_gaussian_filter_f64" ffiSignalGaussianFilterF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalGaussianFilterF64 :: 
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalGaussianFilterF64 vWidth vSigma vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.gaussianFilter (fromIntegral vWidth) (coerce vSigma :: Double) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_savitzky_golay_f64" ffiSignalSavitzkyGolayF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalSavitzkyGolayF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalSavitzkyGolayF64 vWidth vDegree vDerivative vSpacing vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.savitzkyGolay (fromIntegral vWidth) (fromIntegral vDegree) (fromIntegral vDerivative) (coerce vSpacing :: Double) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_downsample_f64" ffiSignalDownsampleF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalDownsampleF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalDownsampleF64 vFactor vOffset vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.downsample (fromIntegral vFactor) (fromIntegral vOffset) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_upsample_f64" ffiSignalUpsampleF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalUpsampleF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalUpsampleF64 vFactor vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.upsample (fromIntegral vFactor) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_resample_polyphase_f64" ffiSignalResamplePolyphaseF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalResamplePolyphaseF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalResamplePolyphaseF64 vUp vDown vKernel vKernelCount vXs vXsCount outData outCount = boundary $ do
    vKernelValue <- peekArray (fromIntegral vKernelCount) (castPtr vKernel :: Ptr Double)
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.resamplePolyphase (fromIntegral vUp) (fromIntegral vDown) vKernelValue vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_resample_f64" ffiSignalResampleF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalResampleF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalResampleF64 vUp vDown vTaps vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.resample (fromIntegral vUp) (fromIntegral vDown) (fromIntegral vTaps) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_anti_alias_f64" ffiSignalAntiAliasF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalAntiAliasF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalAntiAliasF64 vFactor vTaps vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.antiAlias (fromIntegral vFactor) (fromIntegral vTaps) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_zero_crossings_f64" ffiSignalZeroCrossingsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalZeroCrossingsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalZeroCrossingsF64 vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.zeroCrossings vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_envelope_f64" ffiSignalEnvelopeF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalEnvelopeF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalEnvelopeF64 vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.envelope vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_unwrap_phase_f64" ffiSignalUnwrapPhaseF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalUnwrapPhaseF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalUnwrapPhaseF64 vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.unwrapPhase vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_detrend_f64" ffiSignalDetrendF64 :: 
    CInt ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalDetrendF64 :: 
    CInt ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalDetrendF64 vLinear vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.detrend (vLinear /= 0) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_normalize_f64" ffiSignalNormalizeF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalNormalizeF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalNormalizeF64 vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.normalize vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_smooth_f64" ffiSignalSmoothF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalSmoothF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiSignalSmoothF64 vArgument1 vArgument2 vArgument2Count outData outCount = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (Signal.smooth (fromIntegral vArgument1) vArgument2Value) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_signal_noise_estimate_f64" ffiSignalNoiseEstimateF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiSignalNoiseEstimateF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiSignalNoiseEstimateF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.noiseEstimate
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_signal_signal_to_noise_f64" ffiSignalSignalToNoiseF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiSignalSignalToNoiseF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiSignalSignalToNoiseF64 vSignal vSignalCount vNoise vNoiseCount out0 = boundary $ do
    vSignalValue <- peekArray (fromIntegral vSignalCount) (castPtr vSignal :: Ptr Double)
    vNoiseValue <- peekArray (fromIntegral vNoiseCount) (castPtr vNoise :: Ptr Double)
    checked (Signal.signalToNoise
        vSignalValue
        vNoiseValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_signal_rms_f64" ffiSignalRmsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiSignalRmsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiSignalRmsF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (Signal.rms
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_arithmetic_mean_f64" ffiStatisticsAdvancedArithmeticMeanF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedArithmeticMeanF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedArithmeticMeanF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.arithmeticMean
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_weighted_mean_f64" ffiStatisticsAdvancedWeightedMeanF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedWeightedMeanF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedWeightedMeanF64 vXs vXsCount vWs vWsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    vWsValue <- peekArray (fromIntegral vWsCount) (castPtr vWs :: Ptr Double)
    checked (StatisticsAdvanced.weightedMean
        vXsValue
        vWsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_geometric_mean_f64" ffiStatisticsAdvancedGeometricMeanF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedGeometricMeanF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedGeometricMeanF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.geometricMean
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_harmonic_mean_f64" ffiStatisticsAdvancedHarmonicMeanF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedHarmonicMeanF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedHarmonicMeanF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.harmonicMean
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_rms_f64" ffiStatisticsAdvancedRmsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedRmsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedRmsF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.rms
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_trimmed_mean_f64" ffiStatisticsAdvancedTrimmedMeanF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedTrimmedMeanF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedTrimmedMeanF64 vFraction vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.trimmedMean
        (coerce vFraction :: Double)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_winsorized_mean_f64" ffiStatisticsAdvancedWinsorizedMeanF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedWinsorizedMeanF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedWinsorizedMeanF64 vFraction vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.winsorizedMean
        (coerce vFraction :: Double)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_quantile_f64" ffiStatisticsAdvancedQuantileF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedQuantileF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedQuantileF64 vP vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.quantile
        (coerce vP :: Double)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_median_f64" ffiStatisticsAdvancedMedianF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedMedianF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedMedianF64 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (StatisticsAdvanced.median
        vArgument1Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_percentile_f64" ffiStatisticsAdvancedPercentileF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedPercentileF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedPercentileF64 vArgument1 vArgument2 vArgument2Count out0 = boundary $ do
    vArgument2Value <- peekArray (fromIntegral vArgument2Count) (castPtr vArgument2 :: Ptr Double)
    checked (StatisticsAdvanced.percentile
        (coerce vArgument1 :: Double)
        vArgument2Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_modes_f64" ffiStatisticsAdvancedModesF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedModesF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedModesF64 vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.modes vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_statistics_advanced_interquartile_range_f64" ffiStatisticsAdvancedInterquartileRangeF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedInterquartileRangeF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedInterquartileRangeF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.interquartileRange
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_median_absolute_deviation_f64" ffiStatisticsAdvancedMedianAbsoluteDeviationF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedMedianAbsoluteDeviationF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedMedianAbsoluteDeviationF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.medianAbsoluteDeviation
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_data_range_f64" ffiStatisticsAdvancedDataRangeF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedDataRangeF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedDataRangeF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.dataRange
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_central_moment_f64" ffiStatisticsAdvancedCentralMomentF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedCentralMomentF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedCentralMomentF64 vK vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.centralMoment
        (fromIntegral vK)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_population_variance_f64" ffiStatisticsAdvancedPopulationVarianceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedPopulationVarianceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedPopulationVarianceF64 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (StatisticsAdvanced.populationVariance
        vArgument1Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_sample_variance_f64" ffiStatisticsAdvancedSampleVarianceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedSampleVarianceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedSampleVarianceF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.sampleVariance
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_population_s_d_f64" ffiStatisticsAdvancedPopulationSDF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedPopulationSDF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedPopulationSDF64 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (StatisticsAdvanced.populationSD
        vArgument1Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_sample_s_d_f64" ffiStatisticsAdvancedSampleSDF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedSampleSDF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedSampleSDF64 vArgument1 vArgument1Count out0 = boundary $ do
    vArgument1Value <- peekArray (fromIntegral vArgument1Count) (castPtr vArgument1 :: Ptr Double)
    checked (StatisticsAdvanced.sampleSD
        vArgument1Value) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_coefficient_of_variation_f64" ffiStatisticsAdvancedCoefficientOfVariationF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedCoefficientOfVariationF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedCoefficientOfVariationF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.coefficientOfVariation
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_skewness_f64" ffiStatisticsAdvancedSkewnessF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedSkewnessF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedSkewnessF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.skewness
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_kurtosis_f64" ffiStatisticsAdvancedKurtosisF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedKurtosisF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedKurtosisF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.kurtosis
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_covariance_f64" ffiStatisticsAdvancedCovarianceF64 :: 
    CInt ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedCovarianceF64 :: 
    CInt ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedCovarianceF64 vSampleCorrection vXs vXsCount vYs vYsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    vYsValue <- peekArray (fromIntegral vYsCount) (castPtr vYs :: Ptr Double)
    checked (StatisticsAdvanced.covariance
        (vSampleCorrection /= 0)
        vXsValue
        vYsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_correlation_f64" ffiStatisticsAdvancedCorrelationF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedCorrelationF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedCorrelationF64 vXs vXsCount vYs vYsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    vYsValue <- peekArray (fromIntegral vYsCount) (castPtr vYs :: Ptr Double)
    checked (StatisticsAdvanced.correlation
        vXsValue
        vYsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_spearman_f64" ffiStatisticsAdvancedSpearmanF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedSpearmanF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedSpearmanF64 vXs vXsCount vYs vYsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    vYsValue <- peekArray (fromIntegral vYsCount) (castPtr vYs :: Ptr Double)
    checked (StatisticsAdvanced.spearman
        vXsValue
        vYsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_kendall_f64" ffiStatisticsAdvancedKendallF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedKendallF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedKendallF64 vXs vXsCount vYs vYsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    vYsValue <- peekArray (fromIntegral vYsCount) (castPtr vYs :: Ptr Double)
    checked (StatisticsAdvanced.kendall
        vXsValue
        vYsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_autocorrelation_f64" ffiStatisticsAdvancedAutocorrelationF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedAutocorrelationF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedAutocorrelationF64 vLag vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.autocorrelation
        (fromIntegral vLag)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_cross_correlation_f64" ffiStatisticsAdvancedCrossCorrelationF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedCrossCorrelationF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedCrossCorrelationF64 vLag vXs vXsCount vYs vYsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    vYsValue <- peekArray (fromIntegral vYsCount) (castPtr vYs :: Ptr Double)
    checked (StatisticsAdvanced.crossCorrelation
        (fromIntegral vLag)
        vXsValue
        vYsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_moving_average_f64" ffiStatisticsAdvancedMovingAverageF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedMovingAverageF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedMovingAverageF64 vWindow vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.movingAverage (fromIntegral vWindow) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_statistics_advanced_moving_variance_f64" ffiStatisticsAdvancedMovingVarianceF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedMovingVarianceF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedMovingVarianceF64 vWindow vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.movingVariance (fromIntegral vWindow) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_statistics_advanced_exponential_moving_average_f64" ffiStatisticsAdvancedExponentialMovingAverageF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedExponentialMovingAverageF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedExponentialMovingAverageF64 vAlpha vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.exponentialMovingAverage (coerce vAlpha :: Double) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_statistics_advanced_entropy_f64" ffiStatisticsAdvancedEntropyF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedEntropyF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedEntropyF64 vPs vPsCount out0 = boundary $ do
    vPsValue <- peekArray (fromIntegral vPsCount) (castPtr vPs :: Ptr Double)
    checked (StatisticsAdvanced.entropy
        vPsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_kl_divergence_f64" ffiStatisticsAdvancedKlDivergenceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedKlDivergenceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedKlDivergenceF64 vP vPCount vQ vQCount out0 = boundary $ do
    vPValue <- peekArray (fromIntegral vPCount) (castPtr vP :: Ptr Double)
    vQValue <- peekArray (fromIntegral vQCount) (castPtr vQ :: Ptr Double)
    checked (StatisticsAdvanced.klDivergence
        vPValue
        vQValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_js_divergence_f64" ffiStatisticsAdvancedJsDivergenceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedJsDivergenceF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedJsDivergenceF64 vP vPCount vQ vQCount out0 = boundary $ do
    vPValue <- peekArray (fromIntegral vPCount) (castPtr vP :: Ptr Double)
    vQValue <- peekArray (fromIntegral vQCount) (castPtr vQ :: Ptr Double)
    checked (StatisticsAdvanced.jsDivergence
        vPValue
        vQValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_z_scores_f64" ffiStatisticsAdvancedZScoresF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedZScoresF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedZScoresF64 vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.zScores vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_statistics_advanced_standard_error_f64" ffiStatisticsAdvancedStandardErrorF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedStandardErrorF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedStandardErrorF64 vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.standardError
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_confidence_interval_f64" ffiStatisticsAdvancedConfidenceIntervalF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedConfidenceIntervalF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedConfidenceIntervalF64 vLevel vXs vXsCount out0 out1 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.confidenceInterval
        (coerce vLevel :: Double)
        vXsValue) $ \(first, second) -> do
        strict0 <- evaluate (first)
        strict1 <- evaluate (second)
        poke out0 (coerce strict0 :: CDouble)
        poke out1 (coerce strict1 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_bonferroni_f64" ffiStatisticsAdvancedBonferroniF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedBonferroniF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedBonferroniF64 vPs vPsCount outData outCount = boundary $ do
    vPsValue <- peekArray (fromIntegral vPsCount) (castPtr vPs :: Ptr Double)
    checked (StatisticsAdvanced.bonferroni vPsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_statistics_advanced_benjamini_hochberg_f64" ffiStatisticsAdvancedBenjaminiHochbergF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedBenjaminiHochbergF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedBenjaminiHochbergF64 vPs vPsCount outData outCount = boundary $ do
    vPsValue <- peekArray (fromIntegral vPsCount) (castPtr vPs :: Ptr Double)
    checked (StatisticsAdvanced.benjaminiHochberg vPsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_statistics_advanced_cohens_d_f64" ffiStatisticsAdvancedCohensDF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedCohensDF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedCohensDF64 vXs vXsCount vYs vYsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    vYsValue <- peekArray (fromIntegral vYsCount) (castPtr vYs :: Ptr Double)
    checked (StatisticsAdvanced.cohensD
        vXsValue
        vYsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_normal_test_power_f64" ffiStatisticsAdvancedNormalTestPowerF64 :: 
    CDouble ->
    CDouble ->
    CPtrdiff ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedNormalTestPowerF64 :: 
    CDouble ->
    CDouble ->
    CPtrdiff ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedNormalTestPowerF64 vAlpha vStandardizedEffect vN out0 = boundary $ do
    checked (StatisticsAdvanced.normalTestPower
        (coerce vAlpha :: Double)
        (coerce vStandardizedEffect :: Double)
        (fromIntegral vN)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_statistics_advanced_normal_sample_size_f64" ffiStatisticsAdvancedNormalSampleSizeF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CPtrdiff ->
    IO CInt
ffiStatisticsAdvancedNormalSampleSizeF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CPtrdiff ->
    IO CInt
ffiStatisticsAdvancedNormalSampleSizeF64 vAlpha vPower vEffect out0 = boundary $ do
    checked (StatisticsAdvanced.normalSampleSize
        (coerce vAlpha :: Double)
        (coerce vPower :: Double)
        (coerce vEffect :: Double)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (fromIntegral strict0)

foreign export ccall "hm_numeric_statistics_advanced_tukey_outliers_f64" ffiStatisticsAdvancedTukeyOutliersF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedTukeyOutliersF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiStatisticsAdvancedTukeyOutliersF64 vMultiplier vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.tukeyOutliers (coerce vMultiplier :: Double) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (map (fromIntegral :: Int -> CPtrdiff) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_statistics_advanced_huber_location_f64" ffiStatisticsAdvancedHuberLocationF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedHuberLocationF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiStatisticsAdvancedHuberLocationF64 vTuning vXs vXsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (StatisticsAdvanced.huberLocation
        (coerce vTuning :: Double)
        vXsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_tensor_shape_size" ffiTensorShapeSize :: 
    Ptr CPtrdiff ->
    CSize ->
    Ptr CPtrdiff ->
    IO CInt
ffiTensorShapeSize :: 
    Ptr CPtrdiff ->
    CSize ->
    Ptr CPtrdiff ->
    IO CInt
ffiTensorShapeSize vDims vDimsCount out0 = boundary $ do
    vDimsRaw <- peekArray (fromIntegral vDimsCount) vDims
    let vDimsValue = map fromIntegral vDimsRaw
    checked (Tensor.shapeSize
        vDimsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (fromIntegral strict0)

foreign export ccall "hm_numeric_tensor_infer_broadcast" ffiTensorInferBroadcast :: 
    Ptr CPtrdiff ->
    CSize ->
    Ptr CPtrdiff ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiTensorInferBroadcast :: 
    Ptr CPtrdiff ->
    CSize ->
    Ptr CPtrdiff ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiTensorInferBroadcast vAs vAsCount vBs vBsCount outData outCount = boundary $ do
    vAsRaw <- peekArray (fromIntegral vAsCount) vAs
    let vAsValue = map fromIntegral vAsRaw
    vBsRaw <- peekArray (fromIntegral vBsCount) vBs
    let vBsValue = map fromIntegral vBsRaw
    checked (Tensor.inferBroadcast vAsValue vBsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (map (fromIntegral :: Int -> CPtrdiff) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_timeseries_core_exponential_average_f64" ffiTimeseriesCoreExponentialAverageF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesCoreExponentialAverageF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesCoreExponentialAverageF64 vAlpha vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (TimeSeriesCore.exponentialAverage (coerce vAlpha :: Double) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_timeseries_core_weighted_average_f64" ffiTimeseriesCoreWeightedAverageF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesCoreWeightedAverageF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesCoreWeightedAverageF64 vWs vWsCount vXs vXsCount outData outCount = boundary $ do
    vWsValue <- peekArray (fromIntegral vWsCount) (castPtr vWs :: Ptr Double)
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (TimeSeriesCore.weightedAverage vWsValue vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_timeseries_core_cumulative_returns_f64" ffiTimeseriesCoreCumulativeReturnsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesCoreCumulativeReturnsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesCoreCumulativeReturnsF64 vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (TimeSeriesCore.cumulativeReturns vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_timeseries_core_logarithmic_returns_f64" ffiTimeseriesCoreLogarithmicReturnsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesCoreLogarithmicReturnsF64 :: 
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesCoreLogarithmicReturnsF64 vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (TimeSeriesCore.logarithmicReturns vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_timeseries_core_difference_f64" ffiTimeseriesCoreDifferenceF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesCoreDifferenceF64 :: 
    CPtrdiff ->
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesCoreDifferenceF64 vOrder vLag vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (TimeSeriesCore.difference (fromIntegral vOrder) (fromIntegral vLag) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_timeseries_core_autocorrelation_f64" ffiTimeseriesCoreAutocorrelationF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesCoreAutocorrelationF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesCoreAutocorrelationF64 vLags vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (TimeSeriesCore.autocorrelation (fromIntegral vLags) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_timeseries_core_cross_correlation_f64" ffiTimeseriesCoreCrossCorrelationF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiTimeseriesCoreCrossCorrelationF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    CSize ->
    Ptr CDouble ->
    IO CInt
ffiTimeseriesCoreCrossCorrelationF64 vLag vXs vXsCount vYs vYsCount out0 = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    vYsValue <- peekArray (fromIntegral vYsCount) (castPtr vYs :: Ptr Double)
    checked (TimeSeriesCore.crossCorrelation
        (fromIntegral vLag)
        vXsValue
        vYsValue) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_timeseries_core_partial_autocorrelation_f64" ffiTimeseriesCorePartialAutocorrelationF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesCorePartialAutocorrelationF64 :: 
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CDouble) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesCorePartialAutocorrelationF64 vOrder vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (TimeSeriesCore.partialAutocorrelation (fromIntegral vOrder) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Double])
        bracketOnError (newArray (map (coerce :: Double -> CDouble) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_timeseries_diagnostics_change_points_f64" ffiTimeseriesDiagnosticsChangePointsF64 :: 
    CDouble ->
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesDiagnosticsChangePointsF64 :: 
    CDouble ->
    CPtrdiff ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesDiagnosticsChangePointsF64 vPenalty vMinSegment vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (TimeSeriesDiagnostics.changePoints (coerce vPenalty :: Double) (fromIntegral vMinSegment) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (map (fromIntegral :: Int -> CPtrdiff) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_timeseries_diagnostics_cusum_f64" ffiTimeseriesDiagnosticsCusumF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesDiagnosticsCusumF64 :: 
    CDouble ->
    CDouble ->
    CDouble ->
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesDiagnosticsCusumF64 vMean vSd vDrift vThreshold vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (TimeSeriesDiagnostics.cusum (coerce vMean :: Double) (coerce vSd :: Double) (coerce vDrift :: Double) (coerce vThreshold :: Double) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (map (fromIntegral :: Int -> CPtrdiff) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_timeseries_diagnostics_anomalies_f64" ffiTimeseriesDiagnosticsAnomaliesF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesDiagnosticsAnomaliesF64 :: 
    CDouble ->
    Ptr CDouble ->
    CSize ->
    Ptr (Ptr CPtrdiff) ->
    Ptr CSize ->
    IO CInt
ffiTimeseriesDiagnosticsAnomaliesF64 vThreshold vXs vXsCount outData outCount = boundary $ do
    vXsValue <- peekArray (fromIntegral vXsCount) (castPtr vXs :: Ptr Double)
    checked (TimeSeriesDiagnostics.anomalies (coerce vThreshold :: Double) vXsValue) $ \value -> do
        strict <- mapM evaluate (value :: [Int])
        bracketOnError (newArray (map (fromIntegral :: Int -> CPtrdiff) strict)) free $ \pointer -> do
            poke outData pointer
            poke outCount (fromIntegral (length strict))

foreign export ccall "hm_numeric_units_radians_to_degrees_f32" ffiUnitsRadiansToDegreesF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiUnitsRadiansToDegreesF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiUnitsRadiansToDegreesF32 vX out0 = boundary $ do
    checked (Right (Units.radiansToDegrees
        (coerce vX :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_units_radians_to_degrees_f64" ffiUnitsRadiansToDegreesF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiUnitsRadiansToDegreesF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiUnitsRadiansToDegreesF64 vX out0 = boundary $ do
    checked (Right (Units.radiansToDegrees
        (coerce vX :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_units_degrees_to_radians_f32" ffiUnitsDegreesToRadiansF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiUnitsDegreesToRadiansF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiUnitsDegreesToRadiansF32 vX out0 = boundary $ do
    checked (Right (Units.degreesToRadians
        (coerce vX :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_units_degrees_to_radians_f64" ffiUnitsDegreesToRadiansF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiUnitsDegreesToRadiansF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiUnitsDegreesToRadiansF64 vX out0 = boundary $ do
    checked (Right (Units.degreesToRadians
        (coerce vX :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_units_radians_to_gradians_f32" ffiUnitsRadiansToGradiansF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiUnitsRadiansToGradiansF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiUnitsRadiansToGradiansF32 vX out0 = boundary $ do
    checked (Right (Units.radiansToGradians
        (coerce vX :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_units_radians_to_gradians_f64" ffiUnitsRadiansToGradiansF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiUnitsRadiansToGradiansF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiUnitsRadiansToGradiansF64 vX out0 = boundary $ do
    checked (Right (Units.radiansToGradians
        (coerce vX :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_units_gradians_to_radians_f32" ffiUnitsGradiansToRadiansF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiUnitsGradiansToRadiansF32 :: 
    CFloat ->
    Ptr CFloat ->
    IO CInt
ffiUnitsGradiansToRadiansF32 vX out0 = boundary $ do
    checked (Right (Units.gradiansToRadians
        (coerce vX :: Float))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CFloat)

foreign export ccall "hm_numeric_units_gradians_to_radians_f64" ffiUnitsGradiansToRadiansF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiUnitsGradiansToRadiansF64 :: 
    CDouble ->
    Ptr CDouble ->
    IO CInt
ffiUnitsGradiansToRadiansF64 vX out0 = boundary $ do
    checked (Right (Units.gradiansToRadians
        (coerce vX :: Double))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: CDouble)

foreign export ccall "hm_numeric_scalar_saturating_add_i8" ffiScalarSaturatingAddI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarSaturatingAddI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarSaturatingAddI8 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingAdd
        (vA :: Int8)
        (vB :: Int8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_scalar_saturating_add_i16" ffiScalarSaturatingAddI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarSaturatingAddI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarSaturatingAddI16 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingAdd
        (vA :: Int16)
        (vB :: Int16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_scalar_saturating_add_i32" ffiScalarSaturatingAddI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarSaturatingAddI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarSaturatingAddI32 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingAdd
        (vA :: Int32)
        (vB :: Int32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_scalar_saturating_add_i64" ffiScalarSaturatingAddI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarSaturatingAddI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarSaturatingAddI64 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingAdd
        (vA :: Int64)
        (vB :: Int64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_scalar_saturating_add_u8" ffiScalarSaturatingAddU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarSaturatingAddU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarSaturatingAddU8 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingAdd
        (vA :: Word8)
        (vB :: Word8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_scalar_saturating_add_u16" ffiScalarSaturatingAddU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarSaturatingAddU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarSaturatingAddU16 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingAdd
        (vA :: Word16)
        (vB :: Word16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_scalar_saturating_add_u32" ffiScalarSaturatingAddU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarSaturatingAddU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarSaturatingAddU32 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingAdd
        (vA :: Word32)
        (vB :: Word32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_scalar_saturating_add_u64" ffiScalarSaturatingAddU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarSaturatingAddU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarSaturatingAddU64 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingAdd
        (vA :: Word64)
        (vB :: Word64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_scalar_saturating_add_int" ffiScalarSaturatingAddInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarSaturatingAddInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarSaturatingAddInt vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingAdd
        (vA :: Int)
        (vB :: Int))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_scalar_saturating_add_word" ffiScalarSaturatingAddWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarSaturatingAddWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarSaturatingAddWord vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingAdd
        (vA :: Word)
        (vB :: Word))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_scalar_saturating_subtract_i8" ffiScalarSaturatingSubtractI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarSaturatingSubtractI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarSaturatingSubtractI8 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingSubtract
        (vA :: Int8)
        (vB :: Int8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_scalar_saturating_subtract_i16" ffiScalarSaturatingSubtractI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarSaturatingSubtractI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarSaturatingSubtractI16 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingSubtract
        (vA :: Int16)
        (vB :: Int16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_scalar_saturating_subtract_i32" ffiScalarSaturatingSubtractI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarSaturatingSubtractI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarSaturatingSubtractI32 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingSubtract
        (vA :: Int32)
        (vB :: Int32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_scalar_saturating_subtract_i64" ffiScalarSaturatingSubtractI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarSaturatingSubtractI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarSaturatingSubtractI64 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingSubtract
        (vA :: Int64)
        (vB :: Int64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_scalar_saturating_subtract_u8" ffiScalarSaturatingSubtractU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarSaturatingSubtractU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarSaturatingSubtractU8 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingSubtract
        (vA :: Word8)
        (vB :: Word8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_scalar_saturating_subtract_u16" ffiScalarSaturatingSubtractU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarSaturatingSubtractU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarSaturatingSubtractU16 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingSubtract
        (vA :: Word16)
        (vB :: Word16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_scalar_saturating_subtract_u32" ffiScalarSaturatingSubtractU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarSaturatingSubtractU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarSaturatingSubtractU32 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingSubtract
        (vA :: Word32)
        (vB :: Word32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_scalar_saturating_subtract_u64" ffiScalarSaturatingSubtractU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarSaturatingSubtractU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarSaturatingSubtractU64 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingSubtract
        (vA :: Word64)
        (vB :: Word64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_scalar_saturating_subtract_int" ffiScalarSaturatingSubtractInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarSaturatingSubtractInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarSaturatingSubtractInt vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingSubtract
        (vA :: Int)
        (vB :: Int))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_scalar_saturating_subtract_word" ffiScalarSaturatingSubtractWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarSaturatingSubtractWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarSaturatingSubtractWord vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingSubtract
        (vA :: Word)
        (vB :: Word))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_scalar_saturating_multiply_i8" ffiScalarSaturatingMultiplyI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarSaturatingMultiplyI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarSaturatingMultiplyI8 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingMultiply
        (vA :: Int8)
        (vB :: Int8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_scalar_saturating_multiply_i16" ffiScalarSaturatingMultiplyI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarSaturatingMultiplyI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarSaturatingMultiplyI16 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingMultiply
        (vA :: Int16)
        (vB :: Int16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_scalar_saturating_multiply_i32" ffiScalarSaturatingMultiplyI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarSaturatingMultiplyI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarSaturatingMultiplyI32 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingMultiply
        (vA :: Int32)
        (vB :: Int32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_scalar_saturating_multiply_i64" ffiScalarSaturatingMultiplyI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarSaturatingMultiplyI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarSaturatingMultiplyI64 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingMultiply
        (vA :: Int64)
        (vB :: Int64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_scalar_saturating_multiply_u8" ffiScalarSaturatingMultiplyU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarSaturatingMultiplyU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarSaturatingMultiplyU8 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingMultiply
        (vA :: Word8)
        (vB :: Word8))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_scalar_saturating_multiply_u16" ffiScalarSaturatingMultiplyU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarSaturatingMultiplyU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarSaturatingMultiplyU16 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingMultiply
        (vA :: Word16)
        (vB :: Word16))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_scalar_saturating_multiply_u32" ffiScalarSaturatingMultiplyU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarSaturatingMultiplyU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarSaturatingMultiplyU32 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingMultiply
        (vA :: Word32)
        (vB :: Word32))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_scalar_saturating_multiply_u64" ffiScalarSaturatingMultiplyU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarSaturatingMultiplyU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarSaturatingMultiplyU64 vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingMultiply
        (vA :: Word64)
        (vB :: Word64))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_scalar_saturating_multiply_int" ffiScalarSaturatingMultiplyInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarSaturatingMultiplyInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarSaturatingMultiplyInt vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingMultiply
        (vA :: Int)
        (vB :: Int))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_scalar_saturating_multiply_word" ffiScalarSaturatingMultiplyWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarSaturatingMultiplyWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarSaturatingMultiplyWord vA vB out0 = boundary $ do
    checked (Right (Scalar.saturatingMultiply
        (vA :: Word)
        (vB :: Word))) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_scalar_checked_add_i8" ffiScalarCheckedAddI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarCheckedAddI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarCheckedAddI8 vA vB out0 = boundary $ do
    checked (Scalar.checkedAdd
        (vA :: Int8)
        (vB :: Int8)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_scalar_checked_add_i16" ffiScalarCheckedAddI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarCheckedAddI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarCheckedAddI16 vA vB out0 = boundary $ do
    checked (Scalar.checkedAdd
        (vA :: Int16)
        (vB :: Int16)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_scalar_checked_add_i32" ffiScalarCheckedAddI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarCheckedAddI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarCheckedAddI32 vA vB out0 = boundary $ do
    checked (Scalar.checkedAdd
        (vA :: Int32)
        (vB :: Int32)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_scalar_checked_add_i64" ffiScalarCheckedAddI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarCheckedAddI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarCheckedAddI64 vA vB out0 = boundary $ do
    checked (Scalar.checkedAdd
        (vA :: Int64)
        (vB :: Int64)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_scalar_checked_add_u8" ffiScalarCheckedAddU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarCheckedAddU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarCheckedAddU8 vA vB out0 = boundary $ do
    checked (Scalar.checkedAdd
        (vA :: Word8)
        (vB :: Word8)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_scalar_checked_add_u16" ffiScalarCheckedAddU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarCheckedAddU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarCheckedAddU16 vA vB out0 = boundary $ do
    checked (Scalar.checkedAdd
        (vA :: Word16)
        (vB :: Word16)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_scalar_checked_add_u32" ffiScalarCheckedAddU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarCheckedAddU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarCheckedAddU32 vA vB out0 = boundary $ do
    checked (Scalar.checkedAdd
        (vA :: Word32)
        (vB :: Word32)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_scalar_checked_add_u64" ffiScalarCheckedAddU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarCheckedAddU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarCheckedAddU64 vA vB out0 = boundary $ do
    checked (Scalar.checkedAdd
        (vA :: Word64)
        (vB :: Word64)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_scalar_checked_add_int" ffiScalarCheckedAddInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarCheckedAddInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarCheckedAddInt vA vB out0 = boundary $ do
    checked (Scalar.checkedAdd
        (vA :: Int)
        (vB :: Int)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_scalar_checked_add_word" ffiScalarCheckedAddWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarCheckedAddWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarCheckedAddWord vA vB out0 = boundary $ do
    checked (Scalar.checkedAdd
        (vA :: Word)
        (vB :: Word)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_scalar_checked_subtract_i8" ffiScalarCheckedSubtractI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarCheckedSubtractI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarCheckedSubtractI8 vA vB out0 = boundary $ do
    checked (Scalar.checkedSubtract
        (vA :: Int8)
        (vB :: Int8)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_scalar_checked_subtract_i16" ffiScalarCheckedSubtractI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarCheckedSubtractI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarCheckedSubtractI16 vA vB out0 = boundary $ do
    checked (Scalar.checkedSubtract
        (vA :: Int16)
        (vB :: Int16)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_scalar_checked_subtract_i32" ffiScalarCheckedSubtractI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarCheckedSubtractI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarCheckedSubtractI32 vA vB out0 = boundary $ do
    checked (Scalar.checkedSubtract
        (vA :: Int32)
        (vB :: Int32)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_scalar_checked_subtract_i64" ffiScalarCheckedSubtractI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarCheckedSubtractI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarCheckedSubtractI64 vA vB out0 = boundary $ do
    checked (Scalar.checkedSubtract
        (vA :: Int64)
        (vB :: Int64)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_scalar_checked_subtract_u8" ffiScalarCheckedSubtractU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarCheckedSubtractU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarCheckedSubtractU8 vA vB out0 = boundary $ do
    checked (Scalar.checkedSubtract
        (vA :: Word8)
        (vB :: Word8)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_scalar_checked_subtract_u16" ffiScalarCheckedSubtractU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarCheckedSubtractU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarCheckedSubtractU16 vA vB out0 = boundary $ do
    checked (Scalar.checkedSubtract
        (vA :: Word16)
        (vB :: Word16)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_scalar_checked_subtract_u32" ffiScalarCheckedSubtractU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarCheckedSubtractU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarCheckedSubtractU32 vA vB out0 = boundary $ do
    checked (Scalar.checkedSubtract
        (vA :: Word32)
        (vB :: Word32)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_scalar_checked_subtract_u64" ffiScalarCheckedSubtractU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarCheckedSubtractU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarCheckedSubtractU64 vA vB out0 = boundary $ do
    checked (Scalar.checkedSubtract
        (vA :: Word64)
        (vB :: Word64)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_scalar_checked_subtract_int" ffiScalarCheckedSubtractInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarCheckedSubtractInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarCheckedSubtractInt vA vB out0 = boundary $ do
    checked (Scalar.checkedSubtract
        (vA :: Int)
        (vB :: Int)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_scalar_checked_subtract_word" ffiScalarCheckedSubtractWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarCheckedSubtractWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarCheckedSubtractWord vA vB out0 = boundary $ do
    checked (Scalar.checkedSubtract
        (vA :: Word)
        (vB :: Word)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)

foreign export ccall "hm_numeric_scalar_checked_multiply_i8" ffiScalarCheckedMultiplyI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarCheckedMultiplyI8 :: 
    Int8 ->
    Int8 ->
    Ptr Int8 ->
    IO CInt
ffiScalarCheckedMultiplyI8 vA vB out0 = boundary $ do
    checked (Scalar.checkedMultiply
        (vA :: Int8)
        (vB :: Int8)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int8)

foreign export ccall "hm_numeric_scalar_checked_multiply_i16" ffiScalarCheckedMultiplyI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarCheckedMultiplyI16 :: 
    Int16 ->
    Int16 ->
    Ptr Int16 ->
    IO CInt
ffiScalarCheckedMultiplyI16 vA vB out0 = boundary $ do
    checked (Scalar.checkedMultiply
        (vA :: Int16)
        (vB :: Int16)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int16)

foreign export ccall "hm_numeric_scalar_checked_multiply_i32" ffiScalarCheckedMultiplyI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarCheckedMultiplyI32 :: 
    Int32 ->
    Int32 ->
    Ptr Int32 ->
    IO CInt
ffiScalarCheckedMultiplyI32 vA vB out0 = boundary $ do
    checked (Scalar.checkedMultiply
        (vA :: Int32)
        (vB :: Int32)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int32)

foreign export ccall "hm_numeric_scalar_checked_multiply_i64" ffiScalarCheckedMultiplyI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarCheckedMultiplyI64 :: 
    Int64 ->
    Int64 ->
    Ptr Int64 ->
    IO CInt
ffiScalarCheckedMultiplyI64 vA vB out0 = boundary $ do
    checked (Scalar.checkedMultiply
        (vA :: Int64)
        (vB :: Int64)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int64)

foreign export ccall "hm_numeric_scalar_checked_multiply_u8" ffiScalarCheckedMultiplyU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarCheckedMultiplyU8 :: 
    Word8 ->
    Word8 ->
    Ptr Word8 ->
    IO CInt
ffiScalarCheckedMultiplyU8 vA vB out0 = boundary $ do
    checked (Scalar.checkedMultiply
        (vA :: Word8)
        (vB :: Word8)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word8)

foreign export ccall "hm_numeric_scalar_checked_multiply_u16" ffiScalarCheckedMultiplyU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarCheckedMultiplyU16 :: 
    Word16 ->
    Word16 ->
    Ptr Word16 ->
    IO CInt
ffiScalarCheckedMultiplyU16 vA vB out0 = boundary $ do
    checked (Scalar.checkedMultiply
        (vA :: Word16)
        (vB :: Word16)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word16)

foreign export ccall "hm_numeric_scalar_checked_multiply_u32" ffiScalarCheckedMultiplyU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarCheckedMultiplyU32 :: 
    Word32 ->
    Word32 ->
    Ptr Word32 ->
    IO CInt
ffiScalarCheckedMultiplyU32 vA vB out0 = boundary $ do
    checked (Scalar.checkedMultiply
        (vA :: Word32)
        (vB :: Word32)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word32)

foreign export ccall "hm_numeric_scalar_checked_multiply_u64" ffiScalarCheckedMultiplyU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarCheckedMultiplyU64 :: 
    Word64 ->
    Word64 ->
    Ptr Word64 ->
    IO CInt
ffiScalarCheckedMultiplyU64 vA vB out0 = boundary $ do
    checked (Scalar.checkedMultiply
        (vA :: Word64)
        (vB :: Word64)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word64)

foreign export ccall "hm_numeric_scalar_checked_multiply_int" ffiScalarCheckedMultiplyInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarCheckedMultiplyInt :: 
    Int ->
    Int ->
    Ptr Int ->
    IO CInt
ffiScalarCheckedMultiplyInt vA vB out0 = boundary $ do
    checked (Scalar.checkedMultiply
        (vA :: Int)
        (vB :: Int)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Int)

foreign export ccall "hm_numeric_scalar_checked_multiply_word" ffiScalarCheckedMultiplyWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarCheckedMultiplyWord :: 
    Word ->
    Word ->
    Ptr Word ->
    IO CInt
ffiScalarCheckedMultiplyWord vA vB out0 = boundary $ do
    checked (Scalar.checkedMultiply
        (vA :: Word)
        (vB :: Word)) $ \value -> do
        strict0 <- evaluate (value)
        poke out0 (coerce strict0 :: Word)
