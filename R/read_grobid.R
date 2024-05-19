#' Get study from grobid XML file
#'
#' You can create a grobid XML file from a paper PDF at https://huggingface.co/spaces/kermitt2/grobid.
#'
#' @param filename the path to the XML file, a vector of file paths, or the path to a directory containing XML files
#'
#' @return A study object with class scivrs_stud, or. list of study objects
#' @export
#'
#' @examples
#' filename <- system.file("grobid", "eyecolor.xml", package="papercheck")
#' study <- read_grobid(filename)
#'
read_grobid <- function(filename) {
  # handle list of files or a directory----
  if (length(filename) > 1) {
    #message("Processing ", length(filename), " files...")
    # set up progress bar ----
    if (getOption("scienceverse.verbose")) {
      pb <- progress::progress_bar$new(
        total = length(filename), clear = FALSE,
        format = "Processing XMLs [:bar] :current/:total :elapsedfull"
      )
      pb$tick(0)
      Sys.sleep(0.2)
      pb$tick(0)
    }

    # get unique names
    dirs <- filename |>
      sapply(strsplit, split = "/")
    maxlen <- sapply(dirs, length) |> max()
    dir_df <- lapply(dirs, \(x) {
        x[1:maxlen]
      }) |>
      as.data.frame() |>
      t()
    distinct_vals <- apply(dir_df, 2, unique) |> lapply(length) > 1
    unique_names <- dir_df[ , distinct_vals, drop = FALSE] |>
      apply(1, paste0, collapse = "/")

    s <- lapply(filename, \(x) {
      #message("- ", basename(x))
      s1 <- read_grobid(x)
      if (getOption("scienceverse.verbose")) pb$tick()
      s1
    })
    #message("Complete!")
    names(s) <- unique_names
    for (un in unique_names) {
      s[[un]]$full_text$file <- un
    }
    return(s)
  } else if (file.exists(filename) & file.info(filename)$isdir) {
    xmls <- list.files(filename, "\\.xml",
                       full.names = TRUE,
                       recursive = TRUE)
    if (length(xmls) == 0) {
      stop("There are no xml files in the directory ", filename)
    }
    s <- read_grobid(xmls)
    return(s)
  }

  if (!file.exists(filename)) {
    stop("The file ", filename, " does not exist.")
  }

  xml_text <- filename |>
    readLines(warn = FALSE) |>
    paste(collapse = "\n") |>
    gsub("</s><s>", " ", x = _) |> # get rid of sentence tags
    gsub("</?s>", "", x = _) |> # get rid of sentence tags
    #gsub("</ref>", "[/ref]", x = _) |>
    #gsub("<ref ", "[ref ", x = _) |>
    # fixes a glitch that stopped xml from being read
    gsub(' xmlns="http://www.tei-c.org/ns/1.0"', "", x = _, fixed = TRUE)

  xml <- tryCatch(xml2::read_xml(xml_text), error = function(e) {
    stop("The file ", filename, " could not be read as XML")
  })

  if (xml2::xml_name(xml) != "TEI") {
    stop("This XML file does not parse as a valid Grobid TEI.")
  }

  # set up study object ----
  #xlist <- xml2::as_list(xml)
  if (requireNamespace("scienceverse", quietly = TRUE)) {
    s <- scienceverse::study()
  } else {
    s <- list()
    class(s) <- c("scivrs_study", "list")
  }

  # general info ----
  s$name <- basename(filename)
  s$info$filename <- basename(filename)
  s$info$title <- xml2::xml_find_first(xml, "//titleStmt //title") |>
    xml2::xml_text()

  # get authors ----
  if (requireNamespace("scienceverse", quietly = TRUE)) {

    authors <- xml2::xml_find_all(xml, "//sourceDesc //author[persName]")

    for (a in authors) {
      family <- xml2::xml_find_all(a, ".//surname") |> xml2::xml_text() |> paste(collapse = " ")
      given <- xml2::xml_find_all(a, ".//forename") |> xml2::xml_text() |> paste(collapse = " ")
      email <- xml2::xml_find_all(a, ".//email") |> xml2::xml_text() |> paste(collapse = ";")
      orcid <- xml2::xml_find_all(a, ".//idno[@type='ORCID']") |> xml2::xml_text()
      # if (is.null(orcid) & !is.null(family)) {
      #   orcid_lookup <- scienceverse::get_orcid(family, given)
      #   if (length(orcid_lookup) == 1) orcid <- orcid_lookup
      # }
      if (length(orcid) == 0) orcid = NULL

      s <- scienceverse::add_author(s, family, given, orcid, email = email)
    }
  }

  # process text----

  ## abstract ----
  abstract <- xml2::xml_find_all(xml, "//abstract //p") |>
    xml2::xml_text()
  s$info$description <- paste(abstract, collapse = "\n\n")

  if (length(abstract) > 0) {
    abst_table <- data.frame(
      header = "Abstract",
      text = abstract,
      div = 0,
      p = seq_along(abstract)
    )
  } else {
    abst_table <- data.frame()
  }

  ## body ----
  divs <- xml2::xml_find_all(xml, "//text //body //div")
  div_text <- lapply(seq_along(divs), \(i){
    div <- divs[[i]]
    header <- xml2::xml_find_first(div, ".//head") |> xml2::xml_text()
    if (is.na(header)) header <- sprintf("[div-%02d]", i)
    paragraphs <- xml2::xml_find_all(div, ".//p") |>
      xml2::xml_text()
    df <- data.frame(
      header = header,
      text = c(header, paragraphs),
      div = i,
      p = c(0, seq_along(paragraphs))
    )
  })

  text <- NULL # hack to stop cmdcheck warning :(
  body_table <- do.call(rbind, c(list(abst_table), div_text)) |>
    tidytext::unnest_sentences(text, text, to_lower = FALSE) |>
    dplyr::mutate(s = dplyr::row_number(), .by = c("div", "p"))

  # body_table <- by(body_table,
  #                  list(body_table$div, body_table$p),
  #                  \(x) { x$s = seq_along(x); x }) |>
  #   do.call(rbind, args = _)

  body_table$file <- basename(filename)
  rownames(body_table) <- NULL

  body_table <- full_text_sections(body_table)

  blank_divs <- grepl("\\[div-\\d+\\]", body_table$text)

  s$full_text <- body_table[!blank_divs, ]

  # TODO: figures ----
  divs <- xml2::xml_find_all(xml, "//figure")

  # keywords ----
  s$info$keywords <- xml2::xml_find_all(xml, "//keywords //term") |> xml2::xml_text()

  return(s)
}


