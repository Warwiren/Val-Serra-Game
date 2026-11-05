extends Node2D
## Scène de combat présentable (Lot B).
## Principe : le CombatCore calcule tout ; cette scène TRADUIT son journal d'événements en animations,
## dans l'ordre. Les variantes de rendu A (2D) et B (2.5D) ne changent que le décor et l'éclairage.

const BattleFactory = preload("res://src/combat/battle_factory.gd")
const Battle = preload("res://src/combat/core/battle.gd")
const AutoPolicy = preload("res://src/combat/auto_policy.gd")
const Art = preload("res://src/presentation/art.gd")
const Fx = preload("res://src/presentation/fx.gd")
const Stage = preload("res://src/presentation/stage.gd")
const HunterView = preload("res://src/presentation/hunter_view.gd")
const MonsterView = preload("res://src/presentation/monster_view.gd")
const BattleHud = preload("res://src/presentation/battle_hud.gd")
const RigHunterView = preload("res://src/presentation/rig_hunter_view.gd")
const RigMonsterView = preload("res://src/presentation/rig_monster_view.gd")
const SpriteHunterView = preload("res://src/presentation/sprite_hunter_view.gd")
const SpriteMonsterView = preload("res://src/presentation/sprite_monster_view.gd")
const HUNTER_POS_PX := {"compagnon_vif": Vector2(225, 510), "heros": Vector2(405, 552), "compagnon_lourd": Vector2(585, 512)}
const MONSTER_POS_PX := Vector2(935, 548)
const ProtoHero = preload("res://src/proto/pack_hunter_view.gd")
const CombatHud = preload("res://src/presentation/combat_hud.gd")
const UI = preload("res://src/presentation/ui_style.gd")
## Prototype recentré : groupe à droite tourné vers la gauche, monstre à gauche (maquette du pack, Octopath).
const HUNTER_POS_PROTO := {"heros": Vector2(900, 500), "compagnon_vif": Vector2(1028, 468), "compagnon_lourd": Vector2(1150, 492)}
const MONSTER_POS_PROTO := Vector2(330, 506)
const PROTO_SPRITES := {"heros": "aren", "compagnon_vif": "ilya", "compagnon_lourd": "throne"}
const PROTO_NAMES := {"heros": "Aren", "compagnon_vif": "Ilya", "compagnon_lourd": "Throné"}

## Prototype artistique : positions légèrement différentes (personnages plus grands).
const HUNTER_POS_HD := {
	"compagnon_vif": Vector2(240, 500),
	"heros": Vector2(420, 552),
	"compagnon_lourd": Vector2(585, 506),
}
const MONSTER_POS_HD := Vector2(1010, 534)

const HUNTER_POS := {
	"compagnon_vif": Vector2(250, 494),
	"heros": Vector2(398, 534),
	"compagnon_lourd": Vector2(548, 500),
}
const MONSTER_POS := Vector2(940, 514)
const MODE_COLORS := {"VIF": Color("#7fe6ff"), "MESURE": Color("#d5e2ee"), "CHARGE": Color("#ffb05a")}
const MODE_TITLES := {"VIF": "VIF  »»»", "MESURE": "MESURÉ  »»", "CHARGE": "CHARGÉ  »"}

var battle: Battle
var stage: Stage
var hud: BattleHud
var cam: Camera2D
var actors: Node2D
var fx: Node2D
var hunters: Dictionary = {}
var monster_view: MonsterView
var monster_id := ""

# Affichage progressif (mis à jour événement par événement)
var disp_hp: Dictionary = {}
var disp_max: Dictionary = {}
var disp_res: Dictionary = {}
var disp_guard: Dictionary = {}
var view_now := 0
var tele_resolve := -1
var tele_name := ""

# Sélection du joueur
var sel_action := "attaque"
var sel_mode := "MESURE"
var sel_part := ""
var sel_ally := ""

var busy := false
var _journal_pos := 0
var _drift_t := 0.0
var _shake := 0.0
var _cam_target_offset := Vector2.ZERO


func _ready() -> void:
	battle = BattleFactory.create_default({"potion": GameState.potions})
	battle.get_combatant("heros").name = GameState.hero_name
	if GameState.proto:
		for id in PROTO_NAMES:
			battle.get_combatant(id).name = PROTO_NAMES[id]
	monster_id = battle.monsters()[0].id
	_build_world()
	_build_hud()
	GameState.render_mode_changed.connect(_on_render_mode)
	_on_render_mode(GameState.render_mode)
	battle.start()
	await get_tree().create_timer(0.4).timeout
	_play_pending()


# ---------------------------------------------------------------------------
# Construction
# ---------------------------------------------------------------------------

