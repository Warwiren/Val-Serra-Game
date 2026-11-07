extends Node2D
## P3 — ARCHITECTURE A : Node2D + Camera2D avec gestion de plusieurs hauteurs (prolongement de l'architecture
## actuelle du jeu). Le décor est fait d'ÉLÉMENTS 2D (ici des volumes de blockout projetés en polygones, demain des
## illustrations découpées) ; la profondeur n'existe pas pour le moteur : elle est CALCULÉE.
##  • Collisions : modèle logique (x, y, h) de world25.gd — surfaces par niveau, rampe d'escalier, solides.
##  • Tri : bande « sols » (dessinée sous tout) + éléments ordonnés une fois (tri topologique par emprises au sol et
##    altitude) ; chaque personnage est inséré à chaque image entre les éléments selon son point d'appui ET son
##    altitude (rayon vers / depuis la caméra dans le plan, règle « debout dessus »), pas d'après le Y écran.
##  • Occultation : détection par recouvrement des polygones ; silhouette par-dessus, transparence locale en option.
##  • Caméra : cam25.gd appliquée à une Camera2D — même cadrage que B.
## Scène : demo_a_2d.tscn (micro-test) ; scene_temoin_2d.tscn (diagnostic : même scène témoin, à titre de comparaison).

const World25 = preload("res://src/explore25/world25.gd")
const Session25 = preload("res://src/explore25/session25.gd")
const Actor25 = preload("res://src/explore25/actor25.gd")
const Look = preload("res://src/explore25/look25.gd")

@export_enum("temoin", "micro") var mode := "micro"
@export var arch_label := "A — Camera2D multi-hauteur"

var s
var world
var root: Node2D
var cam2d: Camera2D
var floors: Piece
var shadows: Node2D
var pieces: Array = []                   # éléments triés (Piece)
var actors := {}                         # nom -> {actor, node, spr, ghost, p: Vector3}
var overlay: Overlay
var _occluded := false
var _cli := {}
var _quit_when_done := false
var _switching := false
var _rend_prev := Vector2.INF
var _rend_prev_v := Vector2.ZERO
var _rend_hero_prev := Vector2.INF
var _rend_hero_prev_v := Vector2.ZERO
var sort_conflicts := 0
var conflict_pairs := {}                 # « devant X / derrière Y » -> nombre d'images (diagnostic du tri)
var _time := 0.0


class Piece extends Node2D:
	## Un élément de décor 2D : liste de polygones écran (déjà ombrés) + données de tri.
	var id := ""
	var polys: Array = []                 # [{pts: PackedVector2Array, col: Color}]
	var lines: Array = []                 # grille [{a, b, col}]
	var fp_rect := Rect2()                # emprise au sol (plan)
	var fp_circle := Vector3.ZERO         # (cx, cy, r) si cylindre (r > 0)
	var h0 := 0.0
	var h1 := 0.0
	var aabb := Rect2()                   # rectangle écran
	var d_center := 0.0
	var fadeable := false
	var water: Array = []                 # rectangles d'eau animée (sols)
	var t := 0.0
	var anim := true

	func add(pts: PackedVector2Array, col: Color) -> void:
		polys.append({"pts": pts, "col": col})
		var r := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			r = r.expand(q)
		aabb = r if aabb.size == Vector2.ZERO and aabb.position == Vector2.ZERO else aabb.merge(r)

	func _draw() -> void:
		for p in polys:
			draw_colored_polygon(p["pts"], p["col"])
		for l in lines:
			draw_line(l["a"], l["b"], l["col"], 1.0)
		for w in water:
			var r: Rect2 = w["rect"]
			var h: float = w["h"]
			var k := 0
			var y := r.position.y + fmod(t * 0.35, 0.8)
			while y < r.end.y:
				var off := sin(y * 2.1 + t * 1.7) * 0.25
				var a := World25.screen(Vector3(r.position.x + 0.3 + off + fmod(k * 0.37, 1.0), y, h))
				var b := World25.screen(Vector3(r.position.x + 1.1 + off + fmod(k * 0.37, 1.0), y, h))
				draw_line(a, b, Color(1, 1, 1, 0.16), 1.0)
				var a2 := World25.screen(Vector3(r.end.x - 1.2 - off, y + 0.4, h))
				var b2 := World25.screen(Vector3(r.end.x - 0.5 - off, y + 0.4, h))
				draw_line(a2, b2, Color(1, 1, 1, 0.12), 1.0)
				y += 0.8
				k += 1

	func _process(delta: float) -> void:
		if water.size() > 0 and anim:
			t += delta
			queue_redraw()


