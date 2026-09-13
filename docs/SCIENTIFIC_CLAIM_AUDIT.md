# Scientific claim audit

This note records the final claim-by-claim checks used to align the manuscript with the canonical release. It is not a substitute for the source workbook or the executable verifier.

## Verified numerical claims

- Reference panel: 120 unique country-quarters, seven jurisdictions, fixed analytical window 2019Q1–2023Q4.
- Reporting-mode partition: BHR, BRN, JOR, MYS and NGA are classified as year-to-date; ARE and SAU as quarterly flow. A jurisdiction-year is eligible only with at least three non-missing consecutive quarters and is cumulative only when every successive observed value is strictly larger than its predecessor; the jurisdiction-level YTD share is the fraction of eligible years satisfying that rule, with a 0.60 threshold. Repeating the classifier on `gwc_gen`, `gwc_fam`, `nwc_gen`, and `nwc_fam` gives the same partition, with YTD shares exactly 1 or 0 in this source vintage.
- General-branch raw/de-cumulated distortion among YTD jurisdictions: mean Q2 ratio = 3.20621948; mean Q4 ratio = 3.93872398; maximum = 19.21406940 at JOR 2022Q2.
- De-cumulation produces no non-positive observations in any of the four corrected gross/net, general/family contribution-flow series.
- TP07 provenance: the same 120 jurisdiction-quarters are complete in both branches; maximum absolute discrepancy between the published ratio and its own published components is about 5.00e-7 percentage points (general) and 4.97e-7 (family). For YTD reporters TP07 is treated as the published YTD source ratio; it is not itself differenced, and a quarter-specific retention measure would have to be constructed separately from appropriately de-cumulated components.
- Published TP07 above 100 percent: three general-branch observations, all Q1; five family-branch observations, four Q1 and Brunei 2021Q2 (126.97 percent).
- Among the five YTD-pattern jurisdictions, pooled general-branch retention means by quarter are 74.97, 71.01, 70.54 and 67.34 percent; family-branch means are 84.33, 80.27, 78.08 and 77.17 percent. The pattern is not universal at country-year level: 11 of 21 general-branch slopes and 17 of 21 family-branch slopes are negative.
- General-branch jurisdiction means range from 51.6104 percent (JOR) to 83.4233 percent (SAU).
- Between-jurisdiction variance share (weighted one-way ANOVA sum-of-squares ratio): 79.9803 percent (general) and 71.2592 percent (family). Leave-one-jurisdiction-out ranges are 72.1847 percent when ARE is omitted to 92.8220 percent when NGA is omitted (general), and 64.7736 percent when JOR is omitted to 78.8169 percent when ARE is omitted (family).
- Branch differences are heterogeneous: mean family minus general retention is approximately +13.21 pp (ARE), -0.43 (BHR), +16.58 (BRN), +0.86 (JOR), +13.15 (MYS), +12.94 (NGA), and -16.39 (SAU).

## Claims deliberately softened

- The manuscript no longer claims that the IFSB source is the first or only quarterly cross-country takāful source.
- The within-year retention gradient is described as a pooled source pattern, not a universal calendar rule.
- Values above 100 percent are retained as source observations; no unique accounting mechanism is asserted.
- The variance decomposition is interpreted as descriptive cross-jurisdictional heterogeneity and persistence, not as evidence of a causal regulatory or institutional mechanism.
- The de-cumulated contribution series is described as an inferred quarterly flow, not as an externally observed “true” flow.
- Literature-motivation language was softened to avoid unsupported claims about why the entire takāful literature takes its present form.

## Source-vintage and reproducibility status

The canonical release was rebuilt from the IFSB Islamic-insurance workbook downloaded on 19 July 2026. On 12 September 2026 the strengthened verifier completed on the author's Windows machine under R 4.4.1 and returned `ALL STRUCTURAL CHECKS PASSED`. The raw IFSB workbook is intentionally not redistributed.

## Figure-linked claims added before journal-specific adaptation

- Figure 1 visualises the classifier evidence from raw published gross general contributions indexed within jurisdiction-year at Q1=100. The diagnostic distinction is cumulative ramp versus non-cumulative quarterly variation; quarterly-flow reporters are not assumed to be flat.
- Figure 2 reports raw/de-cumulated gross-general ratios among YTD jurisdictions: Q2 mean 3.2062, Q3 mean 3.5747, Q4 mean 3.9387; maximum 19.2141 at JOR 2022Q2.
- Figure 3 displays missingness over the fixed 2019Q1-2023Q4 window. Panel A contains gross contributions, net contributions, retention and expense ratio; Panel B contains investment income, penetration, density and operator count; all seven jurisdictions are shown in each panel. The paired family-branch variables have the same missingness pattern as the general-branch counterparts over the reference window.
- Figure 4 displays published TP07 quarter profiles for the YTD group, quarterly-flow group and Nigeria separately. Nigeria is included in the pooled YTD line and also plotted separately. It is descriptive and does not assert a universal within-year decline.
