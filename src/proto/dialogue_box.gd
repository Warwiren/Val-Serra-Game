extends Control
## Boîte de dialogue narrative (lot P1-C) : portrait du héros à gauche, portrait de l'interlocuteur à droite,
## locuteur mis en avant (l'autre portrait est atténué), nom du locuteur, texte progressif, réponses au choix.
## Données : une liste d'étapes {who, text, expr?} ou {choice: [{label, then: [étapes]}]}.
## Touches : E / Entrée / Espace pour avancer (ou valider un choix), ↑/↓ pour choisir, Échap pour fermer.
## Portraits : source unique src/proto/portraits.gd (expression par réplique, repli sur « neutre »).

signal closed

const UI = preload("res://src/presentation/ui_style.gd")
const Portraits = preload("res://src/proto/portraits.gd")

var speakers: Dictionary = {}          # id -> {name}
var left_id := "heros"
var right_id := "pnj"
var _queue: Array = []
var _choices: Array = []
var _choice_index := 0
var _speaker := ""
var _left: TextureRect
var _right: TextureRect
var _name: Label
var _text: RichTextLabel
var _choice_box: VBoxContainer
var _hint: Label
var _tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UI.make_theme()
	visible = false
	_left = _portrait_rect(Vector2(110, 390))
	_right = _portrait_rect(Vector2(1170 - 150, 390))
	var box := PanelContainer.new()
	box.position = Vector2(110, 548)
	box.size = Vector2(1060, 132)
	box.add_theme_stylebox_override("panel", UI.box(UI.C_PANEL, UI.C_GOLD, 2, 8, 0.95))
	add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	box.add_child(v)
	_name = Label.new()
	_name.add_theme_font_override("font", UI.title_font())
	_name.add_theme_font_size_override("font_size", 20)
	_name.add_theme_color_override("font_color", UI.C_SELECT)
	v.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(1030, 48)
	_text.add_theme_font_size_override("normal_font_size", 18)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_text)
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 2)
	v.add_child(_choice_box)
	_hint = Label.new()
	_hint.position = Vector2(110 + 1060 - 330, 548 + 152)
	_hint.size = Vector2(320, 20)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", UI.FS_SMALL)
	_hint.add_theme_color_override("font_color", UI.C_TEXT_DIM)
	add_child(_hint)


func _portrait_rect(pos: Vector2) -> TextureRect:
	var frame := PanelContainer.new()
	frame.position = pos
	frame.size = Vector2(150, 150)
	frame.add_theme_stylebox_override("panel", UI.box(UI.C_BG, UI.C_SEP, 1, 6, 0.9))
	add_child(frame)
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(140, 140)
	frame.add_child(t)
	return t


func open(steps: Array, speaker_data: Dictionary) -> void:
	speakers = speaker_data
	_queue = steps.duplicate(true)
	_choices = []
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)
	_left.texture = Portraits.get_texture(left_id)
	_right.texture = Portraits.get_texture(right_id)
	_next()


func is_open() -> bool:
	return visible


func showing_choice() -> bool:
	return not _choices.is_empty()


## Renvoie true si la touche a été consommée par le dialogue.
func handle_key(event: InputEventKey) -> bool:
	if not visible:
		return false
	if event.keycode == KEY_ESCAPE:
		close()
	elif not _choices.is_empty() and (event.keycode == KEY_UP or event.keycode == KEY_DOWN):
		_choice_index = (_choice_index + (1 if event.keycode == KEY_DOWN else -1) + _choices.size()) % _choices.size()
		_draw_choices()
	elif event.physical_keycode == KEY_E or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		advance()
	return true


func advance() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
		_text.visible_ratio = 1.0              # 1er appui : affiche la réplique entière
		return
	if not _choices.is_empty():
		pick(_choice_index)
		return
	_next()


func pick(i: int) -> void:
	var c: Dictionary = _choices[i]
	_choices = []
	_draw_choices()
	_queue = c.get("then", []).duplicate(true) + _queue
	_next()


func close() -> void:
	if not visible:
		return
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.15)
	await t.finished
	visible = false
	_queue = []
	_choices = []
	closed.emit()


func _next() -> void:
	if _queue.is_empty():
		close()
		return
	var step: Dictionary = _queue.pop_front()
	if step.has("choice"):
		_choices = step["choice"]
		_choice_index = 0
		_set_speaker(left_id, step.get("expr", "neutre"))
		_text.text = "[color=#%s]%s[/color]" % [UI.C_TEXT_2.to_html(false), step.get("prompt", "Que répondre ?")]
		_text.visible_ratio = 1.0
		_draw_choices()
		return
	_set_speaker(step["who"], step.get("expr", "neutre"))
	_text.text = step["text"]
	_text.visible_ratio = 0.0
	_tween = create_tween()
	_tween.tween_property(_text, "visible_ratio", 1.0, 0.022 * _text.text.length())
	_hint.text = "E : suite   ·   Échap : fermer"


func _set_speaker(id: String, expr: String) -> void:
	_speaker = id
	_name.text = speakers.get(id, {}).get("name", id)
	# Locuteur éclairé, interlocuteur atténué (l'identité ne repose pas que sur la couleur : le NOM est affiché)
	var on_left := id == left_id
	if on_left:
		_left.texture = Portraits.get_texture(left_id, expr)
	else:
		_right.texture = Portraits.get_texture(right_id, expr)
	_left.modulate = Color.WHITE if on_left else Color(0.45, 0.47, 0.55)
	_right.modulate = Color.WHITE if not on_left else Color(0.45, 0.47, 0.55)
	_left.get_parent().add_theme_stylebox_override("panel", UI.box(UI.C_BG, UI.C_GOLD if on_left else UI.C_SEP, 2 if on_left else 1, 6, 0.9))
	_right.get_parent().add_theme_stylebox_override("panel", UI.box(UI.C_BG, UI.C_GOLD if not on_left else UI.C_SEP, 2 if not on_left else 1, 6, 0.9))


func _draw_choices() -> void:
	for c in _choice_box.get_children():
		c.queue_free()
	for i in range(_choices.size()):
		var b := Button.new()
		b.text = ("▶  " if i == _choice_index else "     ") + _choices[i]["label"]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_color_override("font_color", UI.C_SELECT if i == _choice_index else UI.C_TEXT)
		b.add_theme_font_size_override("font_size", UI.FS_MAIN)
		var idx := i
		b.pressed.connect(func(): pick(idx))
		_choice_box.add_child(b)
	_hint.text = "↑ ↓ : choisir   ·   E : valider   ·   Échap : fermer" if not _choices.is_empty() else "E : suite   ·   Échap : fermer"
