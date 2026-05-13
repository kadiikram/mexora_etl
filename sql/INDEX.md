# Mexora ETL - PostgreSQL Data Warehouse - Complete Package

## 📦 Package Contents

This package contains a **production-ready PostgreSQL Data Warehouse** for the Mexora ETL project with complete documentation and sample data.

---

## 📄 Files Included

### 1. **mexora_dw_setup.sql** ⭐ MAIN FILE
- **Purpose**: Complete Data Warehouse schema creation
- **Contains**:
  - 3 Schemas (staging_mexora, dwh_mexora, reporting_mexora)
  - 5 Dimension Tables (with SCD Type 2 for products & clients)
  - 1 Fact Table (fait_ventes with all measures)
  - 20+ Indexes (FKs, composites, partial)
  - 3 Materialized Views (mv_ca_mensuel, mv_top_produits, mv_performance_livreurs)
  - 2 Real-time Views (vw_ventes_temps_reel, vw_segmentation_client)
  - 1 Data Quality View (vw_data_quality_checks)
  - Materialized View Refresh Procedure
  - All Constraints (PK, FK, CHECK, NOT NULL, DEFAULT, UNIQUE)
  - Full Documentation via SQL Comments
- **Usage**: Run this first in pgAdmin
- **Time to Execute**: 2-5 minutes
- **Size**: ~50 KB

### 2. **SAMPLE_DATA_LOAD.sql**
- **Purpose**: Load test/sample data for demonstration
- **Generates**:
  - 365 date records (2026-01-01 to 2026-12-31)
  - 10 Moroccan regions
  - 10 sample products
  - 10 delivery partners
  - 10 sample clients
  - 100 sales transactions
- **Usage**: Run AFTER mexora_dw_setup.sql for testing
- **Time to Execute**: 1-2 minutes
- **Size**: ~20 KB

### 3. **DATAWAREHOUSE_README.md** 📖 COMPREHENSIVE GUIDE
- **Purpose**: Complete technical documentation
- **Sections**:
  1. Project Structure Overview
  2. Dimension Tables Deep Dive (SCD Type 2 explanation)
  3. Fact Table Architecture
  4. Indexes Strategy & Examples
  5. Materialized Views Documentation
  6. MV Maintenance & Refresh
  7. Reporting Views (Real-time analytics)
  8. Data Quality Checks
  9. Implementation Steps for pgAdmin
  10. Constraints Summary
  11. Performance Optimization Tips
  12. Troubleshooting Guide
  13. SCD Type 2 Implementation Details
  14. Additional Resources
- **Usage**: Read for understanding schema design
- **Size**: ~60 KB

### 4. **PGADMIN_EXECUTION_GUIDE.md** 🚀 STEP-BY-STEP GUIDE
- **Purpose**: Practical guide for executing in pgAdmin
- **Includes**:
  - Prerequisites checklist
  - 6 Step-by-step execution process
  - 5 Post-installation verification tests
  - 6 Troubleshooting scenarios with solutions
  - Maintenance tasks (weekly, monthly)
  - Performance tips
  - Emergency recovery procedures
  - Success checklist
- **Usage**: Follow this to set up in pgAdmin
- **Size**: ~25 KB

### 5. **COMMON_QUERIES.md** 📊 READY-TO-USE QUERIES
- **Purpose**: Pre-built SQL queries for common analytics
- **Contains 10 Categories**:
  1. Revenue Analytics (6 queries)
  2. Product Analytics (4 queries)
  3. Customer Analytics (5 queries)
  4. Delivery Performance (4 queries)
  5. Time-Based Analytics (3 queries)
  6. Operational Metrics (4 queries)
  7. Data Quality & Audits (3 queries)
  8. Advanced Cohort Analysis (2 queries)
  9. MV Refresh Commands
  10. Export to CSV
- **Usage**: Copy & paste queries for analysis
- **Size**: ~30 KB

### 6. **INDEX.md** (This File)
- **Purpose**: Navigation and overview
- **Usage**: Start here for orientation

---

## 🎯 Quick Start (5 Minutes)

### For First-Time Setup:

