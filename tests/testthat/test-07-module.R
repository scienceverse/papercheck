test_that("exists", {
  expect_true(is.function(module_run))
  expect_true(is.function(module_list))

  builtin <- module_list()
  expect_true(is.data.frame(builtin))
})

test_that("text", {
  s <- read_grobid(demofile())

  mod_output <- module_run(s, "all-p-values")

  first_char <- substr(mod_output$text, 1, 1)
  expect_true(all(first_char == "p"))
})

test_that("code", {
  s <- read_grobid(demofile())

  mod_output <- module_run(s, "retractionwatch")
  expect_equal(nrow(mod_output), 0)
})

test_that("text", {
  skip_if_offline()

  p <- read_grobid(demofile("xml")[2])
  hypo <- search_text(p, "hypothes", return = "paragraph")

  mod_output <- module_run(hypo, "ai-summarise")

  expect_equal(names(mod_output), c("id", "section", "answer", "cost"))
})
