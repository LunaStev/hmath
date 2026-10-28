-- SPDX-License-Identifier: MPL-2.0

{- | Exact integer algorithms. Expensive searches take an explicit nonnegative
iteration budget and report 'NonConvergence'. Primality by trial division is
proven; Miller--Rabin and Baillie--PSW are explicitly probable-prime tests.
-}
module HMath.NumberTheory (
    gcdInteger,
    lcmInteger,
    extendedGCD,
    bezout,
    modPow,
    modInverse,
    chineseRemainder,
    linearDiophantine,
    integerSquareRoot,
    perfectPower,
    isPrimeExact,
    nextPrime,
    millerRabin,
    bailliePSW,
    sieveEratosthenes,
    sieveAtkin,
    segmentedSieve,
    primeFactorization,
    pollardRho,
    pollardPMinusOne,
    fermatFactor,
    divisors,
    divisorSum,
    divisorCount,
    eulerTotient,
    carmichael,
    mobius,
    liouville,
    multiplicativeOrder,
    primitiveRoot,
    discreteLog,
    legendreSymbol,
    jacobiSymbol,
    kroneckerSymbol,
    tonelliShanks,
    continuedFraction,
    fromContinuedFraction,
    convergents,
    farey,
    pellFundamental,
    isPerfectNumber,
    areAmicable,
    partitions,
    partitionCount,
    fibonacciFast,
) where

import Data.List (group, sort)
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import Data.Ratio (denominator, numerator, (%))
import qualified Data.Set as Set
import HMath.Error (MathError (..))

-- | Nonnegative greatest common divisor; @gcdInteger 0 0 = 0@.
gcdInteger :: Integer -> Integer -> Integer
gcdInteger = gcd

-- | Nonnegative least common multiple; zero if either argument is zero.
lcmInteger :: Integer -> Integer -> Integer
lcmInteger = lcm

-- | @(g,x,y)@ with @a*x+b*y=g>=0@, also for negative inputs and zero.
extendedGCD :: Integer -> Integer -> (Integer, Integer, Integer)
extendedGCD a b =
    let (g, x, y) = go (abs a) (abs b)
     in (g, x * signum a, y * signum b)
  where
    go u 0 = (u, 1, 0)
    go u v =
        let (q, r) = u `divMod` v; (g, x, y) = go v r
         in (g, y, x - q * y)

-- | Bezout coefficients only; see 'extendedGCD'.
bezout :: Integer -> Integer -> (Integer, Integer)
bezout a b = let (_, x, y) = extendedGCD a b in (x, y)

{- | Binary modular exponentiation. Modulus must be positive. Negative powers
use a modular inverse and fail when the base is not a unit.
-}
modPow :: Integer -> Integer -> Integer -> Either MathError Integer
modPow a e m
    | m <= 0 = Left (DomainError "modulus must be positive")
    | e < 0 = do
        v <- modInverse a m; pure (powMod v (-e) m)
    | otherwise = Right (powMod a e m)

powMod :: Integer -> Integer -> Integer -> Integer
powMod a e m = go (a `mod` m) e (1 `mod` m)
  where
    go _ 0 r = r
    go x k r =
        go
            ((x * x) `mod` m)
            (k `div` 2)
            (if odd k then (r * x) `mod` m else r)

-- | Canonical inverse residue in @[0,m)@. Modulus must exceed one.
modInverse :: Integer -> Integer -> Either MathError Integer
modInverse a m
    | m <= 1 = Left (DomainError "inverse modulus must exceed one")
    | g /= 1 = Left (DomainError "residue has no modular inverse")
    | otherwise = Right (x `mod` m)
  where
    (g, x, _) = extendedGCD a m

{- | Generalized CRT for @(residue,positive modulus)@ pairs. Compatible
noncoprime moduli are supported. Returns canonical residue and lcm modulus.
-}
chineseRemainder :: [(Integer, Integer)] -> Either MathError (Integer, Integer)
chineseRemainder = List.foldl' combine (Right (0, 1))
  where
    combine previous (b, n) = do
        (a, m) <- previous
        if n <= 0
            then Left (DomainError "CRT moduli must be positive")
            else do
                let (g, u, _) = extendedGCD m n
                if (b - a) `mod` g /= 0
                    then Left (DomainError "inconsistent congruences")
                    else
                        let modulus = m * (n `div` g)
                            k = (((b - a) `div` g) * u) `mod` (n `div` g)
                         in Right ((a + m * k) `mod` modulus, modulus)

