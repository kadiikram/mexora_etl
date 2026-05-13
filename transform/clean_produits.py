import pandas as pd
from utils.logger import setup_logger

logger = setup_logger()

def transform_produits(df):
    """
    Transform produits dataframe
    """
    logger.info("Starting transformation of produits")
    
    # Normalize categorie to title case
    logger.info("Normalizing categorie to title case")
    df['categorie'] = df['categorie'].str.title()
    logger.info("Categorie normalized")
    
    # Fill null prix_catalogue with median price of same categorie
    logger.info("Filling null prix_catalogue with median of categorie")
    df['prix_catalogue'] = pd.to_numeric(df['prix_catalogue'], errors='coerce')
    medians = df.groupby('categorie')['prix_catalogue'].median()
    df['prix_catalogue'] = df.apply(lambda row: medians[row['categorie']] if pd.isna(row['prix_catalogue']) else row['prix_catalogue'], axis=1)
    logger.info("Null prix_catalogue filled")
    
    # Keep actif=false products but flag them
    logger.info("Flagging inactive products")
    df['actif'] = df['actif'].astype(bool)
    df['flag_inactif'] = ~df['actif']
    logger.info("Inactive products flagged")
    
    # Add column categorie_normalized
    logger.info("Adding categorie_normalized column")
    df['categorie_normalized'] = df['categorie']
    logger.info("categorie_normalized added")
    
    logger.info("Transformation of produits completed")
    return df