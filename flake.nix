{
  description = "Flake providing access to all tools";

  inputs = {
      flake-utils.url = "github:numtide/flake-utils";
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      phd-derivations.url = "./nix-derivations";
      dev-shells.url = "./dev-shells";
  };

  outputs = { self, flake-utils, ... }@inputs:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      phd-packages = inputs.phd-derivations.packages.${system};
      dev-shells = inputs.dev-shells.devShells.${system};
    in
    {
      packages = phd-packages;

      devShells = {
        inherit (dev-shells) fortran;
        inherit (dev-shells) rust;
      };

      devShells.cspy-external = pkgs.mkShell {
        name = "cspy-external";

        nativeBuildInputs = [
          phd-packages.gdma
          phd-packages.mulfit
          phd-packages.neighcrys
          phd-packages.dmacrys
          phd-packages.pmin
          phd-packages.platon
        ];

        shellHook = ''
          echo "Entered the cspy-external shell"
          echo "Available packages:"
          echo " - gdma"
          echo " - mulfit"
          echo " - neighcrys"
          echo " - dmacrys"
          echo " - pmin"
          echo " - platon"
        '';
      };
    }
  );
}