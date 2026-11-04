"""Génère le Chasseur « HD » articulé : un fichier SVG par segment, TOUS sur le même canevas
(comme les calques d'un PSD), + la fiche de squelette data/rig/hero_hd.json (pivots, parents, ordre).
Usage : python3 tools/art/gen_hero_hd.py   (depuis la racine du projet)

C'est exactement la structure qu'un illustrateur (ou une IA + retouche) devra livrer pour remplacer
ces calques par une peinture finale : même canevas 400×420, mêmes pivots, mêmes noms de fichiers."""
import json, math, os

W, H = 400, 420
OUT = "art/hd/hero"
os.makedirs(OUT, exist_ok=True)
INK = "#15111a"
SW = 2.6

# Palette
SKIN, SKIN_S, SKIN_H = "#f2c9a8", "#d39a78", "#ffe2cc"
HAIR, HAIR_S, HAIR_H = "#3b2a22", "#24170f", "#7a5338"
COAT, COAT_S, COAT_H = "#33598e", "#203a63", "#6694cc"
LINING = "#d9c8a0"
PANTS, PANTS_S = "#3d342d", "#28211c"
BOOT, BOOT_S, BOOT_H = "#5e3f27", "#3d2818", "#93683f"
STEEL, STEEL_S, STEEL_H = "#b3bfca", "#6c7a88", "#eef4f8"
LEATHER, LEATHER_S = "#714b2c", "#4a301b"
SCARF, SCARF_S = "#b4402e", "#7c281c"
GOLD = "#d9a84a"
AETHER = "#6ff0ff"
CLOAK, CLOAK_S = "#2c3e5c", "#1a263b"

# Articulations (repos, canevas). Tourné vers la droite, pieds sur y=400.
J = {
    "hip": (196, 232), "neck": (204, 142),
    "sh_f": (224, 154), "el_f": (246, 200), "wr_f": (262, 240),
    "sh_b": (184, 156), "el_b": (170, 202), "wr_b": (164, 242),
    "hip_f": (210, 240), "kn_f": (232, 314), "an_f": (238, 386),
    "hip_b": (184, 240), "kn_b": (166, 316), "an_b": (150, 388),
    "cape": (192, 150),
}


def P(pts):
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)


def capsule_pts(p0, p1, w0, w1, n=10):
    (x0, y0), (x1, y1) = p0, p1
    dx, dy = x1 - x0, y1 - y0
    L = math.hypot(dx, dy) or 1
    dx, dy = dx / L, dy / L
    nx, ny = -dy, dx
    a = math.atan2(ny, nx)
    pts = []
    for i in range(n + 1):  # demi-cercle à l'extrémité p1 (côté +d)
        t = a - math.pi * i / n
        pts.append((x1 + math.cos(t) * w1 / 2, y1 + math.sin(t) * w1 / 2))
    for i in range(n + 1):  # demi-cercle à l'origine p0 (côté -d)
        t = a + math.pi - math.pi * i / n
        pts.append((x0 + math.cos(t) * w0 / 2, y0 + math.sin(t) * w0 / 2))
    return pts


def offset(p, n, k):
    return (p[0] + n[0] * k, p[1] + n[1] * k)


def normal(p0, p1):
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    L = math.hypot(dx, dy) or 1
    return (-dy / L, dx / L)


def limb(p0, p1, w0, w1, base, shade, hi=None):
    """Segment ombré : forme de base + ombre (côté opposé à la lumière) + rehaut."""
    n = normal(p0, p1)
    out = [f'<polygon points="{P(capsule_pts(p0, p1, w0, w1))}" fill="{base}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>']
    out.append(f'<polygon points="{P(capsule_pts(offset(p0, n, w0 * .2), offset(p1, n, w1 * .2), w0 * .55, w1 * .55))}" fill="{shade}"/>')
    if hi:
        out.append(f'<polygon points="{P(capsule_pts(offset(p0, n, -w0 * .3), offset(p1, n, -w1 * .3), w0 * .14, w1 * .14))}" fill="{hi}" opacity="0.75"/>')
    return "\n".join(out)


