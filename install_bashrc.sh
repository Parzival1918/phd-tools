#!/bin/bash

if grep -q ">>>phd-tools managed block START<<<" ~/.bashrc; then
    tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " .bashrc already contains the managed source files"
    exit 1
fi

tput bold; tput setaf 3; echo "Adding to .bashrc sourcing of phd-tools"; tput sgr0

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "# >>>phd-tools managed block START<<<
source $SCRIPT_DIR/shell-scripts/add_to_bashrc.sh
# >>>phd-tools managed block END<<<
" >> ~/.bashrc
