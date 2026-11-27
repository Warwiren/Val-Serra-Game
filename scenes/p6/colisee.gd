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
const Routes = preload("res://src/explore25/routes25.gd")
const ZONE_QUARTIER := "res://data/p6/quartier_initial.json"
## P7.1 : blockout V0.1 du quartier central (plan directeur V0.5), PROTOTYPE NON VALIDÉ. Actif seulement dans la scène
## -- --ville=v05 (scène F6 retirée en P7.12.2) : la sortie est du Colisée y mène au lieu du quartier
## provisoire, qui reste la destination par défaut du Colisée (aucune scène validée n'est remplacée).
const ZONE_VILLE := "res://data/p7/ville_v05.json"
const VilleBlockout := preload("res://scenes/p7/ville_blockout.gd")
@export var ville_v05 := false
var _ville_on := false
var _ville
## P7.3 : VILLE V0.6, démonstration verticale (porte sud -> guilde -> grande place -> quartier haut), PROTOTYPE NON
## VALIDÉ. -- --ville=v06 (scène F6 retirée en P7.12.2). Caméra propre à la ville (CAMS « V06 » de
## avant_poste.gd) : une seule distance (zoom ×3 fixe, molette et PgPréc / PgSuiv sans effet), plongée abaissée,
## altitude lissée ; touche C : V0.6 perspective / V0.6 orthographique / caméra V0.5 (P24, comparaison).
## Le Colisée et la forêt gardent leur caméra (elle est rétablie en quittant la ville).
const ZONE_VILLE_V06 := "res://data/p7/ville_v06.json"
const VilleV06 := preload("res://scenes/p7/ville_v06.gd")
const CAMS_V06 := ["V06", "V06O", "P24"]
const CAMS_V06_LABEL := {"V06": "V0.6 — perspective 11°, champ 30° (proposée)", "V06O": "V0.6 — orthographique, même plongée (comparaison)",
	"P24": "V0.5 — P24 ×3 (référence avant)"}
const PLONGEE_V06 := 11.0                 # degrés (le Colisée : 24°) ; avec le champ de 30°, horizon vers 15 % du haut
const CHAMP_V06 := 30.0
const AIM_V06 := 0.1                      # Aren un peu sous le centre : la vue porte plus loin vers le nord (la montée)
const ZOOM_V06 := 2                        # ×3, la distance validée du Colisée
@export var ville_v06 := false
@export var forge_variante := ""          # P7.9 : comparatif de la forge-armurerie (A / B / C ; vide : blockout)
## P7.4 : VILLE V0.7-A (micro-blockout semi-circulaire), -- --ville=v07a (scène F6 retirée en P7.12.2). Même
## caméra que la V0.6 (A : fixe vers le nord) ; B : caméra SEMI-FIXE, même projection, même distance, orientation propre
## à 2 secteurs des données (« zones_camera », hystérésis), rotation douce, commandes verrouillées pendant la rotation.
## Touche V ou -- --camera_ville=A|B. Repli sur A : touche V, ou B sans zones dans les données.
const ZONE_VILLE_V07A := "res://data/p7/ville_v07a.json"
const VilleV07A := preload("res://scenes/p7/ville_v07a.gd")
@export var ville_v07a := false
## P7.5 : VILLE V0.7-B, reconstruction compacte du quartier central (scène F6 scenes/p7/ville_v07b.tscn, -- --ville=v07b).
## Mêmes systèmes que la V0.7-A (caméra A par défaut, B en comparaison, portail du Colisée) ; la V0.7-A reste en référence.
const ZONE_VILLE_V07B := "res://data/p7/ville_v07b.json"
const VilleV07B := preload("res://scenes/p7/ville_v07b.gd")
@export var ville_v07b := false
var camera_ville := "A"
var _yaw_base := 0.0
var _yaw_cible := 0.0
var _yaw_vit := 0.0
var _zone_cam := ""
var _yaw_snap := true
const YAW_TAU := 0.55                        # s : rapidité de la rotation (amortissement critique)
const YAW_VMAX := 14.0                       # °/s au plus
var _ville_ver := "v05"
var cam_v06 := "V06"
var _cam_ville := false                    # la caméra de la ville V0.6 est en place (sinon : caméra du Colisée)
const DIALOGUES_P6 := "res://data/p6/dialogues_colisee.json"
const PNJ_P6 := "res://data/p6/pnj_colisee.json"
const QUALITE_OMBRE := 4                  # ombres douces qualité 4 (référence P5.3 retenue)
const QUALITE_OMBRE_DEFAUT := 2
const PNJ_R := 0.35
const AnimV09B5 = preload("res://src/explore25/anim_v09b5.gd")
const Habillage = preload("res://scenes/p6/habillage_p6.gd")
const Secteurs = preload("res://src/explore25/secteurs25.gd")
## P6.1 — réglages de caméra comparés (touche C) : [nom, préréglage, indice de zoom (0 : ×2, 1 : ×2,5, 2 : ×3)]
## P7.4.1 : « V » = caméra V0.7-A de la ville, adoptée PROVISOIREMENT dans le Colisée (décision du 24/11/2026) : perspective
## 11°, champ 30°, distance unique ×3 (zoom manuel désactivé), altitude lissée. A / B / C : caméras P6 en comparaison (C).
const CAMS_P6 := {"V": ["V06", 2], "A": ["P30", 1], "B": ["P30", 2], "C": ["P24", 2]}
const CAMS_P6_ORDRE := ["V", "A", "B", "C"]
const CAMS_P6_LABEL := {"V": "V — V0.7-A (perspective 11°, distance fixe)", "A": "A — P30 ×2,5 (P6)", "B": "B — P30 ×3",
	"C": "C — P24 ×3 (réglage de la forêt)"}
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
var cam_p6 := "V"
## P6.2 : azimut du Colisée validé le 22/11/2026 : 0° (référence 20° : -- --azimut=20 ; scène retirée en P7.2) ; -- --azimut= l'emporte
@export var azimut_initial := 0.0
## P6.2-D : longueur du tunnel sud (comparaison) : "" = données par défaut (colisee.json), "A" 6,5 m, "B" 8,5 m, "C" 9,5 m.
## -- --tunnel=A|B|C l'emporte ; le choix est gardé pour la session (retour du combat tutoriel).
@export var tunnel_variante := ""
static var _tunnel_session := ""
var _dy_sud := 0.0
var aren_variante := "foret"
var _anim_aren: RefCounted
var _auto_p6_t := 0.0
## P6.2-B : mode de transition des intérieurs (touche J, -- --transitions=A|B|C) ; B (continu) par défaut
const TRANSITIONS := {"A": "echelle", "B": "continu", "C": "porte"}
const TRANSITIONS_LABEL := {"A": "A — P6.2 (pièces qui descendent / remontent)", "B": "B — continu (architecture persistante, estompage sur place)", "C": "C — porte (bref fondu sombre au franchissement)"}
const H_VIS := 6.0                           # hauteur AFFICHÉE des murs d'intérieur en B / C (collision inchangée)
const H_TUNNEL := 3.1                        # P6.2-C : murs du tunnel à hauteur de voûte (et non H_VIS), jamais coupés
const VueTunnel := preload("res://src/p6/vue_tunnel.gdshader")
const PORTES_C := [["P12", "S1"]]          # mode C : seuils traités comme de vraies portes (fondu)
var transitions := "B"
var _fondu_porte := false
var _fond_but := Color(0.022, 0.018, 0.026)
var _sect                                  # P6.2 : visibilité par secteurs (null si la zone n'en déclare pas)
var _lueur_tunnel: MeshInstance3D
var _bornes_but := Rect2()
var _amb_but := -1.0
var habillage := true                       # P6.1 : pilote d'habillage (touche H : pilote / blockout P6)
## P6.4 : pilote de direction artistique (touche M ; -- --p64=0 : état P6.3.2) ; porte fermée vue en coupe (touche U ;
## -- --porte_coupe=p632|coupe|silhouette)
var p64 := true
var porte_coupe := "C"
const PORTES_COUPE := ["C", "coupe", "silhouette", "p632"]
## P6.4.1 : état de comparaison (touche M) : "0" = P6.3.2, "1" = premier pilote P6.4, "2" = second pilote,
## "3" = extension P6.4.2 à tout le Colisée (défaut) ; galerie des écoinçons (touche K ; -- --galerie=A|B|p64)
var pilote := "3"
var galerie := "A"
const GALERIES := ["A", "B", "p64"]
var _marques_portes: Array = []             # P6.4.1 : [Sprite3D, centre xz] (indication discrète des portes fermées)
var _hab


## P6.4.1 : réglages par défaut de chaque état de comparaison (galerie, porte) ; la ligne de commande l'emporte.
func _defauts_pilote() -> void:
	# P6.4.2 : galerie B (structure mixte) et porte C retenues par le créateur après P6.4.1
	galerie = {"3": "B", "2": "A"}.get(pilote, "p64")
	porte_coupe = "C" if pilote in ["2", "3"] else "silhouette"


func _ready() -> void:
	_cli = parse_cli()
	variante = "B"
	cam_p6 = str(_cli.get("cam_p6", cam_p6)).to_upper()
	_diag_on = _cli.has("diag")
	_isoler = str(_cli.get("isoler", ""))        # P6.3.2 : diagnostic des clignotements (ombres, occultation, trouee, fondus)
	eblouissement = str(_cli.get("eblouissement", eblouissement))
	pilote = str(_cli.get("p64", "3"))
	if not pilote in ["0", "1", "2", "3"]:
		pilote = "3"
	_defauts_pilote()
	p64 = pilote != "0"
	porte_coupe = str(_cli.get("porte_coupe", porte_coupe))
	if not PORTES_COUPE.has(porte_coupe):
		porte_coupe = "C"
	galerie = str(_cli.get("galerie", galerie))
	if not GALERIES.has(galerie):
		galerie = "A"
	if not CAMS_P6.has(cam_p6):
		cam_p6 = "V"
	cam_mode = CAMS_P6[cam_p6][0]
	habillage = str(_cli.get("habillage", "pilote")) != "blockout"
	transitions = str(_cli.get("transitions", transitions)).to_upper()
	if not TRANSITIONS.has(transitions):
		transitions = "B"
	aren_variante = str(_cli.get("aren", aren_variante))
	if not AREN_VARIANTES.has(aren_variante):
		aren_variante = "foret"
	paysage = "aucun"
	arch_label = "P6 — Colisée"
	# P6.2 : azimut de la caméra propre au Colisée (comparaison 20° / 0°) ; la forêt et l'avant-poste gardent 20°
	World25.yaw = deg_to_rad(float(_cli.get("azimut", azimut_initial)))
	_yaw_base = World25.yaw
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
	s._help.text = "Flèches / ZQSD : marcher  ·  Maj : courir  ·  E / Entrée : parler, examiner  ·  C : caméra (V : distance fixe ; A / B / C : molette)  ·  B : Aren  ·  H : habillage  ·  J : transitions  ·  M : pilote  ·  K : galerie  ·  U : porte  ·  F1 : infos"
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
	var retour: bool = GameState.explore_return == scene_file_path and GameState.last_battle_result != ""
	_ville_on = ville_v05 or ville_v06 or ville_v07a or ville_v07b or str(_cli.get("ville", "")) in ["v05", "v06", "v07a", "v07b"]
	_ville_ver = "v06" if (ville_v06 or str(_cli.get("ville", "")) == "v06") else "v05"
	if ville_v07a or str(_cli.get("ville", "")) == "v07a":
		_ville_ver = "v07a"
	if ville_v07b or str(_cli.get("ville", "")) == "v07b":
		_ville_ver = "v07b"
	camera_ville = "B" if str(_cli.get("camera_ville", "A")).to_upper() == "B" else "A"
	cam_v06 = str(_cli.get("cam_v06", cam_v06)).to_upper()
	if not cam_v06 in CAMS_V06:
		cam_v06 = "V06"
	if (ville_v05 or ville_v06 or ville_v07a or ville_v07b) and not _cli.has("etat") and not _cli.has("neuf") and not retour:
		# P7.1 : la scène du blockout commence dans la ville, après le Colisée (objectif : la Guilde)
		Progression.definir(Progression.COLISEUM_EXITED, true)
		Progression.definir_objectif("guilde_badge")
	# P6.4.2 : au retour du tutoriel (même processus), l'état imposé au lancement n'est pas réappliqué (vidéo continue)
	if _cli.has("neuf") and not retour:
		Progression.reinitialiser()
	if _cli.has("etat") and not retour:
		Progression.definir(str(_cli["etat"]), true)
		if Progression.au_moins(Progression.TUTORIAL_COMPLETED):
			Progression.definir_objectif("guilde_badge")
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
	if _cli.has("tunnel"):
		_tunnel_session = str(_cli["tunnel"]).to_upper()
	elif tunnel_variante != "" and not retour:
		_tunnel_session = tunnel_variante
	var zcol := ZONE_COLISEE if _tunnel_session == "" else "res://data/p6/colisee_tunnel_%s.json" % _tunnel_session
	var zone := (_zone_ville() if _ville_on else ZONE_QUARTIER) if Progression.au_moins(Progression.COLISEUM_EXITED) else zcol
	_load(_cli.get("instance", zone), "instance", arrive)
	s.cam.set_index(ZOOM_V06 if _cam_ville else CAMS_P6[cam_p6][1], false)
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
	Routes.decalage_sud = {}
	World25.yaw_commande_actif = false
	super._exit_tree()
	World25.yaw = World25.YAW
	get_viewport().use_occlusion_culling = false
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


var _props_commandant: Array = []


# ------------------------------------------------------------------------------------------------ P6.3.1 diagnostic
var _isoler := ""


## P6.3.2 : isolation d'une cause de clignotement (diagnostic, -- --isoler=ombres|occultation|trouee|fondus).
func _appliquer_isolation() -> void:
	if _isoler == "":
		return
	if _isoler == "ombres":
		var pile: Array = [self]
		while not pile.is_empty():
			var c = pile.pop_back()
			for k in c.get_children():
				pile.append(k)
			if c is Light3D:
				(c as Light3D).shadow_enabled = false
	elif _isoler == "occultation":
		get_viewport().use_occlusion_culling = false
	elif _isoler == "fondus" and _sect != null:
		_sect.duree_fondu = 0.0


