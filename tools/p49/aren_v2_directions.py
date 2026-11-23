"""Val'Serra — Aren « Animations de déplacement (V2) » : marche de face, marche de dos et attente de face, préparées pour
le banc d'essai (même design que le profil droit V09B.5), SANS REDESSIN.

Usage :
    python3 tools/p49/aren_v2_directions.py <planche Aren V2 (grille 8 colonnes × 5 rangées, fond blanc)>

Rangées de la planche : 0 marche vers le bas (face), 1 marche vers le haut (dos), 2 profil droit, 3 profil gauche,
4 attente (face). Seules les rangées 0, 1 et 4 sont reprises : le profil droit reste V09B.5 (validé) et la gauche
reste son miroir (même dessin exactement).

Traitement (technique uniquement) :
  1. détourage : pixels « fond » = quasi blancs et peu saturés ; chaque pose = la grande composante non-fond de sa
     case ; les petits trous intérieurs (< 60 px source : blancs des yeux, reflets) sont gardés opaques, les grands
     (entre les jambes, sous la cape) restent transparents ; bord érodé d'1 px source contre la frange blanche ;
  2. échelle : chaque RANGÉE (pas chaque image) est ramenée à la hauteur médiane de la marche V09B.5 (89 px dans le
     canevas 96 × 112) : en jeu, ×0,719 → 64 px comme le profil droit ; l'attente, dessinée ≈ 9 % plus grande sur la
     planche, est ramenée à la même taille ;
  3. réduction par moyenne de surface (alpha prémultiplié), alpha seuillé à 50 %, palette de 64 couleurs de la
     planche, sans tramage ;
  4. placement : pieds (bas de la pose) sur la rangée 100 (ligne de sol 101, comme V09B.5), centre de la tête de
     chaque image sur la médiane de sa rangée (cycle sur place ; le balancement du corps sous la tête est conservé).

Sortie : art/tests/aren_v2/{walk_face,walk_back,idle_face}_{0..7}.png + cadence_aren_v2.json (mesures, SHA-256).
"""
import hashlib, json, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DST = os.path.join(REPO, "art/tests/aren_v2")
RANGEES = {0: "walk_face", 1: "walk_back", 4: "idle_face"}
CANEVAS = (96, 112)
SOL = 101                 # bord inférieur des semelles (V09B.5 96 × 112)
HAUTEUR = 89              # hauteur médiane de la marche V09B.5 dans le canevas
TETE_X = 48               # axe de la tête dans le canevas


