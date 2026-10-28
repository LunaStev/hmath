-- SPDX-License-Identifier: MPL-2.0

{- | Checked distances, containment, intersections and primitive signed distance
functions. Boundaries are included, rays return their nonnegative parameter
(direction need not be normalized), and coincident/overlapping intersections
are explicit. Metrics accept dimensions 1..16; discrete Jaccard uses sets.
-}
module HMath.Geometry.Primitives (
    Metric (..),
    distance,
    cosineDistance,
    hammingDistance,
    jaccardDistance,
    hausdorffDistance,
    mahalanobisDistance,
    pointLineDistance,
    pointSegmentDistance,
    pointPlaneDistance,
    orientation,
    incircle,
    polygonLocation,
    triangleLocation,
    sphereContains,
    boxContains,
    ellipseContains,
    triangleBarycentric,
    circumcenter,
    incenter,
    Intersection2 (..),
    segmentIntersection,
    lineIntersection,
    linePlaneIntersection,
    planeIntersection,
    rayTriangle,
    rayBox,
    raySphere,
    CircleIntersection (..),
    circleIntersection,
    triangleIntersection,
    sphereSDF,
    boxSDF,
    obbSDF,
    capsuleSDF,
    cylinderSDF,
    coneSDF,
) where

import Data.List (nub, sort)
import HMath.Error (MathError (..))
import HMath.Geometry.Internal

-- | Minkowski p must be finite and at least one.
data Metric = Euclidean | Manhattan | Chebyshev | Minkowski Double deriving (Eq, Show)

-- | Euclidean, L1, Linfinity, or scaled Lp distance.
distance :: Metric -> PointND -> PointND -> Either MathError Double
distance metric a b = do
    checkPair a b
    let xs = map abs (sub (coordsND a) (coordsND b)); s = maximum xs
    case metric of
        Euclidean -> Right (norm xs)
        Manhattan -> Right (sum xs)
        Chebyshev -> Right s
        Minkowski p ->
            require (finite p && p >= 1) "Minkowski p must be >=1"
                >> Right (if s == 0 then 0 else s * (sum [(x / s) ** p | x <- xs]) ** (1 / p))

-- | One minus cosine similarity; zero vectors are undefined.
cosineDistance :: PointND -> PointND -> Either MathError Double
cosineDistance a b = do
    checkPair a b
    let x = coordsND a; y = coordsND b; nx = norm x; ny = norm y
    require (nx > 0 && ny > 0) "cosine distance of zero vector"
    Right (1 - max (-1) (min 1 (dot (map (/ nx) x) (map (/ ny) y))))

-- | Number of unequal positions (not normalized).
hammingDistance :: (Eq a) => [a] -> [a] -> Either MathError Int
hammingDistance a b =
    require (length a == length b && length a <= 1000000) "Hamming length mismatch/budget"
        >> Right (length (filter not (zipWith (==) a b)))

-- | Set Jaccard distance; two empty sets have distance zero.
jaccardDistance :: (Eq a) => [a] -> [a] -> Either MathError Double
jaccardDistance a b = do
    require (length a <= 4096 && length b <= 4096) "Jaccard reference budget exceeded"
    let x = nub a; y = nub b; union = nub (x ++ y); common = filter (`elem` y) x
    Right (if null union then 0 else 1 - fromIntegral (length common) / fromIntegral (length union))

-- | Symmetric Hausdorff distance on two nonempty finite clouds, at most 1024 each.
hausdorffDistance :: [PointND] -> [PointND] -> Either MathError Double
hausdorffDistance a b = do
    require
        (not (null a || null b) && length a <= 1024 && length b <= 1024)
        "Hausdorff empty cloud/budget"
    rows <- mapM (\x -> mapM (distance Euclidean x) b) a
    Right
        (max (maximum (map minimum rows)) (maximum [minimum [r !! j | r <- rows] | j <- [0 .. length b - 1]]))

