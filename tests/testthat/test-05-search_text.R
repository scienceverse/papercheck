test_that("error", {
  filename <- demofiles("xml")[2]
  s <- read_grobid(filename)

  expect_true(is.function(search_text))

  expect_error(suppressWarnings(search_text(s, "(bad pattern")),
               "Check the pattern argument")

  expect_warning(search_text(s, "test", fixed = TRUE),
               "argument 'ignore.case = TRUE' will be ignored")
})

test_that("default", {
  filename <- demofiles("xml")[2]
  s <- read_grobid(filename)

  sig <- search_text(s, "significant")

  expect_true(all(grepl("significant", sig$text)))
  expect_equal(nrow(sig), 4)

  # section
  res <- search_text(s, "significant", "results")
  expect_equal(nrow(res), 3)
  expect_true(all(res$section == "results"))

  # multiple matches in a sentence
  equal <- search_text(s, "[a-zA-Z]*\\s*=\\s*[\\.0-9-]*",
                       section = "abstract",
                       return = "match")
  expect_equal(nrow(equal), 2)
  expect_equal(equal$text, c("N=313", "N=269"))
})

test_that("table as first argument", {
  filename <- demofiles("xml")[2]
  s <- read_grobid(filename)

  sig <- search_text(s, "significant")
  sig2 <- search_text(sig, "significant")
  expect_equal(sig, sig2)

  s3 <- search_text(sig, "[a-zA-Z]*\\s*=\\s*[\\.0-9-]*", return = "match")
  expect_equal(nrow(s3), 9)
})

test_that("return", {
  filename <- demofiles("xml")[2]
  s <- read_grobid(filename)

  res_s1 <- search_text(s, "significant")
  res_s2 <- search_text(s, "significant", return = "sentence")
  res_p <- search_text(s, "significant", return = "paragraph")
  res_sec <- search_text(s, "significant", return = "section")
  res_m <- search_text(s, "significant", return = "match")

  expect_equal(res_s1$text, res_s2$text)

  expect_equal(nrow(res_s1), 4)
  expect_equal(nrow(res_p), 3)
  expect_equal(nrow(res_sec), 2)
  expect_equal(res_m$text, rep("significant", 4))

  p <- search_text(s, "p\\s*[><=]{1,2}\\s*[0-9\\.]+", return = "match")
  expect_equal(p$text[[1]], "p = 0.019")
})

test_that("iteration", {
  s <- read_grobid(demofiles())

  # search full text
  sig <- search_text(s, "significant")
  expect_equal(nrow(sig), 13)

  equal <- search_text(s, "=", section = "results")
  classes <- as.character(unique(equal$section))
  expect_equal(classes, "results")
})
