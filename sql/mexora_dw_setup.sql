/**
 * ============================================================================
 * MEXORA ETL - PostgreSQL Data Warehouse Complete Setup
 * ============================================================================
 * Description: Complete Data Warehouse schema with dimensions (SCD Type 2),
 *              fact tables, indexes, and materialized views
 * Created: 2026-05-12
 * Database: PostgreSQL 12+
 * ============================================================================
 */

-- ============================================================================
-- 1. SCHEMA CREATION
-- ============================================================================

-- Staging schema for raw data
CREATE SCHEMA IF NOT EXISTS staging_mexora
  AUTHORIZATION postgres;

COMMENT ON SCHEMA staging_mexora IS 'Staging area for raw data ingestion';

-- Data Warehouse schema for cleaned and transformed data
CREATE SCHEMA IF NOT EXISTS dwh_mexora
  AUTHORIZATION postgres;

COMMENT ON SCHEMA dwh_mexora IS 'Data Warehouse schema with dimensions and facts';

-- Reporting schema for analytical views
CREATE SCHEMA IF NOT EXISTS reporting_mexora
  AUTHORIZATION postgres;

COMMENT ON SCHEMA reporting_mexora IS 'Reporting layer with materialized views and analytics';


-- ============================================================================
-- 2. DIMENSION TABLES
-- ============================================================================

