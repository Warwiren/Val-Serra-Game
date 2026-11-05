"""Mini-test artistique de l'exploration HD-2D : composition d'une vue 640×360 natifs (affichée ×2 au plus proche
voisin -> 1280×720, comme dans Godot) avec fond crépusculaire, sol, maison (Blender + conversion pixel art),
arbre illustré, personnages triés par la position de leurs pieds. Deux échelles comparées :
  A : 27,9 px natifs / m (personnages ≈ 80 px à l'écran)   B : 22,3 px / m (≈ 64 px)
Usage : python3 compose_test.py <scratch_ex> <dossier_art_proto> <sortie_A.png> <sortie_B.png>"""
import math, os, sys
import numpy as np
from PIL import Image

EX, ART, OUT_A, OUT_B = sys.argv[1:5]
sys.argv = [sys.argv[0], os.path.join(EX, "_tmp"), "27.9", "3"]
import importlib.util
spec = importlib.util.spec_from_file_location("pa", os.path.join(os.path.dirname(__file__), "paint_assets.py"))

W, H = 640, 360


def load(p):
    return Image.open(p).convert("RGBA")


def shrink(im, f):
    """Réduction d'un sprite pixel art (couleur médiane par cellule) — test d'échelle uniquement."""
    a = np.asarray(im).astype(np.float32)
    h, w = a.shape[:2]
    nh, nw = max(1, round(h * f)), max(1, round(w * f))
    out = np.zeros((nh, nw, 4), np.uint8)
    for y in range(nh):
        for x in range(nw):
            blk = a[int(y / f):max(int(y / f) + 1, int((y + 1) / f)), int(x / f):max(int(x / f) + 1, int((x + 1) / f))].reshape(-1, 4)
            op = blk[blk[:, 3] > 0]
            if len(op) >= len(blk) * 0.5:
                out[y, x, :3] = np.median(op[:, :3], axis=0); out[y, x, 3] = 255
    return Image.fromarray(out, "RGBA")