class Overlay extends Node2D:
	## Calque « couches / collisions / niveaux » (F2) et étiquettes des points de passage.
	var world
	var show_layers := false
	var show_labels := true

	func _draw() -> void:
		if world == null:
			return
		if show_layers:
			for reg in world.regions:
				var r: Rect2 = reg["rect"]
				var ramp: bool = not reg["ramp"].is_empty()
				var c := Color(1.0, 0.25, 0.9, 0.35) if ramp else (Color(1.0, 0.6, 0.1, 0.35) if reg["h"] > 0.6 else Color(0.2, 0.9, 0.35, 0.3))
				var parts: Array = [r]
				for hole in reg["holes"]:
					var np: Array = []
					for pr in parts:
						np.append_array(_sub(pr, hole))
					parts = np
				for pr in parts:
					var pts := PackedVector2Array()
					for q in [pr.position, Vector2(pr.end.x, pr.position.y), pr.end, Vector2(pr.position.x, pr.end.y)]:
						pts.append(World25.screen(Vector3(q.x, q.y, world.region_h(reg, q))))
					draw_colored_polygon(pts, c)
			for so in world.solids:
				var pts := PackedVector2Array()
				if so["kind"] == "circle":
					for i in 16:
						var q: Vector2 = so["c"] + Vector2.from_angle(TAU * i / 16.0) * so["r"]
						pts.append(World25.screen(Vector3(q.x, q.y, so["h0"])))
				else:
					var rr: Rect2 = so["rect"]
					for q in [rr.position, Vector2(rr.end.x, rr.position.y), rr.end, Vector2(rr.position.x, rr.end.y)]:
						pts.append(World25.screen(Vector3(q.x, q.y, so["h0"])))
				draw_colored_polygon(pts, Color(1, 0.15, 0.1, 0.45))
		if show_labels:
			var f := ThemeDB.fallback_font
			for k in world.checkpoints:
				var p: Vector3 = world.checkpoints[k]
				if world.surfaces_under(Vector2(p.x, p.y)).is_empty():
					continue
				var sp := World25.screen(p) + Vector2(-4, 4)
				draw_string_outline(f, sp, k, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0, 0, 0))
				draw_string(f, sp, k, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.95, 0.4))

	static func _sub(r: Rect2, h: Rect2) -> Array:
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


func _ready() -> void:
	_cli = parse_cli()
	if _cli.has("mode"):
		mode = _cli["mode"]
	RenderingServer.set_default_clear_color(Color(0.13, 0.15, 0.19))
	s = Session25.new(self, arch_label)
	s.build_hud()
	cam2d = Camera2D.new()
	add_child(cam2d)
	cam2d.make_current()
	shadows = Node2D.new()
	shadows.z_index = -2000
	_spawn_actors()
	_load(World25.SPEC, mode)
	_apply_cli()


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
	apply_options()
	if _cli.has("route"):
		s.start_pilot(_cli["route"])
		_quit_when_done = _cli.has("quit")


# ------------------------------------------------------------------------------------------------ construction
func _load(file: String, m: String, arrive := Vector3.INF) -> void:
	if actors.has("pnj"):
		(actors["pnj"]["blob"] as Node).queue_free()
		actors.erase("pnj")
	if root != null:
		root.remove_child(shadows)
		root.queue_free()
		remove_child(root)
	root = Node2D.new()
	root.name = "Instance"
	add_child(root)
	move_child(root, 0)
	root.add_child(shadows)
	pieces.clear()
	world = World25.load_world(file, m)
	floors = Piece.new()
	floors.z_index = -3000
	root.add_child(floors)
	var order := ["decor", "eau", "berge", "sol0", "pont"]
	var fl: Array = []
	for e in world.elements:
		if e["type"] in ["floor", "water", "bank", "deck"]:
			fl.append(e)
	fl.sort_custom(func(a, b): return order.find(a["role"]) < order.find(b["role"]))
	for e in fl:
		_floor(e)
	for e in world.elements:
		if not e["type"] in ["floor", "water", "bank", "deck"]:
			_piece(e)
	if not world.npc.is_empty():
		var n: Dictionary = world.npc
		var d := _make_actor("pnj", n["sprite"])
		root.add_child(d["node"])
		d["p"] = n["p"]
		d["actor"].face_toward(Vector2(1, 0.3))
	_order_pieces()
	overlay = Overlay.new()
	overlay.world = world
	overlay.z_index = 3500
	root.add_child(overlay)
	for k in ["aren", "ilya"]:
		if actors[k]["node"].get_parent() != null:
			actors[k]["node"].get_parent().remove_child(actors[k]["node"])
		root.add_child(actors[k]["node"])
	s.set_world(world, arrive)
	teleport(s.hero, s.companion)
	apply_options()


