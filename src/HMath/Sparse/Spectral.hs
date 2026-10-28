-- SPDX-License-Identifier: MPL-2.0

-- | Matrix-free sparse power algorithms. Neither a dense matrix nor A^T A is
-- formed. Sparse multiplication, explicit vector workspaces and orthogonal
-- deflation determine storage. Power convergence requires a starting component
-- in the desired singular/eigen direction and a separated dominant magnitude;
-- an exact residual certifies an eigen/singular pair, not spectral dominance.
-- Every returned pair has residuals checked against the original sparse input.
-- See the power-method SVD derivation in
-- <https://ee263.stanford.edu/archive/ee263_course_reader.pdf Stanford EE263, exercise 15.10>.
module HMath.Sparse.Spectral
    ( SparseSpectralOptions(..), defaultSparseSpectralOptions
    , SparseEigenResult(..), sparseDominantEigen
    , SparseSVD(..), sparseTruncatedSVD
    ) where

import Control.Monad (foldM)
import qualified Data.Map.Strict as Map
import HMath.Error (MathError(..))
import HMath.Matrix.Internal (finiteValues,stableNorm,dotV)
import HMath.Sparse (Sparse,sparseShape,sparseEntries,sparseTranspose,spmv)

-- | Residual tolerances, per-pair iteration budget and an explicit workspace
-- limit measured in scalar elements. Tolerances are finite and nonnegative.
data SparseSpectralOptions a=SparseSpectralOptions
    { sparseAbsoluteTolerance :: a
      -- ^ Absolute norm tolerance, finite and nonnegative.
    , sparseRelativeTolerance :: a
      -- ^ Relative tolerance against max(abs eigen/singular value,maxAbs input).
    , sparseIterationLimit :: Int
      -- ^ Nonnegative number of power updates per pair.
    , sparseWorkspaceLimit :: Integer
      -- ^ Maximum estimated simultaneous vector elements, nonnegative.
    } deriving (Eq,Show)

-- | Absolute tolerance 1e-12, relative tolerance 1e-10, 1000 iterations per
-- pair and a workspace limit of ten million scalar elements.
defaultSparseSpectralOptions :: Fractional a => SparseSpectralOptions a
defaultSparseSpectralOptions=SparseSpectralOptions 1e-12 1e-10 1000 10000000

-- | A normalized real symmetric eigenpair and its independently checked residual.
data SparseEigenResult a=SparseEigenResult
    { sparseEigenvalue :: a
      -- ^ Rayleigh quotient; negative dominant eigenvalues retain their sign.
    , sparseEigenvector :: [a]
      -- ^ Unit Euclidean norm eigenvector.
    , sparseEigenResidual :: a
      -- ^ Original norm ||A v-lambda v||_2.
    , sparseEigenIterations :: Int
      -- ^ Number of completed power updates.
    } deriving (Eq,Show)

-- | Symmetric power iteration targeting the eigenvalue of largest magnitude.
-- Exact symmetry and finite input are required. The caller supplies a nonzero
-- finite initial vector; its projection onto the desired eigenspace must be
-- nonzero. An initial eigenvector can converge with a zero budget. Equal opposite
-- dominant eigenvalues may cause non-convergence. Returned residuals do not prove
-- that the converged eigenvalue is the largest when the initial projection is zero.
sparseDominantEigen :: RealFloat a => SparseSpectralOptions a -> Sparse a -> [a]
                    -> Either MathError (SparseEigenResult a)
