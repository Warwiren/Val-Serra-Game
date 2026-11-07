#!/usr/bin/env python3
"""P2 lot A — INTÉGRATION des bâtiments validés (habitation, remise) sur leurs gabarits.

Principe (aucune déformation locale de l'illustration, aucune partie reconstituée) :
  1. Les illustrations validées (art/source/batiments_2026-11-07/*_reference.webp, fond transparent, sans sol ni
     accessoire) sont déjà dessinées presque dans la projection du jeu. On les met à l'échelle par un facteur UNIQUE
     (porte à 2,0 m, Aren mesure 1,77 m), avec un très léger cisaillement vertical pour que la pente de la façade
     suive exactement la rotation de 20° du jeu. Les verticales restent verticales, rien n'est étiré localement.
  2. Le gabarit est ADAPTÉ à l'illustration (et non l'inverse), à partir de points relevés sur l'image : arêtes au sol du
     soubassement -> largeur et profondeur (emprise = collision), égouts, faîtage, rives, cheminée, marche, portes et
     fenêtres. Les paramètres sont écrits dans docs/media/gabarits_batiments/adaptation.json, puis
     gabarits_batiments.py régénère gabarit, zones, trait, repères et gabarits.json.
  3. L'illustration est posée dans le cadre exact de la texture du gabarit (même taille, même pivot).
  4. Les vitres éclairées sont séparées dans un calque « _fenetres » (le bâtiment de base a des vitres sombres) :
     la lumière peut être réglée ou animée sans toucher au bâtiment.
Sorties : art/explore_hd2d/batiments/<nom>.png et <nom>_fenetres.png ; docs/media/gabarits_batiments/<nom>/
superposition.png et controle.json (écarts illustration / gabarit).
    python3 tools/explore/batiments_p2.py
"""
import json
import os
import subprocess
import sys
import numpy as np
from collections import deque
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools/explore"))
import gabarits_batiments as G  # noqa: E402

SRC = os.path.join(ROOT, "art/source/batiments_2026-11-07")
OUT = os.path.join(ROOT, "art/explore_hd2d/batiments")
GAB = os.path.join(ROOT, "docs/media/gabarits_batiments")
AX, AY, HZ = G.AX, G.AY, G.HZ
_h = np.asarray(Image.open(os.path.join(ROOT, "art/explore_hd2d/illustre/maison.png")).convert("RGBA")).astype(np.float32)
HOUSE_MEAN = _h[_h[..., 3] > 200][:, :3].mean(0)                # lumière de référence (maison de l'avant-poste)
DOOR_M = 2.0                                     # hauteur des portes (Aren : 1,77 m)

# Points relevés sur les illustrations (px de l'image source). Les points de silhouette sont affinés automatiquement
# (« dir » : direction d'extrémité cherchée dans un rayon de 40 px autour du point estimé).
REF = {
    "habitation": {
        "mur": "enduit", "base_ov": 0.08,
        "sol_FL": ((300, 1146), (0.2, 1)), "sol_FR": ((1131, 1003), (1, 0.6)), "sol_BL": ((104, 853), (-1, 0.4)),
        "base_FL": (300, 1030),
        "egout_FL": (298, 645), "egout_FR": ((1176, 500), (1, 0.15)), "faitage_L": (177, 222),
        "faitage_R": ((1047, 90), (0.4, -1)), "rive_BL": ((46, 360), (-1, 0)),
        "cheminee_dessus": ((330, 48), 148),       # centre du dessus, largeur (px)
        "marche": [(643, 1098), (858, 1063), (640, 1058)],   # avant-bas gauche, avant-bas droite, avant-haut gauche
        "porte": [(673, 820), (797, 1012)],        # rectangle du vantail (px)
        "porte_hauteur_px": 195,
    },
    "remise": {
        "mur": "planches", "base_ov": 0.06,
        "sol_FL": ((395, 1005), (0.2, 1)), "sol_FR": ((1170, 862), (1, 0.6)), "sol_BL": ((184, 735), (-1, 0.4)),
        "base_FL": (395, 940),
        "egout_FL": (350, 672), "egout_FR": ((1245, 525), (1, 0.15)), "faitage_L": (178, 272),
        "faitage_R": ((1100, 95), (0.4, -1)), "rive_BL": ((116, 330), (-1, 0)),
        "cheminee_dessus": None, "marche": None,
        "porte": [(610, 700), (915, 932)],
        "porte_hauteur_px": 230,
    },
}


