extends SceneTree
## P6.2 — mesure de la circulation au clavier (modèle logique World25 : mêmes surfaces, solides et glissement que le jeu).
## Pour chaque tronçon du parcours principal et chaque azimut de caméra, on maintient UNE touche (8 directions,
## comme au clavier) et on mesure : arrivée, durée, part du trajet en contact avec un mur (glissement), écart latéral,
## et le nombre d'« épisodes de contact » (moments où un joueur corrigerait avec une seconde touche).
##   godot --headless --path . --script res://tools/p6/circulation_p6.gd [-- --zone=res://data/p6/colisee.json]
const World25 = preload("res://src/explore25/world25.gd")
const DT := 1.0 / 60.0
const V := 2.2
## [nom, départ (x, y), touche écran (x, y), fin : ["y<", v] ou ["x>", v]]
const TRONCONS := [
	["Vestiaires → salle d'attente", Vector2(26.0, 51.5), Vector2(0, -1), ["y<", 44.4]],
	["Salle d'attente → tunnel → arène", Vector2(26.0, 43.8), Vector2(0, -1), ["y<", 31.0]],
	["Arène (commandant) → grille est", Vector2(26.0, 23.3), Vector2(1, 0), ["x>", 38.6]],
	["Tunnel est → coursive → sortie", Vector2(38.6, 23.0), Vector2(1, 0), ["x>", 63.6]],
]
const DECALAGES := [-0.7, 0.0, 0.7]


func _initialize() -> void:
	var zone := "res://data/p6/colisee.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--zone="):
			zone = a.substr(7)
	var res := {}
	for yaw_deg in [20.0, 0.0]:
		World25.yaw = deg_to_rad(yaw_deg)
		var w = World25.load_world(zone, "instance")
		for p in w.adj["p6"].get("portes", []):
			if p.has("ouverte_a_partir_de") or p.get("marque", "") != "fermee":
				continue
			var q: Array = p["rect"]
			w.solids.append({"id": p["id"], "kind": "rect", "rect": Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]), "h0": 0.0, "h1": 2.6})
		for t in TRONCONS:
			for dec in DECALAGES:
				var start: Vector2 = t[1] + (Vector2(dec, 0) if t[2].y != 0 else Vector2(0, dec))
				var r := _simule(w, start, t[2], t[3])
				var k := "%s|%d" % [t[0], int(yaw_deg)]
				if not res.has(k):
					res[k] = []
				res[k].append(r)
	World25.yaw = World25.YAW
	print("P6.2 CIRCULATION — une seule touche maintenue, départs décalés de -0,7 / 0 / +0,7 m")
	for t in TRONCONS:
		for yaw_deg in [20, 0]:
			var rs: Array = res["%s|%d" % [t[0], yaw_deg]]
			var ok := rs.filter(func(r): return r["ok"]).size()
			var contact := 0.0
			var episodes := 0
			var dev := 0.0
			var tps := 0.0
			for r in rs:
				contact += r["contact"]
				episodes += r["episodes"]
				dev = maxf(dev, r["ecart"])
				tps += r["t"]
			print("%-36s azimut %2d° : arrivée %d/3 · contact %3.0f %% · épisodes %d · écart latéral max %.2f m · durée moy. %.1f s" % [
				t[0], yaw_deg, ok, 100.0 * contact / rs.size(), episodes, dev, tps / rs.size()])
	quit()


func _simule(w, start: Vector2, key: Vector2, fin: Array) -> Dictionary:
	var p := start
	var h := 0.0
	var t := 0.0
	var bloque := 0
	var n := 0
	var episodes := 0
	var prev := false
	var ecart := 0.0
	var dir: Vector2 = World25.input_to_plan(key)
	while t < 40.0:
		var m: Dictionary = w.move(p, h, dir * V * DT)
		var b: bool = m["blocked"]
		if b and not prev:
			episodes += 1
		prev = b
		if b:
			bloque += 1
		n += 1
		p = m["p"]
		h = m["h"]
		t += DT
		ecart = maxf(ecart, absf((p - start).x if key.y != 0 else (p - start).y))
		var done: bool = p.y < fin[1] if fin[0] == "y<" else p.x > fin[1]
		if done:
			return {"ok": true, "t": t, "contact": float(bloque) / n, "episodes": episodes, "ecart": ecart}
		if (m["p"] - start).length() < 0.001 and t > 1.0:
			break
	return {"ok": false, "t": t, "contact": float(bloque) / maxi(1, n), "episodes": episodes, "ecart": ecart}
