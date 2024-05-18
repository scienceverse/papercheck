test_that("exists", {
  expect_true(is.function(gpt))

  expect_error(gpt("hi", "repeat this", chunk_size = 0),
               "The argument `chunk_size` must be larger than 0",
               fixed = TRUE)
  expect_error(gpt("hi", "repeat this", chunk_size = "a"),
               "The argument `chunk_size` must be a positive integer",
               fixed = TRUE)
  expect_error(gpt("hi", "repeat this", chunk_overlap = "a"),
               "The argument `chunk_overlap` must be a positive integer",
               fixed = TRUE)
  expect_error(gpt("hi", "repeat this", chunk_overlap = -100),
               "The argument `chunk_overlap` must be 0 or larger",
               fixed = TRUE)
  expect_error(gpt("hi", "repeat this", chunk_overlap = 1000),
               "The argument `chunk_overlap` must be smaller than `chunk_size`",
               fixed = TRUE)
  expect_error(gpt("hi", "repeat this", temperature = "a"),
               "The argument `temperature` must be a positive number",
               fixed = TRUE)
  expect_error(gpt("hi", "repeat this", temperature = -3),
               "The argument `temperature` must be between 0.0 and 2.0",
               fixed = TRUE)
  expect_error(gpt("hi", "repeat this", temperature = 2.1),
               "The argument `temperature` must be between 0.0 and 2.0",
               fixed = TRUE)
})

test_that("basic", {
  skip("Requires ChatGPT API key")

  filename <- system.file("grobid", package = "papercheck")
  s <- read_grobid(filename)
  text <- search_text(s, section = "method", return = "section")
  query <- "What is the sample size of this study (e.g., the number of participants tested?"
  context <- "Please give your answer exactly like this: 'XXX (XX men, XX women)', with the total number first, then any subsets in parentheses."


  expect_message( res <- gpt(text, query, context) )

  expect_equal(res$query[[1]], query)
  expect_equal(res$context[[1]], context)
  expect_equal(res$answer[[1]], "300 (150 men, 150 women)")
  expect_equal(res$answer[[2]], "1998 (666 men, 1332 women)")
  expect_equal(res$index, c("eyecolor.xml", "incest.xml"))

  res$eyecolor.xml$callback$total_tokens


  text_vector <- text$text[8:10]
  expect_message( res2 <- gpt(text_vector, query, context) )
  expect_equal(res2$answer, "1998 (666 men, 1332 women)")

  # changing options
  res$answer

  size100 <- gpt(text, query, context, chunk_size = 100, chunk_overlap = 25)
  size100$answer

  overlap200 <- gpt(text, query, context, chunk_overlap = 200)
  overlap200$answer

  temp1 <- gpt(text, query, context, temperature = 1)
  temp1$answer

  temp2 <- gpt(text, query, context, temperature = 2)
  temp2$answer
})
