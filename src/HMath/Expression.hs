-- SPDX-License-Identifier: MPL-2.0

{- | A pure, bounded real expression language shared with 'HMath.Symbolic'.

Grammar: @let name = expression in expression@; left-associative @+ - * /@;
right-associative @^@; unary @+ -@ binds below powers (@-2^2 = -(2^2)@).
Calls use commas; literals are integers, exact decimal/scientific notation, or
@numerator//denominator@. Constants are @pi@, @e@ and @tau@. Identifiers contain
letters, digits and underscores and start with a letter or underscore.

Values select exact Rational or finite Double arithmetic. Exact mode rejects
transcendental functions and irrational square roots rather than rounding them.
There is no IO, reflection, dynamically supplied Haskell function or code execution.
The registry maps allowed names to a closed set of builtins. Let is strict and
lexically scoped. Expression identity ignores source locations, otherwise it is
structural; algebraic equality is a separate symbolic operation.

Limits cover input characters, AST/payload units, recursion, arithmetic steps and
integer bits. They are conservative work/allocation limits, not operating-system
byte or wall-clock quotas. Intermediate rational sizes are checked before large
arithmetic. Compilation/CSE and cache insertion use the same bounded validator.
Compiler traversal and evaluation have separate fresh budgets; cache hits still
revalidate limits, registry and bindings when evaluated. Only trusted callers
should construct an AST directly; validation rejects malformed names and shapes.
-}
module HMath.Expression (
    SourcePos (..),
    unknownPosition,
    Expr (..),
    ExprNode (..),
    UnaryOp (..),
    BinaryOp (..),
    NamedConstant (..),
    literal,
    variable,
    constant,
    unary,
    binary,
    call,
    letIn,
    Limits (..),
    defaultLimits,
    ExprError (..),
    ErrorKind (..),
    validateLimits,
    validateExpression,
    parseExpression,
    prettyExpression,
    freeVariables,
    Precision (..),
    Value (..),
    Bindings,
    Builtin (..),
    Registry,
    defaultRegistry,
    emptyRegistry,
    registerFunction,
    allowedFunctions,
    typeCheckExpression,
    evaluateExpression,
    evaluateText,
    Compiled,
    compileExpression,
    compiledNodeCount,
    evaluateCompiled,
    optimizeExpression,
    ExpressionCache,
    emptyExpressionCache,
    cachedExpression,
    cacheSize,
    formatScientific,
    formatRadix,
    serializeExpression,
    deserializeExpression,
    expressionHash,
) where

import Control.Monad (foldM)
import Data.Bits (xor)
import Data.Char (isAlpha, isAlphaNum, isDigit, isSpace, ord)
import Data.List (intercalate)
import qualified Data.Map.Strict as Map
import Data.Ratio (denominator, numerator, (%))
import qualified Data.Set as Set
import Data.Word (Word64)
import Numeric (showEFloat, showIntAtBase)

-- | Zero-based offset and one-based line/column. Generated expressions use 0/0/0.
data SourcePos = SourcePos {sourceOffset :: Int, sourceLine :: Int, sourceColumn :: Int}
    deriving (Eq, Ord, Show)

unknownPosition :: SourcePos
unknownPosition = SourcePos 0 0 0

data UnaryOp = Negate deriving (Eq, Ord, Show)
data BinaryOp = Add | Subtract | Multiply | Divide | Power deriving (Eq, Ord, Show)
data NamedConstant = Pi | Euler | Tau deriving (Eq, Ord, Show)
data Expr = Expr {expressionPosition :: SourcePos, expressionNode :: ExprNode} deriving (Show)
data ExprNode
    = Literal Rational
    | Variable String
    | Constant NamedConstant
    | Unary UnaryOp Expr
    | Binary BinaryOp Expr Expr
    | Call String [Expr]
    | Let String Expr Expr
    deriving (Eq, Ord, Show)
instance Eq Expr where Expr _ a == Expr _ b = a == b
instance Ord Expr where compare (Expr _ a) (Expr _ b) = compare a b
literal :: Rational -> Expr
literal = Expr unknownPosition . Literal
variable :: String -> Expr
variable = Expr unknownPosition . Variable
constant :: NamedConstant -> Expr
constant = Expr unknownPosition . Constant
unary :: UnaryOp -> Expr -> Expr
unary op = Expr unknownPosition . Unary op
binary :: BinaryOp -> Expr -> Expr -> Expr
binary op a b = Expr unknownPosition (Binary op a b)
call :: String -> [Expr] -> Expr
call name = Expr unknownPosition . Call name
letIn :: String -> Expr -> Expr -> Expr
letIn name a b = Expr unknownPosition (Let name a b)

data Limits = Limits
    { maximumSteps :: Int
    , maximumDepth :: Int
    , maximumNodes :: Int
    , maximumInputChars :: Int
    , maximumIntegerBits :: Int
    , maximumCacheEntries :: Int
    }
    deriving (Eq, Show)
defaultLimits :: Limits
defaultLimits = Limits 100000 128 20000 100000 1024 64

data ErrorKind
    = SyntaxError
    | UnknownName
    | TypeMismatch
    | DomainFailure
    | NonFinite
    | StepLimit
    | DepthLimit
    | MemoryLimit
    | InvalidLimits
    | Unsupported
    deriving (Eq, Ord, Show)
