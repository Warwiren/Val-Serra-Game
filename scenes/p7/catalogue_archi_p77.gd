extends Node3D
## P7.7 — CATALOGUE DES COMPOSANTS ARCHITECTURAUX (scenes/p7/archi_p77.gd), scène F6 de revue. Même éclairage et même
## projection que la caméra de la ville (perspective, plongée 11°, champ 30°). Aucun jeu, aucune collision.
##   Rangée A : façades complètes (palettes, 2 à 4 niveaux, rez-de-chaussée pierre / bossage / enduit, étages enduit /
##              pierre, corniches simple / à consoles, toits à deux versants dans les deux sens, à croupes, en appentis).
##   Rangée B : baies, volets, portes et balcons, sur un même mur.
## Touches : ← / → (ou Q / D) : vue précédente / suivante. Ligne de commande : --vue=N --capture=<dossier> (captures de
## toutes les vues puis sortie).

const Archi := preload("res://scenes/p7/archi_p77.gd")
const VUES := [
	# [titre, cible (x, y, h), recul]
	["A1 — façades : miel, ocre, gris chaud", Vector3(18.0, 0.0, 4.0), 34.0],
	["A2 — façades : rose, crème, terre", Vector3(62.0, 0.0, 4.0), 34.0],
	["B1 — fenêtres et volets", Vector3(11.0, -36.0, 2.6), 24.0],
	["B2 — portes-fenêtres, balcons, œil-de-bœuf", Vector3(37.0, -36.0, 3.2), 20.0],
	["B3 — portes, vitrine, devanture, grande baie", Vector3(64.5, -36.0, 2.4), 26.0],
	["A0 — rangée A à la distance de jeu (22 m)", Vector3(31.0, 0.0, 2.0), 22.4],
]

var a
var cam: Camera3D
var titre: Label
var vue := 0
var cli := {}


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var kv := arg.substr(2).split("=", true, 1)
			cli[kv[0]] = kv[1]
	_ambiance()
	var racine := Node3D.new()
	add_child(racine)
	a = Archi.new(racine)
	_rangee_a()
	_rangee_b()
	cam = Camera3D.new()
	cam.fov = 30.0
	add_child(cam)
	var cl := CanvasLayer.new()
	add_child(cl)
	titre = Label.new()
	titre.position = Vector2(16, 12)
	titre.add_theme_font_size_override("font_size", 22)
	titre.add_theme_color_override("font_outline_color", Color.BLACK)
	titre.add_theme_constant_override("outline_size", 6)
	cl.add_child(titre)
	vue = int(cli.get("vue", "0"))
	_regler_vue()
	if cli.has("capture"):
		_captures()


## Ambiance de la ville (colisee.gd et scenes/p7/ville_v06.gd._ambiance) : ambiance colorée, mappage linéaire, lueur,
## ciel de fin d'après-midi, même soleil ; sol de la couleur des rues du blockout.
func _ambiance() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
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
	env.ambient_light_color = Color(0.6, 0.6, 0.68)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.95
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.04
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34.0, -128.0, 0.0)
	sun.light_color = Color(1.0, 0.90, 0.78)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var sol := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 160)
	sol.mesh = pm
	sol.position = Vector3(40, 0, -10)
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.50, 0.47, 0.42)
	ms.roughness = 1.0
	sol.material_override = ms
	add_child(sol)


## Étiquette posée au sol devant un élément (lisible dans les captures de revue).
func _etiquette(texte: String, p: Vector3) -> void:
	var l := Label3D.new()
	l.text = texte
	l.font_size = 48
	l.pixel_size = 0.006
	l.outline_size = 10
	l.position = p
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(l)


func _desc(id: String, palette: String, niveaux: Array, faces_s: Array, extra := {}) -> Dictionary:
	var pal: Array = Archi.PALETTES[palette]
	var d := {"id": id, "niveaux": niveaux, "enduit": pal[0], "volets": pal[1], "toit_h": 2.6, "faces": {"s": faces_s}}
	for k in extra:
		d[k] = extra[k]
	return d


