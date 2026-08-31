##################################################################################
#       Green Backlash in Colombia: Electoral Analysis (Petro Switchers)
#       Master R Script for Data Processing, Matching, and Switching Analysis
#
#       Autores: Brigitte Castañeda & Antigravity
#       Fecha: 25/08/2026
#
#       Inputs:
#       - data/electoral/raw/primera_vuelta_2021/partyfamily_shares.dta
#       - data/electoral/raw/primera_vuelta_2021/Data_Preparation_All_Elections_Covered_CMP.dta
#       - data/electoral/raw/primera_vuelta_2026/MUNICIPIO_PRESIDENTE_31-05-2026.xlsx
#
#       Outputs:
#       - data/electoral/processed/municipio_switching/petro_switching.csv
#################################################################################

library(haven)
library(readxl)
library(dplyr)
library(stringi)
library(tidyr)

# Clean string function for fuzzy matching
clean_string <- function(s) {
  s <- tolower(s)
  s <- stri_trans_general(s, "Latin-ASCII")
  s <- gsub("[^a-z0-9]", "", s)
  return(s)
}

cat("=== 1. PROCESSING 2022 ELECTION DATA ===\n")
pf_2022 <- read_dta("data/electoral/raw/primera_vuelta_2021/partyfamily_shares.dta") %>%
  filter(year == "2022")

# Standardize district code to 5 digits
pf_2022 <- pf_2022 %>%
  mutate(dane_code = sprintf("%05d", as.integer(district)))

# Load name mapping from CMP data
cmp <- read_dta("data/electoral/raw/primera_vuelta_2021/Data_Preparation_All_Elections_Covered_CMP.dta") %>%
  select(district, ADM1_ES, ADM2_ES) %>%
  distinct() %>%
  mutate(dane_code = sprintf("%05d", as.integer(district)))

# Keep unique names
cmp_unique <- cmp %>%
  group_by(dane_code) %>%
  summarize(
    ADM1_ES = first(ADM1_ES),
    ADM2_ES = first(ADM2_ES),
    .groups = "drop"
  )

# Extract Petro vote share and winner in 2022
votes_22 <- pf_2022 %>%
  group_by(dane_code) %>%
  mutate(
    is_winner = (pvs1 == max(pvs1, na.rm = TRUE))
  ) %>%
  ungroup()

petro_22 <- votes_22 %>%
  filter(candidatename == "gustavo_petro") %>%
  select(dane_code, pvs1_petro_2022 = pvs1, petro_winner_2022 = is_winner)

winner_22 <- votes_22 %>%
  filter(is_winner) %>%
  group_by(dane_code) %>%
  summarize(winner_name_2022 = first(candidatename), .groups = "drop")

# Merge
mun_22_summary <- cmp_unique %>%
  inner_join(petro_22, by = "dane_code") %>%
  left_join(winner_22, by = "dane_code")

cat("Processed", nrow(mun_22_summary), "municipalities from 2022.\n")


cat("\n=== 2. PROCESSING 2026 ELECTION DATA ===\n")
f2026 <- "data/electoral/raw/primera_vuelta_2026/MUNICIPIO_PRESIDENTE_31-05-2026.xlsx"
data_2026 <- read_excel(f2026)

data_2026_muns <- data_2026 %>%
  filter(DES_DD != "CONSULADOS")

muns_votes_26 <- data_2026_muns %>%
  group_by(COD_DDE, DES_DD, COD_MME, DES_MM, DES_CAN) %>%
  summarize(votes = sum(NUM_VOT, na.rm = TRUE), .groups = "drop")

muns_summary_26 <- muns_votes_26 %>%
  group_by(COD_DDE, DES_DD, COD_MME, DES_MM) %>%
  mutate(
    total_votes = sum(votes),
    vote_share = votes / total_votes,
    is_winner = (votes == max(votes))
  ) %>%
  ungroup()

cepeda_26 <- muns_summary_26 %>%
  filter(DES_CAN == "IVÁN CEPEDA CASTRO") %>%
  select(COD_DDE, DES_DD, COD_MME, DES_MM, 
         votes_cepeda_2026 = votes, 
         share_cepeda_2026 = vote_share, 
         cepeda_winner_2026 = is_winner,
         total_votes_2026 = total_votes)

winner_26 <- muns_summary_26 %>%
  filter(is_winner) %>%
  group_by(COD_DDE, DES_DD, COD_MME, DES_MM) %>%
  summarize(winner_name_2026 = first(DES_CAN), .groups = "drop")

mun_26_summary <- cepeda_26 %>%
  left_join(winner_26, by = c("COD_DDE", "DES_DD", "COD_MME", "DES_MM"))

cat("Processed", nrow(mun_26_summary), "municipalities from 2026.\n")


