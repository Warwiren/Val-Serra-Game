extends Node2D
## EXPLORATION HD-2D — scène expérimentale (branche exploration-hd2d), indépendante de la boucle actuelle.
## Décor : zone construite dans Blender sous la caméra commune (plongée 35°, rotation 20°), puis passe « peinture »
## pixel art (tools/explore/scene_blender.py + paint_pass.py). Le fond contient tout ; chaque élément contournable
## est AUSSI un sprite découpé au pixel près, trié en profondeur avec les personnages selon la ligne de ses pieds.
## Monde en pixels natifs, affichage ×2 (caméra), filtrage au plus proche voisin, positions entières.
## Collisions : zone praticable (polygone) + emprises au sol projetées des éléments solides (zone.json).
## Commandes : flèches / ZQSD (8 directions), E parler, toucher le monstre = combat.

const DialogueBox = preload("res://src/proto/dialogue_box.gd")
## Transparence LOCALE d'un élément de décor : ellipses douces autour des personnages qui sont derrière.
const OCC_SHADER_CODE := """
shader_type canvas_item;
uniform vec2 holes[3];
uniform int hole_count = 0;
uniform vec2 radius = vec2(11.0, 17.0);
uniform float min_alpha = 0.5;
void fragment() {
	vec2 px = UV / TEXTURE_PIXEL_SIZE;
	float a = 1.0;
	for (int i = 0; i < hole_count; i++) {
		vec2 d = (px - holes[i]) / radius;
		float r = length(d);
		a = min(a, mix(min_alpha, 1.0, smoothstep(0.55, 1.0, r)));
	}
	COLOR.a *= a;                       // COLOR contient déjà texture × modulation (Godot 4)
}
"""
static var OCC_SHADER: Shader = null


## Règle unique de dialogue (utilisée par le joueur, la démo et les tests) : il faut être PRÈS du PNJ.
static func can_talk(hero_pos: Vector2, npc_pos: Vector2, talk_range := 14.0) -> bool:
	return hero_pos.distance_to(npc_pos) < talk_range


## Contact monstre : pieds du héros dans l'ellipse au sol du monstre élargie d'une petite marge.
static func touches_monster(hero_pos: Vector2, mpos: Vector2, rx: float, ry: float, margin := 6.0) -> bool:
	var d := hero_pos - mpos
	return (d.x / (rx + margin)) ** 2 + (d.y / (ry + margin * 0.5)) ** 2 < 1.0
const DIR := "res://art/explore_hd2d/"
const SPEED := 72.0                       # px natifs / s (≈ 3,6 m/s)
const Y_FACTOR := 0.8                     # vitesse verticale réduite (perspective)
const FOOT_R := 3.0                       # rayon de collision des pieds (px natifs)
const FOLLOW_GAP := 18.0                  # écart de file entre les membres du groupe
const TALK_RANGE := 14.0                  # il faut être tout près du garde pour parler
const NOTICE_RANGE := 34.0                # au-delà : simple bulle « … » au-dessus du PNJ
const ENGAGE_MARGIN := 6.0               # le combat se déclenche quand on touche presque le monstre (ellipse au sol + 6 px)
const OCC_RX := 11.0                     # trou de transparence locale autour du personnage caché (px natifs)
const OCC_RY := 17.0
const OCC_ALPHA := 0.5
const DIALOGUE := "res://data/dialogue/pnj_proto.json"

var zone: Dictionary
var walkable := PackedVector2Array()
var solids: Array = []                    # PackedVector2Array (emprises au sol)
var occluders: Array = []                 # [{sprite, sort_y, rect, mat}] : éléments qui peuvent cacher le groupe
var monster_rx := 20.0                    # demi-axes de l'emprise au sol du monstre (ellipse)
var monster_ry := 8.0
var demo_log: Array = []                  # trace des étapes de la démo (vérification)
var hero: Walker
var party: Array = []                     # [hero, ilya, throne]
var npc: Walker
var monster: AnimatedSprite2D
var monster_pos := Vector2.ZERO
var cam: Camera2D
var trail: Array = []
var _dialog
var _prompt: Label
var _locked := false
var _engaging := false
var _auto_target := Vector2.INF


