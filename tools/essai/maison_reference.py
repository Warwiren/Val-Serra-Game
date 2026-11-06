"""ESSAI — maison d'après la RÉFÉRENCE OFFICIELLE (art/source/concepts_2026-11-07/maison_reference_officielle.webp),
ramenée face par face sur la GÉOMÉTRIE EXACTE du gabarit du jeu (silhouette, toit, ouvertures, emprise inchangés).
Chaque face plane (façade, mur latéral gauche, versant de toit) est reprojetée de la référence vers le gabarit par
une homographie définie par ses 4 coins (repérés à la main sur les deux images, ci-dessous). Puis :
  - porte et 3 fenêtres de la référence redimensionnées dans les rectangles EXACTS du gabarit ;
  - cheminée et poutre faîtière de la référence posées aux emplacements du gabarit ;
  - pixels du gabarit non couverts (débords, épaisseurs) : maison de l'essai v2 ; silhouette = alpha du gabarit ;
  - étalonnage crépusculaire léger (fenêtres chaudes conservées).
    python3 tools/essai/maison_reference.py [v2]"""
import json, sys
import numpy as np
from PIL import Image

V = sys.argv[1] if len(sys.argv) > 1 else "v2"
OUT = "art/explore_hd2d/essai_%s/" % V
GAB = "docs/media/gabarits_exploration/"
REF = np.asarray(Image.open("art/source/concepts_2026-11-07/maison_reference_officielle.webp").convert("RGB")).astype(np.float32)
meta = json.load(open(GAB + "gabarits.json"))
box = meta["elements"]["maison"]["rectangle_ecran"]
full = np.asarray(Image.open(GAB + "maison/maison_complete_cadre_1408x800.png").convert("RGBA")).astype(np.float32)[box[1]:box[3], box[0]:box[2]]
fallback = np.asarray(Image.open(OUT + "maison.png").convert("RGBA")).astype(np.float32) if False else None
H, W = full.shape[:2]
alpha = full[..., 3]

# coins (référence -> gabarit), ordre : haut-gauche, haut-droit, bas-droit, bas-gauche
OX, OY = 40, 90                                            # coins relevés sur un recadrage (40, 90) de la planche
FACES = {
    "toit":    ([(65, 100), (690, 38), (805, 250), (195, 335)], [(25, 35), (310, -5), (375, 105), (60, 160)]),
    "facade":  ([(205, 352), (775, 270), (775, 690), (205, 775)], [(110, 151), (355, 108), (355, 300), (110, 355)]),
    "lateral": ([(45, 310), (205, 352), (205, 775), (45, 560)], [(48, 100), (110, 151), (110, 355), (46, 228)]),
}
FACES = {k: ([(x + OX, y + OY) for x, y in s_], d) for k, (s_, d) in FACES.items()}
# ouvertures de la référence (coordonnées de la planche) : étage, rdc gauche, rdc droite, porte
REF_OPEN = {"etage": (488, 465, 575, 555), "rdc_g": (300, 615, 405, 730), "rdc_d": (652, 577, 760, 687), "porte": (458, 590, 595, 780)}
ORDER = ["lateral", "facade", "toit"]                       # le toit déborde par-dessus les murs


def homography(src, dst, wts=None):
    A = []
    for k, ((x, y), (u, v)) in enumerate(zip(src, dst)):
        w = 1.0 if wts is None else wts[k]
        A += [[w * x, w * y, w, 0, 0, 0, -w * u * x, -w * u * y, -w * u], [0, 0, 0, w * x, w * y, w, -w * v * x, -w * v * y, -w * v]]
    h = np.linalg.svd(np.array(A, float))[2][-1]
    return (h / h[-1]).reshape(3, 3)


def inside(poly, xx, yy):
    m = np.ones(xx.shape, bool)
    n = len(poly)
    sgn = None
    for i in range(n):
        (x0, y0), (x1, y1) = poly[i], poly[(i + 1) % n]
        c = (x1 - x0) * (yy - y0) - (y1 - y0) * (xx - x0)
        s = c >= 0
        m &= s if (sgn is None or sgn) else ~s
        if sgn is None:
            sgn = True
    return m


def sample(img, x, y):
    x = np.clip(x, 0, img.shape[1] - 1.001); y = np.clip(y, 0, img.shape[0] - 1.001)
    x0 = np.floor(x).astype(int); y0 = np.floor(y).astype(int); fx = (x - x0)[..., None]; fy = (y - y0)[..., None]
    return (img[y0, x0] * (1 - fx) * (1 - fy) + img[y0, x0 + 1] * fx * (1 - fy) + img[y0 + 1, x0] * (1 - fx) * fy + img[y0 + 1, x0 + 1] * fx * fy)


