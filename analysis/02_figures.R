# ============================================================================
#  02_figures.R — rebuild the data figures for session 3b ("Working with data")
#
#  Reads only what 01_download.R wrote into analysis/data-raw/ and writes
#  PDF + PNG into analysis/figures/. Numbering follows the slide it replaces.
#
#  Run:  Rscript analysis/01_download.R && Rscript analysis/02_figures.R
#  or double-click Abbildungen-bauen.command in the repo root.
# ============================================================================

source(file.path("analysis", "R", "euf_style.R"))

RAW     <- file.path("analysis", "data-raw")
FIG_DIR <- file.path("analysis", "figures")
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)
rd <- function(f) read_csv(file.path(RAW, f), show_col_types = FALSE, progress = FALSE)

message("Building figures ...")

# ============================================================================
# 06 · GDP per capita by world region, long run                    [slide 6]
# ============================================================================
mad_regions <- c("Western offshoots (Maddison)"            = "Western offshoots",
                 "Western Europe (Maddison)"               = "Western Europe",
                 "Eastern Europe (Maddison)"               = "Eastern Europe",
                 "Middle East and North Africa (Maddison)" = "Middle East & N. Africa",
                 "East Asia (Maddison)"                    = "East Asia",
                 "Latin America (Maddison)"                = "Latin America",
                 "South and South East Asia (Maddison)"    = "South & South-East Asia",
                 "Sub Saharan Africa (Maddison)"           = "Sub-Saharan Africa",
                 "World"                                   = "World")

gdp_reg <- rd("gdp_maddison.csv") |>
  filter(entity %in% names(mad_regions), year >= 1820, !is.na(gdp_per_capita)) |>
  mutate(region = factor(mad_regions[entity], levels = unname(mad_regions)))

gdp_end <- gdp_reg |> group_by(region) |> slice_max(year, n = 1) |> ungroup()
MAXY    <- max(gdp_reg$year)

# Nine series: identity is carried by the direct end labels, colour only
# supports them. "World" is drawn heavier as the reference line.
reg_cols <- c(setNames(c("#C98A00", "#2A72B5", "#8A5FBF", "#E0542F",
                         "#1F8A5B", "#00A0A8", "#6F8FA8", "#B0561F"),
                       unname(mad_regions)[1:8]),
              World = euf$ink)

p06 <- ggplot(gdp_reg, aes(year, gdp_per_capita, color = region)) +
  geom_line(aes(linewidth = region == "World")) +
  geom_text_repel(data = gdp_end, aes(label = region), hjust = 0,
                  direction = "y", nudge_x = 6, size = 3.5, fontface = "bold",
                  family = euf_family, segment.color = euf$grid,
                  min.segment.length = 0, seed = 1, xlim = c(MAXY + 4, NA)) +
  scale_color_manual(values = reg_cols) +
  scale_linewidth_manual(values = c(`FALSE` = 0.9, `TRUE` = 1.7), guide = "none") +
  scale_x_continuous(breaks = seq(1820, 2020, 40),
                     limits = c(1820, MAXY + 95), expand = expansion(mult = c(0.01, 0))) +
  scale_y_continuous(labels = lbl_dollar) +
  labs(title = "Income grows, but in a very unequal fashion",
       subtitle = paste0("GDP per capita by world region, 1820-", MAXY,
                         " (constant international $, adjusted for price differences)"),
       x = NULL, y = "GDP per capita",
       caption = "Source: Maddison Project Database via Our World in Data.") +
  guides(color = "none") +
  theme_euf()
save_euf(p06, "fig_06_gdp_by_region", width = 10, height = 5.8)

# ============================================================================
# 07 · Share of the world below several poverty lines              [slide 7]
# ============================================================================
pov <- rd("poverty_pip_lines.csv") |>
  filter(estimate_type == "actual") |>   # drop PIP's nowcast years
  mutate(share = headcount * 100,
         line  = factor(sprintf("$%.2f", povline),
                        levels = sprintf("$%.2f", sort(unique(povline)))))
