extends "res://scenes/explore25/explore_3d.gd"
## P4 — AVANT-POSTE DE LA LISIÈRE : première zone d'exploration HD-2D / 2.5D habillée.
## Réutilise le socle P3 (modèle de monde World25, session, caméra à 3 zooms, déplacement et collisions de
## l'architecture Camera3D orthographique) et n'en remplace que l'habillage et les rencontres :
##   - caméra : variante B de P3-07 (plongée 28°, azimut 20°, héros centré), rotation fixe ;
##   - données : data/p4/avant_poste.json (cour, terrasse, escalier, porte fortifiée, pont, rivière, plaine) et
##     data/p4/interieur_poste.json (instance intérieure du bâtiment principal) ;
##   - matières P4_MAT_v03, découpes P4_ENV_MODULES_v01, pilotes P4_PILOTES_TECH_v01 (art/p4/, voir SOURCES.md) ;
##   - dialogue à portraits, Vorgane, combat et retour (GameState), comme l'exploration précédente.
## Voir docs/P4_AVANT_POSTE.md.

const SURF_SH = preload("res://src/p4/surface_p4.gdshader")
const CARD_SH = preload("res://src/p4/carte_p4.gdshader")
const DECAL_SH = preload("res://src/p4/decal_p4.gdshader")
const EAU_SH = preload("res://src/p4/eau_p4.gdshader")
const HALO_SH = preload("res://src/p4/halo_p4.gdshader")
const DialogueBox = preload("res://src/proto/dialogue_box.gd")
const ZONE := "res://data/p4/avant_poste.json"
const DIALOGUE := "res://data/p4/dialogue_garde.json"
const T := "res://art/p4/"
const P41 := "res://art/p41/"
const PERSO_SH = preload("res://src/p4/perso_p41.gdshader")
const MONSTER_DIR := "res://art/p45/chars/vorgane/"   # P4.7 : trois-quarts, pattes au sol (planche du créateur)
## P4.1 — personnages nets : dossier de sprites et facteur « hauteur à l'écran (px natifs P4) / hauteur du sprite »
## (la taille validée à l'écran est conservée : Aren 28 px natifs, Ilya 26, garde 25 ; ×2,5 par défaut).
## P4.5 : sprites à 1 pixel = 1 pixel d'écran au zoom ×2,5 (k = hauteur à l'écran en px natifs / hauteur du sprite) ;
## mêmes tailles à l'écran que P4.4 pour Aren (28) et Ilya (26) ; garde en armure un peu plus grand (30).
const CHARS := {
	"aren": {"dir": "res://art/p45/chars/aren/", "k": 25.2 / 63.0},     # P4.7 : 63 px, silhouette comparable à Ilya
	"ilya": {"dir": "res://art/p45/chars/ilya/", "k": 26.0 / 65.0},
	"pnj": {"dir": "res://art/p45/chars/garde/", "k": 30.0 / 75.0},
}
const MONSTER_K := 0.4                     # P4.7 : 1 px de sprite = 1 px d'écran à ×2,5, comme les personnages
const MONSTER_FRAMES := 24                 # attente, respiration, il flaire le sol, se redresse
const CHAR_TINT := Color(0.93, 0.91, 1.0)   # éclairage commun du crépuscule
const DEMO_HP_MULT := 0.5
const TILT_SH = preload("res://src/p4/tilt_shift_p41.gdshader")
## P4.1 — variantes de caméra à comparer (touche C, ou --camera=). B28 reste la caméra par défaut (validée) ;
## P30 et P38 rapprochent la vue de l'image de référence HD-2D : perspective (le lointain rapetisse), paysage
## visible en haut, flou de distance. Même taille du héros à l'écran aux trois zooms dans toutes les variantes.
const CAMS := {
	"P30": {"label": "P30 — perspective, plongée 30°, champ 30°, flou de distance léger (défaut P4.4)", "pitch": 30.0, "persp": true, "fov": 30.0, "tilt": 0.3},
	"B28": {"label": "B28 — orthographique, plongée 28° (référence P4 / P4.1)", "pitch": 28.0, "persp": false},
	"P38": {"label": "P38 — perspective, plongée 38°, champ 22°, flou de distance léger", "pitch": 38.0, "persp": true, "fov": 22.0, "tilt": 0.3},
}
const CAM_ORDER := ["P30", "B28", "P38"]
const BANK_TINT := Color(0.86, 0.78, 0.86)        # berge BER-01 moins orangée (raccord avec le talus et l'eau)
## Falaises de fond (non jouables) : [z arrière, z du pied, hauteur, teinte de perspective atmosphérique]
const BANDS := [[-3.0, 2.0, 3.2, Color(0.8, 0.82, 0.95)], [-8.0, -3.0, 5.6, Color(0.64, 0.68, 0.9)], [-14.0, -8.0, 8.4, Color(0.52, 0.56, 0.86)]]

## rôle -> [texture, taille d'un carreau (m), teinte]
const MATS := {
	"paves": ["mat/sol_paves.png", 4.0, Color(1, 1, 1)],
	"herbe": ["mat/sol_herbe.png", 6.0, Color(0.94, 0.98, 1.0)],
	"terre": ["mat/sol_terre.png", 5.0, Color(1, 1, 1)],
	"decor": ["mat/sol_herbe.png", 6.0, Color(0.8, 0.86, 0.92)],
	"roche": ["mat/roche.png", 4.0, Color(1, 1, 1)],
	"pierre": ["batiment/pierre_taille.png", 2.6, Color(0.8, 0.77, 0.78)],
	"marche": ["batiment/pierre_taille.png", 3.2, Color(1.0, 0.96, 0.98)],
	"plancher": ["pont/planches.png", 2.0, Color(0.6, 0.55, 0.6)],
	"bois": ["pont/planches.png", 2.0, Color(0.52, 0.45, 0.46)],
	"toit": ["batiment/toit_violet.png", 2.4, Color(0.84, 0.82, 0.9)],
	"facade": ["batiment/facade_colombage.png", 4.0, Color(1, 1, 1)],
}
const ROLE_MAT := {"terrasse": "paves", "terrasse_face": "pierre", "escalier": "marche", "pont": "plancher", "garde_corps": "bois",
	"berge": "terre", "muret": "pierre", "mur": "pierre", "caisse": "bois", "porte": "bois", "borne": "bois"}
## accessoire à collision (préfixe d'identifiant) -> [image, largeur (m), ancrage (fraction de hauteur sous le pied)]
const PROPS := {
	"prop_caisses": ["props/cais01_caisse.png", 1.15, 0.1], "prop_caisse_terrasse": ["props/cais01_caisse.png", 1.0, 0.1],
	"prop_tonneaux": ["props/tont01_tonneau.png", 0.9, 0.08], "prop_chariot": ["props/chart01_chariot.png", 2.7, 0.1],
	"prop_buches": ["props/bois02_buches.png", 2.2, 0.12], "prop_banc": ["props/banc01_banc.png", 1.7, 0.1],
	"roc_": ["vegetation/roc01_rocher.png", 1.5, 0.14], "lant_": ["props/lant01_lanterne.png", 0.92, 0.05],
	"bann_": ["props/bann02_bleue.png", 1.1, 0.05],
}

var _mat_cache := {}
var _dialog
var _prompt: Label
var _title: Label
var _title_t := 0.0
var _monster: Node3D
var _monster_cfg := {}
var _engaging := false
var _hole := 0.0
var _lights: Array = []                   # [OmniLight3D, énergie de base, phase]
var _sun: DirectionalLight3D
var _interior := false
var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _auto_dialog_t := 0.0
var _monster_frames: Array = []
var _foot_cache := {}
## P4.5 — garde : courte ronde (carré de 1 m autour de son poste, 4 directions), pauses d'attente animée ; quand le
## héros approche (4 m) ou parle, il regagne son poste et se tourne vers lui. Collision et point de dialogue suivent.
const GUARD_ROUND := [Vector2(-0.5, -0.35), Vector2(0.45, -0.35), Vector2(0.45, 0.4), Vector2(-0.5, 0.4)]
const GUARD_SPEED := 1.1
var _guard_body: StaticBody3D
var _guard_post := Vector3.INF
var _guard_i := 0
var _guard_wait := 0.0
var cam_mode := "P30"
## scènes de comparaison F6 : caméra de départ
@export var camera_initiale := ""
var _tilt: ColorRect
var _monster_quad: MeshInstance3D


