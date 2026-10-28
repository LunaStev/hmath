-- SPDX-License-Identifier: MPL-2.0

{- | Bounded symbolic real algebra over the common 'Expr' language.

This is a reference CAS with explicit unsupported results, not a decision
procedure for arbitrary elementary expressions. Variables are real; assumptions
are caller assertions, checked for contradictions and retained as proof premises.
Cancellation and log/power rewrites require domain proofs. Generic expansion
and ring collection preserve partial-function domains by refusing to erase an
unproved undefined subexpression. All public transformations validate input and
output against caller limits. Polynomial operations additionally bound degrees
and rational coefficient growth before entering existing exact algorithms.

Integration handles rational polynomials, affine elementary primitives,
polynomial-times-exp/sin/cos by parts, and rational partial fractions with linear
or simple quadratic denominators. Limits and Laurent jets are exact for rational
functions; regular elementary Taylor jets use symbolic derivatives. General
transcendental limits, non-elementary integrals, higher-dimensional eigensystems,
and branch-dependent identities return 'Unsupported'. There are no hidden
numerical guesses or silently discarded branch conditions.
-}
module HMath.Symbolic (
    module HMath.Expression,
    Property (..),
    Assumptions,
    assumptions,
    noAssumptions,
    proves,
    SymbolicOptions (..),
    defaultSymbolicOptions,
    normalize,
    simplify,
    expand,
    collectTerms,
    factorPolynomial,
    PolynomialFactorization (..),
    rationalSimplify,
    trigonometricSimplify,
    logarithmicSimplify,
    substitute,
    Pattern (..),
    matchPattern,
    RewriteRule (..),
    applyRewrite,
    differentiate,
    gradient,
    jacobian,
    hessian,
    integrateBasic,
    integrateByParts,
    integrateSubstitution,
    integrateRational,
    Direction (..),
    LimitResult (..),
    symbolicLimit,
    Series (..),
    taylorSeries,
    maclaurinSeries,
    laurentSeries,
    formalPowerSeries,
    multiplyFormalSeries,
    reciprocalFormalSeries,
    toPolynomial,
    fromPolynomial,
    exactPolynomialRoots,
    numericalPolynomialRoots,
    RelationOp (..),
    Relation (..),
    RelationResult (..),
    simplifyRelation,
    solveLinearInequality,
    LinearSolution (..),
    solveLinearEquations,
    SymbolicMatrix,
    symbolicMatrix,
    matrixExpressions,
    matrixAdd,
    matrixMultiply,
    symbolicDeterminant,
    Guarded (..),
    symbolicEigenvalues,
    numericalSubstitution,
    toLaTeX,
    toMathML,
) where

