import pandas as pd
from datetime import datetime, timedelta
from utils.logger import setup_logger
from config.settings import GOLD_THRESHOLD, SILVER_THRESHOLD

logger = setup_logger()

def build_dim_temps(date_debut, date_fin):
    """
    Generate all dates with specified columns
    """
    logger.info("Building dim_temps")
    dates = pd.date_range(start=date_debut, end=date_fin, freq='D')
    df = pd.DataFrame({'date': dates})
    df['id_date'] = df['date'].dt.strftime('%Y%m%d').astype(int)
    df['jour'] = df['date'].dt.day
    df['mois'] = df['date'].dt.month
    df['trimestre'] = df['date'].dt.quarter
    df['annee'] = df['date'].dt.year
    df['semaine'] = df['date'].dt.isocalendar().week
    df['libelle_jour'] = df['date'].dt.day_name(locale='fr_FR')
    df['libelle_mois'] = df['date'].dt.month_name(locale='fr_FR')
    df['est_weekend'] = df['date'].dt.weekday >= 5
    
    # Moroccan holidays (approximate)
    holidays = [
        '2020-01-01', '2020-05-01', '2020-07-30', '2020-08-14', '2020-08-20', '2020-08-21', '2020-11-06', '2020-11-18',
        '2021-01-01', '2021-05-01', '2021-07-20', '2021-08-14', '2021-08-20', '2021-08-21', '2021-11-06', '2021-11-18',
        '2022-01-01', '2022-05-01', '2022-07-09', '2022-08-14', '2022-08-20', '2022-08-21', '2022-11-06', '2022-11-18',
        '2023-01-01', '2023-05-01', '2023-06-28', '2023-08-14', '2023-08-20', '2023-08-21', '2023-11-06', '2023-11-18',
        '2024-01-01', '2024-05-01', '2024-06-16', '2024-08-14', '2024-08-20', '2024-08-21', '2024-11-06', '2024-11-18',
        '2025-01-01', '2025-05-01', '2025-06-05', '2025-08-14', '2025-08-20', '2025-08-21', '2025-11-06', '2025-11-18'
    ]
    df['est_ferie_maroc'] = df['date'].dt.strftime('%Y-%m-%d').isin(holidays)
    
    # Ramadan periods (approximate)
    ramadan_periods = [
        ('2022-04-02', '2022-05-01'), ('2023-03-22', '2023-04-20'), ('2024-03-11', '2024-04-09'), ('2025-03-01', '2025-03-30')
    ]
    df['periode_ramadan'] = False
    for start, end in ramadan_periods:
        mask = (df['date'] >= start) & (df['date'] <= end)
        df.loc[mask, 'periode_ramadan'] = True
    
    df = df.drop(columns='date')
    logger.info(f"dim_temps built with {len(df)} rows")
    return df

def build_dim_client(df_clients, df_commandes):
    """
    Build dim_client with surrogate key and segment
    """
    logger.info("Building dim_client")
    df = df_clients.copy()
    df['id_client_sk'] = range(1, len(df) + 1)
    
    # Calculate segment based on last 12 months CA
    today = datetime.now()
    one_year_ago = today - timedelta(days=365)
    df_commandes['date_commande'] = pd.to_datetime(df_commandes['date_commande'])
    delivered = df_commandes[(df_commandes['statut'] == 'livré') & (df_commandes['date_commande'] >= one_year_ago)]
    ca = delivered.groupby('id_client')['montant_ttc'].sum().reset_index()
    df = df.merge(ca, on='id_client', how='left')
    df['montant_ttc'] = df['montant_ttc'].fillna(0)
    df['segment_client'] = pd.cut(df['montant_ttc'], bins=[-1, SILVER_THRESHOLD, GOLD_THRESHOLD, float('inf')], labels=['Bronze', 'Silver', 'Gold'])
    df = df.drop(columns='montant_ttc')
    
    df['date_debut'] = today.strftime('%Y-%m-%d')
    df['date_fin'] = '9999-12-31'
    df['est_actif'] = True
    logger.info(f"dim_client built with {len(df)} rows")
    return df

def build_dim_produit(df_produits):
    """
    Build dim_produit with surrogate key
    """
    logger.info("Building dim_produit")
    df = df_produits.copy()
    df['id_produit_sk'] = range(1, len(df) + 1)
    today = datetime.now().strftime('%Y-%m-%d')
    df['date_debut'] = today
    df['date_fin'] = '9999-12-31'
    df['est_actif'] = True
    logger.info(f"dim_produit built with {len(df)} rows")
    return df

def build_dim_region(df_regions):
    """
    Build dim_region with id_region
    """
    logger.info("Building dim_region")
    df = df_regions.copy()
    df['id_region'] = range(1, len(df) + 1)
    logger.info(f"dim_region built with {len(df)} rows")
    return df

def build_dim_livreur(df_commandes):
    """
    Build dim_livreur from unique id_livreur
    """
    logger.info("Building dim_livreur")
    livreurs = df_commandes['id_livreur'].unique()
    df = pd.DataFrame({'id_livreur': livreurs})
    # Add unknown row
    if '-1' not in df['id_livreur'].values:
        df = pd.concat([df, pd.DataFrame({'id_livreur': ['-1']})], ignore_index=True)
    df['nom_livreur'] = df['id_livreur'].apply(lambda x: 'Inconnu' if x == '-1' else f'Livreur {x}')
    logger.info(f"dim_livreur built with {len(df)} rows")
    return df

def build_fait_ventes(df_commandes, dim_temps, dim_client, dim_produit, dim_region, dim_livreur):
    """
    Build fait_ventes with joins and calculations
    """
    logger.info("Building fait_ventes")
    df = df_commandes.copy()
    df['date_commande'] = pd.to_datetime(df['date_commande'])
    df['date_livraison'] = pd.to_datetime(df['date_livraison'])
    df['id_date'] = df['date_commande'].dt.strftime('%Y%m%d').astype(int)
    df['delai_livraison_jours'] = (df['date_livraison'] - df['date_commande']).dt.days
    
    # Joins
    df = df.merge(dim_temps[['id_date']], on='id_date', how='left')
    df = df.merge(dim_produit[['id_produit', 'id_produit_sk']], on='id_produit', how='left')
    df = df.merge(dim_client[['id_client', 'id_client_sk']], on='id_client', how='left')
    df = df.merge(dim_region[['nom_ville_standard', 'id_region']], left_on='ville_livraison', right_on='nom_ville_standard', how='left')
    df = df.merge(dim_livreur[['id_livreur']], on='id_livreur', how='left')
    
    # Fill missing FK
    df['id_region'] = df['id_region'].fillna(1)
    df['id_livreur'] = df['id_livreur'].fillna(1)  # Assuming id_livreur is the key, but wait, dim_livreur has id_livreur as key
    
    # Select columns
    df = df[['id_date', 'id_produit_sk', 'id_client_sk', 'id_region', 'id_livreur', 'quantite', 'prix_unitaire', 'montant_ttc', 'delai_livraison_jours', 'statut']]
    df = df.rename(columns={'quantite': 'quantite_vendue', 'prix_unitaire': 'montant_ht', 'statut': 'statut_commande'})
    df['montant_ht'] = pd.to_numeric(df['montant_ht']) * pd.to_numeric(df['quantite_vendue'])
    
    logger.info(f"fait_ventes built with {len(df)} rows")
    return df