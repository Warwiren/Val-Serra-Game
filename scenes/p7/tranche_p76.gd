extends RefCounted
## P7.6 — TRANCHE ARCHITECTURALE de la ville (PILOTE, NON VALIDÉ) : îlot de l'auberge-taverne et ruelle des Tonneliers.
##
## Une seule zone, raccordée à la grande place par le bras est : la ruelle (petite rue montante), son escalier et ses
## murs d'échiffre, l'auberge-taverne (commerce, entrée sur sa terrasse), la maison de la ruelle et la maison du bras
## est (deux à trois niveaux). Le reste du quartier garde le blockout : ces matières et façades ne s'étendent PAS à toute
## la ville avant validation (--tranche=0 : blockout V0.7-B dans la zone, pour comparer).
##
## Architecture cohérente avec le Colisée : MÊMES matières procédurales (src/p6/maconnerie_p64.gdshader, calcaire
## ocre / gris chaud du second pilote validé : « mur2 », « moulure », « dalle », « dallage2 », tuiles « tuiles_a »),
## rez-de-chaussée de pierre, étages à l'enduit de chaux (src/p7/enduit_p76.gdshader), baies à encadrement de pierre,
## volets, balcons sur consoles, corniches, toits de tuiles canal (versant face à la caméra). Lecture HD-2D : silhouettes
## et rythmes de baies lisibles à 22 m, aucun détail sous le pixel ; collisions inchangées (celles des données).

const HAB := preload("res://scenes/p6/habillage_p6.gd")
const MACON_SH := preload("res://src/p6/maconnerie_p64.gdshader")
const ENDUIT_SH := preload("res://src/p7/enduit_p76.gdshader")

## Emprise de la tranche (la maison du bras est, l'auberge, la ruelle, la terrasse et le départ de la rue du chantier)
const ZONE := Rect2(66.0, 98.0, 36.0, 48.0)
const SOLS := ["ruelle", "terrasse_auberge", "place_bras_est", "pied_ruelle_escalier"]
const ESCALIER := "ruelle_escalier"

