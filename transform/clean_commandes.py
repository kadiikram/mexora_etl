import pandas as pd
from utils.logger import setup_logger

logger = setup_logger()

def transform_commandes(df, df_regions):
    """
    Transform commandes dataframe with 7 rules, each logged before/after
    """
    logger.info("Starting transformation of commandes")
    
    # R1: Remove duplicates on id_commande (keep last)
    logger.info(f"Before R1: {len(df)} rows")
    df = df.drop_duplicates(subset='id_commande', keep='last')
    logger.info(f"After R1: {len(df)} rows")
    
    # R2: Standardize dates to YYYY-MM-DD
    logger.info("Applying R2: Standardizing dates")
    df['date_commande'] = pd.to_datetime(df['date_commande'], format='mixed', dayfirst=True).dt.strftime('%Y-%m-%d')
    df['date_livraison'] = pd.to_datetime(df['date_livraison'], format='mixed', dayfirst=True).dt.strftime('%Y-%m-%d')
    logger.info("R2 completed")
    
    # R3: Normalize ville_livraison
    logger.info("Applying R3: Normalizing ville_livraison")
    # Build mapping from dirty variants to standard names
    mapping = {
        'casablanca': 'Casablanca', 'CASABLANCA': 'Casablanca', 'casa': 'Casablanca', 'csa': 'Casablanca',
        'tanger': 'Tanger', 'TNG': 'Tanger', 'TANGER': 'Tanger', 'tnja': 'Tanger', 'tanja': 'Tanger',
        'rabat': 'Rabat', 'RABAT': 'Rabat',
        'marrakech': 'Marrakech', 'marrakech': 'Marrakech',
        'fes': 'Fès', 'FES': 'Fès', 'fès': 'Fès',
        'agadir': 'Agadir', 'agadir': 'Agadir',
        'meknes': 'Meknès', 'meknès': 'Meknès',
        'oujda': 'Oujda', 'OUJDA': 'Oujda'
    }
    df['ville_livraison'] = df['ville_livraison'].str.strip().str.lower().map(mapping).fillna('Non renseignée')
    logger.info("R3 completed")
    
    # R4: Standardize statut
    logger.info("Applying R4: Standardizing statut")
    statut_mapping = {
        'livré': 'livré', 'livre': 'livré', 'LIVRE': 'livré', 'DONE': 'livré',
        'annulé': 'annulé', 'annule': 'annulé', 'KO': 'annulé',
        'en_cours': 'en_cours', 'OK': 'en_cours',
        'retourné': 'retourné', 'retourne': 'retourné'
    }
    df['statut'] = df['statut'].map(statut_mapping).fillna('inconnu')
    logger.info("R4 completed")
    
    # R5: Remove rows where quantite <= 0
    logger.info(f"Before R5: {len(df)} rows")
    df = df[pd.to_numeric(df['quantite'], errors='coerce') > 0]
    logger.info(f"After R5: {len(df)} rows")
    
    # R6: Remove rows where prix_unitaire = 0
    logger.info(f"Before R6: {len(df)} rows")
    df = df[pd.to_numeric(df['prix_unitaire'], errors='coerce') != 0]
    logger.info(f"After R6: {len(df)} rows")
    
    # R7: Fill missing id_livreur with "-1"
    logger.info("Applying R7: Filling missing id_livreur")
    df['id_livreur'] = df['id_livreur'].fillna('-1')
    logger.info("R7 completed")
    
    # Add montant_ttc
    logger.info("Adding montant_ttc column")
    df['montant_ttc'] = pd.to_numeric(df['quantite']) * pd.to_numeric(df['prix_unitaire']) * 1.20
    logger.info("montant_ttc added")
    
    logger.info("Transformation of commandes completed")
    return df