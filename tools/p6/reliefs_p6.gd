extends SceneTree
## P6.3 — recherche des « fausses marches » : volumes visibles posés sur un sol praticable (hauteur 5–80 cm), sans
## obstacle dans le modèle logique (World25) : Aren les traverse alors qu'ils ont l'air d'une marche ou d'un muret.
##   godot --headless --path . --script res://tools/p6/reliefs_p6.gd [-- --etat=tutorial_completed]
var z
var n := 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/p6/colisee.tscn")


func _process(_d: float) -> bool:
	n += 1
	if z == null:
		if n > 5 and current_scene != null and current_scene.get("world") != null:
			z = current_scene
			n = 0
		return false
	if n < 5:
		return false
	var w = z.world
	var res := {}
	var pile: Array = [z.root]
	while not pile.is_empty():
		var c = pile.pop_back()
		for k in c.get_children():
			pile.append(k)
		if not (c is GeometryInstance3D) or c is Light3D:
			continue
		var gi := c as GeometryInstance3D
		if gi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY or c is SpriteBase3D:
			continue
		var a: AABB = gi.global_transform * gi.get_aabb()
		var top := a.end.y
		var bas := a.position.y
		if bas > 0.08 or top < 0.05 or top > 0.8 or a.size.x * a.size.z < 0.02:
			continue
		var touches := 0
		var x := a.position.x + 0.05
		while x < a.end.x:
			var y := a.position.z + 0.05
			while y < a.end.z:
				var p := Vector2(x, y)
				if not w.stand(p, 0.0).is_empty():      # sol praticable ET libre (stand tient compte des obstacles)
					touches += 1
				y += 0.2
			x += 0.2
		if touches > 0:
			var cle := "%s (%.1f, %.1f) h %.2f–%.2f, %.1f × %.1f m" % [str(c.get_parent().name) + "/" + str(c.name), a.get_center().x, a.get_center().z, bas, top, a.size.x, a.size.z]
			res[cle] = touches
	print("RELIEFS P6.3 : %d volumes visibles bas posés sur un sol praticable" % res.size())
	var ks := res.keys()
	ks.sort_custom(func(p, q): return res[p] > res[q])
	for k in ks.slice(0, 40):
		print("  %4d pts  %s" % [res[k], k])
	quit()
	return false
