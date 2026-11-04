extends Node2D
## Représentation du monstre : corps + une couche par partie ciblable (intacte / brisée),
## marqueurs de ciblage avec jauge d'intégrité, lueur d'attaque annoncée. Aucune règle de jeu ici.

const Art = preload("res://src/presentation/art.gd")
const Fx = preload("res://src/presentation/fx.gd")

const MOUTH := Vector2(62, 316)

var rig: Node2D
var body: Sprite2D
var parts: Dictionary = {}           # id -> {sprite, intact, broken, anchor(local)}
var markers: Node2D
var _gland_glow: Sprite2D
var _telegraph := false
var _t := 0.0
var _dead := false

# État d'affichage des marqueurs (rempli par la scène de combat)
var part_info: Dictionary = {}       # id -> {name, integrity, max, broken, hint, hint_color}
var selected_part: String = ""
var hovered_part: String = ""
var targeting: bool = false


## `overlay` : nœud d'une couche non assombrie (CanvasLayer qui suit la caméra) pour les marqueurs.
func setup(feet: Vector2, scale_factor := 0.9, overlay: Node = null) -> void:
	position = feet
	scale = Vector2.ONE * scale_factor
	rig = Node2D.new()
	add_child(rig)
	var off := Vector2(0, -(Art.MONSTER["feet"].y - Art.MONSTER["size"].y / 2.0))
	body = Sprite2D.new()
	body.texture = load(Art.MONSTER["body"])
	body.offset = off
	rig.add_child(body)
	var defs: Dictionary = Art.MONSTER["parts"]
	var order := defs.keys()
	order.sort_custom(func(a, b): return int(defs[a]["z"]) < int(defs[b]["z"]))
	for id in order:
		var d: Dictionary = defs[id]
		var s := Sprite2D.new()
		s.texture = load(d["intact"])
		s.offset = off
		rig.add_child(s)
		parts[id] = {"sprite": s, "intact": d["intact"], "broken": d["broken"],
			"anchor": d["anchor"] - Art.MONSTER["feet"]}
		if id == "glande":
			_gland_glow = Fx.glow_sprite(Color(0.4, 0.95, 1.0, 0.0), 260.0)
			_gland_glow.position = parts[id]["anchor"]
			rig.add_child(_gland_glow)
	markers = Node2D.new()
	markers.z_index = 30
	markers.draw.connect(_draw_markers)
	if overlay != null:
		overlay.add_child(markers)
	else:
		rig.add_child(markers)


func _process(delta: float) -> void:
	_t += delta
	if markers.get_parent() != rig:
		markers.global_transform = rig.global_transform
		markers.visible = not _dead
	if _dead:
		return
	var breath := sin(_t * 1.5)
	body.scale = Vector2(1.0 + breath * 0.006, 1.0 - breath * 0.01)
	for id in parts:
		parts[id]["sprite"].scale = body.scale
	if _gland_glow != null:
		var base := 0.25 if not part_info.get("glande", {}).get("broken", false) else 0.0
		var a := base + (0.55 + 0.45 * sin(_t * 9.0) if _telegraph else 0.0)
		_gland_glow.modulate.a = a
		_gland_glow.scale = Vector2.ONE * ((2.6 if _telegraph else 1.9) + 0.2 * sin(_t * 4.0))
	if _telegraph:
		body.modulate = Color(1.0 + 0.25 * (0.5 + 0.5 * sin(_t * 9.0)), 0.92, 0.95)
	markers.queue_redraw()


func part_global(id: String) -> Vector2:
	return rig.to_global(parts[id]["anchor"])


func mouth_global() -> Vector2:
	return rig.to_global(MOUTH - Art.MONSTER["feet"])


func center() -> Vector2:
	return rig.to_global(Vector2(40, -220))


## Partie sous le pointeur (coordonnées globales), ou "".
func part_at(global_pos: Vector2) -> String:
	var best := ""
	var best_d := 70.0
	for id in parts:
		var d := global_pos.distance_to(part_global(id))
		if d < best_d:
			best_d = d
			best = id
	return best


