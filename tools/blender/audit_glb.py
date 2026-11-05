"""Audit technique d'un modèle GLB dans Blender (exécuté avec le module officiel bpy).
Usage : python audit_glb.py <modele.glb> <dossier_sortie>
Produit : rapport JSON (dimensions, topologie, normales, UV, textures, îlots) + rendus sous 4 angles.
Le GLB d'origine n'est jamais modifié."""
import json, math, os, sys
import bpy, bmesh
from mathutils import Vector

src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)

report = {"fichier": os.path.basename(src), "objets": [], "materiaux": [], "images": []}
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
report["types_objets"] = sorted({o.type for o in bpy.context.scene.objects})
report["armature_presente"] = any(o.type == "ARMATURE" for o in bpy.context.scene.objects)
report["animations"] = [a.name for a in bpy.data.actions]

mins = Vector((1e9, 1e9, 1e9)); maxs = Vector((-1e9, -1e9, -1e9))
for o in meshes:
    me = o.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.transform(o.matrix_world)
    for v in bm.verts:
        mins = Vector((min(mins.x, v.co.x), min(mins.y, v.co.y), min(mins.z, v.co.z)))
        maxs = Vector((max(maxs.x, v.co.x), max(maxs.y, v.co.y), max(maxs.z, v.co.z)))
    tris = sum(len(f.verts) - 2 for f in bm.faces)
    quads = sum(1 for f in bm.faces if len(f.verts) == 4)
    ngons = sum(1 for f in bm.faces if len(f.verts) > 4)
    non_manifold = sum(1 for e in bm.edges if not e.is_manifold)
    boundary = sum(1 for e in bm.edges if e.is_boundary)
    loose_v = sum(1 for v in bm.verts if not v.link_edges)
    zero_area = sum(1 for f in bm.faces if f.calc_area() < 1e-10)
    # Normales : faces dont l'orientation est incohérente avec leurs voisines
    bm.normal_update()
    flipped_pairs = 0
    for e in bm.edges:
        if len(e.link_faces) == 2:
            f1, f2 = e.link_faces
            # deux faces voisines cohérentes parcourent l'arête en sens opposés
            v1 = [v.index for v in f1.verts]; v2 = [v.index for v in f2.verts]
            a, b = e.verts[0].index, e.verts[1].index
            i1 = v1.index(a); i2 = v2.index(a)
            d1 = v1[(i1 + 1) % len(v1)] == b
            d2 = v2[(i2 + 1) % len(v2)] == b
            if d1 == d2:
                flipped_pairs += 1
    # Îlots (parties de maillage non connectées)
    islands = []
    seen = set()
    for v in bm.verts:
        if v.index in seen:
            continue
        stack = [v]; seen.add(v.index); comp = []
        while stack:
            c = stack.pop(); comp.append(c)
            for e in c.link_edges:
                w = e.other_vert(c)
                if w.index not in seen:
                    seen.add(w.index); stack.append(w)
        cmin = Vector((min(p.co.x for p in comp), min(p.co.y for p in comp), min(p.co.z for p in comp)))
        cmax = Vector((max(p.co.x for p in comp), max(p.co.y for p in comp), max(p.co.z for p in comp)))
        islands.append({"sommets": len(comp), "min": [round(x, 3) for x in cmin], "max": [round(x, 3) for x in cmax]})
    islands.sort(key=lambda d: -d["sommets"])
    report["objets"].append({
        "nom": o.name, "sommets": len(bm.verts), "faces": len(bm.faces), "triangles": tris,
        "quads": quads, "ngons": ngons, "aretes_non_manifold": non_manifold, "aretes_de_bord": boundary,
        "sommets_isoles": loose_v, "faces_degenerees": zero_area, "paires_de_normales_incoherentes": flipped_pairs,
        "uv": [uv.name for uv in me.uv_layers], "couleurs_de_sommets": [c.name for c in me.color_attributes],
        "nb_ilots": len(islands), "ilots_principaux": islands[:12],
        "modificateurs": [m.type for m in o.modifiers],
        "materiaux": [m.name for m in me.materials if m],
    })
    bm.free()

report["dimensions_m"] = [round(maxs[i] - mins[i], 3) for i in range(3)]
report["boite_min"] = [round(x, 3) for x in mins]
report["boite_max"] = [round(x, 3) for x in maxs]
for m in bpy.data.materials:
    nodes = [n.type for n in m.node_tree.nodes] if m.use_nodes else []
    report["materiaux"].append({"nom": m.name, "noeuds": nodes})
for img in bpy.data.images:
    report["images"].append({"nom": img.name, "taille": list(img.size), "canaux": img.channels})

json.dump(report, open(os.path.join(out, "audit.json"), "w"), indent=1, ensure_ascii=False)

# --- Rendus sous 4 angles (Cycles CPU, éclairage neutre) ---------------------------------------
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 24
scene.render.resolution_x = 640
scene.render.resolution_y = 640
scene.render.film_transparent = False
world = bpy.data.worlds.new("w"); scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.18, 0.2, 0.24, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.8
center = (mins + maxs) / 2
size = max(maxs - mins)
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 3.0
sun.rotation_euler = (math.radians(50), 0, math.radians(30))
scene.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
cam.data.ortho_scale = size * 1.25
scene.collection.objects.link(cam)
scene.camera = cam
# glTF : +Y en haut dans le fichier, converti en +Z en haut dans Blender ; l'avant d'un modèle Meshy est
# souvent -Y ou +Y : les 4 vues permettent de le vérifier visuellement.
views = {"face": (0, -1, 0), "profil": (1, 0, 0), "arriere": (0, 1, 0), "trois_quarts": (0.7, -0.7, 0.35)}
for name, d in views.items():
    dv = Vector(d).normalized()
    cam.location = center + dv * size * 3
    look = (center - cam.location).normalized()
    cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(out, f"vue_{name}.png")
    bpy.ops.render.render(write_still=True)
print(json.dumps({k: report[k] for k in ("dimensions_m", "types_objets", "armature_presente")}, ensure_ascii=False))
