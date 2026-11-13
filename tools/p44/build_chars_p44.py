#!/usr/bin/env python3
"""P4.4 — construit art/p44/ : Aren (gris), Ilya (verte, pistolet d'Aether), portraits, à partir des packs Drive
P4_3_ANIMATIONS_QA_v01 (exploration), P4_2_COMBAT_PORTRAITS_v01 (combat d'Aren, portraits), P4_4_ILYA_AETHER_COMBAT_v01
(combat d'Ilya, 7 séquences).

  python3 tools/p44/build_chars_p44.py <dossier des packs>
      <dossier>/p43/ValSerra_P43_ANIMATIONS_QA_v01_A_TESTER/{aren_gray_corrige_4dir_5frames.png, ilya/ilya_exploration_4dir_5frames_RGBA.png}
      <dossier>/p44/atlases/ilya_<séquence>_strip_192.png
      <dossier>/p42/aren_combat/<séquence>.png, p42/aren_portraits/*.png, p42/ilya_portraits/*.png, p42/garde_portraits/*.png

Même méthode que P4.1 (pas de flou) : chaque pixel du sprite de jeu = couleur médiane des pixels opaques de la
source qu'il recouvre (réduction, jamais d'agrandissement), palette commune par personnage, pixels isolés retirés.
Les pieds restent au même point d'un canevas fixe pour toutes les images d'un même jeu."""
import json, os, sys
import numpy as np
from PIL import Image

SRC = sys.argv[1]
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
OUT = os.path.join(ROOT, "art", "p44")
P43 = os.path.join(SRC, "p43", "ValSerra_P43_ANIMATIONS_QA_v01_A_TESTER")
ROWS = ["face", "back", "left", "right"]          # ordre des lignes du pack : down, up, left, right
H_AREN_EX, H_ILYA_EX = 56, 52                     # hauteur debout en pixels de jeu (exploration)
H_AREN_CB, H_ILYA_CB = 56, 54                     # combat (affiché ×2)


def reduce(rgba, f):
    """Réduction par couleur médiane : bloc f × f de la source -> 1 pixel (opaque si couvert à 45 %)."""
    H, W = rgba.shape[:2]
    nh, nw = int(np.ceil(H / f)), int(np.ceil(W / f))
    out = np.zeros((nh, nw, 4), np.uint8)
    a = rgba[..., 3] > 110
    for y in range(nh):
        y0, y1 = int(round(y * f)), min(H, int(round((y + 1) * f)))
        for x in range(nw):
            x0, x1 = int(round(x * f)), min(W, int(round((x + 1) * f)))
            m = a[y0:y1, x0:x1]
            if m.size and m.mean() >= 0.45:
                out[y, x, :3] = np.median(rgba[y0:y1, x0:x1, :3][m], axis=0)
                out[y, x, 3] = 255
    return out


def palette(imgs, K, seed=7):
    px = np.concatenate([i[i[..., 3] > 0][:, :3] for i in imgs]).astype(float)
    rng = np.random.default_rng(seed)
    c = px[rng.choice(len(px), min(K, len(px)), replace=False)]
    for _ in range(30):
        lab = ((px[:, None] - c[None]) ** 2).sum(-1).argmin(1)
        for k in range(len(c)):
            s = px[lab == k]
            if len(s):
                c[k] = s.mean(0)
    return c


def quantize(img, pal, edge_k=0.6, edge_min=90):
    out = img.copy()
    m = out[..., 3] > 0
    idx = ((out[m][:, :3].astype(float)[:, None] - pal[None]) ** 2).sum(-1).argmin(1)
    out[m, :3] = pal[idx].astype(np.uint8)
    # pixels isolés (0 ou 1 voisin) retirés ; contour clair assombri (silhouette lisible sur le décor)
    a = out[..., 3] > 0
    n = sum(np.roll(np.roll(a, dy, 0), dx, 1) for dy in (-1, 0, 1) for dx in (-1, 0, 1)) - a
    out[a & (n <= 1)] = 0
    a = out[..., 3] > 0
    edge = a & ~(np.roll(a, 1, 0) & np.roll(a, -1, 0) & np.roll(a, 1, 1) & np.roll(a, -1, 1))
    light = edge & (out[..., :3].astype(float).mean(-1) > edge_min)
    out[light, :3] = (out[light, :3] * edge_k).astype(np.uint8)
    return out


