#!/usr/bin/env python3
"""P4.5 — construit art/p45/ : personnages d'exploration (Aren, Ilya, garde), combat (Aren, Ilya), portraits.

  python3 tools/p45/build_p45.py <dossier des sources>
      <src>/p43/ValSerra_P43_ANIMATIONS_QA_v01_A_TESTER/{aren_gray_corrige_4dir_5frames.png, ilya/ilya_exploration_4dir_5frames_RGBA.png}
      <src>/garde/garde/combat/frames/{down,up,left,right}_{0..4}.png, <src>/garde/garde/portraits/neutre.png
      <src>/aren/Aren_sprites_combat.png      (planche de combat d'origine, Drive Art/Aren)
      <src>/p44/manifest.json, <src>/p44/atlases/ilya_<séquence>_strip_192.png   (pack P4_4_ILYA_AETHER_COMBAT_v01)
      <src>/p42/{aren,ilya}_portraits/*.png    (pack P4_2_COMBAT_PORTRAITS_v01)

Principes (mêmes que P4.1 / P4.4) : réduction par couleur médiane, jamais d'agrandissement ; palette commune par
personnage ; ancrage fixe. Nouveautés P4.5 :
  - exploration à 1 pixel de sprite = 1 pixel d'écran au zoom ×2,5 (Aren 70 px, Ilya 65, garde 75) ;
  - alignement des images de marche sur la TÊTE (et non sur les pieds, qui bougent) : plus de sauts latéraux ;
  - ombres portées peintes retirées des sources (garde) ;
  - attente : 8 images par direction, dérivées de la pose de repos par décalages d'un pixel (respiration, transfert
    du poids, mèche / cape) — animation PROCÉDURALE, pas un dessin image par image ;
  - combat d'Aren redécoupé dans la planche d'origine (les bandes du pack P4.2 coupaient l'épée et les arcs),
    bleu recoloré en gris comme P4.2 ;
  - combat d'Ilya : attente avec respiration, recul du bras au tir, K.O. reposé au sol."""
import json, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import planche  # noqa: E402

SRC = sys.argv[1]
ROOT = os.path.join(HERE, "..", "..")
OUT = os.path.join(ROOT, "art", "p45")
DIRS = ["face", "back", "left", "right"]          # lignes des packs : down, up, left, right
CANVAS = (128, 96)


# ------------------------------------------------------------------------------------------------ outils
def reduce(rgba, f):
    H, W = rgba.shape[:2]
    nh, nw = int(np.ceil(H / f)), int(np.ceil(W / f))
    out = np.zeros((nh, nw, 4), np.uint8)
    a = rgba[..., 3] > 110
    for y in range(nh):
        y0, y1 = int(round(y * f)), min(H, int(round((y + 1) * f)))
        for x in range(nw):
            x0, x1 = int(round(x * f)), min(W, int(round((x + 1) * f)))
            m = a[y0:y1, x0:x1]
            if m.size and m.mean() >= 0.45:
                out[y, x, :3] = np.median(rgba[y0:y1, x0:x1, :3][m], axis=0)
                out[y, x, 3] = 255
    return out


def palette(imgs, K, seed=7):
    px = np.concatenate([i[i[..., 3] > 0][:, :3] for i in imgs]).astype(float)
    rng = np.random.default_rng(seed)
    c = px[rng.choice(len(px), min(K, len(px)), replace=False)]
    for _ in range(30):
        lab = ((px[:, None] - c[None]) ** 2).sum(-1).argmin(1)
        for k in range(len(c)):
            s = px[lab == k]
            if len(s):
                c[k] = s.mean(0)
    return c


def quantize(img, pal, edge_k=0.6, edge_min=90):
    out = img.copy()
    m = out[..., 3] > 0
    if m.any():
        idx = ((out[m][:, :3].astype(float)[:, None] - pal[None]) ** 2).sum(-1).argmin(1)
        out[m, :3] = pal[idx].astype(np.uint8)
    a = out[..., 3] > 0
    n = sum(np.roll(np.roll(a, dy, 0), dx, 1) for dy in (-1, 0, 1) for dx in (-1, 0, 1)) - a
    out[a & (n <= 1)] = 0
    a = out[..., 3] > 0
    edge = a & ~(np.roll(a, 1, 0) & np.roll(a, -1, 0) & np.roll(a, 1, 1) & np.roll(a, -1, 1))
    light = edge & (out[..., :3].astype(float).mean(-1) > edge_min)
    out[light, :3] = (out[light, :3] * edge_k).astype(np.uint8)
    return out


