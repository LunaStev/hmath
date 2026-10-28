{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Checked dense CPU kernels with explicit, garbage-collected provider handles.
Inputs and outputs use private contiguous copies. No pointer escapes to the
caller and the immutable matrices are never mutated. Auto selection tries
OpenBLAS LP64, then the pure implementation; explicit selection never silently
falls back. Provider paths are executable native libraries and must be trusted.

OpenBLAS reports its integer ABI via openblas_get_config; BLIS reports both
query and BLAS integer widths. oneMKL's process-global interface layer is set
on first explicit selection: applications sharing MKL must select this handle
before other MKL use and must not change that layer afterwards. Accelerate's
system CBLAS uses LP64. Thread setters affect the provider globally; callers
serialize reconfiguration with other uses of that provider.

LAPACKE solve/spectral dispatch is independently configured by the environment
documented in "HMath.Matrix.LAPACK". LU factors, QR, Cholesky and least squares expose
the checked pure reference algorithms; the provider affects BLAS kernels only.
Batched operations loop over GEMM calls (no vendor batch-extension requirement).
-}
module HMath.Backend (
    Provider (..),
    IntegerABI (..),
    BackendRequest (..),
    Backend,
    BackendInfo (..),
    selectBackend,
    backendInfo,
    pureBackend,
    setBackendThreads,
    lapackAvailable,
    BackendLayout (..),
    Transpose (..),
    matrixFromLayout,
    matrixToLayout,
    axpy,
    dot,
    nrm2,
    gemv,
    gemm,
    complexAxpy,
    complexDot,
    complexNrm2,
    complexGemv,
    complexGemm,
    batchedGemm,
    stridedBatchedGemm,
    backendLU,
    backendQR,
    backendSolve,
    backendCholesky,
    backendLeastSquares,
    backendSVD,
    backendSymmetricEigen,
    pureSVD,
    pureSymmetricEigen,
    lapackStatus,
) where

import Control.Exception (mask_)
import Control.Monad (foldM)
import Data.Complex (Complex ((:+)), conjugate, imagPart, realPart)
import Data.List (sortOn, transpose)
import Data.Ord (Down (..))
import Foreign hiding (rotate)
import Foreign.C
import HMath.Error
import qualified HMath.Matrix as M
import qualified HMath.Matrix.Decomposition as D
import qualified HMath.Matrix.Internal as I
import qualified HMath.Matrix.LAPACK as L
import qualified HMath.Matrix.LU as LU
import qualified HMath.Matrix.QR as QR
import System.Environment (lookupEnv)
import System.IO.Unsafe (unsafePerformIO)

-- | Pure reference, OpenBLAS, BLIS, Intel oneMKL SDL, or Apple's system framework.
data Provider = Pure | OpenBLAS | BLIS | OneMKL | Accelerate deriving (Eq, Ord, Show, Enum)

-- | BLAS/LAPACK integer width; Haskell dimensions must additionally fit Int.
data IntegerABI = LP64 | ILP64 deriving (Eq, Ord, Show)

{- | Optional path overrides the provider default; Accelerate only accepts its
system framework. OpenBLAS custom symbol prefixes are unsupported; the usual
unsuffixed and 64_ suffixed builds are recognized.
-}
data BackendRequest = AutoBackend | RequireBackend Provider IntegerABI (Maybe FilePath)
    deriving (Eq, Show)

data BackendInfo = BackendInfo {selectedProvider :: Provider, selectedIntegerABI :: IntegerABI}
    deriving (Eq, Show)
data NativeBackend
data Backend = Backend !BackendInfo !(Maybe (ForeignPtr NativeBackend))

-- | Provider identity is immutable for the lifetime of a handle.
backendInfo :: Backend -> BackendInfo
backendInfo (Backend info _) = info

pureBackend :: Backend
pureBackend = Backend (BackendInfo Pure ILP64) Nothing
foreign import ccall safe "hmath_backend_open"
    cOpen :: CInt -> CInt -> CString -> Ptr CInt -> IO (Ptr NativeBackend)
