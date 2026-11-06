extends Node
## PARCOURS DE LOCOMOTION « MANUEL » (sans autoplay) : uniquement de vraies touches clavier simulées
## (InputEventKey via Input.parse_input_event, exactement le chemin du joueur). Aucun appel à la démo, aucun
## déplacement direct du héros. Mesure image par image : orientation, image de marche, distance réellement
## parcourue, espacements du groupe, positions interdites, ordre de profondeur.
##
## Lancement :  godot --path . -- --start=hd2d-zone --course=manuel [--course-out=/chemin/metrics.json]
##              godot --path . -- --start=hd2d-zone --autoplay --course=observer   (mesure la démo automatique)
## Ajouter --fixed-fps 60 (ou --write-movie fichier.avi) avant « -- » pour un résultat reproductible.

var zone                                # scène zone_hd2d (non typée : le script est chargé à la volée)
var mode := "manuel"
var out_path := ""
var frames: Array = []                  # une entrée par image
var events: Array = []                  # étapes du parcours
var _t := 0.0
var _held := {}
var _hud: Label                         # affichage des touches tenues (vidéo)

const K_R := KEY_RIGHT
const K_L := KEY_LEFT
const K_U := KEY_UP
const K_D := KEY_DOWN


func _init(z, m: String) -> void:
	zone = z
	mode = m
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--course-out="):
			out_path = a.substr(13)


func _ready() -> void:
	process_priority = 1000             # mesure APRÈS la mise à jour de la zone (même image)
	if mode == "manuel" or mode == "pnj":
		var layer := CanvasLayer.new()
		layer.layer = 50
		add_child(layer)
		_hud = Label.new()
		_hud.position = Vector2(16, 12)
		_hud.add_theme_font_size_override("font_size", 18)
		_hud.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
		_hud.add_theme_constant_override("outline_size", 6)
		layer.add_child(_hud)
	if mode == "manuel":
		_run.call_deferred()
	elif mode == "pnj":
		_run_pnj.call_deferred()


## Parcours : départ arrêté, ligne droite, arrêts, diagonales, virages enchaînés, glissement contre un obstacle,
## tour complet de la maison (gauche, arrière, droite, devant le garde), relâchements de touches décalés.
func _run() -> void:
	await get_tree().create_timer(0.8).timeout
	await _step("départ arrêté", [], 0.5)
	await _step("droite", [K_R], 1.0)
	await _step("arrêt", [], 0.5)
	await _step("haut", [K_U], 0.7)
	await _step("arrêt", [], 0.4)
	await _step("diagonale haut-gauche", [K_U, K_L], 0.9)
	await _step("relâchement décalé (gauche lâché en premier)", [K_U], 0.05)
	await _step("arrêt", [], 0.5)
	await _step("diagonale bas-droite", [K_D, K_R], 0.8)
	await _step("virage : droite", [K_R], 0.4)
	await _step("virage : haut", [K_U], 0.4)
	await _step("virage : gauche", [K_L], 0.5)
	await _step("demi-tour : droite", [K_R], 0.5)
	await _step("arrêt", [], 0.5)
	await _goto("devant les caisses", Vector2(330, 205))
	await _step("glissement : haut-droite contre la maison", [K_U, K_R], 1.6)
	await _step("arrêt", [], 0.4)
	await _goto("retour devant la porte", Vector2(392, 200))
	await _goto("devant le banc", Vector2(296, 205))
	await _goto("côté gauche de la maison", Vector2(296, 160))
	await _goto("arrière gauche", Vector2(318, 113))
	await _goto("arrière droit", Vector2(440, 88))
	await _goto("au-delà de l'angle", Vector2(512, 112))
	await _goto("droite des tonneaux", Vector2(514, 168))
	await _goto("devant le garde", Vector2(452, 186))
	await _step("arrêt", [], 0.6)
	await _goto("devant la porte", Vector2(392, 200))
	await _step("diagonale bas-gauche", [K_D, K_L], 1.0)
	await _step("relâchement décalé (bas lâché en premier)", [K_L], 0.05)
	await _step("arrêt final", [], 1.2)
	_finish()