func _ready() -> void:
	GameState.proto = true
	if OCC_SHADER == null:
		OCC_SHADER = Shader.new()
		OCC_SHADER.code = OCC_SHADER_CODE
	zone = JSON.parse_string(FileAccess.open(DIR + "zone.json", FileAccess.READ).get_as_text())
	for p in zone["walkable"]:
		walkable.append(Vector2(p[0], p[1]))
	var bg := Sprite2D.new()
	bg.texture = load(DIR + "fond.png")
	bg.centered = false
	bg.z_index = -4000
	add_child(bg)
	# Éléments contournables : sprites triés par la ligne de leurs pieds (z = y)
	for g in zone["sprites"]:
		var e: Dictionary = zone["sprites"][g]
		var s := Sprite2D.new()
		s.texture = load(DIR + "el_%s.png" % g)
		s.centered = false
		s.position = Vector2(e["pos"][0], e["pos"][1])
		s.z_index = int(e["sort_y"])
		add_child(s)
		if g != "muret":
			var m := ShaderMaterial.new()
			m.shader = OCC_SHADER
			s.material = m
			occluders.append({"sprite": s, "sort_y": float(e["sort_y"]), "rect": Rect2(s.position, s.texture.get_size()), "mat": m})
		if e["solid"] and e["footprint"].size() >= 3:
			var poly := PackedVector2Array()
			for p in e["footprint"]:
				poly.append(Vector2(p[0], p[1]))
			solids.append(poly)
	_lights()
	# Groupe
	var sp: Array = zone["spawn"]["heros"]
	hero = Walker.new("aren", true)
	add_child(hero)
	hero.position = Vector2(sp[0], sp[1])
	party = [hero]
	for k in ["ilya", "throne"]:
		var w := Walker.new(k, false)
		add_child(w)
		w.position = hero.position + Vector2(-FOLLOW_GAP * party.size(), 4)
		party.append(w)
	if GameState.zone_return_pos != Vector2.ZERO and GameState.explore_return == scene_file_path:
		hero.position = GameState.zone_return_pos
		for i in range(1, party.size()):
			party[i].position = hero.position + Vector2(-FOLLOW_GAP * i, 4)
	var np_: Array = zone["spawn"]["pnj"]
	npc = Walker.new("pnj", false)
	add_child(npc)
	npc.position = Vector2(np_[0], np_[1])
	npc.face(-1.0)
	solids.append(_circle(npc.position, 5.0))
	# Monstre déclencheur
	var mp: Array = zone["spawn"]["monstre"]
	monster_pos = Vector2(mp[0], mp[1])
	monster = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", 6.0)
	for i in range(8):
		sf.add_frame("default", load(DIR + "chars/vorgane_x/idle_%d.png" % i))
	monster.sprite_frames = sf
	monster.centered = false
	var anc: Dictionary = JSON.parse_string(FileAccess.open(DIR + "chars/vorgane_x/anchor.json", FileAccess.READ).get_as_text())
	monster.offset = -Vector2(anc["feet"][0], anc["feet"][1]).round()        # pieds du rendu = position au sol
	monster.position = monster_pos
	monster.z_index = int(monster_pos.y)
	monster.play()
	monster.visible = not GameState.enemy_defeated
	add_child(monster)
	if monster.visible:
		solids.append(_ellipse(monster_pos, monster_rx, monster_ry))      # on ne traverse pas le monstre
	# Caméra : suit le groupe en douceur, bornée au décor
	cam = Camera2D.new()
	cam.zoom = Vector2(2, 2)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(zone["native"][0])
	cam.limit_bottom = int(zone["native"][1])
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 4.0
	cam.position = hero.position
	add_child(cam)
	cam.make_current()
	# Interface : invite et dialogue
	var layer := CanvasLayer.new()
	add_child(layer)
	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 16)
	_prompt.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.visible = false
	layer.add_child(_prompt)
	_dialog = DialogueBox.new()
	layer.add_child(_dialog)
	_dialog.closed.connect(func(): _locked = false)
	if GameState.last_battle_result != "" and GameState.explore_return == scene_file_path:
		GameState.last_battle_result = ""
		GameState.from_zone = false
	if GameState.autoplay:
		_autoplay()


