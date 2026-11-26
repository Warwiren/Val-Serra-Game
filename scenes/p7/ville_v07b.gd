extends "res://scenes/p7/ville_v07a.gd"
## P7.5 — VILLE V0.7-B : reconstruction compacte du quartier central. BLOCKOUT CONSOLIDÉ, NON VALIDÉ.
## Données : data/p7/ville_v07b.json (tools/p7/build_ville_v07b.py). Reprend tout le vocabulaire de la V0.7-A (masses,
## toits, Colisée, propylée, porte, château, ambiance) et ajoute :
##   * les obstacles « crédibles » des accès futurs : caravane (faubourgs ouest), guérites et gardes (château) ;
##     le chantier du quartier est vient de la V0.7-A ;
##   * des prolongements visuels NON praticables : escaliers qui montent vers des secteurs inaccessibles, arches au-dessus
##     de rues lointaines, tours à mi-distance.

const Tranche := preload("res://scenes/p7/tranche_p76.gd")
const BOIS_CARAVANE := Color(0.46, 0.33, 0.22)
var tr                                    # P7.6 : tranche architecturale (scenes/p7/tranche_p76.gd)


func _tr():
	if tr == null:
		tr = Tranche.new(self)
	return tr


const Forge := preload("res://scenes/p7/forge_p79.gd")
const Boutique := preload("res://scenes/p7/boutique_p710.gd")
const Boutique711 := preload("res://scenes/p7/boutique_p711.gd")
const Civique := preload("res://scenes/p7/civique_p712.gd")
var ci                                    # P7.12 : quartier civique et porte du château (scenes/p7/civique_p712.gd)


func _civ():
	if ci == null:
		ci = Civique.new(sc, self, _tr().a, _forge())
	return ci
var bo                                    # P7.10 : boutique de fournitures (scenes/p7/boutique_p710.gd)
var fo                                    # P7.9 : comparatif de la forge (scenes/p7/forge_p79.gd)


## Boutique : P7.11 par défaut (scenes/p7/boutique_p711.gd) ; « 710 » = version P7.10 (comparaison avant / après, option
## --boutique=710 ou métadonnée boutique_variante de la scène) ; --boutique=0 : blockout. Active avec la forge C ou D.
func _boutique():
	if bo == null and _forge().variante in ["C", "D"]:
		var meta := str(sc.get_meta("boutique_variante", "711")) if sc.has_meta("boutique_variante") else "711"
		var choix := str(sc._cli.get("boutique", meta))
		if choix == "710":
			var b = Boutique.new(sc, _tr().a, _forge())
			if b.actif:
				bo = b
		elif choix != "0":
			bo = Boutique711.new(sc, _tr().a, _forge())
	return bo


func _forge():
	if fo == null:
		fo = Forge.new(sc, _tr().a, Forge.lire_variante(sc))
	return fo


const Place := preload("res://scenes/p7/place_p78.gd")
var pl                                    # P7.8 : grande place, lot 1 (scenes/p7/place_p78.gd)


func _place():
	if pl == null:
		pl = Place.new(sc, _tr().a)
	return pl


## P7.8 : la fontaine de la grande place est dessinée par le lot 1 (sinon : fontaine du blockout).
func _fontaine_v06() -> void:
	if _place().actif():
		return
	super()
const TOILE := Color(0.82, 0.76, 0.62)


