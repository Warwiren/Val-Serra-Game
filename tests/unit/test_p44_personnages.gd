extends "res://tests/test_case.gd"
## P4.4 — personnages (Aren gris, Ilya verte au pistolet d'Aether, garde), cohérence exploration / combat / portraits,
## netteté (réduction des sources, jamais d'agrandissement filtré), caméra P30 par défaut, PV de démo, nettoyage.

const World25 = preload("res://src/explore25/world25.gd")
const Portraits = preload("res://src/proto/portraits.gd")
const P44 := "res://art/p44/"


func _img(p: String) -> Image:
	return (load(p) as Texture2D).get_image()


func _height(p: String) -> int:
	return _img(p).get_used_rect().size.y


func _count(img: Image, pred: Callable, y0 := 0, y1 := -1) -> int:
	var n := 0
	var r := img.get_used_rect()
	for y in range(r.position.y if y0 == 0 else y0, r.end.y if y1 < 0 else y1):
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and pred.call(c):
				n += 1
	return n


func test_exploration_sets_are_complete_with_feet_on_one_line() -> void:
	for who in ["aren", "ilya"]:
		var bottoms := {}
		for d in ["face", "back", "left", "right"]:
			for f in ["idle_%s" % d, "idle_%s_1" % d, "walk_%s_0" % d, "walk_%s_1" % d, "walk_%s_2" % d, "walk_%s_3" % d]:
				var p := P44 + "chars/%s/%s.png" % [who, f]
				check(ResourceLoader.exists(p), "%s : %s" % [who, f])
				var r := _img(p).get_used_rect()
				bottoms[r.end.y] = true
		check(bottoms.size() <= 2, "%s : pieds sur la même ligne dans les 24 images (%s)" % [who, str(bottoms.keys())])
	var ha := _height(P44 + "chars/aren/walk_face_1.png")
	check(ha >= 52 and ha <= 60, "Aren ≈ 56 px de jeu (%d)" % ha)
	var src: String = FileAccess.open("res://scenes/p4/avant_poste.gd", FileAccess.READ).get_as_text()
	check(src.contains("res://art/p44/chars/aren/") and src.contains("res://art/p44/chars/ilya/"), "exploration : sprites P4.4")
	check(src.contains("\"k\": 28.0 / 56.0"), "taille d'Aren à l'écran conservée (28 px natifs)")


func test_designs_aren_gray_ilya_green_silver() -> void:
	var aren := _img(P44 + "chars/aren/idle_face.png")
	var ilya := _img(P44 + "chars/ilya/idle_face.png")
	var blue := _count(aren, func(c): return c.b > c.r * 1.35 and c.b > c.g * 1.2 and c.s > 0.35)
	var brown := _count(aren, func(c): return c.h < 0.12 and c.s > 0.35, 0, aren.get_used_rect().position.y + 12)
	check(blue <= 8, "Aren : plus de tissu bleu (%d px bleus saturés)" % blue)
	check(brown >= 25, "Aren : cheveux bruns (%d px)" % brown)
	var silver := _count(ilya, func(c): return c.s < 0.22 and c.v > 0.55, 0, ilya.get_used_rect().position.y + 10)
	var green := _count(ilya, func(c): return c.g > c.r * 1.05 and c.g > c.b * 1.1)
	check(silver >= 20, "Ilya : cheveux argentés (%d px)" % silver)
	check(green >= 15, "Ilya : tenue verte (%d px)" % green)