def on_canvas(img, anchor, canvas):
    """Pose `img` pour que son point `anchor` (x, y) tombe au milieu de la dernière rangée du canevas."""
    W, H = canvas
    out = np.zeros((H, W, 4), np.uint8)
    dx, dy = W // 2 - int(round(anchor[0])), H - 1 - int(round(anchor[1]))
    h, w = img.shape[:2]
    ys, xs = np.mgrid[0:h, 0:w]
    tx, ty = xs + dx, ys + dy
    ok = (tx >= 0) & (tx < W) & (ty >= 0) & (ty < H) & (img[..., 3] > 0)
    out[ty[ok], tx[ok]] = img[ok]
    if (img[..., 3] > 0).sum() != ok.sum():
        print("   ! rogné :", (img[..., 3] > 0).sum() - ok.sum(), "px")
    return out


def save(img, *p):
    path = os.path.join(OUT, *p)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    Image.fromarray(img, "RGBA").save(path)


def grid(path, cw, ch):
    im = np.asarray(Image.open(path).convert("RGBA"))
    return [[im[r * ch:(r + 1) * ch, c * cw:(c + 1) * cw] for c in range(im.shape[1] // cw)] for r in range(im.shape[0] // ch)]


def exploration(name, path, cw, ch, foot, target, canvas, edge_k=0.6, edge_min=90):
    """Atlas 5 colonnes (repos, marche 0..3) × 4 lignes (face, dos, gauche, droite), pieds au point `foot` de la cellule."""
    g = grid(path, cw, ch)
    walk_h = np.median([np.ptp(np.where(c[..., 3] > 128)[0]) + 1 for row in g for c in row[1:]])
    f = walk_h / target
    frames = {}
    for r, d in enumerate(ROWS):
        for c in range(5):
            img = reduce(g[r][c], f)
            frames["idle_%s" % d if c == 0 else "walk_%s_%d" % (d, c - 1)] = on_canvas(img, (foot[0] / f, foot[1] / f), canvas)
    pal = palette(list(frames.values()), 96)
    for k, img in frames.items():
        save(quantize(img, pal, edge_k, edge_min), "chars", name, k + ".png")
    # 2e image de repos : haut du corps abaissé d'un pixel (respiration), comme P4.1
    for d in ROWS:
        a = np.asarray(Image.open(os.path.join(OUT, "chars", name, "idle_%s.png" % d))).copy()
        ys = np.where(a[..., 3].any(1))[0]
        w = int(ys.min() + (ys.max() - ys.min()) * 0.55)
        b = a.copy(); top = a[:w].copy(); b[:w] = 0
        b[1:w + 1] = np.where(top[..., 3:4] > 0, top, b[1:w + 1])
        save(b, "chars", name, "idle_%s_1.png" % d)
    print("%s exploration : facteur %.2f, %d images" % (name, f, len(frames) + 4))


def aren_combat():
    seqs = {"idle": "repos", "advance": "avance", "prepare": "preparation", "attack": "attaque", "guard": "garde",
            "hit": "touche", "return": "retour", "aether_charge": "res_charge", "aether_release": "res_liberation"}
    f = 80.0 / H_AREN_CB
    frames = {}
    for src, dst in seqs.items():
        im = np.asarray(Image.open(os.path.join(SRC, "p42", "aren_combat", src + ".png")).convert("RGBA"))
        cw = 118 if src == "aether_release" else 110
        for i in range(im.shape[1] // cw):
            cell = im[:, i * cw:(i + 1) * cw]
            a = cell[..., 3] > 128
            ys, xs = np.where(a)
            if not len(ys):
                continue
            # pieds : milieu des pixels opaques des 8 dernières rangées (mêmes repères que P4.1)
            bottom = ys.max()
            fx = xs[ys >= bottom - 8].mean()
            img = reduce(cell, f)
            # ombre portée peinte sous les pieds (noir bleuté) : retirée des 5 dernières rangées
            ys2 = np.where(img[..., 3].any(1))[0]
            for y in range(ys2.max() - 4, ys2.max() + 1):
                dark = (img[y, :, 3] > 0) & (img[y, :, :3].astype(int).sum(-1) < 75)
                img[y, dark] = 0
            ys2 = np.where(img[..., 3].any(1))[0]
            frames["%s_%d" % (dst, i)] = on_canvas(img, (fx / f, ys2.max()), (132, 90))
    pal = palette(list(frames.values()), 96, 3)
    for k, img in frames.items():
        save(quantize(img, pal), "combat", "aren", k + ".png")
    # « impact » (suivi de frappe) absent du pack P4.2 : fin de l'attaque, sans image inventée
    for i, j in enumerate([3, 4, 5, 5]):
        Image.open(os.path.join(OUT, "combat", "aren", "attaque_%d.png" % j)).save(os.path.join(OUT, "combat", "aren", "impact_%d.png" % i))
    print("Aren combat : facteur %.2f, %d images" % (f, len(frames)))


def ilya_combat():
    man = json.load(open(os.path.join(SRC, "p44", "manifest.json")))
    ax, ay = man["anchor_pixels"]
    f = 143.0 / H_ILYA_CB
    frames = {}
    meta = {}
    for s, d in man["sequences"].items():
        im = np.asarray(Image.open(os.path.join(SRC, "p44", "atlases", "ilya_%s_strip_192.png" % s)).convert("RGBA"))
        for i in range(d["count"]):
            img = reduce(im[:, i * 192:(i + 1) * 192], f)
            frames["%s_%d" % (s, i)] = on_canvas(img, (ax / f, ay / f), (132, 90))
        meta[s] = {"count": d["count"], "fps": d["fps"], "loop": d["loop"]}
    pal = palette(list(frames.values()), 112, 5)
    for k, img in frames.items():
        save(quantize(img, pal), "combat", "ilya", k + ".png")
    json.dump(meta, open(os.path.join(OUT, "combat", "ilya", "sequences.json"), "w"), indent=1)
    print("Ilya combat : facteur %.2f, %d images" % (f, len(frames)))


def portraits():
    for who, names in (("aren", ["neutre", "determine", "souriant", "surpris", "blesse", "concentre"]),
                       ("ilya", ["neutre", "determine", "souriant", "surpris", "inquiete", "resolue"]),
                       ("garde", ["neutre"])):
        for n in names:
            src = os.path.join(SRC, "p42", "%s_portraits" % who, n + ".png")
            if who == "ilya" and n == "neutre":
                src = os.path.join(SRC, "p42", "ilya_portraits", "neutre_large.png")   # seule source nette (219 px)
            im = Image.open(src).convert("RGBA")
            w, h = im.size
            if who == "garde":
                im = im.crop((0, 0, w, int(w * 1.0)))                       # tête et épaules
            # cadre carré, 160 px au plus : réduction seulement (les petites sources gardent leur taille)
            s = min(w, h)
            im = im.crop(((w - s) // 2, 0, (w - s) // 2 + s, s))
            if s > 160:
                im = im.resize((160, 160), Image.LANCZOS)
            os.makedirs(os.path.join(OUT, "portraits", who), exist_ok=True)
            im.save(os.path.join(OUT, "portraits", who, n + ".png"))
    print("portraits : ok")


exploration("aren", os.path.join(P43, "aren_gray_corrige_4dir_5frames.png"), 180, 168, (90, 154), H_AREN_EX, (88, 92))
exploration("ilya", os.path.join(P43, "ilya", "ilya_exploration_4dir_5frames_RGBA.png"), 256, 288, (127, 280), H_ILYA_EX, (88, 92), 0.42, 40)   # contour plus sombre : cape claire sur l'herbe
aren_combat()
ilya_combat()
portraits()
print("art/p44 :", sum(len(fs) for _, _, fs in os.walk(OUT)), "fichiers")
