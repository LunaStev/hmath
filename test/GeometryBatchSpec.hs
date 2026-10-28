-- SPDX-License-Identifier: MPL-2.0

-- | Analytic, exhaustive-small and independent invariant checks for #30/#31.
module GeometryBatchSpec (geometryBatchTests) where

import Data.Complex (Complex ((:+)))
import qualified Data.Complex as C
import Data.Either (isLeft)
import Data.List (subsequences)
import qualified HMath.Complex as Z
import HMath.Error (MathError)
import HMath.Geometry
import qualified HMath.Matrix as M
import qualified HMath.Quaternion as Q
import qualified HMath.Rotation as R

near :: Double -> Double -> Bool
near a b = abs (a - b) <= 1e-8 * max 1 (max (abs a) (abs b))
nearV :: [Double] -> [Double] -> Bool
nearV a b = length a == length b && and (zipWith near a b)
nearP :: Point2 -> Point2 -> Bool
nearP (P2 a b) (P2 x y) = nearV [a, b] [x, y]
right :: (a -> Bool) -> Either MathError a -> Bool
right f x = case x of Right a -> f a; Left _ -> False
nearR :: Double -> Either MathError Double -> Bool
nearR x = right (near x)
qIdentity :: Q.Quaternion -> Bool
qIdentity q = let xs = Q.components q in nearV xs [1, 0, 0, 0] || nearV xs [-1, 0, 0, 0]
rotationEqual :: Q.Quaternion -> Q.Quaternion -> Bool
rotationEqual a b = right qIdentity (Q.inverse a >>= Q.multiply b)
rect :: Double -> Double -> Double -> Double -> [Point2]
rect x y w h = [P2 x y, P2 (x + w) y, P2 (x + w) (y + h), P2 x (y + h)]
areaRings :: [Polygon] -> Double
areaRings rings = sum [case shoelace p of Right a -> a; Left _ -> 0 | p <- rings]
triArea :: [Point2] -> IndexedTriangle -> Double
triArea ps (a, b, c) = case polygonArea (Polygon [ps !! a, ps !! b, ps !! c]) of Right x -> x; Left _ -> 0
geometryBatchTests :: [(String, Bool)]
geometryBatchTests =
    complexTests
        ++ quaternionTests
        ++ rotationTests
        ++ primitiveTests
        ++ polygonTests
        ++ triangulationTests
        ++ spatialTests
        ++ transformTests
        ++ collisionTests

complexTests :: [(String, Bool)]
complexTests =
    [
        ( "complex construction and components"
        , right (\z -> Z.realPart z == 3 && Z.imagPart z == 4) (Z.complex 3 4)
        )
    ,
        ( "complex magnitude phase conjugate"
        , near (Z.magnitude (3 :+ 4)) 5
            && near (Z.phase (0 :+ 1)) (pi / 2)
            && Z.conjugate (3 :+ 4 :: Complex Double) == 3 :+ (-4)
        )
    , ("complex rejects nonfinite", isLeft (Z.complex (0 / 0) 1) && isLeft (Z.complex 1 (1 / 0)))
    , ("complex zero reciprocal", isLeft (Z.reciprocal 0))
    ,
        ( "complex scaled reciprocal"
        , right (\z -> C.magnitude (z - (0.5e-300 :+ (-0.5e-300))) < 1e-310) (Z.reciprocal (1e300 :+ 1e300))
        )
    ,
        ( "complex scaled division"
        , right (\z -> C.magnitude (z - 1) < 1e-14) (Z.divide (1e300 :+ 1e300) (1e300 :+ 1e300))
        )
    ,
        ( "complex principal square root"
        , right (\z -> C.magnitude (z - (0 :+ 1)) < 1e-12) (Z.elementary Z.Sqrt ((-1) :+ 0))
        )
    , ("complex principal log cut", right (\z -> near (C.imagPart z) pi) (Z.elementary Z.Log ((-1) :+ 0)))
    , ("complex log zero rejected", isLeft (Z.elementary Z.Log 0))
    ,
        ( "complex power zero contracts"
        , Z.power 0 0 == Right 1 && Z.power 0 2 == Right 0 && isLeft (Z.power 0 (-1))
        )
    ,
        ( "complex polar conversion"
        , right (\z -> right (\(r, p) -> near r 2 && near p (pi / 3)) (Z.toPolar z)) (Z.fromPolar 2 (pi / 3))
        )
    , ("complex plane rotation", right (\z -> C.magnitude (z - (0 :+ 1)) < 1e-12) (Z.rotate (pi / 2) 1))
    , ("complex polar rejects radius", isLeft (Z.fromPolar (-1) 0))
    ,
        ( "complex matrix Hermitian involution"
        , right
            (\a -> right (== a) (Z.conjugateTranspose a >>= Z.conjugateTranspose))
            (Z.complexMatrix 2 2 [1 :+ 2, 3 :+ 4, 5 :+ 6, 7 :+ 8])
        )
    ,
        ( "complex matrix multiply"
        , right
            (\a -> right (\c -> M.toList c == [5 :+ 0, 8 :+ 0, 8 :+ 0, 13 :+ 0]) (Z.multiplyMatrices a a))
            (Z.complexMatrix 2 2 [1 :+ 0, 2 :+ 0, 2 :+ 0, 3 :+ 0])
        )
    , ("complex matrix nonfinite rejected", isLeft (Z.complexMatrix 1 1 [1 / 0 :+ 0]))
    ]
        ++ [ ( "complex arithmetic identity " ++ show n
             , let a = fromIntegral n :+ 0.25; b = 2 :+ (-1)
                in right (\x -> right (\z -> C.magnitude (z - a) < 1e-10) (Z.divide x b)) (Z.multiply a b)
                    && right (== a) (Z.add a b >>= (\v -> Z.subtractComplex v b))
             )
           | n <- [-10 :: Int .. 10]
           ]
        ++ [ ( "complex elementary round trip " ++ show op
             , right (\v -> C.magnitude (v - z) < 1e-9) (Z.elementary op z >>= Z.elementary inv)
             )
           | (op, inv) <-
                [(Z.Exp, Z.Log), (Z.Sin, Z.Asin), (Z.Sinh, Z.Asinh), (Z.Tan, Z.Atan), (Z.Tanh, Z.Atanh)]
           , let z = 0.2 :+ 0.3
           ]
        ++ [ ( "complex FFT round trip " ++ show n
             , right
                (\zs -> and (zipWith (\a b -> C.magnitude (a - b) < 1e-9) xs zs))
                (Z.complexFFT xs >>= Z.complexIFFT)
             )
           | n <- [1 .. 16 :: Int]
           , let xs = [fromIntegral j :+ fromIntegral (j `mod` 3) | j <- [0 .. n - 1]]
           ]

