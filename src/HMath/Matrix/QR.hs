-- SPDX-License-Identifier: MPL-2.0
-- | Column-pivoted Householder QR. @A[:, permutation] = Q R@, with square Q.
-- Least squares requires m >= n and full column rank. Ridge uses augmented QR,
-- avoiding formation of the normal equations. Relative rank tolerance defaults
-- to max(m,n) times machine epsilon; callers may select an explicit tolerance.
module HMath.Matrix.QR
    ( QR, qrDecompose, qrDecomposeWithTolerance, qrQ, qrR, qrPermutation
    , qrRank, applyQ, applyQT, leastSquares, leastSquaresMatrix
    , solveQR, solveMatrixQR, ridgeSolve, ridgeSolveMatrix ) where

import Control.Monad (foldM)
import Data.List (maximumBy, transpose)
import Data.Ord (comparing)
import HMath.Error
import HMath.Matrix
import HMath.Matrix.Internal

data QR a = QR (Matrix a) (Matrix a) [Int] Int deriving (Eq,Show)
qrQ :: QR a -> Matrix a
qrQ (QR q _ _ _) = q
qrR :: QR a -> Matrix a
qrR (QR _ r _ _) = r
qrPermutation :: QR a -> [Int]
qrPermutation (QR _ _ p _) = p
qrRank :: QR a -> Int
qrRank (QR _ _ _ r) = r
qrDecompose :: RealFloat a => Matrix a -> Either MathError (QR a)
qrDecompose a = qrDecomposeWithTolerance (defaultTolerance a) a
qrDecomposeWithTolerance :: RealFloat a => a -> Matrix a -> Either MathError (QR a)
qrDecomposeWithTolerance tol a
    | tol < 0 || isNaN tol || isInfinite tol = Left InvalidTolerance
    | otherwise = do
        finiteMatrix a
        q0 <- identityChecked m
        (q,r,p) <- foldM step (entries q0, entries a,[0..n-1]) [0..min m n-1]
        qm <- fromListChecked m m (concat q)
        rm <- fromListChecked m n (concat r)
        finiteMatrix qm
        finiteMatrix rm
        let diagonals = [abs (r!!i!!i) | i<-[0..min m n-1]]
            scale = maximum (0:diagonals)
            rank = length [x | x<-diagonals, x>0, tol==0 || x/scale>tol]
        Right (QR qm rm p rank)
    where
    (m,n) = shape a
    step (q,r,p) k = do
        let candidates = [(j,stableNorm [r!!i!!j | i<-[k..m-1]]) | j<-[k..n-1]]
            pivot = fst (maximumBy (comparing snd) candidates)
            rs = map (swap k pivot) r
            x = [rs!!i!!k | i<-[k..m-1]]
            s = maximum (0:map abs x)
        if s==0 then Right (q,rs,swap k pivot p) else do
            let u = map (/s) x
                alpha = if u !! 0 >= 0 then negate (stableNorm u) else stableNorm u
                v0 = replace 0 (u !! 0-alpha) u
                v = map (/stableNorm v0) v0
                transform xs = let t=2*dotV v (drop k xs) in take k xs ++ zipWith (\z w -> z-t*w) (drop k xs) v
                rnew = transpose (map transform (transpose rs))
                qnew = map transform q
                rclean = [ [if j==k && i>k then 0 else rnew!!i!!j | j<-[0..n-1]] | i<-[0..m-1]]
            finiteValues (concat qnew++concat rclean)
            Right (qnew,rclean,swap k pivot p)
applyQ :: Num a => QR a -> Matrix a -> Either MathError (Matrix a)
applyQ f = multiplyChecked (qrQ f)
applyQT :: Num a => QR a -> Matrix a -> Either MathError (Matrix a)
applyQT f = multiplyChecked (transposeMatrix (qrQ f))
solveMatrixQR :: RealFloat a => QR a -> Matrix a -> Either MathError (Matrix a)
solveMatrixQR f b
    | m<n = Left (InvalidArgument "leastSquares: underdetermined system")
    | fst (shape b)/=m = Left (RightHandSideMismatch m (fst (shape b)))
    | qrRank f<n = Left (RankDeficient (qrRank f))
    | otherwise = do
        finiteMatrix b
        if n==0 || snd (shape b)==0 then fromListChecked n (snd (shape b)) [] else do
          y <- applyQT f b
          let solveColumn j = foldM (back y j) [] (reverse [0..n-1])
              back ymat j xs i = do
                  let value = (get ymat i j - sum [get r i k * (xs!!(k-i-1)) | k<-[i+1..n-1]]) / get r i i
                  finiteValues [value]
                  Right (value:xs)
          columns <- traverse solveColumn [0..snd (shape b)-1]
          build n (snd (shape b)) (\i j -> let pos=case lookup i (zip (qrPermutation f) [0..]) of Just k->k; Nothing->i in columns!!j!!pos)
    where r=qrR f; (m,n)=shape r
solveQR :: RealFloat a => QR a -> [a] -> Either MathError [a]
solveQR f b = do
    rhs <- fromListChecked (length b) 1 b
    toList <$> solveMatrixQR f rhs
leastSquares :: RealFloat a => Matrix a -> [a] -> Either MathError [a]
leastSquares a b = qrDecompose a >>= (`solveQR` b)
leastSquaresMatrix :: RealFloat a => Matrix a -> Matrix a -> Either MathError (Matrix a)
leastSquaresMatrix a b = qrDecompose a >>= (`solveMatrixQR` b)
ridgeSolve :: RealFloat a => a -> Matrix a -> [a] -> Either MathError [a]
ridgeSolve lambda a b = do
    rhs <- fromListChecked (length b) 1 b
    toList <$> ridgeSolveMatrix lambda a rhs
ridgeSolveMatrix :: RealFloat a => a -> Matrix a -> Matrix a -> Either MathError (Matrix a)
ridgeSolveMatrix lambda a b
    | lambda < 0 || isNaN lambda || isInfinite lambda = Left (DomainError "ridgeSolve: finite nonnegative regularization required")
    | fst (shape b)/=m = Left (RightHandSideMismatch m (fst (shape b)))
    | lambda==0 = leastSquaresMatrix a b
    | otherwise = do
        finiteMatrix a
        finiteMatrix b
        if toInteger m + toInteger n > toInteger (maxBound::Int) then Left (InvalidArgument "ridgeSolve: shape overflow") else do
            augmented <- build (m+n) n (\i j -> if i<m then get a i j else if i-m==j then sqrt lambda else 0)
            rhs <- build (m+n) (snd (shape b)) (\i j -> if i<m then get b i j else 0)
            leastSquaresMatrix augmented rhs
    where (m,n)=shape a
