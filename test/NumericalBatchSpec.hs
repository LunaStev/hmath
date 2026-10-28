-- SPDX-License-Identifier: MPL-2.0
module NumericalBatchSpec (numericalBatchTests) where

import Data.Complex (Complex ((:+)))
import HMath.Calculus
import HMath.Error
import HMath.Matrix (Matrix, toList)
import HMath.ODE

numericalBatchTests :: [(String, Bool)]
numericalBatchTests =
    [
        ( "central differentiation analytic sine"
        , closeResult 1e-9 (cos 0.4) (derivative Central 1e-5 sin 0.4)
        )
    ,
        ( "one-sided differences check only sampled direction"
        , derivative Backward 1 id (2 ** 53) == Right 1 && isFailure (derivative Forward 1 id (2 ** 53))
        )
    ,
        ( "Romberg validates budget before evaluating callback"
        , isFailure (romberg (Tolerance 1e-6 0 1) (error "budget must be validated first") 0 1)
        )
    ,
        ( "one-sided derivatives converge"
        , all (\method -> closeResult 1e-4 6 (derivative method 1e-5 (\x -> x * x) 3)) [Forward, Backward]
        )
    ,
        ( "higher centered differences recover cubic derivatives"
        , closeResult 1e-5 6 (derivativeN 3 0.01 (\x -> x * x * x) 2)
        )
    ,
        ( "complex-step avoids subtractive cancellation"
        , closeResult 1e-13 (exp 0.5) (complexDerivative 1e-100 exp 0.5)
        )
    ,
        ( "Richardson and Ridders use analytic exponential"
        , all (\method -> estimateClose 1e-9 (exp 0.5) (method tol 0.1 exp 0.5)) [richardson, ridders]
        )
    ,
        ( "one-sided numerical limits"
        , estimateClose 1e-7 2 (limit Forward tol 0.1 (\x -> if x == 1 then 17 else (x * x - 1) / (x - 1)) 1)
        )
    ,
        ( "gradient analytic polynomial"
        , vectorResult
            1e-7
            [4, 6]
            (gradient 1e-4 (\x -> (x !! 0) ^ (2 :: Int) + 3 * (x !! 1) ^ (2 :: Int)) [2, 1])
        )
    ,
        ( "Jacobian analytic mixed polynomial"
        , matrixResult
            1e-6
            [3, 2, 4, 1]
            (jacobian 1e-4 (\x -> [x !! 0 * x !! 1, (x !! 0) ^ (2 :: Int) + x !! 1]) [2, 3])
        )
    ,
        ( "Hessian analytic quadratic form"
        , matrixResult
            1e-6
            [2, 3, 3, 4]
            (hessian 1e-3 (\x -> (x !! 0) ^ (2 :: Int) + 3 * x !! 0 * x !! 1 + 2 * (x !! 1) ^ (2 :: Int)) [1, 2])
        )
    ,
        ( "JVP agrees with analytic directional map"
        , vectorResult
            1e-6
            [14, 12]
            (jvp 1e-4 (\x -> [x !! 0 * x !! 1, (x !! 0) ^ (2 :: Int) + x !! 1]) [2, 3] [2, 4])
        )
    ,
        ( "VJP agrees with analytic transpose contraction"
        , vectorResult
            1e-6
            [14, 6]
            (vjp 1e-4 (\x -> [x !! 0 * x !! 1, (x !! 0) ^ (2 :: Int) + x !! 1]) [2, 3] [2, 2])
        )
    ,
        ( "HVP and directional derivative"
        , vectorResult
            1e-5
            [4, 12]
            (hvp 1e-3 (\x -> (x !! 0) ^ (2 :: Int) + 3 * (x !! 1) ^ (2 :: Int)) [2, 1] [2, 2])
            && closeResult 1e-7 12 (directionalDerivative 1e-4 sum [1, 2] [5, 7])
        )
    ,
        ( "divergence curl Laplacian analytic fields"
        , closeResult 1e-7 6 (divergence 1e-4 id [1, 2, 3, 4, 5, 6])
            && vectorResult 1e-7 [0, 0, 2] (curl 1e-4 (\x -> [-(x !! 1), x !! 0, 0]) [1, 2, 3])
            && closeResult 1e-5 6 (laplacian 1e-3 (sum . map (^ (2 :: Int))) [1, 2, 3])
        )
    ,
        ( "all composite rules integrate linear functions"
        , all
            (\method -> closeResult 1e-12 1 (integrateComposite method 12 (\x -> 2 * x) 0 1))
            [Trapezoidal, Simpson, ThreeEighths]
        )
    ,
        ( "Simpson and 3/8 cubic exactness"
        , all
            (\method -> closeResult 1e-12 0.25 (integrateComposite method 12 (\x -> x * x * x) 0 1))
            [Simpson, ThreeEighths]
        )
    , ("Romberg integration analytic sine", estimateClose 1e-10 2 (romberg tol sin 0 pi))
    ,
        ( "Gauss-Legendre polynomial exactness"
        , all (\n -> closeResult 1e-12 (2 / 5) (gaussLegendre n (\x -> x ^ (4 :: Int)) (-1) 1)) [3 .. 10]
        )
    ,
        ( "Gaussian Hermite and Laguerre weighted moments"
        , closeResult 1e-11 (3 * sqrt pi / 4) (gaussHermite 5 (\x -> x ^ (4 :: Int)))
            && closeResult 1e-10 24 (gaussLaguerre 5 (\x -> x ^ (4 :: Int)))
        )
    , ("Chebyshev weighted moment", closeResult 1e-12 (pi / 2) (gaussChebyshev 8 (\x -> x * x)))
    ,
        ( "embedded and adaptive Gauss-Kronrod"
        , estimateClose 1e-12 (exp 1 - 1) (gaussKronrod exp 0 1)
            && estimateClose 1e-9 (pi / 4) (adaptiveIntegrate tol (\x -> 1 / (1 + x * x)) 0 1)
        )
    ,
        ( "Clenshaw-Curtis integrates nonpolynomial analytic case"
        , closeResult 1e-11 2 (clenshawCurtis 32 sin 0 pi)
        )
    ,
        ( "tanh-sinh handles endpoint square-root pole"
        , estimateClose 1e-6 2 (tanhSinh (Tolerance 1e-7 1e-7 100000) (\x -> 1 / sqrt x) 0 1)
        )
    ,
        ( "infinite interval maps exponential and Gaussian"
        , estimateClose 1e-8 1 (integrateInfinite tol (\x -> exp (-x)) 0 (1 / 0))
            && estimateClose 1e-8 (sqrt pi) (integrateInfinite tol (\x -> exp (-x * x)) (-1 / 0) (1 / 0))
        )
    ,
        ( "oscillatory quadrature resolves frequency"
        , estimateClose 1e-8 0 (integrateOscillatory True 100 tol (const 1) 0 (2 * pi))
        )
    ,
        ( "multiple and volume integrals"
        , closeResult 1e-12 1 (integrateND 4 1000 sum [(0, 1), (0, 1)])
            && closeResult 1e-12 1.5 (volumeIntegral 4 1000 sum [(0, 1), (0, 1), (0, 1)])
        )
    ,
        ( "Monte Carlo reproducible constant with zero variance"
        , monteCarlo 42 100 (const 3) [(0, 2)] == Right (Estimate 6 0 100)
        )
    ,
        ( "quasi Monte Carlo constant box volume"
        , estimateClose 1e-12 6 (quasiMonteCarlo 100 (const 3) [(0, 2)])
        )
    ,
        ( "cumulative integration on irregular coordinates"
        , cumulativeIntegral [(0, 0), (1, 2), (3, 6)] == Right [0, 1, 9]
        )
    ,
        ( "path and oriented line integrals"
        , estimateClose
            1e-9
            (2 * pi)
            (pathIntegral tol (\t -> [cos t, sin t]) (\t -> [-sin t, cos t]) (const 1) 0 (2 * pi))
            && estimateClose 1e-9 1 (lineIntegral tol (\t -> [t, t]) (const [1, 1]) id 0 1)
        )
    ,
        ( "surface integral plane area"
        , closeResult
            1e-12
            6
            ( surfaceIntegral
                4
                1000
                (\uv -> [uv !! 0, uv !! 1, 0])
                (const [1, 0, 0])
                (const [0, 1, 0])
                (const 1)
                [(0, 2), (0, 3)]
            )
        )
    ,
        ( "quadrature rejects invalid grids and budgets"
        , isFailure (integrateComposite Simpson 3 id 0 1)
            && isFailure (adaptiveIntegrate (Tolerance 1e-9 1e-9 14) exp 0 1)
            && isFailure (integrateND 10 9 sum [(0, 1)])
        )
    ,
        ( "differentiation rejects invalid steps and coordinates"
        , isFailure (derivative Central 0 sin 0)
            && isFailure (partialDerivative 3 0.1 sum [1, 2])
            && isFailure (derivative Central 0.1 (const (0 / 0)) 0)
        )
    ,
        ( "adaptive quadrature budget exhaustion is explicit"
        , case adaptiveIntegrate (Tolerance 1e-30 0 15) sin 0 pi of
            Left (NonConvergence _ _) -> True
            _ -> False
        )
    ,
        ( "fixed-step RK4 analytic decay"
        , trajectoryClose 1e-9 [exp (-1)] (solveIVP RK4 opts 100 decay 0 1 [1])
        )
    ,
        ( "fixed Euler one-panel numerical contract"
        , trajectoryClose 1e-12 [0] (solveIVP Euler opts 1 decay 0 1 [1])
        )
    ,
        ( "fixed explicit and multistep families converge"
        , all
            (\method -> trajectoryClose 0.003 [exp (-1)] (solveIVP method opts 200 decay 0 1 [1]))
            [ Euler
            , Heun
            , Midpoint
            , RK2
            , RK4
            , RK23
            , RK45
            , DormandPrince
            , DOP853
            , AdamsBashforth
            , AdamsMoulton
            , PredictorCorrector
            ]
        )
    ,
        ( "embedded adaptive methods analytic exponential"
        , all
            (\method -> trajectoryClose 2e-6 [exp 1] (solveAdaptive method opts (\_ y -> y) 0 1 [1]))
            [RK23, RK45, DormandPrince, DOP853]
        )
    ,
        ( "adaptive basic RK families"
        , all
            (\method -> trajectoryClose 2e-4 [exp (-1)] (solveAdaptive method opts decay 0 1 [1]))
            [Euler, Heun, Midpoint, RK2, RK4]
        )
    ,
        ( "backward integration reverses exponential decay"
        , trajectoryClose 1e-8 [1] (solveIVP RK4 opts 100 decay 1 0 [exp (-1)])
        )
    ,
        ( "implicit stiff methods dissipate fast decay"
        , all
            (\method -> trajectoryClose 1e-5 [0] (solveIVP method opts 100 (\_ y -> map ((-1000) *) y) 0 1 [1]))
            [BackwardEuler, BDF, Radau, Rosenbrock]
        )
    , ("cubic dense output and event roots", denseAndEvents)
    ,
        ( "DAE implicit residual integration"
        , trajectoryClose 0.003 [exp (-1)] (solveDAE opts 200 (\_ y d -> zipWith (+) y d) 0 1 [1] [-1])
        )
    ,
        ( "DAE rejects inconsistent initial state"
        , isFailure (solveDAE opts 10 (\_ y d -> zipWith (+) y d) 0 1 [1] [0])
        )
    ,
        ( "boundary shooting satisfies affine trajectory"
        , trajectoryClose
            1e-6
            [2]
            (solveBoundary RK4 opts 10 (\_ _ -> [1]) (\_ final -> [final !! 0 - 2]) 0 1 [0])
        )
    ,
        ( "symplectic methods bound oscillator energy"
        , all hamiltonianCase [SymplecticEuler, Verlet, Leapfrog]
        )
    ,
        ( "Runge-Kutta-Nystrom oscillator"
        , trajectoryClose 1e-7 [cos 1, -sin 1] (solveNystrom 100 (\_ q -> map negate q) 0 1 [1] [0])
        )
    ,
        ( "parameter sensitivities analytic exponential"
        , matrixResult
            1e-6
            [exp 0.5]
            (sensitivities RK4 opts 200 1e-4 (\p _ y -> map (p !! 0 *) y) [0.5] 0 1 [1])
        )
    ,
        ( "equilibrium and phase-space trajectories"
        , vectorResult 1e-6 [2] (equilibrium opts (\x -> [x !! 0 * x !! 0 - 4]) [3]) && case phaseTrajectories RK4 opts 20 (map negate) 0 1 [[1], [2]] of
            Right values -> length values == 2
            _ -> False
        )
    ,
        ( "finite-time Lyapunov spectrum diagonal system"
        , vectorResult
            1e-5
            [0.3, -0.7]
            (lyapunovExponents opts 100 1e-5 (\_ y -> [0.3 * y !! 0, -0.7 * y !! 1]) 0 1 [1, 1])
        )
    ,
        ( "ODE shape nonfinite grid and budget failures"
        , isFailure (solveIVP RK4 opts 10 (\_ _ -> [1, 2]) 0 1 [1])
            && isFailure (solveIVP RK4 opts 0 decay 0 1 [1])
            && isFailure (solveAdaptive RK4 opts{maximumSteps = 1} decay 0 100 [1])
            && isFailure (solveIVP RK4 opts 10 (\_ _ -> [1 / 0]) 0 1 [1])
        )
    ,
        ( "complex-step rejects a nonfinite real callback component"
        , isFailure (complexDerivative 1e-6 (const ((0 / 0) :+ 1e-6)) 0)
        )
    ,
        ( "central limit rejects budget smaller than one sample pair"
        , case limit Central (Tolerance 1e-9 0 1) 1 (const 1) 0 of
            Left (NonConvergence _ count) -> count <= 1
            Left _ -> True
            Right _ -> False
        )
    , ("JVP rejects nonfinite perturbed coordinates", isFailure (jvp 1e308 (const [1]) [1e308] [2]))
    ,
        ( "empty derivative domains still validate steps"
        , isFailure (jacobian (-1) (const []) []) && isFailure (gradient 0 (const 0) [])
        )
    ,
        ( "line and surface integrals reject nonfinite geometry"
        , isFailure (lineIntegral tol (const [1 / 0]) (const [1]) (const [1]) 0 1)
            && isFailure
                ( surfaceIntegral
                    2
                    4
                    (const [1 / 0, 0, 0])
                    (const [1, 0, 0])
                    (const [0, 1, 0])
                    (const 1)
                    [(0, 1), (0, 1)]
                )
        )
    , ("Newton rejects nonfinite initial equilibrium", isFailure (equilibrium opts (const [0]) [0 / 0]))
    ,
        ( "Newton cannot accept overflowed residual norms as converged"
        , case equilibrium opts id (replicate 10 1e308) of
            Left _ -> True
            Right answer -> all (\x -> abs x < 1e-6) answer
        )
    ,
        ( "ODE zero duration and empty states preserve shapes"
        , trajectoryClose 0 [2] (solveIVP RK4 opts 10 decay 1 1 [2]) && case solveIVP RK4 opts 10 (\_ _ -> []) 0 1 [] of
            Right t -> length (trajectoryStates t) == 11 && all null (trajectoryStates t)
            _ -> False
        )
    ]
  where
    tol = Tolerance 1e-10 1e-9 100000
    opts = defaultODEOptions
    decay _ = map negate

