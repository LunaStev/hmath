# Foundation, discrete structures and convergence

These functions call the original Haskell algorithms. Persistent heaps/multisets retain the actual original element ordering dictionary; exact integers, coefficient dtypes, strings, tuples and registered mathematical values are not converted through FP64. Sampling/combinatorial output limits, bit widths, logic depth/input caps, resource defaults and source error conventions remain unchanged. Objects own independent immutable references and support `close()`/context management.

Generic checked callbacks use plain successful return values and raise a `MathError` to return source Left. Pure callbacks abort on failure. Unexpected Python exceptions are rethrown after native cleanup. Callback owners are retained transitively. Convergence reports retain their estimate even when iteration/stagnation limits stop execution; inspect `stop_reason` or use `require_convergence`. Generic Either results use explicit Left/Right owners; optional Just(None) is preserved as a Just owner.

## Ordered element prototypes

Ord operations infer an actual Haskell dictionary from the supplied values. For all-None or recursively empty inputs, supply an explicit `prototype=`; it selects a type without adding data to the source algorithm. C uses the corresponding `_typed` overload. `ordered_type(example)` retains a representative original Ord dictionary and `optional_type(prototype)` constructs the original `Ord (Maybe a)` dictionary, including nesting. Empty heaps/multisets normally defer their dictionary until the first element arrives.

```python
from hmath import convergence, datastructure

with convergence.optional_type(0) as optional_integer:
    with datastructure.heap_from_list([None, None], prototype=optional_integer) as heap:
        first, remaining = datastructure.heap_pop(heap)
        assert first is None
        remaining.close()
```

`None` represents Nothing; `convergence.just(None)` distinguishes Just Nothing when optional layers nest. Generic Either values retain explicit Left/Right via `left`, `right`, and `.parts`. Prototypes and every returned owner support `close()`/context management. Equality-dependent grouping uses original dictionaries for supported scalar/recursive values, Foundation records, Polynomial/PowerSeries/RationalFunction, numeric/Bool/String/Exact Matrix and Tensor, and original AD.Dual full-field equality. NaNs and tensor views retain their source equality behavior. This finite transport does not invent Eq/Ord for arbitrary custom Haskell types.

## `datastructure.fenwick`

Build an immutable Fenwick prefix-sum tree from at most 1048576 Integers. Oversized input fails; indices in public operations are zero based.

Original signature: `[Integer] -> Either MathError Fenwick`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.fenwick_add`

Given zero-based index,delta,then Fenwick tree, return a new tree with that value incremented. Invalid index returns Left InvalidArgument.

Original signature: `Int -> Integer -> Fenwick -> Either MathError Fenwick`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.fenwick_prefix`

Given exclusive end then tree, return exact sum over [0,end). Require 0\<=end\<=length; invalid bounds fail.

Original signature: `Int -> Fenwick -> Either MathError Integer`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.fenwick_range`

Given lo,hi,then tree, return exact half-open sum over [lo,hi). Invalid/reversed bounds fail; empty range gives zero.

Original signature: `Int -> Int -> Fenwick -> Either MathError Integer`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.segment_tree`

Build an immutable Integer sum segment tree from at most 1048576 values. Invalid size fails; later queries use half-open bounds.

Original signature: `[Integer] -> Either MathError SegmentTree`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.segment_set`

Given zero-based index,new Integer,then segment tree, return an updated tree. Invalid index fails; the original remains unchanged.

Original signature: `Int -> Integer -> SegmentTree -> Either MathError SegmentTree`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.segment_range`

Given lo,hi,then segment tree, return Integer sum over [lo,hi). Invalid bounds fail; an empty range gives zero.

Original signature: `Int -> Int -> SegmentTree -> Either MathError Integer`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.sparse_table`

Precompute range minima for at most 1048576 Integers. Return immutable sparse table; oversized input fails.

Original signature: `[Integer] -> Either MathError SparseTable`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.sparse_minimum`

Given lo,hi,then sparse table, return minimum over nonempty [lo,hi). Out-of-range/reversed or empty bounds fail.

