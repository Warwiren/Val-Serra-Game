"""Assemble le kit de GABARITS de l'exploration à partir des rendus de gabarits_blender.py et des données du jeu.
    python3 tools/explore/gabarits_reperes.py <dossier_rendus> [docs/media/gabarits_exploration]
Tout est à l'échelle de l'écran (1408×800 = ×2 du natif 704×400 du jeu) et recalé sur le même cadre.
Écrit aussi gabarits.json (projection, emprises, ancrages, rectangles de découpe)."""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

RAW = sys.argv[1]
OUT = sys.argv[2] if len(sys.argv) > 2 else "docs/media/gabarits_exploration"
D = "art/explore_hd2d/"
K = 2                                                      # natif -> écran
W, H = 1408, 800
z = json.load(open(D + "zone.json"))
for sub in ("terrain", "maison", "arbre"):
    os.makedirs(os.path.join(OUT, sub), exist_ok=True)
try:
    FONT = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
    FONT_B = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 16)
except OSError:
    FONT = FONT_B = None

# Projection : sol (x, y en mètres, repère de la scène Blender) -> pixels natifs. Caméra orthographique : affine.
WORLD = [(-15.5, -8.3), (15.5, -8.3), (15.5, 10.5), (-15.5, 10.5)]   # coins du praticable (scene_blender.py)
A = np.array([[x, y, 1] for x, y in WORLD]); B = np.array(z["walkable"])
M = np.linalg.lstsq(A, B, rcond=None)[0]                   # (3, 2)


def ground(x, y):
    return (np.array([x, y, 1.0]) @ M) * K


def S(p):                                                  # point natif -> écran
    return (p[0] * K, p[1] * K)


def text(d, xy, s, col, bold=False):
    d.text(xy, s, fill=col, font=FONT_B if bold else FONT, stroke_width=2, stroke_fill=(0, 0, 0, 255))


def load(n):
    return Image.open(os.path.join(RAW, n)).convert("RGBA")


# ------------------------------------------------------------------------------------------------ terrain
nu = load("terrain_sans_objets.png"); omb = load("terrain_ombres_objets.png")
nu.save(os.path.join(OUT, "terrain", "terrain_gabarit_1408x800.png"))
omb.save(os.path.join(OUT, "terrain", "terrain_avec_ombres_1408x800.png"))


def shadow_mask(with_s, base):
    a = np.asarray(with_s.convert("RGB")).astype(np.float32).mean(-1) + 1
    b = np.asarray(base.convert("RGB")).astype(np.float32).mean(-1) + 1
    s = np.clip(1 - a / b, 0, 1)
    s[s < 0.06] = 0
    return Image.fromarray(np.dstack([np.zeros_like(s), np.zeros_like(s), np.full_like(s, 30), s * 255]).astype(np.uint8), "RGBA")


shadow_mask(omb, nu).save(os.path.join(OUT, "terrain", "ombres_des_objets_calque.png"))
Image.open(D + "fond.png").convert("RGBA").resize((W, H), Image.NEAREST).save(os.path.join(OUT, "terrain", "terrain_actuel_en_jeu_x2.png"))
if os.path.exists(os.path.join(RAW, "profondeur_terrain.png")):
    tv = np.asarray(Image.open(os.path.join(RAW, "profondeur_terrain.png")).convert("L")).astype(np.float32)
    lo, hi = np.percentile(tv, 1), np.percentile(tv, 99)
    Image.fromarray((255 * np.clip((tv - lo) / max(1, hi - lo), 0, 1)).astype(np.uint8)).save(os.path.join(OUT, "terrain", "profondeur_terrain_1408x800.png"))

# grille au sol : 1 m (fine), 5 m (épaisse) — matérialise la perspective 35°/20°
grid = Image.new("RGBA", (W, H)); g = ImageDraw.Draw(grid)
for v in range(-20, 21):
    col = (255, 255, 255, 150) if v % 5 == 0 else (255, 255, 255, 55)
    wdt = 2 if v % 5 == 0 else 1
    g.line([tuple(ground(v, -14)), tuple(ground(v, 16))], fill=col, width=wdt)
for v in range(-14, 17):
    col = (255, 255, 255, 150) if v % 5 == 0 else (255, 255, 255, 55)
    wdt = 2 if v % 5 == 0 else 1
    g.line([tuple(ground(-20, v)), tuple(ground(20, v))], fill=col, width=wdt)
