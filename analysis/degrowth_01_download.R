# ============================================================================
#  degrowth_01_download.R — fetch the data for the session 8b figures
#
#  Writes into analysis/data-raw/ (gitignored); an existing file is overwritten.
#  degrowth_02_figures.R reads this file, the OWID CO2 file of
#  policy_01_download.R and the IRP export in analysis/data-manual/.
#
#  Three sources:
#    · World Bank, World Development Indicators, NY.GDP.MKTP.KD
#        (GDP, constant 2015 US$), for the world and the countries on the slides.
#        Annual values. The Maddison GDP in the OWID file has only benchmark
#        years for the world before 2008, which would draw straight lines.
#    · Heating in German housing, 1990-2020 (living space per person, heat
#        demand per m² and per person), as published with Gräbner-Radkowitsch,
#        Lage & Wiese (2024) in a GitHub gist. Original data: Destatis, AGEB.
#    · Our World in Data, technology adoption by US households (Comin and
#        Hobijn 2004, and others), for the adoption curves.
#
#  Run:  Rscript analysis/degrowth_01_download.R
# ============================================================================

RAW <- file.path("analysis", "data-raw")
dir.create(RAW, showWarnings = FALSE, recursive = TRUE)

CODES <- c("WLD", "CHN", "DEU", "TUR")
url <- paste0("https://api.worldbank.org/v2/country/", paste(CODES, collapse = ";"),
              "/indicator/NY.GDP.MKTP.KD?format=json&per_page=1000&date=1960:2030")
js <- jsonlite::fromJSON(url)
if (length(js) < 2 || !is.data.frame(js[[2]])) stop("World Bank API: unexpected answer")
gdp <- data.frame(country = js[[2]]$country$value,
                  iso3    = js[[2]]$countryiso3code,
                  year    = as.integer(js[[2]]$date),
                  gdp     = js[[2]]$value)
gdp <- gdp[!is.na(gdp$gdp), ]
if (!all(CODES %in% gdp$iso3)) stop("World Bank API: missing ",
                                    paste(setdiff(CODES, gdp$iso3), collapse = ", "))

readr::write_csv(gdp, file.path(RAW, "wdi_gdp_constant.csv"))
message("      -> wdi_gdp_constant.csv (", nrow(gdp), " rows, ",
        min(gdp$year), "-", max(gdp$year), ")")

# The gist is pinned to one revision, so the data cannot change under the figure.
curl::curl_download(
  paste0("https://gist.githubusercontent.com/graebnerc/346608931c440c1a27cd431476b43779/raw/",
         "6724d8eb93c2f3c0945051338d71b1c37ffa5eae/rebound_data.csv"),
  file.path(RAW, "rebound_housing_de.csv"), quiet = TRUE)
message("      -> rebound_housing_de.csv")

h <- curl::new_handle(useragent = "Our World In Data data fetch/1.0")
curl::curl_download(
  "https://ourworldindata.org/grapher/technology-adoption-by-households-in-the-united-states.csv",
  file.path(RAW, "owid_technology_adoption_us.csv"), quiet = TRUE, handle = h)
message("      -> owid_technology_adoption_us.csv")
