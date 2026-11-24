#!/usr/bin/env python3
"""P7.4 — Génère le MICRO-BLOCKOUT V0.7-A de Val'Serra (ville semi-circulaire et ascendante, comparaison de caméras).

Sortie : data/p7/ville_v07a.json (instance chargée par la scène du Colisée en mode « ville v07a »).

EXPÉRIENCE DE CONCEPTION, NON VALIDÉE (brief P7.4 / V0.7-A) : un seul itinéraire représentatif, réversible :
  porte sud -> placette des voyageurs (respiration, guilde) -> montée coudée (deux volées étroites et un palier)
  -> portion de grande place commerçante -> embranchement ouest vers le parvis du Colisée (vue extérieure)
  -> montée coudée vers la terrasse haute (porte du château fermée, volumes lointains)
  + ruelle secondaire courte (place -> escalier étroit -> départ de rue « chantier » -> placette)
  + deux départs de rues vers des instances futures, fermés par un obstacle cohérent (chantier, grille).
Le tracé tourne autour d'un centre situé au nord-ouest (le Colisée) : la place et les montées dessinent un arc
plutôt qu'une ligne droite. Le socle n'accepte que des sols rectangulaires et des escaliers qui montent vers le nord :
l'arc est fait de rectangles décalés (volées et paliers en baïonnette).

Repère : x vers l'est, y vers le SUD, h = altitude (m). Niveaux d'essai : 0 / 1,75 (paliers) / 3,5 / 5,75 / 8 m.
Zones de caméra du mode B (caméra semi-fixe) : au plus deux, avec hystérésis (voir « zones_camera »).

Usage : python3 tools/p7/build_ville_v07a.py
"""
import json
import math
import os

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SORTIE = os.path.join(REPO, "data", "p7", "ville_v07a.json")

W, H = 140.0, 170.0
H0, HP1, H1, HP2, H2 = 0.0, 1.75, 3.5, 5.75, 8.0
# volées : (id, x0, x1, y_haut, longueur, h_bas, h_haut) — 6 m de large au plus (V0.6 : 12 et 16 m)
VOLEES = [
    ("volee_a", 56.0, 62.0, 126.0, 6.0, H0, HP1),     # placette -> palier 1
    ("volee_b", 62.0, 68.0, 115.0, 6.0, HP1, H1),     # palier 1 -> grande place (décalée vers l'est)
    ("volee_c", 60.0, 66.0, 82.0, 6.0, H1, HP2),      # grande place -> palier 2
    ("volee_d", 68.0, 74.0, 71.0, 6.0, HP2, H2),      # palier 2 -> terrasse haute (décalée vers l'est)
    ("ruelle_escalier", 80.0, 84.0, 115.0, 10.0, H0, H1),   # ruelle secondaire, 4 m de large
]
COLISEE = {"c": (0.0, 54.0), "r": (28.0, 24.0), "haut": 18.0}     # au nord-ouest de la place, entrée publique au SUD
VESTIBULE = (-3.0, 74.0, 3.0, 79.0)                                  # x0, y0, x1, y1 : porche de l'entrée publique


def rect(x0, y0, x1, y1):
    return [round(x0, 3), round(y0, 3), round(x1, 3), round(y1, 3)]


def surface(sid, r, h):
    x0, y0, x1, y1 = r
    return {"id": sid, "category": "surface", "polygon_xy_m": [[x0, y0], [x1, y0], [x1, y1], [x0, y1]], "height_m": h, "walkable": True}


def escalier(eid, x0, x1, y_haut, longueur, h_bas, h_haut):
    n = int(math.ceil((h_haut - h_bas) / 0.17))
    return {"id": eid, "category": "transition", "bounds_xy_m": rect(x0, y_haut, x1, y_haut + longueur),
            "bottom_h_m": h_bas, "top_h_m": h_haut, "risers": n, "tread_depth_m": round((longueur - 0.44) / n, 3)}


