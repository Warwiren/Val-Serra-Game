extends Node2D
## EXPLORATION HD-2D — zone de l'avant-poste (scène lancée par F5).
## Caméra commune : orthographique, plongée 35°, rotation 20° ; monde en pixels natifs (704×400), affichage ×2.
## Décor définitif illustré : art/explore_hd2d/illustre/ (voir _decor) ; géométrie de jeu : zone.json (praticable,
## emprises au sol = collisions, lignes de tri), produite par tools/explore/scene_blender.py.
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


## Règle de distance du dialogue : ellipse au sol autour des pieds du PNJ, plus large que haute (perspective :
## une même distance au sol paraît plus courte à la verticale). 22 × 16 px natifs ≈ 1,1 m sur les côtés : il
## suffit d'arriver à côté du PNJ, de face ou en diagonale, sans viser un point précis.
static func can_talk(hero_pos: Vector2, npc_pos: Vector2, rx := 22.0, ry := 16.0) -> bool:
	var d := hero_pos - npc_pos
	return (d.x / rx) ** 2 + (d.y / ry) ** 2 <= 1.0


## Contact monstre : pieds du héros dans l'ellipse au sol du monstre élargie d'une petite marge.
static func touches_monster(hero_pos: Vector2, mpos: Vector2, rx: float, ry: float, margin := 6.0) -> bool:
	var d := hero_pos - mpos
	return (d.x / (rx + margin)) ** 2 + (d.y / (ry + margin * 0.5)) ** 2 < 1.0
const DIR := "res://art/explore_hd2d/"
const SPEED := 72.0                       # px natifs / s (≈ 3,6 m/s)
const Y_FACTOR := 0.8                     # vitesse verticale réduite (perspective)
const FOOT_R := 3.0                       # rayon de collision des pieds (px natifs)
const FOLLOW_GAP := 20.0                  # écart de file, mesuré LE LONG de la trace du héros (px natifs)
const TRAIL_STEP := 1.0                   # un point de trace par px parcouru
const NPC_RX := 10.0                      # emprise au sol du garde (collision)
const NPC_RY := 5.0
const TALK_RX := 22.0                     # zone de dialogue : ellipse au sol (voir can_talk)
const TALK_RY := 16.0
const NOTICE_RANGE := 34.0                # au-delà : simple bulle « … » au-dessus du PNJ
const ENGAGE_MARGIN := 6.0               # le combat se déclenche quand on touche presque le monstre (ellipse au sol + 6 px)
const OCC_RX := 11.0                     # trou de transparence locale autour du personnage caché (px natifs)
const OCC_RY := 17.0
const OCC_ALPHA := 0.5
const DIALOGUE := "res://data/dialogue/pnj_proto.json"
const CameraRig = preload("res://src/explore/camera_hd2d.gd")

## Carte jouée : l'avant-poste (par défaut) ou la zone de test agrandie P1 (scenes/explore_hd2d/zone_p1.tscn).
@export var zone_file := DIR + "zone.json"
@export var decor_file := DIR + "illustre/decor.json"

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
var cam: CameraRig
var _cam_label: Label
var _cam_label_t := 0.0
var trail: Array = []
var _dialog
var _prompt: Label
var _locked := false
var _engaging := false
var _npc_solid := PackedVector2Array()
var _engage_armed := false                # le contact ne relance un combat qu'après être sorti de la zone de contact
var _auto_path := PackedVector2Array()   # démo : itinéraire simplifié (points de passage sans arrêt)


