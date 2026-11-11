"""P3-07 — Planches comparatives des variantes de caméra A/B/C (doc 07), à partir des captures des parcours
« obs6 », « obs6_zooms », « captures » (instance fictive) de scenes/explore25/camera_variante_*.tscn.
    python3 tools/explore25/planches_p307.py <dossier_captures> <dossier_sortie>
Sous-dossiers attendus : obs6/, zooms/, obs6_2d/, obs6_aucun/, instance/ (fichiers V<variante>_<paysage>_<point>_x<zoom>.png)."""
import os, sys
from PIL import Image, ImageDraw, ImageFont

SRC, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
try:
    F = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
    FS = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
except OSError:
    F = FS = ImageFont.load_default()
PTS = [("1_arbre", "1 · près de l'arbre"), ("2_pied_escalier", "2 · pied de l'escalier"), ("3_haut_escalier", "3 · haut de l'escalier"),
       ("4_derriere_maison", "4 · derrière la maison"), ("5_entree_pont", "5 · entrée du pont"), ("6_sortie", "6 · sortie (instance)")]
IPTS = [("i1_arrivee", "arrivée"), ("i2_centre", "centre"), ("i3_coin_nord_est", "coin nord-est"), ("i4_coin_sud_ouest", "coin sud-ouest")]
VAR = [("A", "A · 35°, centré"), ("B", "B · 28°, centré"), ("C", "C · 35°, héros ≈ 63 %")]
Z = [("x2", "×2"), ("x2-5", "×2,5"), ("x3", "×3")]


def load(p, w):
    im = Image.open(p).convert("RGB").crop((0, 0, 1280, 684))   # sans la ligne d'aide
    return im.resize((w, int(684 * w / 1280)), Image.LANCZOS)


def board(title, cols, rows, cell, path_of, name, cw=420):
    ch = int(684 * cw / 1280)
    lw, th = 200, 66
    img = Image.new("RGB", (lw + len(cols) * (cw + 6), th + len(rows) * (ch + 6)), (24, 26, 32))
    d = ImageDraw.Draw(img)
    d.text((12, 10), title, font=F, fill=(240, 230, 200))
    for c, (_, h) in enumerate(cols):
        d.text((lw + c * (cw + 6) + 8, 40), h, font=F, fill=(250, 220, 120))
    for r, (rid, h) in enumerate(rows):
        d.text((10, th + r * (ch + 6) + ch // 2 - 10), h, font=FS, fill=(230, 230, 230))
        for c, (cid, _) in enumerate(cols):
            p = path_of(rid, cid)
            if os.path.exists(p):
                img.paste(load(p, cw), (lw + c * (cw + 6), th + r * (ch + 6)))
            else:
                d.text((lw + c * (cw + 6) + 20, th + r * (ch + 6) + 20), "absent", font=FS, fill=(200, 80, 80))
    img.save(os.path.join(OUT, name), quality=85)
    print("écrit", name, img.size)


board("Comparaison A / B / C à ×2,5 — mêmes positions du héros, même compagnon, paysage 3D + brume (1280 × 720)", VAR, PTS, None,
      lambda r, c: os.path.join(SRC, "obs6", "V%s_3d_%s_x2-5.png" % (c, r)), "comparatif_ABC_x2-5.jpg")
for v, lab in VAR:
    board("Variante %s — six points aux trois zooms (paysage 3D + brume)" % lab, Z, PTS, None,
          lambda r, c, v=v: os.path.join(SRC, "zooms", "V%s_3d_%s_%s.png" % (v, r, c)), "zooms_%s.jpg" % v, 400)
board("Traitements du paysage non jouable — variante A, ×2,5 : 3D simplifiée + brume / plans 2D / aucun (plaque P3)",
      [("3d", "3D simplifiée + brume"), ("2d", "plans 2D illustratifs"), ("aucun", "aucun (P3)")], PTS, None,
      lambda r, c: os.path.join(SRC, {"3d": "obs6", "2d": "obs6_2d", "aucun": "obs6_aucun"}[c], "VA_%s_%s_x2-5.png" % (c, r)), "traitements_paysage_A.jpg")
for zid, zl in [("x2-5", "×2,5"), ("x2", "×2")]:
    board("Instance fictive (placette 10 × 7 m) à %s — A / B / C" % zl, VAR, IPTS, None,
          lambda r, c, zid=zid: os.path.join(SRC, "instance", "V%s_3d_%s_%s.png" % (c, r, zid)), "instance_ABC_%s.jpg" % zid)
