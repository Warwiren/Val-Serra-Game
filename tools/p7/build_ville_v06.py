#!/usr/bin/env python3
"""P7.3 — Génère la DÉMONSTRATION VERTICALE V0.6 de Val'Serra au format du socle 2.5D.

Sortie : data/p7/ville_v06.json (instance chargée par la scène du Colisée en mode « ville v06 »).

PROTOTYPE DE CADRAGE ET DE PROGRESSION, NON VALIDÉ : volumes architecturaux provisoires, aucun habillage définitif.
Le blockout V0.1 (ville_v05.json) n'est qu'une référence fonctionnelle : aucune de ses géométries n'est reprise.

Périmètre (brief V0.6, § 6) : un seul parcours vertical représentatif
    porte sud -> guilde -> montée -> grande place -> montée vers le quartier haut
dans une ville compacte à parcourir mais grande à regarder :
  * l'espace PRATICABLE est une seule avenue nord-sud (la caméra regarde le nord : rien ne s'interpose entre elle et
    Aren dans une rue nord-sud), une place, un parvis et quelques seuils de portes ;
  * tout le reste est du PAYSAGE : façades serrées qui ferment les rues (aucune circulation entre bâtiments
    décoratifs), toitures en gradins, tours, et au loin le quartier du château (décor seul, jamais construit).

Repère du socle : x vers l'est, y vers le SUD, h = altitude (m). Caméra de la ville : azimut 0 (elle regarde le nord).

Niveaux (calibrés pour la caméra V0.6 et un personnage de 1,75 m ; réglables ici, rien n'est définitif) :
  bas    h = 0,0 : quartier des voyageurs (porte sud, guilde, auberge-taverne)
  médian h = 3,5 : quartier central (grande place, fontaine, commerces dont la forge-armurerie, accès au Colisée)
  haut   h = 8,0 : quartier civique (hôtel de ville, archives, avenue et porte du château fermée)
Les murs de soutènement (3,5 m puis 4,5 m, soit deux à trois fois la hauteur d'Aren) font face à la caméra : chaque
niveau supérieur se lit comme un gradin au-dessus du précédent. On ne change de niveau que par les deux escaliers.

Usage : python3 tools/p7/build_ville_v06.py
"""
import json
import math
import os

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SORTIE = os.path.join(REPO, "data", "p7", "ville_v06.json")

W, H = 130.0, 190.0
H0, H1, H2 = 0.0, 3.5, 8.0
Y_MUR1 = 118.0         # mur de soutènement bas / médian (face sud)
Y_MUR2 = 72.0          # mur de soutènement médian / haut (face sud)
X_MUR2_O = 36.0        # à l'ouest de x = 36, le niveau médian continue vers le nord (Colisée)
ESC1 = (54.0, 66.0, Y_MUR1, 10.0)      # x0, x1, y du palier haut, longueur : montée 1 (3,5 m sur 10 m)
ESC2 = (52.0, 68.0, Y_MUR2, 12.0)      # montée 2 (4,5 m sur 12 m), monumentale
COLISEE = {"c": (13.0, 80.0), "r": (26.0, 22.0), "haut": 17.0}
VESTIBULE = (32.0, 88.0, 36.2, 92.0)   # entrée publique du Colisée (est), au bout de la rue du Colisée


def rect(x0, y0, x1, y1):
    return [round(x0, 3), round(y0, 3), round(x1, 3), round(y1, 3)]


def surface(sid, r, h):
    x0, y0, x1, y1 = r
    return {"id": sid, "category": "surface", "polygon_xy_m": [[x0, y0], [x1, y0], [x1, y1], [x0, y1]], "height_m": h, "walkable": True}


def escalier(eid, x0, x1, y_haut, longueur, h_bas, h_haut):
    n = int(math.ceil((h_haut - h_bas) / 0.17))
    return {"id": eid, "category": "transition", "bounds_xy_m": rect(x0, y_haut, x1, y_haut + longueur),
            "bottom_h_m": h_bas, "top_h_m": h_haut, "risers": n, "tread_depth_m": round((longueur - 0.44) / n, 3)}