static func P(x: float, y: float, h: float) -> Vector2:
	return World25.screen(Vector3(x, y, h))


## Hexaèdre (8 sommets en repère Godot, ordre : -x-y-z, +x-y-z, +x+y-z, -x+y-z, -x-y+z, +x-y+z, +x+y+z, -x+y+z) :
## faces visibles (normale vers la caméra), de la plus éloignée à la plus proche, ombrées comme en B.
func _hexa(pc: Piece, c: Array, col: Color, top_col := Color(-1, 0, 0), only_top := false) -> void:
	var faces := [[0, 3, 7, 4], [1, 5, 6, 2], [0, 4, 5, 1], [3, 2, 6, 7], [0, 1, 2, 3], [4, 7, 6, 5]]
	var cen := Vector3.ZERO
	for v in c:
		cen += v
	cen /= 8.0
	var vis: Array = []
	for f in faces:
		var fc: Vector3 = (c[f[0]] + c[f[1]] + c[f[2]] + c[f[3]]) / 4.0
		var e1: Vector3 = c[f[1]] - c[f[0]]
		var e2: Vector3 = c[f[3]] - c[f[0]]
		var n := e1.cross(e2).normalized()
		if n.dot(fc - cen) < 0:
			n = -n
		if n.dot(World25.cam_back()) <= 0.001:
			continue
		if only_top and n.y < 0.5:
			continue
		vis.append({"f": f, "n": n, "d": fc.dot(World25.cam_back())})
	vis.sort_custom(func(a, b): return a["d"] < b["d"])
	for v in vis:
		var pts := PackedVector2Array()
		for i in v["f"]:
			var g: Vector3 = c[i]
			pts.append(World25.screen(Vector3(g.x, g.z, g.y)))
		var base := top_col if (v["n"].y > 0.7 and top_col.r >= 0) else col
		pc.add(pts, Look.shade(base, v["n"]))


func _box(pc: Piece, r: Rect2, h0: float, h1: float, col: Color, top_col := Color(-1, 0, 0), only_top := false) -> void:
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	_hexa(pc, [Vector3(x0, h0, z0), Vector3(x1, h0, z0), Vector3(x1, h1, z0), Vector3(x0, h1, z0),
		Vector3(x0, h0, z1), Vector3(x1, h0, z1), Vector3(x1, h1, z1), Vector3(x0, h1, z1)], col, top_col, only_top)


func _grid(pc: Piece, r: Rect2, h: float, holes := []) -> void:
	var col := Color(0, 0, 0, 0.12)
	for x in range(int(ceil(r.position.x)), int(floor(r.end.x)) + 1):
		pc.lines.append({"a": P(x, r.position.y, h), "b": P(x, r.end.y, h), "col": col})
	for y in range(int(ceil(r.position.y)), int(floor(r.end.y)) + 1):
		pc.lines.append({"a": P(r.position.x, y, h), "b": P(r.end.x, y, h), "col": col})


func _floor(e: Dictionary) -> void:
	match e["type"]:
		"floor":
			var r: Rect2 = e["rect"]
			var h: float = e["h"]
			var pts := PackedVector2Array([P(r.position.x, r.position.y, h), P(r.end.x, r.position.y, h), P(r.end.x, r.end.y, h), P(r.position.x, r.end.y, h)])
			floors.add(pts, Look.shade(Look.col(e["role"]), Vector3.UP))
			_grid(floors, r, h)
		"water":
			var r: Rect2 = e["rect"]
			var h: float = e["h"]
			floors.add(PackedVector2Array([P(r.position.x, r.position.y, h), P(r.end.x, r.position.y, h), P(r.end.x, r.end.y, h), P(r.position.x, r.end.y, h)]),
				Look.shade(Look.col("eau"), Vector3.UP))
			floors.water.append({"rect": r, "h": h})
		"bank":
			var r: Rect2 = e["rect"]
			var hl: float = e["h_top"]
			var hw: float = e["h_bottom"]
			var x_land: float = r.position.x if e["water_side"] > 0 else r.end.x
			var x_water: float = r.end.x if e["water_side"] > 0 else r.position.x
			var pts := PackedVector2Array([P(x_land, r.position.y, hl), P(x_water, r.position.y, hw), P(x_water, r.end.y, hw), P(x_land, r.end.y, hl)])
			var n: Vector3 = Vector3(e["water_side"] * (hl - hw), r.size.x, 0).normalized()   # pente tournée vers l'eau
			floors.add(pts, Look.shade(Look.col("berge"), n))
		"deck":
			var r: Rect2 = e["rect"]
			_box(floors, r, e["h"] - 0.22, e["h"] + 0.012, Look.col("pont"))