{- | Mahalanobis distance using a checked symmetric positive-definite covariance.
A Cholesky triangular solve avoids an explicit inverse.
-}
mahalanobisDistance :: [[Double]] -> PointND -> PointND -> Either MathError Double
mahalanobisDistance covariance a b = do
    checkPair a b
    let n = length (coordsND a)
    require
        (length covariance == n && all ((== n) . length) covariance && all finite (concat covariance))
        "invalid covariance shape/entries"
    require
        ( and
            [ abs (covariance !! i !! j - covariance !! j !! i) <= 1e-12 * max 1 (abs (covariance !! i !! j))
            | i <- [0 .. n - 1]
            , j <- [0 .. n - 1]
            ]
        )
        "covariance is not symmetric"
    l <- build n [] 0
    let delta = sub (coordsND a) (coordsND b)
        solve ys i
            | i == n = ys
            | otherwise =
                solve
                    (ys ++ [(delta !! i - sum [l !! i !! j * ys !! j | j <- [0 .. i - 1]]) / (l !! i !! i)])
                    (i + 1)
        answer = norm (solve [] 0)
    if finite answer then Right answer else Left NonFiniteResult
  where
    build n rows i
        | i == n = Right rows
        | otherwise = do
            row <- columns rows i [] 0
            build n (rows ++ [row ++ replicate (n - i - 1) 0]) (i + 1)
    columns rows i vals j
        | j > i = Right vals
        | otherwise =
            let s =
                    covariance !! i !! j
                        - sum [vals !! k * (if i == j then vals !! k else rows !! j !! k) | k <- [0 .. j - 1]]
             in if i == j
                    then
                        if s <= 0 || not (finite s)
                            then Left (NotPositiveDefinite i)
                            else columns rows i (vals ++ [sqrt s]) (j + 1)
                    else columns rows i (vals ++ [s / (rows !! j !! j)]) (j + 1)

-- | Distance to an infinite line; a zero direction is an error.
pointLineDistance :: PointND -> Line -> Either MathError Double
pointLineDistance p (Line a direction) = do
    checkPair p a
    checkPair p direction
    let directionValues = coordsND direction; q = sub (coordsND p) (coordsND a); size = norm directionValues
    require (size > 0) "zero line direction"
    let unit = map (/ size) directionValues
    Right (norm (sub q (scale (dot q unit) unit)))

-- | Distance to a closed segment, including a zero-length segment.
pointSegmentDistance :: PointND -> Segment -> Either MathError Double
pointSegmentDistance p (Segment a b) = do
    checkPair p a
    checkPair a b
    let d = sub (coordsND b) (coordsND a)
        q = sub (coordsND p) (coordsND a)
        size = norm d
        unit = if size == 0 then replicate (length d) 0 else map (/ size) d
        t = max 0 (min size (dot q unit))
    Right (norm (sub q (scale t unit)))

checkPlane :: Plane -> Either MathError ()
checkPlane (Plane n h) = check3 n >> require (coord h && norm (coords3 n) > 0) "invalid plane normal/offset"

-- | Unsigned perpendicular plane distance.
pointPlaneDistance :: Point3 -> Plane -> Either MathError Double
pointPlaneDistance p plane@(Plane n h) = do
    check3 p
    checkPlane plane
    let value = fromRational (abs (rDot (r3 p) (r3 n) - toRational h) / toRational (norm (coords3 n)))
    _ <- checked [value]
    Right value

r3 :: Point3 -> [Rational]
r3 = map toRational . coords3
rDot :: [Rational] -> [Rational] -> Rational
rDot a b = sum (zipWith (*) a b)
rCross :: [Rational] -> [Rational] -> [Rational]
rCross [a, b, c] [x, y, z] = [b * z - c * y, c * x - a * z, a * y - b * x]
rCross _ _ = []

