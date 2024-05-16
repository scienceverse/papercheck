### load_tab ----
load_tab <- tabItem(
  tabName = "load_tab",
  p("This shiny app is under development; all materials created should be carefully checked."),
  fileInput("load_xml", "Load from XML", multiple = TRUE, width = "100%", accept = ".xml"),
  box(width = 12, collapsible = TRUE, collapsed = FALSE,
      title = "Info",
      selectInput("study_name", "Study Name", c()),
      textOutput("study_title"),
      h4("Abstract"),
      textOutput("study_desc"),
      textOutput("study_keywords")
      # textInput("study_title", "Study Title", "", "100%"),
      # textAreaInput("study_desc", "Study Description", "", "100%"),
      # textInput("study_keywords", "Keywords (separate with semicolons)", "", "100%", )
  )
)