func _build_world() -> void:
	if GameState.proto:
		_build_world_proto()
		return
	stage = Stage.new()
	if GameState.art_proto or GameState.hd2d:
		_configure_hd_stage()
		if GameState.hd2d:
			stage.pixelate = 3
	else:
		stage.light_points = [
		{"pos": Vector2(136, 312), "color": Color(1.0, 0.72, 0.4), "energy": 1.3, "size": 2.4},
		{"pos": Vector2(400, 380), "color": Color(1.0, 0.86, 0.66), "energy": 0.55, "size": 4.5},
		{"pos": Vector2(800, 380), "color": Color(0.4, 0.9, 1.0), "energy": 0.75, "size": 3.6},
		{"pos": Vector2(520, 470), "color": Color(0.5, 0.95, 1.0), "energy": 0.6, "size": 1.4},
		{"pos": Vector2(1180, 480), "color": Color(0.5, 0.95, 1.0), "energy": 0.6, "size": 1.6},
		]
	add_child(stage)

	actors = Node2D.new()
	add_child(actors)
	stage.build(self)

	# Couche d'effets non assombrie, qui suit la caméra (textes, particules, marqueurs)
	var overlay := CanvasLayer.new()
	overlay.layer = 1
	overlay.follow_viewport_enabled = true
	add_child(overlay)
	fx = Node2D.new()
	overlay.add_child(fx)

	var hpos: Dictionary = HUNTER_POS_PX if GameState.hd2d else (HUNTER_POS_HD if GameState.art_proto else HUNTER_POS)
	var mpos: Vector2 = MONSTER_POS_PX if GameState.hd2d else (MONSTER_POS_HD if GameState.art_proto else MONSTER_POS)
	if GameState.hd2d:
		monster_view = SpriteMonsterView.new()
	else:
		monster_view = RigMonsterView.new() if GameState.art_proto else MonsterView.new()
	actors.add_child(monster_view)
	monster_view.setup(mpos, 0.76 if GameState.art_proto else 0.88, fx)
	for c in battle.hunters():
		var hv
		if GameState.hd2d and c.id == "heros":
			hv = SpriteHunterView.new()
			actors.add_child(hv)
			hv.setup(c.id, Art.hunter(c.id, GameState.hero_gender), hpos[c.id], 0.8)
		elif GameState.art_proto and c.id == "heros":
			hv = RigHunterView.new()
			actors.add_child(hv)
			hv.setup(c.id, Art.hunter(c.id, GameState.hero_gender), hpos[c.id], 0.74)
		else:
			hv = HunterView.new()
			actors.add_child(hv)
			hv.setup(c.id, Art.hunter(c.id, GameState.hero_gender), hpos[c.id], 0.78)
		hv.z_index = int(hpos[c.id].y / 10.0)
		hunters[c.id] = hv
	monster_view.z_index = int(mpos.y / 10.0) - 2

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


## Prototype recentré : le combat a lieu dans la clairière de la zone (même décor, même grille de pixels).
func _build_world_proto() -> void:
	var bg := Sprite2D.new()
	bg.texture = load("res://art/proto/zone_bg.png")
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.centered = false
	bg.scale = Vector2(3, 3)
	bg.z_index = -100
	add_child(bg)
	var cm := CanvasModulate.new()
	cm.color = Color(0.8, 0.8, 0.92)
	add_child(cm)
	for lp in [Vector2(60, 212), Vector2(683, 282), Vector2(951, 266), Vector2(1068, 262)]:
		var l := PointLight2D.new()
		l.texture = Fx.glow_texture(256)
		l.position = lp
		l.color = Color(1.0, 0.72, 0.38)
		l.energy = 0.55
		l.texture_scale = 1.5
		add_child(l)
	actors = Node2D.new()
	add_child(actors)
	var overlay := CanvasLayer.new()
	overlay.layer = 1
	overlay.follow_viewport_enabled = true
	add_child(overlay)
	fx = Node2D.new()
	overlay.add_child(fx)
	var mv := SpriteMonsterView.new()
	mv.sprite_dir = "res://art/proto/vorgane_nuit/"
	mv.facing_right = true
	monster_view = mv
	actors.add_child(monster_view)
	monster_view.compact = true
	monster_view.setup(MONSTER_POS_PROTO, 1.0, fx)
	monster_view.z_index = int(MONSTER_POS_PROTO.y / 10.0) - 2
	for c in battle.hunters():
		var hv := ProtoHero.new()
		actors.add_child(hv)
		hv.setup(c.id, {"sprite": PROTO_SPRITES[c.id]}, HUNTER_POS_PROTO[c.id])
		hv.scale.x = -1
		hv.z_index = int(HUNTER_POS_PROTO[c.id].y / 10.0)
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


func _portrait(id: String) -> Texture2D:
	if GameState.proto:
		return load("res://art/proto/portrait_%s.png" % PROTO_SPRITES[id])
	return load(Art.hunter(id, GameState.hero_gender)["portrait"])


func _monster_icon() -> Texture2D:
	if not GameState.proto:
		return load(Art.MONSTER["portrait"])
	# Icône tirée du sprite lui-même : la tête, autour du point « gueule »
	var mv: SpriteMonsterView = monster_view
	var a: Array = mv.anchors["idle_001"]["gueule"]
	var at := AtlasTexture.new()
	at.atlas = load("res://art/proto/vorgane_nuit/base/idle_001.png")
	at.region = Rect2(a[0] - 12, a[1] - 26, 40, 40)
	return at


func _configure_hd_stage() -> void:
	stage.layer_defs = Stage.HD_LAYERS
	stage.front_def = Stage.HD_FRONT
	stage.rays_path = Stage.HD_RAYS
	stage.ambient = Color(0.62, 0.66, 0.84)
	stage.mist_color = Color(0.5, 0.64, 0.9, 0.12)
	stage.fog_color = Color(0.13, 0.19, 0.32)
	stage.light_points = [
		{"pos": Vector2(190, 270), "color": Color(1.0, 0.72, 0.38), "energy": 1.2, "size": 2.6},
		{"pos": Vector2(400, 410), "color": Color(1.0, 0.75, 0.42), "energy": 1.0, "size": 2.0},
		{"pos": Vector2(1000, 420), "color": Color(1.0, 0.75, 0.42), "energy": 1.0, "size": 2.0},
		{"pos": Vector2(690, 210), "color": Color(0.7, 0.8, 1.0), "energy": 0.6, "size": 6.0},
		{"pos": Vector2(170, 560), "color": Color(0.45, 0.95, 1.0), "energy": 0.9, "size": 1.6},
		{"pos": Vector2(1250, 560), "color": Color(0.45, 0.95, 1.0), "energy": 0.9, "size": 1.6},
		{"pos": Vector2(860, 400), "color": Color(0.5, 0.85, 1.0), "energy": 0.6, "size": 3.5},
		{"pos": Vector2(420, 430), "color": Color(0.85, 0.9, 1.0), "energy": 0.35, "size": 4.0},
	]


