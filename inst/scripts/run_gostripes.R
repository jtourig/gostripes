#!/usr/bin/env Rscript
# a generic gostripesR entry/wrapper script
# gostripes by Bob Policastro @rpolicastro
# this script by @jtourig / zentlab 2020

library("gostripes")
library("magrittr")

### FUNCTIONS ###
print_usage <- function() {
    cat("
        usage:  gostripes.R [options] 
        
        options:
        -h | --help         (prints this message)
        --sample-sheet      path/to/sample_sheet                            (required)
        --assembly          path/to/genome/assembly                         (required WITH annotation file OR use --STAR-index)
        --annotation        path/to/assembly/annotation                     (required WITH assembly OR use --STAR-index)
        --STAR-index        path/to/STAR/index                              (required if NOT using --assembly and --annotations)
                            use a pre-built index instead of building from scratch
        --rRNA              fasta file defining your contaminants to filter (required)
        --cpus              integer number of cpu cores/threads to use      (optional, defaults to 2)
                            or, name of environment variable defining value
                            (must set via SINGULARITYENV_[ENV_VAR_NAME]=[value or ${YOUR_VAR_NAME}] singularity [cmd] ... )
        --output-dir       path/to/output/directory                         (optional, defaults to ./)
        
        Example (from inside gostripes singularity container):
        gostripes.R --sample_sheet ./sample_sheet.tsv --assembly /opt/genome/hg38.fa.masked  \
            --annotation /opt/genome/hg38.ncbiRefSeq.gtf --rRNA /opt/genome/Hs_rRNA.fa \
            --cpus 4 --output_dir ./gostripes_output/
        
    "
    )
    q()
}

# parse args without added dependencies
parse_args <- function(args){
    opts <- list(cpus = 2, output_dir = './') # init options and set defaults
    i <- 1
    while(i <= length(args)) {
        print(args[[i]])
        switch(
            args[[i]],
            '--sample-sheet' = { 
                opts$sample_sheet = args[[i+1]] 
                i <- i + 2
            },
            '--assembly' = {
                opts$assembly <- args[[i+1]]
                i <- i + 2
            },
            '--annotation' = {
                opts$annotation <- args[[i+1]]
                i <- i + 2
            },
            '--STAR-index' = {
                opts$STAR_index <- args[[i+1]]
                i <- i + 2
            },
            '--rRNA' = {
                opts$rRNA <- args[[i+1]]
                i <- i + 2
            },
            '--cpus' = {
                opts$cpus <- suppressWarnings(as.integer(args[[i+1]]))
                # if --cpus not an integer, try to import from env var
                if(is.na(opts$cpus)) {
                    opts$cpus <- Sys.getenv(args[[i+1]])
                    if(opts$cpus == '') stop(paste('# CPUs environment variable', args[[i+1]], 'is not set'))
                }
                i <- i + 2
            },
            '--output-dir' = {
                opts$output_dir <- args[[i+1]]
                i <- i + 2
            },
            stop(paste('Argument not recognized::', args[[i]], '\nrun with -h or --help for usage', "\nExiting..."))
        )
    }
    return(opts)
}


### MAIN ###
# fetch and parse command line arguments, give user help
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0 || '-h' %in% args || '--help' %in% args) print_usage()
opts <- parse_args(args)

# check the genome + assembly OR index settings, and initialize gostripes object
if(!is.null(opts$assembly) && !is.null(opts$annotation)){
    print('assembly and annotation are set')
    if(!is.null(opts$STAR_index)) {
        print('oops, a STAR index is also set')
        stop("You must specify a genome assembly + annotation, OR just a STAR index", '\nExiting...')
    }
    #init gostripes object with genome and assembly
    go_object <- gostripes(sample_sheet = read.csv(opts$sample_sheet, header = TRUE, sep = '\t'),
                           cores = opts$cpus, rRNA = opts$rRNA,
                           assembly = opts$assembly, annotation = opts$annotation,
                           output_dir = opts$output_dir
    )
} else if(is.null(opts$assembly) && is.null(opts$annotation)) {
    print('no assembly or annotation assigned, using STAR index')
    if(!is.null(opts$STAR_index)) {
        print('index is assigned')
        #init gostripes object with STAR index
        go_object <- gostripes(sample_sheet = read.csv(opts$sample_sheet, header = TRUE, sep = '\t'),
                               cores = opts$cpus, rRNA = opts$rRNA,
                               index = opts$index, output_dir = opts$output_dir
        )
    } else stop('no assembly, annotation or index set! see gostripes.R --help for usage')
} else {
    message('missing an assembly or annotation - both are required!')
    if(!is.null(opts$STAR_index)) message('oops, a STAR index is also set')
    stop("You must specify a genome assembly + annotation, OR just a STAR index", '\nExiting...')
}


# run workflow given options

print(go_object)

go_object <- go_object %>%
    process_reads(paste(opts$output_dir, "/cleaned-fastqs/", sep=''), opts$rRNA, cores = opts$cpus) %>%
    fastq_quality(paste(opts$output_dir, "/fastqc-reports/", sep=''), cores = opts$cpus) %>%
    genome_index(opts$assembly, opts$annotation, paste(opts$output_dir, "/genome-index/", sep=''), cores = opts$cpu) %>%
    align_reads(paste(opts$output_dir, "/aligned-bams/", sep=''), cores = opts$cpus)

print(go_object)

message("\n  gostripes complete!!\n\n")

## steps which Bob says are redundant with TSRexploreR and better featured/maintained there
#     process_bams("./scratch/cleaned_bams", cores = 4) %>%
#     count_features(annotation, cores = 4) %>%
#     export_counts("./scratch/counts") %>%
#     call_TSSs %>%
#     export_TSSs("./scratch/TSSs") %>%
#     call_TSRs(3, 25) %>%
#     export_TSRs("./scratch/TSRs")
