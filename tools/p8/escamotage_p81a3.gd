extends SceneTree
## P8.1-A3 — Diagnostic et continuité de l'escamotage des volumes de la ville sur un parcours (défaut : p81a3_aller_retour,
## forge et Colisée, aller-retour en marchant puis en courant, arrêts et demi-tours). Relève par volume :
##   * bascules (changements de mode aucune / haut / toit / tout) et nombre de passages au mode « tout » (disparition entière) ;
##   * cause du masquage à chaque bascule (« camera_proche » : caméra dans la marge du volume ; « ligne_de_vue » : le volume
##     coupe la ligne caméra -> buste d'Aren) ;
##   * intervalle minimal entre deux bascules (clignotement si < 1 s) ;
##   * images où une partie VISIBLE d'un volume coupe la ligne de vue caméra -> buste d'Aren (Aren masqué).
## godot --headless --path . --script res://tools/p8/escamotage_p81a3.gd -- --route=p81a3_aller_retour [--trace] [options de ville]
## Sortie : « ESCAMOTAGE_A3 {...} » puis une ligne « VOLUME » par volume ayant basculé.
## P8.1-A4 : « bascules_perceptibles » = bascules dont la partie changée couvre au moins 1 % de l'écran (projetée).

var n := 0
var sc
var modes := {}
var t := 0.0
var bascules := {}
var vers_tout := {}
var causes := {}
var dernier := {}
var min_int := {}
var masque_images := 0
var masque_par := {}
var images := 0
var sommets := {}                       # P8.1-A4 : hauteur visible précédente par volume
var perceptibles := {}                  # bascules perceptibles par volume (partie changée >= 1 % de l'écran)
var part_ecran := {}                    # plus grande part d'écran changée par volume
var retire_somme := 0.0                  # part de hauteur retirée (0 à 1) cumulée sur les images où un volume est escamoté
var retire_images := 0


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
	var tout: int = v.mode_tout() if v.has_method("mode_tout") else 2      # mode « volume entier » (P8.1-A3 : 99 ; avant : 2)
	var cam: Vector3 = sc.cam.global_position
	var heros: Vector3 = sc.body.global_position + Vector3(0, 1.0, 0)
	images += 1
	var cache := false
	for vo in v._vols:
		var id := str(vo["id"])
		var mo := int(vo.get("mode", 0))
		var h_vis: float = v.sommet_visible(vo) if v.has_method("sommet_visible") else float(vo["top"])
		if mo == tout:
			h_vis = float(vo["h0"])
		if modes.get(id, 0) != mo:
			var f := _part_ecran(_emprise(vo), float(sommets.get(id, vo["top"])), h_vis)
			part_ecran[id] = maxf(float(part_ecran.get(id, 0.0)), f)
			if f >= 0.01:
				perceptibles[id] = int(perceptibles.get(id, 0)) + 1
			bascules[id] = int(bascules.get(id, 0)) + 1
			if mo == tout:
				vers_tout[id] = int(vers_tout.get(id, 0)) + 1
			if mo > 0:
				var c := str(vo.get("cause", ""))
				if not causes.has(id):
					causes[id] = {}
				causes[id][c] = int(causes[id].get(c, 0)) + 1
			if dernier.has(id):
				min_int[id] = minf(float(min_int.get(id, 99.0)), t - float(dernier[id]))
			dernier[id] = t
			modes[id] = mo
			if OS.get_cmdline_user_args().has("--trace"):
				print("BASCULE %s -> %d (%s) à %.2f s, Aren (%.1f, %.1f, %.1f), caméra (%.1f, %.1f, %.1f)" % [id, mo, vo.get("cause", ""), t, sc.s.hero.x, sc.s.hero.y, sc.s.hero.z, cam.x, cam.y, cam.z])
		sommets[id] = h_vis
		if mo > 0:
			retire_somme += clampf((float(vo["top"]) - h_vis) / maxf(0.5, float(vo["top"]) - float(vo["h0"])), 0.0, 1.0)
			retire_images += 1
		if mo == tout or not (vo["node"] as Node3D).visible:
			continue
		var vv: Dictionary = (vo as Dictionary).duplicate()
		if v.has_method("sommet_visible"):
			vv["top"] = v.sommet_visible(vo)
		elif mo == 1 and vo.has("coupe"):
			vv["top"] = float(vo["coupe"])
		if v._coupe_vue(vv, cam, heros, 0.0) and float(vo["rect"].position.y) > sc.body.global_position.z - 1.0:
			cache = true
			masque_par[id] = int(masque_par.get(id, 0)) + 1
	if cache:
		masque_images += 1
	if sc.s.pilot_done or n > 60 * 600:
		var clign := []
		for id in min_int:
			if float(min_int[id]) < 1.0:
				clign.append("%s (%.2f s)" % [id, min_int[id]])
		var tot_p := 0
		for id in perceptibles:
			tot_p += int(perceptibles[id])
		var total := 0
		var total_tout := 0
		for id in bascules:
			total += int(bascules[id])
		for id in vers_tout:
			total_tout += int(vers_tout[id])
		print("ESCAMOTAGE_A3 ", JSON.stringify({"images": images, "bascules_total": total, "disparitions_entieres": total_tout, "bascules_perceptibles": tot_p,
			"part_hauteur_retiree_moy": snappedf(retire_somme / maxf(1.0, retire_images), 0.01), "images_volume_escamote": retire_images,
			"clignotements_lt_1s": clign, "aren_masque_images": masque_images, "aren_masque_par": masque_par,
			"bloque": sc.s.m.get("stuck", [])}))
		var ids := bascules.keys()
		ids.sort_custom(func(x, y): return int(bascules[x]) > int(bascules[y]))
		for id in ids:
			print("VOLUME %s : %d bascules (%d perceptibles, part d'écran max %.1f %%), %d disparitions entières, causes %s, intervalle min %.2f s" % [id,
				bascules[id], int(perceptibles.get(id, 0)), 100.0 * float(part_ecran.get(id, 0.0)), int(vers_tout.get(id, 0)),
				JSON.stringify(causes.get(id, {})), float(min_int.get(id, 99.0))])
		quit()
	return false


