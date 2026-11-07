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
	if mode == "micro":
		return [["1_entree", 2.6, 14, 0.0], ["2_place", 13, 14, 0.0], ["3_escalier", 14, 9.6, 0.0],
			["4_terrasse", 12.5, 5.6, 1.2], ["5_derriere_arbre", 6.6, 15.3, 0.0]]
	return [["1_entree_A", 2.6, 14, 0.0], ["2_place_B", 13, 14, 0.0], ["3_escalier", 14, 9.6, 0.0],
		["4_PNJ_E", 11.9, 5.6, 1.2], ["5_pont_F", 23.5, 13.75, 0.0], ["6_derriere_arbre", 6.6, 15.3, 0.0],
		["7_derriere_maison", 18.0, 2.5, 1.2], ["8_sortie_G", 29.6, 13.75, 0.0]]
