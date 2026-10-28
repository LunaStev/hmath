-- SPDX-License-Identifier: MPL-2.0
module DifferentiableBatchSpec (differentiableBatchTests) where

import Data.Complex (Complex ((:+)))
import Data.Either (isLeft)
import qualified HMath.Autodiff as A
import qualified HMath.DeepLearning as D
import HMath.Error
import qualified HMath.Optimization as O
import qualified HMath.Polynomial as P
import HMath.Random (Generator (PCG32), seedRNG)
import qualified HMath.Random
import qualified HMath.Root as R
import qualified HMath.Tensor as T

near :: Double -> Double -> Bool
near a b = abs (a - b) <= 1e-6 * (1 + abs b)
nearList :: [Double] -> [Double] -> Bool
nearList a b = length a == length b && and (zipWith near a b)
right :: (a -> Bool) -> Either e a -> Bool
right f (Right x) = f x
right _ _ = False
quad :: O.Objective
quad xs = Right (sum [(x - 2) ^ (2 :: Int) | x <- xs])
gquad :: O.Gradient
gquad xs = Right (map (\x -> 2 * (x - 2)) xs)
hquad :: O.Hessian
hquad xs = Right [[if i == j then 2 else 0 | j <- [0 .. length xs - 1]] | i <- [0 .. length xs - 1]]
opt :: O.OptimizeOptions
opt = O.OptimizeOptions 20000 120000 1e-6 0.05
rOpt :: R.RootOptions
rOpt = R.defaultRootOptions
rng :: HMath.Random.RNG
rng = seedRNG PCG32 42

-- The helper takes structured tensor failures through the same checked path.
tensorTest :: [Int] -> [Double] -> (T.Tensor Double -> Either MathError a) -> (a -> Bool) -> Bool
tensorTest shape values f check = right check (T.tensor shape values >>= f)

differentiableBatchTests :: [(String, Bool)]
differentiableBatchTests = adTests ++ rootTests ++ optimizationTests ++ deepTests ++ regressionTests ++ boundaryTests

adTests :: [(String, Bool)]
adTests =
    [
        ( "AD nested dual second derivative"
        , let x = A.Dual (A.Dual 2 1) (A.Dual 1 0); y = x * x * x in near (A.tangent (A.tangent y)) 12
        )
    ,
        ( "AD forward JVP"
        , right
            (\(v, d) -> nearList v [13] && nearList d [18])
            (A.forwardJVP (\xs -> [xs !! 0 * xs !! 0 + 3 * xs !! 1]) [2, 3] [3, 2])
        )
    ,
        ( "AD reverse scalar chain"
        , right (nearList [12, 4]) (A.gradient (\xs -> xs !! 0 * xs !! 0 * xs !! 1) [2, 3])
        )
    ,
        ( "AD static graph reuse"
        , right
            (\g -> right (near 5) (A.evaluateGraph g [2]) && right (near 10) (A.evaluateGraph g [3]))
            (A.compileGraph 1 (A.variable 0 * A.variable 0 + 1))
        )
    ,
        ( "AD dynamic graph branch"
        , right (nearList [4]) (A.gradient (\xs -> if length xs == 1 then xs !! 0 * xs !! 0 else sum xs) [2])
        )
    ,
        ( "AD accumulation reset"
        , right
            ( \s ->
                right
                    (\a -> A.accumulatedGradient a == [4, 6] && A.accumulatedGradient (A.resetGradients a) == [0, 0])
                    (A.accumulateGradients s [3, 4])
            )
            (A.zeroGradients 2 >>= (\s -> A.accumulateGradients s [1, 2]))
        )
    ,
        ( "AD symbolic Hessian"
        , right
            (\h -> and (zipWith nearList h [[6, 4], [4, 0]]))
            (A.hessian (\x -> x !! 0 * x !! 0 * x !! 1) [2, 3])
        )
    ,
        ( "AD Jacobian"
        , right
            (\h -> and (zipWith nearList h [[3, 2], [1, 1]]))
            (A.jacobian (\x -> [product x, sum x]) [2, 3])
        )
    ,
        ( "AD JVP VJP duality"
        , let f x = [x !! 0 * x !! 1, x !! 0 + 2 * x !! 1]
           in right
                ( \j ->
                    right (\v -> near (sum (zipWith (*) [4, 5] j)) (sum (zipWith (*) [2, 3] v))) (A.vjp f [1, 2] [4, 5])
                )
                (A.jvp f [1, 2] [2, 3])
        )
    , ("AD HVP", right (nearList [6, 8]) (A.hvp (\x -> sum (map (\z -> z * z) x)) [2, 3] [3, 4]))
    ,
        ( "AD checkpoint recomputation"
        , right (nearList [12]) (A.gradient (\x -> A.checkpoint (\y -> y !! 0 * y !! 0 * y !! 0) x) [2])
        )
    ,
        ( "AD gradient hook"
        , right
            (\s -> A.accumulatedGradient s == [2, 4])
            (A.gradientHook (Right . map (* 2)) (A.GradientState [1, 2]))
        )
    ,
        ( "AD clipping large direction"
        , right (nearList [sqrt 0.5, sqrt 0.5]) (A.clipGradient 1 [1e308, 1e308])
        )
    ,
        ( "AD custom gradient"
        , right (nearList [7]) (A.gradient (\x -> A.customUnary (\z -> z * z) (const 7) (x !! 0)) [2])
        )
    , ("AD detach", right (nearList [2]) (A.gradient (\x -> x !! 0 * A.detach (x !! 0)) [2]))
    ,
        ( "AD custom arity rejects"
        , isLeft (A.gradient (\x -> A.customOperation (const (Right (1, []))) x) [1])
        )
    ,
        ( "AD complex Wirtinger"
        , right (\z -> z == (2 :+ 3)) (A.complexGradient (\x -> sum (map (\y -> y * y) x)) (2 :+ 3))
        )
    ,
        ( "AD numerical gradient check"
        , right (< 1e-6) (A.gradientCheck 1e-5 (\x -> sin (x !! 0) * x !! 1) [1, 2])
        )
    ,
        ( "AD differentiable repeated optimizer step"
        , right
            (nearList [0.81])
            ( do
                x1 <- A.differentiableStep 0.05 (\x -> sum (map (\z -> z * z) x)) [A.variable 0]
                x2 <- A.differentiableStep 0.05 (\x -> sum (map (\z -> z * z) x)) x1
                A.gradient (const (sum x2)) [3]
            )
        )
    , ("AD stable saturated tanh", right (nearList [0]) (A.gradient (\x -> tanh (x !! 0)) [1000]))
    , ("AD rejects JVP overflow", isLeft (A.jvp (\x -> [1e308 * x !! 0]) [0] [1e308]))
    , ("AD rejects HVP overflow", isLeft (A.hvp (\x -> 1e308 * x !! 0 * x !! 0 / 2) [0] [1e308]))
    , ("AD rejects empty-output nonfinite", isLeft (A.jacobian (const []) [0 / 0]))
    ,
        ( "AD rejects finite difference overflow"
        , isLeft
            (A.gradientCheck 1e-200 (\x -> A.customUnary (\z -> signum z * 1e308) (const 0) (x !! 0)) [0])
        )
    ,
        ( "AD tensor broadcast gradients"
        , right
            (nearList [3, 3])
            ( do
                let x = map A.variable [0, 1]
                a <- A.adTensor [2, 1] x
                b <- A.adBroadcast [2, 3] a
                A.gradient (const (A.adSum b)) [2, 3]
            )
        )
    ,
        ( "AD tensor matrix gradients"
        , right
            (nearList [3, 7])
            ( do
                a <- A.adTensor [1, 2] (map A.variable [0, 1])
                b <- A.adTensor [2, 2] (map A.constant [1, 2, 3, 4])
                c <- A.adMatmul a b
                A.gradient (const (A.adSum c)) [2, 3]
            )
        )
    ,
        ( "AD tensor contraction"
        , right
            (nearList [3, 4])
            ( do
                a <- A.adTensor [2] (map A.variable [0, 1])
                b <- A.adTensor [2] (map A.constant [3, 4])
                c <- A.adContract [0] [0] a b
                A.gradient (const (A.adSum c)) [1, 2]
            )
        )
    ]

