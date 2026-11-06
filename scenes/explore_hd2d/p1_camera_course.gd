extends Node
## P1 — PARCOURS DE COMPARAISON DES CAMÉRAS (zone de test agrandie). Pour chaque configuration (A, B, C), le
## MÊME parcours au clavier simulé (vraies touches, comme locomotion_course.gd) : 8 directions, prairie ouverte,
## hameau et passage derrière la 2e maison, couloir étroit entre deux clôtures, bosquet (derrière les arbres),
## limites de la carte (eau, lisière droite, angle haut), puis dialogue avec le garde (E / Échap).
## Mesures image par image : vitesse et à-coups de la caméra, mouvements à l'arrêt, inversions de sens, position
## du héros à l'écran, collisions (positions interdites), écart du groupe, temps d'image, mémoire.
##   godot --fixed-fps 60 --path . -- --start=p1-zone --course=p1 [--cam=B] [--course-out=f.json] [--course-shots=dossier]
## Sans --cam : les trois configurations à la suite (changement EN JEU, sans rechargement).

var zone
var out_path := ""
var shots_dir := ""
var only := ""
var events: Array = []
var results := {}
var _held := {}
var _hud: Label
var _rec: Dictionary = {}
var _prev_c := Vector2.INF
var _prev_v := Vector2.ZERO
var _prev_hero := Vector2.ZERO
var _t := 0.0
var _label := ""
var _skip := 0
var _stop_t := -1.0
var _was_moving := false                  # temps écoulé depuis l'arrêt du groupe, tant que la caméra bouge encore
var short := false                   # --course-short : version courte pour la vidéo (mêmes passages clés)                       # images ignorées juste après une téléportation (changement de configuration)

const K_R := KEY_RIGHT
const K_L := KEY_LEFT
const K_U := KEY_UP
const K_D := KEY_DOWN


func _init(z) -> void:
	zone = z
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--course-out="):
			out_path = a.substr(13)
		elif a.begins_with("--course-shots="):
			shots_dir = a.substr(15)
		elif a == "--course-short":
			short = true
		elif a.begins_with("--cam="):
			only = a.substr(6).to_upper()


func _ready() -> void:
	process_priority = 1000
	if DisplayServer.get_name() == "headless":
		get_tree().root.size = Vector2i(1280, 720)       # sans écran, la fenêtre virtuelle est carrée : mesures fausses
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(16, 12)
	_hud.add_theme_font_size_override("font_size", 17)
	_hud.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
	_hud.add_theme_constant_override("outline_size", 6)
	layer.add_child(_hud)
	_run.call_deferred()


func _run() -> void:
	if not is_inside_tree():
		return                                         # zone remplacée par --start=p1-zone avant le départ
	await get_tree().create_timer(0.5).timeout
	var list := [only] if only != "" else ["A", "B", "C"]
	for p in list:
		await _course(p)
	_finish()


func _reset(p: String) -> void:
	var sp: Array = zone.zone["spawn"]["heros"]
	zone.hero.position = Vector2(sp[0], sp[1])
	zone._place_party()
	GameState.camera_preset = p
	zone.cam.apply(p)                                  # sans transition d'échelle : chaque mesure part du même état
	zone.cam.snap_to(zone.hero.position)