{- | One solution and a direction: @(x,y,dx,dy)@ represents every solution
@(x+k*dx,y+k*dy)@ of @a*x+b*y=c@. The all-zero equation has a two-dimensional
solution set and is rejected instead of returning a misleading direction.
-}
linearDiophantine ::
    Integer ->
    Integer ->
    Integer ->
    Either MathError (Integer, Integer, Integer, Integer)
linearDiophantine a b c
    | g == 0 = Left (DomainError "degenerate Diophantine equation")
    | c `mod` g /= 0 = Left (DomainError "no integer solution")
    | otherwise = Right (x * (c `div` g), y * (c `div` g), b `div` g, -a `div` g)
  where
    (g, x, y) = extendedGCD a b

-- | Floor of the square root, computed by exact integer Newton iteration.
integerSquareRoot :: Integer -> Either MathError Integer
integerSquareRoot n
    | n < 0 = Left (DomainError "negative integer square root")
    | n < 2 = Right n
    | otherwise = Right (go n)
  where
    go x = let y = (x + n `div` x) `div` 2 in if y >= x then x else go y

rootFloor :: Int -> Integer -> Integer
rootFloor k n = search 0 (n + 1)
  where
    search a b
        | b - a <= 1 = a
        | otherwise =
            let c = (a + b) `div` 2
             in if c ^ k <= n then search c b else search a c

{- | Find a representation @n = base^exponent@ with exponent greater than one.
Zero, one, and minus one use exponent 2, 2, and 3 respectively.
-}
perfectPower :: Integer -> Maybe (Integer, Int)
perfectPower n
    | n == 0 = Just (0, 2)
    | n == 1 = Just (1, 2)
    | n == -1 = Just (-1, 3)
    | otherwise = seek 2
  where
    cap = bitLength (abs n)
    seek k
        | k > cap = Nothing
        | n < 0 && even k = seek (k + 1)
        | otherwise =
            let r = rootFloor k (abs n)
             in if r ^ k == abs n
                    then Just (if n < 0 then -r else r, k)
                    else seek (k + 1)

bitLength :: Integer -> Int
bitLength = go 0
  where
    go k 0 = k; go k n = go (k + 1) (n `div` 2)

-- | Proven primality using trial division. The budget counts trial divisors.
isPrimeExact :: Int -> Integer -> Either MathError Bool
isPrimeExact budget n
    | budget < 0 = Left (InvalidArgument "negative primality budget")
    | n < 2 = Right False
    | n == 2 = Right True
    | even n = Right False
    | otherwise = go budget 3
  where
    go left d
        | d * d > n = Right True
        | left == 0 = Left (NonConvergence "trial primality" budget)
        | n `mod` d == 0 = Right False
        | otherwise = go (left - 1) (d + 2)

{- | First proven prime at least the requested integer. The budget bounds both
candidate count and trial divisions per candidate.
-}
nextPrime :: Int -> Integer -> Either MathError Integer
nextPrime budget n
    | budget < 0 = Left (InvalidArgument "negative prime-search budget")
    | otherwise = go budget (max 2 n)
  where
    go 0 _ = Left (NonConvergence "prime search" budget)
    go left k = do
        p <- isPrimeExact budget k
        if p then Right k else go (left - 1) (k + 1)

{- | Strong Miller--Rabin for explicitly supplied bases (each >=2). Passing is
probable primality, not a proof. No random-base probability bound is claimed
for caller-selected deterministic bases. An empty base list is rejected.
-}
millerRabin :: [Integer] -> Integer -> Either MathError Bool
millerRabin bases n
    | null bases || any (< 2) bases = Left (InvalidArgument "Miller-Rabin needs bases >= 2")
    | n < 2 = Right False
    | n == 2 || n == 3 = Right True
    | even n = Right False
    | otherwise = Right (all strong bases)
  where
    (s, d) = splitTwos (n - 1)
    strong a
        | a `mod` n == 0 = True
        | otherwise =
            let x = powMod a d n
             in x == 1
                    || any
                        (== n - 1)
                        (take s (iterate (\z -> z * z `mod` n) x))

