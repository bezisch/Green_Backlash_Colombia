##################################################################################
#       Green Backlash in Colombia: Municipality-Year Energy & Mining Panel
#       Master R Script to Create a Harmonized Panel (2018–2026)
#
#       Authors: Brigitte Castañeda & Antigravity
#       Date: October 2026
#
#       Inputs:
#       - data/electoral/processed/colombia_municipios.geojson
#       - data/energy_mining/all_minerals/ANM_Volúmen_de_Explotación_de_Minerales_Asociados_a_Pagos_de_Regalías_20260702.csv
#       - data/energy_mining/oil_gas/Consolidación_de_liquidación_de_regalías_por_campo_20260702.csv.gz
#       - data/energy_mining/solar/Proyectos de generación solar (XM).csv
#
#       Outputs:
#       - data/energy_mining/processed/municipality_year_energy_mining_panel_2018_2026.csv
#       - data/energy_mining/processed/municipality_year_energy_mining_panel_2018_2026.rds
#################################################################################

library(readr)
library(dplyr)
library(tidyr)
library(sf)
library(stringi)

# String cleaning helper function for fuzzy string matching
clean_string <- function(s) {
  s <- tolower(s)
  s <- stri_trans_general(s, "Latin-ASCII")
  s <- gsub("[^a-z0-9]", "", s)
  return(s)
}

# Numeric character cleaner helper function
clean_num <- function(x) {
  x <- as.character(x)
  x <- gsub(",", "", x)
  x <- gsub(" ", "", x)
  x <- gsub("-", "", x)
  x[x == "" | is.na(x)] <- "0"
  return(as.numeric(x))
}

cat("=== 1. BUILDING BALANCED MUNICIPALITY-YEAR GRID (2018-2026) ===\n")
geo_path <- "data/electoral/processed/colombia_municipios.geojson"
geo <- st_read(geo_path, quiet = TRUE)

geo_muns <- geo %>% 
  as.data.frame() %>% 
  transmute(
    dane_code = sprintf("%05d", as.integer(MPIO_CCNCT)),
    dept_code = sprintf("%02d", as.integer(DPTO_CCDGO)),
    dept_name = DPTO_CNMBR,
    mun_name = MPIO_CNMBR,
    dept_clean = clean_string(DPTO_CNMBR),
    mun_clean = clean_string(MPIO_CNMBR)
  ) %>% 
  distinct(dane_code, .keep_all = TRUE)

years <- 2018:2026
panel_base <- expand_grid(dane_code = geo_muns$dane_code, year = years) %>%
  left_join(geo_muns %>% select(dane_code, dept_code, dept_name, mun_name), by = "dane_code")

cat("Base Grid Created: ", nrow(panel_base), " rows (", n_distinct(panel_base$dane_code), " municipalities x ", length(years), " years)\n", sep="")

# -----------------------------------------------------------------------------
# 2. MINING DATA (ANM 2018-2026)
# -----------------------------------------------------------------------------
cat("\n=== 2. PROCESSING MINING DATA (ANM) ===\n")
anm_path <- "data/energy_mining/all_minerals/ANM_Volúmen_de_Explotación_de_Minerales_Asociados_a_Pagos_de_Regalías_20260702.csv"
minerals <- read_csv(anm_path, show_col_types = FALSE)

minerals_clean <- minerals %>%
  filter(`Año Liquidado` >= 2018 & `Año Liquidado` <= 2026) %>%
  mutate(
    dane_code = sprintf("%05d", as.integer(`Codigo DANE`)),
    year = as.integer(`Año Liquidado`),
    regalias_cop = ifelse(is.na(`Regalías pagadas`), 0, `Regalías pagadas`),
    volumen_num = clean_num(`Volúmenes de explotación`),
    recurso = toupper(trimws(`Recurso Natural`))
  )

