extends Node2D
## Prototype recentré — zone d'exploration (scène de lancement).
## Aren + 2 compagnons qui suivent, 1 PNJ (dialogue court), 1 monstre qui lance le combat au contact.
## Un seul langage visuel : décor et personnages issus du pack, même grille de pixels (×3).

const Fx = preload("res://src/presentation/fx.gd")
const Hero = preload("res://src/proto/pack_hunter_view.gd")
const Monster = preload("res://src/presentation/sprite_monster_view.gd")
const DialogueBox = preload("res://src/proto/dialogue_box.gd")

const PX := 3
const WALK_MIN := Vector2(60, 462)
const WALK_MAX := Vector2(1225, 560)
const SPEED := 210.0
const SPAWN := Vector2(700, 520)
const FOLLOW_GAP := 80.0                 # écart de file : les silhouettes (66 à 111 px de large) ne se chevauchent pas
const NPC_POS := Vector2(1110, 478)
const MONSTER_POS := Vector2(255, 548)
const TALK_RANGE := 120.0
const ENGAGE_RANGE := 170.0
const DIALOGUE := "res://data/dialogue/pnj_proto.json"

var actors: Node2D
var overlay: Node2D
var hero: Hero
var companions: Array = []
var npc: Hero
var monster: Monster
var cam: Camera2D
var _trail: Array = []
var _prompt: PanelContainer
var _prompt_label: Label
var _dialog
var _locked := false
var _engaging := false
var _t := 0.0
var _auto_target := Vector2.INF


func _ready() -> void:
	GameState.proto = true
	_build_world()
	_build_ui()
	_on_arrival()
	if GameState.autoplay:
		_autoplay()


# ---------------------------------------------------------------------------
# Construction
# ---------------------------------------------------------------------------

func _build_world() -> void:
	var bg := Sprite2D.new()
	bg.texture = load("res://art/proto/zone_bg.png")
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.centered = false
	bg.scale = Vector2.ONE * PX
	bg.z_index = -100
	add_child(bg)
	var cm := CanvasModulate.new()
	cm.color = Color(0.9, 0.88, 0.97)
	add_child(cm)
	# Sources lumineuses peintes dans le décor (lanternes, fenêtres) : halo chaud qui respire
	for lp in [[Vector2(60, 212), 1.4], [Vector2(683, 282), 1.6], [Vector2(951, 266), 1.6], [Vector2(1068, 262), 1.3], [Vector2(1250, 262), 1.0]]:
		var l := PointLight2D.new()
		l.texture = Fx.glow_texture(256)
		l.position = lp[0]
		l.color = Color(1.0, 0.72, 0.38)
		l.energy = 0.55
		l.texture_scale = lp[1]
		l.set_meta("base", 0.55)
		add_child(l)
	_add_fireflies()

	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	var layer := CanvasLayer.new()
	layer.layer = 1
	layer.follow_viewport_enabled = true
	add_child(layer)
	overlay = Node2D.new()
	layer.add_child(overlay)

	hero = Hero.new(); actors.add_child(hero)
	hero.setup("heros", {"sprite": "aren"}, SPAWN)
	for i in range(2):
		var c := Hero.new(); actors.add_child(c)
		c.setup(["compagnon_vif", "compagnon_lourd"][i], {"sprite": ["ilya", "throne"][i]}, SPAWN - Vector2(FOLLOW_GAP * (i + 1), -6 * i))
		companions.append(c)
	npc = Hero.new(); actors.add_child(npc)
	npc.setup("pnj", {"sprite": "pnj"}, NPC_POS)
	npc.scale.x = -1
	monster = Monster.new()
	monster.sprite_dir = "res://art/proto/vorgane_nuit_p1/"
	monster.facing_right = true
	monster.scene_lights = [Vector2(60, 212), Vector2(683, 282), Vector2(951, 266), Vector2(1068, 262)]   # lanternes du décor
	actors.add_child(monster)
	monster.setup(MONSTER_POS, 1.0, null)
	monster.visible = not GameState.enemy_defeated

	cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)
	cam.make_current()


