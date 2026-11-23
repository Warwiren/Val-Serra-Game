#!/usr/bin/env python3
"""P6.4 — indice de répétition d'une surface sur une capture d'écran.

On prend une zone de la capture (un pan de mur, un sol), on retire les variations lentes (éclairage, dégradés), puis
on calcule l'autocorrélation normalisée de la luminance. Une texture qui se répète (tuile visible) produit des pics
secondaires forts, aux décalages de sa période ; une surface sans répétition n'a que le pic central.

Indice = hauteur du plus fort pic secondaire ISOLÉ (maximum local), hors d'un disque central de 24 px (le grain
propre du motif), entre 0 et 1. Le rythme régulier des joints horizontaux donne une crête continue, non comptée.
Repères : < 0,25 : pas de répétition perceptible ; 0,25–0,45 : rythme régulier (joints, assises) ; > 0,45 : tuile
répétée visible.

Usage : python3 tools/p6/repetition_p64.py capture.png x y l h [capture2.png x y l h ...]
"""
import sys

import numpy as np
from PIL import Image


def indice(chemin, x, y, l, h, r_min=24):
    im = np.asarray(Image.open(chemin).convert("L"), dtype=np.float64)[y:y + h, x:x + l]
    # variations lentes retirées (moyenne glissante large, par intégrale)
    k = 24
    pad = np.pad(im, k, mode="reflect")
    cs = pad.cumsum(0).cumsum(1)
    s = (cs[2 * k:, 2 * k:] - cs[:-2 * k, 2 * k:] - cs[2 * k:, :-2 * k] + cs[:-2 * k, :-2 * k]) / (2 * k) ** 2
    hp = im - s[: im.shape[0], : im.shape[1]]
    hp -= hp.mean()
    win = np.outer(np.hanning(hp.shape[0]), np.hanning(hp.shape[1]))
    f = np.fft.fft2(hp * win, s=(2 * hp.shape[0], 2 * hp.shape[1]))
    ac = np.fft.ifft2(np.abs(f) ** 2).real
    ac = np.fft.fftshift(ac)
    ac /= ac.max()
    cy, cx = np.array(ac.shape) // 2
    yy, xx = np.ogrid[: ac.shape[0], : ac.shape[1]]
    d = np.hypot(yy - cy, xx - cx)
    # pics ISOLÉS seulement (maximum local sur ±7 px) : la décroissance continue le long des joints (rythme des
    # assises) n'est pas une répétition ; recouvrement suffisant (décalages < moitié de la zone)
    loc = np.ones_like(ac, dtype=bool)
    for dy in range(-7, 8):
        for dx in range(-7, 8):
            if dx or dy:
                loc &= ac >= np.roll(np.roll(ac, dy, 0), dx, 1)
    m = loc & (d > r_min) & (np.abs(yy - cy) < h // 2) & (np.abs(xx - cx) < l // 2)
    i = np.argmax(np.where(m, ac, -1))
    py, px = np.unravel_index(i, ac.shape)
    return float(ac[py, px]), (int(px - cx), int(py - cy))


def main():
    a = sys.argv[1:]
    for j in range(0, len(a), 5):
        chemin = a[j]
        x, y, l, h = map(int, a[j + 1: j + 5])
        v, dec = indice(chemin, x, y, l, h)
        print("%-48s zone %4d,%4d %4dx%-4d  indice %.2f  (décalage du pic %s px)" % (chemin.split("/")[-1], x, y, l, h, v, dec))


if __name__ == "__main__":
    main()
