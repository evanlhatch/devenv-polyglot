#include <unity.h>
#include "../src/arena.h"

static uint8_t test_heap[4096];
static Arena test_arena;

void setUp(void) {
    test_arena = ARENA_INIT(test_heap, sizeof(test_heap));
}

void tearDown(void) {}

void test_ArenaAllocation(void) {
    int *nums = ARENA_ARRAY(&test_arena, int, 10);
    nums[0] = 42;
    TEST_ASSERT_EQUAL(42, nums[0]);
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_ArenaAllocation);
    return UNITY_END();
}
