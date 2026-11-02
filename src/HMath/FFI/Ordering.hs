{-# LANGUAGE GADTs #-}
{-# LANGUAGE ScopedTypeVariables #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Recover actual native Ord dictionaries for language-polymorphic APIs.
-- This module transports values; it defines no substitute comparison relation.
module HMath.FFI.Ordering
    (SomeOrdered(..),Resolver,orderedFor,orderedWith,orderedFromPrototype,orderedMaybe) where

import Data.List (transpose)
import Data.Proxy (Proxy(..))
import Data.Typeable (Typeable,cast)
import qualified HMath.Backend as B
import qualified HMath.Expression as E
import qualified HMath.Geometry as G
import qualified HMath.Graph.Core as Graph
import qualified HMath.Interchange.Array as Interchange
import qualified HMath.FFI.Autodiff as AD
import qualified HMath.FFI.AutodiffValue as ADV
import HMath.FFI.Coefficient
import qualified HMath.FFI.GraphCodec as W
import qualified HMath.FFI.LinearCodec as L
import qualified HMath.FFI.Value as V

data SomeOrdered where
    SomeOrdered :: (Typeable a,Ord a) => (a -> IO V.Value) -> (V.Value -> IO a) -> SomeOrdered

type Resolver = V.Value -> IO (Maybe SomeOrdered)

orderedFor :: [V.Value] -> IO SomeOrdered
orderedFor = orderedWith []

-- A prototype is a representative value of the desired native type, not data
-- added to the original algorithm. Empty arrays/None alone do not invent an
-- element type. Callers must supply a concrete nested example when necessary.
orderedFromPrototype :: V.Value -> IO SomeOrdered
orderedFromPrototype prototype = orderedFor [prototype]

orderedMaybe :: SomeOrdered -> SomeOrdered
orderedMaybe (SomeOrdered write readValue) = SomeOrdered
    (maybe (pure V.None) write)
    (\value -> case value of V.None -> pure Nothing;_ -> Just <$> readValue value)

orderedOpaque :: forall a. (Typeable a,Ord a) => Proxy a -> Int -> SomeOrdered
orderedOpaque _ kind = SomeOrdered (pure . W.boxed kind) (W.unboxed kind :: V.Value -> IO a)

readCoefficient :: forall a. Coefficient a => V.Value -> IO a
readCoefficient (V.Index value) = maybe (V.invalid "Haskell Int category type differs") pure (cast value)
readCoefficient value = V.asScalar value

-- Extensions can recognize their own typed envelopes without making this
-- shared module import every foundation/domain adapter (and create cycles).
orderedWith :: [Resolver] -> [V.Value] -> IO SomeOrdered
orderedWith _ [] = V.invalid "Ord category type cannot be inferred from an empty collection; provide a prototype"
orderedWith resolvers values@(first:_) = do
    extension <- tryResolvers resolvers first
    case extension of
        Just result -> pure result
        Nothing -> infer
  where
    recurse = orderedWith resolvers
    tryResolvers [] _ = pure Nothing
    tryResolvers (resolver:rest) value = do
        result <- resolver value
        case result of Just _ -> pure result;Nothing -> tryResolvers rest value
    nonmissing = [value | value <- values,case value of V.None -> False;_ -> True]
    infer
        | length nonmissing /= length values =
            if null nonmissing
                then V.invalid "optional Ord category type requires a nonmissing prototype"
                else orderedMaybe <$> recurse nonmissing
        | otherwise = case first of
            V.Scalar witness (_ :: a) -> case orderingDict (Proxy :: Proxy a) of
                Just Dict -> pure (SomeOrdered (pure . V.Scalar witness) (readCoefficient :: V.Value -> IO a))
                Nothing -> V.unsupported "the original coefficient type has no Ord instance"
            V.Index _ -> pure (SomeOrdered (pure . V.Index) V.asIndex)
            V.Boolean _ -> pure (SomeOrdered (pure . V.Boolean) V.asBoolean)
            V.Text _ -> pure (SomeOrdered (pure . V.Text) V.asText)
            V.List _ -> do
                groups <- mapM V.asList values
                SomeOrdered write readValue <- recurse (concat groups)
                pure (SomeOrdered (fmap V.List . mapM write) (\value -> V.asList value >>= mapM readValue))
            V.Tuple fields -> tupleOrdered (length fields)
            V.Opaque 458 _ _ _ _ -> pure (orderedOpaque (Proxy :: Proxy Interchange.DType) 458)
            V.Opaque 61 _ _ _ _ -> pure (orderedOpaque (Proxy :: Proxy Graph.Edge) 61)
            V.Opaque 80 _ _ _ _ -> pure (orderedOpaque (Proxy :: Proxy E.Expr) 80)
            V.Opaque 81 _ _ _ _ -> pure (orderedOpaque (Proxy :: Proxy E.ExprNode) 81)
            V.Opaque 169 _ _ _ _ -> pure (orderedOpaque (Proxy :: Proxy G.Point2) 169)
            V.Opaque 170 _ _ _ _ -> pure (orderedOpaque (Proxy :: Proxy G.Point3) 170)
            V.Opaque 171 _ _ _ _ -> pure (orderedOpaque (Proxy :: Proxy G.PointND) 171)
            V.Opaque 188 _ _ _ _ -> pure (orderedOpaque (Proxy :: Proxy G.Orientation) 188)
            V.Opaque 189 _ _ _ _ -> pure (orderedOpaque (Proxy :: Proxy G.Location) 189)
            V.Opaque 289 _ _ _ _ -> do
                AD.Tower (_ :: a) <- ADV.asADTower first
                case AD.orderingDict (Proxy :: Proxy a) of
                    Nothing -> V.unsupported "the original Autodiff type has no Ord instance"
                    Just AD.Dict -> pure (SomeOrdered
                        (pure . ADV.fromADTower . AD.Tower)
                        (\value -> do
                            AD.Tower other <- ADV.asADTower value
                            maybe (V.invalid "Autodiff category types differ") pure (cast other :: Maybe a)))
            V.Opaque 100 _ _ _ _ -> do
                name <- L.objectName first
                case name of
                    "HMath.Backend.Provider" -> pure (SomeOrdered L.encodeProvider (L.unbox name :: V.Value -> IO B.Provider))
                    "HMath.Backend.IntegerABI" -> pure (SomeOrdered L.encodeIntegerABI (L.unbox name :: V.Value -> IO B.IntegerABI))
                    _ -> V.unsupported "original Ord dictionary unavailable for this linear-domain type"
            _ -> V.unsupported "original Ord dictionary unavailable for this native type"
    tupleOrdered count = do
        rows <- mapM (V.asTuple count) values
        let columns=transpose rows
        case count of
            0 -> pure (SomeOrdered (\() -> pure (V.Tuple [])) (\value -> V.asTuple 0 value >> pure ()))
            2 -> do
                SomeOrdered write0 read0 <- recurse (columns !! 0)
                SomeOrdered write1 read1 <- recurse (columns !! 1)
                pure (SomeOrdered
                    (\(a0,a1) -> V.Tuple <$> sequence [write0 a0,write1 a1])
                    (\value -> do
                        items <- V.asTuple 2 value
                        case items of
                            [v0,v1] -> (,) <$> read0 v0 <*> read1 v1
                            _ -> V.invalid "category tuple arity differs"))
            3 -> do
                SomeOrdered write0 read0 <- recurse (columns !! 0)
                SomeOrdered write1 read1 <- recurse (columns !! 1)
                SomeOrdered write2 read2 <- recurse (columns !! 2)
                pure (SomeOrdered
                    (\(a0,a1,a2) -> V.Tuple <$> sequence [write0 a0,write1 a1,write2 a2])
                    (\value -> do
                        items <- V.asTuple 3 value
                        case items of
                            [v0,v1,v2] -> (,,) <$> read0 v0 <*> read1 v1 <*> read2 v2
                            _ -> V.invalid "category tuple arity differs"))
            4 -> do
                SomeOrdered write0 read0 <- recurse (columns !! 0)
                SomeOrdered write1 read1 <- recurse (columns !! 1)
                SomeOrdered write2 read2 <- recurse (columns !! 2)
                SomeOrdered write3 read3 <- recurse (columns !! 3)
                pure (SomeOrdered
                    (\(a0,a1,a2,a3) -> V.Tuple <$> sequence [write0 a0,write1 a1,write2 a2,write3 a3])
                    (\value -> do
                        items <- V.asTuple 4 value
                        case items of
                            [v0,v1,v2,v3] -> (,,,) <$> read0 v0 <*> read1 v1 <*> read2 v2 <*> read3 v3
                            _ -> V.invalid "category tuple arity differs"))
            5 -> do
                SomeOrdered write0 read0 <- recurse (columns !! 0)
                SomeOrdered write1 read1 <- recurse (columns !! 1)
                SomeOrdered write2 read2 <- recurse (columns !! 2)
                SomeOrdered write3 read3 <- recurse (columns !! 3)
                SomeOrdered write4 read4 <- recurse (columns !! 4)
                pure (SomeOrdered
                    (\(a0,a1,a2,a3,a4) -> V.Tuple <$> sequence [write0 a0,write1 a1,write2 a2,write3 a3,write4 a4])
                    (\value -> do
                        items <- V.asTuple 5 value
                        case items of
                            [v0,v1,v2,v3,v4] -> (,,,,) <$> read0 v0 <*> read1 v1 <*> read2 v2 <*> read3 v3 <*> read4 v4
                            _ -> V.invalid "category tuple arity differs"))
            6 -> do
                SomeOrdered write0 read0 <- recurse (columns !! 0)
                SomeOrdered write1 read1 <- recurse (columns !! 1)
                SomeOrdered write2 read2 <- recurse (columns !! 2)
                SomeOrdered write3 read3 <- recurse (columns !! 3)
                SomeOrdered write4 read4 <- recurse (columns !! 4)
                SomeOrdered write5 read5 <- recurse (columns !! 5)
                pure (SomeOrdered
                    (\(a0,a1,a2,a3,a4,a5) -> V.Tuple <$> sequence [write0 a0,write1 a1,write2 a2,write3 a3,write4 a4,write5 a5])
                    (\value -> do
                        items <- V.asTuple 6 value
                        case items of
                            [v0,v1,v2,v3,v4,v5] -> (,,,,,) <$> read0 v0 <*> read1 v1 <*> read2 v2 <*> read3 v3 <*> read4 v4 <*> read5 v5
                            _ -> V.invalid "category tuple arity differs"))
            7 -> do
                SomeOrdered write0 read0 <- recurse (columns !! 0)
                SomeOrdered write1 read1 <- recurse (columns !! 1)
                SomeOrdered write2 read2 <- recurse (columns !! 2)
                SomeOrdered write3 read3 <- recurse (columns !! 3)
                SomeOrdered write4 read4 <- recurse (columns !! 4)
                SomeOrdered write5 read5 <- recurse (columns !! 5)
                SomeOrdered write6 read6 <- recurse (columns !! 6)
                pure (SomeOrdered
                    (\(a0,a1,a2,a3,a4,a5,a6) -> V.Tuple <$> sequence [write0 a0,write1 a1,write2 a2,write3 a3,write4 a4,write5 a5,write6 a6])
                    (\value -> do
                        items <- V.asTuple 7 value
                        case items of
                            [v0,v1,v2,v3,v4,v5,v6] -> (,,,,,,) <$> read0 v0 <*> read1 v1 <*> read2 v2 <*> read3 v3 <*> read4 v4 <*> read5 v5 <*> read6 v6
                            _ -> V.invalid "category tuple arity differs"))
            8 -> do
                SomeOrdered write0 read0 <- recurse (columns !! 0)
                SomeOrdered write1 read1 <- recurse (columns !! 1)
                SomeOrdered write2 read2 <- recurse (columns !! 2)
                SomeOrdered write3 read3 <- recurse (columns !! 3)
                SomeOrdered write4 read4 <- recurse (columns !! 4)
                SomeOrdered write5 read5 <- recurse (columns !! 5)
                SomeOrdered write6 read6 <- recurse (columns !! 6)
                SomeOrdered write7 read7 <- recurse (columns !! 7)
                pure (SomeOrdered
                    (\(a0,a1,a2,a3,a4,a5,a6,a7) -> V.Tuple <$> sequence [write0 a0,write1 a1,write2 a2,write3 a3,write4 a4,write5 a5,write6 a6,write7 a7])
                    (\value -> do
                        items <- V.asTuple 8 value
                        case items of
                            [v0,v1,v2,v3,v4,v5,v6,v7] -> (,,,,,,,) <$> read0 v0 <*> read1 v1 <*> read2 v2 <*> read3 v3 <*> read4 v4 <*> read5 v5 <*> read6 v6 <*> read7 v7
                            _ -> V.invalid "category tuple arity differs"))
            9 -> do
                SomeOrdered write0 read0 <- recurse (columns !! 0)
                SomeOrdered write1 read1 <- recurse (columns !! 1)
                SomeOrdered write2 read2 <- recurse (columns !! 2)
                SomeOrdered write3 read3 <- recurse (columns !! 3)
                SomeOrdered write4 read4 <- recurse (columns !! 4)
                SomeOrdered write5 read5 <- recurse (columns !! 5)
                SomeOrdered write6 read6 <- recurse (columns !! 6)
                SomeOrdered write7 read7 <- recurse (columns !! 7)
                SomeOrdered write8 read8 <- recurse (columns !! 8)
                pure (SomeOrdered
                    (\(a0,a1,a2,a3,a4,a5,a6,a7,a8) -> V.Tuple <$> sequence [write0 a0,write1 a1,write2 a2,write3 a3,write4 a4,write5 a5,write6 a6,write7 a7,write8 a8])
                    (\value -> do
                        items <- V.asTuple 9 value
                        case items of
                            [v0,v1,v2,v3,v4,v5,v6,v7,v8] -> (,,,,,,,,) <$> read0 v0 <*> read1 v1 <*> read2 v2 <*> read3 v3 <*> read4 v4 <*> read5 v5 <*> read6 v6 <*> read7 v7 <*> read8 v8
                            _ -> V.invalid "category tuple arity differs"))
            10 -> do
                SomeOrdered write0 read0 <- recurse (columns !! 0)
                SomeOrdered write1 read1 <- recurse (columns !! 1)
                SomeOrdered write2 read2 <- recurse (columns !! 2)
                SomeOrdered write3 read3 <- recurse (columns !! 3)
                SomeOrdered write4 read4 <- recurse (columns !! 4)
                SomeOrdered write5 read5 <- recurse (columns !! 5)
                SomeOrdered write6 read6 <- recurse (columns !! 6)
                SomeOrdered write7 read7 <- recurse (columns !! 7)
                SomeOrdered write8 read8 <- recurse (columns !! 8)
                SomeOrdered write9 read9 <- recurse (columns !! 9)
                pure (SomeOrdered
                    (\(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9) -> V.Tuple <$> sequence [write0 a0,write1 a1,write2 a2,write3 a3,write4 a4,write5 a5,write6 a6,write7 a7,write8 a8,write9 a9])
                    (\value -> do
                        items <- V.asTuple 10 value
                        case items of
                            [v0,v1,v2,v3,v4,v5,v6,v7,v8,v9] -> (,,,,,,,,,) <$> read0 v0 <*> read1 v1 <*> read2 v2 <*> read3 v3 <*> read4 v4 <*> read5 v5 <*> read6 v6 <*> read7 v7 <*> read8 v8 <*> read9 v9
                            _ -> V.invalid "category tuple arity differs"))
            11 -> do
                SomeOrdered write0 read0 <- recurse (columns !! 0)
                SomeOrdered write1 read1 <- recurse (columns !! 1)
                SomeOrdered write2 read2 <- recurse (columns !! 2)
                SomeOrdered write3 read3 <- recurse (columns !! 3)
                SomeOrdered write4 read4 <- recurse (columns !! 4)
                SomeOrdered write5 read5 <- recurse (columns !! 5)
                SomeOrdered write6 read6 <- recurse (columns !! 6)
                SomeOrdered write7 read7 <- recurse (columns !! 7)
                SomeOrdered write8 read8 <- recurse (columns !! 8)
                SomeOrdered write9 read9 <- recurse (columns !! 9)
                SomeOrdered write10 read10 <- recurse (columns !! 10)
                pure (SomeOrdered
                    (\(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10) -> V.Tuple <$> sequence [write0 a0,write1 a1,write2 a2,write3 a3,write4 a4,write5 a5,write6 a6,write7 a7,write8 a8,write9 a9,write10 a10])
                    (\value -> do
                        items <- V.asTuple 11 value
                        case items of
                            [v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10] -> (,,,,,,,,,,) <$> read0 v0 <*> read1 v1 <*> read2 v2 <*> read3 v3 <*> read4 v4 <*> read5 v5 <*> read6 v6 <*> read7 v7 <*> read8 v8 <*> read9 v9 <*> read10 v10
                            _ -> V.invalid "category tuple arity differs"))
            12 -> do
                SomeOrdered write0 read0 <- recurse (columns !! 0)
                SomeOrdered write1 read1 <- recurse (columns !! 1)
                SomeOrdered write2 read2 <- recurse (columns !! 2)
                SomeOrdered write3 read3 <- recurse (columns !! 3)
                SomeOrdered write4 read4 <- recurse (columns !! 4)
                SomeOrdered write5 read5 <- recurse (columns !! 5)
                SomeOrdered write6 read6 <- recurse (columns !! 6)
                SomeOrdered write7 read7 <- recurse (columns !! 7)
                SomeOrdered write8 read8 <- recurse (columns !! 8)
                SomeOrdered write9 read9 <- recurse (columns !! 9)
                SomeOrdered write10 read10 <- recurse (columns !! 10)
                SomeOrdered write11 read11 <- recurse (columns !! 11)
                pure (SomeOrdered
                    (\(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11) -> V.Tuple <$> sequence [write0 a0,write1 a1,write2 a2,write3 a3,write4 a4,write5 a5,write6 a6,write7 a7,write8 a8,write9 a9,write10 a10,write11 a11])
                    (\value -> do
                        items <- V.asTuple 12 value
                        case items of
                            [v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11] -> (,,,,,,,,,,,) <$> read0 v0 <*> read1 v1 <*> read2 v2 <*> read3 v3 <*> read4 v4 <*> read5 v5 <*> read6 v6 <*> read7 v7 <*> read8 v8 <*> read9 v9 <*> read10 v10 <*> read11 v11
                            _ -> V.invalid "category tuple arity differs"))
            13 -> do
                SomeOrdered write0 read0 <- recurse (columns !! 0)
                SomeOrdered write1 read1 <- recurse (columns !! 1)
                SomeOrdered write2 read2 <- recurse (columns !! 2)
                SomeOrdered write3 read3 <- recurse (columns !! 3)
                SomeOrdered write4 read4 <- recurse (columns !! 4)
                SomeOrdered write5 read5 <- recurse (columns !! 5)
                SomeOrdered write6 read6 <- recurse (columns !! 6)
                SomeOrdered write7 read7 <- recurse (columns !! 7)
                SomeOrdered write8 read8 <- recurse (columns !! 8)
                SomeOrdered write9 read9 <- recurse (columns !! 9)
                SomeOrdered write10 read10 <- recurse (columns !! 10)
                SomeOrdered write11 read11 <- recurse (columns !! 11)
                SomeOrdered write12 read12 <- recurse (columns !! 12)
                pure (SomeOrdered
                    (\(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12) -> V.Tuple <$> sequence [write0 a0,write1 a1,write2 a2,write3 a3,write4 a4,write5 a5,write6 a6,write7 a7,write8 a8,write9 a9,write10 a10,write11 a11,write12 a12])
                    (\value -> do
                        items <- V.asTuple 13 value
                        case items of
                            [v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12] -> (,,,,,,,,,,,,) <$> read0 v0 <*> read1 v1 <*> read2 v2 <*> read3 v3 <*> read4 v4 <*> read5 v5 <*> read6 v6 <*> read7 v7 <*> read8 v8 <*> read9 v9 <*> read10 v10 <*> read11 v11 <*> read12 v12
                            _ -> V.invalid "category tuple arity differs"))
            14 -> do
                SomeOrdered write0 read0 <- recurse (columns !! 0)
                SomeOrdered write1 read1 <- recurse (columns !! 1)
                SomeOrdered write2 read2 <- recurse (columns !! 2)
                SomeOrdered write3 read3 <- recurse (columns !! 3)
                SomeOrdered write4 read4 <- recurse (columns !! 4)
                SomeOrdered write5 read5 <- recurse (columns !! 5)
                SomeOrdered write6 read6 <- recurse (columns !! 6)
                SomeOrdered write7 read7 <- recurse (columns !! 7)
                SomeOrdered write8 read8 <- recurse (columns !! 8)
                SomeOrdered write9 read9 <- recurse (columns !! 9)
                SomeOrdered write10 read10 <- recurse (columns !! 10)
                SomeOrdered write11 read11 <- recurse (columns !! 11)
                SomeOrdered write12 read12 <- recurse (columns !! 12)
                SomeOrdered write13 read13 <- recurse (columns !! 13)
                pure (SomeOrdered
                    (\(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13) -> V.Tuple <$> sequence [write0 a0,write1 a1,write2 a2,write3 a3,write4 a4,write5 a5,write6 a6,write7 a7,write8 a8,write9 a9,write10 a10,write11 a11,write12 a12,write13 a13])
                    (\value -> do
                        items <- V.asTuple 14 value
                        case items of
                            [v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13] -> (,,,,,,,,,,,,,) <$> read0 v0 <*> read1 v1 <*> read2 v2 <*> read3 v3 <*> read4 v4 <*> read5 v5 <*> read6 v6 <*> read7 v7 <*> read8 v8 <*> read9 v9 <*> read10 v10 <*> read11 v11 <*> read12 v12 <*> read13 v13
                            _ -> V.invalid "category tuple arity differs"))
            15 -> do
                SomeOrdered write0 read0 <- recurse (columns !! 0)
                SomeOrdered write1 read1 <- recurse (columns !! 1)
                SomeOrdered write2 read2 <- recurse (columns !! 2)
                SomeOrdered write3 read3 <- recurse (columns !! 3)
                SomeOrdered write4 read4 <- recurse (columns !! 4)
                SomeOrdered write5 read5 <- recurse (columns !! 5)
                SomeOrdered write6 read6 <- recurse (columns !! 6)
                SomeOrdered write7 read7 <- recurse (columns !! 7)
                SomeOrdered write8 read8 <- recurse (columns !! 8)
                SomeOrdered write9 read9 <- recurse (columns !! 9)
                SomeOrdered write10 read10 <- recurse (columns !! 10)
                SomeOrdered write11 read11 <- recurse (columns !! 11)
                SomeOrdered write12 read12 <- recurse (columns !! 12)
                SomeOrdered write13 read13 <- recurse (columns !! 13)
                SomeOrdered write14 read14 <- recurse (columns !! 14)
                pure (SomeOrdered
                    (\(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14) -> V.Tuple <$> sequence [write0 a0,write1 a1,write2 a2,write3 a3,write4 a4,write5 a5,write6 a6,write7 a7,write8 a8,write9 a9,write10 a10,write11 a11,write12 a12,write13 a13,write14 a14])
                    (\value -> do
                        items <- V.asTuple 15 value
                        case items of
                            [v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14] -> (,,,,,,,,,,,,,,) <$> read0 v0 <*> read1 v1 <*> read2 v2 <*> read3 v3 <*> read4 v4 <*> read5 v5 <*> read6 v6 <*> read7 v7 <*> read8 v8 <*> read9 v9 <*> read10 v10 <*> read11 v11 <*> read12 v12 <*> read13 v13 <*> read14 v14
                            _ -> V.invalid "category tuple arity differs"))
            _ -> V.unsupported "Ord category tuple arity must be zero or between two and fifteen (standard Prelude instances)"
