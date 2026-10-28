-- SPDX-License-Identifier: MPL-2.0
module ExpressionBatchSpec (expressionBatchTests) where

import Data.Complex (magnitude)
import qualified Data.Map.Strict as Map
import Data.Ratio ((%))
import qualified HMath.Expression as E
import qualified HMath.Polynomial as P
import qualified HMath.Symbolic as S

right :: (a -> Bool) -> Either e a -> Bool
right f (Right value) = f value
right _ _ = False
near :: Double -> Double -> Bool
near a b = abs (a - b) < 1e-8 * (1 + abs b)
limits :: E.Limits
limits = E.defaultLimits
opts :: S.SymbolicOptions
opts = S.defaultSymbolicOptions
x, y :: E.Expr
x = E.variable "x"
y = E.variable "y"
parse :: String -> Either E.ExprError E.Expr
parse = E.parseExpression limits
exact :: String -> Either E.ExprError E.Value
exact = E.evaluateText limits E.ExactRational E.defaultRegistry Map.empty
float :: String -> Either E.ExprError E.Value
float = E.evaluateText limits E.Float64 E.defaultRegistry Map.empty
at :: Double -> E.Expr -> Either E.ExprError Double
at value e = do
    v <-
        E.evaluateExpression
            limits
            E.Float64
            E.defaultRegistry
            (Map.fromList [("x", E.FloatValue value), ("y", E.FloatValue 3)])
            e
    case v of
        E.FloatValue r -> Right r
        _ -> Left (E.ExprError E.TypeMismatch E.unknownPosition "test expected Float64")
errorIs :: E.ErrorKind -> Either E.ExprError a -> Bool
errorIs kind (Left e) = E.errorKind e == kind
errorIs _ _ = False
positive :: S.SymbolicOptions
positive = case S.assumptions [("x", [S.Positive]), ("y", [S.Positive])] of
    Right a -> opts{S.symbolicAssumptions = a}
    Left _ -> opts
nonzero :: S.SymbolicOptions
nonzero = case S.assumptions [("x", [S.NonZero])] of
    Right a -> opts{S.symbolicAssumptions = a}
    Left _ -> opts
sameAt :: [Double] -> E.Expr -> E.Expr -> Bool
sameAt points a b = all (\t -> right id (do u <- at t a; v <- at t b; Right (near u v))) points
calculus :: (E.Expr -> Either E.ExprError E.Expr) -> String -> String -> [Double] -> Bool
calculus operation source expected points =
    right
        id
        ( do
            e <- parse source
            target <- parse expected
            result <- operation e
            Right (sameAt points result target)
        )

expressionBatchTests :: [(String, Bool)]
expressionBatchTests =
    parserTests
        ++ evaluationTests
        ++ compilerTests
        ++ resourceTests
        ++ symbolicTests
        ++ calculusTests
        ++ algebraTests
        ++ exportTests
        ++ generatedTests

parserTests :: [(String, Bool)]
parserTests =
    [ ("expression precedence", exact "2+3*4" == Right (E.ExactValue 14))
    , ("expression powers right associative", exact "2^3^2" == Right (E.ExactValue 512))
    , ("expression unary below power", exact "-2^2" == Right (E.ExactValue (-4)))
    , ("expression negative exponent", exact "2^-3" == Right (E.ExactValue (1 % 8)))
    , ("expression left division", exact "8/4/2" == Right (E.ExactValue 1))
    , ("expression parentheses", exact "(-2)^2" == Right (E.ExactValue 4))
    , ("expression exact decimal", exact "0.1+0.2" == Right (E.ExactValue (3 % 10)))
    , ("expression scientific literal", exact "1.25e-2" == Right (E.ExactValue (1 % 80)))
    , ("expression rational literal", exact "2//3+1//6" == Right (E.ExactValue (5 % 6)))
    ,
        ( "expression position after exponent sign"
        , case exact "1e+3+u" of Left e -> E.sourceColumn (E.errorPosition e) == 6; _ -> False
        )
    ,
        ( "expression line column"
        , case exact "2+\n unknown" of Left e -> E.errorPosition e == E.SourcePos 4 2 2; _ -> False
        )
    , ("expression mismatched parenthesis", errorIs E.SyntaxError (parse "(2+3"))
    , ("expression trailing tokens", errorIs E.SyntaxError (parse "2 3"))
    , ("expression missing scientific exponent", errorIs E.SyntaxError (parse "2e+"))
    , ("expression missing call argument", errorIs E.SyntaxError (parse "min(1,)"))
    , ("expression illegal character", errorIs E.SyntaxError (parse "1;2"))
    , ("expression zero literal denominator", errorIs E.DomainFailure (parse "1//0"))
    , ("expression lexical let shadowing", exact "let x=3 in let x=x+1 in x*x" == Right (E.ExactValue 16))
    , ("expression let scope", errorIs E.UnknownName (exact "(let x=2 in x)+x"))
    , ("expression call commas", exact "max(2,min(4,3))" == Right (E.ExactValue 3))
    ]

