extends SceneTree
## P6.3 — capture de la scène de combat tutoriel telle quelle (décor, Aren, commandant, interface), sans rien modifier.
##   godot --path . --rendering-method forward_plus --resolution 1280x720 --script res://tools/p6/capture_combat_p6.gd -- --out=/tmp/c.png
var n := 0
var out := "user://combat_tutoriel.png"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	change_scene_to_file("res://scenes/battle/combat_tutoriel.tscn")


func _process(_d: float) -> bool:
	n += 1
	if n == 150:
		root.get_viewport().get_texture().get_image().save_png(out)
		print("COMBAT capture ", out)
		quit()
	return false
