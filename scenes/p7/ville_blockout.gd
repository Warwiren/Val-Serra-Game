extends RefCounted
## P7.1 — BLOCKOUT V0.1 du quartier central (plan directeur V0.5). PROTOTYPE DE CIRCULATION, NON VALIDÉ.
## Construit l'affichage de la zone « ville » (data/p7/ville_v05.json, généré par tools/p7/build_ville_v05.py) à la
## place de l'habillage du Colisée : volumes neutres colorés par fonction (src/p7/blockout_p7.gdshader : quadrillage
## d'1 m, lignes d'étage, baies schématiques), sols teintés par niveau, libellés temporaires des bâtiments importants.
## Les collisions viennent des DONNÉES (le socle World25 et les corps statiques correspondants) : rien de visible n'est
## traversable, rien d'invisible ne bloque (les limites sont des remparts et des portes dessinés).

const SH := preload("res://src/p7/blockout_p7.gdshader")
## couleurs des fonctions (reprises du plan V0.5, désaturées : repères de lecture, pas une direction artistique)
const COULEURS := {
	"residentiel": Color(0.70, 0.67, 0.62), "residentiel_b": Color(0.64, 0.66, 0.65),
	"civique": Color(0.60, 0.67, 0.60), "guilde": Color(0.42, 0.58, 0.72), "forge": Color(0.78, 0.55, 0.36),
	"commerce": Color(0.80, 0.62, 0.42), "auberge": Color(0.70, 0.50, 0.44), "accueil": Color(0.58, 0.66, 0.60),
	"rempart": Color(0.52, 0.52, 0.50), "colisee": Color(0.74, 0.64, 0.50), "etal": Color(0.66, 0.50, 0.34),
}
const SOL := {0.0: Color(0.47, 0.44, 0.40), 1.0: Color(0.53, 0.50, 0.45), 2.0: Color(0.57, 0.55, 0.51)}

var sc
var v: Dictionary
var _mats := {}


func _init(scene) -> void:
	sc = scene
	v = sc._p6.get("ville", {})


func mat(c: Color, grille := 0.0, facade := 0.0, base_y := 0.0, hole := false) -> ShaderMaterial:
	var k := "%s|%s|%s|%s|%s" % [c, grille, facade, base_y, hole]
	if _mats.has(k):
		return _mats[k]
	var m := ShaderMaterial.new()
	m.shader = SH
	m.set_shader_parameter("couleur", c)
	m.set_shader_parameter("grille", grille)
	m.set_shader_parameter("facade", facade)
	m.set_shader_parameter("base_y", base_y)
	m.set_shader_parameter("hole", 1.0 if hole else 0.0)
	_mats[k] = m
	return m


