extends "res://tools/p49/banc_v07.gd"
## P4.9 V08A — vidéo d'exploration libre, hors des chemins : clairière sud, butte, retour en course, montée nord par
## un passage praticable, crête contournée, ruisseau ; diagnostic des collisions (C) affiché à la fin.
##   godot --path . --write-movie v.avi --fixed-fps 30 --script res://tools/p49/exploration_v08.gd -- --out=<dossier>

const POINTS := [
	[-12.0, 0.0, false], [-9.0, 4.5, false], [-5.5, 4.6, false], [0.3, 5.0, false],       # clairière et butte sud
	[6.0, 5.0, false],
	[8.0, 7.5, false], [8.0, 1.0, true], [6.0, -3.0, true],                               # retour en course, montée nord
	[7.0, -7.0, false], [0.0, -9.0, false], [3.0, -10.0, false],                          # derrière la crête, vers l'eau
]


func _run() -> void:
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	res = {"etapes": []}
	_place(-15.5, 0.0)
	await _frames(30)
	for p in POINTS:
		_key(KEY_SHIFT, bool(p[2]))
		var goal := Vector3(float(p[0]), 0, float(p[1]))
		var best := 1e9
		var since := 0
		for i in 600:
			var h := _hero().global_position
			var to := Vector3(goal.x - h.x, 0, goal.z - h.z)
			if to.length() < 0.5:
				break
			_steer(to.normalized())
			await _frames(1)
			if to.length() < best - 0.02:
				best = to.length()
				since = 0
			else:
				since += 1
			if since > 60:
				break
		res["etapes"].append({"vers": [p[0], p[1]], "atteint": best < 0.6, "course": p[2]})
	_key(KEY_SHIFT, false)
	_stop()
	await _frames(30)
	await _tap(KEY_C)
	await _frames(75)
	await _tap(KEY_C)
	await _frames(20)
	var f := FileAccess.open(out.path_join("exploration_v08.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(res, " "))
	print("EXPLORATION ", JSON.stringify(res))
	quit()
