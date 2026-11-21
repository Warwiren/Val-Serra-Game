extends RefCounted
## P5.2 — sol et horizon de la forêt V07B (exploration F5 et rendu du décor de combat). Présentation seulement :
## même maillage de terrain, mêmes collisions, mêmes objets.
##  - matière de sol : src/explore25/sol_foret.gdshader, sur le terrain jouable ET sur la bordure hors jeu (même
##    texture V07 servant de carte) ; bruits générés au chargement (aucune texture externe) ;
##  - pieds d'objets : positions et tailles des arbres, rochers et buissons du manifeste ;
##  - horizon : sans le brouillard (retiré en V11), la caméra voyait le vide au-delà de la bordure (bande sombre en haut
##    de l'écran). Une ceinture d'arbres lointains (modèles déjà présents, sans collision, sans ombre) et un sol de fond
##    sombre ferment la vue au nord et sur les côtés ; rien au sud (entre la caméra et les personnages).

const SHADER := preload("res://src/explore25/sol_foret.gdshader")            # P5.3 (courant)
const SHADER_P52 := preload("res://src/explore25/sol_foret_p52.gdshader")    # P5.2 figé (comparaison)
const SHADER_P53B := preload("res://src/explore25/sol_foret_p53b.gdshader")  # P5.3-B pilote (textures peintes)
const DIR_PEINT := "res://art/p53/sol/"
## surtout des pins (feuillage jusqu'au sol : un mur de verdure, pas une rangée de troncs), quelques feuillus
const ARBRES_HORIZON := ["models/Pine_2.gltf", "models/Pine_4.gltf", "models/Pine_1.gltf", "models/Pine_2.gltf", "models/Pine_4.gltf", "models/CommonTree_2.gltf"]
const FOND := Color(0.075, 0.105, 0.075)

var materiau: ShaderMaterial             # P5.3
var materiau_p52: ShaderMaterial
var materiau_p53b: ShaderMaterial          # pilote V1 tel que livré (référence conservée), null si absent
var materiau_p53b1c: ShaderMaterial        # V1 + calage de palette (référence visuelle retenue le 21/11/2026)
var materiau_p53b2: ShaderMaterial         # V2 corrective (couleurs recalées par le créateur, hauteurs absolues)
var materiau_p53b2t: ShaderMaterial        # V2 + transitions corrigées (proposition du 21/11/2026)
var materiau_p53b3h: ShaderMaterial        # V3 hybride : V2 transitions + forme des zones mixtes V1 (21/11/2026)
## V2 transitions : moyennes et écarts types mesurés des hauteurs V2 (manifeste + mesure) ; chaque matière est étirée
## pour atteindre un écart type de relief de ≈ 0,2 (comme la V1 étirée ×4), l'herbe usée gardant ses deux modes
## (touffes hautes / terre basse) ; mélange plus doux ; bande intermédiaire en herbe usée
const V2T_MOYENNES := [0.893, 0.565, 0.284]
const V2T_FORCES := Vector3(6.0, 1.3, 8.0)
const V2T_BIAIS := Vector3(0.0, 0.06, -0.02)
const V2T_RAYONS := Vector2(0.8, 1.6)           # proximité du chemin : anneaux de 0,8 et 1,6 m
const V2T_PROFONDEUR := 0.12
## V3 hybride : V2 transitions + herbe clairsemée recomposée (masque du dessin V1, matières V2) ; bande 1 à 2 m,
## relief des îlots 0,5, même recomposition au pied des arbres et rochers (0,8)
const V3H_RAYONS := Vector2(1.0, 2.0)
const V3H_RELIEF := 0.5
const V3H_OBJETS := 0.8
const DIR_PEINT_V2 := "res://art/p53/sol_v2/"
var _maillages := {}                 # MeshInstance3D -> [maillage d'origine, copie avec normales]
var horizon: Node3D
var nb_obstacles := 0
var nb_arbres_horizon := 0


static func bruit(freq: float, octaves: int, graine: int) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq
	n.fractal_octaves = octaves
	n.seed = graine
	var t := NoiseTexture2D.new()
	t.width = 512
	t.height = 512
	t.seamless = true
	t.generate_mipmaps = true
	t.noise = n
	return t


## Les maillages V07 (terrain, bordure) n'ont AUCUNE normale : Godot les éclaire uniformément (effet « surface
## plate ») et la pente n'est pas lisible. Copie du maillage avec normales lissées (mêmes sommets, mêmes faces, la
## collision n'est pas touchée), orientées vers le haut.
static func avec_normales(m: Mesh) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s in m.get_surface_count():
		var st := SurfaceTool.new()
		st.create_from(m, s)
		st.generate_normals()
		var arr: Array = st.commit_to_arrays()
		var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var somme := 0.0
		for i in range(0, nrm.size(), 97):
			somme += nrm[i].y
		if somme < 0.0:
			st = SurfaceTool.new()
			st.create_from(m, s)
			st.generate_normals(true)
			arr = st.commit_to_arrays()
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		out.surface_set_material(s, m.surface_get_material(s))
	return out


