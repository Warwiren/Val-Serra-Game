extends "res://tests/test_case.gd"
## P4 — avant-poste de la lisière : données de la zone (data/p4), navigation par niveaux, liaisons d'instance,
## ressources. Tests sans rendu ; le parcours complet, les sondes de collision et la boucle de combat sont rejoués
## par les commandes de docs/P4_AVANT_POSTE.md (routes p4 / p4_sondes, tests/e2e_p4_retour.gd).

const World25 = preload("res://src/explore25/world25.gd")
const ZONE := "res://data/p4/avant_poste.json"
const INTERIEUR := "res://data/p4/interieur_poste.json"
const SCENE := "res://scenes/p4/avant_poste.tscn"
const GRID := 0.25


func _w(file := ZONE):
	return World25.load_world(file, "instance")


## Diffusion sur une grille de 25 cm avec les règles de déplacement du modèle (pas ≤ 25 cm, disque du personnage).
func _flood(w, start: Vector3) -> Dictionary:
	var seen := {}
	var key := func(p: Vector2, h: float) -> String: return "%d,%d,%d" % [roundi(p.x / GRID), roundi(p.y / GRID), roundi(h * 2.0)]
	var s0: Dictionary = w.stand(Vector2(start.x, start.y), start.z)
	var q: Array = [[Vector2(start.x, start.y), s0["h"], s0["id"]]]
	seen[key.call(q[0][0], q[0][1])] = q[0]
	while q.size() > 0:
		var cur: Array = q.pop_back()
		for d in [Vector2(GRID, 0), Vector2(-GRID, 0), Vector2(0, GRID), Vector2(0, -GRID)]:
			var np: Vector2 = cur[0] + d
			var s: Dictionary = w.stand(np, cur[1])
			if s.is_empty():
				continue
			var k: String = key.call(np, s["h"])
			if not seen.has(k):
				seen[k] = [np, s["h"], s["id"]]
				q.append(seen[k])
	return seen


func _ids(seen: Dictionary) -> Dictionary:
	var out := {}
	for k in seen:
		out[seen[k][2]] = out.get(seen[k][2], 0) + 1
	return out


func test_zone_has_the_five_areas_of_the_brief() -> void:
	var w = _w()
	var ids := []
	for r in w.regions:
		ids.append(r["id"])
	for need in ["cour", "terrasse", "escalier", "passage", "rive_ouest", "pont", "plaine"]:
		check(ids.has(need), "surface « %s » présente" % need)
	check_eq(w.max_h, 1.2, "terrasse à +1,20 m")
	check(w.elements.any(func(e): return e["type"] == "water"), "rivière présente")
	check(w.elements.any(func(e): return e["type"] == "house"), "bâtiment principal présent")
	check_eq(w.run_speed, 3.6, "vitesse P3 conservée pour la course (Maj)")
	check_eq(w.speed, 2.2, "P4.8 : marche à 2,2 m/s (pas dessiné de 0,48 m, ~4,6 pas/s, pieds sans glissement)")
	check_eq(w.actor_r, 0.28, "rayon du personnage P3 conservé")


func test_everything_is_reachable_on_foot_from_the_entrance() -> void:
	var w = _w()
	var ids := _ids(_flood(w, w.spawn))
	for need in ["cour", "escalier", "terrasse", "passage", "rive_ouest", "pont", "plaine"]:
		check(ids.get(need, 0) > 0, "« %s » atteignable à pied depuis l'entrée" % need)


func test_river_banks_and_walls_are_never_walkable() -> void:
	var w = _w()
	var seen := _flood(w, w.spawn)
	var wet := 0
	var in_wall := 0
	for k in seen:
		var p: Vector2 = seen[k][0]
		if p.x > 23.05 and p.x < 28.95 and seen[k][2] != "pont":
			wet += 1
		if p.x > 20.0 and p.x < 20.8 and (p.y < 14.8 or p.y > 17.2):
			in_wall += 1
	check_eq(wet, 0, "aucune position praticable dans la rivière ou sur les berges, hors pont")
	check_eq(in_wall, 0, "la muraille est ne se traverse que par la porte")
	check(w.stand(Vector2(26, 13), 0.0).is_empty(), "eau au nord du pont : non praticable")
	check(not w.stand(Vector2(26, 16), 0.0).is_empty(), "tablier du pont : praticable")
	check(w.stand(Vector2(12, 5), 1.2).is_empty(), "intérieur du volume du bâtiment : non praticable")
	check(w.stand(Vector2(8, 8.9), 1.2).is_empty(), "muret de la terrasse : non praticable")


func test_levels_are_linked_only_by_the_stairs() -> void:
	var w = _w()
	check(w.surface_at(Vector2(8, 9.4), 1.2).is_empty(), "pas de saut de la terrasse vers la cour")
	var mid: Dictionary = w.surface_at(Vector2(12, 10.5), 0.6)
	check(not mid.is_empty() and mid["ramp"], "escalier : rampe continue")
	check(absf(w.surface_at(Vector2(12, 9.1), 1.2)["h"] - 1.2) < 0.01, "haut de l'escalier à +1,20 m")
	check(absf(w.surface_at(Vector2(12, 11.9), 0.0)["h"]) < 0.01, "bas de l'escalier au niveau de la cour")