func _add_fireflies() -> void:
	var p := CPUParticles2D.new()
	p.amount = 28
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(620, 140)
	p.position = Vector2(640, 400)
	p.direction = Vector2(0.2, -1)
	p.spread = 60.0
	p.gravity = Vector2(0, -4)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 12.0
	p.scale_amount_min = 0.05
	p.scale_amount_max = 0.1
	p.texture = Fx.glow_texture(64, true)
	p.color = Color(1.0, 0.9, 0.45, 0.9)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.add_point(0.5, Color(1, 1, 1, 1))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	p.material = mat
	p.z_index = 50
	add_child(p)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	# Vignettage léger (bords assombris, regard au centre)
	var vig := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0)); g.add_point(0.62, Color(0, 0, 0, 0)); g.set_color(g.get_point_count() - 1, Color(0.02, 0.02, 0.06, 0.55))
	var gt := GradientTexture2D.new()
	gt.gradient = g; gt.fill = GradientTexture2D.FILL_RADIAL; gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(1.05, 0.5)
	gt.width = 256; gt.height = 144
	vig.texture = gt
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(vig)

	_prompt = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.11, 0.85)
	sb.border_color = Color(0.85, 0.7, 0.42, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10; sb.content_margin_right = 10; sb.content_margin_top = 4; sb.content_margin_bottom = 4
	_prompt.add_theme_stylebox_override("panel", sb)
	_prompt_label = Label.new()
	_prompt_label.add_theme_font_size_override("font_size", 16)
	_prompt_label.add_theme_color_override("font_color", Color("#f3e3c0"))
	_prompt.add_child(_prompt_label)
	_prompt.visible = false
	overlay.add_child(_prompt)

	# Dialogue narratif : deux portraits, locuteur, réponses au choix (src/proto/dialogue_box.gd)
	_dialog = DialogueBox.new()
	layer.add_child(_dialog)
	_dialog.closed.connect(func(): _locked = false)
	_title(layer, "Avant-poste de la lisière")


func _title(layer: CanvasLayer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.position = Vector2(0, 40)
	l.size = Vector2(1280, 40)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", Color("#f3e3c0"))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
	l.add_theme_constant_override("outline_size", 8)
	l.modulate.a = 0.0
	layer.add_child(l)
	var t := create_tween()
	t.tween_property(l, "modulate:a", 1.0, 0.8)
	t.tween_interval(1.6)
	t.tween_property(l, "modulate:a", 0.0, 0.8)
	t.tween_callback(l.queue_free)


func _on_arrival() -> void:
	if GameState.from_zone and GameState.last_battle_result != "":
		var pos := GameState.zone_return_pos if GameState.last_battle_result == "victory" else SPAWN
		hero.position = pos
		for i in range(companions.size()):
			companions[i].position = pos - Vector2(FOLLOW_GAP * (i + 1), -6 * i)
		GameState.from_zone = false
		GameState.last_battle_result = ""


# ---------------------------------------------------------------------------
# Boucle
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	for l in get_children():
		if l is PointLight2D:
			l.energy = float(l.get_meta("base")) * (0.9 + 0.1 * sin(_t * 2.3 + l.position.x))
	var dir := Vector2.ZERO
	if not _locked:
		if _auto_target != Vector2.INF:
			var to := _auto_target - hero.position
			if to.length() > 4.0:
				dir = to.normalized()
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
		step.y *= 0.6
		if _auto_target != Vector2.INF:
			step = step.limit_length((_auto_target - hero.position).length())
		var next := (hero.position + step).clamp(WALK_MIN, WALK_MAX)
		if next.distance_to(NPC_POS) < 40.0:
			next = hero.position
		hero.position = next
		if _trail.is_empty() or _trail[-1].distance_to(hero.position) > 3.0:
			_trail.append(hero.position)
			if _trail.size() > 120:
				_trail.pop_front()
	hero.walk(moving, dir.x, delta)
	_follow(delta)
	_update_prompt()
	if monster.visible and not _engaging and hero.position.distance_to(MONSTER_POS + Vector2(150, 0)) < ENGAGE_RANGE * 0.62:
		_engage()


## Compagnons : chacun suit la trace du précédent avec un retard fixe (file indienne).
func _follow(delta: float) -> void:
	for i in range(companions.size()):
		var c: Hero = companions[i]
		var lag := int(FOLLOW_GAP / 3.0) * (i + 1)          # la trace est échantillonnée tous les 3 px
		var target: Vector2 = c.position
		if _trail.size() > lag:
			target = _trail[_trail.size() - lag]
		var to := target - c.position
		var leader: Node2D = hero if i == 0 else companions[i - 1]
		var moving := to.length() > 3.0 and c.position.distance_to(leader.position) > FOLLOW_GAP * 0.9
		if moving:
			c.position += to.normalized() * minf(SPEED * 1.1 * delta, to.length())
		c.walk(moving, to.x if moving else 0.0, delta)


func _update_prompt() -> void:
	if _locked:
		_prompt.visible = false
		return
	var p := hero.position
	if p.distance_to(NPC_POS) < TALK_RANGE:
		_show_prompt("E  Parler", NPC_POS + Vector2(0, -130))
	elif monster.visible and p.distance_to(MONSTER_POS + Vector2(150, 0)) < ENGAGE_RANGE * 1.6:
		_show_prompt("!  Vorgane des brumes", MONSTER_POS + Vector2(0, -200))
	else:
		_prompt.visible = false


func _show_prompt(text: String, pos: Vector2) -> void:
	_prompt_label.text = text
	_prompt.visible = true
	_prompt.reset_size()
	_prompt.position = (pos - Vector2(_prompt.size.x / 2, 0)).round()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _dialog.is_open():
		_dialog.handle_key(event)                  # E / Échap / ↑↓ consommés par le dialogue (pas de double action)
		get_viewport().set_input_as_handled()
		return
	if _locked:
		return
	if (event.physical_keycode == KEY_E or event.keycode == KEY_ENTER) and hero.position.distance_to(NPC_POS) < TALK_RANGE:
		_open_dialog()


# ---------------------------------------------------------------------------
# Dialogue et combat
# ---------------------------------------------------------------------------

func _open_dialog() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.open(DIALOGUE, FileAccess.READ).get_as_text())
	var steps: Array = data["after_victory"] if GameState.enemy_defeated else data["start"]
	var spk: Dictionary = data["speakers"].duplicate(true)
	spk["heros"]["name"] = GameState.hero_name
	_locked = true
	hero.walk(false, 1.0, 0.0)
	_dialog.open(steps, spk)


func _engage() -> void:
	_engaging = true
	_locked = true
	_prompt.visible = false
	Fx.float_text(overlay, MONSTER_POS + Vector2(40, -190), "!", Color("#ff7a6a"), 48, 24.0, 0.7)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var l := CanvasLayer.new(); l.layer = 50; add_child(l); l.add_child(flash)
	var t := create_tween()
	t.tween_property(cam, "zoom", Vector2(1.15, 1.15), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(cam, "position", (hero.position + MONSTER_POS) / 2.0 + Vector2(0, -60), 0.5)
	t.tween_property(flash, "color:a", 0.85, 0.12)
	t.tween_property(flash, "color:a", 0.0, 0.2)
	await t.finished
	GameState.from_zone = true
	GameState.proto = true
	GameState.zone_return_pos = hero.position
	GameState.goto(GameState.SCENE_PROTO_BATTLE, 0.35)


# ---------------------------------------------------------------------------
# Démonstration automatique (vidéo)
# ---------------------------------------------------------------------------

func _autoplay() -> void:
	await get_tree().create_timer(1.5).timeout
	if OS.get_cmdline_user_args().has("--demo-walk"):
		# Démonstration de marche (vidéo de contrôle) : départ, arrêt, demi-tour, la file suit et s'arrête
		for wp in [Vector2(1000, 520), Vector2(560, 545), Vector2(860, 500), Vector2(1040, 530), Vector2(700, 520)]:
			await _walk_to(wp)
			await get_tree().create_timer(1.2).timeout
		await get_tree().create_timer(1.5).timeout
		get_tree().quit()
		return
	if GameState.enemy_defeated:
		await _walk_to(NPC_POS + Vector2(-90, 10))
		_open_dialog()
		while _dialog.is_open():
			await get_tree().create_timer(1.6).timeout
			_dialog.advance()
		return
	await _walk_to(Vector2(940, 520))
	await _walk_to(NPC_POS + Vector2(-90, 10))
	_open_dialog()
	while _dialog.is_open():
		await get_tree().create_timer(1.7 if not _dialog.showing_choice() else 1.2).timeout
		_dialog.advance()                          # réponse au choix : la première option est validée
	await get_tree().create_timer(0.6).timeout
	await _walk_to(Vector2(700, 535))
	await _walk_to(MONSTER_POS + Vector2(200, -10))


func _walk_to(target: Vector2) -> void:
	_auto_target = target
	while _auto_target != Vector2.INF and not _engaging:
		await get_tree().process_frame
