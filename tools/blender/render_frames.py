"""Rendu d'images d'une animation du Vorgane (fond transparent, caméra orthographique, cadrage CONSTANT).
Usage : python render_frames.py <vorgane_rig.blend> <action> <images: ex. 1,10,16 ou 1-30/2> <dossier> [taille] [vue]
vue : profil (défaut, monstre tourné vers la gauche de l'image, comme en combat) | trois_quarts
L'éclairage reprend la direction de la scène de combat (lune en haut à droite, contre-jour bleuté)."""
import math, os, sys
import bpy
from mathutils import Vector

blend, action, frames_s, out = sys.argv[1:5]
size = int(sys.argv[5]) if len(sys.argv) > 5 else 512
view = sys.argv[6] if len(sys.argv) > 6 else "profil"
os.makedirs(out, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=blend)
scene = bpy.context.scene
rig = bpy.data.objects["VorganeRig"]
rig.animation_data.action = bpy.data.actions[action]
for t in rig.animation_data.nla_tracks:
    t.mute = True

# Calques (fichier avec parties séparées) : LAYER=complet | base | part_carapace | part_carapace_broken | ...
# Un calque de partie est rendu avec le corps en « holdout » : il est masqué là où le corps passe devant.
import os as _os
layer = _os.environ.get("LAYER", "")
if "Vorgane_base" in bpy.data.objects and layer:
    for ob in bpy.data.objects:
        if ob.type != "MESH":
            continue
        ob.hide_render = True
        ob.is_holdout = False
    if layer == "complet":
        for n in ("Vorgane_base", "part_carapace", "part_griffe", "part_glande"):
            bpy.data.objects[n].hide_render = False
    elif layer == "base":
        bpy.data.objects["Vorgane_base"].hide_render = False
    else:
        bpy.data.objects[layer].hide_render = False
        base = bpy.data.objects["Vorgane_base"]
        base.hide_render = False
        base.is_holdout = True

frames = []
for part in frames_s.split(","):
    if "-" in part:
        rng, _, step = part.partition("/")
        a, b = map(int, rng.split("-"))
        frames += list(range(a, b + 1, int(step or 1)))
    else:
        frames.append(int(part))

scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = int(_os.environ.get("SAMPLES", "32")) if True else 32
scene.cycles.use_denoising = True
scene.render.resolution_x = size
scene.render.resolution_y = size
scene.render.film_transparent = True
scene.view_settings.view_transform = "Standard"
world = bpy.data.worlds.new("w"); scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.25, 0.32, 0.5, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.55
key = bpy.data.objects.new("key", bpy.data.lights.new("key", "SUN"))
key.data.energy = float(_os.environ.get("KEY", "2.6")); key.data.color = (0.85, 0.9, 1.0)
key.rotation_euler = (math.radians(40), math.radians(-30), math.radians(-60))
scene.collection.objects.link(key)
rim = bpy.data.objects.new("rim", bpy.data.lights.new("rim", "SUN"))
rim.data.energy = 4.0; rim.data.color = (0.55, 0.8, 1.0)
rim.rotation_euler = (math.radians(70), math.radians(30), math.radians(160))
scene.collection.objects.link(rim)

cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
cam.data.ortho_scale = 2.6                 # cadrage constant pour toutes les animations
scene.collection.objects.link(cam); scene.camera = cam
target = Vector((0, -0.05, -0.05))
if view == "trois_quarts":
    d = Vector((2.2, -1.6, 0.9)).normalized()
else:
    d = Vector((1, 0, 0.12)).normalized()  # caméra côté +X : la tête (-Y) apparaît à GAUCHE de l'image
cam.location = target + d * 6
cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()

for f in frames:
    scene.frame_set(f)
    scene.render.filepath = os.path.join(out, f"{layer + '_' if layer else ''}{action}_{f:03d}.png")
    bpy.ops.render.render(write_still=True)
print("images :", len(frames))
