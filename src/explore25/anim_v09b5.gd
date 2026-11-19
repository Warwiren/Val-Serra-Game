extends RefCounted
## Val'Serra — V09B.5 : cycles CANDIDATS de marche et de course d'Aren (profil droit seulement), essai réversible.
## N'écrase rien : Actor25 continue d'animer Aren (P4.8) et décide de la direction et de l'attente ; cette couche ne
## remplace l'image que lorsque Actor25 joue « walk_right ». Les autres directions et l'attente restent P4.8.
## Cadence liée à la distance réellement parcourue : un cycle de 8 images = la foulée mesurée sur les poses
## (art/tests/v09b5_aren/cadence_v09b5.json). Aucune compression de cadence en course : la course a son propre cycle.

const DIR := "res://art/tests/v09b5_aren/"
const FORMATS := ["96x112", "64x72"]
## V09B.6 : formats au gabarit P4.8 (128 × 96, sol en bas, 64 px de haut). « calque_64 » = poses V09B.5 RÉDUITES
## automatiquement (calque d'échelle, non dessiné) ; « dessin_64 » = emplacement des poses redessinées, chargé s'il
## existe. Mesures dans cadence_v09b6.json (tools/p49/v09b6_gabarit.py).
const DIR_B6 := "res://art/tests/v09b6_aren/"
## V09B.5 « 96x112_h64 » : MÊMES images 96 × 112 (PNG inchangés), affichées à une échelle uniforme qui ramène la
## silhouette à la hauteur d'Aren P4.8 (référence mesurée sur idle_right.png). Facteur = 64 / hauteur médiane mesurée.
const H64 := "96x112_h64"
const REF_P48 := "res://art/p45/chars/aren/idle_right.png"
var echelle_h64 := 1.0               # facteur d'affichage de la variante H64 (calculé au chargement)
var hauteur_ref_px := 0              # hauteur d'Aren P4.8 (px)
var hauteur_v5_px := 0               # hauteur médiane des poses de marche 96×112 (px)
const N := 8

var format := "96x112"
var formats: Array = []              # formats disponibles (FORMATS + formats V09B.6 présents)
var _dirs := {}                      # format -> dossier
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
		formats.append(f)
		for c in ["walk", "run"]:
			_dirs[c + "_" + f] = DIR + "%s_%s/" % [c, f]
		if f == "96x112":
			formats.append(H64)                 # juste après l'original, pour la comparaison directe (touche T)
			_cad["formats"][H64] = _cad["formats"]["96x112"]
			for c in ["walk", "run"]:
				_dirs[c + "_" + H64] = _dirs[c + "_96x112"]
	if FileAccess.file_exists(DIR_B6 + "cadence_v09b6.json"):
		var b6: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR_B6 + "cadence_v09b6.json"))
		for f in b6["formats"]:
			if ResourceLoader.exists(DIR_B6 + "%s/walk_right_0.png" % f):
				formats.append(f)
				_cad["formats"][f] = b6["formats"][f]
				for c in ["walk", "run"]:
					_dirs[c + "_" + f] = DIR_B6 + f + "/"
	for f in formats:
		for c in ["walk", "run"]:
			var arr: Array[Texture2D] = []
			for i in N:
				arr.append(load(_dirs[c + "_" + f] + "%s_right_%d.png" % [c, i]))
			_tex[c + "_" + f] = arr
	# facteur de la variante H64, mesuré : hauteur visible (rect utilisé) d'Aren P4.8 / médiane des 8 poses de marche
	hauteur_ref_px = (load(REF_P48) as Texture2D).get_image().get_used_rect().size.y
	var hs: Array = []
	for t in _tex["walk_96x112"]:
		var img := (t as Texture2D).get_image()
		hs.append(int(_cad["formats"]["96x112"]["ligne_sol_px"]) - img.get_used_rect().position.y)
	hs.sort()
	hauteur_v5_px = int(hs[hs.size() / 2])
	echelle_h64 = float(hauteur_ref_px) / float(hauteur_v5_px)


## mètres par pixel de texture du format courant (0,02 m, ou 0,02 × facteur pour la variante H64)
func pixel_m() -> float:
	return _pixel_m * (echelle_h64 if format == H64 else 1.0)


## mètres parcourus par un cycle complet (2 pas, 8 images) dans le format courant
func stride_m(c: String = "") -> float:
	var k := cycle if c == "" else c
	return float(_cad["formats"][format][k]["foulee_px"]) * pixel_m()


## recul dessiné du pied d'appui après l'image i (px), ou null (pas d'appui commun)
func recul_px(c: String, i: int) -> Variant:
	return _cad["formats"][format][c]["recul_pied_appui_px_par_image"][i]


## décalage vertical (pixels, +y vers le haut) qui pose la ligne de sol du format sur l'origine du corps, pour un
## Sprite3D centré placé à `sprite_y_m` (0,96 m : bas des images P4.8 de 96 px au sol)
func offset_px(sprite_y_m: float, tex: Texture2D) -> Vector2:
	var ground := float(_cad["formats"][format]["ligne_sol_px"])
	return Vector2(0.0, -(sprite_y_m / pixel_m() - (ground - tex.get_height() * 0.5)))


## hauteur visible du personnage (m), pour l'occlusion
func height_m() -> float:
	return float(_cad["formats"][format]["hauteur_perso_px"]) * pixel_m()


func toggle_format() -> void:
	format = formats[(formats.find(format) + 1) % formats.size()]


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
