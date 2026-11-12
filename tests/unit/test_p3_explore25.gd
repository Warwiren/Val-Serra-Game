extends "res://tests/test_case.gd"
## P3 — prototype d'exploration 2.5D : modèle de monde commun (doc 06), navigation par niveaux, caméra à 3 zooms.
## Tests sans rendu ; les parcours complets (A et B, 30/60/144 i/s) sont dans docs/P3_PROTOTYPE_25D.md.

const World25 = preload("res://src/explore25/world25.gd")
const Cam25 = preload("res://src/explore25/cam25.gd")
const SPEC_MD5 := "61eb9afec8212878e25116bc047d4c33"   # gabarits_blockout_v01.json tel que fourni (doc 06)
const GRID := 0.25


func _w(mode := "temoin"):
	return World25.load_world(World25.SPEC, mode)


## Remplissage par diffusion sur une grille de 25 cm, en respectant les règles de déplacement (pas ≤ 25 cm, disque
## du personnage entièrement sur une surface continue, solides). skip : identifiants de surfaces interdites.
func _flood(w, start: Vector3, skip := []) -> Dictionary:
	var seen := {}
	var key := func(p: Vector2, h: float) -> String: return "%d,%d,%d" % [roundi(p.x / GRID), roundi(p.y / GRID), roundi(h * 2.0)]
	var s0: Dictionary = w.stand(Vector2(start.x, start.y), start.z)
	var q: Array = [[Vector2(start.x, start.y), s0["h"]]]
	seen[key.call(q[0][0], q[0][1])] = q[0]
	while q.size() > 0:
		var cur: Array = q.pop_back()
		for d in [Vector2(GRID, 0), Vector2(-GRID, 0), Vector2(0, GRID), Vector2(0, -GRID)]:
			var np: Vector2 = cur[0] + d
			var s: Dictionary = w.stand(np, cur[1])
			if s.is_empty() or skip.has(s["id"]):
				continue
			var k: String = key.call(np, s["h"])
			if seen.has(k):
				continue
			seen[k] = [np, s["h"], s["id"]]
			q.append([np, s["h"]])
	return seen


func test_spec_file_is_the_unmodified_doc06_json() -> void:
	check_eq(FileAccess.get_md5(World25.SPEC), SPEC_MD5, "le JSON du doc 06 est copié sans modification")
	var w = _w()
	check_eq(w.spec["assets"].size(), 10, "10 gabarits")
	check_eq(w.checkpoints.size(), 7, "7 points A à G")
	check_eq(w.spec["camera"]["zoom_presets"], [2.0, 2.5, 3.0], "zooms du doc 06")
	check_eq(Cam25.ZOOMS, [2.0, 2.5, 3.0], "zooms de la caméra = doc 06")
	check_eq(Cam25.ZOOMS[Cam25.DEFAULT_INDEX], 2.5, "zoom par défaut ×2,5")
	check(w.extent == Rect2(0, 0, 32, 24), "zone 32 × 24 m")


func test_projection_is_the_same_in_2d_and_3d() -> void:
	# A projette (x, y, h) en 2D ; B place une Camera3D orthographique de base (droite, haut, arrière).
	for p in [Vector3(0, 0, 0), Vector3(14, 11, 0), Vector3(14, 8, 1.2), Vector3(23.5, 13.75, 0), Vector3(-3, 30, 2.5)]:
		var g := World25.g3(p)
		var s3 := Vector2(g.dot(World25.cam_right()), -g.dot(World25.cam_up())) * World25.PPM
		check(World25.screen(p).distance_to(s3) < 0.001, "projection identique en %s" % str(p))
	var b := Basis(World25.cam_right(), World25.cam_up(), World25.cam_back())
	check(absf(b.determinant() - 1.0) < 0.0001, "repère caméra orthonormé direct")
	check(absf(rad_to_deg(asin(World25.cam_back().y)) - 35.0) < 0.01, "plongée 35°")
	check(World25.screen(Vector3(0, 0, 1)).distance_to(Vector2(0, -20 * cos(deg_to_rad(35)))) < 0.001, "1 m de hauteur = 16,4 px natifs")
	for v in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, -1), Vector2(0, 1)]:
		check(World25.plan_to_screen_dir(World25.input_to_plan(v)).distance_to(v) < 0.001, "flèche %s : même direction à l'écran" % str(v))


