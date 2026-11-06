"""Inventaire du poids du projet et des textures (rapport docs/PERFORMANCES.md).
    python3 tools/perf/inventaire.py [sortie.json]
- taille par dossier (hors .git et .godot) ;
- textures chargeables par le jeu (hors dossiers .gdignore) : dimensions, octets, mode d'import, mémoire
  graphique estimée (RGBA 8 bits sans compression, mipmaps compris si activés) ;
- doublons exacts (même contenu) et textures plus grandes que l'écran."""
import hashlib, json, os, sys
from collections import defaultdict
from PIL import Image

ROOT = "."
skip = {".git", ".godot", "build"}
ignored = set()
for d, dirs, files in os.walk(ROOT):
    dirs[:] = [x for x in dirs if x not in skip]
    if ".gdignore" in files:
        ignored.add(os.path.normpath(d))
sizes = defaultdict(int)
tex = []
hashes = defaultdict(list)
for d, dirs, files in os.walk(ROOT):
    dirs[:] = [x for x in dirs if x not in skip]
    nd = os.path.normpath(d)
    top = nd.split(os.sep)[0] if nd != "." else "."
    sub = os.sep.join(nd.split(os.sep)[:2])
    game = not any(nd == g or nd.startswith(g + os.sep) for g in ignored)
    for f in files:
        p = os.path.join(d, f)
        b = os.path.getsize(p)
        sizes[sub if top in ("art", "docs") else top] += b
        if game and f.lower().endswith((".png", ".jpg", ".webp", ".svg")):
            imp = {}
            if os.path.exists(p + ".import"):
                for line in open(p + ".import", encoding="utf-8"):
                    if "=" in line and line.split("=")[0] in ("compress/mode", "mipmaps/generate", "process/fix_alpha_border"):
                        imp[line.split("=")[0]] = line.split("=")[1].strip()
            w = h = 0
            if not f.endswith(".svg"):
                with Image.open(p) as im:
                    w, h = im.size
            mip = imp.get("mipmaps/generate") == "true"
            vram = w * h * 4 * (4 / 3 if mip else 1)
            tex.append({"fichier": os.path.normpath(p), "dims": [w, h], "octets": b, "vram_estimee_mo": round(vram / 1048576, 2), "import": imp})
            hashes[hashlib.md5(open(p, "rb").read()).hexdigest()].append(os.path.normpath(p))
tex.sort(key=lambda t: -t["vram_estimee_mo"])
dups = [v for v in hashes.values() if len(v) > 1]
rep = {
    "taille_par_dossier_mo": {k: round(v / 1048576, 2) for k, v in sorted(sizes.items(), key=lambda kv: -kv[1])},
    "textures_du_jeu": {"nombre": len(tex), "octets_disque_mo": round(sum(t["octets"] for t in tex) / 1048576, 2),
                        "vram_si_tout_charge_mo": round(sum(t["vram_estimee_mo"] for t in tex), 1)},
    "plus_lourdes": tex[:15],
    "plus_grandes_que_l_ecran": [t["fichier"] for t in tex if t["dims"][0] > 1300 or t["dims"][1] > 740],
    "doublons": dups,
    "modes_import": dict(sorted(defaultdict(int, {m: sum(1 for t in tex if t["import"].get("compress/mode") == m) for m in {t["import"].get("compress/mode") for t in tex}}).items(), key=lambda kv: str(kv[0]))),
}
out = sys.argv[1] if len(sys.argv) > 1 else None
s = json.dumps(rep, indent=1, ensure_ascii=False)
if out:
    open(out, "w").write(s)
print(s[:3000])
