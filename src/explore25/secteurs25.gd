extends RefCounted
## P6.2 / P6.2-B — VISIBILITÉ PAR SECTEURS pour les intérieurs (réutilisable : Colisée, Guilde, maisons, commerces, palais).
##
## Données (section « secteurs » d'une zone) : [{id, nom, rects: [[x0, y0, x1, y1]…], voisins: [ids], fond: "sombre" |
## "ciel", plafond_h: m (0 : à ciel ouvert), camera: bool}]. Tout ce qui n'appartient à aucun secteur forme le secteur
## implicite « EXT » (le reste du niveau). Le secteur ACTIF est celui sous les pieds du héros, avec une petite zone de
## stabilité autour de ses limites (pas de bascules répétées quand on s'arrête dans une porte).
##
## Le décor est rangé en catégories, traitées séparément (les corps physiques ne sont JAMAIS touchés) :
##   1. structure persistante : murs (méta « mur »), toujours présents ; seule la partie HAUTE d'un mur qui cache la
##      pièce active s'efface (le muret de LIP m reste, coiffé d'une tranche sombre) ;
##   2. décor d'une pièce (méta « secteur », ou emprise au sol) : groupe de visibilité ;
##   3. éléments pouvant masquer le joueur : les murs ci-dessus (calcul géométrique, voir _doit_couper) ;
##   4. lumière : plafonds « ombres seulement » (plafonds), jamais masqués ;
##   5. extérieur (méta « exterieur ») : masqué tant que le secteur actif est un intérieur sombre.
##
## Trois modes de transition, comparables (P6.2-B) :
##   "echelle" (A, P6.2) : les groupes non visibles s'abaissent vers le sol / s'en élèvent, murs coupés idem ;
##   "continu" (B)       : rien ne bouge. Les pièces situées DERRIÈRE restent affichées (cachées par des murs hauts et
##                         l'occultation du moteur) ; seules les pièces DEVANT la pièce active (entre elle et la caméra) et
##                         l'extérieur s'estompent sur place (transparence) ; les murs gênants s'estompent au-dessus du muret ;
##   "porte" (C)         : mêmes règles que B, appliquées d'un coup sous un bref fondu sombre conduit par la scène.

const World25 = preload("res://src/explore25/world25.gd")
const EXT := "EXT"
const EXTERIEUR := "EXTERIEUR"
const MODES := ["echelle", "continu", "porte"]
const MARGE := 0.7                        # mode « echelle » (P6.2) : appartenance des murs par marge
const DUREE := 0.35
const DUREE_FONDU := 0.45                 # mode continu : estompage sur place
const LIP := 0.5
const H_MIN_COUPE := 0.75
const STABILITE := 0.4                    # m : le secteur actif est conservé à moins de 0,4 m de ses limites

var mode := "continu"
var secteurs: Array = []                  # [{id, nom, rects: [Rect2], voisins, fond, plafond_h, camera}]
var par_id := {}
var actif := ""
var visibles: Array = []
var _groupes := {}                        # clé -> {node, membres, montre, tween, geos: [GeometryInstance3D], lum: [Light3D]}
var _murs: Array = []                     # {pivot, coupe, rect, h0, h1, haut: [GeometryInstance3D], occ, coupe_on, tween}
var _hote: Node
var _racine: Node3D
var stats := {"groupes": 0, "elements": 0, "murs": 0, "bascules": 0, "multi_secteurs": 0}
var traverses: Array = []
var voile_ext := 0.0                      # continu : transparence du reste du niveau (EXT), réglée par la scène                 # éléments dont l'emprise traverse plusieurs secteurs (vérification)


func _init(defs: Array, m := "continu") -> void:
	mode = m if MODES.has(m) else "continu"
	for d in defs:
		var rs: Array = []
		for q in d["rects"]:
			rs.append(Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]))
		var s := {"id": d["id"], "nom": d.get("nom", d["id"]), "rects": rs, "voisins": d.get("voisins", []),
			"fond": d.get("fond", "sombre"), "plafond_h": float(d.get("plafond_h", 0.0)), "camera": bool(d.get("camera", true)),
			"ouverte": bool(d.get("zone_ouverte", false))}
		if d.has("revele_ext"):
			s["revele"] = d["revele_ext"]
		secteurs.append(s)
		par_id[d["id"]] = s


