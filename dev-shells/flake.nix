{
  description = "Flake containing dev shells for different langs";

  inputs = {
      flake-utils.url = "github:numtide/flake-utils";
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      
      overlays = [ (import inputs.rust-overlay) ];
      pkgs-overlay = import nixpkgs {
        inherit system overlays;
      };
    in
    {
      devShells.fortran = pkgs.mkShell {
        name = "fortran";

        nativeBuildInputs = [
          pkgs.gfortran10
          pkgs.gnumake
          pkgs.fortran-fpm
        ];

        shellHook = ''
          alias fpm="${pkgs.fortran-fpm}/bin/fortran-fpm"

          echo "Entered the fortran shell"
          echo "Available packages:"
          echo " - gfortran"
          echo " - make"
          echo " - fpm (alias of fortran-fpm)"
        '';
      };

      devShells.rust = pkgs-overlay.mkShell {
        name = "rust";

        nativeBuildInputs = [
          pkgs-overlay.rust-bin.stable.latest.default
        ];

        shellHook = ''
          echo "Entered the rust shell"
          echo "Available packages:"
          echo " - rustc"
          echo " - rustdoc"
          echo " - rustfmt"
          echo " - cargo"
          echo " - cargo-clippy"
          echo " - cargo-fmt"
          echo " - clippy-driver"
        '';
      };
    }
  );
}
