-- SPDX-License-Identifier: MPL-2.0

{- | Deterministic Bowyer-Watson Delaunay triangulation (at most 256 unique
points), edge-flip constrained Delaunay triangulation, polygon ear clipping,
and bounded Voronoi cells. Triangles use original zero-based point indices
and counterclockwise orientation. Collinear clouds return no triangles.
Constraints must be noncrossing input-vertex segments with no interior input
vertices; they do not specify holes or discard the outer convex hull. Exact
Rational orientation/incircle signs avoid epsilon topology decisions.
-}
module HMath.Geometry.Triangulation (
    IndexedTriangle,
    delaunay,
    constrainedDelaunay,
    voronoi,
    earClip,
) where

import Control.Monad (foldM)
import Data.List (delete, nub, sort)
import HMath.Error (MathError (..))
import HMath.Geometry.Internal
import HMath.Geometry.Primitives (Intersection2 (..), segmentIntersection)

-- | Counterclockwise indices into the caller's input point list.
type IndexedTriangle = (Int, Int, Int)

triEdges :: IndexedTriangle -> [(Int, Int)]
triEdges (a, b, c) = [(a, b), (b, c), (c, a)]
canonical :: (Int, Int) -> (Int, Int)
canonical (a, b) = if a < b then (a, b) else (b, a)
orientTri :: [Point2] -> IndexedTriangle -> IndexedTriangle
orientTri ps (a, b, c) = if orient (ps !! a) (ps !! b) (ps !! c) == LT then (a, c, b) else (a, b, c)
insideCircle :: Point2 -> Point2 -> Point2 -> Point2 -> Ordering
insideCircle (P2 ax ay) (P2 bx by) (P2 cx cy) (P2 px py) =
    let a = toRational ax - toRational px
        b = toRational ay - toRational py
        c = toRational bx - toRational px
        d = toRational by - toRational py
        e = toRational cx - toRational px
        f = toRational cy - toRational py
        determinant =
            (a * a + b * b) * (c * f - d * e)
                - (c * c + d * d) * (a * f - b * e)
                + (e * e + f * f) * (a * d - b * c)
        orientationSign = orientExact (P2 ax ay) (P2 bx by) (P2 cx cy)
     in compare (if orientationSign > 0 then determinant else -determinant) 0
validateCloud :: [Point2] -> Either MathError ()
validateCloud ps = do
    require (length ps <= 256) "triangulation reference budget is 256 points"
    mapM_ check2 ps
    require (length (nub ps) == length ps) "duplicate triangulation points"

{- | Incremental cavity replacement. Cocircular insertion uses a strict
in-circle predicate, giving a deterministic (not unique) valid diagonal.
-}
delaunay :: [Point2] -> Either MathError [IndexedTriangle]
delaunay ps = do
    validateCloud ps
    if length ps < 3 || all (\p -> orient (firstOr (P2 0 0) ps) (ps !! 1) p == EQ) (drop 2 ps)
        then Right []
        else do
            let xs = [x | P2 x _ <- ps]
                ys = [y | P2 _ y <- ps]
                cx = (minimum xs + maximum xs) / 2
                cy = (minimum ys + maximum ys) / 2
                span' = max (maximum xs - minimum xs) (maximum ys - minimum ys)
                s = max span' 1e-100
                n = length ps
                allPoints = ps ++ [P2 (cx - 32 * s) (cy - 16 * s), P2 (cx + 32 * s) (cy - 16 * s), P2 cx (cy + 32 * s)]
                insert active i =
                    let p = allPoints !! i
                        bad =
                            [t | t@(a, b, c) <- active, insideCircle (allPoints !! a) (allPoints !! b) (allPoints !! c) p == GT]
                        allEdges = concatMap triEdges bad
                        boundary = [e | e <- allEdges, length (filter ((== canonical e) . canonical) allEdges) == 1]
                        created =
                            [ orientTri allPoints (a, b, i) | (a, b) <- boundary, orient (allPoints !! a) (allPoints !! b) p /= EQ
                            ]
                     in filter (`notElem` bad) active ++ created
                triangles = foldl insert [(n, n + 1, n + 2)] [0 .. n - 1]
            Right (sort [t | t@(a, b, c) <- triangles, a < n, b < n, c < n])

