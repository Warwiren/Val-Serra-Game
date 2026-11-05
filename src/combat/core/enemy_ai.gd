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
		var t = pick_target(battle, monster)
		if t != null:
			cmd["target"] = t.id
			monster.last_target = t.id
	return cmd


## Poids de la politique de ciblage (prototype, à équilibrer par tests — non canonique).
const W_VULN := 1.2        # vulnérabilité : part de PV perdus
const W_THREAT := 0.6      # menace : attaque relative du Chasseur (le plus dangereux attire l'attention)
const W_GUARD := -0.6      # un Chasseur en garde est une cible moins intéressante
const W_REPEAT := -0.35    # varier sans l'interdire : léger malus pour la cible précédente
const JITTER := 0.5        # part aléatoire contrôlée (0 .. JITTER), reproductible
## Point d'entrée pour une future provocation / protection : bonus de score par Chasseur (id -> bonus)
static var score_bonus: Dictionary = {}


## Ciblage pondéré, explicable et reproductible : score par Chasseur VIVANT, la meilleure note est choisie.
## Le hasard dépend seulement de (graine, temps, pas d'IA, Chasseur) : même état -> même choix.
static func scores(battle, monster) -> Dictionary:
	var alive: Array = battle.hunters(true)
	var max_atk := 1
	for h in alive:
		max_atk = maxi(max_atk, h.attack)
	var out := {}
	for h in alive:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([battle.ai_seed, battle.now, monster.ai_step, h.id])
		var s := 1.0
		s += W_VULN * (1.0 - float(h.hp) / float(h.max_hp))
		s += W_THREAT * float(h.attack) / float(max_atk)
		if h.guard_active:
			s += W_GUARD
		if h.id == monster.last_target:
			s += W_REPEAT
		s += float(score_bonus.get(h.id, 0.0))
		s += rng.randf() * JITTER
		out[h.id] = s
	return out


static func pick_target(battle, monster = null):
	if monster == null:
		for m in battle.combatants:
			if not m.is_hunter():
				monster = m
				break
	var sc := scores(battle, monster)
	var best = null
	for h in battle.hunters(true):          # ordre de mise en place = départage stable
		if best == null or sc[h.id] > sc[best.id]:
			best = h
	return best
