extends RefCounted
## P3-07 — PAYSAGE NON JOUABLE de blockout (doc 07 §04) autour d'une instance, pour juger la profondeur du cadrage.
## Données : data/explore25/paysage_p3_07.json (une entrée par fichier d'instance). Deux traitements à coût faible :
##   "3d" : relief en grille (couleurs par pente et altitude), quartiers en gradins, forêts, montagnes + brume de
##          profondeur (perspective atmosphérique) ;
##   "2d" : même relief proche, mais quartiers, forêts et montagnes remplacés par des PLANS 2D illustratifs (silhouettes
##          générées, teintées par la distance), posés dans le monde — pas un panorama collé à la caméra.
## Rien de ce qui est construit ici n'est praticable : aucune région de marche, aucun calque de collision du héros.
## Les volumes portent un calque dédié (L_FOND) servant uniquement aux MESURES (part de paysage visible à l'écran).

const World25 = preload("res://src/explore25/world25.gd")
const DATA := "res://data/explore25/paysage_p3_07.json"
const L_FOND := 64
const TRAITEMENTS := ["3d", "2d", "aucun"]

const C_HERBE := Color(0.36, 0.47, 0.31)
const C_HERBE2 := Color(0.43, 0.52, 0.33)
const C_TERRE := Color(0.56, 0.48, 0.37)
const C_ROCHE := Color(0.50, 0.48, 0.46)
const C_MUR := Color(0.78, 0.72, 0.62)
const C_MUR2 := Color(0.70, 0.66, 0.60)
const C_TOIT := [Color(0.58, 0.29, 0.22), Color(0.40, 0.42, 0.52), Color(0.52, 0.36, 0.26)]
const C_FEUILLE := [Color(0.19, 0.36, 0.21), Color(0.23, 0.41, 0.22), Color(0.17, 0.31, 0.24)]
const C_TRONC := Color(0.34, 0.24, 0.16)
const C_MONT := Color(0.52, 0.54, 0.60)
const C_NEIGE := Color(0.90, 0.92, 0.95)
const C_EAU := Color(0.24, 0.45, 0.62)

var cfg: Dictionary = {}
var world
var _rng := RandomNumberGenerator.new()
var _mats := {}
var stats := {"triangles": 0, "batiments": 0, "arbres": 0, "cartes": 0}


static func config_for(world_path: String) -> Dictionary:
	var all: Dictionary = JSON.parse_string(FileAccess.open(DATA, FileAccess.READ).get_as_text())
	return all["instances"].get(world_path.get_file(), {})


## Points (x, y, h) que le cadre doit pouvoir montrer (limites de caméra élargies vers le paysage).
static func view_points(c: Dictionary) -> Array:
	var out: Array = []
	for p in c.get("cadre", []):
		out.append(Vector3(p[0], p[1], p[2]))
	return out


func build(parent: Node3D, c: Dictionary, w, traitement: String) -> Node3D:
	cfg = c
	world = w
	var root := Node3D.new()
	root.name = "Paysage_" + traitement
	parent.add_child(root)
	if traitement == "aucun" or c.is_empty():
		return root
	_terrain(root)
	for l in c.get("lacs", []):
		_lac(root, l)
	if traitement == "3d":
		for q in c.get("quartiers", []):
			_quartier(root, q)
		for f in c.get("forets", []):
			_foret(root, f)
		for m in c.get("montagnes", []):
			_montagne(root, m)
	else:
		for k in c.get("cartes", []):
			_carte(root, k)
	return root


## Environnement : brume de profondeur (3d) — commence juste derrière le point jouable le plus éloigné de la caméra.
static func apply_fog(env: Environment, c: Dictionary, w, traitement: String) -> void:
	env.fog_enabled = traitement == "3d" and c.has("brume")
	if not env.fog_enabled:
		return
	var b: Dictionary = c["brume"]
	var far := -INF
	for reg in w.regions:
		var r: Rect2 = reg["rect"]
		for q in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			far = maxf(far, cam_depth(Vector3(q.x, q.y, w.region_h(reg, q))))
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = far + b["debut_apres_jeu_m"]
	env.fog_depth_end = env.fog_depth_begin + b["longueur_m"]
	env.fog_depth_curve = 1.0
	env.fog_density = b["densite"]
	var col: Array = b["couleur"]
	env.fog_light_color = Color(col[0], col[1], col[2])
	env.fog_light_energy = 1.0
	env.fog_sky_affect = 0.0


