#!/usr/bin/env python3
"""P7.7 — Plan de réalisation de la GRANDE PLACE (tranche suivante), tiré des données de la V0.7-B.

Fond : plan des données (tools/p7/plan_v07a.py) recadré sur la place ; par-dessus, les lots de réalisation numérotés,
les entrées fonctionnelles conservées, les axes de vue de la caméra (regard vers le nord) et les règles de hauteur.
Usage : python3 tools/p7/plan_grande_place_p77.py [sortie.png]
"""
import os
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFont

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(REPO, "docs", "media", "p7_7", "plan_grande_place.png")
DATA = os.path.join(REPO, "data", "p7", "ville_v07b.json")
X0, Y0, K = -40.0, 20.0, 8.0          # repère de tools/p7/plan_v07a.py
CROP = (10.0, 40.0, 104.0, 122.0)     # x0, y0, x1, y1 (m)

# lots : (numéro, titre, rectangles [x0, y0, x1, y1], couleur)
LOTS = [
    (1, "Sol de la place et fontaine", [[30, 88, 72, 115]], (40, 120, 200)),
    (2, "Forge-armurerie et cour de l'atelier", [[44, 76, 58, 88], [30, 76, 44, 88]], (200, 90, 30)),
    (3, "Boutique de fournitures, recoin et commerce voisin", [[76, 76, 88, 88], [72, 88, 88, 100]], (30, 150, 70)),
    (4, "Fond nord : montée civique, socle du palier, arrière-forge, façade sud de l'administration", [[58, 71, 76, 88], [40, 71, 58, 76], [40, 44, 56, 71]], (130, 60, 170)),
    (5, "Étals de bordure (pas de seconde place de marché)", [[31, 110.6, 41, 112.6], [72.6, 95, 75, 98.5], [66, 89, 70, 91]], (220, 160, 20)),
    (6, "Bord sud : parapet balustré sur le vide de 3,5 m", [[14, 114.2, 56, 115.4], [68, 114.2, 80, 115.4]], (200, 40, 40)),
]


def P(x, y):
    return ((x - X0) * K, (y - Y0) * K)


def main():
    tmp = os.path.join(tempfile.mkdtemp(), "fond.png")
    subprocess.run([sys.executable, os.path.join(REPO, "tools", "p7", "plan_v07a.py"), tmp, DATA], check=True, capture_output=True)
    im = Image.open(tmp).convert("RGB")
    a = P(CROP[0], CROP[1])
    b = P(CROP[2], CROP[3])
    im = im.crop((int(a[0]), int(a[1]), int(b[0]), int(b[1])))
    ox, oy = a
    d = ImageDraw.Draw(im, "RGBA")
    try:
        f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
        fp = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 13)
    except OSError:
        f = fp = ImageFont.load_default()

    def R(q):
        p0 = P(q[0], q[1])
        p1 = P(q[2], q[3])
        return [p0[0] - ox, p0[1] - oy, p1[0] - ox, p1[1] - oy]

    for num, titre, rects, c in LOTS:
        for q in rects:
            r = R(q)
            d.rectangle(r, outline=c + (255,), width=4)
            d.rectangle(r, fill=c + (40,))
        r0 = R(rects[0])
        cx, cy = (r0[0] + r0[2]) / 2, (r0[1] + r0[3]) / 2
        d.ellipse([cx - 15, cy - 15, cx + 15, cy + 15], fill=c + (255,), outline=(255, 255, 255, 255), width=2)
        d.text((cx - 5, cy - 9), str(num), fill=(255, 255, 255), font=f)
    # caméra : regard vers le nord ; règle des hauteurs
    for x in (40, 60):
        p0 = P(x, 120.5)
        p1 = P(x, 113.0)
        d.line([p0[0] - ox, p0[1] - oy, p1[0] - ox, p1[1] - oy], fill=(20, 20, 20, 200), width=3)
        d.polygon([(p1[0] - ox, p1[1] - oy - 8), (p1[0] - ox - 7, p1[1] - oy + 6), (p1[0] - ox + 7, p1[1] - oy + 6)], fill=(20, 20, 20, 220))
    d.text((P(41, 119.5)[0] - ox, P(41, 119.5)[1] - oy), "caméra (regard nord) : fond nord haut, bord sud bas", fill=(20, 20, 20), font=fp)
    # légende des lots
    W, H = im.size
    lg = Image.new("RGB", (W, 34 + 24 * len(LOTS)), (245, 242, 235))
    dl = ImageDraw.Draw(lg)
    dl.text((10, 8), "Grande place — lots de réalisation (P7.8, à valider)", fill=(0, 0, 0), font=f)
    for i, (num, titre, _r, c) in enumerate(LOTS):
        y = 34 + 24 * i
        dl.ellipse([10, y, 28, y + 18], fill=c)
        dl.text((15, y + 1), str(num), fill=(255, 255, 255), font=fp)
        dl.text((36, y + 1), titre, fill=(0, 0, 0), font=fp)
    out = Image.new("RGB", (W, H + lg.size[1]), (255, 255, 255))
    out.paste(im, (0, 0))
    out.paste(lg, (0, H))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.save(OUT)
    print("écrit", os.path.relpath(OUT, REPO))


if __name__ == "__main__":
    main()
