extends SceneTree
## P7.6 — position de la caméra de la ville par rapport à Aren (caméra A, après recalage), en plusieurs points.
## usage : godot --headless --path . --script res://tools/p7/camera_offset_p76.gd
var z
var n := 0
var pts := [Vector3(54, 107, 3.5), Vector3(60, 140, 0.0), Vector3(72, 62, 8.0)]
var i := 0
func _initialize() -> void:
	change_scene_to_file("res://scenes/p7/ville_v07b.tscn")
func _process(_d: float) -> bool:
	n += 1
	if z == null:
		if n > 20 and current_scene != null and current_scene.get("world") != null:
			z = current_scene
			n = 0
		return false
	if n == 5:
		z.s.warp_to(pts[i])
	if n == 60:
		var c: Camera3D = z.get_viewport().get_camera_3d()
		var h: Vector3 = z.body.global_position
		print("HEROS ", h, " CAMERA ", c.global_position, " DELTA ", c.global_position - h, " ROT ", c.global_rotation_degrees, " FOV ", c.fov)
		i += 1
		n = 0
		if i >= pts.size():
			quit()
	return false
