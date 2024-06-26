#' Check Stats
#'
#' @param text the search table (or list of scienceverse paper objects)
#' @param ... arguments to pass to statcheck()
#'
#' @return a table of statistics
#' @export
#'
#' @examples
#' filename <- demoxml()
#' papers <- read_grobid(filename)
#' stats(papers)
stats <- function(text, ...) {
  if (!is.data.frame(text)) {
    text <- search_text(text)
  }

  n <- nrow(text)
  if (n == 0) return(data.frame())

  # set up progress bar ----
  if (getOption("scienceverse.verbose")) {
    pb <- progress::progress_bar$new(
      total = n, clear = FALSE,
      format = "Checking stats [:bar] :current/:total :elapsedfull"
    )
    pb$tick(0)
    Sys.sleep(0.2)
    pb$tick(0)
  }

  subchecks <- lapply(seq_along(text$text), \(i) {
    subtext <- text$text[[i]]

    # statcheck uses cat() to output messages :(
    sink_output <- utils::capture.output(
      sc <- statcheck::statcheck(subtext, messages = FALSE, ...)
    )
    if (getOption("scienceverse.verbose")) pb$tick()
    if (is.null(sc)) return(data.frame())
    sc$source <- i

    return(sc)
  })
  checks <- do.call(rbind, subchecks)

  if (nrow(checks) == 0) return(checks)

  text$source = seq_along(text$text)

  stat_table <- dplyr::left_join(checks, text, by = "source")
  rownames(stat_table) <- NULL

  stat_table[, 2:ncol(stat_table)]
}
