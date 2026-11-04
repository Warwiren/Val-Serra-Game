"""Génère le Vorgane des brumes « HD » articulé : calques sur un canevas commun 760×540 (tourné vers la gauche),
+ la fiche data/rig/vorgane_hd.json (os, pivots, parties ciblables, éclats de rupture).
Usage : python3 tools/art/gen_vorgane_hd.py   (depuis la racine du projet)

Structure attendue d'un monstre final : corps, tête, mâchoire, patte avant, griffe, queue, et pour chaque partie
ciblable son état intact, son état brisé et, si elle doit éclater, ses éclats séparés + la plaie dessous."""
import json, math, os

W, H = 760, 540
OUT = "art/hd/vorgane"
os.makedirs(OUT, exist_ok=True)
INK = "#120d1c"
SW = 3.2

FUR, FUR_S, FUR_D, FUR_H, MANE = "#33284e", "#211936", "#170f28", "#5a4789", "#7a64bf"
CRY_L, CRY_M, CRY_D, CRY_E = "#d8ccff", "#8a72ea", "#3f2c98", "#a8f1ff"
BONE, BONE_S = "#ece4f4", "#a598b8"
FLESH, FLESH_S = "#c2405f", "#7e2140"
AETH = "#6ff0ff"

DEFS = f'''<defs>
<linearGradient id="fur" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{FUR_H}"/><stop offset="0.45" stop-color="{FUR}"/><stop offset="1" stop-color="{FUR_D}"/></linearGradient>
<linearGradient id="furd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{FUR_S}"/><stop offset="1" stop-color="#0f0a1c"/></linearGradient>
<linearGradient id="cry" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{CRY_L}"/><stop offset="0.5" stop-color="{CRY_M}"/><stop offset="1" stop-color="{CRY_D}"/></linearGradient>
<linearGradient id="cry2" x1="1" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b9f6ff"/><stop offset="0.5" stop-color="#6aa6f0"/><stop offset="1" stop-color="#2c3f9a"/></linearGradient>
<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffffff"/><stop offset="0.35" stop-color="#a6f6ff"/><stop offset="0.8" stop-color="#22b4d8"/><stop offset="1" stop-color="#11607a"/></radialGradient>
<radialGradient id="halo" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="{AETH}" stop-opacity="0.6"/><stop offset="1" stop-color="{AETH}" stop-opacity="0"/></radialGradient>
<linearGradient id="flesh" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#a5354e"/><stop offset="0.6" stop-color="#6e1d36"/><stop offset="1" stop-color="#3e0f22"/></linearGradient>
</defs>'''


def svg(name, body, note):
    open(f"{OUT}/{name}.svg", "w").write(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">\n'
        f'<!-- Vorgane HD — calque « {name} » : {note}. Canevas commun {W}x{H}, tourné vers la gauche. -->\n'
        f'{DEFS}\n<g stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round" stroke-linecap="round">\n{body}\n</g>\n</svg>\n')


def P(pts):
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)


def zig(p0, p1, n, amp, side=1):
    """Bordure en dents de scie (touffes de fourrure) entre deux points."""
    (x0, y0), (x1, y1) = p0, p1
    dx, dy = x1 - x0, y1 - y0
    L = math.hypot(dx, dy) or 1
    nx, ny = -dy / L * side, dx / L * side
    pts = []
    for i in range(n + 1):
        t = i / n
        x, y = x0 + dx * t, y0 + dy * t
        if i % 2 == 1:
            x, y = x + nx * amp, y + ny * amp
        pts.append((x, y))
    return pts


# --- Queue -------------------------------------------------------------------
tail = f'''<path d="M600 220 Q680 190 712 130 Q728 98 716 70 Q744 96 742 140 Q736 200 690 236 Q650 262 612 262 Z" fill="url(#fur)"/>
<path d="M612 250 Q660 240 700 200 Q724 170 730 130 Q738 170 712 212 Q676 250 620 262 Z" fill="{FUR_S}" stroke="none"/>
<polygon points="704,118 724,64 734,112" fill="url(#cry)"/>
<polygon points="686,160 716,120 718,166" fill="url(#cry2)"/>
<polygon points="660,196 690,166 690,206" fill="url(#cry)"/>'''
svg("tail", tail, "queue, pivot à la base")

