extends "res://tests/test_case.gd"
## P6 — Colisée de Val'Serra (ouverture) : données de la zone, accès selon la progression (modèle logique World25 +
## portes de la scène), PNJ et dialogues, états de progression, adversaire du tutoriel (CombatCore inchangé).
## Le parcours complet joué (exploration -> tutoriel -> retour -> sortie) est vérifié par tests/e2e_p6_ouverture.gd.

const World25 = preload("res://src/explore25/world25.gd")
const Progression = preload("res://src/game/progression.gd")
const AutoPolicy = preload("res://src/combat/auto_policy.gd")
const ZONE := "res://data/p6/colisee.json"
const QUARTIER := "res://data/p6/quartier_initial.json"
const PNJ := "res://data/p6/pnj_colisee.json"
const DIALOGUES := "res://data/p6/dialogues_colisee.json"
const TUTO := "res://data/p6/tutoriel_colisee.json"
const MONSTRE := "res://data/combat/monster_commandant.json"
const GRID := 0.25
const CLES_HUD := ["initiative", "groupe", "actions", "description", "tempos", "confirmer", "pv_adversaire", "adversaire"]


func _json(p: String):
	return JSON.parse_string(FileAccess.open(p, FileAccess.READ).get_as_text())


## Monde logique + portes FERMÉES pour un état donné (mêmes règles que scenes/p6/colisee.gd : porte_ouverte).
func _monde(etat: String, file := ZONE):
	var w = World25.load_world(file, "instance")
	for p in w.adj["p6"].get("portes", []):
		var ouverte := true
		if p.has("fermee_a_partir_de"):
			ouverte = Progression.rang(etat) < Progression.rang(p["fermee_a_partir_de"])
		elif p.has("ouverte_a_partir_de"):
			ouverte = Progression.rang(etat) >= Progression.rang(p["ouverte_a_partir_de"])
		else:
			ouverte = p.get("marque", "") != "fermee"
		if not ouverte:
			var q: Array = p["rect"]
			w.solids.append({"id": p["id"], "kind": "rect", "rect": Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1]), "h0": 0.0, "h1": 2.6})
	return w


func _flood(w, start: Vector2) -> Dictionary:
	var seen := {}
	var q: Array = [start]
	seen[Vector2i(roundi(start.x / GRID), roundi(start.y / GRID))] = true
	while q.size() > 0:
		var cur: Vector2 = q.pop_back()
		for d in [Vector2(GRID, 0), Vector2(-GRID, 0), Vector2(0, GRID), Vector2(0, -GRID)]:
			var np: Vector2 = cur + d
			var k := Vector2i(roundi(np.x / GRID), roundi(np.y / GRID))
			if seen.has(k) or w.stand(np, 0.0).is_empty():
				continue
			seen[k] = true
			q.append(np)
	return seen


func _atteint(seen: Dictionary, p: Vector2) -> bool:
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if seen.has(Vector2i(roundi(p.x / GRID) + dx, roundi(p.y / GRID) + dy)):
				return true
	return false


func test_zone_et_donnees() -> void:
	var w = World25.load_world(ZONE, "instance")
	check(not w.stand(Vector2(w.spawn.x, w.spawn.y), 0.0).is_empty(), "départ d'Aren tenable")
	check_eq(w.surface_at(Vector2(w.spawn.x, w.spawn.y), 0.0).get("id", ""), "vestiaires", "Aren démarre dans les vestiaires")
	check(w.triggers.size() == 1 and w.triggers[0]["id"] == "sortie_est", "une seule sortie : la sortie est")
	var p6: Dictionary = w.adj["p6"]
	for k in ["arene", "portes", "examens", "zones_nommees", "sols"]:
		check(p6.has(k), "section p6.%s présente" % k)
	# l'arène est ovale : le centre est praticable, les coins du rectangle sont fermés par le podium
	check(not w.stand(Vector2(26, 23), 0.0).is_empty(), "centre de l'arène praticable")
	var flood := _flood(_monde(Progression.TUTORIAL_COMPLETED), Vector2(26, 23))
	check(not _atteint(flood, Vector2(14.2, 14.6)), "coin nord-ouest du rectangle de l'arène inaccessible (podium ovale)")
	check(not _atteint(flood, Vector2(38.0, 31.6)), "coin sud-est du rectangle de l'arène inaccessible")
	var q = World25.load_world(QUARTIER, "instance")
	check(not q.stand(Vector2(q.spawn.x, q.spawn.y), 0.0).is_empty(), "arrivée dans le quartier tenable")
	check_eq(q.adj["p6"]["zone"], "quartier", "quartier : zone identifiée")


