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
#' sig <- search_full_text(study, "significant", "results")
search_full_text <- function(study, pattern = ".*", section = NULL,
                             return = c("sentence", "paragraph", "section", "match"),
                             refs = FALSE, ignore.case = TRUE, ...) {
  return <- match.arg(return)

  # test pattern for errors(TODO: deal with warnings + errors)
  test_pattern <- tryCatch(
    grep(pattern, "test", ignore.case = ignore.case, ...),
    error = function(e) {
      stop("Check the pattern argument:\n", e$message, call. = FALSE)
    })

  # handle list of scivrs objects ----
  if (!"scivrs_study" %in% class(study)) {
    contains_scivrs <- lapply(study, class) |>
      sapply(\(x) "scivrs_study" %in% x)
    if (all(contains_scivrs)) {
      matches <- lapply(study, \(x) {
        tryCatch({
          search_full_text(x, pattern, section, return, refs, ignore.case, ...)
        }, error = function(e) {
          warning(e)
        })
      })
      matches_agg <- do.call(rbind, matches)
      return(matches_agg)
    } else {
      stop("The study argument doesn't seem to be a scivrs_study object or a list of study objects")
    }
  }

  # filter full text----
  section_filter <- seq_along(study$full_text$section_class)
  if (!is.null(section))
    section_filter <- study$full_text$section_class %in% section
  ref_filter <- TRUE
  if (!refs) ref_filter <- study$full_text$type != "ref"
  ft <- study$full_text[section_filter & ref_filter, ]

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
    groups <- c("section_class", "section", "div", "p", "s")
  } else if (return == "paragraph") {
    ft_match_all <- dplyr::semi_join(ft, ft_match, by = c("section", "div", "p"))
    groups <- c("section_class", "section", "div", "p")
  } else if (return == "section") {
    ft_match_all <- dplyr::semi_join(ft, ft_match, by = c("section", "div"))
    groups <- c("section_class", "section")
  } else if (return == "match") {
    ft_match_all <- ft_match
    matches <- regexpr(pattern, ft_match$text, ignore.case = ignore.case, ...)
    ft_match_all$text <- regmatches(ft_match$text, matches)
    groups <- c("tag", "section_class", "section", "div", "p", "s")
  }

  full_text_table <- dplyr::summarise(ft_match_all,
                                      text = paste(text, collapse = " "),
                                      .by = dplyr::all_of(groups))

  if (nrow(full_text_table) > 0) {
    full_text_table$text <- gsub("\\s+", " ", full_text_table$text)
    full_text_table$text <- gsub(" , ", ", ", full_text_table$text)
    full_text_table$file <- study$name
  }

  return(unique(full_text_table))
}