func secteur_en(p: Vector2) -> String:
	for s in secteurs:
		for r in s["rects"]:
			if (r as Rect2).has_point(p):
				return s["id"]
	return EXT


## Secteur sous p, en conservant l'actif tant qu'on reste à moins de STABILITE m de ses limites.
func secteur_stable(p: Vector2) -> String:
	if actif != "" and actif != EXT:
		for r in par_id[actif]["rects"]:
			if (r as Rect2).grow(STABILITE).has_point(p):
				return actif
	return secteur_en(p)


func _membres(p: Vector2) -> Array:
	var out: Array = []
	for s in _pieces():
		for r in s["rects"]:
			if (r as Rect2).grow(MARGE).has_point(p):
				out.append(s["id"])
				break
	if out.is_empty():
		out.append(EXT)
	return out


## Décor ordinaire (point) : le secteur qui le contient (marge de 0,3 m), sinon EXT.
func _proche(p: Vector2) -> String:
	for s in _pieces():
		for r in s["rects"]:
			if (r as Rect2).grow(0.3).has_point(p):
				return s["id"]
	return EXT


## Secteurs touchés par une emprise au sol (P6.2-B : un élément qui traverse deux pièces appartient aux deux).
func _membres_emprise(e0: Rect2, retrait := true) -> Array:
	var out: Array = []
	# un sol qui touche une limite n'y entre pas (retrait de 0,1 m) ; les murs, minces, gardent leur emprise exacte
	var e := e0.grow(-0.1) if (retrait and e0.size.x > 0.3 and e0.size.y > 0.3) else e0
	for s in _pieces():
		for r in s["rects"]:
			if (r as Rect2).grow(0.05).intersects(e):
				out.append(s["id"])
				break
	var dedans := false
	for s in _pieces():
		for r in s["rects"]:
			if (r as Rect2).grow(0.3).encloses(e):
				dedans = true
	if not dedans:
		out.append(EXT)                    # dépasse des secteurs : appartient aussi au reste du niveau
	return out


## Secteurs qui rangent le décor : tous sauf les « zones ouvertes » (P6.2-C : l'arène sert de pièce de référence pour
## les coupes et la stabilité, mais son décor reste celui du reste du niveau, EXT).
func _pieces() -> Array:
	return secteurs.filter(func(s): return not s["ouverte"])


func _emprise(n: Node3D) -> Rect2:
	var aabb := AABB()
	var premier := true
	var pile: Array = [n]
	while not pile.is_empty():
		var c = pile.pop_back()
		if c is VisualInstance3D and not (c is Light3D):
			var a: AABB = (c as VisualInstance3D).get_aabb()
			var t: Transform3D = (c as Node3D).global_transform if (c as Node3D).is_inside_tree() else (c as Node3D).transform
			a = t * a
			aabb = a if premier else aabb.merge(a)
			premier = false
		for k in c.get_children():
			pile.append(k)
	if premier:
		return Rect2()
	return Rect2(aabb.position.x, aabb.position.z, aabb.size.x, aabb.size.z)


## Range le décor construit sous `racine`. Corps physiques et nœuds « hors_secteurs » restent en place.
## Métas : « xz » (position de référence), « secteur » (pièce imposée), « mur » (structure), « exterieur ».
func classer(hote: Node, racine: Node3D) -> void:
	_hote = hote
	_racine = racine
	for n in racine.get_children():
		if n is CollisionObject3D or n.has_meta("hors_secteurs") or not (n is Node3D):
			continue
		var p: Vector2
		if n.has_meta("xz"):
			p = n.get_meta("xz")
		else:
			var g: Vector3 = (n as Node3D).global_position if n.is_inside_tree() else (n as Node3D).position
			p = Vector2(g.x, g.z)
		var m: Array
		if n.has_meta("exterieur"):
			m = [EXTERIEUR]
		elif n.has_meta("secteur"):
			m = [n.get_meta("secteur")]
		elif mode == "echelle":
			m = _membres(p) if n.has_meta("mur") else [_proche(p)]
		else:
			var e := _emprise(n)
			m = _membres_emprise(e, not n.has_meta("mur")) if e.size != Vector2.ZERO else [_proche(p)]
			if m.size() > 1:
				stats["multi_secteurs"] += 1
				if traverses.size() < 40:
					traverses.append("%s %s" % [n.name, str(m)])
		m.sort()
		var k := "|".join(PackedStringArray(m))
		var mur: bool = n.has_meta("mur") and mode != "echelle"
		if mur:
			k = "MUR:" + k                        # structure : groupes à part, jamais masqués en continu
		if not _groupes.has(k):
			var gn := Node3D.new()
			gn.name = "Secteurs_" + k.replace("|", "_")
			racine.add_child(gn)
			_groupes[k] = {"node": gn, "membres": m, "montre": true, "tween": null, "geos": [], "lum": [], "mur": mur}
		n.reparent(_groupes[k]["node"], n.is_inside_tree())
		stats["elements"] += 1
	for k in _groupes:
		_collecter(_groupes[k])
	stats["groupes"] = _groupes.size()


