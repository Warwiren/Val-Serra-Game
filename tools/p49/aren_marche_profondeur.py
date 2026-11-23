"""Val'Serra — Aren : marche et course de face / de dos « en profondeur » (proposition V3, banc d'essai).

Usage :
    python3 tools/p49/aren_marche_profondeur.py [--sortie art/tests/aren_4dir_v3]

Source : attentes de face et de dos de l'étude « Aren IDLE V1 » déjà nettoyées (`art/tests/aren_4dir/idle_*_0.png`).
Méthode (PROCÉDURALE : aucun pixel inventé, seulement déplacés / répétés) :
  - la foulée est projetée comme la caméra la voit : un pied qui avance vers la caméra descend à l'écran, un pied qui
    recule remonte (vue de face) ; c'est l'inverse de dos. Amplitude = demi-foulée du profil V09B.5 × sin(24°) / 2 ×
    part retenue (marche 0,6, course 0,4 : ±5,6 / ±7,4 px de texture ; 1,0 planterait parfaitement le pied d'appui
    mais étirerait trop les jambes courtes de ce personnage : il glisse donc encore un peu) ;
  - pied d'appui : recul régulier ; pied en l'air : avance en douceur et se lève (3 px marche, 6 px
    course) ;
  - botte rigide, cuisse étirée (répétition de rangées) pour rester attachée sous la tunique ; la jambe proche de la
    caméra passe devant l'autre ;
  - bras en opposition des jambes : la main qui avance vers la caméra descend, l'autre remonte (2 px marche, 3 px
    course) ; corps soulevé au passage (1 px marche, 2 px course) et décalé d'1 px vers la jambe d'appui ;
  - frange grise de détourage retirée sur les jambes.
Ce ne sont PAS des poses dessinées.
"""
import argparse, hashlib, json, math, os
import numpy as np
from PIL import Image

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(REPO, "art/tests/aren_4dir")
N = 8
TANGAGE = 24.0
# « part » : fraction de la projection physique retenue. 1,0 = pied d'appui parfaitement planté (demi-foulée du profil
# V09B.5 : 46 px de texture en marche, 91 en course, × sin 24° / 2 = ±9,4 / ±18,5 px), mais jambes très étirées pour
# ce personnage aux jambes courtes ; 0,6 / 0,4 = compromis, le pied d'appui glisse encore un peu vers le haut
PIED = 9                  # rangées rigides du bas (pied et bas de la botte) ; au-dessus, la jambe s'étire / se tasse
CYCLES = {
    "walk": {"demi_foulee_px": 46, "part": 0.6, "levee": 3, "rebond": [0, 1, 1, 0], "bras": 2},
    "run": {"demi_foulee_px": 91, "part": 0.4, "levee": 6, "rebond": [0, 1, 2, 1], "bras": 3},
}
# zones (x0, x1, y0, y1) des bras dans le canevas 96 × 112 ; « bas » = première rangée du bras qui bouge (épaule fixe)
HAUT_DOS = 82
BRAS = {"face": ((22, 33, 54, 73), (58, 67, 54, 73)), "back": ((22, 38, 52, 76), (60, 76, 52, 76))}


def masque_bras(z, vue):
    """pixels du bras dans la zone : tout sauf la cape (gris-beige moyen de dos ; brun-gris sombre à droite de face)"""
    rgb = z[..., :3].astype(int)
    moy, sat = rgb.mean(-1), rgb.max(-1) - rgb.min(-1)
    peau = (rgb[..., 0] > 150) & (rgb[..., 0] - rgb[..., 2] > 60)
    if vue == "back":
        cape = (moy > 70) & (sat < 70) & ~peau
    else:
        cape = np.zeros(moy.shape, bool)
    return (z[..., 3] > 0) & ~cape


def frange_jambes(a, y0):
    a = a.copy()
    for _ in range(2):
        m = a[..., 3] > 127
        rgb = a[..., :3].astype(int)
        gris = m & (rgb.min(-1) > 105) & (rgb.max(-1) - rgb.min(-1) < 28)
        gris[:y0] = False
        vide = ~m
        bord = np.zeros_like(vide)
        bord[1:] |= vide[:-1]; bord[:-1] |= vide[1:]; bord[:, 1:] |= vide[:, :-1]; bord[:, :-1] |= vide[:, 1:]
        a[..., 3][gris & bord] = 0
    return a