yy, xx = np.mgrid[0:H, 0:W].astype(np.float64)
out = np.asarray(Image.open(OUT + "maison.png").convert("RGBA")).astype(np.float32)[..., :3].copy()   # repli : essai v2
covered = np.zeros((H, W), bool)
ops = meta.get("ouvertures_maison_ecran", [])


def gab_open(kind):
    for o in ops:
        r = o["rectangle_dans_gabarit"]
        if kind == "porte" and o["type"] == "porte":
            return r
        if o["type"] != "porte":
            if kind == "etage" and r[1] < 230:
                return r
            if kind == "rdc_g" and r[1] >= 230 and r[0] < 200:
                return r
            if kind == "rdc_d" and r[1] >= 230 and r[0] >= 200:
                return r


def ctr(r):
    return ((r[0] + r[2]) / 2, (r[1] + r[3]) / 2)


for name in ORDER:
    src, dst = FACES[name]
    if name == "facade":                                     # la façade est calée aussi sur les 4 ouvertures (poids fort)
        s2 = list(src) + [ctr(REF_OPEN[k]) for k in REF_OPEN]
        d2 = list(dst) + [ctr(gab_open(k)) for k in REF_OPEN]
        # transformation AFFINE (projection orthographique : une façade plane reste un parallélogramme), ajustée
        # aux moindres carrés sur les 4 coins et les coins des 4 ouvertures (poids fort) : stable, sans fuite
        s2 = list(src); d2 = list(dst); wts = [1.0] * 4
        for k in REF_OPEN:
            rs, rg = REF_OPEN[k], gab_open(k)
            for (a_, b_), (c_, e_) in zip(((rs[0], rs[1]), (rs[2], rs[3]), (rs[0], rs[3]), (rs[2], rs[1])), ((rg[0], rg[1]), (rg[2], rg[3]), (rg[0], rg[3]), (rg[2], rg[1]))):
                s2.append((a_, b_)); d2.append((c_, e_)); wts.append(3.0)
        Aa = np.array([[x, y, 1] for x, y in d2]) * np.array(wts)[:, None]
        Bb = np.array(s2) * np.array(wts)[:, None]
        aff = np.linalg.lstsq(Aa, Bb, rcond=None)[0].T          # gabarit -> référence
        Hm = np.vstack([aff, [0, 0, 1]])
    else:
        Hm = homography(dst, src)                            # gabarit -> référence (lecture inverse)
    m = inside(dst, xx, yy)
    if not m.any():
        m = inside(dst[::-1], xx, yy)
    pts = np.stack([xx[m], yy[m], np.ones(m.sum())])
    q = Hm @ pts; q = q[:2] / q[2]
    out[m] = sample(REF, q[0], q[1])
    covered |= m


def paste(rect, crop_box, pad=0):
    x0, y0, x1, y1 = rect
    x0 -= pad; y0 -= pad; x1 += pad; y1 += pad
    c = REF[crop_box[1]:crop_box[3], crop_box[0]:crop_box[2]]
    im = np.asarray(Image.fromarray(c.astype(np.uint8)).resize((x1 - x0, y1 - y0), Image.LANCZOS)).astype(np.float32)
    out[y0:y1, x0:x1] = im


for k in REF_OPEN:                                            # ouvertures EXACTEMENT dans les rectangles du gabarit
    paste(gab_open(k), REF_OPEN[k], 1 if k == "porte" else 3)
# cheminée de la référence à l'emplacement de celle du gabarit (bloc gris de la carte des zones)
zones = np.asarray(Image.open(GAB + "maison/maison_zones.png").convert("RGBA")).astype(np.float32)
leg = {k: np.array([int(v[i:i + 2], 16) for i in (1, 3, 5)], np.float32) for k, v in json.load(open(GAB + "legende_zones.json")).items()}
stone = (np.abs(zones[..., :3] - leg["pierre"]).sum(-1) < 45) & (zones[..., 3] > 100)
ys, xs = np.nonzero(stone & (yy < 100))
if len(xs):
    paste((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1), (610, 120, 680, 285))
# étalonnage crépusculaire : ombres bleutées, fenêtres chaudes gardées
warm = (out[..., 0] > 170) & (out[..., 0] > out[..., 2] * 1.4)
cool = out * np.array([0.88, 0.87, 1.0]) + np.array([3, 2, 12])
out = np.where(warm[..., None], out, cool)
Image.fromarray(np.dstack([np.clip(out, 0, 255), alpha]).astype(np.uint8)).save(OUT + "maison.png")
print("maison (référence officielle) : %d×%d, faces couvrant %.0f %% de la silhouette" % (W, H, 100 * (covered & (alpha > 16)).sum() / max(1, (alpha > 16).sum())))
