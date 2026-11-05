"""Assets « illustrés » du mini-test d'exploration HD-2D, dessinés en pixel art par script (pas de rendu 3D) :
arbre (tronc + feuillage séparés), sol (herbe, chemin pavé en perspective, fleurs), fond crépusculaire
(ciel + deux plans de forêt). Palette crépuscule bleu-violet, lumière du ciel en haut à gauche.
Toutes les tailles dérivent de PPM (pixels natifs par mètre) et de la plongée de 35° de la caméra commune.
Usage : python3 paint_assets.py <dossier_sortie> <ppm> <graine>"""
import math, os, sys
import numpy as np
from PIL import Image

OUT, PPM, SEED = sys.argv[1], float(sys.argv[2]), int(sys.argv[3])
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(SEED)
COS, SIN = math.cos(math.radians(35)), math.sin(math.radians(35))
BAYER = np.array([[0, 2], [3, 1]]) / 4.0


def save(a, name):
    Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, name))


def outline(img, col=(16, 18, 30)):
    al = img[..., 3] > 0
    nb = sum(np.roll(np.roll(al, dy, 0), dx, 1).astype(int) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    e = al & (nb < 4)
    img[e, :3] = col
    return img


# --------------------------------------------------------------------------------------------------
# Arbre : feuillage en grappes (disques bruités), 4 tons + tramage, tronc effilé avec liseré de ciel
# --------------------------------------------------------------------------------------------------
def tree(height_m=6.0, crown_m=5.2):
    Ht = int(height_m * COS * PPM); Wc = int(crown_m * PPM)
    pad = int(0.2 * Wc)                                  # marge haute : le feuillage ne touche pas le bord
    W, H = Wc + 16, Ht + 8 + pad
    cx = W // 2
    canopy = np.zeros((H, W, 4), np.float32)
    trunk = np.zeros((H, W, 4), np.float32)
    # tronc
    base_w = max(5, int(0.75 * PPM)); top_y = pad + int(Ht * 0.40)
    for y in range(top_y, H - 2):
        t = (y - top_y) / (H - 2 - top_y)
        w = int(base_w * (0.55 + 0.45 * t)) + (2 if y > H - 6 else 0)
        off = int(1.5 * math.sin(y * 0.09))
        for x in range(cx - w // 2 + off, cx + w // 2 + off + 1):
            u = (x - (cx - w // 2 + off)) / max(1, w)
            col = (40, 30, 40) if u > 0.6 else ((64, 46, 52) if u > 0.2 else (108, 96, 132))
            if rng.random() < 0.06:
                col = (30, 22, 30)
            trunk[y, x] = (*col, 255)
    # départs de branches (partiellement cachés par le feuillage)
    for sx in (-1, 1):
        for k in range(int(base_w * 1.6)):
            y = top_y + int(base_w * 0.6) - k
            x = cx + sx * (k // 2)
            if 0 <= y < H:
                trunk[y, x:x + 3] = (58, 42, 50, 255)
    # racines
    for sx in (-1, 1):
        for k in range(int(base_w * 0.8)):
            trunk[H - 3 - k // 3, cx + sx * (base_w // 2 + k)] = (52, 38, 44, 255)
    # feuillage : grandes grappes, puis touffes de feuilles à l'intérieur (texture « illustrée »)
    TONES = [(16, 30, 40), (28, 50, 56), (44, 76, 72), (78, 104, 100), (128, 138, 168)]
    yy, xx = np.mgrid[0:H, 0:W]
    cy0 = pad + int(Ht * 0.30)

    def clump(by, bx, r, jag=0.12, light_bias=0.0):
        ang = np.arctan2(yy - by, xx - bx)
        rr = r * (1 + jag * np.sin(ang * 7 + bx) + jag * 0.6 * np.sin(ang * 13 + by))
        d = np.hypot(xx - bx, (yy - by) * 1.12)
        m = d < rr
        nx, ny = (xx - bx) / r, (yy - by) / r
        lit = np.clip(-0.55 * nx - 0.85 * ny, -1, 1) * 0.5 + 0.5 + light_bias
        q = lit * 3.0 + (BAYER[yy % 2, xx % 2] - 0.5) * 0.22          # tramage léger, aux frontières seulement
        idx = np.clip(q.astype(int), 0, 3)
        for k in range(4):
            canopy[m & (idx == k)] = (*TONES[k], 255)
        return m
    big = []
    for i in range(11):
        ang = rng.uniform(0, 2 * math.pi); rad = rng.uniform(0, 0.38)
        big.append((cy0 + math.sin(ang) * rad * Wc * 0.55, cx + math.cos(ang) * rad * Wc, rng.uniform(0.2, 0.3) * Wc))
    big.sort()
    for by, bx, r in big:
        clump(by, bx, r, 0.12, -0.15)
        # touffes : petites grappes posées sur la moitié haute de chaque grande grappe
        for k in range(7):
            a = rng.uniform(math.pi * 1.05, math.pi * 1.95)
            dd = rng.uniform(0.25, 0.75) * r
            clump(by + math.sin(a) * dd * 0.9, bx + math.cos(a) * dd, rng.uniform(0.22, 0.34) * r, 0.18, 0.08)
    # quelques reflets de ciel en petits amas (pas de traits)
    al_c = canopy[..., 3] > 0
    for _ in range(int(Wc * 0.5)):
        x, y = rng.integers(0, W), rng.integers(0, H)
        if al_c[y, x] and tuple(canopy[y, x, :3].astype(int)) == TONES[3] and y < cy0:
            canopy[y, x] = (*TONES[4], 255)
            if x + 1 < W and al_c[y, x + 1]:
                canopy[y, x + 1] = (*TONES[3], 255)
    # ombre intérieure sous le feuillage (le tronc s'y enfonce)
    al = canopy[..., 3] > 0
    canopy = outline(canopy, (10, 18, 24))
    trunk = outline(trunk, (14, 12, 18))
    trunk[al] = 0                                        # le feuillage passe devant le haut du tronc
    return canopy, trunk


# --------------------------------------------------------------------------------------------------
# Sol : herbe, chemin pavé en perspective, fleurs
# --------------------------------------------------------------------------------------------------
def ground(W, H, path_pts, path_w_m=2.0):
    g = np.zeros((H, W, 4), np.float32)
    yy, xx = np.mgrid[0:H, 0:W]
    low = np.zeros((H, W))
    for s, a in ((24, 1.0), (9, 0.5), (4, 0.25)):
        n = rng.random((H // s + 2, W // s + 2))
        low += a * np.array(Image.fromarray((n * 255).astype(np.uint8)).resize((W + s, H + s), Image.BILINEAR))[:H, :W] / 255.0
    low /= 1.75
    GR = [(32, 52, 54), (42, 66, 62), (54, 82, 72), (72, 100, 84)]
    q = np.clip((low * 3.6 + (BAYER[yy % 2, xx % 2] - 0.5) * 0.5).astype(int), 0, 3)
    for k in range(4):
        g[q == k] = (*GR[k], 255)
    # touffes (brins verticaux plus clairs)
    for _ in range(int(W * H / 90)):
        x, y = rng.integers(1, W - 1), rng.integers(3, H)
        g[y - 2:y, x] = (78, 104, 82, 255)
        g[y, x] = (30, 50, 48, 255)
    # chemin : bande le long d'une polyligne, pavés en cellules (Voronoï régulier) aplatis par la perspective
    pw = path_w_m * PPM
    dist = np.full((H, W), 1e9)
    for (x0, y0), (x1, y1) in zip(path_pts[:-1], path_pts[1:]):
        vx, vy = x1 - x0, (y1 - y0) / SIN
        L2 = vx * vx + vy * vy
        t = np.clip(((xx - x0) * vx + ((yy - y0) / SIN) * vy) / L2, 0, 1)
        dx, dy = xx - (x0 + t * vx), (yy - y0) / SIN - t * vy
        dist = np.minimum(dist, np.hypot(dx, dy))
    path = dist < pw / 2
    edge = (dist < pw / 2 + 2) & ~path
    g[edge] = (64, 56, 64, 255)
    sx, sy = max(5, int(0.42 * PPM)), max(3, int(0.42 * PPM * SIN))
    pts = []
    for j in range(-1, H // sy + 2):
        for i in range(-1, W // sx + 2):
            pts.append((i * sx + (sx // 2 if j % 2 else 0) + rng.uniform(-1, 1), j * sy + rng.uniform(-0.6, 0.6)))
    pts = np.array(pts)
    tone = rng.uniform(0, 1, len(pts))
    py, px = np.where(path)
    d = ((px[:, None] - pts[None, :, 0]) ** 2 + ((py[:, None] - pts[None, :, 1]) / SIN * 1.0) ** 2)
    o = np.argsort(d, axis=1)
    near, second = o[:, 0], o[:, 1]
    gap = np.sqrt(d[np.arange(len(px)), second]) - np.sqrt(d[np.arange(len(px)), near])
    ST = [(70, 68, 86), (84, 80, 100), (98, 94, 114), (112, 106, 124)]
    for k, (y, x) in enumerate(zip(py, px)):
        c = ST[int(tone[near[k]] * 3.99)]
        cyc = pts[near[k], 1]
        if gap[k] < 1.2:
            c = (40, 38, 52)
        elif y < cyc - sy * 0.25:
            c = tuple(min(255, v + 18) for v in c)                     # arête haute éclairée par le ciel
        elif y > cyc + sy * 0.3:
            c = tuple(int(v * 0.78) for v in c)
        g[y, x] = (*c, 255)
    # fleurs violettes en petits groupes
    for _ in range(int(W * H / 2600)):
        fx, fy = rng.integers(4, W - 4), rng.integers(6, H - 2)
        if path[fy, fx]:
            continue
        for _ in range(5):
            x, y = fx + rng.integers(-3, 4), fy + rng.integers(-2, 3)
            if 0 <= x < W and 0 <= y < H and not path[y, x]:
                g[y, x] = (150, 110, 190, 255); g[min(H - 1, y + 1), x] = (70, 50, 100, 255)
    return g, path


# --------------------------------------------------------------------------------------------------
# Fond : ciel crépusculaire + deux plans de forêt (le plus lointain plus clair et moins contrasté)
# --------------------------------------------------------------------------------------------------
def backdrop(W, H, horizon):
    sky = np.zeros((H, W, 4), np.float32)
    top, mid, low = np.array([20, 20, 52]), np.array([62, 50, 104]), np.array([132, 92, 128])
    for y in range(H):
        t = y / max(1, horizon)
        c = top + (mid - top) * min(1, t * 1.4) if t < 0.7 else mid + (low - mid) * min(1, (t - 0.7) / 0.3)
        sky[y, :, :3] = c; sky[y, :, 3] = 255
    # étoiles discrètes
    for _ in range(W // 6):
        x, y = rng.integers(0, W), rng.integers(0, int(horizon * 0.5))
        sky[y, x, :3] = (190, 190, 230)

    def forest(base, amp, col, crown):
        f = np.zeros((H, W, 4), np.float32)
        x = 0
        while x < W:
            r = rng.uniform(0.6, 1.0) * crown
            h = base - rng.uniform(0.3, 1.0) * amp
            for xx in range(int(x - r), int(x + r) + 1):
                if 0 <= xx < W:
                    yy = int(h + (abs(xx - x) / r) ** 1.6 * r * 0.9)
                    f[max(0, yy):min(H, base + 22 + int(rng.integers(0, 7))), xx] = (*col, 255)   # lisière irrégulière
            x += r * rng.uniform(0.7, 1.2)
        return f
    far = forest(horizon - 6, 22, (54, 52, 96), 9)
    near = forest(horizon + 4, 30, (30, 32, 60), 14)
    # brume entre les plans
    for y in range(horizon - 10, horizon + 6):
        a = 0.35 * (1 - abs(y - horizon + 2) / 10)
        far[y, :, :3] = far[y, :, :3] * (1 - a) + np.array([110, 96, 150]) * a
    return sky, far, near


if __name__ == "__main__":
    can, tr = tree()
    save(can, "arbre_feuillage.png"); save(tr, "arbre_tronc.png")
    print("arbre :", can.shape[1], "x", can.shape[0])
