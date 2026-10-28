# Wave API

The binding lives in `bindings/wave/hmath.wave` and mirrors the checked C ABI.
Operations return integer status codes: zero is success. Output arguments
are valid only when the status reports success.

| Function | Purpose |
| --- | --- |
| `scalar_add` | Add two `f64` values through an output pointer. |
| `tensor_empty` | Construct an empty wrapper before using an output argument. |
| `tensor_copy` | Copy values with explicit dimensions and rank. |
| `vector_copy` | Copy a vector. |
| `matrix_copy` | Copy a row-major matrix. |
| `tensor_values` | Copy values to a caller-provided output buffer. |
| `tensor_sum`, `tensor_dot` | Scalar reductions. |
| `tensor_add`, `tensor_matmul` | Create a new tensor result. |
| `tensor_clone` | Retain an independent native reference. |
| `tensor_close` | Release the wrapper's reference and reset it. |

Native rank, size, and arithmetic limits are shared with the
[C ABI](c.md). Use `tensor_clone` when creating another owner: assigning a
wrapper by value does not automatically retain its handle.

## Binding source

The maintained declarations and wrappers are included directly:

```text
--8<-- "bindings/wave/hmath.wave"
```

See [Wave integration](../guides/wave.md) for compiler and linking instructions.
