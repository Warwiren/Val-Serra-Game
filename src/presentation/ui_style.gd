extends RefCounted
## Charte de l'interface de combat (brief unifié v1.1, § 5 et annexe B) — SOURCE UNIQUE des couleurs, polices
## et dimensions. Aucun code couleur de l'interface ne doit être écrit ailleurs : utiliser UiStyle.C_*.

# --- Fonds -------------------------------------------------------------------------------------------
const C_BG := Color("#0B1220")            # écran très sombre
const C_PANEL := Color("#13233A")         # panneaux
const C_PANEL_2 := Color("#1B314D")       # panneaux secondaires
const C_SEP := Color("#233955")           # séparateurs / bordures neutres
# --- Texte -------------------------------------------------------------------------------------------
const C_TEXT := Color("#F2EEE6")          # principal (ivoire)
const C_TEXT_2 := Color("#C8D2E0")        # secondaire
const C_TEXT_DIM := Color("#91A2B8")      # discret
# --- Accents -----------------------------------------------------------------------------------------
const C_GOLD := Color("#D6A85D")          # liseré or
const C_SELECT := Color("#F2C978")        # sélection (or clair)
# --- Fonctionnelles (jauges, icônes, bordures uniquement) -------------------------------------------
const C_HP_ALLY := Color("#77D28C")
const C_RESOURCE := Color("#56B9E8")      # Résonance
const C_HP_BOSS := Color("#D94B5D")
const C_BREAK := Color("#B574E6")         # rupture / intégrité des parties
const C_AETHER := Color("#55D9E6")
const C_VIF := Color("#4AA8FF")
const C_MESURE := Color("#D6A85D")
const C_CHARGE := Color("#B06BFF")
const C_WEAK := Color("#FFBE55")
const C_DANGER := Color("#FF6B6B")
const C_HEAL := Color("#7DDB9A")

const MODE_COLORS := {"VIF": C_VIF, "MESURE": C_MESURE, "CHARGE": C_CHARGE}
const MODE_TITLES := {"VIF": "VIF", "MESURE": "MESURÉ", "CHARGE": "CHARGÉ"}
const MODE_ARROWS := {"VIF": 3, "MESURE": 2, "CHARGE": 1}   # chevrons : rapidité relative

# --- Typographie (1280 × 720) -------------------------------------------------------------------------
const FS_TITLE := 22       # logo, titres
const FS_MAIN := 16        # texte courant (15–17)
const FS_SMALL := 13       # information secondaire (13–14)
const FS_TINY := 12        # graduations, compteurs

const FONT_UI := "res://art/fonts/Inter-Regular.otf"
const FONT_UI_BOLD := "res://art/fonts/Inter-SemiBold.otf"
const FONT_TITLE := "res://art/fonts/Caladea-Bold.ttf"

# --- Dimensions / disposition (référence : annexe A) -----------------------------------------------------
const MARGIN := 14.0
const RADIUS := 6
const PARTY_W := 262.0
const PARTY_H := 66.0
const MENU_W := 232.0
const BOSS_BAR_W := 560.0

static var _fonts: Dictionary = {}


static func font(path := FONT_UI) -> Font:
	if not _fonts.has(path):
		_fonts[path] = load(path)
	return _fonts[path]


static func bold() -> Font:
	return font(FONT_UI_BOLD)


static func title_font() -> Font:
	return font(FONT_TITLE)


## Panneau : bleu nuit, bordure fine ; la sélection se marque par un CONTOUR doré, jamais par un grand aplat.
static func box(bg := C_PANEL, edge := C_SEP, border := 1, radius := RADIUS, alpha := 0.92) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(bg, alpha)
	s.border_color = edge
	s.set_border_width_all(border if edge.a > 0 else 0)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s


