% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read_grobid.R
\name{read_grobid}
\alias{read_grobid}
\title{Get paper from grobid XML file}
\usage{
read_grobid(filename)
}
\arguments{
\item{filename}{the path to the XML file, a vector of file paths, or the path to a directory containing XML files}
}
\value{
A paper object with class scivrs_paper, or a list of paper objects
}
\description{
You can create a grobid XML file from a paper PDF at https://huggingface.co/spaces/kermitt2/grobid.
}
\examples{
filename <- demoxml()
paper <- read_grobid(filename)
}