def svg(name, body, note):
    s = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">\n'
         f'  <!-- Chasseur HD — calque « {name} » : {note}. Canevas commun {W}x{H}. -->\n'
         f'  <defs>\n'
         f'    <radialGradient id="aeth" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffffff"/><stop offset="0.45" stop-color="{AETHER}"/><stop offset="1" stop-color="#1b8fb0"/></radialGradient>\n'
         f'    <linearGradient id="blade" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="0.5" stop-color="{STEEL}"/><stop offset="1" stop-color="{STEEL_S}"/></linearGradient>\n'
         f'  </defs>\n{body}\n</svg>\n')
    open(f"{OUT}/{name}.svg", "w").write(s)


def rot(p, c, deg):
    a = math.radians(deg)
    x, y = p[0] - c[0], p[1] - c[1]
    return (c[0] + x * math.cos(a) - y * math.sin(a), c[1] + x * math.sin(a) + y * math.cos(a))


# --- Cape (derrière tout) ---------------------------------------------------
cape = f'''<path d="M180 148 Q150 160 132 214 Q112 268 96 322 Q132 312 152 300 Q170 330 196 318 Q204 250 214 160 Z" fill="{CLOAK}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M176 160 Q150 196 132 256 Q118 296 104 316 Q130 306 150 296 Q156 240 182 170 Z" fill="{CLOAK_S}"/>
<path d="M150 300 Q172 326 196 318" fill="none" stroke="{GOLD}" stroke-width="2"/>'''
svg("cape", cape, "cape, pivot aux épaules")

# --- Bras arrière -----------------------------------------------------------
svg("arm_b_up", limb(J["sh_b"], J["el_b"], 26, 21, "#29466f", "#192d4a"), "bras arrière (haut)")
arm_b_lo = limb(J["el_b"], J["wr_b"], 20, 16, "#29466f", "#192d4a")
arm_b_lo += f'\n<polygon points="{P(capsule_pts((168, 222), (165, 238), 19, 17))}" fill="{STEEL_S}" stroke="{INK}" stroke-width="{SW}"/>'
arm_b_lo += f'\n<ellipse cx="{J["wr_b"][0] - 1}" cy="{J["wr_b"][1] + 9}" rx="10" ry="11" fill="{LEATHER_S}" stroke="{INK}" stroke-width="{SW}"/>'
svg("arm_b_lo", arm_b_lo, "avant-bras et main arrière")

# --- Jambes -----------------------------------------------------------------
svg("leg_b_up", limb(J["hip_b"], J["kn_b"], 34, 25, PANTS_S, "#1d1814"), "cuisse arrière")
leg_b_lo = limb(J["kn_b"], J["an_b"], 24, 20, PANTS_S, "#1d1814")
leg_b_lo += f'''\n<path d="M138 352 L164 348 L166 392 Q176 394 184 400 L126 402 Q126 392 138 388 Z" fill="{BOOT_S}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M136 352 L166 346 L167 358 L137 364 Z" fill="{LEATHER_S}" stroke="{INK}" stroke-width="2"/>'''
svg("leg_b_lo", leg_b_lo, "jambe et botte arrière")

svg("leg_f_up", limb(J["hip_f"], J["kn_f"], 36, 27, PANTS, PANTS_S, "#5a4d42"), "cuisse avant")
leg_f_lo = limb(J["kn_f"], J["an_f"], 26, 21, PANTS, PANTS_S)
leg_f_lo += f'''\n<path d="M222 346 L254 342 L252 384 Q272 388 280 400 L226 402 Q222 380 222 346 Z" fill="{BOOT}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M226 360 L234 398 L228 400 Q222 382 224 360 Z" fill="{BOOT_S}"/>
<path d="M248 350 L250 384" fill="none" stroke="{BOOT_H}" stroke-width="3" stroke-linecap="round"/>
<path d="M219 342 L256 337 L257 352 L220 357 Z" fill="{LEATHER}" stroke="{INK}" stroke-width="2"/>
<circle cx="238" cy="347" r="3" fill="{GOLD}" stroke="{INK}" stroke-width="1.5"/>
<path d="M262 392 L280 400 L252 401 Z" fill="{STEEL}" stroke="{INK}" stroke-width="2"/>
<circle cx="{J["kn_f"][0]}" cy="{J["kn_f"][1]}" r="13" fill="{LEATHER}" stroke="{INK}" stroke-width="2"/>
<circle cx="{J["kn_f"][0] + 3}" cy="{J["kn_f"][1] - 3}" r="4" fill="{BOOT_H}"/>'''
svg("leg_f_lo", leg_f_lo, "jambe et botte avant, genouillère")

