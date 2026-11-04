extends RefCounted
## CombatCore — simulation de combat DÉTERMINISTE, indépendante de tout affichage.
##
## Principe (GDD §31) : une seule horloge entière commune à tous les acteurs.
##  - Un acteur prêt au temps t choisit UNE action.
##  - L'effet se produit à t + windup × C (C = cycle de l'acteur).
##  - Sa décision suivante est TOUJOURS à t + C, quel que soit le mode : pas de double taxation.
##  - À temps égal : les effets (résolutions) passent avant les décisions ; entre décisions,
##    départage stable : Vitesse la plus haute, puis Chasseurs avant monstres, puis ordre de mise en place.
##
## Utilisation :
##   battle.advance()           -> avance jusqu'au prochain Chasseur à commander (ou fin du combat)
##   battle.preview_timeline()  -> chronologie prévisionnelle (avec une commande hypothétique)
##   battle.estimate(cmd)       -> aperçu chiffré avant confirmation
##   battle.submit(cmd)         -> exécute la commande du Chasseur courant puis avance
## Une commande est un Dictionary : { action, mode?, target?, part? }.

const Formulas = preload("res://src/combat/core/formulas.gd")
const Combatant = preload("res://src/combat/core/combatant.gd")
const Cast = preload("res://src/combat/core/cast.gd")
const EnemyAI = preload("res://src/combat/core/enemy_ai.gd")

enum State { RUNNING, AWAITING_COMMAND, VICTORY, DEFEAT, ABORTED }

const EV_RESOLVE := "resolve"
const EV_READY := "ready"

var rules: Dictionary = {}
var actions: Dictionary = {}        # définitions d'actions des Chasseurs
var combatants: Array = []          # Combatant, dans l'ordre de mise en place
var casts: Array = []               # Cast en attente de résolution
var inventory: Dictionary = {}      # objets consommables disponibles pendant le combat
var monster_rewards: Dictionary = {}
var loot: Dictionary = {}           # composants gagnés par ruptures
var rewards: Dictionary = {}        # rempli à la victoire

var now: int = 0
var state: int = State.RUNNING
var current_actor = null            # Chasseur qui doit choisir une action
var journal: Array = []             # [{t, type, text, data}] — journal horodaté, aussi source d'événements pour l'affichage
var abort_reason: String = ""

var _cast_seq: int = 0


# ---------------------------------------------------------------------------
# Accès
# ---------------------------------------------------------------------------

func get_combatant(id: String):
	for c in combatants:
		if c.id == id:
			return c
	return null


func hunters(alive_only := false) -> Array:
	return combatants.filter(func(c): return c.is_hunter() and (not alive_only or c.is_alive()))


func monsters(alive_only := false) -> Array:
	return combatants.filter(func(c): return not c.is_hunter() and (not alive_only or c.is_alive()))


func is_over() -> bool:
	return state == State.VICTORY or state == State.DEFEAT or state == State.ABORTED


# ---------------------------------------------------------------------------
# Boucle principale
# ---------------------------------------------------------------------------

## Démarre le combat : chaque acteur commence au début de son cycle (le plus rapide joue en premier).
func start() -> void:
	now = 0
	for c in combatants:
		c.cycle_start = 0
		c.next_ready = c.cycle(rules)
	_log("start", "Le combat commence.")
	advance()


## Traite les événements dans l'ordre jusqu'à ce qu'un Chasseur doive décider, ou jusqu'à la fin.
## Les monstres décident automatiquement via EnemyAI.
func advance() -> void:
	if is_over() or state == State.AWAITING_COMMAND:
		return
	var budget: int = int(rules["safety"]["max_events_per_advance"])
	while budget > 0:
		budget -= 1
		var events := _build_events(1)
		if events.is_empty():
			_abort("Aucun événement à traiter.")
			return
		var ev: Dictionary = events[0]
		now = ev["time"]
		if ev["kind"] == EV_RESOLVE:
			_resolve_cast(ev["cast"])
		else:
			var actor = ev["actor"]
			_on_ready(actor)
			if actor.is_hunter():
				current_actor = actor
				state = State.AWAITING_COMMAND
				_log("turn", "%s peut agir." % actor.name, {"actor": actor.id})
				return
			_commit(actor, EnemyAI.choose(self, actor))
		if _check_end():
			return
	_abort("Garde-fou : trop d'événements sans décision de joueur (boucle infinie ?).")