def clean_source(rgba):
    """Ombre portée peinte (sombre et translucide) et fragments isolés retirés."""
    a = rgba.copy()
    lum = a[..., :3].astype(int).sum(-1) / 3
    shadow = ((a[..., 3] < 200) & (lum < 70)) | (a[..., 3] < 60)
    a[shadow, 3] = 0
    m = a[..., 3] > 110
    lab, n = ndimage.label(m)
    if n > 1:
        sz = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
        big = ndimage.binary_dilation(lab == int(np.argmax(sz)) + 1, iterations=6)
        keep = [i + 1 for i in range(n) if sz[i] >= 0.01 * sz.max() and (big & (lab == i + 1)).any()]
        a[~np.isin(lab, keep), 3] = 0
    return a


def torso_x(img):
    """Repère horizontal d'une image de marche : centre de la TÊTE (14 % supérieurs de la silhouette). La cape et les
    bras, qui flottent, faussaient le centre du torse (saut de 11 px chez Aren de profil) ; la tête est ce que
    l'œil suit."""
    ys, xs = np.where(img[..., 3] > 0)
    top, bot = ys.min(), ys.max()
    band = img[top: top + max(3, int((bot - top) * 0.14)) + 1, :, 3] > 0
    cols = np.where(band.any(0))[0]
    return (cols.min() + cols.max()) / 2.0, bot


def height(a):
    ys = np.where((a[..., 3] > 110).any(1))[0]
    return ys.max() - ys.min() + 1


def head_w(a):
    """Largeur de la tête (15 % supérieurs de la silhouette) : repère d'échelle stable d'une image de marche à l'autre."""
    m = a[..., 3] > 110
    ys = np.where(m.any(1))[0]
    t, h = ys.min(), ys.max() - ys.min() + 1
    return max(np.ptp(np.where(m[y])[0]) + 1 for y in range(t, t + max(2, int(h * 0.15))))


def reduce2(rgba, fy, fx):
    """Comme reduce(), avec des facteurs vertical et horizontal distincts (toujours une réduction)."""
    H, W = rgba.shape[:2]
    nh, nw = int(np.ceil(H / fy)), int(np.ceil(W / fx))
    out = np.zeros((nh, nw, 4), np.uint8)
    a = rgba[..., 3] > 110
    for y in range(nh):
        y0, y1 = int(round(y * fy)), min(H, int(round((y + 1) * fy)))
        for x in range(nw):
            x0, x1 = int(round(x * fx)), min(W, int(round((x + 1) * fx)))
            m = a[y0:y1, x0:x1]
            if m.size and m.mean() >= 0.45:
                out[y, x, :3] = np.median(rgba[y0:y1, x0:x1, :3][m], axis=0)
                out[y, x, 3] = 255
    return out


def idle_to_walk_scale(idle, walks, f, name="", d=""):
    """P4.6 — taille constante entre l'attente et la marche. Dans le pack P4.3 d'Aren, la pose de repos est dessinée
    plus petite que les pas (tête et épaules ~18 % plus petites, jambes plus longues) : le personnage « grandissait »
    en démarrant. Si l'écart de tête dépasse 6 %, le haut du corps (tête, épaules, buste jusqu'à la taille) est réduit
    à l'échelle des pas, et les jambes sont tassées verticalement pour que la hauteur totale égale celle des pas.
    Toujours une réduction (aucun agrandissement)."""
    s = np.median([head_w(w) for w in walks]) / head_w(idle)
    if abs(s - 1) <= 0.06:
        return reduce(idle, f)
    ys = np.where((idle[..., 3] > 110).any(1))[0]
    t, b = ys.min(), ys.max()
    cut = t + int((b - t) * 0.45)                     # taille (ceinture)
    fu = f / s
    up = reduce2(idle[:cut], fu, fu)[:int(round(cut / fu))]
    rest = np.median([height(w) for w in walks]) / f - (cut - t) / fu
    lo = reduce2(idle[cut:], (b + 1 - cut) / rest, fu)
    w = max(up.shape[1], lo.shape[1])
    out = np.zeros((up.shape[0] + lo.shape[0], w, 4), np.uint8)
    out[:up.shape[0], :up.shape[1]] = up
    out[up.shape[0]:, :lo.shape[1]] = lo
    print("   %s %s : repos remis à l'échelle des pas (tête ×%.2f, jambes tassées)" % (name, d, s))
    return out


