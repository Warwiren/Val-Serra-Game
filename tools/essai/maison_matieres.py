"""ESSAI — maison : MATIÈRES du concept C posées sur la GÉOMÉTRIE EXACTE du gabarit (pas de nouvelle architecture).
Le gabarit (rendu de la scène du jeu) donne pour chaque pixel sa matière (carte de zones) et son éclairage ;
on remplace la couleur par la texture correspondante prélevée sur le concept :
  ardoise -> tuiles moussues du toit, enduit -> enduit, poutre -> bois des colombages, pierre -> soubassement,
  porte -> la porte du concept, redimensionnée DANS le rectangle de la porte du gabarit,
  fenêtres -> la fenêtre éclairée du concept, dans chacun des trois rectangles de fenêtre du gabarit.
L'éclairage du gabarit module la texture (lune, contre-jour, fenêtres), puis un étalonnage crépusculaire.
Porte, fenêtres, toit, silhouette et emprise restent exactement ceux du gabarit.
Sortie : art/explore_hd2d/essai_<v>/maison.png (+ pivot dans essai.json).
    python3 tools/essai/maison_matieres.py [v2]"""
import json, sys
import numpy as np
from PIL import Image

V = sys.argv[1] if len(sys.argv) > 1 else "v2"
OUT = "art/explore_hd2d/essai_%s/" % V
GAB = "docs/media/gabarits_exploration/"
meta = json.load(open(GAB + "gabarits.json"))
box = meta["elements"]["maison"]["rectangle_ecran"]                      # [597, 0, 1000, 381]
full = np.asarray(Image.open(GAB + "maison/maison_complete_cadre_1408x800.png").convert("RGBA")).astype(np.float32)
full = full[box[1]:box[3], box[0]:box[2]]
zones = np.asarray(Image.open(GAB + "maison/maison_zones.png").convert("RGBA")).astype(np.float32)
leg = {k: np.array([int(v[i:i + 2], 16) for i in (1, 3, 5)], np.float32) for k, v in json.load(open(GAB + "legende_zones.json")).items()}
H, W = full.shape[:2]
alpha = full[..., 3]
concept = np.asarray(Image.open("art/source/concepts_2026-11-06/concept_c_arbre_maison_buissons.webp").convert("RGBA")).astype(np.float32)
C = concept[24:684, 772:1516]                                            # maison du concept (repère de la grille)


def zone(name, tol=45):
    return (np.abs(zones[..., :3] - leg[name]).sum(-1) < tol) & (zones[..., 3] > 100)