func _draw_markers() -> void:
	var font := ThemeDB.fallback_font
	for id in parts:
		var info: Dictionary = part_info.get(id, {})
		if info.is_empty():
			continue
		var p: Vector2 = parts[id]["anchor"]
		var sel: bool = targeting and id == selected_part
		var hov: bool = id == hovered_part
		var r := 30.0 if not sel else 36.0
		var broken: bool = info.get("broken", false)
		markers.draw_circle(p, r, Color(0.04, 0.06, 0.1, 0.22))
		if broken:
			markers.draw_arc(p, r, 0, TAU, 40, Color(0.6, 0.6, 0.65, 0.9), 4.0, true)
			markers.draw_line(p + Vector2(-12, -12), p + Vector2(12, 12), Color(1, 0.5, 0.45), 4.0, true)
			markers.draw_line(p + Vector2(12, -12), p + Vector2(-12, 12), Color(1, 0.5, 0.45), 4.0, true)
		else:
			var ratio := float(info["integrity"]) / maxf(1.0, float(info["max"]))
			var col := Color(0.6, 0.95, 1.0) if ratio > 0.35 else Color(1.0, 0.65, 0.3)
			markers.draw_arc(p, r, 0, TAU, 40, Color(1, 1, 1, 0.18), 6.0, true)
			markers.draw_arc(p, r, -PI / 2, -PI / 2 + TAU * ratio, 40, col, 6.0, true)
		if sel:
			var rot := _t * 1.8
			for k in range(4):
				var a := rot + k * PI / 2
				markers.draw_arc(p, r + 14, a, a + 0.9, 12, Art.C_GOLD, 5.0, true)
			var pulse := 0.5 + 0.5 * sin(_t * 6.0)
			markers.draw_arc(p, r + 24 + pulse * 6, 0, TAU, 48, Color(Art.C_GOLD, 0.35 * pulse), 3.0, true)
		elif hov:
			markers.draw_arc(p, r + 10, 0, TAU, 40, Color(1, 1, 1, 0.7), 3.0, true)
		# Étiquette
		var label: String = info["name"]
		var sub: String = "BRISÉE" if broken else "%d / %d" % [info["integrity"], info["max"]]
		var lp := p + Vector2(0, r + 28)
		var fs := 22 if sel else 19
		markers.draw_string_outline(font, lp - Vector2(110, 0), label, HORIZONTAL_ALIGNMENT_CENTER, 220, fs, 6, Color(0, 0, 0, 0.85))
		markers.draw_string(font, lp - Vector2(110, 0), label, HORIZONTAL_ALIGNMENT_CENTER, 220, fs, Art.C_GOLD if sel else Art.C_TEXT)
		markers.draw_string_outline(font, lp + Vector2(-110, 22), sub, HORIZONTAL_ALIGNMENT_CENTER, 220, 17, 5, Color(0, 0, 0, 0.85))
		markers.draw_string(font, lp + Vector2(-110, 22), sub, HORIZONTAL_ALIGNMENT_CENTER, 220, 17, Art.C_DIM if broken else Color(0.75, 0.95, 1.0))
		var hint: String = info.get("hint", "")
		if hint != "" and not broken:
			markers.draw_string_outline(font, p + Vector2(-60, -r - 10), hint, HORIZONTAL_ALIGNMENT_CENTER, 120, 18, 5, Color(0, 0, 0, 0.85))
			markers.draw_string(font, p + Vector2(-60, -r - 10), hint, HORIZONTAL_ALIGNMENT_CENTER, 120, 18, info.get("hint_color", Art.C_TEXT))


func set_telegraph(on: bool) -> void:
	_telegraph = on
	if not on:
		var t := create_tween()
		t.tween_property(body, "modulate", Color.WHITE, 0.3)
	else:
		Fx.ring(get_parent(), part_global("glande"), Color(1.0, 0.45, 0.4, 0.9), 160.0, 0.6, 6.0)


