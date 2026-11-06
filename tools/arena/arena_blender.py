"""Arène de combat « Lisière de l'avant-poste » au crépuscule — pilote de la refonte des décors de combat.
Même méthode hybride que l'exploration (tools/explore/scene_blender.py) : volumes, matières, lumière et ombres
dans Blender, puis passe pixel (arena_paint.py). Mêmes matières et même éclairage (lune froide, contre-jour
violet, lanternes chaudes), mais CAMÉRA DE COMBAT : vue latérale trois-quarts, légèrement plongeante, en
perspective longue focale. Ce n'est pas la vue d'exploration recadrée.

Composition imposée par le combat existant (positions écran inchangées, ×3 pixels) :
  Vorgane au sol en (330, 506), Chasseurs en (900, 500), (1028, 468), (1150, 492) ;
  HUD : bandeau d'initiative en haut, panneaux du groupe en haut à droite, panneaux d'action sous y = 550.

Sorties (<out>/) : un rendu par PLAN, chacun complet (non coupé par les plans plus proches) pour permettre une
parallaxe légère sans trou :
  base.png   ciel + sol + petits détails au sol (ombres de tous les objets comprises)
  loin.png   forêt lointaine, crête (alpha)
  lisiere.png  lisière, palissade et maison de l'avant-poste, grand arbre, rochers (alpha)
  avant.png  premier plan sombre qui cadre le bas de l'image (alpha)
  apercu.png scène complète
  layout.json  lanternes (pour l'éclairage Godot et celui du Vorgane), ligne de combat, échelle
Usage : python arena_blender.py <dossier_sortie> [SS=3] [échantillons=48]"""
import json, math, os, random, sys
import bpy
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

OUT = sys.argv[1]
SS = int(sys.argv[2]) if len(sys.argv) > 2 else 3
SAMPLES = int(sys.argv[3]) if len(sys.argv) > 3 else 48
NW, NH = 432, 244                       # natif (affichage ×3 = 1296×732, centré sur 1280×720 : marge de parallaxe)
os.makedirs(OUT, exist_ok=True)
random.seed(21)
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
LAYER = {}                              # objet -> plan


def put(o, layer):
    LAYER[o] = layer
    return o


# ------------------------------------------------------------------------------------------------ matériaux
# (mêmes définitions que l'exploration, pour la cohérence des matières)
def mat(name, col, rough=0.9, tex=None, scale=5.0, col2=None, noise=0.35, emit=None, estr=0.0, bump=0.0, gloss=False):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; b = nt.nodes["Principled BSDF"]; b.inputs["Roughness"].default_value = rough
    base = None
    if tex == "brick":
        t = nt.nodes.new("ShaderNodeTexBrick"); t.inputs["Scale"].default_value = scale
        t.inputs["Color1"].default_value = (*col, 1); t.inputs["Color2"].default_value = (*(col2 or col), 1)
        t.inputs["Mortar"].default_value = (col[0] * 0.3, col[1] * 0.3, col[2] * 0.35, 1)
        t.inputs["Mortar Size"].default_value = 0.03; t.inputs["Bias"].default_value = 0.2
        base = t.outputs["Color"]
    elif tex == "planks":
        t = nt.nodes.new("ShaderNodeTexWave"); t.inputs["Scale"].default_value = scale; t.inputs["Distortion"].default_value = 3
        r = nt.nodes.new("ShaderNodeValToRGB")
        r.color_ramp.elements[0].color = (col[0] * 0.55, col[1] * 0.55, col[2] * 0.55, 1); r.color_ramp.elements[1].color = (*col, 1)
        nt.links.new(t.outputs["Fac"], r.inputs["Fac"]); base = r.outputs["Color"]
    elif tex == "voronoi":
        t = nt.nodes.new("ShaderNodeTexVoronoi"); t.inputs["Scale"].default_value = scale
        r = nt.nodes.new("ShaderNodeValToRGB")
        r.color_ramp.elements[0].color = (*(col2 or col), 1); r.color_ramp.elements[1].color = (*col, 1)
        nt.links.new(t.outputs["Distance"], r.inputs["Fac"]); base = r.outputs["Color"]
    if base is not None or noise:
        n = nt.nodes.new("ShaderNodeTexNoise"); n.inputs["Scale"].default_value = scale * 2.2; n.inputs["Detail"].default_value = 6
        mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"
        mix.inputs["Factor"].default_value = noise
        if base is not None:
            nt.links.new(base, mix.inputs["A"])
        else:
            mix.inputs["A"].default_value = (*col, 1)
        nt.links.new(n.outputs["Color"], mix.inputs["B"])
        nt.links.new(mix.outputs["Result"], b.inputs["Base Color"])
        if bump:
            bm = nt.nodes.new("ShaderNodeBump"); bm.inputs["Strength"].default_value = bump
            nt.links.new(n.outputs["Fac"], bm.inputs["Height"]); nt.links.new(bm.outputs["Normal"], b.inputs["Normal"])
    else:
        b.inputs["Base Color"].default_value = (*col, 1)
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1); b.inputs["Emission Strength"].default_value = estr
    if gloss:
        b.inputs["Roughness"].default_value = 0.08; b.inputs["Specular IOR Level"].default_value = 0.9
    return m


