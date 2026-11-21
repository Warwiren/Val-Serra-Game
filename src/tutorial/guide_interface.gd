extends Control
## P6 — GUIDE D'INTERFACE réutilisable (tutoriels) : met en évidence un ou plusieurs composants RÉELS de l'interface
## et affiche une bulle de l'instructeur. Aucune copie de l'interface, aucune position codée en dur : les cibles sont
## résolues À CHAQUE IMAGE par un Callable fourni par la scène (clé -> Rect2 en coordonnées de ce calque), donc le
## cadre suit les composants quelle que soit la taille de la fenêtre.
##
##   - voile sombre sur tout l'écran, DÉCOUPÉ autour des cibles (shader, coins arrondis) ;
##   - contour doré animé (pulsation) autour de chaque cible ;
##   - bulle : portrait + nom de l'orateur + texte progressif + consigne (Entrée / clic : continuer) ;
##   - deux modes : « suite » (le guide bloque l'interface et attend Entrée / Espace / clic) et « action » (voile léger,
##     l'interface reste utilisable : c'est la scène qui vérifie l'action demandée).
## Le déroulé (quelles étapes, quand) appartient à la scène : ce nœud ne connaît ni le combat ni ses règles.

signal advanced                 # l'étape « suite » a été lue (Entrée / clic)
signal escape_pressed           # Échap pendant le tutoriel (la scène répond par une réplique)

const UI = preload("res://src/presentation/ui_style.gd")
const Portraits = preload("res://src/proto/portraits.gd")
const MAX_TROUS := 4
const MARGE := 8.0

const VOILE_SH := """
shader_type canvas_item;
uniform vec2 taille = vec2(1280.0, 720.0);
uniform vec4 trous[4];
uniform int n = 0;
uniform float opacite = 0.55;
uniform float rayon = 10.0;
float sd_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}
void fragment() {
	vec2 p = UV * taille;
	float a = opacite;
	for (int i = 0; i < 4; i++) {
		if (i >= n) { break; }
		vec4 t = trous[i];
		float d = sd_box(p - (t.xy + t.zw * 0.5), t.zw * 0.5, rayon);
		a = min(a, opacite * smoothstep(-1.5, 6.0, d));
	}
	COLOR = vec4(0.02, 0.03, 0.06, a);
}
"""

var resoudre: Callable                  # func(cle: String) -> Rect2 (Rect2() si introuvable)
var orateur := ""
var portrait_id := "pnj"
var mode := ""                           # "" (masqué), "suite", "action"
var cibles: Array = []
var _rects: Array = []
var _t := 0.0
var _voile: ColorRect
var _bulle: PanelContainer
var _nom: Label
var _texte: RichTextLabel
var _consigne: Label
var _portrait: TextureRect
var _tw: Tween
var _opacite := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UI.make_theme()
	_voile = ColorRect.new()
	_voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_voile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = VOILE_SH
	var mm := ShaderMaterial.new()
	mm.shader = sh
	_voile.material = mm
	add_child(_voile)
	# bulle : ancrée en haut au centre, sous la frise d'initiative (le théâtre du combat reste dégagé en bas)
	_bulle = PanelContainer.new()
	_bulle.anchor_left = 0.5
	_bulle.anchor_right = 0.5
	_bulle.offset_left = -330
	_bulle.offset_right = 330
	_bulle.offset_top = 108
	_bulle.grow_vertical = Control.GROW_DIRECTION_END
	_bulle.add_theme_stylebox_override("panel", UI.box(UI.C_PANEL, UI.C_GOLD, 2, 8, 0.96))
	_bulle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bulle)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	_bulle.add_child(h)
	var cadre := PanelContainer.new()
	cadre.add_theme_stylebox_override("panel", UI.box(UI.C_BG, UI.C_GOLD, 1, 6, 0.9))
	cadre.custom_minimum_size = Vector2(76, 76)
	cadre.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(cadre)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.custom_minimum_size = Vector2(70, 70)
	cadre.add_child(_portrait)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	h.add_child(v)
	_nom = Label.new()
	_nom.add_theme_font_override("font", UI.title_font())
	_nom.add_theme_font_size_override("font_size", 18)
	_nom.add_theme_color_override("font_color", UI.C_SELECT)
	v.add_child(_nom)
	_texte = RichTextLabel.new()
	_texte.bbcode_enabled = true
	_texte.fit_content = true
	_texte.scroll_active = false
	_texte.custom_minimum_size = Vector2(540, 0)
	_texte.add_theme_font_size_override("normal_font_size", 17)
	_texte.add_theme_color_override("default_color", UI.C_TEXT)
	_texte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_texte)
	_consigne = Label.new()
	_consigne.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_consigne.add_theme_font_size_override("font_size", UI.FS_SMALL)
	_consigne.add_theme_color_override("font_color", UI.C_TEXT_DIM)
	v.add_child(_consigne)
	visible = false