splitTwos :: Integer -> (Int, Integer)
splitTwos = go 0
  where
    go s d
        | even d && d /= 0 = go (s + 1) (d `div` 2)
        | otherwise = (s, d)

{- | Baillie--PSW: base-2 strong Miller--Rabin plus strong Lucas--Selfridge.
Perfect squares are rejected. Passing is probable primality for arbitrary
integers; no unproved claim of deterministic primality is made. Selfridge
parameter search is limited to 10000 discriminants.
-}
bailliePSW :: Integer -> Either MathError Bool
bailliePSW n
    | n < 2 = Right False
    | n == 2 = Right True
    | even n = Right False
    | otherwise = do
        r <- integerSquareRoot n
        mr <- millerRabin [2] n
        if r * r == n || not mr then Right False else choose 0 5
  where
    choose :: Int -> Integer -> Either MathError Bool
    choose k d
        | k == 10000 = Left (NonConvergence "Lucas-Selfridge parameters" k)
        | gcd n (abs d) > 1 && gcd n (abs d) < n = Right False
        | otherwise = do
            j <- jacobiSymbol d n
            if j == -1
                then Right (strongLucas d)
                else choose (k + 1) (if d > 0 then -d - 2 else -d + 2)
    strongLucas d =
        let q = (1 - d) `div` 4
            (s, k) = splitTwos (n + 1)
            (u, v) = lucasUV 1 q k n
            vs =
                take
                    s
                    ( map
                        fst
                        ( iterate
                            ( \(x, z) ->
                                ((x * x - 2 * z) `mod` n, z * z `mod` n)
                            )
                            (v, powMod q k n)
                        )
                    )
         in u == 0 || any (== 0) vs

lucasUV :: Integer -> Integer -> Integer -> Integer -> (Integer, Integer)
lucasUV p q k m =
    let (a, _, c, _) = matrixPower (p, -q, 1, 0) k
     in (c, (2 * a - p * c) `mod` m)
  where
    mul (a, b, c, d) (e, f, g, h) =
        ( (a * e + b * g) `mod` m
        , (a * f + b * h) `mod` m
        , (c * e + d * g) `mod` m
        , (c * f + d * h) `mod` m
        )
    matrixPower a e = go a e (1, 0, 0, 1)
    go _ 0 r = r
    go a e r = go (mul a a) (e `div` 2) (if odd e then mul r a else r)

-- | Eratosthenes sieve through an inclusive nonnegative upper bound.
sieveEratosthenes :: Int -> [Integer]
sieveEratosthenes bound = map toInteger (go [2 .. bound])
  where
    go [] = []
    go (p : xs)
        | p > bound `div` p = p : xs
        | otherwise = p : go (filter (\x -> x `mod` p /= 0) xs)

-- | Atkin quadratic-residue sieve, followed by removal of prime-square multiples.
sieveAtkin :: Int -> [Integer]
sieveAtkin bound
    | bound < 2 = []
    | otherwise = map toInteger (filter (<= bound) [2, 3] ++ Set.toAscList cleaned)
  where
    limit = floor (sqrt (fromIntegral bound :: Double))
    flipMember x s = if Set.member x s then Set.delete x s else Set.insert x s
    toggles =
        [ n
        | x <- [1 .. limit]
        , y <- [1 .. limit]
        , n <- [4 * x * x + y * y]
        , n <= bound
        , n `mod` 12 `elem` [1, 5]
        ]
            ++ [ n
               | x <- [1 .. limit]
               , y <- [1 .. limit]
               , n <- [3 * x * x + y * y]
               , n <= bound
               , n `mod` 12 == 7
               ]
            ++ [ n
               | x <- [1 .. limit]
               , y <- [1 .. x - 1]
               , n <- [3 * x * x - y * y]
               , n <= bound
               , n `mod` 12 == 11
               ]
    candidates = List.foldl' (flip flipMember) Set.empty toggles
    cleaned =
        List.foldl'
            ( \s p ->
                if Set.member p s
                    then List.foldl' (flip Set.delete) s [p * p, p * p + p * p .. bound]
                    else s
            )
            candidates
            [5 .. limit]

