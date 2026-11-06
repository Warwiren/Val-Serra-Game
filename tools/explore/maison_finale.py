"""MAISON DÉFINITIVE de l'exploration : référence officielle (art/source/concepts_2026-11-07/maison_reference_officielle.webp)
posée sur la GÉOMÉTRIE EXACTE du gabarit (docs/media/gabarits_exploration/maison/) — silhouette, toit, ouvertures,
emprise, collisions et tri inchangés.
Chaque pixel prend sa matière dans la CARTE DES ZONES du gabarit (et non dans des quadrilatères approximatifs) :
  - toit (ardoise, mousse, poutre faîtière) : versant de la référence projeté par homographie sur le versant du
    gabarit ; la partie supérieure est donc entièrement refaite à partir du gabarit ;
  - cheminée : celle de la référence, dans le bloc de la cheminée du gabarit ;
  - murs : façade (transformation affine calée sur ses coins et ses 4 ouvertures) ou mur latéral gauche
    (homographie) selon le côté de l'arête d'angle ; ce qui, dans la référence, tombe AU-DESSUS de l'égout
    (toiture peinte) est remplacé par le mur réfléchi juste sous l'égout : plus de toit dessiné sur la façade ;
  - porte et 3 fenêtres de la référence dans les rectangles EXACTS du gabarit ;
  - avant-toit : bord de rive en bois sombre de 3 px et ombre portée douce sur les murs sous l'égout ;
  - éclairage : ombrage du gabarit (lune, contre-jour) appliqué légèrement, fenêtres chaudes conservées.
Sortie : art/explore_hd2d/illustre/maison.png
    python3 tools/explore/maison_finale.py"""
import json
import numpy as np
from PIL import Image, ImageFilter

OUT = "art/explore_hd2d/illustre/maison.png"
GAB = "docs/media/gabarits_exploration/"
REF = np.asarray(Image.open("art/source/concepts_2026-11-07/maison_reference_officielle.webp").convert("RGB")).astype(np.float32)
meta = json.load(open(GAB + "gabarits.json"))
box = meta["elements"]["maison"]["rectangle_ecran"]
full = np.asarray(Image.open(GAB + "maison/maison_complete_cadre_1408x800.png").convert("RGBA")).astype(np.float32)[box[1]:box[3], box[0]:box[2]]
zones = np.asarray(Image.open(GAB + "maison/maison_zones.png").convert("RGBA")).astype(np.float32)
leg = {k: np.array([int(v[i:i + 2], 16) for i in (1, 3, 5)], np.float32) for k, v in json.load(open(GAB + "legende_zones.json")).items()}
H, W = full.shape[:2]
alpha = full[..., 3]
yy, xx = np.mgrid[0:H, 0:W].astype(np.float64)


def zone(n, tol=45):
    return (np.abs(zones[..., :3] - leg[n]).sum(-1) < tol) & (zones[..., 3] > 100)


OX, OY = 40, 90                                           # coins relevés sur un recadrage (40, 90) de la planche
ROOF_SRC = [(65, 100), (690, 38), (805, 250), (195, 335)]
FAC_SRC = [(205, 352), (775, 270), (775, 690), (205, 775)]
LAT_SRC = [(45, 310), (205, 352), (205, 775), (45, 560)]
ROOF_SRC, FAC_SRC, LAT_SRC = [[(x + OX, y + OY) for x, y in p] for p in (ROOF_SRC, FAC_SRC, LAT_SRC)]
ROOF_DST = [(25, 35), (310, -5), (375, 105), (60, 160)]
FAC_DST = [(110, 151), (355, 108), (355, 300), (110, 355)]
LAT_DST = [(48, 100), (110, 151), (110, 355), (46, 228)]
REF_OPEN = {"etage": (488, 465, 575, 555), "rdc_g": (300, 615, 405, 730), "rdc_d": (652, 577, 760, 687), "porte": (458, 590, 595, 780)}


