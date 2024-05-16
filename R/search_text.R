#' Search the full text
#'
#' Search the full text of a study. Currently only works with study objects that have full text imported from grobid (e.g., using `read_grobid()`).
#'
#' @param study a study object created by `read_grobid` or a list of study objects
#' @param pattern the regex pattern to search for
#' @param section the section(s) to search in
#' @param return the kind of text to return, the full sentence, paragraph, or section that the text is in, or just the (regex) match
#' @param ignore.case whether to ignore case when text searching
#' @param ... additional arguments to pass to `grep()` and `regexpr()`, such as `fixed = TRUE`
#'
#' @return a data frame of matches
#' @export
#'
#' @examples
#' filename <- system.file("grobid", "eyecolor.xml", package="papercheck")
#' study <- read_grobid(filename)
#' search_text(study, "p\\s*(=|<)\\s*[0-9\\.]+", return = "match")
search_text <- function(study, pattern = ".*", section = NULL,
                             return = c("sentence", "paragraph", "section", "match"),
                             ignore.case = TRUE, ...) {
  return <- match.arg(return)

  # test pattern for errors(TODO: deal with warnings + errors)
  test_pattern <- tryCatch(
    grep(pattern, "test", ignore.case = ignore.case, ...),
    error = function(e) {
      stop("Check the pattern argument:\n", e$message, call. = FALSE)
    })

  if (is.data.frame(study)) {
    full_text <- study
  } else if ("scivrs_study" %in% class(study)) {
    full_text <- study$full_text
  } else if (is.list(study)) {
    contains_scivrs <- lapply(study, class) |>
      sapply(\(x) "scivrs_study" %in% x)
    # handle list of scivrs objects ----
    if (all(contains_scivrs)) {
      matches <- lapply(study, \(x) {
        tryCatch({
          search_text(x, pattern, section, return, ignore.case, ...)
        }, error = function(e) {
          warning(e)
        })
      })
      matches_agg <- do.call(rbind, matches)
      return(matches_agg)
    } else {
      stop("The study argument doesn't seem to be a scivrs_study object or a list of study objects")
    }
  } else {
    stop("The study argument doesn't seem to be a scivrs_study object or a list of study objects")
  }

  # filter full text----
  section_filter <- seq_along(full_text$section)
  if (!is.null(section))
    section_filter <- full_text$section %in% section
  ft <- full_text[section_filter, ]

  # get all rows with a match----
  match_rows <- tryCatch(
    grep(pattern, ft$text, ignore.case = ignore.case, ...),
    error = function(e) { stop(e) },
    warning = function(w) {}
  )
  ft_match <- ft[match_rows, ]

  # add back the other parts----

  if (return == "sentence") {
    ft_match_all <- ft_match
  } else if (return == "paragraph") {
    # add in other sentences from matched paragraphs
    groups <- c("section", "header", "div", "p", "file")

    ft_match_all <- dplyr::semi_join(ft, ft_match, by = groups) |>
      dplyr::summarise(text = paste(text, collapse = " "),
                       .by = dplyr::all_of(groups))

  } else if (return == "section") {
    # add in other sentences from matched sections

    groups <- c("section", "header", "div", "file")
    ft_match_all <- dplyr::semi_join(ft, ft_match, by = groups) |>
      dplyr::summarise(text = paste(text, collapse = " "),
                       .by = dplyr::all_of(groups))

  } else if (return == "match") {
    ft_match_all <- ft_match
    matches <- regexpr(pattern, ft_match$text, ignore.case = ignore.case, ...)
    ft_match_all$text <- regmatches(ft_match$text, matches)
  }

  all_cols <- names(ft)

  if (nrow(ft_match_all) > 0) {
    ft_match_all$text <- gsub("\\s+", " ", ft_match_all$text)
    ft_match_all$text <- gsub(" , ", ", ", ft_match_all$text)
    missing_cols <- setdiff(all_cols, names(ft_match_all))
    for (mc in missing_cols) {
      ft_match_all[[mc]] <- NA
    }
    ft_match_all <- ft_match_all[, all_cols]
  } else {
    ft_match_all <- data.frame(row.names = all_cols)
  }

  rownames(ft_match_all) <- NULL

  return(unique(ft_match_all))
}