func _new_piece(e: Dictionary) -> Piece:
	var pc := Piece.new()
	pc.id = e["id"]
	root.add_child(pc)
	pieces.append(pc)
	return pc


func _piece(e: Dictionary) -> void:
	match e["type"]:
		"block":
			var pc := _new_piece(e)
			var r: Rect2 = e["rect"]
			pc.fp_rect = r
			pc.h0 = e["h0"]
			pc.h1 = e["h1"]
			if e["role"] == "terrasse":
				_box(pc, r, e["h0"], e["h1"], Look.col("terrasse_face"), Look.col("terrasse"))
				_grid(pc, r, e["h1"])
			else:
				_box(pc, r, e["h0"], e["h1"], Look.col(e["role"]))
				pc.fadeable = true
		"stairs":
			var pc := _new_piece(e)
			var r: Rect2 = e["rect"]
			pc.fp_rect = r
			pc.h0 = e["h0"]
			pc.h1 = e["h1"]
			var n: int = e["risers"]
			var rise: float = (e["h1"] - e["h0"]) / n
			var yb: float = r.end.y - e["land_bottom"]
			var yt: float = r.position.y + e["land_top"]
			var tread: float = (yb - yt) / n
			_box(pc, Rect2(r.position.x, r.position.y, r.size.x, yt - r.position.y), e["h0"], e["h1"], Look.col("escalier"))
			for i in range(n - 1, -1, -1):
				var top: float = e["h0"] + rise * (i + 1)
				_box(pc, Rect2(r.position.x + 0.12, yb - tread * (i + 1), r.size.x - 0.24, tread), e["h0"], top, Look.col("escalier"))
			for x in [r.position.x, r.end.x - 0.12]:
				var hb := 0.2
				_hexa(pc, [Vector3(x, e["h0"], yt), Vector3(x + 0.12, e["h0"], yt), Vector3(x + 0.12, e["h1"] + hb, yt), Vector3(x, e["h1"] + hb, yt),
					Vector3(x, e["h0"], yb), Vector3(x + 0.12, e["h0"], yb), Vector3(x + 0.12, e["h0"] + hb, yb), Vector3(x, e["h0"] + hb, yb)], Look.col("terrasse_face"))
		"rail", "border":
			var pc := _new_piece(e)
			var r: Rect2 = e["rect"]
			pc.fp_rect = r
			pc.h0 = e["h"]
			pc.h1 = e["h"] + e["height"]
			_box(pc, r, pc.h0, pc.h1, Look.col(e["role"]))
			pc.fadeable = e["height"] > 1.0
		"gate":
			var a: Vector2 = e["a"]
			var b: Vector2 = e["b"]
			for q in [a, b]:
				var pc := _new_piece({"id": e["id"]})
				pc.fp_rect = Rect2(q - Vector2(0.15, 0.15), Vector2(0.3, 0.3))
				pc.h0 = e["h"]
				pc.h1 = e["h"] + e["height"]
				_box(pc, pc.fp_rect, pc.h0, pc.h1, Look.col("porte"))
			var pl := _new_piece({"id": e["id"] + "_linteau"})
			var lr := Rect2(a, Vector2.ZERO).expand(b).grow(0.15)
			pl.fp_rect = lr
			pl.h0 = e["h"] + e["height"] - 0.3
			pl.h1 = e["h"] + e["height"]
			_box(pl, lr, pl.h0, pl.h1, Look.col("porte"))
		"post":
			var pc := _new_piece(e)
			var c: Vector2 = e["c"]
			pc.fp_circle = Vector3(c.x, c.y, e["r"])
			pc.fp_rect = Rect2(c - Vector2.ONE * e["r"], Vector2.ONE * e["r"] * 2)
			pc.h0 = e["h"]
			pc.h1 = e["h"] + e["height"]
			_cylinder(pc, c, e["r"], pc.h0, pc.h1, Look.col(e["role"]))
		"tree":
			var pc := _new_piece(e)
			var c: Vector2 = e["c"]
			pc.fp_circle = Vector3(c.x, c.y, e["r"])
			pc.fp_rect = Rect2(c - Vector2.ONE * e["r"], Vector2.ONE * e["r"] * 2)
			pc.h0 = e["h"]
			pc.h1 = e["h"] + e["foliage_h"] + e["foliage_r"]
			pc.fadeable = true
			_cylinder(pc, c, e["r"], e["h"], e["h"] + e["trunk_h"] + 0.5, Look.col("arbre_tronc"), 0.7)
			# feuillage : ellipsoïde (rayon R, hauteur 1,8 R) -> ellipse à l'écran, ombrée en deux tons
			var fc := P(c.x, c.y, e["h"] + e["foliage_h"])
			var rr: float = e["foliage_r"] * World25.PPM
			var ry: float = e["foliage_r"] * World25.PPM * sqrt(pow(0.9 * cos(World25.PITCH), 2) + pow(sin(World25.PITCH), 2))
			pc.add(_ellipse(fc, rr, ry), Look.shade(Look.col("arbre"), Vector3(0, 0.6, 0.8)))
			pc.add(_ellipse(fc + Vector2(-rr * 0.18, -ry * 0.2), rr * 0.72, ry * 0.7), Look.shade(Look.col("arbre"), Vector3(-0.4, 1.0, 0.1)))
		"house":
			var pc := _new_piece(e)
			var r: Rect2 = e["rect"]
			pc.fp_rect = r
			pc.h0 = e["h0"]
			pc.h1 = e["h1"] + e["roof"]
			pc.fadeable = true
			_box(pc, r, e["h0"], e["h1"], Look.col("maison"))
			var dx := r.get_center().x + 0.6
			pc.add(PackedVector2Array([P(dx - 0.5, r.end.y, e["h0"]), P(dx + 0.5, r.end.y, e["h0"]), P(dx + 0.5, r.end.y, e["h0"] + 2.0), P(dx - 0.5, r.end.y, e["h0"] + 2.0)]),
				Look.shade(Look.col("porte"), Vector3(0, 0, 1)))
			# toit à deux pans, faîtage selon x, débord de 0,3 m
			var o := 0.3
			var x0 := r.position.x - o
			var x1 := r.end.x + o
			var y0 := r.position.y - o
			var y1 := r.end.y + o
			var hr: float = e["h1"] + e["roof"]
			var ym := r.get_center().y
			var rc := Look.col("maison_toit")
			var ns := Vector3(0, r.size.y / 2.0 + o, e["roof"]).normalized()     # pan sud : monte vers le nord
			pc.add(PackedVector2Array([P(x0, ym, hr), P(x1, ym, hr), P(x1, y1, e["h1"]), P(x0, y1, e["h1"])]), Look.shade(rc, ns))
			pc.add(PackedVector2Array([P(x0, y0, e["h1"]), P(x0, ym, hr), P(x0, y1, e["h1"])]), Look.shade(Look.col("maison"), Vector3(-1, 0, 0)))


