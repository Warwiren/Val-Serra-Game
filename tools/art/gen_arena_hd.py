"""Génère l'arène forestière nocturne « HD » en 8 plans (1360×760, marge pour le parallax).
Usage : python3 tools/art/gen_arena_hd.py   (depuis la racine du projet)
Chaque plan est un calque indépendant, comme le livrerait un illustrateur (ou une IA + séparation des plans)."""
import math, os, random

W, H = 1360, 760
OUT = "art/hd/arena"
os.makedirs(OUT, exist_ok=True)
INK = "#070a12"
OX, OY = 40, 20   # décalage : (0,0) du jeu = (40,20) du canevas


def svg(name, body, defs="", note=""):
    open(f"{OUT}/{name}.svg", "w").write(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">\n'
        f'<!-- Arène HD — plan « {name} » : {note} -->\n<defs>{defs}</defs>\n{body}\n</svg>\n')


def pine(x, base, h, w, body, rim, ink=None):
    """Pin stylisé en étages, avec liseré de lune sur le côté droit."""
    out = [f'<rect x="{x - w * .07:.1f}" y="{base - h * .12:.1f}" width="{w * .14:.1f}" height="{h * .14:.1f}" fill="{body}"/>']
    tiers = 5
    for i in range(tiers):
        b = base - h * i / tiers * .82
        ww = w * (1 - i / tiers * .72)
        top = b - h * .34
        d = f"M{x - ww:.1f} {b:.1f} Q{x - ww * .4:.1f} {b - h * .05:.1f} {x - ww * .15:.1f} {b - h * .02:.1f} L{x:.1f} {top:.1f} L{x + ww:.1f} {b:.1f} Q{x:.1f} {b - h * .07:.1f} {x - ww:.1f} {b:.1f} Z"
        st = f' stroke="{ink}" stroke-width="2" stroke-linejoin="round"' if ink else ""
        out.append(f'<path d="{d}" fill="{body}"{st}/>')
        out.append(f'<path d="M{x + ww * .1:.1f} {top + h * .06:.1f} L{x + ww * .92:.1f} {b - h * .01:.1f} L{x + ww * .55:.1f} {b - h * .035:.1f} Z" fill="{rim}" opacity="0.55"/>')
    return "\n".join(out)


def crystal(x, y, s, a="#bff6ff", b="#58c4ec", c="#2a6fb0", glow=True):
    out = []
    if glow:
        out.append(f'<circle cx="{x}" cy="{y - s * .5}" r="{s * 1.8}" fill="url(#cglow)"/>')
    for dx, hh, ww, col in [(-.45, .7, .28, c), (.35, .85, .3, b), (0, 1.3, .34, a), (-.2, .9, .26, b)]:
        cx = x + dx * s
        out.append(f'<path d="M{cx - ww * s:.1f} {y:.1f} L{cx - ww * s * .2:.1f} {y - hh * s:.1f} L{cx + ww * s * .3:.1f} {y - hh * s * .8:.1f} L{cx + ww * s:.1f} {y:.1f} Z" fill="{col}" stroke="{INK}" stroke-width="1.8" stroke-linejoin="round"/>')
        out.append(f'<path d="M{cx - ww * s * .2:.1f} {y - hh * s:.1f} L{cx:.1f} {y - s * .1:.1f}" stroke="#ffffff" stroke-width="1.2" opacity="0.7"/>')
    return "\n".join(out)


CGLOW = '<radialGradient id="cglow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#7fefff" stop-opacity="0.5"/><stop offset="1" stop-color="#7fefff" stop-opacity="0"/></radialGradient>'
WARM = '<radialGradient id="warm" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffd890" stop-opacity="0.85"/><stop offset="1" stop-color="#ff9e40" stop-opacity="0"/></radialGradient>'

