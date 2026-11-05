extends "res://src/presentation/battle_hud.gd"
## HUD de combat du prototype (brief unifié v1.1, § 4 ; disposition de l'annexe A, contenu = données réelles).
##   haut gauche  : identité de la rencontre        haut centre : frise d'initiative     haut droite : 3 Chasseurs
##   centre       : théâtre (aucun panneau)          bas centre  : PV du Vorgane + statuts actifs
##   bas gauche   : menu vertical des actions        bas centre/droite : description, cartes VIF/MESURÉ/CHARGÉ, Confirmer
## Même interface publique que BattleHud : la scène de combat et le CombatCore ne changent pas.
## Couleurs, polices et tailles : uniquement UiStyle (src/presentation/ui_style.gd).

const UI = preload("res://src/presentation/ui_style.gd")
const InitiativeBar = preload("res://src/presentation/initiative_bar.gd")

var zone_name := "Avant-poste de la lisière"
var _c_party: Dictionary = {}          # id -> PartyCard
var _c_party_box: VBoxContainer
var _c_boss: BossBar
var _c_menu: VBoxContainer
var _c_rows: Dictionary = {}           # action_id -> ActionRow
var _c_desc_title: Label
var _c_desc: RichTextLabel
var _c_target: RichTextLabel
var _c_cards: Array = []               # TempoCard × 3
var _c_info: TempoCard
var _c_allies: HBoxContainer
var _c_confirm: Button
var _c_preview: RichTextLabel
var _c_log_panel: PanelContainer
var _c_log: RichTextLabel
var _c_banner: Label
var _c_actions_cache: Array = []


