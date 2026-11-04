extends RefCounted
## Un acteur du combat (Chasseur ou monstre). État d'exécution uniquement : les définitions
## viennent des fichiers JSON de data/combat/.

const Formulas = preload("res://src/combat/core/formulas.gd")

const TEAM_HUNTERS := "hunters"
const TEAM_MONSTERS := "monsters"

var id: String = ""
var name: String = ""
var team: String = TEAM_HUNTERS
var index: int = 0                  # ordre de mise en place (départage final des égalités)
var is_boss: bool = false

# Caractéristiques et dérivés
var stats: Dictionary = {}          # FOR, DEX, CON, TEC, VOL
var max_hp: int = 1
var hp: int = 1
var defense: int = 0
var defense_mult: float = 1.0       # modifié par la rupture d'une carapace, etc.
var base_speed: int = 100
var speed_mod: int = 0              # bonus/malus temporaires de Vitesse
var resonance: int = 0

# Arme (Chasseurs) ou attaque naturelle (monstres)
var weapon_name: String = ""
var attack: int = 0
var break_power: int = 0
var damage_type: String = "impact"
var stat_weights: Dictionary = {}

# Chronologie
var cycle_start: int = 0            # début du cycle en cours
var next_ready: int = 0             # prochaine décision
var pending_cast = null             # Cast en préparation (une seule à la fois)
var window_shift: float = 0.0       # avance/recul cumulé depuis la dernière décision (fraction de C)
var delays_received: int = 0        # nombre de reculs subis (résistance croissante des boss)
var guard_active: bool = false
var decisions: int = 0

# Chasseurs
var action_ids: Array = []

# Monstres
var parts: Array = []               # MonsterPart
var monster_actions: Dictionary = {}
var ai: Dictionary = {}
var ai_step: int = 0
var action_power_mult: Dictionary = {}   # action_id -> multiplicateur (partie brisée)
var disabled_actions: Dictionary = {}    # action_id -> true
var resistances: Dictionary = {}


func is_alive() -> bool:
	return hp > 0


func is_hunter() -> bool:
	return team == TEAM_HUNTERS


func speed(rules: Dictionary) -> int:
	return Formulas.clamp_speed(rules, base_speed + speed_mod)


func cycle(rules: Dictionary) -> int:
	return Formulas.cycle_length(rules, base_speed + speed_mod)


func effective_defense() -> int:
	return roundi(float(defense) * defense_mult)


func weapon_stat() -> float:
	return Formulas.weighted_stat(stats, stat_weights)


func get_part(part_id: String):
	for p in parts:
		if p.id == part_id:
			return p
	return null


func gain_resonance(amount: int, cap: int) -> int:
	var before := resonance
	resonance = clampi(resonance + amount, 0, cap)
	return resonance - before