-- | Exact orientation of the represented finite Double coordinates.
orientation :: Point2 -> Point2 -> Point2 -> Either MathError Orientation
orientation a b c = do
    mapM_ check2 [a, b, c]
    Right (case orient a b c of LT -> Clockwise; EQ -> Collinear; GT -> Counterclockwise)

{- | Exact in-circle sign, orientation-independent: positive means inside.
A collinear defining triangle is rejected.
-}
incircle :: Point2 -> Point2 -> Point2 -> Point2 -> Either MathError Ordering
incircle a b c p = do
    mapM_ check2 [a, b, c, p]
    require (orient a b c /= EQ) "incircle triangle is collinear"
    let rational (P2 x y) = (toRational x, toRational y)
        delta u v = let (x, y) = rational u; (z, w) = rational v in (x - z, y - w)
        (ax, ay) = delta a p
        (bx, by) = delta b p
        (cx, cy) = delta c p
        determinant =
            (ax * ax + ay * ay) * (bx * cy - by * cx)
                - (bx * bx + by * by) * (ax * cy - ay * cx)
                + (cx * cx + cy * cy) * (ax * by - ay * bx)
    Right (compare (if orient a b c == GT then determinant else -determinant) 0)

-- | Simple polygon position, with boundary separate from interior.
polygonLocation :: Polygon -> Point2 -> Either MathError Location
polygonLocation poly p = do ps <- checkPolygon poly; check2 p; Right (locateUnchecked ps p)

-- | Triangle position using exact orientation signs.
triangleLocation :: Triangle -> Point2 -> Either MathError Location
triangleLocation (Triangle a b c) p = do
    mapM_ check2 [a, b, c, p]
    require (orient a b c /= EQ) "degenerate triangle"
    let signs = [orient a b p, orient b c p, orient c a p]
    Right
        (if LT `elem` signs && GT `elem` signs then Outside else if EQ `elem` signs then Boundary else Inside)

-- | Closed sphere containment.
sphereContains :: Sphere -> Point3 -> Either MathError Bool
sphereContains sphere p = (<= 0) <$> sphereSDF sphere p

checkBox :: AABB -> Either MathError ()
checkBox (AABB a b) = checkPair a b >> require (and (zipWith (<=) (coordsND a) (coordsND b))) "unordered box bounds"

-- | Closed axis-aligned box containment.
boxContains :: AABB -> PointND -> Either MathError Bool
boxContains box@(AABB a b) p =
    checkBox box
        >> checkPair a p
        >> Right (and (zipWith3 (\x l h -> x >= l && x <= h) (coordsND p) (coordsND a) (coordsND b)))

-- | Closed ellipse containment after rotation to its principal axes.
ellipseContains :: Ellipse -> Point2 -> Either MathError Bool
ellipseContains (Ellipse c a b theta) p = do
    mapM_ check2 [c, p]
    require (coord a && coord b && a > 0 && b > 0 && finite theta) "invalid ellipse"
    let P2 x y = sub2 p c; u = (cos theta * x + sin theta * y) / a; v = (-sin theta * x + cos theta * y) / b
    Right (u * u + v * v <= 1)

-- | Weights (a,b,c) summing to one; valid outside the triangle as well.
triangleBarycentric :: Triangle -> Point2 -> Either MathError [Double]
triangleBarycentric (Triangle a b c) p = do
    mapM_ check2 [a, b, c, p]
    require (orient a b c /= EQ) "degenerate barycentric triangle"
    let d = orientExact a b c
    checked (map fromRational [orientExact p b c / d, orientExact a p c / d, orientExact a b p / d])

