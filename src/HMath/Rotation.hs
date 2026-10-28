-- SPDX-License-Identifier: MPL-2.0

{- | SO(3), SE(3), and rigid dual quaternions. Active right-handed transforms
act on column vectors; @compose a b@ applies b first. Translation shares the
coordinate unit of points, angles are radians, and twists are @(omega,v)@.
SO(3) logs choose angles in [0,pi]; pi-axis sign is the quaternion convention.
SE(3) exp/log use the SO(3) left Jacobian, with series near identity. Dual
quaternion interpolation is screw-linear ScLERP through SE(3), including the
pure-translation limit. These APIs model rigid transforms, not scale/shear.
-}
module HMath.Rotation (
    SO3,
    so3,
    rotationQuaternion,
    identityRotation,
    composeRotation,
    inverseRotation,
    rotate,
    expSO3,
    logSO3,
    SE3,
    se3,
    rotationPart,
    translationPart,
    identityTransform,
    compose,
    inverse,
    transformPoint,
    expSE3,
    logSE3,
    toHomogeneous,
    fromHomogeneous,
    DualQuaternion,
    dualQuaternion,
    dualParts,
    toDualQuaternion,
    fromDualQuaternion,
    multiplyDual,
    inverseDual,
    interpolateDual,
) where

import HMath.Error (MathError (..))
import qualified HMath.Matrix as M
import qualified HMath.Quaternion as Q

-- | Normalized representative of SO(3).
newtype SO3 = SO3 Q.Quaternion deriving (Eq, Show)

-- | Rigid transformation x -> R*x+t.
data SE3 = SE3 SO3 [Double] deriving (Eq, Show)

-- | Unit real part and Study-orthogonal dual part.
data DualQuaternion = DQ Q.Quaternion Q.Quaternion deriving (Eq, Show)

finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)
vector :: [Double] -> Either MathError ()
vector xs =
    if length xs == 3 && all finite xs
        then Right ()
        else Left (InvalidArgument "expected finite three-vector")
checkV :: [Double] -> Either MathError [Double]
checkV xs = if all finite xs then Right xs else Left NonFiniteResult
qFrom :: [Double] -> Either MathError Q.Quaternion
qFrom [w, x, y, z] = Q.quaternion w x y z
qFrom _ = Left (InvalidArgument "quaternion component count")

-- | Normalize a nonzero quaternion into SO(3).
so3 :: Q.Quaternion -> Either MathError SO3
so3 = fmap SO3 . Q.normalize

-- | Underlying unit Hamilton quaternion.
rotationQuaternion :: SO3 -> Q.Quaternion
rotationQuaternion (SO3 q) = q

-- | Identity rotation.
identityRotation :: SO3
identityRotation = SO3 one

one :: Q.Quaternion
one = case Q.quaternion 1 0 0 0 of Right q -> q; Left _ -> error "finite quaternion constant"
zero :: Q.Quaternion
zero = case Q.quaternion 0 0 0 0 of Right q -> q; Left _ -> error "finite quaternion constant"

-- | Composition applying the right rotation first.
composeRotation :: SO3 -> SO3 -> Either MathError SO3
composeRotation (SO3 a) (SO3 b) = Q.multiply a b >>= so3

-- | Inverse of a unit rotation.
inverseRotation :: SO3 -> SO3
inverseRotation (SO3 q) = SO3 (Q.conjugate q)

-- | Apply a rotation to a finite three-vector.
rotate :: SO3 -> [Double] -> Either MathError [Double]
rotate (SO3 q) = Q.rotateVector q

norm3 :: [Double] -> Double
norm3 xs =
    let s = maximum (map abs xs)
     in if s == 0 then 0 else s * sqrt (sum [(x / s) ^ (2 :: Int) | x <- xs])
cross :: [Double] -> [Double] -> [Double]
cross [a, b, c] [x, y, z] = [b * z - c * y, c * x - a * z, a * y - b * x]
cross _ _ = [0, 0, 0]

-- | Exponential of a rotation vector; vector norm is the angle in radians.
expSO3 :: [Double] -> Either MathError SO3
expSO3 omega = do
    vector omega
    let theta = norm3 omega
    if not (finite theta)
        then Left NonFiniteResult
        else
            if theta == 0 then Right identityRotation else Q.axisAngle (map (/ theta) omega) theta >>= so3

-- | Principal logarithm as a rotation vector.
logSO3 :: SO3 -> Either MathError [Double]
logSO3 (SO3 q) = do
    (axis, angle) <- Q.toAxisAngle q
    checkV (map (* angle) axis)

-- | Construct a rigid transform from a rotation and finite translation.
se3 :: SO3 -> [Double] -> Either MathError SE3
se3 r t = vector t >> Right (SE3 r t)

-- | Rotation component.
rotationPart :: SE3 -> SO3
rotationPart (SE3 r _) = r

-- | Translation component.
translationPart :: SE3 -> [Double]
translationPart (SE3 _ t) = t

-- | Identity rigid transform.
identityTransform :: SE3
identityTransform = SE3 identityRotation [0, 0, 0]

