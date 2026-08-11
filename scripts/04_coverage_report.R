# =============================================================================
# 04_coverage_report.R — IFSB-DataHub
# Cartes de couverture (pays x trimestre) par segment -> figures/*.png
# À relancer après chaque mise à jour des données.
# =============================================================================
source(file.path("scripts", "00_setup.R"))

master <- readRDS(file.path(dir_clean, "master_panel.rds"))

plot_coverage <- function(seg) {
  cov <- master %>%
    filter(segment == seg, !is.na(value_nc)) %>%
    count(country, period)
  if (nrow(cov) == 0) return(invisible(NULL))

  periods   <- sort(unique(cov$period))
  countries <- sort(unique(cov$country), decreasing = TRUE)
  mat <- cov %>%
    complete(country = countries, period = periods, fill = list(n = 0)) %>%
    mutate(country = factor(country, levels = countries),
           period  = factor(period,  levels = periods))

  png(file.path(dir_fig, paste0("coverage_", seg, ".png")),
      width = 1400, height = 200 + 40 * length(countries), res = 120)
  par(mar = c(6, 12, 3, 1))
  z <- xtabs(n ~ country + period, data = mat)
  image(x = seq_along(periods), y = seq_along(countries), z = t(z),
        col = hcl.colors(20, "YlGn"), axes = FALSE, xlab = "", ylab = "",
        main = paste0("Couverture PSIFIs — ", seg,
                      " (points de données non manquants)"))
  axis(1, at = seq_along(periods), labels = periods, las = 2, cex.axis = .7)
  axis(2, at = seq_along(countries), labels = countries, las = 1, cex.axis = .8)
  box()
  dev.off()
  message("figures/coverage_", seg, ".png : OK")
}

walk(unique(master$segment), plot_coverage)
message("04_coverage_report.R : OK")
