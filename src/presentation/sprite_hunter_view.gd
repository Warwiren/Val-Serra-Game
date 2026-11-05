extends "res://src/presentation/hunter_view.gd"
## Aren en sprites pixel art (AnimatedSprite2D). Même interface que HunterView : la scène de combat,
## le CombatCore, la chronologie, les modes et le ciblage ne changent pas.
## Images : art/sprites/aren/ (cadre commun 140×84, ancrage aux pieds en (44,80)), affichées ×3 sans flou.

const DIR := "res://art/sprites/aren/"
const PIXEL_SCALE := 3
const ANCHOR := Vector2(44, 80)

var spr: AnimatedSprite2D
var fx_spr: AnimatedSprite2D
var _guarding := false


func setup(id: String, hunter_def: Dictionary, feet: Vector2, _scale_factor := 0.8) -> void:
	actor_id = id
	def = hunter_def
	sprite_scale = 0.8
	home = feet
	position = feet.round()
	rig = Node2D.new()
	add_child(rig)
	_aura = Fx.glow_sprite(Color(0.4, 0.9, 1.0, 0.0), 300.0)
	_aura.position = Vector2(0, -100)
	rig.add_child(_aura)

	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add(frames, "idle", ["idle_0", "idle_1", "idle_2", "idle_3"], 4.0, true)
	_add(frames, "guard", ["guard_0", "guard_1", "guard_2", "guard_3"], 4.0, true)
	_add(frames, "windup", ["pose_garde"], 1.0, false)
	_add(frames, "dash", ["pose_avance"], 1.0, false)
	_add(frames, "strike", ["pose_attaque"], 1.0, false)
	_add(frames, "hurt", ["pose_touche"], 1.0, false)
	_add(frames, "walk", ["pose_avance", "pose_repos"], 6.0, true)
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = frames
	spr.centered = false
	spr.offset = -ANCHOR
	spr.scale = Vector2.ONE * PIXEL_SCALE
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://src/presentation/rim_light.gdshader")
	mat.set_shader_parameter("strength", 0.0)       # pas de liseré : le pixel art a déjà son contour
	spr.material = mat
	rig.add_child(spr)
	spr.play("idle")

	var fxf := SpriteFrames.new()
	fxf.remove_animation("default")
	_add(fxf, "slash", ["fx_slash_0", "fx_slash_1", "fx_slash_2", "fx_slash_3"], 16.0, false)
	_add(fxf, "guard", ["fx_guard_0", "fx_guard_1", "fx_guard_2"], 10.0, false)
	fx_spr = AnimatedSprite2D.new()
	fx_spr.sprite_frames = fxf
	fx_spr.scale = Vector2.ONE * PIXEL_SCALE
	fx_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx_spr.material = add
	fx_spr.visible = false
	fx_spr.z_index = 5
	rig.add_child(fx_spr)
	fx_spr.animation_finished.connect(func(): fx_spr.visible = false)


func _add(frames: SpriteFrames, anim: String, files: Array, fps: float, loop: bool) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	for f in files:
		var tex: Texture2D = load(DIR + f + ".png")
		frames.add_frame(anim, tex)


func _process(delta: float) -> void:
	_t += delta
	rig.position = rig.position.round()       # pas de position sous-pixel : le pixel art reste net
	queue_redraw()


