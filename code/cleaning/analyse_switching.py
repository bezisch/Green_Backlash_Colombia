##################################################################################
#       Green Backlash in Colombia: Electoral Analysis (Petro Switchers)
#       Master Python Script for Data Processing, Matching, and Switching Analysis
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

import os
import re
import unicodedata
import pandas as pd
import numpy as np

# Clean string function for fuzzy matching
def clean_string(s):
    if not isinstance(s, str):
        return ""
    # Lowercase
    s = s.lower()
    # Remove accents/diacritics
    s = "".join(
        c for c in unicodedata.normalize('NFD', s)
        if unicodedata.category(c) != 'Mn'
    )
    # Remove non-alphanumeric
    s = re.sub(r'[^a-z0-9]', '', s)
    return s

# Levenshtein distance function in pure Python
def levenshtein_distance(s1, s2):
    if len(s1) < len(s2):
        return levenshtein_distance(s2, s1)
    if len(s2) == 0:
        return len(s1)
    
    previous_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (c1 != c2)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row
        
    return previous_row[-1]

print("=== 1. PROCESSING 2022 ELECTION DATA ===")
pf_2022 = pd.read_stata("data/electoral/raw/primera_vuelta_2021/partyfamily_shares.dta")
pf_2022 = pf_2022[pf_2022['year'] == "2022"].copy()

# Standardize district code to 5 digits
pf_2022['dane_code'] = pf_2022['district'].apply(
    lambda x: f"{int(float(x)):05d}" if pd.notna(x) and str(x).strip() != "" else ""
)

# Load name mapping from CMP data
cmp = pd.read_stata("data/electoral/raw/primera_vuelta_2021/Data_Preparation_All_Elections_Covered_CMP.dta")
cmp = cmp[['district', 'ADM1_ES', 'ADM2_ES']].drop_duplicates().copy()
cmp['dane_code'] = cmp['district'].apply(
    lambda x: f"{int(float(x)):05d}" if pd.notna(x) and str(x).strip() != "" else ""
)

# Keep first occurrence of each DANE code to avoid duplicates
cmp_unique = cmp.groupby('dane_code').first().reset_index()

# Extract Petro vote share and winner in 2022
pf_2022['is_winner'] = pf_2022.groupby('dane_code')['pvs1'].transform(lambda x: x == x.max())

petro_22 = pf_2022[pf_2022['candidatename'] == "gustavo_petro"][['dane_code', 'pvs1', 'is_winner']].copy()
petro_22.rename(columns={'pvs1': 'pvs1_petro_2022', 'is_winner': 'petro_winner_2022'}, inplace=True)

winner_22 = pf_2022[pf_2022['is_winner']].groupby('dane_code').first().reset_index()[['dane_code', 'candidatename']]
winner_22.rename(columns={'candidatename': 'winner_name_2022'}, inplace=True)

# Merge
mun_22_summary = cmp_unique.merge(petro_22, on='dane_code', how='inner')
mun_22_summary = mun_22_summary.merge(winner_22, on='dane_code', how='left')
print(f"Processed {len(mun_22_summary)} municipalities from 2022.")


print("\n=== 2. PROCESSING 2026 ELECTION DATA ===")
f2026 = "data/electoral/raw/primera_vuelta_2026/MUNICIPIO_PRESIDENTE_31-05-2026.xlsx"
data_2026 = pd.read_excel(f2026)

# Exclude Consulados
data_2026_muns = data_2026[data_2026['DES_DD'] != "CONSULADOS"].copy()

# Sum votes by department, municipality, and candidate
muns_votes_26 = data_2026_muns.groupby(['COD_DDE', 'DES_DD', 'COD_MME', 'DES_MM', 'DES_CAN'])['NUM_VOT'].sum().reset_index()
muns_votes_26.rename(columns={'NUM_VOT': 'votes'}, inplace=True)