func _cylinder(pc: Piece, c: Vector2, r: float, h0: float, h1: float, col: Color, top_k := 1.0) -> void:
	var n := 12
	var sides: Array = []
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var nm := Vector3(cos((a0 + a1) / 2), 0, sin((a0 + a1) / 2))
		if nm.dot(World25.cam_back()) <= 0:
			continue
		var q0 := c + Vector2(cos(a0), sin(a0)) * r
		var q1 := c + Vector2(cos(a1), sin(a1)) * r
		var q0t := c + Vector2(cos(a0), sin(a0)) * r * top_k
		var q1t := c + Vector2(cos(a1), sin(a1)) * r * top_k
		sides.append({"pts": PackedVector2Array([P(q0.x, q0.y, h0), P(q1.x, q1.y, h0), P(q1t.x, q1t.y, h1), P(q0t.x, q0t.y, h1)]), "n": nm})
	for sd in sides:
		pc.add(sd["pts"], Look.shade(col, sd["n"]))
	var top := PackedVector2Array()
	for i in n:
		var q := c + Vector2.from_angle(TAU * i / n) * r * top_k
		top.append(P(q.x, q.y, h1))
	pc.add(top, Look.shade(col, Vector3.UP))


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# ------------------------------------------------------------------------------------------------ tri
## Rayon dans le plan depuis p (vers la caméra si toward) : touche-t-il l'emprise de l'élément ?
static func _ray_hits(pc: Piece, p: Vector2, toward: bool, reach := 40.0) -> bool:
	var dir := World25.toward_cam() * (1.0 if toward else -1.0)
	var q := p + dir * reach
	if pc.fp_circle.z > 0.0:
		return Geometry2D.segment_intersects_circle(p, q, Vector2(pc.fp_circle.x, pc.fp_circle.y), pc.fp_circle.z) >= 0.0
	var r := pc.fp_rect
	if r.has_point(p):
		return false
	var c := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(p, q, c[i], c[(i + 1) % 4]) != null:
			return true
	return false


