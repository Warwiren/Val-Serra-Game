#!/usr/bin/env python3
"""P7.1 — Génère le BLOCKOUT V0.1 du quartier central de Val'Serra (plan directeur V0.5) au format du socle 2.5D.

Sortie : data/p7/ville_v05.json (instance chargée par la scène du Colisée, comme le quartier provisoire).

PROTOTYPE DE CIRCULATION, NON VALIDÉ : volumes neutres, libellés temporaires, aucun habillage définitif.

Échelle : le plan V0.5 est « hors échelle ». L'échelle est déduite des DURÉES CIBLES du brief, à la vitesse réelle de
marche du jeu (2,2 m/s, data/p6/colisee.json) : 0,145 m par pixel du plan donne en même temps
  guilde -> porte sud ≈ 50 m (≈ 23 s), porte sud -> bord de la grande place ≈ 86 m (≈ 39 s),
  grande place -> entrée publique du Colisée ≈ 44 m (≈ 20 s),
et un Colisée d'environ 58 × 52 m, proche de l'emprise réelle de l'instance du Colisée (64 × 48 m).
Repère du socle : x vers l'est, y vers le SUD du plan, h = altitude (m).

Niveaux (profils du plan : bas -1 / centre 0 / haut +1, recalés en 0 / 1 / 2 m pour rester positifs) :
  sud (porte, guilde, commerces, auberge) h = 0 ; centre (place, Colisée, marché, hôtel de ville) h = 1 ;
  nord (avenue haute, archives, porte du château) h = 2. Les terrasses ne se franchissent que par des escaliers
  (avenue des Portes, rues des boucles ouest et est, avenue haute) : leurs bords sont des murs de soutènement visibles.

Usage : python3 tools/p7/build_ville_v05.py
"""
import json
import math
import os

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SORTIE = os.path.join(REPO, "data", "p7", "ville_v05.json")

W, H = 190.0, 168.0
Y_NORD = 24.0          # bord de la terrasse haute (h 2) ; escaliers de 24 à 27
Y_SUD = 101.0          # bord de la terrasse centrale (h 1) ; escaliers de 101 à 104
L_ESC = 3.0
AVENUE = (102.0, 115.0)          # avenue haute / avenue des Portes (13 m)
ESC_NORD = [(104.0, 113.0)]
ESC_SUD = [(104.0, 113.0), (66.0, 72.0), (150.0, 156.0)]
COLISEE = {"c": (34.0, 53.0), "r": (29.0, 26.0), "haut": 15.0}


def niveau(y):
    return 2.0 if y < Y_NORD + L_ESC else (1.0 if y < Y_SUD + L_ESC else 0.0)


def rect(x0, y0, x1, y1):
    return [round(x0, 3), round(y0, 3), round(x1, 3), round(y1, 3)]


def surface(sid, r, h):
    x0, y0, x1, y1 = r
    return {"id": sid, "category": "surface", "polygon_xy_m": [[x0, y0], [x1, y0], [x1, y1], [x0, y1]], "height_m": h, "walkable": True}


def bande(prefix, y0, y1, h, coupes, x0=2.0, x1=188.0):
    """Surfaces de la bande [y0, y1] entre les escaliers (coupes = [(xa, xb), ...])."""
    out, x, k = [], x0, 0
    for a, b in sorted(coupes):
        if a > x:
            out.append(surface("%s_%d" % (prefix, k), rect(x, y0, a, y1), h))
            k += 1
        x = b
    if x < x1:
        out.append(surface("%s_%d" % (prefix, k), rect(x, y0, x1, y1), h))
    return out


def escalier(eid, x0, x1, y_haut, h_bas, h_haut):
    n = int(math.ceil((h_haut - h_bas) / 0.17))
    return {"id": eid, "category": "transition", "bounds_xy_m": rect(x0, y_haut, x1, y_haut + L_ESC),
            "bottom_h_m": h_bas, "top_h_m": h_haut, "risers": n, "tread_depth_m": round((L_ESC - 0.44) / n, 3)}


