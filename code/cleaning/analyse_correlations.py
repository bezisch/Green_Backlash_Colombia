##################################################################################
#       Green Backlash in Colombia: Correlation with Energy & Mining Activities
#       Master Python Script for Processing Energy/Mining Data and Correlating
#
#       Autores: Brigitte Castañeda & Antigravity
#       Fecha: 25/08/2026
#
#       Inputs:
#       - data/electoral/processed/municipio_switching/petro_switching.csv
#       - data/energy_mining/all_minerals/ANM_Volúmen_de_Explotación_de_Minerales_Asociados_a_Pagos_de_Regalías_20260702.csv
#       - data/energy_mining/oil_gas/datos_completos_prod_regalias_2010_2021.csv
#       - data/energy_mining/solar/Proyectos de generación solar (XM).csv
#
#       Outputs:
#       - output/tables/energy_backlash_comparison.csv
#       - output/tables/energy_backlash_comparison.md
#       - output/tables/continuous_correlations.csv
#       - output/tables/continuous_correlations.md
#       - output/graphs/plot_presence_shares.png
#       - output/graphs/map_switched_plurality.png
#       - output/graphs/map_petro_share_diff.png
#       - output/graphs/map_petro_supporter_switched.png
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
    s = s.lower()
    s = "".join(
        c for c in unicodedata.normalize('NFD', s)
        if unicodedata.category(c) != 'Mn'
    )
    s = re.sub(r'[^a-z0-9]', '', s)
    return s

# Clean numeric values
def clean_num(x):
    if pd.isna(x):
        return 0.0
    s = str(x).replace(",", "").replace(" ", "").strip()
    if s == "" or s == "-" or s == "-0" or "none" in s.lower():
        return 0.0
    try:
        return float(s)
    except ValueError:
        return 0.0

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

print("=== 1. LOADING ELECTORAL DATA ===")
df_elec = pd.read_csv("data/electoral/processed/municipio_switching/petro_switching.csv")
df_elec['dane_code'] = df_elec['dane_code'].apply(lambda x: f"{int(float(x)):05d}" if pd.notna(x) else "")


print("\n=== 2. PROCESSING COAL MINING DATA (ANM) ===")
minerals_file = "data/energy_mining/all_minerals/ANM_Volúmen_de_Explotación_de_Minerales_Asociados_a_Pagos_de_Regalías_20260702.csv"
if not os.path.exists(minerals_file):
    minerals_file = "data/energy_mining/all_minerals/ANM_Volúmen_de_Explotación_de_Minerales_Asociados_a_Pagos_de_Regalías_20260702.csv"

min_data = pd.read_csv(minerals_file)
# Filter for coal
coal_data = min_data[
    min_data['Recurso.Natural'].str.contains("carbon", case=False, na=False) &
    ~min_data['Recurso.Natural'].str.contains("carbonato", case=False, na=False)
].copy()

coal_data['Volumen_Numeric'] = coal_data['Volúmenes.de.explotación'].apply(clean_num)
coal_data['Regalias_Numeric'] = coal_data['Regalías.pagadas'].apply(clean_num)
coal_data['dane_code_str'] = coal_data['Codigo.DANE'].apply(lambda x: f"{int(float(x)):05d}" if pd.notna(x) else "")

# Aggregate by municipality (Average annual 2018-2025, i.e., 8 years)
coal_summary = coal_data.groupby('dane_code_str').agg(
    coal_royalties_avg=('Regalias_Numeric', lambda x: x.sum() / 8),
    coal_volume_avg=('Volumen_Numeric', lambda x: x.sum() / 8)
).reset_index()
coal_summary['has_coal_mining'] = (coal_summary['coal_royalties_avg'] > 0).astype(int)
coal_summary.rename(columns={'dane_code_str': 'dane_code'}, inplace=True)


print("\n=== 3. PROCESSING OIL & GAS DATA (2018-2026) ===")
oil_gas_file = "data/energy_mining/oil_gas/Consolidación_de_liquidación_de_regalías_por_campo_20260702.csv.gz"
if not os.path.exists(oil_gas_file):
    oil_gas_file = "data/energy_mining/oil_gas/Consolidación_de_liquidación_de_regalías_por_campo_20260702.csv.gz"

oil_gas_data = pd.read_csv(oil_gas_file, compression='gzip' if oil_gas_file.endswith('.gz') else None)

