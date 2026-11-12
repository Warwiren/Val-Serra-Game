extends "res://tests/test_case.gd"
## Validation caméra A / C (reprise P3-07) : parcours « validation » et mesures de cadrage. Tests sans rendu.

const World25 = preload("res://src/explore25/world25.gd")
const Routes = preload("res://src/explore25/routes25.gd")


func test_validation_route_covers_the_brief_and_stays_on_walkable_ground() -> void:
	var r: Array = Routes.route("validation")
	check(r.size() > 40, "parcours « validation » défini")
	var dirs := {}
	var marks: Array = []
	var exits := 0
	for s in r:
		match s["do"]:
			"push":
				dirs[s["dir"]] = true
			"mark":
				marks.append(s["id"])
			"go":
				if s.get("exit", false):
					exits += 1
	check_eq(dirs.size(), 8, "les 8 directions du clavier sont parcourues (aller et retour)")
	for z in ["escalier", "maison", "arbre", "pont", "instance"]:
		check(marks.has(z), "tronçon « %s » présent" % z)
	check_eq(exits, 2, "sortie vers la petite instance et retour")
	# chaque point visé dans la scène témoin est tenable par le héros (aucune étape impossible par construction)
	var w = World25.load_world(World25.SPEC, "temoin")
	var bad: Array = []
	var in_instance := false
	for s in r:
		if s["do"] == "mark":
			in_instance = s["id"] == "instance"
		if s["do"] != "go" or s.get("exit", false) or in_instance:
			continue
		var p: Vector2 = s["to"]
		var ok := false
		for u in w.surfaces_under(p):
			if not w.stand(p, u["h"]).is_empty():
				ok = true
		if not ok:
			bad.append(s.get("id", str(p)))
	check_eq(bad, [], "tous les points du parcours sont praticables")
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/p4/avant_poste.tscn", "F5 : avant-poste P4 (promotion du 12 novembre 2026, brief P4)")
	check(ResourceLoader.exists("res://scenes/explore_hd2d/zone_exploration.tscn"), "ancienne exploration stable conservée (F6)")
