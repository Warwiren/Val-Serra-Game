"""Maison test de l'exploration HD-2D (mini-test artistique) — modélisée par script, rendue sous la caméra COMMUNE
de l'exploration : orthographique, de face, plongée de 35°. Crépuscule bleu-violet + fenêtres et lanterne chaudes.
Le rendu sert de BASE STRUCTURELLE (perspective, volumes, lumière) ; il est ensuite converti en pixel art et
retouché (tools/explore/to_pixel.py) pour ne pas ressembler à un simple modèle 3D pixélisé.
Usage : python house_blender.py <sortie.png> <px_natifs_par_mètre> [suréchantillonnage=4]"""
import math, sys
import bpy
from mathutils import Vector

OUT = sys.argv[1]
PPM = float(sys.argv[2])
SS = int(sys.argv[3]) if len(sys.argv) > 3 else 4
ELEV = math.radians(35)

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene


def mat(name, color, rough=0.85, tex=None, scale=4.0, color2=None, emission=None, estr=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = rough
    if tex == "brick":
        t = nt.nodes.new("ShaderNodeTexBrick"); t.inputs["Scale"].default_value = scale
        t.inputs["Color1"].default_value = (*color, 1); t.inputs["Color2"].default_value = (*(color2 or color), 1)
        t.inputs["Mortar"].default_value = (color[0] * 0.35, color[1] * 0.35, color[2] * 0.4, 1)
        t.inputs["Mortar Size"].default_value = 0.025
        n = nt.nodes.new("ShaderNodeTexNoise"); n.inputs["Scale"].default_value = scale * 3.0
        mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.inputs["Factor"].default_value = 0.35
        mix.blend_type = "MULTIPLY"
        nt.links.new(t.outputs["Color"], mix.inputs["A"]); nt.links.new(n.outputs["Color"], mix.inputs["B"])
        nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    elif tex == "planks":
        t = nt.nodes.new("ShaderNodeTexWave"); t.inputs["Scale"].default_value = scale
        t.inputs["Distortion"].default_value = 2.0
        r = nt.nodes.new("ShaderNodeValToRGB")
        r.color_ramp.elements[0].color = (color[0] * 0.6, color[1] * 0.6, color[2] * 0.6, 1)
        r.color_ramp.elements[1].color = (*color, 1)
        nt.links.new(t.outputs["Fac"], r.inputs["Fac"]); nt.links.new(r.outputs["Color"], bsdf.inputs["Base Color"])
    else:
        bsdf.inputs["Base Color"].default_value = (*color, 1)
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1)
        bsdf.inputs["Emission Strength"].default_value = estr
    return m