GRASS = mat("herbe", (0.19, 0.31, 0.21), tex="voronoi", scale=3, col2=(0.07, 0.15, 0.12), noise=0.5, bump=0.4)
DIRT = mat("terre", (0.26, 0.20, 0.17), noise=0.5, bump=0.3)
TRAMPLED = mat("terre_battue", (0.30, 0.25, 0.22), tex="voronoi", scale=6, col2=(0.22, 0.18, 0.17), noise=0.5, bump=0.5)
PATH = mat("paves", (0.42, 0.39, 0.42), tex="brick", scale=3.5, col2=(0.33, 0.30, 0.34), noise=0.45, bump=0.6)
STONE = mat("pierre", (0.34, 0.33, 0.37), tex="brick", scale=4, col2=(0.25, 0.24, 0.29), noise=0.5, bump=0.8)
ROCK = mat("roche", (0.30, 0.30, 0.35), noise=0.6, bump=1.2)
PLASTER = mat("enduit", (0.62, 0.55, 0.45), noise=0.45, bump=0.3)
BEAM = mat("poutre", (0.20, 0.12, 0.08), tex="planks", scale=3)
WOOD = mat("bois", (0.33, 0.21, 0.12), tex="planks", scale=4)
LOG = mat("rondin", (0.27, 0.18, 0.12), tex="planks", scale=7)
ROOF = mat("ardoise", (0.24, 0.23, 0.33), tex="brick", scale=11, col2=(0.15, 0.14, 0.23), noise=0.6, bump=0.8)
MOSS = mat("mousse", (0.16, 0.24, 0.12), noise=0.6)
GLASS = mat("vitre", (1.0, 0.62, 0.28), emit=(1.0, 0.6, 0.26), estr=2.4)
FLAME = mat("flamme", (1.0, 0.7, 0.35), emit=(1.0, 0.68, 0.32), estr=14.0)
IRON = mat("fer", (0.07, 0.07, 0.09), rough=0.5, noise=0)
LEAF = [mat("feuilles_%d" % i, c, noise=0.55, bump=0.6) for i, c in enumerate([(0.10, 0.22, 0.17), (0.13, 0.27, 0.19), (0.08, 0.17, 0.15)])]
LEAF_DARK = mat("feuilles_ombre", (0.05, 0.10, 0.10), noise=0.5)
BARK = mat("ecorce", (0.18, 0.13, 0.12), tex="planks", scale=6)
FOREST = mat("foret", (0.07, 0.09, 0.15), noise=0.3)
FOREST_FAR = mat("foret_loin", (0.15, 0.15, 0.27), noise=0.2)
FLOWER = [mat("fleur_%d" % i, c, noise=0) for i, c in enumerate([(0.55, 0.32, 0.85), (0.85, 0.82, 0.95)])]
CLOTH = mat("tissu", (0.18, 0.2, 0.42), noise=0.3)
WATER = mat("flaque", (0.05, 0.06, 0.10), gloss=True, noise=0)


