extends SceneTree
## P4.9 — banc d'essai de la scène V07B (forêt Quaternius). Pilote la VRAIE scène par le clavier simulé (actions
## ui_*, touches Maj, 1/2/3, N, V) et mesure : vitesses de marche et de course, demi-tour, les 3 parcours du
## manifeste (blocages, chutes), collisions des arbres, du ruisseau et des bords, touche N. Captures PNG.
## Ne valide PAS le rendu : les captures servent à la revue artistique.
##   godot --headless --path . --script res://tools/p49/banc_v07.gd -- --out=<dossier>     (mesures, rapide)
##   godot --path . --script res://tools/p49/banc_v07.gd -- --out=<dossier> --captures      (vitesses + captures)
##   godot --path . --write-movie v.avi --fixed-fps 30 --script res://tools/p49/banc_v07.gd -- --film
## --film : déroulé court pour la vidéo (--write-movie), sans les mesures longues.
## --captures : seulement les vitesses et les captures (Forward+ en Vulkan logiciel, très lent).

const SCENE := "res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.tscn"
const MANIFEST := "res://ValSerra_P49_V07B_PREFLIGHT_GODOT/docs/V07_WORLD.json"
var sc: Node
var out := "user://p49"
var film := false
var captures_only := false
var res := {"mesures": {}, "parcours": {}, "collisions": [], "captures": []}
var data: Dictionary


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		film = film or a == "--film"
		captures_only = captures_only or a == "--captures"
	DirAccess.make_dir_recursive_absolute(out)
	data = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _key(k: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = down
	Input.parse_input_event(e)


func _tap(k: Key) -> void:
	_key(k, true)
	await _frames(2)
	_key(k, false)
	await _frames(2)


## direction monde (x, z) -> actions ui_* analogiques, dans le repère de la caméra (comme le joueur)
func _steer(dir: Vector3) -> void:
	var cam: Camera3D = sc.get("_camera")
	var right := cam.global_transform.basis.x
	right.y = 0
	right = right.normalized()
	var fwd := -cam.global_transform.basis.z
	fwd.y = 0
	fwd = fwd.normalized()
	var ix := dir.dot(right)
	var iy := -dir.dot(fwd)
	for a in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		Input.action_release(a)
	if ix > 0.01:
		Input.action_press("ui_right", ix)
	elif ix < -0.01:
		Input.action_press("ui_left", -ix)
	if iy > 0.01:
		Input.action_press("ui_down", iy)
	elif iy < -0.01:
		Input.action_press("ui_up", -iy)


func _stop() -> void:
	for a in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		Input.action_release(a)


func _hero() -> CharacterBody3D:
	return sc.get("_hero")


func _place(x: float, z: float) -> void:
	var h := _hero()
	h.global_position = Vector3(x, _ground(x, z) + 0.15, z)
	h.velocity = Vector3.ZERO
	var il: CharacterBody3D = sc.get("_ilya")
	il.global_position = Vector3(x - 1.1, _ground(x - 1.1, z) + 0.15, z + 0.3)
	il.velocity = Vector3.ZERO
	sc.call("_update_camera", 1.0)


func _ground(x: float, z: float) -> float:
	var space := (sc as Node3D).get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 30, z), Vector3(x, -10, z))
	q.exclude = [_hero().get_rid(), (sc.get("_ilya") as CharacterBody3D).get_rid()]
	var hit := space.intersect_ray(q)
	return float(hit["position"].y) if not hit.is_empty() else 0.0


