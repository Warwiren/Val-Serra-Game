extends "res://src/presentation/arena_layers.gd"
## P5 — ARÈNE DE COMBAT « Forêt » : le décor est la forêt d'exploration V07B elle-même (mêmes modèles, même lumière
## de fin d'après-midi, sans brouillard), rendue depuis une caméra de combat par tools/p5/decor_foret.gd
## (art/p5/combat/foret_clairiere.png, 1280 × 720, affiché 1:1). Présentation seulement (aucune règle de combat).
## Lumière : le soleil, haut à droite (ombres des arbres vers la gauche) ; il éclaire aussi le Vorgane (scene_lights).
## Poussière dorée dans les rayons, très discrète.

const IMAGE := "res://art/p5/combat/foret_clairiere.png"
## P5.2 : premier plan (fougères et herbes hautes dans les coins du bas, rendu à part, fond transparent), dessiné
## DEVANT les combattants, un peu assombri (profondeur) ; centre dégagé
const AVANT := "res://art/p5/combat/foret_clairiere_avant.png"
const SOLEIL := Vector2(1180, -160)
var _layers_avant: Sprite2D


func _build_hd() -> void:
	var s := Sprite2D.new()
	s.texture = load(IMAGE)
	s.centered = false
	s.position = Vector2.ZERO
	s.z_index = -100
	s.set_meta("origin", Vector2.ZERO)
	s.set_meta("parallax", 0.0)
	add_child(s)
	_layers["base"] = s
	painted.append("foret")
	var cm := CanvasModulate.new()
	cm.color = Color(1.0, 0.98, 0.95)
	add_child(cm)
	lights.append(SOLEIL)
	if ResourceLoader.exists(AVANT):
		var f := Sprite2D.new()
		f.texture = load(AVANT)
		f.centered = false
		f.modulate = Color(0.8, 0.84, 0.78)
		_front.add_child(f)
		_layers_avant = f
	_add_dust()


func _add_dust() -> void:
	var p := CPUParticles2D.new()
	p.amount = 18
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(640, 220)
	p.position = Vector2(640, 300)
	p.gravity = Vector2(-2, 1.5)
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 5.0
	p.spread = 180.0
	p.texture = _radial(8)
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.7
	p.color = Color(1.0, 0.92, 0.7, 0.55)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.add_point(0.5, Color(1, 1, 1, 1))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	p.material = m
	p.z_index = -94
	add_child(p)
