#include <stdio.h>
#include "arena.h"
#include "str.h"

#ifndef TEST_MODE
int main(void) {
    // Static storage for the main loop arena
    static uint8_t memory[1024 * 1024];
    Arena perm = ARENA_INIT(memory, sizeof(memory));

    Str msg = str_from_cstr(&perm, "Hello from Constitutional C99!");
    printf(SV_FMT "\n", SV_ARG(msg));

    return 0;
}
#endif
