extends SceneTree
## P8.1-A2 — Contrôle de cohérence des façades et des accès de la ville (lecture seule, --headless suffit).
## Lit le registre des façades construites par la bibliothèque archi_p77 (tranche P7.6, fiches P8.1-A) et vérifie :
##   1. conflits dans le plan de chaque face : baie (encadrement, volets, appui, linteau, arc) contre bandeau, corniche,
##      consoles, chaîne d'angle ou une autre baie ;
##   2. baies omises parce qu'elles tombaient dans un volume voisin (façade mitoyenne) ;
##   3. portes (entrées des données ET baies-portes des rez-de-chaussée) : écart seuil / sol devant la porte (rayon vers
##      le bas, 0,8 m devant), soubassement traversant l'ouverture, obstacle des données dans le passage (1,2 m devant).
## godot --headless --path . --script res://tools/p8/coherence_facades_p81a2.gd [-- --f_coherence=0]
## Résultat : « COHERENCE {conflits, mitoyennes_omises, portes_hors_sol, soubassements_traversants, obstacles_devant} »
## puis le détail (lignes « CONFLIT », « PORTE »).

var sc
var n := 0


func _initialize() -> void:
	Engine.set_meta("registre_facades", true)               # lu par ville_v07b._tr() avant la construction
	change_scene_to_file("res://scenes/p7/ville_v07b.tscn")


func _process(_d: float) -> bool:
	n += 1
	if sc == null:
		if current_scene != null and current_scene.get("_ville") != null and current_scene._ville != null:
			sc = current_scene
		return false
	if n < 120:
		return false
	var reg: Array = sc._ville._tr().a.registre if sc._ville._tr().a.registre != null else []
	var par_face := {}
	for it in reg:
		var k := "%s|%s" % [it["bat"], it["face"]]
		if not par_face.has(k):
			par_face[k] = []
		par_face[k].append(it)
	var conflits := []
	var omises := 0
	for k in par_face:
		var items: Array = par_face[k]
		for i in items.size():
			var a: Dictionary = items[i]
			if a["quoi"] == "baie_mitoyenne_omise":
				omises += 1
				continue
			if a["quoi"] != "baie":
				continue
			for j in items.size():
				if j == i:
					continue
				var b: Dictionary = items[j]
				if b["quoi"] in ["soubassement", "baie_mitoyenne_omise"] or (b["quoi"] == "baie" and j < i):
					continue
				var du := minf(a["u1"], b["u1"]) - maxf(a["u0"], b["u0"])
				var dv := minf(a["v1"], b["v1"]) - maxf(a["v0"], b["v0"])
				if du > 0.02 and dv > 0.02:
					conflits.append("%s : baie %s (u %.2f) / %s (%.2f x %.2f m)" % [k, a.get("style", "?"), (a["u0"] + a["u1"]) * 0.5, b["quoi"], du, dv])
	# portes
	var portes := []
	for e in sc._ville.v.get("entrees", []):
		if sc._ville._tr().a.coherence and str(e["type"]) != "fonctionnelle" and sc._ville._entree_obstruee(e):
			continue                                          # porte décorative obstruée : non dessinée (P8.1-A2)
		portes.append({"id": str(e["id"]), "p": Vector3(float(e["x"]), float(e["h"]), float(e["y"])), "n": Vector3(0, 0, 1), "l": float(e["largeur"]), "bat": str(e["batiment"])})
	for it in reg:
		if it["quoi"] == "baie" and str(it.get("style", "")) in sc._ville._tr().a.STYLES_PORTE_SOL and it.has("p") and int(it.get("niveau", 0)) == 0:
			var p: Vector3 = it["p"]
			portes.append({"id": "%s/%s %s u%.1f" % [it["bat"], it["face"], it["style"], (it["u0"] + it["u1"]) * 0.5], "p": p, "n": it["n"], "l": float(it["largeur"]), "bat": str(it["bat"])})
	var hors_sol := 0
	var traversants := 0
	var devant := 0
	var lignes := []
	var espace: PhysicsDirectSpaceState3D = sc.get_world_3d().direct_space_state
	for pt in portes:
		var p: Vector3 = pt["p"]
		var nn: Vector3 = pt["n"]
		var q := PhysicsRayQueryParameters3D.create(p + nn * 0.8 + Vector3.UP * 2.0, p + nn * 0.8 + Vector3.DOWN * 3.0)
		var r := espace.intersect_ray(q)
		var sol: float = r["position"].y if not r.is_empty() else -99.0
		var ecart := p.y - sol
		var defauts := []
		if absf(ecart) > 0.12:
			hors_sol += 1
			defauts.append("seuil %+.2f m / sol" % ecart)
		var bloque := _obstacle_devant(p, nn, float(pt["l"]), pt["bat"])
		if bloque != "":
			devant += 1
			defauts.append("obstacle devant : " + bloque)
		if not defauts.is_empty():
			lignes.append("PORTE %s (%.1f, %.1f, h %.2f) : %s" % [pt["id"], p.x, p.z, p.y, ", ".join(defauts)])
	traversants = _soubassements_traversants(reg, portes)
	print("COHERENCE ", JSON.stringify({"faces": par_face.size(), "conflits": conflits.size(), "mitoyennes_omises": omises,
		"portes": portes.size(), "portes_hors_sol": hors_sol, "soubassements_traversants": traversants, "obstacles_devant": devant}))
	for c in conflits:
		print("CONFLIT ", c)
	for l in lignes:
		print(l)
	quit()
	return false


