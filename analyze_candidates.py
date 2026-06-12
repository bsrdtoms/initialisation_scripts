#!/usr/bin/env python3
import csv
from statistics import mean

def analyze_candidates(csv_file):
    candidates = []

    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        candidates = list(reader)

    if not candidates:
        print("Aucun candidat trouvé dans le fichier CSV")
        return

    # Extraire les âges et niveaux d'études
    ages = [int(c['age']) for c in candidates]
    education_levels = [c['education_level'] for c in candidates]

    # Calculer les statistiques
    avg_age = mean(ages)
    master_count = sum(1 for e in education_levels if e == 'Master')
    phd_count = sum(1 for e in education_levels if e == 'PhD')
    total_count = len(candidates)

    # Afficher les résultats
    print("=" * 60)
    print("ANALYSE DES CANDIDATS ADMISSIBLES INSED EXTERNE 2026")
    print("=" * 60)
    print(f"\nNombre total de candidats: {total_count}")
    print(f"\nÂGE MOYEN: {avg_age:.2f} ans")
    print(f"\nNIVEAU D'ÉTUDES:")
    print(f"  - Masters: {master_count} ({master_count/total_count*100:.1f}%)")
    print(f"  - PhDs: {phd_count} ({phd_count/total_count*100:.1f}%)")

    # Détail par candidat
    print(f"\n{'Nom':<20} {'Prénom':<15} {'Âge':<5} {'Niveau':<10}")
    print("-" * 60)
    for c in sorted(candidates, key=lambda x: x['nom']):
        print(f"{c['nom']:<20} {c['prenom']:<15} {c['age']:<5} {c['education_level']:<10}")

    print("\n" + "=" * 60)

if __name__ == '__main__':
    analyze_candidates('candidates.csv')
