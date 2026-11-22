extends RefCounted
## P6.1 — PILOTE D'HABILLAGE du Colisée, uniquement avec les ressources déjà présentes dans le dépôt :
##   - lumière et tonalité rapprochées de la forêt V07B (tonalité filmique, ambiance plus basse, soleil chaud, ciel) ;
##   - ARÈNE : sable (texture terre_chemin de P5.3-B), bande de sable tassé au pied du podium, podium avec chaperon,
##     pilastres, bannières et braseros, gradins avec assises en bois et escaliers, colonnade haute au nord, arcs des
##     accès combattants, loge officielle à colonnes et dais ;
##   - VESTIAIRES (intérieur pilote) : plinthes et poutres, casiers à portes, bancs en planches, râtelier garni,
##     accessoires peints de l'avant-poste (tonneaux, caisses, sacs, bûches, lanternes, bannière), tapis ;
##   - EXTÉRIEUR : parvis pavé et façade extérieure du Colisée, silhouettes de bâtiments lointains (aucun vide noir).
## Aucune collision, surface praticable ni donnée de jeu n'est modifiée : tout est décor (sans corps physique), sauf
## les objets posés là où un meuble des données existait déjà (même emprise).
## Le blockout P6 reste disponible (touche H : pilote / blockout).

const SURF_SH = preload("res://src/p4/surface_p4.gdshader")
const SABLE := "res://art/p53/sol_v2/terre_chemin.png"
const PIERRE := "res://art/p4/batiment/pierre_taille.png"
const PAVES := "res://art/p4/mat/sol_paves.png"
const PLANCHES := "res://art/p4/pont/planches.png"
const FACADE := "res://art/p4/batiment/facade_colombage.png"
const TOIT := "res://art/p4/batiment/toit_violet.png"
const C_CALCAIRE := Color(1.06, 0.98, 0.86)          # pierre de taille réchauffée (le gris-violet venait de la lumière)
const C_GUILDE := Color(0.2, 0.28, 0.62)
const C_OR := Color(0.86, 0.68, 0.3)

var sc                                    # scène du Colisée (méthodes d'aide : _box_mesh, _faces, _card, _light…)
var _mats := {}


func _init(scene) -> void:
	sc = scene


func mat(path: String, tile: float, tint: Color, hole := false, antitile := false) -> ShaderMaterial:
	var k := "%s|%s|%s|%s" % [path, tile, tint, hole]
	if _mats.has(k):
		return _mats[k]
	var m := ShaderMaterial.new()
	m.shader = SURF_SH
	m.set_shader_parameter("tex", load(path))
	m.set_shader_parameter("tile_m", tile)
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("hole", 1.0 if hole else 0.0)
	m.set_shader_parameter("antitile", 1.0 if antitile else 0.0)
	m.set_shader_parameter("macro", 0.06)
	_mats[k] = m
	return m


func uni(c: Color, rough := 0.9, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


# ------------------------------------------------------------------------------------------------ lumière
func lumiere(env: Environment, sun: DirectionalLight3D) -> void:
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.48, 0.52, 0.62)
	env.ambient_light_energy = 0.62
	var sky := Sky.new()
	var ps := ProceduralSkyMaterial.new()
	ps.sky_top_color = Color(0.32, 0.47, 0.72)
	ps.sky_horizon_color = Color(0.78, 0.74, 0.66)
	ps.ground_horizon_color = Color(0.5, 0.45, 0.4)
	ps.ground_bottom_color = Color(0.25, 0.22, 0.2)
	sky.sky_material = ps
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.glow_enabled = true
	env.glow_intensity = 0.22
	env.glow_bloom = 0.02
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.04
	env.adjustment_contrast = 1.06
	sun.light_color = Color(1.0, 0.9, 0.76)
	sun.light_energy = 1.3
	sun.shadow_opacity = 0.82


