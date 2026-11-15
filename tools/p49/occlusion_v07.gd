extends SceneTree
## P4.9 — vérification de l'occlusion dynamique et des trois inclinaisons dans la scène V07B (F6).
##   godot --headless --path . --fixed-fps 60 --script res://tools/p49/occlusion_v07.gd -- --out=<dossier>   (scénarios)
##   godot --path . --script res://tools/p49/occlusion_v07.gd -- --out=<dossier> --captures               (captures comparatives)
##   godot --path . --write-movie v.avi --fixed-fps 30 --script res://tools/p49/occlusion_v07.gd -- --film (vidéo)
## Les scénarios vérifient le FONCTIONNEMENT (détection, transitions, restauration). Ils ne jugent pas l'image.

const SCENE := "res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.tscn"
const MANIFEST := "res://ValSerra_P49_V07B_PREFLIGHT_GODOT/docs/V07_WORLD.json"
var sc: Node
var occ: RefCounted
var out := "user://p49_occlusion"
var mode := "tests"
var data: Dictionary
var res := {"scenarios": [], "captures": [], "perf": {}}
var pin := {}                                # "aren"/"ilya" -> Vector3 imposée à chaque image physique


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a == "--captures":
			mode = "captures"
		elif a == "--film":
			mode = "film"
	DirAccess.make_dir_recursive_absolute(out)
	data = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	physics_frame.connect(_pin)
	_run.call_deferred()


func _pin() -> void:
	if sc == null:
		return
	for k in pin:
		var b: CharacterBody3D = sc.get("_hero" if k == "aren" else "_ilya")
		b.global_position = pin[k]
		b.velocity = Vector3.ZERO


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _key(k: Key) -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = down
		Input.parse_input_event(e)
		await process_frame


func _ground(x: float, z: float) -> float:
	var space := (sc as Node3D).get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 30, z), Vector3(x, -10, z), 1)
	var hit := space.intersect_ray(q)
	return float(hit["position"].y) if not hit.is_empty() else 0.0


func _p(x: float, z: float) -> Vector3:
	return Vector3(x, _ground(x, z) + 0.02, z)


func _set_pos(aren, ilya) -> void:
	pin.clear()
	if aren != null:
		pin["aren"] = aren
	if ilya != null:
		pin["ilya"] = ilya
	_pin()
	sc.call("_update_camera", 1.0)


## direction « derrière » vue de la caméra P30 (azimut 20°), sur le sol
func _behind() -> Vector3:
	return Vector3(sin(deg_to_rad(20.0)), 0, -cos(deg_to_rad(20.0)))


func _trees() -> Array:
	var t: Array = data["placements"].filter(func(p): return p["role"] == "tree" and float(p["scale"]) >= 0.6)
	t.sort_custom(func(a, b): return Vector2(float(a["xyz"][0]), float(a["xyz"][2])).length() < Vector2(float(b["xyz"][0]), float(b["xyz"][2])).length())
	return t


## états internes de l'occlusion, pour les vérifications
func _obs() -> Array:
	return occ.get("_obstacles")


func _actifs() -> Array:
	var outa: Array = []
	for o in _obs():
		if o["actif"]:
			outa.append(o)
	return outa


func _arbre_attenue(c: Vector3) -> bool:
	for o in _actifs():
		if o.has("node"):
			var g := (o["node"] as Node3D).global_position
			if Vector2(g.x, g.z).distance_to(Vector2(c.x, c.z)) < 0.2:
				return true
	return false


func _nom(o: Dictionary) -> String:
	return String((o["node"] as Node).name) if o.has("node") else "%s[%d]" % [(o["mmi"] as Node).name, o["index"]]


func _ghost_a(i: int) -> float:
	return float(occ.get("_persos")[i]["a"])


func _scenario(id: String, ok: bool, detail: Dictionary) -> void:
	detail["id"] = id
	detail["ok"] = ok
	res["scenarios"].append(detail)
	print("%s  %s  %s" % ["OK " if ok else "ÉCHEC", id, JSON.stringify(detail)])


func _attendre_repos() -> void:
	_set_pos(_p(-2.0, 0.5), _p(-3.2, 0.9))           # clairière dégagée
	await _frames(40)


# ---------------------------------------------------------------------------------------------------------------
func _run() -> void:
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	occ = sc.get("_occ")
	res["rendu"] = RenderingServer.get_current_rendering_method()
	if mode == "tests":
		await _tests()
	elif mode == "captures":
		await _captures()
	else:
		await _film()
	var f := FileAccess.open(out.path_join("occlusion_%s.json" % mode), FileAccess.WRITE)
	f.store_string(JSON.stringify(res, " "))
	pin.clear()
	quit()


