# Harmonised takāful panel: variable codebook

Canonical review-release file: `clean/panel_takaful_harmonised.csv`.
One row is one jurisdiction-quarter. The reference vintage contains 120 rows for seven
jurisdictions over 2019Q1–2023Q4 with jurisdiction-specific endpoints.

## Identification and provenance

| Variable | Meaning |
|---|---|
| `iso3` | ISO-3 jurisdiction code. |
| `country` | Jurisdiction name. |
| `period` | Calendar quarter in `YYYYQ#` form. |
| `year`, `quarter` | Numeric period components. |
| `reporting_mode` | Algorithmic classification of contribution reporting: `year-to-date` or `quarterly flow`. |
| `ytd_share` | Share of eligible country-years with strictly increasing within-year gross general contributions. Reference vintage: 1.0 for YTD reporters and 0.0 for flow reporters. |
| `source_extraction_date` | IFSB portal extraction date for the reference release. |

When the panel is rebuilt from raw PSIFIs files with the revised pipeline, it also
carries `source_currency`, `source_units`, `usd_exchange_rate`, and
`portal_value_usd_mn` for unit/FX auditing. These fields are intentionally **not
back-filled into the distributed CSV from assumptions** because the raw source files are not
redistributed in this archive.

## Contributions

`gwc_*` and `nwc_*` are the published contribution levels as downloaded. Suffix `gen`
means general takāful and `fam` family takāful. Corresponding `*_flux` variables are the
quarterly-flow versions: unchanged for flow reporters and within-calendar-year first
differences for YTD reporters, with Q1 retained as published.

## Published indicators

- `retention_gen`, `retention_fam`: published risk-retention ratios (TP07); never reconstructed or winsorised.
- `opex_ratio_gen`, `opex_ratio_fam`: published operating-expense ratios.
- `penetr_gen`, `penetr_fam`: penetration indicators.
- `densite_gen`, `densite_fam`: density indicators.
- `equity_assets_gen`, `equity_assets_fam`: equity/assets indicators.
- `invest_income_gen`, `invest_income_fam`: investment-income indicators.
- `operateurs_gen`, `operateurs_fam`: operator counts.

No values are imputed.

## Ratio provenance on rebuild

The revised extraction script also imports the TP07 published numerator/denominator
components (`TP07a_010`, `TP07a_020`, `TP07b_010`, `TP07b_020`) into the regenerated
RDS/CSV. `07_verify_release.R` checks the TP07 identity against **those components**,
not against TS05/TS03.
