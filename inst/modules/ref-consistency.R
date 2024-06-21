if (nrow(paper$references) == 0 & nrow(paper$citations) == 0) {
  table <- data.frame()
  traffic_light <- "na"
} else {
  missing_cites <- dplyr::anti_join(paper$references, paper$citations, by = "bib_id")
  if (nrow(missing_cites)) missing_cites$missing <- "citation"
  missing_refs <- dplyr::anti_join(paper$citations, paper$references, by = "bib_id")
  if (nrow(missing_refs)) missing_refs$missing <- "reference"
  names(missing_refs) <- names(missing_refs) |> sub("text", "ref", x = _)

  table <- dplyr::bind_rows(missing_cites, missing_refs)

  if (nrow(table) == 0) {
    traffic_light <- "green"
  } else {
    traffic_light <- "red"
  }
}

# return
list(
  table = table,
  traffic_light = traffic_light
)
