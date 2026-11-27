extends RefCounted
## P7.1 — BLOCKOUT V0.1 du quartier central (plan directeur V0.5). PROTOTYPE DE CIRCULATION, NON VALIDÉ.
## P8.0-C : BASE DE LA CHAÎNE D'HÉRITAGE de la ville (ville_blockout -> ville_v06 -> ville_v07a -> ville_v07b, seule version
## jouée) ; ses données V0.5 et son décor propre sont retirés (historique Git, commit 588e90c). Description d'origine :
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


## Décor propre à la ville : défini par les versions dérivées (ville_v07a.decorer, puis ville_v07b.decorer).
## P8.0-C : le décor du blockout V0.1 (plan V0.5, version retirée) est dans l'historique Git (commit 588e90c).
func decorer() -> void:
	pass


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
