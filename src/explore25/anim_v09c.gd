extends RefCounted
## Val'Serra — V09C : BANC D'ESSAI d'Ilya (nouvelle apparence), réversible (touche I de la forêt). NON VALIDÉ.
## Images : art/tests/v09c_ilya/ (pack V09C.5 + marche droite du 19/11/2026, voir SOURCES.md). P4.8 intact.
## Comme pour Aren V09B.5 : Actor25 continue d'animer Ilya et décide de la direction et de l'attente ; cette couche
## remplace l'image par celle du pack (4 directions × attente / marche / course).
## - échelle d'affichage uniforme mesurée : hauteur de référence (64 px, Aren V09B.5 ×0,719) / hauteur médiane de la
##   marche droite livrée (le facteur ×0,719 d'Aren n'est PAS recopié) ;
## - cadence liée à la distance réellement parcourue (foulée mesurée, cadence_v09c.json) ;
## - Ilya n'a pas de touche Maj : la course se choisit d'après sa VITESSE RÉELLE, avec hystérésis (entrée au-delà de
##   60 % de l'écart marche → course du profil de vitesse, sortie sous 30 %) pour éviter le clignotement.

const DIR := "res://art/tests/v09c_ilya/"
## V09C.6 : course de profil droit candidate (art/tests/v09c6_ilya/), seule à changer ; le reste reste V09C.5.
const DIR6 := "res://art/tests/v09c6_ilya/"
const DIRS := ["right", "left", "face", "back"]
const N := 8
const ENTREE_COURSE := 0.6
const SORTIE_COURSE := 0.3

var active := false
var cycle := "idle"
var dir := "face"
var frame := 0
var phase := 0.0
var running := false
var echelle := 1.0
var hauteur_ref_px := 64
var hauteur_px := 89                 # hauteur médiane mesurée de la marche droite livrée
var _tex := {}                       # "walk_right" -> Array[Texture2D]
var _cad: Dictionary
var _pixel_m := 0.02
var course_v09c6 := false            # true : la course droite utilise les 8 poses V09C.6
## Profil unique (demande du créateur du 19/11/2026) : le profil droit (marche de la planche du 19/11, course V09C.5
## ou V09C.6) sert à toutes les directions — miroir vers la gauche, dernier profil gardé vers le haut / le bas ; à
## l'arrêt, pose tenue IMAGE_ARRET de la marche droite (même style ; l'attente du pack est d'un autre style). La vue
## gauche du pack reste dans le banc (profil_unique = false) ; face et dos : voir vues_face_dos.
var profil_unique := true
const IMAGE_ARRET := 2
## Haut / bas (demande du créateur du 20/11/2026) : en profil unique, vers le bas et vers le haut, les vues de FACE et
## de DOS dessinées du pack V09C.5 (marche, course, attente animée 8 images à l'arrêt) ; droite / gauche inchangées
## (profil, miroir). false : dernier profil gardé vers le haut / le bas (comportement du 19/11).
var vues_face_dos := true
var flip := false
var _axe := {}
var _arret := false
var _cad6: Dictionary


static func make() -> RefCounted:
	var a = load("res://src/explore25/anim_v09c.gd").new()
	a._build()
	return a


func _build() -> void:
	_cad = JSON.parse_string(FileAccess.get_file_as_string(DIR + "cadence_v09c.json"))
	_pixel_m = float(_cad["pixel_m"])
	hauteur_ref_px = int(_cad["hauteur_reference_px"])
	for d in DIRS:
		for c in ["idle", "walk", "run"]:
			var arr: Array[Texture2D] = []
			for i in N:
				arr.append(load(DIR + "exploration/%s/%s_%s_%d.png" % [d, c, d, i]))
			_tex[c + "_" + d] = arr
	_cad6 = JSON.parse_string(FileAccess.get_file_as_string(DIR6 + "cadence_v09c6.json"))
	var arr6: Array[Texture2D] = []
	for i in N:
		arr6.append(load(DIR6 + "exploration/right/run_right_%d.png" % i))
	_tex["run_right_v09c6"] = arr6
	for k in ["walk_right", "run_right", "run_right_v09c6", "walk_face", "run_face", "idle_face", "walk_back", "run_back", "idle_back"]:
		_axe[k] = load("res://src/explore25/anim_v09b5.gd").axe_tete(_tex[k])
	var hs: Array = []
	for t in _tex["walk_right"]:
		var img := (t as Texture2D).get_image()
		hs.append(int(_cad["directions"]["right"]["walk"]["ligne_sol_px"]) - img.get_used_rect().position.y)
	hs.sort()
	hauteur_px = int(hs[hs.size() / 2])
	echelle = float(hauteur_ref_px) / float(hauteur_px)