## Le parcours (coordonnées natives de la zone P1 ; l'avant-poste d'origine est translaté de (0, 400)).
func _course(p: String) -> void:
	_reset(p)
	_rec = {"frames": 0, "moving_frames": 0, "cam_speed_max": 0.0, "cam_acc_spikes": 0, "cam_acc_max": 0.0,
		"idle_cam_motion_frames": 0, "idle_frames": 0, "reversals": 0, "hero_off_max": Vector2.ZERO,
		"hero_off_sum": 0.0, "hero_near_edge": 0, "blocked_frames": 0, "forbidden": 0, "gap_sum": 0.0, "gap_max": 0.0,
		"dt_max": 0.0, "dt_sum": 0.0, "settle": [], "steps": [], "zoom": float(zone.cam.PRESETS[p]["zoom"])}
	_prev_c = Vector2.INF
	_skip = 10
	await get_tree().create_timer(0.6).timeout
	# 1. huit directions depuis le départ (prairie de l'avant-poste)
	for k in [[K_R], [K_D, K_R], [K_D], [K_D, K_L], [K_L], [K_U, K_L], [K_U], [K_U, K_R]]:
		await _step(p, "direction " + _arrows(k), k, 0.3 if short else 0.45)
	await _step(p, "arrêt", [], 0.6)
	# 2. chemin vers le hameau, passage DERRIÈRE la 2e maison
	await _goto(p, "chemin vers le hameau", Vector2(740, 528))
	await _goto(p, "devant la 2e maison", Vector2(860, 420))
	await _goto(p, "angle gauche maison 2", Vector2(808, 372))
	await _goto(p, "derrière la maison 2", Vector2(860, 300))
	await _shot(p, "derriere_maison2")
	await _goto(p, "derrière la maison 2 (droite)", Vector2(950, 290))
	await _goto(p, "côté droit maison 2", Vector2(1000, 340))
	# 3. couloir étroit entre les deux clôtures, d'un bout à l'autre
	await _goto(p, "entrée du couloir", Vector2(1028, 492))
	await _goto(p, "dans le couloir", Vector2(1100, 476))
	await _shot(p, "couloir")
	await _goto(p, "sortie du couloir", Vector2(1176, 458))
	# 4. limites : lisière droite, eau (bas), angle haut
	await _goto(p, "vers la limite droite", Vector2(1330, 480))
	await _step(p, "pousser contre la limite droite", [K_R], 0.6)
	await _shot(p, "limite_droite")
	await _goto(p, "bord de l'eau", Vector2(1200, 532))
	await _step(p, "pousser vers l'eau", [K_D], 0.6)
	if not short:
		await _goto(p, "prairie ouverte", Vector2(1000, 250))
		await _goto(p, "angle haut", Vector2(1080, 118))
		await _step(p, "pousser contre la lisière haute", [K_U], 0.6)
		await _shot(p, "limite_haute")
	# 5. bosquet : entre et derrière les arbres
	await _goto(p, "vers le bosquet", Vector2(520, 330))
	await _goto(p, "lisière du bosquet", Vector2(330, 370))
	await _goto(p, "derrière les arbres", Vector2(280, 380))
	await _shot(p, "bosquet")
	await _goto(p, "entre les troncs", Vector2(200, 420))
	await _goto(p, "sortie du bosquet", Vector2(150, 480))
	# 6. vers le garde (devant la maison d'origine) et dialogue
	await _goto(p, "devant le banc", Vector2(296, 605))
	await _goto(p, "devant la porte", Vector2(392, 600))
	await _goto(p, "à côté du garde", zone.npc.position + Vector2(-12, 4))
	await _step(p, "arrêt", [], 0.4)
	_press(KEY_E)
	await get_tree().create_timer(0.3).timeout
	var talked: bool = zone._dialog.is_open()
	await _shot(p, "dialogue")
	_press(KEY_ESCAPE)
	await get_tree().create_timer(0.4).timeout
	_rec["dialogue"] = talked
	# 7. approche du Vorgane (sans le toucher : le combat est vérifié par la démo et le test de retour)
	await _goto(p, "vers le Vorgane", zone.monster_pos + Vector2(zone.monster_rx + 22, 4))
	await _step(p, "arrêt devant le Vorgane", [], 0.8)
	await _shot(p, "vorgane")
	results[p] = _summary()
	print("P1 %s : %s" % [p, JSON.stringify(results[p])])


func _arrows(keys: Array) -> String:
	var s := ""
	for k in keys:
		s += {K_R: "→", K_L: "←", K_U: "↑", K_D: "↓"}[k]
	return s