data ExprError = ExprError {errorKind :: ErrorKind, errorPosition :: SourcePos, errorMessage :: String}
    deriving (Eq, Show)
err :: ErrorKind -> SourcePos -> String -> Either ExprError a
err k p = Left . ExprError k p
validateLimits :: Limits -> Either ExprError ()
validateLimits l
    | or
        [ maximumSteps l < 1
        , maximumSteps l > 10000000
        , maximumDepth l < 1
        , maximumDepth l > 256
        , maximumNodes l < 1
        , maximumNodes l > 100000
        , maximumInputChars l < 1
        , maximumInputChars l > 1000000
        , maximumIntegerBits l < 2
        , maximumIntegerBits l > 8192
        , maximumCacheEntries l < 0
        , maximumCacheEntries l > 1024
        ] =
        err InvalidLimits unknownPosition "limits exceed positive reference implementation bounds"
    | otherwise = Right ()
data Budget = Budget !Int !Int
start :: Limits -> Budget
start l = Budget (maximumSteps l) (maximumNodes l)
charge :: SourcePos -> Int -> Int -> Budget -> Either ExprError Budget
charge p s m (Budget steps nodes)
    | s > steps = err StepLimit p "expression step budget exhausted"
    | m > nodes = err MemoryLimit p "expression allocation/payload budget exhausted"
    | otherwise = Right (Budget (steps - s) (nodes - m))
depth :: Limits -> SourcePos -> Int -> Either ExprError ()
depth l p n
    | n > maximumDepth l = err DepthLimit p "expression recursion budget exhausted"
    | otherwise = Right ()
identifier :: String -> Bool
identifier [] = False
identifier (x : xs) =
    (isAlpha x || x == '_')
        && all (\c -> isAlphaNum c || c == '_') xs
        && (x : xs) `notElem` ["let", "in"]
boundedLength :: Int -> [a] -> Int
boundedLength n = length . take (n + 1)
bits :: Int -> Integer -> Int
bits cap = go 0 . abs
  where
    go n x
        | n > cap || x == 0 = n
        | otherwise = go (n + 1) (x `quot` 2)
checkRational :: Limits -> SourcePos -> Rational -> Either ExprError ()
checkRational l p x
    | denominator x <= 0 = err DomainFailure p "invalid rational denominator"
    | bits cap (numerator x) > cap || bits cap (denominator x) > cap =
        err MemoryLimit p "integer bit budget exhausted"
    | otherwise = Right ()
  where
    cap = maximumIntegerBits l

-- | Validate size before traversing arbitrary user-created trees further.
validateExpression :: Limits -> Expr -> Either ExprError ()
validateExpression l e = validateLimits l >> go 1 (start l) e >> Right ()
  where
    go d b (Expr p node) = do
        depth l p d
        b1 <- charge p 1 1 b
        case node of
            Literal q ->
                checkRational l p q
                    >> charge
                        p
                        0
                        ((bits (maximumIntegerBits l) (numerator q) + bits (maximumIntegerBits l) (denominator q)) `div` 8)
                        b1
            Constant _ -> Right b1
            Variable n -> name p n b1
            Unary _ a -> go (d + 1) b1 a
            Binary _ a c -> go (d + 1) b1 a >>= \b2 -> go (d + 1) b2 c
            Call n xs -> do
                b2 <- name p n b1
                if boundedLength (maximumNodes l) xs > maximumNodes l
                    then err MemoryLimit p "too many arguments"
                    else foldM (go (d + 1)) b2 xs
            Let n a c -> name p n b1 >>= \b2 -> go (d + 1) b2 a >>= \b3 -> go (d + 1) b3 c
    name p n b =
        let k = boundedLength (maximumInputChars l) n
         in if k > maximumInputChars l
                then err MemoryLimit p "identifier too long"
                else if not (identifier n) then err SyntaxError p "invalid identifier" else charge p k k b

