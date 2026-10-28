-- SPDX-License-Identifier: MPL-2.0
module AlgebraBatchSpec (algebraBatchTests) where

import Data.Complex (Complex,magnitude)
import Data.Either (isLeft)
import Data.Ratio ((%))
import qualified HMath.Algebra as A
import HMath.Error (MathError(..))
import qualified HMath.Matrix as M
import HMath.NumberTheory
import HMath.Polynomial

algebraBatchTests :: [(String,Bool)]
algebraBatchTests=numberTests++polynomialTests++algebraTests

numberTests :: [(String,Bool)]
numberTests=
    [("integer gcd/lcm signs and zeros",gcdInteger (-24) 18==6 && lcmInteger (-24) 18==72 && gcdInteger 0 0==0 && lcmInteger 0 9==0)
    ,("Bezout exhaustive signed identity",and [let (g,x,y)=extendedGCD a b in g==gcd a b && a*x+b*y==g && bezout a b==(x,y)|a<-[-20..20],b<-[-20..20]])
    ,("modular exponentiation negative exponent",modPow 3 (-2) 11==Right 5 && modPow 5 0 1==Right 0)
    ,("modular exponentiation domains",isLeft (modPow 2 (-1) 4) && isLeft (modPow 2 3 0) && isLeft (modInverse 3 1))
    ,("modular inverse identities",and [fmap (\x->a*x `mod` m) (modInverse a m)==Right 1|m<-[2..30],a<-[1..m-1],gcd a m==1])
    ,("generalized noncoprime CRT",chineseRemainder [(2,6),(8,9)]==Right (8,18) && chineseRemainder []==Right (0,1))
    ,("CRT rejects inconsistent and invalid moduli",isLeft (chineseRemainder [(1,2),(0,4)]) && isLeft (chineseRemainder [(0,0)]))
    ,("Diophantine solution family",case linearDiophantine (-12) 18 30 of Right (x,y,dx,dy)->and [-12*(x+k*dx)+18*(y+k*dy)==30|k<-[-5..5]]; _->False)
    ,("Diophantine failures",isLeft (linearDiophantine 2 4 3) && isLeft (linearDiophantine 0 0 0))
    ,("integer square root exact large boundaries",and [integerSquareRoot (r*r)==Right r && integerSquareRoot (r*r+2*r)==Right r|r<-[0,1,2,10^(20::Int),10^(100::Int)]])
    ,("integer square root negative rejected",isLeft (integerSquareRoot (-1)))
    ,("perfect powers signed and trivial",perfectPower (-125)==Just (-5,3) && perfectPower 81==Just (9,2) && perfectPower 17==Nothing && perfectPower 0==Just (0,2))
    ,("proven prime search and budget",nextPrime 1000 100==Right 101 && isPrimeExact 0 101==Left (NonConvergence "trial primality" 0) && isPrimeExact 0 2==Right True)
    ,("Miller-Rabin pseudoprime distinguished",millerRabin [2] 2047==Right True && millerRabin [2,3] 2047==Right False && isLeft (millerRabin [] 17))
    ,("Baillie-PSW agrees with proof over 0..5000",and [bailliePSW n==isPrimeExact 1000 n|n<-[0..5000]])
    ,("Baillie-PSW known strong pseudoprimes",all ((==Right False).bailliePSW) [2047,1373653,25326001,3215031751,3825123056546413051])
    ,("Baillie-PSW large prime and square",bailliePSW (2^(61::Int)-1)==Right True && bailliePSW ((2^(61::Int)-1)^(2::Int))==Right False)
    ,("independent sieves agree",all (\n->sieveAtkin n==sieveEratosthenes n) [0,1,2,3,4,5,20,100,1000])
    ,("segmented prime sieve",segmentedSieve 990 1100==Right (filter (>=990) (sieveEratosthenes 1100)) && segmentedSieve (-10) 10==Right [2,3,5,7])
    ,("segmented reversed bounds",isLeft (segmentedSieve 10 1))
    ,("factorization exact product and multiplicities",primeFactorization 1000 7560==Right [(2,3),(3,3),(5,1),(7,1)] && primeFactorization 0 1==Right [])
    ,("factorization domain and budget",isLeft (primeFactorization 10 0) && isLeft (primeFactorization 0 91))
    ,("Pollard rho proper factor",properFactor 8051 (pollardRho 1000 2 8051))
    ,("Pollard p-1 smooth factor",properFactor 299 (pollardPMinusOne 4 2 299))
    ,("Fermat close factors",properFactor 5959 (fermatFactor 100 5959))
    ,("factor searches bounded failure",isLeft (pollardRho 0 2 91) && isLeft (fermatFactor 0 91) && isLeft (pollardPMinusOne 2 2 101))
    ,("divisors sums and counts",divisors 100 12==Right [1,2,3,4,6,12] && divisorCount 100 12==Right 6 && divisorSum 100 12==Right 28)
    ,("multiplicative arithmetic functions",eulerTotient 100 36==Right 12 && carmichael 100 8==Right 2 && mobius 100 30==Right (-1) && mobius 100 12==Right 0 && liouville 100 12==Right (-1))
    ,("arithmetic functions at one",eulerTotient 0 1==Right 1 && carmichael 0 1==Right 1 && mobius 0 1==Right 1 && liouville 0 1==Right 1)
    ,("primitive root and multiplicative order",primitiveRoot 100 17==Right 3 && multiplicativeOrder 100 3 17==Right 16 && isLeft (primitiveRoot 100 8))
    ,("discrete logarithm and missing subgroup",discreteLog 100 2 8 13==Right 3 && isLeft (discreteLog 100 2 3 7) && isLeft (discreteLog 1 2 8 13))
    ,("Legendre/Jacobi/Kronecker signs",legendreSymbol 100 2 7==Right 1 && jacobiSymbol 1001 9907==Right (-1) && kroneckerSymbol 3 2== -1 && kroneckerSymbol (-1) (-1)== -1)
    ,("symbol domain checks",isLeft (jacobiSymbol 1 2) && isLeft (legendreSymbol 100 2 9) && kroneckerSymbol 1 0==1 && kroneckerSymbol 2 0==0)
    ,("Tonelli-Shanks all small prime residues",and [case tonelliShanks 100 a p of Right r->r*r `mod` p==a && r<=p-r; Left _->a/=0 && powInteger a ((p-1) `div` 2) p/=1|p<-filter (>2) (sieveEratosthenes 100),a<-[0..p-1]])
    ,("Tonelli-Shanks domains and modulus two",tonelliShanks 0 3 2==Right 1 && isLeft (tonelliShanks 100 2 9) && isLeft (tonelliShanks 100 2 11))
    ,("continued-fraction signed round trip",and [fromContinuedFraction (continuedFraction r)==Right r|r<-[17%12,-17%12,0,355%113]])
    ,("continued-fraction convergents",convergents [1,2,2]==Right [1,3%2,7%5] && isLeft (fromContinuedFraction [1,0]))
    ,("Farey sequence exact order",farey 5==Right [0,1%5,1%4,1%3,2%5,1%2,3%5,2%3,3%4,4%5,1] && isLeft (farey 0))
    ,("Pell fundamental solutions",pellFundamental 100 2==Right (3,2) && pellFundamental 100 61==Right (1766319049,226153980) && isLeft (pellFundamental 1 61) && isLeft (pellFundamental 100 4))
    ,("perfect and amicable numbers",isPerfectNumber 1000 28==Right True && areAmicable 1000 220 284==Right True && areAmicable 100 6 6==Right False)
    ,("integer partitions and counts",partitions 4==Right [[4],[3,1],[2,2],[2,1,1],[1,1,1,1]] && partitionCount 20==Right 627 && partitionCount 0==Right 1)
    ,("partition domains",isLeft (partitions (-1)) && isLeft (partitionCount (-1)))
    ,("fast-doubling Fibonacci signed and huge",fibonacciFast (-10)== -55 && fibonacciFast 100==354224848179261915075 && fibonacciFast 1000>10^(200::Int))
    ,("fast-doubling addition identity",and [fibonacciFast (n+1)*fibonacciFast (n-1)-fibonacciFast n^ (2::Int)==if even n then 1 else -1|n<-[1..100]])]
  where properFactor n result=case result of Right d->d>1 && d<n && n `mod` d==0; _->False
        powInteger a e p=either (const (-1)) id (modPow a e p)