# Calculate total votes in each municipality and winner
muns_votes_26['total_votes'] = muns_votes_26.groupby(['COD_DDE', 'DES_DD', 'COD_MME', 'DES_MM'])['votes'].transform('sum')
muns_votes_26['vote_share'] = muns_votes_26['votes'] / muns_votes_26['total_votes']
muns_votes_26['is_winner'] = muns_votes_26['votes'] == muns_votes_26.groupby(['COD_DDE', 'DES_DD', 'COD_MME', 'DES_MM'])['votes'].transform('max')

# Extract Cepeda votes and winner in 2026
cepeda_26 = muns_votes_26[muns_votes_26['DES_CAN'] == "IVÁN CEPEDA CASTRO"][
    ['COD_DDE', 'DES_DD', 'COD_MME', 'DES_MM', 'votes', 'vote_share', 'is_winner', 'total_votes']
].copy()
cepeda_26.rename(columns={
    'votes': 'votes_cepeda_2026',
    'vote_share': 'share_cepeda_2026',
    'is_winner': 'cepeda_winner_2026',
    'total_votes': 'total_votes_2026'
}, inplace=True)

winner_26 = muns_votes_26[muns_votes_26['is_winner']].groupby(['COD_DDE', 'DES_DD', 'COD_MME', 'DES_MM']).first().reset_index()[
    ['COD_DDE', 'DES_DD', 'COD_MME', 'DES_MM', 'DES_CAN']
]
winner_26.rename(columns={'DES_CAN': 'winner_name_2026'}, inplace=True)

# Merge
mun_26_summary = cepeda_26.merge(winner_26, on=['COD_DDE', 'DES_DD', 'COD_MME', 'DES_MM'], how='left')
print(f"Processed {len(mun_26_summary)} municipalities from 2026.")


print("\n=== 3. MATCHING MUNICIPALITIES BETWEEN 2022 AND 2026 ===")
dept_map = {
    "Amazonas": "AMAZONAS", "Antioquia": "ANTIOQUIA", "Arauca": "ARAUCA",
    "Archipielago De San Andres, Providencia Y Santa Catalina": "SAN ANDRES",
    "Atlantico": "ATLANTICO", "Bogota, D.C.": "BOGOTA D.C.", "Bolivar": "BOLIVAR",
    "Boyaca": "BOYACA", "Caldas": "CALDAS", "Caqueta": "CAQUETA",
    "Casanare": "CASANARE", "Cauca": "CAUCA", "Cesar": "CESAR",
    "Choco": "CHOCO", "Cordoba": "CORDOBA", "Cundinamarca": "CUNDINAMARCA",
    "Guainia": "GUAINIA", "Guaviare": "GUAVIARE", "Huila": "HUILA",
    "La Guajira": "LA GUAJIRA", "Magdalena": "MAGDALENA", "Meta": "META",
    "Narino": "NARIÑO", "Norte De Santander": "NORTE DE SAN", "Putumayo": "PUTUMAYO",
    "Quindio": "QUINDIO", "Risaralda": "RISARALDA", "Santander": "SANTANDER",
    "Sucre": "SUCRE", "Tolima": "TOLIMA", "Valle Del Cauca": "VALLE",
    "Vaupes": "VAUPES", "Vichada": "VICHADA"
}

mun_22_summary['dept_2026'] = mun_22_summary['ADM1_ES'].map(dept_map)
mun_22_summary['clean_mun'] = mun_22_summary['ADM2_ES'].apply(clean_string)
mun_26_summary['clean_mun'] = mun_26_summary['DES_MM'].apply(clean_string)

# Find exact matches
exact_matches = mun_22_summary.merge(mun_26_summary, left_on=['dept_2026', 'clean_mun'], right_on=['DES_DD', 'clean_mun'], how='inner')
exact_matches['match_type'] = 'exact'

# Identify unmatched
matched_dane_codes = set(exact_matches['dane_code'])
unmatched_22 = mun_22_summary[~mun_22_summary['dane_code'].isin(matched_dane_codes)].copy()

matched_26_keys = set(zip(exact_matches['DES_DD'], exact_matches['clean_mun']))
unmatched_26 = mun_26_summary[~mun_26_summary.apply(lambda r: (r['DES_DD'], r['clean_mun']) in matched_26_keys, axis=1)].copy()

