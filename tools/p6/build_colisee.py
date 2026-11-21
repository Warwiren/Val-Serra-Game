#!/usr/bin/env python3
"""P6 — Génère les données de zone du Colisée de Val'Serra (blockout jouable) au format du socle 2.5D.

Sorties :
  data/p6/colisee.json          — Colisée : vestiaires, salle d'attente, arène, coursive, sortie est
  data/p6/quartier_initial.json — point de transition provisoire (premier quartier de la ville)

Repère (celui de src/explore25/world25.gd) : x vers l'est, y vers le sud du plan, en mètres ; h = altitude.
Le plan de référence (« Plan de la zone d'ouverture ») est suivi pour l'organisation, pas au pixel : l'ensemble est
ramené à environ 55 % de l'échelle dessinée (arène de 25 × 18 m au lieu d'environ 49 × 39 m) pour garder des
traversées courtes à la vitesse de marche du projet (2,2 m/s).

Le socle ne gère que des surfaces rectangulaires : l'arène ovale est une surface rectangulaire entourée d'un ANNEAU
de petits blocs (podium de 1,4 m) qui suit l'ellipse ; les coins hors de l'anneau sont inaccessibles. L'habillage
(sable ovale, gradins, loge) est construit par la scène (scenes/p6/colisee.gd) à partir de la section « p6 ».

Usage : python3 tools/p6/build_colisee.py
"""
import json
import math
import os

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# ------------------------------------------------------------------------------------------------ gabarit
ARENE_C = (26.0, 23.0)          # centre du sable
ARENE_R = (12.5, 9.0)           # demi-axes du sable (m)
ANNEAU_EP = 0.5                 # épaisseur du podium
ANNEAU_H = 1.4                  # hauteur du podium
GRADINS_PROF = 4.6              # profondeur des gradins (5 rangs)

MUR_EP = 0.4
H_NORD = 3.0                    # murs vus de face (fond des pièces)
H_COTE = 2.6                    # murs latéraux
H_SUD = 1.0                     # murs « coupés » côté caméra (sud) : l'intérieur reste lisible

# Pièces praticables : id -> [x0, y0, x1, y1], sol (matière de l'habillage)
PIECES = {
    "vestiaires":        ([16.0, 46.5, 36.0, 55.0], "plancher"),
    "passage_vestiaires": ([24.5, 44.5, 27.5, 46.5], "paves"),     # P6.2 : 3 m, aligné sur la salle et le tunnel
    "salle_attente":     ([20.0, 37.5, 32.0, 44.5], "paves"),
    "tunnel_sud":        ([24.5, 31.0, 27.5, 37.5], "paves"),
    "arene":             ([13.5, 14.0, 38.5, 32.0], "sable"),
    "tunnel_est":        ([38.0, 21.5, 44.0, 24.5], "paves"),
    "coursive":          ([44.0, 12.0, 56.0, 34.0], "paves"),
    "passage_infirmerie": ([45.5, 34.0, 47.5, 35.0], "paves"),
    "infirmerie":        ([44.0, 35.0, 49.5, 41.0], "plancher"),
    "couloir_sortie":    ([56.0, 21.5, 65.0, 24.5], "paves"),
}
# Pièces visibles mais non accessibles (porte fermée) : sol dessiné, aucune surface praticable
PIECES_FERMEES = {
    "reserve": ([50.5, 35.0, 56.0, 41.0], "plancher"),
}


def rect(x0, y0, x1, y1):
    return [round(x0, 3), round(y0, 3), round(x1, 3), round(y1, 3)]


def murs_piece(pid, r, ouvertures, cotes="nsoe", hauteurs=None):
    """Murs autour du rectangle r (à l'extérieur), avec ouvertures [(côté, a, b)] le long du côté."""
    x0, y0, x1, y1 = r
    t = MUR_EP
    hs = {"n": H_NORD, "s": H_SUD, "o": H_COTE, "e": H_COTE}
    hs.update(hauteurs or {})
    out = []
    for cote in cotes:
        if cote in "ns":
            y = y0 - t if cote == "n" else y1
            a0, a1 = x0 - t, x1 + t
            segs = _decoupe(a0, a1, [(a, b) for c, a, b in ouvertures if c == cote])
            for i, (a, b) in enumerate(segs):
                out.append({"id": "cmur_%s_%s%d" % (pid, cote, i), "rect": rect(a, y, b, y + t), "h": 0.0, "haut": hs[cote]})
        else:
            x = x0 - t if cote == "o" else x1
            segs = _decoupe(y0, y1, [(a, b) for c, a, b in ouvertures if c == cote])
            for i, (a, b) in enumerate(segs):
                out.append({"id": "cmur_%s_%s%d" % (pid, cote, i), "rect": rect(x, a, x + t, b), "h": 0.0, "haut": hs[cote]})
    return out


