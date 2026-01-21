{
  pkgs,
  lib,
  config,
  ...
}: {
  profiles.zig = {
    module = {
      enterShell = ''
        export DEVENV_ACTIVE_PROFILES="''${DEVENV_ACTIVE_PROFILES} ⚡ zig"
      '';

      # 1. Enable devenv's core Zig language support.
      languages.zig = {
        enable = true;
      };

      # 2. Define the package set for the Zig stack.
      packages = with pkgs; [
        # ZLS (Zig Language Server) for IDE support
        zls
      ];

      # 3. Configure environment variables for Zig development.
      env = {
        # Zig cache directory
        ZIG_GLOBAL_CACHE_DIR = "${config.env.DEVENV_STATE}/zig-cache";
        ZIG_LOCAL_CACHE_DIR = "${config.env.DEVENV_STATE}/zig-cache";
      };

      # 4. Git hooks that are NOT formatters/linters.
      # Formatter (zig fmt) is now managed by treefmt.
      git-hooks.hooks = {
        # Run tests before pushing.
        zig-test = {
          enable = true;
          entry = "zig build test";
          stages = ["pre-push"];
        };
        # Check for build errors before committing.
        zig-build = {
          enable = true;
          entry = "zig build";
          stages = ["pre-commit"];
        };
      };

      # 5. Centralized formatting via treefmt.
      # This replaces the individual zig fmt git hook.
      treefmt.config.programs = {
        zig.enable = true;
        # Zig includes built-in formatting via 'zig fmt'
        # treefmt will use the zig package we configured above
      };

      # 6. Script to generate a default build.zig.zon and build.zig with best practices.
      scripts.zig-init = {
        description = "Initialize or update Zig project with optimized build.zig and build.zig.zon";
        exec = ''
          # Create build.zig.zon if it doesn't exist
          if [ ! -f "$DEVENV_ROOT/build.zig.zon" ]; then
            cat > "$DEVENV_ROOT/build.zig.zon" << 'EOF'
          .{
              .name = "zig-project",
              .version = "0.1.0",
              .minimum_zig_version = "0.13.0",

              .dependencies = .{},

              .paths = .{
                  "build.zig",
                  "build.zig.zon",
                  "src",
                  "README.md",
              },
          }
          EOF
            echo "Created build.zig.zon with project metadata"
          fi

          # Create build.zig if it doesn't exist
          if [ ! -f "$DEVENV_ROOT/build.zig" ]; then
            cat > "$DEVENV_ROOT/build.zig" << 'EOF'
          const std = @import("std");

          pub fn build(b: *std.Build) void {
              const target = b.standardTargetOptions(.{});
              const optimize = b.standardOptimizeOption(.{});

              // Main executable
              const exe = b.addExecutable(.{
                  .name = "zig-project",
                  .root_source_file = b.path("src/main.zig"),
                  .target = target,
                  .optimize = optimize,
              });

              // Install the executable
              b.installArtifact(exe);

              // Run the app
              const run_cmd = b.addRunArtifact(exe);
              run_cmd.step.dependOn(b.getInstallStep());

              const run_step = b.step("run", "Run the app");
              run_step.dependOn(&run_cmd.step);

              // Tests
              const exe_tests = b.addTest(.{
                  .root_source_file = b.path("src/main.zig"),
                  .target = target,
                  .optimize = optimize,
              });

              const test_step = b.step("test", "Run unit tests");
              test_step.dependOn(&exe_tests.step);

              // Benchmarks (optional)
              const bench = b.addExecutable(.{
                  .name = "benchmark",
                  .root_source_file = b.path("src/benchmark.zig"),
                  .target = target,
                  .optimize = .ReleaseFast,
              });

              const bench_step = b.step("bench", "Run benchmarks");
              bench_step.dependOn(&bench.step);
          }
          EOF
            echo "Created build.zig with standard build configuration"
          fi

          # Create src/main.zig if it doesn't exist
          if [ ! -f "$DEVENV_ROOT/src/main.zig" ]; then
            mkdir -p "$DEVENV_ROOT/src"
            cat > "$DEVENV_ROOT/src/main.zig" << 'EOF'
          const std = @import("std");

          pub fn main() !void {
              const stdout = std.io.getStdOut().writer();
              try stdout.print("Hello, {s}!\n", .{"Zig"});
          }

          test "basic test" {
              const expected: i32 = 42;
              const actual: i32 = 42;
              try std.testing.expectEqual(expected, actual);
          }
          EOF
            echo "Created src/main.zig with hello world and basic test"
          fi
        '';
      };

      # 7. Task to run the init script automatically.
      tasks."zig:init".exec = "zig-init";
      tasks."zig:init".before = ["devenv:enterShell"];
    };
  };
}
