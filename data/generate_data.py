import json
import os
import random
from datetime import datetime, timedelta

import numpy as np
import pandas as pd
from faker import Faker


def ensure_data_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def format_date(date_obj: datetime) -> str:
    formats = ["%d/%m/%Y", "%Y-%m-%d", "%b %d %Y"]
    chosen = random.choice(formats)
    return date_obj.strftime(chosen)


def generate_random_dates(n: int, start_date: datetime, end_date: datetime) -> list[datetime]:
    total_days = (end_date - start_date).days
    return [start_date + timedelta(days=random.randint(0, total_days)) for _ in range(n)]


def random_moroccan_phone() -> str:
    prefix = random.choice(["06", "07"])
    suffix = "".join(str(random.randint(0, 9)) for _ in range(8))
    return prefix + suffix


def inject_malformed_email(email: str) -> str:
    patterns = [
        lambda e: e.replace("@", "", 1),
        lambda e: e.split("@")[0] + "@",
        lambda e: "notemail",
        lambda e: e.replace(".", "", 1),
    ]
    chosen = random.choice(patterns)
    return chosen(email)


def build_commandes(data_dir: str, produit_ids_with_inactive: list[str]) -> tuple[int, int, int]:
    n_rows = 50000
    id_commande = [f"CMD{idx:05d}" for idx in range(1, n_rows + 1)]
    clients = [f"CLT{idx:04d}" for idx in range(1, 2001)]
    produits = [f"P{idx:03d}" for idx in range(1, 101)]
    dates = generate_random_dates(n_rows, datetime(2022, 1, 1), datetime(2024, 12, 31))
    date_commande = [format_date(dt_obj) for dt_obj in dates]
    date_livraison_dt = [dt_obj + timedelta(days=random.randint(1, 7)) for dt_obj in dates]
    date_livraison = [format_date(dt_obj) for dt_obj in date_livraison_dt]

    quantite = np.random.randint(1, 11, size=n_rows).tolist()
    error_quantite_idx = random.sample(range(n_rows), 50)
    for idx in error_quantite_idx:
        quantite[idx] = random.randint(-5, -1)

    prix_unitaire = np.random.randint(50, 15001, size=n_rows).tolist()
    zero_price_idx = random.sample(range(n_rows), 100)
    for idx in zero_price_idx:
        prix_unitaire[idx] = 0

    statut_options = ["livré", "annulé", "retourné", "en_cours", "OK", "KO", "DONE", "livre", "LIVRE"]
    ville_options = [
        "Casablanca", "casablanca", "CASABLANCA", "Tanger", "tanger", "TNG", "TANGER", "Tnja",
        "Rabat", "RABAT", "Marrakech", "marrakech", "Fes", "FES", "Fès", "Agadir", "agadir",
        "Meknes", "meknès", "Oujda", "OUJDA",
    ]
    mode_paiement_options = ["carte", "virement", "cash", "COD"]

    commandes = pd.DataFrame({
        "id_commande": id_commande,
        "id_client": random.choices(clients, k=n_rows),
        "id_produit": random.choices(produits, k=n_rows),
        "date_commande": date_commande,
        "quantite": quantite,
        "prix_unitaire": prix_unitaire,
        "statut": random.choices(statut_options, k=n_rows),
        "ville_livraison": random.choices(ville_options, k=n_rows),
        "mode_paiement": random.choices(mode_paiement_options, k=n_rows),
        "id_livreur": random.choices([f"LIV{idx:02d}" for idx in range(1, 31)], k=n_rows),
        "date_livraison": date_livraison,
    })

    missing_livreur_count = int(round(n_rows * 0.07))
    missing_livreur_idx = random.sample(range(n_rows), missing_livreur_count)
    commandes.loc[missing_livreur_idx, "id_livreur"] = pd.NA

    # ensure inactive products appear in commandes at least once
    if produit_ids_with_inactive:
        for produit_id in produit_ids_with_inactive[:5]:
            idx = random.randint(0, n_rows - 1)
            commandes.at[idx, "id_produit"] = produit_id

    # inject duplicates among rows by copying existing rows into other rows
    duplicate_count = int(round(n_rows * 0.03))
    source_indices = random.sample(range(n_rows), duplicate_count)
    target_indices = random.sample([i for i in range(n_rows) if i not in source_indices], duplicate_count)
    for src, tgt in zip(source_indices, target_indices):
        commandes.loc[tgt] = commandes.loc[src]

    commandes.to_csv(os.path.join(data_dir, "commandes_mexora.csv"), index=False)
    return n_rows, duplicate_count, missing_livreur_count