evaluationTests :: [(String, Bool)]
evaluationTests =
    [
        ( "expression static exact type"
        , E.typeCheckExpression
            limits
            E.ExactRational
            E.defaultRegistry
            (Map.singleton "x" (E.ExactValue 2))
            x
            == Right E.ExactRational
        )
    ,
        ( "expression static builtin precision"
        , errorIs
            E.TypeMismatch
            (parse "sin(0)" >>= E.typeCheckExpression limits E.ExactRational E.defaultRegistry Map.empty)
        )
    ,
        ( "expression static lexical binding"
        , right
            (== E.ExactRational)
            (parse "let x=1 in x+2" >>= E.typeCheckExpression limits E.ExactRational E.defaultRegistry Map.empty)
        )
    ,
        ( "expression finite Float64 constants"
        , right (\v -> case v of E.FloatValue a -> near a 1; _ -> False) (float "sin(pi/2)")
        )
    , ("expression exact irrational constant rejects", errorIs E.TypeMismatch (exact "pi"))
    , ("expression exact transcendental rejects", errorIs E.TypeMismatch (exact "exp(0)"))
    , ("expression exact square root", exact "sqrt(9//16)" == Right (E.ExactValue (3 % 4)))
    , ("expression irrational square root rejects", errorIs E.TypeMismatch (exact "sqrt(2)"))
    ,
        ( "expression unary builtins"
        , exact "abs(-4)+floor(3//2)+ceil(3//2)+signum(-2)" == Right (E.ExactValue 6)
        )
    , ("expression wrong arity", errorIs E.TypeMismatch (exact "sin(1,2)"))
    , ("expression unknown function", errorIs E.UnknownName (exact "system(1)"))
    ,
        ( "expression disallowed function"
        , errorIs E.UnknownName (E.evaluateText limits E.Float64 E.emptyRegistry Map.empty "sin(1)")
        )
    ,
        ( "expression registry alias"
        , right
            ( \r ->
                right
                    (\v -> case v of E.FloatValue a -> near a 0; _ -> False)
                    (E.evaluateText limits E.Float64 r Map.empty "wave(0)")
            )
            (E.registerFunction "wave" E.Sin E.emptyRegistry)
        )
    ,
        ( "expression bad registry name"
        , errorIs E.SyntaxError (E.registerFunction "a;exec" E.Sin E.emptyRegistry)
        )
    ,
        ( "expression bindings precision check"
        , errorIs
            E.TypeMismatch
            (E.evaluateExpression limits E.Float64 E.defaultRegistry (Map.singleton "x" (E.ExactValue 2)) x)
        )
    ,
        ( "expression nonfinite binding"
        , errorIs
            E.NonFinite
            (E.evaluateExpression limits E.Float64 E.defaultRegistry (Map.singleton "x" (E.FloatValue (0 / 0))) x)
        )
    , ("expression division zero", errorIs E.DomainFailure (exact "1/0"))
    , ("expression zero negative power", errorIs E.DomainFailure (exact "0^-1"))
    , ("expression zero zero power", errorIs E.DomainFailure (exact "0^0"))
    , ("expression fractional exact power", errorIs E.TypeMismatch (exact "4^0.5"))
    , ("expression negative fractional power", errorIs E.DomainFailure (float "(-2)^0.5"))
    , ("expression logarithm domain", errorIs E.DomainFailure (float "log(-1)"))
    , ("expression square root domain", errorIs E.DomainFailure (float "sqrt(-1)"))
    , ("expression asin domain", errorIs E.DomainFailure (float "asin(2)"))
    , ("expression overflow", errorIs E.NonFinite (float "exp(1000)"))
    , ("expression strict unused let", errorIs E.DomainFailure (exact "let unused=1/0 in 3"))
    ,
        ( "expression stable free variables"
        , E.freeVariables (E.letIn "x" y (E.binary E.Add x (E.variable "z"))) == ["y", "z"]
        )
    , ("expression scientific formatting", E.formatScientific 2 (E.FloatValue 1234) == Right "1.23e3")
    ,
        ( "expression scientific invalid digits"
        , errorIs E.DomainFailure (E.formatScientific 31 (E.ExactValue 2))
        )
    , ("expression radix formatting", E.formatRadix 16 (E.ExactValue (-255)) == Right "-ff")
    ,
        ( "expression radix fraction rejects"
        , errorIs E.TypeMismatch (E.formatRadix 2 (E.ExactValue (1 % 2)))
        )
    , ("expression radix out of range", errorIs E.DomainFailure (E.formatRadix 1 (E.ExactValue 1)))
    ]

