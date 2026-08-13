mfa4_export.csv — UN IRP Global Material Flows Database
=======================================================

WHY THIS ONE FILE IS NOT DOWNLOADED BY SCRIPT
---------------------------------------------
Everything else under analysis/ is fetched by analysis/01_download.R from a
public API. The IRP material flows database has no such API: it is served
through an interactive portal that builds the export in the browser. So this
file has to be refreshed by hand, roughly once a year.

It is worth the manual step. The scriptable alternative (UN SDG Indicators API,
series EN_MAT_DOMCMPT) only gives domestic material *consumption* from 2000
onwards. This file gives domestic *extraction* — which is what the slide is
actually about — from 1970, and with the IRP's own world regions.


WHERE TO GET IT
---------------
Portal:     https://www.materialflows.net/   (Visualisation Centre)
Background: https://www.resourcepanel.org/global-material-flows-database

Export the full table from the visualisation centre; it downloads as
"mfa4_export.csv". Drop it in this folder under exactly that name, replacing
the old one, and re-run the figures.

NOTE ON THE CLICK PATH: the portal's interface changes between releases, so no
step-by-step is given here on purpose — it would go stale and mislead. What
matters is the *contents* below. Export widely (all flows, all materials, all
countries, all years) rather than narrowly; the script filters what it needs and
a too-wide export costs nothing but disk.


WHAT THE FILE MUST CONTAIN
--------------------------
analysis/02_figures.R checks this on every run and stops with a clear message if
the export does not match, so a wrong download fails loudly instead of silently
producing a wrong figure.

  Columns:      Country, Category, Flow name, Flow code, Flow unit,
                then one column per year, named "1970", "1971", ...
  Flow code:    must include "DE"  (Domestic Extraction)
  Flow unit:    "t"  (tonnes)
  Categories:   must include all four of
                  Biomass, Fossil fuels, Metal ores, Non-metallic minerals
  Country:      must include "World" and the seven IRP regions:
                  Africa
                  Asia + Pacific
                  EECCA              (Eastern Europe, Caucasus and Central Asia)
                  Europe
                  Latin America + Caribbean
                  North America
                  West Asia
                The seven regions sum to World — the script verifies this to
                within 1%, which is the check that catches a partial export.


CURRENT FILE
------------
Downloaded:   2026-08 (carried over from the "Wohlstand ohne Wachstum" deck)
Covers:       1970-2024, 249 countries and regions
Used by:      analysis/02_figures.R -> fig_11_material_use
              (the old EN_MAT_DOMCMPT path is kept as an automatic fallback,
               so the figures still build if this file is ever missing)
