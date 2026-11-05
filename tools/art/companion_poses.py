"""Poses de combat PROVISOIRES d'Ilya (dagues) et Throné (marteau), dérivées de leurs sprites du pack (vus de face),
même méthode que les premières poses d'Aren : le bras d'arme d'origine est effacé puis redessiné de l'épaule à la
main (manche, contour, main) aux couleurs du sprite, et l'arme est tracée au pixel avec une longueur constante.
Gestes propres à chaque arme (pas une copie de l'attaque d'Aren) :
  Ilya   : appel bas -> estocade rapide en extension -> fente basse -> garde dagues croisées -> touché
  Throné : marteau levé au-dessus de la tête -> frappe descendante -> marteau au sol -> garde manche en travers -> touché
À remplacer par des planches dédiées (comme celles d'Aren) dès qu'elles existent.
Usage : python3 companion_poses.py <dossier art/proto>"""
import math, os, sys
import numpy as np
from PIL import Image

D = sys.argv[1]
CW, CH = 64, 44
CFG = {
    "ilya": {"arm": (18, 18, 23), "shoulder": (18, 18), "waist": 22, "sleeve": (19, 18), "sleeve_sh": (18, 20), "skin": (19, 21)},
    "throne": {"arm": (26, 18, 27), "shoulder": (26, 19), "waist": 25, "sleeve": (28, 20), "sleeve_sh": (29, 22), "skin": (28, 24)},
}
STEEL_HI, STEEL, STEEL_LO, EDGE = (226, 232, 240), (168, 178, 194), (96, 104, 122), (22, 20, 30)
WOOD, WOOD_SH, IRON, IRON_HI = (122, 82, 50), (78, 50, 32), (70, 74, 86), (150, 156, 170)
GOLD = (214, 168, 86)


def put(dst, x, y, col, only_empty=False):
    x, y = int(round(x)), int(round(y))
    if 0 <= y < CH and 0 <= x < CW and not (only_empty and dst[y, x, 3] > 0):
        dst[y, x] = (*col, 255)


def line_px(p, q):
    n = int(max(abs(q[0] - p[0]), abs(q[1] - p[1]))) + 1
    return [(p[0] + (q[0] - p[0]) * t / max(1, n - 1), p[1] + (q[1] - p[1]) * t / max(1, n - 1)) for t in range(n)]


def outline_line(dst, pts, nrm):
    for (x, y) in pts:
        for k in (-1, 1):
            put(dst, x + nrm[0] * k, y + nrm[1] * k, EDGE, only_empty=True)


def dagger(dst, hand, ang):
    a = math.radians(ang); d = (math.cos(a), math.sin(a)); n = (-d[1], d[0])
    blade = line_px((hand[0] + d[0] * 2, hand[1] + d[1] * 2), (hand[0] + d[0] * 7, hand[1] + d[1] * 7))
    outline_line(dst, blade, n)
    put(dst, hand[0] + d[0] * 8, hand[1] + d[1] * 8, EDGE, True)
    for i, (x, y) in enumerate(blade):
        put(dst, x, y, STEEL_HI if i < len(blade) - 1 else STEEL)
    for k in (-1, 0, 1):
        put(dst, hand[0] + d[0] * 1.2 + n[0] * k, hand[1] + d[1] * 1.2 + n[1] * k, GOLD)


def hammer(dst, hand, ang):
    a = math.radians(ang); d = (math.cos(a), math.sin(a)); n = (-d[1], d[0])
    haft = line_px((hand[0] - d[0] * 3, hand[1] - d[1] * 3), (hand[0] + d[0] * 12, hand[1] + d[1] * 12))
    outline_line(dst, haft, n)
    for i, (x, y) in enumerate(haft):
        put(dst, x, y, WOOD if i % 3 else WOOD_SH)
    hx, hy = hand[0] + d[0] * 14, hand[1] + d[1] * 14       # tête du marteau, perpendiculaire au manche
    for u in range(-5, 6):                                    # masse large et lisible (pas une pioche)
        for v in range(-3, 4):
            if abs(u) == 5 and abs(v) == 3:
                continue
            c = EDGE if (abs(u) == 5 or abs(v) == 3) else (IRON_HI if v <= -2 else IRON)
            put(dst, hx + n[0] * u + d[0] * v, hy + n[1] * u + d[1] * v, c)