sparseDominantEigen options matrix initial=do
    validateOptions options
    let (m,n)=sparseShape matrix
    if m/=n then Left (NonSquareMatrix (m,n)) else Right ()
    if n==0 then Left (DomainError "empty matrix has no eigenvector") else Right ()
    checkWorkspace options (6*toInteger n)
    validateSparse matrix
    if length initial/=n then Left (VectorLengthMismatch n (length initial)) else finiteValues initial
    let values=Map.fromList [((i,j),v)|(i,j,v)<-sparseEntries matrix]
    if any (\((i,j),v)->Map.findWithDefault 0 (j,i) values/=v) (Map.toList values)
        then Left (DomainError "sparseDominantEigen requires exact symmetry") else Right ()
    q<-unitVector initial
    go 0 q
  where
    scale=inputScale matrix
    go k q=do
        aq<-checkedProduct matrix q
        let lambda=dotV q aq
            r=zipWith (\a v->a-lambda*v) aq q
        finiteValues (lambda:r)
        rn<-checkedNorm r
        if within options (max scale (abs lambda)) rn
            then Right (SparseEigenResult lambda q rn k)
            else if k==sparseIterationLimit options
                then Left (NonConvergence "sparse symmetric power iteration" k)
                else do
                    next<-unitVector aq
                    go (k+1) next

-- | Compact singular triplets. Left and right vectors are stored as lists of
-- columns, requiring O(k*(rows+columns)) storage instead of a dense matrix.
data SparseSVD a=SparseSVD
    { sparseSingularValues :: [a]
      -- ^ Nonnegative singular estimates in extraction order.
    , sparseLeftVectors :: [[a]]
      -- ^ Left unit vectors, one list per singular triplet.
    , sparseRightVectors :: [[a]]
      -- ^ Right unit vectors (columns of V, rather than rows of V^T).
    , sparseSingularResiduals :: [(a,a)]
      -- ^ Original (||A v-s u||_2,||A^T u-s v||_2) residuals.
    , sparseSingularIterations :: [Int]
      -- ^ Power updates used by each triplet.
    } deriving (Eq,Show)

-- | Truncated SVD by two-sided power iteration and two-pass orthogonal deflation.
-- The seed initializes a local deterministic stream, with no global RNG state.
-- Both original singular residuals must meet the configured tolerance. The
-- algorithm targets descending singular values if starting vectors have nonzero
-- projection and the successive singular values are separated; it does not claim
-- a certified rank or ordering when these power-method assumptions fail.
-- Exact null images report RankDeficient, rather than inventing zero singular
-- vectors. Small positive singular values may be returned within tolerance;
-- requesting more vectors than the numerical rank can also exhaust the budget.
-- k=0 returns empty factors, including for empty/zero inputs.
sparseTruncatedSVD :: RealFloat a => SparseSpectralOptions a -> Int -> Integer -> Sparse a
                   -> Either MathError (SparseSVD a)
sparseTruncatedSVD options requested seed matrix=do
    validateOptions options
    let (m,n)=sparseShape matrix
    if requested<0 || requested>min m n then Left (InvalidArgument "invalid sparse SVD rank") else Right ()
    checkWorkspace options (if requested==0 then 0 else (2*toInteger requested+10)*(toInteger m+toInteger n))
    validateSparse matrix
    (triplets,_)<-foldM extract ([],seed `mod` 4294967296) [0..requested-1]
    pure (SparseSVD [s|(_,s,_,_,_)<-triplets] [u|(u,_,_,_,_)<-triplets]
        [v|(_,_,v,_,_)<-triplets] [r|(_,_,_,r,_)<-triplets] [k|(_,_,_,_,k)<-triplets])
  where
    transposed=sparseTranspose matrix
    (_,columns)=sparseShape matrix
    scale=inputScale matrix
    extract (prior,state) index=do
        let (candidate,nextSeed)=randomVector state columns
            lefts=[u|(u,_,_,_,_)<-prior]
            rights=[v|(_,_,v,_,_)<-prior]
        start<-unitVector (projectOut rights candidate)
        triplet<-iteratePair index lefts rights 0 start
        pure (prior++[triplet],nextSeed)
    iteratePair index lefts rights k v
        | k==sparseIterationLimit options=Left (NonConvergence "sparse two-sided SVD" k)
        | otherwise=do
            av<-checkedProduct matrix v
            let left=projectOut lefts av
            if all (==0) left then Left (RankDeficient index) else Right ()
            u<-unitVector left
            atu<-checkedProduct transposed u
            let right=projectOut rights atu
            if all (==0) right then Left (RankDeficient index) else Right ()
            vn<-unitVector right
            avn<-checkedProduct matrix vn
            let sigma=dotV u avn
                leftResidual=zipWith (\a z->a-sigma*z) avn u
                rightResidual=zipWith (\a z->a-sigma*z) atu vn
            finiteValues (sigma:leftResidual++rightResidual)
            if sigma<0 then Left (DomainError "sparse SVD lost nonnegative singular orientation")
                else if sigma==0 then Left (RankDeficient index) else Right ()
            lr<-checkedNorm leftResidual
            rr<-checkedNorm rightResidual
            if within options (max scale sigma) lr && within options (max scale sigma) rr
                then Right (u,sigma,vn,(lr,rr),k+1)
                else iteratePair index lefts rights (k+1) vn

