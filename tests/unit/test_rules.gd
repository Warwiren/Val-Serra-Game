extends "res://tests/test_case.gd"
## Dégâts, garde, rupture, interruption, Résonance, objets, sérum, fin de combat, déterminisme.

const Formulas = preload("res://src/combat/core/formulas.gd")
const AutoPolicy = preload("res://tests/helpers/auto_policy.gd")


func _journal_has(b: Battle, type: String, key := "", value = null) -> bool:
	for e in b.journal:
		if e["type"] != type:
			continue
		if key == "":
			return true
		var v = e["data"].get(key, null)
		if typeof(v) == typeof(value) and v == value:
			return true
	return false


func test_damage_is_never_negative() -> void:
	var r: Dictionary = new_battle().rules
	check_eq(Formulas.physical_damage(r, 10, -2.0, 1.0, 5.0, 1.0, 0), 0, "multiplicateur négatif → 0")
	check_eq(Formulas.break_damage(r, -5, 1.0, 1.0, 5, 1.0), 0, "rupture négative → 0")
	check(Formulas.physical_damage(r, 50, 1.0, 1.0, 5.0, 1.0, 100000) >= 0, "défense énorme → jamais négatif")
	var b := frozen_battle()
	var h = hero(b)
	b._apply_damage(monster(b), h, -30)
	check_eq(h.hp, h.max_hp, "des dégâts négatifs ne soignent pas")


func test_modes_scale_damage_and_break() -> void:
	var b := frozen_battle()
	var h = hero(b)
	var res := {}
	for mode in ["VIF", "MESURE", "CHARGE"]:
		res[mode] = b.estimate(h, {"action": "technique", "mode": mode, "target": "vorgane", "part": "griffe"})
	check(res["VIF"]["damage"] < res["MESURE"]["damage"] and res["MESURE"]["damage"] < res["CHARGE"]["damage"],
		"dégâts VIF < MESURÉ < CHARGÉ")
	check(res["VIF"]["break"] < res["MESURE"]["break"] and res["MESURE"]["break"] < res["CHARGE"]["break"],
		"rupture VIF < MESURÉ < CHARGÉ")
	check(res["VIF"]["resolve_at"] < res["MESURE"]["resolve_at"] and res["MESURE"]["resolve_at"] < res["CHARGE"]["resolve_at"],
		"effet VIF avant MESURÉ avant CHARGÉ")


func test_guard_reduces_next_hit_by_40_percent() -> void:
	var plain := frozen_battle()
	plain._commit(monster(plain), {"action": "fauche", "target": "heros"})
	hero(plain).next_ready = 100   # le Héros reprend la main avant le tour suivant du monstre
	plain.advance()
	var unguarded: int = hero(plain).max_hp - hero(plain).hp

	var b := frozen_battle()
	var h = hero(b)
	b._commit(h, {"action": "garde"})
	b._commit(monster(b), {"action": "fauche", "target": "heros"})
	b.advance()
	check_eq(h.max_hp - h.hp, roundi(unguarded * 0.6), "dégâts réduits de 40 %")
	check_eq(h.resonance, 10, "garde utile : +10 Résonance")
	check(not h.guard_active, "la garde est consommée")


func test_break_interrupts_announced_attack() -> void:
	var b := frozen_battle()
	var m = monster(b)
	m.cycle_start = 0
	b._commit(m, {"action": "souffle"})
	check(m.pending_cast != null and m.pending_cast.telegraph, "le Souffle est annoncé")
	m.get_part("glande").integrity = 1
	b._commit(hero(b), {"action": "attaque", "target": "vorgane", "part": "glande"})
	b.advance()
	check(m.get_part("glande").broken, "glande brisée")
	check(m.pending_cast == null, "préparation annulée")
	check(_journal_has(b, "interrupt"), "interruption journalisée")
	check(not _journal_has(b, "hit", "action", "souffle"), "le Souffle ne s'est jamais produit")
	check_eq(m.next_ready, 109, "le prochain tour du monstre n'est pas modifié par l'interruption")
	check(m.disabled_actions.has("souffle"), "Souffle désactivé après rupture")
	for h in b.hunters():
		check_eq(h.hp, h.max_hp, "%s indemne" % h.name)


