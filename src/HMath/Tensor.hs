{-# LANGUAGE ScopedTypeVariables #-}
-- SPDX-License-Identifier: MPL-2.0
-- | CPU tensors with immutable boxed backing arrays and shared, zero-copy
-- strided views. Logical indexing is zero based; strides and offsets count
-- elements. Scalars have shape [], one element; zero axes have no elements.
-- No implicit numeric promotion occurs: 'promoteTensor' makes it explicit.
-- Garbage collection manages immutable backing storage and view lifetimes.
module HMath.Tensor
    ( Tensor, Layout(..), Device(..), tensor, tensorColumnMajor, tensorValues
    , tensorShape, tensorStrides, tensorOffset, tensorDType, tensorDevice
    , tensorLayout, isContiguous, contiguous, numel, shapeSize, inferBroadcast
    , tensorZeros, tensorOnes, tensorFull, tensorArange, tensorLinspace, tensorLogspace
    , tensorRandom, indexTensor, sliceTensor, fancyIndex, booleanIndex, gather
    , scatter, scatterAdd, reshapeTensor, flattenTensor, squeeze, unsqueeze
    , expand, permute, transposeTensor, moveAxis, swapAxes, broadcastTo, repeatTensor, tile
    , concatenate, stack, splitTensor, chunkTensor, padTensor, roll, flipTensor, rotate
    , sortTensor, argsort, topk, unique, nonzero, whereTensor, maskedFill, maskedSelect
    , mapTensor, zipTensor, tensorAdd, tensorSubtract, tensorMultiply, tensorDivide
    , tensorEqual, tensorLess, tensorAnd, tensorOr, tensorNot, promoteTensor
    , sumAxes, meanAxes, productAxes, minAxes, maxAxes, argmin, argmax
    , varianceAxes, normAxes, cumulativeSum, cumulativeProduct, tensordot, einsum
    , batchedMatmul, tensorKronecker, serializeTensor, deserializeTensor
    , TensorGraph, inputGraph, mapGraph, zipGraph, evaluateGraph ) where

import Prelude hiding (repeat)
import Data.Array (Array,(!),listArray,bounds)
import Data.List (sort,sortOn,nub,elemIndex)
import Data.Proxy (Proxy(..))
import Data.Typeable (Typeable,typeRep)
import qualified Data.Map.Strict as M
import HMath.Error

data Layout = RowMajor | ColumnMajor | Strided deriving (Eq,Show,Read)
data Device = CPU deriving (Eq,Show,Read)
data Tensor a = Tensor [Int] [Int] Int (Array Int a) deriving (Show)
instance Eq a => Eq (Tensor a) where
    a==b = tensorShape a==tensorShape b && tensorValues a==tensorValues b
shapeSize :: [Int] -> Either MathError Int
shapeSize dims
    | any (<0) dims = Left (InvalidArgument "tensor: negative shape")
    | size>toInteger (maxBound::Int) = Left (InvalidArgument "tensor: element count overflow")
    | otherwise = Right (fromInteger size)
    where size=product (map toInteger dims)
stridesFor :: Layout -> [Int] -> [Int]
stridesFor layout dims
    | 0 `elem` dims = replicate (length dims) 0
    | layout==ColumnMajor = take (length dims) (scanl (*) 1 dims)
    | otherwise = drop 1 (scanr (*) 1 dims)
tensor :: [Int] -> [a] -> Either MathError (Tensor a)
tensor dims xs = do
    n<-shapeSize dims
    if n/=length xs then Left (ElementCountMismatch n (length xs))
        else Right (Tensor dims (stridesFor RowMajor dims) 0 (listArray (0,n-1) xs))
tensorColumnMajor :: [Int] -> [a] -> Either MathError (Tensor a)
tensorColumnMajor dims xs = do
    Tensor _ _ offset storage<-tensor dims xs
    Right (Tensor dims (stridesFor ColumnMajor dims) offset storage)
tensorShape :: Tensor a -> [Int]
tensorShape (Tensor dims _ _ _) = dims
tensorStrides :: Tensor a -> [Int]
tensorStrides (Tensor _ strides _ _) = strides
tensorOffset :: Tensor a -> Int
tensorOffset (Tensor _ _ offset _) = offset
tensorDType :: forall a. Typeable a => Tensor a -> String
tensorDType _ = show (typeRep (Proxy :: Proxy a))
tensorDevice :: Tensor a -> Device
tensorDevice _ = CPU
numel :: Tensor a -> Int
numel = product . tensorShape
isContiguous :: Tensor a -> Bool
isContiguous t = tensorStrides t==stridesFor RowMajor (tensorShape t)
tensorLayout :: Tensor a -> Layout
tensorLayout t | isContiguous t = RowMajor
               | tensorStrides t==stridesFor ColumnMajor (tensorShape t) = ColumnMajor
               | otherwise = Strided
allIndices :: [Int] -> [[Int]]
allIndices dims | 0 `elem` dims = []
allIndices [] = [[]]
allIndices (d:ds) = [i:is | i<-[0..d-1],is<-allIndices ds]
linearIndex :: Tensor a -> [Int] -> Int
linearIndex (Tensor _ strides offset _) ix = offset+sum (zipWith (*) strides ix)
unsafeIndex :: Tensor a -> [Int] -> a
unsafeIndex t@(Tensor _ _ _ storage) ix = storage ! linearIndex t ix
tensorValues :: Tensor a -> [a]
tensorValues t = [unsafeIndex t ix | ix<-allIndices (tensorShape t)]
contiguous :: Tensor a -> Either MathError (Tensor a)
contiguous t = tensor (tensorShape t) (tensorValues t)
validIndex :: [Int] -> [Int] -> Bool
validIndex dims ix = length dims==length ix && and (zipWith (\i d->i>=0&&i<d) ix dims)
indexTensor :: Tensor a -> [Int] -> Either MathError a
indexTensor t ix | validIndex (tensorShape t) ix = Right (unsafeIndex t ix)
                 | otherwise = Left (InvalidArgument "indexTensor: index out of bounds")
view :: [Int] -> [Int] -> Int -> Tensor a -> Either MathError (Tensor a)
view dims strides offset (Tensor _ _ _ storage) = do
    n<-shapeSize dims
    let (lo,hi)=bounds storage
        extremes=zipWith (\d s->toInteger (max 0 (d-1))*toInteger s) dims strides
        low=toInteger offset+sum (map (min 0) extremes)
        high=toInteger offset+sum (map (max 0) extremes)
    if length dims/=length strides || (n>0 && (low<toInteger lo || high>toInteger hi))
      || (n==0 && (offset<lo || toInteger offset>toInteger hi+1))
      then Left (InvalidArgument "tensor view: storage bounds invalid")
      else Right (Tensor dims strides offset storage)
axisValid :: Int -> Tensor a -> Either MathError ()
axisValid axis t | axis<0 || axis>=length (tensorShape t) = Left (InvalidArgument "tensor: axis out of range")
                 | otherwise = Right ()
replaceAt :: Int -> a -> [a] -> [a]
replaceAt i x xs = take i xs++x:drop (i+1) xs
insertAt :: Int -> a -> [a] -> [a]
insertAt i x xs = take i xs++x:drop i xs
removeAt :: Int -> [a] -> [a]
removeAt i xs = take i xs++drop (i+1) xs
tensorFull :: [Int] -> a -> Either MathError (Tensor a)
tensorFull dims x = do n<-shapeSize dims; tensor dims (replicate n x)
tensorZeros :: Num a => [Int] -> Either MathError (Tensor a)
tensorZeros dims = tensorFull dims 0
tensorOnes :: Num a => [Int] -> Either MathError (Tensor a)
tensorOnes dims = tensorFull dims 1
tensorArange :: RealFloat a => a -> a -> a -> Either MathError (Tensor a)
tensorArange start stop step
    | any (\x->isNaN x||isInfinite x) [start,stop,step] || step==0 = Left (InvalidArgument "arange: finite bounds and nonzero finite step required")
    | size>toInteger (maxBound::Int) = Left (InvalidArgument "arange: element count overflow")
    | otherwise = tensor [fromInteger size] [fromRational (toRational start+fromInteger i*toRational step) | i<-[0..size-1]]
    where ratio=(toRational stop-toRational start)/toRational step
          size=max 0 (ceiling ratio)
tensorLinspace :: Fractional a => a -> a -> Int -> Either MathError (Tensor a)
tensorLinspace start stop n
    | n<0 = Left (InvalidArgument "linspace: negative count")
    | n==0 = tensor [0] []
    | n==1 = tensor [1] [start]
    | otherwise = tensor [n] [if i==0 then start else if i==n-1 then stop else
        start*(fromIntegral (n-1-i)/fromIntegral (n-1))+stop*(fromIntegral i/fromIntegral (n-1)) | i<-[0..n-1]]
tensorLogspace :: Floating a => a -> a -> a -> Int -> Either MathError (Tensor a)
tensorLogspace base start stop n = mapTensor (base**) <$> tensorLinspace start stop n
-- | Explicit deterministic LCG seed. Values are uniform in [0,1); the returned
-- seed continues the stream, and does not access global mutable generator state.
tensorRandom :: Integer -> [Int] -> Either MathError (Tensor Double,Integer)
tensorRandom seed dims = do
    n<-shapeSize dims
    let states=take n (drop 1 (iterate (\x->(1664525*x+1013904223) `mod` 4294967296) (seed `mod` 4294967296)))
    t<-tensor dims [fromInteger x/4294967296 | x<-states]
    Right (t,case reverse states of x:_->x; []->seed `mod` 4294967296)
sliceTensor :: Int -> Int -> Int -> Int -> Tensor a -> Either MathError (Tensor a)
sliceTensor axis start count step t = do
    axisValid axis t
    let dims=tensorShape t; strides=tensorStrides t; d=dims!!axis
        end=toInteger start+toInteger (count-1)*toInteger step
        offset=toInteger (tensorOffset t)+toInteger start*toInteger (strides!!axis)
        stride=toInteger (strides!!axis)*toInteger step
    if count<0 || step==0 || start<0 || (count>0 && (start>=d||end<0||end>=toInteger d)) || (count==0 && start>d)
        || stride<toInteger (minBound::Int) || stride>toInteger (maxBound::Int)
        then Left (InvalidArgument "sliceTensor: invalid extent or step")
        else view (replaceAt axis count dims) (replaceAt axis (fromInteger stride) strides)
            (if count==0 then tensorOffset t else fromInteger offset) t
fancyIndex :: Int -> [Int] -> Tensor a -> Either MathError (Tensor a)
fancyIndex axis indices t = do
    axisValid axis t
    let dims=tensorShape t
    if any (\i->i<0||i>=dims!!axis) indices then Left (InvalidArgument "fancyIndex: index out of bounds") else do
        let output=replaceAt axis (length indices) dims
        _<-shapeSize output
        tensor output [unsafeIndex t (replaceAt axis (indices!!(ix!!axis)) ix) | ix<-allIndices output]
booleanIndex :: Tensor Bool -> Tensor a -> Either MathError (Tensor a)
booleanIndex = maskedSelect
gather :: Int -> [Int] -> Tensor a -> Either MathError (Tensor a)
gather = fancyIndex
scatterWith :: (a -> a -> a) -> Int -> [Int] -> Tensor a -> Tensor a -> Either MathError (Tensor a)
scatterWith combine axis indices updates target = do
    axisValid axis target
    let dims=tensorShape target; updateDims=replaceAt axis (length indices) dims
    if tensorShape updates/=updateDims || any (\i->i<0||i>=dims!!axis) indices
      then Left (InvalidArgument "scatter: update shape or indices invalid") else do
        let initial=M.fromList (zip (allIndices dims) (tensorValues target))
            apply values ix = M.adjust (\old->combine old (unsafeIndex updates ix)) (replaceAt axis (indices!!(ix!!axis)) ix) values
            final=foldl apply initial (allIndices updateDims)
        tensor dims [final M.! ix | ix<-allIndices dims]
scatter :: Int -> [Int] -> Tensor a -> Tensor a -> Either MathError (Tensor a)
scatter = scatterWith (\_ new->new)
scatterAdd :: Num a => Int -> [Int] -> Tensor a -> Tensor a -> Either MathError (Tensor a)
scatterAdd = scatterWith (+)
reshapeTensor :: [Int] -> Tensor a -> Either MathError (Tensor a)
reshapeTensor dims t = do
    size<-shapeSize dims
    if size/=numel t then Left (ElementCountMismatch size (numel t)) else
        if isContiguous t then view dims (stridesFor RowMajor dims) (tensorOffset t) t
            else tensor dims (tensorValues t)
flattenTensor :: Tensor a -> Either MathError (Tensor a)
flattenTensor t = reshapeTensor [numel t] t
squeeze :: Tensor a -> Either MathError (Tensor a)
squeeze t = view [d | d<-tensorShape t,d/=1] [s | (d,s)<-zip (tensorShape t) (tensorStrides t),d/=1] (tensorOffset t) t
unsqueeze :: Int -> Tensor a -> Either MathError (Tensor a)
unsqueeze axis t
    | axis<0 || axis>length (tensorShape t) = Left (InvalidArgument "unsqueeze: axis out of range")
    | otherwise = view (insertAt axis 1 (tensorShape t)) (insertAt axis 0 (tensorStrides t)) (tensorOffset t) t
permute :: [Int] -> Tensor a -> Either MathError (Tensor a)
permute order t
    | sort order/=[0..length (tensorShape t)-1] = Left (InvalidArgument "permute: axes must be a permutation")
    | otherwise = view (map (tensorShape t!!) order) (map (tensorStrides t!!) order) (tensorOffset t) t
transposeTensor :: Tensor a -> Either MathError (Tensor a)
transposeTensor t = permute (reverse [0..length (tensorShape t)-1]) t
moveAxis :: Int -> Int -> Tensor a -> Either MathError (Tensor a)
moveAxis source destination t = do
    axisValid source t; axisValid destination t
    permute (insertAt destination source (filter (/=source) [0..length (tensorShape t)-1])) t
swapAxes :: Int -> Int -> Tensor a -> Either MathError (Tensor a)
swapAxes a b t = do
    axisValid a t; axisValid b t
    permute [if i==a then b else if i==b then a else i | i<-[0..length (tensorShape t)-1]] t
inferBroadcast :: [Int] -> [Int] -> Either MathError [Int]
inferBroadcast as bs = do
    _<-shapeSize as; _<-shapeSize bs
    dims<-sequence (zipWith compatible (pad as) (pad bs))
    _<-shapeSize dims
    Right dims
    where n=max (length as) (length bs); pad xs=replicate (n-length xs) 1++xs
          compatible a b | a==b = Right a
                         | a==1 = Right b
                         | b==1 = Right a
                         | otherwise = Left (InvalidArgument "broadcast: incompatible shapes")
broadcastTo :: [Int] -> Tensor a -> Either MathError (Tensor a)
broadcastTo dims t = do
    inferred<-inferBroadcast dims (tensorShape t)
    if inferred/=dims || length dims<length (tensorShape t) then Left (InvalidArgument "broadcastTo: incompatible target") else do
        let rank=length dims; missing=rank-length (tensorShape t)
            source=replicate missing 1++tensorShape t
            strides=replicate missing 0++tensorStrides t
        view dims (zipWith3 (\d old s->if old==1&&d/=1 then 0 else s) dims source strides) (tensorOffset t) t
expand :: [Int] -> Tensor a -> Either MathError (Tensor a)
expand = broadcastTo
repeatTensor :: Int -> Int -> Tensor a -> Either MathError (Tensor a)
repeatTensor axis repetitions t = do
    axisValid axis t
    let dim=tensorShape t!!axis
        new=toInteger dim*toInteger repetitions
    if repetitions<0 || new>toInteger (maxBound::Int) then Left (InvalidArgument "repeatTensor: invalid repetition or size overflow") else do
        let dims=replaceAt axis (fromInteger new) (tensorShape t)
        _<-shapeSize dims
        tensor dims [unsafeIndex t (replaceAt axis (ix!!axis `div` repetitions) ix) | ix<-allIndices dims]
tile :: [Int] -> Tensor a -> Either MathError (Tensor a)
tile repetitions t
    | length repetitions/=length (tensorShape t) || any (<0) repetitions = Left (InvalidArgument "tile: repetition rank mismatch or negative repetition")
    | any (>toInteger (maxBound::Int)) dimensions = Left (InvalidArgument "tile: shape overflow")
    | otherwise = do
        let dims=map fromInteger dimensions
        _<-shapeSize dims
        tensor dims [unsafeIndex t (zipWith mod ix (tensorShape t)) | ix<-allIndices dims]
    where dimensions=zipWith (\d n->toInteger d*toInteger n) (tensorShape t) repetitions
concatenate :: Int -> [Tensor a] -> Either MathError (Tensor a)
concatenate _ [] = Left (InvalidArgument "concatenate: nonempty input required")
concatenate axis ts@(first:_) = do
    axisValid axis first
    let dims=tensorShape first
        total=sum [toInteger (tensorShape t!!axis) | t<-ts,length (tensorShape t)==length dims]
    if any (\t->length (tensorShape t)/=length dims || removeAt axis (tensorShape t)/=removeAt axis dims) ts || total>toInteger (maxBound::Int)
        then Left (InvalidArgument "concatenate: incompatible shapes or dimension overflow") else do
            let output=replaceAt axis (fromInteger total) dims
                locate position (t:rest) | position<tensorShape t!!axis = (t,position)
                                         | otherwise = locate (position-tensorShape t!!axis) rest
                locate _ [] = error "concatenate: internal index invariant"
            _<-shapeSize output
            tensor output [let (t,j)=locate (ix!!axis) ts in unsafeIndex t (replaceAt axis j ix) | ix<-allIndices output]
stack :: Int -> [Tensor a] -> Either MathError (Tensor a)
stack axis ts = traverse (unsqueeze axis) ts >>= concatenate axis
splitTensor :: Int -> [Int] -> Tensor a -> Either MathError [Tensor a]
splitTensor axis sizes t = do
    axisValid axis t
    if any (<0) sizes || sum (map toInteger sizes)/=toInteger (tensorShape t!!axis) then Left (InvalidArgument "splitTensor: sizes must partition axis") else
        sequence [sliceTensor axis start count 1 t | (start,count)<-zip (scanl (+) 0 sizes) sizes]
chunkTensor :: Int -> Int -> Tensor a -> Either MathError [Tensor a]
chunkTensor axis chunks t = do
    axisValid axis t
    if chunks<=0 then Left (InvalidArgument "chunkTensor: positive chunk count required") else do
        let n=tensorShape t!!axis; (q,r)=n `divMod` chunks
        splitTensor axis [q+if i<r then 1 else 0 | i<-[0..chunks-1]] t
padTensor :: [(Int,Int)] -> a -> Tensor a -> Either MathError (Tensor a)
padTensor padding value t
    | length padding/=length (tensorShape t) || any (\(a,b)->a<0||b<0) padding = Left (InvalidArgument "padTensor: invalid padding")
    | any (>toInteger (maxBound::Int)) dimensions = Left (InvalidArgument "padTensor: dimension overflow")
    | otherwise = do
        let output=map fromInteger dimensions
        _<-shapeSize output
        tensor output [let old=zipWith (-) ix (map fst padding) in if validIndex (tensorShape t) old then unsafeIndex t old else value | ix<-allIndices output]
    where dimensions=zipWith (\d (a,b)->toInteger d+toInteger a+toInteger b) (tensorShape t) padding
roll :: Int -> Int -> Tensor a -> Either MathError (Tensor a)
roll axis shift t = do
    axisValid axis t
    let dims=tensorShape t; n=dims!!axis
    tensor dims [unsafeIndex t (replaceAt axis (fromInteger ((toInteger (ix!!axis)-toInteger shift) `mod` toInteger n)) ix) | ix<-allIndices dims]
flipTensor :: Int -> Tensor a -> Either MathError (Tensor a)
flipTensor axis t = do
    axisValid axis t
    let n=tensorShape t!!axis
    sliceTensor axis (max 0 (n-1)) n (-1) t
rotate :: Int -> Int -> Int -> Tensor a -> Either MathError (Tensor a)
rotate axisA axisB turns t = do
    axisValid axisA t; axisValid axisB t
    if axisA==axisB then Left (InvalidArgument "rotate: distinct axes required") else go (turns `mod` 4) t
    where go 0 x=Right x
          go k x=swapAxes axisA axisB x >>= flipTensor axisA >>= go (k-1)
sortTensor :: Ord a => Tensor a -> Either MathError (Tensor a)
sortTensor t = tensor [numel t] (sort (tensorValues t))
argsort :: Ord a => Tensor a -> Either MathError (Tensor Int)
argsort t = tensor [numel t] (map fst (sortOn snd (zip [0..] (tensorValues t))))
topk :: Ord a => Int -> Tensor a -> Either MathError (Tensor a,Tensor Int)
topk k t
    | k<0 || k>numel t = Left (InvalidArgument "topk: invalid k")
    | otherwise = let selected=take k (reverse (sortOn snd (zip [0..] (tensorValues t)))) in (,) <$> tensor [k] (map snd selected) <*> tensor [k] (map fst selected)
unique :: Ord a => Tensor a -> Either MathError (Tensor a)
unique t = let xs=M.keys (M.fromList [(x,()) | x<-tensorValues t]) in tensor [length xs] xs
nonzero :: (Eq a,Num a) => Tensor a -> Either MathError (Tensor Int)
nonzero t = let ix=[is | is<-allIndices (tensorShape t),unsafeIndex t is/=0] in tensor [length ix,length (tensorShape t)] (concat ix)
whereTensor :: Tensor Bool -> Tensor a -> Tensor a -> Either MathError (Tensor a)
whereTensor mask yes no = do
    dims<-inferBroadcast (tensorShape yes) (tensorShape no) >>= inferBroadcast (tensorShape mask)
    m<-broadcastTo dims mask; y<-broadcastTo dims yes; n<-broadcastTo dims no
    tensor dims (zipWith3 (\condition a b->if condition then a else b) (tensorValues m) (tensorValues y) (tensorValues n))
maskedFill :: Tensor Bool -> a -> Tensor a -> Either MathError (Tensor a)
maskedFill mask value t = do full<-tensorFull (tensorShape t) value; whereTensor mask full t
maskedSelect :: Tensor Bool -> Tensor a -> Either MathError (Tensor a)
maskedSelect mask t
    | tensorShape mask/=tensorShape t = Left (InvalidArgument "maskedSelect: mask shape mismatch")
    | otherwise = let xs=[x | (True,x)<-zip (tensorValues mask) (tensorValues t)] in tensor [length xs] xs
-- | Apply scalar arithmetic, comparisons, logic, or elementary functions such
-- as @sin@, @exp@, and @log@ to each logical element. A contiguous output is
-- created; scalar numeric domain/overflow behavior follows the supplied function.
mapTensor :: (a -> b) -> Tensor a -> Tensor b
mapTensor f t = case tensor (tensorShape t) (map f (tensorValues t)) of Right r->r; Left _->error "mapTensor: shape invariant"
zipTensor :: (a -> b -> c) -> Tensor a -> Tensor b -> Either MathError (Tensor c)
zipTensor f a b = do
    dims<-inferBroadcast (tensorShape a) (tensorShape b)
    x<-broadcastTo dims a; y<-broadcastTo dims b
    tensor dims (zipWith f (tensorValues x) (tensorValues y))
tensorAdd :: Num a => Tensor a -> Tensor a -> Either MathError (Tensor a)
tensorAdd = zipTensor (+)
tensorSubtract :: Num a => Tensor a -> Tensor a -> Either MathError (Tensor a)
tensorSubtract = zipTensor (-)
tensorMultiply :: Num a => Tensor a -> Tensor a -> Either MathError (Tensor a)
tensorMultiply = zipTensor (*)
tensorDivide :: Fractional a => Tensor a -> Tensor a -> Either MathError (Tensor a)
tensorDivide = zipTensor (/)
tensorEqual :: Eq a => Tensor a -> Tensor a -> Either MathError (Tensor Bool)
tensorEqual = zipTensor (==)
tensorLess :: Ord a => Tensor a -> Tensor a -> Either MathError (Tensor Bool)
tensorLess = zipTensor (<)
tensorAnd :: Tensor Bool -> Tensor Bool -> Either MathError (Tensor Bool)
tensorAnd = zipTensor (&&)
tensorOr :: Tensor Bool -> Tensor Bool -> Either MathError (Tensor Bool)
tensorOr = zipTensor (||)
tensorNot :: Tensor Bool -> Tensor Bool
tensorNot = mapTensor not
promoteTensor :: (Real a,Fractional b) => Tensor a -> Tensor b
promoteTensor = mapTensor realToFrac

reduceAxes :: (b -> a -> b) -> b -> [Int] -> Bool -> Tensor a -> Either MathError (Tensor b)
reduceAxes f initial axes keep t
    | length (nub axes)/=length axes || any (\i->i<0||i>=length dims) axes = Left (InvalidArgument "reduction: invalid/duplicate axis")
    | otherwise = do
        let output=if keep then [if i `elem` axes then 1 else d | (i,d)<-zip [0..] dims] else [d | (i,d)<-zip [0..] dims,i `notElem` axes]
            key ix=if keep then [if i `elem` axes then 0 else x | (i,x)<-zip [0..] ix] else [x | (i,x)<-zip [0..] ix,i `notElem` axes]
            accumulated=foldl (\m ix->M.alter (Just . (\old->f old (unsafeIndex t ix)) . maybe initial id) (key ix) m) M.empty (allIndices dims)
        tensor output [M.findWithDefault initial ix accumulated | ix<-allIndices output]
    where dims=tensorShape t
sumAxes :: Num a => [Int] -> Bool -> Tensor a -> Either MathError (Tensor a)
sumAxes = reduceAxes (+) 0
productAxes :: Num a => [Int] -> Bool -> Tensor a -> Either MathError (Tensor a)
productAxes = reduceAxes (*) 1
meanAxes :: Fractional a => [Int] -> Bool -> Tensor a -> Either MathError (Tensor a)
meanAxes axes keep t = do
    summed<-sumAxes axes keep t
    let count=product [toInteger (tensorShape t!!i) | i<-axes]
    if count==0 && numel summed>0 then Left (DomainError "meanAxes: empty reduction") else Right (mapTensor (/fromInteger count) summed)
reduceNonempty :: (a -> a -> a) -> [Int] -> Bool -> Tensor a -> Either MathError (Tensor a)
reduceNonempty f axes keep t = do
    reduced<-reduceAxes (\old x->Just (maybe x (`f` x) old)) Nothing axes keep t
    case sequence (tensorValues reduced) of Nothing->Left (DomainError "reduction: empty axis"); Just xs->tensor (tensorShape reduced) xs
minAxes :: Ord a => [Int] -> Bool -> Tensor a -> Either MathError (Tensor a)
minAxes = reduceNonempty min
maxAxes :: Ord a => [Int] -> Bool -> Tensor a -> Either MathError (Tensor a)
maxAxes = reduceNonempty max
argExtreme :: Ord a => (a -> a -> Bool) -> Tensor a -> Either MathError Int
argExtreme better t = case zip [0..] (tensorValues t) of
    []->Left (DomainError "argmin/argmax: empty tensor")
    x:xs->Right (fst (foldl (\old new->if better (snd new) (snd old) then new else old) x xs))
argmin :: Ord a => Tensor a -> Either MathError Int
argmin = argExtreme (<)
argmax :: Ord a => Tensor a -> Either MathError Int
argmax = argExtreme (>)
varianceAxes :: Fractional a => [Int] -> Bool -> Tensor a -> Either MathError (Tensor a)
varianceAxes axes keep t = do
    means<-meanAxes axes True t
    deviations<-zipTensor (\x m->(x-m)*(x-m)) t means
    meanAxes axes keep deviations
normAxes :: RealFloat a => [Int] -> Bool -> Tensor a -> Either MathError (Tensor a)
normAxes axes keep t = do
    pairs<-reduceAxes accumulate (0,1) axes keep t
    Right (mapTensor (\(scale,ssq)->if scale==0 then 0 else scale*sqrt ssq) pairs)
    where
    accumulate (scale,ssq) x
        | isNaN x || isNaN scale = (0/0,0/0)
        | isInfinite x || isInfinite scale = (1/0,1)
        | x==0 = (scale,ssq)
        | scale<abs x = (abs x,1+ssq*(scale/abs x)^(2::Int))
        | otherwise = (scale,ssq+(abs x/scale)^(2::Int))
cumulative :: (a -> a -> a) -> a -> Int -> Tensor a -> Either MathError (Tensor a)
cumulative f initial axis t = do
    axisValid axis t
    tensor (tensorShape t) [foldl f initial [unsafeIndex t (replaceAt axis k ix) | k<-[0..ix!!axis]] | ix<-allIndices (tensorShape t)]
cumulativeSum :: Num a => Int -> Tensor a -> Either MathError (Tensor a)
cumulativeSum = cumulative (+) 0
cumulativeProduct :: Num a => Int -> Tensor a -> Either MathError (Tensor a)
cumulativeProduct = cumulative (*) 1

tensordot :: Num a => [Int] -> [Int] -> Tensor a -> Tensor a -> Either MathError (Tensor a)
tensordot axesA axesB a b
    | length axesA/=length axesB || length (nub axesA)/=length axesA || length (nub axesB)/=length axesB
        || any (\i->i<0||i>=length da) axesA || any (\i->i<0||i>=length db) axesB = Left (InvalidArgument "tensordot: invalid axes")
    | map (da!!) axesA/=map (db!!) axesB = Left (InvalidArgument "tensordot: contracted dimensions differ")
    | otherwise = do
        _<-shapeSize output
        let na=length freeA
            position axis contracted frees ix contraction = case elemIndex axis contracted of
                Just p->contraction!!p
                Nothing->case elemIndex axis frees of Just p->ix!!p;Nothing->error "tensordot axis invariant"
        tensor output [sum [unsafeIndex a [position axis axesA freeA (take na ix) contracted | axis<-[0..length da-1]]
                           *unsafeIndex b [position axis axesB freeB (drop na ix) contracted | axis<-[0..length db-1]]
                           | contracted<-allIndices (map (da!!) axesA)] | ix<-allIndices output]
    where da=tensorShape a; db=tensorShape b
          freeA=[i | i<-[0..length da-1],i `notElem` axesA];freeB=[i | i<-[0..length db-1],i `notElem` axesB]
          output=map (da!!) freeA++map (db!!) freeB
-- | Explicit Einstein notation; each operand has one label per axis. Repeated
-- labels select diagonals; absent output labels are summed. Ellipses are not
-- accepted: callers express batch labels explicitly, preventing ambiguity.
einsum :: Num a => [String] -> String -> [Tensor a] -> Either MathError (Tensor a)
einsum labels output operands
    | length labels/=length operands || or (zipWith (\ls t->length ls/=length (tensorShape t)) labels operands)
        || length (nub output)/=length output = Left (InvalidArgument "einsum: invalid label ranks or duplicate output labels")
    | any (`notElem` allLabels) output = Left (InvalidArgument "einsum: unknown output label")
    | any (\ls->any (\(x,y)->x/=y) [(d,dimension l) | (l,d)<-ls]) labeledDims = Left (InvalidArgument "einsum: label dimensions differ")
    | otherwise = do
        let dims=map dimension output; contracted=filter (`notElem` output) allLabels
        _<-shapeSize dims
        tensor dims [sum [let environment=M.fromList (zip output ix++zip contracted ks)
                          in product [unsafeIndex t [environment M.! l | l<-ls] | (ls,t)<-zip labels operands]
                         | ks<-allIndices (map dimension contracted)] | ix<-allIndices dims]
    where labeledDims=zipWith (\ls t->zip ls (tensorShape t)) labels operands
          allLabels=nub (concat labels)
          dimension l=case [d | ls<-labeledDims,(name,d)<-ls,name==l] of d:_->d;[]->0
batchedMatmul :: Num a => Tensor a -> Tensor a -> Either MathError (Tensor a)
batchedMatmul a b
    | length da<2 || length db<2 = Left (InvalidArgument "batchedMatmul: ranks must be at least two")
    | da!!(length da-1)/=db!!(length db-2) = Left (InnerDimensionMismatch (last da) (db!!(length db-2)))
    | otherwise = do
        batch<-inferBroadcast (take (length da-2) da) (take (length db-2) db)
        let m=da!!(length da-2); n=last db; k=last da
        av<-broadcastTo (batch++[m,k]) a;bv<-broadcastTo (batch++[k,n]) b
        let output=batch++[m,n];rank=length batch
        _<-shapeSize output
        tensor output [sum [unsafeIndex av (take rank ix++[ix!!rank,l])*unsafeIndex bv (take rank ix++[l,ix!!(rank+1)]) | l<-[0..k-1]] | ix<-allIndices output]
    where da=tensorShape a;db=tensorShape b
tensorKronecker :: Num a => Tensor a -> Tensor a -> Either MathError (Tensor a)
tensorKronecker a b
    | any (>toInteger (maxBound::Int)) dimensions = Left (InvalidArgument "tensorKronecker: dimension overflow")
    | otherwise = do
        av<-reshapeTensor da a;bv<-reshapeTensor db b
        let output=map fromInteger dimensions
        _<-shapeSize output
        tensor output [unsafeIndex av (zipWith div ix db)*unsafeIndex bv (zipWith mod ix db) | ix<-allIndices output]
    where rank=max (length (tensorShape a)) (length (tensorShape b));pad xs=replicate (rank-length xs) 1++xs
          da=pad (tensorShape a);db=pad (tensorShape b);dimensions=zipWith (\x y->toInteger x*toInteger y) da db
serializeTensor :: Show a => Tensor a -> String
serializeTensor t = show (tensorShape t,tensorValues t)
deserializeTensor :: Read a => String -> Either MathError (Tensor a)
deserializeTensor input = case reads input of
    [((dims,xs),rest)] | all (`elem` " \n\r\t") rest -> tensor dims xs
    _->Left (InvalidArgument "deserializeTensor: invalid shape/value encoding")

-- | Lazy expression trees defer computation. Evaluation fuses adjacent maps
-- and composes per-element expressions through broadcasted binary nodes; only
-- the output array is allocated. Shape errors are checked before evaluation.
data TensorGraph a = Graph [Int] ([Int] -> a)
inputGraph :: Tensor a -> TensorGraph a
inputGraph t = Graph (tensorShape t) (unsafeIndex t)
mapGraph :: (a -> b) -> TensorGraph a -> TensorGraph b
mapGraph f (Graph dims action) = Graph dims (f . action)
zipGraph :: (a -> b -> c) -> TensorGraph a -> TensorGraph b -> Either MathError (TensorGraph c)
zipGraph f (Graph da a) (Graph db b) = do
    dims<-inferBroadcast da db
    let select source ix=zipWith (\d i->if d==1 then 0 else i) source (drop (length dims-length source) ix)
    Right (Graph dims (\ix->f (a (select da ix)) (b (select db ix))))
evaluateGraph :: TensorGraph a -> Either MathError (Tensor a)
evaluateGraph (Graph dims action) = tensor dims [action ix | ix<-allIndices dims]
