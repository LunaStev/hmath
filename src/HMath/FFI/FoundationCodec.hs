{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Foreign representation, original dictionaries and persistent owners only.
module HMath.FFI.FoundationCodec where
import Control.Exception (catch,evaluate,throw,throwIO)
import Data.Dynamic (Dynamic,toDyn,fromDynamic)
import Data.Typeable (Typeable,cast,typeRep)
import Data.Proxy (Proxy(..))
import Foreign.C (CInt)
import System.IO.Unsafe (unsafePerformIO)
import qualified HMath.DataStructure as D
import qualified HMath.Discrete as S
import qualified HMath.API.Algebra as AlgebraAPI
import qualified HMath.API.Shape as ShapeAPI
import HMath.Matrix (Matrix)
import qualified HMath.Error as E
import qualified HMath.FFI.Autodiff as AD
import qualified HMath.FFI.AutodiffValue as ADValue
import qualified HMath.FFI.NumericTypes.Core as NumericCore
import qualified HMath.FFI.Polynomial as Polynomial
import qualified HMath.FFI.TensorCodec as Tensor
import qualified HMath.FFI.Value as X
import qualified HMath.FFI.LinearCodec as LC
import qualified HMath.FFI.Boundary as Boundary
import HMath.FFI.Coefficient
import HMath.FFI.MathError
import HMath.FFI.Ordering

data Envelope=Envelope String Dynamic (IO X.Value) (Maybe(Dynamic -> IO Bool))
opaque :: Typeable a => String -> Int -> a -> IO () -> IO X.Value -> X.Value
opaque name dtype value force view=X.Opaque 400 dtype 0 force(Envelope name(toDyn value)view Nothing)
opaqueEq :: (Typeable a,Eq a) => String -> Int -> a -> IO () -> IO X.Value -> X.Value
opaqueEq name dtype value force view=X.Opaque 400 dtype 0 force(Envelope name(toDyn value)view(Just compareValue))
  where
    compareValue other=maybe(X.invalid "equality source types differ")(pure . (value==))(fromDynamic other)

unbox :: forall a. Typeable a => String -> X.Value -> IO a
unbox name(X.Opaque 400 _ _ _ payload)=case cast payload of
    Just(Envelope actual value _ _) | name==actual -> maybe(X.invalid "foundation object type differs") pure(fromDynamic value)
    _ -> X.invalid "foundation object subtype differs"
unbox _ _=X.invalid "expected foundation object"
objectName :: X.Value -> IO String
objectName(X.Opaque 400 _ _ _ payload)=case cast payload of
    Just(Envelope name _ _ _) -> pure name
    _ -> X.invalid "invalid foundation envelope"
objectName _=X.invalid "expected foundation object"
objectParts :: X.Value -> IO X.Value
objectParts(X.Opaque 400 _ _ _ payload)=case cast payload of
    Just(Envelope _ _ view _) -> view
    _ -> X.invalid "invalid foundation envelope"
objectParts _=X.invalid "expected foundation object"
source :: Either E.MathError a -> IO a
source=either(throwIO . CallbackMathError)pure
foundationBoundary :: IO CInt -> IO CInt
foundationBoundary action=Boundary.boundary $ callbackBoundary (\e -> Boundary.checked(Left e)(const(pure()))) action
forceFields :: [IO X.Value] -> IO ()
forceFields actions=sequence actions >>= mapM_ X.forceValue

-- Only a successful Just containing None needs an explicit wrapper. Ordinary
-- optional non-None values retain the common language representation.
data Present=Present X.Value
maybeValue :: Maybe X.Value -> IO X.Value
maybeValue Nothing=pure X.None
maybeValue(Just value)=case value of
    X.None -> pure(opaque "HMath.Internal.Just" (-1) (Present value) (X.forceValue value) (pure(X.Tuple[X.Text "Just",value])))
    _ -> pure value
asMaybeValue :: X.Value -> IO(Maybe X.Value)
asMaybeValue X.None=pure Nothing
asMaybeValue value@(X.Opaque 400 _ _ _ _)=do
    name <- objectName value
    if name=="HMath.Internal.Just" then do Present x <- unbox name value;pure(Just x) else pure(Just value)
asMaybeValue value=pure(Just value)
newtype Choice=Choice(Either X.Value X.Value)
eitherValue :: Either X.Value X.Value -> IO X.Value
eitherValue result=pure(opaque "HMath.Internal.Either" (-1)(Choice result) force view)
  where
    force=either X.forceValue X.forceValue result
    view=pure(case result of Left e -> X.Tuple[X.Text "Left",e];Right x -> X.Tuple[X.Text "Right",x])
asEitherValue :: X.Value -> IO(Either X.Value X.Value)
asEitherValue value=do Choice result <- unbox "HMath.Internal.Either" value;pure result

-- These wrappers delegate to the actual original Ord/Eq dictionaries. No
-- alternate numeric ordering, hashing or sorting algorithm is implemented.
data OrderedValue where
    OrderedValue :: (Typeable a,Ord a) => (a -> IO X.Value) -> a -> OrderedValue
instance Eq OrderedValue where
    OrderedValue _ a == OrderedValue _ b=case cast b of Just y -> a==y;Nothing -> throw(CallbackFailure 1 "incompatible foreign ordered types")
instance Ord OrderedValue where
    compare(OrderedValue _ a)(OrderedValue _ b)=case cast b of Just y -> compare a y;Nothing -> throw(CallbackFailure 1 "incompatible foreign ordered types")
writeOrdered :: OrderedValue -> IO X.Value
writeOrdered(OrderedValue write value)=write value
readOrdered :: SomeOrdered -> X.Value -> IO OrderedValue
readOrdered(SomeOrdered write readValue) value=OrderedValue write <$> readValue value
sameDomain :: SomeOrdered -> SomeOrdered -> Bool
sameDomain(SomeOrdered(_::a->IO X.Value)_)(SomeOrdered(_::b->IO X.Value)_)=typeRep(Proxy::Proxy a)==typeRep(Proxy::Proxy b)
chooseDomain :: Maybe SomeOrdered -> [X.Value] -> IO SomeOrdered
chooseDomain(Just domain) _=pure domain
chooseDomain Nothing examples=orderedWith [foundationOrdering] examples
mergeDomain :: Maybe SomeOrdered -> Maybe SomeOrdered -> IO(Maybe SomeOrdered)
mergeDomain Nothing b=pure b
mergeDomain a Nothing=pure a
mergeDomain a@(Just left)(Just right)
    | sameDomain left right=pure a
    | otherwise=X.invalid "ordered container element types differ"

data HeapState=HeapState (Maybe SomeOrdered) (D.Heap OrderedValue)
instance Eq HeapState where
    HeapState a x == HeapState b y=case(a,b) of
        (Just left,Just right) | not(sameDomain left right) -> throw(CallbackFailure 1 "heap element types differ")
        _ -> x==y
heapEmpty :: HeapState
heapEmpty=HeapState Nothing D.emptyHeap
heapFromList :: [X.Value] -> IO HeapState
heapFromList []=pure heapEmpty
heapFromList values=do domain <- chooseDomain Nothing values;xs <- mapM(readOrdered domain) values;pure(HeapState(Just domain)(D.heapFromList xs))
heapFromListTyped :: X.Value -> [X.Value] -> IO HeapState
heapFromListTyped prototype values=do domain <- orderedWith [foundationOrdering][prototype];xs <- mapM(readOrdered domain)values;pure(HeapState(Just domain)(D.heapFromList xs))
heapInsert :: X.Value -> HeapState -> IO HeapState
heapInsert value(HeapState existing heap)=do
    domain <- chooseDomain existing [value];x <- readOrdered domain value
    pure(HeapState(Just domain)(D.heapInsert x heap))
heapPop :: HeapState -> IO(Maybe(X.Value,HeapState))
heapPop(HeapState domain heap)=case D.heapPop heap of
    Nothing -> pure Nothing
    Just(value,next) -> do x <- writeOrdered value;pure(Just(x,HeapState domain next))

data MultiState=MultiState (Maybe SomeOrdered) (S.MultiSet OrderedValue)
instance Eq MultiState where
    MultiState a x == MultiState b y=case(a,b) of
        (Just left,Just right) | not(sameDomain left right) -> throw(CallbackFailure 1 "multiset element types differ")
        _ -> x==y
multiset :: [X.Value] -> IO MultiState
multiset []=pure(MultiState Nothing(S.multiset []))
multiset values=do domain <- chooseDomain Nothing values;xs <- mapM(readOrdered domain) values;pure(MultiState(Just domain)(S.multiset xs))
multisetTyped :: X.Value -> [X.Value] -> IO MultiState
multisetTyped prototype values=do domain <- orderedWith [foundationOrdering][prototype];xs <- mapM(readOrdered domain)values;pure(MultiState(Just domain)(S.multiset xs))
multiplicity :: X.Value -> MultiState -> IO Integer
multiplicity value(MultiState domain set)=do witness <- chooseDomain domain [value];x <- readOrdered witness value;pure(S.multiplicity x set)
multisetEntries :: MultiState -> IO[(X.Value,Integer)]
multisetEntries(MultiState _ set)=mapM(\(x,n) -> do v <- writeOrdered x;pure(v,n))(S.multisetEntries set)
multisetInsert :: X.Value -> MultiState -> IO MultiState
multisetInsert value(MultiState existing set)=do
    domain <- chooseDomain existing [value];x <- readOrdered domain value
    pure(MultiState(Just domain)(S.multisetInsert x set))
multisetDelete :: X.Value -> MultiState -> IO MultiState
multisetDelete value(MultiState existing set)=do
    domain <- chooseDomain existing [value];x <- readOrdered domain value
    pure(MultiState(Just domain)(S.multisetDelete x set))
multisetBinary :: (S.MultiSet OrderedValue -> S.MultiSet OrderedValue -> S.MultiSet OrderedValue) -> MultiState -> MultiState -> IO MultiState
multisetBinary operation(MultiState a left)(MultiState b right)=do domain <- mergeDomain a b;pure(MultiState domain(operation left right))

foundationOrdering :: Resolver
foundationOrdering value=case value of
    X.Opaque 400 _ _ _ _ -> do
        name <- objectName value
        case name of
            "HMath.Internal.OrderedType" -> do OrderedType domain <- unbox name value;pure(Just domain)
            "HMath.API.Shape.Shape" -> pure(Just(SomeOrdered (\x -> pure(opaqueEq name (-1)(x::ShapeAPI.Shape)(evaluate(ShapeAPI.shapeElements x)>>pure())(X.unsupported "original Shape is abstract")))(unbox name)))
            "HMath.API.Algebra.Exact" -> pure(Just(SomeOrdered (\x -> pure(opaqueEq name 18 (x::AlgebraAPI.Exact)(evaluate(AlgebraAPI.getExact x)>>pure())(pure(X.Tuple[X.Text "Exact",X.Tuple[X.Scalar SRational(AlgebraAPI.getExact x)]]))))(unbox name)))
            "HMath.Discrete.Implicant" -> pure(Just(SomeOrdered (\x -> pure(opaque name (-1)(x::S.Implicant)(evaluate x>>pure())(pure(X.Tuple[X.Text "Implicant",X.Tuple[X.Scalar SInteger(S.implicantValue x),X.Scalar SInteger(S.implicantMask x)]]))))(unbox name)))
            _ -> pure Nothing
    _ -> pure Nothing

newtype OrderedType=OrderedType SomeOrdered
orderedType :: X.Value -> IO X.Value
orderedType prototype=do domain <- orderedWith [foundationOrdering][prototype];pure(boxOrderedType domain)
optionalType :: X.Value -> IO X.Value
optionalType prototype=do
    SomeOrdered write readValue <- orderedWith [foundationOrdering][prototype]
    let writeMaybe Nothing=pure X.None
        writeMaybe(Just x)=write x >>= maybeValue . Just
        readMaybe value=asMaybeValue value >>= traverse readValue
    pure(boxOrderedType(SomeOrdered writeMaybe readMaybe))
boxOrderedType :: SomeOrdered -> X.Value
boxOrderedType domain=opaque "HMath.Internal.OrderedType" (-1)(OrderedType domain)(pure())(X.unsupported "an original Ord dictionary prototype has no value fields")

checkedCallback :: X.Value -> X.Value -> (X.Value -> IO a) -> IO(Either E.MathError a)
checkedCallback function argument decodeResult=(LC.callbackValue function argument >>= decodeResult >>= pure . Right) `catch` relay
  where
    relay(CallbackMathError e)=pure(Left e)
    relay other=throwIO(other::CallbackFailure)

newtype EqualityValue=EqualityValue X.Value
instance Eq EqualityValue where
    EqualityValue a == EqualityValue b=unsafePerformIO(eqValue a b)
writeEquality :: EqualityValue -> IO X.Value
writeEquality(EqualityValue value)=pure value
readEquality :: X.Value -> IO EqualityValue
readEquality=pure . EqualityValue
eqValue :: X.Value -> X.Value -> IO Bool
eqValue (X.Scalar (_::ScalarType a) a)(X.Scalar _ b)=
    maybe(X.invalid "equality coefficient types differ")(pure . (a==))(cast b)
eqValue (X.Index a)(X.Index b)=pure(a==b)
eqValue (X.Boolean a)(X.Boolean b)=pure(a==b)
eqValue (X.Text a)(X.Text b)=pure(a==b)
eqValue X.None X.None=pure True
eqValue (X.List a)(X.List b)=pure(map EqualityValue a==map EqualityValue b)
eqValue (X.Tuple a)(X.Tuple b)
    | length a==length b=pure(map EqualityValue a==map EqualityValue b)
    | otherwise=X.invalid "equality tuple types differ"
-- Recover the original Eq dictionaries of standard mathematical owners.
-- Equality is performed by each source instance, including tensor views and NaN.
eqValue (X.Dense(X.SomeMatrix _ left)) right = (left==) <$> X.asMatrix right
eqValue left@(X.Dense(X.StructuralMatrix code _ _ _ _)) right = case code of
    16 -> do a <- X.asMatrix left :: IO(Matrix Bool); b <- X.asMatrix right; pure(a==b)
    17 -> do a <- X.asMatrix left :: IO(Matrix String); b <- X.asMatrix right; pure(a==b)
    18 -> do a <- X.asMatrix left :: IO(Matrix AlgebraAPI.Exact); b <- X.asMatrix right; pure(a==b)
    _ -> X.unsupported "structural Matrix has no exposed original Eq dictionary"
eqValue (X.Opaque 6 _ _ _ payload) right = case cast payload of
    Just(Polynomial.SomePolynomial _ left) -> (left==) <$> Polynomial.asPolynomial right
    Nothing -> X.invalid "invalid Polynomial equality payload"
eqValue (X.Opaque 7 _ _ _ payload) right = case cast payload of
    Just(Polynomial.SomeSeries _ left) -> (left==) <$> Polynomial.asSeries right
    Nothing -> X.invalid "invalid PowerSeries equality payload"
eqValue left@(X.Opaque 8 _ _ _ _) right = (==) <$> Polynomial.asRationalFunction left <*> Polynomial.asRationalFunction right
eqValue left@(X.Opaque kind _ _ _ _) right | kind>=40 && kind<=53 =
    NumericCore.equalValueWith eqValue left right
eqValue left@(X.Opaque 289 _ _ _ _) right = do
    AD.Tower a <- ADValue.asADTower left
    AD.Tower b <- ADValue.asADTower right
    maybe(X.invalid "original AD equality component types differ")(pure . (a==))(cast b)
eqValue left@(X.Opaque kind _ _ _ _) right | kind==161 || kind==270 = do
    Tensor.SomeTensor _ original <- Tensor.asTensor left
    (original==) <$> Tensor.asTensorType right
eqValue a@(X.Opaque 400 _ _ _ left) b@(X.Opaque 400 _ _ _ right)=case(cast left,cast right) of
    (Just(Envelope name _ _ (Just compareValue)),Just(Envelope other payload _ _))
        | name==other -> compareValue payload
    _ -> do
        SomeOrdered _ readValue <- orderedWith [foundationOrdering] [a,b]
        (==) <$> readValue a <*> readValue b
eqValue a b=do
    SomeOrdered _ readValue <- orderedWith [foundationOrdering] [a,b]
    (==) <$> readValue a <*> readValue b

orderedValues :: [X.Value] -> IO[OrderedValue]
orderedValues []=pure[]
orderedValues values=do domain <- orderedWith [foundationOrdering] values;mapM(readOrdered domain) values
