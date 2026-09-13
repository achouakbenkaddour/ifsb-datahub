# =============================================================================
# 00_setup.R — IFSB-DataHub
# Shared paths, packages, country map, numeric helpers, and SHA-256 utilities.
# Run directly once to initialise folders and print checksums for raw source files.
# Other scripts source() this file; checksum printing occurs only when run directly.
# =============================================================================

required_packages <- c("readxl", "dplyr", "tidyr", "stringr", "purrr",
                       "readr", "openxlsx", "digest")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace,
                                               quietly = TRUE, FUN.VALUE = logical(1))]
if (length(missing_packages) > 0) {
  stop("Missing R packages: ", paste(missing_packages, collapse = ", "),
       ". Install them before running the pipeline.")
}

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(purrr)
  library(readr)
  library(openxlsx)
})

# Run all scripts from the repository root.
dir_raw   <- file.path("raw", "ifsb")
dir_clean <- "clean"
dir_docs  <- "docs"
dir_fig   <- "figures"
for (d in c(dir_clean, dir_docs, dir_fig)) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

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

split_period <- function(x) {
  tibble(
    year    = as.integer(str_sub(x, 1, 4)),
    quarter = as.integer(str_sub(x, 6, 6))
  )
}

clean_num <- function(v) {
  v <- str_trim(as.character(v))
  v[v %in% c("…", "", "-", "N/A", "NA", "n.a.")] <- NA
  suppressWarnings(as.numeric(str_replace_all(v, ",", "")))
}

sha256_file <- function(path) {
  if (!file.exists(path)) return(NA_character_)
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

print_raw_checksums <- function(raw_dir = dir_raw) {
  if (!dir.exists(raw_dir)) {
    message("No raw/ifsb directory found; create it and download source files first.")
    return(invisible(NULL))
  }
  files <- sort(list.files(raw_dir, full.names = TRUE))
  files <- files[file.info(files)$isdir %in% FALSE]
  if (length(files) == 0) {
    message("raw/ifsb exists but contains no files.")
    return(invisible(NULL))
  }
  out <- tibble(file = basename(files), sha256 = vapply(files, sha256_file, character(1)))
  print(out, n = Inf)
  invisible(out)
}

message("00_setup.R : OK — ", nrow(country_map), " countries in ISO3 map.")
if (sys.nframe() == 0L) print_raw_checksums()
