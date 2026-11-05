"""Zone d'exploration HD-2D « Lisière de Val'Serra » — construite par script dans Blender, rendue sous la caméra
commune de l'exploration : orthographique, plongée 35°, tournée de 20° (on voit la façade ET le côté des volumes).
Crépuscule bleu-violet, lanternes chaudes. Produit :
  - <out>/plate.png      : image de la scène complète (suréchantillonnée ×SS)
  - <out>/mask_<g>.png   : masque de chaque élément contournable (pixels visibles de l'élément dans l'image)
  - <out>/layout.json    : pour chaque élément, ligne de tri (pieds) et emprise au sol projetée (collisions),
                           zone praticable, positions de départ (héros, PNJ, monstre) en pixels natifs.
Usage : python scene_blender.py <dossier_sortie> [ppm=20] [SS=3] [échantillons=48]"""
import json, math, os, random, sys
import bpy, bmesh
from mathutils import Vector, Euler
from bpy_extras.object_utils import world_to_camera_view

OUT = sys.argv[1]
PPM = float(sys.argv[2]) if len(sys.argv) > 2 else 20.0
SS = int(sys.argv[3]) if len(sys.argv) > 3 else 3
SAMPLES = int(sys.argv[4]) if len(sys.argv) > 4 else 48
NW, NH = 704, 400                       # image native (un peu plus grande que l'écran 640×360 : la caméra suit)
ELEV, AZ = math.radians(35), math.radians(20)
os.makedirs(OUT, exist_ok=True)
random.seed(7)
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
GROUPS = {}                             # nom de groupe -> [objets]


def grp(o, g):
    if g:
        GROUPS.setdefault(g, []).append(o)
    return o


# ------------------------------------------------------------------------------------------------ matériaux
def mat(name, col, rough=0.9, tex=None, scale=5.0, col2=None, noise=0.35, emit=None, estr=0.0, bump=0.0):
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
    return m


GRASS = mat("herbe", (0.19, 0.31, 0.21), tex="voronoi", scale=3, col2=(0.07, 0.15, 0.12), noise=0.5, bump=0.4)
GRASS_LOW = mat("herbe_basse", (0.09, 0.17, 0.14), tex="voronoi", scale=3, col2=(0.05, 0.11, 0.1), noise=0.5)
PATH = mat("paves", (0.42, 0.39, 0.42), tex="brick", scale=3.5, col2=(0.33, 0.30, 0.34), noise=0.45, bump=0.6)
DIRT = mat("terre", (0.26, 0.20, 0.17), noise=0.5, bump=0.3)
STONE = mat("pierre", (0.34, 0.33, 0.37), tex="brick", scale=4, col2=(0.25, 0.24, 0.29), noise=0.5, bump=0.8)
WALLSTONE = mat("muret", (0.30, 0.29, 0.31), tex="brick", scale=2.2, col2=(0.22, 0.21, 0.24), noise=0.55, bump=1.0)
PLASTER = mat("enduit", (0.62, 0.55, 0.45), noise=0.45, bump=0.3)
BEAM = mat("poutre", (0.20, 0.12, 0.08), tex="planks", scale=3)
WOOD = mat("bois", (0.33, 0.21, 0.12), tex="planks", scale=4)
ROOF = mat("ardoise", (0.24, 0.23, 0.33), tex="brick", scale=11, col2=(0.15, 0.14, 0.23), noise=0.6, bump=0.8)
MOSS = mat("mousse", (0.16, 0.24, 0.12), noise=0.6)
GLASS = mat("vitre", (1.0, 0.62, 0.28), emit=(1.0, 0.6, 0.26), estr=2.4)
FLAME = mat("flamme", (1.0, 0.7, 0.35), emit=(1.0, 0.68, 0.32), estr=14.0)
IRON = mat("fer", (0.07, 0.07, 0.09), rough=0.5, noise=0)
LEAF = [mat("feuilles_%d" % i, c, noise=0.55, bump=0.6) for i, c in enumerate([(0.10, 0.22, 0.17), (0.13, 0.27, 0.19), (0.08, 0.17, 0.15)])]
BARK = mat("ecorce", (0.18, 0.13, 0.12), tex="planks", scale=6)
FOREST = mat("foret", (0.07, 0.09, 0.15), noise=0.3)
FOREST_FAR = mat("foret_loin", (0.15, 0.15, 0.27), noise=0.2)
FLOWER = [mat("fleur_%d" % i, c, noise=0) for i, c in enumerate([(0.55, 0.32, 0.85), (0.85, 0.82, 0.95), (0.95, 0.75, 0.3)])]
CLOTH = mat("tissu", (0.18, 0.2, 0.42), noise=0.3)


