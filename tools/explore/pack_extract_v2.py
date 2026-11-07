#!/usr/bin/env python3
"""Découpe du pack d'assets d'exploration (planche du 2026-11-07, fond sombre uni) en sprites RGBA pour le jeu.
    python3 tools/explore/pack_extract_v2.py
Pour chaque boîte de tools/explore/pack_2026-11-07.json : fond estimé sur le bord de la boîte, fond = pixels
proches de cette couleur ET reliés au bord (remplissage : les ombres sombres À L'INTÉRIEUR d'un objet restent),
îlots parasites supprimés, bord adouci, couleur « décontaminée » du fond (pas de liseré bleuté), recadrage serré,
mise à l'échelle éventuelle (Lanczos, en espace prémultiplié). Les accents de sol (decal) gardent une opacité
douce (terre, herbe) car ils sont peints dans le sol. Sortie : art/source/pack_2026-11-07/extraits/<nom>.png + index.json (hors jeu)
(taille, point d'appui = milieu du bas de la partie opaque)."""
import json
import os
from collections import deque
import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SHEET = os.path.join(ROOT, "art/source/pack_2026-11-07/pack_vegetation_props.webp")
SPEC = os.path.join(ROOT, "tools/explore/pack_2026-11-07.json")
OUT = os.path.join(ROOT, "art/source/pack_2026-11-07/extraits")       # hors jeu (.gdignore) ; le constructeur de la carte copie dans art/explore_hd2d/pack/ SEULEMENT les sprites utilisés
os.makedirs(OUT, exist_ok=True)
im = np.asarray(Image.open(SHEET).convert("RGB")).astype(np.float32)
spec = json.load(open(SPEC))
index = {}


def flood_background(near):
    """Pixels « proches du fond » reliés au bord de la boîte."""
    h, w = near.shape
    bg = np.zeros_like(near)
    q = deque()
    for y in range(h):
        for x in (0, w - 1):
            if near[y, x] and not bg[y, x]:
                bg[y, x] = True; q.append((y, x))
    for x in range(w):
        for y in (0, h - 1):
            if near[y, x] and not bg[y, x]:
                bg[y, x] = True; q.append((y, x))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            u, v = y + dy, x + dx
            if 0 <= u < h and 0 <= v < w and near[u, v] and not bg[u, v]:
                bg[u, v] = True; q.append((u, v))
    return bg


def largest_parts(m, min_px):
    lab = np.zeros(m.shape, np.int32); keep = np.zeros(m.shape, bool); n = 0
    for y0, x0 in zip(*np.nonzero(m)):
        if lab[y0, x0]:
            continue
        n += 1; q = deque([(y0, x0)]); lab[y0, x0] = n; pts = []
        while q:
            a, b = q.popleft(); pts.append((a, b))
            for da, db in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                u, v = a + da, b + db
                if 0 <= u < m.shape[0] and 0 <= v < m.shape[1] and m[u, v] and not lab[u, v]:
                    lab[u, v] = n; q.append((u, v))
        if len(pts) >= min_px:
            ys, xs = zip(*pts); keep[list(ys), list(xs)] = True
    return keep


