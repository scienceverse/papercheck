
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

The function `study_from_xml()` can read XML files in
[TEI](https://tei-c.org/) format created by
[grobid](https://grobid.readthedocs.io/).

The example below uses some previously created XML files that are
included with papercheck. You can [use grobid on your own
paper](https://huggingface.co/spaces/kermitt2/grobid) here.

``` r
grobid_dir <- system.file("grobid", package="papercheck")
filename <- file.path(grobid_dir, "incest.pdf.tei.xml")
s <- study_from_xml(filename)
#> Processing incest.pdf.tei.xml...
```

## Full Text

You can access a parsed table of the full text of the paper via
`s$full_text`

``` r
dplyr::count(s$full_text, section_class)
#>   section_class  n
#> 1      abstract  6
#> 2         intro 25
#> 3        method 25
#> 4       results 16
#> 5    discussion 12
#> 6        figure  5
```

However, you may find it more convenient to use the function
`search_full_text()`.

``` r
search_full_text(s, "significan[t|ce]")
#> # A tibble: 4 × 7
#> # Groups:   section_class, section, div, p [3]
#>   section_class section div   p     s     text                             study
#>   <fct>         <chr>   <chr> <chr> <chr> <chr>                            <chr>
#> 1 results       div_5   5     2     1     Our main, omnibus analysis show… ince…
#> 2 results       div_5   5     3     1     Our analysis of moral wrongness… ince…
#> 3 results       div_5   5     3     7     In contrast, our analysis of mo… ince…
#> 4 discussion    div_6   6     3     1     In contrast, having other-sex s… ince…
```

(Note that grobid is often bad at parsing sentences with statistics, and
will break them into multiple sentences. We are working on ways of
detecting and fixing this.)

References are omitted by default, but you can add them back in.

``` r
search_full_text(s, "third-party", section = "intro", refs = TRUE)
#> # A tibble: 5 × 7
#> # Groups:   section_class, section, div, p [3]
#>   section_class section div   p     s     text                             study
#>   <fct>         <chr>   <chr> <chr> <chr> <chr>                            <chr>
#> 1 intro         div_1   1     3     3     This observation led Lieberman … ince…
#> 2 intro         div_1   1     4     3     Royzman et al's non-replication… ince…
#> 3 intro         div_1   1     4     4     Royzman et al's (2008) non-repl… ince…
#> 4 intro         div_1   1     5     1     In light of the above, we teste… ince…
#> 5 intro         div_1   1     5     2     We also investigated the specif… ince…
```

## Batch Processing

The function `study_from_xml()` also works on a folder of XML files,
returning a list of scienceverse study objects, and `search_full_text()`
works on such a list.

``` r
studies <- study_from_xml(grobid_dir)
#> Processing eyecolor.pdf.tei.xml...
#> Processing incest.pdf.tei.xml...
#> Processing prereg.pdf.tei.xml...

search_full_text(studies, "hypothesi", section = "intro")
#> # A tibble: 13 × 7
#> # Groups:   section_class, section, div, p [5]
#>    section_class section div   p     s     text                            study
#>    <fct>         <chr>   <chr> <chr> <chr> <chr>                           <chr>
#>  1 intro         div_1   1     3     3     "However, this hypothesis is d… eyec…
#>  2 intro         div_1   1     4     12    "This model was supported 7.45… eyec…
#>  3 intro         div_1   1     4     14    "The imprinting model was also… eyec…
#>  4 intro         div_1   1     4     2     "While the matching hypothesis… eyec…
#>  5 intro         div_1   1     4     21    "The model supporting the posi… eyec…
#>  6 intro         div_1   1     4     22    "Our data provide clear eviden… eyec…
#>  7 intro         div_1   1     4     24    "Our data also give little sup… eyec…
#>  8 intro         div_1   1     4     25    "Our data give clearest suppor… eyec…
#>  9 intro         div_1   1     4     3     "While these latter two predic… eyec…
#> 10 intro         div_1   1     4     5     "The best model supported the … eyec…
#> 11 intro         div_1   1     2     2     "Consequently, humans (like ma… ince…
#> 12 intro         div_1   1     1     3     "Clearly specifying the rules … prer…
#> 13 intro         div_1   1     5     1     "The hypothesis that more effi… prer…
```
