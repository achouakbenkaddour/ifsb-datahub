# Verification report for the distributed canonical panel

This report was recomputed from `clean/panel_takaful_harmonised.csv` as distributed in this release.
It verifies the claims that can be checked without redistributing the raw IFSB files.

## Structural checks

- Rows: **120**
- Jurisdictions: **7**
- Duplicate `iso3-period` keys: **0**
- YTD reporters: **BHR, BRN, JOR, MYS, NGA**
- Quarterly-flow reporters: **ARE, SAU**

## YTD distortion, general gross contributions

- Mean raw/flow ratio in Q2: **3.2062**
- Mean raw/flow ratio in Q4: **3.9387**
- Largest raw/flow ratio observed in those checks: **19.2141**

## Retention variance decomposition

- General branch, between-jurisdiction share: **79.98%**
- Family branch, between-jurisdiction share: **71.26%**

## Retention above 100%

- General: NGA 2019Q1 = **104.281%**
- General: NGA 2021Q1 = **108.637%**
- General: NGA 2022Q1 = **101.404%**
- Family: BRN 2021Q2 = **126.973%**
- Family: NGA 2019Q1 = **113.479%**
- Family: NGA 2020Q1 = **112.962%**
- Family: NGA 2021Q1 = **105.583%**
- Family: NGA 2022Q1 = **110.018%**

## Provenance checks requiring a fresh raw-source rebuild

Two claims deliberately are **not** asserted from the distributed derived CSV alone:

1. Whether the portal USD column equals the conversion implied by its own unit multiplier and exchange rate.
2. Whether TP07 equals its own published TP07 numerator/denominator components.

The revised importer now preserves the required FX fields and the revised extractor imports the TP07 component rows. Running `07_verify_release.R` after rebuilding from the downloaded PSIFIs files checks both claims and stops on a ratio-provenance failure. This avoids the previous error of attempting to infer TP07 provenance from TS05/TS03.

## Source-workbook audit added 2026-09-12

The original `ISLAMIC_INSURANCE_DATA_202607191918.xlsx` workbook was supplied and
independently transformed using the same documented selection, widening, YTD-detection
and de-cumulation logic. The rebuilt 2019Q1–2023Q4 panel contains exactly 120 rows and
matches every legacy canonical-panel field exactly after CSV serialization.

For TP07 provenance, all 120 reference-window observations are complete in each branch.
The maximum absolute discrepancy between the published ratio and 100 × its own published
numerator/denominator is below 5e-7 percentage points for both General and Family.

For checkable TS03a currency/scale observations, the median ratio of the portal USD value
to the source-based formula is 1.000 for ARE, BRN, JOR, MYS (2019 checkable rows), NGA and
SAU. Bahrain has no usable FX value for this check. In this source vintage, scale code `G`
behaves as an unscaled/actual-value code (multiplier 1), not a billion multiplier.

## End-to-end R integration test completed 2026-09-12

The final runtime test was subsequently completed on the author's Windows/RStudio
environment using R 4.4.1 and the original IFSB insurance workbook placed manually in
`raw/ifsb/`. The canonical chain was run in order:

`00_setup.R -> 01_import_psifis.R -> 03_build_master.R -> 06_extract_takaful_panel.R -> 07_verify_release.R`.

Observed checkpoints were:

- `00_setup.R`: OK — 27 countries in ISO3 map.
- `01_import_psifis.R`: 27,182 takaful long rows; source window 2019Q1–2023Q4; output written successfully.
- `03_build_master.R`: 27,182 master rows; 211 indicators documented.
- `06_extract_takaful_panel.R`: ARE and SAU classified as quarterly flow; BHR, BRN, JOR, MYS and NGA classified as YTD; canonical output written successfully.
- `07_verify_release.R`: **ALL STRUCTURAL CHECKS PASSED**.
- TP07 provenance: n = 120 in each branch; maximum absolute discrepancy = 5.00e-7 percentage points (General) and 4.97e-7 (Family).

