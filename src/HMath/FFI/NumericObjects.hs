{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Typed instances of existing generic functions. The source functions and
-- original instance dictionaries determine all arithmetic, ordering and errors.
module HMath.FFI.NumericObjects where
import Data.Proxy(Proxy(..))
import Data.Typeable(Typeable,cast)
import Foreign
import Foreign.C
import qualified HMath.Basic as B
import qualified HMath.Scalar as S
import qualified HMath.Linear as L
import qualified HMath.Statistics as T
import qualified HMath.Autodiff as A
import qualified HMath.Geometry.Primitives as G
import qualified HMath.FFI.Autodiff as D
import qualified HMath.FFI.AutodiffValue as AD
import qualified HMath.FFI.Coefficient as C
import qualified HMath.FFI.Value as V
import qualified HMath.FFI.FoundationCodec as F
import HMath.FFI.Ordering

-- Expr has Num/Fractional/Floating but deliberately has no Eq or Ord. Numeric
-- Dual/Quaternion and AD Dual use their distinct original instance families.
data Domain a=Domain {
    writeValue :: a -> V.Value,
    readValue :: V.Value -> IO a,
    fractional :: Maybe(C.Dict(Fractional a)),
    floating :: Maybe(C.Dict(Floating a)),
    equality :: Maybe(C.Dict(Eq a)),
    ordering :: Maybe(C.Dict(Ord a)),
    integral :: Maybe(C.Dict(Integral a)),
    bounded :: Maybe(C.Dict(Bounded a))}
data SomeDomain where
    SomeDomain :: (Typeable a,Num a) => Domain a -> SomeDomain
fromADDict :: Maybe(D.Dict c) -> Maybe(C.Dict c)
fromADDict(Just D.Dict)=Just C.Dict
fromADDict Nothing=Nothing
coefficientDomain :: forall a. C.Coefficient a => C.ScalarType a -> Domain a
coefficientDomain witness=Domain(V.Scalar witness)V.asScalar(C.fractionalDict proxy)(C.floatingDict proxy)(Just C.Dict)(C.orderingDict proxy)(C.integralDict proxy)(C.boundedDict proxy)
  where proxy=Proxy::Proxy a
asTower :: forall a. Typeable a => V.Value -> IO a
asTower value=do
    D.Tower x <- AD.asADTower value
    maybe(V.invalid "original AD Dual coefficient types differ")pure(cast x)
domain :: V.Value -> IO SomeDomain
domain value=case value of
    V.Scalar witness _ -> pure(SomeDomain(coefficientDomain witness))
    V.Opaque 289 _ _ _ _ -> do
        D.Tower(_::a) <- AD.asADTower value
        let proxy=Proxy::Proxy a
        pure(SomeDomain(Domain(AD.fromADTower . D.Tower)asTower(fromADDict(D.fractionalDict proxy))(fromADDict(D.floatingDict proxy))(Just C.Dict)(fromADDict(D.orderingDict proxy)) Nothing Nothing))
    V.Opaque 287 _ _ _ _ -> pure(SomeDomain(Domain AD.fromADExpr AD.asADExpr (Just C.Dict)(Just C.Dict)Nothing Nothing Nothing Nothing :: Domain A.Expr))
    _ -> V.unsupported "generic numeric operation needs an actual numeric scalar, Numeric Dual/Quaternion, AD Dual or AD Expr prototype"
withDict :: String -> Maybe(C.Dict c) -> (c => IO r) -> IO r
withDict _ (Just C.Dict) action=action
withDict name Nothing _=V.unsupported("original type has no "++name++" instance")

-- Native primitive and recursively nested coefficient witnesses are retained.
-- A raw literal is not implicitly promoted to a different coefficient domain.
numeric :: forall a. (Typeable a,Num a) => Domain a -> Int -> [V.Value] -> IO V.Value
numeric d operation values=case(operation,values)of
    (1,[a,b,t]) -> withDict "Fractional" (fractional d) $ do x <- readValue d a;y <- readValue d b;z <- readValue d t;pure(writeValue d(B.lerp x y z))
    (2,[a,b]) -> binary S.add a b
    (3,[a,b]) -> binary S.subtractScalar a b
    (4,[a,b]) -> binary S.multiply a b
    (7,[a]) -> unary S.absolute a
    (8,[a]) -> unary S.sign a
    (9,[a,b]) -> withDict "Integral" (integral d) $ do x <- readValue d a;y <- readValue d b;F.source(S.positiveModulo x y) >>= pure . writeValue d
    (10,[a]) -> listUnary S.cumulativeSum a
    (11,[a]) -> listUnary S.cumulativeProduct a
    (12,[a]) -> listUnary S.prefixSum a
    (13,[a]) -> withDict "Fractional" (fractional d) $ scalarList T.mean a
    (14,[a]) -> withDict "Fractional" (fractional d) $ scalarList T.variance a
    (15,[a]) -> withDict "Floating" (floating d) $ scalarList T.standardDeviation a
    (16,[a]) -> withDict "Fractional" (fractional d) $ withDict "Ord" (ordering d) $ scalarList T.median a
    (17,[a,b]) -> scalarBinaryList L.dot a b
    (18,[a,b]) -> do xs <- readElements a;ys <- readElements b;F.source(L.dotChecked xs ys) >>= pure . writeValue d
    (19,[a]) -> withDict "Floating" (floating d) $ scalarList L.magnitude a
    (20,[a]) -> withDict "Floating" (floating d) $ withDict "Eq" (equality d) $ listUnary L.normalize a
    (21,[a,b]) -> listBinary L.add a b
    (22,[a,b]) -> checkedList L.addChecked a b
    (23,[a,b]) -> checkedList L.subtractChecked a b
    (24,[a,b]) -> do x <- readValue d a;ys <- readElements b;pure(writeList(L.scale x ys))
    (25,[a,b]) -> boundedBinary (\x y -> pure(S.saturatingAdd x y)) a b
    (26,[a,b]) -> boundedBinary (\x y -> pure(S.saturatingSubtract x y)) a b
    (27,[a,b]) -> boundedBinary (\x y -> pure(S.saturatingMultiply x y)) a b
    (28,[a,b]) -> boundedBinary (\x y -> F.source(S.checkedAdd x y)) a b
    (29,[a,b]) -> boundedBinary (\x y -> F.source(S.checkedSubtract x y)) a b
    (30,[a,b]) -> boundedBinary (\x y -> F.source(S.checkedMultiply x y)) a b
    _ -> V.invalid "generic numeric argument shape differs"
  where
    readElements value=V.asList value >>= mapM(readValue d)
    writeList=V.List . map(writeValue d)
    unary f value=writeValue d . f <$> readValue d value
    binary f left right=do x <- readValue d left;y <- readValue d right;pure(writeValue d(f x y))
    scalarList f value=writeValue d . f <$> readElements value
    listUnary f value=writeList . f <$> readElements value
    listBinary f left right=do xs <- readElements left;ys <- readElements right;pure(writeList(f xs ys))
    scalarBinaryList f left right=do xs <- readElements left;ys <- readElements right;pure(writeValue d(f xs ys))
    checkedList f left right=do xs <- readElements left;ys <- readElements right;F.source(f xs ys) >>= pure . writeList
    boundedBinary :: ((Integral a,Bounded a) => a -> a -> IO a) -> V.Value -> V.Value -> IO V.Value
    boundedBinary f left right=withDict "Integral" (integral d) $ withDict "Bounded" (bounded d) $ do
        x <- readValue d left;y <- readValue d right;f x y >>= pure . writeValue d

ordered :: Int -> V.Value -> [V.Value] -> IO V.Value
ordered operation prototype values=do
    let examples=case prototype of V.None -> values;_ -> prototype:values
    SomeOrdered write readOrdered <- orderedWith[F.foundationOrdering] examples
    case(operation,values)of
        (0,[a,b,c]) -> do x <- readOrdered a;y <- readOrdered b;z <- readOrdered c;write(B.clamp x y z)
        (5,[a,b]) -> do x <- readOrdered a;y <- readOrdered b;write(S.minimumScalar x y)
        (6,[a,b]) -> do x <- readOrdered a;y <- readOrdered b;write(S.maximumScalar x y)
        _ -> V.invalid "generic ordered argument shape differs"
foreign export ccall "hm_numeric_objects_apply" apply :: CInt -> StablePtr V.Value -> Ptr(StablePtr V.Value) -> CSize -> Ptr(StablePtr V.Value) -> IO CInt
apply :: CInt -> StablePtr V.Value -> Ptr(StablePtr V.Value) -> CSize -> Ptr(StablePtr V.Value) -> IO CInt
apply operation inputPrototype input arity out=F.foundationBoundary $ do
    prototype <- deRefStablePtr inputPrototype
    values <- peekArray(fromIntegral arity) input >>= mapM deRefStablePtr
    result <- if operation `elem` [31,32]
        then case values of
            [left,right] -> do
                xs <- V.asList left >>= mapM F.readEquality
                ys <- V.asList right >>= mapM F.readEquality
                if operation==31 then V.Index <$> F.source(G.hammingDistance xs ys)
                    else V.Scalar C.SDouble <$> F.source(G.jaccardDistance xs ys)
            _ -> V.invalid "generic equality argument shape differs"
        else if operation `elem` [0,5,6]
        then ordered(fromIntegral operation) prototype values
        else do SomeDomain witness <- domain prototype;numeric witness(fromIntegral operation) values
    V.publish result out
    pure 0