func _step(p: String, label: String, keys: Array, sec: float) -> void:
	_label = label
	_set_keys(keys)
	await get_tree().create_timer(sec).timeout
	_set_keys([])
	_rec["steps"].append({"label": label, "ok": true, "pos": zone.hero.position.round()})


## Pilote « humain » : itinéraire planifié une fois (A* de la démo, mêmes collisions, simplifié en lignes droites),
## puis suivi aux FLÈCHES (vraies touches) point par point, comme un joueur qui sait où il va.
func _goto(p: String, label: String, target: Vector2) -> void:
	_label = label
	var nav = zone._nav()
	var from := Vector2i(zone.hero.position / zone.CELL)
	var to := Vector2i(target / zone.CELL)
	var pts := PackedVector2Array([zone.hero.position])
	if nav.is_point_solid(from):                       # héros contre un obstacle : cellule libre la plus proche
		var best := from
		for r in range(1, 5):
			for dx in range(-r, r + 1):
				for dy in range(-r, r + 1):
					var c := from + Vector2i(dx, dy)
					if best == from and nav.region.has_point(c) and not nav.is_point_solid(c):
						best = c
			if best != from:
				break
		from = best
	if nav.region.has_point(to) and not nav.is_point_solid(to) and not nav.is_point_solid(from):
		var raw: PackedVector2Array = nav.get_point_path(from, to)
		for i in range(1, raw.size() - 1):
			pts.append(raw[i] + Vector2(zone.CELL, zone.CELL) * 0.5)
	pts.append(target)
	if pts.size() == 2 and not zone.segment_free(zone.hero.position, target):
		print("P1 %s pas d'itinéraire pour « %s »" % [p, label])
	var way := PackedVector2Array()                   # un point de passage tous les 2 pas de grille (8 px)
	for i in range(2, pts.size() - 1, 2):
		way.append(pts[i])
	way.append(target)
	for i in way.size():
		await _drive(way[i], 3.0)
	var ok: bool = target.distance_to(zone.hero.position) < 6.0
	_rec["steps"].append({"label": label, "ok": ok, "pos": zone.hero.position.round()})
	if not ok:
		print("P1 %s ÉCHEC « %s » : héros à %.1f px du point (%s)" % [p, label, target.distance_to(zone.hero.position), zone.hero.position.round()])


func _drive(target: Vector2, tol: float) -> void:
	var t := 0.0
	var h := 0
	var v := 0
	while t < 9.0:
		var to: Vector2 = target - zone.hero.position
		if to.length() < tol:
			break
		# seuil de départ 2 px < tolérance / √2 : jamais de zone où aucune touche n'est tenue sans être arrivé
		if h == 0 and absf(to.x) > 2.0:
			h = signi(int(signf(to.x)))
		elif h != 0 and (absf(to.x) < 1.5 or signf(to.x) != h):
			h = 0
		if v == 0 and absf(to.y) > 2.0:
			v = signi(int(signf(to.y)))
		elif v != 0 and (absf(to.y) < 1.5 or signf(to.y) != v):
			v = 0
		var keys := []
		if h > 0: keys.append(K_R)
		if h < 0: keys.append(K_L)
		if v > 0: keys.append(K_D)
		if v < 0: keys.append(K_U)
		_set_keys(keys)
		await get_tree().process_frame
		t += get_process_delta_time()
	if tol <= 3.0:
		_set_keys([])


func _shot(p: String, name: String) -> void:
	await get_tree().create_timer(0.7).timeout          # la caméra a fini de se poser
	if shots_dir == "" or DisplayServer.get_name() == "headless":
		return
	_hud.visible = false
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [shots_dir, name, p])
	_hud.visible = true


func _press(k: Key) -> void:
	for down in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = k
		ev.physical_keycode = k
		ev.pressed = down
		Input.parse_input_event(ev)


