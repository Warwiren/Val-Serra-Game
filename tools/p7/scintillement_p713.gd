extends SceneTree
## P7.13 — Détecteur de SCINTILLEMENT au rendu (z-fighting et ombres dépendantes de la caméra).
## Pour chaque point de vue (Aren placé, caméra de jeu), deux images identiques sont rendues avec un plan proche à peine
## différent (0,5 m puis 0,51 m) : la projection des points est la même, seule la précision de profondeur change. Les
## pixels qui basculent sont ceux qui scintillent en jeu quand la caméra bouge (faces coplanaires, ombres instables).
## Mesure à faire avec et sans ombres (--noshadow) pour séparer les deux causes. Sortie : une ligne SCINTILLEMENT par vue
## (pixels qui basculent, en ‰ de l'image, hors interface) et, avec --masques=<dossier>, l'image des pixels en cause.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/p7/scintillement_p713.gd -- [--noshadow]
##     [--points=x,y,h;...] [--masques=<dossier>] [options de la ville]
const POINTS := "70,104,3.5;60,108,3.5;78,106,3.5;63,79.5,5.75;71,83,5.75;70,60,8;70,47,8;59,137,0;62,124,1.75;66,130,1.75;82,128,0"
const SEUIL := 24          # écart de couleur (somme RGB, 0..765) au-delà duquel un pixel « bascule »

var sc
var n := 0
var pts := []
var i := 0
var etape := 0
var attente := 0
var img_a: Image
var img_b: Image
var masques := ""
var near_b := 0.51
var libre: Camera3D
var resultats := []


func _initialize() -> void:
	var p := POINTS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--points="):
			p = a.substr(9)
		elif a.begins_with("--near_b="):
			near_b = float(a.substr(9))
		elif a.begins_with("--masques="):
			masques = a.substr(10)
	for q in p.split(";"):
		var c := q.split(",")
		if c.size() >= 6:            # caméra libre (gros plan) : position x, y, h puis point visé x, y, h
			pts.append([Vector3(float(c[0]), float(c[2]), float(c[1])), Vector3(float(c[3]), float(c[5]), float(c[4]))])
		else:
			pts.append(Vector3(float(c[0]), float(c[1]), float(c[2])))
	change_scene_to_file("res://scenes/p7/ville_v07b.tscn")


func _process(_d: float) -> bool:
	n += 1
	if sc == null:
		if current_scene != null and current_scene.get("s") != null and current_scene.s != null and n > 60:
			sc = current_scene
		return false
	if i >= pts.size():
		var tot := 0.0
		for r in resultats:
			tot += float(r)
		print("SCINTILLEMENT_TOTAL ", snappedf(tot / maxf(1.0, resultats.size()), 0.001), " ‰ en moyenne sur ", resultats.size(), " vues")
		quit()
		return false
	attente += 1
	if libre != null and pts[i] is Array:
		libre.current = true
		libre.near = float(sc._cli.get("near_ville", 0.5))
	if etape == 0 and attente == 1:
		if pts[i] is Array:
			if libre == null:
				libre = Camera3D.new()
				libre.fov = 30.0
				sc.add_child(libre)
			libre.global_position = pts[i][0]
			libre.look_at(pts[i][1], Vector3.UP)
			libre.current = true
		else:
			if libre != null:
				libre.current = false
				sc.cam.current = true
			sc.s.warp_to(pts[i])
	elif etape == 0 and attente == 90:
		sc._cli["near_ville"] = 0.5
		etape = 1
		attente = 0
	elif etape == 1 and attente == 3:
		img_a = root.get_viewport().get_texture().get_image()
		sc._cli["near_ville"] = near_b
	elif etape == 1 and attente == 6:
		img_b = root.get_viewport().get_texture().get_image()
		sc._cli["near_ville"] = 0.5
	elif etape == 1 and attente == 9:
		var img_c := root.get_viewport().get_texture().get_image()
		_comparer(img_a, img_b, img_c)
		i += 1
		etape = 0
		attente = 0
	return false


## a, c : plan proche 0,5 m (avant / après) ; b : 0,51 m. Un pixel compte s'il change avec le plan proche (a != b, c != b)
## mais pas entre a et c (sinon : animation, eau, fumée, personnage).
func _comparer(a: Image, b: Image, c: Image) -> void:
	var w := a.get_width()
	var h := a.get_height()
	var masque := Image.create(w, h, false, Image.FORMAT_RGB8) if masques != "" else null
	var nb := 0
	var total := 0
	var bx := [w, h, 0, 0]
	for y in range(int(h * 0.14), int(h * 0.95)):          # hors bandeau d'objectif et ligne d'aide
		for x in range(0, w):
			total += 1
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			var cc := c.get_pixel(x, y)
			var dd := absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
			var dc := absf(cc.r - cb.r) + absf(cc.g - cb.g) + absf(cc.b - cb.b)
			var anim := absf(ca.r - cc.r) + absf(ca.g - cc.g) + absf(ca.b - cc.b)
			if dd * 255.0 > SEUIL and dc * 255.0 > SEUIL and anim * 255.0 <= SEUIL:
				nb += 1
				bx = [mini(bx[0], x), mini(bx[1], y), maxi(bx[2], x), maxi(bx[3], y)]
				if masque != null:
					masque.set_pixel(x, y, Color(1, 0.2, 0.2))
			elif masque != null:
				masque.set_pixel(x, y, ca * 0.35)
	var pm := 1000.0 * nb / maxf(1.0, total)
	resultats.append(pm)
	var cam := root.get_viewport().get_camera_3d()
	var ct := cam.get_camera_transform()
	print("CAMERA %d %f %f %f %f %f %f %f %f %f %f %f %f %f %d %d %d" % [i, ct.origin.x, ct.origin.y, ct.origin.z,
		ct.basis.x.x, ct.basis.x.y, ct.basis.x.z, ct.basis.y.x, ct.basis.y.y, ct.basis.y.z, ct.basis.z.x, ct.basis.z.y, ct.basis.z.z,
		cam.fov, w, h, cam.keep_aspect])
	var pp: Vector3 = pts[i][1] if pts[i] is Array else pts[i]
	print("SCINTILLEMENT vue %d (%.1f, %.1f, %.2f) : %d px (%.3f ‰) cadre %s" % [i, pp.x, pp.z if pts[i] is Array else pp.y, pp.y if pts[i] is Array else pp.z, nb, pm, str(bx) if nb > 0 else "-"])
	if masque != null:
		masque.save_png("%s/masque_%02d.png" % [masques, i])
		a.save_png("%s/vue_%02d.png" % [masques, i])
