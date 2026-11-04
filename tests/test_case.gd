extends RefCounted
## Base minimale des tests (pas d'extension externe nécessaire).

const BattleFactory = preload("res://src/combat/battle_factory.gd")
const Battle = preload("res://src/combat/core/battle.gd")

var failures: Array = []
var checks: int = 0
var current_test: String = ""


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)


func check_eq(actual, expected, msg: String) -> void:
	checks += 1
	if typeof(actual) != typeof(expected) and not (_is_num(actual) and _is_num(expected)):
		failures.append("%s (attendu %s, obtenu %s)" % [msg, str(expected), str(actual)])
	elif actual != expected:
		failures.append("%s (attendu %s, obtenu %s)" % [msg, str(expected), str(actual)])


func _is_num(v) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT


# --- Aides communes -----------------------------------------------------------

## Combat par défaut, non démarré, horloge à 0.
func new_battle(inventory := {"potion": 2}) -> Battle:
	return BattleFactory.create_default(inventory)


## Combat « figé » : tous les acteurs prêts très tard, pour composer une situation précise à la main.
func frozen_battle() -> Battle:
	var b := new_battle()
	for c in b.combatants:
		c.cycle_start = 0
		c.next_ready = 1000
	return b


func hero(b: Battle):
	return b.get_combatant("heros")


func monster(b: Battle):
	return b.get_combatant("vorgane")