{- | Insert noncrossing constrained edges by convex quadrilateral flips, then
Lawson-flip every unconstrained illegal edge. Work is bounded explicitly.
-}
constrainedDelaunay :: [Point2] -> [(Int, Int)] -> Either MathError [IndexedTriangle]
constrainedDelaunay ps constraints = do
    validateCloud ps
    let n = length ps; cs = nub (map canonical constraints)
    require
        (length cs <= 512 && all (\(a, b) -> a >= 0 && b < n && a < b) cs)
        "invalid constraint indices/budget"
    require
        ( and
            [not (onSegment (ps !! a) (ps !! b) (ps !! i)) | (a, b) <- cs, i <- [0 .. n - 1], i /= a, i /= b]
        )
        "constraint contains an interior input point"
    checks <-
        mapM
            (\((a, b), (c, d)) -> segmentIntersection (ps !! a) (ps !! b) (ps !! c) (ps !! d))
            [(x, y) | x <- cs, y <- cs, x < y, not (shared x y)]
    require (all (== NoIntersection) checks) "constraints intersect"
    initial <- delaunay ps
    (inserted, _) <- foldM insert (initial, []) cs
    legalize inserted cs 0
  where
    shared (a, b) (c, d) = a == c || a == d || b == c || b == d
    uniqueEdges ts = nub (map canonical (concatMap triEdges ts))
    adjacent edge ts = [t | t <- ts, edge `elem` map canonical (triEdges t)]
    opposite (a, b) (x, y, z) = firstOr a (filter (\p -> p /= a && p /= b) [x, y, z])
    flipEdge edge@(a, b) ts = case adjacent edge ts of
        [u, v] ->
            let c = opposite edge u; d = opposite edge v
             in if orient (ps !! c) (ps !! d) (ps !! a) == orient (ps !! c) (ps !! d) (ps !! b)
                    || orient (ps !! c) (ps !! d) (ps !! a) == EQ
                    || orient (ps !! c) (ps !! d) (ps !! b) == EQ
                    then Nothing
                    else Just (filter (\t -> t /= u && t /= v) ts ++ [orientTri ps (c, d, a), orientTri ps (d, c, b)])
        _ -> Nothing
    insert (ts, locked) edge = do
        out <- seek ts 0
        Right (out, edge : locked)
      where
        seek current budget
            | edge `elem` uniqueEdges current = Right current
            | budget >= 200000 = Left (NonConvergence "constrained edge insertion" budget)
            | otherwise =
                let (a, b) = edge
                    crossing =
                        [ e
                        | e@(c, d) <- uniqueEdges current
                        , e `notElem` locked
                        , not (shared edge e)
                        , orient (ps !! a) (ps !! b) (ps !! c) /= orient (ps !! a) (ps !! b) (ps !! d)
                        , orient (ps !! c) (ps !! d) (ps !! a) /= orient (ps !! c) (ps !! d) (ps !! b)
                        ]
                    candidates = [out | e <- crossing, Just out <- [flipEdge e current]]
                 in case candidates of
                        [] -> Left (DomainError "constraint cannot be inserted into this triangulation")
                        out : _ -> seek out (budget + 1)
    legalize ts locked budget
        | budget >= 200000 = Left (NonConvergence "constrained Delaunay legalization" budget)
        | otherwise =
            let illegal =
                    [ out
                    | edge <- uniqueEdges ts
                    , edge `notElem` locked
                    , [(a, b, c), v] <- [adjacent edge ts]
                    , let d = opposite edge v
                    , insideCircle (ps !! a) (ps !! b) (ps !! c) (ps !! d) == GT
                    , Just out <- [flipEdge edge ts]
                    ]
             in case illegal of [] -> Right ts; out : _ -> legalize out locked (budget + 1)

{- | Voronoi cells clipped to an ordered nonzero rectangle, one polygon ring per
site (empty only if the site lies outside the clipping rectangle). Direct
pairwise half-plane clipping is O(n^3), limited to 128 sites. Bisector
classification and intersections use exact Rational arithmetic; final vertices
are rounded once to Double.
-}
voronoi :: Rectangle -> [Point2] -> Either MathError [[Point2]]
voronoi (Rectangle lo@(P2 x0 y0) hi@(P2 x1 y1)) sites = do
    validateCloud sites
    mapM_ check2 [lo, hi]
    require (length sites <= 128 && x0 < x1 && y0 < y1) "invalid Voronoi rectangle/site budget"
    mapM cell sites
  where
    rational (P2 x y) = (toRational x, toRational y)
    initial = map rational [P2 x0 y0, P2 x1 y0, P2 x1 y1, P2 x0 y1]
    cell site =
        mapM
            (\(x, y) -> point2 (fromRational x) (fromRational y))
            (foldl (clip (rational site)) initial (map rational (filter (/= site) sites)))
    clip _ [] _ = []
    clip (sx, sy) input (ox, oy) =
        -- Shift the bisector to the first site. Exact rational accumulation
        -- prevents subtracting two huge squared world-coordinate norms and
        -- rounds intersections only once, when the final cell is emitted.
        let nx = ox - sx
            ny = oy - sy
            offset = (nx * nx + ny * ny) / 2
            value (px, py) = (px - sx) * nx + (py - sy) * ny - offset
            crossing a@(ax, ay) b@(bx, by) =
                let t = value a / (value a - value b) in (ax + t * (bx - ax), ay + t * (by - ay))
         in concat
                [ case (value a <= 0, value b <= 0) of
                    (True, True) -> [b]
                    (True, False) -> [crossing a b]
                    (False, True) -> [crossing a b, b]
                    _ -> []
                | (a, b) <- edges input
                ]

{- | Ear clipping of a simple polygon. Collinear boundary vertices are removed
from the active ring; returned triangles retain original indices.
-}
earClip :: Polygon -> Either MathError [IndexedTriangle]
earClip poly = do
    points <- checkPolygon poly
    let indices = if signedArea points < 0 then reverse [0 .. length points - 1] else [0 .. length points - 1]
    clip points indices []
  where
    clip _ [] acc = Right (reverse acc)
    clip _ [_] acc = Right (reverse acc)
    clip _ [_, _] acc = Right (reverse acc)
    clip _ [a, b, c] acc = Right (reverse ((a, b, c) : acc))
    clip ps ring acc =
        let triples = zip3 (last ring : init ring) ring (drop 1 ring ++ [firstOr 0 ring])
            collinear = [b | (a, b, c) <- triples, orient (ps !! a) (ps !! b) (ps !! c) == EQ]
            inside a b c p = all (/= LT) [orient a b p, orient b c p, orient c a p]
            ears =
                [ (a, b, c)
                | (a, b, c) <- triples
                , orient (ps !! a) (ps !! b) (ps !! c) == GT
                , all (\i -> i `elem` [a, b, c] || not (inside (ps !! a) (ps !! b) (ps !! c) (ps !! i))) ring
                ]
         in case collinear of
                b : _ -> clip ps (delete b ring) acc
                [] -> case ears of
                    [] -> Left (NonConvergence "ear clipping" (length ring))
                    t@(_, b, _) : _ -> clip ps (delete b ring) (t : acc)