def praticable():
    s = []
    # --- bas (0 m)
    s.append(surface("route_sud", rect(57, 156, 63, 162), H0))
    s.append(surface("porte_sud", rect(57, 150, 63, 156), H0))
    s.append(surface("placette_voyageurs", rect(48, 132, 72, 150), H0))       # respiration avant la première volée
    s.append(surface("rue_chantier", rect(72, 136, 90, 144), H0))             # départ de rue vers une instance future
    s.append(surface("ruelle", rect(80, 125, 84, 136), H0))                    # ruelle secondaire (4 m)
    # --- paliers et place (1,75 / 3,5 m)
    s.append(surface("palier_1", rect(56, 121, 68, 126), HP1))
    s.append(surface("balcon_palier", rect(56, 115, 62, 121), H1))            # belvédère au-dessus du palier
    s.append(surface("belvedere_palier", rect(62, 126, 68, 132), HP1))        # P7.4.1 : prolongement du palier (praticable)
    s.append(surface("grande_place", rect(30, 88, 72, 115), H1))
    s.append(surface("place_bras_est", rect(72, 100, 86, 115), H1))          # bras de la place vers la ruelle
    s.append(surface("rue_colisee", rect(14, 96, 30, 104), H1))               # embranchement ouest
    s.append(surface("place_ouest", rect(14, 104, 30, 115), H1))              # P7.4.1 : la place rejoint l'embranchement
    s.append(surface("parvis_colisee", rect(-10, 70, 22, 104), H1))      # sous le tambour au nord (solides des tranches)
    s.append(surface("vestibule_colisee", rect(VESTIBULE[0], VESTIBULE[1], VESTIBULE[2], VESTIBULE[3]), H1))
    # --- montée haute et terrasse (5,75 / 8 m)
    s.append(surface("palier_2", rect(60, 77, 74, 82), HP2))
    s.append(surface("terrasse_haute", rect(56, 50, 90, 71), H2))
    s.append(surface("avenue_chateau", rect(66, 40.4, 74, 50), H2))
    s.append(surface("rue_haute_est", rect(90, 58, 94, 64), H2))              # départ de rue (grille)
    # pieds des volées (le palier bas du socle n'a pas de dessous physique)
    for vid, x0, x1, yh, L, hb, ht in VOLEES:
        s.append(surface("pied_" + vid, rect(x0, yh + L - 0.4, x1, yh + L), hb))
    for v in VOLEES:
        s.append(escalier(*v))
    return s


# (id, rect, pied, hauteur des murs, catégorie, libellé, toit). Tous bloquent (collision des données).
BATIMENTS = [
    # --- bas
    ("guilde", rect(32, 115, 56, 132), H0, 9.0, "guilde", "Guilde des Chasseurs", "2p"),   # façade sud sur la placette
    ("b_est", rect(68, 115, 80, 132), H0, 6.0, "residentiel_b", "", "2p"),
    ("b_o_placette", rect(30, 132, 48, 150), H0, 8.0, "residentiel", "", "2p"),
    ("b_e_placette", rect(72, 144, 96, 150), H0, 1.2, "residentiel_b", "", ""),    # muret bas (rue du chantier)
    ("b_e_ruelle", rect(84, 115, 100, 136), H0, 8.0, "residentiel", "", "2p"),
    ("b_chantier_n", rect(72, 132, 80, 136), H0, 6.0, "residentiel", "", "2p"),
    ("rempart_sud_o", rect(10, 152, 53, 155), H0, 9.0, "rempart", "", ""),
    ("rempart_sud_e", rect(67, 152, 120, 155), H0, 9.0, "rempart", "", ""),
    ("tour_sud_o", rect(53, 150, 57, 157), H0, 12.0, "rempart", "", ""),
    ("tour_sud_e", rect(63, 150, 67, 157), H0, 12.0, "rempart", "", ""),
    # --- palier 1 : bloc de pierre à l'est de la volée A (sous le palier)
    # --- grande place : fronts denses
    ("echoppe_no", rect(30, 76, 44, 88), H1, 3.0, "commerce", "", "2p"),
    ("forge_armurerie", rect(44, 76, 60, 88), H1, 4.0, "forge", "Forge-armurerie", "2p"),    # façade sud
    ("commerce_est", rect(74, 76, 86, 100), H1, 7.0, "commerce", "", "2p"),
    ("socle_palier_2", rect(66, 82, 74, 88), H1, HP2 - H1, "rempart", "", ""),
    ("b_rue_colisee_n", rect(22, 84, 30, 96), H1, 3.0, "commerce", "", "2p"),      # bas, en retrait : le Colisée se découvre
    ("b_parvis_ne", rect(22, 62, 30, 84), H1, 2.5, "residentiel_b", "", ""),              # portique bas : le Colisée se voit de la place
    ("b_no_place", rect(30, 60, 40, 76), H1, 3.0, "residentiel", "", "2p"),
    ("b_arriere_forge", rect(40, 71, 60, 76), H1, 4.5, "residentiel_b", "", "plat"),        # contre le mur de la terrasse
    ("b_parvis_o", rect(-24, 82, -10, 104), H1, 7.0, "residentiel", "", "2p"),             # front ouest du parvis
    ("b_parvis_s", rect(-10, 104, 14, 112), H1, 1.2, "residentiel_b", "", ""),             # bas : la caméra passe au-dessus
    # --- terrasse haute
    ("b_terrasse_o", rect(40, 44, 56, 71), H2, 10.0, "civique", "", "plat"),
    ("b_terrasse_no", rect(56, 36, 66, 50), H2, 11.0, "residentiel_b", "", "2p"),
    ("b_terrasse_ne", rect(74, 36, 90, 50), H2, 11.0, "civique", "", "2p"),
    ("b_terrasse_e", rect(90, 64, 104, 72), H2, 8.0, "residentiel", "", "2p"),
    ("b_terrasse_e2", rect(90, 44, 104, 58), H2, 9.0, "residentiel_b", "", "2p"),
    ("socle_palier_2b", rect(60, 71, 68, 77), H1, H2 - H1, "rempart", "", ""),              # sous la terrasse, à l'ouest de D
    ("tour_chateau_o", rect(62, 36, 66, 42), H2, 7.5, "rempart", "", ""),
    ("tour_chateau_e", rect(74, 36, 78, 42), H2, 7.5, "rempart", "", ""),
]


