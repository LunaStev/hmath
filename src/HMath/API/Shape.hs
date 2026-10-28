{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveFoldable #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveTraversable #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE RoleAnnotations #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE ViewPatterns #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Runtime-checked shapes and nominal type-indexed matrices/tensors. Shape
witnesses never coerce arbitrary dimensions. Conversion checks occur at the
dynamic/static boundary; multiplication then requires matching types.
-}
module HMath.API.Shape (
    Shape,
    shapeDimensions,
    shapeElements,
    makeShape,
    pattern ScalarShape,
    pattern VectorShape,
    pattern MatrixShape,
    StaticMatrix,
    staticMatrix,
    dynamicMatrix,
    staticMultiply,
    staticTranspose,
    KnownShape (..),
    StaticTensor,
    staticTensor,
    dynamicTensor,
    Coordinates,
    coordinates,
    coordinateValues,
    coordinatesToVector,
) where

import Data.Proxy (Proxy (..))
import GHC.TypeLits (KnownNat, Nat, natVal)
import HMath.Error
import qualified HMath.Matrix as M
import qualified HMath.Tensor as T
import qualified HMath.Vector as V

-- | Scalars have shape [] and one element. Zero axes are allowed.
data Shape = Shape ![Int] !Int deriving (Eq, Ord, Show)

{- | Return runtime dimensions in axis order. Scalars have []; zero-length axes are
retained.
-}
shapeDimensions :: Shape -> [Int]
shapeDimensions (Shape ds _) = ds

{- | Return the validated shape product, including one for scalar [] and zero when an axis
is zero.
-}
shapeElements :: Shape -> Int
shapeElements (Shape _ n) = n

{- | Validate nonnegative dimensions and an Int-representable element product, returning an
immutable shape witness. Invalid dimensions/overflow return Left MathError. Example:
shapeElements \<$> makeShape [2,3] == Right 6.
-}
makeShape :: [Int] -> Either MathError Shape
makeShape ds = Shape ds <$> T.shapeSize ds

-- | Read-only views: construction always uses makeShape.
pattern ScalarShape :: Shape
pattern ScalarShape <- (shapeDimensions -> [])

pattern VectorShape :: Int -> Shape
pattern VectorShape n <- (shapeDimensions -> [n])
pattern MatrixShape :: Int -> Int -> Shape
pattern MatrixShape m n <- (shapeDimensions -> [m, n])

{- | Nominal type-indexed matrix dimensions,validated by staticMatrix. Compatible
multiplication is expressed by shared type indices.
-}
newtype StaticMatrix (m :: Nat) (n :: Nat) a = StaticMatrix (M.Matrix a) deriving (Eq, Show)

type role StaticMatrix nominal nominal representational

{- | Given a dynamic matrix, compare its dimensions against type-level m and n, returning a
nominally indexed witness. Reject type-level Int overflow or runtime mismatch.
-}
staticMatrix ::
    forall m n a. (KnownNat m, KnownNat n) => M.Matrix a -> Either MathError (StaticMatrix m n a)
staticMatrix a = do
    r <- natInt (Proxy :: Proxy m)
    c <- natInt (Proxy :: Proxy n)
    if M.shape a == (r, c) then Right (StaticMatrix a) else Left (ShapeMismatch (r, c) (M.shape a))

{- | Forget the nominal type-level dimensions of a StaticMatrix, returning the same
immutable dynamic matrix without changing its values.
-}
dynamicMatrix :: StaticMatrix m n a -> M.Matrix a
dynamicMatrix (StaticMatrix a) = a

{- | Multiply statically compatible m-by-k and k-by-n matrices. Return an m-by-n witness;
checked dynamic size errors can still return Left MathError. Num arithmetic follows the
element instance.
-}
staticMultiply ::
    (Num a) => StaticMatrix m k a -> StaticMatrix k n a -> Either MathError (StaticMatrix m n a)
staticMultiply (StaticMatrix a) (StaticMatrix b) = StaticMatrix <$> M.multiplyChecked a b

{- | Transpose a StaticMatrix m n to StaticMatrix n m, preserving values with axes
exchanged.
-}
staticTranspose :: StaticMatrix m n a -> StaticMatrix n m a
staticTranspose (StaticMatrix a) = StaticMatrix (M.transposeMatrix a)