func _ready() -> void:
	_cli = parse_cli()
	variante = "B"                         # préférence validée : plongée 28°, héros centré
	if CAMS.has(camera_initiale):
		cam_mode = camera_initiale
	if CAMS.has(str(_cli.get("camera", "")).to_upper()):
		cam_mode = str(_cli["camera"]).to_upper()
	paysage = "aucun"                      # le paysage non jouable est construit ici (falaises, forêt), pas par P3-07
	arch_label = "P4 — avant-poste"
	for k in CHARS:
		Actor25.overrides[k] = CHARS[k]["dir"]
	get_tree().physics_interpolation = true
	s = Session25.new(self, arch_label)
	s.options["debug"] = _cli.has("debug")
	s.options["grid"] = false
	s.options["occlusion"] = 0             # pas de silhouette bleue : masquage localisé des occultants (shader)
	_apply_variante()
	s.arch = "P4.1 — avant-poste · " + CAMS[cam_mode]["label"]
	s.build_hud()
	s._help.text = "Flèches / ZQSD : marcher  ·  Maj : courir  ·  Molette : zoom ×2 / ×2,5 / ×3  ·  E : parler, examiner  ·  C : caméra (comparaison)  ·  R : retour à l'entrée  ·  F1 : infos"
	_build_ui()
	_build_tilt()
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
	# retour de combat : victoire -> on reprend où l'on était, le Vorgane a disparu ; défaite -> retour à l'entrée
	var returning: bool = GameState.explore_return == scene_file_path and GameState.last_battle_result != ""
	var arrive := Vector3.INF
	if returning and GameState.last_battle_result == "victory" and GameState.flags.has("p4_pos"):
		arrive = GameState.flags["p4_pos"]
	if GameState.autoplay or _cli.has("route"):
		print("P4 chargé : retour=%s, Vorgane vaincu=%s" % [GameState.last_battle_result if returning else "-", GameState.enemy_defeated])
	if returning:
		GameState.last_battle_result = ""
		GameState.from_zone = false
		if _cli.has("route_retour"):
			_cli["route"] = _cli["route_retour"]     # démonstration filmée : suite du parcours après le combat
		else:
			_cli.erase("route")
	_load(_cli.get("instance", ZONE), "instance", arrive)
	_apply_cli()
	if _cli.has("flou"):
		s.options["sharp"] = false
	if returning:
		s.toast("Le Vorgane est vaincu." if GameState.enemy_defeated else "Le groupe s'est replié dans la cour.", 3.0)


func _exit_tree() -> void:
	for k in CHARS:
		Actor25.overrides.erase(k)
	get_tree().physics_interpolation = false      # le combat (2D) garde son réglage d'origine


func _build_ui() -> void:
	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(590, 600)
	s.hud.add_child(_prompt)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", Color(0.96, 0.9, 0.74))
	_title.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
	_title.add_theme_constant_override("outline_size", 8)
	_title.position = Vector2(40, 34)
	s.hud.add_child(_title)
	_dialog = DialogueBox.new()
	s.hud.add_child(_dialog)
	_dialog.closed.connect(_on_dialog_closed)


func _env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.07, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.78)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = not _cli.has("noglow")
	env.glow_intensity = 0.55
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.95
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.04
	we.environment = env
	_env_res = env
	add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.basis = Basis.looking_at(Look.LIGHT_DIR.normalized(), Vector3.UP)
	_sun.light_color = Color(1.0, 0.84, 0.7)          # soleil bas du crépuscule
	_sun.light_energy = 0.82
	_sun.shadow_enabled = not _cli.has("noshadow")
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_sun.directional_shadow_max_distance = 120.0
	_sun.shadow_bias = 0.04
	_sun.shadow_opacity = 0.7
	add_child(_sun)


# ------------------------------------------------------------------------------------------------ matériaux
func _surf(key: String, hole := false, uv_mesh := false) -> ShaderMaterial:
	var ck := "%s|%s|%s" % [key, hole, uv_mesh]
	if _mat_cache.has(ck):
		return _mat_cache[ck]
	var d: Array = MATS[key]
	var mm := ShaderMaterial.new()
	mm.shader = SURF_SH
	mm.set_shader_parameter("tex", load(T + d[0]))
	mm.set_shader_parameter("tile_m", d[1])
	mm.set_shader_parameter("tint", d[2])
	mm.set_shader_parameter("hole", 1.0 if hole else 0.0)
	mm.set_shader_parameter("uv_mode", 1.0 if uv_mesh else 0.0)
	mm.set_shader_parameter("antitile", 1.0 if key in ["herbe", "decor", "terre", "roche"] else 0.0)
	_mat_cache[ck] = mm
	return mm


## Matériau par rôle : appelé aussi par les constructeurs P3 conservés (terrasse, escalier, tablier, murets).
func _mat(role: String, _c := Color(-1, 0, 0)) -> ShaderMaterial:
	return _surf(ROLE_MAT.get(role, role) if MATS.has(ROLE_MAT.get(role, role)) else "pierre")


func _tinted(key: String, tint: Color, hole := false) -> ShaderMaterial:
	var mm: ShaderMaterial = _surf(key, hole).duplicate()
	mm.set_shader_parameter("tint", tint)
	mm.set_shader_parameter("macro", 0.05)
	return mm


## P4.1 : version nettoyée (sans plaque de sol peinte) si elle existe dans art/p41/decor/, sinon l'original P4.
func _decor_path(tex_path: String) -> String:
	if tex_path.begins_with("decor/"):
		return P41 + tex_path
	var cleaned := P41 + "decor/" + tex_path.get_file()
	return cleaned if ResourceLoader.exists(cleaned) else T + tex_path


## Carte illustrée verticale tournée vers la caméra (azimut seul), pied posé en `foot` (repère Godot).
func _card(tex_path: String, foot: Vector3, width_m: float, o := {}) -> MeshInstance3D:
	var path := _decor_path(tex_path)
	var tex: Texture2D = load(path)
	var hw := width_m * float(tex.get_height()) / tex.get_width() / cos(World25.pitch)
	var anchor: float = o.get("anchor", 0.1)
	if path.begins_with(P41):
		# image nettoyée : le pied est le bas réel de l'image (plus de plaque de sol peinte sous lui)
		if not _foot_cache.has(path):
			_foot_cache[path] = float(tex.get_height() - tex.get_image().get_used_rect().end.y) / tex.get_height()
		anchor = _foot_cache[path] + 0.012
	# la partie de l'image sous le pied (herbes, racines) est ramenée vers la caméra pour rester devant le sol
	var shift: float = maxf(o.get("shift", 0.45), anchor * hw / sin(World25.pitch) + 0.06)
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(width_m, hw)
	mi.mesh = qm
	var mm := ShaderMaterial.new()
	mm.shader = CARD_SH
	mm.set_shader_parameter("tex", tex)
	mm.set_shader_parameter("tint", o.get("tint", Color(1, 1, 1)))
	mm.set_shader_parameter("sway", o.get("sway", 0.0))
	mm.set_shader_parameter("phase", foot.x * 1.7 + foot.z * 0.9)
	mm.set_shader_parameter("hole", 1.0 if o.get("hole", false) else 0.0)
	mm.set_shader_parameter("emit", o.get("emit", 0.0))
	mi.material_override = mm
	mi.basis = Basis(Vector3.UP, -World25.YAW)
	mi.position = foot + World25.cam_back() * (shift + o.get("layer", 0.0)) + Vector3.UP * (hw * (0.5 - anchor))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(o.get("parent", root) as Node3D).add_child(mi)
	if o.get("blob", 0.0) > 0.0:
		_blob(foot, o["blob"])
	return mi


func _blob(foot: Vector3, w: float, strength := 0.4) -> void:
	var blob := MeshInstance3D.new()
	var bq := QuadMesh.new()
	bq.size = Vector2(w, w * 0.62)
	blob.mesh = bq
	var bmat := ShaderMaterial.new()
	bmat.shader = BLOB_SH
	bmat.set_shader_parameter("strength", strength)
	blob.material_override = bmat
	blob.rotation = Vector3(-PI / 2, -World25.YAW, 0)
	blob.position = foot + Vector3(0, 0.03, 0)
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(blob)


## Bande de transition posée au sol : quadrilatère a0-a1 (bord « haut » de l'image) vers b0-b1, V de v0 à v1.
func _strip(tex_path: String, a0: Vector3, a1: Vector3, b0: Vector3, b1: Vector3, v0: float, v1: float, tile := 4.0, tint := Color(1, 1, 1)) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var u1 := a0.distance_to(a1) / tile
	var u0 := (a0.x + a0.z) / tile
	for q in [[a0, Vector2(u0, v0)], [a1, Vector2(u0 + u1, v0)], [b1, Vector2(u0 + u1, v1)], [a0, Vector2(u0, v0)], [b1, Vector2(u0 + u1, v1)], [b0, Vector2(u0, v1)]]:
		st.set_normal(Vector3.UP)
		st.set_uv(q[1])
		st.add_vertex(q[0])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mm := ShaderMaterial.new()
	mm.shader = DECAL_SH
	mm.set_shader_parameter("tex", load(T + tex_path))
	mm.set_shader_parameter("tint", tint * Color(0.74, 0.72, 0.78))
	mi.material_override = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)


## Maillage libre à UV explicites : liste de faces [points (3 ou 4), uv (3 ou 4)].
func _faces(faces: Array, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		var p: Array = f[0]
		var uv: Array = f[1]
		var n: Vector3 = ((p[1] as Vector3) - p[0]).cross((p[2] as Vector3) - p[0]).normalized() * -1.0
		for i in ([0, 1, 2] if p.size() == 3 else [0, 1, 2, 0, 2, 3]):
			st.set_normal(n)
			st.set_uv(uv[i])
			st.add_vertex(p[i])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	(parent if parent != null else root).add_child(mi)
	return mi


func _light(pos: Vector3, energy: float, rng := 5.5, col := Color(1.0, 0.7, 0.4)) -> void:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.3
	l.shadow_enabled = false
	l.position = pos
	root.add_child(l)
	_lights.append([l, energy, pos.x * 3.1 + pos.z * 1.3])


func _halo(pos: Vector3, size: float, strength := 0.5) -> void:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(size, size / cos(World25.pitch))
	mi.mesh = qm
	var mm := ShaderMaterial.new()
	mm.shader = HALO_SH
	mm.set_shader_parameter("tex", load(T + "fx/halo.png"))
	mm.set_shader_parameter("strength", strength)
	mm.set_shader_parameter("phase", pos.x * 2.3 + pos.z)
	mi.material_override = mm
	mi.basis = Basis(Vector3.UP, -World25.YAW)
	mi.position = pos + World25.cam_back() * 0.9
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)


