extends "res://src/presentation/hunter_view.gd"
## Personnage du prototype recentré (Aren, Ilya, Throné, PNJ) : sprites issus du pack visuel, une seule passe
## graphique pour tous. Affichage ×3 au plus proche voisin, positions alignées sur la grille de pixels.
## Même interface que HunterView : utilisable en exploration ET dans la scène de combat existante.

const DIR := "res://art/proto/"
const PX := 3

var key: String = "aren"
var spr: AnimatedSprite2D
var fx_spr: AnimatedSprite2D
var _guarding := false
var _walk_phase := 0.0
var _height := 111.0


func setup(id: String, hunter_def: Dictionary, feet: Vector2, _scale_factor := 0.8) -> void:
	actor_id = id
	def = hunter_def
	key = def.get("sprite", "aren")
	sprite_scale = 0.8
	home = feet
	position = feet.round()
	rig = Node2D.new()
	add_child(rig)
	_aura = Fx.glow_sprite(Color(0.4, 0.9, 1.0, 0.0), 200.0)
	_aura.position = Vector2(0, -60)
	rig.add_child(_aura)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 2.5)
	frames.set_animation_loop("idle", true)
	var t0: Texture2D = load(DIR + key + ".png")
	frames.add_frame("idle", t0)
	frames.add_frame("idle", load(DIR + key + "_1.png"))
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = frames
	spr.centered = false
	spr.offset = Vector2(-t0.get_width() / 2, -t0.get_height())
	spr.scale = Vector2.ONE * PX
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://src/presentation/rim_light.gdshader")
	mat.set_shader_parameter("strength", 0.0)
	spr.material = mat
	rig.add_child(spr)
	spr.play("idle")
	spr.frame = int(hash(id)) % 2
	_height = t0.get_height() * PX
	var fxf := SpriteFrames.new()
	fxf.remove_animation("default")
	for anim in [["slash", 4, 18.0], ["guard", 3, 10.0]]:
		fxf.add_animation(anim[0])
		fxf.set_animation_speed(anim[0], anim[2])
		fxf.set_animation_loop(anim[0], false)
		for i in range(anim[1]):
			fxf.add_frame(anim[0], load("res://art/sprites/aren/fx_%s_%d.png" % [anim[0], i]))
	fx_spr = AnimatedSprite2D.new()
	fx_spr.sprite_frames = fxf
	fx_spr.scale = Vector2.ONE * 2
	fx_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx_spr.material = add
	fx_spr.visible = false
	fx_spr.z_index = 5
	rig.add_child(fx_spr)
	fx_spr.animation_finished.connect(func(): fx_spr.visible = false)


func _process(delta: float) -> void:
	_t += delta
	rig.position = (rig.position / PX).round() * PX          # jamais de demi-pixel
	queue_redraw()


func _draw() -> void:
	# Ombre au sol en pixels (ellipse pleine, sans flou) et anneau du personnage actif
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, spr.sprite_frames.get_frame_texture("idle", 0).get_width() * 1.5 + 6, Color(0.02, 0.03, 0.05, 0.45))
	if _active:
		draw_arc(Vector2.ZERO, spr.sprite_frames.get_frame_texture("idle", 0).get_width() * 1.5 + 18, 0, TAU, 40, Color(Art.C_GOLD, 0.55 + 0.35 * sin(_t * 5.0)), 4.0, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func center() -> Vector2:
	return global_position + Vector2(0, -_height * 0.5)


func hand_global() -> Vector2:
	return global_position + Vector2(18 * scale.x, -_height * 0.5)


func _flash(color: Color, amount: float, duration: float) -> void:
	var m: ShaderMaterial = spr.material
	m.set_shader_parameter("flash_color", color)
	m.set_shader_parameter("flash", amount)
	create_tween().tween_method(func(v: float): m.set_shader_parameter("flash", v), amount, 0.0, duration)


# --- Exploration ---------------------------------------------------------------------------------

func walk(moving: bool, dir_x: float, delta: float) -> void:
	if absf(dir_x) > 0.05:
		scale.x = signf(dir_x)
	if moving:
		_walk_phase += delta * 10.0
		spr.position.y = -PX * float(int(absf(sin(_walk_phase)) * 2.0))   # sautillé de 0 à 2 pixels natifs
	else:
		_walk_phase = 0.0
		spr.position.y = 0.0


# --- Combat (interface HunterView) ------------------------------------------------------------------

func prepare(mode: String, is_serum := false) -> void:
	var strength := 0.6 if (mode == "CHARGE" or is_serum) else 0.0
	_aura.modulate = Color(Color(1.0, 0.8, 0.45) if mode == "CHARGE" else Color(0.5, 0.9, 1.0), 0.0)
	create_tween().tween_property(_aura, "modulate:a", strength, 0.25)
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(-PX * 3, 0), 0.15)


func attack(target_global: Vector2, heavy: bool) -> void:
	_guarding = false
	var dist := absf(target_global.x - global_position.x)
	var reach := clampf(dist - 230.0, 30.0, 360.0)
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(-PX * 4, 0), 0.1)
	t.tween_property(rig, "position", Vector2(reach, -PX * 2), 0.16 if not heavy else 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await t.finished
	fx_spr.position = Vector2(40, -_height * 0.55)
	fx_spr.visible = true
	fx_spr.play("slash")
	_flash(Color(1, 1, 1), 0.35, 0.15)
	release_aura()
	var back := create_tween()
	back.tween_interval(0.22)
	back.tween_property(rig, "position", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func cast_serum() -> void:
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(0, -PX * 4), 0.15)
	await t.finished
	Fx.ring(get_parent(), center(), Color(0.5, 0.95, 1.0, 0.9), 120.0, 0.4, 5.0)
	release_aura()
	create_tween().tween_property(rig, "position", Vector2.ZERO, 0.2)


func use_item() -> void:
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(0, -PX * 3), 0.12)
	t.tween_property(rig, "position", Vector2.ZERO, 0.15)
	await t.finished


func hurt(heavy: bool) -> void:
	_flash(Color(1, 1, 1), 0.9, 0.25)
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(-PX * (8 if heavy else 4), 0), 0.06)
	t.tween_property(rig, "position", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_QUAD)


func heal_flash() -> void:
	Fx.burst(get_parent(), center(), Color(0.5, 1.0, 0.55), 16, 120.0, 6.0, 0.7, -100.0)
	_flash(Color(0.6, 1.0, 0.6), 0.5, 0.5)


func set_guard(on: bool) -> void:
	_guarding = on
	if on:
		fx_spr.position = Vector2(34, -_height * 0.5)
		fx_spr.visible = true
		fx_spr.play("guard")


func guard_flash() -> void:
	fx_spr.position = Vector2(34, -_height * 0.5)
	fx_spr.visible = true
	fx_spr.play("guard")
	_guarding = false


func knock_out() -> void:
	_ko = true
	_active = false
	release_aura()
	var t := create_tween()
	t.tween_property(spr, "modulate", Color(0.4, 0.4, 0.5, 0.85), 0.5)
	spr.pause()