quaternionTests :: [(String, Bool)]
quaternionTests =
    [
        ( "quaternion tiny inverse representable components"
        , right
            (\q -> right (\r -> nearV (map (/ 1.25e308) (Q.components r)) [1, -1, -1, -1]) (Q.inverse q))
            (Q.quaternion 2e-309 2e-309 2e-309 2e-309)
        )
    ,
        ( "quaternion negative-real near-axis log"
        , right
            (\q -> right (\r -> nearV (Q.components r) [0, 0, pi, 0]) (Q.logarithm q))
            (Q.quaternion (-1) 0 1e-200 0)
        )
    ,
        ( "SQUAD sign equivalent neighboring representatives"
        , right
            ( \a ->
                right
                    ( \b ->
                        right
                            ( \negative -> right (\p -> right (rotationEqual p) (Q.squad 0.5 a a negative negative)) (Q.squad 0.5 a a b b)
                            )
                            (Q.scale (-1) b)
                    )
                    (Q.axisAngle [0, 0, 1] 0.7)
            )
            (Q.axisAngle [0, 0, 1] 0)
        )
    ,
        ( "quaternion scalar first construction"
        , right ((== [1, 2, 3, 4]) . Q.components) (Q.quaternion 1 2 3 4)
        )
    , ("quaternion zero normalization", right (isLeft . Q.normalize) (Q.quaternion 0 0 0 0))
    ,
        ( "quaternion tiny normalization"
        , right (\q -> right qIdentity (Q.normalize q)) (Q.quaternion 1e-320 0 0 0)
        )
    , ("quaternion overflow construction", isLeft (Q.quaternion (1 / 0) 0 0 0))
    ,
        ( "quaternion Hamilton ij=k"
        , right
            (\i -> right (\j -> right ((== [0, 0, 0, 1]) . Q.components) (Q.multiply i j)) (Q.quaternion 0 0 1 0))
            (Q.quaternion 0 1 0 0)
        )
    ,
        ( "quaternion active z rotation"
        , right (\q -> right (nearV [0, 1, 0]) (Q.rotateVector q [1, 0, 0])) (Q.axisAngle [0, 0, 1] (pi / 2))
        )
    ,
        ( "quaternion invalid rotation vector"
        , right (\q -> isLeft (Q.rotateVector q [1, 2])) (Q.axisAngle [1, 0, 0] 0)
        )
    , ("quaternion zero axis rejected", isLeft (Q.axisAngle [0, 0, 0] 0))
    ,
        ( "quaternion matrix rejects reflection"
        , right (isLeft . Q.fromMatrix) (M.fromListChecked 3 3 [-1, 0, 0, 0, 1, 0, 0, 0, 1])
        )
    ,
        ( "quaternion matrix rejects shear"
        , right (isLeft . Q.fromMatrix) (M.fromListChecked 3 3 [1, 1, 0, 0, 1, 0, 0, 0, 1])
        )
    ,
        ( "quaternion interpolation outside domain"
        , right (\q -> isLeft (Q.slerp 2 q q) && isLeft (Q.nlerp (-1) q q)) (Q.axisAngle [1, 0, 0] 1)
        )
    ,
        ( "quaternion swing twist recomposes"
        , right
            (\q -> right (\(s, t) -> right (\p -> rotationEqual p q) (Q.multiply s t)) (Q.swingTwist [0, 0, 1] q))
            (Q.fromEuler 0.4 0.6 0.8)
        )
    ,
        ( "quaternion singular swing twist"
        , right
            (\q -> right (\(s, t) -> qIdentity t && rotationEqual s q) (Q.swingTwist [0, 0, 1] q))
            (Q.quaternion 0 1 0 0)
        )
    ]
        ++ [ ( "quaternion inverse identity " ++ show n
             , right (\q -> right qIdentity (Q.inverse q >>= Q.multiply q)) (Q.quaternion (fromIntegral n) 1 2 3)
             )
           | n <- [-10 :: Int .. 10]
           ]
        ++ [ ( "quaternion matrix and axis round trip " ++ show theta
             , right
                ( \q ->
                    right (\p -> rotationEqual q p) (Q.toMatrix q >>= Q.fromMatrix)
                        && right (\(axis, t) -> right (\p -> rotationEqual p q) (Q.axisAngle axis t)) (Q.toAxisAngle q)
                )
                (Q.axisAngle [1, 2, 3] theta)
             )
           | theta <- [0, 1e-12, 0.1, 1, pi - 1e-10, pi, pi + 1e-10, 2 * pi]
           ]
        ++ [ ( "quaternion Euler round trip " ++ show angles
             , right
                (\q -> right (\(x, y, z) -> right (\p -> rotationEqual p q) (Q.fromEuler x y z)) (Q.toEuler q))
                (Q.fromEuler a b c)
             )
           | angles@(a, b, c) <- [(0, 0, 0), (0.2, 0.4, 0.7), (0.6, pi / 2, 0.9), (0.2, -pi / 2, 1.1)]
           ]
        ++ [ ( "quaternion interpolation endpoints " ++ show t
             , right
                ( \a ->
                    right
                        (\b -> right (\p -> rotationEqual p (if t == 0 then a else b)) (method t a b))
                        (Q.axisAngle [0, 1, 0] 2)
                )
                (Q.axisAngle [1, 0, 0] 1)
             )
           | t <- [0, 1]
           , method <- [Q.slerp, Q.nlerp]
           ]
        ++ [ ( "quaternion sign equivalent interpolation " ++ show t
             , right
                (\q -> right (\negative -> right (\p -> rotationEqual p q) (Q.slerp t q negative)) (Q.scale (-1) q))
                (Q.axisAngle [1, 2, 3] 1)
             )
           | t <- [0, 0.25, 0.5, 0.75, 1]
           ]
        ++ [ ( "quaternion exp log round trip " ++ show n
             , right
                (\q -> right (\p -> nearV (Q.components p) (Q.components q)) (Q.logarithm q >>= Q.exponential))
                (Q.quaternion (fromIntegral n) 1 2 3)
             )
           | n <- [-3 :: Int .. 3]
           ]
        ++ [ ( "quaternion SQUAD endpoint " ++ show t
             , right
                ( \a ->
                    right
                        ( \b ->
                            right
                                ( \c ->
                                    right
                                        (\d -> right (\p -> rotationEqual p (if t == 0 then b else c)) (Q.squad t a b c d))
                                        (Q.axisAngle [0, 0, 1] 1.5)
                                )
                                (Q.axisAngle [0, 0, 1] 1)
                        )
                        (Q.axisAngle [0, 0, 1] 0.5)
                )
                (Q.axisAngle [0, 0, 1] 0)
             )
           | t <- [0, 1]
           ]

