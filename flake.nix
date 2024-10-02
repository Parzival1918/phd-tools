{
  description = "Flake providing access to all tools";

  inputs = {
      flake-utils.url = "github:numtide/flake-utils";
      # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      phd-derivations.url = "./nix-derivations";
  };

  outputs = { self, flake-utils, ... }@inputs:
  flake-utils.lib.eachDefaultSystem (system:
    let
      # pkgs = nixpkgs.legacyPackages.${system};
      phd-packages = inputs.phd-derivations.packages.${system};
    in
    {
      packages = phd-packages;
    }
  );
}