func _collecter(g: Dictionary) -> void:
	var pile: Array = [g["node"]]
	while not pile.is_empty():
		var c = pile.pop_back()
		if c is Light3D:
			c.set_meta("energie", (c as Light3D).light_energy)
			g["lum"].append(c)
		elif c is GeometryInstance3D:
			g["geos"].append(c)
		for k in c.get_children():
			pile.append(k)


## Mur escamotable : maillages sous `pivot` (à l'origine) ; `haut` = maillages au-dessus du muret (mode continu) ;
## `occ` = occulteur du moteur (désactivé dès que le mur s'efface).
## `garde` (P6.2-C) : mur porteur d'un passage (tunnel) ; il n'est jamais coupé parce qu'il est « devant » la pièce
## active, seulement s'il en cache réellement le sol.
func declarer_mur(pivot: Node3D, coupe: Node3D, rect: Rect2, h0: float, h1: float, haut: Array = [], occ: Node3D = null, garde := false) -> void:
	_murs.append({"pivot": pivot, "coupe": coupe, "rect": rect, "h0": h0, "h1": h1, "haut": haut, "occ": occ, "coupe_on": false, "tween": null, "garde": garde})
	coupe.visible = false
	stats["murs"] = _murs.size()


## Plafonds « ombres seulement » des secteurs couverts (invisibles pour la caméra, ils arrêtent le soleil).
func plafonds(racine: Node3D, h_min := 0.0) -> void:
	for s in secteurs:
		var h: float = s["plafond_h"]
		if s["fond"] == "sombre" and h > 0.0:
			h = maxf(h, h_min)                 # mode continu : au-dessus des murs prolongés
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


## Secteur qui serait actif en p (sans rien changer) : la scène s'en sert en mode « porte » pour lancer son fondu.
func prochain(p: Vector2) -> String:
	return secteur_stable(p)


## Met à jour l'état pour la position du héros. `immediat` : sans transition (chargement, téléportation, mode porte).
func mettre_a_jour(p: Vector2, immediat := false) -> bool:
	var a := secteur_stable(p) if not immediat else secteur_en(p)
	if a == actif and not immediat:
		return false
	actif = a
	stats["bascules"] += 1
	visibles = [a]
	if a == EXT:
		visibles = [EXT] + secteurs.map(func(s): return s["id"])
	else:
		visibles += par_id[a]["voisins"]
	var instant := immediat or mode == "porte"
	for k in _groupes:
		var g: Dictionary = _groupes[k]
		_basculer(g, _groupe_montre(g), instant)
	for w in _murs:
		_couper(w, _doit_couper(w), instant)
	return true


func _groupe_montre(g: Dictionary) -> bool:
	var m: Array = g["membres"]
	if m.has(EXTERIEUR):
		return mode == "echelle" or fond() != "sombre"
	if mode != "echelle" and (g.get("mur", false) or m.has(EXT)):
		return true                         # continu : structure persistante ; le reste du niveau : voile progressif
	for x in m:
		if visibles.has(x):
			return true
	if mode == "echelle":
		return false
	# continu / porte : une pièce non visible n'est masquée que si elle est DEVANT la pièce active (sinon les murs
	# hauts la cachent déjà : rien ne doit disparaître sous les yeux du joueur)
	return not _devant(m)


