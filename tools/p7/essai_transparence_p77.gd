extends SceneTree
## P7.7 — essai : la transparence d'objet (GeometryInstance3D.transparency) agit-elle sur les matières de la ville ?
## Aren immobile sur la placette ; l'auberge (groupe vol_bat_auberge_taverne) passe à 0 / 0,5 / 1 ; une capture chacune.
## usage : godot --path . --script res://tools/p7/essai_transparence_p77.gd -- --out=<dossier>
var z
var n := 0
var etapes := [0.0, 0.5, 0.9]
var i := 0
var out := "user://"
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	change_scene_to_file("res://scenes/p7/ville_v07b.tscn")
func _process(_d: float) -> bool:
	n += 1
	if z == null:
		if n > 20 and current_scene != null and current_scene.get("world") != null:
			z = current_scene
			z.s.warp_to(Vector3(70.0, 141.0, 0.0))
			n = 0
		return false
	if n == 60 + i * 30:
		var g: Node = z.root.find_child("vol_bat_auberge_taverne", true, false)
		var nb := 0
		for c in g.find_children("*", "GeometryInstance3D", true, false):
			(c as GeometryInstance3D).transparency = etapes[i]
			nb += 1
		print("ESSAI transparence ", etapes[i], " sur ", nb, " maillages")
	if n == 75 + i * 30:
		root.get_viewport().get_texture().get_image().save_png(out + "/transp_%d.png" % i)
		i += 1
		if i >= etapes.size():
			quit()
	return false
