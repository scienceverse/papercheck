
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

### Load from XML

The function `read_grobid()` can read XML files in
[TEI](https://tei-c.org/) format created by
[grobid](https://grobid.readthedocs.io/).

The example below uses some previously created XML files that are
included with papercheck. You can [use grobid on your own
paper](https://huggingface.co/spaces/kermitt2/grobid) here.

``` r
grobid_dir <- system.file("grobid", package="papercheck")
filename <- file.path(grobid_dir, "incest.xml")
s <- read_grobid(filename)
```

## Full Text

You can access a parsed table of the full text of the paper via
`s$full_text`

``` r
dplyr::count(s$full_text, section)
#>      section  n
#> 1   abstract  6
#> 2 discussion 11
#> 3      intro 13
#> 4     method 20
#> 5    results  7
```

However, you may find it more convenient to use the function
`search_text()`.

``` r
sig <- search_text(s, "signific")

sig$text
#> [1] "Our main, omnibus analysis showed a significant three-way interaction among incest type, participant sex, and sibling type (Estimate = 0.285, t(578.003) = 2.359, p = 0.019)."                            
#> [2] "Our analysis of moral wrongness scores for sibling incest scores showed a significant interaction between participant sex and sibling type (Estimate = -0.559, t(578) = -2.84, p = 0.005)."               
#> [3] "In contrast, our analysis of moral wrongness scores for parental incest scores showed no significant interaction between participant sex and sibling type (Estimate = -0.268, t(578) = -1.373, p = 0.17)."
#> [4] "In contrast, having other-sex siblings was not significantly associated with greater moral opposition to parent-child incest."
```

You can also return just the matched text from a regex search.

``` r
pattern <- "[^\\s\\(\\)]+\\s*(=|<)\\s*[0-9\\.-]+"
search_text(s, pattern, section = "results", return = "match", perl = TRUE)
#>                text section  header div p s       file
#> 1  Estimate = 0.285 results Results   5 1 1 incest.xml
#> 2 Estimate = -0.559 results Results   5 2 1 incest.xml
#> 3  Estimate = 0.179 results Results   5 2 2 incest.xml
#> 4 Estimate = -0.268 results Results   5 2 3 incest.xml
```

## Batch Processing

The function `read_grobid()` also works on a folder of XML files,
returning a list of scienceverse study objects, and `search_text()`
works on such a list.

``` r
studies <- read_grobid(grobid_dir)
#> Processing 3 files...
#> - eyecolor.xml
#> - incest.xml
#> - prereg.xml
#> Complete!

hypotheses <- search_text(studies, "hypothesi", section = "intro")

hypotheses$text
#>  [1] "However, this hypothesis is difficult to reconcile with consistent findings that the parent--child relationship affects the strength of preferences for faces that resemble one's other--sex parent 17 and the strength of resemblance between that parent and one's spouse 8,9, as well as husband--father resemblance being observed even among adopted women who were not genetically related to their fathers 9 ."
#>  [2] "While the matching hypothesis predicts that the best predictor of partner's eye color will be own eye color, the sex--linked heritable preference hypothesis predicts this will be the other--sex parent's eye color and the positive sexual imprinting hypothesis predicts this will be the partner--sex parent's eye color."                                                                                        
#>  [3] "While these latter two predictions lead to the same pattern of results for heterosexual couples, here we also test same--sex couples to distinguish the sex-linked heritable preference hypothesis from the positive sexual imprinting hypothesis."                                                                                                                                                                   
#>  [4] "The best model supported the positive sexual imprinting hypothesis, where maternal eye color significantly predicted the eye color of female partners (B = 0.812, S.E."                                                                                                                                                                                                                                               
#>  [5] "This model was supported 7.455 times more strongly than the model corresponding to the matching hypothesis, where own eye color did not significantly predict partner eye color (B = 0.263, S.E."                                                                                                                                                                                                                     
#>  [6] "The imprinting model was also supported 9.655 times more strongly than the model corresponding to the sex--linked heritable preference hypothesis, where maternal eye color did not predict the eye color of men's partners (B = 0.262, S.E."                                                                                                                                                                         
#>  [7] "The model supporting the positive sexual imprinting hypothesis remained the best model (see Table 2)."                                                                                                                                                                                                                                                                                                                
#>  [8] "Our data provide clear evidence against the sex--linked heritable preferences hypothesis 3, which predicts a relationship between partner's eye color and other-sex parent's eye color."                                                                                                                                                                                                                              
#>  [9] "Our data also give little support to the matching hypothesis, as own eye color was positively but not significantly related to partner's eye color."                                                                                                                                                                                                                                                                  
#> [10] "Our data give clearest support to the positive sexual imprinting hypothesis, where we found that partner's eye color was predicted by maternal eye color for people with female partners and by paternal eye color for people with male partners."                                                                                                                                                                    
#> [11] "Consequently, humans (like many other animals) are hypothesized to possess adaptions to reduce inbreeding."                                                                                                                                                                                                                                                                                                           
#> [12] "Clearly specifying the rules that will be used to terminate the data collection, and specifying the analysis plan before data is collected, can prevent undesirable research practices such as inflated of Type 1 errors and \"hypothesizing after the results are known\" (Kerr, 1998)."                                                                                                                             
#> [13] "The hypothesis that more efficient study designs might increase the willingness to pre-register rests on several requirements."                                                                                                                                                                                                                                                                                       
#> [14] "Greenland, Senn, Rothman, Carlin, Poole, Goodman, and Altman (2016) respond to the statement that \"One should always use two-sided p-values\" with a resounding \"No!\", indicating that when a hypothesis is directional, a one-tailed test is required3 ."                                                                                                                                                         
#> [15] "Since one-sided tests are only appropriate whenever null-hypothesis significance tests are appropriate, we have to assume that a null-hypothesis test answers a question a researcher is interested in, and that the null-hypothesis is both plausible and interesting."                                                                                                                                              
#> [16] "The difference between hypothesis testing and estimation is relevant here -an unexpected effect might not confirm a hypothesis, but the descriptives related to the effect size might still be interesting."                                                                                                                                                                                                          
#> [17] "Purely descriptive studies where all data is reported might not require pre-registration, small pilot studies to test the feasibility of a paradigm are not designed to test a hypothesis, and some researchers might only publish studies when they have directly replicated every test in an independent sample."
```
