#!/usr/bin/env python3
"""P4.1 — Ilya : sprites d'exploration, de combat et portraits extraits des deux planches canoniques
(Drive Art/Ilya : Ilya-1.png et Ilya-2.png — cheveux courts argentés, yeux verts, manteau bleu nuit et cuir).
Les planches sont en 1121 × 744 : les sprites y sont petits (≈ 45 px d'exploration, ≈ 58 px de combat) et
légèrement flous (planche rééchantillonnée). On les ramène sur leur grille réelle (≈ 1,15 px de planche par
pixel) sans les agrandir : c'est la meilleure netteté que ces sources permettent (voir docs/P4_1_FINITIONS.md).
  - exploration : Ilya-1, 4 directions × 4 images de marche (+ repos) ;
  - combat : Ilya-2 (attente, préparation, tir, fin) + Ilya-1 (dégâts) ;
  - portraits : Ilya-1, 6 expressions.
Usage : python3 tools/p41/sprites_ilya.py <dossier des planches> <sortie>"""
import os, sys
import numpy as np
from scipy import ndimage
from PIL import Image

SRC, OUT = sys.argv[1], sys.argv[2]
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "art"))
sys.argv = [sys.argv[0], SRC, OUT]
import aren_sheets as A  # noqa: E402

F = 1.15
WALK = {"face": (60, 117), "back": (115, 168), "left": (167, 219), "right": (217, 273)}
WALK_X = (466, 666)
COMBAT2 = {"idle": (470, 272, 553, 352), "prep": (553, 272, 640, 352), "strike": (640, 272, 735, 352), "follow": (735, 272, 812, 352)}
COMBAT1 = {}   # Ilya-1 dessine le combat plus petit (≈ 45 px) : non mélangé aux poses d'Ilya-2
PORTRAITS = {"neutre": (852, 68, 931, 157), "determine": (941, 68, 1019, 157), "sereine": (1029, 68, 1107, 157),
             "surpris": (852, 185, 931, 274), "inquiete": (941, 185, 1019, 274), "resolue": (1029, 185, 1107, 274)}
CANVAS_E, CANVAS_C = (72, 66), (132, 90)


def grab(img, box, f):
    _, bg = A.sprites_in(img, (box[0], box[1], box[2], box[3]), min_h=10)
    a, m = A.cutout(img, box, bg)
    rgb, al = A.reduce(a, m, f)
    # filets et étiquettes de la planche : seules les parties proches de la plus grande masse sont gardées
    lab, n = ndimage.label(al, structure=np.ones((3, 3)))
    if n > 1:
        sz = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
        big = ndimage.binary_dilation(lab == (int(np.argmax(sz)) + 1), iterations=3)
        keep = [i + 1 for i in range(n) if sz[i] >= 0.25 * sz.max() or (big & (lab == i + 1)).any()]
        al &= np.isin(lab, keep)
    return rgb, al


def finish(rgb, al, canvas, pal):
    rgb, al = A.place(rgb, al, canvas)
    out = np.zeros(rgb.shape[:2] + (4,), np.uint8)
    idx = ((rgb[al][:, None] - pal[None]) ** 2).sum(-1).argmin(1)
    out[al, :3] = pal[idx].astype(np.uint8); out[al, 3] = 255
    # ombre portée de la planche (rangées du bas, très sombres, plus larges que les pieds) : retirée
    ys = np.where(out[..., 3].any(1))[0]
    for y in range(ys.max() - 2, ys.max() + 1):
        dark = (out[y, :, 3] > 0) & (out[y, :, :3].astype(int).sum(-1) < 95)
        out[y, dark] = 0
    a = out[..., 3] > 0
    n = sum(np.roll(np.roll(a, dy, 0), dx, 1) for dy in (-1, 0, 1) for dx in (-1, 0, 1)) - a
    out[a & (n <= 1)] = 0
    return out


def palette(px, K=64, seed=5):
    rng = np.random.default_rng(seed)
    c = px[rng.choice(len(px), K, replace=False)].astype(float)
    for _ in range(30):
        lab = ((px[:, None] - c[None]) ** 2).sum(-1).argmin(1)
        for k in range(K):
            s = px[lab == k]
            if len(s):
                c[k] = s.mean(0)
    return c


def run():
    os.makedirs(os.path.join(OUT, "explo"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "combat"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "portraits"), exist_ok=True)
    i1 = np.asarray(Image.open(os.path.join(SRC, "Ilya-1.png")).convert("RGB"))
    i2 = np.asarray(Image.open(os.path.join(SRC, "Ilya-2.png")).convert("RGB"))
    ex, cb = {}, {}
    w = (WALK_X[1] - WALK_X[0]) / 4
    for d, (y0, y1) in WALK.items():
        for i in range(4):
            ex["walk_%s_%d" % (d, i)] = grab(i1, (int(WALK_X[0] + i * w), y0, int(WALK_X[0] + (i + 1) * w), y1), F)
    for k, b in COMBAT2.items():
        cb[k] = grab(i2, b, F)
    for k, b in COMBAT1.items():
        cb[k] = grab(i1, b, F)
    pal = palette(np.concatenate([r[a] for r, a in list(ex.values()) + list(cb.values())]))
    for k, (r, a) in ex.items():
        Image.fromarray(finish(r, a, CANVAS_E, pal), "RGBA").save(os.path.join(OUT, "explo", k + ".png"))
    # repos des trois autres vues : l'image de marche la plus étroite (pieds joints)
    for d in ("face", "back", "left", "right"):
        best = min(range(4), key=lambda i: ex["walk_%s_%d" % (d, i)][1].any(0).sum())
        Image.open(os.path.join(OUT, "explo", "walk_%s_%d.png" % (d, best))).save(os.path.join(OUT, "explo", "idle_%s.png" % d))
    for k, (r, a) in cb.items():
        Image.fromarray(finish(r, a, CANVAS_C, pal), "RGBA").save(os.path.join(OUT, "combat", "ilya_%s.png" % k))
    # poses manquantes de la planche : garde = préparation ; frappe d'Aether = tir
    for dst, src in (("guard", "prep"), ("hurt", "idle"), ("aether_prep", "prep"), ("aether_strike", "strike")):
        Image.open(os.path.join(OUT, "combat", "ilya_%s.png" % src)).save(os.path.join(OUT, "combat", "ilya_%s.png" % dst))
    # 2e image de repos (respiration : haut du corps abaissé d'1 px), comme Aren
    for d, k in ((os.path.join(OUT, "combat"), "ilya_idle"),) + tuple((os.path.join(OUT, "explo"), "idle_" + v) for v in ("face", "back", "left", "right")):
        a = np.asarray(Image.open(os.path.join(d, k + ".png")).convert("RGBA")).copy()
        ys = np.where(a[..., 3].any(1))[0]
        w = int(ys.min() + (ys.max() - ys.min()) * 0.55)
        b = a.copy(); top = a[:w].copy(); b[:w] = 0
        b[1:w + 1] = np.where(top[..., 3:4] > 0, top, b[1:w + 1])
        Image.fromarray(b, "RGBA").save(os.path.join(d, k + "_1.png"))
    for k, (x0, y0, x1, y1) in PORTRAITS.items():
        p = Image.fromarray(i1[y0:y1, x0:x1]).resize((128, int(128 * (y1 - y0) / (x1 - x0))), Image.LANCZOS)
        p.save(os.path.join(OUT, "portraits", "portrait_%s.png" % k))
    print("Ilya : %d exploration, %d combat, %d portraits" % (len(ex), len(cb), len(PORTRAITS)))


run()
