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
		# P8.1-A (L4) : jardinières plantées par modèles (--f_vegetation=0 : sphères P7.7)
		if _fin().actif("vegetation"):
			tr.a.plantes = Vegetation.new(self, tr.a)
		# P8.1-A2 : cohérence des façades (portes, mitoyenneté, baies bornées ; --f_coherence=0 : P8.1-A)
		if _fin().actif("coherence"):
			tr.a.coherence = true
			tr.a.passages = (v.get("entrees", []) as Array).filter(func(x): return str(x["type"]) == "fonctionnelle" or not _entree_obstruee(x))
			tr.a.libre = _point_libre
		if Engine.has_meta("registre_facades"):              # outil tools/p8/coherence_facades_p81a2.gd
			tr.a.registre = []
	return tr


const Vegetation := preload("res://scenes/p8/vegetation_p81.gd")


## P8.1-A2 : un point de façade est-il hors de tout autre volume des données (bâtiments, tours, remparts, fonds ; toit
## compris, 1,5 m au-dessus des murs) ? Sert à ne pas poser de baie, balcon ou lanterne dans un volume mitoyen.
var _volumes_pleins := []


func _point_libre(p: Vector3) -> bool:
	if _volumes_pleins.is_empty():
		for o in sc.world.adj.get("obstacles", []):
			var oid := str(o["id"])
			if oid.begins_with("bat_") or oid.begins_with("tour_") or oid.begins_with("rempart_"):
				var q: Array = o["rect"]
				_volumes_pleins.append([Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]), float(o["h"]), float(o["h"]) + float(o["haut"]) + 1.5])
		for pz in v.get("paysage", []):
			var q2: Array = pz["rect"]
			_volumes_pleins.append([Rect2(q2[0], q2[1], q2[2] - q2[0], q2[3] - q2[1]), float(pz["h"]), float(pz["h"]) + float(pz["haut"]) + 1.5])
	for vp in _volumes_pleins:
		if (vp[0] as Rect2).has_point(Vector2(p.x, p.z)) and p.y >= float(vp[1]) and p.y <= float(vp[2]):
			return false
	return true


const Forge := preload("res://scenes/p7/forge_p79.gd")
const Boutique711 := preload("res://scenes/p7/boutique_p711.gd")
const Civique := preload("res://scenes/p7/civique_p712.gd")
var ci                                    # P7.12 : quartier civique et porte du château (scenes/p7/civique_p712.gd)


## P7.12.2 : escaliers de pierre (volées A à D et ruelle) : les joues pleines du blockout ne sont plus dessinées.
func sans_joues() -> bool:
	return _civ().actif


## P7.13 : la grille des données devant le château n'est plus dessinée quand la herse du châtelet est baissée (sa
## collision et son texte « fermée » restent : c'est la herse qui ferme) ; --herse=relevee : état P7.12.2.
func grille_dessinee(p: Dictionary) -> bool:
	return not (str(p.get("id", "")) == "porte_chateau" and _civ().actif and _civ().herse_baissee())


## P7.13 — Essai d'ombres pour la ville (--ombres_ville=<distance m>, ex. 200) : soleil en 4 tranches (PSSM) jusqu'à cette
## distance au lieu de l'ombre orthogonale unique limitée à 120 m (fondu dès ≈ 96 m : les volées lointaines y entrent et en
## sortent quand la caméra avance). NON activé par défaut : à juger en Forward+ sur GPU (ce conteneur rend en Compatibilité).
func _ombres_ville() -> void:
	var od := str(sc._cli.get("ombres_ville", ""))
	if od == "" or sc.get("_sun") == null:
		return
	var s: DirectionalLight3D = sc._sun
	s.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	s.directional_shadow_max_distance = float(od)
	s.directional_shadow_blend_splits = true


const LumiereP80B := preload("res://scenes/p8/lumiere_p80b.gd")
var lum                                   # P8.0-B : profils de lumière A / B (scenes/p8/lumiere_p80b.gd)


const Finition := preload("res://scenes/p8/finition_p81.gd")
var fi                                    # P8.1-A : finition du quartier par lots (scenes/p8/finition_p81.gd)


