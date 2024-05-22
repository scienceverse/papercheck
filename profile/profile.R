library(lineprof)

devtools::load_all(".")
#source("profile/stats-custom.R")

files <- list.files("profile/psyarxiv", "xml$", full.names = TRUE)

lineprof( s <- read_grobid(files[[1]]) )

lineprof( res <- search_text(s, section = "results") )

lineprof( sc <- stats(res) )

lineprof( p <- check_p_values(res) )

