"""Val'Serra V09C — vérification d'un pack de sprites ou de portraits AVANT intégration (aucun fichier n'est modifié).

Usage :
    python3 tools/p49/verif_pack_v09c.py <dossier du pack> [--ref-hauteur 64] [--sans-appui-course 2,3,6,7] [--json sortie.json]

Cherche dans le dossier (sous-dossiers compris) les images de cycle nommées <cycle>_<direction>_<n>.png, avec
cycle = walk|run|idle (ou marche|course|attente) et direction = right|left|face|back (ou droite|gauche|face|dos),
n = 0..7 (00..07 accepté), ainsi que les portraits <expression>.png dans un dossier « portraits ».

Pour chaque cycle : nombre d'images et numérotation, taille de canevas identique, transparence nette (alpha 0 ou
255, pas de halo), ligne de sol commune, hauteur visible (min / médiane / max), FACTEUR D'AFFICHAGE qui donne la
hauteur de référence (Aren V09B.5 à ×0,719 = 64 px), recul du pied d'appui image par image, foulée mesurée,
images en double. Pour les portraits : les 7 expressions attendues, format carré, tailles identiques.

Les mesures de foulée supposent un cycle « sur place » (bassin aligné horizontalement d'une image à l'autre),
comme le pack V09B.5 d'Aren. Les paires sans pied d'appui commun (envol, appel) sont à signaler par
--sans-appui-course (indices i de la paire i -> i+1) ; elles sont alors exclues de la mesure.
"""
import json, os, re, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from v09b6_gabarit import mesure_cycle, opaque  # noqa: E402  (mêmes mesures que V09B.5 / V09B.6)

CYCLES = {"walk": "walk", "marche": "walk", "run": "run", "course": "run", "idle": "idle", "attente": "idle"}
DIRS = {"right": "right", "droite": "right", "left": "left", "gauche": "left", "face": "face", "back": "back", "dos": "back"}
PORTRAITS = ["neutre", "determinee", "sereine", "surprise", "inquiete", "resolue", "blessee"]
REF_H = 64            # hauteur affichée d'Aren V09B.5 (88-91 px × 0,719) et d'Aren P4.8
PX_M_JEU = 0.02       # 1 px affiché = 0,02 m (1 px d'écran au zoom ×2,5)


def trouve(root):
    rx = re.compile(r"^(?P<c>[a-z]+)[_-](?P<d>[a-z]+)[_-]0*(?P<n>\d+)(?:_preview)?\.png$", re.I)
    cycles, portraits, autres = {}, {}, []
    for dp, _, fs in os.walk(root):
        for f in sorted(fs):
            if not f.lower().endswith(".png"):
                continue
            p = os.path.join(dp, f)
            m = rx.match(f)
            if m and m["c"].lower() in CYCLES and m["d"].lower() in DIRS:
                key = (CYCLES[m["c"].lower()], DIRS[m["d"].lower()], os.path.relpath(dp, root))
                cycles.setdefault(key, {})[int(m["n"])] = p
            elif "portrait" in dp.lower():
                portraits[os.path.splitext(f)[0].lower()] = p
            else:
                autres.append(os.path.relpath(p, root))
    return cycles, portraits, autres


def alpha_net(im):
    a = np.asarray(im.convert("RGBA"))[..., 3]
    inter = int(((a > 0) & (a < 255)).sum())
    return inter, int((a > 0).sum())


