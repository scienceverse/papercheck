## code to prepare `psychsci` dataset goes here

# make relative filename make sense
dir <- "data-raw/psychsci/grobid_0.8.2/"
setwd(dir)
psychsci <- read(".")
setwd("../../../")

usethis::use_data(psychsci, overwrite = TRUE, compress = "xz")

# docker run --rm --init --ulimit core=0 -p 8070:8070 lfoppiano/grobid:0.8.2
dir <- "data-raw/psychsci/grobid_0.8.2/"
filename = "data-raw/psychsci/pdf"
sink <- pdf2grobid(
  filename = filename,
  save_path = dir,
  #grobid_url = "http://localhost:8070",
  consolidateHeader = 1,
  consolidateCitations = 1,
  consolidateFunders = 1
)




# 09567976231188124 is an erratum
# 09567976221139496 and 09567976231217508 are just a corrigendum
# 0956797620955209 and 0956797620939054 have no titles but are research papers (both preregistered direct replications)

# fix corrigenda DOIs ----
info <- info_table(psychsci)
bad_dois <- which(paste0("10.1177/", info$id) != info$doi)
info[bad_dois, c("id", "doi", "title")]


# test full vs light ----
full <- read("data-raw/psychsci/grobid_0.8.2-full/")
light <- read("data-raw/psychsci/grobid_0.8.2/")
consolidated <- read("data-raw/psychsci/grobid_0.8.3_consolidated/")

info <- c("filename", "title", "keywords", "doi", "description")
light_info <- info_table(light, info)
full_info <- info_table(full, info)
cons_info <- info_table(consolidated, info)

info_table(psychsci, c("title", "keywords", "doi", "description"))

all(light_info$id == full_info$id)
all(light_info$id == cons_info$id)

abs_mismatch <- data.frame(
  id = light_info$id,
  light = light_info$description,
  full = full_info$doi,
  cons = cons_info$description
) |>
  dplyr::filter(light != cons)

doi_mismatch <- data.frame(
  id = light_info$id,
  light = light_info$doi,
  full = full_info$doi,
  cons = cons_info$doi
) |>
  dplyr::filter(light != cons)

kw_mismatch <- data.frame(
  id = light_info$id,
  light = light_info$keywords,
  full= full_info$keywords,
  cons= cons_info$keywords
) |>
  dplyr::filter(light != full)

title_mismatch <- data.frame(
  id = light_info$id,
  light = light_info$title,
  full= full_info$title,
  cons = cons_info$title
) |>
  dplyr::filter(tolower(light) != tolower(cons))

consref <- concat_tables(consolidated, "references")
lightref <- concat_tables(light, "references")
fullref <- concat_tables(full, "references")
