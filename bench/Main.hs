-- SPDX-License-Identifier: MPL-2.0

{- | Criterion forces all exported numeric outputs. Inputs are deterministic,
checked before timing, and shared across repetitions. The backend cases include
checked copying/dispatch overhead; they are not raw vendor-kernel timings.
Use --json/--csv and +RTS -T -s for timing/allocation observations. Missing
native providers omit native cases; they are never relabeled pure timings.
-}
module Main where

import Control.Exception (evaluate)
import Control.Monad (unless, void)
import Criterion.Main
import Data.Complex (Complex ((:+)), imagPart, realPart)
import qualified HMath.Autodiff as AD
import qualified HMath.Backend as B
import qualified HMath.Calculus as C
import qualified HMath.Fourier as F
import qualified HMath.Linear as V
import qualified HMath.Matrix as M
import qualified HMath.Matrix.Decomposition as D
import qualified HMath.Matrix.LAPACK as L
import qualified HMath.Matrix.LU as LU
import qualified HMath.ODE as O
import qualified HMath.Optimization.Common as OC
import qualified HMath.Optimization.Local as OL
import qualified HMath.Random as R
import qualified HMath.Signal as Signal
import qualified HMath.Statistics as S
import qualified HMath.Tensor as T

checked :: (Show e) => Either e a -> a
checked = either (error . show) id

-- n I + ones: a dense positive-definite matrix with eigenvalues n (n-1
-- times) and 2n. It provides independent spectral and solve references.
matrix :: Int -> M.Matrix Double
matrix n =
    checked $
        M.fromListChecked
            n
            n
            [if i == j then fromIntegral (n + 1) else 1 | i <- [0 .. n - 1], j <- [0 .. n - 1]]

close :: Double -> Double -> Bool
close a b = abs (a - b) <= 1e-8 * max 1 (max (abs a) (abs b))

complexValues :: [Complex Double] -> [(Double, Double)]
complexValues = map (\z -> (realPart z, imagPart z))

svdValues :: L.SVD -> ([Double], [Double], [Double])
svdValues f = (M.toList (L.svdU f), L.singularValues f, M.toList (L.svdVT f))

eigenValues :: L.Eigen -> ([(Double, Double)], [(Double, Double)])
eigenValues f = (complexValues (L.eigenvalues f), complexValues (M.toList (L.eigenvectors f)))

backendProduct :: B.Backend -> M.Matrix Double -> IO [Double]
backendProduct backend a = do
    let (rows, columns) = M.shape a
        zeros = checked (M.zeroMatrixChecked rows columns)
    M.toList . checked <$> B.gemm backend B.NoTranspose B.NoTranspose 1 a a 0 zeros

trajectory :: O.Method -> Int -> ([Double], [[Double]], [[Double]])
trajectory method panels =
    let result = checked (O.solveIVP method O.defaultODEOptions panels (\_ -> map negate) 0 1 [1])
     in (O.trajectoryTimes result, O.trajectoryStates result, O.trajectoryDerivatives result)

optimize :: [Double] -> ([Double], Double, Double, Int, Int)
optimize initial =
    let objective xs = Right (sum [(x - 1) ^ (2 :: Int) | x <- xs])
        gradient xs = Right (map (\x -> 2 * (x - 1)) xs)
        result = checked (OL.minimizeQuasiNewton OL.BFGS OC.defaultOptimizeOptions objective gradient initial)
     in if OC.optConverged result
            then
                ( OC.optPoint result
                , OC.optValue result
                , OC.optGradientNorm result
                , OC.optIterations result
                , OC.optEvaluations result
                )
            else error "benchmark optimizer did not converge"