func _set_keys(keys: Array) -> void:
	for k in [K_R, K_L, K_U, K_D]:
		var down: bool = keys.has(k)
		if bool(_held.get(k, false)) != down:
			var ev := InputEventKey.new()
			ev.keycode = k
			ev.physical_keycode = k
			ev.pressed = down
			Input.parse_input_event(ev)
			_held[k] = down


# ------------------------------------------------------------------------------------------------ mesures
func _process(delta: float) -> void:
	_t += delta
	if zone.cam == null or _rec.is_empty():
		return
	if _skip > 0:
		_skip -= 1
		_prev_c = Vector2.INF
		_prev_hero = zone.hero.position
		return
	var k := ""
	for key in [K_L, K_U, K_D, K_R]:
		k += {K_L: "←", K_U: "↑", K_D: "↓", K_R: "→"}[key] if _held.get(key, false) else "·"
	_hud.text = "Caméra %s   touches : %s\n%s" % [zone.cam.PRESETS[zone.cam.preset]["label"], k, _label]
	var c: Vector2 = zone.cam.get_screen_center_position()
	var hero: Vector2 = zone.hero.position
	var moving := hero.distance_to(_prev_hero) > 0.01
	var z: float = zone.cam.zoom.x
	_rec["frames"] += 1
	if OS.has_environment("P1_DEBUG") and _rec["frames"] % 30 == 0:
		print("DBG f=%d hero=%s held=%s label=%s dt=%.4f" % [_rec["frames"], str(hero.round()), str(_held), _label, delta])
	_rec["dt_max"] = maxf(_rec["dt_max"], delta)
	_rec["dt_sum"] += delta
	if _prev_c != Vector2.INF and delta > 0.0:
		var v := (c - _prev_c) / delta * z                  # vitesse caméra en px d'ÉCRAN / s
		var acc := (v - _prev_v).length() / delta
		if v.length() > _rec["cam_speed_max"]:
			_rec["cam_speed_where"] = _label
		_rec["cam_speed_max"] = maxf(_rec["cam_speed_max"], v.length())
		_rec["cam_acc_max"] = maxf(_rec["cam_acc_max"], acc)
		if acc > 6000.0:                                     # à-coup : variation de vitesse > 100 px/s en 1/60 s
			_rec["cam_acc_spikes"] += 1
			if not _rec.has("spike_where"):
				_rec["spike_where"] = []
			if not _rec["spike_where"].has(_label):
				_rec["spike_where"].append(_label)
		if v.length() > 2.0 and _prev_v.length() > 2.0 and v.dot(_prev_v) < 0.0:
			_rec["reversals"] += 1                           # oscillation / va-et-vient
		if not moving:
			_rec["idle_frames"] += 1
			if v.length() > 3.0:
				_rec["idle_cam_motion_frames"] += 1          # la caméra glisse encore alors que le groupe est arrêté
			# temps de pose : de l'arrêt du groupe à l'immobilité de la caméra (< 3 px/s)
			if _stop_t >= 0.0:
				_stop_t += delta
				if v.length() <= 3.0:
					_rec["settle"].append(_stop_t)
					_stop_t = -1.0
		elif _stop_t >= 0.0:
			_stop_t = -1.0                                     # reparti avant que la caméra soit posée
		if not moving and hero.distance_to(_prev_hero) <= 0.01 and _was_moving:
			_stop_t = 0.0
		_prev_v = v
	_prev_c = c
	if moving:
		_rec["moving_frames"] += 1
	_was_moving = moving
	var off: Vector2 = (hero + Vector2(0, -14) - c) * z      # héros (buste) par rapport au centre, px d'écran
	if absf(off.x) > _rec["hero_off_max"].x or absf(off.y) > _rec["hero_off_max"].y:
		_rec["hero_off_where"] = "%s héros %s centre %s off %s" % [_label, str(hero.round()), str(c.round()), str(off.round())]
	_rec["hero_off_max"] = Vector2(maxf(_rec["hero_off_max"].x, absf(off.x)), maxf(_rec["hero_off_max"].y, absf(off.y)))
	_rec["hero_off_sum"] += off.length()
	var half: Vector2 = zone.get_viewport().get_visible_rect().size / 2.0
	if absf(off.x) > half.x - 120.0 or absf(off.y) > half.y - 90.0:
		_rec["hero_near_edge"] += 1
	for w in zone.party:
		if not zone.free_at(w.position):
			_rec["forbidden"] += 1
	var gap: float = zone.party[0].position.distance_to(zone.party[1].position)
	_rec["gap_sum"] += gap
	_rec["gap_max"] = maxf(_rec["gap_max"], gap)
	_prev_hero = hero