## Distance à la caméra (le long de la visée) d'un point (x, y, h) — la caméra est à 120 m dans le plan de l'écran.
static func cam_depth(p: Vector3) -> float:
	return 120.0 - World25.g3(p).dot(World25.cam_back())


# ------------------------------------------------------------------------------------------------ relief
func height(x: float, y: float) -> float:
	var t: Dictionary = cfg["terrain"]
	var h := 0.0
	var low := 0.0
	for r in t.get("reliefs", []):
		match r["type"]:
			"plateau":
				var q: Array = r["rect"]
				if x >= q[0] and x <= q[2] and y >= q[1] and y <= q[3]:
					h = maxf(h, r["h"])
			"colline":
				var d := Vector2(x - r["c"][0], y - r["c"][1]).length() / float(r["r"])
				if d < 1.0:
					h = maxf(h, r["h"] * (0.5 + 0.5 * cos(PI * d)) * (0.85 + 0.15 * sin(x * 0.7) * cos(y * 0.6)))
			"pente":
				var xr: Array = r["x"]
				if x >= xr[0] and x <= xr[1]:
					var v: float = y if r["axe"] == "y" else x
					var tt := clampf((v - r["de"]) / (r["a"] - r["de"]), 0.0, 1.0)
					low = minf(low, lerpf(r["h0"], r["h1"], smoothstep(0.0, 1.0, tt)))
	h = h + low if h <= 0.001 else h
	for cr in t.get("creux", []):
		var q: Array = cr["rect"]
		if x >= q[0] and x <= q[2] and y >= q[1] and y <= q[3]:
			h = minf(h, cr["h"])
	for ch in t.get("chemins", []):
		var q: Array = ch["rect"]
		if x >= q[0] and x <= q[2] and y >= q[1] and y <= q[3]:
			h = minf(h, 0.0) if h > 0.0 else h
	# protection de l'aire de jeu : le relief passe SOUS les sols praticables (jamais au-dessus d'un chemin)
	var pm: float = t.get("protection_m", 0.35)
	for reg in world.regions:
		if (reg["rect"] as Rect2).grow(pm).has_point(Vector2(x, y)):
			return minf(h, -0.03)                      # jamais au-dessus (ni le lit de la rivière sous le pont)
	return h


func _on_road(x: float, y: float) -> bool:
	for ch in cfg["terrain"].get("chemins", []):
		var q: Array = ch["rect"]
		if x >= q[0] and x <= q[2] and y >= q[1] and y <= q[3]:
			return true
	return false


func _terrain(root: Node3D) -> void:
	var t: Dictionary = cfg["terrain"]
	var q: Array = t["rect"]
	var step: float = t.get("pas_m", 1.0)
	var nx := int((q[2] - q[0]) / step) + 1
	var ny := int((q[3] - q[1]) / step) + 1
	var hs := PackedFloat32Array()
	hs.resize(nx * ny)
	for j in ny:
		for i in nx:
			hs[j * nx + i] = height(q[0] + i * step, q[1] + j * step)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in ny - 1:
		for i in nx - 1:
			var x0: float = q[0] + i * step
			var y0: float = q[1] + j * step
			var v := [Vector3(x0, hs[j * nx + i], y0), Vector3(x0 + step, hs[j * nx + i + 1], y0),
				Vector3(x0 + step, hs[(j + 1) * nx + i + 1], y0 + step), Vector3(x0, hs[(j + 1) * nx + i], y0 + step)]
			var hmax := maxf(maxf(v[0].y, v[1].y), maxf(v[2].y, v[3].y))
			var hmin := minf(minf(v[0].y, v[1].y), minf(v[2].y, v[3].y))
			var col: Color
			if hmax - hmin > step * 0.9:
				col = C_ROCHE                                  # talus, gradins, falaises
			elif _on_road(x0 + step / 2, y0 + step / 2):
				col = C_TERRE
			else:
				# variation à deux échelles (prés, parcelles) : pas de grande plaque uniforme
				var n := sin(x0 * 0.21 + y0 * 0.13) * cos(y0 * 0.17 - x0 * 0.05)
				var n2 := sin(x0 * 0.045 + 1.3) * cos(y0 * 0.05 - 0.7)
				col = C_HERBE.lerp(C_HERBE2, 0.5 + 0.5 * n)
				col = col.lerp(Color(0.52, 0.53, 0.32), clampf(n2 * 0.9, 0.0, 0.55))     # prés secs
				col = col.lerp(Color(0.28, 0.40, 0.27), clampf(-n2 * 0.9, 0.0, 0.5))     # herbe sombre
				if int(floor((x0 + 3.0 * sin(y0 * 0.05)) / 6.0)) % 2 == 0 and hmax < 2.0 and absf(n2) > 0.35:
					col = col.lerp(Color(0.60, 0.54, 0.36), 0.35)                       # parcelles cultivées
				col = col.lerp(C_ROCHE, clampf((hmax - 9.0) / 10.0, 0.0, 0.6))
				col = col.darkened(clampf(-hmax * 0.06, 0.0, 0.25))
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_color(col)
				st.add_vertex(v[k])
	st.generate_normals()
	var mesh := st.commit()
	_add(root, mesh, _vmat())
	var sb := StaticBody3D.new()
	sb.collision_layer = L_FOND
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	cs.shape = mesh.create_trimesh_shape()
	sb.add_child(cs)
	root.add_child(sb)


