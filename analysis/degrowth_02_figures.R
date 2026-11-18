# ============================================================================
#  degrowth_02_figures.R — rebuild the data figures for session 8b
#  ("The growth vs. degrowth debate")
#
#  Replaces the charts of the 2025 deck (Hickel & Kallis 2020, EEA 2021, and
#  three World Bank panels without code) with figures from current data:
#    · world GDP and material footprint, 1990 onwards           [slide 5]
#    · same data, three stories: the trick with two y-axes      [slide 7]
#    · no decoupling, relative and absolute decoupling          [slide 10]
#    · the rebound effect in German housing                     [slide 11]
#    · world GDP, material footprint and GHG, 1970 onwards      [slide 14]
#    · how fast new goods spread in US households                [slide 27]
#  The country panels on GDP and consumption-based CO2 (slide 14, right) are
#  fig_14_decoupling of session 3 and are not rebuilt here.
#
#  Reads these files —
#    analysis/data-raw/wdi_gdp_constant.csv (World Bank GDP, degrowth_01_download.R)
#    analysis/data-raw/rebound_housing_de.csv, owid_technology_adoption_us.csv
#                                           (also degrowth_01_download.R)
#    analysis/data-raw/owid_co2_data.csv    (OWID GHG, policy_01_download.R)
#    analysis/data-manual/mfa4_export.csv   (IRP export, see its README)
#  Writes PDF + SVG into analysis/figures/ and copies the SVGs into
#  content/material/slides/figures/. Names are fig_L08b_<slide>_<topic>; the
#  number is the slide of the 2026 deck.
#
#  Run:  Rscript analysis/degrowth_02_figures.R
# ============================================================================

source(file.path("analysis", "R", "euf_style.R"))

RAW       <- file.path("analysis", "data-raw")
FIG_DIR   <- file.path("analysis", "figures")
SLIDE_DIR <- file.path("content", "material", "slides", "figures")
IRP_FILE  <- file.path("analysis", "data-manual", "mfa4_export.csv")
OWID_FILE <- file.path(RAW, "owid_co2_data.csv")
WDI_FILE  <- file.path(RAW, "wdi_gdp_constant.csv")
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(SLIDE_DIR, showWarnings = FALSE, recursive = TRUE)

save_l08b <- function(plot, file, width = 9, height = 5.4) {
  save_euf(plot, file, width, height)
  invisible(file.copy(file.path(FIG_DIR, paste0(file, ".svg")), SLIDE_DIR, overwrite = TRUE))
}

if (!file.exists(IRP_FILE))
  stop("IRP export missing - see analysis/data-manual/README-mfa4_export.txt")
if (!file.exists(OWID_FILE))
  stop("OWID CO2 file missing - run analysis/policy_01_download.R first")
if (!file.exists(WDI_FILE))
  stop("World Bank GDP missing - run analysis/degrowth_01_download.R first")

message("Building session 8b figures ...")

# ---- Data ------------------------------------------------------------------
# The unit column holds the single letter "t", which readr would guess as
# logical TRUE - so the text columns are typed explicitly (as in 02_figures.R).
irp <- read_csv(IRP_FILE, show_col_types = FALSE, progress = FALSE,
                col_types = cols(Country     = col_character(),
                                 Category    = col_character(),
                                 `Flow name` = col_character(),
                                 `Flow code` = col_character(),
                                 `Flow unit` = col_character(),
                                 .default    = col_double())) |>
  select(area = Country, category = Category, flow = `Flow code`,
         matches("^[0-9]{4}$")) |>
  pivot_longer(matches("^[0-9]{4}$"), names_to = "year", values_to = "tonnes") |>
  mutate(year = as.integer(year)) |>
  filter(!is.na(tonnes))

# Total over all material categories. For the world, domestic extraction and
# material footprint are the same thing: what one country imports another has
# extracted. So the world series is DE, which the IRP gives from 1970.
irp_total <- function(a, f) {
  irp |> filter(area == a, flow == f) |>
    group_by(year) |> summarise(tonnes = sum(tonnes), .groups = "drop")
}