func test_acces_avant_tutoriel() -> void:
	var w = _monde(Progression.TUTORIAL_AVAILABLE)
	var f := _flood(w, Vector2(w.spawn.x, w.spawn.y))
	check(_atteint(f, Vector2(26, 41)), "avant : salle d'attente accessible")
	check(_atteint(f, Vector2(26, 23.5)), "avant : arène (devant le commandant) accessible")
	check(not _atteint(f, Vector2(50, 23)), "avant : coursive fermée (grille est baissée)")
	check(not _atteint(f, Vector2(62, 23)), "avant : sortie est inaccessible (impossible de quitter le Colisée)")
	check(not _atteint(f, Vector2(46.5, 38)), "avant : infirmerie inaccessible")
	check(not _atteint(f, Vector2(14.0, 51.6)), "avant : porte des vestiaires vers la rue fermée")


func test_acces_apres_tutoriel() -> void:
	var w = _monde(Progression.TUTORIAL_COMPLETED)
	var f := _flood(w, Vector2(26, 23.3))
	check(_atteint(f, Vector2(50, 23)), "après : coursive accessible")
	check(_atteint(f, Vector2(46.5, 38.5)), "après : infirmerie accessible")
	check(_atteint(f, Vector2(64.2, 23)), "après : sortie est accessible")
	check(_atteint(f, Vector2(26, 50)), "après : retour possible vers les vestiaires")
	check(not _atteint(f, Vector2(53, 37)), "après : réserve fermée")
	check(not _atteint(f, Vector2(50, 11)), "après : loge officielle fermée")
	check(not _atteint(f, Vector2(57.5, 16)), "après : accès aux gradins est fermé")


func test_quartier_retour_ferme() -> void:
	var w = _monde(Progression.COLISEUM_EXITED, QUARTIER)
	var f := _flood(w, Vector2(w.spawn.x, w.spawn.y))
	check(_atteint(f, Vector2(25.8, 8)), "quartier : la rue mène au panneau de la Guilde")
	check(not _atteint(f, Vector2(1.0, 8.0)), "quartier : retour au Colisée fermé après la sortie")


func test_pnj_et_dialogues() -> void:
	var pnj: Array = _json(PNJ)["pnj"]
	var dia: Dictionary = _json(DIALOGUES)["dialogues"]
	var w = World25.load_world(ZONE, "instance")
	var wq = World25.load_world(QUARTIER, "instance")
	var ids := {}
	for d in pnj:
		check(not ids.has(d["id"]), "PNJ %s : identifiant unique" % d["id"])
		ids[d["id"]] = true
		check(dia.has(d["dialogue"]), "PNJ %s : dialogue « %s » défini" % [d["id"], d["dialogue"]])
		var ww = wq if d["zone"] == "quartier" else w
		check(not ww.stand(Vector2(d["xy"][0], d["xy"][1]), 0.0).is_empty(), "PNJ %s : posé sur un sol libre" % d["id"])
		check(d.get("teinte", [1, 1, 1]) != [0.87, 0.79, 0.69], "PNJ %s : pas la silhouette d'Aren" % d["id"])
	for k in ["garde_vestiaires", "commandant", "chasseur_nerveux", "chasseuse_confiante", "chasseur_reussi", "chasseuse_echouee", "garde_gradins"]:
		check(ids.has(k), "PNJ attendu : " + k)
	for k in dia:
		var vs: Array = dia[k]
		check(vs.size() > 0 and vs[-1]["a_partir_de"] == Progression.INTRO_NOT_STARTED, "dialogue %s : une variante de repli" % k)
	# le commandant : choix de réponses (3) qui aboutissent tous au tutoriel
	var cmd: Dictionary = dia["commandant"][-1]
	check_eq(cmd.get("effet", ""), "lancer_tutoriel", "commandant : le dialogue lance le tutoriel")
	var choix: Array = []
	for st in cmd["etapes"]:
		if st.has("choice"):
			choix = st["choice"]
	check_eq(choix.size(), 3, "commandant : trois réponses au choix")
	for c in choix:
		check(c["then"].size() >= 2, "réponse « %s » : réplique adaptée du commandant" % c["label"])
	check(cmd["etapes"][-1]["who"] == "pnj", "commandant : réplique commune après le choix")
	check_eq(dia["garde_vestiaires"][-1].get("effet", ""), "consigne_arene", "garde des vestiaires : donne l'objectif")


