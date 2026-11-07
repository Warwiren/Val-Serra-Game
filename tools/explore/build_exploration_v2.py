#!/usr/bin/env python3
"""EXPLORATION v2 — carte d'exploration HD-2D de la lisière (version par défaut, F5).

Reprend la carte agrandie (1408×800 px natifs, praticable et projection 35°/20° inchangés) et l'enrichit avec le pack
d'assets du 2026-11-07 (art/explore_hd2d/pack/, découpé par tools/explore/pack_extract_v2.py) :
  * sol : avant-poste peint d'origine conservé ; herbe recomposée SANS taches d'ombre recopiées (retouche par une
    seconde synthèse), variation lente de teinte, eau profonde fondue (plus de damier), raccords du muret adoucis,
    chemins pavés en COURBES continues (plus d'angles), sentiers de terre, accents de sol semés (herbes, fleurs, terre
    nue, cailloux), bordures de chemin, ombres de contact sous chaque élément ;
  * éléments : arbres, buissons, fleurs, rochers et accessoires variés du pack ; deux maisons qui ne sont plus des
    copies (une retournée, toits recolorés) ; rive dressée de rochers ; lisière de forêt bordée d'arbres.
Chaque élément a une emprise au sol (collision si solide), une ligne de tri et la transparence locale du jeu.
Sorties : art/explore_hd2d/v2/{sol.webp, zone.json, decor.json, maison_ardoise.png, maison_tuiles.png}.
Reproductible (graine fixe) :  python3 tools/explore/build_exploration_v2.py
"""
import colorsys
import json
import math
import os
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "art/explore_hd2d")
OUT = os.path.join(SRC, "v2")
PACK = os.path.join(ROOT, "art/source/pack_2026-11-07/extraits")   # découpe complète (hors jeu)
PACK_JEU = os.path.join(SRC, "pack")                                 # sprites réellement utilisés par la carte
RES_V2 = "res://art/explore_hd2d/v2/"
RES_PACK = "res://art/explore_hd2d/pack/"
NAT = (1408, 800)
W, H = NAT[0] * 2, NAT[1] * 2
OFF = np.array([0.0, 400.0])                     # avant-poste d'origine dans la grande carte (natif)
SLOPE = (248.8 - 370.4) / (691.5 - 108.9)
rng = np.random.default_rng(11)

zone = json.load(open(os.path.join(SRC, "zone.json")))
decor = json.load(open(os.path.join(SRC, "illustre/decor.json")))
pack_index = json.load(open(os.path.join(PACK, "index.json")))
plate = np.asarray(Image.open(os.path.join(SRC, "illustre/sol/sol.png")).convert("RGB")).astype(np.float32)
PH, PW = plate.shape[:2]
os.makedirs(OUT, exist_ok=True)


def poly_mask(points, size, scale=2.0, offset=(0, 0)):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).polygon([((x + offset[0]) * scale, (y + offset[1]) * scale) for x, y in points], fill=255)
    return np.asarray(m).astype(np.float32) / 255.0


