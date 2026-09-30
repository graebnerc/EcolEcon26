# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A [Quarto](https://quarto.org) website for the university course "Ecological Economics" (taught by Claudius Gräbner-Radkowitsch, EUF/JKU). The site is rendered to static HTML in `_site/` and published to Netlify at <https://ecological-economics26.netlify.app/> (the site `id` and `url` live in `_publish.yml`). R is used by the figure pipeline in `analysis/` and is available for executable code in pages; package versions are pinned in `renv.lock`.

**Deployment is a local push, not CI.** The Netlify site is *not* linked to GitHub — no repo, no build command, no server-side build. The built site is uploaded straight from the author's machine with `quarto publish netlify` (wrapped by the `*.command` scripts below), so `_site/` is gitignored and GitHub serves only as source history. A `git push` therefore does **not** update the live site; running one of the publish scripts does.

This repo started from a generic academic-course template (see `README.md` for what to change when reusing it) and was carried over from an earlier "Development Economics" edition, so stray old names may still surface — treat anything saying *Development Economics* as stale. It now targets the **Winter 2026/27** edition (the autumn term; repo directory `2026_Fall`). The course is **poster- and presentation-based**: the examination is a country-analysis poster (`content/material/examination.qmd`), and several sessions cover argumentation, poster design, and student presentations rather than problem-set exercises. Note that `references/references.bib` and in-text citations legitimately contain years like `2025` (publication/retrieval years, prize years, etc.) — these are real data, not edition labels, and must not be bumped. The authoritative course schedule lives in the table in `content/material/SeminarDescription.qmd`; session pages are numbered to match it (and match the sidebar in `_quarto.yml`).

## Commands

```bash
quarto preview        # Live-reloading local preview (use during editing)
quarto render         # Build the full site into _site/
quarto render content/material/s_05_Trade.qmd   # Render a single page
quarto publish netlify   # Publish to Netlify (target in _publish.yml)
```

There is no test suite or linter — "building" means rendering with Quarto. Most renders are pure Markdown; R is needed for two things: any page with `{r}` chunks (at present only `content/material/template/session00.qmd`), and the figure pipeline in `analysis/`.

**renv is activated.** `.Rprofile` sources `renv/activate.R`, so every R process started in this repo — including the one Quarto uses — resolves packages against the project library in `renv/library/`, not against the user library. After cloning, run `R -e 'renv::restore()'` once to install the pinned versions.

Tracked: `renv.lock`, `.Rprofile`, `renv/activate.R`, `renv/settings.json`. **Not** tracked: `renv/library/` (renv writes its own `renv/.gitignore` for that, and the root `.gitignore` repeats it) — the library is only symlinks into renv's global cache anyway.

After adding or removing a package, run `renv::snapshot()` to update the lockfile; `renv::status()` reports drift between library and lockfile, and `renv::dependencies()` shows which packages renv found and in which file. The snapshot type is `implicit`, so a package only enters the lockfile if some file in the project actually references it. Note that `yaml` must be installed for renv to scan `.qmd` files at all — without it, dependency discovery silently skips them.

## Architecture

