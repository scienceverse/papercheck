test_that("exists", {
  expect_true(is.function(module_run))
  expect_true(is.function(module_list))

  builtin <- module_list()
  expect_true(is.data.frame(builtin))
  exp <- c("name", "title", "description", "type", "path")
  expect_equal(names(builtin), exp)

  paper <- read_grobid(demoxml())
  expect_error( module_run() )
  expect_error( module_run(paper) )

  # setwd("tests/testthat/")

  expect_error( module_run(paper, "notamodule"),
                "There were no modules that matched notamodule",
                fixed = TRUE )

  expect_error(module_run(paper, "modules/code-no-file.mod"),
             "The code file does-not-exist.R could not be found",
             fixed = TRUE)


  expect_error(module_run(paper, "modules/error.mod"),
               "The module has a problem with JSON format")
})

test_that("text", {
  paper <- demoxml() |> read_grobid()

  module <- "all-p-values"
  mod_output <- module_run(paper, module)

  expect_equal(mod_output$module, module)
  expect_equal(mod_output$title, "List All P-Values")
  expect_equal(mod_output$traffic_light, "info")
  expect_null(mod_output$report)

  first_char <- substr(mod_output$table$text, 1, 1)
  expect_true(all(first_char == "p"))
})

test_that("code", {
  paper <- demoxml() |> read_grobid()

  # code from json
  mod_output <- module_run(paper, "retractionwatch")
  expect_equal(names(mod_output$table), c("bib_id", "doi", "ref", "id"))
  expect_equal(mod_output$report, "You cited some papers in the Retraction Watch database; double-check that you are acknowledging their retracted status when citing them.")
})

test_that("ml", {
  # errors
  paper <- demoxml() |> read_grobid()

  args <- list(model_dir = "no-exist",
               result_col = "class",
               map = c(`0` = "no", `1` = "yes"))
  expect_error( module_run_ml(paper, args, "."),
                "The model directory no-exist could not be found")
})

test_that("AI", {
  skip("AI")
  skip_if_offline()

  paper <- read_grobid(demoxml())
  hypo <- search_text(paper, "hypothes", return = "paragraph")

  mod_output <- module_run(hypo, "ai-summarise")

  expect_equal(names(mod_output$table),
               c("id", "section", "answer", "cost"))
})

test_that("all-p-values", {
  paper <- read_grobid(demoxml())
  module <- "all-p-values"
  p <- module_run(paper, module)
  expect_equal(p$traffic_light, "info")
  expect_equal(nrow(p$table), 3)
  expect_equal(p$module, module)
})

test_that("all-urls", {
  paper <- read_grobid(demoxml())
  module <- "all-urls"
  urls <- module_run(paper, module)
  expect_equal(urls$traffic_light, "info")
  expect_equal(nrow(urls$table), 3)
  expect_equal(urls$module, module)
})

test_that("osf-check", {
  skip_if_offline("osf.io")

  text <- data.frame(
    text = c("https://osf.io/5tbm9/",
             "https://osf.io/629bx/"),
    section = NA, # TODO: search_text not require section column
    id = c("private", "public")
  )
  mo <- module_run(text, "osf-check")
  exp <- c(`https://osf.io/5tbm9` = "closed",
           `https://osf.io/629bx` = "open"
  )
  expect_equal(mo$table$status, exp)
})

test_that("retractionwatch", {
  paper <- demoxml() |> read_grobid()

  mod_output <- module_run(paper, "retractionwatch")
  expect_equal(mod_output$traffic_light, "yellow")
  expect_equal(mod_output$table$doi, "10.1177/0956797614520714")
  expect_equal(mod_output$report, "You cited some papers in the Retraction Watch database; double-check that you are acknowledging their retracted status when citing them.")
})

test_that("imprecise-p", {
  paper <- demodir() |> read_grobid()
  paper <- paper[[1]]

  module <- "imprecise-p"
  mod_output <- module_run(paper, module)
  expect_equal(mod_output$traffic_light, "green")
  expect_equal(nrow(mod_output$table), 0)
  expect_equal(mod_output$report, "All p-values were reported with standard precision")

  # add imprecise p-values
  paper$full_text[1, "text"] <- "Bad p-value example (p < .05)"
  paper$full_text[2, "text"] <- "Bad p-value example (p<.05)"
  paper$full_text[3, "text"] <- "Bad p-value example (p < 0.05)"
  paper$full_text[4, "text"] <- "Bad p-value example; p < .05"
  paper$full_text[5, "text"] <- "Bad p-value example (p < .005)"
  paper$full_text[6, "text"] <- "Bad p-value example (p > 0.05)"
  paper$full_text[7, "text"] <- "Bad p-value example (p > .1)"
  paper$full_text[8, "text"] <- "Bad p-value example (p = n.s.)"
  paper$full_text[9, "text"] <- "Bad p-value example; p=ns"
  paper$full_text[10, "text"] <- "OK p-value example; p < .001"
  paper$full_text[11, "text"] <- "OK p-value example; p < .0005"

  mod_output <- module_run(paper, module)
  expect_equal(mod_output$traffic_light, "red")
  expect_equal(nrow(mod_output$table), 9)
  expect_equal(mod_output$report, "You may have reported some imprecise p-values")
})

test_that("marginal", {
  paper <- demodir() |> read_grobid()
  paper <- paper[[1]]
  module <- "marginal"

  # no relevant text
  mod_output <- module_run(paper, module)
  expect_equal(mod_output$traffic_light, "green")
  expect_equal(nrow(mod_output$table), 0)
  expect_equal(mod_output$report, "No effects were described as marginally/borderline/close to significant.")

  # add marginal text
  paper$full_text[1, "text"] <- "This effect was marginally significant."
  paper$full_text[12, "text"] <- "This effect approached significance."

  mod_output <- module_run(paper, module)
  expect_equal(mod_output$traffic_light, "red")
  expect_equal(nrow(mod_output$table), 2)
  expect_equal(mod_output$report, "You described effects as marginally/borderline/close to significant. It is better to write 'did not reach the threshold alpha for significance'.")
})

test_that("sample-size", {
  skip("ml")

  paper <- demoxml() |> read_grobid() |>
    search_text(".{30, }", section = "method", return = "paragraph")
  module <- "sample-size-ml"

  mod_output <- module_run(paper, module)
  expect_equal(mod_output$traffic_light, "na")
  expect_equal(nrow(mod_output$table), nrow(paper))
  expect_equal(mod_output$module, module)
})

test_that("ref-consistency", {
  paper <- demoxml() |> read_grobid()
  module <- "ref-consistency"

  mod_output <- module_run(paper, module)
  expect_equal(mod_output$traffic_light, "red")
  expect_equal(nrow(mod_output$table), 2)
  expect_equal(mod_output$module, module)
})

test_that("statcheck", {
  paper <- demoxml() |> read_grobid()
  module <- "statcheck"

  mod_output <- module_run(paper, module)
  expect_equal(mod_output$traffic_light, "red")
  expect_equal(nrow(mod_output$table), 2)
  expect_equal(mod_output$module, module)
})

