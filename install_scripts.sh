#!/bin/bash

installation_dir=${1:?"Give me an installation location!"}
# check that installation_dir exists
if [ ! -d $installation_dir ]; then
    tput bold; tput setaf 3; echo -n "Creating installation directory: "; tput sgr0; echo $installation_dir;
    mkdir $installation_dir
fi
installation_dir="$(cd "$installation_dir"; pwd)"

link_or_copy=${2:-"copied"}

if [ "$link_or_copy" != "copied" -a "$link_or_copy" != "linked" ]; then
    tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " Scripts can only be 'linked' or 'copied'"
    exit 1
fi

tput bold; tput setaf 3; echo -n "Scripts will be "; tput sgr0; echo -n $link_or_copy;
tput bold; tput setaf 3; echo -n " to target directory: "; tput sgr0; echo $installation_dir;

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

#copy or link files to target dir
script_names=(cancel.sh create_config.sh new_csp.sh new_thresh.sh project.sh)
for script_name in "${script_names[@]}"; do
    script_path="$SCRIPT_DIR/shell-scripts/$script_name"
    installation_path="$installation_dir/$script_name"
    echo -n $script_path; tput bold; tput setaf 3; echo -n " -> "; tput sgr0; echo $installation_path
    case $link_or_copy in
        linked)
            ln -sf $script_path $installation_path
            ;;

        copied)
            cp $script_path $installation_path
            ;;

        *)
            echo "Unavailable option"
            exit 1
            ;;
    esac
done
