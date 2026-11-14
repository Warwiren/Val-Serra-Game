extends "res://tests/test_case.gd"
## P4.5 — garde en armure, attente animée et marche des trois personnages, combat d'Aren non rogné, attente et tir
## d'Ilya retravaillés, netteté (1 px de sprite = 1 px d'écran à ×2,5), caméra P30, PV de démo, F5.

const World25 = preload("res://src/explore25/world25.gd")
const Actor25 = preload("res://src/explore25/actor25.gd")
const Portraits = preload("res://src/proto/portraits.gd")
const P45 := "res://art/p45/"


func _img(p: String) -> Image:
	return (load(p) as Texture2D).get_image()


func _rect(p: String) -> Rect2i:
	return _img(p).get_used_rect()


func test_three_characters_have_idle_and_walk_in_four_directions() -> void:
	for who in ["aren", "ilya", "garde"]:
		for d in ["face", "back", "left", "right"]:
			check(ResourceLoader.exists(P45 + "chars/%s/idle_%s.png" % [who, d]), "%s : attente %s" % [who, d])
			for i in range(1, 8):
				check(ResourceLoader.exists(P45 + "chars/%s/idle_%s_%d.png" % [who, d, i]), "%s : attente %s image %d" % [who, d, i])
			for i in 4:
				check(ResourceLoader.exists(P45 + "chars/%s/walk_%s_%d.png" % [who, d, i]), "%s : marche %s %d" % [who, d, i])


func test_feet_stay_on_one_line_and_head_does_not_jump() -> void:
	for who in ["aren", "ilya", "garde"]:
		for d in ["face", "back", "left", "right"]:
			var bottoms := {}
			var heads: Array = []
			var names := ["idle_%s" % d] + range(1, 8).map(func(i): return "idle_%s_%d" % [d, i]) + range(4).map(func(i): return "walk_%s_%d" % [d, i])
			for f in names:
				var img := _img(P45 + "chars/%s/%s.png" % [who, f])
				var r := img.get_used_rect()
				bottoms[r.end.y] = true
				if f.begins_with("walk"):
					var xs: Array = []
					for x in img.get_width():
						for y in range(r.position.y, r.position.y + 6):
							if img.get_pixel(x, y).a > 0.5:
								xs.append(x)
								break
					heads.append((xs.min() + xs.max()) / 2.0)
			check_eq(bottoms.size(), 1, "%s %s : pieds sur la même ligne (attente et marche)" % [who, d])
			check(heads.max() - heads.min() <= 3.0, "%s %s : tête stable pendant la marche (écart %.1f px)" % [who, d, heads.max() - heads.min()])


func test_idle_is_a_real_cycle_not_identical_frames() -> void:
	for who in ["aren", "ilya", "garde"]:
		var a := _img(P45 + "chars/%s/idle_face.png" % who)
		var b := _img(P45 + "chars/%s/idle_face_2.png" % who)
		var c := _img(P45 + "chars/%s/idle_face_5.png" % who)
		check(a.get_data() != b.get_data(), "%s : respiration (image 2 différente du repos)" % who)
		check(b.get_data() != c.get_data(), "%s : transfert du poids (image 5 différente)" % who)
		check_eq(_rect(P45 + "chars/%s/idle_face_2.png" % who).end.y, _rect(P45 + "chars/%s/idle_face.png" % who).end.y, "%s : pieds immobiles pendant l'attente" % who)
	var src: String = FileAccess.open("res://src/explore25/actor25.gd", FileAccess.READ).get_as_text()
	check(src.contains("IDLE_FPS") and src.contains("const STRIDE_M := 0.42"), "attente animée et cadence de marche liée à la distance")


func test_one_sprite_pixel_per_screen_pixel_at_default_zoom() -> void:
	var src: String = FileAccess.open("res://scenes/p4/avant_poste.gd", FileAccess.READ).get_as_text()
	for pair in [["aren", 63, "25.2 / 63.0"], ["ilya", 65, "26.0 / 65.0"], ["garde", 75, "30.0 / 75.0"]]:
		var h := _rect(P45 + "chars/%s/walk_face_1.png" % pair[0]).size.y
		check(absi(h - int(pair[1])) <= 3, "%s : %d px de haut (cible %d)" % [pair[0], h, pair[1]])
		check(src.contains(pair[2]), "%s : k = %s (1 px = 1 px d'écran à ×2,5)" % [pair[0], pair[2]])
	check(src.contains("res://art/p45/chars/garde/"), "garde : sprites du pack en armure")
	check(not ResourceLoader.exists("res://art/proto/pnj.png"), "ancien garde au béret retiré")


