# =============================================================================
# 01_import_psifis.R — IFSB-DataHub
# Imports the manually downloaded IFSB PSIFIs workbooks. The takāful workbook
# is required for the data paper; banking, capital-markets and detailed-
# financial-statements workbooks are optional and are imported when present.
# Original IFSB download filenames are accepted without renaming.
# =============================================================================
source(file.path("scripts", "00_setup.R"))

find_raw_file <- function(patterns, required = FALSE, label = "source") {
  if (!dir.exists(dir_raw)) {
    if (required) stop("Missing raw source directory: ", dir_raw)
    return(NA_character_)
  }
  fs <- list.files(dir_raw, full.names = TRUE)
  bn <- basename(fs)
  for (pat in patterns) {
    hit <- fs[str_detect(bn, regex(pat, ignore_case = TRUE))]
    if (length(hit) == 1) return(hit)
    if (length(hit) > 1) stop("Multiple files match ", label, ": ", paste(basename(hit), collapse = ", "))
  }
  if (required) stop("Missing ", label, " in ", dir_raw,
                     ". Keep the original IFSB filename or use a documented legacy alias.")
  NA_character_
}

import_psifis <- function(file, segment) {
  message("Import: ", basename(file), " [", segment, "]")
  df <- read_excel(file, skip = 7, col_types = "text")
  names(df) <- str_trim(names(df))

  required <- c("Country", "Time Period", "Indicator Code", "Values")
  if (!all(required %in% names(df))) {
    stop("Unexpected PSIFIs schema in ", basename(file),
         ". Missing: ", paste(setdiff(required, names(df)), collapse = ", "))
  }

  get_col <- function(nm) if (nm %in% names(df)) df[[nm]] else rep(NA_character_, nrow(df))

  out <- tibble(
      segment           = segment,
      country_raw       = str_trim(get_col("Country")),
      region            = str_trim(get_col("Regional Code")),
      report_type       = str_trim(get_col("Report Type")),
      period            = str_trim(get_col("Time Period")),
      usd_exchange_rate = clean_num(get_col("USD Exchange Rate")),
      indicator_code    = str_trim(get_col("Indicator Code")),
      indicator_desc    = str_trim(get_col("Indicator Description")),
      currency          = str_trim(get_col("currency")),
      units             = str_trim(get_col("units")),
      value_nc          = clean_num(get_col("Values")),
      value_usd_mn      = clean_num(get_col("Values in USD Millions"))
    ) %>%
    filter(!is.na(country_raw), country_raw != "", !is.na(period), period != "") %>%
    left_join(country_map, by = "country_raw") %>%
    bind_cols(split_period(.$period)) %>%
    select(segment, iso3, country, region, report_type, period, year, quarter,
           indicator_code, indicator_desc, currency, units, usd_exchange_rate,
           value_nc, value_usd_mn)

  unmatched <- out %>% filter(is.na(iso3)) %>% distinct(country) %>% pull()
  if (length(unmatched) > 0) warning("Countries without ISO3 mapping: ", paste(unmatched, collapse = ", "))
  out
}

sources <- tribble(
  ~segment,  ~required, ~label, ~p1, ~p2,
  "takaful", TRUE,  "Islamic insurance data workbook", "^ISLAMIC_INSURANCE_DATA_.*\\.xlsx$", "^islamic_insurance_data\\.xlsx$",
  "banking", FALSE, "Islamic banking data workbook", "^ISLAMIC_BANKING_DATA_.*\\.xlsx$", "^islamic_banking_data\\.xlsx$",
  "icm",     FALSE, "Islamic capital-markets data workbook", "^ISLAMIC_CAPITAL_MARKETS_DATA_.*\\.xlsx$", "^islamic_capital_markets_data\\.xlsx$",
  "dfs",     FALSE, "Detailed financial-statements workbook", "^DETAILED_FINANCIAL_STATEMENTS_.*\\.xlsx$", "^detailed_financial_statements\\.xlsx$"
)

parts <- pmap(sources, function(segment, required, label, p1, p2) {
  f <- find_raw_file(c(p1, p2), required = required, label = label)
  if (is.na(f)) return(NULL)
  import_psifis(f, segment)
})
psifis_long <- bind_rows(parts)

saveRDS(psifis_long, file.path(dir_clean, "psifis_long.rds"))
psifis_long %>%
  group_split(segment) %>%
  walk(~ saveRDS(.x, file.path(dir_clean, paste0("psifis_", unique(.x$segment), ".rds"))))

ctrl <- psifis_long %>%
  group_by(segment) %>%
  summarise(pays = n_distinct(iso3), p_min = min(period), p_max = max(period),
            lignes = n(), valeurs_non_manquantes = sum(!is.na(value_nc)), .groups = "drop")
print(ctrl)
message("01_import_psifis.R : OK -> clean/psifis_long.rds")