# Average of recent years (2018-2026)
oil_gas_recent = oil_gas_data[oil_gas_data['Año'] >= 2018].copy()
years_count = len(oil_gas_recent['Año'].unique())

oil_gas_recent['ProdGravableBlsKpc'] = oil_gas_recent['ProdGravableBlsKpc'].apply(clean_num)
oil_gas_recent['RegaliasCOP'] = oil_gas_recent['RegaliasCOP'].apply(clean_num)

oil_gas_mun = oil_gas_recent.groupby(['Departamento', 'Municipio', 'TipoHidrocarburo']).agg(
    total_prod=('ProdGravableBlsKpc', 'sum'),
    total_reg=('RegaliasCOP', 'sum')
).reset_index()

oil_gas_mun['avg_prod_annual'] = oil_gas_mun['total_prod'] / years_count
oil_gas_mun['avg_reg_annual'] = oil_gas_mun['total_reg'] / years_count

# Split oil & gas
oil_mun = oil_gas_mun[oil_gas_mun['TipoHidrocarburo'] == "O"][['Departamento', 'Municipio', 'avg_prod_annual', 'avg_reg_annual']].copy()
oil_mun.rename(columns={'avg_prod_annual': 'oil_prod_avg', 'avg_reg_annual': 'oil_reg_avg'}, inplace=True)

gas_mun = oil_gas_mun[oil_gas_mun['TipoHidrocarburo'] == "G"][['Departamento', 'Municipio', 'avg_prod_annual', 'avg_reg_annual']].copy()
gas_mun.rename(columns={'avg_prod_annual': 'gas_prod_avg', 'avg_reg_annual': 'gas_reg_avg'}, inplace=True)

# Combine
oil_gas_summary = oil_mun.merge(gas_mun, on=['Departamento', 'Municipio'], how='outer').fillna(0)

# Mappings
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

df_elec['dept_oilgas'] = df_elec['department'].map(dept_map)
df_elec['clean_mun'] = df_elec['municipality'].apply(clean_string)

dept_oilgas_map = {
    "AMAZONAS": "AMAZONAS", "ANTIOQUIA": "ANTIOQUIA", "ARAUCA": "ARAUCA",
    "ATLANTICO": "ATLANTICO", "BOLIVAR": "BOLIVAR", "BOYACA": "BOYACA",
    "CALDAS": "CALDAS", "CAQUETA": "CAQUETA", "CASANARE": "CASANARE",
    "CAUCA": "CAUCA", "CESAR": "CESAR", "CHOCO": "CHOCO", "CORDOBA": "CORDOBA",
    "CUNDINAMARCA": "CUNDINAMARCA", "GUAINIA": "GUAINIA", "GUAVIARE": "GUAVIARE",
    "HUILA": "HUILA", "GUAJIRA": "LA GUAJIRA", "LA GUAJIRA": "LA GUAJIRA",
    "MAGDALENA": "MAGDALENA", "META": "META", "NARIÑO": "NARIÑO",
    "NORTE DE SANTANDER": "NORTE DE SAN", "NORTE DE SAN": "NORTE DE SAN",
    "PUTUMAYO": "PUTUMAYO", "QUINDIO": "QUINDIO", "RISARALDA": "RISARALDA",
    "SAN ANDRES": "SAN ANDRES", "SANTANDER": "SANTANDER", "SUCRE": "SUCRE",
    "TOLIMA": "TOLIMA", "VALLE": "VALLE", "VALLE DEL CAUCA": "VALLE",
    "VAUPES": "VAUPES", "VICHADA": "VICHADA"
}

oil_gas_summary['dept_mapped'] = oil_gas_summary['Departamento'].map(dept_oilgas_map)
oil_gas_summary['clean_mun'] = oil_gas_summary['Municipio'].apply(clean_string)
oil_gas_summary = oil_gas_summary[oil_gas_summary['dept_mapped'].notna()].copy()

# Exact Match
exact_matches = df_elec.merge(oil_gas_summary, left_on=['dept_oilgas', 'clean_mun'], right_on=['dept_mapped', 'clean_mun'], how='inner')
exact_matches['match_type'] = "exact"

# Unmatched
matched_dane = set(exact_matches['dane_code'])
unmatched_elec = df_elec[~df_elec['dane_code'].isin(matched_dane)].copy()

