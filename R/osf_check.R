#' Check for OSF links
#'
#' @param text the text table
#'
#' @return a table of OSF links, their openness, and other table info
#' @export
#'
osf_check <- function(text) {
  url_regex <- "\\b((?:doi:)?(?:https?://)?(?:(?:www\\.)?(?:[\\da-z\\.-]+)\\.(?:[a-z]{2,6})|(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)|(?:(?:[0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:(?:(?::[0-9a-fA-F]{1,4}){1,6})|:(?:(?::[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(?::[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(?:ffff(?::0{1,4}){0,1}:){0,1}(?:(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])|(?:[0-9a-fA-F]{1,4}:){1,4}:(?:(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])))(?::[0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])?(?:/[\\w\\.-]*)*/?)\\b"

  # get OSF links
  found_urls <- search_text(text, url_regex, return = "match", perl = TRUE)
  found_osf <- search_text(found_urls, "osf\\.io")
  unique_urls <- unique(found_osf["text"]) # check https://

  if (nrow(unique_urls) == 0) {
    message("No OSF URLs found")
    return(data.frame())
  }

  # set up progress bar ----
  if (getOption("scienceverse.verbose")) {
    pb <- progress::progress_bar$new(
      total = nrow(unique_urls), clear = FALSE,
      format = "Processing URLs [:bar] :current/:total :elapsedfull"
    )
    pb$tick(0)
    Sys.sleep(0.2)
    pb$tick(0)
  }

  # Check for closed OSF links
  unique_urls$status <- sapply(unique_urls$text, \(url) {
    resp <- httr::GET(url)
    txt <- httr::content(resp, "text")

    if (grepl("Sign in with your OSF account to continue", txt)) {
      status <- "closed"
    } else if (grepl("Page not found", txt)) {
      status <- "missing"
    } else {
      status <- "open"
    }

    if (getOption("scienceverse.verbose")) pb$tick()

    return(status)
  })

  dplyr::left_join(found_osf, unique_urls, by = "text")
}