## Les secteurs `m` sont-ils entièrement du côté de la caméra par rapport à la pièce active ?
func _devant(m: Array) -> bool:
	if actif == EXT or m.has(EXT):
		return false
	var vers_fond := -World25.toward_cam()
	var proche_actif := INF
	for r in par_id[actif]["rects"]:
		proche_actif = minf(proche_actif, _prof_min(r, vers_fond))
	for id in m:
		for r in par_id[id]["rects"]:
			if _prof_max(r, vers_fond) > proche_actif + 0.3:
				return false
	return true


func _prof_min(r: Rect2, d: Vector2) -> float:
	return minf(minf(r.position.dot(d), r.end.dot(d)), minf(Vector2(r.end.x, r.position.y).dot(d), Vector2(r.position.x, r.end.y).dot(d)))


func _prof_max(r: Rect2, d: Vector2) -> float:
	return maxf(maxf(r.position.dot(d), r.end.dot(d)), maxf(Vector2(r.end.x, r.position.y).dot(d), Vector2(r.position.x, r.end.y).dot(d)))


## Un mur est coupé seulement s'il cache réellement le sol du secteur actif depuis la caméra : son ombre portée vers
## l'arrière-plan (hauteur affichée / tan(plongée)) recoupe le secteur.
func _doit_couper(w: Dictionary) -> bool:
	var h: float = w["h1"] - w["h0"]
	if actif == EXT or h <= H_MIN_COUPE:
		return false
	if w.get("garde", false) and par_id[actif]["ouverte"]:
		return false                        # P6.2-C : depuis l'arène, le tunnel garde ses murs (minces, axe de la vue)
	var r: Rect2 = w["rect"]
	var vers_fond := -World25.toward_cam()
	if mode != "echelle" and not w.get("garde", false):
		# continu : un mur haut entièrement DEVANT la pièce active (entre elle et la caméra) perd aussi sa partie haute
		# (pas de grande masse sombre au premier plan) ; il reste son muret
		var proche := INF
		for z in par_id[actif]["rects"]:
			proche = minf(proche, _prof_min(z, vers_fond))
		if _prof_max(r, vers_fond) <= proche + 0.45:
			return true
	var ombre := r.merge(Rect2(r.position + vers_fond * (h / tan(World25.pitch)), r.size))
	for z in par_id[actif]["rects"]:
		if ombre.intersects((z as Rect2).grow(-0.05)):
			return true
	return false


## Continu : transparence du reste du niveau (0 : visible, 1 : masqué), pilotée en continu par la position du héros
## (révélation progressive de l'arène depuis la salle d'attente, sans déclenchement brusque).
func regler_voile_ext(t: float) -> void:
	t = clampf(t, 0.0, 1.0)
	# P6.2-C : extrémités exactes. Un voile résiduel (0,002) laissait l'arène dans la passe transparente : rendu plus cher,
	# et aucune profondeur écrite (la vue depuis le tunnel s'appuie sur la profondeur)
	if t < 0.004:
		t = 0.0
	elif t > 0.996:
		t = 1.0
	if mode == "echelle" or t == voile_ext:
		return
	voile_ext = t
	for k in _groupes:
		var g: Dictionary = _groupes[k]
		if (g["membres"] as Array).has(EXT) and not g.get("mur", false):
			_transparence(g, t)
			(g["node"] as Node3D).visible = t < 0.999


## Valeur cible du voile de l'extérieur pour la position p (données : « revele_ext » [prof. masqué, prof. visible]).
func voile_ext_pour(p: Vector2) -> float:
	if actif == EXT or actif == "":
		return 0.0
	var s: Dictionary = par_id[actif]
	if s.has("revele"):
		var r: Array = s["revele"]
		return clampf((p.y - r[1]) / (r[0] - r[1]), 0.0, 1.0)
	return 0.0 if visibles.has(EXT) else 1.0


func est_visible(id: String) -> bool:
	return visibles.has(id)


## Limites de caméra du secteur actif (plan, m) ou Rect2() s'il n'en impose pas.
func camera_rect() -> Rect2:
	if actif == EXT or actif == "" or not par_id[actif]["camera"]:
		return Rect2()
	var r := Rect2()
	var first := true
	for q in par_id[actif]["rects"]:
		r = q if first else r.merge(q)
		first = false
	return r


func fond() -> String:
	return "ciel" if (actif == EXT or actif == "") else par_id[actif]["fond"]