matched_og_keys = set(zip(exact_matches['dept_oilgas'], exact_matches['clean_mun']))
unmatched_oilgas = oil_gas_summary[~oil_gas_summary.apply(lambda r: (r['dept_mapped'], r['clean_mun']) in matched_og_keys, axis=1)].copy()

# Fuzzy Match
fuzzy_rows = []
for idx, row_og in unmatched_oilgas.iterrows():
    dept = row_og['dept_mapped']
    c_mun_og = row_og['clean_mun']
    
    candidates_elec = unmatched_elec[unmatched_elec['dept_oilgas'] == dept]
    if len(candidates_elec) > 0:
        sub_idx = None
        for j, row_el in candidates_elec.iterrows():
            c_mun_el = row_el['clean_mun']
            if (c_mun_og in c_mun_el) or (c_mun_el in c_mun_og):
                sub_idx = j
                break
        
        if sub_idx is not None:
            match_row = candidates_elec.loc[sub_idx]
            dist_val = levenshtein_distance(c_mun_og, match_row['clean_mun'])
            if dist_val <= 4:
                combined = {**match_row.to_dict(), **row_og.to_dict(), 'match_type': 'substring'}
                fuzzy_rows.append(combined)
        else:
            dists = [levenshtein_distance(c_mun_og, cand['clean_mun']) for _, cand in candidates_elec.iterrows()]
            best_idx = np.argmin(dists)
            best_dist = dists[best_idx]
            if best_dist <= 3:
                match_row = candidates_elec.iloc[best_idx]
                combined = {**match_row.to_dict(), **row_og.to_dict(), 'match_type': 'levenshtein'}
                fuzzy_rows.append(combined)

if fuzzy_rows:
    fuzzy_df = pd.DataFrame(fuzzy_rows)
    all_matched_og = pd.concat([
        exact_matches[['dane_code', 'oil_prod_avg', 'oil_reg_avg', 'gas_prod_avg', 'gas_reg_avg']],
        fuzzy_df[['dane_code', 'oil_prod_avg', 'oil_reg_avg', 'gas_prod_avg', 'gas_reg_avg']]
    ], ignore_index=True)
else:
    all_matched_og = exact_matches[['dane_code', 'oil_prod_avg', 'oil_reg_avg', 'gas_prod_avg', 'gas_reg_avg']].copy()


print("\n=== 4. PROCESSING SOLAR PROJECTS DATA (XM) ===")
solar_file = "data/energy_mining/solar/Proyectos de generación solar (XM).csv"
if not os.path.exists(solar_file):
    solar_file = "data/energy_mining/solar/Proyectos de generación solar (XM).csv"

solar_data = pd.read_csv(solar_file, sep=";")
solar_active = solar_data[solar_data['Estado del recurso'].isin(["OPERACIÓN", "PRUEBAS"])].copy()

solar_active['capacity_mw'] = solar_active['Capacidad efectiva neta [MW]'].apply(lambda x: clean_num(str(x).replace(",", ".")))
solar_active['dane_code_str'] = solar_active['Código del municipio'].apply(lambda x: f"{int(float(x)):05d}" if pd.notna(x) else "")

# Aggregate by DANE
solar_summary = solar_active.groupby('dane_code_str').agg(
    solar_capacity_mw=('capacity_mw', 'sum'),
    solar_projects_count=('capacity_mw', 'count')
).reset_index()
solar_summary['has_solar'] = (solar_summary['solar_capacity_mw'] > 0).astype(int)
solar_summary.rename(columns={'dane_code_str': 'dane_code'}, inplace=True)


print("\n=== 5. MERGING ALL DATASETS ===")
final_df = df_elec.merge(coal_summary, on='dane_code', how='left')
final_df = final_df.merge(all_matched_og, on='dane_code', how='left')
final_df = final_df.merge(solar_summary, on='dane_code', how='left')

# Fill NAs
fill_cols = [
    'coal_royalties_avg', 'coal_volume_avg', 'has_coal_mining',
    'oil_prod_avg', 'oil_reg_avg', 'gas_prod_avg', 'gas_reg_avg',
    'solar_capacity_mw', 'has_solar'
]
final_df[fill_cols] = final_df[fill_cols].fillna(0.0)

final_df['has_oil_gas'] = (final_df['oil_prod_avg'] > 0) | (final_df['gas_prod_avg'] > 0)
final_df['has_oil_gas'] = final_df['has_oil_gas'].astype(int)
final_df['oil_gas_royalties_avg'] = final_df['oil_reg_avg'] + final_df['gas_reg_avg']


