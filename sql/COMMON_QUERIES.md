# Mexora Data Warehouse - Common Analytics Queries

## Quick Reference for Reporting

This file contains ready-to-use SQL queries for common analytical questions on the Mexora DWH.

---

## 1. REVENUE ANALYTICS

### 1.1 Total Revenue by Region (Current Month)
```sql
SELECT
  region_admin,
  COUNT(*) as nombre_commandes,
  SUM(quantite_vendue) as quantite_totale,
  SUM(montant_ttc) as ca_ttc,
  ROUND(AVG(montant_ttc), 2) as panier_moyen,
  ROUND(100.0 * COUNT(CASE WHEN est_livrée_a_temps THEN 1 END) / COUNT(*), 2) as taux_ponctualite_pct
FROM reporting_mexora.vw_ventes_temps_reel
WHERE EXTRACT(YEAR FROM date_commande) = 2026
  AND EXTRACT(MONTH FROM date_commande) = 5
GROUP BY region_admin
ORDER BY ca_ttc DESC;
```

### 1.2 Revenue Trend by Month
```sql
SELECT
  annee,
  mois,
  libelle_mois,
  SUM(nombre_commandes) as total_commandes,
  SUM(ca_ttc) as revenue_ttc,
  ROUND(SUM(ca_ttc) / SUM(nombre_commandes), 2) as panier_moyen
FROM reporting_mexora.mv_ca_mensuel
GROUP BY annee, mois, libelle_mois
ORDER BY annee DESC, mois DESC;
```

### 1.3 Top 5 Revenue-Generating Regions by Quarter
```sql
SELECT
  periode_trimestre,
  region_admin,
  SUM(ca_ttc) as revenue_ttc,
  SUM(nombre_commandes) as order_count,
  ROUND(SUM(ca_ttc) / SUM(nombre_commandes), 2) as ticket_moyen
FROM reporting_mexora.mv_ca_mensuel
WHERE annee = 2026
GROUP BY periode_trimestre, region_admin
ORDER BY periode_trimestre, revenue_ttc DESC;
```

### 1.4 Revenue by Category and Region
```sql
SELECT
  categorie,
  region_admin,
  COUNT(*) as nombre_ventes,
  SUM(quantite_vendue) as quantite_totale,
  SUM(montant_ttc) as ca_ttc,
  ROUND(AVG(montant_ttc), 2) as panier_moyen
FROM reporting_mexora.vw_ventes_temps_reel
WHERE EXTRACT(YEAR FROM date_commande) = 2026
GROUP BY categorie, region_admin
ORDER BY ca_ttc DESC
LIMIT 20;
```

---

## 2. PRODUCT ANALYTICS

### 2.1 Top 10 Best-Selling Products (All Time)
```sql
SELECT
  nom_produit,
  categorie,
  SUM(quantite_vendue) as quantite_totale,
  COUNT(DISTINCT id_vente) as nombre_ventes,
  SUM(montant_ttc) as revenue_ttc,
  ROUND(SUM(montant_ttc) / COUNT(DISTINCT id_vente), 2) as prix_moyen_vente
FROM reporting_mexora.vw_ventes_temps_reel
GROUP BY nom_produit, categorie
ORDER BY revenue_ttc DESC
LIMIT 10;
```

### 2.2 Top Products by Quarter
```sql
SELECT
  periode_trimestre,
  nom_produit,
  categorie,
  nombre_ventes,
  quantite_totale,
  montant_ttc_total as revenue_ttc,
  rang_ca
FROM reporting_mexora.mv_top_produits
WHERE rang_ca <= 5
  AND annee = 2026
ORDER BY periode_trimestre, rang_ca;
```

### 2.3 Product Sales by Category and Month
```sql
SELECT
  libelle_mois,
  categorie,
  COUNT(DISTINCT id_vente) as nombre_ventes,
  SUM(quantite_vendue) as quantite_totale,
  SUM(montant_ttc) as ca_ttc
FROM reporting_mexora.vw_ventes_temps_reel
WHERE EXTRACT(YEAR FROM date_commande) = 2026
GROUP BY libelle_mois, categorie
ORDER BY libelle_mois, ca_ttc DESC;
```

