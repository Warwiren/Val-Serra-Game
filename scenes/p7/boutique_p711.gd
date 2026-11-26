extends RefCounted
## P7.11 — BOUTIQUE DE FOURNITURES, passe artistique (référence de qualité : forge D de P7.10.1). Même emprise
## (x 76 -> 88, y 76 -> 88), même collision (bloc des données), même entrée fonctionnelle (x 78, piédroits à collision
## x 76,65 -> 77,1 et 78,9 -> 79,35, saillie 0,35) et même examen ; maison haute et étroite de trois niveaux conservée.
## Identité propre (la forge est une masse de pierre basse) :
##   * rez-de-chaussée de pierre chaude maçonné en épaisseur (0,45 m) ; DEVANTURE de bois peint vert sur l'entrée : poteaux
##     (= piédroits à collision), bandeau d'enseigne à filet doré et emblème, corniche ; porte vitrée à deux vantaux en
##     embrasure (0,8 m), imposte éclairée à grille ; seuil et dalle sur le caniveau ;
##   * étages en PAN DE BOIS sur ENCORBELLEMENT (0,4 m, sur consoles) : poteaux, sablières, décharges en croix, hourdis
##     enduits miel ; croisées en retrait, volets verts, appuis ; pignon sur rue en pan de bois, planches de rive, lucarne,
##     potence de grenier et porte de chargement ;
##   * toit de tuiles canal (texture Quaternius, matière tuiles_p7101) plus brun que la forge ; souche de pierre ;
##   * enseigne pendante au flacon (fournitures, potions) à l'angle, lisible depuis la place ; lanterne.
## Occultation : l'étal (seule collision ajoutée en P7.10) quitte le pied du mur de bat_commerce_e2, qui le cachait depuis
## l'est de la place, pour l'angle ouest de la boutique (devant le socle du palier, hors des circulations), même mobilier ;
## toit et éléments en saillie rattachés au volume d'escamotage de la boutique (meta « vol »).

const Archi := preload("res://scenes/p7/archi_p77.gd")
const Refonte := preload("res://scenes/p7/forge_p7101.gd")
const TUILES_SH := preload("res://src/p7/tuiles_p7101.gdshader")
const R := Rect2(76.0, 76.0, 12.0, 12.0)
const H0 := 3.5
const N1 := 7.0                       # plancher du premier étage (encorbellement)
const N2 := 9.9
const N3 := 12.4                      # sablière haute
const EP := 0.45                      # épaisseur du rez-de-chaussée maçonné
const ENC := 0.4                      # saillie de l'encorbellement (sud)
const ETAL := Rect2(73.9, 88.05, 2.55, 1.0)
const VOL := "bat_boutique_fournitures"
const PORTE := {"u0": 1.1, "u1": 2.9, "bas": 3.5, "haut": 6.0}
const TOIT_KY := 0.7

var sc
var a
var fo
var m := {}
var _depuis := 0


func _init(scene, archi, forge) -> void:
	sc = scene
	a = archi
	fo = forge


func batiment() -> void:
	var ref = Refonte.new(fo)
	ref._matieres()
	m = ref.m
	_matieres()
	_depuis = a.racine.get_child_count()
	var d0: int = a.racine.get_child_count()
	_corps()
	_rdc_sud()
	_devanture()
	_rdc_ouest()
	_encorbellement()
	_pan_de_bois_sud()
	_etages_ouest()
	_potence()
	_enseigne()
	_cheminee()
	_etal_bois()
	a.fusionner(d0, "boutique_p711")
	var d1: int = a.racine.get_child_count()
	_pignons()
	a.fusionner(d1, "boutique_p711_pignons")
	_modeles()
	_toit()
	_rattacher()


# ------------------------------------------------------------------------------------------------ matières
func _matieres() -> void:
	var pal: Array = Archi.PALETTES["miel"]
	m["enduit"] = a.enduit(pal[0], N1, N3 + 4.0)
	# hourdis de la façade sur rue (souvent à l'ombre) : même miel, un peu plus chaud
	m["enduit_sud"] = a.enduit(Color(0.97, 0.82, 0.58), N1, N3 + 4.0)
	m["vert"] = a.plein(Color(0.16, 0.27, 0.21), 0.7)
	m["vert_clair"] = a.plein(Color(0.22, 0.37, 0.29), 0.75)
	m["volet"] = a.plein(pal[1], 0.85)
	m["volet_s"] = a.plein((pal[1] as Color).darkened(0.25), 0.85)
	m["or"] = a.plein(Color(0.78, 0.60, 0.26), 0.35, 0.0, 0.6)
	m["chene"] = a.plein(Color(0.26, 0.17, 0.11), 0.9)
	m["chene_c"] = a.plein(Color(0.31, 0.21, 0.13), 0.9)
	m["vitre"] = a.plein(Color(0.20, 0.24, 0.27), 0.2, 0.0, 0.35)
	m["vitre_chaude"] = a.plein(Color(0.98, 0.70, 0.38), 0.5, 0.9)
	m["vitre_douce"] = a.plein(Color(0.85, 0.58, 0.32), 0.5, 0.5)
	m["toile_v"] = a.plein(Color(0.25, 0.44, 0.30))
	m["toile_c"] = a.plein(Color(0.86, 0.82, 0.70))
	m["flacon"] = a.plein(Color(0.20, 0.62, 0.42), 0.25, 0.35, 0.1)
	m["bouchon"] = a.plein(Color(0.52, 0.36, 0.22))
	m["panneau"] = a.plein(Color(0.86, 0.80, 0.64))


