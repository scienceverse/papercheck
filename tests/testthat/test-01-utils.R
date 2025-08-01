test_that("site_down", {
  skip_on_ci()
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

test_that(".onLoad", {
  op.defaults <- c(
    papercheck.verbose = TRUE,
    papercheck.llm_max_calls = 30L,
    papercheck.llm.model = "llama-3.3-70b-versatile",
    papercheck.osf.delay = 0,
    papercheck.osf.api = "https://api.osf.io/v2",
    papercheck.osf.api.calls = 0
  )

  # op.current <- names(op.defaults) |> sapply(getOption)
  names(op.defaults) |> sapply(\(o) options(setNames(list(NULL), o)))
  op.null <- names(op.defaults) |> sapply(getOption)
  expect_true(sapply(op.null, is.null) |> all())

  papercheck:::.onLoad()
  op.reset <- names(op.defaults) |> sapply(getOption)
  expect_false(sapply(op.reset, is.null) |> any())
  expect_equal(op.reset, op.defaults)
})

test_that(".onAttach", {
  op <- capture_message(papercheck:::.onAttach())
  expect_true(grepl("Welcome to PaperCheck", op))
  expect_true(grepl("This is alpha software", op))
})

test_that("demo functions", {

  d <- demodir()
  e <- system.file("grobid", package = "papercheck")
  expect_equal(d, e)

  x <- demoxml()
  expect_true(all(grepl("\\.xml$", x)))

  p <- demopdf()
  expect_true(all(grepl("\\.pdf$", p)))
})

test_that("concat_tables", {
  papers <- read(demodir())

  bibs <- concat_tables(papers, c("bib"))
  expect_equal(nrow(bibs), 48)

  ids <- unique(bibs$id)
  expect_equal(length(ids), length(papers))
})


test_that("is_paper_list", {
  expect_equal(is_paper_list(psychsci), TRUE)
  expect_equal(is_paper_list(psychsci[1]), TRUE)
  expect_equal(is_paper_list(psychsci[[1]]), FALSE)
  expect_equal(is_paper_list(list(1,3,5)), FALSE)
  expect_equal(is_paper_list(NULL), FALSE)

  # empty lists return TRUE
  expect_equal(is_paper_list(psychsci[c()]), TRUE)
  expect_equal(is_paper_list(list()), TRUE)
})

test_that("print.scivrs_paper", {
  paper <- demoxml() |> read()
  op <- capture_output(print(paper))
  op.sv <- capture_output(print.scivrs_paper(paper))
  expected <- "---------------\nto_err_is_human\n---------------\n\nTo Err is Human: An Empirical Investigation\n\n* Sections: 4\n* Sentences: 24\n* Bibliography: 2\n* X-Refs: 2\n"

  expect_equal(op, expected)
  expect_equal(op, op.sv)
  expect_true(grepl("to_err_is_human", op))
})

test_that("print.scivrs_paperlist", {
  x <- psychsci[1:3]
  op <- capture_output(print(x))
  op.sv <- capture_output(print.scivrs_paperlist(x))

  expect_true(grepl("# A tibble: 3", op, fixed = TRUE))
  expect_equal(op, op.sv)
})

test_that("[.scivrs_paperlist", {
  # subsetting maintains class
  x <- psychsci[1:3]
  expect_s3_class(psychsci, "scivrs_paperlist")
  expect_s3_class(x, "scivrs_paperlist")
})

test_that("verbose", {
  expect_equal(verbose(FALSE), FALSE)
  expect_equal(verbose(), FALSE)
  expect_equal(verbose(TRUE), TRUE)
  expect_equal(verbose(), TRUE)
  expect_equal(verbose(0), FALSE)
  expect_equal(verbose("FALSE"), FALSE)
  expect_equal(verbose(1), TRUE)
  expect_equal(verbose("TRUE"), TRUE)

  expect_error(verbose("G"))
  expect_invisible(verbose(TRUE))
  expect_visible(verbose())
})


