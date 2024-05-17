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

## UI ----
ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "PaperCheck"),
  dashboardSidebar(
    sidebarMenu(
      id = "tabs",
      menuItem("Load", tabName = "load_tab",
               icon = icon("yin-yang")),
      menuItem("Text", tabName = "text_tab",
               icon = icon("table"))
    ),
    actionButton("demo", "Demo"),
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
      text_tab
    )
  )
)


## server ----
server <- function(input, output, session) {
  ## reactiveVals ----
  debug_msg("----reactiveVals----")

  my_study <- reactiveVal( scienceverse::study(name = "", description = "") )
  text_table <- reactiveVal( data.frame() )

  ### return_study ----
  observeEvent(input$return_study, {
    debug_msg("return_study")

    # just return sv object if only one study
    s <- my_study()
    if (length(s) == 1) s <- s[[1]]

    stopApp(s)
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
      s <- read_grobid(input$load_xml$datapath)

      if (length(input$load_xml$datapath) == 1) {
        s <- list(s)
      }

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

    my_study(study)
    text_table(papercheck::search_text(study))

    # reset search interface
    c("search_pattern",
      "search_section",
      "search_return",
      "search_ignore_case",
      "search_fixed") |> sapply(shinyjs::reset)

    updateSelectInput(session, "study_name", choices = names(study))
  }

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

  output$study_title <- renderText({
    my_study()[[input$study_name]]$info$title
  })
  output$study_desc <- renderText({
    my_study()[[input$study_name]]$info$description
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

    tryCatch({
      sec <- input$search_section
      if (sec == "all") sec <- NULL

      s <- text_table()
      if (!"table" %in% input$search_options | nrow(s) == 0) {
        s <- my_study()
      }
      tt <- search_text(s,
                        pattern = input$search_pattern,
                        section = sec,
                        return = input$search_return,
                        ignore.case = "ignore.case" %in% input$search_options,
                        fixed = "fixed" %in% input$search_options
                        )
      text_table(tt)
    }, error = function(e) {
      shinyjs::alert(e$message)
    })
  }, ignoreNULL = TRUE)

  ### search_reset ----
  observeEvent(input$search_reset, {
    debug_msg("search_reset")

    updateTextInput(session, "search_pattern", value = "*")
    my_study() |>
      papercheck::search_text() |>
      text_table()
  })

  ### search presets ----

  observeEvent(input$search_preset_p, {
    updateTextInput(session, "search_pattern", value = "p\\s*(=|<|>)+\\s*[0-9\\.,-]*\\d")
  })

  observeEvent(input$search_preset_n, {
    updateTextInput(session, "search_pattern", value = "N\\s*=\\s*[0-9,\\.]*\\d")
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
    if ("scivrs_study" %in% class(.app.study.)) {
      .app.study. <- list(.app.study.)
      names(.app.study.) <- .app.study.[[1]]$name
    }
    update_from_study( .app.study. )
  }

} # end server()

shinyApp(ui, server)
