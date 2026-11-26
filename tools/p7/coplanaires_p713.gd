extends SceneTree
## P7.13 — Recherche des faces coplanaires superposées dans la ville (cause classique de clignotement « z-fighting »).
## Les maillages de la ville sont fusionnés par matière : l'outil P6.3.2 (paires de BoxMesh) ne s'applique pas. On exporte
## donc tous les triangles visibles (repère monde, nœud, matière, sens de la face) ; l'analyse est faite par
## tools/p7/coplanaires_p713.py (paires de triangles de même plan, même sens, à moins de 3 mm, recouvrement > 4 cm²).
##   godot --headless --path . --script res://tools/p7/coplanaires_p713.gd -- --sortie=<fichier.tsv> [options de la ville]
##   python3 tools/p7/coplanaires_p713.py <fichier.tsv>
var n := 0
var z
var sortie := "user://triangles_p713.tsv"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--sortie="):
			sortie = a.substr(9)
	change_scene_to_file("res://scenes/p7/ville_v07b.tscn")


func _process(_d: float) -> bool:
	n += 1
	if z == null:
		if n > 20 and current_scene != null and current_scene.get("world") != null:
			z = current_scene
			n = 0
		return false
	if n < 10:
		return false
	var f := FileAccess.open(sortie, FileAccess.WRITE)
	var nb := 0
	for mi in z.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or not m.is_visible_in_tree() or m.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			continue
		# nœuds cachés par défaut (chapeaux de coupe, parties hautes escamotables) : comptés s'ils sont visibles au repos
		var tr := m.global_transform
		var nom := str(z.get_path_to(m)).replace("\t", " ")
		for s in m.mesh.get_surface_count():
			var mat: Material = m.material_override if m.material_override != null else m.mesh.surface_get_material(s)
			var cull := 0
			if mat is BaseMaterial3D and (mat as BaseMaterial3D).cull_mode == BaseMaterial3D.CULL_DISABLED:
				cull = 1
			var arr := m.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx = arr[Mesh.ARRAY_INDEX]
			var tri := PackedInt32Array()
			if idx != null and (idx as PackedInt32Array).size() > 0:
				tri = idx
			else:
				for i in v.size():
					tri.append(i)
			var mid := mat.get_instance_id() if mat != null else 0
			var mnom := "?"
			if mat is ShaderMaterial and (mat as ShaderMaterial).shader != null:
				mnom = (mat as ShaderMaterial).shader.resource_path.get_file().get_basename()
				for p in ["couleur", "teinte", "c_joint"]:
					var vp = (mat as ShaderMaterial).get_shader_parameter(p)
					if vp is Color:
						mnom += "(%.2f,%.2f,%.2f)" % [vp.r, vp.g, vp.b]
						break
			elif mat is BaseMaterial3D:
				var c := (mat as BaseMaterial3D).albedo_color
				mnom = "plein(%.2f,%.2f,%.2f)" % [c.r, c.g, c.b]
			var nom2 := nom + "#" + mnom + "#" + str(m.get_parent().name)
			for i in range(0, tri.size() - 2, 3):
				var p0: Vector3 = tr * v[tri[i]]
				var p1: Vector3 = tr * v[tri[i + 1]]
				var p2: Vector3 = tr * v[tri[i + 2]]
				if (p1 - p0).cross(p2 - p0).length() < 2e-4:
					continue
				f.store_line("%s\t%d\t%d\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f" % [nom2, mid, cull,
					p0.x, p0.y, p0.z, p1.x, p1.y, p1.z, p2.x, p2.y, p2.z])
				nb += 1
	f.close()
	print("TRIANGLES ", nb, " -> ", sortie)
	quit()
	return false
