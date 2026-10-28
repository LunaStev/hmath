-- SPDX-License-Identifier: MPL-2.0

{- | Finite Hamilton quaternions in scalar-first @(w,x,y,z)@ order. Rotations
are active, right-handed, column-vector rotations in radians. Product @a*b@
applies @b@ first. Euler angles are intrinsic ZYX (yaw, pitch, roll), returned
as @(roll,pitch,yaw)@ with pitch in [-pi/2,pi/2]. At gimbal lock roll is zero.
Unit quaternions differing by sign represent the same rotation. Interpolation
chooses the shortest sign-equivalent arc; SQUAD tangents use quaternion logs.
-}
module HMath.Quaternion (
    Quaternion,
    quaternion,
    components,
    norm,
    normalize,
    inverse,
    conjugate,
    multiply,
    add,
    scale,
    rotateVector,
    axisAngle,
    toAxisAngle,
    fromEuler,
    toEuler,
    toMatrix,
    fromMatrix,
    nlerp,
    slerp,
    squad,
    exponential,
    logarithm,
    swingTwist,
) where

import HMath.Error (MathError (..))
import qualified HMath.Matrix as M

-- | A finite scalar-first Hamilton quaternion. Construction is checked.
data Quaternion = Q Double Double Double Double deriving (Eq, Show)

finite :: Double -> Bool
finite a = not (isNaN a || isInfinite a)
check :: Quaternion -> Either MathError Quaternion
check q = if all finite (components q) then Right q else Left NonFiniteResult

-- | Finite scalar-first constructor.
quaternion :: Double -> Double -> Double -> Double -> Either MathError Quaternion
quaternion w x y z = check (Q w x y z)

-- | Scalar, x, y, z components.
components :: Quaternion -> [Double]
components (Q w x y z) = [w, x, y, z]

-- | Scaled Euclidean norm (may overflow only when the true norm is unrepresentable).
norm :: Quaternion -> Double
norm q =
    let xs = components q; s = maximum (map abs xs)
     in if s == 0 then 0 else s * sqrt (sum [(x / s) ^ (2 :: Int) | x <- xs])

-- | Normalize without forming a squared norm; zero has no normalization.
normalize :: Quaternion -> Either MathError Quaternion
normalize q =
    let s = maximum (map abs (components q))
     in if s == 0
            then Left (DomainError "zero quaternion norm")
            else
                let Q a b c e = q
                    w = a / s
                    x = b / s
                    y = c / s
                    z = e / s
                    d = sqrt (w * w + x * x + y * y + z * z)
                 in check (Q (w / d) (x / d) (y / d) (z / d))

-- | Quaternion conjugation.
conjugate :: Quaternion -> Quaternion
conjugate (Q w x y z) = Q w (-x) (-y) (-z)

-- | Multiplicative inverse; uses component scaling to avoid norm overflow.
inverse :: Quaternion -> Either MathError Quaternion
inverse q = do
    u <- normalize q
    let s = maximum (map abs (components q))
        d = sqrt (sum [(x / s) ^ (2 :: Int) | x <- components q])
    let Q w x y z = conjugate u
    check (Q ((w / d) / s) ((x / d) / s) ((y / d) / s) ((z / d) / s))

rawScale :: Double -> Quaternion -> Quaternion
rawScale a (Q w x y z) = Q (a * w) (a * x) (a * y) (a * z)
rawAdd :: Quaternion -> Quaternion -> Quaternion
rawAdd (Q a b c d) (Q w x y z) = Q (a + w) (b + x) (c + y) (d + z)
rawMul :: Quaternion -> Quaternion -> Quaternion
rawMul (Q a b c d) (Q w x y z) =
    Q
        (a * w - b * x - c * y - d * z)
        (a * x + b * w + c * z - d * y)
        (a * y - b * z + c * w + d * x)
        (a * z + b * y - c * x + d * w)

-- | Hamilton product.
multiply :: Quaternion -> Quaternion -> Either MathError Quaternion
multiply a b = check (rawMul a b)

-- | Component sum.
add :: Quaternion -> Quaternion -> Either MathError Quaternion
add a b = check (rawAdd a b)

-- | Checked real scaling.
scale :: Double -> Quaternion -> Either MathError Quaternion
scale a q = if finite a then check (rawScale a q) else Left (DomainError "nonfinite quaternion scale")

-- | Rotate a finite three-vector; any nonzero quaternion is normalized first.
rotateVector :: Quaternion -> [Double] -> Either MathError [Double]
rotateVector q v = do
    u <- normalize q
    case v of
        [x, y, z] | all finite v -> case rawMul (rawMul u (Q 0 x y z)) (conjugate u) of
            Q _ a b c -> if all finite [a, b, c] then Right [a, b, c] else Left NonFiniteResult
        _ -> Left (InvalidArgument "rotation requires a finite three-vector")

