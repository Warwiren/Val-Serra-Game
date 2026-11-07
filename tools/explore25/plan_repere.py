"""P3 — Schéma du repère monde et plan des niveaux / collisions de la scène témoin, à partir des MÊMES données que le jeu
(gabarits_blockout_v01.json du doc 06 + ajustements_p3_v01.json).
    python3 tools/explore25/plan_repere.py [docs/media/p3_25d/repere_monde.png]"""
import json, math, sys
from PIL import Image, ImageDraw, ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else "docs/media/p3_25d/repere_monde.png"
spec = json.load(open("data/explore25/gabarits_blockout_v01.json"))
adj = json.load(open("data/explore25/ajustements_p3_v01.json"))
S = 30                      # px par mètre (plan)
OX, OY = 60, 70             # marge
W, H = OX * 2 + 32 * S + 470, OY + 24 * S + 60
img = Image.new("RGB", (W, H), (245, 243, 238))
d = ImageDraw.Draw(img, "RGBA")
try:
    F = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 13)
    FB = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
except OSError:
    F = FB = ImageFont.load_default()


def P(x, y):
    return (OX + x * S, OY + y * S)


def rect(x0, y0, x1, y1, fill, outline=None, w=1):
    d.rectangle([P(x0, y0), P(x1, y1)], fill=fill, outline=outline, width=w)


# grille (1 m) et cadre 32 × 24 m
for x in range(33):
    d.line([P(x, 0), P(x, 24)], fill=(0, 0, 0, 40 if x % 4 else 90))
for y in range(25):
    d.line([P(0, y), P(32, y)], fill=(0, 0, 0, 40 if y % 4 else 90))
for x in range(0, 33, 4):
    d.text((P(x, 0)[0] - 6, OY - 18), str(x), font=F, fill=(60, 60, 60))
for y in range(0, 25, 4):
    d.text((OX - 26, P(0, y)[1] - 7), str(y), font=F, fill=(60, 60, 60))
COL = {"sol0": (120, 200, 120, 150), "h1": (240, 160, 60, 170), "ramp": (230, 90, 220, 170), "eau": (70, 130, 210, 200),
       "berge": (150, 120, 90, 160), "pont": (150, 100, 60, 210), "solide": (220, 50, 40, 150)}
for a in spec["assets"]:
    c = a["category"]
    if c == "surface":
        xs = [p[0] for p in a["polygon_xy_m"]]; ys = [p[1] for p in a["polygon_xy_m"]]
        rect(min(xs), min(ys), max(xs), max(ys), COL["h1" if a["height_m"] > 0 else "sol0"], (40, 40, 40), 2)
for r in adj["regions_ajoutees"]:
    q = r["rect"]; rect(q[0], q[1], q[2], q[3], COL["sol0"], (40, 40, 40), 1)
for a in spec["assets"]:
    c = a["category"]
    if c in ("transition", "water", "bank", "crossing"):
        b = a["bounds_xy_m"]
        rect(b[0], b[1], b[2], b[3], COL[{"transition": "ramp", "water": "eau", "bank": "berge", "crossing": "pont"}[c]], (40, 40, 40), 2)
for a in spec["assets"]:
    if a["category"] == "occluder":
        cx, cy = a["foot_center_xy_m"]; rr = a["foliage_overhang_m"]; rt = a["root_collision_radius_m"]
        d.ellipse([P(cx - rr, cy - rr), P(cx + rr, cy + rr)], outline=(30, 120, 40), width=2)
        d.ellipse([P(cx - rt, cy - rt), P(cx + rt, cy + rt)], fill=COL["solide"])
    if a["category"] == "building-placeholder":
        f = a["footprint_xy_m"]; rect(f[0], f[1], f[2], f[3], COL["solide"], (120, 20, 20), 2)
for o in adj["obstacles"]:
    q = o["rect"]; rect(q[0], q[1], q[2], q[3], COL["solide"])