func _lac(root: Node3D, l: Dictionary) -> void:
	var q: Array = l["rect"]
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(q[2] - q[0], q[3] - q[1])
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = C_EAU
	m.roughness = 0.3
	mi.material_override = m
	mi.position = Vector3((q[0] + q[2]) / 2.0, l["h"], (q[1] + q[3]) / 2.0)
	root.add_child(mi)
	_fond_box(root, mi.position - Vector3(0, 0.05, 0), Vector3(q[2] - q[0], 0.1, q[3] - q[1]))


# ------------------------------------------------------------------------------------------------ volumes 3d
func _quartier(root: Node3D, q: Dictionary) -> void:
	_rng.seed = q["graine"]
	var r: Array = q["rect"]
	var rangs: int = q.get("rangs", 1)
	var depth: float = (r[3] - r[1]) / rangs
	for k in rangs:
		var y1: float = r[3] - depth * k
		var y0: float = y1 - depth
		var x: float = r[0]
		while x < r[2] - 1.5:
			var w := minf(_rng.randf_range(2.5, 5.0), r[2] - x)
			var d := _rng.randf_range(depth * 0.55, depth * 0.95)
			var hh := _rng.randf_range(q["haut"][0], q["haut"][1]) * (1.0 + 0.12 * k)
			_maison(root, Rect2(x + 0.15, y1 - d, w - 0.3, d), q["h0"], hh)
			x += w
	if q.has("tour"):
		var t: Array = q["tour"]
		_maison(root, Rect2(t[0] - t[2] / 2, t[1] - t[2] / 2, t[2], t[2]), q["h0"], t[3])


func _maison(root: Node3D, r: Rect2, h0: float, hh: float) -> void:
	var walls := C_MUR.lerp(C_MUR2, _rng.randf())
	var top := maxf(h0, height(r.get_center().x, r.get_center().y))
	_box(root, Vector3(r.get_center().x, top + hh / 2.0 - 0.5, r.get_center().y), Vector3(r.size.x, hh + 1.0, r.size.y), walls)
	var roof := MeshInstance3D.new()
	var pm := PrismMesh.new()
	var rh := minf(r.size.x, r.size.y) * 0.45
	if r.size.x >= r.size.y:
		pm.size = Vector3(r.size.y + 0.4, rh, r.size.x + 0.4)
		roof.transform = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(r.get_center().x, top + hh + rh / 2.0, r.get_center().y))
	else:
		pm.size = Vector3(r.size.x + 0.4, rh, r.size.y + 0.4)
		roof.position = Vector3(r.get_center().x, top + hh + rh / 2.0, r.get_center().y)
	roof.mesh = pm
	roof.material_override = _mat(C_TOIT[_rng.randi() % C_TOIT.size()])
	root.add_child(roof)
	# rangée de fenêtres sur la façade sud (lisibilité de l'échelle)
	var n := int(r.size.x / 1.4)
	for i in n:
		for f in int(hh / 2.6):
			_box(root, Vector3(r.position.x + 0.7 + i * 1.4, top + 1.3 + f * 2.6, r.end.y + 0.03), Vector3(0.5, 0.8, 0.04), Color(0.30, 0.30, 0.38))
	_fond_box(root, Vector3(r.get_center().x, top + (hh + rh) / 2.0, r.get_center().y), Vector3(r.size.x, hh + rh, r.size.y))
	stats["batiments"] += 1