func build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UI.make_theme()

	# --- Haut gauche : identité de la rencontre --------------------------------------------------
	var ident := Identity.new()
	ident.zone = zone_name
	ident.position = Vector2(UI.MARGIN, 10)
	ident.size = Vector2(300, 52)
	ident.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ident)

	# --- Haut centre : frise d'initiative --------------------------------------------------------
	var bar := InitiativeBar.new()
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.offset_left = -318
	bar.offset_right = 318
	bar.offset_top = 8
	bar.offset_bottom = 92
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	timeline = bar

	# --- Haut droite : les trois Chasseurs ----------------------------------------------------------
	_c_party_box = VBoxContainer.new()
	_c_party_box.anchor_left = 1.0
	_c_party_box.anchor_right = 1.0
	_c_party_box.offset_left = -UI.PARTY_W - UI.MARGIN
	_c_party_box.offset_right = -UI.MARGIN
	_c_party_box.offset_top = 8
	_c_party_box.add_theme_constant_override("separation", 6)
	add_child(_c_party_box)

	# --- Bas : bloc d'interface ancré en bas ----------------------------------------------------------
	var bottom := Control.new()
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.anchor_right = 1.0
	bottom.offset_top = -168
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	# voile en dégradé pour la lisibilité (pas un bandeau opaque)
	var grad := GradientTexture2D.new()
	grad.fill_from = Vector2(0, 0)
	grad.fill_to = Vector2(0, 1)
	var g := Gradient.new()
	g.set_color(0, Color(UI.C_BG, 0.0))
	g.set_color(1, Color(UI.C_BG, 0.85))
	grad.gradient = g
	var veil_tex := TextureRect.new()
	veil_tex.texture = grad
	veil_tex.stretch_mode = TextureRect.STRETCH_SCALE
	veil_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil_tex.offset_top = -30
	veil_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(veil_tex)

	# Bas gauche : menu vertical des actions
	var menu_panel := PanelContainer.new()
	menu_panel.position = Vector2(UI.MARGIN, 18)
	menu_panel.size = Vector2(UI.MENU_W, 142)
	menu_panel.add_theme_stylebox_override("panel", UI.box(UI.C_PANEL, UI.C_SEP, 1, UI.RADIUS, 0.94))
	bottom.add_child(menu_panel)
	_c_menu = VBoxContainer.new()
	_c_menu.add_theme_constant_override("separation", 1)
	menu_panel.add_child(_c_menu)

	# Bas centre, au-dessus : PV du Vorgane
	_c_boss = BossBar.new()
	_c_boss.anchor_left = 0.5
	_c_boss.anchor_right = 0.5
	_c_boss.offset_left = -UI.BOSS_BAR_W * 0.5 + 60
	_c_boss.offset_right = UI.BOSS_BAR_W * 0.5 + 60
	_c_boss.offset_top = 0
	_c_boss.offset_bottom = 34
	_c_boss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(_c_boss)

	# Description de l'action + cible
	var desc := PanelContainer.new()
	desc.position = Vector2(UI.MARGIN + UI.MENU_W + 10, 52)
	desc.size = Vector2(262, 108)
	desc.add_theme_stylebox_override("panel", UI.box(UI.C_PANEL, UI.C_SEP, 1, UI.RADIUS, 0.94))
	bottom.add_child(desc)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 2)
	desc.add_child(dv)
	_c_desc_title = Label.new()
	_c_desc_title.add_theme_font_override("font", UI.bold())
	_c_desc_title.add_theme_font_size_override("font_size", UI.FS_MAIN)
	_c_desc_title.add_theme_color_override("font_color", UI.C_TEXT)
	dv.add_child(_c_desc_title)
	_c_desc = RichTextLabel.new()
	_c_desc.bbcode_enabled = true
	_c_desc.fit_content = true
	_c_desc.scroll_active = false
	_c_desc.custom_minimum_size = Vector2(240, 0)
	_c_desc.add_theme_font_size_override("normal_font_size", UI.FS_SMALL)
	_c_desc.add_theme_color_override("default_color", UI.C_TEXT_2)
	_c_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dv.add_child(_c_desc)
	_c_target = RichTextLabel.new()
	_c_target.bbcode_enabled = true
	_c_target.fit_content = true
	_c_target.scroll_active = false
	_c_target.custom_minimum_size = Vector2(240, 0)
	_c_target.add_theme_font_size_override("normal_font_size", UI.FS_SMALL)
	_c_target.add_theme_font_size_override("bold_font_size", UI.FS_SMALL)
	_c_target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dv.add_child(_c_target)

	# Cartes de tempo (ancrées à droite), Confirmer
	var right := Control.new()
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.offset_left = -(3 * 170 + 2 * 8 + 10 + 150 + UI.MARGIN)
	right.offset_right = -UI.MARGIN
	right.offset_top = 52
	right.offset_bottom = 160
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(right)
	for i in range(3):
		var c := TempoCard.new()
		c.position = Vector2(i * 178, 0)
		c.size = Vector2(170, 90)
		c.index = i
		c.pressed.connect(_c_on_card)
		right.add_child(c)
		_c_cards.append(c)
	_c_info = TempoCard.new()
	_c_info.position = Vector2(0, 0)
	_c_info.size = Vector2(3 * 170 + 16, 90)
	_c_info.static_card = true
	_c_info.visible = false
	right.add_child(_c_info)
	_c_allies = HBoxContainer.new()
	_c_allies.position = Vector2(0, 0)
	_c_allies.size = Vector2(3 * 170 + 16, 84)
	_c_allies.add_theme_constant_override("separation", 8)
	_c_allies.visible = false
	right.add_child(_c_allies)
	_c_confirm = Button.new()
	_c_confirm.text = "Confirmer\nEntrée"
	_c_confirm.position = Vector2(3 * 178 + 2, 0)
	_c_confirm.size = Vector2(150, 90)
	_c_confirm.focus_mode = Control.FOCUS_NONE
	_c_confirm.add_theme_stylebox_override("normal", UI.box(UI.C_PANEL_2, UI.C_GOLD, 2))
	_c_confirm.add_theme_stylebox_override("hover", UI.box(UI.C_PANEL_2, UI.C_SELECT, 2))
	_c_confirm.add_theme_stylebox_override("pressed", UI.box(UI.C_PANEL, UI.C_SELECT, 2))
	_c_confirm.add_theme_color_override("font_color", UI.C_SELECT)
	_c_confirm.add_theme_color_override("font_hover_color", UI.C_SELECT)
	_c_confirm.pressed.connect(func(): confirm_pressed.emit())
	right.add_child(_c_confirm)
	_c_preview = RichTextLabel.new()
	_c_preview.bbcode_enabled = true
	_c_preview.scroll_active = false
	_c_preview.position = Vector2(0, 94)
	_c_preview.size = Vector2(3 * 178 + 152, 22)
	_c_preview.add_theme_font_size_override("normal_font_size", UI.FS_SMALL)
	_c_preview.add_theme_color_override("default_color", UI.C_TEXT_2)
	_c_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(_c_preview)

	# Journal : outil de développement (touche L), masqué du HUD normal
	_c_log_panel = PanelContainer.new()
	_c_log_panel.position = Vector2(UI.MARGIN, 120)
	_c_log_panel.size = Vector2(420, 300)
	_c_log_panel.add_theme_stylebox_override("panel", UI.box(UI.C_BG, UI.C_SEP, 1, UI.RADIUS, 0.92))
	_c_log_panel.visible = false
	_c_log_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_c_log_panel)
	_c_log = RichTextLabel.new()
	_c_log.bbcode_enabled = true
	_c_log.scroll_following = true
	_c_log.add_theme_font_size_override("normal_font_size", UI.FS_TINY)
	_c_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_c_log_panel.add_child(_c_log)

	# Bandeau d'annonce (ponctuel)
	_c_banner = Label.new()
	_c_banner.anchor_right = 1.0
	_c_banner.offset_top = 200
	_c_banner.offset_bottom = 260
	_c_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_c_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_c_banner.add_theme_font_override("font", UI.title_font())
	_c_banner.add_theme_font_size_override("font_size", 34)
	_c_banner.add_theme_color_override("font_outline_color", UI.C_BG)
	_c_banner.add_theme_constant_override("outline_size", 10)
	_c_banner.modulate.a = 0.0
	_c_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_c_banner)


