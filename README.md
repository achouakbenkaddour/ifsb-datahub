# IFSB-DataHub

[![DOI](https://zenodo.org/badge/1331372931.svg)](https://doi.org/10.5281/zenodo.21895282)

A reusable, reproducible pipeline that turns the Islamic Financial Services Board's
**Prudential and Structural Islamic Financial Indicators (PSIFIs)** into a harmonised
analysis panel — covering the banking, takāful, Islamic capital markets and digital
financial services segments.

The PSIFIs database is close to unexploited in the insurance and banking literature.
It is usable, but **not as downloaded**: units are not harmonised across jurisdictions,
most countries report contributions cumulatively within the calendar year, and the
published ratios carry the same within-year gradient at source. This pipeline documents
and corrects those conventions, and logs every judgement made along the way.

Extraction date of the reference release: **2026-07-19**. The portal is revised, so the
extraction date should always be reported alongside any result.

## What this repository contains

```
scripts/     R pipeline, run in order 00 -> 06
docs/        variable dictionary (auto-generated) + decisions log + data sources
clean/       published derived panels (see "What is and is not published" below)
figures/     country x quarter coverage maps by segment
raw/         NOT tracked — see docs/DATA_SOURCES.md to rebuild it
```

## Reproducing the panel

```r
Rscript scripts/00_setup.R
Rscript scripts/01_import_psifis.R
Rscript scripts/02_import_turkey_windows.R
Rscript scripts/03_build_master.R
Rscript scripts/04_coverage_report.R
Rscript scripts/05_import_wui.R
Rscript scripts/06_extract_takaful_panel.R
```

`06_extract_takaful_panel.R` is part of this repository rather than of any single paper:
it applies the reporting-mode identification and within-year differencing described
below, and produces `clean/panel_takaful_uncert.rds` — the corrected takaful panel of
120 country-quarters covering all seven reporting jurisdictions (ARE, BHR, BRN, JOR,
MYS, NGA, SAU), merged with country-level and global uncertainty series. Anyone using
the takaful segment for any question needs it. Paper-specific sample restrictions,
dummies and transformations are applied downstream, in the analysis repositories that
consume this panel.

Required packages: `readxl`, `dplyr`, `tidyr`, `stringr`, `purrr`, `readr`, `openxlsx`.

### What is and is not published

Published in `clean/`: the corrected takaful analysis panel (120 country-quarters) and
the variable dictionary. These are substantively transformed products — reporting modes
identified, within-year differencing applied, variables harmonised and documented.

Not published: the full multi-segment master table. It is a near-complete reformatting
of the source database rather than a derived product, it falls under the same
redistribution constraints as the raw files, and it is regenerable by running the
pipeline. Run `03_build_master.R` to rebuild it locally.

Raw files are not distributed here. `docs/DATA_SOURCES.md` gives the exact download
path for each file, the expected file name, and a checksum so you can verify that your
extract matches the one used for the reference release.

## Three reporting conventions this pipeline handles

1. **Units are not harmonised, and the portal's own conversion fails.** Multipliers
   differ by jurisdiction and the supplied US-dollar column is computed inconsistently.
   The pipeline works in local-currency logs with country fixed effects, so the unit
   problem is differenced away rather than papered over.
2. **Year-to-date cumulation.** Five of seven takāful jurisdictions report contributions
   cumulatively within the calendar year; two report quarterly flows, and nothing in the
   field labels distinguishes them. Raw fourth-quarter figures overstate the true flow by
   a factor of about four on average. The pipeline identifies the reporting mode country
   by country and applies within-year first differences.
3. **Ratios carry a within-year gradient at source.** Published retention and expense
   ratios are taken exactly as disseminated and are never reconstructed. Values above
   100 percent are retained rather than winsorised: they carry information about the
   cession calendar, and removing them would delete first quarters selectively.

Missingness is structural rather than random — it follows jurisdictions and variables,
so listwise deletion removes countries rather than observations. Control sets should be
chosen deliberately, and the retained jurisdictions reported for each specification.

No values are imputed anywhere in the pipeline.

## Extracting a panel for a specific paper

See the commented block at the end of `scripts/03_build_master.R` — for example, gross
takāful contributions for seven jurisdictions, 2019Q1–2022Q4.

## Planned extensions

World Uncertainty Index (quarterly), Swiss Re sigma (annual, total-insurance
denominator), and World Bank WDI / WGI / IMF FAS series through the existing download
scripts.

## Citing this repository

If you use this pipeline or the harmonised panel, please cite both the software and the
accompanying data note.

> Benkaddour, A. (2026). *IFSB-DataHub: a reproducible pipeline for the IFSB Prudential
> and Structural Islamic Financial Indicators* (v1.0.0). Zenodo.
> https://doi.org/10.5281/zenodo.21895283

The concept DOI **10.5281/zenodo.21895282** always resolves to the most recent
version; the version DOI **10.5281/zenodo.21895283** pins release v1.0.0
specifically. Cite the version DOI when reproducibility matters, the concept DOI when
referring to the project as a whole. See `CITATION.cff` for the machine-readable form.

## Licence

Code is released under the MIT Licence. Documentation and derived data files are
released under CC BY 4.0. Raw PSIFIs files remain the property of the Islamic Financial
Services Board and are not redistributed here.