# ------------------------------------------------------------------------------------------------ bâtiments
# (id, rect, hauteur m, catégorie, libellé). Catégories : services (couleurs du plan), civique, residentiel, accueil.
BATIMENTS = [
    # terrasse haute (h 2)
    ("n_res_1", rect(4, 5, 24, 17), 9, "residentiel", ""),
    ("n_res_2", rect(27, 5, 46, 17), 12, "residentiel_b", ""),
    ("n_res_3", rect(49, 4, 68, 16), 9, "residentiel", ""),
    ("archives", rect(76, 8, 96, 19), 9, "civique", "Archives"),
    ("n_res_5", rect(121, 4, 138, 16), 9, "residentiel_b", ""),
    ("n_res_6", rect(141, 5, 160, 17), 12, "residentiel", ""),
    ("n_res_7", rect(163, 4, 186, 17), 9, "residentiel_b", ""),
    # terrasse centrale (h 1)
    ("c_res_nord", rect(67, 29, 97, 37), 9, "residentiel", ""),
    ("hotel_de_ville", rect(134, 28, 160, 42), 13, "civique", "Hôtel de ville"),
    ("c_res_ne", rect(163, 28, 186, 44), 9, "residentiel_b", ""),
    ("c_res_est_1", rect(130, 57, 146, 79), 9, "residentiel", ""),
    ("c_res_est_2", rect(159, 56, 186, 63), 9, "residentiel_b", ""),
    ("c_res_est_3", rect(159, 75, 186, 98), 12, "residentiel", ""),
    ("c_res_est_4", rect(131, 90, 146, 99), 6, "residentiel_b", ""),
    ("accueil_arene", rect(75, 62, 86, 72), 6, "accueil", "Accueil de l'arène"),
    ("logements_1", rect(74, 74, 87, 81), 9, "residentiel_b", "Logements"),
    ("logements_2", rect(74, 90, 87, 99), 9, "residentiel", ""),
    ("c_res_so_1", rect(2.5, 81, 31, 99), 9, "residentiel", ""),
    ("c_res_so_2", rect(32, 81, 62, 99), 12, "residentiel_b", ""),
    # terrasse sud (h 0)
    ("atelier", rect(74, 108, 86, 116), 6, "commerce", "Atelier"),
    ("objets", rect(88, 108, 100, 116), 6, "commerce", "Marchand d'objets"),
    ("herboriste", rect(118, 108, 130, 116), 6, "commerce", "Herboriste"),
    ("forge_armurerie", rect(133, 108, 147, 117), 8, "forge", "Forge-armurerie"),
    ("s_res_1", rect(3, 108, 30, 121), 9, "residentiel", ""),
    ("s_res_2", rect(34, 108, 62, 121), 9, "residentiel_b", ""),
    ("s_res_3", rect(3, 125, 30, 140), 6, "residentiel_b", ""),
    ("s_res_4", rect(34, 125, 62, 140), 9, "residentiel", ""),
    ("s_res_5", rect(3, 144, 30, 156), 6, "residentiel", ""),
    ("s_res_6", rect(34, 144, 62, 156), 6, "residentiel_b", ""),
    ("auberge_taverne", rect(76, 121, 99, 134), 9, "auberge", "Auberge-taverne"),
    ("s_res_7", rect(74, 141, 99, 156), 6, "residentiel", ""),
    ("guilde", rect(129, 122, 156, 137), 12, "guilde", "Guilde des Chasseurs"),
    ("s_res_8", rect(119, 142, 156, 156), 6, "residentiel_b", ""),
    ("s_res_9", rect(160, 108, 187, 121), 9, "residentiel", ""),
    ("s_res_10", rect(160, 125, 187, 140), 12, "residentiel_b", ""),
    ("s_res_11", rect(160, 144, 187, 156), 6, "residentiel", ""),
]
# étals du marché (provisoires, 1,8 m) et fontaine-repère (bassin de 7 × 7 m)
ETALS = [rect(93, 76, 97, 78.5), rect(120, 76, 124, 78.5), rect(93, 89.5, 97, 92), rect(120, 89.5, 124, 92)]
FONTAINE = rect(105, 45, 112, 52)


