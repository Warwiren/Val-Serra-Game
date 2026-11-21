extends SceneTree
## P5 / P5.2 — décor de combat « forêt » : rendu de la VRAIE forêt V07B (F5 : mêmes modèles, même sol P5.2, même
## éclairage, sans brouillard) vue depuis une caméra de combat (de côté, à hauteur de personnages), à l'endroit de la
## rencontre. Personnages, Vorgane, interface et repères masqués. Deux images (rendu ×2 puis réduit, sans crénelage) :
##  1. <out> (1280 × 720, opaque) : arrière-plan et sol de la scène de combat ;
##     - décor entre la caméra et la scène retiré (il cacherait les combattants) ;
##     - CLAIRIÈRE : petite végétation retirée sur la bande où se tiennent les combattants (± 7 m, de 1,5 m devant à
##       2,5 m derrière la ligne de combat) ; arbres et rochers gardés ;
##     - profondeur : flou léger au-delà de la scène (HD-2D), la scène reste nette ;
##  2. <out>_avant.png (RGBA, fond transparent) : PREMIER PLAN, le décor retiré devant la scène qui encadre l'image
##     (feuillages et troncs sur les bords, herbes en bas), affiché devant les combattants par l'arène.
##   xvfb-run godot --path . --rendering-method forward_plus --script res://tools/p5/decor_foret.gd -- \
##       --out=art/p5/combat/foret_clairiere.png --x=-8 --z=1.5 --plongee=16