-- Each algorithm family has an independently known identity or closed-form
-- answer. Failure prevents recording timings for invalid fixtures/results.
validateFixtures :: B.Backend -> Bool -> IO ()
validateFixtures selected hasLapack = do
    let a = matrix 4
        expectedProduct = [if i == j then 28 else 12 | i <- [0 .. 3 :: Int], j <- [0 .. 3 :: Int]]
        knownEigenvalues = [4, 4, 4, 8]
        tensor = checked (T.tensor [2, 3] [1 .. 6 :: Double])
        (_, states, _) = trajectory O.RK4 128
        (_, adaptiveStates, _) = trajectory O.DormandPrince 128
        lower = checked (D.cholesky a)
        choleskyProduct = checked (M.multiplyChecked lower (M.transposeMatrix lower))
        (point, objective, _, _, _) = optimize (replicate 8 4)
        spectral f = and (zipWith close knownEigenvalues (map realPart (L.eigenvalues f)))
        luSolution = checked (LU.solve a (replicate 4 1))
        pureSVD = checked (B.pureSVD a)
        spectralSVD = and (zipWith close [8, 4, 4, 4] (L.singularValues pureSVD))
        fftImpulse = checked (F.fft [1, 0, 0, 0])
        convolution = checked (Signal.convolution [1, 2, 3] [1, -1])
        gradient = checked (AD.gradient (\xs -> sum (map (\x -> x * x) xs)) [1, 2, 3])
        referenceOK =
            V.dot [1, 2, 3 :: Double] [1, 2, 3] == 14
                && close (S.variance [1, 2, 3 :: Double]) (2 / 3)
                && and (zipWith close expectedProduct (M.toList (checked (M.multiplyChecked a a))))
                && and (zipWith close (M.toList a) (M.toList choleskyProduct))
                && close (checked (C.integrateComposite C.Simpson 100 (\x -> x * x) 0 1)) (1 / 3)
                && convolution == [1, 1, 1, -3]
                && and (zipWith close (checked (Signal.overlapAdd 8 [1, -1] [1, 2, 3])) convolution)
                && T.tensorValues (checked (T.sumAxes [1] False tensor)) == [6, 15]
                && all (\z -> close (realPart z) 1 && close (imagPart z) 0) fftImpulse
                && gradient == [2, 4, 6]
                && close ((states !! 128) !! 0) (exp (-1))
                && close ((adaptiveStates !! 128) !! 0) (exp (-1))
                && all (`close` 1) point
                && close objective 0
                && all (`close` 0.125) luSolution
                && spectral (checked (B.pureSymmetricEigen a))
                && spectralSVD
    unless referenceOK (fail "benchmark reference validation failed")
    forBackend <- backendProduct selected a
    pureProduct <- backendProduct B.pureBackend a
    unless (and (zipWith close expectedProduct forBackend) && pureProduct == expectedProduct) $
        fail "benchmark backend differential validation failed"
    if hasLapack
        then
            unless (spectral (checked (L.symmetricEigen a))) (fail "native spectral fixture validation failed")
        else pure ()
    -- Demand input scalars before Criterion starts; sum evaluates every cell.
    mapM_ (void . evaluate . sum . M.toList . matrix) [4, 16, 32]

backendBenchmarks :: String -> B.Backend -> Benchmark
backendBenchmarks label backend =
    bgroup
        label
        [ bench ("gemm-" ++ show n) $ nfIO (backendProduct backend (matrix n))
        | n <- [4, 16, 32]
        ]