func _fin():
	if fi == null:
		fi = Finition.new(self)
	return fi


## P8.1-A (L1) : masses de terrain en soutènement de pierre et dallage (--f_sols=0 : blockout V0.7-A)
func _masses() -> void:
	if _fin().actif("sols") and sans_joues():           # joues des volées : seulement sans le quartier civique (super)
		_fin().masses(v.get("masses", []))
		return
	super()


## P8.1-A (L2) : façade extérieure du Colisée à arcades réelles (--f_colisee=0 : tambour de la V0.7-A). Vestibule, propylée
## et porte à battants : ceux de la V0.7-A, le vestibule en pierre du Colisée.
func _colisee_v07() -> void:
	var cd: Dictionary = v.get("colisee", {})
	if cd.is_empty() or not _fin().actif("colisee"):
		super()
		return
	_fin().colisee(cd, func(p: Vector2) -> bool: return _pres_porte(p, cd))
	# bannières rouges de l'attique, sur une pile sur quatre (comme sur le tambour de la V0.7-A)
	for k in range(2, 28, 4):
		var f: Dictionary = _fin()._face_ellipse(Vector2(cd["centre"][0], cd["centre"][1]), Vector2(cd["rayons"][0], cd["rayons"][1]), PI * float(k) / 28.0)
		var pf: Vector3 = f["o"]
		var nf: Vector3 = f["n"]
		if not _pres_porte(Vector2(pf.x, pf.z), cd):
			_banniere_colisee(Vector3(pf.x, float(cd["h"]) + 13.6, pf.z) + nf * 0.2, atan2(nf.x, nf.z), Color(0.62, 0.16, 0.18))
	var h0: float = cd["h"]
	var vb: Array = cd.get("vestibule", [])
	if vb.size() == 4:
		var r := Rect2(vb[0], vb[1], vb[2] - vb[0], vb[3] - vb[1])
		var yc := r.get_center().y
		var pierre: Material = _fin().pierre_colisee(h0)
		for y in [r.position.y - 0.1, r.end.y + 0.1]:
			_fin().a.box(Vector3(r.get_center().x, h0 + 3.6, y), Vector3(r.size.x, 7.2, 0.2), pierre)
		_fin().a.box(Vector3(r.position.x - 0.3, h0 + 3.6, yc), Vector3(0.6, 7.2, r.size.y), _fin().fond_galerie(h0))
		_fin().a.box(Vector3(r.get_center().x, h0 + 7.4, yc), Vector3(r.size.x, 0.4, r.size.y + 0.4), pierre)
		var d1: int = sc.root.get_child_count()
		_propylee(cd.get("propylee", {}), h0, yc)
		_porte_battants(cd.get("porte_battants", []), h0)
		_fin().remplacer_blockout(d1)                      # propylée et porte : pierre et bois (même géométrie)


## P8.1-A (L5) : chantier au bout de la rue (poteaux, lisses, échafaudage, tas de pierres et de planches) : même géométrie,
## bois et pierre au lieu du blockout (lisses jaunes -> planches). --f_limites=0 : V0.7-A.
func _chantier() -> void:
	var d0: int = sc.root.get_child_count()
	super()
	if _fin().actif("limites"):
		_fin().remplacer_blockout(d0)


## P8.1-A (L3) : fonds habillés par fiche (--f_batiments=0 : volumes de la V0.7-A).
func _paysage(p: Dictionary, i: int) -> void:
	if _fin().actif("batiments"):
		_fin().fond(p, i)
		return
	super(p, i)