rootTests :: [(String, Bool)]
rootTests =
    [ ( "root " ++ show method
      , right
            (\r -> near (R.rootValue r) (sqrt 2) && R.rootResidual r <= 1e-10)
            (R.bracket (\x -> x * x - 2) 0 2 >>= R.solveBracket method rOpt (\x -> x * x - 2))
      )
    | method <- [R.Bisection, R.RegulaFalsi, R.Illinois, R.Brent, R.Ridder]
    ]
        ++ [ ( "root derivative " ++ show method
             , right
                (\r -> near (R.rootValue r) (sqrt 2))
                (R.solveDerivative method rOpt (\x -> x * x - 2) [(2 *), const 2, const 0] 1)
             )
           | method <- [R.Newton, R.Halley, R.Householder3]
           ]
        ++ [ ( "fixed point " ++ show method
             , right (\r -> near (R.rootValue r) 0.7390851332151607) (R.fixedPoint method rOpt cos 1)
             )
           | method <- [R.Picard, R.Aitken, R.SteffensenFixed]
           ]
        ++ [ ("root secant", right (\r -> near (R.rootValue r) (sqrt 2)) (R.secant rOpt (\x -> x * x - 2) 1 2))
           ,
               ( "root Steffensen"
               , right (\r -> near (R.rootValue r) (sqrt 2)) (R.steffensen rOpt (\x -> x * x - 2) 1)
               )
           ,
               ( "root all sign intervals"
               , right
                    (\rs -> nearList (map R.rootValue rs) [-1, 0, 1])
                    (R.isolateIntervals rOpt (\x -> x * (x * x - 1)) (-2) 2 80)
               )
           , ("root invalid bracket", isLeft (R.bracket (\x -> x * x + 1) (-1) 1))
           , ("root zero derivative", isLeft (R.solveDerivative R.Newton rOpt (\x -> x * x + 1) [(2 *)] 0))
           ,
               ( "root discontinuity rejected"
               , isLeft
                    ( R.bracket (\x -> if x < 0.3 then -1 else 1) 0 1
                        >>= R.solveBracket R.Brent rOpt (\x -> if x < 0.3 then -1 else 1)
                    )
               )
           , ("root nonfinite rejected", isLeft (R.secant rOpt (const (0 / 0)) 1 2))
           ,
               ( "root iteration exhaustion"
               , isLeft (R.secant (rOpt{R.rootMaxIterations = 1}) (\x -> cos x - x) 1 2)
               )
           ,
               ( "root evaluation exhaustion"
               , isLeft (R.solveDerivative R.Newton (rOpt{R.rootMaxEvaluations = 1}) (\x -> x * x - 2) [(2 *)] 1)
               )
           ,
               ( "root Anderson system"
               , right
                    (\r -> nearList (R.systemRoot r) [2, 4])
                    (R.anderson 3 1e-10 rOpt (zipWith (\target x -> 0.5 * (target + x)) [2, 4]) [0, 0])
               )
           ,
               ( "root complex polynomial"
               , right (\xs -> length xs == 2) (R.polynomialRoots rOpt (P.polynomial [1 :+ 0, 0, 1]))
               )
           ,
               ( "root repeated real multiplicity"
               , right
                    (\xs -> length xs == 1 && all (\(_, _, m) -> m == 2) xs)
                    (R.realPolynomialRoots 1000 (1 / 100000) (P.polynomial [1, -2, 1]))
               )
           ]
        ++ [ ( "root system " ++ show method
             , right
                (\r -> nearList (R.systemRoot r) [2, 3])
                ( R.solveSystem
                    method
                    rOpt
                    (\x -> [x !! 0 * x !! 0 - 4, x !! 1 - 3])
                    (\x -> [[2 * x !! 0, 0], [0, 1]])
                    [1, 1]
                )
             )
           | method <- [R.MultivariateNewton, R.NewtonTrustRegion 1, R.Broyden]
           ]
        ++ [
               ( "root singular Jacobian"
               , isLeft
                    (R.solveSystem R.MultivariateNewton rOpt (\x -> [x !! 0 * x !! 0 + 1]) (\x -> [[2 * x !! 0]]) [0])
               )
           ]

