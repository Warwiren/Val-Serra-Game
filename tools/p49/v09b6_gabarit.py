"""Val'Serra V09B.6 — gabarit d'Aren, calques d'échelle 64 px et fiches de correction pose par pose.

Usage :
    python3 tools/p49/v09b6_gabarit.py <dossier ValSerra_V09B5_Aren_Marche_Course_Revue/> [--sortie-media DOSSIER]

Produit :
  - art/tests/v09b6_aren/calque_64/{walk,run}_right_{0..7}.png : poses V09B.5 ramenées à la hauteur P4.8 (64 px) sur
    le canevas P4.8 (128 x 96, sol = bas de l'image, torse en x = 60). RÉDUCTION AUTOMATIQUE (moyenne de surface,
    alpha prémultiplié, palette du pack) : CALQUE D'ÉCHELLE et base de repixelisation, PAS un asset, pas une
    correction du dessin.
  - art/tests/v09b6_aren/cadence_v09b6.json : mesures (hauteur, sol, foulée, recul du pied d'appui) des calques et
    des cycles P4.8 et V09B.5, au même format que cadence_v09b5.json.
  - fiches PNG (gabarit, corrections marche et course) et GIF de contrôle dans le dossier média.

Mesure du recul : bassin aligné => recul du pied d'appui d'une image à la suivante = avance du corps. Superposition
des pixels opaques des rangées du bas (bottes au sol), décalage horizontal qui maximise le recouvrement. Les paires
sans pied d'appui commun (envol, appel) sont marquées null d'après l'analyse à l'œil (voir ROLES).
"""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PX_M = 0.02
GABARIT = {"canevas": [128, 96], "sol_rangee": 96, "torse_x": 60, "hauteur_px": 64, "tolerance_pc": 5}
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

# Rôle observé de chaque pose V09B.5 (analyse à l'œil des jambes, 96 x 112) et paires sans appui commun
ROLES = {
    "walk": ["contact A (talon avant)", "descente A (pied d'appui déjà sous le bassin)", "passage A (pied d'appui déjà derrière)",
             "contact B", "contact B bis (doublon, pied avant à plat)", "appui B (pied libre derrière)", "passage B (genou haut)",
             "contact A bis (doublon de 0)"],
    "run": ["contact A", "appui A", "poussée A", "envol", "envol bis (doublon de 3)", "contact B", "appui B", "poussée B"],
}
SANS_APPUI = {"walk": [], "run": [2, 3, 4, 7]}
# poses redessinées selon PLAN : course = appel 2->3, envols 3->4 et 7->0, appel 6->7 sans pied d'appui commun
SANS_APPUI_DESSIN = {"walk": [], "run": [2, 3, 6, 7]}

# Plan V09B.6 (cible au gabarit 64 px). talon = position du talon du pied d'appui par rapport au torse (px, + = avant).
# source = pose V09B.5 qui sert de point de départ (None = pose à dessiner). action = correction à apporter.
PLAN = {
    "walk": {"foulee_px": 64, "poses": [
        {"role": "contact A", "talon": 12, "source": 0, "bassin_dy": 0},
        {"role": "descente A (bassin −1 px)", "talon": 4, "source": 1, "bassin_dy": -1},
        {"role": "passage A", "talon": -4, "source": 2, "bassin_dy": 0},
        {"role": "montée A (bassin +1 px)", "talon": -12, "source": None, "bassin_dy": 1},
        {"role": "contact B", "talon": 12, "source": 3, "bassin_dy": 0},
        {"role": "descente B (bassin −1 px)", "talon": 4, "source": 4, "bassin_dy": -1},
        {"role": "passage B", "talon": -4, "source": 6, "bassin_dy": 0},
        {"role": "montée B (bassin +1 px)", "talon": -12, "source": 5, "bassin_dy": 1},
    ]},
    "run": {"foulee_px": 128, "poses": [
        {"role": "contact A", "talon": 12, "source": 0, "bassin_dy": 0},
        {"role": "appui A (bassin −1 px)", "talon": -4, "source": 1, "bassin_dy": -1},
        {"role": "poussée A", "talon": -20, "source": 2, "bassin_dy": 0},
        {"role": "envol A→B (pieds +2 à +3 px)", "talon": None, "source": 3, "bassin_dy": 1},
        {"role": "contact B", "talon": 12, "source": 5, "bassin_dy": 0},
        {"role": "appui B (bassin −1 px)", "talon": -4, "source": 6, "bassin_dy": -1},
        {"role": "poussée B", "talon": -20, "source": 7, "bassin_dy": 0},
        {"role": "envol B→A (pieds +2 à +3 px)", "talon": None, "source": None, "bassin_dy": 1},
    ]},
}


