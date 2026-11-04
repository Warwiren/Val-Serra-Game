extends Node2D
## Atelier d'animation (prototype artistique) : déclencher à volonté les animations du Chasseur articulé
## et du Vorgane, afficher le squelette, tester la capacité d'Aether et les ruptures. Aucune règle de jeu.

const Art = preload("res://src/presentation/art.gd")
const Fx = preload("res://src/presentation/fx.gd")
const Stage = preload("res://src/presentation/stage.gd")
const RigHunterView = preload("res://src/presentation/rig_hunter_view.gd")
const RigMonsterView = preload("res://src/presentation/rig_monster_view.gd")

var stage: Stage
var hero: RigHunterView
var monster: RigMonsterView
var fx: Node2D
var cam: Camera2D
var bones_overlay: Node2D
var show_bones := false
var _t := 0.0
var _shake := 0.0
var _zoom_off := Vector2.ZERO
var _label: Label


func _ready() -> void:
	stage = Stage.new()
	stage.layer_defs = Stage.HD_LAYERS
	stage.front_def = Stage.HD_FRONT
	stage.rays_path = Stage.HD_RAYS
	stage.ambient = Color(0.62, 0.66, 0.84)
	stage.mist_color = Color(0.5, 0.64, 0.9, 0.12)
	stage.fog_color = Color(0.13, 0.19, 0.32)
	stage.light_points = [
		{"pos": Vector2(190, 270), "color": Color(1.0, 0.72, 0.38), "energy": 1.2, "size": 2.6},
		{"pos": Vector2(400, 410), "color": Color(1.0, 0.75, 0.42), "energy": 1.0, "size": 2.0},
		{"pos": Vector2(1000, 420), "color": Color(1.0, 0.75, 0.42), "energy": 1.0, "size": 2.0},
		{"pos": Vector2(690, 210), "color": Color(0.7, 0.8, 1.0), "energy": 0.6, "size": 6.0},
		{"pos": Vector2(170, 560), "color": Color(0.45, 0.95, 1.0), "energy": 0.9, "size": 1.6},
		{"pos": Vector2(1250, 560), "color": Color(0.45, 0.95, 1.0), "energy": 0.9, "size": 1.6},
		{"pos": Vector2(420, 430), "color": Color(0.85, 0.9, 1.0), "energy": 0.35, "size": 4.0},
	]
	add_child(stage)
	var actors := Node2D.new()
	add_child(actors)
	stage.build(self)
	var overlay := CanvasLayer.new()
	overlay.layer = 1
	overlay.follow_viewport_enabled = true
	add_child(overlay)
	fx = Node2D.new()
	overlay.add_child(fx)

	monster = RigMonsterView.new()
	actors.add_child(monster)
	monster.setup(Vector2(990, 560), 0.8, null)
	monster.markers.visible = false
	hero = RigHunterView.new()
	actors.add_child(hero)
	hero.setup("heros", Art.hunter("heros", GameState.hero_gender), Vector2(400, 590), 0.95)
	hero.z_index = 10

	bones_overlay = Node2D.new()
	bones_overlay.draw.connect(_draw_bones)
	overlay.add_child(bones_overlay)

	cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)
	cam.make_current()
	_build_ui()
	stage.set_mode("B")
	if GameState.autoplay:
		_demo()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var title := Label.new()
	title.text = "Atelier d'animation — prototype artistique (Skeleton2D + AnimationPlayer)"
	title.position = Vector2(16, 10)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 6)
	layer.add_child(title)
	_label = Label.new()
	_label.position = Vector2(16, 40)
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color("#9ff0ff"))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 5)
	layer.add_child(_label)
	var hero_box := _box(layer, Vector2(16, 76), "Chasseur")
	for e in [["Repos", "idle"], ["Frappe", "strike"], ["Garde", "guard"], ["Impact", "hurt"], ["Marche", "walk"], ["K.O.", "ko"]]:
		_btn(hero_box, e[0], _hero_anim.bind(e[1]))
	_btn(hero_box, "✦ Capacité d'Aether", _aether)
	var mon_box := _box(layer, Vector2(1080, 76), "Vorgane")
	_btn(mon_box, "Coup de griffe", func(): monster.lunge(hero.center()))
	_btn(mon_box, "Annonce (Souffle)", func(): monster.set_telegraph(true))
	_btn(mon_box, "Souffle d'Aether", func(): monster.breath([hero.center()]))
	_btn(mon_box, "Briser la carapace", _break.bind("carapace"))
	_btn(mon_box, "Briser la griffe", _break.bind("griffe"))
	_btn(mon_box, "Briser la glande", _break.bind("glande"))
	_btn(mon_box, "Réinitialiser", func(): GameState.goto("res://scenes/art/rig_viewer.tscn", 0.2))
	var misc := _box(layer, Vector2(16, 560), "Affichage")
	_btn(misc, "Afficher / masquer le squelette", func(): show_bones = not show_bones)
	_btn(misc, "Retour au menu", func(): GameState.goto(GameState.SCENE_HERO_SELECT))


func _box(layer: CanvasLayer, pos: Vector2, title: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.position = pos
	v.add_theme_constant_override("separation", 4)
	layer.add_child(v)
	var l := Label.new()
	l.text = title
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color("#ffd27a"))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 5)
	v.add_child(l)
	return v


func _btn(parent: Node, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(190, 30)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)