# --- Chasseurs ------------------------------------------------------------------------------------

func add_party_row(id: String, portrait: Texture2D, display_name: String, weapon: String, _index: int) -> void:
	var card := PartyCard.new()
	card.actor_id = id
	card.portrait = portrait
	card.display_name = display_name
	card.weapon = weapon
	card.custom_minimum_size = Vector2(UI.PARTY_W, UI.PARTY_H)
	card.clicked.connect(func(aid): ally_selected.emit(aid))
	_c_party_box.add_child(card)
	_c_party[id] = card


## Gain de Résonance : « +N » éphémère sur la carte du Chasseur (aucun clignotement).
func notify_resonance(actor_id: String, amount: int) -> void:
	if _c_party.has(actor_id):
		_c_party[actor_id].pop_gain(amount)


## Chasseurs visés par l'action en préparation du monstre (cible réelle du CombatCore).
func set_enemy_targets(ids: Array) -> void:
	for id in _c_party:
		_c_party[id].targeted = ids.has(id)
	(timeline as Object).set("enemy_aim", ids)


func set_resonance_cost(cost: int) -> void:
	for c in _c_party.values():
		c.res_cost = cost


func update_party(hp: Dictionary, maxhp: Dictionary, res: Dictionary, guard: Dictionary, current_id: String, ally_pick: bool) -> void:
	for id in _c_party:
		var c: PartyCard = _c_party[id]
		c.set_values(int(hp[id]), int(maxhp[id]), int(res[id]), bool(guard.get(id, false)), id == current_id, ally_pick)


# --- Vorgane ----------------------------------------------------------------------------------------

func set_monster(display_name: String, max_hp: int) -> void:
	_c_boss.display_name = display_name
	_c_boss.max_hp = max_hp


func update_monster(hp: int, _telegraph_text: String) -> void:
	_c_boss.hp = hp


## Statuts RÉELLEMENT actifs (1 à 3) : [{icon, text, color}]
func set_boss_status(statuses: Array) -> void:
	_c_boss.statuses = statuses.slice(0, 3)


func set_render_label(_text: String) -> void:
	pass


# --- Actions ------------------------------------------------------------------------------------------

