extends Node
## P5 — ouverture directe du combat dans le décor « forêt » (F6, sans argument de ligne de commande) :
## prototype (Aren, Ilya, Throné contre le Vorgane), groupe à gauche, monstre à droite, arène forêt.

func _ready() -> void:
	GameState.proto = true
	GameState.arena = "foret"
	get_tree().change_scene_to_file.call_deferred(GameState.SCENE_PROTO_BATTLE)
