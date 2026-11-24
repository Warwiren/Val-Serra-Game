#!/usr/bin/env python3
"""P7.6 — Contrôle géométrique de la caméra de la ville (caméra A) sur tout l'espace praticable, tiré des données.

La caméra A est à un décalage constant d'Aren, mesuré dans le jeu par tools/p7/camera_offset_p76.gd :
(0 ; +21,68 m vers le sud ; +5,84 m de haut). Pour chaque point praticable (pas de 1 m) :
  * CAMÉRA DANS UN VOLUME : la caméra est dans un bâtiment ou sous son toit (le toit couvre alors l'écran) ;
  * VOLUME TROP PROCHE : un volume (toit compris) à moins de 6,6 m de la caméra (entièrement tramé : « proche » de 12 m) ;
  * ARÈN MASQUÉ : le segment Aren (1 m) -> caméra traverse un volume au-delà de la zone tramée (le trou d'occlusion seul
    le rend visible).
Recouvrements : couples de volumes dont les emprises ET les hauteurs se chevauchent (faces confondues, toits qui percent
une façade), plus les volumes flottants (base au-dessus du sol réel).
Usage : python3 tools/p7/camera_volumes_p76.py [data/p7/ville_v07b.json]
"""
import json
import math
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(REPO, "data", "p7", "ville_v07b.json")
DY, DZ = 21.68, 5.84
PROCHE_PLEIN = 12.0 * 0.55


def volumes(d):
    v = d["ajustements"]["p6"]["ville"]
    meta = v.get("batiments", {})
    out = []
    for o in d["ajustements"]["obstacles"]:
        oid = o["id"]
        if oid.startswith(("colisee_tranche", "gc_", "porche_", "decor_garde", "etal_", "decor_caravane")):
            continue
        toit = meta.get(oid, {}).get("toit", "")
        h0, h1 = o["h"], o["h"] + o["haut"]
        cap = (h1 - h0) * 0.7
        out.append((oid, o["rect"], h0, h1, toit, cap))
    for i, p in enumerate(v.get("paysage", [])):
        out.append(("paysage_%d" % i, p["rect"], p["h"], p["h"] + p["haut"], p.get("toit", "2p"), 99.0))
    return out


def haut_toit(r, toit, cap):
    if toit != "2p":
        return 0.0
    court = min(r[2] - r[0], r[3] - r[1])
    return min(max(min(court * 0.42, 6.0), 1.4), max(cap, 1.0))


def dedans(p, vol):
    """p = (x, y, z) dans le volume (boîte + toit à deux pans, débord 0,45 m) ?"""
    _id, r, h0, h1, toit, cap = vol
    x, y, z = p
    d = 0.45
    if not (r[0] - d <= x <= r[2] + d and r[1] - d <= y <= r[3] + d) or z < h0:
        return False
    if r[0] <= x <= r[2] and r[1] <= y <= r[3] and z <= h1:
        return True
    ht = haut_toit(r, toit, cap)
    if ht <= 0.0 or z < h1:
        return False
    long_x = (r[2] - r[0]) >= (r[3] - r[1])
    demi = ((r[3] - r[1]) if long_x else (r[2] - r[0])) * 0.5 + d
    e = abs(y - (r[1] + r[3]) * 0.5) if long_x else abs(x - (r[0] + r[2]) * 0.5)
    return z <= h1 + ht * max(0.0, 1.0 - e / demi)


def dist_boite(p, vol):
    _id, r, h0, h1, toit, cap = vol
    top = h1 + haut_toit(r, toit, cap)
    dx = max(r[0] - 0.45 - p[0], 0.0, p[0] - r[2] - 0.45)
    dy = max(r[1] - 0.45 - p[1], 0.0, p[1] - r[3] - 0.45)
    dz = max(h0 - p[2], 0.0, p[2] - top)
    return math.sqrt(dx * dx + dy * dy + dz * dz)


