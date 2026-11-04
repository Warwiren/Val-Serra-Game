extends Node2D
## Représentation d'un Chasseur à l'écran : corps et arme(s) en calques séparés (découpe « cut-out »).
## Origine du nœud = pieds du personnage. Ne contient AUCUNE règle de jeu.

const Art = preload("res://src/presentation/art.gd")
const Fx = preload("res://src/presentation/fx.gd")

var actor_id: String = ""
var def: Dictionary = {}
var sprite_scale: float = 0.8
var home: Vector2

var body: Sprite2D
var rig: Node2D                      # tout le corps (animé ensemble)
var weapon_pivot: Node2D
var weapon2_pivot: Node2D
var _aura: Sprite2D
var _shield_alpha := 0.0
var _active := false
var _ko := false
var _t := 0.0
var _phase := 0.0


func setup(id: String, hunter_def: Dictionary, feet: Vector2, scale_factor := 0.8) -> void:
	actor_id = id
	def = hunter_def
	sprite_scale = scale_factor
	home = feet
	position = feet
	_phase = float(hash(id) % 100) / 15.0

	rig = Node2D.new()
	rig.scale = Vector2.ONE * sprite_scale
	add_child(rig)

	_aura = Fx.glow_sprite(Color(0.4, 0.9, 1.0, 0.0), 300.0)
	_aura.position = Vector2(0, -150)
	rig.add_child(_aura)

	if def.has("weapon2"):
		weapon2_pivot = _make_weapon(def["weapon2"], def["hand2"], float(def["rest2"]))
	body = Sprite2D.new()
	body.texture = load(def["body"])
	body.offset = Vector2(0, -(Art.BODY_FEET.y - Art.BODY_SIZE.y / 2.0))
	rig.add_child(body)
	weapon_pivot = _make_weapon(def["weapon"], def["hand"], float(def["rest"]))


func _make_weapon(kind: String, hand: Vector2, rest_deg: float) -> Node2D:
	var w: Dictionary = Art.WEAPONS[kind]
	var pivot := Node2D.new()
	pivot.position = hand - Art.BODY_FEET
	pivot.rotation_degrees = rest_deg
	pivot.set_meta("rest", rest_deg)
	var s := Sprite2D.new()
	s.texture = load(w["path"])
	var size := Vector2(s.texture.get_width(), s.texture.get_height())
	s.offset = size / 2.0 - w["grip"]
	pivot.add_child(s)
	rig.add_child(pivot)
	return pivot


func _process(delta: float) -> void:
	_t += delta
	if _ko:
		return
	# Respiration légère et balancement de l'arme au repos
	var breath := sin(_t * 2.2 + _phase)
	body.scale = Vector2(1.0 - breath * 0.008, 1.0 + breath * 0.014)
	if weapon_pivot.has_meta("rest") and not weapon_pivot.has_meta("busy"):
		weapon_pivot.rotation_degrees = float(weapon_pivot.get_meta("rest")) + sin(_t * 1.6 + _phase) * 2.0
	queue_redraw()


