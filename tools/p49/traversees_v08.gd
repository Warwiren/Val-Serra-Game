extends "res://tools/p49/banc_v07.gd"
## P4.9 V08A — les 18 traversées « plein champ » de l'audit V08, dans la vraie scène, à la marche et en course.
##   godot --headless --path . --fixed-fps 60 --script res://tools/p49/traversees_v08.gd -- --out=<dossier>
## Le héros part du chemin principal (Z ≈ 0) et vise en ligne droite Z = -8 (nord) ou Z = +8 (sud), comme le
## ferait un joueur qui tient la direction : il glisse le long de ce qu'il touche (move_and_slide), sans
## contournement intelligent. Pour chaque blocage : ce qui est touché (arbre, rocher, barrière d'eau, bord, terrain),
## la pente du terrain au point de blocage et la distance au premier objet VISIBLE.

const XS_NORD := [-12, -9, -6, -3, 0, 3, 6, 9, 12]
const XS_SUD := [-12, -9, -6, -3, 0, 3, 6, 9, 12]
var lignes: Array = []
var variante := {}                          # --variante=cle:valeur,... (essai de réglages du personnage)


func _run() -> void:
	change_scene_to_file(SCENE)
	await _frames(30)
	sc = current_scene
	var hero := _hero()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--variante="):
			for kv in a.substr(11).split(","):
				var p := kv.split(":")
				variante[p[0]] = str_to_var(p[1])
	for b in [hero, sc.get("_ilya")]:
		for k in variante:
			(b as Object).set(k, variante[k])
	var floor_deg := rad_to_deg(hero.floor_max_angle)
	res = {"floor_max_angle_deg": snappedf(floor_deg, 0.1), "variante": variante, "traversees": []}
	for dirz in [-1, 1]:
		for x in (XS_NORD if dirz < 0 else XS_SUD):
			for run in [false, true]:
				res["traversees"].append(await _traverse(float(x), float(dirz) * 8.0, run))
	res["ecarts_obstacles"] = await _ecarts()
	var f := FileAccess.open(out.path_join("traversees_v08.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(res, " "))
	quit()


func _depart(x: float) -> Vector3:
	# départ sur le chemin principal, sur sol praticable et hors de tout collider (décalage de 0,25 m si besoin)
	for dx in [0.0, 0.25, -0.25, 0.5, -0.5, 0.75, -0.75]:
		var p := Vector3(x + dx, 0, 0.0)
		if _libre(p):
			return p
	return Vector3(x, 0, 0)


func _libre(p: Vector3) -> bool:
	var space := (sc as Node3D).get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.25
	cap.height = 1.3
	q.shape = cap
	q.transform = Transform3D(Basis(), Vector3(p.x, _ground(p.x, p.z) + 0.72, p.z))
	q.collision_mask = 1
	for h in space.intersect_shape(q, 4):
		if not String((h["collider"] as Node).name).begins_with("Terrain"):
			return false
	return true


func _traverse(x: float, zgoal: float, run: bool) -> Dictionary:
	var start := _depart(x)
	_place(start.x, start.z)
	await _frames(20)
	if run:
		_key(KEY_SHIFT, true)
	var goal := Vector3(start.x, 0, zgoal)
	var dist0 := absf(zgoal - start.z)
	var speed := 3.6 if run else 2.2
	var limit := int((dist0 / speed * 1.8 + 1.5) * 60)
	var r := {"x": snappedf(start.x, 0.01), "sens": "nord" if zgoal < 0 else "sud", "allure": "course" if run else "marche",
		"ok": false, "s": 0.0, "ecart_max_m": 0.0, "pente_sol_max_deg": _profil(start.x, start.z, zgoal)}
	var best := 1e9
	var since := 0
	var t := 0
	var hits := {}
	var wall_deg := 0.0
	while t < limit:
		var h := _hero()
		var to := Vector3(goal.x - h.global_position.x, 0, goal.z - h.global_position.z)
		if absf(to.z) < 0.4:
			r["ok"] = true
			break
		_steer(Vector3(0, 0, signf(to.z)))                 # le joueur tient la direction nord ou sud
		await _frames(1)
		t += 1
		r["ecart_max_m"] = maxf(r["ecart_max_m"], absf(h.global_position.x - start.x))
		for k in h.get_slide_collision_count():
			var c := h.get_slide_collision(k)
			var n := _quoi(c.get_collider() as Node)
			if n.begins_with("Obstacle") and String((c.get_collider() as Node).name).begins_with("Obstacle"):
				n = _quoi_obstacle(c.get_collider() as Node)
			var ang := rad_to_deg(c.get_normal().angle_to(Vector3.UP))
			# seuls comptent les contacts qui freinent : obstacles, barrières, et terrain plus raide que 35°
			if not n.begins_with("Terrain") or ang > 35.0:
				hits[n] = hits.get(n, 0) + 1
			if n.begins_with("Terrain"):
				wall_deg = maxf(wall_deg, ang)
		if absf(to.z) < best - 0.02:
			best = absf(to.z)
			since = 0
		else:
			since += 1
		if since > 45 and int(r.get("contournement", 0)) < 3 and _obstacle_visible(hits):
			# le joueur contourne l'obstacle visible : pas de côté (vers le côté le plus dégagé), puis reprend sa direction
			r["contournement"] = int(r.get("contournement", 0)) + 1
			var side := 1.0 if _libre(h.global_position + Vector3(1.0, 0, 0)) else -1.0
			hits.clear()
			for i in 40:
				_steer(Vector3(side, 0, 0))
				await _frames(1)
			t += 40
			since = 0
			best = 1e9
			continue
		if since > 90:                                    # 1,5 s sans avancer : bloqué
			break
	_stop()
	_key(KEY_SHIFT, false)
	var hp := _hero().global_position
	r["s"] = snappedf(t / 60.0, 0.01)
	r["ecart_max_m"] = snappedf(r["ecart_max_m"], 0.01)
	r["arrivee"] = [snappedf(hp.x, 0.01), snappedf(hp.z, 0.01)]
	r["contacts"] = hits
	r["pente_max_touchee_deg"] = snappedf(wall_deg, 0.1)
	if r["ok"] and r.has("contournement"):
		r["statut"] = "OK après contournement d'un obstacle visible"
	elif r["ok"]:
		r["statut"] = "OK en ligne droite"
	if not r["ok"]:
		r["cause"] = _cause(hits, wall_deg)
		r["statut"] = "bloqué : " + r["cause"]
		r["bloque_a"] = [snappedf(hp.x, 0.01), snappedf(hp.z, 0.01), snappedf(hp.y, 0.01)]
	print("%s x=%5.1f %-6s %-7s sol max %4.1f°  %s  %.1fs" % ["OK    " if r["ok"] else "BLOQUÉ", start.x, r["sens"], r["allure"],
		r["pente_sol_max_deg"], r["statut"], r["s"]])
	return r


## hauteur du TERRAIN seul (les rayons ignorent troncs, rochers et barrières)
func _terrain_y(x: float, z: float) -> float:
	var space := (sc as Node3D).get_world_3d().direct_space_state
	var excl: Array[RID] = [_hero().get_rid(), (sc.get("_ilya") as CharacterBody3D).get_rid()]
	for i in 8:
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, 30, z), Vector3(x, -10, z))
		q.exclude = excl
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return 0.0
		if String((hit["collider"] as Node).name).begins_with("Terrain"):
			return float(hit["position"].y)
		excl.append(hit["rid"])
	return 0.0


