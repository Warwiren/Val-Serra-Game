"""Préparation du Vorgane dans Blender : correction minimale, squelette quadrupède, poids automatiques,
animations (repos, marche, coup de griffe, impact), fichier .blend modifiable et GLB animé.

Usage : python rig_vorgane.py <original.glb> <dossier_sortie>
Corrections appliquées (sur une COPIE, l'original n'est pas touché) :
  - fusion des sommets dédoublés aux coutures UV (les UV sont conservées par coin de face) ;
  - recalcul des normales vers l'extérieur ;
  - le fragment flottant de 13 sommets est conservé (attaché à la colonne).
Repère Blender après import : Z vers le haut, le monstre regarde vers -Y, +X = son flanc gauche."""
import json, math, os, sys
import bpy, bmesh
from mathutils import Vector, Euler
from bpy_extras.object_utils import world_to_camera_view

src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
mesh = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
mesh.name = "Vorgane"
bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

bm = bmesh.new(); bm.from_mesh(mesh.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(mesh.data); bm.free()
mesh.data.update()

# --- Squelette (positions issues de l'audit : appuis, profil longitudinal) -----------------------
B = {
    # nom: (tête, queue, parent)
    "root":    ((0, 0.0, -0.43), (0, 0.12, -0.43), None),
    "pelvis":  ((0, 0.28, 0.02), (0, 0.05, 0.08), "root"),
    "spine":   ((0, 0.05, 0.08), (0, -0.25, 0.10), "pelvis"),
    "chest":   ((0, -0.25, 0.10), (0, -0.52, 0.06), "spine"),
    "neck":    ((0, -0.52, 0.06), (0, -0.68, 0.00), "chest"),
    "head":    ((0, -0.68, 0.00), (0, -0.94, -0.16), "neck"),
    "jaw":     ((0, -0.70, -0.12), (0, -0.92, -0.24), "head"),
    "tail1":   ((0, 0.40, 0.00), (0, 0.56, -0.08), "pelvis"),
    "tail2":   ((0, 0.56, -0.08), (0, 0.72, -0.10), "tail1"),
    "tail3":   ((0, 0.72, -0.10), (0, 0.85, -0.02), "tail2"),
    "tail4":   ((0, 0.85, -0.02), (0, 0.94, 0.24), "tail3"),
}
for side, sx in (("L", 1), ("R", -1)):
    B[f"arm_up.{side}"] = ((0.26 * sx, -0.46, 0.04), (0.38 * sx, -0.50, -0.16), "chest")
    B[f"arm_lo.{side}"] = ((0.38 * sx, -0.50, -0.16), (0.40 * sx, -0.52, -0.36), f"arm_up.{side}")
    B[f"paw.{side}"] = ((0.40 * sx, -0.52, -0.36), (0.40 * sx, -0.64, -0.42), f"arm_lo.{side}")
    B[f"leg_up.{side}"] = ((0.22 * sx, 0.20, 0.00), (0.32 * sx, 0.14, -0.20), "pelvis")
    B[f"leg_lo.{side}"] = ((0.32 * sx, 0.14, -0.20), (0.33 * sx, 0.26, -0.36), f"leg_up.{side}")
    B[f"foot.{side}"] = ((0.33 * sx, 0.26, -0.36), (0.33 * sx, 0.14, -0.43), f"leg_lo.{side}")

arm_data = bpy.data.armatures.new("VorganeRig")
rig = bpy.data.objects.new("VorganeRig", arm_data)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
for name, (h, t, p) in B.items():
    eb = arm_data.edit_bones.new(name)
    eb.head = Vector(h); eb.tail = Vector(t)
for name, (h, t, p) in B.items():
    if p:
        eb = arm_data.edit_bones[name]
        eb.parent = arm_data.edit_bones[p]
        eb.use_connect = (Vector(arm_data.edit_bones[p].tail) - Vector(h)).length < 1e-4
arm_data.edit_bones["root"].use_deform = False
bpy.ops.object.mode_set(mode="OBJECT")

# --- Poids : la pondération automatique « Bone Heat » échoue sur ce maillage (auto-intersections des
# cristaux). On utilise une pondération géométrique contrôlée : distance aux segments d'os, dégradé doux
# entre les 3 os les plus proches, et restrictions anatomiques (côté gauche/droit, queue, tête, mâchoire).
bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True); rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type="ARMATURE_NAME")