def reperes(m):
    """rangée où l'écart entre les jambes se referme (haut des jambes visibles), x de l'écart, haut des bottes"""
    ys, xs = np.where(m)
    bot = ys.max()
    xc = int(np.median(xs))
    best = None
    for x in range(xc - 8, xc + 9):
        if not m[bot - 10:bot + 1, x].any():
            y = bot
            while y > 0 and not m[y, x]:
                y -= 1
            if best is None or y < best[0]:
                best = (y, x)
    return best[0] + 1, best[1], bot


def colle(out, src, dy, dx=0):
    """dépose les pixels opaques de src dans out, décalés de (dx, dy)"""
    H, W = out.shape[:2]
    ys, xs = np.where(src[..., 3] > 0)
    ty, tx = ys + dy, xs + dx
    ok = (ty >= 0) & (ty < H) & (tx >= 0) & (tx < W)
    out[ty[ok], tx[ok]] = src[ys[ok], xs[ok]]


def jambe(base, x0, x1, haut, botte, bas, dy, rb):
    """jambe (colonnes x0..x1) : botte rigide décalée de dy, cuisse étirée entre la hanche (haut - rb) et la botte"""
    out = np.zeros_like(base)
    seg = base[:, x0:x1]
    # botte
    b = np.zeros_like(seg); b[botte:bas + 1] = seg[botte:bas + 1]
    tmp = np.zeros_like(out); tmp[:, x0:x1] = b
    colle(out, tmp, dy)
    # cuisse : rangées haut..botte-1 réparties sur haut-rb .. botte+dy-1 (au plus proche)
    y_a, y_b = haut - rb, botte + dy
    n_src = botte - haut
    if y_b > y_a and n_src > 0:
        for y in range(y_a, y_b):
            s = haut + min(n_src - 1, int((y - y_a) * n_src / (y_b - y_a)))
            if 0 <= y < out.shape[0]:
                row = seg[s]
                sel = row[:, 3] > 0
                cur = out[y, x0:x1]
                keep = cur[:, 3] > 0
                cur[sel & ~keep] = row[sel & ~keep]
                out[y, x0:x1] = cur
    return out


def phase(k, decal):
    """profondeur d (+1 = pied en avant) et levée normalisée du pied pour l'image k ; appui linéaire, envol en douceur"""
    u = ((k + decal) % N) / N
    if u < 0.5:
        return 1 - 4 * u, 0.0                   # appui : de +1 à -1, linéaire (pied planté)
    v = (u - 0.5) * 2
    return -math.cos(math.pi * v), math.sin(math.pi * v)


