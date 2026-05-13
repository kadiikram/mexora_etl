/**
 * ============================================================================
 * MEXORA ETL - Sample Data Loading Script
 * ============================================================================
 * Purpose: Load sample data for testing and demonstration
 * Run AFTER: mexora_dw_setup.sql
 * Database: PostgreSQL
 * ============================================================================
 */

-- ============================================================================
-- PART 1: LOAD DIM_TEMPS (Sample date range: 2026-01-01 to 2026-12-31)
-- ============================================================================

-- Function to populate dim_temps (if not already populated)
DO $$
DECLARE
  v_date DATE := '2026-01-01';
  v_end_date DATE := '2026-12-31';
  v_day_of_week INT;
  v_day_name VARCHAR(20);
  v_month_name VARCHAR(20);
  v_quarter INT;
  v_week INT;
  v_is_weekend BOOLEAN;
BEGIN
  WHILE v_date <= v_end_date LOOP
    v_day_of_week := EXTRACT(DOW FROM v_date)::INT;
    v_week := EXTRACT(WEEK FROM v_date)::INT;
    v_quarter := CEIL(EXTRACT(MONTH FROM v_date) / 3.0)::INT;
    
    -- Map day names
    v_day_name := CASE v_day_of_week
      WHEN 0 THEN 'Dimanche'
      WHEN 1 THEN 'Lundi'
      WHEN 2 THEN 'Mardi'
      WHEN 3 THEN 'Mercredi'
      WHEN 4 THEN 'Jeudi'
      WHEN 5 THEN 'Vendredi'
      WHEN 6 THEN 'Samedi'
    END;
    
    -- Map month names
    v_month_name := CASE EXTRACT(MONTH FROM v_date)::INT
      WHEN 1 THEN 'Janvier'
      WHEN 2 THEN 'Février'
      WHEN 3 THEN 'Mars'
      WHEN 4 THEN 'Avril'
      WHEN 5 THEN 'Mai'
      WHEN 6 THEN 'Juin'
      WHEN 7 THEN 'Juillet'
      WHEN 8 THEN 'Août'
      WHEN 9 THEN 'Septembre'
      WHEN 10 THEN 'Octobre'
      WHEN 11 THEN 'Novembre'
      WHEN 12 THEN 'Décembre'
    END;
    
    v_is_weekend := v_day_of_week IN (0, 6);
    
    -- Insert or update
    INSERT INTO dwh_mexora.dim_temps (
      id_date, jour, mois, trimestre, annee, semaine,
      libelle_jour, libelle_mois, est_weekend, est_ferie_maroc, periode_ramadan
    ) VALUES (
      v_date,
      EXTRACT(DAY FROM v_date)::INT,
      EXTRACT(MONTH FROM v_date)::INT,
      v_quarter,
      EXTRACT(YEAR FROM v_date)::INT,
      v_week,
      v_day_name,
      v_month_name,
      v_is_weekend,
      FALSE, -- Set to TRUE for actual Moroccan holidays
      FALSE  -- Set to TRUE for Ramadan period (March 30 - April 28, 2026)
    )
    ON CONFLICT (id_date) DO NOTHING;
    
    v_date := v_date + INTERVAL '1 day';
  END LOOP;
END $$;

RAISE NOTICE 'Sample dates loaded: 2026-01-01 to 2026-12-31';


-- ============================================================================
-- PART 2: LOAD DIM_REGION (Moroccan Regions)
-- ============================================================================

