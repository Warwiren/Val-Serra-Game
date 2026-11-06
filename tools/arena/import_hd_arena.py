"""Arène « Lisière » : intégration de l'ILLUSTRATION fournie (art/source/planches_2026-11-06/4_arene_lisiere.webp)
comme décor de combat, en qualité d'origine (pas de pixellisation) : une seule mise à l'échelle de l'écran
(1590×896 -> 1296×732, Lanczos, recadrage de 1 à 2 px sur les côtés), affichée 1:1 dans le jeu.
Écrit art/arena/lisiere/peint/hd_base.png et hd.json (lanternes repérées dans l'illustration, en pixels de la
texture, pour les lumières Godot et l'éclairage du Vorgane).
    python3 tools/arena/import_hd_arena.py"""
import json, os
from PIL import Image

SRC = "art/source/planches_2026-11-06/4_arene_lisiere.webp"
OUT = "art/arena/lisiere/peint"
W, H = 1296, 732
im = Image.open(SRC).convert("RGB")
k = H / im.height
w = round(im.width * k)
big = im.resize((w, H), Image.LANCZOS)
x0 = (w - W) // 2
big.crop((x0, 0, x0 + W, H)).save(os.path.join(OUT if os.path.isdir(OUT) else (os.makedirs(OUT) or OUT), "hd_base.png"))
# lanternes de l'illustration (coordonnées de la source) : poteau central, maison (×2), deux au fond à gauche
LANTERNES = [(996, 322), (1266, 312), (1432, 318), (668, 292), (110, 282)]
lights = [[round(x * k - x0, 1), round(y * k, 1)] for (x, y) in LANTERNES]
json.dump({"image": "hd_base.png", "taille": [W, H], "source": SRC, "echelle": round(k, 5), "lumieres": lights,
           "plans": "illustration unique : les plans loin/lisière/avant attendent la version en calques"},
          open(os.path.join(OUT, "hd.json"), "w"), indent=1, ensure_ascii=False)
print("arène HD : %d×%d (échelle %.4f), lanternes %s" % (W, H, k, lights))
