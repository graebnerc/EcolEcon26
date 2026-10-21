# ============================================================================
#  trade_02_figures.R — rebuild the data figures for session 5 ("Free trade:
#  blessing or curse?")
#
#  Reads only what trade_01_download.R wrote into analysis/data-raw/, writes
#  PDF + SVG into analysis/figures/ and copies the SVGs into
#  content/material/slides/figures/, where the revealjs deck picks them up.
#  Names are fig_L05_<slide>_<topic>; the number is the slide of the PDF deck.
#
#  It also prints the handful of numbers the slide text quotes (South Korea's
#  GDP multiple, machinery share). Those are typed into the deck by hand, so
#  check them against this output after every data refresh.
#
#  Run:  Rscript analysis/trade_01_download.R && Rscript analysis/trade_02_figures.R
# ============================================================================

source(file.path("analysis", "R", "euf_style.R"))
suppressPackageStartupMessages(library(readxl))

RAW       <- file.path("analysis", "data-raw")
FIG_DIR   <- file.path("analysis", "figures")
SLIDE_DIR <- file.path("content", "material", "slides", "figures")
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(SLIDE_DIR, showWarnings = FALSE, recursive = TRUE)
rd <- function(f) read_csv(file.path(RAW, f), show_col_types = FALSE,
                           progress = FALSE)

# save_euf() plus the copy into the deck's figure folder.
save_l05 <- function(plot, file, width = 9, height = 5.4) {
  save_euf(plot, file, width, height)
  invisible(file.copy(file.path(FIG_DIR, paste0(file, ".svg")), SLIDE_DIR, overwrite = TRUE))
}

message("Building session 5 figures ...")

# ============================================================================
# 14 · South Korea: exports by product group, and GDP per capita    [slide 14]
# ============================================================================
# Goods only. The Atlas adds services from 1980 onwards; including them would
# put a break into the share panel exactly where the story is told, and the
# 1962 vs today comparison on the slide is a comparison of goods exports.
# The ten SITC sections are folded into six groups so that every band can
# carry a direct label.
sitc_groups <- c(
  "0" = "Primary goods", "1" = "Primary goods", "2" = "Primary goods",
  "4" = "Primary goods", "3" = "Fuels", "5" = "Chemicals",
  "6" = "Material manufactures", "7" = "Machinery & vehicles",
  "8" = "Other manufactures", "9" = "Other manufactures")
grp_levels <- c("Primary goods", "Fuels", "Chemicals", "Material manufactures",
                "Other manufactures", "Machinery & vehicles")
grp_pal <- setNames(unname(region_pal[c("North America", "Oceania", "South America",
                                        "Africa", "Asia", "Europe")]), grp_levels)

kor <- rd("atlas_kor_sitc.csv") |>
  left_join(rd("atlas_sitc_sections.csv"), by = "productId") |>
  filter(code != "services") |>
  mutate(group = factor(sitc_groups[code], levels = grp_levels)) |>
  group_by(year, group) |>
  summarise(value = sum(exportValue, na.rm = TRUE), .groups = "drop") |>
  group_by(year) |>
  mutate(share = value / sum(value)) |>
  ungroup()

KOR_FIRST <- min(kor$year); KOR_LAST <- max(kor$year)
mach <- kor |> filter(group == "Machinery & vehicles")
mach_first <- mach$share[mach$year == KOR_FIRST]
mach_last  <- mach$share[mach$year == KOR_LAST]

# Direct labels sit in the middle of each band in the final year.
lab_share <- kor |>
  filter(year == KOR_LAST) |>
  arrange(desc(group)) |>
  mutate(y = cumsum(share) - share / 2)

p14a <- ggplot(kor, aes(year, value / 1e9, fill = group)) +
  geom_area(color = PAPER_BG, linewidth = 0.3) +
  scale_fill_manual(values = grp_pal) +
  scale_x_continuous(breaks = seq(1965, 2025, 10),
                     limits = c(KOR_FIRST, KOR_LAST + 22), expand = expansion(0)) +
  scale_y_continuous(labels = label_dollar(suffix = " bn"),
                     expand = expansion(mult = c(0, 0.04))) +
  labs(title = "Goods exports, current US$", x = NULL, y = NULL) +
  theme_euf(base_size = 12) + theme(legend.position = "none")

