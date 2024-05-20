### osf_tab ----
osf_tab <- tabItem(
  tabName = "osf_tab",
  actionButton("search_osf", "Search for OSF links"),
  downloadButton("download_osf", "Download Table"),
  dataTableOutput("osf_table")
)
