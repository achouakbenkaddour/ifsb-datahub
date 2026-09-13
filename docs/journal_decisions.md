# Decision log — IFSB-DataHub

| Date | Decision | Rationale / status |
|---|---|---|
| 2026-07-19 | Reference PSIFIs extraction date fixed at 2026-07-19. | The portal is revised over time; every later rebuild must record its own extraction date and SHA-256 hashes. |
| 2026-07-19 | Harmonisation key: `iso3 × year × quarter`, long/tidy master table. | New sources enter as rows in the master rather than paper-specific columns. |
| 2026-07-19 | Türkiye excluded from the quarterly takāful panel. | The available takāful-windows file is annual/Q4-only and cannot support quarterly analysis. |
| 2026-07-19 | Seven quarterly takāful jurisdictions retained: ARE, BHR, BRN, JOR, MYS, NGA, SAU. | Reference release contains 120 country-quarters because ARE and BRN extend through 2023Q4; the other five end at 2022Q4. |
| 2026-07-19 | Contribution reporting mode inferred from within-year behaviour, not assumed from field labels. | BHR, BRN, JOR, MYS and NGA exhibit the YTD pattern; ARE and SAU exhibit quarterly-flow reporting. Classification is documented as inferred/provisional. |
| 2026-07-19 | YTD contribution levels are converted to quarterly flows by within-calendar-year first differences; Q1 is retained as published. | Revised code refuses to bridge a missing predecessor quarter; such a flow becomes `NA` rather than a fabricated difference. |
| 2026-07-19 | Published TP07/TP09 ratios are not de-cumulated or reconstructed. | Ratio provenance is checked against the ratio's own published components where available. Above-100 TP07 observations are retained as source values. |
| 2026-07-19 | Portal USD-converted levels are treated as unverified. | **Supersedes an earlier companion-study note that proposed USD levels.** The canonical data-paper product retains local-source levels and corrected within-country flows; cross-country level comparisons require externally verified conversion/deflation. |
| 2026-07-19 | Missing values are not imputed. | Coverage gaps are reported explicitly; model specifications must disclose the jurisdictions retained. |
| 2026-09-12 | Canonical data-paper panel separated from companion WUI study panel. | `panel_takaful_harmonised` is the general resource; `panel_takaful_uncert` is a downstream derivative and is not the canonical data-paper product. |
| 2026-09-12 | Pipeline dependency order corrected. | Optional external importers (e.g. WUI) run before `03_build_master.R`; script 06 no longer requires WUI to produce the canonical panel. |
| 2026-09-12 | Source-provenance checks made explicit. | Import preserves FX metadata; TP07 own components are extracted; script 07 performs structural, ratio-provenance and unit-conversion diagnostics. |
| 2026-09-12 | Data Observer figure order fixed as Fig. 1 reporting pattern, Fig. 2 YTD distortion, Fig. 3 structured missingness, Fig. 4 retention profiles. | Order follows first appearance in the restructured JBNST Data Observer manuscript. Filenames and script 08 use this order as the single source of truth. |
| 2026-09-12 | Publication figures standardised to 300 dpi with captions/source notes outside the PNG files. | JBNST/De Gruyter artwork preparation; interpretation remains non-colour-dependent. Figure 3 uses a two-panel layout for legibility. |

| 2026-09-13 | Final release alignment: classifier rule defined explicitly; TP07 treated as published YTD ratio for YTD reporters; variance decomposition formula and LOO endpoints documented; family-branch missingness parity stated; Figure 3 regrouped by variable panels to match the manuscript. | Prevents ambiguity between source ratios and quarter-specific constructs and keeps manuscript, diagnostics, and figure-generation logic aligned. |
