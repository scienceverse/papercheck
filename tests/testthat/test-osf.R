verbose(FALSE)
# options(papercheck.osf.api = "https://api.osf.io/v2/")
# osf_delay(0)

test_that("exists", {
  expect_true(is.function(papercheck::osf_check_id))

  expect_true(is.function(papercheck::osf_links))
  expect_no_error(helplist <- help(osf_links, papercheck))

  expect_true(is.function(papercheck::osf_retrieve))
  expect_no_error(helplist <- help(osf_retrieve, papercheck))

  expect_true(is.function(papercheck::osf_info))
  expect_no_error(helplist <- help(osf_info, papercheck))

  expect_true(is.function(papercheck::osf_delay))
  expect_no_error(helplist <- help(osf_delay, papercheck))

  expect_true(is.function(papercheck::summarize_contents))
  expect_no_error(helplist <- help(summarize_contents, papercheck))

})

test_that("osf_api_check", {
  status <- osf_api_check()
  possible <- c("ok", "too many requests",
                "server error", "unknown")
  expect_true(status %in% possible)
})

test_that("osf_headers", {
  header <- osf_headers()
  expect_equal(header$`User-Agent`, "Papercheck")
})

test_that("osf_links", {
  paper <- psychsci$`0956797614557697`
  obs <- osf_links(paper)
  exp <- c("osf.io/e2aks", "osf.io/tvyxz/")
  expect_equal(obs$text, exp)

  # has view-only link across sentences
  paper <- psychsci$`0956797615569889`
  obs <- osf_links(paper)
  exp <- "osf.io/t9j8e/? view_only=f171281f212f4435917b16a9e581a73b"
  expect_equal(obs$text, exp)

  # check vo links
  info <- osf_info("t9j8e")
  expect_equal(info$osf_type, "private")
  expect_equal(info$public, FALSE)

  skip("long")
  obs <- osf_links(psychsci)
  ids <- osf_check_id(obs$text)
})

test_that("osf_check_id", {
  # 5-letter
  osf_id <- "pngda"
  checked_id <- osf_check_id(osf_id)
  expect_equal(checked_id, osf_id)

  # vector
  osf_id <- c("pngda", "8c3kb")
  checked_id <- osf_check_id(osf_id)
  expect_equal(checked_id, osf_id)

  # vector with invalid values
  osf_id <- c("pngda", "xxx", "8c3kb")
  expect_warning(checked_id <- osf_check_id(osf_id))
  expect_equal(checked_id, c("pngda", NA, "8c3kb"))

  # waterbutler id
  osf_id <- "6846ed88e49694cd45ab8375"
  checked_id <- osf_check_id(osf_id)
  expect_equal(checked_id, osf_id)

  # invalidwaterbutler id
  osf_id <- "6846ed894cd45ab8375"
  expect_warning(checked_id <- osf_check_id(osf_id))
  expect_true(is.na(checked_id))

  # urls
  osf_id <- "https://osf.io/pngda"
  checked_id <- osf_check_id(osf_id)
  expect_equal(checked_id, "pngda")

  osf_id <- "http://osf.io/pngda"
  checked_id <- osf_check_id(osf_id)
  expect_equal(checked_id, "pngda")

  # url with no http
  osf_id <- "osf.io/pngda"
  checked_id <- osf_check_id(osf_id)
  expect_equal(checked_id, "pngda")

  # deal with rogue whitespace
  osf_id <- "osf .io/pngda"
  checked_id <- osf_check_id(osf_id)
  expect_equal(checked_id, "pngda")

  osf_id <- "xx"
  expect_warning(checked_id <- osf_check_id(osf_id))
  expect_true(is.na(checked_id))

  # view-only link
  osf_id <- "https://osf.io/pngda/?view_only=5acf039f24ac4ea28afec473548dd7f4"
  checked_id <- osf_check_id(osf_id)
  expect_equal(checked_id, "pngda")
})