def glow(base, cx, cy, rx, ry, col, a):
    yy, xx = np.mgrid[0:H, 0:W]
    d = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2
    k = np.clip(1 - d, 0, 1) ** 2 * a
    k = np.round(k * 6) / 6                                   # paliers (pas de dégradé lisse)
    arr = np.asarray(base).astype(np.float32)
    arr[..., :3] = np.clip(arr[..., :3] + np.array(col)[None, None] * k[..., None], 0, 255)
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def compose(ppm, house, canopy, trunk, chars, out, horizon):
    pa = importlib.util.module_from_spec(spec)
    sys.argv = [sys.argv[0], os.path.join(EX, "_tmp"), str(ppm), "5"]
    spec.loader.exec_module(pa)
    sky, far, near = pa.backdrop(W, H, horizon)
    hx = 430
    hb = max(house.height + 8, int(H * 0.62))             # le toit reste dans le cadre
    door = (hx, hb)
    g0 = horizon - 10
    g, path = pa.ground(W, H - g0, [(250, H - g0), (330, (H - g0) // 2 + 20), (hx, hb - g0 + 4)], 2.0)
    img = Image.fromarray(sky.astype(np.uint8), "RGBA")
    img.alpha_composite(Image.fromarray(g.astype(np.uint8), "RGBA"), (0, g0))
    img.alpha_composite(Image.fromarray(far.astype(np.uint8), "RGBA"))      # lisières de forêt au fond de la clairière
    img.alpha_composite(Image.fromarray(near.astype(np.uint8), "RGBA"))
    # ombre portée de la lisière sur l'herbe (bande dégradée par paliers)
    arr = np.asarray(img).astype(np.float32)
    nb_ = np.asarray(Image.fromarray(near.astype(np.uint8), "RGBA"))[..., 3] > 0
    bottom = np.array([np.max(np.where(nb_[:, x])[0]) if nb_[:, x].any() else 0 for x in range(W)])
    for x in range(W):
        for k in range(1, 14):
            y = bottom[x] + k
            if y < H:
                arr[y, x, :3] *= 1 - 0.45 * (1 - k / 14) ** 1.5 // 0.1 * 0.1 if False else 1 - round(0.45 * (1 - k / 14) * 4) / 4
    img = Image.fromarray(arr.astype(np.uint8), "RGBA")
    img = glow(img, hx + 0.85 * ppm, hb + 6, 3.2 * ppm, 1.4 * ppm, (110, 60, 20), 0.9)     # lanterne
    for fx in (-2.0, 2.0):                                                                    # fenêtres
        img = glow(img, hx + fx * ppm, hb + 0.6 * ppm, 1.4 * ppm, 0.7 * ppm, (80, 44, 16), 0.6)
    items = [(hb, house, (hx - house.width // 2, hb - house.height))]
    tx, tb = int(W * 0.2), int(H * 0.9)
    items.append((tb, trunk, (tx - trunk.width // 2, tb - trunk.height)))
    items.append((tb + 0.5, canopy, (tx - canopy.width // 2, tb - canopy.height)))
    for (im, x, y) in chars:
        items.append((y, im, (x - im.width // 2, y - im.height)))
    # ombres de contact (pieds, tronc, base de la maison) avant les sprites
    arr = np.asarray(img).astype(np.float32)
    yy, xx = np.mgrid[0:H, 0:W]
    shadows = [(hx, hb - 1, house.width * 0.5, 5)] + [(tx, tb - 1, trunk.width * 0.18, 3)]
    shadows += [(x, y - 1, im.width * 0.45, 3) for (im, x, y) in chars]
    for cx_, cy_, rx, ry in shadows:
        m = ((xx - cx_) / max(rx, 1)) ** 2 + ((yy - cy_) / ry) ** 2 < 1
        arr[m, :3] *= 0.62
    img = Image.fromarray(arr.astype(np.uint8), "RGBA")
    for _, im, pos in sorted(items, key=lambda t: t[0]):
        img.alpha_composite(im, pos)
    # premier plan : feuillages sombres en bas de l'écran (profondeur, sans flou)
    fg = np.zeros((H, W, 4), np.uint8)
    rng = np.random.default_rng(9)
    yy, xx = np.mgrid[0:H, 0:W]
    for cx0, cy0, r in [(20, H + 6, 46), (70, H + 18, 40), (W - 30, H + 4, 50), (W - 90, H + 22, 36)]:
        ang = np.arctan2(yy - cy0, xx - cx0)
        rr = r * (1 + 0.12 * np.sin(ang * 9 + cx0))
        m = np.hypot(xx - cx0, (yy - cy0) * 1.2) < rr
        fg[m] = (14, 22, 30, 255)
        rim = m & (np.hypot(xx - cx0, (yy - cy0) * 1.2) > rr - 2) & (yy < cy0 - r * 0.5)
        fg[rim] = (40, 52, 70, 255)
    img.alpha_composite(Image.fromarray(fg, "RGBA"))
    img = img.resize((W * 2, H * 2), Image.NEAREST)
    img.convert("RGB").save(out)
    return door, (tx, tb)


house_a = load(os.path.join(EX, "house_28_px.png")); house_b = load(os.path.join(EX, "house_22_px.png"))
can_a, tr_a = load(os.path.join(EX, "a28", "arbre_feuillage.png")), load(os.path.join(EX, "a28", "arbre_tronc.png"))
can_b, tr_b = load(os.path.join(EX, "a22", "arbre_feuillage.png")), load(os.path.join(EX, "a22", "arbre_tronc.png"))
aren_a = load(os.path.join(ART, "aren2", "idle_face.png")); aren_b = load(os.path.join(EX, "aren32", "idle_face.png"))
ilya, throne, pnj = (load(os.path.join(ART, k + ".png")) for k in ("ilya", "throne", "pnj"))
f = 32 / 40
for ppm, house, can, tr, aren, sc, out, hz in (
        (27.9, house_a, can_a, tr_a, aren_a, 1.0, OUT_A, 70),
        (22.3, house_b, can_b, tr_b, aren_b, f, OUT_B, 80)):
    i_, t_, p_ = (ilya, throne, pnj) if sc == 1 else (shrink(ilya, sc), shrink(throne, sc), shrink(pnj, sc))
    chars = [(aren, 300, 286), (t_, 236, 300), (i_, 136, 300), (p_, 492, 262 if sc == 1 else 252)]
    compose(ppm, house, can, tr, chars, out, hz)
    print(out)
