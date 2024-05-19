
<!-- README.md is generated from README.Rmd. Please edit that file -->

# papercheck <img src="man/figures/logo.png" align="right" height="120" alt="" />

<!-- badges: start -->
<!-- badges: end -->

The goal of papercheck is to automatically check scientific papers for
best practices.

## Installation

You can install the development version of papercheck from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("scienceverse/papercheck")
```

## Example

``` r
library(papercheck)
```

``` r
grobid_dir <- system.file("grobid", package="papercheck")
filename <- file.path(grobid_dir, "incest.xml")
s <- read_grobid(filename)
pattern <- "[^\\s\\(\\)]+\\s*(=|<)\\s*[0-9\\.-]+"
text <- search_text(s, pattern, return = "match", perl = TRUE)
```

| text              | section  | header   | div |   p |   s | file       |
|:------------------|:---------|:---------|----:|----:|----:|:-----------|
| N=313             | abstract | Abstract |   0 |   1 |   4 | incest.xml |
| Estimate = 0.285  | results  | Results  |   5 |   1 |   1 | incest.xml |
| Estimate = -0.559 | results  | Results  |   5 |   2 |   1 | incest.xml |
| Estimate = 0.179  | results  | Results  |   5 |   2 |   2 | incest.xml |
| Estimate = -0.268 | results  | Results  |   5 |   2 |   3 | incest.xml |

## Batch Processing

``` r
# read in all the XML files in this directory
studies <- read_grobid(grobid_dir)

# select paragraphs in the intros containing the text "hypothesi"
hypotheses <- search_text(studies, "hypothesi", 
                          section = "intro", 
                          return = "paragraph")
```

## Ask ChatGPT

``` r
# ask chatGPT a question
query <- "What is the hypothesis of this study?"
gpt_hypo <- gpt(hypotheses, query, group_by = "file")
```

| file         | answer                                                                                                                                                                                                 |     cost |
|:-------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------:|
| eyecolor.xml | The hypothesis of this study is to test the matching hypothesis, sex-linked heritable preference hypothesis, and positive sexual imprinting hypothesis in relation to eye color and partner selection. | 0.000612 |
| incest.xml   | The hypothesis of this study is that humans possess adaptations to reduce inbreeding, and that the strong moral opposition to incest plays an important role in preventing inbreeding.                 | 0.000216 |
| prereg.xml   | The hypothesis of this study is that more efficient study designs might increase the willingness to pre-register in psychological science.                                                             | 0.000608 |
