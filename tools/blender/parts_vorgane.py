"""Parties destructibles du Vorgane (non destructif pour l'animation).
À partir du fichier riggé : classe les faces d'après la TEXTURE (cristaux du dos, griffes de la patte avant
visible, glande d'Aether visible), puis crée des OBJETS SÉPARÉS qui gardent le même squelette et les mêmes
poids (ils se déforment exactement comme le corps) :
  Vorgane_base            corps sans les parties ; trous rebouchés par une « plaie » (matériau sombre)
  part_carapace / part_carapace_broken   cristaux intacts / moignons (cristaux réduits vers leur base)
  part_griffe / part_griffe_broken       griffes intactes / serres brisées
  part_glande                             glande (l'état brisé est un traitement de couleur dans Godot)
Usage : python parts_vorgane.py <vorgane_rig.blend> <vorgane_parts.blend> <rapport.json>"""
import colorsys, json, sys
import bpy, bmesh
import numpy as np
from mathutils import Vector

src, dst, rep_path = sys.argv[1:4]
bpy.ops.wm.open_mainfile(filepath=src)
body = bpy.data.objects["Vorgane"]
img = bpy.data.images[0]
W, H = img.size
pix = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)

bm = bmesh.new(); bm.from_mesh(body.data)
uv = bm.loops.layers.uv.active
bm.faces.ensure_lookup_table()


def face_color(f):
    u = sum(l[uv].uv.x for l in f.loops) / len(f.loops)
    v = sum(l[uv].uv.y for l in f.loops) / len(f.loops)
    x = int((u % 1.0) * (W - 1)); y = int((v % 1.0) * (H - 1))
    r, g, b = pix[y, x, :3]
    return colorsys.rgb_to_hsv(float(r), float(g), float(b))


# Centre de la glande visible : barycentre des faces cyan lumineuses du flanc +X, moitié avant
cy = [f.calc_center_median() for f in bm.faces
      if f.calc_center_median().x > 0.15 and f.calc_center_median().y < -0.1
      and 165 <= face_color(f)[0] * 360 <= 205 and face_color(f)[1] > 0.35 and face_color(f)[2] > 0.5]
GLAND_C = sum(cy, Vector()) / len(cy) if cy else Vector((0.36, -0.44, 0.05))
cls = {}
for f in bm.faces:
    c = f.calc_center_median()
    h, s, v = face_color(f)
    hd = h * 360
    if (c - GLAND_C).length < 0.09 and c.x > 0.12:
        cls[f.index] = "glande"
    elif c.x > 0.15 and c.y < -0.4 and c.z < -0.26 and s < 0.35 and v > 0.5:
        cls[f.index] = "griffe"
    elif c.z > 0.02 and 190 <= hd <= 300 and s > 0.2 and v > 0.3 and abs(c.x) < 0.45 and -0.75 < c.y < 0.62:
        cls[f.index] = "carapace"

# Nettoyage : une face isolée entourée d'autres classes est rattachée à la majorité de ses voisines (2 passes)
for _ in range(2):
    new = dict(cls)
    for f in bm.faces:
        nb = [cls.get(o.index) for e in f.edges for o in e.link_faces if o is not f]
        mine = cls.get(f.index)
        cnt = {k: nb.count(k) for k in set(nb)}
        best = max(cnt, key=cnt.get) if cnt else None
        if best != mine and cnt.get(best, 0) >= 3:
            if best is None:
                new.pop(f.index, None)
            else:
                new[f.index] = best
    cls = new
# Fragments restants : petits îlots non classés situés sur le dos une fois la carapace retirée -> carapace
rest = [f for f in bm.faces if f.index not in cls]
rest_set = {f.index for f in rest}
seen = set()
reassigned = 0
for f in rest:
    if f.index in seen:
        continue
    comp, st = [], [f]; seen.add(f.index)
    while st:
        c = st.pop(); comp.append(c)
        for e in c.edges:
            for o in e.link_faces:
                if o.index in rest_set and o.index not in seen:
                    seen.add(o.index); st.append(o)
    if len(comp) < 60:
        for c in comp:
            if c.calc_center_median().z > -0.05:
                cls[c.index] = "carapace"; reassigned += 1