## Élément des données : true s'il est pris en charge ici (sinon la scène le construit comme d'habitude).
func construit(e: Dictionary) -> bool:
	var id: String = e.get("id", "")
	match e["type"]:
		"floor":
			var r: Rect2 = e["rect"]
			if e["role"] == "decor":
				var c := Vector3(r.get_center().x, e["h"] - 0.17, r.get_center().y)
				var size := Vector3(r.size.x + 80.0, 0.3, r.size.y + 80.0)
				sc._static_box(c, size, sc.L_NOWALK)
				var mi: MeshInstance3D = sc._box_mesh(c - Vector3(0, 0.02, 0), size, mat(Color(0.36, 0.40, 0.33)))
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				return true
			var th := 0.3
			sc._static_box(sc._rect_center(r, e["h"] - th, e["h"]), Vector3(r.size.x, th, r.size.y), sc.L_FLOOR)
			sc._box_mesh(sc._rect_center(r, e["h"] - th, e["h"]), Vector3(r.size.x, th, r.size.y), mat(SOL.get(snappedf(e["h"], 1.0), SOL[0.0]), 1.0))
			return true
		"block":
			var r: Rect2 = e["rect"]
			var h0: float = e["h0"]
			var h1: float = e["h1"]
			var size := Vector3(r.size.x, h1 - h0, r.size.y)
			if e.get("role", "") == "terrasse":
				# terrasse : dessus praticable, faces = murs de soutènement (pierre sombre)
				sc._static_box(sc._rect_center(r, h0, h1), size, sc.L_FLOOR)
				sc._box_mesh(sc._rect_center(r, h0, h1 - 0.02), Vector3(r.size.x, h1 - h0 - 0.02, r.size.y), mat(Color(0.50, 0.49, 0.46), 0.0, 0.0, h0))
				sc._box_mesh(sc._rect_center(r, h1 - 0.02, h1), Vector3(r.size.x, 0.02, r.size.y), mat(SOL.get(snappedf(h1, 1.0), SOL[1.0]), 1.0))
				return true
			if id.begins_with("colisee_tranche_"):
				sc._static_box(sc._rect_center(r, h0, h1), size, sc.L_OBST)     # enceinte : collision seule (tambour dessiné à part)
				return true
			var cat := "residentiel"
			var facade := 1.0
			if id.begins_with("bat_"):
				cat = str(v.get("batiments", {}).get(id, {}).get("categorie", "residentiel"))
			elif id.begins_with("rempart_") or id.begins_with("tour_"):
				cat = "rempart"
				facade = 0.0
			elif id.begins_with("etal_"):
				cat = "etal"
				facade = 0.0
			elif id == "fontaine":
				sc._static_box(sc._rect_center(r, h0, h1), size, sc.L_OBST)
				_fontaine(r, h0)
				return true
			elif id.begins_with("barriere"):
				sc._static_box(sc._rect_center(r, h0, h1), size, sc.L_OBST)
				var b: MeshInstance3D = sc._box_mesh(sc._rect_center(r, h0, h1), size, mat(Color(0.85, 0.62, 0.2)))
				b.name = "barriere_fin_de_carte"
				return true
			sc._static_box(sc._rect_center(r, h0, h1), size, sc.L_OBST)
			if id.begins_with("rempart_sud") or id.begins_with("tour_sud"):
				# mur face à la caméra (convention des intérieurs du Colisée) : dessiné en muret de 1,6 m avec une tranche
				# sombre ; collision des données (8 à 11 m) inchangée. Sinon il masque toute l'arrivée sud.
				var hc := h0 + 1.6
				sc._box_mesh(sc._rect_center(r, h0, hc), Vector3(r.size.x, hc - h0, r.size.y), mat(COULEURS["rempart"]))
				sc._box_mesh(sc._rect_center(r.grow(0.05), hc, hc + 0.08), Vector3(r.size.x + 0.1, 0.08, r.size.y + 0.1), mat(Color(0.12, 0.11, 0.1)))
				return true
			var mi2: MeshInstance3D = sc._box_mesh(sc._rect_center(r, h0, h1), size, mat(COULEURS.get(cat, COULEURS["residentiel"]), 0.0, facade, h0, true))
			mi2.name = id
			if id.begins_with("etal_"):
				# auvent de toile au-dessus de l'étal (repère du marché)
				sc._box_mesh(sc._rect_center(r.grow(0.3), h1 + 0.25, h1 + 0.35), Vector3(r.size.x + 0.6, 0.1, r.size.y + 0.6), mat(Color(0.78, 0.36, 0.3)))
			var lib: String = str(v.get("batiments", {}).get(id, {}).get("libelle", ""))
			if lib != "":
				_libelle(lib, Vector3(r.get_center().x, h1 + 1.6, r.get_center().y))
			return true
	return false


## Décor propre au blockout : tambour du Colisée, sols des espaces publics, silhouette du château, libellés des accès.
func decorer() -> void:
	_colisee()
	var pz := {"place": Color(0.60, 0.57, 0.50), "parvis": Color(0.58, 0.54, 0.47), "marche": Color(0.60, 0.52, 0.42),
		"avenue_haute": Color(0.61, 0.58, 0.52), "avenue_portes": Color(0.52, 0.48, 0.42), "parvis_guilde": Color(0.52, 0.54, 0.56)}
	for z in sc._p6.get("zones_nommees", []):
		if not pz.has(z["id"]):
			continue
		var q: Array = z["rect"]
		var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
		var h := _niveau(r.get_center().y)
		var mi: MeshInstance3D = sc._box_mesh(sc._rect_center(r, h, h + 0.012), Vector3(r.size.x, 0.012, r.size.y), mat(pz[z["id"]], 1.0))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# château (au-delà du rempart nord, décor seul) : masse et tours, porte fermée au bout de l'avenue haute
	var pierre := mat(Color(0.58, 0.58, 0.60), 0.0, 1.0, 2.0)
	sc._box_mesh(Vector3(108.5, 2.0 + 11.0, -16.0), Vector3(46.0, 22.0, 20.0), pierre)
	for x in [84.0, 133.0]:
		sc._box_mesh(Vector3(x, 2.0 + 14.0, -12.0), Vector3(7.0, 28.0, 7.0), pierre)
	sc._box_mesh(Vector3(108.5, 2.0 + 17.0, -22.0), Vector3(14.0, 34.0, 12.0), pierre)
	_libelle("Château — accès fermé", Vector3(108.5, 2.0 + 7.0, 3.5))
	_libelle("Quartier est — accès fermé", Vector3(186.0, 1.0 + 6.0, 69.0))
	_libelle("Porte sud — sortie (transition à relier)", Vector3(108.5, 3.0, 160.5))
	_libelle("Grande place", Vector3(108.5, 1.0 + 5.0, 48.5))
	_libelle("Marché", Vector3(108.5, 1.0 + 4.0, 84.0))
	# porte sud : vantaux ouverts contre les tours (passage libre jusqu'à la barrière de fin de carte)
	var bois := mat(Color(0.45, 0.33, 0.24))
	for x in [104.25, 112.75]:
		sc._box_mesh(Vector3(x, 0.8, 157.2), Vector3(0.3, 1.6, 3.0), bois)      # vantaux ouverts (coupés comme le rempart)


