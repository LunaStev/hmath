-- SPDX-License-Identifier: MPL-2.0

{- | Shared finite Euclidean geometry. Coordinates are bounded by 1e50 to keep
Double products representable; exact Rational predicates determine signs.
Public checked operations validate constructors, including raw record values.
-}
module HMath.Geometry.Internal where

import HMath.Error (MathError (..))

-- | Cartesian two-dimensional point, also used for vectors.
data Point2 = P2 Double Double deriving (Eq, Ord, Show)

-- | Cartesian right-handed three-dimensional point/vector.
data Point3 = P3 Double Double Double deriving (Eq, Ord, Show)

-- | A point of dimension 1..16.
newtype PointND = PointND [Double] deriving (Eq, Ord, Show)

-- | Parametric line origin+t*direction; direction must be nonzero.
data Line = Line PointND PointND deriving (Eq, Show)

-- | Parametric ray origin+t*direction, t>=0.
data Ray = Ray Point3 Point3 deriving (Eq, Show)

-- | Closed segment with two endpoints; zero length is valid.
data Segment = Segment PointND PointND deriving (Eq, Show)

-- | Plane normal dot x = offset, with a nonzero normal.
data Plane = Plane Point3 Double deriving (Eq, Show)

-- | Closed triangle; zero-area triangles are rejected by triangle operations.
data Triangle = Triangle Point2 Point2 Point2 deriving (Eq, Show)

-- | Axis-aligned rectangle with ordered corners.
data Rectangle = Rectangle Point2 Point2 deriving (Eq, Show)

-- | Circle with nonnegative radius.
data Circle = Circle Point2 Double deriving (Eq, Show)

-- | Rotated ellipse: positive semiaxes, counterclockwise angle in radians.
data Ellipse = Ellipse Point2 Double Double Double deriving (Eq, Show)

-- | Simple polygon; vertices are implicitly closed and no duplicate endpoint is needed.
newtype Polygon = Polygon [Point2] deriving (Eq, Show)

-- | Closed sphere, including a zero radius.
data Sphere = Sphere Point3 Double deriving (Eq, Show)

-- | Ordered, closed axis-aligned bounds in 1..16 dimensions.
data AABB = AABB PointND PointND deriving (Eq, Show)

-- | Oriented three-dimensional box: center, three orthonormal axes, half-extents.
data OBB = OBB Point3 [Point3] Point3 deriving (Eq, Show)

-- | Capsule around the closed axis segment.
data Capsule = Capsule Point3 Point3 Double deriving (Eq, Show)

-- | Finite cylinder with endpoint centers and radius; endpoints must differ.
data Cylinder = Cylinder Point3 Point3 Double deriving (Eq, Show)

-- | Finite cone with apex, base center, and radius; axis must be nonzero.
data Cone = Cone Point3 Point3 Double deriving (Eq, Show)

-- | Convex frustum represented by six inward half-spaces n dot x >= offset.
newtype Frustum = Frustum [Plane] deriving (Eq, Show)

-- | Sign of an exact predicate on the input Double values.
data Orientation = Clockwise | Collinear | Counterclockwise deriving (Eq, Ord, Show)

-- | Point position with boundary reported separately.
data Location = Outside | Boundary | Inside deriving (Eq, Ord, Show)

finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)
require :: Bool -> String -> Either MathError ()
require condition message = if condition then Right () else Left (DomainError message)
coord :: Double -> Bool
coord x = finite x && abs x <= 1e50
coords2 :: Point2 -> [Double]
coords2 (P2 x y) = [x, y]
coords3 :: Point3 -> [Double]
coords3 (P3 x y z) = [x, y, z]
coordsND :: PointND -> [Double]
coordsND (PointND xs) = xs
check2 :: Point2 -> Either MathError ()
check2 p = require (all coord (coords2 p)) "invalid 2D coordinates (finite, |x|<=1e50)"
check3 :: Point3 -> Either MathError ()
check3 p = require (all coord (coords3 p)) "invalid 3D coordinates (finite, |x|<=1e50)"
checkND :: PointND -> Either MathError ()
checkND (PointND xs) =
    require
        (not (null xs) && length xs <= 16 && all coord xs)
        "invalid ND point (dimension 1..16, |x|<=1e50)"
checkPair :: PointND -> PointND -> Either MathError ()
checkPair a b =
    checkND a
        >> checkND b
        >> require (length (coordsND a) == length (coordsND b)) "point dimensions differ"
