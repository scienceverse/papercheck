options("scipen" = 10,
        "digits" = 4)

# datatable constants ----
dt_options <- list(
  info = TRUE,
  lengthChange = TRUE,
  paging = TRUE,
  ordering = FALSE,
  searching = FALSE,
  pageLength = 10,
  keys = FALSE,
  dom = '<"top" ip>'
  #scrollX = TRUE,
  #columnDefs = list(list(width = "6em", targets = 7))
)

# javascript for datatables ----
table_tab_js <- c(
  "table.on('key', function(e, datatable, key, cell, originalEvent){",
  "  var targetName = originalEvent.target.localName;",
  "  if(key == 13 && targetName == 'body'){",
  "    $(cell.node()).trigger('dblclick.dt').find('input').select();",
  "  }",
  "});",
  "table.on('keydown', function(e){",
  "  if(e.target.localName == 'input' && [9,13,37,38,39,40].indexOf(e.keyCode) > -1){",
  "    $(e.target).trigger('blur');",
  "  }",
  "});",
  "table.on('key-focus', function(e, datatable, cell, originalEvent){",
  "  var targetName = originalEvent.target.localName;",
  "  var type = originalEvent.type;",
  "  if(type == 'keydown' && targetName == 'input'){",
  "    if([9,37,38,39,40].indexOf(originalEvent.keyCode) > -1){",
  "      $(cell.node()).trigger('dblclick.dt').find('input').select();",
  "    }",
  "  }",
  "});"
)