### 2.4 Product Performance - High Volume vs High Margin
```sql
SELECT
  nom_produit,
  categorie,
  COUNT(*) as nombre_achats,
  SUM(quantite_vendue) as quantite_totale,
  ROUND(AVG(quantite_vendue), 2) as qty_moyenne_par_commande,
  ROUND(SUM(montant_ttc) / NULLIF(SUM(quantite_vendue), 0), 2) as prix_unitaire_moyen,
  SUM(montant_ttc) as revenue_total
FROM reporting_mexora.vw_ventes_temps_reel
WHERE EXTRACT(YEAR FROM date_commande) = 2026
GROUP BY nom_produit, categorie
ORDER BY revenue_total DESC;
```

---

## 3. CUSTOMER ANALYTICS

### 3.1 Customer Segmentation Overview
```sql
SELECT
  segment_calculé as segment,
  COUNT(*) as nombre_clients,
  SUM(nombre_achats) as total_achats,
  ROUND(AVG(ca_client), 2) as ca_moyen,
  SUM(ca_client) as ca_total,
  ROUND(AVG(ticket_moyen), 2) as ticket_moyen
FROM reporting_mexora.vw_segmentation_client
GROUP BY segment_calculé
ORDER BY ca_total DESC;
```

### 3.2 Top 20 Customers by Revenue
```sql
SELECT
  nom_client,
  region_admin,
  segment_calculé,
  nombre_achats,
  ca_client,
  ticket_moyen,
  dernier_achat
FROM reporting_mexora.vw_segmentation_client
ORDER BY ca_client DESC
LIMIT 20;
```

### 3.3 Customer Geographic Distribution
```sql
SELECT
  region_admin,
  COUNT(DISTINCT id_client_sk) as nombre_clients,
  COUNT(DISTINCT id_client_sk) FILTER (WHERE segment_calculé = 'VIP') as clients_vip,
  COUNT(DISTINCT id_client_sk) FILTER (WHERE segment_calculé = 'Premium') as clients_premium,
  ROUND(AVG(ca_client), 2) as ca_moyen_par_client,
  SUM(ca_client) as ca_total_region
FROM reporting_mexora.vw_segmentation_client
GROUP BY region_admin
ORDER BY ca_total_region DESC;
```

### 3.4 Customer Lifecycle - Purchase Frequency Analysis
```sql
SELECT
  CASE
    WHEN nombre_achats = 1 THEN 'One-time Buyer'
    WHEN nombre_achats BETWEEN 2 AND 5 THEN '2-5 Purchases'
    WHEN nombre_achats BETWEEN 6 AND 10 THEN '6-10 Purchases'
    ELSE '11+ Purchases'
  END as purchase_frequency,
  COUNT(*) as nombre_clients,
  ROUND(AVG(ca_client), 2) as ca_moyen,
  SUM(ca_client) as ca_total
FROM reporting_mexora.vw_segmentation_client
GROUP BY purchase_frequency
ORDER BY nombre_clients DESC;
```

### 3.5 Recently Active Customers (Last 30 Days)
```sql
SELECT
  nom_client,
  region_admin,
  segment_calculé,
  nombre_achats,
  ca_client,
  dernier_achat,
  CURRENT_DATE - dernier_achat::DATE as jours_depuis_achat
FROM reporting_mexora.vw_segmentation_client
WHERE dernier_achat::DATE >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY dernier_achat DESC;
```

---

## 4. DELIVERY PERFORMANCE ANALYTICS

### 4.1 Delivery Partner Performance Dashboard
```sql
SELECT
  nom_livreur,
  type_transport,
  region_admin,
  nombre_livraisons,
  taux_ponctualite_pct,
  taux_retard_pct,
  delai_moyen_jours,
  note_moyenne,
  CASE
    WHEN taux_ponctualite_pct >= 90 THEN 'Excellent'
    WHEN taux_ponctualite_pct >= 80 THEN 'Bon'
    WHEN taux_ponctualite_pct >= 70 THEN 'Acceptable'
    ELSE 'À Améliorer'
  END as performance_rating
FROM reporting_mexora.mv_performance_livreurs
ORDER BY taux_ponctualite_pct DESC;
```

