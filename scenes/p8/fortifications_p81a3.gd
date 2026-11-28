extends RefCounted
## P8.1-A3 — ENCEINTE DE LA PORTE SUD (principe validé par le créateur : véritable enceinte, fossé sec, créneaux
## rectangulaires, chemin de ronde à parapet, pas d'échauguette, pas d'enceinte géante).
##
## Composition (caméra de ville : vers le nord, ≈ 21 m derrière Aren et 6,4 m au-dessus) :
##  * la ville est assise sur une terrasse : côté ville, la courtine n'est qu'un mur de 1,2 m portant le CHEMIN DE RONDE,
##    son parapet (2,2 m) et ses merlons (3,0 m) ; côté extérieur, l'ESCARPE descend de 5 m dans un FOSSÉ SEC de 9 m :
##    la hauteur défensive se lit sur la façade extérieure (≈ 8 m) sans dresser de mur devant la placette ;
##  * deux TOURS carrées de flanquement (emprises des données, 4 x 7 m) saillantes sur le fossé : talus, cordons, archères,
##    plate-forme crénelée à 6,2 m (≈ 12,8 m au-dessus du fond du fossé), porte de la tour vers la placette (décor) ;
##  * PORTE voûtée entre les tours (plein cintre de 6 m, clé à 5,15 m), herse relevée visible sous la clé, vantaux ouverts
##    contre le passage, chemin de ronde crénelé à 5,4 m reliant les tours ;
##  * PONT DORMANT de maçonnerie sur le fossé dans l'axe x 60 (la route sud praticable et sa barrière restent celles des
##    données : accès extérieur et transitions futures inchangés) ; parapets bas ;
##  * raccords : lices (bande de 2 m entre les maisons et la courtine) fermées côté placette par un muret, escaliers
##    d'accès au chemin de ronde contre la courtine près de chaque tour, courtines prolongées (affichage seul) jusqu'aux
##    fonds (x -12 et x 138) et arrêtées sur le fossé ; maisons de la rue du chantier adossées (fonds existants).
##
## Escamotage (base technique P7.12.1 / P8.1-A3) : le PIED de l'enceinte (escarpe, mur de 1,2 m, chemin de ronde, souche
## des tours jusqu'à 0,9 m) est permanent ; parapets, merlons, corps des tours et porte sont des volumes d'escamotage à
## niveaux explicites (spec) : on ne retire que ce qui dépasse la ligne de vue vers Aren, segment par segment.
## Collisions : celles des données (tours 12 m, courtines 9 m), inchangées. --fortifs=0 : état P8.1-A2 (muret de 1,2 m).

const H_CHEMIN := 1.2            # chemin de ronde des courtines (au-dessus de la placette)
const H_PARAPET := 2.2
const H_MERLON := 3.0
const FOND := -5.0               # fond du fossé
const Y_INT := 152.0             # face intérieure des courtines (données)
const Y_EXT := 155.0             # face extérieure (escarpe)
const Y_CONTRE := 164.0          # contrescarpe
const X_MIN := -12.0             # courtines prolongées (affichage) jusqu'aux fonds
const X_MAX := 138.0
const H_TOUR := 6.2              # plate-forme des tours
const H_PORTE := 5.4             # chemin de ronde au-dessus de la porte
## niveaux de coupe (absolus) : entre les rangs d'archères et au-dessus des cordons ; porte : limite d'un gradin d'écoinçon
## (mi-arc) puis chemin de ronde. Les pièces sont découpées à ces hauteurs (pas de pan coupé en biais par triangle).
const COUPES_TOUR := [3.4, 5.4]
## P8.1-A4 : souche permanente des tours au niveau du chemin de ronde, premier niveau de coupe à celui du parapet : une tour
## coupée reste alignée sur la courtine coupée (enceinte lue comme une ligne continue en gradins). --stabilite_a4=0 : A3.
var souche_tour := H_CHEMIN
var coupe_parapet_tour := true
const COUPES_PORTE := [3.65, 5.46]
## segments d'escamotage des courtines (x0, x1) : étroits près de la porte (placette), larges au loin
const SEGMENTS := [[-12.0, 30.0], [30.0, 38.0], [38.0, 46.0], [46.0, 53.0], [67.0, 74.0], [74.0, 82.0], [82.0, 90.0], [90.0, 138.0]]
const TOURS := {"tour_sud_o": [53.0, 57.0], "tour_sud_e": [63.0, 67.0]}

