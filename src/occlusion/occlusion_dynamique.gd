extends RefCounted
## P4.9 — Occlusion dynamique réutilisable : garde les personnages lisibles derrière le décor.
##
## Détection : chaque obstacle est approché par quelques sphères calculées sur ses vrais triangles (mises en cache par
## maillage). Pour chaque personnage, des rayons partent de la caméra vers 6 points de son sprite (pieds, flancs,
## buste, tête). Un obstacle n'est retenu que s'il coupe au moins 2 de ces rayons, ou celui du buste ou de la tête :
## être proche ne suffit pas.
##
## Effet :
##  - feuillage et buissons (matériau à découpe alpha, sans carte de normales) : l'obstacle s'efface par une trame
##    (Bayer 4×4) jusqu'à `opacite_min`, en `duree_fondu` secondes, à l'aller comme au retour ;
##  - troncs et rochers (matériau opaque, ou écorce à carte de normales) : pas de transparence, mais une silhouette
##    discrète du personnage, dessinée seulement là où il est caché.
##
## Sans toucher aux originaux : l'obstacle effacé est affiché par une COPIE temporaire, avec ses propres matériaux.
## L'original ne garde que son ombre portée et ses collisions ne changent jamais. Dans un MultiMeshInstance3D, seule
## l'instance concernée est remplacée (sa transformation est mise à zéro, puis restaurée), pas tout le groupe.
## Repli : `mode = "alpha"` (transparence alpha de Godot sur la copie, au lieu de la trame).
##
## Emploi :
##   var occ = preload("res://src/occlusion/occlusion_dynamique.gd").new()
##   occ.setup(scene_root, camera)
##   occ.ajouter_noeud(arbre)                 # nœud contenant des MeshInstance3D
##   occ.ajouter_multimesh(lot_de_buissons)   # chaque instance devient un obstacle
##   occ.ajouter_personnage(corps, sprite, 1.26, 0.5)
##   occ.update(delta)                        # à chaque image

const FONDU_SH := preload("res://src/occlusion/fondu_trame.gdshader")
const SIL_SH := preload("res://src/occlusion/silhouette.gdshader")
const HAUTEUR_MIN := 0.55                   # m : obstacles plus bas ignorés (herbes, fleurs, cailloux)
const MAINTIEN := 0.3                       # s : un obstacle reste atténué ce temps après la dernière détection
const POINTS := [[0.12, 0.0], [0.42, -0.42], [0.42, 0.42], [0.55, 0.0], [0.75, 0.0], [0.92, 0.0]]
const BUSTE_TETE := [3, 4, 5]               # indices de POINTS qui suffisent seuls

var enabled := true:
	set(v):
		enabled = v
		if not v:
			_tout_restaurer()
var mode := "trame"                         # "trame" (Bayer) ou "alpha" (repli)
var opacite_min := 0.4
var duree_fondu := 0.2
var silhouette_alpha := 0.5

var _root: Node3D
var _cam: Camera3D
var _calque: Node3D
var _obstacles: Array = []                  # Dictionary : aabb, spheres, kinds, op, hold, actif, ...
var _persos: Array = []                     # Dictionary : body, sprite, h, w, ghost, mat, a
var _cache_spheres := {}                    # mesh RID -> [[centre, rayon, massif?], ...]
var _cache_mats := {}                       # matériau source -> ShaderMaterial tramé


func setup(root: Node3D, cam: Camera3D) -> void:
	_root = root
	_cam = cam
	_calque = Node3D.new()
	_calque.name = "Occlusion_copies_temporaires"
	root.add_child(_calque)


func set_camera(cam: Camera3D) -> void:
	_cam = cam


# --------------------------------------------------------------------------------------------- enregistrement
func ajouter_noeud(node: Node3D) -> void:
	var parts: Array = []
	var spheres: Array = []
	var aabb := AABB()
	var first := true
	for mi in _meshes(node):
		var xf: Transform3D = mi.global_transform
		parts.append(mi)
		for s in _spheres_de(mi.mesh, func(i): return mi.get_active_material(i)):
			spheres.append([xf * (s[0] as Vector3), float(s[1]) * _echelle(xf.basis), s[2]])
		var b: AABB = xf * mi.get_aabb()
		aabb = b if first else aabb.merge(b)
		first = false
	if parts.is_empty() or aabb.size.y < HAUTEUR_MIN:
		return
	_obstacles.append({"node": node, "parts": parts, "aabb": aabb, "spheres": spheres, "op": 1.0, "hold": 0.0, "actif": false,
		"c": aabb.get_center(), "r": aabb.size.length() * 0.5})


