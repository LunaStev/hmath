{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE UndecidableInstances #-}

-- SPDX-License-Identifier: MPL-2.0
-- | Typed representation and callbacks; numerical algorithms remain in HMath.
module HMath.FFI.NumericalCodec where

import Control.Exception (catch, evaluate, throwIO)
import Data.Complex (Complex)
import Data.Typeable (Typeable, cast)
import Data.Word (Word64)
import System.IO.Unsafe (unsafePerformIO)
import HMath.Error (MathError)
import HMath.FFI.Coefficient
import HMath.FFI.MathError (CallbackFailure(..))
import qualified HMath.FFI.GraphCodec as W
import qualified HMath.FFI.LinearCodec as L
import qualified HMath.FFI.Polynomial as P
import qualified HMath.FFI.Value as V
import qualified HMath.Matrix as M
import qualified HMath.Polynomial as Polynomial
import qualified HMath.Sparse as S
import qualified HMath.Calculus as C

class From a where from :: V.Value -> IO a
class To a where to :: a -> IO V.Value

instance From V.Value where from = pure
instance To V.Value where to = pure
instance From Double where from = V.asScalar
instance To Double where to = pure . V.Scalar SDouble
instance From Rational where from = V.asScalar
instance To Rational where to = pure . V.Scalar SRational
instance From Integer where from = V.asScalar
instance To Integer where to = pure . V.Scalar SInteger
instance From Word64 where from = W.unwire
instance To Word64 where to = pure . V.Scalar SWord64
instance From (Complex Double) where from = V.asScalar
instance To (Complex Double) where to = pure . V.Scalar SComplexDouble
instance From Int where from = V.asIndex
instance To Int where to = pure . V.Index
instance From Bool where from = V.asBoolean
instance To Bool where to = pure . V.Boolean
instance From () where from value = V.asTuple 0 value >> pure ()
instance To () where to () = pure (V.Tuple [])
instance {-# OVERLAPPING #-} From String where from = V.asText
instance {-# OVERLAPPING #-} To String where to = pure . V.Text
instance {-# OVERLAPPABLE #-} From a => From [a] where from value = V.asList value >>= mapM from
instance {-# OVERLAPPABLE #-} To a => To [a] where to values = V.List <$> mapM to values
instance From a => From (Maybe a) where
    from V.None = pure Nothing
    from value = Just <$> from value
instance To a => To (Maybe a) where to = maybe (pure V.None) to
instance To a => To (Either MathError a) where
    to (Left errorValue) = throwIO (CallbackMathError errorValue)
    to (Right value) = to value
instance (From a,From b) => From (a,b) where
    from value = do
        fields <- V.asTuple 2 value
        case fields of
            [a,b] -> (,) <$> from a <*> from b
            _ -> V.invalid "numerical pair arity differs"
instance (To a,To b) => To (a,b) where to (a,b) = V.Tuple <$> sequence [to a,to b]
instance (From a,From b,From c) => From (a,b,c) where
    from value = do
        fields <- V.asTuple 3 value
        case fields of
            [a,b,c] -> (,,) <$> from a <*> from b <*> from c
            _ -> V.invalid "numerical triple arity differs"
instance (To a,To b,To c) => To (a,b,c) where to (a,b,c) = V.Tuple <$> sequence [to a,to b,to c]
instance From (M.Matrix Double) where from = L.asMatrix
instance To (M.Matrix Double) where to = pure . V.Dense . V.SomeMatrix SDouble
instance From (S.Sparse Double) where from = L.unbox "HMath.Sparse.Sparse"
instance To (S.Sparse Double) where to = L.encodeSparse SDouble
instance From (Polynomial.Polynomial Rational) where from = P.asPolynomial
instance To (Polynomial.Polynomial Rational) where to = pure . P.poly SRational
instance From (Polynomial.Polynomial (Complex Double)) where from = P.asPolynomial
instance To (Polynomial.Polynomial (Complex Double)) where to = pure . P.poly SComplexDouble

-- Estimate's public parameter remains arbitrary: preserve its payload as an
-- original Estimate Value rather than imposing a floating-point conversion.
instance From a => From (C.Estimate a) where
    from value = do
        original <- unbox 200 value :: IO (C.Estimate V.Value)
        payload <- from (C.estimateValue original)
        pure (C.Estimate payload (C.estimateError original) (C.evaluations original))
instance To a => To (C.Estimate a) where
    to original = do
        payload <- to (C.estimateValue original)
        let value = C.Estimate payload (C.estimateError original) (C.evaluations original)
        pure (box 200 value [pure payload,to (C.estimateError original),to (C.evaluations original)])

box :: Typeable a => Int -> a -> [IO V.Value] -> V.Value
box kind value fields = V.Opaque kind (-1) 0 force value
  where
    force = evaluate value >> sequence fields >>= mapM_ V.forceValue
unbox :: Typeable a => Int -> V.Value -> IO a
unbox kind (V.Opaque actual _ _ _ value)
    | actual == kind = maybe (V.invalid "numerical payload type differs") pure (cast value)
unbox _ _ = V.invalid "numerical object kind differs"

class Apply a where apply :: a -> [V.Value] -> IO V.Value
instance {-# OVERLAPPABLE #-} To a => Apply a where
    apply value [] = to value
    apply _ _ = V.invalid "too many numerical arguments"
instance {-# OVERLAPPING #-} (From a,Apply b) => Apply (a -> b) where
    apply operation (value:rest) = from value >>= \argument -> apply (operation argument) rest
    apply _ [] = V.invalid "missing numerical argument"

-- Curried Haskell callbacks use a flat tuple of positional arguments in C.
-- Only an actual source Either recovers MathError into Left. Other failures
-- unwind to the outer native boundary after all borrowed handles are freed.
class Function a where function :: V.Value -> [IO V.Value] -> a
instance {-# OVERLAPPABLE #-} From a => Function a where
    function = pureCallbackResult
instance {-# OVERLAPPING #-} (To a,Function b) => Function (a -> b) where
    function callback arguments argument = function callback (arguments ++ [to argument])
instance {-# OVERLAPPING #-} From a => Function (Either MathError a) where
    function callback arguments = unsafePerformIO $
        (Right <$> (callbackResult callback arguments >>= from)) `catch` recover
      where
        recover (CallbackMathError errorValue) = pure (Left errorValue)
        recover other = throwIO other
instance {-# OVERLAPPING #-} (To a,Function b) => From (a -> b) where
    from callback = pure (function callback [])

{-# NOINLINE callbackResult #-}
callbackResult :: V.Value -> [IO V.Value] -> IO V.Value
callbackResult callback arguments = do
    input <- V.Tuple <$> sequence arguments
    V.forceValue input
    L.callbackValue callback input

{-# NOINLINE pureCallbackResult #-}
pureCallbackResult :: From a => V.Value -> [IO V.Value] -> a
pureCallbackResult callback arguments = unsafePerformIO (callbackResult callback arguments >>= from)