## Bâtiments de la tranche : niveaux (pied, planchers, corniche), enduit, volets, faîtage ; façades visibles (s, e, o)
## avec leurs baies par niveau : [u, largeur, hauteur, appui, style] (u : abscisse le long de la façade, en m).
const BATIMENTS := {
	"bat_auberge_taverne": {
		"niveaux": [0.0, 3.4, 5.6, 7.5], "enduit": Color(0.90, 0.80, 0.63), "volets": Color(0.22, 0.37, 0.30), "toit_h": 2.6,
		"cheminee": [78.4, 119.0],
		"faces": {
			"s": [[[3.0, 2.4, 2.3, 0.55, "baie"]],
				[[3.0, 1.0, 1.85, 0.0, "porte_fenetre"], [6.0, 1.0, 1.85, 0.0, "porte_fenetre"], [9.7, 0.9, 1.4, 0.5, "fenetre"]],
				[[3.0, 0.9, 1.15, 0.35, "fenetre"], [6.0, 0.9, 1.15, 0.35, "fenetre"], [9.0, 0.9, 1.15, 0.35, "fenetre"]]],
			"e": [[[2.2, 0.8, 1.0, 1.25, "barreaux"], [5.2, 0.8, 1.0, 1.25, "barreaux"]],
				[[2.2, 0.9, 1.4, 0.5, "fenetre"], [5.2, 0.9, 1.4, 0.5, "fenetre"], [8.2, 0.9, 1.4, 0.5, "fenetre"], [11.2, 0.9, 1.4, 0.5, "fenetre"], [14.2, 0.9, 1.4, 0.5, "fenetre"]],
				[[2.2, 0.8, 1.05, 0.4, "fenetre"], [5.2, 0.8, 1.05, 0.4, "fenetre"], [8.2, 0.8, 1.05, 0.4, "fenetre"], [11.2, 0.8, 1.05, 0.4, "fenetre"], [14.2, 0.8, 1.05, 0.4, "fenetre"]]],
			"o": [[],
				[[3.0, 0.9, 1.4, 0.5, "fenetre"], [7.0, 0.9, 1.4, 0.5, "fenetre"], [11.0, 0.9, 1.4, 0.5, "fenetre"], [15.0, 0.9, 1.4, 0.5, "fenetre"]],
				[[3.0, 0.8, 1.05, 0.4, "fenetre"], [7.0, 0.8, 1.05, 0.4, "fenetre"], [11.0, 0.8, 1.05, 0.4, "fenetre"], [15.0, 0.8, 1.05, 0.4, "fenetre"]]],
		},
		# balcons : [face, u0, u1, niveau (index du plancher), profondeur]
		"balcons": [["s", 1.6, 8.3, 1, 0.9]],                  # s'arrête avant l'enseigne en potence de l'entrée
	},
	"bat_b_e_ruelle": {
		"niveaux": [0.0, 3.2, 5.6, 8.0], "enduit": Color(0.86, 0.72, 0.54), "volets": Color(0.26, 0.34, 0.47), "toit_h": 2.8,
		"cheminee": [97.0, 121.0],
		"faces": {
			"s": [[[8.0, 2.4, 2.0, 0.5, "devanture"], [13.0, 0.9, 1.2, 1.0, "barreaux"]],
				[[2.0, 0.9, 1.4, 0.5, "fenetre"], [6.0, 0.9, 1.4, 0.5, "fenetre"], [10.0, 1.0, 1.85, 0.0, "porte_fenetre"], [14.0, 0.9, 1.4, 0.5, "fenetre"]],
				[[2.0, 0.8, 1.15, 0.4, "fenetre"], [6.0, 0.8, 1.15, 0.4, "fenetre"], [10.0, 0.8, 1.15, 0.4, "fenetre"], [14.0, 0.8, 1.15, 0.4, "fenetre"]]],
			# façade ouest : le long de la ruelle (u depuis le nord, y = 115) ; rez-de-chaussée seulement au-dessus du sol bas
			"o": [[[15.5, 0.8, 1.0, 1.3, "barreaux"], [19.0, 0.8, 1.0, 1.3, "barreaux"]],
				[[3.0, 0.9, 1.4, 0.6, "fenetre"], [6.5, 0.9, 1.4, 0.6, "fenetre"], [10.0, 0.9, 1.4, 0.6, "fenetre"], [13.5, 1.0, 1.85, 0.0, "porte_fenetre"], [17.0, 0.9, 1.4, 0.6, "fenetre"]],
				[[3.0, 0.8, 1.1, 0.4, "fenetre"], [6.5, 0.8, 1.1, 0.4, "fenetre"], [10.0, 0.8, 1.1, 0.4, "fenetre"], [13.5, 0.8, 1.1, 0.4, "fenetre"], [17.0, 0.8, 1.1, 0.4, "fenetre"]]],
		},
		"balcons": [["s", 9.0, 11.0, 1, 0.7], ["o", 12.6, 14.4, 1, 0.7]],
		"lanternes": [["o", 11.8, 2.9], ["s", 5.0, 2.7]],
	},
	"bat_b_bras_est_e": {
		"niveaux": [3.5, 6.6, 9.5], "enduit": Color(0.82, 0.78, 0.71), "volets": Color(0.52, 0.22, 0.17), "toit_h": 2.4,
		"faces": {
			"o": [[[3.0, 1.0, 1.6, 0.6, "fenetre"], [7.5, 1.1, 2.3, 0.0, "porte_deco"], [12.0, 1.0, 1.6, 0.6, "fenetre"]],
				[[3.0, 0.9, 1.3, 0.45, "fenetre"], [7.5, 0.9, 1.3, 0.45, "fenetre"], [12.0, 0.9, 1.3, 0.45, "fenetre"]]],
			"s": [[],
				[[4.0, 0.9, 1.3, 0.45, "fenetre"], [8.0, 0.9, 1.3, 0.45, "fenetre"], [12.0, 0.9, 1.3, 0.45, "fenetre"]]],
		},
		"balcons": [],
	},
}