# ------------------------------------------------------------------------------------------------ extérieur
func exterieur(decor: Rect2) -> void:
	# parvis pavé (sous le niveau de jeu, sans collision : le sol de décor garde la sienne)
	var c := Vector3(decor.get_center().x, -0.03, decor.get_center().y)
	var g: MeshInstance3D = sc._box_mesh(c, Vector3(decor.size.x + 60.0, 0.04, decor.size.y + 60.0), mat(PAVES, 3.2, Color(0.86, 0.8, 0.72), false, true))
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# îlots de bâtiments lointains (au-delà de la carte), toits rouges, façades à colombages
	var rng := RandomNumberGenerator.new()
	rng.seed = 7311
	var fac := mat(FACADE, 4.0, Color(0.92, 0.88, 0.84))
	var toit := mat(TOIT, 2.4, Color(1.25, 0.62, 0.5))
	# aucune rangée au SUD : la caméra regarde vers le nord, des bâtiments au sud passeraient devant le joueur
	var rects := [Rect2(-14, -14, 94, 8), Rect2(-14, -6, 8, 44), Rect2(74, -6, 8, 44)]
	for r in rects:
		var along_x: bool = r.size.x > r.size.y
		var t := 0.0
		var length: float = r.size.x if along_x else r.size.y
		while t < length:
			var w := rng.randf_range(4.0, 7.5)
			var h := rng.randf_range(4.5, 8.5)
			var d := rng.randf_range(4.0, 6.5)
			var p: Vector2 = (r.position + Vector2(t + w / 2.0, r.size.y / 2.0)) if along_x else (r.position + Vector2(r.size.x / 2.0, t + w / 2.0))
			var sx := w if along_x else d
			var sz := d if along_x else w
			sc._box_mesh(Vector3(p.x, h / 2.0, p.y), Vector3(sx, h, sz), fac)
			_toit(Vector3(p.x, h, p.y), Vector2(sx, sz), 1.6, toit, along_x)
			t += w + rng.randf_range(0.2, 1.2)


func _toit(base: Vector3, s: Vector2, hh: float, m: Material, faitage_x: bool) -> void:
	var hx := s.x / 2.0 + 0.3
	var hz := s.y / 2.0 + 0.3
	var a := base + Vector3(-hx, 0, -hz)
	var b := base + Vector3(hx, 0, -hz)
	var c := base + Vector3(hx, 0, hz)
	var d := base + Vector3(-hx, 0, hz)
	var faces: Array = []
	if faitage_x:
		var f0 := base + Vector3(-hx, hh, 0)
		var f1 := base + Vector3(hx, hh, 0)
		faces = [[[a, f0, f1, b], [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]],
			[[c, f1, f0, d], [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]],
			[[a, d, f0], [Vector2(0, 1), Vector2(1, 1), Vector2(0.5, 0)]], [[c, b, f1], [Vector2(0, 1), Vector2(1, 1), Vector2(0.5, 0)]]]
	else:
		var f0 := base + Vector3(0, hh, -hz)
		var f1 := base + Vector3(0, hh, hz)
		faces = [[[d, f1, f0, a], [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]],
			[[b, f0, f1, c], [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]],
			[[a, f0, b], [Vector2(0, 1), Vector2(0.5, 0), Vector2(1, 1)]], [[c, f1, d], [Vector2(0, 1), Vector2(0.5, 0), Vector2(1, 1)]]]
	sc._faces(faces, m)


