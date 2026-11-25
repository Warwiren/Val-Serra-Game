extends RefCounted
## P7.7 — COMPOSANTS ARCHITECTURAUX RÉUTILISABLES de la ville, tirés de la tranche pilote P7.6 (direction approuvée le
## 25/11/2026 : rez-de-chaussée de pierre, étages enduits, façades de plusieurs niveaux, toits de tuiles).
##
## Bibliothèque sans état de scène : elle ajoute ses maillages sous `racine` (aucune collision : les collisions restent
## celles des données). Les valeurs par défaut reproduisent EXACTEMENT la tranche P7.6 (vérifié au pixel près) ; les
## variantes sont des options des descriptions. Catalogue F6 : scenes/p7/catalogue_archi_p77.tscn.
##
## Description d'un bâtiment (dictionnaire) :
##   niveaux      [pied, plancher 1, …, corniche] (m, absolus)
##   enduit       couleur de l'enduit ; volets : couleur des volets (ou palette : PALETTES[nom])
##   rdc          "pierre" (défaut) | "bossage" | "enduit"      etages : "enduit" (défaut) | "pierre"
##   faces        {"s"|"e"|"o"|"n": [baies du niveau 0, du niveau 1, …]} ; baie = [u, largeur, hauteur, appui, type]
##   volets_style "pleins" (défaut) | "persiennes" | "fermes" | "aucun"
##   corniche     "simple" (défaut) | "consoles"                  chaines : true (défaut) | false
##   toit         "2p_x" (défaut : faîtage est-ouest, versant face caméra) | "2p_y" (pignon face caméra) | "croupe" | "appentis"
##   toit_h       hauteur du toit ; tuiles : teinte des tuiles ; cheminee : [x, y]
##   balcons      [[face, u0, u1, niveau, profondeur, style]] ; style "fer" (défaut) | "pierre" | "balconnet"
##   lanternes    [[face, u, hauteur au-dessus du pied]]
## Types de baie : fenetre, fenetre_simple, fenetre_cintree, porte_fenetre, oeil_de_boeuf, barreaux, baie (grande baie
## de salle), vitrine (boutique, auvent), devanture (échoppe fermée), porte_deco (planches), porte_cloutee, porte_vitree,
## porte_cochere.

const HAB := preload("res://scenes/p6/habillage_p6.gd")
const MACON_SH := preload("res://src/p6/maconnerie_p64.gdshader")
const ENDUIT_SH := preload("res://src/p7/enduit_p76.gdshader")

## Pierre éclaircie et réchauffée pour l'éclairage de la ville : même calcaire que le Colisée (second pilote validé)
const PIERRE_VILLE := Color(1.32, 1.22, 1.08)
## Palettes (enduit, volets). « miel », « ocre » et « gris_chaud » sont celles de la tranche P7.6.
const PALETTES := {
	"miel": [Color(0.90, 0.80, 0.63), Color(0.22, 0.37, 0.30)],
	"ocre": [Color(0.86, 0.72, 0.54), Color(0.26, 0.34, 0.47)],
	"gris_chaud": [Color(0.82, 0.78, 0.71), Color(0.52, 0.22, 0.17)],
	"rose": [Color(0.88, 0.71, 0.63), Color(0.31, 0.38, 0.31)],
	"creme": [Color(0.93, 0.89, 0.79), Color(0.42, 0.29, 0.18)],
	"terre": [Color(0.79, 0.60, 0.44), Color(0.20, 0.31, 0.40)],
}
const TYPES_BAIES := ["fenetre", "fenetre_simple", "fenetre_cintree", "porte_fenetre", "oeil_de_boeuf", "barreaux", "baie",
	"vitrine", "devanture", "porte_deco", "porte_cloutee", "porte_vitree", "porte_cochere"]
const PORTES := ["porte_deco", "porte_cloutee", "porte_vitree", "porte_cochere", "devanture"]

var racine: Node3D
var _mats := {}
var elements := 0          # maillages ajoutés (coût d'affichage)


func _init(r: Node3D) -> void:
	racine = r


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


func fer() -> StandardMaterial3D:
	return plein(Color(0.13, 0.13, 0.14), 0.5, 0.0, 0.5)


func bois() -> StandardMaterial3D:
	return plein(Color(0.30, 0.21, 0.14))


