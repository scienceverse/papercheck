#' Query ChatGPT
#'
#' Ask ChatGPT any question you want about the text from a search_text()
#'
#' You need to use your own ChatGPT API key. To avoid having to type it ou, add it to the .Renviron file in the following format (you can use `usethis::edit_r_environ()` to access the .Renviron file)
#'
#' CHATGPT_KEY="key_value_asdf"
#'
#' @param text The text to send to chatGPT (vector of strings, or data frame with the text in a column)
#' @param query The query to ask of chatGPT
#' @param context The context to send to chatGPT
#' @param text_col The name of the text column if text is a data frame
#' @param group_by the column(s) to group by if text is a data frame
#' @param CHATGPT_KEY your API key for ChatGPT
#' @param chunk_size text chunk size for embeddings
#' @param chunk_overlap overlap between text chunks for embeddings
#' @param temperature temperature value for ChatGPT (0.0 to 2.0)
#'
#' @return a list of results
gpt <- function(text, query,
                context = "You are a scientist",
                text_col = "text",
                group_by = "file",
                CHATGPT_KEY = Sys.getenv("CHATGPT_KEY"),
                chunk_size = 500,
                chunk_overlap = 100,
                temperature = 0) {
  ## error detection ----

  if (CHATGPT_KEY == "") {
    stop("You need to include the argument CHATGPT_KEY or set the variable CHATGPT_KEY in your Renviron")
  }

  if (!is.numeric(chunk_size)) {
    stop("The argument `chunk_size` must be a positive integer")
  } else if (chunk_size < 1) {
    stop("The argument `chunk_size` must be larger than 0")
  }

  if (!is.numeric(chunk_overlap)) {
    stop("The argument `chunk_overlap` must be a positive integer")
  } else if (chunk_overlap < 0) {
    stop("The argument `chunk_overlap` must be 0 or larger")
  } else if (chunk_overlap > chunk_size) {
    stop("The argument `chunk_overlap` must be smaller than `chunk_size`")
  }

  if (!is.numeric(temperature)) {
    stop("The argument `temperature` must be a positive number")
  } else if (temperature < 0 | temperature > 2) {
    stop("The argument `temperature` must be between 0.0 and 2.0")
  }

  # check if internet is available
  internet_down <- system("ping -c 1 chat.openai.com",
                          ignore.stdout = TRUE,
                          ignore.stderr = TRUE) |>
      as.logical()
  if (internet_down) {
    warning("The internet seems to be not connected")
  }

  # #load/check python stuff ----
  if (!reticulate::py_available(TRUE)) {
    stop("You need to install Python to use the chatGPT functions")
  }

  # load script
  pyscript <- system.file("python/gpt.py", package = "papercheck")
  reticulate::source_python(pyscript)

  # make a data frame if text is a vector
  if (!is.data.frame(text)) {
    text <- data.frame(text = text)
    names(text) <- text_col
    for (x in group_by) text[[x]] = x
  }

  if (getOption("scienceverse.verbose")) {
    ngroups <- text[, group_by, drop = FALSE] |> unique() |> nrow()
    pb <- progress::progress_bar$new(
      total = ngroups, clear = FALSE,
      format = "Querying ChatGPT [:bar] :current/:total :elapsedfull"
    )
    pb$tick(0)
    Sys.sleep(0.2)
    pb$tick(0)
  }

  file <- tempfile(fileext = ".txt")
  indices <- text[, group_by, drop = FALSE] |> as.list()
  response <- by(text, indices, \(x) {
    write(x[[text_col]], file)

    resp <- tryCatch({
      py_gpt(file, query, context, CHATGPT_KEY,
           chunk_size = chunk_size,
           chunk_overlap = chunk_overlap,
           temperature = temperature)
    }, error = function(e) {
      return(list(result = list(answer = NA),
                  callback = list(total_cost = NA),
                  error = e$message))
    })

    if (getOption("scienceverse.verbose")) pb$tick()

    return(resp)
  })

  errors <- lapply(response, \(x) x$error)
  error_indices <- !sapply(errors, is.null)
  if (any(error_indices)) {
    warn <- paste(names(errors)[error_indices], collapse = ", ") |>
      paste("There were errors in the following:", x = _)

    errors[error_indices] |>
      unique()|>
      paste("\n  * ", x = _) |>
      paste(warn, x = _) |>
      warning()
  }

  res <- data.frame(
    index = names(response),
    answer = sapply(response, \(x) x$result$answer),
    cost = sapply(response, \(x) x$callback$total_cost)
  )
  #res$query = query
  #res$context = context
  rownames(res) <- NULL

  message("Total cost: $", sum(res$cost) |> round(5))

  return(res)
}

get_embeddings <- function(text, CHATGPT_KEY = Sys.getenv("CHATGPT_KEY")) {

}
