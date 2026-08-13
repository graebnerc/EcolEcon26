# ============================================================================
#  euf_style.R — shared EUF look for all course figures
#
#  Sourced by 02_figures.R. Provides:
#    · euf          — the EUF colour palette (matches assets/styles/custom.scss)
#    · region_pal   — validated 6-hue categorical palette for OWID world regions
#    · theme_euf()  — ggplot2 theme
#    · save_euf()   — writes each figure as PDF (vector) and PNG
#
#  On the categorical palette: the hues below were checked with the
#  colourblind-separation validator (lightness band, chroma floor, CVD
#  separation, normal-vision floor, contrast). The worst adjacent pair sits in
#  the 6-8 dE band under protanopia, which is only acceptable *with* a secondary
#  encoding — so every figure that uses these hues also carries either a direct
#  label or a facet strip naming the series. Do not reuse them without one.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggrepel)
  library(patchwork)
  library(scales)
})

# The EUF slide master is white, so figures are rendered on white by default:
# what you see in the PNG is what Keynote shows. Set to "transparent" if you
# ever need to drop a figure onto a coloured background.
PAPER_BG <- "white"
FORMATS  <- c("pdf") # , "png"
DPI      <- 300

# ---- EUF colours (see assets/styles/custom.scss) ---------------------------
euf <- list(
  blue      = "#00395B",  # Kobaltblau — headings, primary series
  blue_mid  = "#2A72B5",
  lightblue = "#69AACD",
  red       = "#E65032",
  green     = "#5FB46E",
  gray      = "#6F6F6F",
  ink       = "#1A1A1A",
  muted     = "#4A4A4A",
  grid      = "#DFE3E6",
  wash      = "#EAF0F4"
)

# ---- Validated categorical palette for the six OWID world regions ----------
region_pal <- c(
  "Europe"        = "#2A72B5",
  "Africa"        = "#E0542F",
  "Asia"          = "#1F8A5B",
  "North America" = "#C98A00",
  "South America" = "#8A5FBF",
  "Oceania"       = "#00A0A8"
)

# ---- Font --------------------------------------------------------------
# Inter first: it is the face used in the Keynote deck, so the figures match
# the surrounding slides instead of sitting in a different typeface. The rest
# are fallbacks for a machine without it; "" means the device default.
# cairo_pdf embeds the font, so the PDF looks the same on a machine that does
# not have Inter installed.
FONT_CANDIDATES <- c("Inter", "Open Sans", "Source Sans 3", "Helvetica Neue")

euf_family <- ""
if (requireNamespace("systemfonts", quietly = TRUE)) {
  fams <- systemfonts::system_fonts()$family
  for (cand in FONT_CANDIDATES) {
    if (cand %in% fams) { euf_family <- cand; break }
  }
}
message("Font: ", if (nzchar(euf_family)) euf_family else "device default (none of the candidates installed)")

theme_euf <- function(base_size = 14) {
  theme_minimal(base_size = base_size, base_family = euf_family) +
    theme(
      plot.background   = element_rect(fill = PAPER_BG, color = NA),
      panel.background  = element_rect(fill = PAPER_BG, color = NA),
      panel.grid.major  = element_line(color = euf$grid, linewidth = 0.4),
      panel.grid.minor  = element_blank(),
      plot.title        = element_text(color = euf$blue, face = "bold",
                                       size = base_size * 1.18, margin = margin(b = 2)),
      plot.subtitle     = element_text(color = euf$ink, size = base_size * 0.92,
                                       margin = margin(b = 10)),
      plot.caption      = element_text(color = euf$muted, size = base_size * 0.64,
                                       hjust = 0, margin = margin(t = 10)),
      axis.text         = element_text(color = euf$ink),
      axis.title        = element_text(color = euf$ink, face = "bold"),
      axis.title.y      = element_text(margin = margin(r = 6)),
      axis.title.x      = element_text(margin = margin(t = 4)),
      legend.position   = "bottom",
      legend.title      = element_blank(),
      legend.text       = element_text(color = euf$ink, size = base_size * 0.80),
      legend.key.width  = unit(1.2, "cm"),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      strip.text        = element_text(color = euf$blue, face = "bold",
                                       size = base_size * 0.95)
    )
}

# Theme for a figure's own title block. The figures are dropped onto slides at
# a size where theme_euf()'s default title reads small, so the title size is
# raised here - only the size: colour, weight and plot-edge alignment still come
# from theme_euf().
#
# Use this for every top-level figure, and plain theme_euf(base_size = 12) for
# the inner panels of a patchwork, whose smaller headings should stay small.
theme_euf_main <- function(title_size = 24) {
  theme_euf() + theme(plot.title = element_text(size = title_size))
}

save_euf <- function(plot, file, width = 9, height = 5.4) {
  stem <- tools::file_path_sans_ext(file)
  for (fmt in FORMATS) {
    path <- file.path(FIG_DIR, paste0(stem, ".", fmt))
    if (fmt == "pdf") {
      dev <- if (capabilities("cairo")) grDevices::cairo_pdf else grDevices::pdf
      ggsave(path, plot, width = width, height = height, device = dev, bg = PAPER_BG)
    } else {
      dev <- if (requireNamespace("ragg", quietly = TRUE)) ragg::agg_png else "png"
      ggsave(path, plot, width = width, height = height, dpi = DPI,
             device = dev, bg = PAPER_BG)
    }
  }
  message("  ok  ", stem, " (", paste(FORMATS, collapse = ", "), ")")
}

# ---- Shared scales ---------------------------------------------------------
gdp_breaks <- c(1000, 2000, 5000, 10000, 20000, 50000, 100000)
lbl_short  <- scales::label_number(scale_cut = scales::cut_short_scale())
lbl_dollar <- scales::label_dollar(scale_cut = scales::cut_short_scale())

# Keep only real countries: OWID leaves `owid_region` empty for aggregates
# (World, continents, income groups), so requiring it drops them cleanly.
only_countries <- function(df) {
  df |>
    filter(!is.na(owid_region), owid_region %in% names(region_pal), nchar(code) == 3) |>
    mutate(owid_region = factor(owid_region, levels = names(region_pal)))
}
