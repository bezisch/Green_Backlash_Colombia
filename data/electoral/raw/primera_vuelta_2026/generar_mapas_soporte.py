import os
import re
import unicodedata
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import geopandas as gpd

# ==========================================
# 1. FUNCIÓN DE NORMALIZACIÓN DE NOMBRES
# ==========================================
def clean_text(text):
    if pd.isna(text):
        return ""
    text = str(text).lower()
    text = re.sub(r'\(.*?\)', '', text)
    text = unicodedata.normalize('NFKD', text).encode('ASCII', 'ignore').decode('ASCII')
    text = text.replace('-', ' ')
    text = re.sub(r'[^a-z0-9\s]', '', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def parse_pct(val):
    if pd.isna(val):
        return 0.0
    val_str = str(val).replace('%', '').replace(',', '.').strip()
    try:
        return float(val_str)
    except ValueError:
        return 0.0

# ==========================================
# 2. CARGAR Y PREPARAR LOS DATOS
# ==========================================
print("Cargando archivos CSV...")
winners = pd.read_csv("presidential-2026-municipality-winners.csv")
results = pd.read_csv("presidential-2026-municipality-results.csv")

# Filtrar consulados para el mapeo geográfico de Colombia
winners_col = winners[winners['departamento'] != 'CONSULADOS'].copy()
results_col = results[results['department'] != 'CONSULADOS'].copy()

# Normalizar nombres para cruzado de datos
winners_col['dept_clean'] = winners_col['departamento'].apply(clean_text)
winners_col['muni_clean'] = winners_col['municipio'].apply(clean_text)

results_col['dept_clean'] = results_col['department'].apply(clean_text)
results_col['muni_clean'] = results_col['municipality'].apply(clean_text)

# Crear diccionario base de geo_id (DANE)
mapping_dict = {}
for idx, row in winners_col.iterrows():
    mapping_dict[(row['dept_clean'], row['muni_clean'])] = row['geo_id']

# Diccionario de correcciones manuales
MANUAL_MAPPING = {
    ('antioquia', 'antioquia'): 'santafe de antioquia',
    ('antioquia', 'bolivar'): 'ciudad bolivar',
    ('antioquia', 'carmen de viboral'): 'el carmen de viboral',
    ('antioquia', 'penol'): 'el penol',
    ('antioquia', 'puerto nare la magdalena'): 'puerto nare',
    ('antioquia', 'san andres'): 'san andres de cuerquia',
    ('antioquia', 'santuario'): 'el santuario',
    ('antioquia', 'yondo casabe'): 'yondo',
    ('bogota dc', 'bogota dc'): 'bogota',
    ('bolivar', 'arroyo hondo'): 'arroyohondo',
    ('bolivar', 'mompos'): 'mompox',
    ('bolivar', 'rioviejo'): 'rio viejo',
    ('boyaca', 'villa de leiva'): 'villa de leyva',
    ('caqueta', 'milan'): 'puerto milan',
    ('cauca', 'lopez'): 'lopez de micay',
    ('cesar', 'manaure balcon del cesar mana'): 'manaure',
    ('choco', 'atrato'): 'el atrato',
    ('choco', 'carmen del darien'): 'el carmen del darien',
    ('choco', 'el canton del san pablo man'): 'canton de san pablo',
    ('choco', 'el litoral del san juan'): 'litoral de san juan',
    ('choco', 'union panamericana las animas'): 'union panamericana',
    ('cordoba', 'san andres de sotavento'): 'san andres sotavento',
    ('cundinamarca', 'san juan de rioseco'): 'san juan de rio seco',
    ('guainia', 'barrancominas'): 'barranco minas',
    ('guainia', 'morichal'): 'morichal nuevo',
    ('huila', 'pital'): 'el pital',
    ('magdalena', 'puebloviejo'): 'pueblo viejo',
    ('meta', 'san martin de los llanos'): 'san martin',
    ('meta', 'uribe'): 'la uribe',
    ('meta', 'vista hermosa'): 'vistahermosa',
    ('narino', 'el tablon'): 'el tablon de gomez',
    ('narino', 'magui'): 'magui payan',
    ('santander', 'el carmen'): 'el carmen de chucuri',
    ('sucre', 'toluviejo'): 'tolu viejo',
    ('vaupes', 'buenos aires'): 'pacoa',
    ('vaupes', 'morichal'): 'morichal papunagua'
}

def get_dane_code(row):
    dept = row['dept_clean']
    muni = row['muni_clean']
    key = (dept, muni)
    if key in MANUAL_MAPPING:
        target_muni = MANUAL_MAPPING[key]
        return mapping_dict.get((dept, target_muni))
    return mapping_dict.get(key)

# Obtener código DANE único
results_unique_muni = results_col[['department', 'municipality', 'dept_clean', 'muni_clean']].drop_duplicates().copy()
results_unique_muni['geo_id'] = results_unique_muni.apply(get_dane_code, axis=1)

# Fusionar de vuelta
results_col = results_col.merge(results_unique_muni[['department', 'municipality', 'geo_id']], on=['department', 'municipality'], how='left')

# Limpiar porcentaje
results_col['pct'] = results_col['votes_pct'].apply(parse_pct)

# Pivotear resultados para tener columnas de los candidatos por municipio
df_pivot = results_col.pivot_table(
    index=['department', 'municipality', 'geo_id'],
    columns='president',
    values='pct',
    aggfunc='first'
).reset_index().fillna(0.0)

# Formatear códigos de enlace
df_pivot['dane_code'] = df_pivot['geo_id'].apply(lambda x: str(int(x)).zfill(5) if pd.notna(x) else "")

# ==========================================
# 3. LEER EL GEODATAFRAME
# ==========================================
print("Cargando mapa GeoJSON de Colombia...")
geojson_path = "co_2018_MGN_MPIO_POLITICO.geojson"
gdf = gpd.read_file(geojson_path)

# Fusionar datos pivotados con el GeoDataFrame
gdf_mapped = gdf.merge(df_pivot, left_on='MPIO_CCNCT', right_on='dane_code', how='left')

# ==========================================
# 4. DEFINIR LOS 5 CANDIDATOS MÁS POPULARES Y SUS CONFIGURACIONES DE COLOR
# ==========================================
candidates_config = [
    {
        'name': 'ABELARDO DE LA ESPRIELLA',
        'file_name': 'mapa_soporte_1_abelardo.png',
        'cmap': 'Oranges',
        'title': 'Electoral Support: Abelardo de la Espriella\nVote Percentage by Municipality',
        'label': '% votes for de la Espriella'
    },
    {
        'name': 'IVÁN CEPEDA CASTRO',
        'file_name': 'mapa_soporte_2_cepeda.png',
        'cmap': 'Blues',
        'title': 'Electoral Support: Iván Cepeda Castro\nVote Percentage by Municipality',
        'label': '% votes for Cepeda'
    },
    {
        'name': 'PALOMA VALENCIA LASERNA',
        'file_name': 'mapa_soporte_3_paloma.png',
        'cmap': 'Purples',
        'title': 'Electoral Support: Paloma Valencia Laserna\nVote Percentage by Municipality',
        'label': '% votes for Paloma'
    },
    {
        'name': 'SERGIO FAJARDO VALDERRAMA',
        'file_name': 'mapa_soporte_4_fajardo.png',
        'cmap': 'Greens',
        'title': 'Electoral Support: Sergio Fajardo Valderrama\nVote Percentage by Municipality',
        'label': '% votes for Fajardo'
    },
    {
        'name': 'CLAUDIA LÓPEZ',
        'file_name': 'mapa_soporte_5_claudia.png',
        'cmap': 'YlOrRd',
        'title': 'Electoral Support: Claudia López\nVote Percentage by Municipality',
        'label': '% votes for Claudia'
    }
]

# ==========================================
# 5. GENERAR LOS 5 MAPAS
# ==========================================
for config in candidates_config:
    cand_name = config['name']
    file_name = config['file_name']
    
    if cand_name not in gdf_mapped.columns:
        print(f"Candidato no encontrado en las columnas del dataset: {cand_name}")
        continue
        
    print(f"Generando mapa para {cand_name}...")
    
    # Configurar la figura
    fig, ax = plt.subplots(figsize=(10, 12), dpi=300)
    ax.set_facecolor('#f7f9fa')
    fig.patch.set_facecolor('#f7f9fa')
    
    # Dibujar municipios de fondo (en gris claro si no hay datos)
    gdf_mapped.plot(ax=ax, color='#e5e5e5', edgecolor='#ffffff', linewidth=0.08)
    
    # Calcular el vmax dinámicamente usando el percentil 98 para mejorar la visibilidad geográfica
    max_val = gdf_mapped[cand_name].max()
    p98 = gdf_mapped[cand_name].quantile(0.98)
    # Evitar divisiones por cero o escalas colapsadas
    vmax = max(p98, 5.0)
    
    # Graficar el soporte del candidato
    gdf_mapped.plot(
        column=cand_name,
        ax=ax,
        cmap=config['cmap'],
        vmin=0.0,
        vmax=vmax,
        edgecolor='#ffffff',
        linewidth=0.08,
        legend=True,
        legend_kwds={
            'label': f"{config['label']} (Max scale adjusted to {vmax:.1f}% for visibility)",
            'orientation': 'horizontal',
            'pad': 0.05,
            'shrink': 0.7
        }
    )
    
    # Configurar títulos y estilo
    ax.set_title(config['title'], fontsize=14, fontweight='bold', pad=20, color='#2c3e50')
    ax.axis('off')
    plt.tight_layout()
    
    # Guardar mapa
    plt.savefig(file_name, bbox_inches='tight', facecolor='#f7f9fa')
    plt.close()
    print(f"¡Mapa guardado como {file_name}!")

print("\nTodos los 5 mapas se han generado exitosamente.")