# ------------------------------------------------------------------------------------------------ praticable
def praticable():
    s = []
    # niveau bas : route hors les murs (barrière de fin de carte), passage de la porte, avenue des Voyageurs
    s.append(surface("route_sud", rect(56, 173, 64, 182), H0))
    s.append(surface("porte_sud", rect(56, 168, 64, 173), H0))
    s.append(surface("avenue_voyageurs", rect(54, 128, 66, 168), H0))
    s.append(surface("parvis_guilde", rect(66, 150, 80, 160), H0))       # placette devant la façade sud de la Guilde
    s.append(surface("terrasse_auberge", rect(46, 136, 54, 144), H0))    # terrasse devant la façade sud de l'auberge
    s.append(surface("pied_esc1", rect(ESC1[0], ESC1[2] + ESC1[3] - 0.4, ESC1[1], ESC1[2] + ESC1[3]), H0))
    # niveau médian : grande place, rue du Colisée
    s.append(surface("grande_place", rect(40, 84, 80, Y_MUR1), H1))
    s.append(surface("rue_colisee", rect(VESTIBULE[2], 88, 40, 92), H1))
    s.append(surface("vestibule_colisee", rect(VESTIBULE[0], 88, VESTIBULE[2], 92), H1))
    s.append(surface("pied_esc2", rect(ESC2[0], ESC2[2] + ESC2[3] - 0.4, ESC2[1], ESC2[2] + ESC2[3]), H1))
    # niveau haut : parvis civique, avenue du château
    s.append(surface("parvis_civique", rect(44, 50, 80, Y_MUR2), H2))
    s.append(surface("avenue_chateau", rect(54, 24.4, 66, 50), H2))
    s.append(escalier("montee_place", ESC1[0], ESC1[1], ESC1[2], ESC1[3], H0, H1))
    s.append(escalier("montee_civique", ESC2[0], ESC2[1], ESC2[2], ESC2[3], H1, H2))
    return s


