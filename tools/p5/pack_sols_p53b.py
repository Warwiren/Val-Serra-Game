"""Val'Serra — P5.3-B pilote : empaquetage des textures de sol peintes au format d'intégration (docs/P5_3_SOLS.md § 6).

Usage :
    python3 tools/p5/pack_sols_p53b.py <dossier ValSerra_P53B_Pilote_Sols>

Adaptation de FORMAT seulement (aucune retouche de couleur, d'échelle ni de dessin) :
  textures/SOL-0x_<nom>_1024.png (RGB) + textures/SOL-0x_<nom>_HEIGHT_PROVISOIRE_1024.png (L)
  -> art/p53/sol/<materiau>.png en RGBA : RGB = couleur telle que livrée, A = hauteur provisoire telle que livrée.
Correspondance (pilote du 21/11/2026) : SOL-01 herbe dense -> herbe_drue ; SOL-02 herbe clairsemée -> herbe_usee ;
SOL-03 chemin / terre tassée -> terre_chemin. SOL-04 (roche) et TRS-01 ne font pas partie du pilote.
Écrit aussi art/p53/sol/mesures_pack.json : moyennes, raccords, profil de luminosité près des bords, SHA-256.
"""
import hashlib, json, os, sys
import numpy as np
from PIL import Image

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DST = os.path.join(REPO, "art/p53/sol")
PILOTE = {"herbe_drue": "SOL-01_herbe_dense", "herbe_usee": "SOL-02_herbe_clairsemee", "terre_chemin": "SOL-03_chemin_terre_tassee"}


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def main():
    src = os.path.join(sys.argv[1].rstrip("/"), "textures")
    os.makedirs(DST, exist_ok=True)
    res = {"statut": "P5.3-B PILOTE — textures du créateur, hauteurs PROVISOIRES ; non validé en jeu", "tuile_m": 4.0,
           "px_par_m": 256, "materiaux": {}}
    for nom, s in PILOTE.items():
        fc = os.path.join(src, s + "_1024.png")
        fh = os.path.join(src, s + "_HEIGHT_PROVISOIRE_1024.png")
        c = Image.open(fc).convert("RGB")
        h = Image.open(fh).convert("L")
        assert c.size == (1024, 1024) and h.size == (1024, 1024), (c.size, h.size)
        out = Image.merge("RGBA", (*c.split(), h))
        p = os.path.join(DST, nom + ".png")
        out.save(p, optimize=True)
        a = np.asarray(c).astype(float)
        l = np.asarray(c.convert("L")).astype(float)
        hv = np.asarray(h).astype(float)
        bords = float(np.r_[l[:, :64].mean(), l[:, -64:].mean(), l[:64].mean(), l[-64:].mean()].mean())
        centre = float(l[256:768, 256:768].mean())
        res["materiaux"][nom] = {
            "source": s, "moyenne_srgb": [round(x, 1) for x in a.reshape(-1, 3).mean(0)],
            "hauteur_moyenne": round(hv.mean() / 255, 3), "hauteur_ecart_type": round(hv.std() / 255, 3),
            "luminosite_bords_64px": round(bords, 1), "luminosite_centre": round(centre, 1),
            "assombrissement_bords_pct": round(100 * (1 - bords / centre), 1),
            "colonne_0_egale_colonne_1023": bool(np.array_equal(a[:, 0], a[:, -1])),
            "bords_en_miroir_col1_col1022": round(float(np.abs(a[:, 1] - a[:, -2]).mean()), 2),
            "sha256_couleur": sha(fc), "sha256_hauteur": sha(fh), "sha256_rgba": sha(p)}
    with open(os.path.join(DST, "mesures_pack.json"), "w", encoding="utf-8") as f:
        json.dump(res, f, ensure_ascii=False, indent=1)
    print(json.dumps({k: {kk: v[kk] for kk in ("moyenne_srgb", "hauteur_moyenne", "hauteur_ecart_type", "assombrissement_bords_pct", "bords_en_miroir_col1_col1022")} for k, v in res["materiaux"].items()}, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