def load(name):
    a = np.asarray(Image.open(os.path.join(SRC, name + "_reference.webp")).convert("RGBA")).astype(np.float32)
    return a


def refine(alpha, guess, d):
    (gx, gy), (dx, dy) = guess, d
    ys, xs = np.nonzero(alpha[max(0, gy - 40):gy + 41, max(0, gx - 40):gx + 41] > 128)
    xs = xs + max(0, gx - 40); ys = ys + max(0, gy - 40)
    if len(xs) == 0:
        raise ValueError("point %s : aucun pixel de silhouette à proximité" % (guess,))
    k = np.argmax(xs * dx + ys * dy)
    return float(xs[k]), float(ys[k])


def pt(alpha, v):
    return refine(alpha, *v) if isinstance(v[0], tuple) else (float(v[0]), float(v[1]))


def n2(p):
    """Mètres -> px d'écran du jeu (2 × natif), origine arbitraire."""
    return G.native(p) * G.SS


def nelder_mead(f, x0, step, iters=4000):
    n = len(x0)
    pts = [np.array(x0, float)] + [np.array(x0, float) + np.eye(n)[i] * step[i] for i in range(n)]
    vals = [f(p) for p in pts]
    for _ in range(iters):
        o = np.argsort(vals); pts = [pts[i] for i in o]; vals = [vals[i] for i in o]
        c = np.mean(pts[:-1], 0)
        xr = c + (c - pts[-1]); fr = f(xr)
        if fr < vals[0]:
            xe = c + 2 * (c - pts[-1]); fe = f(xe)
            pts[-1], vals[-1] = (xe, fe) if fe < fr else (xr, fr)
        elif fr < vals[-2]:
            pts[-1], vals[-1] = xr, fr
        else:
            xc = c + 0.5 * (pts[-1] - c); fc = f(xc)
            if fc < vals[-1]:
                pts[-1], vals[-1] = xc, fc
            else:
                pts = [pts[0] + 0.5 * (p - pts[0]) for p in pts]; vals = [f(p) for p in pts]
    i = int(np.argmin(vals))
    return pts[i], vals[i]