def box(size, loc, m, layer, rot=(0, 0, 0), bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object; o.scale = size; bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(m)
    if bevel:
        mod = o.modifiers.new("b", "BEVEL"); mod.width = bevel; mod.segments = 2
    return put(o, layer)


def cyl(r, h, loc, m, layer, verts=10, rot=(0, 0, 0), r2=None):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, location=loc, vertices=verts, rotation=rot)
    else:
        bpy.ops.mesh.primitive_cone_add(radius1=r, radius2=r2, depth=h, location=loc, vertices=verts, rotation=rot)
    o = bpy.context.active_object; o.data.materials.append(m)
    return put(o, layer)


def blob(r, loc, m, layer, sub=2, disp=0.35, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=r, location=loc, subdivisions=sub)
    o = bpy.context.active_object; o.scale = scale; o.data.materials.append(m)
    bpy.ops.object.shade_smooth()
    tx = bpy.data.textures.new("n", "CLOUDS"); tx.noise_scale = r * 0.6
    d = o.modifiers.new("d", "DISPLACE"); d.texture = tx; d.strength = r * disp
    return put(o, layer)


def plane(size, loc, m, layer, sub=24, z_amp=0.0, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=sub, y_subdivisions=sub, size=1, location=loc, rotation=rot)
    o = bpy.context.active_object; o.scale = (size[0], size[1], 1); bpy.ops.object.transform_apply(scale=True)
    for v in o.data.vertices:
        v.co.z += random.uniform(-z_amp, z_amp)
    o.data.materials.append(m)
    return put(o, layer)


# ------------------------------------------------------------------------------------------------ sol de combat
# Repère : x vers la droite de l'écran, y en profondeur (loin), z vers le haut. Ligne de combat vers y = 0.
plane((110, 100), (0, 20, 0), GRASS, "base", sub=70, z_amp=0.02)
# aire de combat : terre battue piétinée, irrégulière (lit l'espace central sans le surcharger)
for i in range(16):
    x = random.uniform(-9, 9); y = random.uniform(-2.2, 2.6)
    blob(random.uniform(1.6, 2.6), (x, y, -0.62), TRAMPLED, "base", sub=2, disp=0.15, scale=(1.6, 1.0, 0.3))
# chemin pavé qui sort de la porte de l'avant-poste (droite) et traverse vers l'avant gauche
PATH_PTS = [(14, 9), (9.5, 4.5), (5.5, 1.2), (0, -1.8), (-8, -4.5), (-16, -6.5)]
for (x0, y0), (x1, y1) in zip(PATH_PTS[:-1], PATH_PTS[1:]):
    L = math.hypot(x1 - x0, y1 - y0); a = math.atan2(y1 - y0, x1 - x0)
    box((L + 0.6, 2.8, 0.1), ((x0 + x1) / 2, (y0 + y1) / 2, 0.02), DIRT, "base", rot=(0, 0, a))
    box((L + 0.3, 2.0, 0.1), ((x0 + x1) / 2, (y0 + y1) / 2, 0.05), PATH, "base", rot=(0, 0, a))
for (x0, y0) in PATH_PTS:
    cyl(1.4, 0.1, (x0, y0, 0.03), DIRT, "base", verts=16)
    cyl(1.0, 0.1, (x0, y0, 0.06), PATH, "base", verts=16)