# ------------------------------------------------------------------------------------------------ reconstruction
class Pack:
    def __init__(self, path):
        self.p = path.rstrip("/") + "/"
        self.man = json.load(open(self.p + "QA_MANIFEST.json"))
        self.src = {k: Image.open(self.p + "sources/" + v).convert("RGBA") for k, v in self.man["source_files"].items()}

    def aligned(self, kind, i):
        """pose i alignée comme dans le pack (torse ~ x 257, sol 410 dans le repère de cellule), décalée de (500, 500)"""
        bx, by = self.man["cell_boundaries_x"], self.man["cell_boundaries_y"]
        r, c = divmod(i, 4)
        cell = self.src[kind].crop((bx[c], by[r], bx[c + 1], by[r + 1]))
        det = self.man["detail"][kind][i]
        out = Image.new("RGBA", (1400, 1400), (0, 0, 0, 0))
        out.paste(cell, (500 + det["torso_correction_px"], 500 + det["foot_alignment_dy_px"]), cell)
        return out

    def calque(self, kind, i, palette, hauteur=64):
        """réduction par moyenne de surface vers `hauteur` px (le 96x112 du pack = 88 px pour 374 px source, 1/4,25)"""
        W, H = GABARIT["canevas"]
        s = (1 / 4.25) * hauteur / 88.0
        im = self.aligned(kind, i)
        # 2,5 px (échelle 96x112) : écart mesuré entre cette reconstruction et le pack (99,3 % de pixels identiques)
        x0 = 500 + 257 - GABARIT["torse_x"] / s
        y0 = 500 + 410 - 2.5 * 4.25 - GABARIT["sol_rangee"] / s
        a = np.asarray(im).astype(np.float64) / 255
        pm = a.copy()
        pm[..., :3] *= pm[..., 3:4]
        pim = Image.fromarray((pm * 255).round().astype(np.uint8), "RGBA")
        r = np.asarray(pim.resize((W, H), Image.BOX, box=(x0, y0, x0 + W / s, y0 + H / s))).astype(np.float64) / 255
        al = r[..., 3:4]
        rgb = np.where(al > 0.001, r[..., :3] / np.maximum(al, 1e-6), 0)
        out = np.zeros((H, W, 4), np.uint8)
        out[..., :3] = (np.clip(rgb, 0, 1) * 255).round().astype(np.uint8)
        out[..., 3] = np.where(al[..., 0] >= 0.5, 255, 0)
        img = Image.fromarray(out, "RGBA")
        q = img.convert("RGB").quantize(palette=palette, dither=Image.Dither.NONE).convert("RGB")
        return Image.merge("RGBA", (*q.split(), img.getchannel("A")))


def palette_of(paths, n=48):
    px = []
    for p in paths:
        a = np.asarray(Image.open(p).convert("RGBA"))
        px.append(a[a[..., 3] > 127][:, :3])
    allpx = np.concatenate(px)
    side = int(np.ceil(np.sqrt(len(allpx))))
    buf = np.zeros((side * side, 3), np.uint8)
    buf[:len(allpx)] = allpx
    buf[len(allpx):] = allpx[0]
    return Image.fromarray(buf.reshape(side, side, 3), "RGB").quantize(n, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)


# ------------------------------------------------------------------------------------------------ mesures
def opaque(im):
    return np.asarray(im.convert("RGBA"))[..., 3] > 127


