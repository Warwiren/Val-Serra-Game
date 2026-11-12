extends "res://tests/test_case.gd"
## P4.1 — finitions de la démo : personnages nets et cohérents, raccords du décor, falaises, variantes caméra,
## PV du monstre de la démo. Tests sans rendu ; captures et parcours : docs/P4_1_FINITIONS.md.

const World25 = preload("res://src/explore25/world25.gd")
const Portraits = preload("res://src/proto/portraits.gd")
const P41 := "res://art/p41/"


func _img(p: String) -> Image:
	return (load(p) as Texture2D).get_image()


func _height(p: String) -> int:
	return _img(p).get_used_rect().size.y


func test_exploration_sprites_have_the_sheet_resolution_and_keep_the_screen_size() -> void:
	for d in ["face", "back", "left", "right"]:
		for f in ["idle_%s" % d, "walk_%s_0" % d, "walk_%s_3" % d]:
			check(ResourceLoader.exists(P41 + "chars/aren/%s.png" % f), "Aren : %s" % f)
			check(ResourceLoader.exists(P41 + "chars/ilya/%s.png" % f), "Ilya : %s" % f)
	var ha := _height(P41 + "chars/aren/idle_face.png")
	check(ha >= 54 and ha <= 60, "Aren debout ≈ 58 px (spécification), mesuré %d" % ha)
	check(ha >= 2 * _height("res://art/explore_hd2d/chars/aren/idle_face.png") - 2, "Aren : au moins deux fois plus de pixels qu'en P4")
	var scene_src: String = FileAccess.open("res://scenes/p4/avant_poste.gd", FileAccess.READ).get_as_text()
	check(scene_src.contains("\"k\": 28.0 / 57.0"), "taille d'Aren à l'écran conservée (28 px natifs P4)")
	check(scene_src.contains("PERSO_SH"), "personnages rendus par le shader « pixel net »")


func test_ilya_matches_the_canonical_design_and_is_not_aren() -> void:
	var ilya := _img(P41 + "chars/ilya/idle_face.png")
	var aren := _img(P41 + "chars/aren/idle_face.png")
	var silver := 0
	var navy := 0
	var brown_hair := 0
	var top := ilya.get_used_rect().position.y
	for y in ilya.get_height():
		for x in ilya.get_width():
			var c := ilya.get_pixel(x, y)
			if c.a < 0.5:
				continue
			if y < top + 10 and c.s < 0.25 and c.v > 0.55:
				silver += 1
			if c.b > c.r * 1.25 and c.b > c.g * 1.05 and c.v < 0.6:
				navy += 1
	var atop := aren.get_used_rect().position.y
	for y in range(atop, atop + 10):
		for x in aren.get_width():
			var c := aren.get_pixel(x, y)
			if c.a > 0.5 and c.h < 0.12 and c.s > 0.35:
				brown_hair += 1
	check(silver >= 25, "Ilya : cheveux argentés en haut de la silhouette (%d px)" % silver)
	check(navy >= 6, "Ilya : bleu nuit présent (%d px)" % navy)
	check(brown_hair >= 25, "Aren : cheveux bruns (%d px) — les deux personnages sont distincts" % brown_hair)
	check(Portraits.path("compagnon_vif").begins_with(P41 + "portraits/ilya/"), "portrait d'Ilya : planche canonique")
	check(ResourceLoader.exists(Portraits.path("compagnon_vif", "surpris")), "portrait d'Ilya : expressions")


