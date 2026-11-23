extends SceneTree
## V09C.6 — portraits d'Ilya dans leurs VRAIS emplacements d'interface, pour comparer les trois jeux : P4.2 (actuel),
## V09C.5 et V09C.6 au cadrage serré (bascule Portraits.ilya_v09c / ilya_cadrage ; le code du dialogue et du
## combat n'est pas modifié). Captures :
##   - boîte de dialogue (src/proto/dialogue_box.gd, cadre 140 px) : Ilya parle, une capture par expression ;
##   - combat prototype (scenes/battle/battle_scene.tscn, GameState.proto) : cartes du groupe et frise d'initiative.
##   godot --path . --rendering-method forward_plus --resolution 1280x720 --script res://tools/p49/portraits_ui_v09c6.gd -- --out=<d>
const Portraits = preload("res://src/proto/portraits.gd")
const DialogueBox = preload("res://src/proto/dialogue_box.gd")
const EXPR := ["neutre", "determine", "souriant", "surpris", "inquiete", "concentre", "blesse"]
const JEUX := {"P42": [false, ""], "V09C5": [true, "v09c5"], "V09C6_serre": [true, "serre"]}
var out := "user://portraits_v09c6"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _snap(id: String) -> void:
	await _frames(3)
	root.get_texture().get_image().save_png(out.path_join(id + ".png"))


func _jeu(j: String) -> void:
	Portraits.ilya_v09c = JEUX[j][0]
	if JEUX[j][1] != "":
		Portraits.ilya_cadrage = JEUX[j][1]


func _run() -> void:
	# 1. dialogue : fond neutre, Aren à gauche, Ilya à droite (locutrice)
	for j in JEUX:
		await _jeu(j)
		var bg := ColorRect.new()
		bg.color = Color(0.12, 0.15, 0.15)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(bg)
		var box = DialogueBox.new()
		box.left_id = "heros"
		box.right_id = "compagnon_vif"
		root.add_child(box)
		await _frames(2)
		for e in EXPR:
			box.open([{"who": "compagnon_vif", "text": "Expression « %s » — même Ilya, cadre de dialogue réel." % e, "expr": e}], {"heros": {"name": "Aren"}, "compagnon_vif": {"name": "Ilya"}})
			await _frames(30)
			box.advance()                         # affiche la réplique entière
			await _snap("dialogue_%s_%s" % [j, e])
			box.visible = false
		box.queue_free()
		bg.queue_free()
		await _frames(2)
	# 2. combat prototype : cartes du groupe et frise d'initiative
	var gs := root.get_node("GameState")
	gs.set("proto", true)
	for j in JEUX:
		await _jeu(j)
		change_scene_to_file("res://scenes/battle/battle_scene.tscn")
		await _frames(90)
		await _snap("combat_%s" % j)
	Portraits.ilya_v09c = false
	Portraits.ilya_cadrage = "serre"
	quit()
