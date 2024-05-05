#' Search the full text
#'
#' Search the full text of a study paper. Currently only works with study objects that have full text imported from grobid (e.g., using `study_from_xml()`).
#'
#' @param study a study object created by `study_from_xml` or a list of study objects
#' @param pattern the regex pattern to search for
#' @param section the section(s) to search in
#' @param return the kind of text to return, the full sentence, paragraph, or section that the text is in, or just the (regex) match
#' @param refs whether to include references
#' @param ignore.case whether to ignore case when text searching
#' @param ... additional arguments to pass to `grep()` and `regexpr()`
#'
#' @return a data frame of matching sentences
#' @export
#'
#' @examples
#' grobid_dir <- system.file("grobid", package="scienceverse")
#' filename <- file.path(grobid_dir, "eyecolor.pdf.tei.xml")
#' study <- study_from_xml(filename)
#' sig <- search_text(study, "significant", "results")
search_text <- function(study, pattern = ".*", section = NULL,
                             return = c("sentence", "paragraph", "section", "match"),
                             refs = FALSE, ignore.case = TRUE, ...) {
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
          search_text(x, pattern, section, return, refs, ignore.case, ...)
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
  section_filter <- seq_along(full_text$section_class)
  if (!is.null(section))
    section_filter <- full_text$section_class %in% section
  ref_filter <- TRUE
  if (!refs) ref_filter <- !((full_text$type == "ref") |>
                               sapply(isTRUE))
  ft <- full_text[section_filter & ref_filter, ]



  # get all rows with a match----
  match_rows <- tryCatch(
    grep(pattern, ft$text, ignore.case = ignore.case, ...),
    error = function(e) { stop(e) },
    warning = function(w) {}
  )
  ft_match <- ft[match_rows, ]

  # add back the other parts----

  if (return == "sentence") {
    ft_match_all <- dplyr::semi_join(ft, ft_match, by = c("section", "div", "p", "s"))
    groups <- c("section", "section_class", "header", "div", "p", "s", "file")
  } else if (return == "paragraph") {
    ft_match_all <- dplyr::semi_join(ft, ft_match, by = c("section", "div", "p"))
    groups <- c("section", "section_class", "header", "div", "p", "file")
  } else if (return == "section") {
    ft_match_all <- dplyr::semi_join(ft, ft_match, by = c("section", "div"))
    groups <- c("section", "section_class", "header", "file")
  } else if (return == "match") {
    ft_match_all <- ft_match
    matches <- regexpr(pattern, ft_match$text, ignore.case = ignore.case, ...)
    ft_match_all$text <- regmatches(ft_match$text, matches)
    groups <- c("section", "section_class", "header", "div", "p", "s", "tag", "file")
  }

  full_text_table <- dplyr::summarise(ft_match_all,
                                      text = paste(text, collapse = " "),
                                      .by = dplyr::all_of(groups))

  all_cols <- c("text", "type", "section", "section_class", "header", "div", "p", "s", "tag", "file")
  if (nrow(full_text_table) > 0) {
    full_text_table$text <- gsub("\\s+", " ", full_text_table$text)
    full_text_table$text <- gsub(" , ", ", ", full_text_table$text)
    missing_cols <- setdiff(all_cols, names(full_text_table))
    for (mc in missing_cols) {
      full_text_table[[mc]] <- NA
    }
    full_text_table <- full_text_table[, all_cols]
    full_text_table$type <- return
  } else {
    full_text_table <- data.frame(row.names = all_cols)
  }

  return(unique(full_text_table))
}