Original signature: `Int -> Int -> SparseTable -> Either MathError Integer`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.disjoint_sparse_table`

Suffix/prefix blocks for associative integer addition, O(n log n) build and O(1) arithmetic for nonempty queries. Also handles an empty range as zero.

Original signature: `[Integer] -> Either MathError DisjointSparseTable`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.disjoint_range`

Given lo,hi,then disjoint sparse sum table, return exact sum over [lo,hi). Invalid bounds fail; empty range yields zero.

Original signature: `Int -> Int -> DisjointSparseTable -> Either MathError Integer`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.next_greater`

For each list position, return Maybe index of its first strictly greater element to the right, using a monotone stack. Preserve input length; absent successors yield Nothing.

Original signature: `[a] -> [Maybe Int]`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.empty_heap`

Construct an empty persistent leftist min-heap. heapPop returns Nothing until values are inserted.

Original signature: `Heap a`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.heap_insert`

Given value then persistent min-heap, return a new heap containing it. Duplicate values are retained; original heap remains valid.

Original signature: `a -> Heap a -> Heap a`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.heap_pop`

Return Nothing for empty heap, otherwise Just (smallest value,remaining heap). Ties follow lawful Ord without discarding duplicates.

Original signature: `Heap a -> Maybe (a, Heap a)`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.heap_from_list`

Build a persistent min-heap from a finite list, retaining all elements including duplicates.

Original signature: `[a] -> Heap a`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.binary_heap`

Build an array-backed Integer min-heap from at most 1048576 values. Oversized input fails.

Original signature: `[Integer] -> Either MathError BinaryHeap`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.binary_insert`

Given Integer then binary heap, return a persistent updated min-heap. The insert operation itself has no Either size check.

Original signature: `Integer -> BinaryHeap -> BinaryHeap`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.binary_pop`

Return Nothing if empty, otherwise the smallest Integer and a new binary heap containing the remaining values.

Original signature: `BinaryHeap -> Maybe (Integer, BinaryHeap)`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.indexed_heap`

Construct an empty indexed priority queue. Each Int key has at most one Integer priority.

Original signature: `IndexedHeap`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.indexed_set`

Given Int key,Integer priority,then indexed heap, set or replace that key's priority. Return a new queue; an existing key is updated, not duplicated.

Original signature: `Int -> Integer -> IndexedHeap -> IndexedHeap`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.indexed_pop`

Return Just ((key,priority),remaining queue) for the minimum (priority,key) pair, or Nothing if empty.

Original signature: `IndexedHeap -> Maybe ((Int, Integer), IndexedHeap)`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.union_find`

Construct disjoint singleton sets for n zero-based elements, requiring n in [0,1048576]. Invalid size fails.

Original signature: `Int -> Either MathError UnionFind`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.find_root`

Given element index then union-find structure, return representative root. Invalid index fails; this pure query does not mutate/compress the stored structure.

Original signature: `Int -> UnionFind -> Either MathError Int`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.union`

Given two valid indices then union-find, return a new structure merging their components by size. Invalid indices fail; already connected inputs leave connectivity unchanged.

Original signature: `Int -> Int -> UnionFind -> Either MathError UnionFind`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.connected`

Given two indices then union-find, return whether their roots match. Invalid indices return Left InvalidArgument.

Original signature: `Int -> Int -> UnionFind -> Either MathError Bool`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.components`

Return all disjoint components as lists of zero-based element indices, including singleton sets.

Original signature: `UnionFind -> [[Int]]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.bloom`

Given bit count m in [1,1048576] then hash count k in [1,64], construct an empty Bloom filter. Invalid dimensions fail.

Original signature: `Int -> Int -> Either MathError Bloom`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.bloom_insert`

Given Word64 key then Bloom filter, set its k hash positions and return updated filter. Reinsertions are permitted; false positives remain possible.

Original signature: `Word64 -> Bloom -> Bloom`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.bloom_member`

Test a Word64 key against all Bloom hash positions. False means definitely absent; True may be a false positive under the documented hash model.

Original signature: `Word64 -> Bloom -> Bool`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.bloom_false_positive_bound`

Conservative union bound `min(1,k*n/m)^k` under independent uniform query hashes, since at most k*n bits can be occupied. This is a bound rather than the common exponential occupancy approximation.

Original signature: `Bloom -> Double`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.count_min`

