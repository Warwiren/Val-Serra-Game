"""GABARITS pour l'illustration de l'exploration, rendus depuis LA scène Blender du jeu (même géométrie, même
caméra orthographique 35°/20°, même lumière) à la taille d'affichage : 1408×800 (×2 du natif 704×400).
Réutilise tools/explore/scene_blender.py jusqu'à la caméra (aucune géométrie n'est modifiée), puis rend :
  terrain_sans_objets.png       sol, chemin, lisière de forêt ; aucun objet, aucune ombre d'objet
  terrain_ombres_objets.png     idem avec les ombres portées des objets (= base actuelle du fond)
  terrain_ombre_maison.png      sol avec la seule ombre de la maison
  terrain_ombre_arbre.png       sol avec la seule ombre du grand arbre
  maison_seule.png              maison complète (non coupée par les caisses, lanternes…), fond transparent
  maison_zones.png              carte des matières de la maison (couleurs unies, voir legende.json)
  arbre_seul.png / arbre_zones.png   grand arbre (« arbre_g ») complet, tronc / feuillage
Tous ces fichiers sont à l'échelle de l'écran et RECALÉS sur le même cadre 1408×800 (calques superposables).
Usage : python gabarits_blender.py <dossier_sortie> [échantillons=32]"""
import json, os, sys

OUT = sys.argv[1]
SAMPLES = int(sys.argv[2]) if len(sys.argv) > 2 else 32
ONLY_DEPTH = len(sys.argv) > 3 and sys.argv[3] == "profondeur"     # seulement les cartes de profondeur
HERE = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(HERE, "scene_blender.py"), encoding="utf-8").read()
cut = src.index('bpy.context.view_layer.update()\nrender(os.path.join(OUT, "plate.png")')
sys.argv = [sys.argv[0], OUT, "20", "2", str(SAMPLES)]       # ppm 20, SS 2 -> 1408×800
g = {"__name__": "scene"}
exec(compile(src[:cut], "scene_blender.py", "exec"), g)
bpy = g["bpy"]; sc = g["sc"]; GROUPS = g["GROUPS"]; render = g["render"]
meshes = [o for o in sc.objects if o.type == "MESH"]
grouped = {o for objs in GROUPS.values() for o in objs}


def setup(camera_groups=(), shadow_groups=(), terrain=True):
    """camera_groups : objets vus ; shadow_groups : objets invisibles mais qui projettent leur ombre."""
    for o in meshes:
        gname = next((k for k, v in GROUPS.items() if o in v), None)
        if o in grouped:
            o.hide_render = not (gname in camera_groups or gname in shadow_groups)
            o.visible_camera = gname in camera_groups
        else:                                                   # sol, chemin, forêt, herbes : le terrain
            o.hide_render = not terrain
            o.visible_camera = True
    bpy.context.view_layer.update()




def depth_maps():
    """Cartes de profondeur (blanc = proche de la caméra) : base pour une génération guidée (ControlNet
    « depth ») ou pour vérifier une repeinture. Même cadre 1408×800."""
    mat = bpy.data.materials.new("profondeur"); mat.use_nodes = True
    nt = mat.node_tree; nt.nodes.clear()
    cam_n = nt.nodes.new("ShaderNodeCameraData")
    mr = nt.nodes.new("ShaderNodeMapRange"); mr.inputs["From Min"].default_value = 22.0; mr.inputs["From Max"].default_value = 62.0
    mr.inputs["To Min"].default_value = 1.0; mr.inputs["To Max"].default_value = 0.0
    em = nt.nodes.new("ShaderNodeEmission"); out = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(cam_n.outputs["View Z Depth"], mr.inputs["Value"]); nt.links.new(mr.outputs["Result"], em.inputs["Color"])
    nt.links.new(em.outputs[0], out.inputs[0])
    saved = {o: [sl.material for sl in o.material_slots] for o in meshes}
    for o in meshes:
        for sl in o.material_slots:
            sl.material = mat
    for l in [o for o in sc.objects if o.type == "LIGHT"]:
        l.hide_render = True
    strength = sc.world.node_tree.nodes["Background"].inputs["Strength"].default_value
    sc.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0
    sc.view_settings.view_transform = "Standard"
    setup(); render(os.path.join(OUT, "profondeur_terrain.png"), 2)
    setup(camera_groups=["maison"], terrain=False); render(os.path.join(OUT, "profondeur_maison.png"), 2, transparent=True)
    setup(camera_groups=["arbre_g"], terrain=False); render(os.path.join(OUT, "profondeur_arbre.png"), 2, transparent=True)
    for o, mats in saved.items():
        for sl, m in zip(o.material_slots, mats):
            sl.material = m
    for l in [o for o in sc.objects if o.type == "LIGHT"]:
        l.hide_render = False
    sc.world.node_tree.nodes["Background"].inputs["Strength"].default_value = strength


