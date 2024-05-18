### gpt_tab ----
gpt_tab <- tabItem(
  tabName = "gpt_tab",

  box(width = 12, collapsible = TRUE, collapsed = FALSE,
      title = "ChatGPT",
      textInput("gpt_query", "Query", "What is the sample size?", "100%"),
      textInput("gpt_context", "Context", "You are a scientist", "100%"),
      fluidRow(
        column(4, checkboxGroupInput("gpt_group_by", "Group By", "file", inline = TRUE)),
        valueBoxOutput("total_cost"),
        column(4, actionButton("gpt_submit", "Search"))
      )
  ),
  downloadButton("download_gpt", "Download Answers"),
  dataTableOutput("gpt_table")
)
