# Mexora ETL - PostgreSQL Data Warehouse Setup Documentation

## Overview

This document describes the complete PostgreSQL Data Warehouse setup for the Mexora ETL project. The schema includes three layers: staging, data warehouse (DWH), and reporting with dimensions (including SCD Type 2 implementations), a fact table, indexes, and materialized views.

---

## Project Structure

```
sql/
├── mexora_dw_setup.sql      # Main DW schema script (ready for pgAdmin)
└── README.md                 # This documentation
```

---

## Schema Architecture

### 1. Three-Layer Schema Design

| Schema | Purpose | Tables |
|--------|---------|--------|
| `staging_mexora` | Raw data staging area | (User-defined for data ingestion) |
| `dwh_mexora` | Cleaned and transformed data | Dimensions + Fact table |
| `reporting_mexora` | Analytical layer | Materialized views + Views |

---

## 2. Dimension Tables

### 2.1 `dim_temps` (Time Dimension)
**Purpose**: Centralized time reference for all fact records

**Key Columns**:
- `id_date` (PK): YYYY-MM-DD format date
- `jour`, `mois`, `trimestre`, `annee`, `semaine`: Time components
- `libelle_jour`, `libelle_mois`: Human-readable labels
- `est_weekend`: Boolean flag for weekends
- `est_ferie_maroc`: Boolean flag for Moroccan holidays
- `periode_ramadan`: Boolean flag for Ramadan period

**Indexes**:
- `(annee, mois)`: For monthly aggregations
- `(trimestre)`: For quarterly analysis

**Usage**: Join point for all date-based queries

---

### 2.2 `dim_produit` (Product Dimension - SCD Type 2)
**Purpose**: Product catalog with change tracking

**Key Columns**:
- `id_produit_sk` (PK): Surrogate key (auto-increment)
- `id_produit_nk`: Natural key from source system (unique + date_debut)
- `nom_produit`, `categorie`: Product attributes
- `prix_unitaire_ht`, `prix_unitaire_ttc`: Pricing
- `est_actif`: Current active flag
- `date_debut`, `date_fin`: SCD Type 2 effective dates
- `date_creation`, `date_modification`: Audit timestamps

**SCD Type 2 Implementation**:
- When a product attribute changes, close the old record (set `date_fin`) and insert a new record with new values
- Queries always filter `WHERE date_fin IS NULL` for current records
- Historical queries can use date ranges

**Indexes**:
- `(id_produit_nk)`: Natural key lookups
- `(categorie)`: Category-based filtering
- `(est_actif)`: Active product filtering
- `(date_debut, date_fin)`: SCD Type 2 temporal queries

**Example - Adding a Product History**:
```sql
-- Initial insert
INSERT INTO dwh_mexora.dim_produit (id_produit_nk, nom_produit, categorie, prix_unitaire_ht, prix_unitaire_ttc, est_actif, date_debut)
VALUES ('PROD-001', 'Téléphone X', 'Électronique', 2000, 2400, TRUE, '2025-01-01');

-- Product price change (SCD Type 2)
UPDATE dwh_mexora.dim_produit 
SET date_fin = '2025-06-30' 
WHERE id_produit_nk = 'PROD-001' AND date_fin IS NULL;

INSERT INTO dwh_mexora.dim_produit (id_produit_nk, nom_produit, categorie, prix_unitaire_ht, prix_unitaire_ttc, est_actif, date_debut)
VALUES ('PROD-001', 'Téléphone X', 'Électronique', 1800, 2160, TRUE, '2025-07-01');
```

---

### 2.3 `dim_client` (Client Dimension - SCD Type 2)
**Purpose**: Client master data with change tracking

**Key Columns**:
- `id_client_sk` (PK): Surrogate key
- `id_client_nk`: Natural key from source system
- `nom_client`, `prenom_client`: Client name
- `email_client`, `telephone_client`: Contact information
- `segment_client`: Client segment (Premium, Standard, Bronze, VIP)
- `tranche_age`: Age bracket
- `sexe`: Gender (M, F, O)
- `date_naissance`: Birth date
- `ville`, `region_admin`: Geographic location
- `canal_acquisition`: How client was acquired
- `date_inscription`: Registration date
- `est_actif`: Current active flag
- `date_debut`, `date_fin`: SCD Type 2 effective dates