# ------------------------------------------------------------------------------------------------ outils
func _f(cote: String) -> Dictionary:
	return Archi.face(R, cote)


func _b(f: Dictionary, u0: float, u1: float, v0: float, v1: float, d0: float, d1: float, mt: Material) -> MeshInstance3D:
	return a.boite(f, u0, u1, v0, v1, d0, d1, mt)


## Mur percé d'ouvertures rectangulaires [u0, u1, bas, haut] (bandes verticales découpées).
func _mur_perce(f: Dictionary, u0: float, u1: float, v0: float, v1: float, d0: float, d1: float, ouv: Array, mt: Material) -> void:
	var xs := [u0, u1]
	for o in ouv:
		xs.append(float(o[0]))
		xs.append(float(o[1]))
	xs.sort()
	for i in xs.size() - 1:
		var xa: float = xs[i]
		var xb: float = xs[i + 1]
		if xb - xa < 0.001 or xa < u0 - 0.001 or xb > u1 + 0.001:
			continue
		var trous := []
		for o in ouv:
			if float(o[0]) <= xa + 0.001 and float(o[1]) >= xb - 0.001:
				trous.append([float(o[2]), float(o[3])])
		trous.sort_custom(func(p, q): return p[0] < q[0])
		var y := v0
		for t in trous:
			if t[0] > y + 0.001:
				_b(f, xa, xb, y, minf(t[0], v1), d0, d1, mt)
			y = maxf(y, t[1])
		if v1 > y + 0.001:
			_b(f, xa, xb, y, v1, d0, d1, mt)


## Pièce de bois inclinée dans le plan d'une façade, de (u0, v0) à (u1, v1), section e × [d0, d1].
func _piece(f: Dictionary, u0: float, v0: float, u1: float, v1: float, e: float, d0: float, d1: float, mt: Material) -> void:
	var lg := Vector2(u1 - u0, v1 - v0).length()
	var ang := atan2(v1 - v0, u1 - u0)
	a.boite_tournee(f, (u0 + u1) * 0.5, (v0 + v1) * 0.5, lg, e, d0, d1, ang, mt)


# ------------------------------------------------------------------------------------------------ volumes
func _corps() -> void:
	# rez-de-chaussée de pierre (derrière le mur sud maçonné) et étages enduits (derrière le pan de bois)
	a.box(Vector3(R.get_center().x, (H0 + N1) * 0.5, (R.position.y + R.end.y - EP) * 0.5), Vector3(R.size.x, N1 - H0, R.size.y - EP), m["mur"])
	a.box(Vector3(R.get_center().x, (N1 + N3) * 0.5, R.get_center().y), Vector3(R.size.x, N3 - N1, R.size.y), m["enduit"])


## Rez-de-chaussée sud : mur maçonné de 0,45 m percé de l'entrée ; soubassement, chaîne d'angle sud-ouest.
func _rdc_sud() -> void:
	var f := _f("s")
	_mur_perce(f, 0.0, R.size.x, H0, N1, -EP, 0.0, [[PORTE["u0"], PORTE["u1"], PORTE["bas"], PORTE["haut"]]], m["mur"])
	_b(f, -0.1, 0.15, H0, 4.0, 0.0, 0.12, m["socle"])
	_b(f, 3.85, 4.4, H0, 4.0, 0.0, 0.12, m["socle"])
	var v := 4.0
	var k := 0
	while v < N1 - 0.4:
		var lg := 0.55 if k % 2 == 0 else 0.32
		var mt: Material = m["taille_a"] if k % 2 == 0 else m["taille_b"]
		_b(f, -0.04, lg, v, v + 0.33, 0.0, 0.04, mt)
		_b(_f("o"), R.size.y - (0.32 if k % 2 == 0 else 0.55), R.size.y, v, v + 0.33, 0.0, 0.04, mt)
		v += 0.35
		k += 1


