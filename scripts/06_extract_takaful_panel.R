# =============================================================================
# 06_extract_takaful_panel.R — IFSB-DataHub
# Extrait le panel PRÊT POUR LA MODÉLISATION du papier takaful-incertitude.
# 1 ligne = iso3 x trimestre ; variables en colonnes (format large).
#
# Design validé (journal des décisions, 2026-07-19) :
#   Spec A (principale) : 5 pays avec WUI pays (JOR, MYS, NGA, SAU, ARE)
#   Spec B (robustesse) : + BHR, BRN avec WUI_GLOBAL (sans effets fixes temps)
#   Mesure principale d'incertitude : WUI_MA3 ; WUI_RAW en robustesse
#   Turquie exclue (données annuelles seulement)
# Sorties : clean/panel_takaful_uncert.rds / .csv
# =============================================================================
source(file.path("scripts", "00_setup.R"))

master <- readRDS(file.path(dir_clean, "master_panel.rds"))

pays_takaful <- c("BHR","BRN","JOR","MYS","NGA","SAU","ARE")   # TUR exclue
pays_specA   <- c("JOR","MYS","NGA","SAU","ARE")

# --- 1. Variables takaful (segment takaful, indicateurs de tête) ------------
codes_takaful <- tribble(
  ~indicator_code, ~var,
  "TS03a", "gwc_gen",        # contributions brutes, General  (VD principale)
  "TS03b", "gwc_fam",        # contributions brutes, Family   (VD principale)
  "TS05a", "nwc_gen",        # contributions nettes (VD alternative)
  "TS05b", "nwc_fam",
  "TA06a", "penetr_gen",     # taux de pénétration (VD alternative)
  "TA06b", "penetr_fam",
  "TA07a", "densite_gen",    # densité (VD alternative)
  "TA07b", "densite_fam",
  "TS01a", "operateurs_gen", # contrôles ->
  "TS01b", "operateurs_fam",
  "TP05a", "equity_assets_gen",
  "TP05b", "equity_assets_fam",
  "TP09a", "opex_ratio_gen",
  "TP09b", "opex_ratio_fam",
  "TP15",  "invest_income_gen",
  "TP16",  "invest_income_fam",
  "TP07a", "retention_gen",  # rétention des risques (coeur "partage des risques")
  "TP07b", "retention_fam"
)

tak <- master %>%
  filter(segment == "takaful", iso3 %in% pays_takaful,
         indicator_code %in% codes_takaful$indicator_code) %>%
  left_join(codes_takaful, by = "indicator_code") %>%
  # contributions : monnaie LOCALE (les EF pays absorbent l'échelle ; la
  # colonne USD du portail est défectueuse pour certains pays, cf. journal)
  mutate(val = value_nc) %>%
  select(iso3, period, year, quarter, var, val) %>%
  pivot_wider(names_from = var, values_from = val)

# --- 2. Incertitude ----------------------------------------------------------
wui_pays <- master %>%
  filter(segment == "uncert", indicator_code %in% c("WUI_MA3","WUI_RAW"),
         iso3 %in% pays_takaful) %>%
  select(iso3, period, indicator_code, value_nc) %>%
  pivot_wider(names_from = indicator_code, values_from = value_nc) %>%
  rename(wui_ma3 = WUI_MA3, wui_raw = WUI_RAW)

wui_glob <- master %>%
  filter(indicator_code == "WUI_GLOBAL") %>%
  select(period, wui_global = value_nc)

# --- 3. Assemblage -----------------------------------------------------------
# --- 2bis. Décumul YTD -> flux trimestriels --------------------------------
# Certains pays déclarent les contributions en CUMUL depuis le début d'année
# (JOR, MYS, NGA : croissance stricte intra-annuelle), d'autres en flux
# (ARE, SAU). Détection algorithmique puis conversion en flux.
detect_ytd <- function(df, v) {
  df %>% group_by(iso3, year) %>% arrange(quarter, .by_group = TRUE) %>%
    summarise(mono = all(diff(na.omit(.data[[v]])) > 0) &
                     sum(!is.na(.data[[v]])) >= 3, .groups = "drop_last") %>%
    summarise(ytd = mean(mono, na.rm = TRUE) >= 0.6, .groups = "drop")
}
decumul <- function(df, v) {
  flags <- detect_ytd(df, v)
  df %>% left_join(flags, by = "iso3") %>%
    group_by(iso3, year) %>% arrange(quarter, .by_group = TRUE) %>%
    mutate("{v}_flux" := if_else(ytd,
             .data[[v]] - dplyr::lag(.data[[v]], default = 0),
             .data[[v]])) %>%
    ungroup() %>% select(-ytd)
}
for (v in c("gwc_gen","gwc_fam","nwc_gen","nwc_fam")) tak <- decumul(tak, v)
cat("Pays detectes en cumul YTD (gwc_gen) : ",
    paste(detect_ytd(tak,"gwc_gen") %>% filter(ytd) %>% pull(iso3), collapse=", "), "\n")

panel <- tak %>%
  left_join(wui_pays, by = c("iso3","period")) %>%
  left_join(wui_glob, by = "period") %>%
  arrange(iso3, year, quarter) %>%
  mutate(
    specA      = iso3 %in% pays_specA,          # TRUE = entre dans la spec principale
    covid      = year == 2020 | (year == 2021 & quarter <= 2),
    ln_gwc_gen = log(gwc_gen_flux),
    ln_gwc_fam = log(gwc_fam_flux)
  )

saveRDS(panel, file.path(dir_clean, "panel_takaful_uncert.rds"))
write_csv(panel, file.path(dir_clean, "panel_takaful_uncert.csv"))

# --- Contrôles ---------------------------------------------------------------
print(panel %>% group_by(iso3) %>%
  summarise(trimestres = n(),
            gwc_gen_ok = sum(!is.na(gwc_gen)),
            gwc_fam_ok = sum(!is.na(gwc_fam)),
            wui_pays_ok = sum(!is.na(wui_ma3)),
            .groups = "drop"))
message("Spec A : ", panel %>% filter(specA, !is.na(gwc_gen), !is.na(wui_ma3)) %>% nrow(),
        " observations exploitables (gwc_gen x wui_ma3)")
message("06_extract_takaful_panel.R : OK -> clean/panel_takaful_uncert.rds")