**SCD Type 2 Implementation**:
- Tracks client profile changes (segment, address, contact info)
- Historical queries possible using date ranges
- Current queries filter `WHERE date_fin IS NULL`

**Constraints**:
- `segment_client` IN ('Premium', 'Standard', 'Bronze', 'VIP')
- `sexe` IN ('M', 'F', 'O')

**Indexes**:
- `(id_client_nk)`: Natural key lookups
- `(segment_client)`: Segment-based analysis
- `(region_admin)`: Geographic filtering
- `(date_debut, date_fin)`: SCD Type 2 temporal queries

---

### 2.4 `dim_region` (Region Dimension)
**Purpose**: Geographic reference for Morocco

**Key Columns**:
- `id_region` (PK): Surrogate key
- `id_region_nk`: Natural key (unique)
- `ville`: City name
- `province`, `region_admin`: Administrative levels
- `zone_geo`: Geographic zone classification
- `pays`: Country (default: 'Maroc')
- `latitude`, `longitude`: Geographic coordinates
- `population`: Population estimate

**Indexes**:
- `(region_admin)`: Regional filtering
- `(zone_geo)`: Zone-based filtering
- `(ville)`: City lookups

---

### 2.5 `dim_livreur` (Delivery Partner Dimension)
**Purpose**: Delivery network reference

**Key Columns**:
- `id_livreur` (PK): Surrogate key
- `id_livreur_nk`: Natural key from source system (unique)
- `nom_livreur`: Delivery partner name
- `email_livreur`, `telephone_livreur`: Contact information
- `type_transport`: Mode of delivery (Motocyclette, Voiture, Camion, Vélo, À pied)
- `zone_couverture`: Geographic coverage
- `region_admin`, `ville_base`: Assigned region and base city
- `est_actif`: Active status
- `date_entree`, `date_sortie`: Employment dates
- `capacite_transport`: Delivery capacity (units)
- `note_moyenne_livraison`: Average delivery rating

**Constraints**:
- `type_transport` IN ('Motocyclette', 'Voiture', 'Camion', 'Vélo', 'À pied')

**Indexes**:
- `(est_actif)`: Active partners filtering
- `(region_admin)`: Regional analysis
- `(type_transport)`: Transport type filtering

---

## 3. Fact Table: `fait_ventes` (Sales)

**Purpose**: Central fact table for all sales transactions

**Structure**:

| Column | Type | Constraints | Purpose |
|--------|------|-----------|---------|
| `id_vente` | BIGSERIAL | PK | Surrogate key |
| `id_vente_nk` | VARCHAR(100) | UNIQUE | Natural key from source |
| `id_date_commande` | DATE | FK → dim_temps | Order date |
| `id_date_livraison` | DATE | FK → dim_temps | Delivery date (nullable) |
| `id_produit_sk` | BIGINT | FK → dim_produit | Product surrogate key |
| `id_client_sk` | BIGINT | FK → dim_client | Client surrogate key |
| `id_region` | BIGINT | FK → dim_region | Region surrogate key |
| `id_livreur` | BIGINT | FK → dim_livreur | Delivery partner (nullable) |
| `quantite_vendue` | INT | NOT NULL, CHECK > 0 | Quantity sold |
| `montant_ht` | DECIMAL(12,2) | NOT NULL, CHECK >= 0 | Amount before tax |
| `montant_ttc` | DECIMAL(12,2) | NOT NULL, CHECK >= 0 | Amount including tax |
| `cout_livraison` | DECIMAL(10,2) | NOT NULL, CHECK >= 0 | Delivery cost |
| `delai_livraison_jours` | INT | Nullable | Delivery delay in days |
| `remise_pct` | DECIMAL(5,2) | CHECK 0-100 | Discount percentage |
| `statut_commande` | VARCHAR(50) | NOT NULL | Order status (7 values) |
| `est_remboursee` | BOOLEAN | DEFAULT FALSE | Refund flag |
| `est_livrée_a_temps` | BOOLEAN | Nullable | On-time delivery flag |
| `date_chargement` | TIMESTAMP | DEFAULT NOW() | Load timestamp |
| `date_modification` | TIMESTAMP | DEFAULT NOW() | Last modification |

