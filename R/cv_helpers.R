# ------------------------------------------------------------------------
# cv_helpers.R
#
# Reads the YAML front matter of every .qmd file in a collection folder
# (publications/, talks/, teaching/, service/, projects/) into one data
# frame. This is the single mechanism both cv.qmd (the HTML long-CV page)
# and R/build_cv_pdf.R (the auto-generated cv.pdf) use to stay in sync
# with whatever entries currently exist -- add or edit a .qmd file in one
# of those folders and both the listing page AND the CV pick it up on
# the next render, nothing to duplicate by hand.
# ------------------------------------------------------------------------

#' Read every entry's front matter from a collection folder
#'
#' @param dir Folder name, e.g. "talks"
#' @return A data frame with columns: title, subtitle, date (Date),
#'   categories (list-column of character vectors), body (character,
#'   the markdown content after the front matter), file (path)
read_collection <- function(dir) {
  files <- list.files(dir, pattern = "\\.qmd$", full.names = TRUE)
  if (length(files) == 0) {
    return(data.frame(
      title = character(), subtitle = character(),
      date = as.Date(character()), file = character(),
      categories = I(list()), body = character()
    ))
  }

  rows <- lapply(files, function(f) {
    fm <- rmarkdown::yaml_front_matter(f)
    lines <- readLines(f, warn = FALSE)
    dashes <- which(lines == "---")
    body <- if (length(dashes) >= 2) {
      paste(trimws(lines[(dashes[2] + 1):length(lines)]), collapse = " ")
    } else ""
    body <- trimws(body)

    cats <- fm[["categories"]]
    if (is.null(cats)) cats <- character()

    data.frame(
      title = fm[["title"]] %||% "",
      subtitle = fm[["subtitle"]] %||% "",
      date = as.Date(as.character(fm[["date"]] %||% NA)),
      file = f,
      body = body,
      stringsAsFactors = FALSE
    ) |> transform(categories = I(list(cats)))
  })

  out <- do.call(rbind, rows)
  out[order(out$date, decreasing = TRUE), ]
}

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || (is.character(a) && !nzchar(a))) b else a

#' Does a row's categories list contain a given keyword (case-insensitive)?
has_category <- function(categories, keyword) {
  vapply(categories, function(cats) any(grepl(keyword, cats, ignore.case = TRUE)), logical(1))
}

#' Format a date as "Month YYYY" (or just "YYYY" if it was Jan 1 -- our
#' convention for entries where only the year is known)
format_cv_date <- function(d) {
  ifelse(format(d, "%m-%d") == "01-01", format(d, "%Y"), format(d, "%B %Y"))
}

# ---- LaTeX-emitting helpers for the PDF CV (cv-pdf.qmd) -----------------
# These print raw LaTeX from an R chunk with `#| output: asis`. Pandoc's
# raw_tex extension (on by default for latex/pdf targets) passes such
# text straight through into the .tex source, so `\textbf{}`, `\\`, etc.
# below survive untouched into the final document -- same visual
# vocabulary as the original hand-written CV, just filled in from data.

latex_escape <- function(x) {
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([&%$#_{}])", "\\\\\\1", x)
  x
}

#' Print a longtable body (2 columns: dates | title/place/detail) for a
#' list of list-entries as used in _data/cv_data.yml (education,
#' positions, awards, grants, training)
latex_block_rows <- function(entries) {
  for (e in entries) {
    cat(sprintf("%s & \\textbf{%s}", e$dates, latex_escape(e$title)))
    if (nzchar(e$place %||% "")) cat(sprintf(" (%s)", latex_escape(e$place)))
    cat(" \\\\\n")
    if (nzchar(e$detail %||% "")) {
      # keep *italics* markers from the yaml as \textit{}
      detail <- gsub("\\*(.+?)\\*", "\\\\textit{\\1}", e$detail)
      cat(sprintf(" & %s \\\\\n", detail))
    }
    cat("\\\\\n")
  }
}

#' Print a longtable body for a collection data frame (talks, teaching,
#' publications): date | title, subtitle
latex_collection_rows <- function(df) {
  if (nrow(df) == 0) return(invisible())
  for (i in seq_len(nrow(df))) {
    d <- format_cv_date(df$date[i])
    cat(sprintf("%s & \\textbf{%s} \\\\\n", d, latex_escape(df$title[i])))
    if (nzchar(df$subtitle[i])) {
      cat(sprintf(" & %s \\\\\n", latex_escape(df$subtitle[i])))
    }
    cat("\\\\\n")
  }
}