# GHG: OWID (Jones et al.), without land use. GDP: World Bank, constant 2015
# US$, because the Maddison GDP in the OWID file has only benchmark years for
# the world before 2008.
owid <- read_csv(OWID_FILE, show_col_types = FALSE, progress = FALSE) |>
  select(country, year, ghg = total_ghg_excluding_lucf) |>
  filter(!is.na(ghg))
wdi <- read_csv(WDI_FILE, show_col_types = FALSE, progress = FALSE) |>
  select(iso3, year, gdp)
# The World Bank, OWID and the IRP spell some names differently ("Turkiye" vs.
# "Turkey"), so GDP is looked up by ISO code.
wdi_iso <- c("World" = "WLD", "China" = "CHN", "Germany" = "DEU", "Turkey" = "TUR")
gdp_of <- function(cty) wdi |> filter(iso3 == wdi_iso[[cty]]) |> transmute(year, value = gdp) |> arrange(year)

# Each figure stops at the last year for which all of its series exist.
last_common <- function(d) d |> group_by(series) |> summarise(m = max(year)) |> pull(m) |> min()

index_to <- function(x, year, base) x / x[year == base]

# End labels instead of a legend: the series name and its change since the
# base year, in the text colour, next to the end of each line.
end_labels <- function(d, digits = 0) {
  d |> group_by(series) |> slice_max(year, n = 1) |> ungroup()
}

ser_cols <- c("GDP" = euf$blue_mid, "Material footprint" = euf$red,
              "Domestic material consumption" = euf$red,
              "Greenhouse gases" = euf$gray)

# ============================================================================
# 5 · GDP and material use move together                           [slide 5]
# ============================================================================
# Hickel & Kallis (2020) show this for 1990-2013, index 1990 = 1. Same
# definition here, with data to the latest year.
d05 <- bind_rows(
  gdp_of("World") |> mutate(series = "GDP"),
  irp_total("World", "DE") |> transmute(year, value = tonnes, series = "Material footprint")
) |>
  filter(year >= 1990)
END05 <- last_common(d05)
d05 <- d05 |> filter(year <= END05) |>
  group_by(series) |> mutate(index = index_to(value, year, 1990)) |> ungroup()

lab05 <- end_labels(d05)
message(sprintf("  World %d-%d: GDP x%.2f, material footprint x%.2f, correlation of levels r = %.3f",
                1990, END05, lab05$index[lab05$series == "GDP"],
                lab05$index[lab05$series == "Material footprint"],
                cor(d05 |> select(year, series, value) |>
                      pivot_wider(names_from = series, values_from = value) |>
                      select(-year), use = "complete.obs")[1, 2]))

p05 <- ggplot(d05, aes(year, index, color = series)) +
  geom_line(linewidth = 1.3) +
  geom_text(data = lab05, aes(label = paste0(series, "\n", number(index, 0.01))),
            hjust = 0, nudge_x = 0.6, lineheight = 0.95, size = 4.6,
            family = euf_family, color = euf$ink) +
  scale_color_manual(values = ser_cols, guide = "none") +
  scale_x_continuous(breaks = seq(1990, 2020, 10), limits = c(1990, END05 + 9)) +
  labs(title = "World GDP and material footprint",
       subtitle = "Index, 1990 = 1", x = NULL, y = NULL,
       caption = paste0("Sources: GDP: World Bank (constant 2015 US$);\n",
                        "material footprint (= global extraction): UN IRP.")) +
  theme_euf(base_size = 15) +
  theme(plot.title = element_text(size = 19))
save_l08b(p05, "fig_L08b_05_gdp_material", width = 7, height = 6)

# ============================================================================
# 7 · Same data, any story you like                                [slide 7]
# ============================================================================
# One country, two series, three choices for the right-hand axis. GDP is the
# same line in all three panels; only the mapping of emissions changes:
#   y_plot = a + b * GHG, and the right axis shows (y_plot - a) / b.
d07 <- inner_join(gdp_of("Germany") |> rename(gdp = value),
                  owid |> filter(country == "Germany") |> select(year, ghg),
                  by = "year") |>
  filter(year >= 1990) |>
  mutate(gdp = gdp / 1e12)