rotationTests :: [(String, Bool)]
rotationTests =
    [ ( "SO3 exp log " ++ show theta
      , right (\r -> right (\w -> nearV w [theta, 0, 0]) (R.logSO3 r)) (R.expSO3 [theta, 0, 0])
      )
    | theta <- [0, 1e-12, 1e-5, 1, pi - 1e-9, pi]
    ]
        ++ [ ( "SE3 exp log " ++ show theta
             , right
                (\t -> right (\(w, v) -> nearV w [0, 0, theta] && nearV v [1, 2, 3]) (R.logSE3 t))
                (R.expSE3 ([0, 0, theta], [1, 2, 3]))
             )
           | theta <- [0, 1e-12, 1e-5, 1, pi - 1e-9]
           ]
        ++ [ ( "SE3 inverse point " ++ show theta
             , right
                ( \t ->
                    right
                        (nearV [1, 2, 3])
                        (R.transformPoint t [1, 2, 3] >>= (\p -> R.inverse t >>= (\i -> R.transformPoint i p)))
                )
                (R.expSE3 ([0, theta, 0], [3, -2, 1]))
             )
           | theta <- [0, 0.1, pi]
           ]
        ++ [
               ( "SE3 homogeneous and dual round trips"
               , right
                    ( \t ->
                        right
                            ( \s ->
                                right (nearV [4, 5, 6]) (R.transformPoint t [1, 2, 3]) && R.translationPart s == R.translationPart t
                            )
                            (R.toHomogeneous t >>= R.fromHomogeneous)
                            && right
                                (\s -> nearV (R.translationPart s) (R.translationPart t))
                                (R.toDualQuaternion t >>= R.fromDualQuaternion)
                    )
                    (R.se3 R.identityRotation [3, 3, 3])
               )
           , ("SE3 nonfinite translation", isLeft (R.se3 R.identityRotation [0, 0, 1 / 0]))
           , ("SO3 invalid tangent dimension", isLeft (R.expSO3 [1, 2]))
           , ("dual Study condition", right (\q -> isLeft (R.dualQuaternion q q)) (Q.quaternion 1 0 0 0))
           ,
               ( "dual product and inverse"
               , right
                    ( \a ->
                        right
                            ( \d ->
                                right
                                    (\p -> right (nearV [0, 0, 0] . R.translationPart) (R.fromDualQuaternion p))
                                    (R.inverseDual d >>= R.multiplyDual d)
                            )
                            (R.toDualQuaternion a)
                    )
                    (R.expSE3 ([0, 0, 0.4], [1, 2, 3]))
               )
           ]
        ++ [ ( "dual translation interpolation " ++ show t
             , right
                ( \a ->
                    right
                        ( \b ->
                            right
                                (\d -> right (nearV [t * 2, 0, 0] . R.translationPart) (R.fromDualQuaternion d))
                                (R.interpolateDual t a b)
                        )
                        (R.se3 R.identityRotation [2, 0, 0] >>= R.toDualQuaternion)
                )
                (R.toDualQuaternion R.identityTransform)
             )
           | t <- [0, 0.25, 0.5, 1]
           ]

