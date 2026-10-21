# ============================================================================
#  trade_01_download.R — fetch every dataset the session 5 figures need
#
#  Session 5 ("Free trade: blessing or curse?") counterpart of 01_download.R.
#  Writes into analysis/data-raw/ (gitignored); existing files are
#  overwritten. trade_02_figures.R reads only what this script wrote.
#
#  Five sources:
#    · Harvard Growth Lab, Atlas of Economic Complexity — GraphQL API
#        (South Korea's exports by SITC section; country x product exports
#        and RCA for every country, HS92 4-digit)
#    · Harvard Dataverse, "Product Space Networks" (CC0) — layout + edges
#    · Geronimi, Anani & Taranco (2018), Mendeley Data — the Grilli-Yang
#        commodity price index, 1900-2016 (CC BY-NC 3.0)
#    · World Bank Pink Sheet — real commodity price indices, 1960-
#    · Our World in Data — GDP per capita (Maddison), solar PV learning curve
#
#  Run:  Rscript analysis/trade_01_download.R
# ============================================================================

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(purrr); library(jsonlite)
  library(tibble); library(curl)
})

RAW <- file.path("analysis", "data-raw")
dir.create(RAW, showWarnings = FALSE, recursive = TRUE)

# The year the RCA matrix and the product spaces are drawn for. The Atlas
# usually lags two years behind the calendar; bump this when it moves on.
ATLAS_YEAR <- 2024

fetch <- function(url, file) {
  dest <- file.path(RAW, file)
  curl::curl_download(url, dest, quiet = TRUE)
  message("      -> ", file)
  invisible(dest)
}

# ---- 1 · Atlas of Economic Complexity --------------------------------------
atlas <- function(query) {
  h <- curl::new_handle()
  curl::handle_setheaders(h, "Content-Type" = "application/json")
  curl::handle_setopt(h, postfields = jsonlite::toJSON(list(query = query),
                                                       auto_unbox = TRUE))
  res <- curl::curl_fetch_memory("https://atlas.hks.harvard.edu/api/graphql",
                                 handle = h)
  out <- jsonlite::fromJSON(rawToChar(res$content))
  if (!is.null(out$errors)) stop("Atlas API: ", paste(out$errors$message, collapse = "; "))
  out$data[[1]]
}

message("ATLAS countries")
countries <- atlas("{ locationCountry { countryId iso3Code nameShortEn incomelevelEnum } }")
write_csv(countries, file.path(RAW, "atlas_countries.csv"))

message("ATLAS location groups (regions)")
groups <- atlas("{ locationGroup { groupId groupName groupType members } }") |>
  filter(groupType %in% c("region", "subregion", "wdi_region", "wdi_income_level")) |>
  tidyr::unnest_longer(members) |>
  transmute(group = groupName, group_type = groupType, countryId = members)
write_csv(groups, file.path(RAW, "atlas_groups.csv"))

message("ATLAS SITC sections")
sitc <- atlas("{ productSitc(productLevel: 1) { productId code nameShortEn } }")
write_csv(sitc, file.path(RAW, "atlas_sitc_sections.csv"))

# South Korea is country 410 (its ISO numeric code, which the Atlas uses).
message("ATLAS South Korea, exports by SITC section, 1962-")
kor <- atlas(paste0(
  "{ countryProductYear(productClass: SITC, servicesClass: unilateral, ",
  "productLevel: 1, countryId: 410, yearMin: 1962, yearMax: 2100) ",
  "{ year productId exportValue } }"))
write_csv(kor, file.path(RAW, "atlas_kor_sitc.csv"))
message("      -> atlas_kor_sitc.csv (", min(kor$year), "-", max(kor$year), ")")

message("ATLAS HS92 4-digit products")
prods <- atlas(paste0("{ productHs92(productLevel: 4) { productId code nameShortEn ",
                      "naturalResource greenProduct topParent { nameShortEn } } }")) |>
  mutate(sector = topParent$nameShortEn) |> select(-topParent)
write_csv(prods, file.path(RAW, "atlas_hs92_products.csv"))

