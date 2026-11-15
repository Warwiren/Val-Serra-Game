extends "res://tools/p49/banc_v07.gd"
## P4.9 V08A — captures du masque de collision (touche C) : vue de dessus de toute la carte (caméra orthographique
## temporaire, propre à la capture) et vues P30 sur la butte sud et la crête nord.
##   godot --path . --script res://tools/p49/masque_v08.gd -- --out=<dossier> --tag=avant|apres

var tag := "apres"


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	await _tap(KEY_C)
	await _tap(KEY_H)
	# vue de dessus (nord en haut, comme la carte de l'audit)
	var cam: Camera3D = sc.get("_camera")
	var top := Camera3D.new()
	top.projection = Camera3D.PROJECTION_ORTHOGONAL
	top.size = 30.0
	(sc as Node3D).add_child(top)
	top.global_transform = Transform3D(Basis.from_euler(Vector3(-PI / 2, 0, 0)), Vector3(0, 40, 0))
	top.current = true
	_place(-15.8, 0.0)
	await _frames(20)
	await _snap("masque_dessus_%s" % tag)
	top.current = false
	cam.current = true
	top.queue_free()
	for v in [["butte_sud", 0.0, 1.5], ["crete_nord", 0.0, -1.5]]:
		_place(v[1], v[2])
		await _frames(30)
		await _snap("masque_%s_P30_%s" % [v[0], tag])
	quit()
