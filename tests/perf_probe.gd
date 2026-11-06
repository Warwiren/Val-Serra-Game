extends SceneTree
## Mesure de performances, toujours dans les mêmes conditions (démo automatique, V-Sync coupée, 1280×720).
##   godot --path . --script res://tests/perf_probe.gd -- [--perf-out=fichier.json] [--perf-tag=avant]
## Exploration (zone HD-2D) puis combat, pour chaque décor de combat disponible ; et une variante « effets
## coupés » (lumières et particules masquées) pour estimer leur coût. Mesures : images/s, temps d'image
## (moyenne, 99e centile), appels de dessin, objets dessinés, mémoire statique, mémoire
## vidéo (textures, tampons), temps de chargement d'une scène.
## Sans écran (--headless), le rendu n'est pas exécuté : lancer sous un serveur d'affichage.

const SECONDS := 6.0
var out := {}
var out_path := ""
var tag := "mesure"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--perf-out="):
			out_path = a.substr(11)
		elif a.begins_with("--perf-tag="):
			tag = a.substr(11)
	_run.call_deferred()


func _gs():
	return root.get_node("GameState")


func _load(path: String) -> float:
	var t0 := Time.get_ticks_usec()
	change_scene_to_file(path)
	await process_frame
	while current_scene == null or current_scene.scene_file_path != path:
		await process_frame
	await process_frame                                   # première image dessinée
	return (Time.get_ticks_usec() - t0) / 1000.0


func _sample(label: String, load_ms: float, hide_fx := false) -> void:
	if hide_fx:
		for n in current_scene.find_children("*", "PointLight2D", true, false) + current_scene.find_children("*", "CPUParticles2D", true, false):
			n.visible = false
	for i in 30:                                           # chauffe
		await process_frame
	var frames: Array = []
	var draws: Array = []
	var objs: Array = []
	var t := 0.0
	while t < SECONDS:
		await process_frame
		frames.append(_frame_ms())
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		objs.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		t += frames[-1] / 1000.0
	frames.sort()
	var mean := 0.0
	for f in frames:
		mean += f
	mean /= frames.size()
	out[label] = {
		"images_par_s": snappedf(1000.0 / mean, 0.1),
		"temps_image_ms_moyen": snappedf(mean, 0.01),
		"temps_image_ms_p99": snappedf(frames[int(frames.size() * 0.99) - 1], 0.01),
		"appels_dessin": int(_avg(draws)),
		"objets_dessines": int(_avg(objs)),
		"memoire_statique_mo": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"memoire_video_mo": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
		"memoire_textures_mo": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.1),
		"chargement_ms": snappedf(load_ms, 0.1),
	}
	print("PERF %-28s %s" % [label, JSON.stringify(out[label])])


var _last_us := 0


func _frame_ms() -> float:
	var now := Time.get_ticks_usec()
	var d := (now - _last_us) / 1000.0 if _last_us > 0 else 16.7
	_last_us = now
	return d


func _avg(a: Array) -> float:
	var s := 0.0
	for x in a:
		s += x
	return s / maxf(1, a.size())


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var gs = _gs()
	gs.autoplay = true
	var cold: float = await _load("res://scenes/explore_hd2d/zone_hd2d.tscn")   # premier chargement (à froid)
	var ms: float = await _load("res://scenes/explore_hd2d/zone_hd2d.tscn")     # rechargement (à chaud)
	_last_us = 0
	await _sample("exploration", ms)
	out["exploration"]["chargement_froid_ms"] = snappedf(cold, 0.1)
	var arenas := ["ancien", "lisiere-rendu"]
	if ResourceLoader.exists("res://art/arena/lisiere/peint/hd.json") or DirAccess.dir_exists_absolute("res://art/arena/lisiere/peint"):
		arenas.append("lisiere")
	for ar in arenas:
		gs.autoplay = true
		gs.proto = true
		gs.from_zone = false
		gs.arena = ar
		ms = await _load("res://scenes/battle/battle_scene.tscn")
		_last_us = 0
		await _sample("combat_" + ar, ms)
	_last_us = 0
	await _sample("combat_%s_effets_coupes" % arenas[-1], 0.0, true)
	out["_conditions"] = {"tag": tag, "moteur": Engine.get_version_info()["string"], "rendu": RenderingServer.get_video_adapter_name(),
		"pilote": RenderingServer.get_video_adapter_vendor(), "processeurs": OS.get_processor_count(), "processeur": OS.get_processor_name(),
		"fenetre": str(DisplayServer.window_get_size()), "vsync": "coupée", "duree_mesure_s": SECONDS}
	if out_path != "":
		FileAccess.open(out_path, FileAccess.WRITE).store_string(JSON.stringify(out, "  "))
	quit()