stopifnot(!anyNA(d07))

two_axes <- function(title, ghg_lo, ghg_hi, reverse = FALSE) {
  gdp_lo <- floor(min(d07$gdp) * 10) / 10
  gdp_hi <- ceiling(max(d07$gdp) * 10) / 10
  # map [ghg_lo, ghg_hi] onto [gdp_lo, gdp_hi], upside down if reverse
  b <- (gdp_hi - gdp_lo) / (ghg_hi - ghg_lo) * if (reverse) -1 else 1
  a <- if (reverse) gdp_hi - b * ghg_lo else gdp_lo - b * ghg_lo
  ggplot(d07, aes(year)) +
    geom_line(aes(y = gdp), color = euf$blue_mid, linewidth = 1.3) +
    geom_line(aes(y = a + b * ghg), color = euf$red, linewidth = 1.3) +
    scale_y_continuous(
      name = "GDP (trillion US$)", limits = c(gdp_lo, gdp_hi),
      sec.axis = sec_axis(~ (. - a) / b, name = "GHG (Mt CO2e)")) +
    scale_x_continuous(breaks = c(1990, 2005, 2020)) +
    labs(title = title, x = NULL) +
    theme_euf(base_size = 15) +
    theme(plot.title         = element_text(size = 18),
          axis.title.y.left  = element_text(color = euf$blue_mid, size = 13),
          axis.title.y.right = element_text(color = euf$red, size = 13))
}

ghg_rng <- range(d07$ghg)
save_l08b(two_axes("Emissions fall as GDP grows", ghg_rng[1], ghg_rng[2]),
          "fig_L08b_07_axes_1", width = 5.2, height = 4.6)
save_l08b(two_axes("Emissions grow with GDP", ghg_rng[1], ghg_rng[2], reverse = TRUE),
          "fig_L08b_07_axes_2", width = 5.2, height = 4.6)
save_l08b(two_axes("Emissions hardly move", 0, 6000),
          "fig_L08b_07_axes_3", width = 5.2, height = 4.6)
message(sprintf("  Germany %d-%d: GDP %+.0f%%, GHG %+.0f%%", 1990, max(d07$year),
                100 * (last(d07$gdp) / first(d07$gdp) - 1),
                100 * (last(d07$ghg) / first(d07$ghg) - 1)))

# ============================================================================
# 10 · No decoupling, relative and absolute decoupling              [slide 10]
# ============================================================================
# Production-based figures, index 2000 = 100: total GDP against domestic
# material consumption (Turkey) and greenhouse gases without land use
# (China, Germany).
panel <- function(cty, ser, title) {
  stress <- if (ser == "Domestic material consumption") {
    irp_total(cty, "DMC") |> transmute(year, value = tonnes)
  } else {
    owid |> filter(country == cty) |> transmute(year, value = ghg)
  }
  d <- bind_rows(
    gdp_of(cty) |> mutate(series = "GDP"),
    stress |> mutate(series = ser)
  ) |>
    filter(year >= 2000, !is.na(value))
  end <- last_common(d)
  d <- d |> filter(year <= end) |>
    group_by(series) |> mutate(index = 100 * index_to(value, year, 2000)) |> ungroup()
  lab <- end_labels(d) |>
    mutate(short = if_else(series == "GDP", "GDP", if_else(ser == "Greenhouse gases", "GHG", "DMC")),
           label = sprintf("%s %+.0f%%", short, index - 100))
  message(sprintf("  %s 2000-%d: %s", cty, end, paste(lab$label, collapse = ", ")))
  ggplot(d, aes(year, index, color = series)) +
    geom_hline(yintercept = 100, color = euf$gray, linewidth = 0.3, linetype = "dotted") +
    geom_line(linewidth = 1.2) +
    geom_text(data = lab, aes(label = label), hjust = 0, nudge_x = 0.5, size = 4.2,
              family = euf_family, color = euf$ink) +
    scale_color_manual(values = ser_cols, guide = "none") +
    scale_x_continuous(breaks = c(2000, 2010, 2020), limits = c(2000, end + 7)) +
    labs(title = title, subtitle = paste0(c(
      "Domestic material consumption" = "Material use and GDP, ",
      "Greenhouse gases" = "GHG emissions and GDP, ")[[ser]],
      recode(cty, Turkey = "T\u00fcrkiye")),
      x = NULL, y = NULL) +
    theme_euf(base_size = 14) +
    theme(plot.title = element_text(size = 18))
}

