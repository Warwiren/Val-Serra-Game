extends RefCounted
## P7.8 — GRANDE PLACE, LOT 1 (autorisé le 25/11/2026) : revêtement de la place et fontaine octogonale à deux vasques.
## Circulations, collisions des données, entrées et terrasses inchangées ; les autres lots (forge, boutique, fond nord,
## étals, parapet) ne sont PAS commencés. Composants : scenes/p7/archi_p77.gd (matières du Colisée), eau
## src/p7/eau_p78.gdshader (opaque). --place=0 : place du blockout V0.7-B (comparaison).
##
## Revêtement (sur la surface « grande_place ») : dallage enrichi, bordures de pierre claire au nord et au sud, caniveau au
## pied des façades nord (grilles de fonte), voie processionnelle de l'AXE DU CHÂTEAU (x 70, réservé : voir axe_chateau des
## données), compas octogonal autour de la fontaine (bande claire et joints rayonnants), carroyage discret de bandes.
## Fontaine : bassin octogonal de 6 m (margelle, pilastres d'angle, emmarchement bas), pile centrale, vasque basse à
## quatre bouches, fût mouluré, vasque haute, pomme de pin ; eau animée opaque, filets d'eau ; hauteur 2,8 m.

const Archi := preload("res://scenes/p7/archi_p77.gd")
const EAU_SH := preload("res://src/p7/eau_p78.gdshader")
const HAB := preload("res://scenes/p6/habillage_p6.gd")
const SOL := "grande_place"
## parties contiguës de la place (même revêtement, sans compas ni voie) ; le recoin de la boutique et l'ouest de la place
const SOLS_SIMPLES := ["place_ouest", "place_recoin"]
const TEINTE_DALLAGE := Color(1.12, 1.09, 1.04)

var sc
var a
var _eau := {}


func _init(scene, archi) -> void:
	sc = scene
	a = archi


func actif() -> bool:
	return str(sc._cli.get("place", "1")) != "0"


func eau(chute := false) -> ShaderMaterial:
	var k := "chute" if chute else "nappe"
	if _eau.has(k):
		return _eau[k]
	var m := ShaderMaterial.new()
	m.shader = EAU_SH
	m.set_shader_parameter("grain", load(HAB.GRAIN))
	m.set_shader_parameter("chute", 1.0 if chute else 0.0)
	_eau[k] = m
	return m


# ------------------------------------------------------------------------------------------------ primitives
## Prisme ou anneau polygonal (n côtés, « apothème » ra = distance au milieu d'un côté) entre y0 et y1 ; ri > 0 : anneau
## (paroi intérieure comprise). Rayons bas / haut distincts : tronc (vasques). UV en mètres (u = périmètre, v = -hauteur)
## pour la maçonnerie en UV du maillage ; dessus en UV monde x / z.
func prisme(c: Vector3, n: int, ra_bas: float, ra_haut: float, y0: float, y1: float, m: Material, ri := 0.0, dessus := true, dessous := false) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var k := 1.0 / cos(PI / n)                       # apothème -> rayon des sommets
	var rb := ra_bas * k
	var rh := ra_haut * k
	var ri_s := ri * k
	var per := 0.0
	for i in n:
		var a0 := TAU * (i + 0.5) / n
		var a1 := TAU * (i + 1.5) / n
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var lg := (d1 - d0).length() * ra_haut * k
		# paroi extérieure
		var p00 := c + d0 * rb + Vector3(0, y0, 0)
		var p10 := c + d1 * rb + Vector3(0, y0, 0)
		var p01 := c + d0 * rh + Vector3(0, y1, 0)
		var p11 := c + d1 * rh + Vector3(0, y1, 0)
		_quad(st, p00, p10, p11, p01, Vector2(per, -y0), Vector2(per + lg, -y0), Vector2(per + lg, -y1), Vector2(per, -y1), true)
		if ri > 0.0:
			var q00 := c + d0 * ri_s + Vector3(0, y0, 0)
			var q10 := c + d1 * ri_s + Vector3(0, y0, 0)
			var q01 := c + d0 * ri_s + Vector3(0, y1, 0)
			var q11 := c + d1 * ri_s + Vector3(0, y1, 0)
			_quad(st, q10, q00, q01, q11, Vector2(per, -y0), Vector2(per + lg, -y0), Vector2(per + lg, -y1), Vector2(per, -y1), true)
			if dessus:
				_quad(st, q01, p01, p11, q11, Vector2(q01.x, q01.z), Vector2(p01.x, p01.z), Vector2(p11.x, p11.z), Vector2(q11.x, q11.z), true)
		elif dessus:
			_tri(st, c + Vector3(0, y1, 0), p11, p01)
		if dessous and ri <= 0.0:
			_tri(st, c + Vector3(0, y0, 0), p00, p10)
		per += lg
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	a.racine.add_child(mi)
	a.elements += 1
	return mi


