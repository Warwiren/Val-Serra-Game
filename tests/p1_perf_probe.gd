extends SceneTree
## P1 — performances des trois caméras, mêmes conditions (1280×720, V-Sync coupée, même marche au clavier simulé).
##   xvfb-run godot --rendering-driver opengl3 --path . --script res://tests/p1_perf_probe.gd -- [--perf-out=f.json]
## Référence : l'avant-poste d'origine en caméra A ; puis la zone de test agrandie en A, B et C.
## Mesures : temps d'image (moyenne, 99e centile), appels de dessin, objets dessinés, mémoire statique et vidéo,
## temps de chargement. Sans écran (--headless) le rendu n'est pas exécuté : lancer sous un serveur d'affichage.

const SECONDS := 6.0
var out := {}
var out_path := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--perf-out="):
			out_path = a.substr(11)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_run.call_deferred()


func _key(k: Key, down: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = down
	Input.parse_input_event(ev)


func _measure(label: String, path: String, preset: String) -> void:
	root.get_node("GameState").camera_preset = preset
	var t0 := Time.get_ticks_usec()
	change_scene_to_file(path)
	await process_frame
	while current_scene == null or current_scene.scene_file_path != path:
		await process_frame
	await process_frame
	var load_ms := (Time.get_ticks_usec() - t0) / 1000.0
	for i in 30:
		await process_frame
	var frames: Array = []
	var draws := 0.0
	var objs := 0.0
	var t := 0.0
	var phase := 0
	while t < SECONDS:
		# même marche : droite, haut, gauche, bas (1,5 s chacun)
		var want := int(t / 1.5)
		if want != phase or t == 0.0:
			for k in [KEY_RIGHT, KEY_UP, KEY_LEFT, KEY_DOWN]:
				_key(k, false)
			_key([KEY_RIGHT, KEY_UP, KEY_LEFT, KEY_DOWN][mini(want, 3)], true)
			phase = want
		await process_frame
		var ms := root.get_process_delta_time() * 1000.0
		frames.append(ms)
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		objs += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		t += ms / 1000.0
	for k in [KEY_RIGHT, KEY_UP, KEY_LEFT, KEY_DOWN]:
		_key(k, false)
	var n := frames.size()
	var mean := 0.0
	for f in frames:
		mean += f
	mean /= n
	frames.sort()
	out[label] = {
		"chargement_ms": snappedf(load_ms, 0.1),
		"image_moy_ms": snappedf(mean, 0.01),
		"image_p99_ms": snappedf(frames[int(n * 0.99) - 1], 0.01),
		"images_par_s": snappedf(1000.0 / mean, 0.1),
		"appels_dessin": snappedf(draws / n, 0.1),
		"objets_dessines": snappedf(objs / n, 0.1),
		"memoire_statique_mo": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"memoire_video_mo": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
		"memoire_textures_mo": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.1),
	}
	print("PERF %-22s %s" % [label, JSON.stringify(out[label])])


func _run() -> void:
	await process_frame
	await _measure("avant-poste A", "res://scenes/explore_hd2d/zone_hd2d.tscn", "A")
	for p in ["A", "B", "C"]:
		await _measure("exploration v2 " + p, "res://scenes/explore_hd2d/zone_exploration.tscn", p)
	if out_path != "":
		FileAccess.open(out_path, FileAccess.WRITE).store_string(JSON.stringify(out, "  "))
	quit()