const PIERRE_VILLE := Color(1.32, 1.22, 1.08)
var b                 # constructeur de la ville (scenes/p7/ville_v07b.gd)
var sc                # scène (colisee.gd)
var _mats := {}
var elements := 0     # maillages ajoutés (compte rendu : coût d'affichage de la tranche)
var rects := {}       # emprises des bâtiments de la tranche (portes des données posées sur leurs façades)


func _init(builder) -> void:
	b = builder
	sc = builder.sc


func actif() -> bool:
	return str(sc._cli.get("tranche", "1")) != "0"


func contient(id: String) -> bool:
	return actif() and BATIMENTS.has(id)


# ------------------------------------------------------------------------------------------------ matières
func macon(nom: String, teinte := Color.WHITE, base_y := 0.0, uv := "monde", hole := true) -> ShaderMaterial:
	var k := "m|%s|%s|%s|%s|%s" % [nom, teinte, base_y, uv, hole]
	if _mats.has(k):
		return _mats[k]
	var d: Dictionary = HAB.P64_PRESETS[nom]
	var m := ShaderMaterial.new()
	m.shader = MACON_SH
	for key in d:
		var val = d[key]
		if val is Color and teinte != Color.WHITE:
			val = (val as Color) * teinte
		m.set_shader_parameter(key, val)
	if float(d.get("k_terre", 0.0)) > 0.0 or float(d.get("k_mousse", 0.0)) > 0.0:
		m.set_shader_parameter("peint_terre", load(HAB.PEINT_TERRE))
		m.set_shader_parameter("peint_mousse", load(HAB.PEINT_MOUSSE))
	if int(d["motif"]) != 2:
		m.set_shader_parameter("grain", load(HAB.GRAIN))
		m.set_shader_parameter("grain_k", 0.32 if int(d["motif"]) != 3 else 0.18)
		m.set_shader_parameter("grain_m", 1.4)
	m.set_shader_parameter("uv_mode", 0.0 if uv == "monde" else 1.0)
	m.set_shader_parameter("uv_m", 1.0)
	m.set_shader_parameter("base_y", base_y)
	m.set_shader_parameter("hole", 1.0 if hole else 0.0)
	_mats[k] = m
	return m


func enduit(c: Color, base_y: float, haut_y: float) -> ShaderMaterial:
	var k := "e|%s|%s|%s" % [c, base_y, haut_y]
	if _mats.has(k):
		return _mats[k]
	var m := ShaderMaterial.new()
	m.shader = ENDUIT_SH
	m.set_shader_parameter("couleur", c)
	m.set_shader_parameter("grain", load(HAB.GRAIN))
	m.set_shader_parameter("base_y", base_y)
	m.set_shader_parameter("haut_y", haut_y)
	m.set_shader_parameter("hole", 1.0)
	_mats[k] = m
	return m


func plein(c: Color, rough := 0.85, emission := 0.0, metal := 0.0) -> StandardMaterial3D:
	var k := "p|%s|%s|%s|%s" % [c, rough, emission, metal]
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	_mats[k] = m
	return m


func moulure() -> ShaderMaterial:
	return macon("moulure", Color(1.12, 1.08, 1.02))


# ------------------------------------------------------------------------------------------------ géométrie
## Façade d'un rectangle : origine (pied, début), tangente le long de la façade, normale sortante, longueur.
func face(r: Rect2, cote: String) -> Dictionary:
	match cote:
		"s":
			return {"o": Vector3(r.position.x, 0, r.end.y), "t": Vector3(1, 0, 0), "n": Vector3(0, 0, 1), "L": r.size.x}
		"e":
			return {"o": Vector3(r.end.x, 0, r.end.y), "t": Vector3(0, 0, -1), "n": Vector3(1, 0, 0), "L": r.size.y}
		"o":
			return {"o": Vector3(r.position.x, 0, r.position.y), "t": Vector3(0, 0, 1), "n": Vector3(-1, 0, 0), "L": r.size.y}
	return {"o": Vector3(r.end.x, 0, r.position.y), "t": Vector3(-1, 0, 0), "n": Vector3(0, 0, -1), "L": r.size.x}