## Exécute la commande du Chasseur courant. Renvoie "" si acceptée, sinon le motif du refus.
func submit(cmd: Dictionary) -> String:
	if state != State.AWAITING_COMMAND or current_actor == null:
		return "Aucun Chasseur n'attend d'ordre."
	var err := validate(current_actor, cmd)
	if err != "":
		return err
	var actor = current_actor
	current_actor = null
	state = State.RUNNING
	_commit(actor, cmd)
	if not _check_end():
		advance()
	return ""


# ---------------------------------------------------------------------------
# Validation et aperçu
# ---------------------------------------------------------------------------

func validate(actor, cmd: Dictionary) -> String:
	var aid: String = cmd.get("action", "")
	if not actor.action_ids.has(aid) or not actions.has(aid):
		return "Action inconnue pour ce Chasseur."
	var def: Dictionary = actions[aid]
	var modes: Array = def.get("modes", [])
	var mode: String = cmd.get("mode", "")
	if modes.size() > 0 and not modes.has(mode):
		return "Choisissez un mode : %s." % ", ".join(PackedStringArray(modes))
	if modes.size() == 0 and mode != "":
		return "Cette action n'a pas de mode."
	var cost: int = int(def.get("resonance_cost", 0))
	if actor.resonance < cost:
		return "Résonance insuffisante (%d / %d)." % [actor.resonance, cost]
	if def.has("item") and int(inventory.get(def["item"], 0)) <= 0:
		return "Plus de %s." % def["name"]
	match def.get("target", "self"):
		"enemy_part":
			var target = get_combatant(cmd.get("target", ""))
			if target == null or target.is_hunter() or not target.is_alive():
				return "Cible invalide."
			if target.get_part(cmd.get("part", "")) == null:
				return "Choisissez une partie du monstre."
		"ally":
			var ally = get_combatant(cmd.get("target", ""))
			if ally == null or not ally.is_hunter() or not ally.is_alive():
				return "Allié invalide."
	return ""


## Chronologie prévisionnelle. Avec `hypo_cmd`, montre où se placerait l'effet de la commande du
## Chasseur courant AVANT confirmation. Les résolutions déjà prévues sont exactes ; les décisions
## futures sont projetées (marquées "projected").
func preview_timeline(count := 10, hypo_cmd := {}) -> Array:
	var hypo_actor = current_actor if (state == State.AWAITING_COMMAND and not hypo_cmd.is_empty()) else null
	var events := _build_events(4, hypo_actor, hypo_cmd)
	return events.slice(0, count)


## Aperçu chiffré d'une commande (hors garde adverse éventuelle).
func estimate(actor, cmd: Dictionary) -> Dictionary:
	var out := {"resolve_at": now, "next_decision": now + actor.cycle(rules), "damage": 0, "break": 0, "heal": 0, "delay": 0}
	if validate(actor, cmd) != "":
		out["error"] = validate(actor, cmd)
		return out
	var def: Dictionary = actions[cmd["action"]]
	out["resolve_at"] = now + roundi(_windup_factor(actor, cmd) * actor.cycle(rules))
	match def["kind"]:
		"strike":
			var rs := _strike_numbers(actor, cmd)
			out["damage"] = rs["damage"]
			out["break"] = rs["break"]
		"serum":
			var rz := _serum_numbers(actor, cmd)
			out["damage"] = rz["damage"]
			out["break"] = rz["break"]
			var target = get_combatant(cmd["target"])
			out["delay"] = roundi(float(def.get("delay_fraction", 0.0)) * target.cycle(rules))
		"item":
			out["heal"] = int(def.get("heal", 0))
	return out


# ---------------------------------------------------------------------------
# Chronologie (source unique pour la simulation ET l'aperçu)
# ---------------------------------------------------------------------------

func _build_events(projections: int, hypo_actor = null, hypo_cmd := {}) -> Array:
	var evs: Array = []
	for cast in casts:
		evs.append(_resolve_event(cast.resolve_at, cast.seq, cast, false))
	for c in combatants:
		if not c.is_alive():
			continue
		var C: int = c.cycle(rules)
		var first: int
		if c == hypo_actor:
			first = now + C
			var dt := roundi(_windup_factor(c, hypo_cmd) * C)
			if dt > 0:
				var fake := Cast.new()
				fake.seq = _cast_seq + 1
				fake.actor_id = c.id
				fake.action_id = hypo_cmd.get("action", "")
				fake.action_name = actions.get(fake.action_id, {}).get("name", fake.action_id)
				fake.mode = hypo_cmd.get("mode", "")
				fake.resolve_at = now + dt
				evs.append(_resolve_event(fake.resolve_at, fake.seq, fake, true))
		elif c == current_actor and state == State.AWAITING_COMMAND:
			first = now + C   # quelle que soit l'action choisie, la décision suivante est à t + C
		else:
			first = _effective_ready(c)
		for k in range(projections):
			var projected: bool = k > 0 or c == current_actor
			evs.append(_ready_event(first + k * C, c, projected))
	evs.sort_custom(_event_less)
	return evs