optimizationTests :: [(String, Bool)]
optimizationTests =
    [ ( "minimize scalar " ++ show method
      , right
            (\r -> nearList (O.optPoint r) [2])
            (O.minimizeScalar method opt (\x -> Right ((x - 2) ^ (2 :: Int))) (-5) 8)
      )
    | method <- [O.GoldenSection, O.TernarySearch, O.BrentSearch]
    ]
        ++ [ ( "optimizer state " ++ show method
             , right
                (\(x, _) -> all (\v -> not (isNaN v || isInfinite v)) x && x !! 0 < 3)
                (O.initializeOptimizer 1 >>= \s -> O.optimizerStep method 0.01 s [3] [2])
             )
           | method <- [minBound .. maxBound]
           ]
        ++ [ ( "optimizer minimize " ++ show method
             , right (\r -> nearList (O.optPoint r) [2, 2]) (O.minimizeGradient method opt quad gquad [3, 4])
             )
           | method <- [O.GradientDescent, O.Momentum, O.Nesterov, O.Adam, O.AMSGrad, O.AdaMax, O.Nadam, O.RAdam]
           ]
        ++ [ ( "quasi Newton " ++ show method
             , right (\r -> nearList (O.optPoint r) [2, 2]) (O.minimizeQuasiNewton method opt quad gquad [3, 4])
             )
           | method <- [O.BFGS, O.LBFGS 4, O.DFP, O.SR1]
           ]
        ++ [ ( "Newton optimizer " ++ show method
             , right (\r -> nearList (O.optPoint r) [2, 2]) (O.minimizeNewton method opt quad gquad hquad [3, 4])
             )
           | method <- [O.Newton, O.NewtonCG, O.TrustRegion 0.2, O.Dogleg 0.2]
           ]
        ++ [
               ( "optimizer nonlinear CG"
               , right (\r -> nearList (O.optPoint r) [2, 2]) (O.nonlinearCG opt quad gquad [3, 4])
               )
           ,
               ( "optimizer SGD minibatch"
               , right
                    (\(x, _) -> x !! 0 < 3)
                    (O.stochasticGradient O.Adam 0.1 [O.miniBatchGradient [gquad, gquad]] [3])
               )
           ,
               ( "optimizer projected boundary"
               , right
                    (\r -> nearList (O.optPoint r) [1])
                    (O.projectedGradient opt quad gquad (Right . map (min 1 . max 0)) [0])
               )
           ,
               ( "optimizer proximal L1"
               , right
                    (\r -> nearList (O.optPoint r) [1.5])
                    (O.proximalGradient opt quad gquad (\rate -> Right . map (\x -> signum x * max 0 (abs x - rate))) [0])
               )
           ,
               ( "optimizer FISTA"
               , right
                    (\r -> nearList (O.optPoint r) [1.5])
                    (O.fista opt quad gquad (\rate -> Right . map (\x -> signum x * max 0 (abs x - rate))) [0])
               )
           ,
               ( "optimizer block coordinate"
               , right (\r -> nearList (O.optPoint r) [2, 2]) (O.coordinateDescent [[0], [1]] opt quad gquad [3, 4])
               )
           ,
               ( "optimizer Nelder Mead"
               , right (\r -> nearList (O.optPoint r) [2, 2]) (O.nelderMead opt quad [3, 4])
               )
           , ("optimizer Powell", right (\r -> nearList (O.optPoint r) [2, 2]) (O.powell 5 opt quad [3, 4]))
           ,
               ( "optimizer GN"
               , right
                    (\r -> nearList (O.optPoint r) [2])
                    ( O.leastSquares
                        O.SquaredLoss
                        0
                        opt
                        (\x -> Right [x !! 0 - 2, 2 * x !! 0 - 4])
                        (const (Right [[1], [2]]))
                        [0]
                    )
               )
           ,
               ( "optimizer LM"
               , right
                    (\r -> nearList (O.optPoint r) [2])
                    ( O.leastSquares
                        O.SquaredLoss
                        0.1
                        opt
                        (\x -> Right [x !! 0 - 2, 2 * x !! 0 - 4])
                        (const (Right [[1], [2]]))
                        [0]
                    )
               )
           ,
               ( "optimizer robust least squares"
               , right
                    (\r -> O.optPoint r !! 0 < 3)
                    ( O.leastSquares
                        (O.HuberLoss 1)
                        0.1
                        opt
                        (\x -> Right [x !! 0 - 2, x !! 0 - 2, x !! 0 - 100])
                        (const (Right [[1], [1], [1]]))
                        [0]
                    )
               )
           ,
               ( "optimizer two phase LP"
               , right
                    (\r -> nearList (O.lpPoint r) [2] && near (O.lpValue r) 2)
                    (O.linearProgramming 100 1e-10 [1] [[-1], [1]] [-2, 4])
               )
           ,
               ( "optimizer simplex upper bound"
               , right
                    (\r -> nearList (O.lpPoint r) [2, 2])
                    (O.linearProgramming 100 1e-10 [-1, -1] [[1, 0], [0, 1], [1, 1]] [2, 2, 5])
               )
           , ("optimizer infeasible LP", isLeft (O.linearProgramming 100 1e-10 [1] [[1], [-1]] [1, -2]))
           , ("optimizer unbounded LP", isLeft (O.linearProgramming 100 1e-10 [-1] [[-1]] [0]))
           ,
               ( "optimizer revised simplex"
               , right
                    (\r -> nearList (take 2 (O.lpPoint r)) [2, 2])
                    (O.revisedSimplex 100 1e-10 [-1, -1, 0, 0] [[1, 0, 1, 0], [0, 1, 0, 1]] [2, 2] [2, 3])
               )
           ,
               ( "optimizer constrained QP"
               , right
                    (\r -> nearList (O.optPoint r) [1] && O.optGradientNorm r < 1e-8)
                    (O.quadraticProgramming 100 1e-8 [[2]] [-4] [[1]] [1])
               )
           ,
               ( "optimizer unconstrained QP"
               , right (\r -> nearList (O.optPoint r) [2]) (O.quadraticProgramming 100 1e-8 [[2]] [-4] [] [])
               )
           ,
               ( "optimizer SLSQP"
               , right
                    (\r -> nearList (O.optPoint r) [1])
                    (O.slsqp opt quad gquad hquad [O.Equality (\x -> Right (x !! 0 - 1)) (const (Right [1]))] [0])
               )
           ,
               ( "optimizer COBYLA"
               , right
                    (\r -> nearList (O.optPoint r) [1])
                    (O.cobyla 0.5 (opt{O.optMaxEvaluations = 200000}) quad [\x -> Right (x !! 0 - 1)] [0])
               )
           ,
               ( "optimizer penalty"
               , right
                    (\r -> abs (O.optPoint r !! 0 - 1) < 1e-4)
                    ( O.constrainedMinimize
                        O.QuadraticPenalty
                        opt
                        quad
                        gquad
                        [O.Equality (\x -> Right (x !! 0 - 1)) (const (Right [1]))]
                        [0]
                    )
               )
           ,
               ( "optimizer augmented Lagrangian"
               , right
                    (\r -> abs (O.optPoint r !! 0 - 1) < 1e-4)
                    ( O.constrainedMinimize
                        O.AugmentedLagrangian
                        opt
                        quad
                        gquad
                        [O.Equality (\x -> Right (x !! 0 - 1)) (const (Right [1]))]
                        [0]
                    )
               )
           ,
               ( "optimizer interior point"
               , right
                    (\r -> abs (O.optPoint r !! 0 - 1) < 1e-3)
                    ( O.constrainedMinimize
                        O.InteriorPoint
                        opt
                        quad
                        gquad
                        [O.LessEqual (\x -> Right (x !! 0 - 1)) (const (Right [1]))]
                        [0]
                    )
               )
           ,
               ( "optimizer barrier rejects infeasible"
               , isLeft
                    ( O.constrainedMinimize
                        O.LogBarrier
                        opt
                        quad
                        gquad
                        [O.LessEqual (\x -> Right (x !! 0 - 1)) (const (Right [1]))]
                        [2]
                    )
               )
           , ("optimizer Pareto", O.paretoFront [[1, 2], [2, 1], [3, 3], [1, 2]] == Right [0, 1, 3])
           ,
               ( "optimizer weighted objective"
               , O.weightedObjective [0.25, 0.75] [const (Right 1), const (Right 3)] [] == Right 2.5
               )
           , ("optimizer schedules", O.learningRate (O.Warmup 4 (O.CosineAnnealing 1 0 10)) 0 == Right 0.25)
           ,
               ( "optimizer early stopping"
               , right O.stopped (O.earlyStopping 2 0 1 (O.EarlyStopping (Just 0) 1 False))
               )
           ,
               ( "optimizer line searches"
               , all
                    (\method -> right (\(_, y, _, _) -> y < 2) (O.lineSearch method 80 quad gquad [3] [-2] 1 [2]))
                    [O.Armijo, O.StrongWolfe]
               )
           ,
               ( "optimizer rejects gradient shape"
               , isLeft (O.minimizeGradient O.Adam opt quad (const (Right [])) [1])
               )
           , ("optimizer rejects NaN", isLeft (O.minimizeGradient O.Adam opt quad (const (Right [0 / 0])) [1]))
           ,
               ( "optimizer budget exhaustion"
               , isLeft (O.minimizeGradient O.Adam (opt{O.optMaxEvaluations = 1}) quad gquad [1])
               )
           ]
        ++ [ ( "global optimizer " ++ show method
             , right
                (\r -> O.optValue r < 0.2)
                (O.globalMinimize method 12 123 (O.OptimizeOptions 150 10000 1e-5 0.1) [(-5, 5)] quad)
             )
           | method <-
                [O.SimulatedAnnealing, O.DifferentialEvolution, O.GeneticAlgorithm, O.ParticleSwarm, O.CMAES]
           ]
        ++ [
               ( "global reproducibility"
               , let solve =
                        O.globalMinimize O.DifferentialEvolution 8 123 (O.OptimizeOptions 20 1000 1e-5 0.1) [(-5, 5)] quad
                  in solve == solve
               )
           ]

