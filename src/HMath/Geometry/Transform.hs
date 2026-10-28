-- SPDX-License-Identifier: MPL-2.0

{- | Column-vector homogeneous transforms. The 3D camera convention is
right-handed, looks along negative camera z, and maps the visible depth range
to OpenGL NDC [-1,1]. Positive y points up. Composition a*b applies b first.
Affine ND transforms accept dimensions 1..16; projective 3D transforms reject
points at infinity. Frustum normals point inward and culling retains tangency.
-}
module HMath.Geometry.Transform (
    affineTransform,
    applyTransform,
    composeTransforms,
    inverseTransform,
    perspective,
    orthographic,
    lookAt,
    extractFrustum,
    cullSphere,
    cullBox,
) where

import Data.List (maximumBy)
import Data.Ord (comparing)
import HMath.Error (MathError (..))
import HMath.Geometry.Internal
import qualified HMath.Matrix as M

validate :: M.Matrix Double -> Either MathError Int
validate matrix =
    let (r, c) = M.shape matrix
     in require
            (r == c && r >= 2 && r <= 17 && all coord (M.toList matrix))
            "transform must be finite square 2..17"
            >> Right (r - 1)

-- | Construct an affine matrix [linear,translation;0,1].
affineTransform :: M.Matrix Double -> PointND -> Either MathError (M.Matrix Double)
affineTransform linear translation = do
    checkND translation
    let d = length (coordsND translation)
    require (M.shape linear == (d, d) && all coord (M.toList linear)) "invalid affine linear part"
    M.fromListChecked
        (d + 1)
        (d + 1)
        ( concat [take d (drop (i * d) (M.toList linear)) ++ [coordsND translation !! i] | i <- [0 .. d - 1]]
            ++ replicate d 0
            ++ [1]
        )

-- | Apply an affine or projective matrix and divide by homogeneous w.
applyTransform :: M.Matrix Double -> PointND -> Either MathError PointND
applyTransform matrix p = do
    d <- validate matrix
    checkND p
    require (length (coordsND p) == d) "transform dimension mismatch"
    let input = coordsND p ++ [1]
        a = M.toList matrix
        raw = [dot (take (d + 1) (drop (i * (d + 1)) a)) input | i <- [0 .. d]]
        w = last raw
    require (w /= 0 && finite w) "projective point lies at infinity"
    pointND (map (/ w) (take d raw))

-- | Checked matrix composition; projective and affine matrices may be mixed.
composeTransforms :: M.Matrix Double -> M.Matrix Double -> Either MathError (M.Matrix Double)
composeTransforms a b = do
    da <- validate a
    db <- validate b
    require (da == db) "transform dimensions differ"
    out <- M.multiplyChecked a b
    _ <- validate out
    Right out