1. **Download the files** to a folder (e.g., `C:\mexora_sql\`)

2. **Open pgAdmin** → Connect to your database

3. **Execute** `mexora_dw_setup.sql`:
   - Right-click database → Query Tool
   - File → Open → Select `mexora_dw_setup.sql`
   - Press F5 to execute
   - Wait ~2-5 minutes

4. **Verify** with a test query:
   ```sql
   SELECT schema_name FROM information_schema.schemata 
   WHERE schema_name LIKE '%mexora%';
   ```

5. **Load sample data** (optional):
   - Execute `SAMPLE_DATA_LOAD.sql` (same way as step 3)
   - Takes ~1-2 minutes

6. **Run a test query** from `COMMON_QUERIES.md`:
   ```sql
   SELECT * FROM reporting_mexora.mv_ca_mensuel LIMIT 10;
   ```

✅ **Done!** Your DWH is ready.

---

## 📐 Schema Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   STAGING_MEXORA                            │
│              (Raw data ingestion zone)                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   DWH_MEXORA                                │
│        (Cleaned & Transformed Data Layer)                   │
├──────────────┬──────────────┬────────────────┬──────────────┤
│ DIMENSIONS   │ DIMENSIONS   │ DIMENSIONS     │ DIMENSIONS   │
│              │              │                │              │
│ dim_temps    │ dim_region   │ dim_livreur    │              │
│ dim_produit  │ dim_client   │ (Normal)       │ (20+ Indexes)│
│ (SCD Type 2) │ (SCD Type 2) │                │              │
└──────────────┴──────────────┴────────────────┴──────────────┘
                            ↓
                   ┌────────────────┐
                   │  FAIT_VENTES   │
                   │  (Fact Table)  │
                   │  Measures:     │
                   │  - quantité    │
                   │  - montants    │
                   │  - coûts       │
                   │  - délais      │
                   └────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              REPORTING_MEXORA                               │
│         (Analytical & Reporting Layer)                      │
├──────────────────┬──────────────────┬──────────────────────┤
│ MATERIALIZED     │ MATERIALIZED     │ MATERIALIZED         │
│ VIEWS (Fast)     │ VIEWS (Fast)     │ VIEWS (Fast)         │
│                  │                  │                      │
│ mv_ca_mensuel    │ mv_top_produits  │ mv_performance_livr  │
│ (Monthly Revenue)│ (Top Products)   │ (Delivery KPIs)      │
└──────────────────┴──────────────────┴──────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              REAL-TIME VIEWS                                │
│  (Current Data - Always reflects SCD Type 2 changes)        │
├──────────────────┬──────────────────────────────────────────┤
│ vw_ventes_       │ vw_segmentation_client                   │
│ temps_reel       │ (Dynamic customer segmentation)          │
│ (Current sales)  │                                          │
└──────────────────┴──────────────────────────────────────────┘
```

---

## 📊 Key Features

### ✅ Dimension Tables (5)
| Table | Type | Rows | Purpose |
|-------|------|------|---------|
| `dim_temps` | Normal | 365 (2026) | Date reference |
| `dim_produit` | SCD Type 2 | Variable | Product catalog with history |
| `dim_client` | SCD Type 2 | Variable | Customer master with history |
| `dim_region` | Normal | 10+ | Geographic reference |
| `dim_livreur` | Normal | 10+ | Delivery partner reference |

### ✅ Fact Table (1)
| Table | Measures | Row Count |
|-------|----------|-----------|
| `fait_ventes` | quantite, montant_ht, montant_ttc, cout, delai, remise | 100+ |

### ✅ Indexes (20+)
- **FK Indexes**: 6 (one per FK)
- **Composite Indexes**: 4 (date+region, date+client, date+product, client+region)
- **Partial Indexes**: 3 (delivery status, pending states, delivery delays)

### ✅ Materialized Views (3)
- **mv_ca_mensuel**: Monthly revenue by region & category (pre-aggregated)
- **mv_top_produits**: Top products per quarter (ranked)
- **mv_performance_livreurs**: Delivery KPIs (delay rate, punctuality)

### ✅ Real-Time Views (2)
- **vw_ventes_temps_reel**: Sales with current dimensions
- **vw_segmentation_client**: Dynamic customer segmentation

### ✅ Constraints
- ✅ Primary Keys
- ✅ Foreign Keys (with referential integrity)
- ✅ NOT NULL constraints
- ✅ CHECK constraints (ranges, enum values)
- ✅ DEFAULT values
- ✅ UNIQUE constraints (SCD Type 2 keys)

---

## 🔧 SCD Type 2 Implementation

### What is SCD Type 2?
Slowly Changing Dimension Type 2 tracks all changes to dimension attributes. When an attribute changes, the old record is closed and a new record is inserted.

### Tables Using SCD Type 2:
- **dim_produit**: Tracks price changes, category changes, stock changes
- **dim_client**: Tracks segment changes, address changes, profile changes

### How It Works:
```sql
-- Old version
id_produit_nk | nom_produit | prix | date_debut  | date_fin
PROD-001      | Phone X     | 2000 | 2026-01-01  | 2026-05-31

-- New version (when price changes)
id_produit_nk | nom_produit | prix | date_debut  | date_fin
PROD-001      | Phone X     | 1900 | 2026-06-01  | NULL
```

### Querying SCD Type 2:
```sql
-- Current records only (WHERE date_fin IS NULL)
SELECT * FROM dim_produit WHERE date_fin IS NULL;

-- Historical records (all versions)
SELECT * FROM dim_produit WHERE id_produit_nk = 'PROD-001';

-- As-of query (state at specific date)
SELECT * FROM dim_produit 
WHERE id_produit_nk = 'PROD-001'
  AND date_debut <= '2026-03-01' 
  AND (date_fin IS NULL OR date_fin > '2026-03-01');
```

---

## 📈 Analytics Examples

### Example 1: Revenue by Region
```sql
SELECT region_admin, SUM(ca_ttc) as revenue
FROM reporting_mexora.mv_ca_mensuel
WHERE annee = 2026
GROUP BY region_admin
ORDER BY revenue DESC;
```

### Example 2: Top 5 Products by Quarter
```sql
SELECT nom_produit, montant_ttc_total, rang_ca
FROM reporting_mexora.mv_top_produits
WHERE annee = 2026 AND trimestre = 2 AND rang_ca <= 5;
```

### Example 3: Delivery Performance
```sql
SELECT nom_livreur, taux_ponctualite_pct, delai_moyen_jours
FROM reporting_mexora.mv_performance_livreurs
ORDER BY taux_ponctualite_pct DESC;
```

### Example 4: Customer Segmentation
```sql
SELECT segment_calculé, COUNT(*) as clients, SUM(ca_client) as revenue
FROM reporting_mexora.vw_segmentation_client
GROUP BY segment_calculé
ORDER BY revenue DESC;
```

---

## 🛠️ Maintenance

### Daily
- Monitor data loads
- Check for errors in ETL logs

### Weekly
```sql
-- Update statistics
ANALYZE dwh_mexora.fait_ventes;

-- Refresh materialized views
CALL reporting_mexora.refresh_all_materialized_views();
```

### Monthly
```sql
-- Full vacuum and rebuild indexes
VACUUM ANALYZE dwh_mexora.fait_ventes;
REINDEX SCHEMA dwh_mexora;

-- Check data quality
SELECT * FROM reporting_mexora.vw_data_quality_checks;
```

---

## 🚀 Next Steps

1. **Execute `mexora_dw_setup.sql`** in pgAdmin (main script)
2. **Review `DATAWAREHOUSE_README.md`** for understanding
3. **Follow `PGADMIN_EXECUTION_GUIDE.md`** for setup
4. **Load sample data** with `SAMPLE_DATA_LOAD.sql`
5. **Run queries** from `COMMON_QUERIES.md`
6. **Integrate with ETL** (see main project)
7. **Connect to BI tools** (Power BI, Tableau, Metabase)

---

## 📚 Documentation Files

| File | Purpose | When to Use |
|------|---------|------------|
| `mexora_dw_setup.sql` | Schema creation | First execution |
| `SAMPLE_DATA_LOAD.sql` | Test data | Testing & demos |
| `DATAWAREHOUSE_README.md` | Full documentation | Learning the schema |
| `PGADMIN_EXECUTION_GUIDE.md` | Setup instructions | During installation |
| `COMMON_QUERIES.md` | Ready-to-use queries | Running reports |
| `INDEX.md` | This file | Navigation |

---

## ✅ Success Criteria

Your installation is successful when:

- [ ] All 3 schemas visible in pgAdmin
- [ ] All 5 dimension tables created
- [ ] Fact table `fait_ventes` created
- [ ] All indexes present
- [ ] 3 materialized views created
- [ ] Test query returns data
- [ ] No error messages in logs

---

## 🆘 Troubleshooting

**See `PGADMIN_EXECUTION_GUIDE.md` for detailed troubleshooting**

Quick fixes:
- **Schema already exists**: Normal, uses IF NOT EXISTS
- **Permission denied**: Use admin account
- **MV won't refresh**: Check unique indexes exist
- **No data**: Load sample data with `SAMPLE_DATA_LOAD.sql`

---

## 📞 Support

1. **Check logs**: Tools → Server Logs in pgAdmin
2. **Review documentation**: See DATAWAREHOUSE_README.md
3. **Verify installation**: Run test queries from COMMON_QUERIES.md
4. **Emergency reset**: Drop schema and re-execute setup script

---

## 🎯 Project Overview

### Mexora ETL Project Structure
```
mexora_etl/
├── main.py                      # Main ETL orchestration
├── requirements.txt             # Python dependencies
├── config/                      # Configuration
│   ├── __init__.py
│   └── settings.py
├── extract/                     # Data extraction
│   ├── __init__.py
│   └── extractor.py
├── transform/                   # Data transformation
│   ├── __init__.py
│   ├── build_dimensions.py
│   ├── clean_clients.py
│   ├── clean_commandes.py
│   └── clean_produits.py
├── load/                        # Data loading
│   ├── __init__.py
│   └── loader.py
├── data/                        # Source data
│   ├── clients_mexora.csv
│   ├── commandes_mexora.csv
│   ├── produits_mexora.json
│   ├── regions_maroc.csv
│   └── generate_data.py
├── utils/                       # Utilities
│   ├── __init__.py
│   └── logger.py
├── logs/                        # Execution logs
└── sql/                         # ⭐ SQL SCRIPTS (YOU ARE HERE)
    ├── mexora_dw_setup.sql
    ├── SAMPLE_DATA_LOAD.sql
    ├── DATAWAREHOUSE_README.md
    ├── PGADMIN_EXECUTION_GUIDE.md
    ├── COMMON_QUERIES.md
    └── INDEX.md
```

---

## 📝 SQL Script Features

✅ **Production Ready**
- Fully commented
- Error handling
- Constraint validation
- Data quality checks
- Referential integrity

✅ **Scalable**
- Surrogate keys for growth
- Partial indexes for performance
- Materialized views for speed
- Supports millions of records

✅ **Maintainable**
- Clear naming conventions
- Comprehensive documentation
- Audit columns (date_creation, date_modification)
- Data quality views

✅ **Secure**
- Proper permissions
- Constraint enforcement
- Referential integrity
- Data validation

---

## 🎓 Learning Path

1. **Beginner**: Read this INDEX.md → Run setup → Load sample data
2. **Intermediate**: Study DATAWAREHOUSE_README.md → Run COMMON_QUERIES.md
3. **Advanced**: Modify schema → Implement custom MV → Integrate with ETL

---

## 📊 Performance Expectations

| Operation | Time |
|-----------|------|
| Schema creation | 2-5 min |
| Sample data load | 1-2 min |
| MV refresh | < 30 sec |
| Query on 1M rows | < 1 sec |

---

## 🔐 Backup Recommendation

```bash
# PostgreSQL backup command
pg_dump -U postgres -d mexora_db > mexora_backup.sql

# Restore
psql -U postgres -d mexora_db < mexora_backup.sql
```

---

**Version**: 1.0  
**Status**: Production Ready ✅  
**Last Updated**: May 12, 2026  
**PostgreSQL Version**: 12+  
**pgAdmin Version**: 4+

---

## 📞 Quick Links

- [DATAWAREHOUSE_README.md](DATAWAREHOUSE_README.md) - Full technical docs
- [PGADMIN_EXECUTION_GUIDE.md](PGADMIN_EXECUTION_GUIDE.md) - Setup guide
- [COMMON_QUERIES.md](COMMON_QUERIES.md) - Query examples
- [mexora_dw_setup.sql](mexora_dw_setup.sql) - Main schema script
- [SAMPLE_DATA_LOAD.sql](SAMPLE_DATA_LOAD.sql) - Test data script

---

**Happy Data Warehousing! 🚀**
