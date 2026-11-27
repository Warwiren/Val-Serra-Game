extends SceneTree
## P8.1-A3 — Contrôle des bannières et drapeaux de la ville (lecture seule, --headless suffit) : chaque bannière notée par
## la ville (ville_v07a.noter_banniere : Colisée, entrées à enseigne « bannière », quartier civique, château) est comparée
## aux baies du registre des façades (baie avec volets et encadrement, archi_p77) : aucune ne doit recouvrir une ouverture.
## Recense aussi les bannières qui se chevauchent (doublons).
## godot --headless --path . --script res://tools/p8/bannieres_p81a3.gd [-- --escamotage_a3=0]
## Sortie : « BANNIERES {"total", "devant_une_baie", "chevauchements"} » puis une ligne par bannière.

var sc
var n := 0


func _initialize() -> void:
	Engine.set_meta("registre_facades", true)
	change_scene_to_file("res://scenes/p7/ville_v07b.tscn")


func _process(_d: float) -> bool:
	n += 1
	if sc == null:
		if current_scene != null and current_scene.get("_ville") != null and current_scene._ville != null:
			sc = current_scene
		return false
	if n < 120:
		return false
	var v = sc._ville
	var a = v._tr().a
	var baies := []
	for it in (a.registre if a.registre != null else []):
		if it["quoi"] != "baie" or not it.has("p"):
			continue
		var pp: Vector3 = it["p"]
		var nn: Vector3 = it["n"]
		var t := Vector3(nn.z, 0.0, -nn.x)
		var ext := (float(it["u1"]) - float(it["u0"])) * 0.5
		var p0: Vector3 = pp - t * ext - nn * 0.1
		var p1: Vector3 = pp + t * ext + nn * 0.35
		var lo := Vector3(minf(p0.x, p1.x), float(it["v0"]), minf(p0.z, p1.z))
		var hi := Vector3(maxf(p0.x, p1.x), float(it["v1"]), maxf(p0.z, p1.z))
		baies.append({"id": "%s/%s %s (%.1f, %.1f)" % [it["bat"], it["face"], it.get("style", ""), pp.x, pp.z], "aabb": AABB(lo, hi - lo)})
	var devant := 0
	var chev := 0
	var lignes := []
	var bs: Array = v.bannieres
	for i in bs.size():
		var b: Dictionary = bs[i]
		var ab: AABB = b["aabb"]
		var gene := []
		for ba in baies:
			var inter: AABB = ab.intersection(ba["aabb"])
			if inter.size.x * inter.size.z > 0.0 or (inter.size.y > 0.05 and (inter.size.x > 0.05 or inter.size.z > 0.05)):
				if inter.size.y > 0.05 and maxf(inter.size.x, inter.size.z) > 0.05:
					gene.append(ba["id"])
		for j in range(i + 1, bs.size()):
			var inter2: AABB = ab.intersection(bs[j]["aabb"])
			if inter2.size.y > 0.05 and maxf(inter2.size.x, inter2.size.z) > 0.05:
				chev += 1
				lignes.append("CHEVAUCHEMENT %s / %s" % [b["id"], bs[j]["id"]])
		if not gene.is_empty():
			devant += 1
		lignes.append("BANNIERE %s (%.1f, %.1f, h %.1f-%.1f) : %s" % [b["id"], ab.get_center().x, ab.get_center().z, ab.position.y, ab.end.y,
			"devant " + ", ".join(gene) if not gene.is_empty() else "ok"])
	print("BANNIERES ", JSON.stringify({"total": bs.size(), "devant_une_baie": devant, "chevauchements": chev, "baies_registre": baies.size()}))
	for l in lignes:
		print(l)
	quit()
	return false
