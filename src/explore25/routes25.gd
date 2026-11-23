extends RefCounted
## P3 — Parcours automatiques (clavier simulé, 8 directions) : identiques pour les démonstrations A et B.
## Coordonnées dans le plan du doc 06 (m). « push » : pousse dans une direction ÉCRAN pendant t secondes et vérifie
## la position obtenue (collisions). « warp » : place le héros (essais ciblés, captures).

static func _go(x: float, y: float, id := "", tol := 0.3) -> Dictionary:
	var d := {"do": "go", "to": Vector2(x, y), "tol": tol}
	if id != "":
		d["id"] = id
	return d


static func _warp(x: float, y: float, h: float) -> Dictionary:
	return {"do": "warp", "to": Vector3(x, y, h)}


static func _push(id: String, dir: Vector2, t: float, expect: Dictionary) -> Dictionary:
	return {"do": "push", "id": id, "dir": dir, "t": t, "expect": expect}


## P6.2-D : décalage du bloc sud du Colisée (longueur du tunnel), réglé par la scène au chargement ; les parcours « p6 »
## écrits pour le tunnel de 6,5 m sont décalés d'autant (x dans [x0, x1], y >= y0 : y + dy).
static var decalage_sud := {}


static func route(name: String) -> Array:
	if name == "p6_tunnel_cmp":
		# P6.2-D — comparaison des longueurs du tunnel : mêmes positions RELATIVES (salle, entrée, milieu, fin, débouché)
		var dy := float(decalage_sud.get("dy", 0.0))
		var e := 37.5 + dy
		var out0: Array = []
		for c in [["t1_salle", e + 3.0], ["t2_entree", e - 0.8], ["t3_milieu", (32.0 + e) * 0.5], ["t4_fin", 32.7],
				["t5_debouche", 31.0], ["t6_arene", 29.0]]:
			out0.append(_warp(26.0, c[1], 0.0))
			out0.append({"do": "wait", "t": 1.5})
			out0.append({"do": "snap", "id": c[0]})
		return out0
	var r := _route_base(name)
	if not name.begins_with("p6") or decalage_sud.is_empty() or float(decalage_sud.get("dy", 0.0)) == 0.0:
		return r
	var out: Array = []
	for st in r:
		var d: Dictionary = (st as Dictionary).duplicate()
		if d.has("to"):
			d["to"] = sud(d["to"])
		if d.has("expect") and d["do"] == "push" and out.size() > 0 and out[-1].get("do", "") == "warp":
			# sonde : seuils exprimés dans le repère du tunnel de 6,5 m -> décalés avec le point de départ
			var w0: Vector3 = r[out.size() - 1]["to"]
			var dyw: float = (out[-1]["to"] as Vector3).y - w0.y
			var ex: Dictionary = (d["expect"] as Dictionary).duplicate()
			for k in ["min_y", "max_y"]:
				if ex.has(k):
					ex[k] = float(ex[k]) + dyw
			d["expect"] = ex
		out.append(d)
	return out


static func sud(v):
	if decalage_sud.is_empty():
		return v
	var xs: Array = decalage_sud["x"]
	var dy := float(decalage_sud["dy"])
	if v is Vector2 and v.x >= xs[0] and v.x <= xs[1] and v.y >= float(decalage_sud["y"]):
		return Vector2(v.x, v.y + dy)
	if v is Vector3 and v.x >= xs[0] and v.x <= xs[1] and v.y >= float(decalage_sud["y"]):
		return Vector3(v.x, v.y + dy, v.z)
	return v


