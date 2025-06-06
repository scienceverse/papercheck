{
  "title": "List All P-Values",
  "description": "List all p-values in the text, returning the matched text (e.g., 'p = 0.04') and document location in a table.",
  "example": [
    "module_run(psychsci[[1]], \"all-p-values\")",
    "module_run(psychsci[1:2], \"all-p-values\")"
  ],
  "authors": [{
    "orcid": "0000-0002-7523-5539",
    "name":{
      "surname": "DeBruine",
      "given": "Lisa"
    },
    "email": "debruine@gmail.com"
  }],
  "text": {
    "pattern": "\\bp-?(value)?\\s*[<>=≤≥]{1,2}\\s*(n\\.?s\\.?|\\d?\\.\\d+)(e-\\d+)?",
    "return": "match",
    "perl": true
  },
  "traffic_light": {
    "found": "info",
    "not_found": "na"
  }
}
