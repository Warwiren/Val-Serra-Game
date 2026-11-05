extends "res://src/presentation/monster_view.gd"
## Vorgane en sprites (solution B : animé dans Blender, rendu puis converti en pixel art).
## Calques synchronisés : corps + carapace + griffe + glande. États par partie, pilotés par le CombatCore :
##   intact   -> calque normal
##   endommagé (intégrité < 50 %) -> calque assombri / fissuré (traitement de couleur)
##   brisé    -> calque « broken » (carapace arasée, serres brisées) ou glande éteinte
## Marqueurs de ciblage et lueur de la glande suivent l'animation (ancrages image par image).

const DIR := "res://art/sprites/vorgane/"
const PIXEL_SCALE := 3
const ANIMS := {
	"idle": {"frames": [1, 7, 13, 19, 25, 31, 37, 43], "fps": 8.0, "loop": true},
	"claw": {"frames": [1, 4, 7, 10, 12, 14, 16, 18, 21, 24, 27, 30], "fps": 16.0, "loop": false},
	"hit": {"frames": [1, 3, 5, 7, 10, 14, 18], "fps": 16.0, "loop": false},
	"walk": {"frames": [1, 5, 9, 13, 17, 21, 25, 29], "fps": 10.0, "loop": true},
}
const CLAW_IMPACT_INDEX := 5
const LAYER_PARTS := {"carapace": "carapace", "griffe": "griffe", "glande": "glande"}

var layers: Dictionary = {}          # nom -> AnimatedSprite2D
var frames_cache: Dictionary = {}    # nom de calque -> SpriteFrames
var anchors: Dictionary = {}
var origin := Vector2.ZERO           # pieds dans l'image native
var _busy := false
var _damage_mat: Dictionary = {}


func setup(feet: Vector2, _scale_factor := 0.9, overlay: Node = null) -> void:
	position = feet.round()
	scale = Vector2.ONE
	rig = Node2D.new()
	add_child(rig)
	anchors = JSON.parse_string(FileAccess.open(DIR + "anchors.json", FileAccess.READ).get_as_text())["images"]
	var ref: Image = load(DIR + "base/idle_001.png").get_image()
	var used := ref.get_used_rect()
	origin = Vector2(used.position.x + used.size.x * 0.5, used.end.y)
	for lname in ["base", "carapace", "griffe", "glande"]:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = _frames(lname)
		s.centered = false
		s.offset = -origin
		s.scale = Vector2.ONE * PIXEL_SCALE
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.light_mask = 0          # pas de lumières ponctuelles : l'éclairage est déjà « peint » dans le rendu Blender
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://src/presentation/part_state.gdshader")
		s.material = mat
		_damage_mat[lname] = mat
		rig.add_child(s)
		layers[lname] = s
	body = null
	for pid in ["griffe", "carapace", "glande"]:
		parts[pid] = {"sprite": layers[pid], "intact": "", "broken": "", "anchor": Vector2.ZERO}
	_gland_glow = Fx.glow_sprite(Color(0.4, 0.95, 1.0, 0.0), 160.0)
	_gland_glow.z_index = 20
	rig.add_child(_gland_glow)
	markers = Node2D.new()
	markers.z_index = 30
	markers.draw.connect(_draw_markers)
	if overlay != null:
		overlay.add_child(markers)
	else:
		rig.add_child(markers)
	layers["base"].animation_finished.connect(_on_finished)
	_play("idle")


func _frames(lname: String) -> SpriteFrames:
	if frames_cache.has(lname):
		return frames_cache[lname]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for a in ANIMS:
		sf.add_animation(a)
		sf.set_animation_speed(a, ANIMS[a]["fps"])
		sf.set_animation_loop(a, ANIMS[a]["loop"])
		for f in ANIMS[a]["frames"]:
			sf.add_frame(a, load("%s%s/%s_%03d.png" % [DIR, lname, a, f]))
	frames_cache[lname] = sf
	return sf


func _play(anim: String, from_frame := 0) -> void:
	for l in layers.values():
		l.play(anim)
		l.frame = from_frame


func _on_finished() -> void:
	if not _dead:
		_play("idle")


func _frame_key() -> String:
	var b: AnimatedSprite2D = layers["base"]
	return "%s_%03d" % [b.animation, ANIMS[String(b.animation)]["frames"][b.frame]]


func _process(delta: float) -> void:
	_t += delta
	var b: AnimatedSprite2D = layers["base"]
	for l in layers.values():                    # synchronisation stricte des calques
		if l != b and (l.animation != b.animation or l.frame != b.frame):
			l.animation = b.animation
			l.frame = b.frame
	rig.position = rig.position.round()
	var key := _frame_key()
	if anchors.has(key):
		var a: Dictionary = anchors[key]
		for pid in ["griffe", "carapace", "glande"]:
			parts[pid]["anchor"] = (Vector2(a[pid][0], a[pid][1]) - origin) * PIXEL_SCALE
		_gland_glow.position = parts["glande"]["anchor"]
	# États des parties
	for pid in LAYER_PARTS:
		var info: Dictionary = part_info.get(pid, {})
		var broken: bool = info.get("broken", false)
		var damaged: bool = not broken and info.has("max") and float(info.get("integrity", 1)) / maxf(1.0, float(info["max"])) < 0.5
		var mat: ShaderMaterial = _damage_mat[pid]
		mat.set_shader_parameter("damaged", 1.0 if damaged else 0.0)
		mat.set_shader_parameter("dead", 1.0 if (broken and pid == "glande") else 0.0)
		mat.set_shader_parameter("time", _t)
	if markers.get_parent() != rig:
		markers.global_transform = rig.global_transform
		markers.visible = not _dead
	var gland_broken: bool = part_info.get("glande", {}).get("broken", false)
	_gland_glow.modulate.a = (0.0 if gland_broken else 0.45) + ((0.5 + 0.45 * sin(_t * 9.0)) if _telegraph and not gland_broken else 0.0)
	_gland_glow.scale = Vector2.ONE * ((2.6 if _telegraph else 1.7) + 0.2 * sin(_t * 4.0))
	markers.queue_redraw()