foreign import ccall unsafe "&hmath_backend_close" cClose :: FinalizerPtr NativeBackend
foreign import ccall safe "hmath_backend_threads" cThreads :: Ptr NativeBackend -> CInt -> IO CInt
foreign import ccall safe "hmath_backend_vector"
    cVector ::
        Ptr NativeBackend -> CInt -> Int64 -> Double -> Ptr Double -> Ptr Double -> Ptr Double -> IO CInt
foreign import ccall safe "hmath_backend_gemv"
    cGemv ::
        Ptr NativeBackend ->
        CInt ->
        Int64 ->
        Int64 ->
        Double ->
        Ptr Double ->
        Ptr Double ->
        Double ->
        Ptr Double ->
        IO CInt
foreign import ccall safe "hmath_backend_gemm"
    cGemm ::
        Ptr NativeBackend ->
        CInt ->
        CInt ->
        CInt ->
        Int64 ->
        Int64 ->
        Int64 ->
        Ptr a ->
        Ptr a ->
        Int64 ->
        Ptr a ->
        Int64 ->
        Ptr a ->
        Ptr a ->
        IO CInt
foreign import ccall safe "hmath_lapack_solve" cSolve :: CInt -> Ptr Double -> Ptr Double -> IO CInt
foreign import ccall safe "hmath_lapack_available" cLapackAvailable :: IO CInt

-- | Availability of the once-initialized independent LAPACKE loader.
lapackAvailable :: IO Bool
lapackAvailable = (/= 0) <$> cLapackAvailable

selectBackend :: BackendRequest -> IO (Either MathError Backend)
selectBackend AutoBackend = do
    mode <- lookupEnv "HMATH_BACKEND"
    provider <- lookupEnv "HMATH_BLAS_PROVIDER"
    width <- lookupEnv "HMATH_BLAS_INTEGER_BITS"
    path <- lookupEnv "HMATH_BLAS_LIBRARY"
    case (mode, width) of
        _
            | maybe False (`notElem` ["auto", "pure", "openblas", "blis", "mkl", "accelerate"]) provider ->
                pure (Left (InvalidArgument "unknown HMATH_BLAS_PROVIDER"))
        (Just unknown, _)
            | unknown `notElem` ["auto", "pure"] ->
                pure (Left (InvalidArgument "HMATH_BACKEND must be auto or pure"))
        (_, Just unknown)
            | unknown `notElem` ["32", "64"] ->
                pure (Left (InvalidArgument "HMATH_BLAS_INTEGER_BITS must be 32 or 64"))
        _ ->
            let abi = if width == Just "64" then ILP64 else LP64
                requested = if mode == Just "pure" then Just "pure" else provider
             in case requested of
                    Just "pure" -> selectBackend (RequireBackend Pure abi Nothing)
                    Just "openblas" -> selectBackend (RequireBackend OpenBLAS abi path)
                    Just "blis" -> selectBackend (RequireBackend BLIS abi path)
                    Just "mkl" -> selectBackend (RequireBackend OneMKL abi path)
                    Just "accelerate" -> selectBackend (RequireBackend Accelerate abi path)
                    Just unknown | unknown /= "auto" -> pure (Left (InvalidArgument "unknown HMATH_BLAS_PROVIDER"))
                    _ -> do
                        native <- selectBackend (RequireBackend OpenBLAS abi path)
                        pure (Right (either (const pureBackend) id native))
selectBackend (RequireBackend Pure abi Nothing) = pure (Right (Backend (BackendInfo Pure abi) Nothing))
selectBackend (RequireBackend Pure _ (Just _)) = pure (Left (InvalidArgument "pure backend does not load a library path"))
selectBackend (RequireBackend _ _ (Just path)) | '\0' `elem` path = pure (Left (InvalidArgument "backend path contains NUL"))
selectBackend (RequireBackend provider abi path) = mask_ $ withCString (maybe "" id path) $ \p -> alloca $ \status -> do
    pointer <- cOpen (fromIntegral (fromEnum provider)) (if abi == LP64 then 32 else 64) p status
    code <- peek status
    if pointer == nullPtr
        then
            pure
                ( Left
                    ( DomainError
                        ("backend unavailable: " ++ show provider ++ " " ++ show abi ++ " (" ++ reason code ++ ")")
                    )
                )
        else Right . Backend (BackendInfo provider abi) . Just <$> newForeignPtr cClose pointer
  where
    reason 2 = "integer ABI incompatible or cannot be verified"
    reason 3 = "allocation failed"
    reason 4 = "required CBLAS symbols absent"
    reason _ = "library not found or native dispatch disabled"

