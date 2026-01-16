{
  pkgs,
  lib,
  config,
  ...
}:
{
  profiles.go = {
    module = {
      enterShell = ''
        export DEVENV_ACTIVE_PROFILES="''${DEVENV_ACTIVE_PROFILES} 🐹 go"
      '';

      # 1. Enable devenv's core Go language support.
      languages.go.enable = true;

      # 2. Define the package set for the Go stack.
      packages = with pkgs; [
        # Linter
        golangci-lint
        gotip
        # For database codegen
        sqlc
        # Stricter-than-gofmt formatter
        gofumpt
      ];

      # 3. Git hooks that are NOT formatters/linters.
      # Formatter (gofumpt) and linter (golangci-lint) are now managed by treefmt.
      git-hooks.hooks = {
        # Tidy Go modules before committing.
        go-mod-tidy = {
          enable = true;
          entry = "go mod tidy";
          stages = [ "pre-commit" ];
        };
        # Run tests before pushing.
        go-test = {
          enable = true;
          entry = "go test ./...";
          stages = [ "pre-push" ];
        };
      };

      # 4. Centralized formatting and linting via treefmt.
      # This replaces the individual golangci-lint git hook.
      treefmt.config.programs = {
        gofumpt.enable = true;
        golangci-lint.enable = true;
      };

      # 5. Script to generate default go.mod and go.work files.
      scripts.init-go-modules = {
        description = "Initialize Go modules (go.mod and go.work) in root directory";
        exec = ''
          # Create go.mod if it doesn't exist
          if [ ! -f "$DEVENV_ROOT/go.mod" ]; then
            echo "Creating go.mod in root directory..."
            cat > "$DEVENV_ROOT/go.mod" << 'EOF'
          module devenv-polyglot

          go 1.22

          require (
          	github.com/samber/oops v1.19.3
          	github.com/stretchr/testify v1.9.0
          )
          EOF
          fi

          # Create go.work if it doesn't exist
          if [ ! -f "$DEVENV_ROOT/go.work" ]; then
            echo "Creating go.work in root directory..."
            cat > "$DEVENV_ROOT/go.work" << 'EOF'
          go 1.22

          use (
              ./go-example
          )
          EOF
          fi
        '';
      };

      # 6. Task to run the init script automatically.
      tasks."go:init-modules".exec = "init-go-modules";
      tasks."go:init-modules".before = [ "devenv:enterShell" ];
    };
  };
}