def homography(src, dst):
    A = []
    for (x, y), (u, v) in zip(src, dst):
        A += [[x, y, 1, 0, 0, 0, -u * x, -u * y, -u], [0, 0, 0, x, y, 1, -v * x, -v * y, -v]]
    h = np.linalg.svd(np.array(A, float))[2][-1]
    return (h / h[-1]).reshape(3, 3)


def apply(Hm, m):
    p = np.stack([xx[m], yy[m], np.ones(m.sum())]); q = Hm @ p
    return q[0] / q[2], q[1] / q[2]


def sample(img, x, y):
    x = np.clip(x, 0, img.shape[1] - 1.001); y = np.clip(y, 0, img.shape[0] - 1.001)
    x0 = np.floor(x).astype(int); y0 = np.floor(y).astype(int); fx = (x - x0)[..., None]; fy = (y - y0)[..., None]
    return (img[y0, x0] * (1 - fx) * (1 - fy) + img[y0, x0 + 1] * fx * (1 - fy) + img[y0 + 1, x0] * (1 - fx) * fy + img[y0 + 1, x0 + 1] * fx * fy)


ops = meta["ouvertures_maison_ecran"]


def gab_open(k):
    for o in ops:
        r = o["rectangle_dans_gabarit"]
        if k == "porte" and o["type"] == "porte":
            return r
        if o["type"] != "porte" and ((k == "etage" and r[1] < 230) or (k == "rdc_g" and r[1] >= 230 and r[0] < 200) or (k == "rdc_d" and r[1] >= 230 and r[0] >= 200)):
            return r


# façade : affine (orthographique) calée sur les coins + coins des ouvertures
s2, d2, w = list(FAC_SRC), list(FAC_DST), [1.0] * 4
for k in REF_OPEN:
    rs, rg = REF_OPEN[k], gab_open(k)
    for a, b in zip(((rs[0], rs[1]), (rs[2], rs[3]), (rs[0], rs[3]), (rs[2], rs[1])), ((rg[0], rg[1]), (rg[2], rg[3]), (rg[0], rg[3]), (rg[2], rg[1]))):
        s2.append(a); d2.append(b); w.append(3.0)
wa = np.array(w)[:, None]
FAC_H = np.vstack([np.linalg.lstsq(np.array([[x, y, 1] for x, y in d2]) * wa, np.array(s2) * wa, rcond=None)[0].T, [0, 0, 1]])
LAT_H = homography(LAT_DST, LAT_SRC)
ROOF_H = homography(ROOF_DST, ROOF_SRC)

solid = alpha > 16
roof = (zone("ardoise") | zone("mousse") | (zone("poutre") & (yy < 120))) & solid
chim = zone("pierre") & (yy < 100) & solid
roof &= ~chim
walls = solid & ~roof & ~chim
out = np.zeros((H, W, 3), np.float32)

# --- toit -----------------------------------------------------------------------------------------------------
qx, qy = apply(ROOF_H, roof)
out[roof] = sample(REF, qx, qy)


# --- murs : égout de la référence (ligne haute de chaque mur) ----------------------------------------------
def line_y(p, q, x):
    return p[1] + (q[1] - p[1]) * (x - p[0]) / (q[0] - p[0])


def walls_from(Hm, m, top_a, top_b):
    sx, sy = apply(Hm, m)
    eave = line_y(top_a, top_b, sx) + 10                   # sous l'égout et sa rive
    above = sy < eave
    sy = np.where(above, 2 * eave - sy, sy)                # mur réfléchi au lieu du toit peint
    return sample(REF, sx, sy)