-- | Circumcenter, obtained from exact rational perpendicular-bisector equations.
circumcenter :: Triangle -> Either MathError Point2
circumcenter (Triangle a b c) = do
    mapM_ check2 [a, b, c]
    require (orient a b c /= EQ) "collinear circumcenter"
    let rational (P2 x y) = (toRational x, toRational y)
        (ax, ay) = rational a
        (bx, by) = rational b
        (cx, cy) = rational c
        u = bx - ax
        v = by - ay
        s = cx - ax
        t = cy - ay
        h = (u * u + v * v) / 2
        k = (s * s + t * t) / 2
        d = u * t - v * s
    point2 (fromRational (ax + (h * t - v * k) / d)) (fromRational (ay + (u * k - h * s) / d))

-- | Incenter weighted by opposite side lengths.
incenter :: Triangle -> Either MathError Point2
incenter (Triangle a b c) = do
    mapM_ check2 [a, b, c]
    require (orient a b c /= EQ) "collinear incenter"
    let x = norm2 (sub2 b c)
        y = norm2 (sub2 a c)
        z = norm2 (sub2 a b)
        total = x + y + z
        P2 u v = add2 (scale2 (x / total) a) (add2 (scale2 (y / total) b) (scale2 (z / total) c))
    point2 u v

-- | Two-dimensional intersection, with a coincident line or overlapping segment explicit.
data Intersection2
    = NoIntersection
    | IntersectionPoint Point2
    | OverlapSegment Point2 Point2
    | CoincidentLine
    deriving (Eq, Show)

-- | Infinite-line intersection from origins and nonzero direction vectors.
lineIntersection :: Point2 -> Point2 -> Point2 -> Point2 -> Either MathError Intersection2
lineIntersection a u b v = do
    mapM_ check2 [a, u, b, v]
    require (u /= P2 0 0 && v /= P2 0 0) "zero line direction"
    let rational (P2 x y) = (toRational x, toRational y)
        (ax, ay) = rational a
        (bx, by) = rational b
        (ux, uy) = rational u
        (vx, vy) = rational v
        dx = bx - ax
        dy = by - ay
        denominator = ux * vy - uy * vx
    if denominator == 0
        then Right (if ux * dy - uy * dx == 0 then CoincidentLine else NoIntersection)
        else
            let t = (dx * vy - dy * vx) / denominator
             in IntersectionPoint <$> point2 (fromRational (ax + t * ux)) (fromRational (ay + t * uy))

-- | Closed segment intersection with exact degeneracy predicates.
segmentIntersection :: Point2 -> Point2 -> Point2 -> Point2 -> Either MathError Intersection2
segmentIntersection a b c d = do
    mapM_ check2 [a, b, c, d]
    if a == b
        then Right (if onSegment c d a then IntersectionPoint a else NoIntersection)
        else
            if c == d
                then Right (if onSegment a b c then IntersectionPoint c else NoIntersection)
                else
                    if orient a b c == EQ && orient a b d == EQ
                        then
                            let pts = nub [p | p <- [a, b, c, d], onSegment a b p && onSegment c d p]
                                ordered = if a <= b then (minimum pts, maximum pts) else (maximum pts, minimum pts)
                             in Right
                                    ( if null pts
                                        then NoIntersection
                                        else
                                            if length pts == 1 then IntersectionPoint (firstOr (P2 0 0) pts) else uncurry OverlapSegment ordered
                                    )
                        else
                            if (orient a b c == EQ || orient a b d == EQ || orient a b c /= orient a b d)
                                && (orient c d a == EQ || orient c d b == EQ || orient c d a /= orient c d b)
                                then lineIntersection a (sub2 b a) c (sub2 d c)
                                else Right NoIntersection

{- | Line/plane result: Nothing parallel/disjoint, Just Nothing coincident,
Just (Just p) a unique intersection. The line must have dimension three.
-}
linePlaneIntersection :: Line -> Plane -> Either MathError (Maybe (Maybe Point3))
linePlaneIntersection (Line a d) plane@(Plane normal h) = do
    checkPair a d
    require (length (coordsND a) == 3 && norm (coordsND d) > 0) "invalid 3D line"
    checkPlane plane
    let ar = map toRational (coordsND a)
        dr = map toRational (coordsND d)
        nr = r3 normal
        den = rDot dr nr
        delta = toRational h - rDot ar nr
    if den == 0
        then Right (if delta == 0 then Just Nothing else Nothing)
        else do
            xs <- checked (map fromRational (zipWith (\x v -> x + delta / den * v) ar dr))
            check3 (from3 xs)
            Right (Just (Just (from3 xs)))