## Un acteur ne peut pas redevenir prêt avant la résolution de sa propre préparation.
func _effective_ready(c) -> int:
	var t: int = c.next_ready
	if c.pending_cast != null:
		t = maxi(t, c.pending_cast.resolve_at)
	return t


func _resolve_event(time: int, seq: int, cast, hypothetical: bool) -> Dictionary:
	return {"time": time, "kind": EV_RESOLVE, "cast": cast, "actor_id": cast.actor_id,
		"hypothetical": hypothetical, "projected": false, "key": [time, 0, seq, 0, 0]}


func _ready_event(time: int, c, projected: bool) -> Dictionary:
	var team_rank := 0 if c.is_hunter() else 1
	return {"time": time, "kind": EV_READY, "actor": c, "actor_id": c.id,
		"hypothetical": false, "projected": projected,
		"key": [time, 1, -c.speed(rules), team_rank, c.index]}


func _event_less(a: Dictionary, b: Dictionary) -> bool:
	var ka: Array = a["key"]
	var kb: Array = b["key"]
	for i in range(ka.size()):
		if ka[i] != kb[i]:
			return ka[i] < kb[i]
	return false


# ---------------------------------------------------------------------------
# Décisions
# ---------------------------------------------------------------------------

func _on_ready(actor) -> void:
	if actor.guard_active:
		actor.guard_active = false
		_log("guard_end", "La garde de %s retombe." % actor.name, {"actor": actor.id})


func _windup_factor(actor, cmd: Dictionary) -> float:
	var aid: String = cmd.get("action", "")
	if actor.is_hunter():
		var def: Dictionary = actions.get(aid, {})
		var mode: String = cmd.get("mode", "")
		if mode != "" and rules["modes"].has(mode):
			return float(rules["modes"][mode]["windup"])
		return float(def.get("windup", 0.0))
	return float(actor.monster_actions.get(aid, {}).get("windup", 0.0))


## Engage une action : effet planifié à t + windup × C, décision suivante à t + C.
func _commit(actor, cmd: Dictionary) -> void:
	var C: int = actor.cycle(rules)
	actor.decisions += 1
	actor.cycle_start = now
	actor.next_ready = now + C
	actor.window_shift = 0.0
	var aid: String = cmd.get("action", "")
	var def: Dictionary = actions.get(aid, {}) if actor.is_hunter() else actor.monster_actions.get(aid, {})

	# Coûts payés à l'engagement (perdus si l'action est interrompue).
	if actor.is_hunter():
		var cost: int = int(def.get("resonance_cost", 0))
		if cost > 0:
			actor.resonance -= cost
		if def.has("item"):
			inventory[def["item"]] = int(inventory.get(def["item"], 0)) - 1

	if actor.is_hunter() and def.get("kind", "") == "guard":
		actor.guard_active = true
		_log("guard", "%s se met en garde." % actor.name, {"actor": actor.id})
		return

	var cast := Cast.new()
	_cast_seq += 1
	cast.seq = _cast_seq
	cast.actor_id = actor.id
	cast.action_id = aid
	cast.action_name = def.get("name", aid)
	cast.mode = cmd.get("mode", "")
	cast.target_id = cmd.get("target", "")
	cast.part_id = cmd.get("part", "")
	cast.decided_at = now
	cast.resolve_at = now + roundi(_windup_factor(actor, cmd) * C)
	cast.telegraph = bool(def.get("telegraph", false))
	cast.interruptible = bool(def.get("interruptible", false))

	var mode_txt := " [%s]" % rules["modes"][cast.mode]["label"] if cast.mode != "" else ""
	var target_txt := ""
	if cast.target_id != "":
		var tgt = get_combatant(cast.target_id)
		target_txt = " → %s" % tgt.name
		if cast.part_id != "":
			target_txt += " (%s)" % tgt.get_part(cast.part_id).name
	var verb := "ANNONCE" if cast.telegraph else "prépare"
	_log("cast", "%s %s %s%s%s — effet à t=%d, prochain tour à t=%d." % [actor.name, verb,
		cast.action_name, mode_txt, target_txt, cast.resolve_at, actor.next_ready],
		{"actor": actor.id, "action": aid, "mode": cast.mode, "resolve_at": cast.resolve_at,
		 "telegraph": cast.telegraph})

	if cast.resolve_at <= now:
		_resolve_cast(cast)
	else:
		actor.pending_cast = cast
		casts.append(cast)


