extends Node2D
## EXPLORATION HD-2D — scène expérimentale (branche exploration-hd2d), indépendante de la boucle actuelle.
## Décor : zone construite dans Blender sous la caméra commune (plongée 35°, rotation 20°), puis passe « peinture »
## pixel art (tools/explore/scene_blender.py + paint_pass.py). Le fond contient tout ; chaque élément contournable
## est AUSSI un sprite découpé au pixel près, trié en profondeur avec les personnages selon la ligne de ses pieds.
## Monde en pixels natifs, affichage ×2 (caméra), filtrage au plus proche voisin, positions entières.
## Collisions : zone praticable (polygone) + emprises au sol projetées des éléments solides (zone.json).
## Commandes : flèches / ZQSD (8 directions), E parler, toucher le monstre = combat.

const DialogueBox = preload("res://src/proto/dialogue_box.gd")
const DIR := "res://art/explore_hd2d/"
const SPEED := 72.0                       # px natifs / s (≈ 3,6 m/s)
const Y_FACTOR := 0.8                     # vitesse verticale réduite (perspective)
const FOOT_R := 3.0                       # rayon de collision des pieds (px natifs)
const FOLLOW_GAP := 18.0                  # écart de file entre les membres du groupe
const TALK_RANGE := 26.0
const ENGAGE_RANGE := 22.0
const DIALOGUE := "res://data/dialogue/pnj_proto.json"

var zone: Dictionary
var walkable := PackedVector2Array()
var solids: Array = []                    # PackedVector2Array (emprises au sol)
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
	sf.set_animation_speed("default", 7.0)
	for i in range(8):
		sf.add_frame("default", load(DIR + "chars/vorgane/idle_%d.png" % i))
	monster.sprite_frames = sf
	monster.centered = false
	var t0: Texture2D = sf.get_frame_texture("default", 0)
	monster.offset = Vector2(-t0.get_width() * 0.5, -t0.get_height())
	monster.position = monster_pos
	monster.z_index = int(monster_pos.y)
	monster.play()
	monster.visible = not GameState.enemy_defeated
	add_child(monster)
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
	_update_prompt()
	if monster.visible and not _engaging and hero.position.distance_to(monster_pos) < ENGAGE_RANGE + 18.0:
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


func _update_prompt() -> void:
	var near: bool = hero.position.distance_to(npc.position) < TALK_RANGE and not _dialog.is_open()
	_prompt.visible = near
	if near:
		_prompt.text = "E  Parler"
		var sp := get_viewport().get_canvas_transform() * (npc.position + Vector2(-14, -40))
		_prompt.position = sp


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _dialog.is_open():
		_dialog.handle_key(event)
		get_viewport().set_input_as_handled()
		return
	if not _locked and (event.physical_keycode == KEY_E or event.keycode == KEY_ENTER) and hero.position.distance_to(npc.position) < TALK_RANGE:
		_open_dialog()


func _open_dialog() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.open(DIALOGUE, FileAccess.READ).get_as_text())
	var steps: Array = data["after_victory"] if GameState.enemy_defeated else data["start"]
	var spk: Dictionary = data["speakers"].duplicate(true)
	spk["heros"]["name"] = GameState.hero_name
	_locked = true
	hero.animate(Vector2.ZERO, 0.0)
	hero.face_toward(npc.position - hero.position)
	_dialog.open(steps, spk)


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
func _autoplay() -> void:
	await get_tree().create_timer(1.0).timeout
	var tree_e: Dictionary = zone["sprites"]["arbre_g"]
	var house_e: Dictionary = zone["sprites"]["maison"]
	var tf := _centroid(tree_e["footprint"])
	var hf := _centroid(house_e["footprint"])
	var hy_top := 9999.0
	for p in house_e["footprint"]:
		hy_top = minf(hy_top, p[1])
	var route := [
		hero.position + Vector2(60, -30),                  # diagonale
		tf + Vector2(22, -14), tf + Vector2(-6, -16),      # DERRIÈRE l'arbre (le feuillage passe devant)
		tf + Vector2(10, 18),                               # devant l'arbre
		Vector2(hf.x - 30, hy_top - 6), Vector2(hf.x + 20, hy_top - 8),   # DERRIÈRE la maison
		npc.position + Vector2(-20, 6),                     # vers le garde
	]
	for wp in route:
		await _walk_to(wp)
		await get_tree().create_timer(0.35).timeout
	_open_dialog()
	while _dialog.is_open():
		await get_tree().create_timer(1.5 if not _dialog.showing_choice() else 1.0).timeout
		_dialog.advance()
	await get_tree().create_timer(0.5).timeout
	await _walk_to(monster_pos + Vector2(40, 4))
	await _walk_to(monster_pos + Vector2(10, 2))


func _centroid(fp: Array) -> Vector2:
	var c := Vector2.ZERO
	for p in fp:
		c += Vector2(p[0], p[1])
	return c / maxf(1.0, fp.size())


func _walk_to(target: Vector2) -> void:
	_auto_target = target
	var t := 0.0
	var last := hero.position
	while _auto_target != Vector2.INF and not _engaging:
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > 1.0:                                         # bloqué par un obstacle : on passe au point suivant
			if hero.position.distance_to(last) < 2.0:
				_auto_target = Vector2.INF
			last = hero.position
			t = 0.0


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
		queue_redraw()