### 4.2 Underperforming Delivery Partners
```sql
SELECT
  nom_livreur,
  type_transport,
  nombre_livraisons,
  taux_ponctualite_pct,
  taux_retard_pct,
  livraisons_probleme,
  delai_moyen_jours,
  delai_max_jours
FROM reporting_mexora.mv_performance_livreurs
WHERE taux_ponctualite_pct < 80
ORDER BY taux_ponctualite_pct ASC;
```

### 4.3 Delivery Time Analysis by Region
```sql
SELECT
  region_admin,
  type_transport,
  COUNT(DISTINCT id_livreur) as nombre_livreurs,
  ROUND(AVG(delai_moyen_jours), 2) as delai_moyen,
  ROUND(AVG(taux_ponctualite_pct), 2) as taux_ponctualite_moyen
FROM reporting_mexora.mv_performance_livreurs
GROUP BY region_admin, type_transport
ORDER BY delai_moyen ASC;
```

### 4.4 Delivery Partners by Volume and Performance
```sql
SELECT
  nom_livreur,
  nombre_livraisons,
  ROUND(100.0 * nombre_livraisons / SUM(nombre_livraisons) OVER (), 2) as pct_volume,
  taux_ponctualite_pct,
  delai_moyen_jours,
  CASE
    WHEN nombre_livraisons > 50 AND taux_ponctualite_pct >= 85 THEN 'Top Performer'
    WHEN nombre_livraisons > 50 AND taux_ponctualite_pct >= 75 THEN 'Solid'
    WHEN nombre_livraisons <= 20 THEN 'New/Low Volume'
    ELSE 'Review'
  END as status
FROM reporting_mexora.mv_performance_livreurs
ORDER BY nombre_livraisons DESC;
```

---

## 5. TIME-BASED ANALYTICS

### 5.1 Sales Performance by Day of Week
```sql
SELECT
  libelle_jour,
  COUNT(DISTINCT id_vente) as nombre_commandes,
  SUM(quantite_vendue) as quantite_totale,
  SUM(montant_ttc) as ca_ttc,
  ROUND(AVG(montant_ttc), 2) as panier_moyen
FROM reporting_mexora.vw_ventes_temps_reel
WHERE EXTRACT(YEAR FROM date_commande) = 2026
GROUP BY libelle_jour
ORDER BY CASE libelle_jour
  WHEN 'Lundi' THEN 1
  WHEN 'Mardi' THEN 2
  WHEN 'Mercredi' THEN 3
  WHEN 'Jeudi' THEN 4
  WHEN 'Vendredi' THEN 5
  WHEN 'Samedi' THEN 6
  WHEN 'Dimanche' THEN 7
END;
```

### 5.2 Seasonal Analysis
```sql
SELECT
  annee,
  trimestre,
  SUM(nombre_commandes) as total_commandes,
  SUM(ca_ttc) as ca_ttc,
  ROUND(AVG(ca_ttc / nombre_commandes), 2) as panier_moyen,
  ROUND(AVG(taux_ponctualite_pct), 2) as taux_ponctualite_moyen
FROM reporting_mexora.mv_ca_mensuel
GROUP BY annee, trimestre
ORDER BY annee DESC, trimestre DESC;
```

### 5.3 Monthly Revenue Comparison
```sql
WITH revenue_by_month AS (
  SELECT
    annee,
    mois,
    libelle_mois,
    SUM(ca_ttc) as revenue
  FROM reporting_mexora.mv_ca_mensuel
  GROUP BY annee, mois, libelle_mois
)
SELECT
  mois,
  libelle_mois,
  MAX(CASE WHEN annee = 2025 THEN revenue END) as revenue_2025,
  MAX(CASE WHEN annee = 2026 THEN revenue END) as revenue_2026,
  ROUND((MAX(CASE WHEN annee = 2026 THEN revenue END) - 
          MAX(CASE WHEN annee = 2025 THEN revenue END)) / 
         NULLIF(MAX(CASE WHEN annee = 2025 THEN revenue END), 0) * 100, 2) as growth_pct
FROM revenue_by_month
GROUP BY mois, libelle_mois
ORDER BY mois;
```