func set_actions(actions: Array, selected: String) -> void:
	var same := actions.size() == _c_actions_cache.size()
	if same:
		for i in range(actions.size()):
			same = same and actions[i]["id"] == _c_actions_cache[i]
	if not same:
		for c in _c_menu.get_children():
			c.queue_free()
		_c_rows.clear()
		_c_actions_cache.clear()
		var i := 0
		for a in actions:
			var row := ActionRow.new()
			row.action_id = a["id"]
			row.key = str(i + 1)
			row.custom_minimum_size = Vector2(UI.MENU_W - 20, 26)
			row.picked.connect(func(aid): action_selected.emit(aid))
			_c_menu.add_child(row)
			_c_rows[a["id"]] = row
			_c_actions_cache.append(a["id"])
			i += 1
	for a in actions:
		var row: ActionRow = _c_rows[a["id"]]
		row.label = a["label"]
		row.enabled = a["enabled"] and _input_enabled
		row.reason = a.get("reason", "")
		row.selected = a["id"] == selected
		row.tooltip_text = row.reason
		row.queue_redraw()


## Une action sans mode : carte d'information unique (titre + lignes). Avec modes : 3 cartes.
func set_mode_cards(cards: Array) -> void:
	_c_allies.visible = false
	if cards.size() == 1:
		for c in _c_cards:
			c.visible = false
		_c_info.visible = true
		_c_info.data = cards[0]
		_c_info.queue_redraw()
		return
	_c_info.visible = false
	for i in range(3):
		_c_cards[i].visible = i < cards.size()
		if i < cards.size():
			_c_cards[i].data = cards[i]
			_c_cards[i].queue_redraw()


func set_action_description(title: String, text: String) -> void:
	_c_desc_title.text = title
	_c_desc.text = text


func set_ally_choices(allies: Array, selected: String) -> void:
	for c in _c_cards:
		c.visible = false
	_c_info.visible = false
	_c_allies.visible = true
	for c in _c_allies.get_children():
		c.queue_free()
	for a in allies:
		var b := Button.new()
		b.text = "%s\n%d / %d PV" % [a["name"], a["hp"], a["max"]]
		b.custom_minimum_size = Vector2(170, 90)
		b.focus_mode = Control.FOCUS_NONE
		b.toggle_mode = true
		b.button_pressed = a["id"] == selected
		b.icon = a["portrait"]
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 48)
		b.add_theme_font_size_override("font_size", UI.FS_SMALL)
		var aid: String = a["id"]
		b.pressed.connect(func(): ally_selected.emit(aid))
		_c_allies.add_child(b)


func set_target_text(bbcode: String) -> void:
	_c_target.text = bbcode


func set_preview(bbcode: String) -> void:
	_c_preview.text = bbcode


func set_input_enabled(on: bool) -> void:
	_input_enabled = on
	_c_confirm.disabled = not on
	for r in _c_rows.values():
		if not on:
			r.enabled = false
			r.queue_redraw()
	for c in _c_cards:
		c.enabled = on
		c.queue_redraw()
	if not on:
		_c_preview.text = ""


func confirm_enabled(on: bool) -> void:
	_c_confirm.disabled = not (on and _input_enabled)


func log_append(t: int, text: String, color: String) -> void:
	_c_log.append_text("[color=#%s]%d[/color]  [color=%s]%s[/color]\n" % [UI.C_TEXT_DIM.to_html(false), t, color, text])


func toggle_log() -> void:
	_c_log_panel.visible = not _c_log_panel.visible


func banner(text: String, color: Color, hold := 0.7) -> void:
	_c_banner.text = text
	_c_banner.add_theme_color_override("font_color", color)
	var t := create_tween()
	t.tween_property(_c_banner, "modulate:a", 1.0, 0.12)
	t.tween_interval(hold)
	t.tween_property(_c_banner, "modulate:a", 0.0, 0.3)


func show_result(victory: bool, lines: Array, buttons: Array) -> void:
	_result = Control.new()
	_result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_result)
	var dim := ColorRect.new()
	dim.color = Color(UI.C_BG, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.box(UI.C_PANEL, UI.C_GOLD if victory else UI.C_DANGER, 2, 8, 0.97))
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -250
	panel.offset_right = 250
	panel.offset_top = -170
	panel.offset_bottom = 170
	_result.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var title := Label.new()
	title.text = "Victoire" if victory else "Défaite"
	title.add_theme_font_override("font", UI.title_font())
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", UI.C_SELECT if victory else UI.C_DANGER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.custom_minimum_size = Vector2(460, 0)
	body.add_theme_font_size_override("normal_font_size", UI.FS_MAIN)
	body.text = "\n".join(PackedStringArray(lines))
	v.add_child(body)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 12)
	v.add_child(hb)
	for b in buttons:
		var btn := Button.new()
		btn.text = b["label"]
		btn.custom_minimum_size = Vector2(200, 44)
		var choice: String = b["id"]
		btn.pressed.connect(func(): result_choice.emit(choice))
		hb.add_child(btn)
		if hb.get_child_count() == 1:
			btn.add_theme_stylebox_override("normal", UI.box(UI.C_PANEL_2, UI.C_GOLD, 2))
			btn.call_deferred("grab_focus")
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.3)


