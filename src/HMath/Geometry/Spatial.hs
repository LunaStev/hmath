-- SPDX-License-Identifier: MPL-2.0

{- | Immutable point-cloud spatial indexes. IDs are original zero-based row
indices, duplicate points are retained, range boxes are closed, and nearest
results sort by (distance,ID). Up to 65536 points in dimensions 1..16 are
accepted (quadtrees require 2D, octrees 3D). Hash cells are real hash buckets;
KD, ball, quadrant, packed R-tree, and BVH nodes retain actual hierarchical
bounds. Query pruning is exact, with a caller leaf budget for nearest search.
-}
module HMath.Geometry.Spatial (
    SpatialKind (..),
    PointCloud,
    pointCloud,
    cloudPoints,
    SpatialIndex,
    buildSpatialIndex,
    rangeQuery,
    radiusQuery,
    NeighborQuery (..),
    nearestQuery,
) where

import qualified Data.IntMap.Strict as IntMap
import Data.List (sortOn, transpose)
import qualified Data.Map.Strict as Map
import HMath.Error (MathError (..))
import HMath.Geometry.Internal

-- | Explicit index construction algorithm; hash width must be positive finite.
data SpatialKind = SpatialHash Double | KDTree | BallTree | Quadtree | Octree | RTree | BVH
    deriving (Eq, Show)

-- | Validated homogeneous finite cloud; a nonempty cloud defines its dimension.
newtype PointCloud = Cloud [PointND] deriving (Eq, Show)

data Node = Leaf AABB [(Int, PointND)] | Branch AABB [Node] | Ball AABB [Double] Double [Node]
    deriving (Eq, Show)

{- | Opaque checked spatial-search tree/hash index. Construction and query functions
document dimension/work limits and exactness flags.
-}
data SpatialIndex = Tree Int Node | Hash Int Double (Map.Map [Integer] [(Int, PointND)])
    deriving (Eq, Show)

-- | Construct a nonempty cloud of at most 65536 points, with consistent dimensions.
pointCloud :: [PointND] -> Either MathError PointCloud
pointCloud ps = do
    require (not (null ps) && length ps <= 65536) "point cloud requires 1..65536 points"
    mapM_ (checkPair (firstOr (PointND []) ps)) ps
    Right (Cloud ps)

-- | Original cloud observations.
cloudPoints :: PointCloud -> [PointND]
cloudPoints (Cloud ps) = ps

bounds :: [(Int, PointND)] -> AABB
bounds pts =
    let columns = transpose (map (coordsND . snd) pts)
     in AABB (PointND (map minimum columns)) (PointND (map maximum columns))
nodeBounds :: Node -> AABB
nodeBounds (Leaf b _) = b
nodeBounds (Branch b _) = b
nodeBounds (Ball b _ _ _) = b

