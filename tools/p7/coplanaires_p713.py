#!/usr/bin/env python3
"""P7.13 — analyse des triangles exportés par tools/p7/coplanaires_p713.gd.

Cherche les paires de triangles de MÊME plan et de MÊME sens (normales à moins de 0,6°, distance des plans < 3 mm) qui se
recouvrent (aire d'intersection > 4 cm²) : z-fighting garanti si les matières ou les UV diffèrent. Les paires de même nœud
et même matière (aucune différence visible) sont comptées à part. Sortie : groupes (nœud A, nœud B) triés par aire, avec un
point exemple (x, y = profondeur nord-sud, h).
    python3 tools/p7/coplanaires_p713.py <triangles.tsv> [--zone=x0,y0,x1,y1] [--max=40]
"""
import math
import sys
from collections import defaultdict

TOL_D = 0.003
TOL_N = 0.9999
AIRE_MIN = 4e-4


def lire(chemin, zone):
    tris = []
    with open(chemin, encoding="utf-8") as f:
        for ligne in f:
            c = ligne.rstrip("\n").split("\t")
            if len(c) < 12:
                continue
            p = [tuple(float(v) for v in c[3 + 3 * k:6 + 3 * k]) for k in range(3)]
            if zone:
                cx = sum(q[0] for q in p) / 3
                cz = sum(q[2] for q in p) / 3
                if not (zone[0] <= cx <= zone[2] and zone[1] <= cz <= zone[3]):
                    continue
            tris.append((c[0], c[1], int(c[2]), p))
    return tris


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def norme(a):
    l = math.sqrt(dot(a, a))
    return (a[0] / l, a[1] / l, a[2] / l)


def clip(poly, a, b):
    """Sutherland–Hodgman : garde la partie de poly à gauche de l'arête a->b (polygones convexes CCW)."""
    out = []
    def cote(p):
        return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])
    for i in range(len(poly)):
        p, q = poly[i], poly[(i + 1) % len(poly)]
        sp, sq = cote(p), cote(q)
        if sp >= 0:
            out.append(p)
        if (sp >= 0) != (sq >= 0):
            t = sp / (sp - sq)
            out.append((p[0] + t * (q[0] - p[0]), p[1] + t * (q[1] - p[1])))
    return out


def aire(poly):
    s = 0.0
    for i in range(len(poly)):
        p, q = poly[i], poly[(i + 1) % len(poly)]
        s += p[0] * q[1] - q[0] * p[1]
    return s * 0.5


def ccw(t):
    return t if aire(t) > 0 else [t[0], t[2], t[1]]


def lire_vues(log, dossier):
    """Caméras exportées par tools/p7/scintillement_p713.gd et masques des pixels qui basculent (rouge)."""
    from PIL import Image
    vues = []
    for ligne in open(log, encoding="utf-8"):
        if not ligne.startswith("CAMERA "):
            continue
        c = ligne.split()
        i = int(c[1])
        o = tuple(float(v) for v in c[2:5])
        bx = tuple(float(v) for v in c[5:8])
        by = tuple(float(v) for v in c[8:11])
        bz = tuple(float(v) for v in c[11:14])
        fov, w, h = float(c[14]), int(c[15]), int(c[16])
        im = Image.open("%s/masque_%02d.png" % (dossier, i)).convert("RGB")
        px = im.load()
        rouge = set()
        for y in range(h):
            for x in range(w):
                r, g, b = px[x, y]
                if r > 200 and g < 90:
                    rouge.add((x, y))
        vues.append((o, bx, by, bz, fov, w, h, rouge))
    return vues


def projeter(p, vue):
    o, bx, by, bz, fov, w, h, _ = vue
    d = sub(p, o)
    xc, yc, zc = dot(d, bx), dot(d, by), dot(d, bz)
    if zc > -0.5:
        return None
    t = math.tan(math.radians(fov) * 0.5)
    xn = (xc / -zc) / (t * w / h)
    yn = (yc / -zc) / t
    return (int((xn + 1) * 0.5 * w), int((1 - (yn + 1) * 0.5) * h))


def confirmer(groupes, vues):
    """Ne garde que les groupes dont au moins un recouvrement se projette (à 2 px près) sur un pixel qui bascule."""
    garde = {}
    for k, g in groupes.items():
        vus = 0
        for p3 in g[3:]:
            for vue in vues:
                q = projeter(p3, vue)
                if q is None:
                    continue
                if any((q[0] + dx, q[1] + dy) in vue[7] for dx in range(-2, 3) for dy in range(-2, 3)):
                    vus += 1
                    break
        if vus:
            garde[k] = [g[0], g[1], g[2], vus]
    return garde


