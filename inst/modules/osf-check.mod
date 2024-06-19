{
  "title": "Check Status of OSF Links",
  "type": "code",
  "authors": [{
    "orcid": "0000-0002-0247-239X",
    "name":{
      "surname": "Lakens",
      "given": "Daniël"
    },
    "email": "lakens@gmail.com"
  },
  {
    "orcid": "0000-0002-7523-5539",
    "name":{
      "surname": "DeBruine",
      "given": "Lisa"
    },
    "email": "debruine@gmail.com"
  }],
  "code": {
    "packages": ["papercheck", "httr", "dplyr"],
    "path": "osf-check.R"
  },
  "report": {
    "na": "No OSF links were detected",
    "red": "We detected closed OSF links",
    "yellow": "There may be problems with some OSF links",
    "green": "All OSF links are open"
  }
}
