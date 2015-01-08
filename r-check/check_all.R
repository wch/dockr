#!/usr/bin/Rscript

# Usage:
# To check a package from Github thats in the wch/R6 repository, you would run:
# Rscript check_all.R wch/R6

# Find number of cores (Linux only)
options(Ncpus = as.integer(system2("nproc", stdout = TRUE)))

update.packages(ask = FALSE)

# Need this because Rscript doesn't load methods, and it's needed for roxygen2.
library(methods)
library(devtools)

# Get command line args after "--args" (for use with Rscript)
get_args <- function() {
  args <- commandArgs()
  arg_idx <- min(which(args == "--args")) + 1
  arg_idx <- seq(arg_idx, length(args))
  args[arg_idx]
}


# Wrapper for revdep_check. Reports time and sends a pushbullet message.
rdc <- function(path, ...) {
  # Exclude some super-slow packages
  ignore <- c(
    "PopGenReport", "mizer", "EpiModel", "caret", "phylosim", "icd9", "NMF",
    "ndtv", "msm",
    "BEQI2", # not necessarily slow by itself, but it may want some X11 interaction
    "Rglpk"  # Can't compile this one - needs GLPK library?
  )

  start_time <- Sys.time()
  res <- devtools::revdep_check(path, libpath = .libPaths()[1], ignore = ignore,
                     threads = getOption('Ncpus'), ...)
  end_time <- Sys.time()

  cat(paste("revdep_check of", path, "finished in",
    round(difftime(end_time, start_time, units = "secs")), "seconds.\n"))

  # if (require(RPushbullet)) {
  #   pbPost("note", paste("Revdep check for", pkg, "finished."))
  # }

  res
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
  pkg <- fetch_source_github(repo, ref = ref)

  install_deps(pkg$path, dependencies = TRUE)

  # Run check
  check_dir <- tempdir()
  res <- list(
    name = pkg$name,
    path = file.path(check_dir, paste0(pkg$name, ".Rcheck"))
  )
  res$result <- check(pkg$path, cleanup = FALSE, check_dir = check_dir,
                      document = FALSE)


  # If package check failed, don't bother with revdeps
  if (!isTRUE(res$result)) {
    list(pkg = pkg, revdep = NULL)
  }

  # Rev dep check
  rd_res <- rdc(pkg$path)

  # Results from check and revdep check
  list(pkg = res, revdep = rd_res)
}

write_package_info <- function(pkgname, file) {
  if (missing(file)) stop("Need filename")

  desc <- packageDescription(pkgname)

  pkgversion <- desc$Version
  if (!is.null(desc$GithubSHA1))
    pkgversion <- paste0(pkgversion, " (", substr(desc$GithubSHA1, 1, 7), ")")

  write.dcf(
    list(
      package = pkgname,
      pkgversion = pkgversion,
      rversion = paste(R.version$major, R.version$minor, sep = "."),
      rstatus = if (grepl("devel", R.version$status)) "r-devel" else "r-release"
    ),
    file = file
  )
}

# Collect the results
collect <- function(results, outdir) {
  if (missing(outdir)) stop("Output directory must be specified")

  hostname <- system2('hostname', stdout = TRUE)
  outdir <- file.path(outdir, hostname)
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

  # Record package and R version information
  write_package_info(results$pkg$name, file.path(outdir, "INFO"))

  file.copy(from = results$pkg$path, to = outdir, recursive = TRUE)
  file.rename(
    file.path(outdir, basename(results$pkg$path)),
    file.path(outdir, "check")
  )

  file.copy(from = results$revdep$path, to = outdir, recursive = TRUE)
  file.rename(
    file.path(outdir, basename(results$revdep$path)),
    file.path(outdir, "revdep")
  )
}


# Clean up the revdep check result directories, removing source packages, built
# packages, and test directories
clean_revdep_results <- function(path) {
  clean_checkdir <- function(path) {
    pkgname <- sub("\\.Rcheck$", "", basename(path))
    unlink(file.path(path, pkgname), recursive = TRUE)
    unlink(file.path(path, "00_pkg_src"), recursive = TRUE)
    unlink(file.path(path, "tests"), recursive = TRUE)
  }

  checkdirs <- dir(path, pattern = "*.Rcheck", full.names = TRUE)

  invisible(lapply(checkdirs, clean_checkdir))
}


results <- check_all(get_args()[1])

clean_revdep_results(results$revdep$path)

collect(results, "/root/results")