## P8.1-A4 — Part de l'écran occupée par la partie d'un volume qui change (emprise entre les hauteurs h_a et h_b),
## projetée par la caméra de jeu et bornée à la fenêtre (0 si hors champ ou derrière la caméra).
func _part_ecran(r: Rect2, h_a: float, h_b: float) -> float:
	var cam: Camera3D = sc.cam
	var vp: Vector2 = Vector2(cam.get_viewport().get_visible_rect().size)
	var lo := minf(h_a, h_b)
	var hi := maxf(h_a, h_b)
	if hi - lo < 0.05:
		return 0.0
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	var devant := 0
	for x in [r.position.x, r.end.x]:
		for z in [r.position.y, r.end.y]:
			for y in [lo, hi]:
				var p := Vector3(x, y, z)
				if cam.is_position_behind(p):
					continue
				devant += 1
				var e := cam.unproject_position(p)
				mn = Vector2(minf(mn.x, e.x), minf(mn.y, e.y))
				mx = Vector2(maxf(mx.x, e.x), maxf(mx.y, e.y))
	if devant == 0:
		return 0.0
	mn = mn.clamp(Vector2.ZERO, vp)
	mx = mx.clamp(Vector2.ZERO, vp)
	return maxf(0.0, (mx.x - mn.x)) * maxf(0.0, (mx.y - mn.y)) / (vp.x * vp.y)


## Emprise RÉELLE d'un volume (réunion des boîtes de sa géométrie), en plan ; mise en cache.
var _emprises := {}


func _emprise(vo: Dictionary) -> Rect2:
	var id := str(vo["id"])
	if _emprises.has(id):
		return _emprises[id]
	var r := Rect2()
	var premier := true
	for g in (vo["node"] as Node).find_children("*", "GeometryInstance3D", true, false):
		var ab: AABB = (g as GeometryInstance3D).global_transform * (g as GeometryInstance3D).get_aabb()
		var rr := Rect2(ab.position.x, ab.position.z, ab.size.x, ab.size.z)
		r = rr if premier else r.merge(rr)
		premier = false
	if premier:
		r = vo["rect"]
	_emprises[id] = r.intersection((vo["rect"] as Rect2).grow(0.7)) if r.intersects((vo["rect"] as Rect2).grow(0.7)) else vo["rect"]
	return _emprises[id]
