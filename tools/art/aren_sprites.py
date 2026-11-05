"""Pipeline de production des sprites d'Aren à partir de la planche de référence (pseudo pixel art IA).

Étapes (chaque pose) :
  1. découpe de la pose dans la planche ;
  2. détourage : fond bleu nuit, ombre portée et bruit retirés ;
  3. retrait des effets lumineux peints (arcs, glyphes, étincelles, traits d'impact) -> recréés dans le moteur ;
  4. PALETTE COMMUNE à toutes les poses (k-means) ;
  5. rééchantillonnage en VRAI pixel art à une résolution native unique (même facteur pour toutes les poses),
     couleur dominante par cellule (pas de moyenne floue) ;
  6. nettoyage (pixels isolés), contour sombre continu ;
  7. placement dans un cadre commun avec point d'ancrage stable (pieds).

Usage : python3 tools/art/aren_sprites.py <planche_sprites.png> <dossier_sortie>
"""
import json, os, sys
import numpy as np
from PIL import Image

SHEET, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)

# Découpes dans la planche « Aren – Référence de sprites » (1448×1086), rangée « Animations de combat ».
CROPS = {
    "repos":   (40, 700, 280, 945),
    "avance":  (300, 700, 525, 945),
    "attaque": (550, 690, 905, 945),
    "garde":   (885, 715, 1145, 945),
    "touche":  (1175, 720, 1425, 945),
}
# Corrections manuelles : zones d'effets peints à effacer (coordonnées dans la découpe source).
# Chaque zone : ("rect", x0, y0, x1, y1) ou ("blade", hx, hy, tx, ty, rayon) = zone PROTÉGÉE autour de la lame.
ERASE = {
    "attaque": {"erase": [("rect", 0, 0, 355, 75), ("rect", 213, 0, 355, 255)],
                "keep": [("blade", 196, 138, 312, 96, 6)]},
    "touche": {"erase": [("rect", 0, 170, 58, 245)], "keep": []},
    "garde": {"erase": [("rect", 175, 0, 260, 168), ("rect", 160, 0, 260, 40)],
              "keep": [("blade", 125, 112, 207, 40, 6)]},
}
NATIVE_H = 64            # hauteur native d'Aren debout (pixels de sprite)
FRAME = (140, 84)        # cadre commun (largeur, hauteur) en pixels natifs
ANCHOR = (44, 80)        # point d'ancrage (pieds) dans le cadre
PALETTE_SIZE = 30


def load(name):
    im = Image.open(SHEET).convert("RGB").crop(CROPS[name])
    return np.asarray(im).astype(np.float32)


def hsv(a):
    r, g, b = a[..., 0] / 255, a[..., 1] / 255, a[..., 2] / 255
    mx, mn = np.max(a / 255, axis=-1), np.min(a / 255, axis=-1)
    d = mx - mn + 1e-6
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    s = np.where(mx > 0, d / (mx + 1e-6), 0)
    return h, s, mx


def dilate(m, n=1):
    out = m.copy()
    for _ in range(n):
        o = out.copy()
        o[1:] |= out[:-1]; o[:-1] |= out[1:]; o[:, 1:] |= out[:, :-1]; o[:, :-1] |= out[:, 1:]
        out = o
    return out


def components(mask):
    """Étiquetage 4-connexe simple (sans scipy)."""
    lab = np.zeros(mask.shape, int)
    cur = 0
    H, W = mask.shape
    for y in range(H):
        for x in range(W):
            if mask[y, x] and not lab[y, x]:
                cur += 1
                stack = [(y, x)]
                lab[y, x] = cur
                while stack:
                    cy, cx = stack.pop()
                    for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                        if 0 <= ny < H and 0 <= nx < W and mask[ny, nx] and not lab[ny, nx]:
                            lab[ny, nx] = cur
                            stack.append((ny, nx))
    return lab, cur


def foreground(a):
    """Masque du personnage : fond, ombre et effets lumineux retirés."""
    corners = np.concatenate([a[:6, :6].reshape(-1, 3), a[:6, -6:].reshape(-1, 3)])
    bg = np.median(corners, axis=0)
    dist = np.linalg.norm(a - bg, axis=-1)
    h, s, v = hsv(a)
    fg = dist > 34
    # Ombre portée : gris-bleu très sombre, UNIQUEMENT dans la bande du sol (le pantalon bleu nuit est aussi sombre)
    H = a.shape[0]
    ground = np.zeros_like(fg)
    ground[int(H * 0.86):] = True
    fg &= ~((v < 0.24) & (s < 0.5) & ground)
    # Effets : cyan saturé et lumineux, ou halo cyan sombre
    cyan = (h > 165) & (h < 215) & (s > 0.35) & (v > 0.3)
    body = fg & ~cyan
    lab, n = components(body)
    sizes = np.bincount(lab.ravel())
    sizes[0] = 0
    main = sizes.argmax()
    core = lab == main
    for i in range(1, n + 1):                          # mèches de cheveux, bout d'écharpe proches du corps
        if i != main and sizes[i] >= 25 and (dilate(lab == i, 3) & core).any():
            core |= lab == i
    keep_cyan = cyan & dilate(core, 3)                 # fiole, fil d'Aether de la lame (au contact du corps)
    mask = core | keep_cyan
    return mask