polynomialTests :: [(String,Bool)]
polynomialTests=
    [("polynomial ascending order normalization",coefficients (poly [1,2,0,0])==[1,2] && polynomialDegree (poly [0,0])==Nothing && evaluatePolynomial (poly [1,2,3]) 2==17)
    ,("polynomial arithmetic exact convolution",multiplyPolynomial (poly [1,2]) (poly [3,4])==poly [3,10,8] && composePolynomial (poly [1,0,1]) (poly [1,1])==poly [2,2,1])
    ,("polynomial division exact reconstruction",and [case dividePolynomial a b of Right (q,r)->addPolynomial (multiplyPolynomial q b) r==a && maybe True (<maybe 0 id (polynomialDegree b)) (polynomialDegree r); _->False|a<-samples,b<-filter ((/=Nothing).polynomialDegree) samples])
    ,("polynomial zero division rejected",isLeft (dividePolynomial (poly [1]) (poly [])))
    ,("polynomial Euclidean GCD",gcdPolynomial (poly [-1,0,1]) (poly [-1,1])==poly [-1,1] && gcdPolynomial (poly []) (poly [])==poly [])
    ,("polynomial calculus inverse identities",and [differentiatePolynomial (integratePolynomial 7 p)==p && integratePolynomial (evaluatePolynomial p 0) (differentiatePolynomial p)==p|p<-samples])
    ,("square-free factor multiplicities",squareFreeFactors repeated==[(poly [2,1],1),(poly [-1,1],2)])
    ,("rational roots multiplicities and zero",rationalRoots 1000 repeated==Right [(-2,1),(1,2)] && rationalRoots 1000 (poly [0,0,-2,1])==Right [(0,2),(2,1)])
    ,("rational-root degenerate domain",isLeft (rationalRoots 100 (poly [])) && rationalRoots 100 (poly [4])==Right [])
    ,("complete rational quartic factorization",factorRationalPolynomial 10000 (poly [4,0,5,0,1])==Right (1,[(poly [1,0,1],1),(poly [4,0,1],1)]))
    ,("rational factorization repeated reconstruction",case factorRationalPolynomial 10000 (scalePolynomial 3 repeated) of Right (c,fs)->scalePolynomial c (foldl multiplyPolynomial (poly [1]) [factorPower f k|(f,k)<-fs])==scalePolynomial 3 repeated; _->False)
    ,("rational factorization budget and zero failure",isLeft (factorRationalPolynomial 0 (poly [1,0,1])) && isLeft (factorRationalPolynomial 100 (poly [])))
    ,("Sturm count ignores multiplicity",countRealRoots repeated (-3) 3==Right 2 && countRealRoots repeated (-3) 0==Right 1)
    ,("Sturm endpoints and bounds rejected",isLeft (countRealRoots repeated 1 3) && isLeft (countRealRoots repeated 3 (-3)))
    ,("Sturm exact root isolation and widths",case isolateRealRoots 1000 (1%10000) repeated of Right intervals->length intervals==2 && all (\(a,b)->b-a<=1%10000) intervals && all (\r->any (\(a,b)->a<r && r<=b) intervals) [-2,1]; _->False)
    ,("Sturm midpoint-root count",case isolateRealRoots 1000 (1%1000) (poly [0,-1,0,1]) of Right intervals->length intervals==3; _->False)
    ,("Sturm repeated midpoint root square-free normalization",case isolateRealRoots 200 (1%1000) (poly [0,0,-1,1]) of Right intervals->length intervals==2 && all (\r->any (\(a,b)->a<r && r<=b) intervals) [0,1]; _->False)
    ,("Sturm failure budgets",isLeft (isolateRealRoots 0 (1%100) repeated) && isLeft (isolateRealRoots 100 0 repeated))
    ,("Durand-Kerner complex residuals",checkRoots (durandKerner 500 1e-12 complexPoly) complexPoly)
    ,("Aberth-Ehrlich complex residuals",checkRoots (aberthEhrlich 100 1e-12 complexPoly) complexPoly)
    ,("root methods repeated-root residuals",checkRoots (aberthEhrlich 500 1e-12 (polynomial [-1,3,-3,1])) (polynomial [-1,3,-3,1]))
    ,("root methods budget/nonfinite/domain",isLeft (durandKerner 0 1e-12 complexPoly) && isLeft (aberthEhrlich 100 0 complexPoly) && isLeft (aberthEhrlich 100 1e-12 (polynomial [0/0,1])) && isLeft (durandKerner 100 1e-12 (polynomial [])))
    ,("companion matrix coefficients",fmap M.toList (companionMatrix (poly [2,3,1]))==Right [0,-2,1,-3] && isLeft (companionMatrix (poly [1])))
    ,("Lagrange interpolation exact identity",lagrangeInterpolation points==Right (poly [1,2,1]))
    ,("Newton interpolation exact identity",newtonInterpolation points==Right (poly [1,2,1]) && newtonInterpolation []==Right (poly []))
    ,("interpolation duplicate nodes rejected",isLeft (lagrangeInterpolation [(1,1),(1,2::Rational)]) && isLeft (newtonInterpolation [(1,1),(1,2::Rational)]))
    ,("Chebyshev exact recurrence",chebyshevPolynomial 4==Right (poly [1,0,-8,0,8]))
    ,("Legendre exact normalization",legendrePolynomial 3==Right (poly [0,-3%2,0,5%2]))
    ,("Hermite physicists normalization",hermitePolynomial 3==Right (poly [0,-12,0,8]))
    ,("Laguerre exact normalization",laguerrePolynomial 3==Right (poly [1,-3,3%2,-1%6]))
    ,("Bernstein partition of unity",fmap (foldl addPolynomial (poly [])) (mapM (bernsteinPolynomial 5) [0..5])==Right (poly [1]) && isLeft (bernsteinPolynomial 2 3::Either MathError (Polynomial Rational)))
    ,("orthogonal degree domains",isLeft (legendrePolynomial (-1)::Either MathError (Polynomial Rational)))
    ,("QR polynomial regression exact data",case polynomialRegression 2 [(x,1+2*x+3*x*x)|x<-[-2,-1,0,1,2::Double]] of Right p->nearList (coefficients p) [1,2,3]; _->False)
    ,("QR regression invalid and rank deficient",isLeft (polynomialRegression (-1) [(0,1::Double)]) && isLeft (polynomialRegression 2 [(0,1),(0,2),(0,3::Double)]))
    ,("Chebyshev approximation cubic",case chebyshevApproximation 3 (\x->1+x^ (3::Int)) of Right p->all (\x->near (evaluatePolynomial p x) (1+x^ (3::Int))) [-1,-0.3,0,0.2,1]; _->False)
    ,("approximation nonfinite callback",isLeft (chebyshevApproximation 4 (const (0/0))))
    ,("formal reciprocal exact coefficients",fmap seriesCoefficients (reciprocalSeries (powerSeries [1,-1,0,0,0::Rational]))==Right [1,1,1,1,1])
    ,("formal reciprocal multiplication identity",case reciprocalSeries jet of Right inv->seriesCoefficients (multiplySeries jet inv)==[1,0,0,0,0]; _->False)
    ,("formal division and composition",divideSeries jet jet==Right (powerSeries [1,0,0,0,0]) && fmap seriesCoefficients (composeSeries (powerSeries [1,2,3::Rational]) (powerSeries [0,1,1]))==Right [1,2,5])
    ,("formal series domains and calculus",isLeft (reciprocalSeries (powerSeries [0,1::Rational])) && isLeft (composeSeries jet (powerSeries [1,1::Rational])) && differentiateSeries (integrateSeries 3 jet)==jet)
    ,("formal exponential and logarithm coefficients",nearList (seriesCoefficients (expSeries (powerSeries [0,1,0,0,0::Double]))) [1,1,0.5,1/6,1/24] && case logSeries (powerSeries [1,1,0,0,0::Double]) of Right s->nearList (seriesCoefficients s) [0,1,-0.5,1/3,-0.25]; _->False)
    ,("formal exp/log roundtrip",case logSeries (expSeries (powerSeries [0.2,1,-2,0.5,0::Double])) of Right s->nearList (seriesCoefficients s) [0.2,1,-2,0.5,0]; _->False)
    ,("rational function canonical cancellation",case rationalFunction (poly [-1,0,1]) (poly [-1,1]) of Right r->rationalNumerator r==poly [1,1] && rationalDenominator r==poly [1]; _->False)
    ,("rational function poles and zero denominator",isLeft (rationalFunction (poly [1]) (poly [])) && isLeft (rationalFunction (poly [1]) (poly [0,1]) >>= (`evaluateRationalFunction` 0)))
    ,("rational function arithmetic",case (do a<-rationalFunction (poly [1]) (poly [0,1]); b<-addRationalFunction a a; multiplyRationalFunction a b >>= (`evaluateRationalFunction` 2)) of Right x->x==1%2; _->False)
    ,("partial fractions repeated nonlinear reconstruction",partialFractionIdentity)]
  where
    partialFractionIdentity=case rationalFunction numeratorPoly denominatorPoly >>= partialFractions 100000 of
        Right (whole,terms)->all (\x->evaluatePolynomial numeratorPoly x/evaluatePolynomial denominatorPoly x==
            evaluatePolynomial whole x+sum [evaluatePolynomial a x/evaluatePolynomial b x^k|(a,b,k)<-terms]) [-3,-1,0,2,4]
        _->False
    numeratorPoly=poly [1,2,3,4,5,6]
    denominatorPoly=multiplyPolynomial (factorPower (poly [-1,1]) 2) (poly [1,0,1])
    poly=polynomial :: [Rational]->Polynomial Rational
    samples=map poly [[],[1],[1,2],[-1,0,1],[2,-3,4,-2],[0,0,1]]
    repeated=poly [2,-3,0,1]
    complexPoly=polynomial [-1,0,0,0,1::Complex Double]
    points=[(x,1+2*x+x*x)|x<-[-2,0,1,3::Rational]]
    jet=powerSeries [2,3,-1,4,0::Rational]
    factorPower p k=foldl multiplyPolynomial (poly [1]) (replicate k p)
    checkRoots result p=case result of Right roots->length roots==maybe 0 id (polynomialDegree p) && all (\z->magnitude (evaluatePolynomial p z)<1e-8) roots; _->False

