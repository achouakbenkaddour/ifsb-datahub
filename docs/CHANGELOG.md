# Changelog

## v2.0.0 (2026-09-13)

Changes to the pipeline, the released panel and the documentation since v1.0.0:

1. Corrected pipeline dependency order: optional external importers precede the master
   build, so `06_extract_takaful_panel.R` no longer depends on optional sources.
2. Added SHA-256 source-vintage hashing of manually supplied raw files via the `digest`
   package.
3. Preserved the PSIFIs `USD Exchange Rate`, report type, currency and unit fields
   during import instead of discarding them.
4. Separated the canonical takāful data-paper panel (`clean/panel_takaful_harmonised.csv`)
   from the WUI companion-study panel (`clean/panel_takaful_uncert.csv`).
5. Hardened the year-to-date detection rule so that missing or interior quarters are not
   silently bridged.
6. Added TP07 numerator/denominator component extraction and a direct provenance check
   against the published ratio.
7. Added unit-conversion diagnostics without imposing an unverified correction.
8. Added `07_verify_release.R` structural release checks.
9. Added a human-readable canonical panel codebook and a verification report.
10. Added reporting-mode metadata to the distributed derived panels.
11. Added four-series reporting-mode robustness checks, leave-one-jurisdiction-out
    retention-variance checks, and shared-field reproducibility verification.
12. Added `08_make_figures.R`, which regenerates the four manuscript figures at 300 dpi
    from the canonical panel.
13. Regrouped Figure 3 so that Panel A contains gross contributions, net contributions,
    retention and the expense ratio, and Panel B contains investment income, penetration,
    density and operator count, with all seven jurisdictions shown in each panel.

The raw publisher files are not redistributed in this release. No source-derived values
(FX metadata or TP07 components) were written into the reference CSV by hand; those
columns are generated and verified when the pipeline is run against a fresh PSIFIs
download.

## Runtime verification (2026-09-12)

The canonical R chain was executed successfully on the author's Windows/RStudio
installation under R 4.4.1, using the original manually downloaded IFSB insurance
workbook. `07_verify_release.R` ended with `ALL STRUCTURAL CHECKS PASSED`. The rebuilt
panel matched all 26 fields shared with the previously deposited companion CSV at
tolerance 1e-6, with identical `iso3-period` keys. The strengthened verifier, including
the robustness and leave-one-out diagnostics, passed in the same run.