Given positive width and depth with product\<=1048576, construct an empty count-min sketch. Invalid dimensions fail.

Original signature: `Int -> Int -> Either MathError CountMin`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.count_min_add`

Given Word64 key,nonnegative Integer increment,then sketch, increment its hash counters. Negative updates fail; return a persistent updated sketch.

Original signature: `Word64 -> Integer -> CountMin -> Either MathError CountMin`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.count_min_estimate`

Given Word64 key then sketch, return minimum associated counter as an Integer frequency estimate. It may overestimate through collisions; use countMinErrorBound for the documented model.

Original signature: `Word64 -> CountMin -> Integer`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.count_min_error_bound`

`(additive error, failure probability)` under the uniform-hash model.

Original signature: `CountMin -> (Double, Double)`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.hyper_log_log`

Construct an empty cardinality sketch from precision p in [4,16], using 2^p registers. Invalid precision fails; hllEstimate returns its probabilistic estimate.

Original signature: `Int -> Either MathError HyperLogLog`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.hll_add`

Given Word64 item then HyperLogLog sketch, hash and update its register maximum. Return persistent updated sketch; repeated items do not add a new exact count.

Original signature: `Word64 -> HyperLogLog -> HyperLogLog`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.hll_estimate`

HyperLogLog with linear-counting small-range correction. Typical relative standard error is approximately `1.04/sqrt(2^p)` under uniform hashing.

Original signature: `HyperLogLog -> Double`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.reservoir`

Given sample capacity in [0,1048576] then Word64 seed, construct an empty deterministic Algorithm-R reservoir. Invalid capacity fails.

Original signature: `Int -> Word64 -> Either MathError (Reservoir a)`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.reservoir_add`

Algorithm R with rejection sampling (no modulo bias). The 64-bit stream index is bounded; uniform sampling assumes the pseudorandom stream model.

Original signature: `a -> Reservoir a -> Either MathError (Reservoir a)`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.reservoir_values`

Return retained reservoir sample values. Their count never exceeds capacity; output order is storage order, not a sorted or arrival-order guarantee.

Original signature: `Reservoir a -> [a]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.online_quantiles`

Given exact-storage cap in [0,1048576], create an empty online order-statistics container. Invalid capacity fails; this retains exact values rather than a bounded-memory approximate sketch.

Original signature: `Int -> Either MathError OnlineQuantiles`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.quantile_add`

Given finite Double then quantile container, insert in sorted order. Non-finite values or a full cap fail without eviction; original container is unchanged.

Original signature: `Double -> OnlineQuantiles -> Either MathError OnlineQuantiles`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `datastructure.online_quantile`

Given finite q in [0,1] then nonempty quantile container, linearly interpolate order statistics at q*(n-1). Invalid q or empty state returns Left InvalidArgument.

Original signature: `Double -> OnlineQuantiles -> Either MathError Double`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.multiset`

Construct a finite multiset by counting equal ordered values with exact nonnegative Integer multiplicities.

Original signature: `[a] -> MultiSet a`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.multiplicity`

Given value then multiset, return its Integer frequency, or zero when absent.

Original signature: `a -> MultiSet a -> Integer`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.multiset_entries`

Return (value,positive multiplicity) pairs in ascending value order.

Original signature: `MultiSet a -> [(a, Integer)]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.multiset_insert`

Given value then multiset, increment its multiplicity by one and return a new multiset.

Original signature: `a -> MultiSet a -> MultiSet a`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.multiset_delete`

Given value then multiset, remove one occurrence, deleting its entry at zero. Absent values are a no-op.

Original signature: `a -> MultiSet a -> MultiSet a`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.multiset_union`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `MultiSet a -> MultiSet a -> MultiSet a`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.multiset_intersection`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `MultiSet a -> MultiSet a -> MultiSet a`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.multiset_difference`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `MultiSet a -> MultiSet a -> MultiSet a`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.bit_set`

Given width in [0,1048576] then nonnegative Integer less than 2^width, construct an opaque bitset. Invalid width/value fails; bit zero is least significant.

