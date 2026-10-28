-- SPDX-License-Identifier: MPL-2.0
-- | Sparse matrices use canonical sorted coordinates, coalesced duplicates and
-- no explicit zeros. Formats carry public metadata and are validated on import.
-- CSR/CSC indices within each segment must be strictly increasing. DIA stores
-- one value per row of a diagonal, with zero padding. BSR allows edge blocks
-- only with zero padding. ELLPACK uses -1 and zero for unused row-major slots.
module HMath.Sparse
    ( Sparse, SparseFormat(..), sparse, sparseShape, nonzeros, sparseEntries
    , fromFormat, toCOO, toCSR, toCSC, toDIA, toBSR, toELLPACK
    , sparseToDense, denseToSparse, sparseTranspose, sparseAdd, sparseSubtract
    , spmv, spmm, sparseKronecker, sparseTriangularSolve, sparseDiagonalSolve
    , SparseLU, sparseLU, sparseLULower, sparseLUUpper, sparseLUPermutation, sparseSolveLU
    , sparseCholesky, SparseQR, sparseQR, sparseQRUpper, sparseQRApplyQT
    , sparseGraph, sparseStorageBytes, SparseTensor, sparseTensor, sparseTensorEntries
    , sparseTensorShape, sparseTensorLookup, sparseEigenReference, sparseSVDReference ) where

import Control.Monad (foldM)
import Data.Array (listArray,accumArray,(!),elems)
import qualified Data.Map.Strict as M
import Data.List (sortOn,maximumBy)
import Data.Ord (comparing)
import Foreign.Storable (sizeOf)
import HMath.Matrix.LAPACK (Eigen,SVD,eigen,svd)
import HMath.Error
import HMath.Matrix
import HMath.Matrix.Internal (finiteValues,stableNorm,dotV,swap)

data Sparse a = Sparse Int Int (M.Map (Int,Int) a) deriving (Eq,Show)
data SparseFormat a
    = COO Int Int [(Int,Int,a)]
    | CSR Int Int [Int] [Int] [a]
    | CSC Int Int [Int] [Int] [a]
    | DIA Int Int [(Int,[a])]
    | BSR Int Int Int Int [Int] [Int] [[a]]
    | ELLPACK Int Int Int [Int] [a]
    deriving (Eq,Show)
shapeValid :: Int -> Int -> Either MathError ()
shapeValid r c | r<0 || c<0 = Left (NegativeDimensions (r,c))
               | otherwise = Right ()
sparse :: (Eq a,Num a) => Int -> Int -> [(Int,Int,a)] -> Either MathError (Sparse a)
sparse r c xs = do
    shapeValid r c
    if any (\(i,j,_) -> i<0 || j<0 || i>=r || j>=c) xs then Left (InvalidArgument "sparse: coordinate out of bounds")
        else Right (Sparse r c (M.filter (/=0) (M.fromListWith (+) [((i,j),v) | (i,j,v)<-xs])))
sparseShape :: Sparse a -> (Int,Int)
sparseShape (Sparse r c _) = (r,c)
sparseEntries :: Sparse a -> [(Int,Int,a)]
sparseEntries (Sparse _ _ xs) = [(i,j,v) | ((i,j),v)<-M.toAscList xs]
nonzeros :: Sparse a -> Int
nonzeros (Sparse _ _ xs) = M.size xs
segments :: Int -> Int -> [Int] -> [Int] -> [a] -> Either MathError [[(Int,a)]]
segments outer inner ptr indices values
    | toInteger outer+1>toInteger (maxBound::Int) = bad
    | length ptr/=outer+1 || length indices/=length values = bad
    | null ptr || ptr!!0/=0 || last ptr/=length values = bad
    | any (\(a,b)->a<0 || b<a || b>length values) (zip ptr (drop 1 ptr)) = bad
    | any (\i->i<0 || i>=inner) indices = bad
    | any (\part->any (uncurry (>=)) (zip (map fst part) (drop 1 (map fst part)))) parts = bad
    | otherwise = Right parts
    where bad=Left (InvalidArgument "sparse compressed format: invalid pointers, indices, or ordering")
          parts=[take (ptr!!(i+1)-ptr!!i) (drop (ptr!!i) (zip indices values)) | i<-[0..outer-1]]