## Éclair lumineux ponctuel (impact d'Aether, rupture) : réellement éclaire le décor en rendu B.
func light_flash(pos: Vector2, color: Color, energy := 2.5, size := 4.0, duration := 0.5) -> void:
	var l := PointLight2D.new()
	l.texture = Fx.glow_texture(256)
	l.position = pos
	l.color = color
	l.energy = energy
	l.texture_scale = size
	add_child(l)
	var t := create_tween()
	t.tween_property(l, "energy", 0.0, duration).set_ease(Tween.EASE_IN)
	t.tween_callback(l.queue_free)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = CombatHud.new() if GameState.proto else BattleHud.new()
	hud.simple = GameState.proto
	layer.add_child(hud)
	hud.build()
	var i := 0
	for c in battle.hunters():
		hud.add_party_row(c.id, _portrait(c.id), short_name(c.name), c.weapon_name, i)
		i += 1
	var m = battle.get_combatant(monster_id)
	hud.set_monster(m.name, m.max_hp)
	hud.timeline.portraits = {}
	for c in battle.hunters():
		hud.timeline.portraits[c.id] = _portrait(c.id)
		hud.timeline.colors[c.id] = Art.C_HUNTER
		hud.timeline.short_names[c.id] = short_name(c.name)
	hud.timeline.portraits[monster_id] = _monster_icon()
	if GameState.proto:
		hud.timeline.enemy_ids = [monster_id]
	hud.timeline.colors[monster_id] = Art.C_MONSTER
	hud.timeline.short_names[monster_id] = "Vorgane"
	hud.action_selected.connect(_on_action_selected)
	hud.mode_selected.connect(_on_mode_selected)
	hud.ally_selected.connect(_on_ally_selected)
	hud.confirm_pressed.connect(_confirm)
	hud.render_toggle_pressed.connect(GameState.toggle_render_mode)
	hud.result_choice.connect(_on_result_choice)
	hud.set_input_enabled(false)
	_refresh_hud()


static func short_name(n: String) -> String:
	return n.replace(" (provisoire)", "")


func _on_render_mode(mode: String) -> void:
	if stage == null:
		return
	stage.set_mode(mode)
	hud.set_render_label(GameState.render_label())


# ---------------------------------------------------------------------------
# Boucle image : caméra, parallax, accélération
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	Engine.time_scale = 2.5 if Input.is_key_pressed(KEY_SPACE) else 1.0
	_drift_t += delta
	var drift := Vector2.ZERO
	if GameState.render_mode == GameState.RENDER_25D and not GameState.proto:
		drift = Vector2(sin(_drift_t * 0.23) * 16.0, sin(_drift_t * 0.17) * 5.0)
	_shake = maxf(0.0, _shake - delta * 40.0)
	var shake_vec := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	cam.offset = drift + _cam_target_offset + shake_vec
	if stage != null:
		stage.update_parallax(drift + _cam_target_offset, delta)
	if not busy and battle.state == Battle.State.AWAITING_COMMAND:
		var hov := monster_view.part_at(get_global_mouse_position())
		if hov != monster_view.hovered_part:
			monster_view.hovered_part = hov


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## Léger zoom vers un point (rupture, coup chargé).
func punch_zoom(point: Vector2, strength := 0.08, duration := 0.45) -> void:
	var t := create_tween()
	var off := (point - cam.position) * 0.35
	t.tween_property(cam, "zoom", Vector2.ONE * (1.0 + strength), duration * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "_cam_target_offset", off, duration * 0.35)
	t.tween_interval(duration * 0.3)
	t.tween_property(cam, "zoom", Vector2.ONE, duration * 0.5).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(self, "_cam_target_offset", Vector2.ZERO, duration * 0.5)


# ---------------------------------------------------------------------------
# Lecture du journal → animations
# ---------------------------------------------------------------------------

