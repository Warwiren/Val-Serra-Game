extends "res://src/presentation/monster_view.gd"
## P6 — Le COMMANDANT de la Guilde dans la scène de combat (tutoriel) : un humain, pas une créature.
## Même interface que les vues de monstre (parties ciblables, marqueurs, préparation, attaque, coup reçu) pour que la
## scène de combat existante l'utilise sans modification. Sprite provisoire : le garde du projet (art/p45/chars/garde/),
## profil gauche (tourné vers le groupe), attente animée, agrandi ×2 au plus proche (règle du combat), teinte dorée
## identique à l'exploration. Aucune animation de mort (le tutoriel ne se termine jamais par sa défaite).

const DIR_GARDE := "res://art/p45/chars/garde/"
const ECHELLE := 2.0
const TEINTE := Color(1.28, 1.08, 0.74)
## ancres des parties (pixels du sprite, origine = pieds), garde de profil gauche
const ANCRES := {"heaume": Vector2(2, -66), "bouclier": Vector2(-14, -36), "plastron": Vector2(6, -44)}

var _frames: Array = []
var _parade := 0.0


func setup(feet: Vector2, _scale_factor := 0.9, overlay: Node = null) -> void:
	position = feet.round()
	scale = Vector2.ONE
	rig = Node2D.new()
	add_child(rig)
	_frames.append(load(DIR_GARDE + "idle_left.png"))
	for i in range(1, 8):
		if ResourceLoader.exists(DIR_GARDE + "idle_left_%d.png" % i):
			_frames.append(load(DIR_GARDE + "idle_left_%d.png" % i))
	body = Sprite2D.new()
	body.texture = _frames[0]
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.centered = true
	body.offset = Vector2(0, -body.texture.get_height() / 2.0)
	body.scale = Vector2.ONE * ECHELLE
	body.self_modulate = TEINTE
	rig.add_child(body)
	var ombre := Sprite2D.new()
	ombre.texture = _ombre_tex()
	ombre.position = Vector2(0, 2)
	ombre.z_index = -1
	ombre.modulate = Color(0, 0, 0, 0.35)
	rig.add_child(ombre)
	for id in ANCRES:
		parts[id] = {"sprite": body, "intact": "", "broken": "", "anchor": ANCRES[id] * ECHELLE}
	markers = Node2D.new()
	markers.z_index = 30
	markers.draw.connect(_draw_markers)
	if overlay != null:
		overlay.add_child(markers)
	else:
		rig.add_child(markers)


func _ombre_tex() -> Texture2D:
	var img := Image.create(90, 22, false, Image.FORMAT_RGBA8)
	for y in 22:
		for x in 90:
			var d := Vector2((x - 45.0) / 45.0, (y - 11.0) / 11.0).length()
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	_t += delta
	if markers.get_parent() != rig:
		markers.global_transform = rig.global_transform
	body.texture = _frames[int(_t * 4.0) % _frames.size()]
	var glow := 0.0
	if _telegraph:
		glow = 0.5 + 0.5 * sin(_t * 8.0)
	if _parade > 0.0:
		_parade -= delta
	body.self_modulate = TEINTE.lerp(Color(1.8, 0.7, 0.6), glow * 0.45).lerp(Color(2.2, 2.2, 2.4), clampf(_parade * 3.0, 0.0, 1.0))
	markers.queue_redraw()


func center() -> Vector2:
	return rig.to_global(Vector2(0, -44 * ECHELLE))


func mouth_global() -> Vector2:
	return center()


## Rectangle à l'écran du commandant (pour le guide d'interface).
func screen_rect() -> Rect2:
	var h := body.texture.get_height() * ECHELLE
	var w := body.texture.get_width() * ECHELLE
	var tl := rig.get_global_transform_with_canvas() * Vector2(-w * 0.32, -h * 0.98)
	var br := rig.get_global_transform_with_canvas() * Vector2(w * 0.32, 4)
	return Rect2(tl, br - tl)


func set_telegraph(on: bool) -> void:
	_telegraph = on
	if on:
		Fx.ring(get_parent(), center(), Color(1.0, 0.45, 0.4, 0.9), 150.0, 0.6, 6.0)


func prepare() -> void:
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(10, 2), 0.25).set_trans(Tween.TRANS_SINE)


func lunge(target_global: Vector2) -> void:
	var dx := clampf(target_global.x - global_position.x + 150.0, -380.0, -60.0)
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(14, 0), 0.12)
	t.tween_property(rig, "position", Vector2(dx, 0), 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await t.finished
	var back := create_tween()
	back.tween_interval(0.12)
	back.tween_property(rig, "position", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_QUAD)


## Coup reçu : le commandant PARE (recul bref, éclat du bouclier) — il ne perd pas de PV.
func hurt(_part_id: String, _heavy: bool) -> void:
	_parade = 0.35
	Fx.burst(get_parent(), rig.to_global(ANCRES["bouclier"] * ECHELLE), Color(1.0, 0.92, 0.7), 14, 260.0, 6.0, 0.35, 200.0)
	var t := create_tween()
	t.tween_property(rig, "position", Vector2(6, 0), 0.05)
	t.tween_property(rig, "position", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func break_part(_part_id: String) -> void:
	pass


func die() -> void:
	pass                                   # jamais : le tutoriel se termine par un événement scénarisé