## Boîte posée sur une façade : u0..u1 le long, v0..v1 en altitude (m, absolue), d0..d1 vers l'extérieur.
func boite(f: Dictionary, u0: float, u1: float, v0: float, v1: float, d0: float, d1: float, m: Material) -> MeshInstance3D:
	var t: Vector3 = f["t"]
	var n: Vector3 = f["n"]
	var c: Vector3 = f["o"] + t * ((u0 + u1) * 0.5) + n * ((d0 + d1) * 0.5)
	c.y = (v0 + v1) * 0.5
	var sx := absf(t.x) * (u1 - u0) + absf(n.x) * (d1 - d0)
	var sz := absf(t.z) * (u1 - u0) + absf(n.z) * (d1 - d0)
	elements += 1
	return sc._box_mesh(c, Vector3(sx, v1 - v0, sz), m)


## Barreaux (garde-corps, grilles) : un seul MultiMesh par série (coût d'affichage d'un seul maillage).
func barreaux(points: Array, taille: Vector3, m: Material) -> void:
	if points.is_empty():
		return
	var bm := BoxMesh.new()
	bm.size = taille
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bm
	mm.instance_count = points.size()
	for i in points.size():
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, points[i]))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = m
	sc.root.add_child(mi)
	elements += 1


# ------------------------------------------------------------------------------------------------ bâtiments
func batiment(id: String, r: Rect2, h0: float, h1: float) -> void:
	var d: Dictionary = BATIMENTS[id]
	rects[id] = r
	var nv: Array = d["niveaux"]
	var n1: float = nv[1]
	var top: float = nv[nv.size() - 1]
	# corps : rez-de-chaussée de pierre, étages à l'enduit (collision : celle des données, posée par la scène)
	# pierre éclaircie et réchauffée pour l'éclairage de la ville (soleil bas, ciel) : même calcaire que le Colisée
	var pierre := macon("mur2", PIERRE_VILLE, h0)
	var mi: MeshInstance3D = sc._box_mesh(sc._rect_center(r, h0, n1), Vector3(r.size.x, n1 - h0, r.size.y), pierre)
	mi.name = id
	sc._box_mesh(sc._rect_center(r, n1, top), Vector3(r.size.x, top - n1, r.size.y), enduit(d["enduit"], n1, top))
	elements += 2
	var faces: Dictionary = d["faces"]
	for cote in faces:
		var f := face(r, cote)
		var L: float = f["L"]
		# soubassement saillant (assise de base), bandeaux d'étage, corniche à consoles
		boite(f, -0.12, L + 0.12, h0, h0 + 0.55, 0.0, 0.1, macon("socle2", PIERRE_VILLE, h0))
		for i in range(1, nv.size() - 1):
			boite(f, -0.06, L + 0.06, float(nv[i]) - 0.1, float(nv[i]) + 0.12, 0.0, 0.08, moulure())
		boite(f, -0.3, L + 0.3, top - 0.28, top, 0.0, 0.3, moulure())
		boite(f, -0.38, L + 0.38, top, top + 0.1, 0.0, 0.4, moulure())
		# chaînes d'angle (harpes) : pierres alternées aux deux extrémités, sur les étages
		var v := n1
		var k := 0
		while v < top - 0.3:
			var lg := 0.55 if k % 2 == 0 else 0.32
			for ua in [[0.0, lg], [L - lg, L]]:
				boite(f, ua[0], ua[1], v, v + 0.34, 0.0, 0.04, moulure())
			v += 0.36
			k += 1
		var niveaux_baies: Array = faces[cote]
		for i in niveaux_baies.size():
			var plancher: float = nv[i]
			for w in niveaux_baies[i]:
				baie(f, float(w[0]), plancher + float(w[3]), float(w[1]), float(w[2]), str(w[4]), d["volets"])
	for bal in d.get("balcons", []):
		balcon(face(r, bal[0]), float(bal[1]), float(bal[2]), float(nv[int(bal[3])]), float(bal[4]))
	for la in d.get("lanternes", []):
		lanterne(face(r, la[0]), float(la[1]), h0 + float(la[2]))
	toit(r, top, float(d["toit_h"]), d)
	if d.has("cheminee"):
		var c: Array = d["cheminee"]
		var hc := top + float(d["toit_h"]) + 1.0
		sc._box_mesh(Vector3(c[0], (top + hc) * 0.5, c[1]), Vector3(0.9, hc - top, 0.7), macon("mur2", PIERRE_VILLE * 0.92, top))
		sc._box_mesh(Vector3(c[0], hc + 0.08, c[1]), Vector3(1.1, 0.16, 0.9), moulure())
		elements += 2