## cherche, pour l'inclinaison courante, un arbre derrière lequel un personnage est réellement caché
func _cachette(exclude: Array = []) -> Dictionary:
	for t in _trees():
		var c := Vector3(float(t["xyz"][0]), 0, float(t["xyz"][2]))
		if c in exclude:
			continue
		for d in [3.0, 4.0, 5.0, 2.2]:            # le feuillage cache ~2,3 à 10 m derrière l'arbre (le tronc, en deçà)
			var p: Vector3 = c + _behind() * d
			if absf(p.x) > 16.5 or absf(p.z) > 12.5:
				continue
			_set_pos(_p(p.x, p.z), _p(-2.0, 0.5))
			await _frames(16)
			for o in _actifs():
				if o.has("node") and (o["node"] as Node3D).global_position.distance_to(Vector3(c.x, (o["node"] as Node3D).global_position.y, c.z)) < 0.2:
					return {"arbre": t["name"], "centre": c, "pos": p, "d": d}
	return {}


func _tests() -> void:
	var n_coll0 := _collision_signature()
	var mm0 := _multimesh_signature()
	var sh0 := _shadow_signature()
	# 0. aucune transparence au repos (personnages dans une clairière dégagée)
	await _attendre_repos()
	_scenario("repos : aucune transparence globale", _actifs().size() == 0, {"attenues": _actifs().size()})
	# 1. Aren seul derrière un arbre
	var h1 := await _cachette()
	var actifs1 := _actifs().map(_nom)
	await _frames(20)
	var op_min := 1.0
	for o in _actifs():
		op_min = minf(op_min, o["op"])
	_scenario("Aren seul derrière un arbre", not h1.is_empty() and actifs1.size() <= 3 and absf(op_min - 0.4) < 0.02,
		{"arbre": h1.get("arbre", ""), "position": str(h1.get("pos", "")), "attenues": actifs1, "opacite": snappedf(op_min, 0.01)})
	# 2. Ilya masquée, Aren visible
	await _attendre_repos()
	if not h1.is_empty():
		_set_pos(_p(-2.0, 0.5), _p(h1["pos"].x, h1["pos"].z))
		await _frames(30)
		_scenario("Ilya masquée, Aren visible", _actifs().size() >= 1, {"attenues": _actifs().map(_nom)})
	# 3. les deux derrière des obstacles différents
	await _attendre_repos()
	var h2 := {}
	if not h1.is_empty():
		h2 = await _cachette([h1["centre"]])
		if not h2.is_empty():
			_set_pos(_p(h1["pos"].x, h1["pos"].z), _p(h2["pos"].x, h2["pos"].z))
			await _frames(30)
			var noms := _actifs().map(_nom)
			_scenario("deux personnages derrière deux arbres", _arbre_attenue(h1["centre"]) and _arbre_attenue(h2["centre"]),
				{"arbres": [h1["arbre"], h2["arbre"]], "attenues": noms})
	# 4. changements rapides de direction au bord de l'arbre : pas de clignotement
	if not h1.is_empty():
		await _attendre_repos()
		var right := Vector3(cos(deg_to_rad(20.0)), 0, sin(deg_to_rad(20.0)))
		var base: Vector3 = h1["pos"]
		var bascules := 0
		var etat_prec := -1
		for i in 120:                                   # 2 s : le héros oscille de ±0,45 m toutes les 0,13 s
			var off := right * (0.45 if (i / 8) % 2 == 0 else -0.45)
			_set_pos(_p(base.x + off.x, base.z + off.z), _p(-2.0, 0.5))
			await _frames(1)
			var e := 1 if _actifs().size() > 0 else 0
			if etat_prec != -1 and e != etat_prec:
				bascules += 1
			etat_prec = e
		_scenario("changements rapides de direction : pas de clignotement", bascules <= 2, {"bascules_en_2s": bascules})
	# 5. passage derrière plusieurs arbres successifs (marche réelle derrière une rangée)
	await _attendre_repos()
	var vus := {}
	var max_simult := 0
	var trees := _trees().filter(func(t): return absf(float(t["xyz"][2]) - 4.9) < 2.0 or absf(float(t["xyz"][2]) + 4.9) < 2.0)
	var x := -15.0
	while x < 15.0:
		var z := 4.9 + _behind().z * 1.8
		_set_pos(_p(x + _behind().x * 1.8, z), _p(-2.0, -6.0))
		await _frames(2)
		for o in _actifs():
			vus[_nom(o)] = true
		max_simult = maxi(max_simult, _actifs().size())
		x += 0.12
	await _attendre_repos()
	_scenario("plusieurs arbres successifs, tous restaurés après", vus.size() >= 2 and _actifs().size() == 0,
		{"obstacles_atténués_en_chemin": vus.keys(), "max_simultanés": max_simult, "restants_après": _actifs().size()})
	# 6. changement d'angle avec l'occlusion active ; 7. trois zooms
	if not h1.is_empty():
		var par_angle := {}
		for k in [KEY_4, KEY_5, KEY_6]:
			await _key(k)
			_set_pos(_p(h1["pos"].x, h1["pos"].z), _p(-2.0, 0.5))
			await _frames(25)
			par_angle[str(sc.get("_pitch"))] = _actifs().map(_nom)
		_scenario("changement d'angle avec occlusion active", par_angle.values().all(func(v): return v.size() >= 1), par_angle)
		await _key(KEY_4)
		var par_zoom := {}
		for k in [KEY_1, KEY_2, KEY_3]:
			await _key(k)
			_set_pos(_p(h1["pos"].x, h1["pos"].z), _p(-2.0, 0.5))
			await _frames(25)
			par_zoom[str(sc.get("_zoom"))] = _actifs().map(_nom)
		await _key(KEY_2)
		_scenario("trois zooms", par_zoom.values().all(func(v): return v.size() >= 1), par_zoom)
		# 8. O : coupe et rétablit, sans rien laisser derrière
		await _key(KEY_O)
		await _frames(5)
		var coupe_ok: bool = _actifs().size() == 0 and _copies() == 0 and _ghost_a(0) == 0.0
		await _key(KEY_O)
		await _frames(25)
		_scenario("touche O : coupe puis rétablit", coupe_ok and _actifs().size() >= 1, {"apres_coupure_copies": 0 if coupe_ok else _copies(), "apres_retablissement": _actifs().map(_nom)})
	# 9. trop proche mais pas gênant : héros DEVANT un arbre (entre la caméra et l'arbre)
	# l'arbre de la cachette, le héros à 3 m DEVANT (côté caméra), puis à 1,2 m sur le côté, à hauteur du tronc
	if not h1.is_empty():
		var c0: Vector3 = h1["centre"]
		var right0 := Vector3(cos(deg_to_rad(20.0)), 0, sin(deg_to_rad(20.0)))
		var res9 := {}
		for v in [["3 m devant", c0 - _behind() * 3.0], ["1,8 m à côté", c0 + right0 * 1.8]]:
			await _attendre_repos()
			_set_pos(_p(v[1].x, v[1].z), _p(-2.0, 0.5))
			await _frames(40)
			res9[v[0]] = _arbre_attenue(c0)
		_scenario("proche mais pas gênant : l'arbre n'est pas atténué", not res9.values().has(true), {"arbre": h1["arbre"], "atténué": res9})
	# 10. silhouette derrière un rocher (massif : pas de transparence)
	var rocks: Array = data["placements"].filter(func(p): return p["role"] == "rock" and float(p["scale"]) >= 0.9)
	var sil_ok := false
	var sil_detail := {}
	for r in rocks:
		var c := Vector3(float(r["xyz"][0]), 0, float(r["xyz"][2]))
		var p: Vector3 = c + _behind() * (1.2 + float(r["scale"]) * 0.6)
		_set_pos(_p(p.x, p.z), _p(-2.0, 0.5))
		await _frames(25)
		if _ghost_a(0) > 0.35:
			var faded_rock := _actifs().filter(func(o): return o.has("node") and String((o["node"] as Node).name).begins_with(String(r["name"]))).size()
			sil_ok = faded_rock == 0
			sil_detail = {"rocher": r["name"], "silhouette_alpha": snappedf(_ghost_a(0), 0.01), "rocher_atténué": faded_rock > 0}
			break
	_scenario("rocher : silhouette du personnage, rocher non transparent", sil_ok, sil_detail)
	# 11. restauration complète : matériaux, ombres, multimesh, collisions
	await _attendre_repos()
	await _frames(30)
	_scenario("restauration : aucune copie, ombres, MultiMesh et collisions intacts",
		_copies() == 0 and _multimesh_signature() == mm0 and _shadow_signature() == sh0 and _collision_signature() == n_coll0,
		{"copies": _copies(), "multimesh_identique": _multimesh_signature() == mm0, "ombres_identiques": _shadow_signature() == sh0, "collisions_identiques": _collision_signature() == n_coll0})
	# 12. coût CPU de la détection (sans GPU, indicatif)
	if not h1.is_empty():
		_set_pos(_p(h1["pos"].x, h1["pos"].z), _p(-2.0, 0.5))
		await _frames(10)
		var t := Time.get_ticks_usec()
		for i in 60:
			occ.update(1.0 / 60.0)
		res["perf"]["detection_ms_par_image"] = snappedf((Time.get_ticks_usec() - t) / 60000.0, 0.01)
		res["perf"]["obstacles_suivis"] = occ.nombre_obstacles()