compilerTests :: [(String, Bool)]
compilerTests =
    [
        ( "expression DAG common subexpression"
        , right
            ( \p ->
                E.compiledNodeCount p == 4
                    && E.evaluateCompiled limits E.ExactRational E.defaultRegistry (Map.singleton "x" (E.ExactValue 2)) p
                        == Right (E.ExactValue 9)
            )
            (parse "(x+1)*(x+1)" >>= E.compileExpression limits)
        )
    ,
        ( "expression compiled strict let"
        , errorIs
            E.DomainFailure
            ( parse "let unused=1/0 in 2"
                >>= E.compileExpression limits
                >>= E.evaluateCompiled limits E.ExactRational E.defaultRegistry Map.empty
            )
        )
    ,
        ( "expression compiled lexical scopes"
        , right
            id
            ( do
                e <- parse "(let x=2 in x+1)+(let x=3 in x+1)"
                c <- E.compileExpression limits e
                Right
                    (E.evaluateCompiled limits E.ExactRational E.defaultRegistry Map.empty c == Right (E.ExactValue 7))
            )
        )
    ,
        ( "expression compiled allowed list enforced"
        , errorIs
            E.UnknownName
            ( parse "sin(0)"
                >>= E.compileExpression limits
                >>= E.evaluateCompiled limits E.Float64 E.emptyRegistry Map.empty
            )
        )
    ,
        ( "expression exact constant folding"
        , (parse "(2+3)*4" >>= E.optimizeExpression limits E.ExactRational) == Right (E.literal 20)
        )
    ,
        ( "expression Float64 preserves association"
        , right (\e -> E.optimizeExpression limits E.Float64 e == Right e) (parse "0.1+0.2+0.3")
        )
    ,
        ( "expression folding retains unknown variable"
        , errorIs
            E.UnknownName
            ( parse "0*x"
                >>= E.optimizeExpression limits E.ExactRational
                >>= E.evaluateExpression limits E.ExactRational E.defaultRegistry Map.empty
            )
        )
    ,
        ( "expression cache syntax reuse"
        , right
            (\(a, c) -> right (\(b, d) -> a == b && E.cacheSize d == 1) (E.cachedExpression limits "x+1" c))
            (E.cachedExpression limits "x+1" E.emptyExpressionCache)
        )
    ,
        ( "expression cache FIFO eviction"
        , right
            (\(_, c) -> E.cacheSize c == 1)
            ( do
                (_, c) <- E.cachedExpression limits{E.maximumCacheEntries = 1} "x+1" E.emptyExpressionCache
                E.cachedExpression limits{E.maximumCacheEntries = 1} "x+2" c
            )
        )
    ,
        ( "expression cache does not capture bindings"
        , right
            ( \(c, _) ->
                E.evaluateCompiled limits E.ExactRational E.defaultRegistry (Map.singleton "x" (E.ExactValue 2)) c
                    == Right (E.ExactValue 3)
                    && E.evaluateCompiled limits E.ExactRational E.defaultRegistry (Map.singleton "x" (E.ExactValue 4)) c
                        == Right (E.ExactValue 5)
            )
            (E.cachedExpression limits "x+1" E.emptyExpressionCache)
        )
    ]

