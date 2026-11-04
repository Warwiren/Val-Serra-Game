extends "res://tests/test_case.gd"
## Fiches de squelette du prototype artistique : chaque calque existe, chaque os a un parent valide,
## chaque animation ne vise que des os existants. À relancer à chaque nouvel asset livré.

func _json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	check(f != null, "fichier présent : %s" % path)
	return JSON.parse_string(f.get_as_text()) if f != null else {}


func _check_rig(rig: Dictionary, layers_key: String, label: String) -> Dictionary:
	var names := {}
	for b in rig["bones"]:
		var parent: String = b["parent"]
		check(parent == "" or names.has(parent), "%s : l'os %s a un parent déclaré avant lui" % [label, b["name"]])
		names[b["name"]] = true
	for layer in rig[layers_key]:
		check(names.has(layer["bone"]), "%s : le calque %s est attaché à un os existant" % [label, layer["file"]])
		check(FileAccess.file_exists("%s/%s.svg" % [rig["art_dir"], layer["file"]]), "%s : fichier du calque %s" % [label, layer["file"]])
		if layer.has("broken"):
			check(FileAccess.file_exists("%s/%s.svg" % [rig["art_dir"], layer["broken"]]), "%s : état brisé %s" % [label, layer["broken"]])
	return names


func test_hero_rig_is_consistent() -> void:
	var rig := _json("res://data/rig/hero_hd.json")
	var names := _check_rig(rig, "parts", "Chasseur HD")
	check(names.has("weapon") and names.has("hip"), "os indispensables (hip, weapon)")
	var anims := _json("res://data/rig/anim_sword.json")
	for anim_name in ["idle", "strike", "guard", "hurt", "cast", "ko", "walk"]:
		check(anims.has(anim_name), "animation %s présente" % anim_name)
	for anim_name in anims:
		if String(anim_name).begins_with("_"):
			continue
		var a: Dictionary = anims[anim_name]
		for track in a["tracks"]:
			check(names.has(track) or track in ["hip_x", "hip_y"], "%s : piste %s vise un os existant" % [anim_name, track])
			var last := -1.0
			for k in a["tracks"][track]:
				check(float(k[0]) >= last and float(k[0]) <= float(a["length"]) + 0.001, "%s/%s : clés ordonnées dans la durée" % [anim_name, track])
				last = float(k[0])
	check(float(anims["strike"]["impact"]) < float(anims["strike"]["length"]), "instant d'impact dans la frappe")


func test_monster_rig_is_consistent() -> void:
	var rig := _json("res://data/rig/vorgane_hd.json")
	_check_rig(rig, "layers", "Vorgane HD")
	var parts := {}
	for layer in rig["layers"]:
		if layer.has("part"):
			parts[layer["part"]] = true
	for pid in ["griffe", "carapace", "glande"]:
		check(parts.has(pid), "partie ciblable %s dessinée" % pid)
		check(rig["anchors"].has(pid), "point de ciblage de %s" % pid)
	var shards := 0
	for layer in rig["layers"]:
		if layer.get("shard", false):
			shards += 1
	check(shards >= 3, "la carapace se brise en plusieurs éclats (%d)" % shards)