p14b <- ggplot(kor, aes(year, share, fill = group)) +
  geom_area(color = PAPER_BG, linewidth = 0.3) +
  geom_text_repel(data = lab_share, aes(x = KOR_LAST + 1, y = y, label = group,
                                        color = group),
                  hjust = 0, direction = "y", size = 3.4, fontface = "bold",
                  family = euf_family, segment.color = NA, box.padding = 0.15,
                  xlim = c(KOR_LAST + 1, NA), seed = 1) +
  scale_fill_manual(values = grp_pal) +
  scale_color_manual(values = grp_pal) +
  scale_x_continuous(breaks = seq(1965, 2025, 10),
                     limits = c(KOR_FIRST, KOR_LAST + 22), expand = expansion(0)) +
  scale_y_continuous(labels = label_percent(), expand = expansion(0)) +
  coord_cartesian(clip = "off") +
  labs(title = "Share of goods exports", x = NULL, y = NULL) +
  theme_euf(base_size = 12) + theme(legend.position = "none")

# Two separate files: the deck builds them one after the other.
p14a <- p14a + labs(title = "What did South Korea export? Goods, current US$") +
  theme(plot.title = element_text(size = 16))
p14b <- p14b +
  labs(title = "What did South Korea export? Shares of goods exports",
       caption = paste0("Source: Harvard Growth Lab, Atlas of Economic Complexity ",
                        "(SITC rev. 2, goods only), ", KOR_FIRST, "-", KOR_LAST, ". ",
                        "Primary goods: SITC 0, 1, 2 and 4.")) +
  theme(plot.title = element_text(size = 16))
save_l05(p14a, "fig_L05_14_korea_exports_value", width = 8, height = 3.2)
save_l05(p14b, "fig_L05_14_korea_exports_share", width = 8, height = 3.5)

# GDP per capita, long run — the OWID chart that sat on the Keynote slide.
mad_sel <- c("South Korea" = "South Korea",
             "Western Europe (Maddison)" = "Western Europe",
             "World" = "World",
             "Sub Saharan Africa (Maddison)" = "Sub-Saharan Africa")
gdp <- rd("gdp_maddison.csv") |>
  filter(entity %in% names(mad_sel), year >= 1820, !is.na(gdp_per_capita)) |>
  mutate(series = factor(mad_sel[entity], levels = unname(mad_sel)))
GDP_LAST <- max(gdp$year[gdp$series == "South Korea"])
kor_gdp  <- gdp |> filter(series == "South Korea")
gdp_mult <- kor_gdp$gdp_per_capita[kor_gdp$year == GDP_LAST] /
            kor_gdp$gdp_per_capita[kor_gdp$year == 1960]
gdp_end  <- gdp |> group_by(series) |> slice_max(year, n = 1) |> ungroup()
gdp_pal  <- c("South Korea" = euf$red, "Western Europe" = euf$blue_mid,
              "World" = euf$ink, "Sub-Saharan Africa" = region_pal[["Asia"]])

p14_gdp <- ggplot(gdp, aes(year, gdp_per_capita, color = series)) +
  geom_line(linewidth = 1.1) +
  geom_text_repel(data = gdp_end, aes(label = series), hjust = 0,
                  direction = "y", nudge_x = 5, size = 3.8, fontface = "bold",
                  family = euf_family, segment.color = euf$grid,
                  min.segment.length = 0, seed = 1, xlim = c(GDP_LAST + 3, NA)) +
  scale_color_manual(values = gdp_pal) +
  scale_x_continuous(breaks = seq(1820, 2020, 40),
                     limits = c(1820, GDP_LAST + 55), expand = expansion(mult = c(0.01, 0))) +
  scale_y_continuous(labels = lbl_dollar) +
  labs(title = paste0("GDP per capita, 1820 to ", GDP_LAST),
       subtitle = "Adjusted for inflation and for differences in living costs (int.-$ at 2011 prices)",
       x = NULL, y = NULL,
       caption = paste("Source: Bolt and van Zanden, Maddison Project Database 2023,",
                       "via Our World in Data.")) +
  theme_euf_main(title_size = 20) + theme(legend.position = "none")