main :: IO ()
main = do
    selected <- checked <$> B.selectBackend B.AutoBackend
    hasLapack <- B.lapackAvailable
    validateFixtures selected hasLapack
    let nativeSelected = B.selectedProvider (B.backendInfo selected) /= B.Pure
        nativeKernels =
            [ backendBenchmarks
                ( "backend/"
                    ++ show (B.selectedProvider (B.backendInfo selected))
                    ++ "/"
                    ++ show (B.selectedIntegerABI (B.backendInfo selected))
                )
                selected
            | nativeSelected
            ]
        nativeSpectra =
            [ bgroup
                "lapack"
                [ bgroup
                    (show n)
                    [ bench "svd" $ nf (svdValues . checked . L.svd) (matrix n)
                    , bench "symmetric-eigen" $ nf (eigenValues . checked . L.symmetricEigen) (matrix n)
                    ]
                | n <- [4, 16, 32]
                ]
            | hasLapack
            ]
    defaultMain $
        [ bgroup
            "vector"
            [ bgroup
                (show n)
                [ bench "dot" $ nf (\xs -> V.dot xs xs) [1 .. fromIntegral n :: Double]
                , bench "variance" $ nf S.variance [1 .. fromIntegral n :: Double]
                ]
            | n <- [16, 1024, 16384 :: Int]
            ]
        , bgroup
            "matrix"
            [ bgroup
                (show n)
                [ bench "gemm" $ nf (\a -> M.toList (checked (M.multiplyChecked a a))) (matrix n)
                , bench "cholesky" $ nf (M.toList . checked . D.cholesky) (matrix n)
                ]
            | n <- [4, 16, 32]
            ]
        , backendBenchmarks "backend/pure" B.pureBackend
        , bgroup
            "pure-spectral"
            [ bgroup
                (show n)
                [ bench "svd" $ nf (svdValues . checked . B.pureSVD) (matrix n)
                , bench "symmetric-eigen" $ nf (eigenValues . checked . B.pureSymmetricEigen) (matrix n)
                ]
            | n <- [4, 16]
            ]
        , bgroup
            "tensor"
            [ bench "broadcast" $
                nf
                    (T.tensorValues . checked . T.broadcastTo [32, 32])
                    (checked (T.tensor [1, 32] [1 .. 32 :: Double]))
            , bench "reduction" $
                nf
                    (T.tensorValues . checked . T.sumAxes [1] False)
                    (checked (T.tensor [32, 32] [1 .. 1024 :: Double]))
            , bench "batched-matmul" $
                nf
                    (\a -> T.tensorValues (checked (T.batchedMatmul a a)))
                    (checked (T.tensor [4, 8, 8] (replicate 256 (1 :: Double))))
            ]
        , bgroup
            "convolution"
            [ bench "direct-1024x31" $
                nf
                    (checked . (`Signal.convolution` replicate 31 (1 / 31)))
                    [sin (fromIntegral i) | i <- [0 .. 1023 :: Int]]
            , bench "overlap-add-1024x31" $
                nf
                    (checked . (\xs -> Signal.overlapAdd 128 (replicate 31 (1 / 31)) xs))
                    [sin (fromIntegral i) | i <- [0 .. 1023 :: Int]]
            ]
        , bgroup
            "fft"
            [ bench (show n) $
                nf (complexValues . checked . F.fft) [sin (fromIntegral k) :+ 0 | k <- [0 .. n - 1]]
            | n <- [64, 256, 1024 :: Int]
            ]
        , bgroup
            "ode"
            [bench (show method ++ "-128") $ nf (trajectory method) 128 | method <- [O.RK4, O.DormandPrince]]
        , bench "optimizer/bfgs-quadratic-32" $ nf optimize (replicate 32 4)
        , bench "quadrature/simpson-1024" $
            nf (\n -> checked (C.integrateComposite C.Simpson n sin 0 pi)) 1024
        , bench "autodiff/reverse-32" $
            nf (checked . AD.gradient (\xs -> sum (map (\x -> sin x + x * x) xs))) (replicate 32 0.5)
        , bench "rng/normal-1024" $
            nf (\seed -> fst (checked (R.sampleN 1024 (R.normal 0 1) (R.seedRNG R.PCG32 seed)))) 42
        , bench "solve/lu-32" $
            nf (\a -> checked (LU.luDecompose a >>= (\lu -> LU.solveLU lu (replicate 32 1)))) (matrix 32)
        ]
            ++ nativeKernels
            ++ nativeSpectra