var b                 # ville (ville_v07b.gd)
var sc
var a                 # Archi
var fi                # finition (matières)
var actif := true
var _vols := []       # volumes d'escamotage déclarés (spec)
var m := {}


func _init(ville, scene, archi, finition) -> void:
	b = ville
	sc = scene
	a = archi
	fi = finition
	actif = str(sc._cli.get("fortifs", "1")) != "0"
	if str(sc._cli.get("stabilite_a4", "1")) == "0":
		souche_tour = 0.9
		coupe_parapet_tour = false


func _mats() -> void:
	if not m.is_empty():
		return
	m["mur"] = fi.soutenement(FOND)
	m["taille"] = fi.taille()
	m["dalle"] = a.macon("dalle", Color(0.86, 0.82, 0.78), H_CHEMIN, "monde", false)
	m["sombre"] = a.plein(Color(0.07, 0.065, 0.06), 0.95)
	m["bois"] = a.plein(Color(0.30, 0.20, 0.13), 0.9)
	m["fer"] = a.plein(Color(0.15, 0.15, 0.16), 0.55, 0.0, 0.4)
	var herbe := StandardMaterial3D.new()
	herbe.albedo_texture = load("res://art/p4/mat/sol_herbe.png")
	herbe.albedo_color = Color(0.78, 0.8, 0.7)
	herbe.uv1_triplanar = true
	herbe.uv1_world_triplanar = true
	herbe.uv1_scale = Vector3(0.22, 0.22, 0.22)
	herbe.roughness = 0.95
	m["herbe"] = herbe


## Rectangle du fossé (trou dans le sol de décor, finition_p81.sol).
func trou_fosse() -> Rect2:
	return Rect2(X_MIN, Y_EXT, X_MAX - X_MIN, Y_CONTRE - Y_EXT)


## Volumes d'escamotage de l'enceinte (remplacent tour_sud_* / rempart_sud_* dans ville_v07b._classer_volumes) :
## {id, rect, h0, top, h1, spec : [{h (absolue), style}]} ; style « aucun » = pas de chapeau, sinon style de _chapeau_a.
func volumes() -> Array:
	return _vols


# ------------------------------------------------------------------------------------------------ construction
func construire() -> void:
	if not actif:
		return
	_mats()
	var d0: int = a.racine.get_child_count()
	_pied()
	_marquer(d0, "aucun")
	for s in SEGMENTS:
		_segment(float(s[0]), float(s[1]))
	for id in TOURS:
		_tour(str(id), float(TOURS[id][0]), float(TOURS[id][1]))
	_porte()
	var d1: int = a.racine.get_child_count()
	_fosse()
	_pont()
	_lices()
	a.fusionner(d1, "enceinte_fosse")
	_marquer(d1, "aucun")
	_vantaux()


## Méta « vol » des nœuds ajoutés depuis d0 (classement d'escamotage exact ; « aucun » : jamais escamoté).
func _marquer(d0: int, vol: String) -> void:
	for i in range(d0, a.racine.get_child_count()):
		var n: Node = a.racine.get_child(i)
		if n is GeometryInstance3D:
			n.set_meta("vol", vol)