# ------------------------------------------------------------------------------------------------ bâtiments
# (id, rect, niveau du pied, hauteur des murs (m), catégorie, libellé, toit) ; toit : "2p" deux pans (faîtage le long
# du grand côté), "plat" terrasse. Tous BLOQUENT (collision des données) : ils bordent le praticable ou ferment une rue.
# Règle de composition (caméra fixe tournée vers le nord) :
#   * les bâtiments importants ont leur façade principale au SUD, face à la caméra, sur le front nord d'un espace
#     ouvert (guilde, auberge, forge, hôtel de ville, archives) ;
#   * entre la caméra (≈ 22 m au sud d'Aren, ≈ 4,3 m au-dessus de lui) et un lieu où l'on s'arrête, les volumes restent
#     BAS (murets de 1,2 m, jardin clos, appentis ≤ 2,6 m) ; les fronts hauts sont latéraux.
BATIMENTS = [
    # --- niveau bas, ouest de l'avenue (du sud au nord)
    ("b_o1", rect(36, 158, 54, 168), H0, 8.0, "residentiel", "", "2p"),
    ("b_o2", rect(38, 150, 50, 158), H0, 10.0, "residentiel_b", "", "2p"),
    ("b_o2_bas", rect(50, 145, 54, 158), H0, 2.6, "residentiel", "", ""),
    ("muret_auberge", rect(46, 144, 54, 145), H0, 1.2, "residentiel_b", "", ""),
    ("b_o_ouest", rect(34, 136, 46, 150), H0, 9.0, "residentiel", "", "2p"),
    ("auberge_taverne", rect(36, 124, 54, 136), H0, 9.0, "auberge", "Auberge-taverne", "2p"),
    ("b_o3", rect(38, 118, 54, 124), H0, 6.0, "residentiel_b", "", "2p"),
    # --- niveau bas, est de l'avenue
    ("muret_guilde", rect(66, 160, 80, 161), H0, 1.2, "residentiel_b", "", ""),   # muret au sud de la placette (caméra au-dessus)
    ("jardin_guilde", rect(66, 161, 80, 168), H0, 0.6, "residentiel", "", ""),     # jardin clos (bas, non praticable)
    ("b_e1b", rect(80, 150, 94, 168), H0, 9.0, "residentiel", "", "2p"),
    ("guilde", rect(66, 136, 88, 150), H0, 13.0, "guilde", "Guilde des Chasseurs", "2p"),
    ("b_e4", rect(66, 128, 84, 136), H0, 7.0, "residentiel_b", "", "2p"),
    ("b_e5", rect(66, 118, 82, 128), H0, 6.0, "residentiel", "", "2p"),
    # --- remparts sud et porte (rendus coupés : ils sont entre la caméra et Aren à l'arrivée)
    ("rempart_sud_o", rect(10, 170, 52, 173), H0, 9.0, "rempart", "", ""),
    ("rempart_sud_e", rect(68, 170, 120, 173), H0, 9.0, "rempart", "", ""),
    ("tour_sud_o", rect(52, 168, 56, 175), H0, 12.0, "rempart", "", ""),
    ("tour_sud_e", rect(64, 168, 68, 175), H0, 12.0, "rempart", "", ""),
    # --- niveau médian, autour de la place (front nord bas : la caméra du parvis civique passe au-dessus)
    ("objets", rect(40, 72, 52, 84), H1, 4.0, "commerce", "", "2p"),
    ("forge_armurerie", rect(68, 72, 80, 84), H1, 4.0, "forge", "Forge-armurerie", "2p"),
    ("herboriste", rect(80, 84, 94, 100), H1, 7.0, "commerce", "", "2p"),
    ("m_e", rect(80, 100, 96, 112), H1, 8.0, "commerce", "", "2p"),
    ("m_se", rect(80, 112, 96, 118), H1, 6.0, "residentiel_b", "", "2p"),
    ("m_o", rect(31, 96, 40, 110), H1, 3.5, "commerce", "", "2p"),     # bas : le Colisée se lit depuis la place,
    ("m_so", rect(24, 110, 40, 118), H1, 3.5, "residentiel", "", "2p"),
    ("m_no", rect(38, 72, 40, 88), H1, 9.0, "residentiel_b", "", "plat"),    # joint entre le Colisée et la place
    ("m_o_seuil", rect(34, 92, 40, 96), H1, 3.5, "residentiel", "", "2p"),
    # --- niveau haut, quartier civique
    ("archives", rect(30, 34, 54, 50), H2, 12.0, "civique", "", "plat"),
    ("h_o", rect(36, 50, 44, 72), H2, 12.0, "residentiel", "", "2p"),
    ("hotel_de_ville", rect(66, 32, 96, 50), H2, 15.0, "civique", "Hôtel de ville", "2p"),
    ("h_e", rect(80, 50, 100, 72), H2, 12.0, "residentiel_b", "", "2p"),
    ("tour_chateau_o", rect(50, 20, 54, 26), H2, 7.5, "rempart", "", ""),
    ("tour_chateau_e", rect(66, 20, 70, 26), H2, 7.5, "rempart", "", ""),
    ("enceinte_chateau_o", rect(20, 22, 50, 24.4), H2, 4.5, "rempart", "", ""),
    ("enceinte_chateau_e", rect(70, 22, 110, 24.4), H2, 4.5, "rempart", "", ""),
]

