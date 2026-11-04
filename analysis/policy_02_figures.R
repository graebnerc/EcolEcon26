# ============================================================================
#  policy_02_figures.R — Kaya decomposition of production-based (territorial) CO2 (session 7a)
#
#  CO2 = P * (GDP/P) * (E/GDP) * (CO2/E)
#
#  Splits the change in CO2 between two years exactly into the four factors,
#  with the additive log-mean Divisia index (LMDI-I):
#    effect of factor f = L * ln(f_end / f_start),
#    L = (CO2_end - CO2_start) / ln(CO2_end / CO2_start)
#  The four effects sum to the total change, with no residual. Method: Ang (2005),
#  Energy Policy 33(7), 867-871, https://doi.org/10.1016/j.enpol.2003.10.010
#  The steps for Germany are on the session page (callout "The computations
#  behind the decomposition"); the first table printed below has the same numbers.
#
#  The effects are accounting contributions, not causes: the identity is static
#  and does not show how the terms affect each other.
#
#  The numbers go into the waterfall on the slide, which is drawn by hand as an
#  animated SVG: if they change here, change them in
#  content/material/slides/EcolEcon26_L07a_PolicyInstruments.qmd as well.
#
#  For your poster: put your country into `countries` and read the table.
#
#  Run:  Rscript analysis/policy_02_figures.R
# ============================================================================

suppressPackageStartupMessages({ library(readr); library(dplyr) })

countries <- c("Germany", "China")
start     <- 1990
end       <- 2022   # latest year with GDP in the dataset

owid <- read_csv(file.path("analysis", "data-raw", "owid_co2_data.csv"),
                 show_col_types = FALSE)

# The steps for each term, as in the callout on the session page.
# primary_energy_consumption is in TWh, co2 in Mt, gdp in international dollars.
steps <- owid |>
  filter(country %in% countries, year %in% c(start, end)) |>
  arrange(country, year) |>
  mutate(gdp_pp = gdp / population,
         energy_per_gdp = primary_energy_consumption * 1e9 / gdp,   # kWh per dollar
         co2_per_energy = co2 / primary_energy_consumption,         # kg per kWh
         population_m = population / 1e6) |>
  group_by(country) |>
  reframe(
    L     = (last(co2) - first(co2)) / log(last(co2) / first(co2)),
    term  = c("population (million)", "GDP per person (dollars)",
              "energy per GDP (kWh/dollar)", "CO2 per energy (kg/kWh)"),
    value_start = c(first(population_m), first(gdp_pp), first(energy_per_gdp), first(co2_per_energy)),
    value_end   = c(last(population_m), last(gdp_pp), last(energy_per_gdp), last(co2_per_energy))
  ) |>
  mutate(ratio = value_end / value_start,
         ln_ratio = log(ratio),
         effect_mt = L * ln_ratio)

print(as.data.frame(steps), digits = 4)

kaya <- owid |>
  filter(country %in% countries, year %in% c(start, end)) |>
  arrange(country, year) |>
  group_by(country) |>
  summarise(
    co2_start  = first(co2),                      # Mt CO2
    co2_end    = last(co2),
    L          = (co2_end - co2_start) / log(co2_end / co2_start),
    # effects named eff_*: summarise() would otherwise overwrite the input columns
    eff_population     = L * log(last(population) / first(population)),
    eff_gdp_per_person = L * log((last(gdp) / last(population)) /
                                 (first(gdp) / first(population))),
    eff_energy_per_gdp = L * log((last(primary_energy_consumption) / last(gdp)) /
                                 (first(primary_energy_consumption) / first(gdp))),
    eff_co2_per_energy = L * log((last(co2) / last(primary_energy_consumption)) /
                                 (first(co2) / first(primary_energy_consumption))),
    change_pct = 100 * (co2_end / co2_start - 1),
    t_per_person_start = 1e6 * first(co2) / first(population),
    t_per_person_end   = 1e6 * last(co2) / last(population),
    # how much of the change is net trade? consumption = production + net imports
    cons_start     = first(consumption_co2),
    cons_end       = last(consumption_co2),
    cons_change_pct = 100 * (cons_end / cons_start - 1),
    net_imports_start = first(trade_co2),
    net_imports_end   = last(trade_co2),
    cons_t_per_person_end = 1e6 * last(consumption_co2) / last(population),
    .groups = "drop"
  ) |>
  select(-L)

print(as.data.frame(kaya), digits = 4)

dir.create(file.path("analysis", "figures"), showWarnings = FALSE)
write_csv(kaya, file.path("analysis", "figures", "kaya_lmdi_L07a.csv"))
