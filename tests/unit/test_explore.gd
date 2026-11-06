extends "res://tests/test_case.gd"
## Exploration HD-2D : règles d'interaction (une seule règle pour joueur, démo et tests).

const Zone = preload("res://scenes/explore_hd2d/zone_hd2d.gd")


func test_cannot_talk_from_far_can_talk_when_close() -> void:
	var npc := Vector2(448, 170)
	check(not Zone.can_talk(npc + Vector2(-80, -40), npc), "derrière la maison (≈ 90 px) : pas de dialogue")
	check(not Zone.can_talk(npc + Vector2(0, 30), npc), "30 px devant lui : pas encore de dialogue")
	check(not Zone.can_talk(npc + Vector2(-26, 4), npc), "26 px à côté : pas encore de dialogue")
	check(Zone.can_talk(npc + Vector2(-10, 4), npc), "à ≈ 11 px : dialogue possible")


## Approches naturelles (arrêt quand les deux personnages se touchent) mesurées en jeu au clavier
## (--course=pnj) : elles échouaient toutes avec l'ancien rayon de 14 px, sauf de face.
func test_talk_zone_accepts_natural_approaches() -> void:
	var npc := Vector2(448, 170)
	for c in [["gauche", Vector2(-14.8, 7.5)], ["droite", Vector2(13.9, 5.1)], ["bas", Vector2(0.4, 12.2)],
			["bas-gauche", Vector2(-7.0, 14.2)], ["bas-droite", Vector2(6.6, 13.5)], ["côte à côte", Vector2(-17, 2)]]:
		check(Zone.can_talk(npc + c[1], npc), "approche %s %s : dialogue possible" % [c[0], str(c[1])])
		check(c[1].length() >= 14.0 or c[0] == "bas", "(référence) l'ancien rayon de 14 px refusait l'approche %s" % c[0])


func test_cannot_talk_through_an_obstacle() -> void:
	var z = _zone_stub()
	z.npc = Zone.Walker.new("pnj", false)
	z.npc.position = Vector2(300, 250)
	z._npc_solid = z._circle(z.npc.position, 5.0)
	z.solids.append(z._npc_solid)
	z.hero.position = Vector2(282, 250)
	check(z.can_talk_now(), "à 18 px, rien entre eux : dialogue possible")
	z.solids.append(PackedVector2Array([Vector2(289, 240), Vector2(292, 240), Vector2(292, 260), Vector2(289, 260)]))
	check(not z.can_talk_now(), "même distance, une palissade entre eux : pas de dialogue")
	z.npc.free()
	_free_stub(z)


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


# --- Locomotion (P0) ------------------------------------------------------------------------------------------
## Zone minimale hors arbre de scène : praticable + emprise de la maison (collisions réelles de zone.json).
func _zone_stub():
	var z = Zone.new()
	var data: Dictionary = JSON.parse_string(FileAccess.open("res://art/explore_hd2d/zone.json", FileAccess.READ).get_as_text())
	for p in data["walkable"]:
		z.walkable.append(Vector2(p[0], p[1]))
	for g in data["sprites"]:
		var e: Dictionary = data["sprites"][g]
		if e["solid"] and e["footprint"].size() >= 3:
			z.solids.append(z._poly(e["footprint"]))
	z.hero = Zone.Walker.new("aren", true)
	return z


func _free_stub(z) -> void:
	z.hero.free()
	z.free()


func test_walk_frames_follow_real_distance() -> void:
	for fps in [30.0, 60.0, 144.0]:
		var w := Zone.Walker.new("aren", true)
		var travelled := 0.0
		while travelled < 12.0 - 0.001:                      # 12 px parcourus = 2 images de pas, quelle que soit la cadence
			w.animate(Vector2(72.0 / fps, 0), 1.0 / fps)
			travelled += 72.0 / fps
		check_eq(w.spr.frame, 2, "%d i/s : image de pas après 12 px" % fps)
		w.animate(Vector2.ZERO, 1.0 / fps)                    # blocage d'une image : pas de retour au repos
		check(String(w.spr.animation).begins_with("walk"), "%d i/s : un arrêt d'une image ne repasse pas au repos" % fps)
		for i in 20:
			w.animate(Vector2.ZERO, 1.0 / fps)
		check_eq(String(w.spr.animation), "idle_right", "%d i/s : repos après un vrai arrêt" % fps)
		w.free()
	var s := Zone.Walker.new("aren", true)
	for i in 10:
		s.animate(Vector2(0.4, 0), 1.0 / 60.0)                 # glissement lent contre un obstacle : 4 px
	check_eq(s.spr.frame, 0, "glissement lent : les pas ne défilent pas à la vitesse théorique")
	s.free()