{- | Positive thread count; Pure supports one thread. Accelerate has no supported
runtime setter and returns an explicit error. No implicit global restoration.
-}
setBackendThreads :: Backend -> Int -> IO (Either MathError ())
setBackendThreads b n
    | n < 1 || toInteger n > toInteger (maxBound :: CInt) =
        pure (Left (InvalidArgument "backend thread count must fit positive C int"))
    | otherwise = case b of
        Backend _ Nothing -> pure (if n == 1 then Right () else Left (DomainError "pure backend is single-threaded"))
        Backend _ (Just fp) -> withForeignPtr fp $ \p -> adapterStatus <$> cThreads p (fromIntegral n)

adapterStatus :: CInt -> Either MathError ()
adapterStatus 0 = Right ()
adapterStatus 2 = Left (InvalidArgument "backend integer extent or option invalid")
adapterStatus _ = Left (DomainError "backend operation unavailable")

{- | Convert the LAPACK convention without losing the distinction between an
invalid argument and failed numerical convergence. For factorization pivots
callers may instead map a positive code to SingularMatrix (info - 1).
-}
lapackStatus :: String -> Int -> Either MathError ()
lapackStatus _ 0 = Right ()
lapackStatus name n
    | n < 0 = Left (InvalidArgument (name ++ ": argument " ++ show (negate (toInteger n))))
    | otherwise = Left (NonConvergence name n)

data BackendLayout = RowMajor | ColumnMajor deriving (Eq, Show)
data Transpose = NoTranspose | Transpose | ConjugateTranspose deriving (Eq, Show)

-- | Layout conversion is a checked, explicit copy; zero shapes retain rank.
matrixFromLayout :: BackendLayout -> Int -> Int -> [a] -> Either MathError (M.Matrix a)
matrixFromLayout RowMajor m n = M.fromListChecked m n
matrixFromLayout ColumnMajor m n = fmap M.transposeMatrix . M.fromListChecked n m

matrixToLayout :: BackendLayout -> M.Matrix a -> [a]
matrixToLayout RowMajor = M.toList
matrixToLayout ColumnMajor = M.toList . M.transposeMatrix
transCode :: Transpose -> CInt
transCode NoTranspose = 111
transCode Transpose = 112
transCode ConjugateTranspose = 113
op :: (Num a) => (a -> a) -> Transpose -> M.Matrix a -> Either MathError (M.Matrix a)
op _ NoTranspose a = Right a
op _ Transpose a = Right (M.transposeMatrix a)
op conj ConjugateTranspose a = let t = M.transposeMatrix a in uncurry M.fromListChecked (M.shape t) (map conj (M.toList t))
finite :: [Double] -> Either MathError ()
finite = I.finiteValues
finiteC :: [Complex Double] -> Either MathError ()
finiteC = finite . concatMap (\z -> [realPart z, imagPart z])
extents :: Backend -> [Int] -> Either MathError ()
extents b dims
    | any (< 0) dims || any ((> limit) . toInteger) dims =
        Left (InvalidArgument "backend extent exceeds selected integer ABI")
    | otherwise = Right ()
  where
    limit = if selectedIntegerABI (backendInfo b) == LP64 then 2147483647 else toInteger (maxBound :: Int64)
allocation :: Int -> [Int] -> Either MathError ()
allocation bytes counts
    | any (\n -> toInteger (max 1 n) * toInteger bytes > toInteger (maxBound :: Int)) counts =
        Left (InvalidArgument "backend byte allocation overflow")
    | otherwise = Right ()