## P8.1-A (L3) : bâtiment secondaire encore en blockout -> fiche de façade ; socle bas -> soutènement et chaperon.
## Exclus : bat_echoppe_no (plate-forme de la cour, revêtue par la forge D au-dessus du blockout).
func _batiment_secondaire(e: Dictionary) -> bool:
	var id := str(e["id"])
	if not (_fin().actif("batiments") and e["type"] == "block" and id.begins_with("bat_") and id != "bat_echoppe_no"):
		return false
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	if h1 - h0 < 2.5:
		_fin().socle(e)
		return true
	var cat := str(v.get("batiments", {}).get(id, {}).get("categorie", "residentiel"))
	var genre := "civique" if cat in ["guilde", "civique"] else "maison"
	var entrees := (v.get("entrees", []) as Array).filter(func(x): return str(x.get("batiment", "")) == id)
	var toit_max := minf(clampf(minf(r.size.x, r.size.y) * 0.42, 1.4, 6.0), maxf((h1 - h0) * 0.7, 1.0))
	_fin().batiment(e, genre, entrees, toit_max)
	var lib: String = str(v.get("batiments", {}).get(id, {}).get("libelle", ""))
	if lib != "":
		_libelle(lib, Vector3(r.get_center().x, h1 + 1.6, r.get_center().y))
	return true


const Bordures := preload("res://scenes/p7/bordures_p713.gd")
var bd                                    # P7.13 : bordures de la grande place (scenes/p7/bordures_p713.gd)


func _bord():
	if bd == null:
		bd = Bordures.new(sc, _tr().a, _forge())
	return bd


func _civ():
	if ci == null:
		ci = Civique.new(sc, self, _tr().a, _forge())
	return ci
var bo                                    # P7.11 : boutique de fournitures (scenes/p7/boutique_p711.gd)
var fo                                    # forge D (C : comparaison) et utilitaires Quaternius (scenes/p7/forge_p79.gd)


## Boutique P7.11 APPROUVÉE (scenes/p7/boutique_p711.gd) ; --boutique=0 : blockout. Active avec la forge C ou D.
## P8.0-C : version P7.10 (--boutique=710, boutique_p710.gd) retirée ; historique Git, commit 588e90c.
func _boutique():
	if bo == null and _forge().variante in ["C", "D"] and str(sc._cli.get("boutique", "711")) != "0":
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
	# P7.13 : bordures de la grande place (draperie, étals, halle sur quai ; collisions des données)
	if e["type"] == "block" and _bord().gere(id):
		_bord().construit(e)
		var lib1: String = str(v.get("batiments", {}).get(id, {}).get("libelle", ""))
		if lib1 != "":
			var r1: Rect2 = e["rect"]
			_libelle(lib1, Vector3(r1.get_center().x, float(e["h1"]) + 4.0, r1.get_center().y))
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
		if _fin().actif("sols"):
			_fin().corps_terrasse(rt, e["h0"], e["h1"] - 0.3)          # P8.1-A (L1) : soutènement de pierre
		else:
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
		if _fin().actif("sols"):
			_fin().corps_terrasse(rp, h0, hp - 0.3)                    # P8.1-A (L1) : soutènement de pierre
		else:
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
		elif id.begins_with("decor_cafe") and _civ().actif:
			_civ().cafe(r, h0)                                # P7.12.2 : terrasse du belvédère
		elif id == "decor_buvette" and _civ().actif:
			_civ().buvette(r, h0)                             # P7.13 : buvette adossée à la boutique
		return true
	if _batiment_secondaire(e):
		return true
	# P8.1-A (L5) : barrières de fin de carte (chantier, route du sud) : planches sur chevalets (même collision)
	if _fin().actif("limites") and e["type"] == "block" and id.begins_with("barriere"):
		_fin().barriere(e)
		return true
	# P8.1-A (L1) : sols, terrasses et garde-corps restants (mêmes collisions que le blockout ; --f_sols=0)
	if _fin().actif("sols"):
		if e["type"] == "floor":
			_fin().sol(e)
			return true
		if e["type"] == "block" and e.get("role", "") == "terrasse":
			_fin().terrasse(e)
			return true
		if e["type"] == "block" and id.begins_with("gc_"):
			_fin().garde_corps(e)
			return true
	return super(e)


