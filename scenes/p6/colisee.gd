extends "res://scenes/p4/avant_poste.gd"
## P6 — COLISÉE DE VAL'SERRA : ouverture du jeu (blockout jouable).
## Vestiaires → salle d'attente → arène (commandant, combat tutoriel) → coursive → sortie est → quartier (transition).
##
## Réutilise l'habillage de l'avant-poste (caméra P30, sprites « pixel net », matières P4, boîte de dialogue à
## portraits, flou de distance) et le socle d'exploration (données World25, collisions physiques + modèle logique).
## Ce script n'ajoute que ce qui est propre au Colisée :
##   - données : data/p6/colisee.json et quartier_initial.json (tools/p6/build_colisee.py), PNJ et dialogues ;
##   - Aren SEUL (aucun compagnon dans le groupe pendant l'introduction) ;
##   - plusieurs PNJ (sprite du garde, teinte et échelle par rôle), dialogues à variantes selon la progression ;
##   - portes ouvertes / fermées selon l'état (src/game/progression.gd), marques au sol aux couleurs du plan
##     (vert : ouvert, jaune : scénarisé, rouge : fermé) ;
##   - arène ovale (sable, podium, gradins à 5 rangs, loge officielle), décor provisoire ;
##   - objectif affiché en haut à droite, nom des secteurs à l'entrée ;
##   - lancement du combat tutoriel (scenes/battle/combat_tutoriel.tscn) et retour en exploration.

const Progression = preload("res://src/game/progression.gd")
const UIS = preload("res://src/presentation/ui_style.gd")
const ZONE_COLISEE := "res://data/p6/colisee.json"
const ZONE_QUARTIER := "res://data/p6/quartier_initial.json"
const DIALOGUES_P6 := "res://data/p6/dialogues_colisee.json"
const PNJ_P6 := "res://data/p6/pnj_colisee.json"
const QUALITE_OMBRE := 4                  # ombres douces qualité 4 (référence P5.3 retenue)
const QUALITE_OMBRE_DEFAUT := 2
const PNJ_R := 0.35
const AnimV09B5 = preload("res://src/explore25/anim_v09b5.gd")
const Habillage = preload("res://scenes/p6/habillage_p6.gd")
const Secteurs = preload("res://src/explore25/secteurs25.gd")
## P6.1 — réglages de caméra comparés (touche C) : [nom, préréglage, indice de zoom (0 : ×2, 1 : ×2,5, 2 : ×3)]
const CAMS_P6 := {"A": ["P30", 1], "B": ["P30", 2], "C": ["P24", 2]}
const CAMS_P6_ORDRE := ["A", "B", "C"]
const CAMS_P6_LABEL := {"A": "A — P30 ×2,5 (P6)", "B": "B — P30 ×3", "C": "C — P24 ×3 (réglage de la forêt)"}
## P6.1 — apparences d'Aren comparées (touche B) : « foret » = ce qu'affiche F5 depuis le 19/11 (profil V09B.5
## 96 × 112 réduit à 64 px de haut, face / dos V4 dessinés, art/tests/) ; « p48 » = art/p45/chars/aren/ (P6).
const AREN_VARIANTES := ["foret", "p48"]
const TEINTE_P6 := Color(1.0, 0.97, 0.94)        # lumière de fin d'après-midi (l'avant-poste garde son crépuscule)
const PORTEE_PARLER := 1.7
const COMMANDANT_AUTO_M := 2.6             # le dialogue du commandant s'ouvre seul à cette distance (avant le tutoriel)
## Couleurs des marques de passage (légende du plan)
const C_OUVERT := Color(0.36, 0.86, 0.45)
const C_SCENARISE := Color(0.98, 0.84, 0.3)
const C_FERME := Color(0.92, 0.28, 0.28)

var _p6 := {}
var _pnj_defs: Array = []
var _dialogues_p6 := {}
var _pnj := {}                            # id -> {def, p: Vector2, post: Vector2, body, key, i, wait}
var _portes_fermees := {}                 # id -> texte (portes fermées, pour l'examen)
var _parle_a := ""
var _effet := ""
var _bloque := false                      # transition vers le combat : plus aucune entrée
var _zone_courante := ""
var _cmd_arme := true                     # rappel automatique du commandant (réarmé quand on s'éloigne)
var _appel_fait := false
var _fin_tutoriel := false
var _obj_panel: PanelContainer
var _obj_label: Label
var _obj_flash := 0.0
var _journal: Array = []                  # événements de la session (tests, rapport)
var cam_p6 := "C"
## P6.2 : azimut du Colisée validé le 22/11/2026 : 0° (colisee_azimut20.tscn : ancienne référence 20°) ; -- --azimut= l'emporte
@export var azimut_initial := 0.0
var aren_variante := "foret"
var _anim_aren: RefCounted
var _auto_p6_t := 0.0
var _sect                                  # P6.2 : visibilité par secteurs (null si la zone n'en déclare pas)
var _lueur_tunnel: MeshInstance3D
var _bornes_but := Rect2()
var _amb_but := -1.0
var habillage := true                       # P6.1 : pilote d'habillage (touche H : pilote / blockout P6)
var _hab


func _ready() -> void:
	_cli = parse_cli()
	variante = "B"
	cam_p6 = str(_cli.get("cam_p6", cam_p6)).to_upper()
	if not CAMS_P6.has(cam_p6):
		cam_p6 = "C"
	cam_mode = CAMS_P6[cam_p6][0]
	habillage = str(_cli.get("habillage", "pilote")) != "blockout"
	aren_variante = str(_cli.get("aren", aren_variante))
	if not AREN_VARIANTES.has(aren_variante):
		aren_variante = "foret"
	paysage = "aucun"
	arch_label = "P6 — Colisée"
	# P6.2 : azimut de la caméra propre au Colisée (comparaison 20° / 0°) ; la forêt et l'avant-poste gardent 20°
	World25.yaw = deg_to_rad(float(_cli.get("azimut", azimut_initial)))
	for k in CHARS:
		Actor25.overrides[k] = CHARS[k]["dir"]
	get_tree().physics_interpolation = true
	s = Session25.new(self, arch_label)
	s.options["debug"] = _cli.has("debug")
	s.options["grid"] = false
	s.options["occlusion"] = 0
	_apply_variante()
	s.arch = "P6 — Colisée · " + CAMS_P6_LABEL[cam_p6]
	s.build_hud()
	s._help.text = "Flèches / ZQSD : marcher  ·  Maj : courir  ·  E / Entrée : parler, examiner  ·  Molette : zoom  ·  C : caméra  ·  B : Aren  ·  H : habillage  ·  F1 : infos"
	_build_ui()
	_dialog.choisi.connect(_on_choix)
	_build_ui_p6()
	_build_tilt()
	_env()
	RenderingServer.directional_soft_shadow_filter_set_quality(QUALITE_OMBRE)
	RenderingServer.positional_soft_shadow_filter_set_quality(QUALITE_OMBRE)   # P6.2 : lanternes à ombres douces
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.near = 0.5
	cam.far = 400.0
	add_child(cam)
	_cam_basis()
	cam.current = true
	_spawn_actors()
	_dialogues_p6 = JSON.parse_string(FileAccess.open(DIALOGUES_P6, FileAccess.READ).get_as_text())["dialogues"]
	_pnj_defs = JSON.parse_string(FileAccess.open(PNJ_P6, FileAccess.READ).get_as_text())["pnj"]
	# outils de test : état de départ imposé (--etat=tutorial_completed, etc.), nouvelle partie (--neuf)
	if _cli.has("neuf"):
		Progression.reinitialiser()
	if _cli.has("etat"):
		Progression.definir(str(_cli["etat"]), true)
		if Progression.au_moins(Progression.TUTORIAL_COMPLETED):
			Progression.definir_objectif("guilde_badge")
	var retour: bool = GameState.explore_return == scene_file_path and GameState.last_battle_result != ""
	var arrive := Vector3.INF
	if retour and GameState.last_battle_result == Progression.RESULTAT_TUTORIEL:
		# fin du tutoriel : retour dans l'arène, devant le commandant ; la grille est se lève
		Progression.definir(Progression.TUTORIAL_COMPLETED)
		Progression.definir_objectif("guilde_badge")
		arrive = Vector3(26.0, 23.3, 0.0)
		_fin_tutoriel = true
	elif Progression.etat() == Progression.TUTORIAL_IN_PROGRESS:
		# tutoriel interrompu (fermeture, outil) : on revient avant le combat, dans l'arène, sans le relancer seul
		Progression.definir(Progression.TUTORIAL_AVAILABLE, true)
		arrive = Vector3(26.0, 28.5, 0.0)
		_cmd_arme = false
	if retour:
		GameState.last_battle_result = ""
		GameState.from_zone = false
		if _cli.has("route_retour"):
			_cli["route"] = _cli["route_retour"]
		else:
			_cli.erase("route")
	var zone := ZONE_QUARTIER if Progression.au_moins(Progression.COLISEUM_EXITED) else ZONE_COLISEE
	_load(_cli.get("instance", zone), "instance", arrive)
	s.cam.set_index(CAMS_P6[cam_p6][1], false)
	_apply_cli()
	_maj_objectif(false)
	_log("chargement", {"etat": Progression.etat(), "zone": _p6.get("zone", ""), "retour_tutoriel": _fin_tutoriel})
	if _fin_tutoriel:
		_jouer_fin_tutoriel.call_deferred()
	if _cli.has("vue_dessus_p6"):
		_vue_dessus_p6.call_deferred()
	if _cli.has("decor_combat"):
		_decor_combat.call_deferred()