o = ground(0, 0); ex = ground(3, 0); ey = ground(0, 3)
g.line([tuple(o), tuple(ex)], fill=(255, 80, 80, 255), width=3); g.line([tuple(o), tuple(ey)], fill=(80, 255, 80, 255), width=3)
text(g, tuple(ex + [4, -8]), "x (3 m)", (255, 120, 120, 255)); text(g, tuple(ey + [4, -16]), "y, profondeur (3 m)", (120, 255, 120, 255))
grid.save(os.path.join(OUT, "terrain", "grille_sol_1m.png"))

# repères : praticable, obstacles, objets, points de départ, lanternes, zones à garder dégagées
rep = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(rep)
d.polygon([S(p) for p in z["walkable"]], outline=(255, 230, 0, 255), width=3)
text(d, (S(z["walkable"][0])[0] + 20, S(z["walkable"][0])[1] - 30), "limite praticable", (255, 230, 0, 255), True)
for name, e in z["sprites"].items():
    fp = e["footprint"]
    if len(fp) >= 3:
        col = (255, 60, 60, 255) if e["solid"] else (60, 220, 255, 255)
        d.polygon([S(p) for p in fp], outline=col, width=2)
        cx = sum(p[0] for p in fp) / len(fp)
        d.line([S((cx - 6, e["sort_y"])), S((cx + 6, e["sort_y"]))], fill=(255, 0, 255, 255), width=2)
        text(d, S((cx - 8, e["sort_y"] + 2)), name, col)
for k, col in (("heros", (120, 255, 120, 255)), ("pnj", (255, 200, 80, 255)), ("monstre", (220, 120, 255, 255))):
    x, y = S(z["spawn"][k])
    d.ellipse([x - 6, y - 4, x + 6, y + 4], fill=col)
    text(d, (x + 8, y - 8), {"heros": "départ du groupe", "pnj": "garde", "monstre": "Vorgane"}[k], col, True)
for k, r in (("pnj", (44, 32)), ("monstre", (90, 40))):             # dégagements à respecter
    x, y = S(z["spawn"][k])
    d.ellipse([x - r[0], y - r[1], x + r[0], y + r[1]], outline=(255, 255, 255, 200), width=2)
for p in z["lights"]:
    x, y = S(p)
    d.ellipse([x - 9, y - 9 - 28, x + 9, y + 9 - 28], outline=(255, 160, 60, 255), width=3)
    text(d, (x + 12, y - 44), "lanterne", (255, 180, 90, 255))
rep.save(os.path.join(OUT, "terrain", "reperes_terrain.png"))
tmp = nu.copy(); tmp.alpha_composite(grid); tmp.alpha_composite(rep)
tmp.convert("RGB").save(os.path.join(OUT, "terrain", "terrain_gabarit_avec_reperes.jpg"), quality=90)


