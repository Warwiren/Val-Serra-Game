extends "res://tools/p49/locomotion_ab_v09.gd"
## V09C — banc d'essai d'Ilya dans la vraie scène F5 : Aren en V09B.5 96×112 ×0,719 (référence retenue), vitesses
## d'essai 2,8 / 4,5 m/s ; Ilya P4.8 ou nouvelle apparence (touche I). Mêmes commandes clavier dans les deux cas.
##   godot --headless --path . --fixed-fps 60 --script res://tools/p49/ilya_v09c.gd -- --out=<dossier>
##   godot --path . --rendering-method forward_plus --write-movie <d>/f.png --fixed-fps 30 \
##       --script res://tools/p49/ilya_v09c.gd -- --film=P48|V09C5|V09C6   (V09C = V09C5)
##   godot --path . --rendering-method forward_plus --script res://tools/p49/ilya_v09c.gd -- --out=<d> --captures

var film_ilya := ""


func _run() -> void:
	var caps := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--film="):
			film_ilya = a.substr(7)
		caps = caps or a == "--captures"
	if film_ilya == "ILYA_HAUT_BAS":
		# Ilya vers le bas / le haut (face / dos du pack, 20/11/2026), démarrage réel de F5, végétation masquée (N)
		load("res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.gd").set("demarrage_v09c6", true)
		change_scene_to_file(SCENE)
		await _frames(30)
		sc = current_scene
		await _tap(KEY_N)
		await _film_ilya_haut_bas()
		quit()
		return
	if film_ilya.begins_with("FACEDOS_"):
		# Aren vers le bas / vers le haut, démarrage réel de F5 ; jeu de vues face / dos : FACEDOS_V3 | _4DIR | _V2
		load("res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.gd").set("demarrage_v09c6", true)
		change_scene_to_file(SCENE)
		await _frames(30)
		sc = current_scene
		(sc.get("_anim_v09b5") as RefCounted).set("jeu_vues", film_ilya.substr(8).to_lower())
		await _film_haut_bas()
		quit()
		return
	if film_ilya in ["AVANT", "APRES"]:
		# démarrage réel de F5 (19/11/2026) ; AVANT = directions mélangées d'origine, APRES = profil unique
		load("res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.gd").set("demarrage_v09c6", true)
		change_scene_to_file(SCENE)
		await _frames(30)
		sc = current_scene
		if film_ilya == "AVANT":
			(sc.get("_anim_v09b5") as RefCounted).set("profil_unique", false)
			_c().set("profil_unique", false)
		await _film_directions()
		quit()
		return
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	await _reference_aren()
	if film_ilya != "":
		await _mode_ilya("V09C5" if film_ilya == "V09C" else film_ilya)
		await _film()
		quit()
		return
	if caps:
		await _captures_ilya()
		quit()
		return
	res = {}
	for m in ["P48", "V09C5", "V09C6"]:
		await _mode_ilya(m)
		res[m] = await _serie_ilya()
	await _mode_ilya("P48")
	var f := FileAccess.open(out.path_join("ilya_v09c.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(res, " "))
	_resume()
	quit()


## Aren : V09B.5, format « hauteur 64 px », vitesses candidates (références d'essai du 19/11/2026)
func _reference_aren() -> void:
	if not bool(sc.get("_v09b5_on")):
		await _tap(KEY_B)
	var a: RefCounted = sc.get("_anim_v09b5")
	for k in (a.get("formats") as Array).size():
		if String(a.get("format")) == "96x112_h64":
			break
		await _tap(KEY_T)
	if String(sc.get("_speed_profile")) != "candidat":
		await _tap(KEY_P)


## Ilya : "P48", "V09C5" ou "V09C6" (course droite V09C.6), atteint par la touche I (cycle de 3 états)
func _mode_ilya(m: String) -> void:
	for k in 3:
		if _etat_ilya() == m:
			return
		await _tap(KEY_I)


func _etat_ilya() -> String:
	if not bool(sc.get("_v09c_on")):
		return "P48"
	return "V09C6" if bool(_c().get("course_v09c6")) else "V09C5"


func _c() -> RefCounted:
	return sc.get("_ilya_v09c")


func _serie_ilya() -> Dictionary:
	var r := {}
	r["ligne_marche"] = await _suivi_ligne(false)
	r["ligne_course"] = await _suivi_ligne(true)
	r["arret_et_demi_tour"] = await _arret_demi_tour()
	r["marche_course_marche"] = await _transitions()
	r["autour_tronc"] = await _parcours("autour d'un tronc", Vector2(-5.2, 5.4), [], [Vector2(-2.7, 5.25), Vector2(-1.55, 4.2), Vector2(-1.6, 2.6)])
	_key(KEY_SHIFT, true)
	r["courbe_rocher_course"] = await _parcours("courbe autour d'un rocher, course", Vector2(7.2, 9.0), [], [Vector2(9.0, 8.4), Vector2(11.5, 8.5), Vector2(12.6, 9.6)])
	_key(KEY_SHIFT, false)
	return r


## Aren part vers +X (profil droit) ; Ilya suit. Mesures sur Ilya : vitesse, cycle choisi, bascules marche / course,
## cadence, glissement du pied d'appui au profil droit (distance parcourue pendant une image − recul dessiné).
func _suivi_ligne(run: bool) -> Dictionary:
	_place(-15.0, -0.5)
	_ilya().global_position = _hero().global_position + Vector3(-1.2, 0, 0)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, _ilya().global_position)
	await _frames(30)
	_key(KEY_SHIFT, run)
	_steer(Vector3(1, 0, 0))
	await _frames(60)
	var c := _c()
	var spr := (_ilya() as Node).get_node("Pixel_Sprite_ilya") as Sprite3D
	var p_prec := _ilya().global_position
	var p0 := p_prec
	var cycles := {}
	var bascules := 0
	var cyc_prec := ""
	var changements := 0
	var tex_prec: Texture2D = null
	var img_prec := -1
	var d_img := 0.0
	var glis: Array = []
	var dist_ai: Array = []
	var haut_img := {}
	var t_envol := 0
	var n := 180
	for i in n:
		await _frames(1)
		var p := _ilya().global_position
		var d := Vector2(p.x - p_prec.x, p.z - p_prec.z).length()
		p_prec = p
		var cyc := String(c.get("cycle")) if bool(sc.get("_v09c_on")) else String((sc.get("_ilya_anim") as RefCounted).get("anim"))
		cycles[cyc] = cycles.get(cyc, 0) + 1
		if cyc_prec != "" and cyc != cyc_prec:
			bascules += 1
		cyc_prec = cyc
		var tex := spr.texture
		if tex != tex_prec and tex_prec != null:
			changements += 1
			if bool(sc.get("_v09c_on")) and String(c.get("dir")) == "right" and img_prec >= 0 and changements > 1:
				var rec: Variant = c.call("recul_px", img_prec)
				if rec != null:
					glis.append(d_img - float(rec) * float(c.call("pixel_m")))
			d_img = 0.0
		d_img += d
		img_prec = int(c.get("frame"))
		tex_prec = tex
		if bool(sc.get("_v09c_on")):
			var hv := _hauteur_affichee(tex, float(c.call("pixel_m")))
			haut_img[img_prec] = hv
			if hv.y > 0.5:
				t_envol += 1
		if i % 60 == 59:
			var h := _hero().global_position
			dist_ai.append(snappedf(Vector2(h.x - p.x, h.z - p.z).length(), 0.01))
	var p1 := _ilya().global_position
	var foulee := float(c.call("stride_m")) if bool(sc.get("_v09c_on")) else 0.0
	_stop()
	_key(KEY_SHIFT, false)
	await _frames(60)
	var r := {"ilya_vitesse_m_s": snappedf(Vector2(p1.x - p0.x, p1.z - p0.z).length() / (n / 60.0), 0.01),
		"ilya_images_par_s": snappedf(changements / (n / 60.0), 0.1), "ilya_cycles_vus": cycles,
		"ilya_bascules_de_cycle": bascules, "distance_aren_ilya_m": dist_ai}
	if not glis.is_empty():
		var gs := 0.0
		var gm := 0.0
		for g in glis:
			gs += absf(g)
			gm = maxf(gm, absf(g))
		r["ilya_glissement_moyen_m"] = snappedf(gs / glis.size(), 0.001)
		r["ilya_glissement_max_m"] = snappedf(gm, 0.001)
		r["ilya_foulee_m"] = snappedf(foulee, 0.01)
	if bool(sc.get("_v09c_on")):
		var hs := {}
		for k in haut_img:
			hs[str(k)] = [snappedf(haut_img[k].x, 0.1), snappedf(haut_img[k].y, 0.1)]
		r["ilya_hauteur_affichee_px_et_envol_px_par_image"] = hs
		r["ilya_part_du_temps_en_envol_pc"] = snappedf(100.0 * t_envol / n, 0.1)
	return r


## hauteur visible à l'écran (px au ×2,5 : 1 px = 0,02 m) et hauteur des pieds au-dessus du sol (px d'écran)
var _cache_h := {}
func _hauteur_affichee(tex: Texture2D, pixel_m: float) -> Vector2:
	if not _cache_h.has(tex):
		var r := tex.get_image().get_used_rect()
		_cache_h[tex] = r
	var used: Rect2i = _cache_h[tex]
	var c := _c()
	var sol: float = float(c.get("_cad6")["run_right"]["ligne_sol_px"]) if bool(c.call("run_v09c6")) else float(c.get("_cad")["directions"][String(c.get("dir"))][String(c.get("cycle"))]["ligne_sol_px"])
	var k := pixel_m / 0.02
	return Vector2((sol - used.position.y) * k, (sol - used.end.y) * k)


## Aren marche 2 s, court 2 s, marche 2 s : bascules du cycle d'Ilya (attendu : 2), délai après le changement d'Aren
func _transitions() -> Dictionary:
	_place(-15.0, -0.5)
	_ilya().global_position = _hero().global_position + Vector3(-1.2, 0, 0)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, _ilya().global_position)
	await _frames(30)
	var seq: Array = []
	var prec := ""
	var t := 0
	for seg in [[false, 120], [true, 120], [false, 120]]:
		_key(KEY_SHIFT, seg[0])
		_steer(Vector3(1, 0, 0))
		for i in seg[1]:
			await _frames(1)
			t += 1
			var cyc := String(_c().get("cycle")) if bool(sc.get("_v09c_on")) else String((sc.get("_ilya_anim") as RefCounted).get("anim"))
			if cyc != prec:
				seq.append([snappedf(t / 60.0, 0.01), cyc])
				prec = cyc
	_stop()
	_key(KEY_SHIFT, false)
	await _frames(60)
	return {"cycles_d_ilya_et_instant_s": seq, "aren_change_d_allure_a_s": [2.0, 4.0]}


