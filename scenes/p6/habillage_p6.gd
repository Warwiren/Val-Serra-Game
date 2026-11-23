extends RefCounted
## P6.1 — PILOTE D'HABILLAGE du Colisée, uniquement avec les ressources déjà présentes dans le dépôt :
##   - lumière et tonalité rapprochées de la forêt V07B (tonalité filmique, ambiance plus basse, soleil chaud, ciel) ;
##   - ARÈNE : sable (texture terre_chemin de P5.3-B), bande de sable tassé au pied du podium, podium avec chaperon,
##     pilastres, bannières et braseros, gradins avec assises en bois et escaliers, colonnade haute au nord, arcs des
##     accès combattants, loge officielle à colonnes et dais ;
##   - VESTIAIRES (intérieur pilote) : plinthes et poutres, casiers à portes, bancs en planches, râtelier garni,
##     accessoires peints de l'avant-poste (tonneaux, caisses, sacs, bûches, lanternes, bannière), tapis ;
##   - EXTÉRIEUR : parvis pavé et façade extérieure du Colisée, silhouettes de bâtiments lointains (aucun vide noir).
## Aucune collision, surface praticable ni donnée de jeu n'est modifiée : tout est décor (sans corps physique), sauf
## les objets posés là où un meuble des données existait déjà (même emprise).
## Le blockout P6 reste disponible (touche H : pilote / blockout).

const SURF_SH = preload("res://src/p4/surface_p4.gdshader")
const SABLE := "res://art/p53/sol_v2/terre_chemin.png"
const PIERRE := "res://art/p4/batiment/pierre_taille.png"
const PAVES := "res://art/p4/mat/sol_paves.png"
const PLANCHES := "res://art/p4/pont/planches.png"
const FACADE := "res://art/p4/batiment/facade_colombage.png"
const TOIT := "res://art/p4/batiment/toit_violet.png"
const C_CALCAIRE := Color(1.06, 0.98, 0.86)          # pierre de taille réchauffée (le gris-violet venait de la lumière)
const C_GUILDE := Color(0.2, 0.28, 0.62)
const C_OR := Color(0.86, 0.68, 0.3)

var sc                                    # scène du Colisée (méthodes d'aide : _box_mesh, _faces, _card, _light…)
var _mats := {}
## P6.4 : pilote de direction artistique (touche M, -- --p64=0 : état P6.3.2 pour comparaison)
var p64 := true
## P6.4.1 : second pilote (matières hybrides) et variante de la galerie ("p64" : premier pilote, "A", "B")
var pilote2 := true
var galerie := "A"
## P6.4.2 : extension des choix retenus (matières hybrides, galerie B, porte C, lumière des accès) à tout le Colisée,
## avec une ambiance de matière par zone (P642_ZONES). false : pilotes P6.4 / P6.4.1 tels quels (touche M).
var extension := false
## P6.4.3 : calque du sable de l'arène (variations, traces d'usage, cercle d'évaluation ; -- --sable=0 : sans)
var sable_calque := true
const SABLE_SH = preload("res://src/p6/sable_p643.gdshader")
const MACON_SH = preload("res://src/p6/maconnerie_p64.gdshader")
const GRAIN := "res://art/p4/mat/roche.png"
## P6.4 : zones pilotes des matériaux (le reste du Colisée garde les matières P6.3.2)
const P64_MURS := ["cmur_vestiaires_n0", "cmur_vestiaires_n1", "cmur_coursive_n0", "cmur_coursive_n1", "cmur_coursive_o0", "cmur_coursive_o1"]
const P64_SOLS := ["coursive"]
const P64_GRADINS := [95.0, 185.0]          # portion de gradins pilote (degrés, sens de construction : sud-ouest)


func _init(scene) -> void:
	sc = scene


func mat(path: String, tile: float, tint: Color, hole := false, antitile := false) -> ShaderMaterial:
	var k := "%s|%s|%s|%s" % [path, tile, tint, hole]
	if _mats.has(k):
		return _mats[k]
	var m := ShaderMaterial.new()
	m.shader = SURF_SH
	m.set_shader_parameter("tex", load(path))
	m.set_shader_parameter("tile_m", tile)
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("hole", 1.0 if hole else 0.0)
	m.set_shader_parameter("antitile", 1.0 if antitile else 0.0)
	m.set_shader_parameter("macro", 0.06)
	_mats[k] = m
	return m


## P6.4 : matériaux procéduraux du pilote (src/p6/maconnerie_p64.gdshader). nom : préréglage ; uv : "monde" ou
## "maillage" (UV du maillage en mètres × uv_m).
const P64_PRESETS := {
	# appareil de calcaire des murs : assises inégales, deux familles de pierre (ocre doré / gris chaud)
	"mur": {"motif": 0, "assises": Vector3(0.42, 0.30, 0.36), "long_bloc": 0.95, "var_long": 0.4, "joint": 0.016,
		"couleur": Color(0.63, 0.55, 0.45), "couleur2": Color(0.56, 0.53, 0.49), "c_joint": Color(0.24, 0.20, 0.18),
		"var_teinte": 0.2, "part2": 0.32, "salissure": 0.38, "coulures": 0.3, "mousse": 0.16, "usure": 0.35},
	"mur_haut": {"motif": 0, "assises": Vector3(0.42, 0.30, 0.36), "long_bloc": 0.95, "var_long": 0.4, "joint": 0.011,
		"couleur": Color(0.52, 0.46, 0.40), "couleur2": Color(0.46, 0.43, 0.40), "c_joint": Color(0.24, 0.21, 0.19),
		"var_teinte": 0.09, "part2": 0.3, "salissure": 0.0, "coulures": 0.35, "mousse": 0.0, "usure": 0.3},
	"mur_sombre": {"motif": 0, "assises": Vector3(0.42, 0.30, 0.36), "long_bloc": 0.95, "var_long": 0.4, "joint": 0.011,
		"couleur": Color(0.36, 0.32, 0.29), "couleur2": Color(0.32, 0.30, 0.29), "c_joint": Color(0.17, 0.15, 0.14),
		"var_teinte": 0.08, "part2": 0.3, "salissure": 0.0, "coulures": 0.3, "mousse": 0.0, "usure": 0.3},
	# moulures (corniche, bandeau, chaperon) : grands blocs clairs, joints fins, peu salis
	"moulure": {"motif": 0, "assises": Vector3(0.3, 0.3, 0.3), "long_bloc": 1.25, "var_long": 0.3, "joint": 0.008,
		"couleur": Color(0.62, 0.56, 0.47), "couleur2": Color(0.58, 0.54, 0.48), "c_joint": Color(0.45, 0.40, 0.35),
		"var_teinte": 0.12, "part2": 0.3, "salissure": 0.0, "coulures": 0.2, "mousse": 0.0, "usure": 0.45},
	# soubassement : gros blocs plus sombres, très salis au pied
	"socle": {"motif": 0, "assises": Vector3(0.5, 0.5, 0.5), "long_bloc": 1.2, "var_long": 0.35, "joint": 0.012,
		"couleur": Color(0.47, 0.43, 0.39), "couleur2": Color(0.43, 0.41, 0.39), "c_joint": Color(0.27, 0.24, 0.22),
		"var_teinte": 0.09, "part2": 0.35, "salissure": 0.5, "coulures": 0.1, "mousse": 0.3, "usure": 0.5},
	# contremarches des gradins : deux assises par marche
	"gradin": {"motif": 0, "assises": Vector3(0.28, 0.27, 0.28), "long_bloc": 1.05, "var_long": 0.35, "joint": 0.01,
		"couleur": Color(0.58, 0.51, 0.42), "couleur2": Color(0.52, 0.49, 0.45), "c_joint": Color(0.22, 0.19, 0.17),
		"var_teinte": 0.18, "part2": 0.3, "salissure": 0.15, "coulures": 0.15, "mousse": 0.1, "usure": 0.4},
	# dalles des marches et du chaperon (dessus) : longues dalles, bords usés
	"dalle": {"motif": 1, "assises": Vector3(0.46, 0.46, 0.46), "long_bloc": 1.15, "var_long": 0.35, "joint": 0.01,
		"couleur": Color(0.66, 0.60, 0.50), "couleur2": Color(0.62, 0.58, 0.51), "c_joint": Color(0.34, 0.30, 0.26),
		"var_teinte": 0.08, "part2": 0.2, "salissure": 0.0, "coulures": 0.0, "mousse": 0.12, "usure": 0.5},
	# assises de bois des gradins : lames le long de l'arc
	"bois": {"motif": 2, "assises": Vector3(0.115, 0.11, 0.115), "long_bloc": 2.6, "var_long": 0.35, "joint": 0.005,
		"couleur": Color(0.48, 0.32, 0.21), "couleur2": Color(0.41, 0.29, 0.21), "c_joint": Color(0.16, 0.11, 0.08),
		"var_teinte": 0.12, "part2": 0.4, "salissure": 0.0, "coulures": 0.0, "mousse": 0.0, "usure": 0.4},
	# dallage de la coursive : grandes dalles gris ocre, joints sombres, usure au centre des dalles
	"dallage": {"motif": 1, "assises": Vector3(0.62, 0.5, 0.56), "long_bloc": 0.85, "var_long": 0.4, "joint": 0.012,
		"couleur": Color(0.56, 0.50, 0.43), "couleur2": Color(0.50, 0.44, 0.39), "c_joint": Color(0.19, 0.17, 0.16),
		"var_teinte": 0.22, "part2": 0.45, "salissure": 0.0, "coulures": 0.0, "mousse": 0.16, "usure": 0.45},
	# tuiles canal de la galerie (terre cuite, rangs de 32 cm)
	"tuiles": {"motif": 3, "assises": Vector3(0.32, 0.30, 0.33), "long_bloc": 0.2, "var_long": 0.12, "joint": 0.008,
		"couleur": Color(0.50, 0.31, 0.23), "couleur2": Color(0.43, 0.30, 0.25), "c_joint": Color(0.2, 0.12, 0.1),
		"var_teinte": 0.22, "part2": 0.4, "salissure": 0.0, "coulures": 0.0, "mousse": 0.3, "usure": 0.2},
	# P6.4.1 : mur des vestiaires retenu comme base + détails picturaux discrets (salissures et mousse peintes,
	# quelques pierres de réparation et fissures)
	"mur2": {"motif": 0, "assises": Vector3(0.42, 0.30, 0.36), "long_bloc": 0.95, "var_long": 0.4, "joint": 0.016,
		"couleur": Color(0.63, 0.55, 0.45), "couleur2": Color(0.56, 0.53, 0.49), "c_joint": Color(0.24, 0.20, 0.18),
		"var_teinte": 0.2, "part2": 0.32, "salissure": 0.3, "coulures": 0.3, "mousse": 0.08, "usure": 0.35,
		"irregulier": 0.12, "fissures": 0.05, "rapieces": 0.06, "k_terre": 0.72, "k_mousse": 0.38},
	"mur_haut2": {"motif": 0, "assises": Vector3(0.42, 0.30, 0.36), "long_bloc": 0.95, "var_long": 0.4, "joint": 0.011,
		"couleur": Color(0.52, 0.46, 0.40), "couleur2": Color(0.46, 0.43, 0.40), "c_joint": Color(0.24, 0.21, 0.19),
		"var_teinte": 0.12, "part2": 0.3, "salissure": 0.0, "coulures": 0.3, "mousse": 0.0, "usure": 0.3,
		"irregulier": 0.1, "rapieces": 0.05, "k_terre": 0.68, "k_mousse": 0.0},
	"socle2": {"motif": 0, "assises": Vector3(0.5, 0.5, 0.5), "long_bloc": 1.2, "var_long": 0.35, "joint": 0.012,
		"couleur": Color(0.47, 0.43, 0.39), "couleur2": Color(0.43, 0.41, 0.39), "c_joint": Color(0.27, 0.24, 0.22),
		"var_teinte": 0.12, "part2": 0.35, "salissure": 0.4, "coulures": 0.1, "mousse": 0.15, "usure": 0.5,
		"irregulier": 0.2, "fissures": 0.05, "k_terre": 0.6, "k_mousse": 0.4},
	# P6.4.1 : dallage enrichi : dalles recoupées et de tailles inégales, joints taillés irréguliers, dalles gauchies,
	# fissures, pierres de réparation ; salissure et mousse peintes dans les joints et par plaques
	"dallage2": {"motif": 1, "assises": Vector3(0.58, 0.46, 0.66), "long_bloc": 0.82, "var_long": 0.5, "joint": 0.013,
		"couleur": Color(0.56, 0.50, 0.43), "couleur2": Color(0.49, 0.45, 0.41), "c_joint": Color(0.18, 0.16, 0.15),
		"var_teinte": 0.17, "part2": 0.42, "salissure": 0.0, "coulures": 0.0, "mousse": 0.1, "usure": 0.5,
		"irregulier": 1.0, "fissures": 0.07, "rapieces": 0.05, "k_terre": 0.55, "k_mousse": 0.3},
	# P6.4.1 A : petites tuiles canal (rangs de 20 cm, tuiles de 13 cm), terre cuite sombre et rompue, lichen
	"tuiles_a": {"motif": 3, "assises": Vector3(0.2, 0.19, 0.21), "long_bloc": 0.13, "var_long": 0.14, "joint": 0.006,
		"couleur": Color(0.40, 0.27, 0.21), "couleur2": Color(0.35, 0.29, 0.26), "c_joint": Color(0.16, 0.11, 0.09),
		"var_teinte": 0.2, "part2": 0.45, "salissure": 0.0, "coulures": 0.0, "mousse": 0.2, "usure": 0.25, "valeur": 0.85,
		"desordre": 1.0, "k_terre": 0.0, "k_mousse": 0.25},
	# P6.4.2 : planchers (lames de 18 à 22 cm le long de x, joints sombres, crasse peinte dans les joints)
	"plancher": {"motif": 2, "assises": Vector3(0.2, 0.18, 0.22), "long_bloc": 2.3, "var_long": 0.45, "joint": 0.006,
		"couleur": Color(0.50, 0.33, 0.22), "couleur2": Color(0.44, 0.31, 0.23), "c_joint": Color(0.13, 0.09, 0.07),
		"var_teinte": 0.13, "part2": 0.4, "salissure": 0.0, "coulures": 0.0, "mousse": 0.0, "usure": 0.45,
		"rapieces": 0.04, "k_terre": 0.45, "k_mousse": 0.0},
	# P6.4.2 : pavage des tunnels : pierres plus petites, très usées, crasse dans les joints (passage des combattants)
	"dallage_tunnel": {"motif": 1, "assises": Vector3(0.42, 0.34, 0.46), "long_bloc": 0.58, "var_long": 0.45, "joint": 0.013,
		"couleur": Color(0.52, 0.46, 0.40), "couleur2": Color(0.46, 0.42, 0.39), "c_joint": Color(0.15, 0.13, 0.12),
		"var_teinte": 0.17, "part2": 0.42, "salissure": 0.0, "coulures": 0.0, "mousse": 0.08, "usure": 0.7,
		"irregulier": 1.0, "fissures": 0.08, "rapieces": 0.05, "k_terre": 0.7, "k_mousse": 0.25},
	# contreforts et façades de la galerie : gros appareil, plus gris
	"contrefort": {"motif": 0, "assises": Vector3(0.48, 0.40, 0.44), "long_bloc": 1.0, "var_long": 0.3, "joint": 0.012,
		"couleur": Color(0.55, 0.50, 0.43), "couleur2": Color(0.50, 0.48, 0.45), "c_joint": Color(0.31, 0.27, 0.24),
		"var_teinte": 0.18, "part2": 0.35, "salissure": 0.42, "coulures": 0.35, "mousse": 0.2, "usure": 0.45},
}