fromFormat :: (Eq a,Num a) => SparseFormat a -> Either MathError (Sparse a)
fromFormat (COO r c xs) = sparse r c xs
fromFormat (CSR r c ptr indices values) = do
    shapeValid r c
    rows<-segments r c ptr indices values
    sparse r c [(i,j,v) | (i,row)<-zip [0..] rows,(j,v)<-row]
fromFormat (CSC r c ptr indices values) = sparseTranspose <$> fromFormat (CSR c r ptr indices values)
fromFormat (DIA r c diagonals) = do
    shapeValid r c
    if any ((/=r) . length . snd) diagonals || length (M.fromList [(k,()) | (k,_)<-diagonals])/=length diagonals
        || any (\(k,vs)->any (\(i,v)->(toInteger i+toInteger k<0 || toInteger i+toInteger k>=toInteger c) && v/=0) (zip [0::Int ..] vs)) diagonals
      then Left (InvalidArgument "DIA: invalid lengths, duplicate offsets, or nonzero padding")
      else sparse r c [(i,i+k,v) | (k,vs)<-diagonals,(i,v)<-zip [0..] vs,v/=0]
fromFormat (BSR r c br bc ptr cols blocks) = do
    shapeValid r c
    if br<=0 || bc<=0 || toInteger br*toInteger bc>toInteger (maxBound::Int) then Left (InvalidArgument "BSR: invalid block size") else do
        let nr=fromInteger ((toInteger r+toInteger br-1) `div` toInteger br)
            nc=fromInteger ((toInteger c+toInteger bc-1) `div` toInteger bc)
        rows<-segments nr nc ptr cols blocks
        if any ((/=br*bc) . length) blocks then Left (InvalidArgument "BSR: incorrect block element count") else do
            let coords=[(bi*br+i,bj*bc+j,vs!!(i*bc+j)) | (bi,row)<-zip [0..] rows,(bj,vs)<-row,i<-[0..br-1],j<-[0..bc-1]]
            if any (\(i,j,v)->(i>=r || j>=c) && v/=0) coords then Left (InvalidArgument "BSR: nonzero edge padding")
                else sparse r c [(i,j,v) | (i,j,v)<-coords,i<r,j<c]
fromFormat (ELLPACK r c width indices values) = do
    shapeValid r c
    if width<0 || toInteger r*toInteger width>toInteger (maxBound::Int) || length indices/=r*width || length values/=r*width
      then Left (InvalidArgument "ELLPACK: invalid width or slot count")
      else do
        let rows=[take width (drop (i*width) (zip indices values)) | i<-[0..r-1]]
            valid row = let active=takeWhile ((/=(-1)) . fst) row; padding=drop (length active) row
                        in all (\(j,_)->j>=0&&j<c) active && all (\(j,v)->j==(-1)&&v==0) padding
                           && and (zipWith (<) (map fst active) (drop 1 (map fst active)))
        if not (all valid rows) then Left (InvalidArgument "ELLPACK: malformed indices or padding")
            else sparse r c [(i,j,v) | (i,row)<-zip [0..] rows,(j,v)<-row,j/=(-1)]
toCOO :: Sparse a -> SparseFormat a
toCOO a = let (r,c)=sparseShape a in COO r c (sparseEntries a)
toCSR :: Sparse a -> SparseFormat a
toCSR a = let (r,c)=sparseShape a; xs=sparseEntries a
              counts=M.fromListWith (+) [(i,1::Int) | (i,_,_)<-xs]
          in CSR r c (scanl (+) 0 [M.findWithDefault 0 i counts | i<-[0..r-1]]) [j | (_,j,_)<-xs] [v | (_,_,v)<-xs]
