# =============================================================================
# 06_extract_takaful_panel.R — IFSB-DataHub
# Produces the paper-independent harmonised quarterly takāful panel.
# It does NOT require WUI. If WUI has been imported before 03_build_master.R,
# an optional companion-analysis panel is also written.
# =============================================================================
source(file.path("scripts", "00_setup.R"))

f_master <- file.path(dir_clean, "master_panel.rds")
if (!file.exists(f_master)) stop("Run 03_build_master.R before script 06.")
master <- readRDS(f_master)

pays_takaful <- c("BHR","BRN","JOR","MYS","NGA","SAU","ARE")
pays_specA   <- c("JOR","MYS","NGA","SAU","ARE")
reference_start <- "2019Q1"
reference_end   <- "2023Q4"

codes_takaful <- tribble(
  ~indicator_code, ~var,
  "TS03a",      "gwc_gen",
  "TS03b",      "gwc_fam",
  "TS05a",      "nwc_gen",
  "TS05b",      "nwc_fam",
  "TA06a",      "penetr_gen",
  "TA06b",      "penetr_fam",
  "TA07a",      "densite_gen",
  "TA07b",      "densite_fam",
  "TS01a",      "operateurs_gen",
  "TS01b",      "operateurs_fam",
  "TP05a",      "equity_assets_gen",
  "TP05b",      "equity_assets_fam",
  "TP09a",      "opex_ratio_gen",
  "TP09b",      "opex_ratio_fam",
  "TP15",       "invest_income_gen",
  "TP16",       "invest_income_fam",
  "TP07a",      "retention_gen",
  "TP07b",      "retention_fam",
  "TP07a_010",  "retention_num_gen",
  "TP07a_020",  "retention_den_gen",
  "TP07b_010",  "retention_num_fam",
  "TP07b_020",  "retention_den_fam"
)

# Source values in wide form.
tak <- master %>%
  filter(segment == "takaful", iso3 %in% pays_takaful,
         period >= reference_start, period <= reference_end,
         indicator_code %in% codes_takaful$indicator_code) %>%
  left_join(codes_takaful, by = "indicator_code") %>%
  select(iso3, country, period, year, quarter, var, value_nc) %>%
  distinct() %>%
  pivot_wider(names_from = var, values_from = value_nc)

# Source metadata for contribution levels: preserve it so unit/FX diagnostics
# are reproducible without relying on undocumented assumptions.
meta <- master %>%
  filter(segment == "takaful", iso3 %in% pays_takaful,
         period >= reference_start, period <= reference_end,
         indicator_code == "TS03a") %>%
  transmute(iso3, period,
            source_currency = currency,
            source_units = units,
            usd_exchange_rate,
            portal_value_usd_mn = value_usd_mn)

tak <- tak %>% left_join(meta, by = c("iso3", "period"))

# Year-to-date classification. Only country-years with >=3 observed consecutive
# quarters are eligible for the monotonicity test; gaps are never silently bridged.
detect_ytd <- function(df, v) {
  yearly <- df %>%
    group_by(iso3, year) %>%
    arrange(quarter, .by_group = TRUE) %>%
    summarise(
      q = list(quarter[!is.na(.data[[v]])]),
      x = list(.data[[v]][!is.na(.data[[v]])]),
      .groups = "drop"
    ) %>%
    rowwise() %>%
    mutate(
      eligible = length(x) >= 3 && all(diff(q) == 1),
      mono = if (eligible) all(diff(x) > 0) else NA
    ) %>%
    ungroup()

  yearly %>%
    group_by(iso3) %>%
    summarise(
      eligible_years = sum(!is.na(mono)),
      ytd_share = ifelse(eligible_years > 0, mean(mono, na.rm = TRUE), NA_real_),
      ytd = !is.na(ytd_share) & ytd_share >= 0.60,
      .groups = "drop"
    )
}