def fit(name, R, alpha):
    s = DOOR_M * G.SS * HZ / R["porte_hauteur_px"]           # échelle unique (porte à 2,0 m)
    bo = R["base_ov"]
    FL, FR, BL = pt(alpha, R["sol_FL"]), pt(alpha, R["sol_FR"]), pt(alpha, R["sol_BL"])
    # inconnues linéaires : k (cisaillement), a = W/2 + bo, d = D/2 + bo, tx, ty
    rows, rhs = [], []
    for (x, y), (sx, sy) in ((FL, (-1, -1)), (FR, (1, -1)), (BL, (-1, 1))):
        # X : s x + tx = 2 (AX0 sx a + AX1 sy d)
        rows.append([0, -2 * AX[0] * sx, -2 * AX[1] * sy, 1, 0]); rhs.append(-s * x)
        # Y : s y + k s x + ty = 2 (AY0 sx a + AY1 sy d)
        rows.append([s * x, -2 * AY[0] * sx, -2 * AY[1] * sy, 0, 1]); rhs.append(-s * y)
    sol, res, *_ = np.linalg.lstsq(np.array(rows), np.array(rhs), rcond=None)
    k, a, d, tx, ty = sol
    W, D = 2 * (a - bo), 2 * (d - bo)
    M = lambda q: np.array([s * q[0] + tx, s * q[1] + k * s * q[0] + ty])     # source -> 2×natif
    sol_err = [float(np.linalg.norm(M(p) - n2(q))) for p, q in ((FL, (-a, -d, 0)), (FR, (a, -d, 0)), (BL, (-a, d, 0)))]
    base = float((n2((-a, -d, 0))[1] - M(R["base_FL"])[1]) / (G.SS * HZ))
    obs = {key: M(pt(alpha, R[key])) for key in ("egout_FL", "egout_FR", "faitage_L", "faitage_R", "rive_BL")}

    def model(v):
        H1, RH, ovl, ovr, ovf = v
        ze = H1 - ovf * RH / (D / 2) - 0.16
        return {"egout_FL": (-W / 2 - ovl, -(D / 2 + ovf), ze), "egout_FR": (W / 2 + ovr, -(D / 2 + ovf), ze),
                "faitage_L": (-W / 2 - ovl, 0, H1 + RH), "faitage_R": (W / 2 + ovr, 0, H1 + RH),
                "rive_BL": (-W / 2 - ovl, D / 2 + ovf, ze)}

    def cost(v):
        if min(v[2:]) < 0 or v[1] < 0.5 or v[0] < base + 1:
            return 1e9
        m = model(v)
        return sum(float(np.sum((n2(m[q]) - obs[q]) ** 2)) for q in obs)
    v, c = nelder_mead(cost, [base + 4, 2.0, 0.4, 0.4, 0.4], [0.5, 0.4, 0.2, 0.2, 0.2])
    H1, RH, ovl, ovr, ovf = [float(x) for x in v]
    roof_err = {q: round(float(np.linalg.norm(n2(model(v)[q]) - obs[q])), 1) for q in obs}
    p = {"W": round(float(W), 3), "D": round(float(D), 3), "base": round(base, 3), "base_ov": bo, "H1": round(H1, 3),
         "RH": round(RH, 3), "ov_l": round(ovl, 3), "ov_r": round(ovr, 3), "ov_f": round(ovf, 3), "mur": R["mur"]}

    def facade_uz(q):
        """Point de l'image -> (u, z) sur la façade (plan y = -D/2)."""
        X, Y = M(q)
        u = (X / G.SS - AX[1] * (-D / 2)) / AX[0]
        z = (AY[0] * u + AY[1] * (-D / 2) - Y / G.SS) / HZ
        return u, z

    def side_uz(q):
        """Point de l'image -> (v, z) sur le mur gauche (plan x = -W/2)."""
        X, Y = M(q)
        v_ = (X / G.SS - AX[0] * (-W / 2)) / AX[1]
        z = (AY[0] * (-W / 2) + AY[1] * v_ - Y / G.SS) / HZ
        return v_, z
    if R["cheminee_dessus"]:
        (cxr, cyr), wpx = R["cheminee_dessus"]
        X, Y = M((cxr, cyr)); cy = 0.9
        cx = (X / G.SS - AX[1] * cy) / AX[0]
        zt = (AY[0] * cx + AY[1] * cy - Y / G.SS) / HZ
        csz = wpx * s / (G.SS * (AX[0] - AX[1]))
        p["cheminee"] = [round(cx, 3), cy, round(csz, 3), round(zt, 3)]
    if R["marche"]:
        (u0, _), (u1, _) = facade_uz(R["marche"][0]), facade_uz(R["marche"][1])
        # la marche avance devant le soubassement : profondeur et hauteur d'après l'arête avant
        dep = 0.55
        (_, zt) = facade_uz(R["marche"][2])
        p["marche"] = [round(u0, 3), round(u1, 3), dep, round(max(0.15, min(0.35, zt * 0.5)), 3)]
    (du0, dz1), (du1, dz0) = facade_uz(R["porte"][0]), facade_uz(R["porte"][1])
    ops = [["porte", "porte", "avant", round(du0, 3), round(du1, 3), round(max(dz0, base * 0.2), 3), round(dz1, 3)]]
    p["point_porte"] = [round((du0 + du1) / 2, 3), round(-D / 2 - bo - (0.55 if R["marche"] else 0) - 0.45, 3)]
    if name == "remise":
        p["montant"] = [round((du0 + du1) / 2, 3), round(max(dz0, 0.1), 3), round(dz1, 3)]
    return p, M, s, k, sol_err, roof_err, ops, facade_uz, side_uz


