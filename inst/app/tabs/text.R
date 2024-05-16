### text_tab ----
text_tab <- tabItem(
  tabName = "text_tab",

  box(width = 12, collapsible = TRUE, collapsed = TRUE,
      title = "Search",
      fluidRow(
        column(width = 10, textInput("search_pattern", "Pattern", "*", "100%")),
        column(width = 2, actionButton("search_text", "Search"))
      ),
      fluidRow(
        column(width = 4, selectInput("search_section", "Section", c("all", "abstract", "intro", "method", "results", "discussion"))),
        column(width = 4, selectInput("search_return", "Return", c("sentence", "paragraph", "section", "match"))),
        column(width = 2, checkboxInput("search_ignore_case", "Ignore Case", TRUE)),
        column(width = 2, checkboxInput("search_fixed", "Fixed", FALSE))
      ),
      actionButton("search_preset_p", "p-values"),
      actionButton("search_preset_n", "sample size")
  ),
  downloadButton("download_table", "Download Table"),
  dataTableOutput("text_table")
)

