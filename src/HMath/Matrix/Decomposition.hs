-- SPDX-License-Identifier: MPL-2.0
-- | Pure reference decompositions with explicit shape and tolerance contracts.
-- Cholesky uses a symmetric positive-definite matrix; unpivoted LDL^T requires
-- nonzero scalar pivots. Bidiagonalization supports rectangular real matrices.
module HMath.Matrix.Decomposition
    ( gaussianElimination, gaussJordan, cholesky, ldlt, givensQR
    , Bidiagonal(..), bidiagonalize, tridiagonalize
    , Iteration(..), powerIteration, inverseIteration, rayleighIteration
    , Arnoldi(..), arnoldi, lanczos, qrIteration, jordanChains, jordanForm ) where

import Control.Monad (foldM)
import Data.List (maximumBy,nub,findIndex)
import Data.Ord (comparing)
import HMath.Error
import HMath.Matrix
import HMath.Matrix.Internal
import HMath.Matrix.LU (solve, inverse, luDecomposeWithTolerance, solveLU)
import HMath.Matrix.LAPACK (Hessenberg(..),hessenberg)

gaussianElimination :: RealFloat a => a -> Matrix a -> Either MathError (Matrix a,[Int])
gaussianElimination tol a = eliminate False tol a
gaussJordan :: RealFloat a => a -> Matrix a -> Either MathError (Matrix a,[Int])
gaussJordan tol a = eliminate True tol a
eliminate :: RealFloat a => Bool -> a -> Matrix a -> Either MathError (Matrix a,[Int])
eliminate reduced tol a
    | tol<0 || isNaN tol || isInfinite tol = Left InvalidTolerance
    | otherwise = do
        finiteMatrix a
        (rows,pivots)<-go 0 0 (entries a) []
        result<-fromListChecked m n (concat rows)
        finiteMatrix result
        Right (result,pivots)
    where
    (m,n)=shape a
    scale=maximum (0:map abs (toList a))
    go r c rows pivots
        | r>=m || c>=n = Right (rows,pivots)
        | otherwise = do
            let pivot=fst (maximumBy (comparing snd) [(i,abs (rows!!i!!c)) | i<-[r..m-1]])
                value=rows!!pivot!!c
            if value==0 || abs value<=tol*scale then go r (c+1) rows pivots else do
                let swapped=swap r pivot rows
                    normalized=map (/value) (swapped!!r)
                    update i row
                        | i==r = normalized
                        | (reduced && i/=r) || i>r = zipWith (-) row (map ((row!!c)*) normalized)
                        | otherwise = row
                    next=zipWith update [0..] swapped
                finiteValues (concat next)
                go (r+1) (c+1) next (pivots++[c])
checkSymmetric :: RealFloat a => Matrix a -> Either MathError Int
checkSymmetric a
    | n/=m = Left (NonSquareMatrix (n,m))
    | any (\(x,y)->abs (x-y)>defaultTolerance a*max 1 (max (abs x) (abs y))) (zip (toList a) (toList (transposeMatrix a))) = Left (DomainError "symmetric matrix required")
    | otherwise = finiteMatrix a >> Right n
    where (n,m)=shape a
cholesky :: RealFloat a => Matrix a -> Either MathError (Matrix a)
cholesky a = do
    n<-checkSymmetric a
    rows<-foldM (step n) [] [0..n-1]
    fromListChecked n n (concat rows)
    where
    step n rows i = do
        prefix<-foldM (entry rows i) [] [0..i]
        Right (rows++[prefix++replicate (n-i-1) 0])
    entry rows i xs j = do
        let value=get a i j-sum [xs!!k * (if i==j then xs!!k else rows!!j!!k) | k<-[0..j-1]]
        if i==j && value<=0 then Left (NotPositiveDefinite i) else do
            let result=if i==j then sqrt value else value/(rows!!j!!j)
            finiteValues [result]
            Right (xs++[result])
