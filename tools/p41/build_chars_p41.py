#!/usr/bin/env python3
"""P4.1 — construit art/p41/ (personnages nets, cohérents exploration / combat / portraits).
  python3 tools/p41/build_chars_p41.py <dossier des planches Drive (Aren_sprites_*.png, Ilya-1.png, Ilya-2.png)>
Sorties :
  art/p41/chars/aren/   exploration 4 directions (idle_*, walk_*_0..3), Aren debout 57 px
  art/p41/chars/ilya/   exploration 4 directions, Ilya debout ≈ 38 px (limite de la source)
  art/p41/chars/pnj/    garde : sprite 32 px du pack (au lieu de sa réduction à 25 px)
  art/p41/chars/vorgane/ repos 8 images = MÊMES images que le combat (calques composés), tourné vers l'ouest
  art/p41/combat/aren/  combat, mêmes noms que art/proto/aren2/, Aren 60 px (affiché ×2 au lieu de 40 px × 3)
  art/p41/combat/ilya/  combat (Ilya-2), mêmes noms que art/proto/ilya_combat/
  art/p41/portraits/ilya/ 6 expressions (Ilya-1)"""
import os, shutil, subprocess, sys, tempfile
from PIL import Image

SRC = sys.argv[1]
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
OUT = os.path.join(ROOT, "art", "p41")
tmp = tempfile.mkdtemp()
subprocess.run([sys.executable, os.path.join(HERE, "sprites_aren.py"), SRC, os.path.join(tmp, "aren")], check=True)
subprocess.run([sys.executable, os.path.join(HERE, "sprites_ilya.py"), SRC, os.path.join(tmp, "ilya")], check=True)


def put(src, *dst):
    p = os.path.join(OUT, *dst)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    shutil.copyfile(src, p)


for f in os.listdir(os.path.join(tmp, "aren", "explo")):
    put(os.path.join(tmp, "aren", "explo", f), "chars", "aren", f)
for f in os.listdir(os.path.join(tmp, "aren", "combat")):
    put(os.path.join(tmp, "aren", "combat", f), "combat", "aren", f)
for f in os.listdir(os.path.join(tmp, "ilya", "explo")):
    put(os.path.join(tmp, "ilya", "explo", f), "chars", "ilya", f)
for f in os.listdir(os.path.join(tmp, "ilya", "combat")):
    put(os.path.join(tmp, "ilya", "combat", f), "combat", "ilya", f)
for f in os.listdir(os.path.join(tmp, "ilya", "portraits")):
    put(os.path.join(tmp, "ilya", "portraits", f), "portraits", "ilya", f)
ART = os.path.join(ROOT, "art", "proto")
put(os.path.join(ART, "pnj.png"), "chars", "pnj", "idle.png")
put(os.path.join(ART, "pnj_1.png"), "chars", "pnj", "idle_1.png")
V = os.path.join(ART, "vorgane_nuit_p1")
os.makedirs(os.path.join(OUT, "chars", "vorgane"), exist_ok=True)
box = None
ims = []
for fr in [1, 7, 13, 19, 25, 31, 37, 43]:
    im = Image.open(os.path.join(V, "base", "idle_%03d.png" % fr)).convert("RGBA")
    for layer in ("carapace", "griffe", "glande"):
        im.alpha_composite(Image.open(os.path.join(V, layer, "idle_%03d.png" % fr)).convert("RGBA"))
    ims.append(im)
    b = im.getbbox()
    box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
for i, im in enumerate(ims):
    # même cadrage pour les 8 images (pas de saut), pieds sur la dernière rangée
    im.crop((box[0] - 2, box[1] - 2, box[2] + 2, box[3])).transpose(Image.FLIP_LEFT_RIGHT).save(os.path.join(OUT, "chars", "vorgane", "idle_%d.png" % i))
shutil.rmtree(tmp)
n = sum(len(fs) for _, _, fs in os.walk(OUT))
print("art/p41 :", n, "fichiers")
