{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Reference buffer execution delegates arithmetic to the existing matrices.
module HMath.FFI.Execution where
import Control.Exception (evaluate)
import Data.Coerce (coerce)
import Foreign
import Foreign.C
import HMath.FFI.Boundary
import qualified HMath.Matrix as M
import qualified HMath.Matrix.Internal as I

readRows :: Storable a => Int -> Int -> Int -> Ptr a -> IO [a]
readRows rows columns stride pointer
    | rows == 0 || columns == 0 = pure []
    | stride == columns = peekArray (rows * columns) pointer
    | otherwise = concat <$> mapM (\row -> peekArray columns (advancePtr pointer (row * stride))) [0 .. rows-1]
writeRows :: Storable a => Int -> Int -> Int -> Ptr a -> [a] -> IO ()
writeRows rows columns stride pointer values
    | rows == 0 || columns == 0 = pure ()
    | stride == columns = pokeArray pointer values
    | otherwise = go 0 values
  where
    go row remaining
        | row == rows = pure ()
        | otherwise = let (chunk,rest)=splitAt columns remaining
                       in pokeArray (advancePtr pointer (row * stride)) chunk >> go (row+1) rest

foreign export ccall "hm_execution_reference_f32" reference32 :: CSize -> CSize -> CSize -> CFloat -> Ptr CFloat -> CSize -> Ptr CFloat -> CSize -> CFloat -> Ptr CFloat -> CSize -> IO CInt
reference32 :: CSize -> CSize -> CSize -> CFloat -> Ptr CFloat -> CSize -> Ptr CFloat -> CSize -> CFloat -> Ptr CFloat -> CSize -> IO CInt
reference32 m n k alpha ap lda bp ldb beta cp ldc = boundary $ do
 av <- readRows (fromIntegral m) (fromIntegral k) (fromIntegral lda) (castPtr ap :: Ptr Float)
 bv <- readRows (fromIntegral k) (fromIntegral n) (fromIntegral ldb) (castPtr bp :: Ptr Float)
 cv <- readRows (fromIntegral m) (fromIntegral n) (fromIntegral ldc) (castPtr cp :: Ptr Float)
 let computation = do
       a <- M.fromListChecked (fromIntegral m) (fromIntegral k) av
       b <- M.fromListChecked (fromIntegral k) (fromIntegral n) bv
       c <- M.fromListChecked (fromIntegral m) (fromIntegral n) cv
       I.finiteValues ((coerce alpha :: Float) : (coerce beta :: Float) : av ++ bv ++ cv)
       productM <- M.multiplyChecked a b
       result <- M.addMatrixChecked (M.scaleMatrix (coerce alpha) productM) (M.scaleMatrix (coerce beta) c)
       I.finiteValues (M.toList result)
       Right (M.toList result)
 checked computation $ \values -> do
  strict <- mapM evaluate values
  writeRows (fromIntegral m) (fromIntegral n) (fromIntegral ldc) (castPtr cp :: Ptr Float) strict

foreign export ccall "hm_execution_reference_f64" reference64 :: CSize -> CSize -> CSize -> CDouble -> Ptr CDouble -> CSize -> Ptr CDouble -> CSize -> CDouble -> Ptr CDouble -> CSize -> IO CInt
reference64 :: CSize -> CSize -> CSize -> CDouble -> Ptr CDouble -> CSize -> Ptr CDouble -> CSize -> CDouble -> Ptr CDouble -> CSize -> IO CInt
reference64 m n k alpha ap lda bp ldb beta cp ldc = boundary $ do
 av <- readRows (fromIntegral m) (fromIntegral k) (fromIntegral lda) (castPtr ap :: Ptr Double)
 bv <- readRows (fromIntegral k) (fromIntegral n) (fromIntegral ldb) (castPtr bp :: Ptr Double)
 cv <- readRows (fromIntegral m) (fromIntegral n) (fromIntegral ldc) (castPtr cp :: Ptr Double)
 let computation = do
       a <- M.fromListChecked (fromIntegral m) (fromIntegral k) av
       b <- M.fromListChecked (fromIntegral k) (fromIntegral n) bv
       c <- M.fromListChecked (fromIntegral m) (fromIntegral n) cv
       I.finiteValues ((coerce alpha :: Double) : (coerce beta :: Double) : av ++ bv ++ cv)
       productM <- M.multiplyChecked a b
       result <- M.addMatrixChecked (M.scaleMatrix (coerce alpha) productM) (M.scaleMatrix (coerce beta) c)
       I.finiteValues (M.toList result)
       Right (M.toList result)
 checked computation $ \values -> do
  strict <- mapM evaluate values
  writeRows (fromIntegral m) (fromIntegral n) (fromIntegral ldc) (castPtr cp :: Ptr Double) strict
