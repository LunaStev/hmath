{-# LANGUAGE FlexibleInstances #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Pure CPU automatic differentiation. 'Dual' nests for higher orders. 'Expr'
compiles to an immutable, reusable reverse tape; dynamic graphs are ordinary
Haskell functions building expressions at run time. Tapes own their saved
primals, so no ambient mutable graph or lifetime is involved. Accumulation is
explicit in 'GradientState'; reverse evaluation itself never accumulates.
Custom rules return a value and local partial derivatives (first order only).
Checkpoints store the subgraph recipe and recompute its tape on backprop.
Complex gradients use real coordinates: dL/dz = (dL/dx+i*dL/dy)/2 (Wirtinger).
-}
module HMath.Autodiff (
    Dual (..),
    primal,
    tangent,
    forward,
    forwardJVP,
    Expr,
    variable,
    constant,
    customOperation,
    customUnary,
    detach,
    stopGradient,
    checkpoint,
    CompiledGraph,
    compileGraph,
    evaluateGraph,
    gradient,
    valueAndGradient,
    differentiate,
    hessian,
    jacobian,
    jvp,
    vjp,
    hvp,
    GradientState (..),
    zeroGradients,
    accumulateGradients,
    resetGradients,
    gradientHook,
    clipGradient,
    gradientCheck,
    complexGradient,
    differentiableStep,
    ADTensor,
    adTensor,
    adValues,
    adShape,
    adBroadcast,
    adAdd,
    adMultiply,
    adMatmul,
    adContract,
    adSum,
) where

