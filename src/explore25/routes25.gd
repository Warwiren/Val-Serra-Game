extends RefCounted
## P3 — Parcours automatiques (clavier simulé, 8 directions) : identiques pour les démonstrations A et B.
## Coordonnées dans le plan du doc 06 (m). « push » : pousse dans une direction ÉCRAN pendant t secondes et vérifie
## la position obtenue (collisions). « warp » : place le héros (essais ciblés, captures).

## P7.4 — repères de points de vue de la ville V0.7-A (identiques en A et en B)
const V07_VUES := [["01_entree", 60.0, 148.0, 0.0], ["02_placette_guilde", 56.0, 138.0, 0.0], ["03_premier_palier", 62.0, 123.5, 1.75],
	["04_arrivee_place", 65.0, 112.0, 3.5], ["05_grande_place", 52.0, 106.0, 3.5], ["06_rue_colisee", 22.0, 100.0, 3.5],
	["07_parvis_colisee", 2.0, 92.0, 3.5], ["08_pied_montee_haute", 63.0, 90.0, 3.5], ["09_deuxieme_palier", 66.0, 79.5, 5.75],
	["10_terrasse_haute", 70.0, 64.0, 8.0], ["11_porte_chateau", 70.0, 44.0, 8.0], ["12_ruelle", 82.0, 130.0, 0.0],
	["13_chantier", 85.0, 140.0, 0.0], ["14_retour_place", 63.0, 98.0, 3.5], ["15_porte_publique_colisee", 30.5, 69.6, 3.5],
	["16_allee_colisee", 26.0, 80.0, 3.5]]