pov_end <- pov |> group_by(line) |> slice_max(year, n = 1) |> ungroup()
PMAX <- max(pov$year)

line_cols <- setNames(c("#7A1E12", "#E0542F", "#C98A00", "#1F8A5B", "#2A72B5"),
                      levels(pov$line))

p07 <- ggplot(pov, aes(year, share, color = line)) +
  geom_line(linewidth = 1.2) +
  geom_text_repel(data = pov_end, aes(label = paste0("less than ", line, " a day")),
                  hjust = 0, direction = "y", nudge_x = 1.5, size = 3.6,
                  fontface = "bold", family = euf_family, seed = 1,
                  segment.color = euf$grid, min.segment.length = 0,
                  xlim = c(PMAX + 1, NA)) +
  scale_color_manual(values = line_cols) +
  scale_x_continuous(breaks = seq(1980, PMAX, 5), limits = c(1981, PMAX + 17)) +
  scale_y_continuous(labels = label_percent(scale = 1), limits = c(0, 100),
                     breaks = seq(0, 100, 20)) +
  labs(title = "Income poverty remains a global problem",
       subtitle = paste0("Share of the world population below different poverty lines, 1981-", PMAX,
                         "\nLines are in international dollars at 2021 PPP, so they account for inflation and price differences."),
       x = NULL, y = "Share of world population",
       caption = "Source: World Bank Poverty and Inequality Platform (PIP) API.") +
  guides(color = "none") +
  theme_euf()
save_euf(p07, "fig_07_poverty_lines", width = 10, height = 5.8)

# ============================================================================
# 08 · Long-run poverty: two centuries, two measures                [slide 8]
# ============================================================================
# NB: the OWID columns are head*counts* (numbers of people), not shares, so the
# share has to be computed from the two of them.
cbn_share <- function() {
  rd("poverty_cbn.csv") |>
    filter(!is.na(headcount_cbn), !is.na(headcount_above_cbn)) |>
    transmute(entity, year,
              share = headcount_cbn / (headcount_cbn + headcount_above_cbn) * 100)
}

cbn <- cbn_share() |> filter(entity == "World") |>
  transmute(year, share, series = "Extreme poverty, 'cost of basic needs' (Moatsos)")

pip300 <- pov |> filter(povline == 3.00) |>
  transmute(year, share, series = "Below $3.00 a day (World Bank PIP, 2021 PPP)")

pov_long <- bind_rows(cbn, pip300) |>
  mutate(series = factor(series, levels = c(unique(cbn$series), unique(pip300$series))))

long_cols <- setNames(c("#7A1E12", "#2A72B5"), levels(pov_long$series))
pl_end <- pov_long |> group_by(series) |> slice_max(year, n = 1) |> ungroup()

p08 <- ggplot(pov_long, aes(year, share, color = series)) +
  geom_line(linewidth = 1.3) +
  geom_point(data = pl_end, size = 2.4) +
  geom_text_repel(data = pl_end, aes(label = sprintf("%.0f%% (%d)", share, year)),
                  hjust = 0, nudge_x = 6, direction = "y", size = 3.6,
                  fontface = "bold", family = euf_family, seed = 1,
                  segment.color = euf$grid, min.segment.length = 0,
                  show.legend = FALSE) +
  scale_color_manual(values = long_cols) +
  scale_x_continuous(breaks = seq(1820, 2020, 20),
                     limits = c(1820, max(pov_long$year) + 22)) +
  scale_y_continuous(labels = label_percent(scale = 1), limits = c(0, 100)) +
  labs(title = "There has been progress with respect to income poverty",
       subtitle = "Share of the world population living in poverty. Two different measures, two different stories about the level.",
       x = NULL, y = "Share of world population",
       caption = paste("Sources: Moatsos (2021) via Our World in Data; World Bank PIP.",
                       "For a critique of the 'poverty is falling' claim see Hickel (2019).")) +
  guides(color = guide_legend(nrow = 2)) +
  theme_euf()
save_euf(p08, "fig_08_poverty_longrun", width = 10, height = 5.8)