import Control.Monad (foldM)
import Data.Complex (Complex ((:+)))
import qualified Data.Foldable as Foldable (foldl')
import qualified Data.IntMap.Strict as IM
import HMath.Error
import qualified HMath.Tensor as T

-- | A tangent may itself be a dual number. Branches use the primal ordering.
data Dual a = Dual a a deriving (Eq, Show)

primal, tangent :: Dual a -> a
primal (Dual a _) = a
tangent (Dual _ a) = a
instance (Ord a) => Ord (Dual a) where compare (Dual x _) (Dual y _) = compare x y
instance (Num a) => Num (Dual a) where
    Dual x dx + Dual y dy = Dual (x + y) (dx + dy)
    Dual x dx - Dual y dy = Dual (x - y) (dx - dy)
    Dual x dx * Dual y dy = Dual (x * y) (dx * y + x * dy)
    negate (Dual x dx) = Dual (negate x) (negate dx)
    abs (Dual x dx) = Dual (abs x) (signum x * dx)
    signum (Dual x _) = Dual (signum x) 0
    fromInteger n = Dual (fromInteger n) 0
instance (Fractional a) => Fractional (Dual a) where
    recip (Dual x dx) = Dual (recip x) (-dx / (x * x))
    fromRational r = Dual (fromRational r) 0
instance (Floating a, Eq a) => Floating (Dual a) where
    Dual x dx ** Dual y dy
        | dy == 0 = Dual (x ** y) (if y == 0 then 0 else dx * y * x ** (y - 1))
        | otherwise = let value = x ** y in Dual value (dx * y * x ** (y - 1) + dy * log x * value)
    pi = Dual pi 0
    exp (Dual x dx) = Dual (exp x) (dx * exp x)
    log (Dual x dx) = Dual (log x) (dx / x)
    sqrt (Dual x dx) = Dual (sqrt x) (dx / (2 * sqrt x))
    sin (Dual x dx) = Dual (sin x) (dx * cos x)
    cos (Dual x dx) = Dual (cos x) (-dx * sin x)
    tan (Dual x dx) = Dual (tan x) (dx / (cos x * cos x))
    asin (Dual x dx) = Dual (asin x) (dx / sqrt (1 - x * x))
    acos (Dual x dx) = Dual (acos x) (-dx / sqrt (1 - x * x))
    atan (Dual x dx) = Dual (atan x) (dx / (1 + x * x))
    sinh (Dual x dx) = Dual (sinh x) (dx * cosh x)
    cosh (Dual x dx) = Dual (cosh x) (dx * sinh x)
    tanh (Dual x dx) = let t = tanh x in Dual t (dx * (1 - t * t))
    asinh (Dual x dx) = Dual (asinh x) (dx / sqrt (1 + x * x))
    acosh (Dual x dx) = Dual (acosh x) (dx / sqrt (x * x - 1))
    atanh (Dual x dx) = Dual (atanh x) (dx / (1 - x * x))

-- | Evaluate a scalar dual function with unit tangent; returns primal and first derivative.
forward :: (Num a) => (Dual a -> Dual a) -> a -> (a, a)
forward f x = let Dual y dy = f (Dual x 1) in (y, dy)

-- | Evaluate a vector dual function along a checked same-length direction; every output must be finite.
forwardJVP ::
    ([Dual Double] -> [Dual Double]) -> [Double] -> [Double] -> Either MathError ([Double], [Double])
forwardJVP f xs ds = do
    same xs ds
    finite xs
    finite ds
    let ys = f (zipWith Dual xs ds)
    finite (map primal ys ++ map tangent ys)
    Right (map primal ys, map tangent ys)

data Unary
    = Power Double
    | Exp
    | Log
    | Sqrt
    | Sin
    | Cos
    | Tan
    | Asin
    | Acos
    | Atan
    | Sinh
    | Cosh
    | Tanh
    | Asinh
    | Acosh
    | Atanh
    | Abs
    | Sign
    deriving (Eq, Show)
data Expr
    = C Double
    | V Int
    | Add Expr Expr
    | Mul Expr Expr
    | Neg Expr
    | Inv Expr
    | U Unary Expr
    | Stop Expr
    | Custom ([Double] -> Either MathError (Double, [Double])) [Expr]
    | Checkpoint ([Expr] -> Expr) [Expr]
instance Show Expr where
    show (C x) = show x
    show (V i) = "x" ++ show i
    show (Add a b) = "(" ++ show a ++ "+" ++ show b ++ ")"
    show (Mul a b) = "(" ++ show a ++ "*" ++ show b ++ ")"
    show (Neg a) = "-" ++ show a
    show (Inv a) = "1/" ++ show a
    show (U op a) = show op ++ "(" ++ show a ++ ")"
    show (Stop a) = "detach(" ++ show a ++ ")"
    show (Custom _ _) = "custom-operation"
    show (Checkpoint _ _) = "checkpoint"
instance Num Expr where
    (+) = Add
    (*) = Mul
    negate = Neg
    abs = U Abs
    signum = U Sign
    fromInteger = C . fromInteger
instance Fractional Expr where
    recip = Inv
    fromRational = C . fromRational
instance Floating Expr where
    base ** C powerValue = U (Power powerValue) base
    base ** powerValue = exp (powerValue * log base)
    pi = C pi
    exp = U Exp
    log = U Log
    sqrt = U Sqrt
    sin = U Sin
    cos = U Cos
    tan = U Tan
    asin = U Asin
    acos = U Acos
    atan = U Atan
    sinh = U Sinh
    cosh = U Cosh
    tanh = U Tanh
    asinh = U Asinh
    acosh = U Acosh
    atanh = U Atanh

-- | Declare a zero-based graph input. compileGraph validates the declared input count.
variable :: Int -> Expr
variable = V

-- | Embed a literal; nonfinite literals are rejected when a graph is compiled.
constant :: Double -> Expr
constant = C

-- | Supply one local partial derivative per argument. Rules must be deterministic and total; outputs and arity are checked.
customOperation :: ([Double] -> Either MathError (Double, [Double])) -> [Expr] -> Expr
customOperation = Custom

-- | First-order scalar custom rule; the second callback is the analytic local derivative.
customUnary :: (Double -> Double) -> (Double -> Double) -> Expr -> Expr
customUnary f df x = Custom rule [x]
  where
    rule [a] = Right (f a, [df a]); rule _ = Left (InvalidArgument "custom unary arity")

-- | Preserve the primal value while removing every reverse edge through this expression.
detach, stopGradient :: Expr -> Expr
detach = Stop
stopGradient = Stop

-- | Store a graph-building recipe instead of the internal tape; replay it during reverse propagation.
checkpoint :: ([Expr] -> Expr) -> [Expr] -> Expr
checkpoint = Checkpoint

-- Nodes record only direct predecessor indices; a compiled graph can be reused
-- at new input values. Each invocation owns its fresh tape and adjoint map.
data Node
    = Literal Double
    | Input Int
    | SumNode Int Int
    | ProductNode Int Int
    | NegateNode Int
    | InverseNode Int
    | UnaryNode Unary Int
    | StopNode Int
    | CustomNode ([Double] -> Either MathError (Double, [Double])) [Int]
    | RecomputeNode ([Expr] -> Expr) [Int]
data CompiledGraph = CompiledGraph Int Int [(Int, Node)]
data Pullback = Partials [(Int, Double)] | Deferred ([Expr] -> Expr) [Int] [Double]

-- | Compile an immutable reusable graph with n inputs and a hard limit of one million scalar nodes.
compileGraph :: Int -> Expr -> Either MathError CompiledGraph
compileGraph n e
    | n < 0 = Left (InvalidArgument "negative graph input count")
    | otherwise = do
        (root, _, nodes) <- build 0 [] e
        Right (CompiledGraph n root (reverse nodes))
  where
    add next nodes node
        | next >= 1000000 = Left (NonConvergence "automatic differentiation graph node budget" next)
        | otherwise = Right (next, next + 1, (next, node) : nodes)
    build next nodes ex = case ex of
        C x -> if isFinite x then add next nodes (Literal x) else Left NonFiniteResult
        V i -> if i >= 0 && i < n then add next nodes (Input i) else Left (InvalidArgument "graph input index")
        Add a b -> binary SumNode next nodes a b
        Mul a b -> binary ProductNode next nodes a b
        Neg a -> unary NegateNode next nodes a
        Inv a -> unary InverseNode next nodes a
        U (Power powerValue) _ | not (isFinite powerValue) -> Left NonFiniteResult
        U op a -> unary (UnaryNode op) next nodes a
        Stop a -> unary StopNode next nodes a
        Custom f es -> do (ids, k, ns) <- many next nodes es; add k ns (CustomNode f ids)
        Checkpoint f es -> do (ids, k, ns) <- many next nodes es; add k ns (RecomputeNode f ids)
    unary f k ns a = do (i, j, ms) <- build k ns a; add j ms (f i)
    binary f k ns a b = do (i, j, ms) <- build k ns a; (l, q, rs) <- build j ms b; add q rs (f i l)
    many k ns [] = Right ([], k, ns)
    many k ns (a : as) = do (i, j, ms) <- build k ns a; (ids, q, rs) <- many j ms as; Right (i : ids, q, rs)

isFinite :: Double -> Bool
isFinite x = not (isNaN x || isInfinite x)
finite :: [Double] -> Either MathError ()
finite xs = if all isFinite xs then Right () else Left NonFiniteResult
same :: [a] -> [b] -> Either MathError ()
same a b = if length a == length b then Right () else Left (VectorLengthMismatch (length a) (length b))
unaryValue :: Unary -> Double -> Double
unaryValue op = case op of
    Power powerValue -> (** powerValue)
    Exp -> exp
    Log -> log
    Sqrt -> sqrt
    Sin -> sin
    Cos -> cos
    Tan -> tan
    Asin -> asin
    Acos -> acos
    Atan -> atan
    Sinh -> sinh
    Cosh -> cosh
    Tanh -> tanh
    Asinh -> asinh
    Acosh -> acosh
    Atanh -> atanh
    Abs -> abs
    Sign -> signum

-- Expressions for local derivatives support exact symbolic higher orders.
localDerivative :: Unary -> Expr -> Expr
localDerivative op x = case op of
    Power powerValue -> if powerValue == 0 then 0 else C powerValue * x ** C (powerValue - 1)
    Exp -> exp x
    Log -> recip x
    Sqrt -> recip (2 * sqrt x)
    Sin -> cos x
    Cos -> negate (sin x)
    Tan -> recip (cos x * cos x)
    Asin -> recip (sqrt (1 - x * x))
    Acos -> negate (recip (sqrt (1 - x * x)))
    Atan -> recip (1 + x * x)
    Sinh -> cosh x
    Cosh -> sinh x
    Tanh -> 1 - tanh x * tanh x
    Asinh -> recip (sqrt (1 + x * x))
    Acosh -> recip (sqrt (x * x - 1))
    Atanh -> recip (1 - x * x)
    Abs -> signum x
    Sign -> 0

runTape ::
    CompiledGraph -> [Double] -> Either MathError (Double, [(Int, Pullback)], IM.IntMap Double)
runTape (CompiledGraph n root nodes) xs = do
    if length xs /= n then Left (VectorLengthMismatch n (length xs)) else finite xs
    (vs, edges) <- Foldable.foldl' step (Right (IM.empty, [])) nodes
    Right (vs IM.! root, edges, vs)
  where
    step acc (i, node) = do
        (vs, es) <- acc
        let get j = vs IM.! j
        (v, ds) <- case node of
            Literal x -> Right (x, [])
            Input k -> Right (xs !! k, [])
            SumNode a b -> Right (get a + get b, [(a, 1), (b, 1)])
            ProductNode a b -> Right (get a * get b, [(a, get b), (b, get a)])
            NegateNode a -> Right (-get a, [(a, -1)])
            InverseNode a -> Right (1 / get a, [(a, -1 / (get a * get a))])
            UnaryNode op a -> do
                d <- evaluate (localDerivative op (C (get a)))
                Right (unaryValue op (get a), [(a, d)])
            StopNode a -> Right (get a, [])
            CustomNode f ids -> do
                (v, partials) <- f (map get ids)
                same ids partials
                Right (v, zip ids partials)
            RecomputeNode f ids -> do
                graph <- compileGraph (length ids) (f (map V [0 .. length ids - 1]))
                v <- evaluateGraph graph (map get ids)
                Right (v, [])
        finite (v : map snd ds)
        let edge = case node of RecomputeNode recipe ids -> Deferred recipe ids (map get ids); _ -> Partials ds
        Right (IM.insert i v vs, (i, edge) : es)
    evaluate e = do g <- compileGraph 0 e; (y, _, _) <- runValue g []; Right y

-- local derivative evaluation must not recursively differentiate its own
-- unary nodes. This separate evaluator computes values alone.
runValue :: CompiledGraph -> [Double] -> Either MathError (Double, (), ())
runValue (CompiledGraph n root ns) xs = do
    if n /= length xs then Left (VectorLengthMismatch n (length xs)) else finite xs
    vs <- Foldable.foldl' step (Right IM.empty) ns
    Right (vs IM.! root, (), ())
  where
    step acc (i, node) = do
        vs <- acc
        let get k = vs IM.! k
        y <- case node of
            Literal x -> Right x
            Input k -> Right (xs !! k)
            SumNode a b -> Right (get a + get b)
            ProductNode a b -> Right (get a * get b)
            NegateNode a -> Right (-get a)
            InverseNode a -> Right (1 / get a)
            UnaryNode op a -> Right (unaryValue op (get a))
            StopNode a -> Right (get a)
            CustomNode f ids -> fst <$> f (map get ids)
            RecomputeNode f ids -> do
                graph <- compileGraph (length ids) (f (map V [0 .. length ids - 1]))
                evaluateGraph graph (map get ids)
        finite [y]
        Right (IM.insert i y vs)

-- | Re-evaluate a compiled graph at exactly n finite inputs, without requesting gradients.
evaluateGraph :: CompiledGraph -> [Double] -> Either MathError Double
evaluateGraph g xs = do (y, _, _) <- runValue g xs; Right y

-- | Build a dynamic graph and return its checked value and reverse gradient; repeated input leaves accumulate.
valueAndGradient :: ([Expr] -> Expr) -> [Double] -> Either MathError (Double, [Double])
valueAndGradient f xs = do
    let n = length xs
    g@(CompiledGraph _ root nodes) <- compileGraph n (f (map V [0 .. n - 1]))
    (y, edges, _) <- runTape g xs
    adj <-
        foldM
            ( \as (i, pullback) -> do
                derivatives <- case pullback of
                    Partials ds -> Right ds
                    Deferred recipe ids primals -> do
                        (_, partials) <- valueAndGradient recipe primals
                        Right (zip ids partials)
                let adjoint = IM.findWithDefault 0 i as
                    next = Foldable.foldl' (\m (j, d) -> IM.insertWith (+) j (adjoint * d) m) as derivatives
                finite (IM.elems next)
                Right next
            )
            (IM.singleton root 1)
            edges
    let grads =
            Foldable.foldl'
                (\m (i, node) -> case node of Input k -> IM.insertWith (+) k (IM.findWithDefault 0 i adj) m; _ -> m)
                IM.empty
                nodes
        result = [IM.findWithDefault 0 k grads | k <- [0 .. n - 1]]
    finite result
    Right (y, result)

-- | Return a fresh reverse gradient. Previous calls and explicit GradientState values are unaffected.
gradient :: ([Expr] -> Expr) -> [Double] -> Either MathError [Double]
gradient f xs = snd <$> valueAndGradient f xs

-- | Construct a symbolic derivative with respect to one graph input. Opaque custom first-order rules reject higher orders.
differentiate :: Int -> Expr -> Either MathError Expr
differentiate i ex = case ex of
    C _ -> Right 0
    V j -> Right (if i == j then 1 else 0)
    Add a b -> (+) <$> differentiate i a <*> differentiate i b
    Mul a b -> do da <- differentiate i a; db <- differentiate i b; Right (da * b + a * db)
    Neg a -> negate <$> differentiate i a
    Inv a -> (\da -> -da / (a * a)) <$> differentiate i a
    U op a -> (localDerivative op a *) <$> differentiate i a
    Stop _ -> Right 0
    Custom _ _ ->
        Left
            (InvalidArgument "custom rules support first order; provide a symbolic operation for higher orders")
    Checkpoint f as -> differentiate i (f as)

-- | Return output-by-input Jacobian rows, including shape-preserving empty output handling.
jacobian :: ([Expr] -> [Expr]) -> [Double] -> Either MathError [[Double]]
jacobian f xs = do
    finite xs
    mapM (\e -> gradient (const e) xs) (f (map V [0 .. length xs - 1]))

-- | Return input-by-input symbolic second derivatives; all evaluated derivatives must be finite.
hessian :: ([Expr] -> Expr) -> [Double] -> Either MathError [[Double]]
hessian f xs = do
    let n = length xs; e = f (map V [0 .. n - 1])
    graph <- compileGraph n e
    _ <- evaluateGraph graph xs
    ds <- mapM (`differentiate` e) [0 .. n - 1]
    mapM (\d -> gradient (const d) xs) ds

-- | Multiply the automatic Jacobian by a finite input direction; returns one value per output.
jvp :: ([Expr] -> [Expr]) -> [Double] -> [Double] -> Either MathError [Double]
jvp f xs ds = do
    same xs ds
    j <- jacobian f xs
    finite ds
    let values = map (sum . zipWith (*) ds) j
    finite values
    Right values

-- | Multiply an output cotangent by the automatic Jacobian; returns one value per input.
vjp :: ([Expr] -> [Expr]) -> [Double] -> [Double] -> Either MathError [Double]
vjp f xs ds = do
    let ys = f (map V [0 .. length xs - 1])
    same ys ds
    finite ds
    gradient (const (sum (zipWith (\d y -> C d * y) ds ys))) xs

-- | Multiply the symbolic Hessian by a checked finite input direction.
hvp :: ([Expr] -> Expr) -> [Double] -> [Double] -> Either MathError [Double]
hvp f xs ds = do
    same xs ds
    h <- hessian f xs
    finite ds
    let values = map (sum . zipWith (*) ds) h
    finite values
    Right values

newtype GradientState = GradientState {accumulatedGradient :: [Double]} deriving (Eq, Show)

-- | Create an explicit zero accumulation buffer for a nonnegative input count.
zeroGradients :: Int -> Either MathError GradientState
zeroGradients n
    | n < 0 = Left (InvalidArgument "negative gradient size")
    | otherwise = Right (GradientState (replicate n 0))

-- | Add one same-length finite gradient without modifying the previous state.
accumulateGradients :: GradientState -> [Double] -> Either MathError GradientState
accumulateGradients (GradientState a) b = do
    same a b
    let c = zipWith (+) a b
    finite c
    Right (GradientState c)

-- | Return a zero buffer of the original size; existing state remains reusable.
resetGradients :: GradientState -> GradientState
resetGradients (GradientState a) = GradientState (map (const 0) a)

-- | Apply an explicit checked transformation; changing gradient length is rejected.
gradientHook ::
    ([Double] -> Either MathError [Double]) -> GradientState -> Either MathError GradientState
gradientHook f (GradientState a) = do b <- f a; same a b; finite b; Right (GradientState b)

-- | Clip Euclidean norm while preserving direction, including vectors whose unscaled norm exceeds Double range.
clipGradient :: Double -> [Double] -> Either MathError [Double]
clipGradient limit xs
    | not (isFinite limit) || limit <= 0 = Left InvalidTolerance
    | otherwise = do
        finite xs
        let m = maximum (0 : map abs xs)
            unitNorm = sqrt (sum (map (\x -> (x / m) ^ (2 :: Int)) xs))
        Right (if m == 0 || m <= limit / unitNorm then xs else map (\x -> (x / m) * (limit / unitNorm)) xs)

{- | Returns maximum absolute discrepancy. The numerical check is deliberately
separate from automatic derivatives; h must be finite and strictly positive.
-}
gradientCheck :: Double -> ([Expr] -> Expr) -> [Double] -> Either MathError Double
gradientCheck h f xs
    | not (isFinite h) || h <= 0 = Left InvalidTolerance
    | otherwise = do
        g <- gradient f xs
        graph <- compileGraph (length xs) (f (map V [0 .. length xs - 1]))
        fd <-
            mapM
                ( \i -> do
                    a <- evaluateGraph graph (bump i h xs)
                    b <- evaluateGraph graph (bump i (-h) xs)
                    Right ((a - b) / (2 * h))
                )
                [0 .. length xs - 1]
        finite fd
        let discrepancies = zipWith (\a b -> abs (a - b)) g fd
        finite discrepancies
        Right (maximum (0 : discrepancies))
  where
    bump i h' ys = [if j == i then y + h' else y | (j, y) <- zip [0 :: Int ..] ys]