## Devanture de bois peint sur l'entrée : poteaux (= piédroits à collision), socles de pierre, chapiteaux, bandeau
## d'enseigne à filet doré et emblème au flacon, corniche ; porte vitrée en embrasure, imposte à grille, seuil.
func _devanture() -> void:
	var f := _f("s")
	var u0: float = PORTE["u0"]
	var u1: float = PORTE["u1"]
	var uc := (u0 + u1) * 0.5
	var ht: float = PORTE["haut"]
	# poteaux sur socles de pierre, à l'emplacement exact des piédroits à collision
	for p in [[0.65, u0], [u1, 3.35]]:
		_b(f, p[0] - 0.03, p[1] + 0.03, H0, 3.85, 0.0, 0.38, m["taille_b"])
		_b(f, p[0], p[1], 3.85, ht + 0.05, 0.02, 0.35, m["vert"])
		_b(f, p[0] + 0.08, p[1] - 0.08, 4.1, ht - 0.2, 0.35, 0.37, m["vert_clair"])         # panneau en creux (filet)
		_b(f, p[0] - 0.05, p[1] + 0.05, ht + 0.05, ht + 0.17, 0.0, 0.4, m["vert"])           # chapiteau
	# piédroits de l'embrasure (pierre, dans l'épaisseur du mur), linteau de pierre
	for s in [[u0 - 0.04, u0 + 0.03], [u1 - 0.03, u1 + 0.04]]:
		_b(f, s[0], s[1], H0, ht, -EP, 0.0, m["taille_a"])
	_b(f, u0 - 0.05, u1 + 0.05, ht - 0.02, ht + 0.25, -EP, 0.0, m["taille_b"])
	# bandeau d'enseigne et corniche (de bois peint), filet doré, emblème au flacon
	_b(f, 0.1, 3.9, ht + 0.17, ht + 0.62, 0.0, 0.36, m["vert"])
	_b(f, 0.18, 3.82, ht + 0.24, ht + 0.27, 0.36, 0.375, m["or"])
	_b(f, 0.18, 3.82, ht + 0.52, ht + 0.55, 0.36, 0.375, m["or"])
	_b(f, 0.05, 3.95, ht + 0.62, ht + 0.72, 0.0, 0.44, m["vert_clair"])
	_b(f, 0.0, 4.0, ht + 0.72, ht + 0.78, 0.0, 0.48, m["vert"])
	_flacon(f, uc, ht + 0.4, 0.375, 0.26)
	# porte à deux vantaux, au fond de l'embrasure : soubassement à panneaux, partie haute vitrée (petits carreaux
	# éclairés), imposte vitrée à grille de fer
	var dp := -EP
	var hv := ht - 0.45                                  # haut des vantaux, imposte au-dessus
	_b(f, u0, u1, H0 + 0.07, ht, dp - 0.005, dp, m["sombre"])
	for s: float in [-1.0, 1.0]:
		var va: float = u0 if s < 0.0 else uc + 0.01
		var vb: float = uc - 0.01 if s < 0.0 else u1
		_b(f, va, vb, H0 + 0.08, hv, dp, dp + 0.05, m["vert"])
		_b(f, va + 0.1, vb - 0.1, H0 + 0.25, H0 + 1.05, dp + 0.05, dp + 0.07, m["vert_clair"])
		_b(f, va + 0.1, vb - 0.1, H0 + 1.3, hv - 0.12, dp + 0.05, dp + 0.055, m["vitre_chaude"])
		_b(f, (va + vb) * 0.5 - 0.02, (va + vb) * 0.5 + 0.02, H0 + 1.3, hv - 0.12, dp + 0.05, dp + 0.075, m["vert"])
		for yy: float in [H0 + 1.3 + (hv - 0.12 - H0 - 1.3) / 3.0, H0 + 1.3 + (hv - 0.12 - H0 - 1.3) * 2.0 / 3.0]:
			_b(f, va + 0.1, vb - 0.1, yy - 0.018, yy + 0.018, dp + 0.05, dp + 0.075, m["vert"])
		_b(f, (uc + (va + vb) * 0.5) * 0.5 - 0.03, (uc + (va + vb) * 0.5) * 0.5 + 0.03, H0 + 1.08, H0 + 1.2, dp + 0.05, dp + 0.09, m["or"])   # poignées
	_b(f, u0, u1, hv, hv + 0.06, dp, dp + 0.07, m["vert"])
	_b(f, u0 + 0.05, u1 - 0.05, hv + 0.06, ht - 0.03, dp, dp + 0.01, m["vitre_douce"])
	var x := u0 + 0.15
	while x < u1 - 0.1:
		_b(f, x - 0.012, x + 0.012, hv + 0.06, ht - 0.03, dp + 0.01, dp + 0.04, m["fer"])
		x += 0.15
	# seuil dans l'embrasure, marche, dalle sur le caniveau de la place
	_b(f, u0 - 0.02, u1 + 0.02, H0 - 0.05, H0 + 0.07, -EP, 0.35, m["seuil"])
	_b(f, u0 - 0.3, u1 + 0.3, H0 - 0.05, H0 + 0.045, 0.35, 0.8, m["seuil"])
	_b(f, uc - 0.7, uc + 0.7, H0 - 0.05, H0 + 0.022, 0.88, 1.42, m["taille_b"])
	# lanterne de fer à l'angle
	_lanterne(f, 3.68, 5.35)