save_l05(p14_gdp, "fig_L05_14_korea_gdp", width = 8, height = 4.4)

# ============================================================================
# 16 · Solar PV: the learning curve                                  [slide 16]
# ============================================================================
solar <- rd("solar_learning_curve.csv") |>
  filter(entity == "World", !is.na(cost), !is.na(cumulative_capacity))
SOLAR_FIRST <- min(solar$year); SOLAR_LAST <- max(solar$year)
solar_lab <- solar |> filter(year %in% c(SOLAR_FIRST, seq(1980, 2020, 5), SOLAR_LAST))

p16 <- ggplot(solar, aes(cumulative_capacity, cost)) +
  geom_line(color = euf$blue_mid, linewidth = 1.1) +
  geom_point(data = solar_lab, color = euf$blue_mid, size = 2.4) +
  geom_text_repel(data = solar_lab, aes(label = year), size = 3.5,
                  family = euf_family, color = euf$muted, seed = 2,
                  nudge_x = 0.12, nudge_y = 0.12, min.segment.length = 1) +
  scale_x_log10(labels = label_comma(suffix = " MW")) +
  scale_y_log10(labels = label_dollar(accuracy = 0.01, drop0trailing = TRUE),
                breaks = c(0.25, 0.5, 1, 2, 5, 10, 20, 50, 100)) +
  labs(title = "Solar PV module prices vs. cumulative capacity",
       subtitle = "Module cost in constant 2024 US$ per watt; both axes logarithmic",
       x = "Cumulative installed solar PV capacity", y = NULL,
       caption = paste0("Source: Nemet (2009), Farmer and Lafond (2016), IRENA, ",
                        "via Our World in Data; ", SOLAR_FIRST, "-", SOLAR_LAST, ".")) +
  theme_euf_main(title_size = 20)
save_l05(p16, "fig_L05_16_solar_learning", width = 8, height = 5.2)

# Module production by country, 2024 — hand-entered from IEA-PVPS (2025),
# see data-manual/README-pv_module_production_2024.txt.
pv <- read_csv(file.path("analysis", "data-manual", "pv_module_production_2024.csv"),
               show_col_types = FALSE) |>
  mutate(share = gw / sum(gw),
         country = fct_relevel(fct_reorder(country, gw), "Rest of world"))
p16b <- ggplot(pv, aes(gw, country)) +
  geom_col(aes(fill = country == "China"), width = 0.7) +
  geom_text(aes(label = paste0(gw, " GW (", label_percent(accuracy = 1)(share), ")")),
            hjust = -0.08, size = 3.8, family = euf_family, color = euf$ink) +
  scale_fill_manual(values = c(`TRUE` = euf$red, `FALSE` = "#9FB3C2"), guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.3)), labels = label_number(suffix = " GW")) +
  labs(title = "Solar PV module production, 2024",
       subtitle = paste0("World: ", sum(pv$gw), " GW"),
       x = NULL, y = NULL,
       caption = paste("Source: IEA-PVPS, Trends in PV Applications 2025, as reported by",
                       "pv magazine (17.10.2025).\nRest of world: residual.")) +
  theme_euf_main(title_size = 20) +
  theme(panel.grid.major.y = element_blank())
save_l05(p16b, "fig_L05_16_pv_production", width = 8, height = 5.2)

