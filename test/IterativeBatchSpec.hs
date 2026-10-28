-- SPDX-License-Identifier: MPL-2.0
module IterativeBatchSpec (iterativeBatchTests) where

import Data.Either (isLeft)
import HMath.Matrix (Matrix,fromListChecked,toList,shape)
import HMath.Matrix.Iterative

iterativeBatchTests :: [(String,Bool)]
iterativeBatchTests=
    [("CG SPD analytic solution",solves (conjugateGradient options spd rhs zero) expected)
    ,("Jacobi PCG SPD analytic solution",solves (jacobiPreconditioner spd >>= \p->preconditionedCG options p spd rhs zero) expected)
    ,("block PCG SPD analytic solution",solves (blockJacobiPreconditioner [2,1] spd >>= \p->preconditionedCG options p spd rhs zero) expected)
    ,("ILU0 PCG tridiagonal one-step convergence",case ilu0Preconditioner spd >>= \p->preconditionedCG options p spd rhs zero of Right r->iterativeIterations r==1 && close (iterativeSolution r) expected; _->False)
    ,("IC0 PCG tridiagonal one-step convergence",case ic0Preconditioner spd >>= \p->preconditionedCG options p spd rhs zero of Right r->iterativeIterations r==1 && close (iterativeSolution r) expected; _->False)
    ,("GMRES nonsymmetric analytic solution",solves (gmres options 3 nonsymmetric rhs zero) expectedNonsymmetric)
    ,("restarted GMRES converges across restarts",case gmres options 2 nonsymmetric rhs zero of Right r->iterativeIterations r>3 && close (iterativeSolution r) expectedNonsymmetric; _->False)
    ,("MINRES symmetric indefinite solution",solves (minres options indefinite [1,2,3] zero) [0.5,1,-1.5])
    ,("BiCG nonsymmetric analytic solution",solves (bicg options nonsymmetric rhs zero) expectedNonsymmetric)
    ,("BiCGSTAB nonsymmetric analytic solution",solves (bicgstab options nonsymmetric rhs zero) expectedNonsymmetric)
    ,("LSQR square analytic solution",solves (lsqr options nonsymmetric rhs zero) expectedNonsymmetric)
    ,("LSMR square analytic solution",solves (lsmr options nonsymmetric rhs zero) expectedNonsymmetric)
    ,("LSQR inconsistent least-squares normal residual",leastSquaresFixture (lsqr options tall [1,2,2,4] [0,0]))
    ,("LSMR inconsistent least-squares normal residual",leastSquaresFixture (lsmr options tall [1,2,2,4] [0,0]))
    ,("LSQR wide minimum-norm solution",solves (lsqr options wide [1,2] [0,0,0]) [0,1,1])
    ,("LSMR wide minimum-norm solution",solves (lsmr options wide [1,2] [0,0,0]) [0,1,1])
    ,("LSQR rank-deficient minimum-norm solution",solves (lsqr options rankDeficient [2,4,6] [0,0]) [1,1])
    ,("LSMR rank-deficient minimum-norm solution",solves (lsmr options rankDeficient [2,4,6] [0,0]) [1,1])
    ,("Jacobi diagonal-dominant solution",solves (jacobiSolve options spd rhs zero) expected)
    ,("Gauss-Seidel diagonal-dominant solution",solves (gaussSeidelSolve options spd rhs zero) expected)
    ,("SOR diagonal-dominant solution",solves (sorSolve options 1.2 spd rhs zero) expected)
    ,("iterative refinement residual correction",case iterativeRefinement options nonsymmetric rhs [2,-1,5] of Right r->iterativeIterations r==1 && close (iterativeSolution r) expectedNonsymmetric; _->False)
    ,("all solvers honor converged initial guess with zero budget",all (\solver->case solver exactOptions spd rhs expected of Right r->iterativeIterations r==0; _->False) squareSolvers)
    ,("all solvers reject exhausted zero budget",all (\solver->isLeft (solver exactOptions spd rhs zero)) squareSolvers)
    ,("all solvers reject negative iteration budget",all (\solver->isLeft (solver (options { maximumIterations= -1 }) spd rhs zero)) squareSolvers)
    ,("all solvers reject negative/NaN/infinite tolerance",and [isLeft (solver bad spd rhs zero)|solver<-squareSolvers,bad<-[options {absoluteTolerance= -1},options {relativeTolerance=0/0},options {relativeTolerance=1/0}]])
    ,("all square solvers validate shapes and vectors",and [isLeft (solver options tall [1,2,3,4] [0,0]) && isLeft (solver options spd [1] zero) && isLeft (solver options spd rhs [0])|solver<-squareOnly])
    ,("all solvers reject nonfinite rhs/initial guess",and [isLeft (solver options spd [1,0/0,3] zero) && isLeft (solver options spd rhs [0,1/0,0])|solver<-squareSolvers])
    ,("all solvers reject nonfinite matrix",all (\solver->isLeft (solver options nonfinite rhs zero)) squareSolvers)
    ,("CG detects negative curvature",isLeft (conjugateGradient options negativeIdentity rhs zero))
    ,("CG and MINRES require symmetry",isLeft (conjugateGradient options nonsymmetric rhs zero) && isLeft (minres options nonsymmetric rhs zero))
    ,("MINRES solves symmetric system rejected by CG",isLeft (conjugateGradient options indefinite [0,0,1] zero) && solves (minres options indefinite [0,0,1] zero) [0,0,-0.5])
    ,("GMRES restart validation",isLeft (gmres options 0 spd rhs zero))
    ,("GMRES singular inconsistent breakdown",isLeft (gmres options 3 zeroMatrix rhs zero))
    ,("BiCG and BiCGSTAB breakdown explicit",isLeft (bicg options zeroMatrix rhs zero) && isLeft (bicgstab options zeroMatrix rhs zero))
    ,("stationary zero pivots rejected",isLeft (jacobiSolve options zeroMatrix rhs zero) && isLeft (gaussSeidelSolve options zeroMatrix rhs zero))
    ,("SOR relaxation validation",all (\omega->isLeft (sorSolve options omega spd rhs zero)) [0,2,-1,0/0,1/0])
    ,("stationary divergence budget explicit",isLeft (jacobiSolve (options {maximumIterations=5}) divergent [1,1] [0,0]))
    ,("zero least-squares matrix returns stationary solution",all (\solver->case solver options zeroMatrix rhs zero of Right r->iterativeIterations r==0 && iterativeNormalResidualNorm r==0 && iterativeResidualNorm r>0; _->False) [lsqr,lsmr])
    ,("least-squares preserves initial nullspace component",all (\solver->solves (solver options wide [1,2] [2,2,-2]) [2,3,-1]) [lsqr,lsmr])
    ,("identity preconditioner shape and finite checks",case identityPreconditioner 3 of Right p->applyPreconditioner p rhs==Right rhs && isLeft (applyPreconditioner p [1]) && isLeft (applyPreconditioner p [1,0/0,3]); _->False)
    ,("Jacobi inverse diagonal action",case jacobiPreconditioner spd >>= \p->applyPreconditioner p rhs of Right x->close x [0.25,2/3,1.5]; _->False)
    ,("block Jacobi independent inverse blocks",case blockJacobiPreconditioner [2,1] spd >>= \p->applyPreconditioner p rhs of Right x->close x [1/11,7/11,1.5]; _->False)
    ,("block partition rejection",isLeft (blockJacobiPreconditioner [1,1] spd) && isLeft (blockJacobiPreconditioner [0,3] spd))
    ,("ILU0 drops newly created fill",case ilu0Preconditioner sparsePattern >>= \p->applyPreconditioner p rhs of Right x->close (matvec filledApproximation x) rhs && not (close (matvec sparsePattern x) rhs); _->False)
    ,("IC0 drops newly created fill",case ic0Preconditioner sparsePattern >>= \p->applyPreconditioner p rhs of Right x->close (matvec filledApproximation x) rhs && not (close (matvec sparsePattern x) rhs); _->False)
    ,("preconditioner singular/indefinite rejection",isLeft (ilu0Preconditioner zeroMatrix) && isLeft (ic0Preconditioner negativeIdentity) && isLeft (ic0Preconditioner nonsymmetric))
    ,("PCG preconditioner dimension rejection",isLeft (identityPreconditioner 2 >>= \p->preconditionedCG options p spd rhs zero))
    ,("empty square systems",all (\solver->case solver options empty [] [] of Right r->iterativeSolution r==[] && iterativeIterations r==0; _->False) squareSolvers)
    ,("Float CG and LSQR",floatChecks)]
  where
    floatChecks=case (do
        a<-fromListChecked 2 2 [3,1,1,2::Float]
        c<-conjugateGradient (IterativeOptions 1e-6 1e-5 100) a [1,2] [0,0]
        l<-lsqr (IterativeOptions 1e-6 1e-5 100) a [1,2] [0,0]
        pure [c,l]) of
            Right rs->all (\r->case iterativeSolution r of [x,y]->abs x<1e-4 && abs (y-1)<1e-4; _->False) rs
            _->False
    options=IterativeOptions 1e-12 1e-10 1000
    exactOptions=options {absoluteTolerance=1e-14,maximumIterations=0}
    rhs=[1,2,3::Double]
    zero=[0,0,0]
    expected=[2/9,1/9,13/9]
    expectedNonsymmetric=[-17/19,25/19,37/19]
    spd=matrix 3 3 [4,1,0,1,3,1,0,1,2]
    nonsymmetric=matrix 3 3 [4,2,1,0,3,-1,1,0,2]
    indefinite=matrix 3 3 [2,0,0,0,2,0,0,0,-2]
    negativeIdentity=matrix 3 3 [-1,0,0,0,-1,0,0,0,-1]
    tall=matrix 4 2 [1,0,1,1,1,2,1,3]
    wide=matrix 2 3 [1,0,1,0,1,1]
    rankDeficient=matrix 3 2 [1,1,2,2,3,3]
    zeroMatrix=matrix 3 3 (replicate 9 0)
    divergent=matrix 2 2 [1,2,2,1]
    nonfinite=matrix 3 3 [1,0,0,0,0/0,0,0,0,1]
    empty=matrix 0 0 []
    sparsePattern=matrix 3 3 [4,1,1,1,4,0,1,0,4]
    filledApproximation=matrix 3 3 [4,1,1,1,4,0.25,1,0.25,4]
    squareOnly=[conjugateGradient,gmresWithRestart,minres,bicg,bicgstab,jacobiSolve,gaussSeidelSolve,sorWithRelaxation,iterativeRefinement]
    squareSolvers=squareOnly++[lsqr,lsmr]
    gmresWithRestart opts=gmres opts 3
    sorWithRelaxation opts=sorSolve opts 1.1
    solves answer expectedValues=case answer of Right r->close (iterativeSolution r) expectedValues; _->False
    leastSquaresFixture answer=case answer of Right r->close (iterativeSolution r) [0.9,0.9] && abs (iterativeResidualNorm r-sqrt 0.7)<1e-10 && iterativeNormalResidualNorm r<1e-10; _->False

matrix :: Int -> Int -> [Double] -> Matrix Double
matrix r c xs=case fromListChecked r c xs of Right a->a; Left err->error (show err)

close :: [Double] -> [Double] -> Bool
close a b=length a==length b && and (zipWith (\x y->abs (x-y)<=1e-8*max 1 (max (abs x) (abs y))) a b)

matvec :: Matrix Double -> [Double] -> [Double]
matvec a xs=[sum (zipWith (*) (take n (drop (i*n) (toList a))) xs)|i<-[0..m-1]]
  where (m,n)=shape a