func test_progression() -> void:
	var gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	if gs == null:
		check(true, "GameState absent (exécution isolée)")
		return
	var sauve: Dictionary = gs.flags.duplicate()
	Progression.reinitialiser()
	check_eq(Progression.etat(), Progression.INTRO_NOT_STARTED, "état initial")
	Progression.definir(Progression.TUTORIAL_COMPLETED)
	Progression.definir(Progression.TUTORIAL_AVAILABLE)
	check_eq(Progression.etat(), Progression.TUTORIAL_COMPLETED, "l'état ne recule pas sans force")
	check(Progression.au_moins(Progression.TUTORIAL_IN_PROGRESS), "au_moins : ordre des états")
	check(not Progression.au_moins(Progression.COLISEUM_EXITED), "au_moins : état non atteint")
	Progression.definir(Progression.TUTORIAL_AVAILABLE, true)
	check_eq(Progression.etat(), Progression.TUTORIAL_AVAILABLE, "retour en arrière explicite (force)")
	Progression.definir_objectif("guilde_badge")
	check_eq(Progression.objectif_texte(), "Se rendre à la Guilde pour récupérer son badge", "objectif vers la Guilde")
	var snap: Dictionary = Progression.instantane()
	var relu = JSON.parse_string(JSON.stringify(snap))
	check_eq(relu, snap, "état sérialisable (sauvegarde)")
	gs.flags = sauve


func _combat_tuto():
	var data := BattleFactory.load_default_data()
	data["monster"] = BattleFactory.load_json(MONSTRE)
	return BattleFactory.create(data, ["heros"], {"potion": 2})


func test_commandant_ne_perd_pas_de_pv() -> void:
	var b = _combat_tuto()
	b.start()
	check_eq(b.hunters().size(), 1, "tutoriel : Aren seul dans le groupe")
	var mon = b.get_combatant("commandant")
	var h = b.get_combatant("heros")
	h.resonance = 100
	var cmds := [{"action": "attaque", "target": "commandant", "part": "heaume"},
		{"action": "technique", "mode": "CHARGE", "target": "commandant", "part": "plastron"},
		{"action": "serum_pulsation", "target": "commandant", "part": "bouclier"},
		{"action": "technique", "mode": "VIF", "target": "commandant", "part": "bouclier"}]
	for c in cmds:
		check_eq(b.submit(c), "", "commande acceptée : " + c["action"])
		check_eq(mon.hp, mon.max_hp, "le commandant ne perd pas de PV (%s)" % c["action"])
		for p in mon.parts:
			check(not p.broken, "aucune partie du commandant ne se brise")
	check(b.state != Battle.State.VICTORY, "pas de victoire ordinaire possible")


func test_tutoriel_imperdable() -> void:
	# déroulé du tutoriel : attaque, puis garde au moment de l'assaut annoncé ; fin au 3e tour
	var b = _combat_tuto()
	b.start()
	check_eq(b.submit({"action": "attaque", "target": "commandant", "part": "heaume"}), "", "tour 1 : attaque")
	var mon = b.get_combatant("commandant")
	check(mon.pending_cast != null and mon.pending_cast.telegraph, "tour 2 : l'assaut du commandant est annoncé")
	check(mon.pending_cast.resolve_at < b.now + b.get_combatant("heros").cycle(b.rules), "l'assaut frappe avant le tour suivant d'Aren")
	check_eq(b.submit({"action": "garde"}), "", "tour 2 : garde")
	var blocks: Array = b.journal.filter(func(e): return e["type"] == "guard_block")
	check_eq(blocks.size(), 1, "la garde absorbe l'assaut")
	var h = b.get_combatant("heros")
	check(h.hp >= h.max_hp * 0.6, "Aren garde plus de 60 %% de ses PV au 3e tour (%d / %d)" % [h.hp, h.max_hp])
	check(h.resonance >= 10, "la garde utile rapporte de la Résonance")
	# même sans jamais se garder, le joueur ne peut pas perdre pendant la durée du tutoriel (3 tours) ni bien au-delà
	var b2 = _combat_tuto()
	b2.start()
	for i in 6:
		b2.submit({"action": "attaque", "target": "commandant", "part": "heaume"})
	check(b2.get_combatant("heros").is_alive() and b2.state == Battle.State.AWAITING_COMMAND, "6 attaques sans garde : Aren tient toujours debout")


func test_etapes_du_tutoriel() -> void:
	var t: Dictionary = _json(TUTO)
	var hunters: Dictionary = BattleFactory.load_json("res://data/combat/hunters.json")
	var actions: Array = hunters["hunters"][0]["actions"]
	var vues := {}
	var tours := []
	for e in t["etapes"]:
		for c in e.get("cibles", []):
			check(CLES_HUD.has(c), "étape %s : cible d'interface connue (%s)" % [e["id"], c])
		for a in e.get("actions", []):
			check(actions.has(a), "étape %s : action réellement disponible (%s)" % [e["id"], a])
		vues[e["id"]] = true
		tours.append(int(e["tour"]))
	for k in ["initiative", "actions", "ciblage", "attaque", "garde", "fin"]:
		check(vues.has(k), "étape attendue : " + k)
	var trie: Array = tours.duplicate()
	trie.sort()
	check_eq(tours, trie, "étapes dans l'ordre des tours")
	check(t["etapes"][-1].get("fin", false), "la dernière étape clôt le tutoriel")
