extends "res://tests/test_case.gd"
## P1 — caméras d'exploration A / B / C et zone de test agrandie.

const Cam = preload("res://src/explore/camera_hd2d.gd")
const Zone = preload("res://scenes/explore_hd2d/zone_hd2d.gd")
const P1_ZONE := "res://art/explore_hd2d/p1/zone_p1.json"
const P1_DECOR := "res://art/explore_hd2d/p1/decor_p1.json"


func _cam(p: String) -> Node:
	var c = Cam.new()
	c.set_bounds(Rect2(0, 0, 1408, 800))
	c.apply(p)
	c.snap_to(Vector2(700, 400))
	return c


func test_default_camera_is_unchanged_reference_a() -> void:
	var gs = load("res://src/game/game_state.gd").new()
	check_eq(gs.camera_preset, "A", "caméra par défaut : A (réglage actuel)")
	gs.free()
	var a = _cam("A")
	check_eq(a.zoom, Vector2(2, 2), "A : échelle ×2 d'origine")
	check(a.position_smoothing_enabled and is_equal_approx(a.position_smoothing_speed, 4.0), "A : lissage natif vitesse 4 (d'origine)")
	check(not a.limit_smoothed, "A : limites non lissées (d'origine)")
	a.follow(Vector2(710.4, 402.6), Vector2.RIGHT, 1.0 / 60.0)
	check_eq(a.position, Vector2(710, 403), "A : la cible est la position arrondie du héros (d'origine)")
	a.free()


func test_presets_scale_and_switch_without_reload() -> void:
	var c = _cam("A")
	for p in ["B", "C", "A"]:
		c.apply(p, Vector2(700, 400))
		check_eq(c.preset, p, "changement vers %s sur le même nœud" % p)
		check_eq(c.zoom.x, float(Cam.PRESETS[p]["zoom"]), "%s : échelle appliquée" % p)
	check_eq(Cam.next_of("A"), "B", "C (touche) : A -> B")
	check_eq(Cam.next_of("C"), "A", "C (touche) : C -> A")
	check(Cam.PRESETS["A"]["zoom"] < Cam.PRESETS["B"]["zoom"] and Cam.PRESETS["B"]["zoom"] < Cam.PRESETS["C"]["zoom"], "A < B < C (rapprochement)")
	c.free()


func test_dead_zone_keeps_camera_still_for_small_moves() -> void:
	for p in ["B", "C"]:
		var c = _cam(p)
		var start: Vector2 = c.position
		var dz: Vector2 = Cam.PRESETS[p]["dead"]
		for i in 120:                                   # 2 s : petit pas de côté, dans la zone morte
			c.follow(Vector2(700 + dz.x * 0.8, 400), Vector2.ZERO, 1.0 / 60.0)
		check(c.position.distance_to(start) < 0.5, "%s : un pas dans la zone morte ne déplace pas la caméra" % p)
		for i in 120:
			c.follow(Vector2(780, 400), Vector2.ZERO, 1.0 / 60.0)
		check(c.position.x > start.x + 50.0, "%s : au-delà de la zone morte, la caméra suit" % p)
		c.free()


func test_smoothing_never_overshoots_and_is_frame_rate_independent() -> void:
	for p in ["B", "C"]:
		var finals := []
		for fps in [30, 60, 144]:
			var c = _cam(p)
			var prev: float = c.position.x
			var over := false
			for i in fps:                               # 1 s après un saut de cible de 100 px vers la droite
				c.follow(Vector2(800, 400), Vector2.ZERO, 1.0 / fps)
				over = over or c.position.x < prev - 0.001 or c.position.x > 800.0 + 0.001
				prev = c.position.x
			check(not over, "%s à %d i/s : approche monotone, sans dépassement" % [p, fps])
			finals.append(c.position.x)
			c.free()
		check(absf(finals[0] - finals[2]) < 1.0, "%s : même position après 1 s à 30 et 144 i/s (%.2f / %.2f)" % [p, finals[0], finals[2]])


func test_camera_stays_inside_map_bounds() -> void:
	for p in ["B", "C"]:
		var c = _cam(p)
		var half: Vector2 = Vector2(1280, 720) / c.zoom / 2.0
		for target in [Vector2(5, 5), Vector2(1400, 790), Vector2(5, 790), Vector2(1400, 5)]:
			c.snap_to(target)
			for i in 90:
				c.follow(target, Vector2.ONE.normalized(), 1.0 / 60.0)
			var r := Rect2(c.position - half, half * 2.0)
			check(Rect2(0, 0, 1408, 800).grow(0.5).encloses(r), "%s : vue dans la carte au coin %s" % [p, str(target)])
		c.free()