var _diag: Label
var _diag_on := false


## Mode de diagnostic (outil de développement, touche F10 ou -- --diag) : secteur actif, groupes rendus / masqués,
## murs coupés, éléments translucides, position d'Aren. N'agit sur rien : lecture seule.
func _maj_diag() -> void:
	if not _diag_on or _sect == null:
		if _diag != null:
			_diag.visible = false
		return
	if _diag == null:
		_diag = Label.new()
		_diag.add_theme_font_size_override("font_size", 13)
		_diag.add_theme_color_override("font_color", Color(1, 1, 0.75))
		_diag.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		_diag.add_theme_constant_override("outline_size", 4)
		_diag.position = Vector2(12, 96)
		var cl := CanvasLayer.new()
		cl.layer = 60
		add_child(cl)
		cl.add_child(_diag)
	_diag.visible = true
	var rendus: Array = []
	var masques: Array = []
	var transl := 0
	for k in _sect._groupes:
		var g: Dictionary = _sect._groupes[k]
		if (g["node"] as Node3D).visible:
			rendus.append(k)
		else:
			masques.append(k)
		for geo in g["geos"]:
			if is_instance_valid(geo) and (geo as GeometryInstance3D).transparency > 0.001 and (geo as GeometryInstance3D).transparency < 0.999 and (geo as Node3D).is_visible_in_tree():
				transl += 1
	rendus.sort()
	masques.sort()
	_diag.text = "DIAG  Aren (%.1f, %.1f)  actif %s  en vue %s  voile %.2f\nrendus (%d) : %s\nmasqués (%d) : %s\nmurs coupés (%d) : %s\ntranslucides : %d   toits : %s" % [
		s.hero.x, s.hero.y, _sect.actif, str(_sect.visibles), _sect.voile_ext, rendus.size(), ", ".join(PackedStringArray(rendus)),
		masques.size(), ", ".join(PackedStringArray(masques)), _sect.murs_coupes().size(), ", ".join(PackedStringArray(_sect.murs_coupes().map(func(x): return str(x)))),
		transl, str(_sect.toits_visibles())]


## P6.3 : mise en valeur du commandant (avant le tutoriel et après) : lumière chaude dirigée, râtelier derrière lui.
func _scene_commandant() -> void:
	if _hab == null or not _pnj.has("commandant"):
		return
	var p: Vector2 = _pnj["commandant"]["p"]
	var sp := SpotLight3D.new()
	sp.light_color = Color(1.0, 0.88, 0.66)
	sp.light_energy = 2.2
	sp.spot_range = 9.0
	sp.spot_angle = 16.0
	sp.spot_attenuation = 0.6
	sp.shadow_enabled = true
	sp.position = Vector3(p.x, 6.5, p.y + 2.6)
	sp.look_at_from_position(sp.position, Vector3(p.x, 0.6, p.y), Vector3.UP)
	sp.set_meta("hors_secteurs", true)
	root.add_child(sp)
	_props_commandant = [modele("fp/WeaponStand", Vector3(p.x + 1.4, 0.0, p.y - 1.3), -0.35, 0.9),
		modele("fp/Chest_Wood", Vector3(p.x - 1.5, 0.0, p.y - 1.2), 0.3, 0.8)]
	# accessoires solides (comme le mobilier des données) : Aren ne les traverse pas
	_solide_rond(Vector2(p.x + 1.4, p.y - 1.3), 0.55, 1.1)
	_solide_rond(Vector2(p.x - 1.5, p.y - 1.2), 0.5, 0.7)


## P6.3 : obstacle rond pour un accessoire posé par la scène (modèle logique + physique), même principe que les PNJ.
## P6.4.3 : ombres de contact des personnages du Colisée. Le disque doux commun (blob25.gdshader, 0,9 × 0,55 m,
## force 0,45) était presque entièrement couvert par les pieds des sprites au zoom ×3 : les personnages semblaient poser
## à peine sur le sable. Réglage local (force, taille) de l'instance de chaque personnage ; le shader commun et la forêt
## ne changent pas.
func _ombres_contact() -> void:
	if _hab == null or not (_hab.extension and _hab.p64):
		return
	for k in actors:
		var nd = actors[k].get("node")
		if nd == null or not is_instance_valid(nd):
			continue
		for ch in (nd as Node).get_children():
			if ch is MeshInstance3D and (ch as MeshInstance3D).material_override is ShaderMaterial \
					and ((ch as MeshInstance3D).material_override as ShaderMaterial).shader == BLOB_SH:
				var mi := ch as MeshInstance3D
				(mi.mesh as QuadMesh).size = Vector2(1.0, 0.62)
				(mi.material_override as ShaderMaterial).set_shader_parameter("strength", 0.62)


func _solide_rond(c: Vector2, r: float, h: float) -> void:
	_obstacle_cyl(World25.g3(Vector3(c.x, c.y, 0.0)), r, h)
	world.solids.append({"id": "accessoire_%d_%d" % [int(c.x * 10), int(c.y * 10)], "kind": "circle", "c": c, "r": r, "h0": 0.0, "h1": h})


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
		var p: Vector2 = Routes.sud(Vector2(d["xy"][0], d["xy"][1]))   # P6.2-D : bloc sud décalé
		if _sect != null:
			# P6.2-C : un PNJ appartient à la pièce où il se tient (son emprise de sprite débordait sur le reste du niveau)
			a["node"].set_meta("secteur", _sect._proche(p))
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
	_au_mur.clear()
	_au_coupe.clear()
	_rects_p64.clear()
	_monster = null
	_rng.seed = 6061
	world = World25.load_world(file, m)
	_p6 = world.adj.get("p6", {})
	_camera_de_zone()
	_ville = null
	if _p6.get("zone", "") == "ville":
		var ver := str(_p6.get("ville", {}).get("version", ""))
		if ver == "v07b":
			_ville = VilleV07B.new(self)
		else:
			_ville = VilleV07A.new(self) if ver == "v07a" else (VilleV06.new(self) if ver == "v06" else VilleBlockout.new(self))
	Routes.decalage_sud = _p6.get("decalage_sud", {})
	_dy_sud = float(Routes.decalage_sud.get("dy", 0.0))
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
		_hab.p64 = p64
		_hab.pilote2 = pilote in ["2", "3"]
		_hab.extension = pilote == "3"
		_hab.sable_calque = str(_cli.get("sable", "1")) != "0"
		_hab.galerie = galerie
	_marques_portes.clear()
	if _hab != null:
		_hab.lumiere(_env_res, _sun)
	_portes_fermees.clear()
	_sect = Secteurs.new(_p6["secteurs"], TRANSITIONS[transitions]) if (_p6.has("secteurs") and not _cli.has("sans_secteurs")) else null
	get_viewport().use_occlusion_culling = _sect != null and _sect.mode != "echelle"   # murs hauts = occulteurs
	for e in world.elements:
		_build(e)
	_build_p6()
	_spawn_pnj()
	_scene_commandant()
	_ombres_contact()
	_build_overlay()
	s.set_world(world, arrive)
	if cam_mode == "V06":
		s.cam.bounds = Rect2()                  # P7.4.2 : caméra sans limites dès la mise en place (aucune image décentrée)
		s.cam.snap_to(World25.screen(s.hero))
	if _sect != null:
		for n in [_overlay, _labels]:
			if n != null:
				n.set_meta("hors_secteurs", true)
		if _hab != null and _hab.extension and _hab.p64:
			# P6.4.2 : toits des intérieurs vus de l'arène = terrasses dallées, comme la terrasse de la galerie B
			_sect.mat_toit = _hab.mz("dalle", "arene", "monde", 1.0, false, Color(0.74, 0.72, 0.7))
		_sect.plafonds(root, H_VIS + 0.1 if _sect.mode != "echelle" else 0.0)
		if _sect.mode == "echelle":
			_lueur_tunnel = _lueur_fin_de_tunnel()
		else:
			_lueur_tunnel = null
			_jour_du_tunnel()
		_sect.classer(self, root)
		for n in _au_mur:
			if n != null and is_instance_valid(n):
				_sect.attacher(n, Vector2(n.global_position.x, n.global_position.z))
		_au_mur.clear()
		for n in _au_coupe:
			if n != null and is_instance_valid(n):
				_sect.attacher_coupe(n, Vector2(n.global_position.x, n.global_position.z))
		_au_coupe.clear()
		_maj_secteur(true)
		if _sect.mode != "echelle":
			_sect.voile_ext = -1.0
			_sect.regler_voile_ext(_sect.voile_ext_pour(Vector2(s.hero.x, s.hero.y)))
	teleport(s.hero, s.companion)
	apply_options()
	_appliquer_isolation()
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
	if _ville != null and _ville.construit(e):
		return                                  # P7.1 : blockout de la ville (volumes neutres, collisions des données)
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
				var msous: Material = _tinted("paves", Color(0.5, 0.48, 0.55))
				if _hab != null and _hab.extension and _hab.p64:
					msous = _hab.mz("dallage_tunnel", "arene", "monde", 1.0, false, Color(0.8, 0.78, 0.76))   # P6.4.2 : visible aux bouches
				_box_mesh(_rect_center(r, e["h"] - th, e["h"] - 0.01), Vector3(r.size.x, th - 0.01, r.size.y), msous)
			else:
				var d: Array = SOLS.get(sol, SOLS["paves"])
				var msol: Material = _tinted(d[0], d[1])
				if _hab != null and _hab.pilote_sol(id):
					msol = _hab.mat_sol(id) if _hab.extension else _hab.m64("dallage", "monde")      # P6.4.2 : sol de la zone
				var ms := _box_mesh(_rect_center(r, e["h"] - th, e["h"]), Vector3(r.size.x, th, r.size.y), msol)
				ms.set_meta("sol", true)          # P6.3 : structure (une pièce vue en coupe garde son sol)
		"block":
			_build_bloc_p6(e)
		"gate":
			if e["id"] == "sortie_est" and e["a"].y == e["b"].y:
				_porte_ville_p76(e)
		_:
			super._build(e)


