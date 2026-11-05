extends Node2D
## Décor en calques avec deux présentations du MÊME contenu :
##  - Variante A (2D) : calques posés à plat, aucun mouvement, aucune lumière dynamique.
##  - Variante B (2.5D) : parallax selon la caméra, flou de profondeur et brume sur les plans lointains,
##    premier plan flou devant les personnages, lumière d'ambiance, sources lumineuses, particules.
## Les personnages et la logique ne changent pas entre A et B.

const Fx = preload("res://src/presentation/fx.gd")
const DEPTH_SHADER = preload("res://src/presentation/depth_blur.gdshader")

const LAYERS := [
	# nom, chemin, facteur de parallax (1 = immobile à l'écran), flou, brume
	{"name": "sky",    "path": "res://art/stage/sky.svg",    "parallax": 0.96, "blur": 0.0, "fog": 0.0},
	{"name": "far",    "path": "res://art/stage/far.svg",    "parallax": 0.85, "blur": 2.2, "fog": 0.28},
	{"name": "mid",    "path": "res://art/stage/mid.svg",    "parallax": 0.62, "blur": 1.1, "fog": 0.12},
	{"name": "ground", "path": "res://art/stage/ground.svg", "parallax": 0.0,  "blur": 0.0, "fog": 0.0},
]
const FRONT := {"path": "res://art/stage/front.svg", "parallax": -0.35, "blur": 2.6}

## Arène du prototype artistique (forêt nocturne en 8 plans).
const HD_LAYERS := [
	{"name": "sky",        "path": "res://art/hd/arena/sky.svg",        "parallax": 0.97, "blur": 0.0, "fog": 0.0},
	{"name": "ridge",      "path": "res://art/hd/arena/ridge.svg",      "parallax": 0.9,  "blur": 2.4, "fog": 0.30},
	{"name": "forest_far", "path": "res://art/hd/arena/forest_far.svg", "parallax": 0.78, "blur": 1.8, "fog": 0.22},
	{"name": "forest_mid", "path": "res://art/hd/arena/forest_mid.svg", "parallax": 0.55, "blur": 0.9, "fog": 0.08},
	{"name": "trees_near", "path": "res://art/hd/arena/trees_near.svg", "parallax": 0.25, "blur": 0.0, "fog": 0.0},
	{"name": "ground",     "path": "res://art/hd/arena/ground.svg",     "parallax": 0.0,  "blur": 0.0, "fog": 0.0},
]
const HD_FRONT := {"path": "res://art/hd/arena/front.svg", "parallax": -0.4, "blur": 2.8}
const HD_RAYS := "res://art/hd/arena/rays.svg"

var mode: String = "B"
var center := Vector2(640, 360)
var extra_props: Array = []          # [{path, pos, scale, glow?}] posés sur le sol (zone d'exploration)
var light_points: Array = []         # [{pos, color, energy, size}] sources lumineuses en mode B
var layer_defs: Array = LAYERS
var front_def: Dictionary = FRONT
var rays_path: String = ""
var ambient := Color(0.70, 0.72, 0.86)
var mist_color := Color(0.75, 0.82, 0.95, 0.10)
var fog_color := Color(0.72, 0.78, 0.9)
var pixelate: int = 1                 # > 1 : décor ramené à la densité de pixels des sprites (×N, sans flou)
var _rays: Sprite2D

var _layers: Dictionary = {}
var _front: Sprite2D
var _front_holder: Node2D
var _modulate: CanvasModulate
var _b_nodes: Array = []             # nœuds présents uniquement en mode B
var _a_nodes: Array = []             # nœuds présents uniquement en mode A
var _time := 0.0


## `front_parent` reçoit le calque de premier plan (doit être dessiné au-dessus des personnages).
func build(front_parent: Node) -> void:
	for def in layer_defs:
		var s := Sprite2D.new()
		s.texture = _tex(def["path"])
		_pix(s)
		s.position = center
		s.z_index = -100 + _layers.size()
		add_child(s)
		_layers[def["name"]] = {"sprite": s, "def": def}
	for prop in extra_props:
		var p := Sprite2D.new()
		p.texture = load(prop["path"])
		p.scale = Vector2.ONE * float(prop.get("scale", 1.0))
		p.centered = true
		p.offset = Vector2(0, -p.texture.get_height() / 2.0)
		p.position = prop["pos"]
		p.z_index = -50
		add_child(p)
	_front_holder = Node2D.new()
	_front_holder.z_index = 60
	front_parent.add_child(_front_holder)
	_front = Sprite2D.new()
	_front.texture = _tex(front_def["path"])
	_pix(_front)
	_front.position = center
	_front_holder.add_child(_front)

	# Éléments propres au mode B
	_modulate = CanvasModulate.new()
	_modulate.color = ambient
	add_child(_modulate)
	_b_nodes.append(_modulate)
	for lp in light_points:
		var light := PointLight2D.new()
		light.texture = Fx.glow_texture(256)
		light.position = lp["pos"]
		light.color = lp["color"]
		light.energy = float(lp.get("energy", 1.0))
		light.texture_scale = float(lp.get("size", 3.0))
		light.blend_mode = Light2D.BLEND_MODE_ADD
		add_child(light)
		_b_nodes.append(light)
	if rays_path != "":
		_rays = Sprite2D.new()
		_rays.texture = load(rays_path)
		_rays.position = center
		_rays.z_index = -60
		var rm := CanvasItemMaterial.new()
		rm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		rm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_rays.material = rm
		add_child(_rays)
		_b_nodes.append(_rays)
	_add_mist()
	_add_particles()
	set_mode(mode)