func _ready() -> void:
	GameState.proto = true
	if OCC_SHADER == null:
		OCC_SHADER = Shader.new()
		OCC_SHADER.code = OCC_SHADER_CODE
	zone = JSON.parse_string(FileAccess.open(zone_file, FileAccess.READ).get_as_text())
	for p in zone["walkable"]:
		walkable.append(Vector2(p[0], p[1]))
	_decor()
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
		party.append(w)
	var returning: bool = GameState.explore_return == scene_file_path and GameState.last_battle_result != ""
	if GameState.zone_return_pos != Vector2.ZERO and GameState.explore_return == scene_file_path:
		hero.position = GameState.zone_return_pos
	if returning and GameState.last_battle_result == "defeat":
		hero.position = Vector2(sp[0], sp[1])      # défaite : le groupe se replie au point de départ, loin du monstre
	var np_: Array = zone["spawn"]["pnj"]
	npc = Walker.new("pnj", false)
	add_child(npc)
	npc.position = Vector2(np_[0], np_[1])
	npc.face(-1.0)
	# emprise au sol du garde : ellipse 10 × 5 px (largeur des épaules, faible profondeur), plus la marge des
	# pieds du héros -> on s'arrête à côté de lui (13 px) ou devant lui (≈ 7 px), sans le traverser
	_npc_solid = _ellipse(npc.position, NPC_RX, NPC_RY)
	solids.append(_npc_solid)
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
	_place_party()
	# Caméra (P1) : configuration A / B / C, bornée au décor ; A = réglage d'origine, par défaut
	cam = CameraRig.new()
	cam.set_bounds(Rect2(0, 0, int(zone["native"][0]), int(zone["native"][1])))
	cam.apply(GameState.camera_preset)
	add_child(cam)
	cam.snap_to(hero.position)
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
	_cam_label = Label.new()
	_cam_label.add_theme_font_size_override("font_size", 15)
	_cam_label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
	_cam_label.add_theme_constant_override("outline_size", 5)
	_cam_label.position = Vector2(16, 690)
	_cam_label.visible = false
	layer.add_child(_cam_label)
	_dialog = DialogueBox.new()
	layer.add_child(_dialog)
	_dialog.closed.connect(func(): _locked = false)
	if GameState.autoplay:
		print("ZONE chargée : retour=%s, Vorgane présent=%s, héros=%s" % [GameState.last_battle_result if returning else "-", monster.visible, hero.position.round()])
	if GameState.last_battle_result != "" and GameState.explore_return == scene_file_path:
		GameState.last_battle_result = ""
		GameState.from_zone = false
	if GameState.course != "":
		if GameState.course == "p1":
			add_child(load("res://scenes/explore_hd2d/p1_camera_course.gd").new(self))
		else:
			add_child(load("res://scenes/explore_hd2d/locomotion_course.gd").new(self, GameState.course))
	if GameState.autoplay:
		_autoplay()


## DÉCOR DÉFINITIF (seule version active) : art/explore_hd2d/illustre/decor.json.
## Sol : une plaque 1408×800 (calques plaque, ombres, lumière fusionnés à l'import, tools/explore/import_sol.py),
## affichée 1:1 à l'écran. Éléments : pour chaque élément de zone.json, ses calques illustrés (tronc puis feuillage,
## par ex.), triés sur la ligne de tri de l'élément ; l'emprise, la collision et la transparence locale viennent de
## zone.json. Textures en pixels d'écran, échelle 0,5 du monde, filtrage linéaire (pas de pixellisation).
const DECOR := DIR + "illustre/"


static func decor_spec(path := DECOR + "decor.json") -> Dictionary:
	return JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())


## Pied de l'élément (natif) : centre de l'emprise au bord avant, ou extrémité avant gauche (clôtures).
static func element_foot(e: Dictionary, mode: String) -> Vector2:
	if mode == "avant_gauche":
		var f := Vector2(-INF, -INF)
		for q in e["footprint"]:
			if q[1] > f.y:
				f = Vector2(q[0], q[1])
		return f
	var c := Vector2.ZERO
	for q in e["footprint"]:
		c += Vector2(q[0], q[1])
	return Vector2(c.x / e["footprint"].size(), float(e["sort_y"]))