toCSC :: Sparse a -> SparseFormat a
toCSC a = case toCSR (sparseTranspose a) of CSR c r p i v->CSC r c p i v; _->error "toCSC invariant"
toDIA :: Num a => Sparse a -> SparseFormat a
toDIA a = let (r,c)=sparseShape a; xs=sparseEntries a
              offsets=M.keys (M.fromList [(j-i,()) | (i,j,_)<-xs])
              vals=M.fromList [((i,j),v) | (i,j,v)<-xs]
          in DIA r c [(k,[M.findWithDefault 0 (i,i+k) vals | i<-[0..r-1]]) | k<-offsets]
toBSR :: Num a => Int -> Int -> Sparse a -> Either MathError (SparseFormat a)
toBSR br bc a
    | br<=0 || bc<=0 || toInteger br*toInteger bc>toInteger (maxBound::Int) = Left (InvalidArgument "toBSR: invalid block size")
    | otherwise = do
        let groups=M.fromListWith (++) [((i `div` br,j `div` bc),[(i `mod` br,j `mod` bc,v)]) | (i,j,v)<-sparseEntries a]
            nr=fromInteger ((toInteger r+toInteger br-1) `div` toInteger br)
            counts=M.fromListWith (+) [(i,1::Int) | ((i,_),_)<-M.toAscList groups]
            block vs=let vals=M.fromList [((i,j),v) | (i,j,v)<-vs] in [M.findWithDefault 0 (i,j) vals | i<-[0..br-1],j<-[0..bc-1]]
        Right (BSR r c br bc (scanl (+) 0 [M.findWithDefault 0 i counts | i<-[0..nr-1]]) [j | ((_,j),_)<-M.toAscList groups] [block vs | (_,vs)<-M.toAscList groups])
    where (r,c)=sparseShape a
toELLPACK :: Num a => Sparse a -> Either MathError (SparseFormat a)
toELLPACK a
    | toInteger r*toInteger width>toInteger (maxBound::Int) = Left (InvalidArgument "toELLPACK: slot overflow")
    | otherwise = Right (ELLPACK r c width (concat [map fst (row i)++replicate (width-length (row i)) (-1) | i<-[0..r-1]]) (concat [map snd (row i)++replicate (width-length (row i)) 0 | i<-[0..r-1]]))
    where (r,c)=sparseShape a; rows=M.fromListWith (++) [(i,[(j,v)]) | (i,j,v)<-sparseEntries a]
          row i=sortOn fst (M.findWithDefault [] i rows)
          width=maximum (0:map length (M.elems rows))
sparseToDense :: Num a => Sparse a -> Either MathError (Matrix a)
sparseToDense (Sparse r c xs) = fromListChecked r c (if r==0||c==0 then [] else [M.findWithDefault 0 (i,j) xs | i<-[0..r-1],j<-[0..c-1]])
denseToSparse :: (Eq a,Num a) => Matrix a -> Sparse a
denseToSparse a = Sparse r c (M.fromList [((k `div` c,k `mod` c),v) | (k,v)<-zip [0..] (toList a),v/=0])
    where (r,c)=shape a
sparseTranspose :: Sparse a -> Sparse a
sparseTranspose (Sparse r c xs) = Sparse c r (M.mapKeys (\(i,j)->(j,i)) xs)
sparseAdd :: (Eq a,Num a) => Sparse a -> Sparse a -> Either MathError (Sparse a)
sparseAdd (Sparse r c a) (Sparse s t b)
    | (r,c)/=(s,t) = Left (ShapeMismatch (r,c) (s,t))
    | otherwise = Right (Sparse r c (M.filter (/=0) (M.unionWith (+) a b)))
sparseSubtract :: (Eq a,Num a) => Sparse a -> Sparse a -> Either MathError (Sparse a)
sparseSubtract a (Sparse r c b) = sparseAdd a (Sparse r c (M.map negate b))
spmv :: Num a => Sparse a -> [a] -> Either MathError [a]
spmv (Sparse r c xs) vector
    | length vector/=c = Left (VectorLengthMismatch c (length vector))
    | r==0 = Right []
    | otherwise = let input=listArray (0,c-1) vector
                      sums=accumArray (+) 0 (0,r-1) [(i,v*(input!j)) | ((i,j),v)<-M.toAscList xs]
                  in Right (elems sums)