func _exit_tree() -> void:
	super._exit_tree()
	World25.yaw = World25.YAW
	RenderingServer.directional_soft_shadow_filter_set_quality(QUALITE_OMBRE_DEFAUT)
	RenderingServer.positional_soft_shadow_filter_set_quality(QUALITE_OMBRE_DEFAUT)


# ------------------------------------------------------------------------------------------------ interface
func _build_ui_p6() -> void:
	_obj_panel = PanelContainer.new()
	_obj_panel.add_theme_stylebox_override("panel", UIS.box(UIS.C_PANEL, UIS.C_GOLD, 1, 6, 0.86))
	_obj_panel.anchor_left = 1.0
	_obj_panel.anchor_right = 1.0
	_obj_panel.offset_left = -360
	_obj_panel.offset_right = -18
	_obj_panel.offset_top = 16
	_obj_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.hud.add_child(_obj_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	_obj_panel.add_child(v)
	var t := Label.new()
	t.text = "OBJECTIF"
	t.add_theme_font_size_override("font_size", 12)
	t.add_theme_color_override("font_color", UIS.C_GOLD)
	v.add_child(t)
	_obj_label = Label.new()
	_obj_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_obj_label.add_theme_font_size_override("font_size", 17)
	_obj_label.add_theme_color_override("font_color", UIS.C_TEXT)
	v.add_child(_obj_label)


func _maj_objectif(flash := true) -> void:
	var txt := Progression.objectif_texte()
	_obj_panel.visible = txt != ""
	_obj_label.text = txt
	if flash and txt != "":
		_obj_flash = 2.4
		s.toast("Nouvel objectif : " + txt, 2.6)
		_log("objectif", {"objectif": Progression.objectif()})


# ------------------------------------------------------------------------------------------------ personnages
## Aren seul : pas de compagnon (Ilya et les autres restent dans le projet pour la suite, hors du groupe).
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
	_anim_aren = AnimV09B5.make()
	_anim_aren.format = "96x112_h64"           # même réglage que le démarrage de F5 (forêt)
	var h := _make_actor("aren", "aren")
	body.add_child(h["node"])
	comp_vis = Node3D.new()                 # point d'ancrage vide (le socle déplace « le compagnon »)
	comp_vis.name = "SansCompagnon"
	add_child(comp_vis)


func animate(hm: float, hdir: Vector2, _cm: float, _cdir: Vector2, delta: float) -> void:
	actors["aren"]["actor"].step(hm, hdir, delta)
	if _anim_aren != null:
		var run := force_run or Input.is_physical_key_pressed(KEY_SHIFT)
		_anim_aren.step(actors["aren"]["actor"], hm, run, hdir.x if hm > 0.0001 else 0.0)
	_sync_sprite(actors["aren"])


## P6.1 — Aren : image P4.8 (Actor25) ou variante « forêt » (V09B.5 + V4, module de F5), même carte « pixel net ».
## Le pied du personnage reste sur l'origine : ligne de sol et axe de la tête du format V09B.5 pris en compte.
func _sync_sprite(d: Dictionary) -> void:
	super._sync_sprite(d)
	if not d.has("main"):
		return
	var mi: MeshInstance3D = d["main"]
	var mm: ShaderMaterial = mi.material_override
	if d.get("node") != null and actors.has("aren") and d == actors["aren"]:
		mm.set_shader_parameter("tint", TEINTE_P6)
		if aren_variante == "foret" and _anim_aren != null and _anim_aren.active:
			var tex: Texture2D = _anim_aren.texture()
			var pm: float = _anim_aren.pixel_m()
			var w := tex.get_width() * pm
			var h := tex.get_height() * pm / cos(World25.pitch)
			var sol: float = float(_anim_aren._cad["formats"][_anim_aren.format]["ligne_sol_px"])
			var ox: float = _anim_aren.offset_px(0.0, tex).x * pm
			(mi.mesh as QuadMesh).size = Vector2(w, h)
			mi.position = Vector3(ox, h / 2.0 - (tex.get_height() - sol) * pm / cos(World25.pitch), 0)
			mm.set_shader_parameter("tex", tex)
			mm.set_shader_parameter("flip", 1.0 if _anim_aren.miroir() else 0.0)


func groupe() -> Array:
	return actors.keys().filter(func(k): return not str(k).begins_with("pnj_"))


func _spawn_pnj() -> void:
	_pnj.clear()
	var zone_id: String = _p6.get("zone", "colisee")
	for d in _pnj_defs:
		if d.get("zone", "") != zone_id:
			continue
		if d.has("a_partir_de") and not Progression.au_moins(d["a_partir_de"]):
			continue
		if d.has("jusqua") and Progression.au_moins(d["jusqua"]):
			continue
		var key := "pnj_" + str(d["id"])
		var a := _make_actor(key, "pnj")
		a["k"] = float(a["k"]) * float(d.get("echelle", 1.0))
		a["actor"].set_scale_k(a["k"])
		var tc: Array = d.get("teinte", [1.0, 1.0, 1.0])
		(a["main"].material_override as ShaderMaterial).set_shader_parameter("tint", Color(CHAR_TINT.r * tc[0], CHAR_TINT.g * tc[1], CHAR_TINT.b * tc[2]))
		var p := Vector2(d["xy"][0], d["xy"][1])
		root.add_child(a["node"])
		a["node"].position = World25.g3(Vector3(p.x, p.y, 0.0))
		var rg: Array = d.get("regard", [0, 1])
		a["actor"].face_toward(Vector2(rg[0], rg[1]))
		_sync_sprite(a)
		var sb := _obstacle_cyl(World25.g3(Vector3(p.x, p.y, 0.0)), PNJ_R, 1.8)
		world.solids.append({"id": d["id"], "kind": "circle", "c": p, "r": PNJ_R, "h0": 0.0, "h1": 1.8})
		_pnj[d["id"]] = {"def": d, "p": p, "post": p, "body": sb, "key": key, "i": 0, "wait": 1.5 + randf()}


func pnj_presents() -> Array:
	return _pnj.keys()


func _pnj_step(delta: float) -> void:
	var hp := Vector2(s.hero.x, s.hero.y)
	for id in _pnj:
		var n: Dictionary = _pnj[id]
		var d: Dictionary = actors[n["key"]]
		var p: Vector2 = n["p"]
		var near: bool = hp.distance_to(p) < 3.0 or _parle_a == id
		var moved := 0.0
		var sdir := Vector2.ZERO
		var ronde: Array = n["def"].get("ronde", [])
		if ronde.size() > 1:
			var post: Vector2 = n["post"]
			var o: Array = ronde[n["i"]]
			var goal: Vector2 = post if near else post + Vector2(o[0], o[1])
			if p.distance_to(goal) > 0.02 and (near or n["wait"] <= 0.0):
				var stp := (goal - p).limit_length(0.9 * delta)
				var free := true
				for so in world.solids:
					if so["id"] != id and so["kind"] == "circle" and (p + stp).distance_to(so["c"]) < so["r"] + PNJ_R:
						free = false
				if free and hp.distance_to(p + stp) > PNJ_R + 0.4:
					p += stp
					moved = stp.length()
					sdir = World25.plan_to_screen_dir(stp.normalized())
			elif not near:
				n["wait"] -= delta
				if n["wait"] <= 0.0 and p.distance_to(goal) <= 0.02:
					n["i"] = (n["i"] + 1) % ronde.size()
					n["wait"] = 2.0 + randf() * 1.5
		if near and moved == 0.0:
			d["actor"].face_toward(World25.plan_to_screen_dir(hp - p))
		d["actor"].step(moved, sdir, delta)
		if moved > 0.0:
			n["p"] = p
			for so in world.solids:
				if so["id"] == id:
					so["c"] = p
			d["node"].position = World25.g3(Vector3(p.x, p.y, 0.0))
			(n["body"] as Node3D).position = World25.g3(Vector3(p.x, p.y, 0.0))
		_sync_sprite(d)


# ------------------------------------------------------------------------------------------------ chargement
func _load(file: String, m: String, arrive := Vector3.INF) -> void:
	for k in actors.keys():
		if str(k).begins_with("pnj"):
			actors.erase(k)
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
	_rng.seed = 6061
	world = World25.load_world(file, m)
	_p6 = world.adj.get("p6", {})
	_interior = false
	_sun.visible = true
	_sun.light_energy = 1.0
	_sun.light_color = Color(1.0, 0.94, 0.86)             # fin d'après-midi (le crépuscule violet reste à l'avant-poste)
	_env_res.ambient_light_color = Color(0.6, 0.6, 0.68)
	_env_res.ambient_light_energy = 0.85
	_env_res.background_color = Color(0.36, 0.43, 0.6) if _p6.has("arene") else Color(0.09, 0.08, 0.12)   # ciel au-dessus de l'arène
	_env_res.background_mode = Environment.BG_COLOR
	_env_res.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_hab = Habillage.new(self) if habillage else null
	if _hab != null:
		_hab.lumiere(_env_res, _sun)
	_portes_fermees.clear()
	_sect = Secteurs.new(_p6["secteurs"]) if (_p6.has("secteurs") and not _cli.has("sans_secteurs")) else null
	for e in world.elements:
		_build(e)
	_build_p6()
	_spawn_pnj()
	_build_overlay()
	s.set_world(world, arrive)
	if _sect != null:
		for n in [_overlay, _labels]:
			if n != null:
				n.set_meta("hors_secteurs", true)
		_sect.plafonds(root)
		_lueur_tunnel = _lueur_fin_de_tunnel()
		_sect.classer(self, root)
		_maj_secteur(true)
	teleport(s.hero, s.companion)
	apply_options()
	_title.text = _p6.get("nom", "")
	_title_t = 3.5
	_zone_courante = ""


## Matières provisoires du Colisée (textures P4 existantes, teintées) : sol -> [clé MATS, teinte]
const SOLS := {
	"paves": ["paves", Color(0.86, 0.84, 0.9)],
	"plancher": ["plancher", Color(1.02, 0.94, 0.9)],
	"sable": ["terre", Color(0.98, 0.9, 0.8)],
}


func _build(e: Dictionary) -> void:
	var id: String = e.get("id", "")
	match e["type"]:
		"floor":
			if e["role"] == "decor":
				_decor_floor(e)
				return
			var r: Rect2 = e["rect"]
			var sol: String = _p6.get("sols", {}).get(id, "paves")
			var th := 0.3
			_static_box(_rect_center(r, e["h"] - th, e["h"]), Vector3(r.size.x, th, r.size.y), L_FLOOR)
			if sol == "sable":
				# sous le sable ovale : dallage sombre (les coins sont sous les gradins)
				_box_mesh(_rect_center(r, e["h"] - th, e["h"] - 0.01), Vector3(r.size.x, th - 0.01, r.size.y), _tinted("paves", Color(0.5, 0.48, 0.55)))
			else:
				var d: Array = SOLS.get(sol, SOLS["paves"])
				_box_mesh(_rect_center(r, e["h"] - th, e["h"]), Vector3(r.size.x, th, r.size.y), _tinted(d[0], d[1]))
		"block":
			_build_bloc_p6(e)
		"gate":
			pass
		_:
			super._build(e)


func _decor_floor(e: Dictionary) -> void:
	# hors du bâtiment : sol sombre non praticable (la ville viendra plus tard)
	var r: Rect2 = e["rect"]
	var c := Vector3(r.get_center().x, e["h"] - 0.17, r.get_center().y)
	var size := Vector3(r.size.x + 60.0, 0.3, r.size.y + 60.0)
	_static_box(c, size, L_NOWALK)
	if _hab != null:
		return                                  # parvis et bâtiments lointains : Habillage.exterieur
	var mi := _box_mesh(c, size, _tinted("paves", Color(0.2, 0.19, 0.25)))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_bloc_p6(e: Dictionary) -> void:
	var id: String = e["id"]
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	var size := Vector3(r.size.x, h1 - h0, r.size.y)
	var sb := _static_box(_rect_center(r, h0, h1), size, L_OBST)
	if id.begins_with("anneau_"):
		return                                          # podium : collision seule, maillage continu dans _build_arene
	if id.begins_with("cmur_"):
		var tall := h1 - h0 > 1.5
		if _hab != null and id.begins_with("cmur_tunnel_sud"):
			h1 = h0 + 1.7                       # rendu à la hauteur des gradins sud (collision inchangée : 2,6 m)
			size.y = h1 - h0
		var mpierre: Material = _hab.mat(Habillage.PIERRE, 2.4, Habillage.C_CALCAIRE, tall) if _hab != null else _surf("pierre", tall)
		# P6.2 : maillages du mur sous un pivot à l'origine (le mur s'abaisse vers le sol quand il est coupé) ;
		# la collision (sb) reste dans l'instance, jamais modifiée
		var pivot := Node3D.new()
		pivot.name = id
		pivot.set_meta("xz", r.get_center())
		pivot.set_meta("mur", true)
		root.add_child(pivot)
		var mi := _box_mesh(_rect_center(r, h0, h1), size, mpierre, pivot)
		fade_nodes[sb] = [mi]
		var mcap: Material = _hab.mat(Habillage.PIERRE, 2.4, Habillage.C_CALCAIRE * Color(1.12, 1.1, 1.08), tall) if _hab != null else _tinted("pierre", Color(1.12, 1.1, 1.14), tall)
		_box_mesh(_rect_center(r.grow(0.06), h1, h1 + 0.12), Vector3(r.size.x + 0.12, 0.12, r.size.y + 0.12), mcap, pivot)
		if _hab != null:
			_box_mesh(_rect_center(r.grow(0.05), h0, 0.3), Vector3(r.size.x + 0.1, 0.3, r.size.y + 0.1), _hab.mat(Habillage.PIERRE, 1.2, Habillage.C_CALCAIRE * Color(0.72, 0.7, 0.7)), pivot)
		if _sect != null:
			# tranche sombre du mur coupé (vue en coupe, comme une maquette tranchée) : affichée seulement si coupé
			var coupe := _box_mesh(_rect_center(r.grow(0.07), Secteurs.LIP - 0.01, Secteurs.LIP + 0.05), Vector3(r.size.x + 0.14, 0.06, r.size.y + 0.14), _mat_coupe())
			coupe.set_meta("xz", r.get_center())
			coupe.set_meta("mur", true)
			coupe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_sect.declarer_mur(pivot, coupe, r, h0, h1)
		return
	var nom := id.trim_prefix("meuble_")
	var bois := _surf("bois")
	if nom.begins_with("casiers"):
		_box_mesh(_rect_center(r, h0, h1), size, _tinted("bois", Color(0.85, 0.72, 0.62)))
		var along_x := r.size.x > r.size.y
		var n := int((r.size.x if along_x else r.size.y) / 0.8)
		for i in range(1, n):
			var t := float(i) / n
			var c := Vector3(lerpf(r.position.x, r.end.x, t), (h0 + h1) / 2.0, r.end.y + 0.01) if along_x else Vector3(r.end.x + 0.01, (h0 + h1) / 2.0, lerpf(r.position.y, r.end.y, t))
			_box_mesh(c, Vector3(0.04, h1 - h0 - 0.1, 0.02) if along_x else Vector3(0.02, h1 - h0 - 0.1, 0.04), _tinted("bois", Color(0.45, 0.36, 0.32)))
	elif nom.begins_with("banc"):
		_box_mesh(_rect_center(r, h1 - 0.08, h1), Vector3(r.size.x, 0.08, r.size.y), _surf("plancher"))
		for q in [0.15, 0.85]:
			var c := Vector3(lerpf(r.position.x, r.end.x, q), (h1 - 0.08) / 2.0, r.get_center().y) if r.size.x > r.size.y else Vector3(r.get_center().x, (h1 - 0.08) / 2.0, lerpf(r.position.y, r.end.y, q))
			_box_mesh(c, Vector3(0.12, h1 - 0.08, 0.12), bois)
	elif nom.begins_with("ratelier"):
		_box_mesh(_rect_center(r, h0, 0.12), Vector3(r.size.x, 0.12, r.size.y), bois)
		_box_mesh(_rect_center(r, h1 - 0.1, h1), Vector3(r.size.x, 0.1, r.size.y), bois)
		var along_x := r.size.x > r.size.y
		var n := int((r.size.x if along_x else r.size.y) / 0.35)
		for i in n:
			var t := (i + 0.5) / n
			var c := Vector3(lerpf(r.position.x, r.end.x, t), h1 * 0.5, r.get_center().y) if along_x else Vector3(r.get_center().x, h1 * 0.5, lerpf(r.position.y, r.end.y, t))
			_box_mesh(c, Vector3(0.05, h1 * 0.9, 0.05), _tinted("pierre", Color(1.3, 1.3, 1.4)))
	elif nom.begins_with("mannequin"):
		var c := Vector3(r.get_center().x, 0, r.get_center().y)
		_box_mesh(c + Vector3(0, 0.55, 0), Vector3(0.12, 1.1, 0.12), bois)
		_box_mesh(c + Vector3(0, 1.25, 0), Vector3(0.55, 0.5, 0.3), _tinted("bois", Color(0.95, 0.82, 0.6)))
		_box_mesh(c + Vector3(0, 1.62, 0), Vector3(0.26, 0.26, 0.26), _tinted("bois", Color(0.95, 0.82, 0.6)))
		_box_mesh(c + Vector3(0, 1.35, 0), Vector3(1.0, 0.1, 0.1), bois)
	elif nom.begins_with("pilier"):
		var mp: Material = _hab.mat(Habillage.PIERRE, 2.4, Habillage.C_CALCAIRE, true) if _hab != null else _surf("pierre", true)
		_box_mesh(_rect_center(r, h0, h1), size, mp)
		_box_mesh(_rect_center(r.grow(0.12), h0, 0.3), Vector3(r.size.x + 0.24, 0.3, r.size.y + 0.24), _surf("pierre"))
		_box_mesh(_rect_center(r.grow(0.12), h1 - 0.25, h1), Vector3(r.size.x + 0.24, 0.25, r.size.y + 0.24), _surf("pierre", true))
	elif nom.begins_with("lit"):
		_box_mesh(_rect_center(r, h0, 0.35), Vector3(r.size.x, 0.35, r.size.y), bois)
		_box_mesh(_rect_center(r.grow(-0.06), 0.35, h1), Vector3(r.size.x - 0.12, h1 - 0.35, r.size.y - 0.12), _tinted("facade", Color(0.92, 0.9, 0.86)))
	elif nom.begins_with("caisses") or nom.begins_with("coffre"):
		_card("props/cais01_caisse.png", Vector3(r.get_center().x, 0, r.get_center().y), minf(r.size.x, 1.2), {"anchor": 0.1, "blob": 0.9})
	elif nom.begins_with("tonneaux"):
		_card("props/tont01_tonneau.png", Vector3(r.get_center().x, 0, r.get_center().y), 0.9, {"anchor": 0.08, "blob": 0.8})
	elif nom.begins_with("etal"):
		_box_mesh(_rect_center(r, h0, 0.9), Vector3(r.size.x, 0.9, r.size.y), bois)
		_box_mesh(_rect_center(r.grow(0.15), 1.9, 2.0), Vector3(r.size.x + 0.3, 0.1, r.size.y + 0.6), _tinted("toit", Color(1.0, 0.8, 0.8)))
		for q in [Vector2(r.position.x, r.end.y), r.end]:
			_box_mesh(Vector3(q.x, 1.45, q.y + 0.2), Vector3(0.08, 0.9, 0.08), bois)
	elif nom.begins_with("fontaine"):
		_box_mesh(_rect_center(r, h0, h1), size, _surf("pierre"))
		var eau := StandardMaterial3D.new()
		eau.albedo_color = Color(0.3, 0.55, 0.78)
		eau.emission_enabled = true
		eau.emission = Color(0.2, 0.5, 0.7)
		eau.emission_energy_multiplier = 0.4
		_box_mesh(_rect_center(r.grow(-0.2), h1 - 0.1, h1 + 0.01), Vector3(r.size.x - 0.4, 0.11, r.size.y - 0.4), eau)
	else:
		_box_mesh(_rect_center(r, h0, h1), size, bois)


func _build_p6() -> void:
	if _hab != null:
		_hab.exterieur(world.decor)
		if _p6.get("zone", "") == "colisee":
			var avant := root.get_child_count()
			_hab.vestiaires(Rect2(16.0, 46.5, 20.0, 8.5))
			for i in range(avant, root.get_child_count()):
				root.get_child(i).set_meta("secteur", "S1")     # décor composé pour les vestiaires
	if _p6.has("arene"):
		_build_arene(_p6["arene"])
	for pid in _p6.get("pieces_fermees", {}):
		var q: Array = _p6["pieces_fermees"][pid]["rect"]
		var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
		var d: Array = SOLS.get(_p6["pieces_fermees"][pid]["sol"], SOLS["paves"])
		_box_mesh(_rect_center(r, -0.3, 0.0), Vector3(r.size.x, 0.3, r.size.y), _tinted(d[0], d[1] * Color(0.7, 0.7, 0.75)))
	for p in _p6.get("portes", []):
		_build_porte(p)
	for l in _p6.get("lumieres", []):
		var pos := Vector3(l[0], l[2], l[1])
		var interieur: bool = _sect != null and _sect.secteur_en(Vector2(l[0], l[1])) != Secteurs.EXT
		# P6.2 : dans les secteurs couverts, lanternes plus fortes, à ombres douces (la lumière du soleil est coupée)
		var dl: Vector3 = Vector3(l[3], 0, l[4]) if l.size() >= 5 else Vector3(0, 0, 0.6)
		_light(pos + dl, 2.4 if interieur else 1.3, 8.0 if interieur else 6.5)
		if interieur:
			var ol: OmniLight3D = _lights[-1][0]
			ol.shadow_enabled = true
			ol.light_size = 0.12
			ol.shadow_bias = 0.06
			ol.omni_attenuation = 1.6
		_halo(pos, 1.1, 0.45)
		_box_mesh(pos + Vector3(0, -0.15, 0) + dl * 0.15, Vector3(0.18, 0.3, 0.18), _tinted("bois", Color(0.6, 0.5, 0.4)))
	if _p6.get("zone", "") == "colisee":
		if _hab == null:                      # P6.2 : avec l'habillage, bannières peintes de part et d'autre de la porte
			_banniere(Vector3(26.0, 0.0, 46.3), Color(0.25, 0.32, 0.75))          # vestiaires, mur nord (côté porte)
			_banniere(Vector3(21.0, 0.0, 46.3), Color(0.25, 0.32, 0.75))
			_banniere(Vector3(31.0, 0.0, 46.3), Color(0.25, 0.32, 0.75))
			_banniere(Vector3(26.0, 0.0, 54.95), Color(0.72, 0.6, 0.25), 1.6)      # bannière de la Guilde (sud, basse)
		_banniere(Vector3(45.0, 0.0, 11.75), Color(0.72, 0.18, 0.22))
		_banniere(Vector3(55.0, 0.0, 11.75), Color(0.72, 0.18, 0.22))
	else:
		_banniere(Vector3(27.6, 0.0, 6.5), Color(0.72, 0.6, 0.25), 1.8)       # panneau de la Guilde (provisoire)


func _banniere(foot: Vector3, col: Color, h := 2.6) -> void:
	_box_mesh(foot + Vector3(0, h - 0.05, 0), Vector3(1.2, 0.08, 0.08), _surf("bois"))
	var sm := StandardMaterial3D.new()
	sm.albedo_color = col
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_box_mesh(foot + Vector3(0, h - 0.75, 0.02), Vector3(1.0, 1.35, 0.03), sm)
	var or_ := StandardMaterial3D.new()
	or_.albedo_color = Color(0.95, 0.8, 0.35)
	_box_mesh(foot + Vector3(0, h - 0.75, 0.04), Vector3(0.32, 0.32, 0.02), or_)


## Porte : fermée = solide (modèle logique + physique) et vantail / grille ; marque au sol aux couleurs du plan.
func _build_porte(p: Dictionary) -> void:
	var q: Array = p["rect"]
	var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
	var ouverte := porte_ouverte(p)
	var scen: bool = p.has("ouverte_a_partir_de") or p.has("fermee_a_partir_de")
	var col := C_OUVERT if ouverte else (C_SCENARISE if scen and not Progression.au_moins(p.get("fermee_a_partir_de", "zzz")) else C_FERME)
	if not ouverte and p.has("fermee_a_partir_de"):
		col = C_FERME
	var mark := StandardMaterial3D.new()
	mark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mark.albedo_color = col
	var mr := r.grow(0.06)
	_box_mesh(Vector3(mr.get_center().x, 0.012, mr.get_center().y), Vector3(mr.size.x, 0.02, mr.size.y), mark)
	if ouverte:
		if p.get("type", "") == "grille":
			_box_mesh(_rect_center(r, 2.5, 2.7), Vector3(r.size.x, 0.2, r.size.y), _tinted("pierre", Color(0.6, 0.6, 0.66)))
		return
	_portes_fermees[p["id"]] = {"texte": p.get("texte_ferme", "C'est fermé."), "c": r.get_center()}
	_static_box(_rect_center(r, 0.0, 2.6), Vector3(r.size.x, 2.6, r.size.y), L_OBST)
	world.solids.append({"id": p["id"], "kind": "rect", "rect": r, "h0": 0.0, "h1": 2.6})
	if p.get("type", "") == "grille":
		var fer := StandardMaterial3D.new()
		fer.albedo_color = Color(0.22, 0.22, 0.26)
		fer.metallic = 0.6
		fer.roughness = 0.5
		var along_x := r.size.x > r.size.y
		var length := r.size.x if along_x else r.size.y
		var n := int(length / 0.28)
		for i in n:
			var t := (i + 0.5) / n
			var c := Vector3(lerpf(r.position.x, r.end.x, t), 1.3, r.get_center().y) if along_x else Vector3(r.get_center().x, 1.3, lerpf(r.position.y, r.end.y, t))
			_box_mesh(c, Vector3(0.06, 2.6, 0.06), fer)
		for hh in [0.5, 1.4, 2.3]:
			_box_mesh(_rect_center(r, hh - 0.04, hh + 0.04), Vector3(r.size.x, 0.08, r.size.y) + (Vector3(0, 0, 0.04) if along_x else Vector3(0.04, 0, 0)), fer)
	else:
		_box_mesh(_rect_center(r, 0.0, 2.6), Vector3(r.size.x, 2.6, r.size.y), _tinted("bois", Color(0.72, 0.5, 0.42)))
		var c2 := r.get_center()
		_box_mesh(Vector3(c2.x, 1.2, c2.y), Vector3(r.size.x + 0.04, 0.12, r.size.y + 0.04), _tinted("pierre", Color(0.5, 0.48, 0.52)))


func porte_ouverte(p: Dictionary) -> bool:
	if p.has("fermee_a_partir_de"):
		if Progression.au_moins(p["fermee_a_partir_de"]):
			return bool(GameState.flags.get(Progression.CLE_COLISEE_ROUVERT, false))
		return true
	if p.has("ouverte_a_partir_de"):
		return Progression.au_moins(p["ouverte_a_partir_de"])
	return p.get("marque", "") != "fermee"


## Arène : sable ovale, podium continu, gradins à 5 rangs (plus bas au sud, côté caméra), loge officielle au nord-est,
## arcs des deux tunnels. Les collisions du podium sont les petits blocs « anneau_* » des données.
func _build_arene(a: Dictionary) -> void:
	var c := Vector2(a["centre"][0], a["centre"][1])
	var rx: float = a["rayons"][0]
	var ry: float = a["rayons"][1]
	var ep: float = a["anneau_ep"]
	var ah: float = a["anneau_h"]
	var prof: float = a["gradins_prof"]
	var rangs: int = a["rangs"]
	var tunnels: Array = []
	for t in a["tunnels"]:
		tunnels.append(Rect2(t[0], t[1], t[2] - t[0], t[3] - t[1]).grow(0.05))
	if _hab != null:
		_hab.arene(a, tunnels)
		_hab.loge(a["loge"])
		return
	var n := 120
	# sable
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		for v in [Vector3(c.x, 0.005, c.y), Vector3(c.x + rx * cos(a0), 0.005, c.y + ry * sin(a0)), Vector3(c.x + rx * cos(a1), 0.005, c.y + ry * sin(a1))]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	var sable := MeshInstance3D.new()
	sable.mesh = st.commit()
	sable.material_override = _tinted("terre", SOLS["sable"][1])
	root.add_child(sable)
	# marquage du combat (cercle clair au centre)
	var ring := StandardMaterial3D.new()
	ring.albedo_color = Color(0.72, 0.64, 0.5)
	_anneau_plat(c, 3.2, 3.08, 0.012, ring)
	# podium + gradins : quadrilatères entre deux ellipses, sautés dans les tunnels
	var pierre := _surf("pierre", true)
	var gradin := _tinted("pierre", Color(0.82, 0.78, 0.86), true)
	var faces_podium: Array = []
	var faces_gradins: Array = []
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var am := (a0 + a1) / 2.0
		var sud := maxf(0.0, sin(am))                   # 1 au sud (côté caméra), 0 au nord
		var k_h := lerpf(1.0, 0.42, sud)                # gradins sud abaissés : l'arène reste lisible
		var skip := false
		for rr in [rx + ep * 0.5, rx + ep + prof * 0.5, rx + ep + prof - 0.2]:
			var ky: float = ry + (rr - rx)
			var pm := Vector2(c.x + rr * cos(am), c.y + ky * sin(am))
			for t in tunnels:
				if (t as Rect2).has_point(pm):
					skip = true
		if skip:
			continue
		# podium : face intérieure + dessus
		faces_podium.append(_ring_quad(c, rx, ry, a0, a1, 0.0, ah, 0.0))
		faces_podium.append(_ring_top(c, rx, ry, rx + ep, ry + ep, a0, a1, ah))
		# gradins
		for k in rangs:
			var r0 := rx + ep + prof * k / rangs
			var r1 := rx + ep + prof * (k + 1) / rangs
			var hk := (ah + 0.25 + 0.55 * (k + 1)) * k_h + (1.0 - k_h) * 0.4
			var hprev := ah if k == 0 else (ah + 0.25 + 0.55 * k) * k_h + (1.0 - k_h) * 0.4
			faces_gradins.append(_ring_quad(c, r0, ry + (r0 - rx), a0, a1, hprev, hk, 0.0))
			faces_gradins.append(_ring_top(c, r0, ry + (r0 - rx), r1, ry + (r1 - rx), a0, a1, hk))
		# dos des gradins (mur extérieur)
		var rlast := rx + ep + prof
		var htop := (ah + 0.25 + 0.55 * rangs) * k_h + (1.0 - k_h) * 0.4
		faces_gradins.append(_ring_quad(c, rlast, ry + (rlast - rx), a1, a0, 0.0, htop + 0.6, 0.0))
	_faces(faces_podium, pierre)
	var gm := _faces(faces_gradins, gradin)
	gm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# arcs des tunnels (linteaux) côté arène
	for t in tunnels:
		var tr := t as Rect2
		if tr.size.y > tr.size.x:      # tunnel sud
			_box_mesh(Vector3(tr.get_center().x, 2.45, tr.position.y + 1.6), Vector3(tr.size.x + 0.8, 0.5, 0.6), _surf("pierre", true))
		else:
			_box_mesh(Vector3(tr.position.x + 1.4, 2.45, tr.get_center().y), Vector3(0.6, 0.5, tr.size.y + 0.8), _surf("pierre", true))
	# loge officielle (nord-est), visible depuis l'arène
	var lg: Dictionary = a["loge"]
	var lc := Vector3(lg["centre"][0], 0.0, lg["centre"][1])
	var ls := Vector2(lg["taille"][0], lg["taille"][1])
	var lh: float = lg["h"]
	_box_mesh(lc + Vector3(0, lh / 2.0, 0), Vector3(ls.x, lh, ls.y), _tinted("pierre", Color(0.95, 0.9, 0.95), true))
	_box_mesh(lc + Vector3(0, lh + 0.05, 0.1), Vector3(ls.x + 0.3, 0.1, ls.y + 0.2), _tinted("pierre", Color(1.15, 1.1, 1.1)))
	var rouge := StandardMaterial3D.new()
	rouge.albedo_color = Color(0.68, 0.14, 0.2)
	_box_mesh(lc + Vector3(0, lh - 0.7, ls.y / 2.0 + 0.03), Vector3(ls.x - 0.6, 1.0, 0.04), rouge)
	for dx in [-ls.x / 2.0 + 0.2, ls.x / 2.0 - 0.2]:
		_box_mesh(lc + Vector3(dx, lh + 1.0, ls.y / 2.0 - 0.2), Vector3(0.16, 2.0, 0.16), _surf("bois"))
	var toile := StandardMaterial3D.new()
	toile.albedo_color = Color(0.62, 0.16, 0.2)
	_box_mesh(lc + Vector3(0, lh + 2.05, 0), Vector3(ls.x + 0.4, 0.12, ls.y + 0.4), toile)
	var or_ := StandardMaterial3D.new()
	or_.albedo_color = Color(0.95, 0.78, 0.3)
	or_.emission_enabled = true
	or_.emission = Color(0.6, 0.45, 0.1)
	_box_mesh(lc + Vector3(0, lh - 0.7, ls.y / 2.0 + 0.06), Vector3(0.5, 0.5, 0.02), or_)


func _ring_quad(c: Vector2, rx: float, ry: float, a0: float, a1: float, h0: float, h1: float, _x: float) -> Array:
	var p0 := Vector3(c.x + rx * cos(a0), h0, c.y + ry * sin(a0))
	var p1 := Vector3(c.x + rx * cos(a1), h0, c.y + ry * sin(a1))
	return [[p0, Vector3(p0.x, h1, p0.z), Vector3(p1.x, h1, p1.z), p1], [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]]


func _ring_top(c: Vector2, rx0: float, ry0: float, rx1: float, ry1: float, a0: float, a1: float, h: float) -> Array:
	var p0 := Vector3(c.x + rx0 * cos(a0), h, c.y + ry0 * sin(a0))
	var p1 := Vector3(c.x + rx0 * cos(a1), h, c.y + ry0 * sin(a1))
	var q1 := Vector3(c.x + rx1 * cos(a1), h, c.y + ry1 * sin(a1))
	var q0 := Vector3(c.x + rx1 * cos(a0), h, c.y + ry1 * sin(a0))
	return [[p0, q0, q1, p1], [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)]]