# ============================================================================
# 20 · Terms of trade of primary commodities (Prebisch-Singer)       [slide 20]
# ============================================================================
# Grilli-Yang: 24 commodity prices deflated by the manufactures unit value
# (MUV), 1977-79 = 100 in the source. The series ends in 2016; it is carried
# forward with the year-on-year change of the World Bank's real (MUV-deflated)
# non-energy index, which is the closest published successor. The extension is
# drawn dashed so it is never mistaken for the original series.
gy <- read_excel(file.path(RAW, "gycpi_1900_2016.xlsx"), sheet = "gycpi") |>
  transmute(year = as.integer(Year), index = 100 * GY) |>
  filter(!is.na(year), !is.na(index))

wb_raw <- read_excel(file.path(RAW, "wb_cmo_annual.xlsx"),
                     sheet = "Annual Indices (Real)", col_names = FALSE,
                     .name_repair = "minimal")
nonenergy_col <- which(trimws(unlist(wb_raw[6, ])) == "Non-energy")
stopifnot("Pink Sheet layout changed: no 'Non-energy' column" = length(nonenergy_col) == 1)
wb <- tibble(year  = suppressWarnings(as.integer(unlist(wb_raw[, 1]))),
             value = suppressWarnings(as.numeric(unlist(wb_raw[, nonenergy_col])))) |>
  filter(!is.na(year), !is.na(value))

GY_LAST <- max(gy$year)
ext <- wb |>
  filter(year >= GY_LAST) |>
  mutate(index = gy$index[gy$year == GY_LAST] * value / value[year == GY_LAST]) |>
  select(year, index)
TOT_LAST <- max(ext$year)

tot <- bind_rows(gy |> mutate(part = "Grilli-Yang index"),
                 ext |> mutate(part = "Extension"))
trend <- lm(index ~ year, data = gy)
trend_pct <- 100 * coef(trend)[["year"]] / mean(gy$index)

