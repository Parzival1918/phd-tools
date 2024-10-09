{
  description = "Flake containing the python dev shell";

  inputs = {
      flake-utils.url = "github:numtide/flake-utils";
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    {
      devShells.conda-py = pkgs.mkShell {
        name = "conda-py";

        nativeBuildInputs = [
          pkgs.conda
        ];
        
        CSPY_PATH="~/phd/cspy-git";

        shellHook = ''
          echo "Entered the conda-py shell"
          echo "cspy-git location set to: ''${CSPY_PATH}"
          echo "First activate the 'phd-py-scripts' conda env"
          ${pkgs.conda}/bin/conda-shell 
        '';
      };

      devShells.default = self.outputs.devShells.${system}.conda-py;
    }
  );
}