func test_building_door_and_interior_are_linked_both_ways() -> void:
	var w = _w()
	check_eq(w.triggers.size(), 1, "une porte d'entrée")
	var t: Dictionary = w.triggers[0]
	check_eq(t["to"], INTERIEUR, "la porte mène à l'intérieur du poste")
	check(FileAccess.file_exists(INTERIEUR), "données de l'intérieur présentes")
	var seen := _flood(w, w.spawn)
	var door := false
	for k in seen:
		if (t["rect"] as Rect2).has_point(seen[k][0]) and seen[k][1] > 1.0:
			door = true
	check(door, "le seuil de la porte est atteignable à pied depuis l'entrée")
	var wi = _w(INTERIEUR)
	var a: Vector3 = t["arrive"]
	check(not wi.stand(Vector2(a.x, a.y), a.z).is_empty(), "arrivée dans l'intérieur : position tenable")
	check_eq(wi.triggers.size(), 1, "une sortie dans l'intérieur")
	var back: Dictionary = wi.triggers[0]
	check_eq(back["to"], ZONE, "la sortie ramène à l'avant-poste")
	check(not (back["rect"] as Rect2).has_point(Vector2(a.x, a.y)), "arrivée intérieure hors de la zone de sortie")
	var b: Vector3 = back["arrive"]
	var sb: Dictionary = w.stand(Vector2(b.x, b.y), b.z)
	check(not sb.is_empty() and sb["id"] == "terrasse", "retour extérieur : sur la terrasse, position tenable")
	check(not (t["rect"] as Rect2).has_point(Vector2(b.x, b.y)), "retour extérieur hors du seuil (pas de boucle d'entrée)")
	var ok_exit := false
	var si := _flood(wi, wi.spawn)
	for k in si:
		if (back["rect"] as Rect2).has_point(si[k][0]):
			ok_exit = true
	check(ok_exit, "la sortie de l'intérieur est atteignable")


func test_encounter_npc_and_points_of_interest_are_placed_on_walkable_ground() -> void:
	var w = _w()
	var p4: Dictionary = w.adj["p4"]
	var m: Dictionary = p4["monstre"]
	var mp := Vector2(m["xy"][0], m["xy"][1])
	check_eq(w.surface_at(mp, 0.0).get("id", ""), "plaine", "le Vorgane est dans la plaine")
	check(mp.distance_to(Vector2(w.spawn.x, w.spawn.y)) > 20.0, "le Vorgane est loin de l'entrée")
	check(mp.distance_to(Vector2(29.5, 16)) > m["declenchement_m"] + 4.0, "pas de combat à la sortie du pont")
	check(not w.npc.is_empty() and w.surface_at(Vector2(w.npc["p"].x, w.npc["p"].y), 0.0).get("id", "") == "cour", "le garde est dans la cour")
	check_eq(w.pois.size(), 2, "deux panneaux à examiner")
	check(FileAccess.file_exists("res://data/p4/dialogue_garde.json"), "dialogue du garde présent")
	var d: Dictionary = JSON.parse_string(FileAccess.open("res://data/p4/dialogue_garde.json", FileAccess.READ).get_as_text())
	check(d.has("start") and d.has("after_victory") and d.has("speakers"), "dialogue : avant et après victoire")


func test_camera_zooms_and_azimuth() -> void:
	check_eq(rad_to_deg(World25.YAW), 20.0, "azimut 20°")
	var Cam25 = load("res://src/explore25/cam25.gd")
	check_eq(Cam25.ZOOMS, [2.0, 2.5, 3.0], "zooms ×2 / ×2,5 / ×3")
	check_eq(Cam25.ZOOMS[Cam25.DEFAULT_INDEX], 2.5, "×2,5 par défaut")


func test_p4_resources_exist() -> void:
	for f in ["mat/sol_herbe.png", "mat/sol_terre.png", "mat/sol_paves.png", "mat/roche.png", "mat/eau_courante.png", "mat/eau_galets.png",
		"mat/trs_herbe_terre.png", "mat/berge.png", "arbre/arb01_tronc.png", "arbre/arb01_feuillage_avant.png", "arbre/arb01_feuillage_arriere.png",
		"relief/rel01_mur_4m_h120.glb", "batiment/toit_violet.png", "batiment/facade_colombage.png", "pont/planches.png"]:
		check(ResourceLoader.exists("res://art/p4/" + f), "ressource art/p4/%s importée" % f)


func test_f5_launches_the_p4_demo_and_no_experimental_scene() -> void:
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), SCENE, "F5 lance la démo de l'avant-poste")
	for f in [SCENE, "res://scenes/battle/battle_scene.tscn", "res://scenes/p4/comparaison_camera_B28.tscn"]:
		check(ResourceLoader.exists(f), "scène présente : " + f)
	var main: String = ProjectSettings.get_setting("application/run/main_scene")
	check(not main.contains("comparaison") and not main.contains("test") and not main.contains("explore25"), "F5 n'est pas une scène d'essai")
