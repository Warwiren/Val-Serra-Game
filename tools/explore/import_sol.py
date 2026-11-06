"""IMPORTEUR DU SOL ILLUSTRÉ de l'exploration (calques recalés sur le gabarit 1408×800).

    python3 tools/explore/import_sol.py            importe art/source/sol/ -> art/explore_hd2d/sol/
    python3 tools/explore/import_sol.py --retirer  retire le sol importé (le jeu revient au fond actuel)
    python3 tools/explore/import_sol.py --verifier contrôle les fichiers déposés sans rien écrire
    options : --sans-ombres / --sans-lumieres  (si la plaque contient déjà ombres ou lumière des lanternes)

Fichiers à déposer dans art/source/sol/ (dossier ignoré par Godot, sources conservées telles quelles) :
  sol_plaque.png    OBLIGATOIRE. Terrain illustré, opaque, 1408×800 (ou 2816×1600 : réduit UNE fois, Lanczos).
  sol_ombres.png    facultatif. Ombres des objets, RGBA transparent. Absent : ombres actuelles conservées.
  sol_lumieres.png  facultatif. Lumière des lanternes et fenêtres, sur fond noir (ajoutée). Absent : actuelle.
Contrôles : taille, opacité, recalage sur le gabarit (décalage détecté), cohérence des calques.
Sortie (utilisée par le jeu) : art/explore_hd2d/sol/sol.png (calques fusionnés) + sol.json ; avec
--calques-separes : sol_plaque.png, sol_ombres.png, sol_lumieres.png affichés l'un sur l'autre (réglages en direct).
Le jeu affiche ces calques 1:1 à l'écran (échelle 0,5 du monde), sans pixellisation. Les collisions, le
praticable et le tri viennent toujours de zone.json : l'illustration ne change aucune mécanique."""
import hashlib, json, os, shutil, sys, time
import numpy as np
from PIL import Image, ImageFilter

SRC = "art/source/sol"
REF = "art/source/gabarits"
OUT = "art/explore_hd2d/sol"
W, H = 1408, 800


def fail(msg):
    print("REFUSÉ :", msg)
    sys.exit(1)


def load(name, opaque=False):
    p = os.path.join(SRC, name)
    if not os.path.exists(p):
        return None
    im = Image.open(p)
    im.load()
    if im.size == (W * 2, H * 2):
        print("  %s : 2816×1600 -> 1408×800 (Lanczos, une seule réduction)" % name)
        im = im.convert("RGBA").resize((W, H), Image.LANCZOS)
    elif im.size != (W, H):
        fail("%s mesure %d×%d : attendu 1408×800 ou 2816×1600 (gabarit docs/media/gabarits_exploration/)" % ((name,) + im.size))
    im = im.convert("RGBA")
    if opaque:
        a = np.asarray(im)[..., 3]
        if (a < 250).mean() > 0.001:
            fail("%s doit être opaque (%.1f %% de pixels transparents)" % (name, 100 * (a < 250).mean()))
    return im


def existing_shadows():
    """Ombres portées actuelles des objets : rapport entre le rendu avec et sans ombres (même scène Blender)."""
    # filtre médian : supprime le bruit de rendu entre les deux images (sinon un voile d'ombre partout)
    a = np.asarray(Image.open(os.path.join(REF, "terrain_ombres_objets.png")).convert("L").filter(ImageFilter.MedianFilter(5))).astype(np.float32) + 1
    b = np.asarray(Image.open(os.path.join(REF, "terrain_sans_objets.png")).convert("L").filter(ImageFilter.MedianFilter(5))).astype(np.float32) + 1
    s = np.clip(1 - a / b, 0, 1)
    s[s < 0.10] = 0
    rgba = np.dstack([np.full_like(s, 20), np.full_like(s, 18), np.full_like(s, 42), s * 235])
    return Image.fromarray(rgba.astype(np.uint8), "RGBA")


def existing_lights():
    """Lumière actuelle des lanternes et fenêtres : rendu allumé moins rendu éteint, débruité."""
    a = np.asarray(Image.open(os.path.join(REF, "terrain_sans_objets.png")).convert("RGB")).astype(np.float32)
    b = np.asarray(Image.open(os.path.join(REF, "terrain_sans_lumieres.png")).convert("RGB")).astype(np.float32)
    d = np.clip(a - b, 0, 255)
    d = np.asarray(Image.fromarray(d.astype(np.uint8)).filter(ImageFilter.GaussianBlur(2.0))).astype(np.float32)
    d[d.max(-1) < 4] = 0
    return Image.fromarray(np.dstack([d, np.full(d.shape[:2], 255.0)]).astype(np.uint8), "RGBA")