left = xx < 110 + (yy - 151) * 0.0                          # arête d'angle verticale x = 110
lat = walls & left
fac = walls & ~left
out[lat] = walls_from(LAT_H, lat, LAT_SRC[0], LAT_SRC[1])
out[fac] = walls_from(FAC_H, fac, FAC_SRC[0], FAC_SRC[1])
# bande haute de la façade (entre l'égout et la sablière haute) : dans le gabarit c'est un enduit uni, plus haut
# que dans la référence. On la remplit d'enduit de la référence (texture prélevée sur une zone d'enduit nue,
# répétée en miroir, ombrée sous l'égout plus bas) : plus de toit ni de contreventement dédoublés sur la façade.
BEAM_G = ((112, 206), (355, 161))
band = fac & (yy < line_y(*BEAM_G, xx) - 3)                  # bande haute ET pignon droit sous le toit
PL = REF[436:466, 272:388]                                    # enduit patiné nu (sous l'égout, à gauche de l'oculus)
PL = np.concatenate([PL, PL[:, ::-1]], 1); PL = np.concatenate([PL, PL[::-1]], 0)
ty = (yy - 0.175 * (xx - 110)).astype(int) % PL.shape[0]       # rangées parallèles à l'égout
tx = xx.astype(int) % PL.shape[1]
out[band] = PL[ty[band], tx[band]] * 1.05
# oculus de la référence au milieu de la bande
OC = REF[400:431, 487:575]
cx, cy = 232, int((line_y((110, 151), (355, 108), 232) + line_y(*BEAM_G, 232)) / 2)
oc = np.asarray(Image.fromarray(OC.astype(np.uint8)).resize((46, 16), Image.LANCZOS)).astype(np.float32)
yy0, xx0 = cy - 8, cx - 23
el = ((np.mgrid[0:16, 0:46][1] - 22.5) / 23) ** 2 + ((np.mgrid[0:16, 0:46][0] - 7.5) / 8) ** 2 < 1.0
reg = out[yy0:yy0 + 16, xx0:xx0 + 46]
reg[el] = oc[el]


def paste(rect, crop, pad):
    x0, y0, x1, y1 = rect[0] - pad, rect[1] - pad, rect[2] + pad, rect[3] + pad
    c = REF[crop[1]:crop[3], crop[0]:crop[2]]
    out[y0:y1, x0:x1] = np.asarray(Image.fromarray(c.astype(np.uint8)).resize((x1 - x0, y1 - y0), Image.LANCZOS)).astype(np.float32)


for k in REF_OPEN:
    paste(gab_open(k), REF_OPEN[k], 1 if k == "porte" else 3)
ys, xs = np.nonzero(chim)
if len(xs):
    paste((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1), (610, 120, 680, 285), 0)

# --- avant-toit : rive en bois sombre + ombre portée sur les murs sous l'égout ------------------------------
roof_img = Image.fromarray((roof * 255).astype(np.uint8))
below = np.asarray(roof_img.transform(roof_img.size, Image.AFFINE, (1, 0, 0, 0, 1, -3))) > 0   # toit décalé de 3 px
rive = below & ~roof & walls                                 # bande de 3 px juste sous le bord du toit
out[rive] = out[rive] * 0.35 + np.array([46, 28, 24]) * 0.65
dist = np.zeros((H, W), np.float32)
acc = roof.copy()
for d in range(1, 15):                                       # ombre douce sur 14 px sous l'égout
    acc_s = np.zeros_like(acc); acc_s[d:] = roof[:-d]
    newly = acc_s & walls & (dist == 0)
    dist[newly] = d
sh = np.where(dist > 0, 0.68 + 0.32 * (dist / 14.0), 1.0)[..., None]
out = out * np.where(rive[..., None], 1.0, sh)

# --- lumière : ombrage doux du gabarit, crépuscule, fenêtres chaudes ---------------------------------------
lum = full[..., :3].mean(-1)
ref_l = np.percentile(lum[walls], 60) + 1
shade = np.clip(lum / ref_l, 0.75, 1.15) ** 0.5
warm = (out[..., 0] > 170) & (out[..., 0] > out[..., 2] * 1.4)
out = np.where(warm[..., None], out, out * shade[..., None] * np.array([0.88, 0.87, 1.0]) + np.array([3, 2, 12]))
a = alpha
Image.fromarray(np.dstack([np.clip(out, 0, 255), a]).astype(np.uint8)).save(OUT)
print("maison définitive : %d×%d (toit %d px, murs %d px, rive %d px)" % (W, H, roof.sum(), walls.sum(), rive.sum()))