func decorer() -> void:
	super()
	var d_p: int = sc.root.get_child_count()
	for s in v.get("decor_escaliers", []):
		_escalier_decor(s)
	for a in v.get("decor_arches", []):
		_arche_decor(a)
	for tr in v.get("decor_tours", []):
		_tour_decor(tr)
	# P8.1-A (L5) : prolongements visuels aux limites (escaliers, arches, tours vers les faubourgs et l'est) : même
	# géométrie, pierre de soutènement et calcaire au lieu du blockout
	if _fin().actif("limites"):
		_fin().remplacer_blockout(d_p, _fin().soutenement(0.0))
	var d_e: int = sc.root.get_child_count()
	_entrees()
	if _fin().actif("batiments"):
		_fin().remplacer_blockout(d_e)                     # P8.1-A (L3) : encadrements et emmarchements en pierre
	_civ().decorer()
	_bord().finaliser()                                   # P7.13 : étals de la place (fusion commune)
	_ombres_ville()
	_classer_volumes()
	# P8.1-A (L5) : murets de la porte sud (tours, remparts) et vantaux ouverts : maçonnerie et bois (même géométrie)
	if _fin().actif("limites"):
		for vo in _vols:
			if str(vo["id"]).begins_with("tour_sud") or str(vo["id"]).begins_with("rempart_sud"):
				_fin().remplacer_blockout_sous(vo["node"], _fin().soutenement(0.0))
	# P8.0-B : profil de lumière (A = P7.13 par défaut ; --lumiere=b, méta « lumiere », touche F4)
	lum = LumiereP80B.new(sc, self)
	lum.appliquer(lum.profil_demande())
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
			if str(e["id"]) == "boutique" and _boutique() != null:
				continue                                  # P7.11 : devanture dessinée par la boutique (boutique_p711.gd)
			_entree_fonctionnelle(e)
			if str(e["id"]) == "forge":
				_forge().apres_entree(e)
		elif str(e.get("batiment", "")) == Bordures.DRAPERIE and _bord().actif:
			continue                                      # P7.13 : porte cintrée dessinée par la draperie (bordures_p713.gd)
		else:
			if _fin().actif("coherence") and _entree_obstruee(e):
				continue                                      # P8.1-A2 : porte décorative donnant sur un mur (non dessinée)
			_porte_decorative(e)


## P8.1-A2 : une entrée DÉCORATIVE est obstruée si un autre bâtiment des données occupe le passage devant elle (1,2 m) :
## elle ne mènerait nulle part (cas : deco_guilde_o, contre l'immeuble de la placette). Aucune collision n'en dépend.
func _entree_obstruee(e: Dictionary) -> bool:
	var zone := Rect2(float(e["x"]) - float(e["largeur"]) * 0.5, float(e["y"]) + 0.1, float(e["largeur"]), 1.1)
	for o in sc.world.adj.get("obstacles", []):
		var oid := str(o["id"])
		if not oid.begins_with("bat_") or oid == str(e.get("batiment", "")):
			continue
		var q: Array = o["rect"]
		if Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]).intersects(zone) and float(o["h"]) <= float(e["h"]) + 0.5:
			return true
	return false


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


## P7.13 : côtés des volées adossés à un mur (Guilde, auberge, forge, socle du palier) : échiffre non dessiné.
const CONTRE_MUR := {"volee_a": ["o"], "volee_b": ["e"], "volee_c": ["o"], "volee_d": ["o"]}