counts = {k: sum(1 for v in cls.values() if v == k) for k in ("carapace", "griffe", "glande")}
counts["fragments_reaffectes"] = reassigned
counts["centre_glande"] = [round(x, 3) for x in GLAND_C]
body_verts = [v.co.copy() for v in bm.verts if all(cls.get(f.index) is None for f in v.link_faces)]
bm.free()
from mathutils.kdtree import KDTree
kd = KDTree(len(body_verts))
for i, co in enumerate(body_verts):
    kd.insert(co, i)
kd.balance()


def flatten_to_stumps(ob, hmax):
    """Chaque sommet de cristal est ramené à au plus `hmax` de la peau la plus proche : moignons brisés."""
    import random
    rnd = random.Random(7)
    b = bmesh.new(); b.from_mesh(ob.data)
    for v in b.verts:
        q, _, d = kd.find(v.co)
        lim = hmax * rnd.uniform(0.6, 1.4)
        if d > lim:
            v.co = q + (v.co - q).normalized() * lim
    b.to_mesh(ob.data); b.free()


def make_part(name, keep):
    """Duplique le corps et ne garde que les faces de `keep` (ensemble d'indices)."""
    ob = body.copy(); ob.data = body.data.copy(); ob.name = name
    bpy.context.scene.collection.objects.link(ob)
    b = bmesh.new(); b.from_mesh(ob.data); b.faces.ensure_lookup_table()
    bmesh.ops.delete(b, geom=[f for f in b.faces if f.index not in keep], context="FACES")
    b.to_mesh(ob.data); b.free()
    return ob


def shrink_components(ob, factor):
    """Chaque îlot (un cristal, une serre) est réduit vers le centre de sa base -> moignon brisé."""
    b = bmesh.new(); b.from_mesh(ob.data)
    seen = set()
    for v in b.verts:
        if v.index in seen:
            continue
        comp, st = [], [v]; seen.add(v.index)
        while st:
            c = st.pop(); comp.append(c)
            for e in c.link_edges:
                w = e.other_vert(c)
                if w.index not in seen:
                    seen.add(w.index); st.append(w)
        base = [x for x in comp if x.is_boundary] or comp
        bc = sum((x.co for x in base), Vector()) / len(base)
        for x in comp:
            if not x.is_boundary:
                x.co = bc + (x.co - bc) * factor
    b.to_mesh(ob.data); b.free()


parts = {}
for p in ("carapace", "griffe", "glande"):
    keep = {i for i, k in cls.items() if k == p}
    parts[p] = make_part(f"part_{p}", keep)
ob = make_part("part_carapace_broken", {i for i, k in cls.items() if k == "carapace"})
flatten_to_stumps(ob, 0.035)
parts["carapace_broken"] = ob
ob = make_part("part_griffe_broken", {i for i, k in cls.items() if k == "griffe"})
shrink_components(ob, 0.35)
parts["griffe_broken"] = ob

# Corps sans les parties ; trous rebouchés avec un matériau « plaie »
base = make_part("Vorgane_base", {f.index for f in body.data.polygons if f.index not in cls})
wound = bpy.data.materials.new("plaie")
wound.use_nodes = True
bsdf = wound.node_tree.nodes["Principled BSDF"]
bsdf.inputs["Base Color"].default_value = (0.16, 0.03, 0.07, 1)
bsdf.inputs["Roughness"].default_value = 0.6
base.data.materials.append(wound)
wi = len(base.data.materials) - 1
b = bmesh.new(); b.from_mesh(base.data)
res = bmesh.ops.holes_fill(b, edges=[e for e in b.edges if e.is_boundary], sides=0)
for f in res["faces"]:
    f.material_index = wi
holes = len(res["faces"])
b.to_mesh(base.data); b.free()
body.hide_render = True
body.hide_set(True)

rep = {"faces_par_partie": counts, "trous_rebouches": holes,
       "objets": [o.name for o in bpy.data.objects if o.type == "MESH"]}
json.dump(rep, open(rep_path, "w"), indent=1, ensure_ascii=False)
bpy.ops.wm.save_as_mainfile(filepath=dst)
print(json.dumps(rep, ensure_ascii=False))
