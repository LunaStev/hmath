{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated; original algorithms and complete immutable continuation states.
module HMath.FFI.Stochastic where
import Control.Exception (catch,evaluate,throwIO)
import Data.Typeable (Typeable,cast)
import Foreign
import Foreign.C
import System.IO.Unsafe (unsafePerformIO)
import qualified HMath.Error as E
import qualified HMath.Matrix as M
import HMath.FFI.Coefficient
import HMath.FFI.RandomCodec (rng,asRNG)
import qualified HMath.FFI.LinearCodec as LC
import qualified HMath.FFI.Value as X
import qualified HMath.FFI.Boundary as Boundary
import HMath.FFI.MathError
import qualified HMath.Random as R
import qualified HMath.Probability as P
import qualified HMath.Statistics.Advanced as S

unbox :: forall a. Typeable a => Int -> X.Value -> IO a
unbox kind (X.Opaque actual _ _ _ payload) | kind==actual=maybe(X.invalid "stochastic object payload differs") pure(cast payload)
unbox _ _=X.invalid "stochastic object kind differs"
source :: Either E.MathError a -> IO a
source=either (throwIO . CallbackMathError) pure
forceFields :: [IO X.Value] -> IO ()
forceFields fields=sequence fields >>= mapM_ X.forceValue
checkedCallback :: X.Value -> X.Value -> (X.Value -> IO a) -> IO(Either E.MathError a)
checkedCallback function argument decodeResult=(LC.callbackValue function argument >>= decodeResult >>= pure . Right) `catch` relay
  where
    relay(CallbackMathError errorValue)=pure(Left errorValue)
    relay other=throwIO(other::CallbackFailure)
stochasticBoundary :: IO CInt -> IO CInt
stochasticBoundary action=Boundary.boundary $ callbackBoundary (\e -> Boundary.checked(Left e)(const(pure()))) action

encodeGenerator :: R.Generator -> IO X.Value
encodeGenerator value=pure(X.Opaque 241 (-1) 0 force value)
  where
    force=evaluate value >> pure()

encodeRNG :: R.RNG -> IO X.Value
encodeRNG=pure . rng

encodeAliasTable :: R.AliasTable -> IO X.Value
encodeAliasTable value=pure(X.Opaque 242 (-1) 0 force value)
  where
    force=evaluate value >> pure()

encodeDistribution :: P.Distribution -> IO X.Value
encodeDistribution value=pure(X.Opaque 243 (-1) 0 force value)
  where
    force=case value of
        P.Bernoulli field1 -> forceFields [pure(X.Scalar SDouble field1)]
        P.Binomial field2 field3 -> forceFields [pure(X.Index field2),pure(X.Scalar SDouble field3)]
        P.NegativeBinomial field4 field5 -> forceFields [pure(X.Scalar SDouble field4),pure(X.Scalar SDouble field5)]
        P.Geometric field6 -> forceFields [pure(X.Scalar SDouble field6)]
        P.Hypergeometric field7 field8 field9 -> forceFields [pure(X.Index field7),pure(X.Index field8),pure(X.Index field9)]
        P.Poisson field10 -> forceFields [pure(X.Scalar SDouble field10)]
        P.Categorical field11 -> forceFields [X.List <$> mapM (\item12 -> pure(X.Scalar SDouble item12)) field11]
        P.DiscreteUniform field13 field14 -> forceFields [pure(X.Index field13),pure(X.Index field14)]
        P.Uniform field15 field16 -> forceFields [pure(X.Scalar SDouble field15),pure(X.Scalar SDouble field16)]
        P.Normal field17 field18 -> forceFields [pure(X.Scalar SDouble field17),pure(X.Scalar SDouble field18)]
        P.LogNormal field19 field20 -> forceFields [pure(X.Scalar SDouble field19),pure(X.Scalar SDouble field20)]
        P.Exponential field21 -> forceFields [pure(X.Scalar SDouble field21)]
        P.Gamma field22 field23 -> forceFields [pure(X.Scalar SDouble field22),pure(X.Scalar SDouble field23)]
        P.Beta field24 field25 -> forceFields [pure(X.Scalar SDouble field24),pure(X.Scalar SDouble field25)]
        P.ChiSquare field26 -> forceFields [pure(X.Scalar SDouble field26)]
        P.StudentT field27 -> forceFields [pure(X.Scalar SDouble field27)]
        P.FisherF field28 field29 -> forceFields [pure(X.Scalar SDouble field28),pure(X.Scalar SDouble field29)]
        P.Cauchy field30 field31 -> forceFields [pure(X.Scalar SDouble field30),pure(X.Scalar SDouble field31)]
        P.Laplace field32 field33 -> forceFields [pure(X.Scalar SDouble field32),pure(X.Scalar SDouble field33)]
        P.Logistic field34 field35 -> forceFields [pure(X.Scalar SDouble field34),pure(X.Scalar SDouble field35)]
        P.Weibull field36 field37 -> forceFields [pure(X.Scalar SDouble field36),pure(X.Scalar SDouble field37)]
        P.Pareto field38 field39 -> forceFields [pure(X.Scalar SDouble field38),pure(X.Scalar SDouble field39)]
        P.Rayleigh field40 -> forceFields [pure(X.Scalar SDouble field40)]
        P.Maxwell field41 -> forceFields [pure(X.Scalar SDouble field41)]
        P.Gumbel field42 field43 -> forceFields [pure(X.Scalar SDouble field42),pure(X.Scalar SDouble field43)]
        P.GeneralizedExtremeValue field44 field45 field46 -> forceFields [pure(X.Scalar SDouble field44),pure(X.Scalar SDouble field45),pure(X.Scalar SDouble field46)]
        P.BetaBinomial field47 field48 field49 -> forceFields [pure(X.Index field47),pure(X.Scalar SDouble field48),pure(X.Scalar SDouble field49)]
        P.Skellam field50 field51 -> forceFields [pure(X.Scalar SDouble field50),pure(X.Scalar SDouble field51)]
        P.VonMises field52 field53 -> forceFields [pure(X.Scalar SDouble field52),pure(X.Scalar SDouble field53)]
        P.Triangular field54 field55 field56 -> forceFields [pure(X.Scalar SDouble field54),pure(X.Scalar SDouble field55),pure(X.Scalar SDouble field56)]
        P.TruncatedNormal field57 field58 field59 field60 -> forceFields [pure(X.Scalar SDouble field57),pure(X.Scalar SDouble field58),pure(X.Scalar SDouble field59),pure(X.Scalar SDouble field60)]
        P.Mixture field61 -> forceFields [X.List <$> mapM (\item62 -> (\(part63,part64) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part63),encodeDistribution part64]) item62) field61]
        P.Empirical field65 -> forceFields [X.List <$> mapM (\item66 -> pure(X.Scalar SDouble item66)) field65]
        P.GaussianKDE field67 field68 -> forceFields [pure(X.Scalar SDouble field67),X.List <$> mapM (\item69 -> pure(X.Scalar SDouble item69)) field68]

encodeMarkov :: P.Markov -> IO X.Value
encodeMarkov value=pure(X.Opaque 244 (-1) 0 force value)
  where
    force=evaluate value >> pure()

encodeHMM :: P.HMM -> IO X.Value
encodeHMM value=pure(X.Opaque 245 (-1) 0 force value)
  where
    force=evaluate value >> pure()

encodeStreaming :: S.Streaming -> IO X.Value
encodeStreaming value=pure(X.Opaque 246 (-1) 0 force value)
  where
    force=evaluate value >> pure()

encodeTestResult :: S.TestResult -> IO X.Value
encodeTestResult value=pure(X.Opaque 247 (-1) 0 force value)
  where
    force=forceFields [pure(X.Scalar SDouble (S.testStatistic value)),pure(X.Scalar SDouble (S.pValue value)),X.List <$> mapM (\item70 -> pure(X.Scalar SDouble item70)) (S.degreesOfFreedom value)]

