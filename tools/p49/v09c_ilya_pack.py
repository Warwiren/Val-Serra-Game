"""Val'Serra V09C — banc d'essai d'Ilya : prépare les images de test à partir des livraisons de la direction artistique.

Usage :
    python3 tools/p49/v09c_ilya_pack.py <pack V09C.5 (dossier ValSerra_V09C5_Ilya_Pack_CLAUDE_QA)> <planche marche droite (2 × 4 poses)>

Produit art/tests/v09c_ilya/ :
  - exploration/{right,left,face,back}/{idle,walk,run}_<dir>_{0..7}.png : copies SANS RETOUCHE du pack V09C.5,
    sauf walk_right, remplacée par la planche de marche du 19/11/2026 ;
  - portraits/<expression>.png : copies sans retouche du pack ;
  - cadence_v09c.json : mesures (hauteur, ligne de sol, foulée, recul du pied d'appui) ;
  - SOURCES.md est écrit à la main (provenance, statut).

Traitement de la planche de marche (ajustements TECHNIQUES, aucun redessin) :
  1. découpage en 2 × 4 cellules (bornes 0/444/887/1331/1774 × 0/444/887, comme les planches d'Aren) ;
  2. transparence nette : alpha >= 128 -> opaque, sinon transparent (le WebP livré a un personnage à alpha 249-253
     et un voile d'alpha 1 sur le fond) ;
  3. recalage horizontal du personnage (cycle « sur place ») : décalage qui ramène l'avant du visage et le centre du
     buste (cape exclue) à leur médiane sur les 8 poses ; aucun décalage vertical (les pieds sont déjà au même niveau) ;
  4. réduction à la densité du pack V09C.5 (hauteur médiane 89 px pour 96 × 112) par moyenne de surface en alpha
     prémultiplié, alpha seuillé à 50 %, couleurs ramenées sans tramage à une palette de 64 couleurs tirée de la
     planche elle-même (lisse le bruit de compression du WebP) ;
  5. placement sur le canevas 96 × 112 du pack : bas des semelles sur la rangée 103 (ligne de sol 104 du pack
     pour le profil droit), avant du visage en x = 64 comme walk_right du pack.
"""
import hashlib, json, os, shutil, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from v09b6_gabarit import mesure_cycle, opaque  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DST = os.path.join(REPO, "art/tests/v09c_ilya")
BX, BY = [0, 444, 887, 1331, 1774], [0, 444, 887]
CANEVAS = (96, 112)
SOL = 104                # bord inférieur des semelles (profil droit du pack V09C.5)
VISAGE_X = 64            # avant du visage, walk_right du pack V09C.5
HAUTEUR_CIBLE = 89       # hauteur médiane des poses du pack V09C.5
DIRS = ["right", "left", "face", "back"]
# paires sans pied d'appui commun (mesure) : course du pack (pas d'envol dessiné mais appels) ; marche : aucune
SANS_APPUI = {"walk": [], "run": [2, 3, 6, 7], "idle": []}
# Artefacts de détourage du pack V09C.5 (aplats quasi noirs collés au personnage), relevés pixel par pixel :
# dans chaque rectangle (x0, y0, x1, y1 exclus), seuls les pixels opaques quasi noirs (R+G+B < 120) deviennent
# transparents. Retouche de transparence uniquement, sur la copie de test ; le pack d'origine n'est pas modifié.
NETTOYAGE = {
    "right/run_right_4.png": [(74, 100, 82, 104)],              # pavé 8 × 4 contre la botte arrière
    "right/run_right_6.png": [(5, 53, 25, 54), (38, 47, 52, 50)],  # trait de 20 px, pavé 14 × 3 au-dessus de la cape
}


def cellules(path):
    im = Image.open(path).convert("RGBA")
    a = np.asarray(im).astype(np.int32)
    out = []
    for r in range(2):
        for c in range(4):
            cell = a[BY[r]:BY[r + 1], BX[c]:BX[c + 1]].copy()
            cell[..., 3] = np.where(cell[..., 3] >= 128, 255, 0)
            out.append(cell)
    return out


def reperes(cell):
    """avant du visage et centre du buste hors cape (pixels verts et dorés exclus)"""
    m = cell[..., 3] > 0
    ys, _ = np.where(m)
    top, bot = ys.min(), ys.max()
    h = bot - top
    face = max(np.where(m[y])[0].max() for y in range(top + int(0.19 * h), top + int(0.27 * h)))
    rgb = cell[..., :3]
    green = (rgb[..., 1] > rgb[..., 0] + 8) & (rgb[..., 1] > rgb[..., 2] + 8)
    gold = (rgb[..., 0] > 150) & (rgb[..., 2] < 110)
    body = m & ~green & ~gold
    band = body[top + int(0.28 * h):top + int(0.40 * h)]
    mids = [(np.where(row)[0].min() + np.where(row)[0].max()) / 2 for row in band if row.any()]
    return float(face), float(np.median(mids)), int(top), int(bot)


