-- SPDX-License-Identifier: MPL-2.0

{- | Planar hulls, polygon measurements and Boolean arrangements. Hulls return
unique counterclockwise extreme vertices, omitting collinear interior points;
0/1/2-point hulls are valid. Boolean inputs are simple polygons with at most
128 vertices each. They use exact Rational edge splitting and local side
classification, and return oriented rings: counterclockwise exterior rings,
clockwise holes. Rings may share isolated boundary vertices. Coordinates are
rounded to Double only at the output. This is a bounded reference arrangement,
not a sweep-line implementation.
-}
module HMath.Geometry.Polygon (
    HullAlgorithm (..),
    convexHull,
    polygonArea,
    polygonCentroid,
    shoelace,
    BooleanOperation (..),
    polygonBoolean,
    clipPolygon,
    minimumBoundingCircle,
    minimumBoundingRectangle,
    minkowskiSum,
) where

import Control.Monad (foldM)
import Data.List (delete, maximumBy, minimumBy, nub, sort)
import Data.Ord (comparing)
import HMath.Error (MathError (..))
import HMath.Geometry.Internal
import HMath.Geometry.Primitives (circumcenter)

-- | Four distinct planar convex-hull construction algorithms.
data HullAlgorithm = GrahamScan | MonotoneChain | Quickhull | GiftWrapping deriving (Eq, Show)

-- | Convex hull with at most 4096 input points. Exact orientation breaks degeneracies.
convexHull :: HullAlgorithm -> [Point2] -> Either MathError [Point2]
convexHull algorithm input = do
    require (length input <= 4096) "hull reference budget exceeded"
    mapM_ check2 input
    let ps = sort (nub input)
    Right $
        if length ps < 3
            then ps
            else canonical $ case algorithm of
                MonotoneChain -> chain ps
                GrahamScan -> graham ps
                Quickhull -> quick ps
                GiftWrapping -> gift ps
  where
    canonical xs = let ys = ccw xs; p = minimum ys; (a, b) = break (== p) ys in b ++ a
    push stack p = case stack of
        b : a : rest | orient a b p /= GT -> push (a : rest) p
        _ -> p : stack
    half = reverse . foldl push []
    chain ps = init (half ps) ++ init (half (reverse ps))
    graham ps =
        let pivot = minimumBy (comparing (\(P2 x y) -> (y, x))) ps
            polar a b = case orient pivot a b of
                GT -> LT
                LT -> GT
                EQ -> compare (dot2 (sub2 a pivot) (sub2 a pivot)) (dot2 (sub2 b pivot) (sub2 b pivot))
            ordered = sortByLocal polar (filter (/= pivot) ps)
         in reverse (foldl push [pivot] ordered)
    quick ps =
        let a = firstOr (P2 0 0) ps
            b = last ps
            side u v qs = case filter (\p -> orient u v p == GT) qs of
                [] -> []
                inside ->
                    let p = maximumBy (comparing (\q -> orientExact u v q)) inside
                     in side u p inside ++ [p] ++ side p v inside
         in [a] ++ side a b ps ++ [b] ++ side b a ps
    gift ps =
        let start = firstOr (P2 0 0) ps
            walk p acc =
                let candidates = filter (/= p) ps
                    better a b = case orient p a b of LT -> b; GT -> a; EQ -> if norm2 (sub2 b p) > norm2 (sub2 a p) then b else a
                    next = foldl1 better candidates
                 in if next == start then acc ++ [p] else walk next (acc ++ [p])
         in walk start []
    sortByLocal cmp = foldr (\x xs -> let (a, b) = span (\y -> cmp x y == GT) xs in a ++ [x] ++ b) []

-- | Signed shoelace area; clockwise polygons have negative area.
shoelace :: Polygon -> Either MathError Double
shoelace poly = signedArea <$> checkPolygon poly

-- | Unsigned simple polygon area.
polygonArea :: Polygon -> Either MathError Double
polygonArea = fmap abs . shoelace

-- | Area-weighted centroid; works for nonconvex simple polygons.
polygonCentroid :: Polygon -> Either MathError Point2
polygonCentroid poly = do
    ps <- checkPolygon poly
    let rational (P2 x y) = (toRational x, toRational y)
        es = edges (map rational ps)
        terms = [(ax * by - ay * bx, ax + bx, ay + by) | ((ax, ay), (bx, by)) <- es]
        area6 = 3 * sum [c | (c, _, _) <- terms]
    point2
        (fromRational (sum [c * x | (c, x, _) <- terms] / area6))
        (fromRational (sum [c * y | (c, _, y) <- terms] / area6))

-- | Boolean set operation on closed polygon regions; ring boundaries have zero area.
data BooleanOperation = Union | Intersection | Difference deriving (Eq, Show)

