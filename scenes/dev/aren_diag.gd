extends Node2D
## OUTIL DE DÉVELOPPEMENT (hors parcours normal) — diagnostic des poses de combat d'Aren.
## Dans le décor du combat : 3 attaques (préparation, frappe, impact, retour), une garde, un coup reçu.
## Lancement : godot --path . res://scenes/dev/aren_diag.tscn

const ProtoHero = preload("res://src/proto/pack_hunter_view.gd")

var aren
var _t := 0.0


func _ready() -> void:
	var bg := Sprite2D.new()
	bg.texture = load("res://art/proto/zone_bg.png")
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.centered = false
	bg.scale = Vector2(3, 3)
	add_child(bg)
	var cm := CanvasModulate.new()
	cm.color = Color(0.8, 0.8, 0.92)
	add_child(cm)
	var others := {"compagnon_vif": ["ilya", Vector2(1028, 468)], "compagnon_lourd": ["throne", Vector2(1150, 492)]}
	for id in others:
		var h := ProtoHero.new()
		add_child(h)
		h.setup(id, {"sprite": others[id][0], "combat": true}, others[id][1])
		h.scale.x = -1
	aren = ProtoHero.new()
	add_child(aren)
	aren.setup("heros", {"sprite": "aren", "combat": true}, Vector2(900, 500))
	aren.scale.x = -1
	_run()


func _process(delta: float) -> void:
	_t += delta


func _mark(s: String) -> void:
	print("DIAG t=%.3f %s" % [_t, s])


func _run() -> void:
	await get_tree().create_timer(0.8).timeout
	for i in range(3):
		_mark("prepare_%d" % i)
		aren.prepare("MESURE" if i < 2 else "CHARGE")
		await get_tree().create_timer(0.5).timeout
		_mark("attack_%d" % i)
		await aren.attack(Vector2(420, 430), i == 2)
		await get_tree().create_timer(0.9).timeout
	_mark("guard")
	aren.set_guard(true)
	await get_tree().create_timer(1.0).timeout
	aren.guard_flash()
	await get_tree().create_timer(0.8).timeout
	_mark("hurt")
	aren.hurt(true)
	await get_tree().create_timer(1.0).timeout
	_mark("fin")
	get_tree().quit()
