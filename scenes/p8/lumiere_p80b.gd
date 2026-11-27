extends RefCounted
## P8.0-B — PROFILS DE LUMIÈRE DE LA VILLE V0.7-B. EXPÉRIENCE, NON VALIDÉE.
##   A = P7.13 : rendu actuel, référence (défaut).
##   B = P8.0-B : proposition HD-2D, construite par étapes (dans l'ordre du brief) :
##     1 soleil    : même direction (composition des ombres conservée), plus chaud, plus fort, ombres en 4 tranches ;
##     2 ambiance  : lumière indirecte tirée du ciel (ombres plus froides), occlusion ambiante SSAO (Forward+) ;
##     3 couleurs  : rendu filmique (Filmic, ou AgX / ACES / linéaire), contraste et saturation maîtrisés ;
##     4 lumières  : lumière chaude, sans ombre, aux cinq entrées fonctionnelles (Guilde, auberge, forge, boutique,
##                   hôtel de ville) ;
##     5 post-prod : profondeur de champ RÉELLE (distance, Forward+) à la place du flou d'écran vertical ; bloom
##                   seulement sur option ; MSAA 3D et débandage.
## Choix : --lumiere=a|b (ou méta « lumiere » de la scène F6) ; touche F4 en jeu : A <-> B au même endroit.
## Étapes : --b_jusqua=1..5 (B limité aux étapes 1 à N) ; chaque effet se coupe seul : --b_soleil=0, --b_ombres=0,
## --b_ambiance=0, --b_ssao=0, --b_tonemap=filmic|agx|aces|lineaire, --b_lumieres=0, --b_flou=dof|ecran|aucun,
## --b_glow=1, --b_aa=msaa4|msaa2|0. Réglages fins : --b_exposition=, --b_blanc=, --b_dof_m=, --b_dof_flou=.
## Rien n'est construit ni déplacé : bâtiments, caméra, collisions, interactions, escamotage et sprites inchangés.
## Les sprites (non éclairés) ne reçoivent ni soleil ni SSAO ; ils passent en revanche par le rendu filmique et les
## réglages de couleur (à juger : --b_tonemap=lineaire les laisse exactement comme en A).

const ENV_PROPS := ["tonemap_mode", "tonemap_exposure", "tonemap_white", "ambient_light_source", "ambient_light_color",
	"ambient_light_energy", "ambient_light_sky_contribution", "ssao_enabled", "ssao_radius", "ssao_intensity", "ssao_power",
	"ssao_detail", "ssao_horizon", "ssao_sharpness", "ssao_light_affect", "glow_enabled", "glow_intensity", "glow_bloom",
	"glow_hdr_threshold", "adjustment_enabled", "adjustment_brightness", "adjustment_contrast", "adjustment_saturation"]
const SUN_PROPS := ["light_color", "light_energy", "directional_shadow_mode", "directional_shadow_max_distance",
	"directional_shadow_blend_splits", "shadow_bias", "shadow_normal_bias"]

## Entrées fonctionnelles éclairées (ids des « entrees » des données) : lumière à 0,85 de la hauteur de la baie, 0,7 m
## devant la façade (toutes les entrées regardent le sud, vers la caméra).
const ENTREES_ECLAIREES := ["guilde", "auberge", "forge", "boutique", "hotel_de_ville"]

var sc                                   # colisee.gd
var ville                                # ville_v07b.gd
var profil := "a"
var _ref_env := {}
var _ref_sun := {}
var _ref_msaa := 0
var _ref_debanding := false
var _ref_attr: CameraAttributes = null
var _ref_pris := false
var _lumieres: Array = []
var _attr: CameraAttributesPractical
var effets := {}                         # effet -> réglage appliqué (compte rendu, F1)


func _init(scene, v) -> void:
	sc = scene
	ville = v


func profil_demande() -> String:
	var p := str(sc._cli.get("lumiere", sc.get_meta("lumiere", "a") if sc.has_meta("lumiere") else "a")).to_lower()
	return "b" if p == "b" else "a"


func _opt(nom: String, defaut: String) -> String:
	return str(sc._cli.get(nom, defaut)).to_lower()


