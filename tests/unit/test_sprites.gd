extends "res://tests/test_case.gd"
## Contrôle des sprites HD-2D : cadres de taille constante (ancrage stable), toutes les images de chaque
## animation présentes dans chaque calque du Vorgane, ancrages de ciblage disponibles pour chaque image.

const MON := preload("res://src/presentation/sprite_monster_view.gd")


func _size(path: String) -> Vector2i:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	return Vector2i(img.get_width(), img.get_height()) if img != null else Vector2i.ZERO


func test_aren_frames_share_one_frame_size() -> void:
	var files := ["idle_0", "idle_1", "idle_2", "idle_3", "guard_0", "guard_1", "guard_2", "guard_3",
		"pose_attaque", "pose_avance", "pose_garde", "pose_repos", "pose_touche"]
	for f in files:
		var p := "res://art/sprites/aren/%s.png" % f
		check(FileAccess.file_exists(p), "image %s présente" % f)
		check_eq(_size(p), Vector2i(140, 84), "%s : cadre commun 140×84" % f)


func test_vorgane_layers_complete_and_aligned() -> void:
	var anchors: Dictionary = JSON.parse_string(FileAccess.open("res://art/sprites/vorgane/anchors.json", FileAccess.READ).get_as_text())["images"]
	for layer in ["base", "carapace", "carapace_broken", "griffe", "griffe_broken", "glande"]:
		for anim in MON.ANIMS:
			for fr in MON.ANIMS[anim]["frames"]:
				var key := "%s_%03d" % [anim, fr]
				var p := "res://art/sprites/vorgane/%s/%s.png" % [layer, key]
				check(FileAccess.file_exists(p), "%s/%s présent" % [layer, key])
				check_eq(_size(p), Vector2i(256, 256), "%s/%s : cadrage constant 256×256" % [layer, key])
				if layer == "base":
					check(anchors.has(key) and anchors[key].has("glande") and anchors[key].has("griffe") and anchors[key].has("carapace"),
						"%s : ancrages de ciblage" % key)