# ------------------------------------------------------------------------------------------------ maison et arbre
def element(name, key, crop_margin=24):
    full = load({"maison": "maison_seule.png", "arbre": "arbre_seul.png"}[key]); zones = load("%s_zones.png" % key)
    full.save(os.path.join(OUT, key, "%s_complete_cadre_1408x800.png" % key))
    a = np.asarray(full)[..., 3] > 16
    ys, xs = np.nonzero(a)
    box = [max(0, xs.min() - crop_margin), max(0, ys.min() - crop_margin), min(W, xs.max() + 1 + crop_margin), min(H, ys.max() + 1 + crop_margin)]
    full.crop(box).save(os.path.join(OUT, key, "%s_gabarit.png" % key))
    zones.crop(box).save(os.path.join(OUT, key, "%s_zones.png" % key))
    from PIL import ImageFilter
    if os.path.exists(os.path.join(RAW, "profondeur_%s.png" % key)):
        dep = Image.open(os.path.join(RAW, "profondeur_%s.png" % key)).convert("RGBA").crop(box)
        dv = np.asarray(dep.convert("L")).astype(np.float32); dm = np.asarray(dep)[..., 3] > 16
        lo, hi = np.percentile(dv[dm], 1), np.percentile(dv[dm], 99)          # contraste étalé sur l'objet
        dn = np.where(dm, 40 + 215 * np.clip((dv - lo) / max(1, hi - lo), 0, 1), 0)
        Image.fromarray(dn.astype(np.uint8)).save(os.path.join(OUT, key, "%s_profondeur.png" % key))
    zc = zones.crop(box)                                    # trait : contours des zones de matière + silhouette
    zl = np.asarray(zc.convert("RGB").filter(ImageFilter.FIND_EDGES).convert("L")) > 30
    al = np.asarray(zc)[..., 3] > 16
    sil = al & ~np.asarray(Image.fromarray((al * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(3))).astype(bool)
    Image.fromarray(np.where(zl | sil, 0, 255).astype(np.uint8)).save(os.path.join(OUT, key, "%s_trait.png" % key))
    shadow_mask(load("terrain_ombre_%s.png" % key), nu).save(os.path.join(OUT, key, "ombre_au_sol_cadre_1408x800.png"))
    e = z["sprites"][name]
    cur = Image.new("RGBA", (W, H))
    sp = Image.open(D + "el_%s.png" % name).convert("RGBA")
    cur.alpha_composite(sp.resize((sp.width * K, sp.height * K), Image.NEAREST), (e["pos"][0] * K, e["pos"][1] * K))
    cur.crop(box).save(os.path.join(OUT, key, "%s_actuel_en_jeu.png" % key))
    rp = Image.new("RGBA", (box[2] - box[0], box[3] - box[1])); dd = ImageDraw.Draw(rp)
    loc = lambda p: (p[0] * K - box[0], p[1] * K - box[1])
    dd.polygon([loc(p) for p in e["footprint"]], outline=(255, 60, 60, 255), width=3)
    xs_ = [p[0] for p in e["footprint"]]
    dd.line([loc((min(xs_) - 4, e["sort_y"])), loc((max(xs_) + 4, e["sort_y"]))], fill=(255, 0, 255, 255), width=2)
    text(dd, loc((min(xs_), e["sort_y"] + 1)), "ligne de tri (y = %.1f natif)" % e["sort_y"], (255, 120, 255, 255))
    text(dd, (8, 6), "emprise au sol = collision (rouge)", (255, 120, 120, 255), True)
    return box, rp, zones.crop(box), full.crop(box)


meta = {"cadre_ecran": [W, H], "natif": z["native"], "echelle_natif_vers_ecran": K, "pixels_par_metre_natif": z["ppm"],
        "projection_sol_vers_natif": {"x": list(np.round(M[:, 0], 5)), "y": list(np.round(M[:, 1], 5)),
                                      "note": "natif = [x_m, y_m, 1] · colonnes ; caméra orthographique : la projection du sol est affine"},
        "hauteur_1m_natif": round(z["ppm"] * np.cos(np.radians(35)), 2), "elements": {}}
def srgb(h):                                               # couleurs d'émission (linéaires) -> couleurs de l'image
    out = []
    for i in (1, 3, 5):
        c = int(h[i:i + 2], 16) / 255.0
        c = 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055
        out.append(int(round(c * 255)))
    return tuple(out)


LEG = {k: srgb(v) for k, v in json.load(open(os.path.join(RAW, "legende_zones.json"))).items()}
json.dump({k: "#%02X%02X%02X" % c for k, c in LEG.items()}, open(os.path.join(OUT, "legende_zones.json"), "w"), indent=1)
for name, key in (("maison", "maison"), ("arbre_g", "arbre")):
    box, rp, zones, full = element(name, key)
    za = np.asarray(zones).astype(int)
    if key == "maison":
        # porte et fenêtres repérées sur la carte des zones (bois de la porte, vitres)
        from PIL import ImageFilter
        for zone_name, label, col, keep in (("vitre", "fenêtre", (255, 255, 0, 255), 3), ("bois", "porte", (255, 150, 40, 255), 1)):
            c = LEG[zone_name]
            m = (np.abs(za[..., :3] - c).sum(-1) < 40) & (za[..., 3] > 100)
            m = np.asarray(Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(7))) > 0   # réunit les carreaux
            lab = np.zeros(m.shape, int); n = 0
            from collections import deque
            dd = ImageDraw.Draw(rp)
            for yy, xx in zip(*np.nonzero(m)):
                if lab[yy, xx]:
                    continue
                n += 1; q = deque([(yy, xx)]); lab[yy, xx] = n; pts = []
                while q:
                    a_, b_ = q.popleft(); pts.append((a_, b_))
                    for da, db in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        u, v = a_ + da, b_ + db
                        if 0 <= u < m.shape[0] and 0 <= v < m.shape[1] and m[u, v] and not lab[u, v]:
                            lab[u, v] = n; q.append((u, v))
                if len(pts) > 30:
                    comps = locals().setdefault("comps", [])
                    comps.append((len(pts), pts))
            comps = sorted(locals().get("comps", []), key=lambda t: -t[0])[:keep]
            for _, pts in comps:
                py, px = zip(*pts)
                dd.rectangle([min(px) + 1, min(py) + 1, max(px) - 1, max(py) - 1], outline=col, width=2)
                text(dd, (max(px) + 4, min(py)), label, col, True)
                meta.setdefault("ouvertures_maison_ecran", []).append({"type": label, "rectangle_dans_gabarit": [int(min(px)) + 3, int(min(py)) + 3, int(max(px)) - 3, int(max(py)) - 3]})
            comps = []
        pass
    else:
        trunk = (np.abs(za[..., :3] - np.array(LEG["ecorce"])).sum(-1) < 50) & (za[..., 3] > 100)
        leaves = (np.abs(za[..., :3] - np.array(LEG["feuilles"])).sum(-1) < 60) & (za[..., 3] > 100)
        for mm, nm in ((trunk, "tronc"), (leaves, "feuillage")):
            Image.fromarray(np.where(mm, 255, 0).astype(np.uint8)).save(os.path.join(OUT, "arbre", "masque_%s.png" % nm))
        ys, xs = np.nonzero(trunk)
        base = (int(np.median(xs[ys > ys.max() - 6])), int(ys.max()))
        dd = ImageDraw.Draw(rp)
        dd.ellipse([base[0] - 6, base[1] - 4, base[0] + 6, base[1] + 4], fill=(120, 255, 120, 255))
        text(dd, (base[0] + 10, base[1] - 10), "pied du tronc", (120, 255, 120, 255), True)
    rp.save(os.path.join(OUT, key, "%s_reperes.png" % key))
    prev = full.copy(); prev.alpha_composite(rp)
    bg = Image.new("RGBA", prev.size, (40, 44, 58, 255)); bg.alpha_composite(prev)
    bg.convert("RGB").save(os.path.join(OUT, key, "%s_gabarit_avec_reperes.jpg" % key), quality=92)
    e = z["sprites"][name]
    meta["elements"][key] = {"rectangle_ecran": box, "taille": [box[2] - box[0], box[3] - box[1]],
                             "emprise_natif": e["footprint"], "ligne_de_tri_natif": e["sort_y"], "solide": e["solid"],
                             "sprite_actuel": {"fichier": "art/explore_hd2d/el_%s.png" % name, "pos_natif": e["pos"]}}