primitiveTests :: [(String, Bool)]
primitiveTests =
    [
        ( "tiny ray and plane intersections"
        , linePlaneIntersection
            (Line (PointND [0, 0, 0]) (PointND [0, 0, 1e-200]))
            (Plane (P3 0 0 1e-200) 1e-200)
            == Right (Just (Just (P3 0 0 1)))
            && right
                (\x -> case x of Just (Just _) -> True; _ -> False)
                (planeIntersection (Plane (P3 1e-200 0 0) 1e-200) (Plane (P3 0 1e-200 0) 2e-200))
        )
    ,
        ( "tiny triangle transverse ray"
        , rayTriangle (Ray (P3 0 0 1e-200) (P3 0 0 (-1e-200))) (P3 0 0 0, P3 1e-200 0 0, P3 0 1e-200 0)
            == Right (Just 1)
        )
    ,
        ( "tiny ray sphere finite parameter"
        , raySphere (Ray (P3 (-2e-200) 0 0) (P3 1e-200 0 0)) (Sphere (P3 0 0 0) 1e-200) == Right (Just (1, 3))
        )
    ,
        ( "tiny circle intersection scale"
        , right
            ( \result -> case result of
                CirclePoints ps -> length ps == 2 && all (\(P2 x _) -> near (x / 1e-200) 0.5) ps
                _ -> False
            )
            (circleIntersection (Circle (P2 0 0) 1e-200) (Circle (P2 1e-200 0) 1e-200))
        )
    ,
        ( "tiny plane distance and cosine"
        , right (\v -> near (v / 1e-200) 1) (pointPlaneDistance (P3 0 0 1e-200) (Plane (P3 0 0 1e-200) 0))
            && nearR 0 (cosineDistance (PointND [1e-320, 0]) (PointND [1e-320, 0]))
        )
    ,
        ( "triangle overlap ring is ordered"
        , right
            (\ps -> nearR 2 (polygonArea (Polygon ps)))
            (triangleIntersection (Triangle (P2 0 0) (P2 4 0) (P2 0 4)) (Triangle (P2 0 0) (P2 2 0) (P2 0 2)))
        )
    ,
        ( "point dimension and coordinate validation"
        , isLeft (pointND []) && isLeft (pointND (replicate 17 0)) && isLeft (point2 (1 / 0) 0)
        )
    ,
        ( "ND Euclidean Manhattan Chebyshev Minkowski"
        , and
            [ nearR expected (distance metric (PointND [0, 0]) (PointND [3, 4]))
            | (metric, expected) <- [(Euclidean, 5), (Manhattan, 7), (Chebyshev, 4), (Minkowski 2, 5)]
            ]
        )
    ,
        ( "metric invalid dimension p"
        , isLeft (distance Euclidean (PointND [1]) (PointND [1, 2]))
            && isLeft (distance (Minkowski 0.5) (PointND [0]) (PointND [1]))
        )
    ,
        ( "cosine identity opposite zero"
        , nearR 0 (cosineDistance (PointND [1, 2]) (PointND [2, 4]))
            && nearR 2 (cosineDistance (PointND [1, 0]) (PointND [-1, 0]))
            && isLeft (cosineDistance (PointND [0]) (PointND [1]))
        )
    ,
        ( "Hamming and Jaccard"
        , hammingDistance [1 :: Int, 2, 3] [1, 4, 3] == Right 1
            && nearR (2 / 3) (jaccardDistance [1 :: Int, 1, 2] [2, 3])
            && nearR 0 (jaccardDistance ([] :: [Int]) [])
        )
    ,
        ( "Hausdorff and empty"
        , nearR 2 (hausdorffDistance [PointND [0], PointND [2]] [PointND [0]])
            && isLeft (hausdorffDistance [] [PointND [0]])
        )
    ,
        ( "Mahalanobis SPD solve"
        , nearR (sqrt 2) (mahalanobisDistance [[4, 0], [0, 9]] (PointND [0, 0]) (PointND [2, 3]))
            && isLeft (mahalanobisDistance [[1, 2], [2, 1]] (PointND [0, 0]) (PointND [1, 1]))
        )
    ,
        ( "point line segment distances"
        , nearR 2 (pointLineDistance (PointND [1, 2]) (Line (PointND [0, 0]) (PointND [1, 0])))
            && nearR (sqrt 5) (pointSegmentDistance (PointND [2, 2]) (Segment (PointND [0, 0]) (PointND [1, 0])))
        )
    ,
        ( "zero segment and invalid line"
        , nearR 1 (pointSegmentDistance (PointND [1]) (Segment (PointND [0]) (PointND [0])))
            && isLeft (pointLineDistance (PointND [0]) (Line (PointND [0]) (PointND [0])))
        )
    , ("plane scaled normal distance", nearR 3 (pointPlaneDistance (P3 0 0 4) (Plane (P3 0 0 2) 2)))
    ,
        ( "exact orientation near cancellation"
        , orientation (P2 0 0) (P2 1e20 1e20) (P2 1e20 (1e20 + 16384)) == Right Counterclockwise
        )
    ,
        ( "exact incircle inside outside cocircular"
        , incircle (P2 0 0) (P2 1 0) (P2 0 1) (P2 0.5 0.5) == Right GT
            && incircle (P2 0 0) (P2 0 1) (P2 1 0) (P2 2 2) == Right LT
            && incircle (P2 0 0) (P2 1 0) (P2 0 1) (P2 1 1) == Right EQ
        )
    ,
        ( "polygon interior boundary outside"
        , polygonLocation (Polygon (rect 0 0 2 2)) (P2 1 1) == Right Inside
            && polygonLocation (Polygon (rect 0 0 2 2)) (P2 0 1) == Right Boundary
            && polygonLocation (Polygon (rect 0 0 2 2)) (P2 3 1) == Right Outside
        )
    ,
        ( "triangle boundary barycentric centers"
        , triangleLocation (Triangle (P2 0 0) (P2 2 0) (P2 0 2)) (P2 1 1) == Right Boundary
            && right (nearV [0, 0.5, 0.5]) (triangleBarycentric (Triangle (P2 0 0) (P2 2 0) (P2 0 2)) (P2 1 1))
            && right (nearP (P2 1 1)) (circumcenter (Triangle (P2 0 0) (P2 2 0) (P2 0 2)))
        )
    , ("triangle incenter", right (nearP (P2 1 1)) (incenter (Triangle (P2 0 0) (P2 4 0) (P2 0 3))))
    ,
        ( "degenerate triangle rejected"
        , isLeft (triangleLocation (Triangle (P2 0 0) (P2 1 0) (P2 2 0)) (P2 0 0))
        )
    ,
        ( "closed zero sphere box"
        , sphereContains (Sphere (P3 1 2 3) 0) (P3 1 2 3) == Right True
            && boxContains (AABB (PointND [0, 0]) (PointND [0, 0])) (PointND [0, 0]) == Right True
        )
    , ("rotated ellipse", ellipseContains (Ellipse (P2 0 0) 2 1 (pi / 2)) (P2 0 2) == Right True)
    ,
        ( "segment crossing tangent overlap disjoint"
        , segmentIntersection (P2 0 0) (P2 2 2) (P2 0 2) (P2 2 0) == Right (IntersectionPoint (P2 1 1))
            && segmentIntersection (P2 0 0) (P2 1 0) (P2 1 0) (P2 2 0) == Right (IntersectionPoint (P2 1 0))
            && segmentIntersection (P2 0 0) (P2 2 0) (P2 1 0) (P2 3 0) == Right (OverlapSegment (P2 1 0) (P2 2 0))
            && segmentIntersection (P2 0 0) (P2 1 0) (P2 2 0) (P2 3 0) == Right NoIntersection
        )
    ,
        ( "line coincidence with sub-ULP direction"
        , lineIntersection (P2 1e20 1e20) (P2 1 0) (P2 0 (1e20 + 16384)) (P2 1 0) == Right NoIntersection
        )
    ,
        ( "line parallel and coincident"
        , lineIntersection (P2 0 0) (P2 1 0) (P2 0 1) (P2 1 0) == Right NoIntersection
            && lineIntersection (P2 0 0) (P2 1 0) (P2 2 0) (P2 1 0) == Right CoincidentLine
        )
    ,
        ( "line plane unique coincident parallel"
        , linePlaneIntersection (Line (PointND [0, 0, 0]) (PointND [0, 0, 2])) (Plane (P3 0 0 1) 1)
            == Right (Just (Just (P3 0 0 1)))
            && linePlaneIntersection (Line (PointND [0, 0, 0]) (PointND [1, 0, 0])) (Plane (P3 0 0 1) 0)
                == Right (Just Nothing)
            && linePlaneIntersection (Line (PointND [0, 0, 0]) (PointND [1, 0, 0])) (Plane (P3 0 0 1) 1)
                == Right Nothing
        )
    ,
        ( "plane plane unique parallel coincidence"
        , right
            (\r -> case r of Just (Just _) -> True; _ -> False)
            (planeIntersection (Plane (P3 1 0 0) 1) (Plane (P3 0 1 0) 2))
            && planeIntersection (Plane (P3 0 0 1) 1) (Plane (P3 0 0 2) 2) == Right (Just Nothing)
            && planeIntersection (Plane (P3 0 0 1) 1) (Plane (P3 0 0 1) 2) == Right Nothing
        )
    ,
        ( "ray triangle transverse and coplanar"
        , rayTriangle (Ray (P3 0.25 0.25 1) (P3 0 0 (-1))) (P3 0 0 0, P3 1 0 0, P3 0 1 0) == Right (Just 1)
            && rayTriangle (Ray (P3 0 0 0) (P3 1 0 0)) (P3 0 0 0, P3 1 0 0, P3 0 1 0) == Right Nothing
        )
    ,
        ( "ray sphere tangent and interior"
        , raySphere (Ray (P3 (-2) 1 0) (P3 1 0 0)) (Sphere (P3 0 0 0) 1) == Right (Just (2, 2))
            && raySphere (Ray (P3 0 0 0) (P3 1 0 0)) (Sphere (P3 0 0 0) 1) == Right (Just (0, 1))
        )
    ,
        ( "ray slabs parallel on boundary"
        , rayBox (Ray (P3 (-1) 0 0) (P3 1 0 0)) (AABB (PointND [0, 0, 0]) (PointND [1, 1, 1]))
            == Right (Just (1, 2))
        )
    ,
        ( "circle tangent coincident separate"
        , circleIntersection (Circle (P2 0 0) 1) (Circle (P2 2 0) 1) == Right (CirclePoints [P2 1 0])
            && circleIntersection (Circle (P2 0 0) 1) (Circle (P2 0 0) 1) == Right CoincidentCircles
            && circleIntersection (Circle (P2 0 0) 1) (Circle (P2 3 0) 1) == Right DisjointCircles
        )
    ,
        ( "triangle triangle touch overlap"
        , right
            ((== 1) . length)
            (triangleIntersection (Triangle (P2 0 0) (P2 1 0) (P2 0 1)) (Triangle (P2 1 0) (P2 2 0) (P2 2 1)))
        )
    ,
        ( "sphere box capsule cylinder cone SDF"
        , nearR (-1) (sphereSDF (Sphere (P3 0 0 0) 1) (P3 0 0 0))
            && nearR (-1) (boxSDF (AABB (PointND [-1, -1]) (PointND [1, 1])) (PointND [0, 0]))
            && nearR 1 (capsuleSDF (Capsule (P3 0 0 0) (P3 0 0 2) 1) (P3 2 0 1))
            && nearR (-1) (cylinderSDF (Cylinder (P3 0 0 0) (P3 0 0 2) 1) (P3 0 0 1))
            && nearR 0 (coneSDF (Cone (P3 0 0 0) (P3 0 0 2) 1) (P3 0.5 0 1))
        )
    ,
        ( "oriented box SDF"
        , nearR 1 (obbSDF (OBB (P3 0 0 0) [P3 0 1 0, P3 (-1) 0 0, P3 0 0 1] (P3 1 2 3)) (P3 3 0 0))
        )
    ,
        ( "invalid primitives rejected"
        , isLeft (cylinderSDF (Cylinder (P3 0 0 0) (P3 0 0 0) 1) (P3 0 0 0))
            && isLeft (sphereSDF (Sphere (P3 0 0 0) (-1)) (P3 0 0 0))
            && isLeft (boxContains (AABB (PointND [1]) (PointND [0])) (PointND [0]))
        )
    ]

