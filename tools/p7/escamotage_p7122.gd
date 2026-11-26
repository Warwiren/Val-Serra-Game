extends SceneTree
## P7.12.2 — Mesure de l'escamotage des volumes de la ville pendant un parcours (par défaut p7_7122_aller_retour : deux
## premières volées, marche puis course, arrêts et demi-tours). Relève, image par image :
##   * chaque bascule de mode (aucune / haut / tout) par volume, l'intervalle minimal entre deux bascules d'un même
##     volume (clignotement si < 1 s) ;
##   * les images où une partie VISIBLE d'un volume coupe la ligne de vue caméra -> buste d'Aren (« Aren masqué »).
## godot --headless --path . --script res://tools/p7/escamotage_p7122.gd -- --route=p7_7122_aller_retour [--camera_ville=A|B]
##   [--escamotage_partiel=0] [--escamotage_delai=0]

var n := 0
var sc
var modes := {}
var t := 0.0
var bascules := {}
var dernier := {}
var min_int := {}
var masque_images := 0
var masque_par := {}
var images := 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/p7/ville_v07b.tscn")


func _process(d: float) -> bool:
	n += 1
	if sc == null:
		if current_scene != null and current_scene.get("s") != null and current_scene.s != null and current_scene.get("_ville") != null:
			sc = current_scene
		return false
	t += d
	var v = sc._ville
	var cam: Vector3 = sc.cam.global_position
	var heros: Vector3 = sc.body.global_position + Vector3(0, 1.0, 0)
	images += 1
	var cache := false
	for vo in v._vols:
		var id := str(vo["id"])
		var mo := int(vo.get("mode", 0))
		if modes.get(id, 0) != mo:
			bascules[id] = int(bascules.get(id, 0)) + 1
			if dernier.has(id):
				min_int[id] = minf(float(min_int.get(id, 99.0)), t - float(dernier[id]))
			dernier[id] = t
			modes[id] = mo
			if OS.get_cmdline_user_args().has("--trace"):
				print("BASCULE %s -> %d à %.2f s, Aren (%.1f, %.1f, %.1f)" % [id, mo, t, sc.s.hero.x, sc.s.hero.y, sc.s.hero.z])
		if mo == 2 or not (vo["node"] as Node3D).visible:
			continue
		var top: float = float(vo["top"])
		if mo == 1 and vo.has("coupe"):
			top = float(vo["coupe"])
		var vv: Dictionary = (vo as Dictionary).duplicate()
		vv["top"] = top
		if v._coupe_vue(vv, cam, heros, 0.0) and float(vo["rect"].position.y) > sc.body.global_position.z - 1.0:
			cache = true
			masque_par[id] = int(masque_par.get(id, 0)) + 1
	if cache:
		masque_images += 1
	if sc.s.pilot_done or n > 60 * 400:
		var clign := []
		for id in min_int:
			if float(min_int[id]) < 1.0:
				clign.append("%s (%.2f s)" % [id, min_int[id]])
		print("ESCAMOTAGE ", JSON.stringify({"images": images, "bascules": bascules, "intervalle_min_s": min_int,
			"clignotements_lt_1s": clign, "aren_masque_images": masque_images, "aren_masque_par": masque_par,
			"bloque": sc.s.m.get("stuck", [])}))
		quit()
	return false