## Parcours « PNJ » : on s'approche du garde AU CLAVIER depuis plusieurs côtés, comme un joueur : on marche
## vers lui et on s'arrête quand les deux personnages se touchent visuellement (ou quand on bute sur lui),
## puis on appuie sur E. On vérifie aussi qu'on ne parle ni de loin ni à travers la maison.
## godot --path . -- --start=hd2d-zone --course=pnj
func _run_pnj() -> void:
	await get_tree().create_timer(0.6).timeout
	var n: Vector2 = zone.npc.position
	var results := []
	# [nom, départ, touches tenues, arrêt quand (personnages côte à côte), parler attendu]
	var cases := [
		["gauche", n + Vector2(-40, 6), [K_R], func(p: Vector2): return p.x >= n.x - 16.0, true],
		["droite", n + Vector2(40, 2), [K_L], func(p: Vector2): return p.x <= n.x + 16.0, true],
		["bas", n + Vector2(0, 40), [K_U], func(p: Vector2): return p.y <= n.y + 14.0, true],
		["bas-gauche (diagonale)", n + Vector2(-32, 34), [K_U, K_R], func(p: Vector2): return p.distance_to(n) <= 17.0, true],
		["bas-droite (diagonale)", n + Vector2(32, 34), [K_U, K_L], func(p: Vector2): return p.distance_to(n) <= 17.0, true],
		["gauche, on longe le mur jusque sous lui", n + Vector2(-40, 6), [K_R], func(p: Vector2): return p.x >= n.x - 3.0, true],
		["bas, contre lui", n + Vector2(0, 40), [K_U], func(_p: Vector2): return false, true],
		["droite, contre lui", n + Vector2(40, 2), [K_L], func(_p: Vector2): return false, true],
		["bas-gauche, contre lui", n + Vector2(-30, 30), [K_U, K_R], func(_p: Vector2): return false, true],
		["trop loin (bas, 34 px)", n + Vector2(0, 40), [K_U], func(p: Vector2): return p.y <= n.y + 34.0, false],
		["derrière la maison", n + Vector2(-8, -78), [K_D], func(_p: Vector2): return false, false],
	]
	for c in cases:
		if c[0] == "derrière la maison":                      # on fait le tour par la gauche, comme un joueur
			for wp in [Vector2(392, 200), Vector2(296, 205), Vector2(296, 160), Vector2(318, 113)]:
				await _goto("contournement", wp)
		elif zone.hero.position.y < n.y + 20.0:              # on contourne le garde par devant (le pilote n'a pas d'A*)
			await _goto("dégagement", Vector2(zone.hero.position.x, n.y + 30.0))
			await _goto("dégagement", Vector2(c[1].x, n.y + 30.0))
		await _goto("départ " + c[0], c[1])
		events.append({"t": _t, "label": "approche " + c[0], "depart": zone.hero.position})
		_set_keys(c[2])
		var t := 0.0
		var last: Vector2 = zone.hero.position
		var still := 0.0
		var overlap := false
		var hold := 0.7 if c[0].ends_with("contre lui") else 3.0     # « contre lui » : on pousse vers lui 0,7 s
		while t < hold:
			await get_tree().process_frame
			t += get_process_delta_time()
			still = still + get_process_delta_time() if zone.hero.position.distance_to(last) < 0.05 else 0.0
			last = zone.hero.position
			var dd0: Vector2 = (zone.hero.position - n).abs()
			overlap = overlap or (dd0.x / 11.5) ** 2 + (dd0.y / 5.5) ** 2 < 1.0   # dans l'emprise du garde (+ pieds)
			if c[3].call(zone.hero.position) or still > 0.25:
				break
		_set_keys([])
		await get_tree().create_timer(0.25).timeout
		var prompt: String = zone._prompt.text if zone._prompt.visible else ""
		_press(KEY_E)
		await get_tree().create_timer(0.1).timeout
		var opened: bool = zone._dialog.is_open()
		var ok: bool = opened == c[4]
		if overlap:
			ok = false                                         # le héros est entré dans l'emprise du garde
			print("PNJ chevauchement pendant l'approche « %s »" % c[0])
		var d: Vector2 = zone.hero.position - n
		results.append({"cas": c[0], "position_relative": [snappedf(d.x, 0.1), snappedf(d.y, 0.1)], "distance": snappedf(d.length(), 0.1),
				"invite": prompt, "dialogue": opened, "attendu": c[4], "ok": ok and (prompt == "E  Parler") == opened})
		print("PNJ %s %-24s rel=(%5.1f,%5.1f) dist=%4.1f invite=«%s» dialogue=%s" % ["ok  " if results[-1]["ok"] else "ÉCHEC", c[0], d.x, d.y, d.length(), prompt, opened])
		_shot("pnj " + c[0])
		if opened:
			_press(KEY_ESCAPE)
			await get_tree().create_timer(0.3).timeout
	var fails := results.filter(func(r): return not r["ok"])
	print("PNJ VERDICT : %s (%d/%d)" % ["RÉUSSI" if fails.is_empty() else "ÉCHEC", results.size() - fails.size(), results.size()])
	if out_path != "":
		FileAccess.open(out_path, FileAccess.WRITE).store_string(JSON.stringify({"pnj": results}, "  "))
	get_tree().quit(0 if fails.is_empty() else 1)