def _decoupe(a0, a1, trous):
    segs = []
    cur = a0
    for a, b in sorted(trous):
        if a - cur > 0.05:
            segs.append((cur, a))
        cur = max(cur, b)
    if a1 - cur > 0.05:
        segs.append((cur, a1))
    return segs


def anneau():
    """Podium de l'arène : blocs de 0,55 m tous les 0,42 m le long de l'ellipse, interrompus aux deux tunnels."""
    cx, cy = ARENE_C
    rx, ry = ARENE_R[0] + ANNEAU_EP / 2.0, ARENE_R[1] + ANNEAU_EP / 2.0
    n = 170
    out = []
    for i in range(n):
        a = 2 * math.pi * i / n
        x, y = cx + rx * math.cos(a), cy + ry * math.sin(a)
        if 24.35 < x < 27.65 and y > cy:          # tunnel sud (salle d'attente)
            continue
        if 21.35 < y < 24.65 and x > cx:          # tunnel est (coursive)
            continue
        h = 0.275
        out.append({"id": "anneau_%03d" % i, "rect": rect(x - h, y - h, x + h, y + h), "h": 0.0, "haut": ANNEAU_H})
    return out


def colisee():
    murs = []
    P = {k: v[0] for k, v in PIECES.items()}
    murs += murs_piece("vestiaires", P["vestiaires"], [("n", 24.5, 27.5)])
    murs += murs_piece("passage_vestiaires", P["passage_vestiaires"], [], cotes="oe", hauteurs={"o": 2.6, "e": 2.6})
    murs += murs_piece("salle_attente", P["salle_attente"],
                       [("n", 24.5, 27.5), ("s", 24.5, 27.5)])
    murs += murs_piece("tunnel_sud", [24.5, 32.0, 27.5, 37.5], [], cotes="oe")
    murs += murs_piece("tunnel_est", [38.4, 21.5, 44.0, 24.5], [], cotes="ns", hauteurs={"s": 1.6})
    murs += murs_piece("coursive", P["coursive"],
                       [("o", 21.5, 24.5), ("e", 21.5, 24.5), ("s", 45.5, 47.5), ("s", 52.0, 54.0),
                        ("n", 49.0, 51.0), ("e", 15.0, 17.0)])
    murs += murs_piece("couloir_sortie", P["couloir_sortie"], [("e", 21.5, 24.5)], cotes="nse", hauteurs={"s": 1.2})
    murs += murs_piece("infirmerie", P["infirmerie"], [("n", 45.5, 47.5)], cotes="soe")
    murs += murs_piece("reserve", PIECES_FERMEES["reserve"][0], [], cotes="soe")
    # cloison nord de l'infirmerie et de la réserve = mur sud de la coursive (déjà posé)

    # Mobilier et accessoires (obstacles) : id -> rect, hauteur
    meubles = [
        # vestiaires : casiers contre le mur nord et le mur ouest, bancs, râtelier, mannequin, bannière de la Guilde
        ("casiers_no", [16.2, 46.6, 22.6, 47.2], 2.0), ("casiers_ne", [29.4, 46.6, 35.8, 47.2], 2.0),
        ("casiers_o", [16.1, 49.0, 16.7, 53.5], 2.0),
        ("banc_v1", [19.0, 50.2, 22.4, 50.75], 0.45), ("banc_v2", [29.6, 50.2, 33.0, 50.75], 0.45),
        ("banc_v3", [19.0, 53.0, 22.4, 53.55], 0.45),
        ("ratelier_v", [34.9, 49.2, 35.7, 52.6], 1.6), ("mannequin_v", [31.6, 53.3, 32.4, 54.1], 1.7),
        ("coffre_v", [16.4, 54.0, 17.6, 54.8], 0.8),
        # salle d'attente : bancs latéraux, râtelier
        ("banc_a1", [20.3, 40.0, 20.9, 43.4], 0.45), ("banc_a2", [31.1, 40.0, 31.7, 43.4], 0.45),
        ("ratelier_a", [28.4, 37.6, 31.6, 38.2], 1.6),
        # coursive : quatre piliers
        ("pilier_1", [46.6, 16.6, 47.4, 17.4], 3.4), ("pilier_2", [52.6, 16.6, 53.4, 17.4], 3.4),
        ("pilier_3", [46.6, 28.6, 47.4, 29.4], 3.4), ("pilier_4", [52.6, 28.6, 53.4, 29.4], 3.4),
        # infirmerie : deux lits, une table
        ("lit_1", [44.3, 37.2, 46.0, 38.2], 0.6), ("lit_2", [44.3, 39.4, 46.0, 40.4], 0.6),
        ("table_i", [48.0, 38.6, 49.2, 39.6], 0.8),
        # réserve (vue à travers le mur bas) : caisses
        ("caisses_r", [51.0, 38.6, 53.2, 40.6], 1.2), ("tonneaux_r", [54.0, 35.6, 55.6, 36.8], 1.0),
    ]
    obstacles = murs + anneau()
    for mid, r, h in meubles:
        obstacles.append({"id": "meuble_" + mid, "rect": rect(*r), "h": 0.0, "haut": h})

    surfaces = []
    for pid, (r, _sol) in PIECES.items():
        x0, y0, x1, y1 = r
        surfaces.append({"id": pid, "category": "surface", "polygon_xy_m": [[x0, y0], [x1, y0], [x1, y1], [x0, y1]],
                         "height_m": 0, "walkable": True})

    # Portes : fermées = solides posés par la scène selon l'état de la progression.
    portes = [
        {"id": "grille_arene_est", "rect": rect(38.5, 21.5, 38.9, 24.5), "ouverte_a_partir_de": "tutorial_completed",
         "type": "grille", "texte_ferme": "La grille est baissée. Le commandant vous attend au centre de l'arène."},
        {"id": "porte_sortie_est", "rect": rect(56.6, 21.5, 57.0, 24.5), "ouverte_a_partir_de": "tutorial_completed",
         "type": "porte", "texte_ferme": "La porte de la ville est fermée pendant les évaluations."},
        {"id": "porte_loge", "rect": rect(49.0, 11.6, 51.0, 12.0), "type": "porte", "marque": "fermee",
         "texte_ferme": "Loge officielle — réservée aux autorités de la Guilde."},
        {"id": "porte_gradins_est", "rect": rect(56.0, 15.0, 56.4, 17.0), "type": "porte", "marque": "fermee",
         "texte_ferme": "Accès aux gradins est — réservé au public."},
        {"id": "porte_reserve", "rect": rect(52.0, 34.0, 54.0, 34.4), "type": "porte", "marque": "fermee",
         "texte_ferme": "Réserve — personnel du Colisée uniquement."},
        {"id": "porte_attente_o", "rect": rect(19.6, 40.0, 20.0, 42.0), "type": "porte", "marque": "fermee",
         "texte_ferme": "Couloir de service. La porte est verrouillée."},
        {"id": "porte_attente_e", "rect": rect(32.0, 40.0, 32.4, 42.0), "type": "porte", "marque": "fermee",
         "texte_ferme": "Couloir de service. La porte est verrouillée."},
        {"id": "porte_vestiaires_o", "rect": rect(15.6, 50.6, 16.0, 52.6), "type": "porte", "marque": "fermee",
         "texte_ferme": "Sortie des vestiaires vers la rue. Fermée : les recrues passent par l'arène."},
    ]
    # Points d'examen (accessoires) : texte court
    examens = [
        {"id": "ex_casiers", "xy": [19.4, 47.6], "portee_m": 1.4, "texte": "Des casiers de recrues. Le vôtre est vide : vous portez déjà votre équipement."},
        {"id": "ex_ratelier_v", "xy": [34.4, 50.9], "portee_m": 1.4, "texte": "Un râtelier d'armes d'entraînement émoussées."},
        {"id": "ex_mannequin", "xy": [32.0, 53.0], "portee_m": 1.3, "texte": "Un mannequin d'entraînement, couvert d'entailles."},
        {"id": "ex_banniere_v", "xy": [26.0, 52.9], "portee_m": 1.5, "texte": "La bannière de la Guilde des Chasseurs : une larme d'Aether entre deux lames."},
        {"id": "ex_lits", "xy": [46.6, 38.8], "portee_m": 1.2, "texte": "Des lits de camp. L'odeur des onguents flotte dans la pièce."},
    ]
    sortie = {"id": "sortie_est", "rect": rect(63.6, 21.5, 65.0, 24.5), "vers": "res://data/p6/quartier_initial.json",
              "porte": [65.0, 21.5, 65.0, 24.5], "arrivee": [4.2, 8.0, 0.0]}

    p6 = {
        "nom": "Colisée de Val'Serra",
        "zone": "colisee",
        "sols": {k: v[1] for k, v in PIECES.items()},
        "pieces_fermees": {k: {"rect": v[0], "sol": v[1]} for k, v in PIECES_FERMEES.items()},
        "arene": {"centre": list(ARENE_C), "rayons": list(ARENE_R), "anneau_ep": ANNEAU_EP, "anneau_h": ANNEAU_H,
                  "gradins_prof": GRADINS_PROF, "rangs": 5,
                  "tunnels": [rect(24.5, 31.0, 27.5, 37.5), rect(38.0, 21.5, 44.0, 24.5)],
                  "loge": {"centre": [35.4, 10.4], "taille": [6.0, 3.2], "h": 3.6}},
        "portes": portes,
        "examens": examens,
        "zones_nommees": [
            {"id": "vestiaires", "nom": "Vestiaires", "rect": PIECES["vestiaires"][0]},
            {"id": "salle_attente", "nom": "Salle d'attente", "rect": [20.0, 37.5, 32.0, 46.5]},
            {"id": "arene", "nom": "Arène centrale", "rect": [13.5, 14.0, 38.5, 32.0]},
            {"id": "coursive", "nom": "Coursive", "rect": [44.0, 12.0, 56.0, 34.0]},
            {"id": "infirmerie", "nom": "Infirmerie", "rect": PIECES["infirmerie"][0]},
            {"id": "sortie", "nom": "Sortie est", "rect": PIECES["couloir_sortie"][0]},
        ],
        "camera_vue_dessus": [8.0, 6.0, 66.0, 57.0],
        "lumieres": [[18.0, 47.3, 2.2], [34.0, 47.3, 2.2], [21.0, 38.0, 2.2], [31.0, 38.0, 2.2],
                     [45.0, 12.6, 2.6], [55.0, 12.6, 2.6], [47.0, 35.6, 2.0], [60.0, 22.0, 2.2]],
    }
    zone = {
        "project": "Val'Serra — Les Larmes d'Aether",
        "stage": "P6 — Colisée de Val'Serra, ouverture (blockout jouable)",
        "godot_target": "4.7.2",
        "_note": "Généré par tools/p6/build_colisee.py — ne pas éditer à la main.",
        "world": {"axes": "x droite (est), y bas du plan (sud), h altitude", "unit": "mètre", "extent_m": [66, 58],
                  "reference_native_px_per_m": 20},
        "checkpoints": [
            {"id": "A", "name": "départ (vestiaires)", "xy_m": [26.0, 50.6], "height_m": 0},
            {"id": "B", "name": "salle d'attente", "xy_m": [26.0, 41.0], "height_m": 0},
            {"id": "C", "name": "entrée de l'arène", "xy_m": [26.0, 30.5], "height_m": 0},
            {"id": "D", "name": "commandant", "xy_m": [26.0, 21.0], "height_m": 0},
            {"id": "E", "name": "coursive", "xy_m": [50.0, 23.0], "height_m": 0},
            {"id": "F", "name": "sortie est", "xy_m": [64.0, 23.0], "height_m": 0},
        ],
        "assets": surfaces,
        "ajustements": {
            "parametres": {"pas_franchissable_m": 0.25, "rayon_personnage_m": 0.28, "vitesse_m_s": 2.2,
                           "vitesse_course_m_s": 3.6, "ecart_compagnon_m": 1.0, "assistance_escalier": 0.3},
            "decor_marge": [-6, -6, 72, 64],
            "obstacles": obstacles,
            "entree": {"xy": [26.0, 50.6], "h": 0.0},
            "sorties": [sortie],
            "p6": p6,
        },
    }
    return zone


