{-# LANGUAGE DeriveFoldable #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveTraversable #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Checked containers and copying conversion boundaries. Boxed containers can
retain lazy elements; strictBoxed forces each element to WHNF, not deep NF.
Unboxed storage specializes to Double. ST regions cannot escape runSTBuffer;
IO storage has one ForeignPtr owner shared by aliases and is garbage collected.
IO operations synchronize on the buffer lock. Pointer callbacks borrow storage
only for their dynamic extent and must not retain the pointer or reenter the
same buffer's locking operations. Freeze and thaw always copy.
-}
module HMath.API.Buffer (
    Boxed,
    lazyBoxed,
    strictBoxed,
    boxedValues,
    boxedLength,
    mapStrict,
    UnboxedDouble,
    unboxedDouble,
    unboxedValues,
    STBuffer,
    runSTBuffer,
    thawSTBuffer,
    freezeSTBuffer,
    readSTBuffer,
    writeSTBuffer,
    IOBuffer,
    newIOBuffer,
    thawIOBuffer,
    freezeIOBuffer,
    ioBufferLength,
    readIOBuffer,
    writeIOBuffer,
    withIOBuffer,
    unboxedToBoxed,
    boxedToUnboxed,
) where

import Control.Concurrent.MVar
import Control.Monad.ST (ST, runST)
import Data.Array (Array, elems, listArray)
import Data.Array.ST (STArray, getElems, newListArray, readArray, writeArray)
import qualified Data.Array.Unboxed as U
import Foreign.ForeignPtr (ForeignPtr, mallocForeignPtrArray, withForeignPtr)
import Foreign.Marshal.Array (peekArray, pokeArray)
import Foreign.Ptr (Ptr)
import Foreign.Storable (Storable, peekElemOff, pokeElemOff, sizeOf)
import HMath.Error

newtype Boxed a = Boxed (Array Int a) deriving (Eq, Show, Functor, Foldable, Traversable)

-- | Finite lists only. The list spine is consumed; elements remain lazy.
lazyBoxed :: [a] -> Boxed a
lazyBoxed xs = Boxed (listArray (0, length xs - 1) xs)

strictBoxed :: [a] -> Boxed a
strictBoxed xs = foldr seq () xs `seq` lazyBoxed xs
boxedValues :: Boxed a -> [a]
boxedValues (Boxed a) = elems a
boxedLength :: Boxed a -> Int
boxedLength = length . boxedValues
mapStrict :: (a -> b) -> Boxed a -> Boxed b
mapStrict f = strictBoxed . map f . boxedValues
newtype UnboxedDouble = UnboxedDouble (U.UArray Int Double) deriving (Eq, Show)
unboxedDouble :: [Double] -> UnboxedDouble
unboxedDouble xs = UnboxedDouble (U.listArray (0, length xs - 1) xs)
unboxedValues :: UnboxedDouble -> [Double]
unboxedValues (UnboxedDouble a) = U.elems a
unboxedToBoxed :: UnboxedDouble -> Boxed Double
unboxedToBoxed = strictBoxed . unboxedValues
boxedToUnboxed :: Boxed Double -> UnboxedDouble
boxedToUnboxed = unboxedDouble . boxedValues
data STBuffer s a = STBuffer !Int !(STArray s Int a)

-- | The rank-2 state parameter prevents a mutable region from escaping.
runSTBuffer :: Boxed a -> (forall s. STBuffer s a -> ST s b) -> b
runSTBuffer boxed action = runST (thawSTBuffer boxed >>= action)

thawSTBuffer :: Boxed a -> ST s (STBuffer s a)
thawSTBuffer boxed = let xs = boxedValues boxed; n = length xs in STBuffer n <$> newListArray (0, n - 1) xs
freezeSTBuffer :: STBuffer s a -> ST s (Boxed a)
freezeSTBuffer (STBuffer _ array) = lazyBoxed <$> getElems array
indexCheck :: Int -> Int -> Either MathError ()
indexCheck n i
    | i < 0 || i >= n = Left (InvalidArgument "buffer index out of bounds")
    | otherwise = Right ()
readSTBuffer :: STBuffer s a -> Int -> ST s (Either MathError a)
readSTBuffer (STBuffer n array) i = case indexCheck n i of Left e -> pure (Left e); Right () -> Right <$> readArray array i
writeSTBuffer :: STBuffer s a -> Int -> a -> ST s (Either MathError ())
writeSTBuffer (STBuffer n array) i x = case indexCheck n i of Left e -> pure (Left e); Right () -> Right <$> writeArray array i x
data IOBuffer a = IOBuffer !Int !(ForeignPtr a) !(MVar ())
ioBufferLength :: IOBuffer a -> Int
ioBufferLength (IOBuffer n _ _) = n

{- | Allocation overflow is checked before allocation. Allocation/OS exceptions
remain IO exceptions; MathError describes input and numeric contract failures.
-}
newIOBuffer :: forall a. (Storable a) => Int -> a -> IO (Either MathError (IOBuffer a))
newIOBuffer n x
    | n < 0 || toInteger (max 1 n) * toInteger (sizeOf (undefined :: a)) > toInteger (maxBound :: Int) =
        pure (Left (InvalidArgument "IO buffer allocation size overflow"))
    | otherwise = do
        fp <- mallocForeignPtrArray (max 1 n)
        withForeignPtr fp (\p -> pokeArray p (replicate n x))
        lock <- newMVar ()
        pure (Right (IOBuffer n fp lock))

thawIOBuffer :: forall a. (Storable a) => Boxed a -> IO (Either MathError (IOBuffer a))
thawIOBuffer boxed
    | toInteger (max 1 n) * toInteger (sizeOf (undefined :: a)) > toInteger (maxBound :: Int) =
        pure (Left (InvalidArgument "IO buffer allocation size overflow"))
    | otherwise = do
        fp <- mallocForeignPtrArray (max 1 n)
        withForeignPtr fp (\p -> pokeArray p xs)
        lock <- newMVar ()
        pure (Right (IOBuffer n fp lock))
  where
    xs = boxedValues boxed; n = length xs
withIOBuffer :: (Storable a) => IOBuffer a -> (Ptr a -> Int -> IO b) -> IO b
withIOBuffer (IOBuffer n fp lock) action = withMVar lock (\() -> withForeignPtr fp (\p -> action p n))
freezeIOBuffer :: (Storable a) => IOBuffer a -> IO (Boxed a)
freezeIOBuffer buffer = withIOBuffer buffer (\p n -> strictBoxed <$> peekArray n p)
readIOBuffer :: (Storable a) => IOBuffer a -> Int -> IO (Either MathError a)
readIOBuffer buffer i = case indexCheck (ioBufferLength buffer) i of
    Left e -> pure (Left e)
    Right () -> withIOBuffer buffer (\p _ -> Right <$> peekElemOff p i)
writeIOBuffer :: (Storable a) => IOBuffer a -> Int -> a -> IO (Either MathError ())
writeIOBuffer buffer i x = case indexCheck (ioBufferLength buffer) i of
    Left e -> pure (Left e)
    Right () -> withIOBuffer buffer (\p _ -> Right <$> pokeElemOff p i x)
