extends "res://scenes/p7/ville_blockout.gd"
## P7.3 — VILLE V0.6 : démonstration verticale (porte sud -> guilde -> montée -> grande place -> quartier haut).
## PROTOTYPE DE CADRAGE, NON VALIDÉ. Données : data/p7/ville_v06.json (tools/p7/build_ville_v06.py).
## Même principe que le blockout V0.1 (volumes provisoires, couleurs par fonction, collisions des DONNÉES), avec ce qui
## sert la profondeur demandée par le brief V0.6 :
##   * trois niveaux portés par des masses de terrain et des murs de soutènement face à la caméra ;
##   * toitures à deux pans (silhouettes lisibles de loin), gradins de toits de part et d'autre de l'axe (paysage sans
##     collision, hors d'atteinte), tours ;
##   * au loin, le quartier du château sur son rocher (décor seul, jamais construit), ciel et brume de distance.
## Rien de visible n'est traversable ; rien d'invisible ne bloque : le praticable est bordé de façades, de garde-corps
## ou de murs de soutènement.

const TOITS := [Color(0.62, 0.36, 0.28), Color(0.55, 0.33, 0.27), Color(0.40, 0.40, 0.45), Color(0.66, 0.42, 0.30)]
const SOLS_V06 := {"bas": Color(0.50, 0.47, 0.42), "median": Color(0.56, 0.53, 0.47), "haut": Color(0.60, 0.58, 0.53)}
const MUR_SOUT := Color(0.47, 0.45, 0.42)
const MARCHE := Color(0.66, 0.63, 0.58)
const PROCHE_M := 12.0           # m : la caméra est à ≈ 24 m d'Aren ; ce qui est à moins de 12 m d'elle s'estompe
const PIERRE_CHATEAU := Color(0.62, 0.63, 0.66)
var nv: Dictionary
var libelles := true


func _init(scene) -> void:
	super(scene)
	nv = v.get("niveaux", {})
	libelles = sc._cli.has("libelles")          # V0.6 : libellés coupés par défaut (L ou -- --libelles)


## Matériau du blockout avec l'estompage des volumes trop proches de la caméra (src/p7/blockout_p7.gdshader).
func mat(c: Color, grille := 0.0, facade := 0.0, base_y := 0.0, hole := false) -> ShaderMaterial:
	var m := super(c, grille, facade, base_y, hole)
	m.set_shader_parameter("proche", PROCHE_M)
	return m


func _sol(h: float) -> Color:
	if h >= float(nv.get("haut", 8.0)) - 0.01:
		return SOLS_V06["haut"]
	if h >= float(nv.get("median", 3.5)) - 0.01:
		return SOLS_V06["median"]
	return SOLS_V06["bas"]


func construit(e: Dictionary) -> bool:
	var id: String = e.get("id", "")
	match e["type"]:
		"floor":
			var r: Rect2 = e["rect"]
			if e["role"] == "decor":
				var c := Vector3(r.get_center().x, e["h"] - 0.17, r.get_center().y)
				var size := Vector3(r.size.x + 80.0, 0.3, r.size.y + 80.0)
				sc._static_box(c, size, sc.L_NOWALK)
				var md: MeshInstance3D = sc._box_mesh(c - Vector3(0, 0.02, 0), size, mat(SOLS_V06["bas"].darkened(0.15)))
				md.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				return true
			var th := 0.3
			sc._static_box(sc._rect_center(r, e["h"] - th, e["h"]), Vector3(r.size.x, th, r.size.y), sc.L_FLOOR)
			var mi: MeshInstance3D = sc._box_mesh(sc._rect_center(r, e["h"] - th, e["h"]), Vector3(r.size.x, th, r.size.y), mat(_sol(e["h"]), 1.0))
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			return true
		"stairs":
			_escalier(e)
			return true
		"block":
			var r: Rect2 = e["rect"]
			var h0: float = e["h0"]
			var h1: float = e["h1"]
			var size := Vector3(r.size.x, h1 - h0, r.size.y)
			if id.begins_with("gc_"):
				# garde-corps (1 m, collision réelle) : muret plein et main courante claire
				sc._static_box(sc._rect_center(r, h0, h1), size, sc.L_OBST)
				sc._box_mesh(sc._rect_center(r, h0, h0 + 0.85), Vector3(r.size.x, 0.85, r.size.y), mat(MUR_SOUT.lightened(0.08)))
				sc._box_mesh(sc._rect_center(r.grow(0.06), h0 + 0.85, h0 + 1.0), Vector3(r.size.x + 0.12, 0.15, r.size.y + 0.12), mat(Color(0.74, 0.71, 0.66)))
				return true
			if id.begins_with("enceinte_") or id.begins_with("tour_chateau"):
				sc._static_box(sc._rect_center(r, h0, h1), size, sc.L_OBST)
				sc._box_mesh(sc._rect_center(r, h0, h1), size, mat(PIERRE_CHATEAU, 0.0, 0.0, h0))
				_creneaux(r, h1, PIERRE_CHATEAU)
				return true
			var fait := super(e)
			if fait and id.begins_with("bat_"):
				var bm: Dictionary = v.get("batiments", {}).get(id, {})
				# P7.4 (V0.7-A seulement) : toit d'un volume bas plafonné à 70 % de ses murs (une échoppe de 3,5 m ne
				# porte plus un toit de 6 m) ; V0.6 inchangée
				var cap := (h1 - h0) * 0.7 if str(v.get("version", "")) in ["v07a", "v07b"] else 99.0
				_toit(r, h1, str(bm.get("toit", "")), id.hash(), cap)
			return fait
	return false


