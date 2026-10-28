/* SPDX-License-Identifier: MPL-2.0 */
#include "hmath_backend.h"
#include <limits.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>
typedef HMODULE libhandle;
static libhandle loadlib(const char *p) { return LoadLibraryA(p); }
static void *symbol(libhandle h, const char *p) { return (void *)GetProcAddress(h, p); }
static void unload(libhandle h) {
    if (h)
        FreeLibrary(h);
}
#else
#include <dlfcn.h>
typedef void *libhandle;
static libhandle loadlib(const char *p) { return dlopen(p, RTLD_NOW | RTLD_LOCAL); }
static void *symbol(libhandle h, const char *p) { return dlsym(h, p); }
static void unload(libhandle h) {
    if (h)
        dlclose(h);
}
#endif
struct hmath_backend {
    libhandle library;
    int provider, bits, blis_bits;
    char suffix[8];
};
static void *bsym(hmath_backend *b, const char *name) {
    char buffer[96];
    if (snprintf(buffer, sizeof(buffer), "%s%s", name, b->suffix) < 0)
        return NULL;
    return symbol(b->library, buffer);
}
static atomic_flag mkl_lock = ATOMIC_FLAG_INIT;
static int mkl_bits = 0;
static libhandle mkl_pinned = NULL;
hmath_backend *hmath_backend_open(int provider, int bits, const char *path, int *status) {
    *status = 1;
#ifdef HMATH_DISABLE_NATIVE
    (void)provider;
    (void)bits;
    (void)path;
    return NULL;
#endif
    if (bits != 32 && bits != 64) {
        *status = 2;
        return NULL;
    }
    const char *mode = getenv("HMATH_BACKEND");
    if (mode && strcmp(mode, "pure") == 0)
        return NULL;
    if (mode && strcmp(mode, "auto") != 0) {
        *status = 2;
        return NULL;
    }
    const char *default_path = NULL;
#ifdef _WIN32
    if (provider == 1)
        default_path = bits == 64 ? "libopenblas64_.dll" : "libopenblas.dll";
    if (provider == 2)
        default_path = "libblis.dll";
    if (provider == 3)
        default_path = "mkl_rt.dll";
#elif defined(__APPLE__)
    if (provider == 1)
        default_path = bits == 64 ? "libopenblas64_.dylib" : "libopenblas.dylib";
    if (provider == 2)
        default_path = "libblis.dylib";
    if (provider == 3)
        default_path = "libmkl_rt.dylib";
    if (provider == 4)
        default_path = "/System/Library/Frameworks/Accelerate.framework/Accelerate";
#else
    if (provider == 1)
        default_path = bits == 64 ? "libopenblas64_.so.0" : "libopenblas.so.0";
    if (provider == 2)
        default_path = "libblis.so.4";
    if (provider == 3)
        default_path = "libmkl_rt.so";
#endif
    if (!default_path || provider < 1 || provider > 4)
        return NULL;
    hmath_backend *b = calloc(1, sizeof(*b));
    if (!b) {
        *status = 3;
        return NULL;
    }
    b->provider = provider;
    b->bits = bits;
    b->library = loadlib(path && *path ? path : default_path);
    if (!b->library) {
        free(b);
        return NULL;
    }
    if (provider == 1) {
        typedef const char *(*config_t)(void);
        config_t config = (config_t)symbol(b->library, "openblas_get_config");
        if (!config) {
            config = (config_t)symbol(b->library, "openblas_get_config64_");
            if (config)
                strcpy(b->suffix, "64_");
        }
        if (!config) {
            *status = 2;
            goto fail;
        }
        const char *s = config();
        int actual = s && (strstr(s, "USE64BITINT") || strstr(s, "USE_64BITINT")) ? 64 : 32;
        if (actual != bits) {
            *status = 2;
            goto fail;
        }
    } else if (provider == 2) {
        typedef const char *(*str_t)(void);
        str_t str = (str_t)symbol(b->library, "bli_info_get_int_type_size_str");
        void *query = symbol(b->library, "bli_info_get_blas_int_type_size");
        if (!str || !query) {
            *status = 2;
            goto fail;
        }
        const char *size = str();
        b->blis_bits = size ? atoi(size) : 0;
        int actual = b->blis_bits == 32   ? ((int32_t (*)(void))query)()
                     : b->blis_bits == 64 ? (int)((int64_t (*)(void))query)()
                                          : 0;
        if (actual != bits) {
            *status = 2;
            goto fail;
        }
    } else if (provider == 3) {
        /* oneMKL's SDL layer is process-global. Reserve one ABI for all adapter
         * handles. Applications sharing MKL must configure it before all other use
         * and must not change its interface layer while these handles exist. */
        int (*set_layer)(int) = (int (*)(int))symbol(b->library, "MKL_Set_Interface_Layer");
        if (!set_layer)
            set_layer = (int (*)(int))symbol(b->library, "mkl_set_interface_layer");
        if (!set_layer) {
            *status = 2;
            goto fail;
        }
        while (atomic_flag_test_and_set(&mkl_lock)) {
        }
        int valid = mkl_bits == 0 || (mkl_bits == bits && mkl_pinned == b->library);
        if (valid && mkl_bits == 0) {
            int result = set_layer(bits == 64 ? 1 : 0);
            valid = result >= 0 && (result & 1) == (bits == 64 ? 1 : 0);
            if (valid) {
                mkl_pinned = loadlib(path && *path ? path : default_path);
                valid = mkl_pinned != NULL;
                if (valid)
                    mkl_bits = bits;
            }
        }
        atomic_flag_clear(&mkl_lock);
        if (!valid) {
            *status = 2;
            goto fail;
        }
    } else if (bits != 32 || (path && *path)) {
        *status = 2;
        goto fail;
    }
    const char *names[] = {"cblas_daxpy", "cblas_ddot",  "cblas_dnrm2",
                           "cblas_dgemv", "cblas_dgemm", "cblas_zgemm"};
    for (unsigned i = 0; i < sizeof(names) / sizeof(names[0]); i++)
        if (!bsym(b, names[i])) {
            *status = 4;
            goto fail;
        }
    *status = 0;
    return b;
fail:
    unload(b->library);
    free(b);
    return NULL;
}
void hmath_backend_close(hmath_backend *b) {
    if (b) {
        unload(b->library);
        free(b);
    }
}
int hmath_backend_threads(hmath_backend *b, int threads) {
    if (!b || threads < 1)
        return 2;
    if (b->provider == 1) {
        void (*f)(int) = (void (*)(int))bsym(b, "openblas_set_num_threads");
        if (!f)
            return 4;
        f(threads);
        return 0;
    }
    if (b->provider == 2) {
        void *p = symbol(b->library, "bli_thread_set_num_threads");
        if (!p)
            return 4;
        if (b->blis_bits == 64)
            ((void (*)(int64_t))p)(threads);
        else
            ((void (*)(int32_t))p)(threads);
        return 0;
    }
    if (b->provider == 3) {
        void (*f)(int) = (void (*)(int))symbol(b->library, "MKL_Set_Num_Threads");
        if (!f)
            return 4;
        f(threads);
        return 0;
    }
    return 4; /* Accelerate does not offer a supported runtime setter. */
}
int hmath_backend_vector(hmath_backend *b, int op, int64_t n, double alpha, const double *x,
                         double *y, double *out) {
    if (!b || n < 0 || (b->bits == 32 && n > INT32_MAX))
        return 2;
    if (b->bits == 32) {
        if (op == 0)
            ((void (*)(int32_t, double, const double *, int32_t, double *, int32_t))bsym(
                b, "cblas_daxpy"))((int32_t)n, alpha, x, 1, y, 1);
        else if (op == 1)
            *out = ((double (*)(int32_t, const double *, int32_t, const double *, int32_t))bsym(
                b, "cblas_ddot"))((int32_t)n, x, 1, y, 1);
        else if (op == 2)
            *out = ((double (*)(int32_t, const double *, int32_t))bsym(b, "cblas_dnrm2"))(
                (int32_t)n, x, 1);
        else
            return 2;
    }
    if (b->bits == 64) {
        if (op == 0)
            ((void (*)(int64_t, double, const double *, int64_t, double *, int64_t))bsym(
                b, "cblas_daxpy"))((int64_t)n, alpha, x, 1, y, 1);
        else if (op == 1)
            *out = ((double (*)(int64_t, const double *, int64_t, const double *, int64_t))bsym(
                b, "cblas_ddot"))((int64_t)n, x, 1, y, 1);
        else if (op == 2)
            *out = ((double (*)(int64_t, const double *, int64_t))bsym(b, "cblas_dnrm2"))(
                (int64_t)n, x, 1);
        else
            return 2;
    }
    return 0;
}
int hmath_backend_gemv(hmath_backend *b, int tr, int64_t m, int64_t n, double alpha,
                       const double *a, const double *x, double beta, double *y) {
    if (!b || m < 0 || n < 0 || (b->bits == 32 && (m > INT32_MAX || n > INT32_MAX)))
        return 2;
    if (b->bits == 32)
        ((void (*)(int, int, int32_t, int32_t, double, const double *, int32_t, const double *,
                   int32_t, double, double *, int32_t))bsym(b, "cblas_dgemv"))(
            101, tr, (int32_t)m, (int32_t)n, alpha, a, (int32_t)n, x, 1, beta, y, 1);
    if (b->bits == 64)
        ((void (*)(int, int, int64_t, int64_t, double, const double *, int64_t, const double *,
                   int64_t, double, double *, int64_t))bsym(b, "cblas_dgemv"))(
            101, tr, (int64_t)m, (int64_t)n, alpha, a, (int64_t)n, x, 1, beta, y, 1);
    return 0;
}
int hmath_backend_gemm(hmath_backend *b, int z, int ta, int tb, int64_t m, int64_t n, int64_t k,
                       const void *alpha, const void *a, int64_t lda, const void *bb, int64_t ldb,
                       const void *beta, void *c) {
    if (!b || m < 0 || n < 0 || k < 0 ||
        (b->bits == 32 &&
         (m > INT32_MAX || n > INT32_MAX || k > INT32_MAX || lda > INT32_MAX || ldb > INT32_MAX)))
        return 2;
    if (b->bits == 32) {
        if (z)
            ((void (*)(int, int, int, int32_t, int32_t, int32_t, const void *, const void *,
                       int32_t, const void *, int32_t, const void *, void *,
                       int32_t))bsym(b, "cblas_zgemm"))(101, ta, tb, (int32_t)m, (int32_t)n,
                                                        (int32_t)k, alpha, a, (int32_t)lda, bb,
                                                        (int32_t)ldb, beta, c, (int32_t)n);
        else
            ((void (*)(int, int, int, int32_t, int32_t, int32_t, double, const double *, int32_t,
                       const double *, int32_t, double, double *, int32_t))bsym(b, "cblas_dgemm"))(
                101, ta, tb, (int32_t)m, (int32_t)n, (int32_t)k, *(const double *)alpha, a,
                (int32_t)lda, bb, (int32_t)ldb, *(const double *)beta, c, (int32_t)n);
    }
    if (b->bits == 64) {
        if (z)
            ((void (*)(int, int, int, int64_t, int64_t, int64_t, const void *, const void *,
                       int64_t, const void *, int64_t, const void *, void *,
                       int64_t))bsym(b, "cblas_zgemm"))(101, ta, tb, (int64_t)m, (int64_t)n,
                                                        (int64_t)k, alpha, a, (int64_t)lda, bb,
                                                        (int64_t)ldb, beta, c, (int64_t)n);
        else
            ((void (*)(int, int, int, int64_t, int64_t, int64_t, double, const double *, int64_t,
                       const double *, int64_t, double, double *, int64_t))bsym(b, "cblas_dgemm"))(
                101, ta, tb, (int64_t)m, (int64_t)n, (int64_t)k, *(const double *)alpha, a,
                (int64_t)lda, bb, (int64_t)ldb, *(const double *)beta, c, (int64_t)n);
    }
    return 0;
}
/* LAPACKE retains one process-lifetime library reference: the old pure API has
 * no explicit context lifetime. Initialization uses acquire/release ordering;
 * all subsequent calls use independent Haskell-owned buffers. */