## Pied permanent : escarpe et mur intérieur jusqu'au chemin de ronde (dallé), talus, cordon extérieur, souches des tours.
func _pied() -> void:
	for s in [[X_MIN, 53.0], [67.0, X_MAX]]:
		var x0: float = s[0]
		var x1: float = s[1]
		var cx := (x0 + x1) * 0.5
		var lx := x1 - x0
		a.box(Vector3(cx, (FOND + H_CHEMIN) * 0.5, (Y_INT + Y_EXT) * 0.5), Vector3(lx, H_CHEMIN - FOND, Y_EXT - Y_INT), m["mur"])
		a.box(Vector3(cx, H_CHEMIN + 0.02, (Y_INT + Y_EXT - 0.6) * 0.5), Vector3(lx, 0.04, Y_EXT - Y_INT - 0.6), m["dalle"])
		# talus de l'escarpe (deux ressauts) et cordon (larmier) au niveau du chemin de ronde
		a.box(Vector3(cx, FOND + 0.9, Y_EXT + 0.35), Vector3(lx, 1.8, 0.7), m["mur"])
		a.box(Vector3(cx, FOND + 2.25, Y_EXT + 0.15), Vector3(lx, 0.9, 0.3), m["mur"])
		a.box(Vector3(cx, H_CHEMIN - 0.1, Y_EXT + 0.08), Vector3(lx, 0.2, 0.16), m["taille"])
		# couronnement de la face intérieure (côté lices)
		a.box(Vector3(cx, H_CHEMIN - 0.06, Y_INT - 0.06), Vector3(lx, 0.12, 0.2), m["taille"])
	# retours d'angle aux extrémités (sur le fossé)
	for x in [X_MIN + 0.4, X_MAX - 0.4]:
		a.box(Vector3(x, (FOND + H_PARAPET) * 0.5, (Y_INT + Y_EXT) * 0.5 - 1.0), Vector3(0.8, H_PARAPET - FOND, Y_EXT - Y_INT + 2.0), m["mur"])
	for id in TOURS:
		var x0: float = TOURS[id][0]
		var x1: float = TOURS[id][1]
		var r := Rect2(x0, 150.0, x1 - x0, 7.0)
		a.box(Vector3(r.get_center().x, (FOND + souche_tour) * 0.5, r.get_center().y), Vector3(r.size.x, souche_tour - FOND, r.size.y), m["mur"])
		a.box(Vector3(r.get_center().x, souche_tour + 0.02, r.get_center().y), Vector3(r.size.x - 0.7, 0.04, r.size.y - 0.7), m["dalle"])
		# talus de la partie saillante (dans le fossé)
		for k in 2:
			var g := 0.6 - 0.3 * k
			a.box(Vector3(r.get_center().x, FOND + 0.8 + 1.6 * k, (Y_EXT + r.end.y + g) * 0.5), Vector3(r.size.x + 2.0 * g, 1.6, r.end.y + g - Y_EXT), m["mur"])


## Segment de courtine (volume) : parapet plein (1,2 -> 2,2) et merlons (2,2 -> 3,0), tablette ; créneaux de 0,6 m.
func _segment(x0: float, x1: float) -> void:
	var id := "enceinte_%d_%d" % [int(x0), int(x1)]
	var d0: int = a.racine.get_child_count()
	var cx := (x0 + x1) * 0.5
	var yp := Y_EXT - 0.3
	a.box(Vector3(cx, (H_CHEMIN + H_PARAPET) * 0.5, yp), Vector3(x1 - x0, H_PARAPET - H_CHEMIN, 0.6), m["mur"])
	a.box(Vector3(cx, H_PARAPET - 0.05, yp), Vector3(x1 - x0 + 0.02, 0.1, 0.7), m["taille"])
	var pas := 1.6
	var n := int(floor((x1 - x0 - 0.4) / pas))
	var marge := (x1 - x0 - n * pas) * 0.5
	for k in n:
		var xm := x0 + marge + pas * (k + 0.5)
		a.box(Vector3(xm, (H_PARAPET + H_MERLON) * 0.5, yp), Vector3(1.0, H_MERLON - H_PARAPET, 0.6), m["mur"])
		a.box(Vector3(xm, H_MERLON + 0.04, yp), Vector3(1.06, 0.08, 0.66), m["taille"])
	a.fusionner(d0, id)
	_marquer(d0, id)
	_vols.append({"id": id, "rect": Rect2(x0, Y_INT, x1 - x0, Y_EXT - Y_INT + 0.1), "h0": H_CHEMIN, "top": H_MERLON + 0.1,
		"h1": H_PARAPET, "spec": [{"h": H_PARAPET + 0.08, "style": "aucun"}]})


