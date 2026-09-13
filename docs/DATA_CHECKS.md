# Verification checks on the distributed canonical takāful panel

These checks refer to `clean/panel_takaful_harmonised.csv` as distributed in this
release. They distinguish **derived-panel checks** from **source-provenance checks**.
The latter require rebuilding from a fresh IFSB download because raw publisher files
are intentionally not redistributed.

## 1. Structure and reporting-mode classification

- 120 unique jurisdiction-quarters; 7 jurisdictions; 0 duplicate `iso3-period` keys.
- YTD pattern: BHR, BRN, JOR, MYS, NGA.
- Quarterly-flow pattern: ARE, SAU.
- Classification is inferred from the data and should be re-verified when the portal is updated.

## 2. De-cumulation edge cases

- First-quarter-missing cases among YTD country-years/series: **0**.
- Interior-gap cases among YTD country-years/series: **0**.
- Non-positive `gwc_gen_flux` values: **0**.
- Non-positive `gwc_fam_flux` values: **0**.
- Non-positive `nwc_gen_flux` values: **0**.
- Non-positive `nwc_fam_flux` values: **0**.
- Mean raw/flow distortion for gross general contributions in Q2: **3.2062×**.
- Mean raw/flow distortion for gross general contributions in Q4: **3.9387×**.
- Largest observed raw/flow distortion across YTD gross-general observations: **19.2141×**.

## 3. Published retention above 100%

- General: NGA 2019Q1 = **104.281%**.
- General: NGA 2021Q1 = **108.637%**.
- General: NGA 2022Q1 = **101.404%**.
- Family: BRN 2021Q2 = **126.973%**.
- Family: NGA 2019Q1 = **113.479%**.
- Family: NGA 2020Q1 = **112.962%**.
- Family: NGA 2021Q1 = **105.583%**.
- Family: NGA 2022Q1 = **110.018%**.

These observations are retained as published. The distributed panel establishes that
they are source values; it does **not** by itself identify whether inward retakāful,
cession timing, or another accounting convention is responsible.

## 4. Within-year gradient in published general-branch retention

| Group | Q1 | Q2 | Q3 | Q4 |
|---|---:|---:|---:|---:|
| Nigeria | 103.4 | 80.7 | 74.3 | 66.3 |
| YTD reporters | 75.0 | 71.0 | 70.5 | 67.3 |
| Quarterly-flow reporters | 67.7 | 63.4 | 65.2 | 67.2 |

## 5. Between-jurisdiction variance share

- General retention: **79.98%**.
- Family retention: **71.26%**.

General-branch jurisdiction means:

- Jordan: **51.6%**
- United Arab Emirates: **51.8%**
- Bahrain: **64.8%**
- Brunei Darussalam: **77.5%**
- Malaysia: **78.0%**
- Nigeria: **81.2%**
- Saudi Arabia: **83.4%**

## 6. Missingness audit

| ISO3 | penetration missing | density missing | expense-ratio missing | investment-income missing | operator-count missing |
|---|---:|---:|---:|---:|---:|
| ARE | 4 | 0 | 0 | 0 | 0 |
| BHR | 16 | 16 | 16 | 16 | 0 |
| BRN | 0 | 0 | 0 | 0 | 0 |
| JOR | 0 | 0 | 0 | 0 | 0 |
| MYS | 0 | 0 | 0 | 0 | 0 |
| NGA | 16 | 16 | 0 | 0 | 6 |
| SAU | 0 | 0 | 0 | 0 | 0 |

The audit shows that missingness is predominantly jurisdiction/variable-specific but can
also occur in contiguous time blocks (for example UAE penetration in 2023). It should
therefore be described as **structured**, not literally random scattering.

## 7. Source-provenance checks after rebuild

`07_verify_release.R` performs two checks that cannot honestly be reconstructed from the
legacy derived CSV alone:

1. TP07 is compared with its own published `TP07*_010` and `TP07*_020` components.
2. The portal USD value is compared with the value implied by the preserved source unit
   multiplier and USD exchange-rate field.

The ratio check is a stopping condition. The FX comparison is a diagnostic because the
point of the data note is precisely that the portal conversion should not be trusted
uncritically.

No values are imputed.

## Final release clarifications (2026-09-13)

- An eligible jurisdiction-year requires at least three non-missing consecutive quarters. It is marked cumulative only if every successive observed contribution value is strictly increasing; jurisdiction-level YTD share is the fraction of eligible years meeting that rule, with a 0.60 threshold.
- The paired general/family variables used in the paper have identical missingness masks over the fixed reference window.
- TP07 provenance checks validate the published source ratio against its published components. For YTD reporters, TP07 is interpreted as a published YTD ratio rather than a quarter-specific retention measure.
