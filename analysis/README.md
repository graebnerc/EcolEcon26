# analysis/: the code behind the lecture figures

All data figures in the lectures are produced by the R scripts in this folder,
using openly available data. I publish the code so that you can see which
series went into a chart and which choices I made along the way, and so that
you can check, change or criticise them.

You can also use the scripts as a starting point for your own country
analysis: most of the sources are the ones you will need anyway, and the code
shows the steps from the raw download to the finished figure.

## Overview

| Session | Scripts | Figures | Data sources with links |
|---|---|---|---|
| 3: Working with data | `01_download.R`, `02_figures.R` | GDP, poverty, material use, emissions, the doughnut | [session page](https://ecological-economics26.netlify.app/content/material/s_03b_WorkingWithData.html#data-sources-for-the-figures) |
| 5: Free trade | `trade_01_download.R`, `trade_02_figures.R` | South Korea, solar PV, terms of trade, economic complexity, product space | [session page](https://ecological-economics26.netlify.app/content/material/s_05_Trade.html#data-sources-for-the-figures) |

For each session there are two scripts. The download script fetches the data
and needs an internet connection. The figure script only reads the downloaded
files, so once you have the data you can work offline.

If you only need the data and not the code, the session pages linked above are
the better place to start. They link to every source, and most of these let you
download the data for your country directly.

## Running the scripts

You need R and the following packages:

```r
install.packages(c("tidyverse", "ggrepel", "patchwork", "scales",
                   "jsonlite", "systemfonts", "readxl", "curl"))
```

Alternatively, use the package versions I used. They are recorded in
`renv.lock` via [renv](https://rstudio.github.io/renv/). After cloning the
repository, run

```r
renv::restore()
```

This installs the packages into a library inside the project and leaves your
usual R setup alone.

Then run the scripts from the repository root, i.e. the folder that contains
`analysis/`:

```bash
# Session 3
Rscript analysis/01_download.R          # data go to analysis/data-raw/
Rscript analysis/02_figures.R           # figures go to analysis/figures/

# Session 5
Rscript analysis/trade_01_download.R
Rscript analysis/trade_02_figures.R
```

In RStudio, open the project file, open a script and click *Source*. Opening
the project sets the working directory correctly. On macOS, double-clicking
`Abbildungen-bauen.command` in the repository root runs the two session 3
scripts and opens the folder with the results.

Feel free to change countries, years or colours. Some checks in the scripts
are strict on purpose (see below); if one of them fails, the error message
says what went wrong.

## Session 3: working with data

### Figures

| File | Slide | Content |
|---|---|---|
| `fig_06_gdp_by_region` | 6 | GDP per capita by world region, since 1820 |
| `fig_07_poverty_lines` | 7 | Share of the world population below five poverty lines |
| `fig_08_poverty_longrun` | 8 | Long-run poverty, two measures |
| `fig_09_poverty_vs_gdp` | 9 | Extreme poverty vs. GDP per capita, by region |
| `fig_10_gdp_indicators` | 10 | Schooling, child mortality, literacy and doctors vs. GDP |
| `fig_11_material_use` | 11 | Material extraction by material group and by region |
| `fig_12_energy_and_emissions` | 12 | Energy use and CO2 vs. GDP |
| `fig_14_decoupling` | 14 | GDP vs. consumption-based CO2, six countries |
| `fig_15_composite_indicators` | 15 | HDI and Augmented HDI vs. GDP |
| `fig_16_safe_and_just` | 16 | Social thresholds achieved vs. planetary boundaries transgressed |

### Data

- **Our World in Data** for most series, via its CSV interface
  (`ourworldindata.org/grapher/<name>.csv`). The original source of each
  series is given in the caption of the figure.
- **World Bank Poverty and Inequality Platform (PIP)** for poverty at several
  poverty lines. PIP also publishes nowcasts for years after the last survey.
  `02_figures.R` removes them (`estimate_type == "actual"`), so only
  observed values are plotted.
- **UN IRP Global Material Flows Database** for material extraction. There is
  no API for it, so I download `data-manual/mfa4_export.csv` by hand about
  once a year; `data-manual/README-mfa4_export.txt` describes how.
  `02_figures.R` checks the file on every run and stops if it is incomplete.
  If the file is missing, the figure uses the UN SDG database instead (series
  `EN_MAT_DOMCMPT`, which measures consumption rather than extraction, from
  2000 onwards), and its subtitle says so.
- **"A Good Life For All Within Planetary Boundaries"** (University of Leeds)
  for figure 16, i.e. the supplementary data of Fanning, O'Neill, Hickel and
  Roux (2022): 148 countries, 6 biophysical and 11 social indicators,
  1992–2015. The website blocks scripted downloads, so the file is stored in
  `data-manual/fanning2022_trends.csv.gz` (see
  `README-fanning2022_trends.txt`). I kept only the historical data and
  dropped the projections for 2016–2050 contained in the original file.

### Caveats

1. The right panel of figure 15 shows the *Augmented* HDI by Prados de la
   Escosura (health, education and civil liberties). It is not the HDI
   without its income component, because Our World in Data no longer
   publishes that series. The argument on the slide holds for both: an index
   without income still moves closely with income.
2. The poverty lines have changed. Older material uses lines in 2011 PPP
   ($1.90, $3.20, ...). The World Bank now uses 2021 PPP, so the lines here
   are $3.00, $4.20 and $8.30, and the levels cannot be compared with older
   charts. If you run into such a break in your own data, mention it on the
   poster.
3. Figure 16 reproduces the figure in Fanning et al. (2022). Both axes count
   indicators with normalised values above 1. The country selection follows
   the rule in the caption of the original figure: complete data for all six
   biophysical and at least 9 of the 10 social indicators in every year
   1992–2015 (social support, the eleventh, is not counted). `02_figures.R`
   checks that this gives the 91 countries reported in the paper and that no
   country is in the "safe and just" corner. If the data or the rule change,
   the script stops.

   There are no more recent country data. The follow-up study by Fanning and
   Raworth (2025, *Nature*) covers the years up to 2021/22, but only reports
   global values and three income groups. The country doughnuts on the slide
   before figure 16 come from an older data release (2018).

## Session 5: free trade

### Figures

Slide titles refer to the
[slides of session 5](https://ecological-economics26.netlify.app/content/material/s_05_Trade.html).

| File | Slide | Content |
|---|---|---|
| `fig_L05_14_korea_gdp` | Example case: South Korea | GDP per capita of South Korea, Western Europe, the world and Sub-Saharan Africa, since 1820 |
| `fig_L05_14_korea_exports_value`, `_share` | Example case: South Korea | South Korea's goods exports by product group since 1962, in US$ and as shares |
| `fig_L05_16_solar_learning` | Example: China and the solar panel boom | Price of solar modules vs. cumulative installed capacity |
| `fig_L05_16_pv_production` | Example: China and the solar panel boom | Production of solar modules by country, 2024 |
| `fig_L05_20_terms_of_trade` | The Terms-of-Trade problem | Grilli-Yang index of real commodity prices, since 1900 |
| `fig_L05_21_rca_matrix` | Technologically unequal exchange | Countries × products with RCA ≥ 1 |
| `fig_L05_24_product_space` | The product space | The product space |
| `fig_L05_25_product_space_groups` | The product space | The product space for three groups of countries (`_blind`: the same without panel titles) |
| `fig_L06a_lithium_trade` | Environmental conflicts (session 6) | Exporters of lithium carbonate, and the destinations of Chile's exports |

The lithium figure is used in session 6, but it is based on the same Atlas
data and therefore built here.

### Data

- **Atlas of Economic Complexity** (Harvard Growth Lab), via its GraphQL API
  (`atlas.hks.harvard.edu/api/graphql`): South Korea's exports, and the
  exports and RCA of all countries for all 4-digit products (HS 1992). The
  year of the matrix and the product spaces is set by `ATLAS_YEAR` at the top
  of `trade_01_download.R`. The Atlas data usually end two years before the
  current year.
- **Product space**: positions and links of the products come from the Growth
  Lab's dataset on Harvard Dataverse (doi:10.7910/DVN/FCDZBN, CC0), so the
  layout is the same as in the Atlas.
- **Grilli-Yang commodity price index**, 1900–2016, in the version of
  Geronimi, Anani and Taranco (2018) on Mendeley Data
  (doi:10.17632/j24mjpcrrz.1).
- **World Bank Pink Sheet** (real commodity price indices) to extend that
  index beyond 2016.
- **Our World in Data** for GDP per capita (Maddison Project Database) and the
  prices of solar modules.
- **IEA-PVPS (2025)** for the production of solar modules by country, as
  reported by pv magazine. I entered these numbers by hand in
  `data-manual/pv_module_production_2024.csv`; the accompanying
  `README-pv_module_production_2024.txt` documents the source.

### Caveats

1. The terms-of-trade series combines two sources. The Grilli-Yang index ends
   in 2016; for later years it is continued with the World Bank's real
   non-energy index, drawn as a dashed line. The address of the World Bank
   file changes with every monthly release. If the download fails, update it
   in `trade_01_download.R`.
2. The matrix and the product spaces only include countries with goods
   exports of at least US$ 1 bn, roughly following the Atlas rankings.
3. In the product spaces for the three country groups, a product is shaded by
   the share of countries in the group that export it with RCA ≥ 1. Adding up
   the exports of a whole group would be misleading: a continent as a whole
   exports a bit of almost everything, even if each of its countries exports
   only a few products.
4. The two numbers in the text of the South Korea slide (growth of GDP per
   capita, share of machinery in exports) are printed by `trade_02_figures.R`
   at the end of its run. I copied them into the slides by hand.

### Economic complexity for your own country

For most posters, the Atlas website is all you need: start with the
[country profiles](https://atlas.hks.harvard.edu/countries) and the
[explore](https://atlas.hks.harvard.edu/explore) section. If you want to work
with the data in R, the API needs only a few lines. The following example
downloads Chile's goods exports by product group since 2000:

```r
library(jsonlite)

query <- '{ countryProductYear(productClass: SITC, servicesClass: unilateral,
            productLevel: 1, countryId: 152, yearMin: 2000, yearMax: 2100)
            { year productId exportValue } }'

h <- curl::new_handle()
curl::handle_setheaders(h, "Content-Type" = "application/json")
curl::handle_setopt(h, postfields = toJSON(list(query = query), auto_unbox = TRUE))
res <- curl::curl_fetch_memory("https://atlas.hks.harvard.edu/api/graphql", handle = h)
exports <- fromJSON(rawToChar(res$content))$data$countryProductYear
```

To adapt it:

- `countryId` is the numeric ISO 3166 code of the country, e.g. 152 for
  Chile, 410 for South Korea, 276 for Germany, 404 for Kenya. The full list is
  saved by the download script in `data-raw/atlas_countries.csv`.
- With `productClass: HS92, productLevel: 4` you get about 1,200 individual
  products instead of 10 product groups. Adding `exportRca` to the fields in
  the last line of the query also gives you the revealed comparative
  advantage of each product.
- `trade_01_download.R` contains all queries used for the lecture, each with
  a short comment.

## Technical notes

This section is not needed for running the scripts.

### Files

| File | Content |
|---|---|
| `01_download.R`, `02_figures.R` | Session 3: download the data, build the figures. |
| `trade_01_download.R`, `trade_02_figures.R` | Session 5: download the data, build the figures. |
| `R/euf_style.R` | Colours, ggplot theme and the function that saves the figures. Used by all scripts. |
| `data-raw/` | The downloaded data. Not in git; the download scripts recreate them and overwrite existing files. |
| `data-manual/` | Data that cannot be downloaded by script, each with a `README-*.txt` describing the source. These are in git. |
| `figures/` | The finished figures. Not in git; the figure scripts recreate them. |

### Output formats

Each figure is saved as PDF (for the Keynote slides) and as SVG (for the HTML
slides, since browsers cannot show a PDF as an image). Both are vector
formats and stay sharp at any size. The formats are set in `FORMATS` in
`R/euf_style.R`.

The SVG files are written with the cairo device (`grDevices::svg`), which
stores letters as shapes rather than as text. An SVG embedded as an image
cannot use the fonts of the surrounding web page, so otherwise the labels
would be shown in whatever font the viewer's computer has. `save_euf()` stops
with a message if your R installation lacks cairo support.

### Font

The figures use Inter, the font of the slides. `FONT_CANDIDATES` in
`R/euf_style.R` lists the fonts the scripts look for; the first one installed
on your computer is used, and the script tells you which. If none is
installed, R's default font is used.

### Colours

`R/euf_style.R` defines six colours for the world regions, chosen to be
distinguishable for people with colour vision deficiencies. Two neighbouring
colours are still fairly close, so every figure that uses them also has a
legend and either direct labels or panel titles. If you change the colours,
check them again, and the same applies to the colours on your poster.
