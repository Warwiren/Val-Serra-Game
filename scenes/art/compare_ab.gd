extends Node2D
## Comparaison visuelle des deux solutions pour le Vorgane, dans la MÊME arène et à côté du MÊME sprite d'Aren.
##   A : modèle 3D animé (GLB) rendu en direct dans un SubViewport (caméra orthographique + lumières propres)
##   B : animations rendues dans Blender puis converties en sprites pixel art
## Lancement : godot --path . res://scenes/art/compare_ab.tscn -- --cmp=A   (ou --cmp=B)

const Stage = preload("res://src/presentation/stage.gd")

var mode := "A"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cmp="):
			mode = a.substr(6)
	var stage := Stage.new()
	stage.layer_defs = Stage.HD_LAYERS
	stage.front_def = Stage.HD_FRONT
	stage.rays_path = Stage.HD_RAYS
	stage.ambient = Color(0.62, 0.66, 0.84)
	stage.fog_color = Color(0.13, 0.19, 0.32)
	stage.mist_color = Color(0.5, 0.64, 0.9, 0.12)
	stage.light_points = [{"pos": Vector2(690, 210), "color": Color(0.7, 0.8, 1.0), "energy": 0.6, "size": 6.0}]
	add_child(stage)
	stage.build(self)
	stage.set_mode("B")
	var aren := Sprite2D.new()
	aren.texture = load("res://art/sprites/aren/aren_repos.png")
	aren.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	aren.scale = Vector2(3, 3)
	aren.centered = false
	aren.offset = Vector2(-44, -80)
	aren.position = Vector2(330, 560)
	add_child(aren)
	if mode == "A":
		_monster_3d()
	else:
		_monster_sprites()
	var l := Label.new()
	l.text = "Solution %s — %s" % [mode, "modèle 3D animé en direct (GLB)" if mode == "A" else "rendu Blender converti en sprites pixel art"]
	l.position = Vector2(20, 16)
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(l)


func _monster_3d() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(768, 768)
	vp.transparent_bg = true
	vp.own_world_3d = true
	add_child(vp)
	var model: Node3D = load("res://art/3d/vorgane_rig.glb").instantiate()
	vp.add_child(model)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.6
	cam.position = Vector3(6, 0.7, 0.3)
	cam.rotation_degrees = Vector3(-6.8, 90, 0)
	vp.add_child(cam)
	var key := DirectionalLight3D.new()
	key.light_color = Color(0.85, 0.9, 1.0)
	key.light_energy = 1.6
	key.rotation_degrees = Vector3(-40, 60, 0)
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.light_color = Color(0.55, 0.8, 1.0)
	rim.light_energy = 2.2
	rim.rotation_degrees = Vector3(-20, -150, 0)
	vp.add_child(rim)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.3, 0.38, 0.6)
	env.environment.ambient_light_energy = 0.8
	vp.add_child(env)
	var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	if ap != null:
		print("animations GLB : ", ap.get_animation_list())
		ap.play("idle")
	var spr := Sprite2D.new()
	spr.texture = vp.get_texture()
	spr.position = Vector2(930, 420)
	add_child(spr)


func _monster_sprites() -> void:
	var spr := Sprite2D.new()
	spr.texture = load("res://art/sprites/vorgane/claw_001.png")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(3, 3)
	spr.position = Vector2(930, 420)
	add_child(spr)