Original signature: `Int -> Integer -> Either MathError BitSet`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.bit_width`

Return declared number of bits, including leading zeros.

Original signature: `BitSet -> Int`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.bit_value`

Return unsigned Integer value of all bits within the declared width.

Original signature: `BitSet -> Integer`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.bit_member`

Given bitset then zero-based bit index, return membership. Out-of-width or negative indices return Left InvalidArgument.

Original signature: `BitSet -> Int -> Either MathError Bool`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.bit_insert`

Given bitset then valid bit index, return a new bitset with that bit set. Invalid index fails.

Original signature: `BitSet -> Int -> Either MathError BitSet`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.bit_delete`

Given bitset then valid bit index, return a new bitset with that bit cleared. Invalid index fails.

Original signature: `BitSet -> Int -> Either MathError BitSet`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.bit_union`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `BitSet -> BitSet -> Either MathError BitSet`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.bit_intersection`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `BitSet -> BitSet -> Either MathError BitSet`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.bit_difference`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `BitSet -> BitSet -> Either MathError BitSet`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.resize_bit_set`

Shrinking explicitly discards high bits.

Original signature: `Int -> BitSet -> Either MathError BitSet`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.population_count`

Count set bits within declared width, returning Int.

Original signature: `BitSet -> Int`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.leading_zeros`

Count high-end zero bits within declared width. All-zero bitset returns its full width.

Original signature: `BitSet -> Int`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.trailing_zeros`

Count low-end zero bits; an all-zero bitset returns its declared width.

Original signature: `BitSet -> Int`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.rotate_bits`

Given signed rotation count then bitset, rotate left modulo width (negative counts rotate right). Width-zero input is unchanged.

Original signature: `Int -> BitSet -> BitSet`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.reverse_bits`

Reverse exactly the declared width of bits, preserving width and leading/trailing zero positions.

Original signature: `BitSet -> BitSet`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.gray_encode`

Return width-preserving reflected Gray code v xor (v shifted right one).

Original signature: `BitSet -> BitSet`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.gray_decode`

Decode reflected Gray bits to the corresponding width-preserving binary value.

Original signature: `BitSet -> BitSet`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.hamming_distance`

Count differing bit positions between equal-width bitsets. Different widths return Left InvalidArgument.

Original signature: `BitSet -> BitSet -> Either MathError Int`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.transitive_closure`

Warshall closure. Paths must have positive length; use 'equivalenceClosure' when a reflexive closure is wanted.

Original signature: `[[Bool]] -> Either MathError [[Bool]]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.equivalence_closure`

Given square Bool relation matrix, add reflexivity and symmetry then compute transitive closure. Reject nonsquare or oversized (>512) relations.

Original signature: `[[Bool]] -> Either MathError [[Bool]]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.is_equivalence`

Return whether a bounded square Bool relation is already reflexive, symmetric and transitive. Invalid matrix shape/size fails.

Original signature: `[[Bool]] -> Either MathError Bool`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.boolean_multiply`

Multiply compatible square Bool relation matrices over OR/AND, representing relational composition. Invalid dimensions or size bounds fail.

Original signature: `[[Bool]] -> [[Bool]] -> Either MathError [[Bool]]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.evaluate_prop`

Given variable Bool assignment list then proposition, evaluate literals/variables/connectives. Invalid variable index or excessive expression depth returns Left MathError.

Original signature: `[Bool] -> Prop -> Either MathError Bool`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.truth_table`

Assignments in binary order, variable zero the least-significant bit.

Original signature: `Int -> Prop -> Either MathError [([Bool], Bool)]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.implicant_covers`

Given implicant then Integer minterm, compare bits where implicantMask is clear. True means this Boolean cube covers the minterm.

Original signature: `Implicant -> Integer -> Bool`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.quine_mc_cluskey`

Exact Quine--McCluskey prime generation followed by branch-and-bound cover selection. Objective is fewest terms, then literals, then lexical order. The explicit budget counts prime comparisons and covering-search nodes.

Original signature: `Int -> Int -> [Integer] -> [Integer] -> Either MathError [Implicant]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.literal`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.variable`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.logical_not`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.logical_and`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.logical_or`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.xor`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.implies`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.iff`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.implicant_value`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Implicant -> field`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.implicant_mask`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Implicant -> field`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `discrete.Implicant`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `algorithms.binary_search`