## P7.6 — porte de la ville, au sud du vestibule de sortie : deux battants de bois ferré OUVERTS vers l'intérieur (rabattus
## contre les joues de la baie, solides : aucun relief traversable), seuil et piédroits de calcaire clair. Le jour entre par
## la baie (« jours » des données). Classée par emprise dans le secteur de la sortie comme le reste de la pièce.
func _porte_ville_p76(e: Dictionary) -> void:
	var a: Vector2 = e["a"]
	var b: Vector2 = e["b"]
	var yi := a.y - 0.2                                    # face intérieure du mur sud
	var bois := StandardMaterial3D.new()
	bois.albedo_color = Color(0.33, 0.22, 0.14)
	bois.roughness = 0.85
	var fer := StandardMaterial3D.new()
	fer.albedo_color = Color(0.14, 0.14, 0.15)
	fer.metallic = 0.6
	fer.roughness = 0.5
	var pierre: Material = _hab.mm("mur", "sortie", "monde", 1.0, false, Color(1.12, 1.08, 1.0)) if _hab != null else _surf("pierre")
	# battants ouverts, rabattus à plat contre la face intérieure du mur sud (vus de face par la caméra, au-dessus du muret)
	for k in [-1.0, 1.0]:
		var xc: float = (a.x - 0.5) if k < 0.0 else (b.x + 0.5)
		var c := Vector3(xc, 1.25, yi - 0.12)
		_static_box(c, Vector3(1.0, 2.5, 0.1), L_OBST)
		_box_mesh(c, Vector3(0.96, 2.5, 0.07), bois)
		for hb in [0.45, 1.25, 2.05]:
			_box_mesh(Vector3(xc, hb, yi - 0.165), Vector3(0.9, 0.09, 0.03), fer)
		_box_mesh(Vector3(xc - k * 0.32, 1.15, yi - 0.17), Vector3(0.1, 0.1, 0.03), fer)        # anneau
	# encadrement de calcaire : piédroits jusqu'à 2,8 m et linteau (la porte se lit au-dessus du muret coupé)
	for x in [a.x - 0.18, b.x + 0.18]:
		_box_mesh(Vector3(x, 1.4, a.y + 0.2), Vector3(0.36, 2.8, 0.55), pierre)
	_box_mesh(Vector3((a.x + b.x) * 0.5, 2.98, a.y + 0.2), Vector3(b.x - a.x + 0.72, 0.36, 0.55), pierre)
	_box_mesh(Vector3((a.x + b.x) * 0.5, 0.02, a.y + 0.2), Vector3(b.x - a.x, 0.04, 0.5), pierre)        # seuil
	# jour : tache de lumière sur le seuil, au-delà de la porte (l'extérieur reste voilé depuis l'intérieur)
	var jour := StandardMaterial3D.new()
	jour.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	jour.albedo_color = Color(0.97, 0.91, 0.78)
	_box_mesh(Vector3((a.x + b.x) * 0.5, 0.012, (a.y + 0.45 + 29.8) * 0.5), Vector3(b.x - a.x - 0.02, 0.02, 29.8 - a.y - 0.45), jour)


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
		if _hab != null and _hab.pilote_mur(id):
			mpierre = _hab.mm("mur", _hab.zone_piece(id), "monde", 1.0, tall)      # P6.4 : mur pilote ; P6.4.2 : ambiance de la zone
			_rects_p64.append(r)
		# P6.2 : maillages du mur sous un pivot à l'origine ; la collision (sb) reste dans l'instance, jamais modifiée
		var pivot := Node3D.new()
		pivot.name = id
		pivot.set_meta("xz", r.get_center())
		pivot.set_meta("mur", true)
		root.add_child(pivot)
		if _sect != null and _sect.mode != "echelle":
			# P6.2-B : muret (persistant) + partie haute (estompée si elle cache la pièce active) ; murs d'intérieur
			# prolongés jusqu'à H_VIS (structure continue : ils cachent les pièces voisines sans que rien ne disparaisse)
			var hv := h1
			var garde := id.begins_with("cmur_tunnel_sud")
			var interieur := false
			var n_int := 0
			for m in _sect._membres_emprise(r, false):
				if _sect.par_id.has(m) and _sect.par_id[m]["fond"] == "sombre":
					interieur = true
					n_int += 1
			if interieur and tall:
				hv = H_VIS
			if (n_int >= 2 or id.begins_with("cmur_coursive_s")) and not garde:
				# P6.3.1 : cloison entre deux intérieurs (coursive / infirmerie, réserve) : basse pour la pièce dont elle est
				# le mur côté caméra, mais c'est le mur du FOND de l'autre : rendue sur toute la hauteur (collision
				# inchangée) ; la coupe la réduit en muret quand elle est devant la pièce active
				hv = H_VIS
			if garde:
				# P6.2-C : le tunnel passe sous les gradins ; ses murs (prolongés à 6 m en P6.2-B parce qu'ils touchent la
				# salle) restent à hauteur de voûte : ils encadrent la vue sans dresser de grandes lames devant l'arène
				hv = H_TUNNEL
			_mur_continu(id, pivot, r, h0, hv, mpierre, sb, garde)
			if garde:
				_naissance_voute(pivot, r, hv)
			return
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
	if _hab != null and _meuble_modele(nom, r):
		return                                  # P6.3 : modèle Quaternius (collision des données inchangée)
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
		var mb: Material = _surf("pierre")
		var mh: Material = _surf("pierre", true)
		if _hab != null and _hab.extension and _hab.p64:
			# P6.4.2 : piliers de la coursive dans l'appareil de leur pièce (base en soubassement, chapiteau mouluré)
			var zp: String = _hab.zone_en(r.get_center())
			# fût un peu plus clair que les murs : isolés au milieu de la pièce, ils ne reçoivent que la lumière de l'allée
			mp = _hab.mz("mur", zp, "monde", 1.0, true, Color(1.28, 1.24, 1.18))
			mb = _hab.mz("socle", zp, "monde", 1.0, false, Color(1.15, 1.12, 1.08))
			mh = _hab.mz("moulure", zp, "monde", 1.0, true, Color(1.15, 1.12, 1.08))
		_box_mesh(_rect_center(r, h0, h1), size, mp)
		_box_mesh(_rect_center(r.grow(0.12), h0, 0.3), Vector3(r.size.x + 0.24, 0.3, r.size.y + 0.24), mb)
		_box_mesh(_rect_center(r.grow(0.12), h1 - 0.25, h1), Vector3(r.size.x + 0.24, 0.25, r.size.y + 0.24), mh)
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
	_linteaux()
	_entree_tunnel()
	if _ville != null:
		_ville.decorer()
	elif _hab != null:
		var n0 := root.get_child_count()
		_hab.exterieur(world.decor)
		for i in range(n0, root.get_child_count()):
			root.get_child(i).set_meta("exterieur", true)      # parvis, bâtiments lointains
		if _p6.get("zone", "") == "colisee":
			var avant := root.get_child_count()
			_hab.vestiaires(Rect2(16.0, 46.5, 20.0, 8.5))
			for i in range(avant, root.get_child_count()):
				root.get_child(i).set_meta("secteur", "S1")     # décor composé pour les vestiaires
				if _dy_sud != 0.0 and root.get_child(i) is Node3D:
					(root.get_child(i) as Node3D).position.z += _dy_sud      # P6.2-D : bloc sud décalé (longueur du tunnel)
	if _p6.has("arene"):
		_build_arene(_p6["arene"])
	for pid in _p6.get("pieces_fermees", {}):
		var q: Array = _p6["pieces_fermees"][pid]["rect"]
		var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
		var d: Array = SOLS.get(_p6["pieces_fermees"][pid]["sol"], SOLS["paves"])
		var mfm: Material = _tinted(d[0], d[1] * Color(0.7, 0.7, 0.75))
		if _hab != null and _hab.extension and _hab.p64:
			mfm = _hab.mat_sol(pid)                    # P6.4.2 : plancher de la réserve (vu par la porte en coupe)
		var mf := _box_mesh(_rect_center(r, -0.3, 0.0), Vector3(r.size.x, 0.3, r.size.y), mfm)
		mf.set_meta("sol", true)
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
			ol.omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID      # 2 passes au lieu de 6 (cube)
			ol.light_size = 0.12
			ol.shadow_bias = 0.06
			ol.omni_attenuation = 1.6
		_halo(pos + dl * 0.75, 1.1, 0.45)
		if _hab != null:
			# P6.3 : lanterne murale (Quaternius) au lieu d'un cube : potence au mur, lanterne au bout, sous la lumière
			var kl := 0.48
			_au_mur.append(modele("fp/Lantern_Wall", pos - Vector3(0, 0.95 * kl, 0) - dl.normalized() * 0.02, atan2(dl.x, dl.z), kl))
		else:
			_box_mesh(pos + Vector3(0, -0.15, 0) + dl * 0.15, Vector3(0.18, 0.3, 0.18), _tinted("bois", Color(0.6, 0.5, 0.4)))
	if _p6.get("zone", "") == "colisee":
		if _hab == null:                      # P6.2 : avec l'habillage, bannières peintes de part et d'autre de la porte
			_banniere(Vector3(26.0, 0.0, 46.3 + _dy_sud), Color(0.25, 0.32, 0.75))          # vestiaires, mur nord (côté porte)
			_banniere(Vector3(21.0, 0.0, 46.3 + _dy_sud), Color(0.25, 0.32, 0.75))
			_banniere(Vector3(31.0, 0.0, 46.3 + _dy_sud), Color(0.25, 0.32, 0.75))
			_banniere(Vector3(26.0, 0.0, 54.95 + _dy_sud), Color(0.72, 0.6, 0.25), 1.6)      # bannière de la Guilde (sud, basse)
		# P6.3 : bannières de la coursive sur la face intérieure du mur nord (elles étaient prises dans le mur)
		if _hab != null:
			for bx in [45.9, 54.1]:
				_au_mur.append(modele("fp/Banner_1_Cloth", Vector3(bx, 2.75, 12.08), 0.0, 0.9))
			# P6.3 (extension) : bancs et tonneaux de la coursive = mobilier des DONNÉES (collision comprise)
		else:
			_banniere(Vector3(45.6, 0.0, 12.06), Color(0.72, 0.18, 0.22))
			_banniere(Vector3(54.4, 0.0, 12.06), Color(0.72, 0.18, 0.22))
	elif _ville == null:
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


## P7.3 : porte à l'altitude de son seuil (« h » des données, ville V0.6) : construite à 0 puis remontée en bloc.
func _build_porte(p: Dictionary) -> void:
	var hp := float(p.get("h", 0.0))
	var n0 := root.get_child_count()
	_build_porte_0(p)
	if hp != 0.0:
		for i in range(n0, root.get_child_count()):
			var n := root.get_child(i)
			if n is Node3D:
				(n as Node3D).position.y += hp


## Porte : fermée = solide (modèle logique + physique) et vantail / grille ; marque au sol aux couleurs du plan.
func _build_porte_0(p: Dictionary) -> void:
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
	if _hab == null:
		# marque au sol aux couleurs du plan : lecture du blockout seulement (P6.3 : pas avec l'habillage)
		_box_mesh(Vector3(mr.get_center().x, 0.012, mr.get_center().y), Vector3(mr.size.x, 0.02, mr.size.y), mark)
	if ouverte:
		if p.get("type", "") == "grille":
			var mg: Material = _tinted("pierre", Color(0.6, 0.6, 0.66))
			if _hab != null and _hab.extension and _hab.p64:
				mg = _hab.mz("moulure", "tunnel", "monde", 1.0, false, Color(0.82, 0.8, 0.78))
			var tg := _box_mesh(_rect_center(r, 2.5, 2.7), Vector3(r.size.x, 0.2, r.size.y), mg)
			if _hab != null and _hab.extension and _hab.p64:
				tg.set_meta("secteur", Secteurs.EXT)       # P6.4.3 : avec l'arc de la bouche (sinon isolée vue de la coursive)
		return
	_portes_fermees[p["id"]] = {"texte": p.get("texte_ferme", "C'est fermé."), "c": r.get_center()}
	# P7.3 : altitude du seuil (« h » des données, 0 par défaut : Colisée et quartier inchangés) ; la porte est
	# construite à 0 puis remontée en bloc (solide logique compris)
	var hp := float(p.get("h", 0.0))
	_static_box(_rect_center(r, 0.0, 2.6), Vector3(r.size.x, 2.6, r.size.y), L_OBST)
	world.solids.append({"id": p["id"], "kind": "rect", "rect": r, "h0": hp, "h1": hp + 2.6})
	if p.get("type", "") == "grille" and _ville != null and _ville.has_method("grille_dessinee") and not _ville.grille_dessinee(p):
		pass                                               # P7.13 : grille retirée (la herse du châtelet ferme), collision gardée
	elif p.get("type", "") == "grille":
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
	elif _hab != null:
		_porte_habillee(r)
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
		_hab.lumiere_coursive_p64()
		_hab.lumiere_p642()
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
	return (_dialog != null and _dialog.is_open()) or _bloque or _switching     # P7.5 : porte publique (transition en cours)


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
	var pp := _porte_publique_proche()
	if not pp.is_empty():
		_entrer_porte_publique(pp)
		return true
	var ex := _examen_proche()
	if not ex.is_empty():
		_examiner(ex)
		return true
	return false


## P7.5 : porte publique du Colisée (ville V0.7-A) : battants fermés et solides ; E devant la porte déclenche la sortie
## des données (portail colisee_porte_publique) avec le fondu existant. Aucun nouveau système de transition.
func _porte_publique_proche() -> Dictionary:
	if _ville == null or _switching:
		return {}
	var pp: Dictionary = _p6.get("ville", {}).get("colisee", {}).get("porte_publique", {})
	if pp.is_empty():
		return {}
	if Vector2(s.hero.x, s.hero.y).distance_to(Vector2(pp["xy"][0], pp["xy"][1])) > float(pp.get("portee_m", 2.0)):
		return {}
	return pp


func _entrer_porte_publique(pp: Dictionary) -> void:
	for t in world.triggers:
		if str(t["id"]) == str(pp["sortie"]):
			_log("porte_publique", {"sortie": t["id"]})
			s.m["exits"] = s.m.get("exits", []) + [t["id"]]
			_switch(t)
			return


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
		if _ville_on and str(t.get("to", "")) == ZONE_QUARTIER:
			# P7.1 : la sortie du Colisée mène au parvis du blockout de la ville (devant l'entrée publique)
			var vd: Dictionary = JSON.parse_string(FileAccess.open(_zone_ville(), FileAccess.READ).get_as_text())["ajustements"]["p6"]["ville"]
			var aa: Array = vd["arrivee_colisee"]
			t = t.duplicate()
			t["to"] = _zone_ville()
			t["arrive"] = Vector3(aa[0], aa[1], aa[2])
			var oa: Array = vd.get("orientation_arrivee_colisee", [])
			if oa.size() == 2:
				t["orientation"] = Vector2(oa[0], oa[1])
	_log("portail", {"id": str(t.get("id", "")), "portail": str(t.get("portail", "")), "vers": str(t.get("to", "")),
		"arrivee": [t["arrive"].x, t["arrive"].y, t["arrive"].z] if t.get("arrive", Vector3.INF) != Vector3.INF else []})
	await super._switch(t)                      # P7.4.1 : attendre la fin du chargement (fondu compris)
	await get_tree().physics_frame
	# P7.4.1 : orientation d'arrivée (données du portail), Aren et son compagnon tournés dans le sens de la marche
	var ori: Vector2 = t.get("orientation", Vector2.ZERO)
	if ori != Vector2.ZERO:
		var sd := World25.plan_to_screen_dir(ori)
		s.hero_dir = sd
		for k in ["aren", "ilya"]:
			if actors.has(k) and actors[k].has("actor"):
				actors[k]["actor"].face_toward(sd)
	_log("arrivee_portail", {"zone": str(_p6.get("zone", "")), "x": snappedf(s.hero.x, 0.01), "y": snappedf(s.hero.y, 0.01),
		"h": snappedf(s.hero.z, 0.01), "orientation": [ori.x, ori.y], "declencheurs_armes": s._armed.duplicate()})
	await get_tree().physics_frame
	var porte_ouverte_v07: bool = _ville_ver in ["v07a", "v07b"] and _p6.get("zone", "") == "ville"
	if _p6.get("zone", "") in ["quartier", "ville"] and Progression.au_moins(Progression.COLISEUM_EXITED) and not porte_ouverte_v07:
		s.toast("Les portes du Colisée se referment derrière vous.", 3.0)


