"""Audit de la topologie RÉELLE : fusion des sommets dédoublés aux coutures UV (sur une copie en mémoire),
puis îlots, bords ouverts, et coupes horizontales pour repérer pattes, queue et tête.
Usage : python audit_topology.py <modele.glb> <rapport.json>"""
import json, sys
import bpy, bmesh
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=sys.argv[1])
o = [x for x in bpy.context.scene.objects if x.type == "MESH"][0]
bm = bmesh.new(); bm.from_mesh(o.data); bm.transform(o.matrix_world)
before = len(bm.verts)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
after = len(bm.verts)
bm.edges.ensure_lookup_table()
boundary = sum(1 for e in bm.edges if e.is_boundary)
nonman = sum(1 for e in bm.edges if not e.is_manifold and not e.is_boundary)
# îlots réels
seen = set(); islands = []
for v in bm.verts:
    if v.index in seen: continue
    st = [v]; seen.add(v.index); n = 0; zs = []; ys = []; xs = []
    while st:
        c = st.pop(); n += 1; zs.append(c.co.z); ys.append(c.co.y); xs.append(c.co.x)
        for e in c.link_edges:
            w = e.other_vert(c)
            if w.index not in seen: seen.add(w.index); st.append(w)
    islands.append({"sommets": n, "x": [round(min(xs), 3), round(max(xs), 3)], "y": [round(min(ys), 3), round(max(ys), 3)], "z": [round(min(zs), 3), round(max(zs), 3)]})
islands.sort(key=lambda d: -d["sommets"])
# Coupes : nombre de « colonnes » au ras du sol (pattes) — regroupement des sommets sous z_min + 12 cm
zmin = min(v.co.z for v in bm.verts)
low = [v.co for v in bm.verts if v.co.z < zmin + 0.12]
clusters = []
for p in low:
    for c in clusters:
        if (c["c"] - p).length < 0.18:
            c["pts"].append(p); c["c"] = sum(c["pts"], Vector()) / len(c["pts"]); break
    else:
        clusters.append({"c": p.copy(), "pts": [p]})
feet = [{"centre": [round(c["c"].x, 2), round(c["c"].y, 2)], "sommets": len(c["pts"])} for c in clusters if len(c["pts"]) > 20]
# Profil : hauteur max par tranche de longueur (Y) -> silhouette, cou, queue
ymin = min(v.co.y for v in bm.verts); ymax = max(v.co.y for v in bm.verts)
prof = []
for i in range(12):
    a = ymin + (ymax - ymin) * i / 12; b = ymin + (ymax - ymin) * (i + 1) / 12
    sl = [v.co for v in bm.verts if a <= v.co.y < b]
    if sl:
        prof.append({"y": [round(a, 2), round(b, 2)], "z_bas": round(min(p.z for p in sl), 2), "z_haut": round(max(p.z for p in sl), 2),
                     "largeur_x": round(max(p.x for p in sl) - min(p.x for p in sl), 2), "sommets": len(sl)})
rep = {"sommets_avant_fusion": before, "sommets_apres_fusion": after, "aretes_de_bord_reelles": boundary,
       "aretes_non_manifold_reelles": nonman, "nb_ilots_reels": len(islands), "ilots": islands[:10],
       "appuis_au_sol": feet, "profil_longitudinal": prof}
json.dump(rep, open(sys.argv[2], "w"), indent=1, ensure_ascii=False)
print(json.dumps({k: rep[k] for k in ("sommets_avant_fusion", "sommets_apres_fusion", "aretes_de_bord_reelles", "aretes_non_manifold_reelles", "nb_ilots_reels")}))
for i in islands[:10]: print("ilot", i)
for f in feet: print("appui", f)
for p in prof: print("tranche", p)
