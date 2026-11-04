extends Control
## Écran de combat de DÉBOGAGE (Lot A) : texte et menus simples, aucun graphisme.
## Sert à jouer le CombatCore à la main et à vérifier chronologie, modes, ruptures et Résonance.
## L'écran « présentable » viendra au Lot B, branché sur le même CombatCore.

const BattleFactory = preload("res://src/combat/battle_factory.gd")
const Battle = preload("res://src/combat/core/battle.gd")

const COL_HUNTER := "#8EC9FF"
const COL_MONSTER := "#FF8A7A"
const COL_HYPO := "#FFE07A"
const COL_DIM := "#9A9AA8"

var battle: Battle
var _journal_shown := 0

var _timeline: RichTextLabel
var _party: RichTextLabel
var _monster: RichTextLabel
var _journal: RichTextLabel
var _actor_label: Label
var _action_opt: OptionButton
var _mode_opt: OptionButton
var _target_opt: OptionButton
var _preview: RichTextLabel
var _confirm: Button


func _ready() -> void:
	_build_ui()
	_new_battle()


func _new_battle() -> void:
	battle = BattleFactory.create_default()
	_journal_shown = 0
	_journal.clear()
	battle.start()
	_refresh()


# ---------------------------------------------------------------------------
# Construction de l'interface (en code, pour rester lisible et modifiable)
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#15161c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Val'Serra — CombatCore (Lot A, écran de débogage)"
	title.add_theme_font_size_override("font_size", 20)
	root.add_child(title)

	_timeline = _rich(root, 64)

	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 12)
	root.add_child(middle)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(430, 0)
	middle.add_child(left)
	_party = _rich(left, 160)
	_monster = _rich(left, 230)

	_journal = _rich(middle, 0)
	_journal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_journal.scroll_following = true

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	root.add_child(bar)
	_actor_label = Label.new()
	_actor_label.custom_minimum_size = Vector2(230, 0)
	bar.add_child(_actor_label)
	_action_opt = OptionButton.new()
	_action_opt.custom_minimum_size = Vector2(230, 0)
	_action_opt.item_selected.connect(func(_i): _on_action_changed())
	bar.add_child(_action_opt)
	_mode_opt = OptionButton.new()
	_mode_opt.custom_minimum_size = Vector2(120, 0)
	_mode_opt.item_selected.connect(func(_i): _update_preview())
	bar.add_child(_mode_opt)
	_target_opt = OptionButton.new()
	_target_opt.custom_minimum_size = Vector2(260, 0)
	_target_opt.item_selected.connect(func(_i): _update_preview())
	bar.add_child(_target_opt)
	_confirm = Button.new()
	_confirm.text = "Valider (Entrée)"
	_confirm.pressed.connect(_on_confirm)
	bar.add_child(_confirm)
	var restart := Button.new()
	restart.text = "Recommencer"
	restart.pressed.connect(_new_battle)
	bar.add_child(restart)

	_preview = _rich(root, 54)