# ------------------------------------------------------------------------------------- vitres éclairées
def window_mask(img, eave_y_at, front_x):
    """Vitres éclairées. Noyau : jaune très lumineux (vert presque égal au rouge : l'enduit chaud, plus orangé, en est
    exclu), sous la ligne d'égout (pas la mousse du toit). Les carreaux d'une même fenêtre sont regroupés ; dans le
    rectangle de chaque fenêtre, la lumière suit la luminance chaude."""
    r, g, b, a = img[..., 0], img[..., 1], img[..., 2], img[..., 3]
    h, w = r.shape
    core = (r > 220) & (g > 0.86 * r) & (b < 215) & (a > 200)
    xs_ = np.arange(w)
    limit = np.where(xs_ < front_x - 6, -1, eave_y_at(xs_))        # mur gauche (pignon) : pas de toit devant lui
    core &= np.arange(h)[:, None] > limit[None, :]
    lab = np.zeros(core.shape, np.int32); boxes = []; n = 0
    for y0, x0 in zip(*np.nonzero(core)):
        if lab[y0, x0]:
            continue
        n += 1; q = deque([(y0, x0)]); lab[y0, x0] = n; pts = []
        while q:
            y, x = q.popleft(); pts.append((y, x))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    u, v = y + dy, x + dx
                    if 0 <= u < h and 0 <= v < w and core[u, v] and not lab[u, v]:
                        lab[u, v] = n; q.append((u, v))
        if len(pts) > 25:
            ys, xs = zip(*pts); boxes.append([min(xs), min(ys), max(xs), max(ys)])
    merged = True                                     # carreaux voisins -> une fenêtre
    while merged:
        merged = False
        for i_ in range(len(boxes)):
            for j_ in range(i_ + 1, len(boxes)):
                A, B = boxes[i_], boxes[j_]
                if A[0] - 18 <= B[2] and B[0] - 18 <= A[2] and A[1] - 18 <= B[3] and B[1] - 18 <= A[3]:
                    boxes[i_] = [min(A[0], B[0]), min(A[1], B[1]), max(A[2], B[2]), max(A[3], B[3])]
                    boxes.pop(j_); merged = True; break
            if merged:
                break
    boxes = [bx for bx in boxes if (bx[2] - bx[0]) * (bx[3] - bx[1]) > 500]
    keep = np.zeros(core.shape, bool)
    for x0, y0, x1, y1 in boxes:
        keep[max(0, y0 - 6):y1 + 7, max(0, x0 - 6):x1 + 7] = True
    lum = (r * 0.5 + g * 0.4 + b * 0.1)
    glow = np.clip((lum - 140) / 80.0, 0, 1) * np.clip((g / np.maximum(r, 1) - 0.62) / 0.2, 0, 1) * keep
    glow = np.asarray(Image.fromarray((glow * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.0))).astype(np.float32) / 255
    return glow * (a / 255.0), [tuple(bx) for bx in boxes]