# 1. Ciel et lune ---------------------------------------------------------------
random.seed(4)
defs = ('<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#070d1c"/><stop offset="0.45" stop-color="#16274a"/>'
        '<stop offset="0.75" stop-color="#2e4a72"/><stop offset="1" stop-color="#4a6688"/></linearGradient>'
        '<radialGradient id="halo" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#dfe9ff" stop-opacity="0.55"/><stop offset="0.35" stop-color="#9fb8e8" stop-opacity="0.18"/><stop offset="1" stop-color="#9fb8e8" stop-opacity="0"/></radialGradient>'
        '<radialGradient id="moon" cx="0.42" cy="0.4" r="0.6"><stop offset="0" stop-color="#ffffff"/><stop offset="0.7" stop-color="#e3ebfb"/><stop offset="1" stop-color="#b9c6e4"/></radialGradient>')
mx, my = 690 + OX, 205 + OY   # lune visible entre les combattants (sous la chronologie)
body = f'<rect width="{W}" height="{H}" fill="url(#sky)"/>\n'
for i in range(120):
    body += f'<circle cx="{random.uniform(0, W):.0f}" cy="{random.uniform(0, 380):.0f}" r="{random.choice([0.8, 1, 1.2, 1.6])}" fill="#eaf2ff" opacity="{random.uniform(.3, .95):.2f}"/>\n'
body += f'<circle cx="{mx}" cy="{my}" r="330" fill="url(#halo)"/>\n<circle cx="{mx}" cy="{my}" r="48" fill="url(#moon)"/>\n'
for cx, cy, r in [(-11, -8, 7), (9, 11, 9), (15, -14, 5), (-17, 15, 5)]:
    body += f'<circle cx="{mx + cx}" cy="{my + cy}" r="{r}" fill="#c6d1ea" opacity="0.6"/>\n'
for i in range(7):
    y = 150 + i * 42
    x = random.uniform(-100, 1000)
    w = random.uniform(260, 520)
    body += f'<path d="M{x:.0f} {y} Q{x + w * .3:.0f} {y - 18} {x + w * .6:.0f} {y - 6} T{x + w:.0f} {y - 4} Q{x + w * .5:.0f} {y + 12} {x:.0f} {y} Z" fill="#7d93bd" opacity="0.22"/>\n'
    body += f'<path d="M{x + w * .3:.0f} {y - 16} Q{x + w * .5:.0f} {y - 22} {x + w * .7:.0f} {y - 10}" stroke="#d6e2ff" stroke-width="2" fill="none" opacity="0.35"/>\n'
svg("sky", body, defs, "ciel nocturne, lune et nuages éclairés")

# 2. Crêtes lointaines ------------------------------------------------------------
random.seed(7)
pts = "M0 760 L0 400 "
x = 0
while x < W:
    x += random.randint(70, 150)
    pts += f"L{x} {random.randint(300, 400)} "
body = f'<path d="{pts} L{W} 760 Z" fill="#2c3d5e"/>\n'
pts2 = "M0 760 L0 450 "
x = 0
while x < W:
    x += random.randint(50, 100)
    pts2 += f"L{x} {random.randint(400, 460)} "
body += f'<path d="{pts2} L{W} 760 Z" fill="#26354f"/>\n'
for i in range(70):
    x = random.uniform(0, W)
    body += pine(x, 492 + random.uniform(-6, 8), random.uniform(60, 100), random.uniform(16, 26), "#1f2c45", "#4e6a96") + "\n"
svg("ridge", body, "", "crêtes et forêt lointaines")

# 3. Forêt intermédiaire -----------------------------------------------------------
random.seed(13)
body = ""
for i in range(34):
    x = random.uniform(-40, W + 40)
    h = random.uniform(170, 250)
    body += pine(x, 512 + random.uniform(-8, 8), h, h * .27, "#152138", "#40608e") + "\n"
svg("forest_far", body, "", "rangée de pins intermédiaire, liseré de lune")