## Rangée A : six façades complètes de 9 m (y de -10 à 0 : façade sud en y = 0).
func _rangee_a() -> void:
	var specs := [
		["miel · 3 niveaux · pierre / enduit · deux versants (P7.6)", "miel", [0.0, 3.4, 5.6, 7.5],
			[[[2.2, 1.0, 1.6, 0.6, "fenetre"], [6.6, 1.2, 2.4, 0.0, "porte_cloutee"]],
			 [[2.2, 1.0, 1.85, 0.0, "porte_fenetre"], [6.6, 0.9, 1.4, 0.5, "fenetre"]],
			 [[2.2, 0.8, 1.1, 0.35, "fenetre"], [6.6, 0.8, 1.1, 0.35, "fenetre"]]],
			{"balcons": [["s", 1.4, 3.0, 1, 0.8]], "cheminee": [7.0, -6.0]}],
		["ocre · 4 niveaux · persiennes · corniche à consoles", "ocre", [0.0, 3.4, 5.8, 8.2, 10.4],
			[[[2.2, 2.2, 2.2, 0.4, "vitrine"], [6.8, 1.1, 2.3, 0.0, "porte_vitree"]],
			 [[2.2, 0.9, 1.5, 0.5, "fenetre"], [6.8, 0.9, 1.5, 0.5, "fenetre"]],
			 [[2.2, 0.9, 1.4, 0.5, "fenetre"], [6.8, 0.9, 1.4, 0.5, "fenetre"]],
			 [[2.2, 0.8, 1.1, 0.35, "fenetre"], [6.8, 0.8, 1.1, 0.35, "fenetre"]]],
			{"volets_style": "persiennes", "corniche": "consoles", "toit_h": 3.0}],
		["gris chaud · 2 niveaux · bossage · croupe", "gris_chaud", [0.0, 3.6, 6.4],
			[[[2.2, 1.0, 1.7, 0.5, "fenetre_cintree"], [6.6, 2.4, 3.0, 0.0, "porte_cochere"]],
			 [[2.2, 0.9, 1.4, 0.45, "fenetre"], [6.6, 0.9, 1.4, 0.45, "fenetre"]]],
			{"rdc": "bossage", "toit": "croupe", "toit_h": 2.4}],
		["rose · 3 niveaux · pignon face caméra", "rose", [0.0, 3.2, 5.6, 7.8],
			[[[2.2, 2.4, 2.0, 0.5, "devanture"], [6.8, 1.1, 2.3, 0.0, "porte_deco"]],
			 [[2.2, 0.9, 1.4, 0.5, "fenetre"], [4.5, 1.0, 1.85, 0.0, "porte_fenetre"], [6.8, 0.9, 1.4, 0.5, "fenetre"]],
			 [[4.5, 0.9, 0.9, 0.6, "oeil_de_boeuf"]]],
			{"toit": "2p_y", "toit_h": 3.2, "balcons": [["s", 3.7, 5.3, 1, 0.3, "balconnet"]]}],
		["crème · 3 niveaux · enduit sur toute la hauteur · volets fermés", "creme", [0.0, 3.2, 5.6, 7.6],
			[[[2.2, 0.9, 1.4, 0.8, "barreaux"], [6.8, 1.1, 2.3, 0.0, "porte_vitree"]],
			 [[2.2, 0.9, 1.4, 0.5, "fenetre"], [6.8, 0.9, 1.4, 0.5, "fenetre"]],
			 [[2.2, 0.8, 1.1, 0.35, "fenetre"], [6.8, 0.8, 1.1, 0.35, "fenetre"]]],
			{"rdc": "enduit", "volets_style": "fermes", "chaines": false}],
		["terre · 2 niveaux · étage de pierre · appentis · balcon de pierre", "terre", [0.0, 3.4, 6.2],
			[[[2.2, 2.4, 2.3, 0.55, "baie"], [6.8, 1.2, 2.4, 0.0, "porte_cloutee"]],
			 [[2.2, 1.0, 1.85, 0.0, "porte_fenetre"], [6.8, 1.0, 1.85, 0.0, "porte_fenetre"]]],
			{"etages": "pierre", "toit": "appentis", "toit_h": 1.8, "balcons": [["s", 1.0, 8.0, 1, 0.9, "pierre"]]}],
	]
	var x := 0.0
	for i in specs.size():
		var s: Array = specs[i]
		var d := _desc("A%d" % (i + 1), s[1], s[2], s[3], s[4])
		var r := Rect2(x, -10.0, 9.0, 10.0)
		if d.has("cheminee"):
			d["cheminee"] = [x + float(d["cheminee"][0]), d["cheminee"][1]]
		a.batiment(r, 0.0, d)
		_etiquette("A%d — %s" % [i + 1, s[0]], Vector3(x + 4.5, 0.05, 1.6))
		x += 14.0


