"""Points d'ancrage par image (projection caméra identique à render_frames.py, vue de profil) :
glande, griffe, carapace (sommet du dos), gueule. Sert au ciblage et aux effets dans Godot.
Usage : python anchors_vorgane.py <vorgane_parts.blend> <sortie.json> <taille_rendu> action:images ..."""
import json, math, sys
import bpy
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

blend, outp, size = sys.argv[1], sys.argv[2], int(sys.argv[3])
bpy.ops.wm.open_mainfile(filepath=blend)
scene = bpy.context.scene
rig = bpy.data.objects["VorganeRig"]
for t in rig.animation_data.nla_tracks:
    t.mute = True
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"; cam.data.ortho_scale = 2.6
scene.collection.objects.link(cam); scene.camera = cam
scene.render.resolution_x = size; scene.render.resolution_y = size
target = Vector((0, -0.05, -0.05))
cam.location = target + Vector((1, 0, 0.12)).normalized() * 6
cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()


def centroid(name, top=False):
    ob = bpy.data.objects[name]
    dg = bpy.context.evaluated_depsgraph_get()
    me = ob.evaluated_get(dg).to_mesh()
    pts = [ob.matrix_world @ v.co for v in me.vertices]
    ob.evaluated_get(dg).to_mesh_clear()
    if top:
        pts.sort(key=lambda p: -p.z)
        pts = pts[: max(1, len(pts) // 6)]
    return sum(pts, Vector()) / len(pts)


res = {"taille_rendu": size, "images": {}}
for spec in sys.argv[4:]:
    action, frames = spec.split(":")
    rig.animation_data.action = bpy.data.actions[action]
    for f in [int(x) for x in frames.split(",")]:
        scene.frame_set(f)
        pts = {"glande": centroid("part_glande"), "griffe": centroid("part_griffe"),
               "carapace": centroid("part_carapace", top=True),
               "gueule": rig.matrix_world @ rig.pose.bones["head"].tail}
        out = {}
        for k, p in pts.items():
            c = world_to_camera_view(scene, cam, p)
            out[k] = [round(c.x * size, 1), round((1 - c.y) * size, 1)]
        res["images"][f"{action}_{f:03d}"] = out
json.dump(res, open(outp, "w"), indent=1)
print("ancrages :", len(res["images"]))