func test_checkpoints_are_on_their_level() -> void:
	var w = _w()
	for id in ["A", "B", "C", "D", "F", "G"]:
		var c: Vector3 = w.checkpoints[id]
		var s: Dictionary = w.stand(Vector2(c.x, c.y), c.z)
		check(not s.is_empty(), "point %s tenable" % id)
		if not s.is_empty():
			check(absf(s["h"] - c.z) < 0.01, "point %s à h = %.1f" % [id, c.z])
	var e: Vector3 = w.checkpoints["E"]
	check(w.npc["p"] == e, "PNJ au point E")
	check(not w.stand(Vector2(11.9, 5.6), 1.2).is_empty(), "on peut se tenir à côté du PNJ")


func test_upper_level_is_reachable_only_by_the_stairs() -> void:
	var w = _w()
	var all := _flood(w, w.spawn)
	var upper := 0
	for k in all:
		if all[k][1] > 1.15:
			upper += 1
	check(upper > 500, "terrasse atteinte depuis l'entrée (%d cases)" % upper)
	var no_stair := _flood(w, w.spawn, ["escalier"])
	var upper2 := 0
	for k in no_stair:
		if no_stair[k][1] > 0.3:
			upper2 += 1
	check_eq(upper2, 0, "sans escalier, aucune case au-dessus du sol (rebord infranchissable)")


func test_river_blocks_and_bridge_is_the_only_crossing() -> void:
	var w = _w()
	for x in [22.2, 23.5, 24.8]:
		for y in [9.0, 11.0, 16.0, 20.0, 22.5]:
			check(w.surfaces_under(Vector2(x, y)).is_empty(), "eau non praticable en (%.1f, %.1f)" % [x, y])
	var all := _flood(w, w.spawn)
	var reach_g := false
	for k in all:
		if (all[k][0] as Vector2).distance_to(Vector2(30, 13.75)) < 0.2:
			reach_g = true
	check(reach_g, "sortie G atteignable")
	var no_bridge := _flood(w, w.spawn, ["pont"])
	var east := false
	for k in no_bridge:
		if all.has(k) and (no_bridge[k][0] as Vector2).x > 26.0:
			east = true
	check(not east, "sans le pont, la rive est est inaccessible")


func test_stair_height_is_continuous() -> void:
	var w = _w()
	var prev := -1.0
	var worst := 0.0
	var y := 11.2
	while y >= 7.8:
		var s: Dictionary = w.surface_at(Vector2(14, y), prev if prev >= 0 else 0.0)
		check(not s.is_empty(), "surface continue dans l'axe de l'escalier (y = %.2f)" % y)
		if s.is_empty():
			return
		if prev >= 0:
			worst = maxf(worst, absf(s["h"] - prev))
		prev = s["h"]
		y -= 0.05
	check(worst <= 0.03, "pas de saut d'altitude dans l'escalier (max %.3f m / 5 cm)" % worst)
	check(absf(prev - 1.2) < 0.001, "arrivée à h = 1,2 m")


func test_two_levels_overlap_on_screen_and_order_comes_from_the_world() -> void:
	# doc 05 §02 : tri selon le point d'appui ET l'altitude, pas le Y écran. Héros sur le bord de la terrasse,
	# compagnon au pied du mur : leurs images (46 px de haut) se recouvrent à l'écran ; le monde sait qui est où.
	var w = _w()
	var up := Vector3(11, 7.4, 1.2)
	var low := Vector3(11, 8.4, 0.0)
	check(not w.stand(Vector2(up.x, up.y), up.z).is_empty(), "héros tenable sur la terrasse")
	check(not w.stand(Vector2(low.x, low.y), low.z).is_empty(), "compagnon tenable au pied du mur")
	var su := World25.screen(up)
	var sl := World25.screen(low)
	check(sl.y - su.y < 46.0, "les deux images se recouvrent à l'écran (écart %.1f px < 46 px)" % (sl.y - su.y))
	check(World25.depth(low.x, low.y) > World25.depth(up.x, up.y), "le compagnon est plus près de la caméra : il passe devant")
	check(w.level_of(up.z) == 1 and w.level_of(low.z) == 0, "niveaux distincts")
	# un même point écran correspond à des positions différentes selon l'altitude
	var p0 := World25.screen_to_plan(su, 0.0)
	check(p0.distance_to(Vector2(up.x, up.y)) > 1.5, "au sol, le même point écran est 1,7 m plus loin")


