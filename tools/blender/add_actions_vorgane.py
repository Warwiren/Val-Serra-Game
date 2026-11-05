"""Ajoute au Vorgane (fichier à parties séparées) deux animations de la phase d'attaque annoncée :
  charge  : le corps s'abaisse et se contracte, la tête se tend vers l'avant, la queue se lève (boucle tenue)
  release : relâchement — poussée vers l'avant, cou et tête projetés, mâchoire ouverte, retour au repos
Mêmes conventions que rig_vorgane.py (rotations en degrés, axes locaux ; la tête est du côté -Y).
Le fichier source n'est pas modifié : le résultat est enregistré sous un nouveau nom.
Usage : python add_actions_vorgane.py <vorgane_parts.blend> <sortie.blend>"""
import math, sys
import bpy
from mathutils import Euler, Vector

src, dst = sys.argv[1:3]
bpy.ops.wm.open_mainfile(filepath=src)
rig = bpy.data.objects["VorganeRig"]
pb = rig.pose.bones
for b in pb:
    b.rotation_mode = "XYZ"


BODY = bpy.data.objects["Vorgane_base"]


def lowest_z() -> float:
    dg = bpy.context.evaluated_depsgraph_get()
    ev = BODY.evaluated_get(dg)
    m = ev.to_mesh()
    z = min((BODY.matrix_world @ v.co).z for v in m.vertices)
    ev.to_mesh_clear()
    return z


def plant(poses, ground):
    """Ancrage au sol : décale la racine pour que le point le plus bas du corps reste au niveau du sol."""
    for b in pb:
        b.rotation_euler = (0, 0, 0)
        b.location = (0, 0, 0)
    for bn, val in poses.items():
        if bn.endswith(":loc"):
            pb[bn[:-4]].location = Vector(val)
        else:
            pb[bn].rotation_euler = Euler([math.radians(x) for x in val])
    bpy.context.view_layer.update()
    dz = ground - lowest_z()
    loc = list(poses.get("root:loc", (0, 0, 0)))
    # la racine est un os : on mesure l'effet d'un déplacement unitaire pour convertir dz dans son repère
    pb["root"].location = Vector(loc) + Vector((0, 0, 0.1))
    bpy.context.view_layer.update()
    out = dict(poses)
    probe = lowest_z()
    unit = probe - (ground - dz)            # variation du point bas pour +0,1 sur l'axe z local de la racine
    if abs(unit) > 1e-4:
        loc[2] += dz * 0.1 / unit
    out["root:loc"] = tuple(loc)
    return out


def key(action_name, frames):
    if action_name in bpy.data.actions:
        bpy.data.actions.remove(bpy.data.actions[action_name])
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
    rig.animation_data.action = None


# Posture ramassée : appuis fléchis, buste bas, cou tendu, tête basse orientée vers l'avant, queue levée
CROUCH = {
    "root:loc": (0, 0.10, -0.15),
    "leg_up.L": (30, 0, 0), "leg_lo.L": (-50, 0, 0), "leg_up.R": (30, 0, 0), "leg_lo.R": (-50, 0, 0),
    "arm_up.L": (-26, 0, 0), "arm_lo.L": (42, 0, 0), "arm_up.R": (-26, 0, 0), "arm_lo.R": (42, 0, 0),
    "spine": (-8, 0, 0), "chest": (10, 0, 0), "neck": (22, 0, 0), "head": (-26, 0, 0), "jaw": (10, 0, 0),
    "tail2": (-22, 0, 0), "tail3": (-30, 0, 0),
}
CROUCH_B = dict(CROUCH, **{"root:loc": (0, 0.10, -0.165), "chest": (12, 0, 0), "tail3": (-36, 0, 0), "jaw": (13, 0, 0)})
rig.animation_data.action = None
_muted = [t.mute for t in rig.animation_data.nla_tracks]
for t in rig.animation_data.nla_tracks:
    t.mute = True                          # mesure du sol sur la pose de repos pure (sans pistes NLA)
for bb in pb:
    bb.rotation_euler = (0, 0, 0)
    bb.location = (0, 0, 0)
bpy.context.view_layer.update()
GROUND = lowest_z()                       # sol = point le plus bas au repos
CROUCH = plant(plant(CROUCH, GROUND), GROUND)
CROUCH_B = plant(plant(CROUCH_B, GROUND), GROUND)
MID = plant(plant({k: tuple(v * 0.6 for v in val) for k, val in CROUCH.items()}, GROUND), GROUND)
key("charge", [(1, {}), (8, MID), (14, CROUCH), (20, CROUCH_B), (26, CROUCH)])
LUNGE = {
    "root:loc": (0, -0.30, 0.02),
    "leg_up.L": (-28, 0, 0), "leg_lo.L": (10, 0, 0), "leg_up.R": (-16, 0, 0), "leg_lo.R": (6, 0, 0),
    "arm_up.L": (-40, 0, 0), "arm_lo.L": (24, 0, 0), "arm_up.R": (-34, 0, 0), "arm_lo.R": (20, 0, 0),
    "chest": (-12, 0, 0), "neck": (-24, 0, 0), "head": (-14, 0, 0), "jaw": (30, 0, 0),
    "tail2": (14, 0, 0), "tail3": (16, 0, 0),
}
LUNGE = plant(plant(LUNGE, GROUND), GROUND)
key("release", [(1, CROUCH), (5, LUNGE), (9, LUNGE), (18, {})])
for t, m in zip(rig.animation_data.nla_tracks, _muted):
    t.mute = m
bpy.ops.wm.save_as_mainfile(filepath=dst)
print("actions :", [a.name for a in bpy.data.actions])
