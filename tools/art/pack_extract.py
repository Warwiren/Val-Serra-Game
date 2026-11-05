"""Extraction des sprites et portraits du « Pack visuel — Brief de recentrage » (une seule passe graphique,
donc un style commun garanti). Sprites : rangée « Style & Échelle » (Aren, Ilya, Throné, PNJ) -> vrai pixel art,
MÊME facteur d'échelle et MÊME palette pour tous. Portraits : panneaux « Personnages » et « PNJ ».
Usage : python3 pack_extract.py <pack.png> <dossier_sortie>"""
import os, sys
import numpy as np
from PIL import Image

PACK, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
im = np.asarray(Image.open(PACK).convert("RGB")).astype(np.float32)

SPRITES = {  # (x0, y0, x1, y1) dans le pack 1672×941
    "aren": (1146, 572, 1196, 646),
    "ilya": (1206, 572, 1254, 646),
    "throne": (1266, 572, 1332, 646),
    "pnj": (1344, 582, 1390, 646),
}
PORTRAITS = {
    "aren": (1128, 49, 1290, 206),
    "ilya": (1308, 49, 1472, 206),
    "throne": (1488, 49, 1652, 206),
    "pnj": (1130, 378, 1246, 480),
}
HERO_NATIVE_H = 37        # Aren debout : 37 px natifs -> 111 px à l'écran (×3)


def mask_of(a):
    corners = np.concatenate([a[:3, :3].reshape(-1, 3), a[:3, -3:].reshape(-1, 3), a[-6:-3, :3].reshape(-1, 3)])
    bg = np.median(corners, axis=0)
    m = np.linalg.norm(a - bg, axis=-1) > 30
    # ligne pointillée du sol (gris-bleu) au bas de la découpe
    m[-4:] = False
    return m


def biggest(m):
    lab = np.zeros(m.shape, int); cur = 0; H, W = m.shape
    for y in range(H):
        for x in range(W):
            if m[y, x] and not lab[y, x]:
                cur += 1; st = [(y, x)]; lab[y, x] = cur
                while st:
                    cy, cx = st.pop()
                    for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                        if 0 <= ny < H and 0 <= nx < W and m[ny, nx] and not lab[ny, nx]:
                            lab[ny, nx] = cur; st.append((ny, nx))
    sizes = np.bincount(lab.ravel()); sizes[0] = 0
    keep = sizes >= max(12, sizes.max() * 0.02)
    return keep[lab]


def reduce(a, m, f):
    H, W = m.shape
    nh, nw = int(np.ceil(H / f)), int(np.ceil(W / f))
    rgb = np.zeros((nh, nw, 3)); al = np.zeros((nh, nw), bool)
    for y in range(nh):
        for x in range(nw):
            y0, y1 = int(round(y * f)), int(round((y + 1) * f)); x0, x1 = int(round(x * f)), int(round((x + 1) * f))
            mm = m[y0:y1, x0:x1]
            if mm.size and mm.mean() >= 0.45:
                rgb[y, x] = np.median(a[y0:y1, x0:x1][mm], axis=0); al[y, x] = True
    return rgb, al


crops = {k: im[b[1]:b[3], b[0]:b[2]] for k, b in SPRITES.items()}
masks = {k: biggest(mask_of(v)) for k, v in crops.items()}
ys = np.where(masks["aren"].any(1))[0]
f = (ys.max() - ys.min() + 1) / HERO_NATIVE_H
print(f"facteur commun : {f:.3f} px du pack par pixel natif")
nat = {k: reduce(crops[k], masks[k], f) for k in crops}
allpx = np.concatenate([r[a] for r, a in nat.values()])
rng = np.random.default_rng(2)
K = 64
c = allpx[rng.choice(len(allpx), K, replace=False)]
for _ in range(30):
    lab = ((allpx[:, None] - c[None]) ** 2).sum(-1).argmin(1)
    for i in range(K):
        s = allpx[lab == i]
        if len(s):
            c[i] = s.mean(0)
for k, (rgb, al) in nat.items():
    out = np.zeros(rgb.shape[:2] + (4,), np.uint8)
    idx = ((rgb[al][:, None] - c[None]) ** 2).sum(-1).argmin(1)
    out[al, :3] = c[idx].astype(np.uint8); out[al, 3] = 255
    nb = sum(np.roll(np.roll(al, dy, 0), dx, 1).astype(int) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    out[~(al & (nb > 0))] = 0
    ys2, xs2 = np.where(out[..., 3] > 0)
    out = out[ys2.min():ys2.max() + 1, xs2.min():xs2.max() + 1]
    Image.fromarray(out, "RGBA").save(os.path.join(OUT, f"{k}.png"))
    print(k, "taille native", out.shape[1], "x", out.shape[0])

# Portraits (illustrés, plus fins que les sprites) : détourage du fond sombre, taille 128 px
for k, b in PORTRAITS.items():
    a = im[b[1]:b[3], b[0]:b[2]]
    corners = np.concatenate([a[:4, :4].reshape(-1, 3), a[:4, -4:].reshape(-1, 3)])
    bg = np.median(corners, axis=0)
    d = np.linalg.norm(a - bg, axis=-1)
    alpha = np.clip((d - 18) / 30, 0, 1)
    rgba = np.dstack([a, alpha * 255]).astype(np.uint8)
    p = Image.fromarray(rgba, "RGBA").resize((128, int(128 * a.shape[0] / a.shape[1])), Image.LANCZOS)
    p.save(os.path.join(OUT, f"portrait_{k}.png"))
print("portraits : ok")

# Image de respiration (2e image de l'animation d'attente) : haut du corps abaissé d'1 px au-dessus de la
# ceinture (55 % de la hauteur), appuis fixes -> <k>_1.png
for k in SPRITES:
    a = np.asarray(Image.open(os.path.join(OUT, f"{k}.png")).convert("RGBA")).copy()
    ys = np.where(a[..., 3].any(1))[0]
    w = int(ys.min() + (ys.max() - ys.min()) * 0.55)
    b = a.copy(); top = a[:w].copy(); b[:w] = 0
    b[1:w + 1] = np.where(top[..., 3:4] > 0, top, b[1:w + 1])
    Image.fromarray(b, "RGBA").save(os.path.join(OUT, f"{k}_1.png"))
print("respiration : ok")