## P7.3 — points de vue de la ville V0.6 (porte sud -> guilde -> montée -> grande place -> quartier haut)
const V06_VUES := [["1_arrivee_sud", 60.0, 163.0, 0.0], ["2_guilde", 70.0, 154.0, 0.0], ["3_auberge", 50.0, 140.0, 0.0],
	["4_pied_montee_1", 60.0, 131.0, 0.0], ["5_milieu_montee_1", 60.0, 123.0, 1.75], ["6_place_sud", 60.0, 114.0, 3.5],
	["7_fontaine", 60.0, 106.0, 3.5], ["8_forge", 72.0, 90.0, 3.5], ["9_rue_colisee", 44.0, 90.0, 3.5],
	["10_pied_montee_2", 60.0, 87.0, 3.5], ["11_milieu_montee_2", 60.0, 78.0, 5.75], ["12_parvis_civique", 60.0, 68.0, 8.0],
	["13_hotel_de_ville", 72.0, 56.0, 8.0], ["14_avenue_chateau", 60.0, 40.0, 8.0], ["15_porte_chateau", 60.0, 28.0, 8.0]]


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
				{"do": "go", "to": Vector2(61.0, 29.4), "tol": 0.25, "id": "porte de la ville", "exit": true},
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
				{"do": "go", "to": Vector2(61.0, 29.4), "tol": 0.25, "id": "porte de la ville", "exit": true},
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
		"p6_741_visite":
			# P7.4.1 — caméra V0.7-A dans le Colisée (après le tutoriel) : vestiaires, passage, salle d'attente, tunnel sud
			# (9 m), arène (profil 20°, allers-retours tunnel / arène, zigzags), gradins, tunnel est, coursive, infirmerie,
			# couloir de sortie. Positions du bloc sud décalées par Routes.sud.
			return [
				_warp(26.0, 51.5, 0.0), {"do": "wait", "t": 1.0},
				_go(22.0, 51.5, "vestiaires : ouest", 0.3), _go(33.5, 52.5, "vestiaires : sud-est", 0.3), _go(26.0, 49.2, "vestiaires : porte nord", 0.3),
				_go(26.0, 45.6, "passage", 0.3), _go(26.0, 41.5, "salle d'attente", 0.3), _go(21.0, 40.0, "salle : ouest", 0.3), _go(26.0, 38.5, "salle : porte du tunnel", 0.3),
				_go(26.0, 34.0, "tunnel sud", 0.3), _go(26.0, 29.0, "débouché dans l'arène", 0.3), _go(26.0, 34.0, "retour dans le tunnel", 0.3),
				_go(26.0, 28.0, "arène", 0.3), _go(18.0, 23.0, "arène : ouest", 0.3), _go(34.0, 23.0, "arène : est (demi-tour)", 0.3),
				_go(19.0, 28.5, "arène : sud-ouest", 0.3), _go(33.0, 28.5, "arène : sud-est", 0.3), _go(26.0, 16.5, "arène : nord", 0.3),
				_go(31.0, 20.0, "arène : nord-est", 0.3), _go(31.0, 27.0, "arène : sud (demi-tour)", 0.3), _go(37.4, 23.0, "bouche du tunnel est", 0.3), _go(41.0, 23.0, "tunnel est", 0.3),
				_go(45.4, 23.0, "coursive : entrée", 0.3), _go(49.5, 24.5, "coursive : centre", 0.3), _go(45.4, 31.5, "coursive : sud", 0.3),
				_go(45.4, 14.0, "coursive : nord", 0.3), _go(45.4, 31.5, "coursive : sud (retour)", 0.3), _go(46.6, 33.6, "porte de l'infirmerie", 0.3),
				_go(46.6, 37.6, "infirmerie", 0.3), _go(46.6, 33.6, "retour", 0.3), _go(50.0, 23.0, "coursive (est)", 0.3),
				_go(58.0, 23.0, "couloir de sortie", 0.3), _go(62.0, 23.0, "devant la porte est", 0.3), {"do": "wait", "t": 1.0},
			]
		"p6_741_arene":
			# P7.4.1 — arène et gradins (profil de cadrage de la caméra V0.7-A dans le Colisée)
			var outq: Array = []
			for c in [["r1_arene_centre", 26.0, 23.0], ["r2_arene_sud", 26.0, 29.0], ["r3_sud_ouest", 19.0, 28.0],
					["r4_sud_est", 33.0, 28.0], ["r5_arene_nord", 26.0, 17.0], ["r6_bouche_est", 37.4, 23.0], ["r7_ouest", 15.0, 23.0]]:
				outq.append(_warp(c[1], c[2], 0.0))
				outq.append({"do": "wait", "t": 2.5})
				outq.append({"do": "snap", "id": c[0]})
			return outq
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
		"p7_trajets":
			# P7.1 — temps de trajet RÉELS du blockout (marche 2,2 m/s, clavier 8 directions, sans course ni téléport
			# pendant la mesure) ; chaque tronçon démarre par un placement, la durée est l'écart entre ses deux points
			return [
				_warp(127.5, 129.5, 0.0), {"do": "wait", "t": 0.5}, _go(127.5, 129.6, "T1 départ guilde", 0.3),
				_go(116.0, 129.5, "T1 parvis de la guilde", 0.4), _go(108.5, 131.0, "T1 avenue des Portes", 0.5),
				_go(108.5, 155.0, "T1 arrivée porte sud", 0.4),
				_warp(108.5, 155.0, 0.0), {"do": "wait", "t": 0.5}, _go(108.5, 154.9, "T2 départ porte sud", 0.3),
				_go(108.5, 106.0, "T2 pied de l'escalier", 0.4), _go(108.5, 99.0, "T2 haut de l'escalier", 0.4),
				_go(108.5, 65.0, "T2 entrée de la place", 0.5), _go(108.5, 57.0, "T2 arrivée grande place", 0.4),
				_warp(108.5, 57.0, 1.0), {"do": "wait", "t": 0.5}, _go(108.5, 57.1, "T3 départ grande place", 0.3),
				_go(88.0, 53.0, "T3 bord ouest de la place", 0.5), _go(65.0, 53.0, "T3 arrivée entrée du Colisée", 0.4),
				_warp(108.5, 155.0, 0.0), {"do": "wait", "t": 0.5}, _go(108.5, 154.9, "T4 départ porte sud", 0.3),
				_go(108.5, 129.5, "T4 avenue", 0.5), _go(127.5, 129.5, "T4 guilde", 0.4),
				_go(116.0, 129.5, "T4 parvis", 0.5), _go(116.0, 119.0, "T4 rue des boutiques", 0.5),
				_go(131.5, 119.0, "T4 ruelle de la forge", 0.4), _go(131.5, 106.0, "T4 rue haute des boutiques", 0.4),
				_go(140.0, 106.0, "T4 forge-armurerie", 0.4), _go(108.5, 106.0, "T4 avenue (boutiques)", 0.5),
				_go(108.5, 119.0, "T4 avenue (auberge)", 0.5), _go(88.0, 119.0, "T4 auberge-taverne", 0.4),
				_go(108.5, 119.0, "T4 retour avenue", 0.5), _go(108.5, 155.0, "T4 retour porte sud", 0.4),
				_warp(108.5, 57.0, 1.0), {"do": "wait", "t": 0.5}, _go(108.5, 57.1, "T5 départ place (boucle ouest)", 0.3),
				_go(69.0, 53.0, "T5 parvis du Colisée", 0.5), _go(69.0, 85.0, "T5 rue des Combattants", 0.5),
				_go(95.0, 85.0, "T5 marché (ouest)", 0.5), _go(108.5, 84.0, "T5 marché", 0.5),
				_go(108.5, 57.0, "T5 retour place", 0.4),
				_warp(108.5, 57.0, 1.0), {"do": "wait", "t": 0.5}, _go(108.5, 57.1, "T6 départ place (boucle est)", 0.3),
				_go(130.0, 50.0, "T6 rue du Conseil", 0.5), _go(152.0, 50.0, "T6 angle rue est", 0.5),
				_go(152.0, 85.0, "T6 rue est", 0.5), _go(128.0, 85.0, "T6 marché (est)", 0.5),
				_go(108.5, 84.0, "T6 marché", 0.5), _go(108.5, 57.0, "T6 retour place", 0.4),
				_warp(108.5, 57.0, 1.0), {"do": "wait", "t": 0.5}, _go(108.5, 57.1, "T7 départ place (château)", 0.3),
				_go(100.0, 50.0, "T7 contour de la fontaine", 0.5), _go(108.5, 32.0, "T7 avenue haute", 0.5),
				_go(108.5, 22.0, "T7 haut de l'escalier", 0.4), _go(108.5, 4.5, "T7 porte du château (fermée)", 0.6),
				_warp(108.5, 57.0, 1.0), {"do": "wait", "t": 0.5}, _go(108.5, 57.1, "T8 départ place (quartier est)", 0.3),
				_go(130.0, 50.0, "T8 rue du Conseil", 0.5), _go(152.0, 50.0, "T8 angle rue est", 0.5),
				_go(152.0, 69.0, "T8 passage est", 0.5), _go(186.5, 69.0, "T8 porte du quartier est (fermée)", 0.7),
				{"do": "wait", "t": 0.5},
			]
		"p7_v06_raccord":
			# P7.3 — raccord réel Colisée -> ville V0.6 (scène ville_v06_montee.tscn avec --etat=tutorial_completed) : sortie
			# est du Colisée, arrivée dans la rue du Colisée, quelques pas vers la grande place
			return [
				_warp(58.0, 23.0, 0.0), {"do": "wait", "t": 0.8},
				_go(62.5, 23.0, "couloir de sortie du Colisée", 0.3),
				{"do": "go", "to": Vector2(61.0, 29.4), "tol": 0.25, "id": "porte est du Colisée", "exit": true},
				{"do": "wait", "t": 1.5},
				_go(52.0, 92.0, "ville V0.6 : grande place", 0.4), {"do": "wait", "t": 1.0},
			]
		"p7_raccord":
			# P7.1 — raccord réel Colisée -> ville : couloir de sortie du Colisée, porte est, arrivée sur le parvis, quelques
			# pas vers la grande place (scène ville_v05_blockout.tscn avec --etat=tutorial_completed)
			return [
				_warp(58.0, 23.0, 0.0), {"do": "wait", "t": 0.8},
				_go(62.5, 23.0, "couloir de sortie du Colisée", 0.3),
				{"do": "go", "to": Vector2(61.0, 29.4), "tol": 0.25, "id": "porte est du Colisée", "exit": true},
				{"do": "wait", "t": 1.5},
				_go(72.0, 53.0, "ville : parvis du Colisée", 0.4),
				_go(88.0, 53.0, "ville : vers la grande place", 0.4),
				{"do": "wait", "t": 0.5},
			]
		"p7_camera":
			# P7.1 — continuité de la caméra : parcours de la vidéo SANS changement de zoom (×3 de bout en bout)
			var outk: Array = []
			for st in _route_base("p7_video"):
				if st["do"] != "zoom":
					outk.append(st)
			return outk
		"p7_vues":
			# P7.1 — vues demandées (A arrivée sud, B place -> hôtel de ville, C parvis -> Colisée) et contrôles, ×3 et ×2
			var outv: Array = []
			for z in [[2, "x3"], [0, "x2"]]:
				outv.append({"do": "zoom", "i": z[0], "smooth": false})
				for c in [["A_arrivee_sud", 108.5, 150.0, 0.0], ["B_place_hotel_de_ville", 150.0, 46.5, 1.0],
						["C_parvis_colisee", 72.0, 55.0, 1.0], ["D_guilde", 116.0, 132.0, 0.0], ["E_commerces", 112.0, 106.0, 0.0],
						["F_marche", 108.5, 88.0, 1.0], ["G_escalier_avenue", 108.5, 107.0, 0.0], ["H_avenue_haute", 108.5, 28.5, 1.0],
						["I_ruelle_ouest", 32.0, 141.0, 0.0], ["J_passage_est", 176.0, 69.0, 1.0]]:
					outv.append(_warp(c[1], c[2], c[3]))
					outv.append({"do": "wait", "t": 1.6})
					outv.append({"do": "snap", "id": c[0] + "_" + z[1]})
			return outv
		"p7_v05_equiv":
			# P7.3 — blockout V0.1 (plan V0.5), caméra d'origine P24 ×3, aux positions équivalentes de la V0.6
			var oute: Array = []
			for c in [["1_arrivee_sud", 108.5, 150.0, 0.0], ["2_guilde", 124.0, 129.5, 0.0], ["4_pied_montee_1", 108.5, 108.0, 0.0],
					["7_fontaine", 108.5, 56.0, 1.0], ["13_hotel_de_ville", 147.0, 46.0, 1.0], ["14_avenue_chateau", 108.5, 20.0, 2.0]]:
				oute.append(_warp(c[1], c[2], c[3]))
				oute.append({"do": "wait", "t": 1.8})
				oute.append({"do": "snap", "id": c[0]})
			return oute
		"p7_v07_vues":
			# P7.4 — repères de points de vue (MÊMES positions en A et en B) ; attente longue : la rotation B se pose
			var outr: Array = []
			for c in V07_VUES:
				outr.append(_warp(c[1], c[2], c[3]))
				outr.append({"do": "wait", "t": 3.5})
				outr.append({"do": "snap", "id": c[0]})
			return outr
		"p7_v07_video":
			# P7.4 — séquence de navigation identique en A et en B (brief § 5) : porte sud -> premier palier ; approche de
			# la grande place ; virage vers le Colisée puis retour ; montée haute et château ; descente ; détour par la
			# ruelle. Déplacements latéraux, demi-tours et passages répétés aux limites des zones de caméra.
			return [
				{"do": "wait", "t": 1.5},
				_go(60.0, 141.0, "1 placette des voyageurs", 0.4), _go(52.0, 136.0, "1 guilde", 0.4), {"do": "wait", "t": 0.8},
				_go(59.0, 134.0, "1 pied de la volée A", 0.3), _go(59.0, 125.6, "1 haut de la volée A", 0.3),
				_go(63.0, 123.5, "1 premier palier", 0.3), {"do": "wait", "t": 1.0},
				_go(65.0, 121.6, "2 pied de la volée B", 0.3), _go(65.0, 113.0, "2 arrivée sur la place", 0.4),
				_go(65.0, 119.0, "2 demi-tour sur la volée (limite de zone)", 0.4), _go(65.0, 112.0, "2 retour sur la place", 0.4),
				_go(54.0, 107.0, "2 grande place", 0.4), _go(40.0, 108.0, "2 latéral vers l'ouest", 0.4), _go(52.0, 108.0, "2 latéral vers l'est", 0.4),
				_go(34.0, 100.0, "3 vers la rue du Colisée", 0.4), _go(16.0, 100.0, "3 rue du Colisée", 0.4), _go(4.0, 92.0, "3 parvis du Colisée", 0.4),
				_go(-6.0, 90.0, "3 parvis (ouest)", 0.4), _go(26.0, 80.0, "3 allée du Colisée", 0.4), _go(30.5, 69.0, "3 perron, porte publique", 0.3),
				{"do": "wait", "t": 2.0}, _go(26.0, 80.0, "3 allée", 0.4), _go(26.0, 100.0, "3 retour", 0.4),
				_go(36.0, 93.0, "3 place (nord-ouest)", 0.4), _go(52.0, 93.0, "3 place (nord)", 0.4),
				_go(63.0, 89.5, "4 pied de la volée C", 0.3), _go(63.0, 81.6, "4 haut de la volée C", 0.3), _go(70.0, 79.5, "4 deuxième palier", 0.3),
				_go(71.0, 77.6, "4 pied de la volée D", 0.3), _go(71.0, 69.0, "4 terrasse haute", 0.4), _go(70.0, 52.0, "4 vers le château", 0.4),
				_go(70.0, 41.8, "4 porte du château (fermée)", 0.3), {"do": "wait", "t": 2.0},
				_go(88.0, 61.0, "4 rue haute (grille)", 0.4), {"do": "wait", "t": 1.0}, _go(60.0, 60.0, "4 terrasse (ouest)", 0.4),
				_go(71.0, 70.0, "5 haut de la volée D", 0.3), _go(71.0, 78.0, "5 descente D", 0.3), _go(63.0, 79.5, "5 palier", 0.3),
				_go(63.0, 82.0, "5 haut de la volée C", 0.3), _go(63.0, 90.0, "5 descente C", 0.3), _go(63.0, 98.0, "5 place", 0.4),
				_go(78.0, 108.0, "6 bras est de la place", 0.4), _go(82.0, 114.6, "6 haut de l'escalier de la ruelle", 0.3),
				_go(82.0, 126.0, "6 descente de la ruelle", 0.3), _go(82.0, 133.0, "6 ruelle", 0.3), _go(87.0, 140.0, "6 chantier", 0.4),
				{"do": "wait", "t": 1.0}, _go(66.0, 140.0, "6 retour à la placette", 0.4), _go(60.0, 150.0, "porte sud", 0.4),
				{"do": "wait", "t": 1.0},
			]
		"p7_v07_trajets":
			# P7.4 — temps de trajet réels (marche 2,2 m/s)
			return [
				_warp(60.0, 154.0, 0.0), {"do": "wait", "t": 0.5}, _go(60.0, 153.9, "T1 départ porte sud", 0.3),
				_go(59.0, 134.0, "T1 pied de la volée A", 0.3), _go(59.0, 125.6, "T1 haut de la volée A", 0.3),
				_go(63.0, 123.5, "T1 arrivée premier palier", 0.3),
				_go(65.0, 121.6, "T2 pied de la volée B", 0.3), _go(65.0, 113.0, "T2 haut de la volée B", 0.3),
				_go(52.0, 106.0, "T2 arrivée grande place", 0.4),
				_go(34.0, 100.0, "T3 ouest de la place", 0.4), _go(16.0, 100.0, "T3 rue du Colisée", 0.4), _go(26.0, 80.0, "T3 allée du Colisée", 0.4), _go(30.5, 69.0, "T3 arrivée porte publique du Colisée", 0.4),
				_warp(52.0, 106.0, 3.5), {"do": "wait", "t": 0.5}, _go(52.1, 106.0, "T4 départ grande place", 0.3),
				_go(63.0, 89.5, "T4 pied de la volée C", 0.3), _go(63.0, 81.6, "T4 haut de C", 0.3), _go(70.0, 79.5, "T4 palier", 0.3),
				_go(71.0, 77.6, "T4 pied de D", 0.3), _go(71.0, 69.0, "T4 terrasse", 0.4), _go(70.0, 41.8, "T4 arrivée porte du château", 0.3),
				_warp(52.0, 106.0, 3.5), {"do": "wait", "t": 0.5}, _go(52.1, 106.0, "T5 départ grande place", 0.3),
				_go(78.0, 108.0, "T5 bras est", 0.4), _go(82.0, 114.6, "T5 haut de la ruelle", 0.3), _go(82.0, 133.0, "T5 ruelle", 0.3),
				_go(80.0, 140.0, "T5 rue du chantier", 0.4), _go(60.0, 141.0, "T5 arrivée placette", 0.4),
				{"do": "wait", "t": 0.5},
			]
		"p7_v07_sondes":
			# P7.4 — sondes de collision : fronts, garde-corps, portes et grilles fermées, chantier, ruelle
			return [
				{"do": "wait", "t": 0.5},
				_warp(50.0, 134.0, 0.0), _push("façade de la guilde", Vector2(0, -1), 1.5, {"min_y": 132.2}),
				_warp(49.0, 140.0, 0.0), _push("front ouest de la placette", Vector2(-1, 0), 1.5, {"min_x": 48.2}),
				_warp(66.0, 133.0, 0.0), _push("mur du belvédère du palier (depuis la placette)", Vector2(0, -1), 1.5, {"min_y": 132.2}),
				_warp(65.0, 129.0, 1.75), _push("garde-corps du belvédère du palier", Vector2(0, 1), 1.5, {"max_y": 131.4, "h": 1.75}),
				_warp(20.0, 112.0, 3.5), _push("garde-corps ouest de la place", Vector2(0, 1), 1.5, {"max_y": 114.4, "h": 3.5}),
				_warp(59.0, 119.0, 3.5), _push("garde-corps du belvédère", Vector2(0, 1), 1.5, {"max_y": 120.4, "h": 3.5}),
				_warp(64.0, 123.5, 1.75), _push("bâtiment à l'est du palier", Vector2(1, 0), 1.5, {"max_x": 67.4, "h": 1.75}),
				_warp(40.0, 113.0, 3.5), _push("garde-corps de la place (vide de 3,5 m)", Vector2(0, 1), 1.5, {"max_y": 114.4, "h": 3.5}),
				_warp(45.0, 104.0, 3.5), _push("fontaine", Vector2(0, -1), 1.5, {"min_y": 102.2}),
				_warp(52.0, 90.0, 3.5), _push("façade de la forge", Vector2(0, -1), 1.5, {"min_y": 88.2}),
				_warp(28.5, 80.0, 3.5), _push("étals à l'est de l'allée du Colisée", Vector2(1, 0), 1.5, {"max_x": 29.8}),
				_warp(4.0, 102.0, 3.5), _push("front sud du parvis (bas)", Vector2(0, 1), 1.5, {"max_y": 103.8}),
				_warp(34.0, 62.0, 3.5), _push("front est du perron (étals)", Vector2(1, 0), 1.5, {"max_x": 35.8}),
				_warp(27.0, 68.5, 3.5), _push("pile sud-ouest du propylée", Vector2(0, -1), 1.5, {"min_y": 67.2}),
				_warp(35.5, 57.5, 3.5), _push("bâtiment au nord du perron", Vector2(0, -1), 1.5, {"min_y": 56.2}),
				_warp(30.4, 68.6, 3.5), _push("porte publique du Colisée (battants fermés)", Vector2(0, -1), 1.5, {"min_y": 66.6}),
				_warp(35.6, 62.0, 3.5), _push("arche est du propylée (aveugle)", Vector2(-1, 0), 1.5, {"min_x": 35.2}),
				_warp(28.0, 76.0, 3.5), _push("flanc du Colisée (allée)", Vector2(-1, 0), 2.0, {"min_x": 21.0}),
				_warp(62.0, 79.5, 5.75), _push("garde-corps ouest du palier 2", Vector2(-1, 0), 1.5, {"min_x": 60.6, "h": 5.75}),
				_warp(80.0, 69.0, 8.0), _push("garde-corps de la terrasse (vide de 4,5 m)", Vector2(0, 1), 1.5, {"max_y": 70.4, "h": 8.0}),
				_warp(70.0, 43.0, 8.0), _push("porte du château (fermée)", Vector2(0, -1), 1.5, {"min_y": 40.6}),
				_warp(92.0, 61.0, 8.0), _push("grille de la rue haute (fermée)", Vector2(1, 0), 1.5, {"max_x": 93.4}),
				_warp(87.0, 140.0, 0.0), _push("barrière du chantier", Vector2(1, 0), 1.5, {"max_x": 89.2}),
				_warp(82.0, 130.0, 0.0), _push("mur est de la ruelle", Vector2(1, 0), 1.5, {"max_x": 83.8}),
				_warp(60.0, 160.0, 0.0), _push("barrière de la route sud", Vector2(0, 1), 1.5, {"max_y": 161.2}),
			]
		"p7_v07_camera":
			# P7.4.1 — test de suivi : changements brusques de direction, bords de la scène (parvis du Colisée, x < 0),
			# abords des bâtiments et de l'entrée du Colisée, allers-retours aux limites des zones de caméra
			return [
				_warp(52.0, 106.0, 3.5), {"do": "wait", "t": 1.0},
				_go(20.0, 100.0, "rue du Colisée", 0.4), _go(-8.0, 100.0, "bord ouest du parvis", 0.4), _go(-8.0, 82.0, "angle nord-ouest du parvis", 0.4),
				_go(-8.0, 100.0, "demi-tour (sud)", 0.4), _go(20.0, 76.0, "diagonale vers le nord-est", 0.4), _go(-6.0, 90.0, "retour", 0.4),
				_go(20.0, 90.0, "est", 0.3), _go(-6.0, 90.0, "ouest", 0.3), _go(20.0, 90.0, "est", 0.3), _go(-6.0, 90.0, "ouest", 0.3),
				_go(14.0, 80.0, "pied du Colisée", 0.4), _go(10.0, 102.0, "sud du parvis", 0.4),
				_go(65.0, 112.0, "limite de zone (place)", 0.4), _go(65.0, 119.0, "hors zone (volée B)", 0.4), _go(65.0, 112.0, "dans la zone", 0.4),
				_go(65.0, 119.0, "hors zone", 0.4), _go(65.0, 112.0, "dans la zone", 0.4),
				_go(31.0, 89.0, "angle nord-ouest de la place", 0.4), _go(71.0, 89.0, "angle nord-est", 0.4), _go(31.0, 113.0, "angle sud-ouest", 0.4),
				_go(63.0, 89.5, "pied de la volée C", 0.3), _go(63.0, 81.6, "haut de C", 0.3), _go(70.0, 79.5, "palier 2", 0.3),
				_go(71.0, 77.6, "pied de D", 0.3), _go(71.0, 69.0, "terrasse", 0.3), _go(57.0, 51.0, "angle nord-ouest de la terrasse", 0.4),
				_go(89.0, 69.0, "angle sud-est", 0.4), _go(57.0, 69.0, "bord sud (ouest)", 0.4), _go(89.0, 51.0, "angle nord-est", 0.4),
				{"do": "wait", "t": 1.0},
			]
		"p7_v07b_sondes":
			# P7.5 — sondes de la V0.7-B : celles de la V0.7-A (sauf la grille de la rue haute, remplacée par du bâti) et
			# les nouveaux bords : auberge, boutique, étals, caravane, gardes et guérites, fronts des faubourgs
			var sb: Array = []
			for st in route("p7_v07_sondes"):
				if st.get("do", "") == "push" and str(st.get("id", "")).begins_with("grille de la rue haute"):
					sb.pop_back()
					continue
				if st.get("do", "") == "push" and str(st.get("id", "")) == "garde-corps ouest du palier 2":
					st = st.duplicate(true)
					st["expect"] = {"min_x": 58.4, "h": 5.75}   # V0.7-B : palier civique élargi vers l'ouest (x = 58)
				sb.append(st)
			sb += [
				_warp(70.0, 134.0, 0.0), _push("façade de l'auberge-taverne", Vector2(0, -1), 1.5, {"min_y": 132.2}),
				_warp(76.0, 134.0, 0.0), _push("terrasse de l'auberge -> auberge", Vector2(0, -1), 1.5, {"min_y": 132.2}),
				_warp(78.0, 90.0, 3.5), _push("façade de la boutique de fournitures", Vector2(0, -1), 1.5, {"min_y": 88.2}),
				_warp(79.0, 94.0, 3.5), _push("commerce à l'est du recoin", Vector2(1, 0), 1.5, {"max_x": 79.8}),
				_warp(33.0, 108.0, 3.5), _push("étal du bord sud de la place", Vector2(0, 1), 1.5, {"max_y": 110.4}),
				_warp(-11.0, 96.0, 3.5), _push("caravane (passage des faubourgs)", Vector2(-1, 0), 2.0, {"min_x": -13.3}),
				_warp(-12.0, 93.5, 3.5), _push("front nord du passage", Vector2(0, -1), 1.5, {"min_y": 92.2}),
				_warp(70.0, 44.5, 8.0), _push("grille du château (entre les gardes)", Vector2(0, -1), 2.0, {"min_y": 40.6}),
				_warp(67.0, 44.5, 8.0), _push("guérite ouest", Vector2(0, -1), 1.5, {"min_y": 42.8}),
				_warp(82.0, 52.0, 8.0), _push("façade de l'hôtel de ville", Vector2(0, -1), 1.5, {"min_y": 50.2}),
			]
			return sb
		"p7_v07b_diag":
			var od: Array = []
			for c in [["d1_caravane", -10.0, 96.0, 3.5], ["d2_ouest_place", 40.0, 96.0, 3.5], ["d3_ouest_place2", 46.0, 100.0, 3.5],
					["d4_ruelle_bas", 82.0, 130.0, 0.0], ["d5_ruelle_placette", 68.0, 137.0, 0.0], ["d6_parvis_est", 6.0, 96.0, 3.5],
					["d7_pied_A", 59.0, 136.0, 0.0], ["d8_belvedere", 65.0, 129.0, 1.75], ["d9_palier", 64.0, 123.5, 1.75], ["d10_perron", 30.5, 69.0, 3.5],
					["d11_allee", 26.0, 82.0, 3.5], ["d12_placette_est", 66.0, 140.0, 0.0],
					["d13_ruelle_pied", 82.0, 129.0, 0.0], ["d14_bras_est", 82.0, 108.0, 3.5], ["d15_bras_est_bout", 85.0, 104.0, 3.5]]:
				od.append(_warp(c[1], c[2], c[3]))
				od.append({"do": "wait", "t": 3.0})
				od.append({"do": "snap", "id": c[0]})
			return od
		"p7_76_anomalies":
			# P7.6 — lieux des anomalies d'affichage (captures avant / après et diagnostics --sans_proche / --sans_ombres /
			# --sans_cordons)
			var o76a: Array = []
			for c in [["x1_tambour", 6.0, 96.0, 3.5], ["x2_faubourgs", -12.0, 96.0, 3.5], ["x3_bras_est", 80.0, 110.0, 3.5],
					["x4_place_sud", 58.0, 104.0, 3.5], ["x5_perron", 30.5, 69.0, 3.5], ["x6_ruelle_chantier", 86.0, 140.0, 0.0],
					["x7_terrasse", 72.0, 66.0, 8.0], ["x8_parvis", 12.0, 100.0, 3.5]]:
				o76a.append(_warp(c[1], c[2], c[3]))
				o76a.append({"do": "wait", "t": 2.5})
				o76a.append({"do": "snap", "id": c[0]})
			return o76a
		"p7_v07b_vues":
			# P7.5 — repères de vues de la V0.7-B (caméra A par défaut ; --camera_ville=B pour comparer)
			var outb: Array = []
			for c in [["01_porte_sud", 60.0, 150.0, 0.0], ["02_placette_guilde", 56.0, 138.0, 0.0], ["03_auberge", 72.0, 138.0, 0.0],
					["04_rue_chantier", 85.0, 140.0, 0.0], ["05_premier_palier", 62.0, 123.5, 1.75], ["06_arrivee_place", 65.0, 112.0, 3.5],
					["07_grande_place", 50.0, 106.0, 3.5], ["08_recoin_boutique", 76.0, 94.0, 3.5], ["09_allee_colisee", 26.0, 82.0, 3.5],
					["10_porte_colisee", 30.5, 69.6, 3.5], ["11_parvis_faubourgs", -6.0, 96.0, 3.5], ["12_pied_montee_civique", 62.0, 90.0, 3.5],
					["13_palier_civique", 66.0, 79.5, 5.75], ["14_terrasse_civique", 70.0, 62.0, 8.0], ["15_acces_chateau", 70.0, 46.0, 8.0],
					["16_ruelle", 82.0, 130.0, 0.0]]:
				outb.append(_warp(c[1], c[2], c[3]))
				outb.append({"do": "wait", "t": 3.0})
				outb.append({"do": "snap", "id": c[0]})
			return outb
		"p7_v07b_video":
			# P7.5 — visite complète : porte sud, Guilde, auberge, rue du chantier (A), placette, montée, grande place, boutique,
			# Colisée (porte), parvis et faubourgs (B), montée civique, hôtel de ville, accès gardé (C), redescente par la ruelle
			return [
				{"do": "wait", "t": 1.5},
				_go(60.0, 141.0, "placette", 0.4), _go(52.0, 136.0, "Guilde", 0.4), {"do": "wait", "t": 0.8},
				_go(70.0, 134.0, "auberge-taverne", 0.4), _go(76.0, 134.0, "terrasse de l'auberge", 0.4), _go(86.0, 140.0, "travaux (quartier est)", 0.4),
				{"do": "wait", "t": 1.0}, _go(66.0, 140.0, "retour à la placette", 0.4),
				_go(59.0, 134.0, "pied de la volée A", 0.3), _go(59.0, 125.6, "haut de A", 0.3), _go(63.0, 123.5, "palier", 0.3),
				_go(65.0, 121.6, "pied de la volée B", 0.3), _go(65.0, 113.0, "grande place", 0.4), _go(54.0, 107.0, "fontaine", 0.4),
				_go(76.0, 94.0, "recoin de la boutique", 0.4), _go(52.0, 93.0, "forge", 0.4), _go(36.0, 93.0, "ouest de la place", 0.4),
				_go(26.0, 82.0, "allée du Colisée", 0.4), _go(30.5, 69.4, "porte du Colisée", 0.3), {"do": "wait", "t": 1.5},
				_go(26.0, 82.0, "allée", 0.4), _go(4.0, 92.0, "parvis", 0.4), _go(-11.0, 96.0, "passage des faubourgs (caravane)", 0.4),
				{"do": "wait", "t": 1.5}, _go(20.0, 100.0, "rue du Colisée", 0.4), _go(52.0, 93.0, "place (nord)", 0.4),
				_go(62.0, 89.5, "pied de la montée civique", 0.3), _go(62.0, 81.6, "haut de C", 0.3), _go(71.0, 79.5, "palier civique", 0.3),
				_go(72.0, 77.6, "pied de D", 0.3), _go(72.0, 69.0, "terrasse civique", 0.4), _go(82.0, 52.0, "hôtel de ville", 0.4),
				_go(70.0, 45.0, "accès gardé du château", 0.3), {"do": "wait", "t": 1.5},
				_go(72.0, 70.0, "redescente", 0.3), _go(72.0, 78.0, "D", 0.3), _go(62.0, 79.5, "palier", 0.3), _go(62.0, 90.0, "C", 0.3),
				_go(78.0, 108.0, "bras est", 0.4), _go(82.0, 114.6, "haut de la ruelle", 0.3), _go(82.0, 133.0, "ruelle", 0.3),
				_go(76.0, 134.0, "terrasse de l'auberge (boucle)", 0.4), _go(60.0, 150.0, "porte sud", 0.4), {"do": "wait", "t": 1.0},
			]
		"p7_v07b_trajets":
			return [
				_warp(60.0, 154.0, 0.0), {"do": "wait", "t": 0.5}, _go(60.0, 153.9, "T1 départ porte sud", 0.3),
				_go(52.0, 134.0, "T1 arrivée Guilde", 0.4),
				_go(59.0, 134.0, "T2 pied de la volée A", 0.3), _go(59.0, 125.6, "T2 haut de A", 0.3), _go(63.0, 123.5, "T2 palier", 0.3),
				_go(65.0, 121.6, "T2 pied de B", 0.3), _go(65.0, 113.0, "T2 arrivée grande place", 0.4),
				_go(36.0, 93.0, "T3 ouest de la place", 0.4), _go(26.0, 82.0, "T3 allée", 0.4), _go(30.5, 69.4, "T3 arrivée porte du Colisée", 0.3),
				_warp(54.0, 107.0, 3.5), {"do": "wait", "t": 0.5}, _go(54.1, 107.0, "T4 départ fontaine", 0.3),
				_go(62.0, 89.5, "T4 pied de C", 0.3), _go(62.0, 81.6, "T4 haut de C", 0.3), _go(71.0, 79.5, "T4 palier", 0.3),
				_go(72.0, 77.6, "T4 pied de D", 0.3), _go(72.0, 69.0, "T4 terrasse", 0.3), _go(70.0, 45.0, "T4 arrivée accès du château", 0.3),
				_warp(54.0, 107.0, 3.5), {"do": "wait", "t": 0.5}, _go(54.1, 107.0, "T5 départ fontaine (boucle)", 0.3),
				_go(78.0, 108.0, "T5 bras est", 0.4), _go(82.0, 114.6, "T5 haut de la ruelle", 0.3), _go(82.0, 133.0, "T5 ruelle", 0.3),
				_go(76.0, 134.0, "T5 terrasse de l'auberge", 0.4), _go(60.0, 140.0, "T5 placette", 0.4),
				_go(59.0, 134.0, "T5 pied de A", 0.3), _go(59.0, 125.6, "T5 haut de A", 0.3), _go(63.0, 123.5, "T5 palier", 0.3),
				_go(65.0, 121.6, "T5 pied de B", 0.3), _go(65.0, 113.0, "T5 arrivée place (boucle bouclée)", 0.4),
				{"do": "wait", "t": 0.5},
			]
		"p7_742_entree":
			# P7.4.2 — entrée du Colisée : depuis la grande place, à mi-chemin, devant le portail, côtés du parvis (A et B)
			var oute: Array = []
			for c in [["1_depuis_la_place", 40.0, 104.0], ["2_mi_chemin", 27.0, 84.0], ["3_devant_le_portail", 30.5, 69.2],
					["4_parvis_ouest", 6.0, 88.0], ["5_parvis_est", 35.0, 69.5], ["6_devant_la_porte", 30.4, 68.6]]:
				oute.append(_warp(c[1], c[2], 3.5))
				oute.append({"do": "wait", "t": 3.5})
				oute.append({"do": "snap", "id": c[0]})
			return oute
		"p6_742_arene":
			# P7.4.2 — démonstration de l'arène (plongée locale de 20°) : salle d'attente, tunnel sud (11°), débouché
			# (pivot vers 20°), gradins sud (ouest et est), demi-tours, retour dans le tunnel (pivot vers 11°)
			return [
				_warp(26.0, 41.5, 0.0), {"do": "wait", "t": 1.5},
				_go(26.0, 34.0, "tunnel sud (11°)", 0.3), _go(26.0, 29.0, "débouché (pivot vers 20°)", 0.3), {"do": "wait", "t": 1.0},
				_go(19.0, 28.5, "près des gradins sud-ouest", 0.3), _go(33.0, 28.5, "près des gradins sud-est", 0.3),
				_go(30.0, 20.0, "nord de l'arène", 0.3), _go(19.0, 28.5, "retour au sud-ouest", 0.3), _go(26.0, 29.0, "bouche du tunnel", 0.3),
				_go(26.0, 34.5, "retour dans le tunnel (pivot vers 11°)", 0.3), {"do": "wait", "t": 1.5},
			]
		"p7_742_approche":
			# P7.4.2 — même trajet en A et en B : grande place -> allée -> perron -> arche sud -> porte publique (entrée)
			return [
				_warp(44.0, 104.0, 3.5), {"do": "wait", "t": 2.0},
				_go(30.0, 93.0, "vers l'allée du Colisée", 0.4), _go(26.0, 82.0, "allée", 0.4), _go(30.5, 69.0, "devant l'arche sud", 0.3),
				{"do": "wait", "t": 1.0}, _go(34.5, 69.0, "perron (est)", 0.3), _go(30.5, 69.0, "retour devant l'arche", 0.3),
				{"do": "wait", "t": 0.8},
				_go(30.45, 68.4, "devant la porte publique", 0.3), {"do": "talk", "id": "entrée dans le Colisée (porte publique, E)"},
				{"do": "wait", "t": 2.0},
			]
		"p7_v07_portail":
			# P7.4.1 — liaison bidirectionnelle ville <-> Colisée par la porte publique (portail colisee_porte_publique) :
			# entrée par le vestibule est du tambour, arrivée dans le couloir de sortie du Colisée (tourné vers l'ouest),
			# quelques pas, retour par la porte est, arrivée sur le perron (tourné vers l'est), puis deuxième aller-retour
			return [
				_warp(26.0, 80.0, 3.5), {"do": "wait", "t": 0.8},
				_go(30.5, 69.5, "ville : perron", 0.3), {"do": "wait", "t": 0.5},
				_go(30.45, 68.4, "devant la porte publique", 0.3), {"do": "talk", "id": "ville -> Colisée (porte publique) (porte publique, E)"},
				{"do": "wait", "t": 1.6},
				_go(58.0, 23.0, "Colisée : couloir de sortie", 0.3), _go(52.0, 23.0, "Colisée : vers la coursive", 0.3),
				_go(61.5, 23.0, "Colisée : retour vers la porte est", 0.3),
				{"do": "go", "to": Vector2(61.0, 29.4), "tol": 0.25, "id": "Colisée -> ville (porte est)", "exit": true},
				{"do": "wait", "t": 1.6},
				_go(35.0, 69.0, "ville : perron (arrivée)", 0.3), _go(26.0, 80.0, "ville : allée", 0.3), _go(30.5, 69.5, "ville : retour au perron", 0.3),
				_go(30.45, 68.4, "devant la porte publique", 0.3), {"do": "talk", "id": "ville -> Colisée (2e passage) (porte publique, E)"},
				{"do": "wait", "t": 1.6},
				{"do": "go", "to": Vector2(61.0, 29.4), "tol": 0.25, "id": "Colisée -> ville (2e passage)", "exit": true},
				{"do": "wait", "t": 1.6}, _go(30.0, 70.0, "ville : perron sud", 0.3),
			]
		"p7_v07_raccord":
			# P7.4 — raccord réel Colisée -> ville V0.7-A (avec --etat=tutorial_completed)
			return [
				_warp(58.0, 23.0, 0.0), {"do": "wait", "t": 0.8},
				_go(62.5, 23.0, "couloir de sortie du Colisée", 0.3),
				{"do": "go", "to": Vector2(61.0, 29.4), "tol": 0.25, "id": "porte est du Colisée", "exit": true},
				{"do": "wait", "t": 1.5},
				_go(26.0, 80.0, "ville V0.7-A : allée du Colisée", 0.4), _go(20.0, 100.0, "ville V0.7-A : rue du Colisée", 0.4), {"do": "wait", "t": 1.0},
			]
		"p7_v06_vues":
			# P7.3 — ville V0.6 : vues de contrôle (même caméra pour toutes ; la caméra vient de la scène / --cam_v06=)
			var outw: Array = []
			for c in V06_VUES:
				outw.append(_warp(c[1], c[2], c[3]))
				outw.append({"do": "wait", "t": 1.8})
				outw.append({"do": "snap", "id": c[0]})
			return outw
		"p7_v06_video":
			# P7.3 — vidéo continue de la ville V0.6 (marche 2,2 m/s, caméra unique) : porte sud, guilde, auberge, montée,
			# grande place, forge, rue du Colisée, montée civique, hôtel de ville, porte du château, puis redescente
			# (déplacements dans les quatre directions, descentes des deux escaliers)
			return [
				{"do": "wait", "t": 1.5},
				_go(60.0, 158.0, "avenue des Voyageurs", 0.4), _go(66.5, 155.0, "vers la guilde", 0.4),
				_go(70.0, 151.4, "guilde (seuil)", 0.3), {"do": "wait", "t": 1.2},
				_go(63.0, 150.0, "avenue", 0.4), _go(56.0, 141.0, "vers l'auberge", 0.4), _go(50.0, 137.4, "auberge (seuil)", 0.3),
				{"do": "wait", "t": 1.0},
				_go(57.0, 133.0, "avenue", 0.4), _go(60.0, 128.4, "pied de la montée", 0.3), _go(60.0, 116.0, "haut de la montée", 0.4),
				_go(60.0, 108.5, "grande place", 0.4), _go(67.0, 100.0, "autour de la fontaine", 0.4), _go(72.0, 91.0, "", 0.4),
				_go(74.0, 85.6, "forge (seuil)", 0.3), {"do": "wait", "t": 1.0},
				_go(58.0, 92.0, "place", 0.4), _go(43.0, 90.0, "rue du Colisée", 0.4), _go(39.5, 90.0, "portes du Colisée (fermées)", 0.3),
				{"do": "wait", "t": 1.2},
				_go(50.0, 94.0, "place", 0.4), _go(60.0, 86.0, "pied de la montée civique", 0.3), _go(60.0, 71.0, "parvis civique", 0.4),
				_go(70.0, 58.0, "", 0.4), _go(74.0, 51.4, "hôtel de ville (seuil)", 0.3), {"do": "wait", "t": 1.0},
				_go(62.0, 52.0, "avenue du château", 0.4), _go(60.0, 30.0, "", 0.4), _go(60.0, 25.6, "porte du château (fermée)", 0.3),
				{"do": "wait", "t": 1.5},
				_go(65.0, 40.0, "redescente", 0.4), _go(52.0, 60.0, "parvis (ouest)", 0.4), _go(60.0, 70.0, "", 0.4),
				_go(60.0, 86.0, "bas de la montée civique", 0.4), _go(46.0, 100.0, "place (ouest)", 0.4), _go(60.0, 114.0, "", 0.4),
				_go(60.0, 130.0, "bas de la montée", 0.4), _go(60.0, 150.0, "avenue", 0.4), _go(60.0, 164.0, "porte sud", 0.4),
				{"do": "wait", "t": 1.0},
			]
		"p7_v06_trajets":
			# P7.3 — temps de trajet réels (marche 2,2 m/s, sans course ni téléport pendant la mesure)
			return [
				_warp(60.0, 166.0, 0.0), {"do": "wait", "t": 0.5}, _go(60.0, 165.9, "T1 départ porte sud", 0.3),
				_go(66.5, 155.0, "T1 placette", 0.4), _go(70.0, 151.4, "T1 arrivée guilde", 0.3),
				_go(63.0, 140.0, "T2 avenue", 0.4), _go(60.0, 128.4, "T2 pied de la montée", 0.3),
				_go(60.0, 117.0, "T2 haut de la montée", 0.4), _go(60.0, 105.4, "T2 arrivée fontaine", 0.4),
				_go(66.0, 100.0, "T3 contour de la fontaine", 0.4), _go(60.0, 86.0, "T3 pied de la montée civique", 0.3), _go(60.0, 71.0, "T3 haut de la montée civique", 0.4),
				_go(74.0, 51.4, "T3 arrivée hôtel de ville", 0.3),
				_warp(60.0, 106.0, 3.5), {"do": "wait", "t": 0.5}, _go(60.0, 106.1, "T4 départ fontaine", 0.3),
				_go(43.0, 90.0, "T4 rue du Colisée", 0.4), _go(39.5, 90.0, "T4 arrivée portes du Colisée", 0.3),
				_warp(74.0, 51.4, 8.0), {"do": "wait", "t": 0.5}, _go(74.0, 51.5, "T5 départ hôtel de ville", 0.3),
				_go(60.0, 40.0, "T5 avenue du château", 0.4), _go(60.0, 25.6, "T5 arrivée porte du château", 0.3),
				{"do": "wait", "t": 0.5},
			]
		"p7_v06_sondes":
			# P7.3 — sondes de collision de la ville V0.6 : fronts bâtis, garde-corps, portes fermées, fontaine, remises
			return [
				{"do": "wait", "t": 0.5},
				_warp(55.0, 154.0, 0.0), _push("front ouest de l'avenue", Vector2(-1, 0), 1.5, {"min_x": 54.2}),
				_warp(65.0, 132.0, 0.0), _push("front est de l'avenue", Vector2(1, 0), 1.5, {"max_x": 65.8}),
				_warp(72.0, 152.0, 0.0), _push("façade de la guilde", Vector2(0, -1), 1.5, {"min_y": 150.2}),
				_warp(72.0, 158.0, 0.0), _push("muret au sud de la placette", Vector2(0, 1), 1.5, {"max_y": 159.8}),
				_warp(50.0, 142.0, 0.0), _push("muret au sud de la terrasse de l'auberge", Vector2(0, 1), 1.5, {"max_y": 143.8}),
				_warp(48.0, 138.0, 0.0), _push("front ouest de la terrasse", Vector2(-1, 0), 1.5, {"min_x": 46.2}),
				_warp(45.0, 116.0, 3.5), _push("garde-corps de la place (vide de 3,5 m)", Vector2(0, 1), 1.5, {"max_y": 117.7, "h": 3.5}),
				_warp(79.0, 92.0, 3.5), _push("front est de la place", Vector2(1, 0), 1.5, {"max_x": 79.8}),
				_warp(74.0, 86.0, 3.5), _push("façade de la forge", Vector2(0, -1), 1.5, {"min_y": 84.2}),
				_warp(60.0, 106.0, 3.5), _push("fontaine", Vector2(0, -1), 1.5, {"min_y": 103.7}),
				_warp(39.0, 90.0, 3.5), _push("portes du Colisée (fermées)", Vector2(-1, 0), 1.5, {"min_x": 36.3}),
				_warp(48.0, 70.0, 8.0), _push("garde-corps du parvis (vide de 4,5 m)", Vector2(0, 1), 1.5, {"max_y": 71.7, "h": 8.0}),
				_warp(74.0, 52.0, 8.0), _push("façade de l'hôtel de ville", Vector2(0, -1), 1.5, {"min_y": 50.2}),
				_warp(60.0, 26.0, 8.0), _push("porte du château (fermée)", Vector2(0, -1), 1.5, {"min_y": 24.5}),
				_warp(60.0, 180.0, 0.0), _push("barrière de la route sud", Vector2(0, 1), 1.5, {"max_y": 181.4}),
				_warp(41.0, 100.0, 3.5), _push("front ouest de la place", Vector2(-1, 0), 1.5, {"min_x": 40.2}),
			]
		"p7_video":
			# P7.1 — vidéo continue (marche, ×3 avec passages à ×2) : arrivée sud, guilde, commerces, auberge, avenue, place,
			# Colisée (parvis), boucle ouest, marché, boucle est, accès est, place, avenue haute, accès nord
			return [
				{"do": "wait", "t": 1.0},
				{"do": "zoom", "i": 0, "smooth": true}, {"do": "wait", "t": 1.5}, {"do": "zoom", "i": 2, "smooth": true},
				_go(108.5, 129.5, "avenue des Portes", 0.5), _go(127.5, 129.5, "guilde", 0.4),
				_go(116.0, 129.5, "parvis de la guilde", 0.5), _go(116.0, 119.0, "rue des boutiques", 0.5),
				_go(131.5, 119.0, "ruelle", 0.4), _go(131.5, 106.0, "rue haute des boutiques", 0.4), _go(140.0, 106.0, "forge-armurerie", 0.4),
				_go(108.5, 106.0, "herboriste, objets", 0.5), _go(108.5, 119.0, "avenue", 0.5), _go(88.0, 119.0, "auberge-taverne", 0.4),
				_go(108.5, 119.0, "avenue", 0.5), _go(108.5, 106.0, "pied de l'escalier", 0.4), _go(108.5, 92.0, "marché", 0.5),
				{"do": "zoom", "i": 0, "smooth": true},
				_go(108.5, 60.0, "grande place (×2)", 0.5), {"do": "wait", "t": 1.0},
				{"do": "zoom", "i": 2, "smooth": true},
				_go(88.0, 53.0, "vers le parvis", 0.5), _go(67.0, 53.0, "entrée du Colisée", 0.4), {"do": "wait", "t": 1.0},
				_go(69.0, 85.0, "rue des Combattants (boucle ouest)", 0.5), _go(95.0, 85.0, "marché", 0.5),
				_go(128.0, 85.0, "marché (est)", 0.5), _go(152.0, 85.0, "rue est (boucle est)", 0.5),
				_go(152.0, 69.0, "passage est", 0.5), _go(184.0, 69.0, "porte du quartier est (fermée)", 0.6), {"do": "wait", "t": 0.8},
				_go(152.0, 69.0, "retour", 0.5), _go(152.0, 50.0, "rue du Conseil", 0.5), _go(130.0, 50.0, "hôtel de ville", 0.5),
				_go(100.0, 50.0, "place", 0.5), _go(108.5, 32.0, "avenue haute", 0.5), _go(108.5, 5.0, "porte du château (fermée)", 0.6),
				{"do": "wait", "t": 1.5},
			]
		"p6_644_vestiaires":
			# P6.4.4 — visibilité de l'arène depuis les vestiaires : centre, coin nord-ouest, porte nord, passage, aux
			# zooms ×3 et ×2 (le parcours démarre aux vestiaires, état d'origine du jeu)
			var outv: Array = []
			for z in [[2, "x3"], [0, "x2"]]:
				outv.append({"do": "zoom", "i": z[0], "smooth": false})
				for c in [["v1_centre", 26.0, 51.5], ["v2_nord_ouest", 18.0, 49.6], ["v3_porte_nord", 26.0, 49.0],
						["v4_nord_est", 34.0, 49.6], ["v5_passage", 26.0, 45.6]]:
					outv.append(_warp(c[1], c[2], 0.0))
					outv.append({"do": "wait", "t": 1.6})
					outv.append({"do": "snap", "id": c[0] + "_" + z[1]})
			return outv
		"p6_644_video":
			# P6.4.4 — vidéo avant / après : départ normal du jeu dans les vestiaires (×2 puis ×3), passage, salle d'attente
			# (aucune arène visible), tunnel sud (vue par la bouche), débouché dans l'arène
			return [
				{"do": "zoom", "i": 0, "smooth": false},
				{"do": "wait", "t": 1.0},
				_go(18.5, 49.8, "vestiaires : coin nord-ouest (×2)", 0.3),
				_go(33.5, 49.8, "vestiaires : le long du mur nord (×2)", 0.3),
				{"do": "zoom", "i": 2, "smooth": true},
				_go(26.0, 49.2, "vestiaires : devant la porte nord (×3)", 0.25),
				_go(26.0, 45.6, "passage", 0.25),
				_go(26.0, 41.2, "salle d'attente", 0.25),
				{"do": "zoom", "i": 0, "smooth": true},
				{"do": "wait", "t": 1.2},
				_go(26.0, 37.0, "entrée du tunnel (×2)", 0.25),
				{"do": "zoom", "i": 2, "smooth": true},
				_go(26.0, 34.6, "tunnel sud : milieu", 0.2),
				_go(26.0, 29.5, "débouché dans l'arène", 0.25),
				{"do": "wait", "t": 1.5},
			]
		"p7_76_sortie":
			# P7.6 — fin de la coursive est et sortie vers la ville (captures avant / après)
			var o76: Array = []
			for c in [["s1_coursive_est", 52.0, 23.0], ["s2_seuil", 56.5, 23.0], ["s3_fin_couloir", 60.0, 24.5], ["s4_porte", 60.5, 27.5]]:
				o76.append(_warp(c[1], c[2], 0.0))
				o76.append({"do": "wait", "t": 2.0})
				o76.append({"do": "snap", "id": c[0]})
			return o76
		"p7_76_arrivees":
			# P7.6 — arrivées du portail colisee_porte_publique (captures) : ville -> vestibule ; vestibule -> perron
			return [
				_warp(30.5, 70.5, 3.5), {"do": "wait", "t": 1.0},
				_go(30.45, 68.4, "devant la porte publique", 0.3), {"do": "talk", "id": "ville -> Colisée (porte publique, E)"},
				{"do": "wait", "t": 2.5}, {"do": "snap", "id": "a1_arrivee_vestibule"},
				{"do": "go", "to": Vector2(61.0, 29.4), "tol": 0.25, "id": "Colisée -> ville (porte sud du vestibule)", "exit": true},
				{"do": "wait", "t": 2.5}, {"do": "snap", "id": "a2_arrivee_perron"},
			]
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

