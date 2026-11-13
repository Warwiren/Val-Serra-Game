extends RefCounted
## SOURCE UNIQUE des portraits de personnages (lot P1, addendum 10.1). Tous les contextes l'utilisent :
## cartes du groupe, frise d'initiative, sélection de cible (potion), dialogue. Aucun chemin de portrait
## ne doit être écrit ailleurs. Expressions : prévues pour le dialogue (Aren dispose des 6 de sa planche),
## les autres personnages n'ont qu'un portrait neutre pour l'instant (repli automatique sur « neutre »).

const DIR := "res://art/proto/"
## P4.4 : portraits du pack P4_2_COMBAT_PORTRAITS_v01 (Aren gris, Ilya verte, garde en armure).
const P44 := "res://art/p45/portraits/"            # P4.5 (garde du pack léger)
const PORTRAITS := {
	"heros": {
		"neutre": P44 + "aren/neutre.png", "determine": P44 + "aren/determine.png", "souriant": P44 + "aren/souriant.png",
		"surpris": P44 + "aren/surpris.png", "blesse": P44 + "aren/blesse.png", "concentre": P44 + "aren/concentre.png",
	},
	"compagnon_vif": {
		"neutre": P44 + "ilya/neutre.png", "determine": P44 + "ilya/determine.png", "souriant": P44 + "ilya/souriant.png",
		"surpris": P44 + "ilya/surpris.png", "blesse": P44 + "ilya/inquiete.png", "concentre": P44 + "ilya/resolue.png",
	},
	"compagnon_lourd": {"neutre": DIR + "portrait_throne.png"},
	"pnj": {"neutre": P44 + "garde/neutre.png"},
}


static func path(id: String, expression := "neutre") -> String:
	var set_: Dictionary = PORTRAITS.get(id, {})
	return set_.get(expression, set_.get("neutre", ""))


static func get_texture(id: String, expression := "neutre") -> Texture2D:
	var p := path(id, expression)
	return load(p) if p != "" else null