# ------------------------------------------------------------------------------------------------ géométrie
func box(c: Vector3, taille: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = taille
	mi.mesh = bm
	mi.material_override = m
	mi.position = c
	racine.add_child(mi)
	return mi


static func centre(r: Rect2, h0: float, h1: float) -> Vector3:
	return Vector3(r.get_center().x, (h0 + h1) / 2.0, r.get_center().y)


## Façade d'un rectangle : origine (pied, début), tangente le long de la façade, normale sortante, longueur.
static func face(r: Rect2, cote: String) -> Dictionary:
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
	return box(c, Vector3(sx, v1 - v0, sz), m)


## Boîte posée sur une façade, tournée d'un angle autour de la normale (claveaux d'arc, losanges) : centre (u, v),
## dimensions a (le long) × b (en hauteur), saillie d0..d1.
func boite_tournee(f: Dictionary, u: float, v: float, a: float, b: float, d0: float, d1: float, angle: float, m: Material) -> MeshInstance3D:
	var t: Vector3 = f["t"]
	var n: Vector3 = f["n"]
	var c: Vector3 = f["o"] + t * u + n * ((d0 + d1) * 0.5)
	c.y = v
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(a, b, d1 - d0)
	mi.mesh = bm
	mi.material_override = m
	mi.basis = Basis(t, Vector3.UP, n) * Basis(Vector3(0, 0, 1), angle)
	mi.position = c
	racine.add_child(mi)
	elements += 1
	return mi


## Série de petites boîtes identiques (barreaux, lames, clous) : un seul MultiMesh (coût d'affichage d'un seul maillage).
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
	racine.add_child(mi)
	elements += 1


## Taille monde d'un élément (le long, hauteur, saillie) sur une façade.
static func taille_face(f: Dictionary, a: float, b: float, d: float) -> Vector3:
	var t: Vector3 = f["t"]
	var n: Vector3 = f["n"]
	return Vector3(absf(t.x) * a + absf(n.x) * d, b, absf(t.z) * a + absf(n.z) * d)


static func point_face(f: Dictionary, u: float, v: float, d: float) -> Vector3:
	var p: Vector3 = f["o"] + (f["t"] as Vector3) * u + (f["n"] as Vector3) * d
	p.y = v
	return p


# ------------------------------------------------------------------------------------------------ bâtiment
func batiment(r: Rect2, h0: float, d: Dictionary) -> void:
	var depuis := racine.get_child_count()
	_batiment(r, h0, d)
	fusionner(depuis, "bat_" + str(d.get("id", "")))


func _batiment(r: Rect2, h0: float, d: Dictionary) -> void:
	var nv: Array = d["niveaux"]
	var n1: float = nv[1]
	var top: float = nv[nv.size() - 1]
	var c_enduit: Color = d["enduit"]
	var c_volets: Color = d["volets"]
	# corps : rez-de-chaussée (pierre, bossage ou enduit) et étages (enduit ou pierre) ; collision : celle des données
	var rdc := str(d.get("rdc", "pierre"))
	var m_rdc: Material = macon("mur2", PIERRE_VILLE, h0)
	if rdc == "bossage":
		m_rdc = macon("socle2", PIERRE_VILLE * 1.05, h0)
	elif rdc == "enduit":
		m_rdc = enduit(c_enduit.darkened(0.04), h0, n1)
	var mi: MeshInstance3D = box(centre(r, h0, n1), Vector3(r.size.x, n1 - h0, r.size.y), m_rdc)
	mi.name = str(d.get("id", "batiment"))
	var m_et: Material = enduit(c_enduit, n1, top)
	if str(d.get("etages", "enduit")) == "pierre":
		m_et = macon("mur_haut2", PIERRE_VILLE * 1.08, n1)
	box(centre(r, n1, top), Vector3(r.size.x, top - n1, r.size.y), m_et)
	elements += 2
	var faces: Dictionary = d["faces"]
	for cote in faces:
		var f := face(r, cote)
		var L: float = f["L"]
		# soubassement saillant (assise de base), bandeaux d'étage, corniche
		boite(f, -0.12, L + 0.12, h0, h0 + 0.55, 0.0, 0.1, macon("socle2", PIERRE_VILLE, h0))
		for i in range(1, nv.size() - 1):
			boite(f, -0.06, L + 0.06, float(nv[i]) - 0.1, float(nv[i]) + 0.12, 0.0, 0.08, moulure())
		boite(f, -0.3, L + 0.3, top - 0.28, top, 0.0, 0.3, moulure())
		boite(f, -0.38, L + 0.38, top, top + 0.1, 0.0, 0.4, moulure())
		if str(d.get("corniche", "simple")) == "consoles":
			var xc := 0.45
			while xc < L - 0.3:
				boite(f, xc - 0.09, xc + 0.09, top - 0.62, top - 0.28, 0.0, 0.24, moulure())
				xc += 0.9
		# chaînes d'angle (harpes) : pierres alternées aux deux extrémités, sur les étages
		if bool(d.get("chaines", true)):
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
				baie(f, float(w[0]), plancher + float(w[3]), float(w[1]), float(w[2]), str(w[4]), c_volets, str(d.get("volets_style", "pleins")))
	for bal in d.get("balcons", []):
		balcon(face(r, bal[0]), float(bal[1]), float(bal[2]), float(nv[int(bal[3])]), float(bal[4]), str(bal[5]) if bal.size() > 5 else "fer")
	for la in d.get("lanternes", []):
		lanterne(face(r, la[0]), float(la[1]), h0 + float(la[2]))
	toit(r, top, float(d["toit_h"]), c_enduit, str(d.get("toit", "2p_x")), d.get("tuiles", Color(1.05, 1.0, 0.98)))
	if d.has("cheminee"):
		cheminee(d["cheminee"], top, top + float(d["toit_h"]) + 1.0)


func cheminee(c: Array, pied: float, hc: float) -> void:
	box(Vector3(c[0], (pied + hc) * 0.5, c[1]), Vector3(0.9, hc - pied, 0.7), macon("mur2", PIERRE_VILLE * 0.92, pied))
	box(Vector3(c[0], hc + 0.08, c[1]), Vector3(1.1, 0.16, 0.9), moulure())
	elements += 2


# ------------------------------------------------------------------------------------------------ baies, portes, volets
## Baie : embrasure sombre, menuiserie ou vantaux, volets, encadrement de pierre (piédroits, linteau à clef, appui).
func baie(f: Dictionary, u: float, v0: float, w: float, h: float, style: String, c_volets: Color, volets := "pleins") -> void:
	var u0 := u - w * 0.5
	var u1 := u + w * 0.5
	var v1 := v0 + h
	var sombre := plein(Color(0.07, 0.07, 0.09), 0.35)
	var pierre := moulure()
	if style == "oeil_de_boeuf":
		_oeil_de_boeuf(f, u, v0 + w * 0.5, w * 0.5)
		return
	var cintre := style in ["fenetre_cintree", "porte_cochere", "baie_cintree"]
	boite(f, u0, u1, v0, v1, 0.0, 0.02, sombre)
	if style in ["porte_deco", "devanture", "porte_cloutee", "porte_cochere"]:
		# vantail (vantaux) plein(s) de bois, planches marquées
		boite(f, u0 + 0.04, u1 - 0.04, v0, v1 - 0.04, 0.0, 0.05, bois())
		var x := u0 + 0.3
		while x < u1 - 0.2:
			boite(f, x - 0.015, x + 0.015, v0 + 0.05, v1 - 0.08, 0.0, 0.06, plein(Color(0.20, 0.14, 0.10)))
			x += 0.3
		if style == "devanture":
			boite(f, u0 - 0.1, u1 + 0.1, v1 + 0.05, v1 + 0.45, 0.0, 0.06, plein(c_volets.darkened(0.2)))      # bandeau d'enseigne
		if style in ["porte_cloutee", "porte_cochere"]:
			_clous(f, u0 + 0.12, u1 - 0.12, v0 + 0.25, v1 - 0.2)
			for hb in [v0 + 0.35, v1 - 0.45]:
				boite(f, u0 + 0.05, u0 + 0.55, hb - 0.03, hb + 0.03, 0.0, 0.07, fer())                       # pentures
				boite(f, u1 - 0.55, u1 - 0.05, hb - 0.03, hb + 0.03, 0.0, 0.07, fer())
		if style == "porte_cochere":
			boite(f, u - 0.02, u + 0.02, v0, v1, 0.0, 0.065, plein(Color(0.16, 0.11, 0.08)))                  # joint des vantaux
	elif style == "porte_vitree":
		boite(f, u0 + 0.04, u1 - 0.04, v0, v1 - 0.04, 0.0, 0.05, bois())
		boite(f, u0 + 0.14, u1 - 0.14, v0 + h * 0.42, v1 - 0.16, 0.0, 0.055, _verre())
		boite(f, u - 0.025, u + 0.025, v0 + h * 0.42, v1 - 0.16, 0.0, 0.06, bois())
		boite(f, u0 + 0.14, u1 - 0.14, v0 + 0.12, v0 + h * 0.36, 0.0, 0.06, plein(Color(0.24, 0.17, 0.11)))   # panneau bas
	elif style in ["baie", "baie_cintree"]:
		# grande baie de salle : petits bois en grille, lumière chaude derrière les carreaux
		boite(f, u0 + 0.06, u1 - 0.06, v0 + 0.06, v1 - 0.06, 0.0, 0.025, plein(Color(0.95, 0.66, 0.32), 0.6, 0.7))
		var nx := 4
		for i in range(1, nx):
			var xx := u0 + w * i / nx
			boite(f, xx - 0.025, xx + 0.025, v0, v1, 0.0, 0.05, bois())
		for j in range(1, 3):
			var yy := v0 + h * j / 3.0
			boite(f, u0, u1, yy - 0.025, yy + 0.025, 0.0, 0.05, bois())
	elif style == "vitrine":
		_vitrine(f, u0, u1, v0, v1, c_volets)
	elif style == "barreaux":
		var pts := []
		var x2 := u0 + 0.12
		while x2 < u1 - 0.05:
			pts.append(f["o"] + f["t"] * x2 + f["n"] * 0.06 + Vector3(0, (v0 + v1) * 0.5, 0))
			x2 += 0.14
		barreaux(pts, Vector3(0.03, h, 0.03), fer())
	else:
		# menuiserie : croisée (fenêtre, fenêtre cintrée), meneau seul (porte-fenêtre), aucun bois (fenêtre simple)
		if style != "fenetre_simple":
			boite(f, u - 0.03, u + 0.03, v0, v1, 0.0, 0.045, bois())
		if style in ["fenetre", "fenetre_cintree"]:
			boite(f, u0, u1, v0 + h * 0.62 - 0.03, v0 + h * 0.62 + 0.03, 0.0, 0.045, bois())
		if style == "fenetre_simple":
			boite(f, u0 + 0.05, u1 - 0.05, v0 + 0.05, v1 - 0.05, 0.0, 0.03, _verre())
		_volets(f, u0, u1, v0, v1, w, h, c_volets, volets)
	# encadrement
	boite(f, u0 - 0.15, u0, v0, v1, 0.0, 0.07, pierre)
	boite(f, u1, u1 + 0.15, v0, v1, 0.0, 0.07, pierre)
	if cintre:
		_arc(f, u, v1, w * 0.5)
	else:
		boite(f, u0 - 0.15, u1 + 0.15, v1, v1 + 0.2, 0.0, 0.08, pierre)
		boite(f, u - 0.1, u + 0.1, v1 - 0.02, v1 + 0.26, 0.0, 0.11, pierre)        # clef
	if v0 > 0.2 and not (style in ["porte_fenetre"] or style in PORTES):
		boite(f, u0 - 0.2, u1 + 0.2, v0 - 0.12, v0, 0.0, 0.15, pierre)       # appui


func _verre() -> StandardMaterial3D:
	return plein(Color(0.16, 0.19, 0.22), 0.18, 0.0, 0.3)


## Volets : pleins (deux barres, ouverts), persiennes (lames, ouverts), fermés (rabattus sur la baie), aucun.
func _volets(f: Dictionary, u0: float, u1: float, v0: float, v1: float, w: float, h: float, c: Color, style: String) -> void:
	if style == "aucun":
		return
	var cv := plein(c)
	var cvs := plein(c.darkened(0.25))
	if style == "fermes":
		for s in [0.0, 1.0]:
			var a0: float = u0 + 0.02 + s * w * 0.5
			var a1: float = a0 + w * 0.5 - 0.04
			boite(f, a0, a1, v0 + 0.02, v1 - 0.02, 0.0, 0.06, cv)
			for yy in [v0 + h * 0.25, v0 + h * 0.75]:
				boite(f, a0 + 0.03, a1 - 0.03, yy - 0.04, yy + 0.04, 0.0, 0.07, cvs)
		return
	for s in [-1.0, 1.0]:
		var a0: float = (u0 - 0.16 - w * 0.5) if s < 0.0 else (u1 + 0.16)
		var a1: float = a0 + w * 0.5
		boite(f, a0, a1, v0 + 0.02, v1 - 0.02, 0.0, 0.04, cv)
		if style == "persiennes":
			var pts := []
			var yy := v0 + 0.1
			while yy < v1 - 0.08:
				pts.append(point_face(f, (a0 + a1) * 0.5, yy, 0.05))
				yy += 0.11
			barreaux(pts, taille_face(f, w * 0.5 - 0.08, 0.03, 0.02), cvs)
		else:
			for yy in [v0 + h * 0.25, v0 + h * 0.75]:
				boite(f, a0 + 0.03, a1 - 0.03, yy - 0.04, yy + 0.04, 0.0, 0.05, cvs)


## Arc en plein cintre de claveaux (fenêtre cintrée, porte cochère) au-dessus des piédroits, embrasure sombre dans le cintre.
func _arc(f: Dictionary, u: float, v: float, rayon: float) -> void:
	var sombre := plein(Color(0.07, 0.07, 0.09), 0.35)
	# remplissage sombre du cintre (marches de boîtes)
	var n := 4
	for i in n:
		var y0 := v + rayon * i / n
		var hw := rayon * sqrt(maxf(0.0, 1.0 - pow(float(i + 1) / n, 2.0)))
		if hw > 0.02:
			boite(f, u - hw, u + hw, y0, y0 + rayon / n, 0.0, 0.02, sombre)
	var nc := 9
	var pierre := moulure()
	for i in nc:
		var a := PI * (i + 0.5) / nc
		var pu := u - cos(a) * (rayon + 0.1)
		var pv := v + sin(a) * (rayon + 0.1)
		var ep := 0.26 if i == nc / 2 else 0.2
		boite_tournee(f, pu, pv, PI * (rayon + 0.1) / nc + 0.03, ep, 0.0, 0.09 if i != nc / 2 else 0.12, PI * 0.5 - a, pierre)


func _oeil_de_boeuf(f: Dictionary, u: float, v: float, rayon: float) -> void:
	var sombre := plein(Color(0.07, 0.07, 0.09), 0.35)
	boite_tournee(f, u, v, rayon * 1.42, rayon * 1.42, 0.0, 0.02, PI * 0.25, sombre)
	boite(f, u - rayon * 0.7, u + rayon * 0.7, v - rayon * 0.7, v + rayon * 0.7, 0.0, 0.02, sombre)
	var nc := 10
	for i in nc:
		var a := TAU * i / nc
		boite_tournee(f, u + cos(a) * (rayon + 0.08), v + sin(a) * (rayon + 0.08), TAU * (rayon + 0.08) / nc + 0.03, 0.18, 0.0, 0.09, a + PI * 0.5, moulure())


## Clous de porte : grille de têtes de fer (un MultiMesh).
func _clous(f: Dictionary, u0: float, u1: float, v0: float, v1: float) -> void:
	var pts := []
	var v := v0
	while v <= v1:
		var u := u0
		while u <= u1:
			pts.append(point_face(f, u, v, 0.065))
			u += 0.22
		v += 0.3
	barreaux(pts, taille_face(f, 0.04, 0.04, 0.03), fer())


## Vitrine de boutique : allège de bois, grands carreaux (petits bois), intérieur chaud discret, auvent de toile rayé.
func _vitrine(f: Dictionary, u0: float, u1: float, v0: float, v1: float, c: Color) -> void:
	var bois_c := plein(Color(0.27, 0.19, 0.12))
	boite(f, u0, u1, v0, v0 + 0.6, 0.0, 0.08, bois_c)
	boite(f, u0 + 0.05, u1 - 0.05, v0 + 0.6, v1 - 0.05, 0.0, 0.03, plein(Color(0.62, 0.48, 0.30), 0.3, 0.35))
	var x := u0
	var nb := maxi(2, int((u1 - u0) / 0.6))
	for i in nb + 1:
		x = u0 + (u1 - u0) * i / nb
		boite(f, x - 0.03, x + 0.03, v0 + 0.6, v1, 0.0, 0.06, bois_c)
	boite(f, u0, u1, v0 + 0.6 + (v1 - v0 - 0.6) * 0.66 - 0.025, v0 + 0.6 + (v1 - v0 - 0.6) * 0.66 + 0.025, 0.0, 0.06, bois_c)
	boite(f, u0, u1, v1 - 0.05, v1 + 0.02, 0.0, 0.07, bois_c)
	# auvent : toile tendue en pente (rayures), lambrequin
	var n: Vector3 = f["n"]
	var t: Vector3 = f["t"]
	var prof := 1.0
	var nb_r := maxi(3, int((u1 - u0 + 0.4) / 0.35))
	for i in nb_r:
		var a := u0 - 0.2 + (u1 - u0 + 0.4) * i / nb_r
		var b := u0 - 0.2 + (u1 - u0 + 0.4) * (i + 1) / nb_r
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(b - a, 0.04, prof * 1.08)
		mi.mesh = bm
		mi.material_override = plein(c.lightened(0.25) if i % 2 == 0 else Color(0.90, 0.86, 0.78))
		var cc: Vector3 = f["o"] + t * ((a + b) * 0.5) + n * (prof * 0.5)
		cc.y = v1 + 0.55 - 0.18
		mi.basis = Basis(t, Vector3.UP, n) * Basis(Vector3(1, 0, 0), 0.38)
		mi.position = cc
		racine.add_child(mi)
		elements += 1
	boite(f, u0 - 0.2, u1 + 0.2, v1 + 0.08, v1 + 0.26, prof - 0.02, prof + 0.02, plein(c.lightened(0.1)))


## Balcon : « fer » (dalle sur consoles, garde-corps de fer — P7.6), « pierre » (balustrade pleine à balustres),
## « balconnet » (garde-corps seul devant une porte-fenêtre, sans dalle saillante).
func balcon(f: Dictionary, u0: float, u1: float, v: float, prof: float, style := "fer") -> void:
	var pierre := moulure()
	if style == "balconnet":
		boite(f, u0, u1, v - 0.1, v, 0.0, 0.25, pierre)
		boite(f, u0, u1, v + 0.92, v + 0.97, 0.2, 0.25, fer())
		var pb := []
		var xb := u0 + 0.05
		while xb < u1:
			pb.append(point_face(f, xb, v + 0.48, 0.225))
			xb += 0.12
		barreaux(pb, taille_face(f, 0.025, 0.9, 0.025), fer())
		return
	boite(f, u0, u1, v - 0.16, v, 0.0, prof, pierre)
	var x := u0 + 0.3
	while x < u1 - 0.2:
		boite(f, x - 0.1, x + 0.1, v - 0.5, v - 0.16, 0.0, prof * 0.75, pierre)
		x += 1.4
	if style == "pierre":
		boite(f, u0, u1, v + 0.82, v + 0.96, prof - 0.2, prof, pierre)                   # tablette
		boite(f, u0, u1, v, v + 0.14, prof - 0.2, prof, pierre)                          # socle
		for uu in [u0 + 0.1, u1 - 0.1]:
			boite(f, uu - 0.1, uu + 0.1, v, v + 0.82, prof - 0.2, prof, pierre)
		var pp := []
		var xp := u0 + 0.32
		while xp < u1 - 0.25:
			pp.append(point_face(f, xp, v + 0.48, prof - 0.1))
			xp += 0.22
		barreaux(pp, taille_face(f, 0.11, 0.68, 0.11), pierre)
		return
	boite(f, u0, u1, v + 0.92, v + 0.97, prof - 0.06, prof - 0.01, fer())
	boite(f, u0, u1, v + 0.12, v + 0.16, prof - 0.06, prof - 0.01, fer())
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
	barreaux(pts, Vector3(0.025, 0.8, 0.025), fer())


## Lanterne murale : potence de fer et verre chaud émissif (aucune lumière ajoutée : l'éclairage n'est pas repris).
func lanterne(f: Dictionary, u: float, v: float) -> void:
	boite(f, u - 0.03, u + 0.03, v + 0.3, v + 0.36, 0.0, 0.45, fer())
	boite(f, u - 0.12, u + 0.12, v - 0.05, v + 0.28, 0.32, 0.56, plein(Color(1.0, 0.72, 0.36), 0.6, 1.6))
	boite(f, u - 0.15, u + 0.15, v + 0.28, v + 0.34, 0.29, 0.59, fer())


# ------------------------------------------------------------------------------------------------ toitures
## Toit de tuiles canal procédurales (UV en mètres le long des versants), débord de 0,45 m.
##   2p_x : faîtage est-ouest, versant sud face à la caméra, pignons est / ouest (P7.6) ;
##   2p_y : faîtage nord-sud, pignon face à la caméra ; croupe : quatre versants ; appentis : un versant montant vers le nord.
func toit(r: Rect2, h: float, ht: float, c_enduit: Color, type := "2p_x", tuiles := Color(1.05, 1.0, 0.98)) -> void:
	match type:
		"aucun":
			return                                   # P7.9 : toit fourni par ailleurs (comparatif hybride)
		"2p_y":
			_toit_2p(r, h, ht, c_enduit, tuiles, true)
		"croupe":
			_toit_croupe(r, h, ht, tuiles)
		"appentis":
			_toit_appentis(r, h, ht, c_enduit, tuiles)
		_:
			_toit_2p(r, h, ht, c_enduit, tuiles, false)


## Versant (quadrilatère ou triangle) : bas a-b (égout), haut c-d (faîtage) ; UV u = abscisse le long de l'égout,
## v = distance remontée sur le versant (tuiles en rangs) ; les deux sens de faces (pas de face absente selon l'enroulement).
func _pan(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, nrm: Vector3) -> void:
	var axe := (b - a).normalized()
	var monte := ((d + c) * 0.5 - (a + b) * 0.5)
	monte = (monte - axe * monte.dot(axe)).normalized()
	var tris := [[a, b, c], [a, c, d]]
	for tri in tris:
		if (tri[1] - tri[0]).cross(tri[2] - tri[0]).length() < 1e-5:
			continue
		for order in [[0, 1, 2], [0, 2, 1]]:
			var flip: bool = order[1] == 2
			for i in order:
				var p: Vector3 = tri[i]
				st.set_normal(-nrm if flip else nrm)
				st.set_uv(Vector2((p - a).dot(axe), -(p - a).dot(monte)))
				st.add_vertex(p)


func _commit_tuiles(st: SurfaceTool, h: float, tuiles: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = macon("tuiles_a", tuiles, h, "maillage", false)
	racine.add_child(mi)
	elements += 1


func _toit_2p(r: Rect2, h: float, ht: float, c_enduit: Color, tuiles: Color, selon_y: bool) -> void:
	if not selon_y:
		_toit_2p_x(r, h, ht, c_enduit, tuiles)
		return
	# faîtage nord-sud : on construit le toit « selon x » d'un rectangle transposé, puis on échange x et z
	var rt := Rect2(r.position.y, r.position.x, r.size.y, r.size.x)
	var n0 := racine.get_child_count()
	_toit_2p_x(rt, h, ht, c_enduit, tuiles)
	var echange := Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(1, 0, 0))
	for i in range(n0, racine.get_child_count()):
		var n := racine.get_child(i) as Node3D
		n.transform = Transform3D(echange, Vector3.ZERO) * n.transform


## Toit à deux versants selon x : reprise exacte de la tranche P7.6 (versants, pignons à l'enduit, faîtière, rive).
func _toit_2p_x(r: Rect2, h: float, ht: float, c_enduit: Color, tuiles: Color) -> void:
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
	_commit_tuiles(st, h, tuiles)
	elements -= 1
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
	mp.material_override = enduit(c_enduit, h, h + ht)
	racine.add_child(mp)
	box(Vector3(r.get_center().x, h + ht + 0.06, ym), Vector3(r.size.x + 2.0 * dd + 0.1, 0.2, 0.34), macon("tuiles_a", Color(0.85, 0.8, 0.8), h, "monde", false))
	box(Vector3(r.get_center().x, hb - 0.08, ys - 0.03), Vector3(r.size.x + 2.0 * dd, 0.16, 0.08), plein(Color(0.26, 0.18, 0.12)))
	elements += 4


## Toit à croupes : faîtage selon le grand côté, raccourci de la demi-largeur à chaque bout ; quatre versants de tuiles.
func _toit_croupe(r: Rect2, h: float, ht: float, tuiles: Color) -> void:
	var dd := 0.45
	var R := r.grow(dd)
	var selon_x := r.size.x >= r.size.y
	var demi := (R.size.y if selon_x else R.size.x) * 0.5
	var hb := h - dd * ht / (demi - dd)
	var hf := h + ht
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(R.position.x, hb, R.end.y)
	var b := Vector3(R.end.x, hb, R.end.y)
	var c := Vector3(R.end.x, hb, R.position.y)
	var d := Vector3(R.position.x, hb, R.position.y)
	var cx := R.get_center().x
	var cy := R.get_center().y
	var f0: Vector3
	var f1: Vector3
	if selon_x:
		f0 = Vector3(R.position.x + demi, hf, cy)
		f1 = Vector3(R.end.x - demi, hf, cy)
		_pan(st, a, b, f1, f0, Vector3(0, demi, ht).normalized())             # sud
		_pan(st, c, d, f0, f1, Vector3(0, demi, -ht).normalized())            # nord
		_pan(st, b, c, f1, f1, Vector3(ht, demi, 0).normalized())             # croupe est
		_pan(st, d, a, f0, f0, Vector3(-ht, demi, 0).normalized())            # croupe ouest
	else:
		f0 = Vector3(cx, hf, R.end.y - demi)
		f1 = Vector3(cx, hf, R.position.y + demi)
		_pan(st, a, b, f0, f0, Vector3(0, demi, ht).normalized())
		_pan(st, c, d, f1, f1, Vector3(0, demi, -ht).normalized())
		_pan(st, b, c, f1, f0, Vector3(ht, demi, 0).normalized())
		_pan(st, d, a, f0, f1, Vector3(-ht, demi, 0).normalized())
	_commit_tuiles(st, h, tuiles)
	box((f0 + f1) * 0.5 + Vector3(0, 0.06, 0), Vector3(absf(f1.x - f0.x) + 0.34, 0.2, absf(f1.z - f0.z) + 0.34), macon("tuiles_a", Color(0.85, 0.8, 0.8), h, "monde", false))
	box(Vector3(cx, hb - 0.08, R.end.y - 0.03), Vector3(R.size.x, 0.16, 0.08), plein(Color(0.26, 0.18, 0.12)))
	elements += 2


## Appentis : un versant montant du sud (égout, face caméra) vers le nord (mur haut) ; joues triangulaires à l'enduit.
func _toit_appentis(r: Rect2, h: float, ht: float, c_enduit: Color, tuiles: Color) -> void:
	var dd := 0.45
	var R := r.grow(dd)
	var hb := h - dd * ht / r.size.y
	var hn := h + ht + dd * ht / r.size.y
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_pan(st, Vector3(R.position.x, hb, R.end.y), Vector3(R.end.x, hb, R.end.y), Vector3(R.end.x, hn, R.position.y),
		Vector3(R.position.x, hn, R.position.y), Vector3(0, R.size.y, ht).normalized())
	_commit_tuiles(st, h, tuiles)
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in [r.position.x, r.end.x]:
		var tri := [Vector3(x, h, r.end.y), Vector3(x, h, r.position.y), Vector3(x, h + ht, r.position.y)]
		for order in [[0, 1, 2], [0, 2, 1]]:
			for i in order:
				st2.set_normal(Vector3(1 if x > r.get_center().x else -1, 0, 0) * (1.0 if order[1] == 1 else -1.0))
				st2.add_vertex(tri[i])
	var mp := MeshInstance3D.new()
	mp.mesh = st2.commit()
	mp.material_override = enduit(c_enduit, h, h + ht)
	racine.add_child(mp)
	box(Vector3(r.get_center().x, h + ht * 0.5, r.position.y + 0.1), Vector3(r.size.x, ht, 0.2), enduit(c_enduit, h, h + ht))   # mur haut
	box(Vector3(r.get_center().x, hb - 0.08, R.end.y - 0.03), Vector3(R.size.x, 0.16, 0.08), plein(Color(0.26, 0.18, 0.12)))
	elements += 3


# ------------------------------------------------------------------------------------------------ jardinière
## Jardinière plantée sur un muret (P7.7, remplace la haie uniforme de P7.6) : terre, touffes d'arbustes de tailles et de
## verts variés (sphères aplaties, un MultiMesh coloré), fleurs en taches (lavande, ocre, blanc), deux pots de terre
## cuite et une lisière de pierres. Hauteur ≤ 0,8 m : le muret reste bas côté caméra. Tirage déterministe (position).
func jardiniere(r: Rect2, h: float) -> void:
	var ri := r.grow(-0.45)
	box(centre(ri, h - 0.02, h + 0.03), Vector3(ri.size.x, 0.05, ri.size.y), plein(Color(0.29, 0.24, 0.18)))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x * 131.0 + r.position.y * 17.0)
	var verts := [Color(0.32, 0.44, 0.22), Color(0.38, 0.50, 0.25), Color(0.44, 0.52, 0.28), Color(0.28, 0.40, 0.22), Color(0.48, 0.54, 0.32)]
	var touffes := []
	# couvre-sol bas et continu (la terre ne se voit plus qu'entre les touffes)
	var xs := ri.position.x + 0.4
	while xs < ri.end.x - 0.3:
		touffes.append([Vector3(xs, h + 0.08, ri.position.y + rng.randf_range(0.7, 1.5)), Vector3(rng.randf_range(1.0, 1.5), 0.22, rng.randf_range(1.0, 1.6)),
			Color(0.30, 0.40, 0.21).lerp(Color(0.38, 0.46, 0.25), rng.randf())])
		xs += rng.randf_range(0.8, 1.1)
	var x := ri.position.x + 0.35
	while x < ri.end.x - 0.3:
		# deux rangs qui se chevauchent : le rang côté rue (nord) plus fourni
		for rang in [0, 1]:
			if rang == 1 and rng.randf() < 0.25:
				continue
			var y: float = ri.position.y + 0.55 + rang * 1.0 + rng.randf_range(-0.2, 0.2)
			var s := rng.randf_range(0.8, 1.3) * (1.0 if rang == 0 else 0.85)
			var ht := rng.randf_range(0.45, 0.78) * (1.0 if rang == 0 else 0.85)
			touffes.append([Vector3(x + rng.randf_range(-0.15, 0.15), h + ht * 0.45, y), Vector3(s, ht, s * rng.randf_range(0.8, 1.2)), verts[rng.randi() % verts.size()]])
		x += rng.randf_range(0.45, 0.75)
	_spheres(touffes, 0.85)
	var fleurs := []
	var couleurs_f := [Color(0.55, 0.45, 0.70), Color(0.84, 0.66, 0.28), Color(0.92, 0.90, 0.84), Color(0.72, 0.34, 0.30)]
	for i in int(ri.size.x / 2.4):
		var c: Color = couleurs_f[rng.randi() % couleurs_f.size()]
		var fx := ri.position.x + rng.randf_range(0.3, ri.size.x - 0.3)
		var fy := ri.position.y + rng.randf_range(0.35, 0.8)
		for k in 5:
			fleurs.append([Vector3(fx + rng.randf_range(-0.3, 0.3), h + rng.randf_range(0.6, 0.78), fy + rng.randf_range(-0.18, 0.18)), Vector3(0.2, 0.14, 0.2), c])
	# pots de terre cuite (plante ronde au-dessus : ajoutée aux fleurs)
	for px in [ri.position.x + ri.size.x * 0.27, ri.position.x + ri.size.x * 0.71]:
		fleurs.append([Vector3(px, h + 0.68, ri.position.y + 0.4), Vector3(0.7, 0.5, 0.7), Color(0.34, 0.46, 0.24)])
	_spheres(fleurs, 0.7)
	for px in [ri.position.x + ri.size.x * 0.27, ri.position.x + ri.size.x * 0.71]:
		var p := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.32
		cm.bottom_radius = 0.24
		cm.height = 0.5
		cm.radial_segments = 12
		p.mesh = cm
		p.material_override = plein(Color(0.62, 0.36, 0.24))
		p.position = Vector3(px, h + 0.25, ri.position.y + 0.4)
		racine.add_child(p)
		elements += 1
	# lisière de pierres le long du bord nord
	box(Vector3(ri.get_center().x, h + 0.06, ri.position.y + 0.06), Vector3(ri.size.x, 0.12, 0.12), macon("socle2", PIERRE_VILLE, h))
	elements += 2


