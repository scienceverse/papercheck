#' Get paper from grobid XML file
#'
#' You can create a grobid XML file from a paper PDF at https://huggingface.co/spaces/kermitt2/grobid.
#'
#' @param filename the path to the XML file, a vector of file paths, or the path to a directory containing XML files
#'
#' @return A paper object with class scivrs_paper, or. list of paper objects
#' @export
#'
#' @examples
#' filename <- demofiles("xml")[1]
#' paper <- read_grobid(filename)
#'
read_grobid <- function(filename) {
  # handle list of files or a directory----
  if (length(filename) > 1) {
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

    p <- lapply(filename, \(x) {
      p1 <- read_grobid(x)
      if (getOption("scienceverse.verbose")) pb$tick()
      p1
    })

    names(p) <- unique_names
    for (un in unique_names) {
      p[[un]]$full_text$id <- un
    }
    return(p)
  } else if (dir.exists(filename)) {
    xmls <- list.files(filename, "\\.xml",
                       full.names = TRUE,
                       recursive = TRUE)
    if (length(xmls) == 0) {
      stop("There are no xml files in the directory ", filename)
    }
    p <- read_grobid(xmls)
    return(p)
  }

  if (!file.exists(filename)) {
    stop("The file ", filename, " does not exist.")
  }

  # read xml ----
  xml <- read_grobid_xml(filename)

  # set up paper object ----
  p <- paper()

  p$name <- basename(filename) |>
    gsub("\\.(xml|pdf)$", "", x = _, ignore.case = TRUE)
  p$info$filename <- filename
  p$info$title <- xml2::xml_find_first(xml, "//titleStmt //title") |>
    xml2::xml_text()
  p$info$description <-  xml2::xml_find_all(xml, "//abstract //p") |>
    xml2::xml_text() |>
    paste(collapse = "\n\n")

  # keywords ----
  p$info$keywords <- xml2::xml_find_all(xml, "//keywords //term") |>
    xml2::xml_text()

  # get authors ----
  p$authors <- get_authors(xml)

  # full text----
  p$full_text <- get_full_text(xml, id = basename(filename))

  # references ----
  refs <- get_refs(xml)
  p$references <- refs$references
  p$citations <- refs$citations

  # TODO: figures ----
  divs <- xml2::xml_find_all(xml, "//figure")

  return(p)
}

#' Read in grobid XML
#'
#' @param filename The path to the XML file to be read
#'
#' @return An XML object
#' @keywords internal
read_grobid_xml <- function(filename) {
  xml_text <- filename |>
    readLines(warn = FALSE) |>
    paste(collapse = "\n") |>
    gsub("</s><s>", " ", x = _) |> # get rid of sentence tags
    gsub("</?s>", "", x = _) |> # get rid of sentence tags
    # fixes a glitch that stopped xml from being read
    gsub(' xmlns="http://www.tei-c.org/ns/1.0"', "", x = _, fixed = TRUE)

  xml <- tryCatch(xml2::read_xml(xml_text), error = function(e) {
    stop("The file ", filename, " could not be read as XML")
  })

  if (xml2::xml_name(xml) != "TEI") {
    stop("This XML file does not parse as a valid Grobid TEI.")
  }

  return(xml)
}


#' Add section info to full text table
#'
#' @param xml The grobid XML
#' @param id An ID for the paper
#'
#' @return a data frame of the classified full text
#' @keywords internal
#'
get_full_text<- function(xml, id = NULL) {
  ## abstract ----
  abstract <- xml2::xml_find_all(xml, "//abstract //p") |>
    xml2::xml_text()

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

  ## tokenize sentences ----
  # TODO: get tidytext to stop breaking sentences at "S.E. ="
  text <- NULL # hack to stop cmdcheck warning :(
  ft <- do.call(rbind, c(list(abst_table), div_text)) |>
    tidytext::unnest_sentences(text, text, to_lower = FALSE) |>
    dplyr::mutate(s = dplyr::row_number(), .by = c("div", "p"))

  ft$id <- id

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

  # beginning sections after abstract with no header labelled intro
  non_blanks <- which(!is.na(ft$section) & ft$section != "abstract")
  if (length(non_blanks) > 0) {
    blank_start <- non_blanks[[1]] - 1
    blanks <- rep(c(TRUE, FALSE), c(blank_start, length(ft$section) - blank_start))
    blanks[abstract] <- FALSE
    ft$section[blanks] <- "intro"
  }

  # check if sections with no label are Figure or Table
  first_s <- ft$p == 1 & ft$s == 1
  no_header <- substr(ft$header, 0, 4) == "[div"

  fig_n <- grepl("^Figure\\s*\\d+", ft$text)
  fig_divs <- ft[first_s & no_header & fig_n, "div"]
  ft[ft$div %in% fig_divs, "section"] <- "figure"

  tab_n <- grepl("^Table\\s*\\d+", ft$text)
  tab_divs <- ft[first_s & no_header & tab_n, "div"]
  ft[ft$div %in% tab_divs, "section"] <- "table"

  # assume sections are the same class as previous if unclassified (after abstract)
  for (i in seq_along(ft$section)) {
    if (i > 1 &
        !abstract[i] &
        isFALSE(abstract[i-1]) &
        is.na(ft$section[i]) ) {
      ft$section[i] <- ft$section[i-1]
    }
  }

  colorder <- c("text", "section", "header", "div", "p", "s", "id")

  blank_divs <- grepl("\\[div-\\d+\\]", ft$text)
  #blank_divs <- ft$p == 0

  body_table <- ft[!blank_divs, colorder]
  rownames(body_table) <- NULL

  return(body_table)
}