## Baie : embrasure sombre, encadrement de pierre (piédroits, linteau à clef, appui saillant), menuiserie, volets ouverts
## ou grille. Styles : fenetre, porte_fenetre, baie (grande baie de la taverne), barreaux, devanture (échoppe fermée),
## porte_deco (porte de façade fermée).
func baie(f: Dictionary, u: float, v0: float, w: float, h: float, style: String, c_volets: Color) -> void:
	var u0 := u - w * 0.5
	var u1 := u + w * 0.5
	var v1 := v0 + h
	var sombre := plein(Color(0.07, 0.07, 0.09), 0.35)
	var bois := plein(Color(0.30, 0.21, 0.14))
	var fer := plein(Color(0.13, 0.13, 0.14), 0.5, 0.0, 0.5)
	var pierre := moulure()
	boite(f, u0, u1, v0, v1, 0.0, 0.02, sombre)
	if style in ["porte_deco", "devanture"]:
		# battant(s) plein(s) de bois, planches marquées
		boite(f, u0 + 0.04, u1 - 0.04, v0, v1 - 0.04, 0.0, 0.05, bois)
		var x := u0 + 0.3
		while x < u1 - 0.2:
			boite(f, x - 0.015, x + 0.015, v0 + 0.05, v1 - 0.08, 0.0, 0.06, plein(Color(0.20, 0.14, 0.10)))
			x += 0.3
		if style == "devanture":
			boite(f, u0 - 0.1, u1 + 0.1, v1 + 0.05, v1 + 0.45, 0.0, 0.06, plein(c_volets.darkened(0.2)))      # bandeau d'enseigne
	elif style == "baie":
		# grande baie de la taverne : petits bois en grille, lumière chaude de la salle derrière les carreaux
		boite(f, u0 + 0.06, u1 - 0.06, v0 + 0.06, v1 - 0.06, 0.0, 0.025, plein(Color(0.95, 0.66, 0.32), 0.6, 0.7))
		var nx := 4
		for i in range(1, nx):
			var xx := u0 + w * i / nx
			boite(f, xx - 0.025, xx + 0.025, v0, v1, 0.0, 0.05, bois)
		for j in range(1, 3):
			var yy := v0 + h * j / 3.0
			boite(f, u0, u1, yy - 0.025, yy + 0.025, 0.0, 0.05, bois)
	elif style == "barreaux":
		var pts := []
		var x2 := u0 + 0.12
		while x2 < u1 - 0.05:
			pts.append(f["o"] + f["t"] * x2 + f["n"] * 0.06 + Vector3(0, (v0 + v1) * 0.5, 0))
			x2 += 0.14
		barreaux(pts, Vector3(0.03, h, 0.03), fer)
	else:
		# menuiserie : croisée (fenêtre) ou meneau seul (porte-fenêtre)
		boite(f, u - 0.03, u + 0.03, v0, v1, 0.0, 0.045, bois)
		if style == "fenetre":
			boite(f, u0, u1, v0 + h * 0.62 - 0.03, v0 + h * 0.62 + 0.03, 0.0, 0.045, bois)
		# volets ouverts, rabattus contre la façade
		var cv := plein(c_volets)
		var cvs := plein(c_volets.darkened(0.25))
		for s in [-1.0, 1.0]:
			var a0: float = (u0 - 0.16 - w * 0.5) if s < 0.0 else (u1 + 0.16)
			var a1: float = a0 + w * 0.5
			boite(f, a0, a1, v0 + 0.02, v1 - 0.02, 0.0, 0.04, cv)
			for yy in [v0 + h * 0.25, v0 + h * 0.75]:
				boite(f, a0 + 0.03, a1 - 0.03, yy - 0.04, yy + 0.04, 0.0, 0.05, cvs)
	# encadrement
	boite(f, u0 - 0.15, u0, v0, v1, 0.0, 0.07, pierre)
	boite(f, u1, u1 + 0.15, v0, v1, 0.0, 0.07, pierre)
	boite(f, u0 - 0.15, u1 + 0.15, v1, v1 + 0.2, 0.0, 0.08, pierre)
	boite(f, u - 0.1, u + 0.1, v1 - 0.02, v1 + 0.26, 0.0, 0.11, pierre)        # clef
	if v0 > 0.2 and style != "porte_fenetre" and style != "porte_deco" and style != "devanture":
		boite(f, u0 - 0.2, u1 + 0.2, v0 - 0.12, v0, 0.0, 0.15, pierre)       # appui


