
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

Convert a PDF to grobid XML format, then read it in as a scienceverse
paper object.

``` r
pdf <- demofile("pdf")[2]
grobid <- pdf2grobid(pdf)
paper <- read_grobid(grobid)
```

Search the returned text. The regex pattern below searches for text that
looks like statistical values (e.g., `N=313` or `p = 0.17`).

``` r
pattern <- "[^\\s\\(\\)]+\\s*(=|<)\\s*[0-9\\.-]+"
text <- search_text(paper, pattern, 
                    return = "match", 
                    perl = TRUE)
```

| text              | section  | header   | div |   p |   s | id         |
|:------------------|:---------|:---------|----:|----:|----:|:-----------|
| N=313             | abstract | Abstract |   0 |   1 |   4 | incest.xml |
| N=269             | abstract | Abstract |   0 |   1 |   4 | incest.xml |
| Estimate = 0.285  | results  | Results  |   5 |   1 |   1 | incest.xml |
| p = 0.019         | results  | Results  |   5 |   1 |   1 | incest.xml |
| Estimate = -0.559 | results  | Results  |   5 |   2 |   1 | incest.xml |
| p = 0.005         | results  | Results  |   5 |   2 |   1 | incest.xml |
| Estimate = 0.179  | results  | Results  |   5 |   2 |   2 | incest.xml |
| p = 0.044         | results  | Results  |   5 |   2 |   2 | incest.xml |
| Estimate = -0.38  | results  | Results  |   5 |   2 |   2 | incest.xml |
| p = 0.055         | results  | Results  |   5 |   2 |   2 | incest.xml |
| Estimate = -0.268 | results  | Results  |   5 |   2 |   3 | incest.xml |
| p = 0.17          | results  | Results  |   5 |   2 |   3 | incest.xml |

## Batch Processing

``` r
# read in all the XML files in the demo directory
grobid_dir <- demofile()
papers <- read_grobid(grobid_dir)

# select paragraphs in the intros containing the text "hypothesi"
hypotheses <- search_text(papers, "hypothesi", 
                          section = "intro", 
                          return = "paragraph")
```

## Modules

``` r
module_list()
#>              name                 title type
#> 1    ai-summarise    Summarise Sections   ai
#> 2    all-p-values     List All P-Values text
#> 3     imprecise-p    Imprecise P-Values code
#> 4        marginal Marginal Significance text
#> 5       osf-links       Check OSF Links code
#> 6 retractionwatch       RetractionWatch code
#>                                                                                                            path
#> 1    /Library/Frameworks/R.framework/Versions/4.4-x86_64/Resources/library/papercheck/modules/ai-summarise.json
#> 2    /Library/Frameworks/R.framework/Versions/4.4-x86_64/Resources/library/papercheck/modules/all-p-values.json
#> 3     /Library/Frameworks/R.framework/Versions/4.4-x86_64/Resources/library/papercheck/modules/imprecise-p.json
#> 4        /Library/Frameworks/R.framework/Versions/4.4-x86_64/Resources/library/papercheck/modules/marginal.json
#> 5       /Library/Frameworks/R.framework/Versions/4.4-x86_64/Resources/library/papercheck/modules/osf-links.json
#> 6 /Library/Frameworks/R.framework/Versions/4.4-x86_64/Resources/library/papercheck/modules/retractionwatch.json
```

``` r
p <- module_run(papers, "all-p-values")

head(p)
#> # A tibble: 6 × 8
#>   text      section header     div     p     s id           file        
#>   <chr>     <chr>   <chr>    <dbl> <dbl> <int> <chr>        <chr>       
#> 1 p = 0.012 intro   [div-01]     1     4     6 eyecolor.xml eyecolor.xml
#> 2 p = 0.849 intro   [div-01]     1     4     7 eyecolor.xml eyecolor.xml
#> 3 p = 0.019 intro   [div-01]     1     4     8 eyecolor.xml eyecolor.xml
#> 4 p = 0.879 intro   [div-01]     1     4     9 eyecolor.xml eyecolor.xml
#> 5 p = 0.266 intro   [div-01]     1     4    11 eyecolor.xml eyecolor.xml
#> 6 p = 0.403 intro   [div-01]     1     4    13 eyecolor.xml eyecolor.xml
```

## Ask ChatGPT

``` r
# ask chatGPT a question
query <- "What is the hypothesis of this study?"
gpt_hypo <- gpt(hypotheses, query, group_by = "id")
```

| id           | answer                                                                                                                                                                                                 |     cost |
|:-------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------:|
| eyecolor.xml | The hypothesis of this study is to test the matching hypothesis, sex-linked heritable preference hypothesis, and positive sexual imprinting hypothesis in relation to eye color and partner selection. | 0.000612 |
| incest.xml   | The hypothesis of this study is that humans possess adaptations to reduce inbreeding, and that the strong moral opposition to incest plays an important role in preventing inbreeding.                 | 0.000216 |
| prereg.xml   | The hypothesis of this study is that more efficient study designs might increase the willingness to pre-register in psychological science.                                                             | 0.000608 |

## Check Stats

``` r
statcheck <- stats(papers)

check <- statcheck |>
  dplyr::filter(error == TRUE) |>
  dplyr::select(file, computed_p:one_tailed_in_txt)
```

| file         | computed_p | raw                          | error | decision_error | one_tailed_in_txt |
|:-------------|-----------:|:-----------------------------|:------|:---------------|:------------------|
| eyecolor.xml |  0.0286696 | Z = 2.188, p = 0.091         | TRUE  | TRUE           | FALSE             |
| prereg.xml   |  0.0245666 | t(288.61) = -2.26, p = 0.012 | TRUE  | FALSE          | FALSE             |
| prereg.xml   |  0.0040024 | t(305.34) = -2.90, p = 0.002 | TRUE  | FALSE          | FALSE             |
