# ------------------------------------------------------------------------
# RStudio addins for the academic Quarto site.
#
# These call back into the project's R/publish.R (found relative to the
# active RStudio project root), so the logic lives in one place and this
# package is just a thin UI layer registered via inst/rstudio/addins.dcf.
# ------------------------------------------------------------------------

#' @importFrom shiny fluidPage textAreaInput checkboxInput observeEvent stopApp runGadget
#' @importFrom miniUI miniPage gadgetTitleBar miniContentPanel
project_root <- function() {
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    proj <- tryCatch(rstudioapi::getActiveProject(), error = function(e) NULL)
    if (!is.null(proj)) return(proj)
  }
  getwd()
}

#' Build & Publish Site addin
#'
#' Opens a small gadget with a commit-message box, then renders the
#' Quarto site and pushes it to GitHub via gert::git_push().
#' @export
addin_publish_site <- function() {
  root <- project_root()
  source(file.path(root, "R", "publish.R"), local = (env <- new.env()))

  ui <- miniUI::miniPage(
    miniUI::gadgetTitleBar("Build & Publish Site"),
    miniUI::miniContentPanel(
      shiny::textAreaInput("msg", "Commit message", rows = 3,
                            placeholder = "e.g. Add new talk, update CV"),
      shiny::checkboxInput("render", "Render site before publishing", value = TRUE)
    )
  )

  server <- function(input, output, session) {
    shiny::observeEvent(input$done, {
      msg <- if (nzchar(input$msg)) input$msg else "Update site"
      shiny::stopApp()
      tryCatch({
        env$publish_site(message = msg, render = input$render, path = root)
      }, error = function(e) {
        message("Publish failed: ", conditionMessage(e))
      })
    })
    shiny::observeEvent(input$cancel, shiny::stopApp())
  }

  shiny::runGadget(ui, server, viewer = shiny::dialogViewer("Build & Publish Site"))
}

#' New Entry addin
#'
#' Small form to scaffold a new publication / talk / course / service /
#' project entry without hand-writing YAML front matter.
#' @export
addin_new_entry <- function() {
  root <- project_root()
  source(file.path(root, "R", "publish.R"), local = (env <- new.env()))

  ui <- miniUI::miniPage(
    miniUI::gadgetTitleBar("New Site Entry"),
    miniUI::miniContentPanel(
      shiny::selectInput("collection", "Collection",
                          choices = c("publications", "talks", "teaching", "service", "projects")),
      shiny::textInput("title", "Title"),
      shiny::textInput("subtitle", "Subtitle (venue / type)"),
      shiny::textInput("date", "Date (YYYY or YYYY-MM-DD)", value = format(Sys.Date(), "%Y")),
      shiny::textInput("categories", "Categories (comma-separated)")
    )
  )

  server <- function(input, output, session) {
    shiny::observeEvent(input$done, {
      shiny::stopApp()
      cats <- trimws(strsplit(input$categories, ",")[[1]])
      tryCatch({
        env$new_entry(
          collection = input$collection,
          title = input$title,
          date = input$date,
          categories = cats,
          subtitle = input$subtitle
        )
      }, error = function(e) message("Could not create entry: ", conditionMessage(e)))
    })
    shiny::observeEvent(input$cancel, shiny::stopApp())
  }

  shiny::runGadget(ui, server, viewer = shiny::dialogViewer("New Site Entry"))
}
