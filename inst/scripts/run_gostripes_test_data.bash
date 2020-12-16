#!/bin/bash
# a test command for gostripes.R script with included sample data
# run from container shell
# jtourig / zentlab 2020

set -eu

### VARS ###
samples='/opt/conda/envs/gostripes/lib/R/library/gostripes/extdata/gostripes_example_sample_sheet.txt'
yeast_assembly='/opt/conda/envs/gostripes/lib/R/library/gostripes/extdata/Saccharomyces_cerevisiae.R64-1-1.dna_sm.toplevel.fa'
yeast_annotation='/opt/conda/envs/gostripes/lib/R/library/gostripes/extdata/Saccharomyces_cerevisiae.R64-1-1.99.gtf'
yeast_rRNA='/opt/conda/envs/gostripes/lib/R/library/gostripes/extdata/Sc_rRNA.fasta'
num_procs=4
output_dir='./gostripes-example-output'

### CMD ###
gostripes.R --sample-sheet "$samples" --cpus "$num_procs" \
	--assembly "$yeast_assembly" --annotation "$yeast_annotation" \
	--rRNA "$yeast_rRNA" --output-dir "$output_dir"`

exit

