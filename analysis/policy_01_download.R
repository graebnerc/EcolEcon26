# ============================================================================
#  policy_01_download.R — fetch the dataset for the session 7a Kaya decomposition
#
#  Writes into analysis/data-raw/ (gitignored); an existing file is overwritten.
#  policy_02_figures.R reads only what this script wrote.
#
#  One source:
#    · Our World in Data, CO2 and greenhouse gas emissions dataset
#        (production-based and consumption-based CO2, primary energy, GDP, population)
#
#  Run:  Rscript analysis/policy_01_download.R
# ============================================================================

RAW <- file.path("analysis", "data-raw")
dir.create(RAW, showWarnings = FALSE, recursive = TRUE)

curl::curl_download(
  "https://nyc3.digitaloceanspaces.com/owid-public/data/co2/owid-co2-data.csv",
  file.path(RAW, "owid_co2_data.csv"), quiet = TRUE
)
message("      -> owid_co2_data.csv")