func _lights() -> void:
	# Lumières de scène DISCRÈTES : la lumière est peinte dans le décor ; ici seulement une respiration douce des lanternes
	for lp in zone["lights"]:
		var l := PointLight2D.new()
		var g := GradientTexture2D.new()
		g.fill = GradientTexture2D.FILL_RADIAL
		g.fill_from = Vector2(0.5, 0.5)
		g.fill_to = Vector2(1.0, 0.5)
		var gr := Gradient.new()
		gr.set_color(0, Color(1, 1, 1, 1))
		gr.set_color(1, Color(1, 1, 1, 0))
		g.gradient = gr
		g.width = 64
		g.height = 64
		l.texture = g
		l.position = Vector2(lp[0], lp[1] - 14)
		l.color = Color(1.0, 0.68, 0.36)
		l.energy = 0.35
		l.texture_scale = 1.6
		add_child(l)
		var tw := create_tween().set_loops()
		tw.tween_property(l, "energy", 0.45, 1.3).set_trans(Tween.TRANS_SINE)
		tw.tween_property(l, "energy", 0.3, 1.1).set_trans(Tween.TRANS_SINE)


func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in range(14):
		var a := TAU * i / 14.0
		p.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return p


func _circle(c: Vector2, r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in range(10):
		var a := TAU * i / 10.0
		p.append(c + Vector2(cos(a) * r, sin(a) * r * 0.6))
	return p


# ---------------------------------------------------------------------------------------------- collisions
func free_at(p: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(p, walkable):
		return false
	for poly in solids:
		if Geometry2D.is_point_in_polygon(p, poly):
			return false
		# marge : les pieds ne frôlent pas les obstacles
		for off in [Vector2(FOOT_R, 0), Vector2(-FOOT_R, 0), Vector2(0, FOOT_R * 0.6), Vector2(0, -FOOT_R * 0.6)]:
			if Geometry2D.is_point_in_polygon(p + off, poly):
				return false
	return true


## Déplacement avec glissement le long des obstacles (essai complet, puis axe par axe).
func move(w: Walker, step: Vector2) -> Vector2:
	var p := w.position
	if free_at(p + step):
		return p + step
	if free_at(p + Vector2(step.x, 0)):
		return p + Vector2(step.x, 0)
	if free_at(p + Vector2(0, step.y)):
		return p + Vector2(0, step.y)
	return p


# ---------------------------------------------------------------------------------------------- boucle
func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if not _locked:
		if _auto_target != Vector2.INF:
			var to := _auto_target - hero.position
			if to.length() < 2.0:
				_auto_target = Vector2.INF
			else:
				dir = to.normalized()
		else:
			dir.x = float(Input.is_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A))
			dir.y = float(Input.is_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W))
			dir = dir.normalized()
	var moved := false
	if dir != Vector2.ZERO:
		var np := move(hero, Vector2(dir.x, dir.y * Y_FACTOR) * SPEED * delta)
		moved = np.distance_to(hero.position) > 0.01
		hero.position = np
		if trail.is_empty() or trail[-1].distance_to(hero.position) > 1.5:
			trail.append(hero.position)
			if trail.size() > 200:
				trail.pop_front()
	hero.animate(dir if moved else Vector2.ZERO, delta)
	_follow(delta)
	for w in party + [npc]:
		w.z_index = int(w.position.y)
	cam.position = hero.position.round()
	_update_occlusion(delta)
	_update_prompt()
	if monster.visible and not _engaging and touches_monster(hero.position, monster_pos, monster_rx, monster_ry, ENGAGE_MARGIN):
		_engage()


## Compagnons : suivent la trace du héros avec un retard fixe ; mêmes collisions ; s'arrêtent avec lui.
func _follow(delta: float) -> void:
	for i in range(1, party.size()):
		var w: Walker = party[i]
		var lag := int(FOLLOW_GAP / 1.5) * i
		var target: Vector2 = trail[trail.size() - lag] if trail.size() > lag else w.position
		var to := target - w.position
		var leader: Walker = party[i - 1]
		var go := to.length() > 1.0 and w.position.distance_to(leader.position) > FOLLOW_GAP * 0.85
		var d := Vector2.ZERO
		if go:
			var np := move(w, to.normalized() * minf(SPEED * 1.05 * delta, to.length()))
			d = np - w.position
			w.position = np
		w.animate(d.normalized() if d.length() > 0.01 else Vector2.ZERO, delta)