for b in adj["bordures"]:
    s = b["seg"]; d.line([P(s[0], s[1]), P(s[2], s[3])], fill=(40, 90, 40) if b["type"] == "haie" else (110, 100, 95), width=5)
for cp in spec["checkpoints"]:
    x, y = cp["xy_m"]; d.ellipse([P(x - 0.25, y - 0.25), P(x + 0.25, y + 0.25)], fill=(250, 220, 40), outline=(0, 0, 0))
    d.text((P(x, y)[0] + 8, P(x, y)[1] - 18), "%s h=%s" % (cp["id"], str(cp["height_m"]).replace(".", ",")), font=FB, fill=(0, 0, 0))
n = adj["pnj"]; d.text((P(n["xy"][0], n["xy"][1])[0] - 14, P(n["xy"][0], n["xy"][1])[1] + 8), "PNJ", font=F, fill=(0, 0, 0))
# axes du plan
d.line([P(0, 0), P(3, 0)], fill=(200, 30, 30), width=4); d.text(P(3.1, -0.6), "x", font=FB, fill=(200, 30, 30))
d.line([P(0, 0), P(0, 3)], fill=(30, 140, 30), width=4); d.text(P(-0.6, 3.1), "y", font=FB, fill=(30, 140, 30))
# direction de la caméra (vers le spectateur, azimut 20°)
cx, cy = 26.5, 2.5; vx, vy = -math.sin(math.radians(20)), math.cos(math.radians(20))
d.line([P(cx, cy), P(cx + vx * 3, cy + vy * 3)], fill=(30, 30, 160), width=4)
d.polygon([P(cx + vx * 3.4, cy + vy * 3.4), P(cx + vx * 2.8 + vy * 0.35, cy + vy * 2.8 - vx * 0.35), P(cx + vx * 2.8 - vy * 0.35, cy + vy * 2.8 + vx * 0.35)], fill=(30, 30, 160))
d.text(P(cx + 0.3, cy - 0.9), "vers la caméra (azimut 20°)", font=F, fill=(30, 30, 160))
d.text((OX, 12), "Val'Serra P3 — repère monde et plan de la scène témoin (vue du dessus, NON projetée) — 1 carreau = 1 m", font=FB, fill=(0, 0, 0))
# légende et convention
lx = OX + 32 * S + 30
lines = [("Convention (doc 06 §01)", None), ("x → droite, y → bas du plan, h = altitude (m)", None),
         ("Godot 3D : X = x, Y = h, Z = y", None), ("", None),
         ("Projection (A et B, identique) :", None), ("écran.x = (x·cos20 + y·sin20)·20", None),
         ("écran.y = ((−x·sin20 + y·cos20)·sin35", None), ("           − h·cos35)·20   [px natifs]", None),
         ("1 m au sol, de face : 11,5 px", None), ("1 m de hauteur : 16,4 px", None), ("1 m en largeur : 20 px", None), ("", None),
         ("niveau 0 (h = 0)", COL["sol0"]), ("niveau +1 (h = 1,2 m)", COL["h1"]), ("escalier : rampe 0 → 1,2 m", COL["ramp"]),
         ("eau (h = −0,4), non praticable", COL["eau"]), ("berges, non praticables", COL["berge"]), ("pont (tablier h = 0)", COL["pont"]),
         ("solides (collision)", COL["solide"]), ("haies / murets (limites visibles)", (40, 90, 40, 255)), ("", None),
         ("Ajouts P3 (signalés) : bande y = 8..9,", None), ("murets, haies, obstacles, borne,", None), ("portes d'entrée et de sortie.", None)]
y = OY
for t, c in lines:
    if c:
        d.rectangle([lx, y + 2, lx + 18, y + 16], fill=c, outline=(40, 40, 40))
        d.text((lx + 26, y), t, font=F, fill=(0, 0, 0))
    else:
        d.text((lx, y), t, font=FB if t.endswith(":") or t.startswith("Convention") else F, fill=(0, 0, 0))
    y += 22
img.save(OUT)
print("écrit", OUT, img.size)