func _etape(n: int) -> bool:
	return int(_opt("b_jusqua", "5")) >= n


## Méthode de rendu courante : « forward_plus », « mobile » ou « gl_compatibility ».
func rendu() -> String:
	return str(RenderingServer.get_current_rendering_method())


func appliquer(p: String) -> void:
	_relever_a()
	_retablir_a()
	profil = p
	effets.clear()
	if p == "b":
		_appliquer_b()


func basculer() -> String:
	appliquer("a" if profil == "b" else "b")
	return profil


## Retour à A avant de quitter la ville (le Colisée ne doit hériter d'aucun réglage de B).
func quitter() -> void:
	if _ref_pris:
		_retablir_a()
	for l in _lumieres:
		if is_instance_valid(l):
			(l as Node).queue_free()
	_lumieres.clear()


func _relever_a() -> void:
	if _ref_pris:
		return
	var env: Environment = sc._env_res
	for k in ENV_PROPS:
		_ref_env[k] = env.get(k)
	for k in SUN_PROPS:
		_ref_sun[k] = sc._sun.get(k)
	var vp: Viewport = sc.get_viewport()
	_ref_msaa = vp.msaa_3d
	_ref_debanding = vp.use_debanding
	_ref_attr = sc.cam.attributes
	_ref_pris = true


func _retablir_a() -> void:
	var env: Environment = sc._env_res
	for k in _ref_env:
		env.set(k, _ref_env[k])
	for k in _ref_sun:
		sc._sun.set(k, _ref_sun[k])
	var vp: Viewport = sc.get_viewport()
	vp.msaa_3d = _ref_msaa
	vp.use_debanding = _ref_debanding
	sc.cam.attributes = _ref_attr
	for l in _lumieres:
		if is_instance_valid(l):
			(l as Node3D).visible = false
	if sc.get("_tilt") != null:
		sc._apply_tilt()                     # flou d'écran de la caméra V06 (état A)


