{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Lossless language adapters; every mathematical transformation calls source APIs.
module HMath.FFI.Expression where
import Control.Exception (Exception, catch, evaluate, throwIO)
import Data.Complex (Complex)
import Data.List (elemIndex)
import qualified Data.Map.Strict as Map
import Data.Typeable (Typeable, cast)
import Foreign
import Foreign.C
import qualified HMath.Expression as E
import qualified HMath.Symbolic as S
import qualified HMath.Polynomial as P
import qualified HMath.FFI.Polynomial as Poly
import HMath.FFI.Coefficient (ScalarType (SDouble,SRational,SWord64,SComplexDouble))
import qualified HMath.FFI.Boundary as B
import HMath.FFI.MathError (withEncodedMessage)
import HMath.FFI.Value (Value(..), asIndex, asList, asTuple, asText, asBoolean, asScalar, invalid, publish)

class FromValue a where fromValue :: Value -> IO a
class ToValue a where toValue :: a -> IO Value
instance FromValue Value where fromValue = pure
instance ToValue Value where toValue = pure
instance FromValue Double where fromValue = asScalar
instance ToValue Double where toValue = pure . Scalar SDouble
instance FromValue Rational where fromValue = asScalar
instance ToValue Rational where toValue = pure . Scalar SRational
instance ToValue (Complex Double) where toValue = pure . Scalar SComplexDouble
instance FromValue Int where fromValue = asIndex
instance ToValue Int where toValue = pure . Index
instance ToValue Word64 where toValue = pure . Scalar SWord64
instance FromValue Bool where fromValue = asBoolean
instance ToValue Bool where toValue = pure . Boolean
instance {-# OVERLAPPING #-} FromValue String where fromValue = asText
instance {-# OVERLAPPING #-} ToValue String where toValue = pure . Text
instance {-# OVERLAPPABLE #-} FromValue a => FromValue [a] where fromValue v = asList v >>= mapM fromValue
instance {-# OVERLAPPABLE #-} ToValue a => ToValue [a] where toValue xs = List <$> mapM toValue xs
instance FromValue a => FromValue (Maybe a) where fromValue None = pure Nothing; fromValue x = Just <$> fromValue x
instance ToValue a => ToValue (Maybe a) where toValue = maybe (pure None) toValue
instance ToValue () where toValue () = pure None
instance ToValue a => ToValue (Either E.ExprError a) where
    toValue (Left err) = throwIO (ExpressionFailure err)
    toValue (Right x) = toValue x
instance (FromValue a,FromValue b) => FromValue (a,b) where
    fromValue v = do [a,b]<-asTuple 2 v; (,) <$> fromValue a <*> fromValue b
instance (ToValue a,ToValue b) => ToValue (a,b) where toValue (a,b) = Tuple <$> sequence [toValue a,toValue b]
instance (FromValue a,FromValue b,FromValue c) => FromValue (a,b,c) where
    fromValue v = do [a,b,c]<-asTuple 3 v; (,,) <$> fromValue a <*> fromValue b <*> fromValue c
instance (ToValue a,ToValue b,ToValue c) => ToValue (a,b,c) where toValue (a,b,c) = Tuple <$> sequence [toValue a,toValue b,toValue c]

unbox :: forall a. Typeable a => Int -> Value -> IO a
unbox kind (Opaque actual _ _ _ value) | actual==kind = maybe (invalid "expression object type differs") pure (cast value)
unbox _ _ = invalid "expression object kind differs"
boxed :: Typeable a => Int -> a -> Value
boxed kind value = Opaque kind (-1) 0 (evaluate value >> pure ()) value
fromEnumValue :: [a] -> Value -> IO a
fromEnumValue values value = do n<-asIndex value; if n<0 || n>=length values then invalid "expression enum representation is invalid" else pure (values!!n)
toEnumValue :: Eq a => [a] -> a -> IO Value
toEnumValue values value = maybe (invalid "unknown expression enum") (pure . Index) (elemIndex value values)

instance FromValue E.SourcePos where
    fromValue value = do [a,b,c]<-asTuple 3 value; E.SourcePos <$> fromValue a <*> fromValue b <*> fromValue c
instance ToValue E.SourcePos where toValue (E.SourcePos a b c) = toValue (a,b,c)
instance FromValue E.Limits where
    fromValue value = do [a,b,c,d,e,f]<-asTuple 6 value; E.Limits <$> fromValue a <*> fromValue b <*> fromValue c <*> fromValue d <*> fromValue e <*> fromValue f
instance ToValue E.Limits where toValue value = Tuple <$> mapM toValue [E.maximumSteps value,E.maximumDepth value,E.maximumNodes value,E.maximumInputChars value,E.maximumIntegerBits value,E.maximumCacheEntries value]
instance FromValue E.ExprError where
    fromValue value = do [a,b,c]<-asTuple 3 value; E.ExprError <$> fromValue a <*> fromValue b <*> fromValue c
instance ToValue E.ExprError where toValue (E.ExprError a b c) = toValue (a,b,c)
instance FromValue E.Value where
    fromValue value = do
        [tag,payload]<-asTuple 2 value
        kind<-asIndex tag
        case kind of { 0 -> E.ExactValue <$> fromValue payload; 1 -> E.FloatValue <$> fromValue payload; _ -> invalid "invalid expression Value constructor" }
instance ToValue E.Value where
    toValue (E.ExactValue q) = Tuple <$> sequence [pure (Index 0),toValue q]
    toValue (E.FloatValue x) = Tuple <$> sequence [pure (Index 1),toValue x]
instance FromValue E.Bindings where fromValue value = Map.fromList <$> fromValue value
instance ToValue E.Bindings where toValue = toValue . Map.toAscList
instance FromValue S.SymbolicOptions where
    fromValue value = do [a,b]<-asTuple 2 value; S.SymbolicOptions <$> fromValue a <*> fromValue b
instance ToValue S.SymbolicOptions where toValue (S.SymbolicOptions a b) = toValue (a,b)
instance FromValue S.PolynomialFactorization where
    fromValue value = do [a,b]<-asTuple 2 value; S.PolynomialFactorization <$> fromValue a <*> fromValue b
instance ToValue S.PolynomialFactorization where toValue (S.PolynomialFactorization a b) = toValue (a,b)
instance FromValue S.RewriteRule where
    fromValue value = do [a,b,c]<-asTuple 3 value; S.RewriteRule <$> fromValue a <*> fromValue b <*> fromValue c
instance ToValue S.RewriteRule where toValue (S.RewriteRule a b c) = toValue (a,b,c)
instance FromValue S.Series where
    fromValue value = do [a,b,c]<-asTuple 3 value; S.Series <$> fromValue a <*> fromValue b <*> fromValue c
instance ToValue S.Series where toValue (S.Series a b c) = toValue (a,b,c)
instance FromValue S.Relation where
    fromValue value = do [a,b,c]<-asTuple 3 value; S.Relation <$> fromValue a <*> fromValue b <*> fromValue c
instance ToValue S.Relation where toValue (S.Relation a b c) = toValue (a,b,c)
instance FromValue S.RelationResult where
    fromValue value = do
        [tag,payload]<-asTuple 2 value; kind<-asIndex tag
        case kind of {0 -> S.Truth <$> fromValue payload; 1 -> S.Unresolved <$> fromValue payload; _ -> invalid "invalid RelationResult constructor"}
instance ToValue S.RelationResult where
    toValue (S.Truth x) = Tuple <$> sequence [pure (Index 0),toValue x]
    toValue (S.Unresolved x) = Tuple <$> sequence [pure (Index 1),toValue x]
instance FromValue S.LimitResult where
    fromValue (Tuple [Index 0,payload]) = S.FiniteLimit <$> fromValue payload
    fromValue (Tuple [Index 1]) = pure S.PositiveInfinity
    fromValue (Tuple [Index 2]) = pure S.NegativeInfinity
    fromValue (Tuple [Index 3]) = pure S.DoesNotExist
    fromValue _ = invalid "invalid LimitResult constructor"
instance ToValue S.LimitResult where
    toValue (S.FiniteLimit x) = Tuple <$> sequence [pure (Index 0),toValue x]
    toValue S.PositiveInfinity = pure (Tuple [Index 1])
    toValue S.NegativeInfinity = pure (Tuple [Index 2])
    toValue S.DoesNotExist = pure (Tuple [Index 3])
instance FromValue S.LinearSolution where
    fromValue (Tuple [Index 0]) = pure S.Inconsistent
    fromValue (Tuple [Index 1,a,b]) = S.ParametricSolution <$> fromValue a <*> fromValue b
    fromValue _ = invalid "invalid LinearSolution constructor"
instance ToValue S.LinearSolution where
    toValue S.Inconsistent = pure (Tuple [Index 0])
    toValue (S.ParametricSolution a b) = Tuple <$> sequence [pure (Index 1),toValue a,toValue b]
instance FromValue (S.Guarded Value) where
    fromValue value = do [a,b]<-asTuple 2 value; S.Guarded a <$> fromValue b
instance ToValue a => ToValue (S.Guarded a) where toValue (S.Guarded a b) = toValue (a,b)
instance FromValue (P.Polynomial Rational) where fromValue = Poly.asPolynomial
instance ToValue (P.Polynomial Rational) where toValue = pure . Poly.poly SRational
instance FromValue (P.PowerSeries Rational) where fromValue = Poly.asSeries
instance ToValue (P.PowerSeries Rational) where toValue = pure . Poly.series SRational

instance FromValue E.UnaryOp where fromValue = fromEnumValue [E.Negate]
instance ToValue E.UnaryOp where toValue = toEnumValue [E.Negate]

instance FromValue E.BinaryOp where fromValue = fromEnumValue [E.Add,E.Subtract,E.Multiply,E.Divide,E.Power]
instance ToValue E.BinaryOp where toValue = toEnumValue [E.Add,E.Subtract,E.Multiply,E.Divide,E.Power]

instance FromValue E.NamedConstant where fromValue = fromEnumValue [E.Pi,E.Euler,E.Tau]
instance ToValue E.NamedConstant where toValue = toEnumValue [E.Pi,E.Euler,E.Tau]

instance FromValue E.Precision where fromValue = fromEnumValue [E.ExactRational,E.Float64]
instance ToValue E.Precision where toValue = toEnumValue [E.ExactRational,E.Float64]

instance FromValue E.ErrorKind where fromValue = fromEnumValue [E.SyntaxError,E.UnknownName,E.TypeMismatch,E.DomainFailure,E.NonFinite,E.StepLimit,E.DepthLimit,E.MemoryLimit,E.InvalidLimits,E.Unsupported]
instance ToValue E.ErrorKind where toValue = toEnumValue [E.SyntaxError,E.UnknownName,E.TypeMismatch,E.DomainFailure,E.NonFinite,E.StepLimit,E.DepthLimit,E.MemoryLimit,E.InvalidLimits,E.Unsupported]

instance FromValue E.Builtin where fromValue = fromEnumValue [E.Sin,E.Cos,E.Tan,E.Exp,E.Log,E.Sqrt,E.Abs,E.Signum,E.Floor,E.Ceiling,E.Min,E.Max,E.Asin,E.Acos,E.Atan,E.Sinh,E.Cosh,E.Tanh]
instance ToValue E.Builtin where toValue = toEnumValue [E.Sin,E.Cos,E.Tan,E.Exp,E.Log,E.Sqrt,E.Abs,E.Signum,E.Floor,E.Ceiling,E.Min,E.Max,E.Asin,E.Acos,E.Atan,E.Sinh,E.Cosh,E.Tanh]

instance FromValue S.Property where fromValue = fromEnumValue [S.Real,S.NonZero,S.Positive,S.NonNegative,S.Integral,S.Negative,S.NonPositive]
instance ToValue S.Property where toValue = toEnumValue [S.Real,S.NonZero,S.Positive,S.NonNegative,S.Integral,S.Negative,S.NonPositive]

instance FromValue S.Direction where fromValue = fromEnumValue [S.FromLeft,S.FromRight,S.TwoSided]
instance ToValue S.Direction where toValue = toEnumValue [S.FromLeft,S.FromRight,S.TwoSided]

instance FromValue S.RelationOp where fromValue = fromEnumValue [S.Equal,S.NotEqual,S.Less,S.LessEqual,S.Greater,S.GreaterEqual]
instance ToValue S.RelationOp where toValue = toEnumValue [S.Equal,S.NotEqual,S.Less,S.LessEqual,S.Greater,S.GreaterEqual]

instance FromValue E.Expr where fromValue = unbox 80
instance ToValue E.Expr where toValue = pure . boxed 80

instance FromValue E.ExprNode where fromValue = unbox 81
instance ToValue E.ExprNode where toValue = pure . boxed 81

instance FromValue E.Registry where fromValue = unbox 82
instance ToValue E.Registry where toValue = pure . boxed 82

instance FromValue E.Compiled where fromValue = unbox 83
instance ToValue E.Compiled where toValue = pure . boxed 83

instance FromValue E.ExpressionCache where fromValue = unbox 84
instance ToValue E.ExpressionCache where toValue = pure . boxed 84

instance FromValue S.Pattern where fromValue = unbox 85
instance ToValue S.Pattern where toValue = pure . boxed 85

instance FromValue S.Assumptions where fromValue = unbox 86
instance ToValue S.Assumptions where toValue = pure . boxed 86

instance FromValue S.SymbolicMatrix where fromValue = unbox 87
instance ToValue S.SymbolicMatrix where toValue = pure . boxed 87

class Apply a where apply :: a -> [Value] -> IO Value
instance {-# OVERLAPPABLE #-} ToValue a => Apply a where
    apply value [] = toValue value
    apply _ _ = invalid "too many expression arguments"
instance {-# OVERLAPPING #-} (FromValue a,Apply b) => Apply (a -> b) where
    apply function (value:rest) = fromValue value >>= \argument -> apply (function argument) rest
    apply _ [] = invalid "missing expression argument"

data ExpressionFailure = ExpressionFailure E.ExprError deriving Show
instance Exception ExpressionFailure
foreign import ccall unsafe "hm_error" report :: CInt -> CString -> IO CInt
foreign import ccall unsafe "hm_record_expression_error" recordError :: CInt -> Ptr CPtrdiff -> CString -> CSize -> IO CInt
expressionBoundary :: IO CInt -> IO CInt
expressionBoundary action = B.boundary (action `catch` failed)
  where
    failed (ExpressionFailure err) = do
        _ <- withCString (show err) (report 12)
        Index kind <- toValue (E.errorKind err)
        let E.SourcePos offset line column = E.errorPosition err
        code <- withArray (map fromIntegral [offset,line,column]) $ \position ->
            withEncodedMessage (E.errorMessage err) (recordError (fromIntegral kind) position)
        if code == 0 then pure 12 else withCString "unable to record ExprError" (report code)
foreign export ccall "hm_expression_apply" ffiApply :: CString -> Ptr (StablePtr Value) -> CSize -> Ptr (StablePtr Value) -> IO CInt
ffiApply :: CString -> Ptr (StablePtr Value) -> CSize -> Ptr (StablePtr Value) -> IO CInt
ffiApply namePointer arguments count out = expressionBoundary $ do
    name<-peekCString namePointer
    values<-peekArray (fromIntegral count) arguments >>= mapM deRefStablePtr
    result<-dispatch name values
    B.checked (Right ()) $ \_ -> publish result out
nodeFields :: E.ExprNode -> IO Value
nodeFields node = case node of
    E.Literal q -> Tuple <$> sequence [pure (Index 0),toValue q]
    E.Variable n -> Tuple <$> sequence [pure (Index 1),toValue n]
    E.Constant c -> Tuple <$> sequence [pure (Index 2),toValue c]
    E.Unary op child -> Tuple <$> sequence [pure (Index 3),toValue op,toValue child]
    E.Binary op a b -> Tuple <$> sequence [pure (Index 4),toValue op,toValue a,toValue b]
    E.Call name args -> Tuple <$> sequence [pure (Index 5),toValue name,toValue args]
    E.Let name a b -> Tuple <$> sequence [pure (Index 6),toValue name,toValue a,toValue b]
patternFields :: S.Pattern -> IO Value
patternFields patternValue = case patternValue of
    S.Any name -> Tuple <$> sequence [pure (Index 0),toValue name]
    S.Exactly expr -> Tuple <$> sequence [pure (Index 1),toValue expr]
    S.UnaryPattern op child -> Tuple <$> sequence [pure (Index 2),toValue op,toValue child]
    S.BinaryPattern op a b -> Tuple <$> sequence [pure (Index 3),toValue op,toValue a,toValue b]
    S.CallPattern name args -> Tuple <$> sequence [pure (Index 4),toValue name,toValue args]
dispatch :: String -> [Value] -> IO Value
dispatch name arguments = case name of
-- BEGIN GENERATED
    "HMath.Expression.SourcePos" -> apply E.SourcePos arguments
    "HMath.Expression.unknownPosition" -> apply E.unknownPosition arguments
    "HMath.Expression.sourceOffset" -> apply E.sourceOffset arguments
    "HMath.Expression.sourceLine" -> apply E.sourceLine arguments
    "HMath.Expression.sourceColumn" -> apply E.sourceColumn arguments
    "HMath.Expression.Negate" -> apply E.Negate arguments
    "HMath.Expression.Add" -> apply E.Add arguments
    "HMath.Expression.Subtract" -> apply E.Subtract arguments
    "HMath.Expression.Multiply" -> apply E.Multiply arguments
    "HMath.Expression.Divide" -> apply E.Divide arguments
    "HMath.Expression.Power" -> apply E.Power arguments
    "HMath.Expression.Pi" -> apply E.Pi arguments
    "HMath.Expression.Euler" -> apply E.Euler arguments
    "HMath.Expression.Tau" -> apply E.Tau arguments
    "HMath.Expression.ExactRational" -> apply E.ExactRational arguments
    "HMath.Expression.Float64" -> apply E.Float64 arguments
    "HMath.Expression.SyntaxError" -> apply E.SyntaxError arguments
    "HMath.Expression.UnknownName" -> apply E.UnknownName arguments
    "HMath.Expression.TypeMismatch" -> apply E.TypeMismatch arguments
    "HMath.Expression.DomainFailure" -> apply E.DomainFailure arguments
    "HMath.Expression.NonFinite" -> apply E.NonFinite arguments
    "HMath.Expression.StepLimit" -> apply E.StepLimit arguments
    "HMath.Expression.DepthLimit" -> apply E.DepthLimit arguments
    "HMath.Expression.MemoryLimit" -> apply E.MemoryLimit arguments
    "HMath.Expression.InvalidLimits" -> apply E.InvalidLimits arguments
    "HMath.Expression.Unsupported" -> apply E.Unsupported arguments
    "HMath.Expression.Sin" -> apply E.Sin arguments
    "HMath.Expression.Cos" -> apply E.Cos arguments
    "HMath.Expression.Tan" -> apply E.Tan arguments
    "HMath.Expression.Exp" -> apply E.Exp arguments
    "HMath.Expression.Log" -> apply E.Log arguments
    "HMath.Expression.Sqrt" -> apply E.Sqrt arguments
    "HMath.Expression.Abs" -> apply E.Abs arguments
    "HMath.Expression.Signum" -> apply E.Signum arguments
    "HMath.Expression.Floor" -> apply E.Floor arguments
    "HMath.Expression.Ceiling" -> apply E.Ceiling arguments
    "HMath.Expression.Min" -> apply E.Min arguments
    "HMath.Expression.Max" -> apply E.Max arguments
    "HMath.Expression.Asin" -> apply E.Asin arguments
    "HMath.Expression.Acos" -> apply E.Acos arguments
    "HMath.Expression.Atan" -> apply E.Atan arguments
    "HMath.Expression.Sinh" -> apply E.Sinh arguments
    "HMath.Expression.Cosh" -> apply E.Cosh arguments
    "HMath.Expression.Tanh" -> apply E.Tanh arguments
    "HMath.Expression.Expr" -> apply E.Expr arguments
    "HMath.Expression.expressionPosition" -> apply E.expressionPosition arguments
    "HMath.Expression.expressionNode" -> apply E.expressionNode arguments
    "HMath.Expression.Literal" -> apply E.Literal arguments
    "HMath.Expression.Variable" -> apply E.Variable arguments
    "HMath.Expression.Constant" -> apply E.Constant arguments
    "HMath.Expression.Unary" -> apply E.Unary arguments
    "HMath.Expression.Binary" -> apply E.Binary arguments
    "HMath.Expression.Call" -> apply E.Call arguments
    "HMath.Expression.Let" -> apply E.Let arguments
    "HMath.Expression.literal" -> apply E.literal arguments
    "HMath.Expression.variable" -> apply E.variable arguments
    "HMath.Expression.constant" -> apply E.constant arguments
    "HMath.Expression.unary" -> apply E.unary arguments
    "HMath.Expression.binary" -> apply E.binary arguments
    "HMath.Expression.call" -> apply E.call arguments
    "HMath.Expression.letIn" -> apply E.letIn arguments
    "HMath.Expression.Limits" -> apply E.Limits arguments
    "HMath.Expression.defaultLimits" -> apply E.defaultLimits arguments
    "HMath.Expression.maximumSteps" -> apply E.maximumSteps arguments
    "HMath.Expression.maximumDepth" -> apply E.maximumDepth arguments
    "HMath.Expression.maximumNodes" -> apply E.maximumNodes arguments
    "HMath.Expression.maximumInputChars" -> apply E.maximumInputChars arguments
    "HMath.Expression.maximumIntegerBits" -> apply E.maximumIntegerBits arguments
    "HMath.Expression.maximumCacheEntries" -> apply E.maximumCacheEntries arguments
    "HMath.Expression.ExprError" -> apply E.ExprError arguments
    "HMath.Expression.errorKind" -> apply E.errorKind arguments
    "HMath.Expression.errorPosition" -> apply E.errorPosition arguments
    "HMath.Expression.errorMessage" -> apply E.errorMessage arguments
    "HMath.Expression.validateLimits" -> apply E.validateLimits arguments
    "HMath.Expression.validateExpression" -> apply E.validateExpression arguments
    "HMath.Expression.parseExpression" -> apply E.parseExpression arguments
    "HMath.Expression.prettyExpression" -> apply E.prettyExpression arguments
    "HMath.Expression.freeVariables" -> apply E.freeVariables arguments
    "HMath.Expression.ExactValue" -> apply E.ExactValue arguments
    "HMath.Expression.FloatValue" -> apply E.FloatValue arguments
    "HMath.Expression.defaultRegistry" -> apply E.defaultRegistry arguments
    "HMath.Expression.emptyRegistry" -> apply E.emptyRegistry arguments
    "HMath.Expression.registerFunction" -> apply E.registerFunction arguments
    "HMath.Expression.allowedFunctions" -> apply E.allowedFunctions arguments
    "HMath.Expression.typeCheckExpression" -> apply E.typeCheckExpression arguments
    "HMath.Expression.evaluateExpression" -> apply E.evaluateExpression arguments
    "HMath.Expression.evaluateText" -> apply E.evaluateText arguments
    "HMath.Expression.evaluateCompiled" -> apply E.evaluateCompiled arguments
    "HMath.Expression.compileExpression" -> apply E.compileExpression arguments
    "HMath.Expression.compiledNodeCount" -> apply E.compiledNodeCount arguments
    "HMath.Expression.optimizeExpression" -> apply E.optimizeExpression arguments
    "HMath.Expression.emptyExpressionCache" -> apply E.emptyExpressionCache arguments
    "HMath.Expression.cacheSize" -> apply E.cacheSize arguments
    "HMath.Expression.cachedExpression" -> apply E.cachedExpression arguments
    "HMath.Expression.formatScientific" -> apply E.formatScientific arguments
    "HMath.Expression.formatRadix" -> apply E.formatRadix arguments
    "HMath.Expression.serializeExpression" -> apply E.serializeExpression arguments
    "HMath.Expression.deserializeExpression" -> apply E.deserializeExpression arguments
    "HMath.Expression.expressionHash" -> apply E.expressionHash arguments
    "HMath.Symbolic.Real" -> apply S.Real arguments
    "HMath.Symbolic.NonZero" -> apply S.NonZero arguments
    "HMath.Symbolic.Positive" -> apply S.Positive arguments
    "HMath.Symbolic.NonNegative" -> apply S.NonNegative arguments
    "HMath.Symbolic.Integral" -> apply S.Integral arguments
    "HMath.Symbolic.Negative" -> apply S.Negative arguments
    "HMath.Symbolic.NonPositive" -> apply S.NonPositive arguments
    "HMath.Symbolic.FromLeft" -> apply S.FromLeft arguments
    "HMath.Symbolic.FromRight" -> apply S.FromRight arguments
    "HMath.Symbolic.TwoSided" -> apply S.TwoSided arguments
    "HMath.Symbolic.Equal" -> apply S.Equal arguments
    "HMath.Symbolic.NotEqual" -> apply S.NotEqual arguments
    "HMath.Symbolic.Less" -> apply S.Less arguments
    "HMath.Symbolic.LessEqual" -> apply S.LessEqual arguments
    "HMath.Symbolic.Greater" -> apply S.Greater arguments
    "HMath.Symbolic.GreaterEqual" -> apply S.GreaterEqual arguments
    "HMath.Symbolic.assumptions" -> apply S.assumptions arguments
    "HMath.Symbolic.noAssumptions" -> apply S.noAssumptions arguments
    "HMath.Symbolic.proves" -> apply S.proves arguments
    "HMath.Symbolic.SymbolicOptions" -> apply S.SymbolicOptions arguments
    "HMath.Symbolic.defaultSymbolicOptions" -> apply S.defaultSymbolicOptions arguments
    "HMath.Symbolic.symbolicLimits" -> apply S.symbolicLimits arguments
    "HMath.Symbolic.symbolicAssumptions" -> apply S.symbolicAssumptions arguments
    "HMath.Symbolic.normalize" -> apply S.normalize arguments
    "HMath.Symbolic.simplify" -> apply S.simplify arguments
    "HMath.Symbolic.expand" -> apply S.expand arguments
    "HMath.Symbolic.collectTerms" -> apply S.collectTerms arguments
    "HMath.Symbolic.trigonometricSimplify" -> apply S.trigonometricSimplify arguments
    "HMath.Symbolic.logarithmicSimplify" -> apply S.logarithmicSimplify arguments
    "HMath.Symbolic.factorPolynomial" -> apply S.factorPolynomial arguments
    "HMath.Symbolic.rationalSimplify" -> apply S.rationalSimplify arguments
    "HMath.Symbolic.differentiate" -> apply S.differentiate arguments
    "HMath.Symbolic.integrateBasic" -> apply S.integrateBasic arguments
    "HMath.Symbolic.toPolynomial" -> apply S.toPolynomial arguments
    "HMath.Symbolic.exactPolynomialRoots" -> apply S.exactPolynomialRoots arguments
    "HMath.Symbolic.numericalPolynomialRoots" -> apply S.numericalPolynomialRoots arguments
    "HMath.Symbolic.PolynomialFactorization" -> apply S.PolynomialFactorization arguments
    "HMath.Symbolic.factorLeading" -> apply S.factorLeading arguments
    "HMath.Symbolic.factorTerms" -> apply S.factorTerms arguments
    "HMath.Symbolic.substitute" -> apply S.substitute arguments
    "HMath.Symbolic.Any" -> apply S.Any arguments
    "HMath.Symbolic.Exactly" -> apply S.Exactly arguments
    "HMath.Symbolic.UnaryPattern" -> apply S.UnaryPattern arguments
    "HMath.Symbolic.BinaryPattern" -> apply S.BinaryPattern arguments
    "HMath.Symbolic.CallPattern" -> apply S.CallPattern arguments
    "HMath.Symbolic.matchPattern" -> apply S.matchPattern arguments
    "HMath.Symbolic.RewriteRule" -> apply S.RewriteRule arguments
    "HMath.Symbolic.rewritePattern" -> apply S.rewritePattern arguments
    "HMath.Symbolic.rewriteReplacement" -> apply S.rewriteReplacement arguments
    "HMath.Symbolic.rewriteRequirements" -> apply S.rewriteRequirements arguments
    "HMath.Symbolic.applyRewrite" -> apply S.applyRewrite arguments
    "HMath.Symbolic.gradient" -> apply S.gradient arguments
    "HMath.Symbolic.hessian" -> apply S.hessian arguments
    "HMath.Symbolic.jacobian" -> apply S.jacobian arguments
    "HMath.Symbolic.integrateByParts" -> apply S.integrateByParts arguments
    "HMath.Symbolic.integrateSubstitution" -> apply S.integrateSubstitution arguments
    "HMath.Symbolic.integrateRational" -> apply S.integrateRational arguments
    "HMath.Symbolic.FiniteLimit" -> apply S.FiniteLimit arguments
    "HMath.Symbolic.PositiveInfinity" -> apply S.PositiveInfinity arguments
    "HMath.Symbolic.NegativeInfinity" -> apply S.NegativeInfinity arguments
    "HMath.Symbolic.DoesNotExist" -> apply S.DoesNotExist arguments
    "HMath.Symbolic.symbolicLimit" -> apply S.symbolicLimit arguments
    "HMath.Symbolic.Series" -> apply S.Series arguments
    "HMath.Symbolic.seriesCenter" -> apply S.seriesCenter arguments
    "HMath.Symbolic.seriesMinimumPower" -> apply S.seriesMinimumPower arguments
    "HMath.Symbolic.seriesTerms" -> apply S.seriesTerms arguments
    "HMath.Symbolic.taylorSeries" -> apply S.taylorSeries arguments
    "HMath.Symbolic.laurentSeries" -> apply S.laurentSeries arguments
    "HMath.Symbolic.maclaurinSeries" -> apply S.maclaurinSeries arguments
    "HMath.Symbolic.formalPowerSeries" -> apply S.formalPowerSeries arguments
    "HMath.Symbolic.multiplyFormalSeries" -> apply S.multiplyFormalSeries arguments
    "HMath.Symbolic.reciprocalFormalSeries" -> apply S.reciprocalFormalSeries arguments
    "HMath.Symbolic.fromPolynomial" -> apply S.fromPolynomial arguments
    "HMath.Symbolic.Relation" -> apply S.Relation arguments
    "HMath.Symbolic.Truth" -> apply S.Truth arguments
    "HMath.Symbolic.Unresolved" -> apply S.Unresolved arguments
    "HMath.Symbolic.simplifyRelation" -> apply S.simplifyRelation arguments
    "HMath.Symbolic.solveLinearInequality" -> apply S.solveLinearInequality arguments
    "HMath.Symbolic.Inconsistent" -> apply S.Inconsistent arguments
    "HMath.Symbolic.ParametricSolution" -> apply S.ParametricSolution arguments
    "HMath.Symbolic.solveLinearEquations" -> apply S.solveLinearEquations arguments
    "HMath.Symbolic.symbolicMatrix" -> apply S.symbolicMatrix arguments
    "HMath.Symbolic.matrixExpressions" -> apply S.matrixExpressions arguments
    "HMath.Symbolic.matrixAdd" -> apply S.matrixAdd arguments
    "HMath.Symbolic.matrixMultiply" -> apply S.matrixMultiply arguments
    "HMath.Symbolic.symbolicDeterminant" -> apply S.symbolicDeterminant arguments
    "HMath.Symbolic.Guarded" -> apply (S.Guarded :: Value -> [(E.Expr,S.Property)] -> S.Guarded Value) arguments
    "HMath.Symbolic.guardedValue" -> apply (S.guardedValue :: S.Guarded Value -> Value) arguments
    "HMath.Symbolic.requiredConditions" -> apply (S.requiredConditions :: S.Guarded Value -> [(E.Expr,S.Property)]) arguments
    "HMath.Symbolic.symbolicEigenvalues" -> apply S.symbolicEigenvalues arguments
    "HMath.Symbolic.numericalSubstitution" -> apply S.numericalSubstitution arguments
    "HMath.Symbolic.toLaTeX" -> apply S.toLaTeX arguments
    "HMath.Symbolic.toMathML" -> apply S.toMathML arguments
-- END GENERATED
    "__node_fields" -> do [value]<-pure arguments; fromValue value >>= nodeFields
    "__pattern_fields" -> do [value]<-pure arguments; fromValue value >>= patternFields
    "__compare_expr" -> apply (\a b -> case compare (a::E.Expr) b of { LT -> -1::Int; EQ -> 0; GT -> 1 }) arguments
    "__compare_node" -> apply (\a b -> case compare (a::E.ExprNode) b of { LT -> -1::Int; EQ -> 0; GT -> 1 }) arguments
    "__equal_pattern" -> apply ((==)::S.Pattern -> S.Pattern -> Bool) arguments
    _ -> invalid "invalid expression operation"