# --- Bassin : pans de manteau ----------------------------------------------
pelvis = f'''<path d="M170 226 Q160 262 150 304 L186 296 L196 250 Z" fill="{COAT_S}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M200 228 L232 228 Q244 262 252 300 Q232 306 214 300 Q210 270 200 250 Z" fill="{COAT}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M214 236 Q222 268 228 302 L214 300 Q210 270 204 246 Z" fill="{COAT_S}"/>
<path d="M232 230 Q244 264 252 300" fill="none" stroke="{LINING}" stroke-width="3"/>
<path d="M240 250 Q246 274 250 296" fill="none" stroke="{COAT_H}" stroke-width="2" opacity="0.8"/>'''
svg("pelvis", pelvis, "pans de manteau, pivot à la hanche")

# --- Torse ------------------------------------------------------------------
torso = f'''<path d="M174 150 Q196 136 230 146 Q240 182 236 228 L172 230 Q166 190 174 150 Z" fill="{COAT}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M176 156 Q170 194 174 228 L194 228 Q186 190 192 150 Z" fill="{COAT_S}"/>
<path d="M226 150 Q236 184 232 224" fill="none" stroke="{COAT_H}" stroke-width="3" opacity="0.8"/>
<path d="M204 146 L222 148 L214 196 Z" fill="{LINING}" stroke="{INK}" stroke-width="2" stroke-linejoin="round"/>
<path d="M200 148 Q214 176 214 200 L206 200 Q204 178 194 152 Z" fill="{COAT_H}" stroke="{INK}" stroke-width="2"/>
<path d="M226 150 Q218 176 220 202 L228 200 Q226 176 232 154 Z" fill="{COAT_S}" stroke="{INK}" stroke-width="2"/>
<path d="M178 160 L232 214" fill="none" stroke="{INK}" stroke-width="9" stroke-linecap="round"/>
<path d="M178 160 L232 214" fill="none" stroke="{LEATHER}" stroke-width="5.5" stroke-linecap="round"/>
<rect x="198" y="178" width="11" height="9" rx="2" fill="{GOLD}" stroke="{INK}" stroke-width="1.5" transform="rotate(45 203 182)"/>
<path d="M168 214 L240 210 L241 226 L169 230 Z" fill="{LEATHER_S}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<rect x="196" y="209" width="16" height="19" rx="3" fill="{GOLD}" stroke="{INK}" stroke-width="2"/>
<rect x="200" y="213" width="8" height="11" rx="1.5" fill="{LEATHER_S}"/>
<rect x="176" y="222" width="13" height="24" rx="6" fill="url(#aeth)" stroke="{INK}" stroke-width="2"/>
<rect x="178" y="218" width="9" height="6" rx="2" fill="{STEEL}" stroke="{INK}" stroke-width="1.5"/>
<path d="M214 226 L234 224 L236 244 L216 246 Z" fill="{LEATHER}" stroke="{INK}" stroke-width="2"/>
<path d="M184 140 Q204 130 230 140 Q236 152 228 160 Q206 166 184 158 Q176 150 184 140 Z" fill="{SCARF}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M188 152 Q206 160 226 154 L228 158 Q206 166 186 158 Z" fill="{SCARF_S}"/>'''
svg("torso", torso, "torse, manteau, ceinture, fiole d'Aether, écharpe")