# The 2025 deck showed Indonesia as "permanent coupling"; with current data its
# material use grows more slowly than GDP (elasticity about 0.85 since 2000).
# Turkey's grows faster than GDP (about 1.1), so it is the example now.
p10 <- (panel("Turkey", "Domestic material consumption", "No decoupling") |
        panel("China", "Greenhouse gases", "Relative decoupling") |
        panel("Germany", "Greenhouse gases", "Absolute decoupling")) +
  plot_annotation(
    caption = paste0("Index, 2000 = 100. Production-based: DMC = domestic material consumption, ",
                     "GHG = greenhouse gases without land use.\nSources: GDP: World Bank (constant 2015 US$); ",
                     "DMC: UN IRP Global Material Flows Database; GHG: Jones et al. via Our World in Data."),
    theme = theme_euf())
save_l08b(p10, "fig_L08b_10_decoupling_types", width = 14, height = 5)

# ============================================================================
# 14 · The global picture since 1970                               [slide 14]
# ============================================================================
# The EEA (2021) chart of the 2025 deck: global GDP, material footprint and
# GHG emissions, index 1990 = 1.
d14 <- bind_rows(
  gdp_of("World") |> mutate(series = "GDP"),
  irp_total("World", "DE") |> transmute(year, value = tonnes, series = "Material footprint"),
  owid |> filter(country == "World") |> transmute(year, value = ghg, series = "Greenhouse gases")
) |>
  filter(year >= 1970, !is.na(value))
END14 <- last_common(d14)
d14 <- d14 |> filter(year <= END14) |>
  group_by(series) |> mutate(index = index_to(value, year, 1990)) |> ungroup()

lab14 <- end_labels(d14)
message(sprintf("  World 1990-%d: %s", END14,
                paste(sprintf("%s x%.2f", lab14$series, lab14$index), collapse = ", ")))

p14 <- ggplot(d14, aes(year, index, color = series)) +
  geom_hline(yintercept = 1, color = euf$gray, linewidth = 0.3, linetype = "dotted") +
  geom_line(linewidth = 1.3) +
  geom_text(data = lab14, aes(label = series), hjust = 0, nudge_x = 0.8, size = 4.6,
            family = euf_family, color = euf$ink) +
  scale_color_manual(values = ser_cols, guide = "none") +
  scale_x_continuous(breaks = seq(1970, 2020, 10), limits = c(1970, END14 + 19)) +
  labs(title = "The world since 1970", subtitle = "Index, 1990 = 1", x = NULL, y = NULL,
       caption = paste0("Sources: GDP: World Bank (constant 2015 US$); material footprint:\n",
                        "UN IRP; GHG without land use: Jones et al. via Our World in Data.")) +
  theme_euf(base_size = 15) +
  theme(plot.title = element_text(size = 19))
save_l08b(p14, "fig_L08b_14_world", width = 7.6, height = 6)

# ============================================================================
# 11 · The rebound effect in German housing                        [slide 11]
# ============================================================================
# Heat demand per m² falls, living space per person grows, so heat demand per
# person hardly changes. Index, 1990 = 100.
d11 <- read_csv(file.path(RAW, "rebound_housing_de.csv"), show_col_types = FALSE,
                progress = FALSE) |>
  # columns: year, living space per person (m²), kWh per m² and year, kWh per
  # person and year; renamed by position, the German headers have umlauts
  rename(year = 1, space = 2, per_m2 = 3, per_person = 4)