func _arret_demi_tour() -> Dictionary:
	_place(-12.0, -0.5)
	_ilya().global_position = _hero().global_position + Vector3(-1.2, 0, 0)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, _ilya().global_position)
	await _frames(30)
	var vus := {}
	var hauteurs := {}
	var spr := (_ilya() as Node).get_node("Pixel_Sprite_ilya") as Sprite3D
	for seg in [[Vector3(1, 0, 0), 90], [Vector3.ZERO, 60], [Vector3(-1, 0, 0), 90], [Vector3(0, 0, -1), 50], [Vector3(0, 0, 1), 50], [Vector3.ZERO, 60]]:
		if seg[0] == Vector3.ZERO:
			_stop()
		else:
			_steer(seg[0])
		for i in seg[1]:
			await _frames(1)
			var k := ("%s_%s" % [_c().get("cycle"), _c().get("dir")]) if bool(sc.get("_v09c_on")) else String((sc.get("_ilya_anim") as RefCounted).get("anim"))
			vus[k] = vus.get(k, 0) + 1
			if bool(sc.get("_v09c_on")):
				var hv := _hauteur_affichee(spr.texture, float(_c().call("pixel_m")))
				var mm: Array = hauteurs.get(k, [999.0, 0.0])
				hauteurs[k] = [minf(mm[0], hv.x), maxf(mm[1], hv.x)]
	_stop()
	return {"etats_ilya_vus_images": vus, "hauteur_affichee_px_min_max_par_etat": hauteurs, "hauteur_texture_finale": spr.texture.get_height(), "taille_pixel_finale": snappedf(spr.pixel_size, 0.0001)}


