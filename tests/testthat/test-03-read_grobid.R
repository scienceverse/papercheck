# setwd("tests/testthat/")

test_that("error", {
  expect_true(is.function(read_grobid))

  # invalid file type
  expect_error(read_grobid("no.exist"))

  # non-grobid XML
  filename <- tempfile(fileext = "xml")
  xml2::read_html("<p>Hello</p>") |>
    xml2::write_xml(filename, options = "as_xml")
  expect_warning(g1 <- read_grobid(filename))
  expect_null(g1)

  # valid grobid with no text
  expect_no_error(notext <- read_grobid("examples/notext.xml"))
  expect_equal( nrow( search_text(notext) ), 0)

  # bad file
  expect_warning(g2 <- read_grobid("examples/badxml.xml"),
                 "The file examples/badxml.xml was not valid XML",
                 fixed = TRUE)
  expect_null(g2)

  # bib problems
  expect_no_error(g3 <- read_grobid("examples/bib_problem.xml"))

  # warning on batch import
  expect_warning(all <- read_grobid("examples"),
                 "The file examples/badxml.xml was not valid XML",
                 fixed = TRUE)
  expect_equal(length(all), 4)
})

test_that("basics", {
  filename <- demoxml()
  s <- read_grobid(filename)
  expect_equal(class(s), c("scivrs_paper", "list"))

  title <- "To Err is Human: An Empirical Investigation"
  expect_equal(s$name, "to_err_is_human")
  expect_equal(s$info$title, title)

  expect_equal(substr(s$info$description, 1, 10), "This paper")

  expect_equal(nrow(s$full_text), 24)
})


test_that("read_grobid_xml", {
  expect_true(is.function(read_grobid_xml))

  # non-grobid XML
  filename <- tempfile(fileext = "xml")
  xml2::read_html("<p>Hello</p>") |>
    xml2::write_xml(filename, options = "as_xml")
  expect_error( read_grobid_xml(filename),
                "does not parse as a valid Grobid TEI")

  filename <- demoxml()
  xml <- read_grobid_xml(filename)
  expect_s3_class(xml, "xml_document")

  title <- xml2::xml_find_first(xml, "//title") |> xml2::xml_text()
  exp <- "To Err is Human: An Empirical Investigation"
  expect_equal(title, exp)
})

test_that("get_refs", {
  expect_true(is.function(get_refs))

  filename <- demoxml()
  xml <- read_grobid_xml(filename)

  refs <- get_refs(xml)
  expect_equal(names(refs), c("references", "citations"))

  expect_equal(names(refs$references), c("bib_id", "doi", "ref"))
  expect_equal(nrow(refs$references), 2)

  expect_equal(names(refs$citations), c("bib_id", "text"))

  # no raw_references
  expect_no_error(g <- read_grobid("examples/bib2.xml"))
  expect_true( all(!is.na(g$references$ref)) )

  #skip_if_offline("api.labs.crossref.org")
  #updated_refs <- crossref(refs$references[1:2, ])
})

test_that("iteration", {
  expect_error(read_grobid("noxml"),
               "^There are no xml files in the directory")

  grobid_dir <- demodir()
  s <- read_grobid(grobid_dir)

  file_list <- list.files(grobid_dir, ".xml")

  expect_equal(length(s), 3)
  expect_equal(names(s), file_list)
  expect_s3_class(s[[1]], "scivrs_paper")
  expect_s3_class(s[[2]], "scivrs_paper")
  expect_s3_class(s[[3]], "scivrs_paper")

  expect_equal(s[[1]]$name, "eyecolor")
  expect_equal(s[[2]]$name, "incest")
  expect_equal(s[[3]]$name, "prereg")

  expect_equal(s[[1]]$info$title, "Positive sexual imprinting for human eye color")
  expect_equal(s[[2]]$info$title, "Having other-sex siblings predicts moral attitudes to sibling incest, but not parent-child incest")
  expect_equal(s[[3]]$info$title, "Will knowledge about more efficient study designs increase the willingness to pre-register?")

  # separate xmls
  filenames <- demodir() |> list.files(".xml", full.names = TRUE)
  s <- read_grobid(filenames)
  expect_equal(names(s), file_list)

  s <- read_grobid(filenames[3:1])
  expect_equal(names(s), file_list[3:1])

  # recursive file search
  s <- read_grobid(system.file(package="papercheck"))
  nested_files <- c("extdata/to_err_is_human.xml",
                    "grobid/eyecolor.xml",
                    "grobid/incest.xml",
                    "grobid/prereg.xml")
  expect_equal(names(s), nested_files)
})





