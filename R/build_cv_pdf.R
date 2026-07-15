# ------------------------------------------------------------------------
# build_cv_pdf.R
#
# Renders cv-pdf.qmd -- which reads publications/, talks/, teaching/ and
# _data/cv_data.yml at render time -- into assets/cv.pdf. That's the same
# file the "Download CV" button on index.qmd and contact.qmd links to, so
# add a new talk/course/publication .qmd file, run this, and the PDF is
# current -- no manual copy-paste between the site and the CV.
#
# Requires a working LaTeX install (TinyTeX is easiest):
#   quarto::quarto_render() will call tinytex automatically if present.
#   tinytex::install_tinytex()
#   tinytex::tlmgr_install(c("tipa", "fontawesome5", "academicons",
#                             "wrapfig", "longtable", "xurl"))
# ------------------------------------------------------------------------

#' Render cv-pdf.qmd to assets/cv.pdf
#'
#' @param dest Destination path for the PDF. Default "assets/cv.pdf"
#'   (what index.qmd and contact.qmd link to).
#' @param quiet Passed to quarto::quarto_render()
build_cv_pdf <- function(dest = "assets/cv.pdf", quiet = FALSE) {
  if (!requireNamespace("quarto", quietly = TRUE)) {
    stop("Package 'quarto' is required. Install with install.packages('quarto').")
  }

  message("-> Rendering cv-pdf.qmd...")
  quarto::quarto_render(input = "cv-pdf.qmd", output_file = "cv-pdf.pdf", quiet = quiet)

  produced <- "cv-pdf.pdf"
  if (!file.exists(produced)) {
    # some Quarto/pandoc versions place the output next to the .qmd
    # regardless of output_file casing/extension quirks -- fall back to
    # searching for the most recently modified pdf in the project root.
    candidates <- list.files(".", pattern = "\\.pdf$", full.names = TRUE)
    if (length(candidates) == 0) stop("Could not find the rendered PDF.")
    produced <- candidates[which.max(file.mtime(candidates))]
  }

  dir.create(dirname(dest), showWarnings = FALSE, recursive = TRUE)
  file.copy(produced, dest, overwrite = TRUE)
  if (produced != dest && file.exists(produced)) file.remove(produced)

  message("-> Wrote ", dest)
  invisible(dest)
}
