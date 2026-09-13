# =============================================================================
# 03_build_master.R — IFSB-DataHub
# Builds the long/tidy master table. The PSIFIs import is required. Turkey
# windows and external sources are optional and are appended only if present.
# =============================================================================
source(file.path("scripts", "00_setup.R"))

f_psifis <- file.path(dir_clean, "psifis_long.rds")
if (!file.exists(f_psifis)) stop("Missing clean/psifis_long.rds. Run script 01 first.")
psifis <- readRDS(f_psifis)
ifsb <- psifis %>% mutate(source = "IFSB PSIFIs (data.ifsb.org, extract 2026-07-19)")

f_tur <- file.path(dir_clean, "psifis_takaful_windows_tur.rds")
if (file.exists(f_tur)) {
  tur_win <- readRDS(f_tur) %>% mutate(source = "IFSB legacy takāful-windows workbook")
  ifsb <- bind_rows(ifsb, tur_win)
}

ext_files <- list.files(dir_clean, pattern = "^ext_.*\\.rds$", full.names = TRUE)
ext <- if (length(ext_files) > 0) map_dfr(ext_files, readRDS) else NULL
master <- bind_rows(ifsb, ext) %>% arrange(segment, iso3, year, quarter, indicator_code)

saveRDS(master, file.path(dir_clean, "master_panel.rds"))

dico <- master %>%
  group_by(segment, indicator_code, indicator_desc) %>%
  summarise(
    pays_couverts  = n_distinct(iso3[!is.na(value_nc)]),
    periode_min    = if (all(is.na(value_nc))) NA_character_ else min(period[!is.na(value_nc)]),
    periode_max    = if (all(is.na(value_nc))) NA_character_ else max(period[!is.na(value_nc)]),
    n_observations = sum(!is.na(value_nc)),
    unites         = paste(sort(unique(na.omit(units))), collapse = "; "),
    sources        = paste(sort(unique(na.omit(source))), collapse = "; "),
    .groups = "drop"
  ) %>% arrange(segment, indicator_code)
write.xlsx(dico, file.path(dir_docs, "dictionnaire_variables.xlsx"), overwrite = TRUE)
message("03_build_master.R : OK — ", nrow(master), " master rows; ", nrow(dico), " indicators documented.")
