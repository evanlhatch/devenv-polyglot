{
  pkgs,
  lib,
  config,
  ...
}:
{
  profiles.nix-dev = {
    module = {
      # enterShell = ''
      #   export DEVENV_ACTIVE_PROFILES="''${DEVENV_ACTIVE_PROFILES} ❄️ nix-dev"
      # '';

      # Nix-specific packages required for linting and formatting
      packages = with pkgs; [
        alejandra
        deadnix
        nixf-diagnose
        statix
      ];

      # Nix-specific linters and formatters integrated with treefmt
      treefmt.config.programs = {
        alejandra.enable = true; # For consistent Nix code formatting
        deadnix.enable = true; # For finding dead code in Nix expressions
        nixf-diagnose.enable = true; # For general Nix diagnostics
        statix.enable = true; # For static analysis of Nix code
      };
    };
  };
}