func _summary() -> Dictionary:
	var n := maxi(1, _rec["frames"])
	var fails := (_rec["steps"] as Array).filter(func(s): return not s["ok"])
	return {
		"zoom": _rec["zoom"],
		"monde_visible_px": [snappedf(1280.0 / _rec["zoom"], 1), snappedf(720.0 / _rec["zoom"], 1)],
		"hauteur_aren_ecran_px": snappedf(29.0 * _rec["zoom"], 1),
		"images": n,
		"vitesse_camera_max_px_s": snappedf(_rec["cam_speed_max"], 1),
		"acceleration_max_px_s2": snappedf(_rec["cam_acc_max"], 1),
		"a_coups": _rec["cam_acc_spikes"],
		"a_coups_lieux": _rec.get("spike_where", []),
		"inversions_de_sens": _rec["reversals"],
		"glissement_a_l_arret_pct": snappedf(100.0 * _rec["idle_cam_motion_frames"] / maxi(1, _rec["idle_frames"]), 0.1),
		"temps_de_pose_moyen_ms": snappedf(1000.0 * _mean(_rec["settle"]), 1),
		"temps_de_pose_max_ms": snappedf(1000.0 * (_rec["settle"].max() if not _rec["settle"].is_empty() else 0.0), 1),
		"arrets_mesures": _rec["settle"].size(),
		"heros_ecart_centre_moyen_px": snappedf(_rec["hero_off_sum"] / n, 0.1),
		"heros_ecart_centre_max_px": [snappedf(_rec["hero_off_max"].x, 1), snappedf(_rec["hero_off_max"].y, 1)],
		"heros_ecart_max_lieu": _rec.get("hero_off_where", ""),
		"vitesse_camera_max_lieu": _rec.get("cam_speed_where", ""),
		"heros_pres_du_bord_pct": snappedf(100.0 * _rec["hero_near_edge"] / n, 0.1),
		"positions_interdites": _rec["forbidden"],
		"ecart_groupe_moyen_px": snappedf(_rec["gap_sum"] / n, 0.1),
		"image_max_ms": snappedf(_rec["dt_max"] * 1000.0, 0.1),
		"images_par_s_rendu": Performance.get_monitor(Performance.TIME_FPS),
		"temps_process_ms": snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.01),
		"dialogue_ouvert": _rec.get("dialogue", false),
		"etapes_ratees": fails.map(func(s): return s["label"]),
		"memoire_statique_mo": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"memoire_textures_mo": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.1),
		"objets_dessines": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
	}


static func _mean(a: Array) -> float:
	var t := 0.0
	for x in a:
		t += x
	return t / maxi(1, a.size())


func _finish() -> void:
	var ok := true
	for p in results:
		var r: Dictionary = results[p]
		ok = ok and r["positions_interdites"] == 0 and r["dialogue_ouvert"] and (r["etapes_ratees"] as Array).is_empty()
	print("P1 VERDICT : %s" % ("RÉUSSI" if ok else "ÉCHEC"))
	if out_path != "":
		FileAccess.open(out_path, FileAccess.WRITE).store_string(JSON.stringify(results, "  "))
	get_tree().quit(0 if ok else 1)