cat("\n=== 3. MATCHING MUNICIPALITIES BETWEEN 2022 AND 2026 ===\n")
dept_map <- c(
  "Amazonas" = "AMAZONAS", "Antioquia" = "ANTIOQUIA", "Arauca" = "ARAUCA",
  "Archipielago De San Andres, Providencia Y Santa Catalina" = "SAN ANDRES",
  "Atlantico" = "ATLANTICO", "Bogota, D.C." = "BOGOTA D.C.", "Bolivar" = "BOLIVAR",
  "Boyaca" = "BOYACA", "Caldas" = "CALDAS", "Caqueta" = "CAQUETA",
  "Casanare" = "CASANARE", "Cauca" = "CAUCA", "Cesar" = "CESAR",
  "Choco" = "CHOCO", "Cordoba" = "CORDOBA", "Cundinamarca" = "CUNDINAMARCA",
  "Guainia" = "GUAINIA", "Guaviare" = "GUAVIARE", "Huila" = "HUILA",
  "La Guajira" = "LA GUAJIRA", "Magdalena" = "MAGDALENA", "Meta" = "META",
  "Narino" = "NARIÑO", "Norte De Santander" = "NORTE DE SAN", "Putumayo" = "PUTUMAYO",
  "Quindio" = "QUINDIO", "Risaralda" = "RISARALDA", "Santander" = "SANTANDER",
  "Sucre" = "SUCRE", "Tolima" = "TOLIMA", "Valle Del Cauca" = "VALLE",
  "Vaupes" = "VAUPES", "Vichada" = "VICHADA"
)

mun_22_summary <- mun_22_summary %>%
  mutate(dept_2026 = dept_map[ADM1_ES], clean_mun = clean_string(ADM2_ES))

mun_26_summary <- mun_26_summary %>%
  mutate(clean_mun = clean_string(DES_MM))

# Exact matches
exact_matches <- mun_22_summary %>%
  inner_join(mun_26_summary, by = c("dept_2026" = "DES_DD", "clean_mun" = "clean_mun")) %>%
  mutate(match_type = "exact")

# Unmatched
unmatched_22 <- mun_22_summary %>%
  filter(!dane_code %in% exact_matches$dane_code)

unmatched_26 <- mun_26_summary %>%
  filter(!paste(DES_DD, clean_mun) %in% paste(exact_matches$dept_2026, exact_matches$clean_mun))

# Fuzzy match unmatched
fuzzy_matches <- list()
for (i in seq_len(nrow(unmatched_22))) {
  row_22 <- unmatched_22[i, ]
  dept <- row_22$dept_2026
  c_mun_22 <- row_22$clean_mun
  
  candidates_26 <- unmatched_26 %>% filter(DES_DD == dept)
  if (nrow(candidates_26) == 0) {
    candidates_26 <- mun_26_summary %>% filter(DES_DD == dept)
  }
  
  if (nrow(candidates_26) > 0) {
    # Check manual override for Vaupes / Papunahua / Papunagua
    if (row_22$dane_code == "97777") {
      papunagua_match <- candidates_26 %>% filter(clean_mun == "morichalpapunagua")
      if (nrow(papunagua_match) > 0) {
        fuzzy_matches[[length(fuzzy_matches) + 1]] <- bind_cols(row_22, papunagua_match[1, ]) %>%
          mutate(match_type = "manual")
        next
      }
    }
    
    # Substring match
    sub_idx <- NA
    for (j in seq_len(nrow(candidates_26))) {
      c_mun_26 <- candidates_26$clean_mun[j]
      if (grepl(c_mun_22, c_mun_26) || grepl(c_mun_26, c_mun_22)) {
        sub_idx <- j
        break
      }
    }
    
    if (!is.na(sub_idx)) {
      fuzzy_matches[[length(fuzzy_matches) + 1]] <- bind_cols(row_22, candidates_26[sub_idx, ]) %>%
        mutate(match_type = "substring")
    } else {
      # Levenshtein distance
      dists <- as.vector(adist(c_mun_22, candidates_26$clean_mun))
      best_idx <- which.min(dists)
      best_dist <- dists[best_idx]
      
      if (best_dist <= 5) {
        fuzzy_matches[[length(fuzzy_matches) + 1]] <- bind_cols(row_22, candidates_26[best_idx, ]) %>%
          mutate(match_type = "levenshtein")
      }
    }
  }
}

fuzzy_df <- bind_rows(fuzzy_matches)

# Combine
all_matched <- bind_rows(exact_matches, fuzzy_df)
cat("Matched", nrow(all_matched), "municipalities out of", nrow(mun_22_summary), "\n")


