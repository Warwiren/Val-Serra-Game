extends Control
## Interface de combat (couche HUD). Affiche ce que la scène lui donne ; ne connaît pas les règles.

signal action_selected(action_id: String)
signal mode_selected(mode: String)
signal ally_selected(actor_id: String)
signal confirm_pressed
signal render_toggle_pressed
signal result_choice(choice: String)

const Art = preload("res://src/presentation/art.gd")
const TimelineView = preload("res://src/presentation/timeline_view.gd")

const ACTION_KEYS := ["1", "2", "3", "4", "5"]

var timeline: TimelineView
var _theme: Theme
var _party_rows: Dictionary = {}       # actor_id -> PartyRow
var _monster_panel: MonsterPanel
var _action_box: VBoxContainer
var _action_buttons: Dictionary = {}   # action_id -> Button
var _cards: Array = []                 # ModeCard x3
var _info_card: ModeCard
var _ally_box: HBoxContainer
var _target_label: RichTextLabel
var _preview: RichTextLabel
var _confirm: Button
var _render_btn: Button
var _log: RichTextLabel
var _log_panel: Panel
var _log_expanded := false
var _banner: Label
var _result: Control
var _hint: Label
var _input_enabled := true


func build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_theme = _make_theme()
	theme = _theme

	timeline = TimelineView.new()
	timeline.position = Vector2(0, 0)
	timeline.size = Vector2(1280, 120)
	timeline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(timeline)

	_monster_panel = MonsterPanel.new()
	_monster_panel.position = Vector2(760, 128)
	_monster_panel.size = Vector2(360, 46)
	_monster_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_monster_panel)

	_render_btn = Button.new()
	_render_btn.position = Vector2(1132, 130)
	_render_btn.size = Vector2(140, 34)
	_render_btn.focus_mode = Control.FOCUS_NONE
	_render_btn.add_theme_font_size_override("font_size", 14)
	_render_btn.pressed.connect(func(): render_toggle_pressed.emit())
	add_child(_render_btn)

	# Journal secondaire (repliable avec L)
	_log_panel = Panel.new()
	_log_panel.position = Vector2(10, 128)
	_log_panel.size = Vector2(430, 84)
	_log_panel.add_theme_stylebox_override("panel", _box(Color(0.03, 0.05, 0.08, 0.55), Color(0, 0, 0, 0), 6))
	_log_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_log_panel)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.position = Vector2(8, 4)
	_log.size = _log_panel.size - Vector2(16, 8)
	_log.add_theme_font_size_override("normal_font_size", 12)
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log_panel.add_child(_log)

	# Bandeau inférieur
	var bottom := Panel.new()
	bottom.position = Vector2(0, 556)
	bottom.size = Vector2(1280, 164)
	bottom.add_theme_stylebox_override("panel", _box(Color(0.03, 0.05, 0.08, 0.86), Art.C_PANEL_EDGE, 0))
	bottom.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bottom)

	_action_box = VBoxContainer.new()
	_action_box.position = Vector2(14, 564)
	_action_box.size = Vector2(250, 150)
	_action_box.add_theme_constant_override("separation", 2)
	add_child(_action_box)

	_target_label = RichTextLabel.new()
	_target_label.bbcode_enabled = true
	_target_label.position = Vector2(280, 562)
	_target_label.size = Vector2(600, 26)
	_target_label.add_theme_font_size_override("normal_font_size", 15)
	_target_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_target_label)

	for i in range(3):
		var c := ModeCard.new()
		c.position = Vector2(280 + i * 160, 590)
		c.size = Vector2(152, 82)
		c.index = i
		c.pressed.connect(_on_card_pressed)
		add_child(c)
		_cards.append(c)
	_info_card = ModeCard.new()
	_info_card.position = Vector2(280, 590)
	_info_card.size = Vector2(472, 82)
	_info_card.static_card = true
	add_child(_info_card)
	_ally_box = HBoxContainer.new()
	_ally_box.position = Vector2(280, 592)
	_ally_box.size = Vector2(472, 78)
	_ally_box.add_theme_constant_override("separation", 8)
	add_child(_ally_box)

	_confirm = Button.new()
	_confirm.text = "EXÉCUTER\n(Entrée)"
	_confirm.position = Vector2(762, 590)
	_confirm.size = Vector2(112, 82)
	_confirm.focus_mode = Control.FOCUS_NONE
	_confirm.add_theme_font_size_override("font_size", 16)
	_confirm.add_theme_stylebox_override("normal", _box(Color(0.55, 0.38, 0.12, 0.95), Art.C_GOLD, 8))
	_confirm.add_theme_stylebox_override("hover", _box(Color(0.7, 0.5, 0.16, 1.0), Color(1, 0.95, 0.75), 8))
	_confirm.add_theme_stylebox_override("pressed", _box(Color(0.4, 0.28, 0.1, 1.0), Art.C_GOLD, 8))
	_confirm.add_theme_stylebox_override("disabled", _box(Color(0.2, 0.2, 0.22, 0.8), Color(0.3, 0.3, 0.3), 8))
	_confirm.pressed.connect(func(): confirm_pressed.emit())
	add_child(_confirm)

	_preview = RichTextLabel.new()
	_preview.bbcode_enabled = true
	_preview.position = Vector2(280, 676)
	_preview.size = Vector2(600, 42)
	_preview.add_theme_font_size_override("normal_font_size", 14)
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_preview)

	_hint = Label.new()
	_hint.position = Vector2(14, 216)
	_hint.size = Vector2(430, 40)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.text = "Clic ou ←/→ : partie visée · ↑/↓ ou 1-5 : action · Tab : mode · Entrée : exécuter\nEspace (maintenu) : accélérer · L : journal · F2 : rendu A/B"
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 0.5))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hint.add_theme_constant_override("outline_size", 4)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)

	_banner = Label.new()
	_banner.position = Vector2(0, 200)
	_banner.size = Vector2(1280, 70)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 40)
	_banner.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05))
	_banner.add_theme_constant_override("outline_size", 12)
	_banner.modulate.a = 0.0
	_banner.pivot_offset = _banner.size / 2
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)