## version du sol sur ces maillages : "p53" (courant), "p52" (figé) ou "v07" (d'origine)
## Ombre du terrain : P5.2 la coupait (pensant supprimer des hachures dues en fait au micro-relief) ; sans le terrain
## dans la carte d'ombres, les ombres douces des arbres et personnages se désagrégeaient en points. P5.3 la rétablit.
func appliquer(mis: Array, version) -> void:
	if version is bool:
		version = "p53" if version else "v07"
	for mi in mis:
		var m: MeshInstance3D = mi
		if not _maillages.has(m):
			_maillages[m] = [m.mesh, avec_normales(m.mesh)]
		m.mesh = _maillages[m][0] if version == "v07" else _maillages[m][1]
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if version == "p52" else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var mats := {"p53": materiau, "p52": materiau_p52, "p53b": materiau_p53b, "p53b1c": materiau_p53b1c, "p53b2": materiau_p53b2, "p53b2t": materiau_p53b2t, "p53b3h": materiau_p53b3h}
		m.material_override = (mats[version] if mats[version] != null else materiau) if mats.has(version) else null


## carte : la texture V07 du terrain ; placements : manifeste ; charge : fonction(nom de fichier) -> PackedScene
func construire(carte: Texture2D, placements: Array, charge: Callable) -> void:
	materiau = ShaderMaterial.new()
	materiau.shader = SHADER
	materiau.set_shader_parameter("carte", carte)
	materiau.set_shader_parameter("bruit_large", bruit(0.012, 3, 7))
	materiau.set_shader_parameter("bruit_fin", bruit(0.045, 2, 21))
	var obs := PackedVector4Array()
	var tailles := {}
	for p in placements:
		var role := String(p.get("role", ""))
		var f := String(p["asset"])
		var nature := -1
		if role == "tree":
			nature = 0
		elif role == "rock":
			nature = 1
		elif f.get_file().begins_with("Bush_") and role == "understory":
			nature = 2
		if nature < 0:
			continue
		if not tailles.has(f):
			tailles[f] = _largeur(charge.call(f))
		var xyz: Array = p["xyz"]
		var s := float(p["scale"])
		var r: float = 1.7 * s if nature == 0 else float(tailles[f]) * s * (0.5 if nature == 1 else 0.6)
		obs.append(Vector4(float(xyz[0]), float(xyz[2]), r, float(nature)))
		if obs.size() >= 128:
			break
	nb_obstacles = obs.size()
	materiau.set_shader_parameter("obstacles", obs)
	materiau.set_shader_parameter("nb_obstacles", nb_obstacles)
	materiau_p52 = materiau.duplicate() as ShaderMaterial
	materiau_p52.shader = SHADER_P52
	for k in ["carte", "bruit_large", "bruit_fin", "obstacles", "nb_obstacles"]:
		materiau_p52.set_shader_parameter(k, materiau.get_shader_parameter(k))
	if ResourceLoader.exists(DIR_PEINT + "herbe_drue.png"):
		materiau_p53b = materiau.duplicate() as ShaderMaterial
		materiau_p53b.shader = SHADER_P53B
		for k in ["carte", "bruit_large", "bruit_fin", "obstacles", "nb_obstacles"]:
			materiau_p53b.set_shader_parameter(k, materiau.get_shader_parameter(k))
		materiau_p53b.set_shader_parameter("tex_drue", load(DIR_PEINT + "herbe_drue.png"))
		materiau_p53b.set_shader_parameter("tex_usee", load(DIR_PEINT + "herbe_usee.png"))
		materiau_p53b.set_shader_parameter("tex_terre", load(DIR_PEINT + "terre_chemin.png"))
		materiau_p53b1c = materiau_p53b.duplicate() as ShaderMaterial
		materiau_p53b1c.set_shader_parameter("calage", 1.0)
	if materiau_p53b != null and ResourceLoader.exists(DIR_PEINT_V2 + "herbe_drue.png"):
		materiau_p53b2 = materiau_p53b.duplicate() as ShaderMaterial
		materiau_p53b2.set_shader_parameter("tex_drue", load(DIR_PEINT_V2 + "herbe_drue.png"))
		materiau_p53b2.set_shader_parameter("tex_usee", load(DIR_PEINT_V2 + "herbe_usee.png"))
		materiau_p53b2.set_shader_parameter("tex_terre", load(DIR_PEINT_V2 + "terre_chemin.png"))
		materiau_p53b2.set_shader_parameter("calage", 0.0)          # couleurs déjà recalées : jamais de second calage
		for k in ["moy_drue", "moy_usee", "moy_terre"]:
			materiau_p53b2.set_shader_parameter(k, 0.5)
		materiau_p53b2.set_shader_parameter("force_hauteur", 0.6)
		materiau_p53b2t = materiau_p53b2.duplicate() as ShaderMaterial
		materiau_p53b2t.set_shader_parameter("moy_drue", V2T_MOYENNES[0])
		materiau_p53b2t.set_shader_parameter("moy_usee", V2T_MOYENNES[1])
		materiau_p53b2t.set_shader_parameter("moy_terre", V2T_MOYENNES[2])
		materiau_p53b2t.set_shader_parameter("force_mat", V2T_FORCES)
		materiau_p53b2t.set_shader_parameter("biais_mat", V2T_BIAIS)
		materiau_p53b2t.set_shader_parameter("profondeur_melange", V2T_PROFONDEUR)
		materiau_p53b2t.set_shader_parameter("transition", 1.0)
		materiau_p53b2t.set_shader_parameter("rayon_proximite", V2T_RAYONS)
		materiau_p53b3h = materiau_p53b2t.duplicate() as ShaderMaterial
		materiau_p53b3h.set_shader_parameter("tex_v1_usee", load(DIR_PEINT + "herbe_usee.png"))
		materiau_p53b3h.set_shader_parameter("hybride", 1.0)
		materiau_p53b3h.set_shader_parameter("rayon_proximite", V3H_RAYONS)
		materiau_p53b3h.set_shader_parameter("relief_hybride", V3H_RELIEF)
		materiau_p53b3h.set_shader_parameter("hybride_objets", V3H_OBJETS)