ldlt :: RealFloat a => Matrix a -> Either MathError (Matrix a,[a])
ldlt a = do
    n<-checkSymmetric a
    (rows,ds)<-foldM (step n) ([],[]) [0..n-1]
    lower<-fromListChecked n n (concat rows)
    Right (lower,ds)
    where
    step n (rows,ds) i = do
        prefix<-foldM (\xs j -> do
            let v=(get a i j-sum [xs!!k*rows!!j!!k*ds!!k | k<-[0..j-1]])/(ds!!j)
            finiteValues [v]
            Right (xs++[v])) [] [0..i-1]
        let d=get a i i-sum [prefix!!k*prefix!!k*ds!!k | k<-[0..i-1]]
        if d==0 then Left (SingularMatrix i) else do
            finiteValues [d]
            Right (rows++[prefix++1:replicate (n-i-1) 0],ds++[d])
givensQR :: RealFloat a => Matrix a -> Either MathError (Matrix a,Matrix a)
givensQR a = do
    finiteMatrix a
    q0<-identityChecked m
    let rotatePair (q,r) (j,i) = do
            let x=r!!j!!j; y=r!!i!!j; radius=stableNorm [x,y]
            if isNaN radius || isInfinite radius then Left NonFiniteResult else
              if radius==0 then Right (q,r) else do
                let c=x/radius; s=y/radius
                    rowJ=zipWith (\u v -> c*u+s*v) (r!!j) (r!!i)
                    rowI=zipWith (\u v -> -s*u+c*v) (r!!j) (r!!i)
                    rnew=replace i rowI (replace j rowJ r)
                    qnew=map (\row -> replace i (-s*(row!!j)+c*(row!!i)) (replace j (c*(row!!j)+s*(row!!i)) row)) q
                finiteValues (concat rnew++concat qnew)
                Right (qnew,rnew)
    (q,r)<-foldM rotatePair (entries q0,entries a) [(j,i) | j<-[0..min m n-1],i<-reverse [j+1..m-1]]
    (,) <$> fromListChecked m m (concat q) <*> fromListChecked m n (concat r)
    where (m,n)=shape a

data Bidiagonal a = Bidiagonal { bidiagonalU :: Matrix a, bidiagonalB :: Matrix a, bidiagonalV :: Matrix a } deriving (Eq,Show)
bidiagonalize :: RealFloat a => Matrix a -> Either MathError (Bidiagonal a)
bidiagonalize a = do
    finiteMatrix a
    u0<-identityChecked m
    v0<-identityChecked n
    (u,b,v)<-foldM step (u0,a,v0) [0..min m n-1]
    Right (Bidiagonal u b v)
    where
    (m,n)=shape a
    reflector size start xs = do
        let s=maximum (0:map abs xs)
        if s==0 then identityChecked size else do
            let y=map (/s) xs
                alpha=if y!!0>=0 then negate (stableNorm y) else stableNorm y
                z=replace 0 (y!!0-alpha) y
                unit=map (/stableNorm z) z
                vv=replicate start 0++unit
            build size size (\i j -> (if i==j then 1 else 0)-2*(vv!!i)*(vv!!j))
    step (u,b,v) k = do
        h<-reflector m k [get b i k | i<-[k..m-1]]
        b1<-multiplyChecked h b
        u1<-multiplyChecked u h
        finiteValues (toList b1++toList u1)
        if k+1>=n then Right (u1,b1,v) else do
            g<-reflector n (k+1) [get b1 k j | j<-[k+1..n-1]]
            b2<-multiplyChecked b1 g
            v1<-multiplyChecked v g
            finiteValues (toList b2++toList v1)
            Right (u1,b2,v1)
tridiagonalize :: Matrix Double -> Either MathError (Matrix Double,Matrix Double)
tridiagonalize a = do
    _<-checkSymmetric a
    f<-hessenberg a
    Right (hessenbergQ f,hessenbergH f)

