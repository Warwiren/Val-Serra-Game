extends SceneTree
## P5 — refonte du combat : groupe à gauche tourné vers la droite, Vorgane à droite tourné vers la gauche, décor forêt.
##   godot --headless --path . --script res://tests/p5_combat_smoke.gd

var failures := 0


func _test(ok: bool, label: String) -> void:
	if ok:
		print("P5 OK : " + label)
	else:
		failures += 1
		push_error("P5 ECHEC : " + label)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file("res://scenes/battle/combat_foret.tscn")
	for i in 40:
		await process_frame
	var sc := current_scene
	_test(sc != null and sc.scene_file_path.ends_with("battle_scene.tscn"), "F6 combat_foret.tscn ouvre le combat")
	var gs = root.get_node("GameState")
	_test(gs.proto and gs.arena == "foret" and gs.use_pilot_arena(), "prototype, arène forêt")
	var hunters: Dictionary = sc.get("hunters")
	var mv = sc.get("monster_view")
	var xs := []
	for id in hunters:
		xs.append((hunters[id] as Node2D).position.x)
	xs.sort()
	_test(hunters.size() == 3 and xs[-1] < 640.0 and (mv as Node2D).position.x > 640.0, "groupe à gauche (x ≤ %d), Vorgane à droite (x = %d)" % [xs[-1], (mv as Node2D).position.x])
	var face := true
	for id in hunters:
		face = face and (hunters[id] as Node2D).scale.x > 0.0
	_test(face and not bool(mv.get("facing_right")), "héros tournés vers la droite, Vorgane vers la gauche")
	var ar = sc.get("arena")
	_test(ar != null and ar.get_script().resource_path.ends_with("arena_foret.gd") and (ar.get("lights") as Array).size() == 1, "décor : forêt d'exploration (soleil pour l'éclairage du Vorgane)")
	var hud = sc.get("hud")
	_test(String(hud.get("zone_name")) == "Forêt de la lisière", "lieu affiché : Forêt de la lisière")
	print("P5 : %d échec(s)" % failures)
	quit(1 if failures > 0 else 0)