static atomic_flag lapack_lock = ATOMIC_FLAG_INIT;
static atomic_int lapack_initialized = 0;
static libhandle lapack_library = NULL;
static int lapack_bits = 32;
static void init_lapack(void) {
    if (atomic_load(&lapack_initialized))
        return;
    while (atomic_flag_test_and_set(&lapack_lock)) {
    }
    if (!atomic_load(&lapack_initialized)) {
#ifndef HMATH_DISABLE_NATIVE
        const char *mode = getenv("HMATH_BACKEND"), *path = getenv("HMATH_LAPACKE_LIBRARY"),
                   *bits = getenv("HMATH_LAPACKE_INTEGER_BITS");
        int valid = !mode || strcmp(mode, "auto") == 0 || strcmp(mode, "pure") == 0;
        if (bits) {
            if (strcmp(bits, "32") == 0)
                lapack_bits = 32;
            else if (strcmp(bits, "64") == 0)
                lapack_bits = 64;
            else
                valid = 0;
        }
        if (path && *path && !bits)
            valid = 0;
        if (valid && !(mode && strcmp(mode, "pure") == 0)) {
            if (path && *path)
                lapack_library = loadlib(path);
            else {
#ifdef _WIN32
                lapack_library = loadlib(lapack_bits == 64 ? "liblapacke64.dll" : "liblapacke.dll");
#elif defined(__APPLE__)
                lapack_library =
                    loadlib(lapack_bits == 64 ? "liblapacke64.dylib" : "liblapacke.dylib");
#else
                lapack_library =
                    loadlib(lapack_bits == 64 ? "liblapacke64.so.3" : "liblapacke.so.3");
#endif
            }
        }
#endif
        if (lapack_library) {
            const char *required[] = {"LAPACKE_zgesdd", "LAPACKE_zgeev",  "LAPACKE_dsyev",
                                      "LAPACKE_dgesdd", "LAPACKE_dgeev",  "LAPACKE_dggev",
                                      "LAPACKE_dgees",  "LAPACKE_dgges",  "LAPACKE_dgehrd",
                                      "LAPACKE_dorghr", "LAPACKE_dgebal", "LAPACKE_dgesv"};
            for (unsigned i = 0; i < sizeof(required) / sizeof(required[0]); i++)
                if (!symbol(lapack_library, required[i])) {
                    unload(lapack_library);
                    lapack_library = NULL;
                    break;
                }
        }
        atomic_store(&lapack_initialized, 1);
    }
    atomic_flag_clear(&lapack_lock);
}
int hmath_lapack_available(void) {
    init_lapack();
    return lapack_library != NULL;
}
static void *lapack_symbol(const char *name) {
    init_lapack();
    return lapack_library ? symbol(lapack_library, name) : NULL;
}
/* Status -10000 is adapter-unavailable; ordinary negative values retain the
 * LAPACKE argument index, positive values retain the convergence/pivot code. */
