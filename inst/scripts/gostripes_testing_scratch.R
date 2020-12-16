#!/bin/env R
# testing and debugging scratch script for gostripes and gostripes environment / container

library("gostripes")
library("magrittr")
library("devtools")

## run the workflow from the example sample sheet (made via excel tsv) and Bob's original functions
# load the sample sheet
#sample_sheet_path <- '/opt/conda/envs/gostripes/lib/R/library/gostripes/extdata/gostripes_example_sample_sheet.txt'
sample_sheet_path <- './gostripes/inst/extdata/gostripes_example_sample_sheet.txt'
sample_sheet <- read.csv(sample_sheet_path, header = TRUE, sep = '\t')

# locate the sample genome files
rRNA <- system.file("extdata", "Sc_rRNA.fasta", package = "gostripes")
assembly <- system.file("extdata", "Saccharomyces_cerevisiae.R64-1-1.dna_sm.toplevel.fa", package = "gostripes")
annotation <- system.file("extdata", "Saccharomyces_cerevisiae.R64-1-1.99.gtf", package = "gostripes")


# # default workflow with original methods - works ok except there is no fastqc output in scratch/fastqc_reports
# go_object <- gostripes(sample_sheet)
# go_object %>%
#     process_reads("./scratch/cleaned_fastq", rRNA, cores = 4) %>%
#     fastq_quality("./scratch/fastqc_reports", cores = 4) %>%
#     genome_index(assembly, annotation, "./scratch/genome_index", cores = 4) %>%
#     align_reads("./scratch/aligned", cores = 4) %>%
#     process_bams("./scratch/cleaned_bams", cores = 4) %>%
#     count_features(annotation, cores = 4) %>%
#     export_counts("./scratch/counts") %>%
#     call_TSSs %>%
#     export_TSSs("./scratch/TSSs") %>%
#     call_TSRs(3, 25) %>%
#     export_TSRs("./scratch/TSRs")


## try to load the go object with new params from JT's fork
# load JT's WIP gostripes version
#devtools::document() # or
#devtools::load_all()

go_object <- gostripes(sample_sheet = sample_sheet, cores = 4,
                       assembly = assembly, annotation = annotation,
                       index = index, rRNA = rRNA, output_dir = './'

go_object <- gostripes(sample_sheet)