func _niveau(y: float) -> float:
	var nv: Dictionary = v.get("niveaux", {})
	if y < float(nv.get("nord", [0, 24])[1]) + 3.0:
		return 2.0
	if y < float(nv.get("centre", [27, 101])[1]) + 3.0:
		return 1.0
	return 0.0


func _colisee() -> void:
	var cd: Dictionary = v.get("colisee", {})
	if cd.is_empty():
		return
	var c := Vector2(cd["centre"][0], cd["centre"][1])
	var rr := Vector2(cd["rayons"][0], cd["rayons"][1])
	var h0: float = cd["h"]
	var haut: float = cd["haut"]
	var cy := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = haut
	cm.radial_segments = 72
	cm.rings = 1
	cy.mesh = cm
	cy.scale = Vector3(rr.x, 1.0, rr.y)
	cy.position = Vector3(c.x, h0 + haut * 0.5, c.y)
	cy.material_override = mat(COULEURS["colisee"], 0.0, 1.0, h0, true)
	cy.name = "Colisee_enceinte"
	sc.root.add_child(cy)
	# couronnement un peu plus clair (lecture du volume) et vestibule de l'entrée publique (est)
	var cr := MeshInstance3D.new()
	var cm2 := CylinderMesh.new()
	cm2.top_radius = 1.0
	cm2.bottom_radius = 1.0
	cm2.height = 0.6
	cm2.radial_segments = 72
	cr.mesh = cm2
	cr.scale = Vector3(rr.x + 0.4, 1.0, rr.y + 0.4)
	cr.position = Vector3(c.x, h0 + haut + 0.3, c.y)
	cr.material_override = mat(Color(0.82, 0.74, 0.60))
	sc.root.add_child(cr)
	var vb: Array = cd.get("vestibule", [])
	if vb.size() == 4:
		var r := Rect2(vb[0], vb[1], vb[2] - vb[0], vb[3] - vb[1])
		# baie sombre du vestibule, encadrement et linteau de l'entrée publique
		sc._box_mesh(sc._rect_center(r.grow_individual(0, 0, 0.35, 0), h0, h0 + 5.0), Vector3(r.size.x + 0.35, 5.0, r.size.y), mat(Color(0.12, 0.11, 0.1)))
		for y in [r.position.y - 0.6, r.end.y + 0.6]:
			sc._box_mesh(Vector3(r.end.x + 0.2, h0 + 3.2, y), Vector3(1.0, 6.4, 1.2), mat(Color(0.82, 0.74, 0.60)))
		sc._box_mesh(Vector3(r.end.x + 0.2, h0 + 6.0, r.get_center().y), Vector3(1.0, 1.0, r.size.y + 2.4), mat(Color(0.82, 0.74, 0.60)))
	_libelle("Colisée — entrée publique", Vector3(cd["porte"][0] + 2.0, h0 + 8.0, cd["porte"][1]))


func _fontaine(r: Rect2, h0: float) -> void:
	var c := r.get_center()
	var bassin := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r.size.x * 0.5
	cm.bottom_radius = r.size.x * 0.5
	cm.height = 0.9
	bassin.mesh = cm
	bassin.position = Vector3(c.x, h0 + 0.45, c.y)
	bassin.material_override = mat(Color(0.74, 0.72, 0.68))
	sc.root.add_child(bassin)
	var eau := MeshInstance3D.new()
	var cm2 := CylinderMesh.new()
	cm2.top_radius = r.size.x * 0.5 - 0.35
	cm2.bottom_radius = r.size.x * 0.5 - 0.35
	cm2.height = 0.05
	eau.mesh = cm2
	eau.position = Vector3(c.x, h0 + 0.88, c.y)
	eau.material_override = mat(Color(0.35, 0.55, 0.66))
	sc.root.add_child(eau)
	var col := MeshInstance3D.new()
	var cm3 := CylinderMesh.new()
	cm3.top_radius = 0.5
	cm3.bottom_radius = 0.8
	cm3.height = 4.0
	col.mesh = cm3
	col.position = Vector3(c.x, h0 + 2.0, c.y)
	col.material_override = mat(Color(0.80, 0.78, 0.72))
	sc.root.add_child(col)


func _libelle(texte: String, p: Vector3) -> void:
	var l := Label3D.new()
	l.text = texte
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0011
	l.font_size = 26
	l.outline_size = 8
	l.modulate = Color(1.0, 0.97, 0.88)
	l.outline_modulate = Color(0.1, 0.09, 0.08)
	l.position = p
	l.name = "Libelle_" + texte.left(24)
	sc.root.add_child(l)