def paysage():
    """Volumes sans collision, hors d'atteinte : prolongements de la ville (rues futures, gradins de toits)."""
    out = []
    rangs = [
        (H0, [(96, 128, 116, 136, 7.0), (96, 144, 118, 152, 8.0), (118, 128, 136, 152, 6.0),     # rue du chantier, au-delà
              (8, 120, 30, 150, 7.0), (8, 115, 30, 120, 2.5), (100, 112, 120, 128, 9.0), (-10, 120, 8, 150, 6.0)]),
        (H1, [(86, 76, 104, 100, 8.0), (104, 80, 124, 104, 9.0), (-6, 112, 14, 120, 5.0), (86, 100, 104, 112, 6.0)]),
        (H2, [(104, 40, 124, 72, 10.0), (124, 44, 140, 70, 8.0), (20, 30, 40, 66, 11.0), (94, 30, 114, 40, 9.0)]),
    ]
    for h, lst in rangs:
        for x0, y0, x1, y1, haut in lst:
            out.append({"rect": rect(x0, y0, x1, y1), "h": h, "haut": haut, "toit": "2p"})
    return out


def masses():
    """Masses de terrain (affichage) : faces sud = murs de soutènement face caméra. [rect, h]."""
    return [
        [rect(-160, -300, 300, 115), H1],                 # niveau de la place et au-delà (sous tout le nord)
        [rect(56, 121, 68, 126), HP1],                    # sous le palier 1
        [rect(62, 126, 68, 132), HP1],                    # sous le belvédère du palier
        [rect(56, 115, 62, 121), H1],                     # belvédère
        [rect(60, 77, 74, 82), HP2],                      # sous le palier 2
        [rect(40, -300, 300, 71), H2],                    # terrasse haute (à l'est de x = 40)
    ]


def colisee_tranches(n=24):
    cx, cy = COLISEE["c"]
    rx, ry = COLISEE["r"]
    out = []
    for k in range(n):
        y0 = cy - ry + 2 * ry * k / n
        y1 = cy - ry + 2 * ry * (k + 1) / n
        ym = (y0 + y1) / 2.0
        dx = rx * math.sqrt(max(0.0, 1.0 - ((ym - cy) / ry) ** 2))
        x1 = cx + dx
        if y1 > VESTIBULE[1] + 1e-6:               # porche : la tranche est coupée en deux de part et d'autre
            out.append({"id": "colisee_tranche_%02d_o" % k, "rect": rect(cx - dx, y0, VESTIBULE[0], y1), "h": H1, "haut": COLISEE["haut"]})
            out.append({"id": "colisee_tranche_%02d_e" % k, "rect": rect(VESTIBULE[2], y0, x1, y1), "h": H1, "haut": COLISEE["haut"]})
            continue
        out.append({"id": "colisee_tranche_%02d" % k, "rect": rect(cx - dx, y0, x1, y1), "h": H1, "haut": COLISEE["haut"]})
    return out


