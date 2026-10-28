-- SPDX-License-Identifier: MPL-2.0

{- | Bounded two-dimensional convex collision reference algorithms. Inputs
are finite point sets whose convex hulls are the shapes. GJK uses support
mapping and simplex reduction; EPA expands a support polytope for penetration;
SAT tests every polygon edge normal. Touching counts as collision. Caller
iteration budgets prevent unbounded work; EPA reports an estimated support-gap
error, not a formal floating-point error bound. Curved 3D primitives have
separate exact signed-distance APIs.
-}
module HMath.Geometry.Collision (
    gjk,
    Penetration (..),
    epa,
    separatingAxis,
) where

import Data.List (minimumBy, nub)
import Data.Ord (comparing)
import HMath.Error (MathError (..))
import HMath.Geometry.Internal
import HMath.Geometry.Polygon (HullAlgorithm (..), convexHull)

validate :: [Point2] -> [Point2] -> Either MathError ()
validate a b =
    require
        (not (null a || null b) && length a <= 256 && length b <= 256)
        "convex collision requires 1..256 points per operand"
        >> mapM_ check2 (a ++ b)
support :: [Point2] -> [Point2] -> Point2 -> Point2
support a b direction = sub2 (extreme a direction) (extreme b (scale2 (-1) direction))
  where
    extreme ps d = foldl1 (\x y -> if dot2 y d > dot2 x d then y else x) ps

-- Rational support and simplex signs prevent thin/small configurations from
-- spuriously containing the origin after Double products underflow. This is
-- still GJK support iteration, with exact arithmetic only for its topology.
type R2 = (Rational, Rational)
toR2 :: Point2 -> R2
toR2 (P2 x y) = (toRational x, toRational y)
rsub :: R2 -> R2 -> R2
rsub (x, y) (a, b) = (x - a, y - b)
rscale :: Rational -> R2 -> R2
rscale a (x, y) = (a * x, a * y)
rdot :: R2 -> R2 -> Rational
rdot (x, y) (a, b) = x * a + y * b
rcross :: R2 -> R2 -> Rational
rcross (x, y) (a, b) = x * b - y * a
rtriple :: R2 -> R2 -> R2 -> R2
rtriple a b c = rsub (rscale (rdot a c) b) (rscale (rdot b c) a)
reduce :: [R2] -> (Bool, [R2], R2)
reduce [a, b] =
    let ab = rsub b a; ao = rscale (-1) a; projection = rdot ab ao
     in if projection <= 0
            then (a == (0, 0), [a], ao)
            else
                if rcross ab ao == 0
                    then
                        if projection <= rdot ab ab
                            then (True, [a, b], (0, 0))
                            else (b == (0, 0), [b], rscale (-1) b)
                    else (False, [a, b], rtriple ab ao ab)
reduce [a, b, c] =
    let ab = rsub b a; ac = rsub c a; ao = rscale (-1) a; left = rtriple ac ab ab; right = rtriple ab ac ac
     in if rdot left ao > 0
            then reduce [a, b]
            else if rdot right ao > 0 then reduce [a, c] else (True, [a, b, c], (0, 0))
reduce [a] = (a == (0, 0), [a], rscale (-1) a)
reduce _ = (False, [], (1, 0))
gjkSimplex :: Int -> [Point2] -> [Point2] -> Either MathError (Bool, [Point2])
gjkSimplex budget a b = do
    validate a b
    require (budget > 0 && budget <= 100000) "invalid GJK iteration budget"
    let aa = map toR2 a
        bb = map toR2 b
        extreme ps direction = foldl1 (\x y -> if rdot y direction > rdot x direction then y else x) ps
        supporting direction = rsub (extreme aa direction) (extreme bb (rscale (-1) direction))
        initial = supporting (1, 0)
        step used simplex direction
            | direction == (0, 0) = Right (True, simplex)
            | used >= budget = Left (NonConvergence "GJK" used)
            | otherwise =
                let p = supporting direction
                 in if rdot p direction < 0
                        then Right (False, simplex)
                        else
                            if p `elem` simplex
                                then Right (False, simplex)
                                else
                                    let (hit, remaining, next) = reduce (p : simplex)
                                     in if hit then Right (True, remaining) else step (used + 1) remaining next
    (hit, points) <-
        if initial == (0, 0) then Right (True, [initial]) else step 0 [initial] (rscale (-1) initial)
    Right (hit, [P2 (fromRational x) (fromRational y) | (x, y) <- points])

