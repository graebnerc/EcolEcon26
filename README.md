# Ecological Economics (Winter 2026/27)

Course website for *Ecological Economics* at Europa-Universität Flensburg,
taught by Claudius Gräbner-Radkowitsch and Anna-Katharina Kothe.

**→ <https://ecological-economics26.netlify.app/>**

The course is poster-based: students analyse a country or region and present
the result at a poster conference. See
[the seminar description](content/material/SeminarDescription.qmd) for the
schedule and [examination.qmd](content/material/examination.qmd) for the task.

## What is where

| | |
|---|---|
| `content/material/` | one page per session, plus the schedule and the exam |
| `content/material/slides/` | the decks: Keynote exports as PDF, web versions as `.qmd` |
| `analysis/` | the R scripts that build the lecture figures from open data — [start here](analysis/) if you want to reproduce or reuse them |
| `references/` | the bibliography |
| `_quarto.yml` | navigation, theme, and which files get rendered |

## Building it

```bash
quarto preview   # live preview while editing
quarto render    # build the site into _site/
```

Package versions are pinned with [renv](https://rstudio.github.io/renv/); run
`renv::restore()` once after cloning.

Publishing is a local step, not CI: `Veroeffentlichen.command` renders and
uploads to Netlify. A push to GitHub does **not** update the live site.

---

Built with [Quarto](https://quarto.org), from
[this template](https://github.com/jonjoncardoso/quarto-template-for-university-courses).
Content © the authors; see [LICENSE](LICENSE) for the code.
