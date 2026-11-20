extends "res://tools/p49/banc_v07.gd"
## P5.2 — vidéo du sol de la forêt : même trajet (chemin principal, croisement, montée vers la pente nord), démarrage
## réel de F5, avec le nouveau sol (--sol=1) ou le sol V07 d'origine (--sol=0).
##   xvfb-run godot --path . --rendering-method forward_plus --write-movie <d>/f.png --fixed-fps 30 \
##       --script res://tools/p5/film_sol.gd -- --sol=1

func _run() -> void:
	var sol := true
	for a in OS.get_cmdline_user_args():
		if a == "--sol=0":
			sol = false
	load("res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.gd").set("demarrage_v09c6", true)
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	sc.call("set_sol_p52", sol)
	await _tap(KEY_H)
	_place(-13.5, 0.3)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, (sc.get("_ilya") as Node3D).global_position)
	await _frames(20)
	for seg in [[Vector3(1, 0, -0.1), 120], [Vector3(1, 0, 0.45), 70], [Vector3(0.3, 0, -1), 80], [Vector3.ZERO, 30]]:
		if seg[0] == Vector3.ZERO:
			_stop()
		else:
			_steer(seg[0])
		await _frames(seg[1])
	_stop()
	quit()