## Rangée B : un long mur (façade sud en y = -36, derrière la rangée A) portant baies, volets, portes et balcons, deux niveaux.
func _rangee_b() -> void:
	var baies0 := []
	var baies1 := []
	var etiquettes := []
	var u := 2.0
	for spec in [["fenetre", "pleins", 1.0, 1.5, 0.8], ["fenetre", "persiennes", 1.0, 1.5, 0.8], ["fenetre", "fermes", 1.0, 1.5, 0.8],
			["fenetre_simple", "aucun", 1.0, 1.5, 0.8], ["fenetre_cintree", "pleins", 1.0, 1.6, 0.8], ["barreaux", "", 0.9, 1.2, 1.1]]:
		baies0.append([u, spec[2], spec[3], spec[4], spec[0]])
		etiquettes.append([u, "%s · %s" % [spec[0], spec[1]] if spec[1] != "" else spec[0]])
		u += 4.0
	# chaque volet a son propre style : un bâtiment-mur par style (même mur, morceaux juxtaposés)
	var morceaux := [[0.0, 4.0, "pleins"], [4.0, 8.0, "persiennes"], [8.0, 12.0, "fermes"], [12.0, 16.0, "aucun"], [16.0, 20.0, "pleins"], [20.0, 24.0, "pleins"]]
	for i in morceaux.size():
		var m: Array = morceaux[i]
		var b: Array = baies0[i].duplicate()
		b[0] = float(b[0]) - float(m[0])
		var d := _desc("B0_%d" % i, "miel", [0.0, 3.4, 6.0], [[b], []], {"volets_style": m[2], "chaines": false, "toit_h": 1.2})
		a.batiment(Rect2(m[0], -40.0, m[1] - m[0], 4.0), 0.0, d)
	for e in etiquettes:
		_etiquette(e[1], Vector3(e[0], 0.35, -34.6))
	# portes-fenêtres et balcons (fer, pierre, balconnet), œil-de-bœuf
	var d2 := _desc("B1", "ocre", [0.0, 3.4, 6.2, 8.0],
		[[[2.0, 0.9, 1.4, 0.6, "fenetre"], [6.5, 0.9, 1.4, 0.6, "fenetre"], [11.0, 0.9, 1.4, 0.6, "fenetre"]],
		 [[2.0, 1.0, 1.85, 0.0, "porte_fenetre"], [6.5, 1.0, 1.85, 0.0, "porte_fenetre"], [11.0, 1.0, 1.85, 0.0, "porte_fenetre"], [15.0, 0.9, 0.9, 0.5, "oeil_de_boeuf"]],
		 []], {"balcons": [["s", 1.0, 3.0, 1, 0.8, "fer"], ["s", 5.3, 7.7, 1, 0.8, "pierre"], ["s", 10.2, 11.8, 1, 0.3, "balconnet"]], "chaines": false, "toit_h": 1.4})
	a.batiment(Rect2(28.0, -40.0, 18.0, 4.0), 0.0, d2)
	for e in [[30.0, "balcon de fer"], [34.5, "balcon de pierre"], [39.0, "balconnet"], [43.0, "œil-de-bœuf"]]:
		_etiquette(e[1], Vector3(e[0], 0.35, -34.6))
	# portes, vitrine, devanture, grande baie
	var d3 := _desc("B2", "gris_chaud", [0.0, 3.6, 5.6],
		[[[2.0, 1.1, 2.3, 0.0, "porte_deco"], [5.5, 1.2, 2.4, 0.0, "porte_cloutee"], [9.0, 1.1, 2.3, 0.0, "porte_vitree"],
		  [13.5, 2.4, 3.0, 0.0, "porte_cochere"], [19.0, 2.4, 2.2, 0.4, "vitrine"], [24.5, 2.4, 2.0, 0.5, "devanture"], [29.5, 2.4, 2.3, 0.55, "baie"]],
		 []], {"chaines": false, "toit_h": 1.2})
	a.batiment(Rect2(48.0, -40.0, 33.0, 4.0), 0.0, d3)
	for e in [[50.0, "porte de planches"], [53.5, "porte cloutée"], [57.0, "porte vitrée"], [61.5, "porte cochère"], [67.0, "vitrine (auvent)"],
			[72.5, "devanture fermée"], [77.5, "grande baie"]]:
		_etiquette(e[1], Vector3(e[0], 0.35, -34.6))


func _regler_vue() -> void:
	var v: Array = VUES[vue]
	var cible: Vector3 = v[1]
	var recul: float = v[2]
	var p := Vector3(cible.x, cible.z, cible.y)
	var dirc := Vector3(0, sin(deg_to_rad(11.0)), cos(deg_to_rad(11.0)))
	cam.position = p + dirc * recul
	cam.look_at(p, Vector3.UP)
	titre.text = "%s   (%d / %d — ← / →)" % [v[0], vue + 1, VUES.size()]


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode in [KEY_RIGHT, KEY_D]:
			vue = (vue + 1) % VUES.size()
			_regler_vue()
		elif ev.keycode in [KEY_LEFT, KEY_Q, KEY_A]:
			vue = (vue + VUES.size() - 1) % VUES.size()
			_regler_vue()


func _captures() -> void:
	var dossier := str(cli["capture"])
	for i in VUES.size():
		vue = i
		_regler_vue()
		for k in 20:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("%s/catalogue_%d.png" % [dossier, i])
	get_tree().quit()
