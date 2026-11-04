extends RefCounted
## Partie ciblable d'un monstre. Pas de PV séparés : seulement une intégrité de rupture.
## Chaque coup sur une partie inflige AUSSI des dégâts aux PV globaux du monstre.

var id: String = ""
var name: String = ""
var max_integrity: int = 0
var integrity: int = 0
var affinities: Dictionary = {}     # type de dégâts -> multiplicateur anatomique
var break_effect: Dictionary = {}   # effet déclenché une seule fois à la rupture
var loot: String = ""               # composant obtenu si la partie est brisée
var broken: bool = false


func affinity(damage_type: String) -> float:
	return float(affinities.get(damage_type, 1.0))
