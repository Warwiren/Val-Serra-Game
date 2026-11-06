extends Node2D
## ARÈNE DE COMBAT EN PLANS (pilote « Lisière de l'avant-poste », crépuscule) — présentation seulement.
## Plans produits par tools/arena/ (Blender + passe pixel, palette commune avec l'exploration) :
##   base (ciel + sol), loin (forêt, brume), lisière (arbres, palissade, maison, rochers), avant (cadre bas).
## Affichage ×3 au plus proche voisin, comme les sprites de combat. Les plans proches bougent un peu plus que
## les lointains quand la caméra tremble ou recule (parallaxe légère). Lanternes : lumières Godot aux positions
## exactes des lanternes rendues, réutilisées pour l'éclairage du Vorgane. Aucune règle de combat ici.

const PX := 3
const PARALLAX := {"base": 0.0, "loin": 0.35, "lisiere": 0.15, "avant": -0.25}

var dir := "res://art/arena/lisiere/"
var use_painted := true                  # un plan repeint (dir/peint/<plan>.png) remplace le plan rendu
var painted: Array = []                  # plans effectivement repeints (compte rendu, tests)
var data: Dictionary
var lights: Array = []                   # positions écran des lanternes (pour SpriteMonsterView.scene_lights)
var _layers := {}
var _front: Node2D
var _mists: Array = []
var _lamps: Array = []
var _t := 0.0


## `front_parent` reçoit le premier plan (dessiné au-dessus des combattants).
func build(front_parent: Node) -> void:
	data = JSON.parse_string(FileAccess.open(dir + "arena.json", FileAccess.READ).get_as_text())
	_front = Node2D.new()
	_front.z_index = 60
	front_parent.add_child(_front)
	if use_painted and FileAccess.file_exists(dir + "peint/hd.json"):
		_build_hd()
		return
	var origin := _origin()
	var z := -100
	for n in ["base", "loin", "lisiere"]:
		var s := _sprite(n, origin)
		s.z_index = z
		add_child(s)
		z += 2
		if n == "loin":
			_add_mist(-97, 0.16, 138.0)                          # brume entre la forêt lointaine et la lisière
	_add_mist(-93, 0.08, 168.0)                                  # voile bas devant la lisière, derrière les combattants
	_front.add_child(_sprite("avant", origin))
	var cm := CanvasModulate.new()
	cm.color = Color(0.86, 0.86, 0.95)
	add_child(cm)
	for p in data["lights"]:
		var sp := origin + Vector2(p[0], p[1]) * PX
		lights.append(sp)
		var l := PointLight2D.new()
		l.texture = _radial(128)
		l.position = sp
		l.color = Color(1.0, 0.66, 0.34)
		l.energy = 0.7
		l.texture_scale = 3.2
		add_child(l)
		_lamps.append(l)
	_add_motes()


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


func _origin() -> Vector2:
	var size := Vector2(data["native"][0], data["native"][1]) * PX
	return ((Vector2(1280, 720) - size) / 2.0).round()


func _sprite(n: String, origin: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	var p := dir + "peint/" + n + ".png"
	if use_painted and ResourceLoader.exists(p):
		s.texture = load(p)
		painted.append(n)
	else:
		s.texture = load(dir + n + ".png")
	s.centered = false
	s.scale = Vector2(PX, PX)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = origin
	s.set_meta("origin", origin)
	s.set_meta("parallax", PARALLAX[n])
	_layers[n] = s
	return s


## Bande de brume : dégradé vertical doux (pas de flou sur les plans eux-mêmes : les pixels restent nets).
func _add_mist(z: int, alpha: float, y_native: float) -> void:
	var g := Gradient.new()
	g.set_color(0, Color(0.55, 0.6, 0.85, 0.0))
	g.add_point(0.5, Color(0.55, 0.6, 0.85, alpha))
	g.set_color(g.get_point_count() - 1, Color(0.55, 0.6, 0.85, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	t.width = 8
	t.height = 64
	var s := Sprite2D.new()
	s.texture = t
	s.centered = true
	s.scale = Vector2(1400 / 8.0, 2.2)
	s.position = Vector2(640, _origin().y + y_native * PX)
	s.z_index = z
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	s.material = m
	add_child(s)
	_mists.append(s)


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