#' Get author info from XML
#'
#' @param xml The grobid XML
#'
#' @return an author list
#' @keywords internal
get_authors <- function(xml) {
  if (!requireNamespace("scienceverse", quietly = TRUE)) {
    return(NULL)
  }

  s <- scienceverse::study()
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

  return(s$authors)
}

#' Get references from grobid XML
#'
#' @param xml The grobid XML
#'
#' @return a list with a data frame of referencesand a data frame of citation sentences
#' @keywords internal
get_refs <- function(xml) {
  refs <- xml2::xml_find_all(xml, "//listBibl //biblStruct")

  ref_table <- data.frame(
    bib_id = xml2::xml_attr(refs, "id")
  )
  ref_table$doi <- xml2::xml_find_first(refs, ".//analytic //idno[@type='DOI']") |>
    xml2::xml_text()
  ref_table$ref <- xml2::xml_find_first(refs, ".//note[@type='raw_reference']") |>
    xml2::xml_text()

  # get in-text citation ----
  textrefs <- xml2::xml_find_all(xml, "//body //ref[@type='bibr']")

  # get parent paragraphs of all in-text references and parse into sentences
  textrefp <- data.frame(
    p = xml2::xml_parent(textrefs) |> as.character() |>
      gsub("</?p>", "", x = _)
  ) |>
    tidytext::unnest_sentences(output = "text", input = "p", to_lower = FALSE)

  # find refs
  matches <- gregexpr("(?<=ref type=\"bibr\" target=\"#)b\\d+", textrefp$text, perl = TRUE)
  no_targets <- gregexpr("(?<=ref type=\"bibr\">).*(?=</ref>)", textrefp$text, perl = TRUE)
  textrefp$bib_id <- mapply(c,
                            regmatches(textrefp$text, matches),
                            regmatches(textrefp$text, no_targets)) |>
    sapply(paste, collapse = ";")

  citation_table <- textrefp[textrefp$bib_id != "", ]
  citation_table$text <- lapply(citation_table$text, xml2::read_html) |>
    sapply(xml2::xml_text)

  citation_table <- citation_table |>
    tidyr::separate_longer_delim("bib_id", delim = ";")


  return(list(
    references = ref_table,
    citations = citation_table[, c("bib_id", "text")]
  ))
}

#' Crossref info
#'
#' @param refs a table with DOIs
#'
#' @return the table with additional crossref data
#' @export
crossref <- function(refs) {
  #site_down("api.labs.crossref.org", error = FALSE)

  # set up progress bar ----
  if (getOption("scienceverse.verbose")) {
    pb <- progress::progress_bar$new(
      total = nrow(refs), clear = FALSE,
      format = "Querying crossref [:bar] :current/:total :elapsedfull"
    )
    pb$tick(0)
    Sys.sleep(0.2)
    pb$tick(0)
  }

  crossref <- lapply(refs$doi, \(doi) {
    url <- sprintf("https://api.labs.crossref.org/works/%s?mailto=debruine@gmail.com", doi)
    j <- jsonlite::read_json(url)
    if (getOption("scienceverse.verbose")) pb$tick()
    j
  })

  refs$updates <- sapply(crossref, \(x) {
    uds <- x$message$`cr-labs-updates`
    if (length(uds) == 0) return(NA)
    sapply(uds, \(ud) {
      paste0(ud$`update-nature`, ": ",
             paste(ud$reasons, collapse = "+")
      )
    }) |> paste(collapse = "; ")
  })

  return(refs)
}