func _decor() -> void:
	var spec := decor_spec(decor_file)
	var sol: String = spec["sol"]
	var ground := _tex_sprite(sol if sol.begins_with("res://") else DECOR + sol, Vector2.ZERO)
	ground.z_index = -4000
	for g in zone["sprites"]:
		var e: Dictionary = zone["sprites"][g]
		if e["solid"] and e["footprint"].size() >= 3:
			solids.append(_poly(e["footprint"]))
		if spec["masquer"].has(g) or not spec["elements"].has(g):
			continue
		var r: Dictionary = spec["elements"][g]
		var foot := element_foot(e, r.get("pied", ""))
		for layer in r["calques"]:
			var s := _tex_sprite(DECOR + "%s.png" % layer, foot - Vector2(r["pivot"][0], r["pivot"][1]) * 0.5)
			s.z_index = int(e["sort_y"])
			s.set_meta("element", g)
			var m := ShaderMaterial.new()
			m.shader = OCC_SHADER
			s.material = m
			occluders.append({"name": g, "sprite": s, "sort_y": float(e["sort_y"]), "rect": Rect2(s.position, s.texture.get_size() * s.scale), "mat": m, "footprint": _poly(e["footprint"])})
	for d in spec["details"]:                                # petits éléments au sol, triés comme les personnages
		var s := _tex_sprite(DECOR + "%s.png" % d[0], Vector2(d[1], d[2]) - Vector2(d[3][0], d[3][1]) * 0.5)
		s.z_index = int(d[2])


