extends "res://tools/p49/banc_v07.gd"
## P5.3-B — pilote des textures de sol peintes : présence et format des textures, import, zone pilote, touche Y,
## collisions et déplacement inchangés, décor de combat.
##   godot --headless --path . --fixed-fps 60 --script res://tests/p53b_pilote_smoke.gd

var failures := 0


func _test(ok: bool, label: String) -> void:
	if ok:
		print("P5.3-B OK : " + label)
	else:
		failures += 1
		push_error("P5.3-B ECHEC : " + label)


## valeur d'un paramètre de shader (null tant qu'il garde sa valeur par défaut du shader)
func _p(mat: ShaderMaterial, nom: String, defaut: Variant) -> Variant:
	var v = mat.get_shader_parameter(nom)
	return defaut if v == null else v


func _run() -> void:
	for n in ["herbe_drue", "herbe_usee", "terre_chemin"]:
		var t: Texture2D = load("res://art/p53/sol/%s.png" % n)
		var img := t.get_image() if t != null else null
		_test(img != null and img.get_width() == 1024 and img.get_height() == 1024 and img.has_mipmaps() and img.detect_alpha() != Image.ALPHA_NONE,
			"%s : 1024 × 1024, mipmaps, canal A (hauteur)" % n)
		var imp := FileAccess.get_file_as_string("res://art/p53/sol/%s.png.import" % n)
		_test(imp.contains("compress/mode=0") and imp.contains("process/fix_alpha_border=false") and imp.contains("process/premult_alpha=false"),
			"%s : import sans perte, alpha non retouché" % n)
	load("res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.gd").set("demarrage_v09c6", true)
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	var sol = sc.get("_sol")
	var mat: ShaderMaterial = sol.get("materiau_p53b")
	var terrain: MeshInstance3D = sc.get("_terrain_mi")
	var mat2: ShaderMaterial = sol.get("materiau_p53b2")
	var mat1c: ShaderMaterial = sol.get("materiau_p53b1c")
	var mat2t: ShaderMaterial = sol.get("materiau_p53b2t")
	var mat3h: ShaderMaterial = sol.get("materiau_p53b3h")
	_test(mat3h != null and terrain.material_override == mat3h and String(sc.get("version_sol")) == "p53b3h", "F5 : pilote P5.3-B V3 hybride (proposition)")
	_test(float(_p(mat3h, "hybride", 0.0)) == 1.0 and float(_p(mat3h, "calage", 0.0)) == 0.0 and (mat3h.get_shader_parameter("tex_drue") as Texture2D).resource_path.contains("sol_v2")
		and (mat3h.get_shader_parameter("tex_v1_usee") as Texture2D).resource_path.ends_with("art/p53/sol/herbe_usee.png"),
		"V3 hybride : matières V2, forme de l'herbe usée V1 (masque), aucun calage")
	_test(float(_p(mat2t, "hybride", 0.0)) == 0.0, "V2 transitions conservée telle quelle")
	_test(float(_p(mat2t, "transition", 0.0)) == 1.0 and float(_p(mat2t, "calage", 0.0)) == 0.0 and (mat2t.get_shader_parameter("tex_terre") as Texture2D).resource_path.contains("sol_v2"),
		"V2 transitions : textures V2 originales, bande intermédiaire active, aucun calage")
	_test(float(_p(mat2, "transition", 0.0)) == 0.0, "V2 actuelle conservée telle quelle (sans bande intermédiaire)")
	_test(float(_p(mat2, "calage", 0.0)) == 0.0 and (mat2.get_shader_parameter("tex_drue") as Texture2D).resource_path.contains("sol_v2"), "V2 : textures V2, aucun second calage")
	_test(mat1c != null and float(_p(mat1c, "calage", 0.0)) == 1.0, "V1 + calage conservée (référence)")
	var ordre := []
	for i in 8:
		ordre.append(String(sc.get("version_sol")))
		sc.call("set_version_sol", (sc.get("SOLS") as Array)[((sc.get("SOLS") as Array).find(sc.get("version_sol")) + 1) % 8])
	_test(ordre == ["p53b3h", "p53b2t", "p53b2", "p53b1c", "p53b", "p53", "p52", "v07"] and String(sc.get("version_sol")) == "p53b3h", "touche U : V3 hybride → V2 transitions → V2 → V1 calée → V1 → P5.3 → P5.2 → V07 (%s)" % [ordre])
	for n in ["herbe_drue", "herbe_usee", "terre_chemin"]:
		var t2: Texture2D = load("res://art/p53/sol_v2/%s.png" % n)
		_test(t2 != null and t2.get_image().get_width() == 1024 and t2.get_image().has_mipmaps(), "V2 %s : 1024 × 1024, mipmaps" % n)
	_test(mat.get_shader_parameter("tex_drue") != null and mat.get_shader_parameter("tex_usee") != null and mat.get_shader_parameter("tex_terre") != null, "trois matières peintes branchées")
	var zone: Vector3 = _p(mat, "zone_pilote", Vector3(-10, 1, 8))
	_test(not _p(mat, "carte_entiere", false) and zone.z <= 10.0, "zone pilote limitée (rayon %.0f m)" % zone.z)
	_test(float(_p(mat, "calage", 0.0)) == 0.0, "couleurs peintes telles quelles (calage d'essai coupé)")
	var ey := InputEventKey.new()
	ey.keycode = KEY_Y
	ey.physical_keycode = KEY_Y
	ey.pressed = true
	sc.call("_unhandled_key_input", ey)
	_test(_p(mat, "carte_entiere", false) == true and _p(mat2, "carte_entiere", false) == true and _p(mat2t, "carte_entiere", false) == true and _p(mat3h, "carte_entiere", false) == true, "touche Y : matières peintes sur toute la carte (toutes variantes)")
	sc.call("_unhandled_key_input", ey)
	_test(_p(mat, "carte_entiere", false) == false, "touche Y : retour à la zone pilote")
	var col: CollisionShape3D = terrain.get_child(0).get_child(0)
	_test((col.shape as ConcavePolygonShape3D).get_faces().size() == 90240 * 3 and (sc.get("_set_colliders") as Array).size() == 97, "collisions inchangées")
	_place(-13.5, 0.3)
	await _frames(10)
	var x0 := _hero().global_position.x
	_steer(Vector3(1, 0, 0))
	await _frames(90)
	_stop()
	_test(_hero().global_position.x - x0 > 2.5, "déplacement inchangé dans la zone pilote (%.2f m en 1,5 s)" % (_hero().global_position.x - x0))
	print("P5.3-B : %d échec(s)" % failures)
	quit(1 if failures > 0 else 0)