#' Add section info to full text table
#'
#' @param ft full text table
#'
#' @return a data frame of the classified full text
#' @keywords internal
#'
full_text_sections <- function(ft) {
  # classify headers ----
  abstract <- grepl("abstract", ft$header, ignore.case = TRUE)
  intro <- grepl("intro", ft$header, ignore.case = TRUE)
  method <- grepl("method", ft$header, ignore.case = TRUE)
  results <- grepl("result", ft$header, ignore.case = TRUE)
  discussion <- grepl("discuss", ft$header, ignore.case = TRUE)
  ft$section <- NA
  ft$section[abstract] <- "abstract"
  ft$section[intro] <- "intro"
  ft$section[method] <- "method"
  ft$section[discussion] <- "discussion"
  ft$section[results] <- "results"

  # assume sections are the same class as previous if unclassified (after abstract)
  for (i in seq_along(ft$section)) {
    if (i > 1 &
        !abstract[i] &
        isFALSE(abstract[i-1]) &
        is.na(ft$section[i]) ) {
      ft$section[i] <- ft$section[i-1]
    }
  }

  # beginning sections after abstract with no header labelled intro
  non_blanks <- which(!is.na(ft$section) & ft$section != "abstract")
  if (length(non_blanks) > 0) {
    blank_start <- non_blanks[[1]] - 1
    blanks <- rep(c(TRUE, FALSE), c(blank_start, length(ft$section) - blank_start))
    blanks[abstract] <- FALSE
    ft$section[blanks] <- "intro"
  }

  colorder <- c("text", "section", "header", "div", "p", "s", "file")

  return(ft[, colorder])
}


