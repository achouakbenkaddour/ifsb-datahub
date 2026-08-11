# Data sources and how to rebuild `raw/`

Raw source files are not distributed in this repository. They remain the property of
their publishers and are freely obtainable from the addresses below. This file records
exactly what to download, where each file belongs, and how to verify that your extract
matches the one used for the reference release.

## 1. IFSB PSIFIs

**Source:** Islamic Financial Services Board, Prudential and Structural Islamic
Financial Indicators — <https://data.ifsb.org>
**Access:** free, no registration required for the standard exports.
**Reference extraction date:** 2026-07-19.

Download the following exports and place them in `raw/ifsb/`:

| File | Segment |
|---|---|
| `islamic_banking_data.xlsx` | Banking |
| `islamic_insurance_data.xlsx` | Takāful |
| `islamic_capital_markets_data.xlsx` | Islamic capital markets |
| `detailed_financial_statements.xlsx` | Detailed financial statements |
| `turkey_takaful_windows.xls` | Türkiye takāful windows (annual reporting) |

**Verifying your extract.** The portal is revised without notice, so an extract taken
today will not necessarily match the reference release. Run `scripts/00_setup.R`, which
prints a SHA-256 checksum for every file in `raw/ifsb/`. Compare these against
`docs/checksums_20260719.txt`. If they differ, your extract is a different vintage —
this is expected and not an error, but the extraction date must then be updated in the
decisions log and reported in any resulting paper.

## 2. World Uncertainty Index

**Source:** Ahir, Bloom and Furceri, World Uncertainty Index —
<https://worlduncertaintyindex.com>
**Access:** free.

Place in `raw/wui/`:

| File | Content |
|---|---|
| `WUI_Data.xlsx` | Country-quarter uncertainty index |
| `wui_global_visualizer.xlsx` | Global aggregate series |

Imported by `scripts/05_import_wui.R`.

## 3. Planned additions

Swiss Re sigma (annual, total-insurance denominator), World Bank WDI and WGI, and IMF
Financial Access Survey — to be pulled through download scripts rather than stored as
files.

## Why raw files are not tracked

Two reasons. Redistribution of a publisher's files is a separate permission from access
to them, and this repository does not assume it. And a raw file frozen in a repository
silently ages: readers would take it for the current database when the portal has since
been revised. Documenting the retrieval path and publishing checksums keeps the record
honest and keeps the pipeline re-runnable against any vintage.