func _foret(root: Node3D, f: Dictionary) -> void:
	_rng.seed = f["graine"]
	var r: Array = f["rect"]
	var area: float = (r[2] - r[0]) * (r[3] - r[1])
	var n := int(area * f["densite"])
	var trunks := MultiMesh.new()
	var crowns := MultiMesh.new()
	for mm in [trunks, crowns]:
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
	var cm := CylinderMesh.new()
	cm.top_radius = 0.12
	cm.bottom_radius = 0.18
	cm.height = 1.0
	cm.radial_segments = 6
	trunks.mesh = cm
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.0
	cone.height = 1.0
	cone.radial_segments = 8
	crowns.mesh = cone
	var pts: Array = []
	for i in n:
		var x := _rng.randf_range(r[0], r[2])
		var y := _rng.randf_range(r[1], r[3])
		var g := height(x, y)
		if _on_road(x, y) or g < -0.5 or _near_play(x, y, 1.5):
			continue
		pts.append([x, y, g, _rng.randf_range(f["taille"][0], f["taille"][1]), _rng.randi() % C_FEUILLE.size()])
	trunks.instance_count = pts.size()
	crowns.instance_count = pts.size()
	var sb := StaticBody3D.new()
	sb.collision_layer = L_FOND
	sb.collision_mask = 0
	root.add_child(sb)
	for i in pts.size():
		var p: Array = pts[i]
		var hgt: float = p[3]
		trunks.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(1, hgt * 0.35, 1)), Vector3(p[0], p[2] + hgt * 0.175, p[1])))
		trunks.set_instance_color(i, C_TRONC)
		var cr := hgt * 0.28
		crowns.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(cr, hgt * 0.8, cr)), Vector3(p[0], p[2] + hgt * 0.25 + hgt * 0.4, p[1])))
		crowns.set_instance_color(i, C_FEUILLE[p[4]])
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = cr * 0.8
		sh.height = hgt * 0.8
		cs.shape = sh
		cs.position = Vector3(p[0], p[2] + hgt * 0.65, p[1])
		sb.add_child(cs)
	for mm in [trunks, crowns]:
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = _vmat()
		root.add_child(mi)
	stats["arbres"] += pts.size()


func _montagne(root: Node3D, m: Dictionary) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = m["r"] * 0.08
	cm.bottom_radius = m["r"]
	cm.height = m["h"]
	cm.radial_segments = 7
	cm.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = _mat(C_MONT)
	mi.position = Vector3(m["c"][0], m["h"] / 2.0 - 2.0, m["c"][1])
	root.add_child(mi)
	var snow := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = m["r"] * 0.08
	sm.bottom_radius = m["r"] * 0.32
	sm.height = m["h"] * 0.26
	sm.radial_segments = 7
	snow.mesh = sm
	snow.material_override = _mat(C_NEIGE)
	snow.position = Vector3(m["c"][0], m["h"] - 2.0 - m["h"] * 0.13 + 0.05, m["c"][1])
	root.add_child(snow)
	var sb := StaticBody3D.new()
	sb.collision_layer = L_FOND
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	cs.shape = cm.create_convex_shape()
	sb.add_child(cs)
	sb.position = mi.position
	root.add_child(sb)