{- | Plane intersection: same nested convention as linePlaneIntersection,
with the unique intersection represented by a line.
-}
planeIntersection :: Plane -> Plane -> Either MathError (Maybe (Maybe Line))
planeIntersection p@(Plane a h) q@(Plane b k) = do
    checkPlane p
    checkPlane q
    let ar = r3 a; br = r3 b; direction = rCross ar br; dd = rDot direction direction
    if dd == 0
        then
            Right
                ( if and (zipWith (==) (map (* toRational h) br) (map (* toRational k) ar))
                    then Just Nothing
                    else Nothing
                )
        else do
            let values =
                    zipWith
                        (\x y -> (toRational h * x + toRational k * y) / dd)
                        (rCross br direction)
                        (rCross direction ar)
                size = maximum (map abs direction)
            position <- pointND (map fromRational values)
            unit <- pointND (map (\x -> fromRational (x / size)) direction)
            Right (Just (Just (Line position unit)))

checkRay :: Ray -> Either MathError ()
checkRay (Ray a d) = check3 a >> check3 d >> require (norm (coords3 d) > 0) "zero ray direction"

{- | Moller-Trumbore ray intersection; coplanar rays return Nothing because
their hit set is not a unique transverse surface crossing. Degenerate triangles fail.
-}
rayTriangle :: Ray -> (Point3, Point3, Point3) -> Either MathError (Maybe Double)
rayTriangle ray@(Ray o d) (a, b, c) = do
    checkRay ray
    mapM_ check3 [a, b, c]
    let e1 = zipWith (-) (r3 b) (r3 a)
        e2 = zipWith (-) (r3 c) (r3 a)
        p = rCross (r3 d) e2
        det = rDot e1 p
    require (any (/= 0) (rCross e1 e2)) "degenerate ray triangle"
    if det == 0
        then Right Nothing
        else
            let relative = zipWith (-) (r3 o) (r3 a)
                u = rDot relative p / det
                q = rCross relative e1
                v = rDot (r3 d) q / det
                t = rDot e2 q / det
             in if u < 0 || v < 0 || u + v > 1 || t < 0
                    then Right Nothing
                    else do
                        let parameter = fromRational t
                        _ <- checked [parameter]
                        Right (Just parameter)

-- | Slab intersection interval [entry,exit], clipped to the ray t>=0.
rayBox :: Ray -> AABB -> Either MathError (Maybe (Double, Double))
rayBox ray@(Ray o d) box@(AABB lo hi) = do
    checkRay ray
    checkBox box
    require (length (coordsND lo) == 3) "ray box must be 3D"
    let slabs =
            [ if v == 0
                then if x < l || x > h then Nothing else Just (0, 1 / 0)
                else Just (min ((l - x) / v) ((h - x) / v), max ((l - x) / v) ((h - x) / v))
            | (x, v, l, h) <- zip4 (coords3 o) (coords3 d) (coordsND lo) (coordsND hi)
            ]
    case sequence slabs of
        Nothing -> Right Nothing
        Just intervals ->
            let a = maximum (0 : map fst intervals); b = minimum (map snd intervals)
             in if a > b
                    then Right Nothing
                    else do
                        _ <- checked [a, b]
                        Right (Just (a, b))
  where
    zip4 as bs cs ds = [(a, b, c, e) | (((a, b), c), e) <- zip (zip (zip as bs) cs) ds]

