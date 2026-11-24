extends "res://scenes/p7/ville_v07a.gd"
## P7.5 — VILLE V0.7-B : reconstruction compacte du quartier central. BLOCKOUT CONSOLIDÉ, NON VALIDÉ.
## Données : data/p7/ville_v07b.json (tools/p7/build_ville_v07b.py). Reprend tout le vocabulaire de la V0.7-A (masses,
## toits, Colisée, propylée, porte, château, ambiance) et ajoute :
##   * les obstacles « crédibles » des accès futurs : caravane (faubourgs ouest), guérites et gardes (château) ;
##     le chantier du quartier est vient de la V0.7-A ;
##   * des prolongements visuels NON praticables : escaliers qui montent vers des secteurs inaccessibles, arches au-dessus
##     de rues lointaines, tours à mi-distance.

const BOIS_CARAVANE := Color(0.46, 0.33, 0.22)
const TOILE := Color(0.82, 0.76, 0.62)


func construit(e: Dictionary) -> bool:
	var id := str(e.get("id", ""))
	if e["type"] == "block" and id.begins_with("decor_"):
		var r: Rect2 = e["rect"]
		var h0: float = e["h0"]
		var h1: float = e["h1"]
		sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_OBST)
		if id == "decor_caravane":
			_caravane(r, h0)
		elif id.begins_with("decor_guerite"):
			_guerite(r, h0)
		elif id.begins_with("decor_garde"):
			_garde(r, h0)
		return true
	return super(e)


func decorer() -> void:
	super()
	for s in v.get("decor_escaliers", []):
		_escalier_decor(s)
	for a in v.get("decor_arches", []):
		_arche_decor(a)
	for tr in v.get("decor_tours", []):
		_tour_decor(tr)
	_libelle("Faubourgs — passage bloqué", Vector3(-14.0, 3.5 + 4.0, 96.0))
	_libelle("Quartier du château — accès gardé", Vector3(70.0, 8.0 + 5.0, 41.0))


## Caravane (B) : plateau, roues, bâche, caisses ; timon vers l'ouest (elle vient des faubourgs).
func _caravane(r: Rect2, h0: float) -> void:
	var bois := mat(BOIS_CARAVANE)
	var c := r.get_center()
	sc._box_mesh(Vector3(c.x, h0 + 0.9, c.y), Vector3(r.size.x, 0.25, r.size.y - 0.6), bois)
	for dy in [-r.size.y * 0.32, r.size.y * 0.32]:
		for dx in [-r.size.x * 0.5, r.size.x * 0.5]:
			var roue := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.55
			cm.bottom_radius = 0.55
			cm.height = 0.15
			cm.radial_segments = 16
			roue.mesh = cm
			roue.rotation = Vector3(0, 0, PI * 0.5)
			roue.position = Vector3(c.x + dx, h0 + 0.55, c.y + dy)
			roue.material_override = mat(BOIS_CARAVANE.darkened(0.3))
			sc.root.add_child(roue)
	# bâche en demi-cylindre (boîte arrondie approchée) et caisses
	var b := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = r.size.x * 0.48
	bc.bottom_radius = r.size.x * 0.48
	bc.height = r.size.y - 1.4
	bc.radial_segments = 20
	b.mesh = bc
	b.rotation = Vector3(PI * 0.5, 0, 0)
	b.position = Vector3(c.x, h0 + 1.05, c.y)
	b.material_override = mat(TOILE)
	sc.root.add_child(b)
	for k in 3:
		sc._box_mesh(Vector3(c.x + 2.6 + (k % 2) * 0.4, h0 + 0.35 + (k / 2) * 0.7, c.y - 1.5 + k * 1.2), Vector3(0.7, 0.7, 0.7), bois)
	sc._box_mesh(Vector3(r.position.x - 1.2, h0 + 0.55, c.y), Vector3(2.4, 0.12, 0.12), bois)