## mètres par pixel de texture
func pixel_m() -> float:
	return _pixel_m * echelle


## mètres parcourus par un cycle de 8 images (direction et cycle courants)
func stride_m(c: String = "", d: String = "") -> float:
	var cc := cycle if c == "" else c
	var dd := dir if d == "" else d
	if course_v09c6 and cc == "run" and dd == "right":
		return float(_cad6["run_right"]["foulee_px"]) * pixel_m()
	return float(_cad["directions"][dd][cc]["foulee_px"]) * pixel_m()


## true : l'image courante vient de la course V09C.6
func run_v09c6() -> bool:
	return course_v09c6 and cycle == "run" and dir == "right"


## recul dessiné du pied d'appui après l'image i (px) du cycle courant, ou null
func recul_px(i: int) -> Variant:
	if run_v09c6():
		return _cad6["run_right"]["recul_pied_appui_px_par_image"][i]
	return _cad["directions"][dir][cycle]["recul_pied_appui_px_par_image"][i]


## décalage vertical (px de texture, +y vers le haut) qui pose la ligne de sol de l'image sur l'origine du corps
func offset_px(sprite_y_m: float, tex: Texture2D) -> Vector2:
	var ground := float(_cad6["run_right"]["ligne_sol_px"]) if run_v09c6() else float(_cad["directions"][dir][cycle]["ligne_sol_px"])
	var ox := 0.0
	if profil_unique:
		var vk := cycle + "_" + dir if dir in ["face", "back"] else cycle + "_right"
		var ax: float = _axe["run_right_v09c6" if run_v09c6() else vk]
		ox = (ax - tex.get_width() * 0.5) if miroir() else (tex.get_width() * 0.5 - ax)
	return Vector2(ox, -(sprite_y_m / pixel_m() - (ground - tex.get_height() * 0.5)))


func height_m() -> float:
	return float(hauteur_px) * pixel_m()


## seuils de vitesse (m/s) d'entrée et de sortie de la course pour un profil [marche, course]
static func seuils(speeds: Array) -> Vector2:
	var w := float(speeds[0])
	var r := float(speeds[1])
	return Vector2(w + ENTREE_COURSE * (r - w), w + SORTIE_COURSE * (r - w))


## base : l'Actor25 d'Ilya, DÉJÀ avancé pour cette image ; moved_m : distance parcourue ; speed : vitesse réelle (m/s)
func step(base: RefCounted, moved_m: float, speed: float, speeds: Array, sx: float = 0.0) -> void:
	var parts := String(base.get("anim")).split("_")
	var d: String = parts[1] if parts.size() > 1 else "face"
	if profil_unique:
		if sx > 0.15:
			flip = false
		elif sx < -0.15:
			flip = true
		var vue := d if vues_face_dos and d in ["face", "back"] else "right"
		d = vue                               # droite / gauche : profil droit (retourné si flip) ; haut / bas : face / dos
		if parts[0] != "walk" and vue == "right":
			running = false
			cycle = "walk"
			frame = IMAGE_ARRET
			dir = d
			active = true
			_arret = true
			return
	else:
		flip = false
	if parts[0] == "walk":
		var s := seuils(speeds)
		if not running and speed > s.x:
			running = true
		elif running and speed < s.y:
			running = false
		var c := "run" if running else "walk"
		if not active or cycle == "idle" or _arret:
			phase = float(_cad["image_de_depart"]) / N           # départ : jambe en passage
		else:
			phase = fposmod(phase + moved_m / stride_m(c, d), 1.0)
		cycle = c
		frame = int(phase * N) % N
		_arret = false
	else:
		running = false
		cycle = "idle"
		frame = int(base.get("frame")) % N                    # attente : même rythme qu'Actor25 (4 i/s)
		_arret = true
	dir = d
	active = true


## true : afficher l'image en miroir (vers la gauche, en profil seulement ; face et dos jamais retournés)
func miroir() -> bool:
	return flip and dir == "right"


func texture() -> Texture2D:
	if run_v09c6():
		return (_tex["run_right_v09c6"] as Array)[frame]
	return (_tex[cycle + "_" + dir] as Array)[frame]
