extends "res://tools/p49/banc_v07.gd"
## P5.3 — coût des ombres : temps d'image moyen (CPU et GPU mesurés par le moteur) par configuration, secteur et zoom,
## dans la vraie scène F5. Configurations : P5.2 (sol P5.2, terrain sans ombre, qualité 2), P5.3 q2, P5.3 q4.
##   xvfb-run godot --path . --rendering-method forward_plus --script res://tools/p5/perf_ombres.gd -- --out=<d>
## Sur Vulkan LOGICIEL (lavapipe), les valeurs absolues ne représentent pas un GPU ; seuls les écarts relatifs servent.

const SECTEURS := [["chemin", -2.0, -0.4], ["pente_nord", 1.0, -6.6], ["clairiere", 6.0, 1.0]]
const ZOOMS := [[KEY_1, 2.0], [KEY_3, 3.0]]
var CONFIGS := [["P5.2_q2", "p52", 2], ["P5.3_q2", "p53", 2], ["P5.3_q4", "p53", 4]]
## --sols : P5.3 contre pilotes P5.3-B (V1 calée, V2), qualité 4, textures sur toute la carte (pire cas)
const CONFIGS_SOLS := [["P5.3", "p53", 4], ["V1_calee", "p53b1c", 4], ["V2", "p53b2", 4]]


func _run() -> void:
	load("res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.gd").set("demarrage_v09c6", true)
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	await _tap(KEY_H)
	if OS.get_cmdline_user_args().has("--sols"):
		CONFIGS = CONFIGS_SOLS
		sc.call("set_pilote_carte_entiere", true)
	var vp := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var out_d := {}
	for z in ZOOMS:
		await _tap(z[0])
		for s in SECTEURS:
			_place(s[1], s[2])
			sc.set_physics_process(false)
			sc.call("_update_camera", 1.0)
			for c in CONFIGS:
				sc.call("set_version_sol", c[1])
				sc.call("set_qualite_ombre", c[2])
				await _frames(8)
				var cpu := 0.0
				var gpu := 0.0
				var t0 := Time.get_ticks_usec()
				var n := 20
				for i in n:
					await process_frame
					cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
					gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
				var mur := float(Time.get_ticks_usec() - t0) / 1000.0 / n
				var k := "%s ×%.1f %s" % [s[0], z[1], c[0]]
				out_d[k] = {"image_ms": snappedf(mur, 0.1), "rendu_cpu_ms": snappedf(cpu / n, 0.01), "rendu_gpu_ms": snappedf(gpu / n, 0.01)}
				print("PERF %-32s image %7.1f ms · rendu GPU %7.2f ms · CPU %6.2f ms" % [k, mur, gpu / n, cpu / n])
			sc.set_physics_process(true)
	var f := FileAccess.open(out.path_join("perf_ombres.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out_d, " "))
	quit()
