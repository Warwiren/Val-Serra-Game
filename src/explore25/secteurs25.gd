extends RefCounted
## P6.2 — VISIBILITÉ PAR SECTEURS pour les intérieurs (réutilisable : Colisée, Guilde, maisons, commerces, palais).
##
## Données (section « secteurs » d'une zone) : [{id, nom, rects: [[x0, y0, x1, y1]…], voisins: [ids], fond: "sombre" |
## "ciel", plafond_h: m (0 : à ciel ouvert), camera: bool}]. Tout ce qui n'appartient à aucun secteur forme le secteur
## implicite « EXT » (le reste du niveau, affiché comme avant). Le secteur ACTIF est celui sous les pieds du héros.
##
## Trois mécanismes indépendants des collisions (les corps physiques ne sont jamais déplacés, masqués ni réduits) :
##  1. VISIBILITÉ : chaque élément de décor est rangé dans un groupe selon les secteurs qui le contiennent ; un groupe
##     est affiché si l'un de ses secteurs est visible (secteur actif + ses voisins). Apparition / disparition douces :
##     le groupe s'abaisse vers le sol ou s'en élève (≈ 0,35 s), puis n'est plus rendu (aucun appel de dessin).
##  2. MURS DE PREMIER PLAN : un mur est « coupé » (réduit à un muret de LIP m, coiffé d'une tranche sombre) seulement
##     s'il cache réellement le sol du secteur actif depuis la caméra (son ombre portée vers l'arrière-plan, longueur
##     hauteur / tan(plongée), recoupe le secteur). Les murs du fond et des côtés restent entiers.
##  3. LUMIÈRE : plafonds des secteurs couverts posés en « ombres seulement » (invisibles pour la caméra, ils arrêtent
##     le soleil), toujours présents quel que soit l'affichage.
## La scène fournit aussi les limites de caméra du secteur actif (camera_rect) et son ambiance (fond).

const World25 = preload("res://src/explore25/world25.gd")
const EXT := "EXT"
const MARGE := 0.7                        # un élément à moins de 0,7 m d'un secteur lui appartient (murs, cartes décalées)
const DUREE := 0.35
const LIP := 0.5
const H_MIN_COUPE := 0.75

var secteurs: Array = []                  # [{id, nom, rects: [Rect2], voisins, fond, plafond_h, camera}]
var par_id := {}
var actif := ""
var visibles: Array = []
var _groupes := {}                        # clé "S1|P12" -> {node, membres: Array, montre: bool, tween}
var _murs: Array = []                     # {pivot, coupe, rect, h0, h1, coupe_on}
var _hote: Node
var _racine: Node3D
var stats := {"groupes": 0, "elements": 0, "murs": 0, "bascules": 0}


func _init(defs: Array) -> void:
	for d in defs:
		var rs: Array = []
		for q in d["rects"]:
			rs.append(Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]))
		var s := {"id": d["id"], "nom": d.get("nom", d["id"]), "rects": rs, "voisins": d.get("voisins", []),
			"fond": d.get("fond", "sombre"), "plafond_h": float(d.get("plafond_h", 0.0)), "camera": bool(d.get("camera", true))}
		secteurs.append(s)
		par_id[d["id"]] = s


func secteur_en(p: Vector2) -> String:
	for s in secteurs:
		for r in s["rects"]:
			if (r as Rect2).has_point(p):
				return s["id"]
	return EXT


func _membres(p: Vector2) -> Array:
	var out: Array = []
	for s in secteurs:
		for r in s["rects"]:
			if (r as Rect2).grow(MARGE).has_point(p):
				out.append(s["id"])
				break
	if out.is_empty():
		out.append(EXT)
	return out


## Décor ordinaire : le secteur qui le contient (marge de 0,3 m), sinon EXT.
func _proche(p: Vector2) -> String:
	for s in secteurs:
		for r in s["rects"]:
			if (r as Rect2).grow(0.3).has_point(p):
				return s["id"]
	return EXT


## Range le décor déjà construit sous `racine` dans des groupes de visibilité. Les corps physiques, et les nœuds
## marqués « hors_secteurs », restent en place. Métas reconnues : « xz » (Vector2, position de référence), « secteur »
## (id imposé : décor composé pour une pièce), « mur » (frontière : appartient à tous les secteurs qu'il touche).
func classer(hote: Node, racine: Node3D) -> void:
	_hote = hote
	_racine = racine
	for n in racine.get_children():
		if n is CollisionObject3D or n.has_meta("hors_secteurs"):
			continue
		if not (n is Node3D):
			continue
		var p: Vector2
		if n.has_meta("xz"):
			p = n.get_meta("xz")
		else:
			var g: Vector3 = (n as Node3D).global_position if n.is_inside_tree() else (n as Node3D).position
			p = Vector2(g.x, g.z)
		var m: Array
		if n.has_meta("secteur"):
			m = [n.get_meta("secteur")]                    # décor posé pour une pièce précise
		elif n.has_meta("mur"):
			m = _membres(p)                                  # mur : frontière, peut appartenir à deux secteurs
		else:
			m = [_proche(p)]
		m.sort()
		var k := "|".join(PackedStringArray(m))
		if not _groupes.has(k):
			var g := Node3D.new()
			g.name = "Secteurs_" + k.replace("|", "_")
			racine.add_child(g)
			_groupes[k] = {"node": g, "membres": m, "montre": true, "tween": null}
		n.reparent(_groupes[k]["node"], n.is_inside_tree())
		stats["elements"] += 1
	stats["groupes"] = _groupes.size()