# ------------------------------------------------------------------------------------------------ boucle
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and (e as InputEventKey).keycode == KEY_F10:
		_diag_on = not _diag_on                # P6.3.1 : diagnostic de visibilité (outil de développement)
		return
	if _switching or _bloque:
		return
	if _dialog.is_open():
		if e is InputEventKey and e.pressed and not e.echo:
			_dialog.handle_key(e)
		return
	if cam_mode == "V06" and _entree_zoom(e):
		if not _zoom_fixe_dit:
			_zoom_fixe_dit = true
			s.toast("Ville V0.6 : distance de caméra unique (zoom désactivé)", 2.2)
		return                                  # P7.3 : une seule distance de caméra dans la ville
	if _cam_ville and e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_C:
		cam_v06 = CAMS_V06[(CAMS_V06.find(cam_v06) + 1) % CAMS_V06.size()]
		_reload_here()
		s.cam.set_index(ZOOM_V06, false)
		s.toast("Caméra " + CAMS_V06_LABEL[cam_v06], 2.5)
		return
	if _cam_ville and _ville_ver in ["v07a", "v07b"] and e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_V:
		camera_ville = "B" if camera_ville == "A" else "A"
		s.toast("Caméra de la ville : " + ("B — semi-fixe (2 secteurs)" if camera_ville == "B" else "A — fixe vers le nord"), 2.5)
		return
	if _cam_ville and e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_L:
		if _cli.has("libelles"):
			_cli.erase("libelles")
		else:
			_cli["libelles"] = true
		_reload_here()
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_C:
		cam_p6 = CAMS_P6_ORDRE[(CAMS_P6_ORDRE.find(cam_p6) + 1) % CAMS_P6_ORDRE.size()]
		cam_mode = CAMS_P6[cam_p6][0]
		s.arch = "P6 — Colisée · " + CAMS_P6_LABEL[cam_p6]
		_reload_here()
		s.cam.set_index(CAMS_P6[cam_p6][1], false)
		s.toast("Caméra " + CAMS_P6_LABEL[cam_p6], 2.5)
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_J:
		transitions = {"A": "B", "B": "C", "C": "A"}[transitions]
		_reload_here()
		s.toast("Transitions : " + TRANSITIONS_LABEL[transitions], 2.8)
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_H:
		habillage = not habillage
		_reload_here()
		s.toast("Habillage : " + ("pilote P6.1" if habillage else "blockout P6"), 2.5)
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_M:
		pilote = {"0": "1", "1": "2", "2": "3", "3": "0"}[pilote]
		p64 = pilote != "0"
		_defauts_pilote()
		_reload_here()
		s.toast("Direction artistique : " + {"0": "P6.3.2 (comparaison)", "1": "premier pilote P6.4", "2": "second pilote P6.4.1", "3": "extension P6.4.2"}[pilote], 2.5)
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_K:
		galerie = GALERIES[(GALERIES.find(galerie) + 1) % GALERIES.size()]
		_reload_here()
		s.toast("Galerie : " + {"A": "A — petites tuiles", "B": "B — structure mixte", "p64": "premier pilote"}[galerie], 2.5)
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_U:
		porte_coupe = PORTES_COUPE[(PORTES_COUPE.find(porte_coupe) + 1) % PORTES_COUPE.size()]
		_reload_here()
		s.toast("Porte en coupe : " + {"C": "C — coupe sobre + indication", "silhouette": "B — coupe + silhouette", "coupe": "A — coupe seule", "p632": "porte basse (P6.3.2)"}[porte_coupe], 2.5)
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
	if _cam_ville and not _switching and world != null:
		_yaw_secteurs(delta)                    # P7.4 : caméra semi-fixe (B) ; sans effet en A
		_profil_ville(delta)                    # P7.12.1 : plongée adoucie sur la terrasse civique et l'avenue du château
	elif cam_mode == "V06" and not _switching and world != null:
		_profil_colisee(delta)                  # P7.4.1 : plongée propre à l'arène (caméra V0.7-A dans le Colisée)
	super._physics_process(delta)
	if _cam_ville and not _switching and world != null and _ville != null and _ville.has_method("coupes_camera") and body != null:
		_ville.coupes_camera(cam.global_position, body.global_position, delta)      # P7.6 : volumes entre la caméra et Aren
	if _switching or world == null or _bloque:
		return
	_pnj_step(delta)
	_suivi_secteur(delta)
	_afficher_touches()
	_maj_diag()
	_suivi_zones()
	_commandant_auto()
	if _cli.has("quitter_fin") and s.pilot_done and s.pilot_name in ["p6_apres", "p6_video_complet_apres", "p6_video_642_apres", "p6_video_643_apres"] and not _dialog.is_open() and not s.dialogue_open:
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
	if _isoler == "trouee":
		RenderingServer.global_shader_parameter_set("p4_hole", 0.0)     # diagnostic : trouée d'occlusion coupée
	if s == null or world == null:
		return
	_maj_marques_portes(delta)
	var hint := ""
	if not s.dialogue_open and not _bloque:
		var id := _pnj_proche()
		if id != "":
			hint = "E  Parler — " + str(_pnj[id]["def"]["nom"])
		elif not _porte_publique_proche().is_empty():
			hint = str(_porte_publique_proche().get("invite", "E  Entrer"))
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
	# P6.4.2 : visibilité de l'ARÈNE (ciel, extérieur) quel que soit le point de départ (sinon : état des vestiaires)
	s.warp_to(Vector3(26.0, 26.0, 0.0))
	for i in 4:
		await get_tree().process_frame
	set_physics_process(false)
	_tilt.visible = false
	s.hud.visible = false
	body.visible = false
	for k in actors:
		if str(k).begins_with("pnj"):
			(actors[k]["node"] as Node3D).visible = false
	for n in _props_commandant:
		if n != null and is_instance_valid(n):
			(n as Node3D).visible = false       # P6.3 : le combat se joue là où se tient le commandant
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
## P6.4.2 : une téléportation (parcours de test, montage vidéo, réapparition) recale la visibilité SANS fondu. Avant,
## l'état de la pièce de départ restait affiché pendant le fondu : en passant de l'arène à la coursive, le toit plat de
## la coursive (vu de l'arène) s'estompait par-dessus la pièce (grand aplat brun de la vidéo P6.4.1, vers 18 s). La
## marche normale n'est pas concernée (seuils franchis pas à pas, voir docs/P6_4_2_COLISEE_EXTENSION.md).
func teleport(p: Vector3, comp: Vector3) -> void:
	super.teleport(p, comp)
	_pitch_snap = true                          # P7.4.1 : un placement instantané recale aussi plongée et azimut, sans pivot
	_yaw_snap = true
	if cam_mode == "V06" and s != null and s.world != null:
		# P7.4.2 : caméra sans limites : le calage du socle (fait AVEC les limites de l'instance) décentrait Aren à
		# l'arrivée près d'un bord (porte est du Colisée : x 939 px), puis la caméra glissait 0,5 s ; recalage direct
		s.cam.bounds = Rect2()
		s.cam.snap_to(World25.screen(s.hero))
	if _sect != null and root != null and is_instance_valid(root) and s != null and s.world != null:
		_maj_secteur(true)
		if _sect.mode != "echelle":
			# P6.4.4 : voile FORCÉ (comme au chargement). La mise à jour immédiate réaffiche les groupes de l'extérieur
			# (arène comprise) à pleine opacité ; si le voile valait déjà 1, regler_voile_ext() ne faisait rien et l'arène
			# restait visible depuis les vestiaires, le passage et la salle d'attente (défaut introduit en P6.4.2).
			_sect.voile_ext = -1.0
			_sect.regler_voile_ext(_sect.voile_ext_pour(Vector2(s.hero.x, s.hero.y)))


func _maj_secteur(immediat := false) -> void:
	if _sect == null:
		return
	if _sect.mode == "porte" and not immediat:
		var nx: String = _sect.prochain(Vector2(s.hero.x, s.hero.y))
		if nx != _sect.actif and not _fondu_porte:
			var paire := [nx, _sect.actif]
			paire.sort()
			if PORTES_C.has(paire):
				_fondu_porte = true
				_passer_porte()
				return
	if _fondu_porte:
		return
	var change: bool = _sect.mettre_a_jour(Vector2(s.hero.x, s.hero.y), immediat)
	if not change and not immediat:
		return
	if _lueur_tunnel != null:
		_lueur_tunnel.visible = _sect.est_visible("S3") and not _sect.est_visible(Secteurs.EXT)
	var sombre: bool = _sect.fond() == "sombre"
	if _sect.mode == "echelle":
		if sombre:
			_env_res.background_mode = Environment.BG_COLOR
			_env_res.background_color = Color(0.022, 0.018, 0.026)
		elif _hab != null:
			_env_res.background_mode = Environment.BG_SKY
	else:
		# P6.2-B : le fond glisse (intérieur sombre chaud <-> jour), jamais de bascule brusque
		if _sect.a_ciel_ouvert() and _hab != null and vue_tunnel_amount < 0.01:
			_env_res.background_mode = Environment.BG_SKY
		else:
			_fond_but = Color(0.05, 0.04, 0.045) if sombre else Color(0.36, 0.43, 0.6)
			if _env_res.background_mode != Environment.BG_COLOR:
				# P6.2-C : en revenant du ciel ouvert, le fond part directement de la teinte de la pièce (dans le tunnel,
				# il est sous le masque de vue : un ciel bleu y restait une seconde)
				_env_res.background_mode = Environment.BG_COLOR
				_env_res.background_color = _fond_but
			if immediat:
				_env_res.background_color = _fond_but
	_amb_but = 0.42 if sombre else (0.62 if _hab != null else 0.85)
	if immediat:
		_env_res.ambient_light_energy = _amb_but
	# P6.2-C : en B / C, limites COMMUNES à tout le bâtiment (celles du niveau). Les limites par pièce (P6.2) faisaient
	# sauter la caméra à chaque seuil : une pièce plus petite que la vue fige le centre sur son milieu, la suivante le
	# relâche, et le changement de limites déplaçait la caméra même Aren arrêté (mesure : tools/p6/camera_continuite_p6.gd).
	# Le mode A garde ses limites par pièce, pour comparaison.
	var cr: Rect2 = _sect.camera_rect() if _sect.mode == "echelle" else Rect2()
	_bornes_but = world.camera_bounds() if cr.size == Vector2.ZERO else _bornes_ecran(cr)
	if immediat:
		s.cam.bounds = Rect2() if cam_mode == "V06" else _bornes_but
	_log("secteur", {"secteur": _sect.actif, "visibles": _sect.visibles, "murs_coupes": _sect.murs_coupes().size()})


## Rectangle du plan -> limites écran (px natifs) : sol et hauts de murs (3,4 m), petite marge.
func _bornes_ecran(r: Rect2) -> Rect2:
	var b := Rect2(World25.screen(Vector3(r.position.x, r.position.y, 0.0)), Vector2.ZERO)
	for x in [r.position.x - 0.5, r.end.x + 0.5]:
		for y in [r.position.y - 0.5, r.end.y + 0.5]:
			for hh in [0.0, 3.4 if (_sect == null or _sect.mode == "echelle") else 4.2]:
				b = b.expand(World25.screen(Vector3(x, y, hh)))
	return b.grow(10.0)


func _suivi_secteur(delta: float) -> void:
	if _sect == null:
		return
	_maj_secteur()
	var k := 1.0 - exp(-5.0 * delta)
	var b: Rect2 = s.cam.bounds
	if cam_mode == "V06":
		# P7.4.1 : caméra V0.7-A : pas de limites écran (à 11°, celles du bâtiment arrêtaient le suivi au nord de l'arène
		# et Aren remontait au bord de l'image) ; le suivi d'Aren l'emporte
		s.cam.bounds = Rect2()
	else:
		s.cam.bounds = Rect2(b.position.lerp(_bornes_but.position, k), b.size.lerp(_bornes_but.size, k))
	if _amb_but >= 0.0:
		_env_res.ambient_light_energy = lerpf(_env_res.ambient_light_energy, _amb_but, k)
	_maj_vue_tunnel()
	if _sect.mode != "echelle":
		var v: float = _sect.voile_ext_pour(Vector2(s.hero.x, s.hero.y))
		if vue_tunnel_ferme >= 0.999:
			_sect.regler_voile_ext(v)       # P6.2-D : seuil salle / tunnel franchi sous le masque fermé : jamais montré
		else:
			_sect.regler_voile_ext(lerpf(_sect.voile_ext, v, 1.0 - exp(-8.0 * delta)) if absf(v - _sect.voile_ext) > 0.01 else v)
	if _sect.mode != "echelle" and _env_res.background_mode == Environment.BG_COLOR:
		_env_res.background_color = _env_res.background_color.lerp(_fond_but, k)
		if _sect.a_ciel_ouvert() and vue_tunnel_amount < 0.01 and _hab != null:
			_env_res.background_mode = Environment.BG_SKY     # P6.2-D : ciel réel une fois la vue du tunnel effacée
	if _sect.mode != "echelle" and _sect.fond() == "sombre" and _sect.actif != "S3":
		# P6.2-D : près d'un seuil vers l'arène (tunnel est, coursive), la lumière ambiante dépend de la distance à l'arène,
		# pas du changement de pièce : rien ne change d'un coup au franchissement
		var dmin := INF
		for sd in _sect.secteurs:
			if sd["ouverte"]:
				for r in sd["rects"]:
					var rr: Rect2 = r
					var hp2 := Vector2(s.hero.x, s.hero.y)
					dmin = minf(dmin, hp2.distance_to(Vector2(clampf(hp2.x, rr.position.x, rr.end.x), clampf(hp2.y, rr.position.y, rr.end.y))))
		if dmin < 3.0:
			_env_res.ambient_light_energy = lerpf(0.62 if _hab != null else 0.85, 0.42, smoothstep(0.0, 3.0, dmin))
	if vue_tunnel_amount > 0.0 and _sect.actif in ["S3", "S4"]:
		# P6.2-D : lumière ambiante liée à la position dans le tunnel (pas de bascule au seuil de l'arène)
		_env_res.ambient_light_energy = lerpf(0.62 if _hab != null else 0.85, 0.42, vue_tunnel_amount)


var _vue_tunnel: MeshInstance3D
var vue_tunnel_amount := 0.0                 # mesure / tests
var vue_tunnel_ferme := 0.0
var eblouissement := "discret"               # P6.3.1 : -- --eblouissement=actuel|aucun|discret