func test_quick_strike_beats_telegraph_but_charged_does_not() -> void:
	# Situation : le monstre annonce son Souffle (effet à t=87) ; le Héros décide à t=50.
	for mode in ["VIF", "CHARGE"]:
		var b := frozen_battle()
		var m = monster(b)
		var h = hero(b)
		b._commit(m, {"action": "souffle"})
		b.now = 50
		h.cycle_start = 50
		b.state = Battle.State.AWAITING_COMMAND
		b.current_actor = h
		var cmd := {"action": "technique", "mode": mode, "target": "vorgane", "part": "glande"}
		m.get_part("glande").integrity = b.estimate(h, cmd)["break"]   # ce coup suffit à la briser
		check_eq(b.submit(cmd), "", "commande %s acceptée" % mode)
		var souffle_hit := _journal_has(b, "hit", "action", "souffle")
		if mode == "VIF":
			check(not souffle_hit, "VIF (effet t=70) brise la glande avant le Souffle (t=87)")
			check(_journal_has(b, "interrupt"), "VIF interrompt le Souffle")
		else:
			check(souffle_hit, "CHARGÉ (effet t=127) arrive trop tard : le Souffle frappe")
			check(m.get_part("glande").broken, "mais la glande finit brisée")


func test_break_happens_once_with_single_loot_and_resonance() -> void:
	var b := frozen_battle()
	var h = hero(b)
	var m = monster(b)
	var part = m.get_part("griffe")
	b._apply_break(h, m, part, 500)
	b._apply_break(h, m, part, 500)
	check(part.broken, "partie brisée")
	check_eq(int(b.loot.get("griffe_vorgane", 0)), 1, "butin de partie une seule fois")
	check_eq(h.resonance, 15, "Résonance de rupture une seule fois")
	check_eq(float(m.action_power_mult.get("fauche", 1.0)), 0.6, "effet réel : Fauche affaiblie")


func test_carapace_break_exposes_body() -> void:
	var b := frozen_battle()
	var h = hero(b)
	var m = monster(b)
	var cmd := {"action": "attaque", "target": "vorgane", "part": "griffe"}
	var before: int = b.estimate(h, cmd)["damage"]
	b._apply_break(h, m, m.get_part("carapace"), 999)
	var after: int = b.estimate(h, cmd)["damage"]
	check(after > before, "après rupture de la carapace, tous les coups font plus mal (%d > %d)" % [after, before])


func test_resonance_is_per_action_and_capped() -> void:
	var b := frozen_battle()
	var h = hero(b)
	b._commit(h, {"action": "attaque", "target": "vorgane", "part": "carapace"})
	b.advance()
	check_eq(h.resonance, 8, "une attaque = +8, une seule fois")
	h.resonance = 98
	b.state = Battle.State.AWAITING_COMMAND
	b.current_actor = h
	b.submit({"action": "attaque", "target": "vorgane", "part": "carapace"})
	check_eq(h.resonance, 100, "plafond à 100")


func test_serum_costs_resonance_and_delays_target() -> void:
	var b := frozen_battle()
	var h = hero(b)
	var m = monster(b)
	m.cycle_start = 0
	m.next_ready = 109
	b.state = Battle.State.AWAITING_COMMAND
	b.current_actor = h
	var cmd := {"action": "serum_pulsation", "target": "vorgane", "part": "glande"}
	check(b.validate(h, cmd) != "", "refusé sans Résonance")
	h.resonance = 30
	check_eq(b.validate(h, cmd), "", "accepté avec 30 Résonance")
	var hp_before: int = m.hp
	b.submit(cmd)
	check_eq(h.resonance, 0, "coût payé")
	check(m.hp < hp_before, "dégâts d'Aether infligés")
	check_eq(m.next_ready, 109 + roundi(0.15 * 109), "tour du monstre retardé de 15 %")


