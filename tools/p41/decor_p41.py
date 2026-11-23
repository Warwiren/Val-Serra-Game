#!/usr/bin/env python3
"""P4.1 — raccords du décor : retire la « plaque de sol » peinte sous les arbres et les accessoires (herbe, fleurs
et cailloux d'une autre teinte que le terrain 3D), et fabrique des touffes d'herbe aux couleurs exactes de SOL-01.
Entrées : art/p4/ (copies des packs Drive, inchangées). Sorties : art/p41/decor/.
Règle : dans la bande basse de l'image, seuls les pixels « racine / pied » reliés au sujet sont gardés ; l'herbe
(teinte verte) et les éléments détachés (fleurs, cailloux posés) sont retirés. Les buissons et fleurs (dont le
vert EST le sujet) ne sont pas traités.
Usage : python3 tools/p41/decor_p41.py"""
import colorsys, os
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
P4 = os.path.join(ROOT, "art", "p4")
OUT = os.path.join(ROOT, "art", "p41", "decor")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(41)

# image -> (part de la hauteur traitée en bas, garder les pixels sombres non verts reliés au sujet)
JOBS = {
    "vegetation/arb02_rond.png": 0.24, "vegetation/arb03_foret.png": 0.24, "vegetation/arb04_jeune.png": 0.18,
    "vegetation/arb05_fleuri.png": 0.22, "arbre/arb01_tronc.png": 0.62,
    "vegetation/roc01_rocher.png": 0.45, "props/lant01_lanterne.png": 0.16, "props/bann02_bleue.png": 0.14,
    "props/pan01_panneau.png": 0.16, "props/tont01_tonneau.png": 0.2, "props/bois02_buches.png": 0.24,
    "props/clot01_cloture.png": 0.28, "props/sac01_sacs.png": 0.18, "props/chart01_chariot.png": 0.14,
    "props/banc01_banc.png": 0.14, "props/cais01_caisse.png": 0.1,
}


def hsv(a):
    f = a[..., :3].astype(float) / 255.0
    mx, mn = f.max(-1), f.min(-1)
    s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    r, g, b = f[..., 0], f[..., 1], f[..., 2]
    d = np.maximum(mx - mn, 1e-6)
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    return h, s, mx


def clean(path, frac):
    im = np.asarray(Image.open(os.path.join(P4, path)).convert("RGBA")).copy()
    al = im[..., 3] > 40
    ys, xs = np.where(al)
    y0, y1 = ys.min(), ys.max()
    band = int(y1 - (y1 - y0) * frac)
    h, s, v = hsv(im)
    green = (h > 55) & (h < 170) & (s > 0.18)
    bright_flower = (s < 0.25) & (v > 0.78) | ((h > 290) | (h < 15)) & (s > 0.35) & (v > 0.6)
    keep = al.copy()
    low = np.zeros_like(al)
    low[band:] = True
    cand = al & ~green & ~bright_flower
    # largeur du « pied » (tronc, poteau, socle) juste au-dessus de la bande ; en dessous, seuls les pixels non
    # verts de cette colonne élargie (racines) sont gardés : la plaque d'herbe, de fleurs et d'ombre disparaît
    rows = cand[max(y0, band - 8):band + 1]
    cols = np.where(rows.any(0))[0]
    if len(cols):
        x0, x1 = np.percentile(cols, 4), np.percentile(cols, 96)
        cx, hw = (x0 + x1) / 2.0, max(3.0, (x1 - x0) / 2.0)
        xx = np.arange(im.shape[1])
        for y in range(band, y1 + 1):
            w = hw * (1.0 + 0.55 * (y - band) / max(1, y1 - band))
            inside = np.abs(xx - cx) <= w
            keep[y] = cand[y] & inside
    lab, n = ndimage.label(keep)
    top_ids = set(np.unique(lab[max(0, band - 2):band + 1][keep[max(0, band - 2):band + 1]])) - {0}
    attached = np.isin(lab, list(top_ids))
    keep[low] = attached[low]
    # pied : les 2 dernières rangées gardées sont adoucies (fondu vers le sol, pas d'arête nette)
    out = im.copy()
    out[~keep, 3] = 0
    ys2 = np.where(out[..., 3].any(1))[0]
    if len(ys2):
        yb = ys2.max()
        for k, f in ((0, 0.45), (1, 0.75)):
            out[yb - k, :, 3] = (out[yb - k, :, 3] * f).astype(np.uint8)
    # petits fragments isolés
    lab2, n2 = ndimage.label(out[..., 3] > 0)
    if n2 > 1:
        sz = ndimage.sum(np.ones_like(lab2), lab2, range(1, n2 + 1))
        small = np.isin(lab2, [i + 1 for i in range(n2) if sz[i] < 30])
        out[small, 3] = 0
    name = os.path.basename(path)
    Image.fromarray(out, "RGBA").save(os.path.join(OUT, name))
    return name, int((al & ~keep).sum())


for p, f in JOBS.items():
    n, removed = clean(p, f)
    print("%-28s %6d px de plaque retirés" % (n, removed))

# touffes d'herbe aux couleurs du terrain : brins tirés de la distribution de couleurs de SOL-01
sol = np.asarray(Image.open(os.path.join(P4, "mat", "sol_herbe.png")).convert("RGB")).reshape(-1, 3).astype(float)
lum = sol.mean(1)
for t in range(4):
    W, H = 96, 56
    img = np.zeros((H, W, 4))
    for _ in range(int(rng.integers(55, 80))):
        x = rng.normal(W / 2, W * (0.2 if t < 2 else 0.28))
        if not (2 < x < W - 3):
            continue
        hgt = rng.uniform(14, H - 6) * (1 - abs(x - W / 2) / (W * 0.7))
        lean = rng.uniform(-0.45, 0.45)
        c = sol[rng.integers(len(sol))]
        c = c * rng.uniform(0.9, 1.25)
        for k in range(int(hgt)):
            yy = H - 2 - k
            xx = int(round(x + lean * k * k / hgt))
            if 0 <= xx < W and 0 <= yy < H:
                sh = 0.55 + 0.45 * k / hgt
                for dx in ((0, 1) if k < hgt * 0.5 else (0,)):
                    if 0 <= xx + dx < W:
                        img[yy, xx + dx, :3] = np.clip(c * sh, 0, 255)
                        img[yy, xx + dx, 3] = 255
    Image.fromarray(img.astype(np.uint8), "RGBA").save(os.path.join(OUT, "touffe_sol_%d.png" % t))
print("touffes : 4")
