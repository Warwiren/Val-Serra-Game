extends "res://src/presentation/hunter_view.gd"
## Chasseur articulé (prototype artistique) : Skeleton2D + Bone2D + AnimationPlayer.
## Construit entièrement à partir de deux fichiers de données :
##  - data/rig/<personnage>.json : calques, os, pivots (fiche de découpe de l'illustration) ;
##  - data/rig/anim_<famille d'arme>.json : animations partagées par tous les porteurs de cette arme.
## Même interface que HunterView : la scène de combat l'utilise sans changement.

const RIM_SHADER = preload("res://src/presentation/rim_light.gdshader")

var skeleton: Skeleton2D
var player: AnimationPlayer
var bones: Dictionary = {}           # nom -> Bone2D
var materials: Array = []            # ShaderMaterial des calques (flash, liseré)
var rig_def: Dictionary = {}
var anims: Dictionary = {}
var _feet := Vector2.ZERO
var _guarding := false
var _walking := false


func setup(id: String, hunter_def: Dictionary, feet: Vector2, scale_factor := 0.68) -> void:
	actor_id = id
	def = hunter_def
	sprite_scale = scale_factor
	home = feet
	position = feet
	rig_def = _load_json(def.get("rig", "res://data/rig/hero_hd.json"))
	anims = _load_json(def.get("anims", "res://data/rig/anim_sword.json"))
	_feet = Vector2(rig_def["feet"][0], rig_def["feet"][1])
	var canvas := Vector2(rig_def["canvas"][0], rig_def["canvas"][1])

	rig = Node2D.new()
	rig.scale = Vector2.ONE * sprite_scale
	add_child(rig)
	_aura = Fx.glow_sprite(Color(0.4, 0.9, 1.0, 0.0), 420.0)
	_aura.position = Vector2(0, -200)
	rig.add_child(_aura)

	skeleton = Skeleton2D.new()
	rig.add_child(skeleton)
	var pivots := {}
	for b in rig_def["bones"]:
		var bone := Bone2D.new()
		bone.name = b["name"]
		var pv := Vector2(b["pivot"][0], b["pivot"][1])
		pivots[b["name"]] = pv
		var parent_name: String = b["parent"]
		if parent_name == "":
			bone.position = pv - _feet
			skeleton.add_child(bone)
		else:
			bone.position = pv - pivots[parent_name]
			bones[parent_name].add_child(bone)
		bone.set_autocalculate_length_and_angle(false)
		bone.set_length(1.0)
		bone.rest = bone.transform
		bones[b["name"]] = bone

	var z := 0
	for part in rig_def["parts"]:
		var s := Sprite2D.new()
		s.texture = load("%s/%s.svg" % [rig_def["art_dir"], part["file"]])
		s.offset = canvas / 2.0 - pivots[part["bone"]]
		s.z_index = z
		var mat := ShaderMaterial.new()
		mat.shader = RIM_SHADER
		s.material = mat
		materials.append(mat)
		bones[part["bone"]].add_child(s)
		z += 1

	player = AnimationPlayer.new()
	skeleton.add_child(player)
	var lib := AnimationLibrary.new()
	for anim_name in anims:
		if String(anim_name).begins_with("_"):
			continue
		lib.add_animation(anim_name, _build_animation(anims[anim_name]))
	player.add_animation_library("", lib)
	player.animation_finished.connect(_on_anim_finished)
	player.play("idle")
	player.seek(fmod(float(hash(id) % 100) / 40.0, 2.4), true)
	weapon_pivot = bones["weapon"]


static func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(f.get_as_text())


## Construit une Animation Godot à partir des clés en degrés / pixels.
func _build_animation(a: Dictionary) -> Animation:
	var anim := Animation.new()
	anim.length = float(a["length"])
	anim.loop_mode = Animation.LOOP_LINEAR if a.get("loop", false) else Animation.LOOP_NONE
	var tracks: Dictionary = a["tracks"]
	for bone_name in bones:
		if bone_name == "hip":
			continue
		var t := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(t, NodePath("%s:rotation" % skeleton.get_path_to(bones[bone_name])))
		anim.track_set_interpolation_type(t, Animation.INTERPOLATION_CUBIC)
		var keys: Array = tracks.get(bone_name, [[0, 0], [anim.length, 0]])
		for k in keys:
			anim.track_insert_key(t, float(k[0]), deg_to_rad(float(k[1])))
	# Bassin : position (hip_x, hip_y) combinées
	var hx: Array = tracks.get("hip_x", [[0, 0]])
	var hy: Array = tracks.get("hip_y", [[0, 0]])
	var times := {}
	for k in hx + hy:
		times[float(k[0])] = true
	if not times.has(anim.length):
		times[anim.length] = true
	var t2 := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t2, NodePath("%s:position" % skeleton.get_path_to(bones["hip"])))
	anim.track_set_interpolation_type(t2, Animation.INTERPOLATION_CUBIC)
	var rest: Vector2 = bones["hip"].position
	var sorted_times := times.keys()
	sorted_times.sort()
	for tm in sorted_times:
		anim.track_insert_key(t2, tm, rest + Vector2(_sample(hx, tm), _sample(hy, tm)))
	return anim


