"""Génère les accessoires de l'avant-poste (zone d'exploration). Pied de chaque objet = bas du fichier.
Usage : python3 tools/art/gen_zone.py   (depuis la racine du projet)"""
import os
OUT = "art/zone"
os.makedirs(OUT, exist_ok=True)
INK = "#11171b"
def svg(w, h, body, defs="", note=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">\n'
            f'  <!-- {note} -->\n  <defs>{defs}</defs>\n  <g stroke="{INK}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">\n{body}  </g>\n</svg>\n')

house = '''    <path d="M30 300 L30 150 L270 150 L270 300 Z" fill="url(#wall)"/>
    <path d="M30 150 L270 150 M30 200 L270 200 M30 250 L270 250 M90 150 L90 300 M210 150 L210 300" fill="none" stroke="#3a2a1c" stroke-width="6"/>
    <path d="M10 156 L150 40 L290 156 Z" fill="url(#roof)"/>
    <path d="M40 130 L150 52 L260 130" fill="none" stroke="#5a2a20" stroke-width="3"/>
    <rect x="128" y="214" width="46" height="86" rx="4" fill="#3a2618"/>
    <circle cx="164" cy="258" r="3" fill="#c49a5a"/>
    <rect x="52" y="208" width="30" height="30" fill="url(#win)"/>
    <rect x="222" y="208" width="30" height="30" fill="url(#win)"/>
    <path d="M67 208 L67 238 M52 223 L82 223 M237 208 L237 238 M222 223 L252 223" fill="none" stroke-width="2"/>
    <rect x="200" y="60" width="26" height="60" fill="#5b5048"/>
    <path d="M118 170 L190 170 L190 196 L118 196 Z" fill="#6b4c32"/>
    <path d="M128 183 L180 183" fill="none" stroke="#e8d6a8" stroke-width="3"/>
'''
house_defs = ('<linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#cdb48a"/><stop offset="1" stop-color="#9c8461"/></linearGradient>'
              '<linearGradient id="roof" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#a14a34"/><stop offset="1" stop-color="#6e2c20"/></linearGradient>'
              '<radialGradient id="win" cx="0.5" cy="0.5" r="0.7"><stop offset="0" stop-color="#fff2c0"/><stop offset="1" stop-color="#f0a040"/></radialGradient>')
open(f"{OUT}/house.svg", "w").write(svg(300, 304, house, house_defs, "Maison de l'intendance (pied en bas)"))

crates = '''    <rect x="10" y="60" width="70" height="60" fill="#8a6440"/>
    <path d="M10 60 L80 120 M80 60 L10 120" fill="none" stroke="#5a3f28" stroke-width="4"/>
    <rect x="80" y="70" width="60" height="50" fill="#7a5636"/>
    <path d="M80 95 L140 95" fill="none" stroke="#5a3f28" stroke-width="4"/>
    <rect x="34" y="10" width="62" height="50" fill="#9a724a"/>
    <path d="M34 35 L96 35 M65 10 L65 60" fill="none" stroke="#5a3f28" stroke-width="4"/>
'''
open(f"{OUT}/crates.svg", "w").write(svg(150, 124, crates, "", "Pile de caisses"))

lantern = '''    <rect x="26" y="40" width="8" height="200" fill="#3a2a1c"/>
    <path d="M30 40 L60 40 L60 52" fill="none" stroke="#3a2a1c" stroke-width="5"/>
    <path d="M48 52 L72 52 L68 88 L52 88 Z" fill="url(#glass)"/>
    <path d="M46 52 L74 52 L60 42 Z" fill="#2a1d14"/>
    <path d="M14 240 L46 240 L40 228 L20 228 Z" fill="#3a2a1c"/>
'''
open(f"{OUT}/lantern.svg", "w").write(svg(80, 244, lantern,
    '<radialGradient id="glass" cx="0.5" cy="0.5" r="0.6"><stop offset="0" stop-color="#fff6d0"/><stop offset="1" stop-color="#f0a040"/></radialGradient>',
    "Lanterne sur poteau ; la flamme est en (60,70)"))

bench = '''    <rect x="10" y="60" width="170" height="16" fill="#7a5636"/>
    <path d="M24 76 L20 130 M166 76 L170 130" fill="none" stroke="#5a3f28" stroke-width="10"/>
    <path d="M40 60 L40 46 L80 46 L84 60 Z" fill="#6b7780"/>
    <path d="M110 60 L110 30 Q140 18 160 40 L150 60 Z" fill="#4b545b"/>
    <path d="M150 30 L170 6" fill="none" stroke="#3a2a1c" stroke-width="6"/>
    <circle cx="66" cy="38" r="8" fill="#5fe3ff" stroke-width="2"/>
'''
open(f"{OUT}/workbench.svg", "w").write(svg(190, 134, bench, "", "Établi de forge (Lot E : amélioration d'arme)"))

fence = ''.join(f'    <path d="M{x} 110 L{x} 20 L{x+9} 8 L{x+18} 20 L{x+18} 110 Z" fill="#6b4c32"/>\n' for x in range(6, 280, 26))
fence += '    <path d="M0 40 L300 40 M0 84 L300 84" fill="none" stroke="#4a3424" stroke-width="7"/>\n'
open(f"{OUT}/fence.svg", "w").write(svg(300, 112, fence, "", "Palissade"))
print("accessoires générés")
