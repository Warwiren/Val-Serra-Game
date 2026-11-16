extends "res://tools/p49/locomotion_ab_v09.gd"
## V09B.5 — cycles candidats d'Aren (marche / course, profil droit) dans la vraie scène F5, comparés à P4.8, aux
## vitesses actuelles (2,2 / 3,6 m/s) et candidates (2,8 / 4,5 m/s). Mêmes commandes clavier pour chaque réglage.
##   godot --headless --path . --fixed-fps 60 --script res://tools/p49/animations_v09b5.gd -- --out=<dossier>
##   godot --path . --rendering-method forward_plus --write-movie v.avi --fixed-fps 30 \
##       --script res://tools/p49/animations_v09b5.gd -- --film=P48:actuel|V09B5:actuel|V09B5:candidat [--format=64x72]
##   godot --path . --rendering-method forward_plus --script res://tools/p49/animations_v09b5.gd -- --out=<d> --captures
## Mesures : vitesse réelle, cadence (images/s, cycles/s), glissement résiduel du pied d'appui image par image
## (distance parcourue pendant l'image − recul dessiné du pied d'appui), départ, arrêt, demi-tour, virage brusque,
## parcours près des arbres et rochers, distance d'Ilya en course. Ne valide pas le rendu.

var film_cfg := ""
var film_format := "96x112"
var cad: Dictionary