## Le secteur actif est-il à ciel ouvert (EXT ou zone ouverte) ? La scène y rend le vrai ciel.
func a_ciel_ouvert() -> bool:
	return actif == EXT or actif == "" or par_id[actif]["ouverte"]


func nom_actif() -> String:
	return "extérieur / reste du niveau" if (actif == EXT or actif == "") else par_id[actif]["nom"]


# ------------------------------------------------------------------------------------------------ transitions
func _tuer(t) -> void:
	if t != null and (t as Tween).is_valid():
		(t as Tween).kill()


func _basculer(g: Dictionary, montre: bool, immediat: bool) -> void:
	if g["montre"] == montre and not immediat:
		return
	g["montre"] = montre
	var n: Node3D = g["node"]
	_tuer(g["tween"])
	if immediat or _hote == null:
		n.visible = montre
		n.scale = Vector3.ONE
		_transparence(g, 0.0 if montre else 1.0)
		return
	var tw := _hote.create_tween()
	g["tween"] = tw
	if mode == "echelle":
		if montre:
			n.visible = true
			n.scale = Vector3(1, 0.02, 1)
			tw.tween_property(n, "scale", Vector3.ONE, DUREE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		else:
			tw.tween_property(n, "scale", Vector3(1, 0.02, 1), DUREE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tw.tween_callback(func(): n.visible = false; n.scale = Vector3.ONE)
		return
	# continu : estompage sur place (aucun mouvement), puis plus aucun rendu
	var depart := 1.0 if montre else 0.0
	if montre:
		n.visible = true
	tw.tween_method(func(t: float): _transparence(g, t), depart, 1.0 - depart, DUREE_FONDU).set_trans(Tween.TRANS_SINE)
	if not montre:
		tw.tween_callback(func(): n.visible = false)


func _transparence(g: Dictionary, t: float) -> void:
	for geo in g["geos"]:
		if is_instance_valid(geo):
			(geo as GeometryInstance3D).transparency = t
	for l in g["lum"]:
		if is_instance_valid(l):
			(l as Light3D).light_energy = float(l.get_meta("energie", 1.0)) * (1.0 - t)


func _couper(w: Dictionary, couper: bool, immediat: bool) -> void:
	if w["coupe_on"] == couper and not immediat:
		return
	w["coupe_on"] = couper
	var pv: Node3D = w["pivot"]
	var cp: Node3D = w["coupe"]
	var h: float = w["h1"] - w["h0"]
	_tuer(w["tween"])
	if w["occ"] != null:
		(w["occ"] as Node3D).visible = not couper     # ne plus occulter ce qui est derrière dès que le mur s'efface
	if mode == "echelle" or (w["haut"] as Array).is_empty():
		var k := LIP / h if couper else 1.0
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
		return
	# continu / porte : seule la partie haute s'estompe sur place ; le muret reste ; la tranche sombre apparaît
	pv.scale = Vector3.ONE
	if immediat or _hote == null:
		_haut(w, 1.0 if couper else 0.0)
		return
	var tw2 := _hote.create_tween()
	w["tween"] = tw2
	var a := 0.0 if couper else 1.0
	tw2.tween_method(func(t: float): _haut(w, t), a, 1.0 - a, DUREE_FONDU).set_trans(Tween.TRANS_SINE)


## t = 0 : mur entier ; t = 1 : partie haute effacée, tranche sombre visible.
func _haut(w: Dictionary, t: float) -> void:
	for geo in w["haut"]:
		if is_instance_valid(geo):
			(geo as GeometryInstance3D).transparency = t
			(geo as Node3D).visible = t < 0.999
	var cp: GeometryInstance3D = w["coupe"] as GeometryInstance3D
	cp.visible = t > 0.001
	cp.transparency = 1.0 - t


func murs_coupes() -> Array:
	return _murs.filter(func(w): return w["coupe_on"]).map(func(w): return w["pivot"].name)


func groupes_masques() -> Array:
	return _groupes.keys().filter(func(k): return not _groupes[k]["montre"])


## Nombre d'éléments de décor rendus (mesure).
func elements_rendus() -> int:
	var n := 0
	for k in _groupes:
		if (_groupes[k]["node"] as Node3D).visible:
			n += (_groupes[k]["node"] as Node3D).get_child_count()
	return n