{- | Build the named structure. RTree uses sort-tile-recursive leaf packing
(fanout 8); BVH splits longest-axis medians; quadrant trees split cells at
their midplanes with a depth limit of 64 for coincident/near-coincident data.
-}
buildSpatialIndex :: SpatialKind -> PointCloud -> Either MathError SpatialIndex
buildSpatialIndex kind (Cloud ps) = do
    let dim = length (coordsND (firstOr (PointND []) ps)); pts = zip [0 ..] ps
    case kind of
        SpatialHash width -> do
            require
                (finite width && width > 0 && all (finite . (/ width)) (concatMap coordsND ps))
                "invalid spatial hash width/cell coordinate"
            let buckets = Map.fromListWith (++) [(map (floor . (/ width)) (coordsND p), [(i, p)]) | (i, p) <- pts]
            Right (Hash dim width buckets)
        _ -> do
            require (kind /= Quadtree || dim == 2) "quadtree requires 2D"
            require (kind /= Octree || dim == 3) "octree requires 3D"
            Right (Tree dim (build 0 pts))
  where
    build :: Int -> [(Int, PointND)] -> Node
    build depth pts
        | length pts <= 8 = Leaf (bounds pts) pts
        | depth >= 64 = Leaf (bounds pts) pts
        | otherwise =
            let box@(AABB lo hi) = bounds pts
                spans = sub (coordsND hi) (coordsND lo)
                axis = snd (maximum (zip spans [0 :: Int ..]))
                ordered = sortOn ((!! axis) . coordsND . snd) pts
                mid = length pts `div` 2
                halves = [take mid ordered, drop mid ordered]
                recurse groups = map (build (depth + 1)) (filter (not . null) groups)
             in case kind of
                    BallTree ->
                        let columns = transpose (map (coordsND . snd) pts)
                            center = map (\xs -> sum xs / fromIntegral (length xs)) columns
                            radius = maximum [norm (sub (coordsND p) center) | (_, p) <- pts]
                            pivot = snd (maximum [(norm (sub (coordsND p) center), i) | (i, p) <- pts])
                            chosen = coordsND (snd (firstOr (-1, PointND []) (filter ((== pivot) . fst) pts)))
                            sorted = sortOn (\(_, p) -> norm (sub (coordsND p) chosen)) pts
                         in Ball box center radius (recurse [take mid sorted, drop mid sorted])
                    Quadtree -> quadrants box lo hi pts depth
                    Octree -> quadrants box lo hi pts depth
                    RTree ->
                        let count = ceiling (sqrt (fromIntegral (length pts) / 8) :: Double) :: Int
                            sliceSize = max 8 (ceiling (fromIntegral (length pts) / fromIntegral count :: Double))
                            axis2 = if length (coordsND lo) > 1 then 1 else 0
                            tiles =
                                concatMap
                                    (chunks 8 . sortOn ((!! axis2) . coordsND . snd))
                                    (chunks sliceSize (sortOn (firstOr 0 . coordsND . snd) pts))
                         in pack [Leaf (bounds tile) tile | tile <- tiles]
                    _ -> Branch box (recurse halves)
    quadrants box lo hi pts depth =
        let mids = map (/ 2) (plus (coordsND lo) (coordsND hi))
            groups = Map.elems (Map.fromListWith (++) [(zipWith (>) (coordsND p) mids, [(i, p)]) | (i, p) <- pts])
         in if length groups <= 1 then Leaf box pts else Branch box (map (build (depth + 1)) groups)
    pack [] = Leaf (AABB (PointND []) (PointND [])) []
    pack [node] = node
    pack nodes
        | length nodes <= 8 = Branch (unionBounds nodes) nodes
        | otherwise = pack [Branch (unionBounds group) group | group <- chunks 8 nodes]
    unionBounds nodes =
        let boxes = map nodeBounds nodes
            lows = [coordsND low | AABB low _ <- boxes]
            highs = [coordsND high | AABB _ high <- boxes]
         in AABB (PointND (map minimum (transpose lows))) (PointND (map maximum (transpose highs)))
    chunks _ [] = []
    chunks k xs = take k xs : chunks k (drop k xs)

checkRange :: Int -> AABB -> Either MathError ()
checkRange dim (AABB lo hi) =
    checkPair lo hi
        >> require
            (length (coordsND lo) == dim && and (zipWith (<=) (coordsND lo) (coordsND hi)))
            "invalid range box/dimension"
overlaps :: AABB -> AABB -> Bool
overlaps (AABB a b) (AABB c d) = and (zipWith (<=) (coordsND a) (coordsND d)) && and (zipWith (<=) (coordsND c) (coordsND b))
inBox :: AABB -> PointND -> Bool
inBox (AABB a b) p = and (zipWith3 (\x lo hi -> x >= lo && x <= hi) (coordsND p) (coordsND a) (coordsND b))

{- | Closed range search, sorted original IDs. Hash queries inspect occupied
bucket bounds, avoiding an unbounded Cartesian enumeration of empty cells.
-}
rangeQuery :: SpatialIndex -> AABB -> Either MathError [Int]
rangeQuery index range = do
    let dim = case index of Tree d _ -> d; Hash d _ _ -> d
    checkRange dim range
    let answer = case index of
            Tree _ root -> walk root
            Hash _ _ buckets -> concatMap (filter (inBox range . snd)) (Map.elems buckets)
    Right (sortOn id (map fst answer))
  where
    walk node | not (overlaps range (nodeBounds node)) = []
    walk (Leaf _ pts) = filter (inBox range . snd) pts
    walk (Branch _ children) = concatMap walk children
    walk (Ball _ _ _ children) = concatMap walk children