# ------------------------------------------------------------------------------------------------ plans 2d
## Plan vertical tourné vers la caméra (azimut seul), avec une silhouette générée ; teinte éclaircie avec la distance
## (perspective atmosphérique peinte, sans brume).
func _carte(root: Node3D, k: Dictionary) -> void:
	var a := Vector2(k["a"][0], k["a"][1])
	var b := Vector2(k["b"][0], k["b"][1])
	var mid := (a + b) / 2.0
	var right := Vector2(cos(World25.YAW), sin(World25.YAW))
	var width := absf((b - a).dot(right)) + 6.0
	var hh: float = k["haut"]
	var tex := _silhouette(k["type"], int(width * 8), int(hh * 8), k["graine"], k["teinte"])
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(width, hh)
	mi.mesh = qm
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.transform = Transform3D(Basis(Vector3.UP, -World25.YAW), Vector3(mid.x, k["h0"] + hh / 2.0, mid.y))
	root.add_child(mi)
	var sb := StaticBody3D.new()
	sb.collision_layer = L_FOND
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(width, hh * 0.7, 0.2)
	cs.shape = bs
	cs.position = Vector3(0, -hh * 0.15, 0)
	sb.add_child(cs)
	sb.transform = mi.transform
	root.add_child(sb)
	stats["cartes"] += 1


func _silhouette(kind: String, w: int, h: int, seed: int, tint: float) -> ImageTexture:
	_rng.seed = seed
	w = clampi(w, 64, 2048)
	h = clampi(h, 32, 512)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var haze := Color(0.66, 0.72, 0.82)
	var base: Color
	match kind:
		"ville":
			base = C_MUR2.lerp(haze, tint)
			var roof := C_TOIT[0].lerp(haze, tint)
			var x := 0
			while x < w:
				var bw := _rng.randi_range(14, 40)
				var bh := _rng.randi_range(int(h * 0.35), int(h * 0.85))
				var rh := int(bw * 0.45)
				for yy in range(h - bh, h):
					for xx in range(x, mini(x + bw - 2, w)):
						var win := (xx - x) % 9 in [3, 4, 5] and (yy - (h - bh)) % 14 in [4, 5, 6, 7, 8] and yy < h - 6
						img.set_pixel(xx, yy, (base.darkened(0.35) if win else base))
				for yy in range(maxi(0, h - bh - rh), h - bh):
					var half := int(float(yy - (h - bh - rh)) / rh * bw / 2.0)
					for xx in range(x + bw / 2 - half, x + bw / 2 + half):
						if xx >= 0 and xx < w:
							img.set_pixel(xx, yy, roof)
				x += bw
		"foret":
			base = C_FEUILLE[0].lerp(haze, tint)
			var x := 0
			while x < w:
				var tw := _rng.randi_range(10, 22)
				var th := _rng.randi_range(int(h * 0.5), h)
				for yy in range(h - th, h):
					var half := int(float(yy - (h - th)) / th * tw / 2.0)
					for xx in range(x + tw / 2 - half, x + tw / 2 + half):
						if xx >= 0 and xx < w:
							img.set_pixel(xx, yy, base.lightened(0.05 * ((xx + yy) % 3)))
				x += _rng.randi_range(5, 12)
			for yy in range(int(h * 0.8), h):
				for xx in w:
					img.set_pixel(xx, yy, base.darkened(0.1))
		_:
			base = C_MONT.lerp(haze, tint)
			var peaks := []
			for i in 6:
				peaks.append(Vector2(_rng.randf_range(0, w), _rng.randf_range(h * 0.05, h * 0.5)))
			for xx in w:
				var top := float(h)
				for p in peaks:
					top = minf(top, p.y + absf(xx - p.x) * 0.55)
				for yy in range(int(top), h):
					var snow: bool = yy < top + h * 0.08 and top < h * 0.4
					img.set_pixel(xx, yy, C_NEIGE.lerp(haze, tint * 0.6) if snow else base)
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------------------------------------ aides
func _near_play(x: float, y: float, m: float) -> bool:
	for reg in world.regions:
		if (reg["rect"] as Rect2).grow(m).has_point(Vector2(x, y)):
			return true
	return false


func _vmat() -> StandardMaterial3D:
	if not _mats.has("v"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true            # couleurs données en sRGB, comme le reste de la palette
		m.roughness = 1.0
		_mats["v"] = m
	return _mats["v"]


func _mat(c: Color) -> StandardMaterial3D:
	var k := c.to_html()
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 1.0
		_mats[k] = m
	return _mats[k]


func _add(root: Node3D, mesh: Mesh, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	root.add_child(mi)
	return mi


func _box(root: Node3D, c: Vector3, size: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(col)
	mi.position = c
	root.add_child(mi)


func _fond_box(root: Node3D, c: Vector3, size: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = L_FOND
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	sb.position = c
	root.add_child(sb)
