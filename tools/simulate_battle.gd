extends SceneTree
## Simule un combat complet avec une politique automatique et affiche le journal horodaté.
##   godot --headless --path . --script res://tools/simulate_battle.gd

const BattleFactory = preload("res://src/combat/battle_factory.gd")
const AutoPolicy = preload("res://src/combat/auto_policy.gd")


func _initialize() -> void:
	var b = BattleFactory.create_default()
	var turns := AutoPolicy.play(b)
	for e in b.journal:
		if e["type"] == "turn":
			continue
		print("[t=%4d] %s" % [e["t"], e["text"]])
	print("")
	print("Tours de Chasseurs joués : %d — durée : t=%d" % [turns, b.now])
	for c in b.combatants:
		print("  %-26s décisions : %2d   PV restants : %d/%d" % [c.name, c.decisions, c.hp, c.max_hp])
	quit()