spmm :: (Eq a,Num a) => Sparse a -> Sparse a -> Either MathError (Sparse a)
spmm (Sparse r c a) (Sparse s t b)
    | c/=s = Left (InnerDimensionMismatch c s)
    | otherwise = sparse r t [(i,j,x*y) | ((i,k),x)<-M.toAscList a,(j,y)<-M.findWithDefault [] k rowsB]
    where rowsB=M.fromListWith (++) [(k,[(j,v)]) | ((k,j),v)<-M.toAscList b]
sparseKronecker :: (Eq a,Num a) => Sparse a -> Sparse a -> Either MathError (Sparse a)
sparseKronecker a b
    | toInteger r*toInteger s>toInteger (maxBound::Int) || toInteger c*toInteger t>toInteger (maxBound::Int) = Left (InvalidArgument "sparseKronecker: dimension overflow")
    | otherwise = sparse (r*s) (c*t) [(i*s+k,j*t+l,x*y) | (i,j,x)<-sparseEntries a,(k,l,y)<-sparseEntries b]
    where (r,c)=sparseShape a; (s,t)=sparseShape b
sparseTriangularSolve :: RealFloat a => Bool -> Sparse a -> [a] -> Either MathError [a]
sparseTriangularSolve lower a@(Sparse n m values) b
    | n/=m = Left (NonSquareMatrix (n,m))
    | length b/=n = Left (VectorLengthMismatch n (length b))
    | any (\(i,j,_)->if lower then j>i else j<i) (sparseEntries a) = Left (DomainError "sparseTriangularSolve: wrong triangular structure")
    | otherwise = do
        finiteValues (b++M.elems values)
        solved<-foldM step M.empty (if lower then [0..n-1] else reverse [0..n-1])
        Right [M.findWithDefault 0 i solved | i<-[0..n-1]]
    where
    rows=M.fromListWith (++) [(i,[(j,v)]) | ((i,j),v)<-M.toAscList values]
    step xs i = let pivot=M.findWithDefault 0 (i,i) values
                    v=(b!!i-sum [x*M.findWithDefault 0 j xs | (j,x)<-M.findWithDefault [] i rows,j/=i])/pivot
                in if pivot==0 then Left (SingularMatrix i) else finiteValues [v] >> Right (M.insert i v xs)
sparseDiagonalSolve :: RealFloat a => Sparse a -> [a] -> Either MathError [a]
sparseDiagonalSolve a b
    | any (\(i,j,_)->i/=j) (sparseEntries a) = Left (DomainError "sparseDiagonalSolve: diagonal matrix required")
    | otherwise = sparseTriangularSolve True a b

data SparseLU a = SparseLU (Sparse a) (Sparse a) [Int] deriving (Eq,Show)
sparseLULower :: SparseLU a -> Sparse a
sparseLULower (SparseLU l _ _) = l
sparseLUUpper :: SparseLU a -> Sparse a
sparseLUUpper (SparseLU _ u _) = u
sparseLUPermutation :: SparseLU a -> [Int]
sparseLUPermutation (SparseLU _ _ p) = p
sparseLU :: RealFloat a => a -> Sparse a -> Either MathError (SparseLU a)
sparseLU tol a@(Sparse n m values)
    | n/=m = Left (NonSquareMatrix (n,m))
    | tol<0 || isNaN tol || isInfinite tol = Left InvalidTolerance
    | otherwise = do
        finiteValues (M.elems values)
        (rows,lower,p)<-foldM step (rowMaps,M.empty,[0..n-1]) [0..n-1]
        l<-sparse n n ([(i,i,1) | i<-[0..n-1]]++[(i,j,v) | ((i,j),v)<-M.toAscList lower])
        u<-sparse n n [(i,j,v) | (i,row)<-M.toAscList rows,(j,v)<-M.toAscList row]
        Right (SparseLU l u p)
    where
    rowMaps=M.fromListWith M.union [(i,M.singleton j v) | (i,j,v)<-sparseEntries a]
    scale=maximum (0:map abs (M.elems values))
    step (rows,l,p) k = do
        let row i=M.findWithDefault M.empty i rows
            pv i=M.findWithDefault 0 k (row i)
            pivot=fst (maximumBy (comparing snd) [(i,abs (pv i)) | i<-[k..n-1]])
            pivotValue=pv pivot
        if pivotValue==0 then Left (SingularMatrix k)
         else if abs pivotValue<=tol*scale then Left (NearSingularMatrix k) else do
            let swapped=M.insert pivot (row k) (M.insert k (row pivot) rows)
                lsw=M.mapKeys (\(i,j)->(if i==k then pivot else if i==pivot then k else i,j)) l
                pr=M.findWithDefault M.empty k swapped
                update acc i = do
                    (rs,ls)<-acc
                    let ri=M.findWithDefault M.empty i rs
                        multiplier=M.findWithDefault 0 k ri/pivotValue
                        next=M.filter (/=0) (M.delete k (M.unionWith (+) ri (M.map (negate . (multiplier*)) pr)))
                    finiteValues (multiplier:M.elems next)
                    Right (M.insert i next rs,if multiplier==0 then ls else M.insert (i,k) multiplier ls)
            (nextRows,nextL)<-foldl update (Right (swapped,lsw)) [k+1..n-1]
            Right (nextRows,nextL,swap k pivot p)
