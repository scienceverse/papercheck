% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/github.R
\name{github_info}
\alias{github_info}
\title{Get GitHub Repo Info}
\usage{
github_info(repo, recursive = FALSE)
}
\arguments{
\item{repo}{The URL of the repository (in the format "username/repo" or "https://github.com/username/repo")}

\item{recursive}{whether to search the files recursively}
}
\value{
a list of information about the repo
}
\description{
Get GitHub Repo Info
}
\examples{
\donttest{
  github_info("scienceverse/papercheck")
}
}
