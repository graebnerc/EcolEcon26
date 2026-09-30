fanning2022_trends.csv.gz — "The social shortfall and ecological overshoot of nations"
===================================================================================

WHAT IT IS
----------
The country-level supplementary data of

  Fanning, A.L., O'Neill, D.W., Hickel, J. and Roux, N. (2022).
  The social shortfall and ecological overshoot of nations.
  Nature Sustainability 5(1), 26-36. doi:10.1038/s41893-021-00799-z

148 countries, 6 biophysical and 11 social indicators, annually 1992-2015.
This is the most recent data of its kind that exists at the level of
individual countries — see "WHY NOT SOMETHING NEWER" below.

Both blocks are NORMALISED, which is what makes the file usable directly:

  biophysical   value = resource use / the downscaled boundary for that year
                -> value > 1 means the boundary is TRANSGRESSED
  social        value = outcome / the sufficiency threshold for that year
                -> value > 1 means the threshold is ACHIEVED

Note that the denominator is re-computed per year, so a value moving over time
reflects both the country and a shifting per-capita boundary.

An empty `value` is missing data. Social Support is missing for every country
in the early years; that is not a defect of this copy, and the figure's
selection rule below is built around it.


WHY THIS ONE IS NOT DOWNLOADED BY SCRIPT
----------------------------------------
goodlife.leeds.ac.uk answers scripted requests with HTTP 403, so
analysis/01_download.R cannot fetch it. It is also a closed series behind a
2022 paper, not a living dataset — there is nothing to refresh between terms.
Hence data-manual/, like mfa4_export.csv.


WHERE TO GET IT
---------------
Page:   https://goodlife.leeds.ac.uk/download-data/
File:   https://goodlife.leeds.ac.uk/wp-content/uploads/sites/20/2021/11/SocialShortfallAndEcologicalOvershoot_SupplementaryData.xlsx

Download the .xlsx in a browser. It has nine sheets; this CSV is the two
HISTORICAL ones (Biophysical_Historical, Social_Historical) stacked into long
form:

    country,iso3c,year,domain,indicator,value

gzipped, because 2.7 MB of CSV compress to 0.26 MB and readr reads .gz
transparently.

The six BAU sheets are deliberately NOT included. They are business-as-usual
projections for 2016-2050, not observations, and have no place on a slide that
presents itself as data.

Indicator names are left exactly as the workbook spells them. Nothing else was
changed — no renaming, no filtering, no interpolation.


WHY NOT SOMETHING NEWER
-----------------------
There is newer work, and it does not help here:

  Fanning, A.L. and Raworth, K. (2025). Doughnut of social and planetary
  boundaries monitors a world out of balance. Nature.
  doi:10.1038/s41586-025-09385-1

"Doughnut 3.0" runs to 2021/22 and uses 35 indicators rather than 17. But it
publishes results only for the globe and for three income-based country
clusters (poorest 40%, middle 40%, richest 20%) — explicitly not for named
countries. A per-country scatter cannot be built from it.

The predecessor, O'Neill, Fanning, Lamb and Steinberger (2018), "A good life
for all within planetary boundaries", Nature Sustainability 1, 88-95, is a
single snapshot for 2011 with 7 biophysical indicators and 151 countries. It
is what fig_16 used before, and it is one download from the same page if you
ever want to go back to it. The country doughnuts on the preceding slide of
the deck are from that 2018 vintage.


HOW THE FIGURE USES IT
----------------------
analysis/02_figures.R, fig_16_safe_and_just, reproduces the paper's Fig. 1
(without the country paths). The selection rule is the one in that figure's
caption:

    "Only countries with data for all six biophysical indicators and at least
     9 of the 10 social indicators are shown (N = 91)."

Read literally, and it reproduces exactly: completeness is required in EVERY
year 1992-2015, not just at the end, and the "10" excludes Social Support,
which has no early observations. The script asserts N == 91, so a corrupted
file or a changed rule fails the build instead of producing a plausible-looking
wrong figure.

Positions are the 2011-2015 average, as in the paper ("performance at the end
of the analysis period"). Thresholds achieved are counted over all 11 social
indicators — the paper does the same when it reports "4 out of 11 in 2015";
only the *selection* uses 10.

Region and population for the point colour and size are joined by iso3c from
the OWID data that 01_download.R already fetches.


LICENCE
-------
Supplementary material to a Nature Sustainability article, published by the
authors for reuse; the Zenodo record of the paper is CC BY 4.0. Cite the paper
as above. Project website content is CC BY (University of Leeds).