func _copies() -> int:
	return (occ.get("_calque") as Node).get_child_count()


func _multimesh_signature() -> int:
	var h := 0
	for o in _obs():
		if o.has("mmi"):
			h = hash([h, str((o["mmi"] as MultiMeshInstance3D).multimesh.get_instance_transform(o["index"]))])
	return h


func _shadow_signature() -> int:
	var h := 0
	for o in _obs():
		if o.has("node"):
			for m in o["parts"]:
				h = hash([h, (m as GeometryInstance3D).cast_shadow, (m as Node3D).visible])
	return h


func _collision_signature() -> int:
	var h := 0
	var stack: Array = [sc]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is CollisionObject3D:
			h = hash([h, n.name, (n as CollisionObject3D).collision_layer, (n as CollisionObject3D).collision_mask])
	return h


# --------------------------------------------------------------------------------------------- captures
func _snap(id: String) -> void:
	await _frames(3)
	var p := out.path_join("%s_%s.png" % [id, res["rendu"]])
	root.get_texture().get_image().save_png(p)
	res["captures"].append(p)


func _captures() -> void:
	await _key(KEY_2)
	# position de comparaison : un grand arbre masque Aren à 30° (même position pour les 3 angles)
	await _key(KEY_4)
	var h1 := await _cachette()
	res["position_comparaison"] = {"arbre": h1.get("arbre", ""), "aren": str(h1.get("pos", "")), "ilya": str(h1.get("pos", Vector3()) + Vector3(-1.4, 0, 0.5))}
	var ap: Vector3 = h1["pos"]
	var ip: Vector3 = ap + Vector3(-1.4, 0, 0.5)
	for k in [[KEY_4, "30"], [KEY_5, "27"], [KEY_6, "24"]]:
		await _key(k[0])
		for etat in [false, true]:
			if bool(occ.get("enabled")) != etat:
				await _key(KEY_O)
			_set_pos(_p(ap.x, ap.z), _p(ip.x, ip.z))
			await _frames(30)
			await _snap("arbre_%s_%s" % [k[1], "avec_occlusion" if etat else "sans_occlusion"])
	# chemin principal et ruisseau, aux trois angles (occlusion active)
	for v in [["chemin", -9.2, -0.95], ["ruisseau", 3.0, -9.0]]:
		for k in [[KEY_4, "30"], [KEY_5, "27"], [KEY_6, "24"]]:
			await _key(k[0])
			_set_pos(_p(v[1], v[2]), _p(v[1] - 1.2, v[2] + 0.4))
			await _frames(30)
			await _snap("%s_%s" % [v[0], k[1]])
	await _key(KEY_4)