resourceTests :: [(String, Bool)]
resourceTests =
    [
        ( "symbolic finite limit validates result bits"
        , errorIs
            E.MemoryLimit
            ( S.symbolicLimit
                opts{S.symbolicLimits = limits{E.maximumIntegerBits = 8}}
                "x"
                16
                S.TwoSided
                (E.binary E.Power x (E.literal 2))
            )
        )
    ,
        ( "symbolic affine inequality validates result bits"
        , errorIs
            E.MemoryLimit
            ( S.solveLinearInequality
                opts{S.symbolicLimits = limits{E.maximumIntegerBits = 8}}
                "x"
                ( S.Relation
                    S.Less
                    (E.binary E.Add (E.literal (127 % 128)) (E.binary E.Multiply (E.literal (1 % 127)) x))
                    (E.literal 0)
                )
            )
        )
    ,
        ( "symbolic Laurent zero validates center bits"
        , errorIs
            E.MemoryLimit
            ( S.laurentSeries
                opts{S.symbolicLimits = limits{E.maximumIntegerBits = 16}}
                "x"
                (2 ^ (40 :: Int))
                3
                (E.literal 0)
            )
        )
    ,
        ( "symbolic Laurent composition validates center bits"
        , errorIs
            E.MemoryLimit
            (S.laurentSeries opts{S.symbolicLimits = limits{E.maximumIntegerBits = 16}} "x" (2 ^ (40 :: Int)) 3 x)
        )
    ,
        ( "symbolic substitution rejects infinite replacement table"
        , errorIs E.MemoryLimit (S.substitute limits{E.maximumNodes = 4} (repeat ("x", E.literal 1)) x)
        )
    ,
        ( "symbolic 1x1 eigenvalue revalidates bits"
        , errorIs
            E.MemoryLimit
            ( S.symbolicMatrix opts [[E.literal (2 ^ (40 :: Int))]]
                >>= S.symbolicEigenvalues opts{S.symbolicLimits = limits{E.maximumIntegerBits = 16}}
            )
        )
    ,
        ( "symbolic 1x1 eigenvalue revalidates limits"
        , errorIs
            E.InvalidLimits
            ( S.symbolicMatrix opts [[x]]
                >>= S.symbolicEigenvalues opts{S.symbolicLimits = limits{E.maximumSteps = 0}}
            )
        )
    ,
        ( "symbolic empty gradient revalidates expression"
        , errorIs
            E.MemoryLimit
            ( S.gradient
                opts{S.symbolicLimits = limits{E.maximumIntegerBits = 16}}
                []
                (E.literal (2 ^ (40 :: Int)))
            )
        )
    ,
        ( "expression character limit"
        , errorIs E.MemoryLimit (E.parseExpression limits{E.maximumInputChars = 3} "1+234")
        )
    ,
        ( "expression parser depth limit"
        , errorIs E.DepthLimit (E.parseExpression limits{E.maximumDepth = 16} "((((((1))))))")
        )
    ,
        ( "expression AST depth limit"
        , errorIs
            E.DepthLimit
            (E.validateExpression limits{E.maximumDepth = 3} (iterate (E.unary E.Negate) x !! 4))
        )
    ,
        ( "expression AST node memory limit"
        , errorIs E.MemoryLimit (E.validateExpression limits{E.maximumNodes = 2} (E.binary E.Add x y))
        )
    ,
        ( "expression integer literal limit"
        , errorIs E.MemoryLimit (E.parseExpression limits{E.maximumIntegerBits = 8} "123456")
        )
    ,
        ( "expression arithmetic growth limit"
        , errorIs
            E.MemoryLimit
            ( E.evaluateText
                limits{E.maximumIntegerBits = 16}
                E.ExactRational
                E.defaultRegistry
                Map.empty
                "255^20"
            )
        )
    ,
        ( "expression huge exponent rejected"
        , errorIs
            E.MemoryLimit
            ( parse "2^100000000000000000000"
                >>= E.evaluateExpression limits E.ExactRational E.defaultRegistry Map.empty
            )
        )
    ,
        ( "expression invalid negative limits"
        , errorIs E.InvalidLimits (E.parseExpression limits{E.maximumSteps = 0} "1")
        )
    ,
        ( "expression parse step limit"
        , errorIs E.StepLimit (E.parseExpression limits{E.maximumSteps = 3} "1+2+3")
        )
    ,
        ( "expression evaluation step limit"
        , errorIs
            E.StepLimit
            ( E.evaluateExpression
                limits{E.maximumSteps = 2}
                E.ExactRational
                E.defaultRegistry
                Map.empty
                (E.binary E.Add (E.literal 1) (E.literal 2))
            )
        )
    ,
        ( "expression compiler step limit"
        , errorIs
            E.StepLimit
            (E.compileExpression limits{E.maximumSteps = 3} (E.binary E.Add (E.literal 1) (E.literal 2)))
        )
    ,
        ( "expression compiler memory limit"
        , errorIs E.MemoryLimit (E.compileExpression limits{E.maximumNodes = 2} (E.binary E.Add x y))
        )
    ,
        ( "expression cache memory limit"
        , errorIs
            E.MemoryLimit
            ( E.cachedExpression limits{E.maximumNodes = 8} "x+1" E.emptyExpressionCache >>= \(_, c) -> E.cachedExpression limits{E.maximumNodes = 8} "y+2" c
            )
        )
    ,
        ( "expression cached tighter validation"
        , right
            ( \(_, cache) -> errorIs E.MemoryLimit (E.cachedExpression limits{E.maximumInputChars = 2} "x+1" cache)
            )
            (E.cachedExpression limits "x+1" E.emptyExpressionCache)
        )
    ,
        ( "expression no unsafe serialization reader"
        , errorIs E.SyntaxError (E.deserializeExpression limits "Expr (SourcePos 0 0 0) (Literal (1 % 0))")
        )
    ,
        ( "expression serialized zero denominator"
        , errorIs E.DomainFailure (E.deserializeExpression limits "__lit(1,0)")
        )
    ]

