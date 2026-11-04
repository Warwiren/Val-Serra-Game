extends "res://tests/test_case.gd"
## Horloge commune, modes VIF/MESURÉ/CHARGÉ, départages, Vitesse, avance/recul.

const Formulas = preload("res://src/combat/core/formulas.gd")


func test_cycle_values_from_gdd() -> void:
	var r: Dictionary = new_battle().rules
	check_eq(Formulas.cycle_length(r, 80), 125, "C(80)")
	check_eq(Formulas.cycle_length(r, 100), 100, "C(100)")
	check_eq(Formulas.cycle_length(r, 125), 80, "C(125)")
	check_eq(Formulas.cycle_length(r, 500), Formulas.cycle_length(r, 135), "Vitesse plafonnée à 135")
	check_eq(Formulas.cycle_length(r, 1), Formulas.cycle_length(r, 70), "Vitesse plancher à 70")


func test_derived_speeds_of_profiles() -> void:
	var b := new_battle()
	check_eq(b.get_combatant("compagnon_vif").cycle(b.rules), 92, "profil rapide : V=109 → C=92")
	check_eq(hero(b).cycle(b.rules), 102, "profil équilibré : V=99 → C=102")
	check_eq(b.get_combatant("compagnon_lourd").cycle(b.rules), 120, "profil lourd : V=84 → C=120")
	check_eq(monster(b).cycle(b.rules), 109, "monstre : V=92 → C=109")


func test_first_turn_goes_to_fastest() -> void:
	var b := new_battle()
	b.start()
	check_eq(b.current_actor.id, "compagnon_vif", "le plus rapide agit en premier")
	check_eq(b.now, 92, "à t = C")


func test_modes_change_effect_time_not_next_decision() -> void:
	var b := frozen_battle()
	var h = hero(b)
	h.base_speed = 100   # C = 100, comme l'exemple du GDD
	b.state = Battle.State.AWAITING_COMMAND
	b.current_actor = h
	var expected := {"VIF": 20, "MESURE": 45, "CHARGE": 75}
	for mode in expected:
		var est: Dictionary = b.estimate(h, {"action": "technique", "mode": mode, "target": "vorgane", "part": "carapace"})
		check_eq(est["resolve_at"], expected[mode], "effet %s à t+%d" % [mode, expected[mode]])
		check_eq(est["next_decision"], 100, "décision suivante à t+100 en mode %s" % mode)
	var err := b.submit({"action": "technique", "mode": "CHARGE", "target": "vorgane", "part": "carapace"})
	check_eq(err, "", "commande acceptée")
	check_eq(h.next_ready, 100, "après CHARGÉ, prochain tour toujours à t+C")


func test_same_scheduler_for_monster_and_hunters() -> void:
	var b := new_battle()
	b.start()
	var seen := {}
	for i in range(8):
		seen[b.current_actor.id] = true
		b.submit({"action": "garde"})
	check(monster(b).decisions >= 2, "le monstre a pris ses tours dans la même chronologie")
	check_eq(seen.size(), 3, "les trois Chasseurs ont joué")


func test_tie_break_is_stable_and_explicit() -> void:
	var b := frozen_battle()
	var h = hero(b)
	var v = b.get_combatant("compagnon_vif")
	h.next_ready = 50
	v.next_ready = 50
	var evs: Array = b._build_events(1)
	check_eq(evs[0]["actor_id"], "compagnon_vif", "égalité : la Vitesse la plus haute d'abord")
	v.base_speed = h.base_speed
	evs = b._build_events(1)
	check_eq(evs[0]["actor_id"], "heros", "égalité parfaite : ordre de mise en place")
	var m = monster(b)
	m.next_ready = 50
	m.base_speed = h.base_speed
	evs = b._build_events(1)
	check_eq(evs[2]["actor_id"], "vorgane", "égalité Chasseur/monstre : Chasseurs d'abord")


func test_resolution_before_decision_at_same_time() -> void:
	var b := frozen_battle()
	b._commit(monster(b), {"action": "fauche", "target": "heros"})   # effet à roundi(0,30 × 109) = 33
	hero(b).next_ready = 33
	var evs: Array = b._build_events(1)
	check_eq(evs[0]["time"], 33, "premier événement à t=33")
	check_eq(evs[0]["kind"], Battle.EV_RESOLVE, "la résolution passe avant la décision")
	check_eq(evs[1]["actor_id"], "heros", "puis la décision du Héros")


