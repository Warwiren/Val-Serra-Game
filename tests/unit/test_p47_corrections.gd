extends "res://tests/test_case.gd"
## P4.7 — taille d'Aren comparable à Ilya ; Ilya en combat depuis la planche du créateur (trois-quarts comme Aren,
## pistolet d'Aether) ; attente et marche d'Ilya ; Vorgane d'exploration posé au sol ; F5.

const P45 := "res://art/p45/"


func _img(p: String) -> Image:
	return (load(p) as Texture2D).get_image()


func _area(img: Image) -> int:
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				n += 1
	return n


func test_aren_is_not_bigger_than_ilya() -> void:
	for d in ["face", "right"]:
		var a := _img(P45 + "chars/aren/idle_%s.png" % d)
		var i := _img(P45 + "chars/ilya/idle_%s.png" % d)
		var ratio := float(_area(a)) / _area(i)
		check(ratio <= 1.15, "%s : silhouette d'Aren / Ilya = %.2f (P4.6 : 1,28 de face)" % [d, ratio])
		check(a.get_used_rect().size.y <= i.get_used_rect().size.y + 1, "%s : Aren pas plus grand qu'Ilya (%d / %d px)" % [d, a.get_used_rect().size.y, i.get_used_rect().size.y])
	var src: String = FileAccess.open("res://scenes/p4/avant_poste.gd", FileAccess.READ).get_as_text()
	check(src.contains("\"k\": 25.2 / 63.0"), "Aren : 1 px de sprite = 1 px d'écran à ×2,5 (63 px)")


func test_ilya_combat_faces_like_aren_with_pistol() -> void:
	var seqs: Dictionary = JSON.parse_string(FileAccess.open(P45 + "combat/ilya/sequences.json", FileAccess.READ).get_as_text())
	for s in [["idle", 8], ["draw", 5], ["fire", 7], ["charged_shot", 8], ["guard", 4], ["hit", 4], ["ko", 6]]:
		check_eq(int(seqs[s[0]]["count"]), s[1], "Ilya : %s (%d images)" % s)
	# visée : le pistolet (lumière d'Aether cyan) est à droite de la tête, comme l'épée d'Aren vise la droite
	var aim := _img(P45 + "combat/ilya/draw_4.png")
	var r := aim.get_used_rect()
	var tip: Array = seqs["muzzle_px"]
	check(int(tip[0]) > r.position.x + r.size.x * 0.7, "Ilya vise vers la droite (bout du pistolet x=%d)" % int(tip[0]))
	var cyan := 0
	for y in range(int(tip[1]) - 3, int(tip[1]) + 4):
		for x in range(int(tip[0]) - 10, int(tip[0]) + 1):
			var c := aim.get_pixel(x, y)
			if c.a > 0.5 and c.b > 0.55 and c.g > 0.55 and c.r < c.g - 0.1:
				cyan += 1
	check(cyan >= 2, "pistolet d'Aether visible au bout du bras (%d px cyan)" % cyan)
	var v: String = FileAccess.open("res://src/proto/pack_hunter_view.gd", FileAccess.READ).get_as_text()
	check(v.contains("const MUZZLE := Vector2(%d, %d)" % [2 * (int(tip[0]) - 80) - 14, 2 * (int(tip[1]) - 98) - 2]), "trait d'Aether : part du bout du pistolet")
	var distinct := {}
	for i in 8:
		distinct[_img(P45 + "combat/ilya/idle_%d.png" % i).get_data()] = true
	check(distinct.size() >= 6, "attente vivante : %d images distinctes sur 8" % distinct.size())
	var lying := _img(P45 + "combat/ilya/ko_5.png").get_used_rect()
	check(lying.size.x > lying.size.y * 2, "K.O. : allongée au sol (%d × %d px)" % [lying.size.x, lying.size.y])


func test_ilya_exploration_idle_and_walk() -> void:
	for d in ["face", "back", "left", "right"]:
		var distinct := {}
		for i in 8:
			distinct[_img(P45 + "chars/ilya/idle_%s%s.png" % [d, "" if i == 0 else "_%d" % i]).get_data()] = true
		check(distinct.size() >= 6, "Ilya %s : attente vivante (%d images distinctes)" % [d, distinct.size()])
		var tops := {}
		for i in 4:
			tops[_img(P45 + "chars/ilya/walk_%s_%d.png" % [d, i]).get_used_rect().position.y] = true
		check(tops.size() >= 2, "Ilya %s : la marche a un appui (le haut du corps descend aux pas)" % d)


func test_vorgane_exploration_grounded() -> void:
	var bottoms := {}
	for i in 24:
		var p := P45 + "chars/vorgane/idle_%d.png" % i
		check(ResourceLoader.exists(p), "Vorgane : image %d" % i)
		bottoms[_img(p).get_used_rect().end.y] = true
	check_eq(bottoms.size(), 1, "Vorgane : pattes sur la même ligne à chaque image")
	var img := _img(P45 + "chars/vorgane/idle_0.png")
	check_eq(img.get_used_rect().end.y, img.get_height() - 1 + 1, "Vorgane : pattes au bas de l'image (posé au sol de la scène)")
	var src: String = FileAccess.open("res://scenes/p4/avant_poste.gd", FileAccess.READ).get_as_text()
	check(src.contains("res://art/p45/chars/vorgane/") and src.contains("_blob(foot, w * 1.15, 0.6)"), "Vorgane : nouvelles images et ombre de contact")
	check(not DirAccess.dir_exists_absolute("res://art/p41/chars/vorgane"), "ancien Vorgane de profil retiré")
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/p4/avant_poste.tscn", "F5 : démo de l'avant-poste")