## P7.6 : escalier de la ruelle des Tonneliers dessiné par la tranche (pierre, murs d'échiffre) ; les autres : socle.
func _escalier(e: Dictionary) -> void:
	if str(e.get("id", "")) in Civique.VOLEES and _civ().actif:
		var ee := e.duplicate()
		ee["contre_mur"] = CONTRE_MUR.get(str(e["id"]), [])  # P7.13 : pas d'échiffre plaqué contre un mur
		_tr().escalier(ee)                                  # P7.12 : volées C et D en pierre (mêmes collisions)
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
		if oid == "bat_boutique_fournitures" and bo != null:
			top = maxf(top, 17.5)                            # P7.11 : étages et toit au-dessus du bloc des données
		if oid == Bordures.HALLE and _bord().actif:
			top = maxf(top, h1 + 5.2)                        # P7.13 : halle de charpente sur le quai
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
	# P7.12.1 : chaque volume assez haut est coupé à hauteur d'étage (bas / haut) : l'escamotage peut ne retirer que les
	# étages et le toit quand la ligne de vue vers Aren passe au-dessus du rez-de-chaussée (--escamotage_partiel=0 : P7.6)
	if _partiel():
		for vo in _vols:
			_decouper(vo)


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
		var marge := 4.0 if int(vo.get("mode", 0)) > 0 else 2.6         # hystérésis : pas de clignotement en longeant
		var masque: bool = entre and hauteur_ok and _dist_rect(r, pc) < marge
		# P7.12.1 : le volume coupe la ligne de vue caméra -> buste d'Aren (Aren et ses chemins restent visibles)
		if not masque and entre and vo.has("haut"):
			masque = _coupe_vue(vo, cam, heros + Vector3(0, 1.0, 0), 0.5 if int(vo.get("mode", 0)) > 0 else 0.0)
		# P7.12.1 : 1 = étages et toit seuls (la ligne de vue caméra -> pieds d'Aren passe au-dessus de la coupe, au droit
		# de la face nord du volume), 2 = volume entier (comportement P7.6)
		var mode := 0
		if masque:
			mode = 2
			if vo.has("haut") and cam.z > heros.z + 0.5:
				var tf := clampf((r.position.y - heros.z) / (cam.z - heros.z), 0.0, 1.0)
				var h_los := heros.y + tf * (cam.y - heros.y)
				var seuil: float = float(vo["coupe"]) + (0.05 if int(vo.get("mode", 0)) == 1 else 0.25)
				if h_los >= seuil:
					mode = 1
		# P7.12.2 : marge de réapparition : masquer est immédiat (Aren d'abord), ré-afficher attend que la vue soit dégagée
		# pendant `escamotage_delai` s (0,6 s par défaut) : plus de clignotement aux arrêts et demi-tours
		var cour := int(vo.get("mode", 0))
		if mode < cour and _partiel():
			vo["t_relache"] = float(vo.get("t_relache", 0.0)) + delta
			if float(vo["t_relache"]) < float(sc._cli.get("escamotage_delai", 0.6)):
				mode = cour
			else:
				vo["t_relache"] = 0.0
		else:
			vo["t_relache"] = 0.0
		if mode != int(vo.get("mode", 0)):
			vo["mode"] = mode
			vo["masque"] = mode > 0
			bascules += 1
			print("P7 escamotage ", JSON.stringify({"id": vo["id"], "masque": mode > 0, "partie": ["aucune", "haut", "tout"][mode],
				"t": snappedf(_t_coupes, 0.01), "dernier_s": snappedf(_t_coupes - float(vo.get("t_bascule", -99.0)), 0.01)}))
			vo["t_bascule"] = _t_coupes
			if mode > 0:
				masques[vo["id"]] = true
			else:
				masques.erase(vo["id"])
		# alpha du volume entier et de sa partie haute (net : immédiat ; fondu : expérimental, Forward+ seulement)
		var cible := 0.0 if mode == 2 else 1.0
		var cible_h := 0.0 if mode >= 1 else 1.0
		var a: float = vo.get("alpha", 1.0)
		var ah: float = vo.get("alpha_h", 1.0)
		if not fondu:
			a = cible
			ah = cible_h
		else:
			a = move_toward(a, cible, delta / duree)
			ah = move_toward(ah, cible_h, delta / duree)
		if vo.has("alpha") and a == float(vo["alpha"]) and ah == float(vo["alpha_h"]):
			continue
		vo["alpha"] = a
		vo["alpha_h"] = ah
		var nd := vo["node"] as Node3D
		nd.visible = a > 0.001
		var parapet: bool = vo.get("parapet", false)       # P8.0-B : coupe permanente (porte sud), dessus toujours affiché
		if vo.has("haut"):
			(vo["haut"] as Node3D).visible = ah > 0.001 and not parapet
		if vo.has("chapeau"):
			(vo["chapeau"] as Node3D).visible = a > 0.001 and (ah <= 0.001 or parapet)
		if fondu:
			if not vo.has("geoms"):
				vo["geoms"] = nd.find_children("*", "GeometryInstance3D", true, false)
			for g in vo["geoms"]:
				var dans_haut: bool = vo.has("haut") and (vo["haut"] as Node).is_ancestor_of(g)
				(g as GeometryInstance3D).transparency = 1.0 - minf(a, ah if dans_haut else 1.0)