boxDistance :: PointND -> AABB -> Double
boxDistance p (AABB a b) =
    norm (zipWith3 (\x lo hi -> max 0 (max (lo - x) (x - hi))) (coordsND p) (coordsND a) (coordsND b))

{- | A budgeted nearest-neighbor answer; False means unexplored leaves may
improve the answer. Returned distances are exact Double Euclidean distances.
-}
data NeighborQuery = NeighborQuery
    { queryNeighbors :: [(Int, Double)]
    -- ^ Nearest candidate IDs paired with Euclidean distances, in increasing distance order.
    , queryLeaves :: Int
    -- ^ Number of visited spatial-index leaves charged to the query budget.
    , queryExhaustive :: Bool
    -- ^ True only when unexplored nodes cannot improve the returned neighbors; False marks a budget-limited approximation.
    }
    deriving (Eq, Show)

{- | Given neighbor count k, positive leaf budget, index, then query point, search for
nearest neighbors. Require matching finite coordinate dimension and 1\<=k\<=65536. The
result reports neighbors, visited leaves and whether search was exhaustive; an
exhausted budget is not an exact-neighbor guarantee.
-}
nearestQuery :: Int -> Int -> SpatialIndex -> PointND -> Either MathError NeighborQuery
nearestQuery k budget index p = do
    checkND p
    let (dim, roots) = case index of
            Tree d root -> (d, [root])
            Hash d _ buckets -> (d, [Leaf (bounds pts) pts | pts <- Map.elems buckets])
    require
        (length (coordsND p) == dim && k > 0 && k <= 65536 && budget > 0)
        "invalid nearest dimension/count/budget"
    let search [] best used = NeighborQuery best used True
        search pending best used
            | used >= budget = NeighborQuery best used False
            | otherwise =
                let ordered = sortOn (boxDistance p . nodeBounds) pending
                    node = firstOr (Leaf (AABB (PointND []) (PointND [])) []) ordered
                    rest = drop 1 ordered
                    bound = if length best < k then 1 / 0 else snd (last best)
                 in if lower node > bound
                        then search rest best used
                        else case node of
                            Leaf _ pts ->
                                let candidates =
                                        take
                                            k
                                            (sortOn (\(i, d) -> (d, i)) (best ++ [(i, norm (sub (coordsND p) (coordsND q))) | (i, q) <- pts]))
                                 in search rest candidates (used + 1)
                            Branch _ children -> search (children ++ rest) best used
                            Ball _ _ _ children -> search (children ++ rest) best used
        lower (Ball box center radius _) = max (boxDistance p box) (norm (sub (coordsND p) center) - radius)
        lower node = boxDistance p (nodeBounds node)
    Right (search roots [] 0)

-- | Exact closed radius query; uses the index range query then Euclidean filtering.
radiusQuery :: SpatialIndex -> PointND -> Double -> Either MathError [Int]
radiusQuery index p radius = do
    checkND p
    require (coord radius && radius >= 0) "invalid query radius"
    let lo = PointND (map (\x -> x - radius) (coordsND p)); hi = PointND (map (+ radius) (coordsND p))
    ids <- rangeQuery index (AABB lo hi)
    let points = case index of Hash _ _ buckets -> concat (Map.elems buckets); Tree _ root -> allPoints root
        indexed = IntMap.fromList points
    Right
        [i | i <- ids, Just q <- [IntMap.lookup i indexed], norm (sub (coordsND p) (coordsND q)) <= radius]
  where
    allPoints (Leaf _ pts) = pts
    allPoints (Branch _ children) = concatMap allPoints children
    allPoints (Ball _ _ _ children) = concatMap allPoints children
