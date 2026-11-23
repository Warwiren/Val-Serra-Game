extends "res://tools/p49/banc_v07.gd"
## V11 — vidéo des collisions du décor et du Vorgane dans la vraie scène F5 (démarrage réel).
##   xvfb-run godot --path . --rendering-method forward_plus --write-movie <d>/f.png --fixed-fps 30 \
##       --script res://tools/p49/collisions_v11.gd
## Aren marche droit sur un rocher autrefois traversable, longe un buisson haut, rejoint le chemin, puis va au
## Vorgane, le heurte et passe à sa droite (il se retourne).


func _run() -> void:
	load("res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.gd").set("demarrage_v09c6", true)
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	await _tap(KEY_H)
	_place(-6.6, 2.4)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, (sc.get("_ilya") as Node3D).global_position)
	await _frames(20)
	for seg in [[Vector3(0, 0, 1), 70], [Vector3(-1, 0, 0.35), 50], [Vector3.ZERO, 20]]:
		if seg[0] == Vector3.ZERO:
			_stop()
		else:
			_steer(seg[0])
		await _frames(seg[1])
	_place(4.6, 0.6)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, (sc.get("_ilya") as Node3D).global_position)
	await _frames(20)
	for seg in [[Vector3(1, 0, 0), 40], [Vector3(0, 0, 1), 50], [Vector3.ZERO, 20], [Vector3(1, 0, 0), 45], [Vector3(0, 0, 1), 30], [Vector3.ZERO, 50]]:
		if seg[0] == Vector3.ZERO:
			_stop()
		else:
			_steer(seg[0])
		await _frames(seg[1])
	_stop()
	quit()
