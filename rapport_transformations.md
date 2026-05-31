# 🧹 Rapport des Transformations ETL — Mexora Analytics

Ce document liste l'ensemble des règles métier appliquées lors de la phase `TRANSFORM` du pipeline ETL.

---

## 1. Commandes (`commandes_mexora.csv`)

### R1 — Suppression des doublons
- **Règle métier** : Les systèmes transactionnels peuvent générer des doublons sur l'`id_commande`. Il faut conserver uniquement la dernière occurrence.
- **Code Python** :
  ```python
  df = df.drop_duplicates(subset=['id_commande'], keep='last')
  ```
- **Lignes affectées** : 1 500 lignes supprimées (~3.0%).

### R2 — Standardisation des dates
- **Règle métier** : Les dates proviennent de différents formats (YYYY-MM-DD, DD/MM/YYYY, etc.). Il faut les normaliser au format standard `YYYY-MM-DD`. Les dates invalides entraînent la suppression de la ligne.
- **Code Python** :
  ```python
  df['date_commande'] = pd.to_datetime(df['date_commande'], format='mixed', dayfirst=True, errors='coerce')
  df = df.dropna(subset=['date_commande'])
  ```
- **Lignes affectées** : 0 dates invalides supprimées.

### R3 — Harmonisation des villes
- **Règle métier** : Les villes saisies librement comportent des erreurs (Tnja, CASA, etc.). Elles doivent être mappées vers leur appellation standard selon le référentiel `regions_maroc.csv`.
- **Code Python** :
  ```python
  mapping_villes = charger_referentiel_villes(referentiel_path)
  df['ville_livraison'] = df['ville_livraison'].str.strip().str.lower()
  df['ville_livraison'] = df['ville_livraison'].map(mapping_villes).fillna('Non renseignée')
  ```
- **Lignes affectées** : 28 variantes identifiées et mappées vers 14 villes standardisées.

### R4 — Standardisation des statuts
- **Règle métier** : Les statuts non standards (OK, KO, DONE) doivent être traduits en valeurs de référence (en_cours, annulé, livré, retourné).
- **Code Python** :
  ```python
  mapping_statuts = {
      'livré': 'livré', 'livre': 'livré', 'LIVRE': 'livré', 'DONE': 'livré',
      'annulé': 'annulé', 'annule': 'annulé', 'KO': 'annulé',
      'en_cours': 'en_cours', 'OK': 'en_cours',
      'retourné': 'retourné', 'retourne': 'retourné',
  }
  df['statut'] = df['statut'].replace(mapping_statuts)
  ```
- **Lignes affectées** : Toutes les valeurs ont été reconnues et standardisées (0 valeurs non reconnues).

### R5 — Suppression des quantités invalides
- **Règle métier** : Toute ligne présentant une quantité de produit inférieure ou égale à 0 est une erreur de saisie à exclure.
- **Code Python** :
  ```python
  df['quantite'] = df['quantite'].astype(float).astype(int)
  df = df[df['quantite'] > 0]
  ```
- **Lignes affectées** : 458 lignes supprimées.

### R6 — Suppression des prix nuls (commandes test)
- **Règle métier** : Les commandes ayant un prix unitaire de 0 MAD sont des tests internes. Elles faussent le CA et doivent être supprimées.
- **Code Python** :
  ```python
  df['prix_unitaire'] = df['prix_unitaire'].astype(float)
  df = df[df['prix_unitaire'] > 0]
  ```
- **Lignes affectées** : 739 commandes test supprimées.

### R7 — Remplacement des livreurs manquants
- **Règle métier** : Les commandes en attente d'affectation n'ont pas d'id_livreur. Ces valeurs nulles doivent être remplacées par la valeur arbitraire "-1" (Livreur inconnu).
- **Code Python** :
  ```python
  df['id_livreur'] = df['id_livreur'].replace('', pd.NA)
  df['id_livreur'] = df['id_livreur'].fillna('-1')
  ```
- **Lignes affectées** : 3 216 valeurs manquantes remplacées par -1.

---

## 2. Clients (`clients_mexora.csv`)

### R1 — Déduplication
- **Règle métier** : Un client ne doit apparaître qu'une seule fois. La déduplication se fait sur l'email (normalisé), en conservant la date d'inscription la plus récente.
- **Code Python** :
  ```python
  df['email_norm'] = df['email'].str.lower().str.strip()
  df['date_inscription'] = pd.to_datetime(df['date_inscription'], errors='coerce')
  df = df.sort_values('date_inscription').drop_duplicates(subset=['email_norm'], keep='last')
  ```
- **Lignes affectées** : 193 lignes supprimées.

### R2 — Standardisation du sexe
- **Règle métier** : Le genre est renseigné avec des abréviations diverses (1/0, h/f, male/female). Elles sont standardisées en `m`, `f`, ou `inconnu`.
- **Code Python** :
  ```python
  mapping_sexe = {
      'm': 'm', 'f': 'f', '1': 'm', '0': 'f', 'homme': 'm', 'femme': 'f', 'male': 'm', 'female': 'f', 'h': 'm',
  }
  df['sexe'] = df['sexe'].str.lower().str.strip().map(mapping_sexe).fillna('inconnu')
  ```