def main():
    args = sys.argv[1:]
    zone = None
    nmax = 40
    vues = None
    for a in args[1:]:
        if a.startswith("--zone="):
            zone = [float(v) for v in a[7:].split(",")]
        elif a.startswith("--max="):
            nmax = int(a[6:])
        elif a.startswith("--vues="):
            log, dossier = a[7:].split(",")
            vues = lire_vues(log, dossier)
    tris = lire(args[0], zone)
    # plans : normale arrondie (sens compris) + distance ; seaux voisins en distance
    seaux = defaultdict(list)
    infos = []
    for i, (nom, mid, cull, p) in enumerate(tris):
        nrm = norme(cross(sub(p[1], p[0]), sub(p[2], p[0])))
        d = dot(nrm, p[0])
        infos.append((nrm, d))
        if nrm[1] < -0.5:
            continue                      # faces tournées vers le bas : jamais vues (caméra au-dessus)
        cle = (round(nrm[0], 2), round(nrm[1], 2), round(nrm[2], 2), int(math.floor(d / TOL_D)))
        seaux[cle].append(i)
    groupes = defaultdict(lambda: [0.0, 0, None])
    vues = vues
    vus = set()
    for cle, liste in seaux.items():
        cand = list(liste)
        for dd in (-1, 1):
            cand += seaux.get((cle[0], cle[1], cle[2], cle[3] + dd), [])
        if len(cand) < 2:
            continue
        nrm = infos[liste[0]][0]
        ax = (1.0, 0.0, 0.0) if abs(nrm[0]) < 0.9 else (0.0, 1.0, 0.0)
        e1 = norme(cross(nrm, ax))
        e2 = cross(nrm, e1)
        proj = {}
        for i in cand:
            proj[i] = ccw([(dot(q, e1), dot(q, e2)) for q in tris[i][3]])
        bbox = {i: (min(q[0] for q in proj[i]), min(q[1] for q in proj[i]), max(q[0] for q in proj[i]), max(q[1] for q in proj[i])) for i in cand}
        for i in liste:
            for j in cand:
                if j <= i or (i, j) in vus:
                    continue
                vus.add((i, j))
                if dot(infos[i][0], infos[j][0]) < TOL_N or abs(infos[i][1] - infos[j][1]) > TOL_D:
                    continue
                bi, bj = bbox[i], bbox[j]
                if bi[2] <= bj[0] or bj[2] <= bi[0] or bi[3] <= bj[1] or bj[3] <= bi[1]:
                    continue
                poly = proj[i]
                tj = proj[j]
                for k in range(3):
                    poly = clip(poly, tj[k], tj[(k + 1) % 3])
                    if not poly:
                        break
                if len(poly) < 3:
                    continue
                s = aire(poly)
                if s < AIRE_MIN:
                    continue
                a, b = tris[i], tris[j]
                meme = a[0] == b[0] and a[1] == b[1]
                def court(s):
                    p = s.split("#")
                    return p[0].split("/")[-1] + "<" + (p[2] if len(p) > 2 else "") + ">" + (p[1] if len(p) > 1 else "")
                nn = infos[i][0]
                face = "sol" if nn[1] > 0.5 else ("mur %+.0f,%+.0f" % (round(nn[0]), round(nn[2])))
                k2 = ("(même maillage, même matière)" if meme else "") + face + " : " + " | ".join(sorted([court(a[0]), court(b[0])]))
                g = groupes[k2]
                g[0] += s
                g[1] += 1
                if g[2] is None:
                    c = [sum(q[t] for q in a[3]) / 3 for t in range(3)]
                    g[2] = (round(c[0], 2), round(c[2], 2), round(c[1], 2))
                if vues:
                    # point du recouvrement (centre du polygone d'intersection), en 3D
                    u = sum(q[0] for q in poly) / len(poly)
                    v = sum(q[1] for q in poly) / len(poly)
                    dpl = infos[i][1]
                    p3 = tuple(nrm[k] * dpl + e1[k] * u + e2[k] * v for k in range(3))
                    g.append(p3)
    if vues:
        groupes = confirmer(groupes, vues)
    tri = sorted(groupes.items(), key=lambda kv: -kv[1][0])
    vis = [kv for kv in tri if not kv[0].startswith("(même")]
    print("TRIANGLES %d ; groupes de faces coplanaires superposées : %d (dont %d à matières ou nœuds différents)" % (len(tris), len(tri), len(vis)))
    for k, g in vis[:nmax]:
        s, nb, ex = g[0], g[1], g[2]
        extra = ("  [vu scintiller : %d]" % g[3]) if vues else ""
        print("  %7.3f m²  %5d paires  ex. (x %.2f, y %.2f, h %.2f)  %s%s" % (s, nb, ex[0], ex[1], ex[2], k, extra))
    print("COPLANAIRES", len(vis), round(sum(kv[1][0] for kv in vis), 3))


if __name__ == "__main__":
    main()
