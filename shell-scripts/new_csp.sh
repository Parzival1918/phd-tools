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
	EXTENSION=${MOLECULE_XYZ##*.}

	if [ ${EXTENSION} != "xyz" ]; then
		echo "ERROR: Extension of '${MOLECULE_XYZ}' is not .xyz"
		return 1
	fi

	# check if csp_settings.txt file exists and source it
	if [ -f "csp_settings.txt" ]; then
		echo "Settings file detected. Sourcing... "
		set -v
		source csp_settings.txt
		set +v
		echo "Settings file sourced."
	fi

	# default and take settings from env vars
	GAUSSIAN_CPUS=${GAUSSIAN_CPUS:-"4"}
	GAUSSIAN_JOB_TIME=${GAUSSIAN_JOB_TIME:-"05:00:00"}
	GAUSSIAN_FUNCTIONAL=${GAUSSIAN_FUNCTIONAL:-"B3LYP"}
	GAUSSIAN_BASIS_SET=${GAUSSIAN_BSIS_SET:-"6-311G**"}
	GAUSSIAN_CHARGE=${GAUSSIAN_CHARGE:-"0"}
	GAUSSIAN_MULTIPLICITY=${GAUSSIAN_MULTIPLICITY:-"1"}
	CSP_JOB_TIME=${CSP_JOB_TIME:-"24:00:00"}
	REOPTIMIZE_JOB_TIME=${REOPTIMIZE_JOB_TIME:-"05:00:00"}

	# replace vars to string contents of files
	GAUSSIAN_JOB_SCRIPT="#!/bin/bash
#SBATCH --job-name=${MOLECULE}_gauss
#SBATCH --mincpus=${GAUSSIAN_CPUS}
#SBATCH --nodes=1-1
#SBATCH --ntasks=1
#SBATCH --time=${GAUSSIAN_JOB_TIME}


cd \$SLURM_SUBMIT_DIR


export GAUSS_SCRDIR=/scratch/\$USER
export g09root=/iridisfs/i6software/gaussian
source \$g09root/g09/bsd/g09.profile

g09 ${MOLECULE}.com ${MOLECULE}.log

# extract optimized coords from log file
source ~/.bashrc
conda activate cspy

python opt_xyz_extractor_gaussian.py PYRENE01.log PYRENE01.xyz
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

Geometry optimisation calculation for ${MOLECULE}

${GAUSSIAN_CHARGE} ${GAUSSIAN_MULTIPLICITY}"
	DMA_ANALYSIS_SCRIPT="#!/bin/bash

source ~/.bashrc
conda activate cspy
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

ln -fs ../${FOLDER_1}/*.xyz ./

cspy-dma *.xyz
	"
	CSP_JOB_SCRIPT="#!/bin/bash
#SBATCH --job-name=${MOLECULE}_csp
#SBATCH --partition=batch
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=128
#SBATCH --time=${CSP_JOB_TIME}


#Source and environmental variables setup
source ~/.bashrc
conda activate cspy
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

ln -fs ../${FOLDER_1}/*.xyz ./
ln -fs ../${FOLDER_2}/*.dma ./
ln -fs ../${FOLDER_2}/*.mols ./

shopt -s extglob
mpiexec csp *.xyz -c *_rank0.dma -m !(*_rank0).dma -a *.mols -g fine10
shopt -u extglob	
	"
	REOPTIMIZE_JOB_SCRIPT="#!/bin/bash
#SBATCH --job-name=${MOLECULE}_reop
#SBATCH --partition=batch
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=128
#SBATCH --time=${REOPTIMIZE_JOB_TIME}


#Source and environmental variables setup
source ~/.bashrc
conda activate cspy
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

ln -fs ../${FOLDER_1}/*.xyz ./
ln -fs ../${FOLDER_2}/*.dma ./
ln -fs ../${FOLDER_2}/*.mols ./

shopt -s extglob
mpiexec cspy-reoptimize output.db -x *.xyz -c *_rank0.dma -m !(*_rank0).dma -a *.mols -p fit --cutoff 30
shopt -u extglob	
	"
	REMOVE_DUPLICATES_SCRIPT="#!/bin/bash

source ~/.bashrc
conda activate cspy
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

ln -fs ../${FOLDER_3}/*-*.db ./

echo \"Running clsutering command...\"
cspy-db cluster *-*.db > cspy_cluster_screen.txt && echo \"Success\" || echo \"Exited with $?, check cspy_cluster_screen.txt\" 
	"
	PLOT_CSP_LANDSCAPE_SCRIPT="from cspy.db.datastore import CspDataStore
import sys
import matplotlib.pyplot as plt


db = CspDataStore(sys.argv[1])
data = [item for item in db.query(\"select energy, density, spacegroup from crystal where id like '%-3'\").fetchall()]

sgs = {}
for y, x, sg in data:
    if sg in sgs:
        sgs[sg].append([x, y])
    else:
        sgs[sg] = [[x,y]]

fig, ax = plt.subplots()
c=0
for sg in sgs:
    x=[a[0] for a in sgs[sg]]
    y=[a[1] for a in sgs[sg]]
    ax.scatter(
        x=x,
        y=[i - min(y) for i in y],
        label=sg,
        s=10,
        edgecolor='k',
    )
    c += 1

plt.xlabel('Density (g cm$^{-3}$)')
plt.ylabel('Relative Energy (kJ mol$^{-1}$)')
plt.legend()
plt.tight_layout()
plt.savefig('Landscape.png', dpi=600)

print(\"Landscape saved to Landscape.png\")
	" # inspired from https://mol-cspy.readthedocs.io/en/latest/bb_wikipages/Scripts%20for%20CSPy.html

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
	cp ../${MOLECULE_XYZ} ${FOLDER_1}/${MOLECULE}.xyz.original
	echo "${GAUSSIAN_INPUT_FILE}" > ${FOLDER_1}/${MOLECULE}.com
	tail -n +3 ../${MOLECULE_XYZ} >> ${FOLDER_1}/${MOLECULE}.com
	echo "" >> ${FOLDER_1}/${MOLECULE}.com # adding two empty lines at end for format requirements
	echo "" >> ${FOLDER_1}/${MOLECULE}.com
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
	echo "${CSP_JOB_SCRIPT}" > job_submit.sh
	echo "# ${FOLDER_3}

This is the CSP step in which crystals are created with a QR
algorithm and are minimised (minimisation steps defined in 
cspy.toml file). Usually constrain the search of space groups
to top 10 most common from CSD (use CLI opt: -g fine10).
	" > README.md 
	cd ..

	# create contents of FOLDER_4
	cd ${FOLDER_4}
	echo "${REMOVE_DUPLICATES_SCRIPT}" > remove_duplicates.sh
	chmod +x remove_duplicates.sh
	echo "# ${FOLDER_4}

This is the step after all candidate structures have been
generated. Now we compare all of them to make sure that there
are no duplicates and create another database containing the 
unique ones (named output.db by default).
	" > README.md 
	cd ..

	# create contents of FOLDER_5
	cd ${FOLDER_5}
	ln -s ../${FOLDER_4}/output.db ./
	echo "${PLOT_CSP_LANDSCAPE_SCRIPT}" > plot_csp_landscape.py
	echo "# ${FOLDER_5}

Analyse the structures in the database in multiple ways:

- \`plot_csp_landscape.py [DATABASE]\` Creates a Landscape.png 
file of the Relative Energy vs Density of the structures.
	" > README.md 
	cd ..

	# create contents of FOLDER_6
	cd ${FOLDER_6}
	ln -s ../${FOLDER_4}/output.db ./
	echo "${REOPTIMIZE_JOB_SCRIPT}" > job_submit.sh
	ln -s ../${FOLDER_5}/plot_csp_landscape.py ./
	echo "# ${FOLDER_6}

Reoptimise any promising low energy structures using more
accurate energy methods.
	" > README.md 
	cd ..

	# return to initial folder
	cd ..

	echo "Created the project in '${PROJ_FOLDER}'" 
}