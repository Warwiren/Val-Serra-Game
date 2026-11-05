extends RefCounted
## SOURCE UNIQUE des portraits de personnages (lot P1, addendum 10.1). Tous les contextes l'utilisent :
## cartes du groupe, frise d'initiative, sélection de cible (potion), dialogue. Aucun chemin de portrait
## ne doit être écrit ailleurs. Expressions : prévues pour le dialogue (Aren dispose des 6 de sa planche),
## les autres personnages n'ont qu'un portrait neutre pour l'instant (repli automatique sur « neutre »).

const DIR := "res://art/proto/"
const PORTRAITS := {
	"heros": {
		"neutre": DIR + "aren2/portrait_neutre.png", "determine": DIR + "aren2/portrait_determine.png",
		"souriant": DIR + "aren2/portrait_souriant.png", "surpris": DIR + "aren2/portrait_surpris.png",
		"blesse": DIR + "aren2/portrait_blesse.png", "concentre": DIR + "aren2/portrait_concentre.png",
	},
	"compagnon_vif": {"neutre": DIR + "portrait_ilya.png"},
	"compagnon_lourd": {"neutre": DIR + "portrait_throne.png"},
	"pnj": {"neutre": DIR + "portrait_pnj.png"},
}


static func path(id: String, expression := "neutre") -> String:
	var set_: Dictionary = PORTRAITS.get(id, {})
	return set_.get(expression, set_.get("neutre", ""))


static func get_texture(id: String, expression := "neutre") -> Texture2D:
	var p := path(id, expression)
	return load(p) if p != "" else null