func _press(k: Key) -> void:
	for down in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = k
		ev.physical_keycode = k
		ev.pressed = down
		Input.parse_input_event(ev)


func _step(label: String, keys: Array, sec: float) -> void:
	events.append({"t": _t, "label": label, "depart": zone.hero.position})
	_set_keys(keys)
	await get_tree().create_timer(sec).timeout
	_shot(label)


## Pilote « humain » : maintient les flèches vers un point (8 directions), avec hystérésis pour ne pas
## tapoter les touches. Aucun calcul de chemin : le parcours est choisi pour être praticable.
func _goto(label: String, target: Vector2) -> void:
	events.append({"t": _t, "label": label, "depart": zone.hero.position})
	var t := 0.0
	var h := 0
	var v := 0
	while t < 7.0:
		var to: Vector2 = target - zone.hero.position
		if to.length() < 3.0:
			break
		if h == 0 and absf(to.x) > 4.0:
			h = signi(int(signf(to.x)))
		elif h != 0 and (absf(to.x) < 1.5 or signf(to.x) != h):
			h = 0
		if v == 0 and absf(to.y) > 4.0:
			v = signi(int(signf(to.y)))
		elif v != 0 and (absf(to.y) < 1.5 or signf(to.y) != v):
			v = 0
		var keys := []
		if h > 0: keys.append(K_R)
		if h < 0: keys.append(K_L)
		if v > 0: keys.append(K_D)
		if v < 0: keys.append(K_U)
		_set_keys(keys)
		await get_tree().process_frame
		t += get_process_delta_time()
	_set_keys([])
	var ok: bool = target.distance_to(zone.hero.position) < 4.0
	events[-1]["ok"] = ok
	_shot(label)
	if not ok:
		print("COURSE ÉCHEC « %s » : héros à %.1f px du point" % [label, target.distance_to(zone.hero.position)])


## Capture d'écran à la fin de chaque étape (seulement avec rendu, option --course-shots=dossier).
func _shot(label: String) -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--course-shots=") and DisplayServer.get_name() != "headless":
			var img := get_viewport().get_texture().get_image()
			img.save_png("%s/%02d_%s.png" % [a.substr(15), events.size(), label.validate_filename().replace(" ", "_")])


func _set_keys(keys: Array) -> void:
	for k in [K_R, K_L, K_U, K_D]:
		var down: bool = keys.has(k)
		if bool(_held.get(k, false)) != down:
			var ev := InputEventKey.new()
			ev.keycode = k
			ev.physical_keycode = k
			ev.pressed = down
			Input.parse_input_event(ev)
			_held[k] = down


# ------------------------------------------------------------------------------------------------ mesures
func _process(delta: float) -> void:
	_t += delta
	if _hud:
		var arrows := {K_L: "←", K_U: "↑", K_D: "↓", K_R: "→"}
		var k := ""
		for key in [K_L, K_U, K_D, K_R]:
			k += arrows[key] if _held.get(key, false) else "·"
		_hud.text = "Parcours clavier (sans autoplay)   touches : %s\n%s" % [k, events[-1]["label"] if events.size() else ""]
	var row := {"t": _t, "dt": delta, "keys": _held.keys().filter(func(k): return _held[k]).size(), "m": []}
	for w in zone.party:
		row["m"].append({
			"p": w.position, "anim": String(w.spr.animation), "fr": w.spr.frame, "flip": w.spr.flip_h,
			"free": zone.free_at(w.position), "depth_err": _depth_error(w),
		})
	frames.append(row)
	if mode == "observer" and frames.size() > 60 and zone._engaging:
		_finish()


