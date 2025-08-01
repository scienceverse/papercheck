#' Set default options
#'
#' @param libname libname
#' @param pkgname pkgname
#'
#' @returns NULL
#' @export
#' @keywords internal
.onLoad <- function(libname, pkgname) {
  op <- options()
  op.pkg <- list(
    papercheck.verbose = TRUE,
    papercheck.llm_max_calls = 30L,
    papercheck.llm.model = "llama-3.3-70b-versatile",
    papercheck.osf.delay = 0,
    papercheck.osf.api = "https://api.osf.io/v2",
    papercheck.osf.api.calls = 0
  )
  # only set if not already set
  toset <- !(names(op.pkg) %in% names(op))
  if(any(toset)) options(op.pkg[toset])

  invisible()
}

#' On Attach
#'
#' @param libname libname
#' @param pkgname pkgname
#'
#' @returns startup message
#' @export
#' @keywords internal
.onAttach <- function(libname, pkgname) {
  stripe <- paste0(
    "\033[31m*****", # red
    "\033[33m*****", # yellow
    "\033[32m*****", # green
    "\033[34m*****", # blue
    #"\033[36m*****" # cyan
    "\033[35m*****\033[0m"  # magenta
  )

  stripe <- paste0("\033[32m",
                   rep("*", 43) |> paste(collapse = ""),
                   "\033[0m")

  if (!interactive()) {
    stripe <- rep("*", 43) |> paste(collapse = "")
  }
  paste(
    "\n",
    stripe,
    "\u2705 Welcome to PaperCheck",
    "For support and examples visit:",
    "https://scienceverse.github.io/papercheck/",
    "",
    "\u26A0\uFE0F This is alpha software; please check any",
    "results. False positives and negatives will",
    "occur at unknown rates.",
    stripe,
    sep = "\n"
  ) |> packageStartupMessage()
}

## quiets concerns of R CMD check re: the .'s that appear in pipelines
if(getRversion() >= "2.15.1")  utils::globalVariables(c("."))