**Statut Values**:
- `Pendante`: Awaiting confirmation
- `Confirmée`: Order confirmed
- `Expédiée`: In transit
- `Livrée`: Delivered
- `Annulée`: Cancelled
- `Retournée`: Returned
- `En cours`: In progress

**Referential Integrity**:
- All foreign keys reference current records in dimensions
- For SCD Type 2 dimensions (produit, client), join via surrogate keys which remain stable

---

## 4. Indexes Strategy

### Foreign Key Indexes (Single-column)
```sql
idx_fait_ventes_id_date_commande        -- Temporal filtering
idx_fait_ventes_id_date_livraison       -- Delivery analysis
idx_fait_ventes_id_produit_sk           -- Product analysis
idx_fait_ventes_id_client_sk            -- Customer analysis
idx_fait_ventes_id_region               -- Geographic analysis
idx_fait_ventes_id_livreur              -- Delivery performance
```

### Composite Indexes (Multi-column for analytics)
```sql
idx_fait_ventes_date_region             -- Revenue by region/time
idx_fait_ventes_date_client             -- Customer trends over time
idx_fait_ventes_date_produit            -- Product trends over time
idx_fait_ventes_client_region           -- Customer geographic analysis
```

### Partial Indexes (Conditional)
```sql
idx_fait_ventes_livree                  -- WHERE statut_commande = 'Livrée'
idx_fait_ventes_statut                  -- WHERE statut IN (pending states)
idx_fait_ventes_livreur_delai           -- WHERE delai_livraison_jours IS NOT NULL
```

**Index Usage Examples**:

```sql
-- Query 1: Revenue by region (uses idx_fait_ventes_date_region)
SELECT id_region, SUM(montant_ttc) 
FROM dwh_mexora.fait_ventes 
WHERE id_date_commande BETWEEN '2026-01-01' AND '2026-12-31'
GROUP BY id_region;

-- Query 2: Delivery performance (uses idx_fait_ventes_livreur_delai)
SELECT id_livreur, AVG(delai_livraison_jours) 
FROM dwh_mexora.fait_ventes 
WHERE delai_livraison_jours IS NOT NULL 
GROUP BY id_livreur;

-- Query 3: Find late deliveries (uses idx_fait_ventes_livree)
SELECT COUNT(*) 
FROM dwh_mexora.fait_ventes 
WHERE statut_commande = 'Livrée' AND est_livrée_a_temps = FALSE;
```

---

## 5. Materialized Views

### 5.1 `mv_ca_mensuel` - Monthly Revenue by Region & Category

**Purpose**: Pre-aggregated monthly revenue metrics

**Key Metrics**:
- `ca_ht`: Monthly revenue before tax
- `ca_ttc`: Monthly revenue including tax
- `nombre_commandes`: Order count
- `quantite_totale`: Total units sold
- `cout_livraison_total`: Total delivery costs
- `remise_pct_moyenne`: Average discount percentage
- `panier_moyen`: Average order value
- `commandes_livrees`: Delivered orders count
- `taux_ponctualite_pct`: On-time delivery percentage

**Dimensions**:
- `annee`, `mois`, `libelle_mois`: Time dimensions
- `region_admin`: Geographic dimension
- `categorie`: Product category

**Refresh**:
```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_mexora.mv_ca_mensuel;
```

**Example Query**:
```sql
-- Top revenue regions for 2026-05
SELECT region_admin, ca_ttc, nombre_commandes, taux_ponctualite_pct
FROM reporting_mexora.mv_ca_mensuel
WHERE annee = 2026 AND mois = 5
ORDER BY ca_ttc DESC;
```

---

### 5.2 `mv_top_produits` - Top Products per Quarter

