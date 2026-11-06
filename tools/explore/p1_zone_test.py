#!/usr/bin/env python3
"""P1 — ZONE DE TEST AGRANDIE pour comparer les caméras (prototype, PAS une nouvelle région).

Compose une carte 1408×800 px natifs (4× la surface de l'avant-poste, 2× dans chaque direction) à partir des
SEULS assets validés, sans étirer d'image :
  * sol : le sol peint d'origine (sol.png) est recopié tel quel en bas à gauche (avec ses ombres) ; autour, l'herbe,
    la lisière de forêt et l'eau sous le muret sont recomposées par PATCHS du même sol (mêmes pixels, même échelle,
    raccords fondus) ; le muret et l'eau sont prolongés le long de leur propre pente ; de nouveaux chemins pavés sont
    tracés en recopiant un tronçon droit du chemin peint ; les nouveaux éléments reçoivent une ombre de contact.
  * éléments : copies translatées des éléments de zone.json (même emprise, collision, tri, calques illustrés).
Sorties (art/explore_hd2d/p1/) : sol_p1.webp, zone_p1.json (même format que zone.json), decor_p1.json.
Reproductible (graine fixe) :  python3 tools/explore/p1_zone_test.py
"""
import json
import math
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "art/explore_hd2d")
OUT = os.path.join(SRC, "p1")
NAT = (1408, 800)                     # px natifs (monde)
W, H = NAT[0] * 2, NAT[1] * 2          # px d'écran du sol (affiché à l'échelle 0,5, comme sol.png)
OFF = np.array([0.0, 400.0])           # position de l'avant-poste d'origine dans la grande carte (natif)
SLOPE = (248.8 - 370.4) / (691.5 - 108.9)  # pente de l'axe « largeur » du sol (rotation 20°) = muret, bord avant
rng = np.random.default_rng(7)

zone = json.load(open(os.path.join(SRC, "zone.json")))
decor = json.load(open(os.path.join(SRC, "illustre/decor.json")))
plate = np.asarray(Image.open(os.path.join(SRC, "illustre/sol/sol.png")).convert("RGB")).astype(np.float32)
PH, PW = plate.shape[:2]


def poly_mask(points, size, scale=2.0, offset=(0, 0)):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).polygon([((x + offset[0]) * scale, (y + offset[1]) * scale) for x, y in points], fill=255)
    return np.asarray(m).astype(np.float32) / 255.0


def soften(mask, radius):
    return np.asarray(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(radius))).astype(np.float32) / 255.0


# ------------------------------------------------------------------------------------- géométrie de la grande carte
F0 = np.array([108.9, 370.4]) + OFF              # coin avant gauche de la zone praticable d'origine
U = np.array([582.6, -121.6])                    # bord avant (largeur) de l'origine
V = np.array([-128.6, -202.7])                   # profondeur de l'origine
F1, B1, B0 = F0 + U * 2.2, F0 + U * 2.2 + V * 2.1, F0 + V * 2.1


def clip_left(a, b, x):
    t = (x - a[0]) / (b[0] - a[0])
    return a + (b - a) * t


WALK = [F0, F1, B1, clip_left(B0, B1, 14.0), clip_left(F0, B0, 14.0)]


def front_y(x):                                   # bord avant (natif) prolongé
    return F0[1] + (x - F0[0]) * SLOPE