def palette(cells, n=64):
    px = np.concatenate([c[c[..., 3] > 0][:, :3] for c in cells]).astype(np.uint8)
    side = int(np.ceil(np.sqrt(len(px))))
    buf = np.zeros((side * side, 3), np.uint8)
    buf[:len(px)] = px
    buf[len(px):] = px[0]
    return Image.fromarray(buf.reshape(side, side, 3), "RGB").quantize(n, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)


def recale(cell, dx):
    """cellule décalée horizontalement de dx px source, dans une marge de 200 px, alpha prémultiplié (0..1)"""
    H, W = cell.shape[:2]
    big = np.zeros((H + 400, W + 400, 4), np.float64)
    big[200:200 + H, 200 + dx:200 + dx + W] = cell
    a = big / 255.0
    a[..., :3] *= a[..., 3:4]
    return a


def prepare_marche(planche, pal_cache=None):
    cells = cellules(planche)
    rep = [reperes(c) for c in cells]
    faces = np.array([r[0] for r in rep])
    torses = np.array([r[1] for r in rep])
    dxs = [int(round(-((f - np.median(faces)) + (t - np.median(torses))) / 2)) for f, t in zip(faces, torses)]
    hauts = [r[3] - r[2] + 1 for r in rep]
    s = HAUTEUR_CIBLE / float(np.median(hauts))
    pal = palette(cells)
    face_ref = float(np.median(faces))
    frames = []
    for cell, dx in zip(cells, dxs):
        a = recale(cell, dx)
        W, H = CANEVAS
        # repère : avant du visage (source, après recalage) -> x = VISAGE_X ; semelles -> y = SOL
        fx = 200 + face_ref
        x0 = fx - VISAGE_X / s
        y0 = 200 + float(np.median([r[3] + 1 for r in rep])) - SOL / s
        pim = Image.fromarray((a * 255).round().astype(np.uint8), "RGBA")
        r = np.asarray(pim.resize((W, H), Image.BOX, box=(x0, y0, x0 + W / s, y0 + H / s))).astype(np.float64) / 255
        al = r[..., 3:4]
        rgb = np.where(al > 0.001, r[..., :3] / np.maximum(al, 1e-6), 0)
        out = np.zeros((H, W, 4), np.uint8)
        out[..., :3] = (np.clip(rgb, 0, 1) * 255).round().astype(np.uint8)
        out[..., 3] = np.where(al[..., 0] >= 0.5, 255, 0)
        img = Image.fromarray(out, "RGBA")
        q = img.convert("RGB").quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
        frames.append(Image.merge("RGBA", (*q.split(), img.getchannel("A"))))
    info = {"decalages_px_source": dxs, "hauteurs_source_px": hauts, "facteur_reduction": round(s, 4),
            "avant_visage_source": faces.round().tolist(), "centre_buste_source": torses.round().tolist()}
    return frames, info


def centre_tete(a):
    """centre horizontal des pixels clairs (visage, cheveux) du quart supérieur du personnage"""
    m = a[..., 3] > 127
    ys, _ = np.where(m)
    top, bot = ys.min(), ys.max()
    light = m & (a[..., :3].astype(int).sum(-1) > 330)
    _, xx = np.where(light[top:top + int(0.25 * (bot - top))])
    return float(np.median(xx))


def centre_pieds(a):
    """centre horizontal des pixels opaques des 4 rangées du bas (pieds)"""
    m = a[..., 3] > 127
    ys, _ = np.where(m)
    _, xx = np.where(m[ys.max() - 3:ys.max() + 1])
    return float(np.median(xx))