func _anneau_plat(c: Vector2, r0: float, r1: float, h: float, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 64
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var v := [Vector3(c.x + r0 * cos(a0), h, c.y + r0 * sin(a0)), Vector3(c.x + r0 * cos(a1), h, c.y + r0 * sin(a1)),
			Vector3(c.x + r1 * cos(a1), h, c.y + r1 * sin(a1)), Vector3(c.x + r1 * cos(a0), h, c.y + r1 * sin(a0))]
		for j in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v[j])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	root.add_child(mi)


# ------------------------------------------------------------------------------------------------ interactions
func _pnj_proche() -> String:
	var hp := Vector2(s.hero.x, s.hero.y)
	var best := ""
	var bd := INF
	for id in _pnj:
		var d: float = hp.distance_to(_pnj[id]["p"])
		if d <= float(_pnj[id]["def"].get("portee_m", PORTEE_PARLER)) and d < bd:
			bd = d
			best = id
	return best


func _examen_proche() -> Dictionary:
	var hp := Vector2(s.hero.x, s.hero.y)
	for e in _p6.get("examens", []):
		if hp.distance_to(Vector2(e["xy"][0], e["xy"][1])) <= float(e.get("portee_m", 1.4)):
			return {"id": e["id"], "texte": e["texte"]}
	for id in _portes_fermees:
		var pc: Vector2 = _portes_fermees[id]["c"]
		if hp.distance_to(pc) <= 1.6:
			return {"id": id, "texte": _portes_fermees[id]["texte"]}
	return {}