func _play_pending() -> void:
	busy = true
	hud.set_input_enabled(false)
	for h in hunters.values():
		h.set_active(false)
	while _journal_pos < battle.journal.size():
		var e: Dictionary = battle.journal[_journal_pos]
		_journal_pos += 1
		view_now = int(e["t"])
		_log_entry(e)
		await _play(e)
		_refresh_hud()
	busy = false
	_sync_from_battle()
	if battle.is_over():
		await get_tree().create_timer(0.7).timeout
		_show_result()
		return
	if battle.state == Battle.State.AWAITING_COMMAND:
		_setup_turn()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _play(e: Dictionary) -> void:
	var d: Dictionary = e["data"]
	var actor_id: String = d.get("actor", "")
	match e["type"]:
		"start":
			hud.banner("Le Vorgane des brumes surgit !", Color("#ffcf9a"), 0.8)
			await _wait(1.0)
		"turn":
			if hunters.has(actor_id):
				hunters[actor_id].set_active(true)
		"cast":
			disp_res[actor_id] = int(d.get("value", disp_res.get(actor_id, 0)))
			if hunters.has(actor_id):
				var is_serum: bool = d.get("action", "") == "serum_pulsation"
				if d.get("action", "") in ["attaque", "technique", "serum_pulsation"]:
					hunters[actor_id].prepare(d.get("mode", ""), is_serum)
					if d.get("mode", "") == "CHARGE":
						Fx.float_text(fx, hunters[actor_id].center() + Vector2(0, -90), "Charge…", Color("#ffb05a"), 22, 30.0, 0.7)
					await _wait(0.3)
			else:
				if d.get("telegraph", false):
					tele_resolve = int(d.get("resolve_at", -1))
					tele_name = battle.get_combatant(actor_id).monster_actions[d["action"]]["name"]
					monster_view.set_telegraph(true)
					hud.banner("⚠ %s annoncé !" % tele_name, Color("#ff7a6a"), 0.9)
					shake(4.0)
					await _wait(1.1)
				else:
					monster_view.prepare()
					await _wait(0.3)
		"hit":
			if hunters.has(actor_id):
				var target_pos := monster_view.part_global(d.get("part", "glande")) if d.has("part") else monster_view.center()
				await hunters[actor_id].attack(target_pos, d.get("mode", "") == "CHARGE")
				Fx.burst(fx, target_pos, Color(1.0, 0.85, 0.55), 18, 300.0, 8.0, 0.45, 400.0)
				if d.get("mode", "") == "CHARGE":
					punch_zoom(target_pos, 0.07, 0.4)
			else:
				var act: String = d.get("action", "")
				if act == "souffle":
					tele_resolve = -1
					var pts: Array = []
					for h in battle.hunters(true):
						pts.append(hunters[h.id].center())
					await monster_view.breath(pts)
				else:
					var tgt := _next_damage_target()
					await monster_view.lunge(hunters[tgt].center() if hunters.has(tgt) else Vector2(400, 420))
		"serum":
			var part_pos := monster_view.part_global(d.get("part", "glande"))
			await hunters[actor_id].cast_serum()
			var from: Vector2 = hunters[actor_id].hand_global() if hunters[actor_id].has_method("hand_global") else hunters[actor_id].center()
			await _orb(from, part_pos)
			Fx.ring(fx, part_pos, Color(0.5, 0.95, 1.0), 140.0, 0.5, 8.0)
			Fx.burst(fx, part_pos, Color(0.5, 0.95, 1.0), 30, 320.0, 10.0, 0.6, 0.0)
			if GameState.art_proto or GameState.hd2d:
				Fx.ring(fx, part_pos, Color(0.85, 1.0, 1.0), 260.0, 0.7, 4.0)
				Fx.burst(fx, part_pos, Color(0.7, 0.98, 1.0), 40, 520.0, 7.0, 0.9, -80.0)
				light_flash(part_pos, Color(0.5, 0.95, 1.0), 3.0, 5.0, 0.6)
				punch_zoom(part_pos, 0.1, 0.8)
				shake(8.0)
		"damage":
			var target: String = d.get("target", "")
			var amount: int = int(d.get("amount", 0))
			disp_hp[target] = int(d.get("hp", disp_hp.get(target, 0)))
			if hunters.has(target):
				hunters[target].hurt(amount >= 40)
				Fx.float_text(fx, hunters[target].center() + Vector2(0, -40), str(amount), Color("#ff9a8a"), 34)
				shake(5.0 + amount * 0.08)
			else:
				var part: String = _last_hit_part()
				monster_view.hurt(part, amount >= 60)
				var pos := monster_view.part_global(part) if part != "" else monster_view.center()
				Fx.float_text(fx, pos + Vector2(0, -50), str(amount), Color("#fff2c8"), 36 if amount < 60 else 46)
				if _last_hit_affinity() > 1.0:
					Fx.float_text(fx, pos + Vector2(10, -10), "FAIBLESSE !", Color("#ffb347"), 24, 50.0, 1.0)
				if GameState.art_proto or GameState.hd2d:
					light_flash(pos, Color(1.0, 0.85, 0.6), 1.6, 3.0, 0.3)
				shake(3.0 + amount * 0.06)
			await _wait(0.28)
		"guard":
			disp_guard[actor_id] = true
			hunters[actor_id].set_guard(true)
			Fx.float_text(fx, hunters[actor_id].center() + Vector2(0, -80), "Garde", Color("#bff6ff"), 26, 40.0, 0.7)
			await _wait(0.4)
		"guard_block":
			disp_guard[actor_id] = false
			hunters[actor_id].guard_flash()
			Fx.float_text(fx, hunters[actor_id].center() + Vector2(50, -90), "GARDE −40 %", Color("#bff6ff"), 24, 50.0, 0.8)
			await _wait(0.15)
		"guard_end":
			disp_guard[actor_id] = false
			if hunters.has(actor_id):
				hunters[actor_id].set_guard(false)
		"break_progress":
			pass
		"break":
			var part_id: String = d.get("part", "")
			_sync_parts()
			monster_view.part_info[part_id]["broken"] = true
			if GameState.art_proto or GameState.hd2d:
				light_flash(monster_view.part_global(part_id), Color(1.0, 0.9, 0.7), 3.0, 5.0, 0.7)
			punch_zoom(monster_view.part_global(part_id), 0.12, 0.7)
			shake(12.0)
			await monster_view.break_part(part_id)
			hud.banner("RUPTURE !  %s" % monster_view.part_info[part_id]["name"], Color("#ffe08a"), 0.8)
			await _wait(0.9)
		"interrupt":
			tele_resolve = -1
			monster_view.set_telegraph(false)
			hud.banner("INTERROMPU !", Color("#7cfc9a"), 0.7)
			Fx.float_text(fx, monster_view.part_global("glande") + Vector2(0, -80), "Souffle annulé", Color("#7cfc9a"), 28)
			await _wait(0.9)
		"tempo":
			var amount2: int = int(d.get("amount", 0))
			Fx.float_text(fx, monster_view.center() + Vector2(0, -120), "Tour retardé +%d" % amount2 if amount2 > 0 else "Tour avancé %d" % amount2, Color("#9fe8ff"), 24, 50.0)
			await _wait(0.35)
		"tempo_resist":
			Fx.float_text(fx, monster_view.center() + Vector2(0, -120), "Résiste au recul", Color("#c0c8d0"), 22)
		"heal":
			disp_hp[d["target"]] = int(d.get("hp", 0))
			await hunters[actor_id].use_item()
			hunters[d["target"]].heal_flash()
			Fx.float_text(fx, hunters[d["target"]].center() + Vector2(0, -40), "+%d" % int(d.get("amount", 0)), Color("#8cff9a"), 32)
			await _wait(0.4)
		"resonance":
			disp_res[actor_id] = int(d.get("value", 0))
			if hunters.has(actor_id) and d.get("amount", 0) >= 10:
				Fx.float_text(fx, hunters[actor_id].center() + Vector2(-40, -110), "+%d Rés." % int(d["amount"]), Color("#5fe3ff"), 20, 40.0, 0.7)
		"defeated":
			if hunters.has(actor_id):
				hunters[actor_id].knock_out()
				disp_guard[actor_id] = false
			else:
				monster_view.die()
				shake(10.0)
			await _wait(0.7)
		"cancel":
			if hunters.has(actor_id):
				hunters[actor_id].release_aura()
		"fizzle":
			Fx.float_text(fx, Vector2(640, 300), "Sans effet", Color("#c0c8d0"), 24)
		"victory":
			hud.banner("VICTOIRE !", Color("#ffe08a"), 1.2)
			await _wait(1.0)
		"defeat":
			hud.banner("DÉFAITE…", Color("#ff7a6a"), 1.2)
			await _wait(1.0)