flags <- detect_ytd(tak, "gwc_gen")
if (any(is.na(flags$ytd_share))) stop("Unable to classify reporting mode for all jurisdictions.")

decumul <- function(df, v, flags) {
  df %>%
    left_join(flags %>% select(iso3, ytd), by = "iso3") %>%
    group_by(iso3, year) %>%
    arrange(quarter, .by_group = TRUE) %>%
    mutate(
      prev_q = lag(quarter),
      prev_x = lag(.data[[v]]),
      "{v}_flux" := case_when(
        !ytd ~ .data[[v]],
        quarter == 1 ~ .data[[v]],
        is.na(.data[[v]]) ~ NA_real_,
        is.na(prev_x) | is.na(prev_q) | quarter - prev_q != 1 ~ NA_real_,
        TRUE ~ .data[[v]] - prev_x
      )
    ) %>%
    ungroup() %>%
    select(-ytd, -prev_q, -prev_x)
}

for (v in c("gwc_gen", "gwc_fam", "nwc_gen", "nwc_fam")) {
  tak <- decumul(tak, v, flags)
}

panel_core <- tak %>%
  left_join(flags, by = "iso3") %>%
  mutate(
    reporting_mode = if_else(ytd, "year-to-date", "quarterly flow"),
    source_extraction_date = as.Date("2026-07-19")
  ) %>%
  select(iso3, country, period, year, quarter, reporting_mode, ytd_share,
         source_extraction_date, source_currency, source_units,
         usd_exchange_rate, portal_value_usd_mn,
         penetr_gen, penetr_fam, densite_gen, densite_fam,
         equity_assets_gen, equity_assets_fam,
         retention_gen, retention_fam,
         retention_num_gen, retention_den_gen,
         retention_num_fam, retention_den_fam,
         opex_ratio_gen, opex_ratio_fam, invest_income_gen, invest_income_fam,
         operateurs_gen, operateurs_fam,
         gwc_gen, gwc_fam, nwc_gen, nwc_fam,
         gwc_gen_flux, gwc_fam_flux, nwc_gen_flux, nwc_fam_flux) %>%
  arrange(iso3, year, quarter)

saveRDS(panel_core, file.path(dir_clean, "panel_takaful_harmonised.rds"))
write_csv(panel_core, file.path(dir_clean, "panel_takaful_harmonised.csv"), na = "")

# Optional companion-study panel. This is not the canonical data-paper product.
if (any(master$segment == "uncert")) {
  wui_pays <- master %>%
    filter(segment == "uncert", indicator_code %in% c("WUI_MA3","WUI_RAW"),
           iso3 %in% pays_takaful) %>%
    select(iso3, period, indicator_code, value_nc) %>%
    pivot_wider(names_from = indicator_code, values_from = value_nc) %>%
    rename(wui_ma3 = WUI_MA3, wui_raw = WUI_RAW)

  wui_glob <- master %>%
    filter(segment == "uncert", indicator_code == "WUI_GLOBAL") %>%
    select(period, wui_global = value_nc)

  panel_uncert <- panel_core %>%
    left_join(wui_pays, by = c("iso3", "period")) %>%
    left_join(wui_glob, by = "period") %>%
    mutate(
      specA = iso3 %in% pays_specA,
      covid = year == 2020 | (year == 2021 & quarter <= 2),
      ln_gwc_gen = if_else(gwc_gen_flux > 0, log(gwc_gen_flux), NA_real_),
      ln_gwc_fam = if_else(gwc_fam_flux > 0, log(gwc_fam_flux), NA_real_)
    )
  saveRDS(panel_uncert, file.path(dir_clean, "panel_takaful_uncert.rds"))
  write_csv(panel_uncert, file.path(dir_clean, "panel_takaful_uncert.csv"), na = "")
}

print(flags)
message("06_extract_takaful_panel.R : OK -> clean/panel_takaful_harmonised.*")
