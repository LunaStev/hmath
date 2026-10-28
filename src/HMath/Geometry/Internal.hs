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

{- | Test whether a Double is neither NaN nor infinite. This alone does not impose the
geometry coordinate magnitude cap.
-}
finite :: Double -> Bool
finite x = not (isNaN x || isInfinite x)

{- | Given predicate then diagnostic text, return Right () if satisfied or Left (DomainError
text).
-}
require :: Bool -> String -> Either MathError ()
require condition message = if condition then Right () else Left (DomainError message)

{- | Accept a finite geometry coordinate only when its absolute value is \<=1e50, bounding
downstream Double products.
-}
coord :: Double -> Bool
coord x = finite x && abs x <= 1e50

-- | Extract [x,y] from a Point2 without validation.
coords2 :: Point2 -> [Double]
coords2 (P2 x y) = [x, y]

-- | Extract [x,y,z] from a Point3 without validation.
coords3 :: Point3 -> [Double]
coords3 (P3 x y z) = [x, y, z]

-- | Extract ordered coordinate list from a PointND without validation.
coordsND :: PointND -> [Double]
coordsND (PointND xs) = xs

{- | Validate both Point2 coordinates as finite with absolute magnitude \<=1e50; invalid data
returns DomainError.
-}
check2 :: Point2 -> Either MathError ()
check2 p = require (all coord (coords2 p)) "invalid 2D coordinates (finite, |x|<=1e50)"

{- | Validate all Point3 coordinates as finite with absolute magnitude \<=1e50; invalid data
returns DomainError.
-}
check3 :: Point3 -> Either MathError ()
check3 p = require (all coord (coords3 p)) "invalid 3D coordinates (finite, |x|<=1e50)"

{- | Require 1..16 coordinates, all finite and bounded by 1e50 in magnitude. Invalid PointND
returns DomainError.
-}
checkND :: PointND -> Either MathError ()
checkND (PointND xs) =
    require
        (not (null xs) && length xs <= 16 && all coord xs)
        "invalid ND point (dimension 1..16, |x|<=1e50)"

{- | Validate both ND points and require equal dimensions. Invalid coordinates/rank/mismatch
return DomainError.
-}
checkPair :: PointND -> PointND -> Either MathError ()
checkPair a b =
    checkND a
        >> checkND b
        >> require (length (coordsND a) == length (coordsND b)) "point dimensions differ"

{- | Return the supplied list if every Double is finite, otherwise Left NonFiniteResult.
This checks numerical results without the coordinate magnitude cap.
-}
checked :: [Double] -> Either MathError [Double]
checked xs = if all finite xs then Right xs else Left NonFiniteResult

{- | Given x,y, construct Point2 after bounded finite-coordinate validation. Invalid values
return DomainError.
-}
point2 :: Double -> Double -> Either MathError Point2
point2 x y = let p = P2 x y in check2 p >> Right p

{- | Given x,y,z, construct Point3 after bounded finite-coordinate validation. Invalid
values return DomainError.
-}
point3 :: Double -> Double -> Double -> Either MathError Point3
point3 x y z = let p = P3 x y z in check3 p >> Right p

{- | Construct a checked ND point from 1..16 bounded finite coordinates. Invalid
dimension/value returns DomainError.
-}
pointND :: [Double] -> Either MathError PointND
pointND xs = let p = PointND xs in checkND p >> Right p

{- | Unchecked sum of pairwise list products using zipWith; unequal lists truncate to the
shorter length. Checked geometry callers must validate matching dimensions first.
-}
dot :: [Double] -> [Double] -> Double
dot a b = sum (zipWith (*) a b)

{- | Return scaled Euclidean list norm to reduce intermediate overflow; empty/all-zero list
yields zero. No finiteness check is added.
-}
norm :: [Double] -> Double
norm xs =
    let size = maximum (0 : map abs xs)
     in if size == 0 then 0 else size * sqrt (sum [(x / size) ^ (2 :: Int) | x <- xs])

{- | Unchecked coordinatewise left-minus-right list subtraction, truncating to the shorter
list on mismatch.
-}
sub :: [Double] -> [Double] -> [Double]
sub = zipWith (-)

-- | Unchecked coordinatewise list addition, truncating to the shorter list on mismatch.
plus :: [Double] -> [Double] -> [Double]
plus = zipWith (+)

{- | Given Double scalar then coordinate list, return all coordinates multiplied by it
without validation.
-}
scale :: Double -> [Double] -> [Double]
scale a = map (* a)

