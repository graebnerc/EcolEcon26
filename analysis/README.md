# analysis/ — reproducible figures for the lecture slides

The data figures on the session 3b slides ("Working with data") used to be
screenshots from Our World in Data. They are now rebuilt from the raw data, so
they can be refreshed every term instead of ageing in place.

## How to rebuild

Double-click **`Abbildungen-bauen.command`** in the repo root. That runs both
scripts and opens the output folder.

From a terminal:

```bash
Rscript analysis/01_download.R    # fetch fresh data into analysis/data-raw/
Rscript analysis/02_figures.R     # write PDF + PNG into analysis/figures/
```

Then drag the PDFs into Keynote — they are vector, so they stay sharp at any
size. PNGs are there for quick previews and for anything that chokes on PDF.

## What is where

| File | Purpose |
|---|---|
| `01_download.R` | Downloads every scriptable dataset. Overwrites `data-raw/` each run. |
| `02_figures.R` | Builds the figures. Reads only local files, never the network. |
| `R/euf_style.R` | EUF palette, ggplot theme, save helper. Shared by all figures. |
| `data-raw/` | Downloaded CSVs. **Gitignored** — recreate with `01_download.R`. |
| `data-manual/` | The one dataset with no API, plus a txt saying how to refresh it. Tracked. |
| `figures/` | Output, tracked in git so the slides have a stable source. |

## Figures and the slides they replace

| Output | Slide | Content |
|---|---|---|
| `fig_06_gdp_by_region` | 6 | GDP per capita by world region, 1820– |
| `fig_07_poverty_lines` | 7 | Share of the world below five poverty lines |
| `fig_08_poverty_longrun` | 8 | Long-run poverty, two measures side by side |
| `fig_09_poverty_vs_gdp` | 9 | Extreme poverty vs GDP per capita, by region |
| `fig_10_gdp_indicators` | 10 | Schooling, child mortality, literacy, doctors vs GDP |
| `fig_11_material_use` | 11 | Material consumption by material group and by region |
| `fig_12_energy_and_emissions` | 12 + 13 | Energy use and CO2 vs GDP, as one figure |
| `fig_14_decoupling` | 14 | GDP vs consumption-based CO2, six countries |
| `fig_15_composite_indicators` | 15 | HDI and Augmented HDI vs GDP |

## Data sources

- **Our World in Data** grapher CSV API (`ourworldindata.org/grapher/<slug>.csv`)
  for most series. Underlying sources are named in each figure's caption.
- **World Bank PIP API** for poverty at several poverty lines. PIP publishes
  nowcasts beyond the last survey year; `02_figures.R` drops them via
  `estimate_type == "actual"` so no forecast is ever drawn as data.
- **UN IRP Global Material Flows Database** for material extraction. This is the
  only source that is **not** scriptable: it comes from an interactive portal, so
  `analysis/data-manual/mfa4_export.csv` is refreshed by hand roughly once a
  year. `analysis/data-manual/README-mfa4_export.txt` says where to get it and
  what the file must contain; `02_figures.R` validates it on every run and stops
  with a specific message if the export is wrong or partial. If the file is
  missing entirely, the figure falls back to the UN SDG API
  (`EN_MAT_DOMCMPT`, consumption rather than extraction, 2000 onwards) and says
  so in its own subtitle, so the build never silently breaks.

## Two things to know before you trust these figures

1. **Slide 15's right panel is the *Augmented* HDI** (Prados de la Escosura:
   health, education and civil liberties), not the "HIHD without the GDP
   metric" of the old slide — Our World in Data no longer publishes that exact
   series. The teaching point survives: a composite built without income still
   tracks income closely.
2. **The poverty lines changed.** The old slide used 2011-PPP lines ($1.90,
   $3.20, …). The World Bank moved to 2021 PPP, so the current lines are $3.00,
   $4.20 and $8.30. The levels are therefore not comparable with the old slide,
   which is itself worth a sentence in the lecture.

## Colours

`R/euf_style.R` carries a six-hue categorical palette for the OWID world
regions, checked for colourblind separation. Its worst adjacent pair sits in the
"acceptable only with a secondary encoding" band, which is why every figure
using it also carries a legend plus either direct labels or facet titles. If you
change the hues, re-check them before shipping.
