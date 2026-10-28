{-# LANGUAGE ScopedTypeVariables #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Pinned CPU storage with shared mutable views. Views retain the same
ForeignPtr, so garbage collection frees storage exactly once after the last
view/callback dies. Freeze/thaw copy; slices and buffer access are zero-copy.
Values have their Storable ABI alignment. Callers synchronize concurrent writes.
-}
module HMath.Tensor.Mutable (
    MutableTensor,
    newMutable,
    thawTensor,
    freezeTensor,
    mutableShape,
    readMutable,
    writeMutable,
    modifyMutable,
    sliceMutable,
    transposeMutable,
    withMutableBuffer,
    mutableAlignment,
) where

import Data.Proxy (Proxy)
import Foreign.ForeignPtr (ForeignPtr, mallocForeignPtrArray, withForeignPtr)
import Foreign.Marshal.Array (advancePtr, pokeArray)
import Foreign.Ptr (Ptr)
import Foreign.Storable (Storable, alignment, peekElemOff, pokeElemOff, sizeOf)
import HMath.Error
import HMath.Tensor

{- | Pinned CPU tensor with shared mutable views and garbage-collected ForeignPtr ownership.
Freeze/thaw copy; callers synchronize concurrent writes.
-}
data MutableTensor a = MutableTensor [Int] [Int] Int Int (ForeignPtr a)

{- | Return current mutable-view dimensions in axis order. Slices/transposes can change the
view shape while sharing storage.
-}
mutableShape :: MutableTensor a -> [Int]
mutableShape (MutableTensor dims _ _ _ _) = dims

{- | Given a type Proxy, return the Storable ABI alignment in bytes. This reports the
element type requirement, not a user-selectable alignment.
-}
mutableAlignment :: forall a. (Storable a) => Proxy a -> Int
mutableAlignment _ = alignment (undefined :: a)

{- | Given checked dimensions then fill value, allocate pinned row-major storage filled with
that value. Shape/byte-size overflow returns Left MathError; allocation errors remain
IO exceptions. Empty tensors are valid.
-}
newMutable :: forall a. (Storable a) => [Int] -> a -> IO (Either MathError (MutableTensor a))
newMutable dims value = case shapeSize dims of
    Left e -> pure (Left e)
    Right size
        | toInteger size * toInteger (sizeOf (undefined :: a)) > toInteger (maxBound :: Int) ->
            pure (Left (InvalidArgument "newMutable: byte allocation overflow"))
    Right size -> do
        storage <- mallocForeignPtrArray (max 1 size)
        withForeignPtr storage $ \pointer -> pokeArray pointer (replicate size value)
        let strides = if size == 0 then replicate (length dims) 0 else drop 1 (scanr (*) 1 dims)
        pure (Right (MutableTensor dims strides 0 size storage))

{- | Copy logical immutable tensor values to new contiguous pinned mutable storage.
Byte-size overflow returns Left InvalidArgument; allocation failures remain IO
exceptions. The source stays unchanged.
-}
thawTensor :: forall a. (Storable a) => Tensor a -> IO (Either MathError (MutableTensor a))
thawTensor t
    | toInteger (numel t) * toInteger (sizeOf (undefined :: a)) > toInteger (maxBound :: Int) =
        pure (Left (InvalidArgument "thawTensor: byte allocation overflow"))
    | otherwise = do
        let xs = tensorValues t; size = numel t; dims = tensorShape t
        storage <- mallocForeignPtrArray (max 1 size)
        withForeignPtr storage $ \pointer -> pokeArray pointer xs
        pure
            ( Right
                ( MutableTensor
                    dims
                    (if size == 0 then replicate (length dims) 0 else drop 1 (scanr (*) 1 dims))
                    0
                    size
                    storage
                )
            )

indices :: [Int] -> [[Int]]
indices dims | 0 `elem` dims = []
indices [] = [[]]
indices (d : ds) = [i : is | i <- [0 .. d - 1], is <- indices ds]
address :: MutableTensor a -> [Int] -> Either MathError Int
address (MutableTensor dims strides offset _ _) ix
    | length ix /= length dims || or (zipWith (\i d -> i < 0 || i >= d) ix dims) =
        Left (InvalidArgument "mutable tensor: index out of bounds")
    | otherwise = Right (offset + sum (zipWith (*) ix strides))