**Purpose**: Identify best-selling products by period

**Key Metrics**:
- `nombre_ventes`: Transaction count
- `quantite_totale`: Units sold
- `montant_ttc_total`: Total revenue
- `prix_moyen_ht`: Average selling price
- `rang_ca`: Rank by revenue within quarter

**Dimensions**:
- `annee`, `trimestre`, `periode_trimestre`: Time dimensions
- `id_produit_nk`, `nom_produit`, `categorie`: Product attributes

**Refresh**:
```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_mexora.mv_top_produits;
```

**Example Query**:
```sql
-- Top 10 products in Q2 2026
SELECT nom_produit, categorie, montant_ttc_total, rang_ca
FROM reporting_mexora.mv_top_produits
WHERE annee = 2026 AND trimestre = 2 AND rang_ca <= 10
ORDER BY rang_ca;
```

---

### 5.3 `mv_performance_livreurs` - Delivery Partner Performance

**Purpose**: Monitor delivery metrics and KPIs

**Key Metrics**:
- `nombre_livraisons`: Total deliveries handled
- `livraisons_completees`: Successfully completed deliveries
- `livraisons_probleme`: Cancelled or returned deliveries
- `taux_ponctualite_pct`: On-time delivery percentage
- `delai_moyen_jours`: Average delivery time
- `ecart_type_delai`: Delivery time consistency (standard deviation)
- `taux_retard_pct`: Percentage of deliveries > 3 days
- `note_moyenne`: Average client rating

**Dimensions**:
- `id_livreur`, `nom_livreur`: Delivery partner info
- `type_transport`: Vehicle type
- `region_admin`: Assigned region

**Refresh**:
```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_mexora.mv_performance_livreurs;
```

**Example Query**:
```sql
-- Identify underperforming delivery partners
SELECT nom_livreur, type_transport, taux_ponctualite_pct, taux_retard_pct, note_moyenne
FROM reporting_mexora.mv_performance_livreurs
WHERE taux_ponctualite_pct < 80 OR taux_retard_pct > 15
ORDER BY taux_ponctualite_pct ASC;
```

---

## 6. Materialized View Maintenance

### Refresh All Views
```sql
-- Procedure to refresh all materialized views concurrently
CALL reporting_mexora.refresh_all_materialized_views();
```

**What "CONCURRENTLY" means**:
- Maintains indexes while refreshing
- Prevents long-term table locks
- Allows queries to continue (slower performance during refresh)
- Must have a unique index on the materialized view

### Automated Refresh (Optional - pgAdmin Task Scheduler)
Create a scheduled job to refresh views at off-peak hours:
```sql
-- Example: Refresh daily at 2 AM
-- (Use pgAdmin > Tools > Maintenance > Create Job)
```

---

## 7. Reporting Views (Real-time, Non-materialized)

### 7.1 `vw_ventes_temps_reel`
**Purpose**: Real-time sales view with current dimensions

**Features**:
- Always shows current dimension attributes (SCD Type 2 aware)
- Joins all relevant dimensions
- Filters for active records (dim_client.date_fin IS NULL, etc.)

**Use Case**: Real-time dashboards, operational reports

**Example Query**:
```sql
SELECT * FROM reporting_mexora.vw_ventes_temps_reel
WHERE date_commande = CURRENT_DATE;
```

---

### 7.2 `vw_segmentation_client`
**Purpose**: Dynamic customer segmentation based on spending

**Segments**:
- VIP: >= 50,000 DH
- Premium: 20,000 - 49,999 DH
- Regular: 5,000 - 19,999 DH
- Bronze: < 5,000 DH

**Metrics**:
- `nombre_achats`: Purchase count
- `ca_client`: Total customer value
- `ticket_moyen`: Average order value
- `dernier_achat`: Last purchase date
- `segment_calculé`: Computed segment

**Use Case**: Customer analytics, retention programs

**Example Query**:
```sql
-- Identify VIP customers
SELECT nom_client, segment_client, ca_client, nombre_achats
FROM reporting_mexora.vw_segmentation_client
WHERE segment_calculé = 'VIP'
ORDER BY ca_client DESC;
```