-- | Convex intersection by Gilbert-Johnson-Keerthi support/simplex iterations.
gjk :: Int -> [Point2] -> [Point2] -> Either MathError Bool
gjk budget a b = fst <$> gjkSimplex budget a b

{- | Normal moves the second shape away from the first by penetrationDepth.
A zero-depth touch may have the deterministic normal (1,0).
-}
data Penetration = Penetration
    { penetrationDepth :: Double
    -- ^ Estimated overlap depth along penetrationNormal, in coordinate units.
    , penetrationNormal :: Point2
    -- ^ Separating direction of the returned EPA penetration estimate.
    , penetrationError :: Double
    -- ^ Remaining absolute support gap at the stopping iteration.
    , penetrationIterations :: Int
    -- ^ Completed expanding-polytope iterations.
    }
    deriving (Eq, Show)

{- | Expanding polytope penetration estimate. The tolerance is an absolute
support-gap stopping threshold, positive finite and <=1e50.
-}
epa :: Int -> Double -> [Point2] -> [Point2] -> Either MathError (Maybe Penetration)
epa budget tolerance a b = do
    require
        (budget > 0 && budget <= 100000 && coord tolerance && tolerance > 0)
        "invalid EPA tolerance/budget"
    (hit, simplex) <- gjkSimplex budget a b
    if not hit
        then Right Nothing
        else do
            poly <-
                convexHull
                    MonotoneChain
                    (nub (simplex ++ [support a b d | d <- [P2 1 0, P2 (-1) 0, P2 0 1, P2 0 (-1)]]))
            if length poly < 3 then Right (Just (Penetration 0 (P2 1 0) 0 0)) else expand poly 0
  where
    expand poly iteration
        | iteration >= budget = Left (NonConvergence "EPA" iteration)
        | otherwise =
            let candidate (edgeIndex, (u, v)) =
                    let P2 dx dy = sub2 v u; size = norm2 (sub2 v u); n = P2 (dy / size) (-dx / size); edgeDepth = dot2 n u
                     in (edgeDepth, edgeIndex, n)
                (depth, index, normal) = minimumBy (comparing (\(d, _, _) -> d)) (map candidate (zip [0 :: Int ..] (edges poly)))
                p = support a b normal
                gap = dot2 normal p - depth
             in if gap <= tolerance || p `elem` poly
                    then Right (Just (Penetration (max 0 depth) normal (max 0 gap) iteration))
                    else expand (take (index + 1) poly ++ [p] ++ drop (index + 1) poly) (iteration + 1)

{- | Separating-axis collision and minimum overlap for convex polygons. Shapes
must have nonzero area; containment depth uses the distance to the nearer
separating interval endpoint, rather than only the interval intersection.
-}
separatingAxis :: [Point2] -> [Point2] -> Either MathError (Maybe Penetration)
separatingAxis a b = do
    validate a b
    x <- convexHull MonotoneChain a
    y <- convexHull MonotoneChain b
    require (length x >= 3 && length y >= 3) "SAT requires nonzero-area convex polygons"
    let axes =
            [ let P2 dx dy = sub2 v u; size = norm2 (sub2 v u) in P2 (dy / size) (-dx / size)
            | (u, v) <- edges x ++ edges y
            ]
        project axis ps = let vals = map (dot2 axis) ps in (minimum vals, maximum vals)
        test axis =
            let (al, ah) = project axis x; (bl, bh) = project axis y; positive = ah - bl; negative = bh - al
             in if positive < 0 || negative < 0
                    then Nothing
                    else if positive <= negative then Just (positive, axis) else Just (negative, scale2 (-1) axis)
    case mapM test axes of
        Nothing -> Right Nothing
        Just hits ->
            let (depth, normal) = minimumBy (comparing fst) hits
             in Right (Just (Penetration depth normal 0 (length axes)))