## Mur escamotable : la scène construit ses maillages sous `pivot` (nœud à l'origine) et le déclare ici.
func declarer_mur(pivot: Node3D, coupe: Node3D, rect: Rect2, h0: float, h1: float) -> void:
	_murs.append({"pivot": pivot, "coupe": coupe, "rect": rect, "h0": h0, "h1": h1, "coupe_on": false, "tween": null})
	coupe.visible = false
	stats["murs"] = _murs.size()


## Plafonds « ombres seulement » des secteurs couverts (invisibles pour la caméra, ils arrêtent le soleil).
func plafonds(racine: Node3D) -> void:
	for s in secteurs:
		var h: float = s["plafond_h"]
		if h <= 0.0:
			continue
		for r in s["rects"]:
			var rr: Rect2 = (r as Rect2).grow(0.6)
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(rr.size.x, 0.2, rr.size.y)
			mi.mesh = bm
			mi.position = Vector3(rr.get_center().x, h + 0.1, rr.get_center().y)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			mi.set_meta("hors_secteurs", true)
			mi.name = "Plafond_" + s["id"]
			racine.add_child(mi)


## Met à jour l'état pour la position du héros. `immediat` : sans transition (chargement, téléportation).
func mettre_a_jour(p: Vector2, immediat := false) -> bool:
	var a := secteur_en(p)
	if a == actif and not immediat:
		return false
	actif = a
	stats["bascules"] += 1
	visibles = [a]
	if a == EXT:
		visibles = [EXT] + secteurs.map(func(s): return s["id"])
	else:
		visibles += par_id[a]["voisins"]
	for k in _groupes:
		var g: Dictionary = _groupes[k]
		var montre := false
		for m in g["membres"]:
			if visibles.has(m):
				montre = true
		_basculer(g, montre, immediat)
	var zone := _zone_active()
	var pente := tan(World25.pitch)
	var vers_fond := -World25.toward_cam()
	for w in _murs:
		var couper := false
		var h: float = w["h1"] - w["h0"]
		if a != EXT and h > H_MIN_COUPE:
			var r: Rect2 = w["rect"]
			var ombre := r.merge(Rect2(r.position + vers_fond * (h / pente), r.size))
			for z in zone:
				if ombre.intersects((z as Rect2).grow(-0.05)):
					couper = true
		_couper(w, couper, immediat)
	return true


## Sol où le joueur peut se trouver dans le secteur actif (les murs qui le cachent sont coupés).
func _zone_active() -> Array:
	if actif == EXT:
		return []
	return par_id[actif]["rects"]


func est_visible(id: String) -> bool:
	return visibles.has(id)


## Limites de caméra du secteur actif (plan, m) ou Rect2() s'il n'en impose pas.
func camera_rect() -> Rect2:
	if actif == EXT or not par_id[actif]["camera"]:
		return Rect2()
	var r := Rect2()
	var first := true
	for q in par_id[actif]["rects"]:
		r = q if first else r.merge(q)
		first = false
	return r


func fond() -> String:
	return "ciel" if actif == EXT else par_id[actif]["fond"]


func nom_actif() -> String:
	return "extérieur / reste du niveau" if actif == EXT else par_id[actif]["nom"]


func _basculer(g: Dictionary, montre: bool, immediat: bool) -> void:
	if g["montre"] == montre and not immediat:
		return
	g["montre"] = montre
	var n: Node3D = g["node"]
	if g["tween"] != null and (g["tween"] as Tween).is_valid():
		(g["tween"] as Tween).kill()
	if immediat or _hote == null:
		n.visible = montre
		n.scale = Vector3.ONE
		return
	var tw := _hote.create_tween()
	g["tween"] = tw
	if montre:
		n.visible = true
		n.scale = Vector3(1, 0.02, 1)
		tw.tween_property(n, "scale", Vector3.ONE, DUREE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(n, "scale", Vector3(1, 0.02, 1), DUREE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(func(): n.visible = false; n.scale = Vector3.ONE)


func _couper(w: Dictionary, couper: bool, immediat: bool) -> void:
	if w["coupe_on"] == couper and not immediat:
		return
	w["coupe_on"] = couper
	var pv: Node3D = w["pivot"]
	var h: float = w["h1"] - w["h0"]
	var k := LIP / h if couper else 1.0
	if w["tween"] != null and (w["tween"] as Tween).is_valid():
		(w["tween"] as Tween).kill()
	var cp: Node3D = w["coupe"]
	if immediat or _hote == null:
		pv.scale = Vector3(1, k, 1)
		cp.visible = couper
		return
	if not couper:
		cp.visible = false
	var tw := _hote.create_tween()
	w["tween"] = tw
	tw.tween_property(pv, "scale", Vector3(1, k, 1), DUREE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if couper:
		tw.tween_callback(func(): cp.visible = true)


func murs_coupes() -> Array:
	return _murs.filter(func(w): return w["coupe_on"]).map(func(w): return w["pivot"].name)


## Les maillages d'un groupe masqué ne sont pas rendus ; compte des éléments rendus (mesure).
func elements_rendus() -> int:
	var n := 0
	for k in _groupes:
		if (_groupes[k]["node"] as Node3D).visible:
			n += (_groupes[k]["node"] as Node3D).get_child_count()
	return n
