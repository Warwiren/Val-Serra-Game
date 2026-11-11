extends RefCounted
## Exécute tous les tests et renvoie un résumé. Utilisé par la ligne de commande ET par la scène de tests.

const TEST_FILES := [
	"res://tests/unit/test_timeline.gd",
	"res://tests/unit/test_rules.gd",
	"res://tests/unit/test_game.gd",
	"res://tests/unit/test_rig.gd",
	"res://tests/unit/test_sprites.gd",
	"res://tests/unit/test_ai_ui.gd",
	"res://tests/unit/test_explore.gd",
	"res://tests/unit/test_arena.gd",
	"res://tests/unit/test_p1_camera.gd",
	"res://tests/unit/test_p3_explore25.gd",
	"res://tests/unit/test_p307_camera.gd",
]


static func run_all() -> Dictionary:
	var lines: Array = []
	var total := 0
	var failed := 0
	for path in TEST_FILES:
		var script: GDScript = load(path)
		if script == null:
			lines.append("ÉCHEC  impossible de charger %s" % path)
			failed += 1
			continue
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			total += 1
			var inst = script.new()
			inst.current_test = name
			inst.call(name)
			if inst.failures.is_empty() and inst.checks > 0:
				lines.append("OK     %s :: %s" % [path.get_file(), name])
			else:
				failed += 1
				lines.append("ÉCHEC  %s :: %s" % [path.get_file(), name])
				if inst.checks == 0:
					lines.append("         - aucune vérification exécutée (erreur de script ?)")
				for f in inst.failures:
					lines.append("         - %s" % f)
	lines.append("")
	lines.append("%d test(s), %d réussi(s), %d échec(s)." % [total, total - failed, failed])
	return {"total": total, "failed": failed, "lines": lines}