def place(img, ax, ay, canvas=CANVAS):
    W, H = canvas
    out = np.zeros((H, W, 4), np.uint8)
    dx, dy = W // 2 - int(round(ax)), H - 1 - int(round(ay))
    ys, xs = np.where(img[..., 3] > 0)
    tx, ty = xs + dx, ys + dy
    ok = (tx >= 0) & (tx < W) & (ty >= 0) & (ty < H)
    out[ty[ok], tx[ok]] = img[ys[ok], xs[ok]]
    lost = int((~ok).sum())
    if lost:
        print("   ! rogné : %d px" % lost)
    return out, lost


def save(img, *p):
    path = os.path.join(OUT, *p)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    Image.fromarray(img, "RGBA").save(path)


def shift_rows(img, y0, y1, dx, dy):
    """Déplace les pixels des rangées [y0, y1[ de (dx, dy) ; le reste de l'image est inchangé."""
    out = img.copy()
    part = img[y0:y1].copy()
    out[y0:y1][part[..., 3] > 0] = 0
    ys, xs = np.where(part[..., 3] > 0)
    ty, tx = ys + y0 + dy, xs + dx
    ok = (ty >= 0) & (ty < img.shape[0]) & (tx >= 0) & (tx < img.shape[1])
    out[ty[ok], tx[ok]] = part[ys[ok], xs[ok]]
    return out


def idle_cycle(base, sway_sign=1):
    """8 images d'attente dérivées de la pose de repos : respiration (haut du corps abaissé d'1 px), transfert du
    poids (haut du corps décalé d'1 px), mèche / haut de cape décalé d'1 px. Les pieds ne bougent jamais."""
    ys = np.where(base[..., 3].any(1))[0]
    top, bot = ys.min(), ys.max()
    h = bot - top
    chest = top + int(h * 0.58)          # au-dessus : buste, bras, tête
    hair = top + int(h * 0.16)           # au-dessus : cheveux / heaume
    breath = shift_rows(base, 0, chest, 0, 1)
    sway = shift_rows(base, 0, chest, sway_sign, 0)
    sway_b = shift_rows(sway, 0, chest, 0, 1)
    flick = shift_rows(breath, 0, hair, sway_sign, 0)
    return [base, base, breath, breath, base, sway, sway_b, flick]


# ------------------------------------------------------------------------------------------------ exploration
def exploration(name, frames, target, edge=(0.6, 90), sway_sign=1):
    """frames : {direction: [repos, marche0..3]} (sources RGBA). Hauteur de marche ramenée à `target` px."""
    cleaned = {d: [clean_source(f) for f in fs] for d, fs in frames.items()}
    walk_h = np.median([height(f) for fs in cleaned.values() for f in fs[1:]])
    f = walk_h / target
    out, lost = {}, 0
    for d, fs in cleaned.items():
        for i, src in enumerate(fs):
            r = reduce(src, f) if i else idle_to_walk_scale(src, fs[1:], f, name, d)
            ax, ay = torso_x(r)
            img, l = place(r, ax, ay)
            lost += l
            out["idle_%s" % d if i == 0 else "walk_%s_%d" % (d, i - 1)] = img
    pal = palette(list(out.values()), 112)
    q = {k: quantize(v, pal, *edge) for k, v in out.items()}
    for k, v in q.items():
        save(v, "chars", name, k + ".png")
    for d in DIRS:
        cyc = idle_cycle(q["idle_%s" % d], sway_sign if d != "left" else -sway_sign)
        for i, img in enumerate(cyc[1:], 1):
            save(img, "chars", name, "idle_%s_%d.png" % (d, i))
    print("%-6s exploration : réduction ×1/%.2f -> %d px, %d images, rognage %d px" % (name, f, target, len(q) + 28, lost))