def doublons(frames, seuil=75):
    """paires consécutives dont la silhouette des jambes (tiers inférieur, masque alpha) se recouvre à plus de
    `seuil` % : pose probablement doublée (V09B.5 : envol 3/4 de la course, 80 %). Les couleurs ne servent pas :
    sur des poses générées, elles changent de toute façon d'une image à l'autre."""
    out = []
    ms = [opaque(f) for f in frames]
    for i in range(len(ms)):
        j = (i + 1) % len(ms)
        h = ms[i].shape[0]
        a, b = ms[i][h * 5 // 8:], ms[j][h * 5 // 8:]
        iou = 100 * float((a & b).sum()) / max(1, int((a | b).sum()))
        if iou >= seuil:
            out.append({"images": [i, j], "recouvrement_jambes_pc": round(iou)})
    return out


def verifie_cycle(kind, paths, sans_appui):
    idx = sorted(paths)
    r = {"images": len(idx), "numerotation_continue": idx == list(range(len(idx))), "alertes": []}
    if not r["numerotation_continue"]:
        r["alertes"].append("numérotation non continue : %s" % idx)
    frames = [Image.open(paths[i]) for i in idx]
    tailles = sorted({f.size for f in frames})
    r["canevas"] = [list(t) for t in tailles]
    if len(tailles) > 1:
        r["alertes"].append("canevas différents dans le cycle")
    modes = sorted({f.mode for f in frames})
    if modes != ["RGBA"]:
        r["alertes"].append("mode %s (RGBA attendu)" % modes)
    inter = [alpha_net(f) for f in frames]
    r["pixels_semi_transparents"] = [i for i, _ in inter]
    if any(i > 0 for i, _ in inter):
        r["alertes"].append("alpha non binaire (halo possible au filtrage au plus proche)")
    if len(tailles) > 1 or not frames:
        return r
    m = mesure_cycle(frames, sans_appui if kind == "run" else ())
    hs = sorted(m["hauteur_px"])
    med = hs[len(hs) // 2]
    r.update({"ligne_sol_px": m["sol_px"], "hauteur_px": m["hauteur_px"], "hauteur_mediane_px": med,
              "facteur_affichage_pour_%dpx" % REF_H: round(REF_H / med, 3),
              "hauteur_affichee_px": [round(h * REF_H / med, 1) for h in m["hauteur_px"]]})
    bas = [int(np.where(opaque(f).any(1))[0].max()) + 1 for f in frames]
    r["bas_des_pieds_par_image"] = bas
    if kind != "idle":
        r["recul_pied_appui_px"] = m["recul_pied_appui_px"]
        r["foulee_px"] = m["foulee_px"]
        r["foulee_m_en_jeu"] = round(m["foulee_px"] * PX_M_JEU * REF_H / med, 2)
        r["ecart_max_au_pas_moyen_px"] = m["ecart_max_au_pas_moyen_px"]
        if any(x is not None and x < -2 for x in m["recul_pied_appui_px"]):
            r["alertes"].append("pied d'appui qui avance (recul négatif)")
    else:
        if max(bas) - min(bas) > 0:
            r["alertes"].append("attente : les pieds bougent verticalement (%d à %d)" % (min(bas), max(bas)))
    d = doublons(frames)
    if d:
        r["images_presque_identiques"] = d
        r["alertes"].append("images consécutives presque identiques : %s" % [x["images"] for x in d])
    return r


def verifie_portraits(portraits):
    r = {"trouves": sorted(portraits), "manquants": [p for p in PORTRAITS if p not in portraits], "alertes": []}
    tailles = {}
    for k, p in portraits.items():
        im = Image.open(p)
        tailles[k] = list(im.size)
        if im.size[0] != im.size[1]:
            r["alertes"].append("%s : non carré %s" % (k, im.size))
    r["tailles"] = tailles
    if len({tuple(t) for t in tailles.values()}) > 1:
        r["alertes"].append("tailles différentes entre portraits")
    if r["manquants"]:
        r["alertes"].append("expressions manquantes : %s" % r["manquants"])
    return r


def main():
    root = sys.argv[1]
    sans = [2, 3, 6, 7]
    if "--sans-appui-course" in sys.argv:
        sans = [int(x) for x in sys.argv[sys.argv.index("--sans-appui-course") + 1].split(",") if x != ""]
    global REF_H
    if "--ref-hauteur" in sys.argv:
        REF_H = int(sys.argv[sys.argv.index("--ref-hauteur") + 1])
    cycles, portraits, autres = trouve(root)
    res = {"pack": os.path.abspath(root), "hauteur_de_reference_px": REF_H, "cycles": {}, "non_reconnus": autres}
    for (kind, d, sub), paths in sorted(cycles.items()):
        res["cycles"]["%s_%s (%s)" % (kind, d, sub)] = verifie_cycle(kind, paths, sans)
    if portraits:
        res["portraits"] = verifie_portraits(portraits)
    besoins = []
    vus = {(k, d) for (k, d, _) in cycles}
    for k in ("walk", "run"):
        if (k, "right") not in vus:
            besoins.append("cycle %s_right absent" % k)
    if ("idle", "right") not in vus:
        besoins.append("pas d'attente au profil droit : l'arrêt repasserait sur l'ancienne Ilya P4.8")
    if not any(d == "left" for (_, d) in vus):
        besoins.append("pas de profil gauche : demi-tour = ancienne Ilya P4.8 (ou miroir, à autoriser)")
    res["besoins"] = besoins
    txt = json.dumps(res, ensure_ascii=False, indent=1)
    if "--json" in sys.argv:
        with open(sys.argv[sys.argv.index("--json") + 1], "w", encoding="utf-8") as f:
            f.write(txt)
    print(txt)
    alertes = sum(len(c.get("alertes", [])) for c in res["cycles"].values()) + len(res.get("portraits", {}).get("alertes", []))
    print("\n%d cycle(s), %d alerte(s), %d besoin(s)" % (len(res["cycles"]), alertes, len(besoins)), file=sys.stderr)


if __name__ == "__main__":
    main()
