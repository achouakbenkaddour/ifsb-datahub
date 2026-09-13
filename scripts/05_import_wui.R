# =============================================================================
# 05_import_wui.R — IFSB-DataHub
# World Uncertainty Index (worlduncertaintyindex.com, fichier WUI_Data.xlsx)
# -> lignes additionnelles du tableau maître (segment = "uncert")
# Indicateurs créés :
#   WUI_RAW    : indice trimestriel par pays (feuille T2)
#   WUI_MA3    : moyenne mobile pondérée sur 3 trimestres (feuille T6)
#   WUI_GLOBAL : indice mondial pondéré PIB (feuille T1), iso3 = "WLD"
# Sortie : clean/ext_wui.rds  (repris automatiquement par 03_build_master.R)
# =============================================================================
source(file.path("scripts", "00_setup.R"))

f_wui <- file.path("raw", "wui", "WUI_Data.xlsx")
stopifnot(file.exists(f_wui))

# --- Feuilles pays (larges : 1 colonne par ISO3) ----------------------------
import_wui_sheet <- function(sheet, code_indicateur, description) {
  df <- read_excel(f_wui, sheet = sheet)
  names(df)[1] <- "period_raw"
  df %>%
    pivot_longer(-period_raw, names_to = "iso3", values_to = "value_nc") %>%
    filter(!is.na(value_nc)) %>%
    mutate(
      segment        = "uncert",
      period         = toupper(str_trim(period_raw)),   # "2019q1" -> "2019Q1"
      indicator_code = code_indicateur,
      indicator_desc = description,
      currency       = NA_character_,
      units          = "index",
      value_usd_mn   = NA_real_,
      region         = NA_character_,
      report_type    = "quarterly",
      usd_exchange_rate = NA_real_
    ) %>%
    left_join(country_map %>% select(iso3, country), by = "iso3") %>%
    bind_cols(split_period(.$period)) %>%
    select(segment, iso3, country, region, report_type, period, year, quarter,
           indicator_code, indicator_desc, currency, units, usd_exchange_rate,
           value_nc, value_usd_mn)
}

wui_raw <- import_wui_sheet("T2", "WUI_RAW",
  "World Uncertainty Index, trimestriel par pays (Ahir-Bloom-Furceri)")
wui_ma3 <- import_wui_sheet("T6", "WUI_MA3",
  "WUI, moyenne mobile ponderee 3 trimestres, par pays")

# --- Indice mondial (feuille T1) --------------------------------------------
t1 <- read_excel(f_wui, sheet = "T1")
names(t1)[1] <- "period_raw"
wui_glob <- t1 %>%
  transmute(period_raw,
            value_nc = `Global (GDP weighted average)`) %>%
  filter(!is.na(value_nc)) %>%
  mutate(
    segment = "uncert", iso3 = "WLD", country = "World",
    region = NA_character_, report_type = "quarterly",
    usd_exchange_rate = NA_real_,
    period = toupper(str_trim(period_raw)),
    indicator_code = "WUI_GLOBAL",
    indicator_desc = "WUI mondial (moyenne ponderee PIB)",
    currency = NA_character_, units = "index", value_usd_mn = NA_real_
  ) %>%
  bind_cols(split_period(.$period)) %>%
  select(segment, iso3, country, region, report_type, period, year, quarter,
         indicator_code, indicator_desc, currency, units, usd_exchange_rate,
         value_nc, value_usd_mn)

ext_wui <- bind_rows(wui_raw, wui_ma3, wui_glob) %>%
  mutate(source = "WUI (worlduncertaintyindex.com, WUI_Data.xlsx)")

saveRDS(ext_wui, file.path(dir_clean, "ext_wui.rds"))

# --- Contrôles ---------------------------------------------------------------
ctrl <- ext_wui %>%
  group_by(indicator_code) %>%
  summarise(pays = n_distinct(iso3), p_min = min(period), p_max = max(period),
            n = n(), .groups = "drop")
print(ctrl)

echantillon <- c("BHR","BRN","JOR","MYS","NGA","SAU","TUR","ARE")
present <- ext_wui %>% filter(indicator_code == "WUI_RAW") %>%
  distinct(iso3) %>% pull()
message("Pays takaful couverts par le WUI pays : ",
        paste(intersect(echantillon, present), collapse = ", "))
message("ABSENTS du WUI pays : ",
        paste(setdiff(echantillon, present), collapse = ", "),
        "  -> utiliser WUI_GLOBAL (voir journal des decisions)")
message("05_import_wui.R : OK -> clean/ext_wui.rds")
