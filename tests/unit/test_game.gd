extends "res://tests/test_case.gd"
## État de partie : accords grammaticaux du héros, récompenses, dialogue bien formé.

const GameStateScript = preload("res://src/game/game_state.gd")


func _state(gender: String, hero_name: String):
	var gs = GameStateScript.new()
	gs.new_game(gender, hero_name)
	return gs


func test_grammar_variants_follow_hero_gender() -> void:
	var m = _state("m", "Aren")
	var f = _state("f", "Ilya")
	var line := "Vous êtes {nom}, {m:le nouveau Chasseur|f:la nouvelle Chasseuse}, {m:prêt|f:prête} ?"
	check_eq(m.g(line), "Vous êtes Aren, le nouveau Chasseur, prêt ?", "accords au masculin")
	check_eq(f.g(line), "Vous êtes Ilya, la nouvelle Chasseuse, prête ?", "accords au féminin")
	check_eq(m.g("{m:entier|f:entière}"), "entier", "variante seule")
	check_eq(f.g("Sans variante."), "Sans variante.", "texte sans balise inchangé")
	m.free()
	f.free()


func test_default_names_when_empty() -> void:
	var m = _state("m", "  ")
	var f = _state("f", "")
	check_eq(m.hero_name, "Aren", "nom par défaut masculin")
	check_eq(f.hero_name, "Ilya", "nom par défaut féminin")
	m.free()
	f.free()


func test_rewards_are_added_to_inventory() -> void:
	var gs = _state("m", "Aren")
	gs.add_rewards({"currency": 60, "items": {"cuir_vorgane": 1, "glande_aether": 1}})
	gs.add_rewards({"currency": 10, "items": {"cuir_vorgane": 2}})
	check_eq(gs.currency, 70, "monnaie cumulée")
	check_eq(int(gs.materials["cuir_vorgane"]), 3, "matériaux cumulés")
	check_eq(int(gs.materials["glande_aether"]), 1, "matériau de partie")
	gs.free()


func test_dialogue_file_is_consistent() -> void:
	var f := FileAccess.open("res://data/dialogue/intendante.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	var nodes: Dictionary = data["nodes"]
	for start in ["intro", "reminder", "after_defeat", "after_victory"]:
		check(nodes.has(start), "nœud de départ %s présent" % start)
	for id in nodes:
		var n: Dictionary = nodes[id]
		check(n.has("text") and n.has("speaker"), "%s : texte et locuteur" % id)
		if n.has("next"):
			check(nodes.has(n["next"]), "%s : suite %s existe" % [id, n["next"]])
		for c in n.get("choices", []):
			check(nodes.has(c["next"]), "%s : choix vers %s existe" % [id, c["next"]])