cat("\n=== 4. ANALYZING PETRO SWITCHERS ===\n")
# Clean and prepare final dataframe (renaming columns to English)
switching_df <- all_matched %>%
  select(
    dane_code,
    department = ADM1_ES,
    municipality = ADM2_ES,
    cod_dde_2026 = COD_DDE,
    cod_mme_2026 = COD_MME,
    municipality_2026 = DES_MM,
    pvs1_petro_2022,
    petro_winner_2022,
    winner_name_2022,
    share_cepeda_2026,
    cepeda_winner_2026,
    winner_name_2026,
    total_votes_2026,
    match_type
  ) %>%
  mutate(
    # Switched plurality winner: voted Petro in 2022 but not Cepeda in 2026
    switched_plurality = petro_winner_2022 & !cepeda_winner_2026,
    
    # Switched support (either won or had high vote share but decreased)
    petro_share_diff = share_cepeda_2026 - pvs1_petro_2022,
    
    # A Petro supporter binary
    petro_supporter_switched = if_else(petro_winner_2022, if_else(cepeda_winner_2026, "No Switch (Still Petro)", "Switched (Voted Petro before, not anymore)"), "Did not vote Petro before")
  )

# Write processed data
output_dir <- "data/electoral/processed/municipio_switching"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(switching_df, file.path(output_dir, "petro_switching.csv"), row.names = FALSE)

cat("\nSaved processed dataset in:", output_dir, "\n")



cat("\n=== 9. GENERATING GEOGRAPHIC MAPS ===\n")
# Download GeoJSON if not present
geojson_url <- "https://raw.githubusercontent.com/caticoa3/colombia_mapa/master/co_2018_MGN_MPIO_POLITICO.geojson"
geojson_path <- "data/electoral/processed/colombia_municipios.geojson"

if (file.exists(geojson_path)) {
  library(sf)
  
  cat("Reading GeoJSON map data...\n")
  colombia_map <- read_sf(geojson_path)
  
  # Standardize DANE codes
  final_df$dane_code_str <- sprintf("%05d", as.integer(final_df$dane_code))
  
  # Merge map and data
  map_data <- colombia_map %>%
    left_join(final_df, by = c("MPIO_CCNCT" = "dane_code_str"))
  
  # Map 1: switched_plurality
  cat("Plotting Map 1: switched_plurality...\n")
  map_data$switched_plurality_char <- as.character(map_data$switched_plurality)
  map_data$switched_plurality_char[is.na(map_data$switched_plurality_char)] <- "No Data"
  
  p_map1 <- ggplot(map_data) +
    geom_sf(aes(fill = switched_plurality_char), color = "#ffffff", size = 0.05) +
    scale_fill_manual(
      values = c("FALSE" = "#e0e0e0", "TRUE" = "#e41a1c", "No Data" = "#ffffff"),
      name = "Switched?"
    ) +
    theme_void() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
      legend.position = "bottom"
    ) +
    labs(title = "Plurality Winner Switch - 2022 vs 2026")
  
  # Map 2: petro_share_diff
  cat("Plotting Map 2: petro_share_diff...\n")
  max_diff <- max(abs(map_data$petro_share_diff), na.rm = TRUE)
  lim <- if (is.na(max_diff) || max_diff == 0) 0.3 else min(max_diff, 0.3)
  
  p_map2 <- ggplot(map_data) +
    geom_sf(aes(fill = petro_share_diff), color = "#ffffff", size = 0.05) +
    scale_fill_gradient2(
      low = "#ca0020",
      mid = "#f7f7f7",
      high = "#0571b0",
      midpoint = 0,
      limits = c(-lim, lim),
      oob = scales::squish,
      name = "Support Difference"
    ) +
    theme_void() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
      legend.position = "bottom"
    ) +
    labs(title = "Vote Share Difference (2026 - 2022)")
  
  # Map 3: petro_supporter_switched
  cat("Plotting Map 3: petro_supporter_switched...\n")
  map_data$petro_supporter_switched_factor <- factor(
    map_data$petro_supporter_switched,
    levels = c("Did not vote Petro before", "No Switch (Still Petro)", "Switched (Voted Petro before, not anymore)")
  )
  
  p_map3 <- ggplot(map_data) +
    geom_sf(aes(fill = petro_supporter_switched_factor), color = "#ffffff", size = 0.05) +
    scale_fill_manual(
      values = c(
        "Did not vote Petro before" = "#cccccc",
        "No Switch (Still Petro)" = "#3182bd",
        "Switched (Voted Petro before, not anymore)" = "#de2d26"
      ),
      na.value = "#ffffff",
      name = "Category"
    ) +
    theme_void() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
      legend.position = "bottom"
    ) +
    labs(title = "Electoral Support and Switch Classification")
  
  # Save plots
  ggsave(file.path(graph_dir, "map_switched_plurality.png"), plot = p_map1, width = 8, height = 10, dpi = 300)
  ggsave(file.path(graph_dir, "map_petro_share_diff.png"), plot = p_map2, width = 8, height = 10, dpi = 300)
  ggsave(file.path(graph_dir, "map_petro_supporter_switched.png"), plot = p_map3, width = 8, height = 10, dpi = 300)
  
  cat("Geographic maps generated and saved in:", graph_dir, "\n")
} else {
  cat("GeoJSON file not found. Skipping map generation.\n")
}