## Relation d'un point (x, y, h) avec un élément : +1 devant, −1 derrière, 0 indéterminé.
static func relation(pc: Piece, p: Vector2, h: float) -> int:
	if h >= pc.h1 - 0.05:
		return 1                                       # debout sur l'élément ou au-dessus
	if _ray_hits(pc, p, true):
		return -1                                      # l'élément est entre la caméra et le point
	if _ray_hits(pc, p, false):
		return 1
	return 0


func _samples(pc: Piece) -> Array:
	if pc.fp_circle.z > 0.0:
		return [Vector2(pc.fp_circle.x, pc.fp_circle.y)]
	var r := pc.fp_rect
	return [r.get_center(), r.position + Vector2(0.01, 0.01), Vector2(r.end.x - 0.01, r.position.y + 0.01), r.end - Vector2(0.01, 0.01), Vector2(r.position.x + 0.01, r.end.y - 0.01)]


## Ordre statique des éléments : tri topologique (relations par emprise et altitude), égalités par profondeur.
func _order_pieces() -> void:
	for pc in pieces:
		var c: Vector2 = pc.fp_rect.get_center() if pc.fp_circle.z <= 0 else Vector2(pc.fp_circle.x, pc.fp_circle.y)
		pc.d_center = World25.depth(c.x, c.y)
	var n := pieces.size()
	var after := []                                    # after[i] = éléments à dessiner après i
	var indeg := []
	for i in n:
		after.append([])
		indeg.append(0)
	for i in n:
		for j in range(i + 1, n):
			var a: Piece = pieces[i]
			var b: Piece = pieces[j]
			if not a.aabb.intersects(b.aabb):
				continue
			var rel := _piece_rel(a, b)
			if rel > 0:
				after[j].append(i)
				indeg[i] += 1
			elif rel < 0:
				after[i].append(j)
				indeg[j] += 1
	var ready: Array = []
	for i in n:
		if indeg[i] == 0:
			ready.append(i)
	var out: Array = []
	while out.size() < n:
		if ready.is_empty():
			# cycle : on le casse par la profondeur (signalé)
			var best := -1
			for i in n:
				if not out.has(i) and (best < 0 or pieces[i].d_center < pieces[best].d_center):
					best = i
			ready.append(best)
			indeg[best] = 0
			sort_conflicts += 1
		ready.sort_custom(func(x, y): return pieces[x].d_center < pieces[y].d_center)
		var k: int = ready.pop_front()
		if out.has(k):
			continue
		out.append(k)
		for j in after[k]:
			indeg[j] -= 1
			if indeg[j] == 0:
				ready.append(j)
	var sorted: Array = []
	for i in out.size():
		var pc: Piece = pieces[out[i]]
		pc.z_index = i * 10
		sorted.append(pc)
	pieces = sorted


## +1 si a doit être dessiné devant b, −1 derrière, 0 si indifférent.
func _piece_rel(a: Piece, b: Piece) -> int:
	if a.h0 >= b.h1 - 0.05 and a.fp_rect.intersects(b.fp_rect):
		return 1
	if b.h0 >= a.h1 - 0.05 and a.fp_rect.intersects(b.fp_rect):
		return -1
	var votes := 0
	for p in _samples(a):
		var r := relation(b, p, a.h0)
		votes += r
	if votes > 0:
		return 1
	if votes < 0:
		return -1
	return 1 if a.d_center > b.d_center else -1