static func _route_base(name: String) -> Array:
	match name:
		"p6_avant":
			# P6 — ouverture, avant le tutoriel : vestiaires (garde) → salle d'attente → arène → commandant. Le
			# dialogue du commandant s'ouvre seul à 2,6 m ; à sa fermeture, le combat tutoriel est lancé.
			return [
				{"do": "wait", "t": 0.8},
				_go(27.4, 48.6, "A garde des vestiaires", 0.3),
				{"do": "talk", "id": "garde_vestiaires"},
				{"do": "wait", "t": 7.0},
				_go(26.0, 45.6, "passage des vestiaires", 0.3),
				_go(26.0, 41.2, "B salle d'attente", 0.3),
				_go(26.0, 35.0, "tunnel sud", 0.3),
				_go(26.0, 30.0, "C entrée de l'arène", 0.3),
				_go(26.0, 23.1, "D devant le commandant", 0.45),
				{"do": "talk", "id": "commandant"},
				{"do": "wait", "t": 12.0},
			]
		"p6_apres":
			# P6 — après le tutoriel (retour devant le commandant) : coursive, PNJ, sortie est, quartier.
			return [
				{"do": "wait", "t": 9.0},
				{"do": "talk", "id": "commandant"},
				{"do": "wait", "t": 3.0},
				_go(33.0, 23.0, "arène (vers l'est)", 0.3),
				_go(39.5, 23.0, "grille est (levée)", 0.3),
				_go(44.6, 23.0, "E entrée de la coursive", 0.3),
				_go(47.8, 24.8, "chasseur reçu", 0.3),
				{"do": "talk", "id": "chasseur_reussi"},
				{"do": "wait", "t": 3.0},
				_go(50.0, 30.6, "coursive (entre les piliers)", 0.3),
				_go(53.4, 30.4, "chasseuse recalée", 0.35),
				{"do": "talk", "id": "chasseuse_echouee"},
				{"do": "wait", "t": 4.0},
				_go(55.0, 23.2, "coursive (est)", 0.3),
				_go(58.5, 23.4, "couloir de sortie", 0.3),
				_go(62.5, 23.2, "F sortie est", 0.3),
				{"do": "go", "to": Vector2(64.4, 23.0), "tol": 0.25, "id": "porte de la ville", "exit": true},
				{"do": "wait", "t": 1.5},
				_go(10.0, 8.0, "quartier", 0.3),
				_go(25.8, 8.0, "panneau de la Guilde", 0.3),
				{"do": "talk", "id": "ex_panneau_guilde"},
				{"do": "wait", "t": 2.0},
			]
		"p6_sondes":
			# P6 — sondes de collision (portes fermées, podium, murs) : pousse contre l'obstacle et vérifie la position.
			return [
				{"do": "wait", "t": 0.5},
				_warp(36.0, 23.0, 0.0),
				_push("grille est fermée (avant le tutoriel)", Vector2(1, 0), 3.0, {"max_x": 38.3}),
				_warp(54.6, 23.0, 0.0),
				_push("porte de la ville fermée (avant le tutoriel)", Vector2(1, 0), 3.0, {"max_x": 56.4}),
				_warp(50.0, 13.4, 0.0),
				_push("loge officielle fermée", Vector2(0, -1), 2.5, {"min_y": 12.2}),
				_warp(53.0, 33.0, 0.0),
				_push("réserve fermée", Vector2(0, 1), 2.5, {"max_y": 34.0}),
				_warp(21.4, 41.0, 0.0),
				_push("porte de service (salle d'attente)", Vector2(-1, 0), 2.5, {"min_x": 20.1}),
				_warp(19.0, 23.0, 0.0),
				_push("podium ouest de l'arène", Vector2(-1, 0), 4.0, {"min_x": 13.6}),
				_warp(26.0, 16.0, 0.0),
				_push("podium nord de l'arène", Vector2(0, -1), 4.0, {"min_y": 14.1}),
				_warp(26.0, 52.0, 0.0),
				_push("mur sud des vestiaires", Vector2(0, 1), 3.0, {"max_y": 54.8}),
				_warp(18.0, 52.0, 0.0),
				_push("porte des vestiaires vers la rue (fermée)", Vector2(-1, 0), 3.0, {"min_x": 16.1}),
				_warp(26.0, 44.0, 0.0),
				_push("passage salle d'attente → vestiaires", Vector2(0, 1), 2.0, {"min_y": 46.0}),
			]
		"p6_cam":
			# P6.1 — six positions de comparaison des caméras (même ordre pour A, B et C)
			var pts := [["1_vestiaires", 26.0, 50.6], ["2_salle_attente", 26.0, 41.2], ["3_entree_arene", 26.0, 30.2],
				["4_centre_arene", 26.0, 24.2], ["5_coursive", 49.6, 24.6], ["6_sortie_est", 61.0, 23.0]]
			var out := [{"do": "wait", "t": 1.0}]
			for p in pts:
				out.append(_warp(p[1], p[2], 0.0))
				out.append({"do": "wait", "t": 1.4})
				out.append({"do": "snap", "id": p[0]})
			return out
		"p6_aren":
			# P6.1 — Aren en jeu : immobile, marche et course vers la droite, de face (centre de l'arène)
			return [
				_warp(22.0, 24.0, 0.0),
				{"do": "wait", "t": 1.5},
				{"do": "push", "id": "pose droite", "dir": Vector2(1, 0), "t": 0.12, "expect": {}},
				{"do": "wait", "t": 1.0},
				{"do": "snap", "id": "aren_immobile"},
				{"do": "push", "id": "marche droite", "dir": Vector2(1, 0), "t": 0.75, "expect": {}},
				{"do": "snap", "id": "aren_marche"},
				{"do": "push", "id": "course droite", "dir": Vector2(1, 0), "t": 0.62, "run": true, "expect": {}},
				{"do": "snap", "id": "aren_course"},
				{"do": "push", "id": "vers le bas", "dir": Vector2(0, 1), "t": 0.5, "expect": {}},
				{"do": "snap", "id": "aren_face_marche"},
				{"do": "wait", "t": 1.0},
				{"do": "snap", "id": "aren_face"},
			]
		"p6_video_cam":
			# P6.1 — courte traversée filmée (vestiaires -> arène -> coursive), identique pour les trois caméras
			return [
				{"do": "wait", "t": 0.8},
				_go(26.0, 45.6, "passage", 0.3),
				_go(26.0, 38.5, "salle d'attente", 0.3),
				_go(26.0, 30.0, "entrée de l'arène", 0.3),
				_go(31.0, 25.5, "arène", 0.3),
				_go(39.5, 23.0, "grille est", 0.3),
				_go(46.0, 23.0, "coursive", 0.3),
				{"do": "wait", "t": 0.6},
			]
		"p6_az":
			# P6.2 — comparaison d'azimut : mêmes points dans les vestiaires, la salle d'attente et la coursive
			var pts := [["1_vestiaires_centre", 26.0, 51.0], ["2_vestiaires_porte", 26.0, 47.3], ["3_salle_attente", 26.0, 41.0],
				["4_tunnel_sud", 26.0, 34.0], ["5_arene", 26.0, 25.0], ["6_coursive", 50.0, 23.0]]
			var out := [{"do": "wait", "t": 1.0}]
			for p in pts:
				out.append(_warp(p[1], p[2], 0.0))
				out.append({"do": "wait", "t": 1.4})
				out.append({"do": "snap", "id": p[0]})
			return out
		"p6_pieces":
			# P6.2 — prototype des deux pièces : centre, angles, murs, porte, passage, salle, tunnel (captures)
			var pts := [["01_vestiaires_centre", 26.0, 51.0], ["02_vestiaires_angle_no", 17.2, 48.0], ["03_vestiaires_angle_se", 34.6, 54.4],
				["04_vestiaires_mur_sud", 26.0, 54.6], ["05_vestiaires_porte", 26.0, 47.0], ["06_passage", 26.0, 45.5],
				["07_salle_entree", 26.0, 43.8], ["08_salle_centre", 26.0, 41.0], ["09_salle_angle_no", 21.5, 38.2],
				["10_salle_angle_se", 30.4, 44.0], ["11_salle_vers_tunnel", 26.0, 38.2], ["12_tunnel", 26.0, 34.5]]
			var out := [{"do": "wait", "t": 1.2}]
			for p in pts:
				out.append(_warp(p[1], p[2], 0.0))
				out.append({"do": "wait", "t": 1.3})
				out.append({"do": "snap", "id": p[0]})
			return out
		"p6_video_pieces":
			# P6.2 — vidéo du prototype : vestiaires (murs, PNJ, porte) -> salle d'attente (murs, PNJ) -> tunnel, puis retour en
			# courant jusqu'au fond des vestiaires ; marche et course, transitions dans les deux sens
			return [
				_warp(26.0, 52.5, 0.0),
				{"do": "wait", "t": 1.5},
				_go(17.4, 52.5, "vestiaires : vers l'ouest (devant la recrue)", 0.3),
				_go(17.4, 48.2, "vestiaires : le long des casiers ouest", 0.3),
				_go(26.0, 48.1, "vestiaires : devant les casiers nord", 0.3),
				{"do": "wait", "t": 0.6},
				_go(26.0, 45.5, "porte et passage", 0.25),
				_go(26.0, 43.8, "entrée de la salle d'attente", 0.25),
				_go(22.6, 43.7, "salle : angle sud-ouest", 0.3),
				_go(22.6, 38.6, "salle : le long du mur ouest", 0.3),
				_go(29.5, 43.9, "salle : vers l'angle sud-est", 0.35),
				_go(26.0, 38.4, "salle : vers le tunnel", 0.3),
				_go(26.0, 34.8, "tunnel : l'arène se révèle", 0.3),
				{"do": "wait", "t": 1.0},
				{"do": "push", "id": "retour en courant", "dir": Vector2(0, 1), "t": 5.5, "run": true, "expect": {}},
				{"do": "push", "id": "vestiaires : vers l'est en courant", "dir": Vector2(1, 0), "t": 1.6, "run": true, "expect": {}},
				{"do": "push", "id": "vestiaires : vers l'ouest", "dir": Vector2(-1, 0), "t": 2.4, "expect": {}},
				{"do": "wait", "t": 1.0},
			]
		"p6_attente":
			return [{"do": "wait", "t": 9.0}]
		"p6_video_transitions":
			# P6.2-B — même trajet pour comparer les modes A / B / C : centre des vestiaires, porte nord, seuil, arrêt au
			# milieu du passage, retour, nouvelle entrée dans la salle, approche du tunnel, découverte de l'arène
			return [
				_warp(26.0, 51.0, 0.0),
				{"do": "wait", "t": 2.0},
				_go(26.0, 47.4, "vestiaires : approche de la porte nord", 0.25),
				{"do": "wait", "t": 0.8},
				_go(26.0, 45.6, "seuil franchi : milieu du passage", 0.2),
				{"do": "wait", "t": 2.5},
				_go(26.0, 46.3, "petit pas en arrière (dans la porte)", 0.15),
				{"do": "wait", "t": 1.0},
				_go(26.0, 45.0, "de nouveau en avant", 0.15),
				{"do": "wait", "t": 1.0},
				_go(26.0, 49.5, "retour dans les vestiaires", 0.25),
				{"do": "wait", "t": 1.5},
				_go(26.0, 43.0, "nouvelle entrée dans la salle d'attente", 0.25),
				{"do": "wait", "t": 1.0},
				_go(26.0, 38.4, "approche du tunnel", 0.25),
				{"do": "wait", "t": 0.8},
				_go(26.0, 33.0, "tunnel : découverte de l'arène", 0.25),
				{"do": "wait", "t": 2.0},
			]
		"p6_tunnel":
			# P6.2-C — trajet continu, vitesse réelle (12 étapes demandées) : vestiaires -> salle -> tunnel -> arène -> retour
			return [
				_warp(26.0, 51.0, 0.0),
				{"do": "wait", "t": 1.5},
				_go(26.0, 47.3, "1-2 vestiaires : approche de la porte nord", 0.2),
				{"do": "wait", "t": 0.6},
				_go(26.0, 43.9, "3-4 passage puis arrêt juste après le seuil de la salle", 0.15),
				{"do": "wait", "t": 1.5},
				_go(26.0, 45.3, "5 pas en arrière (dans le passage)", 0.15),
				{"do": "wait", "t": 0.8},
				_go(26.0, 43.6, "5 de nouveau le seuil", 0.15),
				{"do": "wait", "t": 0.6},
				_go(26.0, 38.2, "6 traversée de la salle", 0.2),
				_go(26.0, 36.6, "7 entrée dans le tunnel", 0.2),
				_go(26.0, 34.7, "8 arrêt au milieu du tunnel", 0.15),
				{"do": "wait", "t": 2.0},
				_go(26.0, 32.6, "9 vers la sortie du tunnel", 0.15),
				{"do": "wait", "t": 0.8},
				_go(26.0, 30.4, "9 sortie dans l'arène", 0.2),
				{"do": "wait", "t": 0.8},
				_go(26.0, 22.6, "10 jusqu'au commandant", 0.2),
				{"do": "wait", "t": 1.5},
				_go(26.0, 30.0, "11 retour vers le tunnel", 0.2),
				_go(26.0, 34.0, "12 de nouveau dans le tunnel", 0.2),
				{"do": "wait", "t": 1.5},
			]
		"p6_tunnel_captures":
			# P6.2-C — captures de comparaison : salle, milieu du tunnel, sortie du tunnel, seuil, arène
			var out: Array = []
			for c in [["1_salle", 26.0, 40.6], ["2_salle_fond", 26.0, 38.4], ["3_tunnel_milieu", 26.0, 34.7],
					["4_tunnel_sortie", 26.0, 32.4], ["5_seuil_arene", 26.0, 31.0], ["6_arene_entree", 26.0, 29.0],
					["7_arene", 26.0, 25.5], ["8_commandant", 26.0, 22.6]]:
				out.append(_warp(c[1], c[2], 0.0))
				out.append({"do": "wait", "t": 1.6})
				out.append({"do": "snap", "id": c[0]})
			return out
		"p6_retour_tunnel":
			# P6.2-C — retour de l'arène dans le tunnel : fond sombre et vue recadrée par la bouche dès l'entrée
			return [_warp(26.0, 28.0, 0.0), {"do": "wait", "t": 1.5}, _go(26.0, 34.0, "retour dans le tunnel", 0.2),
				{"do": "wait", "t": 0.25}, {"do": "snap", "id": "retour_tunnel_0s25"}]
		"p6_vestiaires_captures":
			# P6.2-D — vestiaires : centre, quatre coins, portes (fermeture des lignes de vue)
			var outv: Array = []
			for c in [["v1_centre", 26.0, 51.0], ["v2_coin_no", 17.4, 47.4], ["v3_coin_ne", 34.6, 47.4], ["v4_coin_so", 17.4, 54.2],
					["v5_coin_se", 34.6, 54.2], ["v6_porte_nord", 26.0, 47.0], ["v7_porte_rue", 17.2, 51.9], ["v8_droite", 33.5, 51.0]]:
				outv.append(_warp(c[1], c[2], 0.0))
				outv.append({"do": "wait", "t": 1.4})
				outv.append({"do": "snap", "id": c[0]})
			return outv
		"p6_complet_captures":
			# P6.2-D — Colisée complet : arène, tunnel est, coursive, accès secondaires, sortie est (après le tutoriel)
			var outc: Array = []
			for c in [["c01_arene_centre", 26.0, 24.0], ["c02_arene_ouest", 16.5, 23.0], ["c03_arene_est", 35.5, 23.0],
					["c04_arene_nord", 26.0, 16.5], ["c05_tunnel_est_entree", 39.5, 23.0], ["c06_tunnel_est_milieu", 41.5, 23.0],
					["c07_coursive_ouest", 45.5, 23.0], ["c08_coursive_centre", 50.0, 23.0], ["c09_coursive_nord_loge", 50.0, 13.4],
					["c10_coursive_sud", 50.0, 32.6], ["c11_infirmerie", 46.6, 37.8], ["c12_reserve_porte", 53.0, 33.2],
					["c13_gradins_est_porte", 54.8, 16.0], ["c14_sortie_couloir", 59.5, 23.0], ["c15_sortie_porte", 63.0, 23.0]]:
				outc.append(_warp(c[1], c[2], 0.0))
				outc.append({"do": "wait", "t": 1.5})
				outc.append({"do": "snap", "id": c[0]})
			return outc
		"p6_video_complet_avant":
			# P6.2-D — vidéo du Colisée complet, 1re partie (avant le tutoriel) : vestiaires -> salle -> tunnel sud (arrêt
			# au milieu) -> arène -> retour dans le tunnel -> arène -> commandant (tutoriel passé au dialogue)
			return [
				{"do": "wait", "t": 1.0},
				_go(26.0, 47.6, "vestiaires : porte nord", 0.25),
				_go(26.0, 45.6, "passage", 0.25),
				_go(26.0, 41.2, "salle d'attente", 0.25),
				{"do": "wait", "t": 0.8},
				_go(26.0, 36.0, "tunnel sud : entrée", 0.25),
				_go(26.0, 34.6, "tunnel sud : milieu", 0.2),
				{"do": "wait", "t": 1.5},
				_go(26.0, 30.2, "débouché dans l'arène", 0.25),
				{"do": "wait", "t": 0.8},
				_go(26.0, 34.0, "retour dans le tunnel sud", 0.25),
				{"do": "wait", "t": 1.0},
				_go(26.0, 29.5, "de nouveau l'arène", 0.25),
				_go(26.0, 23.1, "devant le commandant", 0.45),
				{"do": "talk", "id": "commandant"},
				{"do": "wait", "t": 14.0},
			]
		"p6_video_complet_apres":
			# P6.2-D — 2e partie (après le tutoriel) : arène -> tunnel est (aller, retour, aller) -> coursive -> infirmerie
			# (porte) -> sortie est -> quartier
			return [
				{"do": "wait", "t": 7.0},
				_go(33.0, 23.0, "arène vers l'est", 0.3),
				_go(41.2, 23.0, "tunnel est : milieu", 0.25),
				{"do": "wait", "t": 1.0},
				_go(36.5, 23.0, "retour dans l'arène", 0.25),
				{"do": "wait", "t": 0.8},
				_go(44.8, 23.0, "coursive : entrée", 0.25),
				_go(50.0, 23.0, "coursive : centre", 0.3),
				_go(46.6, 33.3, "porte de l'infirmerie", 0.3),
				{"do": "wait", "t": 0.8},
				_go(50.0, 26.0, "coursive", 0.3),
				_go(55.0, 23.2, "coursive (est)", 0.3),
				_go(58.5, 23.2, "couloir de sortie", 0.3),
				_go(62.5, 23.2, "sortie est", 0.3),
				{"do": "go", "to": Vector2(64.4, 23.0), "tol": 0.25, "id": "porte de la ville", "exit": true},
				{"do": "wait", "t": 1.5},
				_go(10.0, 8.0, "quartier", 0.3),
				{"do": "wait", "t": 1.5},
			]
		"p6_video_642_apres":
			# P6.4.2 — suite de la vidéo continue après le tutoriel passé : arène -> tunnel est -> coursive (infirmerie,
			# réserve) -> couloir de sortie -> sortie est (arrêt devant la porte : la ville est hors périmètre)
			return [
				{"do": "wait", "t": 7.0},
				_go(33.0, 23.0, "arène vers l'est", 0.3),
				_go(41.2, 23.0, "tunnel est : milieu", 0.25),
				{"do": "wait", "t": 0.6},
				_go(44.8, 23.0, "coursive : entrée", 0.25),
				_go(50.0, 25.0, "coursive : centre", 0.3),
				_go(46.6, 33.3, "porte de l'infirmerie", 0.3),
				_go(46.6, 36.4, "infirmerie", 0.3),
				{"do": "wait", "t": 0.6},
				_go(46.6, 33.0, "retour dans la coursive", 0.3),
				_go(53.0, 32.6, "devant la réserve", 0.3),
				{"do": "wait", "t": 0.8},
				_go(55.0, 23.2, "coursive (est)", 0.3),
				_go(58.5, 23.2, "couloir de sortie", 0.3),
				_go(62.8, 23.2, "sortie est", 0.3),
				{"do": "wait", "t": 1.5},
			]
		"p6_video_643_avant":
			# P6.4.3 — vidéo de validation, 1re partie : même parcours que P6.4.2 (vestiaires -> salle -> tunnel sud ->
			# arène, aller-retour au débouché), puis vue générale de l'arène au zoom ×2, retour à ×3, commandant
			return [
				{"do": "wait", "t": 1.0},
				_go(26.0, 47.6, "vestiaires : porte nord", 0.25),
				_go(26.0, 45.6, "passage", 0.25),
				_go(26.0, 41.2, "salle d'attente", 0.25),
				{"do": "wait", "t": 0.8},
				_go(26.0, 36.0, "tunnel sud : entrée", 0.25),
				_go(26.0, 34.6, "tunnel sud : milieu", 0.2),
				{"do": "wait", "t": 1.0},
				_go(26.0, 30.2, "débouché dans l'arène", 0.25),
				{"do": "wait", "t": 0.6},
				_go(26.0, 34.0, "retour dans le tunnel sud", 0.25),
				_go(26.0, 28.0, "de nouveau l'arène", 0.25),
				{"do": "zoom", "i": 0, "smooth": true},
				{"do": "wait", "t": 1.2},
				_go(20.5, 25.5, "arène : vers les gradins ouest (×2)", 0.3),
				_go(26.0, 26.5, "arène : centre (×2)", 0.3),
				{"do": "zoom", "i": 2, "smooth": true},
				{"do": "wait", "t": 0.8},
				_go(26.0, 23.1, "devant le commandant", 0.45),
				{"do": "talk", "id": "commandant"},
				{"do": "wait", "t": 14.0},
			]
		"p6_video_643_apres":
			# P6.4.3 — 2e partie (tutoriel passé) : gradins sud-est et bouche du tunnel est (×2 puis ×3), tunnel est,
			# coursive, infirmerie (soigneuse), retour dans la coursive, sortie est
			return [
				{"do": "wait", "t": 7.0},
				_go(30.0, 26.5, "arène : vers les gradins sud-est", 0.3),
				{"do": "zoom", "i": 0, "smooth": true},
				{"do": "wait", "t": 0.8},
				_go(35.0, 23.0, "arène : bouche du tunnel est (×2)", 0.3),
				{"do": "wait", "t": 0.8},
				{"do": "zoom", "i": 2, "smooth": true},
				_go(41.2, 23.0, "tunnel est : milieu", 0.25),
				_go(44.8, 23.0, "coursive : entrée", 0.25),
				_go(50.0, 25.0, "coursive : centre", 0.3),
				_go(46.6, 33.3, "porte de l'infirmerie", 0.3),
				_go(47.2, 37.4, "infirmerie : soigneuse", 0.3),
				{"do": "talk", "id": "soigneuse"},
				{"do": "wait", "t": 7.0},
				_go(46.6, 33.0, "retour dans la coursive", 0.3),
				_go(53.0, 32.6, "devant la réserve", 0.3),
				{"do": "wait", "t": 0.6},
				_go(55.0, 23.2, "coursive (est)", 0.3),
				_go(58.5, 23.2, "couloir de sortie", 0.3),
				_go(62.8, 23.2, "sortie est", 0.3),
				{"do": "wait", "t": 1.5},
			]
		"p6_traversee":
			# P6.2-D — traversée complète d'un seul tenant (après le tutoriel), avec arrêts et demi-tours aux seuils : mesure
			# de la continuité de la caméra (tools/p6/camera_continuite_p6.gd)
			return [
				_warp(26.0, 51.0, 0.0),
				{"do": "wait", "t": 1.2},
				_go(26.0, 43.9, "salle : juste après le seuil", 0.15),
				{"do": "wait", "t": 1.0},
				_go(26.0, 45.3, "pas en arrière", 0.15),
				_go(26.0, 41.0, "salle", 0.2),
				_go(26.0, 34.6, "tunnel sud : milieu", 0.15),
				{"do": "wait", "t": 1.2},
				_go(26.0, 30.0, "arène", 0.2),
				_go(26.0, 33.5, "retour dans le tunnel", 0.2),
				_go(26.0, 24.0, "arène : centre", 0.2),
				_go(41.2, 24.0, "tunnel est : milieu", 0.2),
				{"do": "wait", "t": 1.0},
				_go(37.0, 24.0, "retour dans l'arène", 0.2),
				_go(45.0, 24.0, "coursive : seuil", 0.15),
				{"do": "wait", "t": 0.8},
				_go(50.0, 23.0, "coursive", 0.2),
				_go(57.5, 23.0, "couloir de sortie : seuil", 0.15),
				{"do": "wait", "t": 0.8},
				_go(55.5, 23.0, "pas en arrière (coursive)", 0.15),
				_go(62.5, 23.0, "sortie est", 0.2),
				{"do": "wait", "t": 1.0},
			]
		"p6_gros_plans":
			# P6.3 — gros plans : bannières depuis plusieurs positions, porte nord des vestiaires (ancienne fausse marche)
			var outg: Array = []
			for c in [["g1_porte_vestiaires", 26.0, 48.6], ["g2_bannieres_porte_gauche", 23.0, 48.4],
					["g3_coursive_bannieres_ouest", 46.6, 13.4], ["g4_coursive_bannieres_est", 53.4, 13.4],
					["g5_podium_nord", 22.0, 16.2], ["g6_podium_ouest", 15.8, 21.0], ["g7_podium_est", 36.4, 26.0],
					["g8_commandant", 26.0, 23.4]]:
				outg.append(_warp(c[1], c[2], 0.0))
				outg.append({"do": "wait", "t": 1.5})
				outg.append({"do": "snap", "id": c[0]})
			return outg
		"p6_porte_vestiaires":
			return [_warp(26.0, 48.6, 0.0), {"do": "wait", "t": 1.5}, {"do": "snap", "id": "porte"}]
		"p6_defauts_631":
			# P6.3.1 — positions exactes des anomalies relevées sur la vidéo P6.3 (captures annotées du créateur)
			var outd: Array = []
			for c in [["d1_vestiaires_passage", 26.0, 47.0], ["d1b_passage_seuil", 26.0, 45.4], ["d2_tunnel_sud_milieu", 26.0, 34.4],
					["d3_gradins_courbes", 26.0, 28.4], ["d4_tunnel_est_depuis_arene", 36.4, 23.6], ["d4b_tunnel_est_interieur", 41.4, 23.0],
					["d5_coursive_raccord", 44.9, 23.4], ["d6_infirmerie", 46.6, 36.0], ["d6b_infirmerie_porte", 46.6, 34.6]]:
				outd.append(_warp(c[1], c[2], 0.0))
				outd.append({"do": "wait", "t": 1.6})
				outd.append({"do": "snap", "id": c[0]})
			return outd
		"p6_infirmerie_diag":
			return [_warp(46.6, 36.0, 0.0), {"do": "wait", "t": 1.6}, {"do": "snap", "id": "inf"}]
		"p6_video_631":
			# P6.3.1 — contrôle en mouvement : vestiaires -> salle -> tunnel sud -> arène -> tunnel est -> coursive ->
			# infirmerie -> coursive, allers-retours aux seuils, passages près des murs
			return [
				_warp(26.0, 51.5, 0.0),
				{"do": "wait", "t": 1.0},
				_go(24.0, 49.7, "vestiaires : vers le nord", 0.3),
				_go(17.6, 49.7, "vestiaires : coin nord-ouest (près du mur)", 0.3),
				_go(26.0, 47.2, "vers la porte nord", 0.25),
				_go(26.0, 45.6, "passage", 0.2),
				_go(26.0, 47.0, "retour au seuil des vestiaires", 0.2),
				_go(26.0, 43.6, "salle d'attente", 0.2),
				_go(21.2, 41.0, "salle : près du mur ouest", 0.3),
				_go(26.0, 38.6, "vers le tunnel", 0.25),
				_go(26.0, 34.5, "tunnel sud : milieu", 0.2),
				_go(26.0, 36.8, "retour vers l'entrée du tunnel", 0.2),
				_go(26.0, 30.2, "débouché dans l'arène", 0.2),
				_go(26.0, 33.0, "de nouveau dans le tunnel", 0.2),
				_go(26.0, 26.0, "arène", 0.25),
				_go(34.0, 25.5, "arène : vers le tunnel est (gradins sud-est)", 0.3),
				_go(36.6, 23.0, "arène : axe du tunnel est", 0.3),
				_go(41.2, 23.0, "tunnel est : milieu", 0.25),
				_go(37.0, 23.0, "retour dans l'arène", 0.25),
				_go(44.8, 23.0, "coursive : seuil", 0.25),
				_go(44.8, 30.0, "coursive : le long du mur ouest", 0.3),
				_go(46.6, 33.6, "porte de l'infirmerie", 0.25),
				_go(46.6, 37.0, "infirmerie", 0.25),
				_go(47.2, 40.4, "infirmerie : fond (près du mur)", 0.3),
				_go(46.6, 34.6, "infirmerie : porte", 0.25),
				_go(46.6, 33.0, "coursive", 0.25),
				_go(46.6, 35.2, "de nouveau l'infirmerie", 0.2),
				_go(50.0, 28.0, "coursive", 0.3),
				_go(55.0, 31.0, "coursive : coin sud-est (près de la réserve)", 0.3),
				{"do": "wait", "t": 1.0},
			]
		"p6_arriere_gradins":
			# P6.3.2 — recherche de l'ouverture entre le dos des gradins et le mur extérieur, vue depuis l'arène
			var outa: Array = []
			for c in [["a1_arene_est", 34.0, 22.0], ["a2_arene_nord_est", 32.0, 17.0], ["a3_arene_nord", 26.0, 16.5],
					["a4_arene_nord_ouest", 19.0, 17.0], ["a5_arene_ouest", 16.5, 23.0], ["a6_arene_sud_est", 33.0, 28.0],
					["a7_arene_sud_ouest", 19.0, 28.0], ["a8_centre", 26.0, 23.0]]:
				outa.append(_warp(c[1], c[2], 0.0))
				outa.append({"do": "wait", "t": 1.5})
				outa.append({"do": "snap", "id": c[0]})
			return outa
		"p6_porte_reserve":
			# P6.3.2 — porte de la réserve : depuis l'infirmerie puis depuis la coursive (même porte)
			var outr: Array = []
			for c in [["r1_infirmerie", 46.6, 37.0], ["r2_infirmerie_porte", 47.0, 34.6], ["r3_coursive_loin", 52.0, 28.0],
					["r4_coursive_devant", 53.0, 32.6], ["r5_coursive_ouest", 47.5, 31.0], ["r6_salle_portes_service", 26.0, 41.0],
					["r7_tunnel_vers_salle", 26.0, 36.5]]:
				outr.append(_warp(c[1], c[2], 0.0))
				outr.append({"do": "wait", "t": 1.6})
				outr.append({"do": "snap", "id": c[0]})
			return outr
		"p6_pilote_64":
			# P6.4 — pilote de direction artistique : gradins et galerie, mur des vestiaires et sa porte, coursive
			var outp: Array = []
			for c in [["z1_gradins_sud_ouest", 19.0, 28.0], ["z1b_arene_ouest", 16.5, 23.0], ["z1c_arene_sud_est", 33.0, 28.0],
					["z1d_arene_nord_ouest", 19.0, 17.0], ["z2_vestiaires_mur_nord", 22.0, 50.6], ["z2b_vestiaires_porte", 26.0, 49.4],
					["z3_coursive_nord", 48.0, 15.0], ["z3b_coursive_ouest", 45.6, 21.0], ["z3c_coursive_centre", 50.0, 26.0]]:
				outp.append(_warp(c[1], c[2], 0.0))
				outp.append({"do": "wait", "t": 1.6})
				outp.append({"do": "snap", "id": c[0]})
			return outp
		"p6_video_64":
			# P6.4 — Aren en mouvement près des éléments du pilote (vitesse réelle)
			return [
				_warp(17.5, 50.4, 0.0), {"do": "wait", "t": 0.8},
				_go(25.0, 49.4, "vestiaires : le long du mur nord", 0.3),
				_go(26.0, 47.0, "porte nord des vestiaires", 0.25),
				_go(26.0, 49.6, "retour dans les vestiaires", 0.25),
				_warp(16.0, 24.0, 0.0), {"do": "wait", "t": 0.6},
				_go(18.6, 28.4, "arène : pied des gradins ouest", 0.3),
				_go(24.0, 30.4, "arène : gradins sud-ouest", 0.3),
				_go(30.0, 28.0, "arène : vers le sud-est", 0.3),
				_warp(45.4, 14.0, 0.0), {"do": "wait", "t": 0.6},
				_go(45.4, 26.0, "coursive : le long du mur ouest", 0.3),
				_go(52.0, 31.0, "coursive : dallage", 0.3),
				_go(53.0, 33.2, "coursive : devant la réserve", 0.25),
				_go(50.0, 20.0, "coursive : vers le nord", 0.3),
				{"do": "wait", "t": 0.5},
			]
		"p6_clignotements":
			# P6.3.2 — diagnostic des clignotements : marche le long des murs (vestiaires, salle, coursive), vitesse réelle
			return [
				_warp(18.0, 49.6, 0.0), {"do": "wait", "t": 0.8},
				_go(34.0, 49.6, "vestiaires : le long des casiers", 0.3),
				_warp(21.0, 43.6, 0.0), {"do": "wait", "t": 0.6},
				_go(21.0, 38.6, "salle : le long du mur ouest", 0.3),
				_go(30.6, 38.6, "salle : le long du mur nord", 0.3),
				_warp(45.4, 14.0, 0.0), {"do": "wait", "t": 0.6},
				_go(45.4, 31.5, "coursive : le long du mur ouest", 0.3),
				{"do": "wait", "t": 0.5},
			]
		"p6_extension_captures":
			# P6.4.2 — avant / après de l'extension, mêmes cadrages pour --p64=2 et --p64=3 (dix zones du Colisée)
			var oute: Array = []
			for c in [["e01_vestiaires", 26.0, 51.5], ["e02_salle_attente", 26.0, 42.6], ["e03_tunnel_sud", 26.0, 35.0],
					["e04_arene_gradins", 26.0, 27.0], ["e05_galerie_sud_ouest", 19.0, 28.0], ["e05b_galerie_sud_est", 33.0, 28.0],
					["e05c_arene_nord", 26.0, 17.0], ["e06_tunnel_est", 41.2, 23.0], ["e07_coursive", 49.5, 24.5],
					["e08_infirmerie", 46.6, 37.6], ["e09_reserve_coursive", 53.0, 32.6], ["e09b_reserve_infirmerie", 47.2, 34.8],
					["e10_sortie_est", 61.5, 23.0]]:
				oute.append(_warp(c[1], c[2], 0.0))
				oute.append({"do": "wait", "t": 1.6})
				oute.append({"do": "snap", "id": c[0]})
			return oute
		"p6_643_inspection":
			# P6.4.3 — points de contrôle des P0 : tunnel sud, bouche du tunnel est (gradins, escaliers), coursive
			var outi: Array = []
			for c in [["i1_tunnel_milieu", 26.0, 34.4], ["i2_tunnel_fin", 26.0, 32.7], ["i3_arene_vers_est", 35.0, 23.0],
					["i4_bouche_est", 37.4, 23.0], ["i5_tunnel_est", 40.0, 23.0], ["i6_coursive_seuil", 44.8, 23.0],
					["i7_coursive_sud", 47.0, 31.0], ["i8_infirmerie", 46.6, 37.0]]:
				outi.append(_warp(c[1], c[2], 0.0))
				outi.append({"do": "wait", "t": 1.6})
				outi.append({"do": "snap", "id": c[0]})
			return outi
		"p6_643_captures":
			# P6.4.3 — captures artistiques (après le tutoriel, sans débogage) : arène générale ×2 et ×3, entrée principale,
			# raccords gradins / coursive, salle d'attente, infirmerie
			var outa: Array = [{"do": "zoom", "i": 2, "smooth": false}]
			for c in [["a1_arene_x3", 26.0, 27.0, 2], ["a2_arene_x2", 26.0, 27.0, 0], ["a3_entree_x3", 26.0, 31.0, 2],
					["a4_entree_x2", 26.0, 31.0, 0], ["a5_raccords_x3", 36.4, 23.0, 2], ["a6_raccords_x2", 36.4, 23.0, 0],
					["a7_salle_x3", 26.0, 42.6, 2], ["a8_infirmerie_x3", 46.6, 37.6, 2], ["a9_coursive_x2", 49.5, 24.5, 0]]:
				outa.append({"do": "zoom", "i": c[3], "smooth": false})
				outa.append(_warp(c[1], c[2], 0.0))
				outa.append({"do": "wait", "t": 1.6})
				outa.append({"do": "snap", "id": c[0]})
			return outa
		"p6_643_ombres":
			return [_warp(26.0, 27.0, 0.0), {"do": "wait", "t": 1.6}, {"do": "snap", "id": "o1_arene"},
				_warp(46.6, 37.6, 0.0), {"do": "wait", "t": 1.6}, {"do": "snap", "id": "o2_infirmerie"}]
		"p6_extension_coursive":
			# P6.4.2 — cadrages de la coursive seuls (reprise après réglage des piliers)
			var outk: Array = []
			for c in [["e07_coursive", 49.5, 24.5], ["e09_reserve_coursive", 53.0, 32.6], ["e10_sortie_est", 61.5, 23.0], ["e06_tunnel_est", 41.2, 23.0]]:
				outk.append(_warp(c[1], c[2], 0.0))
				outk.append({"do": "wait", "t": 1.6})
				outk.append({"do": "snap", "id": c[0]})
			return outk
		"p6_captures":
			return [
				{"do": "wait", "t": 1.5},
				{"do": "snap", "id": "vestiaires"},
				_warp(26.0, 41.5, 0.0),
				{"do": "wait", "t": 1.5},
				{"do": "snap", "id": "salle_attente"},
				_warp(26.0, 27.5, 0.0),
				{"do": "wait", "t": 1.5},
				{"do": "snap", "id": "arene"},
				{"do": "zoom", "i": 0, "smooth": false},
				{"do": "wait", "t": 1.2},
				{"do": "snap", "id": "arene_x2"},
				{"do": "zoom", "i": 1, "smooth": false},
				_warp(49.5, 24.5, 0.0),
				{"do": "wait", "t": 1.5},
				{"do": "snap", "id": "coursive"},
				_warp(46.5, 37.8, 0.0),
				{"do": "wait", "t": 1.5},
				{"do": "snap", "id": "infirmerie"},
				_warp(61.5, 23.0, 0.0),
				{"do": "wait", "t": 1.5},
				{"do": "snap", "id": "sortie_est"},
			]
		"p4":
			# P4 — parcours complet de l'avant-poste : cour → garde (dialogue) → escalier → terrasse → bâtiment (entrée,
			# examen, sortie) → descente → porte fortifiée → pont → plaine → abords du Vorgane (le combat se déclenche
			# au contact : la boucle complète est vérifiée par tests/e2e_p4_retour.gd).
			return [
				{"do": "wait", "t": 0.6},
				_go(13.0, 15.0, "cour (centre)"),
				_go(17.3, 14.6, "B garde", 0.3),
				{"do": "talk", "id": "garde"},
				{"do": "wheel", "n": 1},                     # doit être IGNORÉE : dialogue ouvert
				{"do": "wait", "t": 9.0},                    # le dialogue à portraits avance seul pendant le parcours
				_go(12.0, 12.5, "C pied de l'escalier", 0.25),
				_go(12.0, 10.5, "escalier (mi-hauteur)", 0.25),
				{"do": "wheel", "n": 1},                     # ×3 en pleine montée
				_go(12.0, 8.55, "D haut de l'escalier", 0.25),
				_go(6.0, 8.2, "terrasse ouest"),
				_go(6.0, 5.0, "terrasse (côté du bâtiment)"),
				_go(6.0, 8.2, "terrasse ouest (retour)"),
				_go(12.0, 8.0, "devant la porte", 0.25),
				{"do": "go", "to": Vector2(12.0, 7.25), "tol": 0.2, "id": "E porte du poste", "exit": true},
				{"do": "wait", "t": 0.8},
				{"do": "wheel", "n": -1},
				_go(5.0, 4.75, "intérieur : table", 0.3),
				{"do": "talk", "id": "carte"},
				{"do": "next"},
				_go(7.6, 5.6, "intérieur : âtre", 0.3),
				_go(5.0, 5.6, "intérieur : devant la porte", 0.25),
				{"do": "go", "to": Vector2(5.0, 6.8), "tol": 0.2, "id": "intérieur : sortie", "exit": true},
				{"do": "wait", "t": 0.8},
				_go(12.0, 8.6, "retour sur la terrasse", 0.3),
				_go(12.0, 12.5, "descente de l'escalier", 0.25),
				_go(17.5, 16.0, "cour (vers la porte)"),
				_go(20.4, 16.0, "F porte fortifiée", 0.3),
				_go(22.0, 16.0, "rive ouest"),
				{"do": "wheel", "n": -1},                    # ×2 sur le pont
				_go(26.0, 16.0, "G milieu du pont", 0.3),
				_go(30.5, 16.0, "plaine (sortie du pont)"),
				{"do": "wheel", "n": 1},
				_go(31.3, 14.7, "panneau de la plaine", 0.2),
				{"do": "talk", "id": "panneau"},
				{"do": "next"},
				_go(34.4, 12.6, "sous l'arbre pilote (devant)"),
				_go(35.2, 11.0, "contour de l'arbre pilote (est)", 0.3),
				_go(34.6, 9.2, "derrière l'arbre pilote", 0.3),
				_go(32.4, 9.6, "derrière l'arbre pilote (ouest)", 0.3),
				_go(34.0, 16.0, "H chemin de la plaine"),
				_go(40.4, 20.6, "plaine sud"),
				_go(37.0, 16.0, "abords du Vorgane", 0.3),
				{"do": "wait", "t": 0.5},
			]
		"p4_demo":
			# P4 — démonstration filmée (avec --autoplay : le combat se joue seul, puis « p4_retour ») ; même trajet que « p4 » : cour → garde (dialogue) → escalier → terrasse → bâtiment (entrée,
			# examen, sortie) → descente → porte fortifiée → pont → plaine → abords du Vorgane (le combat se déclenche
			# au contact : la boucle complète est vérifiée par tests/e2e_p4_retour.gd).
			return [
				{"do": "wait", "t": 0.6},
				_go(13.0, 15.0, "cour (centre)"),
				_go(17.3, 14.6, "B garde", 0.3),
				{"do": "talk", "id": "garde"},
				{"do": "wheel", "n": 1},                     # doit être IGNORÉE : dialogue ouvert
				{"do": "wait", "t": 9.0},                    # le dialogue à portraits avance seul pendant le parcours
				_go(12.0, 12.5, "C pied de l'escalier", 0.25),
				_go(12.0, 10.5, "escalier (mi-hauteur)", 0.25),
				{"do": "wheel", "n": 1},                     # ×3 en pleine montée
				_go(12.0, 8.55, "D haut de l'escalier", 0.25),
				_go(6.0, 8.2, "terrasse ouest"),
				_go(6.0, 5.0, "terrasse (côté du bâtiment)"),
				_go(6.0, 8.2, "terrasse ouest (retour)"),
				_go(12.0, 8.0, "devant la porte", 0.25),
				{"do": "go", "to": Vector2(12.0, 7.25), "tol": 0.2, "id": "E porte du poste", "exit": true},
				{"do": "wait", "t": 0.8},
				{"do": "wheel", "n": -1},
				_go(5.0, 4.75, "intérieur : table", 0.3),
				{"do": "talk", "id": "carte"},
				{"do": "next"},
				_go(7.6, 5.6, "intérieur : âtre", 0.3),
				_go(5.0, 5.6, "intérieur : devant la porte", 0.25),
				{"do": "go", "to": Vector2(5.0, 6.8), "tol": 0.2, "id": "intérieur : sortie", "exit": true},
				{"do": "wait", "t": 0.8},
				_go(12.0, 8.6, "retour sur la terrasse", 0.3),
				_go(12.0, 12.5, "descente de l'escalier", 0.25),
				_go(17.5, 16.0, "cour (vers la porte)"),
				_go(20.4, 16.0, "F porte fortifiée", 0.3),
				_go(22.0, 16.0, "rive ouest"),
				{"do": "wheel", "n": -1},                    # ×2 sur le pont
				_go(26.0, 16.0, "G milieu du pont", 0.3),
				_go(30.5, 16.0, "plaine (sortie du pont)"),
				{"do": "wheel", "n": 1},
				_go(31.3, 14.7, "panneau de la plaine", 0.2),
				{"do": "talk", "id": "panneau"},
				{"do": "next"},
				_go(34.4, 12.6, "sous l'arbre pilote (devant)"),
				_go(35.2, 11.0, "contour de l'arbre pilote (est)", 0.3),
				_go(34.6, 9.2, "derrière l'arbre pilote", 0.3),
				_go(32.4, 9.6, "derrière l'arbre pilote (ouest)", 0.3),
				_go(34.0, 16.0, "H chemin de la plaine"),
				_go(40.4, 20.6, "plaine sud"),
				_go(37.0, 16.0, "abords du Vorgane", 0.3),
				{"do": "wait", "t": 0.5},
				_go(38.3, 14.8, "contact du Vorgane", 0.2),
				{"do": "wait", "t": 4.0},
			]
		"p4_retour":
			# après le combat : retour vers le pont
			return [
				{"do": "wait", "t": 2.5},
				_go(33.0, 16.0, "retour : chemin de la plaine"),
				_go(27.0, 16.0, "retour : pont"),
				{"do": "wait", "t": 1.5},
			]
		"p4_anim":
			# P4.5 — démonstration des animations (vidéo) : marche puis attente dans les 4 directions à ×3, près du
			# garde qui fait sa ronde (à plus de 4 m : il ne revient pas à son poste).
			var dirs := [[Vector2(1, 0), "droite"], [Vector2(-1, 0), "gauche"], [Vector2(0, -1), "haut"], [Vector2(0, 1), "bas"]]
			var oa: Array = [_warp(12.6, 16.6, 0.0), {"do": "zoom", "i": 2, "smooth": false}, {"do": "wait", "t": 2.5}]
			for dd in dirs:
				oa.append({"do": "push", "id": "marche " + dd[1], "dir": dd[0], "t": 1.4, "expect": {}})
				oa.append({"do": "wait", "t": 2.4})
			oa.append({"do": "zoom", "i": 1, "smooth": false})
			oa.append({"do": "wait", "t": 1.0})
			return oa
		"p4_marche":
			# P4.8 — vidéo de la marche : à ×3 dans la cour, marche dans les 4 directions avec arrêts, puis course (Maj).
			var om: Array = [_warp(12.6, 16.6, 0.0), {"do": "zoom", "i": 2, "smooth": false}, {"do": "wait", "t": 1.5}]
			for dd in [[Vector2(1, 0), "droite"], [Vector2(-1, 0), "gauche"], [Vector2(0, -1), "haut"], [Vector2(0, 1), "bas"]]:
				om.append({"do": "push", "id": "marche " + dd[1], "dir": dd[0], "t": 2.2, "expect": {}})
				om.append({"do": "wait", "t": 1.2})
			om.append({"do": "push", "id": "course droite", "dir": Vector2(1, 0), "t": 1.4, "expect": {}, "run": true})
			om.append({"do": "wait", "t": 1.0})
			om.append({"do": "push", "id": "course gauche", "dir": Vector2(-1, 0), "t": 1.4, "expect": {}, "run": true})
			om.append({"do": "wait", "t": 1.2})
			return om
		"p4_vorgane":
			# P4.7 — le Vorgane dans la plaine : captures aux 3 zooms, puis le héros tourne autour (vidéo).
			var ov: Array = [_warp(35.6, 15.2, 0.0)]
			for zi in 3:
				ov.append({"do": "zoom", "i": zi, "smooth": false})
				ov.append({"do": "wait", "t": 1.0})
				ov.append({"do": "snap", "id": "vorgane_x%s" % ["2", "2-5", "3"][zi]})
			ov.append({"do": "zoom", "i": 1, "smooth": false})
			ov.append({"do": "push", "id": "vers le nord", "dir": Vector2(0.3, -1), "t": 1.6, "expect": {}})
			ov.append({"do": "push", "id": "vers l'est", "dir": Vector2(1, 0), "t": 1.2, "expect": {}})
			ov.append({"do": "wait", "t": 1.5})
			ov.append({"do": "snap", "id": "vorgane_nord"})
			return ov
		"p4_garde":
			# P4.5 — vidéo du garde : ronde en 4 directions et attente (héros à 4,7 m), puis le héros approche : le
			# garde regagne son poste et se tourne vers lui ; dialogue.
			return [_warp(14.0, 15.5, 0.0), {"do": "zoom", "i": 2, "smooth": false}, {"do": "wait", "t": 13.0},
				_go(16.6, 14.6, "approche du garde", 0.3), {"do": "wait", "t": 1.5}, {"do": "talk", "id": "garde"}, {"do": "wait", "t": 4.0}]
		"p4_vues_int":
			var o2: Array = []
			for c in [["interieur", 5.0, 4.9, 0.0], ["interieur_atre", 7.6, 5.4, 0.0]]:
				o2.append(_warp(c[1], c[2], c[3]))
				for zi in 3:
					o2.append({"do": "zoom", "i": zi, "smooth": false})
					o2.append({"do": "wait", "t": 1.0})
					o2.append({"do": "snap", "id": "%s_x%s" % [c[0], ["2", "2-5", "3"][zi]]})
			return o2
		"p4_sondes":
			# P4 — essais ciblés de collision (poussée au clavier) : aucune limite visible ne doit être franchie.
			return [
				_warp(8.0, 8.4, 1.2), _push("muret avant de la terrasse (vers le bas)", Vector2(0, 1), 1.2, {"h": 1.2, "max_y": 9.0}),
				_warp(5.0, 6.0, 1.2), _push("muraille ouest depuis la terrasse", Vector2(-1, 0), 1.2, {"h": 1.2, "min_x": 4.0}),
				_warp(7.0, 9.8, 0), _push("façade de la terrasse depuis la cour", Vector2(0, -1), 1.2, {"h": 0.0, "min_y": 9.0}),
				_warp(10.2, 10.4, 0), _push("côté de l'escalier depuis la cour", Vector2(1, 0), 1.0, {"max_h": 0.3, "max_x": 10.8}),
				_warp(12.0, 10.5, 0.6), _push("limon de l'escalier depuis les marches", Vector2(-1, 0), 1.0, {"min_h": 0.3, "min_x": 10.8}),
				_warp(9.6, 8.0, 1.2), _push("mur du bâtiment (hors porte)", Vector2(0, -1), 0.5, {"h": 1.2, "min_y": 7.0}),
				_warp(7.6, 5.4, 1.2), _push("pignon ouest du bâtiment", Vector2(1, 0), 1.0, {"h": 1.2, "max_x": 8.5}),
				_warp(18.5, 11.5, 0), _push("muraille est (hors porte)", Vector2(1, 0), 1.2, {"h": 0.0, "max_x": 20.0}),
				_warp(18.9, 14.0, 0), _push("tour nord de la porte", Vector2(1, 0), 0.4, {"h": 0.0, "max_x": 19.7}),
				_warp(12.0, 21.0, 0), _push("parapet sud de la cour", Vector2(0, 1), 1.2, {"h": 0.0, "max_y": 22.0}),
				_warp(5.0, 17.0, 0), _push("muraille ouest de la cour", Vector2(-1, 0), 1.2, {"h": 0.0, "min_x": 4.0}),
				_warp(22.0, 12.0, 0), _push("berge ouest / rivière", Vector2(1, 0), 1.2, {"h": 0.0, "max_x": 23.0}),
				_warp(26.0, 16.0, 0), _push("garde-corps sud du pont", Vector2(0, 1), 1.2, {"h": 0.0, "max_y": 17.25}),
				_warp(26.0, 16.0, 0), _push("garde-corps nord du pont", Vector2(0, -1), 1.2, {"h": 0.0, "min_y": 14.75}),
				_warp(30.0, 20.0, 0), _push("berge est / rivière", Vector2(-1, 0), 1.2, {"h": 0.0, "min_x": 29.0}),
				_warp(35.0, 7.0, 0), _push("plateau rocheux au nord de la plaine", Vector2(0, -1), 1.2, {"h": 0.0, "min_y": 6.0}),
				_warp(34.6, 11.4, 0), _push("tronc de l'arbre pilote", Vector2(-1, -0.8), 1.0, {"h": 0.0, "clear": [33.6, 10.6, 0.93]}),
				_warp(40.0, 22.0, 0), _push("haie sud de la plaine", Vector2(0, 1), 1.2, {"h": 0.0, "max_y": 23.0}),
				_warp(45.0, 12.0, 0), _push("haie est de la plaine", Vector2(1, 0), 1.2, {"h": 0.0, "max_x": 46.0}),
				_warp(15.2, 11.0, 0), _push("tonneaux au pied de la terrasse", Vector2(0, -1), 0.35, {"h": 0.0, "min_y": 10.3}),
			]
		"p4_vues":
			# P4 — captures comparatives : 6 points de vue × 3 zooms.
			var out: Array = []
			for c in [["cour", 10.0, 16.0, 0.0], ["escalier", 12.0, 10.6, 0.56], ["terrasse", 12.0, 8.4, 1.2], ["porte_pont", 21.6, 16.0, 0.0],
				["pont", 26.0, 16.0, 0.0], ["plaine", 35.5, 14.5, 0.0], ["derriere_arbre", 33.9, 9.3, 0.0], ["derriere_tour", 21.6, 17.6, 0.0]]:
				out.append(_warp(c[1], c[2], c[3]))
				for zi in 3:
					out.append({"do": "zoom", "i": zi, "smooth": false})
					out.append({"do": "wait", "t": 1.0})
					out.append({"do": "snap", "id": "%s_x%s" % [c[0], ["2", "2-5", "3"][zi]]})
			out.append({"do": "zoom", "i": 1, "smooth": false})
			return out
		"temoin":
			# parcours complet (doc 05 §07) : entrée → place → escalier → PNJ → descente → détour arbre → pont → sortie
			# → instance fictive → retour ; zoom changé dans l'escalier, sur la terrasse (dialogue ouvert) et sur le pont.
			return [
				{"do": "wait", "t": 0.5},
				_go(13, 14, "B place"),
				_go(14, 11.25, "C pied escalier", 0.25),
				_go(14, 9.7, "escalier mi-hauteur", 0.25),
				{"do": "wheel", "n": 1},                     # ×3 en pleine montée
				_go(14, 7.6, "D haut escalier", 0.25),
				_go(11.9, 5.6, "E PNJ", 0.3),
				{"do": "talk", "id": "PNJ"},
				{"do": "wheel", "n": -1},                    # doit être IGNORÉE : dialogue ouvert
				{"do": "next"}, {"do": "next"}, {"do": "next"},
				_go(15.2, 4.6, "ouest maison"),
				_go(15.4, 2.5, "derrière maison (entrée)", 0.3),
				_go(19.6, 2.5, "derrière maison (sortie)", 0.3),
				_go(15.4, 2.5, "derrière maison (retour)", 0.3),
				_go(14.6, 6.0, "terrasse"),
				_go(14, 7.7, "D retour", 0.25),
				_go(14, 11.3, "C descente", 0.25),
				{"do": "wheel", "n": -1},                    # ×2,5
				_go(13, 14, "B retour"),
				_go(9.4, 16.0, "détour 1"),
				_go(8.6, 18.9, "détour sud de l'arbre"),
				_go(5.5, 18.4, "détour ouest de l'arbre"),
				_go(5.4, 16.0, "détour nord-ouest"),
				_go(6.6, 15.3, "derrière l'arbre (borne)", 0.25),
				{"do": "talk", "id": "borne"}, {"do": "next"},
				_go(9.6, 13.75, "retour place"),
				_go(20.0, 13.75, "tête de pont"),
				_go(23.5, 13.75, "F pont"),
				{"do": "wheel", "n": -1},                    # ×2 sur le pont
				_go(28.5, 13.75, "rive est"),
				{"do": "go", "to": Vector2(30.8, 13.75), "tol": 0.3, "id": "G sortie", "exit": true},
				{"do": "wait", "t": 1.0},
				_go(6.0, 3.8, "instance 2 : panneau", 0.2),
				{"do": "talk", "id": "panneau"}, {"do": "next"},
				{"do": "go", "to": Vector2(1.0, 4.5), "tol": 0.2, "id": "instance 2 : porte de retour", "exit": true},
				{"do": "wait", "t": 1.0},
				_go(27.0, 13.75, "retour scène témoin"),
				{"do": "wheel", "n": 1},                     # ×2,5
				{"do": "wait", "t": 0.8},
			]
		"video":
			# P3-07 : marche continue pour les vidéos A/B/C (arbre, escalier, terrasse, derrière la maison, pont, sortie,
			# arrivée dans l'instance fictive), zooms ×3, ×2 et ×2,5 visibles
			return [
				{"do": "wait", "t": 0.6},
				_go(13, 14, "B place"),
				_go(9.4, 16.6, "près de l'arbre"),
				_go(14, 11.25, "pied de l'escalier", 0.25),
				{"do": "wheel", "n": 1},
				_go(14, 7.6, "haut de l'escalier", 0.25),
				_go(15.4, 4.6, "ouest de la maison"),
				_go(15.4, 2.5, "derrière la maison (entrée)", 0.3),
				_go(19.6, 2.5, "derrière la maison (sortie)", 0.3),
				{"do": "wheel", "n": -1}, {"do": "wait", "t": 0.4}, {"do": "wheel", "n": -1},
				_go(15.4, 2.5, "derrière la maison (retour)", 0.3),
				_go(14.6, 6.0, "terrasse"),
				_go(14, 7.7, "haut de l'escalier (retour)", 0.25),
				_go(14, 11.3, "pied de l'escalier (retour)", 0.25),
				{"do": "wheel", "n": 1},
				_go(20.0, 13.75, "entrée du pont"),
				_go(28.5, 13.75, "rive est"),
				{"do": "go", "to": Vector2(30.8, 13.75), "tol": 0.3, "id": "sortie", "exit": true},
				{"do": "wait", "t": 1.0},
				_go(6.0, 4.4, "instance fictive"),
				{"do": "wait", "t": 0.8},
			]
		"validation":
			# Validation caméra (doc 12 §04, doc 07 §05) : marche au clavier simulé, à lancer une fois par zoom
			# (--zoom=0|1|2). Huit directions avec demi-tours, escalier (montée ET descente), tour de la maison,
			# tour de l'arbre, pont dans les deux sens, sortie, quatre coins de la petite instance, retour.
			# Le couloir de 0,5 m entre la maison et le rebord n'y figure pas : il est infranchissable (voir « sondes »).
			var out: Array = [{"do": "wait", "t": 0.5}, _go(11.5, 15.5, "place (départ des 8 directions)")]
			for d in [Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1)]:
				out.append(_push("8dir aller %s" % str(d), d, 0.9, {}))
				out.append(_push("8dir retour %s" % str(d), -d, 0.9, {}))
			out.append_array([
				{"do": "mark", "id": "escalier"},
				_go(14, 11.25, "pied de l'escalier", 0.25),
				_go(14, 7.6, "haut de l'escalier", 0.25),
				_go(14, 11.3, "descente de l'escalier", 0.25),
				_go(14, 7.6, "remontée de l'escalier", 0.25),
				{"do": "mark", "id": "maison"},
				_go(11.9, 5.6, "PNJ", 0.3),
				{"do": "talk", "id": "PNJ"}, {"do": "next"}, {"do": "next"}, {"do": "next"},
				_go(15.2, 4.6, "ouest de la maison"),
				_go(15.4, 2.5, "derrière la maison (entrée)", 0.3),
				_go(19.6, 2.5, "derrière la maison (sortie)", 0.3),
				_go(15.4, 2.5, "derrière la maison (retour)", 0.3),
				_go(15.2, 4.6, "ouest de la maison (retour)"),
				_go(14, 7.7, "haut de l'escalier (retour)", 0.25),
				_go(14, 11.3, "pied de l'escalier (retour)", 0.25),
				{"do": "mark", "id": "arbre"},
				_go(9.4, 16.0, "arbre : est"),
				_go(8.6, 18.9, "arbre : sud"),
				_go(5.5, 18.4, "arbre : ouest"),
				_go(5.4, 16.0, "arbre : nord-ouest"),
				_go(6.6, 15.3, "derrière l'arbre", 0.25),
				_go(8.4, 15.6, "arbre : nord-est"),
				{"do": "mark", "id": "pont"},
				_go(9.6, 13.75, "retour place"),
				_go(20.0, 13.75, "tête de pont"),
				_go(28.5, 13.75, "rive est"),
				_go(20.0, 13.75, "pont, retour vers l'ouest"),
				_go(28.5, 13.75, "rive est (2)"),
				{"do": "mark", "id": "instance"},
				{"do": "go", "to": Vector2(30.8, 13.75), "tol": 0.3, "id": "sortie est", "exit": true},
				{"do": "wait", "t": 1.0},
				_go(10.3, 7.3, "instance : coin sud-est", 0.3),
				_go(10.3, 1.9, "instance : coin nord-est", 0.3),
				_go(1.9, 1.9, "instance : coin nord-ouest", 0.3),
				_go(1.9, 7.3, "instance : coin sud-ouest", 0.3),
				_go(6.0, 4.5, "instance : centre", 0.3),
				{"do": "go", "to": Vector2(1.0, 4.5), "tol": 0.2, "id": "instance : porte de retour", "exit": true},
				{"do": "wait", "t": 1.0},
				{"do": "mark", "id": "retour"},
				_go(27.0, 13.75, "retour scène témoin"),
				{"do": "wait", "t": 0.8},
			])
			return out
		"micro":
			# micro-test commun A/B : deux surfaces, un escalier, un occultant (doc 05 §06)
			return [
				{"do": "wait", "t": 0.5},
				_go(13, 14, "B place"),
				_go(14, 11.25, "C pied escalier", 0.25),
				_go(14, 9.7, "escalier mi-hauteur", 0.25),
				{"do": "wheel", "n": 1},
				_go(14, 7.6, "D haut escalier", 0.25),
				_go(11.0, 4.0, "terrasse ouest"),
				_go(19.5, 4.0, "terrasse est"),
				_go(14, 7.7, "D retour", 0.25),
				_go(14, 9.5, "escalier demi-tour (descente)", 0.25),
				_go(14, 8.6, "escalier demi-tour (remontée)", 0.25),
				_go(14, 11.3, "C descente", 0.25),
				{"do": "wheel", "n": -1},
				_go(9.4, 16.0, "détour 1"),
				_go(8.6, 18.9, "sud de l'arbre"),
				_go(5.5, 18.4, "ouest de l'arbre"),
				_go(5.4, 16.0, "nord-ouest"),
				_go(6.6, 15.3, "derrière l'arbre", 0.25),
				{"do": "wait", "t": 0.6},
				_go(9.6, 13.75, "retour place"),
				{"do": "wheel", "n": -1},
				_go(19.5, 13.75, "place est"),
				{"do": "wait", "t": 0.6},
			]
		"sondes":
			# essais ciblés de collision (poussée au clavier, donc avec glissement) : le héros ne doit franchir AUCUNE
			# limite visible — même niveau, jamais dans l'eau ni dans un solide (les sauts d'altitude et les positions
			# hors du modèle sont en outre comptés à chaque image sur tout le parcours)
			return [
				_warp(11, 7.4, 1.2), _push("rebord avant de la terrasse (vers le bas)", Vector2(0, 1), 1.2, {"h": 1.2}),
				_warp(9.8, 5, 1.2), _push("rebord ouest de la terrasse", Vector2(-1, 0), 1.2, {"h": 1.2, "min_x": 9.0}),
				_warp(11, 9.6, 0), _push("façade de la terrasse depuis le bas", Vector2(0, -1), 1.2, {"h": 0.0, "min_y": 8.0}),
				_warp(12.2, 9.4, 0), _push("côté de l'escalier depuis le sol", Vector2(1, 0), 1.0, {"max_h": 0.3}),
				_warp(14, 9.3, 0.7), _push("côté de l'escalier depuis les marches", Vector2(-1, 0), 1.0, {"min_h": 0.45}),
				_warp(15.5, 7.75, 1.2), _push("passage de 0,5 m entre maison et rebord", Vector2(1, 0), 1.2, {"h": 1.2, "max_x": 16.0}),
				_warp(20.3, 18, 0), _push("berge ouest / rivière", Vector2(1, 0), 1.2, {"h": 0.0, "dry": true}),
				_warp(23.5, 13.75, 0), _push("garde-corps avant du pont", Vector2(0, 1), 1.2, {"h": 0.0, "max_y": 15.0}),
				_warp(23.5, 13.75, 0), _push("garde-corps arrière du pont", Vector2(0, -1), 1.2, {"h": 0.0, "min_y": 12.5}),
				_warp(26.6, 16.0, 0), _push("berge est / rivière", Vector2(-1, 0), 1.2, {"h": 0.0, "dry": true}),
				_warp(7.0, 18.2, 0), _push("tronc de l'arbre", Vector2(0, -1), 1.0, {"h": 0.0, "clear": [7.0, 17.0, 0.9]}),
				_warp(29.5, 18.6, 0), _push("haie sud de la rive est", Vector2(0, 1), 1.0, {"max_y": 20.0}),
				_warp(2.0, 14.0, 0), _push("entrée ouest (limite)", Vector2(-1, 0), 1.0, {"min_x": 1.0}),
				_warp(14, 9.0, 0.9), _push("escalier : demi-tour (montée)", Vector2(0, -1), 0.4, {"min_h": 0.5}),
				_push("escalier : demi-tour (descente)", Vector2(0, 1), 0.4, {"max_h": 1.2}),
			]
		"limites":
			var out: Array = []
			for c in [["coin sud-ouest", 1.4, 21.6, 0.0], ["coin nord-ouest (bas)", 1.4, 9.4, 0.0],
					["terrasse nord-ouest", 9.5, 2.4, 1.2], ["terrasse nord-est", 20.6, 2.4, 1.2],
					["rive est, sud", 30.6, 19.6, 0.0], ["rive est, nord", 30.6, 10.4, 0.0], ["sortie", 30.2, 13.75, 0.0]]:
				out.append(_warp(c[1], c[2], c[3]))
				for zi in 3:
					out.append({"do": "zoom", "i": zi, "smooth": true})
					out.append({"do": "wait", "t": 1.4})
					out.append({"do": "snap", "id": "limite_%s_z%d" % [c[0], zi]})
			return out
	return []


