# Mexora DW - Step-by-Step pgAdmin Execution Guide

## Complete Setup Process for PostgreSQL Data Warehouse

This guide walks you through executing the Mexora DWH setup in pgAdmin 4 (Recommended).

---

## ✅ Prerequisites

Before starting, ensure you have:
- ✅ PostgreSQL 12+ installed and running
- ✅ pgAdmin 4 installed and accessible
- ✅ Database connection with admin privileges
- ✅ SQL files downloaded:
  - `mexora_dw_setup.sql`
  - `SAMPLE_DATA_LOAD.sql`

---

## 📋 Step-by-Step Execution

### STEP 1: Connect to Your Database

1. Open **pgAdmin 4** in your browser (usually `http://localhost:5050`)
2. Log in with your credentials
3. Navigate to **Servers** → Your Server (expand tree)
4. Right-click on your **Database** (or create a new database named `mexora_db`)
5. Select **Properties** and note the database name

### STEP 2: Open Query Tool

1. Right-click on your database → **Query Tool** (or press **Alt+Shift+Q**)
2. A new tab opens with the SQL editor
3. You should see:
   - Top toolbar with Execute button (⚡ lightning icon)
   - Main editor area (blank white space)
   - Notifications panel at bottom

### STEP 3: Load the Main DW Schema Script

**Option A - Using File Menu (Recommended):**
1. In the Query Tool, go to **File** → **Open**
2. Navigate to your saved location and select `mexora_dw_setup.sql`
3. Click **Open** - the entire script should load into the editor

**Option B - Copy & Paste:**
1. Open `mexora_dw_setup.sql` in your text editor
2. Select all content (**Ctrl+A**)
3. Copy (**Ctrl+C**)
4. In pgAdmin Query Tool, paste (**Ctrl+V**)

### STEP 4: Execute the Main Schema

1. **Review the script** (optional):
   - Scroll through to understand the structure
   - Check comments (lines starting with `--`)
   - Verify schema names and table names

2. **Execute the script**:
   - Click the **Execute** button (⚡ icon) in toolbar
   - OR press **F5**
   - OR press **Ctrl+Shift+E**

3. **Wait for completion**:
   - You should see:
     ```
     Query returned successfully in X ms.
     ```
   - In the **Notifications** panel at bottom
   - No errors should appear (red highlighting)

4. **Expected Output in Messages**:
   ```
   CREATE SCHEMA
   COMMENT
   CREATE TABLE
   CREATE INDEX
   ...
   (many lines)
   ```

### STEP 5: Verify Schema Installation

1. **Check Schemas Exist**:
   - Go to **View** → **Refresh** (or **F5**)
   - In left panel, expand your database
   - You should see:
     - `dwh_mexora` (blue database icon)
     - `reporting_mexora` (blue database icon)
     - `staging_mexora` (blue database icon)

2. **Verify Tables in Query Tool**:
   ```sql
   -- Copy and paste this to verify:
   SELECT schema_name FROM information_schema.schemata 
   WHERE schema_name LIKE '%mexora%'
   ORDER BY schema_name;
   ```
   - Click Execute
   - Should return 3 rows (schemas)

3. **List All Tables**:
   ```sql
   SELECT schemaname, tablename 
   FROM pg_tables 
   WHERE schemaname LIKE '%mexora%'
   ORDER BY schemaname, tablename;
   ```
   - Should show dimension and fact tables

### STEP 6: Load Sample Data (Optional - for Testing)

**IMPORTANT**: Only proceed if Step 5 verification passed!

1. **Open a New Query Tab**:
   - Right-click on database → **Query Tool** (opens new tab)

2. **Load Sample Data Script**:
   - **File** → **Open** → Select `SAMPLE_DATA_LOAD.sql`
   - OR copy/paste the content

3. **Execute Sample Data Load**:
   - Click **Execute** (⚡)
   - Wait for completion
   - You should see notice messages:
     ```
     NOTICE: Sample dates loaded: 2026-01-01 to 2026-12-31
     NOTICE: Sample regions loaded: 10 Moroccan regions
     NOTICE: Sample products loaded: 10 products
     ...
     NOTICE: Sample data loading completed successfully!
     ```

4. **Verify Sample Data**:
   ```sql
   SELECT COUNT(*) as nombre_dates FROM dwh_mexora.dim_temps;
   SELECT COUNT(*) as nombre_regions FROM dwh_mexora.dim_region;
   SELECT COUNT(*) as nombre_produits FROM dwh_mexora.dim_produit;
   SELECT COUNT(*) as nombre_clients FROM dwh_mexora.dim_client;
   SELECT COUNT(*) as nombre_ventes FROM dwh_mexora.fait_ventes;
   ```

---

## 🧪 Post-Installation Tests

### Test 1: Verify All Dimensions

