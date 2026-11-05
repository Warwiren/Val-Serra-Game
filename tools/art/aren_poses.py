"""Poses de combat d'Aren (brief unifié v1.1, § 3.1) dérivées du sprite du pack, dans la MÊME grille et la
MÊME palette : repos armé (+ respiration), préparation, frappe, impact (suivi), garde, touché.
Méthode : le haut du corps et le bras d'épée sont déplacés au pixel près, l'épée (longueur constante,
LAME px) est tracée depuis la main avec la palette du sprite. Canevas commun 64×42, pieds au point (32, 41).
Orientation native : « avant » = +x (le sprite est retourné en combat pour regarder le monstre).
Usage : python3 aren_poses.py <aren.png> <dossier_sortie>"""
import math, os, sys
import numpy as np
from PIL import Image

SRC, OUT = sys.argv[1], sys.argv[2]
base = np.asarray(Image.open(SRC).convert("RGBA")).copy()
H, W = base.shape[:2]                     # 38 × 22
CW, CH = 64, 42
OX, OY = (CW - W) // 2, CH - H            # pieds sur la dernière rangée du canevas
WAIST = 22                                # rangée de la ceinture (natif)
ARM_X0, ARM_Y0, ARM_Y1 = 17, 20, 28       # bras d'épée d'origine (côté +x), effacé dans les poses
SHOULDER = (17, 20)                       # épaule (natif)
LAME = 16                                 # longueur de lame (px natifs), identique dans toutes les poses
STEEL_HI, STEEL, STEEL_LO = (226, 232, 240), (168, 178, 194), (96, 104, 122)
EDGE = (22, 20, 30)
GUARD, GRIP = (214, 168, 86), (92, 58, 40)
# Couleurs du bras prélevées sur le sprite du pack
SLEEVE = tuple(int(v) for v in base[20, 17, :3])     # manche claire
SLEEVE_SH = tuple(int(v) for v in base[22, 18, :3])  # manche ombrée
SKIN = tuple(int(v) for v in base[23, 18, :3])
SKIN_HI = tuple(int(v) for v in base[23, 19, :3])
OUTLINE = tuple(int(v) for v in base[25, 21, :3])


def canvas():
    return np.zeros((CH, CW, 4), np.uint8)


def paste(dst, src, dx, dy):
    ys, xs = np.where(src[..., 3] > 0)
    for y, x in zip(ys, xs):
        ty, tx = y + dy, x + dx
        if 0 <= ty < CH and 0 <= tx < CW:
            dst[ty, tx] = src[y, x]


def put(dst, x, y, col, only_empty=False):
    x, y = int(round(x)), int(round(y))
    if 0 <= y < CH and 0 <= x < CW and not (only_empty and dst[y, x, 3] > 0):
        dst[y, x] = (*col, 255)


def line_px(p, q):
    (x0, y0), (x1, y1) = p, q
    n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
    return [(x0 + (x1 - x0) * t / max(1, n - 1), y0 + (y1 - y0) * t / max(1, n - 1)) for t in range(n)]


def sword(dst, hand, angle_deg):
    """Épée tenue en `hand` (coordonnées du canevas), angle en degrés (0 = vers l'avant, 90 = vers le bas)."""
    a = math.radians(angle_deg)
    d = (math.cos(a), math.sin(a)); nrm = (-d[1], d[0])
    tip = (hand[0] + d[0] * LAME, hand[1] + d[1] * LAME)
    blade = line_px((hand[0] + d[0] * 2, hand[1] + d[1] * 2), tip)
    for (x, y) in blade:                                   # contour sombre : lisible à ×3 sur tout décor
        for k in (-1, 1):
            put(dst, x + nrm[0] * k, y + nrm[1] * k, EDGE, only_empty=True)
    put(dst, tip[0] + d[0], tip[1] + d[1], EDGE, only_empty=True)
    for i, (x, y) in enumerate(blade):
        put(dst, x, y, STEEL_HI if i < len(blade) - 2 else STEEL)
        if i % 3 != 2 and i < len(blade) - 1:
            put(dst, x + nrm[0], y + nrm[1], STEEL_LO)
    for k in (-2, -1, 0, 1, 2):
        put(dst, hand[0] + d[0] * 1.5 + nrm[0] * k, hand[1] + d[1] * 1.5 + nrm[1] * k, GUARD)
    for (x, y) in line_px(hand, (hand[0] - d[0] * 2, hand[1] - d[1] * 2)):
        put(dst, x, y, GRIP)


def arm(dst, shoulder, hand):
    """Bras dessiné (manche 2 px, contour, main 2×2) de l'épaule à la main."""
    pts = line_px(shoulder, hand)
    for (x, y) in pts:
        for ox in (-1, 0, 1, 2):
            for oy in (-1, 0, 1, 2):
                put(dst, x + ox, y + oy, OUTLINE, only_empty=True)
    for i, (x, y) in enumerate(pts):
        c = SLEEVE if i < len(pts) * 0.55 else SLEEVE_SH
        for ox in (0, 1):
            for oy in (0, 1):
                put(dst, x + ox, y + oy, c)
    hx, hy = hand
    put(dst, hx, hy, SKIN); put(dst, hx + 1, hy, SKIN_HI); put(dst, hx, hy + 1, SKIN); put(dst, hx + 1, hy + 1, SKIN)


def pose(upper=(0, 0), hand=(2, 5), angle=62, legs=0, original_arm=False):
    """upper : décalage du haut du corps ; hand : main relative à l'épaule ; legs : flexion (rangées retirées)."""
    body = base.copy()
    if not original_arm:
        body[ARM_Y0:ARM_Y1, ARM_X0:] = 0
    out = canvas()
    lower = body.copy(); lower[:WAIST] = 0
    top = body.copy(); top[WAIST:] = 0
    if legs:
        keep = [y for y in range(WAIST, H) if not (WAIST + 4 <= y < WAIST + 4 + legs)]
        squashed = np.zeros_like(lower); off = H - len(keep)
        for i, y in enumerate(keep):
            squashed[i + off] = lower[y]
        lower = squashed
    paste(out, lower, OX, OY)
    paste(out, top, OX + upper[0], OY + upper[1] + legs)
    sh = (OX + SHOULDER[0] + upper[0], OY + SHOULDER[1] + upper[1] + legs)
    hd = (sh[0] + hand[0], sh[1] + hand[1])
    sword(out, hd, angle)
    arm(out, sh, hd)
    return out


POSES = {
    "idle":   pose(hand=(2, 5), angle=62),                            # repos armé : lame basse vers l'avant
    "idle_1": pose(upper=(0, 1), hand=(2, 4), angle=62),              # respiration (main fixe au sol près)
    "prep":   pose(upper=(-2, 0), hand=(1, -6), angle=-72, legs=2),   # préparation : lame levée, buste en arrière
    "strike": pose(upper=(2, 0), hand=(7, 0), angle=-4, legs=1),      # frappe : bras tendu, lame à l'horizontale
    "follow": pose(upper=(3, 1), hand=(5, 6), angle=42, legs=2),      # impact / suivi : lame vers le sol
    "guard":  pose(upper=(-1, 0), hand=(3, 1), angle=-100, legs=1),   # garde : lame verticale devant soi
    "hurt":   pose(upper=(-3, 0), hand=(0, 6), angle=112),            # touché : recul du buste
}
os.makedirs(OUT, exist_ok=True)
for k, img in POSES.items():
    Image.fromarray(img, "RGBA").save(os.path.join(OUT, f"aren_{k}.png"))
print("poses :", ", ".join(POSES), "| canevas", CW, "x", CH, "| pieds", (CW // 2, CH - 1))