def grid(path, cw, ch):
    im = np.asarray(Image.open(path).convert("RGBA"))
    return {DIRS[r]: [im[r * ch:(r + 1) * ch, c * cw:(c + 1) * cw] for c in range(5)] for r in range(4)}


# ------------------------------------------------------------------------------------------------ combat d'Aren
BANDS = {
    "repos": (14, 380, 449, 504), "avance": (463, 380, 970, 504), "preparation": (984, 380, 1433, 504),
    "attaque": (14, 548, 767, 670), "impact": (789, 548, 1433, 670),
    "retour": (14, 713, 709, 837), "garde": (731, 713, 1433, 837),
    "touche": (14, 880, 333, 1003), "res_charge": (355, 880, 825, 1003), "res_liberation": (847, 880, 1433, 1003),
}
EQUAL = {"res_charge": 6, "res_liberation": 6}
COUNT = {"repos": 4, "avance": 6, "preparation": 5, "attaque": 6, "impact": 4, "retour": 5, "garde": 4, "touche": 4}


def to_gray(rgb):
    """Bleu de l'écharpe et de la cape -> gris neutre (même choix que le pack P4.2) ; cyan d'Aether conservé."""
    f = rgb.astype(float) / 255.0
    mx, mn = f.max(-1), f.min(-1)
    d = np.maximum(mx - mn, 1e-6)
    r, g, b = f[..., 0], f[..., 1], f[..., 2]
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    s = (mx - mn) / np.maximum(mx, 1e-6)
    blue = (h > 205) & (h < 280) & (s > 0.18)
    lum = 0.3 * f[..., 0] + 0.55 * f[..., 1] + 0.15 * f[..., 2]
    grey = np.stack([lum * 0.97, lum, lum * 1.05], -1) * 0.95
    out = np.where(blue[..., None], grey, f)
    return np.clip(out * 255, 0, 255).astype(np.uint8)