## Affiche une étape. `m` = "suite" (bloque et attend la lecture) ou "action" (laisse jouer).
func montrer(texte: String, cles: Array, m := "suite") -> void:
	mode = m
	cibles = cles
	visible = true
	_nom.text = orateur
	_portrait.texture = Portraits.get_texture(portrait_id)
	_portrait.get_parent().visible = _portrait.texture != null
	_texte.text = texte
	_texte.visible_ratio = 0.0
	if _tw != null and _tw.is_running():
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(_texte, "visible_ratio", 1.0, clampf(0.018 * texte.length(), 0.25, 1.6))
	_consigne.text = "Entrée / Espace / clic : continuer" if m == "suite" else "À vous de jouer"
	# « suite » : le guide capte la souris (clic n'importe où) ; « action » : l'interface reste cliquable
	mouse_filter = Control.MOUSE_FILTER_STOP if m == "suite" else Control.MOUSE_FILTER_IGNORE
	_opacite = 0.62 if m == "suite" else 0.3
	_maj_rects()


## Réplique ponctuelle sans changer d'étape (refus d'une action, tentative de quitter) : texte seul, mode conservé.
func interjection(texte: String) -> void:
	_texte.text = texte
	_texte.visible_ratio = 1.0
	_bulle.modulate = Color(1.25, 1.1, 1.1)
	create_tween().tween_property(_bulle, "modulate", Color.WHITE, 0.5)


func masquer() -> void:
	mode = ""
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func texte_complet() -> bool:
	return _texte.visible_ratio >= 1.0


func rects() -> Array:
	return _rects


func _maj_rects() -> void:
	_rects.clear()
	if resoudre.is_valid():
		for c in cibles:
			var r: Rect2 = resoudre.call(c)
			if r.size.x > 1.0 and r.size.y > 1.0:
				_rects.append(r.grow(MARGE))
	var mm := _voile.material as ShaderMaterial
	var arr: Array = []
	for i in MAX_TROUS:
		var r: Rect2 = _rects[i] if i < _rects.size() else Rect2()
		arr.append(Vector4(r.position.x, r.position.y, r.size.x, r.size.y))
	mm.set_shader_parameter("trous", arr)
	mm.set_shader_parameter("n", mini(_rects.size(), MAX_TROUS))
	mm.set_shader_parameter("taille", size)
	mm.set_shader_parameter("opacite", _opacite)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_maj_rects()
	queue_redraw()


func _draw() -> void:
	var k := 0.5 + 0.5 * sin(_t * 4.2)
	for r in _rects:
		var rr: Rect2 = r
		draw_style_box(_contour(Color(UI.C_SELECT, 0.55 + 0.45 * k), 2.0 + 1.5 * k), rr)
		draw_style_box(_contour(Color(UI.C_SELECT, 0.18 * (1.0 - k)), 1.0), rr.grow(4.0 + 6.0 * k))


func _contour(c: Color, w: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = c
	sb.set_border_width_all(int(round(w)))
	sb.set_corner_radius_all(10)
	sb.anti_aliasing = true
	return sb


func _gui_input(e: InputEvent) -> void:
	if mode == "suite" and e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_avancer()


func _input(e: InputEvent) -> void:
	if not visible or not (e is InputEventKey) or not e.pressed or e.echo:
		return
	if e.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		escape_pressed.emit()
		return
	if mode == "suite" and (e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] or e.physical_keycode == KEY_E):
		get_viewport().set_input_as_handled()
		_avancer()


func _avancer() -> void:
	if not texte_complet():
		if _tw != null:
			_tw.kill()
		_texte.visible_ratio = 1.0              # premier appui : texte entier
		return
	advanced.emit()


## Outil de test / démonstration : avance comme le joueur.
func simuler_suite() -> void:
	if mode == "suite":
		if _tw != null:
			_tw.kill()
		_texte.visible_ratio = 1.0
		advanced.emit()