# flaques : reflets des lanternes et du ciel (entre les combattants, au premier plan)
for (x, y, s) in [(2.2, -3.2, 1.0), (-1.5, -4.6, 0.7), (11.5, -3.4, 0.8)]:
    blob(s, (x, y, -0.1), WATER, "base", sub=3, disp=0.05, scale=(2.0, 1.0, 0.12))
# herbes, fleurs et cailloux semés (hors aire centrale)
for k in range(700):
    x, y = random.uniform(-22, 22), random.uniform(-6, 16)
    centre = abs(x) < 9.5 and -2.6 < y < 3.0
    if centre and random.random() < 0.85:
        continue
    if random.random() < 0.7:
        bpy.ops.mesh.primitive_cone_add(radius1=0.06, depth=random.uniform(0.18, 0.4), location=(x, y, 0.1), vertices=4,
                                        rotation=(random.uniform(-0.3, 0.3), random.uniform(-0.3, 0.3), 0))
        o = bpy.context.active_object; o.data.materials.append(random.choice(LEAF)); put(o, "base")
    else:
        blob(0.07, (x, y, 0.15), random.choice(FLOWER), "base", sub=1, disp=0.2)
for k in range(24):
    x, y = random.uniform(-20, 20), random.uniform(-8, 12)
    blob(random.uniform(0.12, 0.3), (x, y, 0.04), STONE, "base", sub=2, disp=0.3, scale=(1.3, 1.0, 0.6))

# ------------------------------------------------------------------------------------------------ avant-poste (droite)
# palissade de rondins taillés en pointe, en biais vers le fond, avec une porte et deux lanternes
def palisade(x0, y0, x1, y1, layer, h=3.4):
    n = int(math.hypot(x1 - x0, y1 - y0) / 0.42)
    for i in range(n + 1):
        t = i / n
        hh = h + random.uniform(-0.3, 0.25)
        x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        cyl(0.22, hh, (x, y, hh / 2), LOG, layer, verts=7, rot=(0, random.uniform(-0.04, 0.04), 0))
        cyl(0.22, 0.6, (x, y, hh + 0.3), LOG, layer, verts=7, r2=0.0)
    a = math.atan2(y1 - y0, x1 - x0); L = math.hypot(x1 - x0, y1 - y0)
    for z in (0.9, 2.5):
        box((L, 0.12, 0.18), ((x0 + x1) / 2, (y0 + y1) / 2 - 0.25, z), BEAM, layer, rot=(0, 0, a))


GATE = (14.0, 8.0)
palisade(GATE[0] + 2.0, GATE[1] + 1.9, 24.0, 18.5, "lisiere")   # vers le fond à droite
palisade(GATE[0] - 2.0, GATE[1] - 1.9, GATE[0] - 3.4, GATE[1] - 3.2, "lisiere", h=3.0)
for s in (-1, 1):                                          # porte : deux poteaux, linteau, toit
    cyl(0.3, 4.4, (GATE[0] + s * 1.7, GATE[1] + s * 1.6, 2.2), LOG, "lisiere", verts=8)
box((4.6, 0.3, 0.32), (GATE[0], GATE[1], 4.2), BEAM, "lisiere", rot=(0, 0, math.radians(43)))
box((5.2, 1.4, 0.15), (GATE[0], GATE[1], 4.75), ROOF, "lisiere", rot=(math.radians(18), 0, math.radians(43)))
box((0.7, 0.06, 1.1), (GATE[0] - 0.4, GATE[1] - 1.0, 3.3), CLOTH, "lisiere", rot=(0, 0, math.radians(43)))   # bannière
# maison de garde (même construction que l'exploration : colombages, enduit, ardoise), derrière la palissade
HX, HY, W, D, H0, H1, RH = 21.0, 16.5, 6.0, 4.4, 0.9, 4.4, 1.8
box((W + 0.2, D + 0.2, H0), (HX, HY, H0 / 2), STONE, "lisiere", bevel=0.05)
box((W, D, H1 - H0), (HX, HY, H0 + (H1 - H0) / 2), PLASTER, "lisiere")
fy = HY - D / 2 - 0.04
for x in (-W / 2 + 0.1, -1.0, 1.0, W / 2 - 0.1):
    box((0.2, 0.1, H1 - H0), (HX + x, fy, H0 + (H1 - H0) / 2), BEAM, "lisiere")