# 4. Plan moyen : grands pins, tour, palissade, bannière, lanternes -------------------
random.seed(19)
defs = CGLOW + WARM + ('<linearGradient id="wood" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#2c2018"/><stop offset="1" stop-color="#5a4232"/></linearGradient>'
                       '<linearGradient id="ban" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5a3a8c"/><stop offset="1" stop-color="#2e1d4e"/></linearGradient>')
body = ""
for i in range(16):
    x = random.uniform(200, W - 150)
    h = random.uniform(260, 360)
    body += pine(x, 536 + random.uniform(-6, 6), h, h * .28, "#0d1526", "#36507a", INK) + "\n"
tx = 150 + OX
body += f'''<g stroke="{INK}" stroke-width="2.5" stroke-linejoin="round">
<path d="M{tx - 70} 540 L{tx - 56} 300 L{tx + 56} 300 L{tx + 70} 540" fill="none" stroke="#3a2a20" stroke-width="10"/>
<path d="M{tx - 62} 420 L{tx + 62} 420 M{tx - 66} 480 L{tx + 66} 480 M{tx - 60} 360 L{tx + 60} 360" stroke="#3a2a20" stroke-width="7"/>
<path d="M{tx - 62} 420 L{tx + 64} 480 M{tx + 62} 420 L{tx - 64} 480" stroke="#2c2018" stroke-width="5"/>
<rect x="{tx - 72}" y="236" width="144" height="70" fill="url(#wood)"/>
<rect x="{tx - 40}" y="250" width="30" height="34" fill="#ffcf7a"/><rect x="{tx + 10}" y="250" width="30" height="34" fill="#ffc060"/>
<path d="M{tx - 25} 250 L{tx - 25} 284 M{tx + 25} 250 L{tx + 25} 284" stroke-width="2"/>
<path d="M{tx - 96} 240 L{tx} 176 L{tx + 96} 240 Z" fill="#3b2b26"/>
<path d="M{tx - 80} 234 L{tx} 182 L{tx + 30} 202" stroke="#6a7fa8" stroke-width="2" fill="none"/>
</g>
<circle cx="{tx}" cy="268" r="120" fill="url(#warm)"/>
'''
# palissade et bannière à droite
fx0 = 860 + OX
for k in range(14):
    x = fx0 + k * 26
    body += f'<path d="M{x} 546 L{x} 470 L{x + 9} 458 L{x + 18} 470 L{x + 18} 546 Z" fill="#3a2a20" stroke="{INK}" stroke-width="2"/>\n'
body += f'<path d="M{fx0 - 6} 488 L{fx0 + 370} 488 M{fx0 - 6} 524 L{fx0 + 370} 524" stroke="#2a1d16" stroke-width="7"/>\n'
bx = 1150 + OX
body += f'''<g stroke="{INK}" stroke-width="2.5" stroke-linejoin="round">
<rect x="{bx - 5}" y="300" width="10" height="250" fill="#3a2a20"/>
<rect x="{bx - 60}" y="304" width="120" height="8" fill="#3a2a20"/>
<path d="M{bx - 50} 312 L{bx + 50} 312 L{bx + 50} 450 L{bx} 476 L{bx - 50} 450 Z" fill="url(#ban)"/>
<path d="M{bx} 340 L{bx + 22} 380 L{bx} 430 L{bx - 22} 380 Z" fill="none" stroke="#c9a0ff" stroke-width="3"/>
<path d="M{bx - 12} 372 L{bx} 352 L{bx + 12} 372 M{bx} 352 L{bx} 412" fill="none" stroke="#c9a0ff" stroke-width="2.5"/>
</g>
'''
for lx, ly in [(330 + OX, 380), (930 + OX, 392)]:
    body += f'''<g stroke="{INK}" stroke-width="2.2"><rect x="{lx - 4}" y="{ly}" width="8" height="{556 - ly}" fill="#2c2018"/>
<path d="M{lx} {ly} L{lx + 30} {ly} L{lx + 30} {ly + 10}" fill="none" stroke="#2c2018" stroke-width="5"/>
<path d="M{lx + 20} {ly + 10} L{lx + 40} {ly + 10} L{lx + 37} {ly + 42} L{lx + 23} {ly + 42} Z" fill="#ffd27a"/></g>
<circle cx="{lx + 30}" cy="{ly + 26}" r="70" fill="url(#warm)"/>\n'''
body += f'<g stroke="{INK}" stroke-width="2"><ellipse cx="{1040 + OX}" cy="534" rx="22" ry="8" fill="#4a3424"/><rect x="{1018 + OX}" y="500" width="44" height="34" fill="#5a4030"/><path d="M{1018 + OX} 512 L{1062 + OX} 512 M{1018 + OX} 524 L{1062 + OX} 524" stroke="#2c2018" stroke-width="3"/></g>\n'
svg("forest_mid", body, defs, "grands pins, tour de guet éclairée, palissade, bannière, lanternes")

