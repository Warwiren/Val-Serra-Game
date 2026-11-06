extends Node
## Lanceurs d'essai pour l'ÉDITEUR (F6 sur la scène), sans options de ligne de commande :
##   essai_combat_lisiere.tscn   : combat direct sur l'arène illustrée « Lisière »
##   essai_parcours_clavier.tscn : parcours de locomotion au clavier simulé, mesures dans la console
## (la zone d'exploration elle-même se lance avec F5)

@export_enum("combat_lisiere", "parcours_clavier") var essai := "combat_lisiere"


func _ready() -> void:
	GameState.proto = true
	match essai:
		"combat_lisiere":
			GameState.arena = "lisiere"
			_go.call_deferred(GameState.SCENE_PROTO_BATTLE)
		"parcours_clavier":
			GameState.course = "manuel"
			_go.call_deferred(GameState.SCENE_EXPLORE_HD2D)
		_:
			_go.call_deferred(GameState.SCENE_EXPLORE_HD2D)


func _go(path: String) -> void:
	get_tree().change_scene_to_file(path)
