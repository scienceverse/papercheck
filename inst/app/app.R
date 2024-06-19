## app.R ##
suppressPackageStartupMessages({
  library(shiny)
  library(shinyjs)
  library(shinydashboard)
  library(DT)
  library(scienceverse)
  library(papercheck)
  library(dplyr)
  library(shiny.i18n)
})

source("R/constants.R")
source("R/funcs.R")
source("i18n/trans.R")


## Interface Tab Items ----
source("tabs/load.R")
source("tabs/text.R")
source("tabs/gpt.R")
source("tabs/osf.R")
source("tabs/statcheck.R")

## UI ----
ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "PaperCheck"),
  dashboardSidebar(
    sidebarMenu(
      id = "tabs",
      menuItem("Load Files", tabName = "load_tab",
               icon = icon("file")),
      menuItem("Search Text", tabName = "text_tab",
               icon = icon("magnifying-glass")),
      menuItem("OSF Links", tabName = "osf_tab",
               icon = icon("database")),
      menuItem("Statcheck", tabName = "statcheck_tab",
               icon = icon("database")),
      menuItem("ChatGPT", tabName = "gpt_tab",
               icon = icon("robot"))
    ),
    actionButton("demo", "Load Demo Files"),
    #actionButton("reset_study", "Reset"),
    actionButton("return_study", "Quit & Return"),
    tags$br(),

    selectInput("lang", "Change language",
                choices = c(English = "en",
                            Dutch = "nl",
                            Spanish = "es",
                            Chinese = "zh"),
                selected = "en"),
    p("Most of the phrases have not been translated; this is just a proof of concept.", style="margin: 0 1em;")
  ),
  dashboardBody(
    shinyjs::useShinyjs(),
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
      tags$script(src = "custom.js")
    ),
    tabItems(
      load_tab,
      text_tab,
      osf_tab,
      gpt_tab,
      statcheck_tab
    )
  )
)