checkedList :: [Double] -> Either MathError [Double]
checkedList xs = finite xs >> Right xs
sameLength :: [a] -> [b] -> Either MathError Int
sameLength a b
    | length a /= length b = Left (VectorLengthMismatch (length a) (length b))
    | otherwise = Right (length a)
vectorOperation ::
    Backend -> Int -> Double -> [Double] -> [Double] -> IO (Either MathError [Double])
vectorOperation b kind alpha xs ys = case validate of
    Left e -> pure (Left e)
    Right n -> case b of
        Backend _ Nothing -> pure (reference kind)
        Backend _ (Just fp) | n > 0 -> withForeignPtr fp $ \p -> withArray xs $ \px -> withArray ys $ \py -> alloca $ \out -> do
            poke out 0
            status <- cVector p (fromIntegral kind) (fromIntegral n) alpha px py out
            values <- if kind == 0 then peekArray n py else (: []) <$> peek out
            pure (adapterStatus status >> checkedList values)
        _ -> pure (reference kind)
  where
    validate = do
        n <- sameLength xs ys
        extents b [n]
        allocation 8 [n]
        finite (alpha : xs ++ ys)
        Right n
    reference 0 = checkedList (zipWith (\x y -> alpha * x + y) xs ys)
    reference 1 = checkedList [sum (zipWith (*) xs ys)]
    reference _ = checkedList [I.stableNorm xs]
axpy :: Backend -> Double -> [Double] -> [Double] -> IO (Either MathError [Double])
axpy b = vectorOperation b 0

{- | Real inner product. Finite input and output; accumulation can overflow even
when exact cancellation would produce a finite mathematical result.
-}
dot :: Backend -> [Double] -> [Double] -> IO (Either MathError Double)
dot b x y = fmap (fmap (!! 0)) (vectorOperation b 1 0 x y)

nrm2 :: Backend -> [Double] -> IO (Either MathError Double)
nrm2 b x = fmap (fmap (!! 0)) (vectorOperation b 2 0 x (replicate (length x) 0))

-- | y := alpha op(A) x + beta y. Finite inputs are checked even for zero alpha.
gemv ::
    Backend ->
    Transpose ->
    Double ->
    M.Matrix Double ->
    [Double] ->
    Double ->
    [Double] ->
    IO (Either MathError [Double])
gemv b tr alpha a x beta y = case validate of
    Left e -> pure (Left e)
    Right aa -> case b of
        Backend _ (Just fp) | m > 0 && n > 0 -> withForeignPtr fp $ \p -> withArray (M.toList a) $ \pa -> withArray x $ \px -> withArray y $ \py -> do
            code <- cGemv p (transCode tr) (fromIntegral m) (fromIntegral n) alpha pa px beta py
            output <- peekArray (length y) py
            pure (adapterStatus code >> checkedList output)
        _ ->
            pure (checkedList [alpha * sum (zipWith (*) row x) + beta * v | (row, v) <- zip (I.entries aa) y])
  where
    (m, n) = M.shape a
    validate = do
        aa <- op id tr a
        let (r, c) = M.shape aa
        if length x /= c then Left (VectorLengthMismatch c (length x)) else Right ()
        if length y /= r then Left (VectorLengthMismatch r (length y)) else Right ()
        extents b [m, n]
        allocation 8 [length (M.toList a), length x, length y]
        finite (alpha : beta : M.toList a ++ x ++ y)
        Right aa

{- | C := alpha op(A) op(B) + beta C. Matrices and output must have compatible
shapes; all zero-dimensional cases use the reference arithmetic.
-}
gemm ::
    Backend ->
    Transpose ->
    Transpose ->
    Double ->
    M.Matrix Double ->
    M.Matrix Double ->
    Double ->
    M.Matrix Double ->
    IO (Either MathError (M.Matrix Double))
gemm = gemmWith 0 id finite

aComplex :: Complex Double -> [Double]
aComplex z = [realPart z, imagPart z]
complexGemm ::
    Backend ->
    Transpose ->
    Transpose ->
    Complex Double ->
    M.Matrix (Complex Double) ->
    M.Matrix (Complex Double) ->
    Complex Double ->
    M.Matrix (Complex Double) ->
    IO (Either MathError (M.Matrix (Complex Double)))
