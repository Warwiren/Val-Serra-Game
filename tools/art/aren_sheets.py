"""Extraction des planches de référence d'Aren (Drive « Aren », fournies par le créateur le 5/11/2026) :
sprites d'exploration (repos 4 vues, marche 4 directions × 4 images) et de combat (repos, avance, préparation,
attaque, impact, retour, garde, touché, Résonance charge/libération), portraits (6 expressions).
Pipeline identique au pack : détourage du fond, MÊME facteur d'échelle pour toutes les images (hauteur du héros
au repos = 37 px natifs, comme les autres personnages), couleur médiane par cellule, palette commune,
pieds ancrés au même point d'un canevas commun.
Usage : python3 aren_sheets.py <dossier_planches> <dossier_sortie> [--debug]
Puis : python3 aren_retouch.py <dossier_sortie>  (retouche pixel du visage et des contours)."""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

SRC, OUT = sys.argv[1], sys.argv[2]
DEBUG = "--debug" in sys.argv
HERO_H = 37
# Bandes (x0, y0, x1, y1) en pixels des planches 1448×1086 : une animation par bande, images de gauche à droite
EXPLO = {
    "idle_views": (384, 137, 1426, 326),          # Face, Dos, Profil G, Profil D
    "walk_face": (507, 410, 1426, 552), "walk_back": (507, 556, 1426, 698),
    "walk_left": (507, 702, 1426, 848), "walk_right": (507, 851, 1426, 1000),
}
COMBAT = {
    "repos": (14, 391, 449, 502), "avance": (463, 391, 970, 502), "preparation": (984, 391, 1433, 502),
    "attaque": (14, 557, 767, 668), "impact": (789, 557, 1433, 668),
    "retour": (14, 724, 709, 835), "garde": (731, 724, 1433, 835),
    "touche": (14, 890, 333, 1001), "res_charge": (355, 890, 825, 1001), "res_liberation": (847, 890, 1433, 1001),
}


def runs(m, axis):
    """Longueur de la suite continue de pixels allumés à laquelle appartient chaque pixel, le long d'un axe."""
    mm = m if axis == 1 else m.T
    out = np.zeros(mm.shape, int)
    for i, row in enumerate(mm):
        j = 0
        while j < len(row):
            if row[j]:
                k = j
                while k < len(row) and row[k]:
                    k += 1
                out[i, j:k] = k - j
                j = k
            else:
                j += 1
    return out if axis == 1 else out.T


def thin_lines(m):
    """Filets des cadres : longs (> 50 px) et fins (<= 4 px) — les sprites n'ont pas cette forme."""
    h, v = runs(m, 1), runs(m, 0)
    return ((h > 50) & (v <= 4)) | ((v > 50) & (h <= 4))


def sprites_in(img, box, min_h=45):
    x0, y0, x1, y1 = box
    a = img[y0:y1, x0:x1].astype(int)
    bg = np.median(np.concatenate([a[:3].reshape(-1, 3), a[-3:].reshape(-1, 3)]), axis=0)
    m = np.abs(a - bg).sum(-1) > 60
    # filets dorés des cadres : rangées / colonnes presque entièrement « allumées » -> retirées
    m &= ~thin_lines(m)
    lab, n = ndimage.label(ndimage.binary_dilation(m, iterations=4))
    out = []
    for sl in ndimage.find_objects(lab):
        h, w = sl[0].stop - sl[0].start, sl[1].stop - sl[1].start
        if h >= min_h and w >= 25:
            out.append((sl[1].start + x0, sl[0].start + y0, sl[1].stop + x0, sl[0].stop + y0))
    return sorted(out, key=lambda b: b[0]), bg


# Échelle : px de planche par pixel natif, pour que Aren DEBOUT mesure 37 px natifs dans toutes les sections.
# Exploration : repos debout 186 px ; marche : sprites de 138 px (posture de marche ≈ 0,97 de la hauteur debout).
# Combat : silhouette debout de référence 156 px dans l'en-tête, mais les lignes d'animation sont dessinées plus
# petites (repos combat 107 px, posture fléchie ≈ 0,92 de la hauteur debout).
# Aren (design élancé des nouvelles planches) est calibré sur 40 px natifs debout : à 37 px, sa silhouette fine
# paraissait nettement plus petite que celles, plus trapues, d'Ilya et Throné (comparaison en jeu, combat).
AREN_H = 40
# Combat : hauteur RÉELLE du personnage au repos de combat mesurée après détourage = 90 px de planche.
SCALE = {"idle_views": 186 / AREN_H, "walk": 138 / (AREN_H * 0.97), "combat": 90 / (AREN_H * 0.92)}
EQUAL_CELLS = {"res_charge": 6, "res_liberation": 6}       # effets fusionnés : découpage en cellules régulières
CANVAS = {"explo": (44, 46), "combat": (88, 60)}            # pieds au centre de la dernière rangée
PORTRAITS = {  # (x0, y0, x1, y1) planche « portraits » 1448×1086 : visage + épaules, sans l'étiquette
    "neutre": (558, 125, 805, 352), "determine": (850, 125, 1097, 352), "souriant": (1140, 125, 1387, 352),
    "surpris": (558, 442, 805, 669), "blesse": (850, 442, 1097, 669), "concentre": (1140, 442, 1387, 669),
}


