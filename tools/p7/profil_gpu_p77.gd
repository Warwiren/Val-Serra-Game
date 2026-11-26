extends SceneTree
## P7.7 — PROFILAGE DU SECTEUR PILOTE (tranche P7.6 : îlot de l'auberge, ruelle des Tonneliers) et de points témoins en
## blockout. À lancer AVEC rendu (pas --headless) sur la machine à mesurer :
##   godot --path . --script res://tools/p7/profil_gpu_p77.gd -- [--tranche=0] [--resolution=1920x1080] [--sortie=chemin.csv]
## Pour chaque point de vue (caméra de jeu, Aren immobile) : 2 s de stabilisation puis 4 s de mesures, synchronisation
## verticale coupée. Relevés par image : durée réelle de l'image, temps de rendu CPU et GPU mesurés par le moteur
## (RenderingServer.viewport_get_measured_render_time_*), appels de dessin, primitives, objets ; mémoire vidéo.
## Sortie : un tableau dans la console, un CSV (par point de vue : moyenne, p95, max) et l'identité de la machine.
## --tranche=0 : même parcours, tranche remplacée par le blockout (coût propre de la tranche = différence).

const SCENE := "res://scenes/p7/ville_v07b.tscn"
const POINTS := [
	# [id, x, y, h, dans la tranche]
	["T1_terrasse_auberge", 76.0, 135.0, 0.0, true],
	["T2_pied_ruelle", 82.0, 133.0, 0.0, true],
	["T3_escalier_ruelle", 82.0, 122.0, 1.05, true],
	["T4_haut_ruelle", 82.0, 113.5, 3.5, true],
	["T5_bras_est", 78.0, 106.0, 3.5, true],
	["T6_rue_chantier", 86.0, 140.0, 0.0, true],
	["T7_placette", 66.0, 142.0, 0.0, true],
	["B1_grande_place", 50.0, 104.0, 3.5, false],
	["B2_terrasse_haute", 72.0, 62.0, 8.0, false],
	["B3_parvis_colisee", 12.0, 100.0, 3.5, false],
]
const STAB_S := 2.0
const MESURE_S := 4.0

var z
var n := 0
var i_point := -1
var t_point := 0.0
var t_prec := 0
var echant := []
var lignes := []
var cli := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			cli[kv[0]] = kv[1]
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if cli.has("resolution"):
		var r := str(cli["resolution"]).split("x")
		DisplayServer.window_set_size(Vector2i(int(r[0]), int(r[1])))
	change_scene_to_file(SCENE)


func _process(_d: float) -> bool:
	n += 1
	if z == null:
		if n > 20 and current_scene != null and current_scene.get("world") != null:
			z = current_scene
			RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
			_suivant()
		return false
	var now := Time.get_ticks_usec()
	var dt := (now - t_prec) / 1000.0
	t_prec = now
	t_point += dt / 1000.0
	if t_point > STAB_S:
		var vp := root.get_viewport_rid()
		echant.append([dt, RenderingServer.viewport_get_measured_render_time_cpu(vp), RenderingServer.viewport_get_measured_render_time_gpu(vp),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)])
	if t_point > STAB_S + MESURE_S:
		_bilan_point()
		if not _suivant():
			_fin()
			quit()
	return false


func _suivant() -> bool:
	i_point += 1
	if i_point >= POINTS.size():
		return false
	var p: Array = POINTS[i_point]
	z.s.warp_to(Vector3(p[1], p[2], p[3]))
	z.teleport(z.s.hero, z.s.companion)
	t_point = 0.0
	t_prec = Time.get_ticks_usec()
	echant = []
	return true


static func _stats(v: Array) -> Array:
	var s := v.duplicate()
	s.sort()
	var moy := 0.0
	for x in s:
		moy += float(x)
	moy /= maxf(1.0, s.size())
	return [moy, float(s[int(0.95 * (s.size() - 1))]) if s.size() > 0 else 0.0, float(s[s.size() - 1]) if s.size() > 0 else 0.0]


func _bilan_point() -> void:
	var p: Array = POINTS[i_point]
	var cols := []
	for k in 6:
		cols.append(_stats(echant.map(func(e): return e[k])))
	var l := {"point": p[0], "tranche": p[4], "images": echant.size(),
		"image_ms": cols[0], "cpu_ms": cols[1], "gpu_ms": cols[2], "appels": cols[3], "primitives": cols[4], "objets": cols[5]}
	lignes.append(l)
	print("PROFIL %-22s images %4d | image %6.2f ms (p95 %6.2f, max %6.2f) | CPU %5.2f | GPU %5.2f (p95 %5.2f) | appels %5d | primitives %8d | objets %5d"
		% [p[0], echant.size(), cols[0][0], cols[0][1], cols[0][2], cols[1][0], cols[2][0], cols[2][1], int(cols[3][0]), int(cols[4][0]), int(cols[5][0])])


func _fin() -> void:
	var machine := {"godot": Engine.get_version_info()["string"], "carte": RenderingServer.get_video_adapter_name(),
		"fabricant": RenderingServer.get_video_adapter_vendor(), "api": RenderingServer.get_video_adapter_api_version(),
		"pilote": OS.get_video_adapter_driver_info(), "processeur": OS.get_processor_name(), "systeme": OS.get_name() + " " + OS.get_version(),
		"fenetre": DisplayServer.window_get_size(), "rendu": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"tranche": str(cli.get("tranche", "1")), "memoire_video_mo": snappedf(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0, 0.1)}
	print("PROFIL MACHINE ", JSON.stringify(machine))
	var chemin := str(cli.get("sortie", "user://profil_gpu_p77_%s.csv" % ("blockout" if str(cli.get("tranche", "1")) == "0" else "tranche")))
	var f := FileAccess.open(chemin, FileAccess.WRITE)
	if f == null:
		return
	f.store_line("# " + JSON.stringify(machine))
	f.store_line("point;tranche;images;image_moy_ms;image_p95_ms;image_max_ms;cpu_moy_ms;gpu_moy_ms;gpu_p95_ms;gpu_max_ms;appels_moy;appels_max;primitives_moy;objets_moy")
	for l in lignes:
		f.store_line("%s;%s;%d;%.3f;%.3f;%.3f;%.3f;%.3f;%.3f;%.3f;%d;%d;%d;%d" % [l["point"], l["tranche"], l["images"], l["image_ms"][0], l["image_ms"][1],
			l["image_ms"][2], l["cpu_ms"][0], l["gpu_ms"][0], l["gpu_ms"][1], l["gpu_ms"][2], int(l["appels"][0]), int(l["appels"][2]),
			int(l["primitives"][0]), int(l["objets"][0])])
	f.close()
	print("PROFIL CSV ", ProjectSettings.globalize_path(chemin))