## Cinq points de vue comparables (doc 05 §07, doc 06 §07) — et un sixième pour l'occultation.
static func capture_points(mode: String) -> Array:
	if mode == "instance":
		return [["i1_arrivee", 1.8, 4.5, 0.0], ["i2_centre", 6.0, 4.5, 0.0], ["i3_coin_nord_est", 10.4, 1.6, 0.0],
			["i4_coin_sud_ouest", 1.6, 7.4, 0.0]]
	if mode == "micro":
		return [["1_entree", 2.6, 14, 0.0], ["2_place", 13, 14, 0.0], ["3_escalier", 14, 9.6, 0.0],
			["4_terrasse", 12.5, 5.6, 1.2], ["5_derriere_arbre", 6.6, 15.3, 0.0]]
	return [["1_entree_A", 2.6, 14, 0.0], ["2_place_B", 13, 14, 0.0], ["3_escalier", 14, 9.6, 0.0],
		["4_PNJ_E", 11.9, 5.6, 1.2], ["5_pont_F", 23.5, 13.75, 0.0], ["6_derriere_arbre", 6.6, 15.3, 0.0],
		["7_derriere_maison", 18.0, 2.5, 1.2], ["8_sortie_G", 29.6, 13.75, 0.0]]


## P3-07 (doc 07 §05) : six points d'observation de la scène témoin, identiques pour A, B et C.
static func obs_points() -> Array:
	return [["1_arbre", 8.6, 18.6, 0.0], ["2_pied_escalier", 14.0, 11.3, 0.0], ["3_haut_escalier", 14.0, 7.6, 1.2],
		["4_derriere_maison", 18.0, 2.5, 1.2], ["5_entree_pont", 20.2, 13.75, 0.0], ["6_sortie", 29.6, 13.75, 0.0]]

