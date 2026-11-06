extends "res://tests/test_case.gd"
## Arène de combat illustrée « Lisière de l'avant-poste » : cohérence de l'illustration et des lanternes.

const DIR := "res://art/arena/lisiere/"


func _img(n: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(DIR + n + ".png"))


func test_illustrated_arena_keeps_screen_size_and_lights_on_lanterns() -> void:
	check(FileAccess.file_exists(DIR + "peint/hd.json"), "arène illustrée présente (seule version active)")
	var hd: Dictionary = JSON.parse_string(FileAccess.open(DIR + "peint/hd.json", FileAccess.READ).get_as_text())
	var im := Image.load_from_file(ProjectSettings.globalize_path(DIR + "peint/" + hd["image"]))
	check(im.get_width() == 1296 and im.get_height() == 732, "illustration à la taille de l'écran (pas plus grande : %s)" % str(im.get_size()))
	for p in hd["lumieres"]:
		var best := 0.0
		for dy in range(-4, 5):
			for dx in range(-4, 5):
				var c := im.get_pixel(clampi(int(p[0]) + dx, 0, im.get_width() - 1), clampi(int(p[1]) + dy, 0, im.get_height() - 1))
				best = maxf(best, c.r + c.g - c.b)
		check(best > 1.1, "lumière posée sur une lanterne peinte %s" % str(p))
