-- SPDX-License-Identifier: MPL-2.0

{- | Finite-width bits, relations and propositional logic. Widths are explicit;
zero has both leading- and trailing-zero count equal to its width. Boolean
matrices use the OR/AND semiring. Logic enumerations are bounded to 12 inputs.
-}
module HMath.Discrete (
    MultiSet,
    multiset,
    multiplicity,
    multisetEntries,
    multisetInsert,
    multisetDelete,
    multisetUnion,
    multisetIntersection,
    multisetDifference,
    BitSet,
    bitSet,
    bitWidth,
    bitValue,
    bitMember,
    bitInsert,
    bitDelete,
    bitUnion,
    bitIntersection,
    bitDifference,
    resizeBitSet,
    populationCount,
    leadingZeros,
    trailingZeros,
    rotateBits,
    reverseBits,
    grayEncode,
    grayDecode,
    hammingDistance,
    setUnion,
    setIntersection,
    setDifference,
    symmetricDifference,
    transitiveClosure,
    equivalenceClosure,
    isEquivalence,
    booleanMultiply,
    Prop (..),
    evaluateProp,
    truthTable,
    Implicant (..),
    quineMcCluskey,
    implicantCovers,
) where

import Data.Bits hiding (And, Iff, Xor)
import Data.List (nub, sort)
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import HMath.Error (MathError (..))

{- | Finite multiset with exact nonnegative multiplicities. Union adds
multiplicities; intersection takes minima and difference truncates at zero.
-}
newtype MultiSet a = MultiSet (M.Map a Integer) deriving (Eq, Show)

{- | Construct a finite multiset by counting equal ordered values with exact nonnegative
Integer multiplicities.
-}
multiset :: (Ord a) => [a] -> MultiSet a
multiset xs = MultiSet (M.fromListWith (+) [(x, 1) | x <- xs])

-- | Given value then multiset, return its Integer frequency, or zero when absent.
multiplicity :: (Ord a) => a -> MultiSet a -> Integer
multiplicity x (MultiSet m) = M.findWithDefault 0 x m

-- | Return (value,positive multiplicity) pairs in ascending value order.
multisetEntries :: MultiSet a -> [(a, Integer)]
multisetEntries (MultiSet m) = M.toAscList m

-- | Given value then multiset, increment its multiplicity by one and return a new multiset.
multisetInsert :: (Ord a) => a -> MultiSet a -> MultiSet a
multisetInsert x (MultiSet m) = MultiSet (M.insertWith (+) x 1 m)

{- | Given value then multiset, remove one occurrence, deleting its entry at zero. Absent
values are a no-op.
-}
multisetDelete :: (Ord a) => a -> MultiSet a -> MultiSet a
multisetDelete x (MultiSet m) = MultiSet (M.update (\n -> if n <= 1 then Nothing else Just (n - 1)) x m)

multisetUnion
    , multisetIntersection
    , multisetDifference ::
        (Ord a) => MultiSet a -> MultiSet a -> MultiSet a

{- | Add multiplicities of two multisets, retaining all distinct values. This is multiset
sum rather than maximum-multiplicity union.
-}
multisetUnion (MultiSet a) (MultiSet b) = MultiSet (M.unionWith (+) a b)

-- | Return shared values with minimum of the two multiplicities.
multisetIntersection (MultiSet a) (MultiSet b) = MultiSet (M.intersectionWith min a b)

-- | Subtract right multiplicities from left, truncating at zero and removing empty entries.
multisetDifference (MultiSet a) (MultiSet b) = MultiSet (M.filter (> 0) (M.mapWithKey (\x n -> n - M.findWithDefault 0 x b) a))

-- | Opaque arbitrary-size dynamic bitset; bits outside its width are zero.
data BitSet = BitSet Int Integer deriving (Eq, Show)

{- | Given width in [0,1048576] then nonnegative Integer less than 2^width, construct an
opaque bitset. Invalid width/value fails; bit zero is least significant.
-}
bitSet :: Int -> Integer -> Either MathError BitSet
bitSet w v
    | w < 0 || w > 1048576 || v < 0 || v >= 2 ^ w =
        Left (InvalidArgument "bitset width/value out of range")
    | otherwise = Right (BitSet w v)

