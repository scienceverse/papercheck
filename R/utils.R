#' Less scary green messages
#'
#' @param ... message components (see \code{\link[base]{message}})
#' @param domain (see \code{\link[base]{message}})
#' @param appendLF append new line? (see \code{\link[base]{message}})
#'
#' @return TRUE
#' @keywords internal
#'
message <- function (..., domain = NULL, appendLF = TRUE) {
  #if (is.null(knitr::opts_knit$get('rmarkdown.pandoc.to'))) {
  if (options("scienceverse.verbose")[[1]]) {
    if (interactive()) {
      # not in knitr environment
      base::message("\033[32m", ..., "\033[39m",
                    domain = domain, appendLF = appendLF)
    } else {
      base::message(..., domain = domain, appendLF = appendLF)
    }
  }
}


#' Check if site is available
#'
#' @param url A URL to check
#' @param msg A message that contains %s to replace in the site name
#' @param error Throw an error if the site is down; otherwise return a logical
#'
#' @return logical
#' @keywords internal
site_down <- function(url, msg = "The website %s is not available", error = TRUE) {
  site <- url |>
    gsub("https?\\://", "", x = _) |>
    gsub("/.*", "", x = _)

  down <- tryCatch(httr::http_error(site),
                          error = function(e) { return(TRUE) })

  if (down & error) {
    sprintf(msg, site) |> stop(call. = FALSE)
  }

  return(down)
}



#' Concatenate tables
#'
#' Concatenate tables across a list of scienceverse objects
#'
#' @param papers a list of scienceverse study objects
#' @param name_path a vector of names that get you to the table
#'
#' @return a merged table
#' @export
#'
#' @examples
#' grobid_dir <- system.file("grobid", package = "papercheck")
#' papers <- read_grobid(grobid_dir)
#' references <- concat_tables(papers, c("refs", "references"))
concat_tables <- function(papers, name_path) {
  if ("scivrs_paper" %in% class(papers)) {
    # single scienceverse object
    papers <- list(papers)
  }

  table_list <- papers
  for (name in name_path) {
    table_list <- lapply(table_list, `[[`, name)
  }
  for (i in seq_along(papers)) {
    x <- table_list[[i]]
    if (is.data.frame(x) && nrow(x) > 0) {
      table_list[[i]]$id <- papers[[i]]$info$filename
    }
  }

  merged_table <- do.call(rbind, table_list)
  rownames(merged_table) <- NULL

  merged_table
}


#' Print Paper Object
#'
#' @param x The scivrs_paper list
#' @param ... Additional parameters for print
#'
#' @export
#' @keywords internal
#'
print.scivrs_paper <- function(x, ...) {
  ft <- sprintf("%d rows", nrow(x$full_text))

  ref <- sprintf("%d rows", nrow(x$references))

  cite <- sprintf("%d rows", nrow(x$citations))

  underline <- rep("-", nchar(x$name)) |> paste(collapse="")
  txt <- sprintf("%s\n%s\n\n* Full Text: %s\n* References: %s\n* Citations: %s\n\n%s", x$name, underline, ft, ref, cite)

  cat(txt)
}


#' Get demo files
#'
#' @param type whether to return the path to the demo directory, or demo XML or PDF files
#'
#' @return vector of paths
#' @export
#'
#' @examples
#' demofile()
#' demofile("xml")
#' demofile("pdf")
demofile <- function(type = c("dir", "xml", "pdf")) {
  grobid_dir <- system.file("grobid", package="papercheck")

  type <- match.arg(type)

  if (type == "dir") return(grobid_dir)
  if (type == "xml") {
    pattern <- "\\.xml$"
  } else if (type == "pdf") {
    pattern <- "\\.pdf$"
  }

  files <- list.files(grobid_dir, pattern, full.names = TRUE)
  return(files)
}