type RPoint = (Rational, Rational)
rp :: Point2 -> RPoint
rp (P2 x y) = (toRational x, toRational y)
radd :: RPoint -> RPoint -> RPoint
radd (a, b) (x, y) = (a + x, b + y)
rsub :: RPoint -> RPoint -> RPoint
rsub (a, b) (x, y) = (a - x, b - y)
rscale :: Rational -> RPoint -> RPoint
rscale t (x, y) = (t * x, t * y)
rcross :: RPoint -> RPoint -> Rational
rcross (a, b) (x, y) = a * y - b * x
rdot :: RPoint -> RPoint -> Rational
rdot (a, b) (x, y) = a * x + b * y
rOn :: RPoint -> RPoint -> RPoint -> Bool
rOn a b p = rcross (rsub b a) (rsub p a) == 0 && rdot (rsub p a) (rsub p b) <= 0
rInside :: [RPoint] -> RPoint -> Bool
rInside ps (x, y) =
    odd
        ( length
            [ ()
            | ((ax, ay), (bx, by)) <- edges ps
            , (ay > y) /= (by > y)
            , x < (bx - ax) * (y - ay) / (by - ay) + ax
            ]
        )

{- | Exact edge-arrangement Boolean. Empty output is allowed, including an
intersection that consists only of points/segments (zero-area components).
-}
polygonBoolean :: BooleanOperation -> Polygon -> Polygon -> Either MathError [Polygon]
polygonBoolean operation a b = do
    pa <- checkPolygon a
    pb <- checkPolygon b
    require (length pa <= 128 && length pb <= 128) "polygon Boolean budget is 128 vertices per input"
    let aa = map rp (ccw pa)
        bb = map rp (ccw pb)
        allEdges = edges aa ++ edges bb
        splitEdge (u, v) =
            let dir = rsub v u
                denom = rdot dir dir
                params = [rdot (rsub p u) dir / denom | (c, d) <- allEdges, p <- intersections (u, v) (c, d), rOn u v p]
                ts = sort (nub (0 : 1 : params))
                at t = radd u (rscale t dir)
             in zip (map at (init ts)) (map at (drop 1 ts))
        pieces = nub [if u < v then (u, v) else (v, u) | e <- allEdges, (u, v) <- splitEdge e, u /= v]
        truth x y = case operation of Union -> x || y; Intersection -> x && y; Difference -> x && not y
        boundary (u, v) =
            let midpoint = rscale (1 / 2) (radd u v)
                (dx, dy) = rsub v u
                normal = (-dy, dx)
                cuts =
                    [ abs t
                    | (c, d) <- allEdges
                    , let edge = rsub d c
                    , let den = rcross normal edge
                    , den /= 0
                    , let t = rcross (rsub c midpoint) edge / den
                    , let s = rcross (rsub c midpoint) normal / den
                    , t /= 0
                    , s >= 0
                    , s <= 1
                    ]
                epsilon = minimum (1 : cuts) / 2
                l = radd midpoint (rscale epsilon normal)
                r = rsub midpoint (rscale epsilon normal)
                left = truth (rInside aa l) (rInside bb l)
                right = truth (rInside aa r) (rInside bb r)
             in if left == right then [] else if left then [(u, v)] else [(v, u)]
        segments = concatMap boundary pieces
    loops <- stitch segments
    mapM (\ring -> Polygon <$> mapM (\(x, y) -> point2 (fromRational x) (fromRational y)) ring) loops
  where
    intersections (a0, b0) (c0, d0) =
        let u = rsub b0 a0; v = rsub d0 c0; den = rcross u v; w = rsub c0 a0
         in if den == 0
                then if rcross w u == 0 then filter (\p -> rOn a0 b0 p && rOn c0 d0 p) [a0, b0, c0, d0] else []
                else
                    let t = rcross w v / den; s = rcross w u / den
                     in if t >= 0 && t <= 1 && s >= 0 && s <= 1 then [radd a0 (rscale t u)] else []
    stitch [] = Right []
    stitch ((start, next) : remaining) = do
        (ring, rest) <- walk start start next [start] remaining (length remaining + 2)
        others <- stitch rest
        Right (if length ring >= 3 then ring : others else others)
    walk start before current acc remaining budget
        | current == start = Right (acc, remaining)
        | budget <= 0 = Left (NonConvergence "polygon ring stitching" 0)
        | otherwise = case filter ((== current) . fst) remaining of
            [] -> Left (DomainError "polygon arrangement has an open boundary")
            candidates ->
                let incoming = rsub current before
                    turn (_, p) =
                        let (x, y) = rsub p current; (u, v) = incoming
                         in atan2 (fromRational (u * y - v * x) :: Double) (fromRational (u * x + v * y))
                    chosen = maximumBy (comparing turn) candidates
                 in walk start current (snd chosen) (acc ++ [current]) (delete chosen remaining) (budget - 1)