## Tour carrée de flanquement (emprise des données) : corps au-dessus de la souche, cordons, archères, porte vers la
## placette, glissière de herse côté passage, plate-forme dallée, parapet et merlons.
func _tour(id: String, x0: float, x1: float) -> void:
	var r := Rect2(x0, 150.0, x1 - x0, 7.0)
	var d0: int = a.racine.get_child_count()
	var c := r.get_center()
	var hs := [souche_tour, COUPES_TOUR[0], COUPES_TOUR[1], H_TOUR]
	if coupe_parapet_tour:
		hs.insert(1, H_PARAPET + 0.05)
	for k in hs.size() - 1:
		a.box(Vector3(c.x, (hs[k] + hs[k + 1]) * 0.5, c.y), Vector3(r.size.x, hs[k + 1] - hs[k], r.size.y), m["mur"])
	for h in [H_CHEMIN, H_TOUR]:
		a.box(Vector3(c.x, h - 0.1, c.y), Vector3(r.size.x + 0.24, 0.2, r.size.y + 0.24), m["taille"])
	a.box(Vector3(c.x, H_TOUR + 0.02, c.y), Vector3(r.size.x - 0.9, 0.04, r.size.y - 0.9), m["dalle"])
	# parapet (0,45 m) et merlons sur le pourtour
	var hp := H_TOUR + 0.9
	for bd in [[r.position.x, r.end.x, r.position.y, r.position.y + 0.45], [r.position.x, r.end.x, r.end.y - 0.45, r.end.y],
			[r.position.x, r.position.x + 0.45, r.position.y, r.end.y], [r.end.x - 0.45, r.end.x, r.position.y, r.end.y]]:
		a.box(Vector3((bd[0] + bd[1]) * 0.5, (H_TOUR + hp) * 0.5, (bd[2] + bd[3]) * 0.5), Vector3(bd[1] - bd[0], hp - H_TOUR, bd[3] - bd[2]), m["mur"])
	for k in 3:
		for y in [r.position.y + 0.225, r.end.y - 0.225]:
			var xm := r.position.x + 0.45 + (r.size.x - 0.9) * (k + 0.5) / 3.0
			a.box(Vector3(xm, hp + 0.35, y), Vector3(0.8, 0.7, 0.45), m["mur"])
	for k in 5:
		for x in [r.position.x + 0.225, r.end.x - 0.225]:
			var ym := r.position.y + 0.45 + (r.size.y - 0.9) * (k + 0.5) / 5.0
			a.box(Vector3(x, hp + 0.35, ym), Vector3(0.45, 0.7, 0.8), m["mur"])
	# archères (face sud et flancs saillants sur le fossé) : fente et traverse
	for h in [2.8 if coupe_parapet_tour else 2.6, 4.6]:
		a.box(Vector3(c.x, h, r.end.y + 0.01), Vector3(0.12, 1.1, 0.04), m["sombre"])
		a.box(Vector3(c.x, h + 0.15, r.end.y + 0.01), Vector3(0.4, 0.1, 0.04), m["sombre"])
		var cote := r.position.x if x0 < 60.0 else r.end.x            # flanc extérieur (côté opposé au passage)
		a.box(Vector3(cote + (-0.01 if x0 < 60.0 else 0.01), h, 156.0), Vector3(0.04, 1.1, 0.12), m["sombre"])
	# porte de la tour vers la placette (décor) : encadrement de pierre de taille, battant ferré
	a.box(Vector3(c.x, 1.15, r.position.y - 0.03), Vector3(1.0, 2.1, 0.06), m["bois"])
	for xx in [c.x - 0.62, c.x + 0.62]:
		a.box(Vector3(xx, 1.125, r.position.y - 0.06), Vector3(0.24, 2.25, 0.14), m["taille"])
	a.box(Vector3(c.x, 2.38, r.position.y - 0.06), Vector3(1.5, 0.26, 0.14), m["taille"])
	for v in [0.6, 1.7]:
		a.box(Vector3(c.x, v, r.position.y - 0.07), Vector3(0.9, 0.05, 0.02), m["fer"])
	# glissière de herse (face côté passage, au droit de la porte)
	var xg := r.end.x if x0 < 60.0 else r.position.x
	for sg in [[0.0, H_PARAPET + 0.05], [H_PARAPET + 0.05, COUPES_TOUR[0]], [COUPES_TOUR[0], 5.2]]:
		a.box(Vector3(xg + (0.01 if x0 < 60.0 else -0.01), (sg[0] + sg[1]) * 0.5, 154.6), Vector3(0.04, sg[1] - sg[0], 0.16), m["sombre"])
	a.fusionner(d0, id)
	_marquer(d0, id)
	var spec := [{"h": COUPES_TOUR[0], "style": "pierre"}, {"h": COUPES_TOUR[1], "style": "pierre"}]
	if coupe_parapet_tour:
		spec.insert(0, {"h": H_PARAPET + 0.05, "style": "pierre"})
	_vols.append({"id": id, "rect": r, "h0": souche_tour, "top": hp + 0.8, "h1": H_TOUR, "spec": spec})


