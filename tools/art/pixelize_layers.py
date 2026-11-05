"""Solution B, production : convertit TOUS les calques rendus du Vorgane en pixel art avec UNE palette commune.
Entrée : <dossier>/<calque>/<calque>_<anim>_<nnn>.png (rendus Blender 512 px) + ancrages.json
Sortie : art/sprites/vorgane/<calque>/<anim>_<nnn>.png (256 px natifs) + anchors.json (coordonnées natives)
Le contour sombre n'est posé que sur la silhouette extérieure (pas de couture entre corps et parties).
Usage : python3 pixelize_layers.py <dossier_rendus> <dossier_sortie> [couleurs=32]"""
import glob, json, os, sys
import numpy as np
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
K = int(sys.argv[3]) if len(sys.argv) > 3 else 32
F = int(sys.argv[4]) if len(sys.argv) > 4 else 2
LAYERS = {"base": "base", "part_carapace": "carapace", "part_carapace_broken": "carapace_broken",
          "part_griffe": "griffe", "part_griffe_broken": "griffe_broken", "part_glande": "glande"}


def reduce(path):
    a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32)
    H, W = a.shape[0] // F, a.shape[1] // F
    a = a[:H * F, :W * F].reshape(H, F, W, F, 4).transpose(0, 2, 1, 3, 4).reshape(H, W, F * F, 4)
    alpha = (a[..., 3] > 110).mean(-1) >= 0.5
    w = a[..., 3:4] / 255.0
    rgb = (a[..., :3] * w).sum(2) / np.maximum(w.sum(2), 1e-3)   # couleur non prémultipliée par la transparence
    # Niveaux : éclaircit les tons moyens et renforce le contraste (lisibilité sur décor de nuit)
    rgb = np.clip(((rgb / 255.0) ** 0.72) * 1.18 * 255.0, 0, 255)
    return rgb, alpha


data = {}
for d, name in LAYERS.items():
    for f in sorted(glob.glob(os.path.join(src, d, "*.png"))):
        key = os.path.basename(f)[len(d) + 1:-4]          # ex. claw_014
        data[(name, key)] = reduce(f)
fit = np.concatenate([r[a] for (n, k), (r, a) in data.items() if n in ("base", "carapace", "griffe", "glande")])
rng = np.random.default_rng(0)
sample = fit[rng.choice(len(fit), min(80000, len(fit)), replace=False)]
c = sample[rng.choice(len(sample), K, replace=False)]
for _ in range(25):
    lab = ((sample[:, None] - c[None]) ** 2).sum(-1).argmin(1)
    for i in range(K):
        s = sample[lab == i]
        if len(s):
            c[i] = s.mean(0)
pal = c


def neigh_any(m):
    return np.roll(m, 1, 0) | np.roll(m, -1, 0) | np.roll(m, 1, 1) | np.roll(m, -1, 1)


for (name, key), (rgb, alpha) in data.items():
    base_alpha = data[("base", key)][1]
    nb = sum(np.roll(np.roll(alpha, dy, 0), dx, 1).astype(int) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    alpha = alpha & (nb > 1)
    img = np.zeros(rgb.shape[:2] + (4,), np.uint8)
    idx = ((rgb[alpha][:, None] - pal[None]) ** 2).sum(-1).argmin(1)
    img[alpha, :3] = pal[idx].astype(np.uint8)
    img[alpha, 3] = 255
    union = alpha | base_alpha
    edge = alpha & neigh_any(~union)
    img[edge, :3] = (img[edge, :3] * 0.42).astype(np.uint8)
    os.makedirs(os.path.join(out, name), exist_ok=True)
    Image.fromarray(img, "RGBA").save(os.path.join(out, name, key + ".png"))

anc = json.load(open(os.path.join(src, "ancrages.json")))
native = {k: {p: [round(v[0] / F, 1), round(v[1] / F, 1)] for p, v in pts.items()} for k, pts in anc["images"].items()}
json.dump({"taille_native": 256, "images": native}, open(os.path.join(out, "anchors.json"), "w"), indent=1)
print("images converties :", len(data), "palette :", K)
