extends Node3D
## P3 — ARCHITECTURE B : Node3D + Camera3D ORTHOGRAPHIQUE, géométrie simple (boîtes, rampe, cylindres) générée à
## partir du modèle de monde commun, personnages = sprites existants sur cartes verticales (AnimatedSprite3D).
##  • Collisions : physique Godot (CharacterBody3D contre StaticBody3D) + règle de rebord par rayons verticaux
##    (on ne descend pas plus de 25 cm d'un pas ; eau, berges et décor sont des sols « non praticables »).
##  • Tri et occultation : tampon de profondeur (aucune règle de tri à écrire) ; silhouette du héros là où il est
##    caché (test de profondeur inversé) ; transparence tramée locale de l'occultant en option.
##  • Caméra : même logique que A (cam25.gd), convertie en position de caméra 3D — cadrage identique.
## Scènes : demo_b_3d.tscn (micro-test), scene_temoin.tscn (scène témoin complète).

const World25 = preload("res://src/explore25/world25.gd")
const Session25 = preload("res://src/explore25/session25.gd")
const Actor25 = preload("res://src/explore25/actor25.gd")
const Look = preload("res://src/explore25/look25.gd")
const BLOCK_SH = preload("res://src/explore25/block25.gdshader")
const WATER_SH = preload("res://src/explore25/water25.gdshader")
const GHOST_SH = preload("res://src/explore25/ghost25.gdshader")
const BLOB_SH = preload("res://src/explore25/blob25.gdshader")
const OVER_SH = preload("res://src/explore25/overlay25.gdshader")
const Variantes = preload("res://src/explore25/variantes25.gd")
const Paysage = preload("res://src/explore25/paysage25.gd")

const L_FLOOR := 1                         # sols praticables (et terrasse : son dessus est un sol, ses faces des murs)
const L_OBST := 2                          # obstacles (murs, troncs, haies, garde-corps, PNJ)
const L_NOWALK := 4                        # sols NON praticables (décor, eau, berges)
const L_OCC := 16                          # volumes d'occultation sans collision (feuillage, toit)
const L_ACTOR := 32
const SPRITE_TOWARD_CAM := 0.4             # m : carte décalée vers la caméra (invisible en orthographique) pour
										   # qu'elle ne s'enfonce pas dans un mur voisin

@export_enum("temoin", "micro") var mode := "temoin"
@export var arch_label := "B — Camera3D orthographique"
## P3-07 : variante de caméra ("" = prototype P3 inchangé) et traitement du paysage non jouable.
@export var variante := ""                   # "", "A", "B" ou "C"
@export_enum("aucun", "3d", "2d") var paysage := "aucun"

var s                                      # Session25
var world
var root: Node3D                           # contenu de l'instance courante (reconstruit à chaque changement)
var cam: Camera3D
var body: CharacterBody3D
var hero_vis: Node3D
var comp_vis: Node3D
var actors := {}                           # nom -> {actor, spr, ghost, ghost_mat, node}
var fade_nodes := {}                       # collider -> [MeshInstance3D] (transparence locale)
var _faded: Array = []
var _block_mats: Array = []
var _water_mats: Array = []
var _overlay: Node3D
var _labels: Node3D
var _occluded := false
var _cli := {}
var _quit_when_done := false
var _switching := false
var _rend_prev := Vector2.INF
var _rend_prev_v := Vector2.ZERO
var _rend_hero_prev := Vector2.INF
var _rend_hero_prev_v := Vector2.ZERO
var _env_res: Environment
var _paysage_cfg := {}
var _paysage_stats := {}
var _frame_ms: Array = []
var _hidden_ground := {}


func _ready() -> void:
	_cli = parse_cli()
	if _cli.has("mode"):
		mode = _cli["mode"]
	if _cli.has("variante"):
		variante = _cli["variante"]
	if _cli.has("paysage"):
		paysage = _cli["paysage"]
	get_tree().physics_interpolation = true
	s = Session25.new(self, arch_label)
	_apply_variante()
	s.build_hud()
	_env()
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.near = 0.5
	cam.far = 400.0
	add_child(cam)
	_cam_basis()
	cam.current = true
	_spawn_actors()
	if _cli.has("instance"):
		_load(_cli["instance"], "instance")
	else:
		_load(World25.SPEC if mode != "micro" else World25.SPEC, mode)
	_apply_cli()
	if _cli.has("vue_dessus"):
		_top_view()


static func parse_cli() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			out[kv[0]] = kv[1]
		elif a.begins_with("--"):
			out[a.substr(2)] = true
	return out


func _apply_cli() -> void:
	if _cli.has("zoom"):
		s.cam.set_index(int(_cli["zoom"]), false)
	if _cli.has("occ"):
		s.options["occlusion"] = int(_cli["occ"])
	if _cli.has("filter"):
		s.options["filter_linear"] = _cli["filter"] != "nearest"
		s.cam.snap = not s.options["filter_linear"]
	if _cli.has("snap"):
		s.cam.snap = _cli["snap"] == "1"
	if _cli.has("nodebug"):
		s.options["debug"] = false
	if _cli.has("layers"):
		s.options["layers"] = true
	if _cli.has("fps"):
		Engine.max_fps = int(_cli["fps"])
	if _cli.has("physics"):
		Engine.physics_ticks_per_second = int(_cli["physics"])
	apply_options()
	if _cli.has("route"):
		s.start_pilot(_cli["route"])
		_quit_when_done = _cli.has("quit")


func _env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.15, 0.19)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.74)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	we.environment = env
	_env_res = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.basis = Basis.looking_at(Look.LIGHT_DIR.normalized(), Vector3.UP)
	sun.light_energy = 0.85
	sun.shadow_enabled = not parse_cli().has("noshadow")
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 120.0
	sun.shadow_bias = 0.04
	add_child(sun)