test_that("osf_get_all_pages", {
  skip_on_cran()
  skip_on_covr()
  skip_if_not(osf_api_check() == "ok")

  osf_api <- getOption("papercheck.osf.api")

  # fewer than 10
  url <- sprintf("%s/nodes/pngda/files/osfstorage/", osf_api)
  data <- osf_get_all_pages(url)
  files <- c("test-folder", "README", "papercheck.png")
  expect_true(all(files %in% data$attributes$name))

  # more than 10
  url <- sprintf("%s/nodes/yt32c/files/osfstorage/", osf_api)
  data <- osf_get_all_pages(url)
  expect_equal(nrow(data), 14)

  # no results
  url <- sprintf("%s/nodes/y6a34/files/osfstorage/", osf_api)
  data <- osf_get_all_pages(url)
  expect_equal(data, list())
})

test_that("osf_files", {
  osf_id <- "pngda"
  data <- osf_files(osf_id)
  expect_equal(nrow(data), 3)

  osf_id <- "yt32c"
  data <- osf_files(osf_id)
  expect_equal(nrow(data), 14)
  expect_equal(data$filetype, rep("data", 14))

  osf_id <- "y6a34"
  data <- osf_files(osf_id)
  expect_equal(nrow(data), 0)
})

test_that("osf_children", {
  osf_id <- "pngda"
  data <- osf_children(osf_id)
  expect_equal(nrow(data), 2)

  osf_id <- "y6a34"
  data <- osf_children(osf_id)
  expect_equal(nrow(data), 0)
})

test_that("osf_info", {
  skip("long")
  # project
  osf_id <- "pngda"
  info <- osf_info(osf_id)
  expect_equal(info$osf_id, osf_id)
  expect_equal(info$osf_type, "nodes")
  expect_equal(info$name, "Papercheck Test")

  # component
  osf_id <- "6nt4v"
  info <- osf_info(osf_id)
  expect_equal(info$osf_id, osf_id)
  expect_equal(info$osf_type, "nodes")
  expect_equal(info$name, "Processed Data")

  # file
  osf_id <- "75qgk"
  info <- osf_info(osf_id)
  expect_equal(info$osf_id, osf_id)
  expect_equal(info$osf_type, "files")
  expect_equal(info$kind, "file")
  expect_equal(info$name, "processed-data.csv")

  # preprint
  osf_id <- "xp5cy"
  info <- osf_info(osf_id)
  expect_true(grepl(osf_id, info$osf_id))
  expect_equal(info$osf_type, "preprints")
  expect_equal(info$name, "Understanding mixed effects models through data simulation")

  # user
  # osf_id <- "4i578"
  # info <- osf_info(osf_id)
  # expect_equal(info$osf_id, osf_id)
  # expect_equal(info$osf_type, "users")
  # expect_equal(info$name, "Lisa DeBruine")

  # reg
  osf_id <- "8c3kb"
  info <- osf_info(osf_id)
  expect_equal(info$osf_id, osf_id)
  expect_equal(info$osf_type, "registrations")
  expect_equal(info$name, "Understanding mixed effects models through data simulation")

  # private
  osf_id <- "ybm3c"
  info <- osf_info(osf_id)
  expect_equal(info$osf_id, osf_id)
  expect_equal(info$osf_type, "private")
  expect_equal(info$public, FALSE)

  # view-only (private)
  osf_id <- "https://osf.io/ybm3c/?view_only=5acf039f24ac4ea28afec473548dd7f4"
  info <- osf_info(osf_id)
  expect_equal(info$osf_id, "ybm3c")
  expect_equal(osf_type, "private")

  # view-only (public)
  osf_id <- "https://osf.io/pngda/?view_only=5acf039f24ac4ea28afec473548dd7f4"
  info <- osf_info(osf_id)
  expect_equal(info$osf_id, "pngda")
  expect_equal(info$osf_type, "nodes")
  expect_equal(info$name, "Papercheck Test")

  # invalid
  osf_id <- "xx"
  expect_warning(info <- osf_info(osf_id))
  expect_equal(info$osf_id, osf_id)
  expect_equal(info$osf_type, "invalid")

  # valid but not found
  osf_id <- "xxxxx"
  expect_warning(info <- osf_info(osf_id))
  expect_equal(info$osf_id, osf_id)
  expect_equal(info$osf_type, "unfound")
})