# per person = per m² x m² per person: a check that the columns are what they claim
stopifnot(all(abs(d11$per_m2 * d11$space / d11$per_person - 1) < 0.01))
d11 <- d11 |>
  pivot_longer(-year, names_to = "series", values_to = "value") |>
  mutate(series = recode(series, space = "Living space per person",
                         per_m2 = "Heat demand per square metre", per_person = "Heat demand per person")) |>
  group_by(series) |> mutate(index = 100 * index_to(value, year, 1990)) |> ungroup()
lab11 <- end_labels(d11) |> mutate(label = sprintf("%s: %.0f", series, index))
message(sprintf("  German housing 1990-%d: %s", max(d11$year), paste(lab11$label, collapse = ", ")))

p11 <- ggplot(d11, aes(year, index, color = series)) +
  geom_hline(yintercept = 100, color = euf$gray, linewidth = 0.3, linetype = "dotted") +
  geom_line(linewidth = 1.3) +
  geom_text(data = lab11, aes(label = label), hjust = 0, nudge_x = 0.5, size = 4.4,
            family = euf_family, color = euf$ink) +
  scale_color_manual(values = c("Living space per person" = euf$red,
                                "Heat demand per square metre" = euf$green,
                                "Heat demand per person" = euf$blue), guide = "none") +
  scale_x_continuous(breaks = seq(1990, 2020, 10), limits = c(1990, max(d11$year) + 19)) +
  labs(title = "Heating in German housing", subtitle = "Index, 1990 = 100", x = NULL, y = NULL,
       caption = "Data: Destatis, AGEB, as compiled for Gr\u00e4bner-Radkowitsch, Lage & Wiese (2024).") +
  theme_euf(base_size = 15) +
  theme(plot.title = element_text(size = 19))
save_l08b(p11, "fig_L08b_11_rebound", width = 8, height = 5.4)

# ============================================================================
# 27 · How fast new goods spread                                   [slide 27]
# ============================================================================
# Share of US households (or of the relevant stock) that use a technology. The
# selection is that of Systemiq (2023), Figure 2, as far as Our World in Data
# has it; Systemiq's cars, steamships and steel come from another source, so
# cars are OWID's "Automobile" here, and steamships and steel are missing.
GOODS <- c("Flush toilet", "Radial tires", "Dishwasher", "Household refrigerator",
           "Refrigerator", "Microwave", "Washing machine", "Stove", "Automobile")
d27 <- read_csv(file.path(RAW, "owid_technology_adoption_us.csv"), show_col_types = FALSE,
                progress = FALSE) |>
  rename(entity = 1, year = 2, share = 3) |>
  filter(entity %in% GOODS)
if (!all(GOODS %in% d27$entity))
  stop("OWID adoption data: missing ", paste(setdiff(GOODS, d27$entity), collapse = ", "))
lab27 <- d27 |> group_by(entity) |> slice_max(year, n = 1) |> ungroup()

p27 <- ggplot(d27, aes(year, share, group = entity)) +
  geom_line(color = euf$blue_mid, linewidth = 1) +
  geom_point(data = lab27, color = euf$blue_mid, size = 1.8) +
  # labels in one column right of the plot, pulled apart vertically
  ggrepel::geom_text_repel(data = lab27, aes(label = entity), hjust = 0, direction = "y",
                           xlim = c(2030, NA), ylim = c(0, 108), box.padding = 0.25,
                           size = 3.9, family = euf_family, color = euf$ink,
                           segment.color = euf$gray, segment.size = 0.3,
                           min.segment.length = 0, seed = 1) +
  scale_x_continuous(breaks = seq(1860, 2020, 20), limits = c(1855, 2075)) +
  coord_cartesian(clip = "off") +
  scale_y_continuous(limits = c(0, 100), labels = label_percent(scale = 1)) +
  labs(title = "Adoption of new goods in US households", x = NULL, y = NULL,
       caption = "Data: Comin and Hobijn (2004) and others, via Our World in Data.") +
  theme_euf(base_size = 15) +
  theme(plot.title = element_text(size = 19))
save_l08b(p27, "fig_L08b_27_adoption_goods", width = 8.4, height = 6)

message("\nDone. Figures in ", FIG_DIR, "/ and ", SLIDE_DIR, "/")