func ajouter_multimesh(mmi: MultiMeshInstance3D) -> void:
	var mm := mmi.multimesh
	if mm == null or mm.mesh == null:
		return
	var local := _spheres_de(mm.mesh, func(i): return mmi.material_override if mmi.material_override != null else mm.mesh.surface_get_material(i))
	for i in mm.instance_count:
		var xf: Transform3D = mmi.global_transform * mm.get_instance_transform(i)
		var aabb: AABB = xf * mm.mesh.get_aabb()
		if aabb.size.y < HAUTEUR_MIN:
			continue
		var spheres: Array = []
		for s in local:
			spheres.append([xf * (s[0] as Vector3), float(s[1]) * _echelle(xf.basis), s[2]])
		_obstacles.append({"mmi": mmi, "index": i, "aabb": aabb, "spheres": spheres, "op": 1.0, "hold": 0.0, "actif": false,
			"c": aabb.get_center(), "r": aabb.size.length() * 0.5})


func ajouter_personnage(body: Node3D, sprite: Sprite3D, hauteur: float, largeur: float) -> void:
	var ghost := Sprite3D.new()
	ghost.name = "Silhouette_occlusion"
	ghost.centered = sprite.centered
	ghost.pixel_size = sprite.pixel_size
	ghost.position = sprite.position
	ghost.texture = sprite.texture
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = SIL_SH
	ghost.material_override = mat
	sprite.get_parent().add_child(ghost)
	_persos.append({"body": body, "sprite": sprite, "h": hauteur, "w": largeur, "ghost": ghost, "mat": mat, "a": 0.0, "hold": 0.0})


func nombre_attenues() -> int:
	var n := 0
	for o in _obstacles:
		if o["actif"]:
			n += 1
	return n


func nombre_obstacles() -> int:
	return _obstacles.size()


func silhouettes_actives() -> int:
	var n := 0
	for p in _persos:
		if p["a"] > 0.01:
			n += 1
	return n


# --------------------------------------------------------------------------------------------- mise à jour
func update(delta: float) -> void:
	for p in _persos:
		(p["mat"] as ShaderMaterial).set_shader_parameter("tex", (p["sprite"] as Sprite3D).texture)
	if not enabled or _cam == null:
		return
	var cam_pos := _cam.global_position
	var up := _cam.global_transform.basis.y
	var right := _cam.global_transform.basis.x
	var gene := {}                           # index obstacle -> true (à effacer)
	for p in _persos:
		var body: Node3D = p["body"]
		var foot := body.global_position
		var hits := {}                       # index obstacle -> [nb points, buste/tête ?, feuillage ?]
		# tri grossier, une fois par personnage : seuls les obstacles proches du segment caméra -> personnage, et
		# situés entre les deux, passent aux rayons (≈ 10 sur 500 ; détail fin ensuite)
		var mid: Vector3 = foot + up * (p["h"] * 0.5)
		var seg := mid - cam_pos
		var seg_len2 := seg.length_squared()
		var cand: Array = []
		for oi in _obstacles.size():
			var o: Dictionary = _obstacles[oi]
			var oc: Vector3 = o["c"]
			var orad: float = o["r"]
			var t: float = (oc - cam_pos).dot(seg) / seg_len2
			if t <= 0.0 or t >= 1.0 + orad / sqrt(seg_len2):
				continue
			if (cam_pos + seg * minf(t, 1.0)).distance_to(oc) <= orad + float(p["h"]) * 0.6:
				cand.append(oi)
		for k in POINTS.size():
			var target: Vector3 = foot + up * (p["h"] * POINTS[k][0]) + right * (p["w"] * 0.5 * POINTS[k][1])
			for oi in cand:
				var o: Dictionary = _obstacles[oi]
				var r := _coupe(o, cam_pos, target)
				if r == 0:
					continue
				var hcur: Array = hits.get(oi, [0, false, false])
				hcur[0] += 1
				hcur[1] = hcur[1] or k in BUSTE_TETE
				hcur[2] = hcur[2] or r == 2
				hits[oi] = hcur
		var masque_massif := false
		for oi in hits:
			var hh: Array = hits[oi]
			if hh[0] >= 2 or hh[1]:
				if hh[2]:
					gene[oi] = true
				else:
					masque_massif = true
		p["hold"] = MAINTIEN if masque_massif else maxf(0.0, p["hold"] - delta)
		var a_cible := silhouette_alpha if p["hold"] > 0.0 else 0.0
		p["a"] = move_toward(p["a"], a_cible, silhouette_alpha * delta / duree_fondu)
		(p["mat"] as ShaderMaterial).set_shader_parameter("alpha", p["a"])
	var pas := (1.0 - opacite_min) * delta / duree_fondu
	for oi in _obstacles.size():
		var o: Dictionary = _obstacles[oi]
		if gene.has(oi):
			o["hold"] = MAINTIEN
		else:
			o["hold"] = maxf(0.0, o["hold"] - delta)
		var cible := opacite_min if o["hold"] > 0.0 else 1.0
		if o["op"] == cible and not (o["actif"] and cible == 1.0):
			continue
		o["op"] = move_toward(o["op"], cible, pas)
		if o["op"] < 1.0 and not o["actif"]:
			_activer(o)
		if o["actif"]:
			if o["op"] >= 1.0:
				_restaurer(o)
			else:
				_appliquer(o)


