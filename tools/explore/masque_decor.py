"""Occlusion des accessoires illustrés par le décor PEINT DANS LE FOND (arbres de bord de clairière, buissons du
bas, lisière…). Ces éléments du fond n'ont pas de sprite à trier : un accessoire illustré posé derrière l'un
d'eux serait dessiné par-dessus. On compare, pixel par pixel, la profondeur du décor du fond (rendu Blender de la
scène, sans les objets : art/source/gabarits/profondeur_terrain_brute.png) à la profondeur de l'accessoire
(sol à son pied + hauteur du pixel au-dessus du pied, caméra orthographique 35°). Là où le fond est plus proche
de la caméra, l'accessoire est masqué. Seules les instances réellement concernées reçoivent une variante :
art/explore_hd2d/hd/occ/<sprite>__<instance>.png, référencée dans decor.json. Les textures communes ne sont
jamais modifiées. Relançable sans effet cumulatif.
    python3 tools/explore/masque_decor.py"""
import json, math, os
import numpy as np
from PIL import Image, ImageDraw

D = "art/explore_hd2d/"
K = 2
DEPTH = np.asarray(Image.open("art/source/gabarits/profondeur_terrain_brute.png").convert("L")).astype(np.float32)
H_, W_ = DEPTH.shape
zone = json.load(open(D + "zone.json"))
spec_path = D + "hd/decor.json"
spec = json.load(open(spec_path))
index = json.load(open(D + "hd/index.json"))
os.makedirs(D + "hd/occ", exist_ok=True)

# Profondeur du SOL (plan) ajustée sur la zone praticable : niveau 8 bits = a*x + b*y + c (pixels écran)
m = Image.new("L", (W_, H_), 0)
ImageDraw.Draw(m).polygon([(p[0] * K, p[1] * K) for p in zone["walkable"]], fill=255)
ys, xs = np.nonzero(np.asarray(m) > 0)
A = np.c_[xs, ys, np.ones_like(xs)].astype(np.float64); v = DEPTH[ys, xs].astype(np.float64)
for _ in range(3):
    plane = np.linalg.lstsq(A, v, rcond=None)[0]; r = v - A @ plane; A, v = A[np.abs(r) < 2.5], v[np.abs(r) < 2.5]
LEVELS_PER_M = 255.0 / 40.0                                  # carte : 22 m -> 255, 62 m -> 0
PX_PER_M_HEIGHT = 2 * 20.0 * math.cos(math.radians(35))     # 1 m de hauteur = 32,8 px écran
RISE = math.sin(math.radians(35)) * LEVELS_PER_M / PX_PER_M_HEIGHT   # rapprochement par pixel de hauteur
MARGIN = 3.0                                                 # ≈ 0,5 m de tolérance (herbes, fleurs du fond)


def ground(x, y):
    return plane[0] * x + plane[1] * y + plane[2]


def occlude(tex, pos, foot_of_column):
    """tex : RGBA ; pos : coin haut gauche à l'écran ; foot_of_column(x) -> (fx, fy) pied du pixel."""
    a = np.asarray(tex).copy()
    hh, ww = a.shape[:2]
    hidden = np.zeros((hh, ww), bool)
    for tx in range(ww):
        sx = pos[0] + tx
        if not 0 <= sx < W_:
            continue
        fx, fy = foot_of_column(sx)
        base = ground(fx, fy)
        for ty in range(hh):
            sy = pos[1] + ty
            if a[ty, tx, 3] < 8 or not 0 <= sy < H_:
                continue
            obj = base + max(0.0, fy - sy) * RISE
            if DEPTH[sy, sx] > obj + MARGIN:
                hidden[ty, tx] = True
    # pas de pixels isolés : on garde les zones masquées d'au moins 4 pixels voisins
    nb = sum(np.roll(np.roll(hidden, dy, 0), dx, 1).astype(int) for dy in (-1, 0, 1) for dx in (-1, 0, 1))
    hidden &= nb >= 4
    a[hidden, 3] = 0
    return Image.fromarray(a), int(hidden.sum()), int((np.asarray(tex)[..., 3] >= 8).sum())


report = []
for name, r in spec["remplace"].items():
    base_sprite = r["sprite"].split("/")[-1].split("__")[0]
    r["sprite"] = base_sprite                                # repart toujours de la texture d'origine
    e = zone["sprites"][name]
    tex = Image.open(D + "hd/%s.png" % base_sprite).convert("RGBA")
    if r.get("sol") == "avant_gauche":
        fl = max(e["footprint"], key=lambda p: p[1]); fr = max(e["footprint"], key=lambda p: p[0])
        slope = (fr[1] - fl[1]) / (fr[0] - fl[0])
        foot = fl
        col = lambda sx, fl=fl, slope=slope: (sx, (fl[1] + slope * (sx / K - fl[0])) * K)
    else:
        foot = (sum(p[0] for p in e["footprint"]) / len(e["footprint"]), e["sort_y"])
        col = lambda sx, foot=foot: (foot[0] * K, foot[1] * K)
    pos = (round(foot[0] * K - r["pivot"][0]), round(foot[1] * K - r["pivot"][1]))
    out, n, tot = occlude(tex, pos, col)
    if n > 0:
        fn = "occ/%s__%s" % (base_sprite, name)
        out.save(D + "hd/%s.png" % fn)
        r["sprite"] = fn
    report.append((name, base_sprite, n, tot))
for i, dcl in enumerate(spec["sol"]):
    nm, x, y = dcl[0], dcl[1], dcl[2]
    tex = Image.open(D + "hd/%s.png" % nm).convert("RGBA")
    ap = index[nm]["appui"]
    pos = (round(x * K - ap[0]), round(y * K - ap[1]))
    out, n, tot = occlude(tex, pos, lambda sx, x=x, y=y: (x * K, y * K))
    spec["sol"][i] = [nm, x, y]
    if n > 0:
        fn = "occ/%s__sol%d" % (nm, i)
        out.save(D + "hd/%s.png" % fn)
        spec["sol"][i].append(fn)
    report.append(("sol %d (%s)" % (i, nm), nm, n, tot))
json.dump(spec, open(spec_path, "w"), indent=1, ensure_ascii=False)
for name, s, n, tot in report:
    if n:
        print("%-24s %-16s masqué par le décor du fond : %4d / %4d px" % (name, s, n, tot))
print("plan du sol : niveau = %.5f x + %.5f y + %.2f ; %d instances masquées sur %d" % (plane[0], plane[1], plane[2], sum(1 for t in report if t[2]), len(report)))
