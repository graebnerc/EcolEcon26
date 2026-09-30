# analysis/ — how the lecture figures are made

Every data figure in session 3 ("Working with data") is built here, from openly
available data, by the two R scripts in this folder. None of them is a
screenshot. That is deliberate, and it is the point of the session: if you can
see exactly which series went into a chart and which choices were made along
the way, you can argue with it.

You are welcome to run all of this yourself. You may well want to — the sources
used here are the same ones you will need for your own country analysis, and
the code shows how to get from a raw download to a finished figure.

## Rebuild the figures yourself

You need **R** and a handful of packages:

```r
install.packages(c("tidyverse", "ggrepel", "patchwork", "scales",
                   "jsonlite", "systemfonts"))
```

Or let the project do it for you. This repository uses
[renv](https://rstudio.github.io/renv/), so the exact package versions the
figures were built with are pinned in `renv.lock`. Once you have cloned the
repository, a single call installs them into a project-local library without
touching your usual R setup:

```r
renv::restore()
```

Then, from the repository root:

```bash
Rscript analysis/01_download.R    # fetch the data into analysis/data-raw/
Rscript analysis/02_figures.R     # write PDF + SVG into analysis/figures/
```

The first script needs an internet connection; the second never touches the
network, so once you have the data you can rebuild and modify figures offline.
On macOS you can also just double-click **`Abbildungen-bauen.command`** in the
repository root, which runs both and opens the output folder.

Change a colour, a year range, a country selection — the scripts are meant to
be poked at. If something breaks, the error message should tell you what and
where; several checks are deliberately strict (see below).

## Why there are two output formats

| Format | Used for | Why |
|---|---|---|
| **PDF** | the Keynote deck | vector, with the typeface embedded |
| **SVG** | the revealjs HTML deck | a browser `<img>` cannot display a PDF, but handles SVG natively |

Both are vector, so a figure stays sharp at any zoom and on any projector.
There is deliberately no PNG: raster output only ever existed as a workaround
for that `<img>` limitation, and it went soft the moment anyone zoomed in. The
setting lives in `FORMATS` in `R/euf_style.R`.

The SVG device is cairo (`grDevices::svg`), which writes every letter as an
outline path instead of as a text element. That matters: an SVG loaded through
an `<img>` is an isolated document and cannot see the fonts of the page around
it, so a text-based SVG would quietly fall back to whatever font your machine
happens to have. As outlines it looks identical everywhere. `save_euf()` stops
with a clear message if your R build has no cairo support.

## What is where

| File | What it is |
|---|---|
| `01_download.R` | Downloads every dataset that has an API. Overwrites `data-raw/` on each run. |
| `02_figures.R` | Builds the figures. Reads only local files, never the network. |
| `R/euf_style.R` | The EUF palette, the ggplot theme, and the save helper. Shared by every figure. |
| `data-raw/` | The downloaded CSVs. **Not in git** — recreate them with `01_download.R`. |
| `data-manual/` | The two datasets that cannot be downloaded by script, each with a `README-*.txt` saying exactly where it came from. **In git**, because there is no way to fetch them automatically. |
| `figures/` | The finished figures. **Not in git** — git tracks what *produces* a figure, not the figure itself. Run `02_figures.R` to get them. |

## Which figure is which

| Output | Slide | What it shows |
|---|---|---|
| `fig_06_gdp_by_region` | 6 | GDP per capita by world region, 1820– |
| `fig_07_poverty_lines` | 7 | Share of the world below five poverty lines |
| `fig_08_poverty_longrun` | 8 | Long-run poverty, two measures side by side |
| `fig_09_poverty_vs_gdp` | 9 | Extreme poverty vs GDP per capita, by region |
| `fig_10_gdp_indicators` | 10 | Schooling, child mortality, literacy, doctors vs GDP |
| `fig_11_material_use` | 11 | Material extraction by material group and by region |
| `fig_12_energy_and_emissions` | 12 | Energy use and CO2 vs GDP |
| `fig_14_decoupling` | 14 | GDP vs consumption-based CO2, six countries |
| `fig_15_composite_indicators` | 15 | HDI and Augmented HDI vs GDP |
| `fig_16_safe_and_just` | 16 | Social thresholds achieved vs boundaries transgressed |

## Where the data come from

The session page lists every source with a clickable link, which is the better
starting point if you are looking for data for your own country. What follows
is the same information from the pipeline's side.

- **Our World in Data**, through its grapher CSV API
  (`ourworldindata.org/grapher/<slug>.csv`), for most series. The original
  source behind each series is named in that figure's own caption.
- **World Bank PIP API** for poverty at several poverty lines. PIP publishes
  nowcasts beyond the last survey year; `02_figures.R` drops them via
  `estimate_type == "actual"`, so no forecast is ever drawn as if it were an
  observation.
- **UN IRP Global Material Flows Database** for material extraction. This one
  has no API — it comes out of an interactive portal — so
  `data-manual/mfa4_export.csv` is refreshed by hand roughly once a year.
  `data-manual/README-mfa4_export.txt` says where to get it and what the file
  has to contain. `02_figures.R` validates it on every run and stops with a
  specific message if the export is wrong or partial. If the file is missing
  altogether, the figure falls back to the UN SDG API (`EN_MAT_DOMCMPT`,
  consumption rather than extraction, 2000 onwards) and says so in its own
  subtitle — so the build never breaks silently.
- **Leeds, "A Good Life For All Within Planetary Boundaries"** for figure 16:
  the supplementary data of Fanning, O'Neill, Hickel and Roux (2022), 148
  countries, 6 biophysical and 11 social indicators, annually 1992–2015. Also
  not scriptable — goodlife.leeds.ac.uk answers scripted requests with HTTP 403
  — so it lives in `data-manual/fanning2022_trends.csv.gz`, described in
  `README-fanning2022_trends.txt`. Only the historical sheets are kept; the
  file's 2016–2050 business-as-usual projections are deliberately left out,
  because projections have no place on a slide that presents itself as data.

## Three things to know before you trust these figures

1. **The right-hand panel of figure 15 is the *Augmented* HDI** (Prados de la
   Escosura: health, education and civil liberties), not the HDI with the
   income component removed — Our World in Data no longer publishes that exact
   series. The point survives either way: a composite built without income
   still tracks income closely.
2. **The poverty lines changed.** Older versions of this material used 2011-PPP
   lines ($1.90, $3.20, …). The World Bank has moved to 2021 PPP, so the lines
   here are $3.00, $4.20 and $8.30. The levels are therefore *not* comparable
   with older charts you may find elsewhere — which is exactly the kind of
   thing worth flagging on a poster.
3. **Figure 16 is a reproduction, not an approximation.** Both axes are simply
   counts of normalised values above 1, and the country selection is the rule
   quoted in the source paper's own figure caption: all six biophysical
   indicators and at least 9 of the 10 social ones — read literally, meaning
   complete data in *every* year 1992–2015, with Social Support excluded as the
   eleventh. `02_figures.R` asserts that this yields exactly the 91 countries
   the paper reports, and separately asserts that the "safe and just" corner it
   shades really is empty. A corrupted file or a changed rule therefore fails
   the build instead of quietly producing a wrong-but-plausible figure.

   **1992–2015 is as recent as this gets.** The 2025 successor (Fanning and
   Raworth, "Doughnut of social and planetary boundaries", *Nature*) runs to
   2021/22, but publishes only global and three-income-cluster aggregates,
   never named countries — so it cannot produce a per-country scatter. Note
   also that the country doughnuts on the preceding slide come from the older
   2018 snapshot, so those two slides are of different vintages.

## Typeface

The figures are set in **Inter**, the same face as the slides, so a chart does
not sit in a different typeface from the text around it. The candidate list is
`FONT_CANDIDATES` in `R/euf_style.R`; the first one installed on your machine
wins, and the script prints which it picked. If you have none of them, the
figures still build — they will just use your device default.

## Colours

`R/euf_style.R` carries a six-hue categorical palette for the world regions,
checked for colourblind separation. Its worst adjacent pair sits in the band
that is only acceptable *with* a second visual cue, which is why every figure
using it also carries a legend plus either direct labels or facet titles. If
you change the hues, check them again before using the result — and the same
advice holds for your own poster.
