extends RefCounted
## Action en préparation : décidée au temps `decided_at`, produit son effet au temps `resolve_at`.

var seq: int = 0                 # ordre de création (départage stable des égalités)
var actor_id: String = ""
var action_id: String = ""
var action_name: String = ""
var mode: String = ""            # "", "VIF", "MESURE" ou "CHARGE"
var target_id: String = ""
var part_id: String = ""
var decided_at: int = 0
var resolve_at: int = 0
var telegraph: bool = false      # attaque annoncée (affichée en évidence)
var interruptible: bool = false