def construire():
    assets = praticable()
    obstacles = []
    meta_bat = {}
    for bid, r, h, haut, cat, lib, toit in BATIMENTS:
        oid = bid if bid.startswith(("rempart", "tour", "socle")) else "bat_" + bid
        obstacles.append({"id": oid, "rect": r, "h": h, "haut": haut})
        meta_bat[oid] = {"categorie": cat, "libelle": lib, "toit": toit}
    obstacles += colisee_tranches()
    gc = [  # garde-corps (1 m, collision réelle) aux bords de terrasse qui ne sont pas des volées
        ("gc_place_o", rect(14, 114.6, 56, 115), H1), ("gc_belvedere_s", rect(62, 131.6, 68, 132), HP1), ("gc_balcon", rect(56, 120.6, 62, 121), H1),
        ("gc_palier_e", rect(67.6, 121, 68, 126), HP1),
        ("gc_terrasse_o", rect(56, 70.6, 68, 71), H2), ("gc_terrasse_e", rect(74, 70.6, 90, 71), H2),
        ("gc_palier_2_o", rect(60, 77, 60.4, 82), HP2), ("gc_place_bras_o", rect(72, 114.6, 80, 115), H1), ("gc_place_bras_e", rect(84, 114.6, 86, 115), H1),
        ("gc_place_e", rect(68, 114.6, 72, 115), H1),
    ]
    for gid, r, h in gc:
        obstacles.append({"id": gid, "rect": r, "h": h, "haut": 1.0})
    obstacles.append({"id": "barriere_chantier", "rect": rect(89.4, 136, 90, 144), "h": H0, "haut": 1.2})
    obstacles.append({"id": "barriere_route_sud", "rect": rect(57, 161.4, 63, 162), "h": H0, "haut": 1.1})
    obstacles.append({"id": "fontaine", "rect": rect(42, 96, 48, 102), "h": H1, "haut": 1.0})

    portes = [
        {"id": "porte_chateau", "rect": [66.0, 40.0, 74.0, 40.4], "type": "grille", "marque": "fermee", "h": H2,
         "texte_ferme": "Porte du château — fermée. L'accès s'ouvrira plus tard dans l'histoire."},
        {"id": "grille_rue_haute", "rect": [93.6, 58.0, 94.0, 64.0], "type": "grille", "marque": "fermee", "h": H2,
         "texte_ferme": "Rue haute — fermée pour l'instant (futur quartier)."},
        {"id": "portes_colisee_public", "rect": [VESTIBULE[0], VESTIBULE[3] - 0.4, VESTIBULE[2], VESTIBULE[3]], "type": "porte",
         "marque": "fermee", "h": H1, "fermee_a_partir_de": "coliseum_exited",
         "texte_ferme": "Les portes du Colisée se sont refermées derrière vous. Elles rouvriront plus tard."},
    ]
    examens = [
        {"id": "ex_porte_sud", "xy": [60.0, 160.0], "portee_m": 2.2, "texte": "Porte sud — sortie de la ville (transition non reliée)."},
        {"id": "ex_guilde", "xy": [50.0, 132.6], "portee_m": 1.8, "texte": "Guilde des Chasseurs (volume provisoire)."},
        {"id": "ex_forge", "xy": [52.0, 88.6], "portee_m": 1.8, "texte": "Forge-armurerie (volume provisoire)."},
        {"id": "ex_chantier", "xy": [88.6, 140.0], "portee_m": 2.0, "texte": "Chantier — la rue est barrée (futur quartier)."},
        {"id": "ex_fontaine", "xy": [45.0, 102.6], "portee_m": 1.8, "texte": "Fontaine (repère provisoire)."},
    ]
    zones = [
        {"id": "placette_voyageurs", "nom": "Placette des Voyageurs", "rect": [48.0, 132.0, 72.0, 150.0]},
        {"id": "grande_place", "nom": "Grande place", "rect": [30.0, 88.0, 86.0, 115.0]},
        {"id": "parvis_colisee", "nom": "Parvis du Colisée", "rect": [2.0, 90.0, 30.0, 110.0]},
        {"id": "terrasse_haute", "nom": "Terrasse haute", "rect": [56.0, 40.4, 94.0, 71.0]},
        {"id": "ruelle", "nom": "Ruelle des Tonneliers", "rect": [72.0, 112.0, 90.0, 144.0]},
    ]
    points = {
        "porte_sud": [60.0, 154.0, H0], "guilde": [50.0, 133.2, H0], "pied_volee_a": [59.0, 132.6, H0],
        "palier_1": [62.0, 123.5, HP1], "haut_volee_b": [65.0, 114.0, H1], "place": [50.0, 106.0, H1],
        "colisee": [0.0, 82.0, H1], "pied_volee_c": [63.0, 89.0, H1], "palier_2": [67.0, 79.5, HP2],
        "terrasse": [71.0, 66.0, H2], "chateau": [70.0, 41.6, H2], "ruelle_bas": [82.0, 130.0, H0], "chantier": [88.0, 140.0, H0],
    }
    zones_camera = [   # mode B : orientation propre à 2 secteurs ; 0° ailleurs. « marge » = hystérésis de sortie (m)
        {"id": "revelation_colisee", "rect": [-10.0, 70.0, 72.0, 116.0], "azimut_deg": -16.0, "marge_m": 2.0},
        {"id": "montee_chateau", "rect": [56.0, 40.0, 96.0, 85.0], "azimut_deg": 12.0, "marge_m": 2.0},
    ]
    return {
        "project": "Val'Serra — Les Larmes d'Aether",
        "stage": "P7.4 — Ville V0.7-A : micro-blockout semi-circulaire, caméras A / B comparées (EXPÉRIENCE, NON VALIDÉE)",
        "godot_target": "4.7.2",
        "_note": "Généré par tools/p7/build_ville_v07a.py — ne pas éditer à la main.",
        "world": {"axes": "x droite (est), y bas du plan (sud), h altitude", "unit": "mètre", "extent_m": [W, H],
                  "reference_native_px_per_m": 20},
        "checkpoints": [{"id": k, "name": k, "xy_m": v[:2], "height_m": v[2]} for k, v in points.items()],
        "assets": assets,
        "ajustements": {
            "parametres": {"pas_franchissable_m": 0.25, "rayon_personnage_m": 0.28, "vitesse_m_s": 2.2,
                           "vitesse_course_m_s": 3.6, "ecart_compagnon_m": 1.0, "assistance_escalier": 0.3},
            "escalier": {"palier_bas_m": 0.22, "palier_haut_m": 0.22},
            "decor_marge": [-60.0, -80.0, W + 60.0, H + 20.0],
            "obstacles": obstacles,
            "entree": {"xy": [60.0, 154.0], "h": H0},
            "sorties": [
                {"id": "entree_colisee", "rect": [VESTIBULE[0], VESTIBULE[1], VESTIBULE[2], VESTIBULE[1] + 1.0],
                 "vers": "res://data/p6/colisee.json", "porte": [VESTIBULE[0], VESTIBULE[1], VESTIBULE[2], VESTIBULE[1]],
                 "arrivee": [61.5, 23.0, 0.0]},
            ],
            "p6": {
                "nom": "Val'Serra — ville V0.7-A (micro-blockout, expérience)",
                "zone": "ville",
                "sols": {},
                "portes": portes,
                "examens": examens,
                "zones_nommees": zones,
                "camera_vue_dessus": [-60.0, -40.0, W, H],
                "lumieres": [],
                "ville": {
                    "version": "v07a",
                    "batiments": meta_bat,
                    "paysage": paysage(),
                    "masses": masses(),
                    "volees": [list(v) for v in VOLEES],
                    "niveaux": {"bas": H0, "median": H1, "haut": H2},
                    "colisee": {"centre": list(COLISEE["c"]), "rayons": list(COLISEE["r"]), "h": H1, "haut": COLISEE["haut"],
                                "porte": [0.0, VESTIBULE[3]], "vestibule": list(VESTIBULE)},
                    "fontaine": rect(42, 96, 48, 102),
                    "chateau": [100.0, -240.0],
                    "porte_sud": [57.0, 63.0, 153.5],
                    "chantier": rect(88.4, 136, 89.4, 144),
                    "points": points,
                    "zones_camera": zones_camera,
                    "arrivee_colisee": [0.0, 84.0, H1],
                },
            },
        },
    }


def main():
    z = construire()
    os.makedirs(os.path.dirname(SORTIE), exist_ok=True)
    with open(SORTIE, "w", encoding="utf-8") as f:
        json.dump(z, f, ensure_ascii=False, indent=1)
    a = z["ajustements"]
    print("écrit %s : %d surfaces/escaliers, %d obstacles, %d volumes de paysage" % (
        os.path.relpath(SORTIE, REPO), len(z["assets"]), len(a["obstacles"]), len(a["p6"]["ville"]["paysage"])))


if __name__ == "__main__":
    main()
