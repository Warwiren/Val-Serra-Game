"""Val'Serra — Aren : marches de face et de dos DESSINÉES (GIF du 20/11/2026), préparées pour le banc d'essai (V4).

Usage :
    python3 tools/p49/aren_marche_gif.py <gif marche de face> <gif marche de dos> [--sortie art/tests/aren_4dir_v4]

Sources : deux GIF animés (8 images, 120 ms, fond transparent) fournis par le créateur le 20/11/2026 : marche vers
le bas (face) et marche vers le haut (dos), même design qu'Aren (cheveux bruns en pointes, écharpe grise,
épaulières, ceinture et fiole, bottes brunes, cape).

Traitement (technique uniquement, AUCUN redessin) :
  1. échelle : un seul facteur PAR CYCLE (pas par image), hauteur médiane du cycle -> 89 px (hauteur de la marche
     V09B.5 dans le canevas 96 × 112 ; en jeu ×0,719 -> 64 px) ;
  2. placement : un seul décalage PAR CYCLE : bas médian des pieds sur la rangée 100 (ligne de sol 101), axe médian
     de la tête sur x = 48. Le pas en profondeur dessiné (pied avant plus bas), le rebond et le balancement sont donc
     conservés tels quels ;
  3. réduction par moyenne de surface (alpha prémultiplié), alpha seuillé à 50 %, puis chaque couleur ramenée à la
     plus proche de la palette de 64 couleurs d'Aren en jeu (marche de profil V09B.5 + attentes de l'étude), sans
     tramage : les GIF, un peu plus clairs et moins contrastés, prennent les teintes du profil.
Sortie : walk_face_0..7, walk_back_0..7 + cadence_aren_4dir_v4.json (mesures, SHA-256 des GIF et des PNG).
"""
import argparse, glob, hashlib, json, os
import numpy as np
from PIL import Image, ImageSequence

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
W, H = 96, 112
SOL = 101
HAUTEUR = 89
TETE_X = 48


def images(path):
    out = []
    for f in ImageSequence.Iterator(Image.open(path)):
        a = np.asarray(f.convert("RGBA")).astype(np.float64) / 255.0
        a[..., 3] = (a[..., 3] > 0.5).astype(np.float64)
        out.append(a)
    return out


def mesure(a):
    m = a[..., 3] > 0
    ys, xs = np.where(m)
    top, bot = ys.min(), ys.max()
    _, xx = np.where(m[top:top + int(0.2 * (bot - top))])
    return top, bot, float(np.median(xx))


def reduit(a, s, x0, y0):
    M = 400
    pm = np.zeros((a.shape[0] + 2 * M, a.shape[1] + 2 * M, 4))
    pm[M:M + a.shape[0], M:M + a.shape[1]] = a
    pm[..., :3] *= pm[..., 3:4]
    src = Image.fromarray((pm * 255).round().astype(np.uint8), "RGBA")
    r = np.asarray(src.resize((W, H), Image.BOX, box=(x0 + M, y0 + M, x0 + M + W / s, y0 + M + H / s))).astype(np.float64) / 255
    al = r[..., 3:4]
    rgb = np.where(al > 0.001, r[..., :3] / np.maximum(al, 1e-6), 0)
    o = np.zeros((H, W, 4), np.uint8)
    o[..., :3] = (np.clip(rgb, 0, 1) * 255).round().astype(np.uint8)
    o[..., 3] = np.where(al[..., 0] >= 0.5, 255, 0)
    return o


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("face")
    ap.add_argument("dos")
    ap.add_argument("--sortie", default=os.path.join(REPO, "art/tests/aren_4dir_v4"))
    args = ap.parse_args()
    os.makedirs(args.sortie, exist_ok=True)
    res = {"statut": "Aren marches de face / de dos V4 — DESSINÉES (GIF du créateur, 20/11/2026), préparées sans redessin ; BANC D'ESSAI NON VALIDÉ",
           "pixel_m": 0.02, "ligne_sol_px": SOL, "cycles": {}, "sha256": {}}
    cycles = {"walk_face": images(args.face), "walk_back": images(args.dos)}
    sorties = {}
    for nom, fr in cycles.items():
        ms = [mesure(a) for a in fr]
        hs = [int(b - t + 1) for t, b, _ in ms]
        s = HAUTEUR / float(np.median(hs))
        bot = float(np.median([b for _, b, _ in ms])) + 1
        tx = float(np.median([x for _, _, x in ms]))
        x0, y0 = tx - TETE_X / s, bot - SOL / s
        sorties[nom] = [reduit(a, s, x0, y0) for a in fr]
        res["cycles"][nom] = {"images": len(fr), "duree_gif_ms": 120, "hauteur_source_px": hs, "facteur": round(s, 4),
                              "bas_source_px": [int(b) for _, b, _ in ms]}
    refs = sorted(glob.glob(os.path.join(REPO, "art/tests/v09b5_aren/walk_96x112/walk_right_*.png"))) + \
        sorted(glob.glob(os.path.join(REPO, "art/tests/aren_4dir/idle_*_0.png")))
    allpx = []
    for f in refs:
        a = np.asarray(Image.open(f).convert("RGBA"))
        allpx.append(a[..., :3][a[..., 3] > 127])
    allpx = np.concatenate(allpx)
    side = int(np.ceil(np.sqrt(len(allpx))))
    buf = np.zeros((side * side, 3), np.uint8); buf[:len(allpx)] = allpx; buf[len(allpx):] = allpx[0]
    pal = Image.fromarray(buf.reshape(side, side, 3), "RGB").quantize(64, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    for nom, v in sorties.items():
        bas, hauts = [], []
        for i, o in enumerate(v):
            img = Image.fromarray(o, "RGBA")
            q = img.convert("RGB").quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
            out = Image.merge("RGBA", (*q.split(), img.getchannel("A")))
            p = os.path.join(args.sortie, "%s_%d.png" % (nom, i))
            out.save(p, optimize=True)
            m = np.asarray(out)[..., 3] > 127
            ys = np.where(m.any(1))[0]
            hauts.append(int(SOL - ys.min())); bas.append(int(ys.max()))
            res["sha256"][os.path.basename(p)] = hashlib.sha256(open(p, "rb").read()).hexdigest()
        res["cycles"][nom].update({"hauteur_px": hauts, "bas_px": bas})
    for k, p in (("gif_face", args.face), ("gif_dos", args.dos)):
        res["sha256"][k] = hashlib.sha256(open(p, "rb").read()).hexdigest()
    with open(os.path.join(args.sortie, "cadence_aren_4dir_v4.json"), "w", encoding="utf-8") as f:
        json.dump(res, f, ensure_ascii=False, indent=1)
    for k, v in res["cycles"].items():
        print(k, v["facteur"], "hauteurs", v["hauteur_px"], "bas", v["bas_px"])


if __name__ == "__main__":
    main()