## Balcon sur consoles : dalle de pierre, consoles, garde-corps de fer (barreaux en MultiMesh).
func balcon(f: Dictionary, u0: float, u1: float, v: float, prof: float) -> void:
	var pierre := moulure()
	var fer := plein(Color(0.13, 0.13, 0.14), 0.5, 0.0, 0.5)
	boite(f, u0, u1, v - 0.16, v, 0.0, prof, pierre)
	var x := u0 + 0.3
	while x < u1 - 0.2:
		boite(f, x - 0.1, x + 0.1, v - 0.5, v - 0.16, 0.0, prof * 0.75, pierre)
		x += 1.4
	boite(f, u0, u1, v + 0.92, v + 0.97, prof - 0.06, prof - 0.01, fer)
	boite(f, u0, u1, v + 0.12, v + 0.16, prof - 0.06, prof - 0.01, fer)
	var pts := []
	var xx := u0 + 0.05
	while xx < u1:
		pts.append(f["o"] + f["t"] * xx + f["n"] * (prof - 0.035) + Vector3(0, v + 0.54, 0))
		xx += 0.16
	for s in [0.0, 1.0]:
		var uu: float = u0 + 0.02 if s == 0.0 else u1 - 0.02
		var dd := 0.1
		while dd < prof - 0.05:
			pts.append(f["o"] + f["t"] * uu + f["n"] * dd + Vector3(0, v + 0.54, 0))
			dd += 0.16
	barreaux(pts, Vector3(0.025, 0.8, 0.025), fer)


## Lanterne murale : potence de fer et verre chaud émissif (aucune lumière ajoutée : l'éclairage n'est pas repris).
func lanterne(f: Dictionary, u: float, v: float) -> void:
	var fer := plein(Color(0.13, 0.13, 0.14), 0.5, 0.0, 0.5)
	boite(f, u - 0.03, u + 0.03, v + 0.3, v + 0.36, 0.0, 0.45, fer)
	boite(f, u - 0.12, u + 0.12, v - 0.05, v + 0.28, 0.32, 0.56, plein(Color(1.0, 0.72, 0.36), 0.6, 1.6))
	boite(f, u - 0.15, u + 0.15, v + 0.28, v + 0.34, 0.29, 0.59, fer)


