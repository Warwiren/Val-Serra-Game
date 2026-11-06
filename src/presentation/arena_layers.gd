extends Node2D
## ARÈNE DE COMBAT « Lisière de l'avant-poste » au crépuscule — présentation seulement (aucune règle de combat).
## Décor définitif : l'illustration art/arena/lisiere/peint/ (hd.json : image et lanternes), affichée 1:1 sans
## pixellisation (tools/arena/import_hd_arena.py). Lanternes Godot posées sur les lanternes peintes, réutilisées
## pour l'éclairage du Vorgane ; lucioles discrètes.

var dir := "res://art/arena/lisiere/"
var painted: Array = []
var lights: Array = []                   # positions écran des lanternes (pour SpriteMonsterView.scene_lights)
var _layers := {}
var _front: Node2D
var _mists: Array = []
var _lamps: Array = []
var _t := 0.0


## `front_parent` reçoit le premier plan (dessiné au-dessus des combattants ; vide pour une illustration unique).
func build(front_parent: Node) -> void:
	_front = Node2D.new()
	_front.z_index = 60
	front_parent.add_child(_front)
	_build_hd()


## Illustration fournie, affichée 1:1 (pas de pixellisation). Elle contient déjà brume, lumière peinte et
## profondeur : pas de bandes de brume ajoutées ; lanternes Godot discrètes aux lanternes peintes (elles éclairent
## les combattants et le Vorgane) ; lucioles. Un seul plan tant que la version en calques n'est pas fournie.
func _build_hd() -> void:
	var hd: Dictionary = JSON.parse_string(FileAccess.open(dir + "peint/hd.json", FileAccess.READ).get_as_text())
	var s := Sprite2D.new()
	s.texture = load(dir + "peint/" + hd["image"])
	s.centered = false
	var origin := ((Vector2(1280, 720) - s.texture.get_size()) / 2.0).round()
	s.position = origin
	s.z_index = -100
	s.set_meta("origin", origin)
	s.set_meta("parallax", 0.0)
	add_child(s)
	_layers["base"] = s
	painted.append("hd")
	var cm := CanvasModulate.new()
	cm.color = Color(0.93, 0.92, 0.98)
	add_child(cm)
	for p in hd["lumieres"]:
		var sp := origin + Vector2(p[0], p[1])
		lights.append(sp)
		var l := PointLight2D.new()
		l.texture = _radial(128)
		l.position = sp
		l.color = Color(1.0, 0.68, 0.38)
		l.energy = 0.45
		l.texture_scale = 2.6
		add_child(l)
		_lamps.append(l)
	_add_motes()


## Quelques lucioles chaudes près des lanternes et poussières d'Aether froides, très discrètes.
func _add_motes() -> void:
	for spec in [{"c": Color(1.0, 0.75, 0.4, 0.8), "n": 10, "pos": Vector2(1020, 360), "ext": Vector2(260, 120)},
			{"c": Color(0.6, 0.9, 1.0, 0.5), "n": 14, "pos": Vector2(640, 380), "ext": Vector2(620, 140)}]:
		var p := CPUParticles2D.new()
		p.amount = spec["n"]
		p.lifetime = 7.0
		p.preprocess = 7.0
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = spec["ext"]
		p.position = spec["pos"]
		p.gravity = Vector2(0, -3)
		p.initial_velocity_min = 2.0
		p.initial_velocity_max = 8.0
		p.spread = 180.0
		p.texture = _radial(8)
		p.scale_amount_min = 0.4
		p.scale_amount_max = 0.8
		p.color = spec["c"]
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1, 1, 1, 0))
		ramp.add_point(0.5, Color(1, 1, 1, 1))
		ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0))
		p.color_ramp = ramp
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		p.material = m
		p.z_index = -94
		add_child(p)


func _radial(size: int) -> GradientTexture2D:
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	g.gradient = gr
	g.width = size
	g.height = size
	return g


## Appelée chaque image avec le décalage de caméra (tremblement, recul) : parallaxe légère, au pixel près.


## Appelée chaque image avec le décalage de caméra (tremblement, recul) : parallaxe légère, au pixel près.
func update_parallax(cam_offset: Vector2, delta: float) -> void:
	_t += delta
	for n in _layers:
		var s: Sprite2D = _layers[n]
		s.position = (s.get_meta("origin") + cam_offset * float(s.get_meta("parallax"))).round()
	for i in _lamps.size():
		_lamps[i].energy = (0.45 if painted.has("hd") else 0.7) + 0.08 * sin(_t * 2.3 + i * 1.7) + 0.04 * sin(_t * 7.1 + i)
	for i in _mists.size():
		_mists[i].position.x = 640 + sin(_t * 0.07 + i) * 30.0


func set_shown(v: bool) -> void:
	visible = v
	_front.visible = v