def praticables(d):
    out = []
    for a in d["assets"]:
        if a.get("category") != "surface" or "polygon_xy_m" not in a:
            continue
        xs = [q[0] for q in a["polygon_xy_m"]]
        ys = [q[1] for q in a["polygon_xy_m"]]
        h = a.get("height_m", 0.0)
        if max(xs) - min(xs) < 1.0 or max(ys) - min(ys) < 1.0:
            continue
        x = math.floor(min(xs)) + 0.5
        while x < max(xs):
            y = math.floor(min(ys)) + 0.5
            while y < max(ys):
                out.append((a["id"], x, y, h))
                y += 1.0
            x += 1.0
    return out


def recouvrements(vols):
    res = []
    for i in range(len(vols)):
        for j in range(i + 1, len(vols)):
            a, b = vols[i], vols[j]
            ra, rb = a[1], b[1]
            s = max(0, min(ra[2], rb[2]) - max(ra[0], rb[0])) * max(0, min(ra[3], rb[3]) - max(ra[1], rb[1]))
            if s > 0.01 and min(a[3], b[3]) - max(a[2], b[2]) > 0.01:
                res.append((a[0], b[0], s))
    return res


def main():
    d = json.load(open(SRC, encoding="utf-8"))
    vols = volumes(d)
    pts = praticables(d)
    dans, proches, masques = {}, {}, {}
    for sid, x, y, h in pts:
        cam = (x, y + DY, h + DZ)
        for vol in vols:
            if dedans(cam, vol):
                dans.setdefault(vol[0], []).append((sid, x, y))
            elif dist_boite(cam, vol) < PROCHE_PLEIN * 0.25:
                proches.setdefault(vol[0], []).append((sid, x, y))
        # Aren masqué au-delà de la zone tramée : échantillons du segment Aren -> caméra
        a = (x, y, h + 1.0)
        for k in range(1, 40):
            t = k / 40.0
            q = (a[0], a[1] + (cam[1] - a[1]) * t, a[2] + (cam[2] - a[2]) * t)
            dc = (1.0 - t) * math.hypot(DY, DZ - 1.0)
            if dc < PROCHE_PLEIN:
                break
            hit = next((vol[0] for vol in vols if dedans(q, vol)), None)
            if hit:
                masques.setdefault(hit, []).append((sid, x, y))
                break
    print("Points praticables testés : %d (pas de 1 m) — %s" % (len(pts), os.path.basename(SRC)))
    print("\nCAMÉRA DANS UN VOLUME (le volume couvre l'écran) : %d points" % sum(len(v) for v in dans.values()))
    for k, v in sorted(dans.items(), key=lambda kv: -len(kv[1])):
        zones = sorted({s for s, _x, _y in v})
        print("  %-24s %4d points  (%s)" % (k, len(v), ", ".join(zones)))
    print("\nVOLUME À MOINS DE %.1f m DE LA CAMÉRA : %d points" % (PROCHE_PLEIN * 0.25, sum(len(v) for v in proches.values())))
    for k, v in sorted(proches.items(), key=lambda kv: -len(kv[1]))[:12]:
        print("  %-24s %4d points" % (k, len(v)))
    print("\nAREN MASQUÉ (au-delà de la zone tramée ; seul le trou d'occlusion le montre) : %d points sur %d (%.1f %%)"
          % (sum(len(v) for v in masques.values()), len(pts), 100.0 * sum(len(v) for v in masques.values()) / max(1, len(pts))))
    for k, v in sorted(masques.items(), key=lambda kv: -len(kv[1]))[:12]:
        zones = sorted({s for s, _x, _y in v})
        print("  %-24s %4d points  (%s)" % (k, len(v), ", ".join(zones)))
    rec = recouvrements(vols)
    print("\nRECOUVREMENTS DE VOLUMES : %d" % len(rec))
    for a, b, s in rec:
        print("  %-24s x %-24s %.1f m²" % (a, b, s))


if __name__ == "__main__":
    main()