func add_party_row(id: String, portrait: Texture2D, display_name: String, weapon: String, index: int) -> void:
	var row := PartyRow.new()
	row.actor_id = id
	row.portrait = portrait
	row.display_name = display_name
	row.weapon = weapon
	row.position = Vector2(892, 562 + index * 52)
	row.size = Vector2(380, 50)
	row.clicked.connect(func(aid): ally_selected.emit(aid))
	add_child(row)
	_party_rows[id] = row


func set_monster(display_name: String, max_hp: int) -> void:
	_monster_panel.display_name = display_name
	_monster_panel.max_hp = max_hp


func update_party(hp: Dictionary, maxhp: Dictionary, res: Dictionary, guard: Dictionary, current_id: String, ally_pick: bool) -> void:
	for id in _party_rows:
		var r: PartyRow = _party_rows[id]
		r.set_values(int(hp[id]), int(maxhp[id]), int(res[id]), bool(guard.get(id, false)), id == current_id, ally_pick)


func update_monster(hp: int, telegraph_text: String) -> void:
	_monster_panel.hp = hp
	_monster_panel.telegraph = telegraph_text
	_monster_panel.queue_redraw()


func set_render_label(text: String) -> void:
	_render_btn.text = text + " [F2]"


## actions : [{id, label, enabled, reason}]
func set_actions(actions: Array, selected: String) -> void:
	for c in _action_box.get_children():
		c.queue_free()
	_action_buttons.clear()
	var i := 0
	for a in actions:
		var b := Button.new()
		b.text = "%s   %s" % [ACTION_KEYS[i] if i < ACTION_KEYS.size() else " ", a["label"]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(250, 28)
		b.add_theme_font_size_override("font_size", 14)
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = not a["enabled"]
		b.tooltip_text = a.get("reason", "")
		b.toggle_mode = true
		b.button_pressed = a["id"] == selected
		var aid: String = a["id"]
		b.pressed.connect(func(): action_selected.emit(aid))
		_action_box.add_child(b)
		_action_buttons[aid] = b
		i += 1


## cards : [{mode, title, lines:[...], windup:float, selected, color}] (3 cartes) ou une seule carte d'info.
func set_mode_cards(cards: Array) -> void:
	_ally_box.visible = false
	if cards.size() == 1:
		for c in _cards:
			c.visible = false
		_info_card.visible = true
		_info_card.data = cards[0]
		_info_card.queue_redraw()
		return
	_info_card.visible = false
	for i in range(3):
		_cards[i].visible = i < cards.size()
		if i < cards.size():
			_cards[i].data = cards[i]
			_cards[i].queue_redraw()


func set_ally_choices(allies: Array, selected: String) -> void:
	for c in _cards:
		c.visible = false
	_info_card.visible = false
	_ally_box.visible = true
	for c in _ally_box.get_children():
		c.queue_free()
	for a in allies:
		var b := Button.new()
		b.text = "%s\n%d / %d PV" % [a["name"], a["hp"], a["max"]]
		b.custom_minimum_size = Vector2(150, 78)
		b.focus_mode = Control.FOCUS_NONE
		b.toggle_mode = true
		b.button_pressed = a["id"] == selected
		b.icon = a["portrait"]
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 44)
		var aid: String = a["id"]
		b.pressed.connect(func(): ally_selected.emit(aid))
		_ally_box.add_child(b)