func _tex(path: String) -> Texture2D:
	var t: Texture2D = load(path)
	if pixelate <= 1:
		return t
	var img := t.get_image()
	img.resize(img.get_width() / pixelate, img.get_height() / pixelate, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


func _pix(s: Sprite2D) -> void:
	if pixelate > 1:
		s.scale = Vector2.ONE * pixelate
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _add_mist() -> void:
	for i in range(5):
		var m := Fx.glow_sprite(mist_color, 520.0)
		m.scale = Vector2(5.0, 0.9) * (0.6 + i * 0.1)
		m.position = Vector2(150 + i * 260, 470 + (i % 2) * 18)
		m.z_index = -96
		m.set_meta("drift", 8.0 + i * 3.0)
		add_child(m)
		_b_nodes.append(m)


func _add_particles() -> void:
	# Poussières d'Aether flottantes (avant-plan et plan moyen)
	for layer in [{"z": 55, "amount": 26, "scale": 0.22, "alpha": 0.85}, {"z": -90, "amount": 40, "scale": 0.12, "alpha": 0.6}]:
		var p := CPUParticles2D.new()
		p.amount = layer["amount"]
		p.lifetime = 9.0
		p.preprocess = 9.0
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(700, 260)
		p.position = Vector2(640, 420)
		p.direction = Vector2(0.3, -1)
		p.spread = 40.0
		p.gravity = Vector2(0, -6)
		p.initial_velocity_min = 4.0
		p.initial_velocity_max = 16.0
		p.scale_amount_min = layer["scale"] * 0.5
		p.scale_amount_max = layer["scale"]
		p.texture = Fx.glow_texture(64, true)
		p.color = Color(0.55, 0.92, 1.0, layer["alpha"])
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1, 1, 1, 0))
		ramp.add_point(0.3, Color(1, 1, 1, 1))
		ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0))
		p.color_ramp = ramp
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		p.material = mat
		p.z_index = layer["z"]
		add_child(p)
		_b_nodes.append(p)


func set_mode(new_mode: String) -> void:
	mode = new_mode
	var b := mode == "B"
	for n in _b_nodes:
		n.visible = b
	for key in _layers:
		var entry: Dictionary = _layers[key]
		var s: Sprite2D = entry["sprite"]
		var def: Dictionary = entry["def"]
		s.position = center
		if b and (float(def["blur"]) > 0.0 or float(def["fog"]) > 0.0):
			var mat := ShaderMaterial.new()
			mat.shader = DEPTH_SHADER
			mat.set_shader_parameter("radius", float(def["blur"]) / float(pixelate))
			mat.set_shader_parameter("fog", float(def["fog"]))
			mat.set_shader_parameter("fog_color", fog_color)
			s.material = mat
		else:
			s.material = null
	_front.position = center
	if b:
		var fm := ShaderMaterial.new()
		fm.shader = DEPTH_SHADER
		fm.set_shader_parameter("radius", float(front_def["blur"]) / float(pixelate))
		fm.set_shader_parameter("fog", 0.0)
		fm.set_shader_parameter("tint", Color(0.55, 0.6, 0.65, 1.0))
		_front.material = fm
		_front.scale = Vector2(1.08, 1.08) * pixelate
	else:
		_front.material = null
		_front.scale = Vector2.ONE * pixelate


## À appeler chaque image avec le décalage de caméra par rapport au centre (mode B seulement).
func update_parallax(cam_offset: Vector2, delta: float) -> void:
	_time += delta
	if mode != "B":
		return
	for key in _layers:
		var entry: Dictionary = _layers[key]
		entry["sprite"].position = center + cam_offset * float(entry["def"]["parallax"])
	_front.position = center + cam_offset * float(front_def["parallax"])
	if _rays != null:
		_rays.modulate.a = 0.75 + 0.25 * sin(_time * 0.6)
		_rays.position = center + cam_offset * 0.9
	for n in _b_nodes:
		if n is Sprite2D and n.has_meta("drift"):
			n.position.x += sin(_time * 0.2 + n.position.y) * float(n.get_meta("drift")) * delta


func light_nodes() -> Array:
	return _b_nodes.filter(func(n): return n is PointLight2D)
