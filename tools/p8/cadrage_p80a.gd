extends SceneTree
## P8.0-A — Mesure du cadrage de la ville pour UNE plongée, sur les cinq parcours de comparaison (route p80a_cadrage,
## src/explore25/routes25.gd). Outil de lecture seule : il ne modifie ni la scène ni la caméra. Relève, par parcours :
##   * Aren : images masquées par une partie visible d'un volume (même test que tools/p7/escamotage_p7122.gd), images
##     hors du cadre, position verticale à l'écran (fraction de la hauteur, 0 = haut) ;
##   * occultations : nombre d'escamotages (passage d'un volume de « aucun » à « haut » ou « tout »), dont « tout »,
##     durée cumulée et durée moyenne d'un escamotage, bascules de mode, clignotements (deux bascules d'un même volume
##     à moins d'1 s) ;
##   * profondeur : ligne d'horizon à l'écran (fraction, < 0 = au-dessus du cadre), distance de sol visible devant Aren
##     jusqu'au bord haut du cadre (m ; « horizon » si le bord haut est au-dessus de l'horizon) ;
##   * repères : part des images où le sommet du Colisée, la porte fortifiée et la porte du château sont DANS LE CADRE,
##     et dans le cadre SANS volume d'escamotage visible devant (le décor qui n'est pas un volume, ville haute comprise,
##     n'est pas compté : approximation) ;
##   * toitures : volumes visibles dans le cadre dont le dessus est sous la caméra (toit ou terrasse vus de dessus),
##     moyenne et maximum, et les volumes concernés le plus souvent ;
##   * P8.0-A2, confort des transitions : plongée minimale et maximale du parcours, vitesse maximale de variation (°/s),
##     et écart maximal de la position d'Aren à l'écran d'une image à l'autre pendant une variation de plongée (px).
## godot --headless --path . --script res://tools/p8/cadrage_p80a.gd -- --route=p80a_cadrage --plongee_ville=16
##   [--route=p80a_cadrage_course] [--plongee_civique=0|1] [--camera_ville=B] [--zone_lecture=17]
## Les chiffres dépendent de la taille de la fenêtre (headless : celle du projet) ; ils servent à COMPARER les angles
## entre eux, pas à juger l'image : le jugement se fait en vidéo sur GPU.

const Civique := preload("res://scenes/p7/civique_p712.gd")
const World25 := preload("res://src/explore25/world25.gd")

var n := 0
var sc
var t := 0.0
var seg := ""
var R := {}                      # segment -> mesures
var modes := {}
var dernier := {}
var debut := {}
var reperes := {}
var pitch_prec := -1.0
var aren_prec := Vector2(-1, -1)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not Array(args).any(func(a): return str(a).begins_with("--route=p80a_cadrage")):     # PackedStringArray n'a pas any()
		print("Ajouter -- --route=p80a_cadrage (ou p80a_cadrage_course) --plongee_ville=<11|16|20|24>")
	change_scene_to_file("res://scenes/p7/ville_v07b.tscn")


func _nouveau() -> Dictionary:
	return {"images": 0, "duree_s": 0.0, "aren_masque": 0, "aren_hors_cadre": 0, "aren_y_min": 1.0, "aren_y_max": 0.0,
		"escamotages": 0, "escamotages_tout": 0, "duree_escamote_s": 0.0, "fins": 0, "bascules": 0, "clignotements": 0,
		"horizon_min": 9.0, "horizon_max": -9.0, "sol_min_m": INF, "sol_max_m": 0.0, "sol_horizon_images": 0,
		"colisee_cadre": 0, "colisee_degage": 0, "porte_cadre": 0, "porte_degagee": 0, "chateau_cadre": 0, "chateau_degage": 0,
		"toits_somme": 0, "toits_max": 0, "toits_ids": {},
		"plongee_min": 90.0, "plongee_max": -90.0, "plongee_vit_max": 0.0, "aren_saut_px": 0.0}