def box(size, loc, m, rot=(0, 0, 0), g=None, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object; o.scale = size; bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(m)
    if bevel:
        mod = o.modifiers.new("b", "BEVEL"); mod.width = bevel; mod.segments = 2
    return grp(o, g)


def cyl(r, h, loc, m, g=None, verts=10, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, location=loc, vertices=verts, rotation=rot)
    o = bpy.context.active_object; o.data.materials.append(m)
    return grp(o, g)


def blob(r, loc, m, g=None, sub=2, disp=0.35, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=r, location=loc, subdivisions=sub)
    o = bpy.context.active_object; o.scale = scale; o.data.materials.append(m)
    bpy.ops.object.shade_smooth()
    tx = bpy.data.textures.new("n", "CLOUDS"); tx.noise_scale = r * 0.6
    d = o.modifiers.new("d", "DISPLACE"); d.texture = tx; d.strength = r * disp
    return grp(o, g)


# ------------------------------------------------------------------------------------------------ terrain
def terrain(size, loc, m, z_amp=0.08, sub=24):
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=sub, y_subdivisions=sub, size=1, location=loc)
    o = bpy.context.active_object; o.scale = (size[0], size[1], 1); bpy.ops.object.transform_apply(scale=True)
    for v in o.data.vertices:
        v.co.z += random.uniform(-z_amp, z_amp)
    o.data.materials.append(m)
    return o


terrain((70, 40), (0, 6, 0), GRASS, z_amp=0.03, sub=40)                # plateau praticable (et au-delà, sous la forêt)
terrain((80, 30), (0, -24, -1.7), GRASS_LOW, sub=30)       # niveau bas (premier plan, non praticable)
# muret / bord de terrasse au premier plan (pierres irrégulières), avec mousse et herbe qui déborde
for i in range(50):
    x = -25 + i
    h = 1.7 + random.uniform(-0.15, 0.25)
    box((1.02, 0.9, h), (x + 0.5, -9.05, -1.7 + h / 2), WALLSTONE, rot=(0, 0, random.uniform(-0.04, 0.04)), g="muret", bevel=0.06)
    if random.random() < 0.6:
        blob(0.35, (x + random.uniform(0, 1), -8.7, 0.02), MOSS, g="muret", sub=1, disp=0.5, scale=(1.4, 0.8, 0.4))
# chemin pavé (bandes successives) avec bordure de terre irrégulière
PATH_PTS = [(-12, -8.6), (-7, -5.5), (-2, -2.5), (2.5, 0.2), (4.6, 1.8), (9, 0.8), (16, 1.4)]
for i, ((x0, y0), (x1, y1)) in enumerate(zip(PATH_PTS[:-1], PATH_PTS[1:])):
    L = math.hypot(x1 - x0, y1 - y0); a = math.atan2(y1 - y0, x1 - x0)
    dz = i * 0.006                                     # pas de faces confondues entre segments voisins
    box((L + 0.6, 2.6, 0.1), ((x0 + x1) / 2, (y0 + y1) / 2, 0.04 + dz), DIRT, rot=(0, 0, a))
    box((L + 0.3, 1.9, 0.1), ((x0 + x1) / 2, (y0 + y1) / 2, 0.1 + dz), PATH, rot=(0, 0, a))
for (x0, y0) in PATH_PTS:                                  # jonctions arrondies : chemin continu
    cyl(1.3, 0.1, (x0, y0, 0.072), DIRT, verts=16)
    cyl(0.95, 0.1, (x0, y0, 0.142), PATH, verts=16)
    for k in range(0):                                    # (pavés détachés retirés : lecture « dalles flottantes »)
        t = random.random(); s = random.choice((-1, 1))
        px = x0 + (x1 - x0) * t - math.sin(a) * s * 1.15; py = y0 + (y1 - y0) * t + math.cos(a) * s * 1.15
        box((0.22, 0.18, 0.05), (px, py, 0.06), PATH, rot=(0, 0, random.uniform(0, 3)))