-- | Axis-angle conversion. The axis must be nonzero even for a zero angle.
axisAngle :: [Double] -> Double -> Either MathError Quaternion
axisAngle axis angle = case axis of
    [x, y, z] | all finite axis && finite angle -> do
        Q _ a b c <- normalize (Q 0 x y z)
        check (Q (cos (angle / 2)) (a * sin (angle / 2)) (b * sin (angle / 2)) (c * sin (angle / 2)))
    _ -> Left (InvalidArgument "invalid axis-angle")

canonical :: Quaternion -> Quaternion
canonical q@(Q w x y z) = if w < 0 || (w == 0 && [x, y, z] < [0, 0, 0]) then rawScale (-1) q else q

-- | Principal rotation angle in [0,pi]; identity uses the x axis.
toAxisAngle :: Quaternion -> Either MathError ([Double], Double)
toAxisAngle q = do
    Q w x y z <- canonical <$> normalize q
    let s = sqrt (x * x + y * y + z * z)
    Right (if s < 1e-15 then ([1, 0, 0], 0) else ([x / s, y / s, z / s], 2 * atan2 s w))

-- | Intrinsic ZYX rotation from @(roll,pitch,yaw)@.
fromEuler :: Double -> Double -> Double -> Either MathError Quaternion
fromEuler roll pitch yaw
    | not (all finite [roll, pitch, yaw]) = Left (DomainError "nonfinite Euler angle")
    | otherwise =
        let cr = cos (roll / 2)
            sr = sin (roll / 2)
            cp = cos (pitch / 2)
            sp = sin (pitch / 2)
            cy = cos (yaw / 2)
            sy = sin (yaw / 2)
         in normalize
                ( Q
                    (cr * cp * cy + sr * sp * sy)
                    (sr * cp * cy - cr * sp * sy)
                    (cr * sp * cy + sr * cp * sy)
                    (cr * cp * sy - sr * sp * cy)
                )

-- | Intrinsic ZYX angles, choosing roll zero at gimbal lock.
toEuler :: Quaternion -> Either MathError (Double, Double, Double)
toEuler q = do
    m <- toMatrix q
    let a = M.toList m
        s = max (-1) (min 1 (-(a !! 6)))
        cp = sqrt ((a !! 0) ^ (2 :: Int) + (a !! 3) ^ (2 :: Int))
        pitch = atan2 s cp
    Right $
        if cp < 1e-12
            then (0, if s >= 0 then pi / 2 else -pi / 2, atan2 (-(a !! 1)) (a !! 4))
            else (atan2 (a !! 7) (a !! 8), pitch, atan2 (a !! 3) (a !! 0))

-- | Active rotation as a row-major 3x3 matrix.
toMatrix :: Quaternion -> Either MathError (M.Matrix Double)
toMatrix q = do
    Q w x y z <- normalize q
    M.fromListChecked
        3
        3
        [ 1 - 2 * (y * y + z * z)
        , 2 * (x * y - z * w)
        , 2 * (x * z + y * w)
        , 2 * (x * y + z * w)
        , 1 - 2 * (x * x + z * z)
        , 2 * (y * z - x * w)
        , 2 * (x * z - y * w)
        , 2 * (y * z + x * w)
        , 1 - 2 * (x * x + y * y)
        ]

-- | Validate SO(3) within 1e-9, then use the largest-diagonal conversion near pi.
fromMatrix :: M.Matrix Double -> Either MathError Quaternion
fromMatrix matrix
    | M.shape matrix /= (3, 3) = Left (InvalidArgument "rotation matrix must be 3x3")
    | not (all finite a) = Left (DomainError "nonfinite rotation matrix")
    | maximum (map abs orth) > 1e-9 || abs (det - 1) > 1e-9 = Left (DomainError "matrix is not SO(3)")
    | otherwise =
        normalize $
            if tr > 0
                then
                    let s = 2 * sqrt (tr + 1)
                     in Q (s / 4) ((a !! 7 - a !! 5) / s) ((a !! 2 - a !! 6) / s) ((a !! 3 - a !! 1) / s)
                else
                    if a !! 0 >= a !! 4 && a !! 0 >= a !! 8
                        then
                            let s = 2 * sqrt (1 + a !! 0 - a !! 4 - a !! 8)
                             in Q ((a !! 7 - a !! 5) / s) (s / 4) ((a !! 1 + a !! 3) / s) ((a !! 2 + a !! 6) / s)
                        else
                            if a !! 4 >= a !! 8
                                then
                                    let s = 2 * sqrt (1 + a !! 4 - a !! 0 - a !! 8)
                                     in Q ((a !! 2 - a !! 6) / s) ((a !! 1 + a !! 3) / s) (s / 4) ((a !! 5 + a !! 7) / s)
                                else
                                    let s = 2 * sqrt (1 + a !! 8 - a !! 0 - a !! 4)
                                     in Q ((a !! 3 - a !! 1) / s) ((a !! 2 + a !! 6) / s) ((a !! 5 + a !! 7) / s) (s / 4)
  where
    a = M.toList matrix
    tr = a !! 0 + a !! 4 + a !! 8
    orth =
        [ sum [a !! (3 * k + i) * a !! (3 * k + j) | k <- [0 .. 2]] - if i == j then 1 else 0
        | i <- [0 .. 2]
        , j <- [0 .. 2]
        ]
    det =
        a !! 0 * (a !! 4 * a !! 8 - a !! 5 * a !! 7)
            - a !! 1 * (a !! 3 * a !! 8 - a !! 5 * a !! 6)
            + a !! 2 * (a !! 3 * a !! 7 - a !! 4 * a !! 6)

