"""Conversion d'un rendu Blender (suréchantillonné) en asset pixel art d'exploration :
couleur médiane par bloc, palette réduite (aplats « peints », pas de dégradé 3D), contour de silhouette sombre,
recadrage serré. Usage : python3 to_pixel.py <rendu.png> <sortie.png> [suréchantillonnage=4] [couleurs=20]"""
import sys
import numpy as np
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
SS = int(sys.argv[3]) if len(sys.argv) > 3 else 4
K = int(sys.argv[4]) if len(sys.argv) > 4 else 20
a = np.asarray(Image.open(src).convert("RGBA")).astype(np.float32)
H, W = a.shape[0] // SS, a.shape[1] // SS
b = a[:H * SS, :W * SS].reshape(H, SS, W, SS, 4).transpose(0, 2, 1, 3, 4).reshape(H, W, SS * SS, 4)
alpha = (b[..., 3] > 128).mean(-1) >= 0.5
rgb = np.median(b[..., :3], axis=2)
px = rgb[alpha]
rng = np.random.default_rng(0)
c = px[rng.choice(len(px), K, replace=False)]
for _ in range(25):
    lab = ((px[:, None] - c[None]) ** 2).sum(-1).argmin(1)
    for k in range(K):
        sel = px[lab == k]
        if len(sel):
            c[k] = sel.mean(0)
img = np.zeros((H, W, 4), np.uint8)
idx = ((rgb[alpha][:, None] - c[None]) ** 2).sum(-1).argmin(1)
img[alpha, :3] = c[idx].astype(np.uint8); img[alpha, 3] = 255
nb = sum(np.roll(np.roll(alpha, dy, 0), dx, 1).astype(int) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
edge = alpha & (nb < 4)
img[edge, :3] = (img[edge, :3] * 0.45).astype(np.uint8)
ys, xs = np.where(alpha)
img = img[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
Image.fromarray(img, "RGBA").save(out)
print(out, img.shape[1], "x", img.shape[0])
