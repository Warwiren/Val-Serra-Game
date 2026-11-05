extends "res://src/presentation/timeline_view.gd"
## Frise d'initiative (brief unifié v1.1, § 4.2) — haut centre.
## ORDRE calculé par le planificateur du CombatCore (battle.preview_timeline) : on affiche la SÉQUENCE des
## prochains événements, à espacement fixe (aucune collision possible même avec 10 événements rapprochés).
## Sous chaque élément : délai RÉEL en unités de temps du moteur (« +24 »), jamais de « tours » fictifs.
##  - grand portrait doré à gauche : l'acteur qui décide maintenant ;
##  - portraits : prochaines décisions (alliés : liseré ivoire ; ennemi : liseré rouge ; projections estompées) ;
##  - losanges : effets en préparation (rouge + libellé = attaque ANNONCÉE ; or = effet de votre choix).
## Au-delà de la largeur disponible : pastille « +N » (regroupement) au lieu de chevaucher.

const UI = preload("res://src/presentation/ui_style.gd")

const SLOT_PORTRAIT := 52.0
const SLOT_EFFECT := 40.0
const R_PORTRAIT := 17.0
const R_ACTIVE := 23.0
const ROW_Y := 44.0

var enemy_ids: Array = []
var enemy_aim: Array = []


func _draw() -> void:
	var w := size.x
	draw_style_box(UI.box(UI.C_BG, UI.C_SEP, 1, UI.RADIUS, 0.78), Rect2(Vector2.ZERO, size))
	var f := UI.bold()
	draw_string(f, Vector2(0, 14), "INITIATIVE", HORIZONTAL_ALIGNMENT_CENTER, w, UI.FS_TINY, UI.C_TEXT_DIM)

	var items := _items()
	var x := 14.0
	# Acteur actif
	if current_id != "":
		var c := Vector2(x + R_ACTIVE, ROW_Y)
		_portrait(c, R_ACTIVE, current_id, 1.0)
		var pulse := 0.55 + 0.35 * sin(_t * 4.0)
		draw_arc(c, R_ACTIVE + 4, 0, TAU, 40, Color(UI.C_SELECT, pulse), 2.0, true)
		draw_string(UI.bold(), Vector2(c.x - 40, ROW_Y + R_ACTIVE + 16), "À jouer", HORIZONTAL_ALIGNMENT_CENTER, 80, UI.FS_TINY, UI.C_SELECT)
		x += R_ACTIVE * 2 + 18
	# Ligne de temps (sens de lecture)
	var x_end := w - 46.0
	draw_line(Vector2(x - 6, ROW_Y), Vector2(x_end + 10, ROW_Y), Color(UI.C_SEP, 1.0), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x_end + 18, ROW_Y), Vector2(x_end + 10, ROW_Y - 5), Vector2(x_end + 10, ROW_Y + 5)]), UI.C_SEP)
	var shown := 0
	for it in items:
		var slot: float = SLOT_PORTRAIT if it["kind"] == "ready" else SLOT_EFFECT
		if x + slot > x_end:
			break
		var c := Vector2(x + slot * 0.5, ROW_Y)
		if it["kind"] == "ready":
			_portrait(c, R_PORTRAIT, it["id"], 1.0 if it["first"] else 0.5)
			_label(c, "+%d" % it["dt"], UI.C_TEXT_2 if it["first"] else UI.C_TEXT_DIM, R_PORTRAIT)
		else:
			var col: Color = it["color"]
			var r := 7.0 if it["major"] else 5.0
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)
			draw_polyline(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0), c + Vector2(0, -r)]), Color(UI.C_BG, 0.9), 1.5)
			if it["major"]:
				# libellé au-dessus (le texte porte l'info, pas seulement la couleur)
				draw_string(UI.bold(), Vector2(c.x - 60, ROW_Y - 12), it["label"], HORIZONTAL_ALIGNMENT_CENTER, 120, UI.FS_TINY, col)
			_label(c, "+%d" % it["dt"], col if it["major"] else UI.C_TEXT_DIM, r)
		x += slot
		shown += 1
	var rest := items.size() - shown
	if rest > 0:
		var c := Vector2(w - 26, ROW_Y)
		draw_circle(c, 13, UI.C_PANEL_2)
		draw_arc(c, 13, 0, TAU, 24, UI.C_SEP, 1.5, true)
		draw_string(UI.bold(), Vector2(c.x - 20, c.y + 5), "+%d" % rest, HORIZONTAL_ALIGNMENT_CENTER, 40, UI.FS_TINY, UI.C_TEXT_2)


func _label(c: Vector2, text: String, col: Color, r: float) -> void:
	draw_string(UI.font(), Vector2(c.x - 26, ROW_Y + r + 16), text, HORIZONTAL_ALIGNMENT_CENTER, 52, UI.FS_TINY, col)


## Séquence ordonnée (temps, puis ordre stable du moteur) des événements à venir.
func _items() -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	var evs := events.duplicate()
	evs.sort_custom(func(a, b): return int(a["time"]) < int(b["time"]))
	for e in evs:
		var dt: int = int(e["time"]) - now
		if e["kind"] == "ready":
			var id: String = e["actor_id"]
			if id == current_id and not e["projected"]:
				continue
			out.append({"kind": "ready", "id": id, "dt": dt, "first": not seen.has(id)})
			seen[id] = true
		elif e["kind"] == "resolve":
			var cast = e["cast"]
			var it := {"kind": "effect", "dt": dt, "major": false, "label": "",
				"color": UI.C_HP_BOSS if enemy_ids.has(e["actor_id"]) else UI.C_TEXT_2}
			if e["hypothetical"]:
				it["major"] = true
				it["color"] = UI.C_SELECT
				it["label"] = "Votre effet"
			elif cast.telegraph:
				it["major"] = true
				it["color"] = UI.C_DANGER
				it["label"] = cast.action_name.split(" ")[0]
			elif enemy_ids.has(e["actor_id"]) and cast.target_id != "":
				# intention ennemie monocible : « → Ilya » (cible verrouillée dans l'action)
				it["major"] = true
				it["color"] = UI.C_DANGER
				it["label"] = "→ " + String(short_names.get(cast.target_id, cast.target_id))
			out.append(it)
	return out


func _portrait(c: Vector2, r: float, id: String, alpha: float) -> void:
	var enemy := enemy_ids.has(id)
	draw_circle(c, r + 2, Color(UI.C_BG, alpha))
	draw_circle(c, r, Color(UI.C_PANEL_2, alpha))
	var tex: Texture2D = portraits.get(id)
	if tex != null:
		draw_texture_rect(tex, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1, 1, 1, alpha))
	draw_arc(c, r, 0, TAU, 32, Color(UI.C_HP_BOSS if enemy else UI.C_TEXT_2, alpha), 2.0, true)
