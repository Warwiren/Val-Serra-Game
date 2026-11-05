"""Animations d'Aren (pixel art) à partir des 5 poses corrigées + effets lumineux séparés (pixel art).
- repos : respiration (haut du corps abaissé d'1 px au-dessus de la ceinture, appuis fixes), 4 images ;
- garde : même principe sur la pose de garde ;
- effets : arc de taille (4 images) et glyphe de garde (3 images), dessinés au pixel près, palette Aether.
Usage : python3 aren_anims.py <dossier_poses> <dossier_sortie>"""
import math, os, sys
import numpy as np
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)


def load(n):
    return np.asarray(Image.open(os.path.join(src, f"aren_{n}.png")).convert("RGBA")).copy()


def save(a, name):
    Image.fromarray(a, "RGBA").save(os.path.join(out, name + ".png"))


def breathe(a, waist, dy=1, shift_from_x=None):
    """Décale d'un pixel vers le bas tout ce qui est au-dessus de la ligne de ceinture."""
    b = a.copy()
    top = a[:waist].copy()
    b[:waist] = 0
    b[dy:waist + dy] = np.where(top[..., 3:4] > 0, top, b[dy:waist + dy])
    return b


def waist_row(a):
    ys = np.where(a[..., 3].any(1))[0]
    top, bottom = ys.min(), ys.max()
    return int(top + (bottom - top) * 0.58)


for pose, name in (("repos", "idle"), ("garde", "guard")):
    a = load(pose)
    w = waist_row(a)
    b = breathe(a, w)
    for i, fr in enumerate([a, b, b, a]):
        save(fr, f"{name}_{i}")
for pose in ("avance", "attaque", "touche", "garde", "repos"):
    save(load(pose), f"pose_{pose}")

# --- Effets en pixel art --------------------------------------------------------------------------
AE = [(20, 70, 110), (40, 150, 200), (110, 220, 245), (210, 250, 255), (255, 255, 255)]


def slash_frame(t, size=72):
    """Croissant de taille : t de 0 (naissant) à 1 (dissipé)."""
    img = np.zeros((size, size, 4), np.uint8)
    cx, cy, R = size * 0.38, size * 0.55, size * 0.42
    a0, a1 = -2.2, 0.9
    span = a0 + (a1 - a0) * min(1.0, 0.35 + t * 1.2)
    for y in range(size):
        for x in range(size):
            dx, dy = x - cx, y - cy
            r = math.hypot(dx, dy)
            ang = math.atan2(dy, dx)
            if not (a0 <= ang <= span):
                continue
            k = (ang - a0) / (a1 - a0)                    # 0 à la queue, 1 à la tête du croissant
            thick = 1.5 + 6.5 * math.sin(min(1, k) * math.pi) * (1 - 0.6 * t)
            d = abs(r - R)
            if d > thick:
                continue
            lvl = 4 - int(d / thick * 4)                  # cœur blanc, bord bleu sombre
            lvl -= int(t * 3)
            if (x + y) % 2 and d > thick * 0.6:           # tramage pixel art sur le bord
                lvl -= 1
            if lvl < 0:
                continue
            img[y, x, :3] = AE[min(4, lvl)]
            img[y, x, 3] = 255
    return img


for i, t in enumerate([0.0, 0.3, 0.6, 0.85]):
    save(slash_frame(t), f"fx_slash_{i}")


def glyph_frame(t, size=48):
    img = np.zeros((size, size, 4), np.uint8)
    c = size // 2
    s = int(6 + 14 * min(1, t * 1.5))
    for y in range(size):
        for x in range(size):
            d = abs(x - c) + abs(y - c) * 0.6               # losange
            if abs(d - s) < 1.2 or (abs(x - c) < 1 and abs(y - c) < s * 1.4) or (abs(y - c) < 1 and abs(x - c) < s * 0.7):
                lvl = 4 if abs(d - s) < 0.6 else 2
                lvl -= int(t * 2)
                if lvl >= 0:
                    img[y, x, :3] = AE[lvl]; img[y, x, 3] = 255
            r = math.hypot(x - c, (y - c) * 0.55)
            if abs(r - (s + 6)) < 1.0 and x > c:             # arc de bouclier côté ennemi
                img[y, x, :3] = AE[3 - int(t * 2)]; img[y, x, 3] = 255
    return img


for i, t in enumerate([0.0, 0.5, 1.0]):
    save(glyph_frame(t), f"fx_guard_{i}")
print("animations et effets générés dans", out)
