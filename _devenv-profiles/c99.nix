{
  pkgs,
  lib,
  config,
  ...
}: {
  profiles.c99 = {
    module = {
      enterShell = ''
        export DEVENV_ACTIVE_PROFILES="''${DEVENV_ACTIVE_PROFILES} 🇨 c99"
      '';

      # 1. Core C support
      languages.c = {
        enable = true;
        debugger = pkgs.llvmPackages_18.lldb;
      };

      # 2. Faster rebuilds
      ccache.enable = true;

      # 3.
      packages = with pkgs; [
        # Compiler & Linker
        clang_18
        mold

        # Build System
        meson
        ninja
        pkg-config

        # Tools (LSP, Lint, Format)
        llvmPackages_18.clang-tools
        llvmPackages_18.lldb

        # Testing (Unity instead of Criterion)
        unity
      ];

      # 4. Linker Configuration
      env = {
        NIX_CFLAGS_COMPILE = "-fuse-ld=mold";
      };

      # 5. Hooks
      treefmt.config = {
        programs = {
          clang-format = {
            enable = true;
            package = pkgs.llvmPackages_18.clang-tools;
          };
          clang-tidy = {
            enable = true;
            package = pkgs.llvmPackages_18.clang-tools;
            compileCommandsPath = "${config.env.DEVENV_ROOT}/builddir";
          };
        };
      };

      # 6. Scaffolding Scripts
      scripts = {
        c99-init = {
          description = "Scaffold C99 (Arena+Meson+Unity) Project";
          exec = ''
            set -e

            # --- 1. Tooling Configs ---
            if [ ! -f "$DEVENV_ROOT/.clang-tidy" ]; then
              echo "Creating .clang-tidy..."
              cat > "$DEVENV_ROOT/.clang-tidy" << 'EOF'
            Checks: '-*,clang-diagnostic-*,clang-analyzer-*,readability-*,bugprone-*,performance-*'
            CheckOptions:
              - key: readability-identifier-naming.VariableCase
                value: lower_case
            EOF
            fi

            if [ ! -f "$DEVENV_ROOT/.clang-format" ]; then
              echo "Creating .clang-format..."
              cat > "$DEVENV_ROOT/.clang-format" << 'EOF'
            BasedOnStyle: LLVM
            IndentWidth: 4
            ColumnLimit: 100
            Language: Cpp
            AllowShortFunctionsOnASingleLine: Empty
            EOF
            fi

            # --- 2. Build System (Meson) ---
            if [ ! -f "$DEVENV_ROOT/meson.build" ]; then
              echo "Creating strict meson.build..."
              cat > "$DEVENV_ROOT/meson.build" << 'EOF'
            project('c99-constitutional', 'c',
              version: '0.1.0',
              default_options: [
                'c_std=c99',
                'warning_level=3',              # -Wall -Wextra
                'werror=true',                  # Warnings are Errors
                'b_sanitize=address,undefined', # Dev defaults
              ]
            )

            # Enable GNU extensions for __alignof__ and __attribute__
            add_project_arguments('-D_GNU_SOURCE', language: 'c')

            # Global strictness flags
            add_project_arguments(
              '-Wshadow', '-Wstrict-prototypes', '-Wmissing-prototypes',
              '-Wcast-qual', '-Wconversion', '-Wwrite-strings',
              '-Werror=vla', # VLA Ban
              language: 'c'
            )

            # Dependencies
            unity_dep = dependency('unity', fallback: ['unity', 'unity_dep'], required: false)
            # If system unity is missing (common in some setups), we might need a fallback or subproject.
            # For Nix, pkgs.unity usually provides the headers/libs.

            # Sources
            src_files = files('src/main.c')

            # Main Executable
            executable('main', src_files, install: true)

            # Test Suite
            if unity_dep.found()
              test_exe = executable('unit_tests',
                ['tests/main_test.c', 'src/main.c'], # Link main src for testing logic (exclude main.c via ifdef in real app)
                dependencies: [unity_dep],
                c_args: '-DTEST_MODE'
              )
              test('unit_tests', test_exe)
            endif
            EOF
            fi

            # --- 3. Source Directory & Files ---
            mkdir -p "$DEVENV_ROOT/src"

            # src/arena.h
            if [ ! -f "$DEVENV_ROOT/src/arena.h" ]; then
              echo "Creating src/arena.h (The Law)..."
              cat > "$DEVENV_ROOT/src/arena.h" << 'EOF'
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
            EOF
            fi

            # src/str.h
            if [ ! -f "$DEVENV_ROOT/src/str.h" ]; then
              echo "Creating src/str.h (String Views)..."
              cat > "$DEVENV_ROOT/src/str.h" << 'EOF'
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
            EOF
            fi

            # src/main.c
            if [ ! -f "$DEVENV_ROOT/src/main.c" ]; then
              echo "Creating src/main.c..."
              cat > "$DEVENV_ROOT/src/main.c" << 'EOF'
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
            EOF
            fi

            # --- 4. Tests Directory ---
            mkdir -p "$DEVENV_ROOT/tests"

            if [ ! -f "$DEVENV_ROOT/tests/main_test.c" ]; then
              echo "Creating tests/main_test.c (Unity)..."
              cat > "$DEVENV_ROOT/tests/main_test.c" << 'EOF'
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
            EOF
            fi

            echo "Project initialized. Run 'just setup' or 'meson setup builddir' to begin."
          '';
        };

        c99-clean = {
          description = "Clean project";
          exec = ''
            rm -rf builddir src tests .clang-tidy .clang-format meson.build
          '';
        };
      };

      tasks."c99:init".exec = "c99-init";
      tasks."c99:init".before = ["devenv:enterShell"];
    };
  };
}