func _process(delta: float) -> void:
	_t += delta
	_shake = maxf(0.0, _shake - delta * 40.0)
	var drift := Vector2(sin(_t * 0.23) * 14.0, sin(_t * 0.17) * 5.0)
	cam.offset = drift + _zoom_off + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	stage.update_parallax(drift + _zoom_off, delta)
	_label.text = "Animation du Chasseur : %s   ·   %d os, %d calques" % [hero.player.current_animation, hero.bones.size(), hero.materials.size()]
	bones_overlay.queue_redraw()


func _draw_bones() -> void:
	if not show_bones:
		return
	for view in [hero, monster]:
		for b in view.bones.values():
			var p: Vector2 = b.global_position
			var parent = b.get_parent()
			if parent is Bone2D:
				bones_overlay.draw_line(parent.global_position, p, Color(1, 0.85, 0.3, 0.9), 3.0, true)
			bones_overlay.draw_circle(p, 6.0, Color(1, 0.4, 0.3, 0.95))


func _hero_anim(anim: String) -> void:
	match anim:
		"strike":
			hero.attack(monster.part_global("griffe"), false)
		"guard":
			hero.set_guard(true)
		"hurt":
			hero.hurt(true)
		"ko":
			hero.knock_out()
		"walk":
			hero.walk(true, 1.0, 0.0)
		_:
			hero.set_guard(false)
			hero.walk(false, 0.0, 0.0)
			hero.player.play("idle", 0.2)


func _break(part: String) -> void:
	if not monster.part_info.has(part):
		monster.part_info[part] = {"name": part, "integrity": 0, "max": 1, "broken": true}
	monster.part_info[part]["broken"] = true
	monster.break_part(part)
	_shake = 12.0
	_punch(monster.part_global(part))
	_flash_light(monster.part_global(part), Color(1.0, 0.9, 0.7))


## Capacité d'Aether complète : charge en spirale, lancer, projectile, impact, lumière, caméra.
func _aether() -> void:
	hero.prepare("", true)
	await get_tree().create_timer(0.7).timeout
	await hero.cast_serum()
	var from := hero.hand_global()
	var to := monster.part_global("glande")
	var orb := Fx.glow_sprite(Color(0.55, 0.97, 1.0, 1.0), 110.0)
	orb.position = from
	fx.add_child(orb)
	var trail := CPUParticles2D.new()
	trail.amount = 60
	trail.lifetime = 0.35
	trail.local_coords = false
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_max = 30.0
	trail.scale_amount_min = 0.2
	trail.scale_amount_max = 0.45
	trail.texture = Fx.glow_texture(64, true)
	trail.color = Color(0.5, 0.95, 1.0, 0.8)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	trail.material = mat
	orb.add_child(trail)
	var mid := (from + to) / 2.0 + Vector2(0, -160)
	var t := create_tween()
	t.tween_method(func(k: float): orb.position = from.lerp(mid, k).lerp(mid.lerp(to, k), k), 0.0, 1.0, 0.45).set_ease(Tween.EASE_IN)
	await t.finished
	orb.queue_free()
	Fx.ring(fx, to, Color(0.5, 0.95, 1.0), 180.0, 0.5, 9.0)
	Fx.ring(fx, to, Color(0.85, 1.0, 1.0), 300.0, 0.75, 4.0)
	Fx.burst(fx, to, Color(0.5, 0.95, 1.0), 50, 560.0, 11.0, 0.8, 0.0)
	_flash_light(to, Color(0.5, 0.95, 1.0))
	monster.hurt("glande", true)
	Fx.float_text(fx, to + Vector2(0, -70), "42", Color("#fff2c8"), 46)
	Fx.float_text(fx, to + Vector2(10, -24), "FAIBLESSE !", Color("#ffb347"), 26)
	_shake = 9.0
	_punch(to)


func _punch(point: Vector2) -> void:
	var t := create_tween()
	t.tween_property(cam, "zoom", Vector2.ONE * 1.1, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "_zoom_off", (point - cam.position) * 0.35, 0.25)
	t.tween_interval(0.25)
	t.tween_property(cam, "zoom", Vector2.ONE, 0.45).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(self, "_zoom_off", Vector2.ZERO, 0.45)


func _flash_light(pos: Vector2, color: Color) -> void:
	var l := PointLight2D.new()
	l.texture = Fx.glow_texture(256)
	l.position = pos
	l.color = color
	l.energy = 3.0
	l.texture_scale = 5.0
	add_child(l)
	var t := create_tween()
	t.tween_property(l, "energy", 0.0, 0.6)
	t.tween_callback(l.queue_free)


## Démonstration automatique (vidéo) : enchaîne toutes les animations.
func _demo() -> void:
	var seq := [
		[1.5, func(): show_bones = true],
		[2.5, func(): show_bones = false],
		[0.5, _hero_anim.bind("strike")],
		[1.6, _hero_anim.bind("guard")],
		[1.4, _hero_anim.bind("idle")],
		[0.8, func(): monster.lunge(hero.center())],
		[0.6, _hero_anim.bind("hurt")],
		[1.6, _aether],
		[3.2, func(): monster.set_telegraph(true)],
		[1.6, func(): monster.breath([hero.center()])],
		[1.6, _break.bind("carapace")],
		[2.0, _break.bind("griffe")],
		[1.6, _break.bind("glande")],
		[1.8, _hero_anim.bind("walk")],
		[1.6, _hero_anim.bind("idle")],
		[1.2, _hero_anim.bind("strike")],
		[2.0, _hero_anim.bind("ko")],
	]
	for step in seq:
		await get_tree().create_timer(step[0]).timeout
		step[1].call()