{- | Sutherland-Hodgman clipping against a convex CCW/clockwise clip polygon.
Output may be empty; nonconvex clippers fail instead of silently corrupting output.
-}
clipPolygon :: Polygon -> Polygon -> Either MathError [Point2]
clipPolygon subject clipper = do
    ps <- checkPolygon subject
    cs <- ccw <$> checkPolygon clipper
    require (and [orient a b c /= LT | (a, b, c) <- triples cs]) "clip polygon is not convex"
    foldM clip ps (edges cs)
  where
    triples xs = zip3 xs (drop 1 xs ++ take 1 xs) (drop 2 xs ++ take 2 xs)
    clip [] _ = Right []
    clip input (a, b) =
        fmap concat $
            mapM
                ( \(u, v) ->
                    let iu = orient a b u /= LT
                        iv = orient a b v /= LT
                        hit = do
                            result <- lineIntersectionLocal u (sub2 v u) a (sub2 b a)
                            case result of { Just p -> Right [p]; Nothing -> Right [] }
                     in case (iu, iv) of
                            (True, True) -> Right [v]
                            (True, False) -> hit
                            (False, True) -> (++ [v]) <$> hit
                            _ -> Right []
                )
                (edges input)
    lineIntersectionLocal a u b v =
        let den = orientExact (P2 0 0) u v
         in if den == 0
                then Right Nothing
                else
                    let t = fromRational (orientExact (P2 0 0) (sub2 b a) v / den); P2 x y = add2 a (scale2 t u)
                     in Just <$> point2 x y

{- | Deterministic incremental minimum enclosing circle, O(n^3), at most 256
points. Each violated boundary introduces a 1-, 2-, or 3-point support.
-}
minimumBoundingCircle :: [Point2] -> Either MathError Circle
minimumBoundingCircle ps = do
    require (not (null ps) && length ps <= 256) "minimum circle requires 1..256 points"
    mapM_ check2 ps
    foldM outer (Circle (firstOr (P2 0 0) ps) 0) (zip [0 :: Int ..] ps)
  where
    contains (Circle c r) p = norm2 (sub2 p c) <= r * (1 + 1e-12)
    diameter a b = Circle (scale2 0.5 (add2 a b)) (norm2 (sub2 a b) / 2)
    outer circle (i, p)
        | contains circle p = Right circle
        | otherwise = foldM (middle p) (Circle p 0) (zip [0 :: Int ..] (take i ps))
    middle p circle (j, q)
        | contains circle q = Right circle
        | otherwise = foldM (inner p q) (diameter p q) (take j ps)
    inner p q circle r
        | contains circle r = Right circle
        | orient p q r == EQ =
            Right
                (maximumBy (comparing (\(Circle _ radius) -> radius)) [diameter p q, diameter p r, diameter q r])
        | otherwise = do center <- circumcenter (Triangle p q r); Right (Circle center (norm2 (sub2 p center)))

{- | Minimum-area oriented enclosing rectangle. Testing every hull edge uses
the rotating-calipers extremal-orientation theorem; the reference scans all
vertices for each orientation (O(h^2)), at most 4096 points.
-}
minimumBoundingRectangle :: [Point2] -> Either MathError [Point2]
minimumBoundingRectangle ps = do
    hull <- convexHull MonotoneChain ps
    require (not (null hull)) "empty bounding rectangle"
    Right $
        if length hull == 1
            then replicate 4 (firstOr (P2 0 0) hull)
            else snd (minimumBy (comparing fst) [candidate a b | (a, b) <- edges hull])
  where
    candidate a b =
        let d = sub2 b a
            P2 dx dy = d
            size = norm2 d
            ux = dx / size
            uy = dy / size
            u = P2 ux uy
            v = P2 (-uy) ux
            xs = map (dot2 u) ps
            ys = map (dot2 v) ps
            lo = minimum xs
            hi = maximum xs
            bottom = minimum ys
            top = maximum ys
         in ( (hi - lo) * (top - bottom)
            , [add2 (scale2 x u) (scale2 y v) | (x, y) <- [(lo, bottom), (hi, bottom), (hi, top), (lo, top)]]
            )

{- | Convex Minkowski sum, via pairwise sums followed by a hull. Nonconvex
inputs are deliberately convexified; at most 64 vertices per operand.
-}
minkowskiSum :: [Point2] -> [Point2] -> Either MathError [Point2]
minkowskiSum a b = do
    require
        (not (null a || null b) && length a <= 64 && length b <= 64)
        "Minkowski sum requires 1..64 points per operand"
    mapM_ check2 (a ++ b)
    convexHull MonotoneChain [add2 x y | x <- a, y <- b]