-- Lexer retains positions even for end-of-input diagnostics.
data Token = Number Rational | Name String | Punctuation Char | End deriving (Eq, Show)
type LocatedToken = (SourcePos, Token)
advance :: SourcePos -> Char -> SourcePos
advance (SourcePos o r c) x = if x == '\n' then SourcePos (o + 1) (r + 1) 1 else SourcePos (o + 1) r (c + 1)
lexExpression :: Limits -> String -> Either ExprError [LocatedToken]
lexExpression l input = do
    validateLimits l
    if boundedLength (maximumInputChars l) input > maximumInputChars l
        then err MemoryLimit (SourcePos 0 1 1) "input character budget exhausted"
        else go (SourcePos 0 1 1) (start l) input
  where
    go p b [] = charge p 1 1 b >> Right [(p, End)]
    go p b s@(x : xs)
        | isSpace x = charge p 1 0 b >>= \b1 -> go (advance p x) b1 xs
        | isAlpha x || x == '_' =
            let (n, rest) = span (\c -> isAlphaNum c || c == '_') s in emit p b n (Name n) rest
        | isDigit x || (x == '.' && case xs of y : _ -> isDigit y; [] -> False) = do
            (q, raw, rest) <- number p s
            checkRational l p q
            emit p b raw (Number q) rest
        | x `elem` "+-*/^(),=" = emit p b [x] (Punctuation x) xs
        | otherwise = err SyntaxError p "unexpected character"
    emit p b raw t rest = do
        b1 <- charge p (length raw + 1) (length raw + 1) b
        more <- go (foldl advance p raw) b1 rest
        Right ((p, t) : more)
    number p s = do
        let (whole, rest) = span isDigit s
            (fraction, rest1) = case rest of '.' : ys -> let (ds, zs) = span isDigit ys in ('.' : ds, zs); _ -> ("", rest)
            mantissa = whole ++ fraction
            decimalDigits = filter (/= '.') mantissa
            cap = maximumIntegerBits l
            parseDigits ds =
                if length ds > cap `div` 3 + 2
                    then err MemoryLimit p "numeric literal bit budget"
                    else Right (foldl (\a c -> 10 * a + toInteger (ord c - ord '0')) 0 ds)
        a <- parseDigits decimalDigits
        case rest1 of
            '/' : '/' : ys | null fraction -> do
                let (ds, zs) = span isDigit ys
                if null ds
                    then err SyntaxError p "rational denominator required"
                    else do
                        den <- parseDigits ds
                        if den == 0
                            then err DomainFailure p "zero rational literal denominator"
                            else Right (a % den, mantissa ++ "//" ++ ds, zs)
            _ -> do
                (expo, expoText, zs) <- case rest1 of
                    c : ys | c `elem` "eE" -> do
                        let (sign, ys1) = case ys of '-' : tailDigits -> (-1, tailDigits); '+' : tailDigits -> (1, tailDigits); _ -> (1, ys)
                            (ds, z) = span isDigit ys1
                        if null ds
                            then err SyntaxError (foldl advance p mantissa) "scientific exponent required"
                            else do
                                n <- parseDigits ds
                                if n > toInteger cap
                                    then err MemoryLimit p "scientific exponent budget"
                                    else
                                        Right
                                            ( sign * fromInteger n
                                            , c : (case ys of signCharacter : _ | signCharacter `elem` "+-" -> [signCharacter]; _ -> "") ++ ds
                                            , z
                                            )
                    _ -> Right (0, "", rest1)
                let places = if null fraction then 0 else length fraction - 1
                    decimalPower = expo - places
                if abs decimalPower > cap `div` 3
                    then err MemoryLimit p "decimal scale bit budget"
                    else
                        Right
                            ( if decimalPower >= 0 then fromInteger (a * 10 ^ decimalPower) else a % (10 ^ (-decimalPower))
                            , mantissa ++ expoText
                            , zs
                            )

type Parse a = Int -> [LocatedToken] -> Either ExprError (a, [LocatedToken])

{- | Parse with positions and a bounded lexer. Parentheses, calls, unary chains and
right-associative powers all count toward parser recursion.
-}
parseExpression :: Limits -> String -> Either ExprError Expr
parseExpression l source = do
    ts <- lexExpression l source
    (e, rest) <- expression 1 ts
    case rest of
        [(_, End)] -> validateExpression l e >> Right e
        (p, _) : _ -> err SyntaxError p "unexpected trailing token"
        [] -> err SyntaxError unknownPosition "missing end token"
  where
    guarded d ts action = depth l (position ts) d >> action
    expression :: Parse Expr
    expression d ts = guarded d ts $ case ts of
        (p, Name "let") : (_, Name n) : (_, Punctuation '=') : xs | identifier n -> do
            (a, ys) <- expression (d + 1) xs
            case ys of
                (_, Name "in") : zs -> do (b, rest) <- expression (d + 1) zs; Right (Expr p (Let n a b), rest)
                _ -> err SyntaxError (position ys) "expected 'in'"
        (_, Name "let") : _ -> err SyntaxError (position ts) "expected let name = value in body"
        _ -> addParse d ts
    addParse d ts = mulParse (d + 1) ts >>= uncurry (loop d [('+', Add), ('-', Subtract)] (mulParse (d + 1)))
    mulParse d ts = unaryParse (d + 1) ts >>= uncurry (loop d [('*', Multiply), ('/', Divide)] (unaryParse (d + 1)))
    loop d ops next a ts = guarded d ts $ case ts of
        (_, Punctuation c) : xs | Just op <- lookup c ops -> do
            (b, ys) <- next xs
            let e = Expr (expressionPosition a) (Binary op a b)
            loop d ops next e ys
        _ -> Right (a, ts)
    unaryParse d ts = guarded d ts $ case ts of
        (p, Punctuation '-') : xs -> do
            (a, ys) <- unaryParse (d + 1) xs
            let e = case expressionNode a of Literal q -> Expr p (Literal (-q)); _ -> Expr p (Unary Negate a)
            Right (e, ys)
        (_, Punctuation '+') : xs -> unaryParse (d + 1) xs
        _ -> powerParse (d + 1) ts
    powerParse d ts = guarded d ts $ do
        (a, ys) <- atom (d + 1) ts
        case ys of
            (_, Punctuation '^') : zs -> do (b, rest) <- unaryParse (d + 1) zs; Right (Expr (expressionPosition a) (Binary Power a b), rest)
            _ -> Right (a, ys)
    atom d ts = guarded d ts $ case ts of
        (p, Number q) : xs -> Right (Expr p (Literal q), xs)
        (p, Name n) : (_, Punctuation '(') : xs | identifier n -> do
            (args, ys) <- arguments (d + 1) xs
            Right (Expr p (Call n args), ys)
        (p, Name n) : xs
            | identifier n ->
                Right (Expr p (maybe (Variable n) Constant (lookup n [("pi", Pi), ("e", Euler), ("tau", Tau)])), xs)
        (_, Punctuation '(') : xs -> do
            (a, ys) <- expression (d + 1) xs
            case ys of
                (_, Punctuation ')') : zs -> Right (a, zs)
                _ -> err SyntaxError (position ys) "expected ')'"
        _ -> err SyntaxError (position ts) "expected an expression"
    arguments d ts = guarded d ts $ case ts of
        (_, Punctuation ')') : xs -> Right ([], xs)
        _ -> do
            (a, ys) <- expression (d + 1) ts
            case ys of
                (_, Punctuation ')') : zs -> Right ([a], zs)
                (_, Punctuation ',') : zs -> do
                    case zs of
                        (_, Punctuation ')') : _ -> err SyntaxError (position zs) "missing argument"
                        _ -> Right ()
                    (as, rest) <- arguments (d + 1) zs
                    Right (a : as, rest)
                _ -> err SyntaxError (position ys) "expected ',' or ')'"
    position ((p, _) : _) = p
    position [] = unknownPosition

