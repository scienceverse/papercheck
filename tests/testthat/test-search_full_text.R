options(scienceverse.verbose = FALSE)
grobid_dir <- system.file("grobid", package="papercheck")
filename <- file.path(grobid_dir, "incest.pdf.tei.xml")

test_that("error", {
  expect_true(is.function(search_full_text))
})

test_that("default", {
  s <- study_from_xml(filename)
  sig <- search_full_text(s, "significant")

  expect_true(all(grepl("significant", sig$text)))
  expect_equal(nrow(sig), 4)

  # section
  res <- search_full_text(s, "significant", "results")
  expect_equal(nrow(res), 3)
  expect_true(all(res$section_class == "results"))
})

test_that("return", {
  s <- study_from_xml(filename)

  res_s1 <- search_full_text(s, "significant")
  res_s2 <- search_full_text(s, "significant", return = "sentence")
  res_p <- search_full_text(s, "significant", return = "paragraph")
  res_sec <- search_full_text(s, "significant", return = "section")
  res_m <- search_full_text(s, "significant", return = "match")

  expect_equal(res_s1$text, res_s2$text)

  expect_equal(nrow(res_s1), 4)
  expect_equal(nrow(res_p), 3)
  expect_equal(nrow(res_sec), 2)
  expect_equal(res_m$text, rep("significant", 4))

  p <- search_full_text(s, "p\\s*[><=]{1,2}\\s*[0-9\\.]+", return = "match")
  expect_equal(p$text[[1]], "p = 0.019")
})

test_that("iteration", {
  s <- study_from_xml(grobid_dir)

  # search full text
  sig <- search_full_text(s, "significant")
  expect_equal(nrow(sig), 13)

  equal <- search_full_text(s, "=", section = "results")
  classes <- as.character(unique(equal$section_class))
  expect_equal(classes, "results")
})
