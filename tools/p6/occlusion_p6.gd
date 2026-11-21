extends SceneTree
## P6.1 — part de la surface praticable où Aren est caché par le décor (rayons vers la caméra réelle, comme le
## « trou de visibilité » du jeu), pour un réglage de caméra donné, pièce par pièce.
##   godot --headless --path . --script res://tools/p6/occlusion_p6.gd -- --cam_p6=C [--habillage=blockout]
const PAS := 0.75
var z


func _initialize() -> void:
	change_scene_to_file("res://scenes/p6/colisee.tscn")
	_run.call_deferred()


func _run() -> void:
	for i in 20:
		await physics_frame
	z = current_scene
	var par := {}
	for reg in z.world.regions:
		var r: Rect2 = reg["rect"]
		var tot := 0
		var cache := 0
		var x := r.position.x + PAS / 2.0
		while x < r.end.x:
			var y := r.position.y + PAS / 2.0
			while y < r.end.y:
				if not z.world.stand(Vector2(x, y), 0.0).is_empty():
					z.s.warp_to(Vector3(x, y, 0))
					z.apply_camera(z.s.cam.render_center(), z.s.cam.zoom)
					await physics_frame
					tot += 1
					if z.hero_occluded():
						cache += 1
				y += PAS
			x += PAS
		par[reg["id"]] = [cache, tot]
	var t := 0
	var c := 0
	var lignes: Array = []
	for k in par:
		t += par[k][1]
		c += par[k][0]
		lignes.append("%s %d/%d (%.0f %%)" % [k, par[k][0], par[k][1], 100.0 * par[k][0] / maxi(1, par[k][1])])
	print("OCCLUSION caméra %s habillage %s : %d/%d points cachés (%.1f %%)" % [z.cam_p6, "pilote" if z.habillage else "blockout", c, t, 100.0 * c / maxi(1, t)])
	print("  " + " · ".join(PackedStringArray(lignes)))
	quit()
