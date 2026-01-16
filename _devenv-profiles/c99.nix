{
  pkgs,
  lib,
  config,
  ...
}:
{
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

      # 6. Scaffolding Task (Copier)
      tasks."c99:init" = {
        description = "Scaffold/Update C99 Project via Copier";
        # --trust required for local templates often; --skip-if-exists is default behavior when running against a directory with .copier-answers.yml
        exec = "copier copy --trust _devenv-profiles/copier_templates/c99 .";
        before = [ "devenv:enterShell" ];
      };

      scripts.c99-clean = {
        description = "Clean C99 project scaffolding";
        exec = ''
          rm -rf builddir src tests .clang-tidy .clang-format meson.build
        '';
      };
    };
  };
}
