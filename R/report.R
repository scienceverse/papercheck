#' Create a report
#'
#' @param paper a paper object
#' @param modules a vector of modules to run (names for built-in modules or paths for custom modules)
#' @param output_file the name of the output file
#' @param output_format the format to create the report in
#'
#' @return the file path the report is saved to
#' @export
#'
#' @examples
#' \dontrun{
#' filename <- demofiles("xml")[[1]]
#' paper <- read_grobid(filename)
#' report(paper)
#' }
report <- function(paper,
                   modules = c("imprecise-p", "marginal", "osf-check", "retractionwatch"),
                   output_file = paste0(paper$name, "_report.", output_format),
                   output_format = c("qmd", "html", "pdf")) {
  output_format <- match.arg(output_format)

  # check paper has required things
  if (!"scivrs_paper" %in% class(paper)) {
    stop("The paper argument must be a paper object (e.g., created with `read_grobid()`)")
  }

  # check if modules are available ----
  builtin <- module_list()$name
  custom <- setdiff(modules, builtin)
  cm_exists <- sapply(custom, file.exists)
  if (any(!cm_exists)) {
    stop("Some modules are not available: ",
         paste(custom[!cm_exists], collapse = ", "))
  }

  # run each module ----
  module_output <- lapply(modules, \(module) {
    tryCatch(module_run(paper, module),
             error = function(e) {
               report_items <- list(
                 module = module,
                 title = module,
                 table = NULL,
                 report = e$message,
                 traffic_light = "fail"
               )

               return(report_items)
             })
  })

  # set up report ----
  if (output_format == "pdf") {
    format <- paste0("  pdf:\n",
                     "    toc: true\n")
  } else {
    format <- paste0("  html:\n",
                     "    toc: true\n",
                     "    toc-float: true\n",
                     "    df-print: paged\n")
  }

  head <- paste0("---\n",
                "title: PaperCheck Report\n",
                "subtitle: ", paper$info$title, "\n",
                "date: ", Sys.Date(), "\n",
                "format:\n", format,
                "---\n\n",
                "<style>\n",
                "  h2.na::before { content: '⚪️ '; }\n",
                "  h2.fail::before { content: '⚫️ '; }\n",
                "  h2.red::before { content: '🔴 '; }\n",
                "  h2.yellow::before { content: '🟡 '; }\n",
                "  h2.green::before { content: '🟢 '; }\n",
                "</style>\n\n",
                "🟢 no problems detected; 🟡 something to check; 🔴 possible problems detected; ⚪️ not applicable; ⚫️ check failed\n\n")

  body <- sapply(module_output, function(mop) {
    tab <- mop$table
    if (is.data.frame(tab)) {
      tab$id <- NULL
      if (nrow(tab) == 0) {
        tab <- ""
      } else {
        tab <- knitr::kable(tab, format = "markdown") |>
          as.character() |>
          paste(collapse = "\n")
      }
    }
    paste0("## ", mop$title, " {.", mop$traffic_light, "}\n\n",
           mop$report, "\n\n", tab)
  }) |>
    paste(collapse = "\n\n") |>
    gsub("\\n{3,}", "\n\n", x = _)

  if (output_format == "qmd") {
    write(paste0(head, body), output_file)
  } else {
    # render report ----
    temp_input <- tempfile(fileext = ".qmd")
    temp_output <- sub("qmd$", output_format, temp_input)
    write(paste0(head, body), temp_input)

    tryCatch({
      quarto::quarto_render(input = temp_input,
                            quiet = TRUE,
                            output_format = output_format)
    }, error = function(e) {
      stop("There was an error rendering your report:\n", e$message)
    })

    file.rename(temp_output, output_file)
    unlink(temp_input) # clean up
  }

  return(output_file)
}
