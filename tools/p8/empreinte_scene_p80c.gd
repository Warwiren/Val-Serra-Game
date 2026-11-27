extends SceneTree
## P8.0-C — Empreinte d'une scène chargée, pour vérifier qu'un nettoyage de code ne change RIEN à l'affichage ni aux
## collisions (outil de non-régression, lecture seule, sans rendu : --headless suffit).
## Relève, après `--images` images (220 par défaut) : chaque GeometryInstance3D (classe, visibilité effective, position,
## base, boîte englobante, maillage : surfaces / sommets / index, matière active de chaque surface : shader et paramètres,
## ombre portée, transparence), chaque lumière, chaque forme de collision, l'environnement et les attributs de caméra.
## Les noms de nœuds générés (@MeshInstance3D@123) sont ignorés : seul le contenu compte. Lignes triées, puis condensé MD5.
## godot --headless --path . --fixed-fps 60 --script res://tools/p8/empreinte_scene_p80c.gd -- \
##     --scene=res://scenes/p7/ville_v07b.tscn [--sortie=empreinte.txt] [--images=220] [options de la scène : --lumiere=b ...]
## Résultat : ligne « EMPREINTE {scene, lignes, md5, par_classe} » ; deux états identiques donnent le même md5.

var args := {}
var n := 0
var sc: Node


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			args[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
	change_scene_to_file(str(args.get("scene", "res://scenes/p7/ville_v07b.tscn")))


func _process(_d: float) -> bool:
	n += 1
	if n < int(args.get("images", "220")):
		return false
	sc = current_scene
	var lignes: Array[String] = []
	var par_classe := {}
	_parcourir(root, lignes, par_classe)
	var e := _env()
	if e != "":
		lignes.append(e)
	lignes.sort()
	var tout := "\n".join(lignes)
	if args.has("sortie"):
		var f := FileAccess.open(str(args["sortie"]), FileAccess.WRITE)
		f.store_string(tout + "\n")
	print("EMPREINTE ", JSON.stringify({"scene": args.get("scene", ""), "lignes": lignes.size(), "md5": tout.md5_text(),
		"par_classe": par_classe}))
	quit()
	return false


static func _v(v: Vector3) -> String:
	return "(%.3f,%.3f,%.3f)" % [v.x, v.y, v.z]


static func _val(x) -> String:
	if x is float:
		return "%.4f" % x
	if x is Vector3:
		return _v(x)
	if x is Color:
		return "c(%.4f,%.4f,%.4f,%.4f)" % [x.r, x.g, x.b, x.a]
	if x is Resource:
		return (x as Resource).resource_path if (x as Resource).resource_path != "" else (x as Resource).get_class()
	return str(x)


func _mat(m: Material) -> String:
	if m == null:
		return "-"
	if m is ShaderMaterial:
		var sm := m as ShaderMaterial
		var p := []
		if sm.shader != null:
			for u in sm.shader.get_shader_uniform_list():
				p.append("%s=%s" % [u["name"], _val(sm.get_shader_parameter(u["name"]))])
		return "S:%s{%s}" % [sm.shader.resource_path.get_file() if sm.shader != null else "?", ",".join(p)]
	if m is BaseMaterial3D:
		var b := m as BaseMaterial3D
		return "B:%s/%s/%s/%d/%d" % [_val(b.albedo_color), _val(b.albedo_texture), _val(b.emission), b.shading_mode, b.transparency]
	return m.get_class()


func _parcourir(nd: Node, lignes: Array[String], par_classe: Dictionary) -> void:
	if nd is GeometryInstance3D:
		var g := nd as GeometryInstance3D
		var t := g.global_transform
		var l := "G %s vis=%s pos=%s base=%s|%s|%s aabb=%s+%s ombre=%d tr=%.3f" % [g.get_class(), g.is_visible_in_tree(),
			_v(t.origin), _v(t.basis.x), _v(t.basis.y), _v(t.basis.z), _v(g.get_aabb().position), _v(g.get_aabb().size),
			g.cast_shadow, g.transparency]
		l += " ovr=" + _mat(g.material_override)
		if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			var mi := g as MeshInstance3D
			var me := mi.mesh
			for s in me.get_surface_count():
				var nv := 0
				var ni := 0
				if me is ArrayMesh:
					var arr := (me as ArrayMesh).surface_get_arrays(s)
					nv = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
					ni = (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() if arr[Mesh.ARRAY_INDEX] != null else 0
				l += " s%d[%s v%d i%d %s]" % [s, me.get_class(), nv, ni, _mat(mi.get_active_material(s))]
		elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null:
			var mm := (g as MultiMeshInstance3D).multimesh
			l += " multi=%d buf=%s maillage=%s" % [mm.instance_count, str(mm.buffer).md5_text(), _val(mm.mesh)]
			if mm.mesh != null:
				for s in mm.mesh.get_surface_count():
					l += " s%d[%s]" % [s, _mat(mm.mesh.surface_get_material(s))]
		elif g is SpriteBase3D:
			l += " sprite=" + _val((g as SpriteBase3D).get("texture")) + " px=%.4f" % (g as SpriteBase3D).pixel_size
		elif g is Label3D:
			l += " texte=" + (g as Label3D).text
		lignes.append(l)
		par_classe[g.get_class()] = int(par_classe.get(g.get_class(), 0)) + 1
	elif nd is Light3D:
		var li := nd as Light3D
		lignes.append("L %s vis=%s pos=%s dir=%s c=%s e=%.3f ombre=%s" % [li.get_class(), li.is_visible_in_tree(), _v(li.global_position),
			_v(-li.global_transform.basis.z), _val(li.light_color), li.light_energy, li.shadow_enabled])
		par_classe[li.get_class()] = int(par_classe.get(li.get_class(), 0)) + 1
	elif nd is CollisionShape3D:
		var cs := nd as CollisionShape3D
		var sh := cs.shape
		var d := ""
		if sh is BoxShape3D:
			d = _v((sh as BoxShape3D).size)
		elif sh is CylinderShape3D:
			d = "r%.3f h%.3f" % [(sh as CylinderShape3D).radius, (sh as CylinderShape3D).height]
		elif sh is CapsuleShape3D:
			d = "r%.3f h%.3f" % [(sh as CapsuleShape3D).radius, (sh as CapsuleShape3D).height]
		elif sh is SphereShape3D:
			d = "r%.3f" % (sh as SphereShape3D).radius
		elif sh != null:
			d = sh.get_class()
		var co := cs.get_parent() as CollisionObject3D
		lignes.append("C %s pos=%s dim=%s off=%s couche=%d" % [sh.get_class() if sh else "-", _v(cs.global_position), d, cs.disabled,
			co.collision_layer if co else -1])
		par_classe["CollisionShape3D"] = int(par_classe.get("CollisionShape3D", 0)) + 1
	for c in nd.get_children():
		_parcourir(c, lignes, par_classe)


func _env() -> String:
	var vp := root.get_viewport()
	var cam := vp.get_camera_3d()
	var we: WorldEnvironment = null
	for w in root.find_children("*", "WorldEnvironment", true, false):
		we = w
	if we == null or we.environment == null:
		return ""
	var e := we.environment
	var p := []
	for k in ["background_mode", "tonemap_mode", "tonemap_exposure", "tonemap_white", "ambient_light_source", "ambient_light_color",
			"ambient_light_energy", "ambient_light_sky_contribution", "ssao_enabled", "ssao_radius", "ssao_intensity",
			"ssao_light_affect", "glow_enabled", "glow_intensity", "adjustment_contrast", "adjustment_saturation", "fog_enabled"]:
		p.append("%s=%s" % [k, _val(e.get(k))])
	var ca := ""
	if cam != null and cam.attributes is CameraAttributesPractical:
		var a := cam.attributes as CameraAttributesPractical
		ca = "dof=%s/%.2f/%.2f/%.3f" % [a.dof_blur_far_enabled, a.dof_blur_far_distance, a.dof_blur_far_transition, a.dof_blur_amount]
	return "E %s msaa=%d deband=%s cam=%s fov=%.3f %s" % [" ".join(p), vp.msaa_3d, vp.use_debanding,
		_v(cam.global_position) if cam else "-", cam.fov if cam else 0.0, ca]