polygonTests :: [(String, Bool)]
polygonTests =
    [
        ( "shoelace centroid clockwise"
        , nearR (-4) (shoelace (Polygon (reverse (rect 0 0 2 2))))
            && right (nearP (P2 1 1)) (polygonCentroid (Polygon (rect 0 0 2 2)))
        )
    , ("self intersection rejected", isLeft (polygonArea (Polygon [P2 0 0, P2 2 2, P2 0 2, P2 2 0])))
    ,
        ( "Boolean contained difference has oriented hole"
        , right
            (\rings -> length rings == 2 && near (areaRings rings) 12)
            (polygonBoolean Difference (Polygon (rect 0 0 4 4)) (Polygon (rect 1 1 2 2)))
        )
    ,
        ( "Boolean coincident equal inputs"
        , right (near 4 . areaRings) (polygonBoolean Union (Polygon (rect 0 0 2 2)) (Polygon (rect 0 0 2 2)))
            && polygonBoolean Difference (Polygon (rect 0 0 2 2)) (Polygon (rect 0 0 2 2)) == Right []
        )
    ,
        ( "Boolean touching edges and vertices"
        , right (near 2 . areaRings) (polygonBoolean Union (Polygon (rect 0 0 1 1)) (Polygon (rect 1 0 1 1)))
            && right (near 2 . areaRings) (polygonBoolean Union (Polygon (rect 0 0 1 1)) (Polygon (rect 1 1 1 1)))
        )
    ,
        ( "convex clipping area"
        , right
            (\ring -> nearR 1 (polygonArea (Polygon ring)))
            (clipPolygon (Polygon (rect 0 0 2 2)) (Polygon (rect 1 1 2 2)))
        )
    ,
        ( "minimum bounding circle analytic"
        , right
            (\(Circle center radius) -> nearP center (P2 0 0) && near radius (sqrt 2))
            (minimumBoundingCircle [P2 (-1) (-1), P2 1 (-1), P2 1 1, P2 (-1) 1])
        )
    ,
        ( "minimum bounding collinear circle"
        , minimumBoundingCircle [P2 0 0, P2 1 0, P2 2 0] == Right (Circle (P2 1 0) 1)
        )
    ,
        ( "minimum rotated rectangle"
        , right
            (\ring -> nearR 4 (polygonArea (Polygon ring)))
            (minimumBoundingRectangle [P2 0 1, P2 1 0, P2 3 2, P2 2 3])
        )
    ,
        ( "convex Minkowski sum"
        , right (\ring -> nearR 9 (polygonArea (Polygon ring))) (minkowskiSum (rect 0 0 1 1) (rect 0 0 2 2))
        )
    ]
        ++ [ ( "four hull differential subset " ++ show i
             , let answers = [convexHull method ps | method <- [GrahamScan, MonotoneChain, Quickhull, GiftWrapping]]
                in not (null answers) && all (== firstAnswer answers) answers
             )
           | (i, ps) <- zip [0 :: Int ..] (subsequences [P2 x y | x <- [0, 1, 2], y <- [0, 1, 2]])
           ]
        ++ [ ( "polygon Boolean rectangle area " ++ show (x, y)
             , let a = Polygon (rect 0 0 2 2)
                   b = Polygon (rect x y 2 2)
                   overlap = max 0 (min 2 (x + 2) - max 0 x) * max 0 (min 2 (y + 2) - max 0 y)
                in right (near (8 - overlap) . areaRings) (polygonBoolean Union a b)
                    && right (near overlap . areaRings) (polygonBoolean Intersection a b)
                    && right (near (4 - overlap) . areaRings) (polygonBoolean Difference a b)
             )
           | x <- [-2, -1.5 .. 2]
           , y <- [-2, -1.5 .. 2]
           ]
  where
    firstAnswer [] = Right []; firstAnswer (x : _) = x

