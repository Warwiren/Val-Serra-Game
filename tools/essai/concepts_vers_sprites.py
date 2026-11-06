"""ESSAI — sprites d'exploration tirés des concepts fournis (planche C, fond réellement transparent) :
grand arbre (tronc et feuillage séparés) et buissons. Pour chaque élément :
  1. détourage : alpha d'origine, halo d'ombre douce supprimé (seuil), bords adoucis sur 1 px ;
  2. étalonnage crépusculaire : couleurs rapprochées (60 %) de celles de la lisière peinte de l'esquisse de sol,
     pour que l'élément appartienne à la même lumière que le sol ;
  3. une seule réduction (Lanczos, en prémultiplié) à la taille d'affichage de l'élément qu'il remplace ;
  4. arbre : séparation tronc / feuillage par la couleur (feuillage = tout ce qui n'est pas brun (écorce) au-dessus de la butte du pied).
Sorties : art/explore_hd2d/essai_v1/*.png + essai.json (pivots). Les sources ne sont jamais modifiées.
    python3 tools/essai/concepts_vers_sprites.py"""
import json, os, sys
import numpy as np
from PIL import Image

SRC = "art/source/concepts_2026-11-06/concept_c_arbre_maison_buissons.webp"
SOL = "art/source/sol/sol_plaque_essai_%s.png" % (sys.argv[1] if len(sys.argv) > 1 else "v2")
import sys
VERSION = sys.argv[1] if len(sys.argv) > 1 else "v2"
OUT = "art/explore_hd2d/essai_%s/" % VERSION
D = "art/explore_hd2d/"
os.makedirs(OUT, exist_ok=True)
zone = json.load(open(D + "zone.json"))
sheet = np.asarray(Image.open(SRC).convert("RGBA")).astype(np.float32)

# couleurs cibles : la lisière de forêt peinte dans l'esquisse (même lumière que le sol)
sol = np.asarray(Image.open(SOL).convert("RGB")).astype(np.float32)
ref = sol[20:220].reshape(-1, 3)
REF_MEAN, REF_STD = ref.mean(0), ref.std(0)


def grade(rgb, mask, strength=0.6):
    px = rgb[mask]
    m, s = px.mean(0), px.std(0) + 1e-3
    tgt = (rgb - m) / s * (s * (1 - strength) + REF_STD * strength) + (m * (1 - strength) + REF_MEAN * strength)
    return np.clip(tgt, 0, 255)


