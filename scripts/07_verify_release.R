# =============================================================================
# 07_verify_release.R — IFSB-DataHub
# Deterministic release checks for the harmonised takāful panel and source
# provenance. Run after script 06. Stops on structural failures.
# =============================================================================
source(file.path("scripts", "00_setup.R"))

f <- file.path(dir_clean, "panel_takaful_harmonised.rds")
if (!file.exists(f)) stop("Run 06_extract_takaful_panel.R first.")
p <- readRDS(f)

stopifnot(nrow(p) == 120L)
stopifnot(n_distinct(p$iso3) == 7L)
stopifnot(!anyDuplicated(p[c("iso3", "period")]))

expected_ytd <- c("BHR","BRN","JOR","MYS","NGA")
actual_ytd <- p %>% distinct(iso3, reporting_mode) %>%
  filter(reporting_mode == "year-to-date") %>% pull(iso3) %>% sort()
stopifnot(identical(sort(expected_ytd), actual_ytd))

# No non-positive de-cumulated contribution flows.
flow_vars <- c("gwc_gen_flux","gwc_fam_flux","nwc_gen_flux","nwc_fam_flux")
nonpos <- p %>% summarise(across(all_of(flow_vars), ~ sum(.x <= 0, na.rm = TRUE)))
if (any(unlist(nonpos) > 0)) stop("Non-positive de-cumulated flows detected.")

# Ratio provenance: published TP07 must equal its own published components,
# not TS05/TS03. This check requires the component rows imported from source.
ratio_check <- function(branch) {
  r <- p[[paste0("retention_", branch)]]
  num <- p[[paste0("retention_num_", branch)]]
  den <- p[[paste0("retention_den_", branch)]]
  ok <- complete.cases(r, num, den) & den != 0
  if (!any(ok)) stop("No TP07 component observations available for ", branch)
  diff <- abs(r[ok] - 100 * num[ok] / den[ok])
  tibble(branch = branch, n = sum(ok), max_abs_diff = max(diff),
         mean_abs_diff = mean(diff))
}
ratio_diag <- bind_rows(ratio_check("gen"), ratio_check("fam"))
print(ratio_diag)
if (any(ratio_diag$max_abs_diff > 1e-4)) {
  stop("TP07 ratio/component identity failed; inspect source vintage and codes.")
}

# Unit-conversion diagnostic. It is intentionally diagnostic rather than a
# correction: the note recommends not using the portal USD column unverified.
unit_multiplier <- function(x) {
  # Empirical scale interpretation verified against the 2026-07-19 IFSB export.
  # In this vintage G behaves as unscaled/actual values, not as "billions".
  z <- toupper(trimws(x))
  case_when(
    z == "B" ~ 1e9,
    z == "M" ~ 1e6,
    z == "K" ~ 1e3,
    z %in% c("A", "G") ~ 1,
    TRUE ~ NA_real_
  )
}

fx_diag <- p %>%
  mutate(
    multiplier = unit_multiplier(source_units),
    expected_usd_mn = case_when(
      toupper(trimws(source_currency)) == "USD" & !is.na(multiplier) ~
        gwc_gen * multiplier / 1e6,
      !is.na(usd_exchange_rate) & usd_exchange_rate != 0 & !is.na(multiplier) ~
        gwc_gen * multiplier / usd_exchange_rate / 1e6,
      TRUE ~ NA_real_
    ),
    usd_ratio = portal_value_usd_mn / expected_usd_mn,
    diagnostic_status = case_when(
      is.na(multiplier) ~ "unknown source scale",
      toupper(trimws(source_currency)) == "USD" ~ "checkable: source labelled USD; FX field not applied",
      is.na(usd_exchange_rate) | usd_exchange_rate == 0 ~ "not checkable: FX missing",
      TRUE ~ "checkable: local value / FX"
    )
  ) %>%
  group_by(iso3, country) %>%
  summarise(
    n_rows = n(),
    n_checkable = sum(is.finite(usd_ratio)),
    median_portal_to_formula = ifelse(n_checkable > 0,
      median(usd_ratio[is.finite(usd_ratio)], na.rm = TRUE), NA_real_),
    statuses = paste(sort(unique(diagnostic_status)), collapse = "; "),
    .groups = "drop"
  )
write_csv(fx_diag, file.path(dir_docs, "unit_conversion_diagnostics.csv"), na = "")

# Paper-level descriptive diagnostics.
anom <- p %>%
  select(iso3, period, quarter, retention_gen, retention_fam) %>%
  pivot_longer(starts_with("retention_"), names_to = "series", values_to = "value") %>%
  filter(value > 100)
write_csv(anom, file.path(dir_docs, "retention_above_100.csv"), na = "")


# Robustness of the reporting-mode classification across all four contribution
# series. This deliberately repeats the classifier rather than assuming that
# general-branch gross contributions are representative.
detect_ytd_verify <- function(df, v) {
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

class_diag <- bind_rows(lapply(
  c("gwc_gen","gwc_fam","nwc_gen","nwc_fam"),
  function(v) detect_ytd_verify(p, v) %>% mutate(series = v, .before = 1)
))
write_csv(class_diag, file.path(dir_docs, "reporting_mode_robustness.csv"), na = "")

# All four contribution series must reproduce the same five-versus-two split.
for (v in unique(class_diag$series)) {
  got <- class_diag %>% filter(series == v, ytd) %>% pull(iso3) %>% sort()
  stopifnot(identical(sort(expected_ytd), got))
}
# In this source vintage all shares are exactly 0 or 1, so the classification
# is insensitive to any threshold in (0, 1].
stopifnot(all(class_diag$ytd_share %in% c(0, 1)))

# Between-jurisdiction variance share and leave-one-jurisdiction-out sensitivity.
between_share <- function(dat, var) {
  x <- dat %>% select(iso3, all_of(var)) %>% filter(!is.na(.data[[var]]))
  grand <- mean(x[[var]])
  m <- x %>% group_by(iso3) %>% summarise(mu = mean(.data[[var]]), n = n(), .groups = "drop")
  ss_between <- sum(m$n * (m$mu - grand)^2)
  ss_total <- sum((x[[var]] - grand)^2)
  ss_between / ss_total
}

loo_diag <- bind_rows(lapply(c("retention_gen","retention_fam"), function(v) {
  bind_rows(
    tibble(series = v, omitted_iso3 = "NONE", between_share = between_share(p, v)),
    bind_rows(lapply(sort(unique(p$iso3)), function(cc)
      tibble(series = v, omitted_iso3 = cc,
             between_share = between_share(p %>% filter(iso3 != cc), v))))
  )
}))
write_csv(loo_diag, file.path(dir_docs, "retention_variance_robustness.csv"), na = "")

# Internal reproducibility comparison against the deposited companion derivative
# shipped in the package, restricted to fields common to both files.
f_old <- file.path(dir_clean, "panel_takaful_uncert.csv")
if (file.exists(f_old)) {
  old <- read_csv(f_old, show_col_types = FALSE)
  new <- p
  common <- intersect(names(old), names(new))
  old2 <- old %>% arrange(iso3, period) %>% select(all_of(common))
  new2 <- new %>% arrange(iso3, period) %>% select(all_of(common))
  stopifnot(identical(paste(old2$iso3, old2$period), paste(new2$iso3, new2$period)))
  cmp <- all.equal(old2, new2, tolerance = 1e-6, check.attributes = FALSE)
  if (!isTRUE(cmp)) stop("Canonical panel differs from deposited derivative on common fields: ",
                         paste(cmp, collapse = "; "))
}

message("07_verify_release.R : ALL STRUCTURAL CHECKS PASSED")
