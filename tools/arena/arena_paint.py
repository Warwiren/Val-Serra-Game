"""Passe « peinture » de l'arène de combat : transforme les plans rendus par arena_blender.py en pixel art HD-2D,
avec le MÊME traitement que l'exploration (tools/explore/paint_pass.py) et une palette COMMUNE :
  1. grille pixel : médiane par bloc SS×SS
  2. étalonnage crépuscule identique (herbe plus verte, ombres bleu-violet, lumières chaudes préservées)
  3. suppression du scintillement, feuillage en grappes peintes, touffes d'herbe et fleurs sur le sol
  4. perspective atmosphérique : plan lointain fondu vers le bleu-violet de la brume, contraste réduit
  5. palette : les couleurs de l'exploration (art/explore_hd2d) + quelques teintes de ciel ; tramage 2×2 léger
  6. contour sombre d'1 px sur la silhouette des plans proches (lisière, premier plan)
Usage : python3 arena_paint.py <dossier_rendu> <dossier_sortie> [SS=3]"""
import glob, json, os, sys
import numpy as np
from PIL import Image

SRC, OUT = sys.argv[1], sys.argv[2]
SS = int(sys.argv[3]) if len(sys.argv) > 3 else 3
EXPLORE = os.path.join(os.path.dirname(__file__), "..", "..", "art", "explore_hd2d")
os.makedirs(OUT, exist_ok=True)
layout = json.load(open(os.path.join(SRC, "layout.json")))
NW, NH = layout["native"]
FOG = np.array([46, 44, 82], np.float32)


def reduce(a):
    b = a[:NH * SS, :NW * SS].reshape(NH, SS, NW, SS, -1).transpose(0, 2, 1, 3, 4).reshape(NH, NW, SS * SS, -1)
    return np.median(b, axis=2)


def load(name):
    im = np.asarray(Image.open(os.path.join(SRC, name + ".png")).convert("RGBA")).astype(np.float32)
    rgb = reduce(im[..., :3])
    alpha = reduce(im[..., 3:4])[..., 0]
    return rgb, alpha


def med3(a):
    st = np.stack([np.roll(np.roll(a, dy, 0), dx, 1) for dy in (-1, 0, 1) for dx in (-1, 0, 1)])
    return np.median(st, axis=0)


def grade(plate, seed, foliage_mask=None, ground_mask=None):
    rng = np.random.default_rng(seed)
    rgb = plate / 255.0
    lum = rgb.mean(-1, keepdims=True)
    warm = (rgb[..., 0] > rgb[..., 2] * 1.3) & (lum[..., 0] > 0.25)
    green = (rgb[..., 1] > rgb[..., 0] * 1.05) & (rgb[..., 1] > rgb[..., 2] * 0.85) & ~warm
    sat = np.where(green[..., None], 1.55, np.where(warm[..., None], 1.25, 1.15))
    rgb = lum + (rgb - lum) * sat
    rgb = np.where(green[..., None], rgb * np.array([0.95, 1.12, 0.95]), rgb)
    shadow = lum[..., 0] < 0.16
    rgb[shadow] = rgb[shadow] * 0.85 + np.array([0.035, 0.03, 0.08])
    rgb = np.clip(rgb ** 0.92, 0, 1) * 255.0
    lumc = rgb.mean(-1)
    spark = (lumc > med3(lumc) + 26) & ~warm
    rgb[spark] = np.stack([med3(rgb[..., k]) for k in range(3)], -1)[spark]
    if foliage_mask is not None:                       # grappes de feuilles : arc éclairé, creux sombre
        lumf = rgb.mean(-1)
        locl = np.stack([np.roll(np.roll(lumf, dy, 0), dx, 1) for dy in (-3, 0, 3) for dx in (-3, 0, 3)]).mean(0)
        LEAF = [np.array(c) for c in ((34, 62, 52), (58, 96, 66), (96, 132, 84), (140, 160, 112))]
        for _ in range(int(foliage_mask.sum() / 12)):
            y, x = rng.integers(3, NH - 4), rng.integers(4, NW - 5)
            if not foliage_mask[y, x]:
                continue
            v = (lumf[y, x] - 40) / 70 + (0.35 if lumf[y, x] > locl[y, x] else -0.15)
            k = int(np.clip(v * 2.2, 0, 3))
            hi, lo = LEAF[k], LEAF[max(0, k - 1)] * 0.7
            w = int(rng.integers(3, 6))
            for dx in range(w):
                yy_ = y - (1 if 0 < dx < w - 1 else 0)
                if foliage_mask[yy_, x + dx]:
                    rgb[yy_, x + dx] = hi
                if foliage_mask[y + 1, x + dx] and rng.random() < 0.7:
                    rgb[y + 1, x + dx] = lo
    if ground_mask is not None:                        # herbe peinte et fleurs, seulement sur le sol vert
        g = ground_mask & green
        for _ in range(int(NW * NH / 16)):
            x, y = rng.integers(1, NW - 1), rng.integers(3, NH)
            if g[y, x] and g[y - 2, x]:
                base = rgb[y, x].copy()
                rgb[y - 2:y, x] = np.clip(base * 1.16 + np.array([2, 8, 0]), 0, 255)
                rgb[y, x] = base * 0.72
        for _ in range(int(NW * NH / 300)):
            fx, fy = rng.integers(3, NW - 3), rng.integers(3, NH - 3)
            if not g[fy, fx]:
                continue
            col = np.array([150, 108, 196]) if rng.random() < 0.8 else np.array([176, 160, 200])
            for _ in range(rng.integers(2, 6)):
                x, y = fx + rng.integers(-3, 4), fy + rng.integers(-2, 3)
                if 0 <= x < NW and 0 <= y < NH and g[y, x]:
                    rgb[y, x] = col * (0.75 + 0.5 * lum[y, x, 0])
    return rgb


