extends SceneTree
## P6.2 — coût de rendu par pièce (appels de dessin, primitives, objets rendus), avec ou sans secteurs.
##   godot --path . --rendering-method forward_plus --script res://tools/p6/perf_pieces_p6.gd [-- --sans_secteurs]
const POS := [["vestiaires", Vector3(26, 51, 0)], ["passage", Vector3(26, 45.5, 0)], ["salle d'attente", Vector3(26, 41, 0)], ["tunnel", Vector3(26, 34.5, 0)]]
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
		z.s.warp_to(POS[i][1])
	if n == 45:
		var dc := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var pr := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		var ob := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
		lignes.append("%s %d appels / %d k prim. / %d objets" % [POS[i][0], dc, pr / 1000, ob])
		i += 1
		n = 0
	return false