# ------------------------------------------------------------------------------------------------ chargement
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
	_lights.clear()
	_monster = null
	_rng.seed = 4072
	world = World25.load_world(file, m)
	var p4: Dictionary = world.adj.get("p4", {})
	_interior = p4.get("interieur", false)
	if not _interior:
		world.extend_view([Vector3(0, 0, 5.5), Vector3(world.extent.end.x, 0, 5.5)])
	_sun.visible = not _interior
	_env_res.ambient_light_color = Color(0.5, 0.44, 0.5) if _interior else Color(0.5, 0.5, 0.78)
	_env_res.ambient_light_energy = 0.95 if _interior else 0.85
	for e in world.elements:
		_build(e)
	if _interior:
		_build_interior()
	else:
		_build_exterior(p4)
	if not world.npc.is_empty():
		var n: Dictionary = world.npc
		var a := _make_actor("pnj", n["sprite"])
		root.add_child(a["node"])
		a["node"].position = World25.g3(n["p"])
		a["actor"].face_toward(Vector2(-1, 0.4))
		_guard_body = _obstacle_cyl(World25.g3(n["p"]), n["r"], 1.8)
		_guard_post = n["p"]
		_guard_i = 0
		_guard_wait = 1.5
	_monster_cfg = p4.get("monstre", {})
	if not _monster_cfg.is_empty() and not GameState.enemy_defeated:
		_spawn_monster()
	_build_overlay()
	s.set_world(world, arrive)
	teleport(s.hero, s.companion)
	apply_options()
	_title.text = p4.get("nom", "")
	_title_t = 3.5


func _build(e: Dictionary) -> void:
	var id: String = e.get("id", "")
	match e["type"]:
		"floor":
			var r: Rect2 = e["rect"]
			if e["role"] == "decor":
				_decor_floor(e)
				return
			var key: String = world.adj.get("p4", {}).get("sols", {}).get(id, "herbe")
			var th := 0.3
			_box_mesh(_rect_center(r, e["h"] - th, e["h"]), Vector3(r.size.x, th, r.size.y), _surf(key))
			_static_box(_rect_center(r, e["h"] - th, e["h"]), Vector3(r.size.x, th, r.size.y), L_FLOOR)
		"block":
			if e["role"] == "terrasse":
				super._build(e)
			else:
				_build_obstacle(e)
		"water":
			_build_water(e)
		"bank":
			super._build(e)
			_bank_overlay(e)
		"rail":
			_build_rail(e)
		"border":
			if e["role"] == "haie":
				_build_hedge(e)
			else:
				super._build(e)
		"gate":
			pass                                   # portes dessinées par le bâtiment / la salle
		"post":
			var c: Vector2 = e["c"]
			if _interior:
				_obstacle_cyl(Vector3(c.x, e["h"], c.y), e["r"], e["height"])
				if e["id"] == "ratelier":
					_box_mesh(Vector3(c.x, 0.7, c.y), Vector3(0.3, 1.4, 0.9), _surf("bois"))
				return
			_card("props/pan01_panneau.png", Vector3(c.x, e["h"], c.y), 1.0, {"anchor": 0.07, "blob": 0.7})
			_obstacle_cyl(Vector3(c.x, e["h"], c.y), e["r"], e["height"])
		"tree":
			_build_tree(e)
		"house":
			_build_house(e)
		"deck":
			super._build(e)
			_deck_details(e)
		_:
			super._build(e)


func _decor_floor(e: Dictionary) -> void:
	# sol de décor non praticable : étendu loin au-delà des vues (jamais de vide), mais interrompu par la rivière
	var r: Rect2 = e["rect"]
	var x0 := r.position.x - 40.0
	var x1 := r.end.x + 40.0
	if not _interior and world.elements.any(func(q): return q["type"] == "water"):
		if e["id"] == "decor_0":
			x1 = r.end.x
		else:
			x0 = r.position.x
	var c := Vector3((x0 + x1) / 2.0, e["h"] - 0.17, r.get_center().y)
	var size := Vector3(x1 - x0, 0.3, r.size.y + 80.0)
	_static_box(c, size, L_NOWALK)
	var mi := _box_mesh(c, size, _interior_dark() if _interior else _surf("decor"))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _interior_dark() -> StandardMaterial3D:
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = Color(0.035, 0.03, 0.05)
	return sm


func _prop_def(id: String) -> Array:
	for k in PROPS:
		if id.begins_with(k):
			return PROPS[k]
	return []


func _build_obstacle(e: Dictionary) -> void:
	var id: String = e["id"]
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	var size := Vector3(r.size.x, h1 - h0, r.size.y)
	_static_box(_rect_center(r, h0, h1), size, L_OBST)
	var foot := Vector3(r.get_center().x, h0, r.get_center().y)
	if id.begins_with("mur_") or id.begins_with("tour_"):
		_build_wall(e)
	elif id.begins_with("int_"):
		_build_furniture(e)
	elif id.begins_with("lant_"):
		_card("props/lant01_lanterne.png", foot, 0.92, {"anchor": 0.05, "emit": 1.6, "blob": 0.6})
		var lamp := foot + Vector3(0, 1.45, 0) + World25.cam_right() * -0.27
		_light(lamp + World25.cam_back() * 0.5, 1.5)
		_halo(lamp, 1.5)
	elif id.begins_with("bann_"):
		_card("props/bann02_bleue.png", foot, 1.1, {"anchor": 0.05, "sway": 0.02, "blob": 0.6})
	else:
		var d := _prop_def(id)
		if d.is_empty():
			_box_mesh(_rect_center(r, h0, h1), size, _surf("bois"))
			return
		if id == "prop_tonneaux":
			_card(d[0], foot + Vector3(-0.4, 0, 0), d[1], {"anchor": d[2], "blob": 0.9})
			_card(d[0], foot + Vector3(0.42, 0, 0.1), d[1], {"anchor": d[2], "blob": 0.9})
		else:
			_card(d[0], foot, d[1], {"anchor": d[2], "blob": d[1] * 0.9})
		if id == "prop_caisses":
			_card("props/sac01_sacs.png", foot + Vector3(1.0, 0, 0.25), 1.0, {"anchor": 0.08})


## Muraille : pierre de taille, créneaux ; tours de la porte coiffées d'un toit violet.
func _build_wall(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	var tall: bool = h1 - h0 > 1.5
	var mat := _surf("pierre", tall)
	_box_mesh(_rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), mat)
	if e["id"].begins_with("tour_"):
		var c := Vector3(r.get_center().x, h1, r.get_center().y)
		var hx := r.size.x / 2.0 + 0.25
		var hz := r.size.y / 2.0 + 0.25
		var top := c + Vector3(0, 1.25, 0)
		var cs := [c + Vector3(-hx, 0, -hz), c + Vector3(hx, 0, -hz), c + Vector3(hx, 0, hz), c + Vector3(-hx, 0, hz)]
		var fs: Array = []
		for i in 4:
			fs.append([[cs[(i + 1) % 4], top, cs[i]], [Vector2(0, 1), Vector2(0.5, 0), Vector2(1, 1)]])
		_faces(fs, _surf("toit", true, true))
		return
	if not tall:
		_box_mesh(_rect_center(r.grow(0.05), h1, h1 + 0.08), Vector3(r.size.x + 0.1, 0.08, r.size.y + 0.1), _tinted("pierre", Color(1.12, 1.1, 1.12)))
		return
	var along_x := r.size.x > r.size.y
	var length := r.size.x if along_x else r.size.y
	var n := int(length / 1.2)
	var pitch_m := length / n
	for i in n:
		var t := (i + 0.5) * pitch_m
		var c := Vector3(r.position.x + t, h1 + 0.22, r.get_center().y) if along_x else Vector3(r.get_center().x, h1 + 0.22, r.position.y + t)
		_box_mesh(c, Vector3(0.62 if along_x else r.size.x, 0.44, r.size.y if along_x else 0.62), mat)