# ------------------------------------------------------------------------------------------------ P7.12.1 : découpe bas / haut
const COUPE_ETAGE := 3.5                     # hauteur conservée (rez-de-chaussée) quand seuls les étages sont escamotés
## P8.0-B — Coupes propres à certains volumes de premier plan (diagnostic P8.0-A2) ; --coupes_p80b=0 : état P8.0-A.
##  * auberge-taverne et Guilde (h0 0, bordées par la grande place à 3,5 m) : coupées à 3,5 m, leur plancher de coupe
##    prolongeait le dallage de la place comme une grande plate-forme de bois. Coupe à 3,1 m (au-dessus des baies et
##    de la porte de l'auberge, 3,0 m), soit 0,4 m sous la place, et dessus en maçonnerie arasée sombre (« arase ») ;
##  * tours et remparts de la porte sud : la caméra est hors les murs au départ de la placette ; coupés à 3,5 m, ils
##    laissaient deux souches massives au premier plan. Parapet de 1,2 m, dessus de pierre (chemin de ronde, « pierre »).
const COUPES_P80B := {
	"bat_auberge_taverne": [3.1, "arase"], "bat_guilde": [3.1, "arase"],
	"tour_sud_o": [1.2, "pierre"], "tour_sud_e": [1.2, "pierre"], "rempart_sud_o": [1.2, "pierre"], "rempart_sud_e": [1.2, "pierre"],
}


func _coupes_p80b() -> bool:
	return str(sc._cli.get("coupes_p80b", "1")) != "0"


## Hauteur conservée au-dessus de h0 et style du dessus de coupe (« plancher » : P7.12.2) du volume.
func _coupe_de(vo: Dictionary) -> Array:
	if _coupes_p80b() and COUPES_P80B.has(str(vo["id"])):
		return COUPES_P80B[str(vo["id"])]
	return [COUPE_ETAGE, "plancher"]


## Découpe d'un volume à h0 + 3,5 m : boîtes coupées en deux, maillages (fusionnés, modèles) répartis par triangle selon
## la hauteur de leur centre, autres géométries selon le centre de leur boîte. Les pièces hautes passent sous un nœud
## « haut » du volume ; tout le reste (rez-de-chaussée) reste sous le volume. Aucun volume bas (< 5 m) n'est découpé.
func _decouper(vo: Dictionary) -> void:
	var nd := vo["node"] as Node3D
	var cd: Array = _coupe_de(vo)
	var coupe: float = float(vo["h0"]) + float(cd[0])
	if float(vo["top"]) - coupe < 1.5:
		return
	vo["style_coupe"] = str(cd[1])
	var haut := Node3D.new()
	haut.name = "haut"
	nd.add_child(haut)
	for g in nd.get_children():
		if g == haut or not (g is GeometryInstance3D):
			continue
		var gi := g as GeometryInstance3D
		var ab: AABB = gi.global_transform * gi.get_aabb()
		if ab.end.y <= coupe + 0.02:
			continue
		if ab.position.y >= coupe - 0.02:
			gi.reparent(haut, true)
			continue
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh != null:
			var mi := gi as MeshInstance3D
			if mi.mesh is BoxMesh and mi.global_transform.basis.is_equal_approx(Basis.from_scale(mi.global_transform.basis.get_scale())):
				_couper_boite(mi, coupe, haut)
				continue
			if mi.mesh is ArrayMesh:
				_couper_maillage(mi, coupe, haut)
				continue
		if ab.get_center().y > coupe:
			gi.reparent(haut, true)
	vo["haut"] = haut
	vo["coupe"] = coupe
	_chapeau(vo)
	# P8.0-B (correctif) : le style « pierre » (porte sud) est une coupe PERMANENTE. Ces volumes ne sont dessinés qu'en muret de
	# 1,6 m coiffé d'une tranche sombre (ville_blockout) et ne sont presque jamais escamotés depuis la placette (la visée passe
	# entre les tours) : le dessus de pierre, réservé au mode « haut », ne s'affichait donc pas et la tranche sombre restait
	# visible (dessus bleu-noir). Parapet de 1,2 m et chemin de ronde toujours affichés ; collision des données inchangée.
	if str(cd[1]) == "pierre":
		vo["parapet"] = true
		haut.visible = false
		(vo["chapeau"] as Node3D).visible = true


