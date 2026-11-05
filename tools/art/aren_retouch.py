"""Retouche pixel ciblée des sprites d'Aren (après aren_sheets.py) — lisibilité du visage à taille de jeu.
Pas de nouvelle réduction d'illustration : on corrige les pixels existants, de la même façon sur TOUTES les images,
pour que le visage reste cohérent d'une image et d'une orientation à l'autre :
  1. pixels parasites du détourage : pixels isolés (0 ou 1 voisin opaque) supprimés ;
  2. contour : bord extérieur assombri là où il était clair (silhouette nette sur le décor) ;
  3. séparation cheveux / visage : la rangée de cheveux posée sur la peau passe au brun le plus sombre ;
  4. yeux : 2 pixels sombres (1 × 2) côté regard, sous la frange — gris-bleu foncé de la planche portrait.
Orientation : images « _left » regard à gauche, toutes les autres (profil droit, combat) regard à droite.
Usage : python3 aren_retouch.py <dossier aren2>"""
import glob, os, sys
import numpy as np
from PIL import Image

D = sys.argv[1]
EYE = (38, 34, 52)
HAIR_DARK = (66, 36, 26)


def is_skin(c):
    """Peau claire du visage (tons pêche f3ca9d / e6b17f) — exclut les reflets orangés des cheveux."""
    r, g, b = int(c[0]), int(c[1]), int(c[2])
    return r > 215 and g > 160 and b > 120 and r - b > 40 and r >= g


def is_hair(c):
    r, g, b = int(c[0]), int(c[1]), int(c[2])
    return r > 70 and r > g > b and r - b > 35 and not is_skin(c)


def retouch(a, facing_left):
    a = a.copy()
    al = a[..., 3] > 0
    H, W = al.shape
    nb = lambda m: sum(np.roll(np.roll(m, dy, 0), dx, 1).astype(int) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    # 1. pixels isolés
    stray = al & (nb(al) <= 1)
    a[stray] = 0
    al = a[..., 3] > 0
    # 2. contour extérieur
    edge = al & (nb(al) < 4)
    lum = a[..., :3].astype(int).mean(-1)
    light_edge = edge & (lum > 110)
    a[light_edge, :3] = (a[light_edge, :3] * 0.55).astype(np.uint8)
    # tête : rangées du haut, centrée sur les cheveux
    ys, xs = np.where(al)
    y0 = ys.min()
    cx = int(np.median(xs[ys < y0 + 7]))
    skin = np.zeros_like(al)
    for y in range(y0, min(H, y0 + 15)):
        for x in range(max(0, cx - 8), min(W, cx + 9)):
            if al[y, x] and is_skin(a[y, x]):
                skin[y, x] = True
    if skin.sum() < 4:
        return a, False
    # 3. séparation cheveux / visage
    sy, sx = np.where(skin)
    for y, x in zip(sy, sx):
        if y > 0 and al[y - 1, x] and is_hair(a[y - 1, x]):
            a[y - 1, x, :3] = HAIR_DARK
    # 4. yeux : sous la frange, côté regard
    top = sy.min()
    cols = np.where(skin[top] | (skin[top + 1] if top + 1 < H else skin[top]))[0]
    ex = (cols.min() + 1) if facing_left else (cols.max() - 1)
    for y in (top, top + 1):
        if 0 <= y < H and al[y, ex]:
            a[y, ex, :3] = EYE
    return a, True


done = 0
for f in sorted(glob.glob(os.path.join(D, "*.png"))):
    n = os.path.basename(f)
    if n.startswith("portrait_") or n.startswith("idle_face") or n.startswith("idle_back") or n.startswith("walk_face") or n.startswith("walk_back"):
        continue                      # portraits illustrés conservés ; vues face/dos non utilisées en jeu
    a = np.asarray(Image.open(f).convert("RGBA"))
    out, ok = retouch(a, "_left" in n)
    Image.fromarray(out, "RGBA").save(f)
    done += ok
print("images retouchées (visage trouvé) :", done)
