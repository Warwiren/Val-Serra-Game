extends "res://tests/test_case.gd"
## P3-07 — variantes de caméra A/B/C et paysage non jouable (doc 07). Tests sans rendu.

const World25 = preload("res://src/explore25/world25.gd")
const Cam25 = preload("res://src/explore25/cam25.gd")
const Variantes = preload("res://src/explore25/variantes25.gd")
const Paysage = preload("res://src/explore25/paysage25.gd")


func _with_pitch(deg: float) -> void:
	World25.pitch = deg_to_rad(deg)


func _reset() -> void:
	World25.pitch = World25.PITCH


func test_one_lever_per_variant() -> void:
	var a: Dictionary = Variantes.get_v("A")
	var b: Dictionary = Variantes.get_v("B")
	var c: Dictionary = Variantes.get_v("C")
	check_eq(a["pitch_deg"], 35.0, "A : plongée 35°")
	check_eq(a["aim_frac"], 0.0, "A : héros centré")
	check(b["pitch_deg"] == 28.0 and b["aim_frac"] == a["aim_frac"], "B : seule la plongée change (28°)")
	check(c["pitch_deg"] == a["pitch_deg"] and c["aim_frac"] > 0.0, "C : seul le cadrage vertical change")
	check_eq(World25.PITCH, deg_to_rad(35.0), "référence P3 inchangée")


func test_projection_follows_the_3d_camera_at_28_degrees() -> void:
	_with_pitch(28.0)
	for p in [Vector3(0, 0, 0), Vector3(14, 11, 0), Vector3(14, 8, 1.2), Vector3(-10, -30, 12)]:
		var g := World25.g3(p)
		var s3 := Vector2(g.dot(World25.cam_right()), -g.dot(World25.cam_up())) * World25.PPM
		check(World25.screen(p).distance_to(s3) < 0.001, "28° : projection 2D = caméra 3D en %s" % str(p))
	check(absf(rad_to_deg(asin(World25.cam_back().y)) - 28.0) < 0.01, "caméra réellement inclinée à 28°")
	check(World25.screen_to_plan(World25.screen(Vector3(5, 7, 1.2)), 1.2).distance_to(Vector2(5, 7)) < 0.001, "inverse cohérente")
	_reset()


func test_sprite_screen_height_is_kept_between_variants() -> void:
	# carte verticale : hauteur monde = px / (20 · cos(plongée)) -> à l'écran, toujours la hauteur de l'image en px
	for deg in [35.0, 28.0]:
		_with_pitch(deg)
		var world_h := 29.0 / World25.PPM / cos(World25.pitch)
		var px := World25.screen(Vector3(0, 0, 0)).y - World25.screen(Vector3(0, 0, world_h)).y
		check(absf(px - 29.0) < 0.001, "%d° : Aren reste à 29 px natifs (%.2f)" % [int(deg), px])
	_reset()


func test_c_puts_the_hero_near_63_percent_and_recentres_in_dialogue() -> void:
	var c = Cam25.new()
	c.aim_frac = Variantes.get_v("C")["aim_frac"]
	var hero := Vector2(500, 300)
	c.snap_to(hero)
	var v: Rect2 = c.view_rect()
	var pct := (hero.y - v.position.y) / v.size.y * 100.0
	check(pct >= 60.0 and pct <= 65.0, "héros entre 60 et 65 %% de la hauteur (%.1f %%)" % pct)
	c.ui_lock = true
	for i in 120:
		c.update(hero, 1.0 / 60.0)
	v = c.view_rect()
	pct = (hero.y - v.position.y) / v.size.y * 100.0
	check(absf(pct - 52.8) < 0.5, "dialogue : retour au cadrage centré P3 (%.1f %%)" % pct)
	var a = Cam25.new()
	a.snap_to(hero)
	v = a.view_rect()
	check(absf((hero.y - v.position.y) / v.size.y * 100.0 - 52.8) < 0.1, "A : cadrage P3 inchangé")


func test_landscape_is_never_walkable_and_keeps_the_play_area() -> void:
	var w = World25.load_world(World25.SPEC)
	var before: Array = []
	for r in w.regions:
		before.append([r["id"], r["rect"], r["h"]])
	var cfg := Paysage.config_for(World25.SPEC)
	check(not cfg.is_empty(), "paysage décrit pour la scène témoin")
	w.extend_view(Paysage.view_points(cfg))
	var after: Array = []
	for r in w.regions:
		after.append([r["id"], r["rect"], r["h"]])
	check(before == after, "régions praticables identiques avec le paysage")
	var pb = Paysage.new()
	pb.cfg = cfg
	pb.world = w
	var above := 0
	for reg in w.regions:
		var r: Rect2 = reg["rect"]
		var x := r.position.x
		while x <= r.end.x:
			var y := r.position.y
			while y <= r.end.y:
				if pb.height(x, y) > -0.02:
					above += 1
				y += 0.5
			x += 0.5
	check_eq(above, 0, "le relief passe toujours sous les sols praticables")
	for p in [Vector2(10, -5), Vector2(-20, 10), Vector2(40, 0), Vector2(20, 40), Vector2(12, -24)]:
		check(w.surfaces_under(p).is_empty(), "paysage non praticable en %s" % str(p))


func test_extended_frame_shows_landscape_but_never_void() -> void:
	for deg in [35.0, 28.0]:
		_with_pitch(deg)
		for file in [World25.SPEC, "res://data/explore25/instance_2_fictive.json"]:
			var w = World25.load_world(file)
			var cfg := Paysage.config_for(file)
			var b0: Rect2 = w.camera_bounds()
			w.extend_view(Paysage.view_points(cfg))
			var b1: Rect2 = w.camera_bounds()
			check(b1.position.y < b0.position.y, "%s à %d° : le cadre peut monter vers le paysage" % [file.get_file(), int(deg)])
			var bad := 0
			for zi in 3:
				for frac in [0.0, 0.1]:
					var c = Cam25.new()
					c.bounds = b1
					c.aim_frac = frac
					c.set_index(zi, false)
					for reg in w.regions:
						var r: Rect2 = reg["rect"]
						for q in [r.position + Vector2(0.4, 0.4), r.end - Vector2(0.4, 0.4), r.get_center()]:
							c.snap_to(World25.screen(Vector3(q.x, q.y, w.region_h(reg, q))))
							if not w.view_inside_decor(c.view_rect()):
								bad += 1
			check_eq(bad, 0, "%s à %d° : aucune vue hors du décor (3 zooms, centré et décentré)" % [file.get_file(), int(deg)])
			var t: Array = cfg["terrain"]["rect"]
			check(Rect2(t[0], t[1], t[2] - t[0], t[3] - t[1]).encloses(w.decor), "%s à %d° : le relief couvre tout le décor visible" % [file.get_file(), int(deg)])
	_reset()


func test_variant_scenes_exist_and_f5_is_unchanged() -> void:
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/explore_hd2d/zone_exploration.tscn", "F5 inchangé")
	for v in ["A", "B", "C"]:
		var p := "res://scenes/explore25/camera_variante_%s.tscn" % v
		check(load(p) is PackedScene, "%s se charge" % p.get_file())
	check(load("res://scenes/explore25/scene_temoin.tscn") is PackedScene, "scène témoin P3 intacte")