func _draw() -> void:
	# Ombre portée et anneau du personnage actif
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, 62 * sprite_scale / 0.8, Color(0, 0, 0, 0.35))
	if _active:
		var pulse := 0.6 + 0.4 * sin(_t * 5.0)
		draw_arc(Vector2.ZERO, 78 * sprite_scale / 0.8, 0, TAU, 48, Color(Art.C_GOLD, pulse), 5.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _shield_alpha > 0.01:
		var c := Color(0.55, 0.9, 1.0, 0.28 * _shield_alpha)
		draw_circle(Vector2(0, -120 * sprite_scale / 0.8), 115 * sprite_scale / 0.8, c)
		draw_arc(Vector2(0, -120 * sprite_scale / 0.8), 115 * sprite_scale / 0.8, -1.2, 1.2, 32,
			Color(0.75, 0.97, 1.0, 0.9 * _shield_alpha), 6.0, true)


func center() -> Vector2:
	return global_position + Vector2(0, -120 * sprite_scale / 0.8)


func set_active(on: bool) -> void:
	_active = on


## Préparation : CHARGÉ = aura intense, VIF = éclair bref, sérum = aura cyan.
func prepare(mode: String, is_serum := false) -> void:
	var col := Color(0.4, 0.9, 1.0) if is_serum else (Color(1.0, 0.75, 0.35) if mode == "CHARGE" else Color(1, 1, 1))
	var strength := 0.75 if (mode == "CHARGE" or is_serum) else (0.35 if mode == "MESURE" else 0.0)
	_aura.modulate = Color(col, 0.0)
	var t := create_tween()
	t.tween_property(_aura, "modulate:a", strength, 0.25)
	var w := weapon_pivot
	w.set_meta("busy", true)
	var raise := float(w.get_meta("rest")) - (35.0 if mode == "CHARGE" else 15.0)
	var tw := create_tween()
	tw.tween_property(w, "rotation_degrees", raise, 0.25).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(rig, "position", Vector2(-10, 0), 0.25)


func release_aura() -> void:
	var t := create_tween()
	t.tween_property(_aura, "modulate:a", 0.0, 0.3)


## Attaque : élan vers la cible, coup d'arme, retour. Renvoie au moment de l'impact.
func attack(target_global: Vector2, heavy: bool) -> void:
	var w := weapon_pivot
	w.set_meta("busy", true)
	var rest := float(w.get_meta("rest"))
	var dir := (target_global - global_position)
	var reach := clampf(dir.length() - 330.0, 60.0, 300.0)
	var dest := Vector2(reach, -10.0) / scale.x
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(-24, 6), 0.12).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(w, "rotation_degrees", rest - 50.0, 0.12)
	t.tween_property(rig, "position", dest, 0.16 if not heavy else 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(w, "rotation_degrees", rest + float(def["swing"]), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if weapon2_pivot != null:
		t.parallel().tween_property(weapon2_pivot, "rotation_degrees", float(weapon2_pivot.get_meta("rest")) + 80.0, 0.18)
	await t.finished
	release_aura()
	var back := create_tween()
	back.tween_interval(0.12)
	back.tween_property(rig, "position", Vector2.ZERO, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	back.parallel().tween_property(w, "rotation_degrees", rest, 0.4).set_trans(Tween.TRANS_QUAD)
	if weapon2_pivot != null:
		back.parallel().tween_property(weapon2_pivot, "rotation_degrees", float(weapon2_pivot.get_meta("rest")), 0.4)
	back.tween_callback(func(): w.remove_meta("busy"))


## Lancement de sérum : posture, onde d'Aether.
func cast_serum() -> void:
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(0, -14), 0.15).set_trans(Tween.TRANS_BACK)
	await t.finished
	Fx.ring(get_parent(), center(), Color(0.5, 0.95, 1.0, 0.9), 150.0, 0.45, 7.0)
	Fx.burst(get_parent(), center(), Color(0.45, 0.9, 1.0), 26, 220.0, 9.0, 0.6, -60.0)
	release_aura()
	var back := create_tween()
	back.tween_property(rig, "position", Vector2.ZERO, 0.3)
	back.parallel().tween_property(weapon_pivot, "rotation_degrees", float(weapon_pivot.get_meta("rest")), 0.3)
	back.tween_callback(func(): weapon_pivot.remove_meta("busy"))


func use_item() -> void:
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(0, -8), 0.12)
	t.tween_property(rig, "position", Vector2.ZERO, 0.18)
	await t.finished


## Coup reçu : flash blanc + recul.
func hurt(heavy: bool) -> void:
	body.modulate = Color(3, 3, 3)
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(-18 if not heavy else -32, 0), 0.06)
	t.parallel().tween_property(body, "modulate", Color(1.6, 0.6, 0.6), 0.08)
	t.tween_property(rig, "position", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(body, "modulate", Color.WHITE, 0.25)


func heal_flash() -> void:
	Fx.burst(get_parent(), center(), Color(0.5, 1.0, 0.55), 18, 140.0, 8.0, 0.8, -120.0)
	body.modulate = Color(1.3, 1.8, 1.3)
	var t := create_tween()
	t.tween_property(body, "modulate", Color.WHITE, 0.5)


func set_guard(on: bool) -> void:
	var t := create_tween()
	t.tween_method(func(v): _shield_alpha = v, _shield_alpha, 1.0 if on else 0.0, 0.25)
	if on:
		Fx.ring(get_parent(), center(), Color(0.7, 0.97, 1.0, 0.8), 130.0, 0.35, 5.0)


func guard_flash() -> void:
	_shield_alpha = 2.0
	Fx.burst(get_parent(), center() + Vector2(60, 0), Color(0.8, 0.98, 1.0), 16, 200.0, 7.0, 0.4, 0.0)
	set_guard(false)


func knock_out() -> void:
	_ko = true
	_active = false
	release_aura()
	var t := create_tween()
	t.tween_property(rig, "rotation_degrees", -80.0, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(rig, "position", Vector2(-30, -10), 0.45)
	t.parallel().tween_property(rig, "modulate", Color(0.45, 0.45, 0.55, 0.85), 0.45)


## Exploration : marche (rebond + balancement) et orientation gauche/droite.
var _walk_t := 0.0


func walk(moving: bool, dir_x: float, delta: float) -> void:
	if absf(dir_x) > 0.05:
		scale.x = signf(dir_x)
	if moving:
		_walk_t += delta * 11.0
		rig.position.y = -absf(sin(_walk_t)) * 7.0
		rig.rotation = sin(_walk_t) * 0.045
	else:
		_walk_t = 0.0
		rig.position.y = lerpf(rig.position.y, 0.0, minf(1.0, delta * 12.0))
		rig.rotation = lerpf(rig.rotation, 0.0, minf(1.0, delta * 12.0))
