# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A [Quarto](https://quarto.org) website for the university course "Ecological Economics" (taught by Claudius Gräbner-Radkowitsch, EUF/JKU). The site is rendered to static HTML in `_site/` and published to Netlify at <https://ecological-economics26.netlify.app/> (the site `id` and `url` live in `_publish.yml`). R is available for executable code in some pages (managed via `renv`).

This repo started from a generic academic-course template (see `README.md` for what to change when reusing it) and was carried over from an earlier "Development Economics" edition, so stray old names may still surface — treat anything saying *Development Economics* as stale. It now targets the **Winter 2026/27** edition (the autumn term; repo directory `2026_Fall`). The course is **poster- and presentation-based**: the examination is a country-analysis poster (`content/material/examination.qmd`), and several sessions cover argumentation, poster design, and student presentations rather than problem-set exercises. Note that `references/references.bib` and in-text citations legitimately contain years like `2025` (publication/retrieval years, prize years, etc.) — these are real data, not edition labels, and must not be bumped. The authoritative course schedule lives in the table in `content/material/SeminarDescription.qmd`; session pages are numbered to match it (and match the sidebar in `_quarto.yml`).

## Commands

```bash
quarto preview        # Live-reloading local preview (use during editing)
quarto render         # Build the full site into _site/
quarto render content/material/s_05_Trade.qmd   # Render a single page
quarto publish netlify   # Publish to Netlify (target in _publish.yml)
```

There is no test suite or linter — "building" means rendering with Quarto. Pages may contain embedded R, so an R toolchain with the `renv` library restored (`R -e 'renv::restore()'`) is required for any page with `{r}` code chunks. At present R usage is minimal (e.g. `content/material/template/session00.qmd`), so most renders are pure Markdown — but keep the toolchain in mind for data-driven session pages.

## Architecture

- **`_quarto.yml`** is the control center: it defines the website type, the navbar/sidebar navigation, the theme, the bibliography/CSL, and — critically — the `render:` glob list. **A new `.qmd` page will not be built unless its path matches an entry under `project.render`** (currently `index.qmd`, `content/index.qmd`, `content/material/*.qmd`, and `content/material/session*/*.qmd`), and it will not appear in navigation unless added to `website.sidebar.contents`.
- **`index.qmd`** (root) is the landing page; **`content/index.qmd`** is the "Getting Started" page.
- **`content/material/`** holds the per-session lecture pages, named **`s_NN[x]_Slug.qmd`** where `NN` is the schedule session number, an optional lowercase letter (`a`, `b`, …) splits a session into parts, and `Slug` is a one-to-two-word topic. Examples: `s_05_Trade.qmd` (single), and `s_01a_Introduction.qmd` / `s_01b_Theories.qmd`, `s_03a_TextDiscussion.qmd` / `s_03b_WorkingWithData.qmd`, `s_04a_ScientificArgumentation.qmd` / `s_04b_PosterDesign.qmd`, `s_07a_PolicyInstruments.qmd` / `s_07b_ETS.qmd` (split sessions). `content/material/examination.qmd` describes the poster exam and is the *only* assessment rubric — there is no separate Moodle rubric. `content/material/template/session00.qmd` is the starting point for a new session. Cross-links between pages use the rendered `.html` name (same basename), not `.qmd`.
- **`content/material/SeminarDescription.qmd`** carries the authoritative schedule table *and* the general references (via `nocite` + a `#refs` div). It renders to both HTML and a downloadable PDF, so links in it are **absolute site URLs** — relative `.qmd` links would break in the PDF. There is deliberately no separate material-overview page.
- **`content/material/slides/`** holds the lecture material as `EcolEcon26_LNN[x]_*.pdf` (e.g. `slides/EcolEcon26_L05_Trade.pdf`). Source decks live in `slides/_keynote/`, superseded ones in `slides/_old/`, and `slides/ExamplePoster/` holds example student posters (PDF). **Slides are published only after the lecture**, via a marker block on each session page:

  ```
  <!--slides:05:EcolEcon26_L05_Trade.pdf-->
  ::: {.slides-pending}
  📽️ Slides will be made available after the lecture.
  :::
  <!--/slides:05-->
  ```

  The marker holds the session id and the expected PDF filename. `Folien-freigeben.command` (repo root) swaps the placeholder for a download link once the PDF exists, then renders and publishes; `Folien-zuruecknehmen.command` reverses it. Edit the block by hand only if you keep both markers intact — the scripts key off them.
- **`*.command` scripts** in the repo root are double-clickable macOS helpers: `Folien-freigeben`, `Folien-zuruecknehmen`, and `Veroeffentlichen` (incremental render + `quarto publish netlify`). They are modelled on the Politische-Ökonomie course's versions.
- **`references/`** — `references.bib` (cited via `@key`) and `jepp.csl` (citation style).
- **`assets/styles/custom.scss`** overrides the bootstrap `cosmo` theme (brand colors in `scss:defaults`) and is the SCSS wired into `_quarto.yml` (`format.html.theme.light`); `assets/scripts/collapse-callouts.html` is an included HTML snippet. (A top-level `css/` dir with `custom.scss`/`custom_style.css` remains from the template but is **not** referenced by `_quarto.yml` — don't edit it expecting an effect.)
- **`figures/`** for site/icon assets (e.g. `figures/icons/course_favicon.png`); large datasets live next to the pages that consume them.
- **`_INBOX/`** holds author working material (course-description drafts, `TODOS.md`, material carried over from other courses) — planning docs, not part of the rendered site, and gitignored.

## Conventions worth knowing

- **`execute: freeze: auto`** (root) means pages with code are *not* re-executed during render unless their source changed; frozen output is cached in `_freeze/` (gitignored). If R output looks stale, that's why.
- Front matter `date` strings drive each session's displayed date; `date-modified: last-modified` auto-updates.
- `_freeze/`, `.quarto/`, `renv/`, and `.Rproj.user/` are build/tooling artifacts and are gitignored. **`_site/` is currently *tracked*** (Netlify deploys the built site from GitHub), so a render shows up as dozens of changed files in `git status` — commit them along with the sources. Never hand-edit `_site/`; re-render instead.
- The site is authored in English; content is academic prose with Quarto callouts (`::: {.callout-note}`), `mermaid` diagrams, and LaTeX math.