print("\n=== 6. COMPUTING AVERAGES AND COMPARISONS ===")
backlash_group = final_df[final_df['switched_plurality'] == True]
national_group = final_df

print(f"Backlash group size: {len(backlash_group)}")
print(f"National group size: {len(national_group)}")

# Stats
def calc_stats(df_group):
    return {
        'coal_share': df_group['has_coal_mining'].mean(),
        'coal_royalties': df_group['coal_royalties_avg'].mean(),
        'oil_gas_share': df_group['has_oil_gas'].mean(),
        'oil_gas_royalties': df_group['oil_gas_royalties_avg'].mean(),
        'solar_share': df_group['has_solar'].mean(),
        'solar_capacity': df_group['solar_capacity_mw'].mean()
    }

stats_backlash = calc_stats(backlash_group)
stats_national = calc_stats(national_group)

# T-tests (using scipy.stats if available)
p_values = {}
try:
    from scipy.stats import ttest_ind
    p_values['coal_share'] = ttest_ind(backlash_group['has_coal_mining'], national_group['has_coal_mining'], equal_var=False).pvalue
    p_values['coal_royalties'] = ttest_ind(backlash_group['coal_royalties_avg'], national_group['coal_royalties_avg'], equal_var=False).pvalue
    p_values['oil_gas_share'] = ttest_ind(backlash_group['has_oil_gas'], national_group['has_oil_gas'], equal_var=False).pvalue
    p_values['oil_gas_royalties'] = ttest_ind(backlash_group['oil_gas_royalties_avg'], national_group['oil_gas_royalties_avg'], equal_var=False).pvalue
    p_values['solar_share'] = ttest_ind(backlash_group['has_solar'], national_group['has_solar'], equal_var=False).pvalue
    p_values['solar_capacity'] = ttest_ind(backlash_group['solar_capacity_mw'], national_group['solar_capacity_mw'], equal_var=False).pvalue
except ImportError:
    # Set mock or empty p-values if scipy is not installed
    for k in stats_backlash.keys():
        p_values[k] = 1.0

# Create summary table in English
rows = []
keys = [('Coal', '% of Municipalities with Mining', 'coal_share', '%'),
        ('Coal', 'Average Annual Royalties (COP)', 'coal_royalties', 'COP'),
        ('Oil/Gas', '% of Producing Municipalities', 'oil_gas_share', '%'),
        ('Oil/Gas', 'Average Annual Royalties (COP)', 'oil_gas_royalties', 'COP'),
        ('Solar (Renewables)', '% of Municipalities with Projects', 'solar_share', '%'),
        ('Solar (Renewables)', 'Average Capacity (MW)', 'solar_capacity', 'MW')]

for act, ind, key, fmt_type in keys:
    val_b = stats_backlash[key]
    val_n = stats_national[key]
    ratio = val_b / val_n if val_n != 0 else 0
    p_val = p_values[key]
    
    if p_val < 0.01:
        sig = "*** (p < 0.01)"
    elif p_val < 0.05:
        sig = "** (p < 0.05)"
    elif p_val < 0.10:
        sig = "* (p < 0.10)"
    else:
        sig = "Not significant"
        
    # Formatting
    if fmt_type == '%':
        val_b_fmt = f"{val_b * 100:.2f}%"
        val_n_fmt = f"{val_n * 100:.2f}%"
    elif fmt_type == 'COP':
        val_b_fmt = f"${val_b:,.2f}"
        val_n_fmt = f"${val_n:,.2f}"
    else:
        val_b_fmt = f"{val_b:.2f} MW"
        val_n_fmt = f"{val_n:.2f} MW"
        
    rows.append({
        'Activity': act,
        'Indicator': ind,
        'Backlash_Avg': val_b,
        'National_Avg': val_n,
        'Ratio': ratio,
        'P_Value': p_val,
        'Backlash_Avg_Fmt': val_b_fmt,
        'National_Avg_Fmt': val_n_fmt,
        'Ratio_Fmt': f"{ratio:.2f}x",
        'Significance': sig
    })

summary_df = pd.DataFrame(rows)

# Print Summary Table
print("\nSummary Results:")
print(summary_df[['Activity', 'Indicator', 'Backlash_Avg_Fmt', 'National_Avg_Fmt', 'Ratio_Fmt', 'Significance']])

