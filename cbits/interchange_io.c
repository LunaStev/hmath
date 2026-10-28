/* SPDX-License-Identifier: MPL-2.0 */
/* Bounded compression and read-only mappings. No Haskell heap pointers escape
 * these calls. zlib is optional; mmap itself has no optional dependency. */
#ifndef _WIN32
#define _FILE_OFFSET_BITS 64
#endif
#include <limits.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#ifdef HMATH_HAVE_ZLIB
#include <zlib.h>
#endif

int hmath_interchange_has_zlib(void) {
#ifdef HMATH_HAVE_ZLIB
    return 1;
#else
    return 0;
#endif
}
/* mode 0=raw DEFLATE (ZIP), 1=zlib, 2=gzip. Capacity is a caller-validated
 * hard limit. The decoder requires exactly one complete stream with no tail. */
int hmath_interchange_compress(int decode, int mode, const unsigned char *input, size_t input_len,
                               unsigned char *output, size_t capacity, size_t *written) {
#ifdef HMATH_HAVE_ZLIB
    z_stream stream;
    int status, window;
    if (!written || input_len > UINT_MAX || capacity > UINT_MAX || mode < 0 || mode > 2)
        return -1;
    memset(&stream, 0, sizeof stream);
    stream.next_in = (Bytef *)input;
    stream.avail_in = (uInt)input_len;
    stream.next_out = output;
    stream.avail_out = (uInt)capacity;
    window = mode == 0 ? -15 : mode == 1 ? 15 : 31;
    status = decode ? inflateInit2(&stream, window)
                    : deflateInit2(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, window, 8,
                                   Z_DEFAULT_STRATEGY);
    if (status != Z_OK)
        return -2;
    status = decode ? inflate(&stream, Z_FINISH) : deflate(&stream, Z_FINISH);
    *written = (size_t)stream.total_out;
    int good = status == Z_STREAM_END && stream.avail_in == 0;
    int full = stream.avail_out == 0 && status != Z_STREAM_END;
    if (decode)
        inflateEnd(&stream);
    else
        deflateEnd(&stream);
    return good ? 0 : full ? -3 : -4;
#else
    (void)decode;
    (void)mode;
    (void)input;
    (void)input_len;
    (void)output;
    (void)capacity;
    (void)written;
    return -5;
#endif
}

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
struct hmath_mapping {
    void *data;
    size_t size;
    HANDLE file;
    HANDLE mapping;
};
void *hmath_interchange_map(const char *path, uint64_t limit, int *error) {
    struct hmath_mapping *m = calloc(1, sizeof *m);
    LARGE_INTEGER size;
    if (!m) {
        *error = 1;
        return NULL;
    }
    /* The Haskell API currently passes UTF-8. Use the wide Windows API. */
    int count = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, path, -1, NULL, 0);
    wchar_t *wide = count > 0 ? malloc((size_t)count * sizeof(wchar_t)) : NULL;
    if (!wide) {
        free(m);
        *error = 1;
        return NULL;
    }
    MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, path, -1, wide, count);
    m->file = CreateFileW(wide, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
                          FILE_ATTRIBUTE_NORMAL, NULL);
    free(wide);
    if (m->file == INVALID_HANDLE_VALUE) {
        free(m);
        *error = 2;
        return NULL;
    }
    if (!GetFileSizeEx(m->file, &size) || size.QuadPart < 0 || (uint64_t)size.QuadPart > limit ||
        (uint64_t)size.QuadPart > SIZE_MAX) {
        CloseHandle(m->file);
        free(m);
        *error = 3;
        return NULL;
    }
    m->size = (size_t)size.QuadPart;
    if (m->size) {
        m->mapping = CreateFileMappingW(m->file, NULL, PAGE_READONLY, 0, 0, NULL);
        if (m->mapping)
            m->data = MapViewOfFile(m->mapping, FILE_MAP_READ, 0, 0, 0);
        if (!m->data) {
            if (m->mapping)
                CloseHandle(m->mapping);
            CloseHandle(m->file);
            free(m);
            *error = 4;
            return NULL;
        }
    }
    *error = 0;
    return m;
}
void hmath_interchange_unmap(void *value) {
    struct hmath_mapping *m = value;
    if (!m)
        return;
    if (m->data)
        UnmapViewOfFile(m->data);
    if (m->mapping)
        CloseHandle(m->mapping);
    CloseHandle(m->file);
    free(m);
}
#else
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
struct hmath_mapping {
    void *data;
    size_t size;
};
void *hmath_interchange_map(const char *path, uint64_t limit, int *error) {
    struct stat st;
    int fd = open(path, O_RDONLY);
    if (fd < 0) {
        *error = 2;
        return NULL;
    }
    if (fstat(fd, &st) != 0 || !S_ISREG(st.st_mode) || st.st_size < 0 ||
        (uint64_t)st.st_size > limit || (uint64_t)st.st_size > SIZE_MAX) {
        close(fd);
        *error = 3;
        return NULL;
    }
    struct hmath_mapping *m = calloc(1, sizeof *m);
    if (!m) {
        close(fd);
        *error = 1;
        return NULL;
    }
    m->size = (size_t)st.st_size;
    if (m->size) {
        m->data = mmap(NULL, m->size, PROT_READ, MAP_PRIVATE, fd, 0);
        if (m->data == MAP_FAILED) {
            close(fd);
            free(m);
            *error = 4;
            return NULL;
        }
    }
    close(fd);
    *error = 0;
    return m;
}
void hmath_interchange_unmap(void *value) {
    struct hmath_mapping *m = value;
    if (!m)
        return;
    if (m->size)
        munmap(m->data, m->size);
    free(m);
}
#endif
uint64_t hmath_interchange_map_size(void *value) {
    return (uint64_t)((struct hmath_mapping *)value)->size;
}
/* Only bounded copies are exposed to Haskell, so a pointer/view cannot outlive
 * the bracket. Caller must ensure the file is not truncated while mapped. */
int hmath_interchange_map_read(void *value, uint64_t offset, size_t count, void *out) {
    struct hmath_mapping *m = value;
    if (offset > m->size || count > m->size - (size_t)offset)
        return -1;
    if (count)
        memcpy(out, (unsigned char *)m->data + (size_t)offset, count);
    return 0;
}