-- | Differentiate a real objective of [real,imaginary] and return its Wirtinger derivative with respect to conjugate z.
complexGradient :: ([Expr] -> Expr) -> Complex Double -> Either MathError (Complex Double)
complexGradient f (x :+ y) = do
    g <- gradient f [x, y]
    case g of { [a, b] -> Right (a / 2 :+ b / 2); _ -> Left (InvalidArgument "complex gradient arity") }

-- | Take a symbolic gradient-descent step at the supplied expressions; local substitution preserves outer derivatives across repeated steps.
differentiableStep :: Double -> ([Expr] -> Expr) -> [Expr] -> Either MathError [Expr]
differentiableStep rate f xs = do
    finite [rate]
    let n = length xs
    ds <- mapM (\i -> differentiate i (f (map V [0 .. n - 1]))) [0 .. n - 1]
    replacements <- mapM substitute ds
    Right (zipWith (\x d -> x - C rate * d) xs replacements)
  where
    substitute expression = case expression of
        C x -> Right (C x)
        V i ->
            if i >= 0 && i < length xs
                then Right (xs !! i)
                else Left (InvalidArgument "differentiable step local variable index")
        Add a b -> Add <$> substitute a <*> substitute b
        Mul a b -> Mul <$> substitute a <*> substitute b
        Neg a -> Neg <$> substitute a
        Inv a -> Inv <$> substitute a
        U op a -> U op <$> substitute a
        Stop a -> Stop <$> substitute a
        Custom rule as -> Custom rule <$> mapM substitute as
        Checkpoint recipe as -> Checkpoint recipe <$> mapM substitute as