# ------------------------------------------------------------------------------------------------ construction
func _load(file: String, m: String, arrive := Vector3.INF) -> void:
	actors.erase("pnj")
	if root != null:
		root.queue_free()
		remove_child(root)
	root = Node3D.new()
	root.name = "Instance"
	add_child(root)
	fade_nodes.clear()
	_faded.clear()
	_block_mats.clear()
	_water_mats.clear()
	world = World25.load_world(file, m)
	_paysage_cfg = Paysage.config_for(file) if paysage != "aucun" else {}
	if not _paysage_cfg.is_empty():
		world.extend_view(Paysage.view_points(_paysage_cfg))
		for e in world.elements:
			if e["type"] in ["water", "bank"]:          # la rivière se jette dans le lac en contrebas, sort d'une gorge
				var er: Rect2 = e["rect"]
				e["rect"] = Rect2(er.position.x, -40.0, er.size.x, 65.0)
	for e in world.elements:
		if not _paysage_cfg.is_empty() and e["type"] == "floor" and e["role"] == "decor":
			_decor_collider_only(e)                   # plaque verte remplacée par le relief (collision de bord gardée)
			continue
		_build(e)
	var pb = Paysage.new()
	pb.build(root, _paysage_cfg, world, paysage)
	_paysage_stats = pb.stats
	Paysage.apply_fog(_env_res, _paysage_cfg, world, paysage)
	if not world.npc.is_empty():
		var n: Dictionary = world.npc
		var a := _make_actor("pnj", n["sprite"])
		root.add_child(a["node"])
		a["node"].position = World25.g3(n["p"])
		a["actor"].face_toward(Vector2(1, 0.3))
		_obstacle_cyl(World25.g3(n["p"]), n["r"], 1.8)
	_build_overlay()
	s.set_world(world, arrive)
	teleport(s.hero, s.companion)
	apply_options()


func _decor_collider_only(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var sb := _static_box(_rect_center(r, e["h"] - 0.32, e["h"] - 0.02), Vector3(r.size.x, 0.3, r.size.y), L_NOWALK)
	sb.set_meta("plaque", true)


# ------------------------------------------------------------------------------------------------ mesures (P3-07 §06)
## Mesures au point courant (héros posé, caméra stabilisée), enregistrées dans les mesures du parcours.
func analyse(id: String) -> void:
	var v: Rect2 = s.cam.view_rect()
	var hs := World25.screen(s.hero)
	var ppm_y := sin(World25.pitch) * World25.PPM
	var a := {
		"hauteur_heros_pct": snappedf((hs.y - v.position.y) / v.size.y * 100.0, 0.1),
		"sol_visible_devant_m": snappedf((hs.y - v.position.y) / ppm_y, 0.1),   # vers le haut de l'écran
		"sol_visible_derriere_m": snappedf((v.end.y - hs.y) / ppm_y, 0.1),
		"largeur_visible_m": snappedf(v.size.x / World25.PPM, 0.1),
		"tiers_superieur": _classify_top_third(),
		"marches_visibles": _visible_steps(),
	}
	if _hidden_ground.is_empty():
		_hidden_ground = _ground_hidden()
	s.m["analyses"] = s.m.get("analyses", {})
	s.m["analyses"][id] = a
	s.m["sol_praticable_masque"] = _hidden_ground


func _ray(from: Vector3, to: Vector3, mask: int) -> Dictionary:
	var space := get_world_3d().direct_space_state
	var ex: Array = []
	for i in 4:
		var pr := PhysicsRayQueryParameters3D.create(from, to, mask, ex)
		var hit := space.intersect_ray(pr)
		if hit.is_empty() or not (hit["collider"] as Object).has_meta("plaque"):
			return hit
		ex.append(hit["rid"])
	return {}


## Tiers supérieur de l'écran (1280 × 720) : part de paysage non jouable, d'eau/berges, d'aire de jeu et de vide.
func _classify_top_third() -> Dictionary:
	var c := {"paysage": 0, "eau_berges": 0, "aire_de_jeu": 0, "vide": 0}
	var n := 0
	var vp: Vector2 = Session25.viewport_size(self)
	for j in 10:
		for i in 40:
			var px := Vector2((i + 0.5) / 40.0 * vp.x, (j + 0.5) / 10.0 * vp.y / 3.0)
			var o := cam.project_ray_origin(px)
			var d := cam.project_ray_normal(px)
			var hit := _ray(o, o + d * 400.0, L_FLOOR | L_OBST | L_NOWALK | L_OCC | Paysage.L_FOND)
			n += 1
			if hit.is_empty():
				c["vide"] += 1
			else:
				var lay: int = (hit["collider"] as CollisionObject3D).collision_layer
				if lay & Paysage.L_FOND:
					c["paysage"] += 1
				elif lay & L_NOWALK:
					c["eau_berges"] += 1
				else:
					c["aire_de_jeu"] += 1
	for k in c:
		c[k] = snappedf(100.0 * c[k] / n, 0.1)
	return c


## Marches dont le dessus est à l'écran et non caché (sur 8).
func _visible_steps() -> int:
	var e := {}
	for el in world.elements:
		if el["type"] == "stairs":
			e = el
	if e.is_empty():
		return -1
	var r: Rect2 = e["rect"]
	var yb: float = r.end.y - e["land_bottom"]
	var yt: float = r.position.y + e["land_top"]
	var n: int = e["risers"]
	var tread := (yb - yt) / n
	var view: Rect2 = s.cam.view_rect()
	var count := 0
	for i in n:
		var p := Vector3(r.get_center().x, yb - tread * (i + 0.5), e["h0"] + (e["h1"] - e["h0"]) / n * (i + 1) + 0.02)
		if not view.has_point(World25.screen(p)):
			continue
		var g := World25.g3(p)
		if _ray(g, g + World25.cam_back() * 80.0, L_OBST | L_OCC | Paysage.L_FOND).is_empty():
			count += 1
	return count


## Part du sol praticable cachée par le décor (grille de 0,5 m, rayon vers la caméra) — dépend de la plongée.
func _ground_hidden() -> Dictionary:
	var tot := 0
	var hid := 0
	var by := {}
	for reg in world.regions:
		var r: Rect2 = reg["rect"]
		var x := r.position.x + 0.25
		while x < r.end.x:
			var y := r.position.y + 0.25
			while y < r.end.y:
				var q := Vector2(x, y)
				var sf: Dictionary = world.surface_at(q, world.region_h(reg, q))
				if not sf.is_empty() and sf["id"] == reg["id"]:
					tot += 1
					var g := World25.g3(Vector3(x, y, sf["h"] + 0.05))
					var hh := _ray(g, g + World25.cam_back() * 80.0, L_FLOOR | L_OBST | L_OCC | Paysage.L_FOND)
					if not hh.is_empty():
						hid += 1
						var key := "%s<-%s" % [reg["id"], _body_name(hh["collider"])]
						by[key] = by.get(key, 0) + 1
				y += 0.5
			x += 0.5
	return {"cellules": tot, "masquees": hid, "pct": snappedf(100.0 * hid / maxi(1, tot), 0.1), "par_cause": by}


func _body_name(o: Object) -> String:
	var lay: int = (o as CollisionObject3D).collision_layer
	if lay & Paysage.L_FOND:
		return "paysage"
	if lay & L_OCC:
		return "feuillage/toit"
	if lay & L_OBST:
		return "obstacle/mur"
	return "sol/terrasse"


# ------------------------------------------------------------------------------------------------ variantes (P3-07)
func _apply_variante() -> void:
	if variante == "":
		World25.pitch = World25.PITCH
		s.cam.aim_frac = 0.0
		return
	var v: Dictionary = Variantes.get_v(variante)
	World25.pitch = deg_to_rad(v["pitch_deg"])
	s.cam.aim_frac = v["aim_frac"]
	s.arch = "Variante " + v["label"] + " · paysage " + paysage


## Visuel d'ensemble (doc 07 §07) : vue de dessus du paysage non jouable, des zones praticables (calque F2) et des
## limites de caméra de l'instance (rectangle écran ramené au sol, aux trois zooms : jaune = zone parcourue par le
## centre du cadre ; blanc = tout ce que le cadre peut montrer à ×2).
func _top_view() -> void:
	s.options["layers"] = true
	s.options["debug"] = false
	_env_res.fog_enabled = false                   # la brume dépend de la visée : sans objet en vue de dessus
	apply_options()
	set_physics_process(false)
	var im := ImmediateMesh.new()
	var lines := MeshInstance3D.new()
	lines.mesh = im
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.vertex_color_use_as_albedo = true
	lm.no_depth_test = true
	lines.material_override = lm
	root.add_child(lines)
	var b: Rect2 = s.cam.bounds
	for z in [[2.0, Color(1, 1, 1)], [3.0, Color(1, 0.85, 0.2)]]:
		var half: Vector2 = Vector2(1280, 720) / z[0] / 2.0
		var r := b if z[0] == 2.0 else b.grow_individual(-half.x, -half.y, -half.x, -half.y)
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]:
			var q := World25.screen_to_plan(c, 0.0)
			im.surface_set_color(z[1])
			im.surface_add_vertex(Vector3(q.x, 0.4, q.y))
		im.surface_end()
	var t: Dictionary = _paysage_cfg.get("terrain", {"rect": [world.decor.position.x, world.decor.position.y, world.decor.end.x, world.decor.end.y]})
	var q: Array = t["rect"]
	cam.basis = Basis(Vector3.RIGHT, -PI / 2.0)
	cam.size = maxf(q[3] - q[1], (q[2] - q[0]) * 720.0 / 1280.0) * 0.82
	cam.position = Vector3((q[0] + q[2]) / 2.0, 150.0, (q[1] + q[3]) / 2.0 - 6.0)
	cam.far = 400.0
	for i in 8:
		await get_tree().process_frame
	capture("vue_dessus")
	get_tree().quit()


