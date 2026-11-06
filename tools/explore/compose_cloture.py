"""Clôtures d'exploration à partir des sections de la planche (vue de face) : sections mises bout à bout, mises
à la longueur du tracé, puis CISAILLÉES pour suivre la pente de la clôture dans la projection du jeu (les
poteaux restent verticaux, les lisses suivent le tracé). Le tracé vient de l'emprise au sol (zone.json).
    python3 tools/explore/compose_cloture.py"""
import json
import numpy as np
from PIL import Image

D = "art/explore_hd2d/"
X = "art/source/planches_2026-11-06/extraits/"
zone = json.load(open(D + "zone.json"))
longue = Image.open(X + "cloture_longue.png")
courte = Image.open(X + "cloture_courte.png")
out = {}
for name in ("cloture_d", "cloture_g"):
    fp = zone["sprites"][name]["footprint"]
    left = max(fp, key=lambda p: p[1])                 # avant gauche : point le plus bas de l'emprise
    right = max(fp, key=lambda p: p[0])                # extrémité droite
    L = (right[0] - left[0]) * 2.0                     # longueur à l'écran (×2)
    rise = (left[1] - right[1]) * 2.0
    strip = Image.new("RGBA", (longue.width + courte.width - 8, longue.height))
    strip.alpha_composite(longue, (0, 0)); strip.alpha_composite(courte, (longue.width - 8, 0))
    strip = strip.resize((int(round(L)), strip.height), Image.LANCZOS)
    a = np.asarray(strip)
    H = a.shape[0] + int(np.ceil(abs(rise)))
    res = np.zeros((H, a.shape[1], 4), np.uint8)
    for x in range(a.shape[1]):
        dy = int(round(rise * x / a.shape[1]))
        res[H - a.shape[0] - dy:H - dy, x] = a[:, x]
    Image.fromarray(res).save(D + "illustre/%s.png" % name)
    out[name] = {"pivot": [0, H], "point_sol": left}
    print(name, res.shape[1], "×", H, "pente", round(rise / L, 3))
json.dump(out, open(X + "clotures.json", "w"), indent=1)