def remparts():
    """Remparts (8 m) et portes. Portes : sud ouverte (passage), château et quartier est fermées (obstacles réels)."""
    out = []
    out.append(("rempart_nord_o", rect(0, 0, 100, 2), 10.0, 2.0))
    out.append(("rempart_nord_e", rect(117, 0, 190, 2), 10.0, 2.0))
    out.append(("rempart_ouest", rect(0, 2, 2, 160), 8.0, None))
    out.append(("rempart_est_n", rect(188, 2, 190, 65), 8.0, None))
    out.append(("rempart_est_s", rect(188, 73, 190, 160), 8.0, None))
    out.append(("rempart_sud_o", rect(0, 158, 100, 160), 8.0, 0.0))
    out.append(("rempart_sud_e", rect(117, 158, 190, 160), 8.0, 0.0))
    # tours des portes
    out.append(("tour_sud_o", rect(100, 156.5, 104, 161), 11.0, 0.0))
    out.append(("tour_sud_e", rect(113, 156.5, 117, 161), 11.0, 0.0))
    out.append(("tour_chateau_o", rect(100, 0, 104, 4.5), 13.0, 2.0))
    out.append(("tour_chateau_e", rect(113, 0, 117, 4.5), 13.0, 2.0))
    out.append(("tour_est_n", rect(186, 62, 190, 66), 10.0, 1.0))
    out.append(("tour_est_s", rect(186, 72, 190, 76), 10.0, 1.0))
    return out


VESTIBULE = (58.0, 51.0, 63.0, 55.0)     # entrée publique (est) : passage de 4 m sous l'enceinte, porte sur la façade


def colisee_tranches(n=26):
    """Enceinte du Colisée en tranches de 2 m (solides rectangulaires du socle) ; vestibule de l'entrée publique évidé."""
    cx, cy = COLISEE["c"]
    rx, ry = COLISEE["r"]
    out = []
    for k in range(n):
        y0 = cy - ry + 2 * ry * k / n
        y1 = cy - ry + 2 * ry * (k + 1) / n
        ym = (y0 + y1) / 2.0
        dx = rx * math.sqrt(max(0.0, 1.0 - ((ym - cy) / ry) ** 2))
        x1 = cx + dx
        if y0 >= VESTIBULE[1] - 1e-6 and y1 <= VESTIBULE[3] + 1e-6:
            x1 = VESTIBULE[0]
        out.append({"id": "colisee_tranche_%02d" % k, "rect": rect(cx - dx, y0, x1, y1), "h": 1.0, "haut": COLISEE["haut"]})
    return out


