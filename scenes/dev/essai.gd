extends Node
## Lanceurs d'essai pour l'ÉDITEUR (F6 sur la scène), sans options de ligne de commande :
##   essai_combat_lisiere.tscn   : combat avec le décor pilote « Lisière » (F2 : ancien / nouveau)
##   essai_combat_ancien.tscn    : même combat avec le décor actuel
##   essai_parcours_clavier.tscn : parcours de locomotion au clavier simulé, mesures dans la console
##   essai_zone_hd2d.tscn        : zone d'exploration HD-2D (combat au contact : décor pilote)

@export_enum("combat_lisiere", "combat_ancien", "parcours_clavier", "zone_hd2d") var essai := "zone_hd2d"


func _ready() -> void:
	GameState.proto = true
	match essai:
		"combat_lisiere", "combat_ancien":
			GameState.arena = "lisiere" if essai == "combat_lisiere" else "ancien"
			_go.call_deferred(GameState.SCENE_PROTO_BATTLE)
		"parcours_clavier":
			GameState.course = "manuel"
			_go.call_deferred(GameState.SCENE_EXPLORE_HD2D)
		_:
			_go.call_deferred(GameState.SCENE_EXPLORE_HD2D)


func _go(path: String) -> void:
	get_tree().change_scene_to_file(path)