algebraTests :: [(String,Bool)]
algebraTests=
    [("Integer semiring/ring laws",all snd (A.ringLaws [-3..3::Integer]))
    ,("Rational field laws",all snd (A.fieldLaws [-2,-1%3,0,1%2,3::Rational]))
    ,("Polynomial ring laws",all snd (A.ringLaws (map polynomial [[],[1],[1,2],[-1,0,1::Rational]])))
    ,("Additive group laws",all snd (A.groupLaws (map A.Additive [-3..3::Integer])))
    ,("Rational vector-space module laws",all snd (A.moduleLaws [-2,0,1%2,3] [[0,0],[1,2],[-1,3::Rational]]))
    ,("module checked linear combination",A.linearCombination [0,0::Rational] [(2,[1,2]),(-1,[3,4])]==Right [-1,0] && isLeft (A.moduleAdd [1::Rational] [1,2]))
    ,("modular canonical signs and arithmetic",case (do a<-A.modular 7 (-3); b<-A.modular 7 6; c<-A.addModular a b; d<-A.multiplyModular a b; pure (A.modularValue c,A.modularValue d)) of Right result->result==(3,3); _->False)
    ,("modular inverse and negative powers",case (do a<-A.modular 11 3; inv<-A.inverseModular a; square<-A.powerModular a (-2); pure (A.modularValue inv,A.modularValue square)) of Right values->values==(4,5); _->False)
    ,("modular mismatch/nonunit rejected",isLeft (do a<-A.modular 4 2; A.inverseModular a) && isLeft (do a<-A.modular 7 1; b<-A.modular 11 1; A.addModular a b))
    ,("finite prime field exhaustive laws",case A.primeField 100 5 >>= A.finiteFieldLaws 5 of Right laws->all snd laws; _->False)
    ,("GF4 extension exhaustive laws",case A.finiteField 100 2 [1,1,1] >>= A.finiteFieldLaws 4 of Right laws->all snd laws; _->False)
    ,("GF9 extension exhaustive laws",case A.finiteField 100 3 [1,0,1] >>= A.finiteFieldLaws 9 of Right laws->all snd laws; _->False)
    ,("finite fields reject composite/reducible",isLeft (A.primeField 100 9) && isLeft (A.finiteField 100 2 [1,0,1]) && isLeft (A.finiteField 100 3 [1]))
    ,("finite-field proof and enumeration budgets",isLeft (A.finiteField 1 2 [1,1,1]) && isLeft (A.finiteField 100 2 [1,1,1] >>= A.fieldElements 3))
    ,("GF256 polynomial arithmetic AES identity",case A.finiteField 100 2 [1,1,0,1,1,0,0,0,1] of Right f->fmap A.fieldElementCoefficients (A.multiplyField (A.fieldElement f [1,1,1,0,1,0,1]) (A.fieldElement f [1,1,0,0,0,0,0,1]))==Right [1,0,0,0,0,0,1,1]; _->False)
    ,("finite-field cardinality and normalized modulus",case A.finiteField 100 3 [2,0,2] of Right f->A.fieldCardinality f==9 && A.fieldModulus f==[1,0,1] && A.fieldCharacteristic f==3 && A.fieldDegree f==2; _->False)
    ,("finite-field inverse zero and mismatch",case (A.primeField 100 3,A.primeField 100 5) of (Right f,Right g)->isLeft (A.inverseFieldElement (A.fieldElement f [])) && isLeft (A.addField (A.fieldElement f [1]) (A.fieldElement g [1])); _->False)
    ,("finite-field Frobenius identity all GF9 elements",case (A.finiteField 100 3 [1,0,1] >>= A.fieldElements 9) of Right xs->all (\a->A.powerField a 9==Right a) xs; _->False)
    ,("finite-field negative power identity",case A.finiteField 100 2 [1,1,1] of Right f->let a=A.fieldElement f [0,1] in (A.powerField a (-1) >>= A.multiplyField a)==Right (A.fieldElement f [1]); _->False)]

near :: Double -> Double -> Bool
near a b=abs (a-b)<=1e-10*max 1 (max (abs a) (abs b))

nearList :: [Double] -> [Double] -> Bool
nearList a b=length a==length b && and (zipWith near a b)