# ---------------------------------------------------------------------------------------------------- film
## même séquence pour Ilya P4.8 et V09C : marche, arrêt (attente), course, arrêt, demi-tour, haut, bas, course, arrêt
func _film() -> void:
	await _tap(KEY_H)
	_place(-14.0, -0.5)
	_ilya().global_position = _hero().global_position + Vector3(-1.2, 0, 0)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, _ilya().global_position)
	await _frames(40)
	for seg in [[Vector3(1, 0, 0), 150, false], [Vector3.ZERO, 70, false], [Vector3(1, 0, 0), 110, true], [Vector3.ZERO, 60, false],
			[Vector3(-1, 0, 0), 80, false], [Vector3(0, 0, -1), 45, false], [Vector3(0, 0, 1), 60, false], [Vector3(1, 0, 0), 90, true],
			[Vector3.ZERO, 80, false]]:
		_key(KEY_SHIFT, seg[2])
		if seg[0] == Vector3.ZERO:
			_stop()
		else:
			_steer(seg[0])
		await _frames(seg[1])
	_key(KEY_SHIFT, false)
	_stop()
	await _frames(20)


## toutes les directions, arrêts compris, à la caméra et aux vitesses du démarrage (24°, ×3, 2,2 / 3,6 m/s)
func _film_directions() -> void:
	await _tap(KEY_H)
	_place(-12.0, -0.5)
	_ilya().global_position = _hero().global_position + Vector3(-1.2, 0, 0)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, _ilya().global_position)
	await _frames(40)
	for seg in [[Vector3(1, 0, 0), 120, false], [Vector3.ZERO, 60, false], [Vector3(-1, 0, 0), 110, false], [Vector3.ZERO, 50, false],
			[Vector3(0, 0, 1), 70, false], [Vector3(0, 0, -1), 70, false], [Vector3(1, 0, 0), 90, true], [Vector3(-1, 0, 0), 90, true],
			[Vector3(0, 0, 1), 60, true], [Vector3.ZERO, 80, false]]:
		_key(KEY_SHIFT, seg[2])
		if seg[0] == Vector3.ZERO:
			_stop()
		else:
			_steer(seg[0])
		await _frames(seg[1])
	_key(KEY_SHIFT, false)
	_stop()
	await _frames(20)