## P6.2-C : vue depuis le tunnel. Un point de l'arène n'est affiché que si la ligne de vue d'Aren passe par la bouche du
## tunnel (src/p6/vue_tunnel.gdshader). Le cône s'ouvre à mesure qu'Aren avance ; en sortant (de « plein » à « libre »),
## le masque s'efface : sable, gradins, loge et enceinte se découvrent selon la position, sans déclencheur.
func _maj_vue_tunnel() -> void:
	var vt: Dictionary = _p6.get("vue_tunnel", {})
	if vt.is_empty() or _sect == null or _sect.mode == "echelle":
		if _vue_tunnel != null:
			_vue_tunnel.visible = false
		return
	if _vue_tunnel == null:
		_vue_tunnel = MeshInstance3D.new()
		_vue_tunnel.name = "VueTunnel"
		var q := QuadMesh.new()
		q.size = Vector2(1, 1)
		_vue_tunnel.mesh = q
		_vue_tunnel.custom_aabb = AABB(Vector3(-1.0e5, -1.0e5, -1.0e5), Vector3(2.0e5, 2.0e5, 2.0e5))
		_vue_tunnel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var m := ShaderMaterial.new()
		m.shader = VueTunnel
		m.render_priority = Material.RENDER_PRIORITY_MAX
		var b: Array = vt["bouche"]
		m.set_shader_parameter("bouche", Vector3(b[0], b[1], b[2]))
		var ins: Array = vt["interieur"]
		m.set_shader_parameter("interieur0", Vector4(ins[0][0], ins[0][1], ins[0][2], ins[0][3]))
		m.set_shader_parameter("interieur1", Vector4(ins[1][0], ins[1][1], ins[1][2], ins[1][3]))
		_vue_tunnel.material_override = m
		_vue_tunnel.set_meta("hors_secteurs", true)
		cam.add_child(_vue_tunnel)
		_vue_tunnel.position = Vector3(0, 0, -1.0)
	var hp := Vector2(s.hero.x, s.hero.y)
	var e := vue_tunnel_etat(hp)
	var a: float = e["amount"]
	vue_tunnel_amount = a
	vue_tunnel_ferme = e["ferme"]
	_vue_tunnel.visible = a > 0.001
	if _vue_tunnel.visible:
		var mat := _vue_tunnel.material_override as ShaderMaterial
		var b2: Array = vt["bouche"]
		mat.set_shader_parameter("eye", Vector2(clampf(hp.x, float(b2[0]) + 0.1, float(b2[1]) - 0.1), hp.y))
		mat.set_shader_parameter("amount", a)
		mat.set_shader_parameter("ferme", e["ferme"])
		mat.set_shader_parameter("portee", e["portee"])
		mat.set_shader_parameter("eblouit", e["eblouit"])
		mat.set_shader_parameter("couleur", Color(0.05, 0.04, 0.045))
		mat.set_shader_parameter("jour", Color(0.96, 0.88, 0.72) if eblouissement == "actuel" else Color(0.86, 0.72, 0.5))


## P6.2-D : état de la vue du tunnel pour une position (fonction pure : tests, mesures). Dépend de la seule position
## d'Aren, pas du secteur actif. amount : présence du masque (1 dans le tunnel, s'efface sur les 2,4 m après la bouche,
## nul au-delà d'un mètre dans la salle) ; ferme : masque complet au seuil salle / tunnel ; portee / eblouit : au-delà de
## la portée (m depuis la bouche), la vue est noyée dans la lumière du jour.
func vue_tunnel_etat(hp: Vector2) -> Dictionary:
	var vt: Dictionary = _p6.get("vue_tunnel", {})
	if vt.is_empty():
		return {"amount": 0.0, "ferme": 0.0, "portee": 100.0, "eblouit": 0.0, "progression": 0.0}
	var cx: Array = vt["couloir_x"]
	var z0: float = vt["bouche"][2]
	var entree: float = vt.get("entree", 37.5)
	var a := (1.0 - smoothstep(float(cx[1]), float(cx[2]), absf(hp.x - float(cx[0])))) * smoothstep(float(vt["libre"]), float(vt["plein"]), hp.y)
	a *= 1.0 - smoothstep(entree + 0.6, entree + 1.0, hp.y)
	var prog := 1.0 - clampf((hp.y - z0) / maxf(entree - z0, 0.1), 0.0, 1.0)
	# P6.3.1 : éblouissement « actuel » (P6.2-D / P6.3 : nappe claire), « aucun » (lignes de vue seules) ou « discret »
	# (proposé : léger voile chaud, portée plus longue : le commandant et le sable restent lisibles, pas de trou blanc)
	var eb := 0.0
	var portee := 8.0 * pow(prog, 1.5)
	match eblouissement:
		"actuel":
			eb = lerpf(0.8, 0.4, prog)
		"discret":
			eb = lerpf(0.32, 0.12, prog)
			portee = 6.0 + 8.0 * prog
	return {"amount": a, "ferme": smoothstep(entree - 0.9, entree - 0.4, hp.y), "portee": portee,
		"eblouit": eb, "progression": prog}


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


# ------------------------------------------------------------------------------------------------ P6.2-B
## Mur en deux parties : muret persistant (0 -> LIP) et partie haute (LIP -> hv) ; tranche sombre ; occulteur du moteur.
func _mur_continu(id: String, pivot: Node3D, r: Rect2, h0: float, hv: float, mpierre: Material, sb: StaticBody3D, garde := false) -> void:
	var lip: float = Secteurs.LIP
	# P6.3.2 : moulures (corniche, bandeau, chaperon, plinthe, tranche) des murs nord-sud décalées de quelques mm : aux
	# angles, celles de deux murs perpendiculaires tombaient dans le même plan (z-fighting, scintillement en mouvement)
	var e := 0.0 if r.size.x >= r.size.y else 0.007
	# corps des murs nord-sud prolongés de e à leurs extrémités : là où deux murs se chevauchent, leurs faces tombaient
	# dans le même plan
	var rc := r.grow_individual(0.0, e, 0.0, e)
	var bas := _box_mesh(_rect_center(rc, h0, lip), Vector3(rc.size.x, lip - h0, rc.size.y), mpierre, pivot)
	fade_nodes[sb] = [bas]
	var haut: Array = []
	var h_mid := minf(hv, 3.0)
	haut.append(_box_mesh(_rect_center(rc, lip, h_mid), Vector3(rc.size.x, h_mid - lip, rc.size.y), mpierre, pivot))
	var mcap: Material = _hab.mat(Habillage.PIERRE, 2.4, Habillage.C_CALCAIRE * Color(1.12, 1.1, 1.08), true) if _hab != null else _tinted("pierre", Color(1.12, 1.1, 1.14), true)
	var p64m: bool = _hab != null and _hab.pilote_mur(id)
	var zm: String = _hab.zone_piece(id) if _hab != null else ""
	var mcorn: Material = _hab.mm("moulure", zm, "monde", 1.0, true) if p64m else mpierre
	if p64m:
		mcap = _hab.mm("moulure", zm, "monde", 1.0, true)
	if hv > 3.05:
		# P6.2-D : partie haute en deux assises (moins brutale qu'un aplat sombre), corniche, chaperon de pierre au sommet
		# (et non plus une tranche noire de maquette), pilastres aux extrémités des murs longs (angles, piédroits)
		var mmoyen: Material = _hab.mat(Habillage.PIERRE, 2.4, Habillage.C_CALCAIRE * Color(0.6, 0.56, 0.55), true) if _hab != null else _tinted("pierre", Color(0.58, 0.56, 0.58), true)
		var msombre: Material = _hab.mat(Habillage.PIERRE, 2.4, Habillage.C_CALCAIRE * Color(0.4, 0.36, 0.36), true) if _hab != null else _tinted("pierre", Color(0.4, 0.38, 0.4), true)
		if p64m:
			mmoyen = _hab.mm("mur_haut", zm, "monde", 1.0, true)
			msombre = _hab.mm("mur_sombre", zm, "monde", 1.0, true)
		var hm := minf(4.3, hv)
		haut.append(_box_mesh(_rect_center(rc, 3.0, hm), Vector3(rc.size.x, hm - 3.0, rc.size.y), mmoyen, pivot))
		if hv > hm + 0.05:
			haut.append(_box_mesh(_rect_center(rc, hm, hv), Vector3(rc.size.x, hv - hm, rc.size.y), msombre, pivot))
			haut.append(_box_mesh(_rect_center(r.grow(0.03 + e), hm - 0.04 + e, hm + 0.06 + e), Vector3(r.size.x + 0.06 + 2.0 * e, 0.1, r.size.y + 0.06 + 2.0 * e), mmoyen, pivot))
		# corniche à la jonction (lecture des proportions : un étage, pas un mur infini)
		haut.append(_box_mesh(_rect_center(r.grow(0.05 + e), 2.95 + e, 3.12 + e), Vector3(r.size.x + 0.1 + 2.0 * e, 0.17, r.size.y + 0.1 + 2.0 * e), mcorn, pivot))
		haut.append(_box_mesh(_rect_center(r.grow(0.08 + e), hv + e, hv + 0.16 + e), Vector3(r.size.x + 0.16 + 2.0 * e, 0.16, r.size.y + 0.16 + 2.0 * e), msombre, pivot))
		var long := maxf(r.size.x, r.size.y)
		if long > 2.5:
			var le_long_x := r.size.x > r.size.y
			for t in [0.0, 1.0]:
				var c := r.get_center()
				# pilastre : dépasse le bout du mur de 3 cm (sa face extrême coïncidait avec celle du mur)
				var dep := -0.03 if t == 0.0 else 0.03
				var bout := Vector2(lerpf(r.position.x + 0.2, r.end.x - 0.2, t) + dep, c.y) if le_long_x else Vector2(c.x, lerpf(r.position.y + 0.2, r.end.y - 0.2, t) + dep)
				var sz := Vector3(0.4, 0.0, r.size.y + 0.16 + 2.0 * e) if le_long_x else Vector3(r.size.x + 0.16 + 2.0 * e, 0.0, 0.4)
				haut.append(_box_mesh(Vector3(bout.x, (lip + hv - 0.001) * 0.5, bout.y), Vector3(sz.x, hv - 0.001 - lip, sz.z), mmoyen, pivot))
	else:
		haut.append(_box_mesh(_rect_center(r.grow(0.06 + e), hv + e, hv + 0.12 + e), Vector3(r.size.x + 0.12 + 2.0 * e, 0.12, r.size.y + 0.12 + 2.0 * e), mcap, pivot))
	if _hab != null:
		_box_mesh(_rect_center(r.grow(0.05 + e), h0, 0.3 + e), Vector3(r.size.x + 0.1 + 2.0 * e, 0.3 + e - h0, r.size.y + 0.1 + 2.0 * e), _hab.mm("socle", zm, "monde") if p64m else _hab.mat(Habillage.PIERRE, 1.2, Habillage.C_CALCAIRE * Color(0.72, 0.7, 0.7)), pivot)
	var coupe := _box_mesh(_rect_center(r.grow(0.07 + e), lip - 0.01 + e, lip + 0.05 + e), Vector3(r.size.x + 0.14 + 2.0 * e, 0.06, r.size.y + 0.14 + 2.0 * e), _mat_coupe(), pivot)
	coupe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var occ: OccluderInstance3D = null
	if hv > 2.0 and r.size.x * r.size.y > 0.5:
		occ = OccluderInstance3D.new()
		var bo := BoxOccluder3D.new()
		bo.size = Vector3(maxf(r.size.x - 0.1, 0.1), hv - lip, maxf(r.size.y - 0.1, 0.1))
		occ.occluder = bo
		occ.position = _rect_center(r, lip, hv)
		pivot.add_child(occ)
	_sect.declarer_mur(pivot, coupe, r, h0, hv, haut, occ, garde)


## Linteaux des portes intérieures (au-dessus de 2,7 m, jusqu'au haut des murs) : encadrements lisibles, structure
## continue. Décor seul (aucune collision) ; ils s'estompent comme les murs s'ils cachent la pièce active.
func _linteaux() -> void:
	if _sect == null or _sect.mode == "echelle":
		return
	var mp: Material = _hab.mat(Habillage.PIERRE, 2.4, Habillage.C_CALCAIRE, true) if _hab != null else _surf("pierre", true)
	for q in _p6.get("linteaux", []):
		var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
		var lb: float = q[4] if q.size() > 5 else 2.7       # P6.2-C : arc bas à la bouche du tunnel [.., bas, haut]
		var lh: float = q[5] if q.size() > 5 else H_VIS
		var pivot := Node3D.new()
		pivot.name = "linteau_%d_%d" % [int(r.position.x * 10), int(r.position.y * 10)]
		pivot.set_meta("xz", r.get_center())
		pivot.set_meta("mur", true)
		root.add_child(pivot)
		var haut: Array = []
		var mclair: Material = _hab.mat(Habillage.PIERRE, 1.2, Habillage.C_CALCAIRE * Color(1.1, 1.06, 1.0), true) if _hab != null else mp
		var pil := false
		for rp in _rects_p64:
			if (rp as Rect2).grow(0.05).intersects(r.grow(0.05)):
				pil = true
		var zl: String = _hab.zone_en(r.get_center()) if _hab != null else ""
		if pil:
			mclair = _hab.mm("mur", zl, "monde", 1.0, true)
			mp = mclair
			if _hab.extension and lh < 3.5:
				mclair = _hab.mz("moulure", zl, "monde", 1.0, true)      # P6.4.2 : claveaux clairs de l'arc de la bouche
		if lh < 3.5:
			# arc de la bouche : un bandeau de pierre claire et son chaperon, sans masse sombre au-dessus
			haut.append(_box_mesh(_rect_center(r, lb, lh), Vector3(r.size.x, lh - lb, r.size.y), mp, pivot))
			haut.append(_box_mesh(_rect_center(r.grow(0.06), lh, lh + 0.12), Vector3(r.size.x + 0.12, 0.12, r.size.y + 0.12), mclair, pivot))
		else:
			haut.append(_box_mesh(_rect_center(r, lb, 3.0), Vector3(r.size.x, 3.0 - lb, r.size.y), mclair, pivot))
			var msombre: Material = _hab.mat(Habillage.PIERRE, 2.4, Habillage.C_CALCAIRE * Color(0.42, 0.38, 0.38), true) if _hab != null else mp
			if pil:
				msombre = _hab.mm("mur_haut", zl, "monde", 1.0, true)
			haut.append(_box_mesh(_rect_center(r, 3.0, lh), Vector3(r.size.x, lh - 3.0, r.size.y), msombre, pivot))
		var arc := lh < 3.5
		if arc:
			# P6.2-D : arc de la bouche = fin de la voûte du tunnel : sommiers sous le bandeau (profil d'arc), et un volume
			# d'occultation (sans collision) : s'il passe devant Aren, une trouée locale s'ouvre dans la pierre (système
			# d'occlusion validé de la forêt) au lieu de faire disparaître tout l'arc
			# P6.3 : arc segmentaire en claveaux (plus une poutre droite) : naissances sur les murs du tunnel à 2,3 m,
			# clé à 2,95 m ; claveaux de pierre claire, clé légèrement saillante
			haut.clear()
			for ch in pivot.get_children():
				ch.queue_free()
			var cx := r.get_center().x
			var demi := r.size.x * 0.5
			var fl := 0.65                                        # flèche de l'arc
			var rr := (demi * demi + fl * fl) / (2.0 * fl)        # rayon de l'arc segmentaire
			var a0 := asin(demi / rr)
			var nv := 9
			for i in nv:
				var t := -a0 + 2.0 * a0 * (i + 0.5) / nv
				var px := cx + rr * sin(t)
				var py := 2.3 - (rr - fl) + rr * cos(t)
				var cle := i == nv / 2
				var v := _box_mesh(Vector3(px, py + 0.12, r.get_center().y), Vector3(2.0 * rr * sin(a0) / nv * 0.94, 0.42 if cle else 0.36, r.size.y + (0.08 if cle else 0.0)), mclair if cle else mp, pivot)
				v.rotation.z = -t
				haut.append(v)
			for sx in [r.position.x + 0.2, r.end.x - 0.2]:
				haut.append(_box_mesh(Vector3(sx, 2.25, r.get_center().y), Vector3(0.5, 0.14, r.size.y + 0.1), mclair, pivot))
			_static_box(_rect_center(r, lb - 0.6, lh), Vector3(r.size.x, lh - lb + 0.6, r.size.y), L_OCC)
		var coupe := _box_mesh(_rect_center(r, lb - 0.01, lb + 0.01), Vector3(0.01, 0.01, 0.01), _mat_coupe(), pivot)
		_sect.declarer_mur(pivot, coupe, r, lb, lh, haut, null, arc)