if ONLY_DEPTH:
    depth_maps()
    sys.exit(0)
setup(); render(os.path.join(OUT, "terrain_sans_objets.png"), SAMPLES)
setup(shadow_groups=list(GROUPS)); render(os.path.join(OUT, "terrain_ombres_objets.png"), SAMPLES)
setup(shadow_groups=["maison"]); render(os.path.join(OUT, "terrain_ombre_maison.png"), SAMPLES)
setup(shadow_groups=["arbre_g"]); render(os.path.join(OUT, "terrain_ombre_arbre.png"), SAMPLES)
setup(camera_groups=["maison"], terrain=False); render(os.path.join(OUT, "maison_seule.png"), SAMPLES, transparent=True)
setup(camera_groups=["arbre_g"], terrain=False); render(os.path.join(OUT, "arbre_seul.png"), SAMPLES, transparent=True)
depth_maps()

# --- cartes de zones : chaque matière en couleur unie (émission, sans lumière) --------------------------------
ZONES = {"ardoise": (0.75, 0.15, 0.15), "mousse": (0.2, 0.8, 0.2), "enduit": (0.95, 0.85, 0.6), "poutre": (0.45, 0.25, 0.1),
         "bois": (1.0, 0.5, 0.1), "pierre": (0.55, 0.55, 0.6), "vitre": (1.0, 1.0, 0.0), "fer": (0.1, 0.1, 0.9),
         "tissu": (0.2, 0.4, 1.0), "fleur": (1.0, 0.3, 1.0), "ecorce": (0.55, 0.3, 0.15), "feuilles": (0.1, 0.6, 0.3)}
flat = {}
for k, c in ZONES.items():
    m = bpy.data.materials.new("zone_" + k); m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear()
    e = nt.nodes.new("ShaderNodeEmission"); e.inputs["Color"].default_value = (*c, 1); e.inputs["Strength"].default_value = 1
    o_ = nt.nodes.new("ShaderNodeOutputMaterial"); nt.links.new(e.outputs[0], o_.inputs[0])
    flat[k] = m
for o in grouped:
    for i, slot in enumerate(o.material_slots):
        base = slot.material.name.split(".")[0] if slot.material else ""
        key = next((k for k in ZONES if base.startswith(k)), None)
        if key:
            o.material_slots[i].material = flat[key]
for l in [o for o in sc.objects if o.type == "LIGHT"]:
    l.hide_render = True
sc.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0
sc.view_settings.view_transform = "Standard"
setup(camera_groups=["maison"], terrain=False); render(os.path.join(OUT, "maison_zones.png"), 4, transparent=True)
setup(camera_groups=["arbre_g"], terrain=False); render(os.path.join(OUT, "arbre_zones.png"), 4, transparent=True)
json.dump({k: "#%02X%02X%02X" % tuple(int(v * 255) for v in c) for k, c in ZONES.items()},
          open(os.path.join(OUT, "legende_zones.json"), "w"), indent=1)
print("gabarits rendus dans", OUT)