instance Functor (StaticMatrix m n) where
    fmap f (StaticMatrix a) =
        StaticMatrix (either (error . show) id (uncurry M.fromListChecked (M.shape a) (map f (M.toList a))))
instance Foldable (StaticMatrix m n) where foldMap f = foldMap f . M.toList . dynamicMatrix
instance Traversable (StaticMatrix m n) where
    traverse f (StaticMatrix a) =
        (\xs -> StaticMatrix (either (error . show) id (uncurry M.fromListChecked (M.shape a) xs)))
            <$> traverse f (M.toList a)

-- | Type-level list of natural dimensions, reflected without Int truncation.
class KnownShape (ds :: [Nat]) where
    {- | Given a type-level shape proxy, reflect exact Integer dimensions
    without truncation to Int.
    -}
    reflectedShape :: proxy ds -> [Integer]

instance KnownShape '[] where reflectedShape _ = []
instance (KnownNat n, KnownShape ns) => KnownShape (n ': ns) where
    reflectedShape _ = toInteger (natVal (Proxy :: Proxy n)) : reflectedShape (Proxy :: Proxy ns)

{- | Nominal type-indexed tensor shape,validated against reflected runtime dimensions by
staticTensor.
-}
newtype StaticTensor (ds :: [Nat]) a = StaticTensor (T.Tensor a) deriving (Eq, Show)

type role StaticTensor nominal representational

{- | Given dynamic tensor and type-level shape ds, return a nominal witness only if runtime
dimensions match reflectedShape exactly. A mismatch returns Left InvalidArgument.
-}
staticTensor :: forall ds a. (KnownShape ds) => T.Tensor a -> Either MathError (StaticTensor ds a)
staticTensor t
    | map toInteger (T.tensorShape t) == reflectedShape (Proxy :: Proxy ds) = Right (StaticTensor t)
    | otherwise = Left (InvalidArgument "staticTensor: type-level shape differs from runtime shape")

{- | Forget a StaticTensor shape witness, returning its underlying immutable dynamic tensor
without numerical conversion.
-}
dynamicTensor :: StaticTensor ds a -> T.Tensor a
dynamicTensor (StaticTensor t) = t

{- | Fixed-length coordinates with lawful zip Applicative. Elements are lazy;
pure/fmap/traverse preserve length. Type-level lengths can exceed Int; the
conversion to ordinary vectors rejects such lengths before traversing data.
-}
newtype Coordinates (n :: Nat) a = Coordinates [a]
    deriving (Eq, Show, Functor, Foldable, Traversable)

type role Coordinates nominal representational

{- | Construct a type-indexed coordinate list only when list length equals the KnownNat
index. A mismatch returns Left InvalidArgument; values remain lazy.
-}
coordinates :: forall n a. (KnownNat n) => [a] -> Either MathError (Coordinates n a)
coordinates xs
    | toInteger (length xs) == toInteger (natVal (Proxy :: Proxy n)) = Right (Coordinates xs)
    | otherwise = Left (InvalidArgument "coordinates: type-level length mismatch")

{- | Extract the ordered list of a Coordinates n value. The nominal length invariant is
preserved by its public constructors.
-}
coordinateValues :: Coordinates n a -> [a]
coordinateValues (Coordinates xs) = xs

instance (KnownNat n) => Applicative (Coordinates n) where
    pure x = Coordinates [x | _ <- [1 .. toInteger (natVal (Proxy :: Proxy n))]]
    Coordinates fs <*> Coordinates xs = Coordinates (zipWith ($) fs xs)

{- | Convert Coordinates n to a dynamic Vector. Reject a type-level length exceeding Int
before traversing the coordinate list; otherwise preserve all values.
-}
coordinatesToVector :: forall n a. (KnownNat n) => Coordinates n a -> Either MathError (V.Vector a)
coordinatesToVector xs = natInt (Proxy :: Proxy n) >> Right (V.vector (coordinateValues xs))

natInt :: (KnownNat n) => Proxy n -> Either MathError Int
natInt p
    | value > toInteger (maxBound :: Int) = Left (InvalidArgument "static dimension exceeds Int")
    | otherwise = Right (fromInteger value)
  where
    value = toInteger (natVal p)
