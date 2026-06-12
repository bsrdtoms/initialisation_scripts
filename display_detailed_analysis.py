#!/usr/bin/env python3
import csv
import json

def display_detailed_candidates(csv_file):
    candidates = []
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        candidates = list(reader)

    if not candidates:
        print("Aucun candidat trouvé")
        return

    print("=" * 140)
    print("ANALYSE DÉTAILLÉE - CANDIDATS ADMISSIBLES INSED EXTERNE 2026")
    print("=" * 140)
    print()

    # Tableau principal
    print(f"{'Nom':<20} {'Prénom':<15} {'Niveau':<10} {'Discipline':<25} {'Spécialisation':<40}")
    print("-" * 140)

    for c in sorted(candidates, key=lambda x: x['Nom']):
        nom = c['Nom']
        prenom = c['Prénom']
        niveau = c["Niveau d'études"]
        discipline = c['Discipline principale']
        specialize = c['Spécialisation']

        print(f"{nom:<20} {prenom:<15} {niveau:<10} {discipline:<25} {specialize:<40}")

    print("\n" + "=" * 140)
    print("TABLEAU COMPLET - DÉTAILS PAR CANDIDAT")
    print("=" * 140)

    # Affichage détaillé par candidat
    for c in sorted(candidates, key=lambda x: x['Nom']):
        nom = c['Nom']
        prenom = c['Prénom']
        niveau = c["Niveau d'études"]
        discipline = c['Discipline principale']
        specialize = c['Spécialisation']
        institutions = c['Institution(s)']
        details = c['Détails']

        print(f"\n👤 {nom.upper()} {prenom}")
        print("-" * 140)
        print(f"  Niveau d'études:       {niveau}")
        print(f"  Discipline principale: {discipline}")
        print(f"  Spécialisation:        {specialize}")
        print(f"  Institution(s):        {institutions}")
        print(f"  Détails:               {details}")

    # Statistiques par discipline
    print("\n\n" + "=" * 140)
    print("STATISTIQUES PAR DISCIPLINE")
    print("=" * 140)

    disciplines = {}
    for c in candidates:
        if c['Discipline principale'] != '?' and c['Discipline principale'] != 'Unknown':
            disc = c['Discipline principale'].strip()
            if disc not in disciplines:
                disciplines[disc] = 0
            disciplines[disc] += 1

    print()
    for disc in sorted(disciplines.keys(), key=lambda x: disciplines[x], reverse=True):
        count = disciplines[disc]
        print(f"  • {disc:<30} : {count} candidat(s)")

    # Statistiques par institution
    print("\n" + "=" * 140)
    print("INSTITUTIONS LES PLUS REPRÉSENTÉES")
    print("=" * 140)

    institutions = {}
    for c in candidates:
        if c['Institution(s)'] != '?' and c['Institution(s)'] != 'Unknown':
            insts = c['Institution(s)'].split('/')
            for inst in insts:
                inst = inst.strip()
                if inst and inst != '?' and inst != 'Unknown':
                    if inst not in institutions:
                        institutions[inst] = 0
                    institutions[inst] += 1

    print()
    for inst in sorted(institutions.keys(), key=lambda x: institutions[x], reverse=True):
        count = institutions[inst]
        print(f"  • {inst:<40} : {count} candidat(s)")

    print("\n" + "=" * 140)

if __name__ == '__main__':
    display_detailed_candidates('candidates_detailed.csv')
