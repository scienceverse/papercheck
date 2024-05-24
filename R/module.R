#' Run a module
#'
#' @param study a study object or a list of study objects
#' @param module the name of a module or path to a module to run on this object
#'
#' @return a list of the returned table and report text
#' @export
#'
module_run <- function(study, module) {
  if (!file.exists(module)) {
    # search for module
    module_libs <- system.file("modules", package = "papercheck")
    module_paths <- sapply(module_libs, list.files, full.names = TRUE, recursive = TRUE)
    module_names <- basename(module_paths) |> sub("\\.json$", "", x = _)

    module_path <- module_paths[which(module_names == module)]
  } else {
    module_path = module
  }
  json <- jsonlite::read_json(module_path, simplifyVector = TRUE)

  if (json$type == "text") {
    results_table <- module_run_text(study, json$search_text)
  } else if (json$type == "code") {
    results_table <- module_run_code(study, json$code)
  } else if (json$type == "ml") {
    results_table <- module_run_ml(study, json$ml)
  } else if (json$type == "ai") {
    results_table <- module_run_ai(study, json$ai)
  } else {
    stop("The module has an invalid type of ", json$type)
  }

  return(results_table)
}


#' Run text module
#'
#' @param study the scienceverse study object (or list of object)
#' @param args a list of arguments to `search_text()`
#'
#' @return data frame
#' @keywords internal
module_run_text <- function(study, args) {
  args$study <- study
  do.call(search_text, args)
}


#' Run code module
#'
#' @param study the scienceverse study object (or list of object)
#' @param args a list of arguments
#'
#' @return data frame
#' @keywords internal
module_run_code <- function(study, args) {
  # make function in new environment
  envir <- new.env()
  assign("study", study, envir = envir)

  code <- sprintf("library(%s)", args$packages) |>
    c(args$code) |>
    paste(collapse = "\n")

  tryCatch(eval(parse(text = code), envir = envir),
           error = function(e) {
             stop("The function has errors:", e$message)
           })
}

#' Run machine learning module
#'
#' @param study the scienceverse study object (or list of object)
#' @param args a list of arguments
#'
#' @return data frame
#' @keywords internal
module_run_ml <- function(study, args) {
  # TODO
  warning("The ML module type is not yet supported")
  data.frame()
}

#' Run AI module
#'
#' @param study the scienceverse study object (or list of object)
#' @param args a list of argumentsto `gpt()`
#'
#' @return data frame
#' @keywords internal
module_run_ai <- function(study, args) {
  args$text <- search_text(study)
  do.call(gpt, args)
}


#' List modules
#'
#' @param module_dir the directory to search for modules (defaults to the built-in modules)
#
#' @return a data frame of modules
#' @export
#'
#' @examples
#' module_list()
module_list <- function(module_dir = system.file("modules", package = "papercheck")) {
  files <- list.files(module_dir, "\\.json$",
                      full.names = TRUE,
                      recursive = TRUE)
  json <- lapply(files, jsonlite::read_json, simplifyVector = TRUE)

  display <- data.frame(
    name = basename(files) |> sub("\\.json$", "", x = _),
    title = sapply(json, `[[`, "title"),
    type = sapply(json, `[[`, "type"),
    path = files
  )

  return(display)
}