def resample(img, s, k, tx, ty, mn, size):
    """Image source -> texture du gabarit : échelle unique (Lanczos, prémultiplié) puis cisaillement vertical léger."""
    pm = img.copy(); pm[..., :3] *= pm[..., 3:4] / 255.0
    w, h = img.shape[1], img.shape[0]
    nw, nh = int(round(w * s)), int(round(h * s))
    small = np.dstack([np.asarray(Image.fromarray(pm[..., c], "F").resize((nw, nh), Image.LANCZOS)) for c in range(4)])
    sx, sy = nw / w, nh / h
    # texture (X, Y) -> petite image : x_s = (X + mn_x - tx) * sx / s ; y_s = (Y + mn_y - ty - k s x_src) * sy / s
    a_ = sx / s
    # y_s = sy/s * (Y + mn_y - ty) - k*sy*x_src  avec x_src = (X + mn_x - tx)/s
    coeffs = (a_, 0, (mn[0] - tx) * a_,
              -k * sy / s, sy / s, (mn[1] - ty) * sy / s - k * sy * (mn[0] - tx) / s)
    out = np.dstack([np.asarray(Image.fromarray(small[..., c].astype(np.float32), "F").transform(
        size, Image.AFFINE, coeffs, resample=Image.BICUBIC)) for c in range(4)])
    out[..., 3] = np.clip(out[..., 3], 0, 255)
    rgb = np.where(out[..., 3:4] > 0.5, out[..., :3] * 255.0 / np.maximum(out[..., 3:4], 1e-3), 0)
    return np.dstack([np.clip(rgb, 0, 255), out[..., 3]])


