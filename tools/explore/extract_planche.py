"""Découpe les éléments des planches fournies (fond sombre uni) en sprites RGBA prêts pour le jeu.
    python3 tools/explore/extract_planche.py [tools/explore/planches.json] [art/source/planches_2026-11-06/extraits]
Pour chaque élément : estimation du fond à partir du bord de la boîte, masque par écart de couleur (avec bord
adouci de 1 px pour l'anticrénelage), suppression des îlots isolés, recadrage serré, puis UNE réduction de
qualité (Lanczos) à la taille réellement affichée à l'écran. Les planches sources ne sont jamais modifiées.
Écrit aussi <sortie>/index.json : taille de chaque texture et point d'appui (milieu du bas de la silhouette)."""
import json, os, sys
import numpy as np
from PIL import Image, ImageFilter

SPEC = sys.argv[1] if len(sys.argv) > 1 else "tools/explore/planches.json"
OUT = sys.argv[2] if len(sys.argv) > 2 else "art/source/planches_2026-11-06/extraits"
JEU = "art/explore_hd2d/illustre"                         # éléments affichés tels quels par le jeu
SRC = "art/source/planches_2026-11-06"
os.makedirs(OUT, exist_ok=True)
spec = json.load(open(SPEC))
index = {}
for sheet, items in spec.items():
    if sheet.startswith("_"):
        continue
    im = np.asarray(Image.open(os.path.join(SRC, sheet)).convert("RGB")).astype(np.float32)
    for name, it in items.items():
        x0, y0, x1, y1 = it["boite"]
        c = im[y0:y1, x0:x1]
        border = np.concatenate([c[:3].reshape(-1, 3), c[-3:].reshape(-1, 3), c[:, :3].reshape(-1, 3), c[:, -3:].reshape(-1, 3)])
        bg = np.median(border, axis=0)
        dist = np.sqrt(((c - bg) ** 2).sum(-1))
        lum = c.mean(-1)
        # fond : proche de la couleur de fond ET sombre ; les ombres portées très sombres restent du fond
        core = (dist > 22) & (lum > bg.mean() + float(it.get("seuil_lum", 6)))
        if "halo_max" in it:                                  # halo lumineux peint sur le fond : on le retire
            sat = c.max(-1) - c.min(-1)
            core &= ~((lum < it["halo_max"]) & (c[..., 0] > c[..., 2]) & (sat < 70))
        m = Image.fromarray((core * 255).astype(np.uint8)).filter(ImageFilter.MedianFilter(3))
        m = np.asarray(m) > 127
        # composantes connexes : on garde les morceaux de taille raisonnable (supprime le bruit de compression)
        from collections import deque
        lab = np.zeros(m.shape, int); keep = np.zeros(m.shape, bool); n = 0
        for yy, xx in zip(*np.nonzero(m)):
            if lab[yy, xx]:
                continue
            n += 1; q = deque([(yy, xx)]); lab[yy, xx] = n; pts = []
            while q:
                a, b = q.popleft(); pts.append((a, b))
                for da, db in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    u, v = a + da, b + db
                    if 0 <= u < m.shape[0] and 0 <= v < m.shape[1] and m[u, v] and not lab[u, v]:
                        lab[u, v] = n; q.append((u, v))
            if len(pts) >= 12:
                for a, b in pts:
                    keep[a, b] = True
        alpha = np.asarray(Image.fromarray((keep * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.6))).astype(np.float32)
        alpha = np.clip((alpha - 40) * 1.6, 0, 255)
        ys, xs = np.nonzero(alpha > 20)
        bx0, by0, bx1, by1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
        rgba = np.dstack([c, alpha])[by0:by1, bx0:bx1].astype(np.uint8)
        sprite = Image.fromarray(rgba, "RGBA")
        h = int(it["hauteur_ecran"])
        w = max(1, round(sprite.width * h / sprite.height))
        # réduction en espace prémultiplié (pas de franges sombres sur les bords)
        arr = np.asarray(sprite).astype(np.float32)
        pm = arr.copy(); pm[..., :3] *= arr[..., 3:4] / 255.0
        small = np.dstack([np.asarray(Image.fromarray(pm[..., k].astype(np.float32), "F").resize((w, h), Image.LANCZOS)) for k in range(4)])
        small[..., 3] = np.clip(small[..., 3], 0, 255)
        rgb = np.where(small[..., 3:4] > 1, small[..., :3] * 255.0 / np.maximum(small[..., 3:4], 1), 0)
        out = np.dstack([np.clip(rgb, 0, 255), small[..., 3]]).astype(np.uint8)
        Image.fromarray(out, "RGBA").save(os.path.join(JEU if it.get("jeu") else OUT, name + ".png"))
        col = (out[..., 3] > 64).any(0).nonzero()[0]
        index[name] = {"taille": [w, h], "appui": [round((col.min() + col.max() + 1) / 2), h], "source": sheet, "boite": it["boite"]}
        print("%-18s %3d×%-3d (source %d×%d)" % (name, w, h, bx1 - bx0, by1 - by0))
json.dump(index, open(os.path.join(OUT, "index.json"), "w"), indent=1)