deepTests :: [(String, Bool)]
deepTests =
    [ ( "activation derivative " ++ show kind
      , right
            ( \d ->
                right
                    (\a -> right (\b -> abs (d - (a - b) / 2e-5) < 1e-5) (D.activation kind (0.7 - 1e-5)))
                    (D.activation kind (0.7 + 1e-5))
            )
            (D.activationDerivative kind 0.7)
      )
    | kind <-
        [ D.Sigmoid
        , D.Tanh
        , D.ReLU
        , D.LeakyReLU 0.1
        , D.PReLU 0.2
        , D.ELU 1
        , D.SELU
        , D.GELU
        , D.SiLU
        , D.Mish
        , D.Softplus
        , D.Softsign
        , D.HardSigmoid
        , D.HardSwish
        ]
    ]
        ++ [ ( "activation gradient tape " ++ show kind
             , right (< 1e-5) (A.gradientCheck 1e-5 (\x -> D.activationExpr kind (x !! 0)) [0.7])
             )
           | kind <- [D.Sigmoid, D.GELU, D.SiLU, D.Mish, D.Softplus]
           ]
        ++ [
               ( "activation extreme sigmoid"
               , D.activation D.Sigmoid (-1000) == Right 0 && D.activation D.Sigmoid 1000 == Right 1
               )
           , ("activation extreme GELU derivative", D.activationDerivative D.GELU 1e308 == Right 1)
           , ("stable softmax", right (nearList [0.5, 0.5]) (D.softmax [1000, 1000]))
           , ("stable log softmax", right (nearList [log 0.5, log 0.5]) (D.logSoftmax [-1000, -1000]))
           , ("sparsemax projection", right (nearList [0, 0, 1]) (D.sparsemax [0, 1, 3]))
           , ("GLU", right (nearList [1, 2]) (D.gatedLinearUnit [2, 4] [0, 0]))
           ,
               ( "MSE MAE Huber SmoothL1"
               , and
                    [ right (near value) (D.loss kind D.Mean [1, 2] [2, 4])
                    | (kind, value) <-
                        [(D.MeanSquaredError, 2.5), (D.MeanAbsoluteError, 1.5), (D.Huber 1, 1), (D.SmoothL1 1, 1)]
                    ]
               )
           ,
               ( "BCE CCE NLL KL"
               , right (near (log 2)) (D.loss D.BinaryCrossEntropy D.Mean [1, 0] [0.5, 0.5])
                    && right (near (log 2)) (D.loss D.CategoricalCrossEntropy D.Sum [1, 0] [0.5, 0.5])
                    && right (near (log 2)) (D.loss D.NegativeLogLikelihood D.Sum [1, 0] [log 0.5, log 0.5])
                    && D.loss D.KLDivergence D.Sum [0.5, 0.5] [0.5, 0.5] == Right 0
               )
           ,
               ( "loss analytic gradient"
               , right (< 1e-5) (A.gradientCheck 1e-5 (D.lossExpr (D.Huber 1) D.Mean [1, 2]) [1.5, 4])
               )
           ,
               ( "loss cosine hinge ranking"
               , right (near 0) (D.loss D.CosineLoss D.Sum [1, 0] [2, 0])
                    && D.loss (D.Hinge 1) D.Sum [1, -1] [2, -2] == Right 0
                    && D.marginRankingLoss 1 [1] [3] [1] == Right 0
               )
           , ("loss BCE logits extreme", D.binaryCrossEntropyLogits D.Mean [1, 0] [1000, -1000] == Right 0)
           ,
               ( "loss categorical logits extreme"
               , right (near (log 2)) (D.categoricalCrossEntropyLogits [1, 0] [1000, 1000])
               )
           ,
               ( "loss contrastive triplet"
               , D.contrastiveLoss 1 True [1, 2] [1, 2] == Right 0 && D.tripletLoss 1 [0] [0] [2] == Right 0
               )
           ,
               ( "loss focal dice IoU"
               , right (> 0) (D.focalLoss 0.25 2 [1, 0] [0.8, 0.2])
                    && D.diceLoss 1 [1, 0] [1, 0] == Right 0
                    && D.iouLoss 1 [1, 0] [1, 0] == Right 0
               )
           , ("loss elastic net", D.regularization 1 2 [1, -2] == Right 8)
           ,
               ( "CTC independent alignments"
               , right (near (-log 0.84)) (D.ctcLoss 0 [1] (map (map log) [[0.4, 0.6], [0.4, 0.6]]))
               )
           ,
               ( "CTC repeated labels impossible"
               , isLeft (D.ctcLoss 0 [1, 1] (map (map log) [[0.5, 0.5], [0.5, 0.5]]))
               )
           ,
               ( "CTC posterior time sums"
               , right
                    (\(_, gs) -> all (near (-1) . sum) gs)
                    (D.ctcLossGradient 0 [1] (map (map log) [[0.4, 0.6], [0.4, 0.6]]))
               )
           ,
               ( "dropout reproducibility"
               , tensorTest
                    [2, 3]
                    [1 .. 6]
                    (D.dropout D.Training 0.5 rng)
                    (\(a, m, _) -> T.tensorValues a == zipWith (*) [1 .. 6] (T.tensorValues m))
               )
           ,
               ( "dropout inference"
               , tensorTest
                    [2]
                    [1, 2]
                    (D.dropout D.Inference 0.9 rng)
                    (\(a, m, s) -> T.tensorValues a == [1, 2] && T.tensorValues m == [1, 1] && s == rng)
               )
           ,
               ( "spatial dropout shared channel mask"
               , tensorTest
                    [1, 2, 3]
                    [1 .. 6]
                    (D.spatialDropout D.Training 0.5 rng)
                    ( \(_, m, _) ->
                        let xs = T.tensorValues m
                         in xs !! 0 == xs !! 1 && xs !! 1 == xs !! 2 && xs !! 3 == xs !! 4 && xs !! 4 == xs !! 5
                    )
               )
           ,
               ( "batch norm training state"
               , tensorTest
                    [2, 1]
                    [1, 3]
                    (D.batchNorm D.Training 0.5 1e-5 [1] [0] (D.BatchNormState [0] [1] 0))
                    ( \(a, s) ->
                        abs (sum (T.tensorValues a)) < 1e-10
                            && D.runningMean s == [1]
                            && D.runningVariance s == [1.5]
                            && D.batchesSeen s == 1
                    )
               )
           ,
               ( "batch norm inference"
               , tensorTest
                    [1, 1]
                    [3]
                    (D.batchNorm D.Inference 0.5 1 [1] [0] (D.BatchNormState [1] [3] 5))
                    (\(a, s) -> T.tensorValues a == [1] && D.batchesSeen s == 5)
               )
           ,
               ( "layer norm degenerate"
               , tensorTest [2, 2] [3, 3, 4, 4] (D.layerNorm 1 1e-5) (\a -> T.tensorValues a == [0, 0, 0, 0])
               )
           ,
               ( "instance group RMS normalization"
               , tensorTest
                    [1, 2, 2]
                    [1, 3, 2, 4]
                    ( \a -> do i <- D.instanceNorm 1e-5 a; g <- D.groupNorm 2 1e-5 a; r <- D.rmsNorm 1 1e-5 a; Right (i, g, r)
                    )
                    (\(i, g, r) -> T.tensorValues i == T.tensorValues g && all (> 0) (T.tensorValues r))
               )
           ,
               ( "weight norm"
               , tensorTest
                    [2, 2]
                    [3, 4, 0, 2]
                    (D.weightNorm 0 [10, 6])
                    (\a -> nearList (T.tensorValues a) [6, 8, 0, 6])
               )
           ,
               ( "initializers finite"
               , all
                    ( \kind -> right (\(a, _) -> length (T.tensorValues a) == 12) (D.initializeWeights kind 3 4 [4, 3] rng)
                    )
                    [ D.XavierUniform
                    , D.XavierNormal
                    , D.KaimingUniform
                    , D.KaimingNormal
                    , D.TruncatedNormal 0 1 2
                    , D.Orthogonal 1
                    ]
               )
           ,
               ( "orthogonal initializer"
               , right
                    ( \(a, _) ->
                        let rows = [[T.tensorValues a !! (i * 2 + j) | j <- [0, 1]] | i <- [0, 1]]
                         in all (near 1 . sum . map (\x -> x * x)) rows && near 0 (sum (zipWith (*) (rows !! 0) (rows !! 1)))
                    )
                    (D.initializeWeights (D.Orthogonal 1) 2 2 [2, 2] rng)
               )
           ,
               ( "embedding"
               , tensorTest [3, 2] [1 .. 6] (\a -> D.embedding a [2, 0]) (\a -> T.tensorValues a == [5, 6, 1, 2])
               )
           ,
               ( "dense"
               , right
                    (\a -> T.tensorValues a == [9, 19])
                    (do x <- T.tensor [1, 2] [2, 3]; w <- T.tensor [2, 2] [1, 2, 3, 4]; D.dense x w [1, 1])
               )
           ,
               ( "convolution 1D"
               , right
                    (\a -> T.tensorValues a == [8, 13])
                    ( do
                        x <- T.tensor [1, 1, 3] [1, 2, 3]
                        w <- T.tensor [1, 1, 2] [2, 3]
                        D.convolution (D.ConvOptions [1] [0] [1] 1) x w [0]
                    )
               )
           ,
               ( "convolution 2D"
               , right
                    (\a -> T.tensorValues a == [10])
                    ( do
                        x <- T.tensor [1, 1, 2, 2] [1, 2, 3, 4]
                        w <- T.tensor [1, 1, 2, 2] [1, 1, 1, 1]
                        D.convolution (D.ConvOptions [1, 1] [0, 0] [1, 1] 1) x w [0]
                    )
               )
           ,
               ( "convolution 3D"
               , right
                    (\a -> T.tensorValues a == [36])
                    ( do
                        x <- T.tensor [1, 1, 2, 2, 2] [1 .. 8]
                        w <- T.tensor [1, 1, 2, 2, 2] (replicate 8 1)
                        D.convolution (D.ConvOptions [1, 1, 1] [0, 0, 0] [1, 1, 1] 1) x w [0]
                    )
               )
           ,
               ( "transposed convolution"
               , right
                    (\a -> T.tensorValues a == [2, 7, 6])
                    ( do
                        x <- T.tensor [1, 1, 2] [1, 2]
                        w <- T.tensor [1, 1, 2] [2, 3]
                        D.transposedConvolution [0] (D.ConvOptions [1] [0] [1] 1) x w [0]
                    )
               )
           ,
               ( "depthwise convolution"
               , right
                    (\a -> T.tensorValues a == [3, 12])
                    ( do
                        x <- T.tensor [1, 2, 2] [1, 2, 3, 4]
                        w <- T.tensor [2, 1, 2] [1, 1, 0, 3]
                        D.depthwiseConvolution (D.ConvOptions [1] [0] [1] 1) x w [0, 0]
                    )
               )
           ,
               ( "convolution AD"
               , right
                    (nearList [2, 5, 3])
                    ( do
                        x <- A.adTensor [1, 1, 3] (map A.variable [0, 1, 2])
                        w <- A.adTensor [1, 1, 2] (map A.constant [2, 3])
                        y <- D.convolutionAD (D.ConvOptions [1] [0] [1] 1) x w [0]
                        A.gradient (const (A.adSum y)) [1, 2, 3]
                    )
               )
           ,
               ( "max average pooling"
               , tensorTest
                    [1, 1, 4]
                    [1, 3, 2, 4]
                    ( \x -> do a <- D.pooling D.MaxPool [2] [2] [0] x; b <- D.pooling D.AveragePool [2] [2] [0] x; Right (a, b)
                    )
                    (\(a, b) -> T.tensorValues a == [3, 4] && T.tensorValues b == [2, 3])
               )
           ,
               ( "adaptive global pooling"
               , tensorTest
                    [1, 1, 4]
                    [1, 3, 2, 4]
                    (\x -> do a <- D.adaptivePooling D.AveragePool [2] x; b <- D.globalPooling D.MaxPool x; Right (a, b))
                    (\(a, b) -> T.tensorValues a == [2, 3] && T.tensorValues b == [4])
               )
           ,
               ( "attention weighted sum"
               , right
                    (\(a, w) -> nearList (T.tensorValues a) [3, 4] && nearList (T.tensorValues w) [0.5, 0.5])
                    ( do
                        q <- T.tensor [1, 2] [0, 0]
                        k <- T.tensor [2, 2] [1, 0, 0, 1]
                        v <- T.tensor [2, 2] [1, 2, 5, 6]
                        D.scaledDotProductAttention q k v Nothing Nothing
                    )
               )
           ,
               ( "attention fully masked"
               , right
                    (\(a, w) -> T.tensorValues a == [0] && T.tensorValues w == [0, 0])
                    ( do
                        q <- T.tensor [1, 1] [1]
                        k <- T.tensor [2, 1] [1, 2]
                        v <- T.tensor [2, 1] [3, 4]
                        D.scaledDotProductAttention q k v (Just [[False, False]]) Nothing
                    )
               )
           ,
               ( "multihead attention"
               , right
                    (\a -> nearList (T.tensorValues a) [3, 4])
                    ( do
                        q <- T.tensor [1, 2] [0, 0]
                        k <- T.tensor [2, 2] [1, 0, 0, 1]
                        v <- T.tensor [2, 2] [1, 2, 5, 6]
                        D.multiheadAttention 2 q k v Nothing
                    )
               )
           ,
               ( "causal mask and ALiBi"
               , D.causalMask 2 2 0 == Right [[True, False], [True, True]] && D.alibiBias 1 1 2 0 == Right [[0, -1]]
               )
           ,
               ( "rotary preserves norm"
               , tensorTest
                    [2, 2]
                    [1, 2, 3, 4]
                    (D.rotaryEmbedding 10000 1)
                    (\a -> near (sum (map (\x -> x * x) (T.tensorValues a))) 30)
               )
           , ("sinusoidal encoding", right (\a -> T.tensorValues a == [0, 1]) (D.sinusoidalEncoding 1 2 0))
           ,
               ( "KV cache capacity"
               , right
                    ( \c ->
                        right
                            (\d -> let (k, _) = D.cacheValues d in T.tensorShape k == [1, 2])
                            (do k <- T.tensor [1, 2] [1, 2]; v <- T.tensor [1, 1] [3]; D.appendCache c k v)
                    )
                    (D.emptyCache 2 2 1)
               )
           ,
               ( "transformer FFN"
               , right
                    (\a -> T.tensorValues a == [3])
                    ( do
                        x <- T.tensor [1, 1] [1]
                        w1 <- T.tensor [1, 1] [2]
                        w2 <- T.tensor [1, 1] [1]
                        D.transformerFeedForward D.ReLU x w1 [0] w2 [1]
                    )
               )
           ,
               ( "quantization per tensor"
               , tensorTest
                    [3]
                    [-2, 0, 2]
                    (D.quantize D.Symmetric Nothing >=> D.dequantize)
                    (\a -> nearList (T.tensorValues a) [-2, 0, 2])
               )
           ,
               ( "quantization per channel"
               , tensorTest
                    [2, 2]
                    [-1, 1, -10, 10]
                    (D.quantize D.Asymmetric (Just 0) >=> D.dequantize)
                    (\a -> and (zipWith (\x y -> abs (x - y) < 0.1) (T.tensorValues a) [-1, 1, -10, 10]))
               )
           ,
               ( "INT8 GEMM"
               , right
                    (\a -> abs (T.tensorValues a !! 0 - 11) < 0.2)
                    ( do
                        a <- T.tensor [1, 2] [1, 2] >>= D.quantize D.Symmetric Nothing
                        b <- T.tensor [2, 1] [3, 4] >>= D.quantize D.Symmetric Nothing
                        D.int8Gemm a b
                    )
               )
           ,
               ( "FP16 BF16 GEMM"
               , all
                    ( \precision ->
                        right
                            (\a -> T.tensorValues a == [11])
                            (do a <- T.tensor [1, 2] [1, 2]; b <- T.tensor [2, 1] [3, 4]; D.reducedGemm precision a b)
                    )
                    [D.FP16, D.BF16]
               )
           ,
               ( "mixed precision overflow skip"
               , right
                    ( \s ->
                        D.unscaleGradients s [1 / 0] == Right (False, [])
                            && D.unscaleGradients s [16, 32] == Right (True, [1, 2])
                            && right (\t -> D.lossScale t == 8) (D.updateLossScaler False s)
                    )
                    (D.initialLossScaler 16 2)
               )
           ,
               ( "gradient norm clip"
               , D.gradientNorm [3, 4] == Right 5 && right (nearList [0.6, 0.8]) (D.clipGradients 1 [3, 4])
               )
           ,
               ( "classification confusion precision recall F1"
               , D.confusionMatrix 2 [0, 0, 1, 1] [0, 1, 1, 1] == Right [[1, 1], [0, 2]]
                    && right
                        (\m -> near (D.accuracy m) 0.75 && nearList (D.precisionByClass m) [1, 2 / 3])
                        (D.classificationMetrics 2 [0, 0, 1, 1] [0, 1, 1, 1])
               )
           ,
               ( "ROC PR AUC ties"
               , D.rocAUC [True, False] [0.5, 0.5] == Right 0.5 && D.prAUC [True, False] [0.9, 0.1] == Right 1
               )
           , ("top K", D.topKAccuracy 2 [2, 0] [[1, 2, 3], [3, 2, 1]] == Right 1)
           ,
               ( "perplexity cosine matrix"
               , right (near 2) (D.perplexity [log 0.5, log 0.5])
                    && right
                        (\a -> nearList (T.tensorValues a) [0])
                        (do a <- T.tensor [1, 2] [1, 0]; b <- T.tensor [1, 2] [0, 1]; D.cosineSimilarityMatrix a b)
               )
           ,
               ( "DL shape finite contracts"
               , isLeft (D.softmax [0 / 0])
                    && isLeft (D.loss D.BinaryCrossEntropy D.Sum [1] [0])
                    && isLeft (D.batchNorm D.Training 0.5 1e-5 [] [] (D.BatchNormState [] [] 0) =<< T.tensor [1, 0] [])
               )
           ]
  where
    (>=>) f g x = f x >>= g