INSERT INTO dwh_mexora.dim_region (id_region_nk, ville, province, region_admin, zone_geo, pays, latitude, longitude, population)
VALUES
('REG-CAS', 'Casablanca', 'Casablanca-Settat', 'Casablanca-Settat', 'Côte Atlantique', 'Maroc', 33.5731, -7.5898, 3500000),
('REG-FES', 'Fez', 'Fès-Meknès', 'Fès-Meknès', 'Moyen Atlas', 'Maroc', 34.0333, -5.0000, 1500000),
('REG-MAR', 'Marrakech', 'Marrakech-Safi', 'Marrakech-Safi', 'Haut Atlas', 'Maroc', 31.6295, -8.0088, 1200000),
('REG-RAB', 'Rabat', 'Rabat-Salé-Kénitra', 'Rabat-Salé-Kénitra', 'Côte Atlantique', 'Maroc', 34.0209, -6.8416, 1800000),
('REG-TAN', 'Tanger', 'Tanger-Tétouan-Al Hoceïma', 'Tanger-Tétouan-Al Hoceïma', 'Rif', 'Maroc', 35.7595, -5.8331, 1300000),
('REG-AGD', 'Agadir', 'Souss-Massa', 'Souss-Massa', 'Souss-Massa', 'Maroc', 30.4278, -9.5982, 500000),
('REG-MEK', 'Meknès', 'Fès-Meknès', 'Fès-Meknès', 'Moyen Atlas', 'Maroc', 33.8869, -5.5454, 600000),
('REG-SAL', 'Salé', 'Rabat-Salé-Kénitra', 'Rabat-Salé-Kénitra', 'Côte Atlantique', 'Maroc', 34.0506, -6.7962, 900000),
('REG-TET', 'Tétouan', 'Tanger-Tétouan-Al Hoceïma', 'Tanger-Tétouan-Al Hoceïma', 'Rif', 'Maroc', 35.3004, -5.3636, 400000),
('REG-OUJ', 'Oujda', 'Oriental', 'Oriental', 'Oriental', 'Maroc', 34.6842, -1.9076, 500000);

RAISE NOTICE 'Sample regions loaded: 10 Moroccan regions';


-- ============================================================================
-- PART 3: LOAD DIM_PRODUIT (Sample Products - Current Records Only)
-- ============================================================================

INSERT INTO dwh_mexora.dim_produit (
  id_produit_nk, nom_produit, description_produit, categorie,
  prix_unitaire_ht, prix_unitaire_ttc, stock_initial, poids_kg, fournisseur, est_actif, date_debut
) VALUES
('PROD-001', 'Téléphone Smartphone X12', 'Téléphone haut de gamme 128GB', 'Électronique', 2000.00, 2400.00, 150, 0.180, 'TechCorp', TRUE, '2026-01-01'),
('PROD-002', 'Laptop ProBook 15', 'Ordinateur portable 16GB RAM', 'Électronique', 8000.00, 9600.00, 50, 2.000, 'TechCorp', TRUE, '2026-01-01'),
('PROD-003', 'Casque Wireless Pro', 'Casque Bluetooth premium', 'Électronique', 800.00, 960.00, 200, 0.250, 'AudioTech', TRUE, '2026-01-01'),
('PROD-004', 'Batterie Externe 20000mAh', 'Power bank rapide', 'Électronique', 250.00, 300.00, 500, 0.400, 'PowerTech', TRUE, '2026-01-01'),
('PROD-005', 'Cable USB-C 2m', 'Cable de charge rapide', 'Accessoires', 50.00, 60.00, 1000, 0.050, 'CablePro', TRUE, '2026-01-01'),
('PROD-006', 'Montre Smartwatch Elite', 'Montre connectée fitness', 'Électronique', 1200.00, 1440.00, 80, 0.080, 'WearTech', TRUE, '2026-01-01'),
('PROD-007', 'Tablette Tab-X 10.5"', 'Tablette Android haute résolution', 'Électronique', 2500.00, 3000.00, 60, 0.600, 'TechCorp', TRUE, '2026-01-01'),
('PROD-008', 'Souris Wireless Ergonomique', 'Souris sans fil silencieuse', 'Accessoires', 150.00, 180.00, 300, 0.100, 'PeripheralCorp', TRUE, '2026-01-01'),
('PROD-009', 'Clavier Mécanique RGB', 'Clavier gaming avec rétroéclairage', 'Accessoires', 600.00, 720.00, 150, 1.200, 'GamingGear', TRUE, '2026-01-01'),
('PROD-010', 'Étui Protection Premium', 'Housse de protection renforcée', 'Accessoires', 80.00, 96.00, 500, 0.150, 'ProtectPro', TRUE, '2026-01-01');

