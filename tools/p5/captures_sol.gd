extends "res://tools/p49/banc_v07.gd"
## P5.2 — captures du sol de la forêt (avant / après) aux mêmes points, configuration F5 (24°, ×3, sans brouillard),
## interface masquée. Points : départ, croisement ouest, chemin central, pente nord, ruisseau, clairière du Vorgane,
## plus une vue large (×2, 30°).
##   xvfb-run godot --path . --rendering-method forward_plus --script res://tools/p5/captures_sol.gd -- --out=<dossier>
##       [--points=chemin,large]

const POINTS := [["depart", -14.5, 0.2], ["croisement", -12.0, 1.2], ["chemin", -2.0, -0.4], ["pente_nord", 1.0, -6.6],
	["ruisseau", 2.5, -9.6], ["clairiere", 6.0, 1.0],
	# P5.3 : vues rapprochées (bord de chemin, pente, pied d'arbre, pied de rocher)
	["proche_bord", -7.2, 2.6], ["proche_pente", -1.0, -7.4], ["proche_arbre", -5.0, -3.0], ["proche_rocher", -6.6, 3.4],
	# P5.3-B : zone pilote des textures peintes (centre (-10, 1), rayon 8 m)
	["pilote_chemin", -10.2, -0.4], ["pilote_herbe", -9.0, 4.2], ["pilote_nord", -11.0, -4.0]]


func _run() -> void:
	load("res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.gd").set("demarrage_v09c6", true)
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	await _tap(KEY_H)
	_variante_ombre()
	var seuls := []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--points="):
			seuls = a.substr(9).split(",")
	for p in POINTS:
		if seuls.is_empty() or p[0] in seuls:
			await _vue(p[0], p[1], p[2])
	if "pilote_large" in seuls:
		await _tap(KEY_1)
		await _vue("pilote_large", -10.0, 1.0)
	if seuls.is_empty() or "large" in seuls:
		await _tap(KEY_1)
		await _tap(KEY_4)
		await _vue("large", -2.0, 0.5)
	quit()


## diagnostic P5.3 des ombres du terrain : --ombre=aucune (P5.2) | directe (le terrain projette son ombre, état qui
## donnait des hachures) | proxy (copie du terrain, ombre seule, abaissée de --abaisse m) ; --angulaire=<°> (taille
## du soleil : ombres douces PCSS) ; --biais_normal=<x>
func _variante_ombre() -> void:
	var mode := ""
	var abaisse := 0.12
	var sun: DirectionalLight3D = null
	for c in sc.get_children():
		if c is DirectionalLight3D:
			sun = c
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ombre="):
			mode = a.substr(8)
		elif a.begins_with("--abaisse="):
			abaisse = float(a.substr(10))
		elif a.begins_with("--angulaire="):
			sun.light_angular_distance = float(a.substr(12))
		elif a.begins_with("--occ_mode="):          # diagnostic : "trame" (Bayer, validé) ou "alpha" (repli existant)
			(sc.get("_occ")).set("mode", a.substr(11))
		elif a == "--occlusion=0":                 # diagnostic : occlusion dynamique coupée (touche O)
			(sc.get("_occ")).set("enabled", false)
		elif a == "--soleil_sans_ombre":            # diagnostic : aucune ombre du soleil
			sun.shadow_enabled = false
		elif a == "--sans_silhouettes":             # diagnostic : silhouettes d'occlusion des personnages masquées
			for n in ["_hero_ghost", "_ilya_ghost"]:
				var g = sc.get(n)
				if g != null:
					(g as Node3D).visible = false
					(g as Node3D).set_meta("cache", true)
		elif a.begins_with("--zoom="):              # 1 (×2) | 2 (×2,5) | 3 (×3, démarrage)
			sc.set("_zoom", {"1": 2.0, "2": 2.5, "3": 3.0}[a.substr(7)])
		elif a.begins_with("--etalon="):            # P5.3-B : couleur unie r,g,b (sRGB 0-255) à la place des textures
			var c := a.substr(9).split(",")
			(sc.get("_sol").get("materiau_p53b") as ShaderMaterial).set_shader_parameter("etalon", Color8(int(c[0]), int(c[1]), int(c[2])))
		elif a.begins_with("--calage=") or a.begins_with("--anti_repetition="):
			var kv := a.substr(2).split("=")
			(sc.get("_sol").get("materiau_p53b") as ShaderMaterial).set_shader_parameter(kv[0], float(kv[1]))
		elif a.begins_with("--gain="):
			(sc.get("_sol").get("materiau_p53b") as ShaderMaterial).set_shader_parameter("gain_peint", float(a.substr(7)))
		elif a == "--pilote=carte":                 # P5.3-B : textures peintes sur toute la carte (touche Y)
			sc.call("set_pilote_carte_entiere", true)
		elif a.begins_with("--sol="):               # P5.3 : p53 | p52 | v07
			sc.call("set_version_sol", a.substr(6))
		elif a.begins_with("--qualite="):          # filtre des ombres douces : 0 dur … 5 ultra (défaut du projet : 2)
			RenderingServer.directional_soft_shadow_filter_set_quality(int(a.substr(10)))
		elif a.begins_with("--biais_normal="):
			sun.shadow_normal_bias = float(a.substr(15))
	var t: MeshInstance3D = sc.get("_terrain_mi")
	if mode == "directe":
		t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	elif mode == "proxy":
		var p := MeshInstance3D.new()
		p.mesh = t.mesh
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		t.add_child(p)
		p.position = Vector3(0, -abaisse, 0)
	print("ombre terrain : %s ; soleil angulaire %.1f, biais %.2f, biais normal %.2f" % [mode if mode != "" else "aucune", sun.light_angular_distance, sun.shadow_bias, sun.shadow_normal_bias])


func _vue(nom: String, x: float, z: float) -> void:
	_place(x, z)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, (sc.get("_ilya") as Node3D).global_position)
	await _frames(20)
	sc.set_physics_process(false)
	sc.call("_update_camera", 1.0)
	await _frames(4)
	await _snap(nom)
	sc.set_physics_process(true)
