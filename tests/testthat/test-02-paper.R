test_that("exists", {
  expect_true(is.function(paper))

  p <- paper()
  expect_s3_class(p, "scivrs_paper")
  exp_names <- c("name", "info", "authors", "full_text", "references", "citations")
  expect_equal(names(p), exp_names)

  xml <- demofile("xml")[1]
  p <- paper(xml)
  expect_equal(nrow(p$full_text), 93)
  expect_equal(nrow(p$references), 21)
  expect_equal(nrow(p$citations), 22)
})
