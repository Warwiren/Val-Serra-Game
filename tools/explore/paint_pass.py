"""Passe « peinture » de la zone d'exploration : transforme le rendu Blender en décor pixel art HD-2D.
  1. grille pixel : couleur médiane par bloc SS×SS (pas de flou de redimensionnement)
  2. étalonnage crépuscule : herbe plus verte, ombres bleu-violet, lumières chaudes préservées
  3. palette limitée (k-moyennes, 40 couleurs) : aplats picturaux au lieu de dégradés 3D
  4. texture d'herbe peinte (touffes, brins, petites fleurs) sur le sol praticable uniquement, tramage 2×2 léger
  5. contour sombre d'1 px sur la silhouette de chaque élément contournable
  6. découpe : fond (sol + éléments plats) et un sprite par élément (pixels visibles de l'élément), pour le tri
     en profondeur dans Godot ; le fond garde l'élément en place (le sprite le redessine par-dessus les
     personnages qui passent derrière).
Usage : python3 paint_pass.py <dossier_rendu> <dossier_sortie> [SS=3]"""
import json, os, sys
import numpy as np
from PIL import Image

SRC, OUT = sys.argv[1], sys.argv[2]
SS = int(sys.argv[3]) if len(sys.argv) > 3 else 3
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(11)
layout = json.load(open(os.path.join(SRC, "layout.json")))
NW, NH = layout["native"]


def reduce(a):
    H, W = NH, NW
    b = a[:H * SS, :W * SS].reshape(H, SS, W, SS, -1).transpose(0, 2, 1, 3, 4).reshape(H, W, SS * SS, -1)
    return np.median(b, axis=2)


plate = reduce(np.asarray(Image.open(os.path.join(SRC, "plate.png")).convert("RGB")).astype(np.float32))
masks = {}
for g in layout["elements"]:
    m = np.asarray(Image.open(os.path.join(SRC, "mask_%s.png" % g)).convert("RGBA")).astype(np.float32)
    # masque rendu à 1 éch./px à la résolution finale ×SS : alpha moyen par bloc
    masks[g] = reduce(m[..., 3:4])[..., 0] > 100

# --- 2. étalonnage --------------------------------------------------------------------------------------
rgb = plate / 255.0
lum = rgb.mean(-1, keepdims=True)
warm = (rgb[..., 0] > rgb[..., 2] * 1.3) & (lum[..., 0] > 0.25)
green = (rgb[..., 1] > rgb[..., 0] * 1.05) & (rgb[..., 1] > rgb[..., 2] * 0.85) & ~warm
sat = np.where(green[..., None], 1.55, np.where(warm[..., None], 1.25, 1.15))
rgb = lum + (rgb - lum) * sat
rgb = np.where(green[..., None], rgb * np.array([0.95, 1.12, 0.95]), rgb)
shadow = lum[..., 0] < 0.16
rgb[shadow] = rgb[shadow] * 0.85 + np.array([0.035, 0.03, 0.08])          # ombres teintées bleu-violet
rgb = np.clip(rgb ** 0.92, 0, 1) * 255.0

# --- 3b. suppression du scintillement (bruit de rendu : pixels isolés bien plus clairs que leur voisinage) --------
def med3(a):
    st = np.stack([np.roll(np.roll(a, dy, 0), dx, 1) for dy in (-1, 0, 1) for dx in (-1, 0, 1)])
    return np.median(st, axis=0)


lumc = rgb.mean(-1)
spark = (lumc > med3(lumc) + 26) & ~warm
rgb[spark] = np.stack([med3(rgb[..., k]) for k in range(3)], -1)[spark]

# --- 3c. feuillage peint : touffes de feuilles (dessus éclairé, creux sombre) sur arbres, buissons et lisière --
foliage = np.zeros((NH, NW), bool)
for g, m in masks.items():
    if g.startswith("arbre") or g.startswith("buisson"):
        foliage |= m