func test_zoom_steps_wheel_and_ui_lock() -> void:
	var c = Cam25.new()
	check_eq(c.zoom, 2.5, "×2,5 au départ")
	check(c.wheel(1), "molette vers l'avant : ×3")
	check_eq(c.target_zoom(), 3.0, "×3")
	check(not c.wheel(1), "pas au-delà de ×3")
	c.wheel(-1)
	c.wheel(-1)
	check_eq(c.target_zoom(), 2.0, "×2")
	check(not c.wheel(-1), "pas en dessous de ×2")
	c.ui_lock = true
	check(not c.wheel(1), "molette ignorée pendant un dialogue")
	check_eq(c.target_zoom(), 2.0, "zoom inchangé pendant le dialogue")
	check_eq(c.wheel_ignored, 1, "molette ignorée comptée")
	c.ui_lock = false
	c.wheel(1)
	for i in 30:
		c.update(Vector2.ZERO, 1.0 / 60.0)
	check_eq(c.zoom, 2.5, "transition douce terminée en 0,3 s")


func test_view_never_leaves_the_decor_at_any_zoom() -> void:
	for file in [World25.SPEC, "res://data/explore25/instance_2_fictive.json"]:
		var w = World25.load_world(file)
		var bad := 0
		var n := 0
		for zi in 3:
			var c = Cam25.new()
			c.bounds = w.camera_bounds()
			c.set_index(zi, false)
			var x: float = w.extent.position.x
			while x <= w.extent.end.x:
				var y: float = w.extent.position.y
				while y <= w.extent.end.y:
					for h in [0.0, 1.2]:
						if w.surface_at(Vector2(x, y), h).is_empty():
							continue
						c.snap_to(World25.screen(Vector3(x, y, h)))
						n += 1
						if not w.view_inside_decor(c.view_rect()):
							bad += 1
					y += 1.0
				x += 1.0
		check(n > 50, "%s : positions testées (%d)" % [file.get_file(), n])
		check_eq(bad, 0, "%s : aucune vue ne montre de vide, aux trois zooms" % file.get_file())


func test_known_dimension_issues_are_real() -> void:
	# Signalés dans le rapport (spécifications non modifiées) :
	var w = _w()
	# 1. 0,5 m entre la façade de la maison (y = 7,5) et le rebord (y = 8) : infranchissable (personnage 0,56 m)
	var ok := false
	var x := 16.0
	while x <= 20.0:
		if not w.stand(Vector2(x, 7.75), 1.2).is_empty():
			ok = true
		x += 0.1
	check(not ok, "aucune position tenable devant la maison")
	# 2. derrière la maison, le passage de 1 m (y = 2..3) reste praticable
	check(not w.stand(Vector2(18, 2.5), 1.2).is_empty(), "passage derrière la maison praticable")


func test_micro_subset_is_two_levels_one_stair() -> void:
	var w = _w("micro")
	var ids := []
	for r in w.regions:
		ids.append(r["id"])
	check(ids.has("terrain_bas") and ids.has("terrasse_haute") and ids.has("escalier"), "deux surfaces + escalier")
	check(not ids.has("pont"), "pas de pont dans le micro-test")
	check(w.triggers.is_empty(), "pas de sortie dans le micro-test")


func test_f5_scene_is_unchanged_and_p3_scenes_load() -> void:
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/p4/avant_poste.tscn", "F5 : avant-poste P4 (promotion du 12 novembre 2026, brief P4)")
	check(ResourceLoader.exists("res://scenes/explore_hd2d/zone_exploration.tscn"), "ancienne exploration stable conservée (F6)")
	for p in ["res://scenes/explore25/demo_a_2d.tscn", "res://scenes/explore25/demo_b_3d.tscn",
			"res://scenes/explore25/scene_temoin.tscn", "res://scenes/explore25/scene_temoin_2d.tscn"]:
		check(load(p) is PackedScene, "%s se charge" % p.get_file())
