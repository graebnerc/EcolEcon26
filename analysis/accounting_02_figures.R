# ============================================================================
#  accounting_02_figures.R — rebuild the data figures for session 6b
#  ("Extractivism, externalization & the global accounting of ecological
#  stressors")
#
#  Replaces the Atlas screenshots (2022) and the two Schandl et al. (2017)
#  charts (data to 2010) of the 2025 deck with figures from current data:
#    · export treemaps, Africa vs. Europe (Atlas data)        [slide 8]
#    · physical trade balance by IRP world region             [slide 9]
#    · material footprint per capita by HDI group             [slide 10]
#
#  There is no download script for this session: it reads only files that
#  already exist —
#    analysis/data-manual/mfa4_export.csv   (IRP export, see its README)
#    analysis/data-raw/gdp_hdi.csv          (OWID, written by 01_download.R)
#    analysis/data-raw/atlas_*.csv          (Atlas, trade_01_download.R)
#  Writes PDF + SVG into analysis/figures/ and copies the SVGs into
#  content/material/slides/figures/. Names are fig_L06b_<slide>_<topic>; the
#  number is the slide of the 2025 PDF deck.
#
#  Run:  Rscript analysis/accounting_02_figures.R
# ============================================================================

source(file.path("analysis", "R", "euf_style.R"))
suppressPackageStartupMessages(library(treemapify))

RAW       <- file.path("analysis", "data-raw")
FIG_DIR   <- file.path("analysis", "figures")
SLIDE_DIR <- file.path("content", "material", "slides", "figures")
IRP_FILE  <- file.path("analysis", "data-manual", "mfa4_export.csv")
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(SLIDE_DIR, showWarnings = FALSE, recursive = TRUE)

save_l06b <- function(plot, file, width = 9, height = 5.4) {
  save_euf(plot, file, width, height)
  invisible(file.copy(file.path(FIG_DIR, paste0(file, ".svg")), SLIDE_DIR, overwrite = TRUE))
}

if (!file.exists(IRP_FILE))
  stop("IRP export missing - see analysis/data-manual/README-mfa4_export.txt")

message("Building session 6b figures ...")

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

IRP_REGIONS <- c("Africa", "Asia + Pacific", "EECCA", "Europe",
                 "Latin America + Caribbean", "North America", "West Asia")
reg_labels  <- c("EECCA" = "E. Europe, Caucasus & C. Asia",
                 "Latin America + Caribbean" = "Latin America & Caribbean",
                 "Asia + Pacific" = "Asia & Pacific")

# ============================================================================
# 8 · What Africa and Europe export                                [slide 8]
# ============================================================================
# One treemap per Atlas region: the area of a tile is the product's share in
# the region's goods exports (HS92, 4 digits), its colour the Atlas sector.
# Services are left out - the slide is about what is taken out of the ground
# and what is made from it. The exports of a region are the sum of its
# members' exports, trade between members included (as on the Atlas website).
rda <- function(f) read_csv(file.path(RAW, f), show_col_types = FALSE, progress = FALSE)
atl_prod <- rda("atlas_hs92_products.csv")
atl_cpy  <- rda("atlas_cpy_hs92.csv")
atl_grp  <- rda("atlas_groups.csv") |> filter(group_type == "region")
ATLAS_YEAR <- max(atl_cpy$year)

# Atlas sector order; the hues follow the Atlas website loosely, so that the
# picture is recognisable when students open the Atlas for their country.
sector_cols <- c("Agriculture" = "#E3C35A", "Minerals" = "#B6705A",
                 "Stone" = "#D9A589", "Metals" = "#D35F5F",
                 "Chemicals" = "#C25A9B", "Textiles" = "#7FB77E",
                 "Machinery" = "#6A8FD1", "Electronics" = "#7DC4D8",
                 "Vehicles" = "#8E79C9", "Other" = "#9E9E9E")

region_exports <- function(region) {
  members <- atl_grp$countryId[atl_grp$group == region]
  if (!length(members)) stop("Atlas: no members for region ", region)
  atl_cpy |>
    filter(countryId %in% members, exportValue > 0) |>
    group_by(productId) |>
    summarise(value = sum(exportValue), .groups = "drop") |>
    inner_join(atl_prod, by = "productId") |>
    filter(sector != "Services") |>
    mutate(share = value / sum(value),
           sector = factor(sector, levels = names(sector_cols)),
           # only tiles big enough to carry it get a label
           label = if_else(share >= 0.012,
                           paste0(nameShortEn, "\n", label_percent(0.1)(share)), ""))
}