{- | Segmented sieve on the inclusive interval @[lo,hi]@. The segment width and
the square-root base sieve must fit an Int; reversed intervals are rejected.
-}
segmentedSieve :: Integer -> Integer -> Either MathError [Integer]
segmentedSieve lo hi
    | hi < lo = Left (InvalidArgument "reversed sieve interval")
    | hi < 2 = Right []
    | hi - lo + 1 > toInteger (maxBound :: Int) = Left (InvalidArgument "sieve segment too large")
    | otherwise = do
        r <- integerSquareRoot hi
        if r > toInteger (maxBound :: Int)
            then Left (InvalidArgument "base sieve too large")
            else
                let low = max 2 lo
                    remove s p =
                        List.foldl'
                            (flip Set.delete)
                            s
                            [ max (p * p) (((low + p - 1) `div` p) * p)
                            , max (p * p) (((low + p - 1) `div` p) * p) + p
                            .. hi
                            ]
                 in Right
                        ( Set.toAscList
                            ( List.foldl'
                                remove
                                (Set.fromList [low .. hi])
                                (sieveEratosthenes (fromInteger r))
                            )
                        )

{- | Exact trial factorization of a positive integer. The budget counts attempted
divisors (including repeated factors). One has an empty factorization.
-}
primeFactorization :: Int -> Integer -> Either MathError [(Integer, Int)]
primeFactorization budget n
    | budget < 0 = Left (InvalidArgument "negative factorization budget")
    | n < 1 = Left (DomainError "factorization requires a positive integer")
    | otherwise =
        fmap (map (\xs -> (case xs of x : _ -> x; [] -> 1, length xs)) . group) (go budget n 2)
  where
    go _ 1 _ = Right []
    go left k d
        | d * d > k = Right [k]
        | left == 0 = Left (NonConvergence "trial factorization" budget)
        | k `mod` d == 0 = (d :) <$> go (left - 1) (k `div` d) d
        | otherwise = go (left - 1) k (if d == 2 then 3 else d + 2)

{- | Pollard rho with Floyd cycle detection, explicit seed and iteration budget.
Returns a proper divisor or failure; a failed seed does not prove primality.
-}
pollardRho :: Int -> Integer -> Integer -> Either MathError Integer
pollardRho budget seed n
    | budget < 0 = Left (InvalidArgument "negative rho budget")
    | n < 4 = Left (DomainError "rho requires a composite candidate >=4")
    | even n = Right 2
    | otherwise = go budget (seed `mod` n) (seed `mod` n)
  where
    f x = (x * x + 1) `mod` n
    go 0 _ _ = Left (NonConvergence "Pollard rho" budget)
    go left x y =
        let a = f x; b = f (f y); d = gcd (abs (a - b)) n
         in if d == 1
                then go (left - 1) a b
                else
                    if d == n
                        then Left (NonConvergence "Pollard rho cycle" budget)
                        else Right d

{- | Pollard p-1 stage one with a smoothness bound >=2 and base. The exponent
includes the maximal powers of every prime <= the bound.
-}
pollardPMinusOne :: Int -> Integer -> Integer -> Either MathError Integer
pollardPMinusOne bound base n
    | bound < 2 || n < 4 = Left (DomainError "invalid p-1 bound or candidate")
    | g > 1 && g < n = Right g
    | otherwise =
        let power = lcmList [1 .. toInteger bound]
            d = gcd (powMod base power n - 1) n
         in if d > 1 && d < n
                then Right d
                else Left (NonConvergence "Pollard p-1" bound)
  where
    g = gcd base n
    lcmList = List.foldl' lcm 1