triangulationTests :: [(String, Bool)]
triangulationTests =
    [
        ( "Voronoi translated close-site bisector"
        , right
            ( \cells ->
                length cells == 2 && all (\ring -> nearR 5 (polygonArea (Polygon ring))) cells && case cells of
                    [a, b] -> maximum [x | P2 x _ <- a] == 1e15 + 0.5 && minimum [x | P2 x _ <- b] == 1e15 + 0.5
                    _ -> False
            )
            (voronoi (Rectangle (P2 (1e15 - 2) (-1)) (P2 (1e15 + 3) 1)) [P2 1e15 0, P2 (1e15 + 1) 0])
        )
    ,
        ( "Delaunay square area and empty circles"
        , let ps = rect 0 0 1 1
           in right
                ( \ts ->
                    length ts == 2
                        && near (sum (map (triArea ps) ts)) 1
                        && and
                            [ incircle (ps !! a) (ps !! b) (ps !! c) (ps !! i) /= Right GT
                            | (a, b, c) <- ts
                            , i <- [0 .. 3]
                            , i `notElem` [a, b, c]
                            ]
                )
                (delaunay ps)
        )
    ,
        ( "Delaunay collinear and duplicate"
        , delaunay [P2 0 0, P2 1 0, P2 2 0] == Right [] && isLeft (delaunay [P2 0 0, P2 0 0, P2 1 1])
        )
    ,
        ( "constrained Delaunay opposite square diagonal"
        , let ps = rect 0 0 1 1
           in right
                ( \ts ->
                    any (\(a, b, c) -> 0 `elem` [a, b, c] && 2 `elem` [a, b, c]) ts
                        && near (sum (map (triArea ps) ts)) 1
                )
                (constrainedDelaunay ps [(0, 2)])
        )
    , ("constrained crossing rejected", isLeft (constrainedDelaunay (rect 0 0 1 1) [(0, 2), (1, 3)]))
    ,
        ( "constrained interior vertex rejected"
        , isLeft (constrainedDelaunay [P2 0 0, P2 2 0, P2 1 0, P2 0 2] [(0, 1)])
        )
    ,
        ( "Voronoi clipped bisector"
        , right
            (\cells -> length cells == 2 && all (\ring -> nearR 2 (polygonArea (Polygon ring))) cells)
            (voronoi (Rectangle (P2 (-1) (-1)) (P2 1 1)) [P2 (-0.5) 0, P2 0.5 0])
        )
    ,
        ( "ear clipping concave area"
        , let ps = [P2 0 0, P2 2 0, P2 2 2, P2 1 1, P2 0 2]
           in right (\ts -> not (null ts) && near (sum (map (triArea ps) ts)) 3) (earClip (Polygon ps))
        )
    ,
        ( "ear clipping collinear boundary"
        , let ps = [P2 0 0, P2 1 0, P2 2 0, P2 2 1, P2 0 1]
           in right (\ts -> near (sum (map (triArea ps) ts)) 2) (earClip (Polygon ps))
        )
    ]
        ++ [ ( "Delaunay independent hull-area invariant " ++ show i
             , right
                ( \ts ->
                    right
                        (\h -> if length h < 3 then null ts else nearR (sum (map (triArea ps) ts)) (polygonArea (Polygon h)))
                        (convexHull GiftWrapping ps)
                )
                (delaunay ps)
             )
           | (i, ps) <-
                zip
                    [0 :: Int ..]
                    (take 128 (filter ((>= 3) . length) (subsequences [P2 x y | x <- [0, 1, 2], y <- [0, 1, 2]])))
           ]