func mouth_global() -> Vector2:
	var key := _frame_key()
	if anchors.has(key):
		var a: Array = anchors[key]["gueule"]
		return rig.to_global((Vector2(a[0], a[1]) - origin) * PIXEL_SCALE)
	return center()


func center() -> Vector2:
	return rig.to_global(Vector2(-40, -150))


func set_telegraph(on: bool) -> void:
	_telegraph = on
	if on:
		_play("claw", 0)
		layers["base"].pause()
		for l in layers.values():
			l.frame = 2
		Fx.ring(get_parent(), part_global("glande"), Color(1.0, 0.45, 0.4, 0.9), 180.0, 0.6, 6.0)
	elif not _busy:
		_play("idle")


func prepare() -> void:
	_play("claw", 0)
	layers["base"].pause()
	for l in layers.values():
		l.frame = 3


## Coup de griffe : animation Blender + bond vers la cible ; renvoie au moment de l'impact.
func lunge(target_global: Vector2) -> void:
	_busy = true
	_play("claw", 3)
	var dx := clampf(target_global.x - global_position.x + 360.0, -280.0, -40.0)
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(dx, 0), 0.14).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(float(CLAW_IMPACT_INDEX - 3) / ANIMS["claw"]["fps"]).timeout
	Fx.slash(get_parent(), target_global + Vector2(30, 0), 100.0, Color(0.75, 0.6, 1.0))
	var back := create_tween()
	back.tween_interval(0.25)
	back.tween_property(rig, "position", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_QUAD)
	back.tween_callback(func(): _busy = false)


func breath(targets: Array) -> void:
	_telegraph = false
	_busy = true
	_play("claw", 1)
	layers["base"].pause()
	await get_tree().create_timer(0.2).timeout
	var from := mouth_global()
	for tg in targets:
		var p := CPUParticles2D.new()
		p.position = from
		p.z_index = 40
		p.amount = 60
		p.lifetime = 0.5
		p.one_shot = true
		p.explosiveness = 0.25
		p.direction = (tg - from).normalized()
		p.spread = 12.0
		p.gravity = Vector2.ZERO
		p.initial_velocity_min = (tg - from).length() * 1.5
		p.initial_velocity_max = (tg - from).length() * 2.1
		p.scale_amount_min = 0.25
		p.scale_amount_max = 0.6
		p.texture = Fx.glow_texture(64, true)
		p.color = Color(0.45, 0.95, 1.0, 0.95)
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = mat
		get_parent().add_child(p)
		p.emitting = true
		get_tree().create_timer(1.2).timeout.connect(p.queue_free)
	await get_tree().create_timer(0.35).timeout
	_busy = false
	_play("idle")


func hurt(_part_id: String, heavy: bool) -> void:
	if not _busy:
		_play("hit")
	for m in _damage_mat.values():
		m.set_shader_parameter("flash", 0.8 if heavy else 0.5)
	var t := create_tween()
	t.tween_method(_set_flash_all, 0.8 if heavy else 0.5, 0.0, 0.22)
	var s := create_tween()
	s.tween_property(rig, "position", Vector2(14 if heavy else 7, 0), 0.05)
	s.tween_property(rig, "position", Vector2.ZERO, 0.2)


## Rupture : le CombatCore a signalé la rupture -> permutation vers le calque « brisé » + effets.
func break_part(part_id: String) -> void:
	var pos := part_global(part_id)
	Fx.ring(get_parent(), pos, Color(1.0, 0.9, 0.6, 1.0), 220.0, 0.55, 9.0)
	Fx.burst(get_parent(), pos, Color(0.78, 0.7, 1.0), 44, 520.0, 12.0, 0.9, 700.0)
	if part_id in ["carapace", "griffe"]:
		var l: AnimatedSprite2D = layers[part_id]
		var anim := l.animation
		var fr := l.frame
		l.sprite_frames = _frames(part_id + "_broken")
		l.animation = anim
		l.frame = fr
	for m in _damage_mat.values():
		m.set_shader_parameter("flash", 1.0)
	var t := create_tween()
	t.tween_method(_set_flash_all, 1.0, 0.0, 0.4)
	await get_tree().create_timer(0.1).timeout


func _set_flash_all(v: float) -> void:
	for m in _damage_mat.values():
		m.set_shader_parameter("flash", v)


func die() -> void:
	_dead = true
	_telegraph = false
	_play("hit")
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(20, 30), 1.0)
	t.parallel().tween_property(rig, "modulate", Color(0.3, 0.3, 0.4, 0.0), 1.3)
	t.parallel().tween_property(_gland_glow, "modulate:a", 0.0, 0.4)
