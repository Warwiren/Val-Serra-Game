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


static func route(name: String) -> Array:
	match name:
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
				_go(31.6, 14.9, "panneau de la plaine", 0.3),
				{"do": "talk", "id": "panneau"},
				{"do": "next"},
				_go(34.4, 12.6, "sous l'arbre pilote (devant)"),
				_go(34.6, 9.2, "derrière l'arbre pilote", 0.3),
				_go(32.4, 9.6, "derrière l'arbre pilote (ouest)", 0.3),
				_go(34.0, 16.0, "H chemin de la plaine"),
				_go(40.4, 20.6, "plaine sud"),
				_go(37.0, 16.0, "abords du Vorgane", 0.3),
				{"do": "wait", "t": 0.5},
			]
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