# ============================================================================
# 09 · Extreme poverty vs GDP per capita, by world region           [slide 9]
# ============================================================================
# Moatsos poverty and Maddison GDP use parallel but differently spelled region
# names, so the crosswalk is explicit rather than fuzzy-matched.
xwalk <- tribble(
  ~moatsos,                                   ~maddison,                                 ~label,
  "World",                                    "World",                                   "World",
  "Western Europe (Moatsos)",                 "Western Europe (Maddison)",               "Western Europe",
  "Western offshoots (Moatsos)",              "Western offshoots (Maddison)",            "Western offshoots",
  "Eastern Europe and former USSR (Moatsos)", "Eastern Europe (Maddison)",               "Eastern Europe",
  "Latin America and Caribbean (Moatsos)",    "Latin America (Maddison)",                "Latin America",
  "Middle East and North Africa (Moatsos)",   "Middle East and North Africa (Maddison)", "Middle East & N. Africa",
  "East Asia (Moatsos)",                      "East Asia (Maddison)",                    "East Asia",
  "South and South-East Asia (Moatsos)",      "South and South East Asia (Maddison)",    "South & South-East Asia",
  "Sub-Saharan Africa (Moatsos)",             "Sub Saharan Africa (Maddison)",           "Sub-Saharan Africa"
)

pov_reg <- cbn_share() |>
  inner_join(xwalk, by = c("entity" = "moatsos")) |>
  transmute(label, year, share)
gdp_j <- rd("gdp_maddison.csv") |>
  inner_join(xwalk, by = c("entity" = "maddison")) |>
  transmute(label, year, gdp = gdp_per_capita) |> filter(!is.na(gdp))

pg <- inner_join(pov_reg, gdp_j, by = c("label", "year")) |>
  mutate(label = factor(label, levels = xwalk$label)) |>
  arrange(label, year)
pg_end <- pg |> group_by(label) |> slice_max(year, n = 1) |> ungroup()

p09 <- ggplot(pg, aes(gdp, share)) +
  # every region repeated in the background of every panel, as a reference
  geom_path(data = select(pg, -label), aes(group = 1), color = "#C7CDD2", linewidth = 0.35) +
  geom_path(color = euf$blue_mid, linewidth = 1.2) +
  geom_point(data = pg_end, color = euf$red, size = 2.2) +
  facet_wrap(~ label, ncol = 3) +
  scale_x_log10(breaks = c(1000, 5000, 20000, 50000), labels = lbl_dollar,
                expand = expansion(mult = 0.08)) +
  scale_y_continuous(labels = label_percent(scale = 1), limits = c(0, 100)) +
  labs(title = "Reducing income poverty due to growth of GDP?!",
       subtitle = paste0("Share in extreme poverty vs. GDP per capita, ", min(pg$year), "-", max(pg$year),
                         ". Blue traces the region named in the panel, red marks its latest year;",
                         "\ngrey repeats all regions in every panel so they can be compared."),
       x = "GDP per capita (log scale)", y = "Share in extreme poverty",
       caption = paste("Sources: Moatsos (2021), 'cost of basic needs' approach;",
                       "Maddison Project Database. Both via Our World in Data.")) +
  theme_euf() +
  theme(panel.spacing = unit(0.9, "lines"))
save_euf(p09, "fig_09_poverty_vs_gdp", width = 10, height = 7)

# ============================================================================
# 10 · GDP correlates with many development indicators             [slide 10]
# ============================================================================
# One helper, four panels. Each panel keeps the latest year in which the
# indicator has broad country coverage.
# Several of these indicators are reported irregularly, so "the latest year with
# full coverage" would either be old or nearly empty. Instead take each country's
# most recent observation within a trailing window; the panel title reports the
# range actually used, so the reader is never misled about the vintage.
latest_wide <- function(df, ycol, window = 10) {
  d <- df |> rename(y = all_of(ycol), gdp = ny_gdp_pcap_pp_kd) |>
    only_countries() |>
    filter(!is.na(y), !is.na(gdp))
  d |> filter(year > max(year) - window) |>
    group_by(code) |> slice_max(year, n = 1, with_ties = FALSE) |> ungroup()
}

