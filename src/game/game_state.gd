extends Node
## État de partie global (autoload « GameState ») : héros choisi, inventaire, progression de la micro-boucle,
## mode de rendu A/B et transitions entre scènes. Volontairement minimal pour le MVP.

signal render_mode_changed(mode: String)

const SCENE_HERO_SELECT := "res://scenes/explore/hero_select.tscn"
const SCENE_ZONE := "res://scenes/explore/zone.tscn"
const SCENE_BATTLE := "res://scenes/battle/battle_scene.tscn"
const SCENE_DEBUG := "res://scenes/debug/combat_debug.tscn"
const SCENE_RIG_VIEWER := "res://scenes/art/rig_viewer.tscn"
## Prototype recentré (scène principale) : zone de l'avant-poste -> combat dans la même clairière
const SCENE_PROTO_ZONE := "res://scenes/proto/proto_zone.tscn"
const SCENE_PROTO_BATTLE := "res://scenes/battle/battle_scene.tscn"

const RENDER_2D := "A"      # Variante A : 2D illustrée simple
const RENDER_25D := "B"     # Variante B : 2.5D (calques, parallax, lumière, particules)

# Héros
var hero_gender: String = "m"          # "m" ou "f"
var hero_name: String = "Aren"

# Progression de la micro-boucle
var potions: int = 2
var currency: int = 0
var materials: Dictionary = {}
var enemy_defeated: bool = false
var flags: Dictionary = {}
var from_zone: bool = false            # le combat a-t-il été lancé depuis la zone ?
var zone_return_pos: Vector2 = Vector2.ZERO
var last_battle_result: String = ""

# Présentation
var render_mode: String = RENDER_25D
var autoplay: bool = false             # démonstration automatique (captures vidéo)
var hd2d: bool = false                 # combat HD-2D : Aren et Vorgane en sprites pixel art
var proto: bool = false                # prototype recentré (pack visuel) : présentation unifiée, interface épurée
var art_proto: bool = false            # prototype artistique HD (héros et monstre articulés, arène nocturne)

var _fade: ColorRect
var _fps: Label


func _ready() -> void:
	autoplay = OS.get_cmdline_user_args().has("--autoplay")
	for arg in OS.get_cmdline_user_args():
		if arg == "--render=A":
			render_mode = RENDER_2D
		elif arg == "--render=B":
			render_mode = RENDER_25D
		elif arg == "--hero=f":
			new_game("f", "")
		elif arg == "--start=battle":
			_start_scene.call_deferred(SCENE_BATTLE)
		elif arg == "--start=zone":
			_start_scene.call_deferred(SCENE_ZONE)
		elif arg == "--start=rigviewer":
			_start_scene.call_deferred(SCENE_RIG_VIEWER)
		elif arg == "--start=hd2d":
			hd2d = true
			_start_scene.call_deferred(SCENE_BATTLE)
		elif arg == "--start=proto-battle":
			proto = true
			_start_scene.call_deferred(SCENE_PROTO_BATTLE)
		elif arg == "--start=artproto":
			art_proto = true
			_start_scene.call_deferred(SCENE_BATTLE)
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.04, 0.06, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_fps = Label.new()
	_fps.position = Vector2(1180, 694)
	_fps.add_theme_font_size_override("font_size", 14)
	_fps.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_fps.add_theme_constant_override("outline_size", 5)
	_fps.visible = false
	layer.add_child(_fps)


func _process(_delta: float) -> void:
	if _fps.visible:
		_fps.text = "%d img/s · %s" % [Engine.get_frames_per_second(), render_mode]


## Lancement direct d'une scène (démo, captures) : godot --path . -- --start=battle
func _start_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		if not proto:
			toggle_render_mode()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_fps.visible = not _fps.visible


func toggle_render_mode() -> void:
	render_mode = RENDER_2D if render_mode == RENDER_25D else RENDER_25D
	render_mode_changed.emit(render_mode)


func render_label() -> String:
	return "Rendu : 2.5D (B)" if render_mode == RENDER_25D else "Rendu : 2D (A)"


## Nouvelle partie (après le choix du héros).
func new_game(gender: String, chosen_name: String) -> void:
	hero_gender = gender
	hero_name = chosen_name.strip_edges() if chosen_name.strip_edges() != "" else ("Aren" if gender == "m" else "Ilya")
	potions = 2
	currency = 0
	materials = {}
	enemy_defeated = false
	flags = {}
	zone_return_pos = Vector2.ZERO


## Remplace {nom} et les accords {m:prêt|f:prête} selon le héros choisi.
func g(text: String) -> String:
	var out := text.replace("{nom}", hero_name)
	var re := RegEx.new()
	re.compile("\\{m:([^|}]*)\\|f:([^}]*)\\}")
	var result := ""
	var last := 0
	for m in re.search_all(out):
		result += out.substr(last, m.get_start() - last)
		result += m.get_string(1) if hero_gender == "m" else m.get_string(2)
		last = m.get_end()
	result += out.substr(last)
	return result


func hero_portrait() -> String:
	return "res://art/portraits/hero_%s.svg" % hero_gender


func add_rewards(rewards: Dictionary) -> void:
	currency += int(rewards.get("currency", 0))
	var items: Dictionary = rewards.get("items", {})
	for k in items:
		materials[k] = int(materials.get(k, 0)) + int(items[k])


## Changement de scène avec fondu au noir.
func goto(scene_path: String, duration := 0.35) -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, duration)
	await t.finished
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	var t2 := create_tween()
	t2.tween_property(_fade, "color:a", 0.0, duration)
	await t2.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


const MATERIAL_NAMES := {
	"cuir_vorgane": "Cuir de Vorgane",
	"griffe_vorgane": "Griffe de Vorgane",
	"eclat_carapace": "Éclat de carapace",
	"glande_aether": "Glande d'Aether",
}


func material_name(id: String) -> String:
	return MATERIAL_NAMES.get(id, id)