## Porte voûtée entre les tours : arcades des deux faces (écoinçons, claveaux), voûte en berceau, herse relevée, chemin de
## ronde à 5,4 m avec parapet crénelé au sud et garde-corps plein au nord.
func _porte() -> void:
	var id := "porte_sud_voute"
	var d0: int = a.racine.get_child_count()
	var x0 := 57.0
	var x1 := 63.0
	var R := 3.0
	var naiss := H_PORTE - 0.25 - R
	var fs := {"o": Vector3(x0, 0, Y_EXT), "t": Vector3(1, 0, 0), "n": Vector3(0, 0, 1), "L": 6.0}
	var fn := {"o": Vector3(x1, 0, Y_INT), "t": Vector3(-1, 0, 0), "n": Vector3(0, 0, -1), "L": 6.0}
	for f in [fs, fn]:
		var fm := {"o": f["o"] + f["t"] * 3.0, "t": f["t"], "n": f["n"], "L": 0.0}
		fi._arcade(fm, 0.0, H_PORTE, 6.72, 0.0, m["mur"], m["taille"])
	# voûte (berceau) entre les deux faces : tranches suivant l'intrados
	var nt := 8
	for k in nt:
		var u0 := -R + 2.0 * R * float(k) / nt
		var u1 := -R + 2.0 * R * float(k + 1) / nt
		var um := maxf(absf(u0), absf(u1))
		var hi := naiss + sqrt(maxf(0.0, R * R - um * um))
		var hz := [hi, H_PORTE] if hi >= COUPES_PORTE[0] else [hi, COUPES_PORTE[0], H_PORTE]
		for j in hz.size() - 1:
			a.box(Vector3(60.0 + (u0 + u1) * 0.5, (hz[j] + hz[j + 1]) * 0.5, (Y_INT + Y_EXT) * 0.5), Vector3(u1 - u0, hz[j + 1] - hz[j], Y_EXT - Y_INT - 0.7), m["mur"])
	# herse relevée : bas de la grille sous la clé
	var yh := Y_EXT - 0.45
	a.box(Vector3(60.0, naiss + R - 0.35, yh), Vector3(2.6, 0.08, 0.08), m["fer"])
	for k in 9:
		var u := -1.2 + 2.4 * float(k) / 8.0
		var hb := naiss + sqrt(maxf(0.0, R * R - u * u)) - 0.05
		a.box(Vector3(60.0 + u, hb - 0.3, yh), Vector3(0.06, 0.6, 0.06), m["fer"])
	# chemin de ronde de la porte, parapet crénelé (sud) et garde-corps plein (nord)
	a.box(Vector3(60.0, H_PORTE + 0.02, (Y_INT + Y_EXT) * 0.5), Vector3(6.0, 0.04, 1.8), m["dalle"])
	a.box(Vector3(60.0, H_PORTE - 0.1, Y_EXT + 0.08), Vector3(6.2, 0.2, 0.16), m["taille"])
	a.box(Vector3(60.0, H_PORTE + 0.45, Y_EXT - 0.3), Vector3(6.0, 0.9, 0.6), m["mur"])
	a.box(Vector3(60.0, H_PORTE + 0.45, Y_INT + 0.2), Vector3(6.0, 0.9, 0.4), m["mur"])
	for k in 4:
		var xm := x0 + 0.75 + 1.5 * k
		a.box(Vector3(xm, H_PORTE + 1.25, Y_EXT - 0.3), Vector3(0.9, 0.7, 0.6), m["mur"])
	a.fusionner(d0, id)
	_marquer(d0, id)
	_vols.append({"id": id, "rect": Rect2(x0, Y_INT, x1 - x0, Y_EXT - Y_INT), "h0": 0.0, "top": H_PORTE + 1.7, "h1": H_PORTE,
		"ouverture": {"x0": x0, "x1": x1, "naiss": naiss},
		"spec": [{"h": COUPES_PORTE[0], "style": "aucun"}, {"h": COUPES_PORTE[1], "style": "aucun"}]})


