{
  description = "Flake for installing programs I need for my PhD";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.gdma = pkgs.stdenv.mkDerivation {
          pname = "gdma";
          version = "2.3";

          src = pkgs.fetchFromGitLab {
            owner = "anthonyjs";
            repo = "gdma";
            rev = "6b8e81ec141fade2cc24c142d58ce82178c85f61";
            sha256 = "sha256-aepRI8K/Zy02R0RJtgWUZDBo7l+iWhqMj0fmrJaSuCk=";
          };

          buildInputs = [
            pkgs.gfortran
            pkgs.python39
          ];

          preBuild = ''
            rm ./src/version.py
            cat <<EOF > ./src/version.py
            #!/usr/bin/python3
            import argparse
            import re

            parser = argparse.ArgumentParser(prog="a")

            parser.add_argument("vfile", help="VERSION file path")
            parser.add_argument("v90", help="version.f90 file path")
            parser.add_argument("compiler", help="Compiler")

            args = parser.parse_args()

            with open(args.vfile) as IN:
                line = IN.readline().strip()
                version = re.sub(r"VERSION +:= +", "", line)
                line = IN.readline().strip()
                patchlevel = re.sub("PATCHLEVEL +:= +", "", line)

            now = "nixpkgs"
            commit = "COMMIT-HASH"

            with open(args.v90,"w") as OUT:
                OUT.write(f"""MODULE version

                          !  version.f90 is generated automatically by version.py
                          !  GDMA version and build date
                          CHARACTER(*), PARAMETER :: gdma_version = "{version}.{patchlevel}"
                          """)

                OUT.write(f'CHARACTER(*), PARAMETER :: commit="{commit}"\n')
                OUT.write(f'CHARACTER(*), PARAMETER :: compiler="{args.compiler}"\n')
                OUT.write(f'CHARACTER(*), PARAMETER :: compiled="{now}"\n')

                OUT.write('\nEND MODULE version\n')

            EOF

            chmod +x ./src/version.py
            patchShebangs ./src/version.py

            touch ./version.f90
            chmod +x ./version.f90
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp bin/gdma $out/bin
          '';
        };

        packages.mulfit = pkgs.stdenv.mkDerivation {
          pname = "mulfit";
          version = "2.1";

          src = pkgs.fetchzip {
            url = "https://gitlab.com/anthonyjs/gdma/-/raw/master/mulfit-2.1.tgz?ref_type=heads";
            extension = ".tgz";
            sha256 = "sha256-tX5V5M5hgSRgniot990JgOjNot5E+6ourhX/SEZGYuA=";
          };

          buildInputs = [
            pkgs.gfortran
          ];

          preBuild = ''
            patchShebangs ./src/compile.sh
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp mulfit $out/bin
          '';
        };
      }
    );
}