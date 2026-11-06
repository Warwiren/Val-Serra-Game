"""Kit de travail pour l'illustrateur qui repeint l'arène : un dossier par plan, aux tailles exactes attendues.
    python3 tools/arena/illustrator_kit.py [art/arena/lisiere] [docs/media/arena/kit_illustrateur]
Produit pour chaque plan (base, loin, lisiere, avant) :
  <plan>_sous-couche_natif.png  le plan actuel, 432×244 (à repeindre en pixel art, format recommandé)
  <plan>_sous-couche_x4.png     le même agrandi ×4 sans flou, 1728×976 (pour une peinture haute définition)
  <plan>_silhouette_x4.png      zone occupée par le plan (blanc), à respecter pour la parallaxe et la lecture
et pour toute l'arène :
  reperes_x4.png   zones réservées au HUD, pieds et encombrement des combattants, ligne de combat, lanternes
                   (calque transparent à poser au-dessus, ×4)
  palette.png / palette.txt   palette commune exploration + arène (cases de 24 px et codes hexadécimaux)"""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw

SRC = sys.argv[1] if len(sys.argv) > 1 else "art/arena/lisiere"
OUT = sys.argv[2] if len(sys.argv) > 2 else "docs/media/arena/kit_illustrateur"
os.makedirs(OUT, exist_ok=True)
d = json.load(open(os.path.join(SRC, "arena.json")))
NW, NH = d["native"]
K = 4
ox, oy = (1280 - NW * 3) // 2, (720 - NH * 3) // 2           # origine écran du décor affiché ×3


def nat(x, y):                                               # écran 1280×720 -> pixels natifs du décor
    return (x - ox) / 3.0, (y - oy) / 3.0


cols = []
for n in ("base", "loin", "lisiere", "avant"):
    im = Image.open(os.path.join(SRC, n + ".png")).convert("RGBA")
    im.save(os.path.join(OUT, "%s_sous-couche_natif.png" % n))
    im.resize((NW * K, NH * K), Image.NEAREST).save(os.path.join(OUT, "%s_sous-couche_x4.png" % n))
    a = np.asarray(im)[..., 3] > 127
    Image.fromarray(np.where(a, 255, 0).astype(np.uint8)).resize((NW * K, NH * K), Image.NEAREST).save(os.path.join(OUT, "%s_silhouette_x4.png" % n))
    px = np.asarray(im).reshape(-1, 4)
    cols.append(px[px[:, 3] > 200][:, :3])
pal = np.unique(np.concatenate(cols), axis=0)
pal = pal[np.argsort(pal.mean(1))]
cell = 24
pim = Image.new("RGB", (cell * 16, cell * ((len(pal) + 15) // 16)), (0, 0, 0))
g = ImageDraw.Draw(pim)
for i, c in enumerate(pal):
    g.rectangle(((i % 16) * cell, (i // 16) * cell, (i % 16) * cell + cell - 1, (i // 16) * cell + cell - 1), fill=tuple(int(v) for v in c))
pim.save(os.path.join(OUT, "palette.png"))
open(os.path.join(OUT, "palette.txt"), "w").write("\n".join("#%02X%02X%02X" % tuple(int(v) for v in c) for c in pal) + "\n")

ov = Image.new("RGBA", (NW * K, NH * K), (0, 0, 0, 0))
g = ImageDraw.Draw(ov)
for (x0, y0, x1, y1), lab in [((322, 8, 958, 92), "HUD : initiative"), ((1004, 4, 1268, 216), "HUD : groupe"),
                              ((420, 550, 980, 586), "HUD : PV du monstre"), ((14, 570, 1268, 714), "HUD : actions"),
                              ((8, 10, 300, 56), "titre")]:
    a0, b0 = nat(x0, y0); a1, b1 = nat(x1, y1)
    g.rectangle((a0 * K, b0 * K, a1 * K, b1 * K), fill=(30, 40, 90, 90), outline=(255, 255, 255, 200), width=3)
    g.text((a0 * K + 8, b0 * K + 6), lab, fill=(255, 255, 255, 255))
for (x, y), (w, h), lab in [((330, 506), (380, 190), "Vorgane"), ((900, 500), (90, 130), "Aren"),
                            ((1028, 468), (80, 120), "Ilya"), ((1150, 492), (100, 130), "Throné")]:
    a0, b0 = nat(x - w / 2, y - h); a1, b1 = nat(x + w / 2, y)
    g.rectangle((a0 * K, b0 * K, a1 * K, b1 * K), outline=(255, 200, 80, 255), width=3)
    fx, fy = nat(x, y)
    g.ellipse((fx * K - 10, fy * K - 6, fx * K + 10, fy * K + 6), fill=(255, 200, 80, 255))
    g.text((a0 * K + 8, b0 * K + 6), lab + " (pieds)", fill=(255, 220, 140, 255))
p0, p1 = d["ligne_combat"]
g.line((p0[0] * K, p0[1] * K, p1[0] * K, p1[1] * K), fill=(120, 220, 255, 230), width=3)
for p in d["lights"]:
    g.ellipse((p[0] * K - 14, p[1] * K - 14, p[0] * K + 14, p[1] * K + 14), outline=(255, 150, 50, 255), width=4)
    g.text((p[0] * K + 18, p[1] * K - 8), "lanterne (ne pas déplacer)", fill=(255, 180, 90, 255))
ov.save(os.path.join(OUT, "reperes_x4.png"))
print("kit :", OUT, "· palette %d couleurs" % len(pal))
