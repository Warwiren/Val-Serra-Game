extends SceneTree
## P6.2 — saut du tutoriel, avec les vraies scènes :
##   godot --headless --path . --script res://tests/e2e_p6_saut_tutoriel.gd
## 1. dans le dialogue du commandant, « Passer le tutoriel » : aucun combat chargé, même état final que la fin normale ;
## 2. pendant le combat : Échap / bouton -> confirmation ; « Oui » -> même état final, commandant intact, ni victoire
##    ni défaite, aucune récompense. Dans les deux cas : retour dans l'arène devant le commandant, dialogue de fin,
##    objectif Guilde, grille est ouverte, et le tutoriel ne se relance pas. Code de sortie 1 en cas d'échec.

const Progression = preload("res://src/game/progression.gd")
var fails := []
var scenes_vues: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, msg: String) -> void:
	print(("OK     " if cond else "ÉCHEC  ") + msg)
	if not cond:
		fails.append(msg)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _suivre() -> void:
	var p := current_scene.scene_file_path if current_scene != null else ""
	if scenes_vues.is_empty() or scenes_vues[-1] != p:
		scenes_vues.append(p)


func _attendre(cond: Callable, max_frames := 3000) -> bool:
	for i in max_frames:
		_suivre()
		if cond.call():
			return true
		await physics_frame
	return false


func _colisee_pret() -> Node:
	var ok: bool = await _attendre(func(): return current_scene != null and current_scene.scene_file_path == Progression.SCENE_COLISEE and current_scene.is_node_ready() and current_scene.world != null, 1200)
	await _frames(6)
	return current_scene if ok else null


func _etat_final(z, cas: String, gs, potions: int) -> void:
	_check(Progression.etat() == Progression.TUTORIAL_COMPLETED, cas + " : état tutorial_completed")
	_check(Progression.objectif() == "guilde_badge", cas + " : objectif « Se rendre à la Guilde »")
	_check(Vector2(z.s.hero.x, z.s.hero.y).distance_to(Vector2(26, 23.3)) < 0.5, cas + " : Aren dans l'arène, devant le commandant")
	_check(z.pnj_presents().has("commandant"), cas + " : commandant présent")
	_check(z.pnj_presents().has("chasseur_reussi"), cas + " : coursive peuplée (accès ouverts)")
	_check(not z._portes_fermees.has("grille_arene_est") and not z._portes_fermees.has("porte_sortie_est"), cas + " : grille est et porte de la ville ouvertes")
	var fin: bool = await _attendre(func(): return z.journal().any(func(e): return e["type"] == "dialogue" and e["dialogue"] == "commandant_fin"), 400)
	_check(fin, cas + " : dialogue de fin du commandant")
	_check(gs.potions == potions and gs.currency == 0 and gs.materials.is_empty(), cas + " : aucune récompense ni consommation")
	_check(gs.last_battle_result == "", cas + " : résultat consommé (pas de relance au prochain chargement)")
	while z._dialog.is_open():
		z._dialog.advance()
		await _frames(20)
	# reparler au commandant ne relance rien
	z.s.warp_to(Vector3(26, 22.4, 0))
	await _frames(4)
	z.parler("commandant")
	while z._dialog.is_open():
		z._dialog.advance()
		await _frames(20)
	await _frames(40)
	_check(current_scene == z and Progression.etat() == Progression.TUTORIAL_COMPLETED, cas + " : reparler au commandant ne relance pas le tutoriel")


func _vers_commandant(z) -> void:
	z.s.warp_to(Vector3(26, 23.4, 0))
	await _frames(4)
	z.parler("commandant")
	await _frames(4)


func _run() -> void:
	var gs = root.get_node("GameState")
	# --- 1. saut dans le dialogue
	gs.new_game("m", "")
	Progression.reinitialiser()
	Progression.definir(Progression.TUTORIAL_AVAILABLE)
	var potions: int = gs.potions
	change_scene_to_file(Progression.SCENE_COLISEE)
	var z = await _colisee_pret()
	await _vers_commandant(z)
	_check(z._dialog.is_open(), "dialogue du commandant ouvert")
	var vu_choix_saut := false
	for i in 60:
		if not z._dialog.is_open():
			break
		if z._dialog.showing_choice():
			var cs: Array = z._dialog._choices
			var idx := 0
			for k in cs.size():
				if cs[k].has("effet"):
					idx = k
					vu_choix_saut = true
			z._dialog.pick(idx)
		else:
			z._dialog.advance()
		await _frames(12)
	_check(vu_choix_saut, "le commandant propose « Passer le tutoriel »")
	scenes_vues.clear()
	var z1 = null
	for i in 3:
		await _frames(30)
		z1 = await _colisee_pret()
		if z1 != null and z1 != z:
			break
	_check(z1 != null and z1 != z, "retour au Colisée après le saut")
	_check(not scenes_vues.has(Progression.SCENE_TUTORIEL), "aucun combat chargé quand on passe le tutoriel dans le dialogue")
	if z1 != null:
		await _etat_final(z1, "saut (dialogue)", gs, potions)
	# --- 2. saut pendant le combat
	gs.new_game("m", "")
	Progression.reinitialiser()
	Progression.definir(Progression.TUTORIAL_AVAILABLE)
	potions = gs.potions
	change_scene_to_file(Progression.SCENE_COLISEE)
	z = await _colisee_pret()
	await _vers_commandant(z)
	for i in 60:
		if not z._dialog.is_open():
			break
		if z._dialog.showing_choice():
			var cs: Array = z._dialog._choices
			var idx := 0
			while idx < cs.size() and cs[idx].has("effet"):
				idx += 1
			z._dialog.pick(idx)
		else:
			z._dialog.advance()
		await _frames(12)
	var en_combat: bool = await _attendre(func(): return current_scene != null and current_scene.scene_file_path == Progression.SCENE_TUTORIEL and current_scene.get("guide") != null and current_scene.guide.visible, 1800)
	_check(en_combat, "« Commencer l'entraînement » lance le combat tutoriel")
	var c = current_scene
	_check(c._bouton_passer.visible, "bouton « Passer le tutoriel » visible")
	c._bouton_passer.pressed.emit()
	await _frames(3)
	_check(c._confirm_box.est_ouverte(), "confirmation demandée avant de passer")
	c._confirm_box._repondre(true)
	var mon = c.battle.get_combatant("commandant")
	await _frames(2)
	_check(mon.hp == mon.max_hp, "commandant intact après le saut")
	_check(c.battle.state != c.Battle.State.VICTORY and c.battle.state != c.Battle.State.DEFEAT, "ni victoire ni défaite")
	_check(c.trace().any(func(e): return e["type"] == "fin" and e["saute"]), "fin marquée « sautée » dans le déroulé")
	var z2 = null
	for i in 20:
		await _frames(30)
		if current_scene != null and current_scene.scene_file_path == Progression.SCENE_COLISEE:
			z2 = await _colisee_pret()
			break
	_check(z2 != null, "retour au Colisée après le saut en combat")
	if z2 != null:
		await _etat_final(z2, "saut (combat)", gs, potions)
	print("E2E P6 SAUT RÉSULTAT : %s (%d échec(s))" % ["RÉUSSI" if fails.is_empty() else "ÉCHEC", fails.size()])
	quit(0 if fails.is_empty() else 1)