## Emblème au flacon (relief) : panse, col, bouchon, reflet.
func _flacon(f: Dictionary, u: float, v: float, d: float, k: float) -> void:
	_b(f, u - k * 0.9, u + k * 0.9, v - k * 0.75, v + k * 0.35, d, d + 0.05, m["flacon"])
	_b(f, u - k * 0.65, u + k * 0.65, v - k * 0.95, v - k * 0.75, d, d + 0.05, m["flacon"])
	_b(f, u - k * 0.25, u + k * 0.25, v + k * 0.35, v + k * 0.85, d, d + 0.05, m["flacon"])
	_b(f, u - k * 0.3, u + k * 0.3, v + k * 0.85, v + k * 1.05, d, d + 0.06, m["bouchon"])
	_b(f, u - k * 0.6, u - k * 0.4, v - k * 0.4, v + k * 0.1, d + 0.05, d + 0.06, m["panneau"])


func _lanterne(f: Dictionary, u: float, v: float) -> void:
	_b(f, u - 0.05, u + 0.05, v + 0.25, v + 0.55, 0.0, 0.04, m["fer"])
	_b(f, u - 0.025, u + 0.025, v + 0.48, v + 0.53, 0.0, 0.42, m["fer"])
	_b(f, u - 0.12, u + 0.12, v - 0.06, v + 0.25, 0.24, 0.48, m["lanterne"])
	_b(f, u - 0.15, u + 0.15, v + 0.25, v + 0.31, 0.21, 0.51, m["fer"])
	_b(f, u - 0.14, u + 0.14, v - 0.1, v - 0.06, 0.22, 0.5, m["fer"])


## Rez-de-chaussée ouest (le long du palier) : soubassement, chaîne d'angle nord-ouest discrète.
func _rdc_ouest() -> void:
	var f := _f("o")
	_b(f, 0.0, R.size.y + 0.1, H0, 4.0, 0.0, 0.12, m["socle"])


# ------------------------------------------------------------------------------------------------ étages
## Encorbellement sud : sablière de chêne sur consoles moulurées, solives apparentes, sous-face.
func _encorbellement() -> void:
	var f := _f("s")
	_b(f, -0.05, R.size.x + 0.05, N1 - 0.22, N1, -0.1, ENC + 0.06, m["chene"])            # sablière de chambrée
	_b(f, -0.05, R.size.x + 0.05, N1 - 0.3, N1 - 0.22, 0.0, ENC - 0.04, m["chene_c"])
	var u := 0.25
	while u < R.size.x:
		_b(f, u - 0.06, u + 0.06, N1 - 0.36, N1 - 0.22, 0.0, ENC, m["chene_c"])          # abouts de solives
		u += 0.5
	for uc: float in [0.0, 4.0, 8.0, 12.0]:
		var ua := clampf(uc, 0.12, R.size.x - 0.12)
		_b(f, ua - 0.1, ua + 0.1, N1 - 0.95, N1 - 0.3, 0.0, 0.16, m["chene"])            # console
		_b(f, ua - 0.1, ua + 0.1, N1 - 0.65, N1 - 0.3, 0.16, 0.3, m["chene"])
		_b(f, ua - 0.1, ua + 0.1, N1 - 0.45, N1 - 0.3, 0.3, ENC, m["chene"])


## Fenêtres des étages : [u, appui, largeur, hauteur, éclairée]
const FEN_SUD := [[2.0, 7.75, 1.1, 1.5, true], [6.0, 7.75, 1.1, 1.5, false], [10.0, 7.75, 1.1, 1.5, false],
	[2.0, 10.45, 1.0, 1.35, false], [10.0, 10.45, 1.0, 1.35, true]]
const CHARGEMENT := [6.0, 10.05, 1.25, 1.95]