# ---------------------------------------------------------------------------
# Résolutions
# ---------------------------------------------------------------------------

func _resolve_cast(cast) -> void:
	casts.erase(cast)
	var actor = get_combatant(cast.actor_id)
	if actor.pending_cast == cast:
		actor.pending_cast = null
	if not actor.is_alive():
		return
	if actor.is_hunter():
		var def: Dictionary = actions[cast.action_id]
		match def["kind"]:
			"strike":
				_resolve_strike(actor, cast, def)
			"serum":
				_resolve_serum(actor, cast, def)
			"item":
				_resolve_item(actor, cast, def)
	else:
		_resolve_monster_action(actor, cast)


func _mode_mults(mode: String) -> Dictionary:
	if mode == "":
		return {"damage": 1.0, "break": 1.0}
	return {"damage": float(rules["modes"][mode]["damage"]), "break": float(rules["modes"][mode]["break"])}


func _strike_numbers(actor, cmd: Dictionary) -> Dictionary:
	var def: Dictionary = actions[cmd["action"]]
	var target = get_combatant(cmd["target"])
	var part = target.get_part(cmd.get("part", ""))
	var m := _mode_mults(cmd.get("mode", ""))
	var aff: float = part.affinity(actor.damage_type) if part != null else 1.0
	var dmg := Formulas.physical_damage(rules, actor.attack, float(def.get("power", 1.0)), m["damage"],
		actor.weapon_stat(), aff, target.effective_defense())
	var brk := Formulas.break_damage(rules, actor.break_power, float(def.get("break", 1.0)), m["break"],
		int(actor.stats.get("TEC", 5)), aff)
	return {"damage": dmg, "break": brk}


func _serum_numbers(actor, cmd: Dictionary) -> Dictionary:
	var def: Dictionary = actions[cmd["action"]]
	var target = get_combatant(cmd["target"])
	var part = target.get_part(cmd.get("part", ""))
	var element: String = def.get("element", "aether")
	var aff: float = part.affinity(element) if part != null else 1.0
	var elem: float = float(target.resistances.get(element, 1.0)) * aff
	var dmg := Formulas.serum_damage(rules, int(def.get("base_power", 0)), int(actor.stats.get("VOL", 5)),
		elem, target.effective_defense())
	var brk := maxi(0, roundi(float(def.get("break", 0)) * aff))
	return {"damage": dmg, "break": brk}


func _cmd_of(cast) -> Dictionary:
	return {"action": cast.action_id, "mode": cast.mode, "target": cast.target_id, "part": cast.part_id}


func _resolve_strike(actor, cast, def: Dictionary) -> void:
	var target = get_combatant(cast.target_id)
	if target == null or not target.is_alive():
		_log("fizzle", "%s frappe dans le vide." % actor.name, {"actor": actor.id})
		return
	var n := _strike_numbers(actor, _cmd_of(cast))
	var part = target.get_part(cast.part_id)
	_log("hit", "%s : %s touche %s (%s)." % [actor.name, cast.action_name, target.name, part.name],
		{"actor": actor.id, "target": target.id, "part": part.id, "mode": cast.mode})
	# La rupture s'applique avant les dégâts : un coup fatal qui brise une partie compte aussi.
	_apply_break(actor, target, part, n["break"])
	_apply_damage(actor, target, n["damage"])
	var gain: int = int(def.get("resonance_gain", 0))
	if gain > 0:
		_gain_resonance(actor, gain, "attaque")


