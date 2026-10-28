# Integrate with C

Build the native library using the [source-build guide](build.md). C programs
use `include/hmath.h`; Python wheel contents are an implementation detail,
not a system C development installation.

## A checked scalar call

```c
#include <stdio.h>
#include "hmath.h"

int main(void) {
    if (hmath_init() != HMATH_INIT_OK)
        return 1;
    double result = 0.0;
    hmath_status status = hmath_scalar_add(NULL, 2.0, 3.0, &result);
    if (status != HMATH_OK) {
        fprintf(stderr, "%s\n", hmath_last_error_message());
        return 1;
    }
    printf("%.1f\n", result);
    return hmath_runtime_shutdown() == HMATH_OK ? 0 : 1;
}
```

Save it as `example.c` in the checkout, then compile and run:

```sh
cc -std=c11 example.c -Iinclude -Lbuilddir -lhmath \
  -Wl,-rpath,"$PWD/builddir" -o example
./example
```

The expected output is `5.0`.

## Ownership and errors

- Release each successfully created tensor with `hmath_tensor_release`.
- Retain a reference before sharing a handle with another independent owner.
- Check status before reading numerical outputs; outputs are written only
  on success, except APIs that explicitly report partial batch progress.
- Copy the thread-local error message before the next checked operation.
- Shut down only after joining all workers and finishing all library use.

The [C ABI reference](../reference/c.md) contains the complete public header,
status codes, limits, and callback contracts.