## Boîte alignée coupée en deux boîtes (même matière, matières en coordonnées monde : raccord invisible).
func _couper_boite(mi: MeshInstance3D, coupe: float, haut: Node3D) -> void:
	var bm := mi.mesh as BoxMesh
	var s := mi.global_transform.basis.get_scale()
	var c := mi.global_position
	var y0 := c.y - bm.size.y * s.y * 0.5
	var y1 := c.y + bm.size.y * s.y * 0.5
	var b_bas := bm.duplicate() as BoxMesh
	b_bas.size = Vector3(bm.size.x, (coupe - y0) / s.y, bm.size.z)
	var b_haut := bm.duplicate() as BoxMesh
	b_haut.size = Vector3(bm.size.x, (y1 - coupe) / s.y, bm.size.z)
	var mh := mi.duplicate() as MeshInstance3D
	mh.mesh = b_haut
	haut.add_child(mh)
	mh.global_position = Vector3(c.x, (coupe + y1) * 0.5, c.z)
	mi.mesh = b_bas
	mi.global_position = Vector3(c.x, (y0 + coupe) * 0.5, c.z)


## Maillage réparti par triangle (centre au-dessus de la coupe -> haut) ; sommets conservés, index séparés.
func _couper_maillage(mi: MeshInstance3D, coupe: float, haut: Node3D) -> void:
	var src := mi.mesh as ArrayMesh
	var gt := mi.global_transform
	var m_bas := ArrayMesh.new()
	var m_haut := ArrayMesh.new()
	for si in src.get_surface_count():
		if src.surface_get_primitive_type(si) != Mesh.PRIMITIVE_TRIANGLES:
			return
		var arr := src.surface_get_arrays(si)
		var vx: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if idx.is_empty():
			idx.resize(vx.size())
			for i in vx.size():
				idx[i] = i
		var ib := PackedInt32Array()
		var ih := PackedInt32Array()
		for k in range(0, idx.size(), 3):
			var cy := (gt * vx[idx[k]]).y + (gt * vx[idx[k + 1]]).y + (gt * vx[idx[k + 2]]).y
			if cy / 3.0 > coupe:
				ih.append_array([idx[k], idx[k + 1], idx[k + 2]])
			else:
				ib.append_array([idx[k], idx[k + 1], idx[k + 2]])
		var mat: Material = mi.get_active_material(si) if mi.material_override == null else src.surface_get_material(si)
		for p in [[m_bas, ib], [m_haut, ih]]:
			if (p[1] as PackedInt32Array).is_empty():
				continue
			var a2 := arr.duplicate()
			a2[Mesh.ARRAY_INDEX] = p[1]
			(p[0] as ArrayMesh).add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a2)
			(p[0] as ArrayMesh).surface_set_material((p[0] as ArrayMesh).get_surface_count() - 1, mat)
	if m_haut.get_surface_count() == 0:
		return
	if m_bas.get_surface_count() == 0:
		mi.reparent(haut, true)
		return
	var mh := mi.duplicate() as MeshInstance3D
	mh.mesh = m_haut
	haut.add_child(mh)
	mh.global_transform = gt
	mi.mesh = m_bas
	for m2 in [mi, mh]:
		for k in (m2 as MeshInstance3D).get_surface_override_material_count():
			(m2 as MeshInstance3D).set_surface_override_material(k, null)


