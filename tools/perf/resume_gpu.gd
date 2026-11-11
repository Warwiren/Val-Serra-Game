extends SceneTree
## Résume les fichiers *_mesures.json écrits par tools/perf/mesure_gpu.bat (ou .sh) en un tableau lisible :
## <dossier>/RESUME_GPU.md. Usage : godot --headless --path . --script res://tools/perf/resume_gpu.gd -- --dir=mesures_gpu
## Voir docs/PROTOCOLE_VALIDATION_CAMERA_GPU.md.

const VSYNC := ["désactivée", "activée", "adaptative", "mailbox"]


func _init() -> void:
	var dir := "mesures_gpu"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dir="):
			dir = a.substr(6)
	var files: Array = []
	var da := DirAccess.open(dir)
	if da == null:
		printerr("Dossier introuvable : ", dir)
		quit(1)
		return
	for f in da.get_files():
		if f.ends_with("_mesures.json"):
			files.append(f)
	files.sort()
	var out: Array = ["# Val'Serra — mesures GPU des variantes de caméra", ""]
	var machine := {}
	var rows: Array = []
	for f in files:
		var d = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f)))
		if typeof(d) != TYPE_DICTIONARY:
			continue
		var mc: Dictionary = d.get("machine", {})
		if machine.is_empty():
			machine = mc
		var ft: Dictionary = d.get("frametime_ms", {})
		var ok := 0
		var total := 0
		for r in d.get("reached", []):
			total += 1
			if r.get("ok", false):
				ok += 1
		var win: Array = mc.get("fenetre", [0, 0])
		rows.append("| %s | %s | %s | %s | %s | %d × %d | %s | %s | %s | %s | %s | %s | %s | %s | %d/%d | %s |" % [
			f.replace("_temoin_mesures.json", "").replace("_mesures.json", ""), d.get("variante", "?"), d.get("paysage", "?"),
			d.get("renderer", "?"), VSYNC[clampi(int(mc.get("vsync", 0)), 0, 3)], int(win[0]), int(win[1]),
			str(d.get("fps_avg", "—")), str(d.get("fps_min", "—")), str(ft.get("moyen", "—")), str(ft.get("p95", "—")), str(ft.get("max", "—")),
			str(int(d.get("draw_calls_max", 0))), str(int(d.get("primitives_max", 0))), str(d.get("video_mem_mb", "—")), ok, total,
			str(int(d.get("render_cam_jerks", 0)))])
	out.append("Date : %s" % Time.get_datetime_string_from_system(false, true))
	out.append("")
	if not machine.is_empty():
		out.append("- Carte graphique : %s (%s)" % [machine.get("carte_graphique", "?"), machine.get("fabricant", "?")])
		out.append("- Pilote : %s" % str(machine.get("pilote", "?")))
		out.append("- Processeur : %s" % machine.get("processeur", "?"))
		out.append("- Système : %s" % machine.get("systeme", "?"))
		out.append("- Godot : %s" % machine.get("godot", "?"))
		out.append("- Fréquence de l'écran : %s Hz" % str(machine.get("ecran_hz", "?")))
		out.append("- Pilote de rendu : %s — API %s" % [machine.get("pilote_rendu", "?"), machine.get("api", "?")])
		out.append("")
	out.append("| Mesure | Variante | Paysage | Rendu obtenu | V-Sync | Fenêtre | i/s moyen | i/s min | Frametime moyen (ms) | p95 (ms) | max (ms) | Appels de dessin max | Primitives max | Mémoire vidéo (Mo) | Étapes du parcours | À-coups caméra |")
	out.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
	out.append_array(rows)
	out.append("")
	out.append("Lecture : « Rendu obtenu » est le moteur de rendu réellement utilisé (forward_plus = Vulkan/D3D12, gl_compatibility = OpenGL) ;")
	out.append("s'il diffère de celui demandé, le pilote graphique a imposé un repli. Le frametime max inclut le chargement de l'instance.")
	out.append("Les i/s sans V-Sync mesurent la marge du GPU ; la ligne « vsync » montre la régularité réelle à l'écran.")
	var fo := FileAccess.open(dir.path_join("RESUME_GPU.md"), FileAccess.WRITE)
	fo.store_string("\n".join(out) + "\n")
	fo.close()
	print("\n".join(out))
	quit(0)