-- Numerical and API regressions found by independent cross-review.
regressionTests :: [(String, Bool)]
regressionTests =
    [
        ( "root already-converged system consumes no Jacobian"
        , right
            (\r -> R.systemEvaluations r == 1)
            ( R.solveSystem
                R.MultivariateNewton
                (rOpt{R.rootMaxEvaluations = 1})
                (const [0])
                (const [[0 / 0]])
                [1]
            )
        )
    ,
        ( "root initial Jacobian budget"
        , isLeft
            (R.solveSystem R.MultivariateNewton (rOpt{R.rootMaxEvaluations = 1}) (const [1]) (const [[1]]) [1])
        )
    ,
        ( "root secant reports no unproved error bound"
        , right (\r -> R.rootErrorBound r == Nothing) (R.secant rOpt (\x -> x * x - 2) 1 2)
        )
    ,
        ( "optimizer callback explicit stopping"
        , right
            (\r -> O.optIterations r == 0 && not (O.optConverged r))
            (O.minimizeGradientWithCallback (const (Right False)) O.Adam opt quad gquad [4])
        )
    ,
        ( "optimizer SQP drops negative inequality multiplier"
        , right
            (\r -> nearList (O.optPoint r) [2])
            (O.slsqp opt quad gquad hquad [O.LessEqual (\x -> Right (x !! 0 - 4)) (const (Right [1]))] [4])
        )
    ,
        ( "optimizer SQP enforces merit budget"
        , isLeft
            ( O.slsqp
                (opt{O.optMaxEvaluations = 6})
                quad
                gquad
                hquad
                [O.Equality (\x -> Right (x !! 0 - 1)) (const (Right [1]))]
                [0]
            )
        )
    ,
        ( "optimizer barrier enforces nested callback budget"
        , isLeft
            ( O.constrainedMinimize
                O.InteriorPoint
                (opt{O.optMaxEvaluations = 5})
                quad
                gquad
                [O.LessEqual (\x -> Right (x !! 0 - 1)) (const (Right [1]))]
                [0]
            )
        )
    ,
        ( "optimizer COBYLA enforces model budget"
        , isLeft (O.cobyla 1 (opt{O.optMaxEvaluations = 7}) quad [\x -> Right (x !! 0 - 1)] [0])
        )
    ,
        ( "optimizer CMAES rotated anisotropic covariance"
        , right
            (\r -> O.optValue r < 1e-8 && nearList (O.optPoint r) [1, 2])
            ( O.globalMinimize
                O.CMAES
                16
                42
                (O.OptimizeOptions 400 10000 1e-8 0.1)
                [(-5, 5), (-5, 5)]
                (\x -> Right (10000 * (x !! 0 + x !! 1 - 3) ^ (2 :: Int) + (x !! 0 - x !! 1 + 1) ^ (2 :: Int)))
            )
        )
    ,
        ( "optimizer basin hopping local descents"
        , right (\r -> O.optValue r < 1e-6) (O.basinHopping 7 1 2 opt [(-5, 5)] quad [4])
        )
    ,
        ( "AD checkpoint numerical equivalence"
        , let f x = sin (x !! 0) * x !! 1 + exp (x !! 1)
           in A.valueAndGradient f [1, 2] == A.valueAndGradient (\x -> A.checkpoint f x) [1, 2]
        )
    ,
        ( "DL softmax graph coupled gradients"
        , right
            (< 1e-6)
            (A.gradientCheck 1e-5 (\xs -> sum (zipWith (*) [1, 2, 3] (D.softmaxExpr xs))) [1, 2, 3])
        )
    ,
        ( "DL log-softmax graph gradients"
        , right (< 1e-6) (A.gradientCheck 1e-5 (sum . D.logSoftmaxExpr) [1, 2, 3])
        )
    ,
        ( "DL sparsemax graph active support"
        , right
            (< 1e-6)
            (A.gradientCheck 1e-5 (\xs -> sum (zipWith (*) [1, 2, 3] (D.sparsemaxExpr xs))) [0, 0.1, 0.2])
        )
    ,
        ( "DL CTC three-step graph gradients"
        , right
            (< 1e-5)
            ( A.gradientCheck
                1e-5
                ( \xs -> case D.ctcLossExpr 0 [1] [take 2 xs, take 2 (drop 2 xs), drop 4 xs] of
                    Right y -> y
                    Left _ -> A.constant (0 / 0)
                )
                (map log [0.3, 0.7, 0.4, 0.6, 0.6, 0.4])
            )
        )
    ,
        ( "DL layer normalization graph gradients"
        , right
            (< 1e-5)
            ( A.gradientCheck
                1e-5
                ( \xs -> case A.adTensor [1, 3] xs >>= D.layerNormAD 1 1e-5 of
                    Right y -> sum (zipWith (*) [1, 2, 3] (A.adValues y))
                    Left _ -> A.constant (0 / 0)
                )
                [1, 2, 4]
            )
        )
    ,
        ( "DL RMS normalization graph gradients"
        , right
            (< 1e-5)
            ( A.gradientCheck
                1e-5
                ( \xs -> case A.adTensor [1, 3] xs >>= D.rmsNormAD 1 1e-5 of
                    Right y -> sum (zipWith (*) [1, 2, 3] (A.adValues y))
                    Left _ -> A.constant (0 / 0)
                )
                [1, 2, 4]
            )
        )
    ,
        ( "DL attention graph query/key/value gradients"
        , right (< 1e-5) (A.gradientCheck 1e-5 attentionFunction [1, 2, 3, 4, 5])
        )
    ,
        ( "DL fully masked attention graph zero gradients"
        , right (nearList (replicate 5 0)) (A.gradient maskedAttention [1, 2, 3, 4, 5])
        )
    ,
        ( "DL cosine scale invariant at huge finite inputs"
        , right (near 0) (D.loss D.CosineLoss D.Sum [1e308] [1])
        )
    , ("DL zero regularization avoids intermediate overflow", D.regularization 0 0 [1e308] == Right 0)
    , ("DL triplet unrepresentable distance fails", isLeft (D.tripletLoss 1 [1e308] [-1e308] [1e308]))
    ,
        ( "DL adaptive pooling zero batch"
        , tensorTest
            [0, 1, 3]
            []
            (D.adaptivePooling D.MaxPool [2])
            (\y -> T.tensorShape y == [0, 1, 2] && null (T.tensorValues y))
        )
    ,
        ( "DL adaptive pooling zero channels"
        , tensorTest
            [1, 0, 3]
            []
            (D.adaptivePooling D.AveragePool [2])
            (\y -> T.tensorShape y == [1, 0, 2] && null (T.tensorValues y))
        )
    ,
        ( "DL convolution padding overflow rejected"
        , isLeft
            ( do
                x <- T.tensor [1, 1, 1] [1]
                w <- T.tensor [1, 1, 1] [1]
                D.convolution (D.ConvOptions [1] [maxBound] [1] 1) x w [0]
            )
        )
    ,
        ( "DL transposed convolution stride overflow rejected"
        , isLeft
            ( do
                x <- T.tensor [1, 1, 3] [1, 2, 3]
                w <- T.tensor [1, 1, 1] [1]
                D.transposedConvolution [0] (D.ConvOptions [maxBound] [0] [1] 1) x w [0]
            )
        )
    ,
        ( "DL pooling padding overflow rejected"
        , tensorTest [1, 1, 1] [1] (\x -> Right (isLeft (D.pooling D.MaxPool [1] [1] [maxBound] x))) id
        )
    ,
        ( "DL positional offsets do not wrap"
        , D.causalMask 2 1 maxBound == Right [[True], [True]]
            && right (\rows -> all (< 0) (concat rows)) (D.alibiBias 1 2 1 maxBound)
        )
    , ("DL ALiBi arithmetic overflow rejected", isLeft (D.alibiBias 1e308 1 1 maxBound))
    ,
        ( "DL positional encoding huge offset finite"
        , right (\t -> length (T.tensorValues t) == 4) (D.sinusoidalEncoding 2 2 maxBound)
        )
    ,
        ( "DL quantization invalid channel axis"
        , tensorTest [2] [1, 2] (\x -> Right (isLeft (D.quantize D.Asymmetric (Just 1) x))) id
        )
    ,
        ( "DL FP16 overflow rejects"
        , isLeft (do a <- T.tensor [1, 1] [1e10]; b <- T.tensor [1, 1] [1]; D.reducedGemm D.FP16 a b)
        )
    ,
        ( "DL cache rejects overflow"
        , isLeft (do c <- D.emptyCache 1 1 1; k <- T.tensor [2, 1] [1, 2]; D.appendCache c k k)
        )
    , ("DL ROC invalid one-class sample", isLeft (D.rocAUC [True, True] [0.1, 0.9]))
    ]
  where
    attentionFunction xs = case do
        q <- A.adTensor [1, 1] [xs !! 0]
        k <- A.adTensor [2, 1] [xs !! 1, xs !! 2]
        v <- A.adTensor [2, 1] [xs !! 3, xs !! 4]
        D.scaledDotProductAttentionAD q k v Nothing of
        Right y -> A.adSum y
        Left _ -> A.constant (0 / 0)
    maskedAttention xs = case do
        q <- A.adTensor [1, 1] [xs !! 0]
        k <- A.adTensor [2, 1] [xs !! 1, xs !! 2]
        v <- A.adTensor [2, 1] [xs !! 3, xs !! 4]
        D.scaledDotProductAttentionAD q k v (Just [[False, False]]) of
        Right y -> A.adSum y
        Left _ -> A.constant (0 / 0)

