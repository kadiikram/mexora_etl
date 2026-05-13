import os

# Base directory
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# File paths for data files
COMMANDES_FILEPATH = os.path.join(BASE_DIR, 'data', 'commandes_mexora.csv')
PRODUITS_FILEPATH = os.path.join(BASE_DIR, 'data', 'produits_mexora.json')
CLIENTS_FILEPATH = os.path.join(BASE_DIR, 'data', 'clients_mexora.csv')
REGIONS_FILEPATH = os.path.join(BASE_DIR, 'data', 'regions_maroc.csv')

# PostgreSQL connection string
DB_CONNECTION_STRING = 'postgresql://postgres:20020314@localhost:5432/mexora_dwh'

# Schema names
STAGING_SCHEMA = 'staging_mexora'
DWH_SCHEMA = 'dwh_mexora'
REPORTING_SCHEMA = 'reporting_mexora'

# TVA rate
TVA_RATE = 0.20  # 20%

# Client segment thresholds (in MAD)
GOLD_THRESHOLD = 15000
SILVER_THRESHOLD = 5000