---

## 6. OPERATIONAL METRICS

### 6.1 Order Status Distribution
```sql
SELECT
  statut_commande,
  COUNT(*) as nombre_commandes,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as pct_total,
  SUM(montant_ttc) as ca_ttc
FROM reporting_mexora.vw_ventes_temps_reel
WHERE EXTRACT(YEAR FROM date_commande) = 2026
GROUP BY statut_commande
ORDER BY nombre_commandes DESC;
```

### 6.2 Discount Impact Analysis
```sql
SELECT
  CASE
    WHEN remise_pct = 0 THEN 'No Discount'
    WHEN remise_pct BETWEEN 0.01 AND 5 THEN '1-5%'
    WHEN remise_pct BETWEEN 5.01 AND 10 THEN '5.01-10%'
    WHEN remise_pct > 10 THEN '>10%'
  END as discount_bracket,
  COUNT(*) as nombre_commandes,
  ROUND(AVG(montant_ttc), 2) as montant_moyen,
  SUM(montant_ttc) as ca_total
FROM reporting_mexora.vw_ventes_temps_reel
WHERE EXTRACT(YEAR FROM date_commande) = 2026
GROUP BY discount_bracket
ORDER BY nombre_commandes DESC;
```

### 6.3 Delivery Cost Analysis
```sql
SELECT
  ROUND(cout_livraison / 50) * 50 as cost_bracket,
  COUNT(*) as nombre_commandes,
  ROUND(AVG(montant_ttc), 2) as montant_moyen,
  ROUND(AVG(cout_livraison), 2) as cout_livraison_moyen,
  ROUND(100.0 * AVG(cout_livraison) / AVG(montant_ttc), 2) as delivery_cost_pct
FROM reporting_mexora.vw_ventes_temps_reel
WHERE EXTRACT(YEAR FROM date_commande) = 2026
GROUP BY cost_bracket
ORDER BY cost_bracket;
```

### 6.4 Refund Analysis
```sql
SELECT
  est_remboursee,
  COUNT(*) as nombre_commandes,
  SUM(montant_ttc) as ca_affecte,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as pct_total
FROM reporting_mexora.vw_ventes_temps_reel
WHERE EXTRACT(YEAR FROM date_commande) = 2026
GROUP BY est_remboursee;
```

---

## 7. DATA QUALITY & AUDITS

### 7.1 Data Completeness Check
```sql
SELECT
  'Total Transactions' as metric,
  COUNT(*) as value
FROM dwh_mexora.fait_ventes
UNION ALL
SELECT 'Records with Missing Delivery Date', COUNT(*) 
FROM dwh_mexora.fait_ventes WHERE id_date_livraison IS NULL
UNION ALL
SELECT 'Records with Missing Livreur', COUNT(*) 
FROM dwh_mexora.fait_ventes WHERE id_livreur IS NULL
UNION ALL
SELECT 'Records with NULL Delay Days', COUNT(*) 
FROM dwh_mexora.fait_ventes WHERE delai_livraison_jours IS NULL;
```

### 7.2 Referential Integrity Check
```sql
SELECT * FROM reporting_mexora.vw_data_quality_checks
WHERE issue_count > 0;
```

### 7.3 Recent Data Changes
```sql
SELECT
  'Added Today' as event,
  COUNT(*) as count
FROM dwh_mexora.fait_ventes
WHERE DATE(date_chargement) = CURRENT_DATE
UNION ALL
SELECT 'Added Yesterday', COUNT()
FROM dwh_mexora.fait_ventes
WHERE DATE(date_chargement) = CURRENT_DATE - INTERVAL '1 day';
```

