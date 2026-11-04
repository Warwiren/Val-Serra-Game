extends RefCounted
## Formules de combat — PROTOTYPE (GDD §31–§35).
## Toutes les constantes viennent de data/combat/rules.json : aucune valeur n'est canonique.
## Mêmes formules pour Chasseurs et monstres.


## Cycle de décision C = arrondi_sup(numérateur / Vitesse). Ex. : V=80 → 125, V=100 → 100, V=125 → 80.
static func cycle_length(rules: Dictionary, speed: int) -> int:
	var clock: Dictionary = rules["clock"]
	return ceili(float(clock["cycle_numerator"]) / float(clamp_speed(rules, speed)))


static func clamp_speed(rules: Dictionary, speed: int) -> int:
	var clock: Dictionary = rules["clock"]
	return clampi(speed, int(clock["speed_min"]), int(clock["speed_max"]))


## Caractéristique pondérée d'une arme (ex. sabre = 60 % DEX + 40 % FOR).
static func weighted_stat(stats: Dictionary, weights: Dictionary) -> float:
	var total := 0.0
	for key in weights:
		total += float(stats.get(key, 5)) * float(weights[key])
	return total


## Bonus de caractéristique : 1 + 0,04 × (valeur − 5).
static func stat_factor(rules: Dictionary, value: float) -> float:
	return 1.0 + float(rules["derived"]["stat_bonus_per_point"]) * (value - 5.0)


## Réduction par la défense : 100 / (100 + défense).
static func defense_factor(rules: Dictionary, defense: int) -> float:
	var k := float(rules["derived"]["defense_constant"])
	return k / (k + float(maxi(defense, 0)))


## Dégâts physiques (GDD §32). Jamais négatifs.
static func physical_damage(rules: Dictionary, attack: int, skill_mult: float, mode_mult: float,
		stat_value: float, anatomy_mult: float, defense: int) -> int:
	var raw := float(attack) * skill_mult * mode_mult * stat_factor(rules, stat_value) \
		* anatomy_mult * defense_factor(rules, defense)
	return maxi(0, roundi(raw))


## Dégâts de rupture sur une partie : puissance de rupture de l'arme, TEC = précision du ciblage.
static func break_damage(rules: Dictionary, break_power: int, skill_mult: float, mode_mult: float,
		tec: int, anatomy_mult: float) -> int:
	var raw := float(break_power) * skill_mult * mode_mult * stat_factor(rules, float(tec)) * anatomy_mult
	return maxi(0, roundi(raw))


## Dégâts de sérum : puissance propre, VOL, résistance élémentaire. N'utilise PAS la statistique d'arme.
static func serum_damage(rules: Dictionary, base_power: int, vol: int, element_mult: float, defense: int) -> int:
	var vol_factor := 1.0 + float(rules["derived"]["serum_bonus_per_vol"]) * float(vol - 5)
	var raw := float(base_power) * vol_factor * element_mult * defense_factor(rules, defense)
	return maxi(0, roundi(raw))