spatialTests :: [(String, Bool)]
spatialTests =
    [ ( "spatial range nearest radius " ++ show kind
      , right
            ( \cloud ->
                right
                    ( \index ->
                        rangeQuery index (AABB (PointND [1, 1]) (PointND [2, 2])) == Right [6, 7, 11, 12]
                            && right
                                (\q -> queryExhaustive q && map fst (queryNeighbors q) == [0, 1, 5])
                                (nearestQuery 3 1000 index (PointND [0, 0]))
                            && radiusQuery index (PointND [0, 0]) 1 == Right [0, 1, 5]
                    )
                    (buildSpatialIndex kind cloud)
            )
            (pointCloud [PointND [x, y] | x <- [0 .. 4], y <- [0 .. 4]])
      )
    | kind <- [SpatialHash 0.7, KDTree, BallTree, Quadtree, RTree, BVH]
    ]
        ++ [
               ( "octree 3D exact range"
               , right
                    ( \cloud ->
                        right
                            ( \index ->
                                rangeQuery index (AABB (PointND [1, 1, 1]) (PointND [2, 2, 2]))
                                    == Right [13, 14, 16, 17, 22, 23, 25, 26]
                            )
                            (buildSpatialIndex Octree cloud)
                    )
                    (pointCloud [PointND [x, y, z] | x <- [0 .. 2], y <- [0 .. 2], z <- [0 .. 2]])
               )
           ,
               ( "spatial dimension rejects quad oct"
               , right (\cloud -> isLeft (buildSpatialIndex Octree cloud)) (pointCloud [PointND [0, 0]])
               )
           ,
               ( "spatial hash zero width rejects"
               , right (\cloud -> isLeft (buildSpatialIndex (SpatialHash 0) cloud)) (pointCloud [PointND [0]])
               )
           ,
               ( "spatial budget reports incomplete"
               , right
                    ( \cloud ->
                        right
                            (\index -> right (not . queryExhaustive) (nearestQuery 25 1 index (PointND [0, 0])))
                            (buildSpatialIndex KDTree cloud)
                    )
                    (pointCloud [PointND [x, y] | x <- [0 .. 4], y <- [0 .. 4]])
               )
           ,
               ( "spatial duplicate IDs retained"
               , right
                    ( \cloud ->
                        right
                            (\index -> rangeQuery index (AABB (PointND [0]) (PointND [0])) == Right [0 .. 19])
                            (buildSpatialIndex BVH cloud)
                    )
                    (pointCloud (replicate 20 (PointND [0])))
               )
           ]