p20 <- ggplot(tot, aes(year, index)) +
  geom_hline(yintercept = 100, color = euf$gray, linewidth = 0.3) +
  geom_line(aes(linetype = part), color = euf$blue_mid, linewidth = 0.9) +
  geom_smooth(data = gy, method = "lm", formula = y ~ x, se = FALSE,
              color = euf$ink, linewidth = 0.7, fullrange = FALSE) +
  scale_linetype_manual(values = c("Grilli-Yang index" = "solid", "Extension" = "22"),
                        guide = "none") +
  scale_x_continuous(breaks = seq(1900, 2020, 20)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  labs(title = "Real price of primary commodities, 1900 to present",
       subtitle = paste0("Commodity prices relative to prices of manufactures, 1977-79 = 100\n",
                         "Straight line: linear trend ", min(gy$year), "-", GY_LAST),
       x = NULL, y = NULL,
       caption = paste0(
         "Source: Grilli-Yang commodity price index (24 commodities, deflated by the ",
         "manufactures unit value index),\nPfaffenzeller et al. (2007), updated to ",
         GY_LAST, " by Geronimi, Anani and Taranco (2017), Mendeley Data, CC BY-NC 3.0.\n",
         "Dashed: ", GY_LAST, "-", TOT_LAST, ", chained with the World Bank ",
         "real non-energy commodity price index (Pink Sheet).")) +
  theme_euf_main(title_size = 20)
save_l05(p20, "fig_L05_20_terms_of_trade", width = 8, height = 5.2)

# ============================================================================
# 21 · The country-product matrix (RCA >= 1)                         [slide 21]
# ============================================================================
countries <- rd("atlas_countries.csv")
# HS codes are strings with leading zeros ("0101"); read_csv would make them
# numbers, so every code is read as character and padded back to four digits.
pad4  <- function(x) str_pad(as.character(x), 4, pad = "0")
prods <- rd("atlas_hs92_products.csv") |> mutate(code = pad4(code))
cpy       <- rd("atlas_cpy_hs92.csv")
ATLAS_YEAR <- unique(cpy$year)

# Same filters as the Atlas rankings, approximately: drop micro-exporters
# (under US$ 1 bn of goods) and products nobody exports, which only add noise.
big <- cpy |> group_by(countryId) |> summarise(x = sum(exportValue)) |>
  filter(x >= 1e9) |> pull(countryId)
# Products: the 865 that the product space shows (the Atlas drops services and
# a few hundred tiny or unreliable codes there too).
ps_products <- prods$productId[prods$code %in%
                 pad4(rd("productspace_layout_hs92.csv")$product_hs92_code)]
mcp <- cpy |>
  filter(countryId %in% big, productId %in% ps_products) |>
  mutate(m = as.integer(coalesce(exportRca, 0) >= 1))

diversity <- mcp |> group_by(countryId) |> summarise(div = sum(m))
ubiquity  <- mcp |> group_by(productId) |> summarise(ubi = sum(m))
mcp <- mcp |>
  left_join(diversity, by = "countryId") |>
  left_join(ubiquity,  by = "productId") |>
  mutate(country = reorder(countryId, div),        # most diversified on top
         product = reorder(productId, -ubi))       # most ubiquitous on the left

p21 <- ggplot(mcp, aes(product, country, fill = factor(m))) +
  geom_raster() +
  scale_fill_manual(values = c("0" = euf$wash, "1" = euf$blue),
                    labels = c("0" = "No comparative advantage",
                               "1" = "Exported with comparative advantage (RCA ≥ 1)")) +
  scale_x_discrete(expand = expansion(0)) +
  scale_y_discrete(expand = expansion(0)) +
  labs(x = "Products  →  from ubiquitous to exclusive",
       y = "Countries  →  more diversified",
       caption = paste0("Source: Harvard Growth Lab, Atlas of Economic Complexity, ",
                        ATLAS_YEAR, "; HS92 4-digit, ",
                        n_distinct(mcp$countryId), " countries with goods exports ",
                        "≥ US$ 1 bn, ", n_distinct(mcp$productId), " products.")) +
  theme_euf(base_size = 12) +
  theme(axis.text = element_blank(), panel.grid = element_blank(),
        legend.position = "top", legend.key.width = unit(0.5, "cm"))
save_l05(p21, "fig_L05_21_rca_matrix", width = 9, height = 3.4)

# ============================================================================
# 24-25 · The product space                                   [slides 24, 25]
# ============================================================================
# Layout and the top relatedness links come from the Growth Lab's own
# product-space network (CC0), so the picture is the one the Atlas draws.
layout <- rd("productspace_layout_hs92.csv") |> mutate(code = pad4(product_hs92_code))
edges  <- rd("productspace_edges_hs92.csv") |>
  mutate(across(everything(), pad4)) |>
  filter(product_hs92_code_source < product_hs92_code_target) |>
  inner_join(layout |> select(code, x = product_space_x, y = product_space_y),
             by = c(product_hs92_code_source = "code")) |>
  inner_join(layout |> select(code, xend = product_space_x, yend = product_space_y),
             by = c(product_hs92_code_target = "code"))

# Node size: world trade in the product, on the sqrt scale so AREA carries it.
world_x <- cpy |> group_by(productId) |> summarise(world = sum(exportValue))
nodes <- layout |>
  left_join(prods |> select(productId, code), by = "code") |>
  left_join(world_x, by = "productId") |>
  rename(x = product_space_x, y = product_space_y, cluster = product_space_cluster_name)

# Eight clusters: the reference eight-hue palette from the dataviz method,
# which validates on adjacent pairs; the legend carries identity.
cluster_pal <- c("#2a78d6", "#eb6834", "#1baf7a", "#eda100",
                 "#e87ba4", "#008300", "#6250d6", "#e34948")
names(cluster_pal) <- sort(unique(nodes$cluster))

ps_base <- function() list(
  geom_segment(data = edges, aes(x = x, y = y, xend = xend, yend = yend),
               inherit.aes = FALSE, color = "#C9D1D8", linewidth = 0.25),
  scale_size(range = c(0.5, 5), trans = "sqrt", guide = "none"),
  coord_equal(),
  theme_void(base_family = euf_family),
  theme(plot.background = element_rect(fill = PAPER_BG, color = NA)))

p24 <- ggplot(nodes, aes(x, y)) +
  ps_base() +
  geom_point(aes(size = world, fill = cluster), shape = 21, color = PAPER_BG,
             stroke = 0.25) +
  scale_fill_manual(values = cluster_pal, labels = function(x) str_wrap(x, 24)) +
  guides(fill = guide_legend(override.aes = list(size = 4), ncol = 4)) +
  labs(caption = paste0("Each node is a product (HS92 4-digit), sized by world trade in ",
                        ATLAS_YEAR, "; links join products that tend to be exported together.\n",
                        "Source: Harvard Growth Lab, Atlas of Economic Complexity; ",
                        "product space network (doi:10.7910/DVN/FCDZBN, CC0).")) +
  theme(legend.position = "bottom", legend.title = element_blank(),
        legend.text = element_text(color = euf$ink, size = 10),
        plot.caption = element_text(color = euf$muted, size = 9, hjust = 0))
save_l05(p24, "fig_L05_24_product_space", width = 9.5, height = 6.6)

# Three country groups, as in Hausmann, Hidalgo et al. A group's summed
# exports would be far more diversified than any of its members (Africa as a
# whole exports a bit of everything), so each node is shaded by the SHARE of
# the group's countries that export the product with RCA >= 1. Only countries
# with goods exports of at least US$ 1 bn count, as in the matrix above.
groups <- rd("atlas_groups.csv")
in_grp <- function(g) groups$countryId[groups$group == g]
industrialised <- intersect(in_grp("high"),
                            c(in_grp("Europe"), in_grp("Northern America"),
                              in_grp("Australia and New Zealand"), in_grp("Eastern Asia")))
grp_def <- list("Industrialised countries" = industrialised,
                "Latin American countries" = in_grp("Latin America & Caribbean"),
                "African countries"        = in_grp("Africa"))

grp_share <- imap_dfr(grp_def, function(ids, nm) {
  ids <- intersect(ids, big)
  cpy |> filter(countryId %in% ids) |>
    group_by(productId) |>
    summarise(share = mean(coalesce(exportRca, 0) >= 1), .groups = "drop") |>
    mutate(group = nm, n = length(ids))
}) |> mutate(group = factor(group, levels = names(grp_def)))
grp_n <- grp_share |> distinct(group, n)
levels(grp_share$group) <- paste0(grp_n$group, " (", grp_n$n, ")")

ps_grp <- nodes |>
  select(productId, x, y, world) |>
  inner_join(grp_share, by = "productId", relationship = "many-to-many") |>
  arrange(share)

p25 <- ggplot(ps_grp, aes(x, y)) +
  ps_base() +
  geom_point(aes(size = world, fill = share), shape = 21, color = PAPER_BG,
             stroke = 0.2) +
  # Capped at 50%: a product half the group exports competitively is already
  # a core strength, and a 0-100% scale would leave every node pale.
  scale_fill_gradient(low = "#E3E8EC", high = euf$blue, limits = c(0, 0.5),
                      oob = squish, breaks = c(0, 0.25, 0.5),
                      labels = c("0%", "25%", "50% or more"),
                      name = "Share of the group's countries exporting the product with RCA ≥ 1") +
  facet_wrap(~ group, nrow = 1) +
  guides(fill = guide_colorbar(title.position = "top", barwidth = unit(7, "cm"),
                               barheight = unit(0.35, "cm"))) +
  labs(caption = paste0(
    ATLAS_YEAR, "; countries with goods exports of at least US$ 1 bn (number in brackets). ",
    "Industrialised: high-income countries in Europe, Northern America, Eastern Asia,\n",
    "Australia and New Zealand. Latin America: World Bank region Latin America & Caribbean. ",
    "Africa: all of the continent. Source: Harvard Growth Lab, Atlas of Economic Complexity.")) +
  theme(legend.position = "bottom",
        legend.title = element_text(color = euf$ink, size = 10),
        legend.text = element_text(color = euf$ink, size = 9),
        strip.text = element_text(color = euf$blue, face = "bold", size = 13,
                                  margin = margin(b = 4)),
        plot.caption = element_text(color = euf$muted, size = 9, hjust = 0))
# The deck shows the panels WITHOUT their titles first (which group is which?)
# and sets the titles as HTML labels; keep the strip height so the panels sit
# exactly where they would with titles.
p25_blind <- p25 + theme(strip.text = element_text(color = NA, size = 13,
                                                   margin = margin(b = 4)))
save_l05(p25_blind, "fig_L05_25_product_space_groups_blind", width = 12, height = 4.8)
message("  slide 25  facet labels: ", paste(levels(grp_share$group), collapse = " | "))
save_l05(p25, "fig_L05_25_product_space_groups", width = 12, height = 4.8)

# ============================================================================
# L06a · Lithium carbonate: Chile in world trade                  [L06a case]
# ============================================================================
cname <- setNames(countries$nameShortEn, countries$countryId)
top_share <- function(df, id, k = 5) {
  df |>
    mutate(name = recode(cname[.data[[id]]], "United States of America" = "USA"),
           share = exportValue / sum(exportValue)) |>
    arrange(desc(share)) |>
    mutate(name = if_else(row_number() <= k, name, "All others")) |>
    group_by(name) |> summarise(share = sum(share), .groups = "drop") |>
    mutate(name = fct_reorder(name, share), name = fct_relevel(name, "All others"))
}
li_exp <- top_share(rd("atlas_lithium_exporters.csv"), "countryId") |>
  mutate(panel = "World exports, by exporter")
li_dst <- top_share(rd("atlas_lithium_chile_destinations.csv"), "partnerCountryId") |>
  mutate(panel = "Chile's exports, by destination")
li_chl_total <- sum(rd("atlas_lithium_chile_destinations.csv")$exportValue)

li_bar <- function(df, highlight) {
  ggplot(df, aes(share, name)) +
    geom_col(aes(fill = name == highlight), width = 0.7) +
    geom_text(aes(label = label_percent(accuracy = 1)(share)), hjust = -0.15,
              size = 4, family = euf_family, color = euf$ink) +
    scale_fill_manual(values = c(`TRUE` = euf$blue, `FALSE` = "#9FB3C2"), guide = "none") +
    scale_x_continuous(labels = label_percent(), breaks = c(0, 0.25, 0.5, 0.75),
                       expand = expansion(mult = c(0, 0.22))) +
    labs(title = unique(df$panel), x = NULL, y = NULL) +
    theme_euf(base_size = 13) +
    theme(panel.grid.major.y = element_blank())
}
p_li <- (li_bar(li_exp, "Chile") | li_bar(li_dst, "China")) +
  plot_annotation(
    title = paste0("Lithium carbonate (HS92 283691), share of export value, ", ATLAS_YEAR),
    caption = paste0("Chile's exports: US$ ", round(li_chl_total / 1e9, 1), " bn.\n",
                     "Source: Harvard Growth Lab, Atlas of Economic Complexity."),
    theme = theme_euf_main(title_size = 15))
save_l05(p_li, "fig_L06a_lithium_trade", width = 7.6, height = 3.6)

# ============================================================================
# Numbers quoted in the slide text
# ============================================================================
message("\nNumbers quoted on the slides (type these into the deck):")
message(sprintf("  slide 14  GDP per capita %d is %.1f times 1960 (South Korea)",
                GDP_LAST, gdp_mult))
message(sprintf("  slide 14  machinery & vehicles: %.1f%% of goods exports in %d, %.1f%% in %d",
                100 * mach_first, KOR_FIRST, 100 * mach_last, KOR_LAST))
message(sprintf("  slide 20  linear trend %d-%d: %.2f%% of the mean index per year",
                min(gy$year), GY_LAST, trend_pct))
message(sprintf("  L06a      Chile: %.0f%% of world lithium-carbonate exports; %.0f%% of them to China (%d)",
                100 * li_exp$share[li_exp$name == "Chile"],
                100 * li_dst$share[li_dst$name == "China"], ATLAS_YEAR))
message("\nDone. Figures in ", FIG_DIR, "/ and ", SLIDE_DIR, "/")