# ------------------------------------------------------------------------------------------------ aperçu sans personnages
comp = Image.open(D + "fond.png").convert("RGBA").resize((W, H), Image.NEAREST)
layers = []
spec = json.load(open(D + "hd/decor.json")); index = json.load(open(D + "hd/index.json"))
for name, e in z["sprites"].items():
    r = spec["remplace"].get(name)
    if r:
        if r.get("sol") == "avant_gauche":
            foot = max(e["footprint"], key=lambda p: p[1])
        else:
            foot = (sum(p[0] for p in e["footprint"]) / len(e["footprint"]), e["sort_y"])
        im = Image.open(D + "hd/%s.png" % r["sprite"]).convert("RGBA")
        pos = (round(foot[0] * K - r["pivot"][0]), round(foot[1] * K - r["pivot"][1]))
    else:
        sp = Image.open(D + "el_%s.png" % name).convert("RGBA")
        im = sp.resize((sp.width * K, sp.height * K), Image.NEAREST); pos = (e["pos"][0] * K, e["pos"][1] * K)
    layers.append((int(e["sort_y"]), im, pos))
for nm, x, y in spec["sol"]:
    im = Image.open(D + "hd/%s.png" % nm).convert("RGBA"); a = index[nm]["appui"]
    layers.append((int(y), im, (round(x * K - a[0]), round(y * K - a[1]))))
for _, im, pos in sorted(layers, key=lambda t: t[0]):
    tmp = Image.new("RGBA", (W, H)); tmp.alpha_composite(im, (max(0, pos[0]), max(0, pos[1])), (max(0, -pos[0]), max(0, -pos[1])))
    comp.alpha_composite(tmp)
comp.convert("RGB").save(os.path.join(OUT, "apercu_composition_actuelle_sans_personnages.png"))
json.dump(meta, open(os.path.join(OUT, "gabarits.json"), "w"), indent=1, ensure_ascii=False, default=lambda v: v.item() if hasattr(v, "item") else str(v))
print("kit :", OUT)