complexGemm = gemmWith 1 conjugate finiteC
gemmWith ::
    forall a.
    (Num a, Storable a) =>
    CInt ->
    (a -> a) ->
    ([a] -> Either MathError ()) ->
    Backend ->
    Transpose ->
    Transpose ->
    a ->
    M.Matrix a ->
    M.Matrix a ->
    a ->
    M.Matrix a ->
    IO (Either MathError (M.Matrix a))
gemmWith complexValues conj check b ta tb alpha a bb beta c = case validate of
    Left e -> pure (Left e)
    Right (aa, bbb, m, n, k) -> case b of
        Backend _ (Just fp) | m > 0 && n > 0 && k > 0 -> withForeignPtr fp $ \p -> with alpha $ \al -> with beta $ \be -> withArray (M.toList a) $ \pa -> withArray (M.toList bb) $ \pb -> withArray (M.toList c) $ \pc -> do
            code <-
                cGemm
                    p
                    complexValues
                    (transCode ta)
                    (transCode tb)
                    (fromIntegral m)
                    (fromIntegral n)
                    (fromIntegral k)
                    al
                    pa
                    (fromIntegral (snd (M.shape a)))
                    pb
                    (fromIntegral (snd (M.shape bb)))
                    be
                    pc
            output <- peekArray (m * n) pc
            pure (adapterStatus code >> check output >> M.fromListChecked m n output)
        _ -> pure $ do
            productM <- M.multiplyChecked aa bbb
            output <- M.addMatrixChecked (M.scaleMatrix alpha productM) (M.scaleMatrix beta c)
            check (M.toList output)
            Right output
  where
    validate = do
        aa <- op conj ta a
        bbb <- op conj tb bb
        let (m, k) = M.shape aa; (kk, n) = M.shape bbb
        if k /= kk then Left (InnerDimensionMismatch k kk) else Right ()
        if M.shape c /= (m, n) then Left (ShapeMismatch (m, n) (M.shape c)) else Right ()
        extents b [m, n, k, snd (M.shape a), snd (M.shape bb)]
        allocation
            (sizeOf (undefined :: a))
            [length (M.toList a), length (M.toList bb), length (M.toList c)]
        check (alpha : beta : M.toList a ++ M.toList bb ++ M.toList c)
        Right (aa, bbb, m, n, k)
complexAxpy ::
    Backend ->
    Complex Double ->
    [Complex Double] ->
    [Complex Double] ->
    IO (Either MathError [Complex Double])
complexAxpy b alpha x y = case sameLength x y >>= \n -> (,,) <$> M.fromListChecked n 1 x <*> M.fromListChecked 1 1 [1] <*> M.fromListChecked n 1 y of
    Left e -> pure (Left e)
    Right (a, one, c) -> fmap (fmap M.toList) (complexGemm b NoTranspose NoTranspose alpha a one 1 c)

-- | Set the Boolean to True for the Hermitian dot product (conjugate x).
complexDot ::
    Backend -> Bool -> [Complex Double] -> [Complex Double] -> IO (Either MathError (Complex Double))
complexDot b hermitian x y = case sameLength x y >>= \n ->
    (,,)
        <$> M.fromListChecked 1 n (if hermitian then map conjugate x else x)
        <*> M.fromListChecked n 1 y
        <*> M.fromListChecked 1 1 [0] of
    Left e -> pure (Left e)
    Right (a, bb, c) -> fmap (fmap ((!! 0) . M.toList)) (complexGemm b NoTranspose NoTranspose 1 a bb 0 c)

complexNrm2 :: Backend -> [Complex Double] -> IO (Either MathError Double)
complexNrm2 b = nrm2 b . concatMap aComplex
complexGemv ::
    Backend ->
    Transpose ->
    Complex Double ->
    M.Matrix (Complex Double) ->
    [Complex Double] ->
    Complex Double ->
    [Complex Double] ->
    IO (Either MathError [Complex Double])