# ------------------------------------------------------------------------------------- synthèse par patchs
def synth(src, allowed, size, patch=160, step=104, power=4.0, norm=None):
    """Remplit `size` (h, w) de patchs tirés de `src` aux positions où `allowed` est vrai (patch entier), avec
    retournement horizontal aléatoire et raccords fondus (fenêtre cosinus^power : les transitions restent nettes)."""
    h, w = size
    ok = np.argwhere(allowed[: src.shape[0] - patch, : src.shape[1] - patch])
    win1 = np.sin(np.linspace(0, math.pi, patch)) ** power + 1e-4
    win = np.outer(win1, win1)[..., None]
    acc = np.zeros((h + 2 * patch, w + 2 * patch, 3), np.float32)
    wsum = np.zeros((h + 2 * patch, w + 2 * patch, 1), np.float32)
    for y0 in range(-patch // 2, h, step):
        for x0 in range(-patch // 2, w, step):
            y = int(y0 + rng.integers(-step // 4, step // 4 + 1))
            x = int(x0 + rng.integers(-step // 4, step // 4 + 1))
            y, x = max(y, -patch // 2), max(x, -patch // 2)
            sy, sx = ok[rng.integers(len(ok))]
            p = src[sy:sy + patch, sx:sx + patch]
            if norm is not None:
                p = p - p.reshape(-1, 3).mean(0) + norm     # même ton moyen : pas de damier de patchs
            if rng.random() < 0.5:
                p = p[:, ::-1]
            yy, xx = y + patch // 2, x + patch // 2
            acc[yy:yy + patch, xx:xx + patch] += p * win
            wsum[yy:yy + patch, xx:xx + patch] += win
    out = acc / np.maximum(wsum, 1e-6)
    return out[patch // 2:patch // 2 + h, patch // 2:patch // 2 + w]


def allowed_for(region_mask, bad, patch, keep=1.0):
    """Positions (coin haut-gauche) dont le patch entier est dans la région ; parmi elles, la fraction `keep` qui
    contient le MOINS de pixels « mauvais » (ombres portées, chemin)."""
    def box(a):
        c = np.pad(np.cumsum(np.cumsum(a.astype(np.int32), 0), 1), ((1, 0), (1, 0)))
        return c[patch:, patch:] - c[:-patch, patch:] - c[patch:, :-patch] + c[:-patch, :-patch]
    inside = box(region_mask > 0.99) >= patch * patch
    nbad = box(bad)
    lim = np.quantile(nbad[inside], keep) if keep < 1.0 else np.inf
    res = np.zeros(region_mask.shape, bool)
    res[: inside.shape[0], : inside.shape[1]] = inside & (nbad <= lim)
    return res


r, g, b = plate[..., 0], plate[..., 1], plate[..., 2]
luma = 0.3 * r + 0.59 * g + 0.11 * b
walk0 = poly_mask([(p[0], p[1]) for p in zone["walkable"]], (PW, PH))
inner0 = soften(walk0, 1) * (np.asarray(Image.fromarray((walk0 * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(41))) > 0)
_pm = Image.new("L", (PW, PH), 0)                # chemin peint d'origine (tracé à la main sur l'image, écran)
ImageDraw.Draw(_pm).line([(330, 712), (480, 598), (700, 392), (830, 358), (1235, 286), (1340, 262)], fill=255, width=70)
path_px = np.asarray(_pm) > 0
_pc = Image.new("L", (PW, PH), 0)
ImageDraw.Draw(_pc).line([(498, 598), (705, 400)], fill=255, width=26)
ImageDraw.Draw(_pc).line([(905, 359), (1235, 291)], fill=255, width=36)
path_core = np.asarray(_pc) > 0                  # cœur du chemin (les pierres sombres comptent aussi)
dark_px = np.asarray(Image.fromarray(((luma < 16) * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(11))) > 0
house_zone = np.zeros_like(path_px)
house_zone[150:400, 600:1000] = True             # ombre de la maison
rocks = np.zeros_like(path_px)
rocks[600:, :] = True                            # rangée de rochers moussus du premier plan
grass_bad = path_px | dark_px | house_zone | rocks

GP = 128
_gok = allowed_for(inner0, grass_bad, GP, keep=0.15)
_gmean = plate[inner0 > 0.99][~grass_bad[inner0 > 0.99]].mean(0)
grass = synth(plate, _gok, (H, W), patch=GP, step=84, norm=_gmean)

# forêt : canopée de l'angle haut gauche de l'avant-poste (au-dessus du bord arrière)
forest_reg = np.zeros((PH, PW), np.float32)
forest_reg[0:250, 0:330] = 1.0
FP = 128
forest = synth(plate, allowed_for(forest_reg, np.zeros_like(path_px), FP), (H, W), patch=FP, step=84)

# eau profonde : angle bas droit, sous le muret
water_reg = np.zeros((PH, PW), np.float32)
water_reg[650:800, 1240:1408] = 1.0
WP_ = 96
water = synth(plate, allowed_for(water_reg, np.zeros_like(path_px), WP_), (H, W), patch=WP_, step=60,
              norm=plate[650:800, 1240:1408].reshape(-1, 3).mean(0))

# ------------------------------------------------------------------------------------- composition
canvas = grass.copy()
walk_big = poly_mask([tuple(p) for p in WALK], (W, H))
grassy = soften(np.asarray(Image.fromarray((walk_big * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(49))) / 255.0, 22)
ys = np.arange(H)[:, None] / 2.0
xs = np.arange(W)[None, :] / 2.0
below_front = ys > front_y(xs) - 4                # côté muret / eau : jamais de forêt
fa = np.where(below_front, 0.0, 1.0 - grassy)[..., None]
canvas = canvas * (1 - fa) + forest * fa

# eau et muret : bande sous le bord avant recopiée de l'origine le long de sa propre pente (pas d'étirement)
src_x0, src_w = 640, 700                          # colonnes source (écran) où la bande muret + eau est la plus haute
band = np.zeros((H, W, 3), np.float32)
band_a = np.zeros((H, W), np.float32)
x = 0
while x < W:
    sx = src_x0 + (x % src_w)
    run = min(src_w - (x % src_w), W - x)
    for k in range(run):
        cx, scx = x + k, sx + k
        line_src = 2 * (front_y(scx / 2.0) - OFF[1])          # ligne du muret (écran) dans l'image d'origine
        shift = int(round(2 * front_y(cx / 2.0) - line_src))  # même pente : décalage constant par colonne
        sy0 = max(int(line_src) - 30, 0, -shift)
        sy1 = min(PH, H - shift)
        if sy1 > sy0:
            band[sy0 + shift:sy1 + shift, cx] = plate[sy0:sy1, scx]
            band_a[sy0 + shift:sy1 + shift, cx] = 1.0
        # sous la bande recopiée : eau profonde
        last = PH - 1 + shift
        if last + 1 < H:
            band[last + 1:, cx] = water[last + 1:, cx]
            band_a[last + 1:, cx] = 1.0
    x += run
# fondu en haut de la bande (raccord herbe) et entre deux recopies (colonnes)
top_soft = np.clip((ys - (front_y(xs) - 13)) / 8.0, 0, 1)
seam = np.ones(W, np.float32)
for sx0 in range(0, W, src_w):
    for k in range(-40, 41):
        if 0 <= sx0 + k < W:
            seam[sx0 + k] = min(seam[sx0 + k], 0.5 + 0.5 * abs(k) / 40.0)
ba = (band_a * top_soft * seam[None, :])[..., None]
canvas = canvas * (1 - ba) + band * ba

# avant-poste d'origine, recopié tel quel (zone praticable + bande du muret), sans sa canopée de gauche
keep = poly_mask([(p[0], p[1]) for p in zone["walkable"]], (PW, PH))
keep = np.maximum(np.asarray(Image.fromarray((keep * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(25))) / 255.0, 0)
yy0 = np.arange(PH)[:, None] / 2.0
xx0 = np.arange(PW)[None, :] / 2.0
keep = np.maximum(keep, (yy0 > (front_y(xx0) - OFF[1]) - 14).astype(np.float32))
canopy = poly_mask([(-10, 100), (170, 100), (175, 150), (120, 205), (40, 215), (-10, 215)], (PW, PH))
keep = keep * (1 - canopy)
keep = soften(keep, 14)[..., None]
oy = int(OFF[1] * 2)
region = canvas[oy:oy + PH, 0:PW]
canvas[oy:oy + PH, 0:PW] = region * (1 - keep) + plate * keep


# ------------------------------------------------------------------------------------- chemins pavés
_pathness = soften((((r > g * 0.95) & (luma > 50)) | path_core).astype(np.float32), 1.2)


def draw_path(poly, seg):
    """Recopie un tronçon droit du chemin peint (seg : début, fin, demi-largeur ; écran) le long d'une polyligne
    (natif). L'opacité vient du chemin source lui-même (bords de pierres naturels)."""
    global canvas
    sa, sb, hw = np.array(seg[0], float), np.array(seg[1], float), seg[2]
    es = (sb - sa) / np.linalg.norm(sb - sa)
    ns = np.array([-es[1], es[0]])
    ls = np.linalg.norm(sb - sa)
    s_acc = rng.uniform(0, ls)
    m = hw + 6
    for a, b_ in zip(poly[:-1], poly[1:]):
        a, b_ = np.array(a, float) * 2, np.array(b_, float) * 2
        e = (b_ - a) / np.linalg.norm(b_ - a)
        n = np.array([-e[1], e[0]])
        L = np.linalg.norm(b_ - a)
        x0, x1 = int(max(min(a[0], b_[0]) - m - 4, 0)), int(min(max(a[0], b_[0]) + m + 4, W))
        y0, y1 = int(max(min(a[1], b_[1]) - m - 4, 0)), int(min(max(a[1], b_[1]) + m + 4, H))
        gy, gx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
        rel = np.stack([gx - a[0], gy - a[1]], -1)
        t = rel @ e
        d = rel @ n
        tc = np.clip(t, 0, L)
        dist = np.hypot(t - tc, d)                 # bouts arrondis (raccord des segments)
        u = (s_acc + t) % (ls - 2)                 # pas de motif radial aux raccords : la texture continue tout droit
        sp = sa[None, None, :] + es * u[..., None] + ns * np.clip(d, -m, m)[..., None]
        sxi = np.clip(np.round(sp[..., 0]).astype(int), 0, PW - 1)
        syi = np.clip(np.round(sp[..., 1]).astype(int), 0, PH - 1)
        alpha = _pathness[syi, sxi] * (dist < m)
        a3 = alpha[..., None]
        canvas[y0:y1, x0:x1] = canvas[y0:y1, x0:x1] * (1 - a3) + plate[syi, sxi] * a3
        s_acc += L


SEG_FLAT = ((905, 359.1), (1235, 291.0), 21.5)     # (début, fin, demi-largeur), centre mesuré sur l'image             # tronçon presque horizontal du chemin peint (écran)
SEG_DIAG = ((498.5, 598), (704.8, 400), 16.5)              # tronçon diagonal


def path(poly):
    # pour chaque segment, le tronçon source dont l'orientation est la plus proche
    for a, b_ in zip(poly[:-1], poly[1:]):
        d = np.array(b_, float) - np.array(a, float)
        ang = abs(math.degrees(math.atan2(-d[1], abs(d[0]))))
        draw_path([a, b_], SEG_DIAG if ang > 30 else SEG_FLAT)


# ------------------------------------------------------------------------------------- éléments
ORIG = zone["sprites"]


def foot_of(e, mode=""):
    fp = e["footprint"]
    if mode == "avant_gauche":
        q = max(fp, key=lambda p: p[1])
        return np.array(q, float)
    c = np.mean(np.array(fp, float), 0)
    return np.array([c[0], e["sort_y"]])


elements = {}
for k, e in ORIG.items():                         # l'avant-poste d'origine, translaté
    elements[k] = {"src": k, "delta": OFF.copy()}

# nouveaux éléments : (nom, élément source, pied visé en px natifs de la grande carte)
NEW = [
    # hameau du haut : deuxième maison (grand élément occultant), caisses, tonneaux, lanternes, banc
    ("maison_2", "maison", (900, 380)),
    ("caisses_2", "caisses", (838, 390)),
    ("tonneaux_2", "tonneaux", (985, 362)),
    ("lanterne_3", "lanterne_0", (782, 470)),
    ("lanterne_4", "lanterne_0", (1010, 408)),
    ("banc_2", "banc", (700, 420)),
    # bosquet à gauche : arbres et buissons serrés (passages entre les troncs, personnages cachés)
    ("arbre_g_2", "arbre_g", (150, 452)),
    ("arbre_d_2", "arbre_d", (282, 398)),
    ("arbre_g_3", "arbre_g", (420, 470)),
    ("arbre_d_3", "arbre_d", (232, 340)),
    ("buisson_5", "buisson_1", (205, 470)),
    ("buisson_6", "buisson_3", (350, 430)),
    ("buisson_7", "buisson_0", (90, 400)),
    # passage étroit à droite : deux clôtures parallèles (couloir de 34 px natifs ≈ 1,7 m), arbres aux extrémités
    ("cloture_3", "cloture_d", (1040, 470)),
    ("cloture_4", "cloture_d", (1040, 504)),
    ("arbre_d_4", "arbre_d", (1018, 452)),
    ("arbre_g_4", "arbre_g", (1215, 430)),
    ("buisson_8", "buisson_4", (1200, 470)),
    # lisière de droite et prairie ouverte
    ("arbre_d_5", "arbre_d", (1150, 230)),
    ("arbre_g_5", "arbre_g", (1270, 330)),
    ("buisson_9", "buisson_2", (1110, 300)),
    ("buisson_10", "buisson_3", (760, 230)),
    ("arbre_d_6", "arbre_d", (640, 250)),
    ("lanterne_5", "lanterne_0", (1180, 560)),
]
for name, src, foot in NEW:
    e = ORIG[src]
    mode = decor["elements"].get(src, {}).get("pied", "")
    elements[name] = {"src": src, "delta": np.array(foot, float) - foot_of(e, mode)}

# chemins : prolongement du chemin peint vers le hameau, puis vers le passage étroit et la prairie
END = np.array([655.0, 142.0]) + OFF               # bout droit du chemin peint d'origine (natif)
path([tuple(END - (6, -1)), (740, 520), (800, 498), (868, 470), (905, 438), (913, 400)])
path([(800, 498), (900, 478), (995, 470), (1040, 487), (1110, 474), (1200, 450), (1300, 420)])

# ombres de contact des NOUVEAUX éléments (l'avant-poste d'origine a déjà les siennes, peintes)
shade = Image.new("L", (W, H), 0)
sd = ImageDraw.Draw(shade)
for name, src, foot in NEW:
    e = ORIG[src]
    dlt = elements[name]["delta"]
    fp = [((p[0] + dlt[0]) * 2, (p[1] + dlt[1]) * 2) for p in e["footprint"]]
    fx, fy = np.array(foot) * 2
    if src == "maison":
        cx, cy = np.mean(np.array(fp), 0)
        sd.polygon([(x + (x - cx) * 0.08 + 10, y + (y - cy) * 0.12 - 8) for x, y in fp], fill=200)
    elif src.startswith("arbre"):
        sd.ellipse([fx - 62, fy - 26, fx + 50, fy + 10], fill=150)
    elif src.startswith("buisson"):
        sd.ellipse([fx - 46, fy - 22, fx + 46, fy + 4], fill=110)
    elif src.startswith("cloture"):
        sd.line(fp[:len(fp) // 2 + 1], fill=120, width=10)
    else:
        sd.ellipse([fx - 22, fy - 10, fx + 22, fy + 5], fill=140)
shade = np.asarray(shade.filter(ImageFilter.GaussianBlur(7))).astype(np.float32)[..., None] / 255.0
canvas = canvas * (1 - shade * 0.82)

os.makedirs(OUT, exist_ok=True)
Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8)).save(os.path.join(OUT, "sol_p1.webp"), quality=90, method=6)

# ------------------------------------------------------------------------------------- données de jeu
def moved(e, d):
    o = json.loads(json.dumps(e))
    o["footprint"] = [[round(p[0] + d[0], 1), round(p[1] + d[1], 1)] for p in e["footprint"]]
    o["sort_y"] = round(e["sort_y"] + d[1], 1)
    if "pos" in o:
        o["pos"] = [int(round(o["pos"][0] + d[0])), int(round(o["pos"][1] + d[1]))]
    return o


sprites = {k: moved(ORIG[v["src"]], v["delta"]) for k, v in elements.items()}
spawn = {k: [round(v[0] + OFF[0], 1), round(v[1] + OFF[1], 1)] for k, v in zone["spawn"].items()}
lights = [[round(p[0] + OFF[0], 1), round(p[1] + OFF[1], 1)] for p in zone["lights"]]
for name, src, foot in NEW:
    if src.startswith("lanterne"):
        lights.append([foot[0] + 10.4, foot[1] - 3.2])
zp = {
    "_doc": "P1 — zone de TEST agrandie (comparaison des caméras) ; générée par tools/explore/p1_zone_test.py. "
            "Même format que zone.json ; l'avant-poste d'origine y est translaté de (0, 400).",
    "native": list(NAT),
    "ppm": zone["ppm"],
    "walkable": [[round(p[0], 1), round(p[1], 1)] for p in WALK],
    "spawn": spawn,
    "lights": lights,
    "sprites": sprites,
}
zp["elements"] = sprites
json.dump(zp, open(os.path.join(OUT, "zone_p1.json"), "w"), ensure_ascii=False, indent=1)
dp = {
    "_doc": "P1 — décor de la zone de test : mêmes calques illustrés que decor.json, sol recomposé (sol_p1.webp).",
    "sol": "res://art/explore_hd2d/p1/sol_p1.webp",
    "masquer": decor["masquer"],
    "elements": {k: decor["elements"][v["src"]] for k, v in elements.items() if v["src"] in decor["elements"]},
    "details": [[d[0], d[1] + OFF[0], d[2] + OFF[1], d[3]] for d in decor["details"]],
}
json.dump(dp, open(os.path.join(OUT, "decor_p1.json"), "w"), ensure_ascii=False, indent=1)
print("sol_p1.webp %dx%d, %d éléments, praticable %s" % (W, H, len(sprites), [[round(p[0]), round(p[1])] for p in WALK]))
