# Data sources and manual-download protocol

## Required source for the data paper

**IFSB PSIFIs — Islamic Insurance Data**  
Publisher: Islamic Financial Services Board (IFSB) Data Portal  
Reference extraction used by the paper: **19 July 2026**  
Original supplied filename in the verified rebuild: `ISLAMIC_INSURANCE_DATA_202607191918.xlsx`

Download the workbook manually from the IFSB portal and place it unchanged in `raw/ifsb/`.
`01_import_psifis.R` accepts the timestamped portal filename directly; manual renaming is
not required. The raw workbook is not redistributed with this repository.

Running `Rscript scripts/00_setup.R` from the repository root prints SHA-256 checksums of
all files currently in `raw/ifsb/`. Keep this output with a local replication log if exact
source-vintage provenance is required.

## Optional sources

The following are not required for the canonical 120-row takāful data-paper panel:

- IFSB Islamic Banking Data workbook
- IFSB Islamic Capital Markets Data workbook
- IFSB Detailed Financial Statements workbook
- `Turkey_Takaful-Windows.xls` (annual robustness only)
- World Uncertainty Index input used by the companion research study

If the first three timestamped IFSB workbooks are present in `raw/ifsb/`, script 01 imports
them automatically into the broader master. Their absence does not stop the data-paper rebuild.

## Fixed paper window

The reference data-paper panel is explicitly restricted to **2019Q1–2023Q4** in script 06.
This matters because the 19 July 2026 portal export itself contains later observations for
some jurisdictions. Those later rows are source data, but they are outside the documented
paper release and must not silently alter the 120-row reference panel.