- **`_quarto.yml`** is the control center: it defines the website type, the navbar/sidebar navigation, the theme, the bibliography/CSL, and — critically — the `render:` glob list. **A new `.qmd` page will not be built unless its path matches an entry under `project.render`** (currently `index.qmd`, `content/index.qmd`, `content/material/*.qmd`, `content/material/session*/*.qmd`, and `content/material/slides/*.qmd`), and it will not appear in navigation unless added to `website.sidebar.contents`.
- **`index.qmd`** (root) is the landing page; **`content/index.qmd`** is the "Getting Started" page.
- **`content/material/`** holds the per-session lecture pages, named **`s_NN[x]_Slug.qmd`** where `NN` is the schedule session number, an optional lowercase letter (`a`, `b`, …) splits a session into parts, and `Slug` is a one-to-two-word topic. Examples: `s_05_Trade.qmd` (single), and `s_01a_Introduction.qmd` / `s_01b_Theories.qmd`, `s_03a_TextDiscussion.qmd` / `s_03b_WorkingWithData.qmd`, `s_04a_ScientificArgumentation.qmd` / `s_04b_PosterDesign.qmd`, `s_07a_PolicyInstruments.qmd` / `s_07b_ETS.qmd` (split sessions). `content/material/examination.qmd` describes the poster exam and is the *only* assessment rubric — there is no separate Moodle rubric. `content/material/template/session00.qmd` is the starting point for a new session. Cross-links between pages use the rendered `.html` name (same basename), not `.qmd`.
- **`content/material/SeminarDescription.qmd`** carries the authoritative schedule table *and* the general references (via `nocite` + a `#refs` div). It renders to both HTML and a downloadable PDF, so links in it are **absolute site URLs** — relative `.qmd` links would break in the PDF. There is deliberately no separate material-overview page.
- **`content/material/slides/`** holds the lecture material. Two kinds live here. **Keynote exports** are static `EcolEcon26_LNN[x]_*.pdf` files (e.g. `slides/EcolEcon26_L05_Trade.pdf`), with sources in `slides/_keynote/` and superseded ones in `slides/_old/`; `slides/ExamplePoster/` holds example student posters (PDF). **revealjs decks** are `EcolEcon26_LNN[x]_*.qmd` built on `slides/euf-slides.scss` (e.g. `slides/EcolEcon26_L03b_Data.qmd`) — these are project render targets, so `quarto render` writes their HTML into `_site/content/material/slides/` and *not* next to the source.

  **Slides are published only after the lecture**, via a marker block on each session page:

  ```
  <!--slides:05:EcolEcon26_L05_Trade.pdf-->
  ::: {.slides-pending}
  📽️ Slides will be made available after the lecture.
  :::
  <!--/slides:05-->
  ```

  The marker holds the session id and the deck's filename, and **the extension decides what gets published**: a `.pdf` becomes a download link, a `.html` (a revealjs deck, named by its rendered filename) becomes a 16:9 iframe embed plus an "open in a separate tab" button and a callout explaining Tools → PDF Export Mode. `Folien-freigeben.command` (repo root) performs the swap once the file exists — for a `.html` marker it checks for the deck's `.qmd`, since the HTML itself is only built into `_site` — then renders and publishes; `Folien-zuruecknehmen.command` reverses it. Edit the block by hand only if you keep both markers intact — the scripts key off them.
- **`*.command` scripts** in the repo root are double-clickable macOS helpers: `Folien-freigeben`, `Folien-zuruecknehmen`, and `Veroeffentlichen` (incremental render + `quarto publish netlify`). They are modelled on the Politische-Ökonomie course's versions.
- **`references/`** — `references.bib` (cited via `@key`) and `jepp.csl` (citation style).
- **`assets/styles/custom.scss`** overrides the bootstrap `cosmo` theme (brand colors in `scss:defaults`) and is the SCSS wired into `_quarto.yml` (`format.html.theme.light`); `assets/scripts/collapse-callouts.html` is an included HTML snippet. (A top-level `css/` dir with `custom.scss`/`custom_style.css` remains from the template but is **not** referenced by `_quarto.yml` — don't edit it expecting an effect.)
- **`figures/`** for site/icon assets (e.g. `figures/icons/course_favicon.png`); large datasets live next to the pages that consume them.
- **`_INBOX/`** holds author working material (course-description drafts, `TODOS.md`, material carried over from other courses) — planning docs, not part of the rendered site, and gitignored.

## Conventions worth knowing

- **`execute: freeze: auto`** (root) means pages with code are *not* re-executed during render unless their source changed; frozen output is cached in `_freeze/` (gitignored). If R output looks stale, that's why.
- Front matter `date` strings drive each session's displayed date; `date-modified: last-modified` auto-updates.
- `_site/`, `_freeze/`, `.quarto/`, `renv/`, and `.Rproj.user/` are build/tooling artifacts and are gitignored — don't hand-edit `_site/`, re-render instead.
- The site is authored in English; content is academic prose with Quarto callouts (`::: {.callout-note}`), `mermaid` diagrams, and LaTeX math.