## Z d'un personnage : juste devant le dernier élément qu'il précède, sans dépasser le premier qui le cache.
func actor_z(p: Vector3, rect: Rect2) -> int:
	var front := -10
	var behind := 1 << 20
	var fid := ""
	var bid := ""
	for pc in pieces:
		if not pc.aabb.intersects(rect):
			continue
		var r := relation(pc, Vector2(p.x, p.y), p.z)
		if r == 0:
			r = 1 if World25.depth(p.x, p.y) > pc.d_center else -1
		if r > 0:
			if pc.z_index > front:
				fid = pc.id
			front = maxi(front, pc.z_index)
		else:
			if pc.z_index < behind:
				bid = pc.id
			behind = mini(behind, pc.z_index)
	if front >= behind:
		sort_conflicts += 1
		var key := "%s devant %s / derrière %s" % ["", fid, bid]
		conflict_pairs[key] = conflict_pairs.get(key, 0) + 1
		return front + 1 + int(clampf(World25.depth(p.x, p.y), 0, 40) / 5.0)
	return front + 1 + int(clampf(World25.depth(p.x, p.y), 0, 40) / 5.0)


# ------------------------------------------------------------------------------------------------ personnages
func _make_actor(name: String, key: String) -> Dictionary:
	var a = Actor25.make(key)
	var node := Node2D.new()
	node.name = name
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = a.frames
	spr.centered = false
	node.add_child(spr)
	var ghost := AnimatedSprite2D.new()
	ghost.sprite_frames = a.frames
	ghost.centered = false
	ghost.z_as_relative = false
	ghost.z_index = 3900
	var sh := Shader.new()
	sh.code = "shader_type canvas_item; void fragment(){ vec4 c = texture(TEXTURE, UV); COLOR = vec4(0.62, 0.74, 1.0, step(0.5, c.a) * 0.55); }"
	var sm := ShaderMaterial.new()
	sm.shader = sh
	ghost.material = sm
	ghost.visible = false
	node.add_child(ghost)
	var blob := Blob.new()
	shadows.add_child(blob)
	var d := {"actor": a, "node": node, "spr": spr, "ghost": ghost, "blob": blob, "p": Vector3.ZERO}
	actors[name] = d
	return d


class Blob extends Node2D:
	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 20:
			var a := TAU * i / 20.0
			pts.append(Vector2(cos(a) * 9.0, sin(a) * 4.0))
		draw_colored_polygon(pts, Color(0, 0, 0, 0.32))


func _spawn_actors() -> void:
	_make_actor("aren", "aren")
	_make_actor("ilya", "ilya")


func _sync(d: Dictionary) -> void:
	var a = d["actor"]
	var p: Vector3 = d["p"]
	var node: Node2D = d["node"]
	node.position = World25.screen(p)
	for spr in [d["spr"], d["ghost"]]:
		if spr.animation != a.anim:
			spr.animation = a.anim
		spr.frame = a.frame
		spr.flip_h = a.flip
		var tex: Texture2D = a.texture()
		spr.offset = Vector2(-int(tex.get_width() / 2), -tex.get_height())
	(d["blob"] as Node2D).position = node.position
	var rect := Rect2(node.position + Vector2(-9, -30), Vector2(18, 30))
	node.z_index = actor_z(p, rect)


func teleport(p: Vector3, comp: Vector3) -> void:
	actors["aren"]["p"] = p
	actors["ilya"]["p"] = comp


func respawn() -> void:
	s.warp_to(world.spawn)


func step_hero(dir: Vector2, delta: float) -> Dictionary:
	var hp: Vector3 = actors["aren"]["p"]
	var r: Dictionary = world.move(Vector2(hp.x, hp.y), hp.z, dir * world.speed * delta)
	var np := Vector3(r["p"].x, r["p"].y, r["h"])
	actors["aren"]["p"] = np
	return {"p": np, "id": r["id"], "blocked": r["blocked"] and dir != Vector2.ZERO}


func animate(hm: float, hdir: Vector2, cm: float, cdir: Vector2, delta: float) -> void:
	actors["aren"]["actor"].step(hm, hdir, delta)
	actors["ilya"]["actor"].step(cm, cdir, delta)
	actors["ilya"]["p"] = s.companion
	for k in actors:
		_sync(actors[k])