```sql
-- Run in Query Tool
SELECT 
  'dim_temps' as table_name,
  COUNT(*) as record_count
FROM dwh_mexora.dim_temps
UNION ALL
SELECT 'dim_region', COUNT(*) FROM dwh_mexora.dim_region
UNION ALL
SELECT 'dim_produit', COUNT(*) FROM dwh_mexora.dim_produit
UNION ALL
SELECT 'dim_client', COUNT(*) FROM dwh_mexora.dim_client
UNION ALL
SELECT 'dim_livreur', COUNT(*) FROM dwh_mexora.dim_livreur;
```

**Expected Output**:
```
table_name    | record_count
dim_temps     | 365
dim_region    | 10
dim_produit   | 10
dim_client    | 10
dim_livreur   | 10
```

### Test 2: Verify Fact Table and Foreign Keys

```sql
-- Should return 100 rows (from sample data)
SELECT COUNT(*) as nombre_ventes FROM dwh_mexora.fait_ventes;

-- Verify no orphaned records
SELECT 'Orphaned Products' as issue, COUNT(*) 
FROM dwh_mexora.fait_ventes fv
LEFT JOIN dwh_mexora.dim_produit dp ON fv.id_produit_sk = dp.id_produit_sk
WHERE dp.id_produit_sk IS NULL
UNION ALL
SELECT 'Orphaned Clients', COUNT() 
FROM dwh_mexora.fait_ventes fv
LEFT JOIN dwh_mexora.dim_client dc ON fv.id_client_sk = dc.id_client_sk
WHERE dc.id_client_sk IS NULL;
```

**Expected Output**:
```
issue              | count
Orphaned Products  | 0
Orphaned Clients   | 0
```

### Test 3: Verify Materialized Views

```sql
-- Check view definitions
SELECT 
  schemaname,
  matviewname,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||matviewname)) as size
FROM pg_matviews
WHERE schemaname = 'reporting_mexora'
ORDER BY matviewname;
```

**Expected Output** (3 materialized views):
```
schemaname        | matviewname              | size
reporting_mexora  | mv_ca_mensuel            | 24 kB
reporting_mexora  | mv_top_produits          | 16 kB
reporting_mexora  | mv_performance_livreurs  | 20 kB
```

### Test 4: Query Sample Data

```sql
-- Get top revenue regions
SELECT 
  region_admin,
  SUM(nombre_commandes) as total_commandes,
  ROUND(SUM(ca_ttc)::NUMERIC, 2) as ca_ttc
FROM reporting_mexora.mv_ca_mensuel
GROUP BY region_admin
ORDER BY ca_ttc DESC;
```

### Test 5: Test SCD Type 2 Implementation

```sql
-- Current products (no end date)
SELECT 
  id_produit_nk,
  nom_produit,
  date_debut,
  date_fin,
  est_actif
FROM dwh_mexora.dim_produit
WHERE date_fin IS NULL
ORDER BY id_produit_nk;

-- Historical view (all records)
SELECT 
  id_produit_nk,
  nom_produit,
  date_debut,
  date_fin
FROM dwh_mexora.dim_produit
ORDER BY id_produit_nk, date_debut;
```

---

## 🔍 Troubleshooting

### Issue 1: "Schema already exists" Error

**Problem**: If you re-run the script
```
ERROR: schema "dwh_mexora" already exists
```

**Solution**:
Option A - Use existing schema (no harm):
- Script uses `CREATE SCHEMA IF NOT EXISTS` so it won't fail
- Just run it again

Option B - Drop and recreate:
```sql
DROP SCHEMA IF EXISTS dwh_mexora CASCADE;
DROP SCHEMA IF EXISTS reporting_mexora CASCADE;
DROP SCHEMA IF EXISTS staging_mexora CASCADE;
-- Then run the main script again
```

### Issue 2: Permission Denied on CREATE SCHEMA

**Problem**:
```
ERROR: permission denied to create database object
```

**Solution**:
1. Ensure you're connected with a superuser or owner account
2. In pgAdmin: 
   - Properties → Security tab
   - Check user permissions
   - May need to reconnect with admin account

### Issue 3: Materialized View Refresh Fails

**Problem**:
```
ERROR: cannot refresh materialized view mv_ca_mensuel concurrently
```

**Solution**:
Option A - Drop unique index first:
```sql
DROP INDEX IF EXISTS idx_mv_ca_mensuel_pk;
```

Option B - Use non-concurrent refresh:
```sql
REFRESH MATERIALIZED VIEW reporting_mexora.mv_ca_mensuel;
```

### Issue 4: Foreign Key Constraint Violation

**Problem**: When inserting test data
```
ERROR: insert or update on table "fait_ventes" violates foreign key constraint
```

**Solution**:
1. Ensure dimensions are loaded first (dates, regions, products, clients)
2. Load facts last
3. Verify natural keys match between source and dimensions

### Issue 5: Indexes Not Created

**Problem**: Queries are still slow

**Solution**:
1. Verify indexes were created:
   ```sql
   SELECT indexname FROM pg_indexes 
   WHERE schemaname = 'dwh_mexora' 
   ORDER BY tablename, indexname;
   ```

2. Rebuild indexes if needed:
   ```sql
   REINDEX SCHEMA dwh_mexora;
   ```

3. Update table statistics:
   ```sql
   ANALYZE dwh_mexora.fait_ventes;
   ```

