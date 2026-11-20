extends SceneTree
## P5 — décor de combat « forêt » : rendu de la VRAIE forêt V07B (F5 : mêmes modèles, éclairage, sans brouillard) vue
## depuis une caméra de combat (de côté, à hauteur de personnages), à l'endroit de la rencontre. Personnages, Vorgane,
## interface et repères masqués ; le décor placé entre la caméra et la scène de combat est retiré (sinon il cache les
## combattants). Sortie : PNG 1280 × 720 (rendu ×2 puis réduit, sans crénelage).
##   xvfb-run godot --path . --rendering-method forward_plus --script res://tools/p5/decor_foret.gd -- \
##       --out=art/p5/combat/foret_clairiere.png [--x=6.5 --z=0.6 --cap=0 --plongee=14 --distance=15.4 --avant=1.6]

const SCENE := "res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.tscn"
var p := {"x": 6.5, "z": 0.6, "cap": 0.0, "plongee": 14.0, "distance": 15.4, "avant": 1.6, "haut": 1.0}
var out := "user://foret_clairiere.png"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		for k in p:
			if a.begins_with("--%s=" % k):
				p[k] = float(a.substr(k.length() + 3))
	load(SCENE.replace(".tscn", ".gd")).set("demarrage_v09c6", true)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(2560, 1440)
	change_scene_to_file(SCENE)
	for i in 30:
		await physics_frame
	var sc := current_scene
	sc.set_process(false)
	sc.set_physics_process(false)
	for n in ["_hero", "_ilya", "_monstre"]:
		(sc.get(n) as Node3D).visible = false
	(sc.get("_hud") as Control).visible = false
	var occ = sc.get("_occ")
	if occ != null:
		occ.set("enabled", false)
	# ciel (la forêt n'est jamais vue à l'horizontale en exploration : fond uni sombre) : dégradé chaud et clair
	var env: Environment = sc.get("_world_env")
	var ciel := ProceduralSkyMaterial.new()
	ciel.sky_top_color = Color(0.55, 0.68, 0.78)
	ciel.sky_horizon_color = Color(0.86, 0.84, 0.72)
	ciel.ground_horizon_color = Color(0.86, 0.84, 0.72)
	ciel.ground_bottom_color = Color(0.35, 0.40, 0.30)
	var sky := Sky.new()
	sky.sky_material = ciel
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	var cam: Camera3D = sc.get("_camera")
	var cap := deg_to_rad(p["cap"])
	var pl := deg_to_rad(p["plongee"])
	# axe de visée horizontal (cap 0 : vers le nord, -z) ; la caméra est derrière, en plongée
	var fwd := Vector3(sin(cap), 0, -cos(cap))
	var cible := Vector3(p["x"], _sol(sc, p["x"], p["z"]) + p["haut"], p["z"])
	cam.global_position = cible - fwd * p["distance"] * cos(pl) + Vector3.UP * p["distance"] * sin(pl)
	cam.look_at(cible, Vector3.UP)
	# décor entre la caméra et la scène (au-delà de « avant » mètres devant la ligne des combattants) : retiré
	var foret: Node3D = sc.get("_forest_root")
	var retire := 0
	for c in foret.get_children():
		if c is MultiMeshInstance3D:
			var mm: MultiMesh = (c as MultiMeshInstance3D).multimesh
			for i in mm.instance_count:
				var t := mm.get_instance_transform(i)
				if _devant(t.origin, cible, fwd):
					mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.0001), t.origin))
					retire += 1
		elif c is Node3D and not (c is StaticBody3D) and _devant((c as Node3D).global_position, cible, fwd):
			(c as Node3D).visible = false
			retire += 1
	for i in 12:
		await process_frame
	var img := root.get_texture().get_image()
	img.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	img.save_png(out)
	print("décor forêt : %s (cible %s, %d éléments retirés au premier plan)" % [out, cible, retire])
	quit()


func _devant(pos: Vector3, cible: Vector3, fwd: Vector3) -> bool:
	return (pos - cible).dot(fwd) < -p["avant"]


func _sol(sc: Node, x: float, z: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 30, z), Vector3(x, -10, z))
	q.collision_mask = 1
	var hit := (sc as Node3D).get_world_3d().direct_space_state.intersect_ray(q)
	return float(hit["position"].y) if not hit.is_empty() else 0.0