# --- Corps (pattes lointaines, tronc, patte arrière proche) -----------------------
belly = zig((640, 330), (300, 392), 22, 12, side=-1)
body = f'''<path d="M330 318 Q356 400 352 488 L392 488 Q392 410 380 330 Z" fill="url(#furd)"/>
<path d="M336 482 L398 482 L404 504 L330 504 Z" fill="{FUR_D}"/>
<path d="M512 300 Q540 400 520 488 L558 490 Q572 400 552 300 Z" fill="url(#furd)"/>
<path d="M512 484 L568 484 L574 506 L506 506 Z" fill="{FUR_D}"/>
<path d="M250 300 Q262 210 330 170 Q420 128 520 150 Q600 166 638 222 Q664 270 640 330 L{P(belly)} Q246 384 230 346 Q224 322 250 300 Z" fill="url(#fur)"/>
<path d="M262 330 Q300 372 380 380 Q480 386 600 350 Q620 340 636 318 Q630 360 600 372 L{P(zig((600, 372), (300, 390), 16, 9, side=-1))} Q262 372 262 330 Z" fill="{FUR_S}" stroke="none"/>
<path d="M330 186 Q420 150 520 166 Q590 180 626 226" fill="none" stroke="{FUR_H}" stroke-width="4" opacity="0.7"/>
<path d="M560 230 Q640 230 656 300 Q664 360 640 420 Q624 460 612 492 L566 492 Q590 440 586 392 Q578 340 540 310 Z" fill="url(#fur)"/>
<path d="M590 300 Q630 330 630 380 Q626 420 610 460" fill="none" stroke="{FUR_H}" stroke-width="3" opacity="0.7"/>
<path d="M556 486 L630 486 Q646 496 648 512 L548 512 Q548 496 556 486 Z" fill="{FUR_D}"/>
<path d="M560 512 L554 524 M584 512 L582 526 M610 512 L612 526 M634 512 L640 524" fill="none" stroke="{BONE}" stroke-width="5"/>
<path d="M300 250 Q330 262 352 252 M380 300 Q420 316 460 300 M470 230 Q500 244 530 236" fill="none" stroke="{AETH}" stroke-width="2.4" opacity="0.85"/>
<path d="M300 250 Q330 262 352 252 M380 300 Q420 316 460 300 M470 230 Q500 244 530 236" fill="none" stroke="#ffffff" stroke-width="0.8" opacity="0.9"/>'''
svg("body", body, "tronc, pattes lointaines, patte arrière proche, runes")

# --- Plaie sous la carapace (visible après rupture) ------------------------------
wound = f'''<path d="M296 196 Q340 150 420 146 Q520 140 590 196 Q560 226 470 224 Q370 226 296 196 Z" fill="url(#flesh)"/>
<path d="M330 188 Q370 176 400 186 M440 170 Q480 162 520 176 M540 196 Q560 192 576 200" fill="none" stroke="#d8607a" stroke-width="2.5"/>
<polygon points="318,196 326,176 336,198" fill="url(#cry)"/>
<polygon points="402,182 414,160 424,184" fill="url(#cry2)"/>
<polygon points="478,176 486,158 498,178" fill="url(#cry)"/>
<polygon points="552,200 560,184 570,204" fill="url(#cry2)"/>
<path d="M300 198 Q340 214 400 216" fill="none" stroke="{AETH}" stroke-width="2" opacity="0.7"/>
<path d="M360 196 L372 214 M470 186 L462 206 M520 200 L532 216" fill="none" stroke="{FLESH_S}" stroke-width="3"/>'''
svg("wound", wound, "plaie exposée sous la carapace")

