function new-thresh {
    # function to create the dir structure of a new MC Threshold run

    HELP_STR="USAGE: new-thresh [FOLDER_NAME] [MOLECULE_XYZ]

ARGUMENTS:
	FOLDER_NAME:  Name of the folder that will be created containing the project.
	MOLECULE_XYZ:  Path to the initial molecule .xyz file

by Pedro Juan Royo
	"
    FOLDER_1="1-relax-structure"
	FOLDER_2="2-dma"
	FOLDER_3="3-starting-crystal-structures"
    FOLDER_4="4-threshold-calculation"
    FOLDER_5="5-generate-disconnectivity-graph"

    PROJ_FOLDER=${1:?"${HELP_STR}"}

	if [ -d "${PROJ_FOLDER}" ]; then
		tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " Folder with name '${PROJ_FOLDER}' already exists"
		return 1
	fi

	if [ -f "${PROJ_FOLDER}" ]; then
		tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " Folder with name '${PROJ_FOLDER}' cannot be created as file with same name exists"
		return 1
	fi

	if [ $# -lt 2 ]; then
		echo "${HELP_STR}"
		return 1
	fi

	MOLECULES=("${@:2}")
	for M in "${MOLECULES[@]}"; do
		if [ ! -f "${M}" ]; then
			tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " No file named '${M}' found"
			return 1
		fi

		EXTENSION=${M##*.}
		if [ ${EXTENSION} != "xyz" ]; then
			tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " Extension of '${M}' is not .xyz"
			return 1
		fi
	done

	declare -A uniq_tmp

	for M in "${MOLECULES[@]}"; do
		uniq_tmp[$M]=0 # assigning a placeholder
	done

	OPT_XY_STRING=""
	G09_STRING=""
	for M in "${!uniq_tmp[@]}"; do
		m=${M%.xyz}
		G09_STRING+="g09 ${m}.com ${m}.log; "
		OPT_XY_STRING+="python opt_xyz_extractor_gaussian.py ${m}.log ${m}.xyz; "
	done

	# check if csp_settings.txt file exists and source it
	if [ -f "thresh_settings.txt" ]; then
		echo "Settings file detected. Sourcing... "
		set -v
		source thresh_settings.txt
		set +v
		echo "Settings file sourced."
	fi

    # default and take settings from env vars
	GAUSSIAN_CPUS=${GAUSSIAN_CPUS:-"4"}
	GAUSSIAN_JOB_TIME=${GAUSSIAN_JOB_TIME:-"05:00:00"}
	GAUSSIAN_FUNCTIONAL=${GAUSSIAN_FUNCTIONAL:-"B3LYP"}
	GAUSSIAN_BASIS_SET=${GAUSSIAN_BSIS_SET:-"6-311G**"}
	MC_JOB_TIME=${MC_JOB_TIME:-"24:00:00"}
	REOPTIMIZE_JOB_TIME=${REOPTIMIZE_JOB_TIME:-"05:00:00"}

	if [ -z "${GAUSSIAN_CHARGE}" ]; then 
		GAUSSIAN_CHARGE=()
		for i in "${MOLECULES[@]}"; do
			GAUSSIAN_CHARGE+=(0)
		done
	fi
	if [ -z "${GAUSSIAN_MULTIPLICITY}" ]; then 
		GAUSSIAN_MULTIPLICITY=()
		for i in "${MOLECULES[@]}"; do
			GAUSSIAN_MULTIPLICITY+=(1)
		done
	fi

	if [ ! "${#MOLECULES[@]}" == "${#GAUSSIAN_CHARGE[@]}" ]; then
		tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " Length of GAUSSIAN_CHARGE and MOLECULES does not match:"
		echo " GAUSSIAN_CHARGE -> ${GAUSSIAN_CHARGE[@]}"
		echo " MOLECULES -> ${MOLECULES[@]}"
		return 1
	fi

	if [ ! "${#MOLECULES[@]}" == "${#GAUSSIAN_MULTIPLICITY[@]}" ]; then
		tput bold; tput setaf 1; echo -n "ERROR:"; tput sgr0; echo " Length of GAUSSIAN_MULTIPLICITY and MOLECULES does not match:"
		echo " GAUSSIAN_MULTIPLICITY -> ${GAUSSIAN_MULTIPLICITY[@]}"
		echo " MOLECULES -> ${MOLECULES[@]}"
		return 1
	fi

	# replace vars to string contents of files
	GAUSSIAN_JOB_SCRIPT="#!/bin/bash
#SBATCH --job-name=${PROJ_FOLDER}_gauss
#SBATCH --mincpus=${GAUSSIAN_CPUS}
#SBATCH --nodes=1-1
#SBATCH --ntasks=1
#SBATCH --time=${GAUSSIAN_JOB_TIME}


cd \$SLURM_SUBMIT_DIR


export GAUSS_SCRDIR=/scratch/\$USER
export g09root=/iridisfs/i6software/gaussian
source \$g09root/g09/bsd/g09.profile

${G09_STRING}

# extract optimized coords from log file
source ~/.bashrc
conda activate cspy

${OPT_XY_STRING}
	"
    EXTRACT_OPT_XYZ="from cspy.chem import Molecule
import argparse


parser = argparse.ArgumentParser()

parser.add_argument(
    \"gaussian_log_file\",
    type=str,
    help=\"The (successful) Gaussian calculation log file \"
    \"containing the molecular structure to be extracted.\"
    )

parser.add_argument(
    \"output_xyz_file\",
    type=str,
    help=\"The name of the XYZ file to output the structure to.\"
    )

args = parser.parse_args()

mol = Molecule.from_gaussian_optimization(args.gaussian_log_file)
mol.to_xyz_file(args.output_xyz_file)
	"
	GAUSSIAN_INPUT_FILE="%mem=4GB
%nprocshared=${GAUSSIAN_CPUS}
# ${GAUSSIAN_FUNCTIONAL}/${GAUSSIAN_BASIS_SET} opt NoSymm EmpiricalDispersion=GD3BJ

Geometry optimisation calculation for ${PROJ_FOLDER}

__charge__ __multiplicity__"
	DMA_ANALYSIS_SCRIPT="#!/bin/bash

source ~/.bashrc
conda activate cspy
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

ln -fs ../${FOLDER_1}/*.xyz ./

cspy-dma ${MOLECULES[@]} --charges \"${GAUSSIAN_CAHRGE[@]}\" --multiplicities \"${GAUSSIAN_MULTIPLICITY[@]}\"
	"
    TO_P1_SCRIPT="from cspy.crystal import Crystal
import sys

crystal = Crystal.load(sys.argv[1])
p1_crystal = crystal.as_P1()
p1_crystal.save(sys.argv[2])
    "

    if [ -d "${PROJ_FOLDER}" ]; then
		echo "ERROR: Folder with name '${PROJ_FOLDER}' already exists"
		return 1
	fi

	if [ ! -f "${MOLECULE_XYZ}" ]; then
		echo "ERROR: No file named '${MOLECULE_XYZ}' found"
		return 1
	fi

    # create project folder
	mkdir ${PROJ_FOLDER}
	cd ${PROJ_FOLDER}

	# create step folders
	mkdir ${FOLDER_1} ${FOLDER_2} ${FOLDER_3}

	# create contents of FOLDER_1
	for M in "${!uniq_tmp[@]}"; do # copy original xyz files
		cp ../${M} ${FOLDER_1}/${M}.original
	done
	local i=0
	for M in "${MOLECULES[@]}"; do # create g09 .com input files for each
		m=${M%.xyz} # molecule file name without .xyz extension
		echo "${GAUSSIAN_INPUT_FILE}" > ${FOLDER_1}/${m}.com
		tail -n +3 ../${M} >> ${FOLDER_1}/${m}.com
		echo "" >> ${FOLDER_1}/${m}.com # adding two empty lines at end for format requirements
		echo "" >> ${FOLDER_1}/${m}.com

		# substitute in the values of charge and multiplicity
		sed -i "s/__charge__/${GAUSSIAN_CHARGE[$i]}/" ${FOLDER_1}/${m}.com
		sed -i "s/__multiplicity__/${GAUSSIAN_MULTIPLICITY[$i]}/" ${FOLDER_1}/${m}.com

		let "i++"
	done
	echo "${EXTRACT_OPT_XYZ}" > ${FOLDER_1}/opt_xyz_extractor_gaussian.py
	echo "${GAUSSIAN_JOB_SCRIPT}" > ${FOLDER_1}/job_submit.sh
	echo "# ${FOLDER_1}

Step consists in relaxing the molecule structure in the gas phase.
The g09 software is used, and an input .com file must be created
from the original .xyz data of the molecule.

The relaxed structure is saved to a new .xyz file using the 
opt_xyz_extractor_gaussian.py script, which extracts the data from
the gaussian .log file.

The resulting relaxed structure of the molecule will be used in 
the next step to create the multipoles using gdma.
	" > ${FOLDER_1}/README.md 

	# create contents of FOLDER_2
	cd ${FOLDER_2}
	ln -s ../${FOLDER_1}/${MOLECULE}.xyz ${MOLECULE}.xyz
	echo "${DMA_ANALYSIS_SCRIPT}" > dma_analysis.sh
	chmod +x dma_analysis.sh
	echo "# ${FOLDER_2}

Step consists in creating the multipoles of the molecule that has
been relaxed in the previous step (${FOLDER_1}). This should 
produce the files: 

1. NAME.mols (Molecular axis definition in NEIGHCRYS/DMACRYS format)
2. NAME.dma (Molecular multipoles file)
3. NAME_rank0.dma (Molecular charges)
	" > README.md 
	cd ..

    # create contents of FOLDER_3
    cd ${FOLDER_3}
    echo "${TO_P1_SCRIPT}" > to_p1.py
    echo "# ${FOLDER_3}

Add the starting crystal structures to start the MC runs from there.
They must all be converted to P1 symmetry. Use the to_p1.sh script
to turn all SHELX or CIF input files to P1.
	" > README.md 
	cd ..

    # create contents of FOLDER_4
    cd ${FOLDER_4}
    echo "# ${FOLDER_4}

Run the MC threshold calculation.
	" > README.md 
	cd ..

    # create contents of FOLDER_5
    cd ${FOLDER_5}
    echo "# ${FOLDER_5}

Create the connectivity graph.
	" > README.md 
	cd ..
}