def mesure_cycle(frames, sans_appui=(), bande=None):
    """hauteur, ligne de sol, recul du pied d'appui image par image (px), foulée = somme des reculs mesurables
    + avance moyenne pour les paires sans appui"""
    masks = [opaque(f) for f in frames]
    H, W = masks[0].shape
    sol = max(int(np.where(m.any(1))[0].max()) for m in masks) + 1          # bord inférieur des pieds
    hauts = [int(sol - np.where(m.any(1))[0].min()) for m in masks]
    bande = bande or max(4, round((max(hauts)) / 15))
    reculs = []
    for i in range(len(masks)):
        if i in sans_appui:
            reculs.append(None)
            continue
        a, b = masks[i][sol - bande:sol], masks[(i + 1) % len(masks)][sol - bande:sol]
        best = (0, -1)
        for dx in range(-45, 7):                 # un pied d appui ne peut pas avancer de plus de 6 px
            sh = np.zeros_like(a)
            if dx < 0:
                sh[:, :W + dx] = a[:, -dx:]
            else:
                sh[:, dx:] = a[:, :W - dx]
            inter = int((sh & b).sum())
            if inter > best[1]:
                best = (dx, inter)
        reculs.append(-best[0])
    vals = [r for r in reculs if r is not None]
    moyen = sum(vals) / len(vals)
    foulee = sum(vals) + moyen * (len(reculs) - len(vals))
    return {"sol_px": sol, "hauteur_px": hauts, "hauteur_min_max": [min(hauts), max(hauts)], "recul_pied_appui_px": reculs,
            "foulee_px": round(foulee), "irregularite_px": round(float(np.std(vals)), 1), "ecart_max_au_pas_moyen_px": round(max(abs(v - foulee / len(reculs)) for v in vals), 1)}


def charge(paths):
    return [Image.open(p).convert("RGBA") for p in paths]


