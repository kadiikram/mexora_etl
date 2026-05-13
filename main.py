import time
from sqlalchemy import create_engine
from utils.logger import setup_logger
from config.settings import (
    COMMANDES_FILEPATH, PRODUITS_FILEPATH, CLIENTS_FILEPATH, REGIONS_FILEPATH,
    DB_CONNECTION_STRING
)
from extract.extractor import extract_commandes, extract_produits, extract_clients, extract_regions
from transform.clean_commandes import transform_commandes
from transform.clean_clients import transform_clients
from transform.clean_produits import transform_produits
from transform.build_dimensions import (
    build_dim_temps, build_dim_client, build_dim_produit, build_dim_region, build_dim_livreur, build_fait_ventes
)
from load.loader import charger_dimension, charger_faits

logger = setup_logger()

def main():
    try:
        start_time = time.time()
        
        # 1. Setup logging (already done)
        
        # 2. Extract
        logger.info("Starting extraction")
        df_commandes = extract_commandes(COMMANDES_FILEPATH)
        df_produits = extract_produits(PRODUITS_FILEPATH)
        df_clients = extract_clients(CLIENTS_FILEPATH)
        df_regions = extract_regions(REGIONS_FILEPATH)
        logger.info("Extraction completed")
        
        # 3. Transform
        logger.info("Starting transformation")
        df_commandes_clean = transform_commandes(df_commandes, df_regions)
        df_clients_clean = transform_clients(df_clients, df_regions)
        df_produits_clean = transform_produits(df_produits)
        logger.info("Transformation completed")
        
        # 4. Build dimensions
        logger.info("Starting dimension building")
        dim_temps = build_dim_temps('2020-01-01', '2025-12-31')
        dim_client = build_dim_client(df_clients_clean, df_commandes_clean)
        dim_produit = build_dim_produit(df_produits_clean)
        dim_region = build_dim_region(df_regions)
        dim_livreur = build_dim_livreur(df_commandes_clean)
        logger.info("Dimension building completed")
        
        # 5. Build fait_ventes
        logger.info("Starting fait_ventes building")
        fait_ventes = build_fait_ventes(df_commandes_clean, dim_temps, dim_client, dim_produit, dim_region, dim_livreur)
        logger.info("fait_ventes building completed")
        
        # 6. Load
        logger.info("Starting loading")
        engine = create_engine(DB_CONNECTION_STRING)
        charger_dimension(dim_temps, 'dim_temps', engine)
        charger_dimension(dim_client, 'dim_client', engine)
        charger_dimension(dim_produit, 'dim_produit', engine)
        charger_dimension(dim_region, 'dim_region', engine)
        charger_dimension(dim_livreur, 'dim_livreur', engine)
        charger_faits(fait_ventes, engine)
        logger.info("Loading completed")
        
        # 7. Log duration
        duration = time.time() - start_time
        logger.info(f"Pipeline completed in {duration:.2f} seconds")
        
    except Exception as e:
        logger.error(f"Pipeline failed: {str(e)}")
        raise

if __name__ == "__main__":
    main()