func construit(e: Dictionary) -> bool:
	var id := str(e.get("id", ""))
	# P7.12 : quartier civique (terrasses, socles, garde-corps, administration ; collisions des données)
	if e["type"] == "block" and _civ().gere(id):
		_civ().construit(e)
		var lib0: String = str(v.get("batiments", {}).get(id, {}).get("libelle", ""))
		if lib0 != "":
			var r0: Rect2 = e["rect"]
			_libelle(lib0, Vector3(r0.get_center().x, float(e["h1"]) + 5.0, r0.get_center().y))
		return true
	# P7.6 : tranche architecturale (bâtiments, sols ; l'escalier passe par _escalier). Collisions : celles des données.
	if e["type"] == "block" and id == "bat_b_e_placette" and _tr().actif():
		# P7.6 : muret bas au sud de la rue du chantier (bord de la tranche, côté caméra) : pierre et chaperon
		var rm: Rect2 = e["rect"]
		sc._static_box(sc._rect_center(rm, e["h0"], e["h1"]), Vector3(rm.size.x, e["h1"] - e["h0"], rm.size.y), sc.L_OBST)
		_tr().muret(rm, e["h0"], e["h1"])
		return true
	# P7.8 : grande place, lot 1 (revêtement et fontaine ; collision de la fontaine = prisme octogonal du bassin)
	# P7.8 : surfaces SURÉLEVÉES (bloc « terrasse » du socle) de la tranche et de la place : corps du blockout, dessus revêtu.
	# (En P7.6, le revêtement du bras est ne s'appliquait pas : seules les surfaces au sol bas passaient par « floor ».)
	if e["type"] == "block" and e.get("role", "") == "terrasse" and ((_tr().actif() and id in Tranche.SOLS) or (_place().actif() and id in Place.SOLS_SIMPLES)):
		var rt: Rect2 = e["rect"]
		sc._static_box(sc._rect_center(rt, e["h0"], e["h1"]), Vector3(rt.size.x, e["h1"] - e["h0"], rt.size.y), sc.L_FLOOR)
		sc._box_mesh(sc._rect_center(rt, e["h0"], e["h1"] - 0.3), Vector3(rt.size.x, e["h1"] - 0.3 - e["h0"], rt.size.y), mat(Color(0.50, 0.49, 0.46), 0.0, 0.0, e["h0"]))
		if id in Tranche.SOLS:
			_tr().sol(id, rt, e["h1"])
		else:
			_place().sol_simple(id, rt, e["h1"])
		return true
	if _place().actif() and e["type"] == "block" and e.get("role", "") == "terrasse" and id == Place.SOL:
		# terrasse surélevée : collision et corps du blockout (murs de soutènement), dessus = revêtement du lot 1
		var rp: Rect2 = e["rect"]
		var h0: float = e["h0"]
		var hp: float = e["h1"]
		sc._static_box(sc._rect_center(rp, h0, hp), Vector3(rp.size.x, hp - h0, rp.size.y), sc.L_FLOOR)
		sc._box_mesh(sc._rect_center(rp, h0, hp - 0.3), Vector3(rp.size.x, hp - 0.3 - h0, rp.size.y), mat(Color(0.50, 0.49, 0.46), 0.0, 0.0, h0))
		var q: Array = v.get("fontaine", [42, 96, 48, 102])
		_place().sol(rp, hp, Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]), v.get("axe_chateau", {}))
		return true
	if _place().actif() and e["type"] == "block" and id == "fontaine":
		_place().fontaine(e["rect"], e["h0"])
		return true
	# P7.9 : forge-armurerie en variante A / B / C (collision : celle des données)
	if e["type"] == "block" and id == "bat_forge_armurerie" and _forge().variante != "":
		var rf: Rect2 = e["rect"]
		sc._static_box(sc._rect_center(rf, e["h0"], e["h1"]), Vector3(rf.size.x, e["h1"] - e["h0"], rf.size.y), sc.L_OBST)
		_forge().batiment()
		_libelle("Forge-armurerie (%s)" % _forge().variante, Vector3(rf.get_center().x, e["h1"] + 4.6, rf.get_center().y))
		return true
	# P7.10 : boutique de fournitures (langage hybride ; collision : celle des données + étal)
	if e["type"] == "block" and id == "bat_boutique_fournitures" and _boutique() != null:
		var rbo: Rect2 = e["rect"]
		sc._static_box(sc._rect_center(rbo, e["h0"], e["h1"]), Vector3(rbo.size.x, e["h1"] - e["h0"], rbo.size.y), sc.L_OBST)
		_boutique().batiment()
		_libelle("Boutique de fournitures", Vector3(rbo.get_center().x, 17.0, rbo.get_center().y))
		return true
	if e["type"] == "block" and _tr().contient(id):
		var rb: Rect2 = e["rect"]
		sc._static_box(sc._rect_center(rb, e["h0"], e["h1"]), Vector3(rb.size.x, e["h1"] - e["h0"], rb.size.y), sc.L_OBST)
		_tr().batiment(id, rb, e["h0"], e["h1"])
		var lib: String = str(v.get("batiments", {}).get(id, {}).get("libelle", ""))
		if lib != "":
			_libelle(lib, Vector3(rb.get_center().x, e["h1"] + 4.6, rb.get_center().y))
		return true
	if e["type"] == "floor" and e.get("role", "") != "decor" and _tr().actif() and id in Tranche.SOLS:
		var rs: Rect2 = e["rect"]
		sc._static_box(sc._rect_center(rs, e["h"] - 0.3, e["h"]), Vector3(rs.size.x, 0.3, rs.size.y), sc.L_FLOOR)
		_tr().sol(id, rs, e["h"])
		return true
	if e["type"] == "block" and id.begins_with("decor_"):
		var r: Rect2 = e["rect"]
		var h0: float = e["h0"]
		var h1: float = e["h1"]
		sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_OBST)
		if id.begins_with("decor_entree_"):
			return true                                   # P7.6 : piédroits des entrées (dessinés par _entrees)
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
	_entrees()
	_civ().decorer()
	_classer_volumes()
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
	if _civ().actif:
		_civ().guerite(r, h0)                               # P7.12 : guérites de pierre à toit d'ardoise
		return
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


