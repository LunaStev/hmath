{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE FlexibleInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated representation adapters; numerical functions are the originals.
module HMath.FFI.NumericalAll where
import Foreign
import Foreign.C
import qualified HMath.FFI.Boundary as B
import HMath.FFI.NumericalCodec
import qualified HMath.FFI.Value as V
import qualified HMath.Calculus as C
import qualified HMath.Root as R
import qualified HMath.ODE as O
import qualified HMath.PDE as P
instance From C.Tolerance where from = unbox 201
instance To C.Tolerance where
    to value = pure (box 201 value [to (C.absoluteTolerance value),to (C.relativeTolerance value),to (C.maximumEvaluations value)])
instance From C.Difference where from = unbox 202
instance To C.Difference where
    to value = pure (box 202 value [])
instance From C.Quadrature where from = unbox 203
instance To C.Quadrature where
    to value = pure (box 203 value [])
instance From R.RootOptions where from = unbox 204
instance To R.RootOptions where
    to value = pure (box 204 value [to (R.rootMaxIterations value),to (R.rootMaxEvaluations value),to (R.rootTolerance value),to (R.rootStepTolerance value)])
instance From R.RootResult where from = unbox 205
instance To R.RootResult where
    to value = pure (box 205 value [to (R.rootValue value),to (R.rootResidual value),to (R.rootErrorBound value),to (R.rootIterations value),to (R.rootEvaluations value)])
instance From R.Bracket where from = unbox 206
instance To R.Bracket where
    to value = pure (box 206 value [])
instance From R.BracketMethod where from = unbox 207
instance To R.BracketMethod where
    to value = pure (box 207 value [])
instance From R.DerivativeMethod where from = unbox 208
instance To R.DerivativeMethod where
    to value = pure (box 208 value [])
instance From R.FixedPointMethod where from = unbox 209
instance To R.FixedPointMethod where
    to value = pure (box 209 value [])
instance From R.SystemMethod where from = unbox 210
instance To R.SystemMethod where
    to value = pure (box 210 value [])
instance From R.SystemRootResult where from = unbox 211
instance To R.SystemRootResult where
    to value = pure (box 211 value [to (R.systemRoot value),to (R.systemResidual value),to (R.systemIterations value),to (R.systemEvaluations value)])
instance From O.Method where from = unbox 212
instance To O.Method where
    to value = pure (box 212 value [])
instance From O.ODEOptions where from = unbox 213
instance To O.ODEOptions where
    to value = pure (box 213 value [to (O.odeAbsoluteTolerance value),to (O.odeRelativeTolerance value),to (O.initialStep value),to (O.minimumStep value),to (O.maximumStep value),to (O.maximumSteps value),to (O.newtonIterations value)])
instance From O.Trajectory where from = unbox 214
instance To O.Trajectory where
    to value = pure (box 214 value [to (O.trajectoryTimes value),to (O.trajectoryStates value),to (O.trajectoryDerivatives value)])
instance From O.EventDirection where from = unbox 215
instance To O.EventDirection where
    to value = pure (box 215 value [])
instance From O.Event where from = unbox 216
instance To O.Event where
    to value = pure (box 216 value [to (O.eventTime value),to (O.eventState value)])
instance From O.HamiltonianMethod where from = unbox 217
instance To O.HamiltonianMethod where
    to value = pure (box 217 value [])
instance From P.Grid where from = unbox 218
instance To P.Grid where
    to value = pure (box 218 value [to (P.gridShape value),to (P.gridSpacing value)])
instance From P.Boundary where from = unbox 219
instance To P.Boundary where
    to value = pure (box 219 value [])
instance From P.Discretization where from = unbox 220
instance To P.Discretization where
    to value = pure (box 220 value [])
instance From P.PDEOperator where from = unbox 221
instance To P.PDEOperator where
    to value = pure (box 221 value [to (P.pdeStiffness value),to (P.pdeMass value),to (P.pdeBoundaryLoad value)])
instance From P.PDEResult where from = unbox 222
instance To P.PDEResult where
    to value = pure (box 222 value [to (P.pdeValues value),to (P.pdeResidual value),to (P.pdeErrorEstimate value)])
foreign export ccall "hm_numerical_apply" dispatch :: CInt -> Ptr (StablePtr V.Value) -> CSize -> Ptr (StablePtr V.Value) -> IO CInt
dispatch :: CInt -> Ptr (StablePtr V.Value) -> CSize -> Ptr (StablePtr V.Value) -> IO CInt
dispatch operation input arity out = B.boundary $ do
    values <- peekArray (fromIntegral arity) input >>= mapM deRefStablePtr
    result <- case operation of
        0 -> apply (C.Estimate :: V.Value -> Double -> Int -> C.Estimate V.Value) values
        1 -> apply (C.estimateValue :: C.Estimate V.Value -> V.Value) values
        2 -> apply (C.estimateError :: C.Estimate V.Value -> Double) values
        3 -> apply (C.evaluations :: C.Estimate V.Value -> Int) values
        4 -> apply C.Tolerance values
        5 -> apply C.absoluteTolerance values
        6 -> apply C.relativeTolerance values
        7 -> apply C.maximumEvaluations values
        8 -> apply C.defaultTolerance values
        9 -> apply C.Forward values
        10 -> apply C.Backward values
        11 -> apply C.Central values
        12 -> apply C.Trapezoidal values
        13 -> apply C.Simpson values
        14 -> apply C.ThreeEighths values
        15 -> apply C.derivative values
        16 -> apply C.derivativeN values
        17 -> apply C.complexDerivative values
        18 -> apply C.richardson values
        19 -> apply C.ridders values
        20 -> apply C.limit values
        21 -> apply C.partialDerivative values
        22 -> apply C.gradient values
        23 -> apply C.jacobian values
        24 -> apply C.hessian values
        25 -> apply C.directionalDerivative values
        26 -> apply C.jvp values
        27 -> apply C.vjp values
        28 -> apply C.hvp values
        29 -> apply C.divergence values
        30 -> apply C.curl values
        31 -> apply C.laplacian values
        32 -> apply C.integrateComposite values
        33 -> apply C.romberg values
        34 -> apply C.gaussLegendre values
        35 -> apply C.gaussHermite values
        36 -> apply C.gaussLaguerre values
        37 -> apply C.gaussChebyshev values
        38 -> apply C.gaussKronrod values
        39 -> apply C.adaptiveIntegrate values
        40 -> apply C.clenshawCurtis values
        41 -> apply C.tanhSinh values
        42 -> apply C.integrateInfinite values
        43 -> apply C.integrateOscillatory values
        44 -> apply C.integrateND values
        45 -> apply C.monteCarlo values
        46 -> apply C.quasiMonteCarlo values
        47 -> apply C.cumulativeIntegral values
        48 -> apply C.pathIntegral values
        49 -> apply C.lineIntegral values
        50 -> apply C.surfaceIntegral values
        51 -> apply C.volumeIntegral values
        52 -> apply R.RootOptions values
        53 -> apply R.rootMaxIterations values
        54 -> apply R.rootMaxEvaluations values
        55 -> apply R.rootTolerance values
        56 -> apply R.rootStepTolerance values
        57 -> apply R.defaultRootOptions values
        58 -> apply R.RootResult values
        59 -> apply R.rootValue values
        60 -> apply R.rootResidual values
        61 -> apply R.rootErrorBound values
        62 -> apply R.rootIterations values
        63 -> apply R.rootEvaluations values
        64 -> apply R.Bisection values
        65 -> apply R.RegulaFalsi values
        66 -> apply R.Illinois values
        67 -> apply R.Brent values
        68 -> apply R.Ridder values
        69 -> apply R.Newton values
        70 -> apply R.Halley values
        71 -> apply R.Householder3 values
        72 -> apply R.Picard values
        73 -> apply R.Aitken values
        74 -> apply R.SteffensenFixed values
        75 -> apply R.MultivariateNewton values
        76 -> apply R.NewtonTrustRegion values
        77 -> apply R.Broyden values
        78 -> apply R.SystemRootResult values
        79 -> apply R.systemRoot values
        80 -> apply R.systemResidual values
        81 -> apply R.systemIterations values
        82 -> apply R.systemEvaluations values
        83 -> apply R.bracket values
        84 -> apply R.solveBracket values
        85 -> apply R.bracketScan values
        86 -> apply R.isolateIntervals values
        87 -> apply R.solveDerivative values
        88 -> apply R.secant values
        89 -> apply R.steffensen values
        90 -> apply R.fixedPoint values
        91 -> apply R.anderson values
        92 -> apply R.solveSystem values
        93 -> apply R.polynomialRoots values
        94 -> apply R.realPolynomialRoots values
        95 -> apply O.Euler values
        96 -> apply O.Heun values
        97 -> apply O.Midpoint values
        98 -> apply O.RK2 values
        99 -> apply O.RK4 values
        100 -> apply O.RK23 values
        101 -> apply O.RK45 values
        102 -> apply O.DormandPrince values
        103 -> apply O.DOP853 values
        104 -> apply O.AdamsBashforth values
        105 -> apply O.AdamsMoulton values
        106 -> apply O.PredictorCorrector values
        107 -> apply O.BackwardEuler values
        108 -> apply O.BDF values
        109 -> apply O.Radau values
        110 -> apply O.Rosenbrock values
        111 -> apply O.ODEOptions values
        112 -> apply O.odeAbsoluteTolerance values
        113 -> apply O.odeRelativeTolerance values
        114 -> apply O.initialStep values
        115 -> apply O.minimumStep values
        116 -> apply O.maximumStep values
        117 -> apply O.maximumSteps values
        118 -> apply O.newtonIterations values
        119 -> apply O.defaultODEOptions values
        120 -> apply O.Trajectory values
        121 -> apply O.trajectoryTimes values
        122 -> apply O.trajectoryStates values
        123 -> apply O.trajectoryDerivatives values
        124 -> apply O.solveIVP values
        125 -> apply O.solveAdaptive values
        126 -> apply O.interpolateTrajectory values
        127 -> apply O.AnyDirection values
        128 -> apply O.Rising values
        129 -> apply O.Falling values
        130 -> apply O.Event values
        131 -> apply O.eventTime values
        132 -> apply O.eventState values
        133 -> apply O.locateEvents values
        134 -> apply O.solveBoundary values
        135 -> apply O.solveDAE values
        136 -> apply O.SymplecticEuler values
        137 -> apply O.Verlet values
        138 -> apply O.Leapfrog values
        139 -> apply O.solveHamiltonian values
        140 -> apply O.solveNystrom values
        141 -> apply O.sensitivities values
        142 -> apply O.equilibrium values
        143 -> apply O.phaseTrajectories values
        144 -> apply O.lyapunovExponents values
        145 -> apply P.Dirichlet values
        146 -> apply P.Neumann values
        147 -> apply P.Robin values
        148 -> apply P.Periodic values
        149 -> apply P.FiniteDifference values
        150 -> apply P.FiniteVolume values
        151 -> apply P.FiniteElement values
        152 -> apply P.PDEResult values
        153 -> apply P.pdeValues values
        154 -> apply P.pdeResidual values
        155 -> apply P.pdeErrorEstimate values
        156 -> apply P.grid values
        157 -> apply P.gridShape values
        158 -> apply P.gridSpacing values
        159 -> apply P.flattenIndex values
        160 -> apply P.unflattenIndex values
        161 -> apply P.gridCoordinates values
        162 -> apply P.assemblePDE values
        163 -> apply P.pdeStiffness values
        164 -> apply P.pdeMass values
        165 -> apply P.pdeBoundaryLoad values
        166 -> apply P.solveElliptic values
        167 -> apply P.poisson values
        168 -> apply P.laplace values
        169 -> apply P.helmholtz values
        170 -> apply P.spatialGradient values
        171 -> apply P.laplacianStencil values
        172 -> apply P.spectralDerivative values
        173 -> apply P.spectralLaplacian values
        174 -> apply P.spectralPoisson values
        175 -> apply P.pseudoSpectralDiffusion values
        176 -> apply P.methodOfLines values
        177 -> apply P.heat values
        178 -> apply P.diffusion values
        179 -> apply P.wave values
        180 -> apply P.advection values
        181 -> apply P.advectionDiffusion values
        182 -> apply P.stabilityLimit values
        183 -> apply P.cflNumber values
        184 -> apply P.manufacturedError values
        _ -> V.invalid "unknown numerical operation"
    V.forceValue result
    B.checked (Right ()) (\_ -> V.publish result out)
