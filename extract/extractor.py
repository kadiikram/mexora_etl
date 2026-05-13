import json
import pandas as pd
from utils.logger import setup_logger

logger = setup_logger()

def extract_commandes(filepath):
    """
    Reads CSV with dtype=str, logs row count
    """
    logger.info(f"Extracting commandes from {filepath}")
    df = pd.read_csv(filepath, dtype=str)
    logger.info(f"Extracted {len(df)} rows from commandes")
    return df

def extract_produits(filepath):
    """
    Reads JSON key "produits", logs row count
    """
    logger.info(f"Extracting produits from {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    df = pd.DataFrame(data['produits'])
    logger.info(f"Extracted {len(df)} products from produits")
    return df

def extract_clients(filepath):
    """
    Reads CSV with dtype=str, logs row count
    """
    logger.info(f"Extracting clients from {filepath}")
    df = pd.read_csv(filepath, dtype=str)
    logger.info(f"Extracted {len(df)} rows from clients")
    return df

def extract_regions(filepath):
    """
    Reads CSV, logs row count
    """
    logger.info(f"Extracting regions from {filepath}")
    df = pd.read_csv(filepath)
    logger.info(f"Extracted {len(df)} rows from regions")
    return df