# Paysage SANS collision (hors d'atteinte : au-delà des fronts bâtis ou sur des niveaux sans praticable) :
# (rect, pied, hauteur des murs, catégorie, toit). Gradins de toitures de part et d'autre de l'axe et au loin.
def paysage():
    out = []
    rangs = [
        # bas, derrière les fronts (ouest puis est)
        (H0, [(14, 150, 36, 168, 7.0), (16, 132, 34, 150, 9.0), (14, 118, 38, 132, 6.0), (94, 150, 110, 168, 7.0),
              (90, 132, 112, 150, 10.0), (84, 118, 104, 132, 7.0), (-8, 120, 14, 168, 6.0), (108, 120, 132, 168, 8.0)]),
        # médian, derrière la place
        (H1, [(96, 84, 116, 100, 9.0), (98, 100, 118, 118, 7.0), (116, 84, 136, 118, 10.0), (14, 96, 28, 118, 8.0),
              (-10, 96, 14, 118, 7.0), (80, 72, 98, 84, 10.0), (98, 72, 118, 84, 8.0)]),
        # haut, derrière le quartier civique
        (H2, [(102, 46, 122, 72, 11.0), (14, 48, 30, 72, 10.0), (96, 26, 118, 46, 12.0), (118, 26, 136, 46, 10.0),
              (8, 26, 30, 46, 11.0), (122, 50, 140, 72, 9.0)]),
    ]
    for h, lst in rangs:
        for x0, y0, x1, y1, haut in lst:
            out.append({"rect": rect(x0, y0, x1, y1), "h": h, "haut": haut, "toit": "2p"})
    return out


def colisee_tranches(n=22):
    """Enceinte du Colisée en tranches (solides du socle) ; seul le côté est touche le praticable (rue du Colisée)."""
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
        out.append({"id": "colisee_tranche_%02d" % k, "rect": rect(cx - dx, y0, x1, y1), "h": H1, "haut": COLISEE["haut"]})
    return out


