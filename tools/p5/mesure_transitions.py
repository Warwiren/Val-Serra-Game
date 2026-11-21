"""Val'Serra — P5.3-B : mesure des transitions herbe / terre sur des captures (même cadrage, même zone).

Usage : python3 tools/p5/mesure_transitions.py <dossier_capture> [<vue> ...]  (zone mesurée : rectangle central 640 × 360)

Classement par pixel : « terre » si R − G > 14 (sinon herbe / végétation) ; fraction de terre lissée sur 15 px.
  - zone_mixte_pct : part de la zone où la fraction lissée est entre 0,15 et 0,85 (transition progressive : plus haut =
    bord moins découpé) ;
  - nettete_bord : écart moyen de luminosité entre les deux côtés immédiats (± 3 px) de la frontière des classes ;
  - longueur_frontiere : longueur de frontière par 1000 px de zone (bord irrégulier, touffes, plaques : plus haut).
"""
import json, sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi


def mesure(p):
    im = np.asarray(Image.open(p).convert("RGB")).astype(float)[180:540, 320:960]
    terre = (im[..., 0] - im[..., 1]) > 14
    f = ndi.uniform_filter(terre.astype(float), 15)
    mixte = ((f > 0.15) & (f < 0.85)).mean() * 100
    fr = terre ^ ndi.binary_erosion(terre)
    L = ndi.gaussian_filter(im.mean(-1), 1)
    gx = np.abs(np.roll(L, -3, 1) - np.roll(L, 3, 1))
    gy = np.abs(np.roll(L, -3, 0) - np.roll(L, 3, 0))
    net = np.maximum(gx, gy)[fr].mean() if fr.any() else 0
    return {"zone_mixte_pct": round(mixte, 1), "nettete_bord": round(float(net), 1),
            "longueur_frontiere": round(fr.sum() / fr.size * 1000, 1), "terre_pct": round(terre.mean() * 100, 1)}


if __name__ == "__main__":
    d = sys.argv[1]
    vues = sys.argv[2:] or ["pilote_chemin", "croisement", "pilote_herbe"]
    print(json.dumps({v: mesure("%s/%s.png" % (d, v)) for v in vues}, ensure_ascii=False))
