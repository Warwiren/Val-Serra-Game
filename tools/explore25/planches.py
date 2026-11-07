"""P3 — Planches comparatives à partir des captures du parcours « captures » / « limites » (voir docs/P3_PROTOTYPE_25D.md).
    python3 tools/explore25/planches.py <dossier_captures> <dossier_sortie>
Le dossier contient temoin/, micro/, couches/, nearest/, limites/ (A_*.png et B_*.png, 1280 × 720)."""
import os, sys
from PIL import Image, ImageDraw, ImageFont

SRC, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
try:
    F = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
    FS = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
except OSError:
    F = FS = ImageFont.load_default()
Z = [("x2", "×2"), ("x2-5", "×2,5"), ("x3", "×3")]
PTS_T = [("1_entree_A", "1 · entrée A"), ("2_place_B", "2 · place B"), ("3_escalier", "3 · escalier"), ("4_PNJ_E", "4 · PNJ (terrasse)"),
         ("5_pont_F", "5 · pont F"), ("6_derriere_arbre", "6 · derrière l'arbre"), ("7_derriere_maison", "7 · derrière la maison"), ("8_sortie_G", "8 · sortie G")]
PTS_M = [("1_entree", "1 · entrée"), ("2_place", "2 · place"), ("3_escalier", "3 · escalier"), ("4_terrasse", "4 · terrasse"), ("5_derriere_arbre", "5 · derrière l'arbre")]


def load(p, w):
    im = Image.open(p).convert("RGB")
    im = im.crop((0, 0, 1280, 684))                  # sans la ligne d'aide
    return im.resize((w, int(684 * w / 1280)), Image.LANCZOS)


def grid(rows, cols, cell_w, title, path, head_cols, head_rows):
    ch = int(684 * cell_w / 1280)
    lw, th = 190, 64
    img = Image.new("RGB", (lw + cols * (cell_w + 6), th + rows * (ch + 6)), (24, 26, 32))
    d = ImageDraw.Draw(img)
    d.text((12, 10), title, font=F, fill=(240, 230, 200))
    for c, h in enumerate(head_cols):
        d.text((lw + c * (cell_w + 6) + 8, 38), h, font=F, fill=(250, 220, 120))
    for r, h in enumerate(head_rows):
        d.text((10, th + r * (ch + 6) + ch // 2 - 10), h, font=FS, fill=(230, 230, 230))
    return img, d, lw, th, ch


def board(prefix, folder, pts, title, name, cell_w=420):
    head_rows = [p[1] for p in pts]
    img, d, lw, th, ch = grid(len(pts), 3, cell_w, title, name, [z[1] for z in Z], head_rows)
    for r, (pid, _) in enumerate(pts):
        for c, (zid, _) in enumerate(Z):
            p = os.path.join(SRC, folder, "%s_%s_%s.png" % (prefix, pid, zid))
            if os.path.exists(p):
                img.paste(load(p, cell_w), (lw + c * (cell_w + 6), th + r * (ch + 6)))
    img.save(os.path.join(OUT, name), quality=86)
    print("écrit", name, img.size)


def ab(folder, pts, zid, title, name, cell_w=560):
    img, d, lw, th, ch = grid(len(pts), 2, cell_w, title, name, ["A — Camera2D multi-hauteur", "B — Camera3D orthographique"], [p[1] for p in pts])
    for r, (pid, _) in enumerate(pts):
        for c, pre in enumerate(["A", "B"]):
            p = os.path.join(SRC, folder, "%s_%s_%s.png" % (pre, pid, zid))
            if os.path.exists(p):
                img.paste(load(p, cell_w), (lw + c * (cell_w + 6), th + r * (ch + 6)))
    img.save(os.path.join(OUT, name), quality=86)
    print("écrit", name, img.size)


def crop_cmp(name):
    """Filtre des sprites à ×2,5 : linéaire / nearest, A et B (agrandi ×2 au plus proche)."""
    tiles = []
    for pre in ["A", "B"]:
        for folder, lab in [("temoin", "linéaire"), ("nearest", "nearest")]:
            p = os.path.join(SRC, folder, "%s_5_pont_F_x2-5.png" % pre)
            if os.path.exists(p):
                im = Image.open(p).convert("RGB").crop((560, 290, 720, 400)).resize((480, 330), Image.NEAREST)
                tiles.append((im, "%s · %s" % (pre, lab)))
    img = Image.new("RGB", (4 * 486 + 6, 380), (24, 26, 32))
    d = ImageDraw.Draw(img)
    for i, (im, lab) in enumerate(tiles):
        img.paste(im, (6 + i * 486, 44))
        d.text((10 + i * 486, 12), lab, font=F, fill=(250, 220, 120))
    img.save(os.path.join(OUT, name), quality=90)
    print("écrit", name, img.size)


board("B", "temoin", PTS_T[:5], "Scène témoin — architecture B (Camera3D orthographique) — 5 points × 3 zooms, 1280 × 720", "temoin_B_5points_3zooms.jpg")
board("A", "temoin", PTS_T[:5], "Scène témoin — architecture A (Camera2D multi-hauteur, diagnostic) — 5 points × 3 zooms", "temoin_A_5points_3zooms.jpg")
ab("temoin", PTS_T, "x2-5", "Scène témoin à ×2,5 (zoom par défaut) — A et B, mêmes positions, même caméra", "temoin_A_vs_B_x2-5.jpg", 520)
ab("micro", PTS_M, "x2-5", "Micro-test commun (2 surfaces, 1 escalier, 1 occultant) à ×2,5 — A et B", "micro_A_vs_B_x2-5.jpg", 560)
board("B", "micro", PTS_M, "Micro-test — B, 3 zooms", "micro_B_3zooms.jpg", 380)
board("A", "micro", PTS_M, "Micro-test — A, 3 zooms", "micro_A_3zooms.jpg", 380)
ab("couches", PTS_T[:5], "x2", "Captures techniques : couches / collisions / niveaux (F2) à ×2 — vert niveau 0, orange niveau +1, magenta rampe, rouge solides", "couches_collisions_niveaux_x2.jpg", 560)
crop_cmp("filtre_sprites_x2-5.jpg")
# limites : 7 positions × 3 zooms (B), avec infos de débogage
lim = sorted(f for f in os.listdir(os.path.join(SRC, "limites")) if f.startswith("B_") and f.endswith(".png")) if os.path.isdir(os.path.join(SRC, "limites")) else []
if lim:
    names = []
    for f in lim:
        base = f[2:-4].rsplit("_z", 1)
        if base[0] not in names:
            names.append(base[0])
    img, d, lw, th, ch = grid(len(names), 3, 360, "Limites de caméra — B, 7 positions de bord × 3 zooms (aucun vide visible)", "", [z[1] for z in Z], [n.replace("limite_", "") for n in names])
    for r, n in enumerate(names):
        for c in range(3):
            p = os.path.join(SRC, "limites", "B_%s_z%d.png" % (n, c))
            if os.path.exists(p):
                img.paste(load(p, 360), (lw + c * 366, th + r * (ch + 6)))
    img.save(os.path.join(OUT, "limites_camera_B.jpg"), quality=84)
    print("écrit limites_camera_B.jpg", img.size)