# ------------------------------------------------------------------------------------------------ P6.3 modèles
const QUAT := "res://art/p63/quaternius/"   # sélection Quaternius (CC0), voir art/p63/quaternius/SOURCES.md
var _qcache := {}
var _au_mur: Array = []                     # P6.3 : modèles fixés aux murs (suivent leur coupe)
var _au_coupe: Array = []                   # P6.3.2 : variantes « mur coupé » (porte basse), visibles seulement coupé
var _qmat := {}
var _rects_p64: Array = []                  # P6.4 : emprises des murs pilotes (linteaux associés)


## Instancie un modèle de la sélection Quaternius (« fp/Bench », « mv/Door_8_Round »…) : position monde, rotation
## autour de y, échelle (nombre ou Vector3), teinte facultative (matériaux dupliqués une fois par teinte), métas.
func modele(chemin: String, pos: Vector3, rot_y := 0.0, k: Variant = 1.0, teinte := Color.WHITE, meta := {}) -> Node3D:
	if not _qcache.has(chemin):
		_qcache[chemin] = load(QUAT + chemin + ".gltf")
	var ps: PackedScene = _qcache[chemin]
	if ps == null:
		return null
	var n: Node3D = ps.instantiate()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = k if k is Vector3 else Vector3.ONE * float(k)
	n.set_meta("xz", Vector2(pos.x, pos.z))
	for kk in meta:
		n.set_meta(kk, meta[kk])
	var pile: Array = [n]
	while not pile.is_empty():
		var c = pile.pop_back()
		for e in c.get_children():
			pile.append(e)
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			# luminaires : pas d'ombre portée (leur cage entourait la source et l'éteignait)
			var lum := chemin.contains("Lantern") or chemin.contains("Torch")
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if lum else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			if teinte != Color.WHITE and mi.mesh != null:
				for si in mi.mesh.get_surface_count():
					var m0: Material = mi.get_active_material(si)
					if m0 is BaseMaterial3D and (m0.resource_name == "" or "Banner" in m0.resource_name or "Cloth" in m0.resource_name or not meta.get("teinte_tissu", false)):
						var cle := "%s|%s" % [m0.get_instance_id(), teinte]
						if not _qmat.has(cle):
							var m1 := (m0 as BaseMaterial3D).duplicate() as BaseMaterial3D
							m1.albedo_color = (m0 as BaseMaterial3D).albedo_color * teinte
							_qmat[cle] = m1
						mi.set_surface_override_material(si, _qmat[cle])
	root.add_child(n)
	return n


## P6.3 : mobilier des données remplacé par un modèle (même emprise ; la collision reste celle des données).
func _meuble_modele(nom: String, r: Rect2) -> bool:
	var c := r.get_center()
	var long_x := r.size.x >= r.size.y
	var rot := 0.0 if long_x else PI / 2.0
	var p := Vector3(c.x, 0.0, c.y)
	if nom.begins_with("banc"):
		var lg := maxf(r.size.x, r.size.y)
		modele("fp/Bench", p, rot, Vector3(lg / 2.78, 0.9, 1.0))
	elif nom.begins_with("ratelier"):
		var lg2 := maxf(r.size.x, r.size.y)
		var n := maxi(1, int(round(lg2 / 1.5)))
		for i in n:
			var t := (i + 0.5) / n
			var q := Vector3(lerpf(r.position.x, r.end.x, t), 0.0, c.y) if long_x else Vector3(c.x, 0.0, lerpf(r.position.y, r.end.y, t))
			modele("fp/WeaponStand", q, rot, 0.85)
	elif nom.begins_with("mannequin"):
		modele("fp/Dummy", p, 0.0, 0.92)
	elif nom.begins_with("coffre"):
		modele("fp/Chest_Wood", p, 0.0, minf(1.0, r.size.x / 1.28))
	elif nom.begins_with("caisses"):
		modele("fp/Crate_Wooden", p + Vector3(-0.45, 0, 0.3), 0.2, 0.85)
		modele("fp/Crate_Wooden", p + Vector3(0.55, 0, -0.2), -0.15, 0.7)
	elif nom.begins_with("table"):
		modele("fp/Table_Large", p, rot, Vector3(maxf(r.size.x, r.size.y) / 2.85, 0.95, minf(r.size.x, r.size.y) / 1.1))
		modele("fp/Stool", p + Vector3(-0.25, 0, 0.3), 0.4, 0.95)          # sous le bord de la table (dans son emprise)
	elif nom.begins_with("tonneaux"):
		modele("fp/Barrel", p + Vector3(-0.35, 0, 0), 0.0, 1.0)
		modele("fp/Barrel", p + Vector3(0.45, 0, 0.1), 0.6, 0.95)
	else:
		return false
	return true


## P6.3 : porte fermée habillée (encadrement cintré en pierre + vantaux de bois ferré), dans l'épaisseur du mur.
func _porte_habillee(r: Rect2) -> void:
	var le_long_x := r.size.x >= r.size.y
	var w := r.size.x if le_long_x else r.size.y
	var c := r.get_center()
	# face intérieure : vers le centre de la pièce praticable la plus proche
	var dir := Vector2(0, 1)
	for sx in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
		if (le_long_x and sx.x != 0.0) or (not le_long_x and sx.y != 0.0):
			continue
		if not world.surface_at(c + sx * 1.0, 0.0).is_empty():     # sol de la pièce (les meubles ne comptent pas)
			dir = sx
	var rot := atan2(dir.x, dir.y)
	# contre la face intérieure du mur (épaisseur 0,4 m) : sinon le mur continu cache la porte
	var d3 := Vector3(dir.x, 0, dir.y)
	var cadre := modele("mv/DoorFrame_Round_Brick", Vector3(c.x, 0, c.y) + d3 * 0.1, rot, Vector3((w + 0.5) / 1.6, 1.0, 1.0), Color(1.05, 1.0, 0.95))
	_au_mur.append(cadre)
	var lw := w * 0.5
	var axe := Vector3(cos(rot), 0, -sin(rot))
	for side in [-1.0, 1.0]:
		var bord: Vector3 = Vector3(c.x, 0, c.y) + axe * float(side) * lw
		var k := Vector3(-float(side) * lw / 1.15, 0.98, 1.0)
		_au_mur.append(modele("mv/Door_8_Round", bord + d3 * 0.22, rot, k))
		if not p64 or porte_coupe == "p632":
			# P6.3.2 : porte basse (1,2 m) pour quand le mur est coupé (comparaison)
			_au_coupe.append(modele("mv/Door_8_Round", bord + d3 * 0.22, rot, Vector3(k.x, 1.2 / 2.36, 1.0)))
		else:
			# P6.4 : vantaux EN COUPE (taille réelle, tranchés au niveau du muret) ; « silhouette » : partie retirée
			# lisible en transparence
			_au_coupe.append(_en_coupe(modele("mv/Door_8_Round", bord + d3 * 0.22, rot, k), Secteurs.LIP + 0.04))
			if porte_coupe == "C":
				# C : ferrure de verrouillage sur la tranche des vantaux (barre et moraillon), des deux côtés
				for sgn in [-1.0, 1.0]:
					var fer := _box_mesh(bord + axe * (-float(side) * lw * 0.5) + d3 * (0.22 + 0.075 * sgn) + Vector3(0, 0.36, 0), Vector3(lw * 0.98, 0.07, 0.025) if le_long_x else Vector3(0.025, 0.07, lw * 0.98), _mat_fer())
					fer.rotation.y = 0.0
					_au_coupe.append(fer)
			if porte_coupe == "silhouette":
				_au_coupe.append(_en_fantome(modele("mv/Door_8_Round", bord + d3 * 0.22, rot, k), Secteurs.LIP + 0.04))
	if not p64 or porte_coupe == "p632":
		_au_coupe.append(modele("mv/DoorFrame_Round_Brick", Vector3(c.x, 0, c.y) + d3 * 0.1, rot, Vector3((w + 0.5) / 1.6, 1.3 / 2.58, 1.0), Color(1.05, 1.0, 0.95)))
	else:
		# P6.4 : encadrement EN COUPE : jambages entiers jusqu'à la naissance de l'arc (1,85 m), tranchés au-dessus ;
		# l'ouverture garde sa vraie largeur et sa vraie hauteur de passage ; l'arc reste en silhouette
		var kc := Vector3((w + 0.5) / 1.6, 1.0, 1.0)
		var pc := Vector3(c.x, 0, c.y) + d3 * 0.1
		_au_coupe.append(_en_coupe(modele("mv/DoorFrame_Round_Brick", pc, rot, kc, Color(1.05, 1.0, 0.95)), 1.85))
		if porte_coupe == "C":
			# moraillon au milieu (là où les vantaux se rejoignent) et indication discrète de porte fermée
			for sgn in [-1.0, 1.0]:
				_au_coupe.append(_box_mesh(Vector3(c.x, 0.36, c.y) + d3 * (0.22 + 0.095 * sgn), Vector3(0.14, 0.18, 0.03) if le_long_x else Vector3(0.03, 0.18, 0.14), _mat_fer()))
			# à côté de la porte, contre le jambage (jamais sur l'axe du passage : il ne se superpose pas à Aren)
			_marque_porte(Vector3(c.x, 0.0, c.y) + axe * (w * 0.5 + 0.5) + d3 * 0.35)
		if porte_coupe == "silhouette":
			_au_coupe.append(_en_fantome(modele("mv/DoorFrame_Round_Brick", pc, rot, kc, Color(1.05, 1.0, 0.95)), 1.85))
		# seuil de pierre encastré (à fleur du sol : aucun relief praticable), des deux côtés de la porte
		if _hab != null:
			var long := Vector3(w + 0.5, 0.02, 1.1) if le_long_x else Vector3(1.1, 0.02, w + 0.5)
			var seuil := _box_mesh(Vector3(c.x, 0.004, c.y), long, _hab.m64("dalle", "monde", 1.0, false, Color(0.85, 0.82, 0.8)))
			seuil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			seuil.set_meta("sol", true)             # structure : toujours rendu avec les sols voisins
			seuil.set_meta("xz", c)
	if cadre != null:
		cadre.set_meta("porte", true)


var _m_fer: StandardMaterial3D
var _tex_cadenas: ImageTexture


func _mat_fer() -> StandardMaterial3D:
	if _m_fer == null:
		_m_fer = StandardMaterial3D.new()
		_m_fer.albedo_color = Color(0.16, 0.15, 0.15)
		_m_fer.metallic = 0.6
		_m_fer.roughness = 0.45
	return _m_fer


## P6.4.1 : indication discrète d'une porte fermée : petit cadenas dessiné au pixel (24 × 24, généré ici, aucune
## ressource externe), au-dessus du seuil, qui n'apparaît qu'à l'approche d'Aren (moins de 2,4 m) puis s'estompe.
func _marque_porte(pos: Vector3) -> void:
	if _tex_cadenas == null:
		var im := Image.create(24, 24, false, Image.FORMAT_RGBA8)
		im.fill(Color(0, 0, 0, 0))
		var bord := Color(0.12, 0.09, 0.07, 1.0)
		var corps := Color(0.86, 0.72, 0.42, 1.0)
		var ombre := Color(0.62, 0.48, 0.26, 1.0)
		for y in range(11, 22):
			for x in range(5, 19):
				var b := y == 11 or y == 21 or x == 5 or x == 18
				im.set_pixel(x, y, bord if b else (ombre if y > 17 else corps))
		for x in range(8, 16):                      # anse
			for y in range(3, 12):
				var dx := absf(x + 0.5 - 12.0)
				var r := Vector2(dx, maxf(0.0, 8.0 - y)).length()
				if y >= 8:
					r = dx
				if absf(r - 3.0) < 0.75 or (y >= 8 and (x == 8 or x == 15)):
					im.set_pixel(x, y, bord)
				elif absf(r - 2.0) < 0.6 and y < 11:
					im.set_pixel(x, y, Color(0.72, 0.7, 0.66, 1.0))
		for p in [Vector2i(11, 14), Vector2i(12, 14), Vector2i(11, 15), Vector2i(12, 15), Vector2i(11, 16), Vector2i(12, 16), Vector2i(11, 17), Vector2i(12, 17)]:
			im.set_pixelv(p, bord)                     # entrée de serrure
		_tex_cadenas = ImageTexture.create_from_image(im)
	var sp := Sprite3D.new()
	sp.texture = _tex_cadenas
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sp.shaded = false
	sp.no_depth_test = true
	sp.render_priority = 10
	sp.pixel_size = 0.015
	sp.position = pos + Vector3(0, 0.95, 0)
	sp.modulate = Color(1, 1, 1, 0)
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sp.set_meta("hors_secteurs", true)
	root.add_child(sp)
	_marques_portes.append([sp, Vector2(pos.x, pos.z)])