# Fuzzy match unmatched 2022
fuzzy_rows = []
for idx, row_22 in unmatched_22.iterrows():
    dept = row_22['dept_2026']
    c_mun_22 = row_22['clean_mun']
    dane_code = row_22['dane_code']
    
    candidates_26 = unmatched_26[unmatched_26['DES_DD'] == dept]
    if len(candidates_26) == 0:
        candidates_26 = mun_26_summary[mun_26_summary['DES_DD'] == dept]
        
    if len(candidates_26) > 0:
        # Check manual override for Vaupes / Papunahua / Papunagua
        if dane_code == "97777":
            papunagua_match = candidates_26[candidates_26['clean_mun'] == "morichalpapunagua"]
            if len(papunagua_match) > 0:
                match_row = papunagua_match.iloc[0]
                combined = {**row_22.to_dict(), **match_row.to_dict(), 'match_type': 'manual'}
                fuzzy_rows.append(combined)
                continue
                
        # Substring match
        sub_match_idx = None
        for j, cand in candidates_26.iterrows():
            c_mun_26 = cand['clean_mun']
            if (c_mun_22 in c_mun_26) or (c_mun_26 in c_mun_22):
                sub_match_idx = j
                break
                
        if sub_match_idx is not None:
            match_row = candidates_26.loc[sub_match_idx]
            combined = {**row_22.to_dict(), **match_row.to_dict(), 'match_type': 'substring'}
            fuzzy_rows.append(combined)
        else:
            # Levenshtein distance
            dists = [levenshtein_distance(c_mun_22, cand['clean_mun']) for _, cand in candidates_26.iterrows()]
            best_idx = np.argmin(dists)
            best_dist = dists[best_idx]
            
            if best_dist <= 5:
                match_row = candidates_26.iloc[best_idx]
                combined = {**row_22.to_dict(), **match_row.to_dict(), 'match_type': 'levenshtein'}
                fuzzy_rows.append(combined)

if fuzzy_rows:
    fuzzy_df = pd.DataFrame(fuzzy_rows)
    all_matched = pd.concat([exact_matches, fuzzy_df], ignore_index=True)
else:
    all_matched = exact_matches.copy()

print(f"Matched {len(all_matched)} municipalities out of {len(mun_22_summary)}.")


print("\n=== 4. ANALYZING PETRO SWITCHERS ===")
# Clean and prepare final dataframe (renaming columns to English)
switching_df = all_matched[[
    'dane_code', 'ADM1_ES', 'ADM2_ES', 'COD_DDE', 'COD_MME', 'DES_MM',
    'pvs1_petro_2022', 'petro_winner_2022', 'winner_name_2022',
    'share_cepeda_2026', 'cepeda_winner_2026', 'winner_name_2026',
    'total_votes_2026', 'match_type'
]].copy()

switching_df.rename(columns={
    'ADM1_ES': 'department',
    'ADM2_ES': 'municipality',
    'COD_DDE': 'cod_dde_2026',
    'COD_MME': 'cod_mme_2026',
    'DES_MM': 'municipality_2026'
}, inplace=True)

# Flags
switching_df['switched_plurality'] = switching_df['petro_winner_2022'] & ~switching_df['cepeda_winner_2026']
switching_df['petro_share_diff'] = switching_df['share_cepeda_2026'] - switching_df['pvs1_petro_2022']

# Supporter switch classification
def classify_switcher(row):
    if row['petro_winner_2022']:
        if row['cepeda_winner_2026']:
            return "No Switch (Still Petro)"
        else:
            return "Switched (Voted Petro before, not anymore)"
    else:
        return "Did not vote Petro before"

switching_df['petro_supporter_switched'] = switching_df.apply(classify_switcher, axis=1)

# Write output files
output_dir = "data/electoral/processed/municipio_switching"
os.makedirs(output_dir, exist_ok=True)

csv_path = os.path.join(output_dir, "petro_switching.csv")
switching_df.to_csv(csv_path, index=False)

print(f"\nSaved processed dataset in: {output_dir}")
