from pathlib import Path
root=Path('/mnt/data')
out=root/'ValSerra_P49_V07_FORET_STYLISEE_TEST'
src=root/'ValSerra_P49_V06_1_RUISSEAU_TEST/godot/P49_V061_Ruisseau_Test.gd'
s=src.read_text()
s=s.replace('P4.9 / V06.1 — BAC À SABLE JOUABLE ISOLÉ.','P4.9 / V07 — FORET STYLISEE QUATERNIUS — BAC A SABLE ISOLE.')
s=s.replace('res://ValSerra_P49_V06_1_RUISSEAU_TEST/','res://ValSerra_P49_V07_FORET_STYLISEE_TEST/')
s=s.replace('const MANIFEST := ROOT + "docs/P49_V061_GODOT_MANIFEST.json"','const MANIFEST := ROOT + "docs/V07_WORLD.json"')
s=s.replace('P49_V061_ForwardPlus_NotValidated','P49_V07_ForwardPlus_NotValidated')
s=s.replace('P30_Follow_Camera','P30_V07_Follow_Camera')
s=s.replace('\t_load_blockout_props()\n','\t# IMPORTANT: aucun des anciens arbres de blocage V06.1 ne charge en V07.\n')
s=s.replace('for filename in ["EAU061_eau_calme.glb", "EAU061_courant_leger.glb"]:','for filename in _data.get("water_assets", []):')
s=s.replace('var path := ROOT + "assets/" + name','var path := ROOT + "assets/" + name')
s=s.replace('"EAU_" + filename.get_basename()','"EAU_" + filename.get_file().get_basename()')
s=s.replace('ROOT + "assets/EAU061_bruit_rides.png"','ROOT + "assets/eau/EAU061_bruit_rides.png"')
s=s.replace('"P4.9 V06.1 — 36×28 m / RUISSEAU NON FINAL','"P4.9 V07 — 36×28 m / FORET STYLISEE (TEST)')
s=s.replace('KEY_H:\n\t\t\t_show_hud', 'KEY_N: _forest_root.visible = not _forest_root.visible\n\t\tKEY_H:\n\t\t\t_show_hud')
s=s.replace('M : repères · F : brume · V : eau mobile · H : interface','M : repères · F : brume · V : eau mobile · N : végétation · H : interface')
# replace the entire set dressing block including old function for blockout and collision; new function.
start=s.index('func _load_blockout_props() -> void:')
end=s.index('func _toggle_water_shader() -> void:',start)
s=s[:start]+'''# Le décor original était un blocage purement géométrique. Ne plus le charger.
var _forest_root: Node3D
var _model_cache: Dictionary = {}

func _tinted_material(base: Material, tint: Color) -> Material:
    if base == null:
        return null
    var result := base.duplicate(true) as Material
    if result is BaseMaterial3D:
        var shaded := result as BaseMaterial3D
        shaded.albedo_color = shaded.albedo_color * tint
        # Ne jamais détruire l'alpha masque des feuilles ; seulement coloriser le matériau.
        shaded.roughness = maxf(0.72, shaded.roughness)
    return result

func _tint_tree(node: Node, tint: Color) -> void:
    if node is MeshInstance3D:
        var mesh_inst := node as MeshInstance3D
        var mesh := mesh_inst.mesh
        if mesh != null:
            for surf_i in range(mesh.get_surface_count()):
                var original := mesh.surface_get_material(surf_i)
                if original != null:
                    mesh_inst.set_surface_override_material(surf_i, _tinted_material(original, tint))
        mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    for child in node.get_children():
        _tint_tree(child, tint)

''' +s[end:]
start=s.index('func _load_set_dressing() -> void:')
end=s.index('func _add_set_collider(',start)
s=s[:start]+'''func _load_set_dressing() -> void:
    _forest_root = Node3D.new()
    _forest_root.name = "FORET_V07_Quaternius_CC0"
    add_child(_forest_root)
    var grouped: Dictionary = {}
    for placement in _data.get("placements", []):
        var filename := String(placement["asset"])
        var style := String(placement.get("style", "forest"))
        var key := filename + "|" + style
        if not grouped.has(key):
            grouped[key] = []
        (grouped[key] as Array).append(placement)
    var total := 0
    for key in grouped.keys():
        var entries: Array = grouped[key]
        if entries.is_empty():
            continue
        var filename := String(entries[0]["asset"])
        var tint_data: Array = entries[0]["tint"]
        var tint := Color(float(tint_data[0]), float(tint_data[1]), float(tint_data[2]))
        var scene: PackedScene
        if _model_cache.has(filename):
            scene = _model_cache[filename] as PackedScene
        else:
            scene = _load_asset(filename)
            if scene == null:
                continue
            _model_cache[filename] = scene
        var test := scene.instantiate() as Node3D
        var mesh_inst := _first_mesh(test)
        var batchable := mesh_inst != null and mesh_inst.mesh != null and mesh_inst.mesh.get_surface_count() == 1
        var is_hero := String(entries[0].get("role", "")) in ["tree", "rock"]
        if batchable and not is_hero:
            var mult := MultiMesh.new()
            mult.transform_format = MultiMesh.TRANSFORM_3D
            mult.mesh = mesh_inst.mesh
            mult.instance_count = entries.size()
            for i in range(entries.size()):
                var p: Dictionary = entries[i]
                var xyz: Array = p["xyz"]
                var sc := float(p["scale"])
                var rad := deg_to_rad(float(p["rotation_y_deg"]))
                var tr := Transform3D(Basis(Vector3.UP, rad).scaled(Vector3.ONE * sc), Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2])))
                mult.set_instance_transform(i, tr)
            var batches := MultiMeshInstance3D.new()
            batches.name = "VEG_BATCH_" + filename.get_file().get_basename() + "_" + String(entries[0]["style"])
            batches.multimesh = mult
            batches.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            batches.material_override = _tinted_material(mesh_inst.mesh.surface_get_material(0), tint)
            _forest_root.add_child(batches)
            total += entries.size()
        else:
            for p in entries:
                var obj := scene.instantiate() as Node3D
                if obj == null:
                    continue
                _forest_root.add_child(obj)
                obj.name = String(p["name"]) + "_V07"
                var xyz: Array = p["xyz"]
                var sc := float(p["scale"])
                obj.position = Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2]))
                obj.rotation_degrees.y = float(p["rotation_y_deg"])
                obj.scale = Vector3.ONE * sc
                _tint_tree(obj, tint)
                if bool(p.get("blocking", false)):
                    _add_set_collider(obj.position, sc, "tree")
                total += 1
        test.free()
    print("V07: placed %d styled Quaternius instances in %d groups" % [total, grouped.size()])

''' +s[end:]
# Fix material access if cast to packed scene succeeded etc.
s=s.replace('P49 V06.1', 'P49 V07')
s=s.replace('_add_set_collider(obj.position, sc, "tree")', '_add_set_collider(obj.position, sc, "rock" if String(p["role"]) == "rock" else "tree")')
s=s.replace('shape.radius = (0.48 if kind == "tree" else .42) * scale_factor', 'shape.radius = (0.48 if kind == "tree" else 1.25) * scale_factor')
s=s.replace('shape.height = (2.1 if kind == "tree" else .55) * scale_factor', 'shape.height = (2.1 if kind == "tree" else 1.3) * scale_factor')
s=s.replace('String(tile).get_basename()','String(tile).get_file().get_basename()')
s=s.replace('P49_V061_Ruisseau_Test.gd','P49_V07_Foret_Test.gd')
s=s.replace('\t# Invisible safety colliders. The test scene is intentionally self contained.', '\t# Joue non praticable de décor : même frontière que le sol jouable, aucun collider.\n\tfor file_name in _data.get("non_colliding_decor", []):\n\t\tvar decoration := _load_asset(String(file_name))\n\t\tif decoration != null:\n\t\t\tvar instance := decoration.instantiate() as Node3D\n\t\t\tinstance.name = "V07_FOND_HORS_JEU"\n\t\t\tadd_child(instance)\n\t# Invisible safety colliders. The test scene is intentionally self contained.')
s=s.replace('\tadd_child(body)\n\nfunc _make_actor(', '\t_forest_root.add_child(body)\n\nfunc _make_actor(')
# Override scene name for water and terrain paths already relative.
(out/'godot/P49_V07_Foret_Test.gd').write_text(s)
(out/'godot/P49_V07_Foret_Test.tscn').write_text('''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://ValSerra_P49_V07_FORET_STYLISEE_TEST/godot/P49_V07_Foret_Test.gd" id="1_script"]

[node name="P49_V07_Foret_Test_ISOLE" type="Node3D"]
script = ExtResource("1_script")
''')
print('scripts created',len(s.splitlines()))