## Façade sud des étages en pan de bois sur l'encorbellement : hourdis enduits (0,4 m, fenêtres en retrait), poteaux,
## sablières, décharges en croix dans les travées pleines, croisées, volets verts, appuis ; porte de chargement.
func _pan_de_bois_sud() -> void:
	var f := _f("s")
	var ouv := []
	for w in FEN_SUD:
		ouv.append([float(w[0]) - float(w[2]) * 0.5, float(w[0]) + float(w[2]) * 0.5, float(w[1]), float(w[1]) + float(w[3])])
	var c: Array = CHARGEMENT
	ouv.append([float(c[0]) - float(c[2]) * 0.5, float(c[0]) + float(c[2]) * 0.5, float(c[1]), float(c[1]) + float(c[3])])
	_mur_perce(f, 0.0, R.size.x, N1, N3, 0.0, ENC, ouv, m["enduit_sud"])
	var d0 := ENC - 0.02
	var d1 := ENC + 0.06
	# ossature : poteaux corniers et de travée, sablières de plancher, sablière haute
	for up: float in [0.0, 4.0, 8.0, 12.0]:
		var ua := clampf(up, 0.11, R.size.x - 0.11)
		_b(f, ua - 0.11, ua + 0.11, N1, N3, d0, d1, m["chene"])
	for vv: float in [N1 + 0.1, N2, N3 - 0.1]:
		_b(f, -0.02, R.size.x + 0.02, vv - 0.1, vv + 0.1, d0, d1 + 0.01, m["chene"])
	# encadrements des fenêtres (linteau, appui, montants) et décharges dans les parties pleines
	for w in FEN_SUD:
		_croisee(f, float(w[0]), float(w[1]), float(w[2]), float(w[3]), bool(w[4]))
	for trav in [[0.11, 4.0], [4.0, 8.0], [8.0, 11.89]]:
		var ua: float = float(trav[0]) + 0.11
		var ub: float = float(trav[1]) - 0.11
		var umid := (ua + ub) * 0.5
		for et in [[N1 + 0.2, N2 - 0.1], [N2 + 0.1, N3 - 0.2]]:
			var va: float = et[0]
			var vb: float = et[1]
			# demi-croix de Saint-André de part et d'autre de la baie
			_piece(f, ua, va, ua + 0.65, vb, 0.11, d0, d1 - 0.01, m["chene_c"])
			_piece(f, ub, va, ub - 0.65, vb, 0.11, d0, d1 - 0.01, m["chene_c"])
			_b(f, umid - 0.07, umid + 0.07, va, va + 0.01, d0, d0 + 0.01, m["chene"])
	# porte de chargement (vantaux de planches, pentures) sous la potence
	var uc: float = c[0]
	var w: float = c[2]
	var v0: float = c[1]
	var v1: float = v0 + float(c[3])
	_b(f, uc - w * 0.5, uc + w * 0.5, v0, v1, 0.0, 0.01, m["sombre"])
	for i in 6:
		var ua := uc - w * 0.5 + w * i / 6.0
		_b(f, ua + 0.005, ua + w / 6.0 - 0.012, v0 + 0.03, v1 - 0.03, 0.02, 0.08, [m["bois1"], m["bois2"], m["bois3"]][i % 3])
	for hb: float in [v0 + 0.35, v1 - 0.4]:
		_b(f, uc - w * 0.5 + 0.05, uc + w * 0.5 - 0.05, hb - 0.03, hb + 0.03, 0.08, 0.1, m["fer"])
	_b(f, uc - w * 0.5 - 0.12, uc + w * 0.5 + 0.12, v1, v1 + 0.16, d0, d1, m["chene"])
	_b(f, uc - w * 0.5 - 0.12, uc + w * 0.5 + 0.12, v0 - 0.12, v0, 0.0, d1 + 0.04, m["chene"])


## Croisée en retrait dans le hourdis : fond, vitrage, meneau et traverse, encadrement de chêne, appui, volets ouverts.
func _croisee(f: Dictionary, u: float, appui: float, w: float, h: float, eclairee: bool) -> void:
	var u0 := u - w * 0.5
	var u1 := u + w * 0.5
	var v1 := appui + h
	var dv := 0.06
	_b(f, u0, u1, appui, v1, 0.0, 0.01, m["sombre"])
	_b(f, u0 + 0.05, u1 - 0.05, appui + 0.05, v1 - 0.05, dv - 0.01, dv, m["vitre_chaude"] if eclairee else m["vitre"])
	_b(f, u - 0.03, u + 0.03, appui, v1, dv, dv + 0.05, m["chene"])
	_b(f, u0, u1, appui + h * 0.62 - 0.03, appui + h * 0.62 + 0.03, dv, dv + 0.05, m["chene"])
	for s: float in [u0, u1 - 0.06]:
		_b(f, s, s + 0.06, appui, v1, dv, dv + 0.05, m["chene"])
	# encadrement de chêne au nu du pan de bois
	var d0 := ENC - 0.02
	var d1 := ENC + 0.06
	_b(f, u0 - 0.12, u1 + 0.12, v1, v1 + 0.14, d0, d1, m["chene"])
	_b(f, u0 - 0.1, u0, appui, v1, d0, d1, m["chene"])
	_b(f, u1, u1 + 0.1, appui, v1, d0, d1, m["chene"])
	_b(f, u0 - 0.16, u1 + 0.16, appui - 0.1, appui, 0.0, d1 + 0.08, m["chene_c"])          # appui saillant
	# volets ouverts (planches, deux barres)
	for s: float in [-1.0, 1.0]:
		var a0 := u0 - 0.12 - w * 0.5 if s < 0.0 else u1 + 0.12
		var a1 := a0 + w * 0.5
		_b(f, a0, a1, appui + 0.02, v1 - 0.02, d1, d1 + 0.04, m["volet"])
		for yy: float in [appui + h * 0.22, appui + h * 0.78]:
			_b(f, a0 + 0.04, a1 - 0.04, yy - 0.035, yy + 0.035, d1 + 0.04, d1 + 0.06, m["volet_s"])