# ------------------------------------------------------------------------------------------------ arène
func arene(a: Dictionary, tunnels: Array) -> void:
	var c := Vector2(a["centre"][0], a["centre"][1])
	var rx: float = a["rayons"][0]
	var ry: float = a["rayons"][1]
	var ep: float = a["anneau_ep"]
	var ah: float = a["anneau_h"]
	var prof: float = a["gradins_prof"]
	var rangs: int = a["rangs"]
	var n := 144
	var pierre := mat(PIERRE, 2.4, C_CALCAIRE, true)
	var pierre_claire := mat(PIERRE, 2.4, C_CALCAIRE * Color(1.1, 1.08, 1.06), true)
	var pierre_sombre := mat(PIERRE, 2.4, C_CALCAIRE * Color(0.78, 0.76, 0.76), true)
	var bois := mat(PLANCHES, 1.6, Color(0.62, 0.5, 0.44))
	# sable
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		for v in [Vector3(c.x, 0.006, c.y), Vector3(c.x + rx * cos(a0), 0.006, c.y + ry * sin(a0)), Vector3(c.x + rx * cos(a1), 0.006, c.y + ry * sin(a1))]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	var sable := MeshInstance3D.new()
	sable.mesh = st.commit()
	sable.material_override = mat(SABLE, 4.0, Color(1.06, 1.0, 0.9), false, true)
	sc.root.add_child(sable)
	# sable tassé et ombré au pied du podium, piétinement au centre (bandes semi-transparentes)
	_bande(c, rx, ry, rx - 1.6, ry - 1.6, 0.009, Color(0.28, 0.2, 0.12, 0.42), Color(0.28, 0.2, 0.12, 0.0))
	_bande(c, 3.6, 3.6, 0.0, 0.0, 0.008, Color(0.35, 0.26, 0.16, 0.0), Color(0.35, 0.26, 0.16, 0.22))
	# podium : parement, chaperon débordant, pilastres, bannières, braseros
	var podium: Array = []
	var chaperon: Array = []
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		if _dans_tunnel(c, rx + ep * 0.5, ry + ep * 0.5, (a0 + a1) / 2.0, tunnels):
			continue
		podium.append(sc._ring_quad(c, rx, ry, a0, a1, 0.0, ah, 0.0))
		chaperon.append(sc._ring_top(c, rx - 0.14, ry - 0.14, rx + ep + 0.05, ry + ep + 0.05, a0, a1, ah + 0.14))
		chaperon.append(sc._ring_quad(c, rx - 0.14, ry - 0.14, a0, a1, ah, ah + 0.14, 0.0))
	sc._faces(podium, pierre)
	sc._faces(chaperon, pierre_claire)
	var k := 0
	for i in range(0, 360, 12):
		var an := deg_to_rad(i + 6)
		if _dans_tunnel(c, rx + ep * 0.5, ry + ep * 0.5, an, tunnels) or _dans_tunnel(c, rx + ep * 0.5, ry + ep * 0.5, an + 0.08, tunnels) or _dans_tunnel(c, rx + ep * 0.5, ry + ep * 0.5, an - 0.08, tunnels):
			continue
		var p := Vector3(c.x + (rx - 0.08) * cos(an), 0, c.y + (ry - 0.08) * sin(an))
		var pil: MeshInstance3D = sc._box_mesh(p + Vector3(0, (ah + 0.3) / 2.0, 0), Vector3(0.5, ah + 0.3, 0.5), pierre_sombre)
		pil.rotation.y = -atan2(ry * sin(an), rx * cos(an))
		k += 1
		var sud := sin(an) > 0.3
		if k % 3 == 0 and not sud:
			var mid := deg_to_rad(i + 12)
			if not _dans_tunnel(c, rx, ry, mid, tunnels):
				_banniere_podium(Vector3(c.x + (rx - 0.05) * cos(mid), 0, c.y + (ry - 0.05) * sin(mid)), mid, c, rx, ry, C_GUILDE if (k / 3) % 2 == 0 else Color(0.62, 0.16, 0.2))
		if k % 5 == 2:
			_brasero(p + Vector3(0, ah + 0.3, 0) - Vector3(cos(an), 0, sin(an)) * 0.1)
	# gradins : contremarches en pierre, assises en bois, escaliers tous les 30°
	var contremarches: Array = []
	var marches: Array = []
	var assises: Array = []
	var escaliers: Array = []
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var am := (a0 + a1) / 2.0
		var sud := maxf(0.0, sin(am))
		# P6.2-D : gradins sud-est abaissés aussi (entre le tunnel est et le sud) : vus de la caméra, ils couvraient le
		# tunnel est et Aren qui y passe (affichage seulement : aucune collision)
		var deg := rad_to_deg(fposmod(am, TAU))
		var se := smoothstep(4.0, 16.0, deg) * (1.0 - smoothstep(60.0, 80.0, deg))
		var k_h := lerpf(1.0, 0.42, maxf(sud, se))
		if _dans_tunnel(c, rx + ep + prof * 0.5, ry + ep + prof * 0.5, am, tunnels) or _dans_tunnel(c, rx + ep * 0.5, ry + ep * 0.5, am, tunnels) or _dans_tunnel(c, rx + ep + prof - 0.2, ry + ep + prof - 0.2, am, tunnels):
			continue
		var allee := fposmod(rad_to_deg(am), 30.0) < 2.6
		for kk in rangs:
			var r0 := rx + ep + prof * kk / rangs
			var r1 := rx + ep + prof * (kk + 1) / rangs
			var hk := (ah + 0.25 + 0.55 * (kk + 1)) * k_h + (1.0 - k_h) * 0.4
			var hprev := ah + 0.14 if kk == 0 else (ah + 0.25 + 0.55 * kk) * k_h + (1.0 - k_h) * 0.4
			contremarches.append(sc._ring_quad(c, r0, ry + (r0 - rx), a0, a1, hprev, hk, 0.0))
			if allee:
				escaliers.append(sc._ring_top(c, r0, ry + (r0 - rx), r1, ry + (r1 - rx), a0, a1, hk))
			else:
				marches.append(sc._ring_top(c, r0, ry + (r0 - rx), r1, ry + (r1 - rx), a0, a1, hk))
				var rs := r0 + 0.08
				assises.append(sc._ring_top(c, rs, ry + (rs - rx), rs + 0.34, ry + (rs + 0.34 - rx), a0, a1, hk + 0.07))
				assises.append(sc._ring_quad(c, rs, ry + (rs - rx), a0, a1, hk, hk + 0.07, 0.0))
		var rl := rx + ep + prof
		var htop := (ah + 0.25 + 0.55 * rangs) * k_h + (1.0 - k_h) * 0.4
		contremarches.append(sc._ring_quad(c, rl, ry + (rl - rx), a1, a0, 0.0, htop + 0.7, 0.0))
		contremarches.append(sc._ring_top(c, rl, ry + (rl - rx), rl + 0.5, ry + (rl + 0.5 - rx), a0, a1, htop + 0.7))
		contremarches.append(sc._ring_quad(c, rl, ry + (rl - rx), a0, a1, htop, htop + 0.7, 0.0))
	sc._faces(contremarches, pierre)
	var mg: MeshInstance3D = sc._faces(marches, pierre_claire)
	mg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	sc._faces(assises, bois)
	sc._faces(escaliers, mat(PIERRE, 1.2, C_CALCAIRE * Color(0.9, 0.86, 0.84), true))
	# colonnade haute (moitié nord, derrière l'arène) : colonnes et architrave
	var rl2 := rx + ep + prof + 0.25
	var htop_n := ah + 0.25 + 0.55 * rangs + 0.7
	var archi: Array = []
	for i in range(-168, -10, 8):
		var an := deg_to_rad(i)
		var p := Vector3(c.x + rl2 * cos(an), htop_n, c.y + (ry + (rl2 - rx)) * sin(an))
		_colonne(p, 2.3, pierre_claire)
	for i in range(-168, -18, 4):
		var a0 := deg_to_rad(i)
		var a1 := deg_to_rad(i + 4)
		archi.append(sc._ring_quad(c, rl2 - 0.3, ry + (rl2 - 0.3 - rx), a0, a1, htop_n + 2.3, htop_n + 2.75, 0.0))
		archi.append(sc._ring_top(c, rl2 - 0.3, ry + (rl2 - 0.3 - rx), rl2 + 0.3, ry + (rl2 + 0.3 - rx), a0, a1, htop_n + 2.75))
	sc._faces(archi, pierre_claire)
	# accès combattants : arcs à claveaux, grille relevée visible
	for t in tunnels:
		if (t as Rect2).size.x > (t as Rect2).size.y:      # tunnel est (vu de côté) ; au sud, un arc masquerait l'arène
			_arc_tunnel(t as Rect2, pierre_claire, pierre_sombre)


