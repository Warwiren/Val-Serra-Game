extends "res://scenes/battle/battle_scene.gd"
## P6 — COMBAT TUTORIEL du Colisée : Aren seul contre le commandant de la Guilde.
## Réutilise la scène de combat du prototype (HUD, frise d'initiative, menu d'actions, ciblage, animations) et le
## CombatCore SANS MODIFICATION de ses règles :
##   - groupe : « heros » seul (aucun compagnon) ; adversaire : data/combat/monster_commandant.json ;
##   - le commandant ne perd pas de PV par ses données (affinités et résistance nulles) : les coups sont « parés » ;
##   - ses coups sont retenus : le joueur ne peut pas perdre (vérifié par tests/p6_tutoriel_smoke.gd) ;
##   - un guide (src/tutorial/guide_interface.gd) déroule data/p6/tutoriel_colisee.json : explications avec mise en
##     évidence des composants réels du HUD, actions demandées (les autres sont refusées par une réplique) ;
##   - fin scénarisée : résultat « tutorial_completed » (ni victoire ni défaite, ni récompense), retour au Colisée.

const Guide = preload("res://src/tutorial/guide_interface.gd")
const CommandantView = preload("res://src/presentation/commandant_view.gd")
const Progression = preload("res://src/game/progression.gd")
const GardeFou = preload("res://src/tutorial/garde_fou.gd")
const Confirmation = preload("res://src/tutorial/confirmation.gd")
const ETAPES := "res://data/p6/tutoriel_colisee.json"
const MONSTRE := "res://data/combat/monster_commandant.json"
const DECOR := "res://art/p6/combat/arene_colisee.png"
const POS_HEROS := Vector2(430, 520)
const POS_COMMANDANT := Vector2(860, 522)
const ORDRE_PARTIES := ["heaume", "plastron", "bouclier"]

var guide
var _def := {}
var _etapes: Array = []
var _i := 0                               # étape courante
var _tour := 0                            # tours du joueur commencés
var _attend_action := false
var _termine := false
var _trace: Array = []                    # déroulé (tests, rapport) : étapes montrées, cibles, refus
var _hp_min := 999999
var _cli_auto := false
var _attaque_base := 0
var _confirm_box
var _bouton_passer: Button
var _saute := false


func _ready() -> void:
	_def = JSON.parse_string(FileAccess.open(ETAPES, FileAccess.READ).get_as_text())
	_etapes = _def["etapes"]
	_cli_auto = GameState.autoplay or OS.get_cmdline_user_args().has("--tuto-auto")
	GameState.proto = true
	var data := BattleFactory.load_default_data()
	data["monster"] = BattleFactory.load_json(MONSTRE)
	battle = BattleFactory.create(data, ["heros"], {"potion": GameState.potions})
	battle.get_combatant("heros").name = GameState.hero_name
	monster_id = battle.monsters()[0].id
	_attaque_base = battle.get_combatant(monster_id).attack
	_build_world()
	_build_hud()
	guide = Guide.new()
	var calque := CanvasLayer.new()
	calque.layer = 20                     # au-dessus du HUD de combat (10), sous le fondu de GameState (100)
	add_child(calque)
	calque.add_child(guide)
	guide.resoudre = _rect_cible
	guide.orateur = _def.get("orateur", "Commandant")
	guide.portrait_id = _def.get("portrait", "pnj")
	guide.advanced.connect(_suite)
	guide.escape_pressed.connect(_echap)
	# P6.2 : passer le tutoriel (bouton visible + Échap), avec confirmation (« Non » par défaut)
	_bouton_passer = Button.new()
	_bouton_passer.text = "Passer le tutoriel  (Échap)"
	_bouton_passer.focus_mode = Control.FOCUS_NONE
	_bouton_passer.position = Vector2(16, 70)
	_bouton_passer.add_theme_font_size_override("font_size", 14)
	_bouton_passer.pressed.connect(_echap)
	calque.add_child(_bouton_passer)
	_confirm_box = Confirmation.new()
	calque.add_child(_confirm_box)
	_confirm_box.repondu.connect(_on_confirmation)
	battle.start()
	_trace.append({"type": "debut", "groupe": battle.hunters().map(func(h): return h.id), "adversaire": monster_id})
	await get_tree().create_timer(0.4).timeout
	_play_pending()


