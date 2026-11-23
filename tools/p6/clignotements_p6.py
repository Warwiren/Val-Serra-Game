#!/usr/bin/env python3
"""P6.3.2 — mesure des clignotements sur une vidéo (rendu du parcours p6_clignotements).

Un pixel « cligne » à l'image t s'il change nettement entre t-1 et t, puis revient à sa valeur de t-1 à l'image t+1
(aller-retour sur une seule image). Le simple défilement de la caméra (changement monotone) n'est pas compté.
Les 8 % bas de l'image (aide des touches) et le coin du panneau d'objectif sont ignorés.

Usage : python3 tools/p6/clignotements_p6.py video.avi [video2.avi ...]
Sortie : par vidéo, pixels clignotants par image (moyenne, 95e centile, maximum) et images les plus touchées.
"""
import subprocess
import sys

import numpy as np

W, H = 480, 270
SEUIL = 14          # écart de luminance (0-255) pour « changer nettement »
RETOUR = 5          # tolérance pour « revenir à la valeur »


def images(chemin):
    cmd = ["ffmpeg", "-v", "error", "-i", chemin, "-vf", "scale=%d:%d,format=gray" % (W, H), "-f", "rawvideo", "-"]
    brut = subprocess.run(cmd, capture_output=True, check=True).stdout
    n = len(brut) // (W * H)
    return np.frombuffer(brut[: n * W * H], dtype=np.uint8).reshape(n, H, W).astype(np.int16)


def mesure(chemin):
    f = images(chemin)
    masque = np.ones((H, W), dtype=bool)
    masque[int(H * 0.92):, :] = False
    masque[: int(H * 0.12), int(W * 0.68):] = False
    comptes = []
    for t in range(1, len(f) - 1):
        a, b, c = f[t - 1], f[t], f[t + 1]
        cligne = (np.abs(b - a) > SEUIL) & (np.abs(c - b) > SEUIL) & (np.abs(c - a) <= RETOUR) & masque
        comptes.append(int(cligne.sum()))
    comptes = np.array(comptes)
    pires = np.argsort(comptes)[::-1][:5] + 1
    return comptes, pires, len(f)


def main():
    for chemin in sys.argv[1:]:
        comptes, pires, n = mesure(chemin)
        print("%-40s %4d images  clignotants/image : moyenne %.1f  p95 %d  max %d  ; images les plus touchées %s" % (
            chemin.split("/")[-1], n, comptes.mean(), int(np.percentile(comptes, 95)), comptes.max(), list(pires)))


if __name__ == "__main__":
    main()