func test_combat_uses_the_same_sharp_designs() -> void:
	for f in ["repos_0", "attaque_3", "garde_1", "impact_0", "res_charge_0", "res_liberation_5"]:
		check(ResourceLoader.exists(P41 + "combat/aren/%s.png" % f), "combat Aren : " + f)
	for f in ["idle", "idle_1", "prep", "strike", "follow", "guard", "hurt", "aether_prep", "aether_strike"]:
		check(ResourceLoader.exists(P41 + "combat/ilya/ilya_%s.png" % f), "combat Ilya : " + f)
	check(_height(P41 + "combat/aren/repos_0.png") * 2 >= _height("res://art/proto/aren2/repos_0.png") * 3 - 8, "combat : même taille à l'écran (×2 au lieu de ×3)")
	var v: String = FileAccess.open("res://src/proto/pack_hunter_view.gd", FileAccess.READ).get_as_text()
	check(v.contains("P41_COMBAT") and v.contains("tex_px = P41_PX"), "vue de combat : poses P4.1 affichées ×2 (entier : net)")
	# monstre : en exploration, les MÊMES images que le combat (calques composés), donc le même design
	var ex := _img(P41 + "chars/vorgane/idle_0.png")
	var cb := _img("res://art/proto/vorgane_nuit_p1/base/idle_001.png")
	check(absi(ex.get_used_rect().size.x - cb.get_used_rect().size.x) <= 6, "Vorgane d'exploration : silhouette du combat")


func test_demo_halves_monster_hp_only_for_this_encounter() -> void:
	var src: String = FileAccess.open("res://scenes/battle/battle_scene.gd", FileAccess.READ).get_as_text()
	check(src.contains("rencontre_pv_mult") and src.contains("GameState.flags.erase(\"rencontre_pv_mult\")"), "multiplicateur lu puis consommé (ce combat seulement)")
	var p4: String = FileAccess.open("res://scenes/p4/avant_poste.gd", FileAccess.READ).get_as_text()
	check(p4.contains("const DEMO_HP_MULT := 0.5"), "démo : PV divisés par deux")
	var data: Dictionary = JSON.parse_string(FileAccess.open("res://data/combat/monster_vorgane.json", FileAccess.READ).get_as_text())
	check_eq(int(data["hp"]), 950, "données du Vorgane inchangées (équilibrage global)")


func test_decor_cleanup_and_cliffs_keep_the_walkable_limits() -> void:
	for f in ["arb02_rond", "arb03_foret", "arb04_jeune", "arb05_fleuri", "arb01_tronc", "roc01_rocher", "lant01_lanterne"]:
		check(ResourceLoader.exists(P41 + "decor/%s.png" % f), "décor nettoyé : " + f)
	for i in 4:
		check(ResourceLoader.exists(P41 + "decor/touffe_sol_%d.png" % i), "touffe aux couleurs du sol %d" % i)
	# arbres : plus de plaque verte dans le bas de l'image
	var t := _img(P41 + "decor/arb02_rond.png")
	var r := t.get_used_rect()
	var green := 0
	for y in range(r.end.y - int(r.size.y * 0.12), r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := t.get_pixel(x, y)
			if c.a > 0.5 and c.g > c.r * 1.15 and c.g > c.b * 1.15:
				green += 1
	check(green < 40, "ARB-02 : plaque d'herbe retirée sous les racines (%d px verts restants)" % green)
	var w = World25.load_world("res://data/p4/avant_poste.json", "instance")
	check(not w.stand(Vector2(36, 6.35), 0.0).is_empty(), "plaine : le pied de la falaise reste praticable")
	check(w.stand(Vector2(36, 5.8), 0.0).is_empty(), "plaine : la falaise n'est pas praticable")


func test_camera_variants_are_comparisons_and_b28_stays_the_default() -> void:
	var src: String = FileAccess.open("res://scenes/p4/avant_poste.gd", FileAccess.READ).get_as_text()
	check(src.contains("var cam_mode := \"B28\""), "caméra par défaut : B28 (orthographique 28°, validée)")
	for k in ["\"B28\"", "\"P30\"", "\"P38\""]:
		check(src.contains(k + ": {"), "variante " + k)
	check(ResourceLoader.exists("res://scenes/p4/comparaison_camera_P30.tscn"), "scène F6 de comparaison P30")
	check(ResourceLoader.exists("res://scenes/p4/comparaison_camera_P38.tscn"), "scène F6 de comparaison P38")
