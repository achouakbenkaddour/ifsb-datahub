# IFSB-DataHub — takāful data-paper replication release

This repository rebuilds the harmonised quarterly takāful panel used in the data paper
from manually downloaded Islamic Financial Services Board (IFSB) PSIFIs workbooks.

**Reference source extraction:** 2026-07-19.  The paper's fixed analytical window is
**2019Q1–2023Q4**.  The window is explicit in `06_extract_takaful_panel.R`, so later
observations present in the same portal export cannot silently enter the released panel.

## Canonical released product

`clean/panel_takaful_harmonised.csv` contains 120 jurisdiction-quarters for ARE, BHR,
BRN, JOR, MYS, NGA and SAU.  It contains published indicators, raw contribution levels,
de-cumulated quarterly flows and the inferred reporting-mode classification.

`clean/panel_takaful_uncert.csv` is a companion-study derivative only; WUI/COVID/specification
variables are not part of the data-paper resource.

## Rebuilding from the original IFSB download

1. The directory `raw/ifsb/` is already present in the release; it contains only the
   placeholder `RAW_FILES_GO_HERE.txt`.
2. Put the original IFSB insurance workbook there **without editing its contents**.
   The script accepts the portal filename such as
   `ISLAMIC_INSURANCE_DATA_202607191918.xlsx`; no renaming is required.
3. From the repository root run:

```r
Rscript scripts/00_setup.R
Rscript scripts/01_import_psifis.R
Rscript scripts/03_build_master.R
Rscript scripts/06_extract_takaful_panel.R
Rscript scripts/07_verify_release.R
Rscript scripts/08_make_figures.R
```

For the canonical data paper, **only the Islamic-insurance PSIFIs workbook is required**.
The banking, capital-markets, detailed-financial-statements, Turkey-windows and WUI files
are optional and are imported/appended only when present or when their optional scripts
are run.

The final command regenerates Figures 1-4 directly from the canonical CSV into `figures/`.
The plots use black/white, line types and markers so interpretation does not depend on colour.

Required R packages: `readxl`, `dplyr`, `tidyr`, `stringr`, `purrr`, `readr`, `openxlsx`, `digest`.

## What is checked

- `00_setup.R`, when run directly, prints SHA-256 hashes for manually supplied raw files.
- `01_import_psifis.R` preserves source currency, scale, exchange rate and portal USD value.
- `06_extract_takaful_panel.R` fixes the paper window at 2019Q1–2023Q4. For each jurisdiction-year and contribution series, a year is eligible only with at least three non-missing consecutive quarters; it is cumulative only if every successive observed value is strictly larger than its predecessor. The jurisdiction-level YTD share is the fraction of eligible years satisfying that rule, with a 0.60 classification threshold.
- De-cumulation never bridges a missing quarter.
- `07_verify_release.R` requires exactly 120 unique rows, seven jurisdictions, the five
  expected YTD-pattern jurisdictions, positive corrected flows, and TP07 equality with
  its own published numerator/denominator components. It also repeats the reporting-mode
  classifier across all four gross/net, general/family contribution series, writes a
  leave-one-jurisdiction-out retention-variance diagnostic, and checks the canonical
  panel against the deposited derivative on shared fields within tolerance 1e-6.
- `08_make_figures.R` regenerates the four manuscript figures from `clean/panel_takaful_harmonised.csv`; the manuscript captions carry the fixed 19 July 2026 source-extraction date, while the PNG files contain plot content only and use non-colour encodings. Outputs are prepared at 300 dpi.
- Unit/FX checks are diagnostics, not silent corrections.  In the 2026-07-19 source
  vintage, scale code `G` behaves as unscaled/actual values; when source currency is
  labelled USD, the portal FX field is not applied by the diagnostic formula.

No values are imputed.

## End-to-end runtime verification

On 2026-09-12 the canonical workflow was run successfully in R 4.4.1 from the original
`ISLAMIC_INSURANCE_DATA_202607191918.xlsx` workbook using the six commands shown above.
The run completed through `08_make_figures.R`. The structural verifier returned:

```text
07_verify_release.R : ALL STRUCTURAL CHECKS PASSED
```

The TP07 provenance check covered all 120 observations in each branch; maximum absolute
differences were 5.00e-7 percentage points (General) and 4.97e-7 (Family). The rebuilt
panel was then compared, on all 26 fields shared with the previously deposited
`panel_takaful_uncert.csv`, after sorting by `iso3-period`; keys were identical and
`all.equal(..., tolerance = 1e-6, check.attributes = FALSE)` returned `TRUE`.

The 300-dpi figure-generation workflow and the Figure 3 / Figure 4 order were first run
on the author's Windows machine under R 4.4.1 on 12 September 2026. `08_make_figures.R`
was then rerun on 13 September 2026 after the Figure 1 margin/axis-label adjustment and
the Figure 3 variable-panel regrouping. Figure 3 is grouped to match the manuscript:
Panel A contains gross contributions, net contributions, retention and the expense
ratio; Panel B contains investment income, penetration, density and operator count, with
all seven jurisdictions shown in each panel. The four PNG files distributed in
`figures/` are the output of that final 13 September run and are the same files
reproduced in the manuscript:
`figure1_reporting_pattern.png`, `figure2_ytd_distortion.png`,
`figure3_missingness_map.png`, and `figure4_retention_profiles.png`.

The canonical data and structural checks are runtime-verified. The raw IFSB workbook is intentionally **not** redistributed; `raw/ifsb/RAW_FILES_GO_HERE.txt` marks where a user should place their source download.

## Optional sources

`02_import_turkey_windows.R` imports the legacy Turkey takaful-windows workbook for annual
robustness work only. `05_import_wui.R` imports WUI only for the companion study. Neither
is required to rebuild the canonical 120-row data-paper panel.

## Licence

Code: MIT. Documentation and derived data: CC BY 4.0. Raw IFSB workbooks remain the
property of their publisher and are not redistributed in this release.
