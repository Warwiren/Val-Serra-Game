"""Sol définitif — recalage de l'esquisse de sol v0 sur le tracé exact du chemin (gabarit), par DÉFORMATION de l'image
(pas de nouvelle peinture). Le chemin de l'esquisse est ramené sur l'axe exact et à la largeur exacte (pavés 1,9 m,
bordure 2,6 m) ; la déformation s'atténue avec la distance et devient nulle à 5,5 m du chemin (lisière, bord bas
et talus inchangés). Le gros rocher qui chevauche la limite praticable à droite est remplacé par de l'herbe
voisine (clonage adouci). Résultat : art/source/sol/sol_plaque.png, puis tools/explore/import_sol.py --sans-lumieres --exclure-ombres muret (1408×800), source jamais modifiée.
    python3 tools/explore/sol_recalage.py"""
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SRC = "art/source/sol/esquisse_sol_v0_1663x945.webp"
import sys
OUT = sys.argv[1] if len(sys.argv) > 1 else "art/source/sol/sol_plaque.png"
W, H = 1408, 800
g = json.load(open("docs/media/gabarits_exploration/gabarits.json"))
Mx = np.array(g["projection_sol_vers_natif"]["x"]); My = np.array(g["projection_sol_vers_natif"]["y"])
A = np.array([[Mx[0], Mx[1]], [My[0], My[1]]]) * 2.0; b = np.array([Mx[2], My[2]]) * 2.0
Ai = np.linalg.inv(A)
PATH0 = np.array([(-12, -8.6), (-7, -5.5), (-2, -2.5), (2.5, 0.2), (4.6, 1.8), (9, 0.8), (16, 1.4)], float)


def chaikin(p, n=4):
    """Tracé lissé (coins arrondis) : repère continu le long du chemin, plus de couture aux coudes."""
    for _ in range(n):
        q = [p[0]]
        for a, b in zip(p[:-1], p[1:]):
            q += [a * 0.75 + b * 0.25, a * 0.25 + b * 0.75]
        q.append(p[-1]); p = np.array(q)
    return p


PATH = chaikin(PATH0)
img = np.asarray(Image.open(SRC).convert("RGB").resize((W, H), Image.LANCZOS)).astype(np.float32)


def to_ground(px):                                           # (N,2) écran -> sol (m)
    return (Ai @ (px.T - b[:, None])).T


def to_screen(gr):
    return (A @ gr.T).T + b


def path_mask(im):
    R, G, B = im[..., 0], im[..., 1], im[..., 2]
    return (B >= G - 4) & (R >= G - 2) & (im.mean(-1) > 70) & (np.abs(R - B) < 45)


# 1. Axe et demi-largeur du chemin de l'esquisse, mesurés tous les 0,5 m le long du tracé exact
ys, xs = np.nonzero(path_mask(img))
P = to_ground(np.c_[xs, ys].astype(float))
seglen = np.linalg.norm(np.diff(PATH, axis=0), axis=1); cum = np.r_[0, np.cumsum(seglen)]


def frame(s):
    i = min(np.searchsorted(cum, s, side="right") - 1, len(seglen) - 1)
    t = (PATH[i + 1] - PATH[i]) / seglen[i]
    return PATH[i] + t * (s - cum[i]), t, np.array([-t[1], t[0]])


S = np.arange(0.5, cum[-1] - 0.5, 0.5)
off, half = [], []
for s in S:
    p0, t, n = frame(s)
    rel = P - p0; along = rel @ t; lat = rel @ n
    sel = (np.abs(along) < 0.6) & (np.abs(lat) < 4.0)
    if sel.sum() > 30:
        lo, hi = np.percentile(lat[sel], 6), np.percentile(lat[sel], 94)
        off.append((lo + hi) / 2); half.append(max(0.8, (hi - lo) / 2))
    else:
        off.append(np.nan); half.append(np.nan)
off = np.array(off); half = np.array(half)
for arr in (off, half):                                      # trous comblés puis lissage (médiane glissante)
    idx = np.arange(len(arr)); good = ~np.isnan(arr)
    arr[:] = np.interp(idx, idx[good], arr[good])
    arr[:] = [np.median(arr[max(0, k - 9):k + 10]) for k in range(len(arr))]
    arr[:] = np.convolve(np.pad(arr, 6, mode="edge"), np.ones(13) / 13, mode="valid")
TARGET_HALF = 1.3                                            # bordure de terre comprise (2,6 m)
print("esquisse : décalage moyen %.2f m, demi-largeur moyenne %.2f m (cible %.2f)" % (off.mean(), half.mean(), TARGET_HALF))

# 2. Coordonnées de chaque pixel de sortie par rapport au tracé exact : abscisse s, écart latéral u (m)
yy, xx = np.mgrid[0:H, 0:W]
G = to_ground(np.c_[xx.ravel(), yy.ravel()].astype(float))
best_d = np.full(len(G), np.inf); best_s = np.zeros(len(G)); best_u = np.zeros(len(G)); nrm = np.zeros_like(G)
for i in range(len(seglen)):
    t = (PATH[i + 1] - PATH[i]) / seglen[i]; n = np.array([-t[1], t[0]])
    rel = G - PATH[i]; a = np.clip(rel @ t, 0, seglen[i]); u = rel @ n
    d = np.linalg.norm(rel - np.outer(a, t), axis=1)
    m = d < best_d
    best_d[m] = d[m]; best_s[m] = cum[i] + a[m]; best_u[m] = u[m]; nrm[m] = n