boundaryTests :: [(String, Bool)]
boundaryTests =
    [
        ( "Broyden exact tiny root before update"
        , right
            (\r -> near (R.systemRoot r !! 0 * 1e200) 1 && R.systemResidual r < 1e-10)
            (R.solveSystem R.Broyden rOpt (\x -> [1e200 * x !! 0 - 1]) (const [[1e200]]) [0])
        )
    ,
        ( "Golden initial callback budget"
        , isLeft
            ( O.minimizeScalar
                O.GoldenSection
                (opt{O.optMaxEvaluations = 1, O.optTolerance = 1})
                (\x -> Right (x * x))
                0
                1
            )
        )
    ,
        ( "least squares validates initial parameters"
        , isLeft (O.leastSquares O.SquaredLoss 0 opt (const (Right [0])) (const (Right [[0]])) [0 / 0])
        )
    ,
        ( "least squares rejects infinite robust objective"
        , isLeft (O.leastSquares O.SquaredLoss 0 opt (const (Right [1e200])) (const (Right [[0]])) [0])
        )
    ,
        ( "minibatch avoids preventable mean overflow"
        , right (nearList [1e308]) (O.miniBatchGradient [const (Right [1e308]), const (Right [1e308])] [0])
        )
    ,
        ( "Adam rejects nonfinite moment state"
        , isLeft (O.initializeOptimizer 1 >>= \state -> O.optimizerStep O.Adam 0.1 state [0] [1e308])
        )
    ,
        ( "SGD empty pass validates parameters and rate"
        , isLeft (O.stochasticGradient O.Adam 0.1 [] [0 / 0])
            && isLeft (O.stochasticGradient O.Adam (-1) [] [0])
        )
    ,
        ( "minibatch validates ignored nonfinite point"
        , isLeft (O.miniBatchGradient [const (Right [0])] [0 / 0])
        )
    ,
        ( "optimizer result validates unrepresentable norm"
        , isLeft
            (O.result 0 0 False (const (Right 0)) (const (Right [1e308, 1e308, 1e308, 1e308])) [0, 0, 0, 0])
        )
    ,
        ( "dual negative base constant power"
        , let (value, derivative) = A.forward (\x -> x ** 2) (-2 :: Double)
           in near value 4 && near derivative (-4)
        )
    , ("AD negative base constant power", right (nearList [-4]) (A.gradient (\x -> x !! 0 ** 2) [-2]))
    ,
        ( "AD higher derivative negative base power"
        , right (\h -> and (zipWith nearList h [[-12]])) (A.hessian (\x -> x !! 0 ** 3) [-2])
        )
    , ("AD zero constant power derivative", right (nearList [0]) (A.gradient (\x -> x !! 0 ** 0) [0]))
    , ("AD Hessian rejects invalid original primal", isLeft (A.hessian (const (A.constant (0 / 0))) [0]))
    , ("AD Hessian rejects invalid unused input", isLeft (A.hessian (const 1) [0 / 0]))
    ]
