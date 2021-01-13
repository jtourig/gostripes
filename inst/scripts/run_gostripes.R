#!/usr/bin/env Rscript
# a generic gostripesR entry/wrapper script
# gostripes by Bob Policastro @rpolicastro
# this script by @jtourig / zentlab 2020

library("gostripes")
library("magrittr")


### FUNCTIONS ###

print_usage <- function() {
    cat("
        usage:  singularity run [singularity opts] [gostripes opts (see below)]
                or
                run_gostripes.R [gostripes opts] (if within container shell)
        
        options:
        -h | --help         (prints this message)
        --sample-sheet      path/to/sample_sheet                            (required)
        --assembly          path/to/genome_assembly                         (required WITH annotation file OR use --STAR-index)
        --annotation        path/to/assembly_annotation                     (required WITH assembly OR use --STAR-index)
        --STAR-index        path/to/STAR-index                              (required if NOT using --assembly and --annotations)
                            use a pre-built index instead of building from scratch
        --rRNA              fasta file defining your contaminants to filter (required)
        --cpus              integer number of cpu cores/threads to use      (optional, defaults to 2)
                            or, environment variable defining value
                            (can also set via SINGULARITYENV_[ENV_VAR_NAME]=[value or ${YOUR_VAR_NAME}] singularity [cmd] ... )
        --output-dir       path/to/output/directory                         (optional, defaults to ./gostripes-output/)
        
        ** gostripes option paths reflect their naming as mounted INSIDE the container               **
        ** see `singularity run --help' for more details on how to use `-B' to mount your host paths **

        Examples:

          Running the container as a host command:

          singularity run -ecB your/genome/dir:/opt/genome/ -H \"$PWD\" gostripes.sif \
            --sample_sheet ./your_sample_sheet.tsv --rRNA /opt/genome/Hs_rRNA.fa \
            --STAR-index /opt/genome/your-STAR-index-dir/ --cpus 4 \
            --output-dir ./gostripes-output/
        

          From inside gostripes singularity container shell:

          run_gostripes.R --sample_sheet ./your_sample_sheet.tsv --assembly /opt/genome/hg38.fa.masked  \
            --annotation /opt/genome/hg38.ncbiRefSeq.gtf --rRNA /opt/genome/Hs_rRNA.fa \
            --cpus 4 --output-dir ./gostripes-output/

    
        NOTE that currently, if you provide --assembly and --annotation, the STAR index build uses default options
          If you need to customize your index build, do that separately first and provide it via --STAR-index
    "
    )
    q()
}

# parse args without added dependencies
parse_args <- function(args){
    opts <- list(cpus = 2, output_dir = './gostripes-output/') # set defaults
    i <- 1
    while(i <= length(args)) {
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
                opts$star_index <- args[[i+1]]
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
    message('...assembly and annotation are set')
    if(!is.null(opts$star_index)) {
        message('......a STAR index is also set')
        stop("You must specify a genome assembly + annotation, OR just a STAR index")
    }
    #init gostripes object with genome and assembly
    go_object <- gostripes(sample_sheet = read.csv(opts$sample_sheet, header = TRUE, sep = '\t'),
                           cores = opts$cpus, rRNA = opts$rRNA,
                           assembly = opts$assembly, annotation = opts$annotation
    )
} else if(is.null(opts$assembly) && is.null(opts$annotation)) {
    message('...no assembly or annotation assigned, using STAR index')
    if(!is.null(opts$star_index)) {
        message('......index is assigned')
        #init gostripes object with STAR index
        go_object <- gostripes(sample_sheet = read.csv(opts$sample_sheet, header = TRUE, sep = '\t'),
                               cores = opts$cpus, rRNA = opts$rRNA,
                               star_index = opts$star_index
        )
    } else stop('no assembly, annotation or index set! see gostripes.R --help for usage')
} else {
    message('...missing an assembly or annotation - both are required!')
    if(!is.null(opts$star_index)) message('......a STAR index is also set!')
    stop("You must specify a genome assembly + annotation, OR just a STAR index")
}

# run workflow given options
go_object <- go_object %>%
    process_reads(paste0(opts$output_dir, "/cleaned-fastqs/"), opts$rRNA, cores = opts$cpus) %>%
    fastq_quality(paste0(opts$output_dir, "/fastqc-reports/"), cores = opts$cpus) %>%
    genome_index(opts$assembly, opts$annotation, paste0(opts$output_dir, "/genome-index/"), cores = opts$cpu) %>%
    align_reads(paste0(opts$output_dir, "/aligned-bams/"), cores = opts$cpus) %>%
    process_bams(paste0(opts$output_dir, "/cleaned-bams/"), cores = opts$cpus)

message("\n  gostripes run complete!!\n\n")

## for reference, remaining steps which are redundant with TSRexploreR and better featured/maintained there:
#     count_features(annotation, cores = 4) %>%
#     export_counts("./scratch/counts") %>%
#     call_TSSs %>%
#     export_TSSs("./scratch/TSSs") %>%
#     call_TSRs(3, 25) %>%
#     export_TSRs("./scratch/TSRs")
