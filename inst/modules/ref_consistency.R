#' Reference Consistency
#'
#' @description
#' Check if all references are cited and all citations are referenced
#'
#' @author Lisa DeBruine
#'
#' @import dplyr
#' @importFrom tidyr pivot_wider
#'
#' @param paper a paper object or paperlist object
#' @param ... further arguments (not used)
#'
#' @returns a list with table, traffic light, and report text
#'
#' @examples
#' module_run(psychsci, "ref_consistency")
ref_consistency <- function(paper) {
  # detailed table of results ----
  bibs <- concat_tables(paper, "bib")
  xrefs <- concat_tables(paper, "xrefs")

  missing_refs <- dplyr::anti_join(bibs, xrefs, by = c("id", "xref_id"))
  if (nrow(missing_refs)) missing_refs$missing <- "xrefs"
  missing_bib <- dplyr::anti_join(xrefs, bibs,  by = c("id", "xref_id"))
  if (nrow(missing_bib)) missing_bib$missing <- "bib"
  names(missing_bib) <- names(missing_bib) |> sub("text", "ref", x = _)

  table <- dplyr::bind_rows(missing_refs, missing_bib) |>
    dplyr::arrange(id, xref_id)

  # summary output for paperlists ----
  nbibs <- dplyr::count(bibs, id, name = "n_bib")
  nxrefs <- dplyr::count(xrefs, id, name = "n_xrefs")
  nmiss <- dplyr::count(table, id, missing) |>
    tidyr::pivot_wider(names_from = missing, names_prefix = "missing_",
                       values_from = n, values_fill = 0)
  summary_table <- info_table(paper, c()) |>
    dplyr::left_join(nbibs, by = "id") |>
    dplyr::left_join(nxrefs, by = "id") |>
    dplyr::left_join(nmiss, by = "id")

  # determine the traffic light ----
  tl <- dplyr::case_when(
    nrow(bibs) == 0 ~ "na",
    nrow(missing_bib) || nrow(missing_xrefs) ~ "red",
    .default = "green"
  )

  # report text for each possible traffic light ----
  report <- c(
    red = "There are cross-references that are not in the bibliography or bibliography entries not cross-referenced in the text",
    green = "All cross-references were in the bibliography and bibliography entries were cross-referenced in the text",
    na = "No bibliography entries were detected"
  )

  report_text <- "This module relies on Grobid correctly parsing the references. There may be some false positives."
  report_text <- paste(report_text, report[[tl]], sep = "\n\n")

  # return
  list(
    table = table,
    summary = summary_table,
    na_replace = 0,
    traffic_light = tl,
    report = report_text
  )
}
