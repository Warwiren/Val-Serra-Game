extends Control
## P6.2 — DEMANDE DE CONFIRMATION réutilisable (modale) : texte, deux boutons, choix au clavier ou à la souris.
## « Non » est sélectionné par défaut (pas d'activation accidentelle) ; ← / → ou Tab : changer ; Entrée / Espace / E :
## valider ; Échap : non. Émet `repondu(oui)`.

signal repondu(oui: bool)

const UI = preload("res://src/presentation/ui_style.gd")

var _texte: Label
var _oui: Button
var _non: Button
var _sel := 1                             # 0 : oui, 1 : non


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UI.make_theme()
	var voile := ColorRect.new()
	voile.color = Color(UI.C_BG, 0.55)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(voile)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = -80
	panel.offset_bottom = 80
	panel.add_theme_stylebox_override("panel", UI.box(UI.C_PANEL, UI.C_GOLD, 2, 8, 0.97))
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	_texte = Label.new()
	_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texte.custom_minimum_size = Vector2(480, 0)
	_texte.add_theme_font_size_override("font_size", 18)
	v.add_child(_texte)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 16)
	v.add_child(h)
	_oui = Button.new()
	_non = Button.new()
	for b in [_oui, _non]:
		b.custom_minimum_size = Vector2(200, 42)
		b.focus_mode = Control.FOCUS_NONE
		h.add_child(b)
	_oui.pressed.connect(func(): _repondre(true))
	_non.pressed.connect(func(): _repondre(false))
	visible = false


func ouvrir(texte: String, oui := "Oui", non := "Non") -> void:
	_texte.text = texte
	_oui.text = oui
	_non.text = non
	_sel = 1
	_maj()
	visible = true


func est_ouverte() -> bool:
	return visible


func _maj() -> void:
	for i in 2:
		var b: Button = [_oui, _non][i]
		b.add_theme_stylebox_override("normal", UI.box(UI.C_PANEL_2, UI.C_SELECT if i == _sel else UI.C_SEP, 2 if i == _sel else 1))
		b.add_theme_color_override("font_color", UI.C_SELECT if i == _sel else UI.C_TEXT)


func _input(e: InputEvent) -> void:
	if not visible or not (e is InputEventKey) or not e.pressed or e.echo:
		return
	get_viewport().set_input_as_handled()
	match e.keycode:
		KEY_LEFT, KEY_RIGHT, KEY_TAB:
			_sel = 1 - _sel
			_maj()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_repondre(_sel == 0)
		KEY_ESCAPE:
			_repondre(false)
		_:
			if e.physical_keycode == KEY_E:
				_repondre(_sel == 0)


func _repondre(oui: bool) -> void:
	visible = false
	repondu.emit(oui)
