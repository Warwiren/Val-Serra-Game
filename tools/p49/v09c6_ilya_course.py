"""Val'Serra V09C.6 — Ilya : import de la course de profil droit et des portraits au cadrage serré (banc d'essai).

Usage :
    python3 tools/p49/v09c6_ilya_course.py <dossier ValSerra_V09C6_Ilya_Course_Droite_CANDIDAT>

Produit art/tests/v09c6_ilya/ (le banc V09C.5 art/tests/v09c_ilya/ et les ressources P4.8 ne sont pas touchés) :
  - exploration/right/run_right_{0..7}.png : COPIES SANS RETOUCHE des 8 poses V09C.6 (déjà au canevas 96 × 112,
    alpha net, cycle sur place : centre de la tête entre x = 60 et 62 ; aucun recalage, aucun nettoyage) ;
  - portraits_160/{v09c5,serre}/<expression>.png : les 7 portraits V09C.5 (512 px) et les 7 portraits V09C.6 au
    cadrage serré (512 px), réduits à 160 × 160 (Lanczos) pour l'interface, comme les portraits P4.x (« carré,
    160 px au plus ») : l'interface affiche en filtrage linéaire sans mipmaps, un 512 px dans un cadre de 34 à 140 px
    scintillerait. Les originaux 512 px restent sur le Drive (V09C.5 : aussi dans art/tests/v09c_ilya/portraits/) ;
  - cadence_v09c6.json : mesures de la course (ligne de sol, hauteurs, recul du pied d'appui, foulée), SHA-256.
"""
import hashlib, json, os, shutil, sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from v09b6_gabarit import mesure_cycle  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DST = os.path.join(REPO, "art/tests/v09c6_ilya")
EXPR = ["neutre", "determinee", "sereine", "surprise", "inquiete", "resolue", "blessee"]
# rôles (QA_V09C6.json) : 0 contact A, 1 amorti A, 2 propulsion A, 3 envol A->B, 4 contact B, 5 amorti B,
# 6 propulsion B, 7 envol B->A. Paires sans pied d'appui commun : 2->3, 3->4 (envol), 6->7, 7->0.
SANS_APPUI = [2, 3, 6, 7]


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def main():
    pack = sys.argv[1].rstrip("/")
    qa = json.load(open(os.path.join(pack, "QA_V09C6.json"), encoding="utf-8"))
    os.makedirs(os.path.join(DST, "exploration/right"), exist_ok=True)
    frames = []
    for i in range(8):
        src = os.path.join(pack, "exploration/right/run_right_%d.png" % i)
        dst = os.path.join(DST, "exploration/right/run_right_%d.png" % i)
        shutil.copyfile(src, dst)
        im = Image.open(dst)
        a = im.getchannel("A")
        assert im.size == (96, 112) and im.mode == "RGBA", (dst, im.size, im.mode)
        assert set(a.getdata()) <= {0, 255}, "alpha non binaire : " + dst
        frames.append(im)
    m = mesure_cycle(frames, SANS_APPUI)
    res = {"statut": "V09C.6 — course droite d'Ilya, BANC D'ESSAI NON VALIDÉ (copie sans retouche du pack V09C.6)",
           "run_right": {"ligne_sol_px": m["sol_px"], "hauteur_px": m["hauteur_px"],
                         "recul_pied_appui_px_par_image": m["recul_pied_appui_px"], "foulee_px": m["foulee_px"],
                         "phases": [f["phase"] for f in qa["frames"]], "images_envol": qa["airborne_frames"],
                         "bas_des_pieds_par_image": [int(f["bottom_alpha_pixel_y"]) for f in qa["frames"]]},
           "qa_pack": {k: qa[k] for k in ("uniform_scale_for_all_poses", "airborne_frames", "ground_line_y", "known_limitations")},
           "sha256": {}}
    for var, src_dir in (("v09c5", os.path.join(REPO, "art/tests/v09c_ilya/portraits")),
                         ("serre", os.path.join(pack, "portraits_cadrage_serre_CANDIDATS"))):
        d = os.path.join(DST, "portraits_160", var)
        os.makedirs(d, exist_ok=True)
        for e in EXPR:
            src = os.path.join(src_dir, e + ".png")
            res["sha256"]["source_%s/%s.png" % (var, e)] = sha(src)
            Image.open(src).convert("RGBA").resize((160, 160), Image.LANCZOS).save(os.path.join(d, e + ".png"), optimize=True)
    for root, _, fs in os.walk(DST):
        for f in sorted(fs):
            if f.endswith(".png"):
                p = os.path.join(root, f)
                res["sha256"][os.path.relpath(p, DST)] = sha(p)
    with open(os.path.join(DST, "cadence_v09c6.json"), "w", encoding="utf-8") as f:
        json.dump(res, f, ensure_ascii=False, indent=1)
    print(json.dumps(res["run_right"], ensure_ascii=False))


if __name__ == "__main__":
    main()