## pente réelle du sol le long de la ligne : hauteurs relevées tous les 0,25 m, pente sur 0,5 m (≈ pas d'une capsule)
func _profil(x: float, z0: float, z1: float) -> float:
	var hs: Array = []
	var n := int(absf(z1 - z0) / 0.25)
	for i in n + 1:
		hs.append(_terrain_y(x, lerpf(z0, z1, float(i) / n)))
	var mx := 0.0
	for i in range(2, hs.size()):
		mx = maxf(mx, rad_to_deg(atan(absf(hs[i] - hs[i - 2]) / 0.5)))
	return snappedf(mx, 0.1)


## nature de ce qui est touché (les nœuds homonymes sont renommés par Godot : on lit la forme et la position)
func _quoi(n: Node) -> String:
	var nm := String(n.name)
	if nm.begins_with("Terrain") or nm.begins_with("Obstacle") or nm.begins_with("River"):
		return nm
	var p := (n as Node3D).global_position
	var cs := n.get_child(0) as CollisionShape3D
	if cs != null and cs.shape is CylinderShape3D:
		return "Obstacle_tree (%.1f, %.1f)" % [p.x, p.z]
	if cs != null and cs.shape is ConvexPolygonShape3D:
		return "Obstacle_rock (%.1f, %.1f)" % [p.x, p.z]
	if cs != null and cs.shape is BoxShape3D:
		var sz := (cs.shape as BoxShape3D).size
		if sz.y < 2.0:
			return "River_NoCrossing (%.1f, %.1f)" % [p.x, p.z]
		return "Bord (%.1f, %.1f)" % [p.x, p.z]
	return "%s (%.1f, %.1f)" % [nm, p.x, p.z]


func _quoi_obstacle(n: Node) -> String:
	var p := (n as Node3D).global_position
	return "%s (%.1f, %.1f)" % [String(n.name), p.x, p.z]


