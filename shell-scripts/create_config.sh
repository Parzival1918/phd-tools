function create-config {
    # create a .txt file that contains the default settings
    # in env variables for the new-csp and new-thresh funcs.

    HELP_STR="USAGE: create-config [TYPE]

ARGUMENTS:
	TYPE csp/thresh: Which type of configuration to create. 

by Pedro Juan Royo
	"
    CSP_SETTINGS_TEXT="
    GAUSSIAN_CPUS=4
	GAUSSIAN_JOB_TIME=05:00:00
	GAUSSIAN_FUNCTIONAL=B3LYP
	GAUSSIAN_BASIS_SET=6-311G**
	GAUSSIAN_CHARGE=(0)
	GAUSSIAN_MULTIPLICITY=(1)
	CSP_JOB_TIME=24:00:00
	REOPTIMIZE_JOB_TIME=05:00:00
    "
    THRESH_SETTINGS_TEXT="THRESH"

    local requested_config=${1:?"${HELP_STR}"}

    case ${requested_config} in
        "csp")
            if [ -f "csp_settings.txt" ]; then
                tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " 'csp_settings.txt' file already exists."
                return 1
            fi
            echo "${CSP_SETTINGS_TEXT}" > csp_settings.txt
            ;;

        "thresh")
            if [ -f "csp_settings.txt" ]; then
                tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " 'thresh_settings.txt' file already exists."
                return 1
            fi
            echo "${THRESH_SETTINGS_TEXT}" > thresh_settings.txt
            ;;

        *)
            tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " Unkown '${requested_config}' config type."
            return 1
            ;;
    esac
    tput bold; tput setaf 3; echo "Created '${requested_config}_settings.txt' settings file."; tput sgr0 
}