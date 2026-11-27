extends SceneTree
## P8.0-C — Contrôle des profils de lumière de la ville (lecture seule, --headless suffit) :
##   1. au chargement : profil attendu (PROFIL_DEFAUT, ou --lumiere=a|b) ;
##   2. B appliqué : valeurs du SECOND DOSAGE retenu (soleil, ambiance, couleurs, SSAO, étapes 4-5) ;
##   3. touche F4 (lum.basculer) A -> B -> A : retour EXACT à A (environnement, soleil, MSAA, débandage, attributs de
##      caméra, flou d'écran, lumières des entrées éteintes).
## godot --headless --path . --script res://tools/p8/lumiere_ab_p80c.gd [-- --lumiere=a|b]
## Résultat : « LUMIERE_AB {ok, erreurs, ...} » (ok = true attendu).

var sc
var n := 0
var ref := {}
var erreurs: Array[String] = []
var lum


func _initialize() -> void:
	change_scene_to_file("res://scenes/p7/ville_v07b.tscn")


func _etat() -> Dictionary:
	var d := {}
	var e: Environment = sc._env_res
	for k in lum.ENV_PROPS:
		d["env." + k] = e.get(k)
	for k in lum.SUN_PROPS:
		d["sun." + k] = sc._sun.get(k)
	d["msaa"] = sc.get_viewport().msaa_3d
	d["debanding"] = sc.get_viewport().use_debanding
	d["attributs"] = sc.cam.attributes
	d["flou_ecran"] = sc._tilt.visible
	d["lumieres_visibles"] = lum._lumieres.filter(func(l): return (l as Node3D).visible).size()
	return d


func _verif(cond: bool, quoi: String) -> void:
	if not cond:
		erreurs.append(quoi)


func _proche(a: float, b: float) -> bool:
	return absf(a - b) < 1e-4


func _verifier_b() -> void:
	var e: Environment = sc._env_res
	var sun: DirectionalLight3D = sc._sun
	_verif(sun.light_color.is_equal_approx(lum.SOLEIL), "soleil : couleur du second dosage")
	_verif(_proche(sun.light_energy, 1.35), "soleil : énergie 1,35")
	_verif(sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "ombres : 4 tranches")
	_verif(e.ambient_light_source == Environment.AMBIENT_SOURCE_SKY, "ambiance : source ciel")
	_verif(e.ambient_light_color.is_equal_approx(lum.AMB) and _proche(e.ambient_light_energy, lum.AMB_E), "ambiance : couleur et énergie")
	_verif(e.ssao_enabled and _proche(e.ssao_intensity, lum.SSAO_I) and _proche(e.ssao_radius, lum.SSAO_R)
		and _proche(e.ssao_light_affect, lum.SSAO_L), "SSAO du second dosage")
	_verif(e.tonemap_mode == Environment.TONE_MAPPER_FILMIC and _proche(e.tonemap_exposure, lum.EXPOSITION), "Filmic, exposition")
	_verif(_proche(e.adjustment_contrast, lum.CONTRASTE) and _proche(e.adjustment_saturation, lum.SATURATION), "contraste, saturation")
	_verif(lum._lumieres.size() == 5, "5 lumières d'entrée")
	_verif(sc.get_viewport().msaa_3d == Viewport.MSAA_4X, "MSAA ×4")


func _process(_d: float) -> bool:
	n += 1
	if sc == null:
		if current_scene != null and current_scene.get("_ville") != null and current_scene._ville != null \
				and current_scene._ville.get("lum") != null:
			sc = current_scene
			lum = sc._ville.lum
		return false
	if n == 100:
		var attendu: String = lum.profil_demande()
		_verif(lum.profil == attendu, "profil au chargement : %s attendu, %s appliqué" % [attendu, lum.profil])
		if lum.profil == "b":
			_verifier_b()
			lum.basculer()                    # vers A, pour partir de A
		ref = _etat()
		lum.basculer()                        # F4 : A -> B
		_verif(lum.profil == "b", "F4 : passage à B")
		_verifier_b()
	if n == 130:
		lum.basculer()                        # F4 : B -> A
	if n == 160:
		var e := _etat()
		for k in ref:
			if str(ref[k]) != str(e[k]):
				erreurs.append("retour à A : %s %s -> %s" % [k, ref[k], e[k]])
		print("LUMIERE_AB ", JSON.stringify({"ok": erreurs.is_empty(), "erreurs": erreurs, "profil_defaut": lum.PROFIL_DEFAUT,
			"rendu": lum.rendu(), "resume_b": "second dosage" if erreurs.is_empty() else "?"}))
		quit()
	return false