def construire():
    assets = []
    # terrasse haute (h 2) : nord, puis bande 24..27 hors escalier
    assets.append(surface("sol_haut", rect(2, 2, 188, Y_NORD), 2.0))
    assets += bande("sol_haut_bord", Y_NORD, Y_NORD + L_ESC, 2.0, ESC_NORD)
    # terrasse centrale (h 1)
    assets.append(surface("sol_centre", rect(2, Y_NORD + L_ESC, 188, Y_SUD), 1.0))
    assets += bande("sol_centre_bord", Y_SUD, Y_SUD + L_ESC, 1.0, ESC_SUD)
    # terrasse sud (h 0) et route sous la porte sud (sortie à relier)
    assets.append(surface("sol_sud", rect(2, Y_SUD + L_ESC, 188, 158), 0.0))
    assets.append(surface("route_porte_sud", rect(104, 158, 113, 165), 0.0))
    # sol sous le palier bas de chaque escalier (0,4 m) : le palier n'a pas de dessous physique, la sonde de rebord du
    # héros y voyait un vide (blocage au pied des escaliers)
    for i, (a, b) in enumerate(ESC_NORD):
        assets.append(surface("pied_escalier_nord_%d" % i, rect(a, Y_NORD + L_ESC - 0.4, b, Y_NORD + L_ESC), 1.0))
    for i, (a, b) in enumerate(ESC_SUD):
        assets.append(surface("pied_escalier_sud_%d" % i, rect(a, Y_SUD + L_ESC - 0.4, b, Y_SUD + L_ESC), 0.0))
    # escaliers
    for i, (a, b) in enumerate(ESC_NORD):
        assets.append(escalier("escalier_avenue_haute", a, b, Y_NORD, 1.0, 2.0))
    noms = {(104.0, 113.0): "escalier_avenue_portes", (66.0, 72.0): "escalier_combattants", (150.0, 156.0): "escalier_rue_est"}
    for a, b in ESC_SUD:
        assets.append(escalier(noms[(a, b)], a, b, Y_SUD, 0.0, 1.0))

    obstacles = []
    meta_bat = {}
    for bid, r, haut, cat, lib in BATIMENTS:
        h = niveau((r[1] + r[3]) / 2.0)
        obstacles.append({"id": "bat_" + bid, "rect": r, "h": h, "haut": float(haut)})
        meta_bat["bat_" + bid] = {"categorie": cat, "libelle": lib}
    for i, r in enumerate(ETALS):
        obstacles.append({"id": "etal_%d" % i, "rect": r, "h": 1.0, "haut": 1.8})
    obstacles.append({"id": "fontaine", "rect": FONTAINE, "h": 1.0, "haut": 1.0})
    for rid, r, haut, h in remparts():
        hh = h if h is not None else niveau((r[1] + r[3]) / 2.0)
        obstacles.append({"id": rid, "rect": r, "h": hh, "haut": haut})
    obstacles += colisee_tranches()
    # bout de route sous la porte sud : barrière de chantier visible (la carte extérieure n'existe pas encore)
    obstacles.append({"id": "barriere_route_sud", "rect": rect(104, 164.4, 113, 165), "h": 0.0, "haut": 1.1})

    portes = [
        {"id": "porte_chateau", "rect": [104.0, 2.0, 113.0, 2.4], "type": "grille", "marque": "fermee",
         "texte_ferme": "Porte du château — fermée. L'accès s'ouvrira plus tard dans l'histoire."},
        {"id": "porte_quartier_est", "rect": [187.6, 66.0, 188.0, 72.0], "type": "grille", "marque": "fermee",
         "texte_ferme": "Accès au quartier est — fermé pour l'instant (futur quartier)."},
        {"id": "portes_colisee_public", "rect": [62.6, 51.0, 63.0, 55.0], "type": "porte", "marque": "fermee",
         "fermee_a_partir_de": "coliseum_exited",
         "texte_ferme": "Les portes du Colisée se sont refermées derrière vous. Elles rouvriront plus tard."},
    ]
    examens = [
        {"id": "ex_porte_sud", "xy": [108.5, 163.0], "portee_m": 2.2,
         "texte": "Porte sud — sortie de la ville. (Prototype : la transition vers l'extérieur est prévue mais pas encore reliée.)"},
        {"id": "ex_guilde", "xy": [128.0, 129.5], "portee_m": 1.8, "texte": "Guilde des Chasseurs (blockout : entrée, pas d'intérieur)."},
        {"id": "ex_forge", "xy": [140.0, 107.2], "portee_m": 1.8, "texte": "Forge-armurerie (blockout)."},
        {"id": "ex_auberge", "xy": [88.0, 120.2], "portee_m": 1.8, "texte": "Auberge-taverne (blockout)."},
        {"id": "ex_herboriste", "xy": [124.0, 107.2], "portee_m": 1.8, "texte": "Herboriste (blockout)."},
        {"id": "ex_objets", "xy": [94.0, 107.2], "portee_m": 1.8, "texte": "Marchand d'objets (blockout)."},
        {"id": "ex_hotel_de_ville", "xy": [147.0, 43.2], "portee_m": 1.8, "texte": "Hôtel de ville (blockout)."},
        {"id": "ex_fontaine", "xy": [108.5, 53.0], "portee_m": 1.8, "texte": "Fontaine-repère provisoire de la grande place."},
    ]
    zones = [
        {"id": "place", "nom": "Grande place", "rect": [87.0, 32.0, 130.0, 65.0]},
        {"id": "parvis", "nom": "Parvis du Colisée", "rect": [63.0, 42.0, 87.0, 58.0]},
        {"id": "marche", "nom": "Marché", "rect": [89.0, 72.0, 128.0, 96.0]},
        {"id": "avenue_haute", "nom": "Avenue haute", "rect": [102.0, 2.0, 115.0, 32.0]},
        {"id": "avenue_portes", "nom": "Avenue des Portes", "rect": [102.0, 104.0, 115.0, 158.0]},
        {"id": "rue_conseil", "nom": "Rue du Conseil", "rect": [130.0, 46.0, 188.0, 54.0]},
        {"id": "rue_combattants", "nom": "Rue des Combattants", "rect": [63.0, 58.0, 73.0, 101.0]},
        {"id": "rue_est", "nom": "Rue est", "rect": [147.0, 54.0, 158.0, 101.0]},
        {"id": "passage_est", "nom": "Passage est", "rect": [158.0, 64.0, 188.0, 74.0]},
        {"id": "rue_aventuriers", "nom": "Rue des Aventuriers", "rect": [62.0, 137.0, 160.0, 141.0]},
        {"id": "parvis_guilde", "nom": "Parvis de la Guilde", "rect": [115.0, 121.0, 129.0, 137.0]},
    ]
    points = {  # repères de mesure (portes des bâtiments, côté rue)
        "porte_sud": [108.5, 155.0, 0.0], "guilde": [127.5, 129.5, 0.0], "forge": [140.0, 106.0, 0.0],
        "auberge": [88.0, 119.0, 0.0], "herboriste": [124.0, 106.0, 0.0], "objets": [94.0, 106.0, 0.0],
        "place": [108.5, 57.0, 1.0], "colisee": [65.0, 53.0, 1.0], "hotel_de_ville": [147.0, 43.8, 1.0],
        "marche": [108.5, 84.0, 1.0], "chateau": [108.5, 6.0, 2.0], "quartier_est": [185.5, 69.0, 1.0],
    }
    zone = {
        "project": "Val'Serra — Les Larmes d'Aether",
        "stage": "P7.1 — Quartier central, BLOCKOUT V0.1 (prototype de circulation, NON VALIDÉ)",
        "godot_target": "4.7.2",
        "_note": "Généré par tools/p7/build_ville_v05.py — ne pas éditer à la main.",
        "world": {"axes": "x droite (est), y bas du plan (sud), h altitude", "unit": "mètre", "extent_m": [W, H],
                  "reference_native_px_per_m": 20},
        "checkpoints": [{"id": k, "name": k, "xy_m": v[:2], "height_m": v[2]} for k, v in points.items()],
        "assets": assets,
        "ajustements": {
            "parametres": {"pas_franchissable_m": 0.25, "rayon_personnage_m": 0.28, "vitesse_m_s": 2.2,
                           "vitesse_course_m_s": 3.6, "ecart_compagnon_m": 1.0, "assistance_escalier": 0.3},
            "escalier": {"palier_bas_m": 0.22, "palier_haut_m": 0.22},
            "decor_marge": [-30.0, -40.0, W + 30.0, H + 20.0],
            "obstacles": obstacles,
            "entree": {"xy": [108.5, 155.0], "h": 0.0},
            "sorties": [
                {"id": "entree_colisee", "rect": [58.2, 51.0, 59.2, 55.0], "vers": "res://data/p6/colisee.json",
                 "porte": [58.2, 51.0, 58.2, 55.0], "arrivee": [61.5, 23.0, 0.0]},
            ],
            "p6": {
                "nom": "Val'Serra — quartier central (blockout V0.1, prototype)",
                "zone": "ville",
                "sols": {},
                "portes": portes,
                "examens": examens,
                "zones_nommees": zones,
                "camera_vue_dessus": [0.0, -2.0, W, H],
                "lumieres": [],
                "ville": {
                    "batiments": meta_bat,
                    "colisee": {"centre": list(COLISEE["c"]), "rayons": list(COLISEE["r"]), "h": 1.0, "haut": COLISEE["haut"],
                                "porte": [63.0, 53.0], "vestibule": list(VESTIBULE)},
                    "fontaine": FONTAINE,
                    "niveaux": {"nord": [0.0, Y_NORD], "centre": [Y_NORD + L_ESC, Y_SUD], "sud": [Y_SUD + L_ESC, 158.0]},
                    "points": points,
                    "arrivee_colisee": [66.5, 53.0, 1.0],
                },
            },
        },
    }
    return zone


def main():
    z = construire()
    os.makedirs(os.path.dirname(SORTIE), exist_ok=True)
    with open(SORTIE, "w", encoding="utf-8") as f:
        json.dump(z, f, ensure_ascii=False, indent=1)
    a = z["ajustements"]
    print("écrit %s : %d surfaces/escaliers, %d obstacles" % (os.path.relpath(SORTIE, REPO), len(z["assets"]), len(a["obstacles"])))


if __name__ == "__main__":
    main()
