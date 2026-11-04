extends RefCounted
## IA ennemie lisible et déterministe. Elle utilise EXACTEMENT le même planificateur que les Chasseurs :
## elle ne fait que choisir une commande quand le monstre est prêt.
## Elle renvoie toujours une action valide : aucune boucle possible.


static func choose(battle, monster) -> Dictionary:
	var pattern: Array = monster.ai.get("pattern", [])
	var fallback: String = monster.ai.get("fallback", "")
	var action_id: String = fallback
	if pattern.size() > 0:
		action_id = pattern[monster.ai_step % pattern.size()]
		monster.ai_step += 1
	if monster.disabled_actions.has(action_id) or not monster.monster_actions.has(action_id):
		action_id = fallback
	var cmd := {"action": action_id}
	if monster.monster_actions[action_id].get("target", "single") == "single":
		var t = pick_target(battle)
		if t != null:
			cmd["target"] = t.id
	return cmd


## Ciblage « PV les plus bas », départage par ordre de mise en place.
static func pick_target(battle):
	var best = null
	for h in battle.hunters(true):
		if best == null or h.hp < best.hp:
			best = h
	return best