func _tex_sprite(path: String, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.scale = Vector2(0.5, 0.5)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.position = pos
	add_child(s)
	return s


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


## Place les compagnons en file derrière le héros, sur des positions LIBRES (jamais dans un obstacle, y compris
## au retour de combat), et amorce la trace avec cette file pour que le suivi parte sans à-coup.
func _place_party() -> void:
	trail.clear()
	var dirs := [Vector2(-1, 0.2), Vector2(1, 0.2), Vector2(0, 1), Vector2(0, -1), Vector2(-1, -0.6), Vector2(1, -0.6)]
	var chosen := Vector2(-1, 0.2).normalized()
	for d in dirs:
		var ok := true
		for i in range(1, party.size()):
			ok = ok and free_at(hero.position + d.normalized() * FOLLOW_GAP * i)
		if ok:
			chosen = d.normalized()
			break
	for i in range(party.size() - 1, 0, -1):
		party[i].position = hero.position + chosen * FOLLOW_GAP * i
		trail.append(party[i].position)
	trail.append(hero.position)
	for i in range(1, party.size()):
		party[i].face_toward(-chosen)


func _poly(a: Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for q in a:
		p.append(Vector2(q[0], q[1]))
	return p


## Ordre d'affichage effectif d'un personnage par rapport à un élément de décor (QA de profondeur).
func drawn_in_front(w: Node2D, o: Dictionary) -> bool:
	return w.z_index >= (o["sprite"] as Sprite2D).z_index


## Bord avant de l'emprise au sol (y maximal du polygone) à l'abscisse x, x ramené dans l'emprise.
static func front_edge(fp: PackedVector2Array, x: float) -> float:
	var lo := INF
	var hi := -INF
	for q in fp:
		lo = minf(lo, q.x)
		hi = maxf(hi, q.x)
	x = clampf(x, lo + 0.01, hi - 0.01)
	var best := -INF
	for i in fp.size():
		var a := fp[i]
		var b := fp[(i + 1) % fp.size()]
		if x < minf(a.x, b.x) or x > maxf(a.x, b.x) or absf(b.x - a.x) < 0.001:
			continue
		best = maxf(best, lerpf(a.y, b.y, (x - a.x) / (b.x - a.x)))
	return best


## Tri de profondeur d'un personnage : la ligne de ses pieds, SAUF devant un élément dont le bord avant est en
## biais (maison, clôtures) : une seule ligne horizontale (y maximal) le ferait passer derrière le mur alors
## qu'il est devant. On compare donc au bord avant réel de l'emprise, à son abscisse.
func depth_z(p: Vector2) -> int:
	var z := int(p.y)
	var sure := -(1 << 20)                  # devant un élément, à une abscisse COUVERTE par son emprise (certain)
	var cap := 1 << 20
	var r := Rect2(p + Vector2(-8, -30), Vector2(16, 30))
	for o in occluders:
		var fp: PackedVector2Array = o["footprint"]
		if fp.size() < 3 or not o["rect"].intersects(r):
			continue
		var sz: int = (o["sprite"] as Sprite2D).z_index
		if p.y > front_edge(fp, p.x):
			z = maxi(z, sz + 1)                 # devant cet élément
			if _covers_x(fp, p.x):
				sure = maxi(sure, sz + 1)
		else:
			cap = mini(cap, sz - 1)             # derrière cet élément : il doit rester devant le personnage
	# conflit (devant un mur mais dans un buisson moins profond) : être caché par le mur serait bien plus
	# visible qu'empiéter sur le feuillage, donc « devant » l'emporte quand il est certain.
	return maxi(mini(z, maxi(cap, int(p.y))), sure)


static func _covers_x(fp: PackedVector2Array, x: float) -> bool:
	var lo := INF
	var hi := -INF
	for q in fp:
		lo = minf(lo, q.x)
		hi = maxf(hi, q.x)
	return x >= lo and x <= hi


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


## Déplacement avec glissement le long des obstacles (essai complet, puis axe par axe), puis contournement des
## ANGLES et murs en biais : si l'on bute, un pas tourné de ±45° puis ±60° (réduit à sa composante utile) permet
## de longer le coin au lieu de rester accroché ; contre un mur plat abordé de face, ces pas restent bloqués.
func move(w: Walker, step: Vector2) -> Vector2:
	var p := w.position
	if free_at(p + step):
		return p + step
	# (un axe nul ne compte pas comme un glissement : sinon on « réussit » sur place et on reste accroché)
	if absf(step.x) > 0.001 and free_at(p + Vector2(step.x, 0)):
		return p + Vector2(step.x, 0)
	if absf(step.y) > 0.001 and free_at(p + Vector2(0, step.y)):
		return p + Vector2(0, step.y)
	for a in [PI / 4.0, -PI / 4.0, PI / 3.0, -PI / 3.0]:
		var s := step.rotated(a) * cos(a)
		if free_at(p + s):
			return p + s
	return p


# ---------------------------------------------------------------------------------------------- boucle
func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if not _locked:
		if not _auto_path.is_empty():
			dir = _auto_dir(delta)
		else:
			dir.x = float(Input.is_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A))
			dir.y = float(Input.is_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W))
			dir = dir.normalized()
	var before := hero.position
	if dir != Vector2.ZERO:
		hero.position = move(hero, Vector2(dir.x, dir.y * Y_FACTOR) * SPEED * delta)
		if trail[-1].distance_to(hero.position) >= TRAIL_STEP:
			trail.append(hero.position)
			if trail.size() > 600:
				trail.pop_front()
	# l'animation suit le déplacement RÉEL (glissement, blocage) ; l'intention sert seulement à l'orientation à l'arrêt
	hero.animate(hero.position - before, delta, Vector2(dir.x, dir.y * Y_FACTOR))
	_follow(delta)
	for w in party + [npc]:
		w.z_index = depth_z(w.position)
	cam.follow(hero.position, dir, delta)
	_update_cam_label(delta)
	_update_occlusion(delta)
	_update_prompt()
	var touching := touches_monster(hero.position, monster_pos, monster_rx, monster_ry, ENGAGE_MARGIN)
	if not touching:
		_engage_armed = true
	if monster.visible and not _engaging and _engage_armed and touching:
		_engage()


## Compagnons : chacun se tient sur la trace du héros, à une DISTANCE PARCOURUE fixe derrière lui
## (FOLLOW_GAP × rang). Ils avancent exactement quand le héros avance, à la même vitesse, et s'arrêtent avec lui
## à espacement constant : pas d'arrêt-relance ni de rattrapage. La trace est faite de positions déjà valides
## pour le héros ; les mêmes collisions restent appliquées par sécurité.
func _follow(delta: float) -> void:
	for i in range(1, party.size()):
		var w: Walker = party[i]
		var to := trail_point(FOLLOW_GAP * i) - w.position
		var before := w.position
		if to.length() > 0.05:
			w.position = move(w, to.limit_length(SPEED * 1.6 * delta))
		w.animate(w.position - before, delta)


