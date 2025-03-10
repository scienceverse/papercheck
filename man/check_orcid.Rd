% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/scienceverse.R
\name{check_orcid}
\alias{check_orcid}
\title{Check validity of ORCiD}
\usage{
check_orcid(orcid)
}
\arguments{
\item{orcid}{a 16-character ORCiD in bare or URL format}
}
\value{
a formatted 16-character ORCiD or FALSE
}
\description{
Check validity of ORCiD
}
\examples{
check_orcid("0000-0002-7523-5539")
check_orcid("0000-0002-0247-239X")
check_orcid("https://orcid.org/0000-0002-0247-239X")
check_orcid("0000-0002-0247-2394") # incorrect, return FALSE
}
