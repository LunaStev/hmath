{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE UndecidableInstances #-}

-- SPDX-License-Identifier: MPL-2.0
-- | Representation adapters only; all mathematical operations call HMath.Autodiff.
module HMath.FFI.Autodiff where

import Control.Exception (Exception, bracket, bracketOnError, catch, evaluate, throwIO)
import Data.Coerce (coerce)
import Data.Typeable (Typeable, cast)
import Data.Proxy (Proxy (..))
import Data.Kind (Constraint)
import Data.Ratio (numerator, denominator, (%))
import GHC.Float (float2Double)
import Data.Complex (Complex ((:+)), imagPart, realPart)
import Foreign
import Foreign.C
import qualified HMath.Autodiff as A
import qualified HMath.FFI.Coefficient as C
import HMath.Error (MathError (..))
import HMath.FFI.Boundary hiding (boundary)
import qualified HMath.FFI.Boundary as Boundary
import System.IO.Unsafe (unsafePerformIO)

-- Existential towers retain the original Dual instance at every nesting depth.
-- No derivative arithmetic or finite check is implemented in the adapter.
data Dict (constraint :: Constraint) where
    Dict :: constraint => Dict constraint
class (Typeable a, Eq a, Num a) => TowerValue a where
    depth :: a -> Int
    baseKind :: a -> CInt
    components :: a -> Maybe (Tower,Tower)
    fractionalDict :: proxy a -> Maybe (Dict (Fractional a))
    floatingDict :: proxy a -> Maybe (Dict (Floating a))
    orderingDict :: proxy a -> Maybe (Dict (Ord a))
    coefficientLeaf :: a -> Maybe C.SomeCoefficient
    coefficientLeaf _ = Nothing
instance {-# OVERLAPPABLE #-} forall a. (Typeable a, Eq a, Num a, C.Coefficient a) => TowerValue a where
    depth _ = 0
    baseKind _ = fromIntegral (C.scalarTypeCode (C.scalarType :: C.ScalarType a))
    components _ = Nothing
    fractionalDict _ = case C.fractionalDict (Proxy :: Proxy a) of
        Just C.Dict -> Just Dict
        Nothing -> Nothing
    floatingDict _ = case C.floatingDict (Proxy :: Proxy a) of
        Just C.Dict -> Just Dict
        Nothing -> Nothing
    orderingDict _ = case C.orderingDict (Proxy :: Proxy a) of
        Just C.Dict -> Just Dict
        Nothing -> Nothing
    coefficientLeaf value = Just (C.SomeCoefficient C.scalarType value)
instance forall a. (TowerValue a) => TowerValue (A.Dual a) where
    depth value = 1 + depth (A.primal value)
    baseKind value = baseKind (A.primal value)
    components value = Just (Tower (A.primal value),Tower (A.tangent value))
    fractionalDict _ = case fractionalDict (Proxy :: Proxy a) of
        Just Dict -> Just Dict
        Nothing -> Nothing
    floatingDict _ = case floatingDict (Proxy :: Proxy a) of
        Just Dict -> Just Dict
        Nothing -> Nothing
    orderingDict _ = case orderingDict (Proxy :: Proxy a) of
        Just Dict -> Just Dict
        Nothing -> Nothing
data Tower = forall a. (TowerValue a) => Tower a

unaryValue :: forall a. (TowerValue a) => Int -> a -> Either MathError a
unaryValue operation value = case operation of
    0 -> Right (negate value)
    1 -> Right (abs value)
    2 -> Right (signum value)
    3 -> case fractionalDict (Proxy :: Proxy a) of
        Just Dict -> Right (recip value)
        Nothing -> Left (InvalidArgument "Dual scalar type has no Fractional instance")
    _ -> case floatingDict (Proxy :: Proxy a) of
        Just Dict -> Right (unary operation value)
        Nothing -> Left (InvalidArgument "Dual scalar type has no Floating instance")
binaryValue :: forall a. (TowerValue a) => Int -> a -> a -> Either MathError a
binaryValue operation left right = case operation of
    0 -> Right (left+right)
    1 -> Right (left-right)
    2 -> Right (left*right)
    3 -> case fractionalDict (Proxy :: Proxy a) of
        Just Dict -> Right (left/right)
        Nothing -> Left (InvalidArgument "Dual scalar type has no Fractional instance")
    _ -> case floatingDict (Proxy :: Proxy a) of
        Just Dict -> Right (binary operation left right)
        Nothing -> Left (InvalidArgument "Dual scalar type has no Floating instance")
unaryTower :: Int -> Tower -> Either MathError Tower
unaryTower operation (Tower value) = Tower <$> unaryValue operation value
binaryTower :: Int -> Tower -> Tower -> Either MathError Tower
binaryTower operation (Tower left) (Tower right) = case cast right of
    Just other -> Tower <$> binaryValue operation left other
    Nothing -> Left (InvalidArgument "mismatched Dual scalar types")
nestTower :: Tower -> Tower -> Either MathError Tower
nestTower (Tower left) (Tower right) = case cast right of
    Just other -> Right (Tower (A.Dual left other))
    Nothing -> Left (InvalidArgument "mismatched Dual component types")
flatDual :: Tower -> Either MathError (A.Dual Double)
flatDual (Tower value) = maybe (Left (InvalidArgument "expected Dual Double")) Right (cast value)
towerData :: Tower -> [Double]
towerData (Tower value) = case cast value of
    Just number -> [number]
    Nothing -> case cast value of
        Just dual -> [A.primal (dual :: A.Dual Double),A.tangent dual]
        Nothing -> case cast value of
            Just number -> [float2Double number]
            Nothing -> case cast value of
                Just dual -> [float2Double (A.primal (dual :: A.Dual Float)),float2Double (A.tangent dual)]
                Nothing -> []

-- One stable-pointer type prevents accidental casts between differently typed
-- Haskell heaps. The C facade checks the public kind before every operation.
data Value
    = Expression A.Expr
    | Graph A.CompiledGraph
    | Gradients A.GradientState
    | Tensor A.ADTensor
    | Dual Tower

expression :: Value -> Either MathError A.Expr
expression (Expression x) = Right x
expression _ = Left (InvalidArgument "expected AD expression")

gradients :: Value -> Either MathError A.GradientState
gradients (Gradients x) = Right x
gradients _ = Left (InvalidArgument "expected gradient state")

tensor :: Value -> Either MathError A.ADTensor
tensor (Tensor x) = Right x
tensor _ = Left (InvalidArgument "expected AD tensor")

unary :: (Floating a) => Int -> a -> a
unary operation = case operation of
    0 -> negate; 1 -> abs; 2 -> signum; 3 -> recip
    4 -> exp; 5 -> log; 6 -> sqrt; 7 -> sin; 8 -> cos; 9 -> tan
    10 -> asin; 11 -> acos; 12 -> atan; 13 -> sinh; 14 -> cosh
    15 -> tanh; 16 -> asinh; 17 -> acosh; 18 -> atanh
    _ -> error "invalid AD unary operation"

binary :: (Floating a) => Int -> a -> a -> a
binary operation = case operation of
    0 -> (+); 1 -> (-); 2 -> (*); 3 -> (/); 4 -> (**)
    _ -> error "invalid AD binary operation"

foreign export ccall "hm_ad_free" release :: StablePtr Value -> IO ()
release :: StablePtr Value -> IO ()
release = freeStablePtr

foreign export ccall "hm_ad_make"
    make :: CInt -> Ptr (StablePtr Value) -> CSize -> CPtrdiff -> CDouble ->
        Ptr CDouble -> CSize -> Ptr CPtrdiff -> CSize -> Ptr CPtrdiff -> CSize ->
        Ptr (StablePtr Value) -> IO CInt
make :: CInt -> Ptr (StablePtr Value) -> CSize -> CPtrdiff -> CDouble ->
    Ptr CDouble -> CSize -> Ptr CPtrdiff -> CSize -> Ptr CPtrdiff -> CSize ->
    Ptr (StablePtr Value) -> IO CInt
make operation inputs inputCount index scalar xs valueCount dimensions rank axes axisCount out = boundary $ do
    arguments <- peekArray (fromIntegral inputCount) inputs >>= mapM deRefStablePtr
    values <- peekArray (fromIntegral valueCount) (castPtr xs :: Ptr Double)
    shape <- map fromIntegral <$> peekArray (fromIntegral rank) dimensions
    otherAxes <- map fromIntegral <$> peekArray (fromIntegral axisCount) axes
    let i = fromIntegral index
        r = coerce scalar :: Double
        result = case (operation, arguments) of
            (0, []) -> Right (Expression (A.variable i))
            (1, []) -> Right (Expression (A.constant r))
            (2, []) -> case values of
                [a,b] -> Right (Dual (Tower (A.Dual a b)))
                _ -> Left (InvalidArgument "dual pair")
            (3, [Expression e]) -> Right (Expression (if i == 19 then A.detach e else if i == 20 then A.stopGradient e else unary i e))
            (3, [Dual e]) -> Dual <$> unaryTower i e
            (4, [Expression a,Expression b]) -> Right (Expression (binary i a b))
            (4, [Dual a,Dual b]) -> Dual <$> binaryTower i a b
            (5, [Expression e]) -> Graph <$> A.compileGraph i e
            (6, [Expression e]) -> Expression <$> A.differentiate i e
            (7, []) -> Gradients <$> A.zeroGradients i
            (8, [Gradients g]) -> Gradients <$> A.accumulateGradients g values
            (9, [Gradients g]) -> Right (Gradients (A.resetGradients g))
            (10, []) -> Gradients . A.GradientState <$> A.clipGradient r values
            (11, es) -> Tensor <$> (mapM expression es >>= A.adTensor shape)
            (12, [Tensor t]) -> Tensor <$> A.adBroadcast shape t
            (13, [Tensor a,Tensor b]) -> Tensor <$> A.adAdd a b
            (14, [Tensor a,Tensor b]) -> Tensor <$> A.adMultiply a b
            (15, [Tensor a,Tensor b]) -> Tensor <$> A.adMatmul a b
            (16, [Tensor a,Tensor b]) -> Tensor <$> A.adContract shape otherAxes a b
            (17, [Tensor t]) -> Right (Expression (A.adSum t))
            (18, Expression e : es) -> do
                points <- mapM expression es
                next <- A.differentiableStep r (const e) points
                Tensor <$> A.adTensor [length next] next
            (19, [Gradients g]) -> Gradients <$> A.gradientHook (const (Right values)) g
            (20, []) -> Right (Gradients (A.GradientState values))
            (21, [Dual a,Dual b]) -> Dual <$> nestTower a b
            _ -> Left (InvalidArgument "invalid AD representation or operation")
    checked result $ \value ->
        bracketOnError (newStablePtr value) freeStablePtr (poke out)

foreign export ccall "hm_ad_metadata"
    metadata :: StablePtr Value -> Ptr CSize -> Ptr CSize -> IO CInt
metadata :: StablePtr Value -> Ptr CSize -> Ptr CSize -> IO CInt
metadata pointer outCount outRank = boundary $ do
    value <- deRefStablePtr pointer
    let (count,rank) = case value of
            Tensor t -> (length (A.adValues t),length (A.adShape t))
            Gradients g -> (length (A.accumulatedGradient g),0)
            Dual t -> (length (towerData t),0)
            _ -> (0,0)
    strictCount <- evaluate count
    strictRank <- evaluate rank
    poke outCount (fromIntegral strictCount)
    poke outRank (fromIntegral strictRank)
    pure 0

foreign export ccall "hm_ad_data"
    copyData :: StablePtr Value -> Ptr CDouble -> Ptr CPtrdiff -> IO CInt
copyData :: StablePtr Value -> Ptr CDouble -> Ptr CPtrdiff -> IO CInt
copyData pointer outValues outShape = boundary $ do
    value <- deRefStablePtr pointer
    let values = case value of
            Gradients g -> A.accumulatedGradient g
            Dual d -> towerData d
            _ -> []
        shape = case value of { Tensor t -> A.adShape t; _ -> [] }
    strictValues <- mapM evaluate values
    strictShape <- mapM evaluate shape
    pokeArray (castPtr outValues) strictValues
    pokeArray outShape (map fromIntegral strictShape)
    pure 0

foreign export ccall "hm_ad_tensor_values"
    tensorValues :: StablePtr Value -> Ptr (StablePtr Value) -> IO CInt
tensorValues :: StablePtr Value -> Ptr (StablePtr Value) -> IO CInt
tensorValues pointer out = boundary $ do
    value <- deRefStablePtr pointer
    checked (tensor value) $ \t -> allocate (A.adValues t) []
  where
    allocate [] pointers = pokeArray out (reverse pointers)
    allocate (e:es) pointers = bracketOnError (newStablePtr (Expression e)) freeStablePtr $ \p -> allocate es (p:pointers)

foreign export ccall "hm_ad_run"
    run :: CInt -> Ptr (StablePtr Value) -> CSize -> Ptr CDouble -> CSize ->
        Ptr CDouble -> CSize -> CDouble -> Ptr CDouble -> IO CInt
run :: CInt -> Ptr (StablePtr Value) -> CSize -> Ptr CDouble -> CSize ->
    Ptr CDouble -> CSize -> CDouble -> Ptr CDouble -> IO CInt
run operation pointers count xs n ds directionCount scalar out = boundary $ do
    arguments <- peekArray (fromIntegral count) pointers >>= mapM deRefStablePtr
    values <- peekArray (fromIntegral n) (castPtr xs :: Ptr Double)
    directions <- peekArray (fromIntegral directionCount) (castPtr ds :: Ptr Double)
    let result = case (operation,arguments) of
            (0,[Graph g]) -> (:[]) <$> A.evaluateGraph g values
            (1,[Expression e]) -> (\(y,g) -> y:g) <$> A.valueAndGradient (const e) values
            (2,[Expression e]) -> A.gradient (const e) values
            (3,[Expression e]) -> concat <$> A.hessian (const e) values
            (4,es) -> concat <$> (mapM expression es >>= \outputs -> A.jacobian (const outputs) values)
            (5,es) -> mapM expression es >>= \outputs -> A.jvp (const outputs) values directions
            (6,es) -> mapM expression es >>= \outputs -> A.vjp (const outputs) values directions
            (7,[Expression e]) -> A.hvp (const e) values directions
            (8,[Expression e]) -> (:[]) <$> A.gradientCheck (coerce scalar) (const e) values
            (9,[Expression e]) -> case values of
                [a,b] -> (\z -> [realPart z,imagPart z]) <$> A.complexGradient (const e) (a :+ b)
                _ -> Left (InvalidArgument "complex coordinate pair")
            (10,outputs) -> do
                duals <- mapM (\v -> case v of { Dual d -> flatDual d; _ -> Left (InvalidArgument "expected dual output") }) outputs
                (primals,tangents) <- A.forwardJVP (const duals) values directions
                Right (primals ++ tangents)
            _ -> Left (InvalidArgument "invalid AD evaluation operation")
    checked result $ \resultValues -> do
        strict <- mapM evaluate resultValues
        pokeArray (castPtr out) strict


-- Callbacks return a status and borrowed error text. Relaying this exception at
-- the C boundary has the same short-circuit effect as Left MathError, preserving
-- the original constructor/payload without parsing or rewriting its Show form.
data CallbackFailure = CallbackFailure CInt String deriving (Show)
instance Exception CallbackFailure
foreign import ccall unsafe "hm_error" setCallbackError :: CInt -> CString -> IO CInt
boundary :: IO CInt -> IO CInt
boundary action = Boundary.boundary (action `catch` relay)
  where
    relay (CallbackFailure code message) = withCString message (setCallbackError code)

type RuleCallback = Ptr CDouble -> CSize -> Ptr () -> Ptr CDouble -> Ptr CDouble -> CSize -> Ptr CSize -> Ptr CString -> IO CInt
type UnaryCallback = CDouble -> Ptr () -> Ptr CDouble -> Ptr CString -> IO CInt
foreign import ccall safe "dynamic" callRule :: FunPtr RuleCallback -> RuleCallback
foreign import ccall safe "dynamic" callUnary :: FunPtr UnaryCallback -> UnaryCallback
foreign import ccall safe "hm_ad_invoke_builder"
    callBuilder :: FunPtr () -> Ptr () -> Ptr (StablePtr Value) -> CSize -> Ptr (StablePtr Value) -> Ptr CString -> IO CInt

callbackStatus :: CInt -> Ptr CString -> IO ()
callbackStatus status messagePointer
    | status == 0 = pure ()
    | otherwise = do
        pointer <- peek messagePointer
        message <- if pointer == nullPtr then pure "AD callback failed" else peekCString pointer
        throwIO (CallbackFailure (if status > 0 && status <= 11 then status else 1) message)

{-# NOINLINE customRule #-}
customRule :: FunPtr RuleCallback -> Ptr () -> [Double] -> Either MathError (Double,[Double])
customRule callback userdata values = unsafePerformIO $
    withArray (map coerce values :: [CDouble]) $ \inputs ->
    alloca $ \outValue -> allocaArray (max 1 (length values)) $ \partials ->
    alloca $ \outCount -> alloca $ \outError -> do
        poke outError nullPtr
        poke outCount (fromIntegral (length values))
        poke outValue (0/0)
        status <- callRule callback inputs (fromIntegral (length values)) userdata outValue partials (fromIntegral (length values)) outCount outError
        callbackStatus status outError
        n <- peek outCount
        if toInteger n > toInteger (maxBound :: Int)
            then throwIO (CallbackFailure 3 "custom derivative count exceeds Haskell Int")
            else do
                value <- coerce <$> peek outValue
                -- Preserve value-only evaluation even when derivative arity is
                -- wrong: runValue ignores partials, runTape checks their length.
                derivatives <- if fromIntegral n == length values
                    then map coerce <$> peekArray (fromIntegral n) partials
                    else pure (replicate (fromIntegral n) 0)
                pure (Right (value,derivatives))

{-# NOINLINE customScalar #-}
customScalar :: FunPtr UnaryCallback -> Ptr () -> Double -> Double
customScalar callback userdata value = unsafePerformIO $
    alloca $ \out -> alloca $ \outError -> do
        poke outError nullPtr
        poke out (0/0)
        status <- callUnary callback (coerce value) userdata out outError
        callbackStatus status outError
        coerce <$> peek out

{-# NOINLINE checkpointRecipe #-}
checkpointRecipe :: FunPtr () -> Ptr () -> [A.Expr] -> A.Expr
checkpointRecipe callback userdata values = unsafePerformIO $ temporary values []
  where
    temporary [] pointers = withArray (reverse pointers) $ \inputs ->
        alloca $ \out -> alloca $ \outError -> do
            poke outError nullPtr
            status <- callBuilder callback userdata inputs (fromIntegral (length values)) out outError
            callbackStatus status outError
            pointer <- peek out
            bracket (pure pointer) freeStablePtr $ \stable -> do
                result <- deRefStablePtr stable
                either (throwIO . CallbackFailure 1 . show) pure (expression result)
    temporary (e:es) pointers = bracket (newStablePtr (Expression e)) freeStablePtr $ \pointer -> temporary es (pointer:pointers)

foreign export ccall "hm_ad_clone"
    clone :: StablePtr Value -> Ptr (StablePtr Value) -> IO CInt
clone :: StablePtr Value -> Ptr (StablePtr Value) -> IO CInt
clone pointer out = boundary $ do
    value <- deRefStablePtr pointer
    bracketOnError (newStablePtr value) freeStablePtr (poke out)
    pure 0

foreign export ccall "hm_ad_callbacks"
    callbacks :: CInt -> Ptr (StablePtr Value) -> CSize -> FunPtr RuleCallback -> FunPtr UnaryCallback -> FunPtr UnaryCallback -> FunPtr () -> Ptr () -> Ptr (StablePtr Value) -> IO CInt
callbacks :: CInt -> Ptr (StablePtr Value) -> CSize -> FunPtr RuleCallback -> FunPtr UnaryCallback -> FunPtr UnaryCallback -> FunPtr () -> Ptr () -> Ptr (StablePtr Value) -> IO CInt
callbacks operation pointers count rule valueCallback derivativeCallback builder userdata out = boundary $ do
    values <- peekArray (fromIntegral count) pointers >>= mapM deRefStablePtr
    checked (mapM expression values) $ \expressions -> do
        let result = case operation of
                0 -> A.customOperation (customRule rule userdata) expressions
                1 -> case expressions of
                    [e] -> A.customUnary (customScalar valueCallback userdata) (customScalar derivativeCallback userdata) e
                    _ -> error "invalid custom unary arity"
                2 -> A.checkpoint (checkpointRecipe builder userdata) expressions
                _ -> error "invalid AD callback operation"
        bracketOnError (newStablePtr (Expression result)) freeStablePtr (poke out)


foreign export ccall "hm_ad_dual_depth"
    dualDepth :: StablePtr Value -> Ptr CSize -> IO CInt
dualDepth :: StablePtr Value -> Ptr CSize -> IO CInt
dualDepth pointer out = boundary $ do
    value <- deRefStablePtr pointer
    checked (case value of { Dual (Tower number) -> Right (depth number); _ -> Left (InvalidArgument "expected Dual") }) $ \n -> poke out (fromIntegral n)

foreign export ccall "hm_ad_dual_parts"
    dualParts :: StablePtr Value -> Ptr (StablePtr Value) -> Ptr (StablePtr Value) -> IO CInt
dualParts :: StablePtr Value -> Ptr (StablePtr Value) -> Ptr (StablePtr Value) -> IO CInt
dualParts pointer outPrimal outTangent = boundary $ do
    value <- deRefStablePtr pointer
    let result = case value of
            Dual (Tower number) -> maybe (Left (InvalidArgument "scalar has no Dual components")) Right (components number)
            _ -> Left (InvalidArgument "expected Dual")
    checked result $ \(primalPart,tangentPart) ->
        bracketOnError (newStablePtr (Dual primalPart)) freeStablePtr $ \primalPointer ->
        bracketOnError (newStablePtr (Dual tangentPart)) freeStablePtr $ \tangentPointer -> do
            poke outPrimal primalPointer
            poke outTangent tangentPointer


foreign export ccall "hm_ad_dual_f32"
    dualFloat :: CFloat -> CFloat -> Ptr (StablePtr Value) -> IO CInt
dualFloat :: CFloat -> CFloat -> Ptr (StablePtr Value) -> IO CInt
dualFloat primalValue tangentValue out = boundary $
    bracketOnError (newStablePtr (Dual (Tower (A.Dual (coerce primalValue :: Float) (coerce tangentValue))))) freeStablePtr $ \pointer -> poke out pointer >> pure 0

foreign export ccall "hm_ad_dual_exact"
    dualExact :: CInt -> CString -> CString -> CString -> CString -> Ptr (StablePtr Value) -> IO CInt
dualExact :: CInt -> CString -> CString -> CString -> CString -> Ptr (StablePtr Value) -> IO CInt
dualExact kind primalNumerator primalDenominator tangentNumerator tangentDenominator out = boundary $ do
    primalValue <- readInteger primalNumerator
    tangentValue <- readInteger tangentNumerator
    value <- if kind == 2
        then pure (Dual (Tower (A.Dual primalValue tangentValue)))
        else do
            primalDivisor <- readInteger primalDenominator
            tangentDivisor <- readInteger tangentDenominator
            pure (Dual (Tower (A.Dual (primalValue % primalDivisor) (tangentValue % tangentDivisor))))
    bracketOnError (newStablePtr value) freeStablePtr $ \pointer -> poke out pointer >> pure 0

foreign export ccall "hm_ad_dual_kind"
    dualKind :: StablePtr Value -> Ptr CInt -> IO CInt
dualKind :: StablePtr Value -> Ptr CInt -> IO CInt
dualKind pointer out = boundary $ do
    value <- deRefStablePtr pointer
    checked (case value of { Dual (Tower number) -> Right (baseKind number); _ -> Left (InvalidArgument "expected Dual") }) (poke out)

foreign export ccall "hm_ad_scalar_text"
    scalarText :: StablePtr Value -> Ptr CString -> Ptr CString -> IO CInt
scalarText :: StablePtr Value -> Ptr CString -> Ptr CString -> IO CInt
scalarText pointer outNumerator outDenominator = boundary $ do
    value <- deRefStablePtr pointer
    let result = case value of
            Dual (Tower number) -> case cast number of
                Just integer -> Right (show (integer :: Integer),"1")
                Nothing -> case cast number of
                    Just rational -> Right (show (numerator (rational :: Rational)),show (denominator rational))
                    Nothing -> Left (InvalidArgument "expected Integer or Rational scalar leaf")
            _ -> Left (InvalidArgument "expected exact scalar leaf")
    checked result $ \(n,d) -> writeStrings [n,d] $ \texts -> do
        poke outNumerator (texts !! 0)
        poke outDenominator (texts !! 1)


relationValue :: forall a. (TowerValue a) => Int -> a -> a -> Either MathError Bool
relationValue operation left right
    | operation == 0 = Right (left == right)
    | otherwise = case orderingDict (Proxy :: Proxy a) of
        Nothing -> Left (InvalidArgument "Dual scalar type has no Ord instance")
        Just Dict -> Right (case operation of { 1 -> left < right; 2 -> left <= right; 3 -> left > right; _ -> left >= right })
relationTower :: Int -> Tower -> Tower -> Either MathError Bool
relationTower operation (Tower left) (Tower right) = case cast right of
    Nothing -> Left (InvalidArgument "mismatched Dual scalar types")
    Just other -> relationValue operation left other
foreign export ccall "hm_ad_dual_relation"
    dualRelation :: CInt -> StablePtr Value -> StablePtr Value -> Ptr CInt -> IO CInt
dualRelation :: CInt -> StablePtr Value -> StablePtr Value -> Ptr CInt -> IO CInt
dualRelation operation leftPointer rightPointer out = boundary $ do
    left <- deRefStablePtr leftPointer
    right <- deRefStablePtr rightPointer
    let result = case (left,right) of
            (Dual a,Dual b) -> relationTower (fromIntegral operation) a b
            _ -> Left (InvalidArgument "expected Dual operands")
    checked result $ \value -> poke out (if value then 1 else 0)