func _resolve_serum(actor, cast, def: Dictionary) -> void:
	var target = get_combatant(cast.target_id)
	if target == null or not target.is_alive():
		_log("fizzle", "La capacité de %s se dissipe." % actor.name, {"actor": actor.id})
		return
	var n := _serum_numbers(actor, _cmd_of(cast))
	var part = target.get_part(cast.part_id)
	_log("serum", "%s libère %s sur %s (%s)." % [actor.name, cast.action_name, target.name, part.name],
		{"actor": actor.id, "target": target.id, "part": part.id})
	_apply_break(actor, target, part, n["break"])
	_apply_damage(actor, target, n["damage"])
	if target.is_alive():
		shift_readiness(target, float(def.get("delay_fraction", 0.0)))


func _resolve_item(actor, cast, def: Dictionary) -> void:
	var ally = get_combatant(cast.target_id)
	if ally == null or not ally.is_alive():
		_log("fizzle", "%s ne peut plus soigner sa cible." % actor.name, {"actor": actor.id})
		return
	var before: int = ally.hp
	ally.hp = mini(ally.max_hp, ally.hp + int(def.get("heal", 0)))
	_log("heal", "%s utilise %s : %s récupère %d PV." % [actor.name, def["name"], ally.name, ally.hp - before],
		{"actor": actor.id, "target": ally.id, "amount": ally.hp - before})


func _resolve_monster_action(monster, cast) -> void:
	var def: Dictionary = monster.monster_actions.get(cast.action_id, {})
	var power: float = float(def.get("power", 1.0)) * float(monster.action_power_mult.get(cast.action_id, 1.0))
	var targets: Array = []
	if def.get("target", "single") == "all":
		targets = hunters(true)
	else:
		var t = get_combatant(cast.target_id)
		if t == null or not t.is_alive():
			t = EnemyAI.pick_target(self)
			if t == null:
				return
			_log("retarget", "%s se tourne vers %s." % [monster.name, t.name], {"actor": monster.id, "target": t.id})
		targets = [t]
	_log("hit", "%s utilise %s !" % [monster.name, cast.action_name], {"actor": monster.id, "action": cast.action_id})
	for t in targets:
		var dmg := Formulas.physical_damage(rules, monster.attack, power, 1.0, monster.weapon_stat(), 1.0, t.effective_defense())
		_apply_damage(monster, t, dmg)


# ---------------------------------------------------------------------------
# Effets
# ---------------------------------------------------------------------------

func _apply_damage(source, target, amount: int) -> void:
	amount = maxi(0, amount)
	if target.guard_active and source.team != target.team:
		var reduced := roundi(float(amount) * (1.0 - float(rules["guard"]["reduction"])))
		_log("guard_block", "La garde de %s absorbe le choc (%d → %d)." % [target.name, amount, reduced],
			{"actor": target.id, "before": amount, "after": reduced})
		amount = reduced
		target.guard_active = false
		_gain_resonance(target, int(rules["resonance"]["gain_useful_guard"]), "garde utile")
	target.hp = maxi(0, target.hp - amount)
	_log("damage", "%s subit %d dégâts (%d/%d PV)." % [target.name, amount, target.hp, target.max_hp],
		{"actor": source.id, "target": target.id, "amount": amount})
	if target.hp == 0:
		_on_defeated(target)


func _apply_break(source, monster, part, amount: int) -> void:
	if part == null or part.broken or amount <= 0:
		return
	part.integrity = maxi(0, part.integrity - amount)
	_log("break_progress", "%s : intégrité %d/%d." % [part.name, part.integrity, part.max_integrity],
		{"target": monster.id, "part": part.id, "amount": amount})
	if part.integrity > 0:
		return
	# Rupture : effet, butin et Résonance UNE SEULE FOIS.
	part.broken = true
	var effect: Dictionary = part.break_effect
	_log("break", "RUPTURE ! %s de %s est brisée. %s" % [part.name, monster.name, effect.get("text", "")],
		{"actor": source.id, "target": monster.id, "part": part.id})
	_gain_resonance(source, int(rules["resonance"]["gain_break"]), "rupture")
	if part.loot != "":
		loot[part.loot] = int(loot.get(part.loot, 0)) + 1
	match effect.get("type", ""):
		"weaken_action":
			monster.action_power_mult[effect["action"]] = float(effect.get("power_mult", 1.0))
		"disable_action":
			monster.disabled_actions[effect["action"]] = true
		"expose":
			monster.defense_mult = float(effect.get("defense_mult", 1.0))
	if effect.get("interrupt", false) and monster.pending_cast != null \
			and monster.pending_cast.action_id == effect.get("action", ""):
		interrupt(monster, "rupture de %s" % part.name)


