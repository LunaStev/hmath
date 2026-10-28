-- SPDX-License-Identifier: MPL-2.0
module SparseSpectralSpec (sparseSpectralTests) where

import Data.Either (isLeft)
import HMath.Sparse
import HMath.Sparse.Spectral

sparseSpectralTests :: [(String,Bool)]
sparseSpectralTests=
    [("sparse dominant positive eigenpair",case sparseDominantEigen options diagonal [1,2,3] of Right r->close (sparseEigenvalue r) 5 && abs (abs (sparseEigenvector r!!0)-1)<1e-8 && sparseEigenResidual r<1e-8; _->False)
    ,("sparse dominant negative eigenpair",case sparseDominantEigen options negative [1,2,3] of Right r->close (sparseEigenvalue r) (-7) && sparseEigenResidual r<1e-8; _->False)
    ,("sparse symmetric offdiagonal eigenpair",case sparseDominantEigen options symmetric [1,2] of Right r->close (sparseEigenvalue r) 3 && closeVectors (map abs (sparseEigenvector r)) [1/sqrt 2,1/sqrt 2]; _->False)
    ,("sparse eigenpair original residual verified",case sparseDominantEigen options symmetric [1,2] of Right r->checkEigen symmetric r; _->False)
    ,("sparse eigenvector huge finite start normalizes safely",case sparseDominantEigen options (sparseMatrix 2 2 [(0,0,1),(1,1,1)]) [1.7e308,1.7e308] of Right r->close (sparseEigenvalue r) 1 && close (norm (sparseEigenvector r)) 1; _->False)
    ,("sparse exact eigenvector zero budget",case sparseDominantEigen (options {sparseIterationLimit=0}) diagonal [1,0,0] of Right r->sparseEigenIterations r==0 && sparseEigenvalue r==5; _->False)
    ,("sparse eigen exhausted budget",isLeft (sparseDominantEigen (options {sparseIterationLimit=0}) diagonal [1,1,1]))
    ,("sparse opposite equal dominant magnitudes do not falsely converge",isLeft (sparseDominantEigen (options {sparseIterationLimit=10}) (sparseMatrix 2 2 [(0,0,1),(1,1,-1)]) [1,1]))
    ,("sparse zero matrix eigenpair",case sparseDominantEigen options zero [1,2,3] of Right r->sparseEigenvalue r==0 && sparseEigenResidual r==0; _->False)
    ,("sparse eigen rejects empty and rectangular",isLeft (sparseDominantEigen options empty []) && isLeft (sparseDominantEigen options tall [1,1]))
    ,("sparse eigen rejects zero/dimension/nonfinite start",isLeft (sparseDominantEigen options diagonal [0,0,0]) && isLeft (sparseDominantEigen options diagonal [1]) && isLeft (sparseDominantEigen options diagonal [1,0/0,1]))
    ,("sparse eigen rejects nonsymmetry",isLeft (sparseDominantEigen options (sparseMatrix 2 2 [(0,1,1)]) [1,1]))
    ,("sparse eigen finite input checks",isLeft (sparseDominantEigen options (sparseMatrix 2 2 [(0,0,1/0)]) [1,1]))
    ,("sparse eigen tolerances/budget/workspace checks",and [isLeft (sparseDominantEigen bad diagonal [1,1,1])|bad<-[options {sparseAbsoluteTolerance= -1},options {sparseRelativeTolerance=0/0},options {sparseIterationLimit= -1},options {sparseWorkspaceLimit=1}]])
    ,("sparse truncated SVD diagonal singular values",case sparseTruncatedSVD options 3 42 diagonal of Right f->closeVectors (sparseSingularValues f) [5,3,1] && checkSVD diagonal f; _->False)
    ,("sparse SVD negative diagonal has positive singular values",case sparseTruncatedSVD options 3 42 negative of Right f->closeVectors (sparseSingularValues f) [7,3,1] && checkSVD negative f; _->False)
    ,("sparse tall SVD singular values and residuals",case sparseTruncatedSVD options 2 7 tall of Right f->closeVectors (sparseSingularValues f) [4,2] && checkSVD tall f; _->False)
    ,("sparse wide SVD singular values and residuals",case sparseTruncatedSVD options 2 7 (sparseTranspose tall) of Right f->closeVectors (sparseSingularValues f) [4,2] && checkSVD (sparseTranspose tall) f; _->False)
    ,("sparse rank deficient SVD leading nonzero triplet",case sparseTruncatedSVD options 1 123 rankOne of Right f->closeVectors (sparseSingularValues f) [sqrt 10] && checkSVD rankOne f; _->False)
    ,("sparse requested null singular directions do not invent results",case sparseTruncatedSVD options 2 123 rankOne of Left _->True; Right f->checkSVD rankOne f && case sparseSingularValues f of [a,b]->close a (sqrt 10) && abs b<1e-8; _->False)
    ,("sparse zero matrix positive rank rejects",isLeft (sparseTruncatedSVD options 1 0 zero))
    ,("sparse zero requested rank empty factors",case sparseTruncatedSVD (options {sparseWorkspaceLimit=0}) 0 0 zero of Right f->sparseSingularValues f==[] && sparseLeftVectors f==[] && sparseRightVectors f==[]; _->False)
    ,("sparse empty SVD rank zero",case sparseTruncatedSVD options 0 0 empty of Right f->null (sparseSingularValues f); _->False)
    ,("sparse SVD rank shape errors",isLeft (sparseTruncatedSVD options (-1) 0 tall) && isLeft (sparseTruncatedSVD options 3 0 tall))
    ,("sparse SVD iteration budget enforced",isLeft (sparseTruncatedSVD (options {sparseIterationLimit=0}) 1 0 diagonal))
    ,("sparse SVD workspace enforced before vector allocation",isLeft (sparseTruncatedSVD (options {sparseWorkspaceLimit=1}) 1 0 diagonal))
    ,("sparse huge shape rejected by workspace without dense allocation",isLeft (sparseTruncatedSVD options 1 0 huge) && isLeft (sparseDominantEigen options huge []))
    ,("sparse SVD nonfinite input rejected",isLeft (sparseTruncatedSVD options 1 0 (sparseMatrix 2 2 [(0,0,0/0)])))
    ,("sparse deterministic seed repeatability",sparseTruncatedSVD options 2 45 diagonal==sparseTruncatedSVD options 2 45 diagonal)
    ,("sparse SVD vectors remain orthonormal",case sparseTruncatedSVD options 3 73 diagonal of Right f->orthonormal (sparseLeftVectors f) && orthonormal (sparseRightVectors f); _->False)
    ,("sparse SVD compact factors reconstruct small complete matrix",case sparseTruncatedSVD options 2 5 tall of Right f->and [close (entry tall i j) (sum [s*(u!!i)*(v!!j)|(s,u,v)<-zip3 (sparseSingularValues f) (sparseLeftVectors f) (sparseRightVectors f)])|i<-[0..3],j<-[0..1]]; _->False)
    ,("sparse spectral storage follows vectors and nonzeros",case sparseTruncatedSVD options 1 17 (sparseMatrix 10000 10000 [(9999,9999,5),(10,10,1)]) of Right f->closeVectors (sparseSingularValues f) [5] && map length (sparseLeftVectors f)==[10000] && map length (sparseRightVectors f)==[10000]; _->False)
    ,("sparse spectral Float paths",floatCheck)]
  where
    options=SparseSpectralOptions 1e-12 1e-10 1000 1000000
    diagonal=sparseMatrix 3 3 [(0,0,5),(1,1,3),(2,2,1)]
    negative=sparseMatrix 3 3 [(0,0,-7),(1,1,3),(2,2,-1)]
    symmetric=sparseMatrix 2 2 [(0,0,2),(0,1,1),(1,0,1),(1,1,2)]
    tall=sparseMatrix 4 2 [(0,0,4),(1,1,2)]
    rankOne=sparseMatrix 3 2 [(0,0,1),(0,1,1),(1,0,2),(1,1,2)]
    zero=sparseMatrix 3 3 []
    empty=sparseMatrix 0 0 []
    huge=sparseMatrix maxBound maxBound [(0,0,1)]
    floatCheck=case (do
        a<-sparse 2 2 [(0,0,4::Float),(1,1,-1)]
        e<-sparseDominantEigen (SparseSpectralOptions 1e-5 1e-5 100 1000) a [1,1]
        s<-sparseTruncatedSVD (SparseSpectralOptions 1e-5 1e-5 100 1000) 1 7 a
        pure (e,s)) of
            Right (e,s)->abs (sparseEigenvalue e-4)<1e-4 && case sparseSingularValues s of [value]->abs (value-4)<1e-4; _->False
            _->False