symbolicTests :: [(String, Bool)]
symbolicTests =
    [ ("symbolic expression ignores positions", E.Expr (E.SourcePos 9 2 3) (E.Variable "x") == x)
    ,
        ( "symbolic assumptions contradictions"
        , errorIs E.DomainFailure (S.assumptions [("x", [S.Positive]), ("x", [S.NonPositive])])
        )
    , ("symbolic assumptions implication", S.proves (S.symbolicAssumptions positive) S.NonZero x)
    , ("symbolic collect like terms", calculus (S.simplify opts) "2*x+3*x-x" "4*x" [-2, 0, 3])
    , ("symbolic expansion", calculus (S.expand opts) "(x+1)*(x-1)" "x^2-1" [-2, 0, 3])
    , ("symbolic no unsafe cancellation", right (\e -> S.simplify opts e == Right e) (parse "x/x"))
    , ("symbolic assumed cancellation", (parse "x/x" >>= S.simplify nonzero) == Right (E.literal 1))
    ,
        ( "symbolic preserves partial zero product"
        , right (\e -> right (\r -> errorIs E.DomainFailure (at 0 r)) (S.simplify opts e)) (parse "0*(1/x)")
        )
    ,
        ( "symbolic trig identity"
        , (parse "sin(x)^2+cos(x)^2" >>= S.trigonometricSimplify opts) == Right (E.literal 1)
        )
    , ("symbolic log exp real identity", S.simplify opts (E.call "log" [E.call "exp" [x]]) == Right x)
    ,
        ( "symbolic exp log needs positive"
        , S.simplify opts (E.call "exp" [E.call "log" [x]]) == Right (E.call "exp" [E.call "log" [x]])
        )
    ,
        ( "symbolic exp log positive identity"
        , S.simplify positive (E.call "exp" [E.call "log" [x]]) == Right x
        )
    ,
        ( "symbolic log product positive"
        , calculus (S.logarithmicSimplify positive) "log(x*y)" "log(x)+log(y)" [0.2, 1, 4]
        )
    ,
        ( "symbolic rational reduction guarded"
        , calculus (S.rationalSimplify positive "x") "(x*x+x)/(x+1)" "x" [0.2, 1, 4]
        )
    ,
        ( "symbolic capture-safe substitution"
        , right
            ( \e ->
                right
                    ( \r ->
                        E.freeVariables r == ["y"]
                            && E.evaluateExpression limits E.ExactRational E.defaultRegistry (Map.singleton "y" (E.ExactValue 7)) r
                                == Right (E.ExactValue 9)
                    )
                    (S.substitute limits [("x", y)] e)
            )
            (parse "let y=2 in x+y")
        )
    ,
        ( "symbolic simultaneous substitution"
        , S.substitute limits [("x", y), ("y", E.literal 3)] x == Right y
        )
    ,
        ( "symbolic repeated wildcard match"
        , right
            (\m -> m == Just [("a", x)])
            (S.matchPattern limits (S.BinaryPattern E.Add (S.Any "a") (S.Any "a")) (E.binary E.Add x x))
        )
    ,
        ( "symbolic unequal wildcard rejects"
        , S.matchPattern limits (S.BinaryPattern E.Add (S.Any "a") (S.Any "a")) (E.binary E.Add x y)
            == Right Nothing
        )
    ,
        ( "symbolic conditional rewrite"
        , S.applyRewrite
            positive
            (S.RewriteRule (S.BinaryPattern E.Divide (S.Any "a") (S.Any "a")) (E.literal 1) [("a", S.NonZero)])
            (E.binary E.Divide x x)
            == Right (E.literal 1)
        )
    ,
        ( "symbolic rewrite missing premise rejects"
        , errorIs
            E.DomainFailure
            ( S.applyRewrite
                opts
                (S.RewriteRule (S.BinaryPattern E.Divide (S.Any "a") (S.Any "a")) (E.literal 1) [("a", S.NonZero)])
                (E.binary E.Divide x x)
            )
        )
    ]