def near_main(m, gap):
    """Ne garde que les morceaux proches du plus gros (fleurs, touffes) : supprime les lettres des légendes."""
    lab = np.zeros(m.shape, np.int32); sizes = [0]; n = 0
    for y0, x0 in zip(*np.nonzero(m)):
        if lab[y0, x0]:
            continue
        n += 1; q = deque([(y0, x0)]); lab[y0, x0] = n; cnt = 0
        while q:
            a, b = q.popleft(); cnt += 1
            for da, db in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                u, v = a + da, b + db
                if 0 <= u < m.shape[0] and 0 <= v < m.shape[1] and m[u, v] and not lab[u, v]:
                    lab[u, v] = n; q.append((u, v))
        sizes.append(cnt)
    if n == 0:
        return m
    main = lab == int(np.argmax(sizes))
    zone = np.asarray(Image.fromarray((main * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(2 * gap + 1))) > 0
    keep_ids = set(np.unique(lab[zone & m])) - {0}
    return np.isin(lab, list(keep_ids))


for name, it in spec.items():
    if name.startswith("_"):
        continue
    x0, y0, x1, y1 = it["boite"]
    c = im[y0:y1, x0:x1]
    border = np.concatenate([c[:2].reshape(-1, 3), c[-2:].reshape(-1, 3), c[:, :2].reshape(-1, 3), c[:, -2:].reshape(-1, 3)])
    bg = np.median(border, axis=0)
    dist = np.sqrt(((c - bg) ** 2).sum(-1))
    if it["type"] == "decal":
        alpha = np.clip((dist - 10.0) / 45.0, 0, 1)
        alpha = np.asarray(Image.fromarray((alpha * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))).astype(np.float32) / 255.0
        alpha[alpha < 0.08] = 0
        alpha *= near_main(alpha > 0.3, 8)
        alpha = np.asarray(Image.fromarray((alpha * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.5))).astype(np.float32) / 255.0
    else:
        near = dist < float(it.get("seuil", 26))
        back = flood_background(near)
        if it.get("trous"):
            back |= largest_parts(near & ~back, 25)        # fond enfermé entre les planches
        fg = largest_parts(~back, 30)
        fg = near_main(fg, 10)
        a = np.asarray(Image.fromarray((fg * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7))).astype(np.float32) / 255.0
        # bord : opacité proportionnelle à l'écart au fond (anticrénelage naturel de la planche)
        edge = np.clip((dist - 8.0) / 30.0, 0, 1)
        alpha = np.where(fg, np.maximum(a, np.minimum(1.0, edge + 0.35)), a * edge)
        alpha = np.clip(alpha, 0, 1)
    # décontamination : la couleur du fond mélangée au bord est retirée
    am = np.maximum(alpha, 1e-3)[..., None]
    col = np.clip((c - (1 - alpha[..., None]) * bg) / am, 0, 255)
    col = np.where(alpha[..., None] > 0.02, col, 0)
    ys, xs = np.nonzero(alpha > 0.06)
    bx0, by0, bx1, by1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    rgba = np.dstack([col, alpha * 255])[by0:by1, bx0:bx1]
    s = float(it.get("echelle", 1.0))
    if abs(s - 1.0) > 1e-3:
        h, w = rgba.shape[:2]
        nw, nh = round(w * s), round(h * s)
        pm = rgba.copy(); pm[..., :3] *= pm[..., 3:4] / 255.0
        pm = np.dstack([np.asarray(Image.fromarray(pm[..., k].astype(np.float32), "F").resize((nw, nh), Image.LANCZOS)) for k in range(4)])
        pm[..., 3] = np.clip(pm[..., 3], 0, 255)
        rgb = np.where(pm[..., 3:4] > 1, pm[..., :3] * 255.0 / np.maximum(pm[..., 3:4], 1), 0)
        rgba = np.dstack([rgb, pm[..., 3]])
    out = np.clip(rgba, 0, 255).astype(np.uint8)
    Image.fromarray(out, "RGBA").save(os.path.join(OUT, name + ".png"))
    opaque = out[..., 3] > 128
    rows = np.nonzero(opaque.any(1))[0]
    bottom = rows.max() + 1
    cols = np.nonzero(opaque[max(0, bottom - 6):bottom].any(0))[0]
    index[name] = {"taille": [out.shape[1], out.shape[0]], "appui": [int(round((cols.min() + cols.max() + 1) / 2)), int(bottom)],
                   "type": it["type"]}
    print("%-20s %4d×%-4d appui %s" % (name, out.shape[1], out.shape[0], index[name]["appui"]))
json.dump(index, open(os.path.join(OUT, "index.json"), "w"), indent=1)
