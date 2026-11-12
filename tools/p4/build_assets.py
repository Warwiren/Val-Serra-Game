#!/usr/bin/env python3
"""P4 — prépare les ressources de l'avant-poste (art/p4/).

  python3 tools/p4/build_assets.py <dossier des packs Drive>

1. COPIE sans retouche les packs Drive « À TESTER » : P4_MAT_v03 (sols, roche, eau, transitions), découpes
   P4_ENV_MODULES_v01 retenues (végétation, accessoires), pilotes P4_PILOTES_TECH_v01 (arbre en calques, falaise GLB).
2. GÉNÈRE les textures PROVISOIRES qu'aucun pack ne fournit sous forme exploitable (façade à colombages, toiture
   violette moussue, porte, fenêtre, platelage de pont, intérieur) : motifs procéduraux, à remplacer par des
   peintures validées. Les planches BAT-REF / BRI-REF sont des concepts sur fond peint : elles ont servi de
   référence de style et de proportions, pas de source de pixels.
3. DÉRIVE l'Ilya provisoire du sprite fonctionnel existant (recoloration bleu nuit + cuir, cheveux raccourcis).
Le script est déterministe (graine fixe)."""
import os, shutil, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SRC = sys.argv[1] if len(sys.argv) > 1 else "/home/user/drive_p4"
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
OUT = os.path.join(ROOT, "art", "p4")
rng = np.random.default_rng(4072)


def d(*p):
    q = os.path.join(OUT, *p)
    os.makedirs(os.path.dirname(q), exist_ok=True)
    return q


def copy(src, *dst):
    shutil.copyfile(os.path.join(SRC, src), d(*dst))


