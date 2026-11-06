"""Intègre une ILLUSTRATION REPEINTE à la place d'un plan rendu de l'arène, sans toucher au code ni aux ancrages.

    python3 tools/arena/import_illustration.py <plan> <image_peinte.png> [--arene art/arena/lisiere]
                                               [--sans-palette] [--contour]
    <plan> : base | loin | lisiere | avant

Formats acceptés (voir docs/ARENE_COMBAT.md, « Kit d'illustration ») :
  - pixel art à la taille native 432×244 (recommandé) : repris tel quel ;
  - illustration à ×2, ×3 ou ×4 (864×488, 1296×732, 1728×976) : réduite par blocs (couleur dominante du bloc,
    pas de flou), pour garder des aplats nets.
Traitements : alpha binarisé (aucun pixel semi-transparent), base forcée opaque, couleurs ramenées à la palette
commune de l'exploration (sauf --sans-palette), contour d'1 px optionnel (--contour, plans lisière/avant).
Contrôles affichés : couverture par rapport au plan rendu (silhouette conservée ?), lanternes toujours au même
endroit (les lumières Godot et l'éclairage du Vorgane en dépendent), nombre de couleurs.
Sortie : <arène>/peint/<plan>.png. Le jeu l'utilise automatiquement à la place du plan rendu ; supprimer le
fichier pour revenir au rendu. Le plan rendu n'est jamais écrasé."""
import argparse, json, os, sys
import numpy as np
from PIL import Image

ap = argparse.ArgumentParser()
ap.add_argument("plan", choices=["base", "loin", "lisiere", "avant"])
ap.add_argument("image")
ap.add_argument("--arene", default="art/arena/lisiere")
ap.add_argument("--sans-palette", action="store_true")
ap.add_argument("--contour", action="store_true")
a = ap.parse_args()

data = json.load(open(os.path.join(a.arene, "arena.json")))
NW, NH = data["native"]
src = np.asarray(Image.open(a.image).convert("RGBA")).astype(np.int32)
h, w = src.shape[:2]
k = w // NW
if k < 1 or w != NW * k or h != NH * k:
    sys.exit("taille %d×%d refusée : attendu %d×%d ou un multiple entier (×2, ×3, ×4)" % (w, h, NW, NH))

if k > 1:                                                     # couleur dominante de chaque bloc k×k
    blk = src.reshape(NH, k, NW, k, 4).transpose(0, 2, 1, 3, 4).reshape(NH, NW, k * k, 4)
    alpha = (blk[..., 3] > 127).mean(-1) >= 0.5
    q = (blk[..., :3] // 8)
    key = q[..., 0] * 1024 + q[..., 1] * 32 + q[..., 2]
    out = np.zeros((NH, NW, 3), np.int32)
    for y in range(NH):
        for x in range(NW):
            vals, cnt = np.unique(key[y, x], return_counts=True)
            sel = key[y, x] == vals[cnt.argmax()]
            out[y, x] = blk[y, x][sel, :3].mean(0)
else:
    out = src[..., :3].copy()
    alpha = src[..., 3] > 127
if a.plan == "base":
    alpha[:] = True

ref = np.asarray(Image.open(os.path.join(a.arene, a.plan + ".png")).convert("RGBA"))
if not a.sans_palette:                                        # palette commune : couleurs déjà employées par l'arène
    pal = []
    for n in ("base", "loin", "lisiere", "avant"):
        im = np.asarray(Image.open(os.path.join(a.arene, n + ".png")).convert("RGBA")).reshape(-1, 4)
        pal.append(im[im[:, 3] > 200][:, :3])
    pal = np.unique(np.concatenate(pal), axis=0).astype(np.int32)
    flat = out.reshape(-1, 3)
    idx = np.zeros(len(flat), int)
    for i in range(0, len(flat), 20000):
        idx[i:i + 20000] = ((flat[i:i + 20000, None] - pal[None]) ** 2).sum(-1).argmin(1)
    out = pal[idx].reshape(NH, NW, 3)
if a.contour and a.plan in ("lisiere", "avant"):
    nb = sum(np.roll(np.roll(alpha, dy, 0), dx, 1).astype(int) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    e = alpha & (nb < 4)
    out[e] = (out[e] * 0.45 + np.array([8, 8, 18]) * 0.55).astype(np.int32)

res = np.dstack([out, np.where(alpha, 255, 0)]).astype(np.uint8)
os.makedirs(os.path.join(a.arene, "peint"), exist_ok=True)
dst = os.path.join(a.arene, "peint", a.plan + ".png")
Image.fromarray(res, "RGBA").save(dst)

# --- contrôles ---------------------------------------------------------------------------------------------
ref_a = ref[..., 3] > 127
inter = (ref_a & alpha).sum() / max(1, ref_a.sum())
print("plan %s : %s → %s (×%d)" % (a.plan, a.image, dst, k))
print("  couleurs : %d · couverture de la silhouette rendue : %.0f %% · pixels opaques : %d (rendu : %d)"
      % (len(np.unique(res[alpha][:, :3], axis=0)), inter * 100, alpha.sum(), ref_a.sum()))
if a.plan == "lisiere":
    for p in data["lights"]:
        x, y = int(round(p[0])), int(round(p[1]))
        win = res[max(0, y - 2):y + 3, max(0, x - 2):x + 3]
        warm = ((win[..., 3] > 0) & (win[..., 0] > 200) & (win[..., 0] >= win[..., 2])).any()
        print("  lanterne (%d, %d) : %s" % (x, y, "présente" if warm else "ABSENTE — la lumière Godot tombera dans le vide"))
if inter < 0.7 and a.plan != "base":
    print("  ATTENTION : la silhouette s'écarte beaucoup du rendu (zones du HUD et des combattants à revérifier)")