-- | Return declared number of bits, including leading zeros.
bitWidth :: BitSet -> Int
bitWidth (BitSet w _) = w

-- | Return unsigned Integer value of all bits within the declared width.
bitValue :: BitSet -> Integer
bitValue (BitSet _ v) = v

bitIndex :: BitSet -> Int -> Either MathError ()
bitIndex (BitSet w _) i
    | i < 0 || i >= w = Left (InvalidArgument "bit index out of bounds")
    | otherwise = Right ()

{- | Given bitset then zero-based bit index, return membership. Out-of-width or negative
indices return Left InvalidArgument.
-}
bitMember :: BitSet -> Int -> Either MathError Bool
bitMember b i = do bitIndex b i; pure (testBit (bitValue b) i)

{- | Given bitset then valid bit index, return a new bitset with that bit set. Invalid index
fails.
-}
bitInsert :: BitSet -> Int -> Either MathError BitSet
bitInsert b@(BitSet w v) i = do bitIndex b i; pure (BitSet w (setBit v i))

{- | Given bitset then valid bit index, return a new bitset with that bit cleared. Invalid
index fails.
-}
bitDelete :: BitSet -> Int -> Either MathError BitSet
bitDelete b@(BitSet w v) i = do bitIndex b i; pure (BitSet w (clearBit v i))

bitCombine :: (Integer -> Integer -> Integer) -> BitSet -> BitSet -> Either MathError BitSet
bitCombine f (BitSet w a) (BitSet v b)
    | w /= v = Left (InvalidArgument "bit widths differ")
    | otherwise = Right (BitSet w (f a b .&. (2 ^ w - 1)))
bitUnion, bitIntersection, bitDifference :: BitSet -> BitSet -> Either MathError BitSet

{- | Return bitwise OR of equal-width bitsets. Different widths fail; no implicit resize
occurs.
-}
bitUnion = bitCombine (.|.)

-- | Return bitwise AND of equal-width bitsets; mismatched widths fail.
bitIntersection = bitCombine (.&.)

-- | Return left bits with right bits cleared, requiring equal widths. Width mismatch fails.
bitDifference = bitCombine (\a b -> a .&. complement b)

-- | Shrinking explicitly discards high bits.
resizeBitSet :: Int -> BitSet -> Either MathError BitSet
resizeBitSet w (BitSet _ v) = bitSet w (v .&. (2 ^ max 0 w - 1))

-- | Count set bits within declared width, returning Int.
populationCount :: BitSet -> Int
populationCount = popCount . bitValue

-- | Count high-end zero bits within declared width. All-zero bitset returns its full width.
leadingZeros :: BitSet -> Int
leadingZeros (BitSet w v) = w - go v
  where
    go 0 = 0; go x = 1 + go (shiftR x 1)

-- | Count low-end zero bits; an all-zero bitset returns its declared width.
trailingZeros :: BitSet -> Int
trailingZeros (BitSet w v) = if v == 0 then w else go v
  where
    go x | odd x = 0 | otherwise = 1 + go (shiftR x 1)

{- | Given signed rotation count then bitset, rotate left modulo width (negative counts
rotate right). Width-zero input is unchanged.
-}
rotateBits :: Int -> BitSet -> BitSet
rotateBits _ b@(BitSet 0 _) = b
rotateBits k (BitSet w v) = let j = k `mod` w in BitSet w ((shiftL v j .|. shiftR v (w - j)) .&. (2 ^ w - 1))

{- | Reverse exactly the declared width of bits, preserving width and leading/trailing zero
positions.
-}
reverseBits :: BitSet -> BitSet
reverseBits (BitSet w v) = BitSet w (sum [if testBit v i then bit (w - i - 1) else 0 | i <- [0 .. w - 1]])

-- | Return width-preserving reflected Gray code v xor (v shifted right one).
grayEncode :: BitSet -> BitSet
grayEncode (BitSet w v) = BitSet w (v `xor` shiftR v 1)

-- | Decode reflected Gray bits to the corresponding width-preserving binary value.
grayDecode :: BitSet -> BitSet
grayDecode (BitSet w v) = BitSet w (go v 0)
  where
    go 0 r = r; go x r = go (shiftR x 1) (r `xor` x)