for z in (H0 + 0.05, 2.7, H1 - 0.05):
    box((W + 0.05, 0.12, 0.18), (HX, fy, z), BEAM, "lisiere")
ang = math.atan2(RH, D / 2 + 0.6); L = math.hypot(RH, D / 2 + 0.6)
for sy in (-1, 1):
    box((W + 0.9, L, 0.22), (HX, HY + sy * (D / 2 + 0.6) / 2, H1 + RH / 2), ROOF, "lisiere", rot=(sy * ang, 0, 0), bevel=0.04)
for x in (-1.9, 1.7):
    box((0.95, 0.08, 0.85), (HX + x, fy - 0.03, 1.9), GLASS, "lisiere")
    box((0.08, 0.1, 0.85), (HX + x, fy - 0.07, 1.9), BEAM, "lisiere")
    box((0.95, 0.1, 0.08), (HX + x, fy - 0.07, 1.9), BEAM, "lisiere")
for k in range(4):
    blob(0.4, (HX + random.uniform(-2.5, 2.5), HY - random.uniform(0.8, 2.0), H1 + random.uniform(0.4, 1.3)), MOSS, "lisiere", sub=1, disp=0.4, scale=(1.5, 1.0, 0.25))
# tonneaux et caisses au pied de la palissade
for (x, y) in [(9.0, 6.2), (9.8, 6.6)]:
    cyl(0.4, 1.0, (x, y, 0.5), WOOD, "lisiere", verts=12)
    for z in (0.2, 0.8):
        cyl(0.42, 0.06, (x, y, z), IRON, "lisiere", verts=12)
box((0.8, 0.8, 0.8), (16.5, 6.0, 0.4), WOOD, "lisiere", rot=(0, 0, 0.3), bevel=0.03)
# lanternes : deux à la porte (éclairent les Chasseurs), une sur un poteau à gauche (contre-jour chaud du Vorgane)
LANTERNS = [(GATE[0] - 2.3, GATE[1] - 2.0, 3.0), (GATE[0] + 1.2, GATE[1] - 2.6, 3.0), (-9.5, 4.0, 2.6)]
for (x, y, h) in LANTERNS:
    cyl(0.09, h, (x, y, h / 2), WOOD, "lisiere", verts=6)
    box((0.6, 0.08, 0.08), (x + 0.25, y, h - 0.05), WOOD, "lisiere")
    box((0.26, 0.26, 0.36), (x + 0.48, y, h - 0.35), FLAME, "lisiere")
    box((0.34, 0.34, 0.06), (x + 0.48, y, h - 0.14), IRON, "lisiere")


# ------------------------------------------------------------------------------------------------ lisière (gauche et fond)
def tree(x, y, h, layer, crown=3.0, leaves=48, lean=0.0):
    cyl(0.42, h, (x, y, h / 2), BARK, layer, verts=9, rot=(0, lean, 0), r2=0.3)
    for k in range(4):                                       # racines
        a = k * 1.57 + random.uniform(-0.3, 0.3)
        cyl(0.18, 1.4, (x + math.cos(a) * 0.5, y + math.sin(a) * 0.5, 0.15), BARK, layer, verts=6, rot=(math.sin(a) * 1.2, -math.cos(a) * 1.2, 0), r2=0.04)
    for k in range(4):                                       # branches
        a = random.uniform(0, 6.28)
        cyl(0.13, 1.9, (x + math.cos(a) * 0.7, y + math.sin(a) * 0.7, h * 0.82), BARK, layer, verts=6, rot=(math.cos(a) * 0.8, math.sin(a) * 0.8, 0))
    for k in range(leaves):
        a = random.uniform(0, 6.28); r = random.uniform(0, crown * 0.85)
        blob(random.uniform(0.45, 0.85) * crown / 2.2, (x + math.cos(a) * r, y + math.sin(a) * r * 0.8, h + random.uniform(-0.6, 1.8)),
             random.choice(LEAF), layer, sub=3, disp=0.9)