func test_guard_patrols_and_returns_to_post() -> void:
	var src: String = FileAccess.open("res://scenes/p4/avant_poste.gd", FileAccess.READ).get_as_text()
	check(src.contains("func _guard_step(") and src.contains("GUARD_ROUND"), "garde : ronde en 4 directions")
	check(Portraits.path("pnj").contains("p45/portraits/garde"), "portrait du garde en armure")


func test_aren_combat_frames_are_never_clipped() -> void:
	for seq in [["repos", 4], ["avance", 6], ["preparation", 5], ["attaque", 6], ["impact", 4], ["retour", 5], ["garde", 4], ["touche", 4], ["res_charge", 6], ["res_liberation", 6]]:
		for i in seq[1]:
			var p := P45 + "combat/aren/%s_%d.png" % [seq[0], i]
			check(ResourceLoader.exists(p), "Aren : %s_%d" % [seq[0], i])
			var img := _img(p)
			var r := img.get_used_rect()
			check(r.position.x > 0 and r.position.y > 0 and r.end.x < img.get_width(), "Aren %s_%d : marge autour du sprite (rien de coupé)" % [seq[0], i])
	check_eq(_rect(P45 + "combat/aren/attaque_3.png").end.y, _rect(P45 + "combat/aren/repos_0.png").end.y, "Aren : pieds au même niveau (attaque / repos)")


func test_ilya_idle_and_shot_are_reworked() -> void:
	var seqs: Dictionary = JSON.parse_string(FileAccess.open(P45 + "combat/ilya/sequences.json", FileAccess.READ).get_as_text())
	check_eq(int(seqs["idle"]["count"]), 8, "Ilya : attente de 8 images")
	check_eq(int(seqs["fire"]["count"]), 7, "Ilya : tir de 7 images")
	var frames: Array = []
	for i in 8:
		frames.append(_img(P45 + "combat/ilya/idle_%d.png" % i).get_data())
	var distinct := {}
	for f in frames:
		distinct[f] = true
	check(distinct.size() >= 6, "Ilya : attente non figée (%d images distinctes sur 8)" % distinct.size())
	check(_img(P45 + "combat/ilya/fire_3.png").get_data() != _img(P45 + "combat/ilya/fire_2.png").get_data(), "Ilya : recul après le tir")
	var ko_bottoms := {}
	for i in 6:
		ko_bottoms[_rect(P45 + "combat/ilya/ko_%d.png" % i).end.y] = true
	check_eq(ko_bottoms.size(), 1, "Ilya : K.O. reposé au sol à chaque image")
	var v: String = FileAccess.open("res://src/proto/pack_hunter_view.gd", FileAccess.READ).get_as_text()
	check(v.contains("res://art/p45/combat/") and v.contains("func _shoot("), "combat : sprites P4.5, Ilya tire au pistolet")


func test_camera_p30_hp_and_f5() -> void:
	var src: String = FileAccess.open("res://scenes/p4/avant_poste.gd", FileAccess.READ).get_as_text()
	check(src.contains("var cam_mode := \"P30\"") and src.contains("\"tilt\": 0.3"), "caméra P30, flou réduit")
	check(src.contains("const DEMO_HP_MULT := 0.5"), "démo : PV du Vorgane ÷ 2")
	var data: Dictionary = JSON.parse_string(FileAccess.open("res://data/combat/monster_vorgane.json", FileAccess.READ).get_as_text())
	check_eq(int(data["hp"]), 950, "données du Vorgane inchangées")
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/p4/avant_poste.tscn", "F5 : démo de l'avant-poste")
	for d in ["res://art/p44", "res://art/p41/chars/pnj"]:
		check(not DirAccess.dir_exists_absolute(d), "remplacé et retiré : " + d)
	var w = World25.load_world("res://data/p4/avant_poste.json", "instance")
	check(not w.npc.is_empty(), "le garde est présent")
