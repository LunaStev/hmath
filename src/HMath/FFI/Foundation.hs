{-# LANGUAGE GADTs #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ForeignFunctionInterface #-}
-- SPDX-License-Identifier: MPL-2.0
-- Generated original-operation adapters. No algorithm implementation here.
module HMath.FFI.Foundation where
import Control.Exception (evaluate)
import Foreign
import Foreign.C
import System.IO.Unsafe (unsafePerformIO)
import qualified HMath.Error as E
import HMath.FFI.Coefficient
import HMath.FFI.FoundationCodec
import HMath.FFI.Ordering
import qualified HMath.FFI.LinearCodec as LC
import qualified HMath.FFI.Value as X
import qualified HMath.FFI.Boundary as Boundary
import qualified HMath.DataStructure as D
import qualified HMath.Discrete as S
import qualified HMath.Algorithms as A
import qualified HMath.Combinatorics as C
import qualified HMath.API.Convergence as V

encodeFenwick :: (D.Fenwick) -> IO X.Value
encodeFenwick value=pure(opaqueEq "HMath.DataStructure.Fenwick" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=X.unsupported "original abstract type has no public constructor fields"

encodeSegmentTree :: (D.SegmentTree) -> IO X.Value
encodeSegmentTree value=pure(opaqueEq "HMath.DataStructure.SegmentTree" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=X.unsupported "original abstract type has no public constructor fields"

encodeSparseTable :: (D.SparseTable) -> IO X.Value
encodeSparseTable value=pure(opaqueEq "HMath.DataStructure.SparseTable" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=X.unsupported "original abstract type has no public constructor fields"

encodeDisjointSparseTable :: (D.DisjointSparseTable) -> IO X.Value
encodeDisjointSparseTable value=pure(opaqueEq "HMath.DataStructure.DisjointSparseTable" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=X.unsupported "original abstract type has no public constructor fields"

encodeHeap :: HeapState -> IO X.Value
encodeHeap value=pure(opaqueEq "HMath.DataStructure.Heap" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=X.unsupported "original abstract type has no public constructor fields"

encodeBinaryHeap :: (D.BinaryHeap) -> IO X.Value
encodeBinaryHeap value=pure(opaqueEq "HMath.DataStructure.BinaryHeap" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=X.unsupported "original abstract type has no public constructor fields"

encodeIndexedHeap :: (D.IndexedHeap) -> IO X.Value
encodeIndexedHeap value=pure(opaqueEq "HMath.DataStructure.IndexedHeap" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=X.unsupported "original abstract type has no public constructor fields"

encodeUnionFind :: (D.UnionFind) -> IO X.Value
encodeUnionFind value=pure(opaqueEq "HMath.DataStructure.UnionFind" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=X.unsupported "original abstract type has no public constructor fields"

encodeBloom :: (D.Bloom) -> IO X.Value
encodeBloom value=pure(opaqueEq "HMath.DataStructure.Bloom" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=X.unsupported "original abstract type has no public constructor fields"

encodeCountMin :: (D.CountMin) -> IO X.Value
encodeCountMin value=pure(opaqueEq "HMath.DataStructure.CountMin" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=X.unsupported "original abstract type has no public constructor fields"

encodeHyperLogLog :: (D.HyperLogLog) -> IO X.Value
encodeHyperLogLog value=pure(opaqueEq "HMath.DataStructure.HyperLogLog" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=X.unsupported "original abstract type has no public constructor fields"

encodeReservoir :: (D.Reservoir EqualityValue) -> IO X.Value
encodeReservoir value=pure(opaqueEq "HMath.DataStructure.Reservoir" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=X.unsupported "original abstract type has no public constructor fields"

encodeOnlineQuantiles :: (D.OnlineQuantiles) -> IO X.Value
encodeOnlineQuantiles value=pure(opaqueEq "HMath.DataStructure.OnlineQuantiles" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=X.unsupported "original abstract type has no public constructor fields"

encodeMultiSet :: MultiState -> IO X.Value
encodeMultiSet value=pure(opaqueEq "HMath.Discrete.MultiSet" (-1) value force view)
  where
    force=multisetEntries value >>= \xs -> forceFields [X.List <$>mapM(\item1 -> (\(part2,part3) -> X.Tuple <$> sequence [pure part2,pure(X.Scalar SInteger part3)]) item1) xs]
    view=X.unsupported "original abstract type has no public constructor fields"

encodeBitSet :: (S.BitSet) -> IO X.Value
encodeBitSet value=pure(opaqueEq "HMath.Discrete.BitSet" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=X.unsupported "original abstract type has no public constructor fields"

encodeProp :: (S.Prop) -> IO X.Value
encodeProp value=pure(opaqueEq "HMath.Discrete.Prop" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=case value of
        S.Literal field4 -> do
            values <- sequence [pure(X.Boolean field4)]
            pure(X.Tuple[X.Text "Literal",X.Tuple values])
        S.Variable field5 -> do
            values <- sequence [pure(X.Index field5)]
            pure(X.Tuple[X.Text "Variable",X.Tuple values])
        S.Not field6 -> do
            values <- sequence [encodeProp field6]
            pure(X.Tuple[X.Text "Not",X.Tuple values])
        S.And field7 field8 -> do
            values <- sequence [encodeProp field7,encodeProp field8]
            pure(X.Tuple[X.Text "And",X.Tuple values])
        S.Or field9 field10 -> do
            values <- sequence [encodeProp field9,encodeProp field10]
            pure(X.Tuple[X.Text "Or",X.Tuple values])
        S.Xor field11 field12 -> do
            values <- sequence [encodeProp field11,encodeProp field12]
            pure(X.Tuple[X.Text "Xor",X.Tuple values])
        S.Implies field13 field14 -> do
            values <- sequence [encodeProp field13,encodeProp field14]
            pure(X.Tuple[X.Text "Implies",X.Tuple values])
        S.Iff field15 field16 -> do
            values <- sequence [encodeProp field15,encodeProp field16]
            pure(X.Tuple[X.Text "Iff",X.Tuple values])

encodeImplicant :: (S.Implicant) -> IO X.Value
encodeImplicant value=pure(opaqueEq "HMath.Discrete.Implicant" (-1) value force view)
  where
    force=forceFields [pure(X.Scalar SInteger (S.implicantValue value)),pure(X.Scalar SInteger (S.implicantMask value))]
    view=case value of
        S.Implicant field17 field18 -> do
            values <- sequence [pure(X.Scalar SInteger field17),pure(X.Scalar SInteger field18)]
            pure(X.Tuple[X.Text "Implicant",X.Tuple values])

encodeStopReason :: (V.StopReason) -> IO X.Value
encodeStopReason value=pure(opaqueEq "HMath.API.Convergence.StopReason" (-1) value force view)
  where
    force=evaluate value >> pure()
    view=case value of
        V.ResidualSatisfied  -> do
            values <- sequence []
            pure(X.Tuple[X.Text "ResidualSatisfied",X.Tuple values])
        V.IterationLimit  -> do
            values <- sequence []
            pure(X.Tuple[X.Text "IterationLimit",X.Tuple values])
        V.Stagnation  -> do
            values <- sequence []
            pure(X.Tuple[X.Text "Stagnation",X.Tuple values])

encodeConvergence :: (V.Convergence EqualityValue) -> IO X.Value
encodeConvergence value=pure(opaqueEq "HMath.API.Convergence.Convergence" (-1) value force view)
  where
    force=forceFields [writeEquality (V.estimate value),pure(X.Index (V.iterationCount value)),pure(X.Scalar SDouble (V.finalResidual value)),encodeStopReason (V.stopReason value)]
    view=case value of
        V.Convergence field19 field20 field21 field22 -> do
            values <- sequence [writeEquality field19,pure(X.Index field20),pure(X.Scalar SDouble field21),encodeStopReason field22]
            pure(X.Tuple[X.Text "Convergence",X.Tuple values])

encodeIterationOptions :: (V.IterationOptions) -> IO X.Value
encodeIterationOptions value=pure(opaqueEq "HMath.API.Convergence.IterationOptions" (-1) value force view)
  where
    force=forceFields [pure(X.Index (V.maximumIterations value)),pure(X.Scalar SDouble (V.absoluteTolerance value)),pure(X.Scalar SDouble (V.relativeTolerance value))]
    view=case value of
        V.IterationOptions field23 field24 field25 -> do
            values <- sequence [pure(X.Index field23),pure(X.Scalar SDouble field24),pure(X.Scalar SDouble field25)]
            pure(X.Tuple[X.Text "IterationOptions",X.Tuple values])

apply :: Int -> [X.Value] -> IO X.Value
apply operation args=case(operation,args) of
    (0,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item26 -> X.asScalar item26) :: IO [(Integer)])
        source ((D.fenwick a0Value) :: (Either (E.MathError) (D.Fenwick))) >>= \_result27 -> encodeFenwick _result27
    (1,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asScalar a1 :: IO (Integer))
        a2Value <- (unbox "HMath.DataStructure.Fenwick" a2 :: IO (D.Fenwick))
        source ((D.fenwickAdd a0Value a1Value a2Value) :: (Either (E.MathError) (D.Fenwick))) >>= \_result28 -> encodeFenwick _result28
    (2,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (unbox "HMath.DataStructure.Fenwick" a1 :: IO (D.Fenwick))
        source ((D.fenwickPrefix a0Value a1Value) :: (Either (E.MathError) (Integer))) >>= \_result29 -> pure(X.Scalar SInteger _result29)
    (3,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (unbox "HMath.DataStructure.Fenwick" a2 :: IO (D.Fenwick))
        source ((D.fenwickRange a0Value a1Value a2Value) :: (Either (E.MathError) (Integer))) >>= \_result30 -> pure(X.Scalar SInteger _result30)
    (4,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item31 -> X.asScalar item31) :: IO [(Integer)])
        source ((D.segmentTree a0Value) :: (Either (E.MathError) (D.SegmentTree))) >>= \_result32 -> encodeSegmentTree _result32
    (5,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asScalar a1 :: IO (Integer))
        a2Value <- (unbox "HMath.DataStructure.SegmentTree" a2 :: IO (D.SegmentTree))
        source ((D.segmentSet a0Value a1Value a2Value) :: (Either (E.MathError) (D.SegmentTree))) >>= \_result33 -> encodeSegmentTree _result33
    (6,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (unbox "HMath.DataStructure.SegmentTree" a2 :: IO (D.SegmentTree))
        source ((D.segmentRange a0Value a1Value a2Value) :: (Either (E.MathError) (Integer))) >>= \_result34 -> pure(X.Scalar SInteger _result34)
    (7,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item35 -> X.asScalar item35) :: IO [(Integer)])
        source ((D.sparseTable a0Value) :: (Either (E.MathError) (D.SparseTable))) >>= \_result36 -> encodeSparseTable _result36
    (8,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (unbox "HMath.DataStructure.SparseTable" a2 :: IO (D.SparseTable))
        source ((D.sparseMinimum a0Value a1Value a2Value) :: (Either (E.MathError) (Integer))) >>= \_result37 -> pure(X.Scalar SInteger _result37)
    (9,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item38 -> X.asScalar item38) :: IO [(Integer)])
        source ((D.disjointSparseTable a0Value) :: (Either (E.MathError) (D.DisjointSparseTable))) >>= \_result39 -> encodeDisjointSparseTable _result39
    (10,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (unbox "HMath.DataStructure.DisjointSparseTable" a2 :: IO (D.DisjointSparseTable))
        source ((D.disjointRange a0Value a1Value a2Value) :: (Either (E.MathError) (Integer))) >>= \_result40 -> pure(X.Scalar SInteger _result40)
    (11,[a0]) -> do
        examples <- concat <$> sequence [X.asList a0]
        witness <- if null examples then orderedFromPrototype(X.Scalar SInteger 0) else orderedWith [foundationOrdering] examples
        a0Value <- (X.asList a0 >>= mapM(\item41 -> readOrdered witness item41) :: IO [OrderedValue])
        X.List <$>mapM(\item42 -> (case item42 of {Nothing -> pure X.None;Just item43 -> pure(X.Index item43) >>= maybeValue . Just})) ((D.nextGreater a0Value) :: [(Maybe (Int))])
    (12,[]) -> do
        (pure heapEmpty) >>= \result -> encodeHeap result
    (13,[a0,a1]) -> do
        a0Value <- (pure a0 :: IO X.Value)
        a1Value <- (unbox "HMath.DataStructure.Heap" a1 :: IO HeapState)
        (heapInsert a0Value a1Value) >>= \result -> encodeHeap result
    (14,[a0]) -> do
        a0Value <- (unbox "HMath.DataStructure.Heap" a0 :: IO HeapState)
        (heapPop a0Value) >>= \result -> (case result of {Nothing -> pure X.None;Just item44 -> (\(part45,part46) -> X.Tuple <$> sequence [pure part45,encodeHeap part46]) item44 >>= maybeValue . Just})
    (15,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item47 -> pure item47) :: IO [X.Value])
        (heapFromList a0Value) >>= \result -> encodeHeap result
    (16,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item48 -> X.asScalar item48) :: IO [(Integer)])
        source ((D.binaryHeap a0Value) :: (Either (E.MathError) (D.BinaryHeap))) >>= \_result49 -> encodeBinaryHeap _result49
    (17,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Integer))
        a1Value <- (unbox "HMath.DataStructure.BinaryHeap" a1 :: IO (D.BinaryHeap))
        encodeBinaryHeap ((D.binaryInsert a0Value a1Value) :: (D.BinaryHeap))
    (18,[a0]) -> do
        a0Value <- (unbox "HMath.DataStructure.BinaryHeap" a0 :: IO (D.BinaryHeap))
        (case ((D.binaryPop a0Value) :: (Maybe ((Integer),(D.BinaryHeap)))) of {Nothing -> pure X.None;Just item50 -> (\(part51,part52) -> X.Tuple <$> sequence [pure(X.Scalar SInteger part51),encodeBinaryHeap part52]) item50 >>= maybeValue . Just})
    (19,[]) -> do
        encodeIndexedHeap ((D.indexedHeap ) :: (D.IndexedHeap))
    (20,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asScalar a1 :: IO (Integer))
        a2Value <- (unbox "HMath.DataStructure.IndexedHeap" a2 :: IO (D.IndexedHeap))
        encodeIndexedHeap ((D.indexedSet a0Value a1Value a2Value) :: (D.IndexedHeap))
    (21,[a0]) -> do
        a0Value <- (unbox "HMath.DataStructure.IndexedHeap" a0 :: IO (D.IndexedHeap))
        (case ((D.indexedPop a0Value) :: (Maybe (((Int),(Integer)),(D.IndexedHeap)))) of {Nothing -> pure X.None;Just item53 -> (\(part54,part55) -> X.Tuple <$> sequence [(\(part56,part57) -> X.Tuple <$> sequence [pure(X.Index part56),pure(X.Scalar SInteger part57)]) part54,encodeIndexedHeap part55]) item53 >>= maybeValue . Just})
    (22,[a0]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        source ((D.unionFind a0Value) :: (Either (E.MathError) (D.UnionFind))) >>= \_result58 -> encodeUnionFind _result58
    (23,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (unbox "HMath.DataStructure.UnionFind" a1 :: IO (D.UnionFind))
        source ((D.findRoot a0Value a1Value) :: (Either (E.MathError) (Int))) >>= \_result59 -> pure(X.Index _result59)
    (24,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (unbox "HMath.DataStructure.UnionFind" a2 :: IO (D.UnionFind))
        source ((D.union a0Value a1Value a2Value) :: (Either (E.MathError) (D.UnionFind))) >>= \_result60 -> encodeUnionFind _result60
    (25,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (unbox "HMath.DataStructure.UnionFind" a2 :: IO (D.UnionFind))
        source ((D.connected a0Value a1Value a2Value) :: (Either (E.MathError) (Bool))) >>= \_result61 -> pure(X.Boolean _result61)
    (26,[a0]) -> do
        a0Value <- (unbox "HMath.DataStructure.UnionFind" a0 :: IO (D.UnionFind))
        X.List <$>mapM(\item62 -> X.List <$>mapM(\item63 -> pure(X.Index item63)) item62) ((D.components a0Value) :: [[(Int)]])
    (27,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        source ((D.bloom a0Value a1Value) :: (Either (E.MathError) (D.Bloom))) >>= \_result64 -> encodeBloom _result64
    (28,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Word64))
        a1Value <- (unbox "HMath.DataStructure.Bloom" a1 :: IO (D.Bloom))
        encodeBloom ((D.bloomInsert a0Value a1Value) :: (D.Bloom))
    (29,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Word64))
        a1Value <- (unbox "HMath.DataStructure.Bloom" a1 :: IO (D.Bloom))
        pure(X.Boolean ((D.bloomMember a0Value a1Value) :: (Bool)))
    (30,[a0]) -> do
        a0Value <- (unbox "HMath.DataStructure.Bloom" a0 :: IO (D.Bloom))
        pure(X.Scalar SDouble ((D.bloomFalsePositiveBound a0Value) :: (Double)))
    (31,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        source ((D.countMin a0Value a1Value) :: (Either (E.MathError) (D.CountMin))) >>= \_result65 -> encodeCountMin _result65
    (32,[a0,a1,a2]) -> do
        a0Value <- (X.asScalar a0 :: IO (Word64))
        a1Value <- (X.asScalar a1 :: IO (Integer))
        a2Value <- (unbox "HMath.DataStructure.CountMin" a2 :: IO (D.CountMin))
        source ((D.countMinAdd a0Value a1Value a2Value) :: (Either (E.MathError) (D.CountMin))) >>= \_result66 -> encodeCountMin _result66
    (33,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Word64))
        a1Value <- (unbox "HMath.DataStructure.CountMin" a1 :: IO (D.CountMin))
        pure(X.Scalar SInteger ((D.countMinEstimate a0Value a1Value) :: (Integer)))
    (34,[a0]) -> do
        a0Value <- (unbox "HMath.DataStructure.CountMin" a0 :: IO (D.CountMin))
        (\(part67,part68) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part67),pure(X.Scalar SDouble part68)]) ((D.countMinErrorBound a0Value) :: ((Double),(Double)))
    (35,[a0]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        source ((D.hyperLogLog a0Value) :: (Either (E.MathError) (D.HyperLogLog))) >>= \_result69 -> encodeHyperLogLog _result69
    (36,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Word64))
        a1Value <- (unbox "HMath.DataStructure.HyperLogLog" a1 :: IO (D.HyperLogLog))
        encodeHyperLogLog ((D.hllAdd a0Value a1Value) :: (D.HyperLogLog))
    (37,[a0]) -> do
        a0Value <- (unbox "HMath.DataStructure.HyperLogLog" a0 :: IO (D.HyperLogLog))
        pure(X.Scalar SDouble ((D.hllEstimate a0Value) :: (Double)))
    (38,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asScalar a1 :: IO (Word64))
        source ((D.reservoir a0Value a1Value) :: (Either (E.MathError) (D.Reservoir EqualityValue))) >>= \_result70 -> encodeReservoir _result70
    (39,[a0,a1]) -> do
        a0Value <- (readEquality a0 :: IO EqualityValue)
        a1Value <- (unbox "HMath.DataStructure.Reservoir" a1 :: IO (D.Reservoir EqualityValue))
        source ((D.reservoirAdd a0Value a1Value) :: (Either (E.MathError) (D.Reservoir EqualityValue))) >>= \_result71 -> encodeReservoir _result71
    (40,[a0]) -> do
        a0Value <- (unbox "HMath.DataStructure.Reservoir" a0 :: IO (D.Reservoir EqualityValue))
        X.List <$>mapM(\item72 -> writeEquality item72) ((D.reservoirValues a0Value) :: [EqualityValue])
    (41,[a0]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        source ((D.onlineQuantiles a0Value) :: (Either (E.MathError) (D.OnlineQuantiles))) >>= \_result73 -> encodeOnlineQuantiles _result73
    (42,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (unbox "HMath.DataStructure.OnlineQuantiles" a1 :: IO (D.OnlineQuantiles))
        source ((D.quantileAdd a0Value a1Value) :: (Either (E.MathError) (D.OnlineQuantiles))) >>= \_result74 -> encodeOnlineQuantiles _result74
    (43,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Double))
        a1Value <- (unbox "HMath.DataStructure.OnlineQuantiles" a1 :: IO (D.OnlineQuantiles))
        source ((D.onlineQuantile a0Value a1Value) :: (Either (E.MathError) (Double))) >>= \_result75 -> pure(X.Scalar SDouble _result75)
    (44,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item76 -> pure item76) :: IO [X.Value])
        (multiset a0Value) >>= \result -> encodeMultiSet result
    (45,[a0,a1]) -> do
        a0Value <- (pure a0 :: IO X.Value)
        a1Value <- (unbox "HMath.Discrete.MultiSet" a1 :: IO MultiState)
        (multiplicity a0Value a1Value) >>= \result -> pure(X.Scalar SInteger result)
    (46,[a0]) -> do
        a0Value <- (unbox "HMath.Discrete.MultiSet" a0 :: IO MultiState)
        (multisetEntries a0Value) >>= \result -> X.List <$>mapM(\item77 -> (\(part78,part79) -> X.Tuple <$> sequence [pure part78,pure(X.Scalar SInteger part79)]) item77) result
    (47,[a0,a1]) -> do
        a0Value <- (pure a0 :: IO X.Value)
        a1Value <- (unbox "HMath.Discrete.MultiSet" a1 :: IO MultiState)
        (multisetInsert a0Value a1Value) >>= \result -> encodeMultiSet result
    (48,[a0,a1]) -> do
        a0Value <- (pure a0 :: IO X.Value)
        a1Value <- (unbox "HMath.Discrete.MultiSet" a1 :: IO MultiState)
        (multisetDelete a0Value a1Value) >>= \result -> encodeMultiSet result
    (49,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.MultiSet" a0 :: IO MultiState)
        a1Value <- (unbox "HMath.Discrete.MultiSet" a1 :: IO MultiState)
        (multisetBinary S.multisetUnion a0Value a1Value) >>= \result -> encodeMultiSet result
    (50,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.MultiSet" a0 :: IO MultiState)
        a1Value <- (unbox "HMath.Discrete.MultiSet" a1 :: IO MultiState)
        (multisetBinary S.multisetIntersection a0Value a1Value) >>= \result -> encodeMultiSet result
    (51,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.MultiSet" a0 :: IO MultiState)
        a1Value <- (unbox "HMath.Discrete.MultiSet" a1 :: IO MultiState)
        (multisetBinary S.multisetDifference a0Value a1Value) >>= \result -> encodeMultiSet result
    (52,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asScalar a1 :: IO (Integer))
        source ((S.bitSet a0Value a1Value) :: (Either (E.MathError) (S.BitSet))) >>= \_result80 -> encodeBitSet _result80
    (53,[a0]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        pure(X.Index ((S.bitWidth a0Value) :: (Int)))
    (54,[a0]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        pure(X.Scalar SInteger ((S.bitValue a0Value) :: (Integer)))
    (55,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        a1Value <- (X.asIndex a1 :: IO (Int))
        source ((S.bitMember a0Value a1Value) :: (Either (E.MathError) (Bool))) >>= \_result81 -> pure(X.Boolean _result81)
    (56,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        a1Value <- (X.asIndex a1 :: IO (Int))
        source ((S.bitInsert a0Value a1Value) :: (Either (E.MathError) (S.BitSet))) >>= \_result82 -> encodeBitSet _result82
    (57,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        a1Value <- (X.asIndex a1 :: IO (Int))
        source ((S.bitDelete a0Value a1Value) :: (Either (E.MathError) (S.BitSet))) >>= \_result83 -> encodeBitSet _result83
    (58,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        a1Value <- (unbox "HMath.Discrete.BitSet" a1 :: IO (S.BitSet))
        source ((S.bitUnion a0Value a1Value) :: (Either (E.MathError) (S.BitSet))) >>= \_result84 -> encodeBitSet _result84
    (59,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        a1Value <- (unbox "HMath.Discrete.BitSet" a1 :: IO (S.BitSet))
        source ((S.bitIntersection a0Value a1Value) :: (Either (E.MathError) (S.BitSet))) >>= \_result85 -> encodeBitSet _result85
    (60,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        a1Value <- (unbox "HMath.Discrete.BitSet" a1 :: IO (S.BitSet))
        source ((S.bitDifference a0Value a1Value) :: (Either (E.MathError) (S.BitSet))) >>= \_result86 -> encodeBitSet _result86
    (61,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (unbox "HMath.Discrete.BitSet" a1 :: IO (S.BitSet))
        source ((S.resizeBitSet a0Value a1Value) :: (Either (E.MathError) (S.BitSet))) >>= \_result87 -> encodeBitSet _result87
    (62,[a0]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        pure(X.Index ((S.populationCount a0Value) :: (Int)))
    (63,[a0]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        pure(X.Index ((S.leadingZeros a0Value) :: (Int)))
    (64,[a0]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        pure(X.Index ((S.trailingZeros a0Value) :: (Int)))
    (65,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (unbox "HMath.Discrete.BitSet" a1 :: IO (S.BitSet))
        encodeBitSet ((S.rotateBits a0Value a1Value) :: (S.BitSet))
    (66,[a0]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        encodeBitSet ((S.reverseBits a0Value) :: (S.BitSet))
    (67,[a0]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        encodeBitSet ((S.grayEncode a0Value) :: (S.BitSet))
    (68,[a0]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        encodeBitSet ((S.grayDecode a0Value) :: (S.BitSet))
    (69,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.BitSet" a0 :: IO (S.BitSet))
        a1Value <- (unbox "HMath.Discrete.BitSet" a1 :: IO (S.BitSet))
        source ((S.hammingDistance a0Value a1Value) :: (Either (E.MathError) (Int))) >>= \_result88 -> pure(X.Index _result88)
    (70,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item89 -> X.asList item89 >>= mapM(\item90 -> X.asBoolean item90)) :: IO [[(Bool)]])
        source ((S.transitiveClosure a0Value) :: (Either (E.MathError) [[(Bool)]])) >>= \_result91 -> X.List <$>mapM(\item92 -> X.List <$>mapM(\item93 -> pure(X.Boolean item93)) item92) _result91
    (71,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item94 -> X.asList item94 >>= mapM(\item95 -> X.asBoolean item95)) :: IO [[(Bool)]])
        source ((S.equivalenceClosure a0Value) :: (Either (E.MathError) [[(Bool)]])) >>= \_result96 -> X.List <$>mapM(\item97 -> X.List <$>mapM(\item98 -> pure(X.Boolean item98)) item97) _result96
    (72,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item99 -> X.asList item99 >>= mapM(\item100 -> X.asBoolean item100)) :: IO [[(Bool)]])
        source ((S.isEquivalence a0Value) :: (Either (E.MathError) (Bool))) >>= \_result101 -> pure(X.Boolean _result101)
    (73,[a0,a1]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item102 -> X.asList item102 >>= mapM(\item103 -> X.asBoolean item103)) :: IO [[(Bool)]])
        a1Value <- (X.asList a1 >>= mapM(\item104 -> X.asList item104 >>= mapM(\item105 -> X.asBoolean item105)) :: IO [[(Bool)]])
        source ((S.booleanMultiply a0Value a1Value) :: (Either (E.MathError) [[(Bool)]])) >>= \_result106 -> X.List <$>mapM(\item107 -> X.List <$>mapM(\item108 -> pure(X.Boolean item108)) item107) _result106
    (74,[a0,a1]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item109 -> X.asBoolean item109) :: IO [(Bool)])
        a1Value <- (unbox "HMath.Discrete.Prop" a1 :: IO (S.Prop))
        source ((S.evaluateProp a0Value a1Value) :: (Either (E.MathError) (Bool))) >>= \_result110 -> pure(X.Boolean _result110)
    (75,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (unbox "HMath.Discrete.Prop" a1 :: IO (S.Prop))
        source ((S.truthTable a0Value a1Value) :: (Either (E.MathError) [([(Bool)],(Bool))])) >>= \_result111 -> X.List <$>mapM(\item112 -> (\(part113,part114) -> X.Tuple <$> sequence [X.List <$>mapM(\item115 -> pure(X.Boolean item115)) part113,pure(X.Boolean part114)]) item112) _result111
    (76,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.Implicant" a0 :: IO (S.Implicant))
        a1Value <- (X.asScalar a1 :: IO (Integer))
        pure(X.Boolean ((S.implicantCovers a0Value a1Value) :: (Bool)))
    (77,[a0,a1,a2,a3]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asList a2 >>= mapM(\item116 -> X.asScalar item116) :: IO [(Integer)])
        a3Value <- (X.asList a3 >>= mapM(\item117 -> X.asScalar item117) :: IO [(Integer)])
        source ((S.quineMcCluskey a0Value a1Value a2Value a3Value) :: (Either (E.MathError) [(S.Implicant)])) >>= \_result118 -> X.List <$>mapM(\item119 -> encodeImplicant item119) _result118
    (78,[a0]) -> do
        a0Value <- (X.asBoolean a0 :: IO (Bool))
        encodeProp ((S.Literal a0Value) :: (S.Prop))
    (79,[a0]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        encodeProp ((S.Variable a0Value) :: (S.Prop))
    (80,[a0]) -> do
        a0Value <- (unbox "HMath.Discrete.Prop" a0 :: IO (S.Prop))
        encodeProp ((S.Not a0Value) :: (S.Prop))
    (81,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.Prop" a0 :: IO (S.Prop))
        a1Value <- (unbox "HMath.Discrete.Prop" a1 :: IO (S.Prop))
        encodeProp ((S.And a0Value a1Value) :: (S.Prop))
    (82,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.Prop" a0 :: IO (S.Prop))
        a1Value <- (unbox "HMath.Discrete.Prop" a1 :: IO (S.Prop))
        encodeProp ((S.Or a0Value a1Value) :: (S.Prop))
    (83,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.Prop" a0 :: IO (S.Prop))
        a1Value <- (unbox "HMath.Discrete.Prop" a1 :: IO (S.Prop))
        encodeProp ((S.Xor a0Value a1Value) :: (S.Prop))
    (84,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.Prop" a0 :: IO (S.Prop))
        a1Value <- (unbox "HMath.Discrete.Prop" a1 :: IO (S.Prop))
        encodeProp ((S.Implies a0Value a1Value) :: (S.Prop))
    (85,[a0,a1]) -> do
        a0Value <- (unbox "HMath.Discrete.Prop" a0 :: IO (S.Prop))
        a1Value <- (unbox "HMath.Discrete.Prop" a1 :: IO (S.Prop))
        encodeProp ((S.Iff a0Value a1Value) :: (S.Prop))
    (86,[a0]) -> do
        a0Value <- (unbox "HMath.Discrete.Implicant" a0 :: IO (S.Implicant))
        pure(X.Scalar SInteger ((S.implicantValue a0Value) :: (Integer)))
    (87,[a0]) -> do
        a0Value <- (unbox "HMath.Discrete.Implicant" a0 :: IO (S.Implicant))
        pure(X.Scalar SInteger ((S.implicantMask a0Value) :: (Integer)))
    (88,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Integer))
        a1Value <- (X.asScalar a1 :: IO (Integer))
        encodeImplicant ((S.Implicant a0Value a1Value) :: (S.Implicant))
    (89,[a0,a1]) -> do
        examples <- concat <$> sequence [pure [a0],X.asList a1]
        witness <- if null examples then orderedFromPrototype(X.Scalar SInteger 0) else orderedWith [foundationOrdering] examples
        a0Value <- (readOrdered witness a0 :: IO OrderedValue)
        a1Value <- (X.asList a1 >>= mapM(\item120 -> readOrdered witness item120) :: IO [OrderedValue])
        source ((A.binarySearch a0Value a1Value) :: (Either (E.MathError) (Maybe (Int)))) >>= \_result121 -> (case _result121 of {Nothing -> pure X.None;Just item122 -> pure(X.Index item122) >>= maybeValue . Just})
    (90,[a0,a1]) -> do
        a0Value <- (X.asScalar a0 :: IO (Integer))
        a1Value <- (X.asList a1 >>= mapM(\item123 -> X.asScalar item123) :: IO [(Integer)])
        source ((A.interpolationSearch a0Value a1Value) :: (Either (E.MathError) (Maybe (Int)))) >>= \_result124 -> (case _result124 of {Nothing -> pure X.None;Just item125 -> pure(X.Index item125) >>= maybeValue . Just})
    (91,[a0,a1]) -> do
        examples <- concat <$> sequence [pure [a0],X.asList a1]
        witness <- if null examples then orderedFromPrototype(X.Scalar SInteger 0) else orderedWith [foundationOrdering] examples
        a0Value <- (readOrdered witness a0 :: IO OrderedValue)
        a1Value <- (X.asList a1 >>= mapM(\item126 -> readOrdered witness item126) :: IO [OrderedValue])
        source ((A.exponentialSearch a0Value a1Value) :: (Either (E.MathError) (Maybe (Int)))) >>= \_result127 -> (case _result127 of {Nothing -> pure X.None;Just item128 -> pure(X.Index item128) >>= maybeValue . Just})
    (92,[a0,a1,a2,a3]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (pure(\callbackArg129 -> unsafePerformIO $ do {inputs <- sequence [pure(X.Scalar SDouble callbackArg129)];let { input=X.Tuple inputs };LC.callbackValue a1 input >>= \reply -> X.asScalar reply}) :: IO ((Double) -> (Double)))
        a2Value <- (X.asScalar a2 :: IO (Double))
        a3Value <- (X.asScalar a3 :: IO (Double))
        source ((A.ternarySearch a0Value a1Value a2Value a3Value) :: (Either (E.MathError) ((Double),(Double)))) >>= \_result130 -> (\(part131,part132) -> X.Tuple <$> sequence [pure(X.Scalar SDouble part131),pure(X.Scalar SDouble part132)]) _result130
    (93,[a0]) -> do
        examples <- concat <$> sequence [X.asList a0]
        witness <- if null examples then orderedFromPrototype(X.Scalar SInteger 0) else orderedWith [foundationOrdering] examples
        a0Value <- (X.asList a0 >>= mapM(\item133 -> readOrdered witness item133) :: IO [OrderedValue])
        X.List <$>mapM(\item134 -> (\(part135,part136) -> X.Tuple <$> sequence [writeOrdered part135,pure(X.Index part136)]) item134) ((A.numericGroups a0Value) :: [(OrderedValue,(Int))])
    (94,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item137 -> readEquality item137) :: IO [EqualityValue])
        X.List <$>mapM(\item138 -> (\(part139,part140) -> X.Tuple <$> sequence [writeEquality part139,pure(X.Index part140)]) item138) ((A.runLengthEncode a0Value) :: [(EqualityValue,(Int))])
    (95,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asList a1 >>= mapM(\item141 -> (X.asTuple 2 item141 >>= \parts144 -> case parts144 of { [part142,part143] -> (,) <$> (pure part142) <*> (X.asIndex part143);_ -> X.invalid "tuple arity differs"})) :: IO [(X.Value,(Int))])
        source ((A.runLengthDecode a0Value a1Value) :: (Either (E.MathError) [X.Value])) >>= \_result145 -> X.List <$>mapM(\item146 -> pure item146) _result145
    (96,[a0]) -> do
        examples <- concat <$> sequence [X.asList a0]
        witness <- if null examples then orderedFromPrototype(X.Scalar SInteger 0) else orderedWith [foundationOrdering] examples
        a0Value <- (X.asList a0 >>= mapM(\item147 -> readOrdered witness item147) :: IO [OrderedValue])
        (\(part148,part149) -> X.Tuple <$> sequence [X.List <$>mapM(\item150 -> writeOrdered item150) part148,X.List <$>mapM(\item151 -> pure(X.Index item151)) part149]) ((A.coordinateCompression a0Value) :: ([OrderedValue],[(Int)]))
    (97,[a0]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item152 -> (X.asTuple 2 item152 >>= \parts155 -> case parts155 of { [part153,part154] -> (,) <$> (X.asScalar part153) <*> (X.asScalar part154);_ -> X.invalid "tuple arity differs"})) :: IO [((Integer),(Integer))])
        source ((A.intervalSweep a0Value) :: (Either (E.MathError) ((Integer),(Int)))) >>= \_result156 -> (\(part157,part158) -> X.Tuple <$> sequence [pure(X.Scalar SInteger part157),pure(X.Index part158)]) _result156
    (98,[a0,a1]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item159 -> X.asScalar item159) :: IO [(Double)])
        a1Value <- (pure(\callbackArg160 callbackArg161 -> unsafePerformIO $ do {inputs <- sequence [pure(X.Index callbackArg160),pure(X.Index callbackArg161)];let { input=X.Tuple inputs };LC.callbackValue a1 input >>= \reply -> X.asScalar reply}) :: IO ((Int) -> (Int) -> (Double)))
        source ((A.divideConquerDP a0Value a1Value) :: (Either (E.MathError) [(Double)])) >>= \_result162 -> X.List <$>mapM(\item163 -> pure(X.Scalar SDouble item163)) _result162
    (99,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (pure(\callbackArg164 -> unsafePerformIO $ do {inputs <- sequence [pure(X.Index callbackArg164)];let { input=X.Tuple inputs };LC.callbackValue a1 input >>= \reply -> X.asList reply >>= mapM(\item165 -> (X.asTuple 2 item165 >>= \parts168 -> case parts168 of { [part166,part167] -> (,) <$> (X.asIndex part166) <*> (X.asScalar part167);_ -> X.invalid "tuple arity differs"}))}) :: IO ((Int) -> [((Int),(Integer))]))
        source ((A.tabulateDP a0Value a1Value) :: (Either (E.MathError) [(Integer)])) >>= \_result169 -> X.List <$>mapM(\item170 -> pure(X.Scalar SInteger item170)) _result169
    (100,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (pure(\callbackArg171 -> unsafePerformIO $ do {inputs <- sequence [pure(X.Index callbackArg171)];let { input=X.Tuple inputs };LC.callbackValue a1 input >>= \reply -> (X.asTuple 2 reply >>= \parts174 -> case parts174 of { [part172,part173] -> (,) <$> (X.asScalar part172) <*> (X.asList part173 >>= mapM(\item175 -> (X.asTuple 2 item175 >>= \parts178 -> case parts178 of { [part176,part177] -> (,) <$> (X.asIndex part176) <*> (X.asScalar part177);_ -> X.invalid "tuple arity differs"})));_ -> X.invalid "tuple arity differs"})}) :: IO ((Int) -> ((Integer),[((Int),(Integer))])))
        a2Value <- (X.asIndex a2 :: IO (Int))
        source ((A.memoizedDP a0Value a1Value a2Value) :: (Either (E.MathError) (Integer))) >>= \_result179 -> pure(X.Scalar SInteger _result179)
    (101,[a0,a1]) -> do
        a0Value <- (X.asList a0 >>= mapM(\item180 -> X.asList item180 >>= mapM(\item181 -> X.asScalar item181)) :: IO [[(Integer)]])
        a1Value <- (X.asScalar a1 :: IO (Integer))
        source ((A.integerMatrixPower a0Value a1Value) :: (Either (E.MathError) [[(Integer)]])) >>= \_result182 -> X.List <$>mapM(\item183 -> X.List <$>mapM(\item184 -> pure(X.Scalar SInteger item184)) item183) _result182
    (102,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asList a2 >>= mapM(\item185 -> pure item185) :: IO [X.Value])
        source ((C.permutationsOf a0Value a1Value a2Value) :: (Either (E.MathError) [[X.Value]])) >>= \_result186 -> X.List <$>mapM(\item187 -> X.List <$>mapM(\item188 -> pure item188) item187) _result186
    (103,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asList a2 >>= mapM(\item189 -> pure item189) :: IO [X.Value])
        source ((C.combinationsOf a0Value a1Value a2Value) :: (Either (E.MathError) [[X.Value]])) >>= \_result190 -> X.List <$>mapM(\item191 -> X.List <$>mapM(\item192 -> pure item192) item191) _result190
    (104,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        source ((C.derangements a0Value a1Value) :: (Either (E.MathError) [[(Int)]])) >>= \_result193 -> X.List <$>mapM(\item194 -> X.List <$>mapM(\item195 -> pure(X.Index item195)) item194) _result193
    (105,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        source ((C.integerPartitions a0Value a1Value) :: (Either (E.MathError) [[(Int)]])) >>= \_result196 -> X.List <$>mapM(\item197 -> X.List <$>mapM(\item198 -> pure(X.Index item198)) item197) _result196
    (106,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asIndex a1 :: IO (Int))
        source ((C.setPartitions a0Value a1Value) :: (Either (E.MathError) [[[(Int)]]])) >>= \_result199 -> X.List <$>mapM(\item200 -> X.List <$>mapM(\item201 -> X.List <$>mapM(\item202 -> pure(X.Index item202)) item201) item200) _result199
    (107,[a0]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        source ((C.pascalTriangle a0Value) :: (Either (E.MathError) [[(Integer)]])) >>= \_result203 -> X.List <$>mapM(\item204 -> X.List <$>mapM(\item205 -> pure(X.Scalar SInteger item205)) item204) _result203
    (108,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asList a1 >>= mapM(\item206 -> pure item206) :: IO [X.Value])
        source ((C.subsets a0Value a1Value) :: (Either (E.MathError) [[X.Value]])) >>= \_result207 -> X.List <$>mapM(\item208 -> X.List <$>mapM(\item209 -> pure item209) item208) _result207
    (109,[a0,a1]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asList a1 >>= mapM(\item210 -> X.asList item210 >>= mapM(\item211 -> pure item211)) :: IO [[X.Value]])
        source ((C.cartesianProduct a0Value a1Value) :: (Either (E.MathError) [[X.Value]])) >>= \_result212 -> X.List <$>mapM(\item213 -> X.List <$>mapM(\item214 -> pure item214) item213) _result212
    (110,[a0,a1]) -> do
        examples <- concat <$> sequence [X.asList a1]
        witness <- if null examples then orderedFromPrototype(X.Scalar SInteger 0) else orderedWith [foundationOrdering] examples
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asList a1 >>= mapM(\item215 -> readOrdered witness item215) :: IO [OrderedValue])
        source ((C.multisetPermutations a0Value a1Value) :: (Either (E.MathError) [[OrderedValue]])) >>= \_result216 -> X.List <$>mapM(\item217 -> X.List <$>mapM(\item218 -> writeOrdered item218) item217) _result216
    (111,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asList a1 >>= mapM(\item219 -> X.asScalar item219) :: IO [(Rational)])
        a2Value <- (X.asList a2 >>= mapM(\item220 -> X.asScalar item220) :: IO [(Rational)])
        source ((C.generatingCoefficients a0Value a1Value a2Value) :: (Either (E.MathError) [(Rational)])) >>= \_result221 -> X.List <$>mapM(\item222 -> pure(X.Scalar SRational item222)) _result221
    (112,[prototype,a0]) -> LC.withWitness prototype $ \(w::ScalarType a) -> do
        a0Value <- (X.asList a0 >>= mapM(\item223 -> X.asScalar item223) :: IO [a])
        X.List <$>mapM(\item224 -> X.List <$>mapM(\item225 -> pure(X.Scalar w item225)) item224) ((C.finiteDifferences a0Value) :: [[a]])
    (113,[]) -> do
        encodeIterationOptions ((V.defaultIterationOptions ) :: (V.IterationOptions))
    (114,[a0,a1,a2,a3,a4]) -> do
        a0Value <- (unbox "HMath.API.Convergence.IterationOptions" a0 :: IO (V.IterationOptions))
        a1Value <- (pure(\callbackArg226 -> unsafePerformIO $ do {inputs <- sequence [writeEquality callbackArg226];let { input=X.Tuple inputs };checkedCallback a1 input (\reply -> readEquality reply)}) :: IO (EqualityValue -> (Either (E.MathError) EqualityValue)))
        a2Value <- (pure(\callbackArg227 -> unsafePerformIO $ do {inputs <- sequence [writeEquality callbackArg227];let { input=X.Tuple inputs };checkedCallback a2 input (\reply -> X.asScalar reply)}) :: IO (EqualityValue -> (Either (E.MathError) (Double))))
        a3Value <- (pure(\callbackArg228 callbackArg229 -> unsafePerformIO $ do {inputs <- sequence [writeEquality callbackArg228,writeEquality callbackArg229];let { input=X.Tuple inputs };LC.callbackValue a3 input >>= \reply -> X.asBoolean reply}) :: IO (EqualityValue -> EqualityValue -> (Bool)))
        a4Value <- (readEquality a4 :: IO EqualityValue)
        source ((V.iterateUntil a0Value a1Value a2Value a3Value a4Value) :: (Either (E.MathError) (V.Convergence EqualityValue))) >>= \_result230 -> encodeConvergence _result230
    (115,[a0,a1]) -> do
        a0Value <- (X.asText a0 :: IO (String))
        a1Value <- (unbox "HMath.API.Convergence.Convergence" a1 :: IO (V.Convergence EqualityValue))
        source ((V.requireConvergence a0Value a1Value) :: (Either (E.MathError) EqualityValue)) >>= \_result231 -> writeEquality _result231
    (116,[a0]) -> do
        a0Value <- (asEitherValue a0 :: IO (Either X.Value X.Value))
        (case ((V.resultMaybe a0Value) :: (Maybe X.Value)) of {Nothing -> pure X.None;Just item232 -> pure item232 >>= maybeValue . Just})
    (117,[a0,a1]) -> do
        a0Value <- (pure a0 :: IO X.Value)
        a1Value <- ((asMaybeValue a1 >>= \optional233 -> case optional233 of {Nothing -> pure Nothing;Just item -> Just <$> (pure item)}) :: IO (Maybe X.Value))
        eitherValue ((V.fromMaybeError a0Value a1Value) :: (Either X.Value X.Value))
    (118,[]) -> do
        encodeStopReason ((V.ResidualSatisfied ) :: (V.StopReason))
    (119,[]) -> do
        encodeStopReason ((V.IterationLimit ) :: (V.StopReason))
    (120,[]) -> do
        encodeStopReason ((V.Stagnation ) :: (V.StopReason))
    (121,[a0]) -> do
        a0Value <- (unbox "HMath.API.Convergence.Convergence" a0 :: IO (V.Convergence EqualityValue))
        writeEquality ((V.estimate a0Value) :: EqualityValue)
    (122,[a0]) -> do
        a0Value <- (unbox "HMath.API.Convergence.Convergence" a0 :: IO (V.Convergence EqualityValue))
        pure(X.Index ((V.iterationCount a0Value) :: (Int)))
    (123,[a0]) -> do
        a0Value <- (unbox "HMath.API.Convergence.Convergence" a0 :: IO (V.Convergence EqualityValue))
        pure(X.Scalar SDouble ((V.finalResidual a0Value) :: (Double)))
    (124,[a0]) -> do
        a0Value <- (unbox "HMath.API.Convergence.Convergence" a0 :: IO (V.Convergence EqualityValue))
        encodeStopReason ((V.stopReason a0Value) :: (V.StopReason))
    (125,[a0,a1,a2,a3]) -> do
        a0Value <- (readEquality a0 :: IO EqualityValue)
        a1Value <- (X.asIndex a1 :: IO (Int))
        a2Value <- (X.asScalar a2 :: IO (Double))
        a3Value <- (unbox "HMath.API.Convergence.StopReason" a3 :: IO (V.StopReason))
        encodeConvergence ((V.Convergence a0Value a1Value a2Value a3Value) :: (V.Convergence EqualityValue))
    (126,[a0]) -> do
        a0Value <- (unbox "HMath.API.Convergence.IterationOptions" a0 :: IO (V.IterationOptions))
        pure(X.Index ((V.maximumIterations a0Value) :: (Int)))
    (127,[a0]) -> do
        a0Value <- (unbox "HMath.API.Convergence.IterationOptions" a0 :: IO (V.IterationOptions))
        pure(X.Scalar SDouble ((V.absoluteTolerance a0Value) :: (Double)))
    (128,[a0]) -> do
        a0Value <- (unbox "HMath.API.Convergence.IterationOptions" a0 :: IO (V.IterationOptions))
        pure(X.Scalar SDouble ((V.relativeTolerance a0Value) :: (Double)))
    (129,[a0,a1,a2]) -> do
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asScalar a1 :: IO (Double))
        a2Value <- (X.asScalar a2 :: IO (Double))
        encodeIterationOptions ((V.IterationOptions a0Value a1Value a2Value) :: (V.IterationOptions))
    (130,[a0]) -> do
        a0Value <- (unbox "HMath.API.Convergence.Convergence" a0 :: IO (V.Convergence EqualityValue))
        (case ((case a0Value of V.Converged x -> Just x;_ -> Nothing) :: (Maybe EqualityValue)) of {Nothing -> pure X.None;Just item234 -> writeEquality item234 >>= maybeValue . Just})
    (131,[prototype,a0]) -> do
        witness <- orderedWith [foundationOrdering][prototype]
        a0Value <- (X.asList a0 >>= mapM(\item235 -> readOrdered witness item235) :: IO [OrderedValue])
        X.List <$>mapM(\item236 -> (case item236 of {Nothing -> pure X.None;Just item237 -> pure(X.Index item237) >>= maybeValue . Just})) ((D.nextGreater a0Value) :: [(Maybe (Int))])
    (132,[prototype,a0,a1]) -> do
        witness <- orderedWith [foundationOrdering][prototype]
        a0Value <- (readOrdered witness a0 :: IO OrderedValue)
        a1Value <- (X.asList a1 >>= mapM(\item238 -> readOrdered witness item238) :: IO [OrderedValue])
        source ((A.binarySearch a0Value a1Value) :: (Either (E.MathError) (Maybe (Int)))) >>= \_result239 -> (case _result239 of {Nothing -> pure X.None;Just item240 -> pure(X.Index item240) >>= maybeValue . Just})
    (133,[prototype,a0,a1]) -> do
        witness <- orderedWith [foundationOrdering][prototype]
        a0Value <- (readOrdered witness a0 :: IO OrderedValue)
        a1Value <- (X.asList a1 >>= mapM(\item241 -> readOrdered witness item241) :: IO [OrderedValue])
        source ((A.exponentialSearch a0Value a1Value) :: (Either (E.MathError) (Maybe (Int)))) >>= \_result242 -> (case _result242 of {Nothing -> pure X.None;Just item243 -> pure(X.Index item243) >>= maybeValue . Just})
    (134,[prototype,a0]) -> do
        witness <- orderedWith [foundationOrdering][prototype]
        a0Value <- (X.asList a0 >>= mapM(\item244 -> readOrdered witness item244) :: IO [OrderedValue])
        X.List <$>mapM(\item245 -> (\(part246,part247) -> X.Tuple <$> sequence [writeOrdered part246,pure(X.Index part247)]) item245) ((A.numericGroups a0Value) :: [(OrderedValue,(Int))])
    (135,[prototype,a0]) -> do
        witness <- orderedWith [foundationOrdering][prototype]
        a0Value <- (X.asList a0 >>= mapM(\item248 -> readOrdered witness item248) :: IO [OrderedValue])
        (\(part249,part250) -> X.Tuple <$> sequence [X.List <$>mapM(\item251 -> writeOrdered item251) part249,X.List <$>mapM(\item252 -> pure(X.Index item252)) part250]) ((A.coordinateCompression a0Value) :: ([OrderedValue],[(Int)]))
    (136,[prototype,a0,a1]) -> do
        witness <- orderedWith [foundationOrdering][prototype]
        a0Value <- (X.asIndex a0 :: IO (Int))
        a1Value <- (X.asList a1 >>= mapM(\item253 -> readOrdered witness item253) :: IO [OrderedValue])
        source ((C.multisetPermutations a0Value a1Value) :: (Either (E.MathError) [[OrderedValue]])) >>= \_result254 -> X.List <$>mapM(\item255 -> X.List <$>mapM(\item256 -> writeOrdered item256) item255) _result254
    (-1,[value]) -> X.Text <$> objectName value
    (-2,[value]) -> objectParts value
    (-3,[value]) -> eitherValue(Left value)
    (-4,[value]) -> eitherValue(Right value)
    (-5,[value]) -> maybeValue(Just value)
    (-6,[value]) -> orderedType value
    (-7,[value]) -> optionalType value
    (-8,[prototype,values]) -> X.asList values >>= heapFromListTyped prototype >>= encodeHeap
    (-9,[prototype,values]) -> X.asList values >>= multisetTyped prototype >>= encodeMultiSet
    _ -> X.invalid "invalid foundation operation/arity"
foreign export ccall "hm_foundation_apply" ffiApply :: CInt -> Ptr(StablePtr X.Value) -> CSize -> Ptr(StablePtr X.Value) -> IO CInt
ffiApply :: CInt -> Ptr(StablePtr X.Value) -> CSize -> Ptr(StablePtr X.Value) -> IO CInt
ffiApply operation input count out=foundationBoundary $ do
    values <- peekArray(fromIntegral count) input >>= mapM deRefStablePtr
    value <- apply(fromIntegral operation) values
    Boundary.checked(Right())(const(X.publish value out))