{- | Count differing bit positions between equal-width bitsets. Different widths return Left
InvalidArgument.
-}
hammingDistance :: BitSet -> BitSet -> Either MathError Int
hammingDistance a b = populationCount <$> bitCombine xor a b

setUnion, setIntersection, setDifference, symmetricDifference :: (Ord a) => [a] -> [a] -> [a]

{- | Treat lists as finite sets and return their sorted unique union; input order and
multiplicity are discarded.
-}
setUnion a b = S.toAscList (S.union (S.fromList a) (S.fromList b))

-- | Return sorted unique values present in both input lists.
setIntersection a b = S.toAscList (S.intersection (S.fromList a) (S.fromList b))

-- | Return sorted unique left values absent from the right list.
setDifference a b = S.toAscList (S.difference (S.fromList a) (S.fromList b))

-- | Return sorted unique values present in exactly one input list.
symmetricDifference a b = setUnion (setDifference a b) (setDifference b a)

square :: [[a]] -> Either MathError Int
square a
    | length a > 512 || any ((/= length a) . length) a =
        Left (InvalidArgument "expected square matrix of order at most 512")
    | otherwise = Right (length a)

{- | Warshall closure. Paths must have positive length; use
'equivalenceClosure' when a reflexive closure is wanted.
-}
transitiveClosure :: [[Bool]] -> Either MathError [[Bool]]
transitiveClosure a = do
    n <- square a
    pure
        ( foldl
            (\m k -> [[m !! i !! j || (m !! i !! k && m !! k !! j) | j <- [0 .. n - 1]] | i <- [0 .. n - 1]])
            a
            [0 .. n - 1]
        )

