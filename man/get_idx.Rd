% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/scienceverse.R
\name{get_idx}
\alias{get_idx}
\title{Get index from id}
\usage{
get_idx(study, id = NULL, section = "hypotheses")
}
\arguments{
\item{study}{A study list object with class scivrs_study}

\item{id}{The id for the section (index or character) if NULL, assigns to the last item in the list}

\item{section}{The section to search, c("hypotheses", "analyses", "data")}
}
\value{
A numeric index
}
\description{
Get the index from id for an item in the hypotheses, analyses, or data sections of a study object
}
\keyword{internal}
