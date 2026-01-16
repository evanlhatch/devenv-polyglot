{
  pkgs,
  lib,
  config,
  ...
}:
{
  # Configure Nix binary caches via environment variables
  # These will be available in the devenv shell and respected by Nix
  env = {
    # Binary caches configuration - all the major caches for faster builds
    NIX_SUBSTITUTERS = "https://cache.nixos.org/ https://nix-community.cachix.org https://nixpkgs-unfree.cachix.org https://cache.flox.dev";
    NIX_TRUSTED_PUBLIC_KEYS = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs= flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs=";

    # Critical for caching to work smoothly
    NIX_CONFIG = "experimental-features = nix-command flakes\nbuilders-use-substitutes = true\nhttp-connections = 50\nmax-jobs = auto";

    # Allow unfree packages (required for certain caches like nixpkgs-unfree)
    NIXPKGS_ALLOW_UNFREE = "1";
  };
}