treemap_panel <- function(region, adjective) {
  d <- region_exports(region)
  message(sprintf("  %s %d: goods exports US$ %.0f bn, top product %s (%.1f%%)",
                  region, ATLAS_YEAR, sum(d$value) / 1e9,
                  d$nameShortEn[which.max(d$share)], max(d$share) * 100))
  ggplot(d, aes(area = value, fill = sector, subgroup = sector, label = label)) +
    geom_treemap(color = "white", size = 0.4) +
    geom_treemap_subgroup_border(color = "white", size = 2.5) +
    geom_treemap_text(family = euf_family, colour = "white", place = "topleft",
                      reflow = TRUE, grow = FALSE, size = 13, min.size = 7,
                      padding.x = grid::unit(1.5, "mm"), padding.y = grid::unit(1.5, "mm")) +
    scale_fill_manual(values = sector_cols, drop = FALSE) +
    labs(title = paste("Exports by", adjective, "countries")) +
    theme_euf(base_size = 14) +
    theme(legend.position = "bottom")
}

p08 <- (treemap_panel("Africa", "African") | treemap_panel("Europe", "European")) +
  plot_layout(guides = "collect") +
  plot_annotation(
    caption = paste0("Goods exports in ", ATLAS_YEAR, ", HS92 4-digit products; ",
                     "tile area = share of the region's exports. ",
                     "Source: Growth Lab at Harvard University, Atlas of Economic Complexity."),
    theme = theme_euf()) &
  theme(legend.position = "bottom") &
  guides(fill = guide_legend(nrow = 1))
save_l06b(p08, "fig_L06b_08_exports_treemap", width = 14, height = 6.4)

# ============================================================================
# 9 · Physical trade balance by world region                       [slide 9]
# ============================================================================
# PTB = imports - exports, in tonnes, summed over all material categories.
# Positive: the region takes in more material than it sends out.
ptb <- irp |>
  filter(flow == "PTB", area %in% IRP_REGIONS, year >= 1970) |>
  group_by(area, year) |>
  summarise(tonnes = sum(tonnes), .groups = "drop")

if (n_distinct(ptb$area) != length(IRP_REGIONS))
  stop("IRP export: physical trade balance missing for some regions")
PTBY <- range(ptb$year)

# Order: net importers on top, net exporters at the bottom, by the last year.
ptb_order <- ptb |> filter(year == PTBY[2]) |> arrange(desc(tonnes)) |> pull(area)
# Same hues as the OWID regions in euf_style.R where the regions match.
ptb_cols  <- c("Africa" = "#E0542F", "Asia + Pacific" = "#1F8A5B",
               "EECCA" = "#6F6F6F", "Europe" = "#2A72B5",
               "Latin America + Caribbean" = "#8A5FBF",
               "North America" = "#C98A00", "West Asia" = "#00A0A8")
ptb <- ptb |> mutate(area = factor(area, levels = ptb_order))

p09 <- ggplot(ptb, aes(year, tonnes / 1e9, fill = area)) +
  geom_col(width = 0.8, color = NA) +
  geom_hline(yintercept = 0, color = euf$ink, linewidth = 0.4) +
  scale_fill_manual(values = ptb_cols,
                    labels = function(x) coalesce(reg_labels[x], x)) +
  scale_x_continuous(breaks = seq(1970, PTBY[2], 10), expand = expansion(0.01)) +
  scale_y_continuous(labels = label_number(suffix = " bn t")) +
  labs(title = "Who imports and who exports raw materials",
       subtitle = paste0("Physical trade balance (imports minus exports) by world region, ",
                         PTBY[1], "-", PTBY[2],
                         ". Above zero: net importers. Below zero: net exporters."),
       x = NULL, y = NULL,
       caption = "Source: UN IRP Global Material Flows Database (manual export, see analysis/data-manual/). All material groups.") +
  guides(fill = guide_legend(nrow = 2)) +
  theme_euf_main(20)
save_l06b(p09, "fig_L06b_09_physical_trade_balance", width = 12, height = 6.6)

# ============================================================================
# 10 · Material footprint per capita by HDI group                  [slide 10]
# ============================================================================
# Material footprint (raw material consumption): all raw materials extracted
# anywhere in the world for a country's final demand. Countries are grouped by
# their most recent HDI (UNDP thresholds) and kept in that group for every
# year, so a line moves because footprints move, not because countries change
# groups. Population and HDI from Our World in Data.
irp_to_owid <- c("Brunei Darussalam" = "Brunei", "Czech Republic" = "Czechia",
                 "DR Congo" = "Democratic Republic of Congo", "Rep Congo" = "Congo",
                 "Russian Federation" = "Russia", "United States of America" = "United States",
                 "Viet Nam" = "Vietnam")

