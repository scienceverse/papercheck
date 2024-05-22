grobid_dir <- system.file("grobid", package="papercheck")

test_that("works", {
  expect_true(is.function(pdf2grobid))

  # invalid file type
  expect_error(pdf2grobid("no.exist"), "does not exist")

  skip_if_offline("grobid.work.abed.cloud")

  filename <- file.path(grobid_dir, "incest.pdf")

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

  file.remove(list.files(tempdir(), "\\.xml", full.names = TRUE))
  xml_files <- pdf2grobid(grobid_dir, tempdir())
  actual <- list.files(tempdir(), "\\.xml")
  expected <- list.files(grobid_dir, "\\.xml")
  expect_equal(actual, expected)
  file.remove(list.files(tempdir(), "\\.xml", full.names = TRUE))

  filenames <- list.files(grobid_dir, "\\.pdf", full.names = TRUE)
  xml_files <- pdf2grobid(filenames[2:3], tempdir())
  actual <- list.files(tempdir(), "\\.xml")
  expected <- list.files(grobid_dir, "\\.xml")[2:3]
  expect_equal(actual, expected)
  file.remove(list.files(tempdir(), "\\.xml", full.names = TRUE))
})
