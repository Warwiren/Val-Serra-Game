"""Découpe des planches illustrées (fonctions reprises de l'ancien tools/art/aren_sheets.py, P1–P4.1) :
repérage des sprites d'une bande, détourage du fond uni, filets des cadres retirés."""
import numpy as np
from scipy import ndimage


def runs(m, axis):
    """Longueur de la suite continue de pixels allumés à laquelle appartient chaque pixel, le long d'un axe."""
    mm = m if axis == 1 else m.T
    out = np.zeros(mm.shape, int)
    for i, row in enumerate(mm):
        j = 0
        while j < len(row):
            if row[j]:
                k = j
                while k < len(row) and row[k]:
                    k += 1
                out[i, j:k] = k - j
                j = k
            else:
                j += 1
    return out if axis == 1 else out.T


def thin_lines(m):
    """Filets des cadres : longs (> 50 px) et fins (<= 4 px) — les sprites n'ont pas cette forme."""
    h, v = runs(m, 1), runs(m, 0)
    return ((h > 50) & (v <= 4)) | ((v > 50) & (h <= 4))


def sprites_in(img, box, min_h=45):
    x0, y0, x1, y1 = box
    a = img[y0:y1, x0:x1].astype(int)
    bg = np.median(np.concatenate([a[:3].reshape(-1, 3), a[-3:].reshape(-1, 3)]), axis=0)
    m = np.abs(a - bg).sum(-1) > 60
    # filets dorés des cadres : rangées / colonnes presque entièrement « allumées » -> retirées
    m &= ~thin_lines(m)
    lab, n = ndimage.label(ndimage.binary_dilation(m, iterations=4))
    out = []
    for sl in ndimage.find_objects(lab):
        h, w = sl[0].stop - sl[0].start, sl[1].stop - sl[1].start
        if h >= min_h and w >= 25:
            out.append((sl[1].start + x0, sl[0].start + y0, sl[1].stop + x0, sl[0].stop + y0))
    return sorted(out, key=lambda b: b[0]), bg


def cutout(img, box, bg):
    x0, y0, x1, y1 = box
    a = img[y0:y1, x0:x1].astype(int)
    m = np.abs(a - bg).sum(-1) > 45
    m &= ~thin_lines(m)
    lab, n = ndimage.label(ndimage.binary_dilation(m, iterations=3))
    if n == 0:
        return a, m
    sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    keep = np.isin(lab, [i + 1 for i, sz in enumerate(sizes) if sz >= 0.08 * sizes.max()])
    m &= keep
    # les zones très sombres du personnage (pantalon, contours) ressemblent au fond : on referme la silhouette
    m = ndimage.binary_closing(m, iterations=2)
    # seuls les PETITS trous sont rebouchés (zones sombres du costume) ; les grands espaces enfermés
    # (entre les jambes, sous la cape) sont du fond et restent transparents
    holes = ndimage.binary_fill_holes(m) & ~m
    hl, hn = ndimage.label(holes)
    if hn:
        hs = ndimage.sum(np.ones_like(hl), hl, range(1, hn + 1))
        m |= np.isin(hl, [i + 1 for i, sz in enumerate(hs) if sz <= 40])
    return a, m


