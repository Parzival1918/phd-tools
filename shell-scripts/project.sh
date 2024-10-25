function project() {
    # function to interact with a project.

    # First check that a file called project.info exists
    # in the current folder or one of its parents
    local project_location=""
    local path=${PWD}
    while [[ $path != / ]]; do
        if [ -f ${path}/project.info ]; then
            echo "File found $path"
            project_location=$path
            break
        fi
        # Note: if you want to ignore symlinks, use "$(realpath -s "$path"/..)"
        path="$(readlink -f "$path"/..)"
    done

    if [ "$project_location" = "" ]; then
        tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " No project.info file found"
        #return 1
    fi

    local command=${1:?"You must use on of the following commands: info, log"}

    case $command in
        info)
            echo "Info"
            ;;

        log)
            local dump=${2:?"You need to pass something to run to 'project log'!"}
            local runcommand=${@:2}
            local datetime=$(date +"%Y-%m-%d-%T")
            local logfile="$datetime.log"
            tput bold; tput setaf 3; echo -n "Running command: "; tput sgr0; echo $runcommand
            tput bold; tput setaf 3; echo -n "Command stdout and stderr logged to: "; tput sgr0; echo $logfile 
            ;;

        *)
            tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " Unknown command ${command}"
            ;;
    esac
}