func _run() -> void:
	cad = JSON.parse_string(FileAccess.get_file_as_string("res://art/tests/v09b5_aren/cadence_v09b5.json"))
	var caps := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--film="):
			film_cfg = a.substr(7)
		if a.begins_with("--format="):
			film_format = a.substr(9)
		caps = caps or a == "--captures"
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	if film_cfg != "":
		var p := film_cfg.split(":")
		await _config(p[0] == "V09B5", film_format, p[1] == "candidat")
		await _sequence_film_b5()
		quit()
		return
	if caps:
		await _captures()
		quit()
		return
	res = {}
	for c in [["P48", "96x112", false], ["P48", "96x112", true], ["V09B5", "96x112", false], ["V09B5", "96x112", true],
			["V09B5", "64x72", false], ["V09B5", "64x72", true]]:
		await _config(c[0] == "V09B5", c[1], c[2])
		var nom := "%s_%s_%s" % [c[0], c[1] if c[0] == "V09B5" else "", "candidat" if c[2] else "actuel"]
		res[nom.replace("__", "_")] = await _serie()
	await _config(false, "96x112", false)
	var f := FileAccess.open(out.path_join("animations_v09b5.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(res, " "))
	_resume()
	quit()


## état voulu, atteint par les touches du jeu (B : animations, T : format, P : vitesses)
func _config(v09b5: bool, fmt: String, candidat: bool) -> void:
	if bool(sc.get("_v09b5_on")) != v09b5:
		await _tap(KEY_B)
	var a: RefCounted = sc.get("_anim_v09b5")
	if String(a.get("format")) != fmt:
		await _tap(KEY_T)
	if (String(sc.get("_speed_profile")) == "candidat") != candidat:
		await _tap(KEY_P)


func _a5() -> RefCounted:
	return sc.get("_anim_v09b5")


func _serie() -> Dictionary:
	var r := {}
	r["ligne_marche"] = await _ligne(false)
	r["ligne_course"] = await _ligne(true)
	r["demarrage_arret"] = await _demarrage_arret_b5()
	r["demi_tour"] = await _demi_tour_b5()
	r["virage_brusque"] = await _virage_brusque()
	r["ilya_course_4s"] = await _ilya_course()
	if bool(sc.get("_v09b5_on")):
		_key(KEY_SHIFT, false)
		r["autour_tronc"] = await _parcours("autour d'un tronc", Vector2(-5.2, 5.4), [], [Vector2(-2.7, 5.25), Vector2(-1.55, 4.2), Vector2(-1.6, 2.6)])
		r["courbe_rocher"] = await _parcours("courbe autour d'un rocher", Vector2(7.2, 9.0), [], [Vector2(9.0, 8.4), Vector2(11.5, 8.5), Vector2(12.6, 9.6)])
		_key(KEY_SHIFT, true)
		r["courbe_rocher_course"] = await _parcours("courbe autour d'un rocher, course", Vector2(7.2, 9.0), [], [Vector2(9.0, 8.4), Vector2(11.5, 8.5), Vector2(12.6, 9.6)])
		_key(KEY_SHIFT, false)
		r["contacts_aren"] = _contacts.duplicate()
	return r


var _contacts := {}

func _note_contacts() -> void:
	var h := _hero()
	for k in h.get_slide_collision_count():
		var n := _nature(h.get_slide_collision(k).get_collider() as Node)
		if not n.begins_with("Terrain"):
			_contacts[n] = _contacts.get(n, 0) + 1


## ligne droite vers +X sur le chemin principal : vitesse, cadence, glissement du pied d'appui
func _ligne(run: bool) -> Dictionary:
	_place(-12.0, -0.5)
	await _frames(30)
	_key(KEY_SHIFT, run)
	_steer(Vector3(1, 0, 0))
	await _frames(45)                              # mise en vitesse
	var anim_base: RefCounted = sc.get("_hero_anim")
	var p0 := _hero().global_position
	var x_prec := p0
	var changements := 0
	var img_prec := -1
	var tex_prec: Texture2D = null
	var d_img := 0.0
	var glis: Array = []
	var v_sum := 0.0
	var n := 150
	var rec_key := "run" if run else "walk"
	for i in n:
		await _frames(1)
		_note_contacts()
		var p := _hero().global_position
		var d := Vector2(p.x - x_prec.x, p.z - x_prec.z).length()
		x_prec = p
		v_sum += Vector2(_hero().get_real_velocity().x, _hero().get_real_velocity().z).length()
		var a5 := _a5()
		var tex: Texture2D = (sc.get("_hero_sprite") as Sprite3D).texture
		var img: int = int(a5.get("frame")) if bool(a5.get("active")) else int(anim_base.get("frame"))
		if tex != tex_prec and tex_prec != null:
			changements += 1
			if bool(a5.get("active")) and img_prec >= 0:
				var rec: Variant = cad["formats"][String(a5.get("format"))][rec_key]["recul_pied_appui_px_par_image"][img_prec]
				if rec != null:
					glis.append({"image": img_prec, "parcouru_m": snappedf(d_img, 0.001), "recul_dessine_m": snappedf(float(rec) * 0.02, 0.001),
						"glissement_m": snappedf(d_img - float(rec) * 0.02, 0.001)})
			d_img = 0.0
		d_img += d
		img_prec = img
		tex_prec = tex
	var p1 := _hero().global_position
	var actif := bool(_a5().get("active"))
	var base_anim := String(anim_base.get("anim"))
	var stride: float = _a5().call("stride_m")
	_stop()
	_key(KEY_SHIFT, false)
	await _frames(40)
	var dist := Vector2(p1.x - p0.x, p1.z - p0.z).length()
	var gmax := 0.0
	var gsum := 0.0
	for g in glis:
		gmax = maxf(gmax, absf(g["glissement_m"]))
		gsum += absf(g["glissement_m"])
	var r := {"vitesse_mesuree_m_s": snappedf(dist / (n / 60.0), 0.01), "vitesse_moy_reelle_m_s": snappedf(v_sum / n, 0.01),
		"images_par_s": snappedf(changements / (n / 60.0), 0.1), "sprite_v09b5": actif, "anim_base": base_anim}
	if actif:
		r["foulee_m"] = snappedf(stride, 0.01)
		r["cycles_par_s"] = snappedf(r["vitesse_mesuree_m_s"] / stride, 0.01)
		r["glissement_max_m"] = snappedf(gmax, 0.001)
		r["glissement_moyen_m"] = snappedf(gsum / maxf(1, glis.size()), 0.001)
		r["glissement_par_image"] = _par_image(glis)
	return r


func _par_image(glis: Array) -> Dictionary:
	var m := {}
	for g in glis:
		var k := str(g["image"])
		m[k] = g                                 # dernière occurrence : image vue en entier, à vitesse établie
	return m


## départ depuis l'arrêt, arrêt : première image de cycle, temps jusqu'à l'attente, taille du sprite avant / après
func _demarrage_arret_b5() -> Dictionary:
	_place(-12.0, -0.5)
	await _frames(40)
	var spr := sc.get("_hero_sprite") as Sprite3D
	var h_repos := spr.texture.get_height()
	_steer(Vector3(1, 0, 0))
	await _frames(1)
	var premiere := int(_a5().get("frame")) if bool(_a5().get("active")) else int((sc.get("_hero_anim") as RefCounted).get("frame"))
	var h_marche := spr.texture.get_height()
	await _frames(80)
	_stop()
	var t_attente := -1.0
	for i in 60:
		await _frames(1)
		if t_attente < 0.0 and String((sc.get("_hero_anim") as RefCounted).get("anim")).begins_with("idle"):
			t_attente = (i + 1) / 60.0
	return {"premiere_image": premiere, "hauteur_texture_repos_px": h_repos, "hauteur_texture_marche_px": h_marche,
		"passage_attente_s": snappedf(t_attente, 0.01), "hauteur_texture_apres_arret_px": spr.texture.get_height()}


## demi-tour en marche puis en course : alternance des jeux de sprites (droite V09B.5 / gauche P4.8)
func _demi_tour_b5() -> Dictionary:
	_place(-9.0, -0.5)
	await _frames(30)
	var spr := sc.get("_hero_sprite") as Sprite3D
	var bascules := 0
	var prec := -1
	var r := {}
	for run in [false, true]:
		_key(KEY_SHIFT, run)
		for seg in [[Vector3(1, 0, 0), 60], [Vector3(-1, 0, 0), 60], [Vector3(1, 0, 0), 60]]:
			_steer(seg[0])
			for i in seg[1]:
				await _frames(1)
				_note_contacts()
				var h := spr.texture.get_height()
				if prec >= 0 and h != prec:
					bascules += 1
				prec = h
		r["course" if run else "marche"] = bascules
		bascules = 0
	_stop()
	_key(KEY_SHIFT, false)
	await _frames(30)
	return {"changements_de_jeu_de_sprites": r}


## changement brusque : droite -> haut de l'écran -> droite
func _virage_brusque() -> Dictionary:
	_place(-12.0, -0.5)
	await _frames(30)
	var dirs: Array = []
	for seg in [[Vector3(1, 0, 0), 50], [Vector3(0, 0, -1), 30], [Vector3(1, 0, 0), 50], [Vector3(0, 0, 1), 20], [Vector3(1, 0, 0), 40]]:
		_steer(seg[0])
		for i in seg[1]:
			await _frames(1)
			_note_contacts()
		dirs.append(String((sc.get("_hero_anim") as RefCounted).get("anim")) + (" + V09B.5" if bool(_a5().get("active")) else ""))
	_stop()
	await _frames(30)
	return {"animation_en_fin_de_segment": dirs}


## course droite de 4 s : distance Aren–Ilya (le plafond de suivi d'Ilya en V09A est 4,25 m/s)
func _ilya_course() -> Dictionary:
	_place(-15.0, -0.5)
	_ilya().global_position = _hero().global_position + Vector3(-1.2, 0, 0)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, _ilya().global_position)
	await _frames(30)
	_key(KEY_SHIFT, true)
	_steer(Vector3(1, 0, 0))
	var d := []
	for i in 240:
		await _frames(1)
		if i % 60 == 59:
			var h := _hero().global_position
			var il := _ilya().global_position
			d.append(snappedf(Vector2(h.x - il.x, h.z - il.z).length(), 0.01))
	_stop()
	_key(KEY_SHIFT, false)
	var t_rejoint := -1.0
	for i in 180:
		await _frames(1)
		var h := _hero().global_position
		var il := _ilya().global_position
		if t_rejoint < 0.0 and Vector2(h.x - il.x, h.z - il.z).length() < 1.6:
			t_rejoint = (i + 1) / 60.0
	return {"distance_aren_ilya_chaque_s_m": d, "ilya_revenue_a_1_6_m_apres_arret_s": snappedf(t_rejoint, 0.01)}


# ---------------------------------------------------------------------------------------------------- film
## même séquence de commandes pour chaque réglage ; caméra validée (30°, ×2,5) ; sans HUD (titre ajouté au montage)
func _sequence_film_b5() -> void:
	await _tap(KEY_H)
	_place(-14.0, -0.5)
	_ilya().global_position = _hero().global_position + Vector3(-1.2, 0, 0)
	(sc.get("_v09_trail") as RefCounted).call("reset", _hero().global_position, _ilya().global_position)
	await _frames(40)
	for seg in [[Vector3(1, 0, 0), 150, false], [Vector3.ZERO, 50, false], [Vector3(1, 0, 0), 120, true], [Vector3.ZERO, 50, false],
			[Vector3(-1, 0, 0), 50, false], [Vector3(1, 0, 0), 60, false], [Vector3(0, 0, -1), 30, false], [Vector3(1, 0, 0), 60, false],
			[Vector3(-1, 0, 0), 40, true], [Vector3(1, 0, 0), 60, true], [Vector3.ZERO, 60, false]]:
		_key(KEY_SHIFT, seg[2])
		if seg[0] == Vector3.ZERO:
			_stop()
		else:
			_steer(seg[0])
		await _frames(seg[1])
	_key(KEY_SHIFT, false)
	_stop()
	await _frames(20)


# ---------------------------------------------------------------------------------------------------- captures
## captures en taille réelle, trois zooms, marche et course (images de contact et d'envol), P4.8 et V09B.5
func _captures() -> void:
	await _tap(KEY_H)
	for z in [[KEY_1, "x2"], [KEY_2, "x2-5"], [KEY_3, "x3"]]:
		await _tap(z[0])
		for c in [["P48", "96x112"], ["V09B5", "96x112"], ["V09B5", "64x72"]]:
			await _config(c[0] == "V09B5", c[1], false)
			for run in [false, true]:
				_place(-12.0, -0.5)
				await _frames(20)
				_key(KEY_SHIFT, run)
				_steer(Vector3(1, 0, 0))
				await _frames(50)
				_stop()                                # gel sur une image de cycle : on fige le personnage
				_key(KEY_SHIFT, false)
				sc.set_physics_process(false)
				sc.call("_update_camera", 1.0)
				var nom := "%s_%s_%s_%s" % [z[1], c[0], c[1] if c[0] == "V09B5" else "128x96", "course" if run else "marche"]
				await _snap(nom)
				sc.set_physics_process(true)
	await _config(false, "96x112", false)