-- | Ray-sphere near/far nonnegative parameters; tangent gives equal roots.
raySphere :: Ray -> Sphere -> Either MathError (Maybe (Double, Double))
raySphere ray@(Ray o d) sphere@(Sphere center radius) = do
    checkRay ray
    _ <- sphereSDF sphere o
    let delta = sub (coords3 o) (coords3 center)
        directionNorm = norm (coords3 d)
        direction = map (/ directionNorm) (coords3 d)
        size = max radius (norm delta)
    if size == 0
        then Right (Just (0, 0))
        else do
            let relative = map (/ size) delta
                scaledRadius = radius / size
                b = dot relative direction
                c = dot relative relative - scaledRadius * scaledRadius
                discriminant = b * b - c
            if discriminant < 0
                then Right Nothing
                else
                    let q = -b - if b >= 0 then sqrt discriminant else -sqrt discriminant
                        (u, v) = if q == 0 then (0, 0) else (q, c / q)
                        lo = min u v
                        hi = max u v
                     in if hi < 0
                            then Right Nothing
                            else do
                                values <- checked [(max 0 lo * size) / directionNorm, (hi * size) / directionNorm]
                                case values of { [entry, exit] -> Right (Just (entry, exit)); _ -> Left NonFiniteResult }

-- | Circle intersections: coincidence is distinct from disjointness and tangency.
data CircleIntersection = DisjointCircles | CoincidentCircles | CirclePoints [Point2]
    deriving (Eq, Show)

{- | Given two circles, return DisjointCircles, CoincidentCircles, or CirclePoints for their
intersection. Require valid finite centers and nonnegative bounded radii. Tangency
yields one point; identical zero-radius circles yield their single center.
-}
circleIntersection :: Circle -> Circle -> Either MathError CircleIntersection
circleIntersection (Circle a r) (Circle b s) = do
    mapM_ check2 [a, b]
    require (coord r && coord s && r >= 0 && s >= 0) "invalid circle radius"
    let d = norm2 (sub2 b a)
    if d == 0
        then
            Right (if r == s then if r == 0 then CirclePoints [a] else CoincidentCircles else DisjointCircles)
        else
            if d > r + s || d < abs (r - s)
                then Right DisjointCircles
                else
                    let size = max d (max r s)
                        rn = r / size
                        sn = s / size
                        dn = d / size
                        xn = (rn * rn - sn * sn + dn * dn) / (2 * dn)
                        x = xn * size
                        h = sqrt (max 0 (rn * rn - xn * xn)) * size
                        P2 dx dy = sub2 b a
                        ux = dx / d
                        uy = dy / d
                        mid = add2 a (P2 (x * ux) (x * uy))
                        delta = P2 (-h * uy) (h * ux)
                     in Right (CirclePoints (if h == 0 then [mid] else [add2 mid delta, sub2 mid delta]))

-- | Closed triangle overlap polygon, including isolated tangencies as vertices.
triangleIntersection :: Triangle -> Triangle -> Either MathError [Point2]
triangleIntersection ta@(Triangle a b c) tb@(Triangle d e f) = do
    _ <- triangleLocation ta a
    _ <- triangleLocation tb d
    crossings <-
        mapM
            (\((u, v), (w, x)) -> segmentIntersection u v w x)
            [(x, y) | x <- edges [a, b, c], y <- edges [d, e, f]]
    let hit NoIntersection = []
        hit (IntersectionPoint p) = [p]
        hit (OverlapSegment p q) = [p, q]
        hit CoincidentLine = []
        points =
            nub
                ([p | p <- [a, b, c], inside tb p] ++ [p | p <- [d, e, f], inside ta p] ++ concatMap hit crossings)
        inside tri p = case triangleLocation tri p of Right Outside -> False; Right _ -> True; Left _ -> False
    -- Triangle intersection is convex; order its extreme vertices so the
    -- result can be used directly as a ring (touches retain one/two points).
    let push stack p = case stack of
            y : x : rest | orient x y p /= GT -> push (x : rest) p
            _ -> p : stack
        half = reverse . foldl push []
        ordered = sort points
        hull = if length ordered <= 2 then ordered else init (half ordered) ++ init (half (reverse ordered))
    Right hull