## Décor propre à la V0.6 : masses des niveaux et murs de soutènement, paysage de toits, Colisée, château, ciel.
func decorer() -> void:
	_niveaux()
	for p in v.get("paysage", []):
		var q: Array = p["rect"]
		var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
		var h0: float = p["h"]
		var h1: float = h0 + float(p["haut"])
		var cat := "residentiel" if int(q[0] + q[1]) % 2 == 0 else "residentiel_b"
		var mi: MeshInstance3D = sc._box_mesh(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), mat(COULEURS[cat], 0.0, 1.0, h0, true))
		mi.name = "paysage"
		_toit(r, h1, str(p.get("toit", "2p")), int(q[0] * 31.0 + q[1] * 7.0))
	_colisee()
	_fontaine_v06()
	_chateau()
	_ambiance()
	# porte sud : vantaux ouverts contre les tours (coupés comme le rempart)
	var bois := mat(Color(0.45, 0.33, 0.24))
	for x in [56.25, 63.75]:
		sc._box_mesh(Vector3(x, 0.8, 171.0), Vector3(0.3, 1.6, 3.0), bois)
	_libelle("Château — accès fermé", Vector3(60.0, 12.0, 23.0))


## Masses de terrain sous les niveaux médian et haut ; leurs faces sud sont les murs de soutènement (face caméra),
## avec un cordon clair au sommet et des contreforts réguliers (lecture de la hauteur à distance).
func _niveaux() -> void:
	var hm: float = nv.get("median", 3.5)
	var hh: float = nv.get("haut", 8.0)
	var y1: float = nv.get("mur1_y", 118.0)
	var y2: float = nv.get("mur2_y", 72.0)
	var x2o: float = nv.get("mur2_x_ouest", 36.0)
	var x_a := -160.0
	var x_b := 290.0
	var y_nord := -240.0
	var pierre := mat(MUR_SOUT, 0.0, 0.0, 0.0)
	# niveau médian : de la ligne du mur 1 jusqu'au fond (sous le niveau haut aussi)
	sc._box_mesh(Vector3((x_a + x_b) * 0.5, (hm - 0.006 - 1.0) * 0.5, (y1 + y_nord) * 0.5), Vector3(x_b - x_a, hm - 0.006 + 1.0, y1 - y_nord), pierre)
	sc._box_mesh(Vector3((x_a + x_b) * 0.5, hm - 0.006 - 0.005, (y1 + y_nord) * 0.5), Vector3(x_b - x_a, 0.01, y1 - y_nord), mat(SOLS_V06["median"].darkened(0.12), 1.0))
	# niveau haut : à l'est de x2o, du mur 2 jusqu'au fond
	sc._box_mesh(Vector3((x2o + x_b) * 0.5, (hh - 0.006 + hm) * 0.5, (y2 + y_nord) * 0.5), Vector3(x_b - x2o, hh - 0.006 - hm, y2 - y_nord), pierre)
	sc._box_mesh(Vector3((x2o + x_b) * 0.5, hh - 0.011, (y2 + y_nord) * 0.5), Vector3(x_b - x2o, 0.01, y2 - y_nord), mat(SOLS_V06["haut"].darkened(0.12), 1.0))
	var cordon := mat(Color(0.70, 0.67, 0.61))
	var contrefort := mat(MUR_SOUT.darkened(0.08))
	var esc: Dictionary = v.get("escaliers", {})
	for spec in [[y1, hm, 0.0, x_a, "montee_place"], [y2, hh, hm, x2o, "montee_civique"]]:
		var y: float = spec[0]
		var ht: float = spec[1]
		var hb: float = spec[2]
		var e: Array = esc.get(spec[4], [0, 0, 0, 0])
		for seg in [[float(spec[3]), float(e[0])], [float(e[1]), x_b]]:
			var a: float = seg[0]
			var b: float = seg[1]
			sc._box_mesh(Vector3((a + b) * 0.5, ht - 0.12, y + 0.15), Vector3(b - a, 0.24, 0.3), cordon)
			var x := ceilf(a / 6.0) * 6.0
			while x < b - 0.6:
				if x > a + 0.6:
					sc._box_mesh(Vector3(x, (hb + ht - 0.3) * 0.5, y + 0.25), Vector3(0.7, ht - 0.3 - hb, 0.5), contrefort)
				x += 6.0
		# joues des escaliers (murets latéraux qui reçoivent la montée)
		for xj in [float(e[0]) - 0.35, float(e[1]) + 0.35]:
			sc._box_mesh(Vector3(xj, (hb + ht) * 0.5 + 0.3, y + float(e[3]) * 0.5), Vector3(0.7, ht - hb + 0.6, float(e[3])), mat(MUR_SOUT.lightened(0.05), 0.0, 0.0, hb))