## Orbe d'Aether de la capacité de sérum.
func _orb(from: Vector2, to: Vector2) -> void:
	var orb := Fx.glow_sprite(Color(0.5, 0.95, 1.0, 1.0), 90.0)
	orb.position = from
	orb.z_index = 45
	fx.add_child(orb)
	var t := create_tween()
	var mid := (from + to) / 2.0 + Vector2(0, -120)
	t.tween_method(func(k: float): orb.position = from.lerp(mid, k).lerp(mid.lerp(to, k), k), 0.0, 1.0, 0.35)
	await t.finished
	orb.queue_free()


func _next_damage_target() -> String:
	for i in range(_journal_pos, battle.journal.size()):
		var e: Dictionary = battle.journal[i]
		if e["type"] == "damage" or e["type"] == "guard_block":
			return e["data"].get("target", e["data"].get("actor", ""))
	return ""


func _last_hit_part() -> String:
	for i in range(_journal_pos - 1, -1, -1):
		var e: Dictionary = battle.journal[i]
		if (e["type"] == "hit" or e["type"] == "serum") and e["data"].has("part"):
			return e["data"]["part"]
	return ""


## Multiplicateur de faiblesse du dernier coup porté au monstre (pour la mention « FAIBLESSE ! »).
func _last_hit_affinity() -> float:
	for i in range(_journal_pos - 1, -1, -1):
		var e: Dictionary = battle.journal[i]
		if (e["type"] == "hit" or e["type"] == "serum") and e["data"].has("part"):
			var attacker = battle.get_combatant(e["data"].get("actor", ""))
			if attacker == null or not attacker.is_hunter():
				return 1.0
			var dtype: String = "aether" if e["type"] == "serum" else attacker.damage_type
			var part = battle.get_combatant(monster_id).get_part(e["data"]["part"])
			return part.affinity(dtype) if part != null else 1.0
	return 1.0


func _log_entry(e: Dictionary) -> void:
	if e["type"] in ["turn", "break_progress", "resonance"]:
		return
	var col := "#d8dee4"
	match e["type"]:
		"break", "victory":
			col = "#7cfc9a"
		"interrupt", "defeat", "defeated":
			col = "#ff8a7a"
		"cast":
			col = "#ffd27a" if e["data"].get("telegraph", false) else "#b8c4ce"
	hud.log_append(int(e["t"]), e["text"], col)


# ---------------------------------------------------------------------------
# Affichage HUD
# ---------------------------------------------------------------------------

func _sync_parts() -> void:
	var m = battle.get_combatant(monster_id)
	for p in m.parts:
		var info: Dictionary = monster_view.part_info.get(p.id, {})
		info["name"] = p.name
		info["integrity"] = p.integrity
		info["max"] = p.max_integrity
		if not info.has("broken"):
			info["broken"] = false
		monster_view.part_info[p.id] = info


func _sync_from_battle() -> void:
	for c in battle.combatants:
		disp_hp[c.id] = c.hp
		disp_res[c.id] = c.resonance
		disp_guard[c.id] = c.guard_active
	view_now = battle.now
	var m = battle.get_combatant(monster_id)
	tele_resolve = m.pending_cast.resolve_at if (m.pending_cast != null and m.pending_cast.telegraph) else -1
	if (tele_resolve >= 0) != monster_view._telegraph:
		monster_view.set_telegraph(tele_resolve >= 0)
	_sync_parts()
	for p in m.parts:
		monster_view.part_info[p.id]["broken"] = p.broken
	_refresh_hud()


func _refresh_hud() -> void:
	var current: String = battle.current_actor.id if (battle.current_actor != null and not busy) else ""
	var hunter_ids: Array = hunters.keys()
	var hp := {}
	var mx := {}
	var res := {}
	for id in hunter_ids:
		hp[id] = disp_hp[id]
		mx[id] = disp_max[id]
		res[id] = disp_res[id]
	hud.update_party(hp, mx, res, disp_guard, current, (not busy) and _target_kind() == "ally")
	var tele := ""
	if tele_resolve >= 0:
		tele = "⚠ %s dans %d" % [tele_name, maxi(0, tele_resolve - view_now)]
	hud.update_monster(int(disp_hp[monster_id]), tele)
	if hud.has_method("set_boss_status"):
		# Statuts RÉELLEMENT actifs : attaque annoncée, parties brisées
		var st: Array = []
		if tele_resolve >= 0:
			st.append({"icon": "warn", "text": "%s +%d" % [tele_name.split(" ")[0], maxi(0, tele_resolve - view_now)], "color": UI.C_DANGER})
		for p in battle.get_combatant(monster_id).parts:
			if monster_view.part_info.get(p.id, {}).get("broken", false):
				st.append({"icon": "broken", "text": "%s brisée" % p.name.split(" ")[0], "color": UI.C_BREAK})
		hud.set_boss_status(st)
	for p in battle.get_combatant(monster_id).parts:
		if monster_view.part_info.has(p.id):
			monster_view.part_info[p.id]["integrity"] = _shown_integrity(p.id)