def cycle(base, vue, p):
    m = base[..., 3] > 127
    haut, xg, bas = reperes(m)
    # de face : jambes prises 2 rangées au-dessus de la fermeture de l'écart (sous la tunique) ; de dos : sous l'ourlet
    # de la cape (rangée 82), sinon le bas de la cape partirait avec la jambe
    haut = haut - 2 if vue == "face" else HAUT_DOS
    botte = bas - PIED + 1
    amp = p["part"] * p["demi_foulee_px"] * math.sin(math.radians(TANGAGE)) / 2
    signe = 1 if vue == "face" else -1          # de face, le pied avancé descend ; de dos, il monte
    frames, details = [], []
    for k in range(N):
        rb = p["rebond"][k % 4]
        dG, lG = phase(k, 0)
        dD, lD = phase(k, N // 2)
        dyG = int(round(signe * amp * dG - p["levee"] * lG))
        dyD = int(round(signe * amp * dD - p["levee"] * lD))
        appui_gauche = lG == 0.0
        bx = 0 if k % 4 == 0 else (-1 if appui_gauche else 1)
        out = np.zeros_like(base)
        jg = jambe(base, 0, xg, haut, botte, bas, dyG, rb)
        jd = jambe(base, xg, base.shape[1], haut, botte, bas, dyD, rb)
        # jambe proche de la caméra au-dessus : de face la plus avancée, de dos la plus reculée
        procheG = (dG > dD) if vue == "face" else (dG < dD)
        for j in ((jd, jg) if procheG else (jg, jd)):
            colle(out, j, 0)
        corps = base.copy(); corps[haut + (2 if vue == "face" else 1):] = 0
        bras_px = []
        for (x0, x1, y0, y1), d in zip(BRAS[vue], (dG, dD)):
            dyb = int(round(-signe * p["bras"] * d))      # bras opposé à la jambe du même côté
            z = corps[y0:y1, x0:x1].copy()
            mb = masque_bras(z, vue)
            z[~mb] = 0
            corps[y0:y1, x0:x1][mb] = 0
            # épaule fixe, main décalée : étirement / tassement au plus proche (seuls les pixels du bras bougent)
            n = y1 - y0
            m_ = n + dyb
            dst = np.zeros((m_, x1 - x0, 4), np.uint8)
            for y in range(m_):
                dst[y] = z[min(n - 1, int(y * n / m_))]
            zone = corps[y0:y0 + m_, x0:x1]
            corps[y0:y0 + m_, x0:x1] = np.where(dst[..., 3:4] > 0, dst, zone)
            # main remontée devant la tunique / la cape : le vide laissé est comblé en prolongeant vers le haut ce qui
            # est juste dessous (à l'extérieur de la silhouette, il reste transparent)
            for x in range(x0, x1):
                for y in range(y1 - 1, y0 - 1, -1):
                    if mb[y - y0, x - x0] and corps[y, x, 3] == 0 and y + 1 < corps.shape[0] and corps[y + 1, x, 3] > 0:
                        corps[y, x] = corps[y + 1, x]
            bras_px.append(dyb)
        colle(out, corps, -rb, bx)
        frames.append(out)
        details.append({"image": k, "pied_g_px": dyG, "pied_d_px": dyD, "rebond_px": rb, "bascule_px": bx, "mains_px": bras_px})
    return frames, {"haut_jambes": int(haut), "ecart_x": int(xg), "haut_bottes": int(botte),
                    "amplitude_px": round(amp, 2), "images": details}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sortie", default=os.path.join(REPO, "art/tests/aren_4dir_v3"))
    dst = ap.parse_args().sortie
    os.makedirs(dst, exist_ok=True)
    res = {"statut": "Aren face / dos V3 « en profondeur » — PROPOSITION PROCÉDURALE, BANC D'ESSAI NON VALIDÉ",
           "source": "art/tests/aren_4dir/idle_{face,back}_0.png (étude IDLE V1)", "tangage_deg": TANGAGE,
           "pixel_m": 0.02, "ligne_sol_px": 101, "cycles": {}, "sha256": {}}
    for vue in ("face", "back"):
        base = np.asarray(Image.open(os.path.join(SRC, "idle_%s_0.png" % vue)).convert("RGBA"))
        base = frange_jambes(base, 74)
        for cyc, p in CYCLES.items():
            frames, info = cycle(base, vue, p)
            for i, f in enumerate(frames):
                Image.fromarray(f, "RGBA").save(os.path.join(dst, "%s_%s_%d.png" % (cyc, vue, i)), optimize=True)
            res["cycles"]["%s_%s" % (cyc, vue)] = dict({k: v for k, v in p.items()}, **info, procedural=True)
    for f in sorted(os.listdir(dst)):
        if f.endswith(".png"):
            res["sha256"][f] = hashlib.sha256(open(os.path.join(dst, f), "rb").read()).hexdigest()
    with open(os.path.join(dst, "cadence_aren_4dir_v3.json"), "w", encoding="utf-8") as fp:
        json.dump(res, fp, ensure_ascii=False, indent=1)
    for k, v in res["cycles"].items():
        print(k, v["amplitude_px"], [(d["pied_g_px"], d["pied_d_px"], d["mains_px"]) for d in v["images"]])


if __name__ == "__main__":
    main()