## P6.4.1 : matières du second pilote (hybride : calepinage procédural + détails peints), substituées à celles du
## premier pilote quand `pilote2` est actif
const P641_VARIANTES := {"mur": "mur2", "mur_haut": "mur_haut2", "dallage": "dallage2", "socle": "socle2"}
const PEINT_TERRE := "res://art/p4/mat/sol_terre.png"
const PEINT_MOUSSE := "res://art/p4/mat/sol_herbe.png"


func m64(nom: String, uv := "monde", uv_m := 1.0, hole := false, teinte := Color.WHITE) -> ShaderMaterial:
	if pilote2 and P641_VARIANTES.has(nom):
		nom = P641_VARIANTES[nom]
	var k := "p64|%s|%s|%s|%s|%s" % [nom, uv, uv_m, hole, teinte]
	if _mats.has(k):
		return _mats[k]
	var m := _macon(P64_PRESETS[nom], uv, uv_m, hole, teinte)
	_mats[k] = m
	return m


## P6.4.2 : ambiance des matières par zone. Les calepinages restent ceux des pilotes (mur des vestiaires, dallage
## enrichi) ; seuls changent la palette, la valeur, l'usure et la salissure, selon la fonction de chaque espace.
##   teinte : multiplie les deux familles de pierre ; valeur : multiplie la valeur générale ; sal / mousse / coul :
##   multiplient salissure (et salissure peinte), mousse (et mousse peinte), coulures ; rap / fis : s'ajoutent aux
##   pierres de réparation et aux fissures ; sol : préréglage du sol de la zone.
const P642_ZONES := {
	# référence : mur des vestiaires du second pilote (inchangé), plancher chaud
	"vestiaires": {"sol": "plancher"},
	# intérieur de service, plus neutre et plus propre ; dallage enrichi
	"salle": {"teinte": Color(0.98, 0.97, 0.97), "sal": 0.85, "mousse": 0.4, "sol": "dallage"},
	# passage sous les gradins : plus sombre, suie et humidité (coulures, pied verdi), pavage très usé
	"tunnel": {"valeur": 0.84, "teinte": Color(0.96, 0.93, 0.9), "sal": 1.45, "coul": 1.6, "mousse": 1.5, "fis": 0.03, "sol": "dallage_tunnel"},
	# à ciel ouvert : pierre plus claire et plus chaude, lavée par la pluie (coulures), peu de crasse
	"arene": {"valeur": 1.06, "teinte": Color(1.04, 1.0, 0.93), "sal": 0.75, "coul": 1.35, "mousse": 0.9, "fis": 0.03},
	# référence : coursive du second pilote (inchangée)
	"coursive": {"sol": "dallage"},
	# soins : pierre plus claire, entretenue (presque pas de crasse ni de mousse), plancher clair récuré
	"infirmerie": {"valeur": 1.07, "teinte": Color(1.06, 1.05, 1.02), "sal": 0.45, "coul": 0.5, "mousse": 0.15, "sol": "plancher",
		"sol_teinte": Color(1.18, 1.14, 1.08), "sol_sal": 0.5},
	# réserve : brute, poussiéreuse, réparée ; plancher sombre
	"reserve": {"valeur": 0.92, "teinte": Color(0.97, 0.94, 0.9), "sal": 1.25, "mousse": 0.6, "rap": 0.06, "fis": 0.04, "sol": "plancher",
		"sol_teinte": Color(0.82, 0.8, 0.78), "sol_sal": 1.5},
	# couloir de sortie : proche de la rue, un peu plus exposé (coulures, mousse)
	"sortie": {"teinte": Color(1.0, 0.98, 0.95), "coul": 1.25, "mousse": 1.15, "sol": "dallage"},
}
## pièce des données (id des murs « cmur_<pièce>_<côté><n> », id des sols) -> zone de matière
const P642_PIECES := {"vestiaires": "vestiaires", "passage_vestiaires": "vestiaires", "salle_attente": "salle",
	"tunnel_sud": "tunnel", "tunnel_est": "tunnel", "coursive": "coursive", "passage_infirmerie": "infirmerie",
	"infirmerie": "infirmerie", "reserve": "reserve", "couloir_sortie": "sortie", "arene": "arene"}
## secteur de la visibilité -> zone de matière (éléments posés entre deux pièces : linteaux)
const P642_SECTEURS := {"S1": "vestiaires", "P12": "vestiaires", "S2": "salle", "S3": "tunnel", "S4": "arene",
	"S5": "tunnel", "S6": "coursive", "S7": "infirmerie", "S8": "reserve", "S9": "sortie"}


func zone_piece(id: String) -> String:
	var p := id.trim_prefix("cmur_").trim_prefix("meuble_")
	var best := ""
	for k in P642_PIECES:
		if p.begins_with(k) and (k as String).length() > best.length():
			best = k
	return P642_PIECES.get(best, "coursive")


## Zone d'un point du plan : secteur qui le contient, sinon le plus proche (éléments posés dans l'épaisseur d'un mur).
func zone_en(xz: Vector2) -> String:
	var best := "coursive"
	var dmin := INF
	for sd in sc._p6.get("secteurs", []):
		for q in sd["rects"]:
			var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
			var d := xz.distance_to(Vector2(clampf(xz.x, r.position.x, r.end.x), clampf(xz.y, r.position.y, r.end.y)))
			if d < dmin:
				dmin = d
				best = P642_SECTEURS.get(sd["id"], "coursive")
	return best


func mz(nom: String, zone: String, uv := "monde", uv_m := 1.0, hole := false, teinte := Color.WHITE) -> ShaderMaterial:
	if P641_VARIANTES.has(nom):
		nom = P641_VARIANTES[nom]
	var k := "pz|%s|%s|%s|%s|%s|%s" % [nom, zone, uv, uv_m, hole, teinte]
	if _mats.has(k):
		return _mats[k]
	var z: Dictionary = P642_ZONES.get(zone, {})
	var d: Dictionary = P64_PRESETS[nom].duplicate()
	var sol: bool = int(d["motif"]) == 1 or nom.begins_with("plancher")
	var tz: Color = z.get("sol_teinte" if sol and z.has("sol_teinte") else "teinte", Color.WHITE)
	d["couleur"] = (d["couleur"] as Color) * tz
	d["couleur2"] = (d["couleur2"] as Color) * tz
	d["valeur"] = float(d.get("valeur", 0.8)) * float(z.get("valeur", 1.0))
	var ks: float = z.get("sol_sal" if sol and z.has("sol_sal") else "sal", 1.0)
	d["salissure"] = float(d["salissure"]) * ks
	d["k_terre"] = minf(float(d.get("k_terre", 0.0)) * ks, 0.95)
	d["mousse"] = float(d["mousse"]) * float(z.get("mousse", 1.0))
	d["k_mousse"] = float(d.get("k_mousse", 0.0)) * float(z.get("mousse", 1.0))
	d["coulures"] = float(d["coulures"]) * float(z.get("coul", 1.0))
	if int(d["motif"]) != 3:
		d["rapieces"] = float(d.get("rapieces", 0.0)) + float(z.get("rap", 0.0))
		d["fissures"] = float(d.get("fissures", 0.0)) + float(z.get("fis", 0.0))
	var m := _macon(d, uv, uv_m, hole, teinte)
	_mats[k] = m
	return m


## Matière de pilote : par zone en P6.4.2 (extension), celle des pilotes sinon (comparaison, touche M).
func mm(nom: String, zone: String, uv := "monde", uv_m := 1.0, hole := false, teinte := Color.WHITE) -> ShaderMaterial:
	return mz(nom, zone, uv, uv_m, hole, teinte) if extension else m64(nom, uv, uv_m, hole, teinte)


## P6.4.2 : sol d'une pièce (préréglage de sa zone).
func mat_sol(id: String) -> ShaderMaterial:
	var z := zone_piece(id)
	return mz(str(P642_ZONES.get(z, {}).get("sol", "dallage")), z, "monde", 1.0, false)