# 5. Arbres de cadrage ---------------------------------------------------------------
random.seed(29)
body = ""
for side in (0, 1):
    x = 30 if side == 0 else W - 30
    s = 1 if side == 0 else -1
    body += f'<path d="M{x - 40 * s} {H} Q{x - 30 * s} 400 {x - 50 * s} 0 L{x + 70 * s} 0 Q{x + 50 * s} 380 {x + 66 * s} {H} Z" fill="#0a0f19" stroke="{INK}" stroke-width="3"/>\n'
    body += f'<path d="M{x + 40 * s} 20 Q{x + 36 * s} 380 {x + 56 * s} {H}" stroke="#2d4266" stroke-width="5" fill="none" opacity="0.8"/>\n'
    for k in range(5):
        y = 40 + k * 30
        body += f'<ellipse cx="{x + (90 + k * 40) * s}" cy="{y}" rx="{120 - k * 10}" ry="{38 - k * 3}" fill="#0b1422" stroke="{INK}" stroke-width="2"/>\n'
        body += f'<path d="M{x + (40 + k * 40) * s} {y - 20} Q{x + (110 + k * 40) * s} {y - 34} {x + (190 + k * 40) * s} {y - 10}" stroke="#34507c" stroke-width="3" fill="none" opacity="0.7"/>\n'
svg("trees_near", body, "", "troncs et feuillages de cadrage, liseré de lune")

# 6. Sol de la clairière ------------------------------------------------------------
random.seed(31)
defs = CGLOW + ('<linearGradient id="gr" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a3a3c"/><stop offset="0.3" stop-color="#2c3532"/><stop offset="1" stop-color="#161b1c"/></linearGradient>'
                '<radialGradient id="moonlit" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#6c7f86" stop-opacity="0.7"/><stop offset="1" stop-color="#6c7f86" stop-opacity="0"/></radialGradient>'
                '<radialGradient id="path" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#5a5244" stop-opacity="0.8"/><stop offset="1" stop-color="#5a5244" stop-opacity="0"/></radialGradient>')
body = f'<path d="M0 520 Q340 500 680 512 T{W} 516 L{W} {H} L0 {H} Z" fill="url(#gr)"/>\n'
body += f'<ellipse cx="{700 + OX}" cy="610" rx="600" ry="120" fill="url(#path)"/>\n<ellipse cx="{760 + OX}" cy="580" rx="420" ry="80" fill="url(#moonlit)"/>\n'
for i in range(220):
    y = random.uniform(520, H)
    x = random.uniform(0, W)
    s = 2 + (y - 520) / 240 * 10
    c = random.choice(["#3e5a4a", "#4a6a54", "#355046"])
    body += f'<path d="M{x:.0f} {y:.0f} l{-s * .7:.1f} {-s * 2:.1f} M{x:.0f} {y:.0f} l{s * .2:.1f} {-s * 2.5:.1f} M{x:.0f} {y:.0f} l{s:.1f} {-s * 1.7:.1f}" stroke="{c}" stroke-width="{1 + s * .2:.1f}" stroke-linecap="round"/>\n'
    if random.random() < .25:
        body += f'<path d="M{x + s * .2:.0f} {y - s * 2.5:.0f} l{s * .1:.1f} {s * .8:.1f}" stroke="#8fb0c8" stroke-width="1" opacity="0.6"/>\n'