func _obstacle_visible(hits: Dictionary) -> bool:
	for k in hits:
		if String(k).begins_with("Obstacle") or String(k).begins_with("@StaticBody3D"):
			return true
	return false


func _cause(hits: Dictionary, wall_deg: float) -> String:
	var keys := hits.keys()
	keys.sort_custom(func(a, b): return hits[a] > hits[b])
	if keys.is_empty():
		return "inconnue (aucun contact)"
	var k: String = keys[0]
	if k.begins_with("Obstacle_tree"):
		return "tronc d'arbre " + k.substr(14)
	if k.begins_with("Obstacle_rock"):
		return "rocher " + k.substr(14)
	if k.begins_with("River"):
		return "barrière d'eau " + k.substr(16)
	if k.begins_with("Bord"):
		return "bord de carte " + k.substr(5)
	if k.begins_with("Terrain"):
		return "terrain : pente %.0f°" % wall_deg
	return k


## Le personnage s'approche de chaque rocher et de 6 arbres, depuis 4 directions, jusqu'au contact. Écart = distance
## entre la surface de sa capsule (rayon 0,25 m) et la surface VISIBLE du modèle, à hauteur de personnage.
## Positif : arrêté avant la surface visible (au-delà de 0,3 m : obstacle « invisible »). Négatif : il entre dedans.
func _ecarts() -> Array:
	var data2: Dictionary = data
	var out_e: Array = []
	var forest: Node3D = sc.get("_forest_root")
	var nodes := {}
	for c in forest.get_children():
		if c is Node3D and not (c is StaticBody3D) and not (c is MultiMeshInstance3D):
			nodes[Vector2(snappedf(c.global_position.x, 0.01), snappedf(c.global_position.z, 0.01))] = c
	var cibles: Array = data2["placements"].filter(func(p): return p.get("blocking", false) and p["role"] == "rock")
	var arbres: Array = data2["placements"].filter(func(p): return p.get("blocking", false) and p["role"] == "tree")
	arbres.sort_custom(func(a, b): return Vector2(float(a["xyz"][0]), float(a["xyz"][2])).length() < Vector2(float(b["xyz"][0]), float(b["xyz"][2])).length())
	cibles.append_array(arbres.slice(0, 6))
	for p in cibles:
		var c := Vector3(float(p["xyz"][0]), 0, float(p["xyz"][2]))
		var node: Node3D = nodes.get(Vector2(snappedf(c.x, 0.01), snappedf(c.z, 0.01)))
		var pts := _points_visibles(node, p["role"] == "tree")
		var ec: Array = []
		for d in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			var start: Vector3 = c + d * 3.2
			if absf(start.x) > 17.0 or absf(start.z) > 13.0 or not _libre(start):
				continue
			_place(start.x, start.z)
			await _frames(12)
			for i in 110:
				_steer(-d)
				await _frames(1)
			var touche := {}
			for k in _hero().get_slide_collision_count():
				var cc := _hero().get_slide_collision(k)
				var ang := rad_to_deg(cc.get_normal().angle_to(Vector3.UP))
				var nn := _quoi(cc.get_collider() as Node)
				if not nn.begins_with("Terrain") or ang > 35.0:
					touche[nn if not nn.begins_with("Terrain") else "terrain %.0f°" % ang] = true
			_stop()
			var hp := _hero().global_position
			var dmin := 1e9
			for q in pts:
				if q.y > hp.y + 0.05 and q.y < hp.y + 1.3:
					dmin = minf(dmin, Vector2(q.x - hp.x, q.z - hp.z).length())
			var arrete_par := "lui-même" if touche.keys().any(func(k): return String(k).contains("(%.1f, %.1f)" % [c.x, c.z])) else ", ".join(touche.keys())
			ec.append({"ecart_m": snappedf(dmin - 0.25, 0.01), "arrete_par": arrete_par})
		var r := {"objet": "%s (%.1f, %.1f)" % [p["name"], c.x, c.z], "role": p["role"], "ecarts_m": ec}
		out_e.append(r)
		print("ÉCART %-28s %s" % [r["objet"], ec.map(func(e): return "%.2f (%s)" % [e["ecart_m"], e["arrete_par"]])])
	return out_e


func _points_visibles(node: Node3D, ecorce_seulement: bool) -> Array:
	var pts: Array = []
	if node == null:
		return pts
	var stack: Array = [node]
	while not stack.is_empty():
		var x = stack.pop_back()
		stack.append_array(x.get_children())
		if x is MeshInstance3D:
			var xf: Transform3D = x.global_transform
			for s in x.mesh.get_surface_count():
				var mat = x.get_active_material(s)
				if ecorce_seulement and not (mat is BaseMaterial3D and (mat.normal_enabled or mat.transparency == 0)):
					continue
				for v in x.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
					pts.append(xf * v)
	return pts
