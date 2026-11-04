extends RefCounted
## Effets visuels simples et réutilisables (sans asset externe) : textures de lueur, textes flottants,
## gerbes de particules, anneaux d'onde.

const FxRing = preload("res://src/presentation/fx_ring.gd")

static var _glow_cache: Dictionary = {}


## Texture radiale douce (lumières, particules, brume).
static func glow_texture(size := 128, hard := false) -> Texture2D:
	var key := "%d_%s" % [size, hard]
	if _glow_cache.has(key):
		return _glow_cache[key]
	var grad := Gradient.new()
	if hard:
		grad.set_offset(0, 0.0)
		grad.set_color(0, Color(1, 1, 1, 1))
		grad.add_point(0.55, Color(1, 1, 1, 0.9))
		grad.set_offset(grad.get_point_count() - 1, 1.0)
		grad.set_color(grad.get_point_count() - 1, Color(1, 1, 1, 0))
	else:
		grad.set_color(0, Color(1, 1, 1, 1))
		grad.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = size
	tex.height = size
	_glow_cache[key] = tex
	return tex


## Texte qui monte et s'efface (dégâts, soins, « GARDE », etc.).
static func float_text(parent: Node, pos: Vector2, text: String, color: Color, size := 30, rise := 70.0, duration := 0.9) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	l.add_theme_constant_override("outline_size", maxi(4, size / 5))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(240, size * 1.4)
	l.position = pos - Vector2(120, size * 0.7)
	l.pivot_offset = l.size / 2
	l.z_index = 50
	l.scale = Vector2(0.4, 0.4)
	parent.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "scale", Vector2(1.0, 1.0), 0.08)
	t.parallel().tween_property(l, "position:y", l.position.y - rise, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(l, "modulate:a", 0.0, 0.25)
	t.tween_callback(l.queue_free)


## Gerbe de particules ponctuelle (impacts, éclats de rupture, sérum).
static func burst(parent: Node, pos: Vector2, color: Color, amount := 24, speed := 260.0, size := 10.0, lifetime := 0.6, gravity := 300.0) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.z_index = 40
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = lifetime
	p.explosiveness = 0.95
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.scale_amount_min = size * 0.04
	p.scale_amount_max = size * 0.1
	p.texture = glow_texture(64, true)
	p.color = color
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	parent.add_child(p)
	p.emitting = true
	p.get_tree().create_timer(lifetime + 0.3).timeout.connect(p.queue_free)


## Anneau d'onde qui s'agrandit (garde, sérum, rupture).
static func ring(parent: Node, pos: Vector2, color: Color, radius := 120.0, duration := 0.5, width := 8.0) -> void:
	var r := FxRing.new()
	r.position = pos
	r.color = color
	r.width = width
	r.z_index = 45
	parent.add_child(r)
	var t := r.create_tween()
	t.tween_property(r, "radius", radius, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.parallel().tween_property(r, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	t.tween_callback(r.queue_free)


## Lueur additive (sprite) — utile pour les auras et la lumière en rendu A.
static func glow_sprite(color: Color, size := 256.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = glow_texture(128)
	s.scale = Vector2.ONE * (size / 128.0)
	s.modulate = color
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = mat
	return s


## Arc de taille (traînée de lame) : croissant lumineux additif qui s'efface.
static func slash(parent: Node, pos: Vector2, radius: float, color: Color, duration := 0.32) -> void:
	var arc := Line2D.new()
	arc.position = pos
	arc.z_index = 46
	arc.width = radius * 0.22
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.55, 1.0))
	curve.add_point(Vector2(1.0, 0.1))
	arc.width_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(color, 0.0))
	grad.set_color(1, Color(1, 1, 1, 0.95))
	arc.gradient = grad
	arc.begin_cap_mode = Line2D.LINE_CAP_ROUND
	arc.end_cap_mode = Line2D.LINE_CAP_ROUND
	for i in range(19):
		var a := lerpf(-2.4, 0.5, i / 18.0)
		arc.add_point(Vector2(cos(a), sin(a)) * radius)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	arc.material = mat
	arc.rotation = -0.5
	parent.add_child(arc)
	var t := arc.create_tween()
	t.tween_property(arc, "rotation", 0.25, duration).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(arc, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	t.tween_callback(arc.queue_free)
	burst(parent, pos, color, 20, 360.0, 9.0, 0.45, 300.0)