func dialogue_is_open() -> bool:
	return (_dialog != null and _dialog.is_open()) or _bloque


func interact_override() -> bool:
	if _bloque:
		return true
	if _dialog.is_open():
		if not _dialog.showing_choice():
			_dialog.advance()
		else:
			_dialog.advance()             # valide le choix en surbrillance
		return true
	if s.dialogue_open:
		return false                      # boîte d'examen : la session fait avancer / ferme
	var id := _pnj_proche()
	if id != "":
		parler(id)
		return true
	var ex := _examen_proche()
	if not ex.is_empty():
		_examiner(ex)
		return true
	return false


func _examiner(ex: Dictionary) -> void:
	s._lines = [ex["texte"]]
	s._line_i = 0
	s.dialogue_open = true
	s.cam.ui_lock = true
	s._box.visible = true
	s._box_text.text = ex["texte"]
	_log("examen", {"id": ex["id"]})


## Variante de dialogue : la première dont l'état « a_partir_de » est atteint.
func variante_dialogue(cle: String) -> Dictionary:
	for v in _dialogues_p6.get(cle, []):
		if Progression.au_moins(v.get("a_partir_de", Progression.INTRO_NOT_STARTED)):
			return v
	return {}


func parler(id: String, cle := "") -> void:
	var n: Dictionary = _pnj[id]
	var d: Dictionary = n["def"]
	var v := variante_dialogue(cle if cle != "" else str(d["dialogue"]))
	if v.is_empty():
		return
	_effet = v.get("effet", "")
	_parle_a = id
	var spk := {"heros": {"name": GameState.hero_name}, "pnj": {"name": d["nom"]}}
	_dialog.right_id = str(d.get("portrait", "pnj"))
	s.dialogue_open = true
	s.cam.ui_lock = true
	var np: Vector2 = n["p"]
	var vers := World25.plan_to_screen_dir(np - Vector2(s.hero.x, s.hero.y))
	actors["aren"]["actor"].face_toward(vers)
	if _anim_aren != null:
		_anim_aren.step(actors["aren"]["actor"], 0.0, false, vers.x)
	_sync_sprite(actors["aren"])
	actors[n["key"]]["actor"].face_toward(World25.plan_to_screen_dir(Vector2(s.hero.x, s.hero.y) - np))
	_dialog.open(v["etapes"], spk)
	_log("dialogue", {"pnj": id, "dialogue": cle if cle != "" else d["dialogue"], "etat": Progression.etat()})


