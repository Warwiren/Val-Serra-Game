extends "res://tests/test_case.gd"
## Lot P1 (addendum 10.5) : politique de ciblage du Vorgane et unicité des portraits.

const AutoPolicy = preload("res://src/combat/auto_policy.gd")
const Portraits = preload("res://src/proto/portraits.gd")


func _monster_targets(b) -> Array:
	var out: Array = []
	for e in b.journal:
		var d: Dictionary = e["data"]
		if e["type"] == "cast" and d.get("actor", "") == "vorgane" and d.get("target", "") != "":
			out.append(d["target"])
	return out


func _play(seed: int):
	var b := new_battle()
	b.ai_seed = seed
	AutoPolicy.play(b)
	return b


func test_enemy_target_is_always_a_living_hunter() -> void:
	for seed in range(4):
		var b := new_battle()
		b.ai_seed = seed
		var guard := 0
		while b.state != Battle.State.VICTORY and b.state != Battle.State.DEFEAT and guard < 400:
			guard += 1
			if b.state == Battle.State.AWAITING_COMMAND:
				b.submit(AutoPolicy.choose(b))
			else:
				b.advance()
			var m = b.get_combatant("vorgane")
			if m.pending_cast != null and m.pending_cast.target_id != "":
				var t = b.get_combatant(m.pending_cast.target_id)
				check(t != null and t.is_hunter() and t.is_alive(), "graine %d : cible annoncée vivante (%s)" % [seed, m.pending_cast.target_id])


func test_enemy_target_choice_is_reproducible_with_seed() -> void:
	check_eq(_monster_targets(_play(7)), _monster_targets(_play(7)), "même graine -> mêmes cibles")


func test_enemy_targets_vary_across_scenarios() -> void:
	var distinct := {}
	var battles_with_variety := 0
	for seed in range(6):
		var ts := _monster_targets(_play(seed))
		var local := {}
		for t in ts:
			distinct[t] = true
			local[t] = true
		if local.size() >= 2:
			battles_with_variety += 1
	check(distinct.size() >= 2, "au moins deux Chasseurs différents visés sur 6 scénarios (%s)" % [distinct.keys()])
	check(battles_with_variety >= 3, "la cible varie au sein d'un même combat dans au moins 3 scénarios sur 6 (%d)" % battles_with_variety)


func test_announced_target_is_the_resolved_target() -> void:
	for seed in range(4):
		var b = _play(seed)
		var announced := ""
		for e in b.journal:
			var d: Dictionary = e["data"]
			if e["type"] == "cast" and d.get("actor", "") == "vorgane":
				announced = d.get("target", "")
			elif e["type"] == "retarget":
				announced = d.get("target", "")
			elif announced != "" and d.get("actor", "") == "vorgane" and (e["type"] == "damage" or e["type"] == "guard_block"):
				check_eq(d.get("target", d.get("actor", "")) if e["type"] == "damage" else d.get("target", announced), announced, "graine %d : dégâts sur la cible annoncée" % seed)
				announced = ""


func test_portraits_come_from_one_source() -> void:
	for id in ["heros", "compagnon_vif", "compagnon_lourd", "pnj"]:
		var p := Portraits.path(id)
		check(p != "" and ResourceLoader.exists(p), "%s : portrait unique présent (%s)" % [id, p])
	# Aucun autre script du parcours normal ne référence un fichier de portrait directement
	for f in ["res://scenes/battle/battle_scene.gd", "res://scenes/proto/proto_zone.gd", "res://src/proto/dialogue_box.gd",
			"res://src/presentation/combat_hud.gd", "res://data/dialogue/pnj_proto.json"]:
		var src := FileAccess.open(f, FileAccess.READ).get_as_text()
		var re := RegEx.new()
		re.compile("res://art/[^\"]*portrait")
		check(re.search(src) == null, "%s : pas de chemin de portrait codé en dur" % f.get_file())