shortPair :: Quaternion -> Quaternion -> Either MathError (Quaternion, Quaternion, Double)
shortPair a b = do
    u <- normalize a
    v <- normalize b
    let d = sum (zipWith (*) (components u) (components v)); w = if d < 0 then rawScale (-1) v else v
    Right (u, w, min 1 (abs d))
interpolation :: Double -> Either MathError ()
interpolation t =
    if finite t && t >= 0 && t <= 1
        then Right ()
        else Left (DomainError "interpolation parameter outside [0,1]")

-- | Shortest-arc normalized linear interpolation on [0,1].
nlerp :: Double -> Quaternion -> Quaternion -> Either MathError Quaternion
nlerp t a b = do
    interpolation t
    (u, v, _) <- shortPair a b
    normalize (rawAdd (rawScale (1 - t) u) (rawScale t v))

-- | Shortest-arc spherical interpolation, with stable NLERP near equal rotations.
slerp :: Double -> Quaternion -> Quaternion -> Either MathError Quaternion
slerp t a b = do
    interpolation t
    (u, v, d) <- shortPair a b
    if d > 1 - 1e-10
        then nlerp t u v
        else
            let theta = acos d; s = sin theta
             in normalize (rawAdd (rawScale (sin ((1 - t) * theta) / s) u) (rawScale (sin (t * theta) / s) v))

-- | General quaternion exponential; sinc expansion stabilizes a tiny vector part.
exponential :: Quaternion -> Either MathError Quaternion
exponential (Q w x y z) =
    let v = norm (Q 0 x y z); s = if v < 1e-8 then 1 - v * v / 6 else sin v / v
     in check (rawScale (exp w) (Q (cos v) (s * x) (s * y) (s * z)))

-- | Principal quaternion logarithm; the negative real axis chooses positive x.
logarithm :: Quaternion -> Either MathError Quaternion
logarithm q@(Q w _ _ _) = do
    u <- normalize q
    let Q a b c d = u
        s = norm (Q 0 b c d)
        size = maximum (map abs (components q))
        logNorm = log size + log (sqrt (sum [(v / size) ^ (2 :: Int) | v <- components q]))
    check $
        if s == 0
            then Q logNorm (if w < 0 then pi else 0) 0 0
            else let angle = atan2 s a in Q logNorm (b / s * angle) (c / s * angle) (d / s * angle)

-- | Shoemake SQUAD through q1 to q2 using neighboring q0 and q3.
squad ::
    Double -> Quaternion -> Quaternion -> Quaternion -> Quaternion -> Either MathError Quaternion
squad t q0 q1 q2 q3 = do
    interpolation t
    (_, a, _) <- shortPair q1 q0
    (b, c, _) <- shortPair q1 q2
    (_, d, _) <- shortPair c q3
    s1 <- tangent b a c
    s2 <- tangent c b d
    p <- slerp t b c
    q <- slerp t s1 s2
    slerp (2 * t * (1 - t)) p q
  where
    tangent q before after = do
        l <- logarithm (rawMul (conjugate q) before)
        r <- logarithm (rawMul (conjugate q) after)
        e <- exponential (rawScale (-0.25) (rawAdd l r))
        normalize (rawMul q e)

{- | Decompose q = swing * twist around a nonzero axis. A pi swing with zero
twist projection uses identity twist, a deterministic singular convention.
-}
swingTwist :: [Double] -> Quaternion -> Either MathError (Quaternion, Quaternion)
swingTwist axis q = do
    Q _ ax ay az <- case axis of
        [a, b, c] | all finite axis -> normalize (Q 0 a b c)
        _ -> Left (InvalidArgument "twist axis must be a finite three-vector")
    u@(Q w x y z) <- normalize q
    let d = ax * x + ay * y + az * z; candidate = Q w (d * ax) (d * ay) (d * az)
    twist <- if norm candidate < 1e-14 then Right (Q 1 0 0 0) else normalize candidate
    swing <- normalize (rawMul u (conjugate twist))
    Right (swing, twist)