# --- Éclats de carapace (7 calques séparés) --------------------------------------
SHARDS = [
    [(286, 210), (306, 150), (344, 170), (336, 218)],
    [(330, 182), (352, 108), (392, 132), (384, 190)],
    [(380, 170), (412, 96), (446, 126), (432, 182)],
    [(424, 160), (466, 76), (500, 120), (478, 176)],
    [(470, 168), (520, 104), (548, 150), (520, 192)],
    [(512, 182), (562, 136), (584, 184), (556, 210)],
    [(548, 200), (598, 172), (612, 214), (584, 232)],
]
shard_info = []
for i, pts in enumerate(SHARDS):
    cx = sum(p[0] for p in pts) / 4
    cy = sum(p[1] for p in pts) / 4
    top = min(pts, key=lambda p: p[1])
    facet = [pts[0], top, (cx, cy)]
    grad = "cry" if i % 2 == 0 else "cry2"
    body_s = f'''<polygon points="{P(pts)}" fill="url(#{grad})"/>
<polygon points="{P(facet)}" fill="{CRY_L}" opacity="0.55" stroke="none"/>
<polyline points="{P([pts[1], pts[2]])}" fill="none" stroke="{CRY_E}" stroke-width="2.4"/>
<polyline points="{P([(cx, cy), top])}" fill="none" stroke="#ffffff" stroke-width="1.5" opacity="0.8"/>'''
    svg(f"plate_{i}", body_s, f"éclat de carapace n°{i + 1}")
    shard_info.append({"file": f"plate_{i}", "center": [round(cx, 1), round(cy, 1)]})

# --- Glande d'Aether ----------------------------------------------------------------
gland = f'''<circle cx="330" cy="262" r="58" fill="url(#halo)" stroke="none"/>
<path d="M296 262 Q300 228 332 226 Q366 230 368 262 Q366 296 332 300 Q300 296 296 262 Z" fill="url(#glow)"/>
<circle cx="332" cy="263" r="22" fill="none" stroke="#e8feff" stroke-width="2.5"/>
<path d="M312 250 Q332 238 352 250" fill="none" stroke="#ffffff" stroke-width="2"/>'''
svg("gland", gland, "glande d'Aether (intacte)")
gland_b = f'''<path d="M300 264 Q304 234 332 232 Q362 236 364 264 Q362 292 332 296 Q304 292 300 264 Z" fill="#3a4656"/>
<path d="M318 240 L332 262 L322 276 L340 294 M350 246 L340 264" fill="none" stroke="{AETH}" stroke-width="2.4"/>'''
svg("gland_broken", gland_b, "glande d'Aether (brisée, éteinte)")

# --- Tête et mâchoire -----------------------------------------------------------------
head = f'''<path d="M330 200 Q300 230 300 290 Q270 306 236 300 Q190 306 150 300 Q110 300 70 290 Q50 286 46 274 Q56 258 92 248 Q140 230 176 212 Q214 190 256 186 Q300 182 330 200 Z" fill="url(#fur)"/>
<path d="M300 290 Q268 304 236 300 Q190 306 150 300 Q190 290 236 288 Q270 284 300 270 Z" fill="{FUR_S}" stroke="none"/>
<path d="M92 248 Q140 236 176 220" fill="none" stroke="{FUR_H}" stroke-width="3.5" opacity="0.8"/>
<path d="M46 274 Q40 268 50 262 Q60 262 62 270 Z" fill="#0d0a14"/>
<polyline points="{P(zig((330, 200), (300, 300), 8, 14, side=-1))}" fill="{MANE}" stroke="{INK}"/>
<path d="M232 196 Q248 150 286 128 Q268 176 262 204 Z" fill="{FUR_S}"/>
<polygon points="214,196 236,132 252,196" fill="url(#cry)"/>
<polygon points="244,190 282,126 284,194" fill="url(#cry2)"/>
<polygon points="190,206 200,166 214,204" fill="url(#cry)"/>
<path d="M134 250 Q150 238 170 246 Q154 258 134 250 Z" fill="#dffcff" stroke-width="2"/>
<circle cx="154" cy="248" r="20" fill="url(#halo)" stroke="none"/>
<path d="M110 250 Q140 236 184 236" fill="none" stroke="{INK}" stroke-width="4"/>
<path d="M60 290 L70 302 L78 290 L88 304 L98 292 L108 306 L118 294 L128 306 L138 296" fill="{BONE}" stroke-width="2"/>
<path d="M200 266 Q230 276 260 268" fill="none" stroke="{AETH}" stroke-width="2.2" opacity="0.85"/>'''
svg("head", head, "tête, cornes de cristal, œil, crocs supérieurs ; pivot au cou")
jaw = f'''<path d="M220 300 Q170 312 120 310 Q86 308 66 298 Q72 318 96 326 Q150 336 220 322 Z" fill="url(#furd)"/>
<path d="M76 300 L84 290 L92 302 L102 290 L110 304 L120 292 L130 306" fill="{BONE}" stroke-width="2"/>'''
svg("jaw", jaw, "mâchoire inférieure ; pivot à la charnière")