RAISE NOTICE 'Sample products loaded: 10 products';


-- ============================================================================
-- PART 4: LOAD DIM_LIVREUR (Delivery Partners)
-- ============================================================================

INSERT INTO dwh_mexora.dim_livreur (
  id_livreur_nk, nom_livreur, email_livreur, telephone_livreur,
  type_transport, zone_couverture, region_admin, ville_base, est_actif,
  date_entree, capacite_transport, note_moyenne_livraison
) VALUES
('LIV-001', 'Mohamed Bennani', 'm.bennani@courier.ma', '+212612345678', 'Motocyclette', 'Casablanca Centre', 'Casablanca-Settat', 'Casablanca', TRUE, '2025-06-01', 25, 4.7),
('LIV-002', 'Fatima Alaoui', 'f.alaoui@courier.ma', '+212687654321', 'Voiture', 'Grand Casablanca', 'Casablanca-Settat', 'Casablanca', TRUE, '2025-07-15', 100, 4.6),
('LIV-003', 'Omar El Khadir', 'o.khadir@courier.ma', '+212712345678', 'Motocyclette', 'Fez Médina', 'Fès-Meknès', 'Fez', TRUE, '2025-08-01', 20, 4.8),
('LIV-004', 'Yasmine Bouazza', 'y.bouazza@courier.ma', '+212698765432', 'Voiture', 'Marrakech', 'Marrakech-Safi', 'Marrakech', TRUE, '2025-09-01', 80, 4.5),
('LIV-005', 'Hassan Tazi', 'h.tazi@courier.ma', '+212723456789', 'Camion', 'Transports Longue Distance', 'Rabat-Salé-Kénitra', 'Rabat', TRUE, '2025-05-01', 500, 4.9),
('LIV-006', 'Leila Benchemsi', 'l.benchemsi@courier.ma', '+212634567890', 'Motocyclette', 'Tanger Centre', 'Tanger-Tétouan-Al Hoceïma', 'Tanger', TRUE, '2025-10-01', 15, 4.4),
('LIV-007', 'Ahmed Bouammou', 'a.bouammou@courier.ma', '+212712987654', 'Vélo', 'Agadir Centre', 'Souss-Massa', 'Agadir', TRUE, '2025-11-01', 10, 4.3),
('LIV-008', 'Nadia Kharbouch', 'n.kharbouch@courier.ma', '+212687123456', 'Voiture', 'Meknès', 'Fès-Meknès', 'Meknès', TRUE, '2025-12-01', 90, 4.7),
('LIV-009', 'Karim Bennani', 'k.bennani@courier.ma', '+212712654321', 'Motocyclette', 'Salé Banlieue', 'Rabat-Salé-Kénitra', 'Salé', TRUE, '2026-01-15', 22, 4.6),
('LIV-010', 'Sophia Taha', 's.taha@courier.ma', '+212698764321', 'Voiture', 'Oujda', 'Oriental', 'Oujda', TRUE, '2026-01-20', 85, 4.8);

RAISE NOTICE 'Sample delivery partners loaded: 10 livreurs';


-- ============================================================================
-- PART 5: LOAD DIM_CLIENT (Sample Clients - Current Records Only)
-- ============================================================================