int32_t hmath_lapacke_zgesdd(int32_t a0, char a1, int32_t a2, int32_t a3, double *a4, int32_t a5,
                             double *a6, double *a7, int32_t a8, double *a9, int32_t a10) {
    void *p = lapack_symbol("LAPACKE_zgesdd");
    if (!p)
        return -10000;
    if (lapack_bits == 32) {
        int32_t result = ((int32_t (*)(int32_t, char, int32_t, int32_t, double *, int32_t, double *,
                                       double *, int32_t, double *, int32_t))p)(
            a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    if (lapack_bits == 64) {
        int64_t result = ((int64_t (*)(int32_t, char, int64_t, int64_t, double *, int64_t, double *,
                                       double *, int64_t, double *, int64_t))p)(
            a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    return -10000;
}
int32_t hmath_lapacke_zgeev(int32_t a0, char a1, char a2, int32_t a3, double *a4, int32_t a5,
                            double *a6, double *a7, int32_t a8, double *a9, int32_t a10) {
    void *p = lapack_symbol("LAPACKE_zgeev");
    if (!p)
        return -10000;
    if (lapack_bits == 32) {
        int32_t result = ((int32_t (*)(int32_t, char, char, int32_t, double *, int32_t, double *,
                                       double *, int32_t, double *, int32_t))p)(
            a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    if (lapack_bits == 64) {
        int64_t result = ((int64_t (*)(int32_t, char, char, int64_t, double *, int64_t, double *,
                                       double *, int64_t, double *, int64_t))p)(
            a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    return -10000;
}
int32_t hmath_lapacke_dsyev(int32_t a0, char a1, char a2, int32_t a3, double *a4, int32_t a5,
                            double *a6) {
    void *p = lapack_symbol("LAPACKE_dsyev");
    if (!p)
        return -10000;
    if (lapack_bits == 32) {
        int32_t result = ((int32_t (*)(int32_t, char, char, int32_t, double *, int32_t,
                                       double *))p)(a0, a1, a2, a3, a4, a5, a6);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    if (lapack_bits == 64) {
        int64_t result = ((int64_t (*)(int32_t, char, char, int64_t, double *, int64_t,
                                       double *))p)(a0, a1, a2, a3, a4, a5, a6);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    return -10000;
}
int32_t hmath_lapacke_dgesdd(int32_t a0, char a1, int32_t a2, int32_t a3, double *a4, int32_t a5,
                             double *a6, double *a7, int32_t a8, double *a9, int32_t a10) {
    void *p = lapack_symbol("LAPACKE_dgesdd");
    if (!p)
        return -10000;
    if (lapack_bits == 32) {
        int32_t result = ((int32_t (*)(int32_t, char, int32_t, int32_t, double *, int32_t, double *,
                                       double *, int32_t, double *, int32_t))p)(
            a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    if (lapack_bits == 64) {
        int64_t result = ((int64_t (*)(int32_t, char, int64_t, int64_t, double *, int64_t, double *,
                                       double *, int64_t, double *, int64_t))p)(
            a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    return -10000;
}
int32_t hmath_lapacke_dgeev(int32_t a0, char a1, char a2, int32_t a3, double *a4, int32_t a5,
                            double *a6, double *a7, double *a8, int32_t a9, double *a10,
                            int32_t a11) {
    void *p = lapack_symbol("LAPACKE_dgeev");
    if (!p)
        return -10000;
    if (lapack_bits == 32) {
        int32_t result = ((int32_t (*)(int32_t, char, char, int32_t, double *, int32_t, double *,
                                       double *, double *, int32_t, double *, int32_t))p)(
            a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    if (lapack_bits == 64) {
        int64_t result = ((int64_t (*)(int32_t, char, char, int64_t, double *, int64_t, double *,
                                       double *, double *, int64_t, double *, int64_t))p)(
            a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    return -10000;
}
int32_t hmath_lapacke_dggev(int32_t a0, char a1, char a2, int32_t a3, double *a4, int32_t a5,
                            double *a6, int32_t a7, double *a8, double *a9, double *a10,
                            double *a11, int32_t a12, double *a13, int32_t a14) {
    void *p = lapack_symbol("LAPACKE_dggev");
    if (!p)
        return -10000;
    if (lapack_bits == 32) {
        int32_t result =
            ((int32_t (*)(int32_t, char, char, int32_t, double *, int32_t, double *, int32_t,
                          double *, double *, double *, double *, int32_t, double *, int32_t))p)(
                a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    if (lapack_bits == 64) {
        int64_t result =
            ((int64_t (*)(int32_t, char, char, int64_t, double *, int64_t, double *, int64_t,
                          double *, double *, double *, double *, int64_t, double *, int64_t))p)(
                a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    return -10000;
}
int32_t hmath_lapacke_dgees(int32_t a0, char a1, char a2, void *a3, int32_t a4, double *a5,
                            int32_t a6, int32_t *a7, double *a8, double *a9, double *a10,
                            int32_t a11) {
    void *p = lapack_symbol("LAPACKE_dgees");
    if (!p)
        return -10000;
    if (lapack_bits == 32) {
        int32_t result = ((int32_t (*)(int32_t, char, char, void *, int32_t, double *, int32_t,
                                       int32_t *, double *, double *, double *, int32_t))p)(
            a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    if (lapack_bits == 64) {
        int64_t v7 = 0;
        int64_t result = ((int64_t (*)(int32_t, char, char, void *, int64_t, double *, int64_t,
                                       int64_t *, double *, double *, double *, int64_t))p)(
            a0, a1, a2, a3, a4, a5, a6, &v7, a8, a9, a10, a11);
        *a7 = (int32_t)v7;
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    return -10000;
}
int32_t hmath_lapacke_dgges(int32_t a0, char a1, char a2, char a3, void *a4, int32_t a5, double *a6,
                            int32_t a7, double *a8, int32_t a9, int32_t *a10, double *a11,
                            double *a12, double *a13, double *a14, int32_t a15, double *a16,
                            int32_t a17) {
    void *p = lapack_symbol("LAPACKE_dgges");
    if (!p)
        return -10000;
    if (lapack_bits == 32) {
        int32_t result = ((int32_t (*)(int32_t, char, char, char, void *, int32_t, double *,
                                       int32_t, double *, int32_t, int32_t *, double *, double *,
                                       double *, double *, int32_t, double *, int32_t))p)(
            a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    if (lapack_bits == 64) {
        int64_t v10 = 0;
        int64_t result = ((int64_t (*)(int32_t, char, char, char, void *, int64_t, double *,
                                       int64_t, double *, int64_t, int64_t *, double *, double *,
                                       double *, double *, int64_t, double *, int64_t))p)(
            a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, &v10, a11, a12, a13, a14, a15, a16, a17);
        *a10 = (int32_t)v10;
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    return -10000;
}
int32_t hmath_lapacke_dgehrd(int32_t a0, int32_t a1, int32_t a2, int32_t a3, double *a4, int32_t a5,
                             double *a6) {
    void *p = lapack_symbol("LAPACKE_dgehrd");
    if (!p)
        return -10000;
    if (lapack_bits == 32) {
        int32_t result = ((int32_t (*)(int32_t, int32_t, int32_t, int32_t, double *, int32_t,
                                       double *))p)(a0, a1, a2, a3, a4, a5, a6);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    if (lapack_bits == 64) {
        int64_t result = ((int64_t (*)(int32_t, int64_t, int64_t, int64_t, double *, int64_t,
                                       double *))p)(a0, a1, a2, a3, a4, a5, a6);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    return -10000;
}
int32_t hmath_lapacke_dorghr(int32_t a0, int32_t a1, int32_t a2, int32_t a3, double *a4, int32_t a5,
                             double *a6) {
    void *p = lapack_symbol("LAPACKE_dorghr");
    if (!p)
        return -10000;
    if (lapack_bits == 32) {
        int32_t result = ((int32_t (*)(int32_t, int32_t, int32_t, int32_t, double *, int32_t,
                                       double *))p)(a0, a1, a2, a3, a4, a5, a6);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    if (lapack_bits == 64) {
        int64_t result = ((int64_t (*)(int32_t, int64_t, int64_t, int64_t, double *, int64_t,
                                       double *))p)(a0, a1, a2, a3, a4, a5, a6);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    return -10000;
}
int32_t hmath_lapacke_dgebal(int32_t a0, char a1, int32_t a2, double *a3, int32_t a4, int32_t *a5,
                             int32_t *a6, double *a7) {
    void *p = lapack_symbol("LAPACKE_dgebal");
    if (!p)
        return -10000;
    if (lapack_bits == 32) {
        int32_t result = ((int32_t (*)(int32_t, char, int32_t, double *, int32_t, int32_t *,
                                       int32_t *, double *))p)(a0, a1, a2, a3, a4, a5, a6, a7);
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    if (lapack_bits == 64) {
        int64_t v5 = 0;
        int64_t v6 = 0;
        int64_t result = ((int64_t (*)(int32_t, char, int64_t, double *, int64_t, int64_t *,
                                       int64_t *, double *))p)(a0, a1, a2, a3, a4, &v5, &v6, a7);
        *a5 = (int32_t)v5;
        *a6 = (int32_t)v6;
        return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
    }
    return -10000;
}
/* Row-major single-right-hand-side GESV; pivot storage follows the selected
 * LAPACKE integer ABI, while the public adapter dimensions stay int32_t. */
int32_t hmath_lapack_solve(int32_t n, double *a, double *b) {
    void *p = lapack_symbol("LAPACKE_dgesv");
    if (!p)
        return -10000;
    if (n < 0)
        return -1;
    if (n == 0)
        return 0;
    void *pivots = calloc((size_t)n, sizeof(int64_t));
    if (!pivots)
        return -10002;
    int64_t result;
    if (lapack_bits == 64)
        result = ((int64_t (*)(int, int64_t, int64_t, double *, int64_t, int64_t *, double *,
                               int64_t))p)(101, n, 1, a, n, pivots, b, 1);
    else
        result = ((int32_t (*)(int, int32_t, int32_t, double *, int32_t, int32_t *, double *,
                               int32_t))p)(101, n, 1, a, n, pivots, b, 1);
    free(pivots);
    return result > INT32_MAX || result < INT32_MIN ? -10001 : (int32_t)result;
}