func set_target_text(bbcode: String) -> void:
	_target_label.text = bbcode


func set_preview(bbcode: String) -> void:
	_preview.text = bbcode


func set_input_enabled(on: bool) -> void:
	_input_enabled = on
	_confirm.disabled = not on
	for b in _action_buttons.values():
		if not on:
			b.disabled = true
	for c in _cards:
		c.enabled = on
		c.queue_redraw()
	if not on:
		_preview.text = "[color=#8d98a3]…[/color]"


func confirm_enabled(on: bool) -> void:
	_confirm.disabled = not (on and _input_enabled)


func log_append(t: int, text: String, color: String) -> void:
	_log.append_text("[color=#6d7883]%d[/color] [color=%s]%s[/color]\n" % [t, color, text])


func toggle_log() -> void:
	_log_expanded = not _log_expanded
	_log_panel.size = Vector2(430, 380 if _log_expanded else 84)
	_log.size = _log_panel.size - Vector2(16, 8)


func banner(text: String, color: Color, hold := 0.7) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.scale = Vector2(0.7, 0.7)
	var t := create_tween()
	t.tween_property(_banner, "modulate:a", 1.0, 0.12)
	t.parallel().tween_property(_banner, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(hold)
	t.tween_property(_banner, "modulate:a", 0.0, 0.3)


func show_result(victory: bool, lines: Array, buttons: Array) -> void:
	_result = Control.new()
	_result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_result)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result.add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(390, 170)
	panel.size = Vector2(500, 330)
	panel.add_theme_stylebox_override("panel", _box(Color(0.05, 0.07, 0.1, 0.96), Art.C_GOLD if victory else Art.C_HP_LOW, 12))
	_result.add_child(panel)
	var title := Label.new()
	title.text = "VICTOIRE" if victory else "DÉFAITE"
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Art.C_GOLD if victory else Art.C_HP_LOW)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 18)
	title.size = Vector2(500, 60)
	panel.add_child(title)
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.position = Vector2(40, 92)
	body.size = Vector2(420, 150)
	body.add_theme_font_size_override("normal_font_size", 17)
	body.text = "\n".join(PackedStringArray(lines))
	panel.add_child(body)
	var x := 250.0 - (buttons.size() * 150.0 + (buttons.size() - 1) * 12.0) / 2.0
	for b in buttons:
		var btn := Button.new()
		btn.text = b["label"]
		btn.position = Vector2(x, 262)
		btn.size = Vector2(150, 44)
		var choice: String = b["id"]
		btn.pressed.connect(func(): result_choice.emit(choice))
		panel.add_child(btn)
		x += 162.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	panel.pivot_offset = panel.size / 2
	var t := create_tween()
	t.tween_property(panel, "modulate:a", 1.0, 0.3)
	t.parallel().tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)


