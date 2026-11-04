extends "res://src/presentation/monster_view.gd"
## Vorgane articulé (prototype artistique) : Skeleton2D + Bone2D (tête, mâchoire, patte, griffe, queue),
## carapace en éclats séparés qui volent à la rupture, plaie révélée dessous.
## Construit depuis data/rig/vorgane_hd.json. Même interface que MonsterView.

const RIM_SHADER = preload("res://src/presentation/rim_light.gdshader")

var skeleton: Skeleton2D
var bones: Dictionary = {}
var part_sprites: Dictionary = {}     # id de partie -> [Sprite2D]
var materials: Array = []
var rig_def: Dictionary = {}
var _wound: Sprite2D
var _mouth := Vector2.ZERO
var _mouth_jaw := Vector2.ZERO        # bout du museau, dans le repère de la mâchoire
var _busy := false
var _rest_root := Vector2.ZERO


func setup(feet: Vector2, scale_factor := 0.9, overlay: Node = null) -> void:
	position = feet
	scale = Vector2.ONE * scale_factor
	var f := FileAccess.open("res://data/rig/vorgane_hd.json", FileAccess.READ)
	rig_def = JSON.parse_string(f.get_as_text())
	var canvas := Vector2(rig_def["canvas"][0], rig_def["canvas"][1])
	var foot := Vector2(rig_def["feet"][0], rig_def["feet"][1])
	_mouth = Vector2(rig_def["mouth"][0], rig_def["mouth"][1]) - foot

	rig = Node2D.new()
	add_child(rig)
	skeleton = Skeleton2D.new()
	rig.add_child(skeleton)
	var pivots := {}
	for b in rig_def["bones"]:
		var bone := Bone2D.new()
		bone.name = b["name"]
		var pv := Vector2(b["pivot"][0], b["pivot"][1])
		pivots[b["name"]] = pv
		if b["parent"] == "":
			bone.position = pv - foot
			skeleton.add_child(bone)
		else:
			bone.position = pv - pivots[b["parent"]]
			bones[b["parent"]].add_child(bone)
		bone.set_autocalculate_length_and_angle(false)
		bone.set_length(1.0)
		bone.rest = bone.transform
		bones[b["name"]] = bone
	_rest_root = bones["root"].position
	_mouth_jaw = Vector2(rig_def["mouth"][0], rig_def["mouth"][1]) - pivots["jaw"]

	var z := 0
	for layer in rig_def["layers"]:
		var s := Sprite2D.new()
		s.texture = load("%s/%s.svg" % [rig_def["art_dir"], layer["file"]])
		var pv: Vector2 = pivots[layer["bone"]]
		s.offset = canvas / 2.0 - pv
		s.z_index = z
		z += 1
		var mat := ShaderMaterial.new()
		mat.shader = RIM_SHADER
		mat.set_shader_parameter("rim_color", Color(0.7, 0.85, 1.0))
		mat.set_shader_parameter("strength", 0.7)
		s.material = mat
		materials.append(mat)
		bones[layer["bone"]].add_child(s)
		if layer.get("hidden", false):
			s.visible = false
		if layer.get("role", "") == "wound":
			_wound = s
		if layer.has("part"):
			var pid: String = layer["part"]
			if not part_sprites.has(pid):
				part_sprites[pid] = []
			part_sprites[pid].append(s)
			if layer.has("broken"):
				s.set_meta("broken_tex", "%s/%s.svg" % [rig_def["art_dir"], layer["broken"]])
			if layer.get("shard", false):
				s.set_meta("shard_center", Vector2(layer["center"][0], layer["center"][1]) - pv)

	body = part_sprites.get("carapace", [null])[0]
	for pid in rig_def["anchors"]:
		var a := Vector2(rig_def["anchors"][pid][0], rig_def["anchors"][pid][1]) - foot
		parts[pid] = {"sprite": part_sprites[pid][0], "intact": "", "broken": "", "anchor": a}

	_gland_glow = Fx.glow_sprite(Color(0.4, 0.95, 1.0, 0.0), 300.0)
	_gland_glow.position = parts["glande"]["anchor"]
	_gland_glow.z_index = 50
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
	if not _busy:
		# Repos vivant : souffle, tête qui ondule, queue qui fouette, mâchoire entrouverte
		bones["root"].position = _rest_root + Vector2(0, sin(_t * 1.5) * 4.0)
		bones["tail"].rotation = sin(_t * 1.3) * 0.12
		bones["head"].rotation = sin(_t * 1.1) * 0.035 + (0.14 if _telegraph else 0.0)
		bones["jaw"].rotation = -0.04 - (0.5 + sin(_t * 1.7) * 0.03) * float(_telegraph) - sin(_t * 2.0) * 0.03
		bones["arm"].rotation = sin(_t * 1.5 + 1.0) * 0.025
	var gland_broken: bool = part_info.get("glande", {}).get("broken", false)
	var base := 0.0 if gland_broken else 0.35
	_gland_glow.modulate.a = base + ((0.55 + 0.45 * sin(_t * 9.0)) if _telegraph and not gland_broken else 0.0)
	_gland_glow.scale = Vector2.ONE * ((3.0 if _telegraph else 2.2) + 0.25 * sin(_t * 4.0))
	markers.queue_redraw()


