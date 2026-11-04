extends Node2D
## Micro-zone d'exploration : avant-poste à la lisière de la forêt.
## Héros contrôlable + 1 compagnon suiveur, 1 PNJ à dialogue, 1 ennemi visible qui déclenche le combat.

const Art = preload("res://src/presentation/art.gd")
const Fx = preload("res://src/presentation/fx.gd")
const Stage = preload("res://src/presentation/stage.gd")
const HunterView = preload("res://src/presentation/hunter_view.gd")
const MonsterView = preload("res://src/presentation/monster_view.gd")
const DialogueBox = preload("res://src/explore/dialogue_box.gd")

const WALK_MIN := Vector2(40, 548)
const WALK_MAX := Vector2(1240, 700)
const SPEED := 270.0
const CHAR_SCALE := 0.46
const NPC_POS := Vector2(330, 578)
const ENEMY_HOME := Vector2(1090, 606)
const SPAWN := Vector2(620, 640)
const TALK_RANGE := 110.0
const ENGAGE_PROMPT := 230.0
const ENGAGE_AUTO := 105.0

var stage: Stage
var actors: Node2D
var overlay: Node2D
var player: HunterView
var companion: HunterView
var npc: Node2D
var npc_sprite: Sprite2D
var enemy: MonsterView
var cam: Camera2D

var _trail: Array = []
var _prompt: Label
var _hud_info: RichTextLabel
var _render_btn: Button
var _banner: Label
var _dialogue: DialogueBox
var _locked := false
var _engaging := false
var _t := 0.0
var _auto_target: Vector2 = Vector2.INF


func _ready() -> void:
	_build_world()
	_build_hud()
	GameState.render_mode_changed.connect(_on_render_mode)
	_on_render_mode(GameState.render_mode)
	_on_arrival()
	if GameState.autoplay:
		_autoplay()


# ---------------------------------------------------------------------------
# Construction
# ---------------------------------------------------------------------------

func _build_world() -> void:
	stage = Stage.new()
	stage.extra_props = [
		{"path": "res://art/zone/fence.svg", "pos": Vector2(610, 512), "scale": 0.8},
		{"path": "res://art/zone/fence.svg", "pos": Vector2(840, 516), "scale": 0.8},
		{"path": "res://art/zone/house.svg", "pos": Vector2(220, 532), "scale": 0.86},
		{"path": "res://art/zone/workbench.svg", "pos": Vector2(470, 530), "scale": 0.75},
		{"path": "res://art/zone/crates.svg", "pos": Vector2(700, 530), "scale": 0.8},
		{"path": "res://art/zone/lantern.svg", "pos": Vector2(560, 534), "scale": 0.85},
		{"path": "res://art/zone/lantern.svg", "pos": Vector2(930, 536), "scale": 0.85},
	]
	stage.light_points = [
		{"pos": Vector2(577, 386), "color": Color(1.0, 0.72, 0.4), "energy": 1.4, "size": 2.2},
		{"pos": Vector2(947, 388), "color": Color(1.0, 0.72, 0.4), "energy": 1.4, "size": 2.2},
		{"pos": Vector2(220, 450), "color": Color(1.0, 0.78, 0.45), "energy": 0.45, "size": 2.2},
		{"pos": Vector2(136, 312), "color": Color(1.0, 0.72, 0.4), "energy": 1.0, "size": 2.0},
		{"pos": Vector2(1090, 540), "color": Color(0.4, 0.9, 1.0), "energy": 0.9, "size": 2.4},
		{"pos": Vector2(640, 620), "color": Color(1.0, 0.9, 0.75), "energy": 0.22, "size": 6.0},
	]
	add_child(stage)
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	stage.build(self)

	var layer := CanvasLayer.new()
	layer.layer = 1
	layer.follow_viewport_enabled = true
	add_child(layer)
	overlay = Node2D.new()
	layer.add_child(overlay)

	# PNJ
	npc = Node2D.new()
	npc.position = NPC_POS
	actors.add_child(npc)
	npc_sprite = Sprite2D.new()
	npc_sprite.texture = load("res://art/characters/npc.svg")
	npc_sprite.offset = Vector2(0, -(Art.BODY_FEET.y - Art.BODY_SIZE.y / 2.0))
	npc_sprite.scale = Vector2.ONE * CHAR_SCALE
	npc.add_child(npc_sprite)

	# Ennemi visible
	enemy = MonsterView.new()
	actors.add_child(enemy)
	enemy.setup(ENEMY_HOME, 0.3)
	enemy.visible = not GameState.enemy_defeated

	# Héros et compagnon suiveur
	player = HunterView.new()
	actors.add_child(player)
	player.setup("heros", Art.hunter("heros", GameState.hero_gender), SPAWN, CHAR_SCALE)
	companion = HunterView.new()
	actors.add_child(companion)
	companion.setup("compagnon_vif", Art.hunter("compagnon_vif"), SPAWN - Vector2(70, 0), CHAR_SCALE)

	cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)
	cam.make_current()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var panel := Panel.new()
	panel.position = Vector2(12, 12)
	panel.size = Vector2(380, 92)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.08, 0.78)
	sb.border_color = Art.C_PANEL_EDGE
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	var portrait := TextureRect.new()
	portrait.texture = load(GameState.hero_portrait())
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(6, 6)
	portrait.size = Vector2(80, 80)
	panel.add_child(portrait)
	_hud_info = RichTextLabel.new()
	_hud_info.bbcode_enabled = true
	_hud_info.position = Vector2(92, 6)
	_hud_info.size = Vector2(284, 82)
	_hud_info.add_theme_font_size_override("normal_font_size", 14)
	_hud_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_hud_info)

	_render_btn = Button.new()
	_render_btn.position = Vector2(1080, 14)
	_render_btn.size = Vector2(188, 34)
	_render_btn.focus_mode = Control.FOCUS_NONE
	_render_btn.pressed.connect(func(): GameState.toggle_render_mode())
	root.add_child(_render_btn)

	var hint := Label.new()
	hint.text = "Flèches / ZQSD : se déplacer   ·   E ou Entrée : parler / affronter   ·   F2 : rendu A/B"
	hint.position = Vector2(0, 694)
	hint.size = Vector2(1280, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	hint.add_theme_constant_override("outline_size", 6)
	root.add_child(hint)

	_banner = Label.new()
	_banner.position = Vector2(0, 150)
	_banner.size = Vector2(1280, 60)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 30)
	_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.modulate.a = 0.0
	root.add_child(_banner)

	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.add_theme_color_override("font_color", Color("#ffe2b0"))
	_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_prompt.add_theme_constant_override("outline_size", 7)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.size = Vector2(300, 30)
	_prompt.visible = false
	overlay.add_child(_prompt)

	_dialogue_layer = CanvasLayer.new()
	_dialogue_layer.layer = 20
	add_child(_dialogue_layer)
	_refresh_info()