complexGemv b tr alpha a x beta y = case (,) <$> M.fromListChecked (length x) 1 x <*> M.fromListChecked (length y) 1 y of
    Left e -> pure (Left e)
    Right (bb, c) -> fmap (fmap M.toList) (complexGemm b tr NoTranspose alpha a bb beta c)

{- | Uniform scalar/transpose options, independently checked matrix triples.
Earlier calls may execute before a later invalid item; no input is mutated.
-}
batchedGemm ::
    Backend ->
    Transpose ->
    Transpose ->
    Double ->
    Double ->
    [(M.Matrix Double, M.Matrix Double, M.Matrix Double)] ->
    IO (Either MathError [M.Matrix Double])
batchedGemm b ta tb alpha beta triples = fmap sequence (traverse (\(a, bb, c) -> gemm b ta tb alpha a bb beta c) triples)

{- | Row-major batches of A(m,k) and B(k,n). Strides count elements, may include
padding, and may be zero for broadcast. Extents are checked with Integer before
slicing; output batches are contiguous m*n matrices. No implicit transposes.
-}
stridedBatchedGemm ::
    Backend ->
    Int ->
    Int ->
    Int ->
    Int ->
    Int ->
    [Double] ->
    Int ->
    [Double] ->
    IO (Either MathError [M.Matrix Double])
stridedBatchedGemm b batches m n k strideA as strideB bs = case prepare of
    Left e -> pure (Left e)
    Right triples -> batchedGemm b NoTranspose NoTranspose 1 0 triples
  where
    extent size stride = if batches == 0 then 0 else toInteger (batches - 1) * toInteger stride + size
    prepare = do
        extents b [batches, m, n, k, strideA, strideB]
        let sa = toInteger m * toInteger k; sb = toInteger k * toInteger n
        if (strideA /= 0 && toInteger strideA < sa) || (strideB /= 0 && toInteger strideB < sb)
            then Left (InvalidArgument "strided batch overlaps; use zero stride for broadcast")
            else Right ()
        if extent sa strideA > toInteger (length as) || extent sb strideB > toInteger (length bs)
            then Left (InvalidArgument "strided batch buffer too short")
            else Right ()
        traverse
            ( \i ->
                (,,)
                    <$> M.fromListChecked m k (take (fromInteger sa) (drop (i * strideA) as))
                    <*> M.fromListChecked k n (take (fromInteger sb) (drop (i * strideB) bs))
                    <*> M.zeroMatrixChecked m n
            )
            [0 .. batches - 1]