## Fossé sec : fond herbeux, contrescarpe maçonnée (et sa tablette), murs d'extrémité.
func _fosse() -> void:
	var r := trou_fosse()
	var c := r.get_center()
	var fond: MeshInstance3D = a.box(Vector3(c.x, FOND - 0.15, c.y), Vector3(r.size.x, 0.3, r.size.y), m["herbe"])
	fond.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	a.box(Vector3(c.x, FOND * 0.5, Y_CONTRE + 0.3), Vector3(r.size.x, -FOND, 0.6), m["mur"])
	a.box(Vector3(c.x, 0.04, Y_CONTRE + 0.3), Vector3(r.size.x, 0.08, 0.7), m["taille"])
	for x in [r.position.x - 0.3, r.end.x + 0.3]:
		a.box(Vector3(x, FOND * 0.5, c.y), Vector3(0.6, -FOND, r.size.y), m["mur"])


## Pont dormant (x 56,55 -> 63,45) : culée et pile maçonnées, arche en plein cintre sous le tablier, tablier dallé de
## y 162 à la contrescarpe (la route praticable des données couvre 156 -> 162), parapets bas.
func _pont() -> void:
	var x0 := 56.55
	var x1 := 63.45
	var cx := (x0 + x1) * 0.5
	var lx := x1 - x0
	var y0 := 157.0                        # bout des tours
	var y1 := Y_CONTRE
	var ra := 2.4
	var yc := (y0 + y1) * 0.5
	var naiss := -0.45 - ra
	# piédroits de l'arche (contre les tours et contre la contrescarpe) et tympans au-dessus de l'intrados
	a.box(Vector3(cx, (FOND + 0.0) * 0.5, (Y_EXT + yc - ra) * 0.5), Vector3(lx, -FOND, yc - ra - Y_EXT), m["mur"])
	a.box(Vector3(cx, (FOND + 0.0) * 0.5, (yc + ra + y1) * 0.5), Vector3(lx, -FOND, y1 - yc - ra), m["mur"])
	var nt := 8
	for k in nt:
		var t0 := -ra + 2.0 * ra * float(k) / nt
		var t1 := -ra + 2.0 * ra * float(k + 1) / nt
		var tm := maxf(absf(t0), absf(t1))
		var hi := naiss + sqrt(maxf(0.0, ra * ra - tm * tm))
		a.box(Vector3(cx, (hi + 0.0) * 0.5, yc + (t0 + t1) * 0.5), Vector3(lx, -hi, t1 - t0), m["mur"])
	# claveaux de l'arche sur les deux têtes
	for xs in [x0 - 0.04, x1 + 0.04]:
		for k in 9:
			var t := PI * (k + 0.5) / 9.0
			var mb: MeshInstance3D = a.box(Vector3(xs, naiss + sin(t) * (ra + 0.15), yc - cos(t) * (ra + 0.15)), Vector3(0.08, 0.3, PI * (ra + 0.15) / 9.0 + 0.02), m["taille"])
			mb.rotation.x = -(PI * 0.5 - t)
	# tablier (de la route des données au bord sud) et parapets
	a.box(Vector3(cx, -0.15, (162.0 + y1 + 0.6) * 0.5), Vector3(lx - 0.9, 0.3, y1 + 0.6 - 162.0), fi.dallage(0.0))
	for xp in [x0 + 0.22, x1 - 0.22]:
		a.box(Vector3(xp, 0.45, (y0 + y1 + 0.6) * 0.5), Vector3(0.44, 0.9, y1 + 0.6 - y0), m["mur"])
		a.box(Vector3(xp, 0.95, (y0 + y1 + 0.6) * 0.5), Vector3(0.52, 0.1, y1 + 0.6 - y0), m["taille"])