def recale_cycle(paths, repere):
    """translation horizontale entière qui ramène le repère (tête pour la marche et la course de profil, pieds pour
    l'attente) de chaque image à la médiane du cycle, seulement à partir de 2 px d'écart. Aucun pixel redessiné."""
    imgs = [np.asarray(Image.open(p).convert("RGBA")).copy() for p in paths]
    hc = [repere(a) for a in imgs]
    med = float(np.median(hc))
    shifts = []
    for p, a, h in zip(paths, imgs, hc):
        dx = int(round(med - h))
        if abs(dx) < 2:
            shifts.append(0)
            continue
        out = np.zeros_like(a)
        if dx > 0:
            out[:, dx:] = a[:, :-dx]
        else:
            out[:, :dx] = a[:, -dx:]
        Image.fromarray(out, "RGBA").save(p, optimize=True)
        shifts.append(dx)
    return shifts


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def main():
    pack, planche = sys.argv[1].rstrip("/"), sys.argv[2]
    os.makedirs(DST, exist_ok=True)
    res = {"statut": "V09C — BANC D'ESSAI d'Ilya, NON VALIDÉ ; pack V09C.5 + marche droite du 19/11/2026",
           "pixel_m": 0.02, "hauteur_reference_px": 64, "directions": {}, "sha256": {}}
    for d in DIRS:
        os.makedirs(os.path.join(DST, "exploration", d), exist_ok=True)
        for cyc in ("idle", "walk", "run"):
            for i in range(8):
                src = os.path.join(pack, "exploration", d, "%s_%s_%d.png" % (cyc, d, i))
                dst = os.path.join(DST, "exploration", d, "%s_%s_%d.png" % (cyc, d, i))
                if not (d == "right" and cyc == "walk"):
                    shutil.copyfile(src, dst)
    res["nettoyage"] = {}
    for rel, rects in NETTOYAGE.items():
        p = os.path.join(DST, "exploration", rel)
        a = np.asarray(Image.open(p).convert("RGBA")).copy()
        n = 0
        for x0, y0, x1, y1 in rects:
            zone = a[y0:y1, x0:x1]
            sel = (zone[..., 3] > 127) & (zone[..., :3].astype(int).sum(-1) < 120)
            zone[..., 3][sel] = 0
            n += int(sel.sum())
        Image.fromarray(a, "RGBA").save(p, optimize=True)
        res["nettoyage"][rel] = {"rectangles": rects, "pixels_effaces": n}
    frames, info = prepare_marche(planche)
    for i, f in enumerate(frames):
        f.save(os.path.join(DST, "exploration/right/walk_right_%d.png" % i), optimize=True)
    res["marche_droite_preparation"] = info
    res["recalage_px"] = {}
    for d in DIRS:
        for cyc in ("idle", "walk", "run"):
            if d == "right" and cyc == "walk":
                continue                             # déjà recalée (visage + buste) à la préparation
            if cyc != "idle" and d in ("face", "back"):
                continue                             # face / dos : le balancement latéral fait partie du mouvement
            ps = [os.path.join(DST, "exploration", d, "%s_%s_%d.png" % (cyc, d, i)) for i in range(8)]
            sh = recale_cycle(ps, centre_pieds if cyc == "idle" else centre_tete)
            if any(sh):
                res["recalage_px"]["%s_%s" % (cyc, d)] = sh
    for d in DIRS:
        res["directions"][d] = {}
        for cyc in ("idle", "walk", "run"):
            fr = [Image.open(os.path.join(DST, "exploration", d, "%s_%s_%d.png" % (cyc, d, i))) for i in range(8)]
            m = mesure_cycle(fr, SANS_APPUI[cyc])
            e = {"ligne_sol_px": m["sol_px"], "hauteur_px": m["hauteur_px"]}
            if cyc != "idle":
                e["recul_pied_appui_px_par_image"] = m["recul_pied_appui_px"]
                # face / dos : le recul horizontal ne mesure pas l'avance (déplacement vers la caméra) ; la foulée en
                # mètres reprend celle du profil (même personnage, même allure)
                e["foulee_px_mesuree"] = m["foulee_px"]
            res["directions"][d][cyc] = e
    # foulées retenues (px de texture) : profils mesurés ; face/dos = profil droit
    for cyc in ("walk", "run"):
        fd = res["directions"]["right"][cyc]["foulee_px_mesuree"]
        for d in DIRS:
            fm = res["directions"][d][cyc]["foulee_px_mesuree"]
            res["directions"][d][cyc]["foulee_px"] = fm if d in ("right", "left") and fm and fm > 20 else fd
    os.makedirs(os.path.join(DST, "portraits"), exist_ok=True)
    for f in sorted(os.listdir(os.path.join(pack, "portraits"))):
        shutil.copyfile(os.path.join(pack, "portraits", f), os.path.join(DST, "portraits", f))
    for root, _, fs in os.walk(DST):
        for f in sorted(fs):
            if f.endswith(".png"):
                p = os.path.join(root, f)
                res["sha256"][os.path.relpath(p, DST)] = sha(p)
    res["image_de_depart"] = 1
    with open(os.path.join(DST, "cadence_v09c.json"), "w", encoding="utf-8") as f:
        json.dump(res, f, ensure_ascii=False, indent=1)
    print(json.dumps({"marche": info, "droite": res["directions"]["right"], "gauche": {k: {a: v.get(a) for a in ("foulee_px", "recul_pied_appui_px_par_image")} for k, v in res["directions"]["left"].items()}}, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