## Toit : "2p" deux pans (faîtage le long du grand côté), "plat" terrasse avec acrotère, "" rien.
func _toit(r: Rect2, h: float, kind: String, graine: int, cap := 99.0) -> void:
	if kind == "plat":
		sc._box_mesh(sc._rect_center(r.grow(0.15), h, h + 0.5), Vector3(r.size.x + 0.3, 0.5, r.size.y + 0.3), mat(Color(0.66, 0.63, 0.58)))
		return
	if kind != "2p":
		return
	var c: Color = TOITS[absi(graine) % TOITS.size()]
	var long_x := r.size.x >= r.size.y
	var court := minf(r.size.x, r.size.y)
	var ht := minf(clampf(court * 0.42, 1.4, 6.0), maxf(cap, 1.0))
	var d := 0.45                                   # débord
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0 := r.position.x - d
	var x1 := r.end.x + d
	var z0 := r.position.y - d
	var z1 := r.end.y + d
	var pts: Array
	if long_x:
		var zm := r.get_center().y
		var a := Vector3(x0, h, z0); var b := Vector3(x1, h, z0); var cc := Vector3(x1, h, z1); var dd := Vector3(x0, h, z1)
		var ra := Vector3(x0, h + ht, zm); var rb := Vector3(x1, h + ht, zm)
		pts = [[a, b, rb], [a, rb, ra], [dd, ra, rb], [dd, rb, cc], [a, ra, dd], [b, cc, rb]]
	else:
		var xm := r.get_center().x
		var a := Vector3(x0, h, z0); var b := Vector3(x1, h, z0); var cc := Vector3(x1, h, z1); var dd := Vector3(x0, h, z1)
		var ra := Vector3(xm, h + ht, z0); var rb := Vector3(xm, h + ht, z1)
		pts = [[a, ra, rb], [a, rb, dd], [b, cc, rb], [b, rb, ra], [a, b, ra], [dd, rb, cc]]
	# faces sortantes ; ordre des sommets selon la convention de Godot (sens horaire = face avant)
	var cen := Vector3(r.get_center().x, h + ht * 0.33, r.get_center().y)
	for tri in pts:
		var p0: Vector3 = tri[0]
		var p1: Vector3 = tri[1]
		var p2: Vector3 = tri[2]
		var g := (p1 - p0).cross(p2 - p0)
		var n := g.normalized()
		if n.dot((p0 + p1 + p2) / 3.0 - cen) < 0.0:
			n = -n
		if g.dot(n) > 0.0:
			var tmp := p1
			p1 = p2
			p2 = tmp
		for p in [p0, p1, p2]:
			st.set_normal(n)
			st.add_vertex(p)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat(c, 0.0, 0.0, h, true)
	mi.name = "toit"
	sc.root.add_child(mi)


func _creneaux(r: Rect2, h: float, c: Color) -> void:
	var m := mat(c.darkened(0.05))
	var long_x := r.size.x >= r.size.y
	var n := int(floorf((r.size.x if long_x else r.size.y) / 1.6))
	for i in n:
		var t := (i + 0.5) / n
		var p := Vector3(lerpf(r.position.x, r.end.x, t), h + 0.45, r.get_center().y) if long_x else Vector3(r.get_center().x, h + 0.45, lerpf(r.position.y, r.end.y, t))
		sc._box_mesh(p, Vector3(0.8, 0.9, r.size.y) if long_x else Vector3(r.size.x, 0.9, 0.8), m)


