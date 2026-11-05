"""Cycles de marche d'exploration (lot P1, § 2 et 10.2) pour Aren, Ilya et Throné, dérivés des sprites du pack.
Chaque image change la POSE des membres (pas de déplacement ni de déformation du sprite entier) :
  contact A : jambe avant (+1 px dans le sens de la marche), jambe arrière (-1), bras en balancier opposé
  passage   : jambe libre levée de 2 px (genou fléchi : rangées du tibia comprimées), bassin 1 px plus haut
  contact B : jambes inversées ; passage : l'autre jambe levée
Le bas du vêtement suit avec un pixel de retard (traîne). Pieds d'appui à hauteur constante.
Orientation native : sens de marche = +x (le sprite est retourné quand le personnage va à gauche).
Usage : python3 walk_cycles.py <dossier art/proto>"""
import os, sys
import numpy as np
from PIL import Image

D = sys.argv[1]
# Régions (coordonnées natives) : jambes gauche/droite (x0, x1), rangée du haut des jambes, rangée du genou,
# bras gauche/droit (x0, x1, y0, y1), rangées du bas du vêtement (y0, y1)
CFG = {
    "aren":   {"legs": ((3, 11), (12, 21)), "hip": 29, "knee": 32, "arms": ((0, 5, 19, 28), (17, 22, 19, 27)), "cloth": (26, 29), "amp": (2, 3)},
    "ilya":   {"legs": ((5, 12), (12, 20)), "hip": 26, "knee": 29, "arms": ((0, 4, 18, 26), (18, 22, 18, 26)), "cloth": (24, 27), "amp": (2, 2)},
    "throne": {"legs": ((4, 14), (17, 27)), "hip": 29, "knee": 32, "arms": ((0, 6, 18, 27), (25, 31, 18, 25)), "cloth": (26, 29), "amp": (2, 3)},
}


def blit(dst, src, mask, dx, dy):
    ys, xs = np.where(mask)
    for y, x in zip(ys, xs):
        ty, tx = y + dy, x + dx
        if 0 <= ty < dst.shape[0] and 0 <= tx < dst.shape[1]:
            dst[ty, tx] = src[y, x]


def frame(img, c, step, lift, body_up, arm_swing, cloth_lag):
    """step : (dx jambe gauche, dx jambe droite) ; lift : (levée gauche, levée droite) en px."""
    H, W = img.shape[:2]
    out = np.zeros_like(img)
    alpha = img[..., 3] > 0
    yy, xx = np.mgrid[0:H, 0:W]
    legs = []
    for (x0, x1) in c["legs"]:
        legs.append(alpha & (yy >= c["hip"]) & (xx >= x0) & (xx < x1))
    leg_any = legs[0] | legs[1]
    arms = [alpha & (xx >= a[0]) & (xx < a[1]) & (yy >= a[2]) & (yy < a[3]) for a in c["arms"]]
    cloth = alpha & (yy >= c["cloth"][0]) & (yy < c["cloth"][1]) & ~leg_any & ~arms[0] & ~arms[1]
    rest = alpha & ~leg_any & ~arms[0] & ~arms[1] & ~cloth
    # jambes : la jambe levée perd `lift` rangées de tibia (genou fléchi), pied remonté d'autant
    for i, m in enumerate(legs):
        lf = lift[i]
        if lf:
            keep = [y for y in range(H) if not (c["knee"] <= y < c["knee"] + lf)]
            sq = np.zeros_like(img); sm = np.zeros((H, W), bool)
            for j, y in enumerate([y for y in keep if y >= c["hip"]]):
                ty = c["hip"] + j
                sq[ty] = img[y]; sm[ty] = m[y]
            # rangées du haut (au-dessus de la hanche) inchangées
            blit(out, sq, sm, step[i], -body_up)
        else:
            blit(out, img, m, step[i], 0)
    blit(out, img, cloth, -cloth_lag, -body_up)
    blit(out, img, rest, 0, -body_up)
    blit(out, img, arms[0], -arm_swing, -body_up)       # bras gauche : en arrière quand la jambe gauche avance
    blit(out, img, arms[1], arm_swing, -body_up)
    return out


for k, c in CFG.items():
    img = np.asarray(Image.open(os.path.join(D, k + ".png")).convert("RGBA")).copy()
    # canevas un peu plus large (+3 px de chaque côté) et 1 px plus haut, pieds sur la dernière rangée
    pad = np.zeros((img.shape[0] + 1, img.shape[1] + 6, 4), np.uint8)
    pad[1:, 3:-3] = img
    shift = lambda cc: {"legs": tuple((a + 3, b + 3) for a, b in cc["legs"]), "hip": cc["hip"] + 1, "knee": cc["knee"] + 1,
                        "arms": tuple((a + 3, b + 3, y0 + 1, y1 + 1) for a, b, y0, y1 in cc["arms"]),
                        "cloth": (cc["cloth"][0] + 1, cc["cloth"][1] + 1), "amp": cc["amp"]}
    cc = shift(c)
    st, lf = c["amp"]                                  # amplitude du pas et de la levée (px natifs)
    frames = [
        frame(pad, cc, (st, -st), (0, 0), 0, 1, 1),   # contact A : jambe gauche devant
        frame(pad, cc, (0, 0), (0, lf), 1, 0, 0),     # passage : jambe droite levée
        frame(pad, cc, (-st, st), (0, 0), 0, -1, 1),  # contact B : jambe droite devant
        frame(pad, cc, (0, 0), (lf, 0), 1, 0, 0),     # passage : jambe gauche levée
    ]
    for i, f in enumerate(frames):
        Image.fromarray(f, "RGBA").save(os.path.join(D, f"{k}_walk_{i}.png"))
    print(k, "marche : 4 images", f.shape[1], "x", f.shape[0])