func _macon(d: Dictionary, uv: String, uv_m: float, hole: bool, teinte: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = MACON_SH
	for key in d:
		var v = d[key]
		if v is Color and teinte != Color.WHITE:
			v = (v as Color) * teinte
		m.set_shader_parameter(key, v)
	if float(d.get("k_terre", 0.0)) > 0.0 or float(d.get("k_mousse", 0.0)) > 0.0:
		m.set_shader_parameter("peint_terre", load(PEINT_TERRE))
		m.set_shader_parameter("peint_mousse", load(PEINT_MOUSSE))
	if int(d["motif"]) != 2:
		# grain peint : luminance basse fréquence de la roche peinte du dépôt (art/p4/mat/roche.png), décalée par élément
		m.set_shader_parameter("grain", load(GRAIN))
		m.set_shader_parameter("grain_k", 0.32 if int(d["motif"]) != 3 else 0.18)
		m.set_shader_parameter("grain_m", 1.4)
	m.set_shader_parameter("uv_mode", 0.0 if uv == "monde" else 1.0)
	m.set_shader_parameter("uv_m", uv_m)
	m.set_shader_parameter("hole", 1.0 if hole else 0.0)
	return m


func pilote_mur(id: String) -> bool:
	return p64 and (id in P64_MURS or (extension and id.begins_with("cmur_")))


func pilote_sol(id: String) -> bool:
	return p64 and (id in P64_SOLS or extension)


func pilote_gradins(am: float) -> bool:
	if extension:
		return p64
	var d := rad_to_deg(fposmod(am, TAU))
	return p64 and d >= P64_GRADINS[0] and d <= P64_GRADINS[1]


## P6.3.1 : matériau en « UV du maillage » (les UV sont déjà en mètres / tuile, calculés par _rq / _rt).
func mat_uv(path: String, tint: Color, hole := false, eclat := 1.0) -> ShaderMaterial:
	var k := "uv|%s|%s|%s|%s" % [path, tint, hole, eclat]
	if _mats.has(k):
		return _mats[k]
	var m := ShaderMaterial.new()
	m.shader = SURF_SH
	m.set_shader_parameter("tex", load(path))
	m.set_shader_parameter("uv_mode", 1.0)
	m.set_shader_parameter("tint", tint * eclat if eclat != 1.0 else tint)
	m.set_shader_parameter("hole", 1.0 if hole else 0.0)
	m.set_shader_parameter("macro", 0.06)
	_mats[k] = m
	return m


var _arcs := {}


## Longueur d'arc (m) sur l'ellipse (rx, ry) de l'angle 0 à a (table de 720 pas, a dans [0, 2π]).
func _arc_s(rx: float, ry: float, a: float) -> float:
	var k := "%.3f|%.3f" % [rx, ry]
	if not _arcs.has(k):
		var t := PackedFloat32Array()
		t.resize(721)
		var acc := 0.0
		var prev := Vector2(rx, 0.0)
		for i in range(1, 721):
			var aa := TAU * i / 720.0
			var p := Vector2(rx * cos(aa), ry * sin(aa))
			acc += p.distance_to(prev)
			prev = p
			t[i] = acc
		_arcs[k] = t
	var tab: PackedFloat32Array = _arcs[k]
	var f := clampf(a / TAU * 720.0, 0.0, 720.0)
	var i0 := int(floor(f))
	var i1 := mini(i0 + 1, 720)
	return lerpf(tab[i0], tab[i1], f - i0)


## Face verticale d'anneau, UV métriques : u = longueur d'arc / tuile, v = hauteur / tuile (blocs horizontaux).
func _rq(c: Vector2, rx: float, ry: float, a0: float, a1: float, h0: float, h1: float, tuile := 0.0) -> Array:
	var t := tuile if tuile > 0.0 else 1.8
	var p0 := Vector3(c.x + rx * cos(a0), h0, c.y + ry * sin(a0))
	var p1 := Vector3(c.x + rx * cos(a1), h0, c.y + ry * sin(a1))
	var s0 := _arc_s(rx, ry, a0) / t
	var s1 := _arc_s(rx, ry, a1) / t
	return [[p0, Vector3(p0.x, h1, p0.z), Vector3(p1.x, h1, p1.z), p1], [Vector2(s0, -h0 / t), Vector2(s0, -h1 / t), Vector2(s1, -h1 / t), Vector2(s1, -h0 / t)]]


## Dessus d'anneau, UV métriques le long de l'arc ; planches : les lames suivent l'arc (u radial, v = arc).
func _rt(c: Vector2, rx0: float, ry0: float, rx1: float, ry1: float, a0: float, a1: float, h: float, planches := false) -> Array:
	var t := 1.2 if planches else 1.8
	var p0 := Vector3(c.x + rx0 * cos(a0), h, c.y + ry0 * sin(a0))
	var p1 := Vector3(c.x + rx0 * cos(a1), h, c.y + ry0 * sin(a1))
	var q1 := Vector3(c.x + rx1 * cos(a1), h, c.y + ry1 * sin(a1))
	var q0 := Vector3(c.x + rx1 * cos(a0), h, c.y + ry1 * sin(a0))
	var s0 := _arc_s(rx0, ry0, a0) / t
	var s1 := _arc_s(rx0, ry0, a1) / t
	var w := (rx1 - rx0) / t
	if planches:
		return [[p0, q0, q1, p1], [Vector2(0, s0), Vector2(w, s0), Vector2(w, s1), Vector2(0, s1)]]
	return [[p0, q0, q1, p1], [Vector2(s0, 0), Vector2(s0, w), Vector2(s1, w), Vector2(s1, 0)]]


func uni(c: Color, rough := 0.9, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


# ------------------------------------------------------------------------------------------------ lumière
func lumiere(env: Environment, sun: DirectionalLight3D) -> void:
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.48, 0.52, 0.62)
	env.ambient_light_energy = 0.62
	var sky := Sky.new()
	var ps := ProceduralSkyMaterial.new()
	ps.sky_top_color = Color(0.32, 0.47, 0.72)
	ps.sky_horizon_color = Color(0.78, 0.74, 0.66)
	ps.ground_horizon_color = Color(0.5, 0.45, 0.4)
	ps.ground_bottom_color = Color(0.25, 0.22, 0.2)
	sky.sky_material = ps
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.glow_enabled = true
	env.glow_intensity = 0.22
	env.glow_bloom = 0.02
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.04
	env.adjustment_contrast = 1.06
	sun.light_color = Color(1.0, 0.9, 0.76)
	sun.light_energy = 1.3
	sun.shadow_opacity = 0.82


# ------------------------------------------------------------------------------------------------ extérieur
func exterieur(decor: Rect2) -> void:
	# parvis pavé (sous le niveau de jeu, sans collision : le sol de décor garde la sienne)
	var c := Vector3(decor.get_center().x, -0.03, decor.get_center().y)
	var g: MeshInstance3D = sc._box_mesh(c, Vector3(decor.size.x + 60.0, 0.04, decor.size.y + 60.0), mat(PAVES, 3.2, Color(0.86, 0.8, 0.72), false, true))
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# îlots de bâtiments lointains (au-delà de la carte), toits rouges, façades à colombages
	var rng := RandomNumberGenerator.new()
	rng.seed = 7311
	var fac := mat(FACADE, 4.0, Color(0.92, 0.88, 0.84))
	var toit := mat(TOIT, 2.4, Color(1.25, 0.62, 0.5))
	# aucune rangée au SUD : la caméra regarde vers le nord, des bâtiments au sud passeraient devant le joueur
	var rects := [Rect2(-14, -14, 94, 8), Rect2(-14, -6, 8, 44), Rect2(74, -6, 8, 44)]
	for r in rects:
		var along_x: bool = r.size.x > r.size.y
		var t := 0.0
		var length: float = r.size.x if along_x else r.size.y
		while t < length:
			var w := rng.randf_range(4.0, 7.5)
			var h := rng.randf_range(4.5, 8.5)
			var d := rng.randf_range(4.0, 6.5)
			var p: Vector2 = (r.position + Vector2(t + w / 2.0, r.size.y / 2.0)) if along_x else (r.position + Vector2(r.size.x / 2.0, t + w / 2.0))
			var sx := w if along_x else d
			var sz := d if along_x else w
			sc._box_mesh(Vector3(p.x, h / 2.0, p.y), Vector3(sx, h, sz), fac)
			_toit(Vector3(p.x, h, p.y), Vector2(sx, sz), 1.6, toit, along_x)
			t += w + rng.randf_range(0.2, 1.2)


func _toit(base: Vector3, s: Vector2, hh: float, m: Material, faitage_x: bool) -> void:
	var hx := s.x / 2.0 + 0.3
	var hz := s.y / 2.0 + 0.3
	var a := base + Vector3(-hx, 0, -hz)
	var b := base + Vector3(hx, 0, -hz)
	var c := base + Vector3(hx, 0, hz)
	var d := base + Vector3(-hx, 0, hz)
	var faces: Array = []
	if faitage_x:
		var f0 := base + Vector3(-hx, hh, 0)
		var f1 := base + Vector3(hx, hh, 0)
		faces = [[[a, f0, f1, b], [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]],
			[[c, f1, f0, d], [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]],
			[[a, d, f0], [Vector2(0, 1), Vector2(1, 1), Vector2(0.5, 0)]], [[c, b, f1], [Vector2(0, 1), Vector2(1, 1), Vector2(0.5, 0)]]]
	else:
		var f0 := base + Vector3(0, hh, -hz)
		var f1 := base + Vector3(0, hh, hz)
		faces = [[[d, f1, f0, a], [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]],
			[[b, f0, f1, c], [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]],
			[[a, f0, b], [Vector2(0, 1), Vector2(0.5, 0), Vector2(1, 1)]], [[c, f1, d], [Vector2(0, 1), Vector2(0.5, 0), Vector2(1, 1)]]]
	sc._faces(faces, m)


# ------------------------------------------------------------------------------------------------ arène
func arene(a: Dictionary, tunnels: Array) -> void:
	var c := Vector2(a["centre"][0], a["centre"][1])
	var rx: float = a["rayons"][0]
	var ry: float = a["rayons"][1]
	var ep: float = a["anneau_ep"]
	var ah: float = a["anneau_h"]
	var prof: float = a["gradins_prof"]
	var rangs: int = a["rangs"]
	var n := 144
	var pierre := mat(PIERRE, 2.4, C_CALCAIRE, true)
	var pierre_claire := mat(PIERRE, 2.4, C_CALCAIRE * Color(1.1, 1.08, 1.06), true)
	var pierre_sombre := mat(PIERRE, 2.4, C_CALCAIRE * Color(0.78, 0.76, 0.76), true)
	var bois := mat(PLANCHES, 1.6, Color(0.62, 0.5, 0.44))
	# P6.3.1 : anneaux (podium, gradins, enceinte, colonnade) en UV MÉTRIQUES qui suivent la courbe (_rq / _rt) et
	# matériaux distincts : la projection « UV monde » faisait pivoter et étirer les briques sur les faces courbes
	var u_pierre := mat_uv(PIERRE, C_CALCAIRE, true)                                       # contremarches, enceinte
	var u_dalle := mat_uv(PIERRE, C_CALCAIRE * Color(1.12, 1.1, 1.08), true, 0.9)          # dessus des marches, chaperon
	var u_bois := mat_uv(PLANCHES, Color(0.62, 0.5, 0.44), true)                           # assises (planches le long de l'arc)
	var u_esc := mat_uv(PIERRE, C_CALCAIRE * Color(0.9, 0.86, 0.84), true, 0.75)          # escaliers
	if extension and p64:
		# P6.4.2 : tout l'anneau dans les matières de la portion pilote (plus de surfaces P6.3 à côté des nouvelles)
		pierre_claire = mz("moulure", "arene", "monde", 1.0, true)
		pierre_sombre = mz("contrefort", "arene", "monde", 1.0, true)
		pierre = mz("mur", "arene", "monde", 1.0, true)
		u_pierre = mz("gradin", "arene", "maillage", 1.8, true)
		u_dalle = mz("dalle", "arene", "maillage", 1.8, true)
		u_bois = mz("bois", "arene", "maillage", 1.8, true, Color(0.86, 0.88, 0.96))      # bois grisé par le soleil
		u_esc = mz("dalle", "arene", "maillage", 1.8, true, Color(0.92, 0.9, 0.88))
	# sable
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		for v in [Vector3(c.x, 0.006, c.y), Vector3(c.x + rx * cos(a0), 0.006, c.y + ry * sin(a0)), Vector3(c.x + rx * cos(a1), 0.006, c.y + ry * sin(a1))]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	var sable := MeshInstance3D.new()
	sable.mesh = st.commit()
	sable.material_override = mat(SABLE, 4.0, Color(1.06, 1.0, 0.9), false, true)
	sc.root.add_child(sable)
	# sable tassé et ombré au pied du podium, piétinement au centre (bandes semi-transparentes)
	_bande(c, rx, ry, rx - 1.6, ry - 1.6, 0.009, Color(0.28, 0.2, 0.12, 0.42), Color(0.28, 0.2, 0.12, 0.0))
	_bande(c, 3.6, 3.6, 0.0, 0.0, 0.008, Color(0.35, 0.26, 0.16, 0.0), Color(0.35, 0.26, 0.16, 0.22))
	if extension and p64 and sable_calque:
		_calque_sable(c, rx, ry, n)
	# podium : parement, chaperon débordant, pilastres, bannières, braseros
	var podium: Array = []
	var chaperon: Array = []
	var p_podium: Array = []
	var p_chap: Array = []
	var p_chap_f: Array = []
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		if _dans_tunnel(c, rx + ep * 0.5, ry + ep * 0.5, (a0 + a1) / 2.0, tunnels):
			continue
		var pp := pilote_gradins((a0 + a1) / 2.0)
		(p_podium if pp else podium).append(_rq(c, rx, ry, a0, a1, 0.0, ah, 0.0))
		(p_chap if pp else chaperon).append(_rt(c, rx - 0.14, ry - 0.14, rx + ep + 0.05, ry + ep + 0.05, a0, a1, ah + 0.14))
		(p_chap_f if pp else chaperon).append(_rq(c, rx - 0.14, ry - 0.14, a0, a1, ah, ah + 0.14, 0.0))
	sc._faces(podium, u_pierre)
	sc._faces(chaperon, u_dalle)
	if not p_podium.is_empty():
		sc._faces(p_podium, mm("socle", "arene", "maillage", 1.8, true))
		sc._faces(p_chap, mm("dalle", "arene", "maillage", 1.8, true))
		sc._faces(p_chap_f, mm("moulure", "arene", "maillage", 1.8, true))
	var k := 0
	for i in range(0, 360, 12):
		var an := deg_to_rad(i + 6)
		if _dans_tunnel(c, rx + ep * 0.5, ry + ep * 0.5, an, tunnels) or _dans_tunnel(c, rx + ep * 0.5, ry + ep * 0.5, an + 0.08, tunnels) or _dans_tunnel(c, rx + ep * 0.5, ry + ep * 0.5, an - 0.08, tunnels):
			continue
		var p := Vector3(c.x + (rx - 0.08) * cos(an), 0, c.y + (ry - 0.08) * sin(an))
		var pil: MeshInstance3D = sc._box_mesh(p + Vector3(0, (ah + 0.3) / 2.0, 0), Vector3(0.5, ah + 0.3, 0.5), pierre_sombre)
		pil.rotation.y = -atan2(ry * sin(an), rx * cos(an))
		k += 1
		var sud := sin(an) > 0.3
		if k % 3 == 0 and not sud:
			var mid := deg_to_rad(i + 12)
			if not _dans_tunnel(c, rx, ry, mid, tunnels):
				_banniere_podium(Vector3(c.x + (rx - 0.05) * cos(mid), 0, c.y + (ry - 0.05) * sin(mid)), mid, c, rx, ry, C_GUILDE if (k / 3) % 2 == 0 else Color(0.62, 0.16, 0.2))
		if k % 5 == 2:
			_brasero(p + Vector3(0, ah + 0.3, 0) - Vector3(cos(an), 0, sin(an)) * 0.1)
			if pilote_gradins(an):
				# P6.4 : lueur locale du brasero (chaude, courte portée, sans ombre) sur le podium et les premiers rangs
				lum_fixe(p + Vector3(0, ah + 0.8, 0), 0.9, 3.4, Color(1.0, 0.62, 0.32))
	# gradins : contremarches en pierre, assises en bois, escaliers tous les 30°
	var contremarches: Array = []
	var marches: Array = []
	var assises: Array = []
	var escaliers: Array = []
	# P6.3 : tranche de gradins au sud du tunnel est, en maillages séparés : vue de la caméra, elle couvre le passage ;
	# elle s'estompe seulement quand Aren est dans le tunnel est (coupe), et reste entière vue de l'arène
	var t_contre: Array = []
	var t_marches: Array = []
	var t_assises: Array = []
	var t_esc: Array = []
	var p_contre: Array = []
	var p_marches: Array = []
	var p_assises: Array = []
	var p_esc: Array = []
	# P6.4.3 : segments de gradins conservés (les accès combattants interrompent l'anneau) ; aux extrémités, une joue
	# de maçonnerie ferme le profil des marches (sinon on voyait le dessous des gradins et le parvis par la coupe)
	var garde_g := func(i: int) -> bool:
		var amg := TAU * (fposmod(float(i), float(n)) + 0.5) / n
		return not (_dans_tunnel(c, rx + ep + prof * 0.5, ry + ep + prof * 0.5, amg, tunnels) or _dans_tunnel(c, rx + ep * 0.5, ry + ep * 0.5, amg, tunnels) or _dans_tunnel(c, rx + ep + prof - 0.2, ry + ep + prof - 0.2, amg, tunnels))
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var am := (a0 + a1) / 2.0
		var sud := maxf(0.0, sin(am))
		# P6.2-D : gradins sud-est abaissés aussi (entre le tunnel est et le sud) : vus de la caméra, ils couvraient le
		# tunnel est et Aren qui y passe (affichage seulement : aucune collision)
		var deg := rad_to_deg(fposmod(am, TAU))
		var se := smoothstep(4.0, 16.0, deg) * (1.0 - smoothstep(60.0, 80.0, deg))
		var k_h := lerpf(1.0, 0.42, maxf(sud, se))
		if _dans_tunnel(c, rx + ep + prof * 0.5, ry + ep + prof * 0.5, am, tunnels) or _dans_tunnel(c, rx + ep * 0.5, ry + ep * 0.5, am, tunnels) or _dans_tunnel(c, rx + ep + prof - 0.2, ry + ep + prof - 0.2, am, tunnels):
			continue
		var allee := fposmod(rad_to_deg(am), 30.0) < 2.6
		var tranche := deg >= 2.0 and deg <= 46.0
		var pil := pilote_gradins(am)          # P6.4 : portion pilote (matériaux procéduraux) ; P6.4.2 : tout l'anneau
		var cm_: Array = t_contre if tranche else (p_contre if pil else contremarches)
		var ma_: Array = t_marches if tranche else (p_marches if pil else marches)
		var as_: Array = t_assises if tranche else (p_assises if pil else assises)
		var es_: Array = t_esc if tranche else (p_esc if pil else escaliers)
		for kk in rangs:
			var r0 := rx + ep + prof * kk / rangs
			var r1 := rx + ep + prof * (kk + 1) / rangs
			var hk := (ah + 0.25 + 0.55 * (kk + 1)) * k_h + (1.0 - k_h) * 0.4
			var hprev := ah + 0.14 if kk == 0 else (ah + 0.25 + 0.55 * kk) * k_h + (1.0 - k_h) * 0.4
			cm_.append(_rq(c, r0, ry + (r0 - rx), a0, a1, hprev, hk, 0.0))
			if allee:
				es_.append(_rt(c, r0, ry + (r0 - rx), r1, ry + (r1 - rx), a0, a1, hk))
			else:
				ma_.append(_rt(c, r0, ry + (r0 - rx), r1, ry + (r1 - rx), a0, a1, hk))
				var rs := r0 + 0.08
				as_.append(_rt(c, rs, ry + (rs - rx), rs + 0.34, ry + (rs + 0.34 - rx), a0, a1, hk + 0.07, not (pil or (tranche and extension))))
				as_.append(_rq(c, rs, ry + (rs - rx), a0, a1, hk, hk + 0.07, 0.0))
		var rl := rx + ep + prof
		var htop := (ah + 0.25 + 0.55 * rangs) * k_h + (1.0 - k_h) * 0.4
		if extension and p64:
			for bord in [[a0, i - 1], [a1, i + 1]]:
				if not garde_g.call(int(bord[1])):
					cm_.append_array(_joue_gradins(c, rx, ry, ep, prof, rangs, ah, k_h, float(bord[0])))
		cm_.append(_rq(c, rl, ry + (rl - rx), a1, a0, 0.0, htop + 0.7, 0.0))
		cm_.append(_rt(c, rl, ry + (rl - rx), rl + 0.5, ry + (rl + 0.5 - rx), a0, a1, htop + 0.7))
		cm_.append(_rq(c, rl, ry + (rl - rx), a0, a1, htop, htop + 0.7, 0.0))
	sc._faces(contremarches, u_pierre)
	var mg: MeshInstance3D = sc._faces(marches, u_dalle)
	mg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	sc._faces(assises, u_bois)
	sc._faces(escaliers, u_esc)
	if not p_contre.is_empty():
		# P6.4 : portion pilote (UV métriques de _rq / _rt : 1 unité = 1,8 m)
		sc._faces(p_contre, mm("gradin", "arene", "maillage", 1.8, true))
		var pm: MeshInstance3D = sc._faces(p_marches, mm("dalle", "arene", "maillage", 1.8, true))
		pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var pa: MeshInstance3D = sc._faces(p_assises, u_bois if extension else m64("bois", "maillage", 1.8, true))
		pa.name = "P64_assises"
		if not p_esc.is_empty():
			sc._faces(p_esc, mm("dalle", "arene", "maillage", 1.8, true, Color(0.92, 0.9, 0.88)))
	if not t_contre.is_empty() and sc.has_method("tranche_gradins"):
		var ms: Array = [sc._faces(t_contre, u_pierre), sc._faces(t_marches, u_dalle), sc._faces(t_assises, u_bois)]
		if not t_esc.is_empty():
			ms.append(sc._faces(t_esc, u_esc))
		sc.tranche_gradins(ms)
	# colonnade haute (moitié nord, derrière l'arène) : colonnes et architrave
	var rl2 := rx + ep + prof + 0.25
	var htop_n := ah + 0.25 + 0.55 * rangs + 0.7
	var archi: Array = []
	for i in range(-168, -10, 8):
		var an := deg_to_rad(i)
		var p := Vector3(c.x + rl2 * cos(an), htop_n, c.y + (ry + (rl2 - rx)) * sin(an))
		_colonne(p, 2.3, pierre_claire)
	for i in range(-168, -18, 4):
		var a0 := deg_to_rad(i)
		var a1 := deg_to_rad(i + 4)
		archi.append(_rq(c, rl2 - 0.3, ry + (rl2 - 0.3 - rx), a0, a1, htop_n + 2.3, htop_n + 2.75, 0.0))
		archi.append(_rt(c, rl2 - 0.3, ry + (rl2 - 0.3 - rx), rl2 + 0.3, ry + (rl2 + 0.3 - rx), a0, a1, htop_n + 2.75))
	sc._faces(archi, mz("moulure", "arene", "maillage", 1.8, true) if extension and p64 else u_dalle)
	# P6.3.2 : écoinçons entre l'anneau des gradins et l'enveloppe rectangulaire du bâtiment
	if p64 and galerie in ["A", "B"]:
		_galerie_v2(galerie, a, tunnels, c, rx, ry, ep, prof, rangs, ah)
	elif p64:
		_galerie_p64(a, tunnels, c, rx, ry, ep, prof, rangs, ah)
	else:
		_ecoincons(a, tunnels, c, rx, ry, ep, prof, rangs, ah)
	# accès combattants : arcs à claveaux, grille relevée visible
	for t in tunnels:
		if (t as Rect2).size.x > (t as Rect2).size.y:      # tunnel est (vu de côté) ; au sud, un arc masquerait l'arène
			var n_arc: int = sc.root.get_child_count()
			_arc_tunnel(t as Rect2, pierre_claire, pierre_sombre)
			if extension and p64:
				# P6.4.3 : l'arc fait partie de l'enceinte de l'arène (EXT, comme le reste du décor de l'arène, soumis au voile). Classé par sa position (tunnel est), il
				# restait affiché depuis la coursive, seul sur le noir, alors que l'arène autour était masquée
				for j in range(n_arc, sc.root.get_child_count()):
					sc.root.get_child(j).set_meta("secteur", "EXT")
	if extension and p64:
		_lumiere_arene_p642(c, rx, ry, tunnels)


## P6.4.3 : joue radiale qui ferme l'extrémité d'un segment de gradins à l'angle an (profil des rangs rempli jusqu'au
## sol, puis le mur de fond et son chaperon). Faces doublées (vues des deux côtés), UV métriques (u = rayon, v = -h) à
## l'échelle des matières de l'anneau (1 unité = 1,8 m). Affichage seul : aucune collision.
func _joue_gradins(c: Vector2, rx: float, ry: float, ep: float, prof: float, rangs: int, ah: float, k_h: float, an: float) -> Array:
	var pt := func(r: float, h: float) -> Vector3:
		return Vector3(c.x + r * cos(an), h, c.y + (ry + r - rx) * sin(an))
	var quad := func(r0: float, r1: float, h: float) -> Array:
		return [[pt.call(r0, 0.0), pt.call(r0, h), pt.call(r1, h), pt.call(r1, 0.0)],
			[Vector2(r0 / 1.8, 0.0), Vector2(r0 / 1.8, -h / 1.8), Vector2(r1 / 1.8, -h / 1.8), Vector2(r1 / 1.8, 0.0)]]
	var out: Array = []
	for kk in rangs:
		var r0 := rx + ep + prof * kk / rangs
		var r1 := rx + ep + prof * (kk + 1) / rangs
		out.append(quad.call(r0, r1, (ah + 0.25 + 0.55 * (kk + 1)) * k_h + (1.0 - k_h) * 0.4))
	var rl := rx + ep + prof
	out.append(quad.call(rl, rl + 0.5, (ah + 0.25 + 0.55 * rangs) * k_h + (1.0 - k_h) * 0.4 + 0.7))
	return _deux(out)


func _dans_tunnel(c: Vector2, rx: float, ry: float, an: float, tunnels: Array) -> bool:
	var p := Vector2(c.x + rx * cos(an), c.y + ry * sin(an))
	for t in tunnels:
		if (t as Rect2).grow(0.15).has_point(p):
			return true
	return false


## P6.4.3 : calque transparent sur tout le sable (src/p6/sable_p643.gdshader), juste au-dessus des bandes existantes.
## Axes des traces : bouche du tunnel sud -> centre -> bouche du tunnel est (les trajets réels du parcours).
func _calque_sable(c: Vector2, rx: float, ry: float, n: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		for v in [Vector3(c.x, 0.011, c.y), Vector3(c.x + rx * cos(a0), 0.011, c.y + ry * sin(a0)), Vector3(c.x + rx * cos(a1), 0.011, c.y + ry * sin(a1))]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.name = "Sable_calque_p643"
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = SABLE_SH
	m.set_shader_parameter("centre", c)
	m.set_shader_parameter("rayons", Vector2(rx, ry))
	m.set_shader_parameter("axe_a", Vector4(c.x, c.y + ry - 0.4, c.x, c.y + 0.4))
	m.set_shader_parameter("axe_b", Vector4(c.x + 1.0, c.y, c.x + rx - 0.3, c.y))
	mi.material_override = m
	sc.root.add_child(mi)


func _bande(c: Vector2, rx0: float, ry0: float, rx1: float, ry1: float, h: float, c0: Color, c1: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 96
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var v := [Vector3(c.x + rx0 * cos(a0), h, c.y + ry0 * sin(a0)), Vector3(c.x + rx0 * cos(a1), h, c.y + ry0 * sin(a1)),
			Vector3(c.x + rx1 * cos(a1), h, c.y + ry1 * sin(a1)), Vector3(c.x + rx1 * cos(a0), h, c.y + ry1 * sin(a0))]
		var col := [c0, c0, c1, c1]
		for j in [0, 2, 1, 0, 3, 2]:
			st.set_normal(Vector3.UP)
			st.set_color(col[j])
			st.add_vertex(v[j])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sc.root.add_child(mi)


## P6.4 : lumière locale fixe (sans scintillement de flamme, sans ombre portée).
func lum_fixe(pos: Vector3, energie: float, portee: float, col: Color) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energie
	l.omni_range = portee
	l.omni_attenuation = 1.4
	l.shadow_enabled = false
	l.position = pos
	l.set_meta("p64", true)
	sc.root.add_child(l)
	return l


## P6.4 : éclairage local de la coursive pilote : lumière froide zénithale douce (sépare le dallage des murs) et
## halos chauds sous les lanternes du mur nord.
func lumiere_coursive_p64() -> void:
	if not p64:
		return
	if not pilote2:
		lum_fixe(Vector3(50.0, 5.5, 20.0), 0.55, 11.0, Color(0.74, 0.8, 0.98))
		for x in [46.4, 53.6]:
			lum_fixe(Vector3(x, 2.2, 12.7), 0.7, 3.6, Color(1.0, 0.7, 0.42))
		return
	# P6.4.1 : la lumière sert la lecture : accès (porte de la loge, porte de la réserve, débouché du tunnel est) et
	# allée centrale où circulent les personnages ; fond zénithal plus discret (les murs restent un peu plus sombres
	# que le sol : les silhouettes s'en détachent)
	lum_fixe(Vector3(50.0, 5.5, 20.0), 0.42, 11.0, Color(0.74, 0.8, 0.98))
	lum_fixe(Vector3(50.0, 2.5, 13.0), 1.0, 3.8, Color(1.0, 0.72, 0.44))        # porte de la loge
	lum_fixe(Vector3(53.0, 2.1, 33.0), 0.75, 3.0, Color(1.0, 0.7, 0.42))        # porte de la réserve
	lum_fixe(Vector3(45.2, 2.2, 23.0), 0.6, 3.2, Color(1.0, 0.78, 0.55))        # débouché du tunnel est
	for z in [17.0, 23.0, 29.0]:
		lum_fixe(Vector3(50.0, 3.2, z), 0.6, 4.2, Color(1.0, 0.86, 0.7))        # allée centrale


## P6.4.2 : arène éclairée naturellement. Pas de lumière ajoutée sur le sable : seules les bouches des deux accès
## combattants reçoivent une lueur chaude courte (lecture des passages depuis le centre), sans ombre.
func _lumiere_arene_p642(c: Vector2, rx: float, ry: float, tunnels: Array) -> void:
	for t in tunnels:
		var tr := t as Rect2
		var sud := tr.size.y > tr.size.x
		var p := Vector3(tr.get_center().x, 2.3, tr.position.y + 0.6) if sud else Vector3(tr.position.x + 0.5, 2.3, tr.get_center().y)
		lum_fixe(p, 0.55, 3.2, Color(1.0, 0.74, 0.46))


## P6.4.2 : harmonisation lumineuse. Même logique que la coursive du second pilote : la lumière désigne les accès et
## les axes de circulation, chaque pièce garde sa tonalité. Lumières fixes, sans ombre ni scintillement ; aucune ne
## suit Aren. Vestiaires (chauds) et coursive : réglages des pilotes, inchangés.
func lumiere_p642() -> void:
	if not (extension and p64):
		return
	var dy: float = sc._dy_sud
	# salle d'attente (intérieur) : les deux portes de service, et l'axe vers le tunnel, plus doux que les vestiaires
	for x in [20.6, 31.4]:
		lum_fixe(Vector3(x, 2.1, 41.0 + dy), 0.45, 2.6, Color(1.0, 0.72, 0.46))
	lum_fixe(Vector3(26.0, 2.8, 41.6 + dy), 0.4, 4.6, Color(1.0, 0.82, 0.64))
	# infirmerie : lumière plus blanche et calme au-dessus des lits (lieu de soins), porte vers la coursive
	lum_fixe(Vector3(45.6, 2.7, 38.8), 0.5, 4.2, Color(0.94, 0.94, 0.9))
	lum_fixe(Vector3(46.5, 2.1, 35.4), 0.4, 2.4, Color(1.0, 0.78, 0.55))
	# réserve (vue en coupe) : une seule lueur faible et chaude, pièce fermée et poussiéreuse
	lum_fixe(Vector3(53.2, 2.4, 37.8), 0.3, 3.6, Color(1.0, 0.7, 0.45))
	# couloir de sortie : la porte de la coursive et le bout du couloir (le jour de la ville entre par la porte est)
	lum_fixe(Vector3(57.4, 2.2, 23.0), 0.55, 2.8, Color(1.0, 0.74, 0.48))


## Hauteur du haut du mur de fond des gradins à l'angle a (même formule que la construction des gradins).
func _h_dos(a: float, ah: float, rangs: int) -> float:
	var sud := maxf(0.0, sin(a))
	var deg := rad_to_deg(fposmod(a, TAU))
	var se := smoothstep(4.0, 16.0, deg) * (1.0 - smoothstep(60.0, 80.0, deg))
	var k_h := lerpf(1.0, 0.42, maxf(sud, se))
	return (ah + 0.25 + 0.55 * rangs) * k_h + (1.0 - k_h) * 0.4 + 0.7


## P6.3.2 : MASSIF DES ÉCOINÇONS. L'anneau ovale des gradins était posé seul dans une enveloppe rectangulaire (bloc de
## la salle au sud, coursive à l'est) : entre son dos et ces bâtiments, on voyait le sol du parvis (ouverture réelle de
## l'architecture, identique avec ou sans masquage). On remplit ces écoinçons par une maçonnerie couverte, comme la
## substructure d'un amphithéâtre : toiture continue avec le haut du mur de fond des gradins (même hauteur à chaque
## angle : aucune occultation nouvelle de l'arène), façades de pierre sur le pourtour. Les tunnels et la loge restent
## dégagés. Affichage seulement : ces zones n'étaient déjà pas praticables (aucune collision ajoutée ou retirée).
func _ecoincons(a: Dictionary, tunnels: Array, c: Vector2, rx: float, ry: float, ep: float, prof: float, rangs: int, ah: float) -> void:
	var rl := rx + ep + prof + 0.5
	var rly := ry + ep + prof + 0.5
	var vt: Dictionary = sc._p6.get("vue_tunnel", {})
	var y1: float = float(vt.get("entree", 37.5)) - 0.6         # au pied du mur nord de la salle (bloc sud décalé), hors de la
	                                                            # zone « intérieur » du masque de vue du tunnel
	var rect := Rect2(Vector2(c.x - rl, c.y - rly), Vector2(43.6 - (c.x - rl), y1 - (c.y - rly)))
	var exclus: Array = []
	for t in tunnels:
		exclus.append((t as Rect2).grow(0.3))
	exclus.append(Rect2(24.0, 30.0, 4.0, y1 - 30.0 + 0.5))     # tunnel sud prolongé (longueur retenue)
	var lg: Dictionary = a["loge"]
	exclus.append(Rect2(lg["centre"][0] - lg["taille"][0] * 0.5, lg["centre"][1] - lg["taille"][1] * 0.5, lg["taille"][0], lg["taille"][1]).grow(0.4))
	var toit := mat(PIERRE, 1.8, C_CALCAIRE * Color(0.84, 0.82, 0.8), true)      # terrasse de pierre (couverture)
	var facade := mat(PIERRE, 2.4, C_CALCAIRE * Color(0.92, 0.9, 0.9), true)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sf := SurfaceTool.new()
	sf.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 144
	var coins := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var am := (a0 + a1) * 0.5
		var pts: Array = []
		var hs: Array = []
		for aa in [a0, a1]:
			pts.append(Vector2(c.x + rl * cos(aa), c.y + rly * sin(aa)))
			hs.append(_h_dos(aa, ah, rangs))
		var q0 := _vers_bord(c, pts[0], rect)
		var q1 := _vers_bord(c, pts[1], rect)
		# exclusion : un point du rayon médian dans un tunnel ou la loge
		var pm := Vector2(c.x + rl * cos(am), c.y + rly * sin(am))
		var qm := _vers_bord(c, pm, rect)
		var saute := false
		for e in exclus:
			for t in [0.05, 0.35, 0.65, 0.95]:
				if (e as Rect2).has_point(pm.lerp(qm, t)):
					saute = true
		if saute or pm.distance_to(qm) < 0.05:
			continue
		# polygone du dessus : P0, Q0, (coin éventuel), Q1, P1 — hauteurs : celles du dos des gradins
		var poly: Array = [Vector3(pts[0].x, hs[0], pts[0].y), Vector3(q0.x, hs[0], q0.y)]
		for k in coins:
			var kk: Vector2 = k
			var v0 := (q0 - c).angle()
			var v1 := (q1 - c).angle()
			var vk := (kk - c).angle()
			if _entre(vk, v0, v1):
				poly.append(Vector3(kk.x, (hs[0] + hs[1]) * 0.5, kk.y))
		poly.append(Vector3(q1.x, hs[1], q1.y))
		poly.append(Vector3(pts[1].x, hs[1], pts[1].y))
		for j in range(1, poly.size() - 1):
			for v in [poly[0], poly[j], poly[j + 1]]:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2((v as Vector3).x, (v as Vector3).z) / 2.4)
				st.add_vertex(v)
		# façade sur le pourtour (du sol au dessus), tournée vers l'extérieur
		var bord: Array = poly.slice(1, poly.size() - 1)
		for j in range(bord.size() - 1):
			var b0: Vector3 = bord[j]
			var b1: Vector3 = bord[j + 1]
			var quad := [Vector3(b0.x, 0.0, b0.z), Vector3(b1.x, 0.0, b1.z), Vector3(b1.x, b1.y, b1.z), Vector3(b0.x, b0.y, b0.z)]
			var nn: Vector3 = ((quad[1] as Vector3) - (quad[0] as Vector3)).cross((quad[3] as Vector3) - (quad[0] as Vector3)).normalized()
			for idx in [0, 1, 2, 0, 2, 3, 0, 2, 1, 0, 3, 2]:      # deux faces (vue depuis l'arène et depuis le parvis)
				sf.set_normal(-nn)
				var qv: Vector3 = quad[idx]
				sf.set_uv(Vector2(qv.x + qv.z, -qv.y) / 2.4)
				sf.add_vertex(qv)
	for pair in [[st, toit], [sf, facade]]:
		var mi := MeshInstance3D.new()
		mi.mesh = (pair[0] as SurfaceTool).commit()
		mi.material_override = pair[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mi.name = "Ecoincons_gradins"
		sc.root.add_child(mi)


## P6.4 : GALERIE COUVERTE des écoinçons (remplace la terrasse plate de P6.3.2, toujours sans collision). Entre le dos
## des gradins et l'enveloppe rectangulaire : une toiture de tuiles canal en appentis, qui descend du mur de fond des
## gradins vers les façades (rangs de tuiles parallèles à l'anneau) ; des contreforts rayonnants tous les 15° la
## découpent en travées et finissent en pilastres sur les façades ; une corniche de pierre court le long de l'anneau à
## la jonction ; les façades ont un égout de toit et des retours de mur aux passages (tunnels, loge). Le sol derrière
## les gradins reste entièrement caché ; rien ne dépasse la hauteur du mur de fond des gradins (aucune occultation
## nouvelle de l'arène). Matériaux procéduraux P6.4 (tuiles, gros appareil, moulures).
func _galerie_p64(a: Dictionary, tunnels: Array, c: Vector2, rx: float, ry: float, ep: float, prof: float, rangs: int, ah: float) -> void:
	var rl := rx + ep + prof + 0.5
	var rly := ry + ep + prof + 0.5
	var vt: Dictionary = sc._p6.get("vue_tunnel", {})
	var y1: float = float(vt.get("entree", 37.5)) - 0.6
	var rect := Rect2(Vector2(c.x - rl, c.y - rly), Vector2(43.6 - (c.x - rl), y1 - (c.y - rly)))
	var exclus: Array = []
	for t in tunnels:
		exclus.append((t as Rect2).grow(0.3))
	exclus.append(Rect2(24.0, 30.0, 4.0, y1 - 30.0 + 0.5))
	var lg: Dictionary = a["loge"]
	exclus.append(Rect2(lg["centre"][0] - lg["taille"][0] * 0.5, lg["centre"][1] - lg["taille"][1] * 0.5, lg["taille"][0], lg["taille"][1]).grow(0.4))
	var n := 288
	var coins := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	var toit: Array = []          # faces [points, uv] (UV en mètres)
	var murs: Array = []
	var corniche: Array = []
	var garde := func(am: float) -> bool:
		var pm := Vector2(c.x + rl * cos(am), c.y + rly * sin(am))
		var qm := _vers_bord(c, pm, rect)
		if pm.distance_to(qm) < 0.05:
			return false
		for e in exclus:
			for t in [0.05, 0.35, 0.65, 0.95]:
				if (e as Rect2).has_point(pm.lerp(qm, t)):
					return false
		return true
	# profil d'un rayon : point de l'anneau, point de façade, hauteurs (naissance sous la corniche, égout)
	var rayon := func(aa: float) -> Dictionary:
		var p := Vector2(c.x + rl * cos(aa), c.y + rly * sin(aa))
		var q := _vers_bord(c, p, rect)
		var h_in := _h_dos(aa, ah, rangs) - 0.32
		var dm := p.distance_to(q)
		var chute := minf(0.34 * dm, 0.3 * h_in)
		return {"p": p, "q": q, "h_in": h_in, "dm": dm, "chute": chute, "s": _arc_s(rl, rly, fposmod(aa, TAU))}
	var hauteur := func(r: Dictionary, t: float) -> float:
		return float(r["h_in"]) - float(r["chute"]) * t
	var ok: Array = []
	for i in n:
		ok.append(garde.call(TAU * (i + 0.5) / n))
	for i in n:
		if not ok[i]:
			continue
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var r0: Dictionary = rayon.call(a0)
		var r1: Dictionary = rayon.call(a1)
		# toiture : bandes radiales (60 cm), UV : u = longueur d'arc à ce rayon, v = distance depuis l'anneau
		var m := int(ceil(maxf(r0["dm"], r1["dm"]) / 0.6))
		for k in m:
			var ta := float(k) / m
			var tb := float(k + 1) / m
			var pts: Array = []
			var uvs: Array = []
			for pr in [[r0, ta], [r0, tb], [r1, tb], [r1, ta]]:
				var rr: Dictionary = pr[0]
				var t: float = pr[1]
				var xz: Vector2 = (rr["p"] as Vector2).lerp(rr["q"], t)
				var lam := (xz - c).length() / ((rr["p"] as Vector2) - c).length()
				pts.append(Vector3(xz.x, hauteur.call(rr, t), xz.y))
				uvs.append(Vector2(float(rr["s"]) * lam, -t * float(rr["dm"])))
			toit.append([pts, uvs])
		# coin du rectangle entre les deux rayons : triangle d'égout
		var q0: Vector2 = r0["q"]
		var q1: Vector2 = r1["q"]
		var bord: Array = [Vector3(q0.x, hauteur.call(r0, 1.0), q0.y)]
		for kk in coins:
			var kc: Vector2 = kk
			if _entre((kc - c).angle(), (q0 - c).angle(), (q1 - c).angle()):
				var hk := minf(hauteur.call(r0, 1.0), hauteur.call(r1, 1.0)) - 0.15
				var lam2 := (kc - c).length() / ((r0["p"] as Vector2) - c).length()
				toit.append([[Vector3(q0.x, hauteur.call(r0, 1.0), q0.y), Vector3(kc.x, hk, kc.y), Vector3(q1.x, hauteur.call(r1, 1.0), q1.y)],
					[Vector2(float(r0["s"]) * lam2, -float(r0["dm"])), Vector2(float(r0["s"]) * lam2, -(kc - (r0["p"] as Vector2)).length()), Vector2(float(r1["s"]) * lam2, -float(r1["dm"]))]])
				bord.append(Vector3(kc.x, hk, kc.y))
		bord.append(Vector3(q1.x, hauteur.call(r1, 1.0), q1.y))
		# façades sous l'égout (deux faces) et égout débordant
		for j in range(bord.size() - 1):
			var b0: Vector3 = bord[j]
			var b1: Vector3 = bord[j + 1]
			var u0 := b0.x + b0.z
			var u1 := b1.x + b1.z
			murs.append([[Vector3(b0.x, 0.0, b0.z), Vector3(b0.x, b0.y, b0.z), Vector3(b1.x, b1.y, b1.z), Vector3(b1.x, 0.0, b1.z)], [Vector2(u0, 0), Vector2(u0, -b0.y), Vector2(u1, -b1.y), Vector2(u1, 0)]])
			murs.append([[Vector3(b0.x, 0.0, b0.z), Vector3(b1.x, 0.0, b1.z), Vector3(b1.x, b1.y, b1.z), Vector3(b0.x, b0.y, b0.z)], [Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, -b1.y), Vector2(u0, -b0.y)]])
			var dir := Vector2(b1.x - b0.x, b1.z - b0.z).normalized()
			var nrm := Vector2(-dir.y, dir.x)
			if nrm.dot(Vector2((b0.x + b1.x) * 0.5, (b0.z + b1.z) * 0.5) - c) < 0.0:
				nrm = -nrm
			var o := Vector3(nrm.x, 0, nrm.y) * 0.28
			var e0 := b0 + Vector3(0, 0.02, 0)
			var e1 := b1 + Vector3(0, 0.02, 0)
			corniche.append([[e0, e0 + o + Vector3(0, -0.06, 0), e1 + o + Vector3(0, -0.06, 0), e1], [Vector2(u0, 0), Vector2(u0, 0.28), Vector2(u1, 0.28), Vector2(u1, 0)]])
			corniche.append([[e0 + o + Vector3(0, -0.06, 0), e0 + o + Vector3(0, -0.2, 0), e1 + o + Vector3(0, -0.2, 0), e1 + o + Vector3(0, -0.06, 0)], [Vector2(u0, -0.06), Vector2(u0, -0.2), Vector2(u1, -0.2), Vector2(u1, -0.06)]])
		# retours de mur le long d'un rayon, au bord d'un passage (tunnel, loge)
		for side in [[r0, (i - 1 + n) % n, false], [r1, (i + 1) % n, true]]:
			if ok[side[1]]:
				continue
			var rr: Dictionary = side[0]
			var mm := int(ceil(float(rr["dm"]) / 0.6))
			for k in mm:
				var ta := float(k) / mm
				var tb := float(k + 1) / mm
				var xa: Vector2 = (rr["p"] as Vector2).lerp(rr["q"], ta)
				var xb: Vector2 = (rr["p"] as Vector2).lerp(rr["q"], tb)
				var ha: float = hauteur.call(rr, ta)
				var hb: float = hauteur.call(rr, tb)
				var da := ta * float(rr["dm"])
				var db := tb * float(rr["dm"])
				var quad := [Vector3(xa.x, 0, xa.y), Vector3(xa.x, ha, xa.y), Vector3(xb.x, hb, xb.y), Vector3(xb.x, 0, xb.y)]
				var uvq := [Vector2(da, 0), Vector2(da, -ha), Vector2(db, -hb), Vector2(db, 0)]
				murs.append([quad, uvq])
				murs.append([[quad[0], quad[3], quad[2], quad[1]], [uvq[0], uvq[3], uvq[2], uvq[1]]])
		# corniche le long de l'anneau, à la jonction toiture / mur de fond des gradins
		var hd0 := _h_dos(a0, ah, rangs)
		var hd1 := _h_dos(a1, ah, rangs)
		var hd := minf(hd0, hd1)
		corniche.append(_rq(c, rl, rly, a1, a0, float(r0["h_in"]) - 0.12, hd, 0.0))
		corniche.append(_rq(c, rl + 0.16, rly + 0.16, a1, a0, hd - 0.24, hd - 0.02, 0.0))
		corniche.append(_rt(c, rl, rly, rl + 0.16, rly + 0.16, a0, a1, hd - 0.02))
		corniche.append(_rt(c, rl, rly, rl + 0.16, rly + 0.16, a1, a0, hd - 0.24))
	var mt: MeshInstance3D = sc._faces(toit, m64("tuiles", "maillage", 1.0, true))
	mt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mt.name = "Galerie_toiture"
	var mw: MeshInstance3D = sc._faces(murs, m64("contrefort", "maillage", 1.0, true))
	mw.name = "Galerie_facades"
	var mc: MeshInstance3D = sc._faces(_deux(corniche), m64("moulure", "maillage", 1.8, true))
	mc.name = "Galerie_corniches"
	_contreforts(c, rl, rly, rect, garde, rayon, hauteur)


## P6.4 : contreforts rayonnants de la galerie (tous les 15°) : ils naissent du mur de fond des gradins, suivent la
## pente de la toiture et finissent en pilastre débordant sur la façade.
func _contreforts(c: Vector2, rl: float, rly: float, rect: Rect2, garde: Callable, rayon: Callable, hauteur: Callable) -> void:
	var faces: Array = []
	var dessus: Array = []
	for deg in range(0, 360, 15):
		var am := deg_to_rad(deg)
		if not (garde.call(am) and garde.call(am - 0.035) and garde.call(am + 0.035)):
			continue
		var r: Dictionary = rayon.call(am)
		var p: Vector2 = r["p"]
		var q: Vector2 = r["q"]
		var d := (q - p).normalized()
		var lat := Vector2(-d.y, d.x) * 0.28
		var m := int(ceil(float(r["dm"]) / 0.6))
		var pts_l: Array = []
		var pts_r: Array = []
		for k in m + 1:
			var t := float(k) / m
			var xz := p.lerp(q, t) - d * 0.25 * (1.0 - t)          # naît 25 cm dans le mur de fond
			if k == m:
				xz = q + d * 0.18                                 # pilastre débordant sur la façade
			var h: float = hauteur.call(r, t) + 0.42 - 0.12 * t
			pts_l.append([Vector3(xz.x + lat.x, h, xz.y + lat.y), t * float(r["dm"])])
			pts_r.append([Vector3(xz.x - lat.x, h, xz.y - lat.y), t * float(r["dm"])])
		for k in m:
			for side in [pts_l, pts_r]:
				var a0: Vector3 = side[k][0]
				var a1: Vector3 = side[k + 1][0]
				var u0: float = side[k][1]
				var u1: float = side[k + 1][1]
				var bas0 := maxf(a0.y - 1.2, 0.0)
				var bas1 := maxf(a1.y - 1.2, 0.0)
				var quad := [Vector3(a0.x, bas0, a0.z), Vector3(a0.x, a0.y, a0.z), Vector3(a1.x, a1.y, a1.z), Vector3(a1.x, bas1, a1.z)]
				var uv := [Vector2(u0, -bas0), Vector2(u0, -a0.y), Vector2(u1, -a1.y), Vector2(u1, -bas1)]
				if side == pts_r:
					faces.append([quad, uv])
				else:
					faces.append([[quad[0], quad[3], quad[2], quad[1]], [uv[0], uv[3], uv[2], uv[1]]])
			var l0: Vector3 = pts_l[k][0]
			var l1: Vector3 = pts_l[k + 1][0]
			var r0: Vector3 = pts_r[k][0]
			var r1: Vector3 = pts_r[k + 1][0]
			dessus.append([[l0, r0, r1, l1], [Vector2(pts_l[k][1], 0.0), Vector2(pts_l[k][1], 0.56), Vector2(pts_l[k + 1][1], 0.56), Vector2(pts_l[k + 1][1], 0.0)]])
		# tête du pilastre (du sol au chaperon)
		var lt: Vector3 = pts_l[m][0]
		var rt: Vector3 = pts_r[m][0]
		faces.append([[Vector3(lt.x, 0, lt.z), Vector3(lt.x, lt.y, lt.z), Vector3(rt.x, rt.y, rt.z), Vector3(rt.x, 0, rt.z)], [Vector2(0, 0), Vector2(0, -lt.y), Vector2(0.56, -rt.y), Vector2(0.56, 0)]])
		# flancs du pilastre sous la toiture (au droit de la façade, du sol à l'égout)
		var qa := q + lat
		var qb := q - lat
		var he: float = hauteur.call(r, 1.0)
		for pr in [[qa, lt], [qb, rt]]:
			var f0: Vector2 = pr[0]
			var t1: Vector3 = pr[1]
			var quad2 := [Vector3(f0.x, 0, f0.y), Vector3(t1.x, 0, t1.z), Vector3(t1.x, he, t1.z), Vector3(f0.x, he, f0.y)]
			faces.append([quad2, [Vector2(0, 0), Vector2(0.18, 0), Vector2(0.18, -he), Vector2(0, -he)]])
			faces.append([[quad2[0], quad2[3], quad2[2], quad2[1]], [Vector2(0, 0), Vector2(0, -he), Vector2(0.18, -he), Vector2(0.18, 0)]])
	if faces.is_empty():
		return
	var mf: MeshInstance3D = sc._faces(_deux(faces), m64("contrefort", "maillage", 1.0, true, Color(0.94, 0.92, 0.9)))
	mf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mf.name = "Galerie_contreforts"
	var md: MeshInstance3D = sc._faces(_deux(dessus), m64("moulure", "maillage", 1.0, true))
	md.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## P6.4.1 : SECOND PILOTE de la galerie des écoinçons (même emprise, mêmes exclusions, aucune collision).
##   A : toiture couverte de PETITES tuiles (rangs de 20 cm, tuiles de 13 cm), palette plus sombre et moins saturée,
##       usure discrète (tuiles remplacées, lichen, salissure) ; travées irrégulières (contreforts bas et sombres, pas
##       variable) ; légère flèche de chaque travée.
##   B : structure MIXTE : une bande couverte étroite (2,2 m) le long des gradins, ouverte vers l'extérieur par une
##       arcade ; au-delà, une terrasse maçonnée dallée plus basse, bordée d'un parapet ; piles de maçonnerie massives.
##       La toiture n'occupe plus qu'un liseré : la maçonnerie domine.
func _galerie_v2(variante: String, a: Dictionary, tunnels: Array, c: Vector2, rx: float, ry: float, ep: float, prof: float, rangs: int, ah: float) -> void:
	var rl := rx + ep + prof + 0.5
	var rly := ry + ep + prof + 0.5
	var vt: Dictionary = sc._p6.get("vue_tunnel", {})
	var y1: float = float(vt.get("entree", 37.5)) - 0.6
	var rect := Rect2(Vector2(c.x - rl, c.y - rly), Vector2(43.6 - (c.x - rl), y1 - (c.y - rly)))
	var exclus: Array = []
	for t in tunnels:
		exclus.append((t as Rect2).grow(0.3))
	exclus.append(Rect2(24.0, 30.0, 4.0, y1 - 30.0 + 0.5))
	var lg: Dictionary = a["loge"]
	exclus.append(Rect2(lg["centre"][0] - lg["taille"][0] * 0.5, lg["centre"][1] - lg["taille"][1] * 0.5, lg["taille"][0], lg["taille"][1]).grow(0.4))
	var mixte := variante == "B"
	var n := 288
	var coins := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	var garde := func(am: float) -> bool:
		var pm := Vector2(c.x + rl * cos(am), c.y + rly * sin(am))
		var qm := _vers_bord(c, pm, rect)
		if pm.distance_to(qm) < 0.05:
			return false
		for e in exclus:
			for t in [0.05, 0.35, 0.65, 0.95]:
				if (e as Rect2).has_point(pm.lerp(qm, t)):
					return false
		return true
	# travées : contreforts à pas irrégulier (15° ± 3,5°, tirés une fois pour toutes)
	var cotes: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 6404
	var ang := 0.0
	while ang < 360.0:
		var j := rng.randf_range(-3.5, 3.5) if not mixte else rng.randf_range(-1.0, 1.0)
		cotes.append(deg_to_rad(ang + j))
		ang += 15.0
	var travee := func(aa: float) -> float:             # position dans la travée, 0..1
		var x := fposmod(aa, TAU)
		for k in cotes.size():
			var c0: float = fposmod(cotes[k], TAU)
			var c1: float = fposmod(cotes[(k + 1) % cotes.size()], TAU)
			var span := fposmod(c1 - c0, TAU)
			var dx := fposmod(x - c0, TAU)
			if dx <= span:
				return dx / maxf(span, 1e-4)
		return 0.0
	var BANDE := 2.2
	var rayon := func(aa: float) -> Dictionary:
		var p := Vector2(c.x + rl * cos(aa), c.y + rly * sin(aa))
		var q := _vers_bord(c, p, rect)
		var h_in := _h_dos(aa, ah, rangs) - 0.32
		var dm := p.distance_to(q)
		var chute := minf(0.34 * dm, 0.3 * h_in) if not mixte else minf(0.5, 0.25 * h_in)
		var tb := 1.0 if not mixte else clampf(BANDE / maxf(dm, 0.01), 0.0, 1.0)
		if mixte and dm < BANDE + 0.6:
			tb = 1.0
		var h_t := maxf(h_in - 1.45, 0.9)              # terrasse (B)
		var fl := 0.0 if mixte else 0.06 * sin(PI * float(travee.call(aa)))
		return {"p": p, "q": q, "h_in": h_in, "dm": dm, "chute": chute, "tb": tb, "h_t": h_t, "fl": fl, "s": _arc_s(rl, rly, fposmod(aa, TAU))}
	# hauteur du toit (t dans [0, tb]) : appentis, flèche de la travée nulle contre la corniche
	var toit_h := func(r: Dictionary, t: float) -> float:
		var u := t / maxf(float(r["tb"]), 1e-4)
		return float(r["h_in"]) - float(r["chute"]) * u - float(r["fl"]) * smoothstep(0.0, 0.25, u)
	# hauteur du couronnement (toit, puis terrasse + parapet en B)
	var haut_h := func(r: Dictionary, t: float) -> float:
		if t <= float(r["tb"]) + 1e-4:
			return toit_h.call(r, t)
		return float(r["h_t"]) + 0.6
	var toit: Array = []
	var murs: Array = []
	var dalles: Array = []
	var corniche: Array = []
	var ombres: Array = []                # baies sombres de l'arcade (B)
	var ok: Array = []
	for i in n:
		ok.append(garde.call(TAU * (i + 0.5) / n))
	for i in n:
		if not ok[i]:
			continue
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var r0: Dictionary = rayon.call(a0)
		var r1: Dictionary = rayon.call(a1)
		var m := int(ceil(maxf(float(r0["dm"]) * float(r0["tb"]), float(r1["dm"]) * float(r1["tb"])) / 0.5))
		m = maxi(m, 1)
		for k in m:
			var pts: Array = []
			var uvs: Array = []
			for pr in [[r0, k], [r0, k + 1], [r1, k + 1], [r1, k]]:
				var rr: Dictionary = pr[0]
				var t: float = float(pr[1]) / m * float(rr["tb"])
				var xz: Vector2 = (rr["p"] as Vector2).lerp(rr["q"], t)
				var lam := (xz - c).length() / ((rr["p"] as Vector2) - c).length()
				pts.append(Vector3(xz.x, toit_h.call(rr, t), xz.y))
				uvs.append(Vector2(float(rr["s"]) * lam, -t * float(rr["dm"])))
			toit.append([pts, uvs])
		var q0: Vector2 = r0["q"]
		var q1: Vector2 = r1["q"]
		var tb0: float = r0["tb"]
		var tb1: float = r1["tb"]
		var mix_seg := mixte and (tb0 < 0.999 or tb1 < 0.999)
		if mix_seg:
			# terrasse dallée de tb au bord, et front de la bande couverte (mur d'arcade) de la terrasse au toit
			var e0: Vector2 = (r0["p"] as Vector2).lerp(q0, tb0)
			var e1: Vector2 = (r1["p"] as Vector2).lerp(q1, tb1)
			var ht0: float = r0["h_t"]
			var ht1: float = r1["h_t"]
			var poly: Array = [Vector3(e0.x, ht0, e0.y), Vector3(q0.x, ht0, q0.y)]
			for kk in coins:
				var kc: Vector2 = kk
				if _entre((kc - c).angle(), (q0 - c).angle(), (q1 - c).angle()):
					poly.append(Vector3(kc.x, (ht0 + ht1) * 0.5, kc.y))
			poly.append(Vector3(q1.x, ht1, q1.y))
			poly.append(Vector3(e1.x, ht1, e1.y))
			for j in range(1, poly.size() - 1):
				var tri := [poly[0], poly[j], poly[j + 1]]
				dalles.append([tri, tri.map(func(v): return Vector2((v as Vector3).x, (v as Vector3).z))])
			var f0 := Vector3(e0.x, toit_h.call(r0, tb0), e0.y)
			var f1 := Vector3(e1.x, toit_h.call(r1, tb1), e1.y)
			var u0 := float(r0["s"]) * 1.12
			var u1 := float(r1["s"]) * 1.12
			murs.append([[Vector3(e0.x, ht0 - 0.05, e0.y), f0, f1, Vector3(e1.x, ht1 - 0.05, e1.y)], [Vector2(u0, -ht0), Vector2(u0, -f0.y), Vector2(u1, -f1.y), Vector2(u1, -ht1)]])
		# bord extérieur : façade (deux faces), égout (A) ou parapet (B)
		var hb0: float = haut_h.call(r0, 1.0)
		var hb1: float = haut_h.call(r1, 1.0)
		var bord: Array = [Vector3(q0.x, hb0, q0.y)]
		for kk in coins:
			var kc2: Vector2 = kk
			if _entre((kc2 - c).angle(), (q0 - c).angle(), (q1 - c).angle()):
				var hk := minf(hb0, hb1) - (0.0 if mix_seg else 0.12)
				if not mix_seg:
					var lam2 := (kc2 - c).length() / ((r0["p"] as Vector2) - c).length()
					toit.append([[Vector3(q0.x, hb0, q0.y), Vector3(kc2.x, hk, kc2.y), Vector3(q1.x, hb1, q1.y)],
						[Vector2(float(r0["s"]) * lam2, -float(r0["dm"])), Vector2(float(r0["s"]) * lam2, -(kc2 - (r0["p"] as Vector2)).length()), Vector2(float(r1["s"]) * lam2, -float(r1["dm"]))]])
				bord.append(Vector3(kc2.x, hk, kc2.y))
		bord.append(Vector3(q1.x, hb1, q1.y))
		for j in range(bord.size() - 1):
			var b0: Vector3 = bord[j]
			var b1: Vector3 = bord[j + 1]
			var uu0 := b0.x + b0.z
			var uu1 := b1.x + b1.z
			murs.append([[Vector3(b0.x, 0.0, b0.z), Vector3(b0.x, b0.y, b0.z), Vector3(b1.x, b1.y, b1.z), Vector3(b1.x, 0.0, b1.z)], [Vector2(uu0, 0), Vector2(uu0, -b0.y), Vector2(uu1, -b1.y), Vector2(uu1, 0)]])
			var dir := Vector2(b1.x - b0.x, b1.z - b0.z).normalized()
			var nrm := Vector2(-dir.y, dir.x)
			if nrm.dot(Vector2((b0.x + b1.x) * 0.5, (b0.z + b1.z) * 0.5) - c) < 0.0:
				nrm = -nrm
			if mix_seg:
				# parapet : face intérieure (30 cm en retrait) et chaperon
				var inn := -Vector3(nrm.x, 0, nrm.y) * 0.3
				var hb := b0.y - 0.6
				var hb2 := b1.y - 0.6
				murs.append([[b0 + inn + Vector3(0, hb - b0.y, 0), b0 + inn, b1 + inn, b1 + inn + Vector3(0, hb2 - b1.y, 0)], [Vector2(uu0, -hb), Vector2(uu0, -b0.y), Vector2(uu1, -b1.y), Vector2(uu1, -hb2)]])
				corniche.append([[b0 + Vector3(0, 0.0, 0) - inn * 0.1, b0 + inn * 1.1, b1 + inn * 1.1, b1 - inn * 0.1], [Vector2(uu0, 0), Vector2(uu0, 0.36), Vector2(uu1, 0.36), Vector2(uu1, 0)]])
			else:
				var o := Vector3(nrm.x, 0, nrm.y) * 0.22
				var e0b := b0 + Vector3(0, 0.02, 0)
				var e1b := b1 + Vector3(0, 0.02, 0)
				corniche.append([[e0b, e0b + o + Vector3(0, -0.05, 0), e1b + o + Vector3(0, -0.05, 0), e1b], [Vector2(uu0, 0), Vector2(uu0, 0.22), Vector2(uu1, 0.22), Vector2(uu1, 0)]])
		# retours de mur au bord d'un passage (profil du couronnement)
		for side in [[r0, (i - 1 + n) % n], [r1, (i + 1) % n]]:
			if ok[side[1]]:
				continue
			var rr: Dictionary = side[0]
			var mm := int(ceil(float(rr["dm"]) / 0.5))
			for k in mm:
				var ta := float(k) / mm
				var tb2 := float(k + 1) / mm
				var xa: Vector2 = (rr["p"] as Vector2).lerp(rr["q"], ta)
				var xb: Vector2 = (rr["p"] as Vector2).lerp(rr["q"], tb2)
				var ha: float = haut_h.call(rr, ta)
				var hb3: float = haut_h.call(rr, tb2)
				var da := ta * float(rr["dm"])
				var db := tb2 * float(rr["dm"])
				murs.append([[Vector3(xa.x, 0, xa.y), Vector3(xa.x, ha, xa.y), Vector3(xb.x, hb3, xb.y), Vector3(xb.x, 0, xb.y)], [Vector2(da, 0), Vector2(da, -ha), Vector2(db, -hb3), Vector2(db, 0)]])
		# corniche de l'anneau (pierre sombre, plus fine)
		var hd := minf(_h_dos(a0, ah, rangs), _h_dos(a1, ah, rangs))
		corniche.append(_rq(c, rl, rly, a1, a0, float(r0["h_in"]) - 0.12, hd, 0.0))
		corniche.append(_rq(c, rl + 0.12, rly + 0.12, a1, a0, hd - 0.2, hd - 0.02, 0.0))
		corniche.append(_rt(c, rl, rly, rl + 0.12, rly + 0.12, a0, a1, hd - 0.02))
	# baies de l'arcade (B) : une ouverture sombre cintrée par travée, sur le front de la bande couverte
	if mixte:
		for k in cotes.size():
			var c0: float = cotes[k]
			var c1: float = cotes[(k + 1) % cotes.size()]
			if c1 < c0:
				c1 += TAU
			var am := (c0 + c1) * 0.5
			if not (garde.call(am) and garde.call(am - 0.05) and garde.call(am + 0.05)):
				continue
			var r: Dictionary = rayon.call(am)
			if float(r["tb"]) >= 0.999:
				continue
			var ra: Dictionary = rayon.call(am - 0.01)
			var rb: Dictionary = rayon.call(am + 0.01)
			var pe: Vector2 = (r["p"] as Vector2).lerp(r["q"], r["tb"])
			var pa: Vector2 = (ra["p"] as Vector2).lerp(ra["q"], ra["tb"])
			var pb: Vector2 = (rb["p"] as Vector2).lerp(rb["q"], rb["tb"])
			var tg := (pb - pa).normalized()
			var nn := (pe - c).normalized()
			var h0: float = r["h_t"]
			var htop: float = toit_h.call(r, r["tb"])
			var hh := (htop - h0) * 0.78
			var demi := minf(0.75, 0.45 * hh)
			var base := Vector3(pe.x, h0, pe.y) + Vector3(nn.x, 0, nn.y) * 0.02
			var tg3 := Vector3(tg.x, 0, tg.y)
			var pts2: Array = [base - tg3 * demi, base - tg3 * demi + Vector3(0, hh - demi, 0)]
			for s2 in range(1, 8):
				var th := PI * s2 / 8.0
				pts2.append(base - tg3 * demi * cos(th) + Vector3(0, hh - demi + demi * sin(th), 0))
			pts2.append(base + tg3 * demi + Vector3(0, hh - demi, 0))
			pts2.append(base + tg3 * demi)
			for j in range(1, pts2.size() - 1):
				ombres.append([[pts2[0], pts2[j], pts2[j + 1]], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]])
	var mt: MeshInstance3D = sc._faces(toit, m64("tuiles_a", "maillage", 1.0, true))
	mt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mt.name = "Galerie_toiture"
	var mw: MeshInstance3D = sc._faces(_deux(murs), m64("contrefort", "maillage", 1.0, true, Color(0.92, 0.9, 0.88)))
	mw.name = "Galerie_murs"
	if not dalles.is_empty():
		var md: MeshInstance3D = sc._faces(dalles, m64("dalle", "maillage", 1.0, true, Color(0.78, 0.76, 0.73)))
		md.name = "Galerie_terrasse"
	var mc: MeshInstance3D = sc._faces(_deux(corniche), m64("moulure", "maillage", 1.0, true, Color(0.8, 0.78, 0.76)))
	mc.name = "Galerie_corniches"
	if not ombres.is_empty():
		var mo: MeshInstance3D = sc._faces(_deux(ombres), uni(Color(0.07, 0.06, 0.06), 1.0))
		mo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mo.name = "Galerie_arcade"
	_contreforts_v2(mixte, c, rect, cotes, garde, rayon, toit_h, haut_h)


## P6.4.1 : contreforts du second pilote. A : nervures basses et sombres (18 cm au-dessus des tuiles), pas irrégulier ;
## B : piles de maçonnerie massives (60 cm), qui dépassent le parapet de la terrasse.
func _contreforts_v2(mixte: bool, c: Vector2, rect: Rect2, cotes: Array, garde: Callable, rayon: Callable, toit_h: Callable, haut_h: Callable) -> void:
	var faces: Array = []
	var dessus: Array = []
	var larg := 0.3 if mixte else 0.17
	var sur := 0.32 if mixte else 0.16
	for am0 in cotes:
		var am: float = am0
		if not (garde.call(am) and garde.call(am - 0.03) and garde.call(am + 0.03)):
			continue
		var r: Dictionary = rayon.call(am)
		var p: Vector2 = r["p"]
		var q: Vector2 = r["q"]
		var d := (q - p).normalized()
		var lat := Vector2(-d.y, d.x) * larg
		var m := int(ceil(float(r["dm"]) / 0.4))
		var pl: Array = []
		var pr: Array = []
		for k in m + 1:
			var t := float(k) / m
			var xz := p.lerp(q, t) - d * 0.2 * (1.0 - t)
			if k == m:
				xz = q + d * (0.16 if mixte else 0.1)
			var h: float = haut_h.call(r, minf(t, 0.999) if t < 1.0 else 1.0) + sur
			if mixte and t > float(r["tb"]) + 1e-4:
				h = float(r["h_t"]) + 0.6 + sur + 0.12
			pl.append([Vector3(xz.x + lat.x, h, xz.y + lat.y), t * float(r["dm"])])
			pr.append([Vector3(xz.x - lat.x, h, xz.y - lat.y), t * float(r["dm"])])
		for k in m:
			for side in [pl, pr]:
				var a0: Vector3 = side[k][0]
				var a1: Vector3 = side[k + 1][0]
				var u0: float = side[k][1]
				var u1: float = side[k + 1][1]
				var bas0 := maxf(a0.y - 1.4, 0.0)
				var bas1 := maxf(a1.y - 1.4, 0.0)
				faces.append([[Vector3(a0.x, bas0, a0.z), Vector3(a0.x, a0.y, a0.z), Vector3(a1.x, a1.y, a1.z), Vector3(a1.x, bas1, a1.z)], [Vector2(u0, -bas0), Vector2(u0, -a0.y), Vector2(u1, -a1.y), Vector2(u1, -bas1)]])
			dessus.append([[pl[k][0], pr[k][0], pr[k + 1][0], pl[k + 1][0]], [Vector2(pl[k][1], 0.0), Vector2(pl[k][1], larg * 2.0), Vector2(pl[k + 1][1], larg * 2.0), Vector2(pl[k + 1][1], 0.0)]])
		var lt: Vector3 = pl[m][0]
		var rt: Vector3 = pr[m][0]
		faces.append([[Vector3(lt.x, 0, lt.z), Vector3(lt.x, lt.y, lt.z), Vector3(rt.x, rt.y, rt.z), Vector3(rt.x, 0, rt.z)], [Vector2(0, 0), Vector2(0, -lt.y), Vector2(larg * 2.0, -rt.y), Vector2(larg * 2.0, 0)]])
		var he: float = haut_h.call(r, 1.0)
		for pr2 in [[q + lat, lt], [q - lat, rt]]:
			var f0: Vector2 = pr2[0]
			var t1: Vector3 = pr2[1]
			faces.append([[Vector3(f0.x, 0, f0.y), Vector3(t1.x, 0, t1.z), Vector3(t1.x, he, t1.z), Vector3(f0.x, he, f0.y)], [Vector2(0, 0), Vector2(0.16, 0), Vector2(0.16, -he), Vector2(0, -he)]])
	if faces.is_empty():
		return
	var mf: MeshInstance3D = sc._faces(_deux(faces), m64("contrefort", "maillage", 1.0, true, Color(0.8, 0.78, 0.76) if not mixte else Color(0.95, 0.93, 0.9)))
	mf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mf.name = "Galerie_contreforts"
	var md: MeshInstance3D = sc._faces(_deux(dessus), m64("contrefort", "maillage", 1.0, true, Color(0.72, 0.7, 0.68)))
	md.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## Faces visibles des deux côtés (orientation sans importance) : chaque face est doublée à l'envers.
func _deux(faces: Array) -> Array:
	var out := faces.duplicate()
	for f in faces:
		var pts: Array = (f[0] as Array).duplicate()
		var uv: Array = (f[1] as Array).duplicate()
		pts.reverse()
		uv.reverse()
		out.append([pts, uv])
	return out


func _vers_bord(c: Vector2, p: Vector2, r: Rect2) -> Vector2:
	var d := (p - c).normalized()
	var t := INF
	if absf(d.x) > 1e-5:
		for x in [r.position.x, r.end.x]:
			var tt: float = (x - c.x) / d.x
			if tt > 0.0:
				t = minf(t, tt)
	if absf(d.y) > 1e-5:
		for y in [r.position.y, r.end.y]:
			var tt2: float = (y - c.y) / d.y
			if tt2 > 0.0:
				t = minf(t, tt2)
	var q := c + d * t
	return q if (q - c).length() > (p - c).length() else p


func _entre(v: float, v0: float, v1: float) -> bool:
	var a := fposmod(v - v0, TAU)
	var b := fposmod(v1 - v0, TAU)
	return a > 0.0 and a < b and b < PI


func _colonne(base: Vector3, h: float, m: Material) -> void:
	var cy := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.2
	cm.bottom_radius = 0.24
	cm.height = h
	cm.radial_segments = 10
	cy.mesh = cm
	cy.material_override = m
	cy.position = base + Vector3(0, h / 2.0, 0)
	sc.root.add_child(cy)
	sc._box_mesh(base + Vector3(0, 0.1, 0), Vector3(0.6, 0.2, 0.6), m)
	sc._box_mesh(base + Vector3(0, h - 0.08, 0), Vector3(0.58, 0.16, 0.58), m)


func _banniere_podium(p: Vector3, an: float, _c: Vector2, _rx: float, _ry: float, col: Color) -> void:
	if sc.has_method("modele"):
		# P6.3 : vraie bannière d'étoffe (Quaternius), pendue sous le chaperon du podium, tournée vers le centre ; seule
		# l'étoffe prend la couleur (plus de plaque carrée plaquée sur la pierre)
		var vers := Vector3(_c.x - p.x, 0.0, _c.y - p.z).normalized()
		var q := p + vers * 0.06 + Vector3(0, 1.5, 0)
		# l'étoffe d'origine est sombre : la teinte est fortement relevée pour garder les couleurs de la Guilde lisibles
		var tis := Color(col.r * 3.4 + 0.25, col.g * 2.4 + 0.1, col.b * 1.5)       # étoffe d'origine bleutée : canal par canal
		sc.modele("fp/Banner_2_Cloth", q, atan2(vers.x, vers.z), 0.7, tis, {"teinte_tissu": true})
		return
	var tissu := uni(col, 1.0)
	tissu.cull_mode = BaseMaterial3D.CULL_DISABLED
	var b: MeshInstance3D = sc._box_mesh(p + Vector3(0, 0.95, 0), Vector3(0.9, 0.95, 0.03), tissu)
	b.rotation.y = -an + PI / 2.0
	var o: MeshInstance3D = sc._box_mesh(p + Vector3(0, 1.0, 0) - Vector3(cos(an), 0, sin(an)) * 0.03, Vector3(0.26, 0.26, 0.02), uni(C_OR, 0.5, 0.4))
	o.rotation.y = -an + PI / 2.0


func _brasero(p: Vector3) -> void:
	sc._box_mesh(p + Vector3(0, 0.12, 0), Vector3(0.36, 0.24, 0.36), uni(Color(0.2, 0.18, 0.18), 0.6, 0.5))
	var feu := StandardMaterial3D.new()
	feu.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	feu.albedo_color = Color(1.0, 0.6, 0.2)
	sc._box_mesh(p + Vector3(0, 0.28, 0), Vector3(0.22, 0.1, 0.22), feu)
	sc._halo(p + Vector3(0, 0.45, 0), 1.0, 0.55)
	sc._light(p + Vector3(0, 0.7, 0), 0.9, 5.0)


func _arc_tunnel(t: Rect2, m: Material, m2: Material) -> void:
	var sud := t.size.y > t.size.x
	var largeur: float = t.size.x if sud else t.size.y
	var c := Vector3(t.get_center().x, 0, t.position.y + 1.2) if sud else Vector3(t.position.x + 1.0, 0, t.get_center().y)
	var axe := Vector3(1, 0, 0) if sud else Vector3(0, 0, 1)
	var prof := Vector3(0, 0, 1) if sud else Vector3(1, 0, 0)
	var hp := 2.0
	for s in [-1.0, 1.0]:
		var pc: Vector3 = c + axe * s * (largeur / 2.0 + 0.3)
		var b: MeshInstance3D = sc._box_mesh(pc + Vector3(0, hp / 2.0 + 0.3, 0), Vector3(0.6, hp + 0.6, 0.9) if sud else Vector3(0.9, hp + 0.6, 0.6), m2)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var r := largeur / 2.0 + 0.3
	var nseg := 9
	for i in nseg:
		var a0 := PI * i / nseg
		var a1 := PI * (i + 1) / nseg
		var am := (a0 + a1) / 2.0
		var pos := c + axe * (-cos(am) * r) + Vector3(0, hp + 0.3 + sin(am) * r * 0.62, 0)
		var seg: MeshInstance3D = sc._box_mesh(pos, Vector3(0.62, 0.42, 0.9) if sud else Vector3(0.9, 0.42, 0.62), m if i != nseg / 2 else (mz("moulure", "arene", "monde", 1.0, true, Color(1.12, 1.04, 0.86)) if extension and p64 else mat(PIERRE, 2.4, C_OR * Color(1.2, 1.2, 1.2), true)))
		var ang := am - PI / 2.0
		if sud:
			seg.rotation.z = ang
		else:
			seg.rotation.x = -ang
	sc._box_mesh(c + Vector3(0, hp + 0.3 + r * 0.62 + 0.35, 0), Vector3(largeur + 1.6, 0.3, 1.0) if sud else Vector3(1.0, 0.3, largeur + 1.6), m)


# ------------------------------------------------------------------------------------------------ loge
func loge(lg: Dictionary) -> void:
	var lc := Vector3(lg["centre"][0], 0.0, lg["centre"][1])
	var ls := Vector2(lg["taille"][0], lg["taille"][1])
	var lh: float = lg["h"]
	var pierre := mat(PIERRE, 2.4, C_CALCAIRE * Color(1.08, 1.04, 1.0), true)
	var dalle_loge: Material = mat(PIERRE, 2.4, C_CALCAIRE * Color(1.2, 1.15, 1.1), true)
	var corps: Material = pierre
	if extension and p64:
		# P6.4.2 : la loge dans l'appareil de l'arène, plus soignée (moulures claires, corps en grand appareil)
		pierre = mz("moulure", "arene", "monde", 1.0, true, Color(1.04, 1.02, 0.98))
		dalle_loge = mz("dalle", "arene", "monde", 1.0, true)
		corps = mz("contrefort", "arene", "monde", 1.0, true, Color(1.05, 1.03, 1.0))
	sc._box_mesh(lc + Vector3(0, lh / 2.0, 0), Vector3(ls.x, lh, ls.y), corps)
	sc._box_mesh(lc + Vector3(0, lh + 0.08, 0.2), Vector3(ls.x + 0.4, 0.16, ls.y + 0.5), dalle_loge)
	# balustrade
	for i in 11:
		var x := -ls.x / 2.0 + 0.3 + (ls.x - 0.6) * i / 10.0
		sc._box_mesh(lc + Vector3(x, lh + 0.45, ls.y / 2.0 + 0.1), Vector3(0.1, 0.6, 0.1), pierre)
	sc._box_mesh(lc + Vector3(0, lh + 0.8, ls.y / 2.0 + 0.1), Vector3(ls.x, 0.1, 0.18), pierre)
	# colonnes et dais rouge et or
	for x in [-ls.x / 2.0 + 0.3, -ls.x / 6.0, ls.x / 6.0, ls.x / 2.0 - 0.3]:
		_colonne(lc + Vector3(x, lh + 0.16, ls.y / 2.0 - 0.1), 2.1, pierre)
	var rouge := uni(Color(0.6, 0.12, 0.16), 1.0)
	rouge.cull_mode = BaseMaterial3D.CULL_DISABLED
	var dais: MeshInstance3D = sc._box_mesh(lc + Vector3(0, lh + 2.45, 0.1), Vector3(ls.x + 0.5, 0.1, ls.y + 0.6), rouge)
	dais.rotation.x = 0.12
	sc._box_mesh(lc + Vector3(0, lh + 2.2, ls.y / 2.0 + 0.32), Vector3(ls.x + 0.5, 0.36, 0.04), uni(C_OR, 0.5, 0.3))
	sc._box_mesh(lc + Vector3(0, lh - 0.8, ls.y / 2.0 + 0.04), Vector3(ls.x - 0.8, 1.3, 0.04), rouge)
	sc._box_mesh(lc + Vector3(0, lh - 0.8, ls.y / 2.0 + 0.07), Vector3(0.6, 0.6, 0.02), uni(C_OR, 0.45, 0.5))
	# trône et sièges (silhouettes)
	sc._box_mesh(lc + Vector3(0, lh + 0.6, -0.4), Vector3(0.8, 1.0, 0.6), rouge)


# ------------------------------------------------------------------------------------------------ vestiaires
## r : rectangle praticable des vestiaires (plan). Décor posé sur les meubles existants ou contre les murs.
func vestiaires(r: Rect2) -> void:
	var pierre := mat(PIERRE, 2.4, C_CALCAIRE * Color(0.96, 0.94, 0.92), true)
	var plinthe := mat(PIERRE, 1.2, C_CALCAIRE * Color(0.7, 0.68, 0.68))
	var bois := mat(PLANCHES, 1.6, Color(0.78, 0.62, 0.5))
	var bois_sombre := mat(PLANCHES, 1.6, Color(0.5, 0.38, 0.32))
	# plancher plus chaleureux avec bordure de dalles
	var bordure: Material = mat(PAVES, 1.6, Color(0.8, 0.76, 0.74))
	if extension and p64:
		# P6.4.2 : plancher procédural (sol de la pièce, préréglage « plancher ») ; bordure en dalles du Colisée
		bordure = mz("dallage", "vestiaires", "monde", 1.0, false, Color(0.92, 0.9, 0.88))
	else:
		sc._box_mesh(Vector3(r.get_center().x, 0.004, r.get_center().y), Vector3(r.size.x, 0.008, r.size.y), mat(PLANCHES, 2.0, Color(0.56, 0.5, 0.46)))
	for e in [[r.position.x, r.position.y, r.size.x, 0.45], [r.position.x, r.end.y - 0.45, r.size.x, 0.45], [r.position.x, r.position.y, 0.45, r.size.y], [r.end.x - 0.45, r.position.y, 0.45, r.size.y]]:
		sc._box_mesh(Vector3(e[0] + e[2] / 2.0, 0.012, e[1] + e[3] / 2.0), Vector3(e[2], 0.02, e[3]), bordure)
	# plinthes et poutre haute le long du mur nord (vu de face)
	# P6.3 : plinthe interrompue au droit de la porte nord (elle formait une « marche » de 36 cm qu'Aren traversait)
	var porte := Vector2(24.5, 27.5)
	if p64:
		plinthe = mm("socle", "vestiaires", "monde")         # P6.4 : mur nord pilote (soubassement de gros blocs)
	for seg in [Vector2(r.position.x, porte.x), Vector2(porte.y, r.end.x)]:
		sc._box_mesh(Vector3((seg.x + seg.y) * 0.5, 0.18, r.position.y - 0.02), Vector3(seg.y - seg.x, 0.36, 0.1), plinthe)
	var pb := porte
	if p64:
		pb = Vector2(24.2, 27.8)
		_encadrement_p64(porte, r.position.y)
		# P6.4 : lumière locale : la salle d'attente éclaire le passage (porte lisible, encadrement modelé)
		lum_fixe(Vector3(26.0, 2.1, r.position.y - 1.2), 1.3, 4.2, Color(1.0, 0.74, 0.46))
		lum_fixe(Vector3(26.0, 2.6, r.position.y + 1.6), 0.45, 5.0, Color(1.0, 0.8, 0.6))
	# P6.3.1 : poutre haute interrompue au droit de la porte (elle traversait l'ouverture et restait en l'air quand le
	# mur nord est coupé) ; poutre et poteaux suivent la coupe du mur nord
	for seg in [Vector2(r.position.x - 0.4, pb.x), Vector2(pb.y, r.end.x + 0.4)]:
		var pt: MeshInstance3D = sc._box_mesh(Vector3((seg.x + seg.y) * 0.5, 2.82, r.position.y - 0.04), Vector3(seg.y - seg.x, 0.22, 0.2), bois_sombre)
		if sc.get("_au_mur") != null:
			sc._au_mur.append(pt)
	for x in [r.position.x + 2.0, r.get_center().x - 3.6, r.get_center().x + 3.6, r.end.x - 2.0]:
		var po: MeshInstance3D = sc._box_mesh(Vector3(x, 1.42, r.position.y - 0.02), Vector3(0.24, 2.84, 0.16), bois_sombre)
		if sc.get("_au_mur") != null:
			sc._au_mur.append(po)
	# casiers à portes (sur l'emprise des casiers des données)
	for q in [Rect2(16.2, 46.6, 6.4, 0.6), Rect2(29.4, 46.6, 6.4, 0.6)]:
		_casiers(q, 2.0, bois, bois_sombre)
	_casiers_vertical(Rect2(16.1, 49.0, 0.6, 4.5), 2.0, bois, bois_sombre)
	# râtelier garni, accessoires peints (P6.2 : tapis et lanternes sur pied retirés, axe central dégagé)
	var fer := uni(Color(0.72, 0.74, 0.8), 0.35, 0.8)
	if sc.has_method("modele"):
		# P6.3 : râtelier, coffre et caisses = modèles (données) ; ici : bannières de la porte, patères, tonneau
		for bx in [24.0, 28.0]:
			sc._au_mur.append(sc.modele("fp/Banner_2_Cloth", Vector3(bx, 2.6, 46.58), 0.0, 0.78))
		for px in [19.4, 32.6]:
			sc._au_mur.append(sc.modele("fp/Peg_Rack", Vector3(px, 1.75, 46.52), 0.0, 1.0))
		sc.modele("fp/Barrel", Vector3(34.9, 0, 54.1), 0.0, 1.0)
		sc.modele("fp/Stool", Vector3(21.0, 0, 51.4), 0.3, 1.0)
		if sc.has_method("_solide_rond"):
			var dy: float = sc._dy_sud                       # bloc sud décalé (longueur du tunnel)
			sc._solide_rond(Vector2(34.9, 54.1 + dy), 0.36, 0.9)
			sc._solide_rond(Vector2(21.0, 51.4 + dy), 0.26, 0.6)
		sc._card("props/bois02_buches.png", Vector3(34.9, 0, 48.15), 1.1, {"anchor": 0.12})
		return
	for i in 7:
		var z := 49.45 + i * 0.47
		sc._box_mesh(Vector3(35.1, 0.95, z), Vector3(0.05, 1.5, 0.08), fer)
		sc._box_mesh(Vector3(35.1, 0.32, z), Vector3(0.16, 0.06, 0.16), uni(Color(0.45, 0.3, 0.2)))
	for z in [49.6, 52.2]:
		var bouclier := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.38
		cm.bottom_radius = 0.38
		cm.height = 0.06
		bouclier.mesh = cm
		bouclier.material_override = uni(Color(0.32, 0.4, 0.62), 0.6, 0.3)
		bouclier.rotation = Vector3(0, 0, PI / 2.0)
		bouclier.position = Vector3(35.62, 1.3, z)
		sc.root.add_child(bouclier)
	sc._card("props/tont01_tonneau.png", Vector3(34.9, 0, 54.1), 0.9, {"anchor": 0.08, "blob": 0.8})
	sc._card("props/cais01_caisse.png", Vector3(17.2, 0, 54.3), 1.05, {"anchor": 0.1, "blob": 0.9})
	sc._card("props/sac01_sacs.png", Vector3(18.3, 0, 54.5), 0.9, {"anchor": 0.08})
	sc._card("props/bois02_buches.png", Vector3(34.9, 0, 48.15), 1.1, {"anchor": 0.12})
	sc._card("props/bann02_bleue.png", Vector3(24.0, 0, 46.65), 1.0, {"anchor": 0.05})
	sc._card("props/bann02_bleue.png", Vector3(28.0, 0, 46.65), 1.0, {"anchor": 0.05})


## P6.4 : encadrement de pierre de la porte nord des vestiaires (pilote) : jambages en saillie, plate-bande en
## claveaux avec clé, sur la face intérieure du mur ; suit la coupe du mur nord. Décor seul (hors du passage : la
## largeur praticable de 3 m est intacte).
func _encadrement_p64(porte: Vector2, y_face: float) -> void:
	var m := mm("moulure", "vestiaires", "monde", 1.0, true)
	var ms := mm("contrefort", "vestiaires", "monde", 1.0, true)
	var els: Array = []
	for x in [porte.x - 0.15, porte.y + 0.15]:
		els.append(sc._box_mesh(Vector3(x, 1.27, y_face + 0.06), Vector3(0.3, 2.54, 0.14), m))
		els.append(sc._box_mesh(Vector3(x, 0.2, y_face + 0.08), Vector3(0.36, 0.4, 0.18), ms))       # base
		els.append(sc._box_mesh(Vector3(x, 2.5, y_face + 0.08), Vector3(0.38, 0.1, 0.18), m))         # imposte
	# plate-bande en 7 claveaux, clé saillante
	var n := 7
	var w := (porte.y - porte.x + 0.6) / n
	for i in n:
		var x := porte.x - 0.3 + w * (i + 0.5)
		var cle := i == n / 2
		var h := 0.5 if cle else 0.4
		var b: MeshInstance3D = sc._box_mesh(Vector3(x, 2.55 + h * 0.5, y_face + (0.1 if cle else 0.07)), Vector3(w - 0.012, h, 0.16 if cle else 0.12), m)
		els.append(b)
	for e in els:
		(e as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if sc.get("_au_mur") != null:
			sc._au_mur.append(e)


func _casiers(q: Rect2, h: float, bois: Material, sombre: Material) -> void:
	var n := int(q.size.x / 0.8)
	var w := q.size.x / n
	for i in n:
		var x := q.position.x + w * (i + 0.5)
		sc._box_mesh(Vector3(x, h / 2.0, q.end.y + 0.015), Vector3(w - 0.06, h - 0.08, 0.03), bois)
		sc._box_mesh(Vector3(x, h * 0.82, q.end.y + 0.035), Vector3(w * 0.5, 0.05, 0.02), sombre)
		sc._box_mesh(Vector3(x + w * 0.32, h * 0.5, q.end.y + 0.04), Vector3(0.04, 0.12, 0.03), uni(Color(0.8, 0.66, 0.3), 0.4, 0.7))
	sc._box_mesh(Vector3(q.get_center().x, h + 0.04, q.get_center().y), Vector3(q.size.x + 0.08, 0.08, q.size.y + 0.08), sombre)


func _casiers_vertical(q: Rect2, h: float, bois: Material, sombre: Material) -> void:
	var n := int(q.size.y / 0.8)
	var w := q.size.y / n
	for i in n:
		var z := q.position.y + w * (i + 0.5)
		sc._box_mesh(Vector3(q.end.x + 0.015, h / 2.0, z), Vector3(0.03, h - 0.08, w - 0.06), bois)
		sc._box_mesh(Vector3(q.end.x + 0.035, h * 0.82, z), Vector3(0.02, 0.05, w * 0.5), sombre)
	sc._box_mesh(Vector3(q.get_center().x, h + 0.04, q.get_center().y), Vector3(q.size.x + 0.08, 0.08, q.size.y + 0.08), sombre)