import Control.Monad (foldM)
import Data.Complex (Complex ((:+)))
import qualified Data.Foldable as Foldable (foldl')
import Data.List (intercalate, nub, sort)
import qualified Data.Map.Strict as Map
import Data.Ratio (denominator, numerator)
import qualified Data.Set as Set
import HMath.Expression
import qualified HMath.Polynomial as P

failure :: ErrorKind -> Expr -> String -> Either ExprError a
failure k e = Left . ExprError k (expressionPosition e)
unsupported :: Expr -> String -> Either ExprError a
unsupported = failure Unsupported

{- | Symbolic domain fact such as real,positive,nonzero,or sign restrictions, used to guard
domain-sensitive identities.
-}
data Property = Real | NonZero | Positive | NonNegative | Integral | Negative | NonPositive
    deriving (Eq, Ord, Show)

{- | Validated variable-property environment. Build through the assumptions API;
noAssumptions proves no additional variable facts.
-}
newtype Assumptions = Assumptions (Map.Map String [Property]) deriving (Eq, Show)

{- | Construct an empty variable-property environment. Simplifications requiring
positivity/nonzero facts remain guarded or unchanged without proof.
-}
noAssumptions :: Assumptions
noAssumptions = Assumptions Map.empty

{- | Only variable assertions are accepted. Positive/negative/zero constraints
are checked for contradictions, including repeated entries for a variable.
-}
assumptions :: [(String, [Property])] -> Either ExprError Assumptions
assumptions entries = do
    let merged = Map.fromListWith (++) entries
    mapM_ check (Map.toList merged)
    Right (Assumptions (Map.map (nub . sort) merged))
  where
    check (name, ps) = do
        validateExpression defaultLimits (variable name)
        if (Positive `elem` ps && (Negative `elem` ps || NonPositive `elem` ps))
            || (Negative `elem` ps && NonNegative `elem` ps)
            || (NonZero `elem` ps && NonNegative `elem` ps && NonPositive `elem` ps)
            then failure DomainFailure (variable name) "contradictory assumptions"
            else Right ()

{- | Expression budgets together with permitted variable assumptions for checked symbolic
operations.
-}
data SymbolicOptions = SymbolicOptions
    { symbolicLimits :: Limits
    -- ^ Expression resource/numeric budgets used by symbolic operations.
    , symbolicAssumptions :: Assumptions
    -- ^ Variable facts permitted when proving domain-sensitive rewrites.
    }
    deriving (Eq, Show)

{- | Default expression budgets with no assumptions; domain-sensitive rules
require their preconditions to be proved before rewriting.
-}
defaultSymbolicOptions :: SymbolicOptions
defaultSymbolicOptions = SymbolicOptions defaultLimits noAssumptions

{- | Given assumptions,requested Property,then Expr, conservatively test whether the fact is
established. False means not proved, not a proof of its negation.
-}
proves :: Assumptions -> Property -> Expr -> Bool
proves a@(Assumptions names) prop e = case expressionNode e of
    Literal q -> case prop of
        Real -> True
        NonZero -> q /= 0
        Positive -> q > 0
        NonNegative -> q >= 0
        Integral -> denominator q == 1
        Negative -> q < 0
        NonPositive -> q <= 0
    Variable n -> prop == Real || any (implies prop) (Map.findWithDefault [] n names)
    Constant _ -> prop `elem` [Real, NonZero, Positive, NonNegative]
    Unary Negate x -> case prop of
        Positive -> proves a Negative x
        Negative -> proves a Positive x
        NonNegative -> proves a NonPositive x
        NonPositive -> proves a NonNegative x
        _ -> proves a prop x
    Binary Multiply x y -> case prop of
        NonZero -> proves a NonZero x && proves a NonZero y
        Positive ->
            (x == y && proves a NonZero x)
                || (proves a Positive x && proves a Positive y)
                || (proves a Negative x && proves a Negative y)
        NonNegative ->
            (x == y && defined a x)
                || (proves a NonNegative x && proves a NonNegative y)
                || (proves a NonPositive x && proves a NonPositive y)
        Integral -> proves a Integral x && proves a Integral y
        Real -> defined a e
        _ -> False
    Binary Add x y -> case prop of
        NonZero -> proves a Positive e || proves a Negative e
        Positive ->
            (proves a Positive x && proves a NonNegative y) || (proves a NonNegative x && proves a Positive y)
        NonNegative -> proves a NonNegative x && proves a NonNegative y
        Integral -> proves a Integral x && proves a Integral y
        Real -> defined a e
        _ -> False
    Binary Divide x y ->
        prop == NonZero && defined a e && proves a NonZero x && proves a NonZero y
            || prop == Real && defined a e
    Binary Power x (Expr _ (Literal q)) ->
        (prop == Real && defined a e)
            || (prop == NonZero && proves a NonZero x && defined a e)
            || ( prop == Positive
                    && ((denominator q == 1 && even (numerator q) && proves a NonZero x) || proves a Positive x)
               )
            || (prop == NonNegative && denominator q == 1 && even (numerator q) && defined a e)
    Call "exp" [x] -> prop `elem` [Real, Positive, NonZero, NonNegative] && defined a x
    Call "abs" [x] ->
        (prop `elem` [Real, NonNegative] && defined a x)
            || (prop `elem` [Positive, NonZero] && proves a NonZero x)
    Call "sqrt" [x] ->
        (prop `elem` [Real, NonNegative] && proves a NonNegative x)
            || (prop `elem` [Positive, NonZero] && proves a Positive x)
    _ -> prop == Real && defined a e
  where
    implies p q =
        p == q || case q of
            Positive -> p `elem` [Real, NonZero, NonNegative]
            Negative -> p `elem` [Real, NonZero, NonPositive]
            Integral -> p == Real
            _ -> False

defined :: Assumptions -> Expr -> Bool
defined a (Expr _ n) = case n of
    Literal _ -> True
    Variable _ -> True
    Constant _ -> True
    Unary _ x -> defined a x
    Binary Divide x y -> defined a x && defined a y && proves a NonZero y
    Binary Power x (Expr _ (Literal q)) -> defined a x && (if denominator q == 1 then q > 0 || proves a NonZero x else proves a Positive x)
    Binary Power x y -> proves a Positive x && defined a y
    Binary _ x y -> defined a x && defined a y
    Call f xs
        | f
            `elem` [ "sin"
                   , "cos"
                   , "exp"
                   , "abs"
                   , "signum"
                   , "floor"
                   , "ceil"
                   , "atan"
                   , "sinh"
                   , "cosh"
                   , "tanh"
                   , "min"
                   , "max"
                   ] ->
            all (defined a) xs && length xs == (if f `elem` ["min", "max"] then 2 else 1)
    Call "log" [x] -> proves a Positive x
    Call "sqrt" [x] -> proves a NonNegative x
    Call _ _ -> False
    Let _ _ _ -> False

checked :: SymbolicOptions -> Expr -> Either ExprError Expr
checked o e = validateExpression (symbolicLimits o) e >> Right e
inputs :: SymbolicOptions -> [Expr] -> Either ExprError ()
inputs o es = validateLimits (symbolicLimits o) >> mapM_ (validateExpression (symbolicLimits o)) es
qvalue :: Expr -> Maybe Rational
qvalue (Expr _ (Literal q)) = Just q
qvalue _ = Nothing
plus, minus, times, divide, power :: Expr -> Expr -> Expr
plus = binary Add
minus = binary Subtract
times = binary Multiply
divide = binary Divide
power = binary Power
neg :: Expr -> Expr
neg e = case qvalue e of Just q -> literal (-q); Nothing -> unary Negate e

{- | Bottom-up folding and conservative canonical ring collection. It never
rewrites x/x or removes an unproved partial function from a zero product.
-}
normalize :: SymbolicOptions -> Expr -> Either ExprError Expr
normalize = simplify

{- | Given SymbolicOptions then Expr, simplify within its resource limits and supplied
assumptions, preserving domain-sensitive conditions. Return ExprError for
invalid/budget-exceeding input/output.
-}
simplify :: SymbolicOptions -> Expr -> Either ExprError Expr
simplify o e = inputs o [e] >> go e >>= checked o
  where
    a = symbolicAssumptions o
    go (Expr p n) = do
        result <- case n of
            Unary Negate x -> do
                u <- go x
                Right (case expressionNode u of Literal q -> literal (-q); Unary Negate y -> y; _ -> neg u)
            Binary op x y -> do
                u <- go x
                v <- go y
                foldNode p op u v
            Call f xs -> do ys <- mapM go xs; Right (functionFold f ys)
            Let name x body -> do
                u <- go x
                v <- go body
                if defined a u
                    then substitute (symbolicLimits o) [(name, u)] v >>= go
                    else Right (Expr p (Let name u v))
            _ -> Right (Expr p n)
        checked o result
    foldNode p op u v = case (qvalue u, qvalue v) of
        (Just _, Just _) -> case evaluateExpression
            (symbolicLimits o)
            ExactRational
            defaultRegistry
            Map.empty
            (Expr p (Binary op u v)) of
            Right (ExactValue q) -> Right (literal q)
            _ -> fallback op u v
        _ -> fallback op u v
    fallback op u v = Right $ case op of
        Add
            | qvalue u == Just 0 -> v
            | qvalue v == Just 0 -> u
            | defined a u && defined a v -> collect (plus u v)
        Subtract
            | qvalue v == Just 0 -> u
            | u == v && defined a u -> literal 0
            | defined a u && defined a v -> collect (minus u v)
        Multiply
            | qvalue u == Just 1 -> v
            | qvalue v == Just 1 -> u
            | qvalue u == Just 0 && defined a v -> literal 0
            | qvalue v == Just 0 && defined a u -> literal 0
            | qvalue u == Just (-1) -> neg v
            | qvalue v == Just (-1) -> neg u
            | defined a u && defined a v -> productCanonical u v
        Divide
            | qvalue v == Just 1 -> u
            | u == v && proves a NonZero u -> literal 1
            | qvalue u == Just 0 && proves a NonZero v -> literal 0
        Power
            | qvalue v == Just 1 -> u
            | qvalue v == Just 0 && proves a NonZero u -> literal 1
        _ -> binary op u v
    functionFold f xs = case (f, xs) of
        ("sin", [x]) | qvalue x == Just 0 -> literal 0
        ("cos", [x]) | qvalue x == Just 0 -> literal 1
        ("exp", [x]) | qvalue x == Just 0 -> literal 1
        ("log", [x]) | qvalue x == Just 1 -> literal 0
        ("log", [Expr _ (Call "exp" [x])]) | defined a x -> x
        ("exp", [Expr _ (Call "log" [x])]) | proves a Positive x -> x
        ("abs", [x]) | proves a NonNegative x -> x
        ("abs", [x]) | proves a NonPositive x -> neg x
        ("sqrt", [x]) -> case evaluateExpression (symbolicLimits o) ExactRational defaultRegistry Map.empty (call f xs) of
            Right (ExactValue q) -> literal q
            _ -> call "sqrt" [x]
        _ -> call f xs
    collect expr = assemble (Map.toAscList (terms expr))
    terms (Expr _ (Binary Add x y)) = Map.unionWith (+) (terms x) (terms y)
    terms (Expr _ (Binary Subtract x y)) = Map.unionWith (+) (terms x) (Map.map negate (terms y))
    terms (Expr _ (Unary Negate x)) = Map.map negate (terms x)
    terms x = let (c, body) = coefficient x in Map.singleton body c
    coefficient x = let (q, fs) = productParts x in (q, productBody fs)
    productParts x = case expressionNode x of
        Literal q -> (q, [])
        Unary Negate y -> let (q, fs) = productParts y in (-q, fs)
        Binary Multiply u v -> let (q, fs) = productParts u; (r, gs) = productParts v in (q * r, fs ++ gs)
        _ -> (1, [x])
    productBody fs = case sort fs of [] -> literal 1; y : ys -> Foldable.foldl' times y ys
    productCanonical u v =
        let (q, fs) = productParts (times u v); body = productBody fs
         in if null fs
                then literal q
                else if q == 1 then body else if q == (-1) then neg body else times (literal q) body
    assemble entries = case map term (filter ((/= 0) . snd) entries) of
        [] -> literal 0
        x : xs -> Foldable.foldl' plus x xs
    term (x, q)
        | x == literal 1 = literal q
        | q == 1 = x
        | q == (-1) = neg x
        | otherwise = times (literal q) x

{- | Alias of simplify, combining supported like terms under the same assumption and budget
checks.
-}
collectTerms :: SymbolicOptions -> Expr -> Either ExprError Expr
collectTerms = simplify

{- | Distribute products over sums and nonnegative integer powers <=32, with a
checked output size at every convolution. Other powers remain symbolic.
-}
expand :: SymbolicOptions -> Expr -> Either ExprError Expr
expand o e = inputs o [e] >> go e >>= simplify o
  where
    go x@(Expr _ n) = case n of
        Binary Add a b -> join Add a b
        Binary Subtract a b -> join Subtract a b
        Binary Multiply a b -> do u <- go a; v <- go b; distribute u v
        Binary Power a (Expr _ (Literal k)) | denominator k == 1 && k >= 1 && k <= 32 -> do
            u <- go a
            foldM (\acc _ -> distribute acc u) (literal 1) [1 .. numerator k]
        Binary op a b -> join op a b
        Unary op a -> go a >>= checked o . unary op
        Call name xs -> mapM go xs >>= checked o . call name
        Let binding a b -> do u <- go a; v <- go b; checked o (letIn binding u v)
        _ -> Right x
    join op a b = do u <- go a; v <- go b; checked o (binary op u v)
    distribute (Expr _ (Binary Add a b)) c = do x <- distribute a c; y <- distribute b c; checked o (plus x y)
    distribute (Expr _ (Binary Subtract a b)) c = do x <- distribute a c; y <- distribute b c; checked o (minus x y)
    distribute a (Expr _ (Binary Add b c)) = do x <- distribute a b; y <- distribute a c; checked o (plus x y)
    distribute a (Expr _ (Binary Subtract b c)) = do x <- distribute a b; y <- distribute a c; checked o (minus x y)
    distribute a b = checked o (times a b)

{- | Alpha-renaming makes simultaneous substitution capture-safe. Replacement
expressions are inserted once; substitution does not recurse into them.
-}
substitute :: Limits -> [(String, Expr)] -> Expr -> Either ExprError Expr
substitute limits replacements expression = do
    validateExpression limits expression
    if length (take (maximumNodes limits + 1) replacements) > maximumNodes limits
        then failure MemoryLimit expression "substitution table limit"
        else Right ()
    mapM_
        (\(n, e) -> validateExpression limits (variable n) >> validateExpression limits e)
        replacements
    go (Map.fromList replacements) expression >>= \e -> validateExpression limits e >> Right e
  where
    go env e@(Expr p node) = case node of
        Variable n -> Right (Map.findWithDefault e n env)
        Unary op a -> Expr p . Unary op <$> go env a
        Binary op a b -> do x <- go env a; y <- go env b; bounded (Expr p (Binary op x y))
        Call name xs -> mapM (go env) xs >>= bounded . Expr p . Call name
        Let n a body -> do
            x <- go env a
            let active = Map.delete n env
                inserted = Set.unions (map (Set.fromList . freeVariables) (Map.elems active))
            if Set.member n inserted
                then do
                    let occupied = Set.unions [inserted, Set.fromList (allNames body), Map.keysSet active]
                        fresh = freshName occupied n (0 :: Int)
                    renamed <- go (Map.singleton n (variable fresh)) body
                    y <- go active renamed
                    bounded (Expr p (Let fresh x y))
                else do y <- go active body; bounded (Expr p (Let n x y))
        _ -> Right e
    bounded e = validateExpression limits e >> Right e
    freshName occupied base i =
        let n = base ++ "_" ++ show i
         in if Set.member n occupied then freshName occupied base (i + 1) else n
    allNames (Expr _ node) = case node of
        Variable n -> [n]
        Unary _ a -> allNames a
        Binary _ a b -> allNames a ++ allNames b
        Call n xs -> n : concatMap allNames xs
        Let n a b -> n : allNames a ++ allNames b
        _ -> []

{- | Symbolic rewrite pattern with literal/variable/operator/call structure and binding
placeholders.
-}
data Pattern
    = Any String
    | Exactly Expr
    | UnaryPattern UnaryOp Pattern
    | BinaryPattern BinaryOp Pattern Pattern
    | CallPattern String [Pattern]
    deriving (Eq, Show)

-- | Repeated wildcard names must match structurally identical subtrees.
matchPattern :: Limits -> Pattern -> Expr -> Either ExprError (Maybe [(String, Expr)])
matchPattern limits pat expression = do
    validateExpression limits expression
    (_, result) <- go 1 (maximumSteps limits) Map.empty pat expression
    Right (Map.toAscList <$> result)
  where
    go d fuel env patternNode expr
        | fuel <= 0 = failure StepLimit expr "pattern matching budget"
        | d > maximumDepth limits = failure DepthLimit expr "pattern matching depth"
        | otherwise = case patternNode of
            Any name -> do
                validateExpression limits (variable name)
                Right
                    ( fuel - 1
                    , case Map.lookup name env of
                        Nothing -> Just (Map.insert name expr env)
                        Just x -> if x == expr then Just env else Nothing
                    )
            Exactly expected ->
                validateExpression limits expected
                    >> Right (fuel - 1, if expected == expr then Just env else Nothing)
            UnaryPattern op a -> case expressionNode expr of
                Unary op1 x | op == op1 -> go (d + 1) (fuel - 1) env a x
                _ -> Right (fuel - 1, Nothing)
            BinaryPattern op a b -> case expressionNode expr of
                Binary op1 x y | op == op1 -> do
                    (remaining, first) <- go (d + 1) (fuel - 1) env a x
                    case first of { Nothing -> Right (remaining, Nothing); Just next -> go (d + 1) remaining next b y }
                _ -> Right (fuel - 1, Nothing)
            CallPattern name ps -> case expressionNode expr of
                Call name1 xs
                    | name == name1 && length (take (maximumNodes limits + 1) ps) == length xs ->
                        foldM (step (d + 1)) (fuel - 1, Just env) (zip ps xs)
                _ -> Right (fuel - 1, Nothing)
    step _ (fuel, Nothing) _ = Right (fuel, Nothing)
    step d (fuel, Just env) (p, e) = go d fuel env p e

{- | Pattern,replacement expression,and property requirements needed for a valid bounded
symbolic rewrite.
-}
data RewriteRule = RewriteRule
    { rewritePattern :: Pattern
    -- ^ Pattern to match before applying this rewrite rule.
    , rewriteReplacement :: Expr
    -- ^ Replacement expression, with matched bindings substituted.
    , rewriteRequirements :: [(String, Property)]
    -- ^ Variable properties required to justify the rewrite.
    }
    deriving (Eq, Show)

{- | Apply one caller-supplied rule at the root only. Rules are trusted algebraic
assertions; requirements are checked against the matched expressions.
-}
applyRewrite :: SymbolicOptions -> RewriteRule -> Expr -> Either ExprError Expr
applyRewrite o rule e = do
    result <- matchPattern (symbolicLimits o) (rewritePattern rule) e
    case result of
        Nothing -> Right e
        Just bindings ->
            if all
                (\(n, p) -> maybe False (proves (symbolicAssumptions o) p) (lookup n bindings))
                (rewriteRequirements rule)
                then substitute (symbolicLimits o) bindings (rewriteReplacement rule)
                else failure DomainFailure e "rewrite assumptions are not established"

{- | Differentiate supported elementary real functions. Noninteger powers and
logarithms require a positive argument; abs requires a nonzero argument.
-}
differentiate :: SymbolicOptions -> String -> Expr -> Either ExprError Expr
differentiate o name expression = do
    inputs o [variable name, expression]
    go expression >>= simplify o
  where
    a = symbolicAssumptions o
    go e@(Expr _ node) = do
        result <- case node of
            Literal _ -> Right (literal 0)
            Constant _ -> Right (literal 0)
            Variable n -> Right (literal (if n == name then 1 else 0))
            Unary Negate x -> neg <$> go x
            Binary Add x y -> plus <$> go x <*> go y
            Binary Subtract x y -> minus <$> go x <*> go y
            Binary Multiply x y -> do dx <- go x; dy <- go y; Right (plus (times dx y) (times x dy))
            Binary Divide x y -> do dx <- go x; dy <- go y; Right (divide (minus (times dx y) (times x dy)) (power y (literal 2)))
            Binary Power x (Expr _ (Literal n)) | denominator n == 1 || proves a Positive x -> do
                dx <- go x
                if n == 0
                    then
                        if proves a NonZero x then Right (literal 0) else unsupported e "zero power requires nonzero base"
                    else if n == 1 then Right dx else Right (times (times (literal n) (power x (literal (n - 1)))) dx)
            Binary Power x y | proves a Positive x -> do
                dx <- go x
                dy <- go y
                Right (times e (plus (times dy (call "log" [x])) (divide (times y dx) x)))
            Call f [x] -> do
                dx <- go x
                outer <- case f of
                    "sin" -> Right (call "cos" [x])
                    "cos" -> Right (neg (call "sin" [x]))
                    "tan" -> Right (divide (literal 1) (power (call "cos" [x]) (literal 2)))
                    "exp" -> Right e
                    "log" | proves a Positive x -> Right (divide (literal 1) x)
                    "sqrt" | proves a Positive x -> Right (divide (literal 1) (times (literal 2) e))
                    "abs" | proves a NonZero x -> Right (call "signum" [x])
                    "atan" -> Right (divide (literal 1) (plus (literal 1) (power x (literal 2))))
                    "sinh" -> Right (call "cosh" [x])
                    "cosh" -> Right (call "sinh" [x])
                    "tanh" -> Right (minus (literal 1) (power e (literal 2)))
                    _ -> unsupported e "unsupported derivative or missing domain assumption"
                Right (times outer dx)
            Let n x body | defined a x -> substitute (symbolicLimits o) [(n, x)] body >>= go
            Let _ _ _ -> unsupported e "derivative of strict let requires a defined initializer"
            _ -> unsupported e "unsupported symbolic derivative"
        checked o result

{- | Given symbolic options,ordered variable names,then scalar expression, return symbolic
partial derivatives in that order. At most 32 variables are supported;
expression/domain/resource failures return ExprError.
-}
gradient :: SymbolicOptions -> [String] -> Expr -> Either ExprError [Expr]
gradient o names e = inputs o [e] >> boundedVariables o names >> mapM (\n -> differentiate o n e) names

{- | Given options,ordered variable names,then output-expression list, return one gradient
row per output. Validate variable/expression budgets; failures return ExprError.
-}
jacobian :: SymbolicOptions -> [String] -> [Expr] -> Either ExprError [[Expr]]
jacobian o names es = boundedVariables o names >> boundedExpressions o es >> mapM (gradient o names) es

{- | Given options,ordered variables,then scalar Expr, return derivatives of each gradient
component in the same row/column variable order. Validation/differentiation/resource
failures propagate.
-}
hessian :: SymbolicOptions -> [String] -> Expr -> Either ExprError [[Expr]]
hessian o names e = gradient o names e >>= mapM (gradient o names)

boundedVariables :: SymbolicOptions -> [String] -> Either ExprError ()
boundedVariables o names
    | length (take 33 names) > 32 = failure MemoryLimit (literal 0) "at most 32 symbolic variables"
    | length (nub names) /= length names =
        failure DomainFailure (literal 0) "duplicate symbolic variables"
    | otherwise = inputs o (map variable names)
boundedExpressions :: SymbolicOptions -> [Expr] -> Either ExprError ()
boundedExpressions o es
    | length (take 65 es) > 64 = failure MemoryLimit (literal 0) "at most 64 symbolic outputs"
    | otherwise = inputs o es

-- Polynomial admission checks size/degree/coefficient bits at every operation.

{- | Given options,variable name,then Expr, convert a supported univariate exact Rational
polynomial. Other variables/functions, invalid exponents or resource-limit violations
return ExprError.
-}
toPolynomial :: SymbolicOptions -> String -> Expr -> Either ExprError (P.Polynomial Rational)
toPolynomial o name expression = inputs o [variable name, expression] >> go expression
  where
    go e@(Expr _ node) = case node of
        Literal q -> check (P.polynomial [q])
        Variable n | n == name -> check (P.polynomial [0, 1])
        Unary Negate x -> go x >>= check . P.scalePolynomial (-1)
        Binary Add x y -> combine P.addPolynomial x y
        Binary Subtract x y -> combine P.subtractPolynomial x y
        Binary Multiply x y -> combine P.multiplyPolynomial x y
        Binary Divide x (Expr _ (Literal q)) | q /= 0 -> go x >>= check . P.scalePolynomial (recip q)
        Binary Power x (Expr _ (Literal q)) | denominator q == 1 && q >= 1 && q <= 64 -> do
            p <- go x
            foldM (\acc _ -> check (P.multiplyPolynomial acc p)) (P.polynomial [1]) [1 .. numerator q]
        _ -> unsupported e "expression is not an admitted rational polynomial"
    combine f x y = do
        a <- go x
        b <- go y
        -- Multiplication cannot allocate more than 129 coefficients.
        check (f a b)
    check p
        | maybe 0 id (P.polynomialDegree p) > 64 =
            failure MemoryLimit expression "polynomial degree limit 64"
        | otherwise =
            mapM_ (\q -> validateExpression (symbolicLimits o) (literal q)) (P.coefficients p) >> Right p

{- | Given variable name then exact Rational Polynomial, build an Expr in Horner form. This
pure builder does not itself validate SymbolicOptions limits.
-}
fromPolynomial :: String -> P.Polynomial Rational -> Expr
fromPolynomial name p = foldr (\a acc -> plus (literal a) (times (variable name) acc)) (literal 0) (P.coefficients p)

{- | Exact leading coefficient and symbolic factor/multiplicity pairs; unfactored remainder
behavior follows the factorization function.
-}
data PolynomialFactorization = PolynomialFactorization
    { factorLeading :: Rational
    -- ^ Exact scalar leading factor outside the polynomial factors.
    , factorTerms :: [(Expr, Int)]
    -- ^ Symbolic factors paired with positive multiplicities.
    }
    deriving (Eq, Show)

-- | Exact factorization over Q via the existing bounded Kronecker algorithm.
factorPolynomial :: SymbolicOptions -> String -> Expr -> Either ExprError PolynomialFactorization
factorPolynomial o name e = do
    p <- toPolynomial o name e
    (c, fs) <-
        mathResult e (P.factorRationalPolynomial (min 100000 (maximumSteps (symbolicLimits o))) p)
    terms <- mapM (\(q, k) -> do x <- simplify o (fromPolynomial name q); Right (x, k)) fs
    Right (PolynomialFactorization c terms)

mathResult :: (Show e) => Expr -> Either e a -> Either ExprError a
mathResult e = either (unsupported e . show) Right

{- | Cancel a rational quotient only when its original denominator is proved
nonzero; this preserves holes that ordinary field cancellation would erase.
-}
rationalSimplify :: SymbolicOptions -> String -> Expr -> Either ExprError Expr
rationalSimplify o name e = case expressionNode e of
    Binary Divide n d | proves (symbolicAssumptions o) NonZero d -> do
        p <- toPolynomial o name n
        q <- toPolynomial o name d
        r <- mathResult e (P.rationalFunction p q)
        simplify
            o
            (divide (fromPolynomial name (P.rationalNumerator r)) (fromPolynomial name (P.rationalDenominator r)))
    _ -> simplify o e

{- | Given options then Expr, apply supported trigonometric identities such as matching
sin-squared plus cos-squared terms, after input validation. This is a bounded rule set,
not a general identity prover.
-}
trigonometricSimplify :: SymbolicOptions -> Expr -> Either ExprError Expr
trigonometricSimplify o e = do
    inputs o [e]
    let squared name x = case expressionNode x of
            Binary Power (Expr _ (Call n [a])) (Expr _ (Literal 2)) | name == n -> Just a
            _ -> Nothing
        identity x y = case (squared "sin" x, squared "cos" y) of
            (Just a, Just b) -> a == b && defined (symbolicAssumptions o) a
            _ -> False
    case expressionNode e of
        Binary Add a b | identity a b || identity b a -> Right (literal 1)
        _ -> simplify o e

{- | Given options then Expr, apply log product/quotient/power rules only when the supplied
assumptions establish required real-domain facts. Unproved transformations are left
unchanged; budget errors propagate.
-}
logarithmicSimplify :: SymbolicOptions -> Expr -> Either ExprError Expr
logarithmicSimplify o e = do
    inputs o [e]
    case expressionNode e of
        Call "log" [Expr _ (Binary Multiply a b)]
            | all (proves (symbolicAssumptions o) Positive) [a, b] ->
                simplify o (plus (call "log" [a]) (call "log" [b]))
        _ -> simplify o e

{- | Polynomial primitives and affine exp/sin/cos and reciprocal powers. The
logarithmic primitive log(abs x) has the original nonzero domain.
-}
integrateBasic :: SymbolicOptions -> String -> Expr -> Either ExprError Expr
integrateBasic o name expression = do
    inputs o [variable name, expression]
    primitive expression >>= simplify o
  where
    x = variable name
    primitive e = case toPolynomial o name e of
        Right p -> Right (fromPolynomial name (P.integratePolynomial 0 p))
        Left _ -> case expressionNode e of
            Binary Add a b -> plus <$> primitive a <*> primitive b
            Binary Subtract a b -> minus <$> primitive a <*> primitive b
            Unary Negate a -> neg <$> primitive a
            Binary Multiply a b | name `notElem` freeVariables a -> times a <$> primitive b
            Binary Multiply a b | name `notElem` freeVariables b -> (`times` b) <$> primitive a
            Binary Divide (Expr _ (Literal c)) a -> reciprocalPrimitive c a
            Binary Power a (Expr _ (Literal q)) -> do
                slope <- affineSlope a
                if q == (-1)
                    then Right (divide (call "log" [call "abs" [a]]) (literal slope))
                    else
                        if denominator q == 1 || proves (symbolicAssumptions o) Positive a
                            then Right (divide (power a (literal (q + 1))) (literal (slope * (q + 1))))
                            else unsupported e "fractional power primitive needs positive base"
            Call f [a] | f `elem` ["exp", "sin", "cos"] -> do
                slope <- affineSlope a
                Right
                    (divide (case f of "exp" -> e; "sin" -> neg (call "cos" [a]); _ -> call "sin" [a]) (literal slope))
            _
                | name `notElem` freeVariables e && defined (symbolicAssumptions o) e -> Right (times e x)
                | otherwise -> unsupported e "no supported elementary primitive"
    reciprocalPrimitive c a = do slope <- affineSlope a; Right (times (literal (c / slope)) (call "log" [call "abs" [a]]))
    affineSlope a = do
        p <- toPolynomial o name a
        case P.coefficients p of
            [_, m] | m /= 0 -> Right m
            _ -> unsupported a "primitive requires nonconstant affine argument"

{- | Integrate a supplied u*dv by recursively reducing polynomial degree when
v is an affine exponential/sine/cosine primitive. Degree is capped at 16.
-}
integrateByParts :: SymbolicOptions -> String -> Expr -> Expr -> Either ExprError Expr
integrateByParts o name u dv = do
    p <- toPolynomial o name u
    if maybe 0 id (P.polynomialDegree p) > 16
        then failure MemoryLimit u "integration-by-parts degree limit 16"
        else parts (0 :: Int) u dv >>= simplify o
  where
    parts n a b
        | n > 20 = failure StepLimit a "integration-by-parts recursion limit"
        | otherwise = do
            v <- integrateBasic o name b
            du <- differentiate o name a
            if qvalue du == Just 0
                then checked o (times a v)
                else do
                    residual <- case integrateBasic o name (times du v) of
                        Right r -> Right r
                        Left _ -> case expressionNode v of
                            Binary Divide g (Expr _ (Literal c)) -> divide <$> parts (n + 1) du g <*> pure (literal c)
                            Unary Negate g -> neg <$> parts (n + 1) du g
                            _ -> parts (n + 1) du v
                    checked o (minus (times a v) residual)

{- | Verified substitution: callers supply an outer expression in a fresh
variable t; the integrand must simplify to outer(inner)*inner'.
-}
integrateSubstitution ::
    SymbolicOptions -> String -> String -> Expr -> Expr -> Expr -> Either ExprError Expr
integrateSubstitution o name temporary inner outer integrand = do
    if name == temporary || temporary `elem` freeVariables inner
        then failure DomainFailure inner "substitution variable must be fresh"
        else Right ()
    d <- differentiate o name inner
    composed <- substitute (symbolicLimits o) [(temporary, inner)] outer
    difference <- expand o (minus integrand (times composed d)) >>= simplify o
    if qvalue difference /= Just 0
        then unsupported integrand "integrand does not match the supplied substitution"
        else do
            primitive <- integrateBasic o temporary outer
            substitute (symbolicLimits o) [(temporary, inner)] primitive >>= simplify o

{- | Exact partial fractions; supports all repeated linear poles and simple
irreducible quadratic factors. Unsupported higher quadratic powers are explicit.
-}
integrateRational :: SymbolicOptions -> String -> Expr -> Expr -> Either ExprError Expr
integrateRational o name numeratorExpr denominatorExpr = do
    p <- toPolynomial o name numeratorExpr
    q <- toPolynomial o name denominatorExpr
    rf <- mathResult denominatorExpr (P.rationalFunction p q)
    (whole, fs) <-
        mathResult denominatorExpr (P.partialFractions (min 100000 (maximumSteps (symbolicLimits o))) rf)
    terms <- mapM term fs
    simplify o (Foldable.foldl' plus (fromPolynomial name (P.integratePolynomial 0 whole)) terms)
  where
    x = variable name
    term (n, d, k) = case (P.coefficients n, P.coefficients d) of
        ([c], [b, 1]) ->
            let linear = plus x (literal b)
             in Right
                    ( if k == 1
                        then times (literal c) (call "log" [call "abs" [linear]])
                        else times (literal (c / fromIntegral (1 - k))) (power linear (literal (fromIntegral (1 - k))))
                    )
        (coeff, [c, b, 1]) | k == 1 && b * b < 4 * c -> do
            let a = case coeff of _ : z : _ -> z; _ -> 0
                b0 = case coeff of z : _ -> z; _ -> 0
                disc = literal (4 * c - b * b)
                root = call "sqrt" [disc]
                quadratic = fromPolynomial name d
                logTerm = times (literal (a / 2)) (call "log" [quadratic])
                atanTerm =
                    times
                        (divide (literal (2 * b0 - a * b)) root)
                        (call "atan" [divide (plus (times (literal 2) x) (literal b)) root])
            checked o (plus logTerm atanTerm)
        _ ->
            unsupported
                denominatorExpr
                "partial fraction primitive requires linear or simple positive quadratic denominator"

-- | Limit approach direction: from left,from right,or two-sided.
data Direction = FromLeft | FromRight | TwoSided deriving (Eq, Show)

{- | Symbolic finite/infinite limit classification,including an explicit does-not-exist or
unresolved result.
-}
data LimitResult = FiniteLimit Rational | PositiveInfinity | NegativeInfinity | DoesNotExist
    deriving (Eq, Show)

{- | Exact finite-point rational limits by root multiplicity. Non-rational
transcendental limits are explicitly unsupported.
-}
symbolicLimit ::
    SymbolicOptions -> String -> Rational -> Direction -> Expr -> Either ExprError LimitResult
symbolicLimit o name center direction e = do
    inputs o [e, literal center]
    (n, d) <- rationalPolynomials o name e
    let (kn, an) = leadingAt center n; (kd, ad) = leadingAt center d
    if ad == 0
        then failure DomainFailure e "identically zero denominator"
        else
            if an == 0 || kn > kd
                then finite 0
                else
                    if kn == kd
                        then finite (an / ad)
                        else
                            let pole = kd - kn
                                signRight = signum (an / ad)
                                signed s = if s > 0 then PositiveInfinity else NegativeInfinity
                             in Right
                                    ( case direction of
                                        FromRight -> signed signRight
                                        FromLeft -> signed (if odd pole then -signRight else signRight)
                                        TwoSided -> if odd pole then DoesNotExist else signed signRight
                                    )
  where
    finite q = inputs o [literal q] >> Right (FiniteLimit q)

rationalPolynomials ::
    SymbolicOptions -> String -> Expr -> Either ExprError (P.Polynomial Rational, P.Polynomial Rational)
rationalPolynomials o name e = case expressionNode e of
    Binary Divide n d -> (,) <$> toPolynomial o name n <*> toPolynomial o name d
    _ -> do p <- toPolynomial o name e; Right (p, P.polynomial [1])
leadingAt :: Rational -> P.Polynomial Rational -> (Int, Rational)
leadingAt center p = go 0 p
  where
    go k q
        | null (P.coefficients q) = (k, 0)
        | value /= 0 = (k, value)
        | otherwise = go (k + 1) (P.differentiatePolynomial q)
      where
        value = P.evaluatePolynomial q center / fromInteger (product [1 .. toInteger k])

{- | Finite symbolic Taylor/Laurent coefficient list with exact center and starting power;
no analytic convergence is implied by storage alone.
-}
data Series = Series
    { seriesCenter :: Rational
    -- ^ Exact Rational expansion center.
    , seriesMinimumPower :: Int
    -- ^ Power corresponding to the first coefficient, including negative powers for Laurent series.
    , seriesTerms :: [Expr]
    -- ^ Coefficient expressions ordered from seriesMinimumPower upward.
    }
    deriving (Eq, Show)

{- | Truncated Taylor coefficients f^(k)(c)/k!, order 0..20. Missing regularity
assumptions or a pole produce an error rather than a fictitious Taylor jet.
-}
taylorSeries :: SymbolicOptions -> String -> Rational -> Int -> Expr -> Either ExprError Series
taylorSeries o name center order e = do
    seriesOrder e order
    inputs o [e, literal center]
    coefficients <- go 0 1 e
    Right (Series center 0 coefficients)
  where
    go k factorial current = do
        value <- substitute (symbolicLimits o) [(name, literal center)] current >>= simplify o
        if not (defined noAssumptions value)
            then unsupported value "Taylor coefficient is singular or domain unproved"
            else Right ()
        c <- simplify o (divide value (literal (fromInteger factorial)))
        if k == order
            then Right [c]
            else do
                next <- differentiate o name current
                more <- go (k + 1) (factorial * toInteger (k + 1)) next
                Right (c : more)

{- | Given options,variable name,order,then Expr, compute the Taylor series centered at zero
via taylorSeries. Unsupported symbolic derivatives or exceeded order/resource bounds
return ExprError.
-}
maclaurinSeries :: SymbolicOptions -> String -> Int -> Expr -> Either ExprError Series
maclaurinSeries o name = taylorSeries o name 0

{- | Rational Laurent coefficients at a rational center, from the lowest power
through that power+order. Exact finite jets reuse HMath.Polynomial division.
-}
laurentSeries :: SymbolicOptions -> String -> Rational -> Int -> Expr -> Either ExprError Series
laurentSeries o name center order e = do
    seriesOrder e order
    inputs o [e, literal center]
    (p, q) <- rationalPolynomials o name e
    let shift = P.polynomial [center, 1]
        as = P.coefficients (P.composePolynomial p shift)
        bs = P.coefficients (P.composePolynomial q shift)
        na = length (takeWhile (== 0) as)
        nb = length (takeWhile (== 0) bs)
        pad xs = take (order + 1) (xs ++ repeat 0)
    if null bs
        then failure DomainFailure e "zero Laurent denominator"
        else
            if null as
                then Right (Series center 0 (replicate (order + 1) (literal 0)))
                else do
                    jet <-
                        mathResult e (P.divideSeries (P.powerSeries (pad (drop na as))) (P.powerSeries (pad (drop nb bs))))
                    let coefficients = take (order + 1) (P.seriesCoefficients jet)
                    inputs o (map literal coefficients)
                    Right (Series center (na - nb) (map literal coefficients))

seriesOrder :: Expr -> Int -> Either ExprError ()
seriesOrder e n
    | n < 0 || n > 20 = failure MemoryLimit e "series order must be 0..20"
    | otherwise = Right ()

{- | Given options then Rational coefficient list, construct a finite formal jet with at
most 64 coefficients, subject to expression numeric budgets. No analytic convergence is
claimed.
-}
formalPowerSeries :: SymbolicOptions -> [Rational] -> Either ExprError (P.PowerSeries Rational)
formalPowerSeries o coefficients
    | length (take 65 coefficients) > 64 =
        failure MemoryLimit (literal 0) "formal jet supports at most 64 coefficients"
    | otherwise = inputs o (map literal coefficients) >> Right (P.powerSeries coefficients)

{- | Given options then two formal Rational jets, validate and convolve coefficients under
the 64-coefficient cap. Oversized input/output or numeric-limit failures return
ExprError.
-}
multiplyFormalSeries ::
    SymbolicOptions ->
    P.PowerSeries Rational ->
    P.PowerSeries Rational ->
    Either ExprError (P.PowerSeries Rational)
multiplyFormalSeries o a b = do
    _ <- formalPowerSeries o (P.seriesCoefficients a)
    _ <- formalPowerSeries o (P.seriesCoefficients b)
    formalPowerSeries o (P.seriesCoefficients (P.multiplySeries a b))

{- | Given options then formal Rational series with nonzero constant term, compute its
reciprocal jet. Invalid constant/size or numeric budgets return ExprError.
-}
reciprocalFormalSeries ::
    SymbolicOptions -> P.PowerSeries Rational -> Either ExprError (P.PowerSeries Rational)
reciprocalFormalSeries o a = do
    _ <- formalPowerSeries o (P.seriesCoefficients a)
    result <- mathResult (literal 0) (P.reciprocalSeries a)
    formalPowerSeries o (P.seriesCoefficients result)

{- | Given options,variable name,then polynomial Expr, return rational roots with
multiplicities plus the remaining deflated Expr. Irrational/non-rational roots remain
in the remainder; unsupported conversion or work-budget exhaustion returns ExprError.
-}
exactPolynomialRoots ::
    SymbolicOptions -> String -> Expr -> Either ExprError ([(Rational, Int)], Expr)
exactPolynomialRoots o name e = do
    p <- toPolynomial o name e
    roots <- mathResult e (P.rationalRoots (min 100000 (maximumSteps (symbolicLimits o))) p)
    let deflate q (r, k) =
            Foldable.foldl'
                ( \current _ -> case P.dividePolynomial current (P.polynomial [-r, 1]) of
                    Right (result, _) -> result
                    Left _ -> current
                )
                q
                [1 .. k]
    residual <- simplify o (fromPolynomial name (Foldable.foldl' deflate p roots))
    Right (roots, residual)

-- | Bounded Durand-Kerner roots, degree <=32; nonconvergence is explicit.
numericalPolynomialRoots :: SymbolicOptions -> String -> Expr -> Either ExprError [Complex Double]
numericalPolynomialRoots o name e = do
    p <- toPolynomial o name e
    if maybe 0 id (P.polynomialDegree p) > 32
        then failure MemoryLimit e "numerical root degree limit 32"
        else
            mathResult
                e
                ( P.durandKerner
                    (min 2000 (maximumSteps (symbolicLimits o)))
                    1e-10
                    (P.polynomial [fromRational q :+ 0 | q <- P.coefficients p])
                )

-- | Comparison relation selector: equality,inequality,or ordered less/greater comparisons.
data RelationOp = Equal | NotEqual | Less | LessEqual | Greater | GreaterEqual deriving (Eq, Show)

{- | Symbolic comparison of two expressions; use simplifyRelation to decide or preserve
unresolved conditions.
-}
data Relation = Relation RelationOp Expr Expr deriving (Eq, Show)

-- | Decided truth value or unresolved symbolic relation under the provided assumptions.
data RelationResult = Truth Bool | Unresolved Relation deriving (Eq, Show)

{- | Given options then Relation, simplify both sides and return a Boolean Truth when
decidable, otherwise a symbolic unresolved relation/conditions. Invalid expressions or
resource failures return ExprError.
-}
simplifyRelation :: SymbolicOptions -> Relation -> Either ExprError RelationResult
simplifyRelation o (Relation op a b) = do
    x <- simplify o a
    y <- simplify o b
    case (qvalue x, qvalue y) of
        (Just u, Just v) -> Right (Truth (compareRelation op u v))
        _
            | x == y && defined (symbolicAssumptions o) x ->
                Right (Truth (op `elem` [Equal, LessEqual, GreaterEqual]))
            | otherwise -> Right (Unresolved (Relation op x y))

compareRelation :: (Ord a) => RelationOp -> a -> a -> Bool
compareRelation Equal = (==)
compareRelation NotEqual = (/=)
compareRelation Less = (<)
compareRelation LessEqual = (<=)
compareRelation Greater = (>)
compareRelation GreaterEqual = (>=)

{- | Isolate a single affine variable; multiplying by a negative coefficient
flips the inequality. Equality and zero slopes are handled explicitly.
-}
solveLinearInequality :: SymbolicOptions -> String -> Relation -> Either ExprError RelationResult
solveLinearInequality o name (Relation op a b) = do
    p <- toPolynomial o name (minus a b)
    case P.coefficients p of
        [] -> Right (Truth (compareRelation op (0 :: Rational) 0))
        [c] -> Right (Truth (compareRelation op c 0))
        [c, m] -> do
            bound <- checked o (literal (-c / m))
            Right (Unresolved (Relation (if m < 0 then flipOp op else op) (variable name) bound))
        _ -> unsupported a "inequality must be affine in one variable"
  where
    flipOp Less = Greater
    flipOp LessEqual = GreaterEqual
    flipOp Greater = Less
    flipOp GreaterEqual = LessEqual
    flipOp x = x

{- | Symbolic linear-system outcome distinguishing a determined/parametric solution from
inconsistency or unresolved computation.
-}
data LinearSolution = Inconsistent | ParametricSolution [(String, Expr)] [String]
    deriving (Eq, Show)

{- | Exact rational RREF for at most 16 variables/equations. Free variables keep
their original names; a zero row with nonzero RHS certifies inconsistency.
-}
solveLinearEquations ::
    SymbolicOptions -> [String] -> [(Expr, Expr)] -> Either ExprError LinearSolution
solveLinearEquations o names equations = do
    boundedVariables o names
    if length names > 16 || length (take 17 equations) > 16
        then failure MemoryLimit (literal 0) "linear system limit 16"
        else Right ()
    rows <- mapM row equations
    (reduced, pivots) <- rref 0 0 rows []
    if any (\r -> all (== 0) (take (length names) r) && lastValue r /= 0) reduced
        then Right Inconsistent
        else do
            let free = [i | i <- [0 .. length names - 1], i `notElem` map snd pivots]
            solved <-
                mapM
                    ( \(r, c) -> do
                        let values = reduced !! r
                            expr =
                                Foldable.foldl'
                                    minus
                                    (literal (lastValue values))
                                    [times (literal (values !! j)) (variable (names !! j)) | j <- free, values !! j /= 0]
                        value <- simplify o expr
                        Right (names !! c, value)
                    )
                    pivots
            Right (ParametricSolution solved [names !! i | i <- free])
  where
    lastValue = Foldable.foldl' (\_ x -> x) 0
    row (a, b) = do
        expanded <- expand o (minus a b)
        (c, coeff) <- affine expanded
        let r = [Map.findWithDefault 0 n coeff | n <- names] ++ [-c]
        inputs o (map literal r)
        Right r
    affine e = case expressionNode e of
        Literal q -> Right (q, Map.empty)
        Variable n | n `elem` names -> Right (0, Map.singleton n 1)
        Unary Negate x -> do (c, m) <- affine x; Right (-c, Map.map negate m)
        Binary Add x y -> combine 1 x y
        Binary Subtract x y -> combine (-1) x y
        Binary Multiply (Expr _ (Literal q)) x -> do (c, m) <- affine x; Right (q * c, Map.map (q *) m)
        Binary Multiply x (Expr _ (Literal q)) -> affine (times (literal q) x)
        Binary Divide x (Expr _ (Literal q)) | q /= 0 -> affine (times (literal (recip q)) x)
        _ -> unsupported e "linear equations require rational affine expressions"
    combine sign x y = do
        (c, m) <- affine x
        (d, n) <- affine y
        Right (c + sign * d, Map.unionWith (+) m (Map.map (sign *) n))
    rref r c rows pivots
        | r >= length rows || c >= length names = Right (rows, pivots)
        | otherwise = case [i | i <- [r .. length rows - 1], rows !! i !! c /= 0] of
            [] -> rref r (c + 1) rows pivots
            i : _ -> do
                let pivot = map (/ (rows !! i !! c)) (rows !! i)
                    swapped =
                        [if j == r then rows !! i else if j == i then rows !! r else value | (j, value) <- zip [0 ..] rows]
                    next =
                        [ if j == r then pivot else zipWith (-) value (map ((value !! c) *) pivot)
                        | (j, value) <- zip [0 ..] swapped
                        ]
                inputs o (map literal (concat next))
                rref (r + 1) (c + 1) next (pivots ++ [(r, c)])

-- | Checked bounded rectangular expression matrix, constructed with symbolicMatrix.
newtype SymbolicMatrix = SymbolicMatrix [[Expr]] deriving (Eq, Show)

{- | Given options then nonempty rectangular Expr rows, construct a checked symbolic matrix
bounded to 8-by-8. Empty/ragged/oversized or invalid expressions fail.
-}
symbolicMatrix :: SymbolicOptions -> [[Expr]] -> Either ExprError SymbolicMatrix
symbolicMatrix o rows
    | null rows
        || length (take 9 rows) > 8
        || any ((/= width) . length . take 9) rows
        || width == 0
        || width > 8 =
        failure DomainFailure (literal 0) "symbolic matrix requires rectangular 1..8 dimensions"
    | otherwise = inputs o (concat rows) >> Right (SymbolicMatrix rows)
  where
    width = case rows of r : _ -> length (take 9 r); [] -> 0

-- | Extract row-major symbolic expressions without evaluation or simplification.
matrixExpressions :: SymbolicMatrix -> [[Expr]]
matrixExpressions (SymbolicMatrix rows) = rows

{- | Given options then equally shaped symbolic matrices, add and simplify corresponding
expressions. Shape mismatch or symbolic resource/domain failure returns ExprError.
-}
matrixAdd :: SymbolicOptions -> SymbolicMatrix -> SymbolicMatrix -> Either ExprError SymbolicMatrix
matrixAdd o (SymbolicMatrix a) (SymbolicMatrix b)
    | length a /= length b || map length a /= map length b =
        failure DomainFailure (literal 0) "matrix addition shape mismatch"
    | otherwise = mapM (mapM (simplify o) . uncurry (zipWith plus)) (zip a b) >>= symbolicMatrix o

{- | Given options then compatible symbolic matrices, form simplified dot-product entries.
Inner-dimension mismatch or expression/output limits return ExprError.
-}
matrixMultiply ::
    SymbolicOptions -> SymbolicMatrix -> SymbolicMatrix -> Either ExprError SymbolicMatrix
matrixMultiply o (SymbolicMatrix a) (SymbolicMatrix b)
    | columns a /= length b = failure DomainFailure (literal 0) "matrix multiplication shape mismatch"
    | otherwise =
        mapM
            ( \row ->
                mapM
                    (\j -> simplify o (Foldable.foldl' plus (literal 0) (zipWith times row [r !! j | r <- b])))
                    [0 .. columns b - 1]
            )
            a
            >>= symbolicMatrix o
  where
    columns rows = case rows of r : _ -> length r; [] -> 0

{- | Cofactor determinant, at most 6x6. This bounded reference algorithm permits
arbitrary symbolic entries without assuming nonzero division pivots.
-}
symbolicDeterminant :: SymbolicOptions -> SymbolicMatrix -> Either ExprError Expr
symbolicDeterminant o (SymbolicMatrix rows)
    | length rows > 6 || any ((/= length rows) . length) rows =
        failure DomainFailure (literal 0) "determinant requires square matrix of order <=6"
    | otherwise = det rows >>= simplify o
  where
    det [] = Right (literal 1)
    det [r] = case r of [x] -> Right x; _ -> failure DomainFailure (literal 0) "invalid determinant row"
    det (r : rs) = do
        terms <-
            mapM
                ( \(j, x) -> do
                    sub <- det [take j row ++ drop (j + 1) row | row <- rs]
                    checked o (times (literal (if even j then 1 else -1)) (times x sub))
                )
                (zip [0 ..] r)
        checked o (Foldable.foldl' plus (literal 0) terms)

-- | Value paired with mathematical property conditions required for its unconditional use.
data Guarded a = Guarded
    { guardedValue :: a
    -- ^ Result whose validity depends on requiredConditions.
    , requiredConditions :: [(Expr, Property)]
    -- ^ Expression/property facts that must hold before using guardedValue unconditionally.
    }
    deriving (Eq, Show)

{- | Exact 1x1/2x2 real eigenvalue formulas; an unproved discriminant is returned
as an explicit NonNegative condition. Negative numeric discriminants fail.
-}
symbolicEigenvalues :: SymbolicOptions -> SymbolicMatrix -> Either ExprError (Guarded [Expr])
symbolicEigenvalues o (SymbolicMatrix rows) = case rows of
    [[x]] -> inputs o [x] >> Right (Guarded [x] [])
    [[a, b], [c, d]] -> do
        trace <- simplify o (plus a d)
        disc <- expand o (plus (power (minus a d) (literal 2)) (times (literal 4) (times b c)))
        if maybe False (< 0) (qvalue disc)
            then unsupported disc "complex eigenvalues require a complex symbolic domain"
            else do
                let root = call "sqrt" [disc]
                lo <- simplify o (divide (minus trace root) (literal 2))
                hi <- simplify o (divide (plus trace root) (literal 2))
                Right
                    ( Guarded
                        [lo, hi]
                        (if proves (symbolicAssumptions o) NonNegative disc then [] else [(disc, NonNegative)])
                    )
    _ -> unsupported (literal 0) "symbolic eigenvalues support order 1 or 2"

{- | Given options,precision,bindings list,then Expr, evaluate using the default builtin
registry and symbolic limits. Later duplicate binding names replace earlier ones.
Evaluation/name/domain/resource errors remain ExprError.
-}
numericalSubstitution ::
    SymbolicOptions -> Precision -> [(String, Value)] -> Expr -> Either ExprError Value
numericalSubstitution o mode bindings = evaluateExpression (symbolicLimits o) mode defaultRegistry (Map.fromList bindings)

-- | TeX with escaped identifiers; expressions are never interpreted as raw TeX.
toLaTeX :: Limits -> Expr -> Either ExprError String
toLaTeX limits e = export limits tex e
  where
    tex (Expr _ node) = case node of
        Literal q
            | denominator q == 1 -> show (numerator q)
            | otherwise -> "\\frac{" ++ show (numerator q) ++ "}{" ++ show (denominator q) ++ "}"
        Variable n -> "\\mathrm{" ++ concatMap escape n ++ "}"
        Constant Pi -> "\\pi"
        Constant Euler -> "e"
        Constant Tau -> "2\\pi"
        Unary Negate a -> "-\\left(" ++ tex a ++ "\\right)"
        Binary Divide a b -> "\\frac{" ++ tex a ++ "}{" ++ tex b ++ "}"
        Binary Power a b -> "{\\left(" ++ tex a ++ "\\right)}^{" ++ tex b ++ "}"
        Binary op a b ->
            "\\left(" ++ tex a ++ (if op == Multiply then "\\cdot " else operatorText op) ++ tex b ++ "\\right)"
        Call n xs ->
            "\\operatorname{" ++ concatMap escape n ++ "}\\left(" ++ intercalate "," (map tex xs) ++ "\\right)"
        Let n a b ->
            "\\operatorname{let}\\;\\mathrm{"
                ++ concatMap escape n
                ++ "}="
                ++ tex a
                ++ "\\;\\operatorname{in}\\;"
                ++ tex b
    escape '_' = "\\_"
    escape c = [c]

operatorText :: BinaryOp -> String
operatorText Add = "+"
operatorText Subtract = "-"
operatorText Multiply = "*"
operatorText Divide = "/"
operatorText Power = "^"

-- | Content MathML, including an explicit lambda application for lexical let.
toMathML :: Limits -> Expr -> Either ExprError String
toMathML limits e =
    export limits (\x -> "<math xmlns=\"http://www.w3.org/1998/Math/MathML\">" ++ xml x ++ "</math>") e
  where
    xml (Expr _ node) = case node of
        Literal q
            | denominator q == 1 -> "<cn>" ++ show (numerator q) ++ "</cn>"
            | otherwise ->
                "<cn type=\"rational\">" ++ show (numerator q) ++ "<sep/>" ++ show (denominator q) ++ "</cn>"
        Variable n -> "<ci>" ++ n ++ "</ci>"
        Constant Pi -> "<pi/>"
        Constant Euler -> "<exponentiale/>"
        Constant Tau -> "<apply><times/><cn>2</cn><pi/></apply>"
        Unary Negate a -> "<apply><minus/>" ++ xml a ++ "</apply>"
        Binary op a b -> "<apply><" ++ tag op ++ "/>" ++ xml a ++ xml b ++ "</apply>"
        Call n xs -> "<apply><ci>" ++ n ++ "</ci>" ++ concatMap xml xs ++ "</apply>"
        Let n a b ->
            "<apply><lambda><bvar><ci>" ++ n ++ "</ci></bvar>" ++ xml b ++ "</lambda>" ++ xml a ++ "</apply>"
    tag Add = "plus"
    tag Subtract = "minus"
    tag Multiply = "times"
    tag Divide = "divide"
    tag Power = "power"

export :: Limits -> (Expr -> String) -> Expr -> Either ExprError String
export limits render e = do
    validateExpression limits e
    let text = render e
    if length (take (maximumInputChars limits + 1) text) > maximumInputChars limits
        then failure MemoryLimit e "export character budget"
        else Right text