func _process(d: float) -> bool:
	n += 1
	if sc == null:
		if current_scene != null and current_scene.get("s") != null and current_scene.s != null and current_scene.get("_ville") != null:
			sc = current_scene
			reperes = {
				"colisee": Vector3(0.0, 18.0, 54.0),                                         # sommet du tambour (données)
				"porte": Vector3(70.0, 15.0, 40.0),                                          # porte fortifiée : 8 m + 7 m
				"chateau": Vector3(Civique.AXE, Civique.RAMPE[3] + 10.5, Civique.RAMPE[1] - 1.6),   # châtelet du château
			}
		return false
	var s = sc.s
	if s.pilot.size() > 0 and s.pilot_i < s.pilot.size():
		var sg := str(s.pilot[s.pilot_i].get("seg", seg))
		if sg != seg:
			_clore()
			seg = sg
	if seg == "" or sc._ville == null:
		return _fin()
	if not R.has(seg):
		R[seg] = _nouveau()
	var r: Dictionary = R[seg]
	t += d
	r["images"] += 1
	r["duree_s"] += d
	var v = sc._ville
	var cam3: Camera3D = sc.cam
	var cam: Vector3 = cam3.global_position
	var heros: Vector3 = sc.body.global_position + Vector3(0, 1.0, 0)
	var vp: Vector2 = Vector2(cam3.get_viewport().get_visible_rect().size)
	# --- Aren
	var cache := false
	var toits := 0
	var degage := {"colisee": true, "porte": true, "chateau": true}
	var tout: int = v.mode_tout() if v.has_method("mode_tout") else 2          # P8.1-A3 : coupes à plusieurs niveaux, volume entier = mode_tout()
	for vo in v._vols:
		var id := str(vo["id"])
		var mo := int(vo.get("mode", 0))
		var avant := int(modes.get(id, 0))
		if mo != avant:
			r["bascules"] += 1
			if dernier.has(id) and t - float(dernier[id]) < 1.0:
				r["clignotements"] += 1
			dernier[id] = t
			if avant == 0:
				r["escamotages"] += 1
				debut[id] = t
			if mo == tout and avant != tout:
				r["escamotages_tout"] += 1
			if mo == 0 and debut.has(id):
				r["duree_escamote_s"] += t - float(debut[id])
				r["fins"] += 1
				debut.erase(id)
			modes[id] = mo
		if mo == tout or not (vo["node"] as Node3D).visible:
			continue
		var vv: Dictionary = (vo as Dictionary).duplicate()
		if v.has_method("sommet_visible"):
			vv["top"] = v.sommet_visible(vo)
		elif mo == 1 and vo.has("coupe"):
			vv["top"] = float(vo["coupe"])
		if v._coupe_vue(vv, cam, heros, 0.0) and float(vo["rect"].position.y) > sc.body.global_position.z - 1.0:
			cache = true
		for k in degage:
			if degage[k] and v._coupe_vue(vv, cam, reperes[k], 0.0):
				degage[k] = false
		var rc: Rect2 = vo["rect"]
		var c := Vector3(rc.get_center().x, float(vv["top"]), rc.get_center().y)
		if float(vv["top"]) < cam.y and cam3.is_position_in_frustum(c):
			toits += 1
			r["toits_ids"][id] = int(r["toits_ids"].get(id, 0)) + 1
	if cache:
		r["aren_masque"] += 1
	var pa := cam3.unproject_position(sc.body.global_position)
	if cam3.is_position_behind(sc.body.global_position) or pa.x < 0.0 or pa.y < 0.0 or pa.x > vp.x or pa.y > vp.y:
		r["aren_hors_cadre"] += 1
	else:
		r["aren_y_min"] = minf(r["aren_y_min"], pa.y / vp.y)
		r["aren_y_max"] = maxf(r["aren_y_max"], pa.y / vp.y)
	# --- profondeur : horizon et sol visible devant Aren
	var fw := -cam3.global_transform.basis.z
	var fh := Vector3(fw.x, 0.0, fw.z).normalized()
	var hz := cam3.unproject_position(cam + fh * 5000.0).y / vp.y
	r["horizon_min"] = minf(r["horizon_min"], hz)
	r["horizon_max"] = maxf(r["horizon_max"], hz)
	var dir := cam3.project_ray_normal(Vector2(vp.x * 0.5, 0.0))
	var h0: float = sc.body.global_position.y
	if dir.y < -1e-4:
		var k := (h0 - cam.y) / dir.y
		var p := cam + dir * k
		var dist := Vector2(p.x - sc.body.global_position.x, p.z - sc.body.global_position.z).length()
		r["sol_min_m"] = minf(r["sol_min_m"], dist)
		r["sol_max_m"] = maxf(r["sol_max_m"], dist)
	else:
		r["sol_horizon_images"] += 1
	# --- repères
	for k in reperes:
		if cam3.is_position_in_frustum(reperes[k]):
			r[k + "_cadre"] += 1
			if degage[k]:
				r[("porte_degagee" if k == "porte" else k + "_degage")] += 1
	r["toits_somme"] += toits
	# --- confort des transitions de plongée (P8.0-A2)
	var pd := rad_to_deg(World25.pitch)
	r["plongee_min"] = minf(r["plongee_min"], pd)
	r["plongee_max"] = maxf(r["plongee_max"], pd)
	if pitch_prec >= 0.0 and d > 0.0:
		var vit := absf(pd - pitch_prec) / d
		if vit < 60.0:                          # un téléport (début de parcours) n'est pas une transition
			r["plongee_vit_max"] = maxf(r["plongee_vit_max"], vit)
			if absf(pd - pitch_prec) > 1e-4 and aren_prec.x >= 0.0:
				r["aren_saut_px"] = maxf(r["aren_saut_px"], absf(pa.y - aren_prec.y))
	pitch_prec = pd
	aren_prec = pa
	r["toits_max"] = maxi(r["toits_max"], toits)
	return _fin()


