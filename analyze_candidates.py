#!/usr/bin/env python3
import csv

def analyze_candidates(csv_file):
    candidates = []

    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        candidates = list(reader)

    if not candidates:
        print("Aucun candidat trouvé dans le fichier CSV")
        return

    # Compter les niveaux d'études
    phd_count = sum(1 for c in candidates if c['education_level'] == 'PhD')
    master_count = sum(1 for c in candidates if c['education_level'] == 'Master')
    unknown_count = sum(1 for c in candidates if c['education_level'] == 'Unknown')
    total_count = len(candidates)
    known_count = total_count - unknown_count

    # Afficher les résultats
    print("=" * 80)
    print("ANALYSE DES CANDIDATS ADMISSIBLES INSED EXTERNE 2026")
    print("=" * 80)
    print(f"\nNombre total de candidats: {total_count}")
    print(f"\n📊 NIVEAU D'ÉTUDES (résultats de recherche web):")
    print(f"  • PhDs: {phd_count} candidats ({phd_count/total_count*100:.1f}%)")
    print(f"  • Masters: {master_count} candidats ({master_count/total_count*100:.1f}%)")
    print(f"  • Données non disponibles: {unknown_count} candidats ({unknown_count/total_count*100:.1f}%)")
    print(f"\n  (Parmi les {known_count} candidats avec données disponibles:)")
    print(f"    - {phd_count}/{known_count} PhDs ({phd_count/known_count*100:.1f}%)")
    print(f"    - {master_count}/{known_count} Masters ({master_count/known_count*100:.1f}%)")

    # Détail par candidat
    print(f"\n{'Nom':<20} {'Prénom':<15} {'Niveau':<12} {'Détails':<45}")
    print("-" * 95)
    for c in sorted(candidates, key=lambda x: x['nom']):
        nom = c['nom']
        prenom = c['prenom']
        level = c['education_level']
        details = c['details']
        print(f"{nom:<20} {prenom:<15} {level:<12} {details:<45}")

    print("\n" + "=" * 80)
    print("NOTES:")
    print("  • Les informations d'âge ne sont pas publiquement disponibles")
    print("    (protection des données personnelles)")
    print("  • Les données de niveau d'études proviennent de:")
    print("    - Profils académiques (ResearchGate, CREST, ENSAE)")
    print("    - Profils professionnels publics (LinkedIn, sites institutionnels)")
    print("    - Recherche web ciblée (Google Scholar, universités)")
    print("=" * 80)

if __name__ == '__main__':
    analyze_candidates('candidates.csv')