func _on_dialog_closed() -> void:
	super._on_dialog_closed()
	var e := _effet
	var qui := _parle_a
	_effet = ""
	_parle_a = ""
	match e:
		"consigne_arene":
			Progression.definir(Progression.TUTORIAL_AVAILABLE)
			Progression.definir_objectif("rejoindre_arene")
			_maj_objectif()
		"lancer_tutoriel":
			if qui == "commandant" and not Progression.au_moins(Progression.TUTORIAL_IN_PROGRESS):
				_lancer_tutoriel()
		"passer_tutoriel":
			if qui == "commandant" and not Progression.au_moins(Progression.TUTORIAL_IN_PROGRESS):
				_passer_tutoriel()


## Démonstration / tests : réponse automatique. Les réponses à effet (passer le tutoriel) ne sont prises que sur demande
## (-- --passer_tutoriel) ; sinon --choix=N parmi les réponses ordinaires.
func _choix_auto(choix: Array) -> int:
	var ordinaires: Array = []
	for i in choix.size():
		if choix[i].has("effet"):
			if _cli.has("passer_tutoriel"):
				return i
		else:
			ordinaires.append(i)
	if ordinaires.is_empty():
		return 0
	return ordinaires[clampi(int(_cli.get("choix", 0)), 0, ordinaires.size() - 1)]