def apply_erase(name, mask):
    rules = ERASE.get(name)
    if not rules:
        return mask
    H, W = mask.shape
    yy, xx = np.mgrid[0:H, 0:W]
    er = np.zeros_like(mask)
    for r in rules["erase"]:
        _, x0, y0, x1, y1 = r
        er |= (xx >= x0) & (xx < x1) & (yy >= y0) & (yy < y1)
    for r in rules["keep"]:
        _, hx, hy, tx, ty, rad = r
        dx, dy = tx - hx, ty - hy
        L2 = dx * dx + dy * dy
        t = np.clip(((xx - hx) * dx + (yy - hy) * dy) / L2, 0, 1)
        d = np.hypot(xx - (hx + t * dx), yy - (hy + t * dy))
        er &= ~(d <= rad)
    return mask & ~er


def to_native(a, mask, f):
    """Réduction par cellule : couleur dominante parmi les pixels du personnage (pas de flou)."""
    H, W = mask.shape
    nh, nw = int(np.ceil(H / f)), int(np.ceil(W / f))
    rgb = np.zeros((nh, nw, 3), np.uint8)
    alpha = np.zeros((nh, nw), bool)
    for y in range(nh):
        for x in range(nw):
            y0, y1 = int(round(y * f)), int(round((y + 1) * f))
            x0, x1 = int(round(x * f)), int(round((x + 1) * f))
            m = mask[y0:y1, x0:x1]
            if m.size == 0 or m.mean() < 0.42:
                continue
            px = a[y0:y1, x0:x1][m]
            # couleur la plus centrale (médiane composante par composante, robuste au flou de compression)
            rgb[y, x] = np.median(px, axis=0)
            alpha[y, x] = True
    return rgb, alpha


def kmeans(pixels, k, iters=25, seed=3):
    rng = np.random.default_rng(seed)
    c = pixels[rng.choice(len(pixels), k, replace=False)].astype(np.float32)
    for _ in range(iters):
        d = ((pixels[:, None, :] - c[None]) ** 2).sum(-1)
        lab = d.argmin(1)
        for i in range(k):
            sel = pixels[lab == i]
            if len(sel):
                c[i] = sel.mean(0)
    return c


def clean(rgb, alpha, pal):
    # Palette commune
    flat = rgb[alpha].astype(np.float32)
    idx = ((flat[:, None, :] - pal[None]) ** 2).sum(-1).argmin(1)
    out = rgb.copy()
    out[alpha] = pal[idx].astype(np.uint8)
    # Pixels isolés (aucun voisin opaque) retirés
    nb = np.zeros_like(alpha, int)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nb += np.roll(np.roll(alpha, dy, 0), dx, 1)
    alpha = alpha & (nb > 0)
    # Contour : pixels opaques en bordure assombris s'ils sont clairs (silhouette lisible sur fond sombre)
    edge = alpha & ~(np.roll(alpha, 1, 0) & np.roll(alpha, -1, 0) & np.roll(alpha, 1, 1) & np.roll(alpha, -1, 1))
    lum = out[..., :3].astype(float).mean(-1)
    dark = edge & (lum > 150)
    out[dark] = (out[dark] * 0.55).astype(np.uint8)
    return out, alpha


# Correction de l'arme : même longueur de lame dans toutes les poses (le long sabre de la fiche de design).
# Pour chaque pose : point de garde (hilt) et direction approximative de la lame, en coordonnées du cadre.
BLADES = {
    "repos":   {"hilt": (67, 59), "toward": (85, 74), "length": 32},
    "garde":   {"hilt": (81, 41), "toward": (91, 26), "length": 30},
    "touche":  {"hilt": (68, 68), "toward": (82, 77), "length": 31},
    "attaque": {"hilt": (96, 46), "toward": (126, 38), "length": 33},
}