yr_range <- function(d) {
  r <- range(d$year)
  if (r[1] == r[2]) as.character(r[1]) else paste0(r[1], "-", r[2])
}

panel_scatter <- function(d, ylab, ptitle, log_y = FALSE, ylabels = waiver()) {
  p <- ggplot(d, aes(gdp, y)) +
    geom_point(aes(fill = owid_region), shape = 21, color = "white",
               size = 2.5, stroke = 0.3, alpha = 0.9) +
    scale_fill_manual(values = region_pal, drop = FALSE, name = NULL) +
    scale_x_log10(breaks = gdp_breaks, labels = lbl_dollar) +
    labs(title = paste0(ptitle, " (", yr_range(d), ")"),
         x = "GDP per capita (log scale)", y = ylab) +
    theme_euf(base_size = 12)
  if (log_y) p + scale_y_log10(labels = ylabels) else p + scale_y_continuous(labels = ylabels)
}

# One shared legend for a patchwork of scatter panels. Collecting guides has to
# happen in a single wrap_plots() call - nesting `|` and `/` produces one legend
# per nested group.
combine_panels <- function(..., ncol = 2) {
  wrap_plots(..., ncol = ncol, guides = "collect") &
    guides(fill = guide_legend(override.aes = list(size = 3.6, alpha = 1), nrow = 1)) &
    theme(legend.position = "bottom")
}

d_sch <- latest_wide(rd("gdp_schooling.csv"),      "mys__sex_total")
d_cm  <- rd("gdp_childmortality.csv") |> rename(ny_gdp_pcap_pp_kd = gdp_per_capita) |>
         latest_wide("child_mortality_rate")
d_lit <- latest_wide(rd("gdp_literacy.csv"),
                     "adult_literacy_rate__population_15plus_years__both_sexes__pct__lr_ag15t99")
d_doc <- latest_wide(rd("gdp_doctors.csv"),        "sh_med_phys_zs")

p10 <- combine_panels(
    panel_scatter(d_sch, "Years", "Average years of schooling"),
    panel_scatter(d_cm,  "Deaths per 100 live births", "Child mortality", log_y = TRUE),
    panel_scatter(d_lit, "% of adults", "Adult literacy rate"),
    panel_scatter(d_doc, "per 1,000 people", "Medical doctors")) +
  plot_annotation(
    title = "GDP correlates with many development indicators",
    subtitle = "One dot = one country, at its most recent observation. All four relationships are strong at low incomes and flatten out at high incomes.",
    caption = paste("Source: Our World in Data (UNDP, UN IGME, UNESCO, WHO via World Bank)."),
    theme = theme_euf_wide())
save_euf(p10, "fig_10_gdp_indicators", width = 12, height = 8.5)

# ============================================================================
# 11 · Material use is increasing                                  [slide 11]
# ============================================================================
mat_cols <- c("Biomass" = "#1F8A5B", "Non-metallic minerals" = "#C98A00",
              "Fossil fuels" = "#6F6F6F", "Metal ores" = "#2A72B5")

IRP_FILE    <- file.path("analysis", "data-manual", "mfa4_export.csv")
IRP_REGIONS <- c("Africa", "Asia + Pacific", "EECCA", "Europe",
                 "Latin America + Caribbean", "North America", "West Asia")

