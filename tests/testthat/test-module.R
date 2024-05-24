test_that("exists", {
  expect_true(is.function(module_run))
  expect_true(is.function(module_list))

  builtin <- module_list()
  expect_true(is.data.frame(builtin))
})

test_that("text", {
  filename <- system.file("grobid", package = "papercheck")
  s <- read_grobid(filename)

  mod_output <- module_run(s, "all-p-values")

  first_char <- substr(mod_output$text, 1, 1)
  expect_true(all(first_char == "p"))
})

test_that("code", {
  filename <- system.file("grobid", package = "papercheck")
  s <- read_grobid(filename)

  mod_output <- module_run(s, "retractionwatch")
  expect_equal(nrow(mod_output), 0)
})

test_that("text", {
  skip_if_offline()

  filename <- system.file("grobid/eyecolor.xml", package = "papercheck")
  s <- read_grobid(filename)

  mod_output <- module_run(s, "ai-summarise")

  first_char <- substr(mod_output$text, 1, 1)
  expect_true(all(first_char == "p"))
})