close :: Double -> Double -> Double -> Bool
close tolerance expected actual =
    not (isNaN actual || isInfinite actual)
        && abs (expected - actual) <= tolerance * max 1 (abs expected)
closeResult :: Double -> Double -> Either e Double -> Bool
closeResult tolerance expected = either (const False) (close tolerance expected)
estimateClose :: Double -> Double -> Either e (Estimate Double) -> Bool
estimateClose tolerance expected =
    either
        (const False)
        (\r -> close tolerance expected (estimateValue r) && finiteError (estimateError r))
  where
    finiteError e = not (isNaN e || isInfinite e) && e >= 0
vectorResult :: Double -> [Double] -> Either e [Double] -> Bool
vectorResult tolerance expected =
    either
        (const False)
        (\actual -> length expected == length actual && and (zipWith (close tolerance) expected actual))
matrixResult :: Double -> [Double] -> Either e (Matrix Double) -> Bool
matrixResult tolerance expected =
    either
        (const False)
        (\actual -> vectorResult tolerance expected (Right (toList actual) :: Either () [Double]))
trajectoryClose :: Double -> [Double] -> Either e Trajectory -> Bool
trajectoryClose tolerance expected =
    either
        (const False)
        ( \t ->
            not (null (trajectoryStates t))
                && vectorResult tolerance expected (Right (last (trajectoryStates t)) :: Either () [Double])
        )
isFailure :: Either e a -> Bool
isFailure = either (const True) (const False)
denseAndEvents :: Bool
denseAndEvents = case solveIVP RK4 defaultODEOptions 8 (\_ _ -> [1]) 0 1 [0] of
    Left _ -> False
    Right trajectory ->
        vectorResult 1e-12 [0.375] (interpolateTrajectory trajectory 0.375) && case locateEvents Rising 1e-10 (\_ y -> y !! 0 - 0.3) trajectory of
            Right [event] -> close 1e-9 0.3 (eventTime event)
            _ -> False
hamiltonianCase :: HamiltonianMethod -> Bool
hamiltonianCase method = case solveHamiltonian method 1000 id (map negate) 0 10 [1] [0] of
    Left _ -> False
    Right trajectory -> all (\state -> abs (sum (map (^ (2 :: Int)) state) - 1) < 0.02) (trajectoryStates trajectory)