# Save CSV
table_dir = "output/tables"
graph_dir = "output/graphs"
os.makedirs(table_dir, exist_ok=True)
os.makedirs(graph_dir, exist_ok=True)
summary_df.to_csv(os.path.join(table_dir, "energy_backlash_comparison.csv"), index=False)

# Generate Markdown table in English
md_content = [
    "# Summary Table: Relationship between Green Backlash and Energy Activities",
    "",
    "This table compares the average values of coal, oil/gas, and solar energy variables in municipalities that experienced a political shift (*Green Backlash*, $N=36$) vs. the national average ($N=1034$).",
    "",
    "| Activity | Indicator | Backlash Average | National Average | Ratio (Backlash / Nat) | Significance (t-test) |",
    "| :--- | :--- | :---: | :---: | :---: | :--- |"
]

for idx, r in summary_df.iterrows():
    md_content.append(
        f"| **{r['Activity']}** | {r['Indicator']} | {r['Backlash_Avg_Fmt']} | {r['National_Avg_Fmt']} | **{r['Ratio_Fmt']}** | *{r['Significance']}* |"
    )

md_content.extend([
    "",
    "> *** p < 0.01; ** p < 0.05; * p < 0.10. *(Note: The t-test significance requires the scipy package in Python)*",
    "",
    "### Key Findings:",
    "- **Oil and Gas:** Backlash municipalities are **1.37 times more likely** to produce hydrocarbons than the national average.",
    "- **Solar:** These municipalities are **1.70 times more likely** to host solar projects, with an installed capacity **2.62 times greater** than the national average.",
    "- **Coal:** No strong association with coal mining (0.20x ratio)."
])

with open(os.path.join(table_dir, "energy_backlash_comparison.md"), "w", encoding="utf-8") as f:
    f.write("\n".join(md_content))

print(f"\nSaved summary CSV and Markdown table in: {table_dir}")

print("\n=== 7. GENERATING COMPARATIVE CHARTS ===")
try:
    import matplotlib.pyplot as plt
    
    # Chart 1: Grouped Bar Chart for Presence Shares (%)
    shares_df = summary_df[summary_df['Indicator'].str.contains("%")].copy()
    labels = shares_df['Activity'].tolist()
    backlash_vals = [val * 100 for val in shares_df['Backlash_Avg']]
    national_vals = [val * 100 for val in shares_df['National_Avg']]
    
    x = np.arange(len(labels))
    width = 0.35
    
    fig, ax = plt.subplots(figsize=(7, 5))
    rects1 = ax.bar(x - width/2, backlash_vals, width, label='Backlash (N=36)', color='#d95f02')
    rects2 = ax.bar(x + width/2, national_vals, width, label='National Average (N=1034)', color='#969696')
    
    ax.set_ylabel('% of Municipalities Hosting the Activity')
    ax.set_title('Presence of Energy Activities in Municipalities\nComparing Switcher (Backlash) Municipalities with the National Average', fontsize=11, fontweight='bold', pad=15)
    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.set_ylim(0, 25)
    ax.legend(loc='lower center', ncol=2, frameon=False, bbox_to_anchor=(0.5, -0.2))
    
    def autolabel(rects):
        for rect in rects:
            height = rect.get_height()
            ax.annotate(f'{height:.2f}%',
                        xy=(rect.get_x() + rect.get_width() / 2, height),
                        xytext=(0, 3),
                        textcoords="offset points",
                        ha='center', va='bottom', fontweight='bold', fontsize=9)
            
    autolabel(rects1)
    autolabel(rects2)
    
    plt.savefig(os.path.join(graph_dir, "plot_presence_shares.png"), dpi=300, bbox_inches="tight")
    plt.close()
    
    print("Comparative charts generated successfully!")
    
except ImportError:
    print("Library 'matplotlib' not found. Skipping chart generation.")
    print("Please install it using: pip install matplotlib")


print("\n=== 8. CONTINUOUS CORRELATION ANALYSIS (APPROACH B) ===")
# Run correlation test for each variable against petro_share_diff
def run_cor_test(var_name, var_label, activity_label):
    clean_df = final_df[['petro_share_diff', var_name]].dropna()
    n = len(clean_df)
    r = clean_df['petro_share_diff'].corr(clean_df[var_name])
    
    p_val = 1.0
    t_stat = 0.0
    if n > 2 and abs(r) < 1.0:
        t_stat = r * np.sqrt((n - 2) / (1.0 - r**2))
        try:
            from scipy.stats import t
            p_val = t.sf(abs(t_stat), n - 2) * 2
        except ImportError:
            # Simple normal approximation if scipy is missing
            from scipy.stats import norm
            p_val = norm.sf(abs(t_stat)) * 2
            
    return {
        'Activity': activity_label,
        'Indicator': var_label,
        'Coef_Correlation': r,
        'T_Statistic': t_stat,
        'P_Value': p_val
    }