def cutout(img, box, bg):
    x0, y0, x1, y1 = box
    a = img[y0:y1, x0:x1].astype(int)
    m = np.abs(a - bg).sum(-1) > 45
    m &= ~thin_lines(m)
    lab, n = ndimage.label(ndimage.binary_dilation(m, iterations=3))
    if n == 0:
        return a, m
    sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    keep = np.isin(lab, [i + 1 for i, sz in enumerate(sizes) if sz >= 0.08 * sizes.max()])
    m &= keep
    # les zones très sombres du personnage (pantalon, contours) ressemblent au fond : on referme la silhouette
    m = ndimage.binary_closing(m, iterations=2)
    # seuls les PETITS trous sont rebouchés (zones sombres du costume) ; les grands espaces enfermés
    # (entre les jambes, sous la cape) sont du fond et restent transparents
    holes = ndimage.binary_fill_holes(m) & ~m
    hl, hn = ndimage.label(holes)
    if hn:
        hs = ndimage.sum(np.ones_like(hl), hl, range(1, hn + 1))
        m |= np.isin(hl, [i + 1 for i, sz in enumerate(hs) if sz <= 40])
    return a, m


def reduce(a, m, f):
    H, W = m.shape
    nh, nw = int(np.ceil(H / f)), int(np.ceil(W / f))
    rgb = np.zeros((nh, nw, 3)); al = np.zeros((nh, nw), bool)
    for y in range(nh):
        for x in range(nw):
            y0, y1 = int(round(y * f)), int(round((y + 1) * f)); x0, x1 = int(round(x * f)), int(round((x + 1) * f))
            mm = m[y0:y1, x0:x1]
            if mm.size and mm.mean() >= 0.45:
                rgb[y, x] = np.median(a[y0:y1, x0:x1][mm], axis=0); al[y, x] = True
    return rgb, al


def place(rgb, al, canvas):
    W, H = canvas
    ys, xs = np.where(al)
    bottom = ys.max()
    feet = xs[ys >= bottom - max(2, int(0.12 * (bottom - ys.min())))]
    fx = int(round((feet.min() + feet.max()) / 2))
    out_rgb = np.zeros((H, W, 3)); out_al = np.zeros((H, W), bool)
    dy, dx = H - 1 - bottom, W // 2 - fx
    for y, x in zip(ys, xs):
        ty, tx = y + dy, x + dx
        if 0 <= ty < H and 0 <= tx < W:
            out_rgb[ty, tx] = rgb[y, x]; out_al[ty, tx] = True
    return out_rgb, out_al


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    frames = {}
    for sheet, bands in (("Aren_sprites_exploration.png", EXPLO), ("Aren_sprites_combat.png", COMBAT)):
        img = np.asarray(Image.open(os.path.join(SRC, sheet)).convert("RGB"))
        for name, box in bands.items():
            boxes, bg = sprites_in(img, box)
            if name in EQUAL_CELLS:
                n = EQUAL_CELLS[name]; w = (box[2] - box[0]) / n
                boxes = [(int(box[0] + i * w), box[1], int(box[0] + (i + 1) * w), box[3]) for i in range(n)]
            kind = "explo" if sheet.endswith("exploration.png") else "combat"
            f = SCALE["idle_views"] if name == "idle_views" else (SCALE["walk"] if name.startswith("walk") else SCALE["combat"])
            for i, b in enumerate(boxes):
                a, m = cutout(img, b, bg)
                rgb, al = reduce(a, m, f)
                frames[(kind, name, i)] = place(rgb, al, CANVAS[kind])
    # Palette commune (K = 64) sur toutes les images d'Aren
    allpx = np.concatenate([r[a] for r, a in frames.values()])
    rng = np.random.default_rng(3)
    K = 64
    c = allpx[rng.choice(len(allpx), K, replace=False)]
    for _ in range(25):
        lab = ((allpx[:, None] - c[None]) ** 2).sum(-1).argmin(1)
        for k in range(K):
            sel = allpx[lab == k]
            if len(sel):
                c[k] = sel.mean(0)
    names = {"idle_views": ["idle_face", "idle_back", "idle_left", "idle_right"]}
    for (kind, name, i), (rgb, al) in frames.items():
        out = np.zeros(rgb.shape[:2] + (4,), np.uint8)
        idx = ((rgb[al][:, None] - c[None]) ** 2).sum(-1).argmin(1)
        out[al, :3] = c[idx].astype(np.uint8); out[al, 3] = 255
        fn = names[name][i] if name in names else f"{name}_{i}"
        Image.fromarray(out, "RGBA").save(os.path.join(OUT, fn + ".png"))
    print("images :", len(frames))
    # Portraits (illustrés) : fond sombre détouré, 128 px de large
    sheet = np.asarray(Image.open(os.path.join(SRC, "Aren_portrait_expressions.png")).convert("RGB")).astype(np.float32)
    for k, (x0, y0, x1, y1) in PORTRAITS.items():
        a = sheet[y0:y1, x0:x1]
        Image.fromarray(a.astype(np.uint8)).resize((128, int(128 * (y1 - y0) / (x1 - x0))), Image.LANCZOS).save(os.path.join(OUT, f"portrait_{k}.png"))
    print("portraits :", len(PORTRAITS))
    # Respiration des repos d'exploration : haut du corps abaissé d'1 px (2e image du repos)
    for k in ("idle_right", "idle_left"):
        a = np.asarray(Image.open(os.path.join(OUT, k + ".png")).convert("RGBA")).copy()
        ys = np.where(a[..., 3].any(1))[0]
        w = int(ys.min() + (ys.max() - ys.min()) * 0.55)
        b = a.copy(); top = a[:w].copy(); b[:w] = 0
        b[1:w + 1] = np.where(top[..., 3:4] > 0, top, b[1:w + 1])
        Image.fromarray(b, "RGBA").save(os.path.join(OUT, k + "_1.png"))