---

## 8. ADVANCED COHORT ANALYSIS

### 8.1 Cohort Analysis - Customer Retention by Registration Period
```sql
WITH cohorts AS (
  SELECT
    DATE_TRUNC('month', date_inscription::DATE)::DATE as cohort_month,
    id_client_sk,
    MAX(DATE(dernier_achat)) as last_purchase
  FROM reporting_mexora.vw_segmentation_client
  GROUP BY cohort_month, id_client_sk
)
SELECT
  cohort_month,
  COUNT(*) as cohort_size,
  COUNT(CASE WHEN last_purchase >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as active_30d,
  COUNT(CASE WHEN last_purchase >= CURRENT_DATE - INTERVAL '90 days' THEN 1 END) as active_90d,
  ROUND(100.0 * COUNT(CASE WHEN last_purchase >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) / COUNT(*), 2) as retention_30d_pct
FROM cohorts
GROUP BY cohort_month
ORDER BY cohort_month DESC;
```

### 8.2 RFM (Recency, Frequency, Monetary) Analysis
```sql
WITH rfm AS (
  SELECT
    id_client_sk,
    nom_client,
    CURRENT_DATE - MAX(dernier_achat)::DATE as recency_days,
    nombre_achats as frequency,
    ca_client as monetary
  FROM reporting_mexora.vw_segmentation_client
)
SELECT
  CASE
    WHEN recency_days <= 30 THEN 'Recent'
    WHEN recency_days <= 90 THEN 'Active'
    ELSE 'Inactive'
  END as recency_segment,
  CASE
    WHEN frequency >= 10 THEN 'Loyal'
    WHEN frequency >= 5 THEN 'Regular'
    ELSE 'New'
  END as frequency_segment,
  CASE
    WHEN monetary >= 50000 THEN 'High Value'
    WHEN monetary >= 10000 THEN 'Medium Value'
    ELSE 'Low Value'
  END as monetary_segment,
  COUNT(*) as customer_count,
  ROUND(AVG(monetary), 2) as avg_value
FROM rfm
GROUP BY
  recency_segment, frequency_segment, monetary_segment
ORDER BY customer_count DESC;
```

---

## 9. MATERIALIZED VIEW REFRESH

### Refresh All MV
```sql
CALL reporting_mexora.refresh_all_materialized_views();
```

### Refresh Individual MV
```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_mexora.mv_ca_mensuel;
REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_mexora.mv_top_produits;
REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_mexora.mv_performance_livreurs;
```

---

## 10. EXPORT DATA FOR EXTERNAL TOOLS

### Export to CSV (using COPY command)
```sql
-- Revenue by region
COPY (
  SELECT * FROM reporting_mexora.mv_ca_mensuel 
  WHERE annee = 2026 
  ORDER BY ca_ttc DESC
) TO '/tmp/ca_mensuel.csv' WITH (FORMAT CSV, HEADER);

-- Top products
COPY (
  SELECT * FROM reporting_mexora.mv_top_produits 
  WHERE annee = 2026 
  ORDER BY montant_ttc_total DESC
) TO '/tmp/top_produits.csv' WITH (FORMAT CSV, HEADER);

-- Delivery performance
COPY (
  SELECT * FROM reporting_mexora.mv_performance_livreurs
) TO '/tmp/livreur_performance.csv' WITH (FORMAT CSV, HEADER);
```

---

## Tips for Using These Queries

1. **Adjust Date Ranges**: Modify `WHERE EXTRACT(YEAR FROM date) = 2026` to match your analysis period
2. **Limit Results**: Add `LIMIT 20` or `LIMIT 100` to prevent excessive output
3. **Filter by Region**: Add `AND region_admin = 'Casablanca-Settat'` for regional focus
4. **Performance**: Use materialized views (mv_*) for better performance on large datasets
5. **Refresh Views**: Always refresh materialized views before important reports: `CALL reporting_mexora.refresh_all_materialized_views();`

---

**Last Updated**: May 12, 2026