func _gain_resonance(actor, amount: int, reason: String) -> void:
	var got: int = actor.gain_resonance(amount, int(rules["resonance"]["max"]))
	if got > 0:
		_log("resonance", "%s gagne %d Résonance (%s) → %d." % [actor.name, got, reason, actor.resonance],
			{"actor": actor.id, "amount": got})


## Annule une préparation interruptible. Le prochain tour de l'acteur reste inchangé (t + C).
func interrupt(actor, reason: String) -> bool:
	var cast = actor.pending_cast
	if cast == null:
		return false
	if not cast.interruptible:
		_log("interrupt_fail", "%s ne peut pas être interrompu." % cast.action_name, {"actor": actor.id})
		return false
	casts.erase(cast)
	actor.pending_cast = null
	_log("interrupt", "INTERRUPTION : %s de %s est annulé (%s)." % [cast.action_name, actor.name, reason],
		{"actor": actor.id, "action": cast.action_id})
	return true


## Avance (fraction < 0) ou recule (fraction > 0) la prochaine décision d'un acteur.
## Bornes : ±max_fraction_per_window entre deux décisions de la cible ; les boss résistent de plus en plus
## aux reculs successifs. Renvoie le décalage réellement appliqué (unités de temps).
func shift_readiness(target, fraction: float) -> int:
	var cap: float = float(rules["tempo_shift"]["max_fraction_per_window"])
	var eff := fraction
	if target.is_boss and fraction > 0.0:
		eff *= pow(float(rules["tempo_shift"]["boss_resistance_factor"]), target.delays_received)
	var new_total := clampf(target.window_shift + eff, -cap, cap)
	eff = new_total - target.window_shift
	var dt := roundi(eff * float(target.cycle(rules)))
	if dt == 0:
		_log("tempo_resist", "%s résiste au changement de rythme." % target.name, {"actor": target.id})
		return 0
	var old: int = target.next_ready
	target.next_ready = maxi(now, target.next_ready + dt)
	target.window_shift = new_total
	if fraction > 0.0:
		target.delays_received += 1
	var applied: int = target.next_ready - old
	var verb := "retardé" if applied > 0 else "avancé"
	_log("tempo", "Le prochain tour de %s est %s de %d (t=%d)." % [target.name, verb, absi(applied), target.next_ready],
		{"actor": target.id, "amount": applied})
	return applied


## Change la Vitesse en CONSERVANT la progression acquise dans le cycle en cours.
func set_speed_mod(target, mod: int) -> void:
	var span: int = target.next_ready - target.cycle_start
	var progress := 0.0
	if span > 0:
		progress = clampf(float(now - target.cycle_start) / float(span), 0.0, 1.0)
	target.speed_mod = mod
	var C: int = target.cycle(rules)
	target.next_ready = now + ceili((1.0 - progress) * float(C))
	target.cycle_start = target.next_ready - C
	_log("speed", "Vitesse de %s : %d (prochain tour t=%d)." % [target.name, target.speed(rules), target.next_ready],
		{"actor": target.id})


func _on_defeated(target) -> void:
	target.guard_active = false
	if target.pending_cast != null:
		casts.erase(target.pending_cast)
		_log("cancel", "L'action en préparation de %s est annulée." % target.name, {"actor": target.id})
		target.pending_cast = null
	_log("defeated", "%s est hors de combat." % target.name, {"actor": target.id})


func _check_end() -> bool:
	if is_over():
		return true
	if monsters(true).is_empty():
		state = State.VICTORY
		current_actor = null
		var items: Dictionary = {}
		var base_items: Dictionary = monster_rewards.get("items", {})
		for k in base_items:
			items[k] = int(base_items[k])
		for k in loot:
			items[k] = int(items.get(k, 0)) + int(loot[k])
		rewards = {"currency": int(monster_rewards.get("currency", 0)), "items": items}
		_log("victory", "VICTOIRE ! Récompenses : %d pièces, %s." % [rewards["currency"], str(items)], rewards)
		return true
	if hunters(true).is_empty():
		state = State.DEFEAT
		current_actor = null
		_log("defeat", "DÉFAITE. Le groupe se replie vers la zone sûre.")
		return true
	return false


func _abort(reason: String) -> void:
	state = State.ABORTED
	abort_reason = reason
	_log("abort", "Combat interrompu : %s" % reason)
	push_error(reason)


func _log(type: String, text: String, data := {}) -> void:
	journal.append({"t": now, "type": type, "text": text, "data": data})
