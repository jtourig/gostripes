#' gostripes class
#'
#' Class container appropriate slots for gostripes
#'
#' @slot sample_sheet Sample sheet
#' @slot settings Settings used throughout gostripes
#' @slot TSSs List of GRanges containing transcription start sites
#' @slot TSRs List of GRagnes containing transcription start regions (TSRs) or clustered transcription start sites (cTSSs)
#' @slot feature_counts data.frame containing the RNA-seq like feature counting of reads
#'
#' @rdname gostripes

setClass(
	"gostripes",
	representation(
		sample_sheet = "data.frame",
		settings = "list",
		TSSs = "list",
		TSRs = "list",
		feature_counts = "data.frame"
	),
	prototype(
		sample_sheet = data.frame(),
		settings = list(),
		TSSs = list(),
		TSRs = list(),
		feature_counts = data.frame()
	)
)

#' gostripes constructor function
#'
#' Create gostripes object
#'
#' @import methods
#' @import tibble
#' @importFrom dplyr mutate pull
#' @importFrom magrittr %>%
#'
#' @param sample_sheet Sample sheet data.frame containing 'sample_name', 'replicate_ID", 'R1_read', and 'R2_read'
#' @param cores Number of CPU cores/threads available to use
#' @param assembly Path to genome assembly
#' @param annotation Path to genome annotation
#' @param rRNA Path to rRNA.fasta to filter with
#' @param star_index Path to STAR index
#'
#' @return gostripes object containing the sample sheet and available cores
#'
#' @examples
#' R1_fastq <- system.file("extdata", "S288C_R1.fastq", package = "gostripes")
#' R2_fastq <- system.file("extdata", "S288C_R2.fastq", package = "gostripes")
#'
#' sample_sheet <- tibble::tibble(
#'   "sample_name" = "stripeseq", "replicate_ID" = 1,
#'   "R1_read" = R1_fastq, "R2_read" = R2_fastq
#' )
#'
#' go_object <- gostripes(sample_sheet)
#'
#' @rdname gostripes
#'
#' @export

gostripes <- function(sample_sheet, cores = 2, rRNA,
                      assembly = NA, annotation = NA, star_index = NA
             ) {

	## Check for proper inputs to gostripes function.

	# Check whether sample_sheet is in proper format.
	if (!is(sample_sheet, "data.frame")) stop("The sample sheet must be a data frame or tibble.")
	if (nrow(sample_sheet) == 0) stop("The sample sheet contains no entries.")
	if (!all(c("sample_name", "replicate_ID", "R1_read", "R2_read") %in% colnames(sample_sheet))) {
		stop("The sample sheet must have columns 'sample_name', 'replicate_ID', 'R1_read', and 'R2_read'.")
	}

	# Check other arguments.
	if (!is(cores, "numeric")) stop("Cores must be a positive integer")
	if (!cores %% 1 == 0 | cores < 1) stop("Cores must be a positive integer")
    #NOTE further parameter checking currently takes place in downstream methods;
    #     consider moving it here

	## Check whether each sample is paired on unpaired.
	sample_sheet <- sample_sheet %>%
		mutate(seq_mode = ifelse(
			is.na(R2_read) | R2_read %in% c("", " "),
			"unpaired", "paired"
		))

	## Print out some information on the sample sheet.
	message(
		"\n## gostripesR v0.4.1\n##\n",
		"## Sample sheet contains ", nrow(sample_sheet), " sample(s)\n",
		sprintf("## - %s\n", pull(sample_sheet, "sample_name")),
		"##\n",
		"## Available cores set to ", cores, "\n",
		"## Assembly = ", assembly, "\n",
		"## STAR Index = ", star_index, "\n",
		"## Annotation = ", annotation, "\n",
		"## rRNA = ", rRNA, "\n",
		"\n"
	)

	## Create gostripes object.
	go_obj <- new(
		"gostripes",
		sample_sheet = sample_sheet,
		settings = list("cores" = cores, "rRNA" = rRNA, "assembly" = assembly, 
		                "annotation" = annotation, "star_index" = star_index
		)
	)

	return(go_obj)
}
