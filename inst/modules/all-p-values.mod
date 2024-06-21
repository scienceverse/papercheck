{
  "title": "List All P-Values",
  "type": "text",
  "authors": [{
    "orcid": "0000-0002-7523-5539",
    "name":{
      "surname": "DeBruine",
      "given": "Lisa"
    },
    "email": "debruine@gmail.com"
  }],
  "text": {
    "pattern": "(?<=[^a-z])p-?(value)?\\s*[<>=≤≥]{1,2}\\s*(n\\.?s\\.?|\\d?\\.\\d+e?-?\\d*)",
    "return": "match",
    "perl": true
  },
  "traffic_light": {
    "found": "info",
    "not-found": "na"
  }
}