data Iteration a = Iteration { iterationValue :: a, iterationVector :: [a], iterationResidual :: a, iterationCount :: Int } deriving (Eq,Show)
iterateEigen :: RealFloat a => String -> a -> Int -> (a -> [a] -> Either MathError [a]) -> Matrix a -> [a] -> Either MathError (Iteration a)
iterateEigen name tol budget action a initial
    | m/=n = Left (NonSquareMatrix (m,n))
    | length initial/=n = Left (VectorLengthMismatch n (length initial))
    | tol<=0 || isNaN tol || isInfinite tol = Left InvalidTolerance
    | budget<1 = Left (InvalidArgument "eigen iteration: positive budget required")
    | otherwise = do
        finiteMatrix a; finiteValues initial
        let norm=stableNorm initial
        if isNaN norm || isInfinite norm || isNaN matrixScale || isInfinite matrixScale then Left NonFiniteResult else
          if norm==0 then Left (DomainError "eigen iteration: initial vector is zero") else go 0 (map (/norm) initial)
    where
    (m,n)=shape a
    go k x = do
        let ax=[dotV row x | row<-entries a]
            lambda=dotV x ax
            residual=stableNorm (zipWith (\u v -> u-lambda*v) ax x)
        finiteValues (lambda:residual:ax)
        if residual / max 1 matrixScale <= tol then Right (Iteration lambda x residual k)
        else if k>=budget then Left (NonConvergence name budget) else do
            y<-action lambda x
            let norm=stableNorm y
            if isNaN norm || isInfinite norm then Left NonFiniteResult else
              if norm==0 then Left (DomainError (name++": zero iterate")) else go (k+1) (map (/norm) y)
    matrixScale=maximum (0:map (sum . map abs) (entries a))
powerIteration :: RealFloat a => a -> Int -> Matrix a -> [a] -> Either MathError (Iteration a)
powerIteration tol budget a = iterateEigen "powerIteration" tol budget (\_ x -> Right [dotV row x | row<-entries a]) a
inverseIteration :: RealFloat a => a -> Int -> a -> Matrix a -> [a] -> Either MathError (Iteration a)
inverseIteration tol budget shift a initial = do
    shifted<-build n n (\i j -> get a i j-if i==j then shift else 0)
    iterateEigen "inverseIteration" tol budget (\_ -> solve shifted) a initial
    where n=fst (shape a)
rayleighIteration :: RealFloat a => a -> Int -> Matrix a -> [a] -> Either MathError (Iteration a)
rayleighIteration tol budget a = iterateEigen "rayleighIteration" tol budget action a
    where
    n=fst (shape a)
    action shift x = do
        shifted<-build n n (\i j -> get a i j-if i==j then shift else 0)
        case luDecomposeWithTolerance 0 shifted >>= (`solveLU` x) of
            Left (SingularMatrix _) -> do
                -- The Rayleigh quotient can round to an exact eigenvalue
                -- before the vector residual reaches tolerance. Perturb the
                -- singular shift by one representable scale and continue.
                let delta=2*epsilon shift*max 1 (abs shift)
                regular<-build n n (\i j -> get a i j-if i==j then shift+delta else 0)
                luDecomposeWithTolerance 0 regular >>= (`solveLU` x)
            result -> result

data Arnoldi a = Arnoldi { arnoldiBasis :: Matrix a, arnoldiHessenberg :: Matrix a } deriving (Eq,Show)
arnoldi :: RealFloat a => a -> Int -> Matrix a -> [a] -> Either MathError (Arnoldi a)
arnoldi tol requested a initial
    | m/=n = Left (NonSquareMatrix (m,n))
    | length initial/=n = Left (VectorLengthMismatch n (length initial))
    | requested<1 || requested>n = Left (InvalidArgument "arnoldi: requested basis must be between one and matrix order")
    | tol<0 || isNaN tol || isInfinite tol = Left InvalidTolerance
    | otherwise = do
        finiteMatrix a; finiteValues initial
        if isNaN beta || isInfinite beta then Left NonFiniteResult else
          if beta==0 then Left (DomainError "arnoldi: zero initial vector") else go [map (/beta) initial] [] 0
    where
    (m,n)=shape a; beta=stableNorm initial
    go qs hs k = do
        let w0=[dotV row (qs!!k) | row<-entries a]
            orth (w,coeffs) q = let h=dotV q w in (zipWith (\x y->x-h*y) w q,coeffs++[h])
            (w1,h1)=foldl orth (w0,[]) qs
            (w2,h2)=foldl orth (w1,[]) qs
            coefficients=zipWith (+) h1 h2
            norm=stableNorm w2
            column=coefficients++[norm]
            done=norm/max 1 (stableNorm w0)<=tol || k+1==requested
            nextQs=if norm==0 then qs else qs++[map (/norm) w2]
        finiteValues (column++w2++[stableNorm w0])
        if done then do
            let count=k+1; rows=length nextQs
            qmat<-build n rows (\i j -> nextQs!!j!!i)
            hmat<-build rows count (\i j -> if i<length ((hs++[column])!!j) then (hs++[column])!!j!!i else 0)
            Right (Arnoldi qmat hmat)
        else go nextQs (hs++[column]) (k+1)
