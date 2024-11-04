function utility-scripts {
    local out="utility-scripts"
    local README="
    "

    if [ -d "${out}" ]; then
        tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " Folder with name '${out}' already exists"
		return 1
    fi

    mkdir ${out}
    cd ${out}

    tput bold; tput setaf 3; echo -n "Writing scripts to '${out}' folder... "; tput sgr0
}