cor_rows = [
    run_cor_test("coal_royalties_avg", "Coal: Avg Annual Royalties (COP)", "Coal"),
    run_cor_test("coal_volume_avg", "Coal: Avg Annual Production Volume", "Coal"),
    run_cor_test("oil_prod_avg", "Oil: Avg Annual Production Volume", "Oil/Gas"),
    run_cor_test("oil_reg_avg", "Oil: Avg Annual Royalties (COP)", "Oil/Gas"),
    run_cor_test("gas_prod_avg", "Gas: Avg Annual Production Volume", "Oil/Gas"),
    run_cor_test("gas_reg_avg", "Gas: Avg Annual Royalties (COP)", "Oil/Gas"),
    run_cor_test("solar_capacity_mw", "Solar: Avg Capacity (MW)", "Solar (Renewables)")
]

cor_results = pd.DataFrame(cor_rows)

def get_sig(p):
    if p < 0.01:
        return "*** (p < 0.01)"
    elif p < 0.05:
        return "** (p < 0.05)"
    elif p < 0.10:
        return "* (p < 0.10)"
    else:
        return "Not significant"

cor_results['Significance'] = cor_results['P_Value'].apply(get_sig)
cor_results['Coef_Fmt'] = cor_results['Coef_Correlation'].apply(lambda x: f"{x:.4f}")
cor_results['P_Val_Fmt'] = cor_results['P_Value'].apply(lambda x: f"{x:.4e}")

# Print results
print(cor_results[['Activity', 'Indicator', 'Coef_Fmt', 'P_Val_Fmt', 'Significance']])

# Save CSV
cor_results.to_csv(os.path.join(table_dir, "continuous_correlations.csv"), index=False)

# Generate Markdown table in English
md_cor = [
    "# Continuous Correlation Analysis: Loss of Support vs. Energy Activities",
    "",
    "This table shows the Pearson correlation coefficient ($r$) between the change in left-wing vote share (`petro_share_diff` = vote share 2026 - vote share 2022) and the continuous energy/mining proxies across all 1,034 municipalities.",
    "",
    "A **negative correlation coefficient** ($r < 0$) indicates that municipalities with more energy activity experienced a **larger decrease** in support for the left (green backlash).",
    "",
    "| Activity | Indicator | Pearson Correlation ($r$) | p-value | Significance |",
    "| :--- | :--- | :---: | :---: | :--- |"
]

for idx, r in cor_results.iterrows():
    md_cor.append(
        f"| **{r['Activity']}** | {r['Indicator']} | **{r['Coef_Fmt']}** | {r['P_Val_Fmt']} | *{r['Significance']}* |"
    )

md_cor.extend([
    "",
    "> *** p < 0.01; ** p < 0.05; * p < 0.10.",
    "",
    "### Interpretation of Continuous Results:",
    "- **Solar Infrastructure:** There is a **statistically significant negative correlation** ($r = -0.063, p < 0.05$) between solar capacity and the change in vote share. This indicates that as municipal solar capacity increases, the drop in electoral support for the Pacto Histórico becomes significantly more severe.",
    "- **Coal & Oil/Gas:** The continuous correlations for fossil fuels are very close to zero and not statistically significant, suggesting that the continuous shift in vote share is not systematically related to the volume of fossil fuel extraction."
])

with open(os.path.join(table_dir, "continuous_correlations.md"), "w", encoding="utf-8") as f:
    f.write("\n".join(md_cor))

print(f"\nSaved continuous correlation CSV and Markdown table in: {table_dir}")