-- | Gauss-Jordan inverse with partial pivoting, bounded to matrices of size 17.
inverseTransform :: M.Matrix Double -> Either MathError (M.Matrix Double)
inverseTransform matrix = do
    d <- validate matrix
    let n = d + 1
        a = M.toList matrix
        rows = [take n (drop (i * n) a) ++ [if i == j then 1 else 0 | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]
    out <- eliminate n rows 0
    result <- M.fromListChecked n n (concatMap (drop n) out)
    _ <- validate result
    Right result
  where
    eliminate n rows col
        | col == n = Right rows
        | otherwise =
            let pivot = maximumBy (comparing (\i -> abs (rows !! i !! col))) [col .. n - 1]
                exchanged =
                    [ if i == col then rows !! pivot else if i == pivot then rows !! col else rows !! i
                    | i <- [0 .. n - 1]
                    ]
                value = exchanged !! col !! col
             in if value == 0
                    then Left (SingularMatrix col)
                    else
                        let prow = map (/ value) (exchanged !! col)
                            output =
                                [ if i == col then prow else zipWith (-) (exchanged !! i) (scale (exchanged !! i !! col) prow)
                                | i <- [0 .. n - 1]
                                ]
                         in if all finite (concat output) then eliminate n output (col + 1) else Left NonFiniteResult

-- | Vertical field of view in (0,pi), positive aspect, 0<near<far.
perspective :: Double -> Double -> Double -> Double -> Either MathError (M.Matrix Double)
perspective fov aspect near far = do
    require
        (all coord [fov, aspect, near, far] && fov > 0 && fov < pi && aspect > 0 && near > 0 && far > near)
        "invalid perspective parameters"
    let f = 1 / tan (fov / 2)
    out <-
        M.fromListChecked
            4
            4
            [ f / aspect
            , 0
            , 0
            , 0
            , 0
            , f
            , 0
            , 0
            , 0
            , 0
            , (far + near) / (near - far)
            , 2 * far * near / (near - far)
            , 0
            , 0
            , -1
            , 0
            ]
    _ <- validate out
    Right out

-- | Orthographic bounds with left<right, bottom<top and 0<=near<far.
orthographic ::
    Double -> Double -> Double -> Double -> Double -> Double -> Either MathError (M.Matrix Double)
orthographic left right bottom top near far = do
    require
        ( all coord [left, right, bottom, top, near, far]
            && left < right
            && bottom < top
            && near >= 0
            && near < far
        )
        "invalid orthographic parameters"
    M.fromListChecked
        4
        4
        [ 2 / (right - left)
        , 0
        , 0
        , -(right + left) / (right - left)
        , 0
        , 2 / (top - bottom)
        , 0
        , -(top + bottom) / (top - bottom)
        , 0
        , 0
        , -2 / (far - near)
        , -(far + near) / (far - near)
        , 0
        , 0
        , 0
        , 1
        ]
        >>= (\m -> validate m >> Right m)

-- | World-to-camera transform from eye, target and nonparallel up direction.
lookAt :: Point3 -> Point3 -> Point3 -> Either MathError (M.Matrix Double)
lookAt eye target up = do
    mapM_ check3 [eye, target, up]
    let forward = sub (coords3 target) (coords3 eye); fNorm = norm forward
    require (fNorm > 0) "look-at eye equals target"
    let f = map (/ fNorm) forward; sRaw = coords3 (cross (from3 f) up); sNorm = norm sRaw
    require (sNorm > 0) "look-at up is parallel to view direction"
    let s = map (/ sNorm) sRaw; u = coords3 (cross (from3 s) (from3 f)); e = coords3 eye
    M.fromListChecked
        4
        4
        (s ++ [-dot s e] ++ u ++ [-dot u e] ++ map negate f ++ [dot f e] ++ [0, 0, 0, 1])

{- | Extract six inward clipping planes from projection*view. Plane normals
are normalized so signed plane values are distances in world coordinates.
-}
extractFrustum :: M.Matrix Double -> Either MathError Frustum
extractFrustum matrix = do
    d <- validate matrix
    require (d == 3) "frustum matrix must be 4x4"
    let rows = [take 4 (drop (4 * i) (M.toList matrix)) | i <- [0 .. 3]]
    planes <-
        mapM make [zipWith (\a b -> a + sign * b) (rows !! 3) (rows !! i) | i <- [0 .. 2], sign <- [1, -1]]
    Right (Frustum planes)
  where
    make [a, b, c, h] =
        let n = sqrt (a * a + b * b + c * c)
         in require (n > 0 && finite n) "degenerate frustum plane"
                >> Right (Plane (P3 (a / n) (b / n) (c / n)) (-h / n))
    make _ = Left (InvalidArgument "frustum plane length")

checkFrustum :: Frustum -> Either MathError [Plane]
checkFrustum (Frustum planes) = do
    require (length planes == 6) "frustum requires six planes"
    mapM_
        (\(Plane n h) -> check3 n >> require (coord h && norm (coords3 n) > 0) "invalid frustum plane")
        planes
    Right planes

-- | True means the closed sphere may be visible (conservative plane culling).
cullSphere :: Frustum -> Sphere -> Either MathError Bool
cullSphere frustum (Sphere center radius) = do
    planes <- checkFrustum frustum
    check3 center
    require (coord radius && radius >= 0) "invalid culling sphere"
    Right
        (all (\(Plane n h) -> dot (coords3 n) (coords3 center) - h >= -radius * norm (coords3 n)) planes)

-- | True means the closed 3D AABB may be visible; corners need not be allocated.
cullBox :: Frustum -> AABB -> Either MathError Bool
cullBox frustum (AABB lo hi) = do
    planes <- checkFrustum frustum
    checkPair lo hi
    require
        (length (coordsND lo) == 3 && and (zipWith (<=) (coordsND lo) (coordsND hi)))
        "invalid culling box"
    Right
        ( all
            ( \(Plane n h) ->
                dot
                    (coords3 n)
                    (zipWith3 (\v a b -> if v >= 0 then b else a) (coords3 n) (coordsND lo) (coordsND hi))
                    >= h
            )
            planes
        )