tree(-11.0, 5.0, 6.5, "lisiere", 4.2, 70)                   # grand arbre de lisière derrière le Vorgane
tree(-17.0, 9.0, 5.5, "lisiere", 3.6, 50)
tree(6.0, 14.5, 5.5, "lisiere", 3.4, 44)
tree(-2.0, 17.0, 6.0, "lisiere", 3.6, 44)
tree(-6.5, 12.0, 4.6, "lisiere", 2.8, 36)
tree(10.0, 12.5, 4.2, "lisiere", 2.6, 30)
for k in range(10):                                          # sous-bois : buissons bas qui cassent la ligne d'horizon
    x = random.uniform(-16, 9); y = random.uniform(9, 13); s_ = random.uniform(0.9, 1.6)
    for j in range(5):
        blob(s_ * random.uniform(0.5, 0.85), (x + random.uniform(-s_, s_) * 0.7, y + random.uniform(-s_, s_) * 0.4, s_ * 0.5), random.choice(LEAF), "lisiere", sub=2, disp=0.5)
for (x, y, s) in [(-11.5, 3.5, 1.0), (-6.5, 8.0, 1.2), (-17.5, 9.5, 1.4), (6.5, 6.5, 0.9), (-3.0, 9.5, 1.0)]:
    for k in range(6):
        blob(s * random.uniform(0.5, 0.85), (x + random.uniform(-s, s) * 0.7, y + random.uniform(-s, s) * 0.4, s * 0.5), random.choice(LEAF), "lisiere", sub=2, disp=0.5)
    for k in range(5):
        blob(0.08, (x + random.uniform(-s, s) * 0.7, y - s * 0.4, s * 0.8 + random.uniform(0, 0.3)), FLOWER[0], "lisiere", sub=1, disp=0.2)
# rochers moussus de part et d'autre de l'aire (ancrent la scène, ne gênent pas la lecture des combattants)
for (x, y, s) in [(-12.5, 0.8, 1.2), (-11.2, 1.6, 0.7), (-4.5, 6.0, 0.9), (8.0, 3.2, 0.8)]:
    blob(s, (x, y, s * 0.35), ROCK, "lisiere", sub=3, disp=0.45, scale=(1.4, 1.0, 0.8))
    blob(s * 0.6, (x - s * 0.2, y, s * 0.85), MOSS, "lisiere", sub=2, disp=0.5, scale=(1.6, 1.0, 0.35))
# forêt dense du fond
for k in range(26):
    x = random.uniform(-34, 30); y = random.uniform(19, 25)
    for j in range(3):
        blob(random.uniform(1.8, 2.8), (x + random.uniform(-1, 1), y + random.uniform(-0.5, 0.5), random.uniform(2.5, 5.5)), random.choice(LEAF), "loin", sub=3, disp=0.45)
    cyl(0.32, 3.5, (x, y, 1.75), BARK, "loin", verts=6)
for k in range(150):
    x = random.uniform(-50, 50); y = random.uniform(25, 55)
    h = random.uniform(8, 13) + (y - 25) * 0.35
    o = cyl(random.uniform(1.8, 2.8), h, (x, y, h / 2), FOREST if y < 34 else FOREST_FAR, "loin", verts=9, r2=0.0)

