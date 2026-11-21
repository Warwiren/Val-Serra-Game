extends SceneTree
## P6 — ouverture jouée de bout en bout, avec les vraies scènes et les vraies transitions :
##   godot --headless --path . --script res://tests/e2e_p6_ouverture.gd -- --tuto-rapide
## 1. Colisée : départ dans les vestiaires (Aren seul), dialogue du garde -> objectif « Rejoindre l'arène » ;
## 2. parcours clavier simulé jusqu'au commandant : son dialogue (choix 2) s'ouvre seul et lance le tutoriel ;
## 3. combat tutoriel : Aren seul, étapes guidées et mises en évidence, action non prévue refusée, Échap refusé,
##    PV du commandant intacts, aucune victoire ordinaire, résultat « tutorial_completed » ;
## 4. retour au Colisée devant le commandant, objectif vers la Guilde, grille est levée, PNJ de la coursive ;
##    le tutoriel ne se relance pas en reparlant au commandant ;
## 5. parcours jusqu'à la sortie est -> quartier, état « coliseum_exited », retour au Colisée fermé.
## Code de sortie 1 en cas d'échec.

const Progression = preload("res://src/game/progression.gd")
var fails := []


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, msg: String) -> void:
	print(("OK     " if cond else "ÉCHEC  ") + msg)
	if not cond:
		fails.append(msg)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _attendre_scene(chemin: String, max_s := 60.0) -> Node:
	var t := 0.0
	while t < max_s:
		await process_frame
		t += 1.0 / 60.0
		if current_scene != null and current_scene.scene_file_path == chemin and current_scene.is_node_ready():
			await _frames(6)
			return current_scene
	return null


func _attendre(cond: Callable, max_frames := 3000) -> bool:
	for i in max_frames:
		if cond.call():
			return true
		await physics_frame
	return false


