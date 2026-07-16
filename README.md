# Academic Quarto site template

A reproduction of the `jeremygenette.github.io` Jekyll site as an **R
Quarto website**, with a few improvements:

- **One templating language.** Publications / talks / teaching / service /
  projects are each a folder of `.qmd` files with YAML front matter,
  rendered as a [Quarto listing](https://quarto.org/docs/websites/website-listings.html) —
  no hand-written Liquid loops, no duplicated card HTML per page.
- **Free filtering & sorting.** Quarto listings ship with category
  filters and sort controls out of the box, replacing the ~250 lines of
  custom JS (the dual-handle year slider + tag buttons) that powered
  `talks.md` / `teaching.md` in the original site.
- **RSS + sitemap + Open Graph cards** are generated automatically by
  Quarto — the original site had none of these.
- **`freeze: auto`** caches renders, so publishing is fast once the site
  has been rendered once.
- **One-click "New Site Entry"** RStudio addin scaffolds correct YAML
  front matter for a new publication/talk/course, so you never
  hand-type it.
- **One-click "Build & Publish Site"** RStudio addin renders the site
  and pushes it to GitHub for you, via `{gert}` (no shell git, no GitHub
  CLI, uses whatever git credentials RStudio/your OS already has).

## Project layout

```
_quarto.yml            site config, nav, theme
styles.scss             color/typography theme (orange/purple, from the original site)
styles-extra.css        a few small overrides

index.qmd                home page (hero + education/positions)
publications.qmd         listing page -> publications/
talks.qmd                listing page -> talks/
teaching.qmd              listing page -> teaching/
service.qmd               listing page -> service/
projects.qmd               listing page -> projects/
contact.qmd

publications/*.qmd        one file per publication
talks/*.qmd                one file per talk
teaching/*.qmd              one file per course
service/*.qmd               one file per service item
projects/*.qmd              one file per project

R/publish.R              build_site() / publish_site() / new_entry() helpers
rstudio-addin/            small local R package registering the two addins
.github/workflows/publish.yml   optional CI alternative to the gert workflow
```

## Auto-generated CV PDF

`assets/cv.pdf` (linked from the "Download CV" button and the Contact
page) is not a static file you maintain by hand -- it's generated from:

- `publications/`, `talks/`, `teaching/` (same folders the website
  listings use)
- `_data/cv_data.yml` (education, positions, awards, grants, skills,
  training, affiliations, references -- the sections that don't
  naturally split into "one file per entry")

Add a new talk/course/publication `.qmd` file (e.g. via the *New Site
Entry* addin) and the CV picks it up on the next build -- nothing to
copy between the site and the CV by hand. There's also `cv.qmd`, a
shorter HTML "long CV" page on the site itself, built from the exact
same source.

**How to build it:** `R/build_cv_pdf.R` shells out to
`scripts/build_cv_pdf.py`, which builds the LaTeX and runs `pdflatex`
directly. This is what generated the `assets/cv.pdf` already in this
template, and it's been test-rendered end-to-end. Needs a standard TeX
Live/MacTeX install (`pdflatex`) and `pip install pyyaml`.

```r
source("R/build_cv_pdf.R"); build_cv_pdf()
```
```bash
# equivalently, straight from a terminal:
python3 scripts/build_cv_pdf.py
```

This is called automatically by `build_site()`/`publish_site()` and the
*Build & Publish Site* addin, so the PDF stays current every time you
publish.

> An earlier version of this template rendered a `cv-pdf.qmd` through
> Quarto instead. A document with a different `format:` (pdf) sitting
> inside an `html` website project can crash Quarto's live preview
> server when its file watcher tries to hot-render it
> (`ServeRenderManager` / `Cannot read properties of undefined
> (reading 'config')`). Switching to a plain Python + `pdflatex` script
> sidesteps Quarto's project system entirely, so this can't happen
> again -- if you'd still rather use LaTeX packages like
> `fontawesome5`/`academicons` for nicer icons (the original hand-written
> CV used them), you can adapt `scripts/build_cv_pdf.py`'s LaTeX template
> freely; it's a plain string, no Quarto involved.

## Auto-push on render

`_quarto.yml` wires up `R/post_render_push.R` as a **post-render
hook**, so every `quarto render` (from the terminal, from
`quarto::quarto_render()`, or from `build_site()`/`publish_site()`/the
*Build & Publish Site* addin) automatically stages, commits, and pushes
to GitHub afterwards -- no separate publish step needed.

> **Careful with `quarto preview`.** Preview also re-renders (and so
> re-triggers this push) on every file save. If you're going to leave
> `quarto preview` running while you edit, turn auto-push off first:
> ```bash
> QUARTO_AUTO_PUSH=false quarto preview
> ```
> Otherwise just edit normally and run `quarto render` (or the addin)
> when you actually want to publish.

Turn it off (one-off or permanently):
```bash
QUARTO_AUTO_PUSH=false quarto render        # one-off
```
```
# permanently for this project: add to a .Renviron file in the project root
QUARTO_AUTO_PUSH=false
```

Optional env vars: `QUARTO_AUTO_PUSH_MESSAGE`, `QUARTO_AUTO_PUSH_REMOTE`
(default `origin`), `QUARTO_AUTO_PUSH_BRANCH` (default `main`). If
you'd rather review changes before they go live instead of publishing
on every render, turn auto-push off and use the *Build & Publish Site*
addin / `publish_site()`, which always asks for a commit message first.

## Deploying to GitHub Pages (and fixing a 404)

1. Repo must be public (or GitHub Pro/Enterprise for a private repo
   with Pages), named either `<username>.github.io` or anything else.
2. **Settings → Pages → Source: "Deploy from a branch"**, Branch
   `main`, Folder **`/docs`** (this template renders to `docs/` via
   `output-dir: docs` in `_quarto.yml`, precisely so this simple setup
   works with no GitHub Actions needed).
3. Push at least once (`quarto render` with auto-push on, or
   `publish_site()`, or plain `git push`) so `docs/index.html` actually
   exists on `main`.
4. Give it a minute, then visit `https://<username>.github.io/<repo>/`
   (or `https://<username>.github.io/` if the repo is named
   `<username>.github.io`).

> Prefer GitHub Actions instead of committing `docs/` locally?
> `.github/workflows/publish.yml` renders and deploys on every push to
> `main`. If you use it, set Pages source to the `gh-pages` branch
> instead of `/docs`, turn off `QUARTO_AUTO_PUSH` (see above) so you're
> not rendering twice, and pick *one* of the two approaches -- not both.

**If you get a 404 / "page not found":**
- **Most common cause:** GitHub Pages runs Jekyll over your output by
  default, and Jekyll silently drops files/folders starting with `_`
  (Quarto uses several, e.g. its internal libs folders) -- this often
  breaks or blanks pages without an obvious error. Fixed by the
  `.nojekyll` file at the project root, which `_quarto.yml`'s
  `project: resources:` now copies into `docs/` on every render. If
  you're not seeing it in `docs/` after rendering, check that
  `.nojekyll` (yes, a dot-file with nothing but that name) still exists
  at the project root.
- Check **Settings → Pages** shows the branch/folder above and a green
  "Your site is live at ..." message, not a warning.
- Check the **Actions** tab / the small "pages build and deployment"
  check next to your latest commit for a build error.
- Confirm `docs/index.html` actually exists in the repo on GitHub (not
  just locally) -- if `render` failed partway through, some pages won't
  have made it into the commit.
- URL casing/trailing slash matters for sub-pages
  (`/talks.html` not `/talks`); make sure `site-url` in `_quarto.yml`
  matches the real URL so Open Graph/canonical links aren't wrong.
- Hard-refresh / try an incognito window -- GitHub Pages' CDN can cache
  an old 404 for a few minutes after the first successful deploy.

## Fixes applied after testing against a live render

- **Duplicate page titles.** Each listing/content page was showing its
  title twice (Quarto's own title block, plus a hand-added heading
  underneath styled the same way). Removed the hand-added heading and
  styled Quarto's title block directly (`#title-block-header` in
  `styles-extra.css`) so there's exactly one, in the same purple/serif
  style with the orange underline.
