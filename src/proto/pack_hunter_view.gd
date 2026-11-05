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
var poses := false                   # Aren en combat : vraies poses (art/proto/aren_combat, tools/art/aren_poses.py)
const POSE_DIR := "res://art/proto/aren_combat/"
const STEP := PX * 14                # pas vers l'avant pendant la frappe (aucune traversée du groupe)
var vfx := true                      # false : poses seules, sans effets (contrôle des animations)


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
	poses = def.get("combat", false) and ResourceLoader.exists(POSE_DIR + key + "_idle.png")
	var fr0: Texture2D = t0
	if poses:
		fr0 = load(POSE_DIR + key + "_idle.png")
		frames.add_frame("idle", fr0)
		frames.add_frame("idle", load(POSE_DIR + key + "_idle_1.png"))
		for pz in ["prep", "strike", "follow", "guard", "hurt", "aether_prep", "aether_strike"]:
			frames.add_animation(pz)
			frames.set_animation_loop(pz, false)
			frames.add_frame(pz, load(POSE_DIR + key + "_" + pz + ".png"))
	else:
		frames.add_frame("idle", t0)
		frames.add_frame("idle", load(DIR + key + "_1.png"))
		if ResourceLoader.exists(DIR + key + "_walk_0.png"):
			frames.add_animation("walk")
			frames.set_animation_speed("walk", 0.0)          # image pilotée par la distance parcourue
			for i in range(4):
				frames.add_frame("walk", load(DIR + key + "_walk_%d.png" % i))
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = frames
	spr.centered = false
	spr.offset = Vector2(-fr0.get_width() / 2, -fr0.get_height())
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
	var sw := 22.0 if poses else float(spr.sprite_frames.get_frame_texture("idle", 0).get_width())
	draw_circle(Vector2(rig.position.x, 0), sw * 1.5 + 6, Color(0.02, 0.03, 0.05, 0.45))   # l'ombre suit le pas
	if _active:
		draw_arc(Vector2.ZERO, sw * 1.5 + 18, 0, TAU, 40, Color(Art.C_GOLD, 0.55 + 0.35 * sin(_t * 5.0)), 4.0, false)
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

const STRIDE := 18.0                 # px parcourus par image de marche (cadence liée à la vitesse réelle)
var _walk_dist := 0.0
var _last_pos := Vector2.INF


## Marche d'exploration : vraies images de marche (tools/art/walk_cycles.py), pilotées par la distance
## RÉELLEMENT parcourue depuis l'image précédente ; arrêt -> repos (respiration).
func walk(moving: bool, dir_x: float, _delta: float) -> void:
	if absf(dir_x) > 0.05:
		scale.x = signf(dir_x)
	var d := 0.0 if _last_pos == Vector2.INF else global_position.distance_to(_last_pos)
	_last_pos = global_position
	if not spr.sprite_frames.has_animation("walk"):
		return
	if moving and d > 0.01:
		_walk_dist += d
		_set_anim("walk")
		spr.frame = int(_walk_dist / STRIDE) % 4
	elif String(spr.animation) == "walk":
		_walk_dist = 0.0
		_set_anim("idle")
		spr.play("idle")


## Change d'animation en gardant les pieds au même point (les canevas n'ont pas tous la même taille).
func _set_anim(name: String) -> void:
	if String(spr.animation) == name:
		return
	var tex: Texture2D = spr.sprite_frames.get_frame_texture(name, 0)
	spr.animation = name
	spr.offset = Vector2(-tex.get_width() / 2, -tex.get_height())
	if name == "walk":
		spr.pause()


# --- Combat (interface HunterView) ------------------------------------------------------------------

func _pose(name: String) -> void:
	if poses and spr.sprite_frames.has_animation(name):
		spr.play(name)


func _rest() -> void:
	if _ko:
		return
	if poses:
		spr.play("guard" if _guarding else "idle")


func prepare(mode: String, is_serum := false) -> void:
	var strength := 0.6 if (mode == "CHARGE" or is_serum) else 0.0
	_aura.modulate = Color(Color(1.0, 0.8, 0.45) if mode == "CHARGE" else Color(0.5, 0.9, 1.0), 0.0)
	create_tween().tween_property(_aura, "modulate:a", strength, 0.25)
	_pose("aether_prep" if is_serum else "prep")          # anticipation lisible (technique : lame chargée en arrière)
	if is_serum:
		_blade_charge(true)
	create_tween().tween_property(rig, "position", Vector2(-PX * 2, 0), 0.15)