def noise(w, h, scale, octaves=3):
    """Bruit de valeur périodique (raccord aux bords)."""
    out = np.zeros((h, w))
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        n = max(2, int(scale * 2 ** o))
        g = rng.random((n, n))
        g = np.pad(g, ((0, 1), (0, 1)), mode="wrap")
        im = Image.fromarray((g * 255).astype(np.uint8)).resize((w + w // n, h + h // n), Image.BICUBIC)
        out += np.asarray(im, dtype=float)[:h, :w] / 255.0 * amp
        tot += amp
        amp *= 0.5
    return out / tot


def save(arr, *p):
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).save(d(*p))


# ------------------------------------------------------------------ 1. copies
for a, b in [("SOL-01_herbe", "sol_herbe"), ("SOL-02_terre", "sol_terre"), ("SOL-03_paves", "sol_paves"),
             ("REL-01_roche", "roche"), ("EAU-01_courante", "eau_courante"), ("EAU-02_galets", "eau_galets"),
             ("TRS-01_herbe_terre", "trs_herbe_terre"), ("BER-01_berge", "berge")]:
    copy("mat/%s.png" % a, "mat", b + ".png")
VEG = ["ARB-02_rond", "ARB-03_foret", "ARB-04_jeune", "ARB-05_fleuri", "BUIS-01_violet", "BUIS-02_dense",
       "BUIS-05_pourpre", "HERB-02_touffe", "FLEUR-04_lavande", "FLEUR-01_marguerites", "ROC-01_rocher",
       "ROSE-01_massette"]
PROPS = ["LANT-01_lanterne", "BANN-02_bleue", "CAIS-01_caisse", "TONT-01_tonneau", "SAC-01_sacs", "BANC-01_banc",
         "CLOT-01_cloture", "BOIS-02_buches", "CHART-01_chariot", "PAN-01_panneau"]
for n in VEG:
    copy("env/%s.png" % n, "vegetation", n.split("_", 1)[0].lower().replace("-", "") + "_" + n.split("_", 1)[1] + ".png")
for n in PROPS:
    copy("env/%s.png" % n, "props", n.split("_", 1)[0].lower().replace("-", "") + "_" + n.split("_", 1)[1] + ".png")
for n in ["tronc", "feuillage_avant", "feuillage_arriere"]:
    copy("arb/%s.png" % n, "arbre", "arb01_%s.png" % n)
copy("rel/REL-01.glb", "relief", "rel01_mur_4m_h120.glb")

# ------------------------------------------------------------------ 2. textures provisoires
# toiture : tuiles violettes en écailles, mousse par plaques
W = 256
y, x = np.mgrid[0:W, 0:W]
row = y // 16
xo = (x + (row % 2) * 12) % 24
ty = y % 16
edge = (np.abs(xo - 12) / 12.0) ** 2 * 5 + ty                      # bas de tuile arrondi
tile_id = (row * 37 + ((x + (row % 2) * 12) // 24) * 11) % 97
var = (np.sin(tile_id * 12.9898) * 43758.5453) % 1.0
base = np.stack([84 + var * 26, 58 + var * 16, 122 + var * 30], -1)
shade = np.where(edge > 15.5, 0.45, np.where(ty < 3, 0.72, 1.0 + (ty - 8) * 0.012))
roof = base * shade[..., None]
moss = noise(W, W, 9, 3)
mm = np.clip((moss - 0.6) * 7, 0, 1)[..., None] * (0.55 + 0.45 * (ty[..., None] > 5))
mossc = np.stack([62 + moss * 34, 92 + moss * 40, 44 + moss * 16], -1)
roof = roof * (1 - mm * 0.75) + mossc * mm * 0.75
save(roof, "batiment", "toit_violet.png")

# façade : torchis clair + colombages ; 256 px = 4 m de large, 128 px = 2 m de haut (64 px/m)
fw, fh = 256, 128
pl = 205 + noise(fw, fh, 6, 3) * 40
fac = np.stack([pl * 1.0, pl * 0.93, pl * 0.78], -1)
img = Image.fromarray(np.clip(fac, 0, 255).astype(np.uint8))
dr = ImageDraw.Draw(img)
BEAM, BEAM_D = (98, 62, 40), (66, 40, 28)
for bx in [0, 64, 128, 192]:
    dr.rectangle([bx - 5, 0, bx + 5, fh], fill=BEAM)
    dr.line([bx + 5, 0, bx + 5, fh], fill=BEAM_D)
dr.rectangle([251, 0, 256, fh], fill=BEAM)
for by in [0, 58, 122]:
    dr.rectangle([0, by, fw, by + 9 if by else 6], fill=BEAM)
    dr.line([0, (by + 9 if by else 6), fw, (by + 9 if by else 6)], fill=BEAM_D)
dr.line([8, 120, 58, 68], fill=BEAM, width=7)
dr.line([200, 68, 248, 120], fill=BEAM, width=7)
dr.line([72, 56, 120, 8], fill=BEAM, width=7)
dr.line([136, 8, 184, 56], fill=BEAM, width=7)
fa = np.asarray(img, dtype=float)
fa *= (0.9 + noise(fw, fh, 24, 2)[..., None] * 0.2)
save(fa, "batiment", "facade_colombage.png")

# porte cintrée (64 × 104 px = 1,2 × 1,95 m) et fenêtre chaude (40 × 48 px)
dw, dh = 64, 104
im = Image.new("RGBA", (dw, dh), (0, 0, 0, 0))
dr = ImageDraw.Draw(im)
dr.rounded_rectangle([0, 0, dw - 1, dh + 30], 30, fill=(120, 112, 118, 255))            # encadrement de pierre
dr.rounded_rectangle([7, 8, dw - 8, dh + 30], 24, fill=(96, 60, 38, 255))
for px in range(11, dw - 8, 9):
    dr.line([px, 10, px, dh], fill=(64, 38, 26, 255))
dr.line([dw // 2, 8, dw // 2, dh], fill=(40, 24, 18, 255), width=2)
for hy in [34, 78]:
    dr.rectangle([8, hy, dw - 9, hy + 4], fill=(52, 50, 58, 255))
dr.ellipse([dw // 2 + 4, 58, dw // 2 + 9, 63], fill=(214, 176, 96, 255))
im.save(d("batiment", "porte.png"))
ww, wh = 40, 48
im = Image.new("RGBA", (ww, wh), (0, 0, 0, 0))
dr = ImageDraw.Draw(im)
dr.rectangle([0, 0, ww - 1, wh - 1], fill=(84, 52, 34, 255))
g = np.zeros((wh, ww, 4))
yy, xx = np.mgrid[0:wh, 0:ww]
glow = 1.0 - np.hypot((xx - ww / 2) / ww, (yy - wh * 0.6) / wh) * 1.1
g[..., 0] = 255
g[..., 1] = 178 + glow * 60
g[..., 2] = 70 + glow * 90
g[..., 3] = 255
pane = Image.fromarray(np.clip(g, 0, 255).astype(np.uint8))
im.paste(pane.crop((4, 4, ww - 4, wh - 5)), (4, 4))
dr.line([ww // 2, 4, ww // 2, wh - 5], fill=(84, 52, 34, 255), width=2)
dr.line([4, wh // 2 - 2, ww - 5, wh // 2 - 2], fill=(84, 52, 34, 255), width=2)
dr.rectangle([0, wh - 5, ww - 1, wh - 1], fill=(120, 112, 118, 255))
im.save(d("batiment", "fenetre.png"))

# bois : planches (256 px = 2 m ; planches de 25 cm) — platelage du pont, plancher intérieur, poutres
pw = 256
yy, xx = np.mgrid[0:pw, 0:pw]
pid = xx // 32
pv = ((np.sin(pid * 78.233 + 3.1) * 43758.5453) % 1.0)
grain = noise(pw, pw, 3, 2)
grain_l = np.asarray(Image.fromarray((noise(pw, 16, 3, 2) * 255).astype(np.uint8)).resize((pw, pw), Image.BICUBIC), dtype=float) / 255.0
wood = np.stack([138 + pv * 34, 92 + pv * 24, 56 + pv * 16], -1) * (0.82 + grain_l.T[..., None] * 0.3 + grain[..., None] * 0.08)
gap = (xx % 32 < 2)
wood[gap] *= 0.35
hl = (xx % 32 == 2)
wood[hl] *= 1.12
for py in [20, 236]:
    nail = (np.abs(yy - py) < 2) & (np.abs(xx % 32 - 16) < 2)
    wood[nail] = (58, 52, 56)
save(wood, "pont", "planches.png")

# pierre de taille (murailles, soubassement) : assises de moellons, 256 px = 2 m
sw = 256
st = np.zeros((sw, sw, 3))
yy, xx = np.mgrid[0:sw, 0:sw]
rowh = 32
r = yy // rowh
bx = (xx + (r % 2) * 28 + ((r * 13) % 5) * 6) % sw
bw = 56
bid = r * 31 + (bx // bw) * 7
bv = ((np.sin(bid * 12.9898 + 1.7) * 43758.5453) % 1.0)
n1 = noise(sw, sw, 10, 3)
stone = np.stack([122 + bv * 34, 114 + bv * 30, 128 + bv * 34], -1) * (0.8 + n1[..., None] * 0.4)
joint = (yy % rowh < 3) | (bx % bw < 3)
stone[joint] = stone[joint] * 0.42
top = (yy % rowh == 3) | (bx % bw == 3)
stone[top] *= 1.15
ms = noise(sw, sw, 4, 3)
mk = np.clip((ms - 0.62) * 8, 0, 1)[..., None]
stone = stone * (1 - mk * 0.55) + np.stack([70 + ms * 26, 96 + ms * 34, 52 + ms * 10], -1) * mk * 0.55
save(stone, "batiment", "pierre_taille.png")

# halo doux (lanternes, fenêtres) et ombre de contact
hw = 64
yy, xx = np.mgrid[0:hw, 0:hw]
rr = np.hypot(xx - hw / 2 + 0.5, yy - hw / 2 + 0.5) / (hw / 2)
a = np.clip(1 - rr, 0, 1) ** 2.2
save(np.stack([np.full_like(a, 255), np.full_like(a, 255), np.full_like(a, 255), a * 255], -1), "fx", "halo.png")

# ------------------------------------------------------------------ 3. Ilya provisoire
SRC_ILYA = os.path.join(ROOT, "art", "explore_hd2d", "chars", "ilya")
for f in ["idle", "idle_1", "walk_0", "walk_1", "walk_2", "walk_3"]:
    im = np.asarray(Image.open(os.path.join(SRC_ILYA, f + ".png")).convert("RGBA"), dtype=float).copy()
    h, w = im.shape[:2]
    r_, g_, b_, a_ = im[..., 0], im[..., 1], im[..., 2], im[..., 3]
    lum = 0.3 * r_ + 0.5 * g_ + 0.2 * b_
    yy, xx = np.mgrid[0:h, 0:w]
    # tenue : bordeaux (b/r > 0,5, rouge dominant) -> bleu nuit ; le cuir brun (b/r < 0,45) est conservé
    maroon = (a_ > 40) & (r_ > g_ * 1.35) & (b_ > r_ * 0.5) & (r_ < 190) & (b_ < r_ * 1.05)
    # cheveux longs : mèches claires sous la nuque -> manteau bleu nuit (coupe courte validée)
    hair = (a_ > 40) & (np.minimum(np.minimum(r_, g_), b_) > 70) & (np.abs(r_ - b_) < 40) & (g_ < r_ + 6)
    long_hair = hair & (yy > h * 0.44) & (xx < w * 0.40)
    dark_hair = (a_ > 40) & (yy > h * 0.44) & (yy < h * 0.80) & (xx < w * 0.30) & (b_ > g_ * 1.1) & (lum < 110)
    sel = maroon | long_hair | dark_hair
    l2 = np.where(long_hair, lum * 0.45, lum) / 255.0
    navy = np.stack([22 + l2 * 95, 30 + l2 * 125, 62 + l2 * 235], -1)
    im[..., :3] = np.where(sel[..., None], navy, im[..., :3])
    Image.fromarray(np.clip(im, 0, 255).astype(np.uint8)).save(d("chars", "ilya", f + ".png"))
print("art/p4 prêt :", sum(len(fs) for _, _, fs in os.walk(OUT)), "fichiers")
