# =============================================================================
# 01_import_psifis.R — IFSB-DataHub
# Importe les 4 extraits du portail data.ifsb.org (format long, en-tête ligne 8)
# Sortie : clean/psifis_long.rds  (+ un rds par segment)
# =============================================================================
source(file.path("scripts", "00_setup.R"))

# Un importeur générique : tous les extraits du portail partagent la même
# structure -> Country | Regional Code | Report Type | Time Period |
# USD Exchange Rate | Indicator Code | Indicator Description | currency |
# units | Values | Values in USD Millions
import_psifis <- function(file, segment) {
  message("Import : ", basename(file), " [", segment, "]")
  df <- read_excel(file, skip = 7, col_types = "text")
  names(df) <- str_trim(names(df))

  stopifnot(all(c("Country", "Time Period", "Indicator Code", "Values") %in% names(df)))

  out <- df %>%
    transmute(
      segment        = segment,
      country_raw    = str_trim(Country),
      region         = str_trim(`Regional Code`),
      period         = str_trim(`Time Period`),
      indicator_code = str_trim(`Indicator Code`),
      indicator_desc = str_trim(`Indicator Description`),
      currency       = str_trim(currency),
      units          = str_trim(units),
      value_nc       = clean_num(Values),
      value_usd_mn   = clean_num(`Values in USD Millions`)
    ) %>%
    filter(!is.na(country_raw), country_raw != "", !is.na(period), period != "") %>%
    left_join(country_map, by = "country_raw") %>%
    bind_cols(split_period(.$period)) %>%
    select(segment, iso3, country, region, period, year, quarter,
           indicator_code, indicator_desc, currency, units,
           value_nc, value_usd_mn)

  # Contrôle : aucun pays non apparié
  unmatched <- out %>% filter(is.na(iso3)) %>% distinct(country) %>% pull()
  if (length(unmatched) > 0)
    warning("Pays sans ISO3 (à ajouter dans country_map) : ",
            paste(unmatched, collapse = ", "))
  out
}

segments <- tribble(
  ~file,                                   ~segment,
  "islamic_banking_data.xlsx",             "banking",
  "islamic_insurance_data.xlsx",           "takaful",
  "islamic_capital_markets_data.xlsx",     "icm",
  "detailed_financial_statements.xlsx",    "dfs"
)

psifis_long <- pmap_dfr(segments, function(file, segment)
  import_psifis(file.path(dir_raw, file), segment))

# Sauvegardes : un rds global + un par segment
saveRDS(psifis_long, file.path(dir_clean, "psifis_long.rds"))
psifis_long %>%
  group_split(segment) %>%
  walk(~ saveRDS(.x, file.path(dir_clean, paste0("psifis_", unique(.x$segment), ".rds"))))

# Résumé de contrôle (à vérifier avant de passer au script suivant)
ctrl <- psifis_long %>%
  group_by(segment) %>%
  summarise(pays = n_distinct(iso3),
            p_min = min(period), p_max = max(period),
            lignes = n(),
            valeurs_non_manquantes = sum(!is.na(value_nc)),
            .groups = "drop")
print(ctrl)
message("01_import_psifis.R : OK -> clean/psifis_long.rds")