# --- Tête -------------------------------------------------------------------
head = f'''<path d="M196 126 L214 126 L214 146 L196 146 Z" fill="{SKIN_S}" stroke="{INK}" stroke-width="{SW}"/>
<path d="M180 90 Q178 56 208 52 Q238 52 242 84 Q246 98 242 108 Q236 128 216 134 Q194 136 186 122 Q178 108 180 90 Z" fill="{SKIN}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M182 92 Q182 116 194 128 Q186 112 190 92 Z" fill="{SKIN_S}"/>
<path d="M240 96 L250 104 L240 108 Z" fill="{SKIN}" stroke="{INK}" stroke-width="2" stroke-linejoin="round"/>
<ellipse cx="192" cy="98" rx="7" ry="10" fill="{SKIN_S}" stroke="{INK}" stroke-width="2"/>
<path d="M220 88 Q228 84 238 87" fill="none" stroke="{HAIR}" stroke-width="3.5" stroke-linecap="round"/>
<path d="M224 94 Q231 91 238 95 L237 104 Q230 106 225 103 Z" fill="#ffffff" stroke="{INK}" stroke-width="1.8"/>
<ellipse cx="232" cy="99" rx="4" ry="5" fill="#2f6fb5"/>
<ellipse cx="232.5" cy="99.5" rx="2" ry="3" fill="#0c1a2c"/>
<circle cx="233.8" cy="97.5" r="1.2" fill="#ffffff"/>
<path d="M226 120 Q233 122 238 118" fill="none" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>
<path d="M206 118 Q214 124 222 122" fill="none" stroke="{SKIN_S}" stroke-width="2"/>
<path d="M172 96 Q164 54 196 40 Q226 28 248 48 Q258 60 254 76 Q246 64 236 64 L242 78 Q228 66 218 68 L222 80 Q210 70 200 74 Q194 86 196 98 L188 104 Q180 98 172 96 Z" fill="{HAIR}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M176 90 Q170 64 188 50 Q178 72 184 92 Z" fill="{HAIR_S}"/>
<path d="M200 48 Q222 40 240 50" fill="none" stroke="{HAIR_H}" stroke-width="3" stroke-linecap="round"/>
<path d="M210 56 Q226 52 236 58" fill="none" stroke="{HAIR_H}" stroke-width="2" stroke-linecap="round" opacity="0.8"/>
<path d="M172 96 L162 104 L176 104 Z M178 86 L166 84 L176 94 Z" fill="{HAIR}" stroke="{INK}" stroke-width="2" stroke-linejoin="round"/>'''
head = f'<g transform="translate(204 142) scale(0.86) translate(-204 -142)">{head}</g>'
svg("head", head, "tête et cheveux, pivot au cou")

# --- Épée (tenue dans la main avant, inclinée vers l'avant) ------------------
G = J["wr_f"]  # point de prise
ANG = -38      # inclinaison de repos (degrés, sens horaire positif)
def S(x, y):    # coordonnées locales de l'épée (lame vers le haut, prise en 0,0) -> canevas
    return rot((G[0] + x, G[1] + y), G, ANG + 90)
blade = [S(-12, -14), S(-14, -150), S(-6, -186), S(8, -198), S(12, -150), S(12, -14)]
fuller = [S(-2, -24), S(-3, -160), S(3, -168), S(3, -24)]
guard = [S(-30, -10), S(30, -10), S(26, -20), S(-26, -20)]
grip = [S(-6, -10), S(6, -10), S(6, 22), S(-6, 22)]
sword = f'''<polygon points="{P(blade)}" fill="url(#blade)" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<polygon points="{P(fuller)}" fill="{STEEL_S}"/>
<polyline points="{P([S(9, -20), S(9, -150), S(6, -186)])}" fill="none" stroke="{STEEL_H}" stroke-width="2"/>
<polyline points="{P([S(0, -40), S(0, -150)])}" fill="none" stroke="{AETHER}" stroke-width="2.4" stroke-linecap="round"/>
<polygon points="{P(guard)}" fill="{GOLD}" stroke="{INK}" stroke-width="2.2" stroke-linejoin="round"/>
<polygon points="{P(grip)}" fill="{LEATHER_S}" stroke="{INK}" stroke-width="2"/>
<circle cx="{S(0, 28)[0]:.1f}" cy="{S(0, 28)[1]:.1f}" r="7" fill="url(#aeth)" stroke="{INK}" stroke-width="2"/>
<circle cx="{S(0, -15)[0]:.1f}" cy="{S(0, -15)[1]:.1f}" r="4.5" fill="url(#aeth)" stroke="{INK}" stroke-width="1.5"/>'''
svg("sword", sword, "épée surdimensionnée, pivot = poing avant")