func _fontaine_v06() -> void:
	var q: Array = v.get("fontaine", [])
	if q.size() == 4:
		_fontaine(Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]), float(nv.get("median", 3.5)))


## Quartier du château (décor seul, jamais praticable) : loin au nord (≈ 250 m au-delà de la porte fermée), sur une
## butte basse. Avec la caméra V0.6, le cadre ne montre que ≈ 4° au-dessus de l'horizon : le château est dimensionné
## pour tenir dans cette bande depuis le quartier haut (silhouette sur l'horizon, détachée par la brume) ; depuis le bas,
## les gradins de la ville le cachent encore (révélation progressive en montant).
func _chateau() -> void:
	var hh: float = nv.get("haut", 8.0)
	var roc := mat(Color(0.54, 0.52, 0.50), 0.0, 0.0, hh)
	var pierre := mat(PIERRE_CHATEAU, 0.0, 1.0, hh + 6.0)
	var ardoise := Color(0.34, 0.36, 0.42)
	var z0 := -250.0
	# butte : deux gradins bas
	sc._box_mesh(Vector3(60, hh + 1.5, z0), Vector3(260, 3.0, 60), roc)
	sc._box_mesh(Vector3(60, hh + 3.5, z0 - 30.0), Vector3(180, 7.0, 60), roc)
	var top := hh + 7.0
	# enceinte et tours d'angle
	sc._box_mesh(Vector3(60, top + 4.0, z0 - 4.0), Vector3(150, 8.0, 3.0), pierre)
	_creneaux(Rect2(-15, z0 - 5.5, 150, 3.0), top + 8.0, PIERRE_CHATEAU)
	for x in [-15.0, 22.0, 98.0, 135.0]:
		sc._box_mesh(Vector3(x, top + 6.0, z0 - 4.0), Vector3(9, 12.0, 9), pierre)
		_cone(Vector3(x, top + 12.0, z0 - 4.0), 6.4, 8.0, ardoise)
	# corps de logis, donjon et tours
	var logis := Rect2(20, z0 - 60.0, 80, 30)
	sc._box_mesh(sc._rect_center(logis, top, top + 13.0), Vector3(logis.size.x, 13.0, logis.size.y), pierre)
	_toit(logis, top + 13.0, "2p", 2)
	sc._box_mesh(Vector3(60, top + 10.0, z0 - 36.0), Vector3(16, 20.0, 16), pierre)
	_cone(Vector3(60, top + 20.0, z0 - 36.0), 11.5, 9.0, ardoise)
	for x in [26.0, 94.0]:
		sc._box_mesh(Vector3(x, top + 9.0, z0 - 30.0), Vector3(8, 18.0, 8), pierre)
		_cone(Vector3(x, top + 18.0, z0 - 30.0), 5.8, 7.0, ardoise)
	# clochers et tours lointains de part et d'autre (horizon urbain)
	for p in [Vector3(-90, 0, -160), Vector3(-40, 0, -230), Vector3(180, 0, -170), Vector3(150, 0, -240), Vector3(-130, 0, -260), Vector3(220, 0, -260)]:
		sc._box_mesh(Vector3(p.x, hh + 9.0, p.z), Vector3(6, 18.0, 6), pierre)
		_cone(Vector3(p.x, hh + 18.0, p.z), 4.2, 7.0, ardoise)
	# toits lointains bas (lignes de la ville haute, sous l'horizon de la caméra)
	for k in 12:
		var r := Rect2(-120.0 + k * 30.0 + (k % 2) * 8.0, -120.0 - (k % 3) * 30.0, 22.0, 14.0)
		if r.position.x > 0.0 and r.end.x < 120.0 and r.position.y > -140.0:
			continue
		var h0 := hh
		var ht := 4.0 + (k % 3) * 1.5
		sc._box_mesh(sc._rect_center(r, h0, h0 + ht), Vector3(r.size.x, ht, r.size.y), mat(COULEURS["residentiel" if k % 2 == 0 else "residentiel_b"], 0.0, 1.0, h0))
		_toit(r, h0 + ht, "2p", k)