## Intégrité affichée : celle du dernier événement joué (et non l'état final).
func _shown_integrity(part_id: String) -> int:
	for i in range(_journal_pos - 1, -1, -1):
		var e: Dictionary = battle.journal[i]
		if e["type"] == "break_progress" and e["data"].get("part", "") == part_id:
			return int(e["data"]["integrity"])
	return battle.get_combatant(monster_id).get_part(part_id).max_integrity


# ---------------------------------------------------------------------------
# Tour du joueur
# ---------------------------------------------------------------------------

func _setup_turn() -> void:
	var a = battle.current_actor
	hunters[a.id].set_active(true)
	if not _action_enabled(a, sel_action):
		sel_action = "attaque"
	sel_ally = a.id
	var m = battle.get_combatant(monster_id)
	var p = m.get_part(sel_part)
	if p == null or p.broken:
		sel_part = AutoPolicy.best_part(m, a.damage_type)
	hud.set_input_enabled(true)
	_refresh_selection()
	if GameState.autoplay:
		_auto_turn()


func _target_kind() -> String:
	return battle.actions.get(sel_action, {}).get("target", "self")


func _cmd_for(aid: String, mode := "") -> Dictionary:
	var def: Dictionary = battle.actions[aid]
	var cmd := {"action": aid}
	if def.get("modes", []).size() > 0:
		cmd["mode"] = mode if mode != "" else sel_mode
	match def.get("target", "self"):
		"enemy_part":
			cmd["target"] = monster_id
			cmd["part"] = sel_part
		"ally":
			cmd["target"] = sel_ally if sel_ally != "" else battle.current_actor.id
	return cmd


func _action_enabled(a, aid: String) -> bool:
	return battle.validate(a, _cmd_for(aid)) == ""


func _refresh_selection() -> void:
	var a = battle.current_actor
	if a == null or busy:
		return
	var m = battle.get_combatant(monster_id)
	# Actions
	var list: Array = []
	for aid in a.action_ids:
		var def: Dictionary = battle.actions[aid]
		var label: String = short_name(def["name"])
		if def.has("item"):
			label += "  ×%d" % int(battle.inventory.get(def["item"], 0))
		if def.has("resonance_cost"):
			label += "  (%d Rés.)" % int(def["resonance_cost"])
		var ok := _action_enabled(a, aid)
		var why: String = def.get("description", "") if ok else battle.validate(a, _cmd_for(aid))
		list.append({"id": aid, "label": label, "enabled": ok, "reason": why})
	hud.set_actions(list, sel_action)

	var def_sel: Dictionary = battle.actions[sel_action]
	var cmd := _cmd_for(sel_action)
	var valid := battle.validate(a, cmd) == ""
	var tk := _target_kind()
	if GameState.proto:
		var dtxt: String = def_sel.get("description", "")
		if not valid:
			dtxt += "\n[color=#%s]Indisponible : %s[/color]" % [UI.C_DANGER.to_html(false), battle.validate(a, cmd)]
		hud.set_action_description(short_name(def_sel["name"]), dtxt)
	monster_view.targeting = tk == "enemy_part"
	monster_view.selected_part = sel_part

	# Indices de faiblesse pour le Chasseur actif
	var dtype: String = def_sel.get("element", a.damage_type) if def_sel.get("kind", "") == "serum" else a.damage_type
	for p in m.parts:
		var aff: float = p.affinity(dtype)
		var info: Dictionary = monster_view.part_info[p.id]
		if aff > 1.0:
			info["hint"] = "▲ ×%.1f" % aff
			info["hint_color"] = Color("#8cff9a")
		elif aff < 1.0:
			info["hint"] = "▼ ×%.1f" % aff
			info["hint_color"] = Color("#ff9a8a")
		else:
			info["hint"] = ""

	# Cartes de mode / carte d'information / choix d'allié
	var tele_line := ""
	if def_sel.get("modes", []).size() > 0:
		var cards: Array = []
		for mode in def_sel["modes"]:
			var c := _cmd_for(sel_action, mode)
			var est: Dictionary = battle.estimate(a, c)
			var lines := ["Effet dans +%d" % (int(est["resolve_at"]) - battle.now),
				"Dégâts ≈ %d · Rupture %d" % [est["damage"], est["break"]]]
			if tele_resolve >= 0:
				if GameState.proto:
					lines.append("+ avant le Souffle" if int(est["resolve_at"]) < tele_resolve else "- après le Souffle")
				else:
					lines.append("✔ avant le Souffle" if int(est["resolve_at"]) < tele_resolve else "✘ après le Souffle")
			cards.append({"mode": mode, "title": MODE_TITLES[mode], "lines": lines, "selected": mode == sel_mode,
				"color": MODE_COLORS[mode], "windup": float(battle.rules["modes"][mode]["windup"])})
		hud.set_mode_cards(cards)
	elif tk == "ally":
		var allies: Array = []
		for h in battle.hunters(true):
			allies.append({"id": h.id, "name": short_name(h.name), "hp": h.hp, "max": h.max_hp,
				"portrait": load(Art.hunter(h.id, GameState.hero_gender)["portrait"])})
		hud.set_ally_choices(allies, sel_ally)
	else:
		var lines2: Array = [] if GameState.proto else [def_sel.get("description", "")]
		if valid:
			var est2: Dictionary = battle.estimate(a, cmd)
			if est2["damage"] > 0:
				lines2.append("Dégâts ≈ %d · Rupture %d%s" % [est2["damage"], est2["break"],
					(" · Recule le monstre de %d" % est2["delay"]) if est2["delay"] > 0 else ""])
			if def_sel.get("kind", "") != "guard":
				lines2.append("Effet dans +%d" % (int(est2["resolve_at"]) - battle.now))
			else:
				lines2.append("Effet immédiat, jusqu'à votre prochain tour (+%d)" % a.cycle(battle.rules))
		hud.set_mode_cards([{"title": short_name(def_sel["name"]), "lines": lines2, "color": Color("#9fe8ff") if def_sel.get("kind") == "serum" else Color("#c6d4e0")}])

	# Ligne de cible
	if GameState.proto:
		_proto_target_and_preview(a, m, def_sel, cmd, valid, tk, dtype)
		return
	match tk:
		"enemy_part":
			var p = m.get_part(sel_part)
			var aff2: float = p.affinity(dtype)
			var aff_txt := ""
			if aff2 > 1.0:
				aff_txt = "  [color=#8cff9a]▲ faible (%s ×%.1f)[/color]" % [dtype, aff2]
			elif aff2 < 1.0:
				aff_txt = "  [color=#ff9a8a]▼ résiste (%s ×%.1f)[/color]" % [dtype, aff2]
			var state_txt := "[color=#8d98a3]brisée[/color]" if p.broken else "%d/%d" % [_shown_integrity(p.id), p.max_integrity]
			hud.set_target_text("[b]%s[/b] → [color=#ffd27a]%s[/color] (%s)%s" % [short_name(a.name), p.name, state_txt, aff_txt])
		"ally":
			hud.set_target_text("[b]%s[/b] → soigner [color=#8cff9a]%s[/color]  (cliquez sur un allié)" % [short_name(a.name), short_name(battle.get_combatant(sel_ally).name)])
		_:
			hud.set_target_text("[b]%s[/b] → soi-même" % short_name(a.name))

	# Aperçu et chronologie
	if valid:
		var est3: Dictionary = battle.estimate(a, cmd)
		var parts_txt: Array = []
		if def_sel.get("kind", "") != "guard":
			parts_txt.append("Effet dans [color=#ffd27a]+%d[/color]" % (int(est3["resolve_at"]) - battle.now))
		parts_txt.append("prochain tour de %s dans +%d" % [short_name(a.name), int(est3["next_decision"]) - battle.now])
		if tele_resolve >= 0 and def_sel.get("kind", "") != "guard":
			if int(est3["resolve_at"]) < tele_resolve:
				tele_line = "  [color=#7cfc9a]✔ AVANT ⚠ (+%d)[/color]" % (tele_resolve - battle.now)
			else:
				tele_line = "  [color=#ff8a7a]✘ APRÈS ⚠ (+%d)[/color]" % (tele_resolve - battle.now)
		hud.set_preview(" · ".join(PackedStringArray(parts_txt)) + tele_line)
		hud.timeline.events = battle.preview_timeline(14, cmd)
	else:
		hud.set_preview("[color=#ff8a7a]%s[/color]" % battle.validate(a, cmd))
		hud.timeline.events = battle.preview_timeline(14)
	hud.timeline.now = battle.now
	hud.timeline.current_id = a.id
	hud.confirm_enabled(valid)
	_refresh_hud()