{- | Return right-handed cross product of two Point3 vectors. Coordinates/results are
unchecked at this helper boundary.
-}
cross :: Point3 -> Point3 -> Point3
cross (P3 a b c) (P3 x y z) = P3 (b * z - c * y) (c * x - a * z) (a * y - b * x)

-- | Add Point2 coordinates componentwise without validation.
add2 :: Point2 -> Point2 -> Point2
add2 (P2 x y) (P2 a b) = P2 (x + a) (y + b)

-- | Subtract right Point2 coordinates from left, without validation.
sub2 :: Point2 -> Point2 -> Point2
sub2 (P2 x y) (P2 a b) = P2 (x - a) (y - b)

-- | Given scalar then Point2, scale both coordinates without validation.
scale2 :: Double -> Point2 -> Point2
scale2 t (P2 x y) = P2 (t * x) (t * y)

-- | Return 2D determinant ax*by-ay*bx as Double without validation.
cross2 :: Point2 -> Point2 -> Double
cross2 (P2 x y) (P2 a b) = x * b - y * a

-- | Return 2D dot product ax*bx+ay*by without validation.
dot2 :: Point2 -> Point2 -> Double
dot2 a b = dot (coords2 a) (coords2 b)

-- | Return scaled Euclidean length of a Point2 without checked finite validation.
norm2 :: Point2 -> Double
norm2 = norm . coords2

{- | Convert a list of exactly three Doubles to Point3; all other lengths return origin P3 0
0 0. This helper does not validate finite coordinates.
-}
from3 :: [Double] -> Point3
from3 [x, y, z] = P3 x y z
from3 _ = P3 0 0 0

{- | Pair each polygon-list element with its cyclic successor, including the last-to-first
edge. Empty list returns []; singleton returns one self-pair.
-}
edges :: [a] -> [(a, a)]
edges [] = []
edges xs@(first : rest) = zip xs (rest ++ [first])

{- | Given finite points a,b,c, compute exact Rational determinant of their represented
Double coordinates. Positive is counterclockwise, zero collinear; non-finite inputs
violate this unchecked helper's precondition.
-}
orientExact :: Point2 -> Point2 -> Point2 -> Rational
orientExact (P2 ax ay) (P2 bx by) (P2 cx cy) =
    (toRational bx - toRational ax) * (toRational cy - toRational ay)
        - (toRational by - toRational ay) * (toRational cx - toRational ax)

{- | Compare orientExact determinant with zero, returning GT for counterclockwise, EQ for
collinear, LT for clockwise. Inputs must already be finite.
-}
orient :: Point2 -> Point2 -> Point2 -> Ordering
orient a b c = compare (orientExact a b c) 0

{- | Given endpoints a,b then point p, test exact collinearity and inclusive coordinate
bounds. Finite input validation belongs to the checked caller.
-}
onSegment :: Point2 -> Point2 -> Point2 -> Bool
onSegment a@(P2 ax ay) b@(P2 bx by) p@(P2 x y) = orient a b p == EQ && x >= min ax bx && x <= max ax bx && y >= min ay by && y <= max ay by

{- | Validate a simple polygon with 3..256 bounded finite vertices, no adjacent duplicates,
nonzero area and no nonadjacent edge intersection. Return validated vertices or
DomainError.
-}
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

{- | Return oriented shoelace area using exact Rational intermediate arithmetic on finite
Double coordinates. Positive means counterclockwise. This helper does not validate
polygon simplicity.
-}
signedArea :: [Point2] -> Double
signedArea ps =
    fromRational
        ( sum
            [toRational ax * toRational by - toRational ay * toRational bx | (P2 ax ay, P2 bx by) <- edges ps]
            / 2
        )

{- | Return polygon vertices in counterclockwise order by reversing negative signed area;
zero-area input remains unchanged. Validation is the caller's responsibility.
-}
ccw :: [Point2] -> [Point2]
ccw ps = if signedArea ps < 0 then reverse ps else ps

{- | Given valid simple polygon vertices then finite Point2, return Boundary for an edge
point, otherwise Inside/Outside by ray parity. This helper performs no constructor
validation.
-}
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

{- | Given fallback then list, return its first element or the fallback for empty input.
Example: firstOr 0 [] == 0.
-}
firstOr :: a -> [a] -> a
firstOr fallback [] = fallback
firstOr _ (x : _) = x
