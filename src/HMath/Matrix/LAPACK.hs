{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- | Double-precision LAPACKE spectral routines. All foreign buffers are private
-- copies; no Haskell storage is exposed or mutated. Inputs must be finite and
-- dimensions must fit the 32-bit LAPACK integer ABI. Pure wrappers are safe
-- because the called routines have no observable effects outside those buffers.
-- LAPACKE interfaces: https://www.netlib.org/lapack/lapacke.html
module HMath.Matrix.LAPACK
    ( SVD(..), svd, fullSVD, truncatedSVD, randomizedSVD, Eigen(..), eigen, symmetricEigen
    , GeneralizedEigen(..), generalizedEigen, Schur(..), schur
    , QZ(..), qz, Hessenberg(..), hessenberg, Balance(..), balance
    , ComplexSVD(..), complexSVD, complexEigen ) where

import Data.Complex (Complex((:+)),realPart,imagPart)
import Foreign
import Foreign.C.Types
import HMath.Error
import HMath.Matrix
import HMath.Matrix.Internal
import HMath.Matrix.QR (qrDecompose, qrQ)
import System.IO.Unsafe (unsafePerformIO)

foreign import ccall unsafe "LAPACKE_zgesdd" cComplexSVD :: CInt -> CChar -> CInt -> CInt -> Ptr (Complex CDouble) -> CInt -> Ptr CDouble -> Ptr (Complex CDouble) -> CInt -> Ptr (Complex CDouble) -> CInt -> IO CInt
foreign import ccall unsafe "LAPACKE_zgeev" cComplexEigen :: CInt -> CChar -> CChar -> CInt -> Ptr (Complex CDouble) -> CInt -> Ptr (Complex CDouble) -> Ptr (Complex CDouble) -> CInt -> Ptr (Complex CDouble) -> CInt -> IO CInt
foreign import ccall unsafe "LAPACKE_dsyev" cSymmetric :: CInt -> CChar -> CChar -> CInt -> Ptr CDouble -> CInt -> Ptr CDouble -> IO CInt
foreign import ccall unsafe "LAPACKE_dgesdd" cSVD :: CInt -> CChar -> CInt -> CInt -> Ptr CDouble -> CInt -> Ptr CDouble -> Ptr CDouble -> CInt -> Ptr CDouble -> CInt -> IO CInt
foreign import ccall unsafe "LAPACKE_dgeev" cEigen :: CInt -> CChar -> CChar -> CInt -> Ptr CDouble -> CInt -> Ptr CDouble -> Ptr CDouble -> Ptr CDouble -> CInt -> Ptr CDouble -> CInt -> IO CInt
foreign import ccall unsafe "LAPACKE_dggev" cGeneralized :: CInt -> CChar -> CChar -> CInt -> Ptr CDouble -> CInt -> Ptr CDouble -> CInt -> Ptr CDouble -> Ptr CDouble -> Ptr CDouble -> Ptr CDouble -> CInt -> Ptr CDouble -> CInt -> IO CInt
foreign import ccall unsafe "LAPACKE_dgees" cSchur :: CInt -> CChar -> CChar -> FunPtr a -> CInt -> Ptr CDouble -> CInt -> Ptr CInt -> Ptr CDouble -> Ptr CDouble -> Ptr CDouble -> CInt -> IO CInt
foreign import ccall unsafe "LAPACKE_dgges" cQZ :: CInt -> CChar -> CChar -> CChar -> FunPtr a -> CInt -> Ptr CDouble -> CInt -> Ptr CDouble -> CInt -> Ptr CInt -> Ptr CDouble -> Ptr CDouble -> Ptr CDouble -> Ptr CDouble -> CInt -> Ptr CDouble -> CInt -> IO CInt
foreign import ccall unsafe "LAPACKE_dgehrd" cHessenberg :: CInt -> CInt -> CInt -> CInt -> Ptr CDouble -> CInt -> Ptr CDouble -> IO CInt
foreign import ccall unsafe "LAPACKE_dorghr" cHessenbergQ :: CInt -> CInt -> CInt -> CInt -> Ptr CDouble -> CInt -> Ptr CDouble -> IO CInt
foreign import ccall unsafe "LAPACKE_dgebal" cBalance :: CInt -> CChar -> CInt -> Ptr CDouble -> CInt -> Ptr CInt -> Ptr CInt -> Ptr CDouble -> IO CInt

data SVD = SVD { svdU :: Matrix Double, singularValues :: [Double], svdVT :: Matrix Double } deriving (Eq,Show)
data Eigen = Eigen { eigenvalues :: [Complex Double], eigenvectors :: Matrix (Complex Double) } deriving (Eq,Show)
-- | Projective eigenvalues alpha/beta preserve infinite eigenvalues and
-- indeterminate singular pencils without dividing by a zero beta.
data GeneralizedEigen = GeneralizedEigen { eigenAlpha :: [Complex Double], eigenBeta :: [Double], generalizedEigenvectors :: Matrix (Complex Double) } deriving (Eq,Show)
data Schur = Schur { schurQ :: Matrix Double, schurT :: Matrix Double, schurEigenvalues :: [Complex Double] } deriving (Eq,Show)
data QZ = QZ { qzQ :: Matrix Double, qzZ :: Matrix Double, qzS :: Matrix Double, qzT :: Matrix Double, qzAlpha :: [Complex Double], qzBeta :: [Double] } deriving (Eq,Show)
data Hessenberg = Hessenberg { hessenbergQ :: Matrix Double, hessenbergH :: Matrix Double } deriving (Eq,Show)
-- | D^-1 A D = balancedMatrix. Scale-only balancing preserves index order.
data Balance = Balance { balancedMatrix :: Matrix Double, balanceScales :: [Double] } deriving (Eq,Show)

char :: Char -> CChar
char = fromIntegral . fromEnum
ni :: Int -> CInt
ni = fromIntegral
withValues :: [Double] -> (Ptr CDouble -> IO a) -> IO a
withValues xs = withArray (map realToFrac xs)
peekValues :: Int -> Ptr CDouble -> IO [Double]
peekValues n p = map realToFrac <$> peekArray n p
buffer :: Int -> (Ptr CDouble -> IO a) -> IO a
buffer n = allocaArray (max 1 n)
status :: String -> CInt -> Either MathError ()
status name info | info==0 = Right ()
                 | info<0 = Left (InvalidArgument (name++": LAPACKE rejected argument "++show (negate info)))
                 | otherwise = Left (NonConvergence name (fromIntegral info))
validate :: Matrix Double -> Either MathError ()
allocationSizes :: [Integer] -> Either MathError ()
allocationSizes sizes
    | any (\count -> count<0 || count*toInteger (sizeOf (undefined::CDouble))>toInteger (maxBound::Int)) sizes = Left (InvalidArgument "LAPACKE: byte allocation overflow")
    | otherwise = Right ()
validate a = do
    let (m,n)=shape a
    allocationSizes [toInteger m*toInteger n]
    if toInteger m>toInteger (maxBound::CInt) || toInteger n>toInteger (maxBound::CInt)
        then Left (InvalidArgument "LAPACKE: dimensions exceed 32-bit integer ABI") else finiteMatrix a
square :: Matrix Double -> Either MathError Int
square a | m/=n = Left (NonSquareMatrix (m,n))
         | otherwise = validate a >> Right n
    where (m,n)=shape a

{-# NOINLINE svd #-}
svd :: Matrix Double -> Either MathError SVD
svd a = do
    validate a
    let (m,n)=shape a; k=min m n
    allocationSizes [toInteger m*toInteger k,toInteger k*toInteger n]
    if k==0 then SVD <$> fromListChecked m 0 [] <*> pure [] <*> fromListChecked 0 n []
      else unsafePerformIO $ withValues (toList a) $ \pa -> buffer k $ \ps -> buffer (m*k) $ \pu -> buffer (k*n) $ \pv -> do
        info <- cSVD 101 (char 'S') (ni m) (ni n) pa (ni n) ps pu (ni k) pv (ni n)
        s <- peekValues k ps
        u <- peekValues (m*k) pu
        v <- peekValues (k*n) pv
        pure $ do status "SVD" info; finiteValues (s++u++v); SVD <$> fromListChecked m k u <*> pure s <*> fromListChecked k n v
{-# NOINLINE fullSVD #-}
-- | Full square U and V^T, including null-space completion.
fullSVD :: Matrix Double -> Either MathError SVD
fullSVD a = do
    validate a
    let (m,n)=shape a; k=min m n
    allocationSizes [toInteger m*toInteger m,toInteger n*toInteger n]
    if toInteger m*toInteger m>toInteger (maxBound::Int) || toInteger n*toInteger n>toInteger (maxBound::Int)
      then Left (InvalidArgument "fullSVD: full factor size overflow") else
      if k==0 then SVD <$> identityChecked m <*> pure [] <*> identityChecked n
      else unsafePerformIO $ withValues (toList a) $ \pa -> buffer k $ \ps -> buffer (m*m) $ \pu -> buffer (n*n) $ \pv -> do
        info <- cSVD 101 (char 'A') (ni m) (ni n) pa (ni n) ps pu (ni m) pv (ni n)
        s <- peekValues k ps
        u <- peekValues (m*m) pu
        v <- peekValues (n*n) pv
        pure $ do status "full SVD" info; finiteValues (s++u++v); SVD <$> fromListChecked m m u <*> pure s <*> fromListChecked n n v

truncatedSVD :: Int -> Matrix Double -> Either MathError SVD
truncatedSVD k a
    | k<0 || k>min m n = Left (InvalidArgument "truncatedSVD: invalid rank")
    | otherwise = do
        f <- svd a
        u <- sliceMatrixChecked (0,0) (m,k) (svdU f)
        v <- sliceMatrixChecked (0,0) (k,n) (svdVT f)
        Right (SVD u (take k (singularValues f)) v)
    where (m,n)=shape a
-- | Randomized range finder with an explicit seed, oversampling, and power
-- iterations, followed by a small deterministic SVD. The Gaussian test matrix
-- uses Box-Muller on a local LCG, so results are reproducible, not cryptographic.
randomizedSVD :: Int -> Int -> Int -> Integer -> Matrix Double -> Either MathError SVD
randomizedSVD k oversample power seed a
    | k<0 || k>min m n || oversample<0 || power<0 = Left (InvalidArgument "randomizedSVD: rank, oversampling, or power budget invalid")
    | otherwise = do
        validate a
        omega <- fromListChecked n l (take (n*l) (gaussian seed))
        y <- multiplyChecked a omega
        yFinal <- iteratePower power y
        qf <- qrDecompose yFinal
        q <- sliceMatrixChecked (0,0) (m,l) (qrQ qf)
        b <- multiplyChecked (transposeMatrix q) a
        f <- truncatedSVD k b
        u <- multiplyChecked q (svdU f)
        Right f {svdU=u}
    where
    (m,n)=shape a
    l=fromInteger (min (toInteger (min m n)) (toInteger k+toInteger oversample))
    iteratePower 0 y = Right y
    iteratePower p y = do
        qf <- qrDecompose y
        q <- sliceMatrixChecked (0,0) (m,l) (qrQ qf)
        z <- multiplyChecked (transposeMatrix a) q
        zf <- qrDecompose z
        zq <- sliceMatrixChecked (0,0) (n,l) (qrQ zf)
        multiplyChecked a zq >>= iteratePower (p-1)
    gaussian initial = pairs (map (\x -> (fromInteger x+0.5)/4294967296) (drop 1 (iterate (\x -> (1664525*x+1013904223) `mod` 4294967296) (initial `mod` 4294967296))))
    pairs (u:v:rest) = sqrt (-2*log u)*cos (2*pi*v) : sqrt (-2*log u)*sin (2*pi*v) : pairs rest
    pairs _ = []

complexVectors :: Int -> [Double] -> [Double] -> Either MathError (Matrix (Complex Double))
complexVectors n imag values = build n n $ \i j ->
    if imag!!j==0 then values!!(i*n+j):+0
    else if imag!!j>0 then values!!(i*n+j):+values!!(i*n+j+1)
    else values!!(i*n+j-1):+negate (values!!(i*n+j))
{-# NOINLINE eigen #-}
eigen :: Matrix Double -> Either MathError Eigen
eigen a = do
    n <- square a
    if n==0 then Eigen [] <$> fromListChecked 0 0 [] else unsafePerformIO $
      withValues (toList a) $ \pa -> buffer n $ \pr -> buffer n $ \pii -> buffer 1 $ \pl -> buffer (n*n) $ \pv -> do
        info <- cEigen 101 (char 'N') (char 'V') (ni n) pa (ni n) pr pii pl 1 pv (ni n)
        re <- peekValues n pr; im <- peekValues n pii; vs <- peekValues (n*n) pv
        pure $ do status "eigen" info; finiteValues (re++im++vs); Eigen (zipWith (:+) re im) <$> complexVectors n im vs
{-# NOINLINE symmetricEigen #-}
-- | Real symmetric eigensolver with orthonormal columns, sorted ascending.
symmetricEigen :: Matrix Double -> Either MathError Eigen
symmetricEigen a = do
    n <- square a
    if any (\(x,y) -> abs (x-y)>1e-12*max 1 (max (abs x) (abs y))) (zip (toList a) (toList (transposeMatrix a)))
      then Left (DomainError "symmetricEigen: symmetric matrix required") else
      if n==0 then Eigen [] <$> fromListChecked 0 0 [] else unsafePerformIO $
      withValues (toList a) $ \pa -> buffer n $ \pw -> do
        info <- cSymmetric 101 (char 'V') (char 'U') (ni n) pa (ni n) pw
        ws <- peekValues n pw; vs <- peekValues (n*n) pa
        pure $ do status "symmetricEigen" info; finiteValues (ws++vs); Eigen (map (:+0) ws) <$> fromListChecked n n (map (:+0) vs)

{-# NOINLINE generalizedEigen #-}
generalizedEigen :: Matrix Double -> Matrix Double -> Either MathError GeneralizedEigen
generalizedEigen a b = do
    n <- square a
    _ <- square b
    if shape a/=shape b then Left (ShapeMismatch (shape a) (shape b)) else
      if n==0 then GeneralizedEigen [] [] <$> fromListChecked 0 0 [] else unsafePerformIO $
      withValues (toList a) $ \pa -> withValues (toList b) $ \pb -> buffer n $ \pr -> buffer n $ \pii -> buffer n $ \pbe -> buffer 1 $ \pl -> buffer (n*n) $ \pv -> do
        info <- cGeneralized 101 (char 'N') (char 'V') (ni n) pa (ni n) pb (ni n) pr pii pbe pl 1 pv (ni n)
        re <- peekValues n pr; im <- peekValues n pii; be <- peekValues n pbe; vs <- peekValues (n*n) pv
        pure $ do status "generalizedEigen" info; finiteValues (re++im++be++vs); GeneralizedEigen (zipWith (:+) re im) be <$> complexVectors n im vs
{-# NOINLINE schur #-}
schur :: Matrix Double -> Either MathError Schur
schur a = do
    n <- square a
    if n==0 then Schur <$> identityChecked 0 <*> pure a <*> pure [] else unsafePerformIO $
      withValues (toList a) $ \pa -> alloca $ \sd -> buffer n $ \pr -> buffer n $ \pii -> buffer (n*n) $ \pq -> do
        info <- cSchur 101 (char 'V') (char 'N') nullFunPtr (ni n) pa (ni n) sd pr pii pq (ni n)
        re <- peekValues n pr; im <- peekValues n pii; qs <- peekValues (n*n) pq; ts <- peekValues (n*n) pa
        pure $ do status "Schur" info; finiteValues (re++im++qs++ts); Schur <$> fromListChecked n n qs <*> fromListChecked n n ts <*> pure (zipWith (:+) re im)
{-# NOINLINE qz #-}
qz :: Matrix Double -> Matrix Double -> Either MathError QZ
qz a b = do
    n <- square a
    _ <- square b
    if shape a/=shape b then Left (ShapeMismatch (shape a) (shape b)) else
      if n==0 then QZ <$> identityChecked 0 <*> identityChecked 0 <*> pure a <*> pure b <*> pure [] <*> pure [] else unsafePerformIO $
      withValues (toList a) $ \pa -> withValues (toList b) $ \pb -> alloca $ \sd -> buffer n $ \pr -> buffer n $ \pii -> buffer n $ \pbe -> buffer (n*n) $ \pq -> buffer (n*n) $ \pz -> do
        info <- cQZ 101 (char 'V') (char 'V') (char 'N') nullFunPtr (ni n) pa (ni n) pb (ni n) sd pr pii pbe pq (ni n) pz (ni n)
        re <- peekValues n pr; im <- peekValues n pii; be <- peekValues n pbe; qs <- peekValues (n*n) pq; zs <- peekValues (n*n) pz; ss <- peekValues (n*n) pa; ts <- peekValues (n*n) pb
        pure $ do status "QZ" info; finiteValues (re++im++be++qs++zs++ss++ts); QZ <$> fromListChecked n n qs <*> fromListChecked n n zs <*> fromListChecked n n ss <*> fromListChecked n n ts <*> pure (zipWith (:+) re im) <*> pure be
{-# NOINLINE hessenberg #-}
hessenberg :: Matrix Double -> Either MathError Hessenberg
hessenberg a = do
    n <- square a
    if n==0 then Hessenberg <$> identityChecked 0 <*> pure a else unsafePerformIO $
      withValues (toList a) $ \pa -> buffer (max 1 (n-1)) $ \pt -> do
        info <- cHessenberg 101 (ni n) 1 (ni n) pa (ni n) pt
        hs <- peekValues (n*n) pa
        infoQ <- cHessenbergQ 101 (ni n) 1 (ni n) pa (ni n) pt
        qs <- peekValues (n*n) pa
        pure $ do
            status "Hessenberg" info; status "Hessenberg Q" infoQ; finiteValues (hs++qs)
            h <- fromListChecked n n [if i>j+1 then 0 else hs!!(i*n+j) | i<-[0..n-1],j<-[0..n-1]]
            Hessenberg <$> fromListChecked n n qs <*> pure h
{-# NOINLINE balance #-}
balance :: Matrix Double -> Either MathError Balance
balance a = do
    n <- square a
    if n==0 then Right (Balance a []) else unsafePerformIO $
      withValues (toList a) $ \pa -> alloca $ \lo -> alloca $ \hi -> buffer n $ \ps -> do
        info <- cBalance 101 (char 'S') (ni n) pa (ni n) lo hi ps
        xs <- peekValues (n*n) pa; scales <- peekValues n ps
        pure $ do status "balance" info; finiteValues (xs++scales); Balance <$> fromListChecked n n xs <*> pure scales

-- | Complex128 thin SVD: A = U diag(s) V*, where complexVT already stores V*.
data ComplexSVD = ComplexSVD { complexU :: Matrix (Complex Double), complexSingularValues :: [Double], complexVT :: Matrix (Complex Double) } deriving (Eq,Show)
complexParts :: [Complex Double] -> [Double]
complexParts = concatMap (\z->[realPart z,imagPart z])
withComplex :: [Complex Double] -> (Ptr (Complex CDouble) -> IO a) -> IO a
withComplex xs = withArray [realToFrac (realPart z):+realToFrac (imagPart z) | z<-xs]
complexBuffer :: Int -> (Ptr (Complex CDouble) -> IO a) -> IO a
complexBuffer n = allocaArray (max 1 n)
peekComplex :: Int -> Ptr (Complex CDouble) -> IO [Complex Double]
peekComplex n p = map (\z->realToFrac (realPart z):+realToFrac (imagPart z)) <$> peekArray n p
validateComplex :: Matrix (Complex Double) -> Either MathError ()
validateComplex a = do
    let (m,n)=shape a
    allocationSizes [2*toInteger m*toInteger n]
    if toInteger m>toInteger (maxBound::CInt) || toInteger n>toInteger (maxBound::CInt) then Left (InvalidArgument "complex LAPACKE: dimensions exceed 32-bit integer ABI") else
        finiteValues (complexParts (toList a))
{-# NOINLINE complexSVD #-}
complexSVD :: Matrix (Complex Double) -> Either MathError ComplexSVD
complexSVD a = do
    validateComplex a
    let (m,n)=shape a;k=min m n
    allocationSizes [2*toInteger m*toInteger k,2*toInteger k*toInteger n]
    if k==0 then ComplexSVD <$> fromListChecked m 0 [] <*> pure [] <*> fromListChecked 0 n [] else unsafePerformIO $
        withComplex (toList a) $ \pa -> buffer k $ \ps -> complexBuffer (m*k) $ \pu -> complexBuffer (k*n) $ \pv -> do
            info<-cComplexSVD 101 (char 'S') (ni m) (ni n) pa (ni n) ps pu (ni k) pv (ni n)
            ss<-peekValues k ps;us<-peekComplex (m*k) pu;vs<-peekComplex (k*n) pv
            pure $ do status "complex SVD" info;finiteValues (ss++complexParts us++complexParts vs);ComplexSVD <$> fromListChecked m k us <*> pure ss <*> fromListChecked k n vs
{-# NOINLINE complexEigen #-}
complexEigen :: Matrix (Complex Double) -> Either MathError Eigen
complexEigen a = do
    validateComplex a
    let (m,n)=shape a
    if m/=n then Left (NonSquareMatrix (m,n)) else
        if n==0 then Eigen [] <$> fromListChecked 0 0 [] else unsafePerformIO $
        withComplex (toList a) $ \pa -> complexBuffer n $ \pw -> complexBuffer 1 $ \pl -> complexBuffer (n*n) $ \pv -> do
            info<-cComplexEigen 101 (char 'N') (char 'V') (ni n) pa (ni n) pw pl 1 pv (ni n)
            ws<-peekComplex n pw;vs<-peekComplex (n*n) pv
            pure $ do status "complex eigen" info;finiteValues (complexParts ws++complexParts vs);Eigen ws <$> fromListChecked n n vs
