#!/usr/bin/env python3
"""P7.5 — Génère la VILLE V0.7-B : reconstruction compacte du quartier central (blockout architectural consolidé).

Sortie : data/p7/ville_v07b.json (scène F6 scenes/p7/ville_v07b.tscn). La V0.7-A (build_ville_v07a.py) reste la référence.

BLOCKOUT CONSOLIDÉ, NON VALIDÉ. Tracé en fer à cheval autour de la grande place, ouvert au sud, montant vers le nord :
  porte sud -> placette d'accueil (Guilde, auberge-taverne) -> montée en baïonnette -> grande place (fontaine, forge,
  boutique, étals ; Colisée à l'ouest) -> montée civique monumentale -> terrasse civique (hôtel de ville, administration)
  -> accès gardé au château.
Boucle courte : place -> ruelle des Tonneliers -> rue du chantier -> terrasse de l'auberge -> placette -> montée.
Accès futurs (un par secteur, jamais deux depuis le même lieu) : A quartier est (chantier, depuis la placette),
B faubourgs ouest (caravane, depuis le parvis du Colisée), C château (porte gardée, depuis la terrasse civique).
Largeurs : rues principales 8 à 12 m, ruelle 4 m, volées ordinaires 6 m, montée civique monumentale 8 m.
Niveaux 0 / 3,5 / 8 m (paliers 1,75 et 5,75 m). Colisée, propylée, porte et portail : ceux de la V0.7-A, inchangés.

Usage : python3 tools/p7/build_ville_v07b.py
"""
import json
import math
import os

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SORTIE = os.path.join(REPO, "data", "p7", "ville_v07b.json")

W, H = 140.0, 170.0
H0, HP1, H1, HP2, H2 = 0.0, 1.75, 3.5, 5.75, 8.0
# volées : (id, x0, x1, y_haut, longueur, h_bas, h_haut) — 6 m de large au plus (V0.6 : 12 et 16 m)
VOLEES = [
    ("volee_a", 56.0, 62.0, 126.0, 6.0, H0, HP1),     # placette -> palier 1
    ("volee_b", 62.0, 68.0, 115.0, 6.0, HP1, H1),     # palier 1 -> grande place (décalée vers l'est)
    ("volee_c", 58.0, 66.0, 82.0, 6.0, H1, HP2),      # montée civique MONUMENTALE (8 m) : grande place -> palier 2
    ("volee_d", 68.0, 76.0, 71.0, 6.0, HP2, H2),      # palier 2 -> terrasse civique (décalée vers l'est)
    ("ruelle_escalier", 80.0, 84.0, 115.0, 10.0, H0, H1),   # ruelle secondaire, 4 m de large
]
COLISEE = {"c": (0.0, 54.0), "r": (28.0, 24.0), "haut": 18.0}     # au nord-ouest de la place, entrée publique au SUD
# P7.4.1 : porte publique sur la façade EST du tambour (vers la grande place), comme la sortie publique de l'instance du
# Colisée (couloir de sortie et porte est, x 63,6 à 65 m) : les deux portes regardent le même axe réel, l'est.
VESTIBULE = (24.0, 60.0, 26.5, 64.0)                                 # x0, y0, x1, y1 : vestibule de la porte est
# P7.4.2 : propylée (x 26,5 -> 35, y 57 -> 67) : arche est entre les piles NE et SE (y 58,6 -> 65,4), arche sud entre les
# piles SO et SE (x 27,5 -> 33,4), mur nord plein. Le portail (fond du vestibule) et les arrivées ne changent pas.
PROPYLEE = {"emprise": [26.5, 57.0, 35.0, 67.0],
            "piles": {"no": [26.5, 57.0, 28.1, 58.6], "ne": [33.4, 57.0, 35.0, 58.6],
                      "se": [33.4, 65.4, 35.0, 67.0], "so": [26.5, 65.4, 27.5, 67.0]},
            "mur_n": [28.1, 57.0, 33.4, 57.8]}