func test_facing_is_stable_on_diagonals_and_key_release() -> void:
	var w := Zone.Walker.new("aren", true)
	for i in 30:                                              # diagonale bas-droite au clavier (déplacement réel)
		w.animate(Vector2(0.85, 0.68), 1.0 / 60.0)
	check_eq(String(w.spr.animation), "walk_right", "diagonale : profil stable")
	for i in 2:                                               # on lâche « droite » deux images avant « bas »
		w.animate(Vector2(0, 0.96), 1.0 / 60.0)
	check_eq(String(w.spr.animation), "walk_right", "relâchement décalé : pas d'orientation parasite")
	for i in 10:
		w.animate(Vector2.ZERO, 1.0 / 60.0)
	check_eq(String(w.spr.animation), "idle_right", "à l'arrêt : garde l'orientation de la marche")
	for i in 10:                                              # vrai virage vers le bas : adopté
		w.animate(Vector2(0, 0.96), 1.0 / 60.0)
	check_eq(String(w.spr.animation), "walk_face", "virage réel vers le bas : de face")
	w.free()


func test_followers_hold_constant_distance_along_trail() -> void:
	var z = _zone_stub()
	z.hero.position = Vector2(300, 250)
	z.trail = [Vector2(250, 280), Vector2(270, 280), Vector2(280, 270), Vector2(300, 250)]
	var p1: Vector2 = z.trail_point(20.0)
	var p2: Vector2 = z.trail_point(40.0)
	check(absf(p1.distance_to(Vector2(300, 250)) - 20.0) < 0.01, "1er suiveur à 20 px le long de la trace")
	var along := p1.distance_to(Vector2(280, 270)) + Vector2(280, 270).distance_to(p2)
	check(absf(along - 20.0) < 0.05, "2e suiveur à 20 px de plus, en suivant le virage (%.2f)" % along)
	_free_stub(z)


func test_corner_and_axis_moves_do_not_snag() -> void:
	var z = _zone_stub()
	z.hero.position = Vector2(318.6, 130.4)                   # contre l'angle arrière gauche de la maison
	check(z.free_at(z.hero.position), "position de départ libre")
	var np: Vector2 = z.move(z.hero, Vector2(0, -1.92))        # flèche « haut » seule (30 i/s)
	check(np != z.hero.position and z.free_at(np), "l'angle ne bloque pas une marche verticale")
	var ok := true
	z.hero.position = Vector2(330, 205)
	for i in 120:                                             # pousser « haut » contre la façade : jamais dans le mur
		z.hero.position = z.move(z.hero, Vector2(0, -1.2))
		ok = ok and z.free_at(z.hero.position)
	check(ok, "contre la façade : aucune position interdite")
	_free_stub(z)


func test_depth_uses_real_front_edge_of_slanted_walls() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.open("res://art/explore_hd2d/zone.json", FileAccess.READ).get_as_text())
	var fp := PackedVector2Array()
	for p in data["sprites"]["maison"]["footprint"]:
		fp.append(Vector2(p[0], p[1]))
	var sort_y: float = data["sprites"]["maison"]["sort_y"]
	var guard := Vector2(448, 170.2)
	check(guard.y < sort_y, "le garde est au-dessus de la ligne de tri horizontale de la maison (ancien tri : derrière)")
	check(guard.y > Zone.front_edge(fp, guard.x), "mais il est DEVANT le mur de façade à son abscisse")
	check(Vector2(440, 92).y < Zone.front_edge(fp, 440), "derrière la maison : derrière")


func test_demo_route_is_simplified_without_micro_waypoints() -> void:
	var z = _zone_stub()
	var pts := PackedVector2Array()
	for i in 41:                                              # 40 cellules de 4 px en ligne droite dans un espace libre
		pts.append(Vector2(200 + i * 4, 300 - i * 1))
	var out: PackedVector2Array = z.simplify_path(pts)
	check_eq(out.size(), 2, "ligne droite praticable : un seul segment")
	_free_stub(z)


func test_sprite_feet_match_logical_position_from_the_start() -> void:
	for spec in [["pnj", false], ["aren", true], ["ilya", false]]:
		var w := Zone.Walker.new(spec[0], spec[1])
		var tex: Texture2D = w.spr.sprite_frames.get_frame_texture(w.spr.animation, w.spr.frame)
		var feet: Vector2 = w.spr.offset + Vector2(tex.get_width() / 2.0, tex.get_height())
		check(absf(feet.x) <= 1.0 and absf(feet.y) < 0.01, "%s : pieds du sprite sur la position dès l'apparition (écart %s)" % [spec[0], str(feet)])
		w.free()