-- ============================================================================
-- 2.1 DIM_TEMPS (Time Dimension)
-- ============================================================================
CREATE TABLE dwh_mexora.dim_temps (
  id_date DATE PRIMARY KEY,
  jour INT NOT NULL CHECK (jour BETWEEN 1 AND 31),
  mois INT NOT NULL CHECK (mois BETWEEN 1 AND 12),
  trimestre INT NOT NULL CHECK (trimestre BETWEEN 1 AND 4),
  annee INT NOT NULL CHECK (annee >= 2000),
  semaine INT NOT NULL CHECK (semaine BETWEEN 1 AND 53),
  libelle_jour VARCHAR(20) NOT NULL,
  libelle_mois VARCHAR(20) NOT NULL,
  est_weekend BOOLEAN NOT NULL DEFAULT FALSE,
  est_ferie_maroc BOOLEAN NOT NULL DEFAULT FALSE,
  periode_ramadan BOOLEAN NOT NULL DEFAULT FALSE,
  date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_temps_annee_mois ON dwh_mexora.dim_temps(annee, mois);
CREATE INDEX idx_dim_temps_trimestre ON dwh_mexora.dim_temps(trimestre);

COMMENT ON TABLE dwh_mexora.dim_temps IS 'Time dimension table with dates, months, quarters';
COMMENT ON COLUMN dwh_mexora.dim_temps.id_date IS 'Primary key - date in YYYY-MM-DD format';


-- ============================================================================
-- 2.2 DIM_PRODUIT (Product Dimension - SCD Type 2)
-- ============================================================================
CREATE TABLE dwh_mexora.dim_produit (
  id_produit_sk BIGSERIAL PRIMARY KEY,
  id_produit_nk VARCHAR(50) NOT NULL,
  nom_produit VARCHAR(255) NOT NULL,
  description_produit TEXT,
  categorie VARCHAR(100),
  prix_unitaire_ht DECIMAL(10, 2) NOT NULL CHECK (prix_unitaire_ht >= 0),
  prix_unitaire_ttc DECIMAL(10, 2) NOT NULL CHECK (prix_unitaire_ttc >= 0),
  stock_initial INT DEFAULT 0 CHECK (stock_initial >= 0),
  poids_kg DECIMAL(8, 2),
  fournisseur VARCHAR(100),
  est_actif BOOLEAN NOT NULL DEFAULT TRUE,
  date_debut DATE NOT NULL DEFAULT CURRENT_DATE,
  date_fin DATE,
  date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(id_produit_nk, date_debut)
);

CREATE INDEX idx_dim_produit_nk ON dwh_mexora.dim_produit(id_produit_nk);
CREATE INDEX idx_dim_produit_categorie ON dwh_mexora.dim_produit(categorie);
CREATE INDEX idx_dim_produit_est_actif ON dwh_mexora.dim_produit(est_actif);
CREATE INDEX idx_dim_produit_date_debut_fin ON dwh_mexora.dim_produit(date_debut, date_fin);

COMMENT ON TABLE dwh_mexora.dim_produit IS 'Product dimension with Slowly Changing Dimension Type 2';
COMMENT ON COLUMN dwh_mexora.dim_produit.id_produit_sk IS 'Surrogate key';
COMMENT ON COLUMN dwh_mexora.dim_produit.id_produit_nk IS 'Natural key from source system';


-- ============================================================================
-- 2.3 DIM_CLIENT (Client Dimension - SCD Type 2)
-- ============================================================================
CREATE TABLE dwh_mexora.dim_client (
  id_client_sk BIGSERIAL PRIMARY KEY,
  id_client_nk VARCHAR(50) NOT NULL,
  nom_client VARCHAR(255) NOT NULL,
  prenom_client VARCHAR(255),
  email_client VARCHAR(255),
  telephone_client VARCHAR(20),
  segment_client VARCHAR(50) DEFAULT 'Standard' CHECK (segment_client IN ('Premium', 'Standard', 'Bronze', 'VIP')),
  tranche_age VARCHAR(50),
  sexe CHAR(1) CHECK (sexe IN ('M', 'F', 'O')),
  date_naissance DATE,
  ville VARCHAR(100),
  region_admin VARCHAR(100),
  code_postal VARCHAR(10),
  canal_acquisition VARCHAR(100),
  date_inscription DATE,
  est_actif BOOLEAN NOT NULL DEFAULT TRUE,
  date_debut DATE NOT NULL DEFAULT CURRENT_DATE,
  date_fin DATE,
  date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(id_client_nk, date_debut)
);

CREATE INDEX idx_dim_client_nk ON dwh_mexora.dim_client(id_client_nk);
CREATE INDEX idx_dim_client_segment ON dwh_mexora.dim_client(segment_client);
CREATE INDEX idx_dim_client_region ON dwh_mexora.dim_client(region_admin);
CREATE INDEX idx_dim_client_date_debut_fin ON dwh_mexora.dim_client(date_debut, date_fin);

COMMENT ON TABLE dwh_mexora.dim_client IS 'Client dimension with Slowly Changing Dimension Type 2';
COMMENT ON COLUMN dwh_mexora.dim_client.id_client_sk IS 'Surrogate key';
COMMENT ON COLUMN dwh_mexora.dim_client.id_client_nk IS 'Natural key from source system';


-- ============================================================================
-- 2.4 DIM_REGION (Region Dimension)
-- ============================================================================
CREATE TABLE dwh_mexora.dim_region (
  id_region BIGSERIAL PRIMARY KEY,
  id_region_nk VARCHAR(50) NOT NULL UNIQUE,
  ville VARCHAR(100) NOT NULL,
  province VARCHAR(100),
  region_admin VARCHAR(100),
  zone_geo VARCHAR(100),
  pays VARCHAR(100) NOT NULL DEFAULT 'Maroc',
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  population INT,
  date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_region_admin ON dwh_mexora.dim_region(region_admin);
CREATE INDEX idx_dim_region_zone_geo ON dwh_mexora.dim_region(zone_geo);
CREATE INDEX idx_dim_region_ville ON dwh_mexora.dim_region(ville);

COMMENT ON TABLE dwh_mexora.dim_region IS 'Geographic region dimension for Morocco';


-- ============================================================================
-- 2.5 DIM_LIVREUR (Delivery Partner Dimension)
-- ============================================================================
CREATE TABLE dwh_mexora.dim_livreur (
  id_livreur BIGSERIAL PRIMARY KEY,
  id_livreur_nk VARCHAR(50) NOT NULL UNIQUE,
  nom_livreur VARCHAR(255) NOT NULL,
  email_livreur VARCHAR(255),
  telephone_livreur VARCHAR(20),
  type_transport VARCHAR(100) NOT NULL CHECK (type_transport IN ('Motocyclette', 'Voiture', 'Camion', 'Vélo', 'À pied')),
  zone_couverture VARCHAR(255),
  region_admin VARCHAR(100),
  ville_base VARCHAR(100),
  est_actif BOOLEAN NOT NULL DEFAULT TRUE,
  date_entree DATE,
  date_sortie DATE,
  capacite_transport INT CHECK (capacite_transport > 0),
  note_moyenne_livraison DECIMAL(3, 2),
  date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_livreur_actif ON dwh_mexora.dim_livreur(est_actif);
CREATE INDEX idx_dim_livreur_region ON dwh_mexora.dim_livreur(region_admin);
CREATE INDEX idx_dim_livreur_type_transport ON dwh_mexora.dim_livreur(type_transport);

COMMENT ON TABLE dwh_mexora.dim_livreur IS 'Delivery partner dimension';


-- ============================================================================
-- 3. FACT TABLE
-- ============================================================================

-- ============================================================================
-- 3.1 FAIT_VENTES (Sales Fact Table)
-- ============================================================================
CREATE TABLE dwh_mexora.fait_ventes (
  id_vente BIGSERIAL PRIMARY KEY,
  id_vente_nk VARCHAR(100) NOT NULL UNIQUE,
  
  -- Foreign Keys (Dimensions)
  id_date_commande DATE NOT NULL REFERENCES dwh_mexora.dim_temps(id_date),
  id_date_livraison DATE REFERENCES dwh_mexora.dim_temps(id_date),
  id_produit_sk BIGINT NOT NULL REFERENCES dwh_mexora.dim_produit(id_produit_sk),
  id_client_sk BIGINT NOT NULL REFERENCES dwh_mexora.dim_client(id_client_sk),
  id_region BIGINT NOT NULL REFERENCES dwh_mexora.dim_region(id_region),
  id_livreur BIGINT REFERENCES dwh_mexora.dim_livreur(id_livreur),
  
  -- Fact Measures
  quantite_vendue INT NOT NULL CHECK (quantite_vendue > 0),
  montant_ht DECIMAL(12, 2) NOT NULL CHECK (montant_ht >= 0),
  montant_ttc DECIMAL(12, 2) NOT NULL CHECK (montant_ttc >= 0),
  cout_livraison DECIMAL(10, 2) NOT NULL CHECK (cout_livraison >= 0),
  delai_livraison_jours INT,
  remise_pct DECIMAL(5, 2) DEFAULT 0 CHECK (remise_pct BETWEEN 0 AND 100),
  
  -- Metadata
  statut_commande VARCHAR(50) NOT NULL DEFAULT 'En cours' CHECK (statut_commande IN ('Pendante', 'Confirmée', 'Expédiée', 'Livrée', 'Annulée', 'Retournée', 'En cours')),
  est_remboursee BOOLEAN DEFAULT FALSE,
  est_livrée_a_temps BOOLEAN,
  
  -- Audit
  date_chargement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dwh_mexora.fait_ventes IS 'Sales fact table with all measures and dimensions';
COMMENT ON COLUMN dwh_mexora.fait_ventes.quantite_vendue IS 'Quantity sold in units';
COMMENT ON COLUMN dwh_mexora.fait_ventes.montant_ht IS 'Amount before tax (HT)';
COMMENT ON COLUMN dwh_mexora.fait_ventes.montant_ttc IS 'Amount including tax (TTC)';
COMMENT ON COLUMN dwh_mexora.fait_ventes.delai_livraison_jours IS 'Number of days between order and delivery';


-- ============================================================================
-- 4. INDEXES FOR FACT TABLE
-- ============================================================================

-- Foreign Key Indexes
CREATE INDEX idx_fait_ventes_id_date_commande 
  ON dwh_mexora.fait_ventes(id_date_commande);

CREATE INDEX idx_fait_ventes_id_date_livraison 
  ON dwh_mexora.fait_ventes(id_date_livraison);

CREATE INDEX idx_fait_ventes_id_produit_sk 
  ON dwh_mexora.fait_ventes(id_produit_sk);

CREATE INDEX idx_fait_ventes_id_client_sk 
  ON dwh_mexora.fait_ventes(id_client_sk);

CREATE INDEX idx_fait_ventes_id_region 
  ON dwh_mexora.fait_ventes(id_region);

CREATE INDEX idx_fait_ventes_id_livreur 
  ON dwh_mexora.fait_ventes(id_livreur);

-- Composite Indexes for Analytical Queries
CREATE INDEX idx_fait_ventes_date_region 
  ON dwh_mexora.fait_ventes(id_date_commande, id_region);

CREATE INDEX idx_fait_ventes_date_client 
  ON dwh_mexora.fait_ventes(id_date_commande, id_client_sk);

CREATE INDEX idx_fait_ventes_date_produit 
  ON dwh_mexora.fait_ventes(id_date_commande, id_produit_sk);

CREATE INDEX idx_fait_ventes_client_region 
  ON dwh_mexora.fait_ventes(id_client_sk, id_region);

-- Partial Indexes
CREATE INDEX idx_fait_ventes_livree 
  ON dwh_mexora.fait_ventes(id_date_livraison) 
  WHERE statut_commande = 'Livrée';

CREATE INDEX idx_fait_ventes_statut 
  ON dwh_mexora.fait_ventes(statut_commande) 
  WHERE statut_commande IN ('Pendante', 'Confirmée', 'Expédiée');

-- Index for temporal analysis
CREATE INDEX idx_fait_ventes_livreur_delai 
  ON dwh_mexora.fait_ventes(id_livreur, delai_livraison_jours) 
  WHERE delai_livraison_jours IS NOT NULL;


-- ============================================================================
-- 5. MATERIALIZED VIEWS
-- ============================================================================

-- ============================================================================
-- 5.1 MV_CA_MENSUEL (Monthly Revenue by Region and Category)
-- ============================================================================
CREATE MATERIALIZED VIEW reporting_mexora.mv_ca_mensuel AS
SELECT
  dt.annee,
  dt.mois,
  dt.libelle_mois,
  dr.region_admin,
  dp.categorie,
  COUNT(DISTINCT fv.id_vente) AS nombre_commandes,
  SUM(fv.quantite_vendue) AS quantite_totale,
  SUM(fv.montant_ht) AS ca_ht,
  SUM(fv.montant_ttc) AS ca_ttc,
  SUM(fv.cout_livraison) AS cout_livraison_total,
  AVG(fv.remise_pct) AS remise_pct_moyenne,
  ROUND(SUM(fv.montant_ttc) / NULLIF(COUNT(DISTINCT fv.id_vente), 0), 2) AS panier_moyen,
  COUNT(DISTINCT CASE WHEN fv.statut_commande = 'Livrée' THEN fv.id_vente END) AS commandes_livrees,
  ROUND(100.0 * COUNT(DISTINCT CASE WHEN fv.est_livrée_a_temps THEN fv.id_vente END) 
        / NULLIF(COUNT(DISTINCT CASE WHEN fv.statut_commande = 'Livrée' THEN fv.id_vente END), 1), 2) AS taux_ponctualite_pct
FROM
  dwh_mexora.fait_ventes fv
  INNER JOIN dwh_mexora.dim_temps dt ON fv.id_date_commande = dt.id_date
  INNER JOIN dwh_mexora.dim_region dr ON fv.id_region = dr.id_region
  INNER JOIN dwh_mexora.dim_produit dp ON fv.id_produit_sk = dp.id_produit_sk
WHERE
  dp.est_actif = TRUE
GROUP BY
  dt.annee,
  dt.mois,
  dt.libelle_mois,
  dr.region_admin,
  dp.categorie;

CREATE UNIQUE INDEX idx_mv_ca_mensuel_pk 
  ON reporting_mexora.mv_ca_mensuel(annee, mois, region_admin, categorie);

COMMENT ON MATERIALIZED VIEW reporting_mexora.mv_ca_mensuel IS 
  'Monthly revenue by region and category - refreshable materialized view';


-- ============================================================================
-- 5.2 MV_TOP_PRODUITS (Top Products per Quarter)
-- ============================================================================
CREATE MATERIALIZED VIEW reporting_mexora.mv_top_produits AS
SELECT
  dt.annee,
  dt.trimestre,
  CONCAT('Q', dt.trimestre, ' ', dt.annee) AS periode_trimestre,
  dp.id_produit_nk,
  dp.nom_produit,
  dp.categorie,
  COUNT(DISTINCT fv.id_vente) AS nombre_ventes,
  SUM(fv.quantite_vendue) AS quantite_totale,
  SUM(fv.montant_ht) AS montant_ht_total,
  SUM(fv.montant_ttc) AS montant_ttc_total,
  ROUND(AVG(fv.montant_ht / NULLIF(fv.quantite_vendue, 0)), 2) AS prix_moyen_ht,
  ROW_NUMBER() OVER (PARTITION BY dt.annee, dt.trimestre ORDER BY SUM(fv.montant_ttc) DESC) AS rang_ca
FROM
  dwh_mexora.fait_ventes fv
  INNER JOIN dwh_mexora.dim_temps dt ON fv.id_date_commande = dt.id_date
  INNER JOIN dwh_mexora.dim_produit dp ON fv.id_produit_sk = dp.id_produit_sk
WHERE
  dp.est_actif = TRUE
  AND fv.statut_commande IN ('Confirmée', 'Expédiée', 'Livrée')
GROUP BY
  dt.annee,
  dt.trimestre,
  dp.id_produit_nk,
  dp.nom_produit,
  dp.categorie;

CREATE UNIQUE INDEX idx_mv_top_produits_pk 
  ON reporting_mexora.mv_top_produits(annee, trimestre, id_produit_nk);

COMMENT ON MATERIALIZED VIEW reporting_mexora.mv_top_produits IS 
  'Top products per quarter by revenue - refreshable materialized view';


-- ============================================================================
-- 5.3 MV_PERFORMANCE_LIVREURS (Delivery Partner Performance)
-- ============================================================================
CREATE MATERIALIZED VIEW reporting_mexora.mv_performance_livreurs AS
SELECT
  dl.id_livreur,
  dl.id_livreur_nk,
  dl.nom_livreur,
  dl.type_transport,
  dl.region_admin,
  COUNT(DISTINCT fv.id_vente) AS nombre_livraisons,
  COUNT(DISTINCT CASE WHEN fv.statut_commande = 'Livrée' THEN fv.id_vente END) AS livraisons_completees,
  COUNT(DISTINCT CASE WHEN fv.statut_commande IN ('Annulée', 'Retournée') THEN fv.id_vente END) AS livraisons_probleme,
  ROUND(100.0 * COUNT(DISTINCT CASE WHEN fv.est_livrée_a_temps = TRUE THEN fv.id_vente END) 
        / NULLIF(COUNT(DISTINCT CASE WHEN fv.statut_commande = 'Livrée' THEN fv.id_vente END), 1), 2) AS taux_ponctualite_pct,
  ROUND(AVG(fv.delai_livraison_jours), 2) AS delai_moyen_jours,
  ROUND(STDDEV(fv.delai_livraison_jours), 2) AS ecart_type_delai,
  MIN(fv.delai_livraison_jours) AS delai_min_jours,
  MAX(fv.delai_livraison_jours) AS delai_max_jours,
  COUNT(DISTINCT CASE WHEN fv.delai_livraison_jours > 3 THEN fv.id_vente END) AS livraisons_retard_3j,
  ROUND(100.0 * COUNT(DISTINCT CASE WHEN fv.delai_livraison_jours > 3 THEN fv.id_vente END) 
        / NULLIF(COUNT(DISTINCT fv.id_vente), 1), 2) AS taux_retard_pct,
  ROUND(AVG(dl.note_moyenne_livraison), 2) AS note_moyenne,
  MAX(fv.date_chargement) AS derniere_maj
FROM
  dwh_mexora.fait_ventes fv
  INNER JOIN dwh_mexora.dim_livreur dl ON fv.id_livreur = dl.id_livreur
WHERE
  fv.statut_commande = 'Livrée'
GROUP BY
  dl.id_livreur,
  dl.id_livreur_nk,
  dl.nom_livreur,
  dl.type_transport,
  dl.region_admin;

CREATE UNIQUE INDEX idx_mv_performance_livreurs_pk 
  ON reporting_mexora.mv_performance_livreurs(id_livreur);

COMMENT ON MATERIALIZED VIEW reporting_mexora.mv_performance_livreurs IS 
  'Delivery partner performance metrics - refreshable materialized view';


-- ============================================================================
-- 6. REFRESH STORED PROCEDURES FOR MATERIALIZED VIEWS
-- ============================================================================

CREATE OR REPLACE PROCEDURE reporting_mexora.refresh_all_materialized_views()
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE NOTICE 'Refreshing materialized view: mv_ca_mensuel';
  REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_mexora.mv_ca_mensuel;
  
  RAISE NOTICE 'Refreshing materialized view: mv_top_produits';
  REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_mexora.mv_top_produits;
  
  RAISE NOTICE 'Refreshing materialized view: mv_performance_livreurs';
  REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_mexora.mv_performance_livreurs;
  
  RAISE NOTICE 'All materialized views refreshed successfully';
END;
$$;

COMMENT ON PROCEDURE reporting_mexora.refresh_all_materialized_views() IS 
  'Refresh all materialized views concurrently';


-- ============================================================================
-- 7. UTILITY VIEWS FOR REPORTING (Non-materialized, real-time)
-- ============================================================================

-- Real-time sales performance view
CREATE OR REPLACE VIEW reporting_mexora.vw_ventes_temps_reel AS
SELECT
  fv.id_vente,
  fv.id_vente_nk,
  dt.id_date AS date_commande,
  dt.libelle_jour,
  dt.libelle_mois,
  dt.annee,
  dc.nom_client,
  dc.segment_client,
  dr.ville,
  dr.region_admin,
  dp.nom_produit,
  dp.categorie,
  fv.quantite_vendue,
  fv.montant_ht,
  fv.montant_ttc,
  fv.remise_pct,
  fv.cout_livraison,
  fv.delai_livraison_jours,
  fv.statut_commande,
  dl.nom_livreur,
  dl.type_transport
FROM
  dwh_mexora.fait_ventes fv
  INNER JOIN dwh_mexora.dim_temps dt ON fv.id_date_commande = dt.id_date
  INNER JOIN dwh_mexora.dim_client dc ON fv.id_client_sk = dc.id_client_sk
  INNER JOIN dwh_mexora.dim_region dr ON fv.id_region = dr.id_region
  INNER JOIN dwh_mexora.dim_produit dp ON fv.id_produit_sk = dp.id_produit_sk
  LEFT JOIN dwh_mexora.dim_livreur dl ON fv.id_livreur = dl.id_livreur
WHERE
  dc.date_fin IS NULL
  AND dp.date_fin IS NULL;

COMMENT ON VIEW reporting_mexora.vw_ventes_temps_reel IS 
  'Real-time sales view with current dimension attributes';


-- Client segmentation view
CREATE OR REPLACE VIEW reporting_mexora.vw_segmentation_client AS
SELECT
  dc.id_client_sk,
  dc.id_client_nk,
  dc.nom_client,
  dc.segment_client,
  dc.region_admin,
  COUNT(DISTINCT fv.id_vente) AS nombre_achats,
  SUM(fv.montant_ttc) AS ca_client,
  AVG(fv.montant_ttc) AS ticket_moyen,
  MAX(fv.date_chargement) AS dernier_achat,
  CASE
    WHEN SUM(fv.montant_ttc) >= 50000 THEN 'VIP'
    WHEN SUM(fv.montant_ttc) >= 20000 THEN 'Premium'
    WHEN SUM(fv.montant_ttc) >= 5000 THEN 'Regular'
    ELSE 'Bronze'
  END AS segment_calculé
FROM
  dwh_mexora.dim_client dc
  LEFT JOIN dwh_mexora.fait_ventes fv ON dc.id_client_sk = fv.id_client_sk
WHERE
  dc.date_fin IS NULL
GROUP BY
  dc.id_client_sk,
  dc.id_client_nk,
  dc.nom_client,
  dc.segment_client,
  dc.region_admin;

COMMENT ON VIEW reporting_mexora.vw_segmentation_client IS 
  'Client segmentation based on purchase behavior';


-- ============================================================================
-- 8. PERMISSIONS AND SECURITY
-- ============================================================================

-- Grant schema permissions
GRANT USAGE ON SCHEMA dwh_mexora TO PUBLIC;
GRANT USAGE ON SCHEMA reporting_mexora TO PUBLIC;
GRANT USAGE ON SCHEMA staging_mexora TO PUBLIC;

-- Grant table permissions for DWH schema
GRANT SELECT ON ALL TABLES IN SCHEMA dwh_mexora TO PUBLIC;

-- Grant view permissions for reporting schema
GRANT SELECT ON ALL TABLES IN SCHEMA reporting_mexora TO PUBLIC;
GRANT SELECT ON ALL MATERIALIZED VIEWS IN SCHEMA reporting_mexora TO PUBLIC;

-- Grant procedure execution
GRANT EXECUTE ON PROCEDURE reporting_mexora.refresh_all_materialized_views() TO PUBLIC;


-- ============================================================================
-- 9. DATA QUALITY CHECKS (Optional)
-- ============================================================================

-- Check for orphaned records (optional - run after data load)
CREATE OR REPLACE VIEW reporting_mexora.vw_data_quality_checks AS
SELECT
  'Orphaned Products' AS check_name,
  COUNT(*) AS issue_count
FROM
  dwh_mexora.fait_ventes fv
  LEFT JOIN dwh_mexora.dim_produit dp ON fv.id_produit_sk = dp.id_produit_sk
WHERE
  dp.id_produit_sk IS NULL

UNION ALL

SELECT
  'Orphaned Clients' AS check_name,
  COUNT(*) AS issue_count
FROM
  dwh_mexora.fait_ventes fv
  LEFT JOIN dwh_mexora.dim_client dc ON fv.id_client_sk = dc.id_client_sk
WHERE
  dc.id_client_sk IS NULL

UNION ALL

SELECT
  'Orphaned Regions' AS check_name,
  COUNT(*) AS issue_count
FROM
  dwh_mexora.fait_ventes fv
  LEFT JOIN dwh_mexora.dim_region dr ON fv.id_region = dr.id_region
WHERE
  dr.id_region IS NULL

UNION ALL

SELECT
  'Invalid Date References' AS check_name,
  COUNT(*) AS issue_count
FROM
  dwh_mexora.fait_ventes fv
  LEFT JOIN dwh_mexora.dim_temps dt ON fv.id_date_commande = dt.id_date
WHERE
  dt.id_date IS NULL;

COMMENT ON VIEW reporting_mexora.vw_data_quality_checks IS 
  'Data quality checks for referential integrity';


-- ============================================================================
-- 10. DOCUMENTATION AND METADATA
-- ============================================================================

COMMENT ON SCHEMA dwh_mexora IS 
  'Data Warehouse schema containing dimensions and fact tables for Mexora ETL';

COMMENT ON TABLE dwh_mexora.fait_ventes IS 
  'Central fact table for sales transactions with measures (quantity, amounts, costs) and foreign key references to all dimensions';

COMMENT ON COLUMN dwh_mexora.fait_ventes.montant_ht IS 
  'Amount excluding tax (HT - Hors Taxes)';

COMMENT ON COLUMN dwh_mexora.fait_ventes.montant_ttc IS 
  'Amount including tax (TTC - Toutes Taxes Comprises)';

COMMENT ON COLUMN dwh_mexora.fait_ventes.delai_livraison_jours IS 
  'Number of days between order date and delivery date';

COMMENT ON COLUMN dwh_mexora.fait_ventes.remise_pct IS 
  'Discount percentage applied to the order';


-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
