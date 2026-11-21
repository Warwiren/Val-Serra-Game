extends RefCounted
## P6 — PROGRESSION DE L'OUVERTURE (Colisée de Val'Serra) : états explicites et objectif courant.
## Tout est rangé dans GameState.flags (dictionnaire de valeurs simples : chaînes, nombres) pour être conservé tel quel
## par le futur système de sauvegarde (aucune référence à un nœud, aucune donnée dérivée).
##
##   intro_not_started   — Aren dans les vestiaires, rien n'a encore été dit
##   tutorial_available  — le garde des vestiaires a donné la consigne (ou Aren a quitté les vestiaires)
##   tutorial_in_progress— le combat tutoriel est lancé
##   tutorial_completed  — le commandant a terminé l'évaluation : coursive et sortie est ouvertes
##   coliseum_exited     — Aren a quitté le Colisée par l'est : le retour est fermé (réouverture prévue plus tard)
##
## Les états sont ORDONNÉS : `au_moins(etat)` répond « l'histoire a-t-elle atteint cet état ? ».

const INTRO_NOT_STARTED := "intro_not_started"
const TUTORIAL_AVAILABLE := "tutorial_available"
const TUTORIAL_IN_PROGRESS := "tutorial_in_progress"
const TUTORIAL_COMPLETED := "tutorial_completed"
const COLISEUM_EXITED := "coliseum_exited"
const ORDRE := [INTRO_NOT_STARTED, TUTORIAL_AVAILABLE, TUTORIAL_IN_PROGRESS, TUTORIAL_COMPLETED, COLISEUM_EXITED]

const CLE_ETAT := "intro_colisee"
const CLE_OBJECTIF := "objectif"
## Réouverture ultérieure du Colisée (événement futur) : quand ce drapeau vaut true, la porte du quartier rouvre.
const CLE_COLISEE_ROUVERT := "colisee_rouvert"

const SCENE_COLISEE := "res://scenes/p6/colisee.tscn"
const SCENE_TUTORIEL := "res://scenes/battle/combat_tutoriel.tscn"
const RESULTAT_TUTORIEL := "tutorial_completed"     # résultat de combat distinct de "victory" / "defeat"

const OBJECTIFS := {
	"rejoindre_arene": "Rejoindre l'arène",
	"parler_commandant": "Parler au commandant, au centre de l'arène",
	"guilde_badge": "Se rendre à la Guilde pour récupérer son badge",
}


## GameState (autoload) atteint par l'arbre : ce script reste compilable dans les outils lancés avec --script,
## où l'identifiant global de l'autoload n'existe pas encore à la compilation.
static func _gs() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("GameState")


static func etat() -> String:
	return str(_gs().flags.get(CLE_ETAT, INTRO_NOT_STARTED))


static func rang(e: String) -> int:
	return ORDRE.find(e)


static func au_moins(e: String) -> bool:
	return rang(etat()) >= rang(e)


## Change l'état. Par défaut, ne recule jamais (un dialogue relu ne ramène pas l'histoire en arrière) ;
## `force` sert aux retours en arrière explicites (tutoriel interrompu, outils de test).
static func definir(e: String, force := false) -> void:
	assert(ORDRE.has(e), "état de progression inconnu : " + e)
	if force or rang(e) > rang(etat()):
		_gs().flags[CLE_ETAT] = e


static func objectif() -> String:
	return str(_gs().flags.get(CLE_OBJECTIF, ""))


static func objectif_texte() -> String:
	return OBJECTIFS.get(objectif(), "")


static func definir_objectif(cle: String) -> void:
	assert(cle == "" or OBJECTIFS.has(cle), "objectif inconnu : " + cle)
	_gs().flags[CLE_OBJECTIF] = cle


## Remise à zéro de l'ouverture (nouvelle partie, tests).
static func reinitialiser() -> void:
	_gs().flags.erase(CLE_ETAT)
	_gs().flags.erase(CLE_OBJECTIF)
	_gs().flags.erase(CLE_COLISEE_ROUVERT)


## Instantané sérialisable (sauvegarde, rapport de test).
static func instantane() -> Dictionary:
	return {CLE_ETAT: etat(), CLE_OBJECTIF: objectif(), CLE_COLISEE_ROUVERT: _gs().flags.get(CLE_COLISEE_ROUVERT, false)}
