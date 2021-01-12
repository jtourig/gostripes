#!/bin/env R
# testing and debugging scratch script for gostripes and gostripes environment / container
# source() this from inside container or environment R

library("gostripes")
library("magrittr")
library("devtools")

## run the workflow from the example sample sheet (made via excel tsv) and Bob's original functions
# load the sample sheet
# sample_sheet_path <- './gostripes/inst/extdata/gostripes_example_sample_sheet.txt'
# sample_sheet <- read.csv(sample_sheet_path, header = TRUE, sep = '\t')

# or, build the sample sheet if not running in container with static sample paths:
sample_sheet <- tibble::tibble(
	"sample_name" = "stripe_example",
	"replicate_ID" = 0,
	"R1_read" = system.file("extdata", "S288C_R1.fastq", package = "gostripes"),
	"R2_read" = system.file("extdata", "S288C_R2.fastq", package = "gostripes")
)

# locate the sample genome files
rRNA <- system.file("extdata", "Sc_rRNA.fasta", package = "gostripes")
assembly <- system.file("extdata", "Saccharomyces_cerevisiae.R64-1-1.dna_sm.toplevel.fa", package = "gostripes")
annotation <- system.file("extdata", "Saccharomyces_cerevisiae.R64-1-1.99.gtf", package = "gostripes")
index <- './Sc-R64-STAR-index/'  # this is too big to include in the repo
output_dir <- './gostripes-testing-output/'
cpus <- 4


## for reference, default workflow with original methods - works ok except there is no fastqc output
##   when running in non-container environment (perl bin/lib incompatibility with host)
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


# reload the modified local package via devtools::document() or devtools::load_all()
devtools::load_all('./gostripes/')

# init object with all attributes
go_object <- gostripes(sample_sheet = sample_sheet, cores = 4,
                       assembly = assembly, annotation = annotation, star_index = index,
                       rRNA = rRNA
)

# nix any existing example output before workflow
unlink(output_dir, recursive = TRUE)

# verify what we're working with
print(go_object)

# workflow derived from container run script for troubleshooting
go_object <- go_object %>%
    process_reads(paste0(output_dir, "/cleaned-fastqs/"), rRNA, cores = cpus) %>%
    fastq_quality(paste0(output_dir, "/fastqc-reports/"), cores = cpus) %>%
    genome_index(assembly, annotation, paste0(output_dir, "/genome-index/"), cores = cpus) %>%
    align_reads(paste0(output_dir, "/aligned-bams/"), cores = cpus) %>%
    process_bams(paste0(output_dir, "/cleaned-bams/"), cores = cpus)

message('\n    ** gostripes workflow complete **\n')
