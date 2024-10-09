# py-scripts

Using `conda` to manage the python virtual environments in order to use same tool that is used for CSPy development.

First of all enter the python devShell provided by the `flake.nix` file in this directory.

`meta.yaml` file was a test to see if I could install CSPy using `conda build` and `conda install`. I have not yet managed to get this working properly, if I did it would be great as it would mean I can package CSPy for use in Nix using a flake.

## First time

1. `conda env create -f conda_env.yml`
2. `conda activate phd-py-scripts`
3. `pip install -e ${CSPY_PATH}`

## Updating environment

1. `conda activate phd-py-scripts`
2. `conda env update --file conda_env.yml --prune`