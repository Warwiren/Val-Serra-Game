extends "res://tools/p49/banc_v07.gd"
## P5.2 — sol de la forêt : nouveau sol au démarrage de F5 (touche U), mêmes collisions, horizon fermé, décor de combat
## forêt avec premier plan.
##   godot --headless --path . --fixed-fps 60 --script res://tests/p52_sol_smoke.gd

var failures := 0


func _test(ok: bool, label: String) -> void:
	if ok:
		print("P5.2 OK : " + label)
	else:
		failures += 1
		push_error("P5.2 ECHEC : " + label)


func _run() -> void:
	load("res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.gd").set("demarrage_v09c6", true)
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	var terrain: MeshInstance3D = sc.get("_terrain_mi")
	var sol = sc.get("_sol")
	_test(bool(sc.get("_sol_p52")) and sol != null and terrain.material_override == sol.get("materiau"), "F5 démarre avec le sol P5.2 (terrain)")
	var mis: Array = sc.call("_sols_mi")
	_test(mis.size() == 2 and (mis[1] as MeshInstance3D).material_override == sol.get("materiau"), "bordure hors jeu : même sol")
	var arr: Array = terrain.mesh.surface_get_arrays(0)
	var nrm = arr[Mesh.ARRAY_NORMAL]
	var haut := 0
	for i in range(0, (nrm as PackedVector3Array).size(), 211):
		haut += 1 if (nrm as PackedVector3Array)[i].y > 0.0 else 0
	_test(nrm != null and haut * 211 >= (nrm as PackedVector3Array).size() * 0.98, "terrain avec normales (vers le haut) : relief éclairé")
	var n_obs: int = sol.get("nb_obstacles")
	_test(n_obs >= 90, "pieds d'objets : %d arbres, rochers et buissons" % n_obs)
	_test((sol.get("horizon") as Node3D).visible and int(sol.get("nb_arbres_horizon")) > 200, "horizon fermé : %d arbres lointains" % int(sol.get("nb_arbres_horizon")))
	# collisions inchangées : même forme de collision du terrain, même nombre d'obstacles
	var col: CollisionShape3D = terrain.get_child(0).get_child(0)
	_test(col.shape is ConcavePolygonShape3D and (col.shape as ConcavePolygonShape3D).get_faces().size() == 90240 * 3, "collision du terrain inchangée (90 240 triangles)")
	_test((sc.get("_set_colliders") as Array).size() == 97, "obstacles inchangés (97)")
	var orig: Mesh = (sol.get("_maillages") as Dictionary)[terrain][0]
	sc.call("set_sol_p52", false)
	_test(terrain.material_override == null and terrain.mesh == orig and not (sol.get("horizon") as Node3D).visible, "touche U : sol V07 d'origine (maillage, matière, horizon)")
	sc.call("set_sol_p52", true)
	# un parcours court au sol : Aren marche sur le chemin sans blocage
	_place(-13.5, 0.3)
	await _frames(10)
	var x0 := _hero().global_position.x
	_steer(Vector3(1, 0, 0))
	await _frames(90)
	_stop()
	_test(_hero().global_position.x - x0 > 2.5, "déplacement inchangé sur le nouveau sol (%.2f m en 1,5 s)" % (_hero().global_position.x - x0))
	# décor de combat forêt : arrière-plan et premier plan
	_test(ResourceLoader.exists("res://art/p5/combat/foret_clairiere.png") and ResourceLoader.exists("res://art/p5/combat/foret_clairiere_avant.png"), "décor de combat : arrière-plan et premier plan")
	print("P5.2 : %d échec(s)" % failures)
	quit(1 if failures > 0 else 0)