## Occlusion : le fond ne contient PAS les éléments triés (terrain seul) ; chaque élément est une couche séparée.
## Quand un membre du groupe est derrière un élément (pieds au-dessus de sa ligne de tri) ET réellement recouvert
## par ses pixels, l'élément devient transparent LOCALEMENT autour de lui (ellipse douce). La silhouette de
## secours (très discrète) ne s'affiche que si le personnage est masqué par plus de 3 trous (cas limite).
func _update_occlusion(_delta: float) -> void:
	for w in party:
		w.hidden_behind = false
	for o in occluders:
		var holes := PackedVector2Array()
		var s: Sprite2D = o["sprite"]
		for w in party:
			var r := Rect2(w.position + Vector2(-8, -30), Vector2(16, 30))
			if w.position.y < o["sort_y"] and o["rect"].intersects(r) and (_opaque_at(s, w.position + Vector2(0, -12)) or _opaque_at(s, w.position + Vector2(0, -24)) or _opaque_at(s, w.position + Vector2(0, -3))):
				if holes.size() < 3:
					holes.append(w.position + Vector2(0, -14) - s.position)
				else:
					w.hidden_behind = true
		var m: ShaderMaterial = o["mat"]
		while holes.size() < 3:
			holes.append(Vector2(-999, -999))
		m.set_shader_parameter("holes", holes)
		m.set_shader_parameter("hole_count", 3)
		m.set_shader_parameter("radius", Vector2(OCC_RX, OCC_RY))
		m.set_shader_parameter("min_alpha", OCC_ALPHA)


func _opaque_at(s: Sprite2D, p: Vector2) -> bool:
	var img: Image = s.get_meta("img") if s.has_meta("img") else null
	if img == null:
		img = s.texture.get_image()
		s.set_meta("img", img)
	var q := Vector2i((p - s.position).round())
	return q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and img.get_pixelv(q).a > 0.5


func _update_prompt() -> void:
	var d := hero.position.distance_to(npc.position)
	var near: bool = d < NOTICE_RANGE and not _dialog.is_open()
	_prompt.visible = near
	if near:
		_prompt.text = "E  Parler" if can_talk(hero.position, npc.position, TALK_RANGE) else "…"
		var sp := get_viewport().get_canvas_transform() * (npc.position + Vector2(-14, -40))
		_prompt.position = sp


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _dialog.is_open():
		_dialog.handle_key(event)
		get_viewport().set_input_as_handled()
		return
	if not _locked and (event.physical_keycode == KEY_E or event.keycode == KEY_ENTER):
		_open_dialog()                               # la distance est vérifiée DANS _open_dialog


## Ouvre le dialogue SEULEMENT si le héros est près du garde. Renvoie true si le dialogue s'est ouvert.
func _open_dialog() -> bool:
	if _dialog.is_open() or not can_talk(hero.position, npc.position, TALK_RANGE):
		return false
	var data: Dictionary = JSON.parse_string(FileAccess.open(DIALOGUE, FileAccess.READ).get_as_text())
	var steps: Array = data["after_victory"] if GameState.enemy_defeated else data["start"]
	var spk: Dictionary = data["speakers"].duplicate(true)
	spk["heros"]["name"] = GameState.hero_name
	_locked = true
	hero.animate(Vector2.ZERO, 0.0)
	hero.face_toward(npc.position - hero.position)
	_dialog.open(steps, spk)
	return true