func _maj_marques_portes(delta: float) -> void:
	if s == null:
		return
	var hp := Vector2(s.hero.x, s.hero.y)
	for mq in _marques_portes:
		var sp: Sprite3D = mq[0]
		if not is_instance_valid(sp):
			continue
		var d := hp.distance_to(mq[1])
		var cible := 0.85 * (1.0 - smoothstep(1.6, 2.4, d))
		sp.modulate.a = move_toward(sp.modulate.a, cible, delta * 3.0)
		sp.visible = sp.modulate.a > 0.01


const COUPE_SH := preload("res://src/p6/coupe_p64.gdshader")
const FANTOME_SH := preload("res://src/p6/fantome_p64.gdshader")


## P6.4 : remplace les matériaux d'un modèle par sa version EN COUPE (au-dessus de y_coupe : retiré ; intérieur mis
## à nu : teinte sombre de la tranche des murs).
func _en_coupe(n: Node3D, y_coupe: float) -> Node3D:
	return _remateriau(n, COUPE_SH, y_coupe)


## P6.4 : silhouette transparente de la partie retirée d'un modèle (au-dessus de y_coupe).
func _en_fantome(n: Node3D, y_coupe: float) -> Node3D:
	var f := _remateriau(n, FANTOME_SH, y_coupe)
	for mi in _geometries(f):
		(mi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return f


func _geometries(n: Node) -> Array:
	var out: Array = []
	var pile: Array = [n]
	while not pile.is_empty():
		var c = pile.pop_back()
		for e in c.get_children():
			pile.append(e)
		if c is MeshInstance3D:
			out.append(c)
	return out


func _remateriau(n: Node3D, sh: Shader, y_coupe: float) -> Node3D:
	if n == null:
		return null
	for mi in _geometries(n):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for si in m3.mesh.get_surface_count():
			var m0 := m3.get_active_material(si) as BaseMaterial3D
			var m := ShaderMaterial.new()
			m.shader = sh
			m.set_shader_parameter("y_coupe", y_coupe)
			m.set_shader_parameter("miroir", 1.0 if n.scale.x * n.scale.y * n.scale.z < 0.0 else 0.0)
			if m0 != null:
				m.set_shader_parameter("albedo", m0.albedo_color)
				m.set_shader_parameter("has_tex", 1.0 if m0.albedo_texture != null else 0.0)
				if m0.albedo_texture != null:
					m.set_shader_parameter("albedo_tex", m0.albedo_texture)
				m.set_shader_parameter("uv1_scale", m0.uv1_scale)
				m.set_shader_parameter("uv1_offset", m0.uv1_offset)
			m3.set_surface_override_material(si, m)
	return n


## P6.3 / P6.3.1 : tranche de gradins devant le tunnel est (maillages construits par l'habillage). P6.3 la coupait
## quand Aren était dans le tunnel est : l'enceinte paraissait trouée et le sol de dessous visible. P6.3.1 : elle n'est
## JAMAIS coupée (enceinte continue) ; un volume d'occultation sans collision ouvre la trouée locale tramée (système
## validé en forêt) quand elle passe devant Aren. Aucune collision (les gradins n'en ont pas : seul le podium bloque).
func tranche_gradins(meshes: Array) -> void:
	var aabb := AABB()
	var premier := true
	for m in meshes:
		var mi := m as MeshInstance3D
		if mi == null:
			continue
		var a := mi.get_aabb()
		aabb = a if premier else aabb.merge(a)
		premier = false
	if premier:
		return
	# volume découpé en tranches radiales grossières : il suit l'anneau au lieu de couvrir le tunnel et l'arène
	var arene: Dictionary = _p6.get("arene", {})
	if arene.is_empty():
		return
	var c := Vector2(arene["centre"][0], arene["centre"][1])
	var rx: float = float(arene["rayons"][0]) + float(arene["anneau_ep"])
	var ry: float = float(arene["rayons"][1]) + float(arene["anneau_ep"])
	var prof: float = arene["gradins_prof"]
	for deg in range(4, 46, 6):
		var am := deg_to_rad(deg + 3.0)
		var r_mid := 0.5 * prof
		var p := Vector2(c.x + (rx + r_mid) * cos(am), c.y + (ry + r_mid) * sin(am))
		var sb := _static_box(Vector3(p.x, aabb.end.y * 0.5, p.y), Vector3(prof * 0.9, aabb.end.y, 1.6), L_OCC)
		sb.rotation.y = -atan2(ry * sin(am), rx * cos(am))

## P6.2-D : naissance de la voûte du tunnel (passage couvert vu en coupe) : deux ressauts vers l'intérieur au sommet du
## mur, assombris ; le passage d'Aren (axe, 2,2 m de large) reste dégagé à l'écran.
func _naissance_voute(pivot: Node3D, r: Rect2, hv: float) -> void:
	var vers := 1.0 if r.get_center().x < 26.0 else -1.0       # vers l'intérieur du tunnel
	var face := r.end.x if vers > 0.0 else r.position.x
	var m1: Material = _hab.mat(Habillage.PIERRE, 2.4, Habillage.C_CALCAIRE * Color(0.62, 0.58, 0.56), true) if _hab != null else _tinted("pierre", Color(0.6, 0.58, 0.6), true)
	var m2: Material = _hab.mat(Habillage.PIERRE, 2.4, Habillage.C_CALCAIRE * Color(0.42, 0.38, 0.38), true) if _hab != null else _tinted("pierre", Color(0.4, 0.38, 0.4), true)
	if _hab != null and _hab.extension and _hab.p64:
		m1 = _hab.mz("moulure", "tunnel", "monde", 1.0, true, Color(0.78, 0.76, 0.74))      # P6.4.2 : naissance de voûte
		m2 = _hab.mz("mur_sombre", "tunnel", "monde", 1.0, true)
	for k in 2:
		var ep := 0.22 + 0.2 * k
		var h0 := hv - 0.05 + 0.24 * k
		var mi := _box_mesh(Vector3(face + vers * ep * 0.5, h0 + 0.12, r.get_center().y), Vector3(ep, 0.24, r.size.y), m1 if k == 0 else m2, pivot)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## P6.2-D : encadrement de l'entrée du tunnel côté salle (piédroits en saillie sous le linteau).
func _entree_tunnel() -> void:
	var vt: Dictionary = _p6.get("vue_tunnel", {})
	if vt.is_empty() or _sect == null or _sect.mode == "echelle":
		return
	var z: float = vt.get("entree", 37.5)
	var b: Array = vt["bouche"]
	if _hab != null:
		# P6.3 : transition lumineuse — deux torches à l'entrée côté salle (chaud), la pénombre au milieu, le jour au bout
		for side in [[float(b[0]), PI / 2.0], [float(b[1]), -PI / 2.0]]:
			var tp := Vector3(side[0], 1.95, z - 1.4)
			var t := modele("fp/Torch_Metal", tp, side[1], 1.1)
			_au_mur.append(t)
			if t != null:
				t.set_meta("secteur", "S3")
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.62, 0.3)
			l.light_energy = 1.1
			l.omni_range = 4.2
			l.omni_attenuation = 1.6
			l.position = tp + Vector3(0.35 if side[1] > 0 else -0.35, 0.35, 0)
			l.set_meta("secteur", "S3")
			root.add_child(l)
			_halo(l.position, 0.6, 0.5)
	var mp: Material = _hab.mat(Habillage.PIERRE, 1.2, Habillage.C_CALCAIRE * Color(1.1, 1.06, 1.0), true) if _hab != null else _surf("pierre", true)
	if _hab != null and _hab.extension and _hab.p64:
		mp = _hab.mz("moulure", "salle", "monde", 1.0, true)          # P6.4.2 : piédroits de l'entrée du tunnel
	for x in [float(b[0]) - 0.15, float(b[1]) + 0.15]:
		var pivot := Node3D.new()
		pivot.name = "piedroit_%d" % int(x * 10)
		pivot.set_meta("xz", Vector2(x, z + 0.12))
		pivot.set_meta("mur", true)
		root.add_child(pivot)
		_box_mesh(Vector3(x, 1.4, z + 0.12), Vector3(0.3, 2.8, 0.25), mp, pivot)
		_box_mesh(Vector3(x, 2.85, z + 0.14), Vector3(0.42, 0.14, 0.32), mp, pivot)


## P6.2-B : la lumière du jour de l'arène entre par le bout du tunnel (une vraie source, pas un panneau).
func _jour_du_tunnel() -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.9, 0.74)
	l.light_energy = 1.6
	l.omni_range = 7.0
	l.omni_attenuation = 1.4
	l.position = Vector3(26.0, 2.0, 31.2)
	l.set_meta("hors_secteurs", true)
	root.add_child(l)
	# P6.2-D : autres bouches vers le jour (sortie est vers la ville, tunnel est côté arène)
	for j in _p6.get("jours", []):
		var lj := OmniLight3D.new()
		lj.light_color = Color(1.0, 0.92, 0.78)
		lj.light_energy = float(j[3])
		lj.omni_range = float(j[4])
		lj.omni_attenuation = 1.4
		lj.position = Vector3(j[0], j[2], j[1])
		lj.set_meta("hors_secteurs", true)
		root.add_child(lj)


## Mode C : bref fondu sombre, nouvelle pièce appliquée d'un coup, caméra recalée, retour de l'image.
func _passer_porte() -> void:
	var tw: Tween = s.fade_to(0.85, 0.14)
	await tw.finished
	_sect.mettre_a_jour(Vector2(s.hero.x, s.hero.y), true)
	_fondu_porte = false
	_maj_secteur(true)
	s.fade_to(0.0, 0.22)


# ------------------------------------------------------------------------------------------------ P7.3 ville V0.6
func _zone_ville() -> String:
	if _ville_ver == "v07b":
		return ZONE_VILLE_V07B
	if _ville_ver == "v07a":
		return ZONE_VILLE_V07A
	return ZONE_VILLE_V06 if _ville_ver == "v06" else ZONE_VILLE


var _zoom_fixe_dit := false


func _entree_zoom(e: InputEvent) -> bool:
	if e is InputEventMouseButton and e.pressed:
		return e.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]
	if e is InputEventKey and e.pressed:
		return e.physical_keycode in [KEY_PAGEUP, KEY_PAGEDOWN, KEY_KP_ADD, KEY_KP_SUBTRACT, KEY_EQUAL, KEY_MINUS]
	return false


## Caméra selon la zone chargée : ville V0.6 -> caméra de la ville (plongée, projection, altitude lissée, zoom ×3) ;
## ailleurs (Colisée, quartier, blockout V0.1) -> caméra du Colisée (cam_p6), inchangée. Appelée avant la construction
## de l'instance (les cartes et les sprites dépendent de la plongée).
func _camera_de_zone() -> void:
	var ville06: bool = _p6.get("zone", "") == "ville" and str(_p6.get("ville", {}).get("version", "")) in ["v06", "v07a", "v07b"]
	# P7.4 : azimut de départ de la zone (caméra B : celui du secteur d'arrivée, sans rotation visible au chargement)
	World25.yaw = _yaw_base
	_zone_cam = ""
	_yaw_vit = 0.0
	World25.yaw_commande_actif = false
	_yaw_snap = true
	var voulu: String = cam_v06 if ville06 else CAMS_P6[cam_p6][0]
	var change := voulu != cam_mode or ville06 != _cam_ville
	_cam_ville = ville06
	cam_mode = voulu
	s.cam_lissage_h = 0.45 if (ville06 or voulu == "V06") else 0.0
	if change:
		_apply_variante()
		_cam_basis()
		s.cam.set_index(ZOOM_V06 if ville06 else CAMS_P6[cam_p6][1], false)
	cam.far = 900.0 if ville06 else 400.0
	s.cam.verrou = voulu == "V06"                # P7.4.1 : distance unique (ville et Colisée), parcours compris
	if ville06:
		s.arch = "P7.3 — Ville V0.6 · " + CAMS_V06_LABEL[cam_v06] + " · P8.0-A : plongée de base %.0f°" % plongee_ville() + (" · zone de lecture %.0f° (belvédère)" % zone_lecture_deg() if zone_lecture_deg() > 0.0 else "")
		s._help.text = "Flèches / ZQSD : marcher  ·  Maj : courir  ·  E / Entrée : examiner  ·  C : caméra (V0.6 perspective / orthographique / V0.5)  ·  L : libellés  ·  F1 : infos"


func _apply_variante() -> void:
	super._apply_variante()
	# P7.12.1 : cadrage stable pendant les interactions ordinaires (ville, caméra « V » du Colisée) ; --visee_dialogue=1 : P3
	s.cam.visee_fixe = false
	if (_cam_ville and cam_mode != "P24") or cam_mode == "V06":
		# P8.0-A : en ville, plongée de base de l'expérience de cadrage ; le Colisée garde v06_plongee (11°)
		World25.pitch = deg_to_rad(plongee_ville() if _cam_ville else float(_cli.get("v06_plongee", PLONGEE_V06)))
		s.cam.aim_frac = float(_cli.get("v06_visee", AIM_V06))
		s.cam.visee_fixe = str(_cli.get("visee_dialogue", "0")) != "1"