validateOptions :: RealFloat a => SparseSpectralOptions a -> Either MathError ()
validateOptions options
    | any (\x->not (finite x) || x<0) [sparseAbsoluteTolerance options,sparseRelativeTolerance options]
        =Left InvalidTolerance
    | sparseIterationLimit options<0=Left (InvalidArgument "negative sparse spectral iteration limit")
    | sparseWorkspaceLimit options<0=Left (InvalidArgument "negative sparse spectral workspace limit")
    | otherwise=Right ()

checkWorkspace :: SparseSpectralOptions a -> Integer -> Either MathError ()
checkWorkspace options count
    | count>sparseWorkspaceLimit options || count>toInteger (maxBound::Int)
        =Left (InvalidArgument "sparse spectral vector workspace limit exceeded")
    | otherwise=Right ()

validateSparse :: RealFloat a => Sparse a -> Either MathError ()
validateSparse=finiteValues . map (\(_,_,v)->v) . sparseEntries

inputScale :: (Num a,Ord a) => Sparse a -> a
inputScale=maximum . (0:) . map (\(_,_,v)->abs v) . sparseEntries

checkedProduct :: RealFloat a => Sparse a -> [a] -> Either MathError [a]
checkedProduct a v=do
    productVector<-spmv a v
    finiteValues productVector
    pure productVector

-- Normalize by max magnitude first. The true norm can overflow for entirely
-- finite input; scaling before normalization avoids converting it to a zero vector.
unitVector :: RealFloat a => [a] -> Either MathError [a]
unitVector xs=do
    finiteValues xs
    let scale=maximum (0:map abs xs)
    if scale==0 then Left (DomainError "zero sparse spectral starting or power vector") else do
        let scaled=map (/scale) xs
            norm=stableNorm scaled
            q=map (/norm) scaled
        finiteValues q
        pure q

checkedNorm :: RealFloat a => [a] -> Either MathError a
checkedNorm xs=do
    finiteValues xs
    let norm=stableNorm xs
    if finite norm then Right norm else Left NonFiniteResult

within :: RealFloat a => SparseSpectralOptions a -> a -> a -> Bool
within options scale residual
    | residual<=sparseAbsoluteTolerance options=True
    | scale==0=False
    | otherwise=residual/scale<=sparseRelativeTolerance options+sparseAbsoluteTolerance options/scale

projectOut :: RealFloat a => [[a]] -> [a] -> [a]
projectOut basis=pass.pass
  where pass xs=foldl (\v q->let coefficient=dotV q v
                             in zipWith (\a b->a-coefficient*b) v q) xs basis

randomVector :: Fractional a => Integer -> Int -> ([a],Integer)
randomVector seed n=
    let states=take n (drop 1 (iterate (\x->(1664525*x+1013904223) `mod` 4294967296) seed))
        values=[(fromInteger x+0.5)/4294967296-0.5|x<-states]
    in (values,case reverse states of x:_->x; []->seed)

finite :: RealFloat a => a -> Bool
finite x=not (isNaN x || isInfinite x)