-- | Sphere signed distance (negative inside).
sphereSDF :: Sphere -> Point3 -> Either MathError Double
sphereSDF (Sphere c r) p =
    check3 c
        >> check3 p
        >> require (coord r && r >= 0) "invalid sphere radius"
        >> Right (norm (sub (coords3 p) (coords3 c)) - r)

-- | Axis-aligned box exact signed Euclidean distance in 1..16 dimensions.
boxSDF :: AABB -> PointND -> Either MathError Double
boxSDF box@(AABB a b) p = do
    checkBox box
    checkPair a p
    let q = zipWith3 (\x l h -> abs (x - (l + h) / 2) - (h - l) / 2) (coordsND p) (coordsND a) (coordsND b)
    Right (norm (map (max 0) q) + min 0 (maximum q))

-- | Oriented box distance after validating its orthonormal axes.
obbSDF :: OBB -> Point3 -> Either MathError Double
obbSDF (OBB c axes half) p = do
    mapM_ check3 (c : half : p : axes)
    require (length axes == 3 && all (>= 0) (coords3 half)) "invalid OBB axes/extents"
    require
        ( and
            [ abs (dot (coords3 (axes !! i)) (coords3 (axes !! j)) - if i == j then 1 else 0) < 1e-9
            | i <- [0 .. 2]
            , j <- [0 .. 2]
            ]
        )
        "OBB axes are not orthonormal"
    let local = [dot (sub (coords3 p) (coords3 c)) (coords3 a) | a <- axes]; h = coords3 half
    boxSDF (AABB (PointND (map negate h)) (PointND h)) (PointND local)

-- | Capsule distance from its closed axis minus radius.
capsuleSDF :: Capsule -> Point3 -> Either MathError Double
capsuleSDF (Capsule a b r) p = do
    mapM_ check3 [a, b, p]
    require (coord r && r >= 0) "invalid capsule radius"
    d <-
        pointSegmentDistance (PointND (coords3 p)) (Segment (PointND (coords3 a)) (PointND (coords3 b)))
    Right (d - r)

-- | Exact capped finite-cylinder signed distance.
cylinderSDF :: Cylinder -> Point3 -> Either MathError Double
cylinderSDF (Cylinder a b r) p = do
    mapM_ check3 [a, b, p]
    require (coord r && r >= 0 && a /= b) "invalid cylinder axis/radius"
    let axis = sub (coords3 b) (coords3 a)
        height = norm axis
        v = sub (coords3 p) (coords3 a)
        axial = dot v axis / height
        radial = norm (sub v (scale (axial / height) axis)) - r
        cap = abs (axial - height / 2) - height / 2
    Right (sqrt (max 0 radial ^ (2 :: Int) + max 0 cap ^ (2 :: Int)) + min 0 (max radial cap))

-- | Exact finite-cone distance by reducing to its radial/axial cross-section.
coneSDF :: Cone -> Point3 -> Either MathError Double
coneSDF (Cone apex base r) p = do
    mapM_ check3 [apex, base, p]
    require (coord r && r >= 0 && apex /= base) "invalid cone axis/radius"
    let axis = sub (coords3 base) (coords3 apex)
        h = norm axis
        v = sub (coords3 p) (coords3 apex)
        y = dot v axis / h
        x = norm (sub v (scale (y / h) axis))
        q = PointND [x, y]
    side <- pointSegmentDistance q (Segment (PointND [0, 0]) (PointND [r, h]))
    bottom <- pointSegmentDistance q (Segment (PointND [0, h]) (PointND [r, h]))
    Right ((if y >= 0 && y <= h && x <= r * y / h then -1 else 1) * min side bottom)
