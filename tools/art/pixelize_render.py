"""Solution B : conversion des rendus Blender du Vorgane en sprites pixel art cohérents avec Aren.
Chaque image : rendu 3× plus grand que la cible -> réduction par cellule (couleur médiane, sans flou)
-> palette commune à TOUTES les images (k-means) -> pixels isolés retirés -> contour sombre continu.
Même cadrage pour toutes les images (caméra orthographique fixe dans Blender) => point d'ancrage stable.
Usage : python3 pixelize_render.py <dossier_rendus> <dossier_sortie> [facteur=3] [couleurs=28]"""
import glob, os, sys
import numpy as np
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
F = int(sys.argv[3]) if len(sys.argv) > 3 else 3
K = int(sys.argv[4]) if len(sys.argv) > 4 else 28
os.makedirs(out, exist_ok=True)
files = sorted(glob.glob(os.path.join(src, "*.png")))


def reduce(path):
    a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32)
    H, W = a.shape[0] // F, a.shape[1] // F
    a = a[:H * F, :W * F].reshape(H, F, W, F, 4).transpose(0, 2, 1, 3, 4).reshape(H, W, F * F, 4)
    alpha = (a[..., 3] > 128).mean(-1) >= 0.5
    rgb = np.median(a[..., :3], axis=2)
    return rgb, alpha


def kmeans(px, k, it=20):
    rng = np.random.default_rng(1)
    c = px[rng.choice(len(px), k, replace=False)]
    for _ in range(it):
        lab = ((px[:, None] - c[None]) ** 2).sum(-1).argmin(1)
        for i in range(k):
            s = px[lab == i]
            if len(s):
                c[i] = s.mean(0)
    return c


data = [reduce(f) for f in files]
allpx = np.concatenate([r[a] for r, a in data])
sample = allpx[np.random.default_rng(0).choice(len(allpx), min(60000, len(allpx)), replace=False)]
pal = kmeans(sample, K)
for f, (rgb, alpha) in zip(files, data):
    idx = ((rgb[alpha][:, None] - pal[None]) ** 2).sum(-1).argmin(1)
    img = np.zeros(rgb.shape[:2] + (4,), np.uint8)
    img[alpha, :3] = pal[idx].astype(np.uint8)
    img[alpha, 3] = 255
    nb = sum(np.roll(np.roll(alpha, dy, 0), dx, 1) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    alpha2 = alpha & (nb > 1)
    img[~alpha2] = 0
    # Contour : liseré sombre sur le bord extérieur (lisibilité sur décor sombre, comme les sprites d'Aren)
    edge = alpha2 & ~(np.roll(alpha2, 1, 0) & np.roll(alpha2, -1, 0) & np.roll(alpha2, 1, 1) & np.roll(alpha2, -1, 1))
    img[edge, :3] = (img[edge, :3] * 0.45).astype(np.uint8)
    Image.fromarray(img, "RGBA").save(os.path.join(out, os.path.basename(f)))
np.save(os.path.join(out, "palette.npy"), pal)
print("images :", len(files), "taille native :", data[0][0].shape[1], "x", data[0][0].shape[0], "palette :", K)