## Étages ouest (le long du palier) : pan de bois plaqué sur l'enduit, croisées, volets ; pas d'encorbellement (palier).
func _etages_ouest() -> void:
	var f := _f("o")
	for up: float in [0.0, 6.0, 12.0]:
		var ua := clampf(up, 0.11, R.size.y - 0.11)
		_b(f, ua - 0.11, ua + 0.11, N1, N3, 0.0, 0.08, m["chene"])
	for vv: float in [N1 + 0.1, N2, N3 - 0.1]:
		_b(f, 0.0, R.size.y, vv - 0.1, vv + 0.1, 0.0, 0.09, m["chene"])
	_b(f, 0.0, R.size.y, N1 - 0.15, N1 + 0.0, 0.0, 0.14, m["chene_c"])
	for u: float in [3.0, 9.0]:
		for et in [[7.75, 1.5], [10.45, 1.35]]:
			var w := 1.0
			var u0 := u - w * 0.5
			var u1 := u + w * 0.5
			var ap: float = et[0]
			var v1: float = ap + float(et[1])
			_b(f, u0, u1, ap, v1, 0.0, 0.015, m["sombre"])
			_b(f, u0 + 0.05, u1 - 0.05, ap + 0.05, v1 - 0.05, 0.015, 0.02, m["vitre"])
			_b(f, u - 0.03, u + 0.03, ap, v1, 0.02, 0.06, m["chene"])
			_b(f, u0, u1, ap + float(et[1]) * 0.62 - 0.03, ap + float(et[1]) * 0.62 + 0.03, 0.02, 0.06, m["chene"])
			_b(f, u0 - 0.1, u1 + 0.1, v1, v1 + 0.14, 0.0, 0.11, m["chene"])
			_b(f, u0 - 0.1, u0, ap, v1, 0.0, 0.1, m["chene"])
			_b(f, u1, u1 + 0.1, ap, v1, 0.0, 0.1, m["chene"])
			_b(f, u0 - 0.14, u1 + 0.14, ap - 0.09, ap, 0.0, 0.18, m["chene_c"])
			for s: float in [-1.0, 1.0]:
				var a0 := u0 - 0.1 - w * 0.5 if s < 0.0 else u1 + 0.1
				_b(f, a0, a0 + w * 0.5, ap + 0.02, v1 - 0.02, 0.1, 0.14, m["volet"])
		# décharges entre les fenêtres
		_piece(f, u + 0.75, N1 + 0.2, u + 2.2, N2 - 0.1, 0.11, 0.0, 0.08, m["chene_c"])
		_piece(f, u + 0.75, N2 + 0.1, u + 2.2, N3 - 0.2, 0.11, 0.0, 0.08, m["chene_c"])


# ------------------------------------------------------------------------------------------------ pignons, toit
## Pignon sur rue (au nu de l'encorbellement) et pignon nord, triangulés (fusionnés à part).
const PIGNON_BAS := 12.25
const PIGNON_HAUT := 16.0


func _pignons() -> void:
	_prisme(R.end.y - 0.3, R.end.y + ENC + 0.05)
	_prisme(R.position.y - 0.05, R.position.y + 0.3)


func _prisme(y0: float, y1: float) -> void:
	var x0 := R.position.x
	var x1 := R.end.x
	var xm := (x0 + x1) * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tri := func(p: Vector3, q: Vector3, r: Vector3) -> void:
		var nrm := (q - p).cross(r - p).normalized()
		for v: Vector3 in [p, r, q]:
			st.set_normal(nrm)
			st.set_uv(Vector2(v.x, v.y))
			st.add_vertex(v)
	var pa := Vector3(x0, PIGNON_BAS, y1)
	var pb := Vector3(x1, PIGNON_BAS, y1)
	var pc := Vector3(xm, PIGNON_HAUT, y1)
	tri.call(pa, pb, pc)
	var qa := Vector3(x0, PIGNON_BAS, y0)
	var qb := Vector3(x1, PIGNON_BAS, y0)
	var qc := Vector3(xm, PIGNON_HAUT, y0)
	tri.call(qb, qa, qc)
	for pr in [[qa, qc, pa, pc], [qc, qb, pc, pb]]:
		tri.call(pr[0], pr[2], pr[3])
		tri.call(pr[0], pr[3], pr[1])
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m["enduit_sud"]
	a.racine.add_child(mi)


## Pan de bois du pignon sur rue (boîtes, fusionnées avec la façade) : entrait, poinçon, arbalétriers, planches de rive,
## lucarne ; appelé depuis _potence pour rester dans la même fusion.
func _pan_pignon() -> void:
	var f := _f("s")
	var d0 := ENC + 0.03
	var d1 := ENC + 0.1
	var um := R.size.x * 0.5
	var hp := PIGNON_HAUT
	_b(f, 0.0, R.size.x, PIGNON_BAS + 0.05, PIGNON_BAS + 0.25, d0, d1, m["chene"])          # entrait
	_b(f, um - 0.1, um + 0.1, PIGNON_BAS + 0.25, hp - 0.1, d0, d1, m["chene"])               # poinçon
	_piece(f, 0.3, PIGNON_BAS + 0.25, um - 0.15, hp - 0.25, 0.2, d0, d1, m["chene"])         # arbalétriers
	_piece(f, R.size.x - 0.3, PIGNON_BAS + 0.25, um + 0.15, hp - 0.25, 0.2, d0, d1, m["chene"])
	_b(f, 1.8, R.size.x - 1.8, 13.7, 13.86, d0, d1, m["chene"])                               # entrait retroussé
	# planches de rive sous la rive des tuiles (finition)
	_piece(f, -0.35, PIGNON_BAS - 0.12, um, hp + 0.3, 0.26, ENC + 0.38, ENC + 0.46, m["chene_c"])
	_piece(f, R.size.x + 0.35, PIGNON_BAS - 0.12, um, hp + 0.3, 0.26, ENC + 0.38, ENC + 0.46, m["chene_c"])
	# lucarne du comble (petite croisée)
	_croisee_simple(f, um, 14.15, 0.7, 0.8)