{- | Given square Bool relation matrix, add reflexivity and symmetry then compute transitive
closure. Reject nonsquare or oversized (>512) relations.
-}
equivalenceClosure :: [[Bool]] -> Either MathError [[Bool]]
equivalenceClosure a = do
    n <- square a
    transitiveClosure [[i == j || a !! i !! j || a !! j !! i | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]

{- | Return whether a bounded square Bool relation is already reflexive, symmetric and
transitive. Invalid matrix shape/size fails.
-}
isEquivalence :: [[Bool]] -> Either MathError Bool
isEquivalence a = (== a) <$> equivalenceClosure a

{- | Multiply compatible square Bool relation matrices over OR/AND, representing relational
composition. Invalid dimensions or size bounds fail.
-}
booleanMultiply :: [[Bool]] -> [[Bool]] -> Either MathError [[Bool]]
booleanMultiply a b = do
    n <- square a
    m <- square b
    if n /= m
        then Left (InvalidArgument "Boolean matrix dimensions differ")
        else
            pure [[or [a !! i !! k && b !! k !! j | k <- [0 .. n - 1]] | j <- [0 .. n - 1]] | i <- [0 .. n - 1]]

{- | Boolean proposition tree. Literal and Variable leaves combine through
Not,And,Or,Xor,Implies,Iff; Variable indices address the assignment list passed to
evaluateProp.
-}
data Prop
    = Literal Bool
    | Variable Int
    | Not Prop
    | And Prop Prop
    | Or Prop Prop
    | Xor Prop Prop
    | Implies Prop Prop
    | Iff Prop Prop
    deriving (Eq, Show)

{- | Given variable Bool assignment list then proposition, evaluate
literals/variables/connectives. Invalid variable index or excessive expression depth
returns Left MathError.
-}
evaluateProp :: [Bool] -> Prop -> Either MathError Bool
evaluateProp values = go (0 :: Int)
  where
    go d _ | d > 1024 = Left (InvalidArgument "proposition nesting exceeds 1024")
    go _ (Literal b) = Right b
    go _ (Variable i)
        | i < 0 || i >= length values = Left (InvalidArgument "unbound proposition variable")
        | otherwise = Right (values !! i)
    go d (Not p) = not <$> go (d + 1) p
    go d (And p q) = binary d (&&) p q
    go d (Or p q) = binary d (||) p q
    go d (Xor p q) = binary d (/=) p q
    go d (Implies p q) = binary d (\a b -> not a || b) p q
    go d (Iff p q) = binary d (==) p q
    binary d f p q = f <$> go (d + 1) p <*> go (d + 1) q

-- | Assignments in binary order, variable zero the least-significant bit.
truthTable :: Int -> Prop -> Either MathError [([Bool], Bool)]
truthTable n p
    | n < 0 || n > 12 = Left (InvalidArgument "truth table input count exceeds 12")
    | otherwise =
        mapM
            (\i -> let a = [testBit i j | j <- [0 .. n - 1]] in (,) a <$> evaluateProp a p)
            [0 :: Int .. 2 ^ n - 1]

{- | Value bits and a don't-care mask. Both fields are bounded by the supplied
input width when returned by 'quineMcCluskey'.
-}
data Implicant = Implicant
    { implicantValue :: Integer
    -- ^ Fixed bit values of a Boolean implicant; positions masked by implicantMask are ignored.
    , implicantMask :: Integer
    -- ^ Bit mask whose set bits denote don't-care positions in an implicant.
    }
    deriving (Eq, Ord, Show)

{- | Given implicant then Integer minterm, compare bits where implicantMask is clear. True
means this Boolean cube covers the minterm.
-}
implicantCovers :: Implicant -> Integer -> Bool
implicantCovers (Implicant v m) x = (x .&. complement m) == v

{- | Exact Quine--McCluskey prime generation followed by branch-and-bound cover
selection. Objective is fewest terms, then literals, then lexical order.
The explicit budget counts prime comparisons and covering-search nodes.
-}
quineMcCluskey :: Int -> Int -> [Integer] -> [Integer] -> Either MathError [Implicant]
quineMcCluskey fuel n on dc
    | fuel < 0
        || n < 0
        || n > 12
        || any (\x -> x < 0 || x >= 2 ^ n) (on ++ dc)
        || not (null (setIntersection on dc)) =
        Left (InvalidArgument "invalid minimizer inputs")
    | otherwise = do
        (primes, remaining) <- generate fuel (map (`Implicant` 0) (sort (nub (on ++ dc)))) []
        let useful = filter (\p -> any (implicantCovers p) on) primes
        fst <$> cover remaining (sort (nub on)) [] useful Nothing
  where
    consume k | k <= 0 = Left (NonConvergence "Quine-McCluskey" fuel) | otherwise = Right (k - 1)
    combine (Implicant a m) (Implicant b q)
        | m == q && popCount (a `xor` b) == 1 = Just (Implicant (a .&. b) (m .|. (a `xor` b)))
        | otherwise = Nothing
    generate k [] acc = Right (sort (nub acc), k)
    generate k terms acc = do
        let pairs = [(a, b) | (i, a) <- zip [0 :: Int ..] terms, b <- drop (i + 1) terms]
        if length pairs > k
            then Left (NonConvergence "Quine-McCluskey primes" fuel)
            else do
                let merged = [(a, b, c) | (a, b) <- pairs, Just c <- [combine a b]]
                    used = S.fromList ([a | (a, _, _) <- merged] ++ [b | (_, b, _) <- merged])
                    old = filter (`S.notMember` used) terms
                generate (k - length pairs) (sort (nub [c | (_, _, c) <- merged])) (old ++ acc)
    score ps = (length ps, sum [n - popCount (implicantMask p) | p <- ps], sort ps)
    improve ps Nothing = Just (sort ps)
    improve ps (Just old) = Just (if score ps < score old then sort ps else old)
    cover k [] chosen _ best = do k' <- consume k; pure (maybe chosen id (improve chosen best), k')
    cover k todo chosen ps best = do
        k' <- consume k
        if maybe False (\old -> length chosen >= length old) best
            then pure (maybe [] id best, k')
            else
                let x = todo !! 0; options = filter (\p -> implicantCovers p x) ps
                 in if null options
                        then Left (InvalidArgument "uncoverable minterm")
                        else
                            foldl
                                ( \prev p -> do
                                    (current, f) <- prev
                                    cover
                                        f
                                        (filter (not . implicantCovers p) todo)
                                        (p : chosen)
                                        (filter (/= p) ps)
                                        (if null current then best else Just current)
                                )
                                (Right (maybe [] id best, k'))
                                options
