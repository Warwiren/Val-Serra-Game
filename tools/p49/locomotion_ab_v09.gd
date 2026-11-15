extends "res://tools/p49/banc_v07.gd"
## V09A — comparaison mesurée V08 / V09A dans la vraie scène F5, mêmes commandes dans les deux modes (touche L).
##   godot --headless --path . --fixed-fps 60 --script res://tools/p49/locomotion_ab_v09.gd -- --out=<dossier>
##   godot --path . --write-movie v.avi --fixed-fps 30 --script res://tools/p49/locomotion_ab_v09.gd -- --film=V08|V09A
## Les commandes sont « numériques » comme au clavier (directions entières), sauf le contournement d'objets où le
## joueur vise des points successifs.

var film_mode := ""


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--film="):
			film_mode = a.substr(7)
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	if film_mode != "":
		await _mode(film_mode == "V09A")
		await _sequence_film()
		quit()
		return
	res = {}
	for m in ["V08", "V09A"]:
		await _mode(m == "V09A")
		res[m] = await _scenarios()
	var f := FileAccess.open(out.path_join("locomotion_ab_v09.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(res, " "))
	_resume()
	quit()


func _mode(v09: bool) -> void:
	if bool(sc.get("_v09_enabled")) != v09:
		await _tap(KEY_L)


func _ilya() -> CharacterBody3D:
	return sc.get("_ilya")


func _hv() -> Vector2:
	var v := _hero().velocity
	return Vector2(v.x, v.z)


# ---------------------------------------------------------------------------------------------------- scénarios
func _scenarios() -> Dictionary:
	var r := {}
	r["marche"] = await _demarrage_arret(false)
	r["course"] = await _demarrage_arret(true)
	r["demi_tour_marche"] = await _demi_tour(false)
	r["demi_tour_course"] = await _demi_tour(true)
	r["virage_90"] = await _parcours("virage à 90°", Vector2(-12.0, -0.5), [[Vector3(1, 0, 0), 120], [Vector3(0, 0, 1), 120]], [])
	# tronc : CommonTree_4 (-2,7 ; 4,2) — Aren passe au sud du tronc puis tourne vers le nord sur son flanc est
	r["autour_tronc"] = await _parcours("autour d'un tronc", Vector2(-5.2, 5.4), [], [Vector2(-2.7, 5.25), Vector2(-1.55, 4.2), Vector2(-1.6, 2.6)])
	# rocher : Rock_Medium_1 (10,3 ; 10,8) — courbe par son flanc nord puis arrêt
	r["courbe_rocher"] = await _parcours("courbe autour d'un rocher", Vector2(7.2, 9.0), [], [Vector2(9.0, 8.4), Vector2(11.5, 8.5), Vector2(12.6, 9.6)])
	return r


func _demarrage_arret(run: bool) -> Dictionary:
	_place(-12.0, -0.5)
	await _frames(30)
	var cible := 3.6 if run else 2.2
	_key(KEY_SHIFT, run)
	_steer(Vector3(1, 0, 0))
	var t95 := -1.0
	var v1 := 0.0
	for i in 150:
		await _frames(1)
		var v := _hv().length()
		if i == 0:
			v1 = v
		if t95 < 0.0 and v >= cible * 0.95:
			t95 = (i + 1) / 60.0
	var x0 := _hero().global_position.x
	_stop()
	_key(KEY_SHIFT, false)
	var t_arret := -1.0
	for i in 90:
		await _frames(1)
		if t_arret < 0.0 and _hv().length() < 0.05:
			t_arret = (i + 1) / 60.0
	return {"vitesse_1re_image_m_s": snappedf(v1, 0.01), "temps_95pc_s": snappedf(t95, 0.001),
		"distance_arret_m": snappedf(_hero().global_position.x - x0, 0.001), "temps_arret_s": snappedf(t_arret, 0.001),
		"vitesse_croisiere_m_s": snappedf(cible, 0.01)}


func _demi_tour(run: bool) -> Dictionary:
	_place(-9.0, -0.5)
	await _frames(30)
	var cible := 3.6 if run else 2.2
	_key(KEY_SHIFT, run)
	_steer(Vector3(1, 0, 0))
	await _frames(90)
	var x_avant := _hero().global_position.x
	_steer(Vector3(-1, 0, 0))
	var t_retour := -1.0
	var x_max := x_avant
	for i in 120:
		await _frames(1)
		x_max = maxf(x_max, _hero().global_position.x)
		if t_retour < 0.0 and _hv().x <= -cible * 0.95:
			t_retour = (i + 1) / 60.0
	_stop()
	_key(KEY_SHIFT, false)
	await _frames(30)
	return {"temps_retour_pleine_vitesse_s": snappedf(t_retour, 0.001), "depassement_m": snappedf(x_max - x_avant, 0.001)}


## commandes : soit des segments [direction, images], soit des points à viser ; puis arrêt et observation 3 s
func _parcours(nom: String, depart: Vector2, segments: Array, points: Array) -> Dictionary:
	_place(depart.x, depart.y)
	_ilya().global_position = _hero().global_position + Vector3(-1.2, 0, 0)
	if bool(sc.get("_v09_enabled")):
		(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, _ilya().global_position)
	await _frames(30)
	var trace: Array = []
	var ecarts: Array = []
	var st := {"dmax": 0.0, "dmin": 99.0, "bloquee": 0, "parcouru": 0.0, "prec": _ilya().global_position}
	var contacts_ilya := {}
	var frames_suivi := func() -> void:
		var h := _hero().global_position
		var il := _ilya().global_position
		trace.append(Vector2(h.x, h.z))
		st["parcouru"] += Vector2(il.x - st["prec"].x, il.z - st["prec"].z).length()
		st["prec"] = il
		var d := Vector2(h.x - il.x, h.z - il.z).length()
		st["dmax"] = maxf(st["dmax"], d)
		st["dmin"] = minf(st["dmin"], d)
		if st["parcouru"] > 1.3:                       # Ilya est entrée sur la trace d'Aren
			var best := 99.0
			for p in trace:
				best = minf(best, (p as Vector2).distance_to(Vector2(il.x, il.z)))
			ecarts.append(best)
		var v := _ilya().get_real_velocity()
		if d > 1.8 and Vector2(v.x, v.z).length() < 0.15:
			st["bloquee"] += 1
		for k in _ilya().get_slide_collision_count():
			var n := _nature(_ilya().get_slide_collision(k).get_collider() as Node)
			if not n.begins_with("Terrain"):
				contacts_ilya[n] = contacts_ilya.get(n, 0) + 1
	for s in segments:
		_steer(s[0])
		for i in s[1]:
			await _frames(1)
			frames_suivi.call()
	for p in points:
		for i in 240:
			var h := _hero().global_position
			var to := Vector3(p.x - h.x, 0, p.y - h.z)
			if to.length() < 0.25:
				break
			_steer(to.normalized())
			await _frames(1)
			frames_suivi.call()
	_stop()
	# arrêt : Ilya se pose-t-elle sans trembler ?
	var bascules := 0
	var anim_prec := ""
	var a_il: RefCounted = sc.get("_ilya_anim")
	var t_pose := -1.0
	for i in 180:
		await _frames(1)
		frames_suivi.call()
		var anim: String = a_il.get("anim")
		if i > 0 and anim.substr(0, 4) != anim_prec.substr(0, 4):
			bascules += 1
		anim_prec = anim
		var v := _ilya().get_real_velocity()
		if t_pose < 0.0 and Vector2(v.x, v.z).length() < 0.05:
			t_pose = (i + 1) / 60.0
	ecarts.sort()
	if ecarts.is_empty():
		ecarts = [0.0]
	var h2 := _hero().global_position
	var il2 := _ilya().global_position
	return {"nom": nom, "ilya_ecart_a_la_trace_max_m": snappedf(ecarts[-1], 0.01), "ilya_ecart_a_la_trace_p90_m": snappedf(ecarts[int(ecarts.size() * 0.9)], 0.01),
		"distance_aren_ilya_min_m": snappedf(st["dmin"], 0.01), "distance_aren_ilya_max_m": snappedf(st["dmax"], 0.01),
		"ilya_immobile_a_distance_images": st["bloquee"], "ilya_contacts_decor": contacts_ilya,
		"ilya_bascules_marche_attente_apres_arret": bascules, "ilya_posee_apres_s": snappedf(t_pose, 0.01),
		"distance_finale_m": snappedf(Vector2(h2.x - il2.x, h2.z - il2.z).length(), 0.01)}


## nature d'un collider (Godot renomme les nœuds homonymes : on lit la forme)
func _nature(n: Node) -> String:
	var nm := String(n.name)
	if nm.begins_with("Terrain"):
		return "Terrain"
	var cs := n.get_child(0) as CollisionShape3D if n.get_child_count() > 0 else null
	var p := (n as Node3D).global_position
	if cs != null and cs.shape is CylinderShape3D:
		return "tronc (%.1f, %.1f)" % [p.x, p.z]
	if cs != null and cs.shape is ConvexPolygonShape3D:
		return "rocher (%.1f, %.1f)" % [p.x, p.z]
	if cs != null and cs.shape is BoxShape3D:
		return "barrière (%.1f, %.1f)" % [p.x, p.z]
	return nm


func _resume() -> void:
	for m in res:
		print("=== ", m)
		for k in res[m]:
			print("  %-18s %s" % [k, JSON.stringify(res[m][k])])


# ---------------------------------------------------------------------------------------------------- film
## même séquence pour V08 et V09A (montées côte à côte ensuite) : démarrage, arrêt, demi-tour, virage, course
func _sequence_film() -> void:
	await _tap(KEY_2)
	_place(-12.0, 1.6)
	_ilya().global_position = _hero().global_position + Vector3(-1.2, 0, 0)
	if bool(sc.get("_v09_enabled")):
		(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, _ilya().global_position)
	await _frames(40)
	for seg in [[Vector3(1, 0, 0), 70, false], [Vector3.ZERO, 40, false], [Vector3(-1, 0, 0), 40, false], [Vector3(1, 0, 0), 60, false],
			[Vector3(0, 0, 1), 60, false], [Vector3(1, 0, 0), 50, true], [Vector3(0, 0, -1), 40, true], [Vector3(-1, 0, 0), 30, true],
			[Vector3.ZERO, 70, false]]:
		_key(KEY_SHIFT, seg[2])
		if seg[0] == Vector3.ZERO:
			_stop()
		else:
			_steer(seg[0])
		await _frames(seg[1])
	_key(KEY_SHIFT, false)
	_stop()
	await _frames(20)