## Guérite (C) : petite loge de pierre à toit de tuiles, ouverte vers l'avenue.
func _guerite(r: Rect2, h0: float) -> void:
	sc._box_mesh(sc._rect_center(r, h0, h0 + 2.6), Vector3(r.size.x, 2.6, r.size.y), mat(Color(0.70, 0.67, 0.62), 0.0, 0.0, h0))
	_toit(r, h0 + 2.6, "2p", 3)


## Garde (C) : sprite du garde en armure (art/p45/chars/garde), face au visiteur, posé sur une ombre de contact.
func _garde(r: Rect2, h0: float) -> void:
	var tex: Texture2D = load("res://art/p45/chars/garde/idle_face.png")
	if tex == null:
		return
	var spr := Sprite3D.new()
	spr.texture = tex
	spr.pixel_size = 0.025                      # ≈ 1,9 m pour un sprite de 75 px
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.offset = Vector2(0, tex.get_height() * 0.5)
	spr.position = Vector3(r.get_center().x, h0, r.get_center().y)
	sc.root.add_child(spr)


## Escalier de décor : [x0, x1, y_haut, longueur, h_bas, h_haut] ; marches visibles, palier haut, joues ; aucune collision
## (il est hors d'atteinte : au-delà des fronts bâtis).
func _escalier_decor(sp: Array) -> void:
	var x0: float = sp[0]
	var x1: float = sp[1]
	var yh: float = sp[2]
	var L: float = sp[3]
	var hb: float = sp[4]
	var ht: float = sp[5]
	var n := int(ceilf((ht - hb) / 0.3))
	var m := mat(MARCHE.darkened(0.06), 0.0, 0.0, hb)
	for i in n:
		var top := hb + (ht - hb) * (i + 1) / n
		var y1 := yh + L - L * i / n
		var y0 := yh + L - L * (i + 1) / n
		sc._box_mesh(Vector3((x0 + x1) * 0.5, (hb + top) * 0.5, (y0 + y1) * 0.5), Vector3(x1 - x0, top - hb, y1 - y0), m)
	sc._box_mesh(Vector3((x0 + x1) * 0.5, (hb + ht) * 0.5, yh - 2.0), Vector3(x1 - x0, ht - hb, 4.0), m)
	for xj in [x0 - 0.3, x1 + 0.3]:
		sc._box_mesh(Vector3(xj, (hb + ht) * 0.5 + 0.4, yh + L * 0.5 - 1.0), Vector3(0.6, ht - hb + 0.8, L + 2.0), mat(MUR_SOUT.lightened(0.05)))


## Arche de décor au-dessus d'une rue lointaine : [x, y, ouverture, pied, axe].
func _arche_decor(a: Array) -> void:
	var c := Vector3(float(a[0]), float(a[3]), float(a[1]))
	var R := float(a[2]) * 0.5
	_arche(c, str(a[4]), R, 3.4, 3.4 + R + 2.4, 1.4, mat(CALCAIRE.darkened(0.08), 0.0, 0.0, float(a[3])), mat(CALCAIRE))
	for s in [-1.0, 1.0]:
		var p := c + (Vector3(s * (R + 0.8), 0, 0) if str(a[4]) == "x" else Vector3(0, 0, s * (R + 0.8)))
		sc._box_mesh(p + Vector3(0, (3.4 + R + 2.4) * 0.5, 0), Vector3(1.6, 3.4 + R + 2.4, 1.6), mat(CALCAIRE.darkened(0.08)))


## Tour à mi-distance : [x, y, pied, hauteur] ; flèche d'ardoise.
func _tour_decor(tr: Array) -> void:
	var x: float = tr[0]
	var y: float = tr[1]
	var h0: float = tr[2]
	var ht: float = tr[3]
	sc._box_mesh(Vector3(x, h0 + ht * 0.5, y), Vector3(6.0, ht, 6.0), mat(Color(0.64, 0.62, 0.60), 0.0, 1.0, h0))
	_creneaux(Rect2(x - 3.0, y - 3.0, 6.0, 6.0), h0 + ht, Color(0.64, 0.62, 0.60))
	_cone(Vector3(x, h0 + ht, y), 4.4, 8.0, Color(0.34, 0.36, 0.42))