func _appliquer_b() -> void:
	var env: Environment = sc._env_res
	var sun: DirectionalLight3D = sc._sun
	# 1 — soleil : même direction ; lumière plus chaude et plus forte, ombres plus franches (contraste lumière / ombre)
	if _etape(1) and _opt("b_soleil", "1") != "0":
		sun.light_color = Color(1.0, 0.86, 0.68)
		sun.light_energy = 1.35
		effets["soleil"] = "chaud 1,35"
		# ombres : 4 tranches jusqu'à 160 m (au lieu d'une seule à 120 m qui s'effaçait dès ≈ 96 m sur les volées lointaines),
		# biais normal relevé contre l'acné des nez de marches
		if _opt("b_ombres", "1") != "0":
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			sun.directional_shadow_max_distance = float(_opt("b_ombres_m", "160"))
			sun.directional_shadow_blend_splits = true
			sun.shadow_normal_bias = 1.4
			sun.shadow_bias = 0.04
			effets["ombres"] = "4 tranches, %s m" % _opt("b_ombres_m", "160")
	# 2 — ambiance : lumière indirecte du ciel (dégradé froid en haut, chaud à l'horizon) ; SSAO (Forward+ seulement)
	if _etape(2) and _opt("b_ambiance", "1") != "0":
		if env.sky != null:
			env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			env.ambient_light_sky_contribution = 0.55
		env.ambient_light_color = Color(0.66, 0.66, 0.74)
		env.ambient_light_energy = 0.62
		effets["ambiance"] = "ciel 0,55 + couleur 0,62"
	if _etape(2) and _opt("b_ssao", "1") != "0":
		env.ssao_enabled = true
		env.ssao_radius = 1.2
		env.ssao_intensity = 1.8
		env.ssao_power = 1.6
		env.ssao_detail = 0.6
		env.ssao_horizon = 0.06
		env.ssao_sharpness = 0.98
		env.ssao_light_affect = 0.15                # un peu d'ombre de contact même au soleil (pieds de murs, marches)
		effets["ssao"] = "r 1,2 / i 1,8" + ("" if rendu() != "gl_compatibility" else " (sans effet en Compatibilité)")
	# 3 — rendu filmique et couleurs
	if _etape(3):
		var tm := _opt("b_tonemap", "filmic")
		match tm:
			"agx":
				env.tonemap_mode = Environment.TONE_MAPPER_AGX
			"aces":
				env.tonemap_mode = Environment.TONE_MAPPER_ACES
			"lineaire":
				env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
			_:
				tm = "filmic"
				env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.tonemap_exposure = float(_opt("b_exposition", "1.15" if tm != "lineaire" else "1.0"))
		env.tonemap_white = float(_opt("b_blanc", "3.0"))
		env.adjustment_enabled = true
		env.adjustment_brightness = 1.0
		env.adjustment_contrast = 1.06
		env.adjustment_saturation = 1.08
		effets["couleurs"] = "%s, exposition %s, contraste 1,06, saturation 1,08" % [tm, str(env.tonemap_exposure)]
	# 4 — lumières locales des entrées
	if _etape(4) and _opt("b_lumieres", "1") != "0":
		if _lumieres.is_empty():
			_creer_lumieres()
		for l in _lumieres:
			(l as Node3D).visible = true
		effets["lumieres"] = "%d entrées (sans ombre)" % _lumieres.size()
	# 5 — post-production : profondeur de champ réelle, bloom sur option, MSAA et débandage
	if _etape(5):
		var flou := _opt("b_flou", "dof")
		if flou == "dof" and rendu() == "gl_compatibility":
			flou = "ecran"                                # la profondeur de champ n'existe pas en Compatibilité
		if flou != "ecran" and sc.get("_tilt") != null:
			sc._tilt.visible = false
		if flou == "dof":
			if _attr == null:
				_attr = CameraAttributesPractical.new()
			_attr.dof_blur_near_enabled = false
			_attr.dof_blur_far_enabled = true
			_attr.dof_blur_far_distance = float(_opt("b_dof_m", "90"))
			_attr.dof_blur_far_transition = 120.0
			_attr.dof_blur_amount = float(_opt("b_dof_flou", "0.05"))
			sc.cam.attributes = _attr
		effets["flou"] = flou + (" (dès %s m)" % _opt("b_dof_m", "90") if flou == "dof" else "")
		if _opt("b_glow", "0") == "1":
			env.glow_enabled = true
			env.glow_intensity = 0.3
			env.glow_bloom = 0.0
			env.glow_hdr_threshold = 1.2
			effets["glow"] = "discret (seuil 1,2)"
		else:
			env.glow_enabled = false
		var aa := _opt("b_aa", "msaa4")
		var vp: Viewport = sc.get_viewport()
		vp.msaa_3d = Viewport.MSAA_4X if aa == "msaa4" else (Viewport.MSAA_2X if aa == "msaa2" else Viewport.MSAA_DISABLED)
		vp.use_debanding = true
		effets["aa"] = aa + " + débandage"


func _creer_lumieres() -> void:
	for e in ville.v.get("entrees", []):
		if not str(e.get("id", "")) in ENTREES_ECLAIREES:
			continue
		var l := OmniLight3D.new()
		l.name = "p80b_entree_" + str(e["id"])
		l.light_color = Color(1.0, 0.74, 0.48)
		l.light_energy = 0.9
		l.light_specular = 0.0
		l.omni_range = 5.0
		l.omni_attenuation = 1.4
		l.shadow_enabled = false
		l.position = Vector3(float(e["x"]), float(e["h"]) + float(e.get("hauteur", 3.0)) * 0.85, float(e["y"]) + 0.7)
		l.set_meta("vol", "aucun")                    # jamais rattachée à un volume d'escamotage
		sc.root.add_child(l)
		_lumieres.append(l)


## Ligne de compte rendu (F1, toast).
func resume() -> String:
	if profil == "a":
		return "Lumière A — P7.13 (référence)"
	var parts := []
	for k in effets:
		parts.append("%s : %s" % [k, effets[k]])
	return "Lumière B — P8.0-B (" + rendu() + ") · " + " · ".join(parts)
