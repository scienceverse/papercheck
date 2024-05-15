## set default options
.onLoad <- function(libname, pkgname) {
  op <- options()
  op.scienceverse <- list(
    scienceverse.verbose = TRUE
  )
  toset <- !(names(op.scienceverse) %in% names(op))
  if(any(toset)) options(op.scienceverse[toset])

  invisible()
}
