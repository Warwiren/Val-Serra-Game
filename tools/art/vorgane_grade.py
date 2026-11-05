"""Étalonnage du Vorgane pixelisé (correctif P0 « netteté et intégration ») : chaque calque est remappé
sur une rampe de couleurs propre, comme la référence du pack (corps sombre brun-violet, cristaux violet-magenta
saturés, griffes ivoire, glande cyan). Les limites de luminance sont calculées sur TOUTES les images d'un calque
(pas de scintillement d'une image à l'autre). Les originaux ne sont pas modifiés.
Usage : python3 vorgane_grade.py <dossier_entrée> <dossier_sortie>"""
import glob, json, os, shutil, sys
import numpy as np
from PIL import Image

SRC, OUT = sys.argv[1], sys.argv[2]
RAMPS = {   # positions 0..1 -> couleur
    "base":     [(0.0, (12, 9, 18)), (0.45, (54, 38, 58)), (0.8, (118, 84, 108)), (1.0, (192, 148, 168))],
    "carapace": [(0.0, (26, 18, 72)), (0.3, (88, 40, 160)), (0.65, (176, 70, 222)), (0.88, (236, 140, 250)), (1.0, (255, 222, 255))],
    "griffe":   [(0.0, (48, 36, 30)), (0.5, (170, 140, 102)), (1.0, (250, 236, 200))],
    "glande":   [(0.0, (16, 50, 82)), (0.5, (64, 190, 226)), (1.0, (220, 255, 255))],
}
CHROMA = {"base": 0.18, "carapace": 0.0, "griffe": 0.0, "glande": 0.15}   # part de la couleur d'origine conservée
FAMILY = {"base": "base", "carapace": "carapace", "carapace_broken": "carapace", "griffe": "griffe",
          "griffe_broken": "griffe", "glande": "glande"}


def ramp(v, stops):
    xs = np.array([s[0] for s in stops]); cs = np.array([s[1] for s in stops], float)
    return np.stack([np.interp(v, xs, cs[:, i]) for i in range(3)], -1)


lum = lambda a: a[..., 0] * 0.3 + a[..., 1] * 0.59 + a[..., 2] * 0.11
os.makedirs(OUT, exist_ok=True)
for layer, fam in FAMILY.items():
    files = sorted(glob.glob(os.path.join(SRC, layer, "*.png")))
    imgs = [np.asarray(Image.open(f).convert("RGBA")).astype(float) for f in files]
    allL = np.concatenate([lum(a)[a[..., 3] > 0] for a in imgs])
    lo, hi = np.percentile(allL, 2), np.percentile(allL, 98)
    os.makedirs(os.path.join(OUT, layer), exist_ok=True)
    for f, a in zip(files, imgs):
        m = a[..., 3] > 0
        v = np.clip((lum(a) - lo) / max(1.0, hi - lo), 0, 1)
        col = ramp(v, RAMPS[fam])
        k = CHROMA[fam]
        if k:
            orig = a[..., :3] - lum(a)[..., None]           # chrominance d'origine (reflets bleus du rendu)
            col = col + orig * k
        out = a.copy()
        out[..., :3] = np.where(m[..., None], np.clip(col, 0, 255), 0)
        Image.fromarray(out.astype(np.uint8), "RGBA").save(os.path.join(OUT, layer, os.path.basename(f)))
    print(layer, len(files), "images | luminance %.0f-%.0f" % (lo, hi))
shutil.copy(os.path.join(SRC, "anchors.json"), os.path.join(OUT, "anchors.json"))
