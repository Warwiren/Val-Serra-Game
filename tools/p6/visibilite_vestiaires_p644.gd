extends SceneTree
## P6.4.4 — usage : godot --headless --path . --script res://tools/p6/visibilite_vestiaires_p644.gd -- --neuf --etat=tutorial_available
## Diagnostic : maillages visibles de l'arène (x 12..40, z 12..34) quand Aren est dans les vestiaires.
var z
var n := 0
func _initialize() -> void:
	change_scene_to_file("res://scenes/p6/colisee.tscn")
func _visible_total(nd: Node) -> bool:
	var c: Node = nd
	while c != null:
		if c is Node3D and not (c as Node3D).visible:
			return false
		c = c.get_parent()
	return true
func _process(_d: float) -> bool:
	n += 1
	if z == null:
		if n > 20 and current_scene != null and current_scene.get("world") != null:
			z = current_scene
			n = 0
		return false
	if n == 5:
		z.s.warp_to(Vector3(26.0, 51.5, 0.0))
	if n == 40:
		var sect = z._sect
		print("actif=", sect.actif, " visibles=", sect.visibles, " voile=", sect.voile_ext)
		var groups := {}
		for k in sect._groupes:
			var g: Dictionary = sect._groupes[k]
			var gn: Node3D = g["node"]
			for mi in gn.find_children("*", "MeshInstance3D", true, false):
				var m := mi as MeshInstance3D
				if not _visible_total(m) or m.transparency > 0.99:
					continue
				var ab: AABB = m.global_transform * m.get_aabb()
				var cx := ab.get_center()
				if cx.x > 11 and cx.x < 41 and cx.z > 10 and cx.z < 36 and ab.end.y > 2.0:
					groups[k] = groups.get(k, 0) + 1
		print("GROUPES visibles avec maillages de l'arène : ", groups)
		# hors groupes
		var hors := []
		for mi in z.root.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if not _visible_total(m) or m.transparency > 0.99:
				continue
			var p := m.get_parent()
			var dans := false
			while p != null:
				if str(p.name).begins_with("Secteurs_"):
					dans = true
					break
				p = p.get_parent()
			if dans:
				continue
			var ab: AABB = m.global_transform * m.get_aabb()
			var cx := ab.get_center()
			if cx.x > 11 and cx.x < 41 and cx.z > 10 and cx.z < 36 and ab.end.y > 2.0:
				hors.append("%s %s" % [m.name, str(cx)])
		print("HORS GROUPES : ", hors.size(), " ", hors.slice(0, 15))
		quit()
	return false
