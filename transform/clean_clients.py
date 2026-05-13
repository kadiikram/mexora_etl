import pandas as pd
import re
from datetime import datetime
from utils.logger import setup_logger

logger = setup_logger()

def transform_clients(df, df_regions):
    """
    Transform clients dataframe with 6 rules
    """
    logger.info("Starting transformation of clients")
    
    # R1: Deduplicate on normalized email, keep most recent date_inscription
    logger.info(f"Before R1: {len(df)} rows")
    df['email_normalized'] = df['email'].str.lower().str.strip()
    df['date_inscription'] = pd.to_datetime(df['date_inscription'])
    df = df.sort_values('date_inscription').drop_duplicates(subset='email_normalized', keep='last')
    df = df.drop(columns='email_normalized')
    logger.info(f"After R1: {len(df)} rows")
    
    # R2: Standardize sexe
    logger.info("Applying R2: Standardizing sexe")
    sexe_mapping = {
        'm': 'm', '1': 'm', 'homme': 'm', 'male': 'm', 'h': 'm',
        'f': 'f', '0': 'f', 'femme': 'f', 'female': 'f'
    }
    df['sexe'] = df['sexe'].map(sexe_mapping).fillna('inconnu')
    logger.info("R2 completed")
    
    # R3: Validate date_naissance
    logger.info("Applying R3: Validating date_naissance")
    df['date_naissance'] = pd.to_datetime(df['date_naissance'], errors='coerce')
    today = datetime.now()
    df['age'] = (today - df['date_naissance']).dt.days // 365
    df.loc[(df['age'] < 16) | (df['age'] > 100), 'date_naissance'] = pd.NaT
    df = df.drop(columns='age')
    logger.info("R3 completed")
    
    # R4: Add tranche_age column
    logger.info("Applying R4: Adding tranche_age")
    bins = [0, 18, 25, 35, 45, 55, 65, 200]
    labels = ['<18', '18-24', '25-34', '35-44', '45-54', '55-64', '65+']
    df['tranche_age'] = pd.cut(df['date_naissance'].dt.year.apply(lambda x: today.year - x if pd.notna(x) else 0), bins=bins, labels=labels, right=False)
    logger.info("R4 completed")
    
    # R5: Validate email format
    logger.info("Applying R5: Validating email format")
    email_regex = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
    df['email'] = df['email'].where(df['email'].str.match(email_regex, na=False), None)
    logger.info("R5 completed")
    
    # R6: Normalize ville
    logger.info("Applying R6: Normalizing ville")
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
    df['ville'] = df['ville'].str.strip().str.lower().map(mapping).fillna('Non renseignée')
    logger.info("R6 completed")
    
    logger.info("Transformation of clients completed")
    return df