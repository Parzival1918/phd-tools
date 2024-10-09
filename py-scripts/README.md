# py-scripts

Using `conda` to manage the python virtual environments in order to use same tool that is used for CSPy development.

First of all enter the python devShell provided by the flake.nix file in this directory.

## First time

1. `conda env create -f conda_env.yml`
2. `conda activate phd-py-scripts`
3. `pip install -e ${CSPY_PATH}`

## Updating environment

1. `conda activate phd-py-scripts`
2. `conda env update --file conda_env.yml --prune`