## Ilya suit Aren vers le bas puis vers le haut : marche, arrêt (attentes), course
func _film_ilya_haut_bas() -> void:
	await _tap(KEY_H)
	_place(-4.0, -6.0)
	_ilya().global_position = _hero().global_position + Vector3(0.5, 0, -1.4)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, _ilya().global_position)
	await _frames(20)
	for seg in [[Vector3(0, 0, 1), 110, false], [Vector3.ZERO, 70, false], [Vector3(0, 0, -1), 110, false], [Vector3.ZERO, 70, false],
			[Vector3(0, 0, 1), 70, true], [Vector3(0, 0, -1), 70, true], [Vector3.ZERO, 50, false]]:
		_key(KEY_SHIFT, seg[2])
		if seg[0] == Vector3.ZERO:
			_stop()
		else:
			_steer(seg[0])
		await _frames(seg[1])
	_key(KEY_SHIFT, false)
	_stop()


## vers le bas et vers le haut seulement : marche, arrêt, course, arrêt (24°, ×3, 2,2 / 3,6 m/s)
func _film_haut_bas() -> void:
	await _tap(KEY_H)
	_place(-12.0, -0.5)
	_ilya().global_position = _hero().global_position + Vector3(-1.6, 0, -0.6)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, _ilya().global_position)
	await _frames(30)
	for seg in [[Vector3(0, 0, 1), 75, false], [Vector3.ZERO, 30, false], [Vector3(0, 0, -1), 75, false], [Vector3.ZERO, 30, false],
			[Vector3(0, 0, 1), 50, true], [Vector3.ZERO, 25, false], [Vector3(0, 0, -1), 50, true], [Vector3.ZERO, 40, false]]:
		_key(KEY_SHIFT, seg[2])
		if seg[0] == Vector3.ZERO:
			_stop()
		else:
			_steer(seg[0])
		await _frames(seg[1])
	_key(KEY_SHIFT, false)
	_stop()
	await _frames(10)


# ---------------------------------------------------------------------------------------------------- captures
func _captures_ilya() -> void:
	await _tap(KEY_H)
	for z in [[KEY_2, "x2-5"], [KEY_3, "x3"], [KEY_1, "x2"]]:
		await _tap(z[0])
		for m in ["V09C5", "V09C6"]:
			await _mode_ilya(m)
			for etat in ["marche", "course", "arret"]:
				_place(-12.0, -0.5)
				_ilya().global_position = _hero().global_position + Vector3(-1.2, 0, 0)
				(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, _ilya().global_position)
				await _frames(20)
				_key(KEY_SHIFT, etat == "course")
				_steer(Vector3(1, 0, 0))
				await _frames(70)
				if etat == "arret":
					_stop()
					await _frames(60)
				_stop()
				_key(KEY_SHIFT, false)
				sc.set_physics_process(false)
				sc.call("_update_camera", 1.0)
				await _snap("%s_ilya_%s_%s" % [z[1], m, etat])
				sc.set_physics_process(true)
	await _mode_ilya("P48")