- **Lignes affectées** : Standardisation complète, 0 valeur `inconnu`.

### R3 — Validation des dates de naissance
- **Règle métier** : Une date de naissance permettant de déduire un âge absurde (< 16 ou > 100 ans) est invalidée (`NaT`).
- **Code Python** :
  ```python
  today = pd.Timestamp(date.today())
  df['age'] = (today - df['date_naissance']).dt.days // 365
  df.loc[(df['age'] < 16) | (df['age'] > 100), 'date_naissance'] = pd.NaT
  ```
- **Lignes affectées** : 101 âges invalides supprimés.

### R4 — Validation format email
- **Règle métier** : Les adresses email mal formées (ex: sans '@' ou domaine) sont supprimées en utilisant une expression régulière.
- **Code Python** :
  ```python
  pattern_email = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  emails_invalides = ~df['email'].str.match(pattern_email, na=False)
  df.loc[emails_invalides, 'email'] = None
  ```
- **Lignes affectées** : 117 emails invalides mis à NULL.

### R5 — Segmentation Gold/Silver/Bronze
- **Règle métier** : Calcul dynamique du segment client en fonction du CA TTC généré sur les 12 derniers mois (Gold ≥ 15 000 MAD, Silver ≥ 5 000 MAD, Bronze < 5 000 MAD).
- **Code Python** :
  ```python
  def segmenter(ca):
      if ca >= 15000: return 'Gold'
      elif ca >= 5000: return 'Silver'
      else: return 'Bronze'
  ca_par_client['segment_client'] = ca_par_client['ca_12m'].apply(segmenter)
  ```
- **Lignes affectées** : Gold: 828, Silver: 177, Bronze: 3 952.

---

## 3. Produits (`produits_mexora.json`)

### R1 — Harmonisation des catégories
- **Règle métier** : La casse des catégories est incohérente. Elle doit être standardisée en "Title Case".
- **Code Python** :
  ```python
  df['categorie'] = df['categorie'].str.strip().str.lower().str.title()
  df['categorie'] = df['categorie'].str.replace('Électronique', 'Electronique', regex=False)
  ```
- **Lignes affectées** : Harmonisation effectuée, réduction à 4 catégories propres.

### R2 — Conservation des produits inactifs
- **Règle métier** : Les produits désactivés du catalogue doivent être conservés dans le DWH pour garantir l'historique des ventes (SCD Type 2).
- **Code Python** :
  ```python
  # Les lignes ne sont pas supprimées, mais l'indicateur est préservé.
  # Aucun filtrage n'est appliqué sur df['actif'].
  ```
- **Lignes affectées** : 9 produits inactifs conservés avec succès.

### R3 — Traitement des prix manquants
- **Règle métier** : Les produits sans `prix_catalogue` reçoivent le prix médian de leur catégorie.
- **Code Python** :
  ```python
  mediane_par_cat = df.groupby('categorie')['prix_catalogue'].transform('median')
  df['prix_catalogue'] = df['prix_catalogue'].fillna(mediane_par_cat)
  ```
- **Lignes affectées** : 2 valeurs nulles remplacées par la médiane de la catégorie.

---

## 📋 Tableau Récapitulatif

| Source | Règle | Description | Impact |
|--------|-------|-------------|--------|
| Commandes | R1 | Suppression doublons `id_commande` | **-1 500** lignes |
| Commandes | R2 | Standardisation dates | 0 ligne |
| Commandes | R3 | Harmonisation villes | 28 variantes corrigées |
| Commandes | R4 | Standardisation statuts | 0 ligne |
| Commandes | R5 | Suppression quantités ≤ 0 | **-458** lignes |
| Commandes | R6 | Suppression prix unitaires = 0 | **-739** lignes |
| Commandes | R7 | Imputation `id_livreur` (-1) | 3 216 valeurs remplacées |
| Clients | R1 | Déduplication sur `email` | **-193** lignes |
| Clients | R2 | Standardisation sexe | 0 valeur inconnue |
| Clients | R3 | Invalidation dates de naissance absirbes | 101 dates effacées |
| Clients | R4 | Validation format email (Regex) | 117 adresses effacées |
| Clients | R5 | Calcul de la segmentation | 1 158 CA analysés |
| Produits | R1 | Casse des catégories | 4 catégories consolidées |
| Produits | R2 | Conservation inactifs | 9 inactifs gardés |
| Produits | R3 | Imputation des prix manquants | 2 prix imputés |

---

## 📊 Bilan Global de l'ETL
- **Volume initial en entrée** : 50 000 lignes brutes
- Lignes rejetées au nettoyage : 2 697
- Lignes rejetées à la validation dimensionnelle (problème d'intégrité sur la clé produit ou client) : 1 716
- **Volume final intégré (`FAIT_VENTES`)** : **45 587** lignes saines.