{- | Row-major symbolic tensors. Broadcasting is delegated to the checked tensor
shape engine. Matrix/contraction rules are ordinary scalar graph operations,
so reverse accumulation includes all repeated/broadcast input contributions.
-}
newtype ADTensor = ADTensor (T.Tensor Expr) deriving (Show)

-- | Construct a checked row-major symbolic tensor. Shape product must match expression count.
adTensor :: [Int] -> [Expr] -> Either MathError ADTensor
adTensor shape xs = ADTensor <$> T.tensor shape xs

-- | Return logical row-major graph expressions, preserving shared input identifiers.
adValues :: ADTensor -> [Expr]
adValues (ADTensor t) = T.tensorValues t

-- | Return tensor dimensions, with [] denoting a scalar.
adShape :: ADTensor -> [Int]
adShape (ADTensor t) = T.tensorShape t

-- | Broadcast through explicit repeated scalar graph leaves; reverse gradients sum over repetitions.
adBroadcast :: [Int] -> ADTensor -> Either MathError ADTensor
adBroadcast s (ADTensor t) = ADTensor <$> T.broadcastTo s t

-- | Broadcast and combine symbolic tensors using the existing checked tensor shape contract.
adAdd, adMultiply :: ADTensor -> ADTensor -> Either MathError ADTensor
adAdd (ADTensor a) (ADTensor b) = ADTensor <$> T.tensorAdd a b
adMultiply (ADTensor a) (ADTensor b) = ADTensor <$> T.tensorMultiply a b

-- | Symbolic batched matrix multiplication with checked contraction dimensions.
adMatmul :: ADTensor -> ADTensor -> Either MathError ADTensor
adMatmul (ADTensor a) (ADTensor b) = ADTensor <$> T.batchedMatmul a b

-- | Contract selected axes with matching sizes; uncontracted dimensions retain tensor order.
adContract :: [Int] -> [Int] -> ADTensor -> ADTensor -> Either MathError ADTensor
adContract ax bx (ADTensor a) (ADTensor b) = ADTensor <$> T.tensordot ax bx a b

-- | Reduce every tensor element to one symbolic scalar.
adSum :: ADTensor -> Expr
adSum = sum . adValues