calculusTests :: [(String, Bool)]
calculusTests =
    [
        ( "symbolic strict let derivative domain"
        , errorIs E.Unsupported (parse "let unused=1/0 in x" >>= S.differentiate opts "x")
        )
    ,
        ( "symbolic undefined fractional power proof"
        , not (S.proves (S.symbolicAssumptions nonzero) S.NonZero (E.binary E.Power x (E.literal (1 % 2))))
        )
    ,
        ( "symbolic polynomial derivative"
        , calculus (S.differentiate opts "x") "x^3+2*x" "3*x^2+2" [-2, 0, 3]
        )
    ,
        ( "symbolic elementary derivative"
        , calculus (S.differentiate opts "x") "exp(x)*sin(x)" "exp(x)*(sin(x)+cos(x))" [-2, 0, 1]
        )
    ,
        ( "symbolic logarithm derivative"
        , calculus (S.differentiate positive "x") "log(x)" "1/x" [0.2, 1, 3]
        )
    ,
        ( "symbolic log derivative domain required"
        , errorIs E.Unsupported (S.differentiate opts "x" (E.call "log" [x]))
        )
    ,
        ( "symbolic variable power derivative"
        , calculus (S.differentiate positive "x") "x^x" "x^x*(log(x)+1)" [0.2, 1, 3]
        )
    ,
        ( "symbolic gradient"
        , right
            (\g -> length g == 2 && right (near 12) (at 2 (g !! 0)) && right (near 4) (at 2 (g !! 1)))
            (parse "x*x*y" >>= S.gradient opts ["x", "y"])
        )
    ,
        ( "symbolic Jacobian"
        , right
            (\m -> length m == 2 && all ((== 2) . length) m && right (near 3) (at 2 (m !! 1 !! 0)))
            (do a <- parse "x*x"; b <- parse "x*y"; S.jacobian opts ["x", "y"] [a, b])
        )
    ,
        ( "symbolic Hessian"
        , right
            (\m -> right (near 6) (at 2 (m !! 0 !! 0)) && right (near 4) (at 2 (m !! 0 !! 1)))
            (parse "x*x*y" >>= S.hessian opts ["x", "y"])
        )
    ,
        ( "symbolic polynomial primitive"
        , calculus
            (\e -> S.integrateBasic opts "x" e >>= S.differentiate opts "x")
            "3*x^2+2"
            "3*x^2+2"
            [-2, 0, 3]
        )
    ,
        ( "symbolic affine primitive"
        , calculus
            (\e -> S.integrateBasic opts "x" e >>= S.differentiate opts "x")
            "sin(2*x+1)"
            "sin(2*x+1)"
            [-2, 0, 3]
        )
    ,
        ( "symbolic parts primitive"
        , right
            ( \primitive ->
                right
                    (\d -> sameAt [-2, 0, 2] d (E.binary E.Multiply x (E.call "exp" [x])))
                    (S.differentiate opts "x" primitive)
            )
            (S.integrateByParts opts "x" x (E.call "exp" [x]))
        )
    ,
        ( "symbolic substitution primitive"
        , right
            (\p -> right (\d -> right (sameAt [-1, 0, 2] d) (parse "2*x*sin(x^2)")) (S.differentiate opts "x" p))
            ( do
                inner <- parse "x^2"
                integrand <- parse "2*x*sin(x^2)"
                S.integrateSubstitution opts "x" "t" inner (E.call "sin" [E.variable "t"]) integrand
            )
        )
    ,
        ( "symbolic incorrect substitution rejects"
        , errorIs
            E.Unsupported
            ( do
                inner <- parse "x^2"
                S.integrateSubstitution opts "x" "t" inner (E.call "sin" [E.variable "t"]) (E.literal 1)
            )
        )
    ,
        ( "symbolic rational linear pole primitive"
        , right
            ( \p ->
                right
                    (\d -> sameAt [-2, -1, 1, 2] d (E.binary E.Divide (E.literal 1) x))
                    (S.differentiate nonzero "x" p)
            )
            (S.integrateRational nonzero "x" (E.literal 1) x)
        )
    ,
        ( "symbolic rational quadratic primitive"
        , right
            (\p -> right (\d -> right (sameAt [-2, 0, 2] d) (parse "1/(1+x*x)")) (S.differentiate opts "x" p))
            (parse "x^2+1" >>= S.integrateRational opts "x" (E.literal 1))
        )
    ,
        ( "symbolic unsupported integral explicit"
        , errorIs E.Unsupported (parse "exp(x*x)" >>= S.integrateBasic opts "x")
        )
    ,
        ( "symbolic rational removable limit"
        , (parse "(x*x-1)/(x-1)" >>= S.symbolicLimit opts "x" 1 S.TwoSided) == Right (S.FiniteLimit 2)
        )
    ,
        ( "symbolic rational odd pole limit"
        , (parse "1/x" >>= S.symbolicLimit opts "x" 0 S.TwoSided) == Right S.DoesNotExist
        )
    ,
        ( "symbolic rational sided limit"
        , (parse "1/x" >>= S.symbolicLimit opts "x" 0 S.FromLeft) == Right S.NegativeInfinity
        )
    ,
        ( "symbolic rational even pole limit"
        , (parse "1/(x*x)" >>= S.symbolicLimit opts "x" 0 S.TwoSided) == Right S.PositiveInfinity
        )
    ,
        ( "symbolic Taylor sine"
        , right
            (\s -> S.seriesTerms s == map E.literal [0, 1, 0, -1 % 6, 0, 1 % 120, 0, -1 % 5040])
            (S.maclaurinSeries opts "x" 7 (E.call "sin" [x]))
        )
    ,
        ( "symbolic Taylor exponential"
        , right
            (\s -> S.seriesTerms s == map E.literal [1, 1, 1 % 2, 1 % 6, 1 % 24])
            (S.maclaurinSeries opts "x" 4 (E.call "exp" [x]))
        )
    ,
        ( "symbolic Taylor pole rejects"
        , errorIs E.Unsupported (parse "1/x" >>= S.maclaurinSeries opts "x" 3)
        )
    ,
        ( "symbolic Laurent rational pole"
        , right
            (\s -> S.seriesMinimumPower s == (-1) && S.seriesTerms s == replicate 5 (E.literal 1))
            (parse "1/(x*(1-x))" >>= S.laurentSeries opts "x" 0 4)
        )
    ,
        ( "symbolic formal reciprocal"
        , right
            (\p -> P.seriesCoefficients p == [1, 1, 1, 1])
            (S.formalPowerSeries opts [1, -1, 0, 0] >>= S.reciprocalFormalSeries opts)
        )
    ,
        ( "symbolic formal convolution"
        , right
            (\p -> P.seriesCoefficients p == [1, 3, 3])
            ( do
                a <- S.formalPowerSeries opts [1, 1, 0]
                b <- S.formalPowerSeries opts [1, 2, 1]
                S.multiplyFormalSeries opts a b
            )
        )
    ]