{- | Fully parenthesized, deterministic grammar output. Signed literal folding
during parsing is intentional; serialization additionally preserves raw nodes.
-}
prettyExpression :: Expr -> String
prettyExpression (Expr _ node) = case node of
    Literal q ->
        let text = show (numerator q) ++ if denominator q == 1 then "" else "//" ++ show (denominator q)
         in if q < 0 then "(" ++ text ++ ")" else text
    Variable n -> n
    Constant n -> constantName n
    Unary Negate a -> "(-" ++ prettyExpression a ++ ")"
    Binary op a b -> "(" ++ prettyExpression a ++ operator op ++ prettyExpression b ++ ")"
    Call n xs -> n ++ "(" ++ intercalate "," (map prettyExpression xs) ++ ")"
    Let n a b -> "(let " ++ n ++ "=" ++ prettyExpression a ++ " in " ++ prettyExpression b ++ ")"

constantName :: NamedConstant -> String
constantName Pi = "pi"
constantName Euler = "e"
constantName Tau = "tau"
operator :: BinaryOp -> String
operator Add = "+"
operator Subtract = "-"
operator Multiply = "*"
operator Divide = "/"
operator Power = "^"
freeVariables :: Expr -> [String]
freeVariables = Set.toAscList . go
  where
    go (Expr _ n) = case n of
        Variable s -> Set.singleton s
        Literal _ -> Set.empty
        Constant _ -> Set.empty
        Unary _ a -> go a
        Binary _ a b -> Set.union (go a) (go b)
        Call _ xs -> Set.unions (map go xs)
        Let s a b -> Set.union (go a) (Set.delete s (go b))

data Precision = ExactRational | Float64 deriving (Eq, Ord, Show)
data Value = ExactValue Rational | FloatValue Double deriving (Eq, Show)
type Bindings = Map.Map String Value
data Builtin
    = Sin
    | Cos
    | Tan
    | Exp
    | Log
    | Sqrt
    | Abs
    | Signum
    | Floor
    | Ceiling
    | Min
    | Max
    | Asin
    | Acos
    | Atan
    | Sinh
    | Cosh
    | Tanh
    deriving (Eq, Ord, Show, Enum, Bounded)
newtype Registry = Registry (Map.Map String Builtin) deriving (Eq, Show)
emptyRegistry :: Registry
emptyRegistry = Registry Map.empty
defaultRegistry :: Registry
defaultRegistry =
    Registry
        ( Map.fromList
            ( zip
                [ "sin"
                , "cos"
                , "tan"
                , "exp"
                , "log"
                , "sqrt"
                , "abs"
                , "signum"
                , "floor"
                , "ceil"
                , "min"
                , "max"
                , "asin"
                , "acos"
                , "atan"
                , "sinh"
                , "cosh"
                , "tanh"
                ]
                [minBound .. maxBound]
            )
        )
registerFunction :: String -> Builtin -> Registry -> Either ExprError Registry
registerFunction n f (Registry m)
    | length (take 1025 n) > 1024 || not (identifier n) =
        err SyntaxError unknownPosition "invalid registry name"
    | Map.size m >= 256 && Map.notMember n m =
        err MemoryLimit unknownPosition "registry supports at most 256 names"
    | otherwise = Right (Registry (Map.insert n f m))
allowedFunctions :: Registry -> [String]
allowedFunctions (Registry m) = Map.keys m
arity :: Builtin -> Int
arity f = if f `elem` [Min, Max] then 2 else 1
finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)
checkValue :: Limits -> Precision -> SourcePos -> Value -> Either ExprError Value
checkValue l mode p v = case (mode, v) of
    (ExactRational, ExactValue q) -> checkRational l p q >> Right v
    (Float64, FloatValue x)
        | finite x -> Right v
        | otherwise -> err NonFinite p "nonfinite floating value"
    _ -> err TypeMismatch p "binding precision differs from selected precision"