owid <- read_csv(file.path(RAW, "gdp_hdi.csv"), show_col_types = FALSE, progress = FALSE) |>
  filter(nchar(code) == 3)

hdi_group <- owid |>
  filter(!is.na(hdi__sex_total)) |>
  group_by(entity) |> slice_max(year, n = 1) |> ungroup() |>
  mutate(group = cut(hdi__sex_total, c(-Inf, 0.55, 0.70, 0.80, Inf), right = FALSE,
                     labels = c("Low HDI", "Medium HDI", "High HDI", "Very high HDI"))) |>
  select(entity, group, hdi_year = year)
HDI_YEAR <- max(hdi_group$hdi_year)

pop <- owid |> filter(!is.na(population_historical)) |>
  select(entity, year, pop = population_historical)

# From 1995: before that the successor states of the USSR, Czechoslovakia and
# Yugoslavia enter the data one by one, which would put breaks into the lines.
mf <- irp |>
  filter(flow == "MF", !area %in% c("World", IRP_REGIONS), year >= 1995) |>
  group_by(area, year) |>
  summarise(tonnes = sum(tonnes), .groups = "drop") |>
  mutate(entity = coalesce(irp_to_owid[area], area)) |>
  inner_join(pop, by = c("entity", "year"))

dropped <- setdiff(unique(irp$area[irp$flow == "MF"]),
                   c("World", IRP_REGIONS, unique(mf$area)))
if (length(dropped))
  message("  note: no OWID population for ", paste(dropped, collapse = ", "))

mf_grp <- mf |>
  inner_join(hdi_group, by = "entity") |>
  group_by(group, year) |>
  summarise(t_pc = sum(tonnes) / sum(pop), n = n_distinct(entity), .groups = "drop")
mf_world <- mf |> group_by(year) |>
  summarise(t_pc = sum(tonnes) / sum(pop), .groups = "drop") |>
  mutate(group = "World")
MFY <- range(mf_grp$year)

mf_all <- bind_rows(mf_grp, mf_world) |>
  mutate(group = factor(group, levels = c("Very high HDI", "High HDI",
                                          "Medium HDI", "Low HDI", "World")))
mf_cols <- c("Very high HDI" = "#2A72B5", "High HDI" = "#1F8A5B",
             "Medium HDI" = "#C98A00", "Low HDI" = "#E0542F", "World" = "#6F6F6F")
mf_lab  <- mf_all |> filter(year == MFY[2])

p10 <- ggplot(mf_all, aes(year, t_pc, color = group)) +
  geom_line(aes(linetype = group == "World"), linewidth = 1.1, show.legend = FALSE) +
  geom_text(data = mf_lab, aes(label = group), hjust = 0, nudge_x = 0.8,
            family = euf_family, fontface = "bold", size = 4.6, show.legend = FALSE) +
  scale_color_manual(values = mf_cols) +
  scale_linetype_manual(values = c("FALSE" = "solid", "TRUE" = "22")) +
  scale_x_continuous(breaks = seq(1995, MFY[2], 5),
                     limits = c(MFY[1], MFY[2] + 8), expand = expansion(0)) +
  scale_y_continuous(limits = c(0, NA), labels = label_number(suffix = " t")) +
  labs(title = "Material footprint per person, by human development",
       subtitle = paste0("Raw materials extracted worldwide for a country's final demand, ",
                         "tonnes per capita, ", MFY[1], "-", MFY[2],
                         ".\nCountries grouped by their HDI in ", HDI_YEAR, "."),
       x = NULL, y = NULL,
       caption = "Sources: UN IRP Global Material Flows Database (material footprint); UNDP via Our World in Data (HDI, population).") +
  theme_euf_main(20)
save_l06b(p10, "fig_L06b_10_material_footprint_hdi", width = 10, height = 6.2)

# The numbers the slide text could quote - re-check after every data refresh.
message("  material footprint per capita, ", MFY[2], ":")
for (i in seq_len(nrow(mf_lab)))
  message(sprintf("    %-14s %5.1f t", mf_lab$group[i], mf_lab$t_pc[i]))
message("  countries per HDI group: ",
        paste(mf_grp |> filter(year == MFY[2]) |>
                transmute(paste0(group, " ", n)) |> pull(), collapse = ", "))