def build_produits(data_dir: str) -> tuple[list[str], int, int]:
    categories = [
        "electronique", "Electronique", "ELECTRONIQUE",
        "mode", "Mode", "MODE",
        "alimentation", "Alimentation", "ALIMENTATION",
    ]
    sous_categories = {
        "electronique": ["Smartphones", "Laptops", "Tablettes", "Casques", "Télévisions"],
        "mode": ["Chaussures", "Robes", "Vestes", "Sacs", "Montres"],
        "alimentation": ["Épices", "Boissons", "Snacks", "Produits Laitiers", "Conserves"],
    }
    marques = [
        "Apple", "Samsung", "Nike", "Adidas", "Zara", "Marwa", "Sidi Ali", "Inwi", "Mayam", "Laila"
    ]
    fournisseurs = [
        "Apple MENA", "Samsung Maroc", "Nike Maroc", "Adidas Maroc", "Zara Maroc", "Local Maroc SARL",
        "Fournisseur Casablanca", "Souss Distribution", "Rabat Import", "Atlas Commerce"
    ]
    origine_pays_options = ["USA", "Chine", "Maroc", "France", "Turquie", "Allemagne"]

    produits = []
    inactive_ids = []
    prix_null_indices = set(random.sample(range(100), 5))
    actif_false_indices = set(random.sample(range(100), 10))
    for idx in range(1, 101):
        category = random.choice(categories)
        normalized_cat = category.lower()
        if normalized_cat.startswith("electronique"):
            sub_cat = random.choice(sous_categories["electronique"])
        elif normalized_cat.startswith("mode"):
            sub_cat = random.choice(sous_categories["mode"])
        else:
            sub_cat = random.choice(sous_categories["alimentation"])

        produit_nom_prefix = random.choice(["Smart", "Pro", "Ultra", "Eco", "Max"])
        produit = {
            "id_produit": f"P{idx:03d}",
            "nom": f"{produit_nom_prefix} {sub_cat} {idx}",
            "categorie": category,
            "sous_categorie": sub_cat,
            "marque": random.choice(marques),
            "fournisseur": random.choice(fournisseurs),
            "prix_catalogue": None if idx - 1 in prix_null_indices else float(random.randint(50, 15000)),
            "origine_pays": random.choice(origine_pays_options),
            "date_creation": (datetime.strptime("2020-01-01", "%Y-%m-%d") + timedelta(days=random.randint(0, 1825))).strftime("%Y-%m-%d"),
            "actif": False if idx - 1 in actif_false_indices else True,
        }
        produits.append(produit)
        if not produit["actif"]:
            inactive_ids.append(produit["id_produit"])

    with open(os.path.join(data_dir, "produits_mexora.json"), "w", encoding="utf-8") as fp:
        json.dump({"produits": produits}, fp, ensure_ascii=False, indent=2)

    return inactive_ids, len(prix_null_indices), len(actif_false_indices)


def build_clients(data_dir: str) -> tuple[int, int]:
    fake = Faker("fr_FR")
    n_clients = 2000
    client_ids = [f"CLT{idx:04d}" for idx in range(1, n_clients + 1)]
    sexes = ["m", "f", "1", "0", "Homme", "Femme", "male", "female", "h"]
    ville_options = [
        "Casablanca", "casablanca", "CASABLANCA", "Tanger", "tanger", "TNG", "TANGER", "Tnja",
        "Rabat", "RABAT", "Marrakech", "marrakech", "Fes", "FES", "Fès", "Agadir", "agadir",
        "Meknes", "meknès", "Oujda", "OUJDA",
    ]
    canal_options = ["organic", "paid_ads", "referral", "social_media", "email_campaign"]

    data = []
    for client_id in client_ids:
        birth_date = fake.date_of_birth(minimum_age=18, maximum_age=70)
        data.append({
            "id_client": client_id,
            "nom": fake.last_name(),
            "prenom": fake.first_name(),
            "email": fake.email(),
            "date_naissance": birth_date.strftime("%Y-%m-%d"),
            "sexe": random.choice(sexes),
            "ville": random.choice(ville_options),
            "telephone": random_moroccan_phone(),
            "date_inscription": fake.date_between_dates(date_start=datetime(2020, 1, 1), date_end=datetime(2024, 12, 31)).strftime("%Y-%m-%d"),
            "canal_acquisition": random.choice(canal_options),
        })

    malformed_idx = random.sample(range(n_clients), 100)
    for idx in malformed_idx:
        data[idx]["email"] = inject_malformed_email(data[idx]["email"])

    invalid_birth_idx = random.sample(range(n_clients), 30)
    for idx in invalid_birth_idx:
        if random.choice([True, False]):
            future_year = random.randint(2025, 2035)
            data[idx]["date_naissance"] = f"{future_year}-01-01"
        else:
            data[idx]["date_naissance"] = f"{random.randint(1850, 1899)}-01-01"

    # duplicate emails across different clients
    for _ in range(100):
        source_idx, target_idx = random.sample(range(n_clients), 2)
        data[target_idx]["email"] = data[source_idx]["email"]

    clients_df = pd.DataFrame(data)
    clients_df.to_csv(os.path.join(data_dir, "clients_mexora.csv"), index=False)
    return n_clients, 100