fromQ :: Limits -> Precision -> SourcePos -> Rational -> Either ExprError Value
fromQ l mode p q =
    checkRational l p q
        >> checkValue
            l
            mode
            p
            (case mode of ExactRational -> ExactValue q; Float64 -> FloatValue (fromRational q))
constantValue :: Precision -> SourcePos -> NamedConstant -> Either ExprError Value
constantValue ExactRational p _ = err TypeMismatch p "irrational constant in exact mode"
constantValue Float64 _ c = Right (FloatValue (case c of Pi -> pi; Euler -> exp 1; Tau -> 2 * pi))
applyBinary :: Limits -> SourcePos -> BinaryOp -> Value -> Value -> Either ExprError Value
applyBinary l p op (ExactValue a) (ExactValue b) = do
    let cap = maximumIntegerBits l
        size q = max (bits cap (numerator q)) (bits cap (denominator q))
        estimate = case op of
            Power -> if denominator b == 1 then toInteger (max 1 (size a)) * abs (numerator b) else toInteger cap + 1
            _ -> toInteger (size a + size b + 1)
    case op of
        Divide | b == 0 -> err DomainFailure p "division by zero"
        Power | denominator b /= 1 -> err TypeMismatch p "exact powers require an integer exponent"
        Power | a == 0 && b <= 0 -> err DomainFailure p "zero to nonpositive power"
        _ -> Right ()
    if estimate > toInteger cap then err MemoryLimit p "intermediate integer bit budget" else Right ()
    let q = case op of
            Add -> a + b
            Subtract -> a - b
            Multiply -> a * b
            Divide -> a / b
            Power -> a ^^ numerator b
    checkRational l p q
    Right (ExactValue q)
applyBinary _ p op (FloatValue a) (FloatValue b) = do
    if (op == Divide && b == 0)
        || (op == Power && ((a == 0 && b <= 0) || (a < 0 && b /= fromInteger (truncate b))))
        then err DomainFailure p "invalid real division or power"
        else Right ()
    let x = case op of Add -> a + b; Subtract -> a - b; Multiply -> a * b; Divide -> a / b; Power -> a ** b
    if finite x then Right (FloatValue x) else err NonFinite p "nonfinite arithmetic result"
applyBinary _ p _ _ _ = err TypeMismatch p "mixed arithmetic precisions"
integerSqrt :: Integer -> Integer
integerSqrt n
    | n < 2 = n
    | otherwise = go (2 ^ ((bits 8192 n + 1) `div` 2))
  where
    go x = let y = (x + n `quot` x) `quot` 2 in if y >= x then x else go y
applyBuiltin :: Limits -> SourcePos -> Builtin -> [Value] -> Either ExprError Value
applyBuiltin l p f args
    | length args /= arity f = err TypeMismatch p "wrong function arity"
    | otherwise = case args of
        [ExactValue a] -> case f of
            Abs -> Right (ExactValue (abs a))
            Signum -> Right (ExactValue (signum a))
            Floor -> Right (ExactValue (fromInteger (floor a)))
            Ceiling -> Right (ExactValue (fromInteger (ceiling a)))
            Sqrt
                | a < 0 -> err DomainFailure p "negative square root"
                | otherwise ->
                    let n = integerSqrt (numerator a); d = integerSqrt (denominator a)
                     in if n * n == numerator a && d * d == denominator a
                            then fromQ l ExactRational p (n % d)
                            else err TypeMismatch p "irrational exact square root"
            _ -> err TypeMismatch p "transcendental function requires Float64"
        [ExactValue a, ExactValue b]
            | f == Min -> Right (ExactValue (min a b))
            | f == Max -> Right (ExactValue (max a b))
        [FloatValue a] -> do
            if (f == Log && a <= 0) || (f == Sqrt && a < 0) || (f `elem` [Asin, Acos] && abs a > 1)
                then err DomainFailure p "function outside real domain"
                else Right ()
            let x = case f of
                    Sin -> sin a
                    Cos -> cos a
                    Tan -> tan a
                    Exp -> exp a
                    Log -> log a
                    Sqrt -> sqrt a
                    Abs -> abs a
                    Signum -> signum a
                    Floor -> fromInteger (floor a)
                    Ceiling -> fromInteger (ceiling a)
                    Asin -> asin a
                    Acos -> acos a
                    Atan -> atan a
                    Sinh -> sinh a
                    Cosh -> cosh a
                    Tanh -> tanh a
                    Min -> a
                    Max -> a
            if finite x then Right (FloatValue x) else err NonFinite p "nonfinite function result"
        [FloatValue a, FloatValue b]
            | f == Min -> Right (FloatValue (min a b))
            | f == Max -> Right (FloatValue (max a b))
        _ -> err TypeMismatch p "function argument precision mismatch"
lookupFunction :: Registry -> SourcePos -> String -> Int -> Either ExprError Builtin
lookupFunction (Registry registry) p name n = case Map.lookup name registry of
    Nothing -> err UnknownName p ("function not allowed: " ++ name)
    Just f
        | arity f /= n -> err TypeMismatch p "wrong function arity"
        | otherwise -> Right f

