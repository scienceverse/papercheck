% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pdf2grobid.R
\name{pdf2grobid}
\alias{pdf2grobid}
\title{Convert a PDF to Grobid XML}
\usage{
pdf2grobid(
  filename,
  save_path = ".",
  grobid_url = "https://kermitt2-grobid.hf.space"
)
}
\arguments{
\item{filename}{path to the PDF}

\item{save_path}{directory or file path to save to; set to NULL to save to a temp file}

\item{grobid_url}{the URL to the grobid server}
}
\value{
XML object
}
\description{
This function uses a public grobid server maintained by Patrice Lopez. You can set up your own local grobid server following instructions from \url{https://grobid.readthedocs.io/} and set the argument \code{grobid_url} to its path (probably \url{http://localhost:8070})
}
