### text_tab ----
text_tab <- tabItem(
  tabName = "text_tab",

  box(width = 12, collapsible = TRUE, collapsed = TRUE,
      title = "Search",
      fluidRow(
        column(width = 12, textInput("search_pattern", "Pattern", "*", "100%"))
      ),
      fluidRow(
        column(width = 4, selectInput("search_section", "Section", c("all", "abstract", "intro", "method", "results", "discussion"))),
        column(width = 4, selectInput("search_return", "Return", c("sentence", "paragraph", "section", "match"))),
        column(width = 4, div(
          checkboxGroupInput("search_options", NULL, c("Ignore Case" = "ignore.case",
                                                       "Fixed" = "fixed",
                                                       "Search this table" = "table"), selected = "ignore.case")
          #checkboxInput("search_ignore_case", "Ignore Case", TRUE),
          #checkboxInput("search_fixed", "Fixed", FALSE),
          #checkboxInput("search_table", "Search this table", FALSE),
        ))
      ),
      actionButton("search_text", "Search"),
      actionButton("search_reset", "Reset"),
      actionButton("search_preset_p", "p-values"),
      actionButton("search_preset_n", "sample size")
  ),
  downloadButton("download_table", "Download Table"),
  dataTableOutput("text_table")
)