## Prototype : cible (nom + intégrité + faiblesse pertinente) et aperçu RÉEL du moteur, couleurs de UiStyle.
func _proto_target_and_preview(a, m, def_sel: Dictionary, cmd: Dictionary, valid: bool, tk: String, dtype: String) -> void:
	var gold := UI.C_SELECT.to_html(false)
	match tk:
		"enemy_part":
			var p = m.get_part(sel_part)
			var aff: float = p.affinity(dtype)
			var state_txt := "brisée" if p.broken else "%d / %d" % [_shown_integrity(p.id), p.max_integrity]
			var t := "Cible : [b][color=#%s]%s[/color][/b]  %s" % [gold, p.name, state_txt]
			if aff > 1.0:
				t += "\n[color=#%s]▲ Faible : %s ×%.1f[/color]" % [UI.C_WEAK.to_html(false), dtype, aff]
			elif aff < 1.0:
				t += "\n[color=#%s]▼ Résiste : %s ×%.1f[/color]" % [UI.C_TEXT_DIM.to_html(false), dtype, aff]
			hud.set_target_text(t)
		"ally":
			hud.set_target_text("Cible : [b][color=#%s]%s[/color][/b]" % [UI.C_HEAL.to_html(false), short_name(battle.get_combatant(sel_ally).name)])
		_:
			hud.set_target_text("Cible : %s" % short_name(a.name))
	if valid:
		var est: Dictionary = battle.estimate(a, cmd)
		var txt := "Prochain tour de %s dans +%d" % [short_name(a.name), int(est["next_decision"]) - battle.now]
		if tele_resolve >= 0 and def_sel.get("kind", "") != "guard":
			if int(est["resolve_at"]) < tele_resolve:
				txt += "   ·   [color=#%s]Frappe AVANT le %s (+%d)[/color]" % [UI.C_HEAL.to_html(false), tele_name, tele_resolve - battle.now]
			else:
				txt += "   ·   [color=#%s]Frappe APRÈS le %s (+%d)[/color]" % [UI.C_DANGER.to_html(false), tele_name, tele_resolve - battle.now]
		hud.set_preview(txt)
		hud.timeline.events = battle.preview_timeline(14, cmd)
	else:
		hud.set_preview("[color=#%s]%s[/color]" % [UI.C_DANGER.to_html(false), battle.validate(a, cmd)])
		hud.timeline.events = battle.preview_timeline(14)
	hud.timeline.now = battle.now
	hud.timeline.current_id = a.id
	hud.confirm_enabled(valid)
	_refresh_hud()


