-- SPDX-License-Identifier: MPL-2.0
-- Independent numeric fixtures generated with SciPy 1.17.1 and mpmath 1.3.0
-- at 50 decimal digits; fixtures contain numeric results, no implementation code.
module ProbabilityBatchSpec (probabilityBatchTests, probabilityBatchIOTests) where

import Data.Complex (realPart)
import qualified Data.Foldable as Foldable (foldl')
import Data.List (nub, sort)
import Data.Word (Word64)
import HMath.Error
import HMath.Matrix (fromListChecked)
import qualified HMath.Probability as P
import qualified HMath.Random as R
import qualified HMath.Special as S
import qualified HMath.Statistics.Advanced as A

near :: Double -> Either MathError Double -> Double -> Bool
near tol actual expected = case actual of Right x -> abs (x - expected) <= tol * max 1 (abs expected); Left _ -> False
isLeft :: Either a b -> Bool
isLeft (Left _) = True
isLeft _ = False
rng :: R.RNG
rng = R.seedRNG R.PCG32 42
probabilityBatchTests :: [(String, Bool)]
probabilityBatchTests =
    referenceTests
        ++ contractTests
        ++ additionalTests
        ++ coulombReferenceTests
        ++ numericEdgeTests
        ++ oscillatoryRegressionTests
        ++ specialTransitionTests
        ++ reviewRegressionTests
referenceTests :: [(String, Bool)]
referenceTests =
    [ ("gamma 0.1", near 1e-09 (S.gamma 0.1) (9.513507698668732))
    , ("loggamma 0.1", near 1e-09 (S.logGamma 0.1) (2.252712651734206))
    , ("digamma 0.1", near 1e-09 (S.digamma 0.1) (-10.423754940411076))
    , ("trigamma 0.1", near 1e-09 (S.trigamma 0.1) (101.43329915079275))
    , ("gamma 0.5", near 1e-09 (S.gamma 0.5) (1.7724538509055159))
    , ("loggamma 0.5", near 1e-09 (S.logGamma 0.5) (0.5723649429247))
    , ("digamma 0.5", near 1e-09 (S.digamma 0.5) (-1.9635100260214235))
    , ("trigamma 0.5", near 1e-09 (S.trigamma 0.5) (4.93480220054468))
    , ("gamma 1.0", near 1e-09 (S.gamma 1.0) (1.0))
    , ("loggamma 1.0", near 1e-09 (S.logGamma 1.0) (0.0))
    , ("digamma 1.0", near 1e-09 (S.digamma 1.0) (-0.5772156649015329))
    , ("trigamma 1.0", near 1e-09 (S.trigamma 1.0) (1.6449340668482266))
    , ("gamma 3.2", near 1e-09 (S.gamma 3.2) (2.4239654799353687))
    , ("loggamma 3.2", near 1e-09 (S.logGamma 3.2) (0.8854048271549091))
    , ("digamma 3.2", near 1e-09 (S.digamma 3.2) (0.9988388912865998))
    , ("trigamma 3.2", near 1e-09 (S.trigamma 3.2) (0.3663211907314009))
    , ("gamma 20.0", near 1e-09 (S.gamma 20.0) (1.21645100408832e+17))
    , ("loggamma 20.0", near 1e-09 (S.logGamma 20.0) (39.339884187199495))
    , ("digamma 20.0", near 1e-09 (S.digamma 20.0) (2.970523992242149))
    , ("trigamma 20.0", near 1e-09 (S.trigamma 20.0) (0.051270822935203124))
    , ("gamma 100.0", near 1e-09 (S.gamma 100.0) (9.332621544394417e+155))
    , ("loggamma 100.0", near 1e-09 (S.logGamma 100.0) (359.1342053695754))
    , ("digamma 100.0", near 1e-09 (S.digamma 100.0) (4.600161852738088))
    , ("trigamma 100.0", near 1e-09 (S.trigamma 100.0) (0.010050166663333573))
    , ("gammaP 0.1 0.001", near 1e-09 (S.gammaP 0.1 0.001) (0.526768568392445))
    , ("gammaQ 0.1 0.001", near 1e-09 (S.gammaQ 0.1 0.001) (0.473231431607555))
    , ("gammaP 0.5 0.5", near 1e-09 (S.gammaP 0.5 0.5) (0.6826894921370859))
    , ("gammaQ 0.5 0.5", near 1e-09 (S.gammaQ 0.5 0.5) (0.31731050786291115))
    , ("gammaP 1 10", near 1e-09 (S.gammaP 1 10) (0.9999546000702375))
    , ("gammaQ 1 10", near 1e-09 (S.gammaQ 1 10) (4.539992976248486e-05))
    , ("gammaP 5 2", near 1e-09 (S.gammaP 5 2) (0.052653017343711125))
    , ("gammaQ 5 2", near 1e-09 (S.gammaQ 5 2) (0.9473469826562889))
    , ("gammaP 5 20", near 1e-09 (S.gammaP 5 20) (0.9999830552560699))
    , ("gammaQ 5 20", near 1e-09 (S.gammaQ 5 20) (1.694474393006737e-05))
    , ("gammaP 100 100", near 1e-09 (S.gammaP 100 100) (0.5132987982791487))
    , ("gammaQ 100 100", near 1e-09 (S.gammaQ 100 100) (0.48670120172085135))
    , ("gammaP 100 150", near 1e-09 (S.gammaP 100 150) (0.9999940754596646))
    , ("gammaQ 100 150", near 1e-09 (S.gammaQ 100 150) (5.924540335483916e-06))
    , ("betaI 0.5 0.5", near 1e-09 (S.betaI 0.5 0.5 0.1) (0.20483276469913345))
    , ("betaI 2 3", near 1e-09 (S.betaI 2 3 0.2) (0.18080000000000004))
    , ("betaI 20 15", near 1e-09 (S.betaI 20 15 0.8) (0.9987740173063321))
    , ("betaI 0.1 10", near 1e-09 (S.betaI 0.1 10 1e-05) (0.41655822619209415))
    , ("erf -10", near 1e-09 (S.erf (-10)) (-1.0))
    , ("erfc -10", near 1e-09 (S.erfc (-10)) (2.0))
    , ("erfcx -10", near 1e-09 (S.sfValue <$> (S.erfcx (-10))) (5.376234283632271e+43))
    , ("Dawson -10", near 1e-09 (S.sfValue <$> (S.dawson (-10))) (-0.05025384718759854))
    , ("erf -1", near 1e-09 (S.erf (-1)) (-0.8427007929497148))
    , ("erfc -1", near 1e-09 (S.erfc (-1)) (1.8427007929497148))
    , ("erfcx -1", near 1e-09 (S.sfValue <$> (S.erfcx (-1))) (5.008980080762283))
    , ("Dawson -1", near 1e-09 (S.sfValue <$> (S.dawson (-1))) (-0.5380795069127684))
    , ("erf 0", near 1e-09 (S.erf (0)) (0.0))
    , ("erfc 0", near 1e-09 (S.erfc (0)) (1.0))
    , ("erfcx 0", near 1e-09 (S.sfValue <$> (S.erfcx (0))) (1.0))
    , ("Dawson 0", near 1e-09 (S.sfValue <$> (S.dawson (0))) (0.0))
    , ("erf 0.5", near 1e-09 (S.erf (0.5)) (0.5204998778130465))
    , ("erfc 0.5", near 1e-09 (S.erfc (0.5)) (0.4795001221869535))
    , ("erfcx 0.5", near 1e-09 (S.sfValue <$> (S.erfcx (0.5))) (0.6156903441929258))
    , ("Dawson 0.5", near 1e-09 (S.sfValue <$> (S.dawson (0.5))) (0.4244363835020223))
    , ("erf 4", near 1e-09 (S.erf (4)) (0.9999999845827421))
    , ("erfc 4", near 1e-09 (S.erfc (4)) (1.541725790028002e-08))
    , ("erfcx 4", near 1e-09 (S.sfValue <$> (S.erfcx (4))) (0.1369994576250614))
    , ("Dawson 4", near 1e-09 (S.sfValue <$> (S.dawson (4))) (0.1293480012360051))
    , ("erf 30", near 1e-09 (S.erf (30)) (1.0))
    , ("erfc 30", near 1e-09 (S.erfc (30)) (0.0))
    , ("erfcx 30", near 1e-09 (S.sfValue <$> (S.erfcx (30))) (0.018795888861416754))
    , ("Dawson 30", near 1e-09 (S.sfValue <$> (S.dawson (30))) (0.016675941401059196))
    , ("inverse erf -0.9", near 1e-09 (S.inverseErf (-0.9)) (-1.1630871536766743))
    , ("inverse erf 0", near 1e-09 (S.inverseErf (0)) (0.0))
    , ("inverse erf 0.9", near 1e-09 (S.inverseErf (0.9)) (1.1630871536766743))
    , ("normal quantile 1e-30", near 1e-09 (S.normalQuantile 1e-30) (-11.464024688443613))
    , ("normal quantile 0.001", near 1e-09 (S.normalQuantile 0.001) (-3.090232306167813))
    , ("normal quantile 0.5", near 1e-09 (S.normalQuantile 0.5) (0.0))
    , ("normal quantile 0.99", near 1e-09 (S.normalQuantile 0.99) (2.3263478740408408))
    ,
        ( "normal quantile 0.999999999999"
        , near 1e-09 (S.normalQuantile 0.999999999999) (7.0344869100478356)
        )
    , ("expint 1", near 1e-09 (S.sfValue <$> (S.exponentialIntegral 1 1.2)) (0.1584084368514626))
    , ("expint 2", near 1e-09 (S.sfValue <$> (S.exponentialIntegral 2 1.2)) (0.11110408769044697))
    , ("expint 5", near 1e-09 (S.sfValue <$> (S.exponentialIntegral 5 1.2)) (0.0552512901878503))
    , ("li", near 1e-09 (S.sfValue <$> (S.logarithmicIntegral 2)) (1.045163780117493))
    , ("Si", near 1e-09 (S.sfValue <$> (S.sineIntegral 2)) (1.605412976802695))
    , ("Ci", near 1e-09 (S.sfValue <$> (S.cosineIntegral 2)) (0.422980828774865))
    , ("Fresnel C", near 1e-09 (S.sfValue . fst <$> S.fresnel 1) (0.779893400376823))
    , ("Fresnel S", near 1e-09 (S.sfValue . snd <$> S.fresnel 1) (0.4382591473903547))
    , ("elliptic F", near 1e-09 (S.sfValue <$> (S.ellipticF 1 0.5)) (1.0832167728451687))
    , ("elliptic E", near 1e-09 (S.sfValue <$> (S.ellipticE 1 0.5)) (0.92732988362444))
    , ("elliptic Pi", near 1e-09 (S.sfValue <$> (S.ellipticPi 0.2 1 0.5)) (1.1520712984118453))
    , ("Jacobi 0 0.2", near 1e-08 ((\(a, _, _) -> a) <$> S.jacobiElliptic 0.2 0.5) (0.19802174298197048))
    , ("Jacobi 1 0.2", near 1e-08 ((\(_, a, _) -> a) <$> S.jacobiElliptic 0.2 0.5) (0.9801976276784098))
    , ("Jacobi 2 0.2", near 1e-08 ((\(_, _, a) -> a) <$> S.jacobiElliptic 0.2 0.5) (0.9901483195224801))
    , ("Jacobi 0 1.0", near 1e-08 ((\(a, _, _) -> a) <$> S.jacobiElliptic 1.0 0.5) (0.8030018248956439))
    , ("Jacobi 1 1.0", near 1e-08 ((\(_, a, _) -> a) <$> S.jacobiElliptic 1.0 0.5) (0.5959765676721407))
    , ("Jacobi 2 1.0", near 1e-08 ((\(_, _, a) -> a) <$> S.jacobiElliptic 1.0 0.5) (0.8231610016315963))
    , ("Jacobi 0 3.0", near 1e-08 ((\(a, _, _) -> a) <$> S.jacobiElliptic 3.0 0.5) (0.630028998242033))
    , ("Jacobi 1 3.0", near 1e-08 ((\(_, a, _) -> a) <$> S.jacobiElliptic 3.0 0.5) (-0.7765716073705891))
    , ("Jacobi 2 3.0", near 1e-08 ((\(_, _, a) -> a) <$> S.jacobiElliptic 3.0 0.5) (0.8952830450126206))
    , ("Jacobi 0 10.0", near 1e-08 ((\(a, _, _) -> a) <$> S.jacobiElliptic 10.0 0.5) (0.8588125059527789))
    ,
        ( "Jacobi 1 10.0"
        , near 1e-08 ((\(_, a, _) -> a) <$> S.jacobiElliptic 10.0 0.5) (-0.5122900346669922)
        )
    , ("Jacobi 2 10.0", near 1e-08 ((\(_, _, a) -> a) <$> S.jacobiElliptic 10.0 0.5) (0.7944938890951594))
    , ("BesselJ 0", near 1e-09 (S.besselJ 0 2) (0.22389077914123562))
    , ("BesselY 0", near 1e-09 (S.besselY 0 2) (0.5103756726497453))
    , ("BesselI 0", near 1e-09 (S.sfValue <$> (S.besselI 0 2)) (2.2795853023360673))
    , ("BesselK 0", near 1e-09 (S.sfValue <$> (S.besselK 0 2)) (0.11389387274953341))
    , ("sphericalJ 0", near 1e-09 (S.sphericalBesselJ 0 2) (0.45464871341284085))
    , ("sphericalY 0", near 1e-09 (S.sphericalBesselY 0 2) (0.2080734182735712))
    , ("BesselJ 1", near 1e-09 (S.besselJ 1 2) (0.5767248077568736))
    , ("BesselY 1", near 1e-09 (S.besselY 1 2) (-0.1070324315409375))
    , ("BesselI 1", near 1e-09 (S.sfValue <$> (S.besselI 1 2)) (1.590636854637329))
    , ("BesselK 1", near 1e-09 (S.sfValue <$> (S.besselK 1 2)) (0.13986588181652246))
    , ("sphericalJ 1", near 1e-09 (S.sphericalBesselJ 1 2) (0.43539777497999166))
    , ("sphericalY 1", near 1e-09 (S.sphericalBesselY 1 2) (-0.35061200427605527))
    , ("BesselJ 3", near 1e-09 (S.besselJ 3 2) (0.12894324947440208))
    , ("BesselY 3", near 1e-09 (S.besselY 3 2) (-1.127783776840428))
    , ("BesselI 3", near 1e-09 (S.sfValue <$> (S.besselI 3 2)) (0.21273995923985264))
    , ("BesselK 3", near 1e-09 (S.sfValue <$> (S.besselK 3 2)) (0.6473853909486342))
    , ("sphericalJ 3", near 1e-09 (S.sphericalBesselJ 3 2) (0.060722097662874876))
    , ("sphericalY 3", near 1e-09 (S.sphericalBesselY 3 2) (-1.48436655744308))
    , ("scaled I large", near 1e-09 (S.sfValue <$> (S.scaledBesselI 0 1000)) (0.012617240455891255))
    , ("scaled K large", near 1e-09 (S.sfValue <$> (S.scaledBesselK 0 1000)) (0.03962832160075422))
    , ("Airy 0 -2.0", near 1e-07 ((\(a, _, _, _) -> S.sfValue a) <$> S.airy (-2.0)) (0.22740742820168564))
    , ("Airy 1 -2.0", near 1e-07 ((\(_, a, _, _) -> S.sfValue a) <$> S.airy (-2.0)) (0.618259020741691))
    , ("Airy 2 -2.0", near 1e-07 ((\(_, _, a, _) -> S.sfValue a) <$> S.airy (-2.0)) (-0.4123025879563985))
    , ("Airy 3 -2.0", near 1e-07 ((\(_, _, _, a) -> S.sfValue a) <$> S.airy (-2.0)) (0.27879516692116973))
    , ("Airy 0 0.0", near 1e-07 ((\(a, _, _, _) -> S.sfValue a) <$> S.airy (0.0)) (0.3550280538878172))
    , ("Airy 1 0.0", near 1e-07 ((\(_, a, _, _) -> S.sfValue a) <$> S.airy (0.0)) (-0.2588194037928068))
    , ("Airy 2 0.0", near 1e-07 ((\(_, _, a, _) -> S.sfValue a) <$> S.airy (0.0)) (0.6149266274460007))
    , ("Airy 3 0.0", near 1e-07 ((\(_, _, _, a) -> S.sfValue a) <$> S.airy (0.0)) (0.4482883573538264))
    , ("Airy 0 2.0", near 1e-07 ((\(a, _, _, _) -> S.sfValue a) <$> S.airy (2.0)) (0.03492413042327436))
    , ("Airy 1 2.0", near 1e-07 ((\(_, a, _, _) -> S.sfValue a) <$> S.airy (2.0)) (-0.05309038443365388))
    , ("Airy 2 2.0", near 1e-07 ((\(_, _, a, _) -> S.sfValue a) <$> S.airy (2.0)) (3.2980949999782143))
    , ("Airy 3 2.0", near 1e-07 ((\(_, _, _, a) -> S.sfValue a) <$> S.airy (2.0)) (4.10068204993289))
    , ("Airy 0 6.0", near 1e-07 ((\(a, _, _, _) -> S.sfValue a) <$> S.airy (6.0)) (9.947694360252897e-06))
    ,
        ( "Airy 1 6.0"
        , near 1e-07 ((\(_, a, _, _) -> S.sfValue a) <$> S.airy (6.0)) (-2.4765200397034972e-05)
        )
    , ("Airy 2 6.0", near 1e-07 ((\(_, _, a, _) -> S.sfValue a) <$> S.airy (6.0)) (6536.446104809864))
    , ("Airy 3 6.0", near 1e-07 ((\(_, _, _, a) -> S.sfValue a) <$> S.airy (6.0)) (15725.602621930475))
    , ("Struve", near 1e-09 (S.sfValue <$> (S.struve 0.5 2)) (0.7989752939540048))
    , ("1F1", near 1e-09 (S.sfValue <$> (S.hypergeometric1F1 0.5 2 3)) (2.980577617801989))
    , ("2F1", near 1e-09 (S.sfValue <$> (S.hypergeometric2F1 0.5 2 3 0.2)) (1.0753393266728355))
    , ("0F1", near 1e-09 (S.sfValue <$> (S.hypergeometric [] [2] 3)) (3.468649618760533))
    , ("Legendre", near 1e-09 (S.legendre 5 0.3) (0.3453862499999999))
    , ("associated Legendre", near 1e-09 (S.associatedLegendre 5 2 0.3) (-10.462725))
    , ("zeta -3.0", near 1e-08 (S.sfValue <$> (S.riemannZeta (-3.0))) (0.008333333333333333))
    , ("zeta 0.5", near 1e-08 (S.sfValue <$> (S.riemannZeta (0.5))) (-1.4603545088095868))
    , ("zeta 2.0", near 1e-08 (S.sfValue <$> (S.riemannZeta (2.0))) (1.6449340668482264))
    , ("zeta 10.0", near 1e-08 (S.sfValue <$> (S.riemannZeta (10.0))) (1.000994575127818))
    , ("Hurwitz", near 1e-09 (S.sfValue <$> (S.hurwitzZeta 2 0.5)) (4.93480220054468))
    , ("polylog", near 1e-09 (S.sfValue <$> (S.polylogarithm 3 0.4)) (0.422877820191444))
    , ("dilog", near 1e-09 (S.sfValue <$> (S.dilogarithm (-2))) (-1.4367463668836808))
    , ("Lambert 0 1.0", near 1e-09 (S.sfValue <$> (S.lambertW (0) (1.0))) (0.5671432904097838))
    , ("Lambert 0 -0.3", near 1e-09 (S.sfValue <$> (S.lambertW (0) (-0.3))) (-0.4894022271802149))
    , ("Lambert -1 -0.1", near 1e-09 (S.sfValue <$> (S.lambertW (-1) (-0.1))) (-3.577152063957297))
    , ("Debye", near 1e-09 (S.sfValue <$> (S.debye 3 2)) (0.4411284737276242))
    , ("Clausen", near 1e-09 (S.sfValue <$> (S.clausen 1)) (1.0139591323607684))
    , ("Fermi", near 1e-09 (S.sfValue <$> (S.fermiDirac 0.5 1)) (1.5756407761513003))
    , ("Bose", near 1e-09 (S.sfValue <$> (S.boseEinstein 1 (-1))) (0.4087542873488963))
    , ("Coulomb regular", near 1e-09 (S.sfValue . fst <$> S.coulombWave 0 0 1) (0.8414709848078965))
    , ("Coulomb irregular", near 1e-06 (S.sfValue . snd <$> S.coulombWave 0 0 1) (0.5403023058681398))
    , ("Gegenbauer", near 1e-09 (S.gegenbauer 4 0.5 0.3) (0.07293749999999993))
    , ("parabolic cylinder", near 1e-09 (S.sfValue <$> (S.parabolicCylinder 0.5 1)) (0.8422032440698389))
    , ("Mathieu characteristic", near 1e-07 (fst <$> S.mathieu True 2 1 0.3) (4.371300982735086))
    , ("Mathieu ce", near 1e-07 (S.sfValue . snd <$> S.mathieu True 2 1 0.3) (0.8926403704086987))
    , ("Bernoulli polynomial", near 1e-09 (S.bernoulliPolynomial 4 0.2) (-0.007733333333333331))
    , ("Euler polynomial", near 1e-09 (S.eulerPolynomial 4 0.2) (0.18560000000000001))
    , ("Wigner 3j", near 1e-09 (S.wigner3j 2 2 0 0 0 0) (-0.5773502691896257))
    , ("Wigner 6j", near 1e-09 (S.wigner6j 2 2 2 2 2 2) (0.16666666666666666))
    , ("Wigner 9j", near 1e-09 (S.wigner9j [0, 0, 0, 0, 0, 0, 0, 0, 0]) (1.0))
    , ("Clebsch-Gordan", near 1e-09 (S.clebschGordan 1 1 1 (-1) 0 0) (0.7071067811865476))
    , ("Bernoulli density", near 1e-08 (P.density (P.Bernoulli 0.3) (1)) (0.3))
    , ("Bernoulli cdf", near 1e-08 (P.cdf (P.Bernoulli 0.3) (1)) (1.0))
    , ("Bernoulli mean", near 1e-08 (fst <$> P.moments (P.Bernoulli 0.3)) (0.3))
    , ("Bernoulli variance", near 1e-08 (snd <$> P.moments (P.Bernoulli 0.3)) (0.21))
    , ("Binomial density", near 1e-08 (P.density (P.Binomial 10 0.3) (3)) (0.2668279319999998))
    , ("Binomial cdf", near 1e-08 (P.cdf (P.Binomial 10 0.3) (3)) (0.6496107184000002))
    , ("Binomial mean", near 1e-08 (fst <$> P.moments (P.Binomial 10 0.3)) (3.0))
    , ("Binomial variance", near 1e-08 (snd <$> P.moments (P.Binomial 10 0.3)) (2.1))
    , ("NegativeBinomial density", near 1e-08 (P.density (P.NegativeBinomial 2 0.4) (3)) (0.13824))
    , ("NegativeBinomial cdf", near 1e-08 (P.cdf (P.NegativeBinomial 2 0.4) (3)) (0.6630400000000001))
    ,
        ( "NegativeBinomial mean"
        , near 1e-08 (fst <$> P.moments (P.NegativeBinomial 2 0.4)) (2.9999999999999996)
        )
    ,
        ( "NegativeBinomial variance"
        , near 1e-08 (snd <$> P.moments (P.NegativeBinomial 2 0.4)) (7.499999999999998)
        )
    , ("Geometric density", near 1e-08 (P.density (P.Geometric 0.4) (2)) (0.14400000000000002))
    , ("Geometric cdf", near 1e-08 (P.cdf (P.Geometric 0.4) (2)) (0.784))
    , ("Geometric mean", near 1e-08 (fst <$> P.moments (P.Geometric 0.4)) (1.4999999999999998))
    , ("Geometric variance", near 1e-08 (snd <$> P.moments (P.Geometric 0.4)) (3.749999999999999))
    ,
        ( "Hypergeometric density"
        , near 1e-08 (P.density (P.Hypergeometric 20 7 5) (2)) (0.38738390092879255)
        )
    , ("Hypergeometric cdf", near 1e-08 (P.cdf (P.Hypergeometric 20 7 5) (2)) (0.7932146542827657))
    , ("Hypergeometric mean", near 1e-08 (fst <$> P.moments (P.Hypergeometric 20 7 5)) (1.75))
    ,
        ( "Hypergeometric variance"
        , near 1e-08 (snd <$> P.moments (P.Hypergeometric 20 7 5)) (0.8980263157894737)
        )
    , ("Poisson density", near 1e-08 (P.density (P.Poisson 4) (3)) (0.19536681481316454))
    , ("Poisson cdf", near 1e-08 (P.cdf (P.Poisson 4) (3)) (0.43347012036670896))
    , ("Poisson mean", near 1e-08 (fst <$> P.moments (P.Poisson 4)) (4.0))
    , ("Poisson variance", near 1e-08 (snd <$> P.moments (P.Poisson 4)) (4.0))
    ,
        ( "DiscreteUniform density"
        , near 1e-08 (P.density (P.DiscreteUniform 2 7) (4)) (0.16666666666666666)
        )
    , ("DiscreteUniform cdf", near 1e-08 (P.cdf (P.DiscreteUniform 2 7) (4)) (0.5))
    , ("DiscreteUniform mean", near 1e-08 (fst <$> P.moments (P.DiscreteUniform 2 7)) (4.5))
    ,
        ( "DiscreteUniform variance"
        , near 1e-08 (snd <$> P.moments (P.DiscreteUniform 2 7)) (2.9166666666666665)
        )
    , ("Uniform density", near 1e-08 (P.density (P.Uniform 2 5) (3)) (0.3333333333333333))
    , ("Uniform cdf", near 1e-08 (P.cdf (P.Uniform 2 5) (3)) (0.3333333333333333))
    , ("Uniform mean", near 1e-08 (fst <$> P.moments (P.Uniform 2 5)) (3.5))
    , ("Uniform variance", near 1e-08 (snd <$> P.moments (P.Uniform 2 5)) (0.75))
    , ("Normal density", near 1e-08 (P.density (P.Normal 2 3) (1)) (0.12579440923099774))
    , ("Normal cdf", near 1e-08 (P.cdf (P.Normal 2 3) (1)) (0.36944134018176367))
    , ("Normal mean", near 1e-08 (fst <$> P.moments (P.Normal 2 3)) (2.0))
    , ("Normal variance", near 1e-08 (snd <$> P.moments (P.Normal 2 3)) (9.0))
    , ("LogNormal density", near 1e-08 (P.density (P.LogNormal 0.5 0.8) (2)) (0.24217677488483338))
    , ("LogNormal cdf", near 1e-08 (P.cdf (P.LogNormal 0.5 0.8) (2)) (0.595390608679215))
    , ("LogNormal mean", near 1e-08 (fst <$> P.moments (P.LogNormal 0.5 0.8)) (2.270499837532406))
    , ("LogNormal variance", near 1e-08 (snd <$> P.moments (P.LogNormal 0.5 0.8)) (4.621510897294227))
    , ("Exponential density", near 1e-08 (P.density (P.Exponential 2) (0.7)) (0.493193927883213))
    , ("Exponential cdf", near 1e-08 (P.cdf (P.Exponential 2) (0.7)) (0.7534030360583935))
    , ("Exponential mean", near 1e-08 (fst <$> P.moments (P.Exponential 2)) (0.5))
    , ("Exponential variance", near 1e-08 (snd <$> P.moments (P.Exponential 2)) (0.25))
    , ("Gamma density", near 1e-08 (P.density (P.Gamma 2 3) (4)) (0.11715428360698966))
    , ("Gamma cdf", near 1e-08 (P.cdf (P.Gamma 2 3) (4)) (0.38494001106330406))
    , ("Gamma mean", near 1e-08 (fst <$> P.moments (P.Gamma 2 3)) (6.0))
    , ("Gamma variance", near 1e-08 (snd <$> P.moments (P.Gamma 2 3)) (18.0))
    , ("Beta density", near 1e-08 (P.density (P.Beta 2 3) (0.4)) (1.7279999999999998))
    , ("Beta cdf", near 1e-08 (P.cdf (P.Beta 2 3) (0.4)) (0.5247999999999999))
    , ("Beta mean", near 1e-08 (fst <$> P.moments (P.Beta 2 3)) (0.4))
    , ("Beta variance", near 1e-08 (snd <$> P.moments (P.Beta 2 3)) (0.04))
    , ("ChiSquare density", near 1e-08 (P.density (P.ChiSquare 4) (3)) (0.1673476201113224))
    , ("ChiSquare cdf", near 1e-08 (P.cdf (P.ChiSquare 4) (3)) (0.4421745996289252))
    , ("ChiSquare mean", near 1e-08 (fst <$> P.moments (P.ChiSquare 4)) (4.0))
    , ("ChiSquare variance", near 1e-08 (snd <$> P.moments (P.ChiSquare 4)) (8.0))
    , ("StudentT density", near 1e-08 (P.density (P.StudentT 5) (1)) (0.21967979735098056))
    , ("StudentT cdf", near 1e-08 (P.cdf (P.StudentT 5) (1)) (0.8183912661754386))
    , ("StudentT mean", near 1e-08 (fst <$> P.moments (P.StudentT 5)) (0.0))
    , ("StudentT variance", near 1e-08 (snd <$> P.moments (P.StudentT 5)) (1.6666666666666667))
    , ("FisherF density", near 1e-08 (P.density (P.FisherF 4 8) (2)) (0.15625000000000008))
    , ("FisherF cdf", near 1e-08 (P.cdf (P.FisherF 4 8) (2)) (0.8125))
    , ("FisherF mean", near 1e-08 (fst <$> P.moments (P.FisherF 4 8)) (1.3333333333333333))
    , ("FisherF variance", near 1e-08 (snd <$> P.moments (P.FisherF 4 8)) (2.2222222222222223))
    , ("Cauchy density", near 1e-08 (P.density (P.Cauchy 1 2) (3)) (0.07957747154594767))
    , ("Cauchy cdf", near 1e-08 (P.cdf (P.Cauchy 1 2) (3)) (0.75))
    , ("Laplace density", near 1e-08 (P.density (P.Laplace 1 2) (3)) (0.09196986029286058))
    , ("Laplace cdf", near 1e-08 (P.cdf (P.Laplace 1 2) (3)) (0.8160602794142788))
    , ("Laplace mean", near 1e-08 (fst <$> P.moments (P.Laplace 1 2)) (1.0))
    , ("Laplace variance", near 1e-08 (snd <$> P.moments (P.Laplace 1 2)) (8.0))
    , ("Logistic density", near 1e-08 (P.density (P.Logistic 1 2) (3)) (0.09830596662074093))
    , ("Logistic cdf", near 1e-08 (P.cdf (P.Logistic 1 2) (3)) (0.7310585786300049))
    , ("Logistic mean", near 1e-08 (fst <$> P.moments (P.Logistic 1 2)) (1.0))
    , ("Logistic variance", near 1e-08 (snd <$> P.moments (P.Logistic 1 2)) (13.159472534785811))
    , ("Weibull density", near 1e-08 (P.density (P.Weibull 2 3) (2)) (0.28496906152442425))
    , ("Weibull cdf", near 1e-08 (P.cdf (P.Weibull 2 3) (2)) (0.3588196115700454))
    , ("Weibull mean", near 1e-08 (fst <$> P.moments (P.Weibull 2 3)) (2.658680776358274))
    , ("Weibull variance", near 1e-08 (snd <$> P.moments (P.Weibull 2 3)) (1.9314165294229664))
    , ("Pareto density", near 1e-08 (P.density (P.Pareto 2 3) (3)) (0.2962962962962963))
    , ("Pareto cdf", near 1e-08 (P.cdf (P.Pareto 2 3) (3)) (0.7037037037037037))
    , ("Pareto mean", near 1e-08 (fst <$> P.moments (P.Pareto 2 3)) (3.0))
    , ("Pareto variance", near 1e-08 (snd <$> P.moments (P.Pareto 2 3)) (3.0))
    , ("Rayleigh density", near 1e-08 (P.density (P.Rayleigh 2) (3)) (0.2434893505187623))
    , ("Rayleigh cdf", near 1e-08 (P.cdf (P.Rayleigh 2) (3)) (0.6753475326416503))
    , ("Rayleigh mean", near 1e-08 (fst <$> P.moments (P.Rayleigh 2)) (2.5066282746310002))
    , ("Rayleigh variance", near 1e-08 (snd <$> P.moments (P.Rayleigh 2)) (1.7168146928204138))
    , ("Maxwell density", near 1e-08 (P.density (P.Maxwell 2) (3)) (0.29141459024825644))
    , ("Maxwell cdf", near 1e-08 (P.cdf (P.Maxwell 2) (3)) (0.47783281046460857))
    , ("Maxwell mean", near 1e-08 (fst <$> P.moments (P.Maxwell 2)) (3.1915382432114616))
    , ("Maxwell variance", near 1e-08 (snd <$> P.moments (P.Maxwell 2)) (1.8140836421186979))
    , ("Gumbel density", near 1e-08 (P.density (P.Gumbel 1 2) (3)) (0.12732319002179124))
    , ("Gumbel cdf", near 1e-08 (P.cdf (P.Gumbel 1 2) (3)) (0.6922006275553464))
    , ("Gumbel mean", near 1e-08 (fst <$> P.moments (P.Gumbel 1 2)) (2.1544313298030655))
    , ("Gumbel variance", near 1e-08 (snd <$> P.moments (P.Gumbel 1 2)) (6.579736267392906))
    ,
        ( "GeneralizedExtremeValue density"
        , near 1e-08 (P.density (P.GeneralizedExtremeValue 1 2 0.2) (3)) (0.11203386432543154)
        )
    ,
        ( "GeneralizedExtremeValue cdf"
        , near 1e-08 (P.cdf (P.GeneralizedExtremeValue 1 2 0.2) (3)) (0.6690626526678188)
        )
    ,
        ( "GeneralizedExtremeValue mean"
        , near 1e-08 (fst <$> P.moments (P.GeneralizedExtremeValue 1 2 0.2)) (2.642297137253033)
        )
    ,
        ( "GeneralizedExtremeValue variance"
        , near 1e-08 (snd <$> P.moments (P.GeneralizedExtremeValue 1 2 0.2)) (13.376142249191547)
        )
    , ("BetaBinomial density", near 1e-08 (P.density (P.BetaBinomial 10 2 3) (3)) (0.14385614385614395))
    , ("BetaBinomial cdf", near 1e-08 (P.cdf (P.BetaBinomial 10 2 3) (3)) (0.4545454545454546))
    , ("BetaBinomial mean", near 1e-08 (fst <$> P.moments (P.BetaBinomial 10 2 3)) (4.0))
    , ("BetaBinomial variance", near 1e-08 (snd <$> P.moments (P.BetaBinomial 10 2 3)) (6.0))
    , ("Skellam density", near 1e-08 (P.density (P.Skellam 3 2) (1)) (0.1830233444549473))
    , ("Skellam cdf", near 1e-08 (P.cdf (P.Skellam 3 2) (1)) (0.5977339296890773))
    , ("VonMises density", near 1e-08 (P.density (P.VonMises 0 2) (1)) (0.20571449951559537))
    , ("VonMises cdf", near 1e-08 (P.cdf (P.VonMises 0 2) (1)) (0.8895777369550326))
    , ("Triangular density", near 1e-08 (P.density (P.Triangular 1 2 4) (2.5)) (0.49999999999999994))
    , ("Triangular cdf", near 1e-08 (P.cdf (P.Triangular 1 2 4) (2.5)) (0.625))
    ,
        ( "TruncatedNormal density"
        , near 1e-08 (P.density (P.TruncatedNormal 0 1 (-1) 2) (0.5)) (0.43008507592322476)
        )
    ,
        ( "TruncatedNormal cdf"
        , near 1e-08 (P.cdf (P.TruncatedNormal 0 1 (-1) 2) (0.5)) (0.6508804213366272)
        )
    , ("arithmetic mean", near 1e-09 (A.arithmeticMean [1, 2, 3, 4]) (2.5))
    , ("weighted mean", near 1e-09 (A.weightedMean [1, 2, 3] [1, 2, 1]) (2.0))
    , ("geometric mean", near 1e-09 (A.geometricMean [1, 4, 16]) (4.0))
    , ("harmonic mean", near 1e-09 (A.harmonicMean [1, 2, 4]) (1.7142857142857142))
    , ("RMS", near 1e-09 (A.rms [3, 4]) (3.5355339059327378))
    , ("trimmed", near 1e-09 (A.trimmedMean 0.2 [0, 1, 2, 3, 100]) (2.0))
    , ("winsorized", near 1e-09 (A.winsorizedMean 0.2 [0, 1, 2, 3, 100]) (2.0))
    , ("quantile type7", near 1e-09 (A.quantile 0.25 [1, 2, 3, 4]) (1.75))
    , ("MAD", near 1e-09 (A.medianAbsoluteDeviation [1, 1, 2, 2, 4]) (1.0))
    , ("sample variance", near 1e-09 (A.sampleVariance [1, 2, 3, 4]) (1.6666666666666667))
    , ("population variance", near 1e-09 (A.populationVariance [1, 2, 3, 4]) (1.25))
    , ("skewness", near 1e-09 (A.skewness [1, 2, 4, 8]) (0.6568077344996993))
    , ("kurtosis", near 1e-09 (A.kurtosis [1, 2, 4, 8]) (-1.0989792060491494))
    , ("Spearman ties", near 1e-09 (A.spearman [1, 2, 2, 4] [4, 1, 2, 3]) (-0.316227766016838))
    , ("Kendall ties", near 1e-09 (A.kendall [1, 2, 2, 4] [4, 1, 2, 3]) (-0.18257418583505539))
    , ("entropy", near 1e-09 (A.entropy [0.5, 0.5]) (0.6931471805599453))
    , ("KL", near 1e-09 (A.klDivergence [0.5, 0.5] [0.25, 0.75]) (0.14384103622589045))
    ,
        ( "one-sample t statistic"
        , near 1e-06 (A.testStatistic <$> (A.oneSampleT 3 [1, 2, 3, 5, 8, 13, 21])) (1.6780242408520976)
        )
    ,
        ( "one-sample t pvalue"
        , near 1e-06 (A.pValue <$> (A.oneSampleT 3 [1, 2, 3, 5, 8, 13, 21])) (0.14435123304309236)
        )
    ,
        ( "Welch t statistic"
        , near
            1e-06
            (A.testStatistic <$> (A.twoSampleT False [1, 2, 3, 5, 8, 13, 21] [2, 3, 4, 6, 7, 9, 12]))
            (0.4708816093480109)
        )
    ,
        ( "Welch t pvalue"
        , near
            1e-06
            (A.pValue <$> (A.twoSampleT False [1, 2, 3, 5, 8, 13, 21] [2, 3, 4, 6, 7, 9, 12]))
            (0.6492753875473636)
        )
    ,
        ( "pooled t statistic"
        , near
            1e-06
            (A.testStatistic <$> (A.twoSampleT True [1, 2, 3, 5, 8, 13, 21] [2, 3, 4, 6, 7, 9, 12]))
            (0.4708816093480109)
        )
    ,
        ( "pooled t pvalue"
        , near
            1e-06
            (A.pValue <$> (A.twoSampleT True [1, 2, 3, 5, 8, 13, 21] [2, 3, 4, 6, 7, 9, 12]))
            (0.6461695865683036)
        )
    ,
        ( "paired t statistic"
        , near
            1e-06
            (A.testStatistic <$> (A.pairedT [1, 2, 3, 5, 8, 13, 21] [2, 3, 4, 6, 7, 9, 12]))
            (0.9885336094784051)
        )
    ,
        ( "paired t pvalue"
        , near
            1e-06
            (A.pValue <$> (A.pairedT [1, 2, 3, 5, 8, 13, 21] [2, 3, 4, 6, 7, 9, 12]))
            (0.3610643268204814)
        )
    ,
        ( "ANOVA statistic"
        , near
            1e-06
            (A.testStatistic <$> (A.anova [[1, 2, 3, 5, 8, 13, 21], [2, 3, 4, 6, 7, 9, 12], [3, 4, 5, 8, 9]]))
            (0.21791830973618734)
        )
    ,
        ( "ANOVA pvalue"
        , near
            1e-06
            (A.pValue <$> (A.anova [[1, 2, 3, 5, 8, 13, 21], [2, 3, 4, 6, 7, 9, 12], [3, 4, 5, 8, 9]]))
            (0.8065389345790192)
        )
    ,
        ( "Kruskal-Wallis statistic"
        , near
            1e-06
            (A.testStatistic <$> (A.kruskalWallis [[1, 2, 3, 5, 8, 13, 21], [2, 3, 4, 6, 7, 9, 12]]))
            (0.004099653106276118)
        )
    ,
        ( "Kruskal-Wallis pvalue"
        , near
            1e-06
            (A.pValue <$> (A.kruskalWallis [[1, 2, 3, 5, 8, 13, 21], [2, 3, 4, 6, 7, 9, 12]]))
            (0.9489475069433878)
        )
    ,
        ( "Mann-Whitney statistic"
        , near
            1e-06
            (A.testStatistic <$> (A.mannWhitney [1, 2, 3, 5, 8, 13, 21] [2, 3, 4, 6, 7, 9, 12]))
            (24.0)
        )
    ,
        ( "Mann-Whitney pvalue"
        , near 1e-06 (A.pValue <$> (A.mannWhitney [1, 2, 3, 5, 8, 13, 21] [2, 3, 4, 6, 7, 9, 12])) (1.0)
        )
    , ("Wilcoxon statistic", near 1e-06 (A.testStatistic <$> (A.wilcoxon [1, 2, -3, 4, -5, 6])) (8.0))
    ,
        ( "Wilcoxon pvalue"
        , near 1e-06 (A.pValue <$> (A.wilcoxon [1, 2, -3, 4, -5, 6])) (0.6749867139704893)
        )
    ,
        ( "Shapiro-Wilk statistic"
        , near 1e-06 (A.testStatistic <$> (A.shapiroWilk [1, 2, 3, 5, 8, 13, 21])) (0.8735010953464453)
        )
    ,
        ( "Shapiro-Wilk pvalue"
        , near 1e-06 (A.pValue <$> (A.shapiroWilk [1, 2, 3, 5, 8, 13, 21])) (0.19912783054171512)
        )
    ,
        ( "Bartlett statistic"
        , near
            1e-06
            (A.testStatistic <$> (A.bartlett [[1, 2, 3, 5, 8, 13, 21], [2, 3, 4, 6, 7, 9, 12]]))
            (2.6067899388601004)
        )
    ,
        ( "Bartlett pvalue"
        , near
            1e-06
            (A.pValue <$> (A.bartlett [[1, 2, 3, 5, 8, 13, 21], [2, 3, 4, 6, 7, 9, 12]]))
            (0.10640695682236576)
        )
    ,
        ( "Levene statistic"
        , near
            1e-06
            (A.testStatistic <$> (A.levene True [[1, 2, 3, 5, 8, 13, 21], [2, 3, 4, 6, 7, 9, 12]]))
            (1.262008733624454)
        )
    ,
        ( "Levene pvalue"
        , near
            1e-06
            (A.pValue <$> (A.levene True [[1, 2, 3, 5, 8, 13, 21], [2, 3, 4, 6, 7, 9, 12]]))
            (0.2832435720592805)
        )
    ,
        ( "Fisher statistic"
        , near 1e-06 (A.testStatistic <$> (A.fisherExact 1 9 11 3)) (0.030303030303030304)
        )
    , ("Fisher pvalue", near 1e-06 (A.pValue <$> (A.fisherExact 1 9 11 3)) (0.0027594561852200836))
    ]
contractTests :: [(String, Bool)]
contractTests =
    [ ( "generator serialization and clone " ++ show g
      , let r = R.seedRNG g 123; (x, t) = R.nextWord64 r
         in R.restoreRNG (R.serializeRNG r) == Right r && R.nextWord64 (R.cloneRNG r) == (x, t)
      )
    | g <- [minBound .. maxBound]
    ]
        ++ [ ( "split deterministic " ++ show g
             , let r = R.seedRNG g 123; (a, b) = R.splitRNG r in a /= b && R.splitRNG r == (a, b)
             )
           | g <- [minBound .. maxBound]
           ]
        ++ [ ( "random uniform moments " ++ show g
             , case R.randomQuality 2000 (R.seedRNG g 23) of
                Right ((m, v, c), _) -> abs (m - 0.5) < 0.04 && abs (v - 1 / 12) < 0.015 && abs c < 0.1
                _ -> False
             )
           | g <- [minBound .. maxBound]
           ]
        ++ [
               ( "PCG32 published seed42 stream54"
               , case R.restoreRNG "hmath-rng-1 RawRNG PCG32 [1753877967969059832,109] []" of
                    Right r -> fst (R.nextWord64 r) == 0xa15c02b77b47f409
                    _ -> False
               )
           ,
               ( "xoshiro256** published state recurrence"
               , case R.restoreRNG "hmath-rng-1 RawRNG Xoshiro256StarStar [1,2,3,4] []" of
                    Right r -> let (a, t) = R.nextWord64 r; (b, _) = R.nextWord64 t in a == 11520 && b == 0
                    _ -> False
               )
           ,
               ( "xoroshiro128+ initial state vector"
               , case R.restoreRNG "hmath-rng-1 RawRNG Xoroshiro128Plus [1,2] []" of
                    Right r -> let (a, t) = R.nextWord64 r; (b, _) = R.nextWord64 t in a == 3 && b == 412333834243
                    _ -> False
               )
           ,
               ( "ChaCha20 RFC zero key block"
               , case R.restoreRNG "hmath-rng-1 RawRNG ChaCha20 [0,0,0,0,0] []" of
                    Right r -> fst (R.nextWord64 r) == 0x903df1a0ade0b876
                    _ -> False
               )
           ,
               ( "Philox published zero vector"
               , fst (R.nextWord64 (R.seedRNG R.Philox4x32 0)) == 0xe169c58d6627e8d5
               )
           ,
               ( "Threefry published zero vector"
               , fst (R.nextWord64 (R.seedRNG R.Threefry2x64 0)) == 0xc2b6e3a8c2c69865
               )
           , ("MT19937 published seed5489", fst (R.nextWord64 (R.seedRNG R.MT19937 5489)) == 0xd091bb5c22ae9ef6)
           ,
               ( "invalid random serialization"
               , isLeft (R.restoreRNG "hmath-rng-1 RawRNG Xoshiro256StarStar [0,0,0,0] []")
               )
           ,
               ( "uniform integer full range"
               , case R.uniformInt minBound maxBound rng of Right _ -> True; _ -> False
               )
           ,
               ( "uniform integers inclusive singleton"
               , case R.uniformInt 4 4 rng of Right (x, _) -> x == 4; _ -> False
               )
           , ("uniform invalid bounds", isLeft (R.uniformInt 2 1 rng))
           , ("Box-Muller seeded distribution", normalQuality (Right . R.boxMuller))
           , ("Marsaglia seeded distribution", normalQuality R.marsagliaNormal)
           , ("Ziggurat seeded distribution", normalQuality R.zigguratNormal)
           , ("gamma seeded mean", sampleMean 2.0 0.15 (R.gamma 2 1))
           ,
               ( "small-shape gamma support"
               , case R.sampleN 100 (R.gamma 0.5 2) rng of Right (xs, _) -> all (>= 0) xs; _ -> False
               )
           , ("beta seeded mean", sampleMean 0.4 0.04 (R.beta 2 3))
           ,
               ( "Poisson seeded mean"
               , sampleMean 4 0.3 (\r -> do (x, s) <- R.poisson 4 r; pure (fromIntegral x, s))
               )
           ,
               ( "binomial seeded mean"
               , sampleMean 3 0.2 (\r -> do (x, s) <- R.binomial 10 0.3 r; pure (fromIntegral x, s))
               )
           ,
               ( "alias zero-weight support"
               , case R.aliasTable [0, 1, 0] >>= \a -> R.sampleN 200 (R.aliasSample a) rng of
                    Right (xs, _) -> all (== 1) xs
                    _ -> False
               )
           ,
               ( "alias frequencies"
               , case R.aliasTable [1, 2, 7] >>= \a -> R.sampleN 2000 (R.aliasSample a) rng of
                    Right (xs, _) -> abs (fromIntegral (length (filter (== 2) xs)) / 2000 - 0.7) < (0.04 :: Double)
                    _ -> False
               )
           , ("weighted zero total rejected", isLeft (R.weighted [0, 0] rng))
           , ("weighted NaN rejected", isLeft (R.weighted [1, 0 / 0] rng))
           ,
               ( "Fisher-Yates permutation"
               , case R.shuffle [1 .. 30 :: Int] rng of Right (xs, _) -> sort xs == [1 .. 30]; _ -> False
               )
           ,
               ( "reservoir unique"
               , case R.reservoir 10 [1 .. 100 :: Int] rng of
                    Right (xs, _) -> length xs == 10 && length (nub xs) == 10
                    _ -> False
               )
           ,
               ( "without replacement unique"
               , case R.withoutReplacement 10 [1 .. 100 :: Int] rng of
                    Right (xs, _) -> length (nub xs) == 10
                    _ -> False
               )
           ,
               ( "replacement sample size"
               , case R.withReplacement 100 [1, 2 :: Int] rng of
                    Right (xs, _) -> length xs == 100 && all (`elem` [1, 2]) xs
                    _ -> False
               )
           ,
               ( "strata membership"
               , case R.stratified 20 rng of
                    Right (xs, _) -> and [x >= fromIntegral i / 20 && x < fromIntegral (i + 1) / 20 | (i, x) <- zip [0 :: Int ..] xs]
                    _ -> False
               )
           , ("importance normalization", near 1e-12 (R.importance [1, 3] [1, 3]) 2.5)
           , ("inverse sampling", sampleMean 0.5 0.04 (R.inverseTransform Right))
           ,
               ( "rejection sampling support"
               , case R.sampleN 100 (R.rejection 100 (\x -> x) (Right . R.uniform)) rng of
                    Right (xs, _) -> all (\x -> x >= 0 && x <= 1) xs
                    _ -> False
               )
           ,
               ( "Metropolis mean"
               , case R.metropolisHastings 4000 1 (\x -> -x * x / 2) 0 rng of
                    Right (xs, _) -> abs (sum (drop 1000 xs) / 3000) < 0.2
                    _ -> False
               )
           ,
               ( "Gibbs coordinate conditionals"
               , case R.gibbs 100 [\_ -> R.normal 0 1, \_ -> R.normal 1 1] [0, 0] rng of
                    Right (xs, _) -> length xs == 100 && all ((== 2) . length) xs
                    _ -> False
               )
           ,
               ( "HMC energy/metropolis chain"
               , case R.hamiltonianMonteCarlo 1000 10 0.1 (\x -> -sum (map (\z -> z * z) x) / 2) (map negate) [0] rng of
                    Right (xs, _) -> abs (sum (map (!! 0) xs) / 1000) < 0.2
                    _ -> False
               )
           ,
               ( "MC standard error"
               , case R.monteCarlo (\x -> x * x) 2000 rng of
                    Right ((m, se), _) -> abs (m - 1 / 3) < 4 * se && se > 0
                    _ -> False
               )
           , ("Halton reference", R.halton 3 1 == Right [0.5, 1 / 3, 0.2])
           ,
               ( "Sobol first reference"
               , R.sobol 3 1 == Right [0.5, 0.5, 0.5] && R.sobol 3 2 == Right [0.75, 0.25, 0.25]
               )
           , ("Faure base2 reference", R.faure 2 1 == Right [0.5, 0.5] && R.faure 2 2 == Right [0.25, 0.75])
           ,
               ( "Latin hypercube projections"
               , case R.latinHypercube 20 3 rng of
                    Right (xs, _) -> all (\j -> sort [floor ((row !! j) * 20) :: Int | row <- xs] == [0 .. 19]) [0 .. 2]
                    _ -> False
               )
           , ("gamma invalid domain", isLeft (S.gamma 0) && isLeft (S.gammaP 0 1))
           , ("beta invalid domain", isLeft (S.betaI 1 2 2))
           , ("special invalid nonfinite", isLeft (S.erf (0 / 0)) && isLeft (S.airy (1 / 0)))
           , ("hypergeometric denominator pole", isLeft (S.hypergeometric1F1 1 0 1))
           , ("Wigner selection zero", S.wigner3j 2 2 2 2 2 2 == Right 0)
           , ("Lambert invalid branch", isLeft (S.lambertW 1 0.1))
           ,
               ( "scaled Bessel avoids overflow"
               , case S.scaledBesselI 0 1000 of Right s -> S.sfValue s > 0 && S.sfValue s < 0.1; _ -> False
               )
           ,
               ( "Coulomb estimate contains independent value"
               , case S.coulombWave 0 1 2 of
                    Right (_, s) -> abs (S.sfValue s - 1.2757787847682766) < S.sfError s
                    _ -> False
               )
           , ("Hankel real/imag", case S.hankel 1 0 1 of Right z -> show z /= ""; _ -> False)
           ,
               ( "spherical harmonic Y00"
               , case S.sphericalHarmonic 0 0 1 1 of
                    Right z -> abs (realPart z - 1 / sqrt (4 * pi)) < 1e-12
                    _ -> False
               )
           , ("discrete noninteger mass zero", P.density (P.Poisson 3) 0.5 == Right 0)
           ,
               ( "CDF tails sum to one"
               , near 1e-14 ((+) <$> P.cdf (P.Normal 0 1) 6 <*> P.survival (P.Normal 0 1) 6) 1
               )
           , ("normal survival 10 sigma", near 1e-36 (P.survival (P.Normal 0 1) 10) 7.61985302416047e-24)
           , ("beta tail direct", near 1e-25 (P.survival (P.Beta 2 3) (1 - 1e-7)) 3.999999393683783e-21)
           , ("categorical mass", P.density (P.Categorical [0.2, 0.8]) 1 == Right 0.8)
           ,
               ( "mixture density"
               , near
                    1e-12
                    (P.density (P.Mixture [(0.5, P.Normal 0 1), (0.5, P.Normal 2 1)]) 1)
                    (exp (-0.5) / sqrt (2 * pi))
               )
           , ("empirical real expectation", near 1e-12 (P.expectation (P.Empirical [0.1, 0.2]) id) 0.15)
           , ("empirical duplicates", near 1e-12 (P.density (P.Empirical [1, 1, 2]) 1) (2 / 3))
           , ("Gaussian KDE mean", near 1e-12 (fst <$> P.moments (P.GaussianKDE 0.5 [1, 2, 3])) 2)
           , ("multinomial mass", near 1e-12 (P.multinomialPMF [0.2, 0.3, 0.5] [1, 1, 2]) 0.18)
           , ("Dirichlet uniform simplex", near 1e-12 (P.dirichletDensity [1, 1, 1] [0.2, 0.3, 0.5]) 2)
           ,
               ( "multivariate Normal identity"
               , near
                    1e-12
                    (do m <- fromListChecked 2 2 [1, 0, 0, 1]; P.multivariateNormalLogDensity [0, 0] m [0, 0])
                    (-log (2 * pi))
               )
           ,
               ( "Wishart one-dimensional chi-square"
               , near
                    1e-12
                    (do m <- fromListChecked 1 1 [1]; x <- fromListChecked 1 1 [2]; P.wishartLogDensity 3 m x)
                    (-1.5723649429247)
               )
           ,
               ( "Wishart sampler shape"
               , case do m <- fromListChecked 2 2 [1, 0, 0, 1]; P.sampleWishart 3 m rng of
                    Right _ -> True
                    _ -> False
               )
           , ("normal fitting", P.fitNormal [1, 2, 3] == Right (P.Normal 2 (sqrt (2 / 3))))
           , ("MLE grid", P.fitMLEGrid [P.Bernoulli 0.2, P.Bernoulli 0.8] [1, 1, 0] == Right (P.Bernoulli 0.8))
           ,
               ( "MAP grid prior"
               , P.fitMAPGrid [P.Bernoulli 0.2, P.Bernoulli 0.8] [1] (\d -> if d == P.Bernoulli 0.2 then 10 else 0)
                    == Right (P.Bernoulli 0.2)
               )
           , ("Beta Bernoulli update", P.betaBernoulliUpdate 1 1 [True, False, True] == Right (3, 2))
           , ("Gamma Poisson update", P.gammaPoissonUpdate 2 3 [1, 2, 3] == Right (8, 6))
           , ("Gaussian conjugate update", P.normalNormalUpdate 0 1 1 [2] == Right (1, 0.5))
           , ("Bayes exact posterior", P.bayes [0.5, 0.5] [0.2, 0.8] == Right [0.2, 0.8])
           , ("conditional probability", P.conditionalProbability 0.2 0.5 == Right 0.4)
           ,
               ( "stationary distribution"
               , case P.markov [[0.9, 0.1], [0.2, 0.8]] >>= P.stationary 1000 1e-12 of
                    Right ps -> abs (ps !! 0 - 2 / 3) < 1e-10
                    _ -> False
               )
           ,
               ( "periodic chain stationary"
               , (P.markov [[0, 1], [1, 0]] >>= P.stationary 100 1e-12) == Right [0.5, 0.5]
               )
           ,
               ( "HMM likelihood independently enumerated"
               , near 1e-12 (do h <- testHMM; (l, _, _) <- P.forward h [0, 1, 0]; pure (exp l)) 0.069616
               )
           ,
               ( "HMM posterior normalized"
               , case testHMM >>= \h -> P.posteriorStates h [0, 1, 0] of
                    Right ps -> all (\row -> abs (sum row - 1) < 1e-12) ps
                    _ -> False
               )
           ,
               ( "HMM Viterbi"
               , case testHMM >>= \h -> P.viterbi h [0, 1, 0] of Right (path, _) -> path == [0, 0, 0]; _ -> False
               )
           ,
               ( "Baum-Welch likelihood monotone"
               , case do
                    h <- testHMM
                    (l, _, _) <- P.forward h [0, 1, 0, 1, 1, 0]
                    h2 <- P.baumWelch 3 0 h [0, 1, 0, 1, 1, 0]
                    (l2, _, _) <- P.forward h2 [0, 1, 0, 1, 1, 0]
                    pure (l2 >= l - 1e-10) of
                    Right b -> b
                    _ -> False
               )
           ,
               ( "HMM scaled long sequence"
               , case testHMM >>= \h -> P.forward h (take 2000 (cycle [0, 1])) of
                    Right (l, _, _) -> not (isInfinite l)
                    _ -> False
               )
           , ("empty advanced data rejected", isLeft (A.arithmeticMean []) && isLeft (A.sampleVariance [1]))
           , ("extreme mean avoids sum overflow", near 1e-15 (A.arithmeticMean [1e308, 1e308]) 1e308)
           , ("extreme RMS avoids squaring overflow", near 1e-15 (A.rms [1e308, 1e308]) 1e308)
           , ("constant correlation rejected", isLeft (A.correlation [1, 1] [2, 3]))
           , ("modes ties", A.modes [1, 1, 2, 2, 3] == Right [1, 2])
           , ("IQR", near 1e-12 (A.interquartileRange [1, 2, 3, 4]) 1.5)
           , ("percentile", near 1e-12 (A.percentile 75 [1, 2, 3, 4]) 3.25)
           , ("population SD", near 1e-12 (A.populationSD [1, 2, 3, 4]) (sqrt 1.25))
           , ("CV", near 1e-12 (A.coefficientOfVariation [1, 2, 3, 4]) (sqrt 1.25 / 2.5))
           , ("central moment order0", A.centralMoment 0 [1, 2, 3] == Right 1)
           , ("covariance matrix", A.covarianceMatrix True [[1, 2, 3], [2, 4, 6]] == Right [[1, 2], [2, 4]])
           , ("Pearson correlation", near 1e-12 (A.correlation [1, 2, 3] [2, 4, 6]) 1)
           ,
               ( "partial correlation"
               , near
                    1e-12
                    (A.partialCorrelation [[1, 2, 3, 4, 5], [2, 1, 4, 3, 6], [1, 1, 0, 0, 2]] 0 1)
                    0.8207242791832111
               )
           , ("autocorrelation lag", near 1e-12 (A.autocorrelation 1 [1, 2, 3, 4]) 1)
           , ("cross correlation", near 1e-12 (A.crossCorrelation 1 [1, 2, 3, 4] [2, 4, 6, 8]) 1)
           , ("moving mean", A.movingAverage 2 [1, 2, 3] == Right [1.5, 2.5])
           , ("moving variance", A.movingVariance 2 [1, 2, 3] == Right [0.25, 0.25])
           , ("EMA", A.exponentialMovingAverage 0.5 [1, 2, 3] == Right [1, 1.5, 2.25])
           ,
               ( "streaming Welford matches batch"
               , near 1e-12 (do s <- foldUpdates [1, 2, 3, 4]; (_, _, v) <- A.streamingResult True s; pure v) (5 / 3)
               )
           ,
               ( "parallel Welford matches batch"
               , near
                    1e-12
                    ( do
                        a <- foldUpdates [1, 2]
                        b <- foldUpdates [3, 4]
                        s <- A.combineStreaming a b
                        (_, _, v) <- A.streamingResult True s
                        pure v
                    )
                    (5 / 3)
               )
           ,
               ( "weighted 2D histogram"
               , A.histogramND [[0, 1, 2], [0, 1, 2]] [[0.2, 0.2], [1.5, 0.2], [2, 2]] [1, 2, 3]
                    == Right [1, 0, 2, 3]
               )
           , ("mutual information diagonal", near 1e-12 (A.mutualInformation [[0.5, 0], [0, 0.5]]) (log 2))
           , ("JS disjoint bounded", near 1e-12 (A.jsDivergence [1, 0] [0, 1]) (log 2))
           , ("masked ignores excluded NaN", A.masked [True, False, True] [1, 0 / 0, 3] == Right [1, 3])
           ,
               ( "Huber robust location"
               , case A.huberLocation 1.345 [0, 1, 2, 3, 100] of Right x -> x < 4; _ -> False
               )
           ,
               ( "Bonferroni"
               , case A.bonferroni [0.01, 0.2, 0.8] of
                    Right xs -> and (zipWith (\a b -> abs (a - b) < 1e-12) xs [0.03, 0.6, 1])
                    _ -> False
               )
           ,
               ( "BH monotone adjusted"
               , case A.benjaminiHochberg [0.01, 0.04, 0.03, 0.9] of
                    Right xs ->
                        and (zipWith (\a b -> abs (a - b) < 1e-12) xs [0.04, 0.05333333333333334, 0.05333333333333334, 0.9])
                    _ -> False
               )
           , ("Cohen d", near 1e-12 (A.cohensD [1, 2, 3] [3, 4, 5]) (-2))
           , ("eta squared", near 1e-12 (A.etaSquared [[1, 2, 3], [3, 4, 5]]) 0.6)
           , ("normal power at null equals alpha", near 1e-12 (A.normalTestPower 0.05 0 100) 0.05)
           ,
               ( "normal sample size meets target"
               , case A.normalSampleSize 0.05 0.8 0.5 of
                    Right n ->
                        ( case (A.normalTestPower 0.05 0.5 n, A.normalTestPower 0.05 0.5 (n - 1)) of
                            (Right p, Right before) -> p >= 0.8 && before < 0.8
                            _ -> False
                        )
                    _ -> False
               )
           , ("Tukey outlier indices", A.tukeyOutliers 1.5 [1, 2, 3, 4, 100] == Right [4])
           ,
               ( "Grubbs extreme"
               , case A.grubbs 0.05 [1, 2, 3, 4, 100] of Right (i, _, out) -> i == 4 && out; _ -> False
               )
           ,
               ( "bootstrap reproducible"
               , A.bootstrap 10 A.arithmeticMean [1, 2, 3] rng == A.bootstrap 10 A.arithmeticMean [1, 2, 3] rng
               )
           , ("jackknife sample mean", near 1e-12 (fst <$> A.jackknife A.arithmeticMean [1, 2, 3, 4]) 2.5)
           ,
               ( "confidence interval contains mean"
               , case A.confidenceInterval 0.95 [1, 2, 3, 4] of Right (a, b) -> a < 2.5 && b > 2.5; _ -> False
               )
           ,
               ( "permutation seeded p-value"
               , case A.permutationTest
                    199
                    (\x y -> (-) <$> A.arithmeticMean x <*> A.arithmeticMean y)
                    [1, 2, 3]
                    [10, 11, 12]
                    rng of
                    Right (t, _) -> A.pValue t < 0.2 && A.pValue t > 0
                    _ -> False
               )
           ]
        ++ [ ( "quantile CDF consistency " ++ show d
             , case P.quantile d 0.37 >>= P.cdf d of Right p -> abs (p - 0.37) < 1e-7; _ -> False
             )
           | d <-
                [ P.Normal 2 3
                , P.Gamma 2 3
                , P.Beta 2 3
                , P.StudentT 5
                , P.FisherF 4 8
                , P.Laplace 1 2
                , P.Logistic 1 2
                , P.Weibull 2 3
                , P.TruncatedNormal 0 1 (-1) 2
                ]
           ]
  where
    normalQuality :: (R.RNG -> Either MathError (Double, R.RNG)) -> Bool
    normalQuality f = case R.sampleN 2000 f rng of
        Right (xs, _) -> abs (sum xs / 2000) < 0.1 && abs (sum (map (\x -> x * x) xs) / 2000 - 1) < 0.15
        _ -> False
    sampleMean :: Double -> Double -> (R.RNG -> Either MathError (Double, R.RNG)) -> Bool
    sampleMean expected tolerance sampler = case R.sampleN 2000 sampler rng of
        Right (xs, _) -> abs (sum xs / 2000 - expected) < tolerance
        _ -> False
foldUpdates :: [Double] -> Either MathError A.Streaming
foldUpdates = Foldable.foldl' (\acc x -> acc >>= \s -> A.updateStreaming s x) (Right A.emptyStreaming)
testHMM :: Either MathError P.HMM
testHMM = P.hmm [0.6, 0.4] [[0.7, 0.3], [0.4, 0.6]] [[0.5, 0.5], [0.1, 0.9]]
probabilityBatchIOTests :: IO [(String, Bool)]
probabilityBatchIOTests = do
    a <- R.entropySeed
    b <- R.entropySeed
    pure
        [
            ( "OS entropy has full Word64 representation"
            , length (show (a :: Word64)) > 0 && length (show b) > 0
            )
        ]

additionalTests :: [(String, Bool)]
additionalTests =
    [
        ( "z-test reference"
        , near 1e-18 (A.pValue <$> A.zTest 3 2 [1, 2, 3, 5, 8, 13, 21]) 1.4717314479880334e-9
        )
    ,
        ( "chi-square reference"
        , near 1e-12 (A.pValue <$> A.chiSquareTest 0 [10, 20, 30] [20, 20, 20]) 0.006737946999085468
        )
    ,
        ( "F variance ratio reference"
        , near
            1e-9
            (A.pValue <$> A.varianceFTest [1, 2, 3, 5, 8, 13, 21] [2, 3, 4, 6, 7, 9, 12])
            0.1063092868327276
        )
    ,
        ( "Welch ANOVA reference"
        , near
            1e-9
            (A.pValue <$> A.welchAnova [[1, 2, 3, 5, 8, 13, 21], [2, 3, 4, 6, 7, 9, 12], [3, 4, 5, 8, 9]])
            0.8467262343373859
        )
    ,
        ( "Anderson-Darling reference"
        , near 1e-9 (A.testStatistic <$> A.andersonDarling [1, 2, 3, 5, 8, 13, 21]) 0.42330650218043964
        )
    , ("KS rejects invalid data", isLeft (A.kolmogorovSmirnov (P.Normal 0 1) []))
    , ("all masked rejected", isLeft (A.masked [False] [0 / 0]))
    , ("negative histogram weight rejected", isLeft (A.histogramND [[0, 1]] [[0.5]] [-1]))
    , ("streaming insufficient sample", isLeft (A.streamingResult True A.emptyStreaming))
    , ("negative weights rejected", isLeft (A.weightedMean [1, 2] [1, -1]))
    ,
        ( "NaN statistics rejected"
        , isLeft (A.arithmeticMean [1, 0 / 0]) && isLeft (A.quantile 0.5 [1, 1 / 0])
        )
    , ("invalid confidence level", isLeft (A.confidenceInterval 1 [1, 2, 3]))
    , ("test insufficient degrees", isLeft (A.chiSquareTest 2 [1, 2, 3] [2, 2, 2]))
    , ("invalid covariance inverse", isLeft (A.partialCorrelation [[1, 2, 3], [2, 4, 6]] 0 1))
    , ("fitted normal constant rejected", isLeft (P.fitNormal [1, 1, 1]))
    , ("Markov bad row sum", isLeft (P.markov [[0.5, 0.4], [0, 1]]))
    ,
        ( "HMM impossible observation"
        , case P.hmm [1] [[1]] [[1, 0]] of Right h -> isLeft (P.forward h [1]); _ -> False
        )
    , ("HMM bad symbol rejected", case testHMM of Right h -> isLeft (P.forward h [-1]); _ -> False)
    ,
        ( "Beta endpoint conventions"
        , P.density (P.Beta 1 1) 0 == Right 1 && P.density (P.Beta 1 1) 1 == Right 1
        )
    , ("Pareto endpoint support", P.quantile (P.Pareto 2 3) 0 == Right 2)
    , ("GEV finite endpoint support", P.quantile (P.GeneralizedExtremeValue 1 2 (-0.5)) 1 == Right 5)
    ,
        ( "probability invalid parameters"
        , all
            isLeft
            [ P.validateDistribution (P.Gamma 0 1)
            , P.validateDistribution (P.Normal 0 0)
            , P.validateDistribution (P.Categorical [0.2, 0.2])
            ]
        )
    ,
        ( "CDF monotonicity grid"
        , case mapM (P.cdf (P.Gamma 2 3)) [0 .. 20] of
            Right ps -> and (zipWith (<=) ps (drop 1 ps))
            _ -> False
        )
    ,
        ( "Poisson CDF survival complement"
        , near 1e-12 ((+) <$> P.cdf (P.Poisson 100) 120 <*> P.survival (P.Poisson 100) 120) 1
        )
    ,
        ( "special error estimates nonnegative"
        , case mapM (S.besselK 2) [0.1, 1, 10, 100] of Right xs -> all ((>= 0) . S.sfError) xs; _ -> False
        )
    , ("Clausen zero limit", S.clausen 0 == Right (S.SFResult 0 0))
    , ("Bose positive eta rejected", isLeft (S.boseEinstein 1 1))
    , ("polygamma order range", isLeft (S.polygamma 33 1))
    , ("elliptic branch invalid", isLeft (S.ellipticF 1 2))
    , ("Mathieu q0 cosine", near 1e-10 (S.sfValue . snd <$> S.mathieu True 3 0 0.2) (cos 0.6))
    ,
        ( "Mathieu q0 sine normalized"
        , near 1e-10 (S.sfValue . snd <$> S.mathieu False 3 0 0.2) (sin 0.6 / 3)
        )
    , ("Legendre Condon-Shortley phase", near 1e-12 (S.associatedLegendre 1 1 0) (-1))
    ,
        ( "Bernoulli reflection identity"
        , near 1e-10 ((-) <$> S.bernoulliPolynomial 5 0.3 <*> (negate <$> S.bernoulliPolynomial 5 0.7)) 0
        )
    ,
        ( "gamma reflection identity"
        , near 1e-10 ((*) <$> S.gamma 0.3 <*> S.gamma 0.7) (pi / sin (0.3 * pi))
        )
    , ("incomplete gamma normalization", near 1e-12 ((+) <$> S.gammaP 3 4 <*> S.gammaQ 3 4) 1)
    , ("error inverse identity", near 1e-12 (S.inverseErf 0.7 >>= S.erf) 0.7)
    ,
        ( "Bessel recurrence"
        , near 1e-12 (do a <- S.besselJ 0 2; b <- S.besselJ 1 2; c <- S.besselJ 2 2; pure (a + c - b)) 0
        )
    , ("parabolic cylinder D0", near 1e-12 (S.sfValue <$> S.parabolicCylinder 0 2) (exp (-1)))
    , ("Euler E0", S.eulerPolynomial 0 2 == Right 1)
    , ("Wigner half-integer normalization", near 1e-12 (S.wigner3j 1 1 0 1 (-1) 0) (1 / sqrt 2))
    , ("rejection budget exhausted", isLeft (R.rejection 2 (const 0) (Right . R.uniform) rng))
    , ("random shape invalid", isLeft (R.gamma 0 1 rng) && isLeft (R.normal 0 0 rng))
    , ("sample count invalid", isLeft (R.sampleN (-1) (Right . R.uniform) rng))
    ,
        ( "HMC gradient dimensions rejected"
        , isLeft (R.hamiltonianMonteCarlo 1 1 0.1 (const 0) (const []) [0] rng)
        )
    , ("Sobol domain invalid", isLeft (R.sobol 9 0))
    ,
        ( "Faure large-index finite"
        , case R.faure 2 maxBound of Right xs -> all (\x -> x >= 0 && x < 1) xs; _ -> False
        )
    ]

coulombReferenceTests :: [(String, Bool)]
coulombReferenceTests =
    [
        ( "Coulomb estimated error l=0 eta=-3 rho=0.5"
        , case S.coulombWave 0 (-3) 0.5 of
            Right (a, b) ->
                abs (S.sfValue a - (0.163606944013866)) <= max 1e-10 (2 * S.sfError a)
                    && abs (S.sfValue b - (-0.5083350687767878)) <= 2 * S.sfError b
            _ -> False
        )
    ,
        ( "Coulomb estimated error l=0 eta=1 rho=8"
        , case S.coulombWave 0 (1) 8 of
            Right (a, b) ->
                abs (S.sfValue a - (-1.0333103289676093)) <= max 1e-10 (2 * S.sfError a)
                    && abs (S.sfValue b - (0.29114260123785396)) <= 2 * S.sfError b
            _ -> False
        )
    ,
        ( "Coulomb estimated error l=0 eta=3 rho=30"
        , case S.coulombWave 0 (3) 30 of
            Right (a, b) ->
                abs (S.sfValue a - (0.08219823341393209)) <= max 1e-10 (2 * S.sfError a)
                    && abs (S.sfValue b - (1.0541185635686068)) <= 2 * S.sfError b
            _ -> False
        )
    ,
        ( "Coulomb estimated error l=1 eta=0 rho=0.5"
        , case S.coulombWave 1 (0) 0.5 of
            Right (a, b) ->
                abs (S.sfValue a - (0.08126851531803328)) <= max 1e-10 (2 * S.sfError a)
                    && abs (S.sfValue b - (2.2345906623849485)) <= 2 * S.sfError b
            _ -> False
        )
    ,
        ( "Coulomb estimated error l=1 eta=1 rho=2"
        , case S.coulombWave 1 (1) 2 of
            Right (a, b) ->
                abs (S.sfValue a - (0.3614128577450535)) <= max 1e-10 (2 * S.sfError a)
                    && abs (S.sfValue b - (1.7652192403391795)) <= 2 * S.sfError b
            _ -> False
        )
    ,
        ( "Coulomb estimated error l=3 eta=-1 rho=0.5"
        , case S.coulombWave 3 (-1) 0.5 of
            Right (a, b) ->
                abs (S.sfValue a - (0.0021638236060038335)) <= max 1e-10 (2 * S.sfError a)
                    && abs (S.sfValue b - (34.92927216895851)) <= 2 * S.sfError b
            _ -> False
        )
    ,
        ( "Coulomb estimated error l=3 eta=1 rho=8"
        , case S.coulombWave 3 (1) 8 of
            Right (a, b) ->
                abs (S.sfValue a - (0.5387914365263475)) <= max 1e-10 (2 * S.sfError a)
                    && abs (S.sfValue b - (-1.0137227036155914)) <= 2 * S.sfError b
            _ -> False
        )
    ,
        ( "Coulomb estimated error l=8 eta=-3 rho=0.5"
        , case S.coulombWave 8 (-3) 0.5 of
            Right (a, b) ->
                abs (S.sfValue a - (3.1568736393919157e-09)) <= max 1e-10 (2 * S.sfError a)
                    && abs (S.sfValue b - (9534695.669579098)) <= 2 * S.sfError b
            _ -> False
        )
    ,
        ( "Coulomb estimated error l=8 eta=3 rho=0.5"
        , case S.coulombWave 8 (3) 0.5 of
            Right (a, b) ->
                abs (S.sfValue a - (3.556015178186733e-13)) <= max 1e-10 (2 * S.sfError a)
                    && abs (S.sfValue b - (81175976505.90977)) <= 2 * S.sfError b
            _ -> False
        )
    ,
        ( "Coulomb estimated error l=8 eta=1 rho=30"
        , case S.coulombWave 8 (1) 30 of
            Right (a, b) ->
                abs (S.sfValue a - (-0.8862972074853213)) <= max 1e-10 (2 * S.sfError a)
                    && abs (S.sfValue b - (-0.5448560317077118)) <= 2 * S.sfError b
            _ -> False
        )
    ]

numericEdgeTests :: [(String, Bool)]
numericEdgeTests =
    [
        ( "subnormal weights never select zero"
        , case R.sampleN 100 (R.weighted [5e-324, 0]) rng of Right (xs, _) -> all (== 0) xs; _ -> False
        )
    ,
        ( "huge alias weights remain normalized"
        , case R.aliasTable [8e307, 6e307, 1e306] >>= \a -> R.sampleN 1000 (R.aliasSample a) rng of
            Right (xs, _) -> abs (fromIntegral (length (filter (== 0) xs)) / 1000 - 80 / 141) < (0.06 :: Double)
            _ -> False
        )
    , ("exponential overflow rejected", isLeft (R.exponential 5e-324 rng))
    ,
        ( "beta huge shapes stable ratio"
        , case R.beta 1e308 1e308 rng of Right (x, _) -> abs (x - 0.5) < 1e-12; _ -> False
        )
    ,
        ( "Poisson zero degenerate mass"
        , P.density (P.Poisson 0) 0 == Right 1 && P.cdf (P.Poisson 0) 0 == Right 1
        )
    , ("unrepresentable moments rejected", isLeft (P.moments (P.Normal 0 1e308)))
    ,
        ( "large normal entropy remains finite"
        , near 1e-12 (P.entropy (P.Normal 0 1e308)) (0.5 * log (2 * pi * exp 1) + log 1e308)
        )
    ,
        ( "extreme logistic log density defined"
        , case P.logDensity (P.Logistic (-1e308) 1e-300) 1e308 of Right x -> not (isNaN x); _ -> True
        )
    ,
        ( "Halton large-index stays open at one"
        , case R.halton 2 maxBound of Right xs -> all (\x -> x >= 0 && x < 1) xs; _ -> False
        )
    ]

oscillatoryRegressionTests :: [(String, Bool)]
oscillatoryRegressionTests =
    [
        ( "Fresnel 64 phase alias regression C"
        , near 1e-12 (S.sfValue . fst <$> S.fresnel 64) 0.49999961349039285
        )
    ,
        ( "Fresnel 64 phase alias regression S"
        , near 1e-12 (S.sfValue . snd <$> S.fresnel 64) 0.49502640811848797
        )
    ,
        ( "Ci256pi phase alias regression"
        , near 1e-12 (S.sfValue <$> S.cosineIntegral (256 * pi)) (-1.5460242278321214e-6)
        )
    ,
        ( "negative-axis li relative accuracy"
        , case S.logarithmicIntegral 1e-100 of
            Right a -> abs (S.sfValue a / (-4.3242453772020464e-103) - 1) < 1e-12
            _ -> False
        )
    ,
        ( "scaled K huge relative accuracy"
        , case S.scaledBesselK 0 1e100 of
            Right a -> abs (S.sfValue a / (sqrt (pi / 2) / 1e50) - 1) < 1e-12
            _ -> False
        )
    ,
        ( "scaled I huge relative accuracy"
        , case S.scaledBesselI 0 1e308 of
            Right a -> abs (S.sfValue a / (1 / (sqrt (2 * pi) * 1e154)) - 1) < 1e-12
            _ -> False
        )
    ,
        ( "scaled K tiny log expansion"
        , near 1e-12 (S.sfValue <$> S.scaledBesselK 0 1e-300) 690.8914594138721
        )
    , ("discrete CDF upper infinity-like finite query", P.cdf (P.DiscreteUniform 0 10) 1e308 == Right 1)
    ,
        ( "discrete CDF lower infinity-like finite query"
        , P.cdf (P.DiscreteUniform 0 10) (-1e308) == Right 0
        )
    , ("Skellam huge CDF saturates", P.cdf (P.Skellam 3 2) 1e308 == Right 1)
    , ("Skellam huge density checked budget", isLeft (P.logDensity (P.Skellam 3 2) 1e308))
    ]

specialTransitionTests :: [(String, Bool)]
specialTransitionTests =
    [
        ( "Fresnel transition 0.01"
        , case S.fresnel 0.01 of
            Right (c, ss) ->
                abs (S.sfValue c - (0.00999999997532599)) < 1e-9
                    && abs (S.sfValue ss - (5.235987746754932e-07)) < 1e-9
            _ -> False
        )
    ,
        ( "Fresnel transition 0.1"
        , case S.fresnel 0.1 of
            Right (c, ss) ->
                abs (S.sfValue c - (0.09999753262708506)) < 1e-9
                    && abs (S.sfValue ss - (0.0005235895476122108)) < 1e-9
            _ -> False
        )
    ,
        ( "Fresnel transition 1.0"
        , case S.fresnel 1.0 of
            Right (c, ss) ->
                abs (S.sfValue c - (0.779893400376823)) < 1e-9 && abs (S.sfValue ss - (0.4382591473903547)) < 1e-9
            _ -> False
        )
    ,
        ( "Fresnel transition 7.9"
        , case S.fresnel 7.9 of
            Right (c, ss) ->
                abs (S.sfValue c - (0.4759737938484119)) < 1e-9 && abs (S.sfValue ss - (0.5323420347477719)) < 1e-9
            _ -> False
        )
    ,
        ( "Fresnel transition 8.0"
        , case S.fresnel 8.0 of
            Right (c, ss) ->
                abs (S.sfValue c - (0.49980218037719715)) < 1e-9
                    && abs (S.sfValue ss - (0.46021421439301446)) < 1e-9
            _ -> False
        )
    ,
        ( "Fresnel transition 8.1"
        , case S.fresnel 8.1 of
            Right (c, ss) ->
                abs (S.sfValue c - (0.5227506125578562)) < 1e-9 && abs (S.sfValue ss - (0.5320393956415613)) < 1e-9
            _ -> False
        )
    ,
        ( "Fresnel transition 30.0"
        , case S.fresnel 30.0 of
            Right (c, ss) ->
                abs (S.sfValue c - (0.4999962473706099)) < 1e-9 && abs (S.sfValue ss - (0.4893896744421938)) < 1e-9
            _ -> False
        )
    ,
        ( "Fresnel transition 64.0"
        , case S.fresnel 64.0 of
            Right (c, ss) ->
                abs (S.sfValue c - (0.49999961349039285)) < 1e-9
                    && abs (S.sfValue ss - (0.49502640811848797)) < 1e-9
            _ -> False
        )
    ,
        ( "Fresnel transition 99.0"
        , case S.fresnel 99.0 of
            Right (c, ss) ->
                abs (S.sfValue c - (0.5032152513654198)) < 1e-9 && abs (S.sfValue ss - (0.4999998955773612)) < 1e-9
            _ -> False
        )
    ,
        ( "transition Si0.001"
        , case S.sineIntegral 0.001 of
            Right r ->
                abs (S.sfValue r - (0.0009999999444444462))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.0009999999444444462))
            _ -> False
        )
    ,
        ( "transition Ci0.001"
        , case S.cosineIntegral 0.001 of
            Right r ->
                abs (S.sfValue r - (-6.330539864080594)) <= max (5 * S.sfError r) (1e-08 * abs (-6.330539864080594))
            _ -> False
        )
    ,
        ( "transition Si1.0"
        , case S.sineIntegral 1.0 of
            Right r ->
                abs (S.sfValue r - (0.9460830703671831)) <= max (5 * S.sfError r) (1e-08 * abs (0.9460830703671831))
            _ -> False
        )
    ,
        ( "transition Ci1.0"
        , case S.cosineIntegral 1.0 of
            Right r ->
                abs (S.sfValue r - (0.33740392290096816))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.33740392290096816))
            _ -> False
        )
    ,
        ( "transition Si49.0"
        , case S.sineIntegral 49.0 of
            Right r ->
                abs (S.sfValue r - (1.5650631167362712)) <= max (5 * S.sfError r) (1e-08 * abs (1.5650631167362712))
            _ -> False
        )
    ,
        ( "transition Ci49.0"
        , case S.cosineIntegral 49.0 of
            Right r ->
                abs (S.sfValue r - (-0.0195730908028717))
                    <= max (5 * S.sfError r) (1e-08 * abs (-0.0195730908028717))
            _ -> False
        )
    ,
        ( "transition Si50.0"
        , case S.sineIntegral 50.0 of
            Right r ->
                abs (S.sfValue r - (1.551617072485936)) <= max (5 * S.sfError r) (1e-08 * abs (1.551617072485936))
            _ -> False
        )
    ,
        ( "transition Ci50.0"
        , case S.cosineIntegral 50.0 of
            Right r ->
                abs (S.sfValue r - (-0.005628386324116305))
                    <= max (5 * S.sfError r) (1e-08 * abs (-0.005628386324116305))
            _ -> False
        )
    ,
        ( "transition Si50.1"
        , case S.sineIntegral 50.1 of
            Right r ->
                abs (S.sfValue r - (1.5511900075409872)) <= max (5 * S.sfError r) (1e-08 * abs (1.5511900075409872))
            _ -> False
        )
    ,
        ( "transition Ci50.1"
        , case S.cosineIntegral 50.1 of
            Right r ->
                abs (S.sfValue r - (-0.0036774110288103))
                    <= max (5 * S.sfError r) (1e-08 * abs (-0.0036774110288103))
            _ -> False
        )
    ,
        ( "transition Si100.0"
        , case S.sineIntegral 100.0 of
            Right r ->
                abs (S.sfValue r - (1.5622254668890563)) <= max (5 * S.sfError r) (1e-08 * abs (1.5622254668890563))
            _ -> False
        )
    ,
        ( "transition Ci100.0"
        , case S.cosineIntegral 100.0 of
            Right r ->
                abs (S.sfValue r - (-0.005148825142610493))
                    <= max (5 * S.sfError r) (1e-08 * abs (-0.005148825142610493))
            _ -> False
        )
    ,
        ( "transition Si800.0"
        , case S.sineIntegral 800.0 of
            Right r ->
                abs (S.sfValue r - (1.5713550876214726)) <= max (5 * S.sfError r) (1e-08 * abs (1.5713550876214726))
            _ -> False
        )
    ,
        ( "transition Ci800.0"
        , case S.cosineIntegral 800.0 of
            Right r ->
                abs (S.sfValue r - (0.0011181587609180512))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.0011181587609180512))
            _ -> False
        )
    ,
        ( "transition li1e-100"
        , case S.logarithmicIntegral 1e-100 of
            Right r ->
                abs (S.sfValue r - (-4.324245377202095e-103))
                    <= max (5 * S.sfError r) (1e-08 * abs (-4.324245377202095e-103))
            _ -> False
        )
    ,
        ( "transition li1e-10"
        , case S.logarithmicIntegral 1e-10 of
            Right r ->
                abs (S.sfValue r - (-4.168887750019648e-12))
                    <= max (5 * S.sfError r) (1e-08 * abs (-4.168887750019648e-12))
            _ -> False
        )
    ,
        ( "transition li0.01"
        , case S.logarithmicIntegral 0.01 of
            Right r ->
                abs (S.sfValue r - (-0.0018297434996255157))
                    <= max (5 * S.sfError r) (1e-08 * abs (-0.0018297434996255157))
            _ -> False
        )
    ,
        ( "transition li0.99"
        , case S.logarithmicIntegral 0.99 of
            Right r ->
                abs (S.sfValue r - (-4.032958701708463)) <= max (5 * S.sfError r) (1e-08 * abs (-4.032958701708463))
            _ -> False
        )
    ,
        ( "transition li1.01"
        , case S.logarithmicIntegral 1.01 of
            Right r ->
                abs (S.sfValue r - (-4.022958673929935)) <= max (5 * S.sfError r) (1e-08 * abs (-4.022958673929935))
            _ -> False
        )
    ,
        ( "transition li2.0"
        , case S.logarithmicIntegral 2.0 of
            Right r ->
                abs (S.sfValue r - (1.045163780117493)) <= max (5 * S.sfError r) (1e-08 * abs (1.045163780117493))
            _ -> False
        )
    ,
        ( "transition li1e+50"
        , case S.logarithmicIntegral 1e+50 of
            Right r ->
                abs (S.sfValue r - (8.762680317507843e+47))
                    <= max (5 * S.sfError r) (1e-08 * abs (8.762680317507843e+47))
            _ -> False
        )
    ,
        ( "transition scaledK0x1e-06"
        , case S.scaledBesselK 0 1e-06 of
            Right r ->
                abs (S.sfValue r - (13.931456005075455)) <= max (5 * S.sfError r) (1e-07 * abs (13.931456005075455))
            _ -> False
        )
    ,
        ( "transition scaledK0x0.01"
        , case S.scaledBesselK 0 0.01 of
            Right r ->
                abs (S.sfValue r - (4.768694028544461)) <= max (5 * S.sfError r) (1e-07 * abs (4.768694028544461))
            _ -> False
        )
    ,
        ( "transition scaledK0x1.0"
        , case S.scaledBesselK 0 1.0 of
            Right r ->
                abs (S.sfValue r - (1.1444630798068949)) <= max (5 * S.sfError r) (1e-07 * abs (1.1444630798068949))
            _ -> False
        )
    ,
        ( "transition scaledK0x49.0"
        , case S.scaledBesselK 0 49.0 of
            Right r ->
                abs (S.sfValue r - (0.1785932647776389)) <= max (5 * S.sfError r) (1e-07 * abs (0.1785932647776389))
            _ -> False
        )
    ,
        ( "transition scaledK0x51.0"
        , case S.scaledBesselK 0 51.0 of
            Right r ->
                abs (S.sfValue r - (0.1750735878842671)) <= max (5 * S.sfError r) (1e-07 * abs (0.1750735878842671))
            _ -> False
        )
    ,
        ( "transition scaledK0x1000.0"
        , case S.scaledBesselK 0 1000.0 of
            Right r ->
                abs (S.sfValue r - (0.03962832160075422))
                    <= max (5 * S.sfError r) (1e-07 * abs (0.03962832160075422))
            _ -> False
        )
    ,
        ( "transition scaledK1x1e-06"
        , case S.scaledBesselK 1 1e-06 of
            Right r ->
                abs (S.sfValue r - (1000000.9999932843)) <= max (5 * S.sfError r) (1e-07 * abs (1000000.9999932843))
            _ -> False
        )
    ,
        ( "transition scaledK1x0.01"
        , case S.scaledBesselK 1 0.01 of
            Right r ->
                abs (S.sfValue r - (100.97864845824003)) <= max (5 * S.sfError r) (1e-07 * abs (100.97864845824003))
            _ -> False
        )
    ,
        ( "transition scaledK1x1.0"
        , case S.scaledBesselK 1 1.0 of
            Right r ->
                abs (S.sfValue r - (1.636153486263258)) <= max (5 * S.sfError r) (1e-07 * abs (1.636153486263258))
            _ -> False
        )
    ,
        ( "transition scaledK1x49.0"
        , case S.scaledBesselK 1 49.0 of
            Right r ->
                abs (S.sfValue r - (0.18040653111759933))
                    <= max (5 * S.sfError r) (1e-07 * abs (0.18040653111759933))
            _ -> False
        )
    ,
        ( "transition scaledK1x51.0"
        , case S.scaledBesselK 1 51.0 of
            Right r ->
                abs (S.sfValue r - (0.176781741962918)) <= max (5 * S.sfError r) (1e-07 * abs (0.176781741962918))
            _ -> False
        )
    ,
        ( "transition scaledK1x1000.0"
        , case S.scaledBesselK 1 1000.0 of
            Right r ->
                abs (S.sfValue r - (0.03964813081296021))
                    <= max (5 * S.sfError r) (1e-07 * abs (0.03964813081296021))
            _ -> False
        )
    ,
        ( "transition scaledK10x1e-06"
        , case S.scaledBesselK 10 1e-06 of
            Right r ->
                abs (S.sfValue r - (1.857947457946477e+68))
                    <= max (5 * S.sfError r) (1e-07 * abs (1.857947457946477e+68))
            _ -> False
        )
    ,
        ( "transition scaledK10x0.01"
        , case S.scaledBesselK 10 0.01 of
            Right r ->
                abs (S.sfValue r - (1.8766130508929294e+28))
                    <= max (5 * S.sfError r) (1e-07 * abs (1.8766130508929294e+28))
            _ -> False
        )
    ,
        ( "transition scaledK10x1.0"
        , case S.scaledBesselK 10 1.0 of
            Right r ->
                abs (S.sfValue r - (491229652.0990197)) <= max (5 * S.sfError r) (1e-07 * abs (491229652.0990197))
            _ -> False
        )
    ,
        ( "transition scaledK10x49.0"
        , case S.scaledBesselK 10 49.0 of
            Right r ->
                abs (S.sfValue r - (0.4888379966367168)) <= max (5 * S.sfError r) (1e-07 * abs (0.4888379966367168))
            _ -> False
        )
    ,
        ( "transition scaledK10x51.0"
        , case S.scaledBesselK 10 51.0 of
            Right r ->
                abs (S.sfValue r - (0.4609318164773611)) <= max (5 * S.sfError r) (1e-07 * abs (0.4609318164773611))
            _ -> False
        )
    ,
        ( "transition scaledK10x1000.0"
        , case S.scaledBesselK 10 1000.0 of
            Right r ->
                abs (S.sfValue r - (0.04165905142800566))
                    <= max (5 * S.sfError r) (1e-07 * abs (0.04165905142800566))
            _ -> False
        )
    ,
        ( "transition scaledK100x1.0"
        , case S.scaledBesselK 100 1.0 of
            Right r ->
                abs (S.sfValue r - (1.6038768474938961e+186))
                    <= max (5 * S.sfError r) (1e-07 * abs (1.6038768474938961e+186))
            _ -> False
        )
    ,
        ( "transition scaledK100x49.0"
        , case S.scaledBesselK 100 49.0 of
            Right r ->
                abs (S.sfValue r - (2.9852537216011905e+35))
                    <= max (5 * S.sfError r) (1e-07 * abs (2.9852537216011905e+35))
            _ -> False
        )
    ,
        ( "transition scaledK100x51.0"
        , case S.scaledBesselK 100 51.0 of
            Right r ->
                abs (S.sfValue r - (2.5082425967667418e+34))
                    <= max (5 * S.sfError r) (1e-07 * abs (2.5082425967667418e+34))
            _ -> False
        )
    ,
        ( "transition scaledK100x1000.0"
        , case S.scaledBesselK 100 1000.0 of
            Right r ->
                abs (S.sfValue r - (5.842446552126513)) <= max (5 * S.sfError r) (1e-07 * abs (5.842446552126513))
            _ -> False
        )
    ,
        ( "transition scaledI0x1.0"
        , case S.scaledBesselI 0 1.0 of
            Right r ->
                abs (S.sfValue r - (0.4657596075936404)) <= max (5 * S.sfError r) (1e-08 * abs (0.4657596075936404))
            _ -> False
        )
    ,
        ( "transition scaledI0x49.0"
        , case S.scaledBesselI 0 49.0 of
            Right r ->
                abs (S.sfValue r - (0.05713884709359022))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.05713884709359022))
            _ -> False
        )
    ,
        ( "transition scaledI0x51.0"
        , case S.scaledBesselI 0 51.0 of
            Right r ->
                abs (S.sfValue r - (0.056001554286845036))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.056001554286845036))
            _ -> False
        )
    ,
        ( "transition scaledI0x1000.0"
        , case S.scaledBesselI 0 1000.0 of
            Right r ->
                abs (S.sfValue r - (0.012617240455891255))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.012617240455891255))
            _ -> False
        )
    ,
        ( "transition scaledI1x1.0"
        , case S.scaledBesselI 1 1.0 of
            Right r ->
                abs (S.sfValue r - (0.20791041534970842))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.20791041534970842))
            _ -> False
        )
    ,
        ( "transition scaledI1x49.0"
        , case S.scaledBesselI 1 49.0 of
            Right r ->
                abs (S.sfValue r - (0.056552760159615884))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.056552760159615884))
            _ -> False
        )
    ,
        ( "transition scaledI1x51.0"
        , case S.scaledBesselI 1 51.0 of
            Right r ->
                abs (S.sfValue r - (0.05544977363583176))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.05544977363583176))
            _ -> False
        )
    ,
        ( "transition scaledI1x1000.0"
        , case S.scaledBesselI 1 1000.0 of
            Right r ->
                abs (S.sfValue r - (0.012610930256928629))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.012610930256928629))
            _ -> False
        )
    ,
        ( "transition scaledI5x1.0"
        , case S.scaledBesselI 5 1.0 of
            Right r ->
                abs (S.sfValue r - (9.9865714112087e-05))
                    <= max (5 * S.sfError r) (1e-08 * abs (9.9865714112087e-05))
            _ -> False
        )
    ,
        ( "transition scaledI5x49.0"
        , case S.scaledBesselI 5 49.0 of
            Right r ->
                abs (S.sfValue r - (0.044165967290303046))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.044165967290303046))
            _ -> False
        )
    ,
        ( "transition scaledI5x51.0"
        , case S.scaledBesselI 5 51.0 of
            Right r ->
                abs (S.sfValue r - (0.04372996950427343))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.04372996950427343))
            _ -> False
        )
    ,
        ( "transition scaledI5x1000.0"
        , case S.scaledBesselI 5 1000.0 of
            Right r ->
                abs (S.sfValue r - (0.012460428940768863))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.012460428940768863))
            _ -> False
        )
    ,
        ( "transition Parabolic0.5x-2"
        , case S.parabolicCylinder (0.5) (-2) of
            Right r ->
                abs (S.sfValue r - (-0.9049556625541808))
                    <= max (5 * S.sfError r) (1e-08 * abs (-0.9049556625541808))
            _ -> False
        )
    ,
        ( "transition Parabolic2.0x-2"
        , case S.parabolicCylinder (2.0) (-2) of
            Right r ->
                abs (S.sfValue r - (1.103638323514327)) <= max (5 * S.sfError r) (1e-08 * abs (1.103638323514327))
            _ -> False
        )
    ,
        ( "transition Parabolic-3.0x3"
        , case S.parabolicCylinder (-3.0) (3) of
            Right r ->
                abs (S.sfValue r - (0.0024190696227610674))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.0024190696227610674))
            _ -> False
        )
    ,
        ( "transition Parabolic0.5x5"
        , case S.parabolicCylinder (0.5) (5) of
            Right r ->
                abs (S.sfValue r - (0.00433747318141474))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.00433747318141474))
            _ -> False
        )
    ,
        ( "transition Parabolic4.0x5"
        , case S.parabolicCylinder (4.0) (5) of
            Right r ->
                abs (S.sfValue r - (0.922757077116845)) <= max (5 * S.sfError r) (1e-08 * abs (0.922757077116845))
            _ -> False
        )
    ,
        ( "transition Struve0.001"
        , case S.struve 0 0.001 of
            Right r ->
                abs (S.sfValue r - (0.0006366197016320538))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.0006366197016320538))
            _ -> False
        )
    ,
        ( "transition Struve1.0"
        , case S.struve 0 1.0 of
            Right r ->
                abs (S.sfValue r - (0.5686566270482881)) <= max (5 * S.sfError r) (1e-08 * abs (0.5686566270482881))
            _ -> False
        )
    ,
        ( "transition Struve10.0"
        , case S.struve 0 10.0 of
            Right r ->
                abs (S.sfValue r - (0.11874368368746126))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.11874368368746126))
            _ -> False
        )
    ,
        ( "transition Struve30.0"
        , case S.struve 0 30.0 of
            Right r ->
                abs (S.sfValue r - (-0.09609842155416415))
                    <= max (5 * S.sfError r) (1e-08 * abs (-0.09609842155416415))
            _ -> False
        )
    ,
        ( "transition 1F10.5 2 -100.0"
        , case S.hypergeometric1F1 (0.5) 2 (-100.0) of
            Right r ->
                abs (S.sfValue r - (0.11255475054034964))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.11255475054034964))
            _ -> False
        )
    ,
        ( "transition 1F10.5 2 100.0"
        , case S.hypergeometric1F1 (0.5) 2 (100.0) of
            Right r ->
                abs (S.sfValue r - (1.528201999699183e+40))
                    <= max (5 * S.sfError r) (1e-08 * abs (1.528201999699183e+40))
            _ -> False
        )
    ,
        ( "transition 1F12.0 3 -2.0"
        , case S.hypergeometric1F1 (2.0) 3 (-2.0) of
            Right r ->
                abs (S.sfValue r - (0.2969970751450809)) <= max (5 * S.sfError r) (1e-08 * abs (0.2969970751450809))
            _ -> False
        )
    ,
        ( "transition 1F1-2.0 3 10.0"
        , case S.hypergeometric1F1 (-2.0) 3 (10.0) of
            Right r ->
                abs (S.sfValue r - (2.666666666666667)) <= max (5 * S.sfError r) (1e-08 * abs (2.666666666666667))
            _ -> False
        )
    ,
        ( "transition 2F1-0.99"
        , case S.hypergeometric2F1 0.5 0.5 1 (-0.99) of
            Right r ->
                abs (S.sfValue r - (0.8357632526552147)) <= max (5 * S.sfError r) (1e-08 * abs (0.8357632526552147))
            _ -> False
        )
    ,
        ( "transition 2F10.9"
        , case S.hypergeometric2F1 0.5 0.5 1 (0.9) of
            Right r ->
                abs (S.sfValue r - (1.6412644143423694)) <= max (5 * S.sfError r) (1e-08 * abs (1.6412644143423694))
            _ -> False
        )
    ,
        ( "transition 2F10.99"
        , case S.hypergeometric2F1 0.5 0.5 1 (0.99) of
            Right r ->
                abs (S.sfValue r - (2.3527158167797424)) <= max (5 * S.sfError r) (1e-08 * abs (2.3527158167797424))
            _ -> False
        )
    ,
        ( "transition zeta-9.5"
        , case S.riemannZeta (-9.5) of
            Right r ->
                abs (S.sfValue r - (-0.006672172296466641))
                    <= max (5 * S.sfError r) (1e-08 * abs (-0.006672172296466641))
            _ -> False
        )
    ,
        ( "transition zeta-0.5"
        , case S.riemannZeta (-0.5) of
            Right r ->
                abs (S.sfValue r - (-0.20788622497735457))
                    <= max (5 * S.sfError r) (1e-08 * abs (-0.20788622497735457))
            _ -> False
        )
    ,
        ( "transition zeta0.01"
        , case S.riemannZeta (0.01) of
            Right r ->
                abs (S.sfValue r - (-0.5092907140398399))
                    <= max (5 * S.sfError r) (1e-08 * abs (-0.5092907140398399))
            _ -> False
        )
    ,
        ( "transition zeta0.99"
        , case S.riemannZeta (0.99) of
            Right r ->
                abs (S.sfValue r - (-99.4235129777281)) <= max (5 * S.sfError r) (1e-08 * abs (-99.4235129777281))
            _ -> False
        )
    ,
        ( "transition zeta1.01"
        , case S.riemannZeta (1.01) of
            Right r ->
                abs (S.sfValue r - (100.57794333849678)) <= max (5 * S.sfError r) (1e-08 * abs (100.57794333849678))
            _ -> False
        )
    ,
        ( "transition zeta20.0"
        , case S.riemannZeta (20.0) of
            Right r ->
                abs (S.sfValue r - (1.0000009539620338)) <= max (5 * S.sfError r) (1e-08 * abs (1.0000009539620338))
            _ -> False
        )
    ,
        ( "transition En0x1e-06"
        , case S.exponentialIntegral 0 1e-06 of
            Right r -> abs (S.sfValue r - (999999.0000005)) <= max (5 * S.sfError r) (1e-08 * abs (999999.0000005))
            _ -> False
        )
    ,
        ( "transition En1x1e-06"
        , case S.exponentialIntegral 1 1e-06 of
            Right r ->
                abs (S.sfValue r - (13.23829589306249)) <= max (5 * S.sfError r) (1e-08 * abs (13.23829589306249))
            _ -> False
        )
    ,
        ( "transition En5x1e-06"
        , case S.exponentialIntegral 5 1e-06 of
            Right r ->
                abs (S.sfValue r - (0.24999966666691667))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.24999966666691667))
            _ -> False
        )
    ,
        ( "transition En0x0.01"
        , case S.exponentialIntegral 0 0.01 of
            Right r -> abs (S.sfValue r - (99.0049833749168)) <= max (5 * S.sfError r) (1e-08 * abs (99.0049833749168))
            _ -> False
        )
    ,
        ( "transition En1x0.01"
        , case S.exponentialIntegral 1 0.01 of
            Right r ->
                abs (S.sfValue r - (4.037929576538113)) <= max (5 * S.sfError r) (1e-08 * abs (4.037929576538113))
            _ -> False
        )
    ,
        ( "transition En5x0.01"
        , case S.exponentialIntegral 5 0.01 of
            Right r ->
                abs (S.sfValue r - (0.2466915025472026)) <= max (5 * S.sfError r) (1e-08 * abs (0.2466915025472026))
            _ -> False
        )
    ,
        ( "transition En0x1.0"
        , case S.exponentialIntegral 0 1.0 of
            Right r ->
                abs (S.sfValue r - (0.36787944117144233))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.36787944117144233))
            _ -> False
        )
    ,
        ( "transition En1x1.0"
        , case S.exponentialIntegral 1 1.0 of
            Right r ->
                abs (S.sfValue r - (0.2193839343955205)) <= max (5 * S.sfError r) (1e-08 * abs (0.2193839343955205))
            _ -> False
        )
    ,
        ( "transition En5x1.0"
        , case S.exponentialIntegral 5 1.0 of
            Right r ->
                abs (S.sfValue r - (0.07045423746172041))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.07045423746172041))
            _ -> False
        )
    ,
        ( "transition En0x100.0"
        , case S.exponentialIntegral 0 100.0 of
            Right r ->
                abs (S.sfValue r - (3.720075976020836e-46))
                    <= max (5 * S.sfError r) (1e-08 * abs (3.720075976020836e-46))
            _ -> False
        )
    ,
        ( "transition En1x100.0"
        , case S.exponentialIntegral 1 100.0 of
            Right r ->
                abs (S.sfValue r - (3.683597761682032e-46))
                    <= max (5 * S.sfError r) (1e-08 * abs (3.683597761682032e-46))
            _ -> False
        )
    ,
        ( "transition En5x100.0"
        , case S.exponentialIntegral 5 100.0 of
            Right r ->
                abs (S.sfValue r - (3.544508568894701e-46))
                    <= max (5 * S.sfError r) (1e-08 * abs (3.544508568894701e-46))
            _ -> False
        )
    ,
        ( "transition Dawson0.001"
        , case S.dawson 0.001 of
            Right r ->
                abs (S.sfValue r - (0.0009999993333336)) <= max (5 * S.sfError r) (1e-08 * abs (0.0009999993333336))
            _ -> False
        )
    ,
        ( "transition Debye0.001"
        , case S.debye 3 0.001 of
            Right r ->
                abs (S.sfValue r - (0.9996250499999995)) <= max (5 * S.sfError r) (1e-08 * abs (0.9996250499999995))
            _ -> False
        )
    ,
        ( "transition Dawson1.0"
        , case S.dawson 1.0 of
            Right r ->
                abs (S.sfValue r - (0.5380795069127684)) <= max (5 * S.sfError r) (1e-08 * abs (0.5380795069127684))
            _ -> False
        )
    ,
        ( "transition Debye1.0"
        , case S.debye 3 1.0 of
            Right r ->
                abs (S.sfValue r - (0.6744155640778147)) <= max (5 * S.sfError r) (1e-08 * abs (0.6744155640778147))
            _ -> False
        )
    ,
        ( "transition Dawson10.0"
        , case S.dawson 10.0 of
            Right r ->
                abs (S.sfValue r - (0.05025384718759854))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.05025384718759854))
            _ -> False
        )
    ,
        ( "transition Debye10.0"
        , case S.debye 3 10.0 of
            Right r ->
                abs (S.sfValue r - (0.01929576569034549))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.01929576569034549))
            _ -> False
        )
    ,
        ( "transition Dawson100.0"
        , case S.dawson 100.0 of
            Right r ->
                abs (S.sfValue r - (0.005000250037509379))
                    <= max (5 * S.sfError r) (1e-08 * abs (0.005000250037509379))
            _ -> False
        )
    ,
        ( "transition Debye100.0"
        , case S.debye 3 100.0 of
            Right r ->
                abs (S.sfValue r - (1.9481818206800488e-05))
                    <= max (5 * S.sfError r) (1e-08 * abs (1.9481818206800488e-05))
            _ -> False
        )
    ]

