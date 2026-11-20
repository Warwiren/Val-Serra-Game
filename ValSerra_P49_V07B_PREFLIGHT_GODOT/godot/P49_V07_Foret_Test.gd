extends Node3D
## Val'Serra P4.9 / V07 — FORET STYLISEE QUATERNIUS — BAC A SABLE ISOLE.
## À ouvrir par F6 depuis le projet `p4-8-marche`, NE remplace PAS F5 ni le niveau original.
## Les GLB sont des candidats de lookdev et ne préjugent pas de la DA finale.

const Actor25 = preload("res://src/explore25/actor25.gd")
const LocomotionV09 = preload("res://src/explore25/locomotion_v09.gd")
const AnimV09B5 = preload("res://src/explore25/anim_v09b5.gd")
const AnimV09C = preload("res://src/explore25/anim_v09c.gd")
const PersoV10 = preload("res://src/explore25/perso_v10.gdshader")
const Occlusion = preload("res://src/occlusion/occlusion_dynamique.gd")
const DiagCollisions = preload("res://src/diag/diagnostic_collisions.gd")
const ROOT := "res://ValSerra_P49_V07B_PREFLIGHT_GODOT/"
const MANIFEST := ROOT + "docs/V07_WORLD.json"
const WALK_M_S := 2.2
const RUN_M_S := 3.6
## V09B.5 — profils de vitesse comparés (touche P) : actuel (P4.8 / V09A) et candidat. Accélération et freinage inchangés ;
## seul le plafond de rattrapage d'Ilya suit la course du profil (voir _physics_process).
const SPEED_PROFILES := {"actuel": [WALK_M_S, RUN_M_S], "candidat": [2.8, 4.5]}
const BOUNDS_X := Vector2(-17.65, 17.65)
const BOUNDS_Z := Vector2(-13.65, 13.65)
const YAW := 20.0
const PITCH := 30.0
## P4.9 : inclinaisons comparées (touches 4 / 5 / 6), mesurées depuis l'horizontale ; azimut, champ et zooms inchangés.
const PITCHES := {KEY_4: 30.0, KEY_5: 27.0, KEY_6: 24.0}

var _hero: CharacterBody3D
var _ilya: CharacterBody3D
var _hero_anim: RefCounted
var _ilya_anim: RefCounted
var _hero_sprite: Sprite3D
var _ilya_sprite: Sprite3D
var _camera: Camera3D
var _world_env: Environment
var _markers: Node3D
var _hud: Label
var _zoom: float = 2.5
var _is_running: bool = false
var _moved_accum: float = 0.0
var _last_dir: Vector3 = Vector3(1, 0, 0)
var _v09_trail := LocomotionV09.new()
var _v09_enabled := true
var _show_hud := true
var _data: Dictionary
var _pitch := PITCH
var _occ: RefCounted
var _diag: Node3D                          # V08A : diagnostic des collisions (touche C), construit à la demande
var _terrain_mi: MeshInstance3D
## V09B.5 — essai réversible des nouveaux cycles d'Aren (touche B), format (T), profil de vitesse (P). Défaut : P4.8,
## vitesses actuelles, c'est-à-dire exactement le comportement d'avant V09B.5.
var _anim_v09b5: RefCounted
var _v09b5_on := false
var _speed_profile := "actuel"
var _hero_ghost: Sprite3D
## V09C — banc d'essai de la nouvelle apparence d'Ilya (touche I) ; défaut : Ilya P4.8, comportement inchangé.
var _ilya_v09c: RefCounted
var _v09c_on := false
var _ilya_ghost: Sprite3D
## V10 (20/11/2026, touche K) : rendu des personnages plus lisible, même dessin (src/explore25/perso_v10.gdshader) ;
## le créateur garde le rendu Sprite3D d'origine au démarrage (20/11/2026), V10 reste en comparaison
var _rendu_v10 := false
var _mat_v10 := {}
const ILYA_OCC_H := 1.30
const HERO_OCC_H := 1.26
## Démarrage retenu par le créateur le 19/11/2026 (vidéo de test) pour la validation : Aren V09B.5 96 × 112 affiché
## à ×0,719 (≈ 64 px, taille constante), Ilya V09C.6, vitesses 2,2 / 3,6 m/s, inclinaison 24°, zoom ×3. Les autres
## versions restent aux touches B / T / I / P / 1-6 (P4.8 en secours). Les outils de non-régression mettent
## `demarrage_v09c6` à false pour garder leur état de référence (P4.8, 30°, ×2,5).
static var demarrage_v09c6 := true
const HERO_PIXEL_M := 0.02                 # taille d'un pixel de sprite (P4.8 : 1 px = 1 px d'écran au ×2,5)

func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not (parsed is Dictionary):
		push_error("P4.9: manifeste JSON invalide ou introuvable: " + MANIFEST)
		return
	_data = parsed as Dictionary
	_make_environment()
	_make_camera()
	_load_terrain()
	_load_water()
	_load_set_dressing()
	# IMPORTANT: aucun des anciens arbres de blocage V06.1 ne charge en V07.
	_make_characters()
	_make_occlusion()
	_make_route_markers()
	_make_monstre()
	_make_hud()
	if demarrage_v09c6:
		_v09b5_on = true
		_anim_v09b5.format = "96x112_h64"
		_v09c_on = true
		_ilya_v09c.course_v09c6 = true
		_speed_profile = "actuel"
		_pitch = 24.0
		_zoom = 3.0
		_set_brume(false)                       # V11 (20/11/2026) : brouillard retiré au démarrage (touche F pour le revoir)
	_reset_positions()

