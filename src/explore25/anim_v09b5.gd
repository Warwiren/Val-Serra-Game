extends RefCounted
## Val'Serra — V09B.5 : cycles CANDIDATS de marche et de course d'Aren (profil droit seulement), essai réversible.
## N'écrase rien : Actor25 continue d'animer Aren (P4.8) et décide de la direction et de l'attente ; cette couche ne
## remplace l'image que lorsque Actor25 joue « walk_right ». Les autres directions et l'attente restent P4.8.
## Cadence liée à la distance réellement parcourue : un cycle de 8 images = la foulée mesurée sur les poses
## (art/tests/v09b5_aren/cadence_v09b5.json). Aucune compression de cadence en course : la course a son propre cycle.

const DIR := "res://art/tests/v09b5_aren/"
const FORMATS := ["96x112", "64x72"]
const N := 8

var format := "96x112"
var active := false                  # true : l'image affichée vient de V09B.5
var cycle := "walk"
var frame := 0
var phase := 0.0                     # position dans le cycle, 0..1
var _tex := {}                       # "walk_96x112" -> Array[Texture2D]
var _cad: Dictionary
var _pixel_m := 0.02


static func make() -> RefCounted:
	var a = load("res://src/explore25/anim_v09b5.gd").new()
	a._build()
	return a


func _build() -> void:
	_cad = JSON.parse_string(FileAccess.get_file_as_string(DIR + "cadence_v09b5.json"))
	_pixel_m = float(_cad["pixel_m"])
	for f in FORMATS:
		for c in ["walk", "run"]:
			var arr: Array[Texture2D] = []
			for i in N:
				arr.append(load(DIR + "%s_%s/%s_right_%d.png" % [c, f, c, i]))
			_tex[c + "_" + f] = arr


## mètres parcourus par un cycle complet (2 pas, 8 images) dans le format courant
func stride_m(c: String = "") -> float:
	var k := cycle if c == "" else c
	return float(_cad["formats"][format][k]["foulee_px"]) * _pixel_m


## décalage vertical (pixels, +y vers le haut) qui pose la ligne de sol du format sur l'origine du corps, pour un
## Sprite3D centré placé à `sprite_y_m` (0,96 m : bas des images P4.8 de 96 px au sol)
func offset_px(sprite_y_m: float, tex: Texture2D) -> Vector2:
	var ground := float(_cad["formats"][format]["ligne_sol_px"])
	return Vector2(0.0, -(sprite_y_m / _pixel_m - (ground - tex.get_height() * 0.5)))


## hauteur visible du personnage (m), pour l'occlusion
func height_m() -> float:
	return float(_cad["formats"][format]["hauteur_perso_px"]) * _pixel_m


func toggle_format() -> void:
	format = FORMATS[(FORMATS.find(format) + 1) % FORMATS.size()]


## base : l'Actor25 d'Aren, DÉJÀ avancé pour cette image ; moved_m : distance parcourue ; running : Maj tenue.
func step(base: RefCounted, moved_m: float, running: bool) -> void:
	if String(base.get("anim")) != "walk_right":
		active = false
		return
	cycle = "run" if running else "walk"
	if not active:
		phase = float(_cad["image_de_depart"]) / N          # départ : une jambe en passage, pas de glissement
	else:
		phase = fposmod(phase + moved_m / stride_m(), 1.0)
	active = true
	frame = int(phase * N) % N


func texture() -> Texture2D:
	return (_tex[cycle + "_" + format] as Array)[frame]