# --- Patte avant proche et griffe -----------------------------------------------------
arm = f'''<path d="M352 252 Q386 300 360 352 Q330 410 282 446 L236 440 Q262 400 280 352 Q290 300 300 262 Z" fill="url(#fur)"/>
<path d="M300 262 Q292 318 280 352 Q262 400 236 440 L252 444 Q284 404 300 352 Q312 304 318 266 Z" fill="{FUR_S}" stroke="none"/>
<path d="M346 270 Q364 304 352 336" fill="none" stroke="{FUR_H}" stroke-width="3.5" opacity="0.8"/>
<polyline points="{P(zig((356, 340), (312, 400), 6, 12))}" fill="{MANE}" stroke="{INK}"/>'''
svg("arm", arm, "patte avant proche (épaule → poignet)")
claw = f'''<path d="M234 432 Q262 424 290 440 Q300 466 286 488 L214 494 Q200 470 214 446 Z" fill="url(#fur)"/>
<path d="M214 494 L286 488 Q280 498 268 500 L222 504 Z" fill="{FUR_D}"/>
<path d="M216 470 Q170 470 140 500 Q176 488 214 490 Z" fill="{BONE}"/>
<path d="M226 480 Q190 488 168 518 Q200 504 232 498 Z" fill="{BONE}"/>
<path d="M246 486 Q222 500 214 524 Q238 510 256 500 Z" fill="{BONE}"/>
<path d="M150 494 Q176 484 206 484 M176 510 Q200 496 224 494" fill="none" stroke="{BONE_S}" stroke-width="2"/>'''
svg("claw", claw, "griffe (intacte)")
claw_b = f'''<path d="M234 432 Q262 424 290 440 Q300 466 286 488 L214 494 Q200 470 214 446 Z" fill="url(#furd)"/>
<path d="M216 472 L196 478 L206 490 Z" fill="{BONE_S}"/>
<path d="M226 482 L208 494 L224 498 Z" fill="{BONE_S}"/>
<path d="M246 488 L236 502 L252 500 Z" fill="{BONE_S}"/>
<path d="M240 440 L252 458 L242 470 L258 486" fill="none" stroke="#ff6a7e" stroke-width="3"/>
<circle cx="202" cy="484" r="5" fill="{FLESH}" stroke="none"/>
<circle cx="216" cy="496" r="4" fill="{FLESH}" stroke="none"/>'''
svg("claw_broken", claw_b, "griffe (brisée : serres arrachées)")

# --- Fiche ------------------------------------------------------------------------------
rig = {
    "_note": "Squelette du Vorgane HD. pivot = articulation (pixels du canevas). anchor = point de ciblage de la partie.",
    "canvas": [W, H],
    "feet": [440, 510],
    "bones": [
        {"name": "root", "parent": "", "pivot": [440, 320]},
        {"name": "tail", "parent": "root", "pivot": [612, 236]},
        {"name": "head", "parent": "root", "pivot": [318, 236]},
        {"name": "jaw", "parent": "head", "pivot": [216, 306]},
        {"name": "arm", "parent": "root", "pivot": [326, 262]},
        {"name": "paw", "parent": "arm", "pivot": [258, 444]},
    ],
    "layers": [
        {"file": "tail", "bone": "tail"},
        {"file": "body", "bone": "root"},
        {"file": "wound", "bone": "root", "hidden": True, "role": "wound"},
        {"file": "jaw", "bone": "jaw"},
        {"file": "head", "bone": "head"},
        {"file": "arm", "bone": "arm"},
        {"file": "claw", "bone": "paw", "part": "griffe", "broken": "claw_broken"},
        {"file": "gland", "bone": "root", "part": "glande", "broken": "gland_broken"},
    ] + [{"file": s["file"], "bone": "root", "part": "carapace", "shard": True, "center": s["center"]} for s in shard_info],
    "anchors": {"griffe": [226, 478], "carapace": [450, 150], "glande": [332, 262]},
    "mouth": [70, 300],
    "art_dir": "res://" + OUT,
}
json.dump(rig, open("data/rig/vorgane_hd.json", "w"), indent=1, ensure_ascii=False)
print("Vorgane HD généré :", len(rig["layers"]), "calques")