func _make_environment() -> void:
	var we := WorldEnvironment.new()
	we.name = "P49_V07_ForwardPlus_NotValidated"
	_world_env = Environment.new()
	_world_env.background_mode = Environment.BG_COLOR
	_world_env.background_color = Color(0.105, 0.145, 0.148)
	_world_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_world_env.ambient_light_color = Color(0.40, 0.48, 0.57)
	_world_env.ambient_light_energy = 0.48
	_world_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_world_env.fog_enabled = true
	_world_env.fog_light_color = Color(0.51, 0.59, 0.60)
	_world_env.fog_density = 0.009
	_world_env.glow_enabled = true
	_world_env.glow_intensity = 0.17
	# Forward+ needed for volumetric fog; this will be evaluated on a GPU.
	# P4.9 : uniquement en Forward+ (en Compatibilité/OpenGL, Godot refuse la brume volumétrique avec un avertissement).
	_world_env.volumetric_fog_enabled = _forward_plus()
	_world_env.volumetric_fog_density = 0.008
	we.environment = _world_env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun_Warm_Forest_Directional"
	sun.rotation_degrees = Vector3(-48.0, 32.0, 0.0)
	sun.light_color = Color(1.0, 0.84, 0.66)
	sun.light_energy = 1.45
	sun.shadow_enabled = true
	sun.light_angular_distance = 2.0
	add_child(sun)

## brume de distance et brume volumétrique (touche F)
func _set_brume(active: bool) -> void:
	_world_env.fog_enabled = active
	_world_env.volumetric_fog_enabled = active and _forward_plus()

## V11 — le Vorgane : corps statique (collision), Sprite3D comme les personnages, posé au sol à la première image
## physique (rayon vers le terrain)
func _make_monstre() -> void:
	for i in 24:
		_monstre_images.append(load(MONSTRE_DIR + "idle_%d.png" % i))
	_monstre = StaticBody3D.new()
	_monstre.name = "Vorgane"
	_monstre.position = Vector3(MONSTRE_XZ.x, 0.0, MONSTRE_XZ.y)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = MONSTRE_BOITE
	collision.position.y = MONSTRE_BOITE.y * 0.5
	collision.rotation.y = deg_to_rad(-YAW)      # longueur selon l'axe droite de la caméra (rotation fixe)
	collision.shape = shape
	_monstre.add_child(collision)
	_monstre_sprite = Sprite3D.new()
	_monstre_sprite.name = "Pixel_Sprite_vorgane"
	_monstre_sprite.pixel_size = .02
	_monstre_sprite.texture = _monstre_images[0]
	_monstre_sprite.position = Vector3(0, _monstre_images[0].get_height() * .02 * .5, 0)
	_monstre_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_monstre_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_monstre_sprite.shaded = true
	_monstre_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_monstre.add_child(_monstre_sprite)
	add_child(_monstre)