# ------------------------------------------------------------------------------------------------ fiches
def fiche_corrections(kind, calques, mes, out_png):
    """pour chaque pose cible : calque de départ (×4), sol, torse, talon actuel (rouge) et cible (vert), consigne"""
    Z = 4
    plan = PLAN[kind]
    cw, ch = 100 * Z, 76 * Z
    font = ImageFont.truetype(FONT, 13)
    big = ImageFont.truetype(FONT, 17)
    sheet = Image.new("RGBA", (4 * (cw + 10) + 10, 2 * (ch + 120) + 60), (24, 28, 28, 255))
    d = ImageDraw.Draw(sheet)
    d.text((10, 12), "V09B.6 %s — plan des 8 poses au gabarit P4.8 (64 px), foulée cible %d px = %.2f m, %d px par image"
           % ("MARCHE" if kind == "walk" else "COURSE", plan["foulee_px"], plan["foulee_px"] * PX_M, plan["foulee_px"] // 8),
           fill=(240, 240, 230), font=big)
    sol = GABARIT["sol_rangee"]
    tx = GABARIT["torse_x"]
    x_off = tx - 50                                  # recadrage 100 px de large autour du torse
    for n, p in enumerate(plan["poses"]):
        ox = 10 + (n % 4) * (cw + 10)
        oy = 50 + (n // 4) * (ch + 120)
        cell = Image.new("RGBA", (cw, ch), (58, 66, 64, 255))
        if p["source"] is not None:
            im = calques[p["source"]].crop((x_off, sol - 76, x_off + 100, sol)).resize((cw, ch), Image.NEAREST)
            cell.alpha_composite(im)
        else:
            dc = ImageDraw.Draw(cell)
            dc.text((20, ch // 2 - 10), "POSE À DESSINER", fill=(255, 210, 120), font=big)
        dc = ImageDraw.Draw(cell)
        dc.line([(0, ch - 1), (cw, ch - 1)], fill=(255, 80, 80, 255), width=2)                    # sol
        dc.line([(50 * Z, 0), (50 * Z, ch)], fill=(255, 255, 0, 150))                              # torse
        dc.line([(0, ch - 64 * Z), (cw, ch - 64 * Z)], fill=(120, 200, 255, 160))                  # 64 px
        actuel = None
        if p["source"] is not None and p["talon"] is not None:
            # mesuré sur le 96x112 du pack (pieds nets ; torse x 52, sol 101), ramené à l'échelle 64/88
            v5 = Image.open(os.path.join(REPO, "art/tests/v09b5_aren/%s_96x112/%s_right_%d.png" % (kind, kind, p["source"])))
            t96 = talon_appui(v5, 52, 101, p["role"].startswith("contact"), rangs=3)
            actuel = None if t96 is None else round(t96 * 64 / 88)
        if p["talon"] is not None:
            x = (50 + p["talon"]) * Z
            dc.polygon([(x, ch - 1), (x - 8, ch - 16), (x + 8, ch - 16)], fill=(80, 255, 120, 255))
        if actuel is not None:
            x = (50 + actuel) * Z
            dc.polygon([(x, ch - 18), (x - 6, ch - 30), (x + 6, ch - 30)], fill=(255, 70, 70, 255))
        sheet.alpha_composite(cell, (ox, oy))
        src = "V09B.5 n°%d" % p["source"] if p["source"] is not None else "nouvelle"
        lignes = ["N%d — %s" % (n, p["role"]), "départ : %s" % src]
        if p["talon"] is not None:
            lignes.append("talon d'appui cible %+d px" % p["talon"] + ("" if actuel is None else ", actuel %+d → %+d px" % (actuel, p["talon"] - actuel)))
        else:
            lignes.append("aucun pied au sol")
        for k, t in enumerate(lignes):
            d.text((ox, oy + ch + 6 + k * 17), t, fill=(235, 235, 225), font=font)
    d.text((10, sheet.height - 26), "vert : talon du pied d'appui visé (rapport au torse, ligne jaune) · rouge : talon actuel du calque · bleu : hauteur 64 px · "
           "rouge bas : sol. Calques = réductions automatiques, à redessiner.", fill=(200, 200, 190), font=font)
    sheet.save(out_png)


def talon_appui(im, tx, sol, avant=False, rangs=2):
    """talon (bord arrière) du pied d'appui, par rapport au torse : segment opaque des 2 rangées du sol le plus large
    (pied à plat), ou le plus en avant pour un contact (talon qui se pose)"""
    m = opaque(im)
    rows = m[sol - rangs:sol].any(0)
    xs = np.where(rows)[0]
    if len(xs) == 0:
        return None
    segs = []
    start = xs[0]
    for a, b in zip(xs, xs[1:]):
        if b != a + 1:
            segs.append((start, a))
            start = b
    segs.append((start, xs[-1]))
    seg = max(segs, key=lambda s: s[1]) if avant else max(segs, key=lambda s: s[1] - s[0])
    return int(seg[0] - tx)


def fiche_gabarit(out_png, items):
    Z = 5
    font = ImageFont.truetype(FONT, 14)
    W = len(items) * 80 * Z
    sheet = Image.new("RGBA", (W, 92 * Z + 70), (24, 28, 28, 255))
    d = ImageDraw.Draw(sheet)
    for k, (titre, im, sol, tx) in enumerate(items):
        cell = Image.new("RGBA", (80, 92), (58, 66, 64, 255))
        cell.alpha_composite(im.crop((tx - 40, sol - 92, tx + 40, sol)))
        cell = cell.resize((80 * Z, 92 * Z), Image.NEAREST)
        dc = ImageDraw.Draw(cell)
        for r, col in [(0, (255, 80, 80)), (64, (120, 200, 255)), (61, (120, 200, 255, 90)), (67, (120, 200, 255, 90)), (88, (255, 160, 60))]:
            dc.line([(0, (92 - r) * Z), (80 * Z, (92 - r) * Z)], fill=col)
        sheet.alpha_composite(cell, (k * 80 * Z, 0))
        h = int(sol - np.where(opaque(im).any(1))[0].min())
        d.text((k * 80 * Z + 6, 92 * Z + 6), titre, fill=(240, 240, 230), font=font)
        d.text((k * 80 * Z + 6, 92 * Z + 26), "hauteur %d px (%.2f m)" % (h, h * PX_M), fill=(240, 240, 230), font=font)
    d.text((6, 92 * Z + 48), "bleu : 64 px (P4.8) et ±5 % (61–67 px) · orange : 88 px (V09B.5 96×112) · rouge : sol", fill=(200, 200, 190), font=font)
    sheet.save(out_png)


def gif_controle(frames, out_gif, ms, pas_px, titre):
    """boucle au gabarit (×4), défilement du sol à la foulée cible : un pied posé doit rester immobile sur le sol"""
    Z = 4
    imgs = []
    for k in range(16):
        f = frames[k % 8]
        cell = Image.new("RGBA", (128, 100), (58, 66, 64, 255))
        dc = ImageDraw.Draw(cell)
        off = (k * pas_px) % 10                       # repères tous les 10 px (non multiple du pas : ils défilent)
        for x in range(-10, 140, 10):
            dc.line([(x - off, 96), (x - off, 99)], fill=(230, 210, 120))
        dc.line([(0, 96), (128, 96)], fill=(255, 80, 80))
        cell.alpha_composite(f, (0, 0))
        big = cell.resize((128 * Z, 100 * Z), Image.NEAREST)
        ImageDraw.Draw(big).text((6, 6), "%s — image %d" % (titre, k % 8), fill=(255, 255, 255), font=ImageFont.truetype(FONT, 14))
        imgs.append(big.convert("P", palette=Image.Palette.ADAPTIVE))
    imgs[0].save(out_gif, save_all=True, append_images=imgs[1:], duration=ms, loop=0)


# ------------------------------------------------------------------------------------------------ principal
def main():
    pack = Pack(sys.argv[1])
    media = sys.argv[sys.argv.index("--sortie-media") + 1] if "--sortie-media" in sys.argv else os.path.join(REPO, "docs/media/p4_9/v09b6")
    dst = os.path.join(REPO, "art/tests/v09b6_aren/calque_64")
    os.makedirs(dst, exist_ok=True)
    os.makedirs(media, exist_ok=True)
    v5 = os.path.join(REPO, "art/tests/v09b5_aren")
    pal = palette_of([os.path.join(v5, "%s_96x112/%s_right_%d.png" % (k, k, i)) for k in ("walk", "run") for i in range(8)])
    calques = {}
    for kind in ("walk", "run"):
        calques[kind] = []
        for i in range(8):
            c = pack.calque(kind, i, pal)
            c.save(os.path.join(dst, "%s_right_%d.png" % (kind, i)), optimize=True)
            calques[kind].append(c)
    res = {"statut": "V09B.6 — mesures ; calque_64 = RÉDUCTION AUTOMATIQUE (calque d'échelle, non dessiné, non adoptable)",
           "pixel_m": PX_M, "gabarit": GABARIT, "roles_v09b5": ROLES, "plan_v09b6": PLAN, "formats": {}}
    # P4.8 (référence)
    aren = os.path.join(REPO, "art/p45/chars/aren")
    p48 = mesure_cycle(charge([os.path.join(aren, "walk_right_%d.png" % i) for i in range(8)]))
    il = mesure_cycle(charge([os.path.join(REPO, "art/p45/chars/ilya/walk_right_%d.png" % i) for i in range(8)]))
    res["reference"] = {"aren_p48_walk": p48, "ilya_p48_walk": il,
                        "aren_p48_marche_json_step_px": json.load(open(os.path.join(aren, "marche.json")))["step_px"]}
    for kind in ("walk", "run"):
        res.setdefault("v09b5_96x112", {})[kind] = mesure_cycle(charge([os.path.join(v5, "%s_96x112/%s_right_%d.png" % (kind, kind, i)) for i in range(8)]), SANS_APPUI[kind])
    fmt = {"ligne_sol_px": GABARIT["sol_rangee"], "hauteur_perso_px": GABARIT["hauteur_px"]}
    for kind in ("walk", "run"):
        m = mesure_cycle(calques[kind], SANS_APPUI[kind])
        fmt[kind] = {"foulee_px": m["foulee_px"], "recul_pied_appui_px_par_image": m["recul_pied_appui_px"], "mesures": m}
        fmt["hauteur_perso_px"] = max(fmt["hauteur_perso_px"], m["hauteur_min_max"][1])
    res["formats"]["calque_64"] = fmt
    # poses redessinées (à déposer par l'équipe artistique) : mesurées et vérifiées si elles existent
    dessin = os.path.join(REPO, "art/tests/v09b6_aren/dessin_64")
    if all(os.path.exists(os.path.join(dessin, "%s_right_%d.png" % (k, i))) for k in ("walk", "run") for i in range(8)):
        fd = {"ligne_sol_px": GABARIT["sol_rangee"], "hauteur_perso_px": GABARIT["hauteur_px"], "verification": {}}
        for kind in ("walk", "run"):
            fr = charge([os.path.join(dessin, "%s_right_%d.png" % (kind, i)) for i in range(8)])
            m = mesure_cycle(fr, SANS_APPUI_DESSIN[kind])
            fd[kind] = {"foulee_px": m["foulee_px"], "recul_pied_appui_px_par_image": m["recul_pied_appui_px"], "mesures": m}
            lo, hi = GABARIT["hauteur_px"] * 0.95, GABARIT["hauteur_px"] * 1.05
            fd["verification"][kind] = {
                "canevas_128x96": all(f.size == tuple(GABARIT["canevas"]) for f in fr),
                "pieds_sur_le_sol": m["sol_px"] == GABARIT["sol_rangee"],
                "hauteur_dans_5pc": kind == "run" or (lo <= m["hauteur_min_max"][0] and m["hauteur_min_max"][1] <= hi),
                "appuis_reguliers_2px": m["ecart_max_au_pas_moyen_px"] <= 2.0,
                "aucun_pied_qui_avance": all(r is None or r >= 0 for r in m["recul_pied_appui_px"])}
        res["formats"]["dessin_64"] = fd
    res["image_de_depart"] = 1
    with open(os.path.join(REPO, "art/tests/v09b6_aren/cadence_v09b6.json"), "w", encoding="utf-8") as f:
        json.dump(res, f, ensure_ascii=False, indent=1)
    # fiches
    for kind in ("walk", "run"):
        fiche_corrections(kind, calques[kind], fmt[kind], os.path.join(media, "fiche_corrections_%s.png" % ("marche" if kind == "walk" else "course")))
        gif_controle(calques[kind], os.path.join(media, "calque64_%s_v09b5_ordre_actuel.gif" % ("marche" if kind == "walk" else "course")),
                     110 if kind == "walk" else 80, fmt[kind]["foulee_px"] // 8, "calque 64 px, poses V09B.5 telles quelles")
    big96 = Image.open(os.path.join(v5, "walk_96x112/walk_right_1.png")).convert("RGBA")
    fiche_gabarit(os.path.join(media, "gabarit_aren_64px.png"), [
        ("Aren P4.8 (référence)", Image.open(os.path.join(aren, "idle_right.png")).convert("RGBA"), 96, 60),
        ("Ilya P4.8", Image.open(os.path.join(REPO, "art/p45/chars/ilya/idle_right.png")).convert("RGBA"), 96, 60),
        ("V09B.5 96×112 (refusé)", big96, 101, 52),
        ("calque 64 px (échelle)", calques["walk"][1], 96, 60),
    ])
    print(json.dumps({"p48": {k: p48[k] for k in ("hauteur_min_max", "recul_pied_appui_px", "foulee_px", "irregularite_px")},
                      "ilya": il["hauteur_min_max"],
                      "calque_walk": {k: fmt["walk"]["mesures"][k] for k in ("hauteur_min_max", "recul_pied_appui_px", "foulee_px", "irregularite_px")},
                      "calque_run": {k: fmt["run"]["mesures"][k] for k in ("hauteur_min_max", "recul_pied_appui_px", "foulee_px", "irregularite_px")},
                      "v5": {k: {a: v[a] for a in ("hauteur_min_max", "recul_pied_appui_px", "foulee_px")} for k, v in res["v09b5_96x112"].items()}}, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