def tile(crop, h, w, flip_rows=True):
    """Texture répétée sans couture visible : miroir alterné."""
    t = crop[..., :3]
    t2 = np.concatenate([t, t[:, ::-1]], 1)
    t2 = np.concatenate([t2, t2[::-1]], 0) if flip_rows else t2
    reps = (h // t2.shape[0] + 1, w // t2.shape[1] + 1, 1)
    return np.tile(t2, reps)[:h, :w]


lum = full[..., :3].mean(-1)
out = full[..., :3].copy()


def apply(mask, tex, gain=1.0):
    if not mask.any():
        return
    l = lum[mask]
    ref = np.percentile(l, 60) + 1
    shade = np.clip(lum / ref, 0.55, 1.25)[..., None] ** 0.8               # éclairage du gabarit, adouci
    t = tex * shade * gain
    out[mask] = t[mask]


# textures (coordonnées dans la maison du concept, voir docs/media/essai_v2/maison_concept_grille.png)
ROOF = C[205:262, 175:395]                                               # tuiles + mousse (sous la poutre faîtière)
PLASTER = C[335:395, 565:640]
WOOD = C[440:462, 190:330]                                               # sablière horizontale
STONE = C[515:575, 455:620]
roof_m = zone("ardoise") | zone("mousse")


def roof_tex():
    """Tuiles du concept suivant la pente du toit du gabarit : rangées parallèles à l'égout, pas d'effet miroir.
    Lecture dans le concept le long de ses propres rangées (pente -0,17), raccords adoucis entre bandes."""
    S_G, S_C = -0.205, -0.17                         # pentes des rangées : gabarit (égout), concept (poutre)
    y0c, x0c, wc, hc = 200, 170, 230, 56
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    u = np.mod(xx, wc); band = np.floor(xx / wc)
    v = np.mod(yy - S_G * xx + band * 17, hc)
    cx = (x0c + u).astype(int); cy = (y0c + v + S_C * u).astype(int)
    t = C[np.clip(cy, 0, C.shape[0] - 1), np.clip(cx, 0, C.shape[1] - 1), :3]
    w = np.clip(np.minimum(u, wc - u) / 12.0, 0, 1)[..., None]                  # fondu aux raccords de bandes
    t2 = C[np.clip(cy, 0, C.shape[0] - 1), np.clip((x0c + np.mod(u + wc / 2, wc)).astype(int), 0, C.shape[1] - 1), :3]
    return t * w + t2 * (1 - w)


apply(roof_m, roof_tex(), 1.05)
rng = np.random.default_rng(4)


def flat(crop, grain):
    """Matière unie à la couleur médiane du concept + grain fin (orientation libre : colombages en biais)."""
    col = np.median(crop[..., :3].reshape(-1, 3), 0)
    n = rng.normal(0, grain, (H, W, 1))
    n = (n + np.roll(n, 1, 0) + np.roll(n, 1, 1)) / 3
    return col + n


apply(zone("enduit"), flat(PLASTER, 7), 1.0)
beam_m = zone("poutre")
apply(beam_m, flat(WOOD, 9), 1.0)
apply(zone("pierre"), tile(STONE, H, W), 0.95)


def paste_into(rect, crop):
    x0, y0, x1, y1 = rect
    im = Image.fromarray(crop.astype(np.uint8)).resize((x1 - x0, y1 - y0), Image.LANCZOS)
    a = np.asarray(im).astype(np.float32)
    m = a[..., 3:4] / 255.0
    out[y0:y1, x0:x1] = out[y0:y1, x0:x1] * (1 - m) + a[..., :3] * m


ops = meta.get("ouvertures_maison_ecran", [])
for o in ops:
    x0, y0, x1, y1 = o["rectangle_dans_gabarit"]
    if o["type"] == "porte":
        paste_into((x0 - 1, y0 - 1, x1 + 1, y1 + 2), C[453:582, 352:444])
    else:
        paste_into((x0 - 3, y0 - 3, x1 + 3, y1 + 3), C[422:505, 520:615])
# étalonnage crépusculaire léger (ombres bleu-violet), les fenêtres restent chaudes
warm = (out[..., 0] > 170) & (out[..., 0] > out[..., 2] * 1.4)
cool = out * np.array([0.86, 0.86, 1.0]) + np.array([4, 2, 14])
out = np.where(warm[..., None], out, cool)
res = np.dstack([np.clip(out, 0, 255), alpha]).astype(np.uint8)
Image.fromarray(res).save(OUT + "maison.png")
zone_json = json.load(open("art/explore_hd2d/zone.json"))["sprites"]["maison"]
fp = zone_json["footprint"]
foot = (sum(p[0] for p in fp) / len(fp), zone_json["sort_y"])
spec_p = OUT + "essai.json"
spec = json.load(open(spec_p))
spec["remplace"]["maison"] = {"calques": ["maison"], "pivot": [round(foot[0] * 2 - box[0], 2), round(foot[1] * 2 - box[1], 2)]}
json.dump(spec, open(spec_p, "w"), indent=1, ensure_ascii=False)
print("maison : %d×%d, %d ouvertures reposées, pivot %s" % (W, H, len(ops), spec["remplace"]["maison"]["pivot"]))