func _update_monstre(delta: float) -> void:
	if _monstre == null:
		return
	if not _monstre_pose:
		var q := PhysicsRayQueryParameters3D.create(Vector3(MONSTRE_XZ.x, 30, MONSTRE_XZ.y), Vector3(MONSTRE_XZ.x, -10, MONSTRE_XZ.y))
		q.exclude = [_monstre.get_rid(), _hero.get_rid(), _ilya.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			_monstre.position.y = float(hit["position"].y)
			_monstre_pose = true
	_monstre_t += delta
	_monstre_sprite.texture = _monstre_images[int(_monstre_t * MONSTRE_IPS) % _monstre_images.size()]
	# il regarde vers la gauche de l'écran ; retourné quand Aren est à sa droite
	var vers := (_hero.global_position - _monstre.global_position).dot(_camera.global_transform.basis.x)
	if absf(vers) > 0.3:
		_monstre_sprite.flip_h = vers > 0.0

func _forward_plus() -> bool:
	return RenderingServer.get_current_rendering_method() == "forward_plus"

func _make_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "P30_V07_Follow_Camera"
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.fov = 30.0
	_camera.current = true
	add_child(_camera)

func _load_asset(name: String) -> PackedScene:
	var path := ROOT + "assets/" + name
	var resource: Resource = load(path)
	if resource is PackedScene:
		return resource as PackedScene
	push_warning("P49 missing or failed GLB import: " + path)
	return null

func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _first_mesh(child)
		if found != null:
			return found
	return null

func _load_terrain() -> void:
	var count := 0
	for tile in _data.get("terrain_tiles", []):
		var packed := _load_asset(String(tile))
		if packed == null:
			continue
		var inst := packed.instantiate() as Node3D
		if inst == null:
			continue
		add_child(inst)
		inst.name = "GROUND_" + String(tile).get_file().get_basename()
		var mesh_inst := _first_mesh(inst)
		if mesh_inst == null or mesh_inst.mesh == null:
			push_error("P49 terrain: no MeshInstance3D in " + String(tile))
			continue
		_terrain_mi = mesh_inst
		var body := StaticBody3D.new()
		body.name = "Terrain_Collision_Exact_TriangleMesh"
		mesh_inst.add_child(body)
		var col := CollisionShape3D.new()
		col.shape = mesh_inst.mesh.create_trimesh_shape()
		body.add_child(col)
		count += 1
	if count != 1:
		push_error("P49: terrain unifié attendu (1 GLB), obtenu " + str(count))
	# Joue non praticable de décor : même frontière que le sol jouable, aucun collider.
	for file_name in _data.get("non_colliding_decor", []):
		var decoration := _load_asset(String(file_name))
		if decoration != null:
			var instance := decoration.instantiate() as Node3D
			instance.name = "V07_FOND_HORS_JEU"
			add_child(instance)
	# Invisible safety colliders. The test scene is intentionally self contained.
	# Terrain is between Y=0 and Y=2.11: walls need to extend above the highest ridge.
	# Using tall vertical walls prevents a high-altitude bypass of the test boundary.
	for e in [
		[Vector3(-18.25, 2.5, 0), Vector3(.5, 9.0, 29)],
		[Vector3(18.25, 2.5, 0), Vector3(.5, 9.0, 29)],
		[Vector3(0, 2.5, -14.25), Vector3(37, 9.0, .5)],
		[Vector3(0, 2.5, 14.25), Vector3(37, 9.0, .5)]
	]:
		var b := StaticBody3D.new()
		b.position = e[0]
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = e[1]
		cs.shape = bs
		b.add_child(cs)
		add_child(b)


# Ruisseau V06.1 : deux matériaux PBR transparents; option V active shader de mouvement.
var _water_meshes: Array[MeshInstance3D] = []
var _water_shader_active := false

func _load_water() -> void:
	for filename in _data.get("water_assets", []):
		var packed := _load_asset(filename)
		if packed == null:
			continue
		var inst := packed.instantiate() as Node3D
		add_child(inst)
		inst.name = "EAU_" + filename.get_file().get_basename()
		var mi := _first_mesh(inst)
		if mi != null:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_water_meshes.append(mi)
	# Invisible segment colliders represent non-walkable water. Independent of shoreline art.
	var sections: Array = _data.get("water_barriers", [])
	for section in sections:
		var bs := BoxShape3D.new()
		var length := float(section["length"])
		var width := float(section["width"])
		bs.size = Vector3(length + .12, 1.70, width)
		var sb := StaticBody3D.new()
		sb.name = "River_NoCrossing"
		var ca := CollisionShape3D.new()
		ca.shape = bs
		sb.add_child(ca)
		var xyz: Array = section["xyz"]
		sb.position = Vector3(float(xyz[0]), float(xyz[1]) + .60, float(xyz[2]))
		sb.rotation.y = float(section["rotation_y"])
		add_child(sb)

# Le décor original était un blocage purement géométrique. Ne plus le charger.
var _forest_root: Node3D
var _model_cache: Dictionary = {}
# Separate scene-visibility toggle from physics: N must also disable obstacles.
var _set_colliders: Array[StaticBody3D] = []
## V11 (20/11/2026) — collisions du décor : tous les rochers bloquent (enveloppe convexe de leur modèle ; seuls 4 sur
## 33 bloquaient, marqués « blocking » dans le manifeste) ; les buissons d'au moins BUISSON_H_MIN de haut bloquent aussi
## (cylindre au cœur du feuillage, BUISSON_COEUR × sa largeur, pour ne pas accrocher sur les feuilles). Herbes,
## fougères, fleurs, cailloux et pierres de chemin restent traversables. Tous ces obstacles sont à plus de 1,6 m des
## tracés des parcours (mesure : tools/p49/mesure_decor.gd).
const BUISSON_H_MIN := 0.85
const BUISSON_COEUR := 0.3
var _nb_rochers := 0
var _nb_buissons := 0
## V11 — le Vorgane (monstre de l'avant-poste, art/p45/chars/vorgane/, 24 images d'attente à 6 i/s) dans une
## clairière au sud du chemin principal (2,45 m du tracé, entre les axes d'audit des traversées) ; même densité de
## pixels que les personnages P4.8 (0,02 m / px) ; collision : boîte de MONSTRE_BOITE alignée sur l'écran (le sprite
## fait 3 m de long : le cylindre de 0,9 m de l'avant-poste laissait Aren entrer dans sa tête) ; il se tourne vers
## Aren. Pas de combat déclenché ici.
const MONSTRE_DIR := "res://art/p45/chars/vorgane/"
const MONSTRE_XZ := Vector2(7.5, 2.5)
const MONSTRE_BOITE := Vector3(2.7, 1.6, 1.1)    # longueur (axe droite de l'écran), hauteur, épaisseur (m)
const MONSTRE_IPS := 6.0
var _monstre: StaticBody3D
var _monstre_sprite: Sprite3D
var _monstre_images: Array[Texture2D] = []
var _monstre_pose := false
var _monstre_t := 0.0

func _tinted_material(base: Material, tint: Color) -> Material:
	if base == null:
		return null
	var result := base.duplicate(true) as Material
	if result is BaseMaterial3D:
		var shaded := result as BaseMaterial3D
		shaded.albedo_color = shaded.albedo_color * tint
		# Ne jamais détruire l'alpha masque des feuilles ; seulement coloriser le matériau.
		shaded.roughness = maxf(0.72, shaded.roughness)
	return result

func _tint_tree(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		var mesh := mesh_inst.mesh
		if mesh != null:
			for surf_i in range(mesh.get_surface_count()):
				var original := mesh.surface_get_material(surf_i)
				if original != null:
					mesh_inst.set_surface_override_material(surf_i, _tinted_material(original, tint))
		mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		_tint_tree(child, tint)

func _toggle_water_shader() -> void:
	if _water_meshes.is_empty():
		return
	_water_shader_active = not _water_shader_active
	for mi in _water_meshes:
		if not _water_shader_active:
			mi.material_override = null
			continue
		var mat := ShaderMaterial.new()
		mat.shader = load(ROOT + "shaders/EAU061_courant_stylise_CANDIDAT.gdshader")
		mat.set_shader_parameter("bruit_eau", load(ROOT + "assets/eau/EAU061_bruit_rides.png"))
		mat.set_shader_parameter("vitesse_courant", .022 if _water_meshes.find(mi) == 0 else .075)
		mi.material_override = mat

func _load_set_dressing() -> void:
	_forest_root = Node3D.new()
	_forest_root.name = "FORET_V07_Quaternius_CC0"
	add_child(_forest_root)
	var grouped: Dictionary = {}
	for placement in _data.get("placements", []):
		var filename := String(placement["asset"])
		var style := String(placement.get("style", "forest"))
		var key := filename + "|" + style
		if not grouped.has(key):
			grouped[key] = []
		(grouped[key] as Array).append(placement)
	var total := 0
	for key in grouped.keys():
		var entries: Array = grouped[key]
		if entries.is_empty():
			continue
		var filename := String(entries[0]["asset"])
		var tint_data: Array = entries[0]["tint"]
		var tint := Color(float(tint_data[0]), float(tint_data[1]), float(tint_data[2]))
		var scene: PackedScene
		if _model_cache.has(filename):
			scene = _model_cache[filename] as PackedScene
		else:
			scene = _load_asset(filename)
			if scene == null:
				continue
			_model_cache[filename] = scene
		var test := scene.instantiate() as Node3D
		var mesh_inst := _first_mesh(test)
		var batchable := mesh_inst != null and mesh_inst.mesh != null and mesh_inst.mesh.get_surface_count() == 1
		var is_hero := String(entries[0].get("role", "")) in ["tree", "rock"]
		if batchable and not is_hero:
			var mult := MultiMesh.new()
			mult.transform_format = MultiMesh.TRANSFORM_3D
			mult.mesh = mesh_inst.mesh
			mult.instance_count = entries.size()
			for i in range(entries.size()):
				var p: Dictionary = entries[i]
				var xyz: Array = p["xyz"]
				var sc := float(p["scale"])
				var rad := deg_to_rad(float(p["rotation_y_deg"]))
				var tr := Transform3D(Basis(Vector3.UP, rad).scaled(Vector3.ONE * sc), Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2])))
				mult.set_instance_transform(i, tr)
			var batches := MultiMeshInstance3D.new()
			batches.name = "VEG_BATCH_" + filename.get_file().get_basename() + "_" + String(entries[0]["style"])
			batches.multimesh = mult
			batches.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			batches.material_override = _tinted_material(mesh_inst.mesh.surface_get_material(0), tint)
			_forest_root.add_child(batches)
			if filename.get_file().begins_with("Bush_"):
				var bb := mesh_inst.mesh.get_aabb()
				for p in entries:
					var s := float(p["scale"])
					if bb.size.y * s >= BUISSON_H_MIN:
						var xyz: Array = p["xyz"]
						_add_bush_collider(Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2])), maxf(bb.size.x, bb.size.z) * s * BUISSON_COEUR, bb.size.y * s)
			total += entries.size()
		else:
			for p in entries:
				var obj := scene.instantiate() as Node3D
				if obj == null:
					continue
				_forest_root.add_child(obj)
				obj.name = String(p["name"]) + "_V07"
				var xyz: Array = p["xyz"]
				var sc := float(p["scale"])
				obj.position = Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2]))
				obj.rotation_degrees.y = float(p["rotation_y_deg"])
				obj.scale = Vector3.ONE * sc
				_tint_tree(obj, tint)
				if bool(p.get("blocking", false)) or String(p["role"]) == "rock":
					if String(p["role"]) == "rock":
						_add_rock_collider(obj)
					else:
						_add_set_collider(obj.position, sc, "tree")
				total += 1
		test.free()
	print("V07: placed %d styled Quaternius instances in %d groups" % [total, grouped.size()])
	print("V11 collisions : %d rochers, %d buissons hauts" % [_nb_rochers, _nb_buissons])

