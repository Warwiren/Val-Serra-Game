extends "res://tests/test_case.gd"
## Exploration HD-2D : règles d'interaction (une seule règle pour joueur, démo et tests).

const Zone = preload("res://scenes/explore_hd2d/zone_hd2d.gd")


func test_cannot_talk_from_far_can_talk_when_close() -> void:
	var npc := Vector2(448, 170)
	check(not Zone.can_talk(npc + Vector2(-80, -40), npc), "derrière la maison (≈ 90 px) : pas de dialogue")
	check(not Zone.can_talk(npc + Vector2(-20, 0), npc), "à 20 px : pas encore de dialogue")
	check(Zone.can_talk(npc + Vector2(-10, 4), npc), "à ≈ 11 px : dialogue possible")


func test_monster_contact_matches_visual_proximity() -> void:
	var m := Vector2(148, 298)
	check(not Zone.touches_monster(m + Vector2(60, 0), m, 22.0, 8.0), "à 60 px du monstre : pas de combat")
	check(not Zone.touches_monster(m + Vector2(0, -25), m, 22.0, 8.0), "25 px derrière lui : pas de combat")
	check(Zone.touches_monster(m + Vector2(24, 2), m, 22.0, 8.0), "contre son flanc : combat")


func test_zone_layers_are_not_duplicated() -> void:
	var fond := Image.load_from_file(ProjectSettings.globalize_path("res://art/explore_hd2d/fond.png"))
	var house := Image.load_from_file(ProjectSettings.globalize_path("res://art/explore_hd2d/el_maison.png"))
	var zone: Dictionary = JSON.parse_string(FileAccess.open("res://art/explore_hd2d/zone.json", FileAccess.READ).get_as_text())
	var pos: Array = zone["sprites"]["maison"]["pos"]
	# là où la maison est opaque, le fond ne doit pas contenir la maison (pixels différents dans la grande majorité)
	var same := 0
	var total := 0
	for y in range(0, house.get_height(), 3):
		for x in range(0, house.get_width(), 3):
			var c := house.get_pixel(x, y)
			if c.a > 0.5:
				total += 1
				if fond.get_pixel(x + int(pos[0]), y + int(pos[1])).is_equal_approx(c):
					same += 1
	check(total > 0 and float(same) / total < 0.2, "fond sans la maison (%d / %d pixels identiques)" % [same, total])