INSERT INTO dwh_mexora.dim_client (
  id_client_nk, nom_client, prenom_client, email_client, telephone_client,
  segment_client, tranche_age, sexe, date_naissance,
  ville, region_admin, code_postal, canal_acquisition, date_inscription, est_actif, date_debut
) VALUES
('CLI-0001', 'Bennis', 'Rachid', 'rachid.bennis@email.com', '+212612345001', 'Premium', '35-44', 'M', '1990-05-15', 'Casablanca', 'Casablanca-Settat', '20000', 'Google', '2024-03-10', TRUE, '2026-01-01'),
('CLI-0002', 'Abdelhak', 'Amina', 'amina.abdelhak@email.com', '+212687654002', 'Standard', '25-34', 'F', '1998-08-22', 'Fez', 'Fès-Meknès', '30000', 'Instagram', '2024-06-15', TRUE, '2026-01-01'),
('CLI-0003', 'Lahcen', 'Mohamed', 'mohamed.lahcen@email.com', '+212712345003', 'VIP', '45-54', 'M', '1978-02-28', 'Marrakech', 'Marrakech-Safi', '40000', 'Référence', '2023-12-01', TRUE, '2026-01-01'),
('CLI-0004', 'Saïd', 'Layla', 'layla.said@email.com', '+212698765004', 'Standard', '18-24', 'F', '2005-11-10', 'Rabat', 'Rabat-Salé-Kénitra', '10000', 'Facebook', '2025-01-20', TRUE, '2026-01-01'),
('CLI-0005', 'Habib', 'Khalid', 'khalid.habib@email.com', '+212723456005', 'Bronze', '55-64', 'M', '1968-07-05', 'Tanger', 'Tanger-Tétouan-Al Hoceïma', '90000', 'Email', '2025-03-10', TRUE, '2026-01-01'),
('CLI-0006', 'Loubna', 'Sabrina', 'sabrina.loubna@email.com', '+212634567006', 'Premium', '30-39', 'F', '1993-09-18', 'Agadir', 'Souss-Massa', '80000', 'TikTok', '2024-08-05', TRUE, '2026-01-01'),
('CLI-0007', 'Karim', 'Hassan', 'hassan.karim@email.com', '+212712987007', 'Standard', '25-34', 'M', '1999-01-12', 'Meknès', 'Fès-Meknès', '50000', 'Google', '2024-09-22', TRUE, '2026-01-01'),
('CLI-0008', 'Farah', 'Noor', 'noor.farah@email.com', '+212687123008', 'VIP', '35-44', 'F', '1988-04-30', 'Salé', 'Rabat-Salé-Kénitra', '11000', 'Référence', '2023-11-15', TRUE, '2026-01-01'),
('CLI-0009', 'Elamin', 'Yasir', 'yasir.elamin@email.com', '+212712654009', 'Standard', '40-49', 'M', '1983-06-25', 'Tétouan', 'Tanger-Tétouan-Al Hoceïma', '93000', 'Instagram', '2024-12-01', TRUE, '2026-01-01'),
('CLI-0010', 'Dounia', 'Zahra', 'zahra.dounia@email.com', '+212698764010', 'Premium', '28-37', 'F', '1996-10-08', 'Oujda', 'Oriental', '60000', 'Facebook', '2025-02-14', TRUE, '2026-01-01');

RAISE NOTICE 'Sample clients loaded: 10 clients';


-- ============================================================================
-- PART 6: LOAD FAIT_VENTES (Sample Sales Transactions)
-- ============================================================================

-- Generate sample sales data
DO $$
DECLARE
  v_counter INT := 0;
  v_max_sales INT := 100;
  v_random_date DATE;
  v_random_product BIGINT;
  v_random_client BIGINT;
  v_random_region BIGINT;
  v_random_livreur BIGINT;
  v_random_qty INT;
  v_random_montant_ht DECIMAL;
  v_random_remise DECIMAL;
  v_random_transport_cost DECIMAL;
  v_delivery_days INT;