def quartier():
    rue = [2.0, 4.0, 30.0, 12.0]
    murs = murs_piece("rue", rue, [("o", 6.5, 9.5), ("e", 6.5, 9.5)], hauteurs={"n": 3.4, "s": 1.0})
    obstacles = murs + [
        {"id": "meuble_barriere_e", "rect": rect(29.4, 6.5, 30.0, 9.5), "h": 0.0, "haut": 1.1},
        {"id": "meuble_etal_1", "rect": rect(9.0, 4.2, 12.0, 5.2), "h": 0.0, "haut": 1.2},
        {"id": "meuble_etal_2", "rect": rect(18.0, 4.2, 21.0, 5.2), "h": 0.0, "haut": 1.2},
        {"id": "meuble_fontaine", "rect": rect(14.4, 9.6, 16.6, 11.6), "h": 0.0, "haut": 0.8},
    ]
    p6 = {
        "nom": "Val'Serra — quartier du Colisée (transition provisoire)",
        "zone": "quartier",
        "sols": {"rue": "paves"},
        "portes": [
            {"id": "portes_colisee", "rect": rect(1.6, 6.5, 2.0, 9.5), "type": "grille", "marque": "fermee",
             "fermee_a_partir_de": "coliseum_exited",
             "texte_ferme": "Les portes du Colisée se sont refermées derrière vous. Elles rouvriront plus tard."},
        ],
        "examens": [
            {"id": "ex_panneau_guilde", "xy": [27.6, 8.0], "portee_m": 1.8,
             "texte": "« Guilde des Chasseurs — par la grande rue ». (Fin de l'introduction : la zone de la Guilde reste à construire.)"},
            {"id": "ex_fontaine", "xy": [15.5, 9.0], "portee_m": 1.6, "texte": "Une fontaine. L'eau scintille d'un léger reflet d'Aether."},
        ],
        "zones_nommees": [{"id": "rue", "nom": "Quartier du Colisée", "rect": rue}],
        "camera_vue_dessus": [0.0, 0.0, 32.0, 16.0],
        "lumieres": [[8.0, 4.6, 2.6], [24.0, 4.6, 2.6]],
        "pnj_zone": "quartier",
    }
    return {
        "project": "Val'Serra — Les Larmes d'Aether",
        "stage": "P6 — point de transition provisoire vers la ville",
        "godot_target": "4.7.2",
        "_note": "Généré par tools/p6/build_colisee.py — ne pas éditer à la main.",
        "world": {"axes": "x droite, y bas du plan, h altitude", "unit": "mètre", "extent_m": [32, 16],
                  "reference_native_px_per_m": 20},
        "checkpoints": [{"id": "A", "name": "sortie du Colisée", "xy_m": [4.2, 8.0], "height_m": 0}],
        "assets": [{"id": "rue", "category": "surface", "polygon_xy_m": [[2, 4], [30, 4], [30, 12], [2, 12]],
                    "height_m": 0, "walkable": True}],
        "ajustements": {
            "parametres": {"pas_franchissable_m": 0.25, "rayon_personnage_m": 0.28, "vitesse_m_s": 2.2,
                           "vitesse_course_m_s": 3.6, "ecart_compagnon_m": 1.0, "assistance_escalier": 0.3},
            "decor_marge": [-6, -6, 38, 22],
            "obstacles": obstacles,
            "entree": {"xy": [4.2, 8.0], "h": 0.0},
            "sorties": [],
            "p6": p6,
        },
    }


def main():
    out = os.path.join(REPO, "data", "p6")
    os.makedirs(out, exist_ok=True)
    for name, data in [("colisee.json", colisee()), ("quartier_initial.json", quartier())]:
        with open(os.path.join(out, name), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
            f.write("\n")
        print("écrit", os.path.join("data", "p6", name), len(data["ajustements"]["obstacles"]), "obstacles")


if __name__ == "__main__":
    main()