# ------------------------------------------------------------------------------------------------ premier plan (cadre bas)
for (x, y, s) in [(-15.5, -9.0, 1.9), (-12.0, -10.0, 1.5), (-18.5, -7.5, 1.6), (15.0, -9.5, 1.8), (12.0, -10.4, 1.3), (18.5, -8.0, 1.7)]:
    for k in range(7):
        blob(s * random.uniform(0.5, 0.85), (x + random.uniform(-s, s) * 0.8, y + random.uniform(-s, s) * 0.4, s * 0.45), random.choice([LEAF[2], LEAF_DARK]), "avant", sub=2, disp=0.55)
for k in range(90):                                         # touffes d'herbe haute (grappes de brins fins)
    x = random.uniform(-20, 20); y = random.uniform(-11.0, -7.5)
    if abs(x) < 8:
        continue
    for j in range(5):
        bpy.ops.mesh.primitive_cone_add(radius1=0.04, depth=random.uniform(0.4, 0.8), location=(x + random.uniform(-0.2, 0.2), y, 0.3), vertices=3,
                                        rotation=(random.uniform(-0.4, 0.4), random.uniform(-0.4, 0.4), 0))
        o = bpy.context.active_object; o.data.materials.append(random.choice([LEAF[0], LEAF_DARK])); put(o, "avant")
# tronc et branches au tout premier plan, à gauche (cadre sombre, hors de la zone des combattants)
cyl(0.7, 12, (-13.0, -8.0, 6), BARK, "avant", verts=10, rot=(0, -0.05, 0), r2=0.5)
for k in range(30):
    a = random.uniform(0, 6.28); r = random.uniform(0, 3.0)
    blob(random.uniform(0.9, 1.5), (-12.0 + math.cos(a) * r, -8.0 + math.sin(a) * r * 0.5, 8.5 + random.uniform(-0.5, 1.5)), random.choice([LEAF[2], LEAF_DARK]), "avant", sub=3, disp=0.9)

# ------------------------------------------------------------------------------------------------ lumière (identique à l'exploration)
world = bpy.data.worlds.new("w"); sc.world = world; world.use_nodes = True
nt = world.node_tree; bg = nt.nodes["Background"]
coord = nt.nodes.new("ShaderNodeTexCoord"); sep = nt.nodes.new("ShaderNodeSeparateXYZ"); ramp = nt.nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].color = (0.42, 0.26, 0.42, 1); ramp.color_ramp.elements[1].color = (0.10, 0.10, 0.26, 1)
ramp.color_ramp.elements[0].position = 0.5
ramp.color_ramp.elements[1].position = 0.72
ramp.color_ramp.elements[0].color = (0.40, 0.25, 0.42, 1); ramp.color_ramp.elements[1].color = (0.07, 0.08, 0.22, 1)
nt.links.new(coord.outputs["Generated"], sep.inputs[0]); nt.links.new(sep.outputs["Z"], ramp.inputs["Fac"])
nt.links.new(ramp.outputs["Color"], bg.inputs["Color"]); bg.inputs["Strength"].default_value = 0.8
moon = bpy.data.objects.new("lune", bpy.data.lights.new("lune", "SUN")); moon.data.energy = 2.6; moon.data.color = (0.62, 0.66, 1.0)
moon.rotation_euler = (math.radians(60), math.radians(-30), math.radians(200)); moon.data.angle = math.radians(3)   # haut gauche, de l'arrière
sc.collection.objects.link(moon)
fill = bpy.data.objects.new("ciel", bpy.data.lights.new("ciel", "SUN")); fill.data.energy = 0.5; fill.data.color = (0.75, 0.55, 0.85)
fill.rotation_euler = (math.radians(35), 0, math.radians(-10)); sc.collection.objects.link(fill)
for (x, y, h) in LANTERNS:
    l = bpy.data.objects.new("lanterne", bpy.data.lights.new("lanterne", "POINT")); l.data.energy = 900; l.data.color = (1.0, 0.58, 0.28)
    l.data.shadow_soft_size = 0.3; l.location = (x + 0.48, y - 0.3, h - 0.45); sc.collection.objects.link(l)
