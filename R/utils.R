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
#' @param studies a list of scienceverse study objects
#' @param name_path a vector of names that get you to the table
#'
#' @return a merged table
#' @export
#'
#' @examples
#' grobid_dir <- system.file("grobid", package = "papercheck")
#' studies <- read_grobid(grobid_dir)
#' references <- concat_tables(studies, c("refs", "references"))
concat_tables <- function(studies, name_path) {
  if ("scivrs_study" %in% class(studies)) {
    # single scienceverse object
    studies <- list(studies)
  }

  table_list <- studies
  for (name in name_path) {
    table_list <- lapply(table_list, `[[`, name)
  }
  for (i in seq_along(studies)) {
    table_list[[i]]$file <- studies[[i]]$info$filename
  }

  merged_table <- do.call(rbind, table_list)
  rownames(merged_table) <- NULL

  merged_table
}