# --- palette commune : couleurs réellement employées dans l'exploration + teintes de ciel de l'arène ---------
explore_px = []
for f in sorted(glob.glob(os.path.join(EXPLORE, "*.png"))):
    a = np.asarray(Image.open(f).convert("RGBA")).reshape(-1, 4)
    explore_px.append(a[a[:, 3] > 200][:, :3])
explore_px = np.unique(np.concatenate(explore_px), axis=0).astype(np.float32)

layers = {n: load(n) for n in ("base", "loin", "lisiere", "avant")}
H = np.arange(NH)[:, None] * np.ones((1, NW))
horizon = layout["ligne_combat"][0][1] - 40
painted = {}
for n, (rgb, alpha) in layers.items():
    solid = alpha > 128
    fol = solid if n in ("lisiere", "avant", "loin") else None
    if n == "lisiere":
        fol = solid & (rgb[..., 1] > rgb[..., 0] * 1.02)          # feuillage seulement (pas la palissade ni la maison)
    ground = (H > horizon) if n == "base" else None
    out = grade(rgb, 11 + len(painted), fol, ground)
    if n == "loin":                                                 # perspective atmosphérique
        out = out * 0.55 + FOG * 0.45
    if n == "base":                                                 # ciel : dégradé lisse, légèrement assombri en haut
        sky = H < horizon - 10
        k = np.clip(H / max(1, horizon), 0, 1)[..., None]
        out = np.where(sky[..., None], out * (0.78 + 0.22 * k), out)
    painted[n] = (out, solid)

rng = np.random.default_rng(5)
sky_px = painted["base"][0][H < horizon - 10].reshape(-1, 3)
extra = sky_px[rng.choice(len(sky_px), min(4000, len(sky_px)), replace=False)] if len(sky_px) else np.zeros((0, 3))
# 40 couleurs de l'exploration (déjà quantifiée) + 8 teintes de ciel/brume (k-moyennes)
K2 = 8
c2 = extra[rng.choice(len(extra), K2, replace=False)] if len(extra) >= K2 else np.zeros((0, 3))
for _ in range(15):
    if not len(c2):
        break
    lab = ((extra[:, None] - c2[None]) ** 2).sum(-1).argmin(1)
    for k in range(K2):
        sel = extra[lab == k]
        if len(sel):
            c2[k] = sel.mean(0)
if len(explore_px) > 48:                                            # ramène les contours/variantes à 48 couleurs
    sample = explore_px[rng.choice(len(explore_px), min(20000, len(explore_px)), replace=False)]
    c1 = sample[rng.choice(len(sample), 48, replace=False)]
    for _ in range(15):
        lab = ((sample[:, None] - c1[None]) ** 2).sum(-1).argmin(1)
        for k in range(48):
            sel = sample[lab == k]
            if len(sel):
                c1[k] = sel.mean(0)
else:
    c1 = explore_px
PAL = np.concatenate([c1, c2]).astype(np.float32)
yy, xx = np.mgrid[0:NH, 0:NW]
bayer = (np.array([[0, 2], [3, 1]]) / 4.0 - 0.375)[yy % 2, xx % 2][..., None] * 10.0


def quantize(img):
    q = (img + bayer).reshape(-1, 3)
    ix = np.zeros(len(q), int)
    for i in range(0, len(q), 20000):
        ix[i:i + 20000] = ((q[i:i + 20000, None] - PAL[None]) ** 2).sum(-1).argmin(1)
    return PAL[ix].reshape(NH, NW, 3)


def edge_of(m):
    nb = sum(np.roll(np.roll(m, dy, 0), dx, 1).astype(int) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    return m & (nb < 4)


full = None
for n in ("base", "loin", "lisiere", "avant"):
    out, solid = painted[n]
    if n in ("lisiere", "avant"):                                   # contour avant quantification : reste dans la palette
        e = edge_of(solid)
        out[e] = out[e] * 0.45 + np.array([8, 8, 18]) * 0.55
    q = quantize(out)
    a = np.where(solid, 255, 0) if n != "base" else np.full((NH, NW), 255)
    Image.fromarray(np.dstack([q, a]).astype(np.uint8), "RGBA").save(os.path.join(OUT, "%s.png" % n))
    full = q.copy() if full is None else np.where(solid[..., None], q, full)
Image.fromarray(full.astype(np.uint8)).save(os.path.join(OUT, "apercu.png"))
lay = dict(layout)
lay["palette"] = len(PAL)
json.dump(lay, open(os.path.join(OUT, "arena.json"), "w"), indent=1)
print("arène peinte : %d×%d, palette %d couleurs (%d de l'exploration)" % (NW, NH, len(PAL), len(c1)))
