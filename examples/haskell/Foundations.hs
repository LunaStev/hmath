-- SPDX-License-Identifier: MPL-2.0
module Main where

import qualified HMath.Calculus as Calculus
import HMath.Error (MathError)
import qualified HMath.Matrix as Matrix
import qualified HMath.Matrix.QR as QR
import qualified HMath.NumberTheory as NumberTheory
import qualified HMath.Numeric as Numeric
import qualified HMath.ODE as ODE
import qualified HMath.Polynomial as Polynomial
import qualified HMath.Scalar as Scalar
import qualified HMath.Sparse as Sparse
import qualified HMath.Tensor as Tensor
import System.Exit (die)

main :: IO ()
main = either (die . show) (mapM_ putStrLn) examples

examples :: Either MathError [String]
examples = do
    distance <- Scalar.hypot 3e200 (4e200 :: Double)
    design <- Matrix.fromListChecked 3 2 [1, 0, 1, 1, 1, 2 :: Double]
    fit <- QR.leastSquares design [1, 3, 5]
    sparse <- Sparse.sparse 2 2 [(0, 0, 2), (1, 1, 3 :: Double)]
    productVector <- Sparse.spmv sparse [4, 5]
    tensor <- Tensor.tensor [2, 2] [1, 2, 3, 4 :: Double]
    integral <- Calculus.adaptiveIntegrate Calculus.defaultTolerance sin 0 pi
    trajectory <- ODE.solveAdaptive ODE.DormandPrince ODE.defaultODEOptions (\_ -> map negate) 0 1 [1]
    let polynomial = Polynomial.polynomial [1, 2, 3 :: Rational]
    pure
        [ "Hypot: " ++ show distance
        , "Stable sum: " ++ show (Numeric.neumaierSum [1e16, 1, -1e16 :: Double])
        , "Bezout: " ++ show (NumberTheory.extendedGCD 240 46)
        , "Polynomial at 2: " ++ show (Polynomial.evaluatePolynomial polynomial 2)
        , "Least-squares intercept/slope: " ++ show fit
        , "Sparse product: " ++ show productVector
        , "Tensor: " ++ show (Tensor.tensorShape tensor, Tensor.tensorValues tensor)
        , "Integral of sin: " ++ show (Calculus.estimateValue integral)
        , "Decay at t=1: " ++ show (last (ODE.trajectoryStates trajectory))
        ]
