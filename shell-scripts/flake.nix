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

        src = [
          ./new_csp.sh
        ];

        unpackPhase = ''
          for srcFile in $src; do
            cp $srcFile $(stripHash $srcFile)
          done
          ls -al
        '';

        buildPhase = ''
          echo "#!${pkgs.bash}/bin/bash" > script.sh
          cat ./new_csp.sh >> script.sh
          echo "" >> script.sh
          echo "new-csp \$@" >> script.sh
        '';

        installPhase = ''
            mkdir -p $out/bin
            cp ./script.sh $out/bin/new-csp
            chmod +x $out/bin/new-csp
        '';
      };
    }
  );
}