## Quadrilatère (sommets dans l'ordre, vus de l'extérieur dans le sens trigonométrique du dessus) dans les deux sens
## d'enroulement si demandé faux ; ici un seul sens, orienté vers l'extérieur (générer les normales après).
func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u0: Vector2, u1: Vector2, u2: Vector2, u3: Vector2, _ext: bool) -> void:
	for tri in [[[p0, u0], [p1, u1], [p2, u2]], [[p0, u0], [p2, u2], [p3, u3]]]:
		for v in tri:
			st.set_uv(v[1])
			st.add_vertex(v[0])


func _tri(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3) -> void:
	for p in [p0, p2, p1]:
		st.set_uv(Vector2(p.x, p.z))
		st.add_vertex(p)


## Filet d'eau rectiligne de a à b (boîte fine orientée), matière de chute.
func filet(p0: Vector3, p1: Vector3, ep: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var lg := (p1 - p0).length()
	bm.size = Vector3(ep, lg, ep * 0.6)
	mi.mesh = bm
	mi.material_override = eau(true)
	var y := (p1 - p0).normalized()
	var x := y.cross(Vector3(0, 0, 1)).normalized() if absf(y.z) < 0.9 else y.cross(Vector3(1, 0, 0)).normalized()
	var z := x.cross(y).normalized()
	mi.basis = Basis(x, y, z)
	mi.position = (p0 + p1) * 0.5
	a.racine.add_child(mi)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	a.elements += 1


# ------------------------------------------------------------------------------------------------ revêtement
func sol_simple(id: String, r: Rect2, h: float) -> void:
	var depuis: int = a.racine.get_child_count()
	var mi: MeshInstance3D = a.box(Archi.centre(r, h - 0.3, h), Vector3(r.size.x, 0.3, r.size.y), a.macon("dallage2", TEINTE_DALLAGE, h, "monde", false))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	a.fusionner(depuis, "sol_" + id)


func sol(r: Rect2, h: float, fontaine: Rect2, axe: Dictionary) -> void:
	var depuis: int = a.racine.get_child_count()
	var th := 0.3
	var mi: MeshInstance3D = a.box(Archi.centre(r, h - th, h), Vector3(r.size.x, th, r.size.y), a.macon("dallage2", TEINTE_DALLAGE, h, "monde", false))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var clair = a.macon("dalle", Color(1.1, 1.07, 1.02), h, "monde", false)
	var joint = a.plein(Color(0.20, 0.18, 0.16))
	# carroyage discret : bandes de pierre claire tous les 7 m (alignées sur l'axe du château et la fontaine)
	var x := 70.0 - 7.0 * 5.0
	while x < r.end.x - 0.5:
		if x > r.position.x + 0.5 and absf(x - 70.0) > 3.0:
			a.box(Vector3(x, h + 0.003, r.get_center().y), Vector3(0.28, 0.006, r.size.y - 1.6), clair)
		x += 7.0
	var yb := fontaine.get_center().y
	for dy in [-7.0, 7.0, 14.0, -14.0]:
		var y: float = yb + dy
		if y > r.position.y + 1.0 and y < r.end.y - 1.0:
			a.box(Vector3(r.get_center().x, h + 0.0035, y), Vector3(r.size.x - 1.6, 0.007, 0.28), clair)
	# bordures nord et sud (pierre claire), caniveau au pied des façades nord avec grilles de fonte
	for yy in [r.position.y + 0.45, r.end.y - 0.45]:
		a.box(Vector3(r.get_center().x, h + 0.004, yy), Vector3(r.size.x, 0.008, 0.9), clair)
	var yc := r.position.y + 1.15
	a.box(Vector3(r.get_center().x, h + 0.005, yc), Vector3(r.size.x, 0.01, 0.42), a.macon("dalle", Color(0.62, 0.6, 0.58), h, "monde", false))
	a.box(Vector3(r.get_center().x, h + 0.006, yc), Vector3(r.size.x, 0.01, 0.12), joint)
	var pts := []
	var xg := r.position.x + 2.0
	while xg < r.end.x - 1.0:
		pts.append(Vector3(xg, h + 0.012, yc))
		xg += 4.0
	a.barreaux(pts, Vector3(0.6, 0.012, 0.38), a.plein(Color(0.14, 0.14, 0.15), 0.5, 0.0, 0.4))
	# voie processionnelle de l'axe du château : longues dalles claires, bordées de deux filets sombres
	if not axe.is_empty():
		var ax: float = axe["x"]
		var lg: float = axe["largeur_voie"]
		var x0 := maxf(r.position.x, ax - lg * 0.5)
		var x1 := minf(r.end.x, ax + lg * 0.5)
		a.box(Vector3((x0 + x1) * 0.5, h + 0.004, r.get_center().y), Vector3(x1 - x0, 0.008, r.size.y), a.macon("dalle", Color(1.16, 1.12, 1.06), h, "monde", false))
		for xe in [x0 + 0.08, x1 - 0.08]:
			if xe > r.position.x + 0.1 and xe < r.end.x - 0.1:
				a.box(Vector3(xe, h + 0.006, r.get_center().y), Vector3(0.14, 0.01, r.size.y), joint)
	# compas octogonal autour de la fontaine : pavage rayonnant, bande claire, joints rayonnants
	var c := Vector3(fontaine.get_center().x, 0, fontaine.get_center().y)
	prisme(c, 8, 4.9, 4.9, h + 0.002, h + 0.006, a.macon("dallage2", Color(0.92, 0.9, 0.88), h, "monde", false), 0.0, true)
	prisme(c, 8, 5.3, 5.3, h + 0.003, h + 0.008, clair, 4.9, true)
	for i in 8:
		var an := TAU * (i + 1.0) / 8.0
		var d := Vector3(cos(an), 0, sin(an))
		var mj = a.box(c + d * 4.0 + Vector3(0, h + 0.009, 0), Vector3(0.1, 0.006, 1.8), joint)
		mj.basis = Basis(Vector3.UP, atan2(d.x, d.z))
	a.fusionner(depuis, "sol_grande_place")


# ------------------------------------------------------------------------------------------------ fontaine
## Fontaine octogonale (centre de l'emprise des données, apothème = demi-côté de l'emprise) ; collision : prisme
## octogonal ajusté au bassin (posé par la scène : aucune collision invisible aux angles).
func fontaine(r: Rect2, h: float) -> void:
	var depuis: int = a.racine.get_child_count()
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	var A := r.size.x * 0.5                      # 3 m
	var pv := Archi.PIERRE_VILLE
	var mur = a.macon("mur2", pv, h, "maillage")
	var socle = a.macon("socle2", pv, h, "maillage")
	var moul = a.moulure()
	var dalle = a.macon("dalle", Color(0.8, 0.78, 0.76), h, "monde", false)
	# emmarchement bas, paroi du bassin, margelle, fond, eau
	prisme(c, 8, A + 0.28, A + 0.28, h, h + 0.12, socle)
	prisme(c, 8, A, A, h + 0.12, h + 0.62, mur, A - 0.28)
	prisme(c, 8, A + 0.12, A + 0.12, h + 0.62, h + 0.76, moul, A - 0.4)
	prisme(c, 8, A - 0.28, A - 0.28, h + 0.1, h + 0.16, dalle)
	prisme(c, 8, A - 0.28, A - 0.28, h + 0.49, h + 0.5, eau())
	# pilastres d'angle (dés de pierre aux huit sommets)
	var k := 1.0 / cos(PI / 8.0)
	for i in 8:
		var an := TAU * (i + 0.5) / 8.0
		var p := c + Vector3(cos(an), 0, sin(an)) * (A * k - 0.05)
		var mi = a.box(p + Vector3(0, h + 0.47, 0), Vector3(0.36, 0.7, 0.36), moul)
		mi.basis = Basis(Vector3.UP, -an)
	# pile centrale, vasque basse, bouches et filets, fût, vasque haute, pomme de pin
	prisme(c, 8, 0.62, 0.55, h + 0.5, h + 1.15, mur)
	prisme(c, 8, 0.72, 0.72, h + 1.1, h + 1.2, moul)
	prisme(c, 16, 0.55, 1.5, h + 1.2, h + 1.52, moul, 1.36)
	prisme(c, 16, 1.36, 1.36, h + 1.44, h + 1.45, eau())
	prisme(c, 16, 1.58, 1.58, h + 1.5, h + 1.56, moul, 1.36)
	for i in 4:
		var an := TAU * (i + 0.125) / 4.0
		var d := Vector3(cos(an), 0, sin(an))
		var bouche = a.box(c + d * 1.62 + Vector3(0, h + 1.43, 0), Vector3(0.22, 0.2, 0.3), moul)
		bouche.basis = Basis(Vector3.UP, atan2(d.x, d.z))
		filet(c + d * 1.78 + Vector3(0, h + 1.42, 0), c + d * 2.05 + Vector3(0, h + 0.5, 0), 0.07)
	prisme(c, 12, 0.2, 0.17, h + 1.5, h + 2.12, mur)
	prisme(c, 12, 0.27, 0.27, h + 1.72, h + 1.8, moul)
	prisme(c, 16, 0.24, 0.8, h + 2.1, h + 2.3, moul, 0.7)
	prisme(c, 16, 0.7, 0.7, h + 2.25, h + 2.26, eau())
	prisme(c, 16, 0.86, 0.86, h + 2.28, h + 2.33, moul, 0.7)
	for i in 4:
		var an := TAU * (i + 0.375) / 4.0
		var d := Vector3(cos(an), 0, sin(an))
		filet(c + d * 0.88 + Vector3(0, h + 2.3, 0), c + d * 0.95 + Vector3(0, h + 1.46, 0), 0.05)
	prisme(c, 8, 0.1, 0.1, h + 2.26, h + 2.5, moul)
	var pomme := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.42
	sm.radial_segments = 10
	sm.rings = 6
	pomme.mesh = sm
	pomme.material_override = moul
	pomme.position = c + Vector3(0, h + 2.66, 0)
	a.racine.add_child(pomme)
	a.fusionner(depuis, "fontaine")
	# collision : prisme octogonal ajusté au bassin (la boîte 6 × 6 m des données laissait les angles bloquer à vide)
	var sb := StaticBody3D.new()
	sb.collision_layer = sc.L_OBST
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cv := ConvexPolygonShape3D.new()
	var pts := PackedVector3Array()
	for i in 8:
		var an := TAU * (i + 0.5) / 8.0
		for y in [h, h + 1.0]:
			pts.append(c + Vector3(cos(an) * A * k, y, sin(an) * A * k))
	cv.points = pts
	cs.shape = cv
	sb.add_child(cs)
	sc.root.add_child(sb)
