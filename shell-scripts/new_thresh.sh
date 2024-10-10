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
	MOLECULE_XYZ=${2:?"${HELP_STR}"}
	MOLECULE=${MOLECULE_XYZ%.xyz}
	EXTENSION=${MOLECULE_XYZ##*.}

	if [ ${EXTENSION} != "xyz" ]; then
		echo "ERROR: Extension of '${MOLECULE_XYZ}' is not .xyz"
		return 1
	fi

    # default and take settings from env vars
	GAUSSIAN_CPUS=${GAUSSIAN_CPUS:-"4"}
	GAUSSIAN_JOB_TIME=${GAUSSIAN_JOB_TIME:-"05:00:00"}
	GAUSSIAN_FUNCTIONAL=${GAUSSIAN_FUNCTIONAL:-"B3LYP"}
	GAUSSIAN_BASIS_SET=${GAUSSIAN_BSIS_SET:-"6-311G**"}
	GAUSSIAN_CHARGE=${GAUSSIAN_CHARGE:-"0"}
	GAUSSIAN_MULTIPLICITY=${GAUSSIAN_MULTIPLICITY:-"1"}
	MC_JOB_TIME=${MC_JOB_TIME:-"24:00:00"}

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
	cp ../${MOLECULE_XYZ} ${FOLDER_1}/${MOLECULE}_original.xyz
	echo "${GAUSSIAN_INPUT_FILE}" > ${FOLDER_1}/${MOLECULE}.com
	echo "${EXTRACT_OPT_XYZ}" > ${FOLDER_1}/opt_xyz_extractor_gaussian.py
	tail -n +3 ../${MOLECULE_XYZ} >> ${FOLDER_1}/${MOLECULE}.com
	echo "" >> ${FOLDER_1}/${MOLECULE}.com # adding two empty lines at end for format requirements
	echo "" >> ${FOLDER_1}/${MOLECULE}.com
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