func _cam_basis() -> void:
	cam.transform.basis = Basis(World25.cam_right(), World25.cam_up(), World25.cam_back())


## Changement de variante ou de paysage en jeu : même position, même zoom, instance reconstruite.
func _reload_here() -> void:
	var here: Vector3 = s.hero
	var file: String = world.path
	var m: String = world.mode
	_apply_variante()
	_cam_basis()
	_load(file, m, here)
	for k in actors:
		_sync_sprite(actors[k])


func _mat(role: String, c := Color(-1, 0, 0)) -> ShaderMaterial:
	var mm := ShaderMaterial.new()
	mm.shader = BLOCK_SH
	mm.set_shader_parameter("albedo", Look.col(role) if c.r < 0 else c)
	mm.set_shader_parameter("grid", 0.0)
	_block_mats.append(mm)
	return mm


func _box_mesh(center: Vector3, size: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = center
	(parent if parent != null else root).add_child(mi)
	return mi


func _static_box(center: Vector3, size: Vector3, layer: int, basis := Basis.IDENTITY) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = layer
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	sb.add_child(cs)
	sb.transform = Transform3D(basis, center)
	root.add_child(sb)
	return sb


func _obstacle_cyl(foot: Vector3, r: float, h: float, layer := L_OBST) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = layer
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	cs.position = Vector3(0, h / 2.0, 0)
	sb.add_child(cs)
	sb.position = foot
	root.add_child(sb)
	return sb


func _rect_center(r: Rect2, h0: float, h1: float) -> Vector3:
	return Vector3(r.get_center().x, (h0 + h1) / 2.0, r.get_center().y)


func _build(e: Dictionary) -> void:
	match e["type"]:
		"floor":
			var r: Rect2 = e["rect"]
			# le sol de décor est 2 cm plus bas que les sols praticables : aucun rayon ne peut hésiter entre les deux
			var lift := -0.02 if e["role"] == "decor" else 0.0
			var th := 0.3
			_box_mesh(_rect_center(r, e["h"] - th + lift, e["h"] + lift), Vector3(r.size.x, th, r.size.y), _mat(e["role"]))
			_static_box(_rect_center(r, e["h"] - th + lift, e["h"] + lift), Vector3(r.size.x, th, r.size.y), L_NOWALK if e["role"] == "decor" else L_FLOOR)
		"block":
			var r: Rect2 = e["rect"]
			var size := Vector3(r.size.x, e["h1"] - e["h0"], r.size.y)
			if e["role"] == "terrasse":
				# dessus = sol de niveau +1 ; faces = paroi (couleur de pierre)
				_box_mesh(_rect_center(r, e["h0"], e["h1"] - 0.06), size - Vector3(0, 0.06, 0), _mat("terrasse_face"))
				_box_mesh(_rect_center(r, e["h1"] - 0.06, e["h1"]), Vector3(r.size.x, 0.06, r.size.y), _mat("terrasse"))
				_static_box(_rect_center(r, e["h0"], e["h1"]), size, L_FLOOR)
			else:
				var mi := _box_mesh(_rect_center(r, e["h0"], e["h1"]), size, _mat(e["role"]))
				var sb := _static_box(_rect_center(r, e["h0"], e["h1"]), size, L_OBST)
				fade_nodes[sb] = [mi]
		"stairs":
			_build_stairs(e)
		"water":
			var r: Rect2 = e["rect"]
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(r.size.x, 0.1, r.size.y)
			mi.mesh = bm
			var wm := ShaderMaterial.new()
			wm.shader = WATER_SH
			wm.set_shader_parameter("albedo", Look.col("eau"))
			_water_mats.append(wm)
			mi.material_override = wm
			mi.position = _rect_center(r, e["h"] - 0.1, e["h"])
			root.add_child(mi)
			_static_box(_rect_center(r, e["h"] - 0.6, e["h"]), Vector3(r.size.x, 0.6, r.size.y), L_NOWALK)
		"bank":
			var r: Rect2 = e["rect"]
			var dh: float = e["h_top"] - e["h_bottom"]
			var length := sqrt(r.size.x * r.size.x + dh * dh)
			var ang: float = atan2(dh, r.size.x) * e["water_side"]
			var b := Basis(Vector3(0, 0, 1), -ang)
			var c := Vector3(r.get_center().x, (e["h_top"] + e["h_bottom"]) / 2.0 - 0.15, r.get_center().y)
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(length, 0.3, r.size.y)
			mi.mesh = bm
			mi.material_override = _mat("berge")
			mi.transform = Transform3D(b, c)
			root.add_child(mi)
			_static_box(c, Vector3(length, 0.3, r.size.y), L_NOWALK, b)
		"deck":
			var r: Rect2 = e["rect"]
			_box_mesh(_rect_center(r, e["h"] - 0.22, e["h"] + 0.012), Vector3(r.size.x, 0.232, r.size.y), _mat("pont"))
			_static_box(_rect_center(r, e["h"] - 0.22, e["h"]), Vector3(r.size.x, 0.22, r.size.y), L_FLOOR)
		"rail", "border":
			var r: Rect2 = e["rect"]
			var role: String = e["role"]
			var mi := _box_mesh(_rect_center(r, e["h"], e["h"] + e["height"]), Vector3(r.size.x, e["height"], r.size.y), _mat(role))
			var sb := _static_box(_rect_center(r, e["h"], e["h"] + e["height"]), Vector3(r.size.x, e["height"], r.size.y), L_OBST)
			if e["height"] > 1.0:
				fade_nodes[sb] = [mi]
		"gate":
			var a: Vector2 = e["a"]
			var b2: Vector2 = e["b"]
			var mt := _mat("porte")
			for p in [a, b2]:
				_box_mesh(Vector3(p.x, e["h"] + e["height"] / 2.0, p.y), Vector3(0.3, e["height"], 0.3), mt)
				_static_box(Vector3(p.x, e["h"] + e["height"] / 2.0, p.y), Vector3(0.3, e["height"], 0.3), L_OBST)
			var mid := (a + b2) / 2.0
			var span := (b2 - a)
			_box_mesh(Vector3(mid.x, e["h"] + e["height"] - 0.15, mid.y), Vector3(maxf(0.3, absf(span.x) + 0.3), 0.3, maxf(0.3, absf(span.y) + 0.3)), mt)
		"post":
			var c: Vector2 = e["c"]
			var mi := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = e["r"] * 0.8
			cm.bottom_radius = e["r"]
			cm.height = e["height"]
			mi.mesh = cm
			mi.material_override = _mat(e["role"])
			mi.position = Vector3(c.x, e["h"] + e["height"] / 2.0, c.y)
			root.add_child(mi)
			_obstacle_cyl(Vector3(c.x, e["h"], c.y), e["r"], e["height"])
		"tree":
			var c: Vector2 = e["c"]
			var tr := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = e["r"] * 0.7
			cm.bottom_radius = e["r"]
			cm.height = e["trunk_h"] + 0.5
			tr.mesh = cm
			tr.material_override = _mat("arbre_tronc")
			tr.position = Vector3(c.x, e["h"] + (e["trunk_h"] + 0.5) / 2.0, c.y)
			root.add_child(tr)
			var trunk := _obstacle_cyl(Vector3(c.x, e["h"], c.y), e["r"], e["trunk_h"])
			var fo := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = e["foliage_r"]
			sm.height = e["foliage_r"] * 1.8
			fo.mesh = sm
			fo.material_override = _mat("arbre")
			fo.position = Vector3(c.x, e["h"] + e["foliage_h"], c.y)
			root.add_child(fo)
			var occ := StaticBody3D.new()
			occ.collision_layer = L_OCC
			occ.collision_mask = 0
			var cs := CollisionShape3D.new()
			var sph := SphereShape3D.new()
			sph.radius = e["foliage_r"] * 0.95
			cs.shape = sph
			cs.scale = Vector3(1, 0.9, 1)
			occ.add_child(cs)
			occ.position = fo.position
			root.add_child(occ)
			fade_nodes[occ] = [fo, tr]
			fade_nodes[trunk] = [fo, tr]
		"house":
			var r: Rect2 = e["rect"]
			var h0: float = e["h0"]
			var h1: float = e["h1"]
			var walls := _box_mesh(_rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), _mat("maison"))
			var roof := MeshInstance3D.new()
			var pm := PrismMesh.new()
			pm.size = Vector3(r.size.y + 0.6, e["roof"], r.size.x + 0.6)   # triangle dans le plan YZ, faîtage selon X
			roof.mesh = pm
			roof.material_override = _mat("maison_toit")
			roof.transform = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(r.get_center().x, h1 + e["roof"] / 2.0, r.get_center().y))
			root.add_child(roof)
			var door := _box_mesh(Vector3(r.get_center().x + 0.6, h0 + 1.0, r.end.y + 0.02), Vector3(1.0, 2.0, 0.06), _mat("porte"))
			var sb := _static_box(_rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), L_OBST)
			var rs := StaticBody3D.new()
			rs.collision_layer = L_OCC
			rs.collision_mask = 0
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(r.size.x + 0.6, e["roof"], r.size.y + 0.6)
			cs.shape = bs
			rs.add_child(cs)
			rs.position = Vector3(r.get_center().x, h1 + e["roof"] / 2.0, r.get_center().y)
			root.add_child(rs)
			fade_nodes[sb] = [walls, roof, door]
			fade_nodes[rs] = [walls, roof, door]