## Erreur de profondeur : le personnage recouvre un élément mais il est dessiné du mauvais côté par rapport
## au bord avant RÉEL de l'emprise au sol, à son abscisse (et non par rapport à une seule ligne horizontale).
func _depth_error(w) -> String:
	for o in zone.occluders:
		var s: Sprite2D = o["sprite"]
		var fp: PackedVector2Array = o.get("footprint", PackedVector2Array())
		if fp.size() < 3:
			continue
		var r := Rect2(w.position + Vector2(-6, -26), Vector2(12, 26))
		if not o["rect"].intersects(r):
			continue
		if not zone._opaque_at(s, w.position + Vector2(0, -12)) and not zone._opaque_at(s, w.position + Vector2(0, -4)):
			continue
		var edge: float = front_edge(fp, w.position.x)
		if is_nan(edge):
			continue
		var geo_front: bool = w.position.y > edge
		var drawn_front: bool = zone.drawn_in_front(w, o)
		if geo_front != drawn_front:
			if not OS.get_cmdline_user_args().has("--course-debug"):
				return "%s:%s" % [o["name"], "devant_dessiné_derrière" if geo_front else "derrière_dessiné_devant"]
			return "%s:%s %s z%d/%d" % [o["name"], "devant_dessiné_derrière" if geo_front else "derrière_dessiné_devant", w.position.round(), w.z_index, s.z_index]
	return ""


## Bord avant de l'emprise au sol (y maximal du polygone) à l'abscisse x ; NAN hors de l'emprise.
static func front_edge(fp: PackedVector2Array, x: float) -> float:
	var best := NAN
	for i in fp.size():
		var a := fp[i]
		var b := fp[(i + 1) % fp.size()]
		if (x < minf(a.x, b.x)) or (x > maxf(a.x, b.x)) or absf(b.x - a.x) < 0.001:
			continue
		var y := lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
		if is_nan(best) or y > best:
			best = y
	return best


func _finish() -> void:
	_set_keys([])
	var rep := analyse()
	print("COURSE RÉSUMÉ ", JSON.stringify(rep))
	var fails := verdict(rep)
	for f in fails:
		print("COURSE CRITÈRE NON TENU : ", f)
	print("COURSE VERDICT : %s" % ("RÉUSSI" if fails.is_empty() else "ÉCHEC"))
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(JSON.stringify({"summary": rep, "events": events, "echecs": fails}, "  "))
	get_tree().quit(0 if fails.is_empty() else 1)


## Critères d'acceptation de la locomotion (code de sortie 1 si l'un n'est pas tenu).
static func verdict(rep: Dictionary) -> Array:
	var fails := []
	if not rep["etapes_ratees"].is_empty():
		fails.append("étapes non atteintes : %s" % [rep["etapes_ratees"]])
	for k in ["aren", "ilya", "throne"]:
		var m: Dictionary = rep[k]
		if m["flashs_repos_en_marche"] > 2:
			fails.append("%s : %d images de repos au milieu d'une marche" % [k, m["flashs_repos_en_marche"]])
		if m["arrets_pendant_marche_du_heros"] > 3:
			fails.append("%s : %d arrêts alors que le héros marche" % [k, m["arrets_pendant_marche_du_heros"]])
		if absf(m["ratio_pas_distance"] - 1.0) > 0.08:
			fails.append("%s : images de pas désynchronisées de la distance (ratio %.2f)" % [k, m["ratio_pas_distance"]])
		if m["images_en_position_interdite"] > 0:
			fails.append("%s : %d images dans un obstacle" % [k, m["images_en_position_interdite"]])
		var de := 0
		for e in m["erreurs_profondeur_images"].values():
			de += e
		if de > 5:
			fails.append("%s : %d images mal triées en profondeur" % [k, de])
	for g in ["ecart_aren_ilya", "ecart_ilya_throne"]:
		if rep[g]["ecart_type"] > 4.0:
			fails.append("%s : espacement irrégulier (écart-type %.1f px)" % [g, rep[g]["ecart_type"]])
	return fails