reviewRegressionTests :: [(String, Bool)]
reviewRegressionTests =
    [
        ( "normal sample size upper-budget interval"
        , case A.normalSampleSize 0.05 0.8 0.000313226 of
            Right n -> n <= 100000000 && n > 67108864
            _ -> False
        )
    ,
        ( "AD extreme statistic has tiny tail"
        , case A.andersonDarling (replicate 1000 0 ++ replicate 1000 1) of
            Right t -> A.testStatistic t > 300 && A.pValue t < 1e-20
            _ -> False
        )
    ,
        ( "KS small-z theta transform"
        , case A.kolmogorovSmirnov (P.Uniform 0 1) [(fromIntegral i + 0.5) / 100000 | i <- [0 .. 99999 :: Int]] of
            Right t -> A.pValue t > 1 - 1e-12
            _ -> False
        )
    ,
        ( "hybrid mixture density rejects incompatible measure"
        , isLeft (P.density (P.Mixture [(0.5, P.Bernoulli 0.5), (0.5, P.Normal 0 1)]) 0)
        )
    , ("Wigner large exact-sum regime", near 1e-12 (S.wigner3j 60 60 60 0 0 0) (-0.01987533918822201))
    , ("Jacobi huge unresolved phase rejected", isLeft (S.jacobiElliptic 1e100 0.5))
    ,
        ( "Jacobi rounded AGM fixed-point regression"
        , case S.jacobiElliptic 1 0.9580059887071425 of
            Right (sn, cn, dn) ->
                abs (sn - 0.7651720984137684) < 1e-11
                    && abs (cn - 0.6438257992726528) < 1e-11
                    && abs (dn - 0.6626452020341539) < 1e-11
            _ -> False
        )
    ,
        ( "Jacobi AGM period identity"
        , case S.jacobiElliptic 1000 0 of
            Right (sn, cn, dn) -> abs (sn - sin 1000) < 1e-10 && abs (cn - cos 1000) < 1e-10 && dn == 1
            _ -> False
        )
    ,
        ( "Clausen huge phase identity"
        , near
            1e-10
            ( (-)
                <$> (S.sfValue <$> S.clausen 1e100)
                <*> (S.sfValue <$> S.clausen (atan2 (sin 1e100) (cos 1e100)))
            )
            0
        )
    ,
        ( "Debye large-x missed-peak regression"
        , case S.debye 3 10000 of
            Right value -> abs (S.sfValue value / 1.9481818206800487e-11 - 1) < 1e-12
            _ -> False
        )
    ]
