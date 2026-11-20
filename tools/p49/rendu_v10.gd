extends "res://tools/p49/banc_v07.gd"
## V10 — rendu des personnages de la forêt (touche K) : captures avant / après dans la vraie scène F5 (démarrage
## réel : Aren V09B.5 ×0,719 + face / dos V4, Ilya V09C.6, 24°, ×3), mêmes poses, seul le rendu change.
##   xvfb-run godot --path . --rendering-method forward_plus --script res://tools/p49/rendu_v10.gd -- --out=<d>
##   (film : --write-movie <d>/f.png --fixed-fps 30 ... -- --film=AVANT|APRES)

var film_v10 := ""


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--film="):
			film_v10 = a.substr(7)
	load("res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.gd").set("demarrage_v09c6", true)
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	await _tap(KEY_H)
	if film_v10 != "":
		sc.set("_rendu_v10", film_v10 == "APRES")
		await _film()
		quit()
		return
	for pose in [["face", Vector3(0, 0, 1)], ["dos", Vector3(0, 0, -1)], ["droite", Vector3(1, 0, 0)], ["arret", Vector3.ZERO]]:
		_place(-12.0, -0.5)
		(sc.get("_ilya") as Node3D).global_position = _hero().global_position + Vector3(-1.3, 0, 0.2)
		(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, (sc.get("_ilya") as Node3D).global_position)
		await _frames(20)
		if pose[1] != Vector3.ZERO:
			_steer(pose[1])
			await _frames(22)
		else:
			_steer(Vector3(0, 0, 1))
			await _frames(10)
			_stop()
			await _frames(40)
		_stop()
		sc.set_physics_process(false)
		sc.call("_update_camera", 1.0)
		for v in [false, true]:
			sc.set("_rendu_v10", v)
			sc.call("_rendu_perso", sc.get("_hero_sprite"), (sc.get("_hero_sprite") as Sprite3D).texture)
			sc.call("_rendu_perso", sc.get("_ilya_sprite"), (sc.get("_ilya_sprite") as Sprite3D).texture)
			await _snap("%s_%s" % [pose[0], "apres" if v else "avant"])
		sc.set_physics_process(true)
	quit()


func _film() -> void:
	_place(-12.0, -0.5)
	(sc.get("_ilya") as Node3D).global_position = _hero().global_position + Vector3(-1.3, 0, 0.2)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, (sc.get("_ilya") as Node3D).global_position)
	await _frames(20)
	for seg in [[Vector3(1, 0, 0), 60], [Vector3(0, 0, 1), 45], [Vector3.ZERO, 30], [Vector3(0, 0, -1), 60], [Vector3(-1, 0, 0), 60], [Vector3.ZERO, 30]]:
		if seg[0] == Vector3.ZERO:
			_stop()
		else:
			_steer(seg[0])
		await _frames(seg[1])
	_stop()
