# papercheck 0.0.0.9055

* `pdf2grobid()` handles `save_path` batter if any path components don't exist yet. The argument `save_path` also now can take a vector of the same length as the number of PDFs to convert, so you can specify the name of each output XML. 
* `read()` now skips any imports with errors and warns you about them after importing all files
* Fixed a bug that errored on read() when bibentry files don't format correctly
* Function `osf_get_all_pages()` now has a new argument `page_end` to limit the number of pages retrieved (mainly for testing purposes), and is external (previously internal)
* Fixed a bug in `osf_files()` that failed on paths with sapces

# papercheck 0.0.0.9054

* `osf_file_download()` now also retrieves files from linked storage
* Removed the last dependency to {osfr} and updated `osf_check_id()` to return expected IDs from various URLs
* OSF functions added to getting started vignette
* Functions that require and API are now tested using httptest
* module_list() doesn't fail if there are any errors in the modules

# papercheck 0.0.0.9053

* Updated `read()` to parse more stupid date formats that turn up in the submission string (and added the unparsed submission string back just in case)
* Completely overhauled how paper objects handle references. 
    - the `paper$reference` table is now `paper$bib`
    - the `paper$citations` table is now `paper$xrefs` and also contains  information for internal cross-references to figures, tables, footnotes, and formulae
    - the `ref_id` and `bib_id` in both tables is now `xref_id`
    - the `xrefs` table also contains location information (section, div, p, s) for the sentence containing the cross-ref, so you can use `expand_text()` 
    - The `read()` function now returns paper objects with these new tables, so you will need to re-read any XML files (if you have stored the papercheck list as Rdata)
    - The `psychsci` object has been updated for this new format
    - Modules and vignettes have been updated as well

# papercheck 0.0.0.9052

* Fixed a bug in `expand_text()` where expanded sentences were duplicated if there are multiple matches from the same sentence in the data frame.
* Updated the `retractionwatch` table
* Fixed a bug in `read()` that omitted paper DOIs from paper$info
* Updated `read()` to add correctly parsed "accepted" and "received" dates to paper\$info (replaces paper\$submission string) (ISO 8601 is the only correct date format!)
* Updated `psychsci` for new info structure

# papercheck 0.0.0.9051

* Small bug fixes to `osf_file_download()`
* `osf_file_download()` now returns a table of file info, including info for files not downloaded because of file size limits

# papercheck 0.0.0.9050

* Added `read()` function, which superceeds `read_grobid()`, `read_cermine()` and `read_text()` (they are still available, but are now just aliases to `read()`). This should work with XML files in TEI (grobid), JATS APA-DTD, NLM-DTD and cermine formats, plus full text-only parsing of .docx and plain text files.
* Added `osf_file_download()` function, which downloads all files under a project or node and structures them the same as the project.

# papercheck 0.0.0.9049

* Updated `read_grobid()` to classify headers as intro, method, results, discussion with better accuracy (to handle garbled headers)
* Updated `pdf2grobid()` to allow some grobid parameters
* Updated the module "all_p_values" to handle more scientific notation formats

# papercheck 0.0.0.9048

* Functions to check ResearchBox.org (`rbox_links()` and `rbox_retrieve()`) -- very preliminary
* The module "all_p_values" now returns the p-value as a numeric column `p_value` and the comparator as `p_comp`, like "exact_p"

# papercheck 0.0.0.9047

* fixed some bugs in osf and aspredicted functions (mainly around dealing with private or empty projects)
* added rvest dependency for better webpage parsing
* changed name of resulting column from `summarize_contents()` from `best_guess` to `file_category`

# papercheck 0.0.0.9046

* New `aspredicted_links()` and `aspredicted_retrieve()` functions
* New related blog post
* General bug fixes in newer stuff
* Updated license to AGPL (GNU Affero General Public License)

# papercheck 0.0.0.9045

* When reading a paper with `read_grobid()`, the paper$references table now contains new columns for bibtype, title, journal, year, and authors to facilitate reference checks, and more reliably pulls DOIs.
* The `psychsci` set has  been updated for the new reference tables
* fixed bug in `info_table()` where adding "id" to the items argument borked the id column
* Added `json_expand()` function to expand JSON-formatted LLM responses
* Updated the LLM examples in the vignettes
* Added `find_project` argument to `osf_retrieve()` to make searching for the parent project optional (it takes 1+ API calls)
* Added `emojis` for convenience

# papercheck 0.0.0.9044

* Revised the OSF functions again!
* Organised the Reference section of the website
* Added some blog posts to the website
* Upgraded the "osf_check" module to give more info

# papercheck 0.0.0.9043

* Totally re-wrote the OSF functions

# papercheck 0.0.0.9042

* New OSF functions and vignette
* Build pkgdown manually 

# papercheck 0.0.0.9041