transformTests :: [(String, Bool)]
transformTests =
    [
        ( "affine inverse round trip"
        , right
            ( \linear ->
                right
                    ( \m ->
                        right
                            ( \p -> right (\(PointND xs) -> nearV xs [2, 3]) (inverseTransform m >>= (\inv -> applyTransform inv p))
                            )
                            (applyTransform m (PointND [2, 3]))
                    )
                    (affineTransform linear (PointND [1, -2]))
            )
            (M.fromListChecked 2 2 [2, 1, 0, 3])
        )
    ,
        ( "look-at origin negative z"
        , right
            (\m -> right (\(PointND xs) -> nearV xs [0, 0, -3]) (applyTransform m (PointND [0, 0, 0])))
            (lookAt (P3 0 0 3) (P3 0 0 0) (P3 0 1 0))
        )
    , ("look-at rejects parallel up", isLeft (lookAt (P3 0 0 1) (P3 0 0 0) (P3 0 0 1)))
    ,
        ( "perspective depth endpoints"
        , right
            ( \m ->
                right (\(PointND xs) -> nearV xs [0, 0, -1]) (applyTransform m (PointND [0, 0, -1]))
                    && right (\(PointND xs) -> nearV xs [0, 0, 1]) (applyTransform m (PointND [0, 0, -10]))
                    && isLeft (applyTransform m (PointND [0, 0, 0]))
            )
            (perspective (pi / 2) 1 1 10)
        )
    ,
        ( "orthographic depth endpoints"
        , right
            ( \m ->
                right (\(PointND xs) -> nearV xs [-1, -1, -1]) (applyTransform m (PointND [-2, -3, -1]))
                    && right (\(PointND xs) -> nearV xs [1, 1, 1]) (applyTransform m (PointND [2, 3, -10]))
            )
            (orthographic (-2) 2 (-3) 3 1 10)
        )
    ,
        ( "frustum sphere and box culling"
        , right
            ( \frustum ->
                cullSphere frustum (Sphere (P3 0 0 (-3)) 0.5) == Right True
                    && cullSphere frustum (Sphere (P3 100 0 (-3)) 0.5) == Right False
                    && cullBox frustum (AABB (PointND [-0.5, -0.5, -4]) (PointND [0.5, 0.5, -2])) == Right True
            )
            (perspective (pi / 2) 1 1 10 >>= extractFrustum)
        )
    , ("inverse singular rejects", right (isLeft . inverseTransform) (M.fromListChecked 2 2 [0, 0, 0, 1]))
    ]

collisionTests :: [(String, Bool)]
collisionTests =
    [
        ( "GJK tiny separated squares"
        , all
            (\s -> gjk 100 (rect 0 0 s s) (rect 0 (1.1 * s) s s) == Right False)
            [1e-50, 1e-100, 1e-150, 1e-300]
        )
    ,
        ( "GJK point containment"
        , gjk 100 [P2 0 0] (rect (-1) (-1) 2 2) == Right True
            && gjk 100 [P2 3 0] (rect (-1) (-1) 2 2) == Right False
        )
    ,
        ( "EPA analytic overlap"
        , right
            ( \p -> case p of Just x -> near (penetrationDepth x) 1 && penetrationError x <= 1e-8; Nothing -> False
            )
            (epa 100 1e-9 (rect 0 0 2 2) (rect 1 0 2 2))
        )
    , ("EPA separation", epa 100 1e-9 (rect 0 0 1 1) (rect 2 0 1 1) == Right Nothing)
    ,
        ( "SAT containment translation depth"
        , right
            (\p -> case p of Just x -> near (penetrationDepth x) 3; _ -> False)
            (separatingAxis (rect (-2) (-2) 4 4) (rect (-1) (-1) 2 2))
        )
    ,
        ( "collision invalid budgets"
        , isLeft (gjk 0 (rect 0 0 1 1) (rect 0 0 1 1)) && isLeft (epa 10 0 (rect 0 0 1 1) (rect 0 0 1 1))
        )
    ]
        ++ [ ( "GJK SAT analytic rectangle agreement " ++ show (x, y)
             , let a = rect 0 0 1 1; b = rect x y 1 1; expected = x <= 1 && x + 1 >= 0 && y <= 1 && y + 1 >= 0
                in gjk 100 a b == Right expected
                    && right (\p -> maybe False (const True) p == expected) (separatingAxis a b)
             )
           | x <- [-2, -1.5 .. 2]
           , y <- [-2, -1.5 .. 2]
           ]