func _rich(parent: Node, min_h: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.custom_minimum_size = Vector2(0, min_h)
	r.add_theme_font_size_override("normal_font_size", 14)
	r.add_theme_font_size_override("bold_font_size", 14)
	parent.add_child(r)
	return r


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_confirm()


# ---------------------------------------------------------------------------
# Affichage
# ---------------------------------------------------------------------------

func _refresh() -> void:
	_draw_party()
	_draw_monster()
	_draw_journal()
	_fill_actions()
	_update_preview()


func _draw_party() -> void:
	var t := "[b]Chasseurs[/b]   (potions : %d)\n" % int(battle.inventory.get("potion", 0))
	for h in battle.hunters():
		var mark := "▶ " if h == battle.current_actor else "   "
		var status := ""
		if not h.is_alive():
			status = " [color=%s](hors de combat)[/color]" % COL_DIM
		elif h.guard_active:
			status = " [GARDE]"
		t += "%s[color=%s]%s[/color] — %s, V%d C%d%s\n" % [mark, COL_HUNTER, h.name, h.weapon_name,
			h.speed(battle.rules), h.cycle(battle.rules), status]
		t += "      PV %s %d/%d   Résonance %s %d\n" % [_bar(h.hp, h.max_hp, 12), h.hp, h.max_hp,
			_bar(h.resonance, 100, 8), h.resonance]
	_party.text = t


func _draw_monster() -> void:
	var t := ""
	for m in battle.monsters():
		t += "[b][color=%s]%s[/color][/b]  PV %s %d/%d   Déf %d   V%d (C=%d)\n" % [COL_MONSTER, m.name,
			_bar(m.hp, m.max_hp, 14), m.hp, m.max_hp, m.effective_defense(), m.speed(battle.rules), m.cycle(battle.rules)]
		if m.pending_cast != null:
			var c = m.pending_cast
			t += "   [color=%s]%s %s → effet à t=%d[/color]\n" % [COL_HYPO, "⚠ ANNONCE" if c.telegraph else "prépare",
				c.action_name, c.resolve_at]
		for p in m.parts:
			var state := "[color=%s]BRISÉE[/color]" % COL_DIM if p.broken else "%s %d/%d" % [_bar(p.integrity, p.max_integrity, 10), p.integrity, p.max_integrity]
			t += "   • %s : %s   [color=%s]%s[/color]\n" % [p.name, state, COL_DIM, _affinity_text(p)]
	_monster.text = t


func _affinity_text(p) -> String:
	var parts: Array = []
	for k in p.affinities:
		var v := float(p.affinities[k])
		if v > 1.0:
			parts.append("faible %s" % k)
		elif v < 1.0:
			parts.append("résiste %s" % k)
	return ", ".join(PackedStringArray(parts))


func _draw_journal() -> void:
	while _journal_shown < battle.journal.size():
		var e: Dictionary = battle.journal[_journal_shown]
		_journal_shown += 1
		var col := "#DDDDDD"
		match e["type"]:
			"break", "victory":
				col = "#7CFC9A"
			"interrupt", "defeat", "defeated":
				col = "#FF7A7A"
			"turn":
				col = COL_DIM
			"cast":
				col = COL_HYPO if e["data"].get("telegraph", false) else "#DDDDDD"
		_journal.append_text("[color=%s][t=%d] %s[/color]\n" % [col, e["t"], e["text"]])


func _bar(value: int, maximum: int, width: int) -> String:
	var filled := 0 if maximum <= 0 else clampi(roundi(float(value) / float(maximum) * width), 0, width)
	return "[" + "█".repeat(filled) + "·".repeat(width - filled) + "]"


# ---------------------------------------------------------------------------
# Commandes
# ---------------------------------------------------------------------------

func _fill_actions() -> void:
	_action_opt.clear()
	var a = battle.current_actor
	var active := a != null and not battle.is_over()
	for ctrl in [_action_opt, _mode_opt, _target_opt, _confirm]:
		ctrl.disabled = not active
	if not active:
		_actor_label.text = _end_text()
		_mode_opt.clear()
		_target_opt.clear()
		return
	_actor_label.text = "t=%d — À %s" % [battle.now, a.name]
	for aid in a.action_ids:
		_action_opt.add_item(battle.actions[aid]["name"])
		_action_opt.set_item_metadata(_action_opt.item_count - 1, aid)
	_on_action_changed()


func _end_text() -> String:
	match battle.state:
		Battle.State.VICTORY:
			return "VICTOIRE !"
		Battle.State.DEFEAT:
			return "DÉFAITE"
		Battle.State.ABORTED:
			return "Combat interrompu"
	return ""


func _on_action_changed() -> void:
	if battle.current_actor == null or _action_opt.item_count == 0:
		return
	var aid: String = _action_opt.get_item_metadata(_action_opt.selected)
	var def: Dictionary = battle.actions[aid]
	_mode_opt.clear()
	for mode in def.get("modes", []):
		_mode_opt.add_item(battle.rules["modes"][mode]["label"])
		_mode_opt.set_item_metadata(_mode_opt.item_count - 1, mode)
		if mode == def.get("default_mode", ""):
			_mode_opt.select(_mode_opt.item_count - 1)
	_mode_opt.disabled = _mode_opt.item_count == 0
	_target_opt.clear()
	match def.get("target", "self"):
		"enemy_part":
			for m in battle.monsters(true):
				for p in m.parts:
					_target_opt.add_item("%s — %s%s" % [m.name, p.name, " (brisée)" if p.broken else ""])
					_target_opt.set_item_metadata(_target_opt.item_count - 1, {"target": m.id, "part": p.id})
		"ally":
			for h in battle.hunters(true):
				_target_opt.add_item("%s (%d/%d PV)" % [h.name, h.hp, h.max_hp])
				_target_opt.set_item_metadata(_target_opt.item_count - 1, {"target": h.id})
	_target_opt.disabled = _target_opt.item_count == 0
	_update_preview()


func _current_cmd() -> Dictionary:
	if battle.current_actor == null or _action_opt.item_count == 0:
		return {}
	var cmd := {"action": _action_opt.get_item_metadata(_action_opt.selected)}
	if _mode_opt.item_count > 0:
		cmd["mode"] = _mode_opt.get_item_metadata(_mode_opt.selected)
	if _target_opt.item_count > 0:
		cmd.merge(_target_opt.get_item_metadata(_target_opt.selected))
	return cmd


func _update_preview() -> void:
	var cmd := _current_cmd()
	_draw_timeline(cmd)
	if cmd.is_empty():
		_preview.text = ""
		return
	var a = battle.current_actor
	var err := battle.validate(a, cmd)
	if err != "":
		_preview.text = "[color=#FF7A7A]%s[/color]" % err
		return
	var est: Dictionary = battle.estimate(a, cmd)
	var t := "[b]Aperçu[/b] — effet à [color=%s]t=%d[/color], prochain tour de %s à t=%d." % [COL_HYPO,
		est["resolve_at"], a.name, est["next_decision"]]
	if est["damage"] > 0 or est["break"] > 0:
		t += "  Dégâts ≈ %d, rupture %d." % [est["damage"], est["break"]]
	if est["heal"] > 0:
		t += "  Soin %d." % est["heal"]
	if est["delay"] > 0:
		t += "  Recule le monstre d'environ %d." % est["delay"]
	for m in battle.monsters(true):
		if m.pending_cast != null and m.pending_cast.telegraph:
			var before: bool = est["resolve_at"] < m.pending_cast.resolve_at
			t += "\n%s" % ("[color=#7CFC9A]✔ Votre effet arrive AVANT %s (t=%d).[/color]" % [m.pending_cast.action_name, m.pending_cast.resolve_at] if before
				else "[color=#FF7A7A]✘ Votre effet arrive APRÈS %s (t=%d).[/color]" % [m.pending_cast.action_name, m.pending_cast.resolve_at])
	_preview.text = t


func _draw_timeline(cmd: Dictionary) -> void:
	if battle.is_over():
		_timeline.text = "[b]Chronologie[/b]\nCombat terminé : %s. Cliquez sur « Recommencer » pour rejouer." % _end_text()
		return
	var events: Array = battle.preview_timeline(9, cmd)
	var chunks: Array = []
	for e in events:
		var who = battle.get_combatant(e["actor_id"])
		var col := COL_HUNTER if who.is_hunter() else COL_MONSTER
		if e["kind"] == Battle.EV_RESOLVE:
			var c = e["cast"]
			if e["hypothetical"]:
				col = COL_HYPO
			var label: String = c.action_name + (" ⚠" if c.telegraph else "")
			chunks.append("[color=%s]t%d ✦ %s : %s[/color]" % [col, e["time"], who.name, label])
		else:
			chunks.append("[color=%s]t%d ▶ %s[/color]" % [col, e["time"], who.name])
	_timeline.text = "[b]Chronologie[/b] (✦ effet, ▶ décision, jaune = votre choix)\n" + "   ".join(PackedStringArray(chunks))


func _on_confirm() -> void:
	if battle.current_actor == null or battle.is_over():
		return
	var err := battle.submit(_current_cmd())
	if err != "":
		_preview.text = "[color=#FF7A7A]%s[/color]" % err
		return
	_refresh()
