#!/bin/bash
# conda environment installation script for gostripes by Bob Policisastro @rpolicastro
# this script excerpted and revised from the evironment recipe in the Singularity definition
# use this if you prefer not to run gostripes in the container
# or, if you need to do further development in a mutable environment
# jtourig / zentlab 2021

set -euo pipefail


# print lines to stderr
se() { >&2 printf -- '    %s\n' "$@" }


# make sure conda is installed and available
type conda > /dev/null \
	|| { se "conda not found - make sure it's installed and in your PATH"; exit 1; }

# Update conda
conda update -n base -y -c defaults conda \
	|| { se "error updating conda base - check it's so named and writable on your system"; exit 1; }

# Install software available via conda environment.
conda create -n gostripes-dev -y -c conda-forge -c bioconda \
	star samtools fastqc picard umi_tools \
	r-tidyverse r-devtools \
	bioconductor-biostrings bioconductor-rsubread \
	bioconductor-genomicalignments bioconductor-shortread \
	bioconductor-genomicranges bioconductor-rtracklayer

# Update conda environment
conda update -n gostripes-dev -y -c conda-forge -c bioconda --all

# Clean installation files for conda.
conda clean -y --all


## Install TagDust2.
# get the gostripes env installation path
env_path=$(conda info --envs | awk '/^gostripes-dev/ {print $3}')
cd "${env_path}/opt/"
wget --content-disposition https://sourceforge.net/projects/tagdust/files/tagdust-2.33.tar.gz/download \
tar -xzf tagdust-2.33.tar.gz

cd tagdust-2.33/
./configure --prefix="${env_path}/bin/"
make
make install


## Install gostripes
# enter the environment to use its R
source activate gostripes-dev

# Install gostripes from github.
#R --slave -e 'Sys.setenv(TAR="/bin/tar");devtools::install_github("rpolicastro/gostripes",ref="dev")'

# temporarily build from JT's fork:
R --slave -e 'Sys.setenv(TAR="/bin/tar");devtools::install_github("jtourig/gostripes",ref="master")'

source deactivate

se 'gostripes-dev conda environment installed' 'you can enter and leave it with:' \
	'  source activate gostripes-dev' '  source deactivate' ''

exit