o = np.interp(best_s, S, off); h = np.interp(best_s, S, half)
inside_ends = (best_s > 0.05) & (best_s < cum[-1] - 0.05)


def sample(ground_pts):
                                                             # lecture bilinéaire de l'esquisse à des points du sol
    sp = to_screen(ground_pts)
    sx = np.clip(sp[:, 0], 0, W - 1.001); sy = np.clip(sp[:, 1], 0, H - 1.001)
    x0 = np.floor(sx).astype(int); y0 = np.floor(sy).astype(int); fx = (sx - x0)[:, None]; fy = (sy - y0)[:, None]
    return (img[y0, x0] * (1 - fx) * (1 - fy) + img[y0, x0 + 1] * fx * (1 - fy) + img[y0 + 1, x0] * (1 - fx) * fy + img[y0 + 1, x0 + 1] * fx * fy)


def smooth(e0, e1, v):
    t = np.clip((v - e0) / (e1 - e0), 0, 1); return t * t * (3 - 2 * t)


base = img.reshape(-1, 3).copy()
# 3a. Effacer l'ancien chemin : herbe de l'esquisse prise juste au-delà de l'ancien chemin, parallèlement au tracé
#     (simple translation au sol : l'échelle et la perspective de l'herbe sont conservées)
side = np.sign(o); side[side == 0] = 1
grass = sample(G + nrm * (side * (2 * h + 0.8))[:, None])
old = np.abs(best_u - o) - h                                 # < 0 : dans l'ancien chemin
a_fill = 1 - smooth(-0.1, 0.5, old)
base = base * (1 - a_fill[:, None]) + grass * a_fill[:, None]
# 3b. Reposer la bande de chemin de l'esquisse sur l'axe exact, à la largeur exacte (bordure 2,6 m)
k = h / TARGET_HALF
strip = sample(G - nrm * best_u[:, None] + nrm * (o + best_u * k)[:, None])
a_path = 1 - smooth(TARGET_HALF - 0.25, TARGET_HALF + 0.15, np.abs(best_u))
base = base * (1 - a_path[:, None]) + strip * a_path[:, None]
out = base.reshape(H, W, 3)
# 4. Rocher qui chevauche la limite praticable (à droite) : herbe voisine clonée, bords adoucis
box = (1238, 482, 1398, 582); dy_src = -118
mask = Image.new("L", (W, H), 0); ImageDraw.Draw(mask).ellipse(box, fill=255)
mask = np.asarray(mask.filter(ImageFilter.GaussianBlur(10))).astype(np.float32)[..., None] / 255.0
patch = np.roll(out, -dy_src, axis=0)
out = out * (1 - mask) + patch * mask
# 5. Bord inférieur : l'arête du talus est une ligne droite trop nette. On la repère colonne par colonne
#    (passage à la bande très sombre, lissé), puis on la rend légèrement irrégulière : petites avancées d'herbe
#    de 1 à 4 px, prises juste au-dessus de l'arête (pas de « coulures »).
lum = out.mean(-1)
edge = np.full(W, -1.0)
for x in range(W):
    col = lum[540:, x]
    idx = np.nonzero((col < 24) & (np.r_[col[4:], [0] * 4] < 30))[0]
    if len(idx):
        edge[x] = 540 + idx[0]
good = edge > 0
xi = np.arange(W)
edge = np.interp(xi, xi[good], edge[good])
edge = np.array([np.median(edge[max(0, x - 15):x + 16]) for x in range(W)])      # lissage robuste
rng = np.random.default_rng(3)
bump = np.convolve(rng.uniform(0, 1, W + 20), np.ones(5) / 5, mode="same")[10:W + 10]
bump = np.clip((bump - 0.45) * 9, 0, 4)                                          # 0 à 4 px, par endroits
for x in range(W):
    y0 = int(round(edge[x]))
    for dy in range(int(bump[x])):
        y = y0 + dy
        if 2 <= y < H and y0 - 3 >= 0:
            out[y, x] = out[y0 - 2 - (dy % 2), x]
print("arête du bord bas repérée sur %d colonnes" % good.sum())
Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(OUT)
# contrôle : chemin mesuré après recalage
ys, xs = np.nonzero(path_mask(out)); P2 = to_ground(np.c_[xs, ys].astype(float))
res = []
for s in S[::4]:
    p0, t, n = frame(s); rel = P2 - p0; sel = (np.abs(rel @ t) < 0.6) & (np.abs(rel @ n) < 4)
    if sel.sum() > 30:
        lat = (rel @ n)[sel]; res.append(((np.percentile(lat, 6) + np.percentile(lat, 94)) / 2, (np.percentile(lat, 94) - np.percentile(lat, 6)) / 2))
r = np.array(res)
print("après recalage : décalage moyen %.2f m (max %.2f), demi-largeur moyenne %.2f m" % (r[:, 0].mean(), np.abs(r[:, 0]).max(), r[:, 1].mean()))
print("écrit :", OUT)