Given target and ascending list, return Just the first matching zero-based index or Nothing if absent. Reject unsorted input. Example: binarySearch 2 [1,2,2] == Right (Just 1).

Original signature: `a -> [a] -> Either MathError (Maybe Int)`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `algorithms.interpolation_search`

Search ascending Integer values using value-based interpolation, returning the first matching index or Nothing. Reject unsorted input. Example: interpolationSearch 20 [10,20,30] == Right (Just 1).

Original signature: `Integer -> [Integer] -> Either MathError (Maybe Int)`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `algorithms.exponential_search`

Given a target and ascending finite list, grow a search range then find a matching index or Nothing. Reject unsorted input. The implementation returns a matching index without a general first-duplicate guarantee.

Original signature: `a -> [a] -> Either MathError (Maybe Int)`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `algorithms.ternary_search`

Fixed-iteration minimization of a unimodal finite function on [lo,hi]. Returns the final bracket; unimodality is a caller precondition.

Original signature: `Int -> (Double -> Double) -> Double -> Double -> Either MathError (Double, Double)`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `algorithms.numeric_groups`

Sort ascending and return each distinct value paired with its frequency. Example: numericGroups [2,1,2] == [(1,1),(2,2)].

Original signature: `[a] -> [(a, Int)]`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `algorithms.run_length_encode`

Encode adjacent equal runs as (value,count), preserving run order without sorting. Example: runLengthEncode [1,1,2,1] == [(1,2),(2,1),(1,1)].

Original signature: `[a] -> [(a, Int)]`. Constraints: `(Eq a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `algorithms.run_length_decode`

Given maximum output length then (value,count) runs, expand runs. Negative budget/count fails; output beyond the budget returns NonConvergence before allocation. Zero-length runs are allowed.

Original signature: `Int -> [(a, Int)] -> Either MathError [a]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `algorithms.coordinate_compression`

Return sorted unique keys and zero-based ranks for the original input order. Example: coordinateCompression [8,2,8] == ([2,8],[1,0,1]).

Original signature: `[a] -> ([a], [Int])`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `algorithms.interval_sweep`

Half-open interval union length and peak overlap; zero-length intervals contribute neither. End events precede starts at the same coordinate.

Original signature: `[(Integer, Integer)] -> Either MathError (Integer, Int)`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `algorithms.divide_conquer_dp`

One DP layer `next[j] = min_{0<=k<j} previous[k]+cost k j`. Monotone argmins are checked against all candidates before returning; invalid optimization assumptions fail explicitly. O(n^2) validation.

Original signature: `[Double] -> (Int -> Int -> Double) -> Either MathError [Double]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `algorithms.tabulate_dp`

Bottom-up bounded DAG recurrence; dependencies must have lower indices.

Original signature: `Int -> (Int -> [(Int, Integer)]) -> Either MathError [Integer]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `algorithms.memoized_dp`

Top-down memoization with a node budget. Recurrence supplies an additive constant and weighted dependencies; cycles are rejected.

Original signature: `Int -> (Int -> (Integer, [(Int, Integer)])) -> Int -> Either MathError Integer`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `algorithms.integer_matrix_power`

Given square Integer rows and a nonnegative exponent, return exact matrix exponentiation by squaring; exponent zero returns identity. Reject ragged/non-square matrices, order >128, or negative exponent.

Original signature: `[[Integer]] -> Integer -> Either MathError [[Integer]]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `combinatorics.permutations_of`

Distinct positions, including when values compare equal.

Original signature: `Int -> Int -> [a] -> Either MathError [[a]]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `combinatorics.combinations_of`

Given output budget, selection length k, then list, enumerate position-distinct k-element combinations in source order. Invalid order or insufficient budget fails before output construction.