## Sphères aplaties colorées (touffes, fleurs) : un seul MultiMesh, couleur par instance.
func _spheres(liste: Array, rugosite: float) -> void:
	if liste.is_empty():
		return
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 10
	sm.rings = 5
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = sm
	mm.instance_count = liste.size()
	for i in liste.size():
		var e: Array = liste[i]
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(e[1]), e[0]))
		mm.set_instance_color(i, e[2])
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = rugosite
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = m
	racine.add_child(mi)
	elements += 1


# ------------------------------------------------------------------------------------------------ fusion
## P7.7 : FUSION PAR MATIÈRE des maillages statiques ajoutés depuis l'index `depuis` de la racine (boîtes et maillages
## construits ; les MultiMesh restent tels quels). Rendu identique, un appel de dessin par matière et par élément au lieu
## d'un par pièce (profilage : la tranche P7.6 multipliait les appels de dessin par 2,4). --fusion=0 : sans fusion.
var fusion := true


func fusionner(depuis: int, nom := "fusion") -> void:
	if not fusion:
		return
	var groupes := {}
	var a_retirer := []
	for i in range(depuis, racine.get_child_count()):
		var n := racine.get_child(i)
		if not (n is MeshInstance3D):
			continue
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi.material_override == null or mi.get_child_count() > 0:
			continue
		var k := mi.material_override.get_instance_id() * 2 + (1 if mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else 0)
		if not groupes.has(k):
			groupes[k] = {"mat": mi.material_override, "ombre": mi.cast_shadow, "items": []}
		groupes[k]["items"].append(mi)
	for k in groupes:
		var g: Dictionary = groupes[k]
		if g["items"].size() < 2:
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for mi in g["items"]:
			var m: Mesh = (mi as MeshInstance3D).mesh
			for s in m.get_surface_count():
				st.append_from(m, s, (mi as MeshInstance3D).transform)
			a_retirer.append(mi)
		var out := MeshInstance3D.new()
		out.name = nom
		out.mesh = st.commit()
		out.material_override = g["mat"]
		out.cast_shadow = g["ombre"]
		racine.add_child(out)
	for mi in a_retirer:
		racine.remove_child(mi)
		(mi as Node).queue_free()