# P7.5 : porte publique à deux battants dans l'ARCHE SUD du propylée (face à l'allée et à la caméra), en retrait de 0,6 m
# des piles ; l'arche est devient aveugle (porche fermé, antichambre du vestibule). Plan de la porte : y 66,2 à 66,4.
PORTE_BATTANTS = [27.5, 66.2, 33.4, 66.4]
ARCHE_EST_AVEUGLE = [34.6, 58.6, 35.0, 65.4]


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
    s.append(surface("terrasse_auberge", rect(72, 132, 80, 136), H0))          # devant l'auberge : placette <-> rue du chantier
    # --- paliers et place (1,75 / 3,5 m)
    s.append(surface("palier_1", rect(56, 121, 68, 126), HP1))
    s.append(surface("balcon_palier", rect(56, 115, 62, 121), H1))            # belvédère au-dessus du palier
    s.append(surface("belvedere_palier", rect(62, 126, 68, 132), HP1))        # P7.4.1 : prolongement du palier (praticable)
    s.append(surface("grande_place", rect(30, 88, 72, 115), H1))
    s.append(surface("place_bras_est", rect(72, 100, 84, 115), H1))          # bras de la place vers la ruelle (P7.6 : jusqu'à x 84)
    s.append(surface("place_recoin", rect(72, 88, 80, 100), H1))              # recoin de la boutique de fournitures
    s.append(surface("rue_colisee", rect(14, 96, 30, 104), H1))               # embranchement ouest
    s.append(surface("place_ouest", rect(14, 104, 30, 115), H1))              # P7.4.1 : la place rejoint l'embranchement
    s.append(surface("parvis_colisee", rect(-10, 70, 22, 104), H1))      # sous le tambour au nord (solides des tranches)
    s.append(surface("vestibule_colisee", rect(VESTIBULE[0], VESTIBULE[1], VESTIBULE[2], VESTIBULE[3]), H1))
    s.append(surface("perron_colisee", rect(VESTIBULE[2], 56, 36, 70), H1))          # perron devant la porte est (sous le propylée)
    s.append(surface("allee_colisee", rect(22, 70, 30, 96), H1))                     # allée parvis -> perron (jusqu'à la rue)
    s.append(surface("perron_angle_se", rect(30, 70, 36, 79), H1))                   # P7.6 : angle libéré par l'échoppe reculée
    s.append(surface("passage_faubourgs", rect(-18, 92, -10, 100), H1))              # B : vers les faubourgs (caravane)
    # --- montée haute et terrasse (5,75 / 8 m)
    s.append(surface("palier_2", rect(58, 77, 76, 82), HP2))
    s.append(surface("terrasse_haute", rect(56, 50, 90, 71), H2))
    s.append(surface("avenue_chateau", rect(66, 40.4, 74, 50), H2))
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
    ("auberge_taverne", rect(68, 115, 80, 132), H0, 7.5, "auberge", "Auberge-taverne", "2p"),   # façade sud, angle nord-est
    ("b_o_placette", rect(30, 132, 48, 150), H0, 8.0, "residentiel", "", "2p"),
    ("b_e_placette", rect(72, 144, 96, 150), H0, 1.2, "residentiel_b", "", ""),    # muret bas (rue du chantier)
    ("b_e_ruelle", rect(84, 115, 100, 136), H0, 8.0, "residentiel", "", "2p"),
    # P7.6 : ferme le bout du bras est (x 84 -> 86 menait à un vide entre deux volumes de décor : faux passage vers l'est)
    ("b_bras_est_e", rect(84, 100, 98, 115), H1, 6.0, "residentiel_b", "", "2p"),
    ("rempart_sud_o", rect(10, 152, 53, 155), H0, 9.0, "rempart", "", ""),
    ("rempart_sud_e", rect(67, 152, 120, 155), H0, 9.0, "rempart", "", ""),
    ("tour_sud_o", rect(53, 150, 57, 157), H0, 12.0, "rempart", "", ""),
    ("tour_sud_e", rect(63, 150, 67, 157), H0, 12.0, "rempart", "", ""),
    # --- palier 1 : bloc de pierre à l'est de la volée A (sous le palier)
    # --- grande place : fronts denses
    # P7.6 : étals abaissés (0,45 m) ; la partie ouest recule de 3 m vers le sud (y 76 -> 79) : dégage l'angle allée / perron
    ("echoppe_no", rect(36, 76, 44, 88), H1, 0.45, "commerce", "", ""),
    ("echoppe_no_o", rect(30, 79, 36, 88), H1, 0.45, "commerce", "", ""),
    ("forge_armurerie", rect(44, 76, 58, 88), H1, 4.0, "forge", "Forge-armurerie", "2p"),    # façade sud
    ("boutique_fournitures", rect(76, 76, 88, 88), H1, 5.0, "commerce", "Boutique de fournitures", "2p"),   # façade sud (recoin)
    ("commerce_e2", rect(80, 88, 88, 100), H1, 6.0, "commerce", "", "2p"),
    ("socle_palier_2", rect(66, 82, 76, 88), H1, HP2 - H1, "rempart", "", ""),
    ("b_porche_n", rect(24, 44, 40, 56), H1, 6.0, "residentiel_b", "", "2p"),            # ferme le perron au nord
    ("b_no_place", rect(36, 56, 40, 76), H1, 0.6, "commerce", "", ""),         # P7.4.2 : étals bas (caméra B au-dessus)
    ("b_arriere_forge", rect(40, 71, 58, 76), H1, 4.5, "residentiel_b", "", "plat"),        # contre le mur de la terrasse
    ("b_parvis_o", rect(-24, 82, -10, 92), H1, 7.0, "residentiel", "", "2p"),              # front ouest du parvis (nord)
    ("b_parvis_o2", rect(-24, 100, -10, 104), H1, 1.2, "residentiel_b", "", ""),           # front ouest du parvis (sud) : BAS, sinon il cache la caravane (accès B)
    ("b_faubourg_n", rect(-34, 84, -24, 92), H1, 6.0, "residentiel_b", "", "2p"),           # P7.6 : x -18 -> -24 (recouvrait b_parvis_o)          # B : le passage se poursuit
    ("b_faubourg_s", rect(-34, 100, -24, 108), H1, 5.0, "residentiel", "", "2p"),          # P7.6 : idem (b_parvis_o2)
    ("b_parvis_s", rect(-10, 104, 14, 112), H1, 1.2, "residentiel_b", "", ""),             # bas : la caméra passe au-dessus
    # --- terrasse haute
    ("administration", rect(40, 44, 56, 71), H2, 10.0, "civique", "Administration", "plat"),
    ("b_terrasse_no", rect(56, 36, 66, 50), H2, 11.0, "civique", "", "2p"),
    ("hotel_de_ville", rect(74, 32, 92, 50), H2, 13.0, "civique", "Hôtel de ville", "2p"),     # façade sud sur la terrasse
    ("b_terrasse_e3", rect(90, 58, 104, 64), H2, 8.0, "residentiel", "", "2p"),               # (ancienne rue haute : fermée par du bâti)
    ("b_terrasse_e", rect(90, 64, 104, 72), H2, 8.0, "residentiel", "", "2p"),
    ("b_terrasse_e2", rect(92, 44, 104, 58), H2, 9.0, "residentiel_b", "", "2p"),          # P7.6 : x 90 -> 92 (recouvrait l'hôtel de ville)
    ("socle_palier_2b", rect(58, 71, 68, 77), H1, H2 - H1, "rempart", "", ""),              # sous la terrasse, à l'ouest de D
    # P7.6 : tours de la porte du château retirées : entièrement noyées dans b_terrasse_no et l'hôtel de ville (invisibles,
    # volumes confondus) ; la porte reste encadrée par les guérites et les gardes
]