# ---------------------------------------------------------------------------- monde (décor du Colisée)
func _build_world() -> void:
	if ResourceLoader.exists(DECOR):
		var bg := Sprite2D.new()
		bg.texture = load(DECOR)
		bg.centered = false
		bg.z_index = -100
		add_child(bg)
	else:
		var fond := ColorRect.new()
		fond.color = Color(0.42, 0.36, 0.3)
		fond.size = Vector2(1280, 720)
		fond.z_index = -100
		add_child(fond)
	actors = Node2D.new()
	add_child(actors)
	var overlay := CanvasLayer.new()
	overlay.layer = 1
	overlay.follow_viewport_enabled = true
	add_child(overlay)
	fx = Node2D.new()
	overlay.add_child(fx)
	var mv := CommandantView.new()
	monster_view = mv
	actors.add_child(monster_view)
	monster_view.compact = true
	monster_view.setup(POS_COMMANDANT, 1.0, fx)
	monster_view.z_index = int(POS_COMMANDANT.y / 10.0) - 2
	for c in battle.hunters():
		var hv := ProtoHero.new()
		actors.add_child(hv)
		hv.setup(c.id, {"sprite": PROTO_SPRITES[c.id], "combat": true}, POS_HEROS)
		hv.scale.x = 1
		hv.z_index = int(POS_HEROS.y / 10.0)
		hunters[c.id] = hv
	cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)
	cam.make_current()
	for c in battle.combatants:
		disp_hp[c.id] = c.hp
		disp_max[c.id] = c.max_hp
		disp_res[c.id] = c.resonance
		disp_guard[c.id] = false
	_sync_parts()


func _build_hud() -> void:
	GameState.arena = "colisee"
	super._build_hud()
	hud.timeline.short_names[monster_id] = "Commandant"
	if hud.has_method("set_monster"):
		hud.set_monster(battle.get_combatant(monster_id).name, battle.get_combatant(monster_id).max_hp)


func _monster_icon() -> Texture2D:
	return Portraits.get_texture("pnj")


## Rectangle (coordonnées du calque du guide = écran) d'une cible du tutoriel.
func _rect_cible(cle: String) -> Rect2:
	if cle == "adversaire":
		return monster_view.screen_rect()
	var c: Control = hud.guide_target(cle) if hud.has_method("guide_target") else null
	if c == null or not c.is_visible_in_tree():
		return Rect2()
	return c.get_global_rect()


# ---------------------------------------------------------------------------- déroulé
func _play(e: Dictionary) -> void:
	var d: Dictionary = e["data"]
	match e["type"]:
		"start":
			hud.banner("Évaluation — %s" % battle.get_combatant(monster_id).name, Color("#f2c978"), 0.9)
			await _wait(1.1)
			return
		"damage":
			if d.get("target", "") == monster_id and int(d.get("amount", 0)) == 0:
				disp_hp[monster_id] = int(d.get("hp", disp_hp[monster_id]))
				monster_view.hurt(_last_hit_part(), false)
				Fx.float_text(fx, monster_view.center() + Vector2(0, -60), "Paré !", Color("#f2c978"), 30)
				_trace.append({"type": "pare", "pv_commandant": int(d.get("hp", 0))})
				await _wait(0.35)
				return
	await super._play(e)
	if e["type"] == "damage" and d.get("target", "") == "heros":
		_hp_min = mini(_hp_min, int(d.get("hp", _hp_min)))


func _setup_turn() -> void:
	GardeFou.borner(battle, "heros", monster_id, _attaque_base)
	super._setup_turn()
	if _termine:
		return
	_tour += 1
	_attend_action = false
	_trace.append({"type": "tour", "n": _tour, "t": battle.now, "pv_heros": battle.get_combatant("heros").hp,
		"pv_commandant": battle.get_combatant(monster_id).hp})
	_montrer_etape()


func _montrer_etape() -> void:
	if _i >= _etapes.size():
		_terminer()
		return
	var et: Dictionary = _etapes[_i]
	if int(et.get("tour", _tour)) > _tour:
		# étape du tour suivant : on laisse jouer (ne devrait pas arriver : chaque tour finit par une action demandée)
		guide.masquer()
		hud.set_input_enabled(true)
		return
	var m := "action" if et.get("attendre", "suite") == "action" else "suite"
	_attend_action = m == "action"
	if et.has("selection") and battle.current_actor != null:
		sel_action = et["selection"]           # montre le composant dont on parle (ex. cartes de tempo)
	hud.set_input_enabled(true)
	_refresh_selection()
	hud.set_input_enabled(m == "action")
	guide.montrer(et["texte"], et.get("cibles", []), m)
	_trace.append({"type": "etape", "id": et["id"], "tour": _tour, "mode": m, "cibles": et.get("cibles", []),
		"rects": guide.rects().map(func(r): return [roundi(r.position.x), roundi(r.position.y), roundi(r.size.x), roundi(r.size.y)])})
	if OS.get_cmdline_user_args().has("--tuto-passer-auto"):
		_demo_saut()
		return
	if _cli_auto:
		_auto_etape(et)


func _suite() -> void:
	if _attend_action or _termine:
		return
	var et: Dictionary = _etapes[_i]
	_i += 1
	if et.get("fin", false):
		_terminer()
		return
	_montrer_etape()


func _confirm() -> void:
	if busy or battle.state != Battle.State.AWAITING_COMMAND or _termine:
		return
	if not _attend_action:
		guide.interjection(_def["interjections"]["attendre"])
		return
	var et: Dictionary = _etapes[_i]
	if not (et.get("actions", []) as Array).has(sel_action):
		guide.interjection(et.get("refus", "Pas cette action pour l'instant."))
		_trace.append({"type": "refus", "etape": et["id"], "action": sel_action})
		return
	_trace.append({"type": "action", "etape": et["id"], "action": sel_action, "partie": sel_part})
	_attend_action = false
	_i += 1
	guide.masquer()
	GardeFou.borner(battle, "heros", monster_id, _attaque_base)
	super._confirm()