## Point de la trace situé à une distance « back » (le long du chemin) derrière la position actuelle du héros.
func trail_point(back: float) -> Vector2:
	var acc := 0.0
	var prev := hero.position
	for k in range(trail.size() - 1, -1, -1):
		var p: Vector2 = trail[k]
		var seg := prev.distance_to(p)
		if seg > 0.0 and acc + seg >= back:
			return prev.lerp(p, (back - acc) / seg)
		acc += seg
		prev = p
	return prev


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
			if not drawn_in_front(w, o) and o["rect"].intersects(r) and (_opaque_at(s, w.position + Vector2(0, -12)) or _opaque_at(s, w.position + Vector2(0, -24)) or _opaque_at(s, w.position + Vector2(0, -3))):
				if holes.size() < 3:
					holes.append((w.position + Vector2(0, -14) - s.position) / s.scale)
				else:
					w.hidden_behind = true
		var m: ShaderMaterial = o["mat"]
		while holes.size() < 3:
			holes.append(Vector2(-999, -999))
		m.set_shader_parameter("holes", holes)
		m.set_shader_parameter("hole_count", 3)
		m.set_shader_parameter("radius", Vector2(OCC_RX, OCC_RY) / s.scale)
		m.set_shader_parameter("min_alpha", OCC_ALPHA)


func _opaque_at(s: Sprite2D, p: Vector2) -> bool:
	var img: Image = s.get_meta("img") if s.has_meta("img") else null
	if img == null:
		img = s.texture.get_image()
		s.set_meta("img", img)
	var q := Vector2i(((p - s.position) / s.scale).round())
	return q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and img.get_pixelv(q).a > 0.5


## Dialogue réellement possible maintenant : dans l'ellipse ET rien entre le héros et le PNJ (bâtiment,
## clôture, tonneaux…). Même règle pour l'invite « E  Parler », la touche E, la démo et les tests.
func can_talk_now() -> bool:
	return can_talk(hero.position, npc.position, TALK_RX, TALK_RY) and line_clear(hero.position, npc.position)


## Aucun obstacle (hors le PNJ lui-même) sur le segment au sol entre deux points.
func line_clear(a: Vector2, b: Vector2) -> bool:
	var n := maxi(1, int(ceil(a.distance_to(b) / 2.0)))
	for k in range(1, n):
		var p := a.lerp(b, float(k) / n)
		if not Geometry2D.is_point_in_polygon(p, walkable):
			return false
		for poly in solids:
			if poly != _npc_solid and Geometry2D.is_point_in_polygon(p, poly):
				return false
	return true


func _update_prompt() -> void:
	var d := hero.position.distance_to(npc.position)
	var near: bool = d < NOTICE_RANGE and not _dialog.is_open()
	_prompt.visible = near
	if near:
		_prompt.text = "E  Parler" if can_talk_now() else "…"
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
	elif not _engaging:
		var k: Key = event.keycode
		if k == KEY_1 or k == KEY_KP_1:
			set_camera("A")
		elif k == KEY_2 or k == KEY_KP_2:
			set_camera("B")
		elif k == KEY_3 or k == KEY_KP_3:
			set_camera("C")
		elif event.physical_keycode == KEY_C:
			set_camera(CameraRig.next_of(cam.preset))


## P1 : change la configuration de caméra EN JEU (sans rechargement) ; conservée au retour de combat.
func set_camera(p: String) -> void:
	if not CameraRig.PRESETS.has(p):
		return
	GameState.camera_preset = p
	cam.apply(p, hero.position)
	_cam_label.text = "Caméra %s   ·   1 / 2 / 3 ou C pour changer" % CameraRig.PRESETS[p]["label"]
	_cam_label.visible = true
	_cam_label_t = 2.5


