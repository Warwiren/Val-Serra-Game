extends SceneTree
## V09C — test rapide du banc d'essai d'Ilya (Godot 4.7.2) :
##   godot --headless --path . --script res://tests/v09c_ilya_smoke.gd
const C = preload("res://src/explore25/anim_v09c.gd")
const Actor25 = preload("res://src/explore25/actor25.gd")
const Portraits = preload("res://src/proto/portraits.gd")
const SCENE := "res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.tscn"
var failures := 0


func _test(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("V09C ECHEC : " + label)
	else:
		print("V09C OK : " + label)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var a = C.make()
	var n := 0
	for k in a._tex:
		for t in a._tex[k]:
			if t != null and (t as Texture2D).get_size() == Vector2(96, 112):
				n += 1
	_test(n == 104, "96 images V09C.5 (4 directions × attente / marche / course × 8) + 8 poses de course V09C.6, 96 × 112")
	_test(ResourceLoader.exists("res://art/p45/chars/ilya/walk_right_7.png"), "sprites P4.8 d'Ilya toujours présents")
	var hv: float = a.hauteur_px * a.echelle
	_test(a.echelle > 0.69 and a.echelle < 0.75 and absf(hv - 64.0) < 0.5, "échelle mesurée ×%.3f (%d px -> %.1f px)" % [a.echelle, a.hauteur_px, hv])
	for d in C.DIRS:
		for c in ["idle", "walk", "run"]:
			a.dir = d
			a.cycle = c
			var t: Texture2D = a._tex[c + "_" + d][0]
			var ofs: Vector2 = a.offset_px(0.96, t)
			var foot: float = 0.96 + (ofs.y + t.get_height() * 0.5 - float(a._cad["directions"][d][c]["ligne_sol_px"])) * a.pixel_m()
			if absf(foot) > 0.0001:
				_test(false, "pieds au sol %s %s (%.4f m)" % [c, d, foot])
	_test(true, "pieds posés sur l'origine du corps, 12 cycles")

	# marche / course d'après la vitesse réelle, avec hystérésis (profil candidat 2,8 / 4,5 m/s)
	var sp := [2.8, 4.5]
	var s: Vector2 = C.seuils(sp)
	_test(absf(s.x - 3.82) < 0.001 and absf(s.y - 3.31) < 0.001, "seuils course : entrée %.2f, sortie %.2f m/s" % [s.x, s.y])
	var base = Actor25.make("ilya")
	base.set_scale_k(26.0 / 65.0)
	var seq := []
	for v in [2.8, 3.6, 4.0, 3.5, 3.4, 3.2, 3.6]:
		base.step(v / 60.0, Vector2(1, 0), 1.0 / 60.0)
		a.step(base, v / 60.0, v, sp)
		seq.append(a.cycle)
	_test(seq == ["walk", "walk", "run", "run", "run", "walk", "walk"], "hystérésis marche / course : %s" % [seq])
	_test(a.dir == "right" and a.texture() == a._tex["walk_right"][a.frame], "profil droit : marche droite livrée")
	base.step(0.05, Vector2(-1, 0), 1.0 / 60.0)
	a.step(base, 0.05, 3.0, sp)
	_test(a.dir == "left" and a.cycle == "walk", "demi-tour : profil gauche du pack")
	for i in 30:
		base.step(0.0, Vector2.ZERO, 1.0 / 60.0)
	a.step(base, 0.0, 0.0, sp)
	_test(a.cycle == "idle" and a.frame == int(base.frame) % 8, "attente : images du pack au rythme d'Actor25")

	# V09C.6 : course droite candidate, seule à changer ; même échelle, pieds au sol, foulée propre
	a.course_v09c6 = true
	base.step(4.5 / 60.0, Vector2(1, 0), 1.0 / 60.0)
	a.step(base, 4.5 / 60.0, 4.5, sp)
	_test(a.cycle == "run" and a.dir == "right" and a.run_v09c6() and a.texture() == a._tex["run_right_v09c6"][a.frame], "V09C.6 : course droite = poses V09C.6")
	var t6: Texture2D = a.texture()
	var o6: Vector2 = a.offset_px(0.96, t6)
	var f6: float = 0.96 + (o6.y + t6.get_height() * 0.5 - float(a._cad6["run_right"]["ligne_sol_px"])) * a.pixel_m()
	_test(absf(f6) < 0.0001 and int(a._cad6["run_right"]["ligne_sol_px"]) == 105, "V09C.6 : pieds au sol (ligne 105, y = %.4f m)" % f6)
	_test(absf(a.stride_m() - float(a._cad6["run_right"]["foulee_px"]) * a.pixel_m()) < 0.0001 and absf(a.stride_m("run", "left") - float(a._cad["directions"]["left"]["run"]["foulee_px"]) * a.pixel_m()) < 0.0001,
		"V09C.6 : foulée propre (%.2f m), autres directions inchangées" % a.stride_m())
	a.course_v09c6 = false
	_test(not a.run_v09c6() and a.texture() == a._tex["run_right"][a.frame], "V09C.5 : course droite d'origine toujours disponible")

	# portraits : anciens par défaut, nouveaux sur bascule, correspondance des clés
	_test(Portraits.path("compagnon_vif", "souriant").ends_with("art/p45/portraits/ilya/souriant.png"), "portraits : anciens par défaut")
	Portraits.ilya_v09c = true
	var ok := true
	for k in Portraits.ILYA_V09C:
		ok = ok and Portraits.get_texture("compagnon_vif", k) != null
	_test(ok and Portraits.path("compagnon_vif", "souriant").ends_with("sereine.png") and Portraits.path("compagnon_vif", "blesse").ends_with("blessee.png")
		and Portraits.path("compagnon_vif", "concentre").ends_with("resolue.png"), "portraits V09C : 7 expressions, souriant -> sereine, blesse -> blessee")
	_test(Portraits.path("heros", "souriant").ends_with("aren/souriant.png"), "portraits d'Aren inchangés")
	var tailles := true
	for cad in ["serre", "v09c5"]:
		Portraits.ilya_cadrage = cad
		for k in Portraits.ILYA_V09C:
			var t: Texture2D = Portraits.get_texture("compagnon_vif", k)
			tailles = tailles and t != null and t.get_size() == Vector2(160, 160)
	_test(tailles, "portraits : cadrage serré et V09C.5 (secours), 160 × 160")
	Portraits.ilya_cadrage = "serre"
	Portraits.ilya_v09c = false

	change_scene_to_file(SCENE)
	for i in 10:
		await physics_frame
	var sc := current_scene
	_test(sc != null and not bool(sc.get("_v09c_on")), "F5 démarre avec Ilya P4.8")
	var etats := []
	for i in 4:
		var e := InputEventKey.new()
		e.keycode = KEY_I
		e.physical_keycode = KEY_I
		e.pressed = true
		sc.call("_unhandled_key_input", e)
		etats.append("P4.8" if not bool(sc.get("_v09c_on")) else ("V09C.6" if bool((sc.get("_ilya_v09c") as RefCounted).get("course_v09c6")) else "V09C.5"))
	_test(etats == ["V09C.5", "V09C.6", "P4.8", "V09C.5"], "touche I : %s" % [etats])
	print("V09C : %d échec(s)" % failures)
	quit(1 if failures > 0 else 0)