def equal_band(img, box, bg, n):
    """Bande « Résonance » : les effets d'Aether débordent d'une cellule à l'autre et relient les personnages.
    Repères : peau et cheveux (bruns, chauds), qui ne se touchent jamais d'un personnage à l'autre. Chaque fragment
    contenu dans une cellule va au repère le plus proche ; un fragment qui relie plusieurs personnages (effet) est
    partagé pixel par pixel selon le repère le plus proche. Étiquettes au-dessus des têtes écartées."""
    x0, y0, x1, y1 = box
    a, m = planche.cutout(img, box, bg)
    f = np.clip(a, 0, 255).astype(float) / 255.0
    mx, mn = f.max(-1), f.min(-1)
    d = np.maximum(mx - mn, 1e-6)
    r, g, b = f[..., 0], f[..., 1], f[..., 2]
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    s = (mx - mn) / np.maximum(mx, 1e-6)
    warm = m & (h < 40) & (s > 0.3) & (mx > 0.3)
    cyan = m & (h > 170) & (h < 215) & (s > 0.25) & (mx > 0.45)
    w = (x1 - x0) / n
    lab, k = ndimage.label(ndimage.binary_closing(warm, iterations=2), structure=np.ones((3, 3)))
    sz = ndimage.sum(np.ones_like(lab), lab, range(1, k + 1))
    com = ndimage.center_of_mass(warm, lab, range(1, k + 1))
    seeds = []
    for c in range(n):
        cand = [j for j in range(k) if c * w <= com[j][1] < (c + 1) * w]
        seeds.append(lab == max(cand, key=lambda j: sz[j]) + 1)
    dist = np.stack([ndimage.distance_transform_edt(~sd) for sd in seeds])
    owner = np.argmin(dist, axis=0)
    top = min(np.where(sd)[0].min() for sd in seeds) - 22          # au-dessus : étiquettes de la planche
    lab2, k2 = ndimage.label(m, structure=np.ones((3, 3)))
    masks = [np.zeros_like(m) for _ in range(n)]
    for j in range(k2):
        cm = lab2 == j + 1
        ys, xs = np.where(cm)
        if ys.max() < top or len(ys) < 4:
            continue
        if xs.max() - xs.min() < 0.9 * w:
            c = int(np.bincount(owner[cm], minlength=n).argmax())
            masks[c] |= cm
        else:
            # fragment qui relie plusieurs personnages : les parties non cyan sont partagées pixel par pixel ; chaque
            # nappe d'effet cyan reste ENTIÈRE et va au personnage qui en possède la plus grande part
            cy = cm & cyan
            for c in range(n):
                masks[c] |= cm & ~cy & (owner == c)
            lc, kc = ndimage.label(cy, structure=np.ones((3, 3)))
            for q in range(kc):
                qm = lc == q + 1
                c = int(np.bincount(owner[qm], minlength=n).argmax())
                masks[c] |= qm
    out = []
    for c in range(n):
        # nettoyage : garder la composante du corps et les nappes d'effet substantielles (≥ 15 px cyan) ; les
        # liserés orphelins d'un effet voisin et les miettes partent
        lc, kc = ndimage.label(masks[c], structure=np.ones((3, 3)))
        body = int(np.bincount(lc[seeds[c] & masks[c]], minlength=kc + 1)[1:].argmax()) + 1
        keep = [q + 1 for q in range(kc) if q + 1 == body or (cyan & (lc == q + 1)).sum() >= 15]
        masks[c] = np.isin(lc, keep)
        rgba = np.zeros(a.shape[:2] + (4,), np.uint8)
        rgba[..., :3] = to_gray(np.clip(a, 0, 255).astype(np.uint8))
        rgba[..., 3] = np.where(masks[c], 255, 0)
        ys, xs = np.where(masks[c])
        out.append(rgba[max(0, ys.min() - 2):ys.max() + 3, max(0, xs.min() - 2):xs.max() + 3])
    return out


def aren_combat(target=56):
    img = np.asarray(Image.open(os.path.join(SRC, "aren", "Aren_sprites_combat.png")).convert("RGB"))
    cuts = {}
    for name, box in BANDS.items():
        boxes, bg = planche.sprites_in(img, box, min_h=40)
        if name in EQUAL:
            # effets d'Aether qui débordent d'une cellule à l'autre : chaque fragment de la bande est rattaché au
            # personnage le plus proche (aucune coupure à la limite de cellule)
            for i, rgba in enumerate(equal_band(img, box, bg, EQUAL[name])):
                cuts["%s_%d" % (name, i)] = rgba
            continue
        if len(boxes) != COUNT[name]:
            print("   ! %s : %d sprites trouvés (attendu %d)" % (name, len(boxes), COUNT[name]))
        for i, b in enumerate(boxes):
            # boîte élargie de 6 px : rien n'est coupé au bord (épée, arcs, cape)
            bb = (max(0, b[0] - 6), max(0, b[1] - 6), min(img.shape[1], b[2] + 6), min(img.shape[0], b[3] + 4))
            a, m = planche.cutout(img, bb, bg)
            # étiquettes de la planche et marques isolées : seule la silhouette principale et ce qui la touche
            # (épée, arcs d'Aether) sont gardés
            lab, n = ndimage.label(m, structure=np.ones((3, 3)))
            if n > 1:
                sz = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
                big = ndimage.binary_dilation(lab == int(np.argmax(sz)) + 1, iterations=4)
                keep = [j + 1 for j in range(n) if (big & (lab == j + 1)).any()]
                m = np.isin(lab, keep)
            rgba = np.zeros(a.shape[:2] + (4,), np.uint8)
            rgba[..., :3] = to_gray(np.clip(a, 0, 255).astype(np.uint8))
            rgba[..., 3] = np.where(m, 255, 0)
            cuts["%s_%d" % (name, i)] = rgba
    ys = np.where(cuts["repos_0"][..., 3] > 0)[0]
    f = (ys.max() - ys.min() + 1) / float(target)
    out, lost = {}, 0
    for k, rgba in cuts.items():
        r = reduce(rgba, f)
        # ombre peinte sous les pieds (noir bleuté) : retirée des 5 dernières rangées
        yy = np.where(r[..., 3].any(1))[0]
        for y in range(yy.max() - 4, yy.max() + 1):
            dark = (r[y, :, 3] > 0) & (r[y, :, :3].astype(int).sum(-1) < 75)
            r[y, dark] = 0
        yy, xx = np.where(r[..., 3] > 0)
        bottom = yy.max()
        feet = xx[yy >= bottom - 3]
        img2, l = place(r, (feet.min() + feet.max()) / 2.0, bottom, (200, 112))
        lost += l
        out[k] = img2
    pal = palette(list(out.values()), 112, 3)
    for k, v in out.items():
        save(quantize(v, pal), "combat", "aren", k + ".png")
    print("Aren combat : %d images, réduction ×1/%.2f, rognage %d px" % (len(out), f, lost))