func _cone(base: Vector3, rayon: float, haut: float, c: Color) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = rayon
	cm.height = haut
	cm.radial_segments = 4
	cm.rings = 1
	mi.mesh = cm
	mi.rotation.y = PI / 4.0
	mi.position = base + Vector3(0, haut * 0.5, 0)
	mi.material_override = mat(c)
	sc.root.add_child(mi)


## Ciel (dégradé de fin d'après-midi) et brume de distance : le lointain s'éclaircit et se désature, ce qui détache
## les plans successifs (premier plan, rues, gradins, château). Propre à cette scène (le Colisée garde son ciel).
func _ambiance() -> void:
	var env: Environment = sc._env_res
	var sky := Sky.new()
	var ps := ProceduralSkyMaterial.new()
	ps.sky_top_color = Color(0.36, 0.48, 0.70)
	ps.sky_horizon_color = Color(0.86, 0.78, 0.66)
	ps.ground_horizon_color = Color(0.78, 0.72, 0.64)
	ps.ground_bottom_color = Color(0.40, 0.38, 0.36)
	ps.sun_angle_max = 20.0
	sky.sky_material = ps
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.fog_enabled = not sc._cli.has("sans_brume")
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.80, 0.76, 0.70)
	env.fog_density = 0.45
	env.fog_depth_begin = 50.0
	env.fog_depth_end = 520.0
	env.fog_depth_curve = 1.3
	env.fog_sky_affect = 0.0
	sc._sun.rotation_degrees = Vector3(-34.0, -128.0, 0.0)     # soleil bas venant de l'ouest-sud-ouest : ombres longues
	sc._sun.light_color = Color(1.0, 0.90, 0.78)
	sc._sun.light_energy = 1.1


## Libellés : bâtiments-clés seulement, cachés par le décor (test de profondeur), plus discrets qu'en V0.1 ; L les coupe.
func _libelle(texte: String, p: Vector3) -> void:
	if not libelles:
		return
	super(texte, p)
	var l: Label3D = sc.root.get_child(sc.root.get_child_count() - 1)
	l.no_depth_test = false
	l.font_size = 22
	l.modulate = Color(1.0, 0.97, 0.88, 0.92)


## Escalier : même géométrie et mêmes collisions que le socle (explore_3d._build_stairs), en pierre claire du blockout
## (au lieu de la texture violette de l'avant-poste) ; nez de marche plus clair pour lire la pente de loin.
func _escalier(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var n: int = e["risers"]
	var rise: float = (e["h1"] - e["h0"]) / n
	var yb: float = r.end.y - e["land_bottom"]
	var yt: float = r.position.y + e["land_top"]
	var tread: float = (yb - yt) / n
	var mt := mat(MARCHE, 0.0, 0.0, e["h0"])
	var nez := mat(MARCHE.lightened(0.12))
	for i in n:
		var top: float = e["h0"] + rise * (i + 1)
		var y1 := yb - tread * i
		var y0 := yb - tread * (i + 1)
		sc._box_mesh(Vector3(r.get_center().x, (e["h0"] + top) / 2.0, (y0 + y1) / 2.0), Vector3(r.size.x - 0.24, top - e["h0"], y1 - y0), mt)
		sc._box_mesh(Vector3(r.get_center().x, top - 0.02, y1 - 0.05), Vector3(r.size.x - 0.24, 0.04, 0.1), nez)
	sc._box_mesh(Vector3(r.get_center().x, e["h1"] / 2.0, (r.position.y + yt) / 2.0), Vector3(r.size.x, e["h1"], yt - r.position.y), mt)
	var sb := StaticBody3D.new()
	sb.collision_layer = sc.L_FLOOR
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cv := ConvexPolygonShape3D.new()
	var x0 := r.position.x
	var x1 := r.end.x
	cv.points = PackedVector3Array([Vector3(x0, e["h0"], yb), Vector3(x1, e["h0"], yb), Vector3(x0, e["h1"], yt), Vector3(x1, e["h1"], yt),
		Vector3(x0, e["h0"], yt), Vector3(x1, e["h0"], yt)])
	cs.shape = cv
	sb.add_child(cs)
	sc.root.add_child(sb)
	sc._static_box(Vector3(r.get_center().x, e["h1"] / 2.0, (r.position.y + yt) / 2.0), Vector3(r.size.x, e["h1"], yt - r.position.y), sc.L_FLOOR)
	for x in [r.position.x + 0.06, r.end.x - 0.06]:
		sc._static_box(Vector3(x, (e["h0"] + e["h1"] + 0.2) / 2.0, (yt + yb) / 2.0), Vector3(0.12, e["h1"] + 0.2 - e["h0"], yb - yt), sc.L_OBST)