def seg_dist(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (p - (a + ab * t)).length


def allowed(name, co):
    x, y, z = co
    side = name[-1] if "." in name else ""
    if side == "L" and x < 0.06:
        return False
    if side == "R" and x > -0.06:
        return False
    if name.startswith(("arm_", "paw")) and (z > 0.12 or y > -0.2):
        return False
    if name.startswith(("leg_", "foot")) and (z > 0.12 or y < -0.05):
        return False
    if name.startswith("tail") and y < 0.36:
        return False
    if name == "jaw":
        # sous la ligne de la gueule (fermée) : de (y=-0.70, z=-0.09) à (y=-0.95, z=-0.19)
        zline = -0.09 + (y + 0.70) / (-0.25) * (-0.10)
        return y < -0.70 and z < zline
    if name in ("head", "neck") and y > -0.4:
        return False
    return True


deform = [n for n in B if n != "root"]
segs = {n: (Vector(B[n][0]), Vector(B[n][1])) for n in deform}
vg = {n: mesh.vertex_groups.get(n) or mesh.vertex_groups.new(name=n) for n in deform}
for v in mesh.data.vertices:
    co = v.co
    cands = []
    for n in deform:
        if not allowed(n, co):
            continue
        d = seg_dist(co, *segs[n])
        cands.append((d, n))
    if not cands:
        cands = [(seg_dist(co, *segs["spine"]), "spine")]
    cands.sort()
    top = cands[:3]
    ws = [1.0 / max(d, 0.02) ** 4 for d, _ in top]
    tot = sum(ws)
    for (d, n), w in zip(top, ws):
        if w / tot > 0.02:
            vg[n].add([v.index], w / tot, "REPLACE")
unweighted = sum(1 for v in mesh.data.vertices if not any(g.weight > 0.01 for g in v.groups))
groups = {g.name: 0 for g in mesh.vertex_groups}
for v in mesh.data.vertices:
    for g in v.groups:
        if g.weight > 0.3:
            groups[mesh.vertex_groups[g.group].name] += 1

# --- Animations (rotations en degrés, axes locaux des os) ----------------------------------------
pb = rig.pose.bones
for b in pb:
    b.rotation_mode = "XYZ"


def key(action_name, frames, fps_len):
    act = bpy.data.actions.new(action_name)
    rig.animation_data_create()
    rig.animation_data.action = act
    for f, poses in frames:
        for b in pb:
            b.rotation_euler = (0, 0, 0)
            b.location = (0, 0, 0)
        for bn, val in poses.items():
            if bn.endswith(":loc"):
                pb[bn[:-4]].location = Vector(val)
            else:
                pb[bn].rotation_euler = Euler([math.radians(x) for x in val])
        for b in pb:
            b.keyframe_insert("rotation_euler", frame=f)
            b.keyframe_insert("location", frame=f)
    act.use_fake_user = True
    track = rig.animation_data.nla_tracks.new()
    track.name = action_name
    track.strips.new(action_name, 1, act)
    rig.animation_data.action = None
    return act


breath = {"chest": (3, 0, 0), "neck": (-2, 0, 0), "head": (-2, 0, 0), "tail2": (0, 0, 4), "tail3": (0, 0, 6), "jaw": (4, 0, 0)}
key("idle", [(1, {}), (25, breath), (49, {})], 48)
key("claw", [
    (1, {}),
    (10, {"arm_up.L": (28, 0, -6), "arm_lo.L": (-45, 0, 0), "paw.L": (-30, 0, 0), "chest": (-6, 0, 0), "neck": (-10, 0, 0), "head": (-12, 0, 0), "jaw": (16, 0, 0), "root:loc": (0, 0.1, 0.03)}),
    (14, {"arm_up.L": (-48, 0, 0), "arm_lo.L": (26, 0, 0), "paw.L": (24, 0, 0), "chest": (8, 0, 0), "head": (10, 0, 0), "jaw": (8, 0, 0), "root:loc": (0, -0.22, -0.03)}),
    (18, {"arm_up.L": (-42, 0, 0), "arm_lo.L": (30, 0, 0), "paw.L": (30, 0, 0), "chest": (8, 0, 0), "head": (8, 0, 0), "jaw": (4, 0, 0), "root:loc": (0, -0.22, -0.03)}),
    (30, {}),
], 30)
key("hit", [(1, {}), (5, {"chest": (-8, 0, 6), "neck": (-10, 0, 8), "head": (-14, 0, 6), "jaw": (14, 0, 0), "root:loc": (0, 0.08, 0)}), (18, {})], 18)
walk = []
for i, ph in enumerate([0, 1, 2, 3, 4]):
    s = 1 if ph % 2 == 0 else -1
    if ph == 4:
        s = 1
    walk.append((1 + i * 8, {
        "arm_up.L": (22 * s, 0, 0), "arm_lo.L": (-15 * max(0, s), 0, 0),
        "arm_up.R": (-22 * s, 0, 0), "arm_lo.R": (-15 * max(0, -s), 0, 0),
        "leg_up.L": (-20 * s, 0, 0), "leg_lo.L": (18 * max(0, -s), 0, 0),
        "leg_up.R": (20 * s, 0, 0), "leg_lo.R": (18 * max(0, s), 0, 0),
        "spine": (0, 0, 3 * s), "tail2": (0, 0, -6 * s), "tail3": (0, 0, -8 * s), "head": (0, 0, -3 * s),
        "root:loc": (0, 0, 0.015 * (1 if ph % 2 else 0)),
    }))
key("walk", walk, 32)

# --- Rapport, fichiers --------------------------------------------------------------------------
rep = {"os": len(B), "sommets": len(mesh.data.vertices), "sommets_sans_poids": unweighted,
       "sommets_par_os_(poids>0.3)": groups, "animations": [a.name for a in bpy.data.actions]}
json.dump(rep, open(os.path.join(out, "rig_rapport.json"), "w"), indent=1, ensure_ascii=False)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, "vorgane_rig.blend"))
bpy.ops.export_scene.gltf(filepath=os.path.join(out, "vorgane_rig.glb"), export_animations=True,
                          export_animation_mode="NLA_TRACKS", export_skins=True)

# Projection du squelette sur une vue de profil (pour contrôle visuel)
scene = bpy.context.scene
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"; cam.data.ortho_scale = 2.4
cam.location = (3, 0, 0); cam.rotation_euler = (math.radians(90), 0, math.radians(90))
scene.collection.objects.link(cam); scene.camera = cam
scene.render.resolution_x = 900; scene.render.resolution_y = 900
proj = {}
for name, (h, t, p) in B.items():
    a = world_to_camera_view(scene, cam, Vector(h)); b = world_to_camera_view(scene, cam, Vector(t))
    proj[name] = [[a.x, 1 - a.y], [b.x, 1 - b.y]]
json.dump(proj, open(os.path.join(out, "os_profil.json"), "w"), indent=1)
print(json.dumps(rep, ensure_ascii=False))
