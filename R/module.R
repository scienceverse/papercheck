#' Run a module
#'
#' @param paper a paper object or a list of paper objects
#' @param module the name of a module or path to a module to run on this object
#'
#' @return a list of the returned table and report text
#' @export
#'
module_run <- function(paper, module) {
  # search for module in built-in directory
  module_libs <- system.file("modules", package = "papercheck")
  module_paths <- sapply(module_libs, list.files, full.names = TRUE, recursive = TRUE)
  module_names <- basename(module_paths) |> sub("\\.mod$", "", x = _)

  which_mod <- which(module_names == module)
  if (length(which_mod) == 1) {
    module_path <- module_paths[which_mod]
  } else if (file.exists(module)) {
    module_path <- module
  } else {
    stop("There were no modules that matched ", module)
  }

  # read in module
  json <- jsonlite::read_json(module_path, simplifyVector = TRUE)
  module_dir <- dirname(module_path)

  if (json$type == "text") {
    results <- module_run_text(paper, json$text)
  } else if (json$type == "code") {
    results <- module_run_code(paper, json$code, module_dir)
  } else if (json$type == "ml") {
    results <- module_run_ml(paper, json$ml, module_dir)
  } else if (json$type == "ai") {
    results <- module_run_ai(paper, json$ai)
  } else {
    stop("The module has an invalid type of ", json$type)
  }

  # TODO: figure out module template for this
  if (is.null(results$traffic_light) &&
      !is.null(json$traffic_light)) {
    results$traffic_light <- ifelse(
      nrow(results$table) == 0,
      json$traffic_light$not_found,
      json$traffic_light$found
    )
  }

  results$traffic_light <- results$traffic_light %||% "na"

  # TODO: determine what kind of report text to send back
  if (is.null(results$report) &&
      !is.null(json$report)) {
    results$report <- json$report[[results$traffic_light]]
  }

  report_items <- list(
    module = module,
    title = json$title,
    table = results$table,
    report = results$report,
    traffic_light = results$traffic_light
  )
  return(report_items)
}


#' Run text module
#'
#' @param paper the scienceverse paper object (or list of objects)
#' @param args a list of arguments to `search_text()`
#'
#' @return data frame
#' @keywords internal
module_run_text <- function(paper, args) {
  args$paper <- paper
  list(
    table = do.call(search_text, args)
  )
}


#' Run code module
#'
#' @param paper the scienceverse paper object (or list of objects)
#' @param args a list of arguments
#' @param module_dir the base directory for the module, in case code is in files with relative paths
#'
#' @return data frame
#' @keywords internal
module_run_code <- function(paper, args, module_dir = ".") {
  if (!is.null(args$path)) {
    filepath <- file.path(module_dir, args$path)
    if (!file.exists(filepath)) {
      stop("The code file ", args$path, " could not be found")
    }
    args$code <- readLines(filepath)
  }
  code <- paste(args$code, collapse = "\n")

  results <- tryCatch(eval(parse(text = code)),
           error = function(e) {
             stop("The function has errors:", e$message)
           })

  if (is.data.frame(results)) {
    results <- list(table = results)
  }

  return(results)
}

#' Run machine learning module
#'
#' @param paper the scienceverse paper object (or list of objects)
#' @param args a list of arguments
#' @param module_dir the base directory for the module, in case resources are in files with relative paths
#'
#' @return data frame
#' @keywords internal
module_run_ml <- function(paper, args, module_dir = ".") {
  model_dir <- file.path(module_dir, args$path)
  if (!file.exists(model_dir)) {
    stop("The model directory ", args$path, " could not be found; make sure the module specification file is using a relative path to the directory")
  }

  if (is.vector(paper)) {
    text <- data.frame(text = paper)
  } else if (is.data.frame(paper)) {
    text <- paper
  } else {
    text <- search_text(paper, return = "sentence")
  }

  class_col <- args$class_col %||% "class"
  return_prob <- args$return_prob %||% FALSE

  results <- ml(text, model_dir,
     class_col = class_col,
     map = args$map,
     return_prob = return_prob)

  return( list(table = results) )
}

#' Run AI module
#'
#' @param paper the scienceverse paper object (or list of object)
#' @param args a list of argumentsto `gpt()`
#'
#' @return data frame
#' @keywords internal
module_run_ai <- function(paper, args) {
  args$text <- search_text(paper)
  results <- do.call(gpt, args)

  return( list(table = results) )
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
  files <- list.files(module_dir, "\\.mod$",
                      full.names = TRUE,
                      recursive = TRUE)
  json <- lapply(files, jsonlite::read_json, simplifyVector = TRUE)

  display <- data.frame(
    name = basename(files) |> sub("\\.mod$", "", x = _),
    title = sapply(json, `[[`, "title"),
    type = sapply(json, `[[`, "type"),
    path = files
  )

  return(display)
}