## Préparation d'une attaque ordinaire : le monstre se ramasse.
func prepare() -> void:
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(16, 6), 0.25).set_trans(Tween.TRANS_SINE)


## Attaque au corps à corps vers une cible. Renvoie au moment de l'impact.
func lunge(target_global: Vector2) -> void:
	var dx := clampf(target_global.x - global_position.x + 300.0, -260.0, -60.0) / scale.x
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(30, 10), 0.12)
	t.tween_property(rig, "position", Vector2(dx, 14), 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(rig, "rotation_degrees", -6.0, 0.16)
	await t.finished
	var back := create_tween()
	back.tween_interval(0.1)
	back.tween_property(rig, "position", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_QUAD)
	back.parallel().tween_property(rig, "rotation_degrees", 0.0, 0.4)


## Souffle d'Aether : se cabre puis crache un flot de particules vers le groupe.
func breath(targets: Array) -> void:
	set_telegraph(false)
	var t := create_tween()
	t.tween_property(rig, "rotation_degrees", 5.0, 0.2)
	t.tween_property(rig, "rotation_degrees", -4.0, 0.12)
	await t.finished
	var from := mouth_global()
	for tg in targets:
		var p := CPUParticles2D.new()
		p.position = from
		p.z_index = 40
		p.amount = 50
		p.lifetime = 0.45
		p.one_shot = true
		p.explosiveness = 0.3
		var dir: Vector2 = (tg - from).normalized()
		p.direction = dir
		p.spread = 10.0
		p.gravity = Vector2.ZERO
		p.initial_velocity_min = (tg - from).length() * 1.6
		p.initial_velocity_max = (tg - from).length() * 2.2
		p.scale_amount_min = 0.25
		p.scale_amount_max = 0.6
		p.texture = Fx.glow_texture(64, true)
		p.color = Color(0.45, 0.95, 1.0, 0.9)
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = mat
		get_parent().add_child(p)
		p.emitting = true
		get_tree().create_timer(1.0).timeout.connect(p.queue_free)
	await get_tree().create_timer(0.3).timeout
	var back := create_tween()
	back.tween_property(rig, "rotation_degrees", 0.0, 0.35)


func hurt(part_id: String, heavy: bool) -> void:
	var s: Sprite2D = parts[part_id]["sprite"] if parts.has(part_id) else body
	s.modulate = Color(3, 3, 3)
	body.modulate = Color(1.6, 1.6, 1.6) if heavy else body.modulate
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(14 if heavy else 7, 0), 0.05)
	t.tween_property(rig, "position", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(s, "modulate", Color.WHITE, 0.2)
	if not _telegraph:
		t.parallel().tween_property(body, "modulate", Color.WHITE, 0.2)


func break_part(part_id: String) -> void:
	var entry: Dictionary = parts[part_id]
	var s: Sprite2D = entry["sprite"]
	var pos := part_global(part_id)
	s.modulate = Color(4, 4, 4)
	Fx.ring(get_parent(), pos, Color(1.0, 0.9, 0.6, 1.0), 220.0, 0.55, 10.0)
	Fx.burst(get_parent(), pos, Color(0.75, 0.7, 1.0), 40, 520.0, 14.0, 0.9, 700.0)
	Fx.burst(get_parent(), pos, Color(1.0, 0.85, 0.5), 30, 380.0, 9.0, 0.6, 200.0)
	await get_tree().create_timer(0.08).timeout
	s.texture = load(entry["broken"])
	var t := create_tween()
	t.tween_property(s, "modulate", Color.WHITE, 0.4)


func die() -> void:
	_dead = true
	_telegraph = false
	var t := create_tween()
	t.tween_property(rig, "rotation_degrees", 8.0, 0.6).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(rig, "position", Vector2(30, 40), 0.9)
	t.parallel().tween_property(rig, "modulate", Color(0.3, 0.3, 0.4, 0.0), 1.2)
	if _gland_glow != null:
		t.parallel().tween_property(_gland_glow, "modulate:a", 0.0, 0.4)