func test_speed_change_keeps_progress() -> void:
	var b := frozen_battle()
	var h = hero(b)
	h.cycle_start = 0
	h.next_ready = 102
	b.now = 51                       # 50 % du cycle écoulé
	b.set_speed_mod(h, 36)           # V = 135 → C = 75
	check_eq(h.next_ready, 51 + 38, "reste 50 % de 75 = 38 (arrondi supérieur)")
	var b2 := frozen_battle()
	var h2 = hero(b2)
	h2.cycle_start = 0
	h2.next_ready = 102
	b2.now = 51
	b2.set_speed_mod(h2, -29)        # V = 70 → C = 143
	check_eq(h2.next_ready, 51 + 72, "ralentissement : reste 50 % de 143 = 72")


func test_never_ready_before_own_preparation() -> void:
	var b := frozen_battle()
	var h = hero(b)
	b._commit(h, {"action": "technique", "mode": "CHARGE", "target": "vorgane", "part": "glande"})
	var resolve_at: int = h.pending_cast.resolve_at
	h.next_ready = resolve_at - 20   # accélération extrême simulée
	var evs: Array = b._build_events(1)
	var ready_ev: Dictionary = {}
	for e in evs:
		if e["kind"] == Battle.EV_READY and e["actor_id"] == "heros":
			ready_ev = e
	check_eq(ready_ev["time"], resolve_at, "décision repoussée à la fin de sa propre préparation")
	check_eq(evs[0]["kind"], Battle.EV_RESOLVE, "la préparation se résout d'abord")


func test_boss_delay_is_capped_and_decays() -> void:
	var b := frozen_battle()
	var m = monster(b)
	m.cycle_start = 0
	m.next_ready = 109
	var d1 := b.shift_readiness(m, 0.15)
	var d2 := b.shift_readiness(m, 0.15)
	var d3 := b.shift_readiness(m, 0.15)
	check_eq(d1, 16, "1er recul : 15 % de 109")
	check_eq(d2, 5, "2e recul : résistance du boss + plafond 20 %/fenêtre")
	check_eq(d3, 0, "3e recul dans la même fenêtre : aucun effet")
	check(d1 + d2 + d3 <= roundi(0.2 * 109), "jamais plus de 20 % d'un cycle par fenêtre")
	b._commit(m, {"action": "fauche", "target": "heros"})   # nouvelle fenêtre
	var d4 := b.shift_readiness(m, 0.15)
	check(d4 < d1, "la résistance du boss persiste d'une fenêtre à l'autre (%d < %d)" % [d4, d1])


func test_advance_is_capped_too() -> void:
	var b := frozen_battle()
	var h = hero(b)
	h.cycle_start = 0
	h.next_ready = 102
	var a1 := b.shift_readiness(h, -0.5)
	check_eq(a1, -20, "avance plafonnée à 20 % de 102")
	check_eq(b.shift_readiness(h, -0.5), 0, "pas d'avance supplémentaire dans la même fenêtre")


func test_preview_matches_simulation() -> void:
	var b := new_battle()
	b.start()
	var cmd := {"action": "technique", "mode": "VIF", "target": "vorgane", "part": "griffe"}
	var preview := b.preview_timeline(10, cmd)
	var predicted := -1
	var first_hunter_preview := ""
	for e in preview:
		if e["hypothetical"]:
			predicted = e["time"]
		elif e["kind"] == Battle.EV_READY and e["actor_id"] != "vorgane" and first_hunter_preview == "":
			first_hunter_preview = e["actor_id"]
	var actor = b.current_actor
	b.submit(cmd)
	var real := -1
	for entry in b.journal:
		if entry["type"] == "cast" and entry["data"].get("actor", "") == actor.id:
			real = entry["data"]["resolve_at"]
	check_eq(real, predicted, "l'aperçu annonce la date d'effet exacte")
	check(predicted > 0, "l'aperçu contient l'action hypothétique")
	# Après la commande, le prochain Chasseur annoncé est bien celui qui joue (le monstre joue seul entre-temps).
	check_eq(b.current_actor.id, first_hunter_preview, "le prochain Chasseur annoncé est le bon")
