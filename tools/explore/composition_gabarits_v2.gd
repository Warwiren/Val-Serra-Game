extends SceneTree
## P2 lot A — COMPOSITION DE RÉFÉRENCE des gabarits pilotes dans la carte V2 (aperçu seulement : la carte du jeu
## n'est PAS modifiée). Les deux maisons recolorées de la V2 sont masquées et remplacées, dans la scène chargée,
## par les gabarits (docs/media/gabarits_batiments/), avec leur emprise comme collision ; puis vérifications
## (chevauchements, point de porte libre et accessible) et captures 1280×720.
##   xvfb-run godot --rendering-driver opengl3 --path . --script res://tools/explore/composition_gabarits_v2.gd -- <dossier>

const GAB := "res://docs/media/gabarits_batiments/"
# bâtiment pilote -> [maison V2 qu'il remplacerait, pied proposé (px natifs de la carte V2)]
const PLAN := {
	"habitation": ["maison_ardoise", Vector2(861, 405)],     # hameau : porte au bout du chemin pavé
	"remise": ["maison_tuiles", Vector2(615, 318)],          # maison du haut : porte au bout du sentier de terre
}
var out := ""


func _initialize() -> void:
	out = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp"
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	change_scene_to_file("res://scenes/explore_hd2d/zone_exploration.tscn")
	for i in 4:
		await process_frame
	var z = current_scene
	var meta: Dictionary = JSON.parse_string(FileAccess.open(GAB + "gabarits.json", FileAccess.READ).get_as_text())
	var report := []
	for name in PLAN:
		var old: String = PLAN[name][0]
		var foot: Vector2 = PLAN[name][1]
		var m: Dictionary = meta["batiments"][name]
		# maison V2 remplacée : masquée, sa collision retirée (aperçu seulement)
		var old_fp := PackedVector2Array()
		for p in z.zone["sprites"][old]["footprint"]:
			old_fp.append(Vector2(p[0], p[1]))
		for o in z.occluders.duplicate():
			if o["name"] == old:
				o["sprite"].visible = false
				z.occluders.erase(o)
		for s in z.solids.duplicate():
			if s.size() == old_fp.size() and s[0].is_equal_approx(old_fp[0]):
				z.solids.erase(s)
		# gabarit posé comme le serait l'illustration définitive
		var img := Image.load_from_file(ProjectSettings.globalize_path(GAB + name + "/gabarit.png"))
		var spr := Sprite2D.new()
		spr.texture = ImageTexture.create_from_image(img)
		spr.centered = false
		spr.scale = Vector2(0.5, 0.5)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		spr.position = foot - Vector2(m["pivot_texture_px"][0], m["pivot_texture_px"][1]) * 0.5
		spr.z_index = int(foot.y)
		z.add_child(spr)
		var fp := PackedVector2Array()
		for p in m["emprise_natif_relative_au_pied"]:
			fp.append(foot + Vector2(p[0], p[1]))
		var line := Line2D.new()
		line.points = fp + PackedVector2Array([fp[0]])
		line.width = 1.0
		line.default_color = Color(1, 0.3, 0.3, 0.9)
		line.z_index = 3990
		z.add_child(line)
		# vérifications : chevauchement avec les autres éléments (solides ou non)
		var hits := []
		for g in z.zone["sprites"]:
			if g == old:
				continue
			var e: Dictionary = z.zone["sprites"][g]
			var q := PackedVector2Array()
			for p in e["footprint"]:
				q.append(Vector2(p[0], p[1]))
			if q.size() >= 3 and not Geometry2D.intersect_polygons(fp, q).is_empty():
				hits.append("%s (%s)" % [g, "solide" if e["solid"] else "traversable"])
		var inside := true
		for p in fp:
			inside = inside and Geometry2D.is_point_in_polygon(p, z.walkable)
		z.solids.append(fp)
		var door: Vector2 = foot + Vector2(m["point_interaction_porte_natif"][0], m["point_interaction_porte_natif"][1])
		report.append({"batiment": name, "remplace": old, "pied": foot, "emprise_dans_zone_praticable": inside,
			"chevauche": hits, "porte": door, "_door": door})
	# accessibilité des portes depuis le départ (mêmes collisions que le joueur, A* de la démo)
	z._astar = null
	var nav: AStarGrid2D = z._nav()
	var sp: Array = z.zone["spawn"]["heros"]
	for r in report:
		var d: Vector2 = r["_door"]
		r["porte_libre"] = z.free_at(d)
		r["porte_accessible"] = not nav.get_point_path(Vector2i(Vector2(sp[0], sp[1]) / z.CELL), Vector2i(d / z.CELL)).is_empty()
		print("COMPOSITION %s" % JSON.stringify(r))
	# captures : vue d'ensemble, puis chaque site avec Aren devant la porte (échelle du jeu)
	await _shot(z, out + "/composition_v2_ensemble.png", Vector2(704, 400), 1280.0 / 1408.0)
	for r in report:
		z.hero.position = r["_door"]
		z._place_party()
		z.hero.face_toward(Vector2(0, -1))
		await _shot(z, out + "/composition_v2_%s.png" % r["batiment"], r["_door"] + Vector2(0, -50), 2.0)
	var clean := report.map(func(r): r.erase("_door"); return r)
	FileAccess.open(out + "/composition_v2.json", FileAccess.WRITE).store_string(JSON.stringify(clean, "  "))
	quit()


func _shot(z, path: String, center: Vector2, zoom: float) -> void:
	z.set_process(true)
	await process_frame
	z.set_process(false)
	z.cam.limit_left = -10000; z.cam.limit_top = -10000; z.cam.limit_right = 10000; z.cam.limit_bottom = 10000
	z.cam.position_smoothing_enabled = false
	z.cam.zoom = Vector2.ONE * zoom
	z.cam.position = center
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
