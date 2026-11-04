extends Control
## Écran d'accueil : choix de la base du héros (masculine / féminine) et du nom.

const Art = preload("res://src/presentation/art.gd")

var _gender := "m"
var _cards: Dictionary = {}
var _name_edit: LineEdit
var _render_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load("res://art/stage/sky.svg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	for layer in ["far", "mid"]:
		var l := TextureRect.new()
		l.texture = load("res://art/stage/%s.svg" % layer)
		l.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.modulate = Color(0.55, 0.6, 0.7)
		add_child(l)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.06, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var title := Label.new()
	title.text = "Val'Serra — Les Larmes d'Aether"
	title.position = Vector2(0, 34)
	title.size = Vector2(1280, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color("#ffe2b0"))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 10)
	add_child(title)
	var sub := Label.new()
	sub.text = "Prototype MVP — Lot B · Choisissez votre Chasseur ou votre Chasseuse"
	sub.position = Vector2(0, 94)
	sub.size = Vector2(1280, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color("#c6d4e0"))
	add_child(sub)

	_cards["m"] = _card("m", Vector2(330, 150))
	_cards["f"] = _card("f", Vector2(670, 150))

	var name_lbl := Label.new()
	name_lbl.text = "Nom :"
	name_lbl.position = Vector2(440, 572)
	name_lbl.add_theme_font_size_override("font_size", 20)
	add_child(name_lbl)
	_name_edit = LineEdit.new()
	_name_edit.position = Vector2(510, 566)
	_name_edit.size = Vector2(320, 40)
	_name_edit.max_length = 18
	_name_edit.add_theme_font_size_override("font_size", 20)
	add_child(_name_edit)

	var start := Button.new()
	start.text = "Commencer  ▸"
	start.position = Vector2(540, 620)
	start.size = Vector2(200, 50)
	start.add_theme_font_size_override("font_size", 22)
	start.pressed.connect(_start)
	add_child(start)

	var quick := Button.new()
	quick.text = "Combat direct (test)"
	quick.position = Vector2(30, 660)
	quick.size = Vector2(210, 36)
	quick.pressed.connect(_quick_battle)
	add_child(quick)
	var hd := Button.new()
	hd.text = "✦ Prototype artistique HD"
	hd.position = Vector2(780, 616)
	hd.size = Vector2(260, 36)
	hd.add_theme_color_override("font_color", Color("#9ff0ff"))
	hd.pressed.connect(_art_proto)
	add_child(hd)
	var atelier := Button.new()
	atelier.text = "✦ Atelier d'animation"
	atelier.position = Vector2(780, 660)
	atelier.size = Vector2(260, 36)
	atelier.add_theme_color_override("font_color", Color("#9ff0ff"))
	atelier.pressed.connect(_atelier)
	add_child(atelier)
	var dbg := Button.new()
	dbg.text = "Écran de débogage (Lot A)"
	dbg.position = Vector2(250, 660)
	dbg.size = Vector2(230, 36)
	dbg.pressed.connect(func(): GameState.goto(GameState.SCENE_DEBUG))
	add_child(dbg)
	_render_btn = Button.new()
	_render_btn.position = Vector2(1060, 660)
	_render_btn.size = Vector2(190, 36)
	_render_btn.pressed.connect(func(): GameState.toggle_render_mode())
	add_child(_render_btn)
	GameState.render_mode_changed.connect(func(_m): _render_btn.text = GameState.render_label() + " [F2]")
	_render_btn.text = GameState.render_label() + " [F2]"

	_select(GameState.hero_gender)
	if GameState.autoplay:
		await get_tree().create_timer(1.2).timeout
		_start()


func _card(g: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.position = pos
	b.size = Vector2(280, 390)
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.09, 0.13, 0.85)
	sb.border_color = Color(0.4, 0.5, 0.58, 0.6)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	var sel := sb.duplicate() as StyleBoxFlat
	sel.border_color = Color("#ffd27a")
	sel.set_border_width_all(4)
	sel.bg_color = Color(0.2, 0.16, 0.08, 0.9)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sel)
	b.add_theme_stylebox_override("hover_pressed", sel)
	b.pressed.connect(_select.bind(g))
	add_child(b)
	var portrait := TextureRect.new()
	portrait.texture = load("res://art/portraits/hero_%s.svg" % g)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(16, 14)
	portrait.size = Vector2(110, 110)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(portrait)
	var body := TextureRect.new()
	body.texture = load("res://art/characters/hero_%s.svg" % g)
	body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	body.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	body.position = Vector2(40, 110)
	body.size = Vector2(220, 270)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(body)
	var lbl := Label.new()
	lbl.text = "Base masculine" if g == "m" else "Base féminine"
	lbl.position = Vector2(150, 40)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color("#e8eef2"))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(lbl)
	return b


func _select(g: String) -> void:
	var previous_default := "Aren" if _gender == "m" else "Ilya"
	_gender = g
	for k in _cards:
		_cards[k].button_pressed = k == g
	if _name_edit.text == "" or _name_edit.text == previous_default:
		_name_edit.text = "Aren" if g == "m" else "Ilya"


func _atelier() -> void:
	GameState.new_game(_gender, _name_edit.text)
	GameState.goto(GameState.SCENE_RIG_VIEWER)


func _art_proto() -> void:
	GameState.new_game(_gender, _name_edit.text)
	GameState.from_zone = false
	GameState.art_proto = true
	GameState.goto(GameState.SCENE_BATTLE)


func _start() -> void:
	GameState.new_game(_gender, _name_edit.text)
	GameState.art_proto = false
	GameState.goto(GameState.SCENE_ZONE)


func _quick_battle() -> void:
	GameState.new_game(_gender, _name_edit.text)
	GameState.art_proto = false
	GameState.from_zone = false
	GameState.goto(GameState.SCENE_BATTLE)