func _run() -> void:
	var gs = root.get_node("GameState")
	gs.new_game("m", "")
	gs.autoplay = false
	Progression.reinitialiser()
	change_scene_to_file(Progression.SCENE_COLISEE)
	var z = await _attendre_scene(Progression.SCENE_COLISEE)
	_check(z != null, "la scène du Colisée se charge")
	if z == null:
		_fin()
		return
	# 1. départ
	_check(z.world.surface_at(Vector2(z.s.hero.x, z.s.hero.y), 0.0).get("id", "") == "vestiaires", "départ : Aren dans les vestiaires")
	_check(z.groupe() == ["aren"], "exploration : Aren seul (aucun compagnon)")
	_check(Progression.etat() == Progression.INTRO_NOT_STARTED, "état initial : intro_not_started")
	_check(z.pnj_presents().has("garde_vestiaires"), "le garde des vestiaires est présent")
	_check(not z.pnj_presents().has("chasseur_reussi"), "les PNJ de la coursive n'apparaissent qu'après le tutoriel")
	# dialogue du garde (parcours clavier simulé, le dialogue avance seul)
	z.s.start_pilot("p6_avant")
	var parle_garde: bool = await _attendre(func(): return z.journal().any(func(e): return e["type"] == "dialogue" and e["pnj"] == "garde_vestiaires"), 900)
	_check(parle_garde, "le garde des vestiaires est interactif")
	var consigne: bool = await _attendre(func(): return Progression.etat() == Progression.TUTORIAL_AVAILABLE, 1200)
	_check(consigne, "après le garde : état tutorial_available")
	_check(Progression.objectif() in ["rejoindre_arene", "parler_commandant"], "objectif : rejoindre l'arène")
	# 2. traversée et commandant
	var arene: bool = await _attendre(func(): return z.journal().any(func(e): return e["type"] == "zone" and e["zone"] == "arene"), 3000)
	_check(arene, "les passages mènent à l'arène (vestiaires -> salle d'attente -> arène)")
	var lance: bool = await _attendre(func(): return Progression.etat() == Progression.TUTORIAL_IN_PROGRESS, 3000)
	_check(lance, "le dialogue du commandant (choix) lance le tutoriel")
	_check(z.journal().any(func(e): return e["type"] == "dialogue" and e["pnj"] == "commandant"), "le commandant a parlé avant le combat")
	_check((z.s.m.get("stuck", []) as Array).is_empty(), "parcours sans blocage : %s" % str(z.s.m.get("stuck", [])))
	# 3. combat tutoriel
	var c = await _attendre_scene(Progression.SCENE_TUTORIEL)
	_check(c != null, "la scène du combat tutoriel se charge")
	if c == null:
		_fin()
		return
	_check(c.battle.hunters().size() == 1 and c.battle.hunters()[0].id == "heros", "combat : Aren seul dans le groupe")
	_check(c.battle.get_combatant("commandant") != null, "adversaire : le commandant de la Guilde")
	var t1: bool = await _attendre(func(): return c.etape_courante() == "presentation" and c.guide.visible, 900)
	_check(t1, "tutoriel : première explication affichée")
	# Échap : on ne quitte pas l'évaluation
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	root.push_input(ev)
	await _frames(3)
	_check(c.trace().any(func(e): return e["type"] == "quitter_refuse"), "Échap pendant le tutoriel : refusé par une réplique")
	_check(current_scene == c, "le joueur reste dans le combat")
	# déroulé joué par le guide en mode démonstration (avec une action non prévue au premier essai)
	c._cli_auto = true
	c._auto_etape(c._etapes[c._i])
	var etapes_vues := {}
	var hl_ok := true
	var fin: bool = await _attendre(func():
		for e in c.trace():
			if e["type"] == "etape":
				etapes_vues[e["id"]] = e
		return c._termine, 6000)
	_check(fin, "le tutoriel va jusqu'au bout")
	for k in ["initiative", "groupe", "actions", "tempos", "ciblage", "attaque", "annonce", "garde", "fin"]:
		_check(etapes_vues.has(k), "étape montrée : " + k)
	for k in etapes_vues:
		var e: Dictionary = etapes_vues[k]
		if (e["cibles"] as Array).size() > 0 and (e["rects"] as Array).size() != (e["cibles"] as Array).size():
			hl_ok = false
	_check(hl_ok, "chaque cible d'interface est trouvée et mise en évidence")
	_check(c.trace().any(func(e): return e["type"] == "action" and e["action"] == "attaque"), "action guidée : attaque vérifiée")
	_check(c.trace().any(func(e): return e["type"] == "action" and e["action"] == "garde"), "action guidée : garde vérifiée")
	var mon = c.battle.get_combatant("commandant")
	_check(mon.hp == mon.max_hp, "le commandant n'a perdu aucun PV (%d / %d)" % [mon.hp, mon.max_hp])
	_check(c.battle.get_combatant("heros").hp > 0, "Aren n'est jamais vaincu")
	_check(c.battle.state != c.Battle.State.VICTORY and c.battle.state != c.Battle.State.DEFEAT, "ni victoire ni défaite ordinaires")
	_check(c.battle.journal.all(func(e): return e["type"] != "defeated"), "aucune mise hors de combat")
	var potions_avant: int = gs.potions
	# 4. retour en exploration
	var z2 = await _attendre_scene(Progression.SCENE_COLISEE, 30.0)
	_check(z2 != null, "retour en exploration dans le Colisée")
	if z2 == null:
		_fin()
		return
	_check(gs.potions == potions_avant, "aucune récompense ni consommation non prévue")
	_check(Progression.etat() == Progression.TUTORIAL_COMPLETED, "état : tutorial_completed")
	_check(Progression.objectif() == "guilde_badge", "objectif : se rendre à la Guilde pour récupérer son badge")
	_check(Vector2(z2.s.hero.x, z2.s.hero.y).distance_to(Vector2(26, 23.3)) < 0.5, "Aren revient dans l'arène, devant le commandant")
	_check(z2.pnj_presents().has("commandant"), "le commandant est toujours présent")
	_check(z2.pnj_presents().has("chasseur_reussi") and z2.pnj_presents().has("chasseuse_echouee"), "coursive : Chasseurs reçu et recalé présents")
	var fin_dlg: bool = await _attendre(func(): return z2.journal().any(func(e): return e["type"] == "dialogue" and e["dialogue"] == "commandant_fin"), 300)
	_check(fin_dlg, "le commandant envoie Aren à la Guilde")
	await _attendre(func(): return not z2.dialogue_is_open(), 600)
	if z2._dialog.is_open():
		await z2._dialog.close()
	await _frames(20)
	# reparler au commandant : pas de nouveau tutoriel
	z2.s.warp_to(Vector3(26, 22.4, 0))
	await _frames(4)
	z2.parler("commandant")
	await _frames(4)
	while z2._dialog.is_open():
		z2._dialog.advance()
		await _frames(30)
	await _frames(40)
	_check(current_scene == z2 and Progression.etat() == Progression.TUTORIAL_COMPLETED, "reparler au commandant ne relance pas le tutoriel")
	# 5. sortie est -> quartier
	z2.s.warp_to(Vector3(26, 23.3, 0))
	await _frames(4)
	z2.s.start_pilot("p6_apres")
	var sorti: bool = await _attendre(func(): return Progression.etat() == Progression.COLISEUM_EXITED, 6000)
	_check(sorti, "la sortie est mène hors du Colisée (état coliseum_exited)")
	var quartier: bool = await _attendre(func(): return z2._p6.get("zone", "") == "quartier", 300)
	_check(quartier, "arrivée dans le quartier (transition provisoire)")
	await _frames(30)
	_check((z2.s.m.get("stuck", []) as Array).is_empty(), "parcours après le tutoriel sans blocage : %s" % str(z2.s.m.get("stuck", [])))
	_check(z2.journal().any(func(e): return e["type"] == "dialogue" and e["pnj"] == "chasseur_reussi"), "PNJ d'ambiance de la coursive interactif")
	# retour au Colisée fermé
	z2.s.warp_to(Vector3(2.6, 8.0, 0))
	await _frames(3)
	var x0: float = z2.s.hero.x
	z2.s.pilot = [{"do": "push", "id": "porte du Colisée", "dir": Vector2(-1, 0), "t": 2.0, "expect": {"min_x": 2.2}}]
	z2.s.pilot_i = 0
	z2.s.pilot_t = 0.0
	z2.s.pilot_done = false
	await _frames(150)
	_check(z2.s.hero.x > 2.2 and z2._p6.get("zone", "") == "quartier", "retour vers l'arène bloqué après la sortie (x = %.2f, départ %.2f)" % [z2.s.hero.x, x0])
	_check(z2._portes_fermees.has("portes_colisee"), "la porte du Colisée est fermée côté quartier")
	_fin()


func _fin() -> void:
	print("E2E P6 RÉSULTAT : %s (%d échec(s))" % ["RÉUSSI" if fails.is_empty() else "ÉCHEC", fails.size()])
	quit(0 if fails.is_empty() else 1)
