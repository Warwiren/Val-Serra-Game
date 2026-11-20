extends "res://tools/p49/banc_v07.gd"
## P5.2 — captures du sol de la forêt (avant / après) aux mêmes points, configuration F5 (24°, ×3, sans brouillard),
## interface masquée. Points : départ, croisement ouest, chemin central, pente nord, ruisseau, clairière du Vorgane,
## plus une vue large (×2, 30°).
##   xvfb-run godot --path . --rendering-method forward_plus --script res://tools/p5/captures_sol.gd -- --out=<dossier>
##       [--points=chemin,large]

const POINTS := [["depart", -14.5, 0.2], ["croisement", -12.0, 1.2], ["chemin", -2.0, -0.4], ["pente_nord", 1.0, -6.6],
	["ruisseau", 2.5, -9.6], ["clairiere", 6.0, 1.0]]


func _run() -> void:
	load("res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.gd").set("demarrage_v09c6", true)
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	await _tap(KEY_H)
	var seuls := []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--points="):
			seuls = a.substr(9).split(",")
	for p in POINTS:
		if seuls.is_empty() or p[0] in seuls:
			await _vue(p[0], p[1], p[2])
	if seuls.is_empty() or "large" in seuls:
		await _tap(KEY_1)
		await _tap(KEY_4)
		await _vue("large", -2.0, 0.5)
	quit()


func _vue(nom: String, x: float, z: float) -> void:
	_place(x, z)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, (sc.get("_ilya") as Node3D).global_position)
	await _frames(20)
	sc.set_physics_process(false)
	sc.call("_update_camera", 1.0)
	await _frames(4)
	await _snap(nom)
	sc.set_physics_process(true)