func _croisee_simple(f: Dictionary, u: float, ap: float, w: float, h: float) -> void:
	var d1 := ENC + 0.1
	_b(f, u - w * 0.5, u + w * 0.5, ap, ap + h, d1 - 0.02, d1, m["sombre"])
	_b(f, u - w * 0.5 + 0.05, u + w * 0.5 - 0.05, ap + 0.05, ap + h - 0.05, d1, d1 + 0.005, m["vitre"])
	_b(f, u - 0.025, u + 0.025, ap, ap + h, d1, d1 + 0.04, m["chene"])
	_b(f, u - w * 0.5 - 0.08, u + w * 0.5 + 0.08, ap + h, ap + h + 0.1, d1 - 0.02, d1 + 0.05, m["chene"])
	_b(f, u - w * 0.5 - 0.1, u + w * 0.5 + 0.1, ap - 0.08, ap, d1 - 0.02, d1 + 0.08, m["chene_c"])


## Potence de grenier au pignon : poutre en saillie, jambe de force, poulie, corde, caisse suspendue.
func _potence() -> void:
	_pan_pignon()
	var x := R.get_center().x
	var y := R.end.y + ENC + 0.1
	var v := 15.0
	a.box(Vector3(x, v, y + 0.75), Vector3(0.2, 0.22, 1.6), m["chene"])
	var j: MeshInstance3D = a.box(Vector3(x, v - 0.48, y + 0.36), Vector3(0.13, 1.0, 0.13), m["chene"])
	j.basis = Basis(Vector3(1, 0, 0), -0.62)
	a.box(Vector3(x, v - 0.19, y + 1.38), Vector3(0.1, 0.26, 0.26), m["fer"])
	a.box(Vector3(x, v - 1.25, y + 1.38), Vector3(0.03, 1.9, 0.03), a.plein(Color(0.62, 0.55, 0.42)))
	a.box(Vector3(x, v - 2.38, y + 1.38), Vector3(0.6, 0.48, 0.6), m["bois_clair"])
	for dy: float in [-0.15, 0.15]:
		a.box(Vector3(x, v - 2.38 + dy, y + 1.38), Vector3(0.64, 0.05, 0.64), m["bois3"])


## Enseigne pendante à l'angle sud-ouest, sous l'encorbellement : potence de fer, panneau ovale clair, flacon vert.
func _enseigne() -> void:
	var f := _f("s")
	var u := 0.25
	var v := 7.55
	_b(f, u - 0.05, u + 0.05, v - 0.4, v + 0.1, ENC, ENC + 0.05, m["fer"])
	_b(f, u - 0.03, u + 0.03, v - 0.03, v + 0.03, ENC, ENC + 1.3, m["fer"])
	_b(f, u - 0.42, u + 0.42, v - 0.03, v + 0.03, ENC + 0.82, ENC + 0.88, m["fer"])
	var jf: MeshInstance3D = a.box(Vector3(R.position.x + u, v - 0.28, R.end.y + ENC + 0.45), Vector3(0.03, 0.95, 0.03), m["fer"])
	jf.basis = Basis(Vector3(1, 0, 0), 1.05)
	for s: float in [-1.0, 1.0]:
		_b(f, u + s * 0.32 - 0.01, u + s * 0.32 + 0.01, v - 0.3, v, ENC + 0.84, ENC + 0.86, m["fer"])
	# panneau (ovale en gradins), cadre de fer, flacon en relief des deux côtés
	var vc := v - 0.78
	var rx := 0.42
	var ry := 0.48
	for i in 7:
		var t := -1.0 + (i + 0.5) * 2.0 / 7.0
		var hw := rx * sqrt(maxf(0.0, 1.0 - t * t))
		_b(f, u - hw, u + hw, vc + t * ry - ry / 7.0, vc + t * ry + ry / 7.0, ENC + 0.82, ENC + 0.9, m["panneau"])
	_b(f, u - rx - 0.03, u + rx + 0.03, vc - 0.02, vc + 0.02, ENC + 0.81, ENC + 0.91, m["fer"])
	_flacon(f, u, vc, ENC + 0.9, 0.3)


func _cheminee() -> void:
	var x := 78.6
	var z := 79.0
	var pied := 13.0
	var top := 17.2
	a.box(Vector3(x, (pied + top) * 0.5, z), Vector3(0.95, top - pied, 0.75), m["mur"])
	a.box(Vector3(x, top + 0.07, z), Vector3(1.15, 0.14, 0.95), m["taille_a"])
	a.box(Vector3(x, top + 0.3, z), Vector3(0.32, 0.32, 0.32), m["taille_b"])
	a.box(Vector3(x, top + 0.47, z), Vector3(0.2, 0.03, 0.2), m["suie"])