# Coupe transversale canonique du long sabre (relevée sur la pose d'attaque, vue la plus nette) :
# tranchant sombre / acier clair / reflet. Utilisée pour prolonger les lames trop courtes.
BLADE_SECTION = {-1: (78, 88, 104, 255), 0: (226, 232, 238, 255), 1: (150, 162, 176, 255)}


def fix_blade(frame, spec):
    """Trouve la pointe réelle le long de l'axe, puis prolonge la lame en recopiant sa coupe transversale."""
    hx, hy = spec["hilt"]
    dx, dy = spec["toward"][0] - hx, spec["toward"][1] - hy
    L = (dx * dx + dy * dy) ** 0.5
    ux, uy = dx / L, dy / L
    px, py = -uy, ux
    a = frame[..., 3] > 0
    tip_t = 0.0
    t = 0.0
    while t < 60:
        x, y = int(round(hx + ux * t)), int(round(hy + uy * t))
        if not (0 <= x < frame.shape[1] and 0 <= y < frame.shape[0]):
            break
        hit = any(0 <= int(round(x + px * o)) < frame.shape[1] and 0 <= int(round(y + py * o)) < frame.shape[0]
                  and a[int(round(y + py * o)), int(round(x + px * o))] for o in (-1, 0, 1))
        if hit:
            tip_t = t
        t += 0.5
    target = spec["length"]
    added = 0
    if tip_t >= target - 0.5:
        return frame, round(tip_t, 1), 0
    ref_t = max(2.0, tip_t - 4.0)          # coupe de référence prise 4 px avant la pointe
    t = tip_t - 1.0
    while t <= target:
        taper = 1 if target - t < 2.5 else 0   # pointe effilée
        for o in (-1, 0, 1):
            if taper and o != 0:
                continue
            tx, ty = int(round(hx + ux * t + px * o)), int(round(hy + uy * t + py * o))
            if not (0 <= tx < frame.shape[1] and 0 <= ty < 80):
                continue
            if frame[ty, tx, 3] == 0:
                frame[ty, tx] = BLADE_SECTION[o]
                added += 1
        t += 0.5
    return frame, round(tip_t, 1), added


def main():
    names = list(CROPS)
    raws = {n: load(n) for n in names}
    masks = {n: apply_erase(n, foreground(raws[n])) for n in names}
    # Facteur commun déduit de la pose de repos (debout) : même échelle pour toutes les poses.
    ys = np.where(masks["repos"].any(1))[0]
    stand_h = ys.max() - ys.min() + 1
    f = stand_h / NATIVE_H
    print(f"hauteur debout source : {stand_h}px -> facteur {f:.3f} (pixel source -> pixel natif)")
    natives = {n: to_native(raws[n], masks[n], f) for n in names}
    allpx = np.concatenate([natives[n][0][natives[n][1]] for n in names]).astype(np.float32)
    pal = kmeans(allpx, PALETTE_SIZE)
    report = {"facteur": round(f, 3), "hauteur_native": NATIVE_H, "cadre": FRAME, "ancrage": ANCHOR, "poses": {}}
    for n in names:
        rgb, alpha = clean(*natives[n], pal)
        ys, xs = np.where(alpha)
        foot_y = ys.max()
        # x d'ancrage : talon du pied ARRIÈRE (appui fixe : le personnage avance depuis ce point)
        feet_x = xs[ys >= foot_y - 3]
        ax = int(feet_x.min()) + 3
        frame = np.zeros((FRAME[1], FRAME[0], 4), np.uint8)
        ox, oy = ANCHOR[0] - ax, ANCHOR[1] - foot_y
        h, w = alpha.shape
        for y in range(h):
            for x in range(w):
                if alpha[y, x]:
                    fy, fx = y + oy, x + ox
                    if 0 <= fy < FRAME[1] and 0 <= fx < FRAME[0]:
                        frame[fy, fx, :3] = rgb[y, x]
                        frame[fy, fx, 3] = 255
        if n in BLADES:
            frame, tip, added = fix_blade(frame, BLADES[n])
            print(f"  lame {n} : longueur mesurée {tip} px -> {BLADES[n]['length']} px ({added} pixels ajoutés)")
        Image.fromarray(frame, "RGBA").save(f"{OUT}/aren_{n}.png")
        report["poses"][n] = {"largeur": int(xs.max() - xs.min() + 1), "hauteur": int(ys.max() - ys.min() + 1),
                              "pixels": int(alpha.sum()), "decalage": [int(ox), int(oy)]}
        print(n, report["poses"][n])
    np.save(f"{OUT}/palette.npy", pal)
    json.dump(report, open(f"{OUT}/rapport.json", "w"), indent=1, ensure_ascii=False)


main()
