#' Get paper from grobid XML file
#'
#' You can create a grobid XML file from a paper PDF at https://huggingface.co/spaces/kermitt2/grobid.
#'
#' @param filename the path to the XML file, a vector of file paths, or the path to a directory containing XML files
#'
#' @return A paper object with class scivrs_paper, or a list of paper objects
#' @export
#'
#' @examples
#' filename <- demoxml()
#' paper <- read_grobid(filename)
read_grobid <- function(filename) {
  # handle list of files or a directory----
  if (length(filename) > 1) {
    # set up progress bar ----
    if (verbose()) {
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
      apply(1, \(x) x[!is.na(x)]) |>
      sapply(paste0, collapse = "/") |>
      gsub("\\.xml$", "", x = _)

    p <- lapply(filename, \(x) {
      p1 <- read_grobid(x)
      if (verbose()) pb$tick()
      p1
    })

    names(p) <- unique_names
    for (un in unique_names) {
      if (!is.null(p[[un]]) && nrow(p[[un]]$full_text) > 0) {
        p[[un]]$full_text$id <- un
      }
    }

    # remove NULLs
    valid <- !sapply(p, is.null)
    return(paperlist(p[valid]))
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

  # add .xml if not there
  filename <- gsub("(\\.xml)?$", "\\.xml", filename)

  if (!file.exists(filename)) {
    stop("The file ", filename, " does not exist.")
  }

  # read xml ----
  xml <- tryCatch(read_grobid_xml(filename),
                  error = function(e) {
                    warning("The file ", filename, " was not valid XML", call. = FALSE)
                    return(FALSE)
                  })

  # return nothing if the file can't be read, so iteration doesn't fail
  if (isFALSE(xml)) return(NULL)

  # set up paper object ----
  p <- paper()

  p$id <- basename(filename) |>
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

  # get app info ----
  p$app <- get_app_info(xml)

  # full text----
  p$full_text <- get_full_text(xml, id = basename(filename))

  # references ----
  refs <- get_refs(xml)
  p$references <- refs$references
  p$citations <- refs$citations

  # DOI ----
  doi <- get_doi(xml)
  p$info$doi <- doi

  # submission ----
  submission <- get_submission(xml)
  p$info$submission <- submission

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
    gsub(' xmlns="http://www.tei-c.org/ns/1.0"', "",
         x = _, fixed = TRUE) |>
    # replace URL links with markdown style
    # gsub("<ref type=\"url\" target=\"([^\"]+)\">([^<]+)</ref>",
    #      "[\\2](\\1)", x = _)
    gsub("<ref type=\"url\" target=\"([^\"]+)\">([^<]+)</ref>",
       "{{\\1}}", x = _)

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
get_full_text<- function(xml, id = "") {
  div <- NULL  # ugh cmdcheck

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

  # back matter ----
  back <- xml2::xml_find_all(xml, "//back //div")
  types <- xml2::xml_attr(back, "type") |>
    setdiff(c(NA, "references"))
  back_text <- lapply(types, function(t) {
    str <- paste0("//back //div[@type='", t, "'] //div")
    divs <- xml2::xml_find_all(xml, str)
    b_text <- lapply(seq_along(divs), \(i){
      div <- divs[[i]]
      header <- xml2::xml_find_first(div, ".//head") |> xml2::xml_text()
      #if (is.na(header)) header <- sprintf("[div-%02d]", i)
      paragraphs <- xml2::xml_find_all(div, ".//p") |>
        xml2::xml_text()
      df <- data.frame(
        header = header,
        text = c(header, paragraphs),
        div = NA,
        p = c(0, seq_along(paragraphs)),
        section = t
      )
    })

    do.call(rbind, b_text)
  }) |> do.call(rbind, args = _)

  # make divs increment (this is gross code)
  if (!is.null(back_text)) {
    start <- length(div_text) + 1
    end <- sum(back_text$p == 0) + start - 1
    back_text$div[back_text$p == 0] <- start:end
    back_text <- tidyr::fill(back_text, div)
  }

  ## add figures and tables ----
  # TODO: get sentences with internal refs to figs
  figs <- xml2::xml_find_all(xml, "//figure")
  figtbl <- lapply(figs, \(fig) {
    figid <- xml2::xml_attr(fig, "id")

    data.frame(
      header = xml2::xml_find_first(fig, ".//head") |>
        xml2::xml_text(),
      text = xml2::xml_find_first(fig, ".//figDesc") |>
        xml2::xml_text(),
      section = sub("_\\d+$", "", x = figid),
      div = sub("^(fig|tab)_", "", x = figid) |> as.numeric()
    )
  }) |> do.call(rbind, args = _)
  figtbl <- figtbl %||% data.frame()

  ## add footnotes ----
  # TODO: find and example to finish and test this
  notes <- xml2::xml_find_all(xml, "//note[@place='foot']")
  notetbl <- lapply(notes, \(note) {
    noteid <- xml2::xml_attr(note, "id")
    data.frame(
      header = "",
      text = xml2::xml_text(note),
      section = sub("_\\d+$", "", x = noteid),
      div = sub("^foot_", "", x = noteid) |> as.numeric()
    )
  }) |> do.call(rbind, args = _)
  notetbl <- notetbl %||% data.frame()

  ## tokenize sentences ----
  # TODO: get tidytext to stop breaking sentences at "S.E. ="
  text <- NULL # hack to stop cmdcheck warning :(
  alltext <- do.call(dplyr::bind_rows, c(list(abst_table),
                                         div_text,
                                         list(back_text,
                                              figtbl,
                                              notetbl)))
  if (nrow(alltext) > 0) {
    ft <- alltext |>
      # stop initials getting parsed as sentences
      dplyr::mutate(text = gsub("\\b([A-Z])\\.", "\\1", text)) |>
      tidytext::unnest_sentences(text, text, to_lower = FALSE) |>
      dplyr::mutate(s = dplyr::row_number(), .by = c("div", "p"))
    ft$id <- id
  } else {
    ft <- data.frame(
      header = character(0),
      text = character(0),
      div = double(0),
      p = double(0),
      s = double(0),
      id = character(0)
    )
  }

  # convert link notation to <url>
  ft$text <- ft$text |>
    gsub("\\{\\{", "<", x = _) |>
    gsub("\\}\\}", ">", x = _)

  # classify headers ----
  back <- !is.na(ft$section)
  back_sections <- ft$section[back]
  nospace_headers <- gsub("\\s", "", ft$header)
  abstract <- grepl("abstract", nospace_headers, ignore.case = TRUE)
  intro <- grepl("intro", nospace_headers, ignore.case = TRUE)
  method <- grepl("method|material", nospace_headers, ignore.case = TRUE)
  results <- grepl("result", nospace_headers, ignore.case = TRUE)
  discussion <- grepl("discuss", nospace_headers, ignore.case = TRUE)
  ft$section <- rep(NA_character_, nrow(ft))
  ft$section[abstract] <- "abstract"
  ft$section[intro] <- "intro"
  ft$section[method] <- "method"
  ft$section[discussion] <- "discussion"
  ft$section[results] <- "results"
  ft$section[back] <- back_sections

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
  s <- study()
  authors <- xml2::xml_find_all(xml, "//sourceDesc //author[persName]")

  for (a in authors) {
    family <- xml2::xml_find_all(a, ".//surname") |> xml2::xml_text() |> paste(collapse = " ")
    given <- xml2::xml_find_all(a, ".//forename") |> xml2::xml_text() |> paste(collapse = " ")
    email <- xml2::xml_find_all(a, ".//email") |> xml2::xml_text() |> paste(collapse = ";")
    orcid <- xml2::xml_find_all(a, ".//idno[@type='ORCID']") |> xml2::xml_text()
    # if (is.null(orcid) & !is.null(family)) {
    #   orcid_lookup <- get_orcid(family, given)
    #   if (length(orcid_lookup) == 1) orcid <- orcid_lookup
    # }
    if (length(orcid) == 0) orcid = NULL

    affs <- xml2::xml_find_all(a, ".//affiliation")
    affiliation <- lapply(affs, function(aff) {
      org <- xml2::xml_find_all(aff, ".//orgName")
      names <- xml2::xml_attr(org, "type")
      vals <- xml2::xml_text(org)
      stats::setNames(as.list(vals), names)
    })

    s <- add_author(s, family, given, orcid, email = email,
                    affiliation = affiliation)
  }

  return(s$authors)
}

#' Get references from grobid XML
#'
#' @param xml The grobid XML
#'
#' @return a list with a data frame of references and a data frame of citation sentences
#' @keywords internal
get_refs <- function(xml) {
  refs <- xml2::xml_find_all(xml, "//listBibl //biblStruct")

  if (length(refs) > 0) {
    ref_table <- data.frame(
      ref_id = xml2::xml_attr(refs, "id")
    )
    # ref_table$doi <- xml2::xml_find_first(refs, ".//analytic //idno[@type='DOI']") |>
    #   xml2::xml_text()

    bibs <- lapply(refs, xml2bib)

    ref_table$ref <- bibs |>
      sapply(format) |>
      gsub("\\n", " ", x = _)

    ref_table$doi <- sapply(bibs, \(x) x$doi %||% NA_character_)
    ref_table$bibtype <- sapply(bibs, \(x) x$bibtype %||% NA_character_)
    ref_table$title <- sapply(bibs, \(x) x$title %||% NA_character_)
    ref_table$journal <- sapply(bibs, \(x) x$journal %||% NA_character_)
    ref_table$year <- sapply(bibs, \(x) x$year %||% NA_integer_)
    ref_table$authors <- lapply(bibs, \(x) x$author %||% NA_character_) |>
      sapply(paste, collapse = ", ")
  } else {
    ref_table <- data.frame(
      ref_id = character(0),
      doi = character(0),
      ref = character(0)
    )
  }

  # get in-text citation ----
  #textrefs <- xml2::xml_find_all(xml, "//body //ref[@type='bibr']")
  textrefs <- xml2::xml_find_all(xml, "//ref[@type='bibr'][@target]")

  if (length(textrefs) > 0) {
    # get parent paragraphs of all in-text references and parse into sentences
    textrefp <- data.frame(
      p = xml2::xml_parent(textrefs) |> as.character() |>
        gsub("</?p>", "", x = _)
    ) |>
      tidytext::unnest_sentences(output = "text", input = "p", to_lower = FALSE)

    # find refs
    matches <- gregexpr("(?<=ref type=\"bibr\" target=\"#)b\\d+",
                        textrefp$text, perl = TRUE) |>
      regmatches(textrefp$text, m = _)
    # textrefp$ref_id <- sapply(matches, paste, collapse = ";")
    no_targets <- gregexpr("(?<=ref type=\"bibr\">)[^</ref>]*(?=</ref>)",
                           textrefp$text, perl = TRUE) |>
      regmatches(textrefp$text, m = _) |>
      # only keep non-target refs that might be author names
      lapply(\(x) x[grepl("[a-zA-Z]{2,}", x)])

    textrefp$ref_id <- mapply(c, matches, no_targets, SIMPLIFY = FALSE) |>
      sapply(paste, collapse = ";")

    citation_table <- textrefp[textrefp$ref_id != "", ]
    citation_table$text <- lapply(citation_table$text, xml2::read_html) |>
      sapply(xml2::xml_text)

    citation_table <- citation_table |>
      tidyr::separate_longer_delim("ref_id", delim = ";")
  } else {
    citation_table = data.frame(ref_id = character(0),
                                text = character(0))
  }

  return(list(
    references = ref_table,
    citations = citation_table[, c("ref_id", "text")]
  ))
}


#' Get Tables from Grobid XML
#'
#' @param xml The grobid XML
#'
#' @return a list of tables
#' @keywords internal
get_tables <- function(xml) {
  tables <- xml2::xml_find_all(xml, "//figure[@type='table']")

  if (length(tables) == 0) return (list())

  ids <- tables |> xml2::xml_attr("id")

  tab <- xml2::xml_find_all(tables[[1]], ".//table //row") |>
    lapply(xml2::xml_find_all, xpath = ".//cell") |>
    lapply(xml2::xml_text)
  tab_header <- tab[[1]]

  return(list())
}


#' Get DOI info from XML
#'
#' @param xml The grobid XML
#'
#' @return a DOI
#' @keywords internal
get_doi <- function(xml) {
  # Find the DOI using its ID type attribute
  doi <- xml2::xml_find_all(xml, "//sourceDesc //idno[@type='DOI']") |>
    xml2::xml_text() |>
    paste(collapse = " ")

  # Return the DOI
  if (nchar(doi) == 0) {
    return(NULL)
  }

  return(doi)
}

#' Get submission info from XML
#'
#' @param xml The grobid XML
#'
#' @return a submission
#' @keywords internal
get_submission <- function(xml) {
  # Find the DOI using its ID type attribute
  submission <- xml2::xml_find_all(xml, "//sourceDesc //note[@type='submission']") |>
    xml2::xml_text() |>
    paste(collapse = " ")

  # Return the submission
  if (nchar(submission) == 0) {
    return(NULL)
  }

  return(submission)
}