func _clore() -> void:
	# un escamotage encore en cours en fin de parcours compte jusqu'à la fin du parcours (le téléport suivant le relâche)
	if seg != "" and R.has(seg):
		for id in debut:
			R[seg]["duree_escamote_s"] += t - float(debut[id])
			R[seg]["fins"] += 1
	debut.clear()


func _fin() -> bool:
	if sc == null:
		return false
	if not (sc.s.pilot_done or n > 60 * 900):
		return false
	_clore()
	var plongee: float = sc.plongee_ville()
	var out := {"plongee_ville": plongee, "plongee_civique": sc.plongee_civique_active(), "zone_lecture": sc.zone_lecture_deg(),
		"route": str(sc._cli.get("route", "")), "bloque": sc.s.m.get("stuck", []), "parcours": {}}
	for k in R:
		var r: Dictionary = R[k]
		var im := maxf(1.0, float(r["images"]))
		var sol_min: Variant = "horizon"
		if float(r["sol_min_m"]) < INF:
			sol_min = snappedf(r["sol_min_m"], 0.1)
		var ids: Array = r["toits_ids"].keys()
		ids.sort_custom(func(a, b): return int(r["toits_ids"][a]) > int(r["toits_ids"][b]))
		out["parcours"][k] = {
			"duree_s": snappedf(r["duree_s"], 0.1),
			"aren_masque_pct": snappedf(100.0 * r["aren_masque"] / im, 0.1),
			"aren_hors_cadre_images": r["aren_hors_cadre"],
			"aren_y_ecran": [snappedf(r["aren_y_min"], 0.01), snappedf(r["aren_y_max"], 0.01)],
			"escamotages": r["escamotages"], "escamotages_tout": r["escamotages_tout"],
			"escamote_cumul_s": snappedf(r["duree_escamote_s"], 0.1),
			"escamotage_moyen_s": snappedf(r["duree_escamote_s"] / maxf(1.0, float(r["fins"])), 0.01),
			"bascules": r["bascules"], "clignotements_lt_1s": r["clignotements"],
			"horizon_ecran": [snappedf(r["horizon_min"], 0.01), snappedf(r["horizon_max"], 0.01)],
			"sol_devant_m": [sol_min, snappedf(r["sol_max_m"], 0.1)],
			"sol_bord_haut_au_dela_horizon_pct": snappedf(100.0 * r["sol_horizon_images"] / im, 0.1),
			"colisee_cadre_pct": snappedf(100.0 * r["colisee_cadre"] / im, 0.1),
			"colisee_degage_pct": snappedf(100.0 * r["colisee_degage"] / im, 0.1),
			"porte_cadre_pct": snappedf(100.0 * r["porte_cadre"] / im, 0.1),
			"porte_degagee_pct": snappedf(100.0 * r["porte_degagee"] / im, 0.1),
			"chateau_cadre_pct": snappedf(100.0 * r["chateau_cadre"] / im, 0.1),
			"chateau_degage_pct": snappedf(100.0 * r["chateau_degage"] / im, 0.1),
			"toits_vus_dessus_moy": snappedf(float(r["toits_somme"]) / im, 0.1), "toits_vus_dessus_max": r["toits_max"],
			"toits_frequents": ids.slice(0, 6),
			"plongee_deg": [snappedf(r["plongee_min"], 0.1), snappedf(r["plongee_max"], 0.1)],
			"plongee_vit_max_deg_s": snappedf(r["plongee_vit_max"], 0.1),
			"aren_saut_vertical_px_pendant_variation": snappedf(r["aren_saut_px"], 0.1),
		}
	print("CADRAGE_P80A ", JSON.stringify(out))
	quit()
	return true