-- | Compose transforms; b acts first.
compose :: SE3 -> SE3 -> Either MathError SE3
compose (SE3 a x) (SE3 b y) = do
    r <- composeRotation a b
    y' <- rotate a y
    t <- checkV (zipWith (+) x y')
    se3 r t

-- | Inverse rigid transform.
inverse :: SE3 -> Either MathError SE3
inverse (SE3 r t) = let ri = inverseRotation r in rotate ri (map negate t) >>= se3 ri

-- | Apply a rigid transform.
transformPoint :: SE3 -> [Double] -> Either MathError [Double]
transformPoint (SE3 r t) x = rotate r x >>= checkV . zipWith (+) t

-- | SE(3) exponential. The translational twist v is integrated by J(omega).
expSE3 :: ([Double], [Double]) -> Either MathError SE3
expSE3 (omega, v) = do
    vector omega
    vector v
    r <- expSO3 omega
    let theta = norm3 omega
        t2 = theta * theta
        a = if theta < 1e-4 then 0.5 - t2 / 24 + t2 * t2 / 720 else (1 - cos theta) / t2
        b = if theta < 1e-4 then 1 / 6 - t2 / 120 + t2 * t2 / 5040 else (theta - sin theta) / (t2 * theta)
        wv = cross omega v
        wwv = cross omega wv
    t <- checkV (zipWith3 (\x y z -> x + a * y + b * z) v wv wwv)
    se3 r t

-- | Principal SE(3) logarithm, stable at identity and at rotations near pi.
logSE3 :: SE3 -> Either MathError ([Double], [Double])
logSE3 (SE3 r t) = do
    omega <- logSO3 r
    let theta = norm3 omega
        t2 = theta * theta
        a =
            if theta < 1e-4
                then 1 / 12 + t2 / 720 + t2 * t2 / 30240
                else (1 - theta / 2 * cos (theta / 2) / sin (theta / 2)) / t2
        wt = cross omega t
        wwt = cross omega wt
    v <- checkV (zipWith3 (\x y z -> x - y / 2 + a * z) t wt wwt)
    Right (omega, v)

-- | Row-major homogeneous 4x4 matrix, bottom row [0,0,0,1].
toHomogeneous :: SE3 -> Either MathError (M.Matrix Double)
toHomogeneous (SE3 (SO3 q) t) = do
    r <- M.toList <$> Q.toMatrix q
    M.fromListChecked 4 4 (concat [take 3 (drop (3 * i) r) ++ [t !! i] | i <- [0 .. 2]] ++ [0, 0, 0, 1])

-- | Validate a homogeneous rigid matrix (bottom row tolerance 1e-12, rotation 1e-9).
fromHomogeneous :: M.Matrix Double -> Either MathError SE3
fromHomogeneous m
    | M.shape m /= (4, 4) = Left (InvalidArgument "rigid matrix must be 4x4")
    | not (all finite a) || maximum (map abs (zipWith (-) (drop 12 a) [0, 0, 0, 1])) > 1e-12 =
        Left (DomainError "invalid homogeneous bottom row")
    | otherwise = do
        r <-
            M.fromListChecked 3 3 [a !! (4 * i + j) | i <- [0 .. 2], j <- [0 .. 2]] >>= Q.fromMatrix >>= so3
        se3 r [a !! 3, a !! 7, a !! 11]
  where
    a = M.toList m

{- | Construct a rigid dual quaternion. Real norm must be nonzero; both parts
are scaled together and the Study dot-product condition checked at 1e-9.
-}
dualQuaternion :: Q.Quaternion -> Q.Quaternion -> Either MathError DualQuaternion
dualQuaternion real dual = do
    unit <- Q.normalize real
    let n = Q.norm real
    if not (finite n)
        then Left (DomainError "dual quaternion norm is unrepresentable")
        else do
            d <- qFrom (map (/ n) (Q.components dual))
            if abs (sum (zipWith (*) (Q.components unit) (Q.components d))) > 1e-9
                then Left (DomainError "dual quaternion violates Study condition")
                else Right (DQ unit d)

-- | Real and dual Hamilton parts.
dualParts :: DualQuaternion -> (Q.Quaternion, Q.Quaternion)
dualParts (DQ r d) = (r, d)

-- | Encode translation as 0.5*(0,t)*r.
toDualQuaternion :: SE3 -> Either MathError DualQuaternion
toDualQuaternion (SE3 (SO3 r) [x, y, z]) = do
    t <- Q.quaternion 0 x y z
    d <- Q.multiply t r >>= Q.scale 0.5
    Right (DQ r d)
toDualQuaternion _ = Right (DQ one zero)

-- | Decode translation from 2*d*conjugate(r).
fromDualQuaternion :: DualQuaternion -> Either MathError SE3
fromDualQuaternion (DQ r d) = do
    t <- Q.multiply d (Q.conjugate r) >>= Q.scale 2
    se3 (SO3 r) (drop 1 (Q.components t))

-- | Rigid dual-quaternion product.
multiplyDual :: DualQuaternion -> DualQuaternion -> Either MathError DualQuaternion
multiplyDual (DQ ar ad) (DQ br bd) = do
    r <- Q.multiply ar br
    a <- Q.multiply ar bd
    b <- Q.multiply ad br
    d <- Q.add a b
    dualQuaternion r d

-- | Inverse rigid dual quaternion.
inverseDual :: DualQuaternion -> Either MathError DualQuaternion
inverseDual d = fromDualQuaternion d >>= inverse >>= toDualQuaternion

-- | Shortest-rotation screw-linear interpolation on [0,1].
interpolateDual :: Double -> DualQuaternion -> DualQuaternion -> Either MathError DualQuaternion
interpolateDual t a b
    | not (finite t) || t < 0 || t > 1 = Left (DomainError "dual interpolation outside [0,1]")
    | otherwise = do
        x <- fromDualQuaternion a
        y <- fromDualQuaternion b
        xi <- inverse x
        relative <- compose xi y
        (w, v) <- logSE3 relative
        step <- expSE3 (map (* t) w, map (* t) v)
        compose x step >>= toDualQuaternion