def cut(box, alpha_lo=120):
    x0, y0, x1, y1 = box
    a = sheet[y0:y1, x0:x1].copy()
    al = np.clip((a[..., 3] - alpha_lo) * 255.0 / (255 - alpha_lo), 0, 255)       # halo d'ombre supprimé
    ys, xs = np.nonzero(al > 8)
    a = a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]; al = al[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    a[..., 3] = al
    a[..., :3] = grade(a[..., :3], al > 128)
    return a


def shrink(a, w, h):
    pm = a.copy(); pm[..., :3] *= a[..., 3:4] / 255.0
    ch = [np.asarray(Image.fromarray(pm[..., k].astype(np.float32), "F").resize((w, h), Image.LANCZOS)) for k in range(4)]
    s = np.dstack(ch); al = np.clip(s[..., 3], 0, 255)
    rgb = np.where(al[..., None] > 1, s[..., :3] * 255.0 / np.maximum(al[..., None], 1), 0)
    return np.dstack([np.clip(rgb, 0, 255), al]).astype(np.uint8)


spec = {"remplace": {}, "masquer": ["muret"],                  # le sol d'essai peint son propre bord bas
        # détails au sol : le sol peint a déjà ses pierres, herbes et fleurs ; on ne garde que les traces d'Aether
        # (sinon doublons « collés » par-dessus la peinture, avec leur propre ombre)
        "sol_gardes": ["cristal_aether", "cristal_petit"]}
# --- grand arbre (arbre_g) : même pied, même hauteur d'affichage que le gabarit ---------------------------------
tree = cut((44, 36, 712, 668))
g = json.load(open("docs/media/gabarits_exploration/gabarits.json"))["elements"]["arbre"]
target_h = g["taille"][1] - 48                                   # gabarit sans marges
k = target_h / tree.shape[0]
w, h = round(tree.shape[1] * k), target_h
small = shrink(tree, w, h).astype(np.float32)
rgb = small[..., :3]; al = small[..., 3]
rows = np.arange(h)[:, None]
brownish = (rgb[..., 0] >= rgb[..., 1] * 1.06) & (rgb[..., 0] > rgb[..., 2] * 1.05)       # écorce, branches
sat = rgb.max(-1) - rgb.min(-1)
brownish |= (sat < 18) & (rgb.mean(-1) < 75) & (rows > h * 0.45)                         # écorce dans l'ombre
clear_green = (rgb[..., 1] > rgb[..., 0] * 1.12) & (rgb[..., 1] >= rgb[..., 2])
brownish |= (rows > h * 0.58) & ~clear_green                                              # bas du tronc
green = ~brownish
rows = np.arange(h)[:, None]
mound = rows > h * 0.80                                          # butte, racines et herbe du pied : avec le tronc
fol = green & ~mound & (al > 8)
trunk = small.copy(); trunk[fol, 3] = 0
leaves = small.copy(); leaves[~fol, 3] = 0
Image.fromarray(trunk.astype(np.uint8)).save(OUT + "arbre_tronc.png")
Image.fromarray(leaves.astype(np.uint8)).save(OUT + "arbre_feuillage.png")
brown = (~green) & (al > 128) & (rows > h * 0.62) & (rows < h * 0.80)  # pied : milieu du tronc au-dessus de la butte
foot_x = int(np.median(np.nonzero(brown)[1]))
spec["remplace"]["arbre_g"] = {"calques": ["arbre_tronc", "arbre_feuillage"], "pivot": [foot_x, int(h * 0.93)]}
# arbre de droite (arbre_d) : même essence, en miroir (pas de jumeau visible), à l'échelle de son propre gabarit
# (largeur de son gabarit Blender : 0,97 × celle du grand arbre ; docs/media/gabarits_exploration/arbre_d/)
K_D = 0.97
for nm, arr in (("arbre_d_tronc", trunk), ("arbre_d_feuillage", leaves)):
    im = Image.fromarray(arr.astype(np.uint8)).transpose(Image.FLIP_LEFT_RIGHT)
    im = Image.fromarray(shrink(np.asarray(im).astype(np.float32), round(w * K_D), round(h * K_D)))
    im.save(OUT + nm + ".png")
spec["remplace"]["arbre_d"] = {"calques": ["arbre_d_tronc", "arbre_d_feuillage"], "pivot": [round((w - foot_x) * K_D), round(h * 0.93 * K_D)]}
print("arbre : %d×%d (source %d×%d, ×%.2f), pied x=%d" % (w, h, tree.shape[1], tree.shape[0], k, foot_x))

# --- buissons : chacun remplace un buisson actuel, à sa largeur d'affichage (×1,15) ---------------------------
BOXES = [(60, 720, 328, 872), (364, 720, 608, 868), (644, 720, 884, 868), (916, 724, 1140, 864), (1168, 744, 1320, 860)]
for i, box in enumerate(BOXES):
    name = "buisson_%d" % i
    old = Image.open(D + "el_%s.png" % name)
    b = cut(box)
    w = round(old.width * 2 * 1.15); hh = round(b.shape[0] * w / b.shape[1])
    Image.fromarray(shrink(b, w, hh)).save(OUT + name + ".png")
    spec["remplace"][name] = {"calques": [name], "pivot": [w // 2, int(hh * 0.86)]}
    print("%s : %d×%d (ancien %d×%d à l'écran)" % (name, w, hh, old.width * 2, old.height * 2))
json.dump(spec, open(OUT + "essai.json", "w"), indent=1, ensure_ascii=False)
