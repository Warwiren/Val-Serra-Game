"""Val'Serra — Aren : jeu complet d'orientations cohérent avec le profil V09B.5 (banc d'essai).

Usage :
    python3 tools/p49/aren_orientations.py <dossier ValSerra_Aren_IDLE_V1_ETUDE>

Sources : étude d'attente « Aren IDLE V1 » (96 × 112, ancrage (48, 101)) : attente de profil droit recomposée à partir
d'un vrai sprite V09B.5, attentes de face et de dos dans les proportions du profil (tête, cheveux, armure).

Sortie art/tests/aren_4dir/ :
  - idle_right / idle_face / idle_back _{0..3}.png : attentes de l'étude, copiées, seule retouche : les pixels quasi
    blancs et neutres au bord de la silhouette, et les gris neutres au bord de la tête (reste de fond du détourage),
    deviennent transparents ;
  - walk_face / walk_back / run_face / run_back _{0..7}.png : cycles de marche et de course de face et de dos
    **PROCÉDURAUX** (dérivés de l'attente, aucun pixel nouveau) : jambes séparées au-dessus de l'écart entre les
    pieds, levées alternativement (marche 3 px, course 5 px de texture), corps soulevé au passage (1 px marche,
    2 px course) et basculé d'1 px vers la jambe d'appui ; bras et cape suivent le corps. Ce ne sont PAS des poses
    dessinées ;
  - cadence_aren_4dir.json : ligne de sol, hauteurs, paramètres, SHA-256.
Le profil droit en mouvement reste V09B.5 (`art/tests/v09b5_aren/`), la gauche son miroir.
"""
import hashlib, json, math, os, shutil, sys
import numpy as np
from PIL import Image

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DST = os.path.join(REPO, "art/tests/aren_4dir")
SOL = 101
VUES = {"droite": "right", "bas": "face", "haut": "back"}
CYCLES = {"walk": {"levee": 3, "rebond": 1, "bascule": 1}, "run": {"levee": 5, "rebond": 2, "bascule": 1}}
N = 8


def nettoie(a):
    """frange de détourage, retirée par passes successives (au plus 3) au contact du vide :
    - pixel quasi blanc et neutre, partout ;
    - gris neutre dans les 20 rangées du haut (tête : cheveux bruns, peau ; le métal gris des épaulières commence plus
      bas et n'est pas touché)."""
    a = a.copy()
    total = 0
    for _ in range(3):
        m = a[..., 3] > 127
        rgb = a[..., :3].astype(int)
        blanc = m & (rgb.min(-1) > 185) & (rgb.max(-1) - rgb.min(-1) < 30)
        ys = np.where(m.any(1))[0]
        tete = np.zeros_like(m)
        tete[ys.min():ys.min() + 20] = True
        gris = m & tete & (rgb.min(-1) > 100) & (rgb.max(-1) - rgb.min(-1) < 25)
        vide = ~m
        bord = np.zeros_like(vide)
        bord[1:] |= vide[:-1]; bord[:-1] |= vide[1:]; bord[:, 1:] |= vide[:, :-1]; bord[:, :-1] |= vide[:, 1:]
        sel = (blanc | gris) & bord
        if not sel.any():
            break
        a[..., 3][sel] = 0
        total += int(sel.sum())
    return a, total


def hanche(m):
    """première rangée (en partant des pieds) où l'écart entre les jambes se referme ; x de cet écart"""
    ys, xs = np.where(m)
    bot = ys.max()
    xc = int(np.median(xs))
    # écart : colonne vide la plus longue autour du centre, dans les 10 rangées du bas
    best = None
    for x in range(xc - 8, xc + 9):
        if not m[bot - 10:bot + 1, x].any():
            y = bot
            while y > 0 and not m[y, x]:
                y -= 1
            if best is None or y < best[0]:
                best = (y, x)
    return best[0] + 1, best[1]


def marche(base, levee, rebond, bascule):
    m = base[..., 3] > 127
    h, xg = hanche(m)
    frames = []
    for k in range(N):
        s = math.sin(2 * math.pi * k / N)
        lg = int(round(levee * max(0.0, s)))
        ld = int(round(levee * max(0.0, -s)))
        rb = int(round(rebond * abs(s)))
        bx = int(round(bascule * s))            # poids sur la jambe d'appui : le haut du corps bascule d'1 px vers elle
        out = np.zeros_like(base)
        for x0, x1, l in ((0, xg, lg), (xg, base.shape[1], ld)):
            jambe = base[h - 2:, x0:x1]
            ys = np.arange(h - 2, base.shape[0]) - l
            ok = ys >= 0
            zone = out[ys[ok], x0:x1]
            src = jambe[ok]
            sel = src[..., 3] > 0
            zone[sel] = src[sel]
            out[ys[ok], x0:x1] = zone
        corps = np.roll(base[:h], bx, axis=1)
        if bx > 0:
            corps[:, :bx] = 0
        elif bx < 0:
            corps[:, bx:] = 0
        dst = np.arange(h) - rb
        ok = dst >= 0
        zone = out[dst[ok]]
        src = corps[ok]
        sel = src[..., 3] > 0
        zone[sel] = src[sel]
        out[dst[ok]] = zone
        frames.append(out)
    return frames, {"hanche_rangee": int(h), "ecart_x": int(xg)}


def main():
    src = sys.argv[1].rstrip("/")
    os.makedirs(DST, exist_ok=True)
    res = {"statut": "Aren 4 directions — BANC D'ESSAI NON VALIDÉ ; attentes de l'étude IDLE V1, marches et courses de face / dos PROCÉDURALES",
           "pixel_m": 0.02, "ligne_sol_px": SOL, "nettoyage_px": {}, "cycles": {}, "sha256": {}}
    bases = {}
    for fr, en in VUES.items():
        for i in range(4):
            a = np.asarray(Image.open(os.path.join(src, "aren_idle_%s_%d.png" % (fr, i))).convert("RGBA"))
            a, n = nettoie(a)
            res["nettoyage_px"]["idle_%s_%d" % (en, i)] = n
            Image.fromarray(a, "RGBA").save(os.path.join(DST, "idle_%s_%d.png" % (en, i)), optimize=True)
            if i == 0:
                bases[en] = a
    for en in ("face", "back"):
        for cyc, p in CYCLES.items():
            frames, info = marche(bases[en], p["levee"], p["rebond"], p["bascule"])
            for i, f in enumerate(frames):
                Image.fromarray(f, "RGBA").save(os.path.join(DST, "%s_%s_%d.png" % (cyc, en, i)), optimize=True)
            res["cycles"]["%s_%s" % (cyc, en)] = dict(p, **info, procedural=True)
    for f in sorted(os.listdir(DST)):
        if f.endswith(".png"):
            p = os.path.join(DST, f)
            m = np.asarray(Image.open(p))[..., 3] > 127
            ys = np.where(m.any(1))[0]
            res["sha256"][f] = hashlib.sha256(open(p, "rb").read()).hexdigest()
            res["cycles"].setdefault("hauteurs_px", {})[f[:-4]] = int(SOL - ys.min())
    with open(os.path.join(DST, "cadence_aren_4dir.json"), "w", encoding="utf-8") as fp:
        json.dump(res, fp, ensure_ascii=False, indent=1)
    print(json.dumps({k: v for k, v in res["cycles"].items() if k != "hauteurs_px"}, ensure_ascii=False), res["nettoyage_px"])


if __name__ == "__main__":
    main()