func _engage() -> void:
	_engaging = true
	_locked = true
	var t := create_tween()
	t.tween_property(cam, "zoom", Vector2(2.4, 2.4), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	GameState.from_zone = true
	GameState.proto = true
	GameState.zone_return_pos = hero.position
	GameState.explore_return = scene_file_path
	GameState.goto(GameState.SCENE_PROTO_BATTLE, 0.35)


# ---------------------------------------------------------------------------------------------- démo (vidéo)
## La démo n'utilise AUCUN raccourci : chaque étape doit être réellement atteinte (sinon elle s'arrête et le
## signale), et le dialogue passe par la même règle de distance que le joueur.
func _autoplay() -> void:
	if OS.get_cmdline_user_args().has("--check-talk"):
		await _check_talk()
		return
	await get_tree().create_timer(1.0).timeout
	var house: Dictionary = zone["sprites"]["maison"]
	var tree_e: Dictionary = zone["sprites"]["arbre_g"]
	var hb := _bounds(house["footprint"])
	var tb := _bounds(tree_e["footprint"])
	var tc := tb.get_center()
	var route := [
		["devant la maison", Vector2(hb.position.x + hb.size.x * 0.35, hb.end.y + 10)],
		["côté gauche de la maison", Vector2(hb.position.x - 10, hb.get_center().y)],
		["derrière la maison", Vector2(hb.position.x + 6, hb.position.y - 8)],
		["derrière la maison (milieu)", Vector2(hb.get_center().x, hb.position.y - 8)],
		["retour côté gauche", Vector2(hb.position.x - 10, hb.get_center().y)],
		["derrière l'arbre", Vector2(tc.x + 4, tb.position.y - 8)],
		["devant l'arbre", Vector2(tc.x + 4, tb.end.y + 10)],
		["vers le garde", npc.position + Vector2(-10, 4)],
	]
	for step in route:
		if not await _walk_to(step[1]):
			push_warning("DEMO : étape « %s » non atteinte (obstacle) — démo arrêtée" % step[0])
			demo_log.append("ÉCHEC " + step[0])
			print("DEMO ÉCHEC %s" % step[0])
			return
		demo_log.append("ok " + step[0])
		print("DEMO ok %s (distance au garde %.1f)" % [step[0], hero.position.distance_to(npc.position)])
		await get_tree().create_timer(0.4).timeout
	if not _open_dialog():
		print("DEMO : trop loin du garde pour parler (%.1f px) — pas de dialogue" % hero.position.distance_to(npc.position))
		return
	print("DEMO dialogue ouvert à %.1f px du garde" % hero.position.distance_to(npc.position))
	while _dialog.is_open():
		await get_tree().create_timer(1.4 if not _dialog.showing_choice() else 1.0).timeout
		_dialog.advance()
	await get_tree().create_timer(0.5).timeout
	await _walk_to(monster_pos + Vector2(monster_rx + 26, 6))
	print("DEMO approche du monstre, distance %.1f" % hero.position.distance_to(monster_pos))
	await _walk_to(monster_pos + Vector2(monster_rx - 2, 2))


## Vérification « manuelle » par vraies touches simulées (InputEventKey) : on ne peut pas parler de loin,
## on peut parler de près. Résultat écrit sur la console (CHECK ok / CHECK ÉCHEC).
func _check_talk() -> void:
	await get_tree().create_timer(0.5).timeout
	var ok := true
	_press(KEY_E)
	await get_tree().process_frame
	var far_ok: bool = not _dialog.is_open()
	print("CHECK %s : E à %.1f px du garde -> dialogue %s" % ["ok" if far_ok else "ÉCHEC", hero.position.distance_to(npc.position), "fermé" if far_ok else "OUVERT"])
	ok = ok and far_ok
	# s'approcher en maintenant les flèches (vraies touches), avec les collisions
	var guard := 0
	while not can_talk(hero.position, npc.position, TALK_RANGE) and guard < 900:
		var to := npc.position + Vector2(-9, 3) - hero.position
		_hold(KEY_RIGHT, to.x > 1.5); _hold(KEY_LEFT, to.x < -1.5)
		_hold(KEY_DOWN, to.y > 1.5); _hold(KEY_UP, to.y < -1.5)
		await get_tree().process_frame
		guard += 1
	for k in [KEY_RIGHT, KEY_LEFT, KEY_DOWN, KEY_UP]:
		_hold(k, false)
	await get_tree().create_timer(0.3).timeout
	_press(KEY_E)
	await get_tree().process_frame
	var near_ok: bool = _dialog.is_open()
	print("CHECK %s : E à %.1f px du garde -> dialogue %s" % ["ok" if near_ok else "ÉCHEC", hero.position.distance_to(npc.position), "OUVERT" if near_ok else "fermé"])
	ok = ok and near_ok
	_press(KEY_ESCAPE)
	await get_tree().create_timer(0.5).timeout
	print("CHECK %s : Échap ferme le dialogue" % ("ok" if not _dialog.is_open() else "ÉCHEC"))
	print("CHECK RÉSULTAT : %s" % ("RÉUSSI" if ok and not _dialog.is_open() else "ÉCHEC"))
	get_tree().quit()


func _press(k: Key) -> void:
	for down in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = k
		ev.physical_keycode = k
		ev.pressed = down
		Input.parse_input_event(ev)


func _hold(k: Key, down: bool) -> void:
	if Input.is_key_pressed(k) == down:
		return
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = down
	Input.parse_input_event(ev)


func _bounds(fp: Array) -> Rect2:
	var r := Rect2(Vector2(fp[0][0], fp[0][1]), Vector2.ZERO)
	for p in fp:
		r = r.expand(Vector2(p[0], p[1]))
	return r


var _astar: AStarGrid2D
const CELL := 4


## Grille de navigation de la démo (mêmes règles de collision que le joueur).
func _nav() -> AStarGrid2D:
	if _astar == null:
		_astar = AStarGrid2D.new()
		_astar.region = Rect2i(0, 0, int(zone["native"][0]) / CELL, int(zone["native"][1]) / CELL)
		_astar.cell_size = Vector2(CELL, CELL)
		_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		_astar.update()
		for x in range(_astar.region.size.x):
			for y in range(_astar.region.size.y):
				_astar.set_point_solid(Vector2i(x, y), not free_at(Vector2(x, y) * CELL + Vector2(CELL, CELL) * 0.5))
	return _astar


## Marche automatique vers un point en CONTOURNANT les obstacles (itinéraire A*) ; renvoie false si le point est
## inaccessible ou n'est pas atteint : une étape n'est jamais validée en silence.
func _walk_to(target: Vector2) -> bool:
	var nav := _nav()
	var from := Vector2i(hero.position / CELL)
	var to := Vector2i(target / CELL)
	if not nav.region.has_point(to) or nav.is_point_solid(to):
		# point visé dans un obstacle : cellule libre la plus proche (rayon 16 px) ; sinon échec explicite
		var best := Vector2i(-1, -1)
		for r in range(1, 5):
			for dx in range(-r, r + 1):
				for dy in range(-r, r + 1):
					var c := to + Vector2i(dx, dy)
					if nav.region.has_point(c) and not nav.is_point_solid(c) and (best.x < 0 or (c - to).length_squared() < (best - to).length_squared()):
						best = c
			if best.x >= 0:
				break
		if best.x < 0:
			return false
		to = best
		target = Vector2(best) * CELL + Vector2(CELL, CELL) * 0.5
	var path := nav.get_point_path(from, to)
	for i in range(1, path.size() - 1):
		if not await _walk_straight(path[i] + Vector2(CELL, CELL) * 0.5, 3.0):
			return false
	return await _walk_straight(target, 3.0)


func _walk_straight(target: Vector2, tol: float) -> bool:
	_auto_target = target
	var t := 0.0
	var last := hero.position
	while _auto_target != Vector2.INF and not _engaging:
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > 1.0:
			if hero.position.distance_to(last) < 2.0:
				_auto_target = Vector2.INF
				return hero.position.distance_to(target) < tol
			last = hero.position
			t = 0.0
	return _engaging or hero.position.distance_to(target) < tol


# ---------------------------------------------------------------------------------------------- personnage
class Walker extends Node2D:
	## Personnage d'exploration : 4 directions si disponibles (Aren), sinon profil retourné ; marche pilotée par la
	## distance parcourue (pas de patinage) ; ombre de contact pleine.
	const STRIDE := 6.0
	var key: String
	var dirs := false
	var spr: AnimatedSprite2D
	var _dist := 0.0
	var _dir := "right"
	var hidden_behind := false
	var ghost: AnimatedSprite2D

	func _init(k: String, four_dirs: bool) -> void:
		key = k
		dirs = four_dirs
		spr = AnimatedSprite2D.new()
		spr.centered = false
		var sf := SpriteFrames.new()
		sf.remove_animation("default")
		var base := "res://art/explore_hd2d/chars/%s/" % k
		if dirs:
			for d in ["face", "back", "left", "right"]:
				sf.add_animation("idle_" + d)
				sf.set_animation_speed("idle_" + d, 1.0)
				sf.add_frame("idle_" + d, load(base + "idle_%s.png" % d))
				sf.add_animation("walk_" + d)
				sf.set_animation_speed("walk_" + d, 0.0)
				for i in range(4):
					sf.add_frame("walk_" + d, load(base + "walk_%s_%d.png" % [d, i]))
		else:
			sf.add_animation("idle_right")
			sf.set_animation_speed("idle_right", 2.0)
			sf.add_frame("idle_right", load(base + "idle.png"))
			sf.add_frame("idle_right", load(base + "idle_1.png"))
			if ResourceLoader.exists(base + "walk_0.png"):
				sf.add_animation("walk_right")
				sf.set_animation_speed("walk_right", 0.0)
				for i in range(4):
					sf.add_frame("walk_right", load(base + "walk_%d.png" % i))
		spr.sprite_frames = sf
		add_child(spr)
		# silhouette (au-dessus de tout, teinte unie claire) affichée quand le personnage est caché par le décor
		ghost = AnimatedSprite2D.new()
		ghost.sprite_frames = sf
		ghost.centered = false
		ghost.z_as_relative = false
		ghost.z_index = 3900
		var sh := Shader.new()
		sh.code = "shader_type canvas_item; void fragment(){ vec4 c = texture(TEXTURE, UV); COLOR = vec4(0.55, 0.66, 0.92, c.a * 0.22); }"
		var sm := ShaderMaterial.new()
		sm.shader = sh
		ghost.material = sm
		ghost.visible = false
		add_child(ghost)
		_anim("idle_" + ("face" if dirs else "right"))
		spr.play()

	func _anim(anim: String) -> void:
		if String(spr.animation) == anim:
			return
		var tex: Texture2D = spr.sprite_frames.get_frame_texture(anim, 0)
		spr.animation = anim
		spr.offset = Vector2(-int(tex.get_width() / 2), -tex.get_height())
		spr.play()

	func face(x: float) -> void:
		spr.flip_h = (not dirs) and x < 0

	func face_toward(v: Vector2) -> void:
		if dirs:
			_dir = _dir_of(v)
			_anim("idle_" + _dir)
		else:
			face(v.x)

	func _dir_of(v: Vector2) -> String:
		if absf(v.x) >= absf(v.y) * 0.9:
			return "right" if v.x > 0 else "left"
		return "face" if v.y > 0 else "back"

	func animate(d: Vector2, delta: float) -> void:
		var moving := d.length() > 0.01
		if moving:
			_dist += SPEED_OF(delta)
			if dirs:
				_dir = _dir_of(d)
				_anim("walk_" + _dir)
			else:
				face(d.x)
				if spr.sprite_frames.has_animation("walk_right"):
					_anim("walk_right")
			if String(spr.animation).begins_with("walk"):
				spr.frame = int(_dist / STRIDE) % 4
		else:
			_dist = 0.0
			_anim("idle_" + (_dir if dirs else "right"))

	func SPEED_OF(delta: float) -> float:
		return 72.0 * delta

	func _draw() -> void:
		draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, 7.0, Color(0.02, 0.02, 0.06, 0.5))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _process(_d: float) -> void:
		spr.position = position.round() - position          # sprite calé sur la grille de pixels
		ghost.visible = hidden_behind
		if hidden_behind:
			ghost.animation = spr.animation
			ghost.frame = spr.frame
			ghost.offset = spr.offset
			ghost.flip_h = spr.flip_h
			ghost.position = spr.position
		queue_redraw()


class Shadow extends Node2D:
	## Ombre de contact pleine, sans flou.
	var radius := Vector2(30, 5)

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, radius.y / radius.x))
		draw_circle(Vector2.ZERO, radius.x, Color(0.02, 0.02, 0.06, 0.55))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