## Lices : muret de 0,55 m fermant la bande entre la placette et la courtine (x 48 -> 53, 67 -> 72) ; escaliers d'accès au
## chemin de ronde contre la courtine (7 marches), de part et d'autre de la porte.
func _lices() -> void:
	for s in [[48.0, 53.0], [67.0, 72.0]]:
		var cx: float = (float(s[0]) + float(s[1])) * 0.5
		a.box(Vector3(cx, 0.275, 150.2), Vector3(float(s[1]) - float(s[0]), 0.55, 0.3), m["mur"])
		a.box(Vector3(cx, 0.59, 150.2), Vector3(float(s[1]) - float(s[0]) + 0.04, 0.08, 0.38), m["taille"])
	for sp in [[52.9, -1.0], [67.1, 1.0]]:
		var xh: float = sp[0]
		var sens: float = sp[1]
		for k in 7:
			var hk := H_CHEMIN * float(k + 1) / 7.0
			var xk := xh + sens * (0.85 * float(6 - k) + 0.425)
			a.box(Vector3(xk, hk * 0.5, 151.3), Vector3(0.85, hk, 1.3), m["mur"])
			a.box(Vector3(xk, hk - 0.03, 151.3), Vector3(0.87, 0.06, 1.34), m["taille"])


## Vantaux ouverts contre les parois du passage (bois ferré, 4,2 m) : jamais escamotés (au sol, contre les murs).
func _vantaux() -> void:
	var d0: int = a.racine.get_child_count()
	for xs in [57.07, 62.93]:
		a.box(Vector3(xs, 2.1, 153.6), Vector3(0.1, 4.2, 2.9), m["bois"])
		for v in [0.6, 2.1, 3.6]:
			a.box(Vector3(xs + (0.06 if xs < 60.0 else -0.06), v, 153.6), Vector3(0.03, 0.09, 2.8), m["fer"])
	a.fusionner(d0, "porte_sud_vantaux")
	_marquer(d0, "aucun")