# --------------------------------------------------------------------------------------------- film
func _film() -> void:
	# marche réelle derrière une rangée d'arbres, angle 30 puis 27 puis 24 ; O coupé puis rétabli
	await _key(KEY_2)
	await _key(KEY_4)
	pin.clear()
	var hero: CharacterBody3D = sc.get("_hero")
	hero.global_position = _p(-15.0, 4.9 + _behind().z * 1.8)
	sc.call("_update_camera", 1.0)
	await _frames(20)
	for seg in [[KEY_4, 1.0, 110], [KEY_5, -1.0, 110], [KEY_6, 1.0, 110]]:
		await _key(seg[0])
		Input.action_press("ui_right" if seg[1] > 0 else "ui_left")
		await _frames(seg[2])
		Input.action_release("ui_right")
		Input.action_release("ui_left")
		await _frames(15)
	# O : coupé puis rétabli, à l'arrêt derrière un arbre
	var h1 := await _cachette()
	pin.clear()
	await _frames(30)
	await _key(KEY_O)
	await _frames(35)
	await _key(KEY_O)
	await _frames(35)
	# demi-tours rapides au bord de l'arbre
	for i in 6:
		Input.action_press("ui_right" if i % 2 == 0 else "ui_left")
		await _frames(10)
		Input.action_release("ui_right")
		Input.action_release("ui_left")
	await _frames(30)