# ------------------------------------------------------------------------------------------------ combat d'Ilya
# P4.6 — Ilya de face en combat, comme Aren. Le pack P4.4 est un profil strict (montage procédural d'une base verte
# + pistolet peint, d'après son manifeste). Même principe ici avec la base verte DE FACE du pack P4.3 (pose de repos
# face, 251 px) : le corps est de face ; le bras armé, le pistolet et les effets d'Aether (éclair, charge, bouclier,
# entailles) viennent des images P4.4 correspondantes. En visée, le bras droit pendant est effacé (cape peinte
# derrière) et le bras tendu part de l'épaule droite. Montage, pas dessin : à redessiner pour une version finale.
def _green(px):
    return (px[..., 1].astype(int) > px[..., 0].astype(int) + 8) & (px[..., 1].astype(int) > px[..., 2].astype(int))


def _effect(px):
    """Pixels d'effet ou de pistolet lumineux : vert dominant clair, ou presque blanc."""
    return (_green(px) & (px[..., 1].astype(int) > 110)) | (px[..., :3].min(-1) > 200)


def _paste(base, layer, dx, dy):
    out = base.copy()
    ys, xs = np.where(layer[..., 3] > 0)
    ty, tx = ys + dy, xs + dx
    ok = (ty >= 0) & (ty < out.shape[0]) & (tx >= 0) & (tx < out.shape[1])
    out[ty[ok], tx[ok]] = layer[ys[ok], xs[ok]]
    return out


def _erase_right_arm(B):
    """Bras droit (à droite de l'écran) pendant retiré ; la cape verte qu'il cachait est peinte à sa place."""
    o = B.copy()
    for y in range(66, 83):
        row = o[y]
        g = _green(row) & (row[:, 3] > 0)
        for x in range(85, 94):
            if row[x, 3] > 0 and not g[x]:
                row[x] = 0
        gx = [x for x in range(85, 96) if row[x, 3] > 0]
        edge = max(max(gx) if gx else 86, 86 if y < 75 else 88)
        for x in range(85, edge + 1):
            if row[x, 3] == 0:
                row[x] = (46, 60, 40, 255)
        row[edge] = (28, 36, 25, 255)
    return o


def _front_frame(B, P, seq):
    """P : image P4.4 (profil) réduite et placée ; B : base de face placée sur le même canevas."""
    bright = _green(P) & (P[..., 3] > 0) & (P[..., 1] > 140)
    bright[:, :86] = False
    gys = np.where(bright.any(1))[0]
    gy = int(np.median(gys)) if len(gys) else 99
    ys, xs = np.where(P[..., 3] > 0)
    eff = _effect(P)[ys, xs]
    layer = np.zeros_like(P)
    if seq == "guard" or gy < 77:                                   # visée : bras tendu depuis l'épaule
        band = (gy - 4, gy + 3) if seq != "guard" else (57, 84)
        keep = ((xs >= 84) & (ys >= band[0]) & (ys <= band[1])) | ((xs >= 91) & eff)
        layer[ys[keep], xs[keep]] = P[ys[keep], xs[keep]]
        out = _paste(_erase_right_arm(B), layer, 4, -5)
    else:                                                           # pistolet tenu bas, dans la main droite
        keep = (xs >= 91) & ((ys >= 70) | eff)
        layer[ys[keep], xs[keep]] = P[ys[keep], xs[keep]]
        out = _paste(B, layer, 1, -3)
    if seq == "hit":                                                # entailles rouges (côté gauche) et buste rejeté
        red = (P[..., 0].astype(int) > P[..., 1].astype(int) + 50) & (P[..., 3] > 0)
        red[:, 72:] = False
        lay = np.where(red[..., None], P, 0).astype(np.uint8)
        top = np.where(out[..., 3].any(1))[0].min()
        out = shift_rows(out, 0, top + 30, -1, 0)
        out = _paste(out, lay, -3, 0)
    return out