sparseMatrix :: Int -> Int -> [(Int,Int,Double)] -> Sparse Double
sparseMatrix m n xs=case sparse m n xs of Right a->a; Left err->error (show err)

checkEigen :: Sparse Double -> SparseEigenResult Double -> Bool
checkEigen a e=case spmv a (sparseEigenvector e) of
    Right av->close (norm (zipWith (\x y->x-sparseEigenvalue e*y) av (sparseEigenvector e))) (sparseEigenResidual e) && close (norm (sparseEigenvector e)) 1
    _->False

checkSVD :: Sparse Double -> SparseSVD Double -> Bool
checkSVD a f=and [case (spmv a v,spmv (sparseTranspose a) u) of
    (Right av,Right atu)->
        let left=norm (zipWith (\x y->x-s*y) av u)
            right=norm (zipWith (\x y->x-s*y) atu v)
        in left<1e-8 && right<1e-8 && close left lr && close right rr
            && close (norm u) 1 && close (norm v) 1
    _->False | (s,u,v,(lr,rr))<-zip4 (sparseSingularValues f) (sparseLeftVectors f) (sparseRightVectors f) (sparseSingularResiduals f)]

zip4 :: [a] -> [b] -> [c] -> [d] -> [(a,b,c,d)]
zip4 (a:as) (b:bs) (c:cs) (d:ds)=(a,b,c,d):zip4 as bs cs ds
zip4 _ _ _ _=[]

orthonormal :: [[Double]] -> Bool
orthonormal xs=and [close (dot a b) (if i==j then 1 else 0)|(i,a)<-zip [0::Int ..] xs,(j,b)<-zip [0::Int ..] xs]

entry :: Sparse Double -> Int -> Int -> Double
entry a i j=sum [v|(r,c,v)<-sparseEntries a,r==i,c==j]

close :: Double -> Double -> Bool
close a b=abs (a-b)<=1e-8*max 1 (max (abs a) (abs b))

closeVectors :: [Double] -> [Double] -> Bool
closeVectors a b=length a==length b && and (zipWith close a b)

dot :: [Double] -> [Double] -> Double
dot a b=sum (zipWith (*) a b)

norm :: [Double] -> Double
norm xs=sqrt (dot xs xs)