## P6.2 — réponse choisie dans un dialogue : une réponse peut remplacer l'effet du dialogue (ex. passer le tutoriel).
func _on_choix(c: Dictionary) -> void:
	if c.has("effet"):
		_effet = str(c["effet"])
		_log("choix", {"effet": _effet})


## P6.2 — saut du tutoriel depuis le dialogue : même conclusion que la fin du combat (Progression.conclure_tutoriel).
func _passer_tutoriel() -> void:
	_bloque = true
	s.dialogue_open = true
	_log("tutoriel_passe", {"moment": "dialogue"})
	Progression.conclure_tutoriel(scene_file_path)


func _lancer_tutoriel() -> void:
	_bloque = true
	s.dialogue_open = true
	Progression.definir(Progression.TUTORIAL_IN_PROGRESS)
	_log("tutoriel_lance", {})
	GameState.from_zone = true
	GameState.proto = true
	GameState.arena = "colisee"
	GameState.explore_return = scene_file_path
	GameState.last_battle_result = ""
	s.toast("Évaluation : combat d'entraînement", 1.2)
	var tw := create_tween()
	tw.tween_interval(0.5)
	await tw.finished
	if _cli.has("sans_combat"):
		return                                          # outil de test : on s'arrête au lancement
	GameState.goto(Progression.SCENE_TUTORIEL, 0.45)


