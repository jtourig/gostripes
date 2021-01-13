#!/bin/bash
# test commands for gostripes container (via run_gostripes.R) with included sample data
# run the container as a command
# jtourig / zentlab 2020

set -eu

### VARS ###
gostripes_container='./gostripes_v0.4.1.sif'
samples='/opt/conda/envs/gostripes/lib/R/library/gostripes/extdata/gostripes_example_sample_sheet.txt'
yeast_assembly='/opt/conda/envs/gostripes/lib/R/library/gostripes/extdata/Saccharomyces_cerevisiae.R64-1-1.dna_sm.toplevel.fa'
yeast_annotation='/opt/conda/envs/gostripes/lib/R/library/gostripes/extdata/Saccharomyces_cerevisiae.R64-1-1.99.gtf'
yeast_rRNA='/opt/conda/envs/gostripes/lib/R/library/gostripes/extdata/Sc_rRNA.fasta'
yeast_index='./Sc-R64-STAR-index/'
num_procs=4
output_dir='./gostripes-container-commands-test-output/'

# clear out any existing test output
rm -r "$output_dir" || >&2 echo '  no output dir to delete'

# # a good command, with index
# singularity run -ecH "$PWD" "$gostripes_container" \
# 	--sample-sheet "$samples" --cpus "$num_procs" \
# 	--STAR-index "$yeast_index" \
# 	--rRNA "$yeast_rRNA" --output-dir "$output_dir"

sleep 2

# # good command, with genome and annotation
# singularity run -ecH "$PWD" "$gostripes_container" \
# 	--sample-sheet "$samples" --cpus "$num_procs" \
# 	--assembly "$yeast_assembly" --annotation "$yeast_annotation" \
# 	--rRNA "$yeast_rRNA" --output-dir "$output_dir"

# # good command with genome and annotation, without the optional options
# singularity run -ecH "$PWD" "$gostripes_container" \
# 	--sample-sheet "$samples" \
# 	--assembly "$yeast_assembly" --annotation "$yeast_annotation" \
# 	--rRNA "$yeast_rRNA"

sleep 2

## BAD commands:

# set +e

# # missing rRNA
# singularity run -ecH "$PWD" "$gostripes_container" \
# 	--sample-sheet "$samples" --cpus "$num_procs" \
# 	--assembly "$yeast_assembly" --annotation "$yeast_annotation" \
# 	--output-dir "$output_dir"

# sleep 2

# # with genome + assembly + STAR index
# singularity run -ecH "$PWD" "$gostripes_container" \
# 	--sample-sheet "$samples" --cpus "$num_procs" --rRNA "$yeast_rRNA" \
# 	--assembly "$yeast_assembly" --annotation "$yeast_annotation" --STAR-index "$yeast_index" \
# 	--output-dir "$output_dir"

# sleep 2

# # bad command with only assembly
# singularity run -ecH "$PWD" "$gostripes_container" \
# 	--sample-sheet "$samples" --cpus "$num_procs" --rRNA "$yeast_rRNA" \
# 	--assembly "$yeast_assembly" \
# 	--output-dir "$output_dir"

# sleep 2

# # bad command with only annotation
# singularity run -ecH "$PWD" "$gostripes_container" \
# 	--sample-sheet "$samples" --cpus "$num_procs" --rRNA "$yeast_rRNA" \
# 	--annotation "$yeast_annotation" \
# 	--output-dir "$output_dir"

# sleep 2

# # bad command with assembly and index
# singularity run -ecH "$PWD" "$gostripes_container" \
# 	--sample-sheet "$samples" --cpus "$num_procs" --rRNA "$yeast_rRNA" \
# 	--assembly "$yeast_assembly" --STAR-index "$yeast_index" \
# 	--output-dir "$output_dir"

# sleep 2

# # bad command with annotation and index
# singularity run -ecH "$PWD" "$gostripes_container" \
# 	--sample-sheet "$samples" --cpus "$num_procs" --rRNA "$yeast_rRNA" \
# 	--annotation "$yeast_annotation" --STAR-index "$yeast_index" \
# 	--output-dir "$output_dir"

exit
