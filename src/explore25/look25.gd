extends RefCounted
## P3 — Palette de BLOCKOUT commune aux deux rendus (couleurs unies : aucune texture définitive) et éclairage de
## référence. A reproduit l'éclairage par un ombrage de faces (Lambert) avec la même lumière que B.

const COLORS := {
	"decor": Color(0.33, 0.39, 0.30),
	"sol0": Color(0.66, 0.61, 0.50),
	"terrasse": Color(0.74, 0.67, 0.53),
	"terrasse_face": Color(0.56, 0.50, 0.45),
	"escalier": Color(0.70, 0.64, 0.55),
	"eau": Color(0.20, 0.42, 0.60),
	"berge": Color(0.45, 0.38, 0.29),
	"pont": Color(0.55, 0.38, 0.23),
	"garde_corps": Color(0.42, 0.28, 0.17),
	"arbre_tronc": Color(0.38, 0.25, 0.16),
	"arbre": Color(0.23, 0.47, 0.24),
	"maison": Color(0.82, 0.76, 0.64),
	"maison_toit": Color(0.58, 0.27, 0.20),
	"haie": Color(0.19, 0.34, 0.19),
	"muret": Color(0.62, 0.57, 0.52),
	"mur": Color(0.56, 0.52, 0.48),
	"caisse": Color(0.58, 0.42, 0.25),
	"porte": Color(0.42, 0.44, 0.56),
	"borne": Color(0.66, 0.66, 0.72),
}
## Direction de la lumière (sens de propagation, repère Godot X, Y haut, Z = y du plan).
const LIGHT_DIR := Vector3(0.55, -1.0, -0.45)
const AMBIENT := 0.52
const DIFFUSE := 0.62


static func col(role: String) -> Color:
	return COLORS.get(role, Color(0.6, 0.6, 0.6))


## Ombrage de face pour A (normale en repère Godot).
static func shade(c: Color, n: Vector3) -> Color:
	var k := AMBIENT + DIFFUSE * maxf(0.0, n.normalized().dot(-LIGHT_DIR.normalized()))
	return Color(c.r * k, c.g * k, c.b * k, c.a)
