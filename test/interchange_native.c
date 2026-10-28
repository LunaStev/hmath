/* SPDX-License-Identifier: MPL-2.0 */
/* Standalone sanitizer target for the compression/mapping boundary. No GHC
 * runtime is involved, so native sanitizer diagnostics are directly actionable.
 * Usage: cc -fsanitize=address,undefined -DHMATH_HAVE_ZLIB \
 * test/interchange_native.c cbits/interchange_io.c -lz -o interchange-native */
#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

int hmath_interchange_has_zlib(void);
int hmath_interchange_compress(int, int, const unsigned char *, size_t, unsigned char *, size_t,
                               size_t *);
void *hmath_interchange_map(const char *, uint64_t, int *);
void hmath_interchange_unmap(void *);
uint64_t hmath_interchange_map_size(void *);
int hmath_interchange_map_read(void *, uint64_t, size_t, void *);
int main(int argc, char **argv) {
    assert(argc == 2);
    const unsigned char payload[] = "bounded numerical interchange";
    unsigned char encoded[256], decoded[256];
    size_t packed = 0, unpacked = 0;
    if (hmath_interchange_has_zlib()) {
        for (int mode = 0; mode < 3; mode++) {
            assert(hmath_interchange_compress(0, mode, payload, sizeof payload, encoded,
                                              sizeof encoded, &packed) == 0);
            assert(hmath_interchange_compress(1, mode, encoded, packed, decoded, sizeof decoded,
                                              &unpacked) == 0);
            assert(unpacked == sizeof payload && memcmp(decoded, payload, unpacked) == 0);
            for (size_t n = 0; n < packed; n++) {
                assert(hmath_interchange_compress(1, mode, encoded, n, decoded, sizeof decoded,
                                                  &unpacked) != 0);
            }
            assert(hmath_interchange_compress(1, mode, encoded, packed, decoded, sizeof payload - 1,
                                              &unpacked) != 0);
        }
        uint32_t state = 1;
        for (size_t trial = 0; trial < 2048; trial++) {
            for (size_t i = 0; i < sizeof encoded; i++) {
                state = 1664525 * state + 1013904223;
                encoded[i] = (unsigned char)(state >> 24);
            }
            /* Random input can be a valid empty stream; either result is fine,
             * while sanitizer guards all reads/writes and cleanup paths. */
            (void)hmath_interchange_compress(1, (int)(trial % 3), encoded, trial % 256, decoded,
                                             trial % 256, &unpacked);
        }
    } else {
        assert(hmath_interchange_compress(0, 0, payload, sizeof payload, encoded, sizeof encoded,
                                          &packed) == -5);
    }
    FILE *file = fopen(argv[1], "wb");
    assert(file);
    assert(fwrite(payload, 1, sizeof payload, file) == sizeof payload);
    assert(fclose(file) == 0);
    int error = -1;
    assert(hmath_interchange_map(argv[1], 1, &error) == NULL && error != 0);
    void *mapping = hmath_interchange_map(argv[1], sizeof payload, &error);
    assert(mapping && error == 0 && hmath_interchange_map_size(mapping) == sizeof payload);
    memset(decoded, 0xa5, sizeof decoded);
    assert(hmath_interchange_map_read(mapping, 0, sizeof payload, decoded) == 0);
    assert(memcmp(decoded, payload, sizeof payload) == 0 && decoded[sizeof payload] == 0xa5);
    assert(hmath_interchange_map_read(mapping, UINT64_MAX, 1, decoded) != 0);
    assert(hmath_interchange_map_read(mapping, 1, SIZE_MAX, decoded) != 0);
    assert(hmath_interchange_map_read(mapping, sizeof payload, 0, NULL) == 0);
    hmath_interchange_unmap(mapping);
    hmath_interchange_unmap(NULL);
    assert(remove(argv[1]) == 0);
    puts("interchange native bounds, fuzz and lifetime checks passed");
    return 0;
}