algebraTests :: [(String, Bool)]
algebraTests =
    [
        ( "symbolic polynomial exact conversion"
        , right (\p -> P.coefficients p == [1, 2, 1]) (parse "(x+1)^2" >>= S.toPolynomial opts "x")
        )
    ,
        ( "symbolic polynomial factorization"
        , right
            (\f -> S.factorLeading f == 1 && length (S.factorTerms f) == 2)
            (parse "x^2-1" >>= S.factorPolynomial opts "x")
        )
    ,
        ( "symbolic rational roots and residual"
        , right
            (\(roots, residual) -> sortRoots roots == [(-1, 1), (1, 1)] && residual == E.literal 1)
            (parse "x^2-1" >>= S.exactPolynomialRoots opts "x")
        )
    ,
        ( "symbolic unresolved irrational residual"
        , right
            ( \(roots, residual) ->
                null roots
                    && sameAt [-2, 0, 2] residual (E.binary E.Subtract (E.binary E.Power x (E.literal 2)) (E.literal 2))
            )
            (parse "x^2-2" >>= S.exactPolynomialRoots opts "x")
        )
    ,
        ( "symbolic complex numerical roots"
        , right
            (\roots -> length roots == 2 && all (\z -> magnitude (z * z + 1) < 1e-8) roots)
            (parse "x^2+1" >>= S.numericalPolynomialRoots opts "x")
        )
    ,
        ( "symbolic linear equations"
        , right
            ( \s -> case s of
                S.ParametricSolution values free -> null free && lookup "x" values == Just (E.literal 2) && lookup "y" values == Just (E.literal 1)
                _ -> False
            )
            ( do
                a <- parse "x+y"
                b <- parse "x-y"
                S.solveLinearEquations opts ["x", "y"] [(a, E.literal 3), (b, E.literal 1)]
            )
        )
    ,
        ( "symbolic underdetermined equations"
        , right
            ( \s -> case s of
                S.ParametricSolution values free -> free == ["y"] && right (near 0) (at 0 (snd (values !! 0)))
                _ -> False
            )
            (do a <- parse "x+y"; S.solveLinearEquations opts ["x", "y"] [(a, E.literal 3)])
        )
    ,
        ( "symbolic inconsistent equations"
        , S.solveLinearEquations opts ["x"] [(x, E.literal 1), (x, E.literal 2)] == Right S.Inconsistent
        )
    ,
        ( "symbolic nonlinear equation rejects"
        , errorIs
            E.Unsupported
            (parse "x*y" >>= \a -> S.solveLinearEquations opts ["x", "y"] [(a, E.literal 1)])
        )
    ,
        ( "symbolic constant inequality"
        , S.simplifyRelation opts (S.Relation S.Less (E.literal 2) (E.literal 3)) == Right (S.Truth True)
        )
    ,
        ( "symbolic negative inequality flips"
        , right
            (\r -> r == S.Unresolved (S.Relation S.Greater x (E.literal (-2))))
            (parse "-2*x" >>= \a -> S.solveLinearInequality opts "x" (S.Relation S.Less a (E.literal 4)))
        )
    ,
        ( "symbolic no unsafe relation cancellation"
        , right
            (\r -> case r of S.Unresolved _ -> True; _ -> False)
            (parse "1/x" >>= \a -> S.simplifyRelation opts (S.Relation S.Equal a a))
        )
    ,
        ( "symbolic determinant"
        , right
            (\d -> sameAt [-2, 0, 2] d (E.binary E.Subtract x (E.literal 6)))
            (S.symbolicMatrix opts [[x, E.literal 2], [E.literal 3, E.literal 1]] >>= S.symbolicDeterminant opts)
        )
    ,
        ( "symbolic matrix product"
        , right
            (\m -> right (near 5) (at 2 ((S.matrixExpressions m !! 0) !! 0)))
            ( do
                a <- S.symbolicMatrix opts [[x, E.literal 1]]
                b <- S.symbolicMatrix opts [[E.literal 2], [E.literal 1]]
                S.matrixMultiply opts a b
            )
        )
    ,
        ( "symbolic exact real eigenvalues"
        , right
            (\g -> null (S.requiredConditions g) && S.guardedValue g == map E.literal [1, 3])
            ( S.symbolicMatrix opts [[E.literal 2, E.literal 1], [E.literal 1, E.literal 2]]
                >>= S.symbolicEigenvalues opts
            )
        )
    ,
        ( "symbolic conditional eigenvalue branches"
        , right
            (\g -> not (null (S.requiredConditions g)))
            (S.symbolicMatrix opts [[x, E.literal 1], [y, E.literal 0]] >>= S.symbolicEigenvalues opts)
        )
    ,
        ( "symbolic complex eigenvalues explicit unsupported"
        , errorIs
            E.Unsupported
            ( S.symbolicMatrix opts [[E.literal 0, E.literal (-1)], [E.literal 1, E.literal 0]]
                >>= S.symbolicEigenvalues opts
            )
        )
    , ("symbolic ragged matrix rejects", errorIs E.DomainFailure (S.symbolicMatrix opts [[x], [x, y]]))
    , ("symbolic duplicate variables reject", errorIs E.DomainFailure (S.gradient opts ["x", "x"] x))
    ,
        ( "symbolic oversized expansion rejected"
        , errorIs
            E.MemoryLimit
            (parse "(x+y)^20" >>= S.expand opts{S.symbolicLimits = limits{E.maximumNodes = 50}})
        )
    ]
  where
    sortRoots roots = Map.toAscList (Map.fromList roots)

