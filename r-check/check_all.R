#!/usr/bin/Rscript

# Need this because Rscript doesn't load methods, and it's needed for roxygen2.
library(methods)

# Find number of cores (Linux only)
options(Ncpus = as.integer(system2("nproc", stdout = TRUE)))

# Get command line args after "--args" (for use with Rscript)
get_args <- function() {
  args <- commandArgs()
  arg_idx <- min(which(args == "--args")) + 1
  arg_idx <- seq(arg_idx, length(args))
  args[arg_idx]
}


# Exclude some super-slow packages
ignore <- c(
  "PopGenReport", "mizer", "EpiModel", "caret", "phylosim", "icd9", "NMF",
  "ndtv", "msm",
  "BEQI2", # not necessarily slow by itself, but it may want some X11 interaction
  "Rglpk"  # Can't compile this one - needs GLPK library?
)

# Wrapper for revdep_check. Reports time and sends a pushbullet message.
rdc <- function(pkg, ...) {
  start_time <- Sys.time()
  res <- devtools::revdep_check(pkg, libpath = .libPaths()[1], ignore = ignore,
																threads = getOption('Ncpus'), ...)
  end_time <- Sys.time()

  cat(paste("revdep_check for", pkg, "finished in",
    round(difftime(end_time, start_time, units = "secs")), "seconds.\n"))

  # if (require(RPushbullet)) {
  #   pbPost("note", paste("Revdep check for", pkg, "finished."))
  # }

  res
}

# Get env vars by running this
showvars <- function(res) {
  pkg <- res$revdep_package
  desc <- packageDescription(pkg)
  rstatus <- if (grepl("devel", R.version$status)) "r-devel" else "r-release"

  pkgversion <- desc$Version
  if (!is.null(desc$GithubSHA1))
    pkgversion <- paste0(pkgversion, " (", substr(desc$GithubSHA1, 1, 7), ")")

  sprintf('
    RVERSION=%s.%s
    RSTATUS=%s
    RPKG=%s
    RPKGVERSION="%s"
    CHECKDIR="%s"\n',
    R.version$major, R.version$minor,
    rstatus,
    pkg,
    pkgversion,
    file.path(res$path, "results")
  )
}


# Fetch source package, unzip, and return list with package name and path
# Derived from devtools:::install_remote
fetch_source_github <- function(repo, ref = "master") {
  remote <- github_remote(repo, ref = ref)
  bundle <- remote_download(remote)
  source <- source_pkg(bundle, subdir = remote$subdir)
  add_metadata(source, remote_metadata(remote, bundle, source))
  clear_description_md5(source)

  # Get package name
  desc <- read.dcf(file.path(source, 'DESCRIPTION'))
  name <- unname(desc[1,'Package'])

  list(name = name, path = source)
}
environment(fetch_source_github) <- asNamespace("devtools")


# Given a repo name, like "hadley/dplyr", download, install, check, and run
# revdep checks.
check_all <- function(repo, ref = "master") {
  library(devtools)
  pkg <- fetch_source_github(repo, ref = ref)

  install_deps(pkg$path, dependencies = TRUE)

  # Run check
  check_dir <- tempdir()
  check_res <- check(pkg$path, cleanup = FALSE, check_dir = check_dir)

  if (!isTRUE(check_res)) {
    return(FALSE)
  }

  install(pkg$path)
  rd_res <- revdep_check(pkg$name)
}


check_all(get_args()[1])
