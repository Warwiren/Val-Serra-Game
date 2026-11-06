"""Tests de l'importeur du sol (sans toucher au dépôt : tout se passe dans un dossier temporaire).
    python3 tools/explore/test_import_sol.py
Les images de test sont des gabarits ou des aplats : ce ne sont PAS des sols illustrés."""
import os, shutil, subprocess, sys, tempfile
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SCRIPT = os.path.join(ROOT, "tools/explore/import_sol.py")
tmp = tempfile.mkdtemp()
shutil.copytree(os.path.join(ROOT, "art/source/gabarits"), os.path.join(tmp, "art/source/gabarits"))
os.makedirs(os.path.join(tmp, "art/source/sol"))
os.makedirs(os.path.join(tmp, "docs/media/gabarits_exploration/terrain"))
shutil.copy(os.path.join(ROOT, "docs/media/gabarits_exploration/terrain/chemin_trace_exact.png"), os.path.join(tmp, "docs/media/gabarits_exploration/terrain/"))
fails = []


def run(*args):
    r = subprocess.run([sys.executable, SCRIPT] + list(args), cwd=tmp, capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def check(cond, msg):
    print(("OK     " if cond else "ÉCHEC  ") + msg)
    if not cond:
        fails.append(msg)


src = os.path.join(tmp, "art/source/sol/sol_plaque.png")
out = os.path.join(tmp, "art/explore_hd2d/sol")
gab = Image.open(os.path.join(ROOT, "art/source/gabarits/terrain_sans_objets.png")).convert("RGB")

Image.new("RGB", (1280, 720), (40, 60, 40)).save(src)
code, txt = run()
check(code != 0 and "1408×800" in txt and not os.path.exists(out), "taille incorrecte refusée, rien n'est écrit")

im = gab.convert("RGBA"); a = np.asarray(im).copy(); a[:200, :200, 3] = 0
Image.fromarray(a).save(src)
code, txt = run()
check(code != 0 and "opaque" in txt, "plaque transparente refusée")

gab.resize((2816, 1600), Image.LANCZOS).save(src)
code, txt = run()
check(code == 0 and "2816×1600 -> 1408×800" in txt, "plaque ×2 acceptée et réduite une fois")
check(Image.open(os.path.join(out, "sol.png")).size == (1408, 800), "sol importé en 1408×800 (calques fusionnés)")
check("décalage estimé (0, 0)" in txt, "plaque recalée détectée au bon endroit")
check("existant" in open(os.path.join(out, "sol.json")).read(), "sans ombres ni lumières fournies : calques actuels conservés")
f = np.asarray(Image.open(os.path.join(out, "sol.png")).convert("L")).astype(int)
g = np.asarray(gab.convert("L")).astype(int)
check(f.mean() != g.mean() and np.abs(f - g).max() > 40, "ombres et lumières actuelles appliquées sur la plaque")
code, txt = run("--calques-separes")
for n in ("sol_plaque", "sol_ombres", "sol_lumieres"):
    check(os.path.exists(os.path.join(out, n + ".png")), "--calques-separes : " + n + " présent")
o = np.asarray(Image.open(os.path.join(out, "sol_ombres.png")))
check(o[..., 3].max() > 100 and (o[..., 3] > 0).mean() < 0.6, "ombres actuelles : calque transparent non vide")

shifted = Image.new("RGB", (1408, 800)); shifted.paste(gab, (24, 0))
shifted.save(src)
code, txt = run("--verifier")
check("ATTENTION" in txt and "chemin décalé" in txt, "plaque décalée de 24 px signalée (chemin)")

Image.new("RGBA", (1408, 800), (0, 0, 0, 0)).save(os.path.join(tmp, "art/source/sol/sol_ombres.png"))
gab.save(src)
code, txt = run()
check(code == 0 and '"sol_ombres": {\n   "origine": "fourni"' in open(os.path.join(out, "sol.json")).read(), "ombres fournies : utilisées à la place des actuelles")

code, txt = run("--sans-lumieres", "--calques-separes")
check(code == 0 and not os.path.exists(os.path.join(out, "sol_lumieres.png")), "--sans-lumieres : pas de calque de lumière (déjà peinte)")
code, txt = run("--retirer")
check(code == 0 and not os.path.exists(out), "retrait : le jeu revient au fond actuel")
shutil.rmtree(tmp)
print("IMPORTEUR DU SOL : %s (%d échec)" % ("RÉUSSI" if not fails else "ÉCHEC", len(fails)))
sys.exit(1 if fails else 0)
