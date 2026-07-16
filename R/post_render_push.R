#!/usr/bin/env Rscript
# ------------------------------------------------------------------------
# post_render_push.R
#
# Wired up in _quarto.yml under `project: post-render:`, so it runs
# automatically at the end of every `quarto render` (and every
# `quarto::quarto_render()` call from R, including inside build_site()):
# stages, commits, and pushes to GitHub -- no separate publish step.
#
# CAUTION -- `quarto preview` also re-renders (and so re-triggers this)
# on every file save. That means if you leave `quarto preview` running
# while you edit, every save gets committed and pushed too. If you'd
# rather review changes before they go live, either:
#   - turn this off while editing:  QUARTO_AUTO_PUSH=false quarto preview
#   - or don't use `quarto preview` at all; just edit, then
#     `quarto render` (or the "Build & Publish Site" addin) when ready.
#
# Opt-out for one call:
#   QUARTO_AUTO_PUSH=false quarto render
# Opt-out permanently for this project: add a line to a .Renviron file
# in the project root:
#   QUARTO_AUTO_PUSH=false
# ------------------------------------------------------------------------

auto_push <- !tolower(Sys.getenv("QUARTO_AUTO_PUSH", "true")) %in% c("0", "false", "no")
if (!auto_push) quit(save = "no", status = 0)

if (!requireNamespace("gert", quietly = TRUE)) {
  message("QUARTO_AUTO_PUSH: the 'gert' package isn't installed -- skipping auto-push. ",
          "install.packages('gert') to enable it.")
  quit(save = "no", status = 0)
}

repo_ok <- tryCatch({ gert::git_status(repo = "."); TRUE }, error = function(e) FALSE)
if (!repo_ok) {
  message("QUARTO_AUTO_PUSH: this doesn't look like a git repo yet ",
          "(run `git init` / `gert::git_init()` and add a GitHub remote first) -- skipping.")
  quit(save = "no", status = 0)
}

status <- gert::git_status(repo = ".")
if (nrow(status) == 0) {
  message("QUARTO_AUTO_PUSH: nothing changed, nothing to push.")
  quit(save = "no", status = 0)
}

msg    <- Sys.getenv("QUARTO_AUTO_PUSH_MESSAGE", paste("Auto-publish", format(Sys.time(), "%Y-%m-%d %H:%M")))
remote <- Sys.getenv("QUARTO_AUTO_PUSH_REMOTE", "origin")
branch <- Sys.getenv("QUARTO_AUTO_PUSH_BRANCH", "main")

tryCatch({
  message("QUARTO_AUTO_PUSH: staging ", nrow(status), " changed file(s)...")
  gert::git_add(".", repo = ".")

  message("QUARTO_AUTO_PUSH: committing...")
  gert::git_commit(msg, repo = ".")

  message("QUARTO_AUTO_PUSH: pushing to ", remote, "/", branch, "...")
  gert::git_push(remote = remote, repo = ".")

  message("QUARTO_AUTO_PUSH: done -- pushed to ", remote, "/", branch, ".")
}, error = function(e) {
  message("QUARTO_AUTO_PUSH failed: ", conditionMessage(e))
  message("(Render still succeeded -- your local changes just weren't pushed. ",
          "Run publish_site() manually to retry, or check your git remote/credentials.)")
})