## Caméra perspective de la ville V0.6 : même principe que la P30 / P24 (Aren au même point de l'écran, à la même
## taille qu'en orthographique), champ propre à la ville (réglable : -- --v06_champ=, --v06_plongee=, --v06_visee=).
func apply_camera(center: Vector2, zoom: float) -> void:
	if _cam_ville and cam_mode == "V06O":
		# orthographique : le socle place la caméra à 120 m d'un plan fixe, ce qui la met devant Aren au sud de la
		# ville (y > 120 m) ; ici, 150 m derrière la profondeur d'Aren (même cadrage, aucune autre différence)
		var vpo: Vector2 = Session25.viewport_size(self)
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = vpo.y / (World25.PPM * zoom)
		var depth_o := body.global_position.dot(World25.cam_back()) if body != null else 0.0
		cam.position = World25.cam_right() * (center.x / World25.PPM) + World25.cam_up() * (-center.y / World25.PPM) + World25.cam_back() * (depth_o + 150.0)
		return
	if cam_mode != "V06":
		super.apply_camera(center, zoom)
		return
	var fov := float(_cli.get("v06_champ", CHAMP_V06))
	# P7.6 : V0.7-B — la trame des volumes proches (P7.3) est remplacée par l'escamotage des volumes qui contiennent la
	# caméra ou la frôlent entre elle et Aren (scenes/p7/ville_v07b.gd, coupes_camera). --near_ville=<m> : essai d'un plan
	# proche reculé (écarté : il évide aussi les façades latérales) ; --coupe_ville=0 : trame d'origine (comparaison).
	cam.near = float(_cli.get("near_ville", 0.5)) if coupe_ville() > 0.0 else 0.5
	var vp: Vector2 = Session25.viewport_size(self)
	var h_view := vp.y / (World25.PPM * zoom)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = fov
	var axis := World25.cam_right() * (center.x / World25.PPM) + World25.cam_up() * (-center.y / World25.PPM)
	var depth := body.global_position.dot(World25.cam_back()) if body != null else 0.0
	cam.position = axis + World25.cam_back() * (depth + h_view * 0.5 / tan(deg_to_rad(fov) * 0.5))


## P7.6 : > 0 quand la ville V0.7-B escamote les volumes proches de la caméra (au lieu de la trame de P7.3).
func coupe_ville() -> float:
	if _ville_ver != "v07b" or str(_cli.get("coupe_ville", "1")) == "0" or _p6.get("zone", "") != "ville":
		return 0.0
	return 1.0


# ------------------------------------------------------------------------------------------------ P7.4 caméra B
## Secteur de caméra du héros (mode B) : on entre dans une zone quand on est dans son rectangle ; on n'en sort qu'à
## « marge_m » au-delà (hystérésis : pas d'oscillation en longeant une limite). Hors zones : azimut de base (nord).
func _secteur_camera(p: Vector2) -> Dictionary:
	var zs: Array = _p6.get("ville", {}).get("zones_camera", [])
	for z in zs:
		if str(z["id"]) == _zone_cam:
			var q: Array = z["rect"]
			if Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]).grow(float(z.get("marge_m", 2.0))).has_point(p):
				return z
	for z in zs:
		var q: Array = z["rect"]
		if Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]).has_point(p):
			return z
	return {}


## Oriente la caméra (mode B) vers l'azimut du secteur, sans saut : amortissement critique, vitesse bornée. Le cadrage
## est recalé pour qu'Aren garde exactement sa place à l'écran pendant la rotation ; les cartes des personnages suivent.
## Commandes : l'azimut des commandes reste celui d'avant la rotation tant qu'une direction est tenue (pas de dérive de
## la marche pendant qu'on tient une touche), puis rejoint celui de la caméra au relâchement.
func _yaw_secteurs(delta: float) -> void:
	# P7.4.1 : dans la ville, AUCUNE limite écran pour la caméra. Les limites calculées sur l'emprise des données
	# (x de 0 à 140 m) arrêtaient le suivi près du parvis du Colisée (x < 10) : Aren pouvait sortir de l'écran (mode A ;
	# en B, elles n'étaient effacées qu'après la première rotation). Le décor couvre toute la vue, rien ne justifie une
	# borne ; le suivi d'Aren l'emporte sur toute composition.
	s.cam.bounds = Rect2()
	if not _ville_ver in ["v07a", "v07b"]:
		return
	var hp := Vector2(s.hero.x, s.hero.y)
	var z: Dictionary = _secteur_camera(hp) if camera_ville == "B" else {}
	_zone_cam = str(z.get("id", ""))
	_yaw_cible = _yaw_base + deg_to_rad(float(z.get("azimut_deg", 0.0)))
	var avant := World25.yaw
	var nouv := avant
	if _yaw_snap:
		nouv = _yaw_cible
		_yaw_vit = 0.0
		_yaw_snap = false
	else:
		# ressort amorti critique : a = w²(cible − x) − 2w v, w = 1 / tau ; vitesse bornée
		var w := 1.0 / YAW_TAU
		_yaw_vit += (w * w * (_yaw_cible - avant) - 2.0 * w * _yaw_vit) * delta
		_yaw_vit = clampf(_yaw_vit, -deg_to_rad(YAW_VMAX), deg_to_rad(YAW_VMAX))
		nouv = avant + _yaw_vit * delta
		if absf(_yaw_cible - nouv) < 0.0002 and absf(_yaw_vit) < 0.002:
			nouv = _yaw_cible
			_yaw_vit = 0.0
	# commandes : verrou tant qu'une direction est tenue
	var tenu: bool = s.derniere_touche != Vector2.ZERO
	if camera_ville == "B":
		if not World25.yaw_commande_actif or not tenu:
			World25.yaw_commande = nouv if not tenu else World25.yaw_commande
		World25.yaw_commande_actif = true
		if not tenu:
			World25.yaw_commande = nouv
	else:
		# A : commandes = azimut de la caméra (aucun verrou) ; même conversion que B pour le pilote de mesure,
		# afin que les deux modes suivent exactement les mêmes trajectoires
		World25.yaw_commande_actif = true
		World25.yaw_commande = nouv
	if absf(nouv - avant) < 1e-7:
		return
	var hero_avant := World25.screen(s.hero)
	World25.yaw = nouv
	_recaler_vue(hero_avant)


## P7.4 / P7.4.1 : après un changement d'azimut ou de plongée, recale le cadrage pour qu'Aren garde exactement sa place
## à l'écran (la caméra pivote autour de lui), réoriente la caméra et les cartes des personnages.
func _recaler_vue(hero_avant: Vector2) -> void:
	var dec := World25.screen(s.hero) - hero_avant
	s.cam.center += dec
	s.cam.focus += dec
	s.cam.bounds = Rect2()                        # pas de limites écran (elles dépendent de l'azimut et de la plongée)
	_cam_basis()
	for k in actors:
		var nd: Node3D = actors[k]["node"]
		for ch in nd.get_children():
			if ch is Node3D and ch.get_child_count() > 0 and ch.get_child(0) is SpriteBase3D:
				(ch as Node3D).basis = Basis(Vector3.UP, -World25.yaw)
				(ch as Node3D).position = World25.cam_back() * SPRITE_TOWARD_CAM


# ------------------------------------------------------------------------------------------------ P7.4.1 Colisée
## Plongée de la caméra V0.7-A selon le secteur du Colisée. 11° (référence de la ville) partout, sauf l'arène (S4) :
## à 11°, la caméra passe sous les gradins sud et la toiture de la galerie, qui cachaient Aren près du podium ; à 20°
## elle passe au-dessus. Transition amortie (pivot autour d'Aren), immédiate après un chargement ou un téléport.
const PLONGEE_SECTEURS := {"S4": 20.0}
var _pitch_vit := 0.0
var _pitch_snap := true


func _profil_colisee(delta: float) -> void:
	if _sect == null:
		return
	var cible := deg_to_rad(float(PLONGEE_SECTEURS.get(_sect.actif, float(_cli.get("v06_plongee", PLONGEE_V06)))))
	var avant := World25.pitch
	var nouv := avant
	if _pitch_snap:
		nouv = cible
		_pitch_vit = 0.0
		_pitch_snap = false
	else:
		var w := 1.0 / 0.6
		_pitch_vit += (w * w * (cible - avant) - 2.0 * w * _pitch_vit) * delta
		_pitch_vit = clampf(_pitch_vit, -deg_to_rad(12.0), deg_to_rad(12.0))
		nouv = avant + _pitch_vit * delta
		if absf(cible - nouv) < 0.0002 and absf(_pitch_vit) < 0.002:
			nouv = cible
			_pitch_vit = 0.0
	if absf(nouv - avant) < 1e-7:
		return
	var hero_avant := World25.screen(s.hero)
	World25.pitch = nouv
	_recaler_vue(hero_avant)


## P7.12.1 — Plongée locale de la ville : sur la terrasse civique et l'avenue du château (niveau haut, y < 71), la plongée
## passe progressivement de 11° à 6,5° (bord haut du cadre ≈ 4° -> 8,5° au-dessus de l'horizon) pour que la porte fortifiée
## et le château lointain entrent dans le cadre ; même lissage critique et même recalage que dans le Colisée (aucun saut,
## aucun zoom). Ailleurs, 11° (inchangé). --plongee_civique=0 : désactivé.
const PLONGEE_CIVIQUE := 6.5


# ------------------------------------------------------------------------------------------------ P8.0-A cadrage
## P8.0-A — EXPÉRIENCE de cadrage de la ville (comparaison sur GPU, AUCUN angle retenu). Plongée de BASE de la ville :
## --plongee_ville=<degrés> (11, 13, 14 [P8.0-A2] ; 16, 20, 24 [P8.0-A]), sinon méta « plongee_ville » de la scène F6, sinon v06_plongee (11° : état
## P7.13 exact). Lue au chargement de la ville seulement : cartes, ombres rondes et sprites du décor sont dimensionnés
## selon la plongée à leur construction (1 / cos), un changement en cours de partie les fausserait. Le Colisée, le champ,
## le zoom, la visée et le suivi sont inchangés.
const PLONGEES_VILLE := [11.0, 13.0, 14.0, 16.0, 20.0, 24.0]


func plongee_ville() -> float:
	if _cli.has("plongee_ville") and str(_cli["plongee_ville"]).is_valid_float():
		return float(_cli["plongee_ville"])
	if has_meta("plongee_ville"):
		return float(get_meta("plongee_ville"))
	return float(_cli.get("v06_plongee", PLONGEE_V06))


## Plongée locale civique (6,5°) : P8.0-A2 — active par défaut pour les plongées de référence et de comparaison fine
## (11°, 13°, 14° : jusqu'à PLONGEE_CIVIQUE_MAX), coupée par défaut aux essais forts de P8.0-A (16°, 20°, 24°) pour qu'ils
## se comparent à angle constant ; --plongee_civique=1 la force, --plongee_civique=0 la coupe (comportement P7.12.1).
const PLONGEE_CIVIQUE_MAX := 14.0


func plongee_civique_active() -> bool:
	if _cli.has("plongee_civique"):
		return str(_cli["plongee_civique"]) != "0"
	return plongee_ville() <= PLONGEE_CIVIQUE_MAX + 0.01


# ------------------------------------------------------------------------------------------------ P8.0-A2 zone de lecture
## P8.0-A2 — ZONE EXPÉRIMENTALE de lecture (FACULTATIVE, désactivée par défaut) : sur la terrasse du belvédère (lieu
## d'arrêt : buvette, tables, emplacements de PNJ), la plongée monte de la plongée de base à --zone_lecture=<degrés>
## (17 ou 18 ; méta « zone_lecture » de la scène F6). Montée progressive sur les 2,5 premiers mètres de la terrasse
## (entrée nord, y 82 -> 84,5) puis lissage critique de 0,6 s, pivot autour d'Aren (_recaler_vue) : aucun saut, aucun zoom ;
## retour symétrique en sortant. Aren est redessiné à chaque image (taille à l'écran constante) ; les cartes 2D du décor
## et les ombres rondes gardent la taille calculée au chargement (écart de hauteur apparente ≈ -2,6 % à 17°, progressif).
const ZONE_LECTURE_RECT := Rect2(66.0, 82.0, 10.0, 6.0)     # terrasse_cafe des données (x 66 -> 76, y 82 -> 88)
const ZONE_LECTURE_H := 5.75
const ZONE_LECTURE_RAMPE := 2.5


func zone_lecture_deg() -> float:
	if _cli.has("zone_lecture") and str(_cli["zone_lecture"]).is_valid_float():
		return float(_cli["zone_lecture"])
	if has_meta("zone_lecture"):
		return float(get_meta("zone_lecture"))
	return 0.0


## Poids de la zone (0 hors de la terrasse, 1 à 2,5 m de son entrée) ; seulement au niveau de la terrasse.
func zone_lecture_poids() -> float:
	if zone_lecture_deg() <= 0.0 or absf(s.hero.z - ZONE_LECTURE_H) > 0.3:
		return 0.0
	var r := ZONE_LECTURE_RECT
	if s.hero.x < r.position.x or s.hero.x > r.end.x or s.hero.y > r.end.y + 0.3:
		return 0.0
	return smoothstep(r.position.y, r.position.y + ZONE_LECTURE_RAMPE, s.hero.y)


func _profil_ville(delta: float) -> void:
	if not _cam_ville or cam_mode != "V06" or _p6.get("ville", {}).get("version", "") != "v07b":
		return
	var base := plongee_ville()
	var p := base
	var wz := zone_lecture_poids()
	if wz > 0.0:
		p = lerpf(base, zone_lecture_deg(), wz)
	if plongee_civique_active() and s.hero.z > 7.0:
		var t := clampf((71.0 - s.hero.y) / 12.0, 0.0, 1.0)
		p = lerpf(base, float(_cli.get("plongee_civique_deg", PLONGEE_CIVIQUE)), smoothstep(0.0, 1.0, t))
	var cible := deg_to_rad(p)
	var avant := World25.pitch
	var nouv := avant
	if _pitch_snap:
		nouv = cible
		_pitch_vit = 0.0
		_pitch_snap = false
	else:
		var w := 1.0 / 0.6
		_pitch_vit += (w * w * (cible - avant) - 2.0 * w * _pitch_vit) * delta
		_pitch_vit = clampf(_pitch_vit, -deg_to_rad(12.0), deg_to_rad(12.0))
		nouv = avant + _pitch_vit * delta
		if absf(cible - nouv) < 0.0002 and absf(_pitch_vit) < 0.002:
			nouv = cible
			_pitch_vit = 0.0
	if absf(nouv - avant) < 1e-7:
		return
	var hero_avant := World25.screen(s.hero)
	World25.pitch = nouv
	_recaler_vue(hero_avant)