test_that("osf_retrieve", {
  skip_on_cran()
  skip_on_covr()
  skip_if_not(osf_api_check() == "ok")

  examples <- c(project = "pngda",
                component = "https://osf.io/6nt4v",
                private = "ybm3c",
                file = "osf.io/75qgk",
                preprint = "xp5cy",
                #user = "4i578",
                reg = "8c3kb",
                duplicate = "6nt4v",
                bad = "xx")
  osf_url <- data.frame(
    url = examples,
    type = names(examples)
  )
  expect_warning(table <- osf_retrieve(osf_url))
  expect_true(!"project" %in% names(table))
  expect_equal(table$url, osf_url$url)
  expect_equal(table$type, osf_url$type)
  expect_equal(table[2, 3:10], table[7, 3:10], ignore_attr = TRUE)

  # vector
  osf_url <- "pngda"
  table <- osf_retrieve(osf_url)
  expect_equal(table$osf_url, osf_url)
  expect_equal(table$name, "Papercheck Test")

  # table with id_col, find project
  osf_url <- data.frame(
    id = 100,
    osf_id = "pngda"
  )
  id_col <- "osf_id"
  table <- osf_retrieve(osf_url, id_col, find_project = TRUE)
  expect_equal(table$osf_id, osf_url$osf_id)
  expect_equal(table$name, "Papercheck Test")
  expect_equal(table$project, "pngda")

  # recursive
  osf_url <- "yt32c"
  table <- osf_retrieve(osf_url, recursive = TRUE)
  expect_equal(nrow(table), 15)
  expect_equal(table$parent, rep(c("ckjef", "yt32c"), c(1, 14)))

  # recursive with duplicates and NA vector
  osf_url <- c("yt32c", "yt32c", NA)
  table <- osf_retrieve(osf_url, recursive = TRUE)
  expect_equal(nrow(table), 1 + 14)

  # recursive with duplicates and NA table
  osf_url <- data.frame(parent_id = c("yt32c", "yt32c", NA),
                        n = 1:3)
  expect_warning(table <- osf_retrieve(osf_url, recursive = TRUE))
  expect_equal(nrow(table), 3 + 14)
  expect_equal(table$n, c(1:3, rep(NA, 14)))

  # only one URL
  osf_url <- "https://osf.io/pngda"
  table <- osf_retrieve(osf_url)
  expect_equal(table$name, "Papercheck Test")

  osf_url <- "https://osf.io/ybm3c/?view_only=5acf039f24ac4ea28afec473548dd7f4"
  table <- osf_retrieve(osf_url)
  expect_equal(table$osf_url, osf_url)
  expect_equal(table$osf_id, "ybm3c")

  # children of private
  osf_url <- "https://osf.io/ybm3c/?view_only=5acf039f24ac4ea28afec473548dd7f4"
  table <- osf_retrieve(osf_url, recursive = TRUE)
  expect_equal(table$osf_url, osf_url)
  expect_equal(table$osf_id, "ybm3c")

  # no links
  paper <- psychsci[[180]]
  osf_url <- osf_links(paper)
  info <- osf_retrieve(osf_url, recursive = TRUE, find_project = TRUE)
  expect_equal(nrow(info), 0)
  expect_equal(osf_url, info)
})

test_that("osf_retrieve recursive", {
  skip_on_cran()
  skip_on_covr()
  skip_if_not(osf_api_check() == "ok")

  # folders can only have wb IDs,
  # files only have wb IDs until someone looks at them on the web
  #  and then they get 5-letter guids
  # currently just using wb IDs for all files

  osf_url <- "j3gcx"
  info <- osf_retrieve(osf_url, recursive = TRUE)
  folders <- paste0("nest-", 1:4) |> c("empty")
  files <- paste0("test-", 1:4, ".txt")
  expect_true(all(folders %in% info$name))
  expect_true(all(files %in% info$name))
})

test_that("osf_id vs wb_id", {
  skip_on_cran()
  skip_on_covr()
  skip_if_not(osf_api_check() == "ok")

  osf_id <- "k6gbt"
  osf_info <- osf_info(osf_id)

  osf_id <- "6846ed88e49694cd45ab8375"
  wb_info <- osf_info(osf_id)

  expect_equal(osf_info[, 2:11], wb_info[, 2:11])
})