def alignment(plaque):
    """Décalage (px écran) qui superpose le mieux les contours de la plaque à ceux du gabarit."""
    def edges(im):
        g = im.convert("L").resize((W // 4, H // 4), Image.LANCZOS).filter(ImageFilter.FIND_EDGES)
        e = np.asarray(g).astype(np.float32)
        return (e - e.mean()) / (e.std() + 1e-6)
    a = edges(Image.open(os.path.join(REF, "terrain_sans_objets.png"))); b = edges(plaque)
    best = (-9, 0, 0)
    for dy in range(-6, 7):
        for dx in range(-6, 7):
            sa = a[max(0, dy):a.shape[0] + min(0, dy), max(0, dx):a.shape[1] + min(0, dx)]
            sb = b[max(0, -dy):b.shape[0] + min(0, -dy), max(0, -dx):b.shape[1] + min(0, -dx)]
            c = float((sa * sb).mean())
            if c > best[0]:
                best = (c, dx * 4, dy * 4)
    return best


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()[:16]


if "--retirer" in sys.argv:
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    print("sol importé retiré : le jeu utilise de nouveau art/explore_hd2d/fond.png")
    sys.exit(0)

print("Importation du sol depuis", SRC)
plaque = load("sol_plaque.png", opaque=True)
if plaque is None:
    fail("art/source/sol/sol_plaque.png manquant")
ombres = load("sol_ombres.png")
lumieres = load("sol_lumieres.png")
c, dx, dy = alignment(plaque)
print("  recalage sur le gabarit : décalage estimé (%d, %d) px, corrélation des contours %.2f" % (dx, dy, c))
if abs(dx) > 4 or abs(dy) > 4:
    print("  ATTENTION : la plaque semble décalée par rapport au gabarit : chemins et collisions ne coïncideront pas")
if c < 0.15:
    print("  ATTENTION : faible ressemblance avec le gabarit (chemin, lisière) : vérifier le cadrage")
if "--verifier" in sys.argv:
    sys.exit(0)
os.makedirs(OUT, exist_ok=True)
info = {"cadre": [W, H], "importe_le": time.strftime("%Y-%m-%d %H:%M"), "recalage": {"decalage_px": [dx, dy], "correlation": round(c, 3)}, "calques": {}}
plaque.convert("RGB").save(os.path.join(OUT, "sol_plaque.png"))
info["calques"]["sol_plaque"] = {"origine": "fourni", "source_sha256": sha(os.path.join(SRC, "sol_plaque.png"))}
for name, im, default in (("sol_ombres", ombres, existing_shadows), ("sol_lumieres", lumieres, existing_lights)):
    flag = "--sans-" + name.split("_")[1]                    # --sans-ombres / --sans-lumieres : calque absent
    if flag in sys.argv:                                      # (ex. lumière déjà peinte dans la plaque)
        if os.path.exists(os.path.join(OUT, name + ".png")):
            os.remove(os.path.join(OUT, name + ".png"))
        info["calques"][name] = {"origine": "aucun (%s)" % flag}
        continue
    if im is None:
        im = default(); origin = "existant (rendu de la scène actuelle)"
    else:
        origin = "fourni"
        if name == "sol_lumieres":                          # lumière ajoutée : on travaille en RVB prémultiplié
            a = np.asarray(im).astype(np.float32)
            rgb = a[..., :3] * a[..., 3:4] / 255.0
            im = Image.fromarray(np.dstack([rgb, np.full(rgb.shape[:2], 255.0)]).astype(np.uint8), "RGBA")
    im.save(os.path.join(OUT, name + ".png"))
    info["calques"][name] = {"origine": origin}
# Par défaut, les calques sont FUSIONNÉS en une seule texture pour le jeu (une seule image plein écran à dessiner :
# moins de mémoire et de surdessin). Les sources restent séparées : retoucher un calque = relancer l'import.
if "--calques-separes" not in sys.argv:
    base = np.asarray(Image.open(os.path.join(OUT, "sol_plaque.png")).convert("RGB")).astype(np.float32)
    p_o = os.path.join(OUT, "sol_ombres.png"); p_l = os.path.join(OUT, "sol_lumieres.png")
    if os.path.exists(p_o):
        o = np.asarray(Image.open(p_o).convert("RGBA")).astype(np.float32)
        base = base * (1 - o[..., 3:4] / 255.0) + o[..., :3] * (o[..., 3:4] / 255.0)
    if os.path.exists(p_l):
        base = base + np.asarray(Image.open(p_l).convert("RGB")).astype(np.float32)
    Image.fromarray(np.clip(base, 0, 255).astype(np.uint8)).save(os.path.join(OUT, "sol.png"))
    for n in ("sol_plaque", "sol_ombres", "sol_lumieres"):
        if os.path.exists(os.path.join(OUT, n + ".png")):
            os.remove(os.path.join(OUT, n + ".png"))
    info["fusion"] = "sol.png = plaque + ombres + lumières (une texture)"
else:
    info["fusion"] = "calques séparés dans le jeu (--calques-separes)"
json.dump(info, open(os.path.join(OUT, "sol.json"), "w"), indent=1, ensure_ascii=False)
for k, v in info["calques"].items():
    print("  %-13s %s" % (k, v["origine"]))
print("sol importé dans", OUT, "— lancer Godot (F5) ; comparaison : godot --path . -- --sol=ancien")
