% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read10xCounts.R
\name{read10xCounts}
\alias{read10xCounts}
\title{Load data from a 10X Genomics experiment}
\usage{
read10xCounts(
  samples,
  sample.names = names(samples),
  col.names = FALSE,
  row.names = c("id", "symbol"),
  type = c("auto", "sparse", "HDF5", "prefix"),
  delayed = FALSE,
  version = c("auto", "2", "3"),
  genome = NULL,
  compressed = NULL,
  intersect.genes = FALSE,
  BPPARAM = SerialParam()
)
}
\arguments{
\item{samples}{A character vector containing one or more directory names, each corresponding to a 10X sample.
Each directory should contain a matrix file, a gene/feature annotation file, and a barcode annotation file.

Alternatively, each string may contain a path to a HDF5 file in the sparse matrix format generated by 10X.
These can be mixed with directory names when \code{type="auto"}.

Alternatively, each string may contain a prefix of names for the three-file system described above,
where the rest of the name of each file follows the standard 10X output.}

\item{sample.names}{A character vector of length equal to \code{samples}, containing the sample names to store in the column metadata of the output object.
If \code{NULL}, the file paths in \code{samples} are used directly.}

\item{col.names}{A logical scalar indicating whether the columns of the output object should be named with the cell barcodes.}

\item{row.names}{String specifying whether to use Ensembl IDs ("ID") or gene symbols ("Symbol") as row names. If using symbols, the Ensembl ID will be appended to disambiguate in case the same symbol corresponds to multiple Ensembl IDs.}

\item{type}{String specifying the type of 10X format to read data from.}

\item{delayed}{Logical scalar indicating whether sparse matrices should be wrapped in \linkS4class{DelayedArray}s before combining.
Only relevant for multiple \code{samples}.}

\item{version}{String specifying the version of the 10X format to read data from.}

\item{genome}{String specifying the genome if \code{type="HDF5"} and \code{version='2'}.}

\item{compressed}{Logical scalar indicating whether the text files are compressed for \code{type="sparse"} or \code{"prefix"}.}

\item{intersect.genes}{Logical scalar indicating whether to take the intersection of common genes across all samples.
If \code{FALSE}, differences in gene information across samples will cause an error to be raised.}

\item{BPPARAM}{A \linkS4class{BiocParallelParam} object specifying how loading should be parallelized for multiple \code{samples}.}
}
\value{
A \linkS4class{SingleCellExperiment} object containing count data for each gene (row) and cell (column) across all \code{samples}.
\itemize{
\item Row metadata will contain the fields \code{"ID"} and \code{"Symbol"}.
The former is the gene identifier (usually Ensembl), while the latter is the gene name.
If \code{version="3"}, it will also contain the \code{"Type"} field specifying the type of feature (e.g., gene or antibody).
\item Column metadata will contain the fields \code{"Sample"} and \code{"Barcode"}.
The former contains the name of the sample (or if not supplied, the path in \code{samples}) from which each column was obtained.
The latter contains to the cell barcode sequence and GEM group for each cell library. 
\item Rows are named with the gene identifier.
Columns are named with the cell barcode in certain settings, see Details.
\item The assays will contain a single \code{"counts"} matrix, containing UMI counts for each gene in each cell.
Note that the matrix representation will depend on the format of the \code{samples}, see Details.
\item The metadata contains a \code{"Samples"} field, containing the input \code{samples} character vector.
}
}
\description{
Creates a \linkS4class{SingleCellExperiment} from the CellRanger output directories for 10X Genomics data.
}
\details{
This function has a long and storied past.
It was originally developed as the \code{read10xResults} function in \pkg{scater}, inspired by the \code{Read10X} function from the \pkg{Seurat} package.
It was then migrated to this package in an effort to consolidate some 10X-related functionality across various packages.

If \code{type="auto"}, the format of the input file is automatically detected for each \code{samples} based on whether it ends with \code{".h5"}.
If so, \code{type} is set to \code{"HDF5"}; otherwise it is set to \code{"sparse"}.
\itemize{
\item If \code{type="sparse"}, count data are loaded as a \linkS4class{dgCMatrix} object.
This is a conventional column-sparse compressed matrix format produced by the CellRanger pipeline,
consisting of a (possibly Gzipped) MatrixMarket text file (\code{"matrix.mtx"})
with additional tab-delimited files for barcodes (\code{"barcodes.tsv"})
and gene annotation (\code{"features.tsv"} for version 3 or \code{"genes.tsv"} for version 2).
\item If \code{type="prefix"}, count data are also loaded as a \linkS4class{dgCMatrix} object.
This assumes the same three-file structure for each sample as described for \code{type="sparse"},
but each sample is defined here by a prefix in the file names rather than by being a separate directory.
For example, if the \code{samples} entry is \code{"xyx_"},
the files are expected to be \code{"xyz_matrix.mtx"}, \code{"xyz_barcodes.tsv"}, etc.
\item If \code{type="HDF5"}, count data are assumed to follow the 10X sparse HDF5 format for large data sets.
It is loaded as a \linkS4class{TENxMatrix} object, which is a stub object that refers back to the file in \code{samples}.
Users may need to set \code{genome} if it cannot be automatically determined when \code{version="2"}.
}

When \code{type="sparse"} or \code{"prefix"} and \code{compressed=NULL},
the function will automatically search for both the unzipped and Gzipped versions of the files.
This assumes that the compressed files have an additional \code{".gz"} suffix.
We can restrict to only compressed or uncompressed files by setting \code{compressed=TRUE} or \code{FALSE}, respectively.

CellRanger 3.0 introduced a major change in the format of the output files for both \code{type}s.
If \code{version="auto"}, the version of the format is automatically detected from the supplied paths.
For \code{type="sparse"}, this is based on whether there is a \code{"features.tsv.gz"} file in the directory.
For \code{type="HDF5"}, this is based on whether there is a top-level \code{"matrix"} group with a \code{"matrix/features"} subgroup in the file.

Matrices are combined by column if multiple \code{samples} were specified.
This will throw an error if the gene information is not consistent across \code{samples}.
For \code{type="sparse"} or \code{"prefix"}, users can set \code{delayed=TRUE} to save memory during the combining process.
This also avoids integer overflow for very large datasets.

If \code{col.names=TRUE} and \code{length(sample)==1}, each column is named by the cell barcode.
For multiple samples, the index of each sample in \code{samples} is concatenated to the cell barcode to form the column name.
This avoids problems with multiple instances of the same cell barcodes in different samples.

Note that user-level manipulation of sparse matrices requires loading of the \pkg{Matrix} package.
Otherwise, calculation of \code{rowSums}, \code{colSums}, etc. will result in errors.
}
\examples{
# Mocking up some 10X genomics output.
example(write10xCounts)

# Reading it in.
sce10x <- read10xCounts(tmpdir)

# Column names are dropped with multiple 'samples'.
sce10x2 <- read10xCounts(c(tmpdir, tmpdir))

}
\references{
Zheng GX, Terry JM, Belgrader P, and others (2017).
Massively parallel digital transcriptional profiling of single cells. 
\emph{Nat Commun} 8:14049.

10X Genomics (2017).
Gene-Barcode Matrices.
\url{https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/2.2/output/matrices}

10X Genomics (2018).
Feature-Barcode Matrices.
\url{https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/output/matrices}

10X Genomics (2018).
HDF5 Gene-Barcode Matrix Format.
\url{https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/2.2/advanced/h5_matrices}

10X Genomics (2018).
HDF5 Feature Barcode Matrix Format.
\url{https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/advanced/h5_matrices}
}
\seealso{
\code{\link{splitAltExps}}, to split alternative feature sets (e.g., antibody tags) into their own Experiments.

\code{\link{write10xCounts}}, to create 10X-formatted file(s) from a count matrix.
}
\author{
Davis McCarthy, with modifications from Aaron Lun
}