func _on_card_pressed(i: int) -> void:
	if _input_enabled and _cards[i].data.has("mode"):
		mode_selected.emit(_cards[i].data["mode"])


# ---------------------------------------------------------------------------
# Thème
# ---------------------------------------------------------------------------

static func _box(bg: Color, edge: Color, radius: int, border := 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(border if edge.a > 0 else 0)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	return s


func _make_theme() -> Theme:
	var th := Theme.new()
	th.set_stylebox("normal", "Button", _box(Color(0.1, 0.14, 0.19, 0.95), Color(0.35, 0.45, 0.52, 0.6), 6))
	th.set_stylebox("hover", "Button", _box(Color(0.16, 0.22, 0.29, 1.0), Color(0.7, 0.85, 0.95, 0.9), 6))
	th.set_stylebox("pressed", "Button", _box(Color(0.3, 0.24, 0.1, 1.0), Art.C_GOLD, 6))
	th.set_stylebox("hover_pressed", "Button", _box(Color(0.36, 0.28, 0.12, 1.0), Art.C_GOLD, 6))
	th.set_stylebox("disabled", "Button", _box(Color(0.08, 0.09, 0.11, 0.8), Color(0.2, 0.22, 0.25, 0.6), 6))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", Art.C_TEXT)
	th.set_color("font_pressed_color", "Button", Color(1, 0.93, 0.75))
	th.set_color("font_hover_pressed_color", "Button", Color(1, 0.93, 0.75))
	th.set_color("font_disabled_color", "Button", Color(0.45, 0.48, 0.52))
	th.set_font_size("font_size", "Button", 15)
	th.set_color("default_color", "RichTextLabel", Art.C_TEXT)
	return th


# ---------------------------------------------------------------------------
# Widgets dessinés
# ---------------------------------------------------------------------------

class PartyRow extends Control:
	signal clicked(actor_id: String)
	var actor_id := ""
	var portrait: Texture2D
	var display_name := ""
	var weapon := ""
	var hp := 1
	var max_hp := 1
	var res := 0
	var guard := false
	var active := false
	var pickable := false
	var _shown_hp := -1.0
	var _t := 0.0

	func set_values(h: int, m: int, r: int, g: bool, a: bool, pick: bool) -> void:
		hp = h; max_hp = m; res = r; guard = g; active = a; pickable = pick
		if _shown_hp < 0:
			_shown_hp = float(h)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if pick else Control.CURSOR_ARROW

	func _gui_input(event: InputEvent) -> void:
		if pickable and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(actor_id)

	func _process(delta: float) -> void:
		_t += delta
		_shown_hp = move_toward(_shown_hp, float(hp), delta * 160.0)
		queue_redraw()

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var bg := Color(0.32, 0.25, 0.1, 0.8) if active else Color(0.08, 0.11, 0.15, 0.85)
		draw_rect(Rect2(Vector2.ZERO, size), bg)
		if active:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.82, 0.48, 0.6 + 0.3 * sin(_t * 5)), false, 2.0)
		elif pickable:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 1.0, 0.55, 0.7), false, 2.0)
		var dead := hp <= 0
		var c := Vector2(26, 25)
		draw_circle(c, 22, Color(0.12, 0.15, 0.2))
		if portrait:
			draw_texture_rect(portrait, Rect2(c - Vector2(23, 23), Vector2(46, 46)), false, Color(1, 1, 1, 0.35 if dead else 1.0))
		draw_arc(c, 22, 0, TAU, 32, Color("#8ec9ff"), 2.5, true)
		draw_string(font, Vector2(56, 17), display_name, HORIZONTAL_ALIGNMENT_LEFT, 170, 15, Color("#8d98a3") if dead else Color("#e8eef2"))
		draw_string(font, Vector2(56, 17), weapon, HORIZONTAL_ALIGNMENT_RIGHT, 316, 12, Color("#8d98a3"))
		# PV
		var ratio := clampf(_shown_hp / float(max_hp), 0, 1)
		var hc := Color("#7fd67a") if ratio > 0.35 else Color("#e8604c")
		draw_rect(Rect2(56, 24, 200, 10), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(56, 24, 200 * float(hp) / float(max_hp), 10), Color(1, 1, 1, 0.5))
		draw_rect(Rect2(56, 24, 200 * ratio, 10), hc)
		draw_string(font, Vector2(262, 34), "%d/%d" % [hp, max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8eef2"))
		# Résonance (repères à 30 = sérum)
		draw_rect(Rect2(56, 38, 200, 7), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(56, 38, 2.0 * res, 7), Color("#5fe3ff"))
		draw_line(Vector2(56 + 60, 36), Vector2(56 + 60, 47), Color(1, 1, 1, 0.7), 2.0)
		draw_string(font, Vector2(262, 47), "Rés. %d" % res, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#5fe3ff"))
		if guard:
			draw_string(font, Vector2(318, 34), "GARDE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#bff6ff"))
		if dead:
			draw_string(font, Vector2(318, 34), "K.O.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8604c"))


class MonsterPanel extends Control:
	var display_name := ""
	var hp := 1
	var max_hp := 1
	var telegraph := ""
	var _shown := -1.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if _shown < 0:
			_shown = float(hp)
		_shown = move_toward(_shown, float(hp), delta * 400.0)
		queue_redraw()

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.05, 0.08, 0.7))
		draw_string(font, Vector2(10, 18), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#ff8a7a"))
		draw_string(font, Vector2(10, 18), "%d / %d" % [hp, max_hp], HORIZONTAL_ALIGNMENT_RIGHT, size.x - 20, 14, Color("#e8eef2"))
		draw_rect(Rect2(10, 26, size.x - 20, 12), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(10, 26, (size.x - 20) * _shown / float(max_hp), 12), Color(1, 0.9, 0.8, 0.6))
		draw_rect(Rect2(10, 26, (size.x - 20) * float(hp) / float(max_hp), 12), Color("#d9534a"))
		if telegraph != "":
			var a := 0.6 + 0.4 * sin(_t * 8.0)
			draw_string_outline(font, Vector2(10, 64), telegraph, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 5, Color(0, 0, 0, 0.9))
			draw_string(font, Vector2(10, 64), telegraph, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.45, 0.35, a))


