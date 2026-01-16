{
  pkgs,
  lib,
  ...
}:
let
  rustFlags = [
    # Faster linker (mold)
    "-C"
    "link-arg=-fuse-ld=mold"
    # Turn off LTO in dev for faster compiles
    "-C"
    "lto=off"
    # Maximum codegen units for parallelism
    "-C"
    "codegen-units=256"
  ];
in
{
  profiles.rust = {
    module = {
      enterShell = ''
        export DEVENV_ACTIVE_PROFILES="''${DEVENV_ACTIVE_PROFILES} 🦀 rust"
      '';

      # 1. Enable devenv's core Rust language support.
      languages.rust = {
        enable = true;
        mold.enable = true;
        rustflags = lib.concatStringsSep " " rustFlags;
      };

      # 2. Define the package set for the Rust stack.
      packages = with pkgs; [
        # Core dev tools
        cargo-watch
        cargo-edit
        cargo-outdated
        bacon
        sccache

        # Testing & benchmarking
        cargo-nextest
        cargo-hack
        cargo-bloat
        cargo-llvm-lines

        # Dependency management
        cargo-machete
      ];

      # 3. Configure environment variables for optimizations.
      env = {
        RUSTFLAGS = lib.concatStringsSep " " rustFlags;
        RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
      };

      # 4. Git hooks that are NOT formatters/linters.
      # Formatters (rustfmt) and linters (clippy) are now managed by treefmt.
      git-hooks.hooks = {
        # Run tests before pushing.
        cargo-test = {
          enable = true;
          entry = "cargo nextest run";
          stages = [ "pre-push" ];
        };
        # Check for unused dependencies before committing.
        cargo-machete = {
          enable = true;
          entry = "cargo machete";
          stages = [ "pre-commit" ];
        };
      };

      # 5. Centralized formatting and linting via treefmt.
      # This replaces the individual git-hooks for fmt and clippy.
      treefmt.config.programs = {
        # Enable rustfmt for code formatting.
        rustfmt.enable = true;
        # Enable clippy for linting.
        clippy = {
          enable = true;
          # Ensure the pre-commit hook fails if there are any warnings.
          options = [
            "--"
            "-D"
            "warnings"
          ];
        };
      };

      # 6. Script to generate a default Cargo.toml with best practices.
      scripts.rust-init = {
        description = "Initialize or update Rust project with optimized Cargo.toml";
        exec = ''
          if [ ! -f "$DEVENV_ROOT/Cargo.toml" ]; then
            cat > "$DEVENV_ROOT/Cargo.toml" << 'EOF'
          [package]
          name = "rust-project"
          version = "0.1.0"
          edition = "2021"

          # See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

          [dependencies]
          anyhow = "1.0"
          thiserror = "1.0"
          clap = { version = "4.5", features = ["derive"] }
          tokio = { version = "1.40", features = ["full"] }
          rayon = "1.10"
          tracing = "0.1"
          tracing-subscriber = { version = "0.3", features = ["env-filter"] }
          bumpalo = "3.16"
          typed-arena = "2.0"

          [dev-dependencies]
          pretty_assertions = "1.4"
          proptest = "1.5"
          insta = "1.40"
          criterion = "0.5"

          [profile.dev]
          opt-level = 1
          debug = "line-tables-only"
          incremental = true
          lto = "off"
          codegen-units = 256

          [profile.dev.package."*"]
          opt-level = 3

          [profile.release]
          opt-level = 3
          debug = false
          lto = "thin"
          codegen-units = 16
          EOF
            echo "Created default Cargo.toml with optimized profiles and common dependencies"
          fi
        '';
      };

      # 7. Task to run the init script automatically.
      tasks."rust:init".exec = "rust-init";
      tasks."rust:init".before = [ "devenv:enterShell" ];
    };
  };
}
