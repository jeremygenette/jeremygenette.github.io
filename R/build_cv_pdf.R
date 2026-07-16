# ------------------------------------------------------------------------
# build_cv_pdf.R
#
# Renders assets/cv.pdf from publications/, talks/, teaching/ and
# _data/cv_data.yml.
#
# This used to render a cv-pdf.qmd through Quarto, but a document with a
# different `format:` (pdf) living inside an `html` website project can
# crash Quarto's live preview server (ServeRenderManager) when its file
# watcher tries to hot-render it. To avoid that entirely, this now just
# shells out to scripts/build_cv_pdf.py, which builds the LaTeX and runs
# pdflatex directly -- completely outside Quarto's project system, so it
# can never collide with `quarto preview` again.
#
# Requires: python3, the PyYAML package (`pip install pyyaml`), and a
# TeX Live / MacTeX install providing `pdflatex` (plus the tipa, xurl,
# wrapfig, longtable, geometry packages -- all present in a default
# install).
# ------------------------------------------------------------------------

#' Render assets/cv.pdf via scripts/build_cv_pdf.py
#'
#' @param quiet Suppress the script's own progress messages
build_cv_pdf <- function(quiet = FALSE) {
  py <- Sys.which("python3")
  if (!nzchar(py)) py <- Sys.which("python")
  if (!nzchar(py)) {
    warning("No python3/python found on PATH -- skipping cv.pdf rebuild. ",
            "Install Python 3 + `pip install pyyaml`, or run ",
            "scripts/build_cv_pdf.py manually once it's set up.")
    return(invisible(FALSE))
  }

  message("-> Rebuilding assets/cv.pdf (scripts/build_cv_pdf.py)...")
  result <- system2(py, "scripts/build_cv_pdf.py",
                     stdout = if (quiet) FALSE else "",
                     stderr = if (quiet) FALSE else "")

  if (!identical(result, 0L) || !file.exists("assets/cv.pdf")) {
    warning("cv.pdf build failed or produced no output. Run ",
            "`python3 scripts/build_cv_pdf.py` directly in a terminal to see the ",
            "full pdflatex log.")
    return(invisible(FALSE))
  }

  message("-> assets/cv.pdf is up to date.")
  invisible(TRUE)
}
