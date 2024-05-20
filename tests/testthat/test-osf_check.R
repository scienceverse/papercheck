grobid_dir <- system.file("grobid", package="papercheck")
filename <- file.path(grobid_dir, "incest.xml")

test_that("exists", {
  expect_true(is.function(osf_check))
})

test_that("basic", {
  skip_if_offline(host = "osf.io")
  skip_on_cran()

  s <- read_grobid(filename)
  text <- search_text(s)

  expect_no_error( osf <- osf_check(text) )
  expect_true(is.data.frame(osf))

  expect_true(all(osf$status %in% c("open", "missing", "closed")))
})
