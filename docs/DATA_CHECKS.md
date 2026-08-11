# Verification checks on `clean/panel_takaful_uncert`

Checks run on the released panel (extraction of 2026-07-19, 120 country-quarters,
seven jurisdictions). Every figure below is reproducible from the published CSV.

## 1. Reporting-mode detection

`06_extract_takaful_panel.R` classifies a jurisdiction as year-to-date when at least
60 percent of its calendar years show a strictly increasing within-year sequence with
three or more observed quarters. Applied to the panel, the classification is
unambiguous — there are no borderline cases and the result is insensitive to the
threshold:

| Jurisdiction | Share of monotone years | Mode |
|---|---|---|
| Bahrain | 1.00 | Year-to-date |
| Brunei | 1.00 | Year-to-date |
| Jordan | 1.00 | Year-to-date |
| Malaysia | 1.00 | Year-to-date |
| Nigeria | 1.00 | Year-to-date |
| United Arab Emirates | 0.00 | Quarterly flow |
| Saudi Arabia | 0.00 | Quarterly flow |

The classification is identical for gross and net contributions in both branches
(`gwc_gen`, `gwc_fam`, `nwc_gen`, `nwc_fam`).

## 2. De-cumulation edge cases

Within-year differencing takes the first quarter as reported and differences
thereafter. Two failure modes were checked explicitly:

- **First quarter missing while a later quarter is observed**, among year-to-date
  reporters: **0 cases**. Such a case would cause a cumulative figure to be recorded as
  a quarterly flow.
- **Interior gaps** (an unobserved quarter between two observed ones), among
  year-to-date reporters: **0 cases**. A gap would cause two non-adjacent quarters to be
  differenced as if consecutive.
- **Non-positive flow values** after differencing, across all four contribution series:
  **0 cases**. A negative flow would indicate a misclassified reporting mode.

## 3. Ratio anomalies

Retention above 100 percent, both branches, all jurisdictions:

| Series | Jurisdiction | Period | Quarter | Value |
|---|---|---|---|---|
| General | Nigeria | 2019Q1 | Q1 | 104.3 |
| General | Nigeria | 2021Q1 | Q1 | 108.6 |
| General | Nigeria | 2022Q1 | Q1 | 101.4 |
| Family | Nigeria | 2019Q1 | Q1 | 113.5 |
| Family | Nigeria | 2020Q1 | Q1 | 113.0 |
| Family | Nigeria | 2021Q1 | Q1 | 105.6 |
| Family | Nigeria | 2022Q1 | Q1 | 110.0 |
| Family | Brunei | 2021Q2 | **Q2** | 127.0 |

Nigeria's general branch in 2020Q1 is 99.4 — just below the threshold.

All above-100 values are retained rather than winsorised. Seven of the eight are first
quarters, consistent with a cession-calendar interpretation. The eighth, Brunei's family
branch in 2021Q2, is not a first quarter and therefore cannot be a calendar artefact; it
points to the accounting mechanism, where net written contributions genuinely exceed
gross because inward retakāful acceptances enter the net figure or cessions are booked
later than the business to which they relate.

## 4. Within-year gradient in published ratios

General-branch retention, mean by quarter:

| Group | Q1 | Q2 | Q3 | Q4 |
|---|---|---|---|---|
| Nigeria | 103.4 | 80.7 | 74.3 | 66.3 |
| Year-to-date reporters, pooled | 75.0 | 71.0 | 70.5 | 67.3 |
| Quarterly-flow reporters | 67.7 | 63.4 | 65.2 | 67.2 |

The year-to-date group declines monotonically across the year. The flow reporters show
no gradient, ending the year essentially where they began.

## 5. Between-country variance in retention

| Branch | Share of total variance lying between jurisdictions |
|---|---|
| General | 80.0 % |
| Family | 71.3 % |

Jurisdiction means, general branch: Jordan 51.6, United Arab Emirates 51.8, Bahrain
64.8, Brunei 77.5, Malaysia 78.0, Nigeria 81.2, Saudi Arabia 83.4.

## 6. Panel dimensions

120 country-quarters. United Arab Emirates and Brunei 2019Q1–2023Q4 (20 quarters each);
Bahrain, Jordan, Malaysia, Nigeria and Saudi Arabia 2019Q1–2022Q4 (16 each).

The `specA` flag marks the five jurisdictions with country-level uncertainty data
(United Arab Emirates, Jordan, Malaysia, Nigeria, Saudi Arabia): 84 country-quarters,
all of them complete on both gross general contributions and the three-quarter moving
average of the uncertainty index.

No values are imputed anywhere in the pipeline.