## Toit à deux versants, faîtage selon x (le versant sud fait face à la caméra), débord de 0,45 m, tuiles canal
## procédurales (UV en mètres le long du versant), pignons à l'enduit, faîtière et rives.
func toit(r: Rect2, h: float, ht: float, d: Dictionary) -> void:
	var dd := 0.45
	var x0 := r.position.x - dd
	var x1 := r.end.x + dd
	var ys := r.end.y + dd
	var yn := r.position.y - dd
	var ym := r.get_center().y
	var pente := (ht + dd * ht / (r.size.y * 0.5)) / (ys - ym)
	var hb := h - dd * pente                                # égout (débord abaissé dans le prolongement du versant)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vers in [[ys, 1.0], [yn, -1.0]]:
		var ye: float = vers[0]
		var s: float = vers[1]
		var a := Vector3(x0, hb, ye)
		var bb := Vector3(x1, hb, ye)
		var c := Vector3(x1, h + ht, ym)
		var e := Vector3(x0, h + ht, ym)
		var lg := Vector2(ye - ym, hb - (h + ht)).length()
		var nrm := Vector3(0, absf(ye - ym), s * (h + ht - hb)).normalized()
		for tri in [[a, bb, c], [a, c, e]]:
			for order in [[0, 1, 2], [0, 2, 1]]:
				var flip: bool = order[1] == 2
				for i in order:
					var p: Vector3 = tri[i]
					st.set_normal(-nrm if flip else nrm)
					st.set_uv(Vector2(p.x, -(lg * (1.0 - (p.y - hb) / (h + ht - hb)))))
					st.add_vertex(p)
	var mt := macon("tuiles_a", Color(1.05, 1.0, 0.98), h, "maillage", false)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mt
	sc.root.add_child(mi)
	# pignons (enduit), faîtière, rives de bois
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in [r.position.x, r.end.x]:
		var tri2 := [Vector3(x, h, r.end.y), Vector3(x, h, r.position.y), Vector3(x, h + ht, ym)]
		for order in [[0, 1, 2], [0, 2, 1]]:
			for i in order:
				st2.set_normal(Vector3(1 if x > r.get_center().x else -1, 0, 0) * (1.0 if order[1] == 1 else -1.0))
				st2.add_vertex(tri2[i])
	var mp := MeshInstance3D.new()
	mp.mesh = st2.commit()
	mp.material_override = enduit(d["enduit"], h, h + ht)
	sc.root.add_child(mp)
	sc._box_mesh(Vector3(r.get_center().x, h + ht + 0.06, ym), Vector3(r.size.x + 2.0 * dd + 0.1, 0.2, 0.34), macon("tuiles_a", Color(0.85, 0.8, 0.8), h, "monde", false))
	sc._box_mesh(Vector3(r.get_center().x, hb - 0.08, ys - 0.03), Vector3(r.size.x + 2.0 * dd, 0.16, 0.08), plein(Color(0.26, 0.18, 0.12)))
	elements += 4


# ------------------------------------------------------------------------------------------------ sols et escalier
## Sols de la tranche : dallage enrichi du Colisée ; caniveau central dans la ruelle ; bordure au raccord avec la place.
func sol(id: String, r: Rect2, h: float) -> void:
	var th := 0.3
	var mi: MeshInstance3D = sc._box_mesh(sc._rect_center(r, h - th, h), Vector3(r.size.x, th, r.size.y), macon("dallage2", Color(1.04, 1.02, 1.0), h, "monde", false))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elements += 1
	if id == "ruelle":
		sc._box_mesh(Vector3(r.get_center().x, h + 0.004, r.get_center().y), Vector3(0.36, 0.01, r.size.y), macon("dalle", Color(0.72, 0.7, 0.68), h, "monde", false))
		elements += 1
	if id == "place_bras_est":
		# bordure de pierre : seuil entre la grande place (blockout) et la tranche
		sc._box_mesh(Vector3(r.position.x + 0.2, h + 0.006, r.get_center().y), Vector3(0.4, 0.012, r.size.y), moulure())
		elements += 1