# ------------------------------------------------------------------------------------------------ maison
HX, HY = 5.0, 5.6
W, D, H0, H1, RH = 6.4, 4.6, 0.9, 4.6, 1.8
house = []
house.append(box((W + 0.2, D + 0.2, H0), (HX, HY, H0 / 2), STONE, g="maison", bevel=0.05))
house.append(box((W, D, H1 - H0), (HX, HY, H0 + (H1 - H0) / 2), PLASTER, g="maison"))
fy = HY - D / 2 - 0.04
sxw = HX + W / 2 + 0.04                                   # mur latéral droit (visible grâce à la rotation)
for x in (-W / 2 + 0.1, -1.2, 1.2, W / 2 - 0.1):
    box((0.2, 0.1, H1 - H0), (HX + x, fy, H0 + (H1 - H0) / 2), BEAM, g="maison")
for y in (-D / 2 + 0.1, 0, D / 2 - 0.1):
    box((0.1, 0.2, H1 - H0), (sxw, HY + y, H0 + (H1 - H0) / 2), BEAM, g="maison")
for z in (H0 + 0.05, 2.75, H1 - 0.05):
    box((W + 0.05, 0.12, 0.18), (HX, fy, z), BEAM, g="maison")
    box((0.12, D + 0.05, 0.18), (sxw, HY, z), BEAM, g="maison")
for sx in (-1, 1):
    box((0.13, 0.08, 2.1), (HX + sx * 2.2, fy, 3.68), BEAM, rot=(0, math.radians(sx * 38), 0), g="maison")
# toit (faîtage parallèle à la façade), avec débord, mousse et pignon droit
ang = math.atan2(RH, D / 2 + 0.6); L = math.hypot(RH, D / 2 + 0.6)
for sy in (-1, 1):
    box((W + 0.9, L, 0.22), (HX, HY + sy * (D / 2 + 0.6) / 2, H1 + RH / 2), ROOF, rot=(sy * ang, 0, 0), g="maison", bevel=0.04)
box((W + 1.0, 0.3, 0.26), (HX, HY, H1 + RH + 0.05), BEAM, g="maison")
for k in range(5):
    blob(0.4, (HX + random.uniform(-3, 3), HY - random.uniform(0.6, 2.2), H1 + random.uniform(0.4, 1.4)), MOSS, g="maison", sub=1, disp=0.4, scale=(1.5, 1.0, 0.25))
bm = bmesh.new()
v = [bm.verts.new((sxw + 0.02, HY - D / 2 - 0.1, H1)), bm.verts.new((sxw + 0.02, HY + D / 2 + 0.1, H1)), bm.verts.new((sxw + 0.02, HY, H1 + RH))]
bm.faces.new(v); me = bpy.data.meshes.new("pignon"); bm.to_mesh(me)
pg = bpy.data.objects.new("pignon", me); sc.collection.objects.link(pg); pg.data.materials.append(PLASTER); grp(pg, "maison")
box((0.7, 0.7, 2.0), (HX + 2.0, HY + 0.8, H1 + 1.4), STONE, g="maison", bevel=0.04)
# porte (en arc), fenêtres à volets, jardinières, marche, enseigne
box((1.1, 0.14, 2.1), (HX - 0.3, fy - 0.04, H0 + 1.05 - 0.9), WOOD, g="maison")
box((1.4, 0.16, 0.22), (HX - 0.3, fy - 0.06, 2.15), BEAM, g="maison")
for x in (-2.1, 1.8):
    box((0.95, 0.08, 0.85), (HX + x, fy - 0.03, 1.8), GLASS, g="maison")
    box((0.08, 0.1, 0.85), (HX + x, fy - 0.07, 1.8), BEAM, g="maison")
    box((0.95, 0.1, 0.08), (HX + x, fy - 0.07, 1.8), BEAM, g="maison")
    for s in (-1, 1):
        box((0.38, 0.07, 0.9), (HX + x + s * 0.68, fy - 0.06, 1.8), WOOD, g="maison")
    box((1.1, 0.3, 0.25), (HX + x, fy - 0.2, 1.25), WOOD, g="maison")
    for k in range(6):
        blob(0.09, (HX + x + random.uniform(-0.45, 0.45), fy - 0.25, 1.42), random.choice(FLOWER[:2]), g="maison", sub=1, disp=0.2)
