extends SceneTree
## P1 — retour de combat dans la ZONE DE TEST AGRANDIE, pour chaque caméra (A, B, C).
##   godot --headless --path . --script res://tests/e2e_p1_retour.gd
## Même simulation de fin de combat que e2e_zone_retour.gd (la mécanique de combat n'est pas exécutée), puis :
## la caméra choisie est conservée, recentrée immédiatement sur le héros (pas de glissade depuis l'origine de la
## carte), reste dans la carte ; le groupe est sur des positions libres ; pas de nouveau combat immédiat.

const ZONE := "res://scenes/explore_hd2d/zone_exploration.tscn"
var fails := []


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, msg: String) -> void:
	print(("OK     " if cond else "ÉCHEC  ") + msg)
	if not cond:
		fails.append(msg)


func _load_zone():
	change_scene_to_file(ZONE)
	for i in 3:
		await process_frame
	return current_scene


func _end(z, result: String) -> void:
	var gs = root.get_node("GameState")
	gs.from_zone = true
	gs.zone_return_pos = z.hero.position
	gs.explore_return = ZONE
	gs.last_battle_result = result
	if result == "victory":
		gs.enemy_defeated = true


func _cam_ok(z, p: String, when: String) -> void:
	var c = z.cam
	_check(c.preset == p and is_equal_approx(c.zoom.x, float(c.PRESETS[p]["zoom"])), "%s %s : caméra %s conservée" % [p, when, p])
	var half: Vector2 = c.view_size() / 2.0
	var want := Vector2(clampf(z.hero.position.x, half.x, 1408 - half.x), clampf(z.hero.position.y, half.y, 800 - half.y))
	var got: Vector2 = c.get_screen_center_position()
	_check(got.distance_to(want) < 24.0, "%s %s : vue centrée sur le groupe dès le retour (écart %.1f px)" % [p, when, got.distance_to(want)])
	_check(Rect2(0, 0, 1408, 800).grow(0.5).encloses(Rect2(got - half, half * 2.0)), "%s %s : vue dans la carte" % [p, when])


func _run() -> void:
	root.size = Vector2i(1280, 720)                       # sans écran, la fenêtre virtuelle est carrée
	var gs = root.get_node("GameState")
	gs.autoplay = false
	for p in ["A", "B", "C"]:
		gs.enemy_defeated = false
		gs.camera_preset = p
		var z = await _load_zone()
		_check(z.monster.visible, "%s départ : le Vorgane est présent" % p)
		# défaite au contact du monstre : repli au départ, pas de nouveau combat
		z.hero.position = z.monster_pos + Vector2(z.monster_rx + 4, 2)
		_end(z, "defeat")
		z = await _load_zone()
		for i in 20:
			await process_frame
		_cam_ok(z, p, "après défaite")
		_check(not z._engaging, "%s après défaite : pas de nouveau combat" % p)
		for w in z.party:
			_check(z.free_at(w.position), "%s après défaite : %s sur une position libre" % [p, w.key])
		# victoire loin du départ (près de la 2e maison) : retour à cet endroit, caméra posée là
		z.hero.position = Vector2(900, 420)
		var pos: Vector2 = z.hero.position
		_end(z, "victory")
		z = await _load_zone()
		for i in 20:
			await process_frame
		_check(z.hero.position.distance_to(pos) < 1.0, "%s après victoire : retour à l'endroit du combat" % p)
		_check(not z.monster.visible, "%s après victoire : le Vorgane a disparu" % p)
		_cam_ok(z, p, "après victoire")
		for w in z.party:
			_check(z.free_at(w.position), "%s après victoire : %s sur une position libre" % [p, w.key])
		gs.zone_return_pos = Vector2.ZERO
	print("E2E P1 RÉSULTAT : %s" % ("RÉUSSI" if fails.is_empty() else "ÉCHEC (%d)" % fails.size()))
	quit(0 if fails.is_empty() else 1)
