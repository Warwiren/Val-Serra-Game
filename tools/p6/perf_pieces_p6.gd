extends SceneTree
## P6.2 — coût de rendu par pièce (appels de dessin, primitives, objets rendus), avec ou sans secteurs.
##   godot --path . --rendering-method forward_plus --script res://tools/p6/perf_pieces_p6.gd [-- --sans_secteurs]
const POS := [["vestiaires", Vector3(26, 51, 0)], ["passage", Vector3(26, 45.5, 0)], ["salle d'attente", Vector3(26, 41, 0)], ["tunnel", Vector3(26, 34.5, 0)], ["sortie du tunnel", Vector3(26, 32.4, 0)], ["arène (entrée)", Vector3(26, 29, 0)],
	["arène (centre)", Vector3(26, 23, 0)], ["tunnel est", Vector3(41, 23, 0)], ["coursive", Vector3(50, 23, 0)], ["infirmerie", Vector3(46.6, 38, 0)], ["couloir de sortie", Vector3(60, 23, 0)]]
const Routes = preload("res://src/explore25/routes25.gd")
var z
var i := 0
var n := 0
var lignes: Array = []


func _initialize() -> void:
	change_scene_to_file("res://scenes/p6/colisee.tscn")


func _process(_d: float) -> bool:
	n += 1
	if z == null:
		if n > 20 and current_scene != null and current_scene.get("world") != null:
			z = current_scene
			n = 0
		return false
	if i >= POS.size():
		print("PERF P6.2 %s : %s" % ["SANS secteurs" if OS.get_cmdline_user_args().has("--sans_secteurs") else "AVEC secteurs", " · ".join(PackedStringArray(lignes))])
		quit()
		return false
	if n == 1:
		var p: Vector3 = POS[i][1]
		var q = Routes.sud(Vector2(p.x, p.y))         # P6.2-D : bloc sud décalé selon la longueur du tunnel
		z.s.warp_to(Vector3(q.x, q.y, 0.0))
	if n == 45:
		var dc := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var pr := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		var ob := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
		var vm := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / (1024 * 1024)
		lignes.append("%s %d appels / %d k prim. / %d objets / %d Mo vidéo" % [POS[i][0], dc, pr / 1000, ob, vm])
		i += 1
		n = 0
	return false