box((0.9, 0.08, 0.75), (HX, fy - 0.03, 3.7), GLASS, g="maison")
box((0.75, 0.08, 0.7), (sxw + 0.03, HY, 3.7), GLASS, rot=(0, 0, math.radians(90)), g="maison")
box((1.8, 0.7, 0.2), (HX - 0.3, fy - 0.35, 0.1), STONE, g="maison", bevel=0.03)
box((0.06, 0.6, 0.06), (HX + 0.7, fy - 0.3, 2.6), IRON, g="maison")
box((0.6, 0.06, 0.4), (HX + 0.7, fy - 0.6, 2.3), CLOTH, g="maison")
WINLIGHTS = [(HX + x, fy - 0.7, 1.8) for x in (-2.1, 1.8)] + [(HX, fy - 0.6, 3.7)]

# ------------------------------------------------------------------------------------------------ végétation
def tree(x, y, h, g, crown=3.0):
    cyl(0.32, h, (x, y, h / 2), BARK, g=g, verts=8)
    for k in range(3):
        a = random.uniform(0, 6.28)
        cyl(0.12, 1.6, (x + math.cos(a) * 0.6, y + math.sin(a) * 0.6, h * 0.8), BARK, g=g, verts=6, rot=(math.cos(a) * 0.7, math.sin(a) * 0.7, 0))
    for k in range(48):
        a = random.uniform(0, 6.28); r = random.uniform(0, crown * 0.8)
        blob(random.uniform(0.45, 0.85) * crown / 2.2, (x + math.cos(a) * r, y + math.sin(a) * r * 0.8, h + random.uniform(-0.4, 1.6)),
             random.choice(LEAF), g=g, sub=3, disp=0.9)


def bush(x, y, s, g=None):
    for k in range(5):
        blob(s * random.uniform(0.5, 0.8), (x + random.uniform(-s, s) * 0.6, y + random.uniform(-s, s) * 0.4, s * 0.45), random.choice(LEAF), g=g, sub=2, disp=0.5)
    if random.random() < 0.6:
        for k in range(5):
            blob(0.08, (x + random.uniform(-s, s) * 0.7, y - s * 0.4, s * 0.7 + random.uniform(0, 0.3)), FLOWER[0], g=g, sub=1, disp=0.2)


tree(-10.5, 4.0, 4.6, "arbre_g", 3.2)
tree(12.0, 6.5, 4.2, "arbre_d", 2.8)
for i, (x, y, s) in enumerate([(-6.5, 6.5, 1.0), (-13, -1.0, 1.1), (0.8, 7.6, 0.9), (13.5, -4.5, 1.0), (-3.0, 7.8, 0.8)]):
    bush(x, y, s, g="buisson_%d" % i)
# herbes hautes, fleurs et pierres semées (hors chemin, sans collision)
def on_path(x, y):
    for (x0, y0), (x1, y1) in zip(PATH_PTS[:-1], PATH_PTS[1:]):
        vx, vy = x1 - x0, y1 - y0; t = max(0, min(1, ((x - x0) * vx + (y - y0) * vy) / (vx * vx + vy * vy)))
        if math.hypot(x - x0 - t * vx, y - y0 - t * vy) < 1.6:
            return True
    return False
for k in range(260):
    x, y = random.uniform(-16, 16), random.uniform(-8.5, 11)
    if on_path(x, y) or (abs(x - HX) < 4 and abs(y - HY) < 3.2):
        continue
    if random.random() < 0.55:
        bpy.ops.mesh.primitive_cone_add(radius1=0.12, depth=random.uniform(0.25, 0.5), location=(x, y, 0.15), vertices=4)
        o = bpy.context.active_object; o.data.materials.append(random.choice(LEAF))
    else:
        blob(0.07, (x, y, 0.12), random.choice(FLOWER), sub=1, disp=0.2)
for k in range(14):
    x, y = random.uniform(-15, 15), random.uniform(-8, 10)
    if not on_path(x, y):
        blob(random.uniform(0.15, 0.35), (x, y, 0.05), STONE, sub=2, disp=0.3, scale=(1.3, 1.0, 0.6))

# ------------------------------------------------------------------------------------------------ accessoires
def fence(x0, y0, x1, y1, g):
    n = int(math.hypot(x1 - x0, y1 - y0) / 1.6) + 1
    for i in range(n + 1):
        t = i / n
        box((0.16, 0.16, 1.1), (x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, 0.55), WOOD, rot=(0, 0, random.uniform(-0.1, 0.1)), g=g)
    a = math.atan2(y1 - y0, x1 - x0); L = math.hypot(x1 - x0, y1 - y0)
    for z in (0.45, 0.85):
        box((L, 0.08, 0.1), ((x0 + x1) / 2, (y0 + y1) / 2, z), WOOD, rot=(random.uniform(-0.03, 0.03), 0, a), g=g)