test_that("osf_parent_project", {
  skip_on_cran()
  skip_on_covr()
  skip_if_not(osf_api_check() == "ok")

  # has parent project
  osf_id <- "yt32c"
  parent <- osf_parent_project(osf_id)
  expect_equal(parent, "pngda")

  # is a parent project
  osf_id <- "pngda"
  parent <- osf_parent_project(osf_id)
  expect_equal(parent, "pngda")

  # preprint
  osf_id <- "xp5cy"
  parent <- osf_parent_project(osf_id)
  expect_equal(parent, "3cz2e")

  # invalid ID
  osf_id <- "pda"
  expect_warning(parent <- osf_parent_project(osf_id))
  expect_true(is.na(parent))
})

test_that("summarize_contents", {
  # handle zero results and/or OSF down
  summary <- summarize_contents(data.frame())
  expect_equal(nrow(summary), 0)

  skip_on_cran()
  skip_on_covr()
  skip_if_not(osf_api_check() == "ok")

  osf_id <- "pngda"
  contents <- osf_retrieve(osf_id, recursive = TRUE)

  summary <- summarize_contents(contents)

  readme <- dplyr::filter(summary, name == "README")
  expect_equal(unique(readme$file_category), "readme")
})

test_that("add_filetype", {
  # edge case classification
  files <- c(
    "datarelease.pdf" = "text",    # pdf cannot be data or code
    "my_r_code.pdf" = "text",
    "data.sas" = "stats",          # sas is always code
    "codebook.sas" = "stats",
    "codebook.pdf" = "text"
  )
  ft <- filetype(names(files))
  expect_equal(ft, files)
})

test_that("edge case summarise", {
  # edge case classification
  # category is from OSF, so can be: analysis, communication, data, hypothesis, instrumentation, methods and measures, procedure, project, software, other, but mostly uncategorized (NA)
  contents <- dplyr::tribble(
    ~name,              ~category, ~classify,
    "datarelease.pdf",  NA,         NA,        # pdf cannot be data or code
    "data.pdf",         "data",     NA,        # what about qual data?
    "my_r_code.pdf",    NA,         NA,
    "readme.xls",       "project",  "data",    # is an xls file always data?
    "data.sas",         NA,         "code",    # sas is always code
    "codebook.sas",     NA,         "code",
    "readme.sas",       NA,         "code",
    "codebook.pdf",     NA,         "codebook" # not a great format but possible
  )
  contents$filetype <- filetype(contents$name)

  summary <- summarize_contents(contents)
  expect_equal(summary$file_category, contents$classify)
})


test_that("rate limiting", {
  skip("long")

  osf_id <- "pngda"

  for (i in 1:110) {
    info <- osf_info(osf_id)
  }
})

