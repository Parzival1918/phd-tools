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

        packages.neighcrys = pkgs.stdenv.mkDerivation {
          pname = "neighcrys";
          version = "2.3.1";

          buildInputs = [
            pkgs.gfortran
          ];

          src = pkgs.fetchFromGitLab {
            owner = "mol-cspy";
            repo = "neighcrys";
            rev = "4591d8a27f1d202df5fc0185de895225073a7dae";
            sha256 = "sha256-wOM8W76HpctZq5hKOThAQ7bO7JEzNFfs4jN1ECgAr9U=";
          };

          preBuild = ''
            sed -i 's/FC=ifort/FC=gfortran/' ./makefile
            sed -i 's/fflags0="-g -check"/fflags0="-g -fbacktrace -fcheck=all"/' ./makefile
            sed -i 's/$(FC) -o neighcrys.out $(fflags3) $(ffiles) $(cfiles)/$(FC) -o neighcrys.out $(fflags) $(ffiles) $(cfiles)/' ./makefile
            sed -i 's/$(FC) -o neighcrysO0.out $(fflags0) $(ffiles) $(cfiles)/$(FC) -o neighcrysO0.out $(fflags) $(ffiles) $(cfiles)/' ./makefile
            sed -i 's/fflags3="-O3"/fflags3="-O3"/' ./makefile
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp neighcrys.out $out/bin/neighcrys
            cp neighcrysO0.out $out/bin/neighcrysO0
          '';
        };

        packages.dmacrys = pkgs.stdenv.mkDerivation {
          pname = "dmacrys";
          version = "2.3.1";

          buildInputs = [
            pkgs.gfortran7
          ];

          src = pkgs.fetchFromGitLab {
            owner = "mol-cspy";
            repo = "dmacrys";
            rev = "badbb0381ce7602ccf9f83718a1a3029e72add5d";
            sha256 = "sha256-Uo8JxYE2ZTilGDniZ3ZG6/wT8fxB4YBO/QZ7d0aAH48=";
          };

          preBuild = ''
            sed -i 's/FC=ifort/FC=gfortran/' ./makefile
            sed -i 's/fflags0="-g -check -Wall -fbounds-check"/fflags0="-g -fbacktrace -fcheck=all"/' ./makefile
            sed -i 's/fflags3="-O3 -static"/fflags3="-O3"/' ./makefile
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp dmacrys.out $out/bin/dmacrys
            cp dmacrysO0.out $out/bin/dmacrysO0
          '';
        };

        packages.platon = pkgs.stdenv.mkDerivation {
          pname = "platon";
          version = "x";

          buildInputs = [
            pkgs.gfortran
            pkgs.xorg.libX11
          ];

          src = pkgs.fetchzip {
            url = "https://www.platonsoft.nl/xraysoft/unix/platon.tar.gz";
            curlOpts = "--insecure";
            sha256 = "sha256-BqWsTgkO4zx6zAoIVqd1R+Q+liL6RwbeP596sv9DmQM=";
          };

          buildPhase = ''
            echo "Unpacking source files..."  
            gzip -d platon.f.gz
            gzip -d xdrvr.c.gz
            gfortran -O3 -o platon platon.f xdrvr.c -lX11
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp platon $out/bin
          '';
        };

        packages.pmin = pkgs.stdenv.mkDerivation {
          pname = "pmin";
          version = "x";

          buildInputs = [
            pkgs.gfortran10
          ];

          src = pkgs.fetchzip { # The source code is taken from MOLPAK
            url = "https://sourceforge.net/projects/molpak/files/Molpak/PREDICTIONS.tar.gz";
            sha256 = "sha256-h8DGU6PsBJbDFrrGRx+fPTA/pujChVZpUQHcDQOb9EI=";
          };

          buildPhase = ''
            cd PMIN
            rm -f *.o
            rm -f *.mod
            rm -f pmin.exe
            gfortran -O3 -c f77kinds.f90
            gfortran -O3 -c *module.f90 f77kinds.o
            gfortran -O3 -std=legacy -c pmin_26oct10.f90
            gfortran -O3 -o pmin *.o
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp pmin $out/bin
          '';
        };

        packages.cspy = pkgs.stdenv.mkDerivation {
          pname = "cspy";
          varsion = "2.x";

          src = builtins.getEnv "SCPY_PATH";

          buildInputs = [
            pkgs.conda
          ];

          buildPhase = ''
            
          '';
        };
      }
    );
}