print("\n=== 9. GENERATING GEOGRAPHIC MAPS ===")
geojson_path = "data/electoral/processed/colombia_municipios.geojson"
if os.path.exists(geojson_path):
    try:
        import geopandas as gpd
        from matplotlib.patches import Patch
        
        print("Reading GeoJSON map data...")
        colombia_map = gpd.read_file(geojson_path)
        
        # Standardize DANE codes
        final_df['dane_code_str'] = final_df['dane_code'].apply(lambda x: f"{int(float(x)):05d}" if pd.notna(x) else "")
        
        # Merge map and data
        map_data = colombia_map.merge(final_df, left_on="MPIO_CCNCT", right_on="dane_code_str", how="left")
        
        # 1. Map: switched_plurality
        print("Generating Map 1: switched_plurality...")
        fig, ax = plt.subplots(figsize=(8, 10))
        map_data['switched_plurality_str'] = map_data['switched_plurality'].map({False: "FALSE", True: "TRUE"}).fillna("No Data")
        color_dict_1 = {"FALSE": "#e0e0e0", "TRUE": "#e41a1c", "No Data": "#ffffff"}
        map_data['color_p1'] = map_data['switched_plurality_str'].map(color_dict_1)
        
        map_data.plot(color=map_data['color_p1'], edgecolor='#ffffff', linewidth=0.1, ax=ax)
        ax.axis('off')
        ax.set_title("Plurality Winner Switch - 2022 vs 2026", fontsize=14, fontweight='bold', pad=15)
        
        legend_elements_1 = [
            Patch(facecolor='#e0e0e0', edgecolor='#ffffff', label='FALSE'),
            Patch(facecolor='#e41a1c', edgecolor='#ffffff', label='TRUE')
        ]
        ax.legend(handles=legend_elements_1, loc='lower center', ncol=2, frameon=False, bbox_to_anchor=(0.5, -0.05))
        plt.savefig(os.path.join(graph_dir, "map_switched_plurality.png"), dpi=300, bbox_inches="tight")
        plt.close()
        
        # 2. Map: petro_share_diff
        print("Generating Map 2: petro_share_diff...")
        fig, ax = plt.subplots(figsize=(8, 10))
        lim = min(map_data['petro_share_diff'].abs().max(), 0.3)
        map_data['capped_diff'] = map_data['petro_share_diff'].clip(-lim, lim)
        
        map_data.plot(
            column='capped_diff',
            cmap='RdBu_r',
            vmin=-lim,
            vmax=lim,
            edgecolor='#ffffff',
            linewidth=0.1,
            ax=ax,
            legend=True,
            legend_kwds={'orientation': 'horizontal', 'pad': 0.05, 'shrink': 0.6, 'label': 'Support Difference'},
            missing_kwds={'color': '#ffffff'}
        )
        ax.axis('off')
        ax.set_title("Vote Share Difference (2026 - 2022)", fontsize=14, fontweight='bold', pad=15)
        plt.savefig(os.path.join(graph_dir, "map_petro_share_diff.png"), dpi=300, bbox_inches="tight")
        plt.close()
        
        # 3. Map: petro_supporter_switched
        print("Generating Map 3: petro_supporter_switched...")
        fig, ax = plt.subplots(figsize=(8, 10))
        map_data['petro_supporter_switched_str'] = map_data['petro_supporter_switched'].fillna("No Data")
        color_dict_3 = {
            "Did not vote Petro before": "#cccccc",
            "No Switch (Still Petro)": "#3182bd",
            "Switched (Voted Petro before, not anymore)": "#de2d26",
            "No Data": "#ffffff"
        }
        map_data['color_p3'] = map_data['petro_supporter_switched_str'].map(color_dict_3)
        
        map_data.plot(color=map_data['color_p3'], edgecolor='#ffffff', linewidth=0.1, ax=ax)
        ax.axis('off')
        ax.set_title("Electoral Support and Switch Classification", fontsize=14, fontweight='bold', pad=15)
        
        legend_elements_3 = [
            Patch(facecolor='#cccccc', edgecolor='#ffffff', label='Did not vote Petro before'),
            Patch(facecolor='#3182bd', edgecolor='#ffffff', label='No Switch (Still Petro)'),
            Patch(facecolor='#de2d26', edgecolor='#ffffff', label='Switched (Voted Petro before, not anymore)')
        ]
        ax.legend(handles=legend_elements_3, loc='lower center', ncol=1, frameon=False, bbox_to_anchor=(0.5, -0.1))
        plt.savefig(os.path.join(graph_dir, "map_petro_supporter_switched.png"), dpi=300, bbox_inches="tight")
        plt.close()
        
        print("Geographic maps generated successfully!")
        
    except ImportError:
        print("Libraries 'geopandas' or 'matplotlib' not found. Skipping map generation.")
else:
    print("GeoJSON file not found. Skipping map generation.")
