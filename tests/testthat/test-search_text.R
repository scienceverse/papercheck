options(scienceverse.verbose = FALSE)
grobid_dir <- system.file("grobid", package="papercheck")
filename <- file.path(grobid_dir, "incest.xml")

test_that("error", {
  s <- read_grobid(filename)

  expect_true(is.function(search_text))

  expect_error(suppressWarnings(search_text(s, "(bad pattern")),
               "Check the pattern argument")

  expect_warning(search_text(s, "test", fixed = TRUE),
               "argument 'ignore.case = TRUE' will be ignored")
})

test_that("default", {
  s <- read_grobid(filename)

  sig <- search_text(s, "significant")

  expect_true(all(grepl("significant", sig$text)))
  expect_equal(nrow(sig), 4)

  # section
  res <- search_text(s, "significant", "results")
  expect_equal(nrow(res), 3)
  expect_true(all(res$section_class == "results"))
})

test_that("table as first argument", {
  s <- read_grobid(filename)

  sig <- search_text(s, "significant")
  sig2 <- search_text(sig, "significant")
  expect_equal(sig, sig2)

  s3 <- search_text(sig, "[a-zA-Z]*\\s*=\\s*[\\.0-9-]*", return = "match")
  expect_equal(nrow(s3), 3)
})

test_that("return", {
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
  s <- read_grobid(grobid_dir)

  # search full text
  sig <- search_text(s, "significant")
  expect_equal(nrow(sig), 13)

  equal <- search_text(s, "=", section = "results")
  classes <- as.character(unique(equal$section_class))
  expect_equal(classes, "results")
})

test_that("private", {
  skip("Private files")

  psyarxiv_dir <- "~/rproj/scienceverse/grobid_test/xml/psyarxiv-s/"
  collabra_dir   <- "~/rproj/scienceverse/grobid_test/xml/collabra-s/"

  # fix error: replacement has 1 row, data has 0
  filename <- list.files(collabra_dir, "collabra.77608.xml", full.names = TRUE)
  s <- read_grobid(filename)

  # long tests
  psyarxiv <- read_grobid(psyarxiv_dir)
  collabra <- read_grobid(collabra_dir)

  studies <- collabra #psyarxiv
  dir <- collabra_dir #psyarxiv_dir
  files <- list.files(dir, ".xml")
  expect_equal(names(studies), files)

  pattern <- "p\\s+(<)\\s+[0-9\\.-]+"
  p_sentence <- search_text(studies, pattern)
  p_match <- search_text(studies, pattern, return = "match")
  p_para <- search_text(studies, pattern, return = "paragraph")
  p_sec <- search_text(studies, pattern, return = "section")

  expect_true(nrow(p_match) > nrow(p_sentence))
  expect_true(nrow(p_sentence) > nrow(p_para))
  expect_true(nrow(p_para) > nrow(p_sec))

  # all sentences are in full match
  missing_s <- dplyr::anti_join(p_sentence, p_match,
                                by = c("section", "div", "p", "s", "file"))
  expect_equal(nrow(missing_s), 0)

  # all paragraphs are in full match
  missing_p <- dplyr::anti_join(p_para, p_match,
                                by = c("section", "div", "p", "file"))
  expect_equal(nrow(missing_p), 0)

  p_match |>
    dplyr::group_by(section, div, p, s, file) |>
    dplyr::filter(dplyr::n() > 1)
})