mining_agg <- minerals_clean %>%
  group_by(dane_code, year) %>%
  summarise(
    mining_royalties_total_cop = sum(regalias_cop, na.rm = TRUE),
    mining_royalties_coal_cop = sum(regalias_cop[grepl("CARBON", recurso)], na.rm = TRUE),
    mining_royalties_gold_cop = sum(regalias_cop[recurso == "ORO"], na.rm = TRUE),
    mining_royalties_nickel_cop = sum(regalias_cop[recurso == "NIQUEL"], na.rm = TRUE),
    mining_royalties_copper_cop = sum(regalias_cop[recurso == "COBRE"], na.rm = TRUE),
    mining_royalties_emeralds_cop = sum(regalias_cop[grepl("ESMERALDA", recurso)], na.rm = TRUE),
    mining_royalties_platinum_cop = sum(regalias_cop[recurso == "PLATINO"], na.rm = TRUE),
    mining_royalties_other_cop = sum(regalias_cop[!grepl("CARBON|ORO|NIQUEL|COBRE|ESMERALDA|PLATINO", recurso)], na.rm = TRUE),
    mining_vol_coal_ton = sum(volumen_num[grepl("CARBON", recurso)], na.rm = TRUE),
    mining_vol_gold_g = sum(volumen_num[recurso == "ORO"], na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(mining_has_activity = ifelse(mining_royalties_total_cop > 0 | mining_vol_coal_ton > 0 | mining_vol_gold_g > 0, 1, 0))

# -----------------------------------------------------------------------------
# 3. OIL AND GAS DATA (ANH CONSOLIDADO 2018-2026)
# -----------------------------------------------------------------------------
cat("\n=== 3. PROCESSING OIL & GAS DATA (ANH CONSOLIDADO) ===\n")
oilgas_path <- "data/energy_mining/oil_gas/Consolidación_de_liquidación_de_regalías_por_campo_20260702.csv.gz"
oilgas <- read_csv(oilgas_path, show_col_types = FALSE)

# Normalize department and municipality names
oilgas_clean <- oilgas %>%
  filter(Año >= 2018 & Año <= 2026) %>%
  mutate(
    dept_norm = case_when(
      clean_string(Departamento) == "guajira" ~ "la guajira",
      TRUE ~ tolower(Departamento)
    ),
    mun_norm = case_when(
      clean_string(Municipio) == "lajaguaibirico" ~ "la jagua de ibirico",
      clean_string(Municipio) == "castillanueva" ~ "castilla la nueva",
      clean_string(Municipio) == "cucuta" ~ "san jose de cucuta",
      clean_string(Municipio) == "sanjosedefragua" ~ "san jose del fragua",
      clean_string(Municipio) == "sancaarlosguaroa" ~ "san carlos de guaroa",
      clean_string(Municipio) == "since" ~ "san luis de since",
      clean_string(Municipio) == "sansebastianbuenavista" ~ "san sebastian de buenavista",
      clean_string(Municipio) == "pazdelrio" ~ "paz de rio",
      TRUE ~ tolower(Municipio)
    ),
    dept_clean = clean_string(dept_norm),
    mun_clean = clean_string(mun_norm)
  ) %>%
  left_join(geo_muns %>% select(dane_code, dept_clean, mun_clean), by = c("dept_clean", "mun_clean"))

# Compute annual average TRM (exchange rate USD/COP)
trm_annual <- oilgas %>%
  filter(Año >= 2018 & Año <= 2026 & !is.na(TrmPromedio) & TrmPromedio > 0) %>%
  group_by(year = as.integer(Año)) %>%
  summarise(trm_avg = mean(TrmPromedio, na.rm = TRUE), .groups = "drop")

oilgas_agg <- oilgas_clean %>%
  filter(!is.na(dane_code)) %>%
  group_by(dane_code, year = as.integer(Año)) %>%
  summarise(
    oil_prod_bbl = sum(ProdGravableBlsKpc[TipoHidrocarburo == "O"], na.rm = TRUE),
    gas_prod_kpc = sum(ProdGravableBlsKpc[TipoHidrocarburo == "G"], na.rm = TRUE),
    oil_royalties_cop = sum(RegaliasCOP[TipoHidrocarburo == "O"], na.rm = TRUE),
    gas_royalties_cop = sum(RegaliasCOP[TipoHidrocarburo == "G"], na.rm = TRUE),
    oilgas_royalties_total_cop = sum(RegaliasCOP, na.rm = TRUE),
    oilgas_active_fields_count = n_distinct(Campo[!is.na(Campo)]),
    .groups = "drop"
  ) %>%
  mutate(
    oilgas_total_prod_boe = oil_prod_bbl + (gas_prod_kpc / 5.615),
    oilgas_has_activity = ifelse(oilgas_royalties_total_cop > 0 | oil_prod_bbl > 0 | gas_prod_kpc > 0, 1, 0)
  )

# -----------------------------------------------------------------------------
# 4. RENEWABLES DATA (SOLAR XM 2018-2026)
# -----------------------------------------------------------------------------
cat("\n=== 4. PROCESSING SOLAR ENERGY DATA (XM) ===\n")
solar_path <- "data/energy_mining/solar/Proyectos de generación solar (XM).csv"
solar <- read_delim(solar_path, delim = ";", show_col_types = FALSE)

solar_clean <- solar %>%
  mutate(
    dane_code = sprintf("%05d", as.integer(`Código del municipio`)),
    fpo_year = as.integer(`Año de puesta en operación (fpo)`),
    capacity_mw = ifelse(is.na(`Capacidad efectiva neta [MW]`), 0, `Capacidad efectiva neta [MW]`)
  ) %>%
  filter(!is.na(dane_code) & !is.na(fpo_year) & fpo_year >= 2010 & fpo_year <= 2026)

# Aggregate new capacity and projects by municipality-year
solar_annual <- solar_clean %>%
  group_by(dane_code, year = fpo_year) %>%
  summarise(
    solar_projects_new = n(),
    solar_capacity_mw_new = sum(capacity_mw, na.rm = TRUE),
    .groups = "drop"
  )

# Complete solar grid for all municipalities and compute cumulative metrics
solar_grid <- expand_grid(dane_code = geo_muns$dane_code, year = years) %>%
  left_join(solar_annual, by = c("dane_code", "year")) %>%
  mutate(
    solar_projects_new = ifelse(is.na(solar_projects_new), 0, solar_projects_new),
    solar_capacity_mw_new = ifelse(is.na(solar_capacity_mw_new), 0, solar_capacity_mw_new)
  ) %>%
  arrange(dane_code, year) %>%
  group_by(dane_code) %>%
  mutate(
    solar_projects_cum = cumsum(solar_projects_new),
    solar_capacity_mw_cum = cumsum(solar_capacity_mw_new),
    solar_has_project = ifelse(solar_capacity_mw_cum > 0 | solar_projects_cum > 0, 1, 0)
  ) %>%
  ungroup()

# -----------------------------------------------------------------------------
# 5. MERGING ALL SECTORS INTO HARMONIZED PANEL
# -----------------------------------------------------------------------------
cat("\n=== 5. MERGING SECTORS INTO FINAL PANEL ===\n")

panel <- panel_base %>%
  left_join(mining_agg, by = c("dane_code", "year")) %>%
  left_join(oilgas_agg, by = c("dane_code", "year")) %>%
  left_join(solar_grid %>% select(dane_code, year, solar_projects_new, solar_capacity_mw_new, solar_projects_cum, solar_capacity_mw_cum, solar_has_project), by = c("dane_code", "year")) %>%
  left_join(trm_annual, by = "year")

# Replace NAs with 0s for numeric indicators
numeric_vars <- c(
  "mining_royalties_total_cop", "mining_royalties_coal_cop", "mining_royalties_gold_cop",
  "mining_royalties_nickel_cop", "mining_royalties_copper_cop", "mining_royalties_emeralds_cop",
  "mining_royalties_platinum_cop", "mining_royalties_other_cop", "mining_vol_coal_ton",
  "mining_vol_gold_g", "mining_has_activity",
  "oil_prod_bbl", "gas_prod_kpc", "oil_royalties_cop", "gas_royalties_cop",
  "oilgas_royalties_total_cop", "oilgas_active_fields_count", "oilgas_total_prod_boe",
  "oilgas_has_activity",
  "solar_projects_new", "solar_capacity_mw_new", "solar_projects_cum", "solar_capacity_mw_cum",
  "solar_has_project"
)

panel[numeric_vars] <- lapply(panel[numeric_vars], function(x) ifelse(is.na(x), 0, x))

# Calculate USD Royalties and Combined Energy & Extractive Indicators
panel <- panel %>%
  mutate(
    trm_avg = ifelse(is.na(trm_avg), 4000, trm_avg),
    mining_royalties_total_usd = mining_royalties_total_cop / trm_avg,
    oilgas_royalties_total_usd = oilgas_royalties_total_cop / trm_avg,
    extractive_royalties_total_cop = mining_royalties_total_cop + oilgas_royalties_total_cop,
    extractive_royalties_total_usd = mining_royalties_total_usd + oilgas_royalties_total_usd,
    has_any_extractive_activity = ifelse(mining_has_activity == 1 | oilgas_has_activity == 1, 1, 0),
    has_any_energy_mining_activity = ifelse(has_any_extractive_activity == 1 | solar_has_project == 1, 1, 0)
  )

# Reorder columns logically
panel <- panel %>%
  select(
    dane_code, year, dept_code, dept_name, mun_name, trm_avg,
    # Mining
    mining_has_activity, mining_royalties_total_cop, mining_royalties_total_usd,
    mining_royalties_coal_cop, mining_royalties_gold_cop, mining_royalties_nickel_cop,
    mining_royalties_copper_cop, mining_royalties_emeralds_cop, mining_royalties_platinum_cop,
    mining_royalties_other_cop, mining_vol_coal_ton, mining_vol_gold_g,
    # Oil & Gas
    oilgas_has_activity, oil_prod_bbl, gas_prod_kpc, oilgas_total_prod_boe,
    oil_royalties_cop, gas_royalties_cop, oilgas_royalties_total_cop, oilgas_royalties_total_usd,
    oilgas_active_fields_count,
    # Solar Renewables
    solar_has_project, solar_projects_new, solar_capacity_mw_new, solar_projects_cum, solar_capacity_mw_cum,
    # Combined Summary Totals
    extractive_royalties_total_cop, extractive_royalties_total_usd,
    has_any_extractive_activity, has_any_energy_mining_activity
  )

cat("Final Panel Rows:", nrow(panel), "\n")
cat("Final Panel Columns:", ncol(panel), "\n")

# -----------------------------------------------------------------------------
# 6. SAVE OUTPUTS
# -----------------------------------------------------------------------------
output_dir <- "data/energy_mining/processed"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

csv_out <- file.path(output_dir, "municipality_year_energy_mining_panel_2018_2026.csv")
rds_out <- file.path(output_dir, "municipality_year_energy_mining_panel_2018_2026.rds")

write_csv(panel, csv_out)
saveRDS(panel, rds_out)

cat("\nOutputs saved successfully:\n - ", csv_out, "\n - ", rds_out, "\n", sep="")
cat("=== PANEL CREATION COMPLETED SUCCESSFULLY! ===\n")
