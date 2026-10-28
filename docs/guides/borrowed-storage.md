# Borrow storage safely in C

Use `hmath_tensor_borrow` when copying a read-only binary64 buffer is
undesirable. The caller must guarantee valid aligned storage, its readable
span, and immutability through **every alias** until the last storage owner
is released. See [C integration](c.md) for compiler and linker setup.

## Give the tensor a cleanup callback

This complete example allocates three values, borrows them, reshapes the
tensor without copying, and checks that cleanup happens only after both
handles are released. Metadata and ownership operations need no runtime
initialization.

```c
#include <hmath.h>
#include <assert.h>
#include <stdlib.h>

struct storage_owner {
    double *values;
    unsigned releases;
};

static void release_storage(void *userdata, const double *data) {
    struct storage_owner *owner = userdata;
    assert(data == owner->values);
    free(owner->values);
    owner->values = NULL;
    owner->releases++;
}

int main(void) {
    struct storage_owner owner = {malloc(3 * sizeof(double)), 0};
    hmath_tensor *vector = NULL, *matrix = NULL;
    const size_t vector_shape[] = {3}, matrix_shape[] = {1, 3};
    hmath_status status;
    if (!owner.values) return 1;
    owner.values[0] = 1; owner.values[1] = 2; owner.values[2] = 3;
    status = hmath_tensor_borrow(owner.values, 3, vector_shape, NULL, 1,
                                 release_storage, &owner, &vector);
    if (status != HMATH_OK) {
        free(owner.values); /* Failed construction did not consume storage. */
        return 1;
    }
    status = hmath_tensor_reshape(vector, matrix_shape, 2, &matrix);
    hmath_tensor_release(vector);
    if (status != HMATH_OK) return 1; /* Final vector release already cleaned up. */
    assert(owner.releases == 0);
    hmath_tensor_release(matrix);
    assert(owner.releases == 1);
    return 0;
}
```

The expected exit status is zero. The `userdata` object lives on the stack
until both handles have been released. A real application must retain its
owner object for at least as long as any handle or exported view can survive.

## Check strided layouts

For nonnegative element strides $s_i$ and dimensions $d_i$, a nonempty
tensor reaches a storage span of

$$
1+\sum_i(d_i-1)s_i.
$$

`storage_count` must cover that span, including gaps; it is not simply the
product of dimensions. C strides are measured in **doubles**, not bytes.
Passing NULL strides selects contiguous row-major storage. An empty tensor
does not read any values. Rank zero is a scalar and needs one value.

## Avoid lifetime errors

The deleter runs synchronously on the final releasing thread, exactly once
for successfully borrowed storage. It must not throw across C or invoke
runtime shutdown. Failed construction leaves ownership with the caller.
`hmath_tensor_data` returns a borrowed pointer and does not create another
owner; never free that pointer separately.

See [the C reference](../reference/c.md),
[architecture and ownership](../explanation/architecture.md), and
[NumPy borrowing](numpy.md) for related contracts.