-- | Symmetric Lanczos with the three-term recurrence and two full
-- reorthogonalization passes. Small correction coefficients are retained in H
-- so the projection residual remains meaningful after floating-point rounding.
lanczos :: RealFloat a => a -> Int -> Matrix a -> [a] -> Either MathError (Arnoldi a)
lanczos tol requested a initial = do
    _<-checkSymmetric a
    if length initial/=n then Left (VectorLengthMismatch n (length initial))
      else if requested<1 || requested>n then Left (InvalidArgument "lanczos: invalid basis size")
      else if tol<0 || isNaN tol || isInfinite tol then Left InvalidTolerance else do
        finiteValues initial
        let beta=stableNorm initial
        if isNaN beta || isInfinite beta then Left NonFiniteResult else
          if beta==0 then Left (DomainError "lanczos: zero initial vector") else go [map (/beta) initial] [] 0 0
    where
    n=fst (shape a)
    go qs columns previousBeta k = do
        let q=qs!!k
            aq=[dotV row q | row<-entries a]
            alpha=dotV q aq
            previous=if k==0 then replicate n 0 else qs!!(k-1)
            residual=zipWith3 (\x y z->x-alpha*y-previousBeta*z) aq q previous
            orth (w,coeffs) basis = let h=dotV basis w in (zipWith (\x y->x-h*y) w basis,coeffs++[h])
            (w1,h1)=foldl orth (residual,[]) qs
            (w2,h2)=foldl orth (w1,[]) qs
            beta=stableNorm w2
            base=[if i==k then alpha else if i==k-1 then previousBeta else 0 | i<-[0..k]]
            column=zipWith3 (\x y z->x+y+z) base h1 h2++[beta]
            next=if beta==0 then qs else qs++[map (/beta) w2]
        finiteValues (column++w2++[stableNorm aq])
        if beta/max 1 (stableNorm aq)<=tol || k+1==requested then do
            qmat<-build n (length next) (\i j->next!!j!!i)
            hmat<-build (length next) (k+1) (\i j->if i<length ((columns++[column])!!j) then (columns++[column])!!j!!i else 0)
            Right (Arnoldi qmat hmat)
        else go next (columns++[column]) beta (k+1)
qrIteration :: RealFloat a => a -> Int -> Matrix a -> Either MathError (Matrix a,Matrix a)
qrIteration tol budget a
    | m/=n = Left (NonSquareMatrix (m,n))
    | tol<=0 || isNaN tol || isInfinite tol = Left InvalidTolerance
    | budget<1 = Left (InvalidArgument "qrIteration: positive budget required")
    | otherwise = do
        finiteMatrix a; q<-identityChecked n; go 0 q a
    where
    (m,n)=shape a
    go k q t
        | any (\x->isNaN x||isInfinite x) [offNorm,totalNorm] = Left NonFiniteResult
        | offNorm/max 1 totalNorm<=tol = Right (q,t)
        | k>=budget = Left (NonConvergence "qrIteration" budget)
        | otherwise = do
            -- Unpivoted Givens QR is required for a similarity iteration.
            (u,r)<-givensQR t
            next<-multiplyChecked r u
            qs<-multiplyChecked q u
            finiteValues (toList qs++toList next)
            go (k+1) qs next
        where
        offNorm=stableNorm [get t i j | i<-[0..n-1],j<-[0..i-1]]
        totalNorm=stableNorm (toList t)
-- | Verify supplied Jordan chains against A and lambda and construct J and P.
-- Computing a Jordan structure from floating input is ill posed; the caller
-- supplies chain vectors ordered eigenvector first. A P = P J is checked.
-- This API never pretends a Schur form is a Jordan form.
jordanChains :: RealFloat a => a -> Matrix a -> [(a,[[a]])] -> Either MathError (Matrix a,Matrix a)
jordanChains tol a chains
    | m/=n = Left (NonSquareMatrix (m,n))
    | tol<0 || isNaN tol || isInfinite tol = Left InvalidTolerance
    | length vectors/=n || any ((/=n) . length) vectors || any (null . snd) chains = Left (InvalidArgument "jordanChains: chains must form a square basis")
    | otherwise = do
        finiteMatrix a
        finiteValues (values++concat vectors)
        p<-build n n (\i j->vectors!!j!!i)
        _<-inverse p
        j<-build n n (\i col -> if i==col then values!!i else if col==i+1 && not (col `elem` starts) then 1 else 0)
        ap<-multiplyChecked a p
        pj<-multiplyChecked p j
        delta<-subtractMatrixChecked ap pj
        let deltaNorm=stableNorm (toList delta);apNorm=stableNorm (toList ap)
        finiteValues (toList p++toList j++toList ap++toList pj++toList delta++[deltaNorm,apNorm])
        if deltaNorm/max 1 apNorm>tol then Left (DomainError "jordanChains: chain residual exceeds tolerance") else Right (p,j)
    where
    (m,n)=shape a
    vectors=concatMap snd chains
    values=concat [replicate (length vs) value | (value,vs)<-chains]
    starts=scanl (+) 0 (map (length . snd) chains)