class ModeCard extends Control:
	signal pressed(index: int)
	var index := 0
	var data: Dictionary = {}
	var enabled := true
	var static_card := false
	var _hover := false

	func _ready() -> void:
		mouse_entered.connect(_set_hover.bind(true))
		mouse_exited.connect(_set_hover.bind(false))

	func _set_hover(on: bool) -> void:
		_hover = on
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if static_card or not enabled:
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit(index)

	func _draw() -> void:
		if data.is_empty():
			return
		var font := ThemeDB.fallback_font
		var sel: bool = data.get("selected", false)
		var col: Color = data.get("color", Color("#8ec9ff"))
		var bg := Color(0.1, 0.13, 0.18, 0.95)
		if sel:
			bg = Color(0.28, 0.22, 0.1, 0.98)
		elif _hover and not static_card:
			bg = Color(0.15, 0.2, 0.26, 0.98)
		draw_rect(Rect2(Vector2.ZERO, size), bg)
		draw_rect(Rect2(Vector2.ZERO, size), Color("#ffd27a") if sel else Color(col, 0.6), false, 3.0 if sel else 1.5)
		draw_string(font, Vector2(10, 22), data.get("title", ""), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 18, col)
		if data.has("windup"):
			# Barre de délai : longueur = part du cycle avant l'effet
			var w := (size.x - 20) * float(data["windup"])
			draw_rect(Rect2(10, 29, size.x - 20, 4), Color(1, 1, 1, 0.12))
			draw_rect(Rect2(10, 29, w, 4), col)
		var y := 47.0
		for line in data.get("lines", []):
			draw_string(font, Vector2(10, y), line, HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 13, Color("#e8eef2"))
			y += 15.0
		if not enabled and not static_card:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