func _snap(id: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	var p := out.path_join(id + ".png")
	img.save_png(p)
	res["captures"].append(p)


func _speed(run: bool, frames: int) -> Dictionary:
	_place(-12.3, 0.3)
	await _frames(20)
	if run:
		_key(KEY_SHIFT, true)
	_steer(Vector3(1, 0, 0))
	await _frames(15)                                  # mise en vitesse
	var p0 := _hero().global_position
	var changes := 0
	var last: int = sc.get("_hero_anim").get("frame")
	for i in frames:
		await _frames(1)
		var f: int = sc.get("_hero_anim").get("frame")
		if f != last:
			changes += 1
			last = f
	var p1 := _hero().global_position
	_stop()
	_key(KEY_SHIFT, false)
	var d := Vector2(p1.x - p0.x, p1.z - p0.z).length()
	var stride: float = sc.get("_hero_anim").get("stride_m")
	var sec := frames / float(Engine.physics_ticks_per_second)
	return {"m_par_s": snappedf(d / sec, 0.01), "images_anim_par_s": snappedf(changes / sec, 0.1), "pas_par_s": snappedf(changes / sec / 4.0, 0.01)}


func _route(name: String, run: bool) -> Dictionary:
	var pts: Array = data["routes"][name]
	_place(float(pts[0][0]), float(pts[0][1]))
	await _frames(20)
	if run:
		_key(KEY_SHIFT, true)
	var r := {"points": pts.size(), "atteints": 0, "bloque": [], "chute": false, "y_min": 99.0, "y_max": -99.0, "s": 0.0}
	var t := 0
	for i in range(1, pts.size()):
		var goal := Vector3(float(pts[i][0]), 0, float(pts[i][1]))
		var best := 1e9
		var since := 0
		while true:
			var h := _hero().global_position
			var to := Vector3(goal.x - h.x, 0, goal.z - h.z)
			if to.length() < 0.45:
				r["atteints"] += 1
				break
			_steer(to.normalized())
			await _frames(1)
			t += 1
			r["y_min"] = minf(r["y_min"], h.y)
			r["y_max"] = maxf(r["y_max"], h.y)
			if h.y < -1.0:
				r["chute"] = true
			if to.length() < best - 0.02:
				best = to.length()
				since = 0
			else:
				since += 1
			if since > 60:                              # 2 s sans progresser : blocage
				r["bloque"].append([snappedf(h.x, 0.1), snappedf(h.z, 0.1), "vers point %d" % i])
				break
	_stop()
	_key(KEY_SHIFT, false)
	r["s"] = snappedf(t / float(Engine.physics_ticks_per_second), 0.1)
	r["y_min"] = snappedf(r["y_min"], 0.01)
	r["y_max"] = snappedf(r["y_max"], 0.01)
	return r


## pousse le héros vers `target` pendant `frames` ; ok si sa distance à `target` (plan horizontal) reste > `min_d`
func _push(id: String, from: Vector2, target: Vector2, min_d: float, frames := 75) -> Dictionary:
	_place(from.x, from.y)
	await _frames(15)
	var closest := 1e9
	for i in frames:
		var h := _hero().global_position
		_steer(Vector3(target.x - h.x, 0, target.y - h.z).normalized())
		await _frames(1)
		h = _hero().global_position
		closest = minf(closest, Vector2(h.x, h.z).distance_to(target))
	_stop()
	var r := {"id": id, "ok": closest > min_d, "distance_min_m": snappedf(closest, 0.01), "limite_m": snappedf(min_d, 0.01)}
	res["collisions"].append(r)
	return r


func _run() -> void:
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	res["rendu"] = RenderingServer.get_current_rendering_method()
	res["carte"] = RenderingServer.get_video_adapter_name()
	if film:
		await _film()
	else:
		await _tests()
	var f := FileAccess.open(out.path_join("banc_v07.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(res, " "))
	print("BANC V07 : ", JSON.stringify(res))
	quit()


func _tests() -> void:
	# vitesses (mesurées sur 3 s)
	res["mesures"]["marche"] = await _speed(false, 90)
	res["mesures"]["course"] = await _speed(true, 90)
	var aren: RefCounted = sc.get("_hero_anim")
	var ilya: RefCounted = sc.get("_ilya_anim")
	res["mesures"]["foulee_m_par_image"] = [snappedf(aren.get("stride_m"), 0.001), snappedf(ilya.get("stride_m"), 0.001)]
	# demi-tour : après 1,3 s vers l'est, 1,3 s vers l'ouest ; le héros doit repartir (Ilya le suit juste derrière)
	_place(-12.3, 0.3)
	await _frames(10)
	_steer(Vector3(1, 0, 0))
	await _frames(80)
	var xa := _hero().global_position.x
	_steer(Vector3(-1, 0, 0))
	await _frames(80)
	var xb := _hero().global_position.x
	var a2: String = aren.get("anim")
	_stop()
	await _frames(10)
	res["mesures"]["demi_tour"] = {"recul_m": snappedf(xa - xb, 0.01), "attendu_m": snappedf(2.2 * 80 / 60.0, 0.01), "anim": a2, "ok": xa - xb > 2.2 * 80 / 60.0 * 0.8}
	if captures_only:
		await _views()
		return
	# parcours du manifeste, à la marche puis le principal en course
	for n in data["routes"].keys():
		res["parcours"][n] = await _route(n, false)
	res["parcours"]["main_course"] = await _route("main", true)
	# collisions : arbres bloquants, ruisseau, bords de carte
	var trees: Array = data["placements"].filter(func(p): return p.get("blocking", false) and p["role"] == "tree")
	for p in trees.slice(0, 4):
		var c := Vector2(float(p["xyz"][0]), float(p["xyz"][2]))
		var side := Vector2(-signf(c.x) * 2.2, 0.0)        # approche depuis le centre (pas depuis la barrière de bord)
		await _push("arbre %s (%.1f, %.1f)" % [p["name"], c.x, c.y], c + side, c, 0.48 * float(p["scale"]) * 0.8)
	for b in [data["water_barriers"][2], data["water_barriers"][12], data["water_barriers"][20]]:
		var c := Vector2(float(b["xyz"][0]), float(b["xyz"][2]))
		var r := float(b["rotation_y"])
		var n := Vector2(sin(r), cos(r))                 # axe local Z de la barrière (travers du ruisseau)
		await _push("ruisseau (%.1f, %.1f)" % [c.x, c.y], c + n * 2.4, c, float(b["width"]) * 0.5 * 0.8)
	await _push("bord est", Vector2(15.5, 0.5), Vector2(19.0, 0.5), 0.9)
	await _push("bord ouest", Vector2(-15.5, 0.0), Vector2(-19.0, 0.0), 0.9)
	# N : décor masqué -> collisions des arbres coupées ; puis rétablies
	var t0: Dictionary = trees[0]
	var c0 := Vector2(float(t0["xyz"][0]), float(t0["xyz"][2]))
	await _tap(KEY_N)
	await _frames(3)
	var s0 := Vector2(-signf(c0.x) * 2.2, 0.0)
	var rn := await _push("N actif : arbre traversable", c0 + s0, c0, 0.0)
	rn["ok"] = rn["distance_min_m"] < 0.3
	await _tap(KEY_N)
	await _frames(3)
	await _push("N rétabli : arbre de nouveau bloquant", c0 + s0, c0, 0.48 * float(t0["scale"]) * 0.8)
	if DisplayServer.get_name() != "headless":
		await _views()


func _views() -> void:
	# captures P30 : seuil, clairière, ruisseau, aux zooms ×2,5 et ×3 ; eau animée (V)
	for v in [["seuil", -14.5, 0.2], ["clairiere", -2.0, -0.5], ["ruisseau", 3.0, -9.0]]:
		_place(v[1], v[2])
		for z in [[KEY_2, "x2-5"], [KEY_3, "x3"]]:
			await _tap(z[0])
			await _frames(25)
			await _snap("%s_%s_%s" % [v[0], z[1], res["rendu"]])
	await _tap(KEY_2)
	_place(3.0, -9.0)
	await _tap(KEY_V)
	await _frames(30)
	await _snap("ruisseau_eau_animee_x2-5_%s" % res["rendu"])
	await _tap(KEY_V)


func _film() -> void:
	# ~24 s : marche du seuil vers la clairière, halte, demi-tour, course, ruisseau avec l'eau animée
	_place(-15.0, 0.0)
	await _tap(KEY_2)
	await _frames(45)
	_steer(Vector3(1, 0, 0.05).normalized())
	await _frames(120)
	_stop()
	await _frames(40)
	_steer(Vector3(-1, 0, 0))
	await _frames(45)
	_steer(Vector3(0, 0, 1))
	await _frames(40)
	_steer(Vector3(0, 0, -1))
	await _frames(40)
	_stop()
	await _frames(30)
	_key(KEY_SHIFT, true)
	_steer(Vector3(1, 0, -0.1).normalized())
	await _frames(90)
	_stop()
	_key(KEY_SHIFT, false)
	await _frames(30)
	await _tap(KEY_3)
	_place(2.0, -8.6)
	await _tap(KEY_V)
	await _frames(40)
	_steer(Vector3(0.3, 0, -1).normalized())                # vers l'eau : la berge arrête le héros
	await _frames(60)
	_stop()
	_steer(Vector3(1, 0, 0))
	await _frames(70)
	_stop()
	await _frames(45)