---

## 8. Data Quality Checks

### Real-time Data Quality View
```sql
SELECT * FROM reporting_mexora.vw_data_quality_checks;
```

**Checks**:
- Orphaned products (FK references missing)
- Orphaned clients
- Orphaned regions
- Invalid date references

**Action**: If any check returns > 0, investigate and fix source data before proceeding.

---

## 9. Implementation Steps for pgAdmin

### Step 1: Download and Open the Script
1. Save the file `mexora_dw_setup.sql` on your computer
2. Open pgAdmin 4
3. Connect to your PostgreSQL database

### Step 2: Execute the Script
**Option A - Recommended (Full Script)**:
1. Right-click on your database → Query Tool
2. File → Open → Select `mexora_dw_setup.sql`
3. Click the lightning bolt icon (Execute) or press F5
4. Wait for completion (check Notifications panel)

**Option B - Line by Line**:
1. For debugging: Execute schemas first, then dimensions, then facts, then views
2. Check for errors after each section

### Step 3: Verify Installation
```sql
-- Check schemas exist
SELECT schema_name FROM information_schema.schemata 
WHERE schema_name LIKE '%mexora%';

-- Check tables in DWH schema
SELECT tablename FROM pg_tables WHERE schemaname = 'dwh_mexora';

-- Check materialized views
SELECT schemaname, matviewname FROM pg_matviews 
WHERE schemaname = 'reporting_mexora';

-- Check indexes
SELECT indexname FROM pg_indexes 
WHERE schemaname = 'dwh_mexora';
```

### Step 4: Load Sample Data (Optional)
See the `ETL_LoadSampleData.sql` script (if available) for test data loading.

### Step 5: Refresh Materialized Views
```sql
CALL reporting_mexora.refresh_all_materialized_views();
```

---

## 10. Constraints Summary

### NOT NULL Constraints
- All foreign keys in fact table
- `quantite_vendue`, `montant_ht`, `montant_ttc`, `cout_livraison`
- `statut_commande`
- All natural keys (`id_*_nk`)

### CHECK Constraints
- `quantite_vendue > 0`
- `montant_ht >= 0`, `montant_ttc >= 0`, `cout_livraison >= 0`
- `remise_pct BETWEEN 0 AND 100`
- `jour BETWEEN 1 AND 31`, `mois BETWEEN 1 AND 12`, etc.
- `type_transport IN (...)`, `segment_client IN (...)`

### UNIQUE Constraints
- `id_vente_nk` (fact table)
- `id_client_nk + date_debut` (SCD Type 2)
- `id_produit_nk + date_debut` (SCD Type 2)
- `id_region_nk`, `id_livreur_nk`

### FOREIGN KEY Constraints
- All fact table FKs reference dimension PKs
- Cascading deletes NOT used (integrity preserved via SCD)

---

## 11. Performance Optimization Tips

### Query Examples

**1. Sales by Region (Fast - uses composite index)**:
```sql
SELECT 
  dr.region_admin,
  SUM(fv.montant_ttc) as total_revenue,
  COUNT(DISTINCT fv.id_vente) as order_count
FROM dwh_mexora.fait_ventes fv
INNER JOIN dwh_mexora.dim_region dr ON fv.id_region = dr.id_region
WHERE fv.id_date_commande BETWEEN '2026-01-01' AND '2026-05-31'
GROUP BY dr.region_admin
ORDER BY total_revenue DESC;
```

**2. Delivery Performance Dashboard**:
```sql
SELECT * 
FROM reporting_mexora.mv_performance_livreurs
WHERE taux_ponctualite_pct < 85
ORDER BY taux_ponctualite_pct ASC;
```

**3. Customer Analysis with SCD Type 2**:
```sql
SELECT 
  dc.nom_client,
  dc.segment_client,
  COUNT(DISTINCT fv.id_vente) as purchases,
  SUM(fv.montant_ttc) as total_spent
FROM dwh_mexora.dim_client dc
INNER JOIN dwh_mexora.fait_ventes fv ON dc.id_client_sk = fv.id_client_sk
WHERE dc.date_fin IS NULL  -- Current record only
GROUP BY dc.id_client_sk, dc.nom_client, dc.segment_client
ORDER BY total_spent DESC;
```