checked :: [Double] -> Either MathError [Double]
checked xs = if all finite xs then Right xs else Left NonFiniteResult
point2 :: Double -> Double -> Either MathError Point2
point2 x y = let p = P2 x y in check2 p >> Right p
point3 :: Double -> Double -> Double -> Either MathError Point3
point3 x y z = let p = P3 x y z in check3 p >> Right p
pointND :: [Double] -> Either MathError PointND
pointND xs = let p = PointND xs in checkND p >> Right p
dot :: [Double] -> [Double] -> Double
dot a b = sum (zipWith (*) a b)
norm :: [Double] -> Double
norm xs =
    let size = maximum (0 : map abs xs)
     in if size == 0 then 0 else size * sqrt (sum [(x / size) ^ (2 :: Int) | x <- xs])
sub :: [Double] -> [Double] -> [Double]
sub = zipWith (-)
plus :: [Double] -> [Double] -> [Double]
plus = zipWith (+)
scale :: Double -> [Double] -> [Double]
scale a = map (* a)
cross :: Point3 -> Point3 -> Point3
cross (P3 a b c) (P3 x y z) = P3 (b * z - c * y) (c * x - a * z) (a * y - b * x)
add2 :: Point2 -> Point2 -> Point2
add2 (P2 x y) (P2 a b) = P2 (x + a) (y + b)
sub2 :: Point2 -> Point2 -> Point2
sub2 (P2 x y) (P2 a b) = P2 (x - a) (y - b)
scale2 :: Double -> Point2 -> Point2
scale2 t (P2 x y) = P2 (t * x) (t * y)
cross2 :: Point2 -> Point2 -> Double
cross2 (P2 x y) (P2 a b) = x * b - y * a
dot2 :: Point2 -> Point2 -> Double
dot2 a b = dot (coords2 a) (coords2 b)
norm2 :: Point2 -> Double
norm2 = norm . coords2
from3 :: [Double] -> Point3
from3 [x, y, z] = P3 x y z
from3 _ = P3 0 0 0
edges :: [a] -> [(a, a)]
edges [] = []
edges xs@(first : rest) = zip xs (rest ++ [first])
orientExact :: Point2 -> Point2 -> Point2 -> Rational
orientExact (P2 ax ay) (P2 bx by) (P2 cx cy) =
    (toRational bx - toRational ax) * (toRational cy - toRational ay)
        - (toRational by - toRational ay) * (toRational cx - toRational ax)
orient :: Point2 -> Point2 -> Point2 -> Ordering
orient a b c = compare (orientExact a b c) 0
onSegment :: Point2 -> Point2 -> Point2 -> Bool
onSegment a@(P2 ax ay) b@(P2 bx by) p@(P2 x y) = orient a b p == EQ && x >= min ax bx && x <= max ax bx && y >= min ay by && y <= max ay by
checkPolygon :: Polygon -> Either MathError [Point2]
checkPolygon (Polygon ps) = do
    require (length ps >= 3 && length ps <= 256) "polygon requires 3..256 vertices"
    mapM_ check2 ps
    require (all (uncurry (/=)) (edges ps)) "polygon has duplicate adjacent vertices"
    let es = zip [0 :: Int ..] (edges ps)
        n = length ps
        hit (a, b) (c, d) =
            (orient a b c /= orient a b d && orient c d a /= orient c d b)
                || onSegment a b c
                || onSegment a b d
                || onSegment c d a
                || onSegment c d b
    require
        (and [not (hit e f) | (i, e) <- es, (j, f) <- es, i < j, j /= i + 1, not (i == 0 && j == n - 1)])
        "polygon self-intersects"
    require (signedArea ps /= 0) "polygon has zero area"
    Right ps
signedArea :: [Point2] -> Double
signedArea ps =
    fromRational
        ( sum
            [toRational ax * toRational by - toRational ay * toRational bx | (P2 ax ay, P2 bx by) <- edges ps]
            / 2
        )
ccw :: [Point2] -> [Point2]
ccw ps = if signedArea ps < 0 then reverse ps else ps
locateUnchecked :: [Point2] -> Point2 -> Location
locateUnchecked ps p@(P2 x y)
    | any (\(a, b) -> onSegment a b p) (edges ps) = Boundary
    | odd
        ( length
            [ ()
            | (P2 ax ay, P2 bx by) <- edges ps
            , (ay > y) /= (by > y)
            , x < (bx - ax) * (y - ay) / (by - ay) + ax
            ]
        ) =
        Inside
    | otherwise = Outside

firstOr :: a -> [a] -> a
firstOr fallback [] = fallback
firstOr _ (x : _) = x
