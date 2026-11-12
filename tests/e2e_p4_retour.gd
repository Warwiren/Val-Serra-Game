extends SceneTree
## P4 — vérification de bout en bout de la rencontre dans l'avant-poste :
##   godot --headless --path . --script res://tests/e2e_p4_retour.gd
## 1. approche du Vorgane -> le combat se déclenche et la scène de combat se charge réellement ;
## 2. fin de combat simulée (mêmes écritures que battle_scene.gd) : victoire -> retour à l'endroit du combat, le
##    Vorgane a disparu, le garde change de répliques ; défaite -> retour à l'entrée, le Vorgane reste, pas de
##    nouveau combat immédiat ; 3. entrée dans le bâtiment et retour. Code de sortie 1 en cas d'échec.

const ZONE := "res://scenes/p4/avant_poste.tscn"
const BATTLE := "res://scenes/battle/battle_scene.tscn"
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


func _load_zone():
	change_scene_to_file(ZONE)
	for i in 4:
		await process_frame
	await _frames(4)
	return current_scene


func _run() -> void:
	var gs = root.get_node("GameState")
	gs.autoplay = false
	var z = await _load_zone()
	_check(z.monster_present(), "départ : le Vorgane est présent dans la plaine")
	_check(z.s.hero.distance_to(z.world.spawn) < 0.1, "départ : le groupe est à l'entrée de la cour")
	# 1. approche : le combat se déclenche au contact et la scène de combat se charge
	var mc: Array = z._monster_cfg["xy"]
	z.s.warp_to(Vector3(mc[0] - 3.0, mc[1] + 0.4, 0))
	await _frames(20)
	_check(not z._engaging, "à 3 m du Vorgane : pas encore de combat")
	z.s.warp_to(Vector3(mc[0] - 1.5, mc[1] + 0.2, 0))
	var here: Vector3 = z.s.hero
	await _frames(10)
	_check(z._engaging, "au contact du Vorgane : le combat se déclenche")
	var t := 0
	while (current_scene == null or current_scene.scene_file_path != BATTLE) and t < 600:
		await process_frame
		t += 1
	_check(current_scene != null and current_scene.scene_file_path == BATTLE, "la scène de combat est chargée")
	_check(gs.from_zone and gs.explore_return == ZONE, "le combat sait revenir à l'avant-poste P4")
	_check(gs.use_pilot_arena(), "le combat utilise l'arène illustrée")
	var bs = current_scene
	var mon = bs.battle.get_combatant(bs.monster_id)
	_check(mon.max_hp == 475 and mon.hp == 475, "démo : PV du Vorgane divisés par deux (%d / 950)" % mon.max_hp)
	_check(not gs.flags.has("rencontre_pv_mult"), "multiplicateur consommé : les autres combats gardent 950 PV")
	for i in 10:
		await process_frame
	# 2a. victoire (écritures de battle_scene._show_result), puis retour
	gs.enemy_defeated = true
	gs.last_battle_result = "victory"
	z = await _load_zone()
	await _frames(20)
	_check(not z.monster_present() and gs.enemy_defeated, "après victoire : le Vorgane a disparu")
	_check(Vector2(z.s.hero.x, z.s.hero.y).distance_to(Vector2(here.x, here.y)) < 3.0, "après victoire : retour près du lieu du combat")
	_check(not z.world.stand(Vector2(z.s.hero.x, z.s.hero.y), z.s.hero.z).is_empty(), "après victoire : héros sur une position tenable")
	_check(not z._engaging, "après victoire : pas de nouveau combat")
	_check(gs.last_battle_result == "" and not gs.from_zone, "après victoire : état de retour consommé")
	z.s.warp_to(Vector3(mc[0], mc[1] + 0.3, 0))
	await _frames(10)
	_check(not z._engaging and not z.world.stand(Vector2(mc[0], mc[1] + 0.3), 0.0).is_empty(), "après victoire : l'emplacement du monstre se traverse")
	var np: Vector3 = z.world.npc["p"]
	z.s.warp_to(Vector3(np.x - 1.0, np.y + 0.5, 0))
	await _frames(4)
	z.s.interact()
	_check(z.dialogue_is_open(), "après victoire : dialogue à portraits avec le garde")
	z._dialog.close()
	await _frames(30)
	_check(not z.s.dialogue_open, "dialogue fermé : déplacement rendu")
	# 2b. défaite : retour à l'entrée, monstre toujours là
	gs.enemy_defeated = false
	gs.from_zone = true
	gs.explore_return = ZONE
	gs.last_battle_result = "defeat"
	z = await _load_zone()
	await _frames(30)
	_check(z.monster_present() and not gs.enemy_defeated, "après défaite : le Vorgane est toujours là")
	_check(z.s.hero.distance_to(z.world.spawn) < 0.5, "après défaite : le groupe est replié à l'entrée")
	_check(not z._engaging, "après défaite : pas de nouveau combat immédiat")
	# 3. bâtiment : entrée, puis sortie
	var tr: Dictionary = z.world.triggers[0]
	var c: Vector2 = (tr["rect"] as Rect2).get_center()
	z.s.warp_to(Vector3(c.x, c.y + 0.8, 1.2))
	await _frames(6)
	z.s.warp_to(Vector3(c.x, c.y + 0.1, 1.2))
	t = 0
	while not z.world.adj.get("p4", {}).get("interieur", false) and t < 240:
		await physics_frame
		t += 1
	_check(z.world.adj.get("p4", {}).get("interieur", false), "porte du bâtiment : l'intérieur se charge")
	_check(not z.monster_present(), "intérieur : pas de monstre")
	await _frames(40)
	var back: Dictionary = z.world.triggers[0]
	var bc: Vector2 = (back["rect"] as Rect2).get_center()
	z.s.warp_to(Vector3(bc.x, bc.y - 0.1, 0))
	t = 0
	while z.world.adj.get("p4", {}).get("interieur", false) and t < 240:
		await physics_frame
		t += 1
	await _frames(40)
	_check(not z.world.adj.get("p4", {}).get("interieur", false), "sortie de l'intérieur : retour à l'avant-poste")
	_check(z.s.hero_region == "terrasse" and absf(z.s.hero.z - 1.2) < 0.05, "retour extérieur : sur la terrasse, devant la porte")
	_check(z.monster_present(), "retour extérieur : le Vorgane est toujours dans la plaine")
	print("E2E P4 RÉSULTAT : %s" % ("RÉUSSI" if fails.is_empty() else "ÉCHEC (%d)" % fails.size()))
	quit(0 if fails.is_empty() else 1)
