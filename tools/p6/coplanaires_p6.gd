extends SceneTree
## P6.3.2 — recherche des surfaces coplanaires ou presque superposées (cause classique de clignotement « z-fighting ») :
## paires de boîtes (BoxMesh) dont une face horizontale ou verticale coïncide à moins de 3 mm, avec recouvrement.
##   godot --headless --path . --script res://tools/p6/coplanaires_p6.gd [-- --etat=tutorial_completed]
var z
var n := 0
const TOL := 0.003


func _initialize() -> void:
	change_scene_to_file("res://scenes/p6/colisee.tscn")


func _famille(nom: String) -> String:
	var p := nom.split("/")[0]
	for pre in ["cmur_", "linteau_", "piedroit_", "Secteurs_MUR", "Secteurs_SOL", "Secteurs_EXTERIEUR", "Secteurs_EXT", "Secteurs_S", "tranche"]:
		if p.begins_with(pre):
			return pre
	return p


func _process(_d: float) -> bool:
	n += 1
	if z == null:
		if n > 5 and current_scene != null and current_scene.get("world") != null:
			z = current_scene
			n = 0
		return false
	if n < 5:
		return false
	var boites: Array = []
	var pile: Array = [z.root]
	while not pile.is_empty():
		var c = pile.pop_back()
		for k in c.get_children():
			pile.append(k)
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is BoxMesh:
			var mi := c as MeshInstance3D
			if mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
				continue
			var a: AABB = mi.global_transform * mi.get_aabb()
			var rot := not mi.global_transform.basis.is_equal_approx(Basis().scaled(mi.global_transform.basis.get_scale()))
			boites.append({"a": a, "nom": str(mi.get_parent().name) + "/" + str(mi.name), "rot": rot})
	var paires := 0
	var par_cat := {}
	var par_fam := {}
	var ex_murs: Array = []
	var exemples: Array = []
	for i in boites.size():
		var A: AABB = boites[i]["a"]
		for j in range(i + 1, boites.size()):
			var B: AABB = boites[j]["a"]
			if not A.grow(0.01).intersects(B):
				continue
			var inter := A.intersection(B.grow(0.002))
			var cat := ""
			# seules les faces de MÊME orientation dans le même plan, qui se recouvrent, scintillent (z-fighting) ;
			# deux boîtes bout à bout (faces opposées) ou les dessous ne comptent pas
			if absf(A.end.y - B.end.y) < TOL and inter.size.x > 0.02 and inter.size.z > 0.02:
				cat = "dessus"
			for pair in [[A.position.x, B.position.x], [A.end.x, B.end.x]]:
				if absf(pair[0] - pair[1]) < TOL and inter.size.y > 0.02 and inter.size.z > 0.02:
					cat = "face x"
			for pair in [[A.position.z, B.position.z], [A.end.z, B.end.z]]:
				if absf(pair[0] - pair[1]) < TOL and inter.size.y > 0.02 and inter.size.x > 0.02:
					cat = "face z"
			if cat != "" and (boites[i]["rot"] or boites[j]["rot"]):
				cat = ""                                  # boîte pivotée : sa boîte englobante n'est pas sa géométrie
			if cat != "":
				var ka := _famille(boites[i]["nom"])
				var kb := _famille(boites[j]["nom"])
				var fam := "%s + %s" % ([ka, kb] if ka <= kb else [kb, ka])
				par_fam[fam] = par_fam.get(fam, 0) + 1
				if fam == "cmur_ + cmur_":
					var meme: bool = str(boites[i]["nom"]).split("/")[0] == str(boites[j]["nom"]).split("/")[0]
					var A2: AABB = boites[i]["a"]
					var B2: AABB = boites[j]["a"]
					var cle := "%s | %s | tailles %s / %s" % ["même mur" if meme else "deux murs", cat, str(Vector3(snappedf(A2.size.x, 0.01), snappedf(A2.size.y, 0.01), snappedf(A2.size.z, 0.01))), str(Vector3(snappedf(B2.size.x, 0.01), snappedf(B2.size.y, 0.01), snappedf(B2.size.z, 0.01)))]
					if ex_murs.size() < 16:
						ex_murs.append(cle + "  " + str(boites[i]["nom"]) + " <-> " + str(boites[j]["nom"]))
					par_cat["murs " + ("même" if meme else "deux")] = par_cat.get("murs " + ("même" if meme else "deux"), 0) + 1
				paires += 1
				par_cat[cat] = par_cat.get(cat, 0) + 1
				if exemples.size() < 25:
					exemples.append("%s : %s  <->  %s  (%.2f, %.2f, %.2f)" % [cat, boites[i]["nom"], boites[j]["nom"], inter.get_center().x, inter.get_center().y, inter.get_center().z])
	print("COPLANAIRES : %d boîtes, %d paires à faces de même orientation confondues (< %d mm) %s" % [boites.size(), paires, int(TOL * 1000), str(par_cat)])
	var fams := par_fam.keys()
	fams.sort_custom(func(x, y): return par_fam[x] > par_fam[y])
	for f in fams.slice(0, 15):
		print("  %4d  %s" % [par_fam[f], f])
	for e in ex_murs:
		print("    " + e)
	quit()
	return false