func test_ilya_combat_is_the_aether_pistol_pack() -> void:
	var seqs: Dictionary = JSON.parse_string(FileAccess.open(P44 + "combat/ilya/sequences.json", FileAccess.READ).get_as_text())
	for s in {"idle": 4, "draw": 5, "fire": 7, "charged_shot": 8, "guard": 4, "hit": 4, "ko": 6}.keys():
		check(seqs.has(s), "séquence %s" % s)
		for i in seqs[s]["count"]:
			check(ResourceLoader.exists(P44 + "combat/ilya/%s_%d.png" % [s, i]), "%s_%d" % [s, i])
	# l'arme est un pistolet : le vert de l'Aether est au bout du bras tendu (à droite des pieds) au tir
	var fire := _img(P44 + "combat/ilya/fire_2.png")
	var right := _count(fire, func(c): return c.g > 0.6 and c.g > c.r + 0.2)
	check(right >= 3, "tir : éclair vert d'Aether visible (%d px)" % right)
	var v: String = FileAccess.open("res://src/proto/pack_hunter_view.gd", FileAccess.READ).get_as_text()
	check(v.contains("func _shoot(") and v.contains("ranged = true"), "Ilya tire à distance (pas d'attaque au contact)")
	check(v.contains("\"strike\": [\"fire\", [0, 1, 2, 4, 5, 6]"), "image de tir incohérente (fire_3) écartée")
	var b: String = FileAccess.open("res://scenes/battle/battle_scene.gd", FileAccess.READ).get_as_text()
	check(b.contains("Pistolet d'Aether"), "combat : arme affichée « Pistolet d'Aether »")


func test_aren_combat_and_portraits_are_p44() -> void:
	for f in ["repos_0", "avance_5", "preparation_4", "attaque_5", "impact_0", "retour_4", "garde_3", "touche_3", "res_charge_5", "res_liberation_5"]:
		check(ResourceLoader.exists(P44 + "combat/aren/%s.png" % f), "combat Aren : " + f)
	var h := _height(P44 + "combat/aren/repos_0.png")
	check(h >= 50 and h <= 60, "combat Aren ≈ 56 px affichés ×2 (%d)" % h)
	for id in ["heros", "compagnon_vif", "pnj"]:
		check(Portraits.path(id).begins_with(P44 + "portraits/"), "portrait P4.4 : " + id)
		check(ResourceLoader.exists(Portraits.path(id)), "portrait présent : " + id)
	for e in ["determine", "souriant", "surpris", "blesse", "concentre"]:
		check(ResourceLoader.exists(Portraits.path("compagnon_vif", e)), "Ilya : expression " + e)


func test_portraits_are_never_enlarged() -> void:
	for who in ["aren", "ilya", "garde"]:
		var p := P44 + "portraits/%s/neutre.png" % who
		var s := _img(p).get_size()
		check(s.x <= 160 and s.y <= 160, "%s : portrait réduit à 160 px au plus (%s)" % [who, str(s)])


func test_camera_p30_default_with_light_blur_and_b28_comparison() -> void:
	var src: String = FileAccess.open("res://scenes/p4/avant_poste.gd", FileAccess.READ).get_as_text()
	check(src.contains("var cam_mode := \"P30\""), "caméra par défaut : P30")
	check(src.contains("\"tilt\": 0.3"), "flou de distance réduit (0,3)")
	check(src.contains("\"B28\": {"), "B28 disponible en comparaison")
	check(ResourceLoader.exists("res://scenes/p4/comparaison_camera_B28.tscn"), "scène F6 de comparaison B28")
	var sh: String = FileAccess.open("res://src/p4/tilt_shift_p41.gdshader", FileAccess.READ).get_as_text()
	check(sh.contains("uniform float strength"), "intensité du flou réglable")


func test_demo_hp_halved_only_for_this_encounter() -> void:
	var p4: String = FileAccess.open("res://scenes/p4/avant_poste.gd", FileAccess.READ).get_as_text()
	check(p4.contains("const DEMO_HP_MULT := 0.5"), "démo : PV divisés par deux")
	var data: Dictionary = JSON.parse_string(FileAccess.open("res://data/combat/monster_vorgane.json", FileAccess.READ).get_as_text())
	check_eq(int(data["hp"]), 950, "données du Vorgane inchangées")


func test_cleanup_left_no_obsolete_folder() -> void:
	for d in ["res://art/explore_hd2d", "res://art/source", "res://art/proto/aren2", "res://art/p41/combat", "res://scenes/explore_hd2d",
		"res://scenes/proto", "res://docs/media/p1_camera", "res://tools/art"]:
		check(not DirAccess.dir_exists_absolute(d), "retiré du projet actif : " + d)
	var w = World25.load_world("res://data/p4/avant_poste.json", "instance")
	check(not w.stand(Vector2(36, 6.35), 0.0).is_empty(), "plaine : pied de falaise praticable")
