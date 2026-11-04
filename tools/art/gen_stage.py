"""Génère les calques SVG du décor (arène de combat + zone d'exploration).
Usage : python3 tools/art/gen_stage.py   (depuis la racine du projet)
Décor original : lisière d'avant-poste au crépuscule, cristaux d'Aether. Placeholders non finaux."""
import random, math, os
W, H = 1280, 720
OUT = "art/stage"
os.makedirs(OUT, exist_ok=True)
INK = "#0f141a"

def svg(body, defs="", note=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">\n'
            f'  <!-- {note} -->\n  <defs>{defs}</defs>\n{body}</svg>\n')

def pine(x, base, h, w, fill, stroke=None, sw=0):
    pts = []
    tiers = 4
    for i in range(tiers):
        t0 = base - h * i / tiers * 0.85
        ww = w * (1 - i / tiers * 0.7)
        top = t0 - h * 0.38
        pts.append(f'<path d="M{x-ww:.1f} {t0:.1f} L{x:.1f} {top:.1f} L{x+ww:.1f} {t0:.1f} Q{x:.1f} {t0-h*0.06:.1f} {x-ww:.1f} {t0:.1f} Z" fill="{fill}"'
                   + (f' stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"' if stroke else '') + '/>')
    pts.insert(0, f'<rect x="{x-w*0.08:.1f}" y="{base-h*0.1:.1f}" width="{w*0.16:.1f}" height="{h*0.14:.1f}" fill="{fill}"/>')
    return "\n".join(pts)

def crystal(x, y, s, c1, c2, glow=True):
    out = []
    if glow:
        out.append(f'<circle cx="{x}" cy="{y-s*0.6}" r="{s*1.6}" fill="url(#cglow)"/>')
    out.append(f'<path d="M{x-s*0.35} {y} L{x-s*0.1} {y-s*1.3} L{x+s*0.2} {y} Z" fill="{c1}" stroke="{INK}" stroke-width="2"/>')
    out.append(f'<path d="M{x} {y} L{x+s*0.35} {y-s*0.9} L{x+s*0.55} {y} Z" fill="{c2}" stroke="{INK}" stroke-width="2"/>')
    out.append(f'<path d="M{x-s*0.6} {y} L{x-s*0.5} {y-s*0.6} L{x-s*0.2} {y} Z" fill="{c2}" stroke="{INK}" stroke-width="2"/>')
    return "\n".join(out)

CGLOW = '<radialGradient id="cglow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#7fefff" stop-opacity="0.55"/><stop offset="1" stop-color="#7fefff" stop-opacity="0"/></radialGradient>'

# --- Ciel -------------------------------------------------------------------
random.seed(3)
defs = ('<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">'
        '<stop offset="0" stop-color="#1b2a44"/><stop offset="0.45" stop-color="#3f4f6e"/>'
        '<stop offset="0.68" stop-color="#b5755a"/><stop offset="0.8" stop-color="#f0b06a"/><stop offset="1" stop-color="#f6c98a"/></linearGradient>'
        '<radialGradient id="sun" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#fff3d0" stop-opacity="0.9"/><stop offset="1" stop-color="#ffcf8a" stop-opacity="0"/></radialGradient>'
        '<linearGradient id="aur" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5fe3ff" stop-opacity="0"/><stop offset="0.5" stop-color="#5fe3ff" stop-opacity="0.35"/><stop offset="1" stop-color="#5fe3ff" stop-opacity="0"/></linearGradient>')
body = f'<rect width="{W}" height="{H}" fill="url(#sky)"/>\n<circle cx="820" cy="430" r="260" fill="url(#sun)"/>\n'
for i in range(3):
    y = 90 + i * 55
    body += f'<path d="M-50 {y} Q400 {y-60} 700 {y+10} T1330 {y-30} L1330 {y-10} Q900 {y+40} 700 {y+30} T-50 {y+22} Z" fill="url(#aur)"/>\n'
for i in range(9):
    x, y = random.randint(0, W), random.randint(200, 360)
    w = random.randint(120, 260)
    body += f'<ellipse cx="{x}" cy="{y}" rx="{w}" ry="{w*0.09:.0f}" fill="#f7d2a8" opacity="0.25"/>\n'
for i in range(40):
    body += f'<circle cx="{random.randint(0,W)}" cy="{random.randint(0,180)}" r="{random.choice([1,1,1.5,2])}" fill="#e8f4ff" opacity="{random.uniform(0.3,0.9):.2f}"/>\n'
open(f"{OUT}/sky.svg", "w").write(svg(body, defs, "Ciel du crépuscule et voiles d'Aether"))

# --- Lointain : montagnes et flèches cristallines ---------------------------
random.seed(5)
defs = CGLOW + '<linearGradient id="mt" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5d6b8a"/><stop offset="1" stop-color="#8e8aa0"/></linearGradient>'
pts = "M0 720 L0 400 "
x = 0
while x < W:
    x += random.randint(60, 140)
    pts += f"L{x} {random.randint(250, 380)} "
pts += f"L{W} 720 Z"
body = f'<path d="{pts}" fill="url(#mt)"/>\n'
pts = "M0 720 L0 460 "
x = 0
while x < W:
    x += random.randint(50, 110)
    pts += f"L{x} {random.randint(360, 440)} "