func _on_action_selected(aid: String) -> void:
	if busy:
		return
	sel_action = aid
	_refresh_selection()


func _on_mode_selected(mode: String) -> void:
	if busy:
		return
	sel_mode = mode
	_refresh_selection()


func _on_ally_selected(id: String) -> void:
	if busy or _target_kind() != "ally":
		return
	sel_ally = id
	_refresh_selection()


func _confirm() -> void:
	if busy or battle.state != Battle.State.AWAITING_COMMAND:
		return
	var cmd := _cmd_for(sel_action)
	var err := battle.submit(cmd)
	if err != "":
		hud.set_preview("[color=#ff8a7a]%s[/color]" % err)
		return
	monster_view.targeting = false
	hud.timeline.current_id = ""
	_play_pending()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_L and not GameState.proto:
		hud.toggle_log()
		return
	if busy or battle.state != Battle.State.AWAITING_COMMAND:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var gp := get_global_mouse_position()
		if _target_kind() == "enemy_part":
			var part := monster_view.part_at(gp)
			if part != "":
				sel_part = part
				_refresh_selection()
		elif _target_kind() == "ally":
			for id in hunters:
				if battle.get_combatant(id).is_alive() and gp.distance_to(hunters[id].center()) < 90.0:
					sel_ally = id
					_refresh_selection()
	elif event is InputEventKey and event.pressed and not event.echo:
		var a = battle.current_actor
		var ids: Array = a.action_ids
		match event.keycode:
			KEY_ENTER, KEY_KP_ENTER:
				_confirm()
			KEY_LEFT, KEY_RIGHT:
				_cycle_target(1 if event.keycode == KEY_RIGHT else -1)
			KEY_UP, KEY_DOWN:
				var i := ids.find(sel_action)
				sel_action = ids[(i + (1 if event.keycode == KEY_DOWN else -1) + ids.size()) % ids.size()]
				_refresh_selection()
			KEY_TAB:
				var modes: Array = battle.actions[sel_action].get("modes", [])
				if modes.size() > 0:
					sel_mode = modes[(modes.find(sel_mode) + 1) % modes.size()]
					_refresh_selection()
		var pk: int = event.physical_keycode
		if pk >= KEY_1 and pk <= KEY_5 and pk - KEY_1 < ids.size():
			sel_action = ids[pk - KEY_1]
			_refresh_selection()


func _cycle_target(dir: int) -> void:
	if _target_kind() == "enemy_part":
		var order := ["griffe", "glande", "carapace"]
		sel_part = order[(order.find(sel_part) + dir + order.size()) % order.size()]
	elif _target_kind() == "ally":
		var alive: Array = battle.hunters(true).map(func(h): return h.id)
		sel_ally = alive[(alive.find(sel_ally) + dir + alive.size()) % alive.size()]
	_refresh_selection()


## Démonstration automatique (vidéos) : choisit comme la politique de test, en variant les modes.
func _auto_turn() -> void:
	var cmd := AutoPolicy.choose(battle)
	await _wait(0.5)
	sel_action = cmd["action"]
	if cmd.has("part"):
		sel_part = cmd["part"]
	if cmd["action"] == "potion":
		sel_ally = cmd["target"]
	if cmd.has("mode"):
		sel_mode = cmd["mode"]
		if cmd["mode"] == "MESURE":
			sel_mode = "CHARGE" if battle.current_actor.decisions % 4 == 2 else "MESURE"
	_refresh_selection()
	await _wait(1.1)
	_confirm()


# ---------------------------------------------------------------------------
# Fin du combat
# ---------------------------------------------------------------------------

func _show_result() -> void:
	var victory := battle.state == Battle.State.VICTORY
	var lines: Array = []
	var m = battle.get_combatant(monster_id)
	var broken: int = m.parts.filter(func(p): return p.broken).size()
	if victory:
		lines.append("[b]Récompenses[/b]")
		lines.append("•  %d pièces" % int(battle.rewards["currency"]))
		var items: Dictionary = battle.rewards["items"]
		for k in items:
			lines.append("•  %s ×%d" % [GameState.material_name(k), int(items[k])])
		lines.append("")
		lines.append("Parties brisées : %d / %d   ·   durée : t=%d" % [broken, m.parts.size(), battle.now])
	else:
		lines.append("Le groupe se replie vers l'avant-poste.")
		lines.append("Astuce : brisez la Glande d'Aether avant le Souffle annoncé,")
		lines.append("ou mettez-vous en garde.")
	var buttons: Array = []
	if GameState.from_zone:
		GameState.potions = int(battle.inventory.get("potion", 0))
		if victory:
			GameState.add_rewards(battle.rewards)
			GameState.enemy_defeated = true
		GameState.last_battle_result = "victory" if victory else "defeat"
		buttons.append({"id": "proto_zone" if GameState.proto else "zone", "label": "Retour à l'avant-poste"})
	elif GameState.proto:
		buttons.append({"id": "retry", "label": "Rejouer"})
		buttons.append({"id": "proto_zone", "label": "Aller à l'avant-poste"})
	else:
		buttons.append({"id": "retry", "label": "Rejouer"})
		buttons.append({"id": "menu", "label": "Menu"})
	hud.show_result(victory, lines, buttons)
	if GameState.autoplay:
		await _wait(2.5)
		_on_result_choice(buttons[0]["id"])


func _on_result_choice(choice: String) -> void:
	match choice:
		"zone":
			GameState.goto(GameState.SCENE_ZONE)
		"proto_zone":
			GameState.goto(GameState.SCENE_PROTO_ZONE)
		"retry":
			GameState.goto(GameState.SCENE_BATTLE)
		"menu":
			GameState.goto(GameState.SCENE_HERO_SELECT)