## Le segment caméra -> cible traverse-t-il la boîte du volume (emprise, h0 -> sommet), élargie de `marge` ?
func _coupe_vue(vo: Dictionary, cam: Vector3, cible: Vector3, marge: float) -> bool:
	var r: Rect2 = (vo["rect"] as Rect2).grow(marge)
	var lo := Vector3(r.position.x, float(vo["h0"]), r.position.y)
	var hi := Vector3(r.end.x, float(vo["top"]) + marge, r.end.y)
	var d := cible - cam
	var t0 := 0.0
	var t1 := 1.0
	for k in 3:
		if absf(d[k]) < 1e-6:
			if cam[k] < lo[k] or cam[k] > hi[k]:
				return false
			continue
		var ta := (lo[k] - cam[k]) / d[k]
		var tb := (hi[k] - cam[k]) / d[k]
		t0 = maxf(t0, minf(ta, tb))
		t1 = minf(t1, maxf(ta, tb))
		if t0 > t1:
			return false
	return true


func _partiel() -> bool:
	return str(sc._cli.get("escamotage_partiel", "1")) != "0"


## P7.12.2 — Finition de la coupe (visible seulement quand les étages sont escamotés) : plancher de bois de l'étage posé
## sur le haut réel de la partie conservée, bordé d'une arase de pierre (épaisseur du mur) : lecture d'une coupe
## volontaire (maquette), au lieu du dessus brut du volume.
func _chapeau(vo: Dictionary) -> void:
	var nd := vo["node"] as Node3D
	var r: Rect2 = vo["rect"]
	var h := float(vo["h0"])
	for g in nd.get_children():
		if g is GeometryInstance3D and not (g is Label3D):
			var ab: AABB = (g as GeometryInstance3D).global_transform * (g as GeometryInstance3D).get_aabb()
			var c := ab.get_center()
			if r.grow(0.2).has_point(Vector2(c.x, c.z)):
				h = maxf(h, ab.end.y)
	h = minf(h, float(vo["coupe"]) + 0.05)
	var a = _tr().a
	var ch := Node3D.new()
	ch.name = "chapeau"
	ch.visible = false
	nd.add_child(ch)
	var d0: int = a.racine.get_child_count()
	var ri := r.grow(-0.35)
	# P8.0-B : dessus selon le style de coupe du volume (« plancher » P7.12.2 ; « arase » : maçonnerie arasée sombre et arase
	# large ; « pierre » : chemin de ronde de pierre, sans plancher)
	var style := str(vo.get("style_coupe", "plancher"))
	var m_dessus: Material = a.macon("plancher", Color(1.05, 0.98, 0.9), h, "monde", false)
	var ep := 0.35
	if style == "arase":
		m_dessus = a.macon("mur2", Color(0.7, 0.66, 0.62), h, "monde", false)
		ep = 0.55
	elif style == "pierre":
		m_dessus = a.macon("dalle", Color(0.86, 0.82, 0.78), h, "monde", false)
		ep = 0.45
	var pl: MeshInstance3D = a.box(Vector3(r.get_center().x, h + 0.015, r.get_center().y), Vector3(ri.size.x, 0.03, ri.size.y), m_dessus)
	pl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ar: Material = a.macon("mur2", Color(1.2, 1.12, 1.0), h)
	for b in [[r.position.x, r.end.x, r.position.y, r.position.y + ep], [r.position.x, r.end.x, r.end.y - ep, r.end.y],
			[r.position.x, r.position.x + ep, r.position.y, r.end.y], [r.end.x - ep, r.end.x, r.position.y, r.end.y]]:
		var m: MeshInstance3D = a.box(Vector3((b[0] + b[1]) * 0.5, h + 0.06, (b[2] + b[3]) * 0.5), Vector3(b[1] - b[0], 0.12, b[3] - b[2]), ar)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	a.fusionner(d0, "chapeau_" + str(vo["id"]))
	for i in range(a.racine.get_child_count() - 1, d0 - 1, -1):
		var n: Node = a.racine.get_child(i)
		n.reparent(ch, true)
	vo["chapeau"] = ch

