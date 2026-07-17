# ------------------------------------------------------------------------
# publish.R
#
# Helpers to render the Quarto site and push it to GitHub using {gert}
# (a libgit2 wrapper — no shell `git` or GitHub CLI required, and it
# picks up credentials already stored by RStudio / the credential
# manager / an SSH key, so nothing extra to configure in most setups).
#
# Usage from the R console or the RStudio Addin ("Build & Publish Site"):
#
#   source("R/publish.R")
#   publish_site("Update talks page")
#
# ------------------------------------------------------------------------
tinytex::tlmgr_install(c("tipa", "fontawesome5", "academicons", "xcolor", "xurl", "wrapfig", "longtable"))
#' Render the Quarto website
#'
#' @param quiet Passed to quarto::quarto_render()
#' @param update_cv Rebuild assets/cv.pdf from current content first
#'   (see R/build_cv_pdf.R). Set FALSE to skip if you don't have a LaTeX
#'   install / just want a quick HTML preview.
build_site <- function(quiet = FALSE, update_cv = TRUE) {
  if (!requireNamespace("quarto", quietly = TRUE)) {
    stop("Package 'quarto' is required. Install with install.packages('quarto').")
  }

  if (isTRUE(update_cv)) {
    tryCatch({
      source("R/build_cv_pdf.R", local = TRUE)
      build_cv_pdf(quiet = quiet)
    }, error = function(e) {
      warning("Could not rebuild cv.pdf (", conditionMessage(e), "). ",
              "Continuing with the existing assets/cv.pdf.")
    })
  }

  quarto::quarto_render(as_job = FALSE, quiet = quiet)
  invisible(TRUE)
}

#' Render (optionally) and publish the site to GitHub
#'
#' Stages every change in the repo (site output + source files), commits
#' with the supplied message, and pushes to the given remote/branch.
#' Designed for projects where `_quarto.yml` sets `output-dir: docs` and
#' GitHub Pages is configured to serve from the `docs/` folder on `main`
#' — the simplest possible GitHub Pages setup (no gh-pages branch, no
#' GitHub Actions required, though a workflow is also included for
#' users who prefer CI-based publishing).
#'
#' @param message Commit message. If NULL you will be prompted.
#' @param render Logical; render the site first? Default TRUE.
#' @param remote Name of the git remote. Default "origin".
#' @param branch Branch to push to. Default "main".
#' @param path Path to the local git repo. Default ".".
publish_site <- function(message = NULL,
                          render = TRUE,
                          remote = "origin",
                          branch = "main",
                          path = ".") {

  if (!requireNamespace("gert", quietly = TRUE)) {
    stop("Package 'gert' is required. Install with install.packages('gert').")
  }

  if (isTRUE(render)) {
    message("-> Rendering site with Quarto...")
    build_site(quiet = TRUE)
  }

  status <- gert::git_status(repo = path)
  if (nrow(status) == 0) {
    message("Nothing to publish -- working tree is already clean.")
    return(invisible(FALSE))
  }

  if (is.null(message) || !nzchar(message)) {
    if (interactive()) {
      message <- readline("Commit message: ")
    } else {
      message <- paste("Update site", format(Sys.time(), "%Y-%m-%d %H:%M"))
    }
  }

  message("-> Staging ", nrow(status), " changed file(s)...")
  gert::git_add(".", repo = path)

  message("-> Committing...")
  gert::git_commit(message, repo = path)

  message("-> Pushing to ", remote, "/", branch, "...")
  gert::git_push(remote = remote, repo = path)

  message("Done: pushed to ", remote, "/", branch, ".")
  invisible(TRUE)
}

#' Scaffold a new entry (publication, talk, course, service item, project)
#'
#' Small convenience so you never have to hand-type YAML front matter.
#'
#' @param collection One of "publications", "talks", "teaching", "service", "projects"
#' @param title Title of the entry
#' @param date Date, "YYYY-MM-DD" or just "YYYY" (defaults to today)
#' @param categories Character vector of tags/categories
#' @param subtitle Venue / type line shown under the title
#' @param open Open the new file in RStudio after creation (if available)
new_entry <- function(collection = c("publications", "talks", "teaching", "service", "projects"),
                       title,
                       date = format(Sys.Date(), "%Y-%m-%d"),
                       categories = character(),
                       subtitle = "",
                       open = TRUE) {

  collection <- match.arg(collection)
  if (missing(title) || !nzchar(title)) stop("Please supply a `title`.")

  slug <- tolower(gsub("[^a-zA-Z0-9]+", "-", title))
  slug <- gsub("^-|-$", "", slug)
  if (nchar(date) == 4) date <- paste0(date, "-01-01")

  fname <- file.path(collection, paste0(substr(date, 1, 4), "-", slug, ".qmd"))
  if (file.exists(fname)) stop("File already exists: ", fname)

  cats <- if (length(categories)) paste0("[", paste(categories, collapse = ", "), "]") else "[]"

  yaml <- c(
    "---",
    sprintf('title: "%s"', title),
    if (nzchar(subtitle)) sprintf('subtitle: "%s"', subtitle),
    sprintf("date: %s", date),
    sprintf("categories: %s", cats),
    "---",
    "",
    "Add the description / abstract here.",
    ""
  )

  dir.create(collection, showWarnings = FALSE)
  writeLines(yaml, fname)
  message("Created ", fname)

  if (open && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    rstudioapi::navigateToFile(fname)
  }

  invisible(fname)
}