{- | Static scalar/precision/name/arity checking. Domains and integer-valued
variable exponents are checked during evaluation, since they depend on values.
Let-bound names are typed lexically without evaluating their initializers.
-}
typeCheckExpression ::
    Limits -> Precision -> Registry -> Bindings -> Expr -> Either ExprError Precision
typeCheckExpression l mode registry env e = do
    validateExpression l e
    _ <- go 1 (start l) Set.empty e
    Right mode
  where
    go d budget locals (Expr p node) = do
        depth l p d
        next <- charge p 1 1 budget
        case node of
            Literal q -> fromQ l mode p q >> Right next
            Constant c -> constantValue mode p c >> Right next
            Variable n
                | Set.member n locals -> Right next
                | otherwise -> case Map.lookup n env of
                    Nothing -> err UnknownName p ("unknown variable: " ++ n)
                    Just v -> checkValue l mode p v >> Right next
            Unary _ a -> go (d + 1) next locals a
            Binary _ a b -> go (d + 1) next locals a >>= \remaining -> go (d + 1) remaining locals b
            Call name xs -> do
                f <- lookupFunction registry p name (length xs)
                if mode == ExactRational && f `notElem` [Sqrt, Abs, Signum, Floor, Ceiling, Min, Max]
                    then err TypeMismatch p "transcendental function requires Float64"
                    else Right ()
                foldM (\remaining child -> go (d + 1) remaining locals child) next xs
            Let name a b -> go (d + 1) next locals a >>= \remaining -> go (d + 1) remaining (Set.insert name locals) b

{- | Direct left-to-right evaluation. Unused let bindings are still evaluated;
unreferenced external bindings are not inspected or copied.
-}
evaluateExpression :: Limits -> Precision -> Registry -> Bindings -> Expr -> Either ExprError Value
evaluateExpression l mode registry env expression = do
    validateExpression l expression
    fst <$> go 1 (start l) env expression
  where
    go d b vars (Expr p node) = do
        depth l p d
        b1 <- charge p 1 1 b
        case node of
            Literal q -> do v <- fromQ l mode p q; Right (v, b1)
            Constant c -> do v <- constantValue mode p c; Right (v, b1)
            Variable n -> case Map.lookup n vars of
                Nothing -> err UnknownName p ("unknown variable: " ++ n)
                Just v -> do x <- checkValue l mode p v; Right (x, b1)
            Unary Negate a -> do
                (x, b2) <- go (d + 1) b1 vars a
                Right (case x of ExactValue q -> ExactValue (-q); FloatValue q -> FloatValue (-q), b2)
            Binary op a c -> do
                (x, b2) <- go (d + 1) b1 vars a
                (y, b3) <- go (d + 1) b2 vars c
                v <- applyBinary l p op x y
                Right (v, b3)
            Call name xs -> do
                f <- lookupFunction registry p name (length xs)
                (args, b2) <-
                    foldM (\(vs, bg) e -> do (v, bg1) <- go (d + 1) bg vars e; Right (vs ++ [v], bg1)) ([], b1) xs
                v <- applyBuiltin l p f args
                Right (v, b2)
            Let n a c -> do (x, b2) <- go (d + 1) b1 vars a; b3 <- charge p 1 1 b2; go (d + 1) b3 (Map.insert n x vars) c

evaluateText :: Limits -> Precision -> Registry -> Bindings -> String -> Either ExprError Value
evaluateText l mode registry env source = parseExpression l source >>= evaluateExpression l mode registry env

-- CSE keys refer only to previously emitted nodes. Lexical bindings resolve to
-- node IDs before interning, so expressions in distinct scopes cannot alias.
data Key
    = KLiteral Rational
    | KConstant NamedConstant
    | KVariable String
    | KUnary UnaryOp Int
    | KBinary BinaryOp Int Int
    | KCall String [Int]
    | KStrictLet Int Int
    deriving (Eq, Ord, Show)
data Instruction = Instruction SourcePos Key deriving (Eq, Show)
data Compiled = Compiled Expr Int (Map.Map Int Instruction) deriving (Eq, Show)
data Build = Build !Int (Map.Map Key Int) (Map.Map Int Instruction) Budget

{- | Compile to a hash-consed DAG. Strict lets are retained, including unused
bindings. CSE changes work requirements, but preserves numeric/domain errors.
-}
compileExpression :: Limits -> Expr -> Either ExprError Compiled
compileExpression l expression = do
    validateExpression l expression
    (root, Build _ _ instructions _) <-
        go 1 Map.empty (Build 0 Map.empty Map.empty (start l)) expression
    Right (Compiled expression root instructions)
  where
    go d locals state (Expr p node) = do
        depth l p d
        st <- spend p state
        case node of
            Literal q -> intern p (KLiteral q) st
            Constant c -> intern p (KConstant c) st
            Variable n -> case Map.lookup n locals of Just i -> Right (i, st); Nothing -> intern p (KVariable n) st
            Unary op a -> do (i, s) <- go (d + 1) locals st a; intern p (KUnary op i) s
            Binary op a b -> do (i, s) <- go (d + 1) locals st a; (j, t) <- go (d + 1) locals s b; intern p (KBinary op i j) t
            Call n xs -> do
                (ids, s) <-
                    foldM (\(is, t) e -> do (i, u) <- go (d + 1) locals t e; Right (is ++ [i], u)) ([], st) xs
                intern p (KCall n ids) s
            Let n a b -> do
                (i, s) <- go (d + 1) locals st a
                (j, t) <- go (d + 1) (Map.insert n i locals) s b
                intern p (KStrictLet i j) t
    spend p (Build n keys instructions b) = do b1 <- charge p 1 0 b; Right (Build n keys instructions b1)
    intern p key (Build n keys instructions b) = case Map.lookup key keys of
        Just i -> Right (i, Build n keys instructions b)
        Nothing -> do
            b1 <- charge p 1 1 b
            Right (n, Build (n + 1) (Map.insert key n keys) (Map.insert n (Instruction p key) instructions) b1)