## matériaux du pilote P5.3-B (V1, V1 calée, V2), pour les réglages communs (touche Y)
func materiaux_pilote() -> Array:
	return [materiau_p53b, materiau_p53b1c, materiau_p53b2, materiau_p53b2t, materiau_p53b3h].filter(func(m): return m != null)


func _largeur(sc: PackedScene) -> float:
	if sc == null:
		return 1.0
	var n := sc.instantiate()
	var w := 1.0
	var stack := [n]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var bb := (c as MeshInstance3D).mesh.get_aabb()
			w = maxf(bb.size.x, bb.size.z)
			break
		stack.append_array(c.get_children())
	n.free()
	return w


## ceinture d'arbres lointains et sol de fond ; parent : la scène
func construire_horizon(parent: Node3D, charge: Callable) -> void:
	horizon = Node3D.new()
	horizon.name = "P52_HORIZON_FORET"
	parent.add_child(horizon)
	var sol := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(260, 260)
	sol.mesh = pm
	sol.position = Vector3(0, -0.15, 0)
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.13, 0.15, 0.09)
	ms.roughness = 1.0
	sol.material_override = ms
	sol.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	horizon.add_child(sol)
	var rng := RandomNumberGenerator.new()
	rng.seed = 52
	var meshes: Array = []
	for f in ARBRES_HORIZON:
		var sc: PackedScene = charge.call(f)
		if sc == null:
			continue
		var n := sc.instantiate()
		var stack := [n]
		while not stack.is_empty():
			var c: Node = stack.pop_back()
			if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
				meshes.append((c as MeshInstance3D).mesh)
				break
			stack.append_array(c.get_children())
		n.free()
	if meshes.is_empty():
		return
	# arbres lointains assombris (sous-bois profond, sans brouillard) : copie du maillage dont les matériaux prennent la
	# couleur d'instance (multipliée à l'albédo)
	for i in meshes.size():
		var src: Mesh = meshes[i]
		var cp := src.duplicate() as Mesh
		for s in cp.get_surface_count():
			var m := cp.surface_get_material(s)
			if m is BaseMaterial3D:
				var md := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
				md.vertex_color_use_as_albedo = true
				cp.surface_set_material(s, md)
		meshes[i] = cp
	var par_mesh := {}
	for m in meshes:
		par_mesh[m] = []
	# nord : bande z ∈ [-62, -24] ; côtés : |x| ∈ [29, 62], z ∈ [-24, 10] ; tirage en grille perturbée (densité régulière)
	var pas := 3.1
	var z := -62.0
	while z <= 10.0:
		var x := -66.0
		while x <= 66.0:
			var px := x + rng.randf_range(-1.2, 1.2)
			var pz := z + rng.randf_range(-1.2, 1.2)
			var nord := pz < -24.0
			var cote := absf(px) > 29.0 and pz < 10.0
			if nord or cote:
				var m = meshes[rng.randi() % meshes.size()]
				var d := maxf(0.0, maxf(absf(px) - 28.0, -pz - 24.0))
				var s := rng.randf_range(0.8, 1.15) + d * 0.01
				var y := 0.35 + 0.035 * minf(d + 8.0, 30.0)
				(par_mesh[m] as Array).append(Transform3D(Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * s), Vector3(px, y, pz)))
			x += pas
		z += pas
	for m in par_mesh:
		var tr: Array = par_mesh[m]
		if tr.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = m
		mm.instance_count = tr.size()
		for i in tr.size():
			mm.set_instance_transform(i, tr[i])
			var o: Vector3 = (tr[i] as Transform3D).origin
			var loin := clampf((maxf(absf(o.x) - 28.0, -o.z - 24.0)) / 30.0, 0.0, 1.0)
			var v := lerpf(0.62, 0.38, loin) * rng.randf_range(0.9, 1.08)
			mm.set_instance_color(i, Color(v * 0.92, v, v * 0.9))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		horizon.add_child(mmi)
		nb_arbres_horizon += tr.size()