func _c_on_card(i: int) -> void:
	if _input_enabled and _c_cards[i].data.has("mode"):
		mode_selected.emit(_c_cards[i].data["mode"])


# =====================================================================================================
# Widgets dessinés
# =====================================================================================================

class Identity extends Control:
	var zone := ""

	func _draw() -> void:
		var t := UI.title_font()
		draw_string_outline(t, Vector2(0, 30), "Val'Serra", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 4, Color(UI.C_BG, 0.8))
		draw_string(t, Vector2(0, 30), "Val'Serra", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UI.C_TEXT)
		var w := t.get_string_size("Val'Serra", HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		draw_line(Vector2(w + 12, 8), Vector2(w + 12, 40), Color(UI.C_GOLD, 0.7), 1.0)
		draw_string_outline(UI.bold(), Vector2(w + 22, 20), "COMBAT", HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FS_TINY, 3, Color(UI.C_BG, 0.8))
		draw_string(UI.bold(), Vector2(w + 22, 20), "COMBAT", HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FS_TINY, UI.C_GOLD)
		draw_string_outline(UI.font(), Vector2(w + 22, 38), zone, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FS_SMALL, 3, Color(UI.C_BG, 0.8))
		draw_string(UI.font(), Vector2(w + 22, 38), zone, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FS_SMALL, UI.C_TEXT_2)


class PartyCard extends Control:
	signal clicked(actor_id: String)
	const ROLE := {"heros": "sword", "compagnon_vif": "daggers", "compagnon_lourd": "hammer"}
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
	var res_cost := 30
	var targeted := false
	var _shown_hp := -1.0
	var _t := 0.0
	var _gain := 0
	var _gain_t := 0.0
	var _ready_t := -1.0          # instant où la compétence est devenue disponible (repère doux, 0,6 s)

	func pop_gain(amount: int) -> void:
		_gain = amount
		_gain_t = 1.2

	func set_values(h: int, m: int, r: int, g: bool, a: bool, pick: bool) -> void:
		if res < res_cost and r >= res_cost:
			_ready_t = 0.6
		hp = h; max_hp = m; res = r; guard = g; active = a; pickable = pick
		if _shown_hp < 0:
			_shown_hp = float(h)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if pick else Control.CURSOR_ARROW

	func _gui_input(event: InputEvent) -> void:
		if pickable and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(actor_id)

	func _process(delta: float) -> void:
		_t += delta
		_gain_t = maxf(0.0, _gain_t - delta)
		_ready_t = maxf(-1.0, _ready_t - delta)
		_shown_hp = move_toward(_shown_hp, float(hp), delta * 160.0)
		queue_redraw()

	func _draw() -> void:
		var edge := UI.C_SEP
		var bw := 1
		if active:
			edge = UI.C_SELECT; bw = 2
		elif pickable:
			edge = UI.C_HEAL; bw = 2
		draw_style_box(UI.box(UI.C_PANEL, edge, bw, UI.RADIUS, 0.93), Rect2(Vector2.ZERO, size))
		var dead := hp <= 0
		var pr := Rect2(6, 6, size.y - 12, size.y - 12)
		draw_rect(pr, UI.C_PANEL_2)
		if portrait:
			draw_texture_rect(portrait, pr, false, Color(1, 1, 1, 0.35 if dead else 1.0))
		draw_rect(pr, edge if active else UI.C_SEP, false, 1.0)
		var x := pr.end.x + 10
		var w := size.x - x - 10
		UI.draw_icon(self, ROLE.get(actor_id, "sword"), Vector2(x + 7, 16), 7.0, UI.C_TEXT_2)
		draw_string(UI.bold(), Vector2(x + 20, 21), display_name, HORIZONTAL_ALIGNMENT_LEFT, w - 20, UI.FS_MAIN, UI.C_TEXT_DIM if dead else UI.C_TEXT)
		var tag := "K.O." if dead else ("Visé" if targeted else ("Garde" if guard else ""))
		if tag != "":
			var tag_col := UI.C_DANGER if (dead or targeted) else UI.C_RESOURCE
			draw_string(UI.bold(), Vector2(x, 21), tag, HORIZONTAL_ALIGNMENT_RIGHT, w, UI.FS_TINY, tag_col)
			if targeted and not dead:
				var tw := UI.bold().get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FS_TINY).x
				UI.draw_icon(self, "warn", Vector2(x + w - tw - 10, 16), 6.0, UI.C_DANGER)
		else:
			draw_string(UI.font(), Vector2(x, 21), weapon, HORIZONTAL_ALIGNMENT_RIGHT, w, UI.FS_TINY, UI.C_TEXT_DIM)
		# PV
		draw_string(UI.font(), Vector2(x, 39), "PV", HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FS_TINY, UI.C_TEXT_2)
		draw_string(UI.font(), Vector2(x, 39), "%d / %d" % [hp, max_hp], HORIZONTAL_ALIGNMENT_RIGHT, w, UI.FS_TINY, UI.C_TEXT)
		var ratio := float(hp) / float(max_hp)
		UI.draw_gauge(self, Rect2(x + 26, 31, w - 96, 7), ratio, _shown_hp / float(max_hp), UI.C_HP_ALLY if ratio > 0.35 else UI.C_DANGER)
		# Résonance (ressource réelle du CombatCore ; repère = coût de la Compétence d'Aether)
		draw_string(UI.font(), Vector2(x, 56), "Rés.", HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FS_TINY, UI.C_TEXT_2)
		draw_string(UI.font(), Vector2(x, 56), "%d / 100" % res, HORIZONTAL_ALIGNMENT_RIGHT, w, UI.FS_TINY, UI.C_TEXT)
		var rr := Rect2(x + 26, 48, w - 96, 7)
		var ready := res >= res_cost and not dead
		UI.draw_gauge(self, rr, res / 100.0, res / 100.0, UI.C_AETHER if ready else UI.C_RESOURCE)
		var mx := rr.position.x + rr.size.x * float(res_cost) / 100.0
		draw_line(Vector2(mx, rr.position.y - 2), Vector2(mx, rr.end.y + 2), UI.C_TEXT, 1.0)
		if ready:
			# compétence disponible : liseré Aether fixe + losange ; une seule montée douce au franchissement du seuil
			draw_rect(rr.grow(1.0), UI.C_AETHER, false, 1.0)
			var k := clampf(_ready_t / 0.6, 0.0, 1.0)
			UI.draw_icon(self, "aether", Vector2(rr.end.x + 8, rr.position.y + 3), 4.0 + 2.0 * k, UI.C_AETHER)
		if _gain_t > 0.0:
			var a := clampf(_gain_t / 0.4, 0.0, 1.0)
			draw_string(UI.bold(), Vector2(rr.position.x + rr.size.x * res / 100.0 + 4, rr.position.y - 2 - (1.2 - _gain_t) * 6.0), "+%d" % _gain, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FS_TINY, Color(UI.C_RESOURCE, a))


