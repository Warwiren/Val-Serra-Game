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

	# scène F5 : état par défaut inchangé
	change_scene_to_file(SCENE)
	for i in 10:
		await physics_frame
	var sc := current_scene
	_test(sc != null and not bool(sc.get("_v09b5_on")), "F5 démarre avec les animations P4.8")
	_test(sc != null and String(sc.get("_speed_profile")) == "actuel" and sc.call("current_speeds") == [2.2, 3.6], "F5 démarre aux vitesses 2,2 / 3,6 m/s")
	print("V09B.5 : %d échec(s)" % failures)
	quit(1 if failures > 0 else 0)
