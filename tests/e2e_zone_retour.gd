extends SceneTree
## Vérification de bout en bout du retour de combat dans la zone HD-2D (état de la rencontre).
##   godot --headless --path . --script res://tests/e2e_zone_retour.gd
## Simule exactement ce que la scène de combat écrit dans GameState à la fin (victoire, défaite), recharge la
## zone et contrôle : monstre visible ou non, solide ou non, pas de nouveau combat immédiat, groupe placé sur des
## positions libres, dialogue « après victoire ». Code de sortie 1 en cas d'échec.

const ZONE := "res://scenes/explore_hd2d/zone_hd2d.tscn"
var fails := []


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, msg: String) -> void:
	print(("OK     " if cond else "ÉCHEC  ") + msg)
	if not cond:
		fails.append(msg)


func _load_zone():
	change_scene_to_file(ZONE)
	for i in 3:
		await process_frame
	return current_scene


func _simulate_end(z, result: String) -> void:
	# même écriture que battle_scene.gd (_engage puis _show_result) ; la mécanique de combat n'est pas exécutée
	var gs = root.get_node("GameState")
	gs.from_zone = true
	gs.zone_return_pos = z.hero.position
	gs.explore_return = ZONE
	gs.last_battle_result = result
	if result == "victory":
		gs.enemy_defeated = true


func _run() -> void:
	var gs = root.get_node("GameState")
	gs.autoplay = false
	var z = await _load_zone()
	_check(z.monster.visible, "départ : le Vorgane est présent")
	# 1. Défaite (le monstre reste) : le héros revient AU CONTACT du monstre -> il ne doit pas relancer le combat
	z.hero.position = z.monster_pos + Vector2(z.monster_rx + 4, 2)
	_simulate_end(z, "defeat")
	z = await _load_zone()
	for i in 30:
		await process_frame
	_check(z.monster.visible and not gs.enemy_defeated, "après défaite : le Vorgane est toujours là")
	_check(not z._engaging, "après défaite : pas de nouveau combat immédiat")
	_check(not z.touches_monster(z.hero.position, z.monster_pos, z.monster_rx, z.monster_ry, z.ENGAGE_MARGIN), "après défaite : le groupe est replié hors de portée du monstre")
	for w in z.party:
		_check(z.free_at(w.position), "après défaite : %s sur une position libre" % w.key)
	_check(gs.last_battle_result == "" and not gs.from_zone, "après défaite : état de retour consommé")
	# 2. Victoire : le monstre disparaît, n'est plus solide, le héros revient où il était
	z.hero.position = z.monster_pos + Vector2(z.monster_rx + 4, 2)
	var pos: Vector2 = z.hero.position
	_simulate_end(z, "victory")
	z = await _load_zone()
	for i in 30:
		await process_frame
	_check(not z.monster.visible and gs.enemy_defeated, "après victoire : le Vorgane a disparu")
	_check(z.hero.position.distance_to(pos) < 1.0, "après victoire : retour à l'endroit du combat")
	_check(z.free_at(z.monster_pos + Vector2(4, 0)), "après victoire : on peut traverser l'emplacement du monstre")
	_check(not z._engaging, "après victoire : pas de combat")
	for w in z.party:
		_check(z.free_at(w.position), "après victoire : %s sur une position libre" % w.key)
	z.hero.position = z.npc.position + Vector2(-10, 4)
	_check(z._open_dialog(), "après victoire : dialogue possible près du garde")
	var data: Dictionary = JSON.parse_string(FileAccess.open(z.DIALOGUE, FileAccess.READ).get_as_text())
	_check(data.has("after_victory"), "après victoire : le garde utilise le dialogue « after_victory »")
	# 3. Rechargement simple (sans combat) : l'état persiste
	z = await _load_zone()
	_check(not z.monster.visible, "rechargement : le Vorgane reste vaincu")
	print("E2E RÉSULTAT : %s" % ("RÉUSSI" if fails.is_empty() else "ÉCHEC (%d)" % fails.size()))
	quit(0 if fails.is_empty() else 1)
