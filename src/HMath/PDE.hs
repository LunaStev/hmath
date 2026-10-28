-- SPDX-License-Identifier: MPL-2.0

{- | Structured-grid reference PDEs in one, two or three spatial dimensions.
Coordinates use consistent caller-selected length units; diffusivity is L²/T,
velocity L/T and reaction 1/T. Nodes are row-major, last axis fastest.
Nonperiodic axes include both endpoints; periodic axes exclude the upper
endpoint. Boundary derivatives are outward normal derivatives, not fluxes.

FD uses nodal kappa*(-Laplacian); FV uses conservative arithmetic face kappa
and half control volumes at physical faces. Q1 FEM uses two-point tensor
Gauss quadrature, a consistent mass matrix, and natural boundary integrals
(cf. <https://mfem.org/tutorial/fem/>). FEM supports nonperiodic grids.
Spectral paths require periodic axes. Sparse assembly is bounded to 32768
nodes (FEM 2048); dense reference solves/time evolution to 1024 nodes.
-}
module HMath.PDE (
    Grid,
    grid,
    gridShape,
    gridCoordinates,
    gridSpacing,
    flattenIndex,
    unflattenIndex,
    Boundary (..),
    Discretization (..),
    PDEOperator,
    assemblePDE,
    pdeStiffness,
    pdeMass,
    pdeBoundaryLoad,
    PDEResult (..),
    solveElliptic,
    poisson,
    laplace,
    helmholtz,
    spatialGradient,
    laplacianStencil,
    spectralDerivative,
    spectralLaplacian,
    spectralPoisson,
    pseudoSpectralDiffusion,
    methodOfLines,
    heat,
    diffusion,
    wave,
    advection,
    advectionDiffusion,
    stabilityLimit,
    cflNumber,
    manufacturedError,
) where

import Control.Monad (foldM)
import Data.Complex (Complex ((:+)), magnitude, realPart)
import qualified Data.Map.Strict as Map
import HMath.Error (MathError (..))
import qualified HMath.Fourier as F
import qualified HMath.ODE as O
import HMath.Signal.Internal
import qualified HMath.Sparse as S

-- | Opaque Cartesian grid with positive representable spacings and 1..3 axes.
data Grid = Grid [Int] [(Double, Double)] [Bool] [Double] deriving (Eq, Show)

-- | Constant essential value, outward derivative, a*u+b*du/dn=c, or paired periodic faces.
data Boundary = Dirichlet Double | Neumann Double | Robin Double Double Double | Periodic
    deriving (Eq, Show)

-- | Nodal nondivergence FD, conservative face-flux FV, or tensor-product Q1 Galerkin FEM.
data Discretization = FiniteDifference | FiniteVolume | FiniteElement deriving (Eq, Show)

-- | Opaque assembled stiffness, source mass matrix, boundary load and essential constraints.
data PDEOperator = PDEOperator Grid (S.Sparse Double) (S.Sparse Double) [Double] [(Int, Double)]
    deriving (Eq, Show)

-- | Nodal solution with independently recomputed infinity residual; errorEstimate reports backward residual only.
data PDEResult = PDEResult {pdeValues :: [Double], pdeResidual :: Double, pdeErrorEstimate :: Double}
    deriving (Eq, Show)

-- | Construct a grid with >=3 nodes per axis; reject overflowing counts and rounded-away duplicate coordinates.
grid :: [Int] -> [(Double, Double)] -> [Bool] -> Either MathError Grid
grid dims bounds periodic = do
    require
        ( length dims >= 1
            && length dims <= 3
            && length bounds == length dims
            && length periodic == length dims
            && all (>= 3) dims
            && product (map toInteger dims) <= 32768
        )
        "invalid PDE grid dimensions (1..3 axes, >=3 nodes/axis, <=32768 total)"
    let spacing = [(b - a) / fromIntegral (if p then n else n - 1) | (n, (a, b), p) <- zip3 dims bounds periodic]
    require
        (all (\(a, b) -> finite a && finite b && a < b) bounds && all (\h -> finite h && h > 0) spacing)
        "invalid PDE bounds/spacing"
    let axes = [[a + fromIntegral i * h | i <- [0 .. n - 1]] | (n, (a, _), h) <- zip3 dims bounds spacing]
    require
        (all (\xs -> all finite xs && and (zipWith (<) xs (drop 1 xs))) axes)
        "rounded-away/nonfinite PDE coordinates"
    Right (Grid dims bounds periodic spacing)

-- | Number of nodes along each axis, preserving last-axis-fastest storage order.
gridShape :: Grid -> [Int]
gridShape (Grid dims _ _ _) = dims

-- | Positive uniform distance between adjacent nodes on each axis.
gridSpacing :: Grid -> [Double]
gridSpacing (Grid _ _ _ hs) = hs

strides :: [Int] -> [Int]
strides dims = drop 1 (scanr (*) 1 dims)

-- | Checked conversion of zero-based multidimensional node coordinates to a row-major flat index.
flattenIndex :: Grid -> [Int] -> Either MathError Int
flattenIndex (Grid dims _ _ _) indices = do
    require
        (length indices == length dims && and (zipWith (\i n -> i >= 0 && i < n) indices dims))
        "PDE index outside grid"
    Right (sum (zipWith (*) indices (strides dims)))

-- | Inverse checked row-major index conversion.
unflattenIndex :: Grid -> Int -> Either MathError [Int]
unflattenIndex (Grid dims _ _ _) i = do
    require (i >= 0 && i < product dims) "PDE flat index outside grid"
    Right (zipWith (\s n -> i `div` s `mod` n) (strides dims) dims)

-- | Physical coordinates in flat storage order; periodic upper endpoints are omitted.
gridCoordinates :: Grid -> [[Double]]
gridCoordinates (Grid dims bounds _ hs) =
    [ [a + fromIntegral (i `div` s `mod` n) * h | ((a, _), h, s, n) <- zip4 bounds hs (strides dims) dims]
    | i <- [0 .. product dims - 1]
    ]
  where
    zip4 as bs cs ds = zipWith (\(a, b) (c, d) -> (a, b, c, d)) (zip as bs) (zip cs ds)

validateBoundary :: Grid -> [(Boundary, Boundary)] -> Either MathError ()
validateBoundary (Grid dims _ periodic _) bc = do
    require (length bc == length dims) "boundary count must equal grid rank"
    mapM_
        ( \(p, (a, b)) ->
            if p
                then require (a == Periodic && b == Periodic) "periodic axis needs both periodic faces"
                else require (a /= Periodic && b /= Periodic) "nonperiodic axis cannot have periodic face"
        )
        (zip periodic bc)
    mapM_ valid (concatMap (\(a, b) -> [a, b]) bc)
  where
    valid Periodic = Right ()
    valid (Dirichlet x) = checked x >> Right ()
    valid (Neumann x) = checked x >> Right ()
    valid (Robin a b c) = vector [a, b, c] >> require (a /= 0 || b /= 0) "Robin coefficients both zero"

-- | Resolve essential values on corners; contradictory Dirichlet faces fail.
fixedNodes :: Grid -> [(Boundary, Boundary)] -> Either MathError [(Int, Double)]
fixedNodes g@(Grid dims _ periodic _) bc = fmap concat (mapM fixed [0 .. product dims - 1])
  where
    fixed i = do
        ix <- unflattenIndex g i
        let faces =
                [ if side == 0 then fst pair else snd pair
                | (k, (n, p, pair)) <- zip [0 ..] (zip3 dims periodic bc)
                , not p
                , side <- [0, 1 :: Int]
                , ix !! k == if side == 0 then 0 else n - 1
                ]
            value (Dirichlet x) = Just x; value (Robin a 0 c) = Just (c / a); value _ = Nothing
            values = [v | Just v <- map value faces]
        _ <- vector values
        case values of
            [] -> Right []
            v : _ ->
                require
                    (all (\w -> abs (w - v) <= 1e-12 * max 1 (abs v)) values)
                    "inconsistent essential boundary values at grid corner"
                    >> Right [(i, v)]

-- | Assemble -kappa*Laplacian (FD) or -div(kappa grad) (FV/FEM) plus constant reaction; coefficient field is positive at every node.
assemblePDE ::
    Discretization ->
    Grid ->
    [(Boundary, Boundary)] ->
    [Double] ->
    Double ->
    Either MathError PDEOperator
assemblePDE method g@(Grid dims _ periodic _) bc diffusivity reaction = do
    validateBoundary g bc
    let n = product dims
    require
        (length diffusivity == n && all (> 0) diffusivity && finite reaction)
        "invalid positive diffusivity field/reaction"
    _ <- vector diffusivity
    fixed <- fixedNodes g bc
    (entries, massEntries, load) <-
        if method == FiniteElement
            then do
                require (n <= 2048 && not (or periodic)) "Q1 FEM reference supports <=2048 nonperiodic nodes"
                femAssembly g bc diffusivity reaction
            else do
                rows <- mapM (stencilRow method g bc diffusivity reaction) [0 .. n - 1]
                Right (concatMap fst rows, [(i, i, 1) | i <- [0 .. n - 1]], map snd rows)
    let essential = map fst fixed
        filtered = [(i, j, v) | (i, j, v) <- entries, i `notElem` essential] ++ [(i, i, 1) | i <- essential]
        massFiltered = [(i, j, v) | (i, j, v) <- massEntries, i `notElem` essential]
        finalLoad = [maybe (load !! i) id (lookup i fixed) | i <- [0 .. n - 1]]
    _ <- vector ([v | (_, _, v) <- filtered] ++ [v | (_, _, v) <- massFiltered] ++ finalLoad)
    stiffness <- S.sparse n n filtered
    mass <- S.sparse n n massFiltered
    Right (PDEOperator g stiffness mass finalLoad fixed)

stencilRow ::
    Discretization ->
    Grid ->
    [(Boundary, Boundary)] ->
    [Double] ->
    Double ->
    Int ->
    Either MathError ([(Int, Int, Double)], Double)
stencilRow method g@(Grid dims _ periodic hs) bc kappas reaction i = do
    ix <- unflattenIndex g i
    let parts axis =
            let h = hs !! axis
                k = kappas !! i
                n = dims !! axis
                q = ix !! axis
                period = periodic !! axis
                neighbor side =
                    let qq = (q + side) `mod` n; j = sum (zipWith (*) (replace axis qq ix) (strides dims))
                     in (j, if method == FiniteVolume then (k + kappas !! j) / 2 else k)
                inner side = let (j, faceK) = neighbor side in ([(i, i, faceK / (h * h)), (i, j, -faceK / (h * h))], 0)
                face side boundary =
                    let (j, kface) = neighbor (-side)
                        scale = 2 * kface / (h * h)
                        (a, b, c) = case boundary of Neumann d -> (0, 1, d); Robin aa bb cc -> (aa, bb, cc); _ -> (0, 1, 0)
                     in if b == 0
                            then ([], 0)
                            else ([(i, i, scale + 2 * k * a / (h * b)), (i, j, -scale)], 2 * k * c / (h * b))
             in if period || q > 0 && q < n - 1
                    then combine (inner (-1)) (inner 1)
                    else if q == 0 then face (-1) (fst (bc !! axis)) else face 1 (snd (bc !! axis))
        combine (a, x) (b, y) = (a ++ b, x + y)
        (entries, load) = foldl combine ([(i, i, reaction)], 0) [parts a | a <- [0 .. length dims - 1]]
    Right (entries, load)

-- Tensor Q1 element and boundary quadrature. Integration uses cell-specific
-- interpolated positive diffusivity and consistent source/mass interpolation.
femAssembly ::
    Grid ->
    [(Boundary, Boundary)] ->
    [Double] ->
    Double ->
    Either MathError ([(Int, Int, Double)], [(Int, Int, Double)], [Double])
femAssembly (Grid dims _ _ hs) bc kappas reaction = do
    let d = length dims
        n = product dims
        bits = sequence (replicate d [0, 1 :: Int])
        cells = sequence [[0 .. k - 2] | k <- dims]
        gauss = [(1 - 1 / sqrt 3) / 2, (1 + 1 / sqrt 3) / 2]
        phi corner z = product (zipWith (\v t -> if v == 0 then 1 - t else t) corner z)
        grad corner z axis =
            (if corner !! axis == 0 then -1 else 1)
                / (hs !! axis)
                * product [if corner !! k == 0 then 1 - z !! k else z !! k | k <- [0 .. d - 1], k /= axis]
        cellData base =
            let nodes = [sum (zipWith (*) (zipWith (+) base corner) (strides dims)) | corner <- bits]
                quadrature = sequence (replicate d gauss)
                weight = product hs / fromIntegral (2 ^ d :: Int)
                kval z = sum [kappas !! j * phi corner z | (j, corner) <- zip nodes bits]
                localMass a b = weight * sum [phi a z * phi b z | z <- quadrature]
                stiff a b =
                    weight
                        * sum
                            [ kval z * sum [grad a z k * grad b z k | k <- [0 .. d - 1]] + reaction * phi a z * phi b z
                            | z <- quadrature
                            ]
             in ( [(i, j, stiff a b) | (i, a) <- zip nodes bits, (j, b) <- zip nodes bits]
                , [(i, j, localMass a b) | (i, a) <- zip nodes bits, (j, b) <- zip nodes bits]
                , nodes
                )
        volume = map cellData cells
        faceData base axis side =
            let (_, _, nodes) = cellData base
                boundary = if side == 0 then fst (bc !! axis) else snd (bc !! axis)
                (a, b, c) = case boundary of Neumann v -> (0, 1, v); Robin aa bb cc -> (aa, bb, cc); _ -> (0, 0, 0)
                zs =
                    map (\z -> take axis z ++ [fromIntegral side] ++ drop axis z) (sequence (replicate (d - 1) gauss))
                weight = product [hs !! k | k <- [0 .. d - 1], k /= axis] / fromIntegral (2 ^ (d - 1) :: Int)
                kval z = sum [kappas !! j * phi corner z | (j, corner) <- zip nodes bits]
             in if b == 0
                    then ([], [])
                    else
                        ( [ (i, j, weight * a / b * sum [kval z * phi ca z * phi cb z | z <- zs])
                          | (i, ca) <- zip nodes bits
                          , (j, cb) <- zip nodes bits
                          ]
                        , [(i, weight * c / b * sum [kval z * phi ca z | z <- zs]) | (i, ca) <- zip nodes bits]
                        )
        boundaryParts =
            [ faceData base axis side
            | base <- cells
            , axis <- [0 .. d - 1]
            , side <- [0, 1 :: Int]
            , base !! axis == if side == 0 then 0 else dims !! axis - 2
            ]
        entries = concat [a | (a, _, _) <- volume] ++ concatMap fst boundaryParts
        mass = concat [a | (_, a, _) <- volume]
        load = [sum [v | (j, v) <- concatMap snd boundaryParts, i == j] | i <- [0 .. n - 1]]
    _ <- vector ([v | (_, _, v) <- entries] ++ [v | (_, _, v) <- mass] ++ load)
    Right (entries, mass, load)

-- | Read the canonical sparse stiffness and source mass operators; essential rows are identity/zero respectively.
pdeStiffness, pdeMass :: PDEOperator -> S.Sparse Double
pdeStiffness (PDEOperator _ a _ _ _) = a
pdeMass (PDEOperator _ _ m _ _) = m

-- | Read boundary contributions, including prescribed values at essential rows.
pdeBoundaryLoad :: PDEOperator -> [Double]
pdeBoundaryLoad (PDEOperator _ _ _ b _) = b

{- | Dense pivoted reference solve and independently recomputed infinity
residual. The error estimate is backward residual, not continuum error.
-}
solveElliptic :: PDEOperator -> [Double] -> Either MathError PDEResult
solveElliptic (PDEOperator g a mass boundary fixed) forcing = do
    let n = product (gridShape g)
    require
        (n <= 1024 && length forcing == n)
        "elliptic reference solve requires <=1024 nodes and matching source"
    _ <- vector forcing
    source <- S.spmv mass forcing
    let rhs = zipWith (+) source boundary
    -- A pure Neumann/periodic nullspace is explicitly rejected before floating
    -- elimination can manufacture a pivot from roundoff.
    rows <- denseRows a
    require
        (not (null fixed) || any (\r -> abs (sum r) > 1e-10 * max 1 (sum (map abs r))) rows)
        "underdetermined zero-reaction Neumann/periodic problem; fix a gauge or use spectralPoisson"
    values <- solve rows rhs
    residual <- checked (maximum (0 : map abs (zipWith (-) (mv rows values) rhs)))
    Right (PDEResult values residual residual)

denseRows :: S.Sparse Double -> Either MathError [[Double]]
denseRows a = do
    let (n, m) = S.sparseShape a
    require (n <= 1024 && m <= 1024) "dense PDE reference budget exceeded"
    let entries = Map.fromList [((i, j), v) | (i, j, v) <- S.sparseEntries a]
    Right [[Map.findWithDefault 0 (i, j) entries | j <- [0 .. m - 1]] | i <- [0 .. n - 1]]

-- | Solve a unit-diffusivity zero-reaction Poisson problem with the selected spatial discretization.
poisson ::
    Discretization -> Grid -> [(Boundary, Boundary)] -> [Double] -> Either MathError PDEResult
poisson method g bc forcing = assemblePDE method g bc (replicate (product (gridShape g)) 1) 0 >>= (`solveElliptic` forcing)

-- | Solve the corresponding homogeneous-source boundary-value problem.
laplace :: Discretization -> Grid -> [(Boundary, Boundary)] -> Either MathError PDEResult
laplace method g bc = poisson method g bc (replicate (product (gridShape g)) 0)

-- | Solve -Laplacian(u)-k²u=f; resonances/singular systems fail.
helmholtz ::
    Discretization -> Grid -> [(Boundary, Boundary)] -> Double -> [Double] -> Either MathError PDEResult
helmholtz method g bc k forcing = do
    require (finite k && k >= 0 && finite (k * k)) "invalid Helmholtz wave number"
    op <- assemblePDE method g bc (replicate (product (gridShape g)) 1) (-k * k)
    solveElliptic op forcing

-- | Second-order central spatial gradients; physical endpoints use second-order one-sided stencils.
spatialGradient :: Grid -> [Double] -> Either MathError [[Double]]
spatialGradient g@(Grid dims _ periodic hs) values = do
    require (length values == product dims) "gradient grid/value mismatch"
    _ <- vector values
    mapM
        ( \axis ->
            mapM
                ( \i -> do
                    ix <- unflattenIndex g i
                    let q = ix !! axis
                        n = dims !! axis
                        h = hs !! axis
                        at j = values !! sum (zipWith (*) (replace axis (j `mod` n) ix) (strides dims))
                        result
                            | periodic !! axis || q > 0 && q < n - 1 = (at (q + 1) - at (q - 1)) / (2 * h)
                            | q == 0 = (-3 * at 0 + 4 * at 1 - at 2) / (2 * h)
                            | otherwise = (3 * at (n - 1) - 4 * at (n - 2) + at (n - 3)) / (2 * h)
                    checked result
                )
                [0 .. product dims - 1]
        )
        [0 .. length dims - 1]

-- | Apply the FD Laplacian with ghost normal/Robin boundary data. Essential rows return prescribed-value minus current-value residuals.
laplacianStencil :: Grid -> [(Boundary, Boundary)] -> [Double] -> Either MathError [Double]
laplacianStencil g bc values = do
    op <- assemblePDE FiniteDifference g bc (replicate (product (gridShape g)) 1) 0
    applied <- S.spmv (pdeStiffness op) values
    vector (zipWith (-) (pdeBoundaryLoad op) applied)

waveNumbers :: Grid -> Either MathError [[Double]]
waveNumbers (Grid dims _ periodic hs) = do
    require (and periodic) "spectral differentiation requires all-periodic grid"
    sequence [map (2 * pi *) <$> F.frequencies n h | (n, h) <- zip dims hs]

-- | Periodic Fourier collocation derivative of order 0..8 along one axis; odd real Nyquist derivatives are zero.
spectralDerivative :: Grid -> Int -> Int -> [Double] -> Either MathError [Double]
spectralDerivative g@(Grid dims _ _ _) axis order values = do
    require
        (axis >= 0 && axis < length dims && order >= 0 && order <= 8 && length values == product dims)
        "invalid spectral derivative axis/order/shape"
    ks <- waveNumbers g
    spectrum <- F.fftND F.Forward dims (map (:+ 0) values)
    let multiplier i =
            let q = i `div` (strides dims !! axis) `mod` (dims !! axis); k = ks !! axis !! q
             in -- Odd derivatives of a real Nyquist mode are zero.
                if odd order && even (dims !! axis) && q == dims !! axis `div` 2 then 0 else (0 :+ k) ^ order
    output <- F.fftND F.Inverse dims [z * multiplier i | (i, z) <- zip [0 ..] spectrum]
    vector (map realPart output)

-- | Sum periodic second Fourier derivatives over all spatial axes.
spectralLaplacian :: Grid -> [Double] -> Either MathError [Double]
spectralLaplacian g values = do
    terms <- mapM (\axis -> spectralDerivative g axis 2 values) [0 .. length (gridShape g) - 1]
    vector (foldl1 (zipWith (+)) terms)

-- | Solve (-Laplacian+reaction)u=f spectrally; reaction>=0, and zero reaction requires a mean-free source with zero-mean solution gauge.
spectralPoisson :: Grid -> Double -> [Double] -> Either MathError PDEResult
spectralPoisson g@(Grid dims _ _ _) reaction forcing = do
    require
        (finite reaction && reaction >= 0 && length forcing == product dims)
        "invalid spectral Poisson reaction/source"
    ks <- waveNumbers g
    spectrum <- F.fftND F.Forward dims (map (:+ 0) forcing)
    let eigenvalue i =
            reaction
                + sum
                    [ (ks !! axis !! (i `div` (strides dims !! axis) `mod` (dims !! axis))) ^ (2 :: Int)
                    | axis <- [0 .. length dims - 1]
                    ]
    require
        (reaction > 0 || magnitude (spectrum !! 0) <= 1e-10 * max 1 (sum (map abs forcing)))
        "periodic Poisson source must have zero mean"
    values <-
        map realPart
            <$> F.fftND
                F.Inverse
                dims
                [if eigenvalue i == 0 then 0 else z / (eigenvalue i :+ 0) | (i, z) <- zip [0 ..] spectrum]
    applied <- spectralLaplacian g values
    residual <-
        checked (maximum (0 : map abs (zipWith3 (\u l f -> reaction * u - l - f) values applied forcing)))
    Right (PDEResult values residual residual)

{- | Pseudospectral divergence(kappa*gradient u). Products are evaluated at
collocation nodes; no implicit de-aliasing, so caller must resolve coefficients.
-}
pseudoSpectralDiffusion :: Grid -> [Double] -> [Double] -> Either MathError [Double]
pseudoSpectralDiffusion g kappas values = do
    require
        (length kappas == length values && all (> 0) kappas)
        "invalid pseudospectral coefficient field"
    _ <- vector kappas
    terms <-
        mapM
            (\axis -> spectralDerivative g axis 1 values >>= spectralDerivative g axis 1 . zipWith (*) kappas)
            [0 .. length (gridShape g) - 1]
    vector (foldl1 (zipWith (+)) terms)

{- | Method of lines with a constant assembled operator and checked time-source
callback. Essential Dirichlet values remain constant in time; initial state
must satisfy them. Consistent FEM mass is inverted on unconstrained rows.
-}
methodOfLines ::
    O.Method ->
    PDEOperator ->
    (Double -> [Double]) ->
    [Double] ->
    [Double] ->
    Either MathError O.Trajectory
methodOfLines method (PDEOperator g stiffness mass boundary fixed) source times initial = do
    let n = product (gridShape g)
    require
        (n <= 1024 && length initial == n && all (\(i, v) -> abs (initial !! i - v) <= 1e-10) fixed)
        "invalid PDE initial state/Dirichlet values or reference budget"
    a <- denseRows stiffness
    m0 <- denseRows mass
    let m =
            [ if i `elem` map fst fixed then row else r
            | (i, r) <- zip [0 ..] m0
            , let row = [if j == i then 1 else 0 | j <- [0 .. n - 1]]
            ]
        rhs t u =
            let f = source t
                load = zipWith3 (\v b au -> v + b - au) (mv m0 f) boundary (mv a u)
                constrained = [if i `elem` map fst fixed then 0 else v | (i, v) <- zip [0 ..] load]
             in if length f /= n || not (all finite f)
                    then replicate n (0 / 0)
                    else either (const (replicate n (0 / 0))) id (solve m constrained)
    require
        (not (null times) && all finite times && and (zipWith (<) times (drop 1 times)))
        "method of lines needs finite increasing time samples"
    (_, states) <-
        foldM
            ( \(u, acc) (aTime, bTime) -> do
                trajectory <- O.solveIVP method O.defaultODEOptions 1 rhs aTime bTime u
                let next = last (O.trajectoryStates trajectory)
                Right (next, acc ++ [next])
            )
            (initial, [initial])
            (zip times (drop 1 times))
    Right (O.Trajectory times states (zipWith rhs times states))

{- | Explicit heat/diffusion uses RK4, with a conservative forward-Euler CFL
check (therefore valid for RK4 too). Positive diffusivity and ordered times.
-}
heat ::
    Grid -> [(Boundary, Boundary)] -> Double -> [Double] -> [Double] -> Either MathError O.Trajectory
heat g bc k = diffusion FiniteVolume g bc (replicate (product (gridShape g)) k)

-- | Variable positive nodal diffusivity, chosen spatial method and increasing output times; FEM uses a stricter consistent-mass CFL bound.
diffusion ::
    Discretization ->
    Grid ->
    [(Boundary, Boundary)] ->
    [Double] ->
    [Double] ->
    [Double] ->
    Either MathError O.Trajectory
diffusion method g bc kappas times initial = do
    require (not (null times)) "diffusion needs times"
    limit <- stabilityLimit g (maximum (0 : kappas)) (replicate (length (gridShape g)) 0)
    require
        ( and
            ( zipWith
                (\a b -> b > a && b - a <= limit / (if method == FiniteElement then 3 else 1))
                times
                (drop 1 times)
            )
        )
        "diffusion time step violates explicit CFL"
    op <- assemblePDE method g bc kappas 0
    methodOfLines O.RK4 op (const (replicate (length initial) 0)) times initial

{- | Periodic velocity-Verlet wave equation u_tt=c² Laplacian(u); returns u at
requested equally or unequally spaced increasing times. Spectral Laplacian.
-}
wave :: Grid -> Double -> [Double] -> [Double] -> [Double] -> Either MathError [[Double]]
wave g speed times initial velocity = do
    _ <- waveNumbers g
    let n = product (gridShape g)
    require
        (finite speed && speed > 0 && not (null times) && length initial == n && length velocity == n)
        "invalid wave inputs"
    _ <- vector (times ++ initial ++ velocity)
    let limit = 2 / (speed * sqrt (sum [(pi / h) ^ (2 :: Int) | h <- gridSpacing g]))
    require
        (and (zipWith (\a b -> b > a && b - a <= limit) times (drop 1 times)))
        "wave step violates spectral Verlet stability"
    let go _ _ [] = Right []
        go u v ((a, b) : steps) = do
            acc <- map (speed * speed *) <$> spectralLaplacian g u
            let dt = b - a; half = zipWith (\vv aa -> vv + dt * aa / 2) v acc
            next <- vector (zipWith (\uu vv -> uu + dt * vv) u half)
            acc2 <- map (speed * speed *) <$> spectralLaplacian g next
            vv <- vector (zipWith (\hh aa -> hh + dt * aa / 2) half acc2)
            rest <- go next vv steps
            Right (next : rest)
    rest <- go initial velocity (zip times (drop 1 times))
    Right (initial : rest)

{- | Conservative first-order upwind periodic advection, central conservative
variable-coefficient diffusion. Explicit Euler preserves constants and total
mass for periodic data when the combined positivity CFL is satisfied.
-}
advection :: Grid -> [Double] -> [Double] -> [Double] -> Either MathError [[Double]]
advection g velocity = advectionDiffusion g velocity 0

-- | Periodic upwind advection plus central diffusion using explicit Euler and the combined positivity CFL bound.
advectionDiffusion ::
    Grid -> [Double] -> Double -> [Double] -> [Double] -> Either MathError [[Double]]
advectionDiffusion g@(Grid dims _ periodic hs) velocity diffusivity times initial = do
    require
        (and periodic && length velocity == length dims && length initial == product dims && not (null times))
        "advection reference requires periodic grid and matching data"
    limit <- stabilityLimit g diffusivity velocity
    _ <- vector (times ++ initial)
    require
        (and (zipWith (\a b -> b > a && b - a <= limit) times (drop 1 times)))
        "advection-diffusion time step violates positivity CFL"
    let derivative u i =
            let ix = [i `div` s `mod` n | (s, n) <- zip (strides dims) dims]
                at axis step =
                    u !! sum (zipWith (*) (replace axis ((ix !! axis + step) `mod` (dims !! axis)) ix) (strides dims))
             in sum
                    [ let h = hs !! axis; v = velocity !! axis; left = at axis (-1); right = at axis 1; center = u !! i
                       in -v * (if v >= 0 then center - left else right - center) / h
                            + diffusivity * (right - 2 * center + left) / (h * h)
                    | axis <- [0 .. length dims - 1]
                    ]
    (_, states) <-
        foldM
            ( \(u, acc) (a, b) -> do
                next <- vector [uu + (b - a) * derivative u i | (i, uu) <- zip [0 ..] u]
                Right (next, acc ++ [next])
            )
            (initial, [initial])
            (zip times (drop 1 times))
    Right states

-- | Conservative explicit positivity bound 1/sum(|v|/h+2*kappa/h^2); infinity denotes a zero spatial operator.
stabilityLimit :: Grid -> Double -> [Double] -> Either MathError Double
stabilityLimit g diffusivity velocity = do
    require
        ( finite diffusivity
            && diffusivity >= 0
            && length velocity == length (gridShape g)
            && all finite velocity
        )
        "invalid CFL coefficients"
    let inverseStep = sum [abs v / h + 2 * diffusivity / (h * h) | (v, h) <- zip velocity (gridSpacing g)]
    require (finite inverseStep) "CFL coefficient overflow"
    Right (if inverseStep == 0 then 1 / 0 else 1 / inverseStep)

-- | Requested nonnegative timestep divided by the conservative combined stability limit.
cflNumber :: Grid -> Double -> [Double] -> Double -> Either MathError Double
cflNumber g diffusivity velocity dt = do
    require (finite dt && dt >= 0) "invalid CFL timestep"
    limit <- stabilityLimit g diffusivity velocity
    checked (dt / limit)

-- | Maximum absolute nodal difference from a finite exact-solution callback; this measures continuum error when an exact solution is known.
manufacturedError :: Grid -> ([Double] -> Double) -> [Double] -> Either MathError Double
manufacturedError g exact values = do
    require (length values == product (gridShape g)) "manufactured solution shape mismatch"
    errors <- vector (zipWith (\x u -> abs (exact x - u)) (gridCoordinates g) values)
    Right (maximum (0 : errors))
