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

**Two ways to build it -- pick whichever matches what you have installed:**

1. **`scripts/build_cv_pdf.py`** (Python, no R/Quarto/TinyTeX-extras
   needed) -- this is what generated the `assets/cv.pdf` already in
   this template, and it's been test-rendered end-to-end with
   `pdflatex`. Needs a standard TeX Live/MacTeX install (`pdflatex`)
   and `pip install pyyaml`.
   ```bash
   python3 scripts/build_cv_pdf.py
   ```
2. **`R/build_cv_pdf.R`** (renders `cv-pdf.qmd` via Quarto/knitr) --
   closer to the original hand-written CV's look, since it uses the
   `fontawesome5`/`academicons` packages for the contact icons instead
   of plain text labels. Needs those two extra LaTeX packages:
   ```r
   tinytex::install_tinytex()  # if you don't have TinyTeX yet
   tinytex::tlmgr_install(c("tipa", "fontawesome5", "academicons",
                             "wrapfig", "longtable", "xurl"))
   source("R/build_cv_pdf.R"); build_cv_pdf()
   ```
   This one is called automatically by `build_site()`/`publish_site()`
   and the *Build & Publish Site* addin. If you're using the Python
   script instead, just re-run it manually before publishing (or drop
   a call to it inside `build_site()` in `R/publish.R` — one line:
   `system("python3 scripts/build_cv_pdf.py")`).

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
  the repo -- it only gets created by running one of the two build
  steps above. This template now ships with a real, pre-built
  `assets/cv.pdf` (via the Python script) so the link works out of the
  box; regenerate it any time your content changes.

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

## Publishing to GitHub Pages

This template writes rendered HTML to `docs/` (set via `output-dir` in
`_quarto.yml`), so the simplest GitHub Pages setup works: create/rename
your repo to `<username>.github.io`, push, then in
**Settings → Pages** set *Source: Deploy from branch*, branch `main`,
folder `/docs`.

Two ways to publish:

**A. From RStudio (recommended, uses `{gert}`)**
- Addins → *Build & Publish Site* → type a commit message → Done.
- Or from the console: `source("R/publish.R"); publish_site("Add new talk")`

**B. From GitHub Actions (`.github/workflows/publish.yml`)**
- Push `.qmd` changes to `main`; Actions renders and deploys automatically.
- If you use this, set Pages source to the `gh-pages` branch instead of
  `/docs`, and you no longer need to commit `docs/` locally — pick
  *one* of A or B, not both, to avoid conflicting deploys.

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