func _jouer_fin_tutoriel() -> void:
	await get_tree().create_timer(0.7).timeout
	if _pnj.has("commandant"):
		parler("commandant", "commandant_fin")
	_maj_objectif()


func _switch(t: Dictionary) -> void:
	if str(t.get("id", "")) == "sortie_est":
		Progression.definir(Progression.COLISEUM_EXITED)
		_log("sortie_colisee", {})
	super._switch(t)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if _p6.get("zone", "") == "quartier":
		s.toast("Les portes du Colisée se referment derrière vous.", 3.0)


# ------------------------------------------------------------------------------------------------ boucle
func _unhandled_input(e: InputEvent) -> void:
	if _switching or _bloque:
		return
	if _dialog.is_open():
		if e is InputEventKey and e.pressed and not e.echo:
			_dialog.handle_key(e)
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_C:
		cam_p6 = CAMS_P6_ORDRE[(CAMS_P6_ORDRE.find(cam_p6) + 1) % CAMS_P6_ORDRE.size()]
		cam_mode = CAMS_P6[cam_p6][0]
		s.arch = "P6 — Colisée · " + CAMS_P6_LABEL[cam_p6]
		_reload_here()
		s.cam.set_index(CAMS_P6[cam_p6][1], false)
		s.toast("Caméra " + CAMS_P6_LABEL[cam_p6], 2.5)
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_H:
		habillage = not habillage
		_reload_here()
		s.toast("Habillage : " + ("pilote P6.1" if habillage else "blockout P6"), 2.5)
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_B:
		aren_variante = AREN_VARIANTES[(AREN_VARIANTES.find(aren_variante) + 1) % AREN_VARIANTES.size()]
		_sync_sprite(actors["aren"])
		s.toast("Aren : " + {"foret": "apparence de la forêt (V09B.5 + V4)", "p48": "P4.8 (art/p45)"}[aren_variante], 2.5)
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_P:
		s.start_pilot("p6_avant" if not Progression.au_moins(Progression.TUTORIAL_COMPLETED) else "p6_apres")
		return
	super._unhandled_input(e)


func _physics_process(delta: float) -> void:
	if _bloque:
		return
	if _dialog.is_open() and (s.pilot.size() > 0 or GameState.autoplay):
		_auto_p6_t += delta
		if _auto_p6_t > 0.5:
			_auto_p6_t = 0.0
			if _dialog.showing_choice():
				_dialog.pick(_choix_auto(_dialog._choices))
			else:
				_dialog.advance()
	_auto_dialog_t = -1.0e9                     # l'avancée automatique héritée de l'avant-poste ne doit pas choisir à notre place
	super._physics_process(delta)
	if _switching or world == null or _bloque:
		return
	_pnj_step(delta)
	_suivi_secteur(delta)
	_afficher_touches()
	_suivi_zones()
	_commandant_auto()
	if _cli.has("quitter_fin") and s.pilot_done and s.pilot_name == "p6_apres" and not _dialog.is_open() and not s.dialogue_open:
		_cli.erase("quitter_fin")
		await get_tree().create_timer(1.5).timeout
		get_tree().quit()                      # démonstration filmée : fin du parcours


func _suivi_zones() -> void:
	var hp := Vector2(s.hero.x, s.hero.y)
	var z := ""
	var nom := ""
	for zn in _p6.get("zones_nommees", []):
		var q: Array = zn["rect"]
		if Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]).has_point(hp):
			z = zn["id"]
			nom = zn["nom"]
	if z == _zone_courante:
		return
	_zone_courante = z
	if z == "":
		return
	_title.text = nom
	_title_t = 2.6
	_log("zone", {"zone": z})
	if z in ["salle_attente", "arene"] and not Progression.au_moins(Progression.TUTORIAL_AVAILABLE):
		Progression.definir(Progression.TUTORIAL_AVAILABLE)
		Progression.definir_objectif("rejoindre_arene")
		_maj_objectif()
	if z == "arene" and not Progression.au_moins(Progression.TUTORIAL_IN_PROGRESS):
		if Progression.objectif() != "parler_commandant":
			Progression.definir_objectif("parler_commandant")
			_maj_objectif()
		if not _appel_fait:
			_appel_fait = true
			s.toast("Commandant : « Approchez, recrue ! »", 2.4)


func _commandant_auto() -> void:
	if not _pnj.has("commandant") or Progression.au_moins(Progression.TUTORIAL_IN_PROGRESS) or s.dialogue_open:
		return
	var d: float = Vector2(s.hero.x, s.hero.y).distance_to(_pnj["commandant"]["p"])
	if d > COMMANDANT_AUTO_M + 1.5:
		_cmd_arme = true
	elif d <= COMMANDANT_AUTO_M and _cmd_arme:
		_cmd_arme = false
		parler("commandant")


func _process(delta: float) -> void:
	super._process(delta)
	if s == null or world == null:
		return
	var hint := ""
	if not s.dialogue_open and not _bloque:
		var id := _pnj_proche()
		if id != "":
			hint = "E  Parler — " + str(_pnj[id]["def"]["nom"])
		elif not _examen_proche().is_empty():
			hint = "E  Examiner"
	_prompt.text = hint
	_prompt.position = Vector2((Session25.viewport_size(self).x - _prompt.size.x) / 2.0, Session25.viewport_size(self).y - 120.0)
	if _obj_flash > 0.0:
		_obj_flash -= delta
		var k := 0.5 + 0.5 * sin(_obj_flash * 9.0)
		_obj_panel.modulate = Color(1.0 + 0.35 * k * minf(1.0, _obj_flash), 1.0 + 0.25 * k * minf(1.0, _obj_flash), 1.0)
	else:
		_obj_panel.modulate = Color.WHITE


