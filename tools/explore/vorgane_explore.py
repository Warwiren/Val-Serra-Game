"""Vorgane en EXPLORATION : rendu original sous la projection du décor (orthographique, plongée 35°, caméra
tournée de 20°), même éclairage crépusculaire (lune froide, ciel violet, lanterne chaude), ombre portée réelle sur
un sol « attrape-ombre », animation de repos (8 images). Le monstre est orienté vers la droite de l'écran
(trois-quarts), à la même échelle que le décor (20 px natifs / m) ; sa taille est réglée pour garder le rapport
monstre/héros du combat (≈ 1,5 × la hauteur d'Aren).
Sortie : <out>/v_<n>.png (suréchantillonné ×SS) + <out>/anchor.json (pieds = projection de l'origine au sol).
Usage : python vorgane_explore.py <vorgane_parts.blend> <out> [ppm=20] [SS=3] [échantillons=32]"""
import json, math, os, sys
import bpy
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

BLEND, OUT = sys.argv[1], sys.argv[2]
PPM = float(sys.argv[3]) if len(sys.argv) > 3 else 20.0
SS = int(sys.argv[4]) if len(sys.argv) > 4 else 3
SAMPLES = int(sys.argv[5]) if len(sys.argv) > 5 else 32
ELEV, AZ = math.radians(35), math.radians(20)
FRAMES = [1, 7, 13, 19, 25, 31, 37, 43]
TARGET_H = 0.95                       # hauteur au garrot (m) : silhouette ≈ 42 px natifs à l'écran, soit ≈ 1,5 × Aren (rapport du combat)
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=BLEND)
sc = bpy.context.scene
rig = bpy.data.objects["VorganeRig"]
for t in rig.animation_data.nla_tracks:
    t.mute = True
rig.animation_data.action = bpy.data.actions["idle"]
for ob in bpy.data.objects:
    if ob.type == "MESH":
        ob.hide_render = ob.name.endswith("_broken") or ob.name not in ("Vorgane_base", "part_carapace", "part_griffe", "part_glande")
        ob.is_holdout = False
# échelle et orientation : tête (côté -Y du modèle) tournée vers la droite de l'écran, en trois-quarts
sc.frame_set(1)
bpy.context.view_layer.update()
body = bpy.data.objects["Vorgane_base"]
zs = [(body.matrix_world @ Vector(c)).z for c in body.bound_box]
k = TARGET_H / (max(zs) - min(zs))
rig.scale = rig.scale * k
rig.rotation_euler.z += math.radians(34)     # tête vers la droite, trois-quarts vers la caméra
bpy.context.view_layer.update()
zs = [(body.matrix_world @ Vector(c)).z for c in body.bound_box]
rig.location.z -= min(zs)                       # pattes posées sur z = 0
bpy.context.view_layer.update()
# sol attrape-ombre
bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, 0))
ground = bpy.context.active_object
ground.is_shadow_catcher = True
# lumière (mêmes réglages que scene_blender.py)
world = bpy.data.worlds.new("w"); sc.world = world; world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.2, 0.16, 0.32, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.9
moon = bpy.data.objects.new("lune", bpy.data.lights.new("lune", "SUN")); moon.data.energy = 2.8; moon.data.color = (0.62, 0.66, 1.0)
moon.rotation_euler = (math.radians(55), math.radians(-25), math.radians(150)); moon.data.angle = math.radians(3)
sc.collection.objects.link(moon)
fill = bpy.data.objects.new("ciel", bpy.data.lights.new("ciel", "SUN")); fill.data.energy = 0.5; fill.data.color = (0.75, 0.55, 0.85)
fill.rotation_euler = (math.radians(30), 0, math.radians(-20)); sc.collection.objects.link(fill)
warm = bpy.data.objects.new("lanterne", bpy.data.lights.new("lanterne", "POINT")); warm.data.energy = 120; warm.data.color = (1.0, 0.6, 0.3)
warm.location = (3.0, -2.5, 2.2); sc.collection.objects.link(warm)
for ob in sc.objects:
    if ob.type == "LIGHT" and ob.name not in ("lune", "ciel", "lanterne"):
        ob.hide_render = True
# caméra commune
cam = bpy.data.objects.new("camx", bpy.data.cameras.new("camx")); cam.data.type = "ORTHO"
sc.collection.objects.link(cam); sc.camera = cam
d = Vector((-math.sin(AZ) * math.cos(ELEV), -math.cos(AZ) * math.cos(ELEV), math.sin(ELEV)))
target = Vector((0, 0, 0.9))
cam.location = target + d * 30
cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
NW = NH = 80
cam.data.ortho_scale = NW / PPM
sc.render.resolution_x, sc.render.resolution_y = NW * SS, NH * SS
sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = SAMPLES; sc.cycles.use_denoising = True
sc.render.film_transparent = True; sc.view_settings.view_transform = "Standard"
for i, f in enumerate(FRAMES):
    sc.frame_set(f)
    sc.render.filepath = os.path.join(OUT, "v_%d.png" % i)
    bpy.ops.render.render(write_still=True)
c = world_to_camera_view(sc, cam, Vector((rig.location.x, rig.location.y, 0)))
json.dump({"native": [NW, NH], "feet": [round(c.x * NW, 1), round((1 - c.y) * NH, 1)]}, open(os.path.join(OUT, "anchor.json"), "w"))
print("vorgane exploration : %d images, pieds" % len(FRAMES), c.x * NW, (1 - c.y) * NH)
