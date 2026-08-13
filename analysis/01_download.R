# ============================================================================
#  01_download.R — fetch every dataset the session 3b figures need
#
#  Writes plain CSVs into analysis/data-raw/ (gitignored). Re-run whenever you
#  want fresher numbers; existing files are overwritten. Nothing here depends
#  on 02_figures.R, and 02_figures.R reads only what this script wrote — so the
#  figures are reproducible from a clean checkout with an internet connection.
#
#  Three sources:
#    · Our World in Data grapher CSV API  (most series)
#    · World Bank PIP API                 (poverty at several poverty lines)
#    · UN SDG Indicators API              (material consumption by material type)
#
#  Run:  Rscript analysis/01_download.R
# ============================================================================

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(purrr); library(jsonlite); library(tibble)
})

RAW <- file.path("analysis", "data-raw")
dir.create(RAW, showWarnings = FALSE, recursive = TRUE)

# ---- 1 · Our World in Data -------------------------------------------------
# The grapher CSV endpoint returns the full long-format series behind a chart.
# `useColumnShortNames=true` gives stable machine-readable column names.
owid <- function(slug, file) {
  url <- paste0("https://ourworldindata.org/grapher/", slug,
                ".csv?csvType=full&useColumnShortNames=true")
  dest <- file.path(RAW, file)
  message("OWID  ", slug)
  utils::download.file(url, dest, quiet = TRUE, method = "libcurl")
  n <- nrow(readr::read_csv(dest, show_col_types = FALSE, progress = FALSE))
  message("      -> ", file, " (", format(n, big.mark = ","), " rows)")
}

owid("gdp-per-capita-maddison-project-database",   "gdp_maddison.csv")            # fig 06, 09
owid("share-of-population-living-in-extreme-poverty-cost-of-basic-needs",
                                                    "poverty_cbn.csv")            # fig 08, 09
owid("share-of-population-in-extreme-poverty",      "poverty_pip_line300.csv")    # fig 08
owid("average-years-of-schooling-vs-gdp-per-capita","gdp_schooling.csv")          # fig 10
owid("child-mortality-gdp-per-capita",              "gdp_childmortality.csv")     # fig 10
owid("literacy-rate-vs-gdp-per-capita",             "gdp_literacy.csv")           # fig 10
owid("medical-doctors-per-1000-people-vs-gdp-per-capita", "gdp_doctors.csv")      # fig 10
owid("energy-use-per-capita-vs-gdp-per-capita",     "gdp_energy.csv")             # fig 12
owid("co2-emissions-vs-gdp",                        "gdp_co2.csv")                # fig 12
owid("co2-emissions-and-gdp-per-capita",            "gdp_co2_consumption.csv")    # fig 14
owid("human-development-index-vs-gdp-per-capita",   "gdp_hdi.csv")                # fig 15
owid("human-development-index-escosura",            "ahdi_escosura.csv")          # fig 15

# ---- 2 · World Bank PIP: share below several poverty lines, World -----------
# PIP reports one poverty line per request, so we loop. Lines are the current
# 2021-PPP international lines plus two higher thresholds used for
# middle/high-income comparisons.
POVLINES <- c(3.00, 4.20, 8.30, 15.00, 30.00)

message("PIP   World aggregate, ", length(POVLINES), " poverty lines")
pip <- purrr::map_dfr(POVLINES, function(pl) {
  url <- paste0("https://api.worldbank.org/pip/v1/pip-grp?country=WLD&year=all",
                "&povline=", format(pl, nsmall = 2), "&group_by=wb&format=csv")
  readr::read_csv(url, show_col_types = FALSE, progress = FALSE) |>
    transmute(year = reporting_year, povline = pl, headcount, estimate_type)
})
# PIP extends past the last survey year with nowcasts/projections. Keep the flag
# so the figures can drop them rather than draw forecasts as if they were data.
readr::write_csv(pip, file.path(RAW, "poverty_pip_lines.csv"))
message("      -> poverty_pip_lines.csv (", nrow(pip), " rows, ",
        min(pip$year), "-", max(pip$year), ")")

# ---- 3 · UN SDG API: domestic material consumption by material type --------
# Series EN_MAT_DOMCMPT, dimension "Type of product". We pull the World plus the
# five M49 continental regions. Note this is domestic material *consumption*
# (extraction + imports - exports), not extraction; at world level the two
# coincide because trade nets out, at regional level they do not. The figure
# labels it accordingly.
SDG_AREAS <- c(World = 1, Africa = 2, Americas = 19, Asia = 142,
               Europe = 150, Oceania = 9)

message("UNSD  EN_MAT_DOMCMPT for World + 5 regions")
q <- paste0("https://unstats.un.org/sdgapi/v1/sdg/Series/Data",
            "?seriesCode=EN_MAT_DOMCMPT",
            paste0("&areaCode=", SDG_AREAS, collapse = ""),
            "&pageSize=5000")
sdg <- jsonlite::fromJSON(q, simplifyDataFrame = TRUE)
stopifnot(sdg$totalPages == 1)   # widen pageSize if this ever trips

material <- tibble::tibble(
  area     = sdg$data$geoAreaName,
  year     = as.integer(sdg$data$timePeriodStart),
  type     = sdg$data$dimensions$`Type of product`,
  tonnes   = suppressWarnings(as.numeric(sdg$data$value))
) |>
  filter(!is.na(tonnes))
readr::write_csv(material, file.path(RAW, "material_dmc.csv"))
message("      -> material_dmc.csv (", nrow(material), " rows, ",
        min(material$year), "-", max(material$year), ")")

message("\nDone. Raw data in ", RAW, "/")
