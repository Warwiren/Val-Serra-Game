"""Sprites d'exploration HD-2D à l'échelle de la zone (20 px natifs / m, affichage ×2) :
  Aren : réextrait des planches à 29 px de haut (≈ 58 px à l'écran), 4 directions, retouché (aren_retouch.py).
  Ilya, Throné, garde : réduction PROVISOIRE des sprites du pack (même rapport 29/37) ; marche = images existantes.
  Vorgane : animation de repos (calques composés), réduite au même rapport, tournée vers la droite.
Usage : python3 build_chars.py <planches_aren> <dossier_art_proto> <sortie>"""
import glob, os, subprocess, sys
import numpy as np
from PIL import Image

REF, ART, OUT = sys.argv[1:4]
F = 29 / 37
here = os.path.dirname(os.path.abspath(__file__))
os.makedirs(os.path.join(OUT, "aren"), exist_ok=True)
env = dict(os.environ, AREN_H="29")
subprocess.run([sys.executable, os.path.join(here, "..", "art", "aren_sheets.py"), REF, os.path.join(OUT, "aren")], env=env, check=True, stdout=subprocess.DEVNULL)
subprocess.run([sys.executable, os.path.join(here, "..", "art", "aren_retouch.py"), os.path.join(OUT, "aren")], check=True)
for f in glob.glob(os.path.join(OUT, "aren", "*.png")):          # on ne garde que l'exploration
    n = os.path.basename(f)
    if not (n.startswith("idle_") or n.startswith("walk_")):
        os.remove(f)


def shrink(im, f):
    a = np.asarray(im.convert("RGBA")).astype(np.float32)
    h, w = a.shape[:2]
    nh, nw = max(1, round(h * f)), max(1, round(w * f))
    out = np.zeros((nh, nw, 4), np.uint8)
    for y in range(nh):
        for x in range(nw):
            blk = a[int(y / f):max(int(y / f) + 1, int((y + 1) / f)), int(x / f):max(int(x / f) + 1, int((x + 1) / f))].reshape(-1, 4)
            op = blk[blk[:, 3] > 0]
            if len(op) >= len(blk) * 0.5:
                out[y, x, :3] = np.median(op[:, :3], axis=0); out[y, x, 3] = 255
    al = out[..., 3] > 0                                         # contour sombre (lisibilité à petite taille)
    nb = sum(np.roll(np.roll(al, dy, 0), dx, 1).astype(int) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    e = al & (nb < 4)
    out[e, :3] = (out[e, :3] * 0.5).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


for k in ("ilya", "throne", "pnj"):
    os.makedirs(os.path.join(OUT, k), exist_ok=True)
    shrink(Image.open(os.path.join(ART, k + ".png")), F).save(os.path.join(OUT, k, "idle.png"))
    shrink(Image.open(os.path.join(ART, k + "_1.png")), F).save(os.path.join(OUT, k, "idle_1.png"))
    for i in range(4):
        p = os.path.join(ART, "%s_walk_%d.png" % (k, i))
        if os.path.exists(p):
            shrink(Image.open(p), F).save(os.path.join(OUT, k, "walk_%d.png" % i))
os.makedirs(os.path.join(OUT, "vorgane"), exist_ok=True)
V = os.path.join(ART, "vorgane_nuit_p1")
for i, fr in enumerate([1, 7, 13, 19, 25, 31, 37, 43]):
    im = Image.open(os.path.join(V, "base", "idle_%03d.png" % fr)).convert("RGBA")
    for l in ("carapace", "griffe", "glande"):
        im.alpha_composite(Image.open(os.path.join(V, l, "idle_%03d.png" % fr)).convert("RGBA"))
    im = im.crop(im.getbbox()) if i == 0 or True else im
    shrink(im, F).transpose(Image.FLIP_LEFT_RIGHT).save(os.path.join(OUT, "vorgane", "idle_%d.png" % i))
print("personnages d'exploration : ok")