Original signature: `Int -> Int -> [a] -> Either MathError [[a]]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `combinatorics.derangements`

Enumeration uses the factorial upper bound, so a request may be rejected even if its filtered derangement output would fit.

Original signature: `Int -> Int -> Either MathError [[Int]]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `combinatorics.integer_partitions`

Nonincreasing positive parts. The budget counts search nodes as well as outputs, preventing long searches with a tiny output limit.

Original signature: `Int -> Int -> Either MathError [[Int]]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `combinatorics.set_partitions`

Set partitions of `[0,n)`, using restricted-growth order of block labels.

Original signature: `Int -> Int -> Either MathError [[[Int]]]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `combinatorics.pascal_triangle`

Return Pascal rows zero through n inclusive, starting [[1]]. n must lie in [0,512]; invalid orders fail.

Original signature: `Int -> Either MathError [[Integer]]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `combinatorics.subsets`

Given maximum output count then list, enumerate its position-based powerset. Reject input order >4096 or a budget smaller than 2^length. Equal input values can yield equal-valued subsets.

Original signature: `Int -> [a] -> Either MathError [[a]]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `combinatorics.cartesian_product`

Given output budget then a list of lists, return all ordered choices using sequence. Reject negative/insufficient budget before constructing results. Empty outer list yields one empty choice.

Original signature: `Int -> [[a]] -> Either MathError [[a]]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `combinatorics.multiset_permutations`

Given budget then ordered values, enumerate distinct multiset permutations in ascending lexicographic order. Invalid size or insufficient output budget fails before enumeration.

Original signature: `Int -> [a] -> Either MathError [[a]]`. Constraints: `(Ord a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `combinatorics.generating_coefficients`

Formal power-series division `P(x)/Q(x)` around zero, exact rationals. The denominator constant must be nonzero; no analytic convergence is claimed.

Original signature: `Int -> [Rational] -> [Rational] -> Either MathError [Rational]`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `combinatorics.finite_differences`

Return successive forward-difference rows beginning with the original list and ending at the last singleton. Empty input yields no rows. Example: finiteDifferences [1,4,9] == [[1,4,9],[3,5],[2]].

Original signature: `[a] -> [[a]]`. Constraints: `(Num a)`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.default_iteration_options`

Default iteration budget 1000, absolute tolerance 1e-12, relative tolerance 1e-10. Use record updates to configure a solver; iterateUntil validates nonnegative finite tolerances.

Original signature: `IterationOptions`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.iterate_until`

Stop at residual <= atol + rtol * initialResidual. Comparisons are scaled to avoid overflow in that sum. The initial value is tested at iteration zero.

Original signature: `IterationOptions -> (a -> Either MathError a) -> (a -> Either MathError Double) -> (a -> a -> Bool) -> a -> Either MathError (Convergence a)`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.require_convergence`

Given operation name then convergence report, return its estimate only for ResidualSatisfied. IterationLimit or Stagnation becomes Left (NonConvergence name iterationCount), preserving the distinction between execution and convergence.

Original signature: `String -> Convergence a -> Either MathError a`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.result_maybe`

Explicitly discard error details for callers retaining a Maybe interface.

Original signature: `Either e a -> Maybe a`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.from_maybe_error`

Given error value then Maybe result, convert Nothing to Left error and Just x to Right x. Example: fromMaybeError "missing" (Just 3) == Right 3.

Original signature: `e -> Maybe a -> Either e a`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.residual_satisfied`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.iteration_limit`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.stagnation`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.estimate`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Convergence -> field`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.iteration_count`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Convergence -> field`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.final_residual`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Convergence -> field`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.stop_reason`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `Convergence -> field`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.Convergence`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.maximum_iterations`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `IterationOptions -> field`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.absolute_tolerance`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `IterationOptions -> field`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.relative_tolerance`

Read the original immutable public field; no numerical conversion is performed.

Original signature: `IterationOptions -> field`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.IterationOptions`

Construct the original public variant; positional fields retain their exact source types and order.

Original signature: `constructor`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

## `convergence.converged`

Read-only successful view. The report still retains its residual and count.

Original signature: `Convergence a -> Maybe a (read-only source pattern)`. Constraints: `none`. C arguments are borrowed Values in source order; a successful output owns one reference and failure leaves it untouched.

