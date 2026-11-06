"""Planche-guide pour l'illustration d'une arène de combat : aperçu du décor à l'échelle d'affichage (×3), avec
les zones réservées au HUD, les points au sol des combattants, la ligne de combat et les lanternes.
Sert de calque de travail à l'illustrateur (peinture par-dessus chaque plan, même format, mêmes ancrages).
Usage : python3 guide_overlay.py <dossier_arene> <sortie.png>"""
import json, os, sys
from PIL import Image, ImageDraw

SRC, OUT = sys.argv[1], sys.argv[2]
d = json.load(open(os.path.join(SRC, "arena.json")))
NW, NH = d["native"]
P = 3
ox, oy = (1280 - NW * P) // 2, (720 - NH * P) // 2
im = Image.open(os.path.join(SRC, "apercu.png")).convert("RGBA").resize((NW * P, NH * P), Image.NEAREST)
canvas = Image.new("RGBA", (1280, 720))
canvas.paste(im, (ox, oy))
ov = Image.new("RGBA", (1280, 720), (0, 0, 0, 0))
g = ImageDraw.Draw(ov)
# zones du HUD de combat (src/presentation/combat_hud.gd) : à garder calmes, sans détail important
for r, lab in [((322, 8, 958, 92), "initiative"), ((1004, 4, 1268, 216), "groupe"), ((420, 550, 980, 586), "PV du monstre"),
               ((14, 570, 1268, 714), "actions"), ((8, 10, 300, 56), "titre")]:
    g.rectangle(r, fill=(20, 30, 60, 110), outline=(255, 255, 255, 160))
    g.text((r[0] + 6, r[1] + 4), lab, fill=(255, 255, 255, 220))
# combattants : point au sol et encombrement approximatif
for (x, y), (w, h), lab in [((330, 506), (380, 190), "Vorgane"), ((900, 500), (90, 130), "Aren"),
                            ((1028, 468), (80, 120), "Ilya"), ((1150, 492), (100, 130), "Throné")]:
    g.rectangle((x - w / 2, y - h, x + w / 2, y), outline=(255, 200, 80, 230), width=2)
    g.ellipse((x - 5, y - 3, x + 5, y + 3), fill=(255, 200, 80, 255))
    g.text((x - w / 2 + 4, y - h + 4), lab, fill=(255, 220, 140, 255))
a, b = d["ligne_combat"]
g.line((ox + a[0] * P, oy + a[1] * P, ox + b[0] * P, oy + b[1] * P), fill=(120, 220, 255, 200), width=2)
for p in d["lights"]:
    x, y = ox + p[0] * P, oy + p[1] * P
    g.ellipse((x - 8, y - 8, x + 8, y + 8), outline=(255, 160, 60, 255), width=2)
Image.alpha_composite(canvas, ov).convert("RGB").save(OUT)
print("guide :", OUT)