Finally, the newly rebuilt canonical panel was compared with the previously deposited
`panel_takaful_uncert.csv`. After sorting by `iso3-period`, the keys were identical. All
26 fields common to the two files compared equal using R's
`all.equal(..., tolerance = 1e-6, check.attributes = FALSE)`, which returned `TRUE`.

Accordingly, the package has now passed both source-workbook audit and an independent
end-to-end R runtime/integration test. The raw IFSB workbook remains intentionally
excluded from the release because it is publisher-supplied source material; users place
their own downloaded copy in `raw/ifsb/` before rebuilding.

## Additional robustness checks

The release verifier repeats the reporting-mode classifier independently on `gwc_gen`, `gwc_fam`, `nwc_gen`, and `nwc_fam`. For a given series, a jurisdiction-year is eligible only when at least three non-missing observations occur in consecutive quarters; an eligible year is cumulative only when every successive observed value is strictly greater than its predecessor. The jurisdiction-level YTD share is the fraction of eligible years meeting that monotonicity rule, and the released threshold is 0.60. In the verified source vintage, all four series return the same classification: BHR, BRN, JOR, MYS, and NGA have a YTD share of 1.00; ARE and SAU have a share of 0.00. Hence the final partition is invariant to any threshold in (0, 1].

The verifier also writes a leave-one-jurisdiction-out sensitivity analysis for
the between-jurisdiction share of retention variance and checks the canonical
panel against the deposited companion derivative on all common fields with a
tolerance of 1e-6.

These additions were independently recomputed from the released canonical CSV
when preparing the strengthened manuscript and were subsequently executed successfully
by the author under R 4.4.1, as recorded below.
## Final author-machine runtime verification (12 September 2026)

The strengthened release was rerun on the author's Windows machine using R 4.4.1. The dependency chain was rebuilt from the documented IFSB insurance-workbook workflow through `03_build_master.R`, `06_extract_takaful_panel.R`, and the strengthened `07_verify_release.R`; the final console returned `07_verify_release.R : ALL STRUCTURAL CHECKS PASSED`. The TP07 checks covered the same 120 jurisdiction-quarters in both the general and family branches, with maximum absolute discrepancies of 0.000000500 and 0.000000497 percentage points, respectively. For YTD reporters this verifies the provenance of the published source ratio; it does not turn TP07 into a quarter-specific retention measure.

The strengthened verifier additionally confirmed that the reporting-mode partition is identical across gross and net contribution series in both general and family branches, that all four de-cumulated contribution-flow series are positive where observed, and that the canonical panel matches the deposited derivative on shared fields within tolerance 1e-6. The between-jurisdiction variance share is computed as the weighted one-way ANOVA sum-of-squares ratio. Leave-one-jurisdiction-out values range from 72.1847% (omit ARE) to 92.8220% (omit NGA) for general retention and from 64.7736% (omit JOR) to 78.8169% (omit ARE) for family retention. The generated diagnostic tables are included as `docs/reporting_mode_robustness.csv` and `docs/retention_variance_robustness.csv`.


## Figure reproducibility extension (updated 2026-09-13)

`scripts/08_make_figures.R` regenerates the four manuscript figures directly from the canonical 120-row panel. The order is (1) within-year reporting patterns, (2) raw/YTD distortion, (3) structured missingness, and (4) retention profiles by reporting mode. The script writes 300-dpi PNG files, uses non-colour encodings, and leaves figure captions and the fixed 19 July 2026 source-extraction note to the manuscript. After final release alignment, Figure 3 is grouped by variables exactly as in the manuscript: Panel A = gross contributions, net contributions, retention, expense ratio; Panel B = investment income, penetration, density, operator count; all seven jurisdictions appear in both panels. The numerical inputs remain those validated by `07_verify_release.R`.

The final `08_make_figures.R` workflow was rerun successfully on the author's Windows/RStudio installation under R 4.4.1 on 13 September 2026. All four 300-dpi manuscript figures were regenerated successfully from the canonical panel, including the final Figure 1 margin/axis-label adjustment and the Figure 3 variable-panel regrouping. The output filenames are `figure1_reporting_pattern.png`, `figure2_ytd_distortion.png`, `figure3_missingness_map.png`, and `figure4_retention_profiles.png`.