compiledNodeCount :: Compiled -> Int
compiledNodeCount (Compiled _ _ nodes) = Map.size nodes

{- | DAG evaluation memoizes successful nodes only; errors keep the first
left-to-right source location. Registry checks occur even on compiled calls.
-}
evaluateCompiled ::
    Limits -> Precision -> Registry -> Bindings -> Compiled -> Either ExprError Value
evaluateCompiled l mode registry env (Compiled original root instructions) = do
    validateExpression l original
    (v, _, _) <- go 1 (start l) Map.empty root
    Right v
  where
    go d b memo i = case Map.lookup i instructions of
        Nothing -> err Unsupported unknownPosition "invalid compiled instruction"
        Just (Instruction p key) -> do
            depth l p d
            b1 <- charge p 1 0 b
            case Map.lookup i memo of
                Just v -> Right (v, b1, memo)
                Nothing -> do
                    (v, b2, m2) <- execute d b1 memo p key
                    b3 <- charge p 0 1 b2
                    Right (v, b3, Map.insert i v m2)
    execute d b m p key = case key of
        KLiteral q -> do v <- fromQ l mode p q; Right (v, b, m)
        KConstant c -> do v <- constantValue mode p c; Right (v, b, m)
        KVariable n -> case Map.lookup n env of
            Nothing -> err UnknownName p ("unknown variable: " ++ n)
            Just v -> do w <- checkValue l mode p v; Right (w, b, m)
        KUnary Negate i -> do
            (v, b1, m1) <- go (d + 1) b m i
            Right (case v of ExactValue q -> ExactValue (-q); FloatValue q -> FloatValue (-q), b1, m1)
        KBinary op i j -> do
            (x, b1, m1) <- go (d + 1) b m i
            (y, b2, m2) <- go (d + 1) b1 m1 j
            v <- applyBinary l p op x y
            Right (v, b2, m2)
        KCall name ids -> do
            f <- lookupFunction registry p name (length ids)
            (args, b1, m1) <-
                foldM
                    (\(vs, bg, mm) j -> do (v, bg1, mm1) <- go (d + 1) bg mm j; Right (vs ++ [v], bg1, mm1))
                    ([], b, m)
                    ids
            v <- applyBuiltin l p f args
            Right (v, b1, m1)
        KStrictLet i j -> do (_, b1, m1) <- go (d + 1) b m i; go (d + 1) b1 m1 j

{- | Conservative constant folding of literal arithmetic only. Calls, division
by zero and failing/oversized operations remain intact, preserving failures
and registry restrictions. Floating mode does not reassociate operations.
-}
optimizeExpression :: Limits -> Precision -> Expr -> Either ExprError Expr
optimizeExpression l mode expression = validateExpression l expression >> go expression >>= \e -> validateExpression l e >> Right e
  where
    go (Expr p node) = case node of
        Unary op a -> do
            x <- go a
            case expressionNode x of
                Literal q -> Right (Expr p (Literal (-q)))
                _ -> Right (Expr p (Unary op x))
        Binary op a b -> do
            x <- go a
            y <- go b
            case (mode, expressionNode x, expressionNode y) of
                (ExactRational, Literal q, Literal r) -> case applyBinary l p op (ExactValue q) (ExactValue r) of
                    Right (ExactValue s) -> Right (Expr p (Literal s))
                    _ -> Right (Expr p (Binary op x y))
                _ -> Right (Expr p (Binary op x y))
        Call n xs -> Expr p . Call n <$> mapM go xs
        Let n a b -> do x <- go a; y <- go b; Right (Expr p (Let n x y))
        _ -> Right (Expr p node)

{- | Immutable FIFO cache. Its entries contain syntax only, never environments
or results. Keys include exact source; eviction occurs at the caller's limit.
-}
newtype ExpressionCache = ExpressionCache [(String, Compiled)] deriving (Eq, Show)

emptyExpressionCache :: ExpressionCache
emptyExpressionCache = ExpressionCache []
cacheSize :: ExpressionCache -> Int
cacheSize (ExpressionCache xs) = length xs
cachedExpression ::
    Limits -> String -> ExpressionCache -> Either ExprError (Compiled, ExpressionCache)