exportTests :: [(String, Bool)]
exportTests =
    [
        ( "symbolic LaTeX golden"
        , S.toLaTeX limits (E.binary E.Divide x (E.literal 2)) == Right "\\frac{\\mathrm{x}}{2}"
        )
    , ("symbolic LaTeX name escape", S.toLaTeX limits (E.variable "x_1") == Right "\\mathrm{x\\_1}")
    ,
        ( "symbolic MathML golden"
        , S.toMathML limits (E.binary E.Add x (E.literal 1))
            == Right
                "<math xmlns=\"http://www.w3.org/1998/Math/MathML\"><apply><plus/><ci>x</ci><cn>1</cn></apply></math>"
        )
    , ("symbolic XML injection rejects", errorIs E.SyntaxError (S.toMathML limits (E.variable "x</ci>")))
    , ("symbolic export size limit", errorIs E.MemoryLimit (S.toLaTeX limits{E.maximumInputChars = 5} x))
    ,
        ( "symbolic hash location independent"
        , E.expressionHash limits x == E.expressionHash limits (E.Expr (E.SourcePos 9 2 4) (E.Variable "x"))
        )
    , ("symbolic hash differs structure", E.expressionHash limits x /= E.expressionHash limits y)
    ]

generatedTests :: [(String, Bool)]
generatedTests =
    [ ( "expression roundtrip " ++ show i
      , right (== e) (E.serializeExpression limits e >>= E.deserializeExpression limits)
      )
    | (i, e) <- zip [0 :: Int ..] expressions
    ]
        ++ [ ( "expression compiler agreement " ++ show i
             , right
                id
                ( do
                    c <- E.compileExpression limits e
                    let env = Map.fromList [("x", E.ExactValue 2), ("y", E.ExactValue 3)]
                     in Right
                            ( E.evaluateCompiled limits E.ExactRational E.defaultRegistry env c
                                == E.evaluateExpression limits E.ExactRational E.defaultRegistry env e
                            )
                )
             )
           | (i, e) <- zip [0 :: Int ..] expressions
           ]
        ++ [ ( "expression parser pretty " ++ show i
             , right (\e -> E.parseExpression limits (E.prettyExpression e) == Right e) (parse s)
             )
           | (i, s) <- zip [0 :: Int ..] ["x+2*y", "2^3^2", "-x^2", "1//3+x", "let x=2 in x+y", "sin(x)+cos(y)"]
           ]
        ++ [ ( "symbolic finite difference " ++ show i
             , right
                ( \d ->
                    all
                        ( \v ->
                            right
                                id
                                ( do
                                    hi <- at (v + 1e-5) e
                                    lo <- at (v - 1e-5) e
                                    z <- at v d
                                    Right (abs ((hi - lo) / 2e-5 - z) < 1e-5 * (1 + abs z))
                                )
                        )
                        [0.2, 0.8, 1.7]
                )
                (S.differentiate positive "x" e)
             )
           | (i, e) <- zip [0 :: Int ..] smooth
           ]
        ++ [ ( "expression compiled error position " ++ show i
             , right
                id
                ( do
                    e <- parse s
                    c <- E.compileExpression limits e
                    Right
                        ( E.evaluateCompiled limits E.Float64 E.defaultRegistry Map.empty c
                            == E.evaluateExpression limits E.Float64 E.defaultRegistry Map.empty e
                        )
                )
             )
           | (i, s) <-
                zip
                    [0 :: Int ..]
                    ["1/0", "log(-1)", "missing+1", "sin(1,2)", "let x=1/0 in x", "(let x=2 in x)+missing"]
           ]
  where
    expressions =
        [ E.literal (-3 % 7)
        , x
        , E.constant E.Pi
        , E.unary E.Negate (E.literal 2)
        , E.binary E.Add x y
        , E.binary E.Power x (E.literal 3)
        , E.call "sin" [x]
        , E.letIn "x" y (E.binary E.Multiply x x)
        , E.call "f" []
        , E.variable "pi"
        , E.call "pi" [x]
        ]
    smooth =
        [ E.binary E.Power x (E.literal 4)
        , E.call "sin" [x]
        , E.call "cos" [x]
        , E.call "exp" [x]
        , E.call "log" [x]
        , E.call "sqrt" [x]
        , E.call "atan" [x]
        , E.binary E.Power x x
        , E.call "tanh" [x]
        ]
