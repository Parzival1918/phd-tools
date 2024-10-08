{
  description = "Flake containing shell scripts";

  inputs = {
      flake-utils.url = "github:numtide/flake-utils";
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, flake-utils, ... }@inputs:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    {
      packages.new-csp = pkgs.stdenv.mkDerivation {
        name = "new-csp";

        src = ./new_csp.sh;

        buildPhase = ''
            
        '';

        installPhase = ''
            mkdir -p $out/bin
            cp ./new_csp.sh $out/bin/
        '';
      };
    }
  );
}