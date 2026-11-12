#!/usr/bin/env python3
"""P4.1 — planches comparatives (avant/après, caméras A/B) à partir des captures des parcours p4_vues.
  python3 tools/p41/planches_p41.py <captures P4> <captures B28> <captures P30> <captures P38> [<combat avant> <combat après>]"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

P4, B28, P30, P38 = sys.argv[1:5]
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
O = os.path.join(ROOT, "docs", "media", "p4_1") + "/"
F = ImageFont.truetype(os.path.join(ROOT, "art", "fonts", "Inter-SemiBold.otf"), 15)
CAMS = {"B28": B28, "P30": P30, "P38": P38}


def lab(d, x, y, s):
    w = d.textlength(s, font=F)
    d.rectangle([x, y, x + w + 12, y + 22], fill=(10, 10, 16))
    d.text((x + 6, y + 2), s, fill=(240, 230, 200), font=F)


def cap(dir_, v, z):
    return Image.open(os.path.join(dir_, "P4_%s_x%s.png" % (v, z))).convert("RGB")


views = ["cour", "escalier", "terrasse", "porte_pont", "pont", "plaine", "derriere_arbre", "derriere_tour", "interieur", "interieur_atre"]
os.makedirs(O + "captures", exist_ok=True)
os.makedirs(O + "camera", exist_ok=True)
for c, dir_ in CAMS.items():
    for v in views:
        for z in ["2", "2-5", "3"]:
            cap(dir_, v, z).save(O + ("captures/" if c == "B28" else "camera/%s_" % c) + "%s_x%s.jpg" % (v, z), quality=88)
names = {"B28": "B28 — orthographique 28° (validée, défaut)", "P30": "P30 — perspective 30°, champ 30°", "P38": "P38 — perspective 38°, champ 22°"}
for v in views[:8]:
    for z in ["2", "2-5", "3"]:
        cv = Image.new("RGB", (1940, 392), (18, 18, 26)); d = ImageDraw.Draw(cv)
        for i, c in enumerate(CAMS):
            cv.paste(cap(CAMS[c], v, z).resize((640, 360), Image.LANCZOS), (i * 650, 30))
            lab(d, i * 650, 4, "%s · %s · ×%s" % (names[c], v, z.replace("-", ",")))
        cv.save(O + "camera/AB_%s_x%s.jpg" % (v, z), quality=86)
for v in ["plaine", "derriere_arbre", "cour", "pont", "porte_pont", "escalier", "terrasse", "derriere_tour"]:
    for z in ["2", "2-5", "3"]:
        cv = Image.new("RGB", (1290, 392), (18, 18, 26)); d = ImageDraw.Draw(cv)
        cv.paste(cap(P4, v, z).resize((640, 360), Image.LANCZOS), (0, 30))
        cv.paste(cap(B28, v, z).resize((640, 360), Image.LANCZOS), (650, 30))
        lab(d, 0, 4, "AVANT (P4) · %s · ×%s" % (v, z.replace("-", ","))); lab(d, 650, 4, "APRÈS (P4.1) · même position, même caméra")
        cv.save(O + "avant_apres_%s_x%s.jpg" % (v, z), quality=86)
for v, box in [("plaine", (470, 230, 830, 450)), ("cour", (470, 230, 830, 450))]:
    a = cap(P4, v, "3").crop(box); b = cap(B28, v, "3").crop(box)
    w, h = a.size
    cv = Image.new("RGB", (w * 4 + 20, h * 2 + 30), (18, 18, 26)); d = ImageDraw.Draw(cv)
    cv.paste(a.resize((w * 2, h * 2), Image.NEAREST), (0, 30)); cv.paste(b.resize((w * 2, h * 2), Image.NEAREST), (w * 2 + 20, 30))
    lab(d, 0, 4, "AVANT (P4) · zoom ×3, détail agrandi ×2 sans filtre"); lab(d, w * 2 + 20, 4, "APRÈS (P4.1) · même cadre")
    cv.save(O + "personnages_avant_apres_%s.png" % v)
if len(sys.argv) > 6:
    a = Image.open(sys.argv[5]).convert("RGB"); b = Image.open(sys.argv[6]).convert("RGB")
    cv = Image.new("RGB", (1290, 392), (18, 18, 26)); d = ImageDraw.Draw(cv)
    cv.paste(a.resize((640, 360), Image.LANCZOS), (0, 30)); cv.paste(b.resize((640, 360), Image.LANCZOS), (650, 30))
    lab(d, 0, 4, "AVANT (P4) · combat"); lab(d, 650, 4, "APRÈS (P4.1) · nouveaux sprites, PV ÷ 2")
    cv.save(O + "combat_avant_apres.jpg", quality=88)
    box = (820, 330, 1230, 520)
    a2 = a.crop(box); b2 = b.crop(box); w, h = a2.size
    cv = Image.new("RGB", (w * 4 + 20, h * 2 + 30), (18, 18, 26)); d = ImageDraw.Draw(cv)
    cv.paste(a2.resize((w * 2, h * 2), Image.NEAREST), (0, 30)); cv.paste(b2.resize((w * 2, h * 2), Image.NEAREST), (w * 2 + 20, 30))
    lab(d, 0, 4, "AVANT (P4) · groupe en combat, agrandi ×2"); lab(d, w * 2 + 20, 4, "APRÈS (P4.1)")
    cv.save(O + "combat_personnages_avant_apres.png")
print("planches : ok")