func _dans_tunnel(c: Vector2, rx: float, ry: float, an: float, tunnels: Array) -> bool:
	var p := Vector2(c.x + rx * cos(an), c.y + ry * sin(an))
	for t in tunnels:
		if (t as Rect2).grow(0.15).has_point(p):
			return true
	return false


func _bande(c: Vector2, rx0: float, ry0: float, rx1: float, ry1: float, h: float, c0: Color, c1: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 96
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var v := [Vector3(c.x + rx0 * cos(a0), h, c.y + ry0 * sin(a0)), Vector3(c.x + rx0 * cos(a1), h, c.y + ry0 * sin(a1)),
			Vector3(c.x + rx1 * cos(a1), h, c.y + ry1 * sin(a1)), Vector3(c.x + rx1 * cos(a0), h, c.y + ry1 * sin(a0))]
		var col := [c0, c0, c1, c1]
		for j in [0, 2, 1, 0, 3, 2]:
			st.set_normal(Vector3.UP)
			st.set_color(col[j])
			st.add_vertex(v[j])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sc.root.add_child(mi)


func _colonne(base: Vector3, h: float, m: Material) -> void:
	var cy := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.2
	cm.bottom_radius = 0.24
	cm.height = h
	cm.radial_segments = 10
	cy.mesh = cm
	cy.material_override = m
	cy.position = base + Vector3(0, h / 2.0, 0)
	sc.root.add_child(cy)
	sc._box_mesh(base + Vector3(0, 0.1, 0), Vector3(0.6, 0.2, 0.6), m)
	sc._box_mesh(base + Vector3(0, h - 0.08, 0), Vector3(0.58, 0.16, 0.58), m)


func _banniere_podium(p: Vector3, an: float, _c: Vector2, _rx: float, _ry: float, col: Color) -> void:
	var tissu := uni(col, 1.0)
	tissu.cull_mode = BaseMaterial3D.CULL_DISABLED
	var b: MeshInstance3D = sc._box_mesh(p + Vector3(0, 0.95, 0), Vector3(0.9, 0.95, 0.03), tissu)
	b.rotation.y = -an + PI / 2.0
	var o: MeshInstance3D = sc._box_mesh(p + Vector3(0, 1.0, 0) - Vector3(cos(an), 0, sin(an)) * 0.03, Vector3(0.26, 0.26, 0.02), uni(C_OR, 0.5, 0.4))
	o.rotation.y = -an + PI / 2.0


func _brasero(p: Vector3) -> void:
	sc._box_mesh(p + Vector3(0, 0.12, 0), Vector3(0.36, 0.24, 0.36), uni(Color(0.2, 0.18, 0.18), 0.6, 0.5))
	var feu := StandardMaterial3D.new()
	feu.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	feu.albedo_color = Color(1.0, 0.6, 0.2)
	sc._box_mesh(p + Vector3(0, 0.28, 0), Vector3(0.22, 0.1, 0.22), feu)
	sc._halo(p + Vector3(0, 0.45, 0), 1.0, 0.55)
	sc._light(p + Vector3(0, 0.7, 0), 0.9, 5.0)


func _arc_tunnel(t: Rect2, m: Material, m2: Material) -> void:
	var sud := t.size.y > t.size.x
	var largeur: float = t.size.x if sud else t.size.y
	var c := Vector3(t.get_center().x, 0, t.position.y + 1.2) if sud else Vector3(t.position.x + 1.0, 0, t.get_center().y)
	var axe := Vector3(1, 0, 0) if sud else Vector3(0, 0, 1)
	var prof := Vector3(0, 0, 1) if sud else Vector3(1, 0, 0)
	var hp := 2.0
	for s in [-1.0, 1.0]:
		var pc: Vector3 = c + axe * s * (largeur / 2.0 + 0.3)
		var b: MeshInstance3D = sc._box_mesh(pc + Vector3(0, hp / 2.0 + 0.3, 0), Vector3(0.6, hp + 0.6, 0.9) if sud else Vector3(0.9, hp + 0.6, 0.6), m2)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var r := largeur / 2.0 + 0.3
	var nseg := 9
	for i in nseg:
		var a0 := PI * i / nseg
		var a1 := PI * (i + 1) / nseg
		var am := (a0 + a1) / 2.0
		var pos := c + axe * (-cos(am) * r) + Vector3(0, hp + 0.3 + sin(am) * r * 0.62, 0)
		var seg: MeshInstance3D = sc._box_mesh(pos, Vector3(0.62, 0.42, 0.9) if sud else Vector3(0.9, 0.42, 0.62), m if i != nseg / 2 else mat(PIERRE, 2.4, C_OR * Color(1.2, 1.2, 1.2), true))
		var ang := am - PI / 2.0
		if sud:
			seg.rotation.z = ang
		else:
			seg.rotation.x = -ang
	sc._box_mesh(c + Vector3(0, hp + 0.3 + r * 0.62 + 0.35, 0), Vector3(largeur + 1.6, 0.3, 1.0) if sud else Vector3(1.0, 0.3, largeur + 1.6), m)


# ------------------------------------------------------------------------------------------------ loge
func loge(lg: Dictionary) -> void:
	var lc := Vector3(lg["centre"][0], 0.0, lg["centre"][1])
	var ls := Vector2(lg["taille"][0], lg["taille"][1])
	var lh: float = lg["h"]
	var pierre := mat(PIERRE, 2.4, C_CALCAIRE * Color(1.08, 1.04, 1.0), true)
	sc._box_mesh(lc + Vector3(0, lh / 2.0, 0), Vector3(ls.x, lh, ls.y), pierre)
	sc._box_mesh(lc + Vector3(0, lh + 0.08, 0.2), Vector3(ls.x + 0.4, 0.16, ls.y + 0.5), mat(PIERRE, 2.4, C_CALCAIRE * Color(1.2, 1.15, 1.1), true))
	# balustrade
	for i in 11:
		var x := -ls.x / 2.0 + 0.3 + (ls.x - 0.6) * i / 10.0
		sc._box_mesh(lc + Vector3(x, lh + 0.45, ls.y / 2.0 + 0.1), Vector3(0.1, 0.6, 0.1), pierre)
	sc._box_mesh(lc + Vector3(0, lh + 0.8, ls.y / 2.0 + 0.1), Vector3(ls.x, 0.1, 0.18), pierre)
	# colonnes et dais rouge et or
	for x in [-ls.x / 2.0 + 0.3, -ls.x / 6.0, ls.x / 6.0, ls.x / 2.0 - 0.3]:
		_colonne(lc + Vector3(x, lh + 0.16, ls.y / 2.0 - 0.1), 2.1, pierre)
	var rouge := uni(Color(0.6, 0.12, 0.16), 1.0)
	rouge.cull_mode = BaseMaterial3D.CULL_DISABLED
	var dais: MeshInstance3D = sc._box_mesh(lc + Vector3(0, lh + 2.45, 0.1), Vector3(ls.x + 0.5, 0.1, ls.y + 0.6), rouge)
	dais.rotation.x = 0.12
	sc._box_mesh(lc + Vector3(0, lh + 2.2, ls.y / 2.0 + 0.32), Vector3(ls.x + 0.5, 0.36, 0.04), uni(C_OR, 0.5, 0.3))
	sc._box_mesh(lc + Vector3(0, lh - 0.8, ls.y / 2.0 + 0.04), Vector3(ls.x - 0.8, 1.3, 0.04), rouge)
	sc._box_mesh(lc + Vector3(0, lh - 0.8, ls.y / 2.0 + 0.07), Vector3(0.6, 0.6, 0.02), uni(C_OR, 0.45, 0.5))
	# trône et sièges (silhouettes)
	sc._box_mesh(lc + Vector3(0, lh + 0.6, -0.4), Vector3(0.8, 1.0, 0.6), rouge)


# ------------------------------------------------------------------------------------------------ vestiaires
## r : rectangle praticable des vestiaires (plan). Décor posé sur les meubles existants ou contre les murs.
func vestiaires(r: Rect2) -> void:
	var pierre := mat(PIERRE, 2.4, C_CALCAIRE * Color(0.96, 0.94, 0.92), true)
	var plinthe := mat(PIERRE, 1.2, C_CALCAIRE * Color(0.7, 0.68, 0.68))
	var bois := mat(PLANCHES, 1.6, Color(0.78, 0.62, 0.5))
	var bois_sombre := mat(PLANCHES, 1.6, Color(0.5, 0.38, 0.32))
	# plancher plus chaleureux avec bordure de dalles
	sc._box_mesh(Vector3(r.get_center().x, 0.004, r.get_center().y), Vector3(r.size.x, 0.008, r.size.y), mat(PLANCHES, 2.0, Color(0.56, 0.5, 0.46)))
	for e in [[r.position.x, r.position.y, r.size.x, 0.45], [r.position.x, r.end.y - 0.45, r.size.x, 0.45], [r.position.x, r.position.y, 0.45, r.size.y], [r.end.x - 0.45, r.position.y, 0.45, r.size.y]]:
		sc._box_mesh(Vector3(e[0] + e[2] / 2.0, 0.012, e[1] + e[3] / 2.0), Vector3(e[2], 0.02, e[3]), mat(PAVES, 1.6, Color(0.8, 0.76, 0.74)))
	# plinthes et poutre haute le long du mur nord (vu de face)
	sc._box_mesh(Vector3(r.get_center().x, 0.18, r.position.y - 0.02), Vector3(r.size.x, 0.36, 0.1), plinthe)
	sc._box_mesh(Vector3(r.get_center().x, 2.82, r.position.y - 0.04), Vector3(r.size.x + 0.8, 0.22, 0.2), bois_sombre)
	for x in [r.position.x + 2.0, r.get_center().x - 3.6, r.get_center().x + 3.6, r.end.x - 2.0]:
		sc._box_mesh(Vector3(x, 1.42, r.position.y - 0.02), Vector3(0.24, 2.84, 0.16), bois_sombre)
	# casiers à portes (sur l'emprise des casiers des données)
	for q in [Rect2(16.2, 46.6, 6.4, 0.6), Rect2(29.4, 46.6, 6.4, 0.6)]:
		_casiers(q, 2.0, bois, bois_sombre)
	_casiers_vertical(Rect2(16.1, 49.0, 0.6, 4.5), 2.0, bois, bois_sombre)
	# râtelier garni, accessoires peints (P6.2 : tapis et lanternes sur pied retirés, axe central dégagé)
	var fer := uni(Color(0.72, 0.74, 0.8), 0.35, 0.8)
	for i in 7:
		var z := 49.45 + i * 0.47
		sc._box_mesh(Vector3(35.1, 0.95, z), Vector3(0.05, 1.5, 0.08), fer)
		sc._box_mesh(Vector3(35.1, 0.32, z), Vector3(0.16, 0.06, 0.16), uni(Color(0.45, 0.3, 0.2)))
	for z in [49.6, 52.2]:
		var bouclier := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.38
		cm.bottom_radius = 0.38
		cm.height = 0.06
		bouclier.mesh = cm
		bouclier.material_override = uni(Color(0.32, 0.4, 0.62), 0.6, 0.3)
		bouclier.rotation = Vector3(0, 0, PI / 2.0)
		bouclier.position = Vector3(35.62, 1.3, z)
		sc.root.add_child(bouclier)
	sc._card("props/tont01_tonneau.png", Vector3(34.9, 0, 54.1), 0.9, {"anchor": 0.08, "blob": 0.8})
	sc._card("props/cais01_caisse.png", Vector3(17.2, 0, 54.3), 1.05, {"anchor": 0.1, "blob": 0.9})
	sc._card("props/sac01_sacs.png", Vector3(18.3, 0, 54.5), 0.9, {"anchor": 0.08})
	sc._card("props/bois02_buches.png", Vector3(34.9, 0, 48.15), 1.1, {"anchor": 0.12})
	sc._card("props/bann02_bleue.png", Vector3(24.0, 0, 46.65), 1.0, {"anchor": 0.05})
	sc._card("props/bann02_bleue.png", Vector3(28.0, 0, 46.65), 1.0, {"anchor": 0.05})


func _casiers(q: Rect2, h: float, bois: Material, sombre: Material) -> void:
	var n := int(q.size.x / 0.8)
	var w := q.size.x / n
	for i in n:
		var x := q.position.x + w * (i + 0.5)
		sc._box_mesh(Vector3(x, h / 2.0, q.end.y + 0.015), Vector3(w - 0.06, h - 0.08, 0.03), bois)
		sc._box_mesh(Vector3(x, h * 0.82, q.end.y + 0.035), Vector3(w * 0.5, 0.05, 0.02), sombre)
		sc._box_mesh(Vector3(x + w * 0.32, h * 0.5, q.end.y + 0.04), Vector3(0.04, 0.12, 0.03), uni(Color(0.8, 0.66, 0.3), 0.4, 0.7))
	sc._box_mesh(Vector3(q.get_center().x, h + 0.04, q.get_center().y), Vector3(q.size.x + 0.08, 0.08, q.size.y + 0.08), sombre)


func _casiers_vertical(q: Rect2, h: float, bois: Material, sombre: Material) -> void:
	var n := int(q.size.y / 0.8)
	var w := q.size.y / n
	for i in n:
		var z := q.position.y + w * (i + 0.5)
		sc._box_mesh(Vector3(q.end.x + 0.015, h / 2.0, z), Vector3(0.03, h - 0.08, w - 0.06), bois)
		sc._box_mesh(Vector3(q.end.x + 0.035, h * 0.82, z), Vector3(0.02, 0.05, w * 0.5), sombre)
	sc._box_mesh(Vector3(q.get_center().x, h + 0.04, q.get_center().y), Vector3(q.size.x + 0.08, 0.08, q.size.y + 0.08), sombre)
