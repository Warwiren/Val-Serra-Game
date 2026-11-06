extends "res://tests/test_case.gd"
## Décor de combat en plans (pilote « Lisière de l'avant-poste ») : cohérence des fichiers produits par tools/arena/.

const DIR := "res://art/arena/lisiere/"


func _img(n: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(DIR + n + ".png"))


func test_arena_layers_share_size_and_cover_the_screen() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.open(DIR + "arena.json", FileAccess.READ).get_as_text())
	var size := Vector2i(data["native"][0], data["native"][1])
	check(size.x * 3 >= 1280 and size.y * 3 >= 720, "×3, le décor couvre tout l'écran 1280×720")
	for n in ["base", "loin", "lisiere", "avant"]:
		var im := _img(n)
		check(im != null and im.get_size() == size, "plan %s : taille native commune" % n)
	var base := _img("base")
	var opaque := true
	for y in range(0, size.y, 7):
		for x in range(0, size.x, 7):
			opaque = opaque and base.get_pixel(x, y).a > 0.99
	check(opaque, "plan de base entièrement opaque (aucun trou derrière les plans mobiles)")


func test_arena_lights_match_painted_lanterns() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.open(DIR + "arena.json", FileAccess.READ).get_as_text())
	var lis := _img("lisiere")
	check(data["lights"].size() >= 2, "au moins deux lanternes")
	for p in data["lights"]:
		var q := Vector2i(roundi(p[0]), roundi(p[1]))
		var warm := false
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var c := lis.get_pixel(clampi(q.x + dx, 0, lis.get_width() - 1), clampi(q.y + dy, 0, lis.get_height() - 1))
				warm = warm or (c.a > 0.5 and c.r > 0.85 and c.r >= c.b and c.r > c.g * 0.98)
		check(warm, "lumière Godot posée sur une lanterne peinte (%s)" % str(q))


func test_arena_palette_is_limited() -> void:
	var colors := {}
	for n in ["base", "loin", "lisiere", "avant"]:
		var im := _img(n)
		for y in range(0, im.get_height(), 2):
			for x in range(0, im.get_width(), 2):
				var c := im.get_pixel(x, y)
				if c.a > 0.5:
					colors[c.to_rgba32()] = true
	check(colors.size() <= 72, "palette limitée et commune à l'exploration (%d couleurs, contours compris)" % colors.size())
