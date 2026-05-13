from sqlalchemy import create_engine
from utils.logger import setup_logger
from config.settings import DB_CONNECTION_STRING, DWH_SCHEMA

logger = setup_logger()

def charger_dimension(df, table_name, engine, schema=DWH_SCHEMA):
    """
    Load dimension table
    """
    logger.info(f"Loading dimension {table_name} with {len(df)} rows")
    df.to_sql(table_name, engine, schema=schema, if_exists='replace', index=False, method='multi', chunksize=1000)
    logger.info(f"Loaded {table_name}")

def charger_faits(df, engine, schema=DWH_SCHEMA):
    """
    Load facts table
    """
    logger.info(f"Loading facts fait_ventes with {len(df)} rows")
    df.to_sql('fait_ventes', engine, schema=schema, if_exists='replace', index=False, method='multi', chunksize=5000)
    logger.info("Loaded fait_ventes")