def _front_ko(armed, body, gun):
    """K.O. de face : le corps bascule en arrière (loin de l'ennemi), reposé au sol à chaque image ; le pistolet
    échappe à la main et repose au sol dès la troisième image. Rotation au plus proche à la résolution du sprite (pas
    d'agrandissement)."""
    frames = []
    for k, ang in enumerate([0, 12, 35, 62, 84, 90]):
        im = Image.fromarray(armed if k < 2 else body)
        r = np.asarray(im.rotate(ang, resample=Image.NEAREST, expand=True))
        ys, xs = np.where(r[..., 3] > 0)
        crop = r[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        img, _ = place(crop, crop.shape[1] / 2.0 + ang / 90.0 * 6, crop.shape[0] - 1, (160, 100))
        if ang == 0:
            img = shift_rows(img, 0, 70, -1, 1)
        if k >= 2:
            gy, gx = np.where(gun[..., 3] > 0)
            img = _paste(img, gun, 96 - gx.min(), 98 - gy.max())
        frames.append(img)
    return frames


def ilya_combat(target=54):
    man = json.load(open(os.path.join(SRC, "p44", "manifest.json")))
    ax, ay = man["anchor_pixels"]
    f = 143.0 / target
    front_src = clean_source(np.asarray(Image.open(os.path.join(P43, "ilya", "frames", "down_idle.png")).convert("RGBA")))
    rf = reduce(front_src, height(front_src) / (target + 1.0))
    hx, hy = torso_x(rf)
    B, _ = place(rf, hx, hy + 1, (160, 100))                        # pieds sur la même ligne que le pack (y = 98)
    raw = {}
    for s, d in man["sequences"].items():
        if s == "ko":
            continue
        im = np.asarray(Image.open(os.path.join(SRC, "p44", "atlases", "ilya_%s_strip_192.png" % s)).convert("RGBA"))
        for i in range(d["count"]):
            r = reduce(im[:, i * 192:(i + 1) * 192], f)
            P, _ = place(r, ax / f, ay / f, (160, 100))
            raw["%s_%d" % (s, i)] = _front_frame(B, P, s)
    # pistolet seul, à l'horizontale (image « dégainer » 4 du pack, au-delà de la main)
    im = np.asarray(Image.open(os.path.join(SRC, "p44", "atlases", "ilya_draw_strip_192.png")).convert("RGBA"))
    P, _ = place(reduce(im[:, 4 * 192:5 * 192], f), ax / f, ay / f, (160, 100))
    gun = P.copy()
    gun[:, :93] = 0
    for i, img in enumerate(_front_ko(raw["idle_0"], B, gun)):
        raw["ko_%d" % i] = img
    pal = palette(list(raw.values()), 112, 5)
    q = {k: quantize(v, pal) for k, v in raw.items()}
    # attente : les 4 images du pack + respiration et léger balancement du buste (8 images)
    base = [q["idle_%d" % i] for i in range(4)]
    ys = np.where(base[0][..., 3].any(1))[0]
    chest = ys.min() + int((ys.max() - ys.min()) * 0.58)
    idle = []
    for i, (b, dy, dx) in enumerate(zip([0, 1, 2, 3, 0, 1, 2, 3], [0, 0, 1, 1, 1, 0, 0, 0], [0, 0, 0, 0, 1, 1, 0, 0])):
        idle.append(shift_rows(base[b], 0, chest, dx, dy))
    # tir : 0, 1, 2 (éclair), recul fort (bras et arme reculent de 2 px, buste d'1 px), recul faible, 5, 6.
    # fire_3 (changement de posture brusque) n'est pas utilisée.
    def recoil(img, arm_dx, body_dx):
        g = (img[..., 1].astype(int) > 150) & (img[..., 1].astype(int) > img[..., 0].astype(int) + 40) & (img[..., 3] > 0)
        gy = np.where(g)[0]
        gy = int(np.median(gy)) if len(gy) else img.shape[0] // 2
        cx = img.shape[1] // 2
        out = shift_rows(img, 0, chest, body_dx, 0)
        arm = out.copy()
        sel = np.zeros(img.shape[:2], bool)
        sel[max(0, gy - 6):gy + 6, cx + 5:] = True
        part = np.where(sel[..., None], out, 0).astype(np.uint8)
        out[sel] = 0
        ys2, xs2 = np.where(part[..., 3] > 0)
        out[ys2, np.clip(xs2 + arm_dx, 0, img.shape[1] - 1)] = part[ys2, xs2]
        return out
    fire = [q["fire_0"], q["fire_1"], q["fire_2"], recoil(q["fire_4"], -2, -1), recoil(q["fire_5"], -1, 0), q["fire_5"], q["fire_6"]]
    final = {"idle": idle, "fire": fire}
    for s in ["draw", "charged_shot", "guard", "hit", "ko"]:
        final[s] = [q["%s_%d" % (s, i)] for i in range(man["sequences"][s]["count"])]
    meta = {}
    for s, imgs in final.items():
        for i, img in enumerate(imgs):
            save(img, "combat", "ilya", "%s_%d.png" % (s, i))
        meta[s] = {"count": len(imgs)}
    json.dump(meta, open(os.path.join(OUT, "combat", "ilya", "sequences.json"), "w"), indent=1)
    print("Ilya combat : %d images (attente 8, tir 7 dont 2 de recul)" % sum(len(v) for v in final.values()))


# ------------------------------------------------------------------------------------------------ portraits
def portraits():
    jobs = [("aren", n, os.path.join(SRC, "p42", "aren_portraits", n + ".png")) for n in ["neutre", "determine", "souriant", "surpris", "blesse", "concentre"]]
    jobs += [("ilya", n, os.path.join(SRC, "p42", "ilya_portraits", ("neutre_large" if n == "neutre" else n) + ".png"))
             for n in ["neutre", "determine", "souriant", "surpris", "inquiete", "resolue"]]
    jobs += [("garde", "neutre", os.path.join(SRC, "garde", "garde", "portraits", "neutre.png"))]
    for who, n, p in jobs:
        im = Image.open(p).convert("RGBA")
        w, h = im.size
        s = min(w, h)
        im = im.crop(((w - s) // 2, 0, (w - s) // 2 + s, s))
        if s > 160:
            im = im.resize((160, 160), Image.LANCZOS)
        os.makedirs(os.path.join(OUT, "portraits", who), exist_ok=True)
        im.save(os.path.join(OUT, "portraits", who, n + ".png"))
    print("portraits : %d" % len(jobs))


P43 = os.path.join(SRC, "p43", "ValSerra_P43_ANIMATIONS_QA_v01_A_TESTER")
exploration("aren", grid(os.path.join(P43, "aren_gray_corrige_4dir_5frames.png"), 180, 168), 70)
exploration("ilya", grid(os.path.join(P43, "ilya", "ilya_exploration_4dir_5frames_RGBA.png"), 256, 288), 65, (0.42, 40))
G = os.path.join(SRC, "garde", "garde", "combat", "frames")
exploration("garde", {d: [np.asarray(Image.open(os.path.join(G, "%s_%d.png" % (s, i))).convert("RGBA")) for i in range(5)]
                      for d, s in zip(DIRS, ["down", "up", "left", "right"])}, 75)
aren_combat()
ilya_combat()
portraits()
print("art/p45 :", sum(len(fs) for _, _, fs in os.walk(OUT)), "fichiers")