const SCENE := "res://ValSerra_P49_V07B_PREFLIGHT_GODOT/godot/P49_V07_Foret_Test.tscn"
var p := {"x": -8.0, "z": 1.5, "cap": 0.0, "plongee": 16.0, "distance": 15.4, "avant": 1.6, "haut": 1.0, "flou": 1.0}
var out := "user://foret_clairiere.png"
const W := 2560
const H := 1440


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
	root.size = Vector2i(W, H)
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
	# ciel (la forêt n'est jamais vue à l'horizontale en exploration) : dégradé chaud et clair
	var env: Environment = sc.get("_world_env")
	var ciel := ProceduralSkyMaterial.new()
	ciel.sky_top_color = Color(0.55, 0.68, 0.78)
	ciel.sky_horizon_color = Color(0.86, 0.84, 0.72)
	ciel.ground_horizon_color = Color(0.3, 0.33, 0.22)
	ciel.ground_bottom_color = Color(0.2, 0.22, 0.15)
	var sky := Sky.new()
	sky.sky_material = ciel
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	var cam: Camera3D = sc.get("_camera")
	var cap := deg_to_rad(p["cap"])
	var pl := deg_to_rad(p["plongee"])
	var fwd := Vector3(sin(cap), 0, -cos(cap))
	var droite := Vector3(cos(cap), 0, sin(cap))
	var sol_y := _sol(sc, p["x"], p["z"])
	var cible := Vector3(p["x"], sol_y + p["haut"], p["z"])
	cam.global_position = cible - fwd * p["distance"] * cos(pl) + Vector3.UP * p["distance"] * sin(pl)
	cam.look_at(cible, Vector3.UP)
	# profondeur : flou au-delà de la scène seulement
	var attr := CameraAttributesPractical.new()
	attr.dof_blur_far_enabled = p["flou"] > 0.0
	attr.dof_blur_far_distance = p["distance"] + 4.0
	attr.dof_blur_far_transition = 14.0
	attr.dof_blur_amount = 0.06 * p["flou"]
	cam.attributes = attr
	var foret: Node3D = sc.get("_forest_root")
	var avant: Array = []          # [noeud] ou [MultiMesh, index, transform]
	var clairiere := 0
	for c in foret.get_children():
		if c is MultiMeshInstance3D:
			var mm: MultiMesh = (c as MultiMeshInstance3D).multimesh
			for i in mm.instance_count:
				var t := mm.get_instance_transform(i)
				var rel := t.origin - Vector3(p["x"], 0, p["z"])
				var devant: bool = rel.dot(fwd) < -float(p["avant"])
				var scene_cb: bool = absf(rel.dot(droite)) < 7.0 and rel.dot(fwd) > -float(p["avant"]) and rel.dot(fwd) < 2.5
				if devant or scene_cb:
					if devant and _cadre(cam, t.origin, false):
						avant.append([mm, i, t])
					mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.0001), t.origin))
					if scene_cb and not devant:
						clairiere += 1
		elif c is Node3D and not (c is StaticBody3D):
			var n := c as Node3D
			if (n.global_position - cible).dot(fwd) < -p["avant"]:
				n.visible = false
				if _cadre(cam, n.global_position, true):
					avant.append([n])
	# pieds d'objets (litière, ombre de contact) : seulement ceux des objets encore visibles
	var sol = sc.get("_sol")
	if sol != null:
		var mat: ShaderMaterial = sol.get("materiau")
		var obs: PackedVector4Array = mat.get_shader_parameter("obstacles")
		var garde := PackedVector4Array()
		for o in obs:
			if (Vector3(o.x, 0, o.y) - Vector3(p["x"], 0, p["z"])).dot(fwd) >= -float(p["avant"]):
				garde.append(o)
		# tous les matériaux de sol (P5.3 et pilotes) : chacun garde sa propre copie des pieds d'objets
		var mats: Array = [mat, sol.get("materiau_p52")]
		if sol.has_method("materiaux_pilote"):
			mats.append_array(sol.call("materiaux_pilote"))
		for m in mats:
			if m != null:
				(m as ShaderMaterial).set_shader_parameter("obstacles", garde)
				(m as ShaderMaterial).set_shader_parameter("nb_obstacles", garde.size())
	# P5.3-B pilote : matières peintes sur tout le décor de combat (--pilote=carte), sinon la zone pilote seule
	if OS.get_cmdline_user_args().has("--pilote=carte") and sc.has_method("set_pilote_carte_entiere"):
		sc.call("set_pilote_carte_entiere", true)
	for a2 in OS.get_cmdline_user_args():
		if a2.begins_with("--sol="):                                    # p53 | p53b | p53b1c | p53b2
			sc.call("set_version_sol", a2.substr(6))
		if a2.begins_with("--calage=") and sc.get("_sol") != null:      # P5.3-B : essai de calage de couleur
			(sc.get("_sol").get("materiau_p53b") as ShaderMaterial).set_shader_parameter("calage", float(a2.substr(9)))
	for i in 12:
		await process_frame
	var img := root.get_texture().get_image()
	img.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	img.save_png(out)
	# --- premier plan : seulement le décor retiré qui encadre l'image, fond transparent
	for c in sc.get_children():
		if c is Node3D and c != cam and not (c is DirectionalLight3D) and not (c is WorldEnvironment):
			(c as Node3D).visible = false
	foret.visible = true
	for c in foret.get_children():
		if c is Node3D:
			(c as Node3D).visible = false
	var mms := {}
	for a in avant:
		if a.size() == 1:
			(a[0] as Node3D).visible = true
		else:
			mms[a[0]] = true
	for c in foret.get_children():
		if c is MultiMeshInstance3D and mms.has((c as MultiMeshInstance3D).multimesh):
			var mm: MultiMesh = (c as MultiMeshInstance3D).multimesh
			for i in mm.instance_count:
				mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.0001), Vector3(0, -50, 0)))
			c.visible = true
	for a in avant:
		if a.size() == 3:
			(a[0] as MultiMesh).set_instance_transform(a[1], a[2])
	# premier plan composé : buissons et fougères de la forêt posés près de la caméra, dans les deux coins du bas
	# (le centre reste dégagé pour les combattants), flous de proximité
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var demi_h := atan(tan(deg_to_rad(cam.fov * 0.5)) * float(W) / float(H))
	var props := 0
	for cote in [-1.0, 1.0]:
		for k in 4:
			var d := rng.randf_range(7.6, 9.0)        # le bas du cadre touche le sol à ≈ 7 m de la caméra
			var l: float = cote * tan(demi_h) * d * rng.randf_range(0.84, 1.04)
			var hz := Vector3(cam.global_position.x, 0, cam.global_position.z) + fwd * d + droite * l
			var y := _sol(sc, hz.x, hz.z)
			var f: String = ["models/Fern_1.gltf", "models/Plant_1.gltf", "models/Fern_1.gltf", "models/Grass_Wispy_Tall.gltf"][k]
			var ps: PackedScene = sc.call("_charge_modele", f)
			if ps == null:
				continue
			var o := ps.instantiate() as Node3D
			foret.add_child(o)
			o.global_position = Vector3(hz.x, y - 0.05, hz.z)
			o.rotation.y = rng.randf_range(0, TAU)
			o.scale = Vector3.ONE * rng.randf_range(0.9, 1.3)
			sc.call("_tint_tree", o, Color(0.72, 0.84, 0.70))
			props += 1
	print("premier plan composé : %d plantes" % props)
	env.background_mode = Environment.BG_CLEAR_COLOR
	root.transparent_bg = true
	attr.dof_blur_far_enabled = false
	attr.dof_blur_near_enabled = p["flou"] > 0.0
	attr.dof_blur_near_distance = p["distance"] * 0.55
	attr.dof_blur_near_transition = 3.0
	for i in 12:
		await process_frame
	var img2 := root.get_texture().get_image()
	img2.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	var out2 := out.get_basename() + "_avant.png"
	img2.save_png(out2)
	print("décor forêt : %s + %s (cible %s ; clairière : %d plantes retirées ; premier plan : %d éléments)" % [out, out2, cible, clairiere, avant.size()])
	quit()


## un élément retiré devant la scène encadre-t-il l'image ? (bords gauche / droit, ou bas pour la petite végétation)
func _cadre(cam: Camera3D, pos: Vector3, grand: bool) -> bool:
	if cam.is_position_behind(pos):
		return false
	var s := cam.unproject_position(pos)
	var x := s.x / W
	var y := s.y / H
	if grand:
		return (x < 0.12 or x > 0.88) and x > -0.3 and x < 1.3
	return (x < 0.16 or x > 0.84) and y > 0.55 and x > -0.1 and x < 1.1 and y < 1.25


func _sol(sc: Node, x: float, z: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 30, z), Vector3(x, -10, z))
	q.collision_mask = 1
	var hit := (sc as Node3D).get_world_3d().direct_space_state.intersect_ray(q)
	return float(hit["position"].y) if not hit.is_empty() else 0.0
