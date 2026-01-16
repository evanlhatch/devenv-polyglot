#pragma once
#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>

typedef struct {
    uint8_t *base;
    size_t size;
    size_t offset;
} Arena;

#define ARENA_INIT(mem, bytes) (Arena){ .base = (uint8_t*)(mem), .size = (bytes), .offset = 0 }

static inline void* _arena_alloc(Arena *a, size_t size, size_t align) {
    uintptr_t current = (uintptr_t)a->base + a->offset;
    uintptr_t aligned = (current + (align - 1)) & ~(align - 1);
    uintptr_t next_offset = aligned - (uintptr_t)a->base + size;

    if (next_offset > a->size) {
        fprintf(stderr, "Fatal: Arena OOM (Size: %zu, Need: %zu)\n", a->size, next_offset);
        abort();
    }

    a->offset = next_offset;
    return (void*)aligned;
}

static inline void arena_reset(Arena *a) { a->offset = 0; }

#define ARENA_NEW(a, T)       ((T*)_arena_alloc((a), sizeof(T), __alignof__(T)))
#define ARENA_ARRAY(a, T, n)  ((T*)_arena_alloc((a), sizeof(T) * (n), __alignof__(T)))