test_that("osf_file_download", {
  expect_true(is.function(papercheck::osf_file_download))

  expect_warning(x <- osf_file_download("notanid"))
  expect_null(x)

  skip_on_cran()
  skip_on_covr()

  osf_id <- "6nt4v" # processed data - 1 file

  op <- capture_messages(
    dl <- osf_file_download(osf_id)
  )
  f <- file.path(getwd(), osf_id)
  expect_true(dir.exists(f))
  expect_true(file.path(f, "processed-data.csv") |> file.exists())
  expect_equal(dl$folder, osf_id)
  expect_equal(dl$downloaded, TRUE)
  expect_equal(dl$osf_id, "6846ed6a29684b023953943e")

  ## second download with existing file
  op <- capture_messages(
    dl <- osf_file_download(osf_id)
  )
  folder <- paste0(osf_id, "_1")
  expect_equal(dl$folder, folder)
  f2 <- file.path(getwd(), folder)
  expect_true(dir.exists(f2))

  unlink(f, recursive = TRUE)
  unlink(f2, recursive = TRUE)

  # too small max_file_size
  op <- capture_messages(
    dl <- osf_file_download(osf_id, max_file_size = .0001)
  )
  expect_equal(nrow(dl), 1)
  expect_equal(dl$folder, osf_id)
  expect_equal(dl$osf_id, "6846ed6a29684b023953943e")
  expect_equal(dl$downloaded, FALSE)
  f <- file.path(getwd(), osf_id)
  expect_true(dir.exists(f))
  expect_equal(list.files(f), character(0))
  unlink(f, recursive = TRUE)

  # too small max_download_size
  op <- capture_messages(
    dl <- osf_file_download(osf_id, max_download_size = .0001)
  )
  expect_equal(nrow(dl), 1)
  expect_equal(dl$folder, osf_id)
  expect_equal(dl$osf_id, "6846ed6a29684b023953943e")
  expect_equal(dl$downloaded, FALSE)
  f <- file.path(getwd(), osf_id)
  expect_true(dir.exists(f))
  expect_equal(list.files(f), character(0))
  unlink(f, recursive = TRUE)

  ## truncate
  osf_id <- "j3gcx"
  expect_warning(op <- capture_messages(
    dl <- osf_file_download(osf_id, max_folder_length = 3)
  ), "truncated")
  f <- file.path(getwd(), osf_id, "nes")
  expect_true(dir.exists(f))
  f <- file.path(getwd(), osf_id, "data.xlsx")
  expect_true(file.exists(f))
  exp_paths <- c("README", "data.xlsx",
                 "nes/README",
                 "nes/test-1.txt",
                 "nes/nes/test-2.txt",
                 "nes/nes/nes/test-3.txt",
                 "nes/nes/nes/nes/test-4.txt")
  expect_equal(dl$path, exp_paths)
  f <- file.path(getwd(), osf_id)
  unlink(f, recursive = TRUE)

  ## multiple osf_ids
  osf_id <- c("6nt4v", "j3gcx")
  dl <- osf_file_download(osf_id)
  expect_equal(dl$folder, rep(osf_id, c(1, 7)))
  f <- file.path(getwd(), osf_id)
  expect_true(dir.exists(f) |> all())
  expect_true(file.path(f[[1]], "processed-data.csv") |> file.exists())
  expect_true(file.path(f[[2]], "nest-1/README") |> file.exists())
  unlink(f, recursive = TRUE)
})

test_that("osf_file_download long", {
  skip("long test")

  osf_id <- "j3gcx" # raw data - nesting and duplicates

  # nested folders
  dl <- osf_file_download(osf_id)
  expect_true("nest-1/nest-2/nest-3/nest-4/test-4.txt" %in% dl)
  f <- file.path(getwd(), osf_id)
  expect_true(dir.exists(f))
  expect_true(file.path(f, "README") |> file.exists())
  expect_true(file.path(f, "nest-1") |> dir.exists())
  unlink(f, recursive = TRUE)

  # unnested with duplicate file names
  dl <- osf_file_download(osf_id, ignore_folder_structure = TRUE)
  expect_true("test-4.txt" %in% dl)
  f <- file.path(getwd(), osf_id)
  expect_true(dir.exists(f))
  expect_true(file.path(f, "README") |> file.exists())
  expect_true(file.path(f, "README_copy") |> file.exists())
  expect_true(file.path(f, "test-4.txt") |> file.exists())
  expect_false(file.path(f, "nest-1") |> dir.exists())
  unlink(f, recursive = TRUE)
})

test_that("osf_file_download retry", {
  skip("very long process")
  osf_id <- "bnq5j"
  dl <- osf_file_download(osf_id)
  f <- file.path(getwd(), osf_id)
  expect_true(dir.exists(f))
  unlink(f, recursive = TRUE)

  # in if (nrow(files) == 0) { : argument is of length zero
  osf_id <- "t9j8e"
  dl <- osf_file_download(osf_id)
  f <- file.path(getwd(), osf_id)
  expect_false(dir.exists(f))

  # lots of links
  osf_id <- osf_links(psychsci[50:60])$text
  dl <- osf_file_download(osf_id, max_file_size = 0.01)
  file.path(getwd(), names(dl)) |> unlink(recursive = TRUE)

  # only folder left after omissions ----
  osf_id <- "3uqx6"
  dl <- osf_file_download(osf_id, max_file_size = 0.01)

  # downloaded == NA
  osf_id <- "rkb96"
  dl <- osf_file_download(osf_id, max_file_size = 0.01)
})


