# =============================================================================
# 03_build_master.R — IFSB-DataHub
# Fusionne tous les segments dans le TABLEAU MAÎTRE (format long/tidy)
# Sorties :
#   clean/master_panel.rds / .csv     — 1 ligne = iso3 x période x indicateur
#   docs/dictionnaire_variables.xlsx  — généré automatiquement
# Toute nouvelle source (WUI, sigma, WDI...) = nouvelles lignes, jamais
# de nouvelles colonnes : ajouter un import puis bind_rows ici.
# =============================================================================
source(file.path("scripts", "00_setup.R"))

psifis  <- readRDS(file.path(dir_clean, "psifis_long.rds"))
tur_win <- readRDS(file.path(dir_clean, "psifis_takaful_windows_tur.rds"))

ifsb <- bind_rows(psifis, tur_win) %>%
  mutate(source = "IFSB PSIFIs (data.ifsb.org, extrait 2026-07-19)")

# Sources externes : tout fichier clean/ext_*.rds est intégré automatiquement
# (chaque script d'import externe doit y inclure sa propre colonne `source`)
ext_files <- list.files(dir_clean, pattern = "^ext_.*\\.rds$", full.names = TRUE)
ext <- if (length(ext_files) > 0) map_dfr(ext_files, readRDS) else NULL

master <- bind_rows(ifsb, ext) %>%
  arrange(segment, iso3, year, quarter, indicator_code)

saveRDS(master, file.path(dir_clean, "master_panel.rds"))
write_csv(master, file.path(dir_clean, "master_panel.csv"))

# --- Dictionnaire de variables (auto) ---------------------------------------
dico <- master %>%
  group_by(segment, indicator_code, indicator_desc) %>%
  summarise(
    pays_couverts   = n_distinct(iso3[!is.na(value_nc)]),
    periode_min     = suppressWarnings(min(period[!is.na(value_nc)])),
    periode_max     = suppressWarnings(max(period[!is.na(value_nc)])),
    n_observations  = sum(!is.na(value_nc)),
    unites          = paste(unique(na.omit(units)), collapse = "; "),
    .groups = "drop"
  ) %>%
  mutate(source = "IFSB PSIFIs") %>%
  arrange(segment, indicator_code)

write.xlsx(dico, file.path(dir_docs, "dictionnaire_variables.xlsx"))

message("03_build_master.R : OK — ", nrow(master), " lignes dans master_panel ; ",
        nrow(dico), " indicateurs documentés.")

# --- Exemple d'extraction pour un papier ------------------------------------
# Panel trimestriel takaful (7 pays, 2019Q1-2022Q4), contributions brutes :
# readRDS("clean/master_panel.rds") %>%
#   filter(segment == "takaful", indicator_code == "TP07a_020",
#          iso3 != "TUR", period <= "2022Q4") %>%
#   select(iso3, year, quarter, gwc_nc = value_nc, gwc_usd = value_usd_mn)
