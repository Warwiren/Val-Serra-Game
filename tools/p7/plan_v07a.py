#!/usr/bin/env python3
"""P7.4 — Plan simplifié du micro-blockout V0.7-A, tiré des données (data/p7/ville_v07a.json).

Rues praticables (teinte par niveau), volées d'escalier, volumes bâtis avec collision, volumes purement visuels,
accès bloqués (portes, grilles, chantier), garde-corps, Colisée, zones de la caméra semi-fixe B.
Usage : python3 tools/p7/plan_v07a.py [sortie.png] [donnees.json]   (P7.5 : data/p7/ville_v07b.json pour la V0.7-B)
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = sys.argv[2] if len(sys.argv) > 2 else os.path.join(REPO, "data", "p7", "ville_v07a.json")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(REPO, "docs", "media", "p7_4", "plan_v07a.png")
X0, Y0, X1, Y1 = -40.0, 20.0, 145.0, 165.0
K = 8.0                     # px par mètre
MARGE = 330                 # légende à droite


def P(x, y):
    return ((x - X0) * K, (y - Y0) * K)


def R(q):
    a = P(q[0], q[1])
    b = P(q[2], q[3])
    return [min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1])]


def main():
    j = json.load(open(SRC, encoding="utf-8"))
    a = j["ajustements"]
    v = a["p6"]["ville"]
    W = int((X1 - X0) * K) + MARGE
    H = int((Y1 - Y0) * K)
    im = Image.new("RGB", (W, H), (236, 232, 222))
    d = ImageDraw.Draw(im, "RGBA")
    try:
        f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 13)
        fb = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
    except OSError:
        f = fb = ImageFont.load_default()
    # paysage (visuel seul)
    for p in v["paysage"]:
        d.rectangle(R(p["rect"]), fill=(205, 200, 190), outline=(170, 165, 155))
    # Colisée
    cx, cy = v["colisee"]["centre"]
    rx, ry = v["colisee"]["rayons"]
    d.ellipse([*P(cx - rx, cy - ry), *P(cx + rx, cy + ry)], fill=(214, 186, 140), outline=(120, 95, 60), width=2)
    d.text(P(cx - 6, cy - 2), "COLISÉE", fill=(90, 60, 30), font=fb)
    # praticable
    teintes = {0.0: (150, 196, 150), 1.75: (130, 186, 160), 3.5: (120, 176, 196), 5.75: (140, 160, 210), 8.0: (170, 150, 210)}
    for s in j["assets"]:
        if s["category"] == "surface":
            xs = [p[0] for p in s["polygon_xy_m"]]
            ys = [p[1] for p in s["polygon_xy_m"]]
            c = teintes.get(round(s["height_m"], 2), (160, 160, 160))
            d.rectangle(R([min(xs), min(ys), max(xs), max(ys)]), fill=c)
    for s in j["assets"]:
        if s["category"] == "transition":
            q = s["bounds_xy_m"]
            d.rectangle(R(q), fill=(235, 170, 80), outline=(150, 90, 30))
            n = 8
            for i in range(1, n):
                y = q[1] + (q[3] - q[1]) * i / n
                d.line([P(q[0], y), P(q[2], y)], fill=(150, 90, 30))
            xm = (q[0] + q[2]) / 2
            d.line([P(xm, q[3] - 0.6), P(xm, q[1] + 0.6)], fill=(90, 40, 10), width=2)
            d.polygon([P(xm, q[1] + 0.4), P(xm - 0.9, q[1] + 1.8), P(xm + 0.9, q[1] + 1.8)], fill=(90, 40, 10))
    # obstacles (bâtiments à collision, garde-corps, barrières)
    for o in a["obstacles"]:
        oid = o["id"]
        if oid.startswith("colisee_tranche"):
            continue
        if oid.startswith("gc_"):
            d.rectangle(R(o["rect"]), fill=(60, 60, 60))
        elif oid.startswith("barriere"):
            d.rectangle(R(o["rect"]), fill=(220, 40, 40))
        elif oid == "fontaine":
            d.ellipse(R(o["rect"]), fill=(110, 160, 200), outline=(60, 90, 120))
        else:
            meta = v["batiments"].get(oid, {})
            imp = bool(meta.get("libelle"))
            d.rectangle(R(o["rect"]), fill=(120, 116, 110) if not imp else (90, 80, 140), outline=(60, 58, 55))
            if imp:
                r = R(o["rect"])
                d.text((r[0] + 4, r[1] + 4), meta["libelle"], fill=(255, 255, 255), font=f)
    for p in a["p6"]["portes"]:
        d.rectangle(R(p["rect"]), fill=(220, 40, 40))
    # zones de caméra B
    for z in v["zones_camera"]:
        r = R(z["rect"])
        for k in range(0, int(r[2] - r[0]), 14):
            d.line([(r[0] + k, r[1]), (r[0] + k + 7, r[1])], fill=(30, 70, 200), width=3)
            d.line([(r[0] + k, r[3]), (r[0] + k + 7, r[3])], fill=(30, 70, 200), width=3)
        for k in range(0, int(r[3] - r[1]), 14):
            d.line([(r[0], r[1] + k), (r[0], r[1] + k + 7)], fill=(30, 70, 200), width=3)
            d.line([(r[2], r[1] + k), (r[2], r[1] + k + 7)], fill=(30, 70, 200), width=3)
        d.text((r[0] + 6, r[1] + 6), "B : %s (%+.0f°)" % (z["id"], z["azimut_deg"]), fill=(30, 70, 200), font=fb)
    # nord, échelle
    d.text((10, 10), "N ↑  (caméra A regarde le nord)", fill=(0, 0, 0), font=fb)
    d.line([(10, H - 20), (10 + 20 * K, H - 20)], fill=(0, 0, 0), width=3)
    d.text((10, H - 40), "20 m", fill=(0, 0, 0), font=f)
    # légende
    lx = W - MARGE + 14
    items = [((150, 196, 150), "rue praticable, 0 m"), ((130, 186, 160), "palier, 1,75 m"), ((120, 176, 196), "place / parvis, 3,5 m"),
             ((140, 160, 210), "palier, 5,75 m"), ((170, 150, 210), "terrasse haute, 8 m"), ((235, 170, 80), "volée (flèche = montée)"),
             ((120, 116, 110), "bâti à collision"), ((90, 80, 140), "bâtiment-repère"), ((205, 200, 190), "volume visuel seul"),
             ((60, 60, 60), "garde-corps"), ((220, 40, 40), "accès bloqué (porte, grille, chantier)")]
    for i, (c, t) in enumerate(items):
        y = 60 + i * 26
        d.rectangle([lx, y, lx + 18, y + 16], fill=c, outline=(40, 40, 40))
        d.text((lx + 26, y), t, fill=(0, 0, 0), font=f)
    d.text((lx, 60 + len(items) * 26 + 10), "tirets bleus : zones de la\ncaméra semi-fixe B", fill=(30, 70, 200), font=f)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    im.save(OUT)
    print("écrit", os.path.relpath(OUT, REPO))


if __name__ == "__main__":
    main()