def soften(mask, radius):
    return np.asarray(Image.fromarray((np.clip(mask, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(radius))).astype(np.float32) / 255.0


# ------------------------------------------------------------------------------------- géométrie (identique à P1)
F0 = np.array([108.9, 370.4]) + OFF
U = np.array([582.6, -121.6])
V = np.array([-128.6, -202.7])
F1, B1, B0 = F0 + U * 2.2, F0 + U * 2.2 + V * 2.1, F0 + V * 2.1


def clip_left(a, b, x):
    t = (x - a[0]) / (b[0] - a[0])
    return a + (b - a) * t


WALK = [F0, F1, B1, clip_left(B0, B1, 14.0), clip_left(F0, B0, 14.0)]


def front_y(x):
    return F0[1] + (x - F0[0]) * SLOPE


def back_y(x):
    return B0[1] + (x - B0[0]) * SLOPE


# ------------------------------------------------------------------------------------- synthèse par patchs
def synth(src, allowed, size, patch=160, step=104, power=4.0, norm=None):
    h, w = size
    ok = np.argwhere(allowed[: src.shape[0] - patch, : src.shape[1] - patch])
    win1 = np.sin(np.linspace(0, math.pi, patch)) ** power + 1e-4
    win = np.outer(win1, win1)[..., None]
    acc = np.zeros((h + 2 * patch, w + 2 * patch, 3), np.float32)
    wsum = np.zeros((h + 2 * patch, w + 2 * patch, 1), np.float32)
    for y0 in range(-patch // 2, h, step):
        for x0 in range(-patch // 2, w, step):
            y = max(int(y0 + rng.integers(-step // 4, step // 4 + 1)), -patch // 2)
            x = max(int(x0 + rng.integers(-step // 4, step // 4 + 1)), -patch // 2)
            sy, sx = ok[rng.integers(len(ok))]
            p = src[sy:sy + patch, sx:sx + patch]
            if norm is not None:
                p = p - p.reshape(-1, 3).mean(0) + norm
            if rng.random() < 0.5:
                p = p[:, ::-1]
            yy, xx = y + patch // 2, x + patch // 2
            acc[yy:yy + patch, xx:xx + patch] += p * win
            wsum[yy:yy + patch, xx:xx + patch] += win
    out = acc / np.maximum(wsum, 1e-6)
    return out[patch // 2:patch // 2 + h, patch // 2:patch // 2 + w]


def allowed_for(region_mask, bad, patch, keep=1.0):
    def box(a):
        c = np.pad(np.cumsum(np.cumsum(a.astype(np.int32), 0), 1), ((1, 0), (1, 0)))
        return c[patch:, patch:] - c[:-patch, patch:] - c[patch:, :-patch] + c[:-patch, :-patch]
    inside = box(region_mask > 0.99) >= patch * patch
    nbad = box(bad)
    lim = np.quantile(nbad[inside], keep) if keep < 1.0 else np.inf
    res = np.zeros(region_mask.shape, bool)
    res[: inside.shape[0], : inside.shape[1]] = inside & (nbad <= lim)
    return res


def luma_of(a):
    return 0.3 * a[..., 0] + 0.59 * a[..., 1] + 0.11 * a[..., 2]


r, g, b = plate[..., 0], plate[..., 1], plate[..., 2]
luma = luma_of(plate)
walk0 = poly_mask([(p[0], p[1]) for p in zone["walkable"]], (PW, PH))
inner0 = soften(walk0, 1) * (np.asarray(Image.fromarray((walk0 * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(41))) > 0)
_pm = Image.new("L", (PW, PH), 0)
ImageDraw.Draw(_pm).line([(330, 712), (480, 598), (700, 392), (830, 358), (1235, 286), (1340, 262)], fill=255, width=70)
path_px = np.asarray(_pm) > 0
_pc = Image.new("L", (PW, PH), 0)
ImageDraw.Draw(_pc).line([(498, 598), (705, 400)], fill=255, width=26)
ImageDraw.Draw(_pc).line([(905, 359), (1235, 291)], fill=255, width=36)
path_core = np.asarray(_pc) > 0
dark_px = np.asarray(Image.fromarray(((luma < 16) * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(11))) > 0
house_zone = np.zeros_like(path_px)
house_zone[150:400, 600:1000] = True
rocks = np.zeros_like(path_px)
rocks[600:, :] = True
grass_bad = path_px | dark_px | house_zone | rocks

GP = 128
_gok = allowed_for(inner0, grass_bad, GP, keep=0.15)
_gmean = plate[inner0 > 0.99][~grass_bad[inner0 > 0.99]].mean(0)


def blob_mask(img):
    """Taches sombres recopiées (ombres portées d'objets absents) : nettement plus sombres que leur voisinage."""
    l = luma_of(img)
    loc = np.asarray(Image.fromarray(np.clip(l, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(26))).astype(np.float32)
    m = ((l < 0.62 * loc) & (l < 30)).astype(np.uint8) * 255
    m = Image.fromarray(m).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(17))
    return soften(np.asarray(m) / 255.0, 4)


grass = synth(plate, _gok, (H, W), patch=GP, step=84, norm=_gmean)
for _ in range(2):                                # retouche : les taches sont remplacées par une autre synthèse
    alt = synth(plate, _gok, (H, W), patch=GP, step=84, norm=_gmean)
    m = blob_mask(grass) * (1 - blob_mask(alt))
    grass = grass * (1 - m[..., None]) + alt * m[..., None]
# variation lente (clairières plus claires, zones plus fraîches) : casse l'uniformité de la synthèse
noise = rng.normal(size=(H // 160 + 2, W // 160 + 2)).astype(np.float32)
low = np.asarray(Image.fromarray(noise, "F").resize((W, H), Image.BICUBIC))
low = (low - low.mean()) / (low.std() + 1e-6)
grass *= (1.0 + 0.06 * low)[..., None]
grass[..., 0] *= (1.0 + 0.025 * low)

forest_reg = np.zeros((PH, PW), np.float32)
forest_reg[0:250, 0:330] = 1.0
forest = synth(plate, allowed_for(forest_reg, np.zeros_like(path_px), 128), (H, W), patch=128, step=84, power=2.5)

water_reg = np.zeros((PH, PW), np.float32)
water_reg[650:800, 1240:1408] = 1.0
_wmean = plate[650:800, 1240:1408].reshape(-1, 3).mean(0)
water = synth(plate, allowed_for(water_reg, np.zeros_like(path_px), 96), (H, W), patch=96, step=40, power=1.2, norm=_wmean)
water = water * 0.55 + np.asarray(Image.fromarray(np.clip(water, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(5))).astype(np.float32) * 0.45
# reflets : quelques traits clairs horizontaux, courts et irréguliers (eau calme du soir), pas de motif régulier
glint = Image.new("L", (W, H), 0)
gd = ImageDraw.Draw(glint)
for _ in range(900):
    gx, gy = rng.uniform(0, W), rng.uniform(0, H)
    gd.line([(gx, gy), (gx + rng.uniform(8, 34), gy)], fill=int(rng.uniform(40, 110)), width=1)
glint = np.asarray(glint.filter(ImageFilter.GaussianBlur(0.8))).astype(np.float32)[..., None] / 255.0
water = water * (1 - glint * 0.5) + np.array([90, 110, 140], np.float32) * glint * 0.5

# ------------------------------------------------------------------------------------- composition
canvas = grass.copy()
walk_big = poly_mask([tuple(p) for p in WALK], (W, H))
grassy = soften(np.asarray(Image.fromarray((walk_big * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(49))) / 255.0, 22)
ys = np.arange(H)[:, None] / 2.0
xs = np.arange(W)[None, :] / 2.0
below_front = ys > front_y(xs) - 4
fa = np.where(below_front, 0.0, 1.0 - grassy)[..., None]
canvas = canvas * (1 - fa) + forest * fa

# muret + eau : bande recopiée le long de sa pente. DEUX recopies complètes à décalages aléatoires différents, puis
# fondu entre elles selon un bruit lent en x : chaque colonne est toujours couverte (pas de raccord visible).
def make_band():
    cuts = []
    band = np.zeros((H, W, 3), np.float32)
    band_a = np.zeros((H, W), np.float32)
    x = 0
    while x < W:
        src_x0 = int(rng.integers(560, 760))
        run = min(int(rng.integers(420, 640)), W - x)
        for k in range(run):
            cx, scx = x + k, src_x0 + k
            line_src = 2 * (front_y(scx / 2.0) - OFF[1])
            shift = int(round(2 * front_y(cx / 2.0) - line_src))
            sy0 = max(int(line_src) - 30, 0, -shift)
            sy1 = min(PH, H - shift)
            if sy1 > sy0:
                band[sy0 + shift:sy1 + shift, cx] = plate[sy0:sy1, scx]
                band_a[sy0 + shift:sy1 + shift, cx] = 1.0
            last = PH - 1 + shift
            if last + 1 < H:
                band[last + 1:, cx] = water[last + 1:, cx]
                band_a[last + 1:, cx] = 1.0
        x += run
        cuts.append(x)
    return band, band_a, cuts


band_a1 = make_band()
band_b1 = make_band()
# poids de chaque recopie = distance à ses propres raccords : à un raccord de A, on ne voit que B (et inversement)
def away(cuts):
    xs_ = np.arange(W, dtype=np.float32)
    d = np.full(W, 1e9, np.float32)
    for c in [0] + cuts[:-1]:
        d = np.minimum(d, np.abs(xs_ - c))
    return np.clip(d / 90.0, 0.0, 1.0) + 1e-3


wa, wb = away(band_a1[2]), away(band_b1[2])
tmix = (wb / (wa + wb))[None, :, None]
band = band_a1[0] * (1 - tmix) + band_b1[0] * tmix
band_a = np.minimum(band_a1[1], band_b1[1])
# l'eau profonde remplace aussi le bas de la bande recopiée (fondu vertical) : plus de ligne de raccord
deep = np.clip((ys - (front_y(xs) + 42)) / 30.0, 0, 1)
band = band * (1 - deep[..., None]) + water * deep[..., None]
# ombre portée du talus sur l'eau : bande sombre juste sous le muret (lecture nette de la limite)
bank = np.clip(1 - np.abs(ys - (front_y(xs) + 46)) / 16.0, 0, 1)
band *= (1 - 0.35 * bank)[..., None]
top_soft = np.clip((ys - (front_y(xs) - 13)) / 8.0, 0, 1)
ba = (band_a * top_soft)[..., None]
band_blur = band * ba + canvas * (1 - ba)
canvas = band_blur

keep = poly_mask([(p[0], p[1]) for p in zone["walkable"]], (PW, PH))
keep = np.asarray(Image.fromarray((keep * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(25))) / 255.0
yy0 = np.arange(PH)[:, None] / 2.0
xx0 = np.arange(PW)[None, :] / 2.0
keep = np.maximum(keep, (yy0 > (front_y(xx0) - OFF[1]) - 14).astype(np.float32))
canopy = poly_mask([(-10, 100), (170, 100), (175, 150), (120, 205), (40, 215), (-10, 215)], (PW, PH))
keep = keep * (1 - canopy)
# bord droit de l'avant-poste peint, côté eau : fondu large (l'eau d'origine est plus sombre que l'eau recomposée)
ramp = np.clip((PW - 8 - np.arange(PW)[None, :]) / 220.0, 0, 1)
water_rows = yy0 > (front_y(xx0) - OFF[1]) + 30
keep = np.where(water_rows, keep * ramp, keep)
keep = soften(keep, 14)[..., None]
oy = int(OFF[1] * 2)
canvas[oy:oy + PH, 0:PW] = canvas[oy:oy + PH, 0:PW] * (1 - keep) + plate * keep


# ------------------------------------------------------------------------------------- chemins (courbes continues)
_pathness = soften((((r > g * 0.95) & (luma > 50)) | path_core).astype(np.float32), 1.2)
SEG = ((905, 359.1), (1235, 291.0), 21.5)        # tronçon droit du chemin peint (écran) : début, fin, demi-largeur
PATH_MASK = np.zeros((H, W), np.float32)


def spline(pts, step=3.0):
    """Catmull-Rom (natif) échantillonnée finement : un chemin sans angles."""
    p = [np.array(pts[0], float)] + [np.array(q, float) for q in pts] + [np.array(pts[-1], float)]
    out = []
    for i in range(1, len(p) - 2):
        p0, p1, p2, p3 = p[i - 1], p[i], p[i + 1], p[i + 2]
        n = max(2, int(np.linalg.norm(p2 - p1) / step))
        for t in np.linspace(0, 1, n, endpoint=False):
            t2, t3 = t * t, t * t * t
            out.append(0.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(p[-2])
    return np.array(out)


def cobble_path(pts, width=1.0):
    """Pavés recopiés du chemin peint le long d'une courbe : coordonnée d'abscisse curviligne continue, la texture
    suit la courbe (aucun angle, aucune répétition visible au même endroit)."""
    global canvas
    sa, sb, hw = np.array(SEG[0], float), np.array(SEG[1], float), SEG[2] * width
    es = (sb - sa) / np.linalg.norm(sb - sa)
    ns = np.array([-es[1], es[0]])
    ls = np.linalg.norm(sb - sa)
    c = spline(pts) * 2.0
    seglen = np.linalg.norm(np.diff(c, axis=0), axis=1)
    s = np.concatenate([[0], np.cumsum(seglen)]) + rng.uniform(0, ls)
    m = hw + 6
    x0, y0 = int(max(c[:, 0].min() - m - 4, 0)), int(max(c[:, 1].min() - m - 4, 0))
    x1, y1 = int(min(c[:, 0].max() + m + 4, W)), int(min(c[:, 1].max() + m + 4, H))
    gy, gx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
    best_d = np.full(gx.shape, 1e9, np.float32)
    best_s = np.zeros(gx.shape, np.float32)
    best_n = np.zeros(gx.shape, np.float32)
    for i in range(len(c) - 1):
        a, bb = c[i], c[i + 1]
        L = max(seglen[i], 1e-3)
        e = (bb - a) / L
        n = np.array([-e[1], e[0]])
        # (boîte locale pour la vitesse)
        lx0, lx1 = int(max(min(a[0], bb[0]) - m - 2 - x0, 0)), int(min(max(a[0], bb[0]) + m + 2 - x0, x1 - x0))
        ly0, ly1 = int(max(min(a[1], bb[1]) - m - 2 - y0, 0)), int(min(max(a[1], bb[1]) + m + 2 - y0, y1 - y0))
        if lx1 <= lx0 or ly1 <= ly0:
            continue
        px, py = gx[ly0:ly1, lx0:lx1] - a[0], gy[ly0:ly1, lx0:lx1] - a[1]
        t = np.clip(px * e[0] + py * e[1], 0, L)
        d = px * n[0] + py * n[1]
        dist = np.hypot(px - t * e[0], py - t * e[1])
        upd = dist < best_d[ly0:ly1, lx0:lx1]
        best_d[ly0:ly1, lx0:lx1][upd] = dist[upd]
        best_s[ly0:ly1, lx0:lx1][upd] = (s[i] + t)[upd]
        best_n[ly0:ly1, lx0:lx1][upd] = np.sign(d[upd] + 1e-6) * dist[upd]
    inside = best_d < m
    u = best_s % (ls - 2)
    sp_x = sa[0] + es[0] * u + ns[0] * np.clip(best_n / width, -SEG[2] - 6, SEG[2] + 6)
    sp_y = sa[1] + es[1] * u + ns[1] * np.clip(best_n / width, -SEG[2] - 6, SEG[2] + 6)
    sxi = np.clip(np.round(sp_x).astype(int), 0, PW - 1)
    syi = np.clip(np.round(sp_y).astype(int), 0, PH - 1)
    alpha = _pathness[syi, sxi] * inside
    a3 = alpha[..., None]
    canvas[y0:y1, x0:x1] = canvas[y0:y1, x0:x1] * (1 - a3) + plate[syi, sxi] * a3
    PATH_MASK[y0:y1, x0:x1] = np.maximum(PATH_MASK[y0:y1, x0:x1], (best_d < hw + 10).astype(np.float32))
    return spline(pts)


def stamp(name, cx, cy, scale=1.0, alpha=1.0, flip=False, mode="normal"):
    """Accent de sol (pack, type decal) peint dans le sol, centré sur (cx, cy) en px d'écran."""
    global canvas
    im = Image.open(os.path.join(PACK, name + ".png")).convert("RGBA")
    if flip:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    if abs(scale - 1) > 1e-3:
        im = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.LANCZOS)
    a = np.asarray(im).astype(np.float32)
    x0, y0 = int(cx - im.width / 2), int(cy - im.height / 2)
    xa, ya = max(0, -x0), max(0, -y0)
    xb, yb = min(im.width, W - x0), min(im.height, H - y0)
    if xb <= xa or yb <= ya:
        return
    sub = a[ya:yb, xa:xb]
    al = sub[..., 3:4] / 255.0 * alpha
    dst = canvas[y0 + ya:y0 + yb, x0 + xa:x0 + xb]
    if mode == "dirt":                          # terre : on assombrit / réchauffe le sol plutôt que de le recouvrir
        canvas[y0 + ya:y0 + yb, x0 + xa:x0 + xb] = dst * (1 - al) + (dst * 0.35 + sub[..., :3] * 0.65) * al
    else:
        canvas[y0 + ya:y0 + yb, x0 + xa:x0 + xb] = dst * (1 - al) + sub[..., :3] * al


def dirt_trail(pts, spacing=16):
    """Sentier de terre : empreintes « terre nue » tamponnées le long d'une courbe, orientation et taille variées."""
    c = spline(pts) * 2.0
    acc = 0.0
    for i in range(1, len(c)):
        acc += np.linalg.norm(c[i] - c[i - 1])
        if acc >= spacing:
            acc = 0.0
            j = rng.normal(0, 3, 2)
            stamp("terre_grande" if rng.random() < 0.55 else "terre_petite", c[i][0] + j[0], c[i][1] + j[1],
                  scale=rng.uniform(0.55, 0.8), alpha=0.85, flip=rng.random() < 0.5, mode="dirt")
    m = Image.new("L", (W, H), 0)
    ImageDraw.Draw(m).line([tuple(p) for p in c], fill=255, width=34)
    global PATH_MASK
    PATH_MASK = np.maximum(PATH_MASK, np.asarray(m) / 255.0)
    return spline(pts)


# ------------------------------------------------------------------------------------- éléments
ORIG = zone["sprites"]


def foot_of(e, mode=""):
    fp = e["footprint"]
    if mode == "avant_gauche":
        return np.array(max(fp, key=lambda p: p[1]), float)
    c = np.mean(np.array(fp, float), 0)
    return np.array([c[0], e["sort_y"]])


def ellipse(cx, cy, rx, ry, n=12):
    return [[round(cx + math.cos(2 * math.pi * i / n) * rx, 1), round(cy + math.sin(2 * math.pi * i / n) * ry, 1)] for i in range(n)]


def trunk_x(name, base_from_bottom):
    """Abscisse du tronc (texture) : pixels brun-bois juste au-dessus de la base."""
    a = np.asarray(Image.open(os.path.join(PACK, name + ".png")).convert("RGBA")).astype(np.float32)
    h = a.shape[0]
    band = a[h - base_from_bottom - 30:h - base_from_bottom]
    wood = (band[..., 3] > 200) & (band[..., 0] > band[..., 1] + 8) & (band[..., 0] > band[..., 2] + 8)
    cols = np.nonzero(wood.sum(0) > 4)[0]
    if len(cols) == 0:
        return pack_index[name]["appui"][0]
    return float(np.median(np.nonzero(wood)[1]))


# Profils des assets du pack : base (px d'écran au-dessus du bas de la texture où se trouve le pied / la ligne de
# tri), emprise (demi-axes natifs rx, ry ; None = traversable), solide.
PROFILS = {
    "arbre_heros": (24, (16, 6), True), "arbre_elance": (18, (6, 3), True), "arbre_canopee": (20, (12, 5), True),
    "jeune_arbre": (14, (4, 2.5), True), "arbre_asym": (20, (9, 4), True),
    "buisson_dense": (6, (22, 8), False), "buisson_arrondi": (6, (19, 7), False), "buisson_ombre": (6, (19, 7), False),
    "buisson_violet": (6, (20, 7), False), "buisson_rose": (6, (20, 7), False), "fleurs_blanches": (5, (15, 6), False),
    "fleurs_violettes": (5, (16, 6), False), "massif_mixte": (5, (17, 6), False), "couvre_sol": (4, (20, 6), False),
    "buisson_sauvage": (5, (14, 6), False),
    "pierre_moyenne": (6, (19, 7), True), "rochers_bas": (6, (30, 8), True), "rocher_moussu": (7, (28, 9), True),
    "rochers_larges": (8, (40, 11), True), "formation_rocheuse": (8, (42, 11), True),
    "reverbere": (4, (3, 2), True), "cloture_petite": (4, (17, 2.5), True), "cloture_longue": (4, (34, 2.5), True),
    "banc_pack": (5, (18, 4), True), "caisses_pack": (5, (19, 6), True), "tonneaux_pack": (5, (18, 6), True),
    "sacs": (4, (17, 5), True), "panneau": (5, (4, 2.5), True), "portillon": (4, (25, 2.5), True),
}

elements = {}       # nom -> {"sprite": {...zone}, "decor": {...}, "ombre": (type, foot)}
USED = set()        # sprites du pack affichés tels quels (copiés dans art/explore_hd2d/pack/)
for k, e in ORIG.items():                                   # avant-poste d'origine (validé), translaté
    d = OFF
    o = json.loads(json.dumps(e))
    o["footprint"] = [[round(p[0] + d[0], 1), round(p[1] + d[1], 1)] for p in e["footprint"]]
    o["sort_y"] = round(e["sort_y"] + d[1], 1)
    if "pos" in o:
        o["pos"] = [int(round(o["pos"][0] + d[0])), int(round(o["pos"][1] + d[1]))]
    elements[k] = {"sprite": o, "decor": decor["elements"].get(k), "ombre": None}


def legacy(name, src, foot, calques=None):
    """Élément validé de l'avant-poste (illustre/), déplacé."""
    e = ORIG[src]
    r = decor["elements"][src]
    dlt = np.array(foot, float) - foot_of(e, r.get("pied", ""))
    o = json.loads(json.dumps(e))
    o["footprint"] = [[round(p[0] + dlt[0], 1), round(p[1] + dlt[1], 1)] for p in e["footprint"]]
    o["sort_y"] = round(e["sort_y"] + dlt[1], 1)
    o.pop("pos", None)
    rr = dict(r)
    if calques:
        rr["calques"] = calques
    elements[name] = {"sprite": o, "decor": rr, "ombre": (src, foot, o["footprint"])}


def pack(name, asset, foot, flip=False):
    """Élément du pack : pied posé sur `foot` (natif), emprise et tri selon le profil."""
    base, rad, solid = PROFILS[asset]
    w, h = pack_index[asset]["taille"]
    px = trunk_x(asset, base) if asset.startswith(("arbre", "jeune")) else pack_index[asset]["appui"][0]
    tex = asset
    if flip:
        tex = asset + "_miroir"
        px = w - px
    pivot = [round(px, 1), h - base]
    fx, fy = foot
    elements[name] = {
        "sprite": {"sort_y": round(fy, 1), "footprint": ellipse(fx, fy - rad[1], rad[0], rad[1]), "solid": solid},
        "decor": {"calques": [RES_PACK + tex if not flip else RES_V2 + tex], "pivot": pivot},
        "ombre": (asset, foot, None),
    }
    if flip:
        im = Image.open(os.path.join(PACK, asset + ".png"))
        im.transpose(Image.FLIP_LEFT_RIGHT).save(os.path.join(OUT, tex + ".png"))
    else:
        USED.add(asset)


# --- maisons : plus de copie évidente --------------------------------------------------------------------------
def recolor_roof(img, hue, sat_k, val_k):
    """Toit violet -> autre matière (ardoise, tuiles) ; murs, fenêtres et bois inchangés."""
    a = np.asarray(img.convert("RGBA")).astype(np.float32) / 255.0
    rgb = a[..., :3]
    mx, mn = rgb.max(-1), rgb.min(-1)
    sat = (mx - mn) / np.maximum(mx, 1e-4)
    # teinte violette : bleu et rouge > vert
    purple = (rgb[..., 2] > rgb[..., 1] * 1.08) & (rgb[..., 0] > rgb[..., 1] * 0.95) & (sat > 0.18)
    # toit seulement (les murs reçoivent aussi une lumière d'ambiance violette, qu'on garde) : polygone du toit
    # relevé sur maison.png (403×381), avec un fondu de 3 px sur son bord
    roof = Image.new("L", img.size, 0)
    ImageDraw.Draw(roof).polygon([(18, 30), (160, -2), (320, -2), (352, 28), (382, 100), (380, 112), (62, 164), (46, 136), (22, 42)], fill=255)
    purple &= np.asarray(roof) > 0
    out = rgb.copy()
    for y, x in zip(*np.nonzero(purple)):
        hh, ss, vv = colorsys.rgb_to_hsv(*rgb[y, x])
        out[y, x] = colorsys.hsv_to_rgb(hue, min(1, ss * sat_k), min(1, vv * val_k))
    return Image.fromarray((np.dstack([out, a[..., 3:4]]) * 255).astype(np.uint8), "RGBA")


ANCIENS = "--anciens" in sys.argv          # retour arrière : maisons recolorées de la V2 (avant le lot A de P2)
house = Image.open(os.path.join(SRC, "illustre/maison.png"))
for f in ("maison_ardoise.png", "maison_tuiles.png"):
    if os.path.exists(os.path.join(OUT, f)):
        os.remove(os.path.join(OUT, f))
if ANCIENS:
    recolor_roof(house, 0.58, 0.55, 1.0).transpose(Image.FLIP_LEFT_RIGHT).save(os.path.join(OUT, "maison_ardoise.png"))
    recolor_roof(house, 0.03, 0.85, 0.95).save(os.path.join(OUT, "maison_tuiles.png"))
GAB_BAT = json.load(open(os.path.join(ROOT, "docs/media/gabarits_batiments/gabarits.json")))["batiments"]
RES_BAT = "res://art/explore_hd2d/batiments/"


def batiment_at(name, key, foot):
    """Bâtiment P2 (illustration validée sur son gabarit) : emprise, pivot et porte lus dans gabarits.json ; calque de
    base + calque des vitres éclairées (« _fenetres », animé par le jeu). Renvoie le point d'interaction de la porte."""
    g = GAB_BAT[key]
    fp = [[round(foot[0] + q[0], 1), round(foot[1] + q[1], 1)] for q in g["emprise_natif_relative_au_pied"]]
    elements[name] = {"sprite": {"sort_y": round(foot[1], 1), "footprint": fp, "solid": True},
                      "decor": {"calques": [RES_BAT + key, RES_BAT + key + "_fenetres"], "pivot": g["pivot_texture_px"]},
                      "ombre": ("maison", foot, fp)}
    return np.array(foot) + np.array(g["point_interaction_porte_natif"])


def house_at(name, foot, tex, mirror):
    e = ORIG["maison"]
    r = decor["elements"]["maison"]
    f0 = foot_of(e)
    fp = []
    for p in e["footprint"]:
        dx, dy = p[0] - f0[0], p[1] - f0[1]
        fp.append([round(foot[0] + (-dx if mirror else dx), 1), round(foot[1] + dy, 1)])
    piv = [house.width - r["pivot"][0] if mirror else r["pivot"][0], r["pivot"][1]]
    elements[name] = {"sprite": {"sort_y": round(foot[1], 1), "footprint": fp, "solid": True},
                      "decor": {"calques": [RES_V2 + tex], "pivot": piv}, "ombre": ("maison", foot, fp)}
    return np.array(foot) + np.array([-9.4 if mirror else 9.4, -5.9])        # porte


# ------------------------------------------------------------------------------------- PLAN DE LA CARTE
if ANCIENS:
    door2 = house_at("maison_ardoise", (900, 380), "maison_ardoise", True) + np.array([0, 20])
    door3 = house_at("maison_tuiles", (620, 300), "maison_tuiles", False) + np.array([0, 16])
else:
    door2 = batiment_at("habitation", "habitation", (861, 405))     # hameau : porte au bout du chemin pavé
    door3 = batiment_at("remise", "remise", (600, 324))             # haut : double porte au bout du sentier

# chemins pavés en courbe (raccord au chemin peint d'origine) et sentiers de terre
END = np.array([655.0, 142.0]) + OFF
main_path = cobble_path([tuple(END - (8, -2)), (700, 534), (760, 516), (830, 494), (875, 450), (door2[0], door2[1] + 6)])
east_path = cobble_path([(800, 506), (880, 486), (960, 478), (1040, 487), (1110, 476), (1200, 452), (1300, 424)], width=0.85)
trail_house3 = dirt_trail([(735, 522), (712, 470), (680, 410), (650, 352), (door3[0], door3[1] + 6)])
trail_forest = dirt_trail([(650, 352), (560, 346), (450, 304), (330, 280), (230, 300), (150, 350)])
trail_east = dirt_trail([(1110, 476), (1140, 400), (1120, 320), (1080, 240), (1070, 150)])

# hameau : accessoires du pack autour de la maison d'ardoise
pack("sacs_1", "sacs", (842, 384) if ANCIENS else (800, 430))       # lot A : sorti de l'emprise de l'habitation
pack("caisses_3", "caisses_pack", (968, 392))
pack("tonneaux_3", "tonneaux_pack", (1000, 366))
pack("panneau_1", "panneau", (812, 520))
pack("reverbere_1", "reverbere", (776, 476))
pack("reverbere_2", "reverbere", (1012, 414))
pack("banc_3", "banc_pack", (930, 455))
pack("massif_1", "massif_mixte", (868, 396) if ANCIENS else (780, 404))
pack("fleurs_1", "buisson_rose", (940, 398))
pack("cloture_5", "cloture_longue", (1078, 380))      # 23 px libres après les tonneaux : pas de coin où se coincer
pack("portillon_1", "portillon", (1146, 372))
# maison de tuiles : sentier, tonneaux d'origine, réverbère, jardin fleuri
legacy("tonneaux_4", "tonneaux", (700, 288) if ANCIENS else (730, 282))   # lot A : pas de goulet contre la remise
pack("reverbere_3", "reverbere", (668, 330))
pack("fleurs_2", "fleurs_violettes", (560, 312) if ANCIENS else (518, 332))   # lot A : hors de l'emprise de la remise
pack("fleurs_3", "fleurs_blanches", (590, 318) if ANCIENS else (690, 322))
pack("cloture_6", "cloture_petite", (520, 300))
# arbre majestueux (repère) derrière la maison de tuiles et le hameau
pack("arbre_repere", "arbre_heros", (770, 252))
# bosquet de gauche : arbres variés et sous-bois (passages entre les troncs)
pack("arbre_b1", "arbre_canopee", (150, 452))
pack("arbre_b2", "arbre_elance", (282, 398))
pack("arbre_b3", "arbre_asym", (420, 468))
pack("arbre_b4", "jeune_arbre", (232, 340))
pack("buisson_b1", "buisson_dense", (205, 470))
pack("buisson_b2", "buisson_ombre", (350, 430))
pack("buisson_b3", "fleurs_violettes", (90, 400))
pack("buisson_b4", "buisson_sauvage", (330, 470))
pack("rocher_b1", "rocher_moussu", (60, 470))
pack("pierre_b1", "pierre_moyenne", (470, 420))
# passage étroit (clôtures validées) et ses abords
legacy("cloture_3", "cloture_d", (1040, 470))
legacy("cloture_4", "cloture_d", (1040, 504))
pack("arbre_c1", "jeune_arbre", (1016, 452))
pack("arbre_c2", "arbre_canopee", (1215, 430))
pack("buisson_c1", "buisson_violet", (1196, 470))
# prairie et lisière droite (prairie ouverte laissée libre autour de (1000, 250))
legacy("arbre_d_5", "arbre_d", (1150, 230))
pack("arbre_p1", "arbre_elance", (1272, 330))
pack("rocher_p1", "rochers_larges", (1180, 330))
pack("buisson_p1", "buisson_arrondi", (1110, 296))
pack("buisson_p2", "couvre_sol", (940, 230))
pack("pierre_p1", "pierre_moyenne", (880, 180))
# lisière arrière : arbres posés sur le bord (hors zone praticable : pas de collision nécessaire)
for i, (x, asset) in enumerate([(70, "arbre_asym"), (190, "arbre_canopee"), (330, "arbre_elance"), (440, "arbre_heros"),
                                (580, "arbre_asym"), (940, "arbre_canopee"), (1060, "arbre_elance")]):
    pack("lisiere_%d" % i, asset, (x, back_y(x) - 4), flip=(i % 2 == 1))
    elements["lisiere_%d" % i]["sprite"]["solid"] = False
for i, (y, asset) in enumerate([(200, "arbre_canopee"), (330, "arbre_asym")]):          # lisière droite
    xr = B1[0] + (y - B1[1]) / (F1[1] - B1[1]) * (F1[0] - B1[0]) + 26
    pack("lisiere_d%d" % i, asset, (xr, y))
    elements["lisiere_d%d" % i]["sprite"]["solid"] = False
# rive : rochers posés sur le haut du muret (hors zone praticable), rompent la ligne droite
for i, (x, asset, dy) in enumerate([(760, "formation_rocheuse", 16), (880, "rochers_bas", 12), (1000, "rocher_moussu", 14),
                                    (1090, "pierre_moyenne", 10), (1220, "rochers_larges", 18), (1340, "rochers_bas", 12)]):
    pack("rive_%d" % i, asset, (x, front_y(x) + dy), flip=(i % 2 == 0))
    elements["rive_%d" % i]["sprite"]["solid"] = False

# ------------------------------------------------------------------------------------- accents de sol
occupied = Image.new("L", (W, H), 0)
od = ImageDraw.Draw(occupied)
for k, el in elements.items():
    fp = el["sprite"]["footprint"]
    od.polygon([(p[0] * 2, p[1] * 2) for p in fp], fill=255)
occ = np.asarray(occupied.filter(ImageFilter.MaxFilter(21))) > 0
walk_in = poly_mask([tuple(p) for p in WALK], (W, H)) > 0.5
plate_zone = np.zeros((H, W), bool)
plate_zone[oy:oy + PH, :PW] = keep[..., 0] > 0.5


def free_for_accent(cx, cy):
    ix, iy = int(cx), int(cy)
    return 0 <= ix < W and 0 <= iy < H and walk_in[iy, ix] and not occ[iy, ix] and PATH_MASK[iy, ix] < 0.5 and not plate_zone[iy, ix]


ACCENTS = [("herbe_courte", 0.30), ("herbe_moyenne", 0.24), ("herbe_haute", 0.06), ("herbe_fleurie", 0.04),
           ("touffe_violette", 0.08), ("touffe_blanche", 0.05), ("cailloux", 0.10), ("terre_petite", 0.13)]
names = [a[0] for a in ACCENTS]
probs = np.array([a[1] for a in ACCENTS]); probs /= probs.sum()
placed = []
tries = 0
while len(placed) < 240 and tries < 40000:
    tries += 1
    cx, cy = rng.uniform(0, W), rng.uniform(0, H)
    if not free_for_accent(cx, cy) or any((cx - px) ** 2 + (cy - py) ** 2 < 70 ** 2 for px, py in placed):
        continue
    n = names[rng.choice(len(names), p=probs)]
    stamp(n, cx, cy, scale=rng.uniform(0.7, 1.0), alpha=0.8, flip=rng.random() < 0.5, mode="dirt" if n.startswith("terre") else "normal")
    placed.append((cx, cy))
# bordures des chemins pavés : touffes et cailloux de part et d'autre (lisent le bord, cassent la ligne)
for curve in (main_path, east_path):
    c = curve * 2.0
    for i in range(4, len(c) - 4, 7):
        t = c[i + 1] - c[i - 1]
        n = np.array([-t[1], t[0]]) / (np.linalg.norm(t) + 1e-6)
        for side in (-1, 1):
            if rng.random() < 0.55:
                p = c[i] + n * side * rng.uniform(28, 36)
                if 0 <= p[0] < W and 0 <= p[1] < H and not occ[int(p[1]), int(p[0])]:
                    stamp(["herbe_moyenne", "herbe_courte", "cailloux", "touffe_violette"][int(rng.integers(4))], p[0], p[1],
                          scale=rng.uniform(0.6, 0.85), alpha=0.9, flip=rng.random() < 0.5)
# rive : herbes hautes en roseaux le long du muret (hors avant-poste peint)
for x in np.arange(720, 1400, 26):
    sx = x * 2 + rng.normal(0, 8)
    sy = 2 * front_y(x) - rng.uniform(4, 14)
    stamp("herbe_haute" if rng.random() < 0.7 else "herbe_moyenne", sx, sy, scale=rng.uniform(0.6, 0.9), alpha=0.95, flip=rng.random() < 0.5)

# ------------------------------------------------------------------------------------- ombres de contact
shade = Image.new("L", (W, H), 0)
sd = ImageDraw.Draw(shade)
for k, el in elements.items():
    if el["ombre"] is None:
        continue
    src, foot, fp = el["ombre"]
    fx, fy = np.array(foot) * 2
    if src == "maison":
        p2 = np.array(fp) * 2
        cx, cy = p2.mean(0)
        sd.polygon([(x + (x - cx) * 0.08 + 10, y + (y - cy) * 0.12 - 8) for x, y in p2], fill=200)
    elif src.startswith(("arbre", "jeune")):
        rx = {"arbre_heros": 120, "arbre_canopee": 90, "arbre_asym": 70, "arbre_elance": 50, "jeune_arbre": 34}.get(src, 60)
        sd.ellipse([fx - rx, fy - rx * 0.38, fx + rx * 0.8, fy + rx * 0.12], fill=150)
    elif src.startswith(("buisson", "fleurs", "massif", "couvre")):
        sd.ellipse([fx - 40, fy - 16, fx + 40, fy + 4], fill=100)
    elif src.startswith(("rocher", "pierre", "formation")):
        rx = PROFILS[src][1][0] * 2.2
        sd.ellipse([fx - rx, fy - rx * 0.3, fx + rx, fy + rx * 0.08], fill=150)
    elif src.startswith("cloture") and fp is not None:
        sd.line([(p[0] * 2, p[1] * 2) for p in fp[:len(fp) // 2 + 1]], fill=120, width=10)
    else:
        sd.ellipse([fx - 22, fy - 10, fx + 22, fy + 5], fill=140)
shade = np.asarray(shade.filter(ImageFilter.GaussianBlur(7))).astype(np.float32)[..., None] / 255.0
canvas = canvas * (1 - shade * 0.78)

Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8)).save(os.path.join(OUT, "sol.webp"), quality=90, method=6)
# le jeu ne reçoit que les sprites utilisés (pas d'assets inutilisés importés ni chargés)
import shutil
os.makedirs(PACK_JEU, exist_ok=True)
for f in os.listdir(PACK_JEU):
    if f.endswith(".png") and f[:-4] not in USED:
        os.remove(os.path.join(PACK_JEU, f))
        if os.path.exists(os.path.join(PACK_JEU, f + ".import")):
            os.remove(os.path.join(PACK_JEU, f + ".import"))
for n in sorted(USED):
    shutil.copyfile(os.path.join(PACK, n + ".png"), os.path.join(PACK_JEU, n + ".png"))
if os.path.exists(os.path.join(PACK_JEU, "index.json")):
    os.remove(os.path.join(PACK_JEU, "index.json"))

# ------------------------------------------------------------------------------------- données de jeu
sprites = {k: v["sprite"] for k, v in elements.items()}
spawn = {k: [round(v[0] + OFF[0], 1), round(v[1] + OFF[1], 1)] for k, v in zone["spawn"].items()}
lights = [[round(p[0] + OFF[0], 1), round(p[1] + OFF[1], 1)] for p in zone["lights"]]
for k, el in elements.items():
    if el["ombre"] and el["ombre"][0] == "reverbere":
        f = el["ombre"][1]
        lights.append([round(f[0] + 13, 1), round(f[1] - 22, 1)])             # lanterne suspendue à droite du poteau
    elif el["ombre"] and el["ombre"][0] == "lanterne_0":
        f = el["ombre"][1]
        lights.append([round(f[0] + 10.4, 1), round(f[1] - 3.2, 1)])
zd = {
    "_doc": "EXPLORATION v2 (version par défaut, F5) — générée par tools/explore/build_exploration_v2.py. Même format "
            "que zone.json ; l'avant-poste d'origine y est translaté de (0, 400).",
    "native": list(NAT), "ppm": zone["ppm"],
    "walkable": [[round(p[0], 1), round(p[1], 1)] for p in WALK],
    "spawn": spawn, "lights": lights, "sprites": sprites,
}
zd["elements"] = sprites
json.dump(zd, open(os.path.join(OUT, "zone.json"), "w"), ensure_ascii=False, indent=1)
dd = {
    "_doc": "EXPLORATION v2 — calques : nom simple = art/explore_hd2d/illustre/<nom>.png (assets validés), chemin "
            "res:// = pack du 2026-11-07 ou variantes générées. Pivot = point de la texture posé sur le pied.",
    "sol": RES_V2 + "sol.webp",
    "masquer": decor["masquer"],
    "elements": {k: v["decor"] for k, v in elements.items() if v["decor"] is not None},
    "details": [[d[0], d[1] + OFF[0], d[2] + OFF[1], d[3]] for d in decor["details"]],
}
json.dump(dd, open(os.path.join(OUT, "decor.json"), "w"), ensure_ascii=False, indent=1)
print("v2 : sol %dx%d, %d éléments (%d du pack), %d accents de sol" % (
    W, H, len(sprites), sum(1 for v in elements.values() if v["decor"] and str(v["decor"]["calques"][0]).startswith("res://")), len(placed)))
