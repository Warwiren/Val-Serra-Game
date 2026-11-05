"""Décor de la zone (et de l'arène) à partir du panneau « Aperçu — Exploration » du pack.
1. Passage sur la MÊME grille de pixels que les sprites (1,73 px du pack par pixel natif, couleur médiane).
2. Retrait des éléments à ne pas figer dans le décor (4 personnages peints, bulle « … », mini-carte) par
   INPAINTING PAR EXEMPLES (type Criminisi) à la résolution native : chaque trou est comblé en recopiant de
   vrais motifs 7×7 de l'image, pris à hauteur voisine (même lumière, même perspective) — aucun lissage.
3. Cadrage 427×240 px natifs (= 1280×720 à l'échelle ×3) ; extension haut/bas par miroir assombri.
Usage : python3 pack_zone.py <pack.png> <sortie.png> [masque_debug.png]"""
import sys
import numpy as np
from numpy.lib.stride_tricks import sliding_window_view
from PIL import Image, ImageDraw

PACK, OUT = sys.argv[1], sys.argv[2]
im = Image.open(PACK).convert("RGB")
X0, Y0, X1, Y1 = 300, 161, 1100, 512
F = 1.73

# Masque dans les coordonnées du pack (ellipses + rectangles ajustés aux silhouettes, marge incluse)
mk = Image.new("L", im.size, 0)
d = ImageDraw.Draw(mk)
for (cx, cy, rx, ry) in [(489, 372, 38, 27), (565, 370, 31, 27), (648, 367, 37, 26), (993, 296, 30, 25)]:
    d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=255)
for (a, b, c, e) in [(440, 376, 536, 444), (532, 380, 601, 438), (606, 374, 696, 441),
                     (962, 296, 1028, 412), (955, 150, 1104, 233)]:
    d.rectangle((a, b, c, e), fill=255)
pan = np.asarray(im.crop((X0, Y0, X1, Y1))).astype(np.float32)
pm = np.asarray(mk.crop((X0, Y0, X1, Y1))) > 0
H, W = pan.shape[:2]
nh, nw = int(H / F), int(W / F)
nat = np.zeros((nh, nw, 3), np.float32)
hole = np.zeros((nh, nw), bool)
for y in range(nh):
    for x in range(nw):
        y0, y1 = int(round(y * F)), int(round((y + 1) * F)); x0, x1 = int(round(x * F)), int(round((x + 1) * F))
        nat[y, x] = np.median(pan[y0:y1, x0:x1].reshape(-1, 3), axis=0)
        hole[y, x] = pm[y0:y1, x0:x1].any()
if len(sys.argv) > 3:
    dbg = nat.copy(); dbg[hole] = (255, 0, 255)
    Image.fromarray(dbg.astype(np.uint8)).save(sys.argv[3])

# --- Zones sources autorisées par trou (coordonnées du pack) ----------------------------------------
def nat_rect(a, b, c, e):
    m = np.zeros((nh, nw), bool)
    m[max(0, int((b - Y0) / F)):int((e - Y0) / F) + 1, max(0, int((a - X0) / F)):int((c - X0) / F) + 1] = True
    return m


ALLOWED = {
    # groupe : végétation de gauche (sans le tronc) + sentier dégagé à droite (sans palissade/tonneaux/maison)
    "groupe": nat_rect(300, 300, 450, 440) | nat_rect(700, 404, 950, 460) | nat_rect(440, 438, 700, 470),
    # PNJ : mur, fenêtres et seuil de la maison
    "pnj": nat_rect(1020, 230, 1100, 470) | nat_rect(905, 330, 965, 470),
    # mini-carte : feuillage du haut, à gauche de la maison
    "carte": nat_rect(560, 161, 900, 260),
}
lab = np.zeros((nh, nw), int)
lab[hole & nat_rect(440, 330, 700, 445)] = 1
lab[hole & nat_rect(955, 260, 1035, 415)] = 2
lab[hole & nat_rect(950, 150, 1105, 235)] = 3
names = {1: "groupe", 2: "pnj", 3: "carte"}

# --- Inpainting par exemples ------------------------------------------------------------------
P = 4                                  # demi-taille du motif (9×9)


