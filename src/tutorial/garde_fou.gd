extends RefCounted
## P6.1 — GARDE-FOU DU TUTORIEL : le joueur ne peut pas perdre, quel que soit le nombre de tours ou d'actions.
## Aucune règle du CombatCore n'est modifiée : on ajuste seulement l'ATTAQUE du commandant (une donnée de l'acteur,
## comme un « coup retenu ») avant chaque décision du joueur. Garantie : même si le commandant résout N_COUPS
## attaques de puissance maximale sans aucune garde avant la décision suivante du joueur, la somme de ses dégâts
## reste STRICTEMENT inférieure aux PV actuels du héros. Le commandant agit au plus 2 fois entre deux décisions du
## héros (cycles 114 / 102) : N_COUPS = 3 garde une marge.

const Formulas = preload("res://src/combat/core/formulas.gd")
const N_COUPS := 3


## Renvoie l'attaque appliquée (et la pose sur le combattant). `base` : attaque des données.
static func borner(battle, hero_id: String, monster_id: String, base: int) -> int:
	var h = battle.get_combatant(hero_id)
	var m = battle.get_combatant(monster_id)
	if h == null or m == null:
		return base
	var p_max := 0.0
	for aid in m.monster_actions:
		p_max = maxf(p_max, float(m.monster_actions[aid].get("power", 1.0)))
	var a := base
	while a > 0 and N_COUPS * Formulas.physical_damage(battle.rules, a, p_max, 1.0, m.weapon_stat(), 1.0, h.effective_defense()) >= h.hp:
		a -= 1
	m.attack = a
	return a