for x in (-1.9, 1.7):
    l = bpy.data.objects.new("fenetre", bpy.data.lights.new("fenetre", "POINT")); l.data.energy = 40; l.data.color = (1.0, 0.6, 0.28)
    l.location = (HX + x, fy - 0.7, 1.9); sc.collection.objects.link(l)

# ------------------------------------------------------------------------------------------------ caméra de combat
# Perspective longue focale (35 mm), vue latérale trois-quarts : 8° vers la droite, plongée réglée pour que la
# ligne de combat (y ≈ 0) tombe sur les pieds des combattants (y écran ≈ 500 / 720).
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); cam.data.lens = 35; cam.data.sensor_width = 36
sc.collection.objects.link(cam); sc.camera = cam
sc.render.resolution_x, sc.render.resolution_y = NW * SS, NH * SS
DIST, HEIGHT, AZ = 22.0, 3.6, math.radians(-8)
cam.location = Vector((math.sin(AZ) * DIST + 1.0, -math.cos(AZ) * DIST, HEIGHT))
look = Vector((1.0, 0.0, 0.0))
FEET_Y = (500 - (732 - 720) / 2) / 3.0 + (244 - 240) / 2      # natif dans l'image 432×244 centrée
for it in range(40):                                        # ajuste le point visé pour placer la ligne au bon endroit
    cam.rotation_euler = (look + Vector((0, 0, 0)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    c = world_to_camera_view(sc, cam, Vector((1.0, 0.0, 0.0)))
    py = (1 - c.y) * NH
    look.z -= (py - FEET_Y) * 0.02
sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.view_settings.view_transform = "Standard"


def to_px(p):
    c = world_to_camera_view(sc, cam, Vector(p))
    return [round(c.x * NW, 1), round((1 - c.y) * NH, 1)]


def render(path, samples, transparent):
    sc.cycles.samples = samples; sc.cycles.use_denoising = samples > 4
    sc.render.film_transparent = transparent
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


ORDER = ["base", "loin", "lisiere", "avant"]
if SAMPLES == 0:                                            # contrôle de cadrage sans rendu
    print("cadrage :", {"ligne": [to_px((-6, 0, 0)), to_px((8, 0, 0))], "lanternes": [to_px((x + 0.48, y, h - 0.35)) for (x, y, h) in LANTERNS], "porte": to_px((GATE[0], GATE[1], 0))})
    sys.exit(0)
meshes = [o for o in sc.objects if o.type == "MESH"]
for o in meshes:
    LAYER.setdefault(o, "base")
render(os.path.join(OUT, "apercu.png"), SAMPLES, False)
for k, name in enumerate(ORDER):
    for o in meshes:
        lk = ORDER.index(LAYER[o])
        o.visible_camera = lk <= k if name != "base" else lk == 0       # plans plus proches : invisibles (ombres gardées)
        o.is_holdout = name != "base" and lk < k                           # plans plus lointains : découpe transparente
    if name == "base":
        for o in meshes:
            o.visible_camera = LAYER[o] == "base"
    render(os.path.join(OUT, "%s.png" % name), SAMPLES, name != "base")
for o in meshes:
    o.visible_camera = True; o.is_holdout = False

bpy.context.view_layer.update()
layout = {
    "native": [NW, NH], "display_scale": 3,
    "lights": [to_px((x + 0.48, y, h - 0.35)) for (x, y, h) in LANTERNS],
    "windows": [to_px((HX + x, fy, 1.9)) for x in (-1.9, 1.7)],
    "ligne_combat": [to_px((-6, 0, 0)), to_px((8, 0, 0))],
    "px_par_metre_ligne": round(to_px((2, 0, 0))[0] - to_px((1, 0, 0))[0], 2),
    "porte": to_px((GATE[0], GATE[1], 0)),
}
json.dump(layout, open(os.path.join(OUT, "layout.json"), "w"), indent=1)
print("arène rendue :", layout)