func test_potion_heals_and_is_consumed() -> void:
	var b := frozen_battle()
	var h = hero(b)
	h.hp = 50
	b.state = Battle.State.AWAITING_COMMAND
	b.current_actor = h
	check_eq(b.submit({"action": "potion", "target": "heros"}), "", "potion acceptée")
	check_eq(int(b.inventory["potion"]), 1, "une potion consommée")
	check_eq(h.hp, 110, "+60 PV")
	b.inventory["potion"] = 0
	check(b.validate(h, {"action": "potion", "target": "heros"}) != "", "refus sans potion")


func test_defeated_actor_loses_pending_action() -> void:
	var b := frozen_battle()
	var h = hero(b)
	var m = monster(b)
	b._commit(h, {"action": "technique", "mode": "CHARGE", "target": "vorgane", "part": "glande"})
	b._commit(m, {"action": "fauche", "target": "heros"})
	h.hp = 1
	b.advance()
	check(not h.is_alive(), "le Héros tombe")
	check(h.pending_cast == null, "sa préparation est annulée")
	check_eq(m.get_part("glande").integrity, m.get_part("glande").max_integrity, "son coup chargé ne part jamais")
	check(_journal_has(b, "cancel"), "annulation journalisée")


func test_full_battle_ends_without_infinite_loop() -> void:
	var b := new_battle()
	var turns := AutoPolicy.play(b)
	check(b.state == Battle.State.VICTORY or b.state == Battle.State.DEFEAT,
		"le combat se termine (état %d, %s)" % [b.state, b.abort_reason])
	check(turns < 500, "en un nombre raisonnable de tours (%d)" % turns)


func test_victory_rewards_include_broken_parts() -> void:
	var b := new_battle()
	AutoPolicy.play(b)
	if b.state != Battle.State.VICTORY:
		check(false, "la politique automatique devrait gagner avec les valeurs par défaut")
		return
	check_eq(int(b.rewards["currency"]), 60, "monnaie")
	check_eq(int(b.rewards["items"]["cuir_vorgane"]), 1, "composant de base")
	for p in monster(b).parts:
		if p.broken:
			check_eq(int(b.rewards["items"].get(p.loot, 0)), 1, "composant de %s" % p.name)


func test_defeat_is_reachable() -> void:
	var b := new_battle({"potion": 0})
	monster(b).attack = 400
	AutoPolicy.play(b)
	check(b.state == Battle.State.DEFEAT, "défaite possible")
	check(b.rewards.is_empty(), "aucune récompense en cas de défaite")


func test_monster_cannot_be_stalled_forever() -> void:
	var b := new_battle()
	AutoPolicy.play(b, "serum_spam")
	var m = monster(b)
	var C: int = m.cycle(b.rules)
	var times: Array = []
	for e in b.journal:
		if e["type"] == "cast" and e["data"].get("actor", "") == m.id:
			times.append(e["t"])
	check(times.size() >= 3, "le monstre agit plusieurs fois (%d)" % times.size())
	for i in range(1, times.size()):
		var gap: int = times[i] - times[i - 1]
		check(gap <= C + roundi(0.2 * C), "écart entre deux tours du monstre borné (%d)" % gap)


func test_simulation_is_deterministic() -> void:
	var a := new_battle()
	var b := new_battle()
	AutoPolicy.play(a)
	AutoPolicy.play(b)
	check_eq(a.journal.size(), b.journal.size(), "même nombre d'événements")
	var same := true
	for i in range(mini(a.journal.size(), b.journal.size())):
		if a.journal[i]["text"] != b.journal[i]["text"] or a.journal[i]["t"] != b.journal[i]["t"]:
			same = false
			break
	check(same, "journaux identiques")
	check_eq(a.state, b.state, "même issue")
