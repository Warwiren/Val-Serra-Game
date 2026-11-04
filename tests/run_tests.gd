extends SceneTree
## Lancement en ligne de commande :
##   godot --headless --path . --script res://tests/run_tests.gd
## Code de sortie 0 si tout passe, 1 sinon.

const TestSuite = preload("res://tests/test_suite.gd")


func _initialize() -> void:
	var result: Dictionary = TestSuite.run_all()
	for line in result["lines"]:
		print(line)
	quit(1 if result["failed"] > 0 else 0)