# ------------------------------------------------------------------------------------------------ outils
func _log(kind: String, data: Dictionary) -> void:
	var e := data.duplicate()
	e["type"] = kind
	_journal.append(e)
	if _cli.has("route") or _cli.has("trace"):
		print("P6 %s %s" % [kind, JSON.stringify(data)])


func journal() -> Array:
	return _journal


func _prefix() -> String:
	return "P6" + (("_" + str(_cli["tag"])) if _cli.has("tag") else "")


## Vue du dessus orthographique de tout le Colisée (comparaison avec le plan) : capture puis quitte.
func _vue_dessus_p6() -> void:
	set_physics_process(false)
	_tilt.visible = false
	s.hud.visible = false
	var q: Array = _p6.get("camera_vue_dessus", [0, 0, 66, 58])
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.basis = Basis(Vector3.RIGHT, -PI / 2.0)
	var vp: Vector2 = Session25.viewport_size(self)
	cam.size = maxf(q[3] - q[1], (q[2] - q[0]) * vp.y / vp.x) * 1.02
	cam.position = Vector3((q[0] + q[2]) / 2.0, 80.0, (q[1] + q[3]) / 2.0)
	cam.far = 200.0
	cam.reset_physics_interpolation()
	RenderingServer.global_shader_parameter_set("p4_hole", 0.0)
	for i in 10:
		await get_tree().process_frame
	capture("vue_dessus")
	get_tree().quit()


## Décor du combat tutoriel : l'arène elle-même, vue depuis le sable (caméra de combat), sans personnages ni
## interface ; enregistré dans art/p6/combat/arene_colisee.png (1280 × 720), affiché 1:1 par la scène de combat.
func _decor_combat() -> void:
	set_physics_process(false)
	_tilt.visible = false
	s.hud.visible = false
	body.visible = false
	for k in actors:
		if str(k).begins_with("pnj"):
			(actors[k]["node"] as Node3D).visible = false
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 46.0
	cam.position = Vector3(26.0, 3.1, 31.2)
	cam.look_at(Vector3(26.0, 0.9, 19.5), Vector3.UP)
	cam.far = 200.0
	cam.reset_physics_interpolation()
	RenderingServer.global_shader_parameter_set("p4_hole", 0.0)
	RenderingServer.global_shader_parameter_set("p4_persp", 1.0)
	for i in 12:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var out: String = _cli.get("out", "res://art/p6/combat")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	img.save_png(ProjectSettings.globalize_path(out).path_join("arene_colisee.png"))
	print("P6 décor de combat : ", out.path_join("arene_colisee.png"), " ", img.get_size())
	get_tree().quit()


# ------------------------------------------------------------------------------------------------ secteurs (P6.2)
var _m_coupe: StandardMaterial3D


## Tranche des murs coupés : pierre sombre, comme la coupe d'une maquette (on ne croit pas pouvoir marcher dessus).
func _mat_coupe() -> StandardMaterial3D:
	if _m_coupe == null:
		_m_coupe = StandardMaterial3D.new()
		_m_coupe.albedo_color = Color(0.09, 0.075, 0.07)
		_m_coupe.roughness = 1.0
	return _m_coupe


## Lumière de l'arène au bout du tunnel, vue depuis la salle d'attente tant que l'arène n'est pas affichée.
func _lueur_fin_de_tunnel() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(3.0, 2.5)
	mi.mesh = qm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.92, 0.78, 0.55)
	m.emission_enabled = true
	m.emission = Color(0.9, 0.72, 0.45)
	m.emission_energy_multiplier = 0.35
	mi.material_override = m
	mi.position = Vector3(26.0, 1.25, 31.9)
	var l := OmniLight3D.new()                     # le jour de l'arène éclaire le bout du tunnel
	l.light_color = Color(1.0, 0.88, 0.7)
	l.light_energy = 1.4
	l.omni_range = 6.0
	l.position = Vector3(0, 0.6, 1.4)
	mi.add_child(l)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("hors_secteurs", true)
	root.add_child(mi)
	return mi


## Applique le secteur actif : visibilité (module Secteurs), lueur du tunnel, ambiance et limites de caméra.
func _maj_secteur(immediat := false) -> void:
	if _sect == null:
		return
	var change: bool = _sect.mettre_a_jour(Vector2(s.hero.x, s.hero.y), immediat)
	if not change and not immediat:
		return
	if _lueur_tunnel != null:
		_lueur_tunnel.visible = _sect.est_visible("S3") and not _sect.est_visible(Secteurs.EXT)
	var sombre: bool = _sect.fond() == "sombre"
	if sombre:
		_env_res.background_mode = Environment.BG_COLOR
		_env_res.background_color = Color(0.022, 0.018, 0.026)
	elif _hab != null:
		_env_res.background_mode = Environment.BG_SKY
	_amb_but = 0.3 if sombre else (0.62 if _hab != null else 0.85)
	if immediat:
		_env_res.ambient_light_energy = _amb_but
	var cr: Rect2 = _sect.camera_rect()
	_bornes_but = world.camera_bounds() if cr.size == Vector2.ZERO else _bornes_ecran(cr)
	if immediat:
		s.cam.bounds = _bornes_but
	_log("secteur", {"secteur": _sect.actif, "visibles": _sect.visibles, "murs_coupes": _sect.murs_coupes().size()})


## Rectangle du plan -> limites écran (px natifs) : sol et hauts de murs (3,4 m), petite marge.
func _bornes_ecran(r: Rect2) -> Rect2:
	var b := Rect2(World25.screen(Vector3(r.position.x, r.position.y, 0.0)), Vector2.ZERO)
	for x in [r.position.x - 0.5, r.end.x + 0.5]:
		for y in [r.position.y - 0.5, r.end.y + 0.5]:
			for hh in [0.0, 3.4]:
				b = b.expand(World25.screen(Vector3(x, y, hh)))
	return b.grow(10.0)


func _suivi_secteur(delta: float) -> void:
	if _sect == null:
		return
	_maj_secteur()
	var k := 1.0 - exp(-5.0 * delta)
	var b: Rect2 = s.cam.bounds
	s.cam.bounds = Rect2(b.position.lerp(_bornes_but.position, k), b.size.lerp(_bornes_but.size, k))
	if _amb_but >= 0.0:
		_env_res.ambient_light_energy = lerpf(_env_res.ambient_light_energy, _amb_but, k)


var _touches: Label
const FLECHES := {Vector2i(0, -1): "↑", Vector2i(0, 1): "↓", Vector2i(-1, 0): "←", Vector2i(1, 0): "→",
	Vector2i(1, -1): "↑ →", Vector2i(-1, -1): "↑ ←", Vector2i(1, 1): "↓ →", Vector2i(-1, 1): "↓ ←"}


## Vidéos de circulation (-- --touches) : touches de déplacement utilisées à l'image, secteur actif.
func _afficher_touches() -> void:
	if not _cli.has("touches"):
		return
	if _touches == null:
		_touches = Label.new()
		_touches.add_theme_font_size_override("font_size", 26)
		_touches.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		_touches.add_theme_constant_override("outline_size", 8)
		_touches.position = Vector2(24, 640)
		s.hud.add_child(_touches)
	var d: Vector2 = s.derniere_touche
	var k := Vector2i(int(signf(d.x)), int(signf(d.y)))
	var t: String = FLECHES.get(k, "—")
	if k != Vector2i.ZERO and (force_run or Input.is_physical_key_pressed(KEY_SHIFT)):
		t += "  + Maj (course)"
	_touches.text = "Touches : %s      ·      %s" % [t, _sect.nom_actif() if _sect != null else ""]


func secteur_actif() -> String:
	return _sect.actif if _sect != null else ""
