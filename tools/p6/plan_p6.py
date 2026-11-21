#!/usr/bin/env python3
"""P6.2 — Plans de level design du Colisée vus du dessus : plan P6/P6.1 (actuel) et plan proposé P6.2, côte à côte.

Lit data/p6/colisee.json (surfaces, murs, portes) et data/p6/pnj_colisee.json ; le plan proposé applique les
modifications de l'étape A (élargissement du passage des vestiaires, secteurs, seuils, axes, mobilier dégagé).
Sortie : docs/media/p6_2/plans_ancien_nouveau.png

Usage : python3 tools/p6/plan_p6.py
"""
import json
import math
import os
from PIL import Image, ImageDraw, ImageFont

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
Z = json.load(open(os.path.join(REPO, "data/p6/colisee.json")))
PNJ = json.load(open(os.path.join(REPO, "data/p6/pnj_colisee.json")))["pnj"]
FONT = os.path.join(REPO, "art/fonts/Inter-SemiBold.otf")
FONT_R = os.path.join(REPO, "art/fonts/Inter-Regular.otf")
S = 15.0                      # px par mètre
OX, OY = 6.0, 6.0             # origine du dessin (m)
W_M, H_M = 66.0, 54.0
BG = (22, 20, 36)
C_ZONE = (64, 66, 108)
C_ZONE_F = (44, 44, 66)
C_MUR = (232, 230, 240)
C_VERT = (90, 205, 110)
C_JAUNE = (245, 205, 80)
C_ROUGE = (225, 70, 70)
C_AXE = (245, 205, 80)
C_TXT = (235, 232, 245)
C_SECT = [(120, 170, 255), (255, 160, 120), (150, 230, 160), (240, 210, 110), (200, 150, 255), (120, 220, 230), (255, 140, 190), (180, 200, 120)]


def f(sz, bold=True):
    return ImageFont.truetype(FONT if bold else FONT_R, sz)


def px(x, y):
    return ((x - OX) * S + 20, (y - OY) * S + 70)


def rect(d, r, **kw):
    a = px(r[0], r[1])
    b = px(r[2], r[3])
    d.rectangle([a, b], **kw)


def fleche(d, a, b, col, w=4, tete=10):
    d.line([a, b], fill=col, width=w)
    ang = math.atan2(b[1] - a[1], b[0] - a[0])
    for s in (-1, 1):
        d.line([b, (b[0] - tete * math.cos(ang + s * 0.45), b[1] - tete * math.sin(ang + s * 0.45))], fill=col, width=w)


def pointilles(d, pts, col, w=4, seg=10, gap=7):
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        L = math.dist(a, b)
        n = int(L / (seg + gap)) + 1
        for k in range(n):
            t0 = k * (seg + gap) / L
            t1 = min(1.0, (k * (seg + gap) + seg) / L)
            if t0 >= 1:
                break
            d.line([(a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0), (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)], fill=col, width=w)


def ellipse(d, c, rx, ry, **kw):
    a = px(c[0] - rx, c[1] - ry)
    b = px(c[0] + rx, c[1] + ry)
    d.ellipse([a, b], **kw)