func apply_camera(center: Vector2, zoom: float) -> void:
	cam2d.position = center
	cam2d.zoom = Vector2(zoom, zoom)


## Le héros est-il caché ? Recouvrement (aire) de la partie haute de son sprite par un élément dessiné après lui.
func hero_occluded() -> bool:
	var d: Dictionary = actors["aren"]
	var node: Node2D = d["node"]
	var rect := PackedVector2Array([node.position + Vector2(-7, -29), node.position + Vector2(7, -29), node.position + Vector2(7, -9), node.position + Vector2(-7, -9)])
	var area := 14.0 * 20.0
	var hidden := 0.0
	var occ: Array = []
	for pc in pieces:
		if pc.z_index <= node.z_index or not pc.aabb.intersects(Rect2(rect[0], Vector2(14, 20))):
			continue
		var hit := false
		for p in pc.polys:
			for part in Geometry2D.intersect_polygons(rect, p["pts"]):
				hidden += _area(part)
				hit = true
		if hit:
			occ.append(pc)
	_occluded = hidden > area * 0.15
	(d["ghost"] as AnimatedSprite2D).visible = _occluded and s.options["occlusion"] >= 1
	for pc in pieces:
		var want: bool = s.options["occlusion"] == 2 and _occluded and occ.has(pc) and pc.fadeable
		pc.modulate.a = 0.42 if want else 1.0
	return _occluded


static func _area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in p.size():
		a += p[i].cross(p[(i + 1) % p.size()])
	return absf(a) / 2.0


func apply_options() -> void:
	if s == null:
		return
	var o: Dictionary = s.options
	if overlay != null:
		overlay.show_layers = o["layers"]
		overlay.show_labels = o["layers"] or o["debug"]
		overlay.queue_redraw()
	if floors != null:
		floors.anim = o["anim"]
		for pc in [floors] + pieces:
			for i in pc.lines.size():
				pc.lines[i]["col"] = Color(0, 0, 0, 0.12 if o["grid"] else 0.0)
			pc.queue_redraw()
	for k in actors:
		var d: Dictionary = actors[k]
		(d["spr"] as AnimatedSprite2D).texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if o["filter_linear"] else CanvasItem.TEXTURE_FILTER_NEAREST
		(d["ghost"] as AnimatedSprite2D).texture_filter = (d["spr"] as AnimatedSprite2D).texture_filter


# ------------------------------------------------------------------------------------------------ boucle
func _unhandled_input(e: InputEvent) -> void:
	if not _switching:
		s.handle_input(e)


func _process(delta: float) -> void:
	if _switching or world == null:
		return
	s.process(delta)
	if actors.has("pnj"):
		_sync(actors["pnj"])
	var cs: Vector2 = s.cam.render_center() * s.cam.zoom
	var hs: Vector2 = World25.screen(s.hero) * s.cam.zoom - cs
	if s._skip_measure > 0:
		_rend_prev = Vector2.INF
	_render_measure(cs, hs, delta)
	if not s.pending_instance.is_empty():
		_switch(s.pending_instance)
	if _quit_when_done and s.pilot_done:
		_finish()


func _render_measure(cs: Vector2, hs: Vector2, delta: float) -> void:
	if delta <= 0.0:
		return
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
	s.toast("Instance : " + to.get_file(), 1.5)
	_switching = false
	s.fade_to(0.0, 0.25)


func capture(id: String) -> void:
	var out: String = _cli.get("out", "user://p3_captures")
	DirAccess.make_dir_recursive_absolute(out)
	var img := get_viewport().get_texture().get_image()
	img.save_png(out.path_join("A_%s.png" % id))


func _finish() -> void:
	_quit_when_done = false
	var out: String = _cli.get("out", "user://p3_captures")
	DirAccess.make_dir_recursive_absolute(out)
	var f := FileAccess.open(out.path_join("A_%s_mesures.json" % s.pilot_name), FileAccess.WRITE)
	var sm: Dictionary = s.summary()
	sm["renderer"] = RenderingServer.get_current_rendering_method()
	sm["fps_cap"] = Engine.max_fps
	sm["sort_conflicts"] = sort_conflicts
	sm["sort_conflict_pairs"] = conflict_pairs
	sm["pieces"] = pieces.size()
	f.store_string(JSON.stringify(sm, "  "))
	f.close()
	print("P3 MESURES A ", JSON.stringify(sm))
	get_tree().quit()