func test_p1_zone_is_3_to_4_times_larger_and_complete() -> void:
	var z: Dictionary = JSON.parse_string(FileAccess.open(P1_ZONE, FileAccess.READ).get_as_text())
	var o: Dictionary = JSON.parse_string(FileAccess.open("res://art/explore_hd2d/zone.json", FileAccess.READ).get_as_text())
	var ratio: float = (z["native"][0] * z["native"][1]) / float(o["native"][0] * o["native"][1])
	check(ratio >= 3.0 and ratio <= 4.01, "surface de la carte : %.2f× l'avant-poste" % ratio)
	var wa := absf(_area(z["walkable"])) / absf(_area(o["walkable"]))
	check(wa >= 3.0, "zone praticable : %.2f× l'avant-poste" % wa)
	check_eq(z["ppm"], o["ppm"], "même échelle du monde (px par mètre)")
	var d: Dictionary = Zone.decor_spec(P1_DECOR)
	var sol: Texture2D = load(d["sol"])
	check(sol != null and sol.get_width() == int(z["native"][0]) * 2 and sol.get_height() == int(z["native"][1]) * 2, "sol à la même densité que l'origine (2 px d'écran par px natif)")
	for g in z["sprites"]:
		if d["masquer"].has(g):
			continue
		check(d["elements"].has(g), "élément %s illustré" % g)
		for layer in d["elements"].get(g, {"calques": []})["calques"]:
			check(ResourceLoader.exists(Zone.DECOR + "%s.png" % layer), "calque validé réutilisé : %s" % layer)
	for k in o["sprites"]:
		check(z["sprites"].has(k), "élément d'origine conservé : %s" % k)


func test_p1_zone_key_points_are_reachable() -> void:
	var z = Zone.new()
	z.zone = JSON.parse_string(FileAccess.open(P1_ZONE, FileAccess.READ).get_as_text())
	for p in z.zone["walkable"]:
		z.walkable.append(Vector2(p[0], p[1]))
	for g in z.zone["sprites"]:
		var e: Dictionary = z.zone["sprites"][g]
		if e["solid"] and e["footprint"].size() >= 3:
			z.solids.append(z._poly(e["footprint"]))
	var sp: Array = z.zone["spawn"]["heros"]
	var start := Vector2(sp[0], sp[1])
	check(z.free_at(start), "départ libre")
	var nav: AStarGrid2D = z._nav()
	var pts := {"garde": z.zone["spawn"]["pnj"], "Vorgane": z.zone["spawn"]["monstre"], "derrière la maison 2": [860, 300],
		"dans le couloir étroit": [1100, 476], "derrière les arbres du bosquet": [280, 380], "limite droite": [1330, 480],
		"angle haut": [1080, 118]}
	for k in pts:
		var t := Vector2(pts[k][0], pts[k][1]) + (Vector2(-14, 6) if k in ["garde", "Vorgane"] else Vector2.ZERO)
		if k == "Vorgane":
			t = Vector2(pts[k][0], pts[k][1]) + Vector2(44, 4)
		var path := nav.get_point_path(Vector2i(start / z.CELL), Vector2i(t / z.CELL))
		check(not path.is_empty(), "accessible depuis le départ : %s" % k)
	# le couloir est réellement étroit : on n'y tient qu'à peu près de front (1 personnage)
	var free := 0                                   # étendue libre continue autour du milieu du couloir
	var y0 := 476
	while z.free_at(Vector2(1100, y0 - 1)) and free < 80:
		y0 -= 1
		free += 1
	var y1 := 476
	while z.free_at(Vector2(1100, y1 + 1)) and free < 80:
		y1 += 1
		free += 1
	check(free > 6 and free < 34, "couloir étroit : %d px libres en travers (≈ 1 à 1,5 m)" % free)
	z.hero = Zone.Walker.new("aren", true)
	z.hero.free()
	z.free()


static func _area(poly: Array) -> float:
	var a := 0.0
	for i in poly.size():
		var p: Array = poly[i]
		var q: Array = poly[(i + 1) % poly.size()]
		a += p[0] * q[1] - q[0] * p[1]
	return a / 2.0