pts += f"L{W} 720 Z"
body += f'<path d="{pts}" fill="#6f7895" opacity="0.9"/>\n'
for cx in (250, 640, 1040):
    body += crystal(cx, 410, 60, "#9fd9ff", "#6fa6e0")
open(f"{OUT}/far.svg", "w").write(svg(body, defs, "Arrière-plan lointain : crêtes et flèches d'Aether"))

# --- Plan moyen : forêt + avant-poste ---------------------------------------
random.seed(11)
defs = CGLOW + '<radialGradient id="lamp" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffd38a" stop-opacity="0.9"/><stop offset="1" stop-color="#ffb35a" stop-opacity="0"/></radialGradient>'
body = ""
for i in range(34):
    x = random.randint(-30, W + 30)
    h = random.randint(170, 260)
    body += pine(x, 470 + random.randint(-10, 10), h, h * 0.28, "#2f4a4f") + "\n"
for i in range(26):
    x = random.randint(-30, W + 30)
    h = random.randint(200, 300)
    body += pine(x, 490 + random.randint(-5, 10), h, h * 0.3, "#203539", INK, 2) + "\n"
# tour de guet de l'avant-poste (gauche)
body += f'''<g stroke="{INK}" stroke-width="3" stroke-linejoin="round">
<path d="M80 480 L96 250 L176 250 L192 480 Z" fill="#5a4636"/>
<path d="M70 256 L136 196 L202 256 Z" fill="#7a3a2a"/>
<rect x="116" y="290" width="40" height="44" fill="#ffcf7a"/>
<path d="M136 290 L136 334 M116 312 L156 312" stroke-width="3"/>
<path d="M0 480 L0 420 L20 410 L40 420 L60 412 L80 420 L80 480 Z" fill="#4a3a2c"/>
<path d="M192 480 L192 424 L212 414 L232 424 L252 416 L272 426 L272 480 Z" fill="#4a3a2c"/>
</g>
<circle cx="136" cy="312" r="70" fill="url(#lamp)"/>
'''
for cx in (520, 980, 1180):
    body += crystal(cx, 486, 34, "#b9f3ff", "#5fb7e0") + "\n"
open(f"{OUT}/mid.svg", "w").write(svg(body, defs, "Plan moyen : forêt de pins, tour de l'avant-poste, cristaux"))

# --- Sol --------------------------------------------------------------------
random.seed(17)
defs = ('<linearGradient id="gr" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a5a3c"/><stop offset="0.25" stop-color="#6b6044"/>'
        '<stop offset="1" stop-color="#3a3024"/></linearGradient>'
        '<radialGradient id="clear" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#a08460" stop-opacity="0.75"/><stop offset="1" stop-color="#a08460" stop-opacity="0"/></radialGradient>')
body = f'<path d="M0 470 Q320 452 640 462 T1280 466 L1280 720 L0 720 Z" fill="url(#gr)"/>\n'
body += '<ellipse cx="660" cy="580" rx="560" ry="110" fill="url(#clear)"/>\n'
for i in range(140):
    y = random.uniform(470, 720)
    x = random.uniform(0, W)
    s = 2 + (y - 470) / 250 * 9
    body += f'<path d="M{x:.0f} {y:.0f} l{-s*0.6:.1f} {-s*1.8:.1f} M{x:.0f} {y:.0f} l{s*0.2:.1f} {-s*2.2:.1f} M{x:.0f} {y:.0f} l{s*0.9:.1f} {-s*1.5:.1f}" stroke="#7d8a52" stroke-width="{1+s*0.18:.1f}" stroke-linecap="round" opacity="0.8"/>\n'
for i in range(26):
    y = random.uniform(480, 710)
    x = random.uniform(0, W)
    s = 4 + (y - 470) / 250 * 12
    body += f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="{s*1.4:.1f}" ry="{s*0.7:.1f}" fill="#7b7366" stroke="{INK}" stroke-width="2"/>\n'
open(f"{OUT}/ground.svg", "w").write(svg(body, defs, "Sol de la clairière, perspective par la taille des touffes et pierres"))

# --- Premier plan -----------------------------------------------------------
random.seed(23)
body = ""
for side in (0, 1):
    for i in range(16):
        x = random.uniform(0, 260) if side == 0 else random.uniform(1020, 1280)
        y = random.uniform(650, 740)
        h = random.uniform(40, 110)
        body += f'<path d="M{x:.0f} {y:.0f} Q{x-12:.0f} {y-h*0.6:.0f} {x-26:.0f} {y-h:.0f} Q{x+2:.0f} {y-h*0.5:.0f} {x+10:.0f} {y:.0f} Z" fill="#1b2a1f" stroke="{INK}" stroke-width="2"/>\n'
    rx = 90 if side == 0 else 1190
    body += f'<path d="M{rx-120} 740 Q{rx-90} 640 {rx} 650 Q{rx+90} 660 {rx+130} 740 Z" fill="#2a2e2c" stroke="{INK}" stroke-width="3"/>\n'
body += f'<path d="M1280 0 Q1150 40 1080 110 Q1140 70 1190 60 Q1150 100 1140 140 Q1200 80 1280 60 Z" fill="#14231d" stroke="{INK}" stroke-width="2"/>\n'
open(f"{OUT}/front.svg", "w").write(svg(body, "", "Premier plan : herbes hautes et rochers (devant les personnages)"))
print("décor généré")