def inpaint(nat, hole, lab, names, allowed, row_win=8, col_win=220, patch=4):
    """Comble `hole` en recopiant des motifs réels de l'image ((2·patch+1)², sources limitées par `allowed`)."""
    global P
    P_save, P = P, patch
    nh, nw = hole.shape
    known = ~hole
    img = nat.copy()
    pad = lambda a, v: np.pad(a, ((P, P), (P, P)) + ((0, 0),) * (a.ndim - 2), constant_values=v)
    img_p = pad(img, 0.0)
    known_p = pad(known, False)
    fully_known = sliding_window_view(known_p, (2 * P + 1, 2 * P + 1)).all(axis=(-1, -2))
    patches = sliding_window_view(img_p, (2 * P + 1, 2 * P + 1), axis=(0, 1))
    step = 0
    while not known.all():
        kp = pad(known, False)
        nb = sum(np.roll(np.roll(kp, dy, 0), dx, 1) for dy in range(-P, P + 1) for dx in range(-P, P + 1))[P:-P, P:-P]
        front = (~known) & (nb > 0)
        ys, xs = np.where(front)
        k = np.argmax(nb[ys, xs])
        py, px = ys[k], xs[k]
        tgt = img_p[py:py + 2 * P + 1, px:px + 2 * P + 1]
        tk = known_p[py:py + 2 * P + 1, px:px + 2 * P + 1]
        ry0, ry1 = max(0, py - row_win), min(nh, py + row_win + 1)
        rx0, rx1 = max(0, px - col_win), min(nw, px + col_win + 1)
        cand_ok = fully_known[ry0:ry1, rx0:rx1].copy()
        rule = names.get(int(lab[py, px]))
        if rule:
            cand_ok &= allowed[rule][ry0:ry1, rx0:rx1]
            if not cand_ok.any():
                ry0, ry1, rx0, rx1 = 0, nh, 0, nw
                cand_ok = fully_known & allowed[rule]
        cand = patches[ry0:ry1, rx0:rx1].transpose(0, 1, 3, 4, 2)
        diff = ((cand - tgt[None, None]) ** 2).sum(-1) * tk[None, None]
        ssd = diff.sum(axis=(-1, -2))
        ssd = ssd + np.abs(np.arange(ry0, ry1) - py)[:, None] * 40.0
        ssd[~cand_ok] = np.inf
        by, bx = np.unravel_index(np.argmin(ssd), ssd.shape)
        src = cand[by, bx]
        fill = ~tk
        tgt[fill] = src[fill]
        known_p[py:py + 2 * P + 1, px:px + 2 * P + 1] |= True
        known = known_p[P:-P, P:-P].copy()
        yy0, yy1 = max(0, py - 2 * P), min(nh, py + 2 * P + 1)
        xx0, xx1 = max(0, px - 2 * P), min(nw, px + 2 * P + 1)
        fully_known[yy0:yy1, xx0:xx1] = sliding_window_view(known_p[yy0:yy1 + 2 * P, xx0:xx1 + 2 * P],
                                                            (2 * P + 1, 2 * P + 1)).all(axis=(-1, -2))
        step += 1
    out = img_p[P:-P, P:-P]
    P = P_save
    return out, step


img, step = inpaint(nat, hole, lab, names, ALLOWED)
print("motifs recopiés :", step)



# --- Cadrage 427×240 --------------------------------------------------------------------------------
TW, TH = 427, 240
cx = (nw - TW) // 2
img = img[:, cx:cx + TW]
top = (TH - nh) // 2
bot = TH - nh - top
# Extension haut/bas (brief P1, § 5) : plus de MIROIR (il créait une ligne de symétrie visible au bas de la scène).
# Les bandes manquantes sont reconstruites par recopie de motifs réels pris dans les rangées voisines.
full = np.zeros((TH, TW, 3), np.float32)
full[top:top + nh] = img[:TH - top - bot]
ext = np.zeros((TH, TW), bool); ext[:top] = True; ext[top + nh:] = True
elab = np.zeros((TH, TW), int); elab[:top] = 1; elab[top + nh:] = 2
src_top = np.zeros((TH, TW), bool); src_top[top:top + 40] = True
src_bot = np.zeros((TH, TW), bool); src_bot[top + nh - 40:top + nh] = True
full, st2 = inpaint(full, ext, elab, {1: "haut", 2: "bas"}, {"haut": src_top, "bas": src_bot}, row_win=40, col_win=427)
print("bandes haut/bas reconstruites :", st2, "motifs")

# --- Retouche finale (brief unifié v1.1, § 3.3) -----------------------------------------------------------
# L'effacement du garde peint avait laissé, à droite de la fenêtre, un fragment de fenêtre lumineuse aux bords
# déchiquetés (répétition visible). On prolonge la porte voisine : profil médian de ses planches verticales,
# une couleur par colonne (aucune période verticale), léger assombrissement vers le bas, poteau d'1 px.
full = np.clip(full, 0, 255).astype(np.uint8).astype(float)
prof = np.median(full[72:96, 382:398], axis=0)
PX0, PX1, PY0, PY1 = 368, 400, 82, 104
for x in range(PX0, PX1):
    for y in range(PY0, PY1):
        full[y, x] = prof[(x - 382) % 16] * (1.0 - 0.12 * (y - PY0) / (PY1 - PY0))
full[PY0:PY1, PX0] *= 0.6

# --- Sentier à gauche (P1 suite) ----------------------------------------------------------------------
# La zone reconstruite à l'emplacement du groupe peint formait un rectangle de pavés plus clair, bordé de
# coutures. Ce rectangle est resynthétisé avec de PETITS motifs (7×7) pris dans les parties saines du sentier,
# à la même hauteur (même lumière, même perspective) : adapté à une texture irrégulière de pavés.
path = np.zeros((TH, TW), bool)
path[150:187, 100:178] = True                  # rangées du sentier, au-dessus de la clôture du premier plan
src_ok = np.zeros((TH, TW), bool)
src_ok[146:190, 214:262] = True                # sentier d'origine intact (jamais reconstruit), même hauteur
full, st3 = inpaint(full.astype(np.float32), path, path.astype(int), {1: "sentier"}, {"sentier": src_ok},
                    row_win=4, col_win=200, patch=3)
print("sentier resynthétisé :", st3, "motifs")
Image.fromarray(np.clip(full, 0, 255).astype(np.uint8), "RGB").save(OUT)
print("décor natif :", full.shape[1], "x", full.shape[0], "| décalage vertical de la scène :", top, "| recadrage x :", cx)
