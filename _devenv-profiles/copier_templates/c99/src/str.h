#pragma once
#include "arena.h"
#include <string.h>

typedef struct {
    const char *ptr;
    size_t len;
} Str;

#define STR(s) ((Str){ .ptr = (s), .len = sizeof(s) - 1 })
#define SV_FMT "%.*s"
#define SV_ARG(s) (int)(s).len, (s).ptr

static inline Str str_from_cstr(Arena *a, const char *src) {
    size_t len = strlen(src);
    char *buf = _arena_alloc(a, len + 1, 1);
    memcpy(buf, src, len);
    buf[len] = '\0';
    return (Str){ .ptr = buf, .len = len };
}