sparseSolveLU :: RealFloat a => SparseLU a -> [a] -> Either MathError [a]
sparseSolveLU f b
    | length b/=n = Left (VectorLengthMismatch n (length b))
    | otherwise = sparseTriangularSolve True (sparseLULower f) [b!!i | i<-sparseLUPermutation f] >>= sparseTriangularSolve False (sparseLUUpper f)
    where n=fst (sparseShape (sparseLULower f))
sparseCholesky :: RealFloat a => Sparse a -> Either MathError (Sparse a)
sparseCholesky a@(Sparse n m values)
    | n/=m = Left (NonSquareMatrix (n,m))
    | any (\(i,j,v)->abs (v-M.findWithDefault 0 (j,i) values)>1e-12*max 1 (abs v)) (sparseEntries a) = Left (DomainError "sparseCholesky: symmetric matrix required")
    | otherwise = do
        finiteValues (M.elems values)
        l<-foldM row M.empty [0..n-1]
        sparse n n [(i,j,v) | ((i,j),v)<-M.toAscList l]
    where
    row l i=foldM (entry i) l [0..i]
    entry i l j = do
        let value=M.findWithDefault 0 (i,j) values-sum [M.findWithDefault 0 (i,k) l*M.findWithDefault 0 (j,k) l | k<-[0..j-1]]
        if i==j && value<=0 then Left (NotPositiveDefinite i) else do
            let x=if i==j then sqrt value else value/M.findWithDefault 0 (j,j) l
            finiteValues [x]
            Right (if x==0 then l else M.insert (i,j) x l)

data SparseQR a = SparseQR (Sparse a) [(Int,[a])] deriving (Eq,Show)
sparseQRUpper :: SparseQR a -> Sparse a
sparseQRUpper (SparseQR r _) = r
-- | Sparse Householder QR retains only the R nonzeros and compact reflectors;
-- fill is retained, never silently dropped. Reflection vectors are dense tails.
sparseQR :: RealFloat a => Sparse a -> Either MathError (SparseQR a)
sparseQR a@(Sparse m n values) = do
    finiteValues (M.elems values)
    (result,reflectors)<-foldM step (a,[]) [0..min m n-1]
    Right (SparseQR result reflectors)
    where
    step (Sparse r c entriesMap,reflectors) k = do
        let xs=[M.findWithDefault 0 (i,k) entriesMap | i<-[k..m-1]]
            scale=maximum (0:map abs xs)
        if scale==0 then Right (Sparse r c entriesMap,reflectors) else do
            let scaled=map (/scale) xs
                alpha=if scaled!!0>=0 then negate (stableNorm scaled) else stableNorm scaled
                vector=(scaled!!0-alpha):drop 1 scaled
                unit=map (/stableNorm vector) vector
                columns=M.fromListWith (++) [(j,[(i,x)]) | ((i,j),x)<-M.toAscList entriesMap,i>=k,j>=k]
                updates=[((i,j),old-2*coefficient*(unit!!(i-k))) | (j,col)<-M.toAscList columns,
                    let vals=M.fromList col,
                    let coefficient=dotV unit [M.findWithDefault 0 i vals | i<-[k..m-1]],i<-[k..m-1],
                    let old=M.findWithDefault 0 i vals]
                next=M.filter (/=0) (M.union (M.fromList updates) entriesMap)
                cleaned=M.filterWithKey (\(i,j) _->not (j==k && i>k)) next
            finiteValues (M.elems cleaned)
            Right (Sparse r c cleaned,reflectors++[(k,unit)])
