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

## a good command, with index
# singularity run -ecH "$PWD" "$gostripes_container" \
# 	--sample-sheet "$samples" --cpus "$num_procs" \
# 	--STAR-index "$yeast_index" \
# 	--rRNA "$yeast_rRNA" --output-dir "$output_dir"

## good command, with genome and annotation
# singularity run -ecH "$PWD" "$gostripes_container" \
# 	--sample-sheet "$samples" --cpus "$num_procs" \
# 	--assembly "$yeast_assembly" --annotation "$yeast_annotation" \
# 	--rRNA "$yeast_rRNA" --output-dir "$output_dir"


## BAD commands:

# with genome + assembly + STAR index
singularity run -ecH "$PWD" "$gostripes_container" \
	--sample-sheet some_file.txt --cpus "$num_procs" --rRNA "$yeast_rRNA" \
	--assembly "$yeast_assembly" --annotation "$yeast_annotation" --STAR-index "$yeast_index" \
	--output-dir "$output_dir"

# # bad command with only assembly
# ./gostripes_parse_args.R --sample-sheet some_file.txt \
# 	--assembly genome.fa --rRNA /opt/genome/some_contam.fa \
# 	--cpus 6 --output-dir some/dir

# # bad command with only annotation
# ./gostripes_parse_args.R --sample-sheet some_file.txt \
# 	--annotation some_annot.gtf --rRNA /opt/genome/some_contam.fa \
# 	--cpus 6 --output-dir some/dir

# # bad command with assembly and index
# ./gostripes_parse_args.R --sample-sheet some_file.txt \
# 	--assembly genome.fa --rRNA /opt/genome/some_contam.fa \
# 	--cpus 6 --output-dir some/dir --STAR-index star.index

# # bad command with annotation and index
# ./gostripes_parse_args.R --sample-sheet some_file.txt \
# 	--annotation some_annot.gtf --rRNA /opt/genome/some_contam.fa \
# 	--cpus 6 --output-dir some/dir --STAR-index star.index

# a well-formed command with genome and annotation, without the optional options
# ./gostripes_parse_args.R --sample-sheet some_file.txt \
# 	--assembly genome.fa --annotation some_annot.gtf --rRNA /opt/genome/some_contam.fa

exit