* Fixed a bug in `validate()` that returned incorrect summary stats if the data type of an expected column didn't match the data type of an observed column (e.g., double vs integer)
* Combined the two effect size modules into "effect_size"
* Renamed the module "imprecise_p" to "exact_p" (I keep typo-ing "imprecise")
* Added a loading message
* Added code coverage at https://app.codecov.io/gh/scienceverse/papercheck
* updated "all_p_values" to handle unicode operators like <=or >>

# papercheck 0.0.0.9040

* Updated default llm model to llama-3.3-70b-versatile (old one is being deprecated in August)
* Updated reporting function for modules to show the summary table
* Fixes a bug in `validate()` that returned FALSE for matches if the expected and observed results were both `NA`
* Added two preliminary modules: "effect_size_ttest" and "effect_size_ftest"

# papercheck 0.0.0.9039

* removed the llm_summarise module
* updated `papercheck_app()` to show all modules
* removed the LLM tab from the shiny app
* fixed a bug in `pdf2grobid()` where a custom grobid_url was not used in batch processing
* `psychsci` object updated to use XMLs from grobid 0.8.2, which fixes some grobid-related errors in PDF import

# papercheck 0.0.0.9038

* `validate()` function is updated for the new module structure
* the validation, metascience, and text_model vignettes are updated
* modules can now use relative paths (to their own location) to access helper files

# papercheck 0.0.0.9037

* The way modules are created has been majorly changed -- it is now very similar to R package functions, using roxygen for documentation, instead of JSON format. There is no longer a need to distinguish text search, code, and LLM types of modules, they all use code. The vignettes have been updated to reflect this.
* Modules now return a `summary` table that is appended to a master summary table if you chain modules like `psychsci |> module_run("all_p_values") |> module_run("marginal")`
* The `validate()` function is temporarily removed to adapt the workflow to the new summary tables.
* new `module_help()` function and some help/examples in modules
* new `module_info()` helper function
* new `paperlist()` function to create paper list objects
* paper lists now print as a table of IDs, titles, and DOIs
* updated `read_grobid()` to have fewer false positives for citations
* updated `retractionwatch`

# papercheck 0.0.0.9036

* Now reads in grobid XMLs that have badly parsed figures

# papercheck 0.0.0.9035

* updated the shiny app for recent changes

# papercheck 0.0.0.9034

* `openalex()` takes paper objects, paper lists, and vectors of DOIs as input, not just a single DOI
* fixed paper object naming problem when nested files are not all at the same depth


# papercheck 0.0.0.9033

* added `read_cermine()` as associated internal functions for reading cermine-formatted XMLs

# papercheck 0.0.0.9032

* New functions for exploring github repositories: `github_repo()`, `github_readme()`, `github_languages()`, `github_files()`, `github_info()`
* A new vignette about github functions

# papercheck 0.0.0.9031

* `read_grobid()` now includes figure and table captions, plus footnotes, in the full_text table
* the `psychsci` paper list object is updated to include the above
* The functions that `module_run()` delegates to now check and only pass valid arguments

# papercheck 0.0.0.9030 (2025-03-01)

* modules are now updated for clearer output, and added a new module vignette
* `llm()` no longer returns NA when the rate limit is hit, but slows down queries accordingly
* `read_grobid()` now includes back matter (e.g., acknowledgements, COI statements) in the full_text, so is searchable with `search_text()`
* references are now converted to bibtex format, so are more complete and consistent
* Machine-learning module types are removed (the python/reticulate setup was too complex for many users), and instructions for how to create simple text feature models is included in the metascience vignette

# papercheck 0.0.0.9029 (2025-02-26)

* added `author_table()` to get a dataframe of author info from a list of paper objects
* fixed a bunch of tests now that multiple matches in a sentence are possible
* added back text (acknowledgements, annex, funding notes) to the full_text of a paper
* Fixed a bug in `search_text()` that omitted duplicate matches in the same sentence when using results = "match"
* Upgraded the search string for the "all-p-values" module to not error when a numeric value is followed by "-"
* Error catching for `stats()` related to the above problem (and filed an issue on statcheck)
* URLs in grobid XML are now converted to "<url>" using the source url, not the text url, which is often mangled

# papercheck 0.0.0.9028 (2025-02-18)

* added `psychsci` dataset of 250 open access papers from Psychological Science
* added "all" option the the return argument of `search_text()`
* added `info_table()` to get a dataframe of info from a list of paper objects
* experimental functions for text prediction: `distinctive_words()` and `text_features()`

# papercheck 0.0.0.9027 (2025-02-07)

* Removed ChatGPT and added groq support
* Updated `llm()` and associated functions like `llm_models()`
* Working on div vs section aggregation for `search_text()`

# papercheck 0.0.0.9026 (2025-02-06)

* metascience and batch vignettes
* removed scienceverse as a dependency
* revised validation functions
* added `tl_accuracy()`

# papercheck 0.0.0.9025 (2025-02-04)

* Added `expand_text()`

# papercheck 0.0.0.9024 (2025-01-31)

* Added `validate()` function and vignette
