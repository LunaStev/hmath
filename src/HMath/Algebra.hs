{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeSynonymInstances #-}

-- SPDX-License-Identifier: MPL-2.0

{- | Algebraic interfaces, exact law checks, checked modular rings, and finite
extension fields GF(p^n). Runtime moduli are deliberately not Num instances:
combining different rings is an explicit error. Finite fields are constructed
only after primality and irreducibility have been proved under a budget.
-}
module HMath.Algebra (
    Semiring (..),
    Ring (..),
    Field (..),
    Group (..),
    Additive (..),
    Module (..),
    VectorSpace,
    linearCombination,
    semiringLaws,
    ringLaws,
    fieldLaws,
    groupLaws,
    moduleLaws,
    Modular,
    modular,
    modularValue,
    modularModulus,
    addModular,
    subtractModular,
    multiplyModular,
    inverseModular,
    powerModular,
    FiniteField,
    finiteField,
    primeField,
    fieldCharacteristic,
    fieldDegree,
    fieldCardinality,
    fieldModulus,
    FieldElement,
    fieldElement,
    fieldElementCoefficients,
    fieldElements,
    addField,
    negateField,
    subtractField,
    multiplyField,
    inverseFieldElement,
    powerField,
    finiteFieldLaws,
) where

import Control.Monad (foldM)
import Data.Ratio ((%))
import HMath.Error (MathError (..))
import HMath.NumberTheory (isPrimeExact, modInverse, modPow)
import HMath.Polynomial (Polynomial, addPolynomial, multiplyPolynomial, polynomial, scalePolynomial)

{- | Commutative addition, associative multiplication, distributivity, additive
identity and absorbing zero. Multiplication need not be commutative.
-}
class Semiring a where
    -- | Additive identity.
    zero :: a

    -- | Multiplicative identity.
    one :: a

    -- | Semiring addition.
    plus :: a -> a -> a

    -- | Semiring multiplication.
    times :: a -> a -> a

-- | A semiring whose additive monoid is an abelian group.
class (Semiring a) => Ring a where
    -- | Additive inverse.
    negateRing :: a -> a

-- | A commutative ring in which each nonzero element has an inverse.
class (Ring a) => Field a where
    -- | Multiplicative inverse; zero returns a domain error.
    inverseField :: a -> Either MathError a

-- | An associative operation with identity and inverse.
class Group a where
    -- | Group identity.
    groupIdentity :: a

    -- | Group operation, not necessarily commutative.
    groupCombine :: a -> a -> a

    -- | Two-sided inverse.
    groupInverse :: a -> a

-- | A ring viewed as its additive group.
newtype Additive a = Additive
    { getAdditive :: a
    -- ^ Recover the underlying ring element.
    }
    deriving (Eq, Show)

instance (Ring a) => Group (Additive a) where
    groupIdentity = Additive zero
    groupCombine (Additive a) (Additive b) = Additive (plus a b)
    groupInverse (Additive a) = Additive (negateRing a)

instance Semiring Integer where
    zero = 0
    one = 1
    plus = (+)
    times = (*)
instance Ring Integer where negateRing = negate
instance Semiring Rational where
    zero = 0 % 1
    one = 1 % 1
    plus = (+)
    times = (*)
instance Ring Rational where negateRing = negate
instance Field Rational where
    inverseField 0 = Left (DomainError "zero has no field inverse")
    inverseField x = Right (recip x)
instance (Eq a, Num a) => Semiring (Polynomial a) where
    zero = polynomial []
    one = polynomial [1]
    plus = addPolynomial
    times = multiplyPolynomial
instance (Eq a, Num a) => Ring (Polynomial a) where negateRing = scalePolynomial (-1)

-- | A left module with checked addition for runtime vector shapes.
class (Ring scalar) => Module scalar vector | vector -> scalar where
    -- | Scalar action.
    moduleScale :: scalar -> vector -> vector

    -- | Addition, rejecting incompatible runtime shapes.
    moduleAdd :: vector -> vector -> Either MathError vector

instance Module Integer [Integer] where
    moduleScale a = map (a *)
    moduleAdd = addVectors
instance Module Rational [Rational] where
    moduleScale a = map (a *)
    moduleAdd = addVectors

{- | A module over a field. Rational finite-list vectors are an exact instance;
list lengths define separate spaces, and moduleAdd rejects differing lengths.
-}
class (Field scalar, Module scalar vector) => VectorSpace scalar vector

instance VectorSpace Rational [Rational]

addVectors :: (Num a) => [a] -> [a] -> Either MathError [a]
addVectors a b
    | length a /= length b = Left (VectorLengthMismatch (length a) (length b))
    | otherwise = Right (zipWith (+) a b)

{- | Checked linear combination. Supply the zero vector explicitly so the empty
combination retains its dimension.
-}
linearCombination :: (Module s v) => v -> [(s, v)] -> Either MathError v
linearCombination = foldM (\acc (a, v) -> moduleAdd acc (moduleScale a v))

{- | Exhaustive semiring identities on the supplied finite sample. This is a
test utility, not a proof for types with an infinite carrier.
-}
semiringLaws :: (Eq a, Semiring a) => [a] -> [(String, Bool)]
semiringLaws xs =
    [ ("addition identity", all (\a -> plus zero a == a && plus a zero == a) xs)
    , ("multiplication identity", all (\a -> times one a == a && times a one == a) xs)
    , ("absorbing zero", all (\a -> times zero a == zero && times a zero == zero) xs)
    , ("addition commutativity", and [plus a b == plus b a | a <- xs, b <- xs])
    , ("addition associativity", and [plus (plus a b) c == plus a (plus b c) | a <- xs, b <- xs, c <- xs])
    ,
        ( "multiplication associativity"
        , and [times (times a b) c == times a (times b c) | a <- xs, b <- xs, c <- xs]
        )
    ,
        ( "left distributivity"
        , and [times a (plus b c) == plus (times a b) (times a c) | a <- xs, b <- xs, c <- xs]
        )
    ,
        ( "right distributivity"
        , and [times (plus a b) c == plus (times a c) (times b c) | a <- xs, b <- xs, c <- xs]
        )
    ]

-- | Semiring laws plus additive inverses on a finite sample.
ringLaws :: (Eq a, Ring a) => [a] -> [(String, Bool)]
ringLaws xs = semiringLaws xs ++ [("additive inverses", all (\a -> plus a (negateRing a) == zero) xs)]

-- | Ring laws, commutative multiplication and nonzero inverses.
fieldLaws :: (Eq a, Field a) => [a] -> [(String, Bool)]
fieldLaws xs =
    ringLaws xs
        ++ [ ("multiplication commutativity", and [times a b == times b a | a <- xs, b <- xs])
           ,
               ( "nonzero inverses"
               , all
                    ( \a ->
                        a == zero || case inverseField a of
                            Left _ -> False
                            Right b -> times a b == one
                    )
                    xs
               )
           ]

-- | Group identities on a finite sample.
groupLaws :: (Eq a, Group a) => [a] -> [(String, Bool)]
groupLaws xs =
    [
        ( "group identity"
        , all (\a -> groupCombine groupIdentity a == a && groupCombine a groupIdentity == a) xs
        )
    ,
        ( "group inverses"
        , all
            ( \a ->
                groupCombine a (groupInverse a) == groupIdentity
                    && groupCombine (groupInverse a) a == groupIdentity
            )
            xs
        )
    ,
        ( "group associativity"
        , and
            [groupCombine (groupCombine a b) c == groupCombine a (groupCombine b c) | a <- xs, b <- xs, c <- xs]
        )
    ]

{- | Check module scalar identity, composition, and both distributive laws.
Vectors in the sample must belong to the same runtime space.
-}
moduleLaws :: (Eq v, Module s v) => [s] -> [v] -> [(String, Bool)]
moduleLaws scalars vectors =
    [ ("module identity", all (\v -> moduleScale one v == v) vectors)
    ,
        ( "module composition"
        , and
            [ moduleScale (times a b) v == moduleScale a (moduleScale b v)
            | a <- scalars
            , b <- scalars
            , v <- vectors
            ]
        )
    ,
        ( "scalar distributivity"
        , and
            [ moduleAdd (moduleScale a v) (moduleScale b v) == Right (moduleScale (plus a b) v)
            | a <- scalars
            , b <- scalars
            , v <- vectors
            ]
        )
    ,
        ( "vector distributivity"
        , and
            [ fmap (moduleScale a) (moduleAdd u v)
                == moduleAdd (moduleScale a u) (moduleScale a v)
            | a <- scalars
            , u <- vectors
            , v <- vectors
            ]
        )
    ]

-- | A canonical residue in Z/mZ, retaining its runtime modulus.
data Modular = Modular Integer Integer deriving (Eq, Show)

-- | Construct a residue, requiring m>1; arbitrary signed values are reduced.
modular :: Integer -> Integer -> Either MathError Modular
modular modulus value
    | modulus <= 1 = Left (DomainError "modular modulus must exceed one")
    | otherwise = Right (Modular modulus (value `mod` modulus))

-- | Canonical value in [0,m).
modularValue :: Modular -> Integer
modularValue (Modular _ a) = a

-- | Modulus greater than one.
modularModulus :: Modular -> Integer
modularModulus (Modular m _) = m

binaryModular :: (Integer -> Integer -> Integer) -> Modular -> Modular -> Either MathError Modular
binaryModular f (Modular m a) (Modular n b)
    | m /= n = Left (DomainError "different modular rings")
    | otherwise = modular m (f a b)

-- | Checked residue addition.
addModular :: Modular -> Modular -> Either MathError Modular
addModular = binaryModular (+)

-- | Checked residue subtraction.
subtractModular :: Modular -> Modular -> Either MathError Modular
subtractModular = binaryModular (-)

-- | Checked residue multiplication.
multiplyModular :: Modular -> Modular -> Either MathError Modular
multiplyModular = binaryModular (*)

-- | Invert a unit; zero and nonunits are domain errors.
inverseModular :: Modular -> Either MathError Modular
inverseModular (Modular m a) = modInverse a m >>= modular m

-- | Integer power, with negative powers supported for units.
powerModular :: Modular -> Integer -> Either MathError Modular
powerModular (Modular m a) e = modPow a e m >>= modular m

{- | An irreducible monic modulus over the proven prime field F_p.
Coefficients are ascending canonical residues.
-}
data FiniteField = FiniteField Integer [Integer] deriving (Eq, Show)

{- | Construct GF(p^n) from an irreducible polynomial of positive degree.
Primality is proven by trial division. Irreducibility uses successive
Frobenius powers and polynomial gcds; n must not exceed the proof budget.
-}
finiteField :: Int -> Integer -> [Integer] -> Either MathError FiniteField
finiteField budget p cs = do
    prime <- isPrimeExact budget p
    if not prime
        then Left (DomainError "field characteristic must be prime")
        else do
            let reduced = trim (map (`mod` p) cs)
                degree = length reduced - 1
            if degree < 1
                then Left (DomainError "field modulus needs positive degree")
                else
                    if degree > budget
                        then Left (NonConvergence "finite-field irreducibility" budget)
                        else do
                            inv <- modInverse (leading reduced) p
                            let f = map (\a -> a * inv `mod` p) reduced
                                x = polyRemainder p [0, 1] f
                                powers = take (degree + 1) (iterate (\a -> polyPow p a p f) x)
                                proper =
                                    and
                                        [ length (polyGCD p (polySub p h x) f) == 1
                                        | h <- take (degree `div` 2) (drop 1 powers)
                                        ]
                                final = concat (take 1 (drop degree powers))
                            if proper && final == x
                                then Right (FiniteField p f)
                                else Left (DomainError "reducible finite-field modulus")

-- | Prime field GF(p), represented as F_p[x]/(x).
primeField :: Int -> Integer -> Either MathError FiniteField
primeField budget p = finiteField budget p [0, 1]

-- | Prime characteristic p.
fieldCharacteristic :: FiniteField -> Integer
fieldCharacteristic (FiniteField p _) = p

-- | Extension degree n.
fieldDegree :: FiniteField -> Int
fieldDegree (FiniteField _ f) = length f - 1

-- | Exact carrier size p^n.
fieldCardinality :: FiniteField -> Integer
fieldCardinality f = fieldCharacteristic f ^ fieldDegree f

-- | Ascending coefficients of the monic irreducible defining polynomial.
fieldModulus :: FiniteField -> [Integer]
fieldModulus (FiniteField _ f) = f

-- | A canonical residue polynomial of degree smaller than its field degree.
data FieldElement = FieldElement FiniteField [Integer] deriving (Eq, Show)

-- | Reduce an arbitrary integer polynomial into a finite field.
fieldElement :: FiniteField -> [Integer] -> FieldElement
fieldElement f@(FiniteField p modulus) xs = FieldElement f (polyRemainder p (trim (map (`mod` p) xs)) modulus)

-- | Canonical ascending residue coefficients (trailing zeros removed).
fieldElementCoefficients :: FieldElement -> [Integer]
fieldElementCoefficients (FieldElement _ xs) = xs

{- | Enumerate the complete carrier, rejecting sizes above an explicit storage
budget. Enumeration is coefficient-lexicographic and deterministic.
-}
fieldElements :: Int -> FiniteField -> Either MathError [FieldElement]
fieldElements budget f
    | budget < 0 = Left (InvalidArgument "negative finite-field enumeration budget")
    | fieldCardinality f > toInteger budget = Left (NonConvergence "finite-field enumeration" budget)
    | otherwise =
        Right
            [fieldElement f xs | xs <- sequence (replicate (fieldDegree f) [0 .. fieldCharacteristic f - 1])]

binaryField ::
    (Integer -> [Integer] -> [Integer] -> [Integer]) ->
    FieldElement ->
    FieldElement ->
    Either MathError FieldElement
binaryField op (FieldElement f a) (FieldElement g b)
    | f /= g = Left (DomainError "different finite fields")
    | otherwise = Right (fieldElement f (op (fieldCharacteristic f) a b))

-- | Addition; different defining fields are rejected even if isomorphic.
addField :: FieldElement -> FieldElement -> Either MathError FieldElement
addField = binaryField polyAdd

-- | Additive inverse in the same field.
negateField :: FieldElement -> FieldElement
negateField (FieldElement f xs) = fieldElement f (map negate xs)

-- | Checked field subtraction.
subtractField :: FieldElement -> FieldElement -> Either MathError FieldElement
subtractField a b = addField a (negateField b)

-- | Checked field multiplication, reduced modulo the defining polynomial.
multiplyField :: FieldElement -> FieldElement -> Either MathError FieldElement
multiplyField = binaryField polyMul

-- | Nonzero inverse via the finite-field identity a^(q-2).
inverseFieldElement :: FieldElement -> Either MathError FieldElement
inverseFieldElement (FieldElement _ []) = Left (DomainError "zero finite-field inverse")
inverseFieldElement a@(FieldElement f _) = powerField a (fieldCardinality f - 2)

-- | Binary exponentiation, with inverses for negative exponents.
powerField :: FieldElement -> Integer -> Either MathError FieldElement
powerField a@(FieldElement f xs) k
    | k < 0 = do inv <- inverseFieldElement a; powerField inv (-k)
    | otherwise = case f of
        FiniteField p modulus -> Right (fieldElement f (polyPow p xs k modulus))

{- | Exhaustive carrier checks for small fields, including distributivity,
associativity, identities and every nonzero inverse. Budget bounds enumeration;
the cubic law checks are intended for small validation fields.
-}
finiteFieldLaws :: Int -> FiniteField -> Either MathError [(String, Bool)]
finiteFieldLaws budget f = do
    xs <- fieldElements budget f
    let z = fieldElement f []
        o = fieldElement f [1]
        plusF a b = addField a b
        mulF a b = multiplyField a b
    pure
        [ ("field additive identity", all (\a -> plusF a z == Right a) xs)
        , ("field multiplicative identity", all (\a -> mulF a o == Right a) xs)
        , ("field additive inverses", all (\a -> plusF a (negateField a) == Right z) xs)
        ,
            ( "field multiplicative inverses"
            , all (\a -> a == z || (inverseFieldElement a >>= mulF a) == Right o) xs
            )
        ,
            ( "field additive associativity"
            , and [(plusF a b >>= (`plusF` c)) == (plusF b c >>= plusF a) | a <- xs, b <- xs, c <- xs]
            )
        ,
            ( "field multiplicative associativity"
            , and [(mulF a b >>= (`mulF` c)) == (mulF b c >>= mulF a) | a <- xs, b <- xs, c <- xs]
            )
        ,
            ( "field distributivity"
            , and
                [ (plusF b c >>= mulF a) == (do ab <- mulF a b; ac <- mulF a c; plusF ab ac)
                | a <- xs
                , b <- xs
                , c <- xs
                ]
            )
        ]

trim :: [Integer] -> [Integer]
trim = reverse . dropWhile (== 0) . reverse

leading :: [Integer] -> Integer
leading = foldl (\_ x -> x) 0

polyAdd :: Integer -> [Integer] -> [Integer] -> [Integer]
polyAdd p a b = trim (map (`mod` p) (add a b))
  where
    add [] ys = ys; add xs [] = xs; add (x : xs) (y : ys) = x + y : add xs ys

polySub :: Integer -> [Integer] -> [Integer] -> [Integer]
polySub p a b = polyAdd p a (map negate b)

polyMul :: Integer -> [Integer] -> [Integer] -> [Integer]
polyMul p a b = foldl (polyAdd p) [] [replicate i 0 ++ map (x *) b | (i, x) <- zip [0 ..] a]

polyRemainder :: Integer -> [Integer] -> [Integer] -> [Integer]
polyRemainder p a b
    | null b = []
    | length a < length b = trim (map (`mod` p) a)
    | otherwise =
        let inv = either (const 0) id (modInverse (leading b) p)
            factor = leading a * inv `mod` p
            result = polySub p a (replicate (length a - length b) 0 ++ map (factor *) b)
         in polyRemainder p result b

polyGCD :: Integer -> [Integer] -> [Integer] -> [Integer]
polyGCD p a [] =
    let inv = either (const 0) id (modInverse (leading a) p)
     in map (\x -> x * inv `mod` p) a
polyGCD p a b = polyGCD p b (polyRemainder p a b)

polyPow :: Integer -> [Integer] -> Integer -> [Integer] -> [Integer]
polyPow p a e modulus = go (polyRemainder p a modulus) e [1]
  where
    go _ 0 r = polyRemainder p r modulus
    go x k r =
        go
            (polyRemainder p (polyMul p x x) modulus)
            (k `div` 2)
            (if odd k then polyRemainder p (polyMul p r x) modulus else r)