def plan(nouveau: bool) -> Image.Image:
    im = Image.new("RGB", (int(W_M * S) + 40, int(H_M * S) + 330), BG)
    d = ImageDraw.Draw(im)
    titre = "PLAN PROPOSÉ P6.2 — azimut 0°, secteurs et seuils" if nouveau else "PLAN ACTUEL P6 / P6.1 — azimut 20°"
    d.text((20, 14), titre, fill=C_TXT, font=f(24))
    d.text((20, 44), "Vue du dessus · nord en haut · 1 carreau = 2 m", fill=(170, 170, 200), font=f(14, False))
    for gx in range(0, 70, 2):
        d.line([px(gx, OY), px(gx, OY + H_M)], fill=(30, 28, 46))
    for gy in range(6, 62, 2):
        d.line([px(OX, gy), px(OX + W_M, gy)], fill=(30, 28, 46))
    adj = Z["ajustements"]
    p6 = adj["p6"]
    ar = p6["arene"]
    c = ar["centre"]
    rx, ry = ar["rayons"]
    prof = ar["gradins_prof"]
    # gradins (anneau) et loge
    ellipse(d, c, rx + 0.5 + prof, ry + 0.5 + prof, fill=(52, 50, 80), outline=(110, 110, 150))
    ellipse(d, c, rx + 0.5, ry + 0.5, fill=(150, 150, 170))
    lg = ar["loge"]
    rect(d, [lg["centre"][0] - lg["taille"][0] / 2, lg["centre"][1] - lg["taille"][1] / 2, lg["centre"][0] + lg["taille"][0] / 2, lg["centre"][1] + lg["taille"][1] / 2], fill=(120, 60, 80), outline=C_MUR)
    d.text(px(lg["centre"][0] - 2.4, lg["centre"][1] - 0.6), "Loge", fill=C_TXT, font=f(14))
    # surfaces praticables
    for a in Z["assets"]:
        poly = a["polygon_xy_m"]
        r = [poly[0][0], poly[0][1], poly[2][0], poly[2][1]]
        if nouveau and a["id"] == "passage_vestiaires":
            r = [24.5, 44.5, 27.5, 46.5]
        if a["id"] == "arene":
            continue
        rect(d, r, fill=C_ZONE)
    ellipse(d, c, rx, ry, fill=(176, 150, 104))
    for k, v in p6.get("pieces_fermees", {}).items():
        rect(d, v["rect"], fill=C_ZONE_F)
    # murs
    for o in adj["obstacles"]:
        if not o["id"].startswith("cmur_"):
            continue
        r = o["rect"]
        if nouveau and o["id"].startswith("cmur_passage_vestiaires"):
            r = [r[0] - 0.25, r[1], r[2] - 0.25, r[3]] if r[0] < 26 else [r[0] + 0.25, r[1], r[2] + 0.25, r[3]]
        rect(d, r, fill=C_MUR)
    for o in adj["obstacles"]:
        if o["id"].startswith("meuble_"):
            r = o["rect"]
            rect(d, r, fill=(150, 110, 80))
    # portes
    for p in p6["portes"]:
        col = C_JAUNE if "ouverte_a_partir_de" in p else (C_ROUGE if p.get("marque") == "fermee" else C_VERT)
        r = p["rect"]
        rect(d, [r[0] - 0.15, r[1] - 0.15, r[2] + 0.15, r[3] + 0.15], fill=col)
    for r in ([[24.75, 44.4, 27.25, 44.6], [24.5, 37.4, 27.5, 37.6]] if not nouveau else [[24.5, 44.4, 27.5, 44.6], [24.5, 46.4, 27.5, 46.6], [24.5, 37.4, 27.5, 37.6], [24.5, 31.9, 27.5, 32.1], [37.9, 21.5, 38.1, 24.5], [43.9, 21.5, 44.1, 24.5], [55.9, 21.5, 56.1, 24.5]]):
        rect(d, r, fill=C_VERT)
    # sortie
    s = adj["sorties"][0]["rect"]
    rect(d, s, outline=C_VERT, width=3)
    d.text(px(s[0] - 1.2, s[3] + 0.4), "→ ville", fill=C_VERT, font=f(14))
    # noms des pièces
    noms = [("Vestiaires", 18.0, 53.6), ("Salle d'attente", 20.4, 43.0), ("Arène", 23.5, 18.0), ("Coursive", 45.0, 32.6),
            ("Infirmerie", 44.3, 40.0), ("Réserve", 51.0, 40.0), ("Sortie est", 57.0, 25.2)]
    for n, x, y in noms:
        d.text(px(x, y), n, fill=C_TXT, font=f(15))
    # PNJ
    for n in PNJ:
        if n["zone"] != "colisee":
            continue
        x, y = n["xy"]
        if nouveau and n["id"] == "garde_vestiaires":
            x, y = 28.6, 47.6
        col = (245, 200, 90) if n["id"] == "commandant" else ((200, 200, 220) if n["id"].startswith("garde") else (140, 220, 150))
        a = px(x, y)
        d.ellipse([a[0] - 6, a[1] - 6, a[0] + 6, a[1] + 6], fill=col, outline=(20, 20, 30))
    a = px(26, 20.6)
    d.text((a[0] + 9, a[1] - 9), "Commandant", fill=(245, 200, 90), font=f(13))
    # secteurs (plan proposé)
    if nouveau:
        sect = [("S1", [16, 46.5, 36, 55]), ("S2", [20, 37.5, 32, 46.5]), ("S3", [24.5, 32, 27.5, 37.5]), ("S4", [13.5, 14, 38, 32]),
                ("S5", [38, 21.5, 44, 24.5]), ("S6", [44, 12, 56, 34]), ("S7", [56, 21.5, 65, 24.5]), ("S8", [44, 34, 49.5, 41])]
        for i, (n, r) in enumerate(sect):
            rect(d, r, outline=C_SECT[i], width=2)
            d.text(px(r[0] + 0.2, r[1] + 0.1), n, fill=C_SECT[i], font=f(14))
    # parcours principal et touches
    if nouveau:
        chemin = [(26, 52.0), (26, 23.3), (64.2, 23.3)]
        pointilles(d, [px(*q) for q in chemin], C_AXE, 5)
        for (x, y, k) in [(26.9, 49.5, "↑"), (26.9, 41.5, "↑"), (26.9, 34.8, "↑"), (26.9, 27.5, "↑"), (31.5, 22.0, "→"), (40.5, 22.0, "→"), (49.5, 22.0, "→"), (59.5, 25.6, "→")]:
            a = px(x, y)
            d.rounded_rectangle([a[0], a[1], a[0] + 26, a[1] + 26], 5, fill=(30, 30, 40), outline=C_AXE, width=2)
            d.text((a[0] + 6, a[1] + 1), k, fill=C_AXE, font=f(18))
        d.text(px(20.5, 56.0), "Parcours : ↑ (≈ 29 m), puis → (≈ 38 m) — un seul changement de touche", fill=C_AXE, font=f(15))
    else:
        chemin = [(26, 52.0), (26, 23.3), (64.2, 23.3)]
        pointilles(d, [px(*q) for q in chemin], (200, 160, 70), 4)
        d.text(px(18.0, 56.0), "Avec une touche : dérive de 0,36 m par mètre → contact mural 74 à 93 % du trajet", fill=(230, 150, 120), font=f(15))
    # rose des axes : axes du monde et directions écran des touches
    ox, oy = 20 + 70, int(H_M * S) + 175
    d.text((20, oy - 70), "Axes du monde (N, E) et touches à l'écran", fill=C_TXT, font=f(16))
    fleche(d, (ox, oy), (ox, oy - 55), (200, 200, 220), 3)
    d.text((ox - 6, oy - 78), "N", fill=(200, 200, 220), font=f(15))
    fleche(d, (ox, oy), (ox + 55, oy), (200, 200, 220), 3)
    d.text((ox + 60, oy - 9), "E", fill=(200, 200, 220), font=f(15))
    az = 0.0 if nouveau else math.radians(20)
    up = (math.sin(az), -math.cos(az))
    right = (math.cos(az), math.sin(az))
    fleche(d, (ox, oy), (ox + up[0] * 48, oy + up[1] * 48), C_AXE, 4)
    fleche(d, (ox, oy), (ox + right[0] * 48, oy + right[1] * 48), C_AXE, 4)
    d.text((ox + up[0] * 48 + 8, oy + up[1] * 48 - 22), "↑", fill=C_AXE, font=f(16))
    d.text((ox + right[0] * 48 + 6, oy + right[1] * 48 - 4), "→", fill=C_AXE, font=f(16))
    d.text((ox + 110, oy - 40), ("Azimut 0° : ↑ = nord, → = est. Les couloirs\nsuivent exactement les touches." if nouveau else
                                 "Azimut 20° : ↑ = 20° à l'est du nord, → = 20° au\nsud de l'est. Aucune des 8 directions du clavier\nne suit un couloir (écart 20° ou 25°)."), fill=C_TXT, font=f(14, False))
    # légende
    ly = oy + 40
    items = [(C_VERT, "Passage ouvert / seuil de secteur" if nouveau else "Passage ouvert"), (C_JAUNE, "Passage scénarisé (après le tutoriel)"), (C_ROUGE, "Porte fermée"),
             ((140, 220, 150), "PNJ"), ((200, 200, 220), "Garde"), ((150, 110, 80), "Mobilier")]
    for i, (col, t) in enumerate(items):
        x = 20 + (i % 3) * 330
        y = ly + (i // 3) * 26
        d.rectangle([x, y + 4, x + 16, y + 18], fill=col)
        d.text((x + 24, y + 2), t, fill=C_TXT, font=f(14, False))
    if nouveau:
        d.text((20, ly + 60), "S1–S8 : secteurs de visibilité (une pièce affichée à la fois + ce que montrent ses ouvertures)", fill=(170, 200, 255), font=f(14, False))
    return im


def main():
    a = plan(False)
    b = plan(True)
    out = Image.new("RGB", (a.width + b.width + 20, a.height), (12, 10, 20))
    out.paste(a, (0, 0))
    out.paste(b, (a.width + 20, 0))
    dst = os.path.join(REPO, "docs/media/p6_2")
    os.makedirs(dst, exist_ok=True)
    out.save(os.path.join(dst, "plans_ancien_nouveau.png"))
    print("écrit docs/media/p6_2/plans_ancien_nouveau.png", out.size)


if __name__ == "__main__":
    main()
