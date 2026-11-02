{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE ForeignFunctionInterface #-}

-- SPDX-License-Identifier: MPL-2.0
-- | Representation only. Graph algorithms remain in the original modules.
module HMath.FFI.GraphCodec where

import Control.Exception (evaluate, throwIO)
import Data.Typeable (Typeable, cast)
import Foreign
import Foreign.C
import HMath.FFI.Coefficient
import HMath.FFI.MathError (CallbackFailure (..))
import HMath.FFI.Value
import qualified HMath.Graph as G
import System.IO.Unsafe (unsafePerformIO)

class Wire a where
    wire :: a -> Value
    unwire :: Value -> IO a

instance Wire Int where
    wire = Index
    unwire = asIndex
instance Wire Integer where
    wire = Scalar SInteger
    unwire (Index value) = pure (toInteger value)
    unwire value = asScalar @Integer value
instance Wire Word64 where
    wire = Scalar SWord64
    unwire (Scalar SWord64 value) = pure value
    unwire value = do
        integer <- unwire value :: IO Integer
        if integer < 0 || integer > toInteger (maxBound :: Word64)
            then throwIO (CallbackFailure 3 "Word64 input is outside its representation")
            else pure (fromInteger integer)
instance Wire Double where
    wire = Scalar SDouble
    unwire = asScalar @Double
instance Wire Bool where
    wire = Boolean
    unwire = asBoolean
instance Wire () where
    wire () = Tuple []
    unwire value = asTuple 0 value >> pure ()
instance {-# OVERLAPPING #-} Wire String where
    wire = Text
    unwire = asText
instance {-# OVERLAPPABLE #-} Wire a => Wire [a] where
    wire = List . map wire
    unwire value = asList value >>= mapM unwire
instance Wire a => Wire (Maybe a) where
    wire Nothing = None
    wire (Just value) = wire value
    unwire None = pure Nothing
    unwire value = Just <$> unwire value
instance (Wire a, Wire b) => Wire (a,b) where
    wire (a,b) = Tuple [wire a,wire b]
    unwire value = do
        items <- asTuple 2 value
        case items of
            [a,b] -> (,) <$> unwire a <*> unwire b
            _ -> invalid "pair arity differs"
instance (Wire a, Wire b, Wire c) => Wire (a,b,c) where
    wire (a,b,c) = Tuple [wire a,wire b,wire c]
    unwire value = do
        items <- asTuple 3 value
        case items of
            [a,b,c] -> (,,) <$> unwire a <*> unwire b <*> unwire c
            _ -> invalid "triple arity differs"
instance (Wire a, Wire b, Wire c, Wire d) => Wire (a,b,c,d) where
    wire (a,b,c,d) = Tuple [wire a,wire b,wire c,wire d]
    unwire value = do
        items <- asTuple 4 value
        case items of
            [a,b,c,d] -> (,,,) <$> unwire a <*> unwire b <*> unwire c <*> unwire d
            _ -> invalid "quadruple arity differs"

boxed :: Typeable a => Int -> a -> Value
boxed kind value = Opaque kind (-1) 0 (evaluate value >> pure ()) value
unboxed :: Typeable a => Int -> Value -> IO a
unboxed expected (Opaque kind _ _ _ value)
    | kind == expected = maybe (invalid "Graph payload type differs") pure (cast value)
unboxed _ _ = invalid "Graph object kind differs"
instance Wire G.Graph where
    wire = boxed 60
    unwire = unboxed 60
instance Wire G.Edge where
    wire = boxed 61
    unwire = unboxed 61
instance Wire G.CSR where
    wire = boxed 62
    unwire = unboxed 62
instance Wire G.BipartiteGraph where
    wire = boxed 63
    unwire = unboxed 63
instance Wire G.Hypergraph where
    wire = boxed 64
    unwire = unboxed 64
instance Wire G.Network where
    wire = boxed 65
    unwire = unboxed 65
instance Wire G.NetworkEdge where
    wire = boxed 66
    unwire = unboxed 66
instance Wire G.FlowResult where
    wire = boxed 67
    unwire = unboxed 67

type Heuristic = CPtrdiff -> Ptr () -> Ptr CDouble -> IO CInt
foreign import ccall "dynamic" callHeuristic :: FunPtr Heuristic -> Heuristic

-- The original heuristic is pure/deterministic; callbacks are borrowed only
-- during the operation. The entire returned path/value is forced before exit.
{-# NOINLINE heuristicFunction #-}
heuristicFunction :: FunPtr Heuristic -> Ptr () -> Int -> Double
heuristicFunction callback userdata vertex = unsafePerformIO $
    alloca $ \out -> do
        status <- callHeuristic callback (fromIntegral vertex) userdata out
        if status == 0
            then realToFrac <$> peek out
            else throwIO (CallbackFailure status "Graph heuristic callback failed")