back = np.array(layout["walkable"])[:, 1].min()               # haut du plateau : au-dessus, la lisière de forêt
foliage |= green & (np.arange(NH)[:, None] < back - 4)
lumf = rgb.mean(-1)
locl = np.stack([np.roll(np.roll(lumf, dy, 0), dx, 1) for dy in (-3, 0, 3) for dx in (-3, 0, 3)]).mean(0)
LEAF = [np.array(c) for c in ((34, 62, 52), (58, 96, 66), (96, 132, 84), (140, 160, 112))]
for _ in range(int(foliage.sum() / 14)):
    y, x = rng.integers(3, NH - 4), rng.integers(4, NW - 5)
    if not foliage[y, x]:
        continue
    # ton de la grappe selon l'éclairage local (le volume 3D sert de guide de valeurs, pas de texture)
    v = (lumf[y, x] - 40) / 70 + (0.35 if lumf[y, x] > locl[y, x] else -0.15)
    k = int(np.clip(v * 2.2, 0, 3))
    hi, lo = LEAF[k], LEAF[max(0, k - 1)] * 0.7
    w = int(rng.integers(3, 6))
    for dx in range(w):                                    # grappe : arc de feuilles éclairé, creux sombre dessous
        yy_ = y - (1 if 0 < dx < w - 1 else 0)
        if foliage[yy_, x + dx]:
            rgb[yy_, x + dx] = hi
        if foliage[y + 1, x + dx] and rng.random() < 0.7:
            rgb[y + 1, x + dx] = lo

# --- 4. herbe peinte (avant la palette, pour qu'elle en fasse partie) -----------------------------------
any_el = np.zeros((NH, NW), bool)
for g, m in masks.items():
    any_el |= m
ground = green & ~any_el
yy, xx = np.mgrid[0:NH, 0:NW]
for _ in range(int(NW * NH / 22)):                                          # touffes : brins clairs + pied sombre
    x, y = rng.integers(1, NW - 1), rng.integers(3, NH)
    if ground[y, x] and ground[y - 2, x]:
        base = rgb[y, x].copy()
        rgb[y - 2:y, x] = np.clip(base * 1.16 + np.array([2, 8, 0]), 0, 255)
        rgb[y, x] = base * 0.72
for _ in range(int(NW * NH / 380)):                                         # fleurs violettes / blanches en petits groupes
    fx, fy = rng.integers(3, NW - 3), rng.integers(3, NH - 3)
    if not ground[fy, fx]:
        continue
    col = np.array([150, 108, 196]) if rng.random() < 0.8 else np.array([176, 160, 200])
    for _ in range(rng.integers(2, 6)):
        x, y = fx + rng.integers(-3, 4), fy + rng.integers(-2, 3)
        if 0 <= x < NW and 0 <= y < NH and ground[y, x]:
            rgb[y, x] = col * (0.75 + 0.5 * lum[y, x, 0])

# --- 3. palette -----------------------------------------------------------------------------------------
px = rgb.reshape(-1, 3)
K = 40
c = px[rng.choice(len(px), K, replace=False)]
sample = px[rng.choice(len(px), min(60000, len(px)), replace=False)]
for _ in range(20):
    lab = ((sample[:, None] - c[None]) ** 2).sum(-1).argmin(1)
    for k in range(K):
        sel = sample[lab == k]
        if len(sel):
            c[k] = sel.mean(0)
# quantification avec tramage 2×2 léger (seuil décalé) : transitions de valeurs « peintes »
bayer = (np.array([[0, 2], [3, 1]]) / 4.0 - 0.375)[yy % 2, xx % 2][..., None] * 10.0
q = rgb + bayer
idx = np.zeros(NH * NW, int)
flat = q.reshape(-1, 3)
for i in range(0, len(flat), 20000):
    idx[i:i + 20000] = ((flat[i:i + 20000, None] - c[None]) ** 2).sum(-1).argmin(1)
out = c[idx].reshape(NH, NW, 3)

# --- 5. contours des éléments ---------------------------------------------------------------------------
def edge_of(m):
    nb = sum(np.roll(np.roll(m, dy, 0), dx, 1).astype(int) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    return m & (nb < 4)


for g, m in masks.items():
    if g == "muret":
        continue
    e = edge_of(m)
    out[e] = out[e] * 0.45 + np.array([8, 8, 18]) * 0.55

# --- 6. découpe ------------------------------------------------------------------------------------------
img = np.dstack([out, np.full((NH, NW), 255.0)]).astype(np.uint8)
Image.fromarray(img, "RGBA").save(os.path.join(OUT, "fond.png"))
sprites = {}
for g, m in masks.items():
    if not m.any():
        continue
    ys, xs = np.where(m)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    sp = np.zeros((y1 - y0, x1 - x0, 4), np.uint8)
    sub = m[y0:y1, x0:x1]
    sp[sub] = img[y0:y1, x0:x1][sub]
    Image.fromarray(sp, "RGBA").save(os.path.join(OUT, "el_%s.png" % g))
    el = layout["elements"][g]
    sprites[g] = {"pos": [int(x0), int(y0)], "sort_y": el["sort_y"], "footprint": el["footprint"], "solid": el["solid"]}
layout["sprites"] = sprites
json.dump(layout, open(os.path.join(OUT, "zone.json"), "w"), indent=1)
print("fond", NW, "x", NH, "| sprites :", len(sprites))