# Preferred source: the hand-downloaded IRP export (domestic EXTRACTION, from
# 1970). See analysis/data-manual/README-mfa4_export.txt. The checks below make
# a wrong or partial export fail loudly instead of producing a wrong figure.
read_irp <- function(path) {
  # The unit column contains the single letter "t", which readr happily guesses
  # as logical TRUE - so the text columns are typed explicitly.
  raw <- read_csv(path, show_col_types = FALSE, progress = FALSE,
                  col_types = cols(Country      = col_character(),
                                   Category     = col_character(),
                                   `Flow name`  = col_character(),
                                   `Flow code`  = col_character(),
                                   `Flow unit`  = col_character(),
                                   .default     = col_double()))

  need <- c("Country", "Category", "Flow code", "Flow unit")
  if (!all(need %in% names(raw))) stop("IRP export: missing columns ",
                                       paste(setdiff(need, names(raw)), collapse = ", "))
  de <- raw |> filter(`Flow code` == "DE")
  if (!nrow(de))                 stop("IRP export: no rows with Flow code 'DE' (domestic extraction)")
  if (!all(de$`Flow unit` == "t")) stop("IRP export: expected tonnes ('t') as the flow unit")
  if (!all(names(mat_cols) %in% de$Category))
    stop("IRP export: missing material categories ",
         paste(setdiff(names(mat_cols), de$Category), collapse = ", "))
  if (!all(c("World", IRP_REGIONS) %in% de$Country))
    stop("IRP export: missing regions ",
         paste(setdiff(c("World", IRP_REGIONS), de$Country), collapse = ", "))

  d <- de |>
    filter(Category %in% names(mat_cols)) |>
    select(area = Country, material = Category, matches("^[0-9]{4}$")) |>
    pivot_longer(-c(area, material), names_to = "year", values_to = "tonnes") |>
    mutate(year = as.integer(year), tonnes = as.numeric(tonnes)) |>
    filter(!is.na(tonnes), tonnes > 0) |>
    mutate(material = factor(material, levels = names(mat_cols)))

  # the seven regions must add up to the reported world total
  chk <- d |> filter(year == max(year)) |>
    summarise(world = sum(tonnes[area == "World"]),
              regs  = sum(tonnes[area %in% IRP_REGIONS]))
  if (abs(chk$regs - chk$world) / chk$world > 0.01)
    stop("IRP export: the seven regions sum to ",
         round(chk$regs / chk$world * 100, 1), "% of the world total - looks like a partial export")
  d
}

if (file.exists(IRP_FILE)) {
  mat      <- read_irp(IRP_FILE)
  mat_what <- "Domestic extraction"
  mat_src  <- "Source: UN IRP Global Material Flows Database (manual export, see analysis/data-manual/)."
} else {
  warning("IRP export not found - falling back to UN SDG consumption data. ",
          "See analysis/data-manual/README-mfa4_export.txt")
  mat_lbl <- c(BIM = "Biomass", FOF = "Fossil fuels",
               MEO = "Metal ores", NMM = "Non-metallic minerals")
  mat <- rd("material_dmc.csv") |>
    filter(type %in% names(mat_lbl)) |>
    group_by(area, year, type) |> summarise(tonnes = max(tonnes), .groups = "drop") |>
    mutate(material = factor(mat_lbl[type], levels = names(mat_cols)),
           area = recode(area, Americas = "North America"))
  IRP_REGIONS <- setdiff(unique(mat$area), "World")
  mat_what <- "Domestic material consumption"
  mat_src  <- "Source: UN SDG Indicators Database, series EN_MAT_DOMCMPT (fallback - IRP export missing)."
}

mat_world <- mat |> filter(area == "World") |>
  group_by(year, material) |> summarise(tonnes = sum(tonnes), .groups = "drop")
MATY <- range(mat_world$year)

p11a <- ggplot(mat_world, aes(year, tonnes, fill = material)) +
  geom_area(color = "white", linewidth = 0.2) +
  scale_fill_manual(values = mat_cols) +
  scale_x_continuous(breaks = seq(MATY[1], MATY[2], 5)) +
  scale_y_continuous(labels = lbl_short) +
  labs(title = "World, by material group", x = NULL, y = "Tonnes") +
  theme_euf(base_size = 12)

reg_order <- mat |> filter(area %in% IRP_REGIONS, year == max(year)) |>
  group_by(area) |> summarise(t = sum(tonnes)) |> arrange(desc(t)) |> pull(area)
mat_reg <- mat |> filter(area %in% IRP_REGIONS) |>
  group_by(area, year) |> summarise(tonnes = sum(tonnes), .groups = "drop") |>
  group_by(year) |> mutate(share = tonnes / sum(tonnes) * 100) |> ungroup() |>
  mutate(area = factor(area, levels = reg_order))