fence(8.5, -2.6, 15.5, -2.2, "cloture_d")
fence(-15.5, 7.0, -8.5, 8.6, "cloture_g")
for i, (x, y, z) in enumerate([(1.6, 3.4, 0.35), (2.4, 3.6, 0.35), (2.0, 3.5, 1.05)]):
    box((0.7, 0.7, 0.7), (x, y, z), WOOD, rot=(0, 0, random.uniform(-0.2, 0.2)), g="caisses", bevel=0.03)
for (x, y) in [(8.6, 3.0), (9.3, 3.4)]:
    cyl(0.38, 0.95, (x, y, 0.47), WOOD, g="tonneaux", verts=12)
    for z in (0.2, 0.75):
        cyl(0.4, 0.06, (x, y, z), IRON, g="tonneaux", verts=12)
box((1.8, 0.45, 0.1), (-3.2, 4.0, 0.5), WOOD, g="banc")
for s in (-1, 1):
    box((0.1, 0.4, 0.5), (-3.2 + s * 0.75, 4.0, 0.25), WOOD, g="banc")
LANTERNS = [(-0.8, -0.4), (-7.8, -6.6), (10.5, -1.4)]
for i, (x, y) in enumerate(LANTERNS):
    box((0.14, 0.14, 2.6), (x, y, 1.3), WOOD, g="lanterne_%d" % i)
    box((0.7, 0.08, 0.08), (x + 0.3, y, 2.55), WOOD, g="lanterne_%d" % i)
    box((0.26, 0.26, 0.36), (x + 0.55, y, 2.25), FLAME, g="lanterne_%d" % i)
    box((0.34, 0.34, 0.06), (x + 0.55, y, 2.46), IRON, g="lanterne_%d" % i)
# lisière de forêt et collines (fond)
# lisière dense : rangée de feuillus juste derrière la clairière, puis conifères plus sombres, plus loin et plus hauts
for k in range(40):
    x = random.uniform(-28, 28); y = random.uniform(11.5, 14.5)
    if abs(x - HX) < 4.5 and y < 12.5:
        continue
    for j in range(3):
        blob(random.uniform(1.6, 2.4), (x + random.uniform(-1, 1), y + random.uniform(-0.5, 0.5), random.uniform(2.0, 4.5)), random.choice(LEAF), sub=3, disp=0.45)
    cyl(0.3, 3, (x, y, 1.5), BARK, verts=6)
for k in range(120):
    x = random.uniform(-34, 34); y = random.uniform(15, 30)
    h = random.uniform(7, 12) + (y - 15) * 0.3
    bpy.ops.mesh.primitive_cone_add(radius1=random.uniform(1.6, 2.6), depth=h, location=(x, y, h / 2), vertices=9)
    o = bpy.context.active_object; o.data.materials.append(FOREST if y < 21 else FOREST_FAR)
# arbres sur les côtés de la clairière (cadrage) et au premier plan bas
for (x, y) in [(-17.5, 2.0), (-18.5, 8.0), (18.5, 0.0), (19.0, 7.5)]:
    tree(x, y, random.uniform(4.0, 5.0), None, 3.0)
for k in range(12):
    bush(random.uniform(-22, 22), random.uniform(-13, -10.5), random.uniform(1.0, 1.6))

# ------------------------------------------------------------------------------------------------ lumière
world = bpy.data.worlds.new("w"); sc.world = world; world.use_nodes = True
bg = world.node_tree.nodes["Background"]
sky = world.node_tree.nodes.new("ShaderNodeTexGradient")
coord = world.node_tree.nodes.new("ShaderNodeTexCoord")
ramp = world.node_tree.nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].color = (0.42, 0.26, 0.42, 1); ramp.color_ramp.elements[1].color = (0.10, 0.10, 0.26, 1)
sep = world.node_tree.nodes.new("ShaderNodeSeparateXYZ")
world.node_tree.links.new(coord.outputs["Generated"], sep.inputs[0])
world.node_tree.links.new(sep.outputs["Z"], ramp.inputs["Fac"])
world.node_tree.links.new(ramp.outputs["Color"], bg.inputs["Color"]); bg.inputs["Strength"].default_value = 1.1
moon = bpy.data.objects.new("lune", bpy.data.lights.new("lune", "SUN")); moon.data.energy = 2.8; moon.data.color = (0.62, 0.66, 1.0)
moon.rotation_euler = (math.radians(55), math.radians(-25), math.radians(150)); moon.data.angle = math.radians(3)
sc.collection.objects.link(moon)
fill = bpy.data.objects.new("ciel", bpy.data.lights.new("ciel", "SUN")); fill.data.energy = 0.5; fill.data.color = (0.75, 0.55, 0.85)
fill.rotation_euler = (math.radians(30), 0, math.radians(-20)); sc.collection.objects.link(fill)
for (x, y) in LANTERNS:
    l = bpy.data.objects.new("lanterne", bpy.data.lights.new("lanterne", "POINT")); l.data.energy = 420; l.data.color = (1.0, 0.58, 0.28)
    l.data.shadow_soft_size = 0.3; l.location = (x + 0.55, y - 0.2, 2.1); sc.collection.objects.link(l)