# --- Bras avant (devant tout) ----------------------------------------------
arm_f_up = limb(J["sh_f"], J["el_f"], 28, 22, COAT, COAT_S, COAT_H)
arm_f_up += f'''\n<path d="M208 146 Q228 132 246 146 Q250 164 236 172 Q220 172 210 162 Z" fill="{LEATHER}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M214 150 Q228 142 240 150" fill="none" stroke="{GOLD}" stroke-width="2"/>'''
svg("arm_f_up", arm_f_up, "bras avant (haut) et spallière")
arm_f_lo = limb(J["el_f"], J["wr_f"], 22, 18, COAT, COAT_S, COAT_H)
arm_f_lo += f'''\n<polygon points="{P(capsule_pts((250, 214), (259, 234), 22, 20))}" fill="{STEEL}" stroke="{INK}" stroke-width="{SW}"/>
<polyline points="254,216 260,232" fill="none" stroke="{STEEL_H}" stroke-width="2"/>
<path d="M251 236 Q262 228 273 236 Q278 248 270 254 Q258 258 252 250 Z" fill="{LEATHER}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M256 240 Q264 236 270 241" fill="none" stroke="{LEATHER_S}" stroke-width="2"/>'''
svg("arm_f_lo", arm_f_lo, "avant-bras, brassard et poing avant")

# --- Fiche de squelette -------------------------------------------------------
rig = {
    "_note": "Squelette du Chasseur HD. pivot = articulation en pixels du canevas. Ordre = ordre d'affichage.",
    "canvas": [W, H],
    "feet": [196, 400],
    "bones": [
        {"name": "hip", "parent": "", "pivot": J["hip"]},
        {"name": "torso", "parent": "hip", "pivot": J["hip"]},
        {"name": "head", "parent": "torso", "pivot": J["neck"]},
        {"name": "cape", "parent": "torso", "pivot": J["cape"]},
        {"name": "arm_b_up", "parent": "torso", "pivot": J["sh_b"]},
        {"name": "arm_b_lo", "parent": "arm_b_up", "pivot": J["el_b"]},
        {"name": "arm_f_up", "parent": "torso", "pivot": J["sh_f"]},
        {"name": "arm_f_lo", "parent": "arm_f_up", "pivot": J["el_f"]},
        {"name": "weapon", "parent": "arm_f_lo", "pivot": J["wr_f"]},
        {"name": "pelvis", "parent": "hip", "pivot": J["hip"]},
        {"name": "leg_f_up", "parent": "hip", "pivot": J["hip_f"]},
        {"name": "leg_f_lo", "parent": "leg_f_up", "pivot": J["kn_f"]},
        {"name": "leg_b_up", "parent": "hip", "pivot": J["hip_b"]},
        {"name": "leg_b_lo", "parent": "leg_b_up", "pivot": J["kn_b"]},
    ],
    "parts": [
        {"file": "cape", "bone": "cape"},
        {"file": "arm_b_up", "bone": "arm_b_up"},
        {"file": "arm_b_lo", "bone": "arm_b_lo"},
        {"file": "leg_b_up", "bone": "leg_b_up"},
        {"file": "leg_b_lo", "bone": "leg_b_lo"},
        {"file": "leg_f_up", "bone": "leg_f_up"},
        {"file": "leg_f_lo", "bone": "leg_f_lo"},
        {"file": "pelvis", "bone": "pelvis"},
        {"file": "torso", "bone": "torso"},
        {"file": "head", "bone": "head"},
        {"file": "sword", "bone": "weapon"},
        {"file": "arm_f_up", "bone": "arm_f_up"},
        {"file": "arm_f_lo", "bone": "arm_f_lo"},
    ],
    "art_dir": "res://" + OUT,
}
os.makedirs("data/rig", exist_ok=True)
json.dump(rig, open("data/rig/hero_hd.json", "w"), indent=1, ensure_ascii=False)
print("Chasseur HD généré :", len(rig["parts"]), "calques")
