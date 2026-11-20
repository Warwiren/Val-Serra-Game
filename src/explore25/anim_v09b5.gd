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
## Profil unique (demande du créateur du 19/11/2026 : même apparence dans toutes les directions) : le profil droit
## V09B.5 sert à TOUTES les directions — miroir horizontal vers la gauche ; vers le haut ou le bas, Aren garde son
## dernier profil ; à l'arrêt, pose tenue IMAGE_ARRET de la marche (jambes rassemblées ; aucune attente V09B.5 n'est
## dessinée). Aucun dessin ajouté : seulement des images existantes, retournées ou tenues.
var profil_unique := true
const IMAGE_ARRET := 2
var flip := false                    # true : profil gauche (miroir du profil droit)
var _bouge := false
## Aren V2 (planche « Animations de déplacement V2 », 20/11/2026) : vues de FACE et de DOS dans le même design, pour
## distinguer les déplacements vers le bas et vers le haut (art/tests/aren_v2/, préparées sans redessin). Utilisées
## en profil unique avec les formats 96 × 112 (même densité de pixels) ; arrêt après un déplacement vers le bas :
## attente de face V2 (8 images) ; vers le haut : pose de dos tenue IMAGE_ARRET_DOS. Pas de course de face / dos
## dessinée : vers le haut ou le bas en courant, le cycle de marche V2 est joué au rythme de la distance.
const DIR_V2 := "res://art/tests/aren_v2/"
const IMAGE_ARRET_DOS := 4
var vues_v2 := true                  # false : vers le haut / le bas, dernier profil gardé (comportement du 19/11)
var v2_dispo := false
## Jeu complet d'orientations (20/11/2026, art/tests/aren_4dir/) : attentes de l'étude IDLE V1 (profil, face, dos,
## mêmes proportions que V09B.5) et marches / courses de face et de dos PROCÉDURALES dérivées de ces attentes
## (tools/p49/aren_orientations.py). Prioritaire sur V2 ; « v2 » rétablit la planche V2 du 20/11.
const DIR_4D := "res://art/tests/aren_4dir/"
var jeu_vues := "4dir"               # « 4dir » ou « v2 »
var d4_dispo := false
var vue := "profil"                  # profil, face ou dos
var _cle := ""                       # jeu d'images affiché
var _axe := {}                       # cycle_format -> axe vertical de la tête (px de texture), médiane du cycle


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
	if ResourceLoader.exists(DIR_4D + "walk_face_0.png"):
		d4_dispo = true
		for c in ["walk_face", "walk_back", "run_face", "run_back", "idle_face", "idle_back", "idle_right"]:
			var arr: Array[Texture2D] = []
			for i in (4 if c.begins_with("idle") else N):
				arr.append(load(DIR_4D + "%s_%d.png" % [c, i]))
			_tex["d4_" + c] = arr
	if ResourceLoader.exists(DIR_V2 + "walk_face_0.png"):
		v2_dispo = true
		for c in ["walk_face", "walk_back", "idle_face"]:
			var arr: Array[Texture2D] = []
			for i in N:
				arr.append(load(DIR_V2 + "%s_%d.png" % [c, i]))
			_tex["v2_" + c] = arr
	for k in _tex:
		_axe[k] = axe_tete(_tex[k])


## axe vertical de la tête d'un cycle : médiane, sur les 8 images, du x médian des pixels opaques du quart supérieur
static func axe_tete(frames: Array) -> float:
	var xs: Array = []
	for t in frames:
		var img := (t as Texture2D).get_image()
		var u := img.get_used_rect()
		var px: Array = []
		for y in range(u.position.y, u.position.y + int(u.size.y * 0.25)):
			for x in range(u.position.x, u.end.x):
				if img.get_pixel(x, y).a > 0.5:
					px.append(x)
		px.sort()
		xs.append(float(px[px.size() / 2]) + 0.5)
	xs.sort()
	return xs[xs.size() / 2]

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
	var ox := 0.0
	if profil_unique:                   # axe de la tête sur l'origine du corps, à droite comme en miroir
		var ax: float = _axe[_cle if _cle != "" else cycle + "_" + format]
		ox = (ax - tex.get_width() * 0.5) if flip else (tex.get_width() * 0.5 - ax)
	return Vector2(ox, -(sprite_y_m / pixel_m() - (ground - tex.get_height() * 0.5)))


## hauteur visible du personnage (m), pour l'occlusion
func height_m() -> float:
	return float(_cad["formats"][format]["hauteur_perso_px"]) * pixel_m()


func toggle_format() -> void:
	format = formats[(formats.find(format) + 1) % formats.size()]


## base : l'Actor25 d'Aren, DÉJÀ avancé pour cette image ; moved_m : distance parcourue ; running : Maj tenue.
## les vues V2 (face, dos) ne servent qu'aux formats de même densité (96 × 112, affiché ×1 ou ×0,719)
func vues_v2_actives() -> bool:
	return profil_unique and vues_v2 and (format == "96x112" or format == H64) and (
		(jeu_vues == "4dir" and d4_dispo) or (jeu_vues == "v2" and v2_dispo))


func step(base: RefCounted, moved_m: float, running: bool, sx: float = 0.0) -> void:
	if profil_unique:
		if sx > 0.15:
			flip = false
		elif sx < -0.15:
			flip = true
		var parts := String(base.get("anim")).split("_")
		var d: String = parts[1] if parts.size() > 1 else "right"
		vue = "profil"
		if vues_v2_actives() and d == "face":
			vue = "face"
		elif vues_v2_actives() and d == "back":
			vue = "dos"
		active = true
		var d4 := jeu_vues == "4dir" and d4_dispo and (format == "96x112" or format == H64)
		if parts[0] != "walk":
			_bouge = false
			cycle = "walk"
			if d4:                           # attentes de l'étude (4 images, ≈ 0,5 s chacune) dans la dernière vue
				_cle = {"face": "d4_idle_face", "dos": "d4_idle_back"}.get(vue, "d4_idle_right")
				frame = int(int(base.get("frame")) / 2) % 4
			elif vue == "face":              # V2 : attente de face
				_cle = "v2_idle_face"
				frame = int(base.get("frame")) % N
			elif vue == "dos":               # V2 : pose de dos tenue
				_cle = "v2_walk_back"
				frame = IMAGE_ARRET_DOS
			else:                            # profil : pose tenue de la marche
				_cle = "walk_" + format
				frame = IMAGE_ARRET
			return
		cycle = "run" if running else "walk"
		if not _bouge:
			phase = float(_cad["image_de_depart"]) / N
		elif vue == "profil":
			phase = fposmod(phase + moved_m / stride_m(), 1.0)
		elif d4:                             # face / dos procéduraux : même foulée que le profil -> même cadence
			phase = fposmod(phase + moved_m / stride_m(), 1.0)
		else:                                # V2 : cycle de marche, foulée de la marche
			phase = fposmod(phase + moved_m / stride_m("walk"), 1.0)
		_bouge = true
		if vue == "profil":
			_cle = cycle + "_" + format
		elif d4:
			_cle = "d4_%s_%s" % [cycle, "face" if vue == "face" else "back"]
		else:
			_cle = "v2_walk_face" if vue == "face" else "v2_walk_back"
		frame = int(phase * N) % N
		return
	_cle = ""
	flip = false
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
	return (_tex[_cle if _cle != "" else cycle + "_" + format] as Array)[frame]


## miroir à appliquer : seulement aux vues de profil
func miroir() -> bool:
	return flip and vue == "profil"
