
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
pdf <- demofiles("pdf")[2]
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
grobid_dir <- demofiles()
papers <- read_grobid(grobid_dir)

# select sentences in the intros containing the text "previous"
previous <- search_text(papers, "previous", 
                        section = "intro", 
                        return = "sentence")
```

``` r
knitr::kable(previous)
```

| text                                                                                                                                                                                                                                                                                                                                                                                                                  | section | header       | div |   p |   s | id         |
|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------|:-------------|----:|----:|----:|:-----------|
| Royzman et al’s non-replication potentially calls into question the reliability of previously reported links between having an other-sex sibling and moral opposition to third-party sibling incest.                                                                                                                                                                                                                  | intro   | Introduction |   1 |   3 |   3 | incest.xml |
| Previous research has shown that making cost-benefit analyses of using statistical approaches explicit can influence researchers’ attitudes.                                                                                                                                                                                                                                                                          | intro   | \[div-01\]   |   1 |   8 |   5 | prereg.xml |
| When exploring difference in responses between previous experience with pre-registration, we see a clear trend where reasearchers who have pre-registered studies in their own research indicate pre-registration is more beneficial, and indicate higher a higher likelihood of pre-registering studies in the future, and higher percentage of studies for which they would consider pre-registering (see Table 2). | intro   | Attitude     |   3 |   7 |   1 | prereg.xml |

## Modules

Papercheck is designed modularly, so you can add modules to check for
anything. It comes with a set of pre-defined modules, and we hope people
will share more modules.

You can see the list of built-in modules with the function below.

``` r
module_list()
#>              name                     title type
#> 1    ai-summarise        Summarise Sections   ai
#> 2    all-p-values         List All P-Values text
#> 3        all-urls             List All URLs text
#> 4     imprecise-p        Imprecise P-Values code
#> 5        marginal     Marginal Significance text
#> 6       osf-check Check Status of OSF Links code
#> 7 retractionwatch           RetractionWatch code
#> 8  sample-size-ml               Sample Size   ml
#>                                                                                                                                 path
#> 1    /private/var/folders/sw/fftq36pn4wj66bj_pjvh5fpw0000gn/T/RtmpiP9OCw/temp_libpath2899724073b/papercheck/modules/ai-summarise.mod
#> 2    /private/var/folders/sw/fftq36pn4wj66bj_pjvh5fpw0000gn/T/RtmpiP9OCw/temp_libpath2899724073b/papercheck/modules/all-p-values.mod
#> 3        /private/var/folders/sw/fftq36pn4wj66bj_pjvh5fpw0000gn/T/RtmpiP9OCw/temp_libpath2899724073b/papercheck/modules/all-urls.mod
#> 4     /private/var/folders/sw/fftq36pn4wj66bj_pjvh5fpw0000gn/T/RtmpiP9OCw/temp_libpath2899724073b/papercheck/modules/imprecise-p.mod
#> 5        /private/var/folders/sw/fftq36pn4wj66bj_pjvh5fpw0000gn/T/RtmpiP9OCw/temp_libpath2899724073b/papercheck/modules/marginal.mod
#> 6       /private/var/folders/sw/fftq36pn4wj66bj_pjvh5fpw0000gn/T/RtmpiP9OCw/temp_libpath2899724073b/papercheck/modules/osf-check.mod
#> 7 /private/var/folders/sw/fftq36pn4wj66bj_pjvh5fpw0000gn/T/RtmpiP9OCw/temp_libpath2899724073b/papercheck/modules/retractionwatch.mod
#> 8  /private/var/folders/sw/fftq36pn4wj66bj_pjvh5fpw0000gn/T/RtmpiP9OCw/temp_libpath2899724073b/papercheck/modules/sample-size-ml.mod
```

To run a built-in module on a paper, you can reference it by name.

``` r
p <- module_run(papers, "all-p-values")

head(p$table)
#> # A tibble: 6 × 7
#>   text      section header     div     p     s id          
#>   <chr>     <chr>   <chr>    <dbl> <dbl> <int> <chr>       
#> 1 p = 0.012 intro   [div-01]     1     4     6 eyecolor.xml
#> 2 p = 0.849 intro   [div-01]     1     4     7 eyecolor.xml
#> 3 p = 0.019 intro   [div-01]     1     4     8 eyecolor.xml
#> 4 p = 0.879 intro   [div-01]     1     4     9 eyecolor.xml
#> 5 p = 0.266 intro   [div-01]     1     4    11 eyecolor.xml
#> 6 p = 0.403 intro   [div-01]     1     4    13 eyecolor.xml
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
  dplyr::select(id, computed_p:one_tailed_in_txt)
```

| id           | computed_p | raw                          | error | decision_error | one_tailed_in_txt |
|:-------------|-----------:|:-----------------------------|:------|:---------------|:------------------|
| eyecolor.xml |  0.0286696 | Z = 2.188, p = 0.091         | TRUE  | TRUE           | FALSE             |
| prereg.xml   |  0.0245666 | t(288.61) = -2.26, p = 0.012 | TRUE  | FALSE          | FALSE             |
| prereg.xml   |  0.0040024 | t(305.34) = -2.90, p = 0.002 | TRUE  | FALSE          | FALSE             |