func _add_set_collider(pos: Vector3, scale_factor: float, kind: String) -> void:
	var body := StaticBody3D.new()
	body.name = "Obstacle_" + kind
	body.position = pos
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = (0.48 if kind == "tree" else 1.25) * scale_factor
	shape.height = (2.1 if kind == "tree" else 1.3) * scale_factor
	collision.position.y = shape.height * .5
	collision.shape = shape
	body.add_child(collision)
	_forest_root.add_child(body)
	_set_colliders.append(body)

## V11 — buisson haut : cylindre au cœur du feuillage
func _add_bush_collider(pos: Vector3, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	body.name = "Obstacle_bush"
	body.position = pos
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.position.y = height * .5
	collision.shape = shape
	body.add_child(collision)
	_forest_root.add_child(body)
	_set_colliders.append(body)
	_nb_buissons += 1

## V08A — rocher : collision = enveloppe convexe de SON modèle (position, rotation, échelle comprises). Le cylindre de
## V07 (rayon 1,25 × échelle) était plus petit que la masse visible (1,8 à 2,5 m) : les personnages entraient dans la
## pierre. Les arbres gardent leur cylindre, mesuré à ±0,07 m de leur tronc.
func _add_rock_collider(obj: Node3D) -> void:
	var mi := _first_mesh(obj)
	if mi == null or mi.mesh == null:
		_add_set_collider(obj.position, obj.scale.x, "rock")
		return
	var hull := mi.mesh.create_convex_shape(true, true) as ConvexPolygonShape3D
	var xf := obj.global_transform.affine_inverse() * mi.global_transform     # maillage -> repère du rocher
	var pts := PackedVector3Array()
	for v in hull.points:
		pts.append(obj.basis * (xf * v))                                       # rotation et échelle intégrées
	hull.points = pts
	var body := StaticBody3D.new()
	body.name = "Obstacle_rock"
	_nb_rochers += 1
	body.position = obj.position
	var collision := CollisionShape3D.new()
	collision.shape = hull
	body.add_child(collision)
	_forest_root.add_child(body)
	_set_colliders.append(body)

func _set_forest_visible(enabled: bool) -> void:
	_forest_root.visible = enabled
	# StaticBody3D is not disabled by its parent's visible property.
	# Use deferred updates to avoid changing physics states during physics steps.
	for obstacle in _set_colliders:
		obstacle.set_deferred("collision_layer", 1 if enabled else 0)

func _make_actor(key: String, name: String) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = name
	body.floor_snap_length = .25
	body.floor_constant_speed = true
	# V08A : marge de sécurité de Godot par défaut (0,001). À 0,02 (V07), le personnage prenait des pentes de 27° à
	# 38° pour des murs et s'arrêtait net, alors que sa pente maximale est de 45° (mesuré, `tools/p49/traversees_v08.gd`).
	body.safe_margin = 0.001
	# P4.9 : les personnages sont sur la couche 2 et ne heurtent que le décor (couche 1). Sans cela, au demi-tour,
	# Aren butait sur Ilya qui le suit, et les deux restaient bloqués (Ilya poussant vers son point de suivi).
	body.collision_layer = 2
	body.collision_mask = 1
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .25
	capsule.height = 1.3
	collider.shape = capsule
	collider.position.y = .65
	body.add_child(collider)
	var sprite := Sprite3D.new()
	sprite.name = "Pixel_Sprite_" + key
	sprite.centered = true
	sprite.pixel_size = .02
	sprite.position = Vector3(0, .96, 0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	body.add_child(sprite)
	add_child(body)
	return body

func _make_characters() -> void:
	_hero_anim = Actor25.make("aren")
	_ilya_anim = Actor25.make("ilya")
	# REQUIRED by Actor25 P4.8: normalize stride to sprite-to-world scale.
	# Without this call both characters retain STRIDE_M=0.42 m / frame and glide.
	_hero_anim.set_scale_k(25.2 / 63.0)
	_ilya_anim.set_scale_k(26.0 / 65.0)
	_hero = _make_actor("aren", "Aren_test")
	_ilya = _make_actor("ilya", "Ilya_test")
	_hero_sprite = _hero.get_node("Pixel_Sprite_aren") as Sprite3D
	_ilya_sprite = _ilya.get_node("Pixel_Sprite_ilya") as Sprite3D
	_hero_sprite.texture = _hero_anim.texture()
	_ilya_sprite.texture = _ilya_anim.texture()
	_anim_v09b5 = AnimV09B5.make()
	_ilya_v09c = AnimV09C.make()

## P4.9 — occlusion dynamique : arbres, buissons et rochers de la forêt ; Aren et Ilya suivis séparément.
func _make_occlusion() -> void:
	_occ = Occlusion.new()
	_occ.setup(self, _camera)
	for child in _forest_root.get_children():
		if child is MultiMeshInstance3D:
			_occ.ajouter_multimesh(child)
		elif child is Node3D and not (child is StaticBody3D):
			_occ.ajouter_noeud(child)
	_occ.ajouter_personnage(_hero, _hero_sprite, HERO_OCC_H, 0.5)
	for c in _hero.get_children():
		if c is Sprite3D and c != _hero_sprite:
			_hero_ghost = c                    # silhouette d'occlusion d'Aren (créée par le module, non modifié)
	_occ.ajouter_personnage(_ilya, _ilya_sprite, ILYA_OCC_H, 0.5)
	for c in _ilya.get_children():
		if c is Sprite3D and c != _ilya_sprite:
			_ilya_ghost = c                    # silhouette d'occlusion d'Ilya (créée par le module, non modifié)
	print("P4.9 occlusion : %d obstacles suivis" % _occ.nombre_obstacles())

## V08A — diagnostic des collisions : colliders réels, barrières d'eau, bords et pentes du terrain (touche C).
func _toggle_diag() -> void:
	if _diag == null:
		_diag = DiagCollisions.construire(self, _terrain_mi, rad_to_deg(_hero.floor_max_angle))
		add_child(_diag)
	_diag.visible = not _diag.visible

func _reset_positions() -> void:
	if _hero == null:
		return
	# Feet are at body origin. Sampled from terrain mesh, not an arbitrary Y=1.1.
	var start_heights: Dictionary = _data.get("spawn_ground_y", {})
	_hero.position = Vector3(-15.8, float(start_heights.get("aren", .19)) + .08, 0.0)
	_ilya.position = Vector3(-16.9, float(start_heights.get("ilya", .18)) + .08, .95)
	_hero.velocity = Vector3.ZERO
	_ilya.velocity = Vector3.ZERO
	_moved_accum = 0.0
	_last_dir = Vector3(1, 0, 0)
	_v09_trail.reset(_hero.global_position, _ilya.global_position)
	_update_camera(1.0)

func _route_mesh(color: Color, radius: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = .025
	mi.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

func _make_route_markers() -> void:
	_markers = Node3D.new()
	_markers.name = "Debug_Waypoints_Toggle_M"
	_markers.visible = false
	add_child(_markers)
	var paths: Dictionary = _data.get("routes", {})
	var route_heights: Dictionary = _data.get("route_ground_y", {})
	for route_name in paths.keys():
		var trail: Array = paths[route_name]
		var heights: Array = route_heights.get(route_name, [])
		for idx in range(trail.size()):
			var pt: Array = trail[idx]
			# The terrain can rise by more than 2 m, so debug markers need local Y.
			var ground_y := float(heights[idx]) if idx < heights.size() else 0.0
			var pos := Vector3(float(pt[0]), ground_y + .075, float(pt[1]))
			var ring := _route_mesh(Color(.9,.7,.35,.68) if route_name == "main" else Color(.38,.75,.7,.60), .24)
			ring.position = pos
			_markers.add_child(ring)

func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(16, 14)
	_hud.add_theme_color_override("font_color", Color(.95,.97,.93))
	_hud.add_theme_color_override("font_shadow_color", Color(.08,.11,.10,1))
	_hud.add_theme_constant_override("shadow_offset_x", 1)
	_hud.add_theme_constant_override("shadow_offset_y", 1)
	_hud.add_theme_font_size_override("font_size", 15)
	layer.add_child(_hud)

func _movement_input() -> Vector2:
	var v := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_physical_key_pressed(KEY_Q) or Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	if Input.is_physical_key_pressed(KEY_Z) or Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	return v.limit_length(1.0)

func _physics_process(delta: float) -> void:
	if _hero == null or _camera == null:
		return
	var inp := _movement_input()
	var right := _camera.global_transform.basis.x
	right.y = 0
	right = right.normalized()
	var fwd := -_camera.global_transform.basis.z
	fwd.y = 0
	fwd = fwd.normalized()
	var direction := (right * inp.x - fwd * inp.y).normalized() if inp.length() > .01 else Vector3.ZERO
	var start := _hero.global_position
	_is_running = Input.is_key_pressed(KEY_SHIFT)
	var speeds: Array = SPEED_PROFILES[_speed_profile]
	var speed: float = speeds[1] if _is_running else speeds[0]
	# V09A : inertie légère, cadence des sprites pilotée par le déplacement EFFECTIF plus bas.
	var want_hero := direction * speed
	var hero_v := LocomotionV09.approach_velocity(_hero.velocity, want_hero, delta, 19.0, 22.0) if _v09_enabled else want_hero
	_hero.velocity.x = hero_v.x
	_hero.velocity.z = hero_v.z
	_hero.velocity.y -= 20.0 * delta
	_hero.move_and_slide()
	var step: Vector3 = _hero.global_position - start
	step.y = 0
	var moved := step.length()
	if moved > .0001:
		_last_dir = step.normalized()
		_moved_accum += moved
	var face_dir := Vector2(step.dot(right), -step.dot(_camera.global_transform.basis.y))
	_hero_anim.step(moved, face_dir.normalized() if moved > .0001 else Vector2.ZERO, delta)
	_apply_hero_sprite(moved, face_dir.normalized().x if moved > .0001 else 0.0)
	if _v09_enabled:
		_v09_trail.record(_hero.global_position)
	# Companion pursues a follow point, independent of screen FPS, with floor collision.
	var goal := _hero.global_position - _last_dir * 1.15 + right * .12
	if _v09_enabled:
		goal = _v09_trail.follow_target(1.28)
	var chase := goal - _ilya.global_position
	chase.y = 0
	var follow_dir := chase.normalized() if chase.length() > .38 else Vector3.ZERO
	var p0 := _ilya.global_position
	# V09B.5 : plafond de rattrapage d'Ilya proportionnel à la course du profil (4,25 m/s inchangé au profil actuel ;
	# 5,31 m/s au profil candidat, sans quoi elle perd 0,25 m/s sur Aren à 4,5 m/s — mesuré, animations_v09b5.gd)
	var want_ilya := LocomotionV09.follower_velocity(_ilya.velocity, chase, delta, 4.25 * speeds[1] / RUN_M_S) if _v09_enabled else follow_dir * minf(speed, 2.8)
	_ilya.velocity.x = want_ilya.x
	_ilya.velocity.z = want_ilya.z
	_ilya.velocity.y -= 20.0 * delta
	_ilya.move_and_slide()
	var step2 := _ilya.global_position - p0
	step2.y = 0
	var dir2 := Vector2(step2.dot(right), -step2.dot(_camera.global_transform.basis.y))
	_ilya_anim.step(step2.length(), dir2.normalized() if step2.length() > .0001 else Vector2.ZERO, delta)
	_apply_ilya_sprite(step2.length(), step2.length() / maxf(delta, 0.0001), speeds, dir2.normalized().x if step2.length() > .0001 else 0.0)
	_update_monstre(delta)

## V09C : image d'Ilya (P4.8, ou banc d'essai de la nouvelle apparence, 4 directions). Mêmes règles que pour Aren :
## pieds posés sur l'origine du corps, échelle mesurée, silhouette et hauteur d'occlusion qui suivent l'image.
func _apply_ilya_sprite(moved: float, speed: float, speeds: Array, sx: float = 0.0) -> void:
	var tex: Texture2D = _ilya_anim.texture()
	var ofs := Vector2.ZERO
	var px := HERO_PIXEL_M
	var occ_h := ILYA_OCC_H
	if _v09c_on:
		_ilya_v09c.step(_ilya_anim, moved, speed, speeds, sx)
		tex = _ilya_v09c.texture()
		px = _ilya_v09c.pixel_m()
		ofs = _ilya_v09c.offset_px(_ilya_sprite.position.y, tex)
		occ_h = _ilya_v09c.height_m() - 0.02
	else:
		_ilya_v09c.active = false
	var fl: bool = _v09c_on and bool(_ilya_v09c.miroir())
	_ilya_sprite.texture = tex
	_ilya_sprite.offset = ofs
	_ilya_sprite.pixel_size = px
	_ilya_sprite.flip_h = fl
	_rendu_perso(_ilya_sprite, tex)
	if _ilya_ghost != null:
		_ilya_ghost.texture = tex
		_ilya_ghost.offset = ofs
		_ilya_ghost.pixel_size = px
		_ilya_ghost.flip_h = fl
	if _occ != null:
		var persos: Array = _occ.get("_persos")
		if persos.size() > 1:
			persos[1]["h"] = occ_h

## V10 : matériau du rendu des personnages (ou retour au Sprite3D d'origine) ; même texture, même géométrie
func _rendu_perso(sprite: Sprite3D, tex: Texture2D) -> void:
	if not _rendu_v10:
		sprite.material_override = null
		return
	if not _mat_v10.has(sprite.name):
		var m := ShaderMaterial.new()
		m.shader = PersoV10
		_mat_v10[sprite.name] = m
	var mat: ShaderMaterial = _mat_v10[sprite.name]
	mat.set_shader_parameter("tex", tex)
	sprite.material_override = mat

## V09B.5 : vitesses [marche, course] du profil actif (touche P)
func current_speeds() -> Array:
	return SPEED_PROFILES[_speed_profile]

## V09B.5 : image d'Aren (P4.8, ou cycle candidat sur le seul profil droit en marche/course). Les pieds du cycle
## candidat sont posés sur l'origine du corps par un décalage vertical du sprite ; la silhouette d'occlusion suit la
## même image et le même décalage, et la hauteur testée par l'occlusion suit la taille du sprite affiché.
func _apply_hero_sprite(moved: float, sx: float = 0.0) -> void:
	var tex: Texture2D = _hero_anim.texture()
	var ofs := Vector2.ZERO
	var occ_h := HERO_OCC_H
	var px := HERO_PIXEL_M
	if _v09b5_on:
		_anim_v09b5.step(_hero_anim, moved, _is_running, sx)
		if _anim_v09b5.active:
			tex = _anim_v09b5.texture()
			px = _anim_v09b5.pixel_m()            # variante « hauteur 64 px » : échelle d'affichage réduite
			ofs = _anim_v09b5.offset_px(_hero_sprite.position.y, tex)
			occ_h = _anim_v09b5.height_m() - 0.02
	else:
		_anim_v09b5.active = false
	var fl: bool = _v09b5_on and _anim_v09b5.active and bool(_anim_v09b5.miroir())
	_hero_sprite.texture = tex
	_hero_sprite.offset = ofs
	_hero_sprite.pixel_size = px
	_hero_sprite.flip_h = fl
	_rendu_perso(_hero_sprite, tex)
	if _hero_ghost != null:
		_hero_ghost.texture = tex
		_hero_ghost.offset = ofs
		_hero_ghost.pixel_size = px
		_hero_ghost.flip_h = fl
	if _occ != null:
		var persos: Array = _occ.get("_persos")
		if not persos.is_empty():
			persos[0]["h"] = occ_h

func _process(delta: float) -> void:
	if _hero == null:
		return
	_update_camera(delta)
	if _occ != null:
		_occ.update(delta)
	if _hud != null and _show_hud:
		var p := _hero.global_position
		_hud.text = "P4.9 V07 — 36×28 m / FORET STYLISEE (TEST)\nZQSD / flèches : marcher · Maj : courir · R : départ\n1/2/3 : zoom ×2 / ×2,5 / ×3 · 4/5/6 : inclinaison 30° / 27° / 24° · O : occlusion · C : collisions · M : repères · F : brume · V : eau mobile · N : végétation · H : interface\nInclinaison %d° · Zoom ×%.1f · Occlusion %s · obstacles atténués %d · silhouettes %d\nVitesse %s · parcouru %.1f m · FPS %d\nPosition locale (%.1f, %.1f) · monde de référence (%.1f, %.1f)" % [int(_pitch), _zoom, "ACTIVE" if _occ.enabled else "coupée", _occ.nombre_attenues(), _occ.silhouettes_actives(), "course" if _is_running else "marche", _moved_accum, Engine.get_frames_per_second(), p.x, p.z, p.x+42.0, p.z+15.0]

		var spd: Array = SPEED_PROFILES[_speed_profile]
		var anim_txt := "P4.8 (actuelles)"
		if _v09b5_on:
			anim_txt = "V09B.5 CANDIDAT %s, profil droit seul — %s" % [("CALQUE 64 px (réduction, non dessiné)" if _anim_v09b5.format == "calque_64" else ("96×112 — hauteur 64 px (échelle ×%.3f)" % _anim_v09b5.echelle_h64 if _anim_v09b5.format == "96x112_h64" else _anim_v09b5.format)), ("%s image %d · foulée %.2f m" % ["course" if _anim_v09b5.cycle == "run" else "marche", _anim_v09b5.frame, _anim_v09b5.stride_m()]) if _anim_v09b5.active else "autres directions et attente : P4.8"]
		_hud.text += "\nB : animations d'Aren %s · T : format · P : vitesses %s (marche %.1f / course %.1f m/s) · vitesse mesurée %.2f m/s" % [anim_txt, _speed_profile.to_upper(), spd[0], spd[1], Vector2(_hero.get_real_velocity().x, _hero.get_real_velocity().z).length()]
		if _v09b5_on:
			_hud.text += "\nG : Aren de face / de dos %s" % {"v4": "V4 dessinée (GIF du 20/11, proposition)", "v3": "V3 « en profondeur » (procédurale, proposition)", "4dir": "4dir du 20/11 (procédurale)", "v2": "planche V2"}.get(_anim_v09b5.jeu_vues, _anim_v09b5.jeu_vues)
		_hud.text += "\nK : rendu des personnages %s" % ("V10 (net, éclairé, sans brume, contour — proposition)" if _rendu_v10 else "d'origine (Sprite3D)")
		var ilya_txt := "P4.8 (ancienne apparence)"
		if _v09c_on:
			ilya_txt = "%s BANC D'ESSAI (×%.3f) — %s %s image %d" % ["V09C.6 (course droite)" if _ilya_v09c.course_v09c6 else "V09C.5", _ilya_v09c.echelle, {"idle": "attente", "walk": "marche", "run": "course"}[_ilya_v09c.cycle], _ilya_v09c.dir, _ilya_v09c.frame]
		_hud.text += "\nI : Ilya %s" % ilya_txt
		_hud.text += "\nL : locomotion %s · suivi %d points (V09A est un essai)" % ["V09A" if _v09_enabled else "V08", _v09_trail.sampled_points_count()]

func _update_camera(delta: float) -> void:
	var yaw := deg_to_rad(YAW)
	var pitch := deg_to_rad(_pitch)
	# P4.9 : même P30 que la démo (World25.cam_back) : la caméra est à -X (V07 la plaçait à +X, azimut inversé), et
	# à la distance où 1 px de sprite (0,02 m) = 1 px d'écran au zoom ×2,5 (26,9 m en 720p ; V07 : 25 m fixes).
	var view_h := get_viewport().get_visible_rect().size.y / (20.0 * _zoom)
	var distance := view_h * 0.5 / tan(deg_to_rad(_camera.fov) * 0.5)
	var offset := Vector3(-sin(yaw)*cos(pitch), sin(pitch), cos(yaw)*cos(pitch)) * distance
	var target := _hero.global_position + Vector3(0, .8, 0)
	var destination := target + offset
	_camera.global_position = destination if delta >= 1.0 else _camera.global_position.lerp(destination, minf(1, delta * 7))
	_camera.look_at(target, Vector3.UP)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1: _zoom = 2.0
		KEY_2: _zoom = 2.5
		KEY_3: _zoom = 3.0
		KEY_4, KEY_5, KEY_6:
			_pitch = PITCHES[event.physical_keycode]
			_update_camera(1.0)
		KEY_O: _occ.enabled = not _occ.enabled
		KEY_C: _toggle_diag()
		KEY_L:
			_v09_enabled = not _v09_enabled
			_v09_trail.reset(_hero.global_position, _ilya.global_position)
		KEY_R: _reset_positions()
		KEY_B: _v09b5_on = not _v09b5_on
		KEY_T: _anim_v09b5.toggle_format()
		KEY_K: _rendu_v10 = not _rendu_v10          # rendu des personnages : V10 / d'origine
		KEY_G: _anim_v09b5.toggle_jeu_vues()          # Aren face / dos : V4 -> V3 -> 4dir -> V2
		KEY_P: _speed_profile = "candidat" if _speed_profile == "actuel" else "actuel"
		KEY_I:                                 # Ilya : P4.8 -> V09C.5 -> V09C.6 (course droite) -> P4.8
			if not _v09c_on:
				_v09c_on = true
				_ilya_v09c.course_v09c6 = false
			elif not _ilya_v09c.course_v09c6:
				_ilya_v09c.course_v09c6 = true
			else:
				_v09c_on = false
				_ilya_v09c.course_v09c6 = false
		KEY_M: _markers.visible = not _markers.visible
		KEY_F: _set_brume(not _world_env.fog_enabled)
		KEY_V: _toggle_water_shader()
		KEY_N: _set_forest_visible(not _forest_root.visible)
		KEY_H:
			_show_hud = not _show_hud
			_hud.visible = _show_hud