-- | Fermat difference-of-squares factorization, with an explicit step budget.
fermatFactor :: Int -> Integer -> Either MathError Integer
fermatFactor budget n
    | budget < 0 = Left (InvalidArgument "negative Fermat budget")
    | n < 4 = Left (DomainError "Fermat requires candidate >=4")
    | even n = Right 2
    | otherwise = do
        r <- integerSquareRoot n
        go budget (if r * r == n then r else r + 1)
  where
    go 0 _ = Left (NonConvergence "Fermat factorization" budget)
    go left a = do
        b <- integerSquareRoot (a * a - n)
        if b * b == a * a - n && a - b > 1
            then Right (a - b)
            else go (left - 1) (a + 1)

-- | All positive divisors in increasing order, under a factorization budget.
divisors :: Int -> Integer -> Either MathError [Integer]
divisors budget n = do
    fs <- primeFactorization budget n
    pure (sort (List.foldl' (\xs (p, k) -> [x * p ^ j | x <- xs, j <- [0 .. k]]) [1] fs))

-- | Sum of positive divisors.
divisorSum :: Int -> Integer -> Either MathError Integer
divisorSum budget n = sum <$> divisors budget n

-- | Number of positive divisors.
divisorCount :: Int -> Integer -> Either MathError Integer
divisorCount budget n = product . map (toInteger . (+ 1) . snd) <$> primeFactorization budget n

-- | Euler totient, including @phi(1)=1@.
eulerTotient :: Int -> Integer -> Either MathError Integer
eulerTotient budget n = do
    fs <- primeFactorization budget n
    pure (List.foldl' (\a (p, _) -> a `div` p * (p - 1)) n fs)

-- | Carmichael's exponent of the multiplicative unit group.
carmichael :: Int -> Integer -> Either MathError Integer
carmichael budget n = List.foldl' lcm 1 . map term <$> primeFactorization budget n
  where
    term (2, k) | k >= 3 = 2 ^ (k - 2)
    term (p, k) = (p - 1) * p ^ (k - 1)

-- | Mobius function on positive integers.
mobius :: Int -> Integer -> Either MathError Integer
mobius budget n = do
    fs <- primeFactorization budget n
    pure (if any ((> 1) . snd) fs then 0 else if even (length fs) then 1 else -1)

-- | Liouville function, counting prime factors with multiplicity.
liouville :: Int -> Integer -> Either MathError Integer
liouville budget n = do
    fs <- primeFactorization budget n
    pure (if even (sum (map snd fs)) then 1 else -1)

-- | Multiplicative order of a unit modulo a modulus >1.
multiplicativeOrder :: Int -> Integer -> Integer -> Either MathError Integer
multiplicativeOrder budget a m
    | m <= 1 || gcd a m /= 1 = Left (DomainError "order requires a unit modulo m>1")
    | otherwise = do
        phi <- eulerTotient budget m
        ds <- divisors budget phi
        case filter (\d -> powMod a d m == 1) ds of
            d : _ -> Right d
            [] -> Left (NonConvergence "multiplicative order" budget)

{- | Smallest generator of the units modulo m, if that group is cyclic. Search
and factorization are both bounded; noncyclic groups report a domain error.
-}
primitiveRoot :: Int -> Integer -> Either MathError Integer
primitiveRoot budget m = do
    phi <- eulerTotient budget m
    if m <= 1
        then Left (DomainError "primitive root modulus must exceed one")
        else do
            fs <- primeFactorization budget phi
            let candidates = take budget [1 .. m - 1]
                valid a = gcd a m == 1 && all (\(p, _) -> powMod a (phi `div` p) m /= 1) fs
            case filter valid candidates of
                a : _ -> Right a
                []
                    | toInteger budget >= m - 1 -> Left (DomainError "unit group has no primitive root")
                    | otherwise -> Left (NonConvergence "primitive root search" budget)

{- | Baby-step giant-step discrete logarithm of a unit. Budget bounds the table
dimension, so storage is O(budget) and work O(budget*log budget), apart
from integer arithmetic. The smallest nonnegative exponent is returned.
-}
discreteLog :: Int -> Integer -> Integer -> Integer -> Either MathError Integer
discreteLog budget a b m
    | budget < 0 = Left (InvalidArgument "negative discrete-log budget")
    | m <= 1 || gcd a m /= 1 || gcd b m /= 1 = Left (DomainError "discrete log needs units modulo m>1")
    | otherwise = do
        r <- integerSquareRoot m
        let width = r + 1
        if width > toInteger budget
            then Left (NonConvergence "discrete logarithm" budget)
            else do
                inv <- modInverse (powMod a width m) m
                let table =
                        Map.fromListWith
                            min
                            ( zip
                                ( take
                                    (fromInteger width)
                                    (iterate (\x -> x * a `mod` m) 1)
                                )
                                [0 ..]
                            )
                    matches =
                        [ i * width + j
                        | (i, v) <- zip [0 .. width] (iterate (\x -> x * inv `mod` m) (b `mod` m))
                        , Just j <- [Map.lookup v table]
                        ]
                case matches of
                    [] -> Left (DomainError "discrete logarithm does not exist")
                    xs -> Right (minimum xs)

-- | Legendre symbol for a proven odd prime modulus, with proof budget.
legendreSymbol :: Int -> Integer -> Integer -> Either MathError Integer
legendreSymbol budget a p = do
    prime <- isPrimeExact budget p
    if not prime || p == 2
        then Left (DomainError "Legendre modulus must be an odd prime")
        else let x = powMod a ((p - 1) `div` 2) p in Right (if x == p - 1 then -1 else x)

-- | Jacobi symbol for a positive odd denominator.
jacobiSymbol :: Integer -> Integer -> Either MathError Integer
jacobiSymbol a n
    | n <= 0 || even n = Left (DomainError "Jacobi denominator must be positive odd")
    | otherwise = Right (go (a `mod` n) n 1)
  where
    go 0 m r = if m == 1 then r else 0
    go x m r =
        let (s, u) = splitTwos x
            r1 = if odd s && m `mod` 8 `elem` [3, 5] then -r else r
            r2 = if u `mod` 4 == 3 && m `mod` 4 == 3 then -r1 else r1
         in go (m `mod` u) u r2

-- | Kronecker symbol, extending Jacobi to every integer denominator.
kroneckerSymbol :: Integer -> Integer -> Integer
kroneckerSymbol a n
    | n == 0 = if abs a == 1 then 1 else 0
    | otherwise =
        let sign = if n < 0 && a < 0 then -1 else 1
            (s, u) = splitTwos (abs n)
            two = if even a then 0 else if a `mod` 8 `elem` [1, 7] then 1 else -1
            oddPart = either (const 0) id (jacobiSymbol a u)
         in sign * (if s == 0 then 1 else two ^ s) * oddPart

{- | Tonelli--Shanks modular square root for a proven prime modulus. Returns the
smaller of the two roots; a nonresidue is a domain error. Proof and nonresidue
search each respect the supplied budget.
-}
tonelliShanks :: Int -> Integer -> Integer -> Either MathError Integer
tonelliShanks budget a p = do
    prime <- isPrimeExact budget p
    if not prime
        then Left (DomainError "square-root modulus must be prime")
        else
            if p == 2
                then Right (a `mod` 2)
                else
                    if a `mod` p == 0
                        then Right 0
                        else do
                            symbol <- legendreSymbol budget a p
                            if symbol /= 1
                                then Left (DomainError "quadratic nonresidue")
                                else do
                                    let (s, q) = splitTwos (p - 1)
                                        nonres = [z | z <- take budget [2 .. p - 1], powMod z ((p - 1) `div` 2) p == p - 1]
                                    case nonres of
                                        [] -> Left (NonConvergence "Tonelli-Shanks nonresidue" budget)
                                        z : _ -> do
                                            r <- loop s (powMod z q p) (powMod a q p) (powMod a ((q + 1) `div` 2) p)
                                            Right (min r (p - r))
  where
    loop m c t r
        | t == 1 = Right r
        | otherwise = case [i | i <- [1 .. m - 1], powMod t (2 ^ i) p == 1] of
            [] -> Left (NonConvergence "Tonelli-Shanks" budget)
            i : _ ->
                let b = powMod c (2 ^ (m - i - 1)) p
                 in loop i (b * b `mod` p) (t * b * b `mod` p) (r * b `mod` p)

-- | Finite simple continued fraction of a rational, using floor division.
continuedFraction :: Rational -> [Integer]
continuedFraction r = go (numerator r) (denominator r)
  where
    go a b = let (q, s) = a `divMod` b in q : if s == 0 then [] else go b s

-- | Evaluate a finite continued fraction. Empty lists and zero tails fail.
fromContinuedFraction :: [Integer] -> Either MathError Rational
fromContinuedFraction [] = Left (InvalidArgument "empty continued fraction")
fromContinuedFraction [a] = Right (a % 1)
fromContinuedFraction (a : xs) = do
    r <- fromContinuedFraction xs
    if r == 0
        then Left (DomainError "zero continued-fraction tail")
        else Right (fromInteger a + 1 / r)

-- | Successive convergents, rejecting invalid finite prefixes.
convergents :: [Integer] -> Either MathError [Rational]
convergents xs = mapM (fromContinuedFraction . (`take` xs)) [1 .. length xs]

-- | Farey sequence of positive order, including zero and one.
farey :: Integer -> Either MathError [Rational]
farey n
    | n < 1 = Left (DomainError "Farey order must be positive")
    | otherwise = Right (0 : go 0 1 1 n)
  where
    go a b c d
        | c > d = []
        | otherwise = (c % d) : let k = (n + b) `div` d in go c d (k * c - a) (k * d - b)

-- | Minimal positive solution to @x^2-d*y^2=1@ via continued fractions of sqrt d.
pellFundamental :: Int -> Integer -> Either MathError (Integer, Integer)
pellFundamental budget d
    | budget < 0 = Left (InvalidArgument "negative Pell budget")
    | d <= 0 = Left (DomainError "Pell d must be positive nonsquare")
    | otherwise = do
        a0 <- integerSquareRoot d
        if a0 * a0 == d
            then Left (DomainError "Pell d must be nonsquare")
            else go budget a0 0 1 a0 1 0 0 1
  where
    go 0 _ _ _ _ _ _ _ _ = Left (NonConvergence "Pell equation" budget)
    go left a0 m den a hm1 hm2 km1 km2 =
        let h = a * hm1 + hm2
            k = a * km1 + km2
            m' = den * a - m
            den' = (d - m' * m') `div` den
            a' = (a0 + m') `div` den'
         in if h * h - d * k * k == 1
                then Right (h, k)
                else go (left - 1) a0 m' den' a' h hm1 k km1

-- | Perfect-number predicate on positive integers.
isPerfectNumber :: Int -> Integer -> Either MathError Bool
isPerfectNumber budget n = (== 2 * n) <$> divisorSum budget n

-- | Amicable-number predicate; equal numbers are not an amicable pair.
areAmicable :: Int -> Integer -> Integer -> Either MathError Bool
areAmicable budget a b = do
    sa <- divisorSum budget a
    sb <- divisorSum budget b
    pure (a /= b && sa - a == b && sb - b == a)

-- | Integer partitions in descending part order. Zero has one empty partition.
partitions :: Int -> Either MathError [[Int]]
partitions n
    | n < 0 = Left (DomainError "negative partition argument")
    | otherwise = Right (go n n)
  where
    go 0 _ = [[]]
    go k top = [p : rest | p <- [min top k, min top k - 1 .. 1], rest <- go (k - p) p]

-- | Partition count by exact dynamic programming, O(n^2) work and O(n) storage.
partitionCount :: Int -> Either MathError Integer
partitionCount n
    | n < 0 = Left (DomainError "negative partition argument")
    | otherwise = Right (sum (drop n (List.foldl' addCoin (1 : replicate n 0) [1 .. n])))
  where
    addCoin xs k = take k xs ++ zipWith (+) (drop k xs) result
      where
        result = addCoin xs k

-- | Signed-index Fibonacci by fast doubling; @F(-n)=(-1)^(n+1)F(n)@.
fibonacciFast :: Integer -> Integer
fibonacciFast n
    | n < 0 && even n = -fst (pair (-n))
    | otherwise = fst (pair (abs n))
  where
    pair 0 = (0, 1)
    pair k =
        let (a, b) = pair (k `div` 2); c = a * (2 * b - a); d = a * a + b * b
         in if even k then (c, d) else (d, c + d)
