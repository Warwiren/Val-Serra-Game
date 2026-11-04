extends Control
## Scène de tests pour l'éditeur : ouvrir tests/test_runner.tscn puis appuyer sur F6.

const TestSuite = preload("res://tests/test_suite.gd")


func _ready() -> void:
	var label := RichTextLabel.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.bbcode_enabled = true
	label.add_theme_font_size_override("normal_font_size", 15)
	add_child(label)
	var result: Dictionary = TestSuite.run_all()
	var color := "#7CFC9A" if result["failed"] == 0 else "#FF7A7A"
	label.append_text("[b]Tests du CombatCore[/b]\n\n")
	for line in result["lines"]:
		print(line)
		var c := "#FF7A7A" if String(line).begins_with("ÉCHEC") or String(line).begins_with("   ") else "#DDDDDD"
		label.append_text("[color=%s]%s[/color]\n" % [c, line])
	label.append_text("\n[color=%s][b]%s[/b][/color]" % [color, "TOUT EST VERT" if result["failed"] == 0 else "DES TESTS ÉCHOUENT"])
