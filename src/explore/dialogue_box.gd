extends Control
## Dialogue à portraits : héros à gauche, PNJ à droite (le locuteur est mis en avant).
## Lit data/dialogue/*.json ; applique les accords via GameState.g().

signal finished

const Art = preload("res://src/presentation/art.gd")

var data: Dictionary = {}
var _node_id := ""
var _hero_portrait: TextureRect
var _npc_portrait: TextureRect
var _name_label: Label
var _text: RichTextLabel
var _choices: VBoxContainer
var _next_hint: Label
var _typing := false
var _tween: Tween


func open(dialogue_path: String, start_node: String) -> void:
	var f := FileAccess.open(dialogue_path, FileAccess.READ)
	data = JSON.parse_string(f.get_as_text())
	_build()
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.25)
	_show(start_node)


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_click)
	add_child(dim)

	_hero_portrait = _portrait(load(GameState.hero_portrait()), Vector2(30, 190), false)
	_npc_portrait = _portrait(load(data.get("npc_portrait", "res://art/portraits/npc.svg")), Vector2(1250 - 330, 190), true)

	var panel := Panel.new()
	panel.position = Vector2(40, 506)
	panel.size = Vector2(1200, 196)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.1, 0.94)
	sb.border_color = Color(0.85, 0.7, 0.45, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	_name_label = Label.new()
	_name_label.position = Vector2(64, 486)
	_name_label.add_theme_font_size_override("font_size", 22)
	_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_name_label.add_theme_constant_override("outline_size", 8)
	add_child(_name_label)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.position = Vector2(70, 528)
	_text.size = Vector2(1140, 80)
	_text.add_theme_font_size_override("normal_font_size", 22)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)

	_choices = VBoxContainer.new()
	_choices.position = Vector2(70, 608)
	_choices.size = Vector2(800, 90)
	_choices.add_theme_constant_override("separation", 6)
	add_child(_choices)

	_next_hint = Label.new()
	_next_hint.text = "E / Entrée ▸"
	_next_hint.position = Vector2(1110, 668)
	_next_hint.add_theme_font_size_override("font_size", 16)
	_next_hint.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
	add_child(_next_hint)


func _portrait(tex: Texture2D, pos: Vector2, flip: bool) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.position = pos
	r.size = Vector2(330, 330)
	r.flip_h = flip
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _show(node_id: String) -> void:
	_node_id = node_id
	var node: Dictionary = data["nodes"][node_id]
	if node.has("action"):
		_do_action(node["action"])
	var hero_speaks: bool = node.get("speaker", "npc") == "hero"
	_name_label.text = GameState.hero_name if hero_speaks else data.get("npc_name", "PNJ")
	_name_label.add_theme_color_override("font_color", Art.C_HUNTER if hero_speaks else Color("#ffd27a"))
	_focus(_hero_portrait, hero_speaks)
	_focus(_npc_portrait, not hero_speaks)
	for c in _choices.get_children():
		c.queue_free()
	_text.text = GameState.g(node["text"])
	_text.visible_ratio = 0.0
	_typing = true
	_next_hint.visible = false
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_text, "visible_ratio", 1.0, 0.018 * _text.get_total_character_count() + 0.05)
	_tween.tween_callback(_on_typed)


func _focus(r: TextureRect, on: bool) -> void:
	var t := create_tween()
	t.tween_property(r, "modulate", Color.WHITE if on else Color(0.4, 0.42, 0.48, 0.9), 0.2)
	t.parallel().tween_property(r, "scale", Vector2.ONE * (1.0 if on else 0.92), 0.2)
	r.pivot_offset = Vector2(165, 330)


func _on_typed() -> void:
	_typing = false
	_text.visible_ratio = 1.0
	var node: Dictionary = data["nodes"][_node_id]
	var choices: Array = node.get("choices", [])
	if choices.is_empty():
		_next_hint.visible = true
		return
	var i := 0
	for ch in choices:
		var b := Button.new()
		b.text = "▸  " + GameState.g(ch["text"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 18)
		b.custom_minimum_size = Vector2(760, 36)
		var nxt: String = ch["next"]
		b.pressed.connect(func(): _show(nxt))
		_choices.add_child(b)
		if i == 0:
			b.grab_focus()
		i += 1


func _advance() -> void:
	if _typing:
		_tween.kill()
		_on_typed()
		return
	var node: Dictionary = data["nodes"][_node_id]
	if not node.get("choices", []).is_empty():
		return
	if node.get("next", null) != null:
		_show(node["next"])
	else:
		_close()


func _close() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.2)
	await t.finished
	finished.emit()
	queue_free()


func _do_action(action: String) -> void:
	if action == "give_potion":
		GameState.potions += 1
		GameState.flags["gift"] = true
	elif action.begins_with("set_flag:"):
		GameState.flags[action.substr(9)] = true


func _on_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_KP_ENTER:
			if _choices.get_child_count() > 0 and not _typing:
				return   # les boutons de choix gèrent Entrée eux-mêmes
			_advance()
			get_viewport().set_input_as_handled()


## Démo automatique : avance seule (premier choix).
func auto_step() -> void:
	if _typing:
		return
	if _choices.get_child_count() > 0:
		(_choices.get_child(0) as Button).emit_signal("pressed")
	else:
		_advance()