func _draw() -> void:
	# Ombre sous le centre du corps (l'ancrage est au talon arrière) et anneau du personnage actif
	draw_set_transform(Vector2(22, 0), 0.0, Vector2(1.0, 0.26))
	draw_circle(Vector2.ZERO, 58, Color(0, 0, 0, 0.38))
	if _active:
		draw_arc(Vector2.ZERO, 74, 0, TAU, 48, Color(Art.C_GOLD, 0.6 + 0.4 * sin(_t * 5.0)), 5.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func center() -> Vector2:
	return global_position + Vector2(0, -105)


func hand_global() -> Vector2:
	return global_position + Vector2(80, -110)


func _flash(color: Color, amount: float, duration: float) -> void:
	var m: ShaderMaterial = spr.material
	m.set_shader_parameter("flash_color", color)
	m.set_shader_parameter("flash", amount)
	var t := create_tween()
	t.tween_method(func(v: float): m.set_shader_parameter("flash", v), amount, 0.0, duration)


func _back_to_rest() -> void:
	spr.play("guard" if _guarding else "idle")


# --- Interface HunterView ------------------------------------------------------------------------

func prepare(mode: String, is_serum := false) -> void:
	var col := Color(0.4, 0.9, 1.0) if is_serum else (Color(1.0, 0.75, 0.35) if mode == "CHARGE" else Color(1, 1, 1))
	var strength := 0.75 if (mode == "CHARGE" or is_serum) else (0.3 if mode == "MESURE" else 0.0)
	_aura.modulate = Color(col, 0.0)
	create_tween().tween_property(_aura, "modulate:a", strength, 0.25)
	spr.play("windup")


## Attaque : armé (garde) -> élan -> frappe (+ arc de taille séparé) -> maintien -> repos.
func attack(target_global: Vector2, heavy: bool) -> void:
	_guarding = false
	spr.play("windup")
	await get_tree().create_timer(0.14 if not heavy else 0.22).timeout
	spr.play("dash")
	var reach := clampf(target_global.x - global_position.x - 260.0, 40.0, 330.0)
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(reach, 0), 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await t.finished
	spr.play("strike")
	fx_spr.position = Vector2(150, -95)
	fx_spr.visible = true
	fx_spr.play("slash")
	release_aura()
	await get_tree().create_timer(0.05).timeout
	var back := create_tween()
	back.tween_interval(0.28)
	back.tween_callback(func(): spr.play("dash"))
	back.tween_property(rig, "position", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	back.tween_callback(_back_to_rest)


func cast_serum() -> void:
	spr.play("windup")
	await get_tree().create_timer(0.3).timeout
	spr.play("strike")
	var p := hand_global()
	Fx.ring(get_parent(), p, Color(0.5, 0.95, 1.0, 0.95), 160.0, 0.45, 6.0)
	Fx.burst(get_parent(), p, Color(0.45, 0.9, 1.0), 30, 240.0, 8.0, 0.6, -40.0)
	_flash(Color(0.6, 0.95, 1.0), 0.5, 0.3)
	release_aura()
	await get_tree().create_timer(0.25).timeout
	_back_to_rest()


func use_item() -> void:
	spr.play("windup")
	await get_tree().create_timer(0.3).timeout
	_back_to_rest()


func hurt(heavy: bool) -> void:
	spr.play("hurt")
	_flash(Color(1.0, 1.0, 1.0), 0.9, 0.25)
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(-24 if heavy else -12, 0), 0.06)
	t.tween_property(rig, "position", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(_back_to_rest)


func heal_flash() -> void:
	Fx.burst(get_parent(), center(), Color(0.5, 1.0, 0.55), 20, 150.0, 8.0, 0.8, -120.0)
	_flash(Color(0.6, 1.0, 0.6), 0.5, 0.5)


func set_guard(on: bool) -> void:
	_guarding = on            # pas de bulle vectorielle : le glyphe pixel art la remplace
	if on:
		spr.play("guard")
		fx_spr.position = Vector2(95, -105)
		fx_spr.visible = true
		fx_spr.play("guard")
	else:
		spr.play("idle")


func guard_flash() -> void:
	Fx.burst(get_parent(), center() + Vector2(70, 0), Color(0.8, 0.98, 1.0), 16, 200.0, 7.0, 0.4, 0.0)
	fx_spr.position = Vector2(95, -105)
	fx_spr.visible = true
	fx_spr.play("guard")
	_guarding = false
	set_guard(false)


func knock_out() -> void:
	_ko = true
	_active = false
	release_aura()
	spr.play("hurt")
	var t := create_tween()
	t.tween_property(spr, "modulate", Color(0.45, 0.45, 0.55, 0.9), 0.5)


func walk(moving: bool, dir_x: float, _delta: float) -> void:
	if absf(dir_x) > 0.05:
		scale.x = signf(dir_x)
	var want := "walk" if moving else "idle"
	if spr.animation != want:
		spr.play(want)