## server ----
server <- function(input, output, session) {
  updateNumericInput(session, "gpt_max_calls", value = getOption("papercheck.gpt_max_callsl"))

  if (Sys.getenv("CHATGPT_KEY") != "") hide("gpt_api")

  ## reactiveVals ----
  debug_msg("----reactiveVals----")

  my_study <- reactiveVal( list() )
  text_table <- reactiveVal( data.frame() )
  gpt_table <- reactiveVal( data.frame() )
  osf_table <- reactiveVal( data.frame() )
  statcheck_table <- reactiveVal( data.frame() )
  total_cost <- reactiveVal(0)

  ### return_study ----
  observeEvent(input$return_study, {
    debug_msg("return_study")

    # just return sv object if only one study
    s <- my_study()
    if (length(s) == 1) s <- s[[1]]

    stopApp(s)
  })

  observe({
    study <- my_study()

    if (length(study) > 0) {
      text_table(search_text(study))

      # reset search interface
      # c("search_pattern",
      #   "search_section",
      #   "search_return",
      #   "search_ignore_case",
      #   "search_fixed") |> sapply(shinyjs::reset)
      choices <- names(study)
    } else {
      choices <- c()
    }
    updateSelectInput(session, "study_name", choices = choices)
  })

  ### on text_table() change ----
  observe({
    needs_text_table <- c("download_table", "gpt_submit", "search_text",
                          "run_statcheck", "check_p_values")
    if (nrow(text_table()) == 0) {
      lapply(needs_text_table, shinyjs::disable)
    } else {
      lapply(needs_text_table, shinyjs::enable)
      #shinyjs::click("search_text") # trigger search
    }
  })

  ### on gpt_table() change ----
  observe({
    needs_gpt_table <- "download_gpt"
    if (nrow(gpt_table()) == 0) {
      lapply(needs_gpt_table, shinyjs::disable)
    } else {
      lapply(needs_gpt_table, shinyjs::enable)
    }
  })

  ## load ----
  debug_msg("---- load ----")

  ### demo ----
  observeEvent(input$demo, {
    debug_msg("demo")

    filepath <- system.file("grobid", package = "papercheck")
    s <- read_grobid(filepath)
    update_from_study(s)
  })

  ### load_xml ----
  observeEvent(input$load_xml, {
    debug_msg("load_xml")

    tryCatch({
      n <- length(input$load_xml$datapath)
      s <- vector("list", n)
      withProgress(message = 'Processing files', value = 0, {
        detail <- paste("1/", n, " (", input$load_xml$name[[1]], ")")
        incProgress(0, detail = detail)

        for (i in seq_along(input$load_xml$datapath)) {
          path <- input$load_xml$datapath[[i]]
          s[[i]] <- read_grobid(path)
          if (i < n) {
            detail <- paste(i+1, "/", n, " (",
                            input$load_xml$name[[i+1]], ")")
          }
          incProgress(1/n, detail = detail)
        }
      })

      # fix filename because of shiny upload
      names(s) <- basename(input$load_xml$name)
      for (i in seq_along(s)) {
        name <- names(s)[[i]]
        s[[i]]$name <- name
        s[[i]]$info$filename <- name
        s[[i]]$full_text$file <- name
      }

      update_from_study(s)
    }, error = function(e) {
      shinyjs::alert(e$message)
    })
  }, ignoreNULL = TRUE)

  ### update_from_study ----
  update_from_study <- function(study) {
    debug_msg("update_from_study")

    text_table(data.frame())
    osf_table(data.frame())
    gpt_table(data.frame())
    statcheck_table(data.frame())

    my_study(study)
  }

  ### n_papers_loaded ----
  output$n_papers_loaded <- renderText({
    n <- length(my_study())
    p <- ifelse(n==1, "paper", "papers")
    paste(n, p, "loaded")
  })

  ### study_name ----
  observeEvent(input$study_name, {
    debug_msg("study_name")

    info <- my_study()[[input$study_name]]$info

    #updateTextInput(session, "study_title", value = info$title)
    # updateTextAreaInput(session, "study_desc",
    #                     value = info$description)
    # updateTextInput(session, "study_keywords",
    #                 value = paste(info$keywords, collapse = "; "))
  })

  output$study_title <- renderUI({
    h4(my_study()[[input$study_name]]$info$title)
  })
  output$study_desc <- renderUI({
    p(my_study()[[input$study_name]]$info$description)
  })
  output$study_keywords <- renderText({
    my_study()[[input$study_name]]$info$keywords |>
      paste(collapse = "; ")
  })

  ## text ----
  debug_msg("----text ----")

  ### text_table ----
  output$text_table <- renderDT({
    debug_msg("text_table")

    text_table()
  },
  selection = 'none',
  rownames = FALSE,
  options = dt_options
  )

  ### search_text ----
  observeEvent(input$search_text, {
    debug_msg("search_text")

    text <- text_table()
    if (!"table" %in% input$search_options | nrow(text) == 0) {
      text <- my_study()
    }
    text_table(data.frame()) # clear table

    tryCatch({
      sec <- input$search_section
      if (sec == "all") sec <- NULL

      tt <- search_text(text,
                        pattern = input$search_pattern,
                        section = sec,
                        return = input$search_return,
                        ignore.case = "ignore.case" %in% input$search_options,
                        fixed = "fixed" %in% input$search_options,
                        perl = "perl" %in% input$search_options
      )
      text_table(tt)
      updateCheckboxGroupInput(session, "gpt_group_by",
                               choices = names(tt),
                               selected = "file",
                               inline = TRUE)
    }, error = function(e) {
      shinyjs::alert(e$message)
    })
  }, ignoreNULL = TRUE)

  ### input$search_options ----
  observeEvent(input$search_options, {
    debug_msg("search_options")
    debug_msg(input$search_options)

    selected <- input$search_options
    choices <- c("Search this table" = "table",
                 "Fixed" = "fixed",
                 "Ignore Case" = "ignore.case",
                 "PERL regex" = "perl")
    if ("fixed" %in% selected) {
      selected <- base::setdiff(selected, c("ignore.case", "perl"))
      choices <- choices[1:2]
    }
    updateCheckboxGroupInput(session, "search_options",
                             choices = choices,
                             selected = selected)
  }, ignoreNULL = FALSE)

  ### search_reset ----
  observeEvent(input$search_reset, {
    debug_msg("search_reset")

    updateTextAreaInput(session, "search_pattern", value = "*")
    s <- my_study()

    if (length(s) > 0) {
      search_text(s) |> text_table()
    }
  })

  ### search presets ----

  observeEvent(input$search_preset_p, {
    updateTextAreaInput(session, "search_pattern", value = "p\\s*(=|<|>)+\\s*[0-9\\.,-]*\\d")
  })

  observeEvent(input$search_preset_n, {
    updateTextAreaInput(session, "search_pattern", value = "N\\s*=\\s*[0-9,\\.]*\\d")
  })

  observeEvent(input$search_marginal, {
    updateTextAreaInput(session, "search_pattern", value = "margin\\w* (?:\\w+\\s+){0,5}significan\\w*|trend\\w* (?:\\w+\\s+){0,1}significan\\w*|almost (?:\\w+\\s+){0,2}significan\\w*|approach\\w* (?:\\w+\\s+){0,2}significan\\w*|border\\w* (?:\\w+\\s+){0,2}significan\\w*|close to (?:\\w+\\s+){0,2}significan\\w*")
  })


  ### download_table ----
  output$download_table <- downloadHandler(
    filename = function() {
      debug_msg("download_table")
      paste0("table.csv")
    },
    content = function(file) {
      write.csv(text_table(), file, row.names = FALSE)
    }
  )

  ## osf ----

  ### search_osf----
  observeEvent(input$search_osf, {
    osf <- tryCatch( module_run(text_table(), "osf_check"),
                     error = function(e) {
                       return(data.frame())
                     })

    if (nrow(osf) == 0) {
      showModal(modalDialog(
        title = "No OSF URLs found",
        easyClose = TRUE,
        footer = tagList(
          modalButton("Dismiss")
        )
      ))
    }
    osf_table(osf)
  })

  ### osf_table----
  output$osf_table <- renderDT({
    debug_msg("osf_table")

    osf_table()
  },
  selection = 'none',
  rownames = FALSE,
  options = dt_options
  )

  ## statcheck ----

  ### run_statcheck ----
  observeEvent(input$run_statcheck, {
    statcheck_table(data.frame()) # clear table
    sc <- tryCatch( stats(text_table()),
                    error = function(e) {
                      return(data.frame())
                    })

    if (nrow(sc) == 0) {
      showModal(modalDialog(
        title = "No stats found",
        easyClose = TRUE,
        footer = tagList(
          modalButton("Dismiss")
        )
      ))
    }
    statcheck_table(sc)
  })

  ### check_p_values ----
  observeEvent(input$check_p_values, {
    statcheck_table(data.frame()) # clear table
    sc <- tryCatch( check_p_values(text_table()),
                    error = function(e) {
                      return(data.frame())
                    })

    if (nrow(sc) == 0) {
      showModal(modalDialog(
        title = "No p-values found",
        easyClose = TRUE,
        footer = tagList(
          modalButton("Dismiss")
        )
      ))
    }
    statcheck_table(sc)
  })

  ### statcheck_table----
  output$statcheck_table <- renderDT({
    debug_msg("statcheck_table")

    st <- statcheck_table()
    if ("computed_p" %in% names(st))
      st$computed_p <- round(st$computed_p, 4)

    if (input$statcheck_errors) {
      if ("imprecise" %in% names(st))
        st <- st[st$imprecise, ]
      if ("error" %in% names(st))
        st <- st[st$error | st$decision_error, ]
    }

    return(st)
  },
  selection = 'none',
  rownames = FALSE,
  options = dt_search_options
  )


  ## gpt ----

  output$total_cost <- renderValueBox({
    valueBox(
      round(total_cost(), 5),
      "total cost",
      icon = icon("dollar-sign"),
      color = "green"
    )
  })

  ### gpt_max_calls----
  observeEvent(input$gpt_max_calls, {
    debug_msg("gpt_max_calls")
    if (is.numeric(input$gpt_max_calls)) {
      set_gpt_max_calls(input$gpt_max_calls)
      newmax <- getOption("papercheck.gpt_max_calls")
      updateNumericInput(session, "gpt_max_calls", value = newmax)
    }
  })

  ### gpt_submit----
  observeEvent(input$gpt_submit, {
    debug_msg("gpt_submit")

    text <- text_table()
    groups <- unique(text[, input$gpt_group_by, drop = FALSE])

    if (nrow(groups) > input$gpt_max_calls) {
      showModal(modalDialog(
        title = "Too many calls",
        paste("This will create", nrow(groups), "calls to ChatGPT. Set the maximum number allowed higher if this is OK."),
        easyClose = TRUE,
        footer = tagList(
          modalButton("Dismiss")
        )
      ))
    } else {
      n <- nrow(groups)
      res <- vector("list", n)
      withProgress(message = 'Querying ChatGPT', value = 0, {
        detail <- paste(groups[1, ], collapse = ":") |>
          paste("1/", n, " (", x = _, ")")
        incProgress(0, detail = detail)
        for (i in 1:n) {
          subtext <- dplyr::semi_join(text, groups[i, ,drop = FALSE],
                                      by = input$gpt_group_by)
          res[[i]] <- gpt(text = subtext,
                          query = input$gpt_query,
                          context = input$gpt_context,
                          group_by = input$gpt_group_by,
                          CHATGPT_KEY = input$gpt_api)
          if (i < n) {
            detail <- paste(groups[i+1, ], collapse = ":") |>
              paste(i+1, "/", n, " (", x = _, ")")
          }
          incProgress(1/n, detail = detail)
        }
      })

      res <- do.call(rbind, res)
      gpt_table(res)
    }
  })

  ### gpt_table ----
  output$gpt_table <- renderDT({
    debug_msg("gpt_table")

    gt <- gpt_table()

    if (!is.null(gt$cost)) {
      total_cost(sum(gt$cost))
      gt$cost <- round(gt$cost, 5)
    }

    gt
  },
  selection = 'none',
  rownames = FALSE,
  options = dt_options
  )

  ### download_gpt ----
  output$download_gpt <- downloadHandler(
    filename = function() {
      debug_msg("download_gpt")
      paste0("gpt.csv")
    },
    content = function(file) {
      write.csv(gpt_table(), file, row.names = FALSE)
    }
  )

  ## translation ----
  debug_msg("----translation ----")

  ### i18n ----
  i18n <- reactive({
    selected <- input$lang
    if (length(selected) > 0 && selected %in% translator$get_languages()) {
      translator$set_translation_language(selected)
    }
    translator
  })

  ### lang ----
  observeEvent(input$lang, {
    debug_msg("lang")

    # text changes (h3, h4, p)
    for (h in trans_text) {
      suppressWarnings(tt <- i18n()$t(h))

      js <- sprintf("$('*[en=\"%s\"]').text(\"%s\");",
                    gsub("'", "\\\\'", h), tt)
      shinyjs::runjs(js)
    }

    # input label changes
    for (func in names(trans_labels)) {
      for (nm in names(trans_labels[[func]])) {
        l <- trans_labels[[func]][[nm]]
        tl <- suppressWarnings(
          i18n()$t(l)
        )

        args <- list(
          session = session,
          inputId = nm,
          label = tl
        )
        do.call(func, args)
      }
    }
  }, ignoreInit = TRUE)

  # save_trans ----
  save_trans(trans_text, trans_labels)

  debug_msg("server functions created")

  # .app.study ----
  if (exists(".app.study.") && !is.null(.app.study.)) {
    if ("scivrs_paper" %in% class(.app.study.)) {
      .app.study. <- list(.app.study.)
      names(.app.study.) <- .app.study.[[1]]$name
    }
    update_from_study( .app.study. )
  }

} # end server()

shinyApp(ui, server)
