extends RefCounted
## Correspondance entre les identifiants du CombatCore et les illustrations.
## Coordonnées exprimées en pixels des fichiers SVG (voir les commentaires de chaque SVG).
## Remplacer un asset = changer un chemin ici (et éventuellement ses points d'ancrage).

const BODY_SIZE := Vector2(240, 320)
const BODY_FEET := Vector2(120, 306)

const WEAPONS := {
	"sabre":   {"path": "res://art/characters/weapon_sabre.svg",  "grip": Vector2(40, 252)},
	"dagger":  {"path": "res://art/characters/weapon_dagger.svg", "grip": Vector2(25, 112)},
	"hammer":  {"path": "res://art/characters/weapon_hammer.svg", "grip": Vector2(80, 262)},
}

const MONSTER := {
	"size": Vector2(600, 460),
	"feet": Vector2(300, 440),
	"body": "res://art/monster/body.svg",
	"portrait": "res://art/portraits/monster.svg",
	"parts": {
		"griffe":   {"intact": "res://art/monster/claw.svg",  "broken": "res://art/monster/claw_broken.svg",  "anchor": Vector2(150, 400), "z": 2},
		"carapace": {"intact": "res://art/monster/plate.svg", "broken": "res://art/monster/plate_broken.svg", "anchor": Vector2(350, 128), "z": 1},
		"glande":   {"intact": "res://art/monster/gland.svg", "broken": "res://art/monster/gland_broken.svg", "anchor": Vector2(205, 292), "z": 3},
	},
}


## Définition visuelle d'un Chasseur du CombatCore.
static func hunter(id: String, hero_gender := "m") -> Dictionary:
	match id:
		"heros":
			return {"body": "res://art/characters/hero_%s.svg" % hero_gender,
				"portrait": "res://art/portraits/hero_%s.svg" % hero_gender,
				"weapon": "sabre", "hand": Vector2(170, 176), "rest": 35.0, "swing": 120.0}
		"compagnon_vif":
			return {"body": "res://art/characters/comp_a.svg", "portrait": "res://art/portraits/comp_a.svg",
				"weapon": "dagger", "hand": Vector2(172, 170), "rest": 70.0, "swing": 70.0,
				"weapon2": "dagger", "hand2": Vector2(94, 182), "rest2": 40.0}
		"compagnon_lourd":
			return {"body": "res://art/characters/comp_b.svg", "portrait": "res://art/portraits/comp_b.svg",
				"weapon": "hammer", "hand": Vector2(168, 182), "rest": -28.0, "swing": 150.0}
	return {}


## Couleurs de l'interface (palette Val'Serra provisoire).
const C_HUNTER := Color("#8ec9ff")
const C_MONSTER := Color("#ff8a7a")
const C_AETHER := Color("#5fe3ff")
const C_GOLD := Color("#ffd27a")
const C_HP := Color("#7fd67a")
const C_HP_LOW := Color("#e8604c")
const C_PANEL := Color(0.06, 0.08, 0.11, 0.86)
const C_PANEL_EDGE := Color(0.55, 0.7, 0.78, 0.35)
const C_TEXT := Color("#e8eef2")
const C_DIM := Color("#8d98a3")
