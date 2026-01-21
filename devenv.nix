{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  # base
  env.VIRTUAL_ENV = "${config.env.DEVENV_STATE}/venv";

  packages = with pkgs; [
    copier
    buf
    protobuf
    #minijinja
    #trufflehog
    jujutsu
    infisical
    #secretspec
    #_1password
  ];

  difftastic.enable = true;
  delta.enable = true;
  cachix.enable = false;
  dotenv.enable = true;

  starship = {
    enable = false;
    config = {
      enable = true;
      settings = {
        format = "$all$env_var\n$character";
        env_var.DEVENV_ACTIVE_PROFILES = {
          variable = "DEVENV_ACTIVE_PROFILES";
          format = "via [$env_value]($style) ";
          style = "bold blue";
        };
      };
    };
  };

  # treefmt - meta-formatter
  # This section now uses the treefmt-nix module,
  # which automatically creates and manages the git hook.
  treefmt = {
    enable = true;
    config = {
      # Enable default excludes like .git/, node_modules/, target/, etc.
      enableDefaultExcludes = true;

      # Global excludes for the formatter, complementing enableDefaultExcludes
      # These are specific to development environments or build artifacts
      settings.global.excludes = [
        ".devenv"
        ".direnv"
        ".venv"
        "builddir"
        "result"
      ];

      # Warn if files are not matched by any formatter
      settings.global.on-unmatched = "warn";

      programs = {
        # --- Universal Formatters/Linters (always included) ---
        # YAML formatter
        yamlfmt.enable = true;
        # JSON formatter
        jsonfmt.enable = true;
        # TOML formatter
        taplo.enable = true;
        # Markdown formatter
        mdformat.enable = true;

        # Shell scripts formatters and linters (commented out, to be enabled in profiles)
        # shfmt.enable = true;
        # shellcheck.enable = true;

        # Justfiles formatter
        just.enable = true;

        # Spell checker
        typos = {
          enable = false;
          binary = false; # Ignore binary files
        };

        # Generic sorter (useful for many kinds of lists)
        keep-sorted.enable = true;
      };
    };
  };

  # shared hooks (non-formatting/linting)
  git-hooks = {
    excludes = []; # Excludes are now handled by treefmt.config.settings.global.excludes
    hooks = {
      trufflehog.enable = false;
      treefmt.enable = true;
      forbid-new-submodules.enable = true;
      check-merge-conflicts.enable = true;
    };
  };

  # Force .venv to be a symlink to the actual environment
  enterShell = ''
    if [ ! -L .venv ]; then
      echo "Fixing .venv symlink..."
      rm -rf .venv
      ln -s $VIRTUAL_ENV .venv
    fi
  '';

  enterTest = ''
    echo "Running tests..."
    just test-all
  '';

  /*
      -----------------------------------------------------------
      2.  PROFILES – opt-in language stacks
  -----------------------------------------------------------
  */
  # Import all profile modules from devenv-profiles folder for faster eval times
  imports = builtins.map (name: import (./_devenv-profiles + "/${name}")) (
    lib.attrNames (
      lib.filterAttrs (name: type: lib.hasSuffix ".nix" name) (builtins.readDir ./_devenv-profiles)
    )
  );
}