- **A "polyfill.io" prompt when switching back to the tab.** Older
  Quarto versions link to `polyfill.io` for MathJax's browser
  compatibility shim; that domain was compromised in 2024 and can pop
  up a fake login dialog. `_quarto.yml` now sets
  `html-math-method: katex`, which doesn't use polyfill.io at all. If
  you still see it, update the Quarto CLI too
  (`quarto --version` should be recent; get the latest at
  <https://quarto.org/docs/get-started/>).
- **Teaching/Talks/Publications entries running together on `cv.qmd`,
  and the Skills line showing literal `` `{r} ...` `` code.** Both were
  bugs in `cv.qmd`: `glue::glue()` silently trims the trailing newline
  from its result by default, so entries lost their separator and ran
  together; and inline R code needs `` `r expr` `` (no curly braces --
  those are only for chunk fences, not inline code). Both are fixed.
- **"Download CV" button 404ing.** There was no real `assets/cv.pdf` in
  the repo -- it only gets created by running the build step above.
  This template now ships with a real, pre-built `assets/cv.pdf` so the
  link works out of the box; regenerate it any time your content changes.
- **Quarto preview crashing with `Cannot read properties of undefined
  (reading 'config')`.** Caused by `cv-pdf.qmd` (a `pdf`-format document
  sitting inside the `html` website project) getting caught by the live
  preview's file watcher. Removed that file; the CV is now built by a
  plain Python script instead (see above), fully outside Quarto's
  project system.

## Setup

```r
install.packages(c("quarto", "gert", "rstudioapi", "shiny", "miniUI", "devtools",
                    "yaml", "glue", "rmarkdown"))
```

You'll also need the [Quarto CLI](https://quarto.org/docs/get-started/)
installed (RStudio 2022.07+ bundles it).

1. Open this folder as an RStudio Project.
2. Replace `assets/img/photo.jpg` and add `assets/cv.pdf`.
3. Edit `index.qmd` and `contact.qmd` with your own bio/links, and update
   `_quarto.yml` (title, url, email, GitHub links).
4. Add your own entries under `publications/`, `talks/`, `teaching/`,
   `service/`, `projects/` (or use the "New Site Entry" addin below).
5. Preview locally:
   ```r
   quarto::quarto_preview()
   ```

## Install the addins (one-time)

```r
devtools::install("rstudio-addin", quick = TRUE)
```

Restart RStudio. You'll now see **Build & Publish Site** and
**New Site Entry** under the Addins menu (bind them to keyboard
shortcuts via Tools → Modify Keyboard Shortcuts if you like).

## Notes on migration from the Jekyll site

- Jekyll `pub.year` → Quarto `date:` (use `YYYY-01-01` if you only track
  the year).
- Jekyll `tags:` / `topics:` (comma-separated string) → Quarto
  `categories: [a, b, c]` (a real YAML list — enables the built-in
  filter UI).
- `venue` + `type` were separate fields in the old cards; here they're
  combined into `subtitle:` (shown under the title).
- The dual-handle year-range slider on `talks.md`/`teaching.md` isn't
  reproduced 1:1 — Quarto's built-in category filter + sort-by-date
  covers the same need with far less code. If you want the slider back,
  it's still possible to drop the original `<script>` block into a
  page, since `.qmd` accepts raw HTML/JS.
