#!/usr/bin/env python3
"""P4.1 — Aren : réextraction des planches validées à leur résolution réelle.
Les planches « Aren_sprites_exploration.png » et « Aren_sprites_combat.png » (1448 × 1086) sont du pixel-art à
grille d'environ 3 px de planche : Aren debout y mesure ≈ 60 pixels réels. P1/P4 le réduisaient à 29 px
(exploration) et 40 px (combat), puis l'affichaient agrandi (×2,5 filtré, ×3) : perte de détail + flou.
Ici : même découpe (tools/art/aren_sheets.py), mais hauteur debout = 58 px (exploration, spécification du pack
Ilya : « Aren : 58 px ») et 60 px (combat, affiché ×2 au lieu de 40 px × 3 : même taille à l'écran).
Usage : python3 tools/p41/sprites_aren.py <dossier des planches> <sortie>"""
import os, sys
import numpy as np
from PIL import Image

SRC, OUT = sys.argv[1], sys.argv[2]
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "art"))
sys.argv = [sys.argv[0], SRC, OUT]
import aren_sheets as A  # noqa: E402  (fonctions de découpe : sprites_in, cutout, reduce, place)

H_EXPLO, H_COMBAT = 58, 60
SCALE = {"idle_views": 186 / H_EXPLO, "walk": 138 / (H_EXPLO * 0.97), "combat": 90 / (H_COMBAT * 0.92)}
CANVAS = {"explo": (88, 92), "combat": (132, 90)}


def palette(frames, K, seed):
    allpx = np.concatenate([r[a] for r, a in frames.values()])
    rng = np.random.default_rng(seed)
    c = allpx[rng.choice(len(allpx), K, replace=False)].astype(float)
    for _ in range(30):
        lab = ((allpx[:, None] - c[None]) ** 2).sum(-1).argmin(1)
        for k in range(K):
            sel = allpx[lab == k]
            if len(sel):
                c[k] = sel.mean(0)
    return c


def clean(out):
    """Pixels isolés supprimés ; contour extérieur assombri (silhouette nette sur le décor)."""
    a = out[..., 3] > 0
    n = sum(np.roll(np.roll(a, dy, 0), dx, 1) for dy in (-1, 0, 1) for dx in (-1, 0, 1)) - a
    out[a & (n <= 1)] = 0
    a = out[..., 3] > 0
    edge = a & ~(np.roll(a, 1, 0) & np.roll(a, -1, 0) & np.roll(a, 1, 1) & np.roll(a, -1, 1))
    lum = out[..., :3].astype(float).mean(-1)
    light = edge & (lum > 70)
    out[light, :3] = (out[light, :3].astype(float) * 0.55).astype(np.uint8)
    return out


def run():
    os.makedirs(os.path.join(OUT, "explo"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "combat"), exist_ok=True)
    frames = {}
    for sheet, bands in (("Aren_sprites_exploration.png", A.EXPLO), ("Aren_sprites_combat.png", A.COMBAT)):
        img = np.asarray(Image.open(os.path.join(SRC, sheet)).convert("RGB"))
        kind = "explo" if sheet.endswith("exploration.png") else "combat"
        for name, box in bands.items():
            boxes, bg = A.sprites_in(img, box)
            if name in A.EQUAL_CELLS:
                n = A.EQUAL_CELLS[name]; w = (box[2] - box[0]) / n
                boxes = [(int(box[0] + i * w), box[1], int(box[0] + (i + 1) * w), box[3]) for i in range(n)]
            f = SCALE["idle_views"] if name == "idle_views" else (SCALE["walk"] if name.startswith("walk") else SCALE["combat"])
            for i, b in enumerate(boxes):
                a, m = A.cutout(img, b, bg)
                rgb, al = A.reduce(a, m, f)
                frames[(kind, name, i)] = A.place(rgb, al, CANVAS[kind])
    c = palette(frames, 96, 3)
    names = {"idle_views": ["idle_face", "idle_back", "idle_left", "idle_right"]}
    for (kind, name, i), (rgb, al) in frames.items():
        out = np.zeros(rgb.shape[:2] + (4,), np.uint8)
        idx = ((rgb[al][:, None] - c[None]) ** 2).sum(-1).argmin(1)
        out[al, :3] = c[idx].astype(np.uint8); out[al, 3] = 255
        out = clean(out)
        fn = names[name][i] if name in names else f"{name}_{i}"
        Image.fromarray(out, "RGBA").save(os.path.join(OUT, kind, fn + ".png"))
    # 2e image de repos (respiration : haut du corps abaissé d'1 px)
    for k in ("idle_face", "idle_back", "idle_right", "idle_left"):
        a = np.asarray(Image.open(os.path.join(OUT, "explo", k + ".png")).convert("RGBA")).copy()
        ys = np.where(a[..., 3].any(1))[0]
        w = int(ys.min() + (ys.max() - ys.min()) * 0.55)
        b = a.copy(); top = a[:w].copy(); b[:w] = 0
        b[1:w + 1] = np.where(top[..., 3:4] > 0, top, b[1:w + 1])
        Image.fromarray(b, "RGBA").save(os.path.join(OUT, "explo", k + "_1.png"))
    print("Aren :", len(frames), "images")


run()
