"""Piles d'accessoires (caisses, barriques) composées à partir des sprites découpés, pour RECOUVRIR entièrement
la place de l'ancien élément : la maison a été découpée là où elle était visible, donc un accessoire plus petit
laisserait un trou dans sa façade. Vérifie la couverture et l'affiche.
    python3 tools/explore/compose_piles.py"""
import json
import numpy as np
from PIL import Image

D = "art/explore_hd2d/"
zone = json.load(open(D + "zone.json"))
caisses = Image.open(D + "hd/caisses.png")
barriques = Image.open(D + "hd/barriques.png")
w, h = caisses.size
petite = caisses.crop((int(w * 0.56), 0, w, h))                 # petite caisse (à droite sur la planche)
pw, ph = petite.size
pb = petite.getbbox(); petite = petite.crop(pb); pw, ph = petite.size


def pile(base, top, top_x, overlap, name):
    H = base.height + top.height - overlap
    out = Image.new("RGBA", (base.width, H))
    out.alpha_composite(top, (top_x, 0))                       # derrière / dessus
    out.alpha_composite(base, (0, H - base.height))
    out.save(D + "hd/%s.png" % name)
    return out


p1 = pile(caisses, petite, int(w * 0.12), int(ph * 0.35), "caisses_pile")
p2 = pile(barriques, petite, int(barriques.width * 0.30), int(ph * 0.55), "barriques_pile")
spec = json.load(open(D + "hd/decor.json"))


def missing(old, im, piv):
    e = zone["sprites"][old]
    om = np.asarray(Image.open(D + "el_%s.png" % old))[..., 3] > 127
    cx = sum(q[0] for q in e["footprint"]) / len(e["footprint"])
    na = np.asarray(im)[..., 3] > 127
    ys, xs = np.nonzero(om)
    tx = ((e["pos"][0] + xs + 0.5 - cx) * 2 + piv[0]).astype(int)
    ty = ((e["pos"][1] + ys + 0.5 - e["sort_y"]) * 2 + piv[1]).astype(int)
    ok = (tx >= 0) & (ty >= 0) & (tx < na.shape[1]) & (ty < na.shape[0])
    hit = np.zeros(len(xs), bool)
    hit[ok] = na[ty[ok], tx[ok]]
    return int((~hit).sum()), int(om.sum())


for old, new, im in (("caisses", "caisses_pile", p1), ("tonneaux", "barriques_pile", p2)):
    best = None
    for dx in range(-12, 13, 2):                                  # léger décalage (pixels d'écran) qui recouvre le mieux
        for dy in range(-8, 9, 2):
            piv = [im.width // 2 + dx, im.height - 2 + dy]
            m, tot = missing(old, im, piv)
            if best is None or m < best[0]:
                best = (m, tot, piv)
    spec["remplace"][old] = {"sprite": new, "pivot": best[2]}
    print("%s -> %s : %d×%d, pivot %s, pixels de l'ancien élément non recouverts : %d / %d" % (old, new, im.width, im.height, best[2], best[0], best[1]))
json.dump(spec, open(D + "hd/decor.json", "w"), indent=1, ensure_ascii=False)
