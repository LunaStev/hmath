{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}

-- SPDX-License-Identifier: MPL-2.0
module BackendAPISpec (backendAPITests, backendAPIIOTests) where

import Control.Exception (SomeException, bracket, evaluate, try)
import Data.Complex (Complex ((:+)), imagPart, realPart)
import Data.Either (isLeft)
import Data.Proxy (Proxy (..))
import Foreign.Storable (pokeElemOff)
import qualified HMath.API as A
import qualified HMath.Autodiff as AD
import qualified HMath.Backend as B
import HMath.Error
import qualified HMath.Matrix as M
import qualified HMath.Matrix.LAPACK as L
import qualified HMath.Matrix.LU as LU
import qualified HMath.Matrix.QR as QR
import qualified HMath.Tensor as T
import System.Environment (lookupEnv, setEnv, unsetEnv)

matrix :: Int -> Int -> [a] -> M.Matrix a
matrix m n = either (error . show) id . M.fromListChecked m n
close :: Double -> Double -> Bool
close a b = abs (a - b) <= 1e-9 * max 1 (max (abs a) (abs b))
closeList :: [Double] -> [Double] -> Bool
closeList x y = length x == length y && and (zipWith close x y)
closeM :: M.Matrix Double -> M.Matrix Double -> Bool
closeM a b = M.shape a == M.shape b && closeList (M.toList a) (M.toList b)
ok :: Either e Bool -> Bool
ok = either (const False) id
svdCheck :: M.Matrix Double -> Bool
svdCheck a = ok $ do
    f <- B.pureSVD a
    d <- M.diagonalChecked (L.singularValues f)
    reconstructed <- M.multiplyChecked (L.svdU f) d >>= (`M.multiplyChecked` L.svdVT f)
    uu <- M.multiplyChecked (M.transposeMatrix (L.svdU f)) (L.svdU f)
    vv <- M.multiplyChecked (L.svdVT f) (M.transposeMatrix (L.svdVT f))
    eye <- M.identityChecked (length (L.singularValues f))
    Right (closeM a reconstructed && closeM uu eye && closeM vv eye)
eigenCheck :: M.Matrix Double -> Bool
eigenCheck a = ok $ do
    f <- B.pureSymmetricEigen a
    let v = matrix (fst (M.shape a)) (snd (M.shape a)) (map realPart (M.toList (L.eigenvectors f)))
    d <- M.diagonalChecked (map realPart (L.eigenvalues f))
    av <- M.multiplyChecked a v
    vd <- M.multiplyChecked v d
    orth <- M.multiplyChecked (M.transposeMatrix v) v
    eye <- M.identityChecked (fst (M.shape a))
    Right (closeM av vd && closeM orth eye)