for i in range(30):
    y = random.uniform(530, H - 10)
    x = random.uniform(0, W)
    s = 4 + (y - 520) / 240 * 13
    body += f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="{s * 1.4:.1f}" ry="{s * .65:.1f}" fill="#454b52" stroke="{INK}" stroke-width="2"/><ellipse cx="{x + s * .3:.0f}" cy="{y - s * .25:.0f}" rx="{s * .6:.1f}" ry="{s * .2:.1f}" fill="#8d9aaa" opacity="0.6"/>\n'
for cx, cy, s in [(130 + OX, 600, 34), (560 + OX, 548, 22), (1210 + OX, 590, 30), (980 + OX, 556, 18)]:
    body += crystal(cx, cy, s) + "\n"
for cx, cy, s in [(420 + OX, 560, 16), (1100 + OX, 548, 14)]:
    body += crystal(cx, cy, s, "#e2ccff", "#a07ae8", "#5a3aa8") + "\n"
svg("ground", body, defs, "sol de la clairière éclairé par la lune, herbes, pierres, cristaux")

# 7. Premier plan ------------------------------------------------------------------
random.seed(37)
body = ""
for side in (0, 1):
    for i in range(18):
        x = random.uniform(0, 300) if side == 0 else random.uniform(W - 300, W)
        y = random.uniform(700, 780)
        h = random.uniform(60, 150)
        lean = random.uniform(-40, 40)
        body += f'<path d="M{x:.0f} {y:.0f} Q{x + lean * .4:.0f} {y - h * .6:.0f} {x + lean:.0f} {y - h:.0f} Q{x + lean * .2 + 8:.0f} {y - h * .5:.0f} {x + 14:.0f} {y:.0f} Z" fill="#0b1712" stroke="{INK}" stroke-width="2"/>\n'
    rx = 110 if side == 0 else W - 110
    body += f'<path d="M{rx - 150} 800 Q{rx - 110} 680 {rx} 690 Q{rx + 110} 700 {rx + 160} 800 Z" fill="#141a20" stroke="{INK}" stroke-width="3"/>\n'
body += crystal(260, 760, 46, glow=False) + "\n" + crystal(W - 240, 770, 40, "#e2ccff", "#a07ae8", "#5a3aa8", glow=False)
svg("front", body, CGLOW, "premier plan : fougères, rochers, cristaux (devant les personnages)")

# 8. Rayons de lune (additifs) ------------------------------------------------------
body = ""
for i, (x0, w0) in enumerate([(820, 60), (930, 40), (700, 80), (1010, 50), (600, 50)]):
    x0 += OX
    a = [(mx - 30 + i * 8, my + 40), (mx + 10 + i * 8, my + 40), (x0 - 260 + w0, 760), (x0 - 260 - w0, 760)]
    pts = " ".join(f"{x:.0f},{y:.0f}" for x, y in a)
    body += f'<polygon points="{pts}" fill="url(#ray)" opacity="{0.55 - i * 0.07:.2f}"/>\n'
defs = '<linearGradient id="ray" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#cfe0ff" stop-opacity="0.0"/><stop offset="0.25" stop-color="#cfe0ff" stop-opacity="0.22"/><stop offset="1" stop-color="#cfe0ff" stop-opacity="0.0"/></linearGradient>'
svg("rays", body, defs, "rayons de lune (affichés en mode additif)")
print("arène HD générée")