var _dialogue_layer: CanvasLayer


func _on_render_mode(mode: String) -> void:
	stage.set_mode(mode)
	_render_btn.text = GameState.render_label() + " [F2]"


func _refresh_info() -> void:
	var mats := ""
	for k in GameState.materials:
		mats += "%s ×%d  " % [GameState.material_name(k), int(GameState.materials[k])]
	if mats == "":
		mats = "[color=#8d98a3]aucun matériau[/color]"
	_hud_info.text = "[b]%s[/b]  [color=#8d98a3]· avant-poste de la lisière[/color]\nPotions ×%d   ·   Pièces %d\n[font_size=12]%s[/font_size]" % [
		GameState.hero_name, GameState.potions, GameState.currency, mats]


func banner(text: String, color: Color, hold := 1.6) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	var t := create_tween()
	t.tween_property(_banner, "modulate:a", 1.0, 0.3)
	t.tween_interval(hold)
	t.tween_property(_banner, "modulate:a", 0.0, 0.5)


## Retour depuis un combat (ou première arrivée).
func _on_arrival() -> void:
	if GameState.from_zone and GameState.last_battle_result != "":
		player.position = GameState.zone_return_pos - Vector2(150, 0)
		companion.position = player.position - Vector2(60, 0)
		if GameState.last_battle_result == "victory":
			banner("Le Vorgane est vaincu !  Récompenses ajoutées à l'inventaire.", Color("#ffe08a"), 2.2)
		else:
			player.position = SPAWN
			companion.position = SPAWN - Vector2(70, 0)
			banner("Repli vers l'avant-poste…", Color("#ff9a8a"))
			GameState.flags["lost_once"] = true
		GameState.from_zone = false
	else:
		banner("Avant-poste de la lisière", Color("#ffe2b0"), 1.4)
	_refresh_info()


# ---------------------------------------------------------------------------
# Boucle
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	var drift := Vector2.ZERO
	if GameState.render_mode == GameState.RENDER_25D:
		drift = Vector2(sin(_t * 0.2) * 10.0 + (player.position.x - 640.0) * 0.02, sin(_t * 0.15) * 4.0)
	cam.offset = drift
	stage.update_parallax(drift, delta)
	_update_enemy(delta)
	if _locked:
		player.walk(false, 0.0, delta)
		_follow(delta)
		_update_prompt()
		return
	var dir := Vector2.ZERO
	var max_step := INF
	if _auto_target != Vector2.INF:
		var to := _auto_target - player.position
		if to.length() > 4.0:
			dir = to.normalized()
			max_step = to.length()
		else:
			_auto_target = Vector2.INF
	else:
		if Input.is_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
			dir.x -= 1
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
			dir.x += 1
		if Input.is_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
			dir.y -= 1
		if Input.is_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
			dir.y += 1
	var moving := dir != Vector2.ZERO
	if moving:
		var step := dir.normalized() * SPEED * delta
		if max_step == INF:
			step.y *= 0.7
		else:
			step = step.limit_length(max_step)
		var next := player.position + step
		next = next.clamp(WALK_MIN, WALK_MAX)
		if next.distance_to(NPC_POS) < 46.0:
			next = player.position
		player.position = next
		if _trail.is_empty() or _trail[-1].distance_to(player.position) > 4.0:
			_trail.append(player.position)
			if _trail.size() > 80:
				_trail.pop_front()
	player.walk(moving, dir.x, delta)
	_follow(delta)
	_update_prompt()
	# Le PNJ se tourne vers le héros
	npc_sprite.flip_h = player.position.x < NPC_POS.x
	# Contact avec l'ennemi : combat
	if enemy.visible and not _engaging and player.position.distance_to(enemy.position) < ENGAGE_AUTO:
		_engage()


