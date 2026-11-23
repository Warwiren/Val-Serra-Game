extends SceneTree
## Collisions — mesure du décor de la forêt V07B : pour chaque placement, taille réelle (AABB du modèle × échelle),
## dedans / dehors de la zone jouable, distance au plus proche tracé de parcours, collision actuelle.
##   godot --headless --path . --script res://tools/p49/mesure_decor.gd -- --out=<fichier.json>

const ROOT := "res://ValSerra_P49_V07B_PREFLIGHT_GODOT/"
const BX := 17.65
const BZ := 13.65


func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	var stack := [[n, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var it = stack.pop_back()
		var node: Node = it[0]
		var xf: Transform3D = it[1]
		if node is Node3D and node != n:
			xf = xf * (node as Node3D).transform
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			var b: AABB = xf * (node as MeshInstance3D).mesh.get_aabb()
			out = b if first else out.merge(b)
			first = false
		for c in node.get_children():
			stack.append([c, xf])
	return out


func _initialize() -> void:
	var out := "user://mesure_decor.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "docs/V07_WORLD.json"))
	var routes: Array = []
	for k in d["routes"]:
		var pts: Array = d["routes"][k]
		for i in pts.size() - 1:
			var a: Array = pts[i]
			var b: Array = pts[i + 1]
			routes.append([Vector2(float(a[0]), float(a[a.size() - 1])), Vector2(float(b[0]), float(b[b.size() - 1]))])
	var cache := {}
	var res: Array = []
	for p in d["placements"]:
		var f := String(p["asset"])
		if not cache.has(f):
			var sc: PackedScene = load(ROOT + "assets/" + f)
			var inst := sc.instantiate()
			cache[f] = _aabb(inst)
			inst.free()
		var bb: AABB = cache[f]
		var s := float(p["scale"])
		var xyz: Array = p["xyz"]
		var pos := Vector2(float(xyz[0]), float(xyz[2]))
		var dmin := 1e9
		for r in routes:
			dmin = minf(dmin, _seg_dist(pos, r[0], r[1]))
		res.append({"nom": p["name"], "asset": f.get_file(), "role": p.get("role", ""), "bloquant": bool(p.get("blocking", false)),
			"x": pos.x, "z": pos.y, "largeur_m": snappedf(maxf(bb.size.x, bb.size.z) * s, 0.01), "hauteur_m": snappedf(bb.size.y * s, 0.01),
			"dans_zone": absf(pos.x) <= BX and absf(pos.y) <= BZ, "distance_parcours_m": snappedf(dmin, 0.01)})
	var fa := FileAccess.open(out, FileAccess.WRITE)
	fa.store_string(JSON.stringify(res, " "))
	print("décor mesuré : %d placements -> %s" % [res.size(), out])
	quit()
