function project() {
    # function to interact with a project.

    # First check that a file called project.info exists
    # in the current folder or one of its parents
    local project_location=""
    local rundir=${PWD}
    local path=${PWD}
    while [[ $path != / ]]; do
        if [ -f ${path}/project.info ]; then
            tput bold; tput setaf 3; echo -n "Project found at:"; tput sgr0; echo " $path"
            project_location=$path
            break
        fi
        # Note: if you want to ignore symlinks, use "$(realpath -s "$path"/..)"
        path="$(readlink -f "$path"/..)"
    done

    if [ "$project_location" = "" ]; then
        tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " No project.info file found"
        return 1
    fi

    local command=${1:?"You must use one of the following commands: info, log, logs"}

    case $command in
        info)
            cat $project_location/project.info
            ;;

        log)
            local dump=${2:?"You need to pass something to run to 'project log'!"}
            local runcommand=${@:2}
            local datetime=$(date +"%Y-%m-%d-%T")
            local logfile="$datetime.log"
            local loglocation=$project_location/.logs/$logfile

            if [ ! -d $project_location/.logs ]; then
                mkdir $project_location/.logs
            fi

            if [ ! -f $project_location/project.logs ]; then
                touch $project_location/project.logs
            fi

            tput bold; tput setaf 3; echo -n "Running command: "; tput sgr0; echo $runcommand
            tput bold; tput setaf 3; echo -n "Command stdout and stderr logged to: "; tput sgr0; echo $logfile 

            echo "[$datetime at $rundir]: $runcommand" >> $project_location/project.logs

            echo "Command: $runcommand" > $loglocation
            echo "At folder: $rundir" >> $loglocation

            $runcommand 2>&1 | tee -a $loglocation
            ;;

        logs)
            local logstoprint=${2:-10}
            tput bold; tput setaf 3; echo -n "Printing the last"; tput sgr0; echo -n " $logstoprint"
            tput bold; tput setaf 3; echo " log entries"; tput sgr0

            tail -$logstoprint $project_location/project.logs
            ;;

        *)
            tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " Unknown command ${command}"
            ;;
    esac
}