class BossBar extends Control:
	var display_name := ""
	var hp := 1
	var max_hp := 1
	var statuses: Array = []
	var _shown := -1.0

	func _process(delta: float) -> void:
		if _shown < 0:
			_shown = float(hp)
		_shown = move_toward(_shown, float(hp), delta * 400.0)
		queue_redraw()

	func _draw() -> void:
		draw_style_box(UI.box(UI.C_BG, UI.C_SEP, 1, UI.RADIUS, 0.85), Rect2(Vector2.ZERO, size))
		var c := Vector2(18, size.y * 0.5)
		UI.draw_icon(self, "aether", c, 9.0, UI.C_BREAK)
		var w := size.x - 44
		draw_string(UI.bold(), Vector2(36, 14), display_name, HORIZONTAL_ALIGNMENT_LEFT, w * 0.6, UI.FS_SMALL, UI.C_TEXT)
		draw_string(UI.font(), Vector2(36, 14), "%d / %d" % [hp, max_hp], HORIZONTAL_ALIGNMENT_RIGHT, w - 8, UI.FS_SMALL, UI.C_TEXT_2)
		UI.draw_gauge(self, Rect2(36, 19, w - 8, 9), float(hp) / float(max_hp), _shown / float(max_hp), UI.C_HP_BOSS)
		# Statuts actifs : rangée de pastilles AU-DESSUS de la barre, alignée à droite (la barre garde sa largeur)
		var x := size.x
		for k in range(statuses.size() - 1, -1, -1):
			var st: Dictionary = statuses[k]
			var tw := UI.font().get_string_size(st["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FS_TINY).x
			var r := Rect2(x - tw - 30, -24, tw + 30, 20)
			draw_style_box(UI.box(UI.C_PANEL, st["color"], 1, 4, 0.95), r)
			UI.draw_icon(self, st["icon"], Vector2(r.position.x + 11, r.position.y + 10), 6.0, st["color"])
			draw_string(UI.font(), Vector2(r.position.x + 22, r.position.y + 14), st["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FS_TINY, UI.C_TEXT)
			x = r.position.x - 6


class ActionRow extends Control:
	signal picked(action_id: String)
	var action_id := ""
	var key := ""
	var label := ""
	var reason := ""
	var enabled := true
	var selected := false
	var _hover := false

	func _ready() -> void:
		mouse_entered.connect(_set_hover.bind(true))
		mouse_exited.connect(_set_hover.bind(false))

	func _set_hover(on: bool) -> void:
		_hover = on
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			picked.emit(action_id)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if selected:
			draw_style_box(UI.box(UI.C_PANEL_2, UI.C_SELECT, 1, 4, 1.0), r)
		elif _hover:
			draw_style_box(UI.box(UI.C_PANEL_2, UI.C_SEP, 1, 4, 0.8), r)
		var col := UI.C_TEXT if enabled else UI.C_TEXT_DIM
		if selected and enabled:
			col = UI.C_SELECT
		draw_string(UI.font(), Vector2(6, 18), key, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.FS_TINY, UI.C_TEXT_DIM)
		UI.draw_icon(self, action_id, Vector2(28, size.y * 0.5), 7.0, col)
		draw_string(UI.bold() if selected else UI.font(), Vector2(44, 18), label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 50, UI.FS_SMALL + 1, col)


class TempoCard extends Control:
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
		var sel: bool = data.get("selected", false)
		var mode: String = data.get("mode", "")
		var col: Color = UI.MODE_COLORS.get(mode, UI.C_TEXT_2)
		var bg := UI.C_PANEL_2 if (sel or (_hover and not static_card)) else UI.C_PANEL
		draw_style_box(UI.box(bg, UI.C_SELECT if sel else UI.C_SEP, 2 if sel else 1, UI.RADIUS, 0.95), Rect2(Vector2.ZERO, size))
		var x := 12.0
		if mode != "":
			# accent de mode : petit, chevrons + liseré court (ne sature pas la carte)
			draw_rect(Rect2(12, 6, 26, 2), col)
			for k in range(UI.MODE_ARROWS[mode]):
				var cx := 16.0 + k * 8.0
				draw_polyline(PackedVector2Array([Vector2(cx, 15), Vector2(cx + 5, 20), Vector2(cx, 25)]), col, 2.0, true)
			x = 46.0
			draw_string(UI.bold(), Vector2(x, 25), UI.MODE_TITLES[mode], HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 8, UI.FS_MAIN, UI.C_SELECT if sel else UI.C_TEXT)
		else:
			draw_string(UI.bold(), Vector2(x, 25), data.get("title", ""), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, UI.FS_MAIN, UI.C_TEXT)
		var y := 45.0
		for line in data.get("lines", []):
			var txt: String = line
			var lc := UI.C_TEXT_2
			if txt.begins_with("+ "):
				lc = UI.C_HEAL
				txt = txt.substr(2)
			elif txt.begins_with("- "):
				lc = UI.C_DANGER
				txt = txt.substr(2)
			draw_string(UI.font(), Vector2(12, y), txt, HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, UI.FS_SMALL, lc)
			y += 16.0
		if not enabled and not static_card:
			draw_rect(Rect2(Vector2.ZERO, size), Color(UI.C_BG, 0.5))