## Étal déplacé à l'angle ouest (collision basse ; mobilier P7.10 réutilisé) : auvent de toile rayée sur tringles de fer,
## accroché au mur du socle du palier.
func _etal_bois() -> void:
	var r := ETAL
	sc._static_box(sc._rect_center(r, H0, H0 + 0.9), Vector3(r.size.x, 0.9, r.size.y), sc.L_OBST)
	var y0 := r.position.y - 0.05
	var n := 7
	var w := (r.size.x + 0.2) / n
	for i in n:
		var b: MeshInstance3D = a.box(Vector3(r.position.x - 0.1 + w * (i + 0.5), 5.4, y0 + 0.62), Vector3(w + 0.002, 0.04, 1.3), m["toile_v"] if i % 2 == 0 else m["toile_c"])
		b.basis = Basis(Vector3(1, 0, 0), 0.38)
		a.box(Vector3(r.position.x - 0.1 + w * (i + 0.5), 5.02, y0 + 1.22), Vector3(w * 0.92, 0.2, 0.03), m["toile_c"] if i % 2 == 0 else m["toile_v"])
	for xb: float in [r.position.x - 0.08, r.end.x + 0.08]:
		a.box(Vector3(xb, 5.4, y0 + 0.62), Vector3(0.035, 0.035, 1.3), m["fer"])
	var cx := r.get_center().x
	var toile: Material = m["toile_c"]
	for p in [[cx + 0.55, 0.36], [cx + 0.9, 0.3]]:
		a.box(Vector3(float(p[0]), H0 + 0.81 + float(p[1]) * 0.5, r.get_center().y - 0.05), Vector3(0.34, float(p[1]), 0.42), toile)


func _modeles() -> void:
	var d0: int = a.racine.get_child_count()
	var r := ETAL
	var cy := r.get_center().y - 0.05
	fo._modele("fp/Table_Large", Vector3(r.get_center().x + 0.15, H0, cy), 0.0, Vector3(0.75, 1.0, 0.75))
	fo._modele("fp/Crate_Wooden", Vector3(r.position.x + 0.55, H0 + 0.81, cy), 0.15, Vector3.ONE * 0.5)
	fo._modele("fp/Crate_Wooden", Vector3(r.position.x + 1.15, H0 + 0.81, cy + 0.05), -0.1, Vector3.ONE * 0.42)
	fo._modele("fp/Barrel", Vector3(r.position.x + 0.28, H0, cy + 0.05), 0.0, Vector3.ONE * 0.8)
	fo._fusion_gltf(d0, "boutique_p711_etal")


## Toit de tuiles canal (texture Quaternius) : matière tuiles_p7101, plus brune que la forge ; rives de bois ; débord
## sur la rue jusqu'à 0,5 m devant le pignon en encorbellement.
func _toit() -> void:
	var z0 := R.position.y - 0.5
	var z1 := R.end.y + ENC + 0.5
	var toit: Node3D = fo._modele("mv/Roof_RoundTiles_8x12", Vector3(R.get_center().x, N3, (z0 + z1) * 0.5), 0.0,
		Vector3((R.size.x + 0.7) / 9.95, TOIT_KY, (z1 - z0) / 14.13))
	for mi in toit.find_children("*", "MeshInstance3D", true, false):
		var mm := mi as MeshInstance3D
		for s in mm.mesh.get_surface_count():
			var m0: Material = mm.get_active_material(s)
			if not (m0 is StandardMaterial3D):
				continue
			var sm := m0 as StandardMaterial3D
			var chemin := str(sm.albedo_texture.resource_path if sm.albedo_texture else "")
			var cle := "p711|tuiles|" + chemin
			if not a._mats.has(cle):
				if chemin.contains("RoundTiles"):
					var sh := ShaderMaterial.new()
					sh.shader = TUILES_SH
					sh.set_shader_parameter("albedo_tex", sm.albedo_texture)
					sh.set_shader_parameter("normal_tex", sm.normal_texture)
					sh.set_shader_parameter("uv_echelle", sm.uv1_scale)
					sh.set_shader_parameter("uv_decalage", sm.uv1_offset)
					sh.set_shader_parameter("teinte", Vector3(0.86, 0.95, 0.98))
					sh.set_shader_parameter("saturation", 0.74)
					sh.set_shader_parameter("variation", 0.17)
					a._mats[cle] = sh
				else:
					var m1 := sm.duplicate() as StandardMaterial3D
					m1.albedo_color = Color(0.55, 0.45, 0.40)
					a._mats[cle] = m1
			mm.set_surface_override_material(s, a._mats[cle])
	# maillages du toit rattachés directement à la racine (transform conservé : normales calculées par le moteur)
	for mi in toit.find_children("*", "MeshInstance3D", true, false):
		(mi as Node3D).reparent(a.racine, true)
	toit.queue_free()


## Tout ce que la boutique a ajouté est rattaché à son volume d'escamotage (toit et saillies compris).
func _rattacher() -> void:
	for i in range(_depuis, a.racine.get_child_count()):
		var n: Node = a.racine.get_child(i)
		if n is GeometryInstance3D:
			n.set_meta("vol", VOL)