## 0 : ne coupe pas ; 1 : coupe une partie massive (tronc, rocher) ; 2 : coupe du feuillage (prioritaire)
func _coupe(o: Dictionary, a: Vector3, b: Vector3) -> int:
	if o.has("node") and not (o["node"] as Node3D).is_visible_in_tree():
		return 0
	if o.has("mmi") and not (o["mmi"] as Node3D).is_visible_in_tree():
		return 0
	var d := b - a
	if not _segment_aabb(a, d, o["aabb"]):
		return 0
	var res := 0
	var len2 := d.length_squared()
	for s in o["spheres"]:
		var c: Vector3 = s[0]
		var r: float = s[1]
		var t := clampf((c - a).dot(d) / len2, 0.0, 0.985)    # le point de la cible lui-même est exclu
		if (a + d * t).distance_squared_to(c) <= r * r:
			if not s[2]:
				return 2
			res = 1
	return res


func _segment_aabb(a: Vector3, d: Vector3, box: AABB) -> bool:
	var t0 := 0.0
	var t1 := 1.0
	for i in 3:
		var lo := box.position[i]
		var hi := box.end[i]
		if absf(d[i]) < 1e-6:
			if a[i] < lo or a[i] > hi:
				return false
		else:
			var u := (lo - a[i]) / d[i]
			var v := (hi - a[i]) / d[i]
			t0 = maxf(t0, minf(u, v))
			t1 = minf(t1, maxf(u, v))
			if t0 > t1:
				return false
	return true


# --------------------------------------------------------------------------------------------- effet
func _activer(o: Dictionary) -> void:
	var copies: Array = []
	if o.has("node"):
		o["ombres"] = []
		for mi in o["parts"]:
			var m: MeshInstance3D = mi
			copies.append(_copie(m.mesh, m.global_transform, func(i): return m.get_active_material(i)))
			o["ombres"].append(m.cast_shadow)
			# l'original reste pour l'ombre portée seulement (et ses collisions ne changent pas)
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if m.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if m.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				m.visible = false
	else:
		var mmi: MultiMeshInstance3D = o["mmi"]
		var mm := mmi.multimesh
		var i: int = o["index"]
		o["xf"] = mm.get_instance_transform(i)
		copies.append(_copie(mm.mesh, mmi.global_transform * o["xf"], func(_s): return mmi.material_override if mmi.material_override != null else mm.mesh.surface_get_material(_s)))
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), (o["xf"] as Transform3D).origin))
	o["copies"] = copies
	o["actif"] = true
	_appliquer(o)


func _appliquer(o: Dictionary) -> void:
	for c in o["copies"]:
		var g: MeshInstance3D = c
		if mode == "trame":
			g.set_instance_shader_parameter("opacite", o["op"])
		else:
			g.transparency = 1.0 - o["op"]


func _restaurer(o: Dictionary) -> void:
	if not o["actif"]:
		return
	for c in o["copies"]:
		(c as Node).queue_free()
	o["copies"] = []
	if o.has("node"):
		for j in o["parts"].size():
			var m: MeshInstance3D = o["parts"][j]
			m.cast_shadow = o["ombres"][j]
			m.visible = true
	else:
		(o["mmi"] as MultiMeshInstance3D).multimesh.set_instance_transform(o["index"], o["xf"])
	o["actif"] = false
	o["op"] = 1.0