{- | Given a mutable view then full zero-based coordinate list, read one element through the
view strides. Wrong rank or out-of-range coordinates return Left InvalidArgument.
Callers synchronize concurrent writes.
-}
readMutable :: (Storable a) => MutableTensor a -> [Int] -> IO (Either MathError a)
readMutable t@(MutableTensor _ _ _ _ storage) ix = case address t ix of
    Left e -> pure (Left e)
    Right location -> Right <$> withForeignPtr storage (\pointer -> peekElemOff pointer location)

{- | Given a mutable view, full coordinate list, then value, update that storage element.
Invalid coordinates return Left InvalidArgument without writing; synchronize concurrent
access externally.
-}
writeMutable :: (Storable a) => MutableTensor a -> [Int] -> a -> IO (Either MathError ())
writeMutable t@(MutableTensor _ _ _ _ storage) ix value = case address t ix of
    Left e -> pure (Left e)
    Right location -> Right <$> withForeignPtr storage (\pointer -> pokeElemOff pointer location value)

{- | Given view, coordinates, then transformation, read and replace an element. Invalid
coordinates fail. This read-modify-write is not atomic across threads; callers provide
synchronization.
-}
modifyMutable :: (Storable a) => MutableTensor a -> [Int] -> (a -> a) -> IO (Either MathError ())
modifyMutable t ix action = do
    result <- readMutable t ix
    case result of { Left e -> pure (Left e); Right value -> writeMutable t ix (action value) }

{- | Copy current logical view values into a new immutable tensor in row-major order. Return
checked tensor construction errors; later mutable writes do not affect the result.
-}
freezeTensor :: (Storable a) => MutableTensor a -> IO (Either MathError (Tensor a))
freezeTensor t = do
    values <- traverse (readMutable t) (indices (mutableShape t))
    pure (sequence values >>= tensor (mutableShape t))

{- | Given axis, start, count, nonzero step, then view, return a zero-copy mutable slice
retaining shared ForeignPtr ownership. Negative steps are supported if all reached
indices stay in bounds. Invalid extent/axis or stride overflow fails.
-}
sliceMutable :: Int -> Int -> Int -> Int -> MutableTensor a -> Either MathError (MutableTensor a)
sliceMutable axis start count step (MutableTensor dims strides offset size storage)
    | axis < 0 || axis >= length dims = Left (InvalidArgument "sliceMutable: invalid axis")
    | count < 0
        || step == 0
        || start < 0
        || (count > 0 && (start >= dims !! axis || end < 0 || end >= toInteger (dims !! axis)))
        || (count == 0 && start > dims !! axis) =
        Left (InvalidArgument "sliceMutable: invalid extent")
    | stride < toInteger (minBound :: Int) || stride > toInteger (maxBound :: Int) =
        Left (InvalidArgument "sliceMutable: stride overflow")
    | otherwise =
        Right
            ( MutableTensor
                (replace axis count dims)
                (replace axis (fromInteger stride) strides)
                (if count == 0 then offset else fromInteger newOffset)
                size
                storage
            )
  where
    end = toInteger start + toInteger (count - 1) * toInteger step
    stride = toInteger (strides !! axis) * toInteger step
    newOffset = toInteger offset + toInteger start * toInteger (strides !! axis)
    replace i x xs = take i xs ++ x : drop (i + 1) xs

{- | Reverse the order of all shape axes and strides, returning a zero-copy mutable view.
For rank two this is a matrix transpose; storage ownership remains shared.
-}
transposeMutable :: MutableTensor a -> MutableTensor a
transposeMutable (MutableTensor dims strides offset size storage) = MutableTensor (reverse dims) (reverse strides) offset size storage

{- | The pointer is valid only during the callback. Shape/strides describe views;
callbacks must honor their extents and may not retain the borrowed pointer.
-}
withMutableBuffer :: (Storable a) => MutableTensor a -> (Ptr a -> [Int] -> [Int] -> IO b) -> IO b
withMutableBuffer (MutableTensor dims strides offset _ storage) action = withForeignPtr storage $ \pointer -> action (pointer `advancePtr` offset) dims strides
