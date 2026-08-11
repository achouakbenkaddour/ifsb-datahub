# =============================================================================
# 00_setup.R — IFSB-DataHub
# Chemins, packages, table de correspondance pays -> ISO3
# Exécuter en premier ; est "source()" par tous les autres scripts.
# =============================================================================

suppressPackageStartupMessages({
  library(readxl)   # lecture xlsx
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(purrr)
  library(readr)
  library(openxlsx) # écriture xlsx (dictionnaire)
})

# --- Racine du projet : à adapter si besoin ---------------------------------
# setwd("chemin/vers/IFSB-DataHub")   # <- décommenter et adapter en local
dir_raw   <- file.path("raw", "ifsb")
dir_clean <- "clean"
dir_docs  <- "docs"
dir_fig   <- "figures"
for (d in c(dir_clean, dir_docs, dir_fig)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)

# --- Correspondance pays -> ISO3 (clé d'harmonisation du hub) ---------------
country_map <- tribble(
  ~country_raw,            ~iso3, ~country,
  "Afghanistan",           "AFG", "Afghanistan",
  "Bahrain",               "BHR", "Bahrain",
  "Bangladesh",            "BGD", "Bangladesh",
  "Brunei Darussalam",     "BRN", "Brunei Darussalam",
  "Egypt",                 "EGY", "Egypt",
  "Indonesia",             "IDN", "Indonesia",
  "Iran",                  "IRN", "Iran",
  "Iraq",                  "IRQ", "Iraq",
  "Jordan",                "JOR", "Jordan",
  "Kazakhstan",            "KAZ", "Kazakhstan",
  "Kenya",                 "KEN", "Kenya",
  "Kuwait",                "KWT", "Kuwait",
  "Kyrgyz Republic",       "KGZ", "Kyrgyz Republic",
  "Lebanon",               "LBN", "Lebanon",
  "Libya",                 "LBY", "Libya",
  "Malaysia",              "MYS", "Malaysia",
  "Morocco",               "MAR", "Morocco",
  "Nigeria",               "NGA", "Nigeria",
  "Oman",                  "OMN", "Oman",
  "Pakistan",              "PAK", "Pakistan",
  "Palestine",             "PSE", "Palestine",
  "Qatar",                 "QAT", "Qatar",
  "Saudi Arabia",          "SAU", "Saudi Arabia",
  "Sudan",                 "SDN", "Sudan",
  "Turkey",                "TUR", "Turkey",
  "United Arab Emirates",  "ARE", "United Arab Emirates",
  "United Kingdom",        "GBR", "United Kingdom"
)

# --- Utilitaires -------------------------------------------------------------
# Décompose "2019Q1" -> year = 2019, quarter = 1
split_period <- function(x) {
  tibble(
    year    = as.integer(str_sub(x, 1, 4)),
    quarter = as.integer(str_sub(x, 6, 6))
  )
}

# Nettoie une valeur numérique (gère "…", espaces, virgules)
clean_num <- function(v) {
  v <- str_trim(as.character(v))
  v[v %in% c("…", "", "-", "N/A", "NA", "n.a.")] <- NA
  as.numeric(str_replace_all(v, ",", ""))
}

message("00_setup.R : OK — ", nrow(country_map), " pays dans la table ISO3.")