func mouth_global() -> Vector2:
	return bones["jaw"].to_global(_mouth_jaw)


func center() -> Vector2:
	return rig.to_global(Vector2(-40, -230))


func _flash(amount: float, duration: float, color := Color.WHITE) -> void:
	for m in materials:
		m.set_shader_parameter("flash_color", color)
	_set_flash(amount)
	var t := create_tween()
	t.tween_method(_set_flash, amount, 0.0, duration)


func _set_flash(v: float) -> void:
	for m in materials:
		m.set_shader_parameter("flash", v)


func set_telegraph(on: bool) -> void:
	_telegraph = on
	if on:
		Fx.ring(get_parent(), part_global("glande"), Color(1.0, 0.45, 0.4, 0.9), 200.0, 0.6, 7.0)


func prepare() -> void:
	_busy = true
	var t := create_tween()
	t.tween_property(bones["arm"], "rotation", 0.5, 0.25).set_trans(Tween.TRANS_BACK)
	t.parallel().tween_property(bones["head"], "rotation", -0.08, 0.25)
	t.parallel().tween_property(bones["root"], "position", _rest_root + Vector2(18, 8), 0.25)
	await t.finished
	_busy = false


## Coup de griffe : patte levée puis abattue, bond vers la cible.
func lunge(target_global: Vector2) -> void:
	_busy = true
	var dx := clampf(target_global.x - global_position.x + 330.0, -300.0, -60.0) / scale.x
	var t := create_tween()
	t.tween_property(bones["arm"], "rotation", 0.95, 0.14).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(bones["head"], "rotation", 0.1, 0.14)
	t.parallel().tween_property(bones["jaw"], "rotation", -0.35, 0.14)
	t.parallel().tween_property(bones["root"], "position", _rest_root + Vector2(26, 6), 0.14)
	t.tween_property(bones["arm"], "rotation", -0.3, 0.13).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(bones["root"], "position", _rest_root + Vector2(dx, 16), 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(bones["head"], "rotation", -0.12, 0.13)
	await t.finished
	Fx.slash(get_parent(), target_global + Vector2(30, 0), 110.0, Color(0.75, 0.6, 1.0))
	var back := create_tween()
	back.tween_interval(0.12)
	back.tween_property(bones["root"], "position", _rest_root, 0.45).set_trans(Tween.TRANS_QUAD)
	back.parallel().tween_property(bones["arm"], "rotation", 0.0, 0.45)
	back.parallel().tween_property(bones["head"], "rotation", 0.0, 0.45)
	back.parallel().tween_property(bones["jaw"], "rotation", -0.04, 0.45)
	back.tween_callback(func(): _busy = false)


## Souffle d'Aether : se cabre, gueule ouverte, flot de particules.
func breath(targets: Array) -> void:
	_telegraph = false
	_busy = true
	var t := create_tween()
	t.tween_property(bones["head"], "rotation", 0.28, 0.22)
	t.parallel().tween_property(bones["jaw"], "rotation", -0.15, 0.22)
	t.parallel().tween_property(bones["root"], "position", _rest_root + Vector2(20, -6), 0.22)
	t.tween_property(bones["head"], "rotation", -0.1, 0.12)
	t.parallel().tween_property(bones["jaw"], "rotation", -0.7, 0.12)
	await t.finished
	var from := mouth_global()
	for tg in targets:
		var p := CPUParticles2D.new()
		p.position = from
		p.z_index = 40
		p.amount = 70
		p.lifetime = 0.5
		p.one_shot = true
		p.explosiveness = 0.25
		p.direction = (tg - from).normalized()
		p.spread = 12.0
		p.gravity = Vector2.ZERO
		p.initial_velocity_min = (tg - from).length() * 1.5
		p.initial_velocity_max = (tg - from).length() * 2.1
		p.scale_amount_min = 0.3
		p.scale_amount_max = 0.8
		p.texture = Fx.glow_texture(64, true)
		p.color = Color(0.45, 0.95, 1.0, 0.95)
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = mat
		get_parent().add_child(p)
		p.emitting = true
		get_tree().create_timer(1.2).timeout.connect(p.queue_free)
	await get_tree().create_timer(0.3).timeout
	var back := create_tween()
	back.tween_property(bones["head"], "rotation", 0.0, 0.4)
	back.parallel().tween_property(bones["jaw"], "rotation", -0.04, 0.4)
	back.parallel().tween_property(bones["root"], "position", _rest_root, 0.4)
	back.tween_callback(func(): _busy = false)


func hurt(part_id: String, heavy: bool) -> void:
	_flash(0.55 if heavy else 0.35, 0.22)
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(16 if heavy else 8, 0), 0.05)
	t.tween_property(rig, "position", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if not _busy:
		var h := create_tween()
		h.tween_property(bones["head"], "rotation", -0.12 if heavy else -0.06, 0.06)
		h.tween_property(bones["head"], "rotation", 0.0, 0.3)


func break_part(part_id: String) -> void:
	var pos := part_global(part_id)
	Fx.ring(get_parent(), pos, Color(1.0, 0.9, 0.6, 1.0), 240.0, 0.55, 10.0)
	Fx.burst(get_parent(), pos, Color(0.8, 0.72, 1.0), 46, 560.0, 14.0, 0.9, 700.0)
	_flash(1.0, 0.4)
	for s in part_sprites.get(part_id, []):
		if s.has_meta("shard_center"):
			_fly_shard(s)
		elif s.has_meta("broken_tex"):
			s.texture = load(s.get_meta("broken_tex"))
	if part_id == "carapace" and _wound != null:
		_wound.visible = true
		_wound.modulate = Color(3, 3, 3)
		var t := create_tween()
		t.tween_property(_wound, "modulate", Color.WHITE, 0.5)
	await get_tree().create_timer(0.1).timeout


## Un éclat de carapace se détache : il part en tournoyant, retombe et s'efface.
func _fly_shard(s: Sprite2D) -> void:
	var c: Vector2 = s.get_meta("shard_center")
	var away := (c - Vector2(-40, 60)).normalized()
	var dest := s.position + away * randf_range(140, 260) + Vector2(randf_range(-40, 40), -randf_range(60, 140))
	var t := create_tween()
	t.tween_property(s, "position", dest, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(s, "rotation", randf_range(-2.5, 2.5), 0.8)
	t.tween_property(s, "position", dest + Vector2(randf_range(-30, 30), 260), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(s, "modulate:a", 0.0, 0.5)
	t.tween_callback(func(): s.visible = false)


func die() -> void:
	_dead = true
	_telegraph = false
	_busy = true
	var t := create_tween()
	t.tween_property(bones["head"], "rotation", -0.35, 0.6)
	t.parallel().tween_property(bones["jaw"], "rotation", -0.3, 0.6)
	t.parallel().tween_property(rig, "rotation_degrees", 7.0, 0.8).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(rig, "position", Vector2(30, 50), 1.0)
	t.parallel().tween_property(rig, "modulate", Color(0.3, 0.3, 0.4, 0.0), 1.3)
	t.parallel().tween_property(_gland_glow, "modulate:a", 0.0, 0.4)