def construire():
    assets = praticable()
    obstacles = []
    meta_bat = {}
    for bid, r, h, haut, cat, lib, toit in BATIMENTS:
        if haut <= 0.0:
            continue
        obstacles.append({"id": "bat_" + bid if not bid.startswith(("rempart", "tour", "enceinte")) else bid,
                          "rect": r, "h": h, "haut": haut})
        meta_bat["bat_" + bid] = {"categorie": cat, "libelle": lib, "toit": toit}
    obstacles.append({"id": "fontaine", "rect": rect(56.5, 96.5, 63.5, 103.5), "h": H1, "haut": 1.0})
    obstacles += colisee_tranches()
    # garde-corps (collision réelle, 1 m) le long des bords de terrasse qui ne sont pas des escaliers
    gc = [("gc_place_o", rect(40, 117.6, ESC1[0], 118), H1), ("gc_place_e", rect(ESC1[1], 117.6, 80, 118), H1),
          ("gc_parvis_o", rect(44, 71.6, ESC2[0], 72), H2), ("gc_parvis_e", rect(ESC2[1], 71.6, 76, 72), H2)]
    for gid, r, h in gc:
        obstacles.append({"id": gid, "rect": r, "h": h, "haut": 1.0})
    obstacles.append({"id": "barriere_route_sud", "rect": rect(56, 181.4, 64, 182), "h": H0, "haut": 1.1})

    portes = [
        {"id": "porte_chateau", "rect": [54.0, 24.0, 66.0, 24.4], "type": "grille", "marque": "fermee", "h": H2,
         "texte_ferme": "Porte du château — fermée. L'accès s'ouvrira plus tard dans l'histoire."},
        {"id": "portes_colisee_public", "rect": [VESTIBULE[2] - 0.4, 88.0, VESTIBULE[2], 92.0], "type": "porte", "marque": "fermee", "h": H1,
         "fermee_a_partir_de": "coliseum_exited",
         "texte_ferme": "Les portes du Colisée se sont refermées derrière vous. Elles rouvriront plus tard."},
    ]
    examens = [
        {"id": "ex_porte_sud", "xy": [60.0, 180.0], "portee_m": 2.2,
         "texte": "Porte sud — sortie de la ville. (Prototype : la transition vers l'extérieur n'est pas encore reliée.)"},
        {"id": "ex_guilde", "xy": [70.0, 150.6], "portee_m": 1.8, "texte": "Guilde des Chasseurs (volume provisoire, pas d'intérieur)."},
        {"id": "ex_auberge", "xy": [50.0, 136.6], "portee_m": 1.8, "texte": "Auberge-taverne (volume provisoire)."},
        {"id": "ex_forge", "xy": [74.0, 84.6], "portee_m": 1.8, "texte": "Forge-armurerie (volume provisoire)."},
        {"id": "ex_fontaine", "xy": [60.0, 104.6], "portee_m": 1.8, "texte": "Fontaine de la grande place (repère provisoire)."},
        {"id": "ex_hotel_de_ville", "xy": [74.0, 50.6], "portee_m": 1.8, "texte": "Hôtel de ville (volume provisoire)."},
    ]
    zones = [
        {"id": "avenue_voyageurs", "nom": "Avenue des Voyageurs", "rect": [54.0, 128.0, 66.0, 168.0]},
        {"id": "grande_place", "nom": "Grande place", "rect": [40.0, 84.0, 80.0, 118.0]},
        {"id": "parvis_civique", "nom": "Parvis civique", "rect": [44.0, 50.0, 80.0, 72.0]},
        {"id": "avenue_chateau", "nom": "Avenue du Château", "rect": [54.0, 24.4, 66.0, 50.0]},
    ]
    points = {  # repères de mesure (portes, côté rue)
        "porte_sud": [60.0, 166.0, H0], "guilde": [70.0, 151.2, H0], "auberge": [50.0, 137.2, H0],
        "pied_montee_1": [60.0, 129.0, H0], "haut_montee_1": [60.0, 116.5, H1], "fontaine": [60.0, 106.0, H1],
        "forge": [74.0, 85.2, H1], "colisee": [39.0, 90.0, H1], "pied_montee_2": [60.0, 85.0, H1],
        "haut_montee_2": [60.0, 70.5, H2], "hotel_de_ville": [74.0, 51.2, H2], "chateau": [60.0, 26.0, H2],
    }
    zone = {
        "project": "Val'Serra — Les Larmes d'Aether",
        "stage": "P7.3 — Ville V0.6 : démonstration verticale (caméra HD-2D, trois niveaux), PROTOTYPE NON VALIDÉ",
        "godot_target": "4.7.2",
        "_note": "Généré par tools/p7/build_ville_v06.py — ne pas éditer à la main.",
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
            "entree": {"xy": [60.0, 166.0], "h": H0},
            "sorties": [
                {"id": "entree_colisee", "rect": [VESTIBULE[0] + 1.0, 88.0, VESTIBULE[0] + 2.0, 92.0], "vers": "res://data/p6/colisee.json",
                 "porte": [VESTIBULE[0] + 1.0, 88.0, VESTIBULE[0] + 1.0, 92.0], "arrivee": [61.5, 23.0, 0.0]},
            ],
            "p6": {
                "nom": "Val'Serra — montée vers le quartier haut (V0.6, prototype)",
                "zone": "ville",
                "sols": {},
                "portes": portes,
                "examens": examens,
                "zones_nommees": zones,
                "camera_vue_dessus": [0.0, -40.0, W, H],
                "lumieres": [],
                "ville": {
                    "version": "v06",
                    "batiments": meta_bat,
                    "paysage": paysage(),
                    "niveaux": {"bas": H0, "median": H1, "haut": H2, "mur1_y": Y_MUR1, "mur2_y": Y_MUR2, "mur2_x_ouest": X_MUR2_O},
                    "escaliers": {"montee_place": list(ESC1), "montee_civique": list(ESC2)},
                    "colisee": {"centre": list(COLISEE["c"]), "rayons": list(COLISEE["r"]), "h": H1, "haut": COLISEE["haut"],
                                "porte": [VESTIBULE[2], 90.0], "vestibule": list(VESTIBULE)},
                    "fontaine": rect(56.5, 96.5, 63.5, 103.5),
                    "points": points,
                    "arrivee_colisee": [41.5, 90.0, H1],
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
    print("écrit %s : %d surfaces/escaliers, %d obstacles, %d volumes de paysage" % (
        os.path.relpath(SORTIE, REPO), len(z["assets"]), len(a["obstacles"]), len(a["p6"]["ville"]["paysage"])))


if __name__ == "__main__":
    main()
