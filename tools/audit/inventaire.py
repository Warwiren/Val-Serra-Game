#!/usr/bin/env python3
"""Inventaire des fichiers suivis par Git et de leurs références (LECTURE SEULE : ne supprime ni ne déplace rien).

Pour chaque fichier suivi (hors .import / .uid, qui suivent leur ressource), on cherche :
  * jeu   : références dans ce que le moteur charge (scènes .tscn/.tres, scripts .gd, shaders, données .json,
            project.godot, export_presets.cfg), hors outils et tests ;
  * outils: références dans tools/ (générateurs, mesures) ;
  * tests : références dans tests/ ;
  * docs  : mentions dans les comptes rendus (docs/, README, CLAUDE.md) — n'implique aucune dépendance d'exécution ;
  * dossier : le dossier du fichier (ou un dossier parent) apparaît comme préfixe de chemin dans le code du jeu
            -> chargement DYNAMIQUE possible (chemin construit à l'exécution) : dépendance INCERTAINE, à vérifier.
Une référence est cherchée sous la forme « res://chemin », puis par nom de fichier seul (plus faible : signalé).

Sortie : un tableau CSV (une ligne par fichier) et un résumé par dossier (JSON), pour docs/audit/.
Usage : python3 tools/audit/inventaire.py [dossier_sortie]
"""
import csv
import json
import os
import re
import subprocess
import sys
from collections import defaultdict

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
JEU_EXT = {".gd", ".tscn", ".tres", ".gdshader", ".json", ".godot", ".cfg"}
TEXTE_EXT = JEU_EXT | {".py", ".md", ".txt", ".csv"}


def suivis():
    out = subprocess.run(["git", "-C", REPO, "ls-files", "-z"], capture_output=True, text=True).stdout
    return [f for f in out.split("\0") if f]


def domaine(f):
    if f.startswith("tools/"):
        return "outils"
    if f.startswith("tests/"):
        return "tests"
    if f.startswith("docs/") or f in ("README.md", "CLAUDE.md"):
        return "docs"
    return "jeu"


def main():
    sortie = sys.argv[1] if len(sys.argv) > 1 else os.path.join(REPO, "docs", "audit")
    os.makedirs(sortie, exist_ok=True)
    fichiers = suivis()
    textes = {}
    for f in fichiers:
        ext = os.path.splitext(f)[1].lower()
        if ext in TEXTE_EXT or f == "project.godot":
            if domaine(f) == "jeu" and ext not in JEU_EXT:
                continue
            try:
                with open(os.path.join(REPO, f), encoding="utf-8", errors="replace") as fh:
                    textes[f] = fh.read()
            except OSError:
                pass
    # préfixes de dossiers cités dans le code du jeu (chemins construits : "res://art/p45/chars/" + nom...)
    prefixes = set()
    for f, t in textes.items():
        if domaine(f) != "jeu":
            continue
        for m in re.finditer(r'res://([A-Za-z0-9_./\-]+/)', t):
            if m.group(1).count("/") >= 2:          # au moins deux niveaux (« art/ » seul ne prouve rien)
                prefixes.add(m.group(1))
    lignes = []
    for f in fichiers:
        if f.endswith(".import") or f.endswith(".uid"):
            continue
        cle = "res://" + f
        base = os.path.basename(f)
        compte = defaultdict(int)
        faible = defaultdict(int)
        for g, t in textes.items():
            if g == f:
                continue
            d = domaine(g)
            if cle in t:
                compte[d] += t.count(cle)
            elif len(base) > 6 and base in t:
                faible[d] += 1
        dossier = any(f.startswith(p) for p in prefixes)
        taille = os.path.getsize(os.path.join(REPO, f)) if os.path.exists(os.path.join(REPO, f)) else 0
        lignes.append({"fichier": f, "octets": taille, "jeu": compte["jeu"], "outils": compte["outils"],
                       "tests": compte["tests"], "docs": compte["docs"] + faible["docs"],
                       "nom_seul_jeu": faible["jeu"], "nom_seul_outils_tests": faible["outils"] + faible["tests"],
                       "dossier_dynamique": int(dossier)})
    with open(os.path.join(sortie, "inventaire_fichiers.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(lignes[0].keys()))
        w.writeheader()
        w.writerows(lignes)
    # résumé par dossier (deux niveaux, trois pour art/ et docs/media/)
    par = defaultdict(lambda: {"fichiers": 0, "octets": 0, "jeu": 0, "outils_tests": 0, "docs_seul": 0, "aucune": 0, "dynamique": 0})
    for l in lignes:
        parts = l["fichier"].split("/")
        n = 3 if parts[0] in ("art", "ValSerra_P49_V07B_PREFLIGHT_GODOT") or l["fichier"].startswith("docs/media/") else 2
        k = "/".join(parts[:n]) if len(parts) > n else "/".join(parts[:-1]) or "."
        p = par[k]
        p["fichiers"] += 1
        p["octets"] += l["octets"]
        if l["jeu"] or l["nom_seul_jeu"]:
            p["jeu"] += 1
        elif l["outils"] or l["tests"] or l["nom_seul_outils_tests"]:
            p["outils_tests"] += 1
        elif l["docs"]:
            p["docs_seul"] += 1
        else:
            p["aucune"] += 1
        if l["dossier_dynamique"]:
            p["dynamique"] += 1
    with open(os.path.join(sortie, "inventaire_dossiers.json"), "w", encoding="utf-8") as fh:
        json.dump(dict(sorted(par.items())), fh, ensure_ascii=False, indent=1)
    print("%d fichiers inventoriés, %d dossiers ; sortie : %s" % (len(lignes), len(par), os.path.relpath(sortie, REPO)))


if __name__ == "__main__":
    main()