func _update_cam_label(delta: float) -> void:
	if GameState.camera_hud:
		_cam_label.text = "Caméra %s" % CameraRig.PRESETS[cam.preset]["label"]
		_cam_label.visible = true
		_cam_label.modulate.a = 1.0
		return
	if _cam_label_t > 0.0:
		_cam_label_t -= delta
		_cam_label.modulate.a = clampf(_cam_label_t / 0.5, 0.0, 1.0)
		_cam_label.visible = _cam_label_t > 0.0


## Ouvre le dialogue SEULEMENT si le héros est près du garde. Renvoie true si le dialogue s'est ouvert.
func _open_dialog() -> bool:
	if _dialog.is_open() or not can_talk_now():
		return false
	var data: Dictionary = JSON.parse_string(FileAccess.open(DIALOGUE, FileAccess.READ).get_as_text())
	var steps: Array = data["after_victory"] if GameState.enemy_defeated else data["start"]
	var spk: Dictionary = data["speakers"].duplicate(true)
	spk["heros"]["name"] = GameState.hero_name
	_locked = true
	_auto_path.clear()
	for w in party:
		w.stop()
	hero.face_toward(npc.position - hero.position)
	_dialog.open(steps, spk)
	return true


func _engage() -> void:
	_engaging = true
	_locked = true
	for w in party:
		w.stop()
	var t := create_tween()
	t.tween_property(cam, "zoom", cam.zoom * 1.2, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
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
	while not can_talk_now() and guard < 900:
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
## L'itinéraire A* (cellules de 4 px) est SIMPLIFIÉ en segments droits (visibilité directe testée avec les mêmes
## collisions) puis parcouru SANS arrêt aux points intermédiaires : pas de micro-virages ni d'images de repos.
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
	var raw := nav.get_point_path(from, to)
	if raw.is_empty():
		return false
	var pts := PackedVector2Array([hero.position])
	for i in range(1, raw.size() - 1):
		pts.append(raw[i] + Vector2(CELL, CELL) * 0.5)
	pts.append(target)
	_auto_path = simplify_path(pts)
	_auto_path.remove_at(0)
	var t := 0.0
	var last := hero.position
	while not _auto_path.is_empty() and not _engaging:
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > 1.0:
			if hero.position.distance_to(last) < 2.0:          # bloqué : on n'insiste pas en silence
				_auto_path.clear()
				break
			last = hero.position
			t = 0.0
	return _engaging or hero.position.distance_to(target) < 3.0


## Simplification par visibilité directe : on garde le point le plus lointain visible en ligne droite.
func simplify_path(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array([pts[0]])
	var i := 0
	while i < pts.size() - 1:
		var j := pts.size() - 1
		while j > i + 1 and not segment_free(pts[i], pts[j]):
			j -= 1
		out.append(pts[j])
		i = j
	return out


func segment_free(a: Vector2, b: Vector2) -> bool:
	var n := int(ceil(a.distance_to(b) / 2.0))
	for k in range(1, n + 1):
		if not free_at(a.lerp(b, float(k) / n)):
			return false
	return true


## Direction de marche de la démo : on passe les points intermédiaires sans s'arrêter.
func _auto_dir(delta: float) -> Vector2:
	var reach := SPEED * delta * 1.5 + 0.5
	while _auto_path.size() > 1 and hero.position.distance_to(_auto_path[0]) <= reach:
		_auto_path.remove_at(0)
	var to := _auto_path[0] - hero.position
	if _auto_path.size() == 1 and to.length() < 2.0:
		_auto_path.clear()
		return Vector2.ZERO
	return to.normalized()


# ---------------------------------------------------------------------------------------------- personnage
class Walker extends Node2D:
	## Personnage d'exploration : 4 directions si disponibles (Aren), sinon profil retourné ; marche pilotée par la
	## distance parcourue (pas de patinage) ; ombre de contact pleine.
	const STRIDE := 6.0                 # px parcourus par image de marche (4 images = 24 px par cycle)
	const TURN_DELAY := 0.06            # s : durée minimale d'une nouvelle orientation avant de l'adopter
	const STOP_GRACE := 0.1             # s : un arrêt plus court ne repasse pas au repos
	var _still := 0.0
	var _cand := ""
	var _cand_t := 0.0
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

	## Les pieds du sprite (milieu du bas de l'image) sont TOUJOURS calés sur la position. Correctif : l'ancien
	## code sortait avant de poser ce calage quand l'animation demandée était déjà l'animation par défaut du
	## SpriteFrames ; un personnage qui ne marche jamais (le garde) restait alors dessiné 25 px trop bas et 7 px
	## trop à droite de sa position réelle (collision, dialogue).
	func _anim(anim: String) -> void:
		var tex: Texture2D = spr.sprite_frames.get_frame_texture(anim, 0)
		spr.offset = Vector2(-int(tex.get_width() / 2), -tex.get_height())
		if String(spr.animation) == anim:
			return
		spr.animation = anim
		spr.play()

	func face(x: float) -> void:
		spr.flip_h = (not dirs) and x < 0

	func face_toward(v: Vector2) -> void:
		if dirs:
			_dir = _dir_of(v)
			_anim("idle_" + _dir)
		else:
			_dir = "left" if v.x < 0 else "right"
			face(v.x)

	func _dir_of(v: Vector2) -> String:
		if absf(v.x) >= absf(v.y) * 0.9:
			return "right" if v.x > 0 else "left"
		return "face" if v.y > 0 else "back"

	## Orientation avec HYSTÉRÉSIS : on garde l'orientation actuelle tant que le mouvement ne penche pas
	## nettement vers une autre (les diagonales restent de profil, sans alterner profil / face).
	func _facing_for(v: Vector2) -> String:
		var ax := absf(v.x)
		var ay := absf(v.y)
		if not dirs:
			if ax < 0.25 * v.length():
				return _dir                                    # mouvement presque vertical : on ne se retourne pas
			return "right" if v.x > 0 else "left"
		var horizontal: bool
		if _dir == "left" or _dir == "right":
			horizontal = ay <= ax * 1.4
		else:
			horizontal = ax > ay * 1.1
		if horizontal:
			return "right" if v.x > 0 else "left"
		return "face" if v.y > 0 else "back"

	## d = déplacement RÉEL de l'image (px natifs). Les images de marche avancent avec la distance parcourue
	## (une image tous les STRIDE px). Un changement d'orientation doit durer TURN_DELAY pour être pris en
	## compte (évite l'orientation parasite quand on relâche deux touches à quelques images d'écart), et un arrêt
	## de moins de STOP_GRACE ne repasse pas au repos. intent = direction voulue (orientation quand on est bloqué).
	func animate(d: Vector2, delta: float, intent := Vector2.ZERO) -> void:
		if d.length() > 0.01:
			_still = 0.0
			var walking := String(spr.animation).begins_with("walk")
			_dist += d.length()
			var c := _facing_for(d)
			if c == _dir or not walking:
				_dir = c
				_cand = ""
			elif c == _cand:
				_cand_t += delta
				if _cand_t >= TURN_DELAY:
					_dir = c
					_cand = ""
			else:
				_cand = c
				_cand_t = delta
			if dirs:
				_anim("walk_" + _dir)
			else:
				face(-1.0 if _dir == "left" else 1.0)
				if spr.sprite_frames.has_animation("walk_right"):
					_anim("walk_right")
			if String(spr.animation).begins_with("walk"):
				spr.frame = int(_dist / STRIDE) % 4
		else:
			_still += delta
			if _still >= STOP_GRACE:
				if intent.length() > 0.01 and dirs:
					_dir = _facing_for(intent)               # on pousse contre un obstacle : on lui fait face
				stop()

	func stop() -> void:
		_dist = 0.0
		_cand = ""
		_anim("idle_" + (_dir if dirs else "right"))

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