BEGIN
  WHILE v_counter < v_max_sales LOOP
    -- Random selections
    SELECT id_date INTO v_random_date FROM dwh_mexora.dim_temps ORDER BY RANDOM() LIMIT 1;
    SELECT id_produit_sk INTO v_random_product FROM dwh_mexora.dim_produit ORDER BY RANDOM() LIMIT 1;
    SELECT id_client_sk INTO v_random_client FROM dwh_mexora.dim_client ORDER BY RANDOM() LIMIT 1;
    SELECT id_region INTO v_random_region FROM dwh_mexora.dim_region ORDER BY RANDOM() LIMIT 1;
    SELECT id_livreur INTO v_random_livreur FROM dwh_mexora.dim_livreur ORDER BY RANDOM() LIMIT 1;
    
    -- Random values
    v_random_qty := (RANDOM() * 10)::INT + 1;
    v_random_montant_ht := (RANDOM() * 10000 + 500)::DECIMAL;
    v_random_remise := (RANDOM() * 10)::DECIMAL; -- 0-10%
    v_random_transport_cost := (RANDOM() * 100 + 20)::DECIMAL;
    v_delivery_days := (RANDOM() * 7 + 1)::INT;
    
    INSERT INTO dwh_mexora.fait_ventes (
      id_vente_nk, id_date_commande, id_date_livraison,
      id_produit_sk, id_client_sk, id_region, id_livreur,
      quantite_vendue, montant_ht, montant_ttc, cout_livraison,
      delai_livraison_jours, remise_pct, statut_commande,
      est_livrée_a_temps, date_chargement
    ) VALUES (
      'VENTE-' || LPAD(v_counter::TEXT, 10, '0'),
      v_random_date,
      v_random_date + (v_delivery_days || ' days')::INTERVAL,
      v_random_product,
      v_random_client,
      v_random_region,
      v_random_livreur,
      v_random_qty,
      ROUND(v_random_montant_ht, 2),
      ROUND(v_random_montant_ht * 1.20, 2),
      ROUND(v_random_transport_cost, 2),
      v_delivery_days,
      ROUND(v_random_remise, 2),
      'Livrée',
      CASE WHEN v_delivery_days <= 3 THEN TRUE ELSE FALSE END,
      CURRENT_TIMESTAMP
    )
    ON CONFLICT (id_vente_nk) DO NOTHING;
    
    v_counter := v_counter + 1;
  END LOOP;
END $$;

RAISE NOTICE 'Sample sales transactions loaded: 100 transactions';


-- ============================================================================
-- PART 7: REFRESH MATERIALIZED VIEWS
-- ============================================================================

RAISE NOTICE 'Refreshing all materialized views...';

REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_mexora.mv_ca_mensuel;
RAISE NOTICE 'Refreshed: mv_ca_mensuel';

REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_mexora.mv_top_produits;
RAISE NOTICE 'Refreshed: mv_top_produits';

REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_mexora.mv_performance_livreurs;
RAISE NOTICE 'Refreshed: mv_performance_livreurs';


-- ============================================================================
-- PART 8: VERIFICATION QUERIES
-- ============================================================================

RAISE NOTICE '';
RAISE NOTICE '========== DATA LOADING SUMMARY ==========';
RAISE NOTICE 'Dates loaded: %', (SELECT COUNT(*) FROM dwh_mexora.dim_temps);
RAISE NOTICE 'Regions loaded: %', (SELECT COUNT(*) FROM dwh_mexora.dim_region);
RAISE NOTICE 'Products loaded: %', (SELECT COUNT(*) FROM dwh_mexora.dim_produit WHERE date_fin IS NULL);
RAISE NOTICE 'Delivery partners loaded: %', (SELECT COUNT(*) FROM dwh_mexora.dim_livreur);
RAISE NOTICE 'Clients loaded: %', (SELECT COUNT(*) FROM dwh_mexora.dim_client WHERE date_fin IS NULL);
RAISE NOTICE 'Sales transactions loaded: %', (SELECT COUNT(*) FROM dwh_mexora.fait_ventes);
RAISE NOTICE '=========================================';
RAISE NOTICE 'Sample data loading completed successfully!';


-- ============================================================================
-- END OF SAMPLE DATA LOADING
-- ============================================================================