area_cols <- setNames(c("#E0542F", "#C98A00", "#2A72B5", "#1F8A5B",
                        "#8A5FBF", "#00A0A8", "#6F6F6F")[seq_along(reg_order)],
                      reg_order)

# EECCA is the IRP's own abbreviation; spell it out for students
reg_labels <- c("EECCA" = "E. Europe, Caucasus & C. Asia",
                "Latin America + Caribbean" = "Latin America & Caribbean",
                "Asia + Pacific" = "Asia & Pacific")

p11b <- ggplot(mat_reg, aes(year, share, fill = area)) +
  geom_area(color = "white", linewidth = 0.2) +
  scale_fill_manual(values = area_cols,
                    labels = function(x) coalesce(reg_labels[x], x)) +
  scale_x_continuous(breaks = seq(MATY[1], MATY[2], 10)) +
  scale_y_continuous(labels = label_percent(scale = 1), expand = expansion(0)) +
  labs(title = "By world region (share of global total)", x = NULL, y = "Share") +
  guides(fill = guide_legend(ncol = 3)) +
  theme_euf(base_size = 12)

p11 <- (p11a | p11b) +
  plot_annotation(
    title = "The extraction of raw materials keeps increasing",
    subtitle = paste0(mat_what, ", ", MATY[1], "-", MATY[2],
                      ". Left: how much is taken out of the ground worldwide. Right: who takes it out."),
    caption = paste(mat_src),
    theme = theme_euf()) &
  theme(legend.position = "bottom")
save_euf(p11, "fig_11_material_use", width = 13, height = 6.2)

# ============================================================================
# 12 · GDP correlates with energy use and with emissions   [slides 12 and 13]
#      Requested as one figure with two plots.
# ============================================================================
d_en <- latest_wide(rd("gdp_energy.csv"), "eg_use_pcap_kg_oe")
d_co <- rd("gdp_co2.csv") |> rename(ny_gdp_pcap_pp_kd = gdp_per_capita) |>
  latest_wide("emissions_total_per_capita") |> filter(y > 0)

p12a <- panel_scatter(d_en, "kg of oil equivalent per person", "Energy use per capita",
                      log_y = TRUE, ylabels = lbl_short)
p12b <- panel_scatter(d_co, "tonnes CO2 per person", "CO2 emissions per capita",
                      log_y = TRUE, ylabels = label_number(accuracy = 0.1))

p12 <- combine_panels(p12a, p12b) +
  plot_annotation(
    title = "GDP correlates with energy use and with emissions",
    subtitle = paste0("One dot = one country, at its most recent observation.\n",
                      "Both axes are logarithmic, so a straight line means a constant percentage relationship."),
    caption = paste("Sources: Our World in Data - World Bank (energy) and Global Carbon Project (CO2).",
                    "Territorial emissions."),
    theme = theme_euf_wide())
save_euf(p12, "fig_12_energy_and_emissions", width = 12, height = 5.8)

# ============================================================================
# 14 · Decoupling of GDP from emissions                            [slide 14]
#      Country selection follows the wow-code example.
# ============================================================================
sel <- c("Germany", "United States", "World", "China", "India", "Switzerland")
BASE <- 1990

dec <- rd("gdp_co2_consumption.csv") |>
  filter(entity %in% sel, year >= BASE,
         !is.na(ny_gdp_pcap_pp_kd), !is.na(consumption_emissions_per_capita)) |>
  group_by(entity) |> arrange(year, .by_group = TRUE) |>
  filter(any(year == BASE)) |>
  mutate(`GDP per capita`  = ny_gdp_pcap_pp_kd / ny_gdp_pcap_pp_kd[year == BASE] * 100,
         `CO2 per capita`  = consumption_emissions_per_capita /
                             consumption_emissions_per_capita[year == BASE] * 100) |>
  ungroup() |>
  select(entity, year, `GDP per capita`, `CO2 per capita`) |>
  pivot_longer(-c(entity, year), names_to = "series", values_to = "index") |>
  mutate(entity = factor(entity, levels = sel))