sparseQRApplyQT :: RealFloat a => SparseQR a -> [a] -> Either MathError [a]
sparseQRApplyQT (SparseQR r reflectors) b
    | length b/=fst (sparseShape r) = Left (VectorLengthMismatch (fst (sparseShape r)) (length b))
    | otherwise = finiteValues b >> foldM apply b reflectors
    where apply xs (start,v)=let coefficient=2*dotV v (drop start xs); next=take start xs++zipWith (\x y->x-coefficient*y) (drop start xs) v
                            in finiteValues next >> Right next
sparseGraph :: Sparse a -> Either MathError [(Int,[(Int,a)])]
sparseGraph a
    | n/=m = Left (NonSquareMatrix (n,m))
    | otherwise = let rows=M.fromListWith (++) [(i,[(j,v)]) | (i,j,v)<-sparseEntries a] in Right [(i,sortOn fst (M.findWithDefault [] i rows)) | i<-[0..n-1]]
    where (n,m)=sparseShape a
-- | Logical payload bytes: two machine-width indices and caller-provided scalar
-- width per nonzero. Runtime Map node overhead is implementation dependent.
sparseStorageBytes :: Int -> Sparse a -> Either MathError Integer
sparseStorageBytes scalarBytes a
    | scalarBytes<0 = Left (InvalidArgument "sparseStorageBytes: negative scalar width")
    | otherwise = Right (toInteger (nonzeros a)*(2*toInteger (sizeOf (undefined::Int))+toInteger scalarBytes)+2*toInteger (sizeOf (undefined::Int)))

data SparseTensor a = SparseTensor [Int] (M.Map [Int] a) deriving (Eq,Show)
sparseTensor :: (Eq a,Num a) => [Int] -> [([Int],a)] -> Either MathError (SparseTensor a)
sparseTensor dims values
    | any (<0) dims || any (\(is,_)->length is/=length dims || or (zipWith (\i d->i<0||i>=d) is dims)) values = Left (InvalidArgument "sparseTensor: shape or index invalid")
    | otherwise = Right (SparseTensor dims (M.filter (/=0) (M.fromListWith (+) values)))
sparseTensorShape :: SparseTensor a -> [Int]
sparseTensorShape (SparseTensor dims _) = dims
sparseTensorEntries :: SparseTensor a -> [([Int],a)]
sparseTensorEntries (SparseTensor _ xs) = M.toAscList xs
sparseTensorLookup :: Num a => SparseTensor a -> [Int] -> Either MathError a
sparseTensorLookup (SparseTensor dims xs) is
    | length is/=length dims || or (zipWith (\i d->i<0||i>=d) is dims) = Left (InvalidArgument "sparseTensorLookup: index out of bounds")
    | otherwise = Right (M.findWithDefault 0 is xs)

-- | Small-problem spectral reference backend. The caller explicitly authorizes
-- a dense element budget; oversized matrices fail before generating zeros.
-- This is not a scalable sparse eigensolver/SVD and never silently densifies.
sparseEigenReference :: Integer -> Sparse Double -> Either MathError Eigen
sparseEigenReference budget a = referenceDense budget a >>= eigen
sparseSVDReference :: Integer -> Sparse Double -> Either MathError SVD
sparseSVDReference budget a = referenceDense budget a >>= svd
referenceDense :: Integer -> Sparse Double -> Either MathError (Matrix Double)
referenceDense budget a
    | budget<0 || toInteger r*toInteger c>budget = Left (InvalidArgument "sparse spectral reference: dense element budget exceeded")
    | otherwise = sparseToDense a
    where (r,c)=sparseShape a
