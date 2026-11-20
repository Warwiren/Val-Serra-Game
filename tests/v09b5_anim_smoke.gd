extends SceneTree
## V09B.5 — test rapide de l'essai réversible des cycles candidats d'Aren (Godot 4.7.2) :
##   godot --headless --path . --script res://tests/v09b5_anim_smoke.gd
## Vérifie : les 32 images candidates se chargent, sans toucher aux sprites P4.8 ; la cadence suit la distance ;
## seul « walk_right » est remplacé ; pieds posés au sol ; la scène F5 démarre en P4.8 aux vitesses actuelles.
const A5 = preload("res://src/explore25/anim_v09b5.gd")
const Actor25 = preload("res://src/explore25/actor25.gd")
const SCENE := "res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.tscn"
var failures := 0


func _test(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("V09B.5 ECHEC : " + label)
	else:
		print("V09B.5 OK : " + label)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var a = A5.make()
	a.profil_unique = false                   # mode d'origine (V09B.5 au seul profil droit) ; profil unique testé plus bas
	var n := 0
	for f in A5.FORMATS:
		for c in ["walk", "run"]:
			for i in 8:
				var t: Texture2D = load(A5.DIR + "%s_%s/%s_right_%d.png" % [c, f, c, i])
				if t != null and t.get_size() == (Vector2(96, 112) if f == "96x112" else Vector2(64, 72)):
					n += 1
	_test(n == 32, "32 images candidates (2 formats × marche/course × 8)")
	_test(ResourceLoader.exists("res://art/p45/chars/aren/walk_right_7.png"), "sprites P4.8 d'Aren toujours présents")

	# pieds : ligne de sol posée sur l'origine du corps (sprite centré à 0,96 m)
	for f in A5.FORMATS:
		a.format = f
		var tex: Texture2D = a._tex["walk_" + f][0]
		var ofs: Vector2 = a.offset_px(0.96, tex)
		var ground_px: float = float(a._cad["formats"][f]["ligne_sol_px"])
		var foot_y := 0.96 + (ofs.y + tex.get_height() * 0.5 - ground_px) * 0.02
		_test(absf(foot_y) < 0.0001, "pieds au sol, format %s (y = %.4f m)" % [f, foot_y])
	a.format = "96x112"

	# cadence : un cycle complet = la foulée mesurée, quelle que soit la vitesse
	var base = Actor25.make("aren")
	base.set_scale_k(25.2 / 63.0)
	var step_m := 0.02
	var seen := {}
	var moved := 0.0
	for i in 200:
		base.step(step_m, Vector2(1, 0), 1.0 / 60.0)
		a.step(base, step_m, false)
		moved += step_m
		seen[a.frame] = true
	_test(a.active and base.anim == "walk_right", "profil droit : cycle candidat actif")
	_test(seen.size() == 8, "8 images parcourues en marche")
	var expected := fposmod(1.0 / 8.0 + (moved - step_m) / a.stride_m("walk"), 1.0)
	_test(absf(a.phase - expected) < 0.001, "phase = distance / foulée (%.3f)" % a.phase)
	a.step(base, step_m, true)
	_test(a.cycle == "run" and absf(a.stride_m() - 3.64) < 0.001, "course : cycle distinct, foulée 3,64 m (96×112)")
	base.step(step_m, Vector2(-1, 0), 1.0 / 60.0)
	a.step(base, step_m, false)
	_test(not a.active and base.anim == "walk_left", "profil gauche : P4.8 conservé")
	for i in 20:
		base.step(0.0, Vector2.ZERO, 1.0 / 60.0)
	a.step(base, 0.0, false)
	_test(not a.active and base.anim.begins_with("idle"), "attente : P4.8 conservée")

	# V09B.6 : calque d'échelle au gabarit P4.8 (128 × 96, sol en bas, 61 à 67 px de haut à la marche)
	_test("calque_64" in a.formats, "V09B.6 : calque 64 px disponible (touche T)")
	if "calque_64" in a.formats:
		a.format = "calque_64"
		var hmin := 999
		var hmax := 0
		for i in 8:
			var img: Image = (a._tex["walk_calque_64"][i] as Texture2D).get_image()
			var used := img.get_used_rect()
			hmin = mini(hmin, used.size.y)
			hmax = maxi(hmax, used.size.y)
			if img.get_size() != Vector2i(128, 96) or used.end.y != 96:
				hmin = -1                          # canevas ou ligne de sol hors gabarit : échec ci-dessous
		_test(hmin >= 61 and hmin <= 67, "calque marche : canevas 128×96, pieds sur la dernière rangée, hauteur %d–%d px (64 ± 5 %%)" % [hmin, hmax])
		_test(a.offset_px(0.96, a._tex["walk_calque_64"][0]) == Vector2.ZERO, "calque : même ancrage que P4.8 (décalage nul)")
		var ref: Image = (load("res://art/p45/chars/aren/idle_right.png") as Texture2D).get_image()
		_test(absi(ref.get_used_rect().size.y - hmin) <= 3, "calque vs Aren P4.8 : %d / %d px" % [hmin, ref.get_used_rect().size.y])
		a.format = "96x112"

	# V09B.5 « hauteur 64 px » : mêmes images 96 × 112, échelle d'affichage réduite, pieds et cadence recalés
	_test(A5.H64 in a.formats and a._tex["walk_" + A5.H64][0] == a._tex["walk_96x112"][0], "H64 : mêmes textures que le 96×112 (PNG inchangés)")
	a.format = A5.H64
	var hv: float = a.hauteur_v5_px * a.echelle_h64
	_test(a.echelle_h64 > 0.69 and a.echelle_h64 < 0.75 and absf(hv - a.hauteur_ref_px) < 0.5,
		"H64 : facteur ×%.3f (88-91 px -> %.1f px ; Aren P4.8 %d px)" % [a.echelle_h64, hv, a.hauteur_ref_px])
	var t0: Texture2D = a._tex["walk_" + A5.H64][0]
	var ofs: Vector2 = a.offset_px(0.96, t0)
	var foot: float = 0.96 + (ofs.y + t0.get_height() * 0.5 - float(a._cad["formats"][A5.H64]["ligne_sol_px"])) * a.pixel_m()
	_test(absf(foot) < 0.0001, "H64 : pieds au sol (y = %.4f m)" % foot)
	_test(absf(a.stride_m("walk") - 92 * 0.02 * a.echelle_h64) < 0.001, "H64 : foulée en mètres à la même échelle (%.2f m)" % a.stride_m("walk"))
	a.format = "96x112"

	# profil unique (19/11/2026) : profil droit V09B.5 dans toutes les directions, miroir à gauche, pose d'arrêt tenue
	var u = A5.make()
	u.format = A5.H64
	u.jeu_vues = "v2"                         # planche V2 (20/11) ; le jeu complet « 4dir » est testé plus bas
	var b2 = Actor25.make("aren")
	b2.set_scale_k(25.2 / 63.0)
	for i in 10:
		b2.step(0.04, Vector2(1, 0), 1.0 / 60.0)
		u.step(b2, 0.04, false, 1.0)
	var ox_d: float = u.offset_px(0.96, u.texture()).x
	b2.step(0.04, Vector2(-1, 0), 1.0 / 60.0)
	u.step(b2, 0.04, false, -1.0)
	_test(u.active and u.flip and u.cycle == "walk", "profil unique : vers la gauche, profil droit en miroir")
	_test(absf(u.offset_px(0.96, u.texture()).x + ox_d) < 0.001, "profil unique : axe de la tête sur le corps à droite comme en miroir (%.1f / %.1f px)" % [ox_d, u.offset_px(0.96, u.texture()).x])
	b2.step(0.04, Vector2(0, 1), 1.0 / 60.0)
	u.step(b2, 0.04, false, 0.0)
	_test(u.active and u.vue == "face" and not u.miroir() and u.texture() == u._tex["v2_walk_face"][u.frame], "vers le bas : marche de face V2 (même design, sans miroir)")
	for i in 20:
		b2.step(0.0, Vector2.ZERO, 1.0 / 60.0)
	u.step(b2, 0.0, false, 0.0)
	_test(u.vue == "face" and u.texture() == u._tex["v2_idle_face"][u.frame], "arrêt après le bas : attente de face V2")
	b2.step(0.04, Vector2(0, -1), 1.0 / 60.0)
	u.step(b2, 0.04, true, 0.0)
	_test(u.vue == "dos" and u.texture() == u._tex["v2_walk_back"][u.frame], "vers le haut (même en courant) : marche de dos V2")
	for i in 20:
		b2.step(0.0, Vector2.ZERO, 1.0 / 60.0)
	u.step(b2, 0.0, false, 0.0)
	_test(u.texture() == u._tex["v2_walk_back"][A5.IMAGE_ARRET_DOS], "arrêt après le haut : pose de dos tenue")
	b2.step(0.04, Vector2(1, 0), 1.0 / 60.0)
	u.step(b2, 0.04, false, 1.0)
	for i in 20:
		b2.step(0.0, Vector2.ZERO, 1.0 / 60.0)
	u.step(b2, 0.0, false, 0.0)
	_test(u.vue == "profil" and u.frame == A5.IMAGE_ARRET and u.texture() == u._tex["walk_" + A5.H64][A5.IMAGE_ARRET], "arrêt après la droite : pose de profil tenue (pas de P4.8)")
	var hv2: Array = []
	for k in ["v2_walk_face", "v2_walk_back", "v2_idle_face", "walk_" + A5.H64]:
		for t in u._tex[k]:
			hv2.append(roundf((101 - (t as Texture2D).get_image().get_used_rect().position.y) * u.echelle_h64))
	hv2.sort()
	_test(hv2[0] >= 61 and hv2[-1] <= 67, "face, dos, attente et profil : %d à %d px à l'écran (64 ± 5 %%)" % [hv2[0], hv2[-1]])

	# jeu complet d'orientations (défaut) : attentes de l'étude IDLE V1, marche / course de face et de dos procédurales
	var w = A5.make()
	w.format = A5.H64
	_test(w.jeu_vues == "v4" and w.v4_dispo and w.v3_dispo and w.d4_dispo, "marches face / dos dessinées V4 chargées par défaut")
	w.jeu_vues = "4dir"                       # jeu « 4dir » du 20/11 ; V3 testée plus bas
	var b4 = Actor25.make("aren")
	b4.set_scale_k(25.2 / 63.0)
	var vus := []
	for seg in [[Vector2(0, 1), false, "d4_walk_face"], [Vector2(0, 1), true, "d4_run_face"], [Vector2(0, -1), false, "d4_walk_back"], [Vector2(0, -1), true, "d4_run_back"], [Vector2(1, 0), false, "walk_" + A5.H64]]:
		for i in 6:
			b4.step(0.04, seg[0], 1.0 / 60.0)
			w.step(b4, 0.04, seg[1], seg[0].x)
		vus.append(w._cle == seg[2] and w.texture() == w._tex[seg[2]][w.frame])
	_test(vus == [true, true, true, true, true], "bas / haut, marche et course : cycles de face et de dos ; droite : V09B.5 (%s)" % [vus])
	for i in 20:
		b4.step(0.0, Vector2.ZERO, 1.0 / 60.0)
	w.step(b4, 0.0, false, 0.0)
	_test(w._cle == "d4_idle_right" and not w.flip, "arrêt après la droite : attente de profil de l'étude")
	b4.step(0.04, Vector2(-1, 0), 1.0 / 60.0)
	w.step(b4, 0.04, false, -1.0)
	for i in 20:
		b4.step(0.0, Vector2.ZERO, 1.0 / 60.0)
	w.step(b4, 0.0, false, 0.0)
	_test(w._cle == "d4_idle_right" and w.miroir(), "arrêt après la gauche : attente de profil en miroir")
	b4.step(0.04, Vector2(0, 1), 1.0 / 60.0)
	w.step(b4, 0.04, false, 0.0)
	for i in 20:
		b4.step(0.0, Vector2.ZERO, 1.0 / 60.0)
	w.step(b4, 0.0, false, 0.0)
	_test(w._cle == "d4_idle_face" and not w.miroir(), "arrêt après le bas : attente de face de l'étude")
	_test(w.stride_m() == w.stride_m("walk"), "face / dos : même foulée que le profil (même cadence dans toutes les directions)")
	var h4: Array = []
	for k in w._tex:
		if String(k).begins_with("d4_"):
			for t in w._tex[k]:
				h4.append(roundf((101 - (t as Texture2D).get_image().get_used_rect().position.y) * w.echelle_h64))
	h4.sort()
	_test(h4[0] >= 61 and h4[-1] <= 67, "jeu complet : %d à %d px à l'écran (64 ± 5 %%)" % [h4[0], h4[-1]])
	var i0: Image = (w._tex["d4_idle_face"][0] as Texture2D).get_image()
	var m0: Image = (w._tex["d4_walk_face"][0] as Texture2D).get_image()
	_test(i0.get_data() == m0.get_data(), "face : la marche part exactement de l'attente (image 0 identique, pas de saut)")

	# proposition V3 : face / dos en profondeur, attentes et profil du jeu 4dir
	var v = A5.make()
	v.format = A5.H64
	v.jeu_vues = "v3"
	var b5 = Actor25.make("aren")
	b5.set_scale_k(25.2 / 63.0)
	var vus3 := []
	for seg in [[Vector2(0, 1), false, "v3_walk_face"], [Vector2(0, 1), true, "v3_run_face"], [Vector2(0, -1), false, "v3_walk_back"], [Vector2(0, -1), true, "v3_run_back"], [Vector2(1, 0), false, "walk_" + A5.H64]]:
		for i in 6:
			b5.step(0.04, seg[0], 1.0 / 60.0)
			v.step(b5, 0.04, seg[1], seg[0].x)
		vus3.append(v._cle == seg[2] and v.texture() == v._tex[seg[2]][v.frame])
	_test(vus3 == [true, true, true, true, true], "V3 : bas / haut, marche et course en profondeur ; droite : V09B.5 (%s)" % [vus3])
	for i in 20:
		b5.step(0.0, Vector2.ZERO, 1.0 / 60.0)
	v.step(b5, 0.0, false, 0.0)
	_test(v._cle == "d4_idle_right", "V3 : attentes du jeu 4dir")
	var v0 = A5.make()
	v0.format = A5.H64
	v0.jeu_vues = "v3"
	var b6 = Actor25.make("aren")
	b6.set_scale_k(25.2 / 63.0)
	b6.step(0.001, Vector2(0, 1), 1.0 / 60.0)
	v0.step(b6, 0.001, false, 0.0)
	_test(v0._cle == "v3_walk_face" and v0.frame == A5.IMAGE_DEPART_V3, "V3 : départ vers le bas au passage (image %d)" % v0.frame)
	var h3: Array = []
	for k in v._tex:
		if String(k).begins_with("v3_"):
			for t in v._tex[k]:
				var r: Rect2i = (t as Texture2D).get_image().get_used_rect()
				h3.append(roundf((101 - r.position.y) * v.echelle_h64))
	h3.sort()
	_test(h3[0] >= 61 and h3[-1] <= 68, "V3 : tête à %d à %d px au-dessus du sol à l'écran (rebond compris)" % [h3[0], h3[-1]])
	var jeux := []
	for i in 4:
		v.toggle_jeu_vues()
		jeux.append(v.jeu_vues)
	_test(jeux == ["4dir", "v2", "v4", "v3"], "touche G : V4 -> V3 -> 4dir -> V2 -> V4 (%s)" % [jeux])

	# V4 (défaut) : marches de face / de dos dessinées (GIF du 20/11), réduites et ramenées à la palette du profil
	var q = A5.make()
	q.format = A5.H64
	var b7 = Actor25.make("aren")
	b7.set_scale_k(25.2 / 63.0)
	var vus4 := []
	for seg in [[Vector2(0, 1), false, "v4_walk_face"], [Vector2(0, 1), true, "v4_walk_face"], [Vector2(0, -1), false, "v4_walk_back"], [Vector2(0, -1), true, "v4_walk_back"], [Vector2(1, 0), true, "run_" + A5.H64]]:
		for i in 6:
			b7.step(0.04, seg[0], 1.0 / 60.0)
			q.step(b7, 0.04, seg[1], seg[0].x)
		vus4.append(q._cle == seg[2] and q.texture() == q._tex[seg[2]][q.frame])
	_test(vus4 == [true, true, true, true, true], "V4 : bas / haut (marche et course) : marches dessinées ; droite : V09B.5 (%s)" % [vus4])
	b7.step(0.04, Vector2(0, 1), 1.0 / 60.0)
	q.step(b7, 0.04, false, 0.0)
	for i in 20:
		b7.step(0.0, Vector2.ZERO, 1.0 / 60.0)
	q.step(b7, 0.0, false, 0.0)
	_test(q._cle == "v4_walk_face" and q.frame == A5.IMAGE_ARRET_V4, "V4 : arrêt après le bas : pose dessinée tenue (même dessin)")
	b7.step(0.001, Vector2(0, 1), 1.0 / 60.0)
	q.step(b7, 0.001, false, 0.0)
	_test(q._cle == "v4_walk_face" and q.frame == A5.IMAGE_ARRET_V4, "V4 : redémarrage depuis la pose tenue (pas de saut)")
	b7.step(0.04, Vector2(1, 0), 1.0 / 60.0)
	q.step(b7, 0.04, false, 1.0)
	for i in 20:
		b7.step(0.0, Vector2.ZERO, 1.0 / 60.0)
	q.step(b7, 0.0, false, 0.0)
	_test(q._cle == "d4_idle_right", "V4 : arrêt après la droite : attente de profil de l'étude")
	var h5: Array = []
	for k in q._tex:
		if String(k).begins_with("v4_"):
			for t in q._tex[k]:
				h5.append(roundf((101 - (t as Texture2D).get_image().get_used_rect().position.y) * q.echelle_h64))
	h5.sort()
	_test(h5[0] >= 61 and h5[-1] <= 67, "V4 : %d à %d px à l'écran (64 ± 5 %%)" % [h5[0], h5[-1]])

	# scène F5 : état par défaut inchangé
	change_scene_to_file(SCENE)
	for i in 10:
		await physics_frame
	var sc := current_scene
	_test(sc != null and bool(sc.get("_v09b5_on")) and String((sc.get("_anim_v09b5") as RefCounted).get("format")) == "96x112_h64",
		"F5 démarre avec Aren V09B.5 96×112 à 64 px (démarrage du 19/11/2026)")
	_test(sc != null and String(sc.get("_speed_profile")) == "actuel" and sc.call("current_speeds") == [2.2, 3.6], "F5 démarre aux vitesses 2,2 / 3,6 m/s")
	_test(sc != null and float(sc.get("_pitch")) == 24.0 and float(sc.get("_zoom")) == 3.0, "F5 démarre à 24°, zoom ×3")
	# V10 : rendu des personnages (touche K)
	var hs3: Sprite3D = sc.get("_hero_sprite")
	var is3: Sprite3D = sc.get("_ilya_sprite")
	var m3 = hs3.material_override
	_test(bool(sc.get("_rendu_v10")) and m3 is ShaderMaterial and (m3 as ShaderMaterial).shader.resource_path.ends_with("perso_v10.gdshader")
		and (m3 as ShaderMaterial).get_shader_parameter("tex") == hs3.texture and is3.material_override is ShaderMaterial,
		"F5 démarre avec le rendu V10 des personnages (Aren et Ilya, texture de l'image courante)")
	var ek := InputEventKey.new()
	ek.keycode = KEY_K
	ek.physical_keycode = KEY_K
	ek.pressed = true
	sc.call("_unhandled_key_input", ek)
	for i in 3:
		await physics_frame
	_test(not bool(sc.get("_rendu_v10")) and hs3.material_override == null and is3.material_override == null, "touche K : retour au rendu Sprite3D d'origine")
	print("V09B.5 : %d échec(s)" % failures)
	quit(1 if failures > 0 else 0)
