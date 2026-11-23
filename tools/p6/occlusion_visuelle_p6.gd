extends SceneTree
## P6.2 — occlusion VISUELLE d'Aren dans les pièces pilotes : un point est « caché » si le rayon de son buste (0,9 m)
## ou de sa tête (1,4 m) vers la caméra traverse un mur ou un meuble AFFICHÉ, à sa hauteur affichée (mur coupé :
## 0,5 m ; secteur masqué : absent). Les collisions, elles, ne changent pas.
##   godot --headless --path . --script res://tools/p6/occlusion_visuelle_p6.gd
const World25 = preload("res://src/explore25/world25.gd")
const Secteurs = preload("res://src/explore25/secteurs25.gd")
const PAS := 0.5
const PIECES := {"S1 vestiaires": Rect2(16, 46.5, 20, 8.5), "P12 passage": Rect2(24.5, 44.5, 3, 2), "S2 salle d'attente": Rect2(20, 37.5, 12, 7)}


func _initialize() -> void:
	for cfg in [["P6.1 (azimut 20°, sans secteurs)", 20.0, false, "echelle"], ["P6.2 A (azimut 0°, secteurs, échelle)", 0.0, true, "echelle"],
			["P6.2-B B (continu, murs d'intérieur de 6 m)", 0.0, true, "continu"]]:
		World25.yaw = deg_to_rad(cfg[1])
		World25.pitch = deg_to_rad(24.0)
		var w = World25.load_world("res://data/p6/colisee.json", "instance")
		var sc = Secteurs.new(w.adj["p6"]["secteurs"], cfg[3])
		var pivots := {}
		var solides: Array = []
		for o in w.adj["obstacles"]:
			var id: String = o["id"]
			if not (id.begins_with("cmur_") or id.begins_with("meuble_")):
				continue
			var q: Array = o["rect"]
			var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
			var so := {"id": id, "rect": r, "h": float(o["haut"]), "mur": id.begins_with("cmur_")}
			if so["mur"] and cfg[3] == "continu" and so["h"] > 1.5:
				for m in sc._membres_emprise(r, false):
					if sc.par_id.has(m) and sc.par_id[m]["fond"] == "sombre":
						so["h"] = 6.0                     # hauteur affichée des murs d'intérieur en mode B
			if so["mur"]:
				var pv := Node3D.new()
				var cp := Node3D.new()
				pv.add_child(cp)
				sc.declarer_mur(pv, cp, r, 0.0, so["h"])
				so["pivot"] = pv
			solides.append(so)
		var lignes: Array = []
		var tot := 0
		var cach := 0
		for nom in PIECES:
			var R: Rect2 = PIECES[nom]
			var n := 0
			var c := 0
			var x := R.position.x + PAS / 2.0
			while x < R.end.x:
				var y := R.position.y + PAS / 2.0
				while y < R.end.y:
					var p := Vector2(x, y)
					if not w.stand(p, 0.0).is_empty():
						n += 1
						if cfg[2]:
							sc.mettre_a_jour(p, true)
						if _cache(p, solides, sc, cfg[2]):
							c += 1
					y += PAS
				x += PAS
			lignes.append("%s %d/%d (%.0f %%)" % [nom, c, n, 100.0 * c / maxi(1, n)])
			tot += n
			cach += c
		print("OCCLUSION VISUELLE %s : %d/%d points (%.1f %%) · %s" % [cfg[0], cach, tot, 100.0 * cach / maxi(1, tot), " · ".join(PackedStringArray(lignes))])
		for so in solides:
			if so.has("pivot"):
				so["pivot"].free()
	World25.yaw = World25.YAW
	World25.pitch = World25.PITCH
	quit()


func _cache(p: Vector2, solides: Array, sc, secteurs: bool) -> bool:
	var dir: Vector3 = World25.cam_back()             # (x, h, y) dans le repère Godot
	for hh in [0.9, 1.4]:
		var o := Vector3(p.x, hh, p.y)
		for so in solides:
			var h: float = so["h"]
			if secteurs:
				if sc.mode == "echelle" or not so["mur"]:
					var membres: Array = sc._membres(so["rect"].get_center()) if so["mur"] else [sc._proche(so["rect"].get_center())]
					if sc.mode == "echelle" and not membres.any(func(m): return sc.est_visible(m)):
						continue
					if sc.mode != "echelle" and not so["mur"] and sc._devant(membres) and not membres.any(func(m): return sc.est_visible(m)):
						continue
				if so["mur"] and (so["pivot"] as Node3D).scale.y < 1.0:
					h = Secteurs.LIP
			if _touche(o, dir, so["rect"].grow(0.02), h):
				return true
	return false


## Rayon o + t·d (t > 0.35 : on quitte le personnage) contre la boîte rect × [0, h].
func _touche(o: Vector3, d: Vector3, r: Rect2, h: float) -> bool:
	var tmin := 0.35
	var tmax := 80.0
	for ax in [[o.x, d.x, r.position.x, r.end.x], [o.z, d.z, r.position.y, r.end.y], [o.y, d.y, 0.0, h]]:
		if absf(ax[1]) < 1e-6:
			if ax[0] < ax[2] or ax[0] > ax[3]:
				return false
			continue
		var t1: float = (ax[2] - ax[0]) / ax[1]
		var t2: float = (ax[3] - ax[0]) / ax[1]
		tmin = maxf(tmin, minf(t1, t2))
		tmax = minf(tmax, maxf(t1, t2))
		if tmin > tmax:
			return false
	return true
