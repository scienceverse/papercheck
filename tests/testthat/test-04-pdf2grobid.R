test_that("works", {
  expect_true(is.function(pdf2grobid))

  filename <- demofile("xml")[2]
  expect_error(pdf2grobid(filename, grobid_url = "notawebsite"),
               "The grobid server notawebsite is not available")

  # invalid file type
  skip_if_offline("localhost")
  expect_error(pdf2grobid("no.exist", grobid_url = "localhost"), "does not exist")
})

test_that("defaults", {
  skip_if_offline("grobid.work.abed.cloud")

  filename <- demofile("pdf")[2]

  xml <- pdf2grobid(filename, NULL)
  expect_s3_class(xml, "xml_document")

  file.remove(list.files(tempdir(), "\\.xml", full.names = TRUE))
  xml_file <- pdf2grobid(filename, tempdir())
  exp <- file.path(tempdir(), "incest.xml")
  expect_equal(xml_file, exp)

  xml2 <- read_grobid_xml(xml_file)
  expect_equal(xml, xml2)
  file.remove(list.files(tempdir(), "\\.xml", full.names = TRUE))
})

test_that("batch", {
  skip_if_offline("grobid.work.abed.cloud")

  grobid_dir <- demofile()

  file.remove(list.files(tempdir(), "\\.xml", full.names = TRUE))
  xml_files <- pdf2grobid(grobid_dir, tempdir())
  actual <- list.files(tempdir(), "\\.xml")
  expected <- list.files(grobid_dir, "\\.xml")
  expect_equal(actual, expected)
  file.remove(list.files(tempdir(), "\\.xml", full.names = TRUE))

  filenames <- demofile("pdf")
  xml_files <- pdf2grobid(filenames[2:3], tempdir())
  actual <- list.files(tempdir(), "\\.xml")
  expected <- list.files(grobid_dir, "\\.xml")[2:3]
  expect_equal(actual, expected)
  file.remove(list.files(tempdir(), "\\.xml", full.names = TRUE))
})
