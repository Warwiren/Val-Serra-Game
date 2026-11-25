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

## P7.7 : les composants (matières, façades, baies, balcons, toits) sont dans la bibliothèque scenes/p7/archi_p77.gd ;
## cette tranche n'en garde que les descriptions, les sols, l'escalier et le muret (rendu identique à P7.6).
const Archi := preload("res://scenes/p7/archi_p77.gd")

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

const PIERRE_VILLE := Archi.PIERRE_VILLE
var b                 # constructeur de la ville (scenes/p7/ville_v07b.gd)
var sc                # scène (colisee.gd)
var a                 # composants (Archi), maillages sous sc.root
var rects := {}       # emprises des bâtiments de la tranche (portes des données posées sur leurs façades)


func _init(builder) -> void:
	b = builder
	sc = builder.sc
	a = Archi.new(sc.root)
	a.fusion = str(sc._cli.get("fusion", "1")) != "0"


func actif() -> bool:
	return str(sc._cli.get("tranche", "1")) != "0"


func contient(id: String) -> bool:
	return actif() and BATIMENTS.has(id)


# ------------------------------------------------------------------------------------------------ délégations
func macon(nom: String, teinte := Color.WHITE, base_y := 0.0, uv := "monde", hole := true) -> ShaderMaterial:
	return a.macon(nom, teinte, base_y, uv, hole)


func plein(c: Color, rough := 0.85, emission := 0.0, metal := 0.0) -> StandardMaterial3D:
	return a.plein(c, rough, emission, metal)


func moulure() -> ShaderMaterial:
	return a.moulure()


func face(r: Rect2, cote: String) -> Dictionary:
	return Archi.face(r, cote)


func baie(f: Dictionary, u: float, v0: float, w: float, h: float, style: String, c_volets: Color) -> void:
	a.baie(f, u, v0, w, h, style, c_volets)


func batiment(id: String, r: Rect2, h0: float, _h1: float) -> void:
	rects[id] = r
	var d: Dictionary = BATIMENTS[id].duplicate()
	d["id"] = id
	a.batiment(r, h0, d)


# ------------------------------------------------------------------------------------------------ sols et escalier
## Sols de la tranche : dallage enrichi du Colisée ; caniveau central dans la ruelle ; bordure au raccord avec la place.
func sol(id: String, r: Rect2, h: float) -> void:
	var depuis: int = sc.root.get_child_count()
	var th := 0.3
	var mi: MeshInstance3D = a.box(Archi.centre(r, h - th, h), Vector3(r.size.x, th, r.size.y), macon("dallage2", Color(1.04, 1.02, 1.0), h, "monde", false))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if id == "ruelle":
		a.box(Vector3(r.get_center().x, h + 0.004, r.get_center().y), Vector3(0.36, 0.01, r.size.y), macon("dalle", Color(0.72, 0.7, 0.68), h, "monde", false))
	if id == "place_bras_est":
		# bordure de pierre : seuil entre la grande place (blockout) et la tranche
		a.box(Vector3(r.position.x + 0.2, h + 0.006, r.get_center().y), Vector3(0.4, 0.012, r.size.y), moulure())
	a.fusionner(depuis, "sol_" + id)

## Escalier de la ruelle : marches de dalles et contremarches de pierre ; murs d'échiffre en gradins le long des deux
## façades (ils portent la montée) ; collisions identiques à celles du socle (ville_v06._escalier).
func escalier(e: Dictionary) -> void:
	var depuis: int = sc.root.get_child_count()
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
		a.box(Vector3(r.get_center().x, (e["h0"] + top - 0.06) / 2.0, (y0 + y1) / 2.0), Vector3(r.size.x - 0.24, top - 0.06 - e["h0"], y1 - y0), mc)
		a.box(Vector3(r.get_center().x, top - 0.03, (y0 + y1) / 2.0 + 0.02), Vector3(r.size.x - 0.24, 0.06, y1 - y0 + 0.04), md)
		# murs d'échiffre : un gradin par marche, 0,9 m au-dessus du giron, de part et d'autre
		for xj in [r.position.x + 0.06, r.end.x - 0.06]:
			a.box(Vector3(xj, (e["h0"] + top + 0.9) / 2.0, (y0 + y1) / 2.0), Vector3(0.12, top + 0.9 - e["h0"], y1 - y0), pierre)
			a.box(Vector3(xj, top + 0.93, (y0 + y1) / 2.0), Vector3(0.2, 0.06, y1 - y0), moulure())
	a.box(Vector3(r.get_center().x, e["h1"] / 2.0, (r.position.y + yt) / 2.0), Vector3(r.size.x, e["h1"], yt - r.position.y), md)
	a.fusionner(depuis, "escalier")
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


## Muret bas (bord de rue côté caméra, 0,6 m validé) : appareil de soubassement, chaperon de pierre, jardinière plantée
## (P7.7 : composant Archi.jardiniere, à la place de la haie uniforme de P7.6).
func muret(r: Rect2, h0: float, h1: float) -> void:
	var depuis: int = sc.root.get_child_count()
	a.box(Archi.centre(r, h0, h1 - 0.12), Vector3(r.size.x, h1 - 0.12 - h0, r.size.y), macon("socle2", PIERRE_VILLE, h0))
	a.box(Archi.centre(r.grow(0.06), h1 - 0.12, h1), Vector3(r.size.x + 0.12, 0.12, r.size.y + 0.12), moulure())
	if str(sc._cli.get("muret", "jardin")) == "haie":
		_haie_p76(r, h1)
		return
	a.jardiniere(r, h1)
	a.fusionner(depuis, "muret")


## Haie uniforme de P7.6 (comparaison : --muret=haie).
func _haie_p76(r: Rect2, h1: float) -> void:
	var terre := plein(Color(0.30, 0.26, 0.19))
	var vert := plein(Color(0.27, 0.36, 0.20))
	var ri := r.grow(-0.45)
	a.box(Archi.centre(ri, h1 - 0.02, h1 + 0.02), Vector3(ri.size.x, 0.04, ri.size.y), terre)
	var x := ri.position.x
	var k := 0
	while x < ri.end.x - 0.1:
		var lg := minf(2.4, ri.end.x - x)
		var ht := 0.55 if k % 2 == 0 else 0.7
		a.box(Vector3(x + lg * 0.5, h1 + ht * 0.5, ri.position.y + 0.55), Vector3(lg - 0.05, ht, 1.0), vert)
		x += lg
		k += 1
