options(scienceverse.verbose = FALSE)
grobid_dir <- system.file("grobid", package="papercheck")

test_that("error", {
  expect_true(is.function(read_grobid))

  # invalid file type
  expect_error(read_grobid("no.exist"))

  # non-grobid XML
  filename <- tempfile(fileext = "xml")
  xml2::read_html("<p>Hello</p>") |>
    xml2::write_xml(filename, options = "as_xml")
  expect_error(read_grobid(filename))
  expect_error(read_grobid(filename, xml_type = "grobid"))
  expect_error(read_grobid(filename, xml_type = "huh"))
})

test_that("basics", {
  filename <- file.path(grobid_dir, "incest.xml")
  s <- read_grobid(filename)
  expect_equal(class(s), c("scivrs_study", "list"))

  title <- "Having other-sex siblings predicts moral attitudes to sibling incest, but not parent-child incest"
  expect_equal(s$name, "incest.xml")
  expect_equal(s$info$title, title)

  expect_equal(substr(s$info$description, 1, 5), "Moral")

  expect_equal(nrow(s$full_text), 89)
})

test_that("iteration", {
  expect_error(read_grobid("."),
               "^There are no xml files in the directory")

  s <- read_grobid(grobid_dir)

  file_list <- list.files(grobid_dir, ".xml")

  expect_equal(length(s), 3)
  expect_equal(names(s), file_list)
  expect_s3_class(s[[1]], "scivrs_study")
  expect_s3_class(s[[2]], "scivrs_study")
  expect_s3_class(s[[3]], "scivrs_study")

  expect_equal(s[[1]]$name, "eyecolor.xml")
  expect_equal(s[[2]]$name, "incest.xml")
  expect_equal(s[[3]]$name, "prereg.xml")

  expect_equal(s[[1]]$info$title, "Positive sexual imprinting for human eye color")
  expect_equal(s[[2]]$info$title, "Having other-sex siblings predicts moral attitudes to sibling incest, but not parent-child incest")
  expect_equal(s[[3]]$info$title, "Will knowledge about more efficient study designs increase the willingness to pre-register?")


  # separate xmls
  filenames <- list.files(grobid_dir, ".xml", full.names = TRUE)
  s <- read_grobid(filenames)
  expect_equal(names(s), file_list)

  s <- read_grobid(filenames[3:1])
  expect_equal(names(s), file_list[3:1])

  # messages
  options(scienceverse.verbose = TRUE)
  suppressMessages({
    expect_message(s <- read_grobid(filenames),
                   "Processing 3 files...", fixed = TRUE)
    expect_message(s <- read_grobid(filenames),
                   "Complete!", fixed = TRUE)
  })
})