def main():
    os.makedirs(OUT, exist_ok=True)
    adapt = {"_doc": "Paramètres des gabarits ADAPTÉS aux illustrations validées (mètres). Écrit par "
                     "tools/explore/batiments_p2.py, lu par gabarits_batiments.py.", "batiments": {}}
    fits = {}
    for name, R in REF.items():
        img = load(name)
        p, M, s, k, sol_err, roof_err, ops, fuz, suz = fit(name, R, img[..., 3])
        fits[name] = (img, M, s, k, sol_err, roof_err, ops, fuz, suz, p)
        adapt["batiments"][name] = p
    # ouvertures (fenêtres) d'après les vitres éclairées
    for name, (img, M, s, k, sol_err, roof_err, ops, fuz, suz, p) in fits.items():
        R = REF[name]
        e1, e2 = pt(img[..., 3], R["egout_FL"]), pt(img[..., 3], R["egout_FR"])
        eave = lambda x, e1=e1, e2=e2: e1[1] + (x - e1[0]) * (e2[1] - e1[1]) / (e2[0] - e1[0]) - 6
        front_x = pt(img[..., 3], R["sol_FL"])[0]
        glow, boxes = window_mask(img, eave, front_x)
        for i, (x0, y0, x1, y1) in enumerate(sorted(boxes)):
            cx = (x0 + x1) / 2
            if cx < front_x - 6:
                (v0, z1), (v1, z0) = suz((x0, y0)), suz((x1, y1))
                ops.append(["fenetre_%d" % i, "fenetre", "gauche", round(min(v0, v1), 3), round(max(v0, v1), 3), round(z0, 3), round(z1, 3)])
            else:
                (u0, z1), (u1, z0) = fuz((x0, y0)), fuz((x1, y1))
                ops.append(["fenetre_%d" % i, "fenetre", "avant", round(u0, 3), round(u1, 3), round(z0, 3), round(z1, 3)])
        p["ouvertures"] = ops
        fits[name] = (img, M, s, k, sol_err, roof_err, ops, fuz, suz, p, glow)
    json.dump(adapt, open(os.path.join(GAB, "adaptation.json"), "w"), ensure_ascii=False, indent=1)
    subprocess.run([sys.executable, os.path.join(ROOT, "tools/explore/gabarits_batiments.py")], check=True)
    meta = json.load(open(os.path.join(GAB, "gabarits.json")))
    for name, (img, M, s, k, sol_err, roof_err, ops, fuz, suz, p, glow) in fits.items():
        b = G.from_params(name, p)
        r = G.render(b)
        size = r["size"]
        mn = r["mn"]
        tx = M((0, 0))[0]; ty = M((0, 0))[1]
        art = resample(img, s, k, tx, ty, mn, size)
        g4 = np.dstack([img[..., :3], glow * 255])
        gl = resample(g4, s, k, tx, ty, mn, size)[..., 3] / 255.0
        gl = np.minimum(gl, art[..., 3] / 255.0)
        # base : vitres sombres (nuit, intérieur éteint) ; calque fenêtres : la lumière d'origine
        dark = art[..., :3] * np.array([0.22, 0.2, 0.3], np.float32) + np.array([14, 12, 22], np.float32)
        base_rgb = art[..., :3] * (1 - gl[..., None]) + dark * gl[..., None]
        # étalonnage crépusculaire (calque de base seulement, les vitres restent chaudes) : ton moyen ramené à mi-chemin
        # vers celui de la maison validée de l'avant-poste, qui sert de référence de lumière de la carte
        op = art[..., 3] > 200
        gain = 0.5 + 0.5 * (HOUSE_MEAN / np.maximum(base_rgb[op].mean(0), 1))
        base_rgb = np.clip(base_rgb * gain, 0, 255)
        base = np.dstack([base_rgb, art[..., 3]]).astype(np.uint8)
        la = gl * art[..., 3]
        light = np.dstack([np.where(la[..., None] >= 1, art[..., :3], 0), la]).astype(np.uint8)
        Image.fromarray(base, "RGBA").save(os.path.join(OUT, name + ".png"))
        Image.fromarray(light, "RGBA").save(os.path.join(OUT, name + "_fenetres.png"))
        # contrôles : silhouette illustration / gabarit, superposition
        gab = np.asarray(Image.open(os.path.join(GAB, name, "gabarit.png")))
        A_art, A_gab = art[..., 3] > 128, gab[..., 3] > 128
        iou = float((A_art & A_gab).sum() / max(1, (A_art | A_gab).sum()))
        sup = Image.new("RGBA", size, (34, 40, 34, 255))
        lit = Image.fromarray(base, "RGBA"); lit.alpha_composite(Image.fromarray(light, "RGBA"))
        sup.alpha_composite(lit)
        tr = np.asarray(Image.open(os.path.join(GAB, name, "trait.png"))).copy()
        tr[..., :3] = (0, 255, 255)
        sup.alpha_composite(Image.fromarray(tr, "RGBA"))
        d = ImageDraw.Draw(sup)
        m = meta["batiments"][name]
        piv = np.array(m["pivot_texture_px"])
        fp = [tuple(piv + np.array(q) * 2) for q in m["emprise_natif_relative_au_pied"]]
        d.line(fp + [fp[0]], fill=(255, 70, 70, 255), width=2)
        dp = piv + np.array(m["point_interaction_porte_natif"]) * 2
        d.ellipse([dp[0] - 5, dp[1] - 3, dp[0] + 5, dp[1] + 3], outline=(255, 220, 60, 255), width=2)
        sup.save(os.path.join(GAB, name, "superposition.png"))
        ctl = {"echelle_source_vers_ecran": round(s, 4), "cisaillement_vertical": round(float(k), 4),
               "ecart_aretes_au_sol_px_ecran": [round(e, 1) for e in sol_err],
               "ecart_toiture_px_ecran": roof_err, "recouvrement_silhouettes_iou": round(iou, 3),
               "parametres": p}
        json.dump(ctl, open(os.path.join(GAB, name, "controle.json"), "w"), ensure_ascii=False, indent=1)
        print("%-10s s=%.4f k=%+.4f W=%.2f D=%.2f base=%.2f murs=%.2f faitage=%.2f IoU=%.3f sol=%s toit=%s fenetres=%d" % (
            name, s, k, p["W"], p["D"], p["base"], p["H1"], p["H1"] + p["RH"], iou, ctl["ecart_aretes_au_sol_px_ecran"],
            roof_err, sum(1 for o in ops if o[1] == "fenetre")))


if __name__ == "__main__":
    main()