## Escalier : marches visuelles (8 × 0,15 m) ; collision = rampe continue (prisme) + palier haut.
func _build_stairs(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var n: int = e["risers"]
	var rise: float = (e["h1"] - e["h0"]) / n
	var yb: float = r.end.y - e["land_bottom"]
	var yt: float = r.position.y + e["land_top"]
	var tread: float = (yb - yt) / n
	var mt := _mat("escalier")
	var side := _mat("terrasse_face")
	for i in n:
		var top: float = e["h0"] + rise * (i + 1)
		var y1 := yb - tread * i
		var y0 := yb - tread * (i + 1)
		_box_mesh(Vector3(r.get_center().x, (e["h0"] + top) / 2.0, (y0 + y1) / 2.0), Vector3(r.size.x - 0.24, top - e["h0"], y1 - y0), mt)
	# palier haut et limons (côtés)
	_box_mesh(Vector3(r.get_center().x, e["h1"] / 2.0, (r.position.y + yt) / 2.0), Vector3(r.size.x, e["h1"], yt - r.position.y), mt)
	var run := yb - yt
	var ang := atan2(e["h1"] - e["h0"], run)
	var ln := sqrt(run * run + (e["h1"] - e["h0"]) * (e["h1"] - e["h0"]))
	for x in [r.position.x + 0.06, r.end.x - 0.06]:
		var mi := _box_mesh(Vector3(x, (e["h0"] + e["h1"]) / 2.0 + 0.04, (yt + yb) / 2.0), Vector3(0.12, 0.2, ln), side)
		mi.basis = Basis(Vector3.RIGHT, ang)
	var sb := StaticBody3D.new()
	sb.collision_layer = L_FLOOR
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cv := ConvexPolygonShape3D.new()
	var x0 := r.position.x
	var x1 := r.end.x
	cv.points = PackedVector3Array([Vector3(x0, e["h0"], yb), Vector3(x1, e["h0"], yb), Vector3(x0, e["h1"], yt), Vector3(x1, e["h1"], yt),
		Vector3(x0, e["h0"], yt), Vector3(x1, e["h0"], yt)])
	cs.shape = cv
	sb.add_child(cs)
	root.add_child(sb)
	_static_box(Vector3(r.get_center().x, e["h1"] / 2.0, (r.position.y + yt) / 2.0), Vector3(r.size.x, e["h1"], yt - r.position.y), L_FLOOR)
	for x in [r.position.x + 0.06, r.end.x - 0.06]:
		_static_box(Vector3(x, (e["h0"] + e["h1"] + 0.2) / 2.0, (yt + yb) / 2.0), Vector3(0.12, e["h1"] + 0.2 - e["h0"], yb - yt), L_OBST)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v in [a, b, c, a, c, d]:
		st.add_vertex(v)


## Calque « couches / collisions / niveaux » (F2) : surfaces praticables par niveau, rampe, solides.
func _build_overlay() -> void:
	_overlay = Node3D.new()
	root.add_child(_overlay)
	for reg in world.regions:
		var r: Rect2 = reg["rect"]
		var ramp: bool = not reg["ramp"].is_empty()
		var c := Color(1.0, 0.25, 0.9, 0.35) if ramp else (Color(1.0, 0.6, 0.1, 0.35) if reg["h"] > 0.6 else Color(0.2, 0.9, 0.35, 0.3))
		var parts: Array = [r]
		for hole in reg["holes"]:
			var np: Array = []
			for pr in parts:
				np.append_array(_subtract(pr, hole))
			parts = np
		for pr in parts:
			var mi := MeshInstance3D.new()
			var am := ArrayMesh.new()
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var pts := [Vector2(pr.position.x, pr.position.y), Vector2(pr.end.x, pr.position.y), pr.end, Vector2(pr.position.x, pr.end.y)]
			var v3 := []
			for q in pts:
				v3.append(Vector3(q.x, world.region_h(reg, q) + 0.03, q.y))
			_quad(st, v3[0], v3[1], v3[2], v3[3])
			st.commit(am)
			mi.mesh = am
			var om := ShaderMaterial.new()
			om.shader = OVER_SH
			om.set_shader_parameter("color", c)
			mi.material_override = om
			_overlay.add_child(mi)
	for so in world.solids:
		var om := ShaderMaterial.new()
		om.shader = OVER_SH
		om.set_shader_parameter("color", Color(1, 0.15, 0.1, 0.45))
		var mi := MeshInstance3D.new()
		if so["kind"] == "circle":
			var cm := CylinderMesh.new()
			cm.top_radius = so["r"]
			cm.bottom_radius = so["r"]
			cm.height = 0.06
			mi.mesh = cm
			mi.position = Vector3(so["c"].x, so["h0"] + 0.05, so["c"].y)
		else:
			var bm := BoxMesh.new()
			var rr: Rect2 = so["rect"]
			bm.size = Vector3(rr.size.x, 0.06, rr.size.y)
			mi.mesh = bm
			mi.position = Vector3(rr.get_center().x, so["h0"] + 0.05, rr.get_center().y)
		mi.material_override = om
		_overlay.add_child(mi)
	_labels = Node3D.new()
	root.add_child(_labels)
	for k in world.checkpoints:
		var p: Vector3 = world.checkpoints[k]
		if world.surfaces_under(Vector2(p.x, p.y)).is_empty():
			continue
		var lb := Label3D.new()
		lb.text = k
		lb.font_size = 48
		lb.pixel_size = 0.01
		lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lb.no_depth_test = true
		lb.modulate = Color(1, 0.95, 0.4)
		lb.outline_size = 10
		lb.position = Vector3(p.x, p.z + 0.15, p.y)
		_labels.add_child(lb)


static func _subtract(r: Rect2, h: Rect2) -> Array:
	if not r.intersects(h):
		return [r]
	var out: Array = []
	var i := r.intersection(h)
	if i.position.y > r.position.y:
		out.append(Rect2(r.position.x, r.position.y, r.size.x, i.position.y - r.position.y))
	if i.end.y < r.end.y:
		out.append(Rect2(r.position.x, i.end.y, r.size.x, r.end.y - i.end.y))
	if i.position.x > r.position.x:
		out.append(Rect2(r.position.x, i.position.y, i.position.x - r.position.x, i.size.y))
	if i.end.x < r.end.x:
		out.append(Rect2(i.end.x, i.position.y, r.end.x - i.end.x, i.size.y))
	return out


# ------------------------------------------------------------------------------------------------ personnages
func _make_actor(name: String, key: String) -> Dictionary:
	var a = Actor25.make(key)
	var node := Node3D.new()
	node.name = name
	var holder := Node3D.new()
	# carte verticale tournée vers la caméra (azimut seul) : les verticales du monde restent verticales à l'écran
	holder.basis = Basis(Vector3.UP, -World25.YAW)
	holder.position = World25.cam_back() * SPRITE_TOWARD_CAM
	node.add_child(holder)
	var spr := AnimatedSprite3D.new()
	spr.sprite_frames = a.frames
	spr.centered = false
	spr.pixel_size = 1.0 / World25.PPM
	spr.scale = Vector3(1, 1.0 / cos(World25.pitch), 1)     # hauteur à l'écran = hauteur de l'image en px natifs
	# sprites en passe transparente, SANS écriture de profondeur : le décor les cache (test de profondeur), mais un
	# personnage ne « cache » jamais un autre personnage pour la silhouette (sinon elle s'affiche sur le compagnon)
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	spr.transparent = true
	spr.shaded = false
	spr.double_sided = true
	spr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(spr)
	var ghost := MeshInstance3D.new()
	var qm := QuadMesh.new()
	ghost.mesh = qm
	var gm := ShaderMaterial.new()
	gm.shader = GHOST_SH
	ghost.material_override = gm
	gm.render_priority = -1                    # silhouettes dessinées avant les personnages (qui passent dessus)
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(ghost)
	var blob := MeshInstance3D.new()
	var bq := QuadMesh.new()
	bq.size = Vector2(0.9, 0.55)
	blob.mesh = bq
	var bmat := ShaderMaterial.new()
	bmat.shader = BLOB_SH
	blob.material_override = bmat
	blob.rotation = Vector3(-PI / 2, 0, 0)
	blob.position = Vector3(0, 0.03, 0)
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(blob)
	var d := {"actor": a, "spr": spr, "ghost": ghost, "ghost_mat": gm, "node": node, "quad": qm}
	actors[name] = d
	_sync_sprite(d)
	return d


func _sync_sprite(d: Dictionary) -> void:
	var a = d["actor"]
	var spr: AnimatedSprite3D = d["spr"]
	if spr.animation != a.anim:
		spr.animation = a.anim
	spr.frame = a.frame
	spr.flip_h = a.flip
	var tex: Texture2D = a.texture()
	var w := tex.get_width()
	var h := tex.get_height()
	spr.offset = Vector2(-int(w / 2), 0)
	spr.scale = Vector3(1, 1.0 / cos(World25.pitch), 1)
	var gm: ShaderMaterial = d["ghost_mat"]
	gm.set_shader_parameter("tex", tex)
	gm.set_shader_parameter("flip", 1.0 if a.flip else 0.0)
	var qm: QuadMesh = d["quad"]
	var sw := w / World25.PPM
	var sh := h / World25.PPM / cos(World25.pitch)
	qm.size = Vector2(sw, sh)
	(d["ghost"] as MeshInstance3D).position = Vector3((float(-int(w / 2)) + w / 2.0) / World25.PPM, sh / 2.0, 0.001)


func _spawn_actors() -> void:
	body = CharacterBody3D.new()
	body.name = "Heros"
	body.collision_layer = L_ACTOR
	body.collision_mask = L_FLOOR | L_OBST | L_NOWALK
	body.floor_max_angle = deg_to_rad(40)
	body.floor_snap_length = 0.35
	body.floor_constant_speed = true
	body.floor_stop_on_slope = true
	body.wall_min_slide_angle = deg_to_rad(5)
	body.safe_margin = 0.01
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.6
	cs.shape = cap
	cs.position = Vector3(0, 0.8, 0)
	body.add_child(cs)
	add_child(body)
	var h := _make_actor("aren", "aren")
	body.add_child(h["node"])
	var c := _make_actor("ilya", "ilya")
	add_child(c["node"])
	comp_vis = c["node"]


func teleport(p: Vector3, comp: Vector3) -> void:
	body.global_position = World25.g3(p)
	body.velocity = Vector3.ZERO
	body.reset_physics_interpolation()
	comp_vis.position = World25.g3(comp)
	comp_vis.reset_physics_interpolation()
	apply_camera(s.cam.render_center(), s.cam.zoom)
	cam.reset_physics_interpolation()


func respawn() -> void:
	s.warp_to(world.spawn)


## Sol sous un point du plan, vu d'en haut à partir de l'altitude actuelle (+ pas franchissable).
func _probe(q: Vector2, h: float) -> bool:
	var space := get_world_3d().direct_space_state
	var from := Vector3(q.x, h + world.step_h + 0.05, q.y)
	var to := Vector3(q.x, h - world.step_h - 0.05, q.y)
	var pr := PhysicsRayQueryParameters3D.create(from, to, L_FLOOR | L_NOWALK)
	var hit := space.intersect_ray(pr)
	if hit.is_empty():
		return false                                  # vide ou chute de plus de 25 cm : rebord
	var col: CollisionObject3D = hit["collider"]
	return (col.collision_layer & L_NOWALK) == 0      # eau, berge, décor : non praticable


func _dir_ok(p: Vector2, h: float, dir: Vector2) -> bool:
	if dir.length() < 0.0001:
		return true
	var r: float = world.actor_r + 0.08
	for a in [0.0, 0.6, -0.6]:
		if not _probe(p + dir.normalized().rotated(a) * r, h):
			return false
	return true


func _can_go(p: Vector2, h: float, v: Vector2, delta: float) -> bool:
	if not _dir_ok(p, h, v):
		return false
	var t := body.global_transform
	t.origin.y += world.step_h + 0.05
	var motion := Vector3(v.x, 0, v.y) * delta
	motion += motion.normalized() * 0.02
	return not body.test_move(t, motion)


func step_hero(dir: Vector2, delta: float) -> Dictionary:
	var gp := body.global_position
	var p := Vector2(gp.x, gp.z)
	var h := gp.y
	var v: Vector2 = dir * world.speed
	var blocked := false
	# même règle de glissement que A : direction complète, sinon ses composantes x puis y (rebords par rayons,
	# obstacles par test_move depuis une position relevée d'un pas, pour ne pas confondre rampe et mur)
	if v.length() > 0.0 and not _can_go(p, h, v, delta):
		blocked = true
		var chosen := Vector2.ZERO
		for t in [Vector2(v.x, 0), Vector2(0, v.y), v.rotated(0.61) * 0.82, v.rotated(-0.61) * 0.82, v.rotated(1.22) * 0.34, v.rotated(-1.22) * 0.34]:
			if t.length() > 0.01 and _can_go(p, h, t, delta):
				chosen = t
				break
		v = chosen
	body.velocity.x = v.x
	body.velocity.z = v.y
	if body.is_on_floor():
		body.velocity.y = 0.0
	else:
		body.velocity.y -= 20.0 * delta
	body.move_and_slide()
	if body.get_slide_collision_count() > 0 and v.length() > 0:
		for i in body.get_slide_collision_count():
			var c := body.get_slide_collision(i)
			if absf(c.get_normal().y) < 0.5:
				blocked = true
	gp = body.global_position
	var s2: Dictionary = world.surface_at(Vector2(gp.x, gp.z), gp.y)
	return {"p": Vector3(gp.x, gp.z, gp.y), "id": s2.get("id", "?"), "blocked": blocked}


func animate(hm: float, hdir: Vector2, cm: float, cdir: Vector2, delta: float) -> void:
	actors["aren"]["actor"].step(hm, hdir, delta)
	actors["ilya"]["actor"].step(cm, cdir, delta)
	comp_vis.position = World25.g3(s.companion)
	for k in actors:
		_sync_sprite(actors[k])


func apply_camera(center: Vector2, zoom: float) -> void:
	var vp: Vector2 = Session25.viewport_size(self)
	cam.size = vp.y / (World25.PPM * zoom)
	cam.position = World25.cam_right() * (center.x / World25.PPM) + World25.cam_up() * (-center.y / World25.PPM) + World25.cam_back() * 120.0


## Le héros est-il caché ? Rayons de son corps vers la caméra (pieds+0,3 m, buste, tête).
func hero_occluded() -> bool:
	var space := get_world_3d().direct_space_state
	var base := body.global_position
	var hit_any := false
	var hits: Array = []
	for hh in [0.35, 0.9, 1.5]:
		var from := base + Vector3(0, hh, 0) + World25.cam_back() * (SPRITE_TOWARD_CAM + 0.05)
		var pr := PhysicsRayQueryParameters3D.create(from, from + World25.cam_back() * 60.0, L_FLOOR | L_OBST | L_OCC)
		var hit := space.intersect_ray(pr)
		if not hit.is_empty():
			if hh > 0.5:
				hit_any = true
			hits.append(hit["collider"])
	_occluded = hit_any
	_update_fade(hits if s.options["occlusion"] == 2 else [])
	return hit_any


func _update_fade(colliders: Array) -> void:
	var want: Array = []
	for c in colliders:
		if fade_nodes.has(c):
			for mi in fade_nodes[c]:
				if not want.has(mi):
					want.append(mi)
	for mi in _faded:
		if is_instance_valid(mi) and not want.has(mi):
			(mi.material_override as ShaderMaterial).set_shader_parameter("fade", 1.0)
	for mi in want:
		(mi.material_override as ShaderMaterial).set_shader_parameter("fade", 0.42)
	_faded = want


func apply_options() -> void:
	if s == null:
		return
	var o: Dictionary = s.options
	for mm in _block_mats:
		mm.set_shader_parameter("grid", 1.0 if o["grid"] else 0.0)
	for wm in _water_mats:
		wm.set_shader_parameter("anim", 1.0 if o["anim"] else 0.0)
	if _overlay != null:
		_overlay.visible = o["layers"]
		_labels.visible = o["layers"] or o["debug"]
	for k in actors:
		var d: Dictionary = actors[k]
		(d["spr"] as AnimatedSprite3D).texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR if o["filter_linear"] else BaseMaterial3D.TEXTURE_FILTER_NEAREST
		(d["ghost"] as MeshInstance3D).visible = o["occlusion"] >= 1 and k != "pnj"
	if o["occlusion"] < 2:
		_update_fade([])


# ------------------------------------------------------------------------------------------------ boucle
func _unhandled_input(e: InputEvent) -> void:
	if _switching:
		return
	if e is InputEventKey and e.pressed and not e.echo and variante != "":
		if e.physical_keycode == KEY_V:
			variante = Variantes.next_of(variante)
			_reload_here()
			s.toast("Variante " + Variantes.get_v(variante)["label"], 2.0)
			return
		if e.physical_keycode == KEY_L:
			paysage = Paysage.TRAITEMENTS[(Paysage.TRAITEMENTS.find(paysage) + 1) % Paysage.TRAITEMENTS.size()]
			_apply_variante()
			_reload_here()
			s.toast("Paysage : " + {"3d": "3D simplifiée + brume", "2d": "plans 2D", "aucun": "aucun (P3)"}[paysage], 2.0)
			return
	s.handle_input(e)


func _physics_process(delta: float) -> void:
	if _switching:
		return
	s.process(delta)
	if not s.pending_instance.is_empty():
		_switch(s.pending_instance)
	if _quit_when_done and s.pilot_done:
		_finish()


func _process(delta: float) -> void:
	# mesure au rythme de l'AFFICHAGE (caméra et héros interpolés) : à-coups visibles réels à 30 / 60 / 144 i/s
	if s == null or world == null:
		return
	var ct := cam.get_global_transform_interpolated().origin
	var cs: Vector2 = Vector2(ct.dot(World25.cam_right()), -ct.dot(World25.cam_up())) * World25.PPM * s.cam.zoom
	var ht := body.get_global_transform_interpolated().origin
	var hs: Vector2 = World25.screen(Vector3(ht.x, ht.z, ht.y)) * s.cam.zoom - cs
	_render_measure(cs, hs, delta)
	if s.m.get("frames", 0) > 0 and s._skip_measure == 0:
		_frame_ms.append(delta * 1000.0)


func _render_measure(cs: Vector2, hs: Vector2, delta: float) -> void:
	if delta <= 0.0:
		return
	if s._skip_measure > 0:
		_rend_prev = Vector2.INF
	var m: Dictionary = s.m
	m["render_frames"] = m.get("render_frames", 0) + 1
	if _rend_prev != Vector2.INF and not s.cam.zooming():
		var v := (cs - _rend_prev) / delta
		if (v - _rend_prev_v).length() > 100.0:
			m["render_cam_jerks"] = m.get("render_cam_jerks", 0) + 1
		_rend_prev_v = v

	_rend_prev = cs
	_rend_hero_prev = hs


func _switch(t: Dictionary) -> void:
	_switching = true
	var tw: Tween = s.fade_to(1.0, 0.25)
	await tw.finished
	var to: String = t["to"]
	var m2 := "temoin" if to == World25.SPEC else "instance"
	s.pending_instance = {}
	_load(to, m2, t["arrive"])
	await get_tree().physics_frame
	s.toast("Instance : " + to.get_file(), 1.5)
	_switching = false
	s.fade_to(0.0, 0.25)


func capture(id: String) -> void:
	var out: String = _cli.get("out", "user://p3_captures")
	DirAccess.make_dir_recursive_absolute(out)
	var img := get_viewport().get_texture().get_image()
	img.save_png(out.path_join("%s_%s.png" % [_prefix(), id]))


func _prefix() -> String:
	var tag: String = ("_" + str(_cli["tag"])) if _cli.has("tag") else ""
	return ("B" if variante == "" else "V%s_%s" % [variante, paysage]) + tag


func _finish() -> void:
	_quit_when_done = false
	var out: String = _cli.get("out", "user://p3_captures")
	DirAccess.make_dir_recursive_absolute(out)
	var f := FileAccess.open(out.path_join("%s_%s_mesures.json" % [_prefix(), s.pilot_name]), FileAccess.WRITE)
	var sm: Dictionary = s.summary()
	sm["variante"] = variante
	sm["paysage"] = paysage
	sm["plongee_deg"] = snappedf(rad_to_deg(World25.pitch), 0.01)
	sm["paysage_volumes"] = _paysage_stats
	if _frame_ms.size() > 0:
		var fm := _frame_ms.duplicate()
		fm.sort()
		var tot := 0.0
		for x in fm:
			tot += x
		sm["frametime_ms"] = {"moyen": snappedf(tot / fm.size(), 0.01), "p95": snappedf(fm[int(fm.size() * 0.95)], 0.01), "max": snappedf(fm[-1], 0.01), "images": fm.size()}
	sm["renderer"] = RenderingServer.get_current_rendering_method()
	# protocole de mesure sur PC (docs/PROTOCOLE_VALIDATION_CAMERA_GPU.md) : matériel et conditions de la mesure
	sm["machine"] = {"carte_graphique": RenderingServer.get_video_adapter_name(), "fabricant": RenderingServer.get_video_adapter_vendor(),
		"pilote": OS.get_video_adapter_driver_info(), "api": RenderingServer.get_video_adapter_api_version(),
		"pilote_rendu": RenderingServer.get_current_rendering_driver_name(), "systeme": OS.get_distribution_name() + " " + OS.get_version(),
		"processeur": OS.get_processor_name(), "godot": Engine.get_version_info()["string"],
		"fenetre": [get_window().size.x, get_window().size.y], "vsync": DisplayServer.window_get_vsync_mode(),
		"ecran_hz": 0.0}
	var hz := DisplayServer.screen_get_refresh_rate()
	if not is_nan(hz) and hz > 0.0:
		sm["machine"]["ecran_hz"] = snappedf(hz, 0.1)
	sm["zoom_depart"] = _cli.get("zoom", "1")
	sm["fps_cap"] = Engine.max_fps
	f.store_string(JSON.stringify(sm, "  "))
	f.close()
	print("P3 MESURES B ", JSON.stringify(sm))
	get_tree().quit()