## Escalier de la ruelle : marches de dalles et contremarches de pierre ; murs d'échiffre en gradins le long des deux
## façades (ils portent la montée) ; collisions identiques à celles du socle (ville_v06._escalier).
func escalier(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var n: int = e["risers"]
	var rise: float = (e["h1"] - e["h0"]) / n
	var yb: float = r.end.y - e["land_bottom"]
	var yt: float = r.position.y + e["land_top"]
	var tread: float = (yb - yt) / n
	var md := macon("dalle", Color.WHITE, e["h0"], "monde", false)
	var mc := macon("gradin", Color.WHITE, e["h0"], "monde", false)
	var pierre := macon("mur2", PIERRE_VILLE * 0.95, e["h0"])
	for i in n:
		var top: float = e["h0"] + rise * (i + 1)
		var y1 := yb - tread * i
		var y0 := yb - tread * (i + 1)
		sc._box_mesh(Vector3(r.get_center().x, (e["h0"] + top - 0.06) / 2.0, (y0 + y1) / 2.0), Vector3(r.size.x - 0.24, top - 0.06 - e["h0"], y1 - y0), mc)
		sc._box_mesh(Vector3(r.get_center().x, top - 0.03, (y0 + y1) / 2.0 + 0.02), Vector3(r.size.x - 0.24, 0.06, y1 - y0 + 0.04), md)
		# murs d'échiffre : un gradin par marche, 0,9 m au-dessus du giron, de part et d'autre
		for xj in [r.position.x + 0.06, r.end.x - 0.06]:
			sc._box_mesh(Vector3(xj, (e["h0"] + top + 0.9) / 2.0, (y0 + y1) / 2.0), Vector3(0.12, top + 0.9 - e["h0"], y1 - y0), pierre)
			sc._box_mesh(Vector3(xj, top + 0.93, (y0 + y1) / 2.0), Vector3(0.2, 0.06, y1 - y0), moulure())
		elements += 6
	sc._box_mesh(Vector3(r.get_center().x, e["h1"] / 2.0, (r.position.y + yt) / 2.0), Vector3(r.size.x, e["h1"], yt - r.position.y), md)
	elements += 1
	# collisions (identiques au socle)
	var sb := StaticBody3D.new()
	sb.collision_layer = sc.L_FLOOR
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cv := ConvexPolygonShape3D.new()
	var x0 := r.position.x
	var x1 := r.end.x
	cv.points = PackedVector3Array([Vector3(x0, e["h0"], yb), Vector3(x1, e["h0"], yb), Vector3(x0, e["h1"], yt), Vector3(x1, e["h1"], yt),
		Vector3(x0, e["h0"], yt), Vector3(x1, e["h0"], yt)])
	cs.shape = cv
	sb.add_child(cs)
	sc.root.add_child(sb)
	sc._static_box(Vector3(r.get_center().x, e["h1"] / 2.0, (r.position.y + yt) / 2.0), Vector3(r.size.x, e["h1"], yt - r.position.y), sc.L_FLOOR)
	for x in [r.position.x + 0.06, r.end.x - 0.06]:
		sc._static_box(Vector3(x, (e["h0"] + e["h1"] + 0.2) / 2.0, (yt + yb) / 2.0), Vector3(0.12, e["h1"] + 0.2 - e["h0"], yb - yt), sc.L_OBST)


## Muret bas (bord de rue côté caméra) : appareil de soubassement, chaperon de pierre, jardinet planté sur le dessus.
func muret(r: Rect2, h0: float, h1: float) -> void:
	sc._box_mesh(sc._rect_center(r, h0, h1 - 0.12), Vector3(r.size.x, h1 - 0.12 - h0, r.size.y), macon("socle2", PIERRE_VILLE, h0))
	sc._box_mesh(sc._rect_center(r.grow(0.06), h1 - 0.12, h1), Vector3(r.size.x + 0.12, 0.12, r.size.y + 0.12), moulure())
	var terre := plein(Color(0.30, 0.26, 0.19))
	var vert := plein(Color(0.27, 0.36, 0.20))
	var ri := r.grow(-0.45)
	sc._box_mesh(sc._rect_center(ri, h1 - 0.02, h1 + 0.02), Vector3(ri.size.x, 0.04, ri.size.y), terre)
	# haie basse continue le long du bord nord (côté rue), taillée en deux hauteurs
	var x := ri.position.x
	var k := 0
	while x < ri.end.x - 0.1:
		var lg := minf(2.4, ri.end.x - x)
		var ht := 0.55 if k % 2 == 0 else 0.7
		sc._box_mesh(Vector3(x + lg * 0.5, h1 + ht * 0.5, ri.position.y + 0.55), Vector3(lg - 0.05, ht, 1.0), vert)
		x += lg
		k += 1
	elements += 3 + k
