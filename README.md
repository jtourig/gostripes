# gostripesR v0.4.1

Processing and quality control of STRIPE-seq FASTQ files.

## Preparing Required Software

### Singularity Container

It is recommended to use the provided singularity container with all required software installed.
Singularity packages containers similar to docker containers that allow for compatibility and reproducibility of software and workflows.
You must first install the [singularity software](https://sylabs.io/guides/3.5/user-guide/quick_start.html#quick-installation-steps) 
onto your machine to use containers.

Once you have singularity installed and are ready to run the workflow, download the gostripes container to access all required software:

- Navigate to your desired directory or create a new one, then follow the instructions below

- Pull the singularity container from Sylabs Cloud:
```
singularity pull library://jtourig/gostripes/gostripes_v0.4.1.sif
```
... for the most recent stable build

or

```
singularity pull library://jtourig/gostripes/gostripes_v0.4.x_dev.sif
```
... for the latest (probably buggy) developmental version


## Quickstart

You have a couple options to run gostripes.  The latest verstion (0.4) lets you run the whole automated workflow  from the host command line.  You can also enter the container to run the workflow command, or use the container's R installation to load the gostripe library run your own R script.

### Run the whole workflow from the host as a single command

**Generic command**:
```
singularity run -eCB your/genome/dir -H "$PWD" path/to/gostripes_v0.4.1.sif \
	--sample-sheet path/to/samples_file.txt --cpus 4 \
	--assembly your/genome/dir/assembly.fa --annotation your/genome/dir/annotation.gtf \
	--rRNA your/genome/dir/rRNA_contaminants.fa --output-dir your/gostripes/output/dir
```
... `-B` binds host directories so you can access them from inside the container. `-H $PWD` does this to your current directory and makes it the container $HOME.  Be mindful where you give this or any other container access on your system.  See `singularity run --help` for more info on how to use these and other handy options.


**Try it on the included example data** (assumes container is in your current working directory):
```
singularity run -eCH "$PWD" gostripes_v0.4.1.sif --cpus 2 \
	--sample-sheet /opt/conda/envs/gostripes/lib/R/library/gostripes/extdata/gostripes_example_sample_sheet.txt \
	--rRNA /opt/conda/envs/gostripes/lib/R/library/gostripes/extdata/Sc_rRNA.fasta \
	--assembly /opt/conda/envs/gostripes/lib/R/library/gostripes/extdata/Saccharomyces_cerevisiae.R64-1-1.dna_sm.toplevel.fa \
	--annotation /opt/conda/envs/gostripes/lib/R/library/gostripes/extdata/Saccharomyces_cerevisiae.R64-1-1.99.gtf \
	--output-dir ./gostripes-example-output/
```

See `singularity help gostripes_v0.4.1.sif` or `singularity run gostripes_v0.4.1.sif --help` for more usage info.


### From container R

Start R within the container to gain access to the installed software:
```
singularity exec -eCH "$PWD" gostripes_0.4.1.sif R
```
...runs R inside a container with your current directory bound as the container's home directory.

You can also give the container access to other directories on the host machine:
```
singularity exec -eCB your/genome/dir/etc:/opt/genome/  -H "$PWD" gostripes_0.3.0.sif R
```
...binds the container's /opt/genome/ path to a host directory possibly containing genome files

See `singularity exec --help` for more info

You are now ready to use gostripes!

**Running the included example from R**:

```
library("gostripes")
library("magrittr")

## Load example data from package.

R1_fastq <- system.file("extdata", "S288C_R1.fastq", package = "gostripes")
R2_fastq <- system.file("extdata", "S288C_R2.fastq", package = "gostripes")

rRNA <- system.file("extdata", "Sc_rRNA.fasta", package = "gostripes")

assembly <- system.file("extdata", "Saccharomyces_cerevisiae.R64-1-1.dna_sm.toplevel.fa", package = "gostripes")
annotation <- system.file("extdata", "Saccharomyces_cerevisiae.R64-1-1.99.gtf", package = "gostripes")


## Create example sample sheet.

sample_sheet <- tibble::tibble(
	"sample_name" = "stripeseq",
	"replicate_ID" = 1,
	"R1_read" = R1_fastq,
	"R2_read" = R2_fastq
)

## Running the workflow on the example data.

go_object <- gostripes(sample_sheet) %>%
	process_reads("./scratch/cleaned_fastq", rRNA, cores = 4) %>%
	fastq_quality("./scratch/fastqc_reports", cores = 4) %>%
	genome_index(assembly, annotation, "./scratch/genome_index", cores = 4) %>%
	align_reads("./scratch/aligned", cores = 4) %>%
	process_bams("./scratch/cleaned_bams", cores = 4) %>%
	count_features(annotation, cores = 4) %>%
	export_counts("./scratch/counts") %>%
	call_TSSs %>%
	export_TSSs("./scratch/TSSs") %>%
	call_TSRs(3, 25) %>%
	export_TSRs("./scratch/TSRs")
```

## Detailed Start

### Preparing Data

gostripes takes demultiplexed STRIPE-seq FASTQ files as input, in either paired- or single-end sequencing format.
For paired-end data it is important that the forward and reverse reads are in the same order in both files.

gostripes is also able to handle multiple samples at the same time using a sample sheet.
The sample sheet should have 4 labeled columns: `sample_name`, `replicate_ID`, `R1_read`, `R2_read`.  This header row must be included.
Each sample in a group of biological replicates should have the same replicate ID.
The R1 and R2 read fields should contain the full path to the FASTQ file including the file name.
If the samples were sequenced in single-end mode, you can leave the entries in 'R2_read' blank.

**For the workflow command**, a tab-separated file such as:
```
sample_name         replicate_ID        R1_read                          R2_read
your_sample1_name   0                   container/path/to/R1.fastq	 container/path/to/R2.fastq
...
```
...will suffice.  Recall that paths must be relative to what the container can see.

**In container R**:
```
library("gostripes")

R1_fastq <- system.file("extdata", "S288C_R1.fastq", package = "gostripes")
R2_fastq <- system.file("extdata", "S288C_R2.fastq", package = "gostripes")

sample_sheet <- tibble::tibble(
        "sample_name" = "stripeseq",
        "replicate_ID" = 1,
        "R1_read" = R1_fastq,
        "R2_read" = R2_fastq
)

go_object <- gostripes(sample_sheet)
```
### Quality Control of FASTQ Files

The first main step of STRIPE-seq analysis is the quality control and filtering of the FASTQ files.
First, R1 read structure is ensured by looking for 'NNNNNNNNTATAGGG' at the beginning of the R1 read,
which corresponds to the UMI:spacer:riboG of the template switching oligonucleotide.
Second, the UMI is stashed in the read name, allowing it to be used for duplicate removal in single-end data (and optionally paired-end).
Third, the remaining TATAGGG after UMI removal is trimmed.
Finally, contaminant reads such as rRNA are filtered out.
This requires a FASTA file containing the contaminant sequences to search against.

As further quality assurance, FastQC quality reports are generated both for the raw FASTQ files,
and the processed FASTQ files.

```
rRNA <- system.file("extdata", "Sc_rRNA.fasta", package = "gostripes")

go_object <- process_reads(go_object, "./scratch/cleaned_fastq", rRNA, cores = 4)
go_object <- fastq_quality(go_object, "./scratch/fastqc_reports", cores = 4)
```

### Aligning Reads to Genome

After quality control of the FASTQ files, the reads can then be mapped to the genome.
First, a STAR genome index is generated from the FASTA genome assembly and GTF genome annotation file.
Then, the FASTQ files are mapped to the genome using this index.

```
assembly <- system.file("extdata", "Saccharomyces_cerevisiae.R64-1-1.dna_sm.toplevel.fa", package = "gostripes")
annotation <- system.file("extdata", "Saccharomyces_cerevisiae.R64-1-1.99.gtf", package = "gostripes")

go_object <- genome_index(go_object, assembly, annotation, "./scratch/genome_index", cores = 4)
go_object <- align_reads(go_object, "./scratch/aligned", cores = 4)
```

### Quality Control of BAM Files

After aligning the reads to the genome, the result is a coordinate sorted and indexed BAM.
Two main quality control steps are taken with this BAM to ensure the most accurate measurement of true TSSs.
First, PCR duplicates reads are removed either using samtools (paired-end) or UMI-tools (single-end).
During this step, various other checks are made, such as ensuring properly paired reads and removing non-primary alignments.
Second, any TSS that has more than 3 soft-clipped bases adjacent to it is removed from the BAM.

```
go_object <- process_bams(go_object, "./scratch/cleaned_bams", cores = 4)
```

## NOTE: The functions below are now better implemented/maintained in the [TSRexploreR](https://github.com/zentnerlab/TSRexploreR) package and are not included in the automated workflow command above

### Feature Counting

After the quality contol steps, the resulting BAMs can be used for RNA-seq like feature counting.
Each read or read-pair will be assigned to the closest overlapping exon,
and a summary of overlapping read counts will be produced for each gene.
These feature counts can then optionally be exported as a table.

```
go_object <- count_features(go_object, annotation, cores = 4)
export_counts(go_object, "./scratch/counts")
```

### Rudimentary TSS and TSR Calling

The final BAMs are also ready for TSS and TSS cluster (TSR or cTSS) analysis.
There are many great software suites available for this, including
[TSRchitect](https://bioconductor.org/packages/release/bioc/html/TSRchitect.html),
[CAGEr](https://bioconductor.org/packages/release/bioc/html/CAGEr.html),
[ADAPT-CAGE](https://gitlab.com/dianalab/adapt-cage), and
[CAGEfightR](https://bioconductor.org/packages/release/bioc/html/CAGEfightR.html).
For convenience, gostripes includes some rudimentary functions for basic TSS and TSR calling.

Although 5' ends with 3 or less soft-clipped bases are retained in the bam quality control steps, those bases are not considered when calling TSSs.
For TSR calling, TSSs with less than the user defined threshold number of reads are first removed.
Surviving TSSs within the user defined number of bases (25 by default) are then clustered into a TSRs/cTSS.
The resulting TSSs and TSRs/cTSSs can be exported as BEDGRAPH and BED files respectively.

```
go_object <- call_TSSs(go_object)
export_TSSs(go_object, "./scratch/TSSs")

go_object <- call_TSRs(go_object, 3, 25)
export_TSRs(go_object, "./scratch/TSRs")
```

## Acknowledgments

The development of gostripes would not be possible without these great software packages.

* [FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/): FASTQ quality control.
* [TagDust 2](http://tagdust.sourceforge.net/): FASTQ read filtering.
* [STAR](https://github.com/alexdobin/STAR): Short read sequence aligner.
* [Samtools](http://www.htslib.org/): SAM/BAM file manipulation.
* [Picard](https://broadinstitute.github.io/picard/): Manipulation of SAM/BAM files.

A special shoutout to the [tidyverse](https://www.tidyverse.org/) for making data science in R easy.
Also, a sincere thank you to [Bioconductor](http://bioconductor.org/) and its varied contributors for hosting so many invaluable tools.