def poses(path):
    a = np.asarray(Image.open(path).convert("RGB")).astype(np.int32)
    H, W, _ = a.shape
    mn, mx = a.min(-1), a.max(-1)
    fond = (mn > 215) & (mx - mn < 25)
    zone = np.zeros((H, W), bool)
    zone[90:, 137:] = True
    fg = (~fond) & zone
    grille = [y for y in range(90, H) if fg[y, 140:W - 4].mean() > 0.9]
    fg[grille, :] = False
    # fond élargi : zones claires et peu saturées (fond + ombre portée gris très clair sous les pieds) RELIÉES au grand
    # fond de la case ; les petites zones claires isolées (reflets, blancs des yeux) restent dans le personnage
    clair = (mn > 165) & (mx - mn < 40) & zone
    clair[grille, :] = False
    cl, cn = ndi.label(clair)
    cs = ndi.sum(clair, cl, range(1, cn + 1))
    grands = np.isin(cl, [i + 1 for i, v in enumerate(cs) if v > 2000])
    fg &= ~grands
    lab, n = ndi.label(fg)
    sl = ndi.find_objects(lab)
    sizes = ndi.sum(fg, lab, range(1, n + 1))
    comps = [(i + 1, sl[i]) for i, s in enumerate(sizes) if s > 3000]
    comps.sort(key=lambda c: (c[1][0].start // 150, c[1][1].start))
    assert len(comps) == 40, len(comps)
    out = {}
    for k, (li, (ys, xs)) in enumerate(comps):
        r, c = divmod(k, 8)
        if r not in RANGEES:
            continue
        m = lab == li
        trous = ndi.binary_fill_holes(m) & ~m
        tl, tn = ndi.label(trous)
        if tn:
            ts = ndi.sum(trous, tl, range(1, tn + 1))
            for j, s in enumerate(ts):
                if s < 60:
                    m |= tl == j + 1
        m = ndi.binary_erosion(m, iterations=1)
        y0, y1, x0, x1 = ys.start - 2, ys.stop + 2, xs.start - 2, xs.stop + 2
        rgba = np.zeros((y1 - y0, x1 - x0, 4), np.float64)
        rgba[..., :3] = a[y0:y1, x0:x1] / 255.0
        rgba[..., 3] = m[y0:y1, x0:x1]
        out.setdefault(RANGEES[r], []).append(rgba)
    return out, a


def palette(a, masks, n=64):
    px = np.concatenate([(m[..., :3][m[..., 3] > 0] * 255).astype(np.uint8) for m in masks])
    side = int(np.ceil(np.sqrt(len(px))))
    buf = np.zeros((side * side, 3), np.uint8)
    buf[:len(px)] = px
    buf[len(px):] = px[0]
    return Image.fromarray(buf.reshape(side, side, 3), "RGB").quantize(n, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)


def tete_x(m):
    ys, _ = np.where(m)
    top, bot = ys.min(), ys.max()
    _, xx = np.where(m[top:top + int(0.25 * (bot - top))])
    return float(np.median(xx))


def main():
    planche = sys.argv[1]
    sets, a = poses(planche)
    allm = [m for v in sets.values() for m in v]
    pal = palette(a, allm)
    os.makedirs(DST, exist_ok=True)
    res = {"statut": "Aren V2 (face, dos, attente) — BANC D'ESSAI NON VALIDÉ ; préparé sans redessin depuis la planche « Aren – Animations de déplacement (V2) » (WebP avec perte)",
           "pixel_m": 0.02, "ligne_sol_px": SOL, "cycles": {}, "sha256": {}}
    W, H = CANEVAS
    for name, frames in sets.items():
        hs = [int(np.where(f[..., 3].any(1))[0].max() - np.where(f[..., 3].any(1))[0].min() + 1) for f in frames]
        s = HAUTEUR / float(np.median(hs))
        tx = [tete_x(f[..., 3] > 0) for f in frames]
        tmed = float(np.median(tx))
        sorties = []
        for f, t in zip(frames, tx):
            M = 300                                    # marge transparente autour de la pose découpée
            pm = np.zeros((f.shape[0] + 2 * M, f.shape[1] + 2 * M, 4))
            pm[M:M + f.shape[0], M:M + f.shape[1]] = f
            pm[..., :3] *= pm[..., 3:4]
            src = Image.fromarray((pm * 255).round().astype(np.uint8), "RGBA")
            bot = np.where(f[..., 3].any(1))[0].max() + 1 + M
            # repère : centre de la tête de la RANGÉE (tmed, balancement conservé) -> TETE_X ; semelles -> SOL
            x0 = tmed + M - TETE_X / s
            y0 = bot - SOL / s
            r = np.asarray(src.resize((W, H), Image.BOX, box=(x0, y0, x0 + W / s, y0 + H / s))).astype(np.float64) / 255
            al = r[..., 3:4]
            rgb = np.where(al > 0.001, r[..., :3] / np.maximum(al, 1e-6), 0)
            o = np.zeros((H, W, 4), np.uint8)
            o[..., :3] = (np.clip(rgb, 0, 1) * 255).round().astype(np.uint8)
            o[..., 3] = np.where(al[..., 0] >= 0.5, 255, 0)
            # frange : pixel quasi blanc et peu saturé au contact du fond -> transparent (reste de fond blanc)
            oi = o[..., :3].astype(int)
            blanc = (oi.min(-1) > 200) & (oi.max(-1) - oi.min(-1) < 30) & (o[..., 3] > 0)
            vide = o[..., 3] == 0
            bord = np.zeros_like(vide)
            bord[1:] |= vide[:-1]; bord[:-1] |= vide[1:]; bord[:, 1:] |= vide[:, :-1]; bord[:, :-1] |= vide[:, 1:]
            o[..., 3][blanc & bord] = 0
            img = Image.fromarray(o, "RGBA")
            q = img.convert("RGB").quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
            sorties.append(Image.merge("RGBA", (*q.split(), img.getchannel("A"))))
        hfin = []
        for i, im in enumerate(sorties):
            p = os.path.join(DST, "%s_%d.png" % (name, i))
            im.save(p, optimize=True)
            m = np.asarray(im)[..., 3] > 127
            ys = np.where(m.any(1))[0]
            hfin.append(int(SOL - ys.min()))
            res["sha256"][os.path.basename(p)] = hashlib.sha256(open(p, "rb").read()).hexdigest()
        res["cycles"][name] = {"hauteur_source_px": hs, "facteur": round(s, 4), "hauteur_px": hfin}
    res["sha256"]["planche_source"] = hashlib.sha256(open(planche, "rb").read()).hexdigest()
    with open(os.path.join(DST, "cadence_aren_v2.json"), "w", encoding="utf-8") as f:
        json.dump(res, f, ensure_ascii=False, indent=1)
    print(json.dumps(res["cycles"], ensure_ascii=False))


if __name__ == "__main__":
    main()
