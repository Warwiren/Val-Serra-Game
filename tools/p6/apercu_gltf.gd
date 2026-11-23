extends SceneTree
## P6.3 — aperçu de modèles glTF HORS du projet (chargés à l'exécution, sans import) sous la caméra du Colisée
## (perspective, plongée 24°, azimut 0°, champ 30°), éclairage de type intérieur chaud + soleil, repère humain de 1,7 m.
##   godot --path . --rendering-method forward_plus --resolution 1280x720 --script res://tools/p6/apercu_gltf.gd -- \
##        --dir=/chemin/glTF --noms=Bench,Barrel,... --out=/tmp/apercu.png [--cols=5] [--pas=2.2]
var n := 0
var out := "user://apercu_gltf.png"


func _initialize() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			args[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
	out = args.get("out", out)
	var dirs: PackedStringArray = str(args.get("dir", "")).split(";")
	var noms: PackedStringArray = str(args.get("noms", "")).split(",")
	var cols := int(args.get("cols", "5"))
	var pas := float(args.get("pas", "2.4"))
	var racine := Node3D.new()
	root.add_child(racine)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.12, 0.11, 0.12)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.58, 0.62)
	e.ambient_light_energy = 0.5
	env.environment = e
	racine.add_child(env)
	var sol := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	sol.mesh = pm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.42, 0.38, 0.36)
	sol.material_override = sm
	racine.add_child(sol)
	var soleil := DirectionalLight3D.new()
	soleil.rotation = Vector3(deg_to_rad(-50), deg_to_rad(30), 0)
	soleil.light_energy = 0.8
	soleil.shadow_enabled = true
	racine.add_child(soleil)
	var rangs := int(ceil(float(noms.size()) / cols))
	for i in noms.size():
		var nom := noms[i].strip_edges()
		var chemin := ""
		for d in dirs:
			if FileAccess.file_exists(d.path_join(nom + ".gltf")):
				chemin = d.path_join(nom + ".gltf")
		if chemin == "":
			print("APERCU absent : ", nom)
			continue
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		if doc.append_from_file(chemin, st) != OK:
			print("APERCU échec : ", nom)
			continue
		var sc := doc.generate_scene(st)
		var x := (i % cols - (cols - 1) * 0.5) * pas
		var z := (i / cols - (rangs - 1) * 0.5) * pas
		(sc as Node3D).position = Vector3(x, 0, z)
		racine.add_child(sc)
		var lab := Label3D.new()
		lab.text = nom
		lab.font_size = 28
		lab.pixel_size = 0.004
		lab.position = Vector3(x, 0.02, z + pas * 0.42)
		lab.rotation.x = -PI / 2.0
		racine.add_child(lab)
	# repère humain 1,7 m (capsule) au coin
	var hum := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.height = 1.7
	cap.radius = 0.25
	hum.mesh = cap
	hum.position = Vector3(-(cols * 0.5 + 0.3) * pas, 0.85, 0)
	racine.add_child(hum)
	var lum := OmniLight3D.new()
	lum.light_color = Color(1.0, 0.78, 0.5)
	lum.light_energy = 2.0
	lum.omni_range = 14.0
	lum.position = Vector3(0, 3.0, 0)
	lum.shadow_enabled = true
	racine.add_child(lum)
	var cam := Camera3D.new()
	cam.fov = 30.0
	var largeur := cols * pas + 3.0
	var dist := largeur * 0.5 / tan(deg_to_rad(30.0 * 1.6) * 0.5) + 2.0
	cam.rotation = Vector3(deg_to_rad(-24), 0, 0)
	cam.position = Vector3(0, sin(deg_to_rad(24)) * dist, cos(deg_to_rad(24)) * dist)
	racine.add_child(cam)
	cam.current = true


func _process(_d: float) -> bool:
	n += 1
	if n == 20:
		root.get_viewport().get_texture().get_image().save_png(out)
		print("APERCU écrit ", out)
		quit()
	return false