def arm(dst, sh, hd, cols):
    sleeve, sleeve_sh, skin = cols
    pts = line_px(sh, hd)
    for (x, y) in pts:
        for ox in (-1, 0, 1, 2):
            for oy in (-1, 0, 1, 2):
                put(dst, x + ox, y + oy, EDGE, only_empty=True)
    for i, (x, y) in enumerate(pts):
        c = sleeve if i < len(pts) * 0.55 else sleeve_sh
        for ox in (0, 1):
            for oy in (0, 1):
                put(dst, x + ox, y + oy, c)
    for ox in (0, 1):
        for oy in (0, 1):
            put(dst, hd[0] + ox, hd[1] + oy, skin)


def pose(base, c, upper=(0, 0), hand=(2, 5), ang=60, legs=0, weapon=dagger, offhand=None):
    H, W = base.shape[:2]
    OX, OY = (CW - W) // 2, CH - H
    x0, y0, y1 = c["arm"]
    cols = tuple(tuple(int(v) for v in base[y, x, :3]) for (x, y) in (c["sleeve"], c["sleeve_sh"], c["skin"]))
    body = base.copy(); body[y0:y1, x0:] = 0
    out = np.zeros((CH, CW, 4), np.uint8)
    lower = body.copy(); lower[:c["waist"]] = 0
    top = body.copy(); top[c["waist"]:] = 0
    if legs:
        keep = [y for y in range(c["waist"], H) if not (c["waist"] + 3 <= y < c["waist"] + 3 + legs)]
        sq = np.zeros_like(lower); off = H - len(keep)
        for i, y in enumerate(keep):
            sq[i + off] = lower[y]
        lower = sq
    def paste(src, dx, dy):
        ys, xs = np.where(src[..., 3] > 0)
        for y, x in zip(ys, xs):
            if 0 <= y + dy < CH and 0 <= x + dx < CW:
                out[y + dy, x + dx] = src[y, x]
    paste(lower, OX, OY)
    paste(top, OX + upper[0], OY + upper[1] + legs)
    if offhand is not None:                      # 2e dague (main gauche, côté arrière)
        dagger(out, (OX + offhand[0] + upper[0], OY + offhand[1] + upper[1] + legs), offhand[2])
    sh = (OX + c["shoulder"][0] + upper[0], OY + c["shoulder"][1] + upper[1] + legs)
    hd = (sh[0] + hand[0], sh[1] + hand[1])
    weapon(out, hd, ang)
    arm(out, sh, hd, cols)
    return out


POSES = {
    "ilya": {   # dagues : vif, bas, en extension
        "idle":   dict(hand=(1, 4), ang=70, offhand=(3, 22, 100)),
        "idle_1": dict(upper=(0, 1), hand=(1, 3), ang=70, offhand=(3, 22, 100)),
        "prep":   dict(upper=(-2, 1), hand=(-2, 3), ang=160, legs=2, offhand=(3, 22, 120)),
        "strike": dict(upper=(3, 1), hand=(8, 1), ang=-5, legs=2, offhand=(5, 21, 20)),
        "follow": dict(upper=(4, 2), hand=(7, 4), ang=25, legs=3, offhand=(6, 22, 40)),
        "guard":  dict(upper=(-1, 0), hand=(2, 0), ang=-60, legs=1, offhand=(8, 17, -120)),
        "hurt":   dict(upper=(-3, 0), hand=(-1, 5), ang=110, offhand=(1, 22, 120)),
    },
    "throne": {  # marteau : lent, lourd, au-dessus de la tête puis au sol
        "idle":   dict(hand=(1, 5), ang=80, weapon=hammer),
        "idle_1": dict(upper=(0, 1), hand=(1, 4), ang=80, weapon=hammer),
        "prep":   dict(upper=(-2, 0), hand=(0, -7), ang=-110, legs=1, weapon=hammer),
        "strike": dict(upper=(2, 1), hand=(5, -2), ang=-20, legs=2, weapon=hammer),
        "follow": dict(upper=(3, 2), hand=(5, 5), ang=60, legs=3, weapon=hammer),
        "guard":  dict(upper=(0, 0), hand=(2, 1), ang=-80, legs=1, weapon=hammer),
        "hurt":   dict(upper=(-3, 0), hand=(-1, 5), ang=100, weapon=hammer),
    },
}
for k, poses in POSES.items():
    base = np.asarray(Image.open(os.path.join(D, k + ".png")).convert("RGBA")).copy()
    os.makedirs(os.path.join(D, k + "_combat"), exist_ok=True)
    for name, kw in poses.items():
        Image.fromarray(pose(base, CFG[k], **kw), "RGBA").save(os.path.join(D, k + "_combat", f"{k}_{name}.png"))
    print(k, ":", ", ".join(poses))