func analyse() -> Dictionary:
	var names := ["aren", "ilya", "throne"]
	var rep := {"frames": frames.size(), "duree_s": snappedf(_t, 0.01), "etapes_ratees": events.filter(func(e): return e.has("ok") and not e["ok"]).map(func(e): return e["label"])}
	for i in names.size():
		var flick := 0          # orientation tenue moins de 0,15 s pendant la marche
		var turns := 0
		var idle_flash := 0     # 1 à 3 images au repos au milieu d'une marche
		var stops := 0          # arrêts complets pendant que le héros marche
		var px_per_step: Array = []
		var acc := 0.0
		var last_face := ""
		var face_t := 0.0
		var run_idle := 0
		var was_moving := false
		var bad_pos := 0
		var depth := {}
		var adv := 0
		var walk_dist := 0.0
		for j in range(1, frames.size()):
			var a: Dictionary = frames[j - 1]["m"][i]
			var b: Dictionary = frames[j]["m"][i]
			var dt: float = frames[j]["dt"]
			var moved: float = (b["p"] - a["p"]).length()
			var face := _facing(b)
			var walking: bool = String(b["anim"]).begins_with("walk")
			if walking:
				if face != last_face:
					if last_face != "":
						turns += 1
						if face_t < 0.15:
							flick += 1
							rep["orientations_breves_detail"] = rep.get("orientations_breves_detail", []) + ["%s %s→%s @%.2fs (%s)" % [names[i], last_face, face, frames[j]["t"], _event_at(frames[j]["t"])]]
					last_face = face
					face_t = 0.0
				face_t += dt
				if run_idle > 0 and run_idle <= 3 and was_moving:
					idle_flash += 1
				run_idle = 0
				was_moving = true
				acc += moved
				walk_dist += moved
				if b["anim"] == a["anim"] and b["fr"] != a["fr"]:
					adv += 1
				if b["fr"] != a["fr"] or b["anim"] != a["anim"]:
					px_per_step.append(acc)
					acc = 0.0
			else:
				run_idle += 1
				if run_idle > 3:
					was_moving = false
					acc = 0.0
			if i > 0:
				var hero_moving: bool = (frames[j]["m"][0]["p"] - frames[j - 1]["m"][0]["p"]).length() > 0.05
				var prev_moving: bool = j >= 2 and (a["p"] - frames[j - 2]["m"][i]["p"]).length() > 0.05
				if hero_moving and prev_moving and moved < 0.05:
					stops += 1
			if not b["free"]:
				bad_pos += 1
			if b["depth_err"] != "":
				depth[b["depth_err"]] = int(depth.get(b["depth_err"], 0)) + 1
		var s := _stats(px_per_step.slice(1))
		rep[names[i]] = {
			"changements_orientation": turns, "orientations_breves": flick, "flashs_repos_en_marche": idle_flash,
			"arrets_pendant_marche_du_heros": stops, "px_par_image_de_marche_moy": s[0], "px_par_image_ecart_type": s[1],
			"images_en_position_interdite": bad_pos, "erreurs_profondeur_images": depth,
			"distance_marche_px": snappedf(walk_dist, 0.1), "images_de_pas_avancees": adv,
			"ratio_pas_distance": snappedf(adv * 6.0 / walk_dist, 0.01) if walk_dist > 0.0 else 0.0,
		}
	# espacements dans la file quand tout le monde marche
	for pair in [[0, 1], [1, 2]]:
		var gaps: Array = []
		var overlap := 0
		for j in range(1, frames.size()):
			var mv := true
			for k in pair:
				mv = mv and (frames[j]["m"][k]["p"] - frames[j - 1]["m"][k]["p"]).length() > 0.05
			var g: float = (frames[j]["m"][pair[0]]["p"] - frames[j]["m"][pair[1]]["p"]).length()
			if g < 7.0:
				overlap += 1
				if overlap == 1 or (g < 7.0 and (frames[j - 1]["m"][pair[0]]["p"] - frames[j - 1]["m"][pair[1]]["p"]).length() >= 7.0):
					rep["chevauchements"] = rep.get("chevauchements", []) + ["%s-%s @%.2fs (%s)" % [names[pair[0]], names[pair[1]], frames[j]["t"], _event_at(frames[j]["t"])]]
			if mv:
				gaps.append(g)
		var s := _stats(gaps)
		rep["ecart_%s_%s" % [names[pair[0]], names[pair[1]]]] = {"moy": s[0], "ecart_type": s[1], "min": snappedf(gaps.min() if gaps.size() else 0.0, 0.1), "max": snappedf(gaps.max() if gaps.size() else 0.0, 0.1), "images_chevauchement": overlap}
	return rep


func _event_at(t: float) -> String:
	var l := ""
	for e in events:
		if e["t"] <= t:
			l = e["label"]
	return l


func _facing(m: Dictionary) -> String:
	var an: String = m["anim"]
	var d := an.substr(an.find("_") + 1)
	if d == "right" and m["flip"]:
		return "left"
	return d


func _stats(a: Array) -> Array:
	if a.is_empty():
		return [0.0, 0.0]
	var mean := 0.0
	for x in a:
		mean += x
	mean /= a.size()
	var v := 0.0
	for x in a:
		v += (x - mean) * (x - mean)
	return [snappedf(mean, 0.01), snappedf(sqrt(v / a.size()), 0.01)]
