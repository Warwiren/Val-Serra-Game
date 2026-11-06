"""Conversion du Vorgane d'exploration (vorgane_explore.py) en pixel art cohérent avec le décor :
grille de pixels (médiane par bloc), étalonnage nocturne (corps assombri, cristaux violets conservés, glande cyan),
palette commune aux 8 images (pas de scintillement), contour sombre, ombre portée pleine et semi-transparente.
Usage : python3 vorgane_pixel.py <dossier_rendu> <sortie> [SS=3]"""
import glob, json, os, sys
import numpy as np
from PIL import Image

SRC, OUT = sys.argv[1], sys.argv[2]
SS = int(sys.argv[3]) if len(sys.argv) > 3 else 3
os.makedirs(OUT, exist_ok=True)
files = sorted(glob.glob(os.path.join(SRC, "v_*.png")))
frames = []
for f in files:
    a = np.asarray(Image.open(f).convert("RGBA")).astype(np.float32)
    H, W = a.shape[0] // SS, a.shape[1] // SS
    b = a[:H * SS, :W * SS].reshape(H, SS, W, SS, 4).transpose(0, 2, 1, 3, 4).reshape(H, W, SS * SS, 4)
    al = np.median(b[..., 3], axis=2) / 255.0
    rgb = np.median(b[..., :3], axis=2)
    lum = rgb.mean(-1)
    body = (al > 0.9) & (lum > 18)                  # le monstre (le sol attrape-ombre ne donne que du sombre)
    shadow = ~body & (al > 0.3)
    # étalonnage : corps plus sombre et moins saturé, cristaux (violet clair) et glande (cyan) gardent leur éclat
    l = rgb.mean(-1, keepdims=True)
    crystal = (rgb[..., 2] > rgb[..., 1] * 1.15) & (rgb[..., 0] > rgb[..., 1]) & (l[..., 0] > 55)
    glow = (rgb[..., 1] > rgb[..., 0] * 1.3) & (rgb[..., 2] > 150)
    g = l + (rgb - l) * 0.8
    # cristaux : violet saturé et plus lumineux (identité du Vorgane) ; glande : cyan franc
    cr = np.clip(l + (rgb - l) * 1.6, 0, 255) * 1.25 + np.array([18, 0, 30])
    gl = np.clip(l + (rgb - l) * 1.4, 0, 255) * 1.2
    g = np.where(crystal[..., None], cr, np.where(glow[..., None], gl, g * 1.0 + np.array([6, 4, 14])))
    g = np.clip(g, 0, 255)
    frames.append((g, body, shadow))
px = np.concatenate([g[m] for g, m, _ in frames])
rng = np.random.default_rng(4)
K = 22
c = px[rng.choice(len(px), K, replace=False)]
for _ in range(25):
    lab = ((px[:, None] - c[None]) ** 2).sum(-1).argmin(1)
    for k in range(K):
        sel = px[lab == k]
        if len(sel):
            c[k] = sel.mean(0)
for i, (g, body, shadow) in enumerate(frames):
    H, W = body.shape
    out = np.zeros((H, W, 4), np.uint8)
    idx = ((g[body][:, None] - c[None]) ** 2).sum(-1).argmin(1)
    out[body, :3] = c[idx].astype(np.uint8); out[body, 3] = 255
    nb = sum(np.roll(np.roll(body, dy, 0), dx, 1).astype(int) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    e = body & (nb < 4)
    out[e, :3] = (out[e, :3] * 0.4 + np.array([6, 6, 16]) * 0.6).astype(np.uint8)
    out[shadow] = (10, 8, 22, 120)                    # ombre portée : un seul ton, semi-transparent, sans flou
    Image.fromarray(out, "RGBA").save(os.path.join(OUT, "idle_%d.png" % i))
anc = json.load(open(os.path.join(SRC, "anchor.json")))
json.dump(anc, open(os.path.join(OUT, "anchor.json"), "w"))
print("vorgane pixel :", len(frames), "images", W, "x", H, "| pieds", anc["feet"])
