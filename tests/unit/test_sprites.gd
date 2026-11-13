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


## Personnages du combat de démonstration : Throné vient encore du pack ; le décor de repli et
## les images « nuit » du Vorgane (combat de la démo) sont complets.
func test_proto_characters_share_one_scale() -> void:
	for k in ["throne"]:
		var p := "res://art/proto/%s.png" % k
		check(FileAccess.file_exists(p), "%s présent" % k)
		check_eq(_size(p), _size("res://art/proto/%s_1.png" % k), "%s : image de respiration de même taille" % k)
	check_eq(_size("res://art/proto/zone_bg.png"), Vector2i(427, 240), "décor natif 427×240 (×3 = 1280×720)")
	var anchors: Dictionary = JSON.parse_string(FileAccess.open("res://art/proto/vorgane_nuit_p1/anchors.json", FileAccess.READ).get_as_text())["images"]
	check(anchors.has("idle_001"), "ancrages du Vorgane de la démo présents")


func test_demo_vorgane_frames_complete() -> void:
	for layer in ["base", "carapace", "carapace_broken", "griffe", "griffe_broken", "glande"]:
		for anim in MON.ANIMS:
			for fr in MON.ANIMS[anim]["frames"]:
				var key := "%s_%03d" % [anim, fr]
				var p := "res://art/proto/vorgane_nuit_p1/%s/%s.png" % [layer, key]
				check(FileAccess.file_exists(p), "%s/%s présent (Vorgane de la démo)" % [layer, key])


## La charte d'interface est centralisée : aucun code couleur hexadécimal dans les scripts du HUD de combat.
func test_combat_ui_colors_are_centralized() -> void:
	for p in ["res://src/presentation/combat_hud.gd", "res://src/presentation/initiative_bar.gd"]:
		var src := FileAccess.open(p, FileAccess.READ).get_as_text()
		check(src.find("Color(\"#") < 0, "%s : pas de couleur codée en dur (utiliser UiStyle)" % p.get_file())