## Frappe : préparation -> pas en avant -> FRAPPE (contact) -> impact/suivi -> retour. L'effet est posé SUR la
## cible, sur la couche d'effets ; le personnage ne quitte pas son couloir (pas de traversée des compagnons).
func attack(target_global: Vector2, heavy: bool) -> void:
	_guarding = false
	_pose("prep")
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(-PX * 3, 0), 0.1)
	t.tween_property(rig, "position", Vector2(STEP, 0), 0.12 if not heavy else 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await t.finished
	_pose("strike")
	if vfx:
		Fx.slash(get_parent(), target_global, 90.0 if heavy else 70.0, Color(1.0, 0.92, 0.75))
	if not poses:
		fx_spr.position = Vector2(40, -_height * 0.55)
		fx_spr.visible = true
		fx_spr.play("slash")
	if vfx:
		_flash(Color(1, 1, 1), 0.25, 0.1)
	release_aura()
	await get_tree().create_timer(0.07).timeout
	_pose("follow")
	var back := create_tween()
	back.tween_interval(0.2)
	back.tween_callback(_rest)
	back.tween_property(rig, "position", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Lueur d'Aether LIMITÉE à la lame (petite, sans halo sur le corps) pendant la préparation de la technique.
var _blade_glow: Sprite2D

func _blade_charge(on: bool) -> void:
	if _blade_glow == null:
		_blade_glow = Fx.glow_sprite(Color(0.33, 0.85, 0.9, 0.0), 46.0)
		_blade_glow.z_index = 3
		rig.add_child(_blade_glow)
	_blade_glow.position = Vector2(-PX * 9, -PX * 10)      # le long de la lame tenue en arrière (pose aether_prep)
	create_tween().tween_property(_blade_glow, "modulate:a", 0.55 if (on and vfx) else 0.0, 0.35 if on else 0.12)


## Technique de Résonance (Pulsation d'Aether) : garde basse chargée -> estocade -> trait d'Aether net jusqu'à la
## partie visée -> impact. Une seule trajectoire, pas de pluie de particules ; renvoie au moment de l'impact.
func resonance_strike(target_global: Vector2) -> void:
	_guarding = false
	_pose("aether_prep")
	_blade_charge(true)
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(-PX * 4, PX), 0.22).set_trans(Tween.TRANS_SINE)
	await t.finished
	var t2 := create_tween()
	t2.tween_property(rig, "position", Vector2(STEP, 0), 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await t2.finished
	_pose("aether_strike")
	_blade_charge(false)
	release_aura()
	# Trait d'Aether : de la pointe de la lame (pose aether_strike) jusqu'à la cible
	var tip := global_position + Vector2(scale.x * (PX * 26 + STEP), -_height * 0.5)
	if not vfx:
		var b0 := create_tween()
		b0.tween_interval(0.35)
		b0.tween_callback(_rest)
		b0.tween_property(rig, "position", Vector2.ZERO, 0.3)
		return
	var beam := Line2D.new()
	beam.points = PackedVector2Array([tip, target_global])
	beam.width = 6.0
	beam.default_color = Color(0.85, 1.0, 1.0, 0.95)
	beam.z_index = 46
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	beam.material = add
	get_parent().add_child(beam)
	var core := Line2D.new()
	core.points = beam.points
	core.width = 2.0
	core.default_color = Color(0.33, 0.85, 0.9, 1.0)
	core.z_index = 47
	get_parent().add_child(core)
	var fade := create_tween()
	fade.tween_property(beam, "width", 0.0, 0.2).set_ease(Tween.EASE_IN)
	fade.parallel().tween_property(core, "modulate:a", 0.0, 0.2)
	fade.tween_callback(beam.queue_free)
	fade.tween_callback(core.queue_free)
	Fx.ring(get_parent(), target_global, Color(0.6, 0.95, 1.0, 0.9), 80.0, 0.3, 4.0)
	var back := create_tween()
	back.tween_interval(0.35)
	back.tween_callback(_rest)
	back.tween_property(rig, "position", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func cast_serum() -> void:
	_pose("prep")
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(0, -PX * 4), 0.15)
	await t.finished
	_pose("strike")
	Fx.ring(get_parent(), center(), Color(0.5, 0.95, 1.0, 0.9), 120.0, 0.4, 5.0)
	release_aura()
	var b := create_tween()
	b.tween_property(rig, "position", Vector2.ZERO, 0.2)
	b.tween_callback(_rest)


func use_item() -> void:
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(0, -PX * 3), 0.12)
	t.tween_property(rig, "position", Vector2.ZERO, 0.15)
	await t.finished


func hurt(heavy: bool) -> void:
	if vfx:
		_flash(Color(1, 1, 1), 0.6, 0.15)
	_pose("hurt")
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(-PX * (6 if heavy else 3), 0), 0.06)
	t.tween_interval(0.18)
	t.tween_callback(_rest)
	t.tween_property(rig, "position", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_QUAD)


func heal_flash() -> void:
	Fx.burst(get_parent(), center(), Color(0.5, 1.0, 0.55), 16, 120.0, 6.0, 0.7, -100.0)
	_flash(Color(0.6, 1.0, 0.6), 0.5, 0.5)


func set_guard(on: bool) -> void:
	_guarding = on
	if on:
		_pose("guard")
		if not poses:
			fx_spr.position = Vector2(34, -_height * 0.5)
			fx_spr.visible = true
			fx_spr.play("guard")
	else:
		_rest()


func guard_flash() -> void:
	fx_spr.position = Vector2(34, -_height * 0.5)
	fx_spr.visible = true
	fx_spr.play("guard")
	_guarding = false
	var t := create_tween()
	t.tween_interval(0.35)
	t.tween_callback(_rest)


func knock_out() -> void:
	_ko = true
	_active = false
	release_aura()
	if poses:
		spr.play("hurt")
	var t := create_tween()
	t.tween_property(spr, "modulate", Color(0.4, 0.4, 0.5, 0.85), 0.5)
	spr.pause()
