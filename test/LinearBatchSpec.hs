{-# LANGUAGE DataKinds #-}
-- SPDX-License-Identifier: MPL-2.0
module LinearBatchSpec (linearBatchTests,linearBatchIOTests) where

import Data.Complex (Complex((:+)),magnitude,realPart)
import Data.Either (isLeft)
import Data.Proxy (Proxy(..))
import Foreign.Storable (pokeElemOff)
import qualified HMath.Vector as V
import HMath.Error
import HMath.Matrix
import HMath.Matrix.QR
import HMath.Matrix.LAPACK
import qualified HMath.Matrix.Advanced as A
import HMath.Matrix.Decomposition
import qualified HMath.Sparse as S
import qualified HMath.Tensor as T
import qualified HMath.Tensor.Mutable as TM

build :: Int -> Int -> (Int -> Int -> a) -> Either MathError (Matrix a)
build r c f = fromListChecked r c [f i j | i<-[0..r-1],j<-[0..c-1]]
get :: Matrix a -> Int -> Int -> a
get a i j = toList a!!(i*snd (shape a)+j)
mapEntries :: (a -> b) -> Matrix a -> Matrix b
mapEntries f a = either (error.show) id (fromListChecked (fst (shape a)) (snd (shape a)) (map f (toList a)))
matrix :: Int -> Int -> [Double] -> Matrix Double
matrix r c xs = either (error.show) id (fromListChecked r c xs)
mat :: Int -> Int -> [Int] -> Matrix Int
mat r c xs = either (error.show) id (fromListChecked r c xs)
tensor :: [Int] -> [Int] -> T.Tensor Int
tensor dims xs = either (error.show) id (T.tensor dims xs)
close :: Double -> Double -> Bool
close a b = abs (a-b)<=1e-8*max 1 (max (abs a) (abs b))
closeList :: [Double] -> [Double] -> Bool
closeList a b = length a==length b && and (zipWith close a b)
closeM :: Matrix Double -> Matrix Double -> Bool
closeM a b = shape a==shape b && closeList (toList a) (toList b)
ok :: Either e Bool -> Bool
ok = either (const False) id
hasValues :: [Double] -> Either e [Double] -> Bool
hasValues expected = either (const False) (closeList expected)
identityM :: Int -> Matrix Double
identityM n = either (error.show) id (identityChecked n)
qrResidual :: Matrix Double -> Bool
qrResidual a = ok $ do
    f<-qrDecompose a
    reconstructed<-multiplyChecked (qrQ f) (qrR f)
    permuted<-build r c (\i j->get a i (qrPermutation f!!j))
    qtq<-multiplyChecked (transposeMatrix (qrQ f)) (qrQ f)
    Right (closeM reconstructed permuted && closeM qtq (identityM r))
    where (r,c)=shape a
svdResidual :: Matrix Double -> Bool
svdResidual a = ok $ do
    f<-svd a
    d<-diagonalChecked (singularValues f)
    ud<-multiplyChecked (svdU f) d
    reconstructed<-multiplyChecked ud (svdVT f)
    Right (closeM reconstructed a)
complexClose :: Complex Double -> Complex Double -> Bool
complexClose a b = magnitude (a-b)<=1e-8*max 1 (max (magnitude a) (magnitude b))
complexResidual :: Matrix Double -> Bool
complexResidual a = ok $ do
    f<-eigen a
    av<-multiplyChecked (mapEntries (:+0) a) (eigenvectors f)
    d<-diagonalChecked (eigenvalues f)
    vd<-multiplyChecked (eigenvectors f) d
    Right (and (zipWith complexClose (toList av) (toList vd)))
spd :: Matrix Double
spd=matrix 3 3 [4,1,1,1,3,0,1,0,2]
rect :: Matrix Double
rect=matrix 4 3 [1,2,0,2,0,1,0,1,3,2,1,1]
sparseFixture :: S.Sparse Double
sparseFixture = either (error.show) id (S.sparse 4 4 [(0,0,4),(0,2,1),(1,0,2),(1,1,3),(2,2,5),(3,1,1),(3,3,2)])
formatRoundtrip :: S.SparseFormat Double -> Bool
formatRoundtrip f = S.fromFormat f==Right sparseFixture
linearBatchTests :: [(String,Bool)]
linearBatchTests = generalFunctionTests++regressionTests++vectorTests++qrTests++spectralTests++advancedTests++decompositionTests++sparseTests++tensorTests

vectorTests :: [(String,Bool)]
vectorTests =
    [ ("fixed vector type-level dimension",fmap V.fixedValues (V.fixedVector [1,2,3::Int] :: Either MathError (V.FixedVector 3 Int))==Right [1,2,3])
    , ("fixed vector rejects wrong dimension",isLeft (V.fixedVector [1,2::Int] :: Either MathError (V.FixedVector 3 Int)))
    , ("sparse vector coalesces and eliminates zeros",fmap V.sparseVectorValues (V.sparseVector 4 [(2,5),(2,-5),(1,3::Int)])==Right [0,3,0,0])
    , ("sparse vector validates index",isLeft (V.sparseVector 2 [(2,1::Int)]))
    , ("vector slice bounds",fmap V.vectorValues (V.vectorSlice 1 2 (V.vector [1,2,3,4::Int]))==Right [2,3])
    , ("vector slice rejects overflow",isLeft (V.vectorSlice 1 maxBound (V.vector [1::Int])))
    , ("vector concatenate",fmap V.vectorValues (V.vectorConcat [V.vector [1,2::Int],V.vector [],V.vector [3]])==Right [1,2,3])
    , ("vector arithmetic",fmap V.vectorValues (V.vectorAdd (V.vector [1,2::Int]) (V.vector [3,4]))==Right [4,6])
    , ("vector dot length mismatch",isLeft (V.vectorDot (V.vector [1::Int]) (V.vector [])))
    , ("cross and scalar triple",V.triple (V.vector [1,0,0::Int]) (V.vector [0,1,0]) (V.vector [0,0,1])==Right 1)
    , ("outer product",fmap toList (V.outer (V.vector [1,2::Int]) (V.vector [3,4,5]))==Right [3,4,5,6,8,10])
    , ("vector norms",let v=V.vector [3,-4,0::Double] in V.norm0 v==2 && V.norm1 v==7 && V.norm2 v==5 && V.normInfinity v==4 && V.normP 2 v==Right 5)
    , ("scaled Euclidean norm avoids overflow",close (V.norm2 (V.vector [3e200,4e200])) 5e200)
    , ("norm NaN propagation",isNaN (V.norm2 (V.vector [0/0,0::Double])))
    , ("norm infinity propagation",isInfinite (V.norm2 (V.vector [1/0,1::Double])))
    , ("normalize rejects zero",isLeft (V.normalizeVector (V.vector [0,0::Double])))
    , ("normalize rejects nonfinite",isLeft (V.normalizeVector (V.vector [0/0::Double])))
    , ("projection",hasValues [3,0] (V.vectorValues <$> V.project (V.vector [3,4::Double]) (V.vector [1,0])))
    , ("reflection",hasValues [1,1] (V.vectorValues <$> V.reflect (V.vector [1,-1::Double]) (V.vector [0,1])))
    , ("refraction index one",hasValues [0,-1] (V.vectorValues <$> V.refract 1 (V.vector [0,-1::Double]) (V.vector [0,1])))
    , ("total internal reflection rejects",isLeft (V.refract 2 (V.vector [1,0::Double]) (V.vector [0,1])))
    , ("distance and angle",V.distance (V.vector [0,0::Double]) (V.vector [3,4])==Right 5 && either (const False) (`close` (pi/2)) (V.angle (V.vector [1,0::Double]) (V.vector [0,1])))
    , ("Gram Schmidt orthonormal",ok $ do basis<-V.gramSchmidt 1e-12 [V.vector [1,1,0::Double],V.vector [1,0,1]]; productValue<-V.vectorDot (basis!!0) (basis!!1);Right (close productValue 0&&all ((`close`1).V.norm2) basis))
    , ("Gram Schmidt rejects dependent input",isLeft (V.gramSchmidt 1e-12 [V.vector [1,1::Double],V.vector [2,2]]))
    ]
qrTests :: [(String,Bool)]
qrTests =
    [("QR reconstructs "++show dims,qrResidual (matrix r c values)) | (dims@(r,c),values)<-[((4,3),toList rect),((2,3),[1,2,3,4,5,6]),((3,2),[0,1,0,2,0,3]),((0,3),[]),((3,0),[]),((0,0),[])]]++
    [ ("QR solve exact overdetermined",hasValues [2,-1,3] (leastSquares rect [0,7,8,6]))
    , ("QR multiple RHS",ok $ do b<-fromListChecked 4 2 [0,0,7,14,8,16,6,12];x<-leastSquaresMatrix rect b;Right (closeList (toList x) [2,4,-1,-2,3,6]))
    , ("QR rank deficient solve rejects",isLeft (leastSquares (matrix 3 2 [1,2,2,4,3,6]) [1,2,3]))
    , ("QR underdetermined solve rejects",isLeft (leastSquares (matrix 1 2 [1,2]) [3]))
    , ("QR ridge handles underdetermined",hasValues [0.5,0] (ridgeSolve 1 (matrix 1 2 [1,0]) [1]))
    , ("QR ridge rejects negative regularization",isLeft (ridgeSolve (-1) rect [0,7,8,6]))
    , ("QR validates tolerance",isLeft (qrDecomposeWithTolerance (0/0) rect))
    , ("QR validates coefficients",isLeft (qrDecompose (matrix 1 1 [1/0])))
    , ("QR tiny coefficients",hasValues [1,2] (leastSquares (matrix 2 2 [1e-200,0,0,1e-200]) [1e-200,2e-200]))
    , ("QR huge coefficients",hasValues [1,2] (leastSquares (matrix 2 2 [1e200,0,0,1e200]) [1e200,2e200]))
    , ("QR apply Q and QT inverse",ok $ do f<-qrDecompose rect;b<-identityChecked 4;x<-applyQ f b >>= applyQT f;Right (closeM x b))
    ]
spectralTests :: [(String,Bool)]
spectralTests =
    [("SVD reconstruction "++show dims,svdResidual (matrix r c xs)) | (dims@(r,c),xs)<-[((4,3),toList rect),((2,3),[1,2,3,4,5,6]),((3,2),[1,2,2,4,3,6]),((0,2),[]),((2,0),[])]]++
    [ ("complex SVD rectangular reconstruction",ok $ do a<-fromListChecked 3 2 [1:+2,3:+0,0:+1,2:+(-1),4:+0,1:+1::Complex Double];f<-complexSVD a;d<-diagonalChecked (map (:+0) (complexSingularValues f));ud<-multiplyChecked (complexU f) d;rec<-multiplyChecked ud (complexVT f);Right (and (zipWith complexClose (toList a) (toList rec))))
    , ("complex eigenpair residual",ok $ do a<-fromListChecked 2 2 [1:+2,3:+0,0:+1,2:+(-1)::Complex Double];f<-complexEigen a;av<-multiplyChecked a (eigenvectors f);d<-diagonalChecked (eigenvalues f);vd<-multiplyChecked (eigenvectors f) d;Right (and (zipWith complexClose (toList av) (toList vd))))
    , ("full SVD wide null completion",ok $ do f<-fullSVD (matrix 1 3 [1,2,3]);Right (shape (svdU f)==(1,1)&&shape (svdVT f)==(3,3)))
    , ("truncated SVD size",ok $ do f<-truncatedSVD 1 rect;Right (shape (svdU f)==(4,1)&&shape (svdVT f)==(1,3)))
    , ("randomized SVD reconstructs full rank",ok $ do f<-randomizedSVD 3 0 2 42 rect;d<-diagonalChecked (singularValues f);ud<-multiplyChecked (svdU f) d;rec<-multiplyChecked ud (svdVT f);Right (closeM rec rect))
    , ("SVD rejects invalid rank",isLeft (truncatedSVD 4 rect))
    , ("SVD rejects huge zero-inner dimensions promptly",isLeft (svd (matrix 0 maxBound [])))
    , ("full SVD rejects output overflow promptly",isLeft (fullSVD (matrix maxBound 0 [])))
    , ("SVD rejects nonfinite",isLeft (svd (matrix 1 1 [0/0])))
    , ("complex eigenpairs residual",complexResidual (matrix 2 2 [0,-1,1,0]))
    , ("real eigenpairs residual",complexResidual spd)
    , ("symmetric eigenvectors orthogonal",ok $ do f<-symmetricEigen spd;q<-pure (mapEntries realPart (eigenvectors f));qtq<-multiplyChecked (transposeMatrix q) q;Right (closeM qtq (identityM 3)))
    , ("eigen non-square rejected",isLeft (eigen rect))
    , ("generalized eigenpairs projective residual",ok $ do f<-generalizedEigen spd (matrix 3 3 [2,0,0,0,3,0,0,0,4]);v<-pure (generalizedEigenvectors f);av<-multiplyChecked (mapEntries (:+0) spd) v;bv<-multiplyChecked (mapEntries (:+0) (matrix 3 3 [2,0,0,0,3,0,0,0,4])) v;Right (and [complexClose (get av i j*(eigenBeta f!!j:+0)) (get bv i j*(eigenAlpha f!!j)) | i<-[0..2],j<-[0..2]]))
    , ("generalized eigen infinite value retained",ok $ do f<-generalizedEigen (matrix 2 2 [1,0,0,1]) (matrix 2 2 [1,0,0,0]);Right (0 `elem` eigenBeta f))
    , ("Schur reconstruction",ok $ do f<-schur (matrix 3 3 [1,2,3,0,4,5,6,0,7]);qt<-multiplyChecked (schurQ f) (schurT f);rec<-multiplyChecked qt (transposeMatrix (schurQ f));Right (closeM rec (matrix 3 3 [1,2,3,0,4,5,6,0,7])))
    , ("QZ reconstructs both matrices",ok $ do f<-qz spd (matrix 3 3 [1,2,0,0,2,0,0,0,0]);qs<-multiplyChecked (qzQ f) (qzS f);a<-multiplyChecked qs (transposeMatrix (qzZ f));qt<-multiplyChecked (qzQ f) (qzT f);b<-multiplyChecked qt (transposeMatrix (qzZ f));Right (closeM a spd&&closeM b (matrix 3 3 [1,2,0,0,2,0,0,0,0])))
    , ("Hessenberg reconstruction",ok $ do f<-hessenberg spd;qh<-multiplyChecked (hessenbergQ f) (hessenbergH f);rec<-multiplyChecked qh (transposeMatrix (hessenbergQ f));Right (closeM rec spd&&abs (get (hessenbergH f) 2 0)<1e-12))
    , ("balance similarity",ok $ do a<-pure (matrix 2 2 [1,1e10,1e-10,2]);f<-balance a;Right (and [close (get (balancedMatrix f) i j) (get a i j*(balanceScales f!!j)/(balanceScales f!!i)) | i<-[0..1],j<-[0..1]]))
    ]
advancedTests :: [(String,Bool)]
advancedTests =
    [ ("symmetric constructor",fmap toList (A.symmetricMatrix (matrix 2 2 [1,2,4,3]))==Right [1,3,3,3])
    , ("Hermitian constructor",ok $ do a<-fromListChecked 2 2 [1:+2,2:+3,4:+1,3:+4::Complex Double];h<-A.hermitianMatrix a;Right (h==A.conjugateTranspose h))
    , ("complex matrix multiplication conjugate identity",ok $ do a<-fromListChecked 2 2 [1:+0,0:+1,0:+1,1:+0::Complex Double];productValue<-multiplyChecked a (A.conjugateTranspose a);Right (and (zipWith complexClose (toList productValue) [2,0,0,2])))
    , ("permutation matrix rejects duplicates",isLeft (A.permutationMatrix [0,0] :: Either MathError (Matrix Int)))
    , ("block matrix assembles",fmap toList (A.blockMatrix [[mat 1 1 [1],mat 1 2 [2,3]],[mat 2 1 [4,5],mat 2 2 [6,7,8,9]]])==Right [1,2,3,4,6,7,5,8,9])
    , ("block matrix rejects incompatible dimensions",isLeft (A.blockMatrix [[mat 1 1 [1],mat 2 1 [2,3]]]))
    , ("banded constructor",fmap toList (A.bandedMatrix 3 3 [(0,[1,2,3::Int]),(1,[4,5])])==Right [1,4,0,0,2,5,0,0,3])
    , ("Kronecker known result",fmap toList (A.kronecker (mat 2 1 [1,2]) (mat 1 2 [3,4]))==Right [3,4,6,8])
    , ("Khatri Rao known result",fmap toList (A.khatriRao (mat 2 2 [1,2,3,4]) (mat 2 2 [5,6,7,8]))==Right [5,12,7,16,15,24,21,32])
    , ("matrix negative power inverse",ok $ do b<-A.matrixPower (-1) spd;productValue<-multiplyChecked b spd;Right (closeM productValue (identityM 3)))
    , ("matrix trace",A.trace spd==Right 9)
    , ("matrix norm catalog",A.matrixNorm1 (matrix 2 2 [1,-2,3,4])==6 && A.matrixNormInfinity (matrix 2 2 [1,-2,3,4])==7 && close (A.frobeniusNorm (matrix 1 2 [3,4])) 5)
    , ("pseudoinverse Penrose reconstruction",ok $ do p<-A.pseudoinverse 1e-12 rect;ap<-multiplyChecked rect p;apa<-multiplyChecked ap rect;pa<-multiplyChecked p rect;pap<-multiplyChecked pa p;Right (closeM apa rect&&closeM pap p))
    , ("complex pseudoinverse Penrose residual",ok $ do a<-fromListChecked 2 3 [1:+2,3:+0,0:+1,2:+(-1),4:+0,1:+1::Complex Double];p<-A.complexPseudoinverse 1e-12 a;ap<-multiplyChecked a p;apa<-multiplyChecked ap a;Right (and (zipWith complexClose (toList apa) (toList a))))
    , ("rank detects dependent columns",A.matrixRank 1e-12 (matrix 3 2 [1,2,2,4,3,6])==Right 1)
    , ("null space residual",ok $ do a<-pure (matrix 2 3 [1,2,3,2,4,6]);basis<-A.nullSpace 1e-12 a;productValue<-multiplyChecked a basis;Right (shape basis==(3,2)&&all (`close`0) (toList productValue)))
    , ("column space dimension",fmap shape (A.columnSpace 1e-12 rect)==Right (4,3))
    , ("row space dimension",fmap shape (A.rowSpace 1e-12 rect)==Right (3,3))
    , ("condition identity",A.conditionNumber (identityM 3)==Right 1)
    , ("matrix exponential diagonal",ok $ do x<-A.matrixExp 1e-14 100 (matrix 2 2 [1,0,0,2]);Right (closeList (toList x) [exp 1,0,0,exp 2]))
    , ("matrix exponential nilpotent",ok $ do x<-A.matrixExp 1e-14 100 (matrix 2 2 [0,3,0,0]);Right (closeList (toList x) [1,3,0,1]))
    , ("matrix exponential overflowing norm fails safely",isLeft (A.matrixExp 1e-14 100 (matrix 2 2 [1e308,1e308,1e308,1e308])))
    , ("matrix exponential budget exhaustion",isLeft (A.matrixExp 1e-16 1 spd))
    , ("matrix sqrt residual",ok $ do root<-A.matrixSqrt spd;squared<-multiplyChecked root root;Right (closeM squared spd))
    , ("matrix logarithm inverse exponential",ok $ do logarithm<-A.matrixLog spd;x<-A.matrixExp 1e-14 100 logarithm;Right (closeM x spd))
    , ("matrix log rejects negative spectrum",isLeft (A.matrixLog (matrix 2 2 [-1,0,0,2])))
    , ("polar reconstruction",ok $ do (u,p)<-A.polar rect;rec<-multiplyChecked u p;Right (closeM rec rect))
    ]
decompositionTests :: [(String,Bool)]
decompositionTests =
    [ ("Gaussian pivots",ok $ do (_,p)<-gaussianElimination 1e-12 (matrix 2 3 [0,1,2,1,1,3]);Right (p==[0,1]))
    , ("Gauss Jordan reference",ok $ do (r,p)<-gaussJordan 1e-12 (matrix 2 3 [0,1,2,1,1,3]);Right (p==[0,1]&&closeList (toList r) [1,0,1,0,1,2]))
    , ("Cholesky reconstruction",ok $ do l<-cholesky spd;rec<-multiplyChecked l (transposeMatrix l);Right (closeM rec spd))
    , ("Cholesky rejects indefinite",isLeft (cholesky (matrix 2 2 [1,2,2,1])))
    , ("Cholesky rejects asymmetry",isLeft (cholesky (matrix 2 2 [1,2,0,1])))
    , ("LDLT reconstruction",ok $ do (l,ds)<-ldlt spd;d<-diagonalChecked ds;ld<-multiplyChecked l d;rec<-multiplyChecked ld (transposeMatrix l);Right (closeM rec spd))
    , ("Givens QR reconstruction",ok $ do (q,r)<-givensQR rect;rec<-multiplyChecked q r;qtq<-multiplyChecked (transposeMatrix q) q;Right (closeM rec rect&&closeM qtq (identityM 4)))
    , ("bidiagonal reconstruction",ok $ do f<-bidiagonalize rect;ub<-multiplyChecked (bidiagonalU f) (bidiagonalB f);rec<-multiplyChecked ub (transposeMatrix (bidiagonalV f));Right (closeM rec rect))
    , ("tridiagonal reconstruction",ok $ do (q,t)<-tridiagonalize spd;qt<-multiplyChecked q t;rec<-multiplyChecked qt (transposeMatrix q);Right (closeM rec spd&&abs (get t 0 2)<1e-8&&abs (get t 2 0)<1e-8))
    , ("power iteration dominant eigenvalue",ok $ do f<-powerIteration 1e-10 200 (matrix 2 2 [3,0,0,1]) [1,1];Right (close (iterationValue f) 3&&iterationResidual f<1e-8))
    , ("inverse iteration closest shift",ok $ do f<-inverseIteration 1e-10 200 0 (matrix 2 2 [3,0,0,1]) [1,1];Right (close (iterationValue f) 1))
    , ("Rayleigh iteration residual",ok $ do f<-rayleighIteration 1e-10 30 (matrix 2 2 [3,0,0,1]) [1,0.1];Right (close (iterationValue f) 3))
    , ("power iteration budget exhaustion",isLeft (powerIteration 1e-16 1 spd [1,1,1]))
    , ("Arnoldi projection residual",ok $ do f<-arnoldi 1e-12 2 spd [1,0,0];q<-sliceMatrixChecked (0,0) (3,2) (arnoldiBasis f);aq<-multiplyChecked spd q;qh<-multiplyChecked (arnoldiBasis f) (arnoldiHessenberg f);Right (closeM aq qh))
    , ("Lanczos recurrence projection residual",ok $ do f<-lanczos 1e-12 2 spd [1,0,0];q<-sliceMatrixChecked (0,0) (3,2) (arnoldiBasis f);aq<-multiplyChecked spd q;qh<-multiplyChecked (arnoldiBasis f) (arnoldiHessenberg f);Right (closeM aq qh))
    , ("Lanczos symmetric validation",isLeft (lanczos 1e-12 2 (matrix 2 2 [1,2,0,3]) [1,0]))
    , ("QR eigen iteration similarity",ok $ do (q,t)<-qrIteration 1e-10 200 spd;qt<-multiplyChecked q t;rec<-multiplyChecked qt (transposeMatrix q);Right (closeM rec spd))
    , ("Jordan chains validated",ok $ do (p,j)<-jordanChains 1e-12 (matrix 2 2 [2,1,0,2]) [(2,[[1,0],[0,1]])];Right (p==identityM 2&&j==matrix 2 2 [2,1,0,2]))
    , ("exact Jordan form computes chains",ok $ do a<-fromListChecked 2 2 [1,1,-1,3::Rational];(p,j)<-jordanForm a [2];ap<-multiplyChecked a p;pj<-multiplyChecked p j;Right (ap==pj&&toList j==[2,1,0,2]))
    , ("exact Jordan mixed eigenvalues and chain sizes",ok $ do a<-fromListChecked 4 4 [0,1,0,0,0,0,1,0,0,0,0,0,0,0,0,2::Rational];(p,j)<-jordanForm a [0,2];ap<-multiplyChecked a p;pj<-multiplyChecked p j;Right (ap==pj&&toList j==toList a))
    , ("exact Jordan incomplete spectrum rejected",isLeft (fromListChecked 2 2 [1,0,0,2::Rational] >>= (\a->jordanForm a [1])))
    , ("Jordan chains reject wrong residual",isLeft (jordanChains 1e-12 (matrix 2 2 [2,1,0,2]) [(3,[[1,0],[0,1]])]))
    ]
sparseTests :: [(String,Bool)]
sparseTests =
    [ ("COO roundtrip",formatRoundtrip (S.toCOO sparseFixture))
    , ("CSR roundtrip",formatRoundtrip (S.toCSR sparseFixture))
    , ("CSC roundtrip",formatRoundtrip (S.toCSC sparseFixture))
    , ("DIA roundtrip",formatRoundtrip (S.toDIA sparseFixture))
    , ("BSR edge padded roundtrip",either (const False) formatRoundtrip (S.toBSR 3 2 sparseFixture))
    , ("ELLPACK roundtrip",either (const False) formatRoundtrip (S.toELLPACK sparseFixture))
    , ("COO coalesces and eliminates zeros",fmap S.sparseEntries (S.sparse 2 3 [(1,2,4::Int),(0,1,2),(1,2,-4)])==Right [(0,1,2)])
    , ("CSR rejects malformed pointers",isLeft (S.fromFormat (S.CSR 2 2 [0,2,1] [0] [1::Int])))
    , ("CSR rejects unsorted indices",isLeft (S.fromFormat (S.CSR 1 2 [0,2] [1,0] [1,2::Int])))
    , ("CSC rejects out of range indices",isLeft (S.fromFormat (S.CSC 1 1 [0,1] [1] [1::Int])))
    , ("DIA rejects nonzero padding",isLeft (S.fromFormat (S.DIA 2 2 [(1,[1,2::Int])])))
    , ("DIA rejects duplicate offsets",isLeft (S.fromFormat (S.DIA 2 2 [(0,[1,2::Int]),(0,[3,4])])))
    , ("BSR rejects block element count",isLeft (S.fromFormat (S.BSR 2 2 2 2 [0,1] [0] [[1::Int]])))
    , ("BSR rejects edge padding",isLeft (S.fromFormat (S.BSR 1 1 2 2 [0,1] [0] [[1,2,0,0::Int]])))
    , ("ELLPACK rejects padding",isLeft (S.fromFormat (S.ELLPACK 1 2 2 [0,-1] [1,2::Int])))
    , ("SpMV reference",hasValues [7,8,15,10] (S.spmv sparseFixture [1,2,3,4]))
    , ("SpMM dense agreement",ok $ do productSparse<-S.spmm sparseFixture (S.sparseTranspose sparseFixture);dense<-S.sparseToDense sparseFixture;reference<-multiplyChecked dense (transposeMatrix dense);actual<-S.sparseToDense productSparse;Right (closeM actual reference))
    , ("sparse transpose involution",S.sparseTranspose (S.sparseTranspose sparseFixture)==sparseFixture)
    , ("sparse subtraction cancels",fmap S.nonzeros (S.sparseSubtract sparseFixture sparseFixture)==Right 0)
    , ("sparse Kronecker dense agreement",ok $ do s<-S.sparseKronecker sparseFixture sparseFixture;dense<-S.sparseToDense sparseFixture;reference<-A.kronecker dense dense;actual<-S.sparseToDense s;Right (closeM actual reference))
    , ("sparse LU solve residual",ok $ do f<-S.sparseLU 1e-12 sparseFixture;x<-S.sparseSolveLU f [1,2,3,4];b<-S.spmv sparseFixture x;Right (closeList b [1,2,3,4]))
    , ("sparse LU row swaps preserve lower multipliers",ok $ do a<-S.sparse 3 3 [(0,0,1),(0,1,2),(0,2,3),(1,0,2),(1,1,4),(1,2,8),(2,0,3),(2,1,8),(2,2,9::Double)];f<-S.sparseLU 0 a;x<-S.sparseSolveLU f [6,14,20];Right (closeList x [1,1,1]))
    , ("sparse Cholesky reconstructs",ok $ do l<-S.sparseCholesky (S.denseToSparse spd);actual<-S.spmm l (S.sparseTranspose l) >>= S.sparseToDense;Right (closeM actual spd))
    , ("sparse Cholesky rejects indefinite",isLeft (S.sparseCholesky (S.denseToSparse (matrix 2 2 [1,2,2,1]))))
    , ("sparse QR transformed RHS",ok $ do f<-S.sparseQR (S.denseToSparse rect);values<-S.sparseQRApplyQT f [0,7,8,6];r<-S.sparseToDense (S.sparseQRUpper f);expected<-pure ([get r i 0*2-get r i 1+get r i 2*3 | i<-[0..3]]);Right (closeList values expected))
    , ("sparse diagonal solve",hasValues [1,2] (S.sparse 2 2 [(0,0,2::Double),(1,1,3)] >>= (`S.sparseDiagonalSolve` [2,6])))
    , ("sparse triangular solve",hasValues [1,2] (S.sparse 2 2 [(0,0,2::Double),(1,0,1),(1,1,3)] >>= (\a->S.sparseTriangularSolve True a [2,7])))
    , ("sparse eigen reference explicitly bounded",ok $ do f<-S.sparseEigenReference 16 (S.denseToSparse spd);Right (length (eigenvalues f)==3))
    , ("sparse SVD reference reconstructs",ok $ do f<-S.sparseSVDReference 16 (S.denseToSparse rect);d<-diagonalChecked (singularValues f);ud<-multiplyChecked (svdU f) d;rec<-multiplyChecked ud (svdVT f);Right (closeM rec rect))
    , ("sparse reference budget prevents densification",isLeft (S.sparseSVDReference 1 sparseFixture))
    , ("sparse graph adjacency",fmap (length . filter (not . null . snd)) (S.sparseGraph sparseFixture)==Right 4)
    , ("sparse storage scales with nonzeros",ok $ do small<-S.sparse 2 2 [(1,1,1::Int)];large<-S.sparse 1000000000 1000000000 [(1,1,1::Int)];Right (S.sparseStorageBytes 8 small==S.sparseStorageBytes 8 large))
    , ("sparse shape need not fit dense storage",ok $ do s<-S.sparse maxBound maxBound [(0,0,1::Int)];Right (S.nonzeros s==1&&isLeft (S.sparseToDense s)))
    , ("sparse tensor coalesces",fmap S.sparseTensorEntries (S.sparseTensor [2,3,4] [([1,2,3],1::Int),([1,2,3],2)])==Right [([1,2,3],3)])
    , ("sparse tensor scalar",fmap (\s->S.sparseTensorLookup s []) (S.sparseTensor [] [([],2::Int)])==Right (Right 2))
    ]++[("empty sparse conversion "++show dims,ok $ do s<-S.sparse r c ([]::[(Int,Int,Double)]);x<-S.fromFormat (S.toCSR s);y<-S.fromFormat (S.toCSC s);Right (s==x&&s==y)) | dims@(r,c)<-[(0,0),(0,3),(3,0)]]
tensorTests :: [(String,Bool)]
tensorTests =
    [ ("tensor scalar",T.tensorShape (tensor [] [7])==[] && T.tensorValues (tensor [] [7])==[7])
    , ("tensor rejects overflow",isLeft (T.tensor [maxBound,2] ([]::[Int])))
    , ("tensor empty huge dimensions",fmap T.numel (T.tensor [0,maxBound,maxBound] ([]::[Int]))==Right 0)
    , ("tensor huge empty strided iteration terminates",T.tensorValues (tensor [maxBound,0,maxBound] [])==[])
    , ("tensor column major logical order",fmap T.tensorValues (T.tensorColumnMajor [2,3] [1..6::Int])==Right [1,3,5,2,4,6])
    , ("tensor dtype device metadata",not (null (T.tensorDType (tensor [1] [1]))) && T.tensorDevice (tensor [1] [1])==T.CPU)
    , ("tensor initializers",fmap T.tensorValues (T.tensorZeros [2,2] :: Either MathError (T.Tensor Int))==Right [0,0,0,0] && fmap T.tensorValues (T.tensorOnes [2] :: Either MathError (T.Tensor Int))==Right [1,1])
    , ("tensor arange",fmap T.tensorValues (T.tensorArange 0 1 0.25::Either MathError (T.Tensor Double))==Right [0,0.25,0.5,0.75])
    , ("tensor negative arange",fmap T.tensorValues (T.tensorArange 3 0 (-1)::Either MathError (T.Tensor Double))==Right [3,2,1])
    , ("tensor linspace endpoint",fmap T.tensorValues (T.tensorLinspace 0 1 3::Either MathError (T.Tensor Double))==Right [0,0.5,1])
    , ("tensor random reproducible",T.tensorRandom 42 [3,4]==T.tensorRandom 42 [3,4])
    , ("tensor indexing bounds",T.indexTensor (tensor [2,3] [1..6]) [1,2]==Right 6 && isLeft (T.indexTensor (tensor [2,3] [1..6]) [2,0]))
    , ("tensor slice reversed view",fmap T.tensorValues (T.sliceTensor 1 2 3 (-1) (tensor [2,3] [1..6]))==Right [3,2,1,6,5,4])
    , ("tensor view strides retained",fmap T.tensorStrides (T.sliceTensor 1 2 3 (-1) (tensor [2,3] [1..6]))==Right [3,-1])
    , ("tensor fancy indexing",fmap T.tensorValues (T.fancyIndex 0 [1,0,1] (tensor [2,2] [1..4]))==Right [3,4,1,2,3,4])
    , ("tensor boolean indexing",fmap T.tensorValues (T.booleanIndex (either (error.show) id (T.tensor [4] [True,False,True,False])) (tensor [4] [1..4]))==Right [1,3])
    , ("tensor scatter repeated last write",fmap T.tensorValues (T.scatter 0 [1,1] (tensor [2] [5,7]) (tensor [3] [1,2,3]))==Right [1,7,3])
    , ("tensor scatter add repeats sum",fmap T.tensorValues (T.scatterAdd 0 [1,1] (tensor [2] [5,7]) (tensor [3] [1,2,3]))==Right [1,14,3])
    , ("tensor reshape strided copy order",fmap T.tensorValues (T.transposeTensor (tensor [2,3] [1..6]) >>= T.reshapeTensor [6])==Right [1,4,2,5,3,6])
    , ("tensor squeeze unsqueeze",(T.unsqueeze 1 (tensor [2] [1,2]) >>= T.squeeze >>= (Right . T.tensorValues))==Right [1,2])
    , ("tensor transpose",fmap T.tensorValues (T.transposeTensor (tensor [2,3] [1..6]))==Right [1,4,2,5,3,6])
    , ("tensor moveaxis",fmap T.tensorShape (T.moveAxis 0 2 (tensor [2,1,3] [1..6]))==Right [1,3,2])
    , ("tensor broadcast stride zero",fmap T.tensorStrides (T.broadcastTo [2,3] (tensor [1,3] [1,2,3]))==Right [0,1])
    , ("tensor broadcasts zero with one",T.inferBroadcast [0,3] [1,3]==Right [0,3])
    , ("tensor rejects incompatible broadcast",isLeft (T.inferBroadcast [2,3] [3,2]))
    , ("tensor repeat",fmap T.tensorValues (T.repeatTensor 0 2 (tensor [2] [1,2]))==Right [1,1,2,2])
    , ("tensor tile",fmap T.tensorValues (T.tile [2] (tensor [2] [1,2]))==Right [1,2,1,2])
    , ("tensor concatenate",fmap T.tensorValues (T.concatenate 1 [tensor [2,1] [1,2],tensor [2,2] [3,4,5,6]])==Right [1,3,4,2,5,6])
    , ("tensor stack",fmap T.tensorValues (T.stack 1 [tensor [2] [1,2],tensor [2] [3,4]])==Right [1,3,2,4])
    , ("tensor split",fmap (map T.tensorValues) (T.splitTensor 0 [1,2] (tensor [3] [1,2,3]))==Right [[1],[2,3]])
    , ("tensor chunk",fmap (map T.tensorValues) (T.chunkTensor 0 2 (tensor [3] [1,2,3]))==Right [[1,2],[3]])
    , ("tensor pad",fmap T.tensorValues (T.padTensor [(1,2)] 0 (tensor [2] [1,2]))==Right [0,1,2,0,0])
    , ("tensor roll minBound shift",fmap T.tensorValues (T.roll 0 minBound (tensor [3] [1,2,3]))==Right [3,1,2])
    , ("tensor flip",fmap T.tensorValues (T.flipTensor 0 (tensor [3] [1,2,3]))==Right [3,2,1])
    , ("tensor rotate",fmap T.tensorValues (T.rotate 0 1 1 (tensor [2,2] [1,2,3,4]))==Right [2,4,1,3])
    , ("tensor sort argsort topk",fmap T.tensorValues (T.argsort (tensor [3] [3,1,2]))==Right [1,2,0] && fmap (T.tensorValues . fst) (T.topk 2 (tensor [3] [3,1,2]))==Right [3,2])
    , ("tensor unique",fmap T.tensorValues (T.unique (tensor [4] [2,1,2,3]))==Right [1,2,3])
    , ("tensor nonzero coordinates",fmap T.tensorValues (T.nonzero (tensor [2,2] [0,1,2,0]))==Right [0,1,1,0])
    , ("tensor elementwise broadcast",fmap T.tensorValues (T.tensorAdd (tensor [2,1] [1,2]) (tensor [3] [10,20,30]))==Right [11,21,31,12,22,32])
    , ("tensor reduction sum",fmap T.tensorValues (T.sumAxes [1] False (tensor [2,3] [1..6]))==Right [6,15])
    , ("tensor reduction empty sum identity",fmap T.tensorValues (T.sumAxes [1] False (tensor [2,0] []))==Right [0,0])
    , ("tensor reduction empty min rejected",isLeft (T.minAxes [1] False (tensor [2,0] [])))
    , ("tensor reduction duplicate axes rejected",isLeft (T.sumAxes [0,0] False (tensor [2] [1,2])))
    , ("tensor variance population",ok $ do t<-T.tensor [2,2] [1,3,2,4::Double];v<-T.varianceAxes [1] False t;Right (closeList (T.tensorValues v) [1,1]))
    , ("tensor stable norm avoids squaring overflow",ok $ do t<-T.tensor [2] [3e200,4e200::Double];n<-T.normAxes [0] False t;Right (closeList (T.tensorValues n) [5e200]))
    , ("tensor stable norm NaN propagation",ok $ do t<-T.tensor [2] [0/0,0::Double];n<-T.normAxes [0] False t;Right (all isNaN (T.tensorValues n)))
    , ("tensor stable norm infinity propagation",ok $ do t<-T.tensor [2] [1/0,1/0::Double];n<-T.normAxes [0] False t;Right (all isInfinite (T.tensorValues n)))
    , ("tensor cumulative sum",fmap T.tensorValues (T.cumulativeSum 1 (tensor [2,3] [1..6]))==Right [1,3,6,4,9,15])
    , ("tensor argmin first tied index",T.argmin (tensor [4] [3,1,1,2])==Right 1)
    , ("tensor tensordot",fmap T.tensorValues (T.tensordot [1] [0] (tensor [2,3] [1..6]) (tensor [3,1] [1,2,3]))==Right [14,32])
    , ("tensor einsum trace",fmap T.tensorValues (T.einsum ["ii"] "" [tensor [2,2] [1,2,3,4]])==Right [5])
    , ("tensor einsum matrix product",fmap T.tensorValues (T.einsum ["ij","jk"] "ik" [tensor [2,3] [1..6],tensor [3,1] [1,2,3]])==Right [14,32])
    , ("tensor batched matmul broadcasts",fmap T.tensorValues (T.batchedMatmul (tensor [2,2,2] [1,0,0,1,2,0,0,2]) (tensor [2,1] [3,4]))==Right [3,4,6,8])
    , ("tensor Kronecker",fmap T.tensorValues (T.tensorKronecker (tensor [2] [1,2]) (tensor [2] [3,4]))==Right [3,4,6,8])
    , ("tensor serialization roundtrip",T.deserializeTensor (T.serializeTensor (tensor [2,2] [1..4]))==Right (tensor [2,2] [1..4]))
    , ("tensor fused graph equals eager",ok $ do graph<-T.zipGraph (+) (T.mapGraph (*2) (T.inputGraph (tensor [2,1] [1,2]))) (T.inputGraph (tensor [3] [10,20,30]));fused<-T.evaluateGraph graph;Right (T.tensorValues fused==[12,22,32,14,24,34]))
    ]

linearBatchIOTests :: IO [(String,Bool)]
linearBatchIOTests = do
    created<-TM.thawTensor (tensor [2,3] [1..6])
    case created of
      Left _->pure [("mutable tensor initialization",False)]
      Right mutable->do
        let reversed=TM.sliceMutable 1 2 3 (-1) mutable
        result<-case reversed of Left e->pure (Left e);Right alias->TM.writeMutable alias [0,0] 99
        aliasValue<-TM.readMutable mutable [0,2]
        frozen<-TM.freezeTensor mutable
        _<-TM.writeMutable mutable [0,0] 88
        frozenCopy<-pure (fmap T.tensorValues frozen==Right [1,2,99,4,5,6])
        TM.withMutableBuffer mutable $ \pointer _ _->pokeElemOff pointer 1 77
        foreignValue<-TM.readMutable mutable [0,1]
        outOfBounds<-TM.readMutable mutable [2,0]
        pure
            [("mutable slices alias backing storage",result==Right ()&&aliasValue==Right 99)
            ,("immutable freeze copies mutable storage",frozenCopy)
            ,("shared pointer callback writes visible",foreignValue==Right 77)
            ,("mutable bounds validated",isLeft outOfBounds)
            ,("mutable alignment positive",TM.mutableAlignment (Proxy::Proxy Double)>0)]

regressionTests :: [(String,Bool)]
regressionTests =
    [ ("QR zero-order solve preserves huge empty RHS columns",ok $ do f<-qrDecompose (matrix 0 0 []);b<-fromListChecked 0 maxBound [];x<-solveMatrixQR f b;Right (shape x==(0,maxBound)&&null (toList x)))
    , ("QR zero rank tolerance accepts nonzero subnormal ratio",fmap qrRank (qrDecomposeWithTolerance 0 (matrix 2 2 [1e200,0,0,1e-200]))==Right 2)
    , ("banded constructor shape overflow rejects promptly",isLeft (A.bandedMatrix maxBound maxBound [(0,[]::[Int])]))
    , ("banded constructor huge empty shape terminates",fmap shape (A.bandedMatrix maxBound 0 [(0,[]::[Int])])==Right (maxBound,0))
    , ("Jordan chains reject NaN eigenvalue",isLeft (jordanChains 1e-8 (identityM 2) [(0/0,[[1,0],[0,1]])]))
    , ("power iteration rejects overflowing matrix norm",isLeft (powerIteration 1e-8 10 (matrix 2 2 [1e308,1e308,1e308,-1e308]) [1,0]))
    , ("QR iteration rejects overflowing matrix norm",isLeft (qrIteration 1e-8 10 (matrix 2 2 [1e308,1e308,1e308,-1e308])))
    , ("Givens rejects unrepresentable rotation norm",isLeft (givensQR (matrix 2 1 [1.7e308,1.7e308])))
    , ("bidiagonalization rejects overflowing final column",isLeft (bidiagonalize (matrix 2 1 [1.7e308,1.7e308])))
    , ("power iteration rejects overflowing initial norm",isLeft (powerIteration 1e-8 10 (identityM 2) [1.7e308,1.7e308]))
    , ("Arnoldi rejects overflowing initial norm",isLeft (arnoldi 1e-8 2 (identityM 2) [1.7e308,1.7e308]))
    , ("Lanczos rejects overflowing initial norm",isLeft (lanczos 1e-8 2 (identityM 2) [1.7e308,1.7e308]))
    , ("arange cancellation avoids intermediate overflow",hasValues [-1e308,-4e307,2e307,8e307] (T.tensorValues <$> T.tensorArange (-1e308) 1e308 6e307))
    , ("linspace opposite extremes midpoint finite",hasValues [-1e308,0,1e308] (T.tensorValues <$> T.tensorLinspace (-1e308) 1e308 3))
    ]

generalFunctionTests :: [(String,Bool)]
generalFunctionTests =
    [ ("nonsymmetric principal sqrt defective Jordan",ok $ do root<-A.matrixSqrtGeneral 1e-10 100 (matrix 2 2 [4,12,0,4]);Right (closeList (toList root) [2,3,0,2]))
    , ("nonsymmetric principal log defective Jordan",ok $ do logarithm<-A.matrixLogGeneral 1e-10 100 (matrix 2 2 [4,12,0,4]);Right (closeList (toList logarithm) [log 4,3,0,log 4]))
    , ("nonnormal principal sqrt residual",ok $ do root<-A.matrixSqrtGeneral 1e-10 100 (matrix 2 2 [4,1e6,0,9]);squared<-multiplyChecked root root;Right (closeM squared (matrix 2 2 [4,1e6,0,9])))
    , ("nonnormal principal log exponential residual",ok $ do logarithm<-A.matrixLogGeneral 1e-10 100 (matrix 2 2 [4,100,0,9]);reconstructed<-A.matrixExp 1e-14 100 logarithm;Right (closeM reconstructed (matrix 2 2 [4,100,0,9])))
    , ("principal sqrt complex conjugate spectrum real output",ok $ do root<-A.matrixSqrtGeneral 1e-10 100 (matrix 2 2 [0,-1,1,0]);Right (closeList (toList root) [sqrt 0.5,-sqrt 0.5,sqrt 0.5,sqrt 0.5]))
    , ("principal log rotation",ok $ do logarithm<-A.matrixLogGeneral 1e-10 100 (matrix 2 2 [0,-1,1,0]);Right (closeList (toList logarithm) [0,-pi/2,pi/2,0]))
    , ("general sqrt singular rejected",isLeft (A.matrixSqrtGeneral 1e-10 100 (matrix 2 2 [0,1,0,0])))
    , ("general log singular rejected",isLeft (A.matrixLogGeneral 1e-10 100 (matrix 2 2 [0,0,0,1])))
    , ("general sqrt negative real branch rejected",isLeft (A.matrixSqrtGeneral 1e-10 100 (matrix 2 2 [-1,0,0,2])))
    , ("general log negative real branch rejected",isLeft (A.matrixLogGeneral 1e-10 100 (matrix 2 2 [-1,0,0,2])))
    , ("general sqrt finite iteration budget",isLeft (A.matrixSqrtGeneral 1e-14 1 (matrix 2 2 [4,12,0,4])))
    , ("general log finite iteration budget",isLeft (A.matrixLogGeneral 1e-14 1 (matrix 2 2 [4,12,0,4])))
    , ("general matrix functions reject invalid tolerance",isLeft (A.matrixSqrtGeneral (0/0) 100 spd)&&isLeft (A.matrixLogGeneral 0 100 spd))
    , ("general matrix functions preserve empty shape",A.matrixSqrtGeneral 1e-10 100 (matrix 0 0 [])==Right (matrix 0 0 [])&&A.matrixLogGeneral 1e-10 100 (matrix 0 0 [])==Right (matrix 0 0 []))
    ]