backendAPITests :: [(String, Bool)]
backendAPITests =
    [
        ( "backend layout row-column roundtrip"
        , ok $ do
            m <- B.matrixFromLayout B.ColumnMajor 2 3 [1, 4, 2, 5, 3, 6 :: Int]
            Right (M.toList m == [1 .. 6] && B.matrixToLayout B.ColumnMajor m == [1, 4, 2, 5, 3, 6])
        )
    ,
        ( "backend empty layout preserves shape"
        , fmap M.shape (B.matrixFromLayout B.ColumnMajor 0 4 ([] :: [Int])) == Right (0, 4)
        )
    , ("backend bad layout count rejected", isLeft (B.matrixFromLayout B.RowMajor 2 3 [1 :: Int]))
    ,
        ( "backend status conventions"
        , B.lapackStatus "test" 0 == Right ()
            && isLeft (B.lapackStatus "test" (-3))
            && B.lapackStatus "test" 2 == Left (NonConvergence "test" 2)
        )
    , ("backend minBound status remains defined", isLeft (B.lapackStatus "test" minBound))
    ,
        ( "API dynamic shapes"
        , fmap A.shapeElements (A.makeShape [2, 3, 4]) == Right 24
            && fmap A.shapeElements (A.makeShape []) == Right 1
        )
    ,
        ( "API shape overflow and negatives"
        , isLeft (A.makeShape [maxBound, 2]) && isLeft (A.makeShape [-1, 0])
        )
    ,
        ( "API zero dimension no overflow"
        , fmap A.shapeElements (A.makeShape [maxBound, maxBound, 0]) == Right 0
        )
    ,
        ( "API typed matrix product"
        , ok $ do
            x <- A.staticMatrix @2 @3 (matrix 2 3 [1 .. 6 :: Int])
            y <- A.staticMatrix @3 @1 (matrix 3 1 [1, 2, 3])
            z <- A.staticMultiply x y
            Right (M.toList (A.dynamicMatrix z) == [14, 32])
        )
    , ("API typed matrix mismatch", isLeft (A.staticMatrix @3 @2 (matrix 2 3 [1 .. 6 :: Int])))
    ,
        ( "API typed tensor"
        , ok $ do
            t <- T.tensor [2, 3] [1 .. 6 :: Int]; s <- A.staticTensor @'[2, 3] t; Right (A.dynamicTensor s == t)
        )
    ,
        ( "API typed tensor mismatch"
        , ok $ do t <- T.tensor [3, 2] [1 .. 6 :: Int]; Right (isLeft (A.staticTensor @'[2, 3] t))
        )
    ,
        ( "API coordinate applicative laws"
        , ok $ do
            x <- A.coordinates @3 [1, 2, 3 :: Int]
            Right ((pure id <*> x) == x && A.coordinateValues ((+) <$> x <*> pure 2) == [3, 4, 5])
        )
    ,
        ( "API coordinate traverse"
        , fmap (fmap A.coordinateValues) (A.coordinates @2 [Just (3 :: Int), Just 4] >>= Right . traverse id)
            == Right (Just [3, 4])
        )
    ,
        ( "API exact custom-domain Horner"
        , A.horner [A.Exact 2, A.Exact 3, A.Exact 4] (A.Exact (1 / 2)) == A.Exact 6
        )
    ,
        ( "API rational inverse"
        , A.invert (A.Exact (2 / 3)) == Right (A.Exact (3 / 2)) && isLeft (A.invert (A.Exact 0))
        )
    ,
        ( "API numeric narrowing rejects rational fraction"
        , isLeft (A.rational (1 / 2) :: Either MathError Integer)
        )
    ,
        ( "API float inverse overflow and NaN rejected"
        , isLeft (A.invert (1e-320 :: Double)) && isLeft (A.invert (0 / 0 :: Double))
        )
    ,
        ( "API complex tiny inverse remains finite"
        , ok $ do z <- A.invert (1e-308 :+ 1e-308); Right (close (realPart z) 5e307)
        )
    ,
        ( "API Hermitian generic inner product"
        , A.innerProduct [1 :+ 2, 3 :+ 0] [1 :+ 2, 3 :+ 0] == Right (14 :+ 0 :: Complex Double)
        )
    , ("API generic dimension mismatch", isLeft (A.innerProduct [1 :: Integer] []))
    , ("API epsilon contract", A.machineEpsilon (Proxy :: Proxy Double) == 2 ** (-52))
    , ("API differential reused Dual", A.differential (AD.Dual 3 (4 :: Int)) == 4)
    ,
        ( "API boxed mapping traversals"
        , A.boxedValues (fmap (+ 1) (A.lazyBoxed [1, 2 :: Int])) == [2, 3]
            && sum (A.lazyBoxed [1, 2, 3 :: Int]) == 6
        )
    ,
        ( "API unboxed roundtrip"
        , A.boxedValues (A.unboxedToBoxed (A.boxedToUnboxed (A.strictBoxed [1, 2, 3]))) == [1, 2, 3]
        )
    ,
        ( "API ST copy isolation"
        , let original = A.strictBoxed [1, 2, 3 :: Int]
              result = A.runSTBuffer original $ \b -> do _ <- A.writeSTBuffer b 1 99; A.freezeSTBuffer b
           in A.boxedValues result == [1, 99, 3] && A.boxedValues original == [1, 2, 3]
        )
    ,
        ( "API ST bad index"
        , A.runSTBuffer (A.lazyBoxed [1 :: Int]) (\b -> A.readSTBuffer b 1)
            == Left (InvalidArgument "buffer index out of bounds")
        )
    ,
        ( "API convergence initial zero iterations"
        , ok $ do
            r <- A.iterateUntil A.defaultIterationOptions (Right . (+ 1)) (Right . abs) (==) (0 :: Double)
            Right (A.iterationCount r == 0 && A.stopReason r == A.ResidualSatisfied)
        )
    ,
        ( "API convergence budget retained"
        , ok $ do
            r <- A.iterateUntil (A.IterationOptions 3 0 0) (Right . (/ 2)) (Right . abs) (==) (1 :: Double)
            Right
                ( A.estimate r == 0.125
                    && A.stopReason r == A.IterationLimit
                    && isLeft (A.requireConvergence "halve" r)
                )
        )
    ,
        ( "API convergence stagnation distinguished"
        , ok $ do
            r <- A.iterateUntil A.defaultIterationOptions Right (Right . abs) (==) (1 :: Double)
            Right (A.stopReason r == A.Stagnation && A.iterationCount r == 1)
        )
    ,
        ( "API convergence invalid residual rejected"
        , isLeft (A.iterateUntil A.defaultIterationOptions Right (const (Right (0 / 0))) (==) (1 :: Int))
        )
    ,
        ( "API Maybe Either explicit conversion"
        , A.resultMaybe (Left "bad" :: Either String Int) == Nothing
            && A.fromMaybeError "missing" Nothing == (Left "missing" :: Either String Int)
        )
    ,
        ( "pure symmetric eigen nonsymmetric rejected"
        , isLeft (B.pureSymmetricEigen (matrix 2 2 [1, 2, 3, 4]))
        )
    , ("pure SVD nonfinite rejected", isLeft (B.pureSVD (matrix 1 1 [0 / 0])))
    ,
        ( "pure SVD tiny dependent columns remain orthogonal"
        , svdCheck (matrix 3 3 [1, 0, 0, 0, 1e-200, 1e-200, 0, 0, 0])
        )
    ,
        ( "pure SVD tiny singular value preserved"
        , ok $ do
            f <- B.pureSVD (matrix 3 3 [1, 0, 0, 0, 1e-200, 1e-200, 0, 0, 0])
            Right (close ((L.singularValues f !! 1) / 1e-200) (sqrt 2) && L.singularValues f !! 2 == 0)
        )
    , ("pure SVD scaling underflow rejected", isLeft (B.pureSVD (matrix 2 2 [1e300, 0, 0, 1e-300])))
    ,
        ( "pure LU solve residual"
        , ok $ do x <- B.backendSolve B.pureBackend (matrix 2 2 [3, 1, 1, 2]) [9, 8]; Right (closeList x [2, 3])
        )
    ,
        ( "pure QR reconstruct"
        , ok $ do
            let a = matrix 3 2 [1, 0, 1, 1, 1, 2]
            f <- B.backendQR B.pureBackend a
            q <- M.multiplyChecked (QR.qrQ f) (QR.qrR f)
            Right (closeList (M.toList q) [M.toList a !! (i * 2 + j) | i <- [0 .. 2], j <- QR.qrPermutation f])
        )
    ,
        ( "pure Cholesky reconstruct"
        , ok $ do
            let a = matrix 2 2 [4, 2, 2, 3]
            l <- B.backendCholesky B.pureBackend a
            r <- M.multiplyChecked l (M.transposeMatrix l)
            Right (closeM a r)
        )
    ,
        ( "pure least squares"
        , ok $ do
            x <- B.backendLeastSquares B.pureBackend (matrix 3 2 [1, 0, 1, 1, 1, 2]) [1, 3, 5]
            Right (closeList x [1, 2])
        )
    , ("pure LU singular checked", isLeft (B.backendLU B.pureBackend (matrix 2 2 [1, 2, 2, 4])))
    ,
        ( "pure LU factors available"
        , ok $ do
            f <- B.backendLU B.pureBackend (matrix 2 2 [3, 1, 1, 2]); Right (M.shape (LU.luLower f) == (2, 2))
        )
    ]
        ++ [ ( "pure Jacobi SVD reconstruction " ++ show (m, n, seed)
             , svdCheck (matrix m n [sin (fromIntegral (i * 7 + seed)) | i <- [1 .. m * n]])
             )
           | m <- [0 .. 6]
           , n <- [0 .. 6]
           , seed <- [1, 3]
           ]
        ++ [ ("pure Jacobi SVD zero " ++ show (m, n), svdCheck (matrix m n (replicate (m * n) 0)))
           | m <- [0 .. 5]
           , n <- [0 .. 5]
           ]
        ++ [ ( "pure Jacobi eigen reconstruction " ++ show (n, seed)
             , eigenCheck (matrix n n [sin (fromIntegral (i + j + seed)) | i <- [0 .. n - 1], j <- [0 .. n - 1]])
             )
           | n <- [0 .. 8]
           , seed <- [1 .. 3]
           ]

kernelTests :: String -> B.Backend -> [(String, IO Bool)]
kernelTests label b =
    [ (label ++ " axpy", fmap (== Right [9, 12]) (B.axpy b 2 [1, 2] [7, 8]))
    , (label ++ " dot", fmap (== Right 11) (B.dot b [1, 2] [3, 4]))
    ,
        ( label ++ " norm scaling"
        , fmap (either (const False) (\x -> close (x / 1e300) 5)) (B.nrm2 b [3e300, 4e300])
        )
    , (label ++ " vector mismatch", isLeft <$> B.dot b [1] [])
    , (label ++ " nonfinite scalar rejected", isLeft <$> B.axpy b (0 / 0) [] [])
    ,
        ( label ++ " complex conjugate dot"
        , fmap (== Right (14 :+ 0)) (B.complexDot b True [1 :+ 2, 3 :+ 0] [1 :+ 2, 3 :+ 0])
        )
    ,
        ( label ++ " complex axpy"
        , fmap
            (== Right [(-4) :+ 7, (-2) :+ 9])
            (B.complexAxpy b (2 :+ 1) [1 :+ 2, 3 :+ 4] [(-4) :+ 2, (-4) :+ (-2)])
        )
    ,
        ( label ++ " gemv transpose"
        , fmap (== Right [10, 14, 18]) (B.gemv b B.Transpose 1 (matrix 2 3 [1 .. 6]) [2, 2] 0 [0, 0, 0])
        )
    ,
        ( label ++ " zero inner dimension"
        , fmap
            (fmap M.toList)
            (B.gemm b B.NoTranspose B.NoTranspose 2 (matrix 3 0 []) (matrix 0 2 []) 3 (matrix 3 2 [1 .. 6]))
            >>= pure . (== Right [3, 6, 9, 12, 15, 18])
        )
    ,
        ( label ++ " strided broadcast"
        , fmap (fmap (map M.toList)) (B.stridedBatchedGemm b 2 1 1 2 0 [1, 2] 3 [3, 4, 99, 5, 6])
            >>= pure . (== Right [[11], [17]])
        )
    , (label ++ " strided short buffer", isLeft <$> B.stridedBatchedGemm b 2 1 1 2 2 [1, 2] 2 [3, 4])
    , (label ++ " bad thread count", isLeft <$> B.setBackendThreads b 0)
    ]
        ++ [ ( label ++ " GEMM " ++ show (m, n, k, ta, tb)
             , do
                let a =
                        matrix
                            (if ta == B.NoTranspose then m else k)
                            (if ta == B.NoTranspose then k else m)
                            [sin (fromIntegral i) | i <- [1 .. m * k]]
                    bb =
                        matrix
                            (if tb == B.NoTranspose then k else n)
                            (if tb == B.NoTranspose then n else k)
                            [cos (fromIntegral i) | i <- [1 .. k * n]]
                    c = matrix m n (replicate (m * n) 0.5)
                expected <- B.gemm B.pureBackend ta tb 2 a bb (-1) c
                actual <- B.gemm b ta tb 2 a bb (-1) c
                pure (case (actual, expected) of (Right x, Right y) -> closeM x y; _ -> False)
             )
           | m <- [0 .. 3]
           , n <- [0 .. 3]
           , k <- [0 .. 3]
           , ta <- [B.NoTranspose, B.Transpose]
           , tb <- [B.NoTranspose, B.Transpose]
           ]
        ++ [ ( label ++ " complex GEMM " ++ show (ta, tb)
             , do
                let a = matrix 2 2 [1 :+ 2, 3 :+ 4, 5 :+ 6, 7 :+ 8]
                    bb = matrix 2 2 [(-2) :+ 1, 3 :+ (-1), 1 :+ 2, 4 :+ 0]
                    c = matrix 2 2 (replicate 4 (0.5 :+ 0.5))
                expected <- B.complexGemm B.pureBackend ta tb (2 :+ 1) a bb ((-1) :+ 0.5) c
                actual <- B.complexGemm b ta tb (2 :+ 1) a bb ((-1) :+ 0.5) c
                pure
                    ( case (actual, expected) of
                        (Right x, Right y) ->
                            and
                                [ close (realPart u) (realPart v) && close (imagPart u) (imagPart v)
                                | (u, v) <- zip (M.toList x) (M.toList y)
                                ]
                        _ -> False
                    )
             )
           | ta <- [B.NoTranspose, B.Transpose, B.ConjugateTranspose]
           , tb <- [B.NoTranspose, B.Transpose, B.ConjugateTranspose]
           ]
withEnvironment :: String -> String -> IO a -> IO a
withEnvironment key value action = bracket (lookupEnv key) restore (\_ -> setEnv key value >> action)
  where
    restore = maybe (unsetEnv key) (setEnv key)
backendAPIIOTests :: [(String, IO Bool)]
backendAPIIOTests =
    kernelTests "pure" B.pureBackend
        ++ [
               ( "backend invalid environment rejected"
               , withEnvironment "HMATH_BLAS_PROVIDER" "invalid-provider" (isLeft <$> B.selectBackend B.AutoBackend)
               )
           ,
               ( "backend invalid integer width rejected"
               , withEnvironment "HMATH_BLAS_INTEGER_BITS" "16" (isLeft <$> B.selectBackend B.AutoBackend)
               )
           ,
               ( "backend explicit pure environment"
               , withEnvironment
                    "HMATH_BLAS_PROVIDER"
                    "pure"
                    ( fmap
                        (either (const False) ((== B.Pure) . B.selectedProvider . B.backendInfo))
                        (B.selectBackend B.AutoBackend)
                    )
               )
           ,
               ( "backend path NUL rejected"
               , isLeft <$> B.selectBackend (B.RequireBackend B.OpenBLAS B.LP64 (Just "libopenblas.so.0\0trailing"))
               )
           ,
               ( "API IO buffer copies and borrowed pointer"
               , do
                    value <- A.thawIOBuffer (A.strictBoxed [1, 2, 3 :: Double])
                    case value of
                        Left _ -> pure False
                        Right b -> do
                            before <- A.freezeIOBuffer b
                            _ <- A.writeIOBuffer b 1 5
                            A.withIOBuffer b (\p _ -> pokeElemOff p 2 7)
                            after <- A.freezeIOBuffer b
                            invalid <- A.readIOBuffer b 3
                            pure (A.boxedValues before == [1, 2, 3] && A.boxedValues after == [1, 5, 7] && isLeft invalid)
               )
           ,
               ( "API empty IO buffer"
               , do
                    r <- A.thawIOBuffer (A.strictBoxed ([] :: [Double]))
                    case r of { Left _ -> pure False; Right b -> null . A.boxedValues <$> A.freezeIOBuffer b }
               )
           ,
               ( "API strict boxed evaluates values"
               , do
                    r <-
                        try (evaluate (A.strictBoxed [error "forced" :: Int])) :: IO (Either SomeException (A.Boxed Int))
                    pure (isLeft r)
               )
           ,
               ( "API lazy boxed preserves laziness"
               , do
                    r <- try (evaluate (A.lazyBoxed [error "lazy" :: Int])) :: IO (Either SomeException (A.Boxed Int))
                    pure (not (isLeft r))
               )
           ,
               ( "backend missing library explicit"
               , isLeft <$> B.selectBackend (B.RequireBackend B.OpenBLAS B.LP64 (Just "/nonexistent/hmath-provider"))
               )
           ,
               ( "backend wrong integer ABI rejected"
               , do
                    r <- B.selectBackend (B.RequireBackend B.OpenBLAS B.ILP64 (Just "libopenblas.so.0"))
                    pure (isLeft r)
               )
           ]
        ++ [ ( "optional OpenBLAS " ++ show abi ++ " differential kernels"
             , do
                selected <- B.selectBackend (B.RequireBackend B.OpenBLAS abi Nothing)
                case selected of
                    Left _ -> pure True -- Availability is reported by the separate integration probe.
                    Right b -> do
                        kernels <- and <$> traverse snd (kernelTests (show abi) b)
                        available <- B.lapackAvailable
                        let solveOK =
                                not available
                                    || (ok $ do x <- B.backendSolve b (matrix 2 2 [3, 1, 1, 2]) [9, 8]; Right (closeList x [2, 3]))
                            singularOK = not available || B.backendSolve b (matrix 2 2 [1, 2, 2, 4]) [1, 2] == Left (SingularMatrix 1)
                        pure (kernels && solveOK && singularOK)
             )
           | abi <- [B.LP64, B.ILP64]
           ]