def paysage():
    """Volumes sans collision, hors d'atteinte : prolongements de la ville (rues futures, gradins de toits)."""
    out = []
    rangs = [
        (H0, [(100, 128, 116, 136, 7.0), (96, 144, 118, 152, 8.0), (118, 128, 136, 152, 6.0),     # rue du chantier, au-delà
              (8, 120, 30, 150, 7.0), (8, 115, 30, 120, 2.5), (100, 112, 120, 128, 9.0), (-10, 120, 8, 150, 6.0)]),
        (H1, [(88, 76, 104, 100, 8.0), (104, 80, 124, 104, 9.0), (-6, 112, 14, 120, 5.0), (98, 100, 104, 112, 6.0),
              # faubourgs ouest : la rue du passage B continue entre deux fronts, puis tourne (rue « disparaissant »)
              (-60, 80, -34, 92, 7.0), (-60, 100, -34, 114, 6.0), (-76, 88, -60, 104, 8.0), (-40, 60, -24, 80, 9.0)]),
        (H2, [(104, 40, 124, 72, 10.0), (124, 44, 140, 70, 8.0), (94, 30, 114, 40, 9.0)]),
        # P7.6 : ce volume flottait à 8 m au-dessus du perron (x 20 -> 40 : pas de terrasse haute à l'ouest de x 40) ;
        # posé au niveau de la place, au nord du bâti du perron
        (H1, [(20, 30, 40, 44, 15.5)]),
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
        [rect(58, 77, 76, 82), HP2],                      # sous le palier 2
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
        if y0 >= VESTIBULE[1] - 1e-6 and y1 <= VESTIBULE[3] + 1e-6:
            x1 = VESTIBULE[0]                      # vestibule de la porte est évidé
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
        ("gc_terrasse_o", rect(56, 70.6, 68, 71), H2), ("gc_terrasse_e", rect(76, 70.6, 90, 71), H2),
        ("gc_palier_2_o", rect(58, 77, 58.4, 82), HP2), ("gc_place_bras_o", rect(72, 114.6, 80, 115), H1),
        ("gc_place_e", rect(68, 114.6, 72, 115), H1),
    ]
    for gid, r, h in gc:
        obstacles.append({"id": gid, "rect": r, "h": h, "haut": 1.0})
    obstacles.append({"id": "barriere_chantier", "rect": rect(89.4, 136, 90, 144), "h": H0, "haut": 1.2})
    obstacles.append({"id": "barriere_route_sud", "rect": rect(57, 161.4, 63, 162), "h": H0, "haut": 1.1})
    obstacles.append({"id": "fontaine", "rect": rect(42, 96, 48, 102), "h": H1, "haut": 1.0})
    # étals à auvent intégrés aux bords de la place (pas de seconde place de marché)
    for i, r in enumerate([rect(31, 110.6, 35, 112.6), rect(37, 110.6, 41, 112.6), rect(77, 96, 79.5, 99.5), rect(66, 89, 70, 91)]):
        obstacles.append({"id": "etal_%d" % i, "rect": r, "h": H1, "haut": 1.6})
    # B : caravane en travers du passage des faubourgs (chargement en cours, chevaux dételés)
    obstacles.append({"id": "decor_caravane", "rect": rect(-17.5, 92.6, -13.5, 99.4), "h": H1, "haut": 2.6})
    # C : accès au château gardé : deux guérites et deux gardes en faction devant la grille
    obstacles.append({"id": "decor_guerite_o", "rect": rect(66.0, 41.0, 67.6, 42.6), "h": H2, "haut": 3.0})
    obstacles.append({"id": "decor_guerite_e", "rect": rect(72.4, 41.0, 74.0, 42.6), "h": H2, "haut": 3.0})
    obstacles.append({"id": "decor_garde_o", "rect": rect(67.9, 41.6, 68.6, 42.3), "h": H2, "haut": 1.9})
    obstacles.append({"id": "decor_garde_e", "rect": rect(71.4, 41.6, 72.1, 42.3), "h": H2, "haut": 1.9})
    # P7.4.2 : propylée de l'entrée publique (avant-corps devant la porte est) : quatre piles et un mur nord. Arche EST
    # (axe de la porte) et arche SUD (vers l'allée d'approche, face caméra) ; dessin dans scenes/p7/ville_v07a.gd
    for pid, r in PROPYLEE["piles"].items():
        obstacles.append({"id": "porche_pile_" + pid, "rect": r, "h": H1, "haut": 9.5})
    obstacles.append({"id": "porche_mur_n", "rect": PROPYLEE["mur_n"], "h": H1, "haut": 9.5})
    # P7.5 : porte publique à deux battants, en retrait dans le vestibule (0,5 m derrière la face du tambour) : solide ;
    # on entre par interaction (E), qui déclenche le portail existant (fondu, arrivée et orientation inchangés)
    obstacles.append({"id": "porche_porte", "rect": PORTE_BATTANTS, "h": H1, "haut": 7.4})
    obstacles.append({"id": "porche_arche_est", "rect": ARCHE_EST_AVEUGLE, "h": H1, "haut": 9.5})

    portes = [
        {"id": "porte_chateau", "rect": [66.0, 40.0, 74.0, 40.4], "type": "grille", "marque": "fermee", "h": H2,
         "texte_ferme": "Porte du château — fermée. L'accès s'ouvrira plus tard dans l'histoire."},
    ]
    examens = [
        {"id": "ex_porte_sud", "xy": [60.0, 160.0], "portee_m": 2.2, "texte": "Porte sud — sortie de la ville (transition non reliée)."},
        {"id": "ex_guilde", "xy": [50.0, 132.6], "portee_m": 1.8, "texte": "Guilde des Chasseurs (volume provisoire)."},
        {"id": "ex_forge", "xy": [52.0, 88.6], "portee_m": 1.8, "texte": "Forge-armurerie (volume provisoire)."},
        {"id": "ex_chantier", "xy": [88.6, 140.0], "portee_m": 2.0, "texte": "Travaux — la rue vers le quartier est est barrée pour l'instant."},
        {"id": "ex_auberge", "xy": [70.0, 132.6], "portee_m": 1.8, "texte": "Auberge-taverne (volume provisoire)."},
        {"id": "ex_boutique", "xy": [78.0, 88.6], "portee_m": 1.8, "texte": "Boutique de fournitures (volume provisoire)."},
        {"id": "ex_caravane", "xy": [-12.8, 96.0], "portee_m": 2.0, "texte": "Une caravane bloque le passage vers les faubourgs — on décharge. (Futur secteur de missions.)"},
        {"id": "ex_garde_chateau", "xy": [70.0, 43.6], "portee_m": 2.0, "texte": "« Halte. Le quartier du château est fermé au public pour l'instant. »"},
        {"id": "ex_hotel_de_ville", "xy": [82.0, 50.6], "portee_m": 1.8, "texte": "Hôtel de ville (volume provisoire)."},
        {"id": "ex_fontaine", "xy": [45.0, 102.6], "portee_m": 1.8, "texte": "Fontaine (repère provisoire)."},
    ]
    zones = [
        {"id": "placette_voyageurs", "nom": "Placette des Voyageurs", "rect": [48.0, 132.0, 72.0, 150.0]},
        {"id": "grande_place", "nom": "Grande place", "rect": [30.0, 88.0, 86.0, 115.0]},
        {"id": "parvis_colisee", "nom": "Parvis du Colisée", "rect": [-10.0, 56.0, 34.0, 110.0]},
        {"id": "terrasse_haute", "nom": "Terrasse civique", "rect": [56.0, 40.4, 94.0, 71.0]},
        {"id": "passage_faubourgs", "nom": "Passage des Faubourgs", "rect": [-18.0, 92.0, -10.0, 100.0]},
        {"id": "ruelle", "nom": "Ruelle des Tonneliers", "rect": [72.0, 112.0, 90.0, 144.0]},
    ]
    points = {
        "porte_sud": [60.0, 154.0, H0], "guilde": [50.0, 133.2, H0], "pied_volee_a": [59.0, 132.6, H0],
        "palier_1": [62.0, 123.5, HP1], "haut_volee_b": [65.0, 114.0, H1], "place": [50.0, 106.0, H1],
        "colisee": [29.5, 62.0, H1], "pied_volee_c": [63.0, 89.0, H1], "palier_2": [67.0, 79.5, HP2],
        "terrasse": [71.0, 66.0, H2], "chateau": [70.0, 41.6, H2], "ruelle_bas": [82.0, 130.0, H0], "chantier": [88.0, 140.0, H0],
    }
    zones_camera = [   # mode B : orientation propre à 2 secteurs ; 0° ailleurs. « marge » = hystérésis de sortie (m)
        {"id": "revelation_colisee", "rect": [-10.0, 54.0, 72.0, 116.0], "azimut_deg": -16.0, "marge_m": 2.0},
    ]
    return {
        "project": "Val'Serra — Les Larmes d'Aether",
        "stage": "P7.5 — Ville V0.7-B : reconstruction compacte du quartier central (BLOCKOUT CONSOLIDÉ, NON VALIDÉ)",
        "godot_target": "4.7.2",
        "_note": "Généré par tools/p7/build_ville_v07b.py — ne pas éditer à la main.",
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
                # portail « colisee_porte_publique », côté ville : le fond du vestibule. Arrivée dans le Colisée (P7.6) : dans le
                # vestibule de sortie, devant sa porte sud (hors du déclencheur du seuil), tourné vers le nord (l'intérieur)
                {"id": "portail_colisee_public", "portail": "colisee_porte_publique", "rect": [VESTIBULE[0], VESTIBULE[1], VESTIBULE[0] + 1.0, VESTIBULE[3]],
                 "vers": "res://data/p6/colisee.json", "porte": [VESTIBULE[0], VESTIBULE[1], VESTIBULE[0], VESTIBULE[3]],
                 "arrivee": [61.0, 26.8, 0.0], "orientation": [0.0, -1.0]},
            ],
            "p6": {
                "nom": "Val'Serra — quartier central (V0.7-B, blockout)",
                "zone": "ville",
                "sols": {},
                "portes": portes,
                "examens": examens,
                "zones_nommees": zones,
                "camera_vue_dessus": [-60.0, -40.0, W, H],
                "lumieres": [],
                "ville": {
                    "version": "v07b",
                    # prolongements visuels non praticables (dessinés par scenes/p7/ville_v07b.gd)
                    "decor_escaliers": [[104.0, 110.0, 56.0, 12.0, H2, 14.0], [-44.0, -38.0, 60.0, 10.0, H1, 8.0],
                                        [104.0, 109.0, 122.0, 8.0, H0, 3.5]],
                    "decor_arches": [[-40.0, 96.0, 6.0, H1, "x"], [118.0, 140.0, 6.0, H0, "x"], [112.0, 60.0, 7.0, H2, "x"]],
                    "decor_tours": [[-62.0, 70.0, H1, 26.0], [132.0, 96.0, H1, 24.0], [128.0, 30.0, H2, 30.0], [-30.0, 20.0, H1, 32.0]],
                    "batiments": meta_bat,
                    "paysage": paysage(),
                    "masses": masses(),
                    "volees": [list(v) for v in VOLEES],
                    "niveaux": {"bas": H0, "median": H1, "haut": H2},
                    "colisee": {"centre": list(COLISEE["c"]), "rayons": list(COLISEE["r"]), "h": H1, "haut": COLISEE["haut"],
                                "porte": [VESTIBULE[2], 62.0], "vestibule": list(VESTIBULE), "porte_cote": "est", "propylee": PROPYLEE,
                                "porte_battants": PORTE_BATTANTS,
                                # P7.5 : interaction devant la porte -> sortie « portail_colisee_public » (portail colisee_porte_publique)
                                "porte_publique": {"xy": [30.45, 68.2], "portee_m": 2.2, "sortie": "portail_colisee_public",
                                                   "invite": "E  Entrer dans le Colisée"}},
                    "fontaine": rect(42, 96, 48, 102),
                    "chateau": [100.0, -240.0],
                    "porte_sud": [57.0, 63.0, 153.5],
                    "chantier": rect(88.4, 136, 89.4, 144),
                    "points": points,
                    "zones_camera": zones_camera,
                    # retour du Colisée (portail colisee_porte_publique) — P7.6 : sur le perron, DIRECTEMENT devant les grandes
                    # portes (arche sud du propylée), tourné vers la ville (le sud : l'allée, la grande place)
                    "arrivee_colisee": [30.45, 68.9, H1],
                    "orientation_arrivee_colisee": [0.0, 1.0],
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
