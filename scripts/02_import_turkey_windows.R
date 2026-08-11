# =============================================================================
# 02_import_turkey_windows.R — IFSB-DataHub
# Fichier hérité au format LARGE (fenêtres takaful, Turquie) -> format long
# Sortie : clean/psifis_takaful_windows_tur.rds
# NOTE (journal des décisions) : ce fichier ne contient que des valeurs
# annuelles (Q4 2019-2021) et les contributions brutes y sont manquantes ;
# la Turquie est donc EXCLUE du panel trimestriel takaful et ne sert
# qu'aux contrôles de robustesse annuels.
# =============================================================================
source(file.path("scripts", "00_setup.R"))

f <- file.path(dir_raw, "turkey_takaful_windows.xls")

# .xls ancien format : readxl le lit nativement
hdr <- read_excel(f, skip = 3, n_max = 0)
qcols <- names(hdr)[str_detect(names(hdr), "^20\\d{2}Q[1-4]$")]

tw <- read_excel(f, skip = 3, col_types = "text")
names(tw) <- str_trim(names(tw))
names(tw)[2] <- "indicator_desc"          # " Key Indicator "

tw_long <- tw %>%
  fill(Code, .direction = "down") %>%     # le code (TP01...) n'est écrit qu'une fois
  filter(!is.na(indicator_desc)) %>%
  pivot_longer(all_of(qcols), names_to = "period", values_to = "value_raw") %>%
  transmute(
    segment        = "takaful_windows",
    iso3           = "TUR",
    country        = "Turkey",
    region         = NA_character_,
    period,
    indicator_code = str_trim(Code),
    indicator_desc = str_trim(indicator_desc),
    currency       = str_trim(Currency),
    units          = str_trim(Units),
    value_nc       = clean_num(value_raw),
    value_usd_mn   = NA_real_
  ) %>%
  bind_cols(split_period(.$period)) %>%
  select(segment, iso3, country, region, period, year, quarter,
         indicator_code, indicator_desc, currency, units, value_nc, value_usd_mn)

saveRDS(tw_long, file.path(dir_clean, "psifis_takaful_windows_tur.rds"))

print(tw_long %>% filter(!is.na(value_nc)) %>% count(period))
message("02_import_turkey_windows.R : OK -> clean/psifis_takaful_windows_tur.rds")