static func make_theme() -> Theme:
	var th := Theme.new()
	th.default_font = font()
	th.default_font_size = FS_MAIN
	th.set_stylebox("normal", "Button", box(C_PANEL, C_SEP))
	th.set_stylebox("hover", "Button", box(C_PANEL_2, C_TEXT_DIM))
	th.set_stylebox("pressed", "Button", box(C_PANEL_2, C_SELECT, 2))
	th.set_stylebox("hover_pressed", "Button", box(C_PANEL_2, C_SELECT, 2))
	th.set_stylebox("disabled", "Button", box(C_BG, C_SEP, 1, RADIUS, 0.8))
	th.set_stylebox("focus", "Button", box(C_PANEL, C_SELECT, 2, RADIUS, 0.0))
	th.set_color("font_color", "Button", C_TEXT)
	th.set_color("font_hover_color", "Button", C_TEXT)
	th.set_color("font_pressed_color", "Button", C_SELECT)
	th.set_color("font_hover_pressed_color", "Button", C_SELECT)
	th.set_color("font_disabled_color", "Button", C_TEXT_DIM)
	th.set_font("font", "Button", bold())
	th.set_font_size("font_size", "Button", FS_MAIN)
	th.set_color("font_color", "Label", C_TEXT)
	th.set_color("default_color", "RichTextLabel", C_TEXT)
	th.set_font("normal_font", "RichTextLabel", font())
	th.set_font("bold_font", "RichTextLabel", bold())
	th.set_font_size("normal_font_size", "RichTextLabel", FS_MAIN)
	th.set_font_size("bold_font_size", "RichTextLabel", FS_MAIN)
	th.set_stylebox("panel", "Panel", box())
	th.set_stylebox("panel", "PanelContainer", box())
	th.set_stylebox("panel", "TooltipPanel", box(C_BG, C_GOLD, 1))
	th.set_color("font_color", "TooltipLabel", C_TEXT)
	return th


## Petites icônes vectorielles (dessinées, pas de glyphes de police) : action ou rôle.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, r: float, col: Color) -> void:
	match kind:
		"attaque", "sword":
			ci.draw_line(c + Vector2(-r, r), c + Vector2(r * 0.8, -r * 0.8), col, 2.0, true)
			ci.draw_line(c + Vector2(-r * 0.75, r * 0.25), c + Vector2(-r * 0.25, r * 0.75), col, 2.0, true)
		"technique", "daggers":
			ci.draw_line(c + Vector2(-r, r), c + Vector2(r * 0.6, -r * 0.6), col, 2.0, true)
			ci.draw_line(c + Vector2(r, r), c + Vector2(-r * 0.6, -r * 0.6), col, 2.0, true)
		"garde", "shield":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.8), c + Vector2(r * 0.8, -r * 0.8),
				c + Vector2(r * 0.7, r * 0.2), c + Vector2(0, r), c + Vector2(-r * 0.7, r * 0.2)]), Color(col, 0.35))
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.8), c + Vector2(r * 0.8, -r * 0.8),
				c + Vector2(r * 0.7, r * 0.2), c + Vector2(0, r), c + Vector2(-r * 0.7, r * 0.2), c + Vector2(-r * 0.8, -r * 0.8)]), col, 1.6, true)
		"potion":
			ci.draw_circle(c + Vector2(0, r * 0.25), r * 0.7, Color(col, 0.35))
			ci.draw_arc(c + Vector2(0, r * 0.25), r * 0.7, 0, TAU, 20, col, 1.6, true)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.25, -r), Vector2(r * 0.5, r * 0.6)), col)
		"serum_pulsation", "aether":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.7, 0), c + Vector2(0, r), c + Vector2(-r * 0.7, 0)]), Color(col, 0.4))
			ci.draw_polyline(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.7, 0), c + Vector2(0, r), c + Vector2(-r * 0.7, 0), c + Vector2(0, -r)]), col, 1.6, true)
		"hammer":
			ci.draw_line(c + Vector2(-r * 0.6, r), c + Vector2(r * 0.4, -r * 0.2), col, 2.0, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.0, -r * 0.9), c + Vector2(r, -r * 0.1), c + Vector2(r * 0.6, r * 0.3), c + Vector2(-r * 0.4, -r * 0.5)]), col)
		"warn":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, r * 0.8), c + Vector2(-r, r * 0.8)]), Color(col, 0.85))
			ci.draw_line(c + Vector2(0, -r * 0.35), c + Vector2(0, r * 0.25), C_BG, 2.0)
			ci.draw_circle(c + Vector2(0, r * 0.55), 1.4, C_BG)
		"broken":
			ci.draw_arc(c, r * 0.8, 0, TAU, 20, col, 1.6, true)
			ci.draw_line(c + Vector2(-r * 0.5, -r * 0.5), c + Vector2(r * 0.5, r * 0.5), col, 2.0, true)
			ci.draw_line(c + Vector2(r * 0.5, -r * 0.5), c + Vector2(-r * 0.5, r * 0.5), col, 2.0, true)
		_:
			ci.draw_circle(c, r * 0.5, col)


## Jauge : fond sombre, valeur, traîne (valeur affichée qui rattrape la vraie).
static func draw_gauge(ci: CanvasItem, rect: Rect2, ratio: float, trail: float, col: Color) -> void:
	ci.draw_rect(rect, Color(C_BG, 0.9))
	ci.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(trail, 0, 1), rect.size.y)), Color(C_TEXT, 0.35))
	ci.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio, 0, 1), rect.size.y)), col)
	ci.draw_rect(rect, Color(C_SEP, 1.0), false, 1.0)