func _tout_restaurer() -> void:
	for o in _obstacles:
		_restaurer(o)
		o["hold"] = 0.0
	for p in _persos:
		p["a"] = 0.0
		p["hold"] = 0.0
		(p["mat"] as ShaderMaterial).set_shader_parameter("alpha", 0.0)


func _copie(mesh: Mesh, xf: Transform3D, mat_de: Callable) -> MeshInstance3D:
	var g := MeshInstance3D.new()
	g.mesh = mesh
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for s in mesh.get_surface_count():
		var src: Material = mat_de.call(s)
		g.set_surface_override_material(s, _mat_trame(src) if mode == "trame" else src)
	_calque.add_child(g)
	g.global_transform = xf
	return g


## Matériau tramé équivalent au matériau source (mis en cache : une seule copie par matériau source ; l'opacité est
## un paramètre d'instance, donc chaque obstacle s'efface indépendamment). Le matériau source n'est jamais modifié.
func _mat_trame(src: Material) -> Material:
	if _cache_mats.has(src):
		return _cache_mats[src]
	var m := ShaderMaterial.new()
	m.shader = FONDU_SH
	if src is BaseMaterial3D:
		var b := src as BaseMaterial3D
		m.set_shader_parameter("albedo_color", b.albedo_color)
		m.set_shader_parameter("use_tex", b.albedo_texture != null)
		if b.albedo_texture != null:
			m.set_shader_parameter("albedo_tex", b.albedo_texture)
		m.set_shader_parameter("use_vcol", b.vertex_color_use_as_albedo)
		m.set_shader_parameter("use_normal", b.normal_enabled and b.normal_texture != null)
		if b.normal_texture != null:
			m.set_shader_parameter("normal_tex", b.normal_texture)
		m.set_shader_parameter("normal_scale", b.normal_scale)
		m.set_shader_parameter("roughness", b.roughness)
		m.set_shader_parameter("metallic", b.metallic)
		m.set_shader_parameter("specular", b.metallic_specular)
		m.set_shader_parameter("use_scissor", b.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR)
		m.set_shader_parameter("scissor", b.alpha_scissor_threshold)
	_cache_mats[src] = m
	return m


# --------------------------------------------------------------------------------------------- géométrie
func _meshes(node: Node) -> Array:
	var out: Array = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out.append(node)
	for c in node.get_children():
		out.append_array(_meshes(c))
	return out


func _echelle(b: Basis) -> float:
	return maxf(b.x.length(), maxf(b.y.length(), b.z.length()))


## Sphères englobant les triangles d'un maillage, par cellules d'une grille (≈ 7 cellules sur la plus grande
## dimension). Chaque sphère retient si sa surface est « massive » (opaque, ou écorce à carte de normales) ou du
## feuillage (découpe alpha sans carte de normales).
func _spheres_de(mesh: Mesh, mat_de: Callable) -> Array:
	var key := mesh.get_rid()
	if _cache_spheres.has(key):
		return _cache_spheres[key]
	var box := mesh.get_aabb()
	var cell := maxf(box.get_longest_axis_size() / 7.0, 0.2)
	var out: Array = []
	for s in mesh.get_surface_count():
		var mat: Material = mat_de.call(s)
		var massif := true
		if mat is BaseMaterial3D:
			var b := mat as BaseMaterial3D
			massif = b.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED or b.normal_enabled
		var arr := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var pts := PackedVector3Array(verts)
		for t in range(0, idx.size() - 2, 3):              # centres des triangles : couvre l'intérieur des feuilles
			pts.append((verts[idx[t]] + verts[idx[t + 1]] + verts[idx[t + 2]]) / 3.0)
		var cells := {}
		for v in pts:
			var k := Vector3i(floori(v.x / cell), floori(v.y / cell), floori(v.z / cell))
			if not cells.has(k):
				cells[k] = []
			cells[k].append(v)
		for k in cells:
			var vs: Array = cells[k]
			var c := Vector3.ZERO
			for v in vs:
				c += v
			c /= vs.size()
			var r := 0.0
			for v in vs:
				r = maxf(r, c.distance_to(v))
			out.append([c, minf(r, cell * 0.9) + 0.02, massif])
	_cache_spheres[key] = out
	return out
