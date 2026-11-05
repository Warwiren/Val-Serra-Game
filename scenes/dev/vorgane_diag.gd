extends Node2D
## OUTIL DE DÉVELOPPEMENT (hors parcours normal) — diagnostic du Vorgane.
## Rejoue, dans le décor du combat, 3 préparations du Souffle annoncé puis 3 coups de griffe ordinaires,
## avec des marqueurs temporels sur la console (« DIAG t=… »), pour filmer et mesurer image par image.
## Lancement : godot --path . res://scenes/dev/vorgane_diag.tscn [-- --neutral]
##   --neutral : sans décor, lumière ni shader (capture B du brief : rendu brut dans Godot).

const SpriteMonsterView = preload("res://src/presentation/sprite_monster_view.gd")
const Fx = preload("res://src/presentation/fx.gd")

var mv
var fx: Node2D
var _t := 0.0


func _ready() -> void:
	var neutral := OS.get_cmdline_user_args().has("--neutral")
	if neutral:
		var bg := ColorRect.new()
		bg.color = Color(0.5, 0.5, 0.5)
		bg.size = Vector2(1280, 720)
		add_child(bg)
	else:
		var bg := Sprite2D.new()
		bg.texture = load("res://art/proto/zone_bg.png")
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.centered = false
		bg.scale = Vector2(3, 3)
		add_child(bg)
		var cm := CanvasModulate.new()
		cm.color = Color(0.8, 0.8, 0.92)
		add_child(cm)
	fx = Node2D.new()
	mv = SpriteMonsterView.new()
	mv.sprite_dir = "res://art/proto/vorgane_nuit/"
	mv.facing_right = true
	add_child(mv)
	add_child(fx)
	mv.setup(Vector2(330, 506), 1.0, fx)
	if neutral:
		for l in mv.layers.values():
			l.material = null
	_run()


func _process(delta: float) -> void:
	_t += delta


func _mark(label: String) -> void:
	print("DIAG t=%.3f %s" % [_t, label])


func _run() -> void:
	await get_tree().create_timer(1.0).timeout
	var targets := [Vector2(900, 445), Vector2(1028, 413), Vector2(1150, 437)]
	for i in range(3):
		_mark("souffle_prepare_%d" % i)
		mv.set_telegraph(true)
		await get_tree().create_timer(2.0).timeout
		_mark("souffle_hit_%d" % i)
		await mv.breath(targets)
		mv.set_telegraph(false)
		await get_tree().create_timer(1.0).timeout
	for i in range(3):
		_mark("griffe_prepare_%d" % i)
		mv.prepare()
		await get_tree().create_timer(0.3).timeout
		_mark("griffe_hit_%d" % i)
		await mv.lunge(targets[0])
		await get_tree().create_timer(1.2).timeout
	_mark("fin")
	get_tree().quit()