def box(name, size, loc, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object; o.name = name; o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(m)
    return o


STONE = mat("pierre", (0.30, 0.29, 0.34), tex="brick", scale=6, color2=(0.24, 0.23, 0.29))
PLASTER = mat("enduit", (0.62, 0.55, 0.46))
BEAM = mat("poutre", (0.20, 0.12, 0.08), tex="planks", scale=3)
ROOF = mat("ardoise", (0.26, 0.25, 0.38), tex="brick", scale=7, color2=(0.17, 0.16, 0.27))
DOOR = mat("porte", (0.36, 0.20, 0.10), tex="planks", scale=5)
GLASS = mat("vitre", (1.0, 0.65, 0.3), emission=(1.0, 0.62, 0.28), estr=2.2)
LANT = mat("lanterne", (1.0, 0.7, 0.35), emission=(1.0, 0.7, 0.35), estr=12.0)
IRON = mat("fer", (0.08, 0.08, 0.1), rough=0.5)

W, D, H0, H1 = 6.0, 4.5, 0.9, 4.6          # largeur, profondeur, soubassement, hauteur des murs
box("soubassement", (W, D, H0), (0, 0, H0 / 2), STONE)
box("murs", (W - 0.1, D - 0.1, H1 - H0), (0, 0, H0 + (H1 - H0) / 2), PLASTER)
# colombages de la façade (face -Y, vers la caméra)
fy = -D / 2 - 0.03
for x in (-W / 2 + 0.1, -1.1, 1.1, W / 2 - 0.1):          # poteaux sur deux niveaux
    box("poteau", (0.18, 0.08, H1 - H0), (x, fy, H0 + (H1 - H0) / 2), BEAM)
box("sabliere", (W, 0.1, 0.18), (0, fy, H1 - 0.05), BEAM)
box("lisse", (W, 0.1, 0.16), (0, fy, H0 + 0.05), BEAM)
box("entretoise", (W, 0.1, 0.16), (0, fy, 2.75), BEAM)    # plancher de l'étage
for sx in (-1, 1):
    box("croix", (0.12, 0.07, 1.9), (sx * 2.1, fy, 3.65), BEAM, rot=(0, math.radians(sx * 40), 0))

# toit à deux pans (faîtage parallèle à la façade : on voit le versant avant depuis la caméra)
RH = 1.5
for sy in (-1, 1):
    ang = math.atan2(RH, D / 2 + 0.5)
    L = math.hypot(RH, D / 2 + 0.5)
    box("pan", (W + 0.3, L, 0.18), (0, sy * (D / 2 + 0.5) / 2, H1 + RH / 2), ROOF, rot=(sy * ang, 0, 0))
box("faitage", (W + 0.4, 0.25, 0.22), (0, 0, H1 + RH + 0.05), BEAM)
box("fenetre_etage", (0.9, 0.08, 0.75), (0, fy - 0.03, 3.65), GLASS)
box("meneau_etage", (0.07, 0.1, 0.75), (0, fy - 0.07, 3.65), BEAM)
box("traverse_etage", (0.9, 0.1, 0.07), (0, fy - 0.07, 3.65), BEAM)
box("cheminee", (0.6, 0.6, 1.8), (1.8, 0.6, H1 + 1.3), STONE)
# porte, fenêtres, marche, lanterne
box("porte", (1.0, 0.12, 2.0), (0, fy - 0.03, 1.0), DOOR)
box("encadrement", (1.25, 0.1, 0.16), (0, fy - 0.05, 2.08), BEAM)
for x in (-2.0, 2.0):
    box("fenetre", (0.9, 0.08, 0.8), (x, fy - 0.03, 1.75), GLASS)
    box("appui", (1.1, 0.16, 0.08), (x, fy - 0.08, 1.32), BEAM)
    box("meneau", (0.07, 0.1, 0.8), (x, fy - 0.07, 1.75), BEAM)
    box("traverse", (0.9, 0.1, 0.07), (x, fy - 0.07, 1.75), BEAM)
    box("volet", (0.35, 0.06, 0.85), (x - 0.65, fy - 0.05, 1.75), DOOR)
    box("volet", (0.35, 0.06, 0.85), (x + 0.65, fy - 0.05, 1.75), DOOR)
box("marche", (1.6, 0.6, 0.18), (0, fy - 0.3, 0.09), STONE)
box("potence", (0.06, 0.4, 0.06), (0.85, fy - 0.2, 2.45), IRON)
box("lanterne", (0.22, 0.22, 0.3), (0.85, fy - 0.38, 2.25), LANT)

# Lumières : ciel crépusculaire bleu-violet, lune froide en haut à gauche, lumières chaudes
world = bpy.data.worlds.new("w"); sc.world = world; world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.20, 0.18, 0.38, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.9
sun = bpy.data.objects.new("lune", bpy.data.lights.new("lune", "SUN"))
sun.data.energy = 2.4; sun.data.color = (0.65, 0.68, 1.0)
sun.rotation_euler = (math.radians(50), math.radians(-35), math.radians(-30)); sc.collection.objects.link(sun)
for loc, e in [((0.85, fy - 0.6, 2.2), 18), ((-2.0, fy - 0.5, 1.75), 6), ((2.0, fy - 0.5, 1.75), 6)]:
    l = bpy.data.objects.new("chaud", bpy.data.lights.new("chaud", "POINT"))
    l.data.energy = e; l.data.color = (1.0, 0.6, 0.3); l.data.shadow_soft_size = 0.2
    l.data.use_custom_distance = True; l.data.cutoff_distance = 2.2       # lumière chaude localisée
    l.location = loc; sc.collection.objects.link(l)

# Caméra commune : orthographique, de face, plongée 35°
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); cam.data.type = "ORTHO"
sc.collection.objects.link(cam); sc.camera = cam
cam.rotation_euler = (math.radians(90) - ELEV, 0, 0)
cam.location = Vector((0, -20 * math.cos(ELEV), 20 * math.sin(ELEV) + 2.0))
WM, HM = 8.0, 9.5                                   # emprise du cadre en mètres (largeur, hauteur image)
cam.data.ortho_scale = max(WM, HM)
sc.render.resolution_x = int(round(max(WM, HM) * PPM * SS))
sc.render.resolution_y = int(round(max(WM, HM) * PPM * SS))
cam.data.shift_y = 0.05
sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 48; sc.cycles.use_denoising = True
sc.render.film_transparent = True
sc.view_settings.view_transform = "Standard"
sc.render.filepath = OUT
bpy.ops.render.render(write_still=True)
print("maison rendue :", sc.render.resolution_x, "px")