## Le compagnon suit la trace du héros avec un léger retard.
func _follow(delta: float) -> void:
	var target: Vector2 = companion.position
	if _trail.size() > 18:
		target = _trail[_trail.size() - 18]
	var to := target - companion.position
	var moving := to.length() > 6.0 and companion.position.distance_to(player.position) > 60.0
	if moving:
		companion.position += to.normalized() * minf(SPEED * 1.05 * delta, to.length())
	companion.walk(moving, to.x if moving else 0.0, delta)


func _update_enemy(delta: float) -> void:
	if not enemy.visible:
		return
	# Rôde de gauche à droite autour de sa position
	var x := ENEMY_HOME.x + sin(_t * 0.5) * 70.0
	var dx := x - enemy.position.x
	enemy.position.x = x
	enemy.scale.x = 0.3 * (-1.0 if dx > 0.0 else 1.0)


func _update_prompt() -> void:
	if _locked:
		_prompt.visible = false
		return
	var p := player.position
	if p.distance_to(NPC_POS) < TALK_RANGE:
		_prompt.text = "E : parler"
		_prompt.position = NPC_POS + Vector2(-150, -170)
		_prompt.visible = true
	elif enemy.visible and p.distance_to(enemy.position) < ENGAGE_PROMPT:
		_prompt.text = "⚠  E : affronter le Vorgane"
		_prompt.position = enemy.position + Vector2(-150, -170)
		_prompt.visible = true
	else:
		_prompt.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _locked:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_interact()


func _interact() -> void:
	var p := player.position
	if p.distance_to(NPC_POS) < TALK_RANGE:
		_talk()
	elif enemy.visible and p.distance_to(enemy.position) < ENGAGE_PROMPT:
		_engage()


# ---------------------------------------------------------------------------
# Dialogue et combat
# ---------------------------------------------------------------------------

func _talk() -> void:
	_locked = true
	var start := "intro"
	if GameState.enemy_defeated:
		start = "after_victory"
	elif GameState.flags.get("lost_once", false) and GameState.flags.get("talked", false):
		start = "after_defeat"
	elif GameState.flags.get("talked", false):
		start = "reminder"
	_dialogue = DialogueBox.new()
	_dialogue_layer.add_child(_dialogue)
	_dialogue.open("res://data/dialogue/intendante.json", start)
	await _dialogue.finished
	_dialogue = null
	_refresh_info()
	if GameState.flags.get("gift", false) and not GameState.flags.get("gift_shown", false):
		GameState.flags["gift_shown"] = true
		Fx.float_text(overlay, player.position + Vector2(0, -150), "+1 Potion de soin", Color("#8cff9a"), 24)
	_locked = false


func _engage() -> void:
	if _engaging:
		return
	_engaging = true
	_locked = true
	_prompt.visible = false
	Fx.float_text(overlay, enemy.position + Vector2(0, -150), "!", Color("#ff7a6a"), 54, 30.0, 0.8)
	Fx.ring(overlay, enemy.position + Vector2(0, -50), Color(1, 0.5, 0.4), 260.0, 0.6, 8.0)
	var t := create_tween()
	t.tween_property(cam, "zoom", Vector2(1.25, 1.25), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(cam, "position", (player.position + enemy.position) / 2.0 + Vector2(0, -80), 0.6)
	await t.finished
	GameState.from_zone = true
	GameState.zone_return_pos = player.position
	GameState.goto(GameState.SCENE_BATTLE, 0.45)


# ---------------------------------------------------------------------------
# Démonstration automatique (captures vidéo)
# ---------------------------------------------------------------------------

func _autoplay() -> void:
	await get_tree().create_timer(1.0).timeout
	if GameState.enemy_defeated:
		await _auto_walk(NPC_POS + Vector2(95, 20))
		_auto_talk()
		return
	await _auto_walk(Vector2(760, 660))
	await _auto_walk(NPC_POS + Vector2(95, 20))
	await _auto_talk()
	await _auto_walk(Vector2(860, 640))
	await _auto_walk(enemy.position + Vector2(-140, 10))
	_interact()


func _auto_walk(target: Vector2) -> void:
	_auto_target = target
	while _auto_target != Vector2.INF:
		await get_tree().process_frame


func _auto_talk() -> void:
	_talk()
	await get_tree().create_timer(0.4).timeout
	while _dialogue != null:
		await get_tree().create_timer(1.5).timeout
		if _dialogue != null:
			_dialogue.auto_step()