def build_regions(data_dir: str) -> int:
    rows = [
        ("CAS", "Casablanca", "Province de Casablanca", "Casablanca-Settat", "Centre", 3752000, 20000),
        ("RAB", "Rabat", "Province de Rabat", "Rabat-Salé-Kénitra", "Centre", 577827, 10000),
        ("TNG", "Tanger", "Province de Tanger", "Tanger-Tétouan-Al Hoceïma", "Nord", 947952, 90000),
        ("FES", "Fès", "Province de Fès", "Fès-Meknès", "Centre-Nord", 1112072, 30000),
        ("MKN", "Marrakech", "Province de Marrakech", "Marrakech-Safi", "Centre-Sud", 928850, 40000),
        ("AGD", "Agadir", "Province d'Agadir", "Souss-Massa", "Sud", 421844, 80000),
        ("MKNS", "Meknès", "Province de Meknès", "Fès-Meknès", "Centre-Nord", 632079, 50000),
        ("OUJ", "Oujda", "Province d'Oujda", "Oriental", "Est", 494252, 60000),
        ("TTA", "Tétouan", "Province de Tétouan", "Tanger-Tétouan-Al Hoceïma", "Nord", 380787, 90000),
        ("ELJ", "El Jadida", "Province d'El Jadida", "Casablanca-Settat", "Centre", 200978, 24000),
        ("KHM", "Khemisset", "Province de Khémisset", "Rabat-Salé-Kénitra", "Centre", 206917, 12000),
        ("KNM", "Kenitra", "Province de Kénitra", "Rabat-Salé-Kénitra", "Centre", 431282, 26000),
        ("SET", "Settat", "Province de Settat", "Casablanca-Settat", "Centre", 142250, 26000),
        ("BER", "Berrechid", "Province de Berrechid", "Casablanca-Settat", "Centre", 180000, 26000),
        ("SFI", "Safi", "Province de Safi", "Marrakech-Safi", "Centre-Sud", 308508, 46000),
        ("ERN", "Errachidia", "Province d'Errachidia", "Drâa-Tafilalet", "Sud-Est", 414517, 52000),
        ("BDA", "Béni Mellal", "Province de Béni Mellal", "Béni Mellal-Khénifra", "Centre", 192676, 23000),
        ("TZN", "Taza", "Province de Taza", "Fès-Meknès", "Centre-Nord", 150000, 35000),
        ("IZR", "Ifrane", "Province d'Ifrane", "Fès-Meknès", "Centre-Nord", 130000, 53000),
        ("SAH", "Sidi Slimane", "Province de Sidi Slimane", "Rabat-Salé-Kénitra", "Centre", 120000, 12000),
        ("FAH", "Fahs-Anjra", "Province de Fahs-Anjra", "Tanger-Tétouan-Al Hoceïma", "Nord", 150000, 91000),
        ("NAD", "Nador", "Province de Nador", "Oriental", "Est", 200000, 62000),
        ("OUZ", "Ouarzazate", "Province d'Ouarzazate", "Drâa-Tafilalet", "Sud", 104000, 45000),
        ("MZN", "Moulay Yacoub", "Province de Moulay Yacoub", "Fès-Meknès", "Centre-Nord", 75000, 53000),
        ("TGH", "Taourirt", "Province de Taourirt", "Oriental", "Est", 90000, 62000),
        ("EDF", "El Oued", "Province d'El Oued", "Oriental", "Est", 85000, 61000),
        ("DRT", "Driouch", "Province de Driouch", "Tanger-Tétouan-Al Hoceïma", "Nord", 82000, 61000),
        ("ATM", "Azilal", "Province d'Azilal", "Béni Mellal-Khénifra", "Centre", 75000, 45000),
        ("OUL", "Oulad Teima", "Province de Chtouka-Aït Baha", "Souss-Massa", "Sud", 58000, 82000),
        ("NWB", "Nador", "Province de Nador", "Oriental", "Est", 200000, 62000),
        ("BEN", "Beni Mellal", "Province de Béni Mellal", "Béni Mellal-Khénifra", "Centre", 192676, 23000),
    ]
    regions_df = pd.DataFrame(rows, columns=[
        "code_ville", "nom_ville_standard", "province", "region_admin", "zone_geo", "population", "code_postal"
    ])
    regions_df.to_csv(os.path.join(data_dir, "regions_maroc.csv"), index=False)
    return len(rows)


def main() -> None:
    base_dir = os.path.dirname(os.path.abspath(__file__))
    ensure_data_dir(base_dir)

    inactive_product_ids, null_products, inactive_products_count = build_produits(base_dir)
    commandes_rows, commandes_duplicates, missing_livreur = build_commandes(base_dir, inactive_product_ids)
    clients_rows, client_duplicates = build_clients(base_dir)
    regions_rows = build_regions(base_dir)

    print("Summary:")
    print(f"- commandes_mexora.csv rows generated: {commandes_rows}")
    print(f"- produits_mexora.json products generated: 100")
    print(f"- clients_mexora.csv rows generated: {clients_rows}")
    print(f"- regions_maroc.csv rows generated: {regions_rows}")
    print(f"- intentional duplicates injected in commandes: {commandes_duplicates}")
    print(f"- duplicate client emails injected: {client_duplicates}")
    print(f"- missing id_livreur values injected: {missing_livreur}")
    print(f"- null prix_catalogue products injected: {null_products}")
    print("✅ All 4 files generated successfully in data/ folder")


if __name__ == "__main__":
    main()