func _unhandled_input(event: InputEvent) -> void:
	if _termine or _confirm_box.est_ouverte():
		return
	if not _attend_action:
		return                              # explication en cours : le guide a la main
	super._unhandled_input(event)


func _cycle_target(dir: int) -> void:
	if _target_kind() == "enemy_part":
		sel_part = ORDRE_PARTIES[(ORDRE_PARTIES.find(sel_part) + dir + ORDRE_PARTIES.size()) % ORDRE_PARTIES.size()]
		_refresh_selection()
		return
	super._cycle_target(dir)


func _echap() -> void:
	if _termine or _confirm_box.est_ouverte():
		return
	_trace.append({"type": "demande_saut"})
	_confirm_box.ouvrir("Passer le tutoriel ?\nL'évaluation sera considérée comme terminée (aucune récompense).", "Oui, passer", "Non, continuer")


func _on_confirmation(oui: bool) -> void:
	_trace.append({"type": "saut_confirme" if oui else "saut_annule"})
	if oui:
		_saute = true
		_terminer()
	elif guide.visible:
		guide.interjection(_def["interjections"]["quitter"])


## Échap quand le guide est masqué (animations entre deux tours) : même demande de confirmation.
func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE and not _termine and not _confirm_box.est_ouverte():
		get_viewport().set_input_as_handled()
		_echap()


## Sécurité : le combat ne peut pas se terminer « normalement » ; si cela arrivait, on clôt l'évaluation quand même.
func _show_result() -> void:
	_trace.append({"type": "fin_anormale", "etat": battle.state})
	_terminer()


func _terminer() -> void:
	if _termine:
		return
	_termine = true
	hud.set_input_enabled(false)
	var fin_txt := ""
	for et in _etapes:
		if et.get("fin", false):
			fin_txt = et["texte"]
	if _saute:
		fin_txt = _def["interjections"].get("saut", fin_txt)
		guide.montrer(fin_txt, [], "action")
	elif guide.mode == "" and fin_txt != "":
		guide.montrer(fin_txt, [], "suite")
	_bouton_passer.visible = false
	_trace.append({"type": "fin", "saute": _saute, "resultat": Progression.RESULTAT_TUTORIEL, "pv_heros": battle.get_combatant("heros").hp,
		"pv_commandant": battle.get_combatant(monster_id).hp, "etat_combat": battle.state})
	await _wait(1.6 if _saute else 0.6)
	guide.masquer()
	hud.banner("Évaluation terminée", Color("#f2c978"), 1.0)
	if OS.get_cmdline_user_args().has("--tuto-trace"):
		print("P6 TUTORIEL ", JSON.stringify(_trace))
	await _wait(1.3)
	if OS.get_cmdline_user_args().has("--tuto-quit"):
		get_tree().quit()
		return
	# conclusion commune (fin normale, saut pendant le combat, saut dans le dialogue) : résultat « tutorial_completed »,
	# ni victoire ni défaite, aucune récompense, potions inchangées, retour au Colisée
	Progression.conclure_tutoriel()


func trace() -> Array:
	return _trace


func etape_courante() -> String:
	return _etapes[_i]["id"] if _i < _etapes.size() else ""


# ---------------------------------------------------------------------------- démonstration automatique
## Joue l'étape comme un joueur (démo vidéo, tests) : lit, puis choisit l'action demandée et confirme.
func _auto_etape(et: Dictionary) -> void:
	if _termine:
		return
	var rapide := OS.get_cmdline_user_args().has("--tuto-rapide")
	var id: String = et["id"]
	while not rapide and not guide.texte_complet():
		await _wait(0.1)
	await _wait(2.2 if not rapide else 0.15)
	if _termine or etape_courante() != id:
		return
	if et.get("attendre", "suite") != "action":
		guide.simuler_suite()
		return
	var voulue: String = et["actions"][0]
	if OS.get_cmdline_user_args().has("--tuto-erreur") and et["id"] == "attaque" and not _trace.any(func(x): return x["type"] == "refus"):
		sel_action = "garde"                # vérifie le refus d'une action non prévue
		_refresh_selection()
		_confirm()
		await _wait(0.3)
	sel_action = voulue
	_refresh_selection()
	await _wait(0.6 if not OS.get_cmdline_user_args().has("--tuto-rapide") else 0.05)
	_confirm()


## Démonstration filmée du saut : Échap après la première explication, confirmation, « Oui ».
func _demo_saut() -> void:
	if _trace.any(func(e): return e["type"] == "demande_saut"):
		return
	await _wait(2.5)
	_echap()
	await _wait(1.0)
	_confirm_box._sel = 0
	_confirm_box._maj()
	await _wait(1.2)
	_confirm_box._repondre(true)


func _auto_turn() -> void:
	pass                                    # le guide pilote la démonstration (pas la politique de test)
