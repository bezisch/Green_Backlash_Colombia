##################################################################################
#       Green Backlash in Colombia: Municipality-Year Energy & Mining Panel
#       Master Python Script to Create a Harmonized Panel (2018–2026)
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
#################################################################################

import os
import re
import unicodedata
import pandas as pd
import json

def clean_string(s):
    if not isinstance(s, str):
        return ""
    s = s.lower()
    s = "".join(c for c in unicodedata.normalize('NFD', s) if unicodedata.category(c) != 'Mn')
    s = re.sub(r'[^a-z0-9]', '', s)
    return s

def clean_num(val):
    if pd.isna(val):
        return 0.0
    s = str(val).replace(',', '').replace(' ', '').replace('-', '')
    try:
        return float(s)
    except ValueError:
        return 0.0

def main():
    base_dir = os.getcwd()
    
    print("=== 1. LOADING GEOJSON MASTER MUNICIPALITIES ===")
    geo_path = os.path.join(base_dir, "data/electoral/processed/colombia_municipios.geojson")
    with open(geo_path, 'r', encoding='utf-8') as f:
        geo_data = json.load(f)
    
    muns_list = []
    for feat in geo_data['features']:
        props = feat['properties']
        dane_code = str(props['MPIO_CCNCT']).zfill(5)
        dept_code = str(props['DPTO_CCDGO']).zfill(2)
        muns_list.append({
            'dane_code': dane_code,
            'dept_code': dept_code,
            'dept_name': props['DPTO_CNMBR'],
            'mun_name': props['MPIO_CNMBR'],
            'dept_clean': clean_string(props['DPTO_CNMBR']),
            'mun_clean': clean_string(props['MPIO_CNMBR'])
        })
    
    geo_df = pd.DataFrame(muns_list).drop_duplicates(subset=['dane_code'])
    print(f"Geojson master municipalities count: {len(geo_df)}")

    # Create balanced grid 2018-2026
    years = list(range(2018, 2027))
    grid_rows = []
    for _, row in geo_df.iterrows():
        for yr in years:
            grid_rows.append({
                'dane_code': row['dane_code'],
                'year': yr,
                'dept_code': row['dept_code'],
                'dept_name': row['dept_name'],
                'mun_name': row['mun_name']
            })
    panel_df = pd.DataFrame(grid_rows)
    print(f"Base panel grid count: {len(panel_df)}")

    # TRM Annual Map
    trm_map = {
        2018: 2958.2, 2019: 3280.2, 2020: 3688.1, 2021: 3744.1,
        2022: 4255.4, 2023: 4310.1, 2024: 4073.3, 2025: 4055.3, 2026: 3693.3
    }
    panel_df['trm_avg'] = panel_df['year'].map(trm_map).fillna(4000.0)

    # 2. MINING ANM
    print("\n=== 2. PROCESSING MINING ANM ===")
    anm_path = os.path.join(base_dir, "data/energy_mining/all_minerals/ANM_Volúmen_de_Explotación_de_Minerales_Asociados_a_Pagos_de_Regalías_20260702.csv")
    minerals_df = pd.read_csv(anm_path, dtype={'Codigo DANE': str})
    minerals_df = minerals_df[(minerals_df['Año Liquidado'] >= 2018) & (minerals_df['Año Liquidado'] <= 2026)].copy()
    
    minerals_df['dane_code'] = minerals_df['Codigo DANE'].str.strip().str.zfill(5)
    minerals_df['year'] = minerals_df['Año Liquidado'].astype(int)
    minerals_df['regalias_cop'] = minerals_df['Regalías pagadas'].fillna(0.0)
    minerals_df['volumen_num'] = minerals_df['Volúmenes de explotación'].apply(clean_num)
    minerals_df['recurso'] = minerals_df['Recurso Natural'].astype(str).str.strip().str.upper()

    def get_mineral_aggs(df_group):
        tot_cop = df_group['regalias_cop'].sum()
        coal_cop = df_group[df_group['recurso'].str.contains('CARBON', na=False)]['regalias_cop'].sum()
        gold_cop = df_group[df_group['recurso'] == 'ORO']['regalias_cop'].sum()
        nickel_cop = df_group[df_group['recurso'] == 'NIQUEL']['regalias_cop'].sum()
        copper_cop = df_group[df_group['recurso'] == 'COBRE']['regalias_cop'].sum()
        emerald_cop = df_group[df_group['recurso'].str.contains('ESMERALDA', na=False)]['regalias_cop'].sum()
        plat_cop = df_group[df_group['recurso'] == 'PLATINO']['regalias_cop'].sum()
        
        other_mask = ~df_group['recurso'].str.contains('CARBON|ORO|NIQUEL|COBRE|ESMERALDA|PLATINO', na=False)
        other_cop = df_group[other_mask]['regalias_cop'].sum()

        vol_coal = df_group[df_group['recurso'].str.contains('CARBON', na=False)]['volumen_num'].sum()
        vol_gold = df_group[df_group['recurso'] == 'ORO']['volumen_num'].sum()

        return pd.Series({
            'mining_royalties_total_cop': tot_cop,
            'mining_royalties_coal_cop': coal_cop,
            'mining_royalties_gold_cop': gold_cop,
            'mining_royalties_nickel_cop': nickel_cop,
            'mining_royalties_copper_cop': copper_cop,
            'mining_royalties_emeralds_cop': emerald_cop,
            'mining_royalties_platinum_cop': plat_cop,
            'mining_royalties_other_cop': other_cop,
            'mining_vol_coal_ton': vol_coal,
            'mining_vol_gold_g': vol_gold,
            'mining_has_activity': 1 if (tot_cop > 0 or vol_coal > 0 or vol_gold > 0) else 0
        })

    mining_agg = minerals_df.groupby(['dane_code', 'year']).apply(get_mineral_aggs).reset_index()

    # 3. OIL AND GAS
    print("\n=== 3. PROCESSING OIL AND GAS ===")
    oilgas_path = os.path.join(base_dir, "data/energy_mining/oil_gas/Consolidación_de_liquidación_de_regalías_por_campo_20260702.csv.gz")
    oilgas_df = pd.read_csv(oilgas_path, compression='gzip')
    oilgas_df = oilgas_df[(oilgas_df['Año'] >= 2018) & (oilgas_df['Año'] <= 2026)].copy()

    # Map names
    geo_lookup = geo_df[['dane_code', 'dept_clean', 'mun_clean']].drop_duplicates()
    
    def norm_dept(d):
        c = clean_string(d)
        return "la guajira" if c == "guajira" else str(d).lower()

    def norm_mun(m):
        c = clean_string(m)
        custom_map = {
            "lajaguaibirico": "la jagua de ibirico",
            "castillanueva": "castilla la nueva",
            "cucuta": "san jose de cucuta",
            "sanjosedefragua": "san jose del fragua",
            "sancaarlosguaroa": "san carlos de guaroa",
            "since": "san luis de since",
            "sansebastianbuenavista": "san sebastian de buenavista",
            "pazdelrio": "paz de rio"
        }
        return custom_map.get(c, str(m).lower())

    oilgas_df['dept_clean'] = oilgas_df['Departamento'].apply(norm_dept).apply(clean_string)
    oilgas_df['mun_clean'] = oilgas_df['Municipio'].apply(norm_mun).apply(clean_string)

    oilgas_mapped = oilgas_df.merge(geo_lookup, on=['dept_clean', 'mun_clean'], how='inner')
    oilgas_mapped['year'] = oilgas_mapped['Año'].astype(int)

    def get_oilgas_aggs(df_group):
        oil_mask = df_group['TipoHidrocarburo'] == 'O'
        gas_mask = df_group['TipoHidrocarburo'] == 'G'

        oil_bbl = df_group[oil_mask]['ProdGravableBlsKpc'].sum()
        gas_kpc = df_group[gas_mask]['ProdGravableBlsKpc'].sum()
        oil_cop = df_group[oil_mask]['RegaliasCOP'].sum()
        gas_cop = df_group[gas_mask]['RegaliasCOP'].sum()
        tot_cop = df_group['RegaliasCOP'].sum()
        fields_cnt = df_group['Campo'].dropna().nunique()
        tot_boe = oil_bbl + (gas_kpc / 5.615)

        return pd.Series({
            'oil_prod_bbl': oil_bbl,
            'gas_prod_kpc': gas_kpc,
            'oilgas_total_prod_boe': tot_boe,
            'oil_royalties_cop': oil_cop,
            'gas_royalties_cop': gas_cop,
            'oilgas_royalties_total_cop': tot_cop,
            'oilgas_active_fields_count': fields_cnt,
            'oilgas_has_activity': 1 if (tot_cop > 0 or oil_bbl > 0 or gas_kpc > 0) else 0
        })

    oilgas_agg = oilgas_mapped.groupby(['dane_code', 'year']).apply(get_oilgas_aggs).reset_index()

    # 4. SOLAR XM
    print("\n=== 4. PROCESSING SOLAR XM ===")
    solar_path = os.path.join(base_dir, "data/energy_mining/solar/Proyectos de generación solar (XM).csv")
    solar_df = pd.read_csv(solar_path, sep=';', dtype={'Código del municipio': str})
    
    solar_df['dane_code'] = solar_df['Código del municipio'].str.strip().str.zfill(5)
    solar_df['fpo_year'] = pd.to_numeric(solar_df['Año de puesta en operación (fpo)'], errors='coerce')
    solar_df['capacity_mw'] = pd.to_numeric(solar_df['Capacidad efectiva neta [MW]'], errors='coerce').fillna(0.0)

    solar_clean = solar_df.dropna(subset=['dane_code', 'fpo_year']).copy()
    solar_clean['fpo_year'] = solar_clean['fpo_year'].astype(int)

    solar_annual = solar_clean.groupby(['dane_code', 'fpo_year']).agg(
        solar_projects_new=('id', 'count'),
        solar_capacity_mw_new=('capacity_mw', 'sum')
    ).reset_index().rename(columns={'fpo_year': 'year'})

    solar_grid = pd.MultiIndex.from_product([geo_df['dane_code'], years], names=['dane_code', 'year']).to_frame().reset_index(drop=True)
    solar_grid = solar_grid.merge(solar_annual, on=['dane_code', 'year'], how='left').fillna(0.0)
    
    solar_grid = solar_grid.sort_values(['dane_code', 'year'])
    solar_grid['solar_projects_cum'] = solar_grid.groupby('dane_code')['solar_projects_new'].cumsum()
    solar_grid['solar_capacity_mw_cum'] = solar_grid.groupby('dane_code')['solar_capacity_mw_new'].cumsum()
    solar_grid['solar_has_project'] = ((solar_grid['solar_capacity_mw_cum'] > 0) | (solar_grid['solar_projects_cum'] > 0)).astype(int)

    # 5. MERGE INTO FINAL PANEL
    print("\n=== 5. MERGING ALL SECTORS ===")
    final_panel = panel_df.merge(mining_agg, on=['dane_code', 'year'], how='left')
    final_panel = final_panel.merge(oilgas_agg, on=['dane_code', 'year'], how='left')
    final_panel = final_panel.merge(solar_grid[['dane_code', 'year', 'solar_projects_new', 'solar_capacity_mw_new', 'solar_projects_cum', 'solar_capacity_mw_cum', 'solar_has_project']], on=['dane_code', 'year'], how='left')

    fill_zero_cols = [
        'mining_royalties_total_cop', 'mining_royalties_coal_cop', 'mining_royalties_gold_cop',
        'mining_royalties_nickel_cop', 'mining_royalties_copper_cop', 'mining_royalties_emeralds_cop',
        'mining_royalties_platinum_cop', 'mining_royalties_other_cop', 'mining_vol_coal_ton',
        'mining_vol_gold_g', 'mining_has_activity',
        'oil_prod_bbl', 'gas_prod_kpc', 'oil_royalties_cop', 'gas_royalties_cop',
        'oilgas_royalties_total_cop', 'oilgas_active_fields_count', 'oilgas_total_prod_boe',
        'oilgas_has_activity',
        'solar_projects_new', 'solar_capacity_mw_new', 'solar_projects_cum', 'solar_capacity_mw_cum',
        'solar_has_project'
    ]
    final_panel[fill_zero_cols] = final_panel[fill_zero_cols].fillna(0.0)

    final_panel['mining_royalties_total_usd'] = final_panel['mining_royalties_total_cop'] / final_panel['trm_avg']
    final_panel['oilgas_royalties_total_usd'] = final_panel['oilgas_royalties_total_cop'] / final_panel['trm_avg']
    final_panel['extractive_royalties_total_cop'] = final_panel['mining_royalties_total_cop'] + final_panel['oilgas_royalties_total_cop']
    final_panel['extractive_royalties_total_usd'] = final_panel['mining_royalties_total_usd'] + final_panel['oilgas_royalties_total_usd']
    
    final_panel['has_any_extractive_activity'] = ((final_panel['mining_has_activity'] == 1) | (final_panel['oilgas_has_activity'] == 1)).astype(int)
    final_panel['has_any_energy_mining_activity'] = ((final_panel['has_any_extractive_activity'] == 1) | (final_panel['solar_has_project'] == 1)).astype(int)

    output_dir = os.path.join(base_dir, "data/energy_mining/processed")
    os.makedirs(output_dir, exist_ok=True)
    out_csv = os.path.join(output_dir, "municipality_year_energy_mining_panel_2018_2026.csv")
    final_panel.to_csv(out_csv, index=False, encoding='utf-8')
    print(f"\nFinal Panel saved to: {out_csv}")
    print(f"Shape: {final_panel.shape}")

if __name__ == "__main__":
    main()