### Maintenance Tasks

**Weekly**: Analyze tables and refresh statistics
```sql
ANALYZE dwh_mexora.fait_ventes;
ANALYZE dwh_mexora.dim_client;
ANALYZE dwh_mexora.dim_produit;
```

**Weekly**: Refresh materialized views
```sql
CALL reporting_mexora.refresh_all_materialized_views();
```

**Monthly**: Check for unused indexes
```sql
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'dwh_mexora'
ORDER BY idx_scan DESC;
```

---

## 12. Troubleshooting

### Issue: "Column does not exist" when querying fact table
**Solution**: Ensure SCD Type 2 dimension queries filter `WHERE date_fin IS NULL`

### Issue: Materialized view refresh is slow
**Solution**: 
- Run during off-peak hours
- Check query complexity in materialized view definition
- Consider partial refreshes if available

### Issue: Foreign key constraint violations during load
**Solution**:
- Load dimensions first, facts last
- Verify natural keys match between source and target
- Check for NULL values in FK columns

### Issue: Query timeout
**Solution**:
- Check if required indexes exist (run ANALYZE)
- Use materialized views instead of base tables
- Consider query optimization (EXPLAIN ANALYZE)

---

## 13. SCD Type 2 Implementation Details

### When to Create a New Record

**Scenario 1: Product Price Change**
```sql
-- Old record
UPDATE dwh_mexora.dim_produit 
SET date_fin = '2026-05-11' 
WHERE id_produit_nk = 'PROD-001' AND date_fin IS NULL;

-- New record
INSERT INTO dwh_mexora.dim_produit (id_produit_nk, nom_produit, prix_unitaire_ht, prix_unitaire_ttc, date_debut)
VALUES ('PROD-001', 'Téléphone X', 1900, 2280, '2026-05-12');
```

**Scenario 2: Client Segment Change**
```sql
-- Mark old record as inactive
UPDATE dwh_mexora.dim_client 
SET date_fin = '2026-05-11' 
WHERE id_client_nk = 'CLI-0001' AND date_fin IS NULL;

-- Insert new record with updated segment
INSERT INTO dwh_mexora.dim_client (id_client_nk, nom_client, segment_client, date_debut)
SELECT id_client_nk, nom_client, 'Premium', '2026-05-12'
FROM dwh_mexora.dim_client 
WHERE id_client_nk = 'CLI-0001' AND date_fin IS NOT NULL
ORDER BY date_fin DESC LIMIT 1;
```

### Historical Queries

**Example: Get all price changes for a product**
```sql
SELECT 
  id_produit_sk,
  nom_produit,
  prix_unitaire_ht,
  prix_unitaire_ttc,
  date_debut,
  date_fin
FROM dwh_mexora.dim_produit
WHERE id_produit_nk = 'PROD-001'
ORDER BY date_debut;
```

**Example: Get customer info as of a specific date**
```sql
SELECT 
  nom_client,
  segment_client,
  ville
FROM dwh_mexora.dim_client
WHERE id_client_nk = 'CLI-0001' 
  AND date_debut <= '2026-03-01' 
  AND (date_fin IS NULL OR date_fin > '2026-03-01');
```

---

## 14. Additional Resources

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Data Warehouse Design: https://en.wikipedia.org/wiki/Data_warehouse
- Slowly Changing Dimensions: https://en.wikipedia.org/wiki/Slowly_changing_dimension
- pgAdmin Documentation: https://www.pgadmin.org/docs/

---

## Contact & Support

For questions or issues with this Data Warehouse schema, refer to:
- Schema documentation in SQL comments (`COMMENT ON ...` statements)
- Data quality views
- PostgreSQL error logs (in pgAdmin Tools > Server Logs)

---

**Last Updated**: May 12, 2026
**Version**: 1.0
**Status**: Production Ready
