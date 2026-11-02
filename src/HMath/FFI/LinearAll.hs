{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated; every operation calls the original Haskell public function.
module HMath.FFI.LinearAll where
import Foreign
import Foreign.C
import qualified HMath.Matrix as M
import qualified HMath.Matrix.LU as LU
import qualified HMath.Matrix.QR as QR
import Data.Complex (Complex)
import System.IO.Unsafe (unsafePerformIO)
import qualified HMath.Error as E
import HMath.FFI.Coefficient
import HMath.FFI.LinearCodec
import qualified HMath.FFI.Value as X
import qualified HMath.FFI.Boundary as Boundary
import qualified HMath.Vector as V
import qualified HMath.Matrix.Advanced as A
import qualified HMath.Matrix.Decomposition as D
import qualified HMath.Matrix.Iterative as I
import qualified HMath.Matrix.LAPACK as L
import qualified HMath.Sparse as S
import qualified HMath.Sparse.Spectral as P
import qualified HMath.Backend as B

generic :: forall a. Coefficient a => ScalarType a -> Int -> [X.Value] -> IO X.Value
generic w operation args=case(operation,args) of
    (0,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item209 -> X.asScalar item209) :: IO [(a)])
        encodeVector w ((V.vector a0Value) :: (V.Vector (a)))
    (1,[a0]) -> do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        X.List <$> mapM (\item210 -> pure (X.Scalar w item210)) ((V.vectorValues a0Value) :: [(a)])
    (2,[a0]) -> do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        pure (X.Index ((V.vectorDimension a0Value) :: (Int)))
    (5,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asList a1 >>= mapM (\item211 -> (X.asTuple 2 item211 >>= \items212 -> case items212 of { [part213,part214] -> (,) <$> (X.asIndex part213) <*> (X.asScalar part214); _ -> X.invalid "tuple arity differs" })) :: IO [((Int),(a))])
        source ((V.sparseVector a0Value a1Value) :: (Either (E.MathError) (V.SparseVector (a)))) >>= \_result215 -> encodeSparseVector w _result215
    (6,[a0]) -> do
        a0Value <- (unbox "HMath.Vector.SparseVector" a0 :: IO (V.SparseVector (a)))
        X.List <$> mapM (\item216 -> pure (X.Scalar w item216)) ((V.sparseVectorValues a0Value) :: [(a)])
    (7,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (unbox "HMath.Vector.Vector" a2 :: IO (V.Vector (a)))
        source ((V.vectorSlice a0Value a1Value a2Value) :: (Either (E.MathError) (V.Vector (a)))) >>= \_result217 -> encodeVector w _result217
    (8,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item218 -> unbox "HMath.Vector.Vector" item218) :: IO [(V.Vector (a))])
        source ((V.vectorConcat a0Value) :: (Either (E.MathError) (V.Vector (a)))) >>= \_result219 -> encodeVector w _result219
    (9,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        a1Value <- (unbox "HMath.Vector.Vector" a1 :: IO (V.Vector (a)))
        source ((V.vectorAdd a0Value a1Value) :: (Either (E.MathError) (V.Vector (a)))) >>= \_result220 -> encodeVector w _result220
    (10,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        a1Value <- (unbox "HMath.Vector.Vector" a1 :: IO (V.Vector (a)))
        source ((V.vectorSubtract a0Value a1Value) :: (Either (E.MathError) (V.Vector (a)))) >>= \_result221 -> encodeVector w _result221
    (11,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (unbox "HMath.Vector.Vector" a1 :: IO (V.Vector (a)))
        encodeVector w ((V.vectorScale a0Value a1Value) :: (V.Vector (a)))
    (12,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        a1Value <- (unbox "HMath.Vector.Vector" a1 :: IO (V.Vector (a)))
        source ((V.vectorDot a0Value a1Value) :: (Either (E.MathError) (a))) >>= \_result222 -> pure (X.Scalar w _result222)
    (13,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        a1Value <- (unbox "HMath.Vector.Vector" a1 :: IO (V.Vector (a)))
        source ((V.cross a0Value a1Value) :: (Either (E.MathError) (V.Vector (a)))) >>= \_result223 -> encodeVector w _result223
    (14,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        a1Value <- (unbox "HMath.Vector.Vector" a1 :: IO (V.Vector (a)))
        source ((V.outer a0Value a1Value) :: (Either (E.MathError) (M.Matrix (a)))) >>= \_result224 -> pure (X.Dense (X.SomeMatrix w _result224))
    (15,[a0,a1,a2]) -> do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        a1Value <- (unbox "HMath.Vector.Vector" a1 :: IO (V.Vector (a)))
        a2Value <- (unbox "HMath.Vector.Vector" a2 :: IO (V.Vector (a)))
        source ((V.triple a0Value a1Value a2Value) :: (Either (E.MathError) (a))) >>= \_result225 -> pure (X.Scalar w _result225)
    (16,[a0]) -> do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        pure (X.Index ((V.norm0 a0Value) :: (Int)))
    (17,[a0]) -> do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        pure (X.Scalar w ((V.norm1 a0Value) :: (a)))
    (18,[a0]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        pure (X.Scalar w ((V.norm2 a0Value) :: (a)))
    (19,[a0]) -> ordered w $ do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        pure (X.Scalar w ((V.normInfinity a0Value) :: (a)))
    (20,[a0,a1]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (unbox "HMath.Vector.Vector" a1 :: IO (V.Vector (a)))
        source ((V.normP a0Value a1Value) :: (Either (E.MathError) (a))) >>= \_result226 -> pure (X.Scalar w _result226)
    (21,[a0]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        source ((V.normalizeVector a0Value) :: (Either (E.MathError) (V.Vector (a)))) >>= \_result227 -> encodeVector w _result227
    (22,[a0,a1]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        a1Value <- (unbox "HMath.Vector.Vector" a1 :: IO (V.Vector (a)))
        source ((V.project a0Value a1Value) :: (Either (E.MathError) (V.Vector (a)))) >>= \_result228 -> encodeVector w _result228
    (23,[a0,a1]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        a1Value <- (unbox "HMath.Vector.Vector" a1 :: IO (V.Vector (a)))
        source ((V.reflect a0Value a1Value) :: (Either (E.MathError) (V.Vector (a)))) >>= \_result229 -> encodeVector w _result229
    (24,[a0,a1,a2]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (unbox "HMath.Vector.Vector" a1 :: IO (V.Vector (a)))
        a2Value <- (unbox "HMath.Vector.Vector" a2 :: IO (V.Vector (a)))
        source ((V.refract a0Value a1Value a2Value) :: (Either (E.MathError) (V.Vector (a)))) >>= \_result230 -> encodeVector w _result230
    (25,[a0,a1]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        a1Value <- (unbox "HMath.Vector.Vector" a1 :: IO (V.Vector (a)))
        source ((V.distance a0Value a1Value) :: (Either (E.MathError) (a))) >>= \_result231 -> pure (X.Scalar w _result231)
    (26,[a0,a1]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        a1Value <- (unbox "HMath.Vector.Vector" a1 :: IO (V.Vector (a)))
        source ((V.cosineSimilarity a0Value a1Value) :: (Either (E.MathError) (a))) >>= \_result232 -> pure (X.Scalar w _result232)
    (27,[a0,a1]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Vector.Vector" a0 :: IO (V.Vector (a)))
        a1Value <- (unbox "HMath.Vector.Vector" a1 :: IO (V.Vector (a)))
        source ((V.angle a0Value a1Value) :: (Either (E.MathError) (a))) >>= \_result233 -> pure (X.Scalar w _result233)
    (28,[a0,a1]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (X.asList a1 >>= mapM (\item234 -> unbox "HMath.Vector.Vector" item234) :: IO [(V.Vector (a))])
        source ((V.gramSchmidt a0Value a1Value) :: (Either (E.MathError) [(V.Vector (a))])) >>= \_result235 -> X.List <$> mapM (\item236 -> encodeVector w item236) _result235
    (30,[a0,a1]) -> do
        a0Value <- (X.asBoolean a0 :: IO (Bool))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        source ((A.triangularMatrix a0Value a1Value) :: (Either (E.MathError) (M.Matrix (a)))) >>= \_result237 -> pure (X.Dense (X.SomeMatrix w _result237))
    (31,[a0]) -> fractional w $ do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        source ((A.symmetricMatrix a0Value) :: (Either (E.MathError) (M.Matrix (a)))) >>= \_result238 -> pure (X.Dense (X.SomeMatrix w _result238))
    (32,[a0]) -> realFloat w $ withComplex w $ \cw -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Complex (a))))
        source ((A.hermitianMatrix a0Value) :: (Either (E.MathError) (M.Matrix (Complex (a))))) >>= \_result239 -> pure (X.Dense (X.SomeMatrix cw _result239))
    (33,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item240 -> X.asIndex item240) :: IO [(Int)])
        source ((A.permutationMatrix a0Value) :: (Either (E.MathError) (M.Matrix (a)))) >>= \_result241 -> pure (X.Dense (X.SomeMatrix w _result241))
    (34,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item242 -> X.asList item242 >>= mapM (\item243 -> asMatrix item243)) :: IO [[(M.Matrix (a))]])
        source ((A.blockMatrix a0Value) :: (Either (E.MathError) (M.Matrix (a)))) >>= \_result244 -> pure (X.Dense (X.SomeMatrix w _result244))
    (35,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asList a2 >>= mapM (\item245 -> (X.asTuple 2 item245 >>= \items246 -> case items246 of { [part247,part248] -> (,) <$> (X.asIndex part247) <*> (X.asList part248 >>= mapM (\item249 -> X.asScalar item249)); _ -> X.invalid "tuple arity differs" })) :: IO [((Int),[(a)])])
        source ((A.bandedMatrix a0Value a1Value a2Value) :: (Either (E.MathError) (M.Matrix (a)))) >>= \_result250 -> pure (X.Dense (X.SomeMatrix w _result250))
    (36,[a0]) -> realFloat w $ withComplex w $ \cw -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Complex (a))))
        pure (X.Dense (X.SomeMatrix cw ((A.conjugateTranspose a0Value) :: (M.Matrix (Complex (a))))))
    (38,[a0,a1]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item251 -> asMatrix item251) :: IO [(M.Matrix (a))])
        a1Value <- (X.asList a1 >>= mapM (\item252 -> asMatrix item252) :: IO [(M.Matrix (a))])
        source ((A.batchedMultiply a0Value a1Value) :: (Either (E.MathError) [(M.Matrix (a))])) >>= \_result253 -> X.List <$> mapM (\item254 -> pure (X.Dense (X.SomeMatrix w item254))) _result253
    (39,[a0,a1]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        source ((A.kronecker a0Value a1Value) :: (Either (E.MathError) (M.Matrix (a)))) >>= \_result255 -> pure (X.Dense (X.SomeMatrix w _result255))
    (40,[a0,a1]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        source ((A.khatriRao a0Value a1Value) :: (Either (E.MathError) (M.Matrix (a)))) >>= \_result256 -> pure (X.Dense (X.SomeMatrix w _result256))
    (41,[a0,a1]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (Integer))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        source ((A.matrixPower a0Value a1Value) :: (Either (E.MathError) (M.Matrix (a)))) >>= \_result257 -> pure (X.Dense (X.SomeMatrix w _result257))
    (42,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        source ((A.trace a0Value) :: (Either (E.MathError) (a))) >>= \_result258 -> pure (X.Scalar w _result258)
    (43,[a0]) -> ordered w $ do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        pure (X.Scalar w ((A.matrixNorm1 a0Value) :: (a)))
    (44,[a0]) -> ordered w $ do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        pure (X.Scalar w ((A.matrixNormInfinity a0Value) :: (a)))
    (45,[a0]) -> realFloat w $ do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        pure (X.Scalar w ((A.frobeniusNorm a0Value) :: (a)))
    (53,[a0,a1,a2]) -> realFloat w $ do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        a2Value <- (X.asList a2 >>= mapM (\item259 -> X.asScalar item259) :: IO [(a)])
        source ((A.changeCoordinates a0Value a1Value a2Value) :: (Either (E.MathError) [(a)])) >>= \_result260 -> X.List <$> mapM (\item261 -> pure (X.Scalar w item261)) _result260
    (54,[a0,a1,a2]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (asMatrix a2 :: IO (M.Matrix (a)))
        source ((A.matrixExp a0Value a1Value a2Value) :: (Either (E.MathError) (M.Matrix (a)))) >>= \_result262 -> pure (X.Dense (X.SomeMatrix w _result262))
    (61,[a0,a1]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        source ((D.gaussianElimination a0Value a1Value) :: (Either (E.MathError) ((M.Matrix (a)),[(Int)]))) >>= \_result263 -> (\(part264,part265) -> X.Tuple <$> sequence [pure (X.Dense (X.SomeMatrix w part264)),X.List <$> mapM (\item266 -> pure (X.Index item266)) part265]) _result263
    (62,[a0,a1]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        source ((D.gaussJordan a0Value a1Value) :: (Either (E.MathError) ((M.Matrix (a)),[(Int)]))) >>= \_result267 -> (\(part268,part269) -> X.Tuple <$> sequence [pure (X.Dense (X.SomeMatrix w part268)),X.List <$> mapM (\item270 -> pure (X.Index item270)) part269]) _result267
    (63,[a0]) -> realFloat w $ do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        source ((D.cholesky a0Value) :: (Either (E.MathError) (M.Matrix (a)))) >>= \_result271 -> pure (X.Dense (X.SomeMatrix w _result271))
    (64,[a0]) -> realFloat w $ do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        source ((D.ldlt a0Value) :: (Either (E.MathError) ((M.Matrix (a)),[(a)]))) >>= \_result272 -> (\(part273,part274) -> X.Tuple <$> sequence [pure (X.Dense (X.SomeMatrix w part273)),X.List <$> mapM (\item275 -> pure (X.Scalar w item275)) part274]) _result272
    (65,[a0]) -> realFloat w $ do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        source ((D.givensQR a0Value) :: (Either (E.MathError) ((M.Matrix (a)),(M.Matrix (a))))) >>= \_result276 -> (\(part277,part278) -> X.Tuple <$> sequence [pure (X.Dense (X.SomeMatrix w part277)),pure (X.Dense (X.SomeMatrix w part278))]) _result276
    (66,[a0]) -> realFloat w $ do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        source ((D.bidiagonalize a0Value) :: (Either (E.MathError) (D.Bidiagonal (a)))) >>= \_result279 -> encodeBidiagonal w _result279
    (68,[a0,a1,a2,a3]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (asMatrix a2 :: IO (M.Matrix (a)))
        a3Value <- (X.asList a3 >>= mapM (\item280 -> X.asScalar item280) :: IO [(a)])
        source ((D.powerIteration a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (D.Iteration (a)))) >>= \_result281 -> encodeIteration w _result281
    (69,[a0,a1,a2,a3,a4]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asScalar a2 :: IO (a))
        a3Value <- (asMatrix a3 :: IO (M.Matrix (a)))
        a4Value <- (X.asList a4 >>= mapM (\item282 -> X.asScalar item282) :: IO [(a)])
        source ((D.inverseIteration a0Value a1Value a2Value a3Value a4Value) :: (Either (E.MathError) (D.Iteration (a)))) >>= \_result283 -> encodeIteration w _result283
    (70,[a0,a1,a2,a3]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (asMatrix a2 :: IO (M.Matrix (a)))
        a3Value <- (X.asList a3 >>= mapM (\item284 -> X.asScalar item284) :: IO [(a)])
        source ((D.rayleighIteration a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (D.Iteration (a)))) >>= \_result285 -> encodeIteration w _result285
    (71,[a0,a1,a2,a3]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (asMatrix a2 :: IO (M.Matrix (a)))
        a3Value <- (X.asList a3 >>= mapM (\item286 -> X.asScalar item286) :: IO [(a)])
        source ((D.arnoldi a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (D.Arnoldi (a)))) >>= \_result287 -> encodeArnoldi w _result287
    (72,[a0,a1,a2,a3]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (asMatrix a2 :: IO (M.Matrix (a)))
        a3Value <- (X.asList a3 >>= mapM (\item288 -> X.asScalar item288) :: IO [(a)])
        source ((D.lanczos a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (D.Arnoldi (a)))) >>= \_result289 -> encodeArnoldi w _result289
    (73,[a0,a1,a2]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (asMatrix a2 :: IO (M.Matrix (a)))
        source ((D.qrIteration a0Value a1Value a2Value) :: (Either (E.MathError) ((M.Matrix (a)),(M.Matrix (a))))) >>= \_result290 -> (\(part291,part292) -> X.Tuple <$> sequence [pure (X.Dense (X.SomeMatrix w part291)),pure (X.Dense (X.SomeMatrix w part292))]) _result290
    (74,[a0,a1,a2]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        a2Value <- (X.asList a2 >>= mapM (\item293 -> (X.asTuple 2 item293 >>= \items294 -> case items294 of { [part295,part296] -> (,) <$> (X.asScalar part295) <*> (X.asList part296 >>= mapM (\item297 -> X.asList item297 >>= mapM (\item298 -> X.asScalar item298))); _ -> X.invalid "tuple arity differs" })) :: IO [((a),[[(a)]])])
        source ((D.jordanChains a0Value a1Value a2Value) :: (Either (E.MathError) ((M.Matrix (a)),(M.Matrix (a))))) >>= \_result299 -> (\(part300,part301) -> X.Tuple <$> sequence [pure (X.Dense (X.SomeMatrix w part300)),pure (X.Dense (X.SomeMatrix w part301))]) _result299
    (76,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Decomposition.Bidiagonal" a0 :: IO (D.Bidiagonal (a)))
        pure (X.Dense (X.SomeMatrix w ((D.bidiagonalU a0Value) :: (M.Matrix (a)))))
    (77,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Decomposition.Bidiagonal" a0 :: IO (D.Bidiagonal (a)))
        pure (X.Dense (X.SomeMatrix w ((D.bidiagonalB a0Value) :: (M.Matrix (a)))))
    (78,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Decomposition.Bidiagonal" a0 :: IO (D.Bidiagonal (a)))
        pure (X.Dense (X.SomeMatrix w ((D.bidiagonalV a0Value) :: (M.Matrix (a)))))
    (79,[a0,a1,a2]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        a2Value <- (asMatrix a2 :: IO (M.Matrix (a)))
        encodeBidiagonal w ((D.Bidiagonal a0Value a1Value a2Value) :: (D.Bidiagonal (a)))
    (80,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Decomposition.Iteration" a0 :: IO (D.Iteration (a)))
        pure (X.Scalar w ((D.iterationValue a0Value) :: (a)))
    (81,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Decomposition.Iteration" a0 :: IO (D.Iteration (a)))
        X.List <$> mapM (\item302 -> pure (X.Scalar w item302)) ((D.iterationVector a0Value) :: [(a)])
    (82,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Decomposition.Iteration" a0 :: IO (D.Iteration (a)))
        pure (X.Scalar w ((D.iterationResidual a0Value) :: (a)))
    (83,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Decomposition.Iteration" a0 :: IO (D.Iteration (a)))
        pure (X.Index ((D.iterationCount a0Value) :: (Int)))
    (84,[a0,a1,a2,a3]) -> do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (X.asList a1 >>= mapM (\item303 -> X.asScalar item303) :: IO [(a)])
        a2Value <- (X.asScalar a2 :: IO (a))
        a3Value <- (X.asIndex a3 :: IO (Int))
        encodeIteration w ((D.Iteration a0Value a1Value a2Value a3Value) :: (D.Iteration (a)))
    (85,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Decomposition.Arnoldi" a0 :: IO (D.Arnoldi (a)))
        pure (X.Dense (X.SomeMatrix w ((D.arnoldiBasis a0Value) :: (M.Matrix (a)))))
    (86,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Decomposition.Arnoldi" a0 :: IO (D.Arnoldi (a)))
        pure (X.Dense (X.SomeMatrix w ((D.arnoldiHessenberg a0Value) :: (M.Matrix (a)))))
    (87,[a0,a1]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        encodeArnoldi w ((D.Arnoldi a0Value a1Value) :: (D.Arnoldi (a)))
    (88,[]) -> fractional w $ do
        encodeIterativeOptions w ((I.defaultIterativeOptions ) :: (I.IterativeOptions (a)))
    (89,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Matrix.Iterative.Preconditioner" a0 :: IO (I.Preconditioner (a)))
        a1Value <- (X.asList a1 >>= mapM (\item304 -> X.asScalar item304) :: IO [(a)])
        source ((I.applyPreconditioner a0Value a1Value) :: (Either (E.MathError) [(a)])) >>= \_result305 -> X.List <$> mapM (\item306 -> pure (X.Scalar w item306)) _result305
    (90,[a0]) -> realFloat w $ do
        a0Value <- (X.asIndex a0 :: IO (Int))
        source ((I.identityPreconditioner a0Value) :: (Either (E.MathError) (I.Preconditioner (a)))) >>= \_result307 -> encodePreconditioner w _result307
    (91,[a0]) -> realFloat w $ do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        source ((I.jacobiPreconditioner a0Value) :: (Either (E.MathError) (I.Preconditioner (a)))) >>= \_result308 -> encodePreconditioner w _result308
    (92,[a0,a1]) -> realFloat w $ do
        a0Value <- (X.asList a0 >>= mapM (\item309 -> X.asIndex item309) :: IO [(Int)])
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        source ((I.blockJacobiPreconditioner a0Value a1Value) :: (Either (E.MathError) (I.Preconditioner (a)))) >>= \_result310 -> encodePreconditioner w _result310
    (93,[a0]) -> realFloat w $ do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        source ((I.ilu0Preconditioner a0Value) :: (Either (E.MathError) (I.Preconditioner (a)))) >>= \_result311 -> encodePreconditioner w _result311
    (94,[a0]) -> realFloat w $ do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        source ((I.ic0Preconditioner a0Value) :: (Either (E.MathError) (I.Preconditioner (a)))) >>= \_result312 -> encodePreconditioner w _result312
    (95,[a0,a1,a2,a3]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        a2Value <- (X.asList a2 >>= mapM (\item313 -> X.asScalar item313) :: IO [(a)])
        a3Value <- (X.asList a3 >>= mapM (\item314 -> X.asScalar item314) :: IO [(a)])
        source ((I.conjugateGradient a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (I.IterativeResult (a)))) >>= \_result315 -> encodeIterativeResult w _result315
    (96,[a0,a1,a2,a3,a4]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        a1Value <- (unbox "HMath.Matrix.Iterative.Preconditioner" a1 :: IO (I.Preconditioner (a)))
        a2Value <- (asMatrix a2 :: IO (M.Matrix (a)))
        a3Value <- (X.asList a3 >>= mapM (\item316 -> X.asScalar item316) :: IO [(a)])
        a4Value <- (X.asList a4 >>= mapM (\item317 -> X.asScalar item317) :: IO [(a)])
        source ((I.preconditionedCG a0Value a1Value a2Value a3Value a4Value) :: (Either (E.MathError) (I.IterativeResult (a)))) >>= \_result318 -> encodeIterativeResult w _result318
    (97,[a0,a1,a2,a3,a4]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (asMatrix a2 :: IO (M.Matrix (a)))
        a3Value <- (X.asList a3 >>= mapM (\item319 -> X.asScalar item319) :: IO [(a)])
        a4Value <- (X.asList a4 >>= mapM (\item320 -> X.asScalar item320) :: IO [(a)])
        source ((I.gmres a0Value a1Value a2Value a3Value a4Value) :: (Either (E.MathError) (I.IterativeResult (a)))) >>= \_result321 -> encodeIterativeResult w _result321
    (98,[a0,a1,a2,a3]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        a2Value <- (X.asList a2 >>= mapM (\item322 -> X.asScalar item322) :: IO [(a)])
        a3Value <- (X.asList a3 >>= mapM (\item323 -> X.asScalar item323) :: IO [(a)])
        source ((I.minres a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (I.IterativeResult (a)))) >>= \_result324 -> encodeIterativeResult w _result324
    (99,[a0,a1,a2,a3]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        a2Value <- (X.asList a2 >>= mapM (\item325 -> X.asScalar item325) :: IO [(a)])
        a3Value <- (X.asList a3 >>= mapM (\item326 -> X.asScalar item326) :: IO [(a)])
        source ((I.bicg a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (I.IterativeResult (a)))) >>= \_result327 -> encodeIterativeResult w _result327
    (100,[a0,a1,a2,a3]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        a2Value <- (X.asList a2 >>= mapM (\item328 -> X.asScalar item328) :: IO [(a)])
        a3Value <- (X.asList a3 >>= mapM (\item329 -> X.asScalar item329) :: IO [(a)])
        source ((I.bicgstab a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (I.IterativeResult (a)))) >>= \_result330 -> encodeIterativeResult w _result330
    (101,[a0,a1,a2,a3]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        a2Value <- (X.asList a2 >>= mapM (\item331 -> X.asScalar item331) :: IO [(a)])
        a3Value <- (X.asList a3 >>= mapM (\item332 -> X.asScalar item332) :: IO [(a)])
        source ((I.lsqr a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (I.IterativeResult (a)))) >>= \_result333 -> encodeIterativeResult w _result333
    (102,[a0,a1,a2,a3]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        a2Value <- (X.asList a2 >>= mapM (\item334 -> X.asScalar item334) :: IO [(a)])
        a3Value <- (X.asList a3 >>= mapM (\item335 -> X.asScalar item335) :: IO [(a)])
        source ((I.lsmr a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (I.IterativeResult (a)))) >>= \_result336 -> encodeIterativeResult w _result336
    (103,[a0,a1,a2,a3]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        a2Value <- (X.asList a2 >>= mapM (\item337 -> X.asScalar item337) :: IO [(a)])
        a3Value <- (X.asList a3 >>= mapM (\item338 -> X.asScalar item338) :: IO [(a)])
        source ((I.jacobiSolve a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (I.IterativeResult (a)))) >>= \_result339 -> encodeIterativeResult w _result339
    (104,[a0,a1,a2,a3]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        a2Value <- (X.asList a2 >>= mapM (\item340 -> X.asScalar item340) :: IO [(a)])
        a3Value <- (X.asList a3 >>= mapM (\item341 -> X.asScalar item341) :: IO [(a)])
        source ((I.gaussSeidelSolve a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (I.IterativeResult (a)))) >>= \_result342 -> encodeIterativeResult w _result342
    (105,[a0,a1,a2,a3,a4]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        a1Value <- (X.asScalar a1 :: IO (a))
        a2Value <- (asMatrix a2 :: IO (M.Matrix (a)))
        a3Value <- (X.asList a3 >>= mapM (\item343 -> X.asScalar item343) :: IO [(a)])
        a4Value <- (X.asList a4 >>= mapM (\item344 -> X.asScalar item344) :: IO [(a)])
        source ((I.sorSolve a0Value a1Value a2Value a3Value a4Value) :: (Either (E.MathError) (I.IterativeResult (a)))) >>= \_result345 -> encodeIterativeResult w _result345
    (106,[a0,a1,a2,a3]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        a2Value <- (X.asList a2 >>= mapM (\item346 -> X.asScalar item346) :: IO [(a)])
        a3Value <- (X.asList a3 >>= mapM (\item347 -> X.asScalar item347) :: IO [(a)])
        source ((I.iterativeRefinement a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (I.IterativeResult (a)))) >>= \_result348 -> encodeIterativeResult w _result348
    (107,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        pure (X.Scalar w ((I.absoluteTolerance a0Value) :: (a)))
    (108,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        pure (X.Scalar w ((I.relativeTolerance a0Value) :: (a)))
    (109,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeOptions" a0 :: IO (I.IterativeOptions (a)))
        pure (X.Index ((I.maximumIterations a0Value) :: (Int)))
    (110,[a0,a1,a2]) -> do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (X.asScalar a1 :: IO (a))
        a2Value <- (X.asIndex a2 :: IO (Int))
        encodeIterativeOptions w ((I.IterativeOptions a0Value a1Value a2Value) :: (I.IterativeOptions (a)))
    (111,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeResult" a0 :: IO (I.IterativeResult (a)))
        X.List <$> mapM (\item349 -> pure (X.Scalar w item349)) ((I.iterativeSolution a0Value) :: [(a)])
    (112,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeResult" a0 :: IO (I.IterativeResult (a)))
        pure (X.Index ((I.iterativeIterations a0Value) :: (Int)))
    (113,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeResult" a0 :: IO (I.IterativeResult (a)))
        pure (X.Scalar w ((I.iterativeResidualNorm a0Value) :: (a)))
    (114,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.Iterative.IterativeResult" a0 :: IO (I.IterativeResult (a)))
        pure (X.Scalar w ((I.iterativeNormalResidualNorm a0Value) :: (a)))
    (115,[a0,a1,a2,a3]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item350 -> X.asScalar item350) :: IO [(a)])
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asScalar a2 :: IO (a))
        a3Value <- (X.asScalar a3 :: IO (a))
        encodeIterativeResult w ((I.IterativeResult a0Value a1Value a2Value a3Value) :: (I.IterativeResult (a)))
    (161,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asList a2 >>= mapM (\item351 -> (X.asTuple 3 item351 >>= \items352 -> case items352 of { [part353,part354,part355] -> (,,) <$> (X.asIndex part353) <*> (X.asIndex part354) <*> (X.asScalar part355); _ -> X.invalid "tuple arity differs" })) :: IO [((Int),(Int),(a))])
        source ((S.sparse a0Value a1Value a2Value) :: (Either (E.MathError) (S.Sparse (a)))) >>= \_result356 -> encodeSparse w _result356
    (162,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        (\(part357,part358) -> X.Tuple <$> sequence [pure (X.Index part357),pure (X.Index part358)]) ((S.sparseShape a0Value) :: ((Int),(Int)))
    (163,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        X.List <$> mapM (\item359 -> (\(part360,part361,part362) -> X.Tuple <$> sequence [pure (X.Index part360),pure (X.Index part361),pure (X.Scalar w part362)]) item359) ((S.sparseEntries a0Value) :: [((Int),(Int),(a))])
    (164,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        pure (X.Index ((S.nonzeros a0Value) :: (Int)))
    (165,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.SparseFormat" a0 :: IO (S.SparseFormat (a)))
        source ((S.fromFormat a0Value) :: (Either (E.MathError) (S.Sparse (a)))) >>= \_result363 -> encodeSparse w _result363
    (166,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        encodeSparseFormat w ((S.toCOO a0Value) :: (S.SparseFormat (a)))
    (167,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        encodeSparseFormat w ((S.toCSR a0Value) :: (S.SparseFormat (a)))
    (168,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        encodeSparseFormat w ((S.toCSC a0Value) :: (S.SparseFormat (a)))
    (169,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        encodeSparseFormat w ((S.toDIA a0Value) :: (S.SparseFormat (a)))
    (170,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (unbox "HMath.Sparse.Sparse" a2 :: IO (S.Sparse (a)))
        source ((S.toBSR a0Value a1Value a2Value) :: (Either (E.MathError) (S.SparseFormat (a)))) >>= \_result364 -> encodeSparseFormat w _result364
    (171,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        source ((S.toELLPACK a0Value) :: (Either (E.MathError) (S.SparseFormat (a)))) >>= \_result365 -> encodeSparseFormat w _result365
    (172,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        source ((S.sparseToDense a0Value) :: (Either (E.MathError) (M.Matrix (a)))) >>= \_result366 -> pure (X.Dense (X.SomeMatrix w _result366))
    (173,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (a)))
        encodeSparse w ((S.denseToSparse a0Value) :: (S.Sparse (a)))
    (174,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        encodeSparse w ((S.sparseTranspose a0Value) :: (S.Sparse (a)))
    (175,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        a1Value <- (unbox "HMath.Sparse.Sparse" a1 :: IO (S.Sparse (a)))
        source ((S.sparseAdd a0Value a1Value) :: (Either (E.MathError) (S.Sparse (a)))) >>= \_result367 -> encodeSparse w _result367
    (176,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        a1Value <- (unbox "HMath.Sparse.Sparse" a1 :: IO (S.Sparse (a)))
        source ((S.sparseSubtract a0Value a1Value) :: (Either (E.MathError) (S.Sparse (a)))) >>= \_result368 -> encodeSparse w _result368
    (177,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        a1Value <- (X.asList a1 >>= mapM (\item369 -> X.asScalar item369) :: IO [(a)])
        source ((S.spmv a0Value a1Value) :: (Either (E.MathError) [(a)])) >>= \_result370 -> X.List <$> mapM (\item371 -> pure (X.Scalar w item371)) _result370
    (178,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        a1Value <- (unbox "HMath.Sparse.Sparse" a1 :: IO (S.Sparse (a)))
        source ((S.spmm a0Value a1Value) :: (Either (E.MathError) (S.Sparse (a)))) >>= \_result372 -> encodeSparse w _result372
    (179,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        a1Value <- (unbox "HMath.Sparse.Sparse" a1 :: IO (S.Sparse (a)))
        source ((S.sparseKronecker a0Value a1Value) :: (Either (E.MathError) (S.Sparse (a)))) >>= \_result373 -> encodeSparse w _result373
    (180,[a0,a1,a2]) -> realFloat w $ do
        a0Value <- (X.asBoolean a0 :: IO (Bool))
        a1Value <- (unbox "HMath.Sparse.Sparse" a1 :: IO (S.Sparse (a)))
        a2Value <- (X.asList a2 >>= mapM (\item374 -> X.asScalar item374) :: IO [(a)])
        source ((S.sparseTriangularSolve a0Value a1Value a2Value) :: (Either (E.MathError) [(a)])) >>= \_result375 -> X.List <$> mapM (\item376 -> pure (X.Scalar w item376)) _result375
    (181,[a0,a1]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        a1Value <- (X.asList a1 >>= mapM (\item377 -> X.asScalar item377) :: IO [(a)])
        source ((S.sparseDiagonalSolve a0Value a1Value) :: (Either (E.MathError) [(a)])) >>= \_result378 -> X.List <$> mapM (\item379 -> pure (X.Scalar w item379)) _result378
    (182,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.SparseLU" a0 :: IO (S.SparseLU (a)))
        encodeSparse w ((S.sparseLULower a0Value) :: (S.Sparse (a)))
    (183,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.SparseLU" a0 :: IO (S.SparseLU (a)))
        encodeSparse w ((S.sparseLUUpper a0Value) :: (S.Sparse (a)))
    (184,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.SparseLU" a0 :: IO (S.SparseLU (a)))
        X.List <$> mapM (\item380 -> pure (X.Index item380)) ((S.sparseLUPermutation a0Value) :: [(Int)])
    (185,[a0,a1]) -> realFloat w $ do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (unbox "HMath.Sparse.Sparse" a1 :: IO (S.Sparse (a)))
        source ((S.sparseLU a0Value a1Value) :: (Either (E.MathError) (S.SparseLU (a)))) >>= \_result381 -> encodeSparseLU w _result381
    (186,[a0,a1]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Sparse.SparseLU" a0 :: IO (S.SparseLU (a)))
        a1Value <- (X.asList a1 >>= mapM (\item382 -> X.asScalar item382) :: IO [(a)])
        source ((S.sparseSolveLU a0Value a1Value) :: (Either (E.MathError) [(a)])) >>= \_result383 -> X.List <$> mapM (\item384 -> pure (X.Scalar w item384)) _result383
    (187,[a0]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        source ((S.sparseCholesky a0Value) :: (Either (E.MathError) (S.Sparse (a)))) >>= \_result385 -> encodeSparse w _result385
    (188,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.SparseQR" a0 :: IO (S.SparseQR (a)))
        encodeSparse w ((S.sparseQRUpper a0Value) :: (S.Sparse (a)))
    (189,[a0]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        source ((S.sparseQR a0Value) :: (Either (E.MathError) (S.SparseQR (a)))) >>= \_result386 -> encodeSparseQR w _result386
    (190,[a0,a1]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Sparse.SparseQR" a0 :: IO (S.SparseQR (a)))
        a1Value <- (X.asList a1 >>= mapM (\item387 -> X.asScalar item387) :: IO [(a)])
        source ((S.sparseQRApplyQT a0Value a1Value) :: (Either (E.MathError) [(a)])) >>= \_result388 -> X.List <$> mapM (\item389 -> pure (X.Scalar w item389)) _result388
    (191,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Sparse" a0 :: IO (S.Sparse (a)))
        source ((S.sparseGraph a0Value) :: (Either (E.MathError) [((Int),[((Int),(a))])])) >>= \_result390 -> X.List <$> mapM (\item391 -> (\(part392,part393) -> X.Tuple <$> sequence [pure (X.Index part392),X.List <$> mapM (\item394 -> (\(part395,part396) -> X.Tuple <$> sequence [pure (X.Index part395),pure (X.Scalar w part396)]) item394) part393]) item391) _result390
    (192,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (unbox "HMath.Sparse.Sparse" a1 :: IO (S.Sparse (a)))
        source ((S.sparseStorageBytes a0Value a1Value) :: (Either (E.MathError) (Integer))) >>= \_result397 -> pure (X.Scalar SInteger _result397)
    (193,[a0,a1]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item398 -> X.asIndex item398) :: IO [(Int)])
        a1Value <- (X.asList a1 >>= mapM (\item399 -> (X.asTuple 2 item399 >>= \items400 -> case items400 of { [part401,part402] -> (,) <$> (X.asList part401 >>= mapM (\item403 -> X.asIndex item403)) <*> (X.asScalar part402); _ -> X.invalid "tuple arity differs" })) :: IO [([(Int)],(a))])
        source ((S.sparseTensor a0Value a1Value) :: (Either (E.MathError) (S.SparseTensor (a)))) >>= \_result404 -> encodeSparseTensor w _result404
    (194,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.SparseTensor" a0 :: IO (S.SparseTensor (a)))
        X.List <$> mapM (\item405 -> pure (X.Index item405)) ((S.sparseTensorShape a0Value) :: [(Int)])
    (195,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.SparseTensor" a0 :: IO (S.SparseTensor (a)))
        X.List <$> mapM (\item406 -> (\(part407,part408) -> X.Tuple <$> sequence [X.List <$> mapM (\item409 -> pure (X.Index item409)) part407,pure (X.Scalar w part408)]) item406) ((S.sparseTensorEntries a0Value) :: [([(Int)],(a))])
    (196,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Sparse.SparseTensor" a0 :: IO (S.SparseTensor (a)))
        a1Value <- (X.asList a1 >>= mapM (\item410 -> X.asIndex item410) :: IO [(Int)])
        source ((S.sparseTensorLookup a0Value a1Value) :: (Either (E.MathError) (a))) >>= \_result411 -> pure (X.Scalar w _result411)
    (199,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asList a2 >>= mapM (\item412 -> (X.asTuple 3 item412 >>= \items413 -> case items413 of { [part414,part415,part416] -> (,,) <$> (X.asIndex part414) <*> (X.asIndex part415) <*> (X.asScalar part416); _ -> X.invalid "tuple arity differs" })) :: IO [((Int),(Int),(a))])
        encodeSparseFormat w ((S.COO a0Value a1Value a2Value) :: (S.SparseFormat (a)))
    (200,[a0,a1,a2,a3,a4]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asList a2 >>= mapM (\item417 -> X.asIndex item417) :: IO [(Int)])
        a3Value <- (X.asList a3 >>= mapM (\item418 -> X.asIndex item418) :: IO [(Int)])
        a4Value <- (X.asList a4 >>= mapM (\item419 -> X.asScalar item419) :: IO [(a)])
        encodeSparseFormat w ((S.CSR a0Value a1Value a2Value a3Value a4Value) :: (S.SparseFormat (a)))
    (201,[a0,a1,a2,a3,a4]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asList a2 >>= mapM (\item420 -> X.asIndex item420) :: IO [(Int)])
        a3Value <- (X.asList a3 >>= mapM (\item421 -> X.asIndex item421) :: IO [(Int)])
        a4Value <- (X.asList a4 >>= mapM (\item422 -> X.asScalar item422) :: IO [(a)])
        encodeSparseFormat w ((S.CSC a0Value a1Value a2Value a3Value a4Value) :: (S.SparseFormat (a)))
    (202,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asList a2 >>= mapM (\item423 -> (X.asTuple 2 item423 >>= \items424 -> case items424 of { [part425,part426] -> (,) <$> (X.asIndex part425) <*> (X.asList part426 >>= mapM (\item427 -> X.asScalar item427)); _ -> X.invalid "tuple arity differs" })) :: IO [((Int),[(a)])])
        encodeSparseFormat w ((S.DIA a0Value a1Value a2Value) :: (S.SparseFormat (a)))
    (203,[a0,a1,a2,a3,a4,a5,a6]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asIndex a2 :: IO (Int))
        a3Value <- (X.asIndex a3 :: IO (Int))
        a4Value <- (X.asList a4 >>= mapM (\item428 -> X.asIndex item428) :: IO [(Int)])
        a5Value <- (X.asList a5 >>= mapM (\item429 -> X.asIndex item429) :: IO [(Int)])
        a6Value <- (X.asList a6 >>= mapM (\item430 -> X.asList item430 >>= mapM (\item431 -> X.asScalar item431)) :: IO [[(a)]])
        encodeSparseFormat w ((S.BSR a0Value a1Value a2Value a3Value a4Value a5Value a6Value) :: (S.SparseFormat (a)))
    (204,[a0,a1,a2,a3,a4]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asIndex a2 :: IO (Int))
        a3Value <- (X.asList a3 >>= mapM (\item432 -> X.asIndex item432) :: IO [(Int)])
        a4Value <- (X.asList a4 >>= mapM (\item433 -> X.asScalar item433) :: IO [(a)])
        encodeSparseFormat w ((S.ELLPACK a0Value a1Value a2Value a3Value a4Value) :: (S.SparseFormat (a)))
    (205,[]) -> fractional w $ do
        encodeSparseSpectralOptions w ((P.defaultSparseSpectralOptions ) :: (P.SparseSpectralOptions (a)))
    (206,[a0,a1,a2]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseSpectralOptions" a0 :: IO (P.SparseSpectralOptions (a)))
        a1Value <- (unbox "HMath.Sparse.Sparse" a1 :: IO (S.Sparse (a)))
        a2Value <- (X.asList a2 >>= mapM (\item434 -> X.asScalar item434) :: IO [(a)])
        source ((P.sparseDominantEigen a0Value a1Value a2Value) :: (Either (E.MathError) (P.SparseEigenResult (a)))) >>= \_result435 -> encodeSparseEigenResult w _result435
    (207,[a0,a1,a2,a3]) -> realFloat w $ do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseSpectralOptions" a0 :: IO (P.SparseSpectralOptions (a)))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asScalar a2 :: IO (Integer))
        a3Value <- (unbox "HMath.Sparse.Sparse" a3 :: IO (S.Sparse (a)))
        source ((P.sparseTruncatedSVD a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (P.SparseSVD (a)))) >>= \_result436 -> encodeSparseSVD w _result436
    (208,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseSpectralOptions" a0 :: IO (P.SparseSpectralOptions (a)))
        pure (X.Scalar w ((P.sparseAbsoluteTolerance a0Value) :: (a)))
    (209,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseSpectralOptions" a0 :: IO (P.SparseSpectralOptions (a)))
        pure (X.Scalar w ((P.sparseRelativeTolerance a0Value) :: (a)))
    (210,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseSpectralOptions" a0 :: IO (P.SparseSpectralOptions (a)))
        pure (X.Index ((P.sparseIterationLimit a0Value) :: (Int)))
    (211,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseSpectralOptions" a0 :: IO (P.SparseSpectralOptions (a)))
        pure (X.Scalar SInteger ((P.sparseWorkspaceLimit a0Value) :: (Integer)))
    (212,[a0,a1,a2,a3]) -> do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (X.asScalar a1 :: IO (a))
        a2Value <- (X.asIndex a2 :: IO (Int))
        a3Value <- (X.asScalar a3 :: IO (Integer))
        encodeSparseSpectralOptions w ((P.SparseSpectralOptions a0Value a1Value a2Value a3Value) :: (P.SparseSpectralOptions (a)))
    (213,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseEigenResult" a0 :: IO (P.SparseEigenResult (a)))
        pure (X.Scalar w ((P.sparseEigenvalue a0Value) :: (a)))
    (214,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseEigenResult" a0 :: IO (P.SparseEigenResult (a)))
        X.List <$> mapM (\item437 -> pure (X.Scalar w item437)) ((P.sparseEigenvector a0Value) :: [(a)])
    (215,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseEigenResult" a0 :: IO (P.SparseEigenResult (a)))
        pure (X.Scalar w ((P.sparseEigenResidual a0Value) :: (a)))
    (216,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseEigenResult" a0 :: IO (P.SparseEigenResult (a)))
        pure (X.Index ((P.sparseEigenIterations a0Value) :: (Int)))
    (217,[a0,a1,a2,a3]) -> do
        a0Value <- (X.asScalar a0 :: IO (a))
        a1Value <- (X.asList a1 >>= mapM (\item438 -> X.asScalar item438) :: IO [(a)])
        a2Value <- (X.asScalar a2 :: IO (a))
        a3Value <- (X.asIndex a3 :: IO (Int))
        encodeSparseEigenResult w ((P.SparseEigenResult a0Value a1Value a2Value a3Value) :: (P.SparseEigenResult (a)))
    (218,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseSVD" a0 :: IO (P.SparseSVD (a)))
        X.List <$> mapM (\item439 -> pure (X.Scalar w item439)) ((P.sparseSingularValues a0Value) :: [(a)])
    (219,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseSVD" a0 :: IO (P.SparseSVD (a)))
        X.List <$> mapM (\item440 -> X.List <$> mapM (\item441 -> pure (X.Scalar w item441)) item440) ((P.sparseLeftVectors a0Value) :: [[(a)]])
    (220,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseSVD" a0 :: IO (P.SparseSVD (a)))
        X.List <$> mapM (\item442 -> X.List <$> mapM (\item443 -> pure (X.Scalar w item443)) item442) ((P.sparseRightVectors a0Value) :: [[(a)]])
    (221,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseSVD" a0 :: IO (P.SparseSVD (a)))
        X.List <$> mapM (\item444 -> (\(part445,part446) -> X.Tuple <$> sequence [pure (X.Scalar w part445),pure (X.Scalar w part446)]) item444) ((P.sparseSingularResiduals a0Value) :: [((a),(a))])
    (222,[a0]) -> do
        a0Value <- (unbox "HMath.Sparse.Spectral.SparseSVD" a0 :: IO (P.SparseSVD (a)))
        X.List <$> mapM (\item447 -> pure (X.Index item447)) ((P.sparseSingularIterations a0Value) :: [(Int)])
    (223,[a0,a1,a2,a3,a4]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item448 -> X.asScalar item448) :: IO [(a)])
        a1Value <- (X.asList a1 >>= mapM (\item449 -> X.asList item449 >>= mapM (\item450 -> X.asScalar item450)) :: IO [[(a)]])
        a2Value <- (X.asList a2 >>= mapM (\item451 -> X.asList item451 >>= mapM (\item452 -> X.asScalar item452)) :: IO [[(a)]])
        a3Value <- (X.asList a3 >>= mapM (\item453 -> (X.asTuple 2 item453 >>= \items454 -> case items454 of { [part455,part456] -> (,) <$> (X.asScalar part455) <*> (X.asScalar part456); _ -> X.invalid "tuple arity differs" })) :: IO [((a),(a))])
        a4Value <- (X.asList a4 >>= mapM (\item457 -> X.asIndex item457) :: IO [(Int)])
        encodeSparseSVD w ((P.SparseSVD a0Value a1Value a2Value a3Value a4Value) :: (P.SparseSVD (a)))
    (230,[a0,a1,a2,a3]) -> do
        a0Value <- (unbox "HMath.Backend.BackendLayout" a0 :: IO (B.BackendLayout))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asIndex a2 :: IO (Int))
        a3Value <- (X.asList a3 >>= mapM (\item458 -> X.asScalar item458) :: IO [(a)])
        source ((B.matrixFromLayout a0Value a1Value a2Value a3Value) :: (Either (E.MathError) (M.Matrix (a)))) >>= \_result459 -> pure (X.Dense (X.SomeMatrix w _result459))
    (231,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Backend.BackendLayout" a0 :: IO (B.BackendLayout))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (a)))
        X.List <$> mapM (\item460 -> pure (X.Scalar w item460)) ((B.matrixToLayout a0Value a1Value) :: [(a)])
    _ -> X.invalid "unsupported generic linear operation/arity"

concrete :: Int -> [X.Value] -> IO X.Value
concrete operation args=case(operation,args) of
    (46,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((A.spectralNorm a0Value) :: (Either (E.MathError) (Double))) >>= \_result461 -> pure (X.Scalar SDouble _result461)
    (47,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        source ((A.matrixRank a0Value a1Value) :: (Either (E.MathError) (Int))) >>= \_result462 -> pure (X.Index _result462)
    (48,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        source ((A.pseudoinverse a0Value a1Value) :: (Either (E.MathError) (M.Matrix (Double)))) >>= \_result463 -> pure (X.Dense (X.SomeMatrix SDouble _result463))
    (49,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((A.conditionNumber a0Value) :: (Either (E.MathError) (Double))) >>= \_result464 -> pure (X.Scalar SDouble _result464)
    (50,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        source ((A.columnSpace a0Value a1Value) :: (Either (E.MathError) (M.Matrix (Double)))) >>= \_result465 -> pure (X.Dense (X.SomeMatrix SDouble _result465))
    (51,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        source ((A.rowSpace a0Value a1Value) :: (Either (E.MathError) (M.Matrix (Double)))) >>= \_result466 -> pure (X.Dense (X.SomeMatrix SDouble _result466))
    (52,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        source ((A.nullSpace a0Value a1Value) :: (Either (E.MathError) (M.Matrix (Double)))) >>= \_result467 -> pure (X.Dense (X.SomeMatrix SDouble _result467))
    (55,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((A.matrixLog a0Value) :: (Either (E.MathError) (M.Matrix (Double)))) >>= \_result468 -> pure (X.Dense (X.SomeMatrix SDouble _result468))
    (56,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((A.matrixSqrt a0Value) :: (Either (E.MathError) (M.Matrix (Double)))) >>= \_result469 -> pure (X.Dense (X.SomeMatrix SDouble _result469))
    (57,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((A.polar a0Value) :: (Either (E.MathError) ((M.Matrix (Double)),(M.Matrix (Double))))) >>= \_result470 -> (\(part471,part472) -> X.Tuple <$> sequence [pure (X.Dense (X.SomeMatrix SDouble part471)),pure (X.Dense (X.SomeMatrix SDouble part472))]) _result470
    (58,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Complex (Double))))
        source ((A.complexPseudoinverse a0Value a1Value) :: (Either (E.MathError) (M.Matrix (Complex (Double))))) >>= \_result473 -> pure (X.Dense (X.SomeMatrix SComplexDouble _result473))
    (59,[a0,a1,a2]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (asMatrix a2 :: IO (M.Matrix (Double)))
        source ((A.matrixSqrtGeneral a0Value a1Value a2Value) :: (Either (E.MathError) (M.Matrix (Double)))) >>= \_result474 -> pure (X.Dense (X.SomeMatrix SDouble _result474))
    (60,[a0,a1,a2]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (asMatrix a2 :: IO (M.Matrix (Double)))
        source ((A.matrixLogGeneral a0Value a1Value a2Value) :: (Either (E.MathError) (M.Matrix (Double)))) >>= \_result475 -> pure (X.Dense (X.SomeMatrix SDouble _result475))
    (67,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((D.tridiagonalize a0Value) :: (Either (E.MathError) ((M.Matrix (Double)),(M.Matrix (Double))))) >>= \_result476 -> (\(part477,part478) -> X.Tuple <$> sequence [pure (X.Dense (X.SomeMatrix SDouble part477)),pure (X.Dense (X.SomeMatrix SDouble part478))]) _result476
    (75,[a0,a1]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Rational)))
        a1Value <- (X.asList a1 >>= mapM (\item479 -> X.asScalar item479) :: IO [(Rational)])
        source ((D.jordanForm a0Value a1Value) :: (Either (E.MathError) ((M.Matrix (Rational)),(M.Matrix (Rational))))) >>= \_result480 -> (\(part481,part482) -> X.Tuple <$> sequence [pure (X.Dense (X.SomeMatrix SRational part481)),pure (X.Dense (X.SomeMatrix SRational part482))]) _result480
    (116,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((L.svd a0Value) :: (Either (E.MathError) (L.SVD))) >>= \_result483 -> encodeSVD _result483
    (117,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((L.fullSVD a0Value) :: (Either (E.MathError) (L.SVD))) >>= \_result484 -> encodeSVD _result484
    (118,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        source ((L.truncatedSVD a0Value a1Value) :: (Either (E.MathError) (L.SVD))) >>= \_result485 -> encodeSVD _result485
    (119,[a0,a1,a2,a3,a4]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asIndex a2 :: IO (Int))
        a3Value <- (X.asScalar a3 :: IO (Integer))
        a4Value <- (asMatrix a4 :: IO (M.Matrix (Double)))
        source ((L.randomizedSVD a0Value a1Value a2Value a3Value a4Value) :: (Either (E.MathError) (L.SVD))) >>= \_result486 -> encodeSVD _result486
    (120,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((L.eigen a0Value) :: (Either (E.MathError) (L.Eigen))) >>= \_result487 -> encodeEigen _result487
    (121,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((L.symmetricEigen a0Value) :: (Either (E.MathError) (L.Eigen))) >>= \_result488 -> encodeEigen _result488
    (122,[a0,a1]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        source ((L.generalizedEigen a0Value a1Value) :: (Either (E.MathError) (L.GeneralizedEigen))) >>= \_result489 -> encodeGeneralizedEigen _result489
    (123,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((L.schur a0Value) :: (Either (E.MathError) (L.Schur))) >>= \_result490 -> encodeSchur _result490
    (124,[a0,a1]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        source ((L.qz a0Value a1Value) :: (Either (E.MathError) (L.QZ))) >>= \_result491 -> encodeQZ _result491
    (125,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((L.hessenberg a0Value) :: (Either (E.MathError) (L.Hessenberg))) >>= \_result492 -> encodeHessenberg _result492
    (126,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((L.balance a0Value) :: (Either (E.MathError) (L.Balance))) >>= \_result493 -> encodeBalance _result493
    (127,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Complex (Double))))
        source ((L.complexSVD a0Value) :: (Either (E.MathError) (L.ComplexSVD))) >>= \_result494 -> encodeComplexSVD _result494
    (128,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Complex (Double))))
        source ((L.complexEigen a0Value) :: (Either (E.MathError) (L.Eigen))) >>= \_result495 -> encodeEigen _result495
    (129,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.SVD" a0 :: IO (L.SVD))
        pure (X.Dense (X.SomeMatrix SDouble ((L.svdU a0Value) :: (M.Matrix (Double)))))
    (130,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.SVD" a0 :: IO (L.SVD))
        X.List <$> mapM (\item496 -> pure (X.Scalar SDouble item496)) ((L.singularValues a0Value) :: [(Double)])
    (131,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.SVD" a0 :: IO (L.SVD))
        pure (X.Dense (X.SomeMatrix SDouble ((L.svdVT a0Value) :: (M.Matrix (Double)))))
    (132,[a0,a1,a2]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        a1Value <- (X.asList a1 >>= mapM (\item497 -> X.asScalar item497) :: IO [(Double)])
        a2Value <- (asMatrix a2 :: IO (M.Matrix (Double)))
        encodeSVD ((L.SVD a0Value a1Value a2Value) :: (L.SVD))
    (133,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.Eigen" a0 :: IO (L.Eigen))
        X.List <$> mapM (\item498 -> pure (X.Scalar SComplexDouble item498)) ((L.eigenvalues a0Value) :: [(Complex (Double))])
    (134,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.Eigen" a0 :: IO (L.Eigen))
        pure (X.Dense (X.SomeMatrix SComplexDouble ((L.eigenvectors a0Value) :: (M.Matrix (Complex (Double))))))
    (135,[a0,a1]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item499 -> X.asScalar item499) :: IO [(Complex (Double))])
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Complex (Double))))
        encodeEigen ((L.Eigen a0Value a1Value) :: (L.Eigen))
    (136,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.GeneralizedEigen" a0 :: IO (L.GeneralizedEigen))
        X.List <$> mapM (\item500 -> pure (X.Scalar SComplexDouble item500)) ((L.eigenAlpha a0Value) :: [(Complex (Double))])
    (137,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.GeneralizedEigen" a0 :: IO (L.GeneralizedEigen))
        X.List <$> mapM (\item501 -> pure (X.Scalar SDouble item501)) ((L.eigenBeta a0Value) :: [(Double)])
    (138,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.GeneralizedEigen" a0 :: IO (L.GeneralizedEigen))
        pure (X.Dense (X.SomeMatrix SComplexDouble ((L.generalizedEigenvectors a0Value) :: (M.Matrix (Complex (Double))))))
    (139,[a0,a1,a2]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item502 -> X.asScalar item502) :: IO [(Complex (Double))])
        a1Value <- (X.asList a1 >>= mapM (\item503 -> X.asScalar item503) :: IO [(Double)])
        a2Value <- (asMatrix a2 :: IO (M.Matrix (Complex (Double))))
        encodeGeneralizedEigen ((L.GeneralizedEigen a0Value a1Value a2Value) :: (L.GeneralizedEigen))
    (140,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.Schur" a0 :: IO (L.Schur))
        pure (X.Dense (X.SomeMatrix SDouble ((L.schurQ a0Value) :: (M.Matrix (Double)))))
    (141,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.Schur" a0 :: IO (L.Schur))
        pure (X.Dense (X.SomeMatrix SDouble ((L.schurT a0Value) :: (M.Matrix (Double)))))
    (142,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.Schur" a0 :: IO (L.Schur))
        X.List <$> mapM (\item504 -> pure (X.Scalar SComplexDouble item504)) ((L.schurEigenvalues a0Value) :: [(Complex (Double))])
    (143,[a0,a1,a2]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        a2Value <- (X.asList a2 >>= mapM (\item505 -> X.asScalar item505) :: IO [(Complex (Double))])
        encodeSchur ((L.Schur a0Value a1Value a2Value) :: (L.Schur))
    (144,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.QZ" a0 :: IO (L.QZ))
        pure (X.Dense (X.SomeMatrix SDouble ((L.qzQ a0Value) :: (M.Matrix (Double)))))
    (145,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.QZ" a0 :: IO (L.QZ))
        pure (X.Dense (X.SomeMatrix SDouble ((L.qzZ a0Value) :: (M.Matrix (Double)))))
    (146,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.QZ" a0 :: IO (L.QZ))
        pure (X.Dense (X.SomeMatrix SDouble ((L.qzS a0Value) :: (M.Matrix (Double)))))
    (147,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.QZ" a0 :: IO (L.QZ))
        pure (X.Dense (X.SomeMatrix SDouble ((L.qzT a0Value) :: (M.Matrix (Double)))))
    (148,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.QZ" a0 :: IO (L.QZ))
        X.List <$> mapM (\item506 -> pure (X.Scalar SComplexDouble item506)) ((L.qzAlpha a0Value) :: [(Complex (Double))])
    (149,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.QZ" a0 :: IO (L.QZ))
        X.List <$> mapM (\item507 -> pure (X.Scalar SDouble item507)) ((L.qzBeta a0Value) :: [(Double)])
    (150,[a0,a1,a2,a3,a4,a5]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        a2Value <- (asMatrix a2 :: IO (M.Matrix (Double)))
        a3Value <- (asMatrix a3 :: IO (M.Matrix (Double)))
        a4Value <- (X.asList a4 >>= mapM (\item508 -> X.asScalar item508) :: IO [(Complex (Double))])
        a5Value <- (X.asList a5 >>= mapM (\item509 -> X.asScalar item509) :: IO [(Double)])
        encodeQZ ((L.QZ a0Value a1Value a2Value a3Value a4Value a5Value) :: (L.QZ))
    (151,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.Hessenberg" a0 :: IO (L.Hessenberg))
        pure (X.Dense (X.SomeMatrix SDouble ((L.hessenbergQ a0Value) :: (M.Matrix (Double)))))
    (152,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.Hessenberg" a0 :: IO (L.Hessenberg))
        pure (X.Dense (X.SomeMatrix SDouble ((L.hessenbergH a0Value) :: (M.Matrix (Double)))))
    (153,[a0,a1]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        encodeHessenberg ((L.Hessenberg a0Value a1Value) :: (L.Hessenberg))
    (154,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.Balance" a0 :: IO (L.Balance))
        pure (X.Dense (X.SomeMatrix SDouble ((L.balancedMatrix a0Value) :: (M.Matrix (Double)))))
    (155,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.Balance" a0 :: IO (L.Balance))
        X.List <$> mapM (\item510 -> pure (X.Scalar SDouble item510)) ((L.balanceScales a0Value) :: [(Double)])
    (156,[a0,a1]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        a1Value <- (X.asList a1 >>= mapM (\item511 -> X.asScalar item511) :: IO [(Double)])
        encodeBalance ((L.Balance a0Value a1Value) :: (L.Balance))
    (157,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.ComplexSVD" a0 :: IO (L.ComplexSVD))
        pure (X.Dense (X.SomeMatrix SComplexDouble ((L.complexU a0Value) :: (M.Matrix (Complex (Double))))))
    (158,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.ComplexSVD" a0 :: IO (L.ComplexSVD))
        X.List <$> mapM (\item512 -> pure (X.Scalar SDouble item512)) ((L.complexSingularValues a0Value) :: [(Double)])
    (159,[a0]) -> do
        a0Value <- (unbox "HMath.Matrix.LAPACK.ComplexSVD" a0 :: IO (L.ComplexSVD))
        pure (X.Dense (X.SomeMatrix SComplexDouble ((L.complexVT a0Value) :: (M.Matrix (Complex (Double))))))
    (160,[a0,a1,a2]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Complex (Double))))
        a1Value <- (X.asList a1 >>= mapM (\item513 -> X.asScalar item513) :: IO [(Double)])
        a2Value <- (asMatrix a2 :: IO (M.Matrix (Complex (Double))))
        encodeComplexSVD ((L.ComplexSVD a0Value a1Value a2Value) :: (L.ComplexSVD))
    (197,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Integer))
        a1Value <- (unbox "HMath.Sparse.Sparse" a1 :: IO (S.Sparse (Double)))
        source ((S.sparseEigenReference a0Value a1Value) :: (Either (E.MathError) (L.Eigen))) >>= \_result514 -> encodeEigen _result514
    (198,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Integer))
        a1Value <- (unbox "HMath.Sparse.Sparse" a1 :: IO (S.Sparse (Double)))
        source ((S.sparseSVDReference a0Value a1Value) :: (Either (E.MathError) (L.SVD))) >>= \_result515 -> encodeSVD _result515
    (224,[a0]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        encodeBackendInfo ((B.backendInfo a0Value) :: (B.BackendInfo))
    (225,[]) -> do
        encodeBackend ((B.pureBackend ) :: (B.Backend))
    (226,[]) -> do
        ((B.lapackAvailable ) :: (IO (Bool))) >>= \_result516 -> pure (X.Boolean _result516)
    (227,[a0]) -> do
        a0Value <- (unbox "HMath.Backend.BackendRequest" a0 :: IO (B.BackendRequest))
        ((B.selectBackend a0Value) :: (IO (Either (E.MathError) (B.Backend)))) >>= \_result517 -> source _result517 >>= \_result518 -> encodeBackend _result518
    (228,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (X.asIndex a1 :: IO (Int))
        ((B.setBackendThreads a0Value a1Value) :: (IO (Either (E.MathError) ()))) >>= \_result519 -> source _result519 >>= \_result520 -> pure X.None
    (229,[a0,a1]) -> do
        a0Value <- (X.asText a0 :: IO (String))
        a1Value <- (X.asIndex a1 :: IO (Int))
        source ((B.lapackStatus a0Value a1Value) :: (Either (E.MathError) ())) >>= \_result521 -> pure X.None
    (232,[a0,a1,a2,a3]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (X.asList a2 >>= mapM (\item522 -> X.asScalar item522) :: IO [(Double)])
        a3Value <- (X.asList a3 >>= mapM (\item523 -> X.asScalar item523) :: IO [(Double)])
        ((B.axpy a0Value a1Value a2Value a3Value) :: (IO (Either (E.MathError) [(Double)]))) >>= \_result524 -> source _result524 >>= \_result525 -> X.List <$> mapM (\item526 -> pure (X.Scalar SDouble item526)) _result525
    (233,[a0,a1,a2]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (X.asList a1 >>= mapM (\item527 -> X.asScalar item527) :: IO [(Double)])
        a2Value <- (X.asList a2 >>= mapM (\item528 -> X.asScalar item528) :: IO [(Double)])
        ((B.dot a0Value a1Value a2Value) :: (IO (Either (E.MathError) (Double)))) >>= \_result529 -> source _result529 >>= \_result530 -> pure (X.Scalar SDouble _result530)
    (234,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (X.asList a1 >>= mapM (\item531 -> X.asScalar item531) :: IO [(Double)])
        ((B.nrm2 a0Value a1Value) :: (IO (Either (E.MathError) (Double)))) >>= \_result532 -> source _result532 >>= \_result533 -> pure (X.Scalar SDouble _result533)
    (235,[a0,a1,a2,a3,a4,a5,a6]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (unbox "HMath.Backend.Transpose" a1 :: IO (B.Transpose))
        a2Value <- (X.asScalar a2 :: IO (Double))
        a3Value <- (asMatrix a3 :: IO (M.Matrix (Double)))
        a4Value <- (X.asList a4 >>= mapM (\item534 -> X.asScalar item534) :: IO [(Double)])
        a5Value <- (X.asScalar a5 :: IO (Double))
        a6Value <- (X.asList a6 >>= mapM (\item535 -> X.asScalar item535) :: IO [(Double)])
        ((B.gemv a0Value a1Value a2Value a3Value a4Value a5Value a6Value) :: (IO (Either (E.MathError) [(Double)]))) >>= \_result536 -> source _result536 >>= \_result537 -> X.List <$> mapM (\item538 -> pure (X.Scalar SDouble item538)) _result537
    (236,[a0,a1,a2,a3,a4,a5,a6,a7]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (unbox "HMath.Backend.Transpose" a1 :: IO (B.Transpose))
        a2Value <- (unbox "HMath.Backend.Transpose" a2 :: IO (B.Transpose))
        a3Value <- (X.asScalar a3 :: IO (Double))
        a4Value <- (asMatrix a4 :: IO (M.Matrix (Double)))
        a5Value <- (asMatrix a5 :: IO (M.Matrix (Double)))
        a6Value <- (X.asScalar a6 :: IO (Double))
        a7Value <- (asMatrix a7 :: IO (M.Matrix (Double)))
        ((B.gemm a0Value a1Value a2Value a3Value a4Value a5Value a6Value a7Value) :: (IO (Either (E.MathError) (M.Matrix (Double))))) >>= \_result539 -> source _result539 >>= \_result540 -> pure (X.Dense (X.SomeMatrix SDouble _result540))
    (237,[a0,a1,a2,a3,a4,a5,a6,a7]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (unbox "HMath.Backend.Transpose" a1 :: IO (B.Transpose))
        a2Value <- (unbox "HMath.Backend.Transpose" a2 :: IO (B.Transpose))
        a3Value <- (X.asScalar a3 :: IO (Complex (Double)))
        a4Value <- (asMatrix a4 :: IO (M.Matrix (Complex (Double))))
        a5Value <- (asMatrix a5 :: IO (M.Matrix (Complex (Double))))
        a6Value <- (X.asScalar a6 :: IO (Complex (Double)))
        a7Value <- (asMatrix a7 :: IO (M.Matrix (Complex (Double))))
        ((B.complexGemm a0Value a1Value a2Value a3Value a4Value a5Value a6Value a7Value) :: (IO (Either (E.MathError) (M.Matrix (Complex (Double)))))) >>= \_result541 -> source _result541 >>= \_result542 -> pure (X.Dense (X.SomeMatrix SComplexDouble _result542))
    (238,[a0,a1,a2,a3]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (X.asScalar a1 :: IO (Complex (Double)))
        a2Value <- (X.asList a2 >>= mapM (\item543 -> X.asScalar item543) :: IO [(Complex (Double))])
        a3Value <- (X.asList a3 >>= mapM (\item544 -> X.asScalar item544) :: IO [(Complex (Double))])
        ((B.complexAxpy a0Value a1Value a2Value a3Value) :: (IO (Either (E.MathError) [(Complex (Double))]))) >>= \_result545 -> source _result545 >>= \_result546 -> X.List <$> mapM (\item547 -> pure (X.Scalar SComplexDouble item547)) _result546
    (239,[a0,a1,a2,a3]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (X.asBoolean a1 :: IO (Bool))
        a2Value <- (X.asList a2 >>= mapM (\item548 -> X.asScalar item548) :: IO [(Complex (Double))])
        a3Value <- (X.asList a3 >>= mapM (\item549 -> X.asScalar item549) :: IO [(Complex (Double))])
        ((B.complexDot a0Value a1Value a2Value a3Value) :: (IO (Either (E.MathError) (Complex (Double))))) >>= \_result550 -> source _result550 >>= \_result551 -> pure (X.Scalar SComplexDouble _result551)
    (240,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (X.asList a1 >>= mapM (\item552 -> X.asScalar item552) :: IO [(Complex (Double))])
        ((B.complexNrm2 a0Value a1Value) :: (IO (Either (E.MathError) (Double)))) >>= \_result553 -> source _result553 >>= \_result554 -> pure (X.Scalar SDouble _result554)
    (241,[a0,a1,a2,a3,a4,a5,a6]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (unbox "HMath.Backend.Transpose" a1 :: IO (B.Transpose))
        a2Value <- (X.asScalar a2 :: IO (Complex (Double)))
        a3Value <- (asMatrix a3 :: IO (M.Matrix (Complex (Double))))
        a4Value <- (X.asList a4 >>= mapM (\item555 -> X.asScalar item555) :: IO [(Complex (Double))])
        a5Value <- (X.asScalar a5 :: IO (Complex (Double)))
        a6Value <- (X.asList a6 >>= mapM (\item556 -> X.asScalar item556) :: IO [(Complex (Double))])
        ((B.complexGemv a0Value a1Value a2Value a3Value a4Value a5Value a6Value) :: (IO (Either (E.MathError) [(Complex (Double))]))) >>= \_result557 -> source _result557 >>= \_result558 -> X.List <$> mapM (\item559 -> pure (X.Scalar SComplexDouble item559)) _result558
    (242,[a0,a1,a2,a3,a4,a5]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (unbox "HMath.Backend.Transpose" a1 :: IO (B.Transpose))
        a2Value <- (unbox "HMath.Backend.Transpose" a2 :: IO (B.Transpose))
        a3Value <- (X.asScalar a3 :: IO (Double))
        a4Value <- (X.asScalar a4 :: IO (Double))
        a5Value <- (X.asList a5 >>= mapM (\item560 -> (X.asTuple 3 item560 >>= \items561 -> case items561 of { [part562,part563,part564] -> (,,) <$> (asMatrix part562) <*> (asMatrix part563) <*> (asMatrix part564); _ -> X.invalid "tuple arity differs" })) :: IO [((M.Matrix (Double)),(M.Matrix (Double)),(M.Matrix (Double)))])
        ((B.batchedGemm a0Value a1Value a2Value a3Value a4Value a5Value) :: (IO (Either (E.MathError) [(M.Matrix (Double))]))) >>= \_result565 -> source _result565 >>= \_result566 -> X.List <$> mapM (\item567 -> pure (X.Dense (X.SomeMatrix SDouble item567))) _result566
    (243,[a0,a1,a2,a3,a4,a5,a6,a7,a8]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asIndex a2 :: IO (Int))
        a3Value <- (X.asIndex a3 :: IO (Int))
        a4Value <- (X.asIndex a4 :: IO (Int))
        a5Value <- (X.asIndex a5 :: IO (Int))
        a6Value <- (X.asList a6 >>= mapM (\item568 -> X.asScalar item568) :: IO [(Double)])
        a7Value <- (X.asIndex a7 :: IO (Int))
        a8Value <- (X.asList a8 >>= mapM (\item569 -> X.asScalar item569) :: IO [(Double)])
        ((B.stridedBatchedGemm a0Value a1Value a2Value a3Value a4Value a5Value a6Value a7Value a8Value) :: (IO (Either (E.MathError) [(M.Matrix (Double))]))) >>= \_result570 -> source _result570 >>= \_result571 -> X.List <$> mapM (\item572 -> pure (X.Dense (X.SomeMatrix SDouble item572))) _result571
    (244,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        source ((B.backendLU a0Value a1Value) :: (Either (E.MathError) (LU.LU (Double)))) >>= \_result573 -> encodeLegacyLU _result573
    (245,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        source ((B.backendQR a0Value a1Value) :: (Either (E.MathError) (QR.QR (Double)))) >>= \_result574 -> encodeLegacyQR _result574
    (246,[a0,a1,a2]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        a2Value <- (X.asList a2 >>= mapM (\item575 -> X.asScalar item575) :: IO [(Double)])
        source ((B.backendSolve a0Value a1Value a2Value) :: (Either (E.MathError) [(Double)])) >>= \_result576 -> X.List <$> mapM (\item577 -> pure (X.Scalar SDouble item577)) _result576
    (247,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        source ((B.backendCholesky a0Value a1Value) :: (Either (E.MathError) (M.Matrix (Double)))) >>= \_result578 -> pure (X.Dense (X.SomeMatrix SDouble _result578))
    (248,[a0,a1,a2]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        a2Value <- (X.asList a2 >>= mapM (\item579 -> X.asScalar item579) :: IO [(Double)])
        source ((B.backendLeastSquares a0Value a1Value a2Value) :: (Either (E.MathError) [(Double)])) >>= \_result580 -> X.List <$> mapM (\item581 -> pure (X.Scalar SDouble item581)) _result580
    (249,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        source ((B.backendSVD a0Value a1Value) :: (Either (E.MathError) (L.SVD))) >>= \_result582 -> encodeSVD _result582
    (250,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Backend.Backend" a0 :: IO (B.Backend))
        a1Value <- (asMatrix a1 :: IO (M.Matrix (Double)))
        source ((B.backendSymmetricEigen a0Value a1Value) :: (Either (E.MathError) (L.Eigen))) >>= \_result583 -> encodeEigen _result583
    (251,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((B.pureSymmetricEigen a0Value) :: (Either (E.MathError) (L.Eigen))) >>= \_result584 -> encodeEigen _result584
    (252,[a0]) -> do
        a0Value <- (asMatrix a0 :: IO (M.Matrix (Double)))
        source ((B.pureSVD a0Value) :: (Either (E.MathError) (L.SVD))) >>= \_result585 -> encodeSVD _result585
    (253,[]) -> do
        encodeProvider ((B.Pure ) :: (B.Provider))
    (254,[]) -> do
        encodeProvider ((B.OpenBLAS ) :: (B.Provider))
    (255,[]) -> do
        encodeProvider ((B.BLIS ) :: (B.Provider))
    (256,[]) -> do
        encodeProvider ((B.OneMKL ) :: (B.Provider))
    (257,[]) -> do
        encodeProvider ((B.Accelerate ) :: (B.Provider))
    (258,[]) -> do
        encodeIntegerABI ((B.LP64 ) :: (B.IntegerABI))
    (259,[]) -> do
        encodeIntegerABI ((B.ILP64 ) :: (B.IntegerABI))
    (260,[]) -> do
        encodeBackendRequest ((B.AutoBackend ) :: (B.BackendRequest))
    (261,[a0,a1,a2]) -> do
        a0Value <- (unbox "HMath.Backend.Provider" a0 :: IO (B.Provider))
        a1Value <- (unbox "HMath.Backend.IntegerABI" a1 :: IO (B.IntegerABI))
        a2Value <- ((case a2 of { X.None -> pure Nothing; _ -> Just <$> (X.asText a2) }) :: IO (Maybe (String)))
        encodeBackendRequest ((B.RequireBackend a0Value a1Value a2Value) :: (B.BackendRequest))
    (262,[a0]) -> do
        a0Value <- (unbox "HMath.Backend.BackendInfo" a0 :: IO (B.BackendInfo))
        encodeProvider ((B.selectedProvider a0Value) :: (B.Provider))
    (263,[a0]) -> do
        a0Value <- (unbox "HMath.Backend.BackendInfo" a0 :: IO (B.BackendInfo))
        encodeIntegerABI ((B.selectedIntegerABI a0Value) :: (B.IntegerABI))
    (264,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Backend.Provider" a0 :: IO (B.Provider))
        a1Value <- (unbox "HMath.Backend.IntegerABI" a1 :: IO (B.IntegerABI))
        encodeBackendInfo ((B.BackendInfo a0Value a1Value) :: (B.BackendInfo))
    (265,[]) -> do
        encodeBackendLayout ((B.RowMajor ) :: (B.BackendLayout))
    (266,[]) -> do
        encodeBackendLayout ((B.ColumnMajor ) :: (B.BackendLayout))
    (267,[]) -> do
        encodeTranspose ((B.NoTranspose ) :: (B.Transpose))
    (268,[]) -> do
        encodeTranspose ((B.Transpose ) :: (B.Transpose))
    (269,[]) -> do
        encodeTranspose ((B.ConjugateTranspose ) :: (B.Transpose))
    (-1,[value]) -> X.Text <$> objectName value
    (-2,[value]) -> objectParts value
    _ -> X.invalid "unsupported concrete linear operation/arity"

{-# NOINLINE generateCallback #-}
generateCallback :: Coefficient a => X.Value -> Int -> Int -> a
generateCallback callback row column=unsafePerformIO $ callbackValue callback (X.Tuple[X.Index row,X.Index column]) >>= X.asScalar
{-# NOINLINE zipCallback #-}
zipCallback :: (Coefficient a,Coefficient b,Coefficient c) => ScalarType a -> ScalarType b -> X.Value -> a -> b -> c
zipCallback wa wb callback left right=unsafePerformIO $ callbackValue callback (X.Tuple[X.Scalar wa left,X.Scalar wb right]) >>= X.asScalar
special :: Int -> X.Value -> [X.Value] -> IO X.Value
special operation prototype args=case(operation,args) of
    (3,[dimension,values]) -> withWitness prototype $ \(w::ScalarType a) -> do
        count <- X.asIndex dimension
        xs <- X.asList values >>= mapM X.asScalar
        fixedFrom w count xs
    (4,[value]) -> withWitness prototype $ \(w::ScalarType a) -> do
        fixed <- (unbox "HMath.Vector.FixedVector" value :: IO(SomeFixed a))
        case fixed of SomeFixed f -> X.List . map (X.Scalar w) <$> pure(V.fixedValues f)
    (29,[rows,columns,callback]) -> withWitness prototype $ \(w::ScalarType a) -> do
        r <- X.asIndex rows; c <- X.asIndex columns
        matrix <- source(A.generateMatrix r c (generateCallback callback) :: Either E.MathError(M.Matrix a))
        pure(X.Dense(X.SomeMatrix w matrix))
    (37,[callback,left,right]) -> do
        prototypes <- X.asTuple 3 prototype
        case prototypes of
            [pa,pb,pc] -> withWitness pa $ \(wa::ScalarType a) -> withWitness pb $ \(wb::ScalarType b) -> withWitness pc $ \(wc::ScalarType c) -> do
                a <- (asMatrix left :: IO(M.Matrix a)); b <- (asMatrix right :: IO(M.Matrix b))
                matrix <- source(A.zipMatrixWith (zipCallback wa wb callback) a b :: Either E.MathError(M.Matrix c))
                pure(X.Dense(X.SomeMatrix wc matrix))
            _ -> X.invalid "zipMatrixWith requires three coefficient prototypes"
    _ -> X.invalid "invalid special linear operation/arity"
foreign export ccall "hm_linear_apply" ffiApply :: CInt -> StablePtr X.Value -> Ptr(StablePtr X.Value) -> CSize -> Ptr(StablePtr X.Value) -> IO CInt
ffiApply :: CInt -> StablePtr X.Value -> Ptr(StablePtr X.Value) -> CSize -> Ptr(StablePtr X.Value) -> IO CInt
ffiApply operation prototype pointers count out=linearBoundary $ do
    values <- peekArray(fromIntegral count) pointers >>= mapM deRefStablePtr
    let op=fromIntegral operation
    value <- if op `elem` [3, 4, 29, 37] then do
            p <- deRefStablePtr prototype
            if structuralVectorInput p values then structuralVectors op p values else special op p values
        else if op `elem` [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 53, 54, 61, 62, 63, 64, 65, 66, 68, 69, 70, 71, 72, 73, 74, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 230, 231] then do
            p <- deRefStablePtr prototype
            if structuralVectorInput p values then structuralVectors op p values else withWitness p (\w -> generic w op values)
        else concrete op values
    Boundary.checked(Right())(const(X.publish value out))
