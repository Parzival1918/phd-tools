function new-csp {
	# function to create the dir structure of a new CSP run

	HELP_STR="USAGE: new-csp [FOLDER_NAME] [MOLECULE_XYZ]

ARGUMENTS:
	 FOLDER_NAME:  Name of the folder that will be created containing the project.
	MOLECULE_XYZ:  Path to the initial molecule .xyz file

by Pedro Juan Royo
	"
	FOLDER_1="1-relax-structure"
	FOLDER_2="2-dma"
	FOLDER_3="3-csp"
	FOLDER_4="4-remove-duplicates"
	FOLDER_5="5-analyse-landscape"
	FOLDER_6="6-reoptimise"

	PROJ_FOLDER=${1:?"${HELP_STR}"}
	MOLECULE_XYZ=${2:?"${HELP_STR}"}
	MOLECULE=${MOLECULE_XYZ%.xyz}

	# default and take settings from env vars
	GAUSSIAN_CPUS=${GAUSSIAN_CPUS:-"4"}
	GAUSSIAN_JOB_TIME=${GAUSSIAN_JOB_TIME:-"05:00:00"}
	GAUSSIAN_FUNCTIONAL=${GAUSSIAN_FUNCTIONAL:-"B3LYP"}
	GAUSSIAN_BASIS_SET=${GAUSSIAN_BSIS_SET:-"6-311G**"}
	GAUSSIAN_CHARGE=${GAUSSIAN_CHARGE:-"0"}
	GAUSSIAN_MULTIPLICITY=${GAUSSIAN_MULTIPLICITY:-"1"}
	CSP_JOB_TIME=${CSP_JOB_TIME:-"24:00:00"}

	# replace vars to string contents of files
	GAUSSIAN_JOB_SCRIPT="#!/bin/bash
#SBATCH --mincpus=${GAUSSIAN_CPUS}
#SBATCH --nodes=1-1
#SBATCH --ntasks=1
#SBATCH --time=${GAUSSIAN_JOB_TIME}


cd \$SLURM_SUBMIT_DIR


export GAUSS_SCRDIR=/scratch/\$USER
export g09root=/local/software/gaussian
source \$g09root/g09/bsd/g09.profile

g09 ${MOLECULE}.com ${MOLECULE}.log
	"
	GAUSSIAN_INPUT_FILE="%mem=4GB
%nprocshared=${GAUSSIAN_CPUS}
# ${GAUSSIAN_FUNCTIONAL}/${GAUSSIAN_BASIS_SET} opt No Symm EmpiricalDispersion=GD3BJ

Geometry optimisation calculation for ${MOLECULE}

${GAUSSIAN_CHARGE} ${GAUSSIAN_MULTIPLICITY}"
	DMA_ANALYSIS_SCRIPT="#!/bin/bash

source ~/.bashrc
conda activate cspy
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

cspy-dma ${MOLECULE}.xyz
	"
	CSP_JOB_SCRIPT="#!/bin/bash
#SBATCH --job-name=${MOLECULE}
#SBATCH --partition=batch
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=128
#SBATCH --time=${CSP_JOB_TIME}


#Source and environmental variables setup
source ~/.bashrc
conda activate cspy
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

#Calculation specific setup
MOL_NAME=${MOLECULE}
XYZ=\${MOL_NAME}.xyz
MULTS=\${MOL_NAME}.dma
CHARGES=\${MOL_NAME}_rank0.dma
AXIS=\${MOL_NAME}.mols

mpiexec csp \${XYZ} -c \${CHARGES} -m \${MULTS} -a \${AXIS} -g fine10
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
	mkdir ${FOLDER_1} ${FOLDER_2} ${FOLDER_3} ${FOLDER_4} ${FOLDER_5} ${FOLDER_6}

	# create contents of FOLDER_1
	echo "${GAUSSIAN_INPUT_FILE}" > ${FOLDER_1}/${MOLECULE}.com
	tail -n +3 ../${MOLECULE_XYZ} >> ${FOLDER_1}/${MOLECULE}.com
	echo "" >> ${FOLDER_1}/${MOLECULE}.com # adding two empty lines at end for format requirements
	echo "" >> ${FOLDER_1}/${MOLECULE}.com
	echo "${GAUSSIAN_JOB_SCRIPT}" > ${FOLDER_1}/job_submit.sh

	# create contents of FOLDER_2
	cd ${FOLDER_2}
	ln -s ../${FOLDER_1}/${MOLECULE}.xyz ${MOLECULE}.xyz
	echo "${DMA_ANALYSIS_SCRIPT}" > dma_analysis.sh
	cd ..

	# create contents of FOLDER_3
	cd ${FOLDER_3}
	ln -s ../${FOLDER_1}/${MOLECULE}.xyz ${MOLECULE}.xyz
	ln -s ../${FOLDER_2}/${MOLECULE}.dma ${MOLECULE}.dma
	ln -s ../${FOLDER_2}/${MOLECULE}_rank0.dma ${MOLECULE}_rank0.dma
	ln -s ../${FOLDER_2}/${MOLECULE}.mols ${MOLECULE}.mols
	echo "${CSP_JOB_SCRIPT}" > job_submit.sh
	cd ..
}