# Every country x every 4-digit product for one year: ~290,000 rows, ~25 MB
# of JSON. One request; the API answers it in well under a minute.
message("ATLAS all countries x HS92 4-digit, ", ATLAS_YEAR)
cpy <- atlas(paste0(
  "{ countryProductYear(productClass: HS92, productLevel: 4, ",
  "yearMin: ", ATLAS_YEAR, ", yearMax: ", ATLAS_YEAR, ") ",
  "{ countryId productId year exportValue exportRca } }"))
write_csv(cpy, file.path(RAW, "atlas_cpy_hs92.csv"))
message("      -> atlas_cpy_hs92.csv (", format(nrow(cpy), big.mark = ","), " rows)")

# Lithium carbonate (HS92 283691, Atlas product id 6009) for the Atacama case
# in L06a (environmental conflicts, session 6): who exports it, and where
# Chile's (country 152) exports go.
message("ATLAS lithium carbonate: exporters and Chile's destinations, ", ATLAS_YEAR)
li_world <- atlas(paste0(
  "{ countryProductYear(productClass: HS92, productLevel: 6, productId: 6009, ",
  "yearMin: ", ATLAS_YEAR, ", yearMax: ", ATLAS_YEAR, ") { countryId year exportValue } }"))
write_csv(li_world, file.path(RAW, "atlas_lithium_exporters.csv"))
li_chl <- atlas(paste0(
  "{ countryCountryProductYear(countryId: 152, productClass: HS92, productLevel: 6, ",
  "productId: 6009, yearMin: ", ATLAS_YEAR, ", yearMax: ", ATLAS_YEAR, ") ",
  "{ partnerCountryId year exportValue } }"))
write_csv(li_chl, file.path(RAW, "atlas_lithium_chile_destinations.csv"))

# ---- 2 · Product space layout and edges (Harvard Dataverse, CC0) -----------
# doi:10.7910/DVN/FCDZBN. Dataverse file ids are stable per version; if a new
# version appears, the ids change — look them up on the dataset page.
message("DVN   product space network (doi:10.7910/DVN/FCDZBN)")
dvn <- function(id, file) fetch(paste0(
  "https://dataverse.harvard.edu/api/access/datafile/", id, "?format=original"), file)
dvn(13438222, "productspace_layout_hs92.csv")
dvn(13438220, "productspace_edges_hs92.csv")

# ---- 3 · Grilli-Yang commodity price index, 1900-2016 ----------------------
# Pfaffenzeller's update of the GYCPI, extended to 2016 by Geronimi, Anani &
# Taranco; doi:10.17632/j24mjpcrrz.1. Licence CC BY-NC 3.0 — fine for a
# course, and the figure caption carries the attribution.
message("MDY   Grilli-Yang commodity price index (doi:10.17632/j24mjpcrrz.1)")
fetch(paste0("https://data.mendeley.com/public-files/datasets/j24mjpcrrz/files/",
             "b0d101be-34d6-494b-afe4-d736e6f93ea7/file_downloaded"),
      "gycpi_1900_2016.xlsx")

# ---- 4 · World Bank Pink Sheet, annual, real indices -----------------------
# Used to carry the Grilli-Yang series past 2016. The URL changes with every
# monthly release; if it 404s, take the current "Annual prices" link from
# https://www.worldbank.org/en/research/commodity-markets.
message("WB    Pink Sheet, annual indices")
fetch(paste0("https://thedocs.worldbank.org/en/doc/18675f1d1639c7a34d463f59263ba0a2-",
             "0050012025/related/CMO-Historical-Data-Annual.xlsx"),
      "wb_cmo_annual.xlsx")

# ---- 5 · Our World in Data -------------------------------------------------
owid <- function(slug, file) {
  message("OWID  ", slug)
  fetch(paste0("https://ourworldindata.org/grapher/", slug,
               ".csv?csvType=full&useColumnShortNames=true"), file)
}
owid("gdp-per-capita-maddison-project-database",  "gdp_maddison.csv")
owid("solar-pv-prices-vs-cumulative-capacity",    "solar_learning_curve.csv")

message("\nDone. Data in ", RAW, "/")