func _build_rail(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var h: float = e["h"]
	_static_box(_rect_center(r, h, h + e["height"]), Vector3(r.size.x, e["height"], r.size.y), L_OBST)
	var zc := r.get_center().y
	var mat := _surf("bois")
	var n := int(round(r.size.x / 1.5))
	for i in n + 1:
		var x := r.position.x + r.size.x * i / n
		_box_mesh(Vector3(x, h + 0.5, zc), Vector3(0.16, 1.0, 0.16), mat)
	for hh in [0.42, 0.82]:
		_box_mesh(Vector3(r.get_center().x, h + hh, zc), Vector3(r.size.x, 0.09, 0.08), mat)


func _deck_details(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var mat := _tinted("bois", Color(0.55, 0.48, 0.46))
	for z in [r.position.y + 0.1, r.end.y - 0.1]:
		_box_mesh(Vector3(r.get_center().x, e["h"] - 0.3, z), Vector3(r.size.x, 0.22, 0.2), mat)
		for x in [r.position.x + 2.2, r.end.x - 2.2]:
			_box_mesh(Vector3(x, e["h"] - 0.75, z), Vector3(0.26, 1.1, 0.26), mat)


func _build_hedge(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	_static_box(_rect_center(r, e["h"], e["h"] + e["height"]), Vector3(r.size.x, e["height"], r.size.y), L_OBST)
	var a: Vector2 = e["a"]
	var b: Vector2 = e["b"]
	var n := maxi(1, int(a.distance_to(b) / 1.15))
	var imgs := ["vegetation/buis02_dense.png", "vegetation/buis01_violet.png", "vegetation/buis02_dense.png", "vegetation/buis05_pourpre.png"]
	var c := r.get_center()
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		p = Vector2(c.x, p.y) if absf(a.x - b.x) < 0.01 else Vector2(p.x, c.y)
		p += Vector2(_rng.randf_range(-0.12, 0.12), _rng.randf_range(-0.12, 0.12))
		_card(imgs[_rng.randi() % imgs.size()], Vector3(p.x, e["h"], p.y), _rng.randf_range(1.5, 1.9), {"anchor": 0.12, "sway": 0.012, "blob": 1.3})


func _build_water(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(r.size.x, 0.1, r.size.y)
	mi.mesh = bm
	var wm := ShaderMaterial.new()
	wm.shader = EAU_SH
	wm.set_shader_parameter("water_albedo", load(T + "mat/eau_courante.png"))
	wm.set_shader_parameter("shallow_albedo", load(T + "mat/eau_galets.png"))
	wm.set_shader_parameter("bank_x0", r.position.x)
	wm.set_shader_parameter("bank_x1", r.end.x)
	_water_mats.append(wm)
	mi.material_override = wm
	mi.position = _rect_center(r, e["h"] - 0.1, e["h"])
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	_static_box(_rect_center(r, e["h"] - 0.6, e["h"]), Vector3(r.size.x, 0.6, r.size.y), L_NOWALK)


## Berge : calque BER-01 (herbe, terre, galets, puis transparent) du sol vers l'eau, par-dessus la pente de terre.
func _bank_overlay(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var ws: float = e["water_side"]
	var xt := r.position.x if ws > 0 else r.end.x      # haut de berge (côté sol)
	var xb := r.end.x if ws > 0 else r.position.x      # bas de berge (côté eau)
	var z0 := r.position.y
	var z1 := r.end.y
	var ht: float = e["h_top"] + 0.02
	var hb: float = e["h_bottom"] + 0.03
	var pts := [[xt - ws * 0.7, ht, 0.30], [xt, ht, 0.42], [xb, hb, 0.60], [xb + ws * 0.45, hb, 0.70]]
	for i in 3:
		var p: Array = pts[i]
		var q: Array = pts[i + 1]
		if ws > 0:
			_strip("mat/berge.png", Vector3(p[0], p[1], z1), Vector3(p[0], p[1], z0), Vector3(q[0], q[1], z1), Vector3(q[0], q[1], z0), p[2], q[2], 4.0, BANK_TINT)
		else:
			_strip("mat/berge.png", Vector3(p[0], p[1], z0), Vector3(p[0], p[1], z1), Vector3(q[0], q[1], z0), Vector3(q[0], q[1], z1), p[2], q[2], 4.0, BANK_TINT)


func _build_tree(e: Dictionary) -> void:
	var c: Vector2 = e["c"]
	var foot := Vector3(c.x, e["h"], c.y)
	var cfg: Dictionary = world.adj.get("p4", {}).get("arbres", {}).get(e["id"], {"sprite": "vegetation/arb02_rond.png", "larg_m": 4.4})
	var w: float = cfg["larg_m"]
	var cards: Array = []
	if cfg.get("pilote", false):
		# pilote ARB-01 : trois calques du même canevas 512 × 512 (pivot au pied : 494 / 512), feuillages animés
		var o := {"anchor": 18.0 / 512.0, "shift": 0.6, "hole": true}
		var px_m := w / 330.0 * 512.0                    # le feuillage occupe ~330 px du canevas
		cards.append(_card("arbre/arb01_feuillage_arriere.png", foot, px_m, o.merged({"layer": -0.12, "sway": 0.028})))
		cards.append(_card("arbre/arb01_tronc.png", foot, px_m, o))
		cards.append(_card("arbre/arb01_feuillage_avant.png", foot, px_m, o.merged({"layer": 0.12, "sway": 0.022})))
	else:
		cards.append(_card(cfg["sprite"], foot, w, {"sway": 0.03, "hole": true}))
	# raccord au terrain : ombre de contact large et douce + touffes aux couleurs du sol autour des racines
	_blob(foot, w * 0.85, 0.5)
	_blob(foot, w * 0.4, 0.35)
	for k in 5:
		var a := -PI * 0.15 + PI * 1.3 * k / 4.0 + _rng.randf_range(-0.2, 0.2)
		var rr: float = e["r"] + _rng.randf_range(0.15, 0.45)
		var q := Vector3(foot.x + cos(a) * rr * 1.2, foot.y, foot.z + sin(a) * rr * 0.8)
		_card("decor/touffe_sol_%d.png" % (k % 4), q, _rng.randf_range(0.6, 0.95), {"shift": 0.05 + 0.3 * sin(a), "sway": 0.012})
	var trunk := _obstacle_cyl(foot, e["r"], e["trunk_h"])
	var occ := StaticBody3D.new()
	occ.collision_layer = L_OCC
	occ.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = e["foliage_r"] * 0.95
	cs.shape = sph
	occ.add_child(cs)
	occ.position = foot + Vector3(0, e["foliage_h"], 0)
	root.add_child(occ)
	trunk.set_meta("arbre", true)


## Bâtiment principal : volume 3D (soubassement de pierre, étage à colombages, toit violet à deux pans, pignon
## d'entrée), fenêtres chaudes ; porte au sud, alignée sur l'escalier.
func _build_house(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	var hs := h0 + 1.0                              # haut du soubassement
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	var zc := r.get_center().y
	var xc := r.get_center().x
	var rh: float = e["roof"]
	var node := Node3D.new()
	root.add_child(node)
	_box_mesh(_rect_center(r.grow(0.04), h0, hs), Vector3(r.size.x + 0.08, hs - h0, r.size.y + 0.08), _surf("pierre", true), node)
	var fac := _surf("facade", true, true)
	var fs: Array = []
	var uw := r.size.x / 4.0
	var ud := r.size.y / 4.0
	fs.append([[Vector3(x0, h1, z1), Vector3(x1, h1, z1), Vector3(x1, hs, z1), Vector3(x0, hs, z1)], [Vector2(0, 0), Vector2(uw, 0), Vector2(uw, 1), Vector2(0, 1)]])
	fs.append([[Vector3(x1, h1, z0), Vector3(x0, h1, z0), Vector3(x0, hs, z0), Vector3(x1, hs, z0)], [Vector2(0, 0), Vector2(uw, 0), Vector2(uw, 1), Vector2(0, 1)]])
	fs.append([[Vector3(x0, h1, z0), Vector3(x0, h1, z1), Vector3(x0, hs, z1), Vector3(x0, hs, z0)], [Vector2(0, 0), Vector2(ud, 0), Vector2(ud, 1), Vector2(0, 1)]])
	fs.append([[Vector3(x1, h1, z1), Vector3(x1, h1, z0), Vector3(x1, hs, z0), Vector3(x1, hs, z1)], [Vector2(0, 0), Vector2(ud, 0), Vector2(ud, 1), Vector2(0, 1)]])
	# pignons ouest et est
	fs.append([[Vector3(x0, h1, z0), Vector3(x0, h1 + rh, zc), Vector3(x0, h1, z1)], [Vector2(0, 1), Vector2(ud / 2.0, 1.0 - rh / 2.0), Vector2(ud, 1)]])
	fs.append([[Vector3(x1, h1, z1), Vector3(x1, h1 + rh, zc), Vector3(x1, h1, z0)], [Vector2(0, 1), Vector2(ud / 2.0, 1.0 - rh / 2.0), Vector2(ud, 1)]])
	# pignon d'entrée (au-dessus de la porte)
	var gw := 1.5
	var gh := 1.25
	var zg := z1 + 0.28
	fs.append([[Vector3(xc - gw, h1 - 0.02, zg), Vector3(xc, h1 + gh, zg), Vector3(xc + gw, h1 - 0.02, zg)], [Vector2(0.02, 0.98), Vector2(gw / 4.0, 0.98 - gh / 2.0), Vector2(gw / 2.0, 0.98)]])
	fs.append([[Vector3(xc - gw, h1 - 0.02, zg), Vector3(xc + gw, h1 - 0.02, zg), Vector3(xc + gw, h1 - 0.3, zg), Vector3(xc - gw, h1 - 0.3, zg)],
		[Vector2(0, 0), Vector2(gw / 2.0, 0), Vector2(gw / 2.0, 0.06), Vector2(0, 0.06)]])
	var walls := _faces(fs, fac, node)
	# toiture : deux pans, débord de 0,4 m
	var ov := 0.42
	var half := r.size.y / 2.0
	var drop := rh * ov / half
	var sl := sqrt(half * half + rh * rh) * (1.0 + ov / half)
	var tu := (r.size.x + 2 * ov) / 2.4
	var tv := sl / 2.4
	var roof_m := _surf("toit", true, true)
	var rf: Array = []
	rf.append([[Vector3(x0 - ov, h1 + rh, zc), Vector3(x1 + ov, h1 + rh, zc), Vector3(x1 + ov, h1 - drop, z1 + ov), Vector3(x0 - ov, h1 - drop, z1 + ov)],
		[Vector2(0, 0), Vector2(tu, 0), Vector2(tu, tv), Vector2(0, tv)]])
	rf.append([[Vector3(x1 + ov, h1 + rh, zc), Vector3(x0 - ov, h1 + rh, zc), Vector3(x0 - ov, h1 - drop, z0 - ov), Vector3(x1 + ov, h1 - drop, z0 - ov)],
		[Vector2(0, 0), Vector2(tu, 0), Vector2(tu, tv), Vector2(0, tv)]])
	# petit toit du pignon d'entrée : faîtage perpendiculaire, raccordé au pan sud
	var zr := zc + half * (1.0 - gh / rh)
	var gz := zg + 0.22
	var gx := gw + 0.3
	var gd := gh * 0.3 / gw
	for sgn in [-1.0, 1.0]:
		var pa := Vector3(xc + sgn * gx, h1 - gd, gz)
		var pb := Vector3(xc, h1 + gh + 0.02, gz)
		var pc := Vector3(xc, h1 + gh + 0.02, zr)
		var pd := Vector3(xc + sgn * gx, h1 - gd, z1 + 0.1)
		var uvq := [Vector2(0, 0.8), Vector2(0, 0), Vector2(0.9, 0), Vector2(0.5, 0.8)]
		rf.append([[pa, pb, pc, pd] if sgn < 0 else [pb, pa, pd, pc], uvq if sgn < 0 else [uvq[1], uvq[0], uvq[3], uvq[2]]])
	var roof := _faces(rf, roof_m, node)
	# faîtière et cheminée
	_box_mesh(Vector3(xc, h1 + rh + 0.03, zc), Vector3(r.size.x + 2 * ov, 0.12, 0.2), _tinted("bois", Color(0.42, 0.34, 0.4), true), node)
	_box_mesh(Vector3(x1 - 1.3, h1 + rh * 0.55 + 0.6, zc - 0.7), Vector3(0.62, 1.6, 0.62), _surf("pierre", true), node)
	# porte et fenêtres (quads à découpe alpha ; les fenêtres émettent)
	_wall_quad("batiment/porte.png", Vector3(xc, h0 + 0.98, z1 + 0.06), Vector2(1.2, 1.95), 0.0, 0.0, node)
	for wx in [x0 + 1.05, x0 + 2.25, x1 - 2.25, x1 - 1.05]:
		_wall_quad("batiment/fenetre.png", Vector3(wx, hs + 1.02, z1 + 0.03), Vector2(0.72, 0.86), 0.0, 1.5, node)
	_wall_quad("batiment/fenetre.png", Vector3(xc, h1 + 0.5, zg + 0.02), Vector2(0.56, 0.66), 0.0, 1.5, node)
	for wz in [z0 + 1.1, z1 - 1.1]:
		_wall_quad("batiment/fenetre.png", Vector3(x0 - 0.03, hs + 1.02, wz), Vector2(0.72, 0.86), -PI / 2.0, 1.5, node)
	_light(Vector3(xc, h0 + 1.5, z1 + 0.9), 1.3, 4.5)
	_halo(Vector3(xc - 0.95, h0 + 1.75, z1 + 0.2), 1.1, 0.4)
	_halo(Vector3(xc + 0.95, h0 + 1.75, z1 + 0.2), 1.1, 0.4)
	# collisions : murs (obstacle) et toit (occultant sans collision)
	_static_box(_rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), L_OBST)
	var rs := StaticBody3D.new()
	rs.collision_layer = L_OCC
	rs.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(r.size.x + 0.8, rh, r.size.y + 0.8)
	cs.shape = bs
	rs.add_child(cs)
	rs.position = Vector3(xc, h1 + rh / 2.0, zc)
	root.add_child(rs)


func _wall_quad(tex_path: String, center: Vector3, size: Vector2, yaw: float, emission: float, parent: Node3D) -> void:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	mi.mesh = qm
	var sm := StandardMaterial3D.new()
	var tex: Texture2D = load(T + tex_path)
	sm.albedo_texture = tex
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	sm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	sm.roughness = 1.0
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission > 0.0:
		sm.emission_enabled = true
		sm.emission_texture = tex
		sm.emission_energy_multiplier = emission
	mi.material_override = sm
	mi.position = center
	mi.rotation.y = yaw
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


# ------------------------------------------------------------------------------------------------ extérieur
func _walkable(p: Vector2) -> bool:
	for reg in world.regions:
		if (reg["rect"] as Rect2).grow(0.9).has_point(p):
			return true
	return false


func _build_exterior(p4: Dictionary) -> void:
	# linteau de la porte fortifiée (entre les deux tours)
	_box_mesh(Vector3(20.4, 3.05, 16.0), Vector3(0.9, 0.7, 2.4), _surf("pierre", true))
	_box_mesh(Vector3(20.4, 2.62, 16.0), Vector3(1.0, 0.16, 2.4), _surf("bois", true))
	_halo(Vector3(19.6, 2.05, 14.95), 1.2, 0.45)
	_halo(Vector3(19.6, 2.05, 17.05), 1.2, 0.45)
	_light(Vector3(19.3, 2.0, 16.0), 1.2, 5.0)
	# chemins de terre + calques TRS-01 (herbe sur terre) sur les deux bords
	for c in p4.get("chemins", []):
		var r := Rect2(c[0], c[1], c[2] - c[0], c[3] - c[1])
		var mi := _box_mesh(_rect_center(r, 0.0, 0.012), Vector3(r.size.x, 0.012, r.size.y), _surf("terre"))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var y := 0.02
		_strip("mat/trs_herbe_terre.png", Vector3(r.position.x, y, r.position.y - 0.55), Vector3(r.end.x, y, r.position.y - 0.55),
			Vector3(r.position.x, y, r.position.y + 0.75), Vector3(r.end.x, y, r.position.y + 0.75), 0.3, 0.68)
		_strip("mat/trs_herbe_terre.png", Vector3(r.end.x, y, r.end.y + 0.55), Vector3(r.position.x, y, r.end.y + 0.55),
			Vector3(r.end.x, y, r.end.y - 0.75), Vector3(r.position.x, y, r.end.y - 0.75), 0.3, 0.68)
	# P4.1 — relief non jouable : falaises irrégulières (strates, talus de terre, roches, herbe en crête) au lieu de
	# boîtes lisses. Les lignes données sont les PIEDS des talus : la limite praticable (plaine, y = 6) n'est pas
	# déplacée ; aucune collision nouvelle (le plateau reste hors de la surface praticable, comme en P4).
	var pl: Dictionary = p4.get("plateau", {})
	if not pl.is_empty():
		var q: Array = pl["rect"]
		_cliff(PackedVector2Array([Vector2(q[0], q[1]), Vector2(q[0], q[3]), Vector2(q[2], q[3])]), 0.0, pl["h"],
			{"depth": q[3] - q[1] - 0.2, "talus": 0.55, "seed": 3.0, "rocks": 1.0})
	for band in BANDS:
		var tint: Color = band[3]
		var zf: float = band[1]
		_cliff(PackedVector2Array([Vector2(-60.0, zf), Vector2(22.6, zf), Vector2(22.6, band[0])]), 0.0, band[2],
			{"depth": zf - band[0], "talus": 0.9, "seed": band[2] * 7.0, "tint": tint, "rocks": 0.6})
		_cliff(PackedVector2Array([Vector2(29.4, band[0]), Vector2(29.4, zf), Vector2(110.0, zf)]), 0.0, band[2],
			{"depth": zf - band[0], "talus": 0.9, "seed": band[2] * 11.0, "tint": tint, "rocks": 0.6})
	# forêt et végétation de décor (non jouable), tirage déterministe
	var trees := ["vegetation/arb02_rond.png", "vegetation/arb03_foret.png", "vegetation/arb02_rond.png", "vegetation/arb05_fleuri.png"]
	for i in 150:
		var p := Vector2(_rng.randf_range(-24.0, 70.0), _rng.randf_range(-13.6, 5.0))
		if p.x > 21.8 and p.x < 30.2:
			continue
		var h := -1.0
		var tint := Color(0.94, 0.94, 1.0)
		for band in BANDS:
			if p.y > band[0] + 0.3 and p.y < band[1] - 1.1:
				h = band[2]
				tint = band[3]
		var q: Array = pl.get("rect", [0, 0, 0, 0])
		if h < 0.0 and p.x > q[0] + 1.0 and p.y > q[1] + 0.3 and p.y < q[3] - 1.1:
			h = pl["h"]
		if h < 0.0 or (p.x > 2.0 and p.x < 21.6 and h < 3.0):
			continue                                   # pas d'arbre dans les murailles ni dans le vide
		_card(trees[i % trees.size()], Vector3(p.x, h, p.y), _rng.randf_range(3.6, 5.2), {"anchor": 0.03, "sway": 0.03, "tint": tint})
		_blob(Vector3(p.x, h, p.y), 2.6, 0.42)
	var low := ["vegetation/buis01_violet.png", "vegetation/buis02_dense.png", "vegetation/buis05_pourpre.png", "vegetation/herb02_touffe.png",
		"vegetation/fleur04_lavande.png", "vegetation/fleur01_marguerites.png", "vegetation/herb02_touffe.png", "vegetation/roc01_rocher.png"]
	var wd := [1.6, 1.6, 1.4, 1.0, 0.8, 0.8, 1.0, 1.4]
	for i in 260:
		var p := Vector2(_rng.randf_range(-14.0, 62.0), _rng.randf_range(6.0, 40.0))
		if p.x > 22.3 and p.x < 29.7:
			continue
		var k := _rng.randi() % low.size()
		var inside := _walkable(p)
		if inside:
			# dans l'aire de jeu : seulement de petites touffes et fleurs sans collision, sur l'herbe, hors chemin
			if k < 3 or k == 7 or p.x < 20.8 or (p.y > 14.2 and p.y < 17.8):
				continue
			if world.surface_at(p, 0.0).is_empty() or not world.stand(p, 0.0):
				continue
		_card(low[k], Vector3(p.x, 0.0, p.y), wd[k] * _rng.randf_range(0.85, 1.15), {"anchor": 0.13, "sway": 0.012 if k != 7 else 0.0})
	# P4.1 — berges : galets et roches au pied de la pente (zone non praticable), plus de transition franche sol / eau
	for i in 70:
		var z := _rng.randf_range(-6.0, 40.0)
		if z > 13.9 and z < 18.1:
			continue                                         # dégagement du pont
		var west := i % 2 == 0
		var x := _rng.randf_range(23.2, 23.85) if west else _rng.randf_range(28.15, 28.8)
		var rr := _rng.randf_range(0.1, 0.28)
		_rock(Vector3(x, -0.35 + rr * 0.3 + (0.25 if (west and x < 23.5) or (not west and x > 28.5) else 0.0), z), rr, Color(0.85, 0.85, 0.9))
	# roseaux le long des berges
	for i in 26:
		var z := _rng.randf_range(-2.0, 38.0)
		if z > 13.6 and z < 18.4:
			continue
		var west := i % 2 == 0
		_card("vegetation/rose01_massette.png", Vector3(23.75 if west else 28.25, -0.3, z), _rng.randf_range(1.1, 1.5), {"anchor": 0.1, "sway": 0.03})


# ------------------------------------------------------------------------------------------------ falaises
static func _hash(n: float) -> float:
	return fposmod(sin(n * 127.1 + 311.7) * 43758.5453, 1.0)


static func _vnoise(x: float, sd: float) -> float:
	var i := floorf(x)
	var f := x - i
	var u := f * f * (3.0 - 2.0 * f)
	return lerpf(_hash(i + sd * 17.0), _hash(i + 1.0 + sd * 17.0), u)


## Falaise procédurale le long d'une ligne de PIEDS de talus (plan x, z). La paroi est en retrait côté roche (gauche
## de la ligne) : talus de terre, paroi rocheuse à strates et corniches, lèvre d'herbe, dessus herbeux sur `depth`.
func _cliff(toe: PackedVector2Array, h0: float, h1: float, o: Dictionary) -> void:
	var sd: float = o.get("seed", 1.0)
	var tint: Color = o.get("tint", Color(1, 1, 1))
	var talus: float = o.get("talus", 0.6)
	var depth: float = o.get("depth", 3.0)
	var hh := h1 - h0
	# échantillons le long de la ligne : position, normale (vers le côté praticable), abscisse curviligne
	var smp: Array = []
	var s_acc := 0.0
	for k in toe.size() - 1:
		var a := toe[k]
		var b := toe[k + 1]
		var d := (b - a).normalized()
		var n := Vector2(-d.y, d.x)
		var steps := maxi(1, int(a.distance_to(b) / 0.5))
		for i in steps + (1 if k == toe.size() - 2 else 0):
			var f := float(i) / steps
			var nn := n
			if i == 0 and k > 0:
				var dp := (toe[k] - toe[k - 1]).normalized()
				nn = (n + Vector2(-dp.y, dp.x)).normalized()
			smp.append([a.lerp(b, f), nn, s_acc + a.distance_to(b) * f])
		s_acc += a.distance_to(b)
	var R := maxi(4, int(hh / 0.45))
	var cols: Array = []                                      # par échantillon : points de la paroi, de bas en haut
	for sm in smp:
		var p: Vector2 = sm[0]
		var n: Vector2 = sm[1]
		var s: float = sm[2]
		var tw := talus * (0.65 + 0.7 * _vnoise(s * 0.45, sd + 3.0))
		var col: Array = []
		for k in R + 1:
			var v := float(k) / R
			var strata := floorf(v * 3.0 + _vnoise(s * 0.2, sd + 5.0) * 0.8)
			var r := tw + 0.06 + 0.5 * _vnoise(s * 0.45 + strata * 3.1, sd) + 0.18 * _vnoise(s * 1.9 + k * 0.7, sd + 1.0) + v * hh * 0.1
			if k == R:
				r -= 0.08                                     # la lèvre d'herbe déborde un peu
			var y := h0 + hh * v + (_vnoise(s * 1.3, sd + 2.0) - 0.5) * 0.12 * float(k > 0 and k < R)
			if k == R:
				# crête irrégulière : blocs plus ou moins hauts (silhouette naturelle, pas une arête droite)
				y += (_vnoise(s * 0.7, sd + 4.0) - 0.45) * minf(0.6, hh * 0.22) + (_vnoise(s * 2.6, sd + 8.0) - 0.5) * minf(0.2, hh * 0.08)
			var q := p - n * r
			col.append(Vector3(q.x, y, q.y))
		cols.append([col, p, n, s, tw])
	var face: Array = []
	var top: Array = []
	var tal: Array = []
	var out_n: Array = []
	for i in cols.size() - 1:
		var c0: Array = cols[i][0]
		var c1: Array = cols[i + 1][0]
		var s0: float = cols[i][3]
		var s1: float = cols[i + 1][3]
		for k in R:
			face.append([c0[k], c1[k], c1[k + 1], c0[k + 1], Vector2(s0, c0[k].y), Vector2(s1, c1[k].y), Vector2(s1, c1[k + 1].y), Vector2(s0, c0[k + 1].y)])
		# dessus herbeux
		var n0: Vector2 = cols[i][2]
		var n1: Vector2 = cols[i + 1][2]
		var b0: Vector3 = c0[R] - Vector3(n0.x, 0, n0.y) * depth
		var b1: Vector3 = c1[R] - Vector3(n1.x, 0, n1.y) * depth
		top.append([c0[R], c1[R], b1, b0])
		# talus : du pied de la paroi au pied du talus (bombé)
		var p0: Vector2 = cols[i][1]
		var p1: Vector2 = cols[i + 1][1]
		var m0: Vector3 = (c0[0] + Vector3(p0.x, h0, p0.y)) / 2.0 + Vector3(0, 0.12 + 0.1 * _vnoise(s0, sd + 9.0), 0)
		var m1: Vector3 = (c1[0] + Vector3(p1.x, h0, p1.y)) / 2.0 + Vector3(0, 0.12 + 0.1 * _vnoise(s1, sd + 9.0), 0)
		tal.append([c0[0] + Vector3(0, 0.22, 0), c1[0] + Vector3(0, 0.22, 0), m1, m0])
		tal.append([m0, m1, Vector3(p1.x, h0 + 0.015, p1.y), Vector3(p0.x, h0 + 0.015, p0.y)])
	var rock := _tinted("roche", tint)
	rock.set_shader_parameter("uv_mode", 1.0)
	rock.set_shader_parameter("tile_m", 1.0)
	_mesh_quads(face, rock, true, 1.0 / 3.0)
	_mesh_quads(top, _tinted("decor", tint), false)
	_mesh_quads(tal, _tinted("terre", tint * Color(0.62, 0.58, 0.62)), false)
	# lèvre d'herbe, touffes en crête et au pied, roches éboulées sur le talus
	var rocks_k: float = o.get("rocks", 1.0)
	var i := 0
	while i < cols.size():
		var col: Array = cols[i][0]
		var p: Vector2 = cols[i][1]
		var n: Vector2 = cols[i][2]
		var s: float = cols[i][3]
		var tw: float = cols[i][4]
		var tp: Vector3 = col[col.size() - 1]
		if _hash(s * 3.7 + sd) < 0.75:
			_card("decor/touffe_sol_%d.png" % (int(_hash(s + sd) * 4.0) % 4), tp - Vector3(n.x, 0, n.y) * 0.25, _rng.randf_range(0.8, 1.3), {"anchor": 0.0, "shift": 0.05, "sway": 0.015, "tint": tint})
		if _hash(s * 5.1 + sd) < 0.7:
			_card("decor/touffe_sol_%d.png" % (int(_hash(s * 2.0 + sd) * 4.0) % 4), Vector3(p.x, h0, p.y) - Vector3(n.x, 0, n.y) * 0.12, _rng.randf_range(0.7, 1.1), {"anchor": 0.0, "shift": 0.05, "sway": 0.012, "tint": tint})
		if _hash(s * 1.3 + sd * 2.0) < 0.33 * rocks_k:
			var rr := _rng.randf_range(0.14, minf(0.42, tw * 0.45))
			var c := p - n * (tw * 0.55)
			_rock(Vector3(c.x, h0 + rr * 0.35, c.y), rr, tint)
		i += 1


func _mesh_quads(quads: Array, mat: Material, explicit_uv: bool, uv_scale := 1.0) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for q in quads:
		var pts := [q[0], q[1], q[2], q[3]]
		var uvs := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
		if explicit_uv:
			uvs = [Vector2(q[4].x, -q[4].y) * uv_scale, Vector2(q[5].x, -q[5].y) * uv_scale, Vector2(q[6].x, -q[6].y) * uv_scale, Vector2(q[7].x, -q[7].y) * uv_scale]
		for tri in [[0, 1, 2], [0, 2, 3]]:
			var a: Vector3 = pts[tri[0]]
			var b: Vector3 = pts[tri[1]]
			var c: Vector3 = pts[tri[2]]
			# Godot : faces avant dans le sens horaire vu de la caméra -> (b - a) × (c - a) doit s'éloigner d'elle
			var nrm := (b - a).cross(c - a).normalized()
			var order: Array = tri
			if nrm.dot(_view_ref(a)) > 0.0:
				order = [tri[0], tri[2], tri[1]]
			else:
				nrm = -nrm
			for k in order:
				st.set_normal(nrm)
				st.set_uv(uvs[k])
				st.add_vertex(pts[k])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	root.add_child(mi)


## Orientation des faces générées : vers la caméra (les falaises ne sont vues que de ce côté).
func _view_ref(_p: Vector3) -> Vector3:
	return World25.cam_back()


func _rock(c: Vector3, r: float, tint: Color) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 1.6
	sm.radial_segments = 7
	sm.rings = 3
	mi.mesh = sm
	mi.material_override = _tinted("roche", tint * Color(1.05, 1.05, 1.08))
	mi.rotation = Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.0, TAU), _rng.randf_range(-0.3, 0.3))
	mi.scale = Vector3(_rng.randf_range(1.0, 1.5), _rng.randf_range(0.7, 1.0), _rng.randf_range(0.9, 1.3))
	mi.position = c
	root.add_child(mi)


# ------------------------------------------------------------------------------------------------ intérieur
func _build_interior() -> void:
	var r: Rect2 = world.regions[0]["rect"]
	var hw := 2.7
	var stone := _surf("pierre")
	var fac := _surf("facade", false, true)
	# murs nord, ouest et est (le mur sud, côté caméra, est ouvert : coupe)
	_box_mesh(Vector3(r.get_center().x, hw / 2.0, r.position.y - 0.2), Vector3(r.size.x + 0.8, hw, 0.4), stone)
	_box_mesh(Vector3(r.position.x - 0.2, hw / 2.0, r.get_center().y), Vector3(0.4, hw, r.size.y), stone)
	_box_mesh(Vector3(r.end.x + 0.2, hw / 2.0, r.get_center().y), Vector3(0.4, hw, r.size.y), stone)
	var u := r.size.x / 4.0
	_faces([[[Vector3(r.position.x, hw, r.position.y + 0.01), Vector3(r.end.x, hw, r.position.y + 0.01), Vector3(r.end.x, 0.9, r.position.y + 0.01), Vector3(r.position.x, 0.9, r.position.y + 0.01)],
		[Vector2(0, 0.1), Vector2(u, 0.1), Vector2(u, 1), Vector2(0, 1)]]], fac)
	_box_mesh(Vector3(r.get_center().x, 0.12, r.end.y + 0.1), Vector3(r.size.x + 0.8, 0.24, 0.2), stone)      # seuil sud
	_wall_quad("batiment/porte.png", Vector3(5.0, 0.3, r.end.y + 0.22), Vector2(1.2, 0.6), 0.0, 0.0, root)
	_wall_quad("batiment/fenetre.png", Vector3(2.4, 1.75, r.position.y + 0.03), Vector2(0.8, 0.95), 0.0, 0.9, root)
	_wall_quad("batiment/fenetre.png", Vector3(7.0, 1.75, r.position.y + 0.03), Vector2(0.8, 0.95), 0.0, 0.9, root)
	# âtre (est) : lumière chaude vacillante
	_box_mesh(Vector3(r.end.x - 0.25, 0.7, 4.7), Vector3(0.5, 1.4, 1.5), stone)
	_halo(Vector3(r.end.x - 0.55, 0.5, 4.7), 1.6, 0.7)
	_light(Vector3(r.end.x - 1.0, 0.9, 4.7), 2.2, 7.5, Color(1.0, 0.62, 0.32))
	_light(Vector3(5.0, 2.2, 3.4), 1.5, 7.0, Color(1.0, 0.8, 0.55))
	_halo(Vector3(5.0, 1.15, 3.45), 0.9, 0.6)


func _build_furniture(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var h1: float = e["h1"]
	var wood := _surf("bois")
	match e["id"]:
		"int_table":
			_box_mesh(_rect_center(r, h1 - 0.1, h1), Vector3(r.size.x, 0.1, r.size.y), _surf("plancher"))
			for c in [r.position + Vector2(0.12, 0.12), Vector2(r.end.x - 0.12, r.position.y + 0.12), r.end - Vector2(0.12, 0.12), Vector2(r.position.x + 0.12, r.end.y - 0.12)]:
				_box_mesh(Vector3(c.x, (h1 - 0.1) / 2.0, c.y), Vector3(0.12, h1 - 0.1, 0.12), wood)
			_box_mesh(Vector3(r.get_center().x, h1 + 0.01, r.get_center().y), Vector3(1.1, 0.02, 0.7), _tinted("facade", Color(1.0, 0.95, 0.8)))
		"int_lit":
			_box_mesh(_rect_center(r, 0.0, 0.35), Vector3(r.size.x, 0.35, r.size.y), wood)
			_box_mesh(_rect_center(r.grow(-0.06), 0.35, h1), Vector3(r.size.x - 0.12, h1 - 0.35, r.size.y - 0.12), _tinted("facade", Color(0.36, 0.42, 0.72)))
		"int_tonneau":
			_card("props/tont01_tonneau.png", Vector3(r.get_center().x, 0, r.get_center().y), 0.9, {"anchor": 0.08})
		"int_coffre":
			_card("props/cais01_caisse.png", Vector3(r.get_center().x, 0, r.get_center().y), 1.05, {"anchor": 0.1})
		_:
			_box_mesh(_rect_center(r, 0.0, h1), Vector3(r.size.x, h1, r.size.y), wood)
			for hh in [0.5, 1.0, 1.5]:
				_box_mesh(Vector3(r.get_center().x, hh, r.end.y + 0.01), Vector3(r.size.x, 0.05, 0.04), _surf("plancher"))


# ------------------------------------------------------------------------------------------------ caméra (P4.1)
func _apply_variante() -> void:
	World25.pitch = deg_to_rad(CAMS[cam_mode]["pitch"])
	s.cam.aim_frac = 0.0
	RenderingServer.global_shader_parameter_set("p4_persp", 1.0 if CAMS[cam_mode]["persp"] else 0.0)
	if _tilt != null:
		_apply_tilt()


func _build_tilt() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5                                     # sous l'interface (50) : le texte reste net
	add_child(layer)
	_tilt = ColorRect.new()
	_tilt.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tilt.size = Vector2(4000, 4000)
	_tilt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mm := ShaderMaterial.new()
	mm.shader = TILT_SH
	_tilt.material = mm
	layer.add_child(_tilt)
	_apply_tilt()


## Flou de distance : réduit en P4.4 (rayon 1,6 px, haut de l'écran seulement), jamais sur le bas ni sur l'interface
## (calque 5, sous l'interface 50) ; --notilt le coupe.
func _apply_tilt() -> void:
	var k: float = CAMS[cam_mode].get("tilt", 0.0)
	_tilt.visible = k > 0.0 and not _cli.has("notilt")
	var mm: ShaderMaterial = _tilt.material
	mm.set_shader_parameter("strength", k)
	mm.set_shader_parameter("radius_px", 2.4)
	mm.set_shader_parameter("top_end", 0.2)
	mm.set_shader_parameter("bottom_start", 2.0)


func apply_camera(center: Vector2, zoom: float) -> void:
	var c: Dictionary = CAMS[cam_mode]
	if not c["persp"]:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		super.apply_camera(center, zoom)
		return
	# même cadrage que l'orthographique (le héros au même point de l'écran, à la même taille) : la caméra est placée
	# sur le rayon central, à la distance où la hauteur visible au niveau du héros égale celle de la vue ortho
	var vp: Vector2 = Session25.viewport_size(self)
	var h_view := vp.y / (World25.PPM * zoom)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = c["fov"]
	var axis := World25.cam_right() * (center.x / World25.PPM) + World25.cam_up() * (-center.y / World25.PPM)
	var depth := body.global_position.dot(World25.cam_back()) if body != null else 0.0
	cam.position = axis + World25.cam_back() * (depth + h_view * 0.5 / tan(deg_to_rad(c["fov"]) * 0.5))


## Occultation : rayons du héros vers la caméra réelle (en perspective, la direction dépend de la position).
func hero_occluded() -> bool:
	if not CAMS[cam_mode]["persp"]:
		return super.hero_occluded()
	var space := get_world_3d().direct_space_state
	var base := body.global_position
	var hit_any := false
	for hh in [0.9, 1.5]:
		var from := base + Vector3(0, hh, 0)
		var dir := (cam.global_position - from).normalized()
		from += dir * (SPRITE_TOWARD_CAM + 0.05)
		var pr := PhysicsRayQueryParameters3D.create(from, from + dir * 60.0, L_FLOOR | L_OBST | L_OCC)
		if not space.intersect_ray(pr).is_empty():
			hit_any = true
	_occluded = hit_any
	return hit_any


func _cycle_camera() -> void:
	cam_mode = CAM_ORDER[(CAM_ORDER.find(cam_mode) + 1) % CAM_ORDER.size()]
	s.arch = "P4.1 — avant-poste · " + CAMS[cam_mode]["label"]
	_reload_here()
	s.toast("Caméra " + CAMS[cam_mode]["label"], 2.5)


# ------------------------------------------------------------------------------------------------ personnages
func _perso_quad(parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = QuadMesh.new()
	var mm := ShaderMaterial.new()
	mm.shader = PERSO_SH
	mm.set_shader_parameter("tint", CHAR_TINT)
	mm.render_priority = 1
	mi.material_override = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _make_actor(name: String, key: String) -> Dictionary:
	var d: Dictionary = super._make_actor(name, key)
	(d["spr"] as AnimatedSprite3D).visible = false          # remplacé par une carte « pixel net »
	d["k"] = CHARS.get(key, {"k": 1.0})["k"]
	d["actor"].set_scale_k(d["k"])                       # P4.8 : cadence de marche = pas dessiné (pieds sans glissement)
	d["main"] = _perso_quad(d["spr"].get_parent())
	_sync_sprite(d)
	return d


func _sync_sprite(d: Dictionary) -> void:
	super._sync_sprite(d)
	if not d.has("main"):
		return
	var tex: Texture2D = d["actor"].texture()
	var k: float = d["k"]
	var w := tex.get_width() * k / World25.PPM
	var h := tex.get_height() * k / World25.PPM / cos(World25.pitch)
	var mi: MeshInstance3D = d["main"]
	(mi.mesh as QuadMesh).size = Vector2(w, h)
	mi.position = Vector3(0, h / 2.0, 0)
	var mm: ShaderMaterial = mi.material_override
	mm.set_shader_parameter("tex", tex)
	mm.set_shader_parameter("flip", 1.0 if d["actor"].flip else 0.0)
	mm.set_shader_parameter("sharp", 1.0 if s == null or s.options.get("sharp", true) else 0.0)


# ------------------------------------------------------------------------------------------------ rencontre
func _spawn_monster() -> void:
	var c: Array = _monster_cfg["xy"]
	var foot := Vector3(c[0], _monster_cfg["h"], c[1])
	_monster = Node3D.new()
	_monster.name = "Vorgane"
	_monster.position = foot
	var holder := Node3D.new()
	holder.basis = Basis(Vector3.UP, -World25.YAW)
	holder.position = World25.cam_back() * (SPRITE_TOWARD_CAM + 0.5)
	_monster.add_child(holder)
	_monster_frames.clear()
	for i in MONSTER_FRAMES:
		_monster_frames.append(load(MONSTER_DIR + "idle_%d.png" % i))
	var mi := _perso_quad(holder)
	var t0: Texture2D = _monster_frames[0]
	var w := t0.get_width() * MONSTER_K / World25.PPM
	var h := t0.get_height() * MONSTER_K / World25.PPM / cos(World25.pitch)
	(mi.mesh as QuadMesh).size = Vector2(w, h)
	mi.position = Vector3(0, h / 2.0, 0)
	(mi.material_override as ShaderMaterial).set_shader_parameter("tex", t0)
	_monster_quad = mi
	root.add_child(_monster)
	_blob(foot, w * 1.15, 0.6)                  # ombre de contact large et douce sous les pattes : il ne flotte plus
	_obstacle_cyl(foot, _monster_cfg["r"], 1.6)
	world.solids.append({"id": "vorgane", "kind": "circle", "c": Vector2(c[0], c[1]), "r": _monster_cfg["r"], "h0": 0.0, "h1": 1.6})


func monster_present() -> bool:
	return _monster != null and is_instance_valid(_monster)


func _engage() -> void:
	_engaging = true
	s.dialogue_open = true                         # fige le déplacement
	s.toast("Le Vorgane vous a repérés !", 1.2)
	var tw := create_tween()
	tw.tween_interval(0.45)
	await tw.finished
	GameState.from_zone = true
	GameState.proto = true
	GameState.arena = "lisiere"                    # arène illustrée du combat, comme l'exploration précédente
	GameState.flags["rencontre_pv_mult"] = DEMO_HP_MULT   # démo : PV du Vorgane divisés par deux (ce combat seulement)
	GameState.flags["p4_pos"] = s.hero - Vector3(2.4, 0, 0)       # au retour : un peu en retrait, côté pont
	GameState.explore_return = scene_file_path
	GameState.goto(GameState.SCENE_PROTO_BATTLE, 0.35)


# ------------------------------------------------------------------------------------------------ dialogue
func dialogue_is_open() -> bool:
	return _dialog != null and _dialog.is_open()


## Appelé par la session (touche E, parcours automatique) : le garde ouvre le dialogue à portraits.
func interact_override() -> bool:
	if _dialog.is_open():
		if not _dialog.showing_choice():
			_dialog.advance()
		return true
	var n: Dictionary = s._nearby()
	if n.get("kind", "") != "npc":
		return false
	var data: Dictionary = JSON.parse_string(FileAccess.open(DIALOGUE, FileAccess.READ).get_as_text())
	var steps: Array = data["after_victory"] if GameState.enemy_defeated else data["start"]
	var spk: Dictionary = data["speakers"].duplicate(true)
	spk["heros"]["name"] = GameState.hero_name
	s.dialogue_open = true
	s.cam.ui_lock = true
	var np: Vector3 = world.npc["p"]
	actors["aren"]["actor"].face_toward(World25.plan_to_screen_dir(Vector2(np.x - s.hero.x, np.y - s.hero.y)))
	_dialog.open(steps, spk)
	s.m["interactions"] = s.m.get("interactions", []) + ["garde"]
	return true


func _on_dialog_closed() -> void:
	s.dialogue_open = false
	s.cam.ui_lock = false


# ------------------------------------------------------------------------------------------------ boucle
func _unhandled_input(e: InputEvent) -> void:
	if _switching or _engaging:
		return
	if _dialog.is_open():
		if e is InputEventKey and e.pressed and not e.echo:
			_dialog.handle_key(e)
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_C:
		_cycle_camera()
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_T:
		s.options["sharp"] = not s.options.get("sharp", true)
		s.toast("Sprites : " + ("pixel net (P4.1)" if s.options["sharp"] else "bilinéaire (P4)"))
		for k in actors:
			_sync_sprite(actors[k])
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_P:
		if not _interior:
			s.start_pilot("p4")                    # parcours automatique de l'avant-poste (depuis l'entrée)
		return
	s.handle_input(e)


func _physics_process(delta: float) -> void:
	if _engaging:
		return
	if dialogue_is_open() and (s.pilot.size() > 0 or GameState.autoplay):
		# parcours automatique / démonstration : le dialogue avance seul (premier choix)
		_auto_dialog_t += delta
		if _auto_dialog_t > 0.45:
			_auto_dialog_t = 0.0
			if _dialog.showing_choice():
				_dialog.pick(0)
			else:
				_dialog.advance()
	super._physics_process(delta)
	if _switching or world == null:
		return
	_guard_step(delta)
	if monster_present() and not s.dialogue_open:
		var c: Array = _monster_cfg["xy"]
		if Vector2(s.hero.x, s.hero.y).distance_to(Vector2(c[0], c[1])) < _monster_cfg["declenchement_m"] and absf(s.hero.z - _monster_cfg["h"]) < 0.5:
			_engage()


func _guard_step(delta: float) -> void:
	if world.npc.is_empty() or _guard_post == Vector3.INF or not actors.has("pnj"):
		return
	var d: Dictionary = actors["pnj"]
	var p: Vector3 = world.npc["p"]
	var hp := Vector2(s.hero.x, s.hero.y)
	var near: bool = hp.distance_to(Vector2(_guard_post.x, _guard_post.y)) < 4.0 or s.dialogue_open
	var goal: Vector2 = Vector2(_guard_post.x, _guard_post.y) + (Vector2.ZERO if near else GUARD_ROUND[_guard_i])
	var cur := Vector2(p.x, p.y)
	var moved := 0.0
	var sdir := Vector2.ZERO
	if cur.distance_to(goal) > 0.02 and (near or _guard_wait <= 0.0):
		var stp := (goal - cur).limit_length(GUARD_SPEED * delta)
		moved = stp.length()
		sdir = World25.plan_to_screen_dir(stp.normalized())
		cur += stp
	elif not near:
		_guard_wait -= delta
		if _guard_wait <= 0.0 and cur.distance_to(goal) <= 0.02:
			_guard_i = (_guard_i + 1) % GUARD_ROUND.size()
			_guard_wait = 1.6
	if near and moved == 0.0:
		d["actor"].face_toward(World25.plan_to_screen_dir(hp - cur))
	elif moved == 0.0 and _guard_wait > 0.0 and d["actor"].anim.begins_with("walk"):
		pass
	d["actor"].step(moved, sdir, delta)
	if moved > 0.0:
		world.npc["p"] = Vector3(cur.x, cur.y, p.z)
		for so in world.solids:
			if so["id"] == world.npc["id"]:
				so["c"] = cur
		d["node"].position = World25.g3(world.npc["p"])
		_guard_body.position = World25.g3(world.npc["p"])
	_sync_sprite(d)


func _process(delta: float) -> void:
	super._process(delta)
	if s == null or world == null:
		return
	_time += delta
	_hole = move_toward(_hole, 1.0 if _occluded else 0.0, delta * 6.0)
	RenderingServer.global_shader_parameter_set("p4_hero", body.get_global_transform_interpolated().origin + Vector3(0, 0.9, 0))
	RenderingServer.global_shader_parameter_set("p4_hole", _hole)
	if monster_present() and _monster_quad != null:
		(_monster_quad.material_override as ShaderMaterial).set_shader_parameter("tex", _monster_frames[int(_time * 6.0) % _monster_frames.size()])
	for l in _lights:
		(l[0] as OmniLight3D).light_energy = l[1] * (0.9 + 0.07 * sin(_time * 7.3 + l[2]) + 0.04 * sin(_time * 13.1 + l[2] * 2.0))
	var hint: String = s.interact_hint if not dialogue_is_open() else ""
	if hint == "" and not s.dialogue_open and not _interior:
		for t in world.triggers:
			if Vector2(s.hero.x, s.hero.y).distance_to((t["rect"] as Rect2).get_center()) < 1.6:
				hint = "Entrer"
	_prompt.text = hint
	_prompt.position = Vector2((Session25.viewport_size(self).x - _prompt.size.x) / 2.0, Session25.viewport_size(self).y - 120.0)
	if _title_t > 0.0:
		_title_t -= delta
		_title.modulate.a = clampf(_title_t, 0.0, 1.0)


func _switch(t: Dictionary) -> void:
	_switching = true
	var tw: Tween = s.fade_to(1.0, 0.25)
	await tw.finished
	s.pending_instance = {}
	_load(t["to"], "instance", t["arrive"])
	for k in actors:
		_sync_sprite(actors[k])
	await get_tree().physics_frame
	_switching = false
	s.fade_to(0.0, 0.25)


func _prefix() -> String:
	return "P4" + (("_" + str(_cli["tag"])) if _cli.has("tag") else "")