dec_end <- dec |> group_by(entity, series) |> slice_max(year, n = 1) |> ungroup()

p14 <- ggplot(dec, aes(year, index, color = series)) +
  geom_hline(yintercept = 100, color = euf$gray, linewidth = 0.3, linetype = "dotted") +
  geom_line(linewidth = 1.1) +
  geom_text(data = dec_end, aes(label = sprintf("%+.0f%%", index - 100)),
            hjust = -0.15, size = 3.3, fontface = "bold", family = euf_family,
            show.legend = FALSE) +
  # free y: China's +1200% would otherwise flatten every other panel and hide
  # exactly the decoupling this figure is about
  facet_wrap(~ entity, ncol = 3, scales = "free_y") +
  scale_color_manual(values = c("GDP per capita" = "#2A72B5", "CO2 per capita" = "#E0542F")) +
  scale_x_continuous(breaks = seq(BASE, 2020, 10),
                     limits = c(BASE, max(dec$year) + 9)) +
  labs(title = "Some countries achieved decoupling of GDP from emissions",
       subtitle = paste0("GDP and consumption-based CO2 emissions per capita, index ", BASE,
                         " = 100.\nEmissions are adjusted for trade, so imported emissions count towards the importer. Note the different y-axes."),
       x = NULL, y = paste0("Index (", BASE, " = 100)"),
       caption = paste("Source: Our World in Data - Global Carbon Project and World Bank.")) +
  theme_euf() +
  theme(panel.spacing = unit(1.1, "lines"))
save_euf(p14, "fig_14_decoupling", width = 11, height = 6)

# ============================================================================
# 15 · Composite indicators also correlate with GDP                [slide 15]
# ============================================================================
d_hdi <- latest_wide(rd("gdp_hdi.csv"), "hdi__sex_total")

# Prados de la Escosura's Augmented HDI: health, education and civil/political
# liberties - a composite built deliberately differently from the UNDP index.
# Joined to Maddison GDP for the same year.
ahdi_raw <- rd("ahdi_escosura.csv") |> filter(!is.na(ahdi), !is.na(owid_region))
AY <- ahdi_raw |> count(year) |> filter(n >= 60) |> slice_max(year, n = 1) |> pull(year)
d_ahdi <- ahdi_raw |> filter(year == AY) |>
  inner_join(rd("gdp_maddison.csv") |> filter(year == AY) |>
               select(code, gdp = gdp_per_capita), by = "code") |>
  rename(y = ahdi) |> only_countries() |> filter(!is.na(gdp))

p15a <- panel_scatter(d_hdi, "HDI (0-1)", "Human Development Index")
p15b <- ggplot(d_ahdi, aes(gdp, y)) +
  geom_point(aes(fill = owid_region), shape = 21, color = "white",
             size = 2.5, stroke = 0.3, alpha = 0.9) +
  scale_fill_manual(values = region_pal, drop = FALSE, name = NULL) +
  scale_x_log10(breaks = gdp_breaks, labels = lbl_dollar) +
  labs(title = paste0("Augmented HDI, excluding income (", AY, ")"),
       x = "GDP per capita (log scale)", y = "Augmented HDI (0-1)") +
  theme_euf(base_size = 12)

p15 <- combine_panels(p15a, p15b) +
  plot_annotation(
    title = "Composite indicators also correlate with GDP",
    subtitle = paste0("Left: the UNDP index, which contains income itself.\n",
                      "Right: Prados de la Escosura's Augmented HDI, built from health, education and civil liberties only - the correlation survives."),
    caption = paste("Sources: Our World in Data - UNDP (HDI); Prados de la Escosura (Augmented HDI);",
                    "Maddison Project Database (GDP for the right panel)."),
    theme = theme_euf_wide()) &
  theme(legend.position = "bottom")
save_euf(p15, "fig_15_composite_indicators", width = 12, height = 5.8)

message("\nDone. Figures in ", FIG_DIR, "/")