### Issue 6: Materialized Views Empty

**Problem**: MV queries return 0 rows

**Solution**:
1. Load sample data first (`SAMPLE_DATA_LOAD.sql`)
2. Refresh materialized views:
   ```sql
   CALL reporting_mexora.refresh_all_materialized_views();
   ```
3. Check if fact table has data:
   ```sql
   SELECT COUNT(*) FROM dwh_mexora.fait_ventes;
   ```

---

## 📊 Running Analytics Queries

Once everything is set up, you can run reporting queries:

### From Query Tool:

1. Open a **New Query Tab** (**+** button)
2. Select a query from `COMMON_QUERIES.md`
3. Copy the query into the editor
4. Click **Execute** (⚡)
5. Results appear in bottom panel

### Example - Revenue by Region:

```sql
SELECT
  region_admin,
  COUNT(*) as nombre_commandes,
  SUM(montant_ttc) as ca_ttc,
  ROUND(AVG(montant_ttc), 2) as panier_moyen
FROM reporting_mexora.vw_ventes_temps_reel
WHERE EXTRACT(YEAR FROM date_commande) = 2026
GROUP BY region_admin
ORDER BY ca_ttc DESC;
```

---

## 🔄 Maintenance Tasks

### Weekly Maintenance:

```sql
-- Analyze tables and update statistics
ANALYZE dwh_mexora.fait_ventes;
ANALYZE dwh_mexora.dim_client;
ANALYZE dwh_mexora.dim_produit;

-- Refresh materialized views
CALL reporting_mexora.refresh_all_materialized_views();

-- Check for unused indexes
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'dwh_mexora' AND idx_scan = 0;
```

### Monthly Maintenance:

```sql
-- Full vacuum and analyze
VACUUM ANALYZE dwh_mexora.fait_ventes;
REINDEX SCHEMA dwh_mexora;
```

---

## 📈 Performance Tips

### For Faster Queries:

1. **Use Materialized Views**:
   - `mv_ca_mensuel` for revenue analysis
   - `mv_top_produits` for product analysis
   - `mv_performance_livreurs` for delivery analysis

2. **Filter by Date Early**:
   ```sql
   WHERE id_date_commande >= '2026-01-01'
   AND id_date_commande <= '2026-12-31'
   ```

3. **Use LIMIT for Exploration**:
   ```sql
   SELECT * FROM reporting_mexora.vw_ventes_temps_reel LIMIT 100;
   ```

4. **Check Query Plan**:
   ```sql
   EXPLAIN ANALYZE
   SELECT region_admin, SUM(montant_ttc)
   FROM reporting_mexora.vw_ventes_temps_reel
   GROUP BY region_admin;
   ```

---

## 🎯 Next Steps After Installation

1. **Load Your Own Data**:
   - Replace sample data with production data
   - Use ETL tools (Python, Talend, etc.)
   - See main project ETL scripts

2. **Create Custom Reports**:
   - Use `COMMON_QUERIES.md` as templates
   - Create BI dashboards in Power BI, Tableau, Metabase
   - Connect via JDBC/ODBC to DWH

3. **Set Up Monitoring**:
   - Schedule daily MV refreshes
   - Monitor table growth
   - Alert on data quality issues

4. **Backup Strategy**:
   - Regular database backups
   - Test restore procedures
   - Document backup location

---

## 📚 Additional Resources

- **PostgreSQL Docs**: https://www.postgresql.org/docs/
- **pgAdmin Docs**: https://www.pgadmin.org/docs/
- **DWH Design**: See `DATAWAREHOUSE_README.md`
- **Common Queries**: See `COMMON_QUERIES.md`

---

## ✅ Checklist for Successful Installation

- [ ] PostgreSQL database created
- [ ] Connected to database in pgAdmin
- [ ] `mexora_dw_setup.sql` executed successfully
- [ ] 3 schemas visible in pgAdmin (dwh_mexora, reporting_mexora, staging_mexora)
- [ ] 5 dimension tables created (dim_temps, dim_produit, dim_client, dim_region, dim_livreur)
- [ ] 1 fact table created (fait_ventes)
- [ ] All indexes created successfully
- [ ] 3 materialized views created
- [ ] Sample data loaded (optional, using `SAMPLE_DATA_LOAD.sql`)
- [ ] Test queries executed and returned results
- [ ] Materialized views refreshed

---

## 🆘 Emergency Recovery

**If something goes wrong:**

1. **View Error Log**:
   - In pgAdmin: **Tools** → **Server Logs**

2. **Rollback**:
   ```sql
   DROP SCHEMA dwh_mexora CASCADE;
   DROP SCHEMA reporting_mexora CASCADE;
   DROP SCHEMA staging_mexora CASCADE;
   ```

3. **Start Over**:
   - Execute `mexora_dw_setup.sql` again
   - Verify with test queries

4. **Get Help**:
   - Check PostgreSQL error messages
   - Review `DATAWAREHOUSE_README.md`
   - Check logs for specific issues

---

**Last Updated**: May 12, 2026
**Status**: Ready for Production
