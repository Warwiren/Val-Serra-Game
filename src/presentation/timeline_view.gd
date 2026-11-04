extends Control
## Chronologie d'initiative : axe de temps PROPORTIONNEL (la distance = le délai réel).
##  - Au-dessus de l'axe : portraits = prochaines décisions (estompés = projections).
##  - Sous l'axe : losanges = effets en préparation (rouge ⚠ = attaque annoncée, or = votre choix).

const Art = preload("res://src/presentation/art.gd")

const SPAN := 200.0        # unités de temps visibles
const AXIS_Y := 62.0

var events: Array = []
var now: int = 0
var current_id: String = ""
var portraits: Dictionary = {}       # actor_id -> Texture2D
var colors: Dictionary = {}          # actor_id -> Color
var short_names: Dictionary = {}     # actor_id -> String
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _x_of(time: int) -> float:
	var x0 := 150.0
	var x1 := size.x - 40.0
	return x0 + clampf(float(time - now) / SPAN, 0.0, 1.0) * (x1 - x0)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w := size.x
	draw_rect(Rect2(0, 0, w, size.y), Color(0.03, 0.05, 0.08, 0.78))
	draw_line(Vector2(0, size.y), Vector2(w, size.y), Art.C_PANEL_EDGE, 2.0)

	# Bloc « À vous » : portrait du Chasseur qui décide
	if current_id != "" and portraits.has(current_id):
		_chip(Vector2(64, 58), 40.0, current_id, 1.0, true)
		draw_string(font, Vector2(4, size.y - 6), "À JOUER", HORIZONTAL_ALIGNMENT_CENTER, 120, 14, Art.C_GOLD)

	# Axe et graduations
	var x0 := _x_of(now)
	var x1 := size.x - 40.0
	draw_line(Vector2(x0, AXIS_Y), Vector2(x1 + 20, AXIS_Y), Color(0.75, 0.85, 0.95, 0.55), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x1 + 30, AXIS_Y), Vector2(x1 + 18, AXIS_Y - 7), Vector2(x1 + 18, AXIS_Y + 7)]), Color(0.75, 0.85, 0.95, 0.55))
	for k in range(0, int(SPAN) + 1, 25):
		var x := _x_of(now + k)
		draw_line(Vector2(x, AXIS_Y - 5), Vector2(x, AXIS_Y + 5), Color(0.75, 0.85, 0.95, 0.5), 2.0)
		draw_string(font, Vector2(x - 30, AXIS_Y + 22), "" if k == 0 else "+%d" % k, HORIZONTAL_ALIGNMENT_CENTER, 60, 12, Art.C_DIM)

	# Effets (sous l'axe) puis décisions (au-dessus)
	var placed_low: Array = []
	var placed_high: Array = []
	for e in events:
		if e["kind"] != "resolve":
			continue
		var x := _x_of(e["time"])
		var cast = e["cast"]
		var col: Color = colors.get(e["actor_id"], Color.WHITE)
		var label := ""
		var size_d := 11.0
		if e["hypothetical"]:
			col = Art.C_GOLD
			label = "Votre effet +%d" % (int(e["time"]) - now)
			size_d = 13.0 + 2.0 * sin(_t * 6.0)
		elif cast.telegraph:
			col = Color(1.0, 0.35 + 0.15 * sin(_t * 8.0), 0.3)
			label = "⚠ %s +%d" % [cast.action_name, int(e["time"]) - now]
			size_d = 14.0
		else:
			label = cast.action_name.split(" ")[0]
		var y := AXIS_Y + 34.0 + _stack(placed_low, x) * 20.0
		draw_line(Vector2(x, AXIS_Y), Vector2(x, y - size_d), Color(col, 0.6), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x, y - size_d), Vector2(x + size_d, y), Vector2(x, y + size_d), Vector2(x - size_d, y)]), col)
		draw_polyline(PackedVector2Array([Vector2(x, y - size_d), Vector2(x + size_d, y), Vector2(x, y + size_d), Vector2(x - size_d, y), Vector2(x, y - size_d)]), Color(0, 0, 0, 0.8), 2.0)
		var fs := 15 if (e["hypothetical"] or cast.telegraph) else 12
		draw_string_outline(font, Vector2(x + size_d + 4, y + 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(x + size_d + 4, y + 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

	var seen: Dictionary = {}
	for e in events:
		if e["kind"] != "ready":
			continue
		var id: String = e["actor_id"]
		if id == current_id and not e["projected"]:
			continue
		var first: bool = not seen.has(id)
		seen[id] = true
		var x := _x_of(e["time"])
		if int(e["time"]) - now > SPAN:
			continue
		var cx := x + _stack(placed_high, x) * 24.0
		var alpha := 1.0 if first else 0.45
		draw_line(Vector2(x, AXIS_Y), Vector2(cx, AXIS_Y - 14), Color(colors.get(id, Color.WHITE), 0.6 * alpha), 2.0)
		_chip(Vector2(cx, AXIS_Y - 32), 19.0 if first else 15.0, id, alpha, false)
		if first:
			draw_string_outline(font, Vector2(cx - 30, AXIS_Y - 54), "+%d" % (int(e["time"]) - now), HORIZONTAL_ALIGNMENT_CENTER, 60, 12, 4, Color(0, 0, 0, 0.9))
			draw_string(font, Vector2(cx - 30, AXIS_Y - 54), "+%d" % (int(e["time"]) - now), HORIZONTAL_ALIGNMENT_CENTER, 60, 12, Art.C_TEXT)


## Décalage pour éviter les chevauchements : renvoie un niveau d'empilement.
func _stack(placed: Array, x: float) -> int:
	var level := 0
	for px in placed:
		if absf(px - x) < 36.0:
			level += 1
	placed.append(x)
	return level


func _chip(c: Vector2, r: float, id: String, alpha: float, big: bool) -> void:
	var col: Color = colors.get(id, Color.WHITE)
	draw_circle(c, r + 3, Color(0, 0, 0, 0.8 * alpha))
	draw_circle(c, r, Color(0.12, 0.15, 0.2, alpha))
	var tex: Texture2D = portraits.get(id)
	if tex != null:
		draw_texture_rect(tex, Rect2(c - Vector2(r, r) * 1.05, Vector2(r, r) * 2.1), false, Color(1, 1, 1, alpha))
	draw_arc(c, r, 0, TAU, 32, Color(col, alpha), 4.0 if big else 3.0, true)
	if big:
		draw_arc(c, r + 6, 0, TAU, 40, Color(Art.C_GOLD, 0.4 + 0.3 * sin(_t * 5.0)), 3.0, true)
