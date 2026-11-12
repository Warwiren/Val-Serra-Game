#!/usr/bin/env python3
"""P4 — plan mesuré de l'avant-poste (vue de dessus) à partir de data/p4/avant_poste.json.
  python3 tools/p4/plan.py   ->  docs/media/p4/plan_avant_poste.png   (1 m = 24 px)"""
import json, os
from PIL import Image, ImageDraw
R = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
j = json.load(open(os.path.join(R, "data", "p4", "avant_poste.json"), encoding="utf-8"))
S, M = 24, 30
W, H = j["world"]["extent_m"]
im = Image.new("RGB", (int(W * S) + 2 * M, int(H * S) + 2 * M + 40), (38, 60, 44))
d = ImageDraw.Draw(im)
def box(r, fill, outline=None, label=None, col=(20, 20, 26)):
    x0, y0, x1, y1 = [M + v * S for v in r]
    d.rectangle([x0, y0, x1, y1], fill=fill, outline=outline)
    if label:
        d.text((x0 + 4, y0 + 3), label, fill=col)
COL = {"cour": (168, 150, 168), "passage": (168, 150, 168), "terrasse": (196, 180, 196), "rive_ouest": (86, 140, 84), "plaine": (86, 140, 84)}
adj = j["ajustements"]
for a in j["assets"]:
    c = a["category"]
    if c == "surface":
        p = a["polygon_xy_m"]
        box([p[0][0], p[0][1], p[2][0], p[2][1]], COL.get(a["id"], (120, 120, 120)), None, "%s  h=%s m" % (a["id"], a["height_m"]))
for a in j["assets"]:
    c = a["category"]
    if c == "water":
        box(a["bounds_xy_m"], (52, 96, 170), None, "rivière h=-0,4", (230, 240, 255))
    elif c == "bank":
        box(a["bounds_xy_m"], (130, 96, 70))
    elif c == "transition":
        box(a["bounds_xy_m"], (226, 214, 190), (60, 50, 40), "escalier")
    elif c == "crossing":
        box(a["bounds_xy_m"], (150, 104, 66), (60, 40, 20), "pont 7 × 2,5 m")
    elif c == "building-placeholder":
        box(a["footprint_xy_m"], (122, 86, 150), (40, 20, 60), "bâtiment principal 7 × 3,6 m", (250, 240, 255))
    elif c == "occluder":
        x, y = a["foot_center_xy_m"]; r = a["foliage_overhang_m"]
        d.ellipse([M + (x - r) * S, M + (y - r) * S, M + (x + r) * S, M + (y + r) * S], outline=(30, 90, 40), width=2)
        rr = a["root_collision_radius_m"]
        d.ellipse([M + (x - rr) * S, M + (y - rr) * S, M + (x + rr) * S, M + (y + rr) * S], fill=(90, 60, 40))
for o in adj["obstacles"]:
    i = o["id"]
    f = (96, 92, 104) if i.startswith(("mur_", "tour_")) else (236, 180, 80) if i.startswith("lant_") else (70, 90, 170) if i.startswith("bann_") else (150, 110, 70)
    box(o["rect"], f, (20, 20, 26))
for b in adj["bordures"]:
    s = b["seg"]
    d.line([M + s[0] * S, M + s[1] * S, M + s[2] * S, M + s[3] * S], fill=(30, 100, 40) if b["type"] == "haie" else (230, 230, 240), width=4)
for t in adj["sorties"]:
    box(t["rect"], (250, 220, 90), (90, 60, 0))
n = adj["pnj"]["xy"]; d.ellipse([M + n[0] * S - 6, M + n[1] * S - 6, M + n[0] * S + 6, M + n[1] * S + 6], fill=(240, 240, 240)); d.text((M + n[0] * S - 44, M + n[1] * S - 20), "garde", fill=(255, 255, 255))
m = adj["p4"]["monstre"]; mx, my = m["xy"]; tr = m["declenchement_m"]
d.ellipse([M + (mx - tr) * S, M + (my - tr) * S, M + (mx + tr) * S, M + (my + tr) * S], outline=(220, 60, 200), width=2); d.text((M + mx * S - 24, M + my * S - 6), "Vorgane", fill=(255, 200, 255))
e = adj["entree"]["xy"]; d.text((M + e[0] * S - 20, M + e[1] * S - 6), "× entrée", fill=(255, 255, 255))
for x in range(0, int(W) + 1, 4):
    d.text((M + x * S - 4, 8), str(x), fill=(220, 220, 220))
for y in range(0, int(H) + 1, 4):
    d.text((6, M + y * S - 6), str(y), fill=(220, 220, 220))
d.text((M, int(H * S) + M + 14), "Avant-poste de la lisière — plan jouable P4 (mètres ; x vers la droite, y vers le bas ; caméra au sud-sud-ouest, plongée 28°, azimut 20°)", fill=(240, 230, 200))
out = os.path.join(R, "docs", "media", "p4", "plan_avant_poste.png")
im.save(out); print(out)