-- | Exact Jordan construction over Rational with a caller-provided complete
-- set of distinct rational eigenvalues (multiplicities are inferred). Unlike
-- floating Jordan algorithms this never uses a tolerance to decide structure.
-- Nullspaces of successive (A-lambda I) powers construct generalized chains.
-- An incomplete/nonrational spectrum is rejected rather than approximated.
jordanForm :: Matrix Rational -> [Rational] -> Either MathError (Matrix Rational,Matrix Rational)
jordanForm a spectrum
    | n/=m = Left (NonSquareMatrix (n,m))
    | nub spectrum/=spectrum = Left (InvalidArgument "jordanForm: provide distinct rational eigenvalues")
    | otherwise = do
        (vectors,blocks)<-foldM eigenChains ([],[]) spectrum
        if length vectors/=n then Left (DomainError "jordanForm: supplied rational spectrum is incomplete") else do
            p<-build n n (\i j->vectors!!j!!i)
            let values=concat [replicate size value | (value,size)<-blocks]
                starts=scanl (+) 0 (map snd blocks)
            j<-build n n (\i col->if i==col then values!!i else if col==i+1&&col `notElem` starts then 1 else 0)
            ap<-multiplyChecked a p
            pj<-multiplyChecked p j
            if ap/=pj || exactRank p/=n then Left (DomainError "jordanForm: exact chain construction failed") else Right (p,j)
    where
    (n,m)=shape a
    eigenChains (basis,blocks) lambda = do
        shifted<-build n n (\i j->get a i j-if i==j then lambda else 0)
        powers<-scanPowers shifted
        foldM (choose shifted powers lambda) (basis,blocks) (reverse [1..n])
    scanPowers shifted = do
        i<-identityChecked n
        foldM (\xs _->do next<-multiplyChecked (last xs) shifted;Right (xs++[next])) [i] [1..n]
    choose shifted powers lambda state k = foldM (candidate shifted lambda k) state (exactKernel (powers!!k))
    candidate shifted lambda k (basis,blocks) top = do
        let descending=take k (iterate (\x->[dotV row x | row<-entries shifted]) top)
            chain=reverse descending
        combined<-build n (length basis+k) (\i j->(basis++chain)!!j!!i)
        if exactRank combined==length basis+k then Right (basis++chain,blocks++[(lambda,k)]) else Right (basis,blocks)

exactRref :: Matrix Rational -> ([[Rational]],[Int])
exactRref a = go 0 0 (entries a) []
    where
    (r,c)=shape a
    go i j rows pivots
        | i>=r || j>=c = (rows,pivots)
        | otherwise = case findIndex (\row->row!!j/=0) (drop i rows) of
            Nothing->go i (j+1) rows pivots
            Just offset->let swapped=swap i (i+offset) rows
                             normalized=map (/(swapped!!i!!j)) (swapped!!i)
                             next=zipWith (\k row->if k==i then normalized else zipWith (-) row (map ((row!!j)*) normalized)) [0..] swapped
                         in go (i+1) (j+1) next (pivots++[j])
exactRank :: Matrix Rational -> Int
exactRank = length . snd . exactRref
exactKernel :: Matrix Rational -> [[Rational]]
exactKernel a = [[if j==free then 1 else case lookup j (zip pivots [0..]) of Just row->negate (rows!!row!!free);Nothing->0 | j<-[0..n-1]] | free<-[0..n-1],free `notElem` pivots]
    where (_,n)=shape a;(rows,pivots)=exactRref a
