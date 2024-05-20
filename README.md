
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

## Check Stats

``` r
statcheck <- stats(studies)

check <- statcheck |>
  dplyr::filter(error == TRUE) |>
  dplyr::select(file, computed_p:one_tailed_in_txt)
```

| file         | computed_p | raw                          | error | decision_error | one_tailed_in_txt |
|:-------------|-----------:|:-----------------------------|:------|:---------------|:------------------|
| eyecolor.xml |  0.0286696 | Z = 2.188, p = 0.091         | TRUE  | TRUE           | FALSE             |
| prereg.xml   |  0.0245666 | t(288.61) = -2.26, p = 0.012 | TRUE  | FALSE          | FALSE             |
| prereg.xml   |  0.0040024 | t(305.34) = -2.90, p = 0.002 | TRUE  | FALSE          | FALSE             |

``` r
p <- check_p_values(studies)
```

| file         | p_comp | reported_p | p_decimals | text                                                                                                                                                                                                                                                                                                                                                                                               |
|:-------------|:-------|-----------:|-----------:|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| eyecolor.xml | =      |      0.012 |          3 | = 0.322, z = 2.52, p = 0.012), but not male partners (B = –0.059, S.E.                                                                                                                                                                                                                                                                                                                             |
| eyecolor.xml | =      |      0.849 |          3 | = 0.31, z = –0.19, p = 0.849) and paternal eye color significantly predicted the eye color of male partners (B = 0.75, S.E.                                                                                                                                                                                                                                                                        |
| eyecolor.xml | =      |      0.019 |          3 | = 0.318, z = 2.355, p = 0.019), but not female partners (B = 0.049, S.E.                                                                                                                                                                                                                                                                                                                           |
| eyecolor.xml | =      |      0.879 |          3 | = 0.32, z = 0.152, p = 0.879).                                                                                                                                                                                                                                                                                                                                                                     |
| eyecolor.xml | =      |      0.266 |          3 | = 0.236, z = 1.113, p = 0.266).                                                                                                                                                                                                                                                                                                                                                                    |
| eyecolor.xml | =      |      0.403 |          3 | = 0.313, z = 0.836, p = 0.403) more than women’s partners (B = 0.472, S.E.                                                                                                                                                                                                                                                                                                                         |
| eyecolor.xml | =      |      0.130 |          2 | = 0.311, z = 1.515, p = 0.13) and paternal eye color did not predict the eye color of women’s partners (B = 0.309, S.E.                                                                                                                                                                                                                                                                            |
| eyecolor.xml | =      |      0.337 |          3 | = 0.321, z = 0.96, p = 0.337) more than men’s partners (B = 0.511, S.E.                                                                                                                                                                                                                                                                                                                            |
| eyecolor.xml | =      |      0.100 |          1 | = 0.311, z = 1.645, p = 0.1).                                                                                                                                                                                                                                                                                                                                                                      |
| eyecolor.xml | =      |      0.029 |          3 | = 0.481, Z = 2.188, p = 0.029), while men’s female partners’ eye color was best predicted by maternal eye color (B = 1.072, S.E.                                                                                                                                                                                                                                                                   |
| eyecolor.xml | =      |      0.027 |          3 | = 0.486, Z = 2.207, p = 0.027).                                                                                                                                                                                                                                                                                                                                                                    |
| eyecolor.xml | =      |      0.076 |          3 | = 0.478, Z = 1.774, p = 0.076).                                                                                                                                                                                                                                                                                                                                                                    |
| eyecolor.xml | =      |      0.091 |          3 | = 0.489, Z = 2.188, p = 0.091), maternal eye color was the only positive predictor in the first step of this analysis (B = 0.694, S.E.                                                                                                                                                                                                                                                             |
| eyecolor.xml | =      |      0.196 |          3 | = 0.537, Z = 1.292, p = 0.196).                                                                                                                                                                                                                                                                                                                                                                    |
| incest.xml   | =      |      0.019 |          3 | Our main, omnibus analysis showed a significant three-way interaction among incest type, participant sex, and sibling type (Estimate = 0.285, t(578.003) = 2.359, p = 0.019).                                                                                                                                                                                                                      |
| incest.xml   | =      |      0.005 |          3 | Our analysis of moral wrongness scores for sibling incest scores showed a significant interaction between participant sex and sibling type (Estimate = -0.559, t(578) = -2.84, p = 0.005).                                                                                                                                                                                                         |
| incest.xml   | =      |      0.044 |          3 | Women with brothers only tended to view sibling incest more negatively than did women with sisters only (Estimate = 0.179, t(452) = 2.022, p = 0.044) while men with brothers only tended to view sibling incest less negatively than did men with sisters only (Estimate = -0.38, t(126) = -1.933, p = 0.055).                                                                                    |
| incest.xml   | =      |      0.055 |          3 | Women with brothers only tended to view sibling incest more negatively than did women with sisters only (Estimate = 0.179, t(452) = 2.022, p = 0.044) while men with brothers only tended to view sibling incest less negatively than did men with sisters only (Estimate = -0.38, t(126) = -1.933, p = 0.055).                                                                                    |
| incest.xml   | =      |      0.170 |          2 | In contrast, our analysis of moral wrongness scores for parental incest scores showed no significant interaction between participant sex and sibling type (Estimate = -0.268, t(578) = -1.373, p = 0.17).                                                                                                                                                                                          |
| prereg.xml   | \<     |      0.001 |          3 | The difference between measurements (M = 2.47, SD = 1.71) was large, t(86) = 13.47, p \< 0.001, Hedges’ g z = 1.43, 95% CI \[1.13;1.73\], see Figure 1.                                                                                                                                                                                                                                            |
| prereg.xml   | \<     |      0.001 |          3 | The difference between measurements (M = 2.35, SD = 1.69) was analyzed with a dependent t-test, t(85) = 12.87, p \< 0.001, Hedges’ g z = 1.38, 95% CI \[1.08;1.67\].                                                                                                                                                                                                                               |
| prereg.xml   | \<     |      0.001 |          3 | Four Welch’s independent t-tests using the TOST approach indicated statistical equivalence for the difference between conditions for the perceived benefits, t(311.65) = -3.45, p \< 0.001, costs, t(288.61) = -2.26, p = 0.012, how likely researchers were to pre-register, t(323.68) = -4.55, p \< 0.001, and percentage of studies they planned to pre-register, t(305.34) = -2.90, p = 0.002. |
| prereg.xml   | =      |      0.012 |          3 | Four Welch’s independent t-tests using the TOST approach indicated statistical equivalence for the difference between conditions for the perceived benefits, t(311.65) = -3.45, p \< 0.001, costs, t(288.61) = -2.26, p = 0.012, how likely researchers were to pre-register, t(323.68) = -4.55, p \< 0.001, and percentage of studies they planned to pre-register, t(305.34) = -2.90, p = 0.002. |
| prereg.xml   | \<     |      0.001 |          3 | Four Welch’s independent t-tests using the TOST approach indicated statistical equivalence for the difference between conditions for the perceived benefits, t(311.65) = -3.45, p \< 0.001, costs, t(288.61) = -2.26, p = 0.012, how likely researchers were to pre-register, t(323.68) = -4.55, p \< 0.001, and percentage of studies they planned to pre-register, t(305.34) = -2.90, p = 0.002. |
| prereg.xml   | =      |      0.002 |          3 | Four Welch’s independent t-tests using the TOST approach indicated statistical equivalence for the difference between conditions for the perceived benefits, t(311.65) = -3.45, p \< 0.001, costs, t(288.61) = -2.26, p = 0.012, how likely researchers were to pre-register, t(323.68) = -4.55, p \< 0.001, and percentage of studies they planned to pre-register, t(305.34) = -2.90, p = 0.002. |