apply :: Int -> [X.Value] -> IO X.Value
apply operation args=case(operation,args) of
    (0,[a0]) -> do
        a0Value <- (asRNG a0 :: IO (R.RNG))
        encodeRNG (R.cloneRNG a0Value :: (R.RNG))
    (1,[a0,a1]) -> do
        a0Value <- (unbox 241 a0 :: IO (R.Generator))
        a1Value <- (X.asScalar a1 :: IO (Word64))
        encodeRNG (R.seedRNG a0Value a1Value :: (R.RNG))
    (2,[a0]) -> do
        a0Value <- (asRNG a0 :: IO (R.RNG))
        (\(part71,part72) -> X.Tuple <$> sequence [pure(X.Scalar SWord64 part71),encodeRNG part72]) (R.nextWord64 a0Value :: ((Word64),(R.RNG)))
    (3,[a0]) -> do
        a0Value <- (asRNG a0 :: IO (R.RNG))
        (\(part73,part74) -> X.Tuple <$> sequence [encodeRNG part73,encodeRNG part74]) (R.splitRNG a0Value :: ((R.RNG),(R.RNG)))
    (4,[a0]) -> do
        a0Value <- (asRNG a0 :: IO (R.RNG))
        pure(X.Text (R.serializeRNG a0Value :: (String)))
    (5,[a0]) -> do
        a0Value <- (X.asText a0 :: IO (String))
        source (R.restoreRNG a0Value :: (Either (E.MathError) (R.RNG))) >>= \_result75 -> encodeRNG _result75
    (6,[a0]) -> do
        a0Value <- (asRNG a0 :: IO (R.RNG))
        (\(part76,part77) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part76),encodeRNG part77]) (R.uniform a0Value :: ((Double),(R.RNG)))
    (7,[a0]) -> do
        a0Value <- (asRNG a0 :: IO (R.RNG))
        (\(part78,part79) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part78),encodeRNG part79]) (R.uniformOpen a0Value :: ((Double),(R.RNG)))
    (8,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (asRNG a2 :: IO (R.RNG))
        source (R.uniformInt a0Value a1Value a2Value :: (Either (E.MathError) ((Int),(R.RNG)))) >>= \_result80 -> (\(part81,part82) -> X.Tuple <$> sequence [pure(X.Index part81),encodeRNG part82]) _result80
    (9,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (pure (\parameter83 -> unsafePerformIO $ do { callbackArgs <- sequence [encodeRNG parameter83]; let { callbackInput=X.Tuple callbackArgs }; checkedCallback a1 callbackInput (\reply -> (X.asTuple 2 reply >>= \tuple86 -> case tuple86 of { [part84,part85] -> (,) <$> (pure part84) <*> (asRNG part85); _ -> X.invalid "tuple arity differs" })) }) :: IO ((R.RNG) -> (Either (E.MathError) ((X.Value),(R.RNG)))))
        a2Value <- (asRNG a2 :: IO (R.RNG))
        source (R.sampleN a0Value a1Value a2Value :: (Either (E.MathError) ([(X.Value)],(R.RNG)))) >>= \_result87 -> (\(part88,part89) -> X.Tuple <$> sequence [X.List <$> mapM (\item90 -> pure item90) part88,encodeRNG part89]) _result87
    (10,[a0]) -> do
        a0Value <- (asRNG a0 :: IO (R.RNG))
        (\(part91,part92) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part91),encodeRNG part92]) (R.boxMuller a0Value :: ((Double),(R.RNG)))
    (11,[a0]) -> do
        a0Value <- (asRNG a0 :: IO (R.RNG))
        source (R.marsagliaNormal a0Value :: (Either (E.MathError) ((Double),(R.RNG)))) >>= \_result93 -> (\(part94,part95) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part94),encodeRNG part95]) _result93
    (12,[a0]) -> do
        a0Value <- (asRNG a0 :: IO (R.RNG))
        source (R.zigguratNormal a0Value :: (Either (E.MathError) ((Double),(R.RNG)))) >>= \_result96 -> (\(part97,part98) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part97),encodeRNG part98]) _result96
    (13,[a0,a1,a2]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (asRNG a2 :: IO (R.RNG))
        source (R.normal a0Value a1Value a2Value :: (Either (E.MathError) ((Double),(R.RNG)))) >>= \_result99 -> (\(part100,part101) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part100),encodeRNG part101]) _result99
    (14,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (asRNG a1 :: IO (R.RNG))
        source (R.exponential a0Value a1Value :: (Either (E.MathError) ((Double),(R.RNG)))) >>= \_result102 -> (\(part103,part104) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part103),encodeRNG part104]) _result102
    (15,[a0,a1,a2]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (asRNG a2 :: IO (R.RNG))
        source (R.gamma a0Value a1Value a2Value :: (Either (E.MathError) ((Double),(R.RNG)))) >>= \_result105 -> (\(part106,part107) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part106),encodeRNG part107]) _result105
    (16,[a0,a1,a2]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (asRNG a2 :: IO (R.RNG))
        source (R.beta a0Value a1Value a2Value :: (Either (E.MathError) ((Double),(R.RNG)))) >>= \_result108 -> (\(part109,part110) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part109),encodeRNG part110]) _result108
    (17,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (asRNG a1 :: IO (R.RNG))
        source (R.poisson a0Value a1Value :: (Either (E.MathError) ((Int),(R.RNG)))) >>= \_result111 -> (\(part112,part113) -> X.Tuple <$> sequence [pure(X.Index part112),encodeRNG part113]) _result111
    (18,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (asRNG a2 :: IO (R.RNG))
        source (R.binomial a0Value a1Value a2Value :: (Either (E.MathError) ((Int),(R.RNG)))) >>= \_result114 -> (\(part115,part116) -> X.Tuple <$> sequence [pure(X.Index part115),encodeRNG part116]) _result114
    (19,[a0,a1]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item117 -> X.asScalar item117) :: IO [(Double)])
        a1Value <- (asRNG a1 :: IO (R.RNG))
        source (R.weighted a0Value a1Value :: (Either (E.MathError) ((Int),(R.RNG)))) >>= \_result118 -> (\(part119,part120) -> X.Tuple <$> sequence [pure(X.Index part119),encodeRNG part120]) _result118
    (20,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item121 -> X.asScalar item121) :: IO [(Double)])
        source (R.aliasTable a0Value :: (Either (E.MathError) (R.AliasTable))) >>= \_result122 -> encodeAliasTable _result122
    (21,[a0,a1]) -> do
        a0Value <- (unbox 242 a0 :: IO (R.AliasTable))
        a1Value <- (asRNG a1 :: IO (R.RNG))
        source (R.aliasSample a0Value a1Value :: (Either (E.MathError) ((Int),(R.RNG)))) >>= \_result123 -> (\(part124,part125) -> X.Tuple <$> sequence [pure(X.Index part124),encodeRNG part125]) _result123
    (22,[a0,a1]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item126 -> pure item126) :: IO [(X.Value)])
        a1Value <- (asRNG a1 :: IO (R.RNG))
        source (R.shuffle a0Value a1Value :: (Either (E.MathError) ([(X.Value)],(R.RNG)))) >>= \_result127 -> (\(part128,part129) -> X.Tuple <$> sequence [X.List <$> mapM (\item130 -> pure item130) part128,encodeRNG part129]) _result127
    (23,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asList a1 >>= mapM (\item131 -> pure item131) :: IO [(X.Value)])
        a2Value <- (asRNG a2 :: IO (R.RNG))
        source (R.withReplacement a0Value a1Value a2Value :: (Either (E.MathError) ([(X.Value)],(R.RNG)))) >>= \_result132 -> (\(part133,part134) -> X.Tuple <$> sequence [X.List <$> mapM (\item135 -> pure item135) part133,encodeRNG part134]) _result132
    (24,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asList a1 >>= mapM (\item136 -> pure item136) :: IO [(X.Value)])
        a2Value <- (asRNG a2 :: IO (R.RNG))
        source (R.withoutReplacement a0Value a1Value a2Value :: (Either (E.MathError) ([(X.Value)],(R.RNG)))) >>= \_result137 -> (\(part138,part139) -> X.Tuple <$> sequence [X.List <$> mapM (\item140 -> pure item140) part138,encodeRNG part139]) _result137
    (25,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asList a1 >>= mapM (\item141 -> pure item141) :: IO [(X.Value)])
        a2Value <- (asRNG a2 :: IO (R.RNG))
        source (R.reservoir a0Value a1Value a2Value :: (Either (E.MathError) ([(X.Value)],(R.RNG)))) >>= \_result142 -> (\(part143,part144) -> X.Tuple <$> sequence [X.List <$> mapM (\item145 -> pure item145) part143,encodeRNG part144]) _result142
    (26,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (asRNG a1 :: IO (R.RNG))
        source (R.stratified a0Value a1Value :: (Either (E.MathError) ([(Double)],(R.RNG)))) >>= \_result146 -> (\(part147,part148) -> X.Tuple <$> sequence [X.List <$> mapM (\item149 -> pure(X.Scalar SDouble item149)) part147,encodeRNG part148]) _result146
    (27,[a0,a1,a2,a3]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (pure (\parameter150 -> unsafePerformIO $ do { callbackArgs <- sequence [pure(X.Scalar SDouble parameter150)]; let { callbackInput=X.Tuple callbackArgs }; LC.callbackValue a1 callbackInput >>= \reply -> X.asScalar reply }) :: IO ((Double) -> (Double)))
        a2Value <- (pure (\parameter151 -> unsafePerformIO $ do { callbackArgs <- sequence [encodeRNG parameter151]; let { callbackInput=X.Tuple callbackArgs }; checkedCallback a2 callbackInput (\reply -> (X.asTuple 2 reply >>= \tuple154 -> case tuple154 of { [part152,part153] -> (,) <$> (X.asScalar part152) <*> (asRNG part153); _ -> X.invalid "tuple arity differs" })) }) :: IO ((R.RNG) -> (Either (E.MathError) ((Double),(R.RNG)))))
        a3Value <- (asRNG a3 :: IO (R.RNG))
        source (R.rejection a0Value a1Value a2Value a3Value :: (Either (E.MathError) ((Double),(R.RNG)))) >>= \_result155 -> (\(part156,part157) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part156),encodeRNG part157]) _result155
    (28,[a0,a1]) -> do
        a0Value <- (pure (\parameter158 -> unsafePerformIO $ do { callbackArgs <- sequence [pure(X.Scalar SDouble parameter158)]; let { callbackInput=X.Tuple callbackArgs }; checkedCallback a0 callbackInput (\reply -> X.asScalar reply) }) :: IO ((Double) -> (Either (E.MathError) (Double))))
        a1Value <- (asRNG a1 :: IO (R.RNG))
        source (R.inverseTransform a0Value a1Value :: (Either (E.MathError) ((Double),(R.RNG)))) >>= \_result159 -> (\(part160,part161) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part160),encodeRNG part161]) _result159
    (29,[a0,a1,a2,a3,a4]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (pure (\parameter162 -> unsafePerformIO $ do { callbackArgs <- sequence [pure(X.Scalar SDouble parameter162)]; let { callbackInput=X.Tuple callbackArgs }; LC.callbackValue a2 callbackInput >>= \reply -> X.asScalar reply }) :: IO ((Double) -> (Double)))
        a3Value <- (X.asScalar a3 :: IO (Double))
        a4Value <- (asRNG a4 :: IO (R.RNG))
        source (R.metropolisHastings a0Value a1Value a2Value a3Value a4Value :: (Either (E.MathError) ([(Double)],(R.RNG)))) >>= \_result163 -> (\(part164,part165) -> X.Tuple <$> sequence [X.List <$> mapM (\item166 -> pure(X.Scalar SDouble item166)) part164,encodeRNG part165]) _result163
    (30,[a0,a1,a2,a3]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asList a1 >>= mapM (\item167 -> pure (\parameter168 parameter169 -> unsafePerformIO $ do { callbackArgs <- sequence [X.List <$> mapM (\item170 -> pure(X.Scalar SDouble item170)) parameter168,encodeRNG parameter169]; let { callbackInput=X.Tuple callbackArgs }; checkedCallback item167 callbackInput (\reply -> (X.asTuple 2 reply >>= \tuple173 -> case tuple173 of { [part171,part172] -> (,) <$> (X.asScalar part171) <*> (asRNG part172); _ -> X.invalid "tuple arity differs" })) })) :: IO [([(Double)] -> (R.RNG) -> (Either (E.MathError) ((Double),(R.RNG))))])
        a2Value <- (X.asList a2 >>= mapM (\item174 -> X.asScalar item174) :: IO [(Double)])
        a3Value <- (asRNG a3 :: IO (R.RNG))
        source (R.gibbs a0Value a1Value a2Value a3Value :: (Either (E.MathError) ([[(Double)]],(R.RNG)))) >>= \_result175 -> (\(part176,part177) -> X.Tuple <$> sequence [X.List <$> mapM (\item178 -> X.List <$> mapM (\item179 -> pure(X.Scalar SDouble item179)) item178) part176,encodeRNG part177]) _result175
    (31,[a0,a1,a2,a3,a4,a5,a6]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asScalar a2 :: IO (Double))
        a3Value <- (pure (\parameter180 -> unsafePerformIO $ do { callbackArgs <- sequence [X.List <$> mapM (\item181 -> pure(X.Scalar SDouble item181)) parameter180]; let { callbackInput=X.Tuple callbackArgs }; LC.callbackValue a3 callbackInput >>= \reply -> X.asScalar reply }) :: IO ([(Double)] -> (Double)))
        a4Value <- (pure (\parameter182 -> unsafePerformIO $ do { callbackArgs <- sequence [X.List <$> mapM (\item183 -> pure(X.Scalar SDouble item183)) parameter182]; let { callbackInput=X.Tuple callbackArgs }; LC.callbackValue a4 callbackInput >>= \reply -> X.asList reply >>= mapM (\item184 -> X.asScalar item184) }) :: IO ([(Double)] -> [(Double)]))
        a5Value <- (X.asList a5 >>= mapM (\item185 -> X.asScalar item185) :: IO [(Double)])
        a6Value <- (asRNG a6 :: IO (R.RNG))
        source (R.hamiltonianMonteCarlo a0Value a1Value a2Value a3Value a4Value a5Value a6Value :: (Either (E.MathError) ([[(Double)]],(R.RNG)))) >>= \_result186 -> (\(part187,part188) -> X.Tuple <$> sequence [X.List <$> mapM (\item189 -> X.List <$> mapM (\item190 -> pure(X.Scalar SDouble item190)) item189) part187,encodeRNG part188]) _result186
    (32,[a0,a1,a2]) -> do
        a0Value <- (pure (\parameter191 -> unsafePerformIO $ do { callbackArgs <- sequence [pure(X.Scalar SDouble parameter191)]; let { callbackInput=X.Tuple callbackArgs }; LC.callbackValue a0 callbackInput >>= \reply -> X.asScalar reply }) :: IO ((Double) -> (Double)))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (asRNG a2 :: IO (R.RNG))
        source (R.monteCarlo a0Value a1Value a2Value :: (Either (E.MathError) (((Double),(Double)),(R.RNG)))) >>= \_result192 -> (\(part193,part194) -> X.Tuple <$> sequence [(\(part195,part196) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part195),pure(X.Scalar SDouble part196)]) part193,encodeRNG part194]) _result192
    (33,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (asRNG a2 :: IO (R.RNG))
        source (R.latinHypercube a0Value a1Value a2Value :: (Either (E.MathError) ([[(Double)]],(R.RNG)))) >>= \_result197 -> (\(part198,part199) -> X.Tuple <$> sequence [X.List <$> mapM (\item200 -> X.List <$> mapM (\item201 -> pure(X.Scalar SDouble item201)) item200) part198,encodeRNG part199]) _result197
    (34,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (asRNG a1 :: IO (R.RNG))
        source (R.randomQuality a0Value a1Value :: (Either (E.MathError) (((Double),(Double),(Double)),(R.RNG)))) >>= \_result202 -> (\(part203,part204) -> X.Tuple <$> sequence [(\(part205,part206,part207) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part205),pure(X.Scalar SDouble part206),pure(X.Scalar SDouble part207)]) part203,encodeRNG part204]) _result202
    (35,[]) -> do
        (R.entropySeed  :: (IO (Word64))) >>= \_result208 -> pure(X.Scalar SWord64 _result208)
    (36,[]) -> do
        encodeGenerator (R.PCG32  :: (R.Generator))
    (37,[]) -> do
        encodeGenerator (R.Xoshiro256StarStar  :: (R.Generator))
    (38,[]) -> do
        encodeGenerator (R.Xoroshiro128Plus  :: (R.Generator))
    (39,[]) -> do
        encodeGenerator (R.MT19937  :: (R.Generator))
    (40,[]) -> do
        encodeGenerator (R.Philox4x32  :: (R.Generator))
    (41,[]) -> do
        encodeGenerator (R.Threefry2x64  :: (R.Generator))
    (42,[]) -> do
        encodeGenerator (R.ChaCha20  :: (R.Generator))
    (43,[a0]) -> do
        a0Value <- (unbox 243 a0 :: IO (P.Distribution))
        source (P.validateDistribution a0Value :: (Either (E.MathError) ())) >>= \_result209 -> pure X.None
    (44,[a0,a1]) -> do
        a0Value <- (unbox 243 a0 :: IO (P.Distribution))
        a1Value <- (X.asScalar a1 :: IO (Double))
        source (P.logDensity a0Value a1Value :: (Either (E.MathError) (Double))) >>= \_result210 -> pure(X.Scalar SDouble _result210)
    (45,[a0,a1]) -> do
        a0Value <- (unbox 243 a0 :: IO (P.Distribution))
        a1Value <- (X.asScalar a1 :: IO (Double))
        source (P.density a0Value a1Value :: (Either (E.MathError) (Double))) >>= \_result211 -> pure(X.Scalar SDouble _result211)
    (46,[a0,a1]) -> do
        a0Value <- (unbox 243 a0 :: IO (P.Distribution))
        a1Value <- (X.asScalar a1 :: IO (Double))
        source (P.cdf a0Value a1Value :: (Either (E.MathError) (Double))) >>= \_result212 -> pure(X.Scalar SDouble _result212)
    (47,[a0,a1]) -> do
        a0Value <- (unbox 243 a0 :: IO (P.Distribution))
        a1Value <- (X.asScalar a1 :: IO (Double))
        source (P.survival a0Value a1Value :: (Either (E.MathError) (Double))) >>= \_result213 -> pure(X.Scalar SDouble _result213)
    (48,[a0,a1]) -> do
        a0Value <- (unbox 243 a0 :: IO (P.Distribution))
        a1Value <- (X.asScalar a1 :: IO (Double))
        source (P.quantile a0Value a1Value :: (Either (E.MathError) (Double))) >>= \_result214 -> pure(X.Scalar SDouble _result214)
    (49,[a0,a1]) -> do
        a0Value <- (unbox 243 a0 :: IO (P.Distribution))
        a1Value <- (X.asScalar a1 :: IO (Double))
        source (P.hazard a0Value a1Value :: (Either (E.MathError) (Double))) >>= \_result215 -> pure(X.Scalar SDouble _result215)
    (50,[a0,a1]) -> do
        a0Value <- (unbox 243 a0 :: IO (P.Distribution))
        a1Value <- (X.asList a1 >>= mapM (\item216 -> X.asScalar item216) :: IO [(Double)])
        source (P.logLikelihood a0Value a1Value :: (Either (E.MathError) (Double))) >>= \_result217 -> pure(X.Scalar SDouble _result217)
    (51,[a0]) -> do
        a0Value <- (unbox 243 a0 :: IO (P.Distribution))
        source (P.moments a0Value :: (Either (E.MathError) ((Double),(Double)))) >>= \_result218 -> (\(part219,part220) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part219),pure(X.Scalar SDouble part220)]) _result218
    (52,[a0]) -> do
        a0Value <- (unbox 243 a0 :: IO (P.Distribution))
        source (P.entropy a0Value :: (Either (E.MathError) (Double))) >>= \_result221 -> pure(X.Scalar SDouble _result221)
    (53,[a0,a1]) -> do
        a0Value <- (unbox 243 a0 :: IO (P.Distribution))
        a1Value <- (pure (\parameter222 -> unsafePerformIO $ do { callbackArgs <- sequence [pure(X.Scalar SDouble parameter222)]; let { callbackInput=X.Tuple callbackArgs }; LC.callbackValue a1 callbackInput >>= \reply -> X.asScalar reply }) :: IO ((Double) -> (Double)))
        source (P.expectation a0Value a1Value :: (Either (E.MathError) (Double))) >>= \_result223 -> pure(X.Scalar SDouble _result223)
    (54,[a0,a1]) -> do
        a0Value <- (unbox 243 a0 :: IO (P.Distribution))
        a1Value <- (asRNG a1 :: IO (R.RNG))
        source (P.sample a0Value a1Value :: (Either (E.MathError) ((Double),(R.RNG)))) >>= \_result224 -> (\(part225,part226) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part225),encodeRNG part226]) _result224
    (55,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item227 -> X.asScalar item227) :: IO [(Double)])
        source (P.fitNormal a0Value :: (Either (E.MathError) (P.Distribution))) >>= \_result228 -> encodeDistribution _result228
    (56,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item229 -> X.asScalar item229) :: IO [(Double)])
        source (P.fitExponential a0Value :: (Either (E.MathError) (P.Distribution))) >>= \_result230 -> encodeDistribution _result230
    (57,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item231 -> X.asScalar item231) :: IO [(Double)])
        source (P.fitBernoulli a0Value :: (Either (E.MathError) (P.Distribution))) >>= \_result232 -> encodeDistribution _result232
    (58,[a0,a1]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item233 -> unbox 243 item233) :: IO [(P.Distribution)])
        a1Value <- (X.asList a1 >>= mapM (\item234 -> X.asScalar item234) :: IO [(Double)])
        source (P.fitMLEGrid a0Value a1Value :: (Either (E.MathError) (P.Distribution))) >>= \_result235 -> encodeDistribution _result235
    (59,[a0,a1,a2]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item236 -> unbox 243 item236) :: IO [(P.Distribution)])
        a1Value <- (X.asList a1 >>= mapM (\item237 -> X.asScalar item237) :: IO [(Double)])
        a2Value <- (pure (\parameter238 -> unsafePerformIO $ do { callbackArgs <- sequence [encodeDistribution parameter238]; let { callbackInput=X.Tuple callbackArgs }; LC.callbackValue a2 callbackInput >>= \reply -> X.asScalar reply }) :: IO ((P.Distribution) -> (Double)))
        source (P.fitMAPGrid a0Value a1Value a2Value :: (Either (E.MathError) (P.Distribution))) >>= \_result239 -> encodeDistribution _result239
    (60,[a0,a1,a2]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (X.asList a2 >>= mapM (\item240 -> X.asBoolean item240) :: IO [(Bool)])
        source (P.betaBernoulliUpdate a0Value a1Value a2Value :: (Either (E.MathError) ((Double),(Double)))) >>= \_result241 -> (\(part242,part243) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part242),pure(X.Scalar SDouble part243)]) _result241
    (61,[a0,a1]) -> do
        a0Value <- (unbox 243 a0 :: IO (P.Distribution))
        a1Value <- (X.asList a1 >>= mapM (\item244 -> X.asScalar item244) :: IO [(Double)])
        source (P.goodnessOfFit a0Value a1Value :: (Either (E.MathError) (Double))) >>= \_result245 -> pure(X.Scalar SDouble _result245)
    (62,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asList a1 >>= mapM (\item246 -> X.asScalar item246) :: IO [(Double)])
        source (P.gaussianKDE a0Value a1Value :: (Either (E.MathError) (P.Distribution))) >>= \_result247 -> encodeDistribution _result247
    (63,[a0,a1,a2]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item248 -> X.asScalar item248) :: IO [(Double)])
        a1Value <- (LC.asMatrix a1 :: IO (M.Matrix (Double)))
        a2Value <- (X.asList a2 >>= mapM (\item249 -> X.asScalar item249) :: IO [(Double)])
        source (P.multivariateNormalLogDensity a0Value a1Value a2Value :: (Either (E.MathError) (Double))) >>= \_result250 -> pure(X.Scalar SDouble _result250)
    (64,[a0,a1,a2]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item251 -> X.asScalar item251) :: IO [(Double)])
        a1Value <- (LC.asMatrix a1 :: IO (M.Matrix (Double)))
        a2Value <- (asRNG a2 :: IO (R.RNG))
        source (P.sampleMultivariateNormal a0Value a1Value a2Value :: (Either (E.MathError) ([(Double)],(R.RNG)))) >>= \_result252 -> (\(part253,part254) -> X.Tuple <$> sequence [X.List <$> mapM (\item255 -> pure(X.Scalar SDouble item255)) part253,encodeRNG part254]) _result252
    (65,[a0,a1,a2]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (LC.asMatrix a1 :: IO (M.Matrix (Double)))
        a2Value <- (LC.asMatrix a2 :: IO (M.Matrix (Double)))
        source (P.wishartLogDensity a0Value a1Value a2Value :: (Either (E.MathError) (Double))) >>= \_result256 -> pure(X.Scalar SDouble _result256)
    (66,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (LC.asMatrix a1 :: IO (M.Matrix (Double)))
        a2Value <- (asRNG a2 :: IO (R.RNG))
        source (P.sampleWishart a0Value a1Value a2Value :: (Either (E.MathError) ((M.Matrix (Double)),(R.RNG)))) >>= \_result257 -> (\(part258,part259) -> X.Tuple <$> sequence [pure(X.Dense(X.SomeMatrix SDouble part258)),encodeRNG part259]) _result257
    (67,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item260 -> X.asList item260 >>= mapM (\item261 -> X.asScalar item261)) :: IO [[(Double)]])
        source (P.markov a0Value :: (Either (E.MathError) (P.Markov))) >>= \_result262 -> encodeMarkov _result262
    (68,[a0,a1]) -> do
        a0Value <- (unbox 244 a0 :: IO (P.Markov))
        a1Value <- (X.asList a1 >>= mapM (\item263 -> X.asScalar item263) :: IO [(Double)])
        source (P.transition a0Value a1Value :: (Either (E.MathError) [(Double)])) >>= \_result264 -> X.List <$> mapM (\item265 -> pure(X.Scalar SDouble item265)) _result264
    (69,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (unbox 244 a2 :: IO (P.Markov))
        source (P.stationary a0Value a1Value a2Value :: (Either (E.MathError) [(Double)])) >>= \_result266 -> X.List <$> mapM (\item267 -> pure(X.Scalar SDouble item267)) _result266
    (70,[a0,a1,a2]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item268 -> X.asScalar item268) :: IO [(Double)])
        a1Value <- (X.asList a1 >>= mapM (\item269 -> X.asList item269 >>= mapM (\item270 -> X.asScalar item270)) :: IO [[(Double)]])
        a2Value <- (X.asList a2 >>= mapM (\item271 -> X.asList item271 >>= mapM (\item272 -> X.asScalar item272)) :: IO [[(Double)]])
        source (P.hmm a0Value a1Value a2Value :: (Either (E.MathError) (P.HMM))) >>= \_result273 -> encodeHMM _result273
    (71,[a0,a1]) -> do
        a0Value <- (unbox 245 a0 :: IO (P.HMM))
        a1Value <- (X.asList a1 >>= mapM (\item274 -> X.asIndex item274) :: IO [(Int)])
        source (P.forward a0Value a1Value :: (Either (E.MathError) ((Double),[[(Double)]],[(Double)]))) >>= \_result275 -> (\(part276,part277,part278) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part276),X.List <$> mapM (\item279 -> X.List <$> mapM (\item280 -> pure(X.Scalar SDouble item280)) item279) part277,X.List <$> mapM (\item281 -> pure(X.Scalar SDouble item281)) part278]) _result275
    (72,[a0,a1]) -> do
        a0Value <- (unbox 245 a0 :: IO (P.HMM))
        a1Value <- (X.asList a1 >>= mapM (\item282 -> X.asIndex item282) :: IO [(Int)])
        source (P.backward a0Value a1Value :: (Either (E.MathError) [[(Double)]])) >>= \_result283 -> X.List <$> mapM (\item284 -> X.List <$> mapM (\item285 -> pure(X.Scalar SDouble item285)) item284) _result283
    (73,[a0,a1]) -> do
        a0Value <- (unbox 245 a0 :: IO (P.HMM))
        a1Value <- (X.asList a1 >>= mapM (\item286 -> X.asIndex item286) :: IO [(Int)])
        source (P.posteriorStates a0Value a1Value :: (Either (E.MathError) [[(Double)]])) >>= \_result287 -> X.List <$> mapM (\item288 -> X.List <$> mapM (\item289 -> pure(X.Scalar SDouble item289)) item288) _result287
    (74,[a0,a1]) -> do
        a0Value <- (unbox 245 a0 :: IO (P.HMM))
        a1Value <- (X.asList a1 >>= mapM (\item290 -> X.asIndex item290) :: IO [(Int)])
        source (P.viterbi a0Value a1Value :: (Either (E.MathError) ([(Int)],(Double)))) >>= \_result291 -> (\(part292,part293) -> X.Tuple <$> sequence [X.List <$> mapM (\item294 -> pure(X.Index item294)) part292,pure(X.Scalar SDouble part293)]) _result291
    (75,[a0,a1,a2,a3]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (unbox 245 a2 :: IO (P.HMM))
        a3Value <- (X.asList a3 >>= mapM (\item295 -> X.asIndex item295) :: IO [(Int)])
        source (P.baumWelch a0Value a1Value a2Value a3Value :: (Either (E.MathError) (P.HMM))) >>= \_result296 -> encodeHMM _result296
    (76,[a0]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        encodeDistribution (P.Bernoulli a0Value :: (P.Distribution))
    (77,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.Binomial a0Value a1Value :: (P.Distribution))
    (78,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.NegativeBinomial a0Value a1Value :: (P.Distribution))
    (79,[a0]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        encodeDistribution (P.Geometric a0Value :: (P.Distribution))
    (80,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asIndex a2 :: IO (Int))
        encodeDistribution (P.Hypergeometric a0Value a1Value a2Value :: (P.Distribution))
    (81,[a0]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        encodeDistribution (P.Poisson a0Value :: (P.Distribution))
    (82,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item297 -> X.asScalar item297) :: IO [(Double)])
        encodeDistribution (P.Categorical a0Value :: (P.Distribution))
    (83,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        encodeDistribution (P.DiscreteUniform a0Value a1Value :: (P.Distribution))
    (84,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.Uniform a0Value a1Value :: (P.Distribution))
    (85,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.Normal a0Value a1Value :: (P.Distribution))
    (86,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.LogNormal a0Value a1Value :: (P.Distribution))
    (87,[a0]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        encodeDistribution (P.Exponential a0Value :: (P.Distribution))
    (88,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.Gamma a0Value a1Value :: (P.Distribution))
    (89,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.Beta a0Value a1Value :: (P.Distribution))
    (90,[a0]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        encodeDistribution (P.ChiSquare a0Value :: (P.Distribution))
    (91,[a0]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        encodeDistribution (P.StudentT a0Value :: (P.Distribution))
    (92,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.FisherF a0Value a1Value :: (P.Distribution))
    (93,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.Cauchy a0Value a1Value :: (P.Distribution))
    (94,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.Laplace a0Value a1Value :: (P.Distribution))
    (95,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.Logistic a0Value a1Value :: (P.Distribution))
    (96,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.Weibull a0Value a1Value :: (P.Distribution))
    (97,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.Pareto a0Value a1Value :: (P.Distribution))
    (98,[a0]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        encodeDistribution (P.Rayleigh a0Value :: (P.Distribution))
    (99,[a0]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        encodeDistribution (P.Maxwell a0Value :: (P.Distribution))
    (100,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.Gumbel a0Value a1Value :: (P.Distribution))
    (101,[a0,a1,a2]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (X.asScalar a2 :: IO (Double))
        encodeDistribution (P.GeneralizedExtremeValue a0Value a1Value a2Value :: (P.Distribution))
    (102,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (X.asScalar a2 :: IO (Double))
        encodeDistribution (P.BetaBinomial a0Value a1Value a2Value :: (P.Distribution))
    (103,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.Skellam a0Value a1Value :: (P.Distribution))
    (104,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        encodeDistribution (P.VonMises a0Value a1Value :: (P.Distribution))
    (105,[a0,a1,a2]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (X.asScalar a2 :: IO (Double))
        encodeDistribution (P.Triangular a0Value a1Value a2Value :: (P.Distribution))
    (106,[a0,a1,a2,a3]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (X.asScalar a2 :: IO (Double))
        a3Value <- (X.asScalar a3 :: IO (Double))
        encodeDistribution (P.TruncatedNormal a0Value a1Value a2Value a3Value :: (P.Distribution))
    (107,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item298 -> (X.asTuple 2 item298 >>= \tuple301 -> case tuple301 of { [part299,part300] -> (,) <$> (X.asScalar part299) <*> (unbox 243 part300); _ -> X.invalid "tuple arity differs" })) :: IO [((Double),(P.Distribution))])
        encodeDistribution (P.Mixture a0Value :: (P.Distribution))
    (108,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item302 -> X.asScalar item302) :: IO [(Double)])
        encodeDistribution (P.Empirical a0Value :: (P.Distribution))
    (109,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asList a1 >>= mapM (\item303 -> X.asScalar item303) :: IO [(Double)])
        encodeDistribution (P.GaussianKDE a0Value a1Value :: (P.Distribution))
    (110,[a0,a1]) -> do
        a0Value <- (X.asBoolean a0 :: IO (Bool))
        a1Value <- (X.asList a1 >>= mapM (\item304 -> X.asList item304 >>= mapM (\item305 -> X.asScalar item305)) :: IO [[(Double)]])
        source (S.covarianceMatrix a0Value a1Value :: (Either (E.MathError) [[(Double)]])) >>= \_result306 -> X.List <$> mapM (\item307 -> X.List <$> mapM (\item308 -> pure(X.Scalar SDouble item308)) item307) _result306
    (111,[a0,a1,a2]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item309 -> X.asList item309 >>= mapM (\item310 -> X.asScalar item310)) :: IO [[(Double)]])
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asIndex a2 :: IO (Int))
        source (S.partialCorrelation a0Value a1Value a2Value :: (Either (E.MathError) (Double))) >>= \_result311 -> pure(X.Scalar SDouble _result311)
    (112,[]) -> do
        encodeStreaming (S.emptyStreaming  :: (S.Streaming))
    (113,[a0,a1]) -> do
        a0Value <- (unbox 246 a0 :: IO (S.Streaming))
        a1Value <- (X.asScalar a1 :: IO (Double))
        source (S.updateStreaming a0Value a1Value :: (Either (E.MathError) (S.Streaming))) >>= \_result312 -> encodeStreaming _result312
    (114,[a0,a1]) -> do
        a0Value <- (unbox 246 a0 :: IO (S.Streaming))
        a1Value <- (unbox 246 a1 :: IO (S.Streaming))
        source (S.combineStreaming a0Value a1Value :: (Either (E.MathError) (S.Streaming))) >>= \_result313 -> encodeStreaming _result313
    (115,[a0,a1]) -> do
        a0Value <- (X.asBoolean a0 :: IO (Bool))
        a1Value <- (unbox 246 a1 :: IO (S.Streaming))
        source (S.streamingResult a0Value a1Value :: (Either (E.MathError) ((Integer),(Double),(Double)))) >>= \_result314 -> (\(part315,part316,part317) -> X.Tuple <$> sequence [pure(X.Scalar SInteger part315),pure(X.Scalar SDouble part316),pure(X.Scalar SDouble part317)]) _result314
    (116,[a0,a1,a2]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item318 -> X.asList item318 >>= mapM (\item319 -> X.asScalar item319)) :: IO [[(Double)]])
        a1Value <- (X.asList a1 >>= mapM (\item320 -> X.asList item320 >>= mapM (\item321 -> X.asScalar item321)) :: IO [[(Double)]])
        a2Value <- (X.asList a2 >>= mapM (\item322 -> X.asScalar item322) :: IO [(Double)])
        source (S.histogramND a0Value a1Value a2Value :: (Either (E.MathError) [(Double)])) >>= \_result323 -> X.List <$> mapM (\item324 -> pure(X.Scalar SDouble item324)) _result323
    (117,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item325 -> X.asList item325 >>= mapM (\item326 -> X.asScalar item326)) :: IO [[(Double)]])
        source (S.mutualInformation a0Value :: (Either (E.MathError) (Double))) >>= \_result327 -> pure(X.Scalar SDouble _result327)
    (118,[a0,a1,a2,a3]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (pure (\parameter328 -> unsafePerformIO $ do { callbackArgs <- sequence [X.List <$> mapM (\item329 -> pure(X.Scalar SDouble item329)) parameter328]; let { callbackInput=X.Tuple callbackArgs }; checkedCallback a1 callbackInput (\reply -> X.asScalar reply) }) :: IO ([(Double)] -> (Either (E.MathError) (Double))))
        a2Value <- (X.asList a2 >>= mapM (\item330 -> X.asScalar item330) :: IO [(Double)])
        a3Value <- (asRNG a3 :: IO (R.RNG))
        source (S.bootstrap a0Value a1Value a2Value a3Value :: (Either (E.MathError) ([(Double)],(R.RNG)))) >>= \_result331 -> (\(part332,part333) -> X.Tuple <$> sequence [X.List <$> mapM (\item334 -> pure(X.Scalar SDouble item334)) part332,encodeRNG part333]) _result331
    (119,[a0,a1]) -> do
        a0Value <- (pure (\parameter335 -> unsafePerformIO $ do { callbackArgs <- sequence [X.List <$> mapM (\item336 -> pure(X.Scalar SDouble item336)) parameter335]; let { callbackInput=X.Tuple callbackArgs }; checkedCallback a0 callbackInput (\reply -> X.asScalar reply) }) :: IO ([(Double)] -> (Either (E.MathError) (Double))))
        a1Value <- (X.asList a1 >>= mapM (\item337 -> X.asScalar item337) :: IO [(Double)])
        source (S.jackknife a0Value a1Value :: (Either (E.MathError) ((Double),(Double)))) >>= \_result338 -> (\(part339,part340) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part339),pure(X.Scalar SDouble part340)]) _result338
    (120,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asList a1 >>= mapM (\item341 -> X.asScalar item341) :: IO [(Double)])
        source (S.oneSampleT a0Value a1Value :: (Either (E.MathError) (S.TestResult))) >>= \_result342 -> encodeTestResult _result342
    (121,[a0,a1,a2]) -> do
        a0Value <- (X.asBoolean a0 :: IO (Bool))
        a1Value <- (X.asList a1 >>= mapM (\item343 -> X.asScalar item343) :: IO [(Double)])
        a2Value <- (X.asList a2 >>= mapM (\item344 -> X.asScalar item344) :: IO [(Double)])
        source (S.twoSampleT a0Value a1Value a2Value :: (Either (E.MathError) (S.TestResult))) >>= \_result345 -> encodeTestResult _result345
    (122,[a0,a1]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item346 -> X.asScalar item346) :: IO [(Double)])
        a1Value <- (X.asList a1 >>= mapM (\item347 -> X.asScalar item347) :: IO [(Double)])
        source (S.pairedT a0Value a1Value :: (Either (E.MathError) (S.TestResult))) >>= \_result348 -> encodeTestResult _result348
    (123,[a0,a1,a2]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (X.asList a2 >>= mapM (\item349 -> X.asScalar item349) :: IO [(Double)])
        source (S.zTest a0Value a1Value a2Value :: (Either (E.MathError) (S.TestResult))) >>= \_result350 -> encodeTestResult _result350
    (124,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asList a1 >>= mapM (\item351 -> X.asScalar item351) :: IO [(Double)])
        a2Value <- (X.asList a2 >>= mapM (\item352 -> X.asScalar item352) :: IO [(Double)])
        source (S.chiSquareTest a0Value a1Value a2Value :: (Either (E.MathError) (S.TestResult))) >>= \_result353 -> encodeTestResult _result353
    (125,[a0,a1]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item354 -> X.asScalar item354) :: IO [(Double)])
        a1Value <- (X.asList a1 >>= mapM (\item355 -> X.asScalar item355) :: IO [(Double)])
        source (S.varianceFTest a0Value a1Value :: (Either (E.MathError) (S.TestResult))) >>= \_result356 -> encodeTestResult _result356
    (126,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item357 -> X.asList item357 >>= mapM (\item358 -> X.asScalar item358)) :: IO [[(Double)]])
        source (S.anova a0Value :: (Either (E.MathError) (S.TestResult))) >>= \_result359 -> encodeTestResult _result359
    (127,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item360 -> X.asList item360 >>= mapM (\item361 -> X.asScalar item361)) :: IO [[(Double)]])
        source (S.welchAnova a0Value :: (Either (E.MathError) (S.TestResult))) >>= \_result362 -> encodeTestResult _result362
    (128,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item363 -> X.asList item363 >>= mapM (\item364 -> X.asScalar item364)) :: IO [[(Double)]])
        source (S.kruskalWallis a0Value :: (Either (E.MathError) (S.TestResult))) >>= \_result365 -> encodeTestResult _result365
    (129,[a0,a1]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item366 -> X.asScalar item366) :: IO [(Double)])
        a1Value <- (X.asList a1 >>= mapM (\item367 -> X.asScalar item367) :: IO [(Double)])
        source (S.mannWhitney a0Value a1Value :: (Either (E.MathError) (S.TestResult))) >>= \_result368 -> encodeTestResult _result368
    (130,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item369 -> X.asScalar item369) :: IO [(Double)])
        source (S.wilcoxon a0Value :: (Either (E.MathError) (S.TestResult))) >>= \_result370 -> encodeTestResult _result370
    (131,[a0,a1]) -> do
        a0Value <- (unbox 243 a0 :: IO (P.Distribution))
        a1Value <- (X.asList a1 >>= mapM (\item371 -> X.asScalar item371) :: IO [(Double)])
        source (S.kolmogorovSmirnov a0Value a1Value :: (Either (E.MathError) (S.TestResult))) >>= \_result372 -> encodeTestResult _result372
    (132,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item373 -> X.asScalar item373) :: IO [(Double)])
        source (S.shapiroWilk a0Value :: (Either (E.MathError) (S.TestResult))) >>= \_result374 -> encodeTestResult _result374
    (133,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item375 -> X.asScalar item375) :: IO [(Double)])
        source (S.andersonDarling a0Value :: (Either (E.MathError) (S.TestResult))) >>= \_result376 -> encodeTestResult _result376
    (134,[a0,a1]) -> do
        a0Value <- (X.asBoolean a0 :: IO (Bool))
        a1Value <- (X.asList a1 >>= mapM (\item377 -> X.asList item377 >>= mapM (\item378 -> X.asScalar item378)) :: IO [[(Double)]])
        source (S.levene a0Value a1Value :: (Either (E.MathError) (S.TestResult))) >>= \_result379 -> encodeTestResult _result379
    (135,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item380 -> X.asList item380 >>= mapM (\item381 -> X.asScalar item381)) :: IO [[(Double)]])
        source (S.bartlett a0Value :: (Either (E.MathError) (S.TestResult))) >>= \_result382 -> encodeTestResult _result382
    (136,[a0,a1,a2,a3]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asIndex a2 :: IO (Int))
        a3Value <- (X.asIndex a3 :: IO (Int))
        source (S.fisherExact a0Value a1Value a2Value a3Value :: (Either (E.MathError) (S.TestResult))) >>= \_result383 -> encodeTestResult _result383
    (137,[a0,a1,a2,a3,a4]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (pure (\parameter384 parameter385 -> unsafePerformIO $ do { callbackArgs <- sequence [X.List <$> mapM (\item386 -> pure(X.Scalar SDouble item386)) parameter384,X.List <$> mapM (\item387 -> pure(X.Scalar SDouble item387)) parameter385]; let { callbackInput=X.Tuple callbackArgs }; checkedCallback a1 callbackInput (\reply -> X.asScalar reply) }) :: IO ([(Double)] -> [(Double)] -> (Either (E.MathError) (Double))))
        a2Value <- (X.asList a2 >>= mapM (\item388 -> X.asScalar item388) :: IO [(Double)])
        a3Value <- (X.asList a3 >>= mapM (\item389 -> X.asScalar item389) :: IO [(Double)])
        a4Value <- (asRNG a4 :: IO (R.RNG))
        source (S.permutationTest a0Value a1Value a2Value a3Value a4Value :: (Either (E.MathError) ((S.TestResult),(R.RNG)))) >>= \_result390 -> (\(part391,part392) -> X.Tuple <$> sequence [encodeTestResult part391,encodeRNG part392]) _result390
    (138,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item393 -> X.asList item393 >>= mapM (\item394 -> X.asScalar item394)) :: IO [[(Double)]])
        source (S.etaSquared a0Value :: (Either (E.MathError) (Double))) >>= \_result395 -> pure(X.Scalar SDouble _result395)
    (139,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asList a1 >>= mapM (\item396 -> X.asScalar item396) :: IO [(Double)])
        source (S.grubbs a0Value a1Value :: (Either (E.MathError) ((Int),(Double),(Bool)))) >>= \_result397 -> (\(part398,part399,part400) -> X.Tuple <$> sequence [pure(X.Index part398),pure(X.Scalar SDouble part399),pure(X.Boolean part400)]) _result397
    (140,[a0,a1]) -> do
        a0Value <- (X.asList a0 >>= mapM (\item401 -> X.asBoolean item401) :: IO [(Bool)])
        a1Value <- (X.asList a1 >>= mapM (\item402 -> X.asScalar item402) :: IO [(Double)])
        source (S.masked a0Value a1Value :: (Either (E.MathError) [(Double)])) >>= \_result403 -> X.List <$> mapM (\item404 -> pure(X.Scalar SDouble item404)) _result403
    (141,[a0]) -> do
        a0Value <- (unbox 247 a0 :: IO (S.TestResult))
        pure(X.Scalar SDouble (S.testStatistic a0Value :: (Double)))
    (142,[a0]) -> do
        a0Value <- (unbox 247 a0 :: IO (S.TestResult))
        pure(X.Scalar SDouble (S.pValue a0Value :: (Double)))
    (143,[a0]) -> do
        a0Value <- (unbox 247 a0 :: IO (S.TestResult))
        X.List <$> mapM (\item405 -> pure(X.Scalar SDouble item405)) (S.degreesOfFreedom a0Value :: [(Double)])
    (144,[a0,a1,a2]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (X.asList a2 >>= mapM (\item406 -> X.asScalar item406) :: IO [(Double)])
        encodeTestResult (S.TestResult a0Value a1Value a2Value :: (S.TestResult))
    (-1,[value]) -> case X.valueInfo value of
        (241,_,_) -> do
            object <- (unbox 241 value :: IO R.Generator)
            case object of
                R.PCG32  -> do
                    values <- sequence []
                    pure(X.Tuple[X.Text "PCG32",X.Tuple values])
                R.Xoshiro256StarStar  -> do
                    values <- sequence []
                    pure(X.Tuple[X.Text "Xoshiro256StarStar",X.Tuple values])
                R.Xoroshiro128Plus  -> do
                    values <- sequence []
                    pure(X.Tuple[X.Text "Xoroshiro128Plus",X.Tuple values])
                R.MT19937  -> do
                    values <- sequence []
                    pure(X.Tuple[X.Text "MT19937",X.Tuple values])
                R.Philox4x32  -> do
                    values <- sequence []
                    pure(X.Tuple[X.Text "Philox4x32",X.Tuple values])
                R.Threefry2x64  -> do
                    values <- sequence []
                    pure(X.Tuple[X.Text "Threefry2x64",X.Tuple values])
                R.ChaCha20  -> do
                    values <- sequence []
                    pure(X.Tuple[X.Text "ChaCha20",X.Tuple values])
        (240,_,_) -> do
            X.unsupported "original abstract type has no public constructor fields"
        (242,_,_) -> do
            X.unsupported "original abstract type has no public constructor fields"
        (243,_,_) -> do
            object <- (unbox 243 value :: IO P.Distribution)
            case object of
                P.Bernoulli field407 -> do
                    values <- sequence [pure(X.Scalar SDouble field407)]
                    pure(X.Tuple[X.Text "Bernoulli",X.Tuple values])
                P.Binomial field408 field409 -> do
                    values <- sequence [pure(X.Index field408),pure(X.Scalar SDouble field409)]
                    pure(X.Tuple[X.Text "Binomial",X.Tuple values])
                P.NegativeBinomial field410 field411 -> do
                    values <- sequence [pure(X.Scalar SDouble field410),pure(X.Scalar SDouble field411)]
                    pure(X.Tuple[X.Text "NegativeBinomial",X.Tuple values])
                P.Geometric field412 -> do
                    values <- sequence [pure(X.Scalar SDouble field412)]
                    pure(X.Tuple[X.Text "Geometric",X.Tuple values])
                P.Hypergeometric field413 field414 field415 -> do
                    values <- sequence [pure(X.Index field413),pure(X.Index field414),pure(X.Index field415)]
                    pure(X.Tuple[X.Text "Hypergeometric",X.Tuple values])
                P.Poisson field416 -> do
                    values <- sequence [pure(X.Scalar SDouble field416)]
                    pure(X.Tuple[X.Text "Poisson",X.Tuple values])
                P.Categorical field417 -> do
                    values <- sequence [X.List <$> mapM (\item418 -> pure(X.Scalar SDouble item418)) field417]
                    pure(X.Tuple[X.Text "Categorical",X.Tuple values])
                P.DiscreteUniform field419 field420 -> do
                    values <- sequence [pure(X.Index field419),pure(X.Index field420)]
                    pure(X.Tuple[X.Text "DiscreteUniform",X.Tuple values])
                P.Uniform field421 field422 -> do
                    values <- sequence [pure(X.Scalar SDouble field421),pure(X.Scalar SDouble field422)]
                    pure(X.Tuple[X.Text "Uniform",X.Tuple values])
                P.Normal field423 field424 -> do
                    values <- sequence [pure(X.Scalar SDouble field423),pure(X.Scalar SDouble field424)]
                    pure(X.Tuple[X.Text "Normal",X.Tuple values])
                P.LogNormal field425 field426 -> do
                    values <- sequence [pure(X.Scalar SDouble field425),pure(X.Scalar SDouble field426)]
                    pure(X.Tuple[X.Text "LogNormal",X.Tuple values])
                P.Exponential field427 -> do
                    values <- sequence [pure(X.Scalar SDouble field427)]
                    pure(X.Tuple[X.Text "Exponential",X.Tuple values])
                P.Gamma field428 field429 -> do
                    values <- sequence [pure(X.Scalar SDouble field428),pure(X.Scalar SDouble field429)]
                    pure(X.Tuple[X.Text "Gamma",X.Tuple values])
                P.Beta field430 field431 -> do
                    values <- sequence [pure(X.Scalar SDouble field430),pure(X.Scalar SDouble field431)]
                    pure(X.Tuple[X.Text "Beta",X.Tuple values])
                P.ChiSquare field432 -> do
                    values <- sequence [pure(X.Scalar SDouble field432)]
                    pure(X.Tuple[X.Text "ChiSquare",X.Tuple values])
                P.StudentT field433 -> do
                    values <- sequence [pure(X.Scalar SDouble field433)]
                    pure(X.Tuple[X.Text "StudentT",X.Tuple values])
                P.FisherF field434 field435 -> do
                    values <- sequence [pure(X.Scalar SDouble field434),pure(X.Scalar SDouble field435)]
                    pure(X.Tuple[X.Text "FisherF",X.Tuple values])
                P.Cauchy field436 field437 -> do
                    values <- sequence [pure(X.Scalar SDouble field436),pure(X.Scalar SDouble field437)]
                    pure(X.Tuple[X.Text "Cauchy",X.Tuple values])
                P.Laplace field438 field439 -> do
                    values <- sequence [pure(X.Scalar SDouble field438),pure(X.Scalar SDouble field439)]
                    pure(X.Tuple[X.Text "Laplace",X.Tuple values])
                P.Logistic field440 field441 -> do
                    values <- sequence [pure(X.Scalar SDouble field440),pure(X.Scalar SDouble field441)]
                    pure(X.Tuple[X.Text "Logistic",X.Tuple values])
                P.Weibull field442 field443 -> do
                    values <- sequence [pure(X.Scalar SDouble field442),pure(X.Scalar SDouble field443)]
                    pure(X.Tuple[X.Text "Weibull",X.Tuple values])
                P.Pareto field444 field445 -> do
                    values <- sequence [pure(X.Scalar SDouble field444),pure(X.Scalar SDouble field445)]
                    pure(X.Tuple[X.Text "Pareto",X.Tuple values])
                P.Rayleigh field446 -> do
                    values <- sequence [pure(X.Scalar SDouble field446)]
                    pure(X.Tuple[X.Text "Rayleigh",X.Tuple values])
                P.Maxwell field447 -> do
                    values <- sequence [pure(X.Scalar SDouble field447)]
                    pure(X.Tuple[X.Text "Maxwell",X.Tuple values])
                P.Gumbel field448 field449 -> do
                    values <- sequence [pure(X.Scalar SDouble field448),pure(X.Scalar SDouble field449)]
                    pure(X.Tuple[X.Text "Gumbel",X.Tuple values])
                P.GeneralizedExtremeValue field450 field451 field452 -> do
                    values <- sequence [pure(X.Scalar SDouble field450),pure(X.Scalar SDouble field451),pure(X.Scalar SDouble field452)]
                    pure(X.Tuple[X.Text "GeneralizedExtremeValue",X.Tuple values])
                P.BetaBinomial field453 field454 field455 -> do
                    values <- sequence [pure(X.Index field453),pure(X.Scalar SDouble field454),pure(X.Scalar SDouble field455)]
                    pure(X.Tuple[X.Text "BetaBinomial",X.Tuple values])
                P.Skellam field456 field457 -> do
                    values <- sequence [pure(X.Scalar SDouble field456),pure(X.Scalar SDouble field457)]
                    pure(X.Tuple[X.Text "Skellam",X.Tuple values])
                P.VonMises field458 field459 -> do
                    values <- sequence [pure(X.Scalar SDouble field458),pure(X.Scalar SDouble field459)]
                    pure(X.Tuple[X.Text "VonMises",X.Tuple values])
                P.Triangular field460 field461 field462 -> do
                    values <- sequence [pure(X.Scalar SDouble field460),pure(X.Scalar SDouble field461),pure(X.Scalar SDouble field462)]
                    pure(X.Tuple[X.Text "Triangular",X.Tuple values])
                P.TruncatedNormal field463 field464 field465 field466 -> do
                    values <- sequence [pure(X.Scalar SDouble field463),pure(X.Scalar SDouble field464),pure(X.Scalar SDouble field465),pure(X.Scalar SDouble field466)]
                    pure(X.Tuple[X.Text "TruncatedNormal",X.Tuple values])
                P.Mixture field467 -> do
                    values <- sequence [X.List <$> mapM (\item468 -> (\(part469,part470) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part469),encodeDistribution part470]) item468) field467]
                    pure(X.Tuple[X.Text "Mixture",X.Tuple values])
                P.Empirical field471 -> do
                    values <- sequence [X.List <$> mapM (\item472 -> pure(X.Scalar SDouble item472)) field471]
                    pure(X.Tuple[X.Text "Empirical",X.Tuple values])
                P.GaussianKDE field473 field474 -> do
                    values <- sequence [pure(X.Scalar SDouble field473),X.List <$> mapM (\item475 -> pure(X.Scalar SDouble item475)) field474]
                    pure(X.Tuple[X.Text "GaussianKDE",X.Tuple values])
        (244,_,_) -> do
            X.unsupported "original abstract type has no public constructor fields"
        (245,_,_) -> do
            X.unsupported "original abstract type has no public constructor fields"
        (246,_,_) -> do
            X.unsupported "original abstract type has no public constructor fields"
        (247,_,_) -> do
            object <- (unbox 247 value :: IO S.TestResult)
            case object of
                S.TestResult field476 field477 field478 -> do
                    values <- sequence [pure(X.Scalar SDouble field476),pure(X.Scalar SDouble field477),X.List <$> mapM (\item479 -> pure(X.Scalar SDouble item479)) field478]
                    pure(X.Tuple[X.Text "TestResult",X.Tuple values])
        _ -> X.invalid "expected stochastic object"
    (-2,[left,right]) -> case(X.valueInfo left,X.valueInfo right) of
        ((241,_,_),(241,_,_)) -> do
            a <- (unbox 241 left :: IO R.Generator); b <- unbox 241 right
            pure(X.Boolean(a==b))
        ((240,_,_),(240,_,_)) -> do
            a <- (asRNG left :: IO R.RNG); b <- asRNG right
            pure(X.Boolean(a==b))
        ((242,_,_),(242,_,_)) -> do
            a <- (unbox 242 left :: IO R.AliasTable); b <- unbox 242 right
            pure(X.Boolean(a==b))
        ((243,_,_),(243,_,_)) -> do
            a <- (unbox 243 left :: IO P.Distribution); b <- unbox 243 right
            pure(X.Boolean(a==b))
        ((244,_,_),(244,_,_)) -> do
            a <- (unbox 244 left :: IO P.Markov); b <- unbox 244 right
            pure(X.Boolean(a==b))
        ((245,_,_),(245,_,_)) -> do
            a <- (unbox 245 left :: IO P.HMM); b <- unbox 245 right
            pure(X.Boolean(a==b))
        ((246,_,_),(246,_,_)) -> do
            a <- (unbox 246 left :: IO S.Streaming); b <- unbox 246 right
            pure(X.Boolean(a==b))
        ((247,_,_),(247,_,_)) -> do
            a <- (unbox 247 left :: IO S.TestResult); b <- unbox 247 right
            pure(X.Boolean(a==b))
        _ -> X.invalid "stochastic equality requires matching types"
    _ -> X.invalid "invalid stochastic operation/arity"
foreign export ccall "hm_stochastic_apply" ffiApply :: CInt -> Ptr(StablePtr X.Value) -> CSize -> Ptr(StablePtr X.Value) -> IO CInt
ffiApply :: CInt -> Ptr(StablePtr X.Value) -> CSize -> Ptr(StablePtr X.Value) -> IO CInt
ffiApply operation pointers count out=stochasticBoundary $ do
    values <- peekArray(fromIntegral count) pointers >>= mapM deRefStablePtr
    value <- apply(fromIntegral operation) values
    Boundary.checked(Right())(const(X.publish value out))