static func _sample(keys: Array, tm: float) -> float:
	if keys.size() == 1:
		return float(keys[0][1])
	for i in range(keys.size() - 1):
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if tm <= float(b[0]):
			var span := maxf(0.0001, float(b[0]) - float(a[0]))
			return lerpf(float(a[1]), float(b[1]), clampf((tm - float(a[0])) / span, 0.0, 1.0))
	return float(keys[-1][1])


func _on_anim_finished(anim_name: StringName) -> void:
	if anims.get(String(anim_name), {}).get("hold", false):
		return
	player.play("walk" if _walking else "idle", 0.15)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func center() -> Vector2:
	return global_position + Vector2(10, -200) * sprite_scale


func hand_global() -> Vector2:
	return bones["weapon"].global_position


func _flash(color: Color, amount: float, duration: float) -> void:
	for m in materials:
		m.set_shader_parameter("flash_color", color)
		m.set_shader_parameter("flash", amount)
	var t := create_tween()
	t.tween_method(_set_flash, amount, 0.0, duration)


func _set_flash(v: float) -> void:
	for m in materials:
		m.set_shader_parameter("flash", v)


# --- Interface HunterView ------------------------------------------------------

func prepare(mode: String, is_serum := false) -> void:
	var col := Color(0.4, 0.9, 1.0) if is_serum else (Color(1.0, 0.75, 0.35) if mode == "CHARGE" else Color(1, 1, 1))
	var strength := 0.8 if (mode == "CHARGE" or is_serum) else (0.35 if mode == "MESURE" else 0.0)
	_aura.modulate = Color(col, 0.0)
	var t := create_tween()
	t.tween_property(_aura, "modulate:a", strength, 0.25)
	if is_serum:
		_charge_particles()


func attack(target_global: Vector2, heavy: bool) -> void:
	var speed := 0.85 if heavy else 1.0
	player.play("strike", 0.05, speed)
	var dir := target_global - global_position
	var reach := clampf(dir.length() - 360.0, 60.0, 320.0)
	var t := create_tween()
	t.tween_interval(0.12 / speed)
	t.tween_property(rig, "position", Vector2(reach, -6), 0.22 / speed).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(float(anims["strike"]["impact"]) / speed).timeout
	release_aura()
	Fx.slash(get_parent(), target_global + Vector2(-20, -10), 120.0 if heavy else 95.0,
		Color(1.0, 0.82, 0.45) if not heavy else Color(1.0, 0.65, 0.3))
	var back := create_tween()
	back.tween_interval(0.25)
	back.tween_property(rig, "position", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func cast_serum() -> void:
	player.play("cast", 0.05)
	await get_tree().create_timer(float(anims["cast"]["impact"])).timeout
	var p := hand_global()
	Fx.ring(get_parent(), p, Color(0.5, 0.95, 1.0, 0.95), 170.0, 0.45, 8.0)
	Fx.burst(get_parent(), p, Color(0.45, 0.9, 1.0), 34, 260.0, 10.0, 0.6, -40.0)
	_flash(Color(0.6, 0.95, 1.0), 0.6, 0.35)
	release_aura()


func use_item() -> void:
	player.play("cast", 0.05, 1.6)
	await get_tree().create_timer(0.3).timeout


func hurt(heavy: bool) -> void:
	player.play("hurt", 0.03, 1.0 if heavy else 1.3)
	_flash(Color(1.0, 0.45, 0.4), 0.85, 0.3)
	if _guarding:
		_guarding = false


func heal_flash() -> void:
	Fx.burst(get_parent(), center(), Color(0.5, 1.0, 0.55), 22, 160.0, 9.0, 0.8, -120.0)
	_flash(Color(0.6, 1.0, 0.6), 0.6, 0.5)


func set_guard(on: bool) -> void:
	super.set_guard(on)
	_guarding = on
	if on:
		player.play("guard", 0.08)
	elif player.current_animation == "guard" or player.assigned_animation == "guard":
		player.play("idle", 0.2)


func knock_out() -> void:
	_ko = true
	_active = false
	release_aura()
	player.play("ko", 0.1)
	var t := create_tween()
	t.tween_property(rig, "modulate", Color(0.5, 0.5, 0.6, 0.9), 0.6)


func walk(moving: bool, dir_x: float, _delta: float) -> void:
	if absf(dir_x) > 0.05:
		scale.x = signf(dir_x)
	if moving != _walking:
		_walking = moving
		player.play("walk" if moving else "idle", 0.15)


## Spirale de particules d'Aether autour de la main pendant la préparation du sérum.
func _charge_particles() -> void:
	var p := CPUParticles2D.new()
	p.amount = 40
	p.lifetime = 0.7
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	p.emission_sphere_radius = 65.0
	p.gravity = Vector2.ZERO
	p.radial_accel_min = -220.0
	p.radial_accel_max = -160.0
	p.tangential_accel_min = 160.0
	p.tangential_accel_max = 220.0
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.3
	p.texture = Fx.glow_texture(64, true)
	p.color = Color(0.5, 0.95, 1.0, 0.95)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	p.position = hand_global() - global_position
	p.z_index = 40
	add_child(p)
	await get_tree().create_timer(1.4).timeout
	p.emitting = false
	await get_tree().create_timer(0.8).timeout
	p.queue_free()
