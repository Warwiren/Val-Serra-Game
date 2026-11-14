extends "res://tests/test_case.gd"
## P4.8 — marche d'Aren et d'Ilya : 8 images (contact / bas / passage / haut), haut du corps stabilisé, cadence
## calée sur le pas dessiné (pieds sans glissement), marche à 2,2 m/s et course (Maj) à 3,6 m/s.

const Actor25 = preload("res://src/explore25/actor25.gd")
const P45 := "res://art/p45/chars/"


func _img(p: String) -> Image:
	return (load(p) as Texture2D).get_image()


func test_eight_frame_walk_for_aren_and_ilya() -> void:
	for who in ["aren", "ilya"]:
		for d in ["face", "back", "left", "right"]:
			for i in 8:
				check(ResourceLoader.exists(P45 + "%s/walk_%s_%d.png" % [who, d, i]), "%s : marche %s image %d" % [who, d, i])
			var tops := {}
			for i in 8:
				tops[_img(P45 + "%s/walk_%s_%d.png" % [who, d, i]).get_used_rect().position.y] = true
			check(tops.size() >= 3, "%s %s : le corps monte et descend (contact / bas / passage / haut)" % [who, d])
		var m: Dictionary = JSON.parse_string(FileAccess.open(P45 + "%s/marche.json" % who, FileAccess.READ).get_as_text())
		check_eq(int(m["walk_frames"]), 8, "%s : 8 images par cycle" % who)
		check(float(m["step_px"]) > 15.0, "%s : pas dessiné mesuré (%.1f px)" % [who, float(m["step_px"])])


func test_upper_body_is_stable_while_walking() -> void:
	# même tête, même buste d'une image à l'autre (aux décalages d'appui près) : plus de « bouillonnement »
	for who in ["aren", "ilya"]:
		for d in ["right", "face"]:
			var a := _img(P45 + "%s/walk_%s_0.png" % [who, d])
			var b := _img(P45 + "%s/walk_%s_4.png" % [who, d])
			var r := a.get_used_rect()
			var diff := 0
			var n := 0
			for y in range(r.position.y + 2, r.position.y + int(r.size.y * 0.4)):
				for x in range(r.position.x, r.end.x):
					n += 1
					var best := 9.0
					for dy in [-1, 0, 1]:
						var ca := a.get_pixel(x, y)
						var cb := b.get_pixel(x, y + dy)
						best = minf(best, absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) + absf(ca.a - cb.a))
					if best > 0.05:
						diff += 1
			check(float(diff) / n < 0.08, "%s %s : haut du corps identique entre deux pas (%.0f %% de pixels différents)" % [who, d, 100.0 * diff / n])


func test_cadence_matches_drawn_step() -> void:
	var a = Actor25.make("aren")
	a.set_scale_k(25.2 / 63.0)
	var m: Dictionary = JSON.parse_string(FileAccess.open(P45 + "aren/marche.json", FileAccess.READ).get_as_text())
	var expect := float(m["step_px"]) * 0.4 / 20.0 * 2.0 / 8.0
	check(absf(a.stride_m - expect) < 0.001, "Aren : %.3f m par image = pas dessiné (%.3f)" % [a.stride_m, expect])
	var g = Actor25.make("garde")
	check_eq(g.frames.get_frame_count("walk_face"), 4, "garde : marche à 4 images inchangée")
	var src: String = FileAccess.open("res://scenes/explore25/explore_3d.gd", FileAccess.READ).get_as_text()
	check(src.contains("KEY_SHIFT") and src.contains("world.run_speed"), "Maj : course")
	var w = load("res://src/explore25/world25.gd").load_world("res://data/p4/avant_poste.json", "instance")
	var steps_per_s: float = w.speed / (float(m["step_px"]) * 0.4 / 20.0)
	check(steps_per_s > 3.5 and steps_per_s < 5.5, "marche : %.1f pas/s (petits pas vifs, pieds posés)" % steps_per_s)