# ------------------------------------------------------------------------------------------------ P7.6 (B) entrées
const BOIS_PORTE := Color(0.30, 0.20, 0.13)
const FER := Color(0.15, 0.15, 0.16)
## Couleur et forme d'enseigne par bâtiment de service (lecture à distance, sans texte)
const ENSEIGNES := {
	"guilde": [Color(0.16, 0.24, 0.52), "banniere"],
	"auberge": [Color(0.62, 0.30, 0.14), "potence"],
	"forge": [Color(0.32, 0.32, 0.34), "potence"],
	"boutique": [Color(0.24, 0.46, 0.30), "potence"],
	"hotel": [Color(0.55, 0.14, 0.16), "banniere"],
}


func _mat_plein(c: Color, emission := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	return m


## Entrées des bâtiments (données « entrees ») : fonctionnelles = avant-corps lisible de loin ; décoratives = simple porte.
func _entrees() -> void:
	for e in v.get("entrees", []):
		if str(e["type"]) == "fonctionnelle":
			if str(e["id"]) == "forge" and _forge().variante != "" and _forge().entree():
				continue                                  # P7.9 : la variante B dessine sa propre porte
			if str(e["id"]) == "boutique" and _boutique() != null and _boutique().get_script() == Boutique711:
				continue                                  # P7.11 : devanture dessinée par la boutique (boutique_p711.gd)
			_entree_fonctionnelle(e)
			if str(e["id"]) == "forge":
				_forge().apres_entree(e)
		else:
			_porte_decorative(e)


## Entrée fonctionnelle (façade sud) : piédroits et linteau de calcaire en saillie, battants de bois ferré en retrait,
## emmarchement, imposte sombre, lanternes (verre émissif, aucune lumière ajoutée) et enseigne propre au bâtiment.
func _entree_fonctionnelle(e: Dictionary) -> void:
	var x: float = e["x"]
	var y: float = e["y"]
	var h: float = e["h"]
	var L: float = e["largeur"]
	var H: float = e["hauteur"]
	var pierre: Material = _tr().moulure() if _tr().contient(str(e["batiment"])) else mat(CALCAIRE, 0.0, 0.0, h)
	var bois := _mat_plein(BOIS_PORTE)
	var fer := _mat_plein(FER)
	# piédroits (collision : decor_entree_*), linteau et corniche
	for xc in [x - L * 0.5 - 0.225, x + L * 0.5 + 0.225]:
		sc._box_mesh(Vector3(xc, h + (H + 0.6) * 0.5, y + 0.175), Vector3(0.45, H + 0.6, 0.35), pierre)
	sc._box_mesh(Vector3(x, h + H + 0.3, y + 0.175), Vector3(L + 0.9, 0.6, 0.35), pierre)
	sc._box_mesh(Vector3(x, h + H + 0.66, y + 0.25), Vector3(L + 1.3, 0.12, 0.5), mat(CALCAIRE_CLAIR))
	# embrasure sombre (profondeur) puis battants en retrait de 0,12 m
	sc._box_mesh(Vector3(x, h + H * 0.5, y + 0.02), Vector3(L, H, 0.04), _mat_plein(Color(0.08, 0.07, 0.06)))
	for k in [-1.0, 1.0]:
		var xc: float = x + k * L * 0.25
		sc._box_mesh(Vector3(xc, h + (H - 0.5) * 0.5, y + 0.06), Vector3(L * 0.5 - 0.04, H - 0.5, 0.06), bois)
		for hb in [0.5, (H - 0.5) * 0.5, H - 1.0]:
			sc._box_mesh(Vector3(xc, h + hb, y + 0.1), Vector3(L * 0.5 - 0.1, 0.08, 0.03), fer)
		sc._box_mesh(Vector3(x + k * 0.18, h + 1.1, y + 0.11), Vector3(0.08, 0.16, 0.03), fer)          # poignées
	# emmarchement (dalle basse, franchissable) et seuil
	sc._box_mesh(Vector3(x, h + 0.04, y + 0.6), Vector3(L + 1.4, 0.08, 1.2), mat(MARCHE.lightened(0.08)))
	# lanternes de part et d'autre (verre chaud émissif, pas de lumière : l'éclairage n'est pas repris)
	for k in [-1.0, 1.0]:
		var lx: float = x + k * (L * 0.5 + 0.7)
		sc._box_mesh(Vector3(lx, h + H - 0.2, y + 0.3), Vector3(0.05, 0.05, 0.3), fer)
		sc._box_mesh(Vector3(lx, h + H - 0.45, y + 0.45), Vector3(0.22, 0.34, 0.22), _mat_plein(Color(1.0, 0.72, 0.36), 1.6))
	# enseigne (P7.10 : la forge C+ a sa propre enseigne d'armurerie)
	if str(e["id"]) == "forge" and _forge().variante == "C":
		return
	var en: Array = ENSEIGNES.get(str(e["enseigne"]), [Color(0.5, 0.5, 0.5), "potence"])
	var col: Color = en[0]
	if str(en[1]) == "banniere":
		for k in [-1.0, 1.0]:
			var bx: float = x + k * (L * 0.5 + 1.4)
			sc._box_mesh(Vector3(bx, h + H + 0.2, y + 0.08), Vector3(0.9, 2.6, 0.04), _mat_plein(col))
			sc._box_mesh(Vector3(bx, h + H + 0.3, y + 0.11), Vector3(0.36, 0.36, 0.02), _mat_plein(Color(0.85, 0.68, 0.25)))
			sc._box_mesh(Vector3(bx, h + H + 1.55, y + 0.1), Vector3(1.1, 0.07, 0.07), fer)
	else:
		# enseigne en potence au-dessus de l'entrée (perpendiculaire à la façade : lisible quand on longe la rue)
		var px: float = x + L * 0.5 + 0.45
		sc._box_mesh(Vector3(px + 0.5, h + H + 0.95, y + 0.05), Vector3(1.0, 0.07, 0.07), fer)
		sc._box_mesh(Vector3(px + 0.75, h + H + 0.45, y + 0.05), Vector3(0.75, 0.75, 0.06), _mat_plein(col))
		sc._box_mesh(Vector3(px + 0.75, h + H + 0.45, y + 0.09), Vector3(0.36, 0.36, 0.02), _mat_plein(Color(0.85, 0.68, 0.25)))


## Porte décorative : battant unique de bois sombre affleurant, petit linteau, sans saillie ni interaction.
func _porte_decorative(e: Dictionary) -> void:
	if _civ().porte_deco(e):
		return                                              # P7.12 : portes du quartier civique
	if _tr().contient(str(e["batiment"])) and _tr().rects.has(str(e["batiment"])):
		var rr: Rect2 = _tr().rects[str(e["batiment"])]
		var dt: Dictionary = Tranche.BATIMENTS[str(e["batiment"])]
		_tr().baie(_tr().face(rr, "s"), float(e["x"]) - rr.position.x, float(e["h"]), float(e["largeur"]), float(e["hauteur"]), "porte_deco", dt["volets"])
		return
	var x: float = e["x"]
	var y: float = e["y"]
	var h: float = e["h"]
	var L: float = e["largeur"]
	var H: float = e["hauteur"]
	sc._box_mesh(Vector3(x, h + H * 0.5, y + 0.03), Vector3(L, H, 0.06), _mat_plein(BOIS_PORTE.darkened(0.15)))
	sc._box_mesh(Vector3(x, h + H + 0.1, y + 0.04), Vector3(L + 0.3, 0.2, 0.08), mat(CALCAIRE.darkened(0.12)))


## P7.6 : escalier de la ruelle des Tonneliers dessiné par la tranche (pierre, murs d'échiffre) ; les autres : socle.
func _escalier(e: Dictionary) -> void:
	if str(e.get("id", "")) in Civique.VOLEES and _civ().actif:
		_tr().escalier(e)                                   # P7.12 : volées C et D en pierre (mêmes collisions)
		return
	if str(e.get("id", "")) == Tranche.ESCALIER and _tr().actif():
		_tr().escalier(e)
		return
	super(e)


## P7.6 : ESCAMOTAGE DES VOLUMES PROCHES (remplace la trame de P7.3 dans la V0.7-B). Cause confirmée des « volumes tramés » :
## la caméra (22 m derrière Aren, 5,8 m plus haut) est DANS un bâtiment ou contre lui sur un quart des points praticables
## (tools/p7/camera_volumes_p76.py) ; la trame ne les cachait qu'à moitié. Désormais, chaque volume bâti (données :
## bâtiments, décor) regroupe ses maillages (classement par emprise, comme Secteurs.classer du Colisée) ; un volume est
## masqué EN ENTIER quand la caméra est dedans ou le frôle ET qu'il se trouve entre elle et Aren (au sud d'Aren). Les
## façades latérales restent pleines ; collisions inchangées. --coupe_ville=0 : trame d'origine (comparaison).
var _vols := []
var masques := {}                       # id -> true : volumes masqués à l'instant (diagnostic, compte rendu)


func _classer_volumes() -> void:
	if not (sc.has_method("coupe_ville") and sc.coupe_ville() > 0.0):
		return
	var defs := []
	for o in sc.world.adj.get("obstacles", []):
		var oid := str(o["id"])
		if not (oid.begins_with("bat_") or oid.begins_with("tour_sud") or oid.begins_with("rempart_sud")):
			continue
		var a: Array = o["rect"]
		var r := Rect2(a[0], a[1], a[2] - a[0], a[3] - a[1])
		var h0 := float(o["h"])
		var h1 := h0 + float(o["haut"])
		var toit := 6.0 if Tranche.BATIMENTS.has(oid) else minf(clampf(minf(r.size.x, r.size.y) * 0.42, 1.4, 6.0), maxf((h1 - h0) * 0.7, 1.0))
		var top := h1 + toit
		if oid == "bat_boutique_fournitures" and bo != null and bo.get_script() == Boutique711:
			top = maxf(top, 17.5)                            # P7.11 : étages et toit au-dessus du bloc des données
		defs.append([oid, r, h0, top])
	for i in v.get("paysage", []).size():
		var p: Dictionary = v["paysage"][i]
		var q: Array = p["rect"]
		var rp := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
		defs.append(["paysage_%d" % i, rp, float(p["h"]), float(p["h"]) + float(p["haut"]) + 6.0])
	for d in defs:
		var g := Node3D.new()
		g.name = "vol_" + str(d[0])
		sc.root.add_child(g)
		_vols.append({"id": d[0], "node": g, "rect": d[1], "h0": d[2], "top": d[3], "masque": false})
	for n in sc.root.get_children():
		if not (n is GeometryInstance3D):
			continue
		var gi := n as GeometryInstance3D
		var ab: AABB = gi.global_transform * gi.get_aabb()
		if ab.size.x > 60.0 or ab.size.z > 60.0 or (ab.size.y < 0.06 and ab.size.x * ab.size.z > 4.0):
			continue
		var c := ab.get_center()
		if gi.has_meta("vol"):
			for vo in _vols:
				if str(vo["id"]) == str(gi.get_meta("vol")):
					gi.reparent(vo["node"], true)
					break
			continue
		for vo in _vols:
			var rr: Rect2 = vo["rect"]
			if rr.grow(0.7).has_point(Vector2(c.x, c.z)) and c.y >= float(vo["h0"]) - 0.3 and c.y <= float(vo["top"]) + 1.5:
				gi.reparent(vo["node"], true)
				break


func _dist_rect(r: Rect2, p: Vector2) -> float:
	var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
	var dy := maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
	return sqrt(dx * dx + dy * dy)


## P7.7 : deux modes comparés (--escamotage=net|fondu, --fondu_s=0.15). « net » (défaut, retenu) : le volume disparaît
## d'une image à l'autre. « fondu » : sa transparence d'objet (GeometryInstance3D.transparency, aucune trame) passe de 0 à 1
## en fondu_s secondes. Chaque bascule est journalisée (« P7 escamotage ») pour mesurer la stabilité.
var _t_coupes := 0.0
var bascules := 0


func coupes_camera(cam: Vector3, heros: Vector3, delta := 1.0 / 60.0) -> void:
	_t_coupes += delta
	var fondu: bool = str(sc._cli.get("escamotage", "net")) == "fondu"
	var duree := maxf(0.01, float(sc._cli.get("fondu_s", 0.15)))
	var pc := Vector2(cam.x, cam.z)
	for vo in _vols:
		var r: Rect2 = vo["rect"]
		var entre: bool = r.position.y > heros.z - 1.0                 # le volume est au sud d'Aren : entre lui et la caméra
		var hauteur_ok: bool = cam.y <= float(vo["top"]) + 0.5 and cam.y >= float(vo["h0"]) - 1.0
		var marge := 4.0 if vo["masque"] else 2.6                        # hystérésis : pas de clignotement en longeant
		var masque: bool = entre and hauteur_ok and _dist_rect(r, pc) < marge
		if masque != vo["masque"]:
			vo["masque"] = masque
			bascules += 1
			print("P7 escamotage ", JSON.stringify({"id": vo["id"], "masque": masque, "t": snappedf(_t_coupes, 0.01),
				"dernier_s": snappedf(_t_coupes - float(vo.get("t_bascule", -99.0)), 0.01)}))
			vo["t_bascule"] = _t_coupes
			if masque:
				masques[vo["id"]] = true
			else:
				masques.erase(vo["id"])
		var cible := 0.0 if vo["masque"] else 1.0
		var a: float = vo.get("alpha", 1.0)
		if not fondu:
			a = cible
		elif a != cible:
			a = move_toward(a, cible, delta / duree)
		if a == vo.get("alpha", 1.0) and vo.has("alpha"):
			continue
		vo["alpha"] = a
		var nd := vo["node"] as Node3D
		nd.visible = a > 0.001
		if fondu:
			if not vo.has("geoms"):
				vo["geoms"] = nd.find_children("*", "GeometryInstance3D", true, false)
			for g in vo["geoms"]:
				(g as GeometryInstance3D).transparency = 1.0 - a