cachedExpression l source (ExpressionCache entries) = do
    validateLimits l
    if boundedLength (maximumInputChars l) source > maximumInputChars l
        then err MemoryLimit (SourcePos 0 1 1) "cached input character budget"
        else Right ()
    -- Aggregate source and instruction storage is bounded, including old entries
    -- when a cache is reused with tighter limits.
    let retained = take (maximumCacheEntries l) entries
        storage = sum [toInteger (length s) + toInteger (compiledNodeCount c) | (s, c) <- retained]
    if storage > toInteger (maximumNodes l)
        then err MemoryLimit unknownPosition "cache aggregate storage budget"
        else Right ()
    case lookup source retained of
        Just c@(Compiled e _ _) -> validateExpression l e >> Right (c, ExpressionCache retained)
        Nothing -> do
            e <- parseExpression l source
            c <- compileExpression l e
            let next = take (maximumCacheEntries l) ((source, c) : retained)
                size = sum [toInteger (length s) + toInteger (compiledNodeCount p) | (s, p) <- next]
            if size > toInteger (maximumNodes l)
                then err MemoryLimit unknownPosition "cache aggregate storage budget"
                else Right (c, ExpressionCache next)

-- | Scientific notation with 0..30 fractional digits, for finite values.
formatScientific :: Int -> Value -> Either ExprError String
formatScientific places value
    | places < 0 || places > 30 = err DomainFailure unknownPosition "scientific digits must be 0..30"
    | not (finite x) = err NonFinite unknownPosition "value cannot be represented as finite Double"
    | otherwise = Right (showEFloat (Just places) x "")
  where
    x = case value of ExactValue q -> fromRational q; FloatValue y -> y

-- | Integer radix 2..36; fractional values and nonfinite Double are rejected.
formatRadix :: Int -> Value -> Either ExprError String
formatRadix base value
    | base < 2 || base > 36 = err DomainFailure unknownPosition "radix must be 2..36"
    | otherwise = case value of
        ExactValue q
            | denominator q == 1 -> Right (render (numerator q))
            | otherwise -> err TypeMismatch unknownPosition "radix formatting requires an integer"
        FloatValue x
            | not (finite x) -> err NonFinite unknownPosition "nonfinite radix input"
            | x /= fromInteger (truncate x) ->
                err TypeMismatch unknownPosition "radix formatting requires an integer"
            | otherwise -> Right (render (truncate x))
  where
    render n =
        (if n < 0 then "-" else "")
            ++ showIntAtBase (toInteger base) (\i -> "0123456789abcdefghijklmnopqrstuvwxyz" !! i) (abs n) ""

-- Serialization uses a reserved constructor vocabulary, not Read: input cannot
-- manufacture a Ratio with denominator zero or bypass parser resource limits.
serializeExpression :: Limits -> Expr -> Either ExprError String
serializeExpression l e = do
    validateExpression l e
    let s = encode e
    if boundedLength (maximumInputChars l) s > maximumInputChars l
        then err MemoryLimit unknownPosition "serialized character budget"
        else Right s
  where
    encode (Expr _ n) = case n of
        Literal q -> "__lit(" ++ show (numerator q) ++ "," ++ show (denominator q) ++ ")"
        Variable name -> "__var(" ++ name ++ ")"
        Constant c -> "__const(" ++ constantName c ++ ")"
        Unary Negate a -> "__neg(" ++ encode a ++ ")"
        Binary op a b -> "__" ++ show op ++ "(" ++ encode a ++ "," ++ encode b ++ ")"
        Call name xs -> "__call(" ++ name ++ concatMap ((", " ++) . encode) xs ++ ")"
        Let name a b -> "__let(" ++ name ++ "," ++ encode a ++ "," ++ encode b ++ ")"
deserializeExpression :: Limits -> String -> Either ExprError Expr
deserializeExpression l source = do
    encoded <- parseExpression l source
    e <- decode encoded
    validateExpression l e
    Right e
  where
    decode (Expr p node) = case node of
        Call "__lit" [a, b] -> do
            n <- integer a
            d <- integer b
            if d <= 0 then err DomainFailure p "invalid serialized denominator" else Right (literal (n % d))
        Call "__var" [n] -> variable <$> name n
        Call "__const" [Expr _ (Constant c)] -> Right (constant c)
        Call "__neg" [a] -> unary Negate <$> decode a
        Call n [a, b]
            | Just op <- lookup n [("__" ++ show op, op) | op <- [Add, Subtract, Multiply, Divide, Power]] ->
                binary op <$> decode a <*> decode b
        Call "__call" (n : xs) -> call <$> name n <*> mapM decode xs
        Call "__let" [n, a, b] -> letIn <$> name n <*> decode a <*> decode b
        _ -> err SyntaxError p "invalid serialized constructor"
    name (Expr _ (Variable n)) = Right n
    name (Expr _ (Constant c)) = Right (constantName c)
    name e = err SyntaxError (expressionPosition e) "invalid serialized name"
    integer (Expr _ (Literal q)) | denominator q == 1 = Right (numerator q)
    integer e = err SyntaxError (expressionPosition e) "serialized integer required"

{- | Stable FNV-1a over canonical serialization Unicode code points (not UTF-8
bytes). This is an identity hash, never a cryptographic authenticator.
-}
expressionHash :: Limits -> Expr -> Either ExprError Word64
expressionHash l e =
    foldl (\h c -> (h `xor` fromIntegral (ord c)) * 1099511628211) 14695981039346656037
        <$> serializeExpression l e