for p in WINLIGHTS:
    l = bpy.data.objects.new("fenetre", bpy.data.lights.new("fenetre", "POINT")); l.data.energy = 35; l.data.color = (1.0, 0.6, 0.28)
    l.location = p; sc.collection.objects.link(l)

# ------------------------------------------------------------------------------------------------ caméra
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); cam.data.type = "ORTHO"
sc.collection.objects.link(cam); sc.camera = cam
target = Vector((1.0, 1.5, 0.0))
dirv = Vector((math.sin(AZ) * math.cos(ELEV) * -1, -math.cos(AZ) * math.cos(ELEV), math.sin(ELEV)))
dirv = Vector((-math.sin(AZ) * math.cos(ELEV), -math.cos(AZ) * math.cos(ELEV), math.sin(ELEV)))
cam.location = target + dirv * 40
cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
cam.data.ortho_scale = NW / PPM
sc.render.resolution_x, sc.render.resolution_y = NW * SS, NH * SS
sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.view_settings.view_transform = "Standard"
sc.render.film_transparent = False


def render(path, samples, transparent=False):
    sc.cycles.samples = samples; sc.cycles.use_denoising = samples > 4
    sc.render.film_transparent = transparent
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


bpy.context.view_layer.update()
render(os.path.join(OUT, "plate.png"), SAMPLES)

# ------------------------------------------------------------------------------------------------ masques et disposition
def to_px(p):
    c = world_to_camera_view(sc, cam, Vector(p))
    return [round(c.x * NW, 1), round((1 - c.y) * NH, 1)]


def footprint(objs):
    pts = []
    for o in objs:
        for corner in o.bound_box:
            w = o.matrix_world @ Vector(corner)
            if w.z < 0.6:
                pts.append((w.x, w.y))
    if not pts:
        return [], 0
    # enveloppe convexe 2D au sol, projetée à l'écran
    pts = sorted(set((round(x, 2), round(y, 2)) for x, y in pts))
    def cross(o, a, b): return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0: lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0: upper.pop()
        upper.append(p)
    hull = lower[:-1] + upper[:-1]
    poly = [to_px((x, y, 0)) for x, y in hull]
    return poly, max(p[1] for p in poly)


layout = {"native": [NW, NH], "ppm": PPM, "elements": {}}
all_objs = [o for o in sc.objects if o.type == "MESH"]
for g, objs in GROUPS.items():
    for o in all_objs:
        o.is_holdout = o not in objs
    render(os.path.join(OUT, "mask_%s.png" % g), 1, transparent=True)
    poly, sort_y = footprint(objs)
    solid = not g.startswith("buisson") and g != "muret"
    layout["elements"][g] = {"sort_y": sort_y, "footprint": poly, "solid": solid}
for o in all_objs:
    o.is_holdout = False
# zone praticable : plateau, en retrait du muret et de la lisière
layout["walkable"] = [to_px(p) for p in [(-15.5, -8.3, 0), (15.5, -8.3, 0), (15.5, 10.5, 0), (-15.5, 10.5, 0)]]
layout["spawn"] = {"heros": to_px((-6.0, -5.2, 0)), "pnj": to_px((HX + 1.4, HY - D / 2 - 1.0, 0)),
                   "monstre": to_px((-11.5, -3.0, 0)), "porte": to_px((HX - 0.3, fy - 0.6, 0))}
layout["lights"] = [to_px((x + 0.55, y, 0)) for (x, y) in LANTERNS]
json.dump(layout, open(os.path.join(OUT, "layout.json"), "w"), indent=1)
print("scène rendue, éléments :", ", ".join(GROUPS))