## Soubassement d'un bâtiment dont un segment couvre l'abscisse d'une porte posée sur la même face.
func _soubassements_traversants(reg: Array, portes: Array) -> int:
	var nb := 0
	for pt in portes:
		var p: Vector3 = pt["p"]
		for o in sc.world.adj.get("obstacles", []):
			if str(o["id"]) != pt["bat"]:
				continue
			var q: Array = o["rect"]
			var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
			for cote in ["s", "e", "o", "n"]:
				var f: Dictionary = sc._ville._tr().a.face(r, cote)
				if absf((p - Vector3(f["o"].x, p.y, f["o"].z)).dot(f["n"])) > 0.7:
					continue
				var u := (p - Vector3(f["o"].x, p.y, f["o"].z)).dot(f["t"])
				for it in reg:
					if it["quoi"] == "soubassement" and str(it["bat"]) == pt["bat"] and it["face"] == cote and it["u0"] < u and it["u1"] > u:
						nb += 1
						print("TRAVERSANT %s : soubassement devant la porte (%s, u %.2f)" % [pt["id"], cote, u])
	return nb


## Obstacle des données (hors piédroits d'entrée et bâtiment de la porte) dans le passage : 1,2 m devant la porte.
func _obstacle_devant(p: Vector3, nn: Vector3, l: float, bat: String) -> String:
	var t := Vector3(nn.z, 0, -nn.x)
	var c := p + nn * 0.7
	var zone := Rect2(Vector2(c.x, c.z) - Vector2(absf(t.x) * (l * 0.5 + 0.1) + absf(nn.x) * 0.55, absf(t.z) * (l * 0.5 + 0.1) + absf(nn.z) * 0.55),
		Vector2(absf(t.x) * (l + 0.2) + absf(nn.x) * 1.1, absf(t.z) * (l + 0.2) + absf(nn.z) * 1.1))
	for o in sc.world.adj.get("obstacles", []):
		var oid := str(o["id"])
		if oid == bat or oid.begins_with("decor_entree"):
			continue
		var q: Array = o["rect"]
		var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
		if r.intersects(zone) and float(o["h"]) < p.y + 1.5 and float(o["h"]) + float(o["haut"]) > p.y + 0.05:
			return oid
	return ""