backendLU :: Backend -> M.Matrix Double -> Either MathError (LU.LU Double)
backendLU _ = LU.luDecompose
backendQR :: Backend -> M.Matrix Double -> Either MathError (QR.QR Double)
backendQR _ = QR.qrDecompose
backendSolve :: Backend -> M.Matrix Double -> [Double] -> Either MathError [Double]
backendSolve (Backend _ Nothing) = LU.solve
backendSolve _ = nativeSolve
{-# NOINLINE nativeSolve #-}
nativeSolve :: M.Matrix Double -> [Double] -> Either MathError [Double]
nativeSolve a rhs = do
    let (m, n) = M.shape a
    if m /= n then Left (NonSquareMatrix (m, n)) else Right ()
    if length rhs /= n then Left (RightHandSideMismatch n (length rhs)) else Right ()
    if toInteger n > toInteger (maxBound :: CInt)
        then Left (InvalidArgument "LAPACKE solver index exceeds Int32")
        else Right ()
    I.finiteMatrix a
    finite rhs
    if n == 0
        then Right []
        else unsafePerformIO $ withArray (M.toList a) $ \pa -> withArray rhs $ \pb -> do
            code <- cSolve (fromIntegral n) pa pb
            output <- peekArray n pb
            pure $
                if code == -10000
                    then Left (DomainError "LAPACKE solve unavailable")
                    else
                        if code == -10002
                            then Left (DomainError "LAPACKE pivot allocation failed")
                            else
                                if code > 0
                                    then Left (SingularMatrix (fromIntegral code - 1))
                                    else lapackStatus "LAPACKE solve" (fromIntegral code) >> checkedList output
backendCholesky :: Backend -> M.Matrix Double -> Either MathError (M.Matrix Double)
backendCholesky _ = D.cholesky
backendLeastSquares :: Backend -> M.Matrix Double -> [Double] -> Either MathError [Double]
backendLeastSquares _ = QR.leastSquares
backendSVD :: Backend -> M.Matrix Double -> Either MathError L.SVD
backendSVD (Backend _ Nothing) = pureSVD
backendSVD _ = L.svd
backendSymmetricEigen :: Backend -> M.Matrix Double -> Either MathError L.Eigen
backendSymmetricEigen (Backend _ Nothing) = pureSymmetricEigen
backendSymmetricEigen _ = L.symmetricEigen

{- | Cyclic Jacobi symmetric eigensolver, at most 100 sweeps, ascending eigenvalues.
Scaled input avoids squared-norm overflow. This reference path is limited to
order 128 and reports nonconvergence rather than returning an unchecked factor.
-}
pureSymmetricEigen :: M.Matrix Double -> Either MathError L.Eigen
pureSymmetricEigen a = do
    let m = fst (M.shape a)
    if m /= n then Left (NonSquareMatrix (m, n)) else Right ()
    if n > 128 then Left (InvalidArgument "pure symmetric eigen: order exceeds 128") else Right ()
    I.finiteMatrix a
    if or
        [ abs (x - y) > 1e-12 * max 1 (max (abs x) (abs y))
        | (x, y) <- zip (M.toList a) (M.toList (M.transposeMatrix a))
        ]
        then Left (DomainError "pure symmetric eigen requires symmetric matrix")
        else Right ()
    let scale = maximum (0 : map abs (M.toList a))
        s = if scale == 0 then 1 else scale
        rows = map (map (/ s)) (I.entries a)
        ident = [[if i == j then 1 else 0 | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
    (d, v) <- sweeps 0 rows ident
    let order = sortOn (\i -> d !! i !! i) [0 .. n - 1]
        values = [d !! i !! i * s :+ 0 | i <- order]
    finiteC values
    vectors <- M.fromListChecked n n [v !! i !! j :+ 0 | i <- [0 .. n - 1], j <- order]
    Right (L.Eigen values vectors)
  where
    n = snd (M.shape a)
    pairs = [(p, q) | p <- [0 .. n - 1], q <- [p + 1 .. n - 1]]
    sweeps count d v
        | all (\(p, q) -> abs (d !! p !! q) <= 2e-15) pairs = Right (d, v)
        | count >= 100 = Left (NonConvergence "pure symmetric Jacobi eigen" count)
        | otherwise = let (dd, vv) = foldl rotate (d, v) pairs in sweeps (count + 1) dd vv
    rotate state@(d, v) (p, q)
        | abs (d !! p !! q) <= 2e-16 = state
        | otherwise =
            let ap = d !! p !! p
                aq = d !! q !! q
                b = d !! p !! q
                tau = (aq - ap) / (2 * b)
                t = if tau == 0 then 1 else signum tau / (abs tau + I.stableNorm [1, tau])
                c = 1 / sqrt (1 + t * t)
                s = t * c
                cols x =
                    map
                        ( \row ->
                            I.replace q (s * (row !! p) + c * (row !! q)) (I.replace p (c * (row !! p) - s * (row !! q)) row)
                        )
                        x
                dd = transpose (cols (transpose (cols d)))
                clean = I.replace q (I.replace p 0 (dd !! q)) (I.replace p (I.replace q 0 (dd !! p)) dd)
             in (clean, cols v)

{- | Thin real SVD by one-sided Jacobi orthogonalization, at most 100 sweeps,
dimensions <=128. Unlike a normal-equation SVD it does not form A^T A.
A deterministic orthogonal completion supplies zero-singular-value columns.
-}
pureSVD :: M.Matrix Double -> Either MathError L.SVD
pureSVD a = do
    I.finiteMatrix a
    let m = fst (M.shape a)
    if max m n > 128 then Left (InvalidArgument "pure SVD: dimensions exceed 128") else Right ()
    if m < n
        then do
            f <- pureSVD (M.transposeMatrix a)
            Right (L.SVD (M.transposeMatrix (L.svdVT f)) (L.singularValues f) (M.transposeMatrix (L.svdU f)))
        else
            if n == 0
                then L.SVD <$> M.fromListChecked m 0 [] <*> pure [] <*> M.fromListChecked 0 n []
                else do
                    let scale = maximum (0 : map abs (M.toList a))
                        s = if scale == 0 then 1 else scale
                        cols = transpose (map (map (/ s)) (I.entries a))
                        eye = [[if i == j then 1 else 0 | i <- [0 .. n - 1]] | j <- [0 .. n - 1]]
                    if or
                        (zipWith (\original scaled -> original /= 0 && scaled == 0) (M.toList a) (concat (transpose cols)))
                        then Left (DomainError "pure SVD: input dynamic range underflows global scaling")
                        else Right ()
                    (columns, vs) <- sweep 0 cols eye
                    let indices = sortOn (Down . (I.stableNorm . (columns !!))) [0 .. n - 1]
                        norms = [I.stableNorm (columns !! i) | i <- indices]
                    us <- foldM (complete m) [] (zip indices norms `zip` repeat columns)
                    let singular = map (* s) norms
                    finite singular
                    u <- M.fromListChecked m n (concat (transpose us))
                    vt <- M.fromListChecked n n (concat [vs !! i | i <- indices])
                    Right (L.SVD u singular vt)
  where
    n = snd (M.shape a)
    pairs = [(p, q) | p <- [0 .. n - 1], q <- [p + 1 .. n - 1]]
    inner x y = sum (zipWith (*) x y)
    -- Compare normalized correlation, not squared tiny norms: distinct
    -- representable columns may have products below the subnormal range.
    converged cols (p, q) =
        let x = cols !! p; y = cols !! q; nx = I.stableNorm x; ny = I.stableNorm y
         in nx == 0 || ny == 0 || abs (inner (map (/ nx) x) (map (/ ny) y)) <= 2e-14
    sweep count cols vs
        | all (converged cols) pairs = Right (cols, vs)
        | count >= 100 = Left (NonConvergence "pure one-sided Jacobi SVD" count)
        | otherwise = let (cc, vv) = foldl rotate (cols, vs) pairs in sweep (count + 1) cc vv
    rotate state@(cols, vs) pair@(p, q)
        | converged cols pair = state
        | otherwise =
            let x = cols !! p
                y = cols !! q
                pairScale = max (I.stableNorm x) (I.stableNorm y)
                xx = map (/ pairScale) x
                yy = map (/ pairScale) y
                aa = inner xx xx
                bb = inner yy yy
                ab = inner xx yy
                delta = (bb - aa) / 2
                -- This form avoids constructing delta/ab when a useful
                -- small rotation exists but that intermediate would overflow.
                t = if delta == 0 then 1 else ab / (delta + signum delta * I.stableNorm [delta, ab])
                c = 1 / sqrt (1 + t * t)
                s = t * c
                turn zs =
                    I.replace
                        q
                        (zipWith (\u v -> s * u + c * v) (zs !! p) (zs !! q))
                        (I.replace p (zipWith (\u v -> c * u - s * v) (zs !! p) (zs !! q)) zs)
             in (turn cols, turn vs)
    complete m previous ((idx, norm), cols)
        | norm > 0 = Right (previous ++ [map (/ norm) (cols !! idx)])
        | otherwise =
            let project v = foldl (\x u -> zipWith (-) x (map (inner x u *) u)) v previous
                candidates = [project (project [if i == j then 1 else 0 | i <- [0 .. m - 1]]) | j <- [0 .. m - 1]]
                good = filter ((> 1e-10) . I.stableNorm) candidates
             in case good of
                    [] -> Left (NonConvergence "pure SVD null-space completion" (length previous))
                    x : _ -> Right (previous ++ [map (/ I.stableNorm x) x])
