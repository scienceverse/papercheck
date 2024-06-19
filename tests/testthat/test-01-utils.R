test_that("site_down", {
  expect_error(site_down("notarealwebsite"),
               "The website notarealwebsite is not available")
  expect_error(site_down("notarealwebsite", "No %s"),
               "No notarealwebsite")

  expect_true(site_down("notarealwebsite", error = FALSE))

  skip_if_offline("localhost")

  expect_false(site_down("localhost"))
  expect_false(site_down("http://localhost"))
  expect_false(site_down("https://localhost"))
  expect_false(site_down("localhost/otherstuff"))
})

test_that("demofiles", {

  d <- demofiles()
  d2 <- demofiles(type = "dir")
  e <- system.file("grobid", package = "papercheck")
  expect_equal(d, d2)
  expect_equal(d, e)

  x <- demofiles("xml")
  expect_true(all(grepl("\\.xml$", x)))

  p <- demofiles("pdf")
  expect_true(all(grepl("\\.pdf$", p)))
})

test_that("concat_tables", {
  papers <- read_grobid(demofiles())

  refs <- concat_tables(papers, c("references"))
  expect_equal(nrow(refs), 48)

  ids <- unique(refs$id)
  expect_equal(length(ids), length(papers))
})

test_that("print.scivrs_paper", {
  paper <- demofiles("xml")[[1]] |> read_grobid()
  op <- capture_output(print(paper))
  op.sv <- capture_output(print.scivrs_paper(paper))

  expect_equal(op, op.sv)
  expect_true(grepl("eyecolor", op))
})
