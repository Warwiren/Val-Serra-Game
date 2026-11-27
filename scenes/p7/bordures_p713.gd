extends RefCounted
## P7.13 — BORDURES DE LA GRANDE PLACE (lot 5), forge D et boutique P7.11 comme références de qualité.
##   * DRAPERIE (bloc des données bat_commerce_e2, collision inchangée) : rez-de-chaussée de pierre maçonné en épaisseur
##     (0,45 m) : porte cintrée au sud (entrée décorative des données, x 82), « ouvroirs » (baies de boutique à tablette dans
##     l'épaisseur du mur, coupons et rouleaux d'étoffe) au sud et à l'ouest ; étage enduit rose sur cordon de pierre,
##     croisées à volets bleu ardoise, corniche ; toit de tuiles à deux versants, pignon sur rue. Plus BAS que le blockout
##     (faîtage 12,1 m contre 12,9 m) et en retrait de l'encorbellement de la boutique : la boutique n'est pas davantage
##     masquée. Enseigne pendante aux ciseaux et au coupon (distincte du flacon de la boutique), lanterne.
##   * ÉTALS DE MARCHÉ (etal_0..3, collisions des données ; etal_3 raccourci à l'est pour dégager le blason et l'axe) :
##     tréteaux et plateau de planches, quatre poteaux, toile à deux pans rayée de teintes sourdes ; marchandises propres
##     à chaque étal (légumes, poteries, sacs d'épices, fleurs) ; caisses et tonneau (modèles Quaternius déjà importés).
##   * HALLE SUR QUAI (bat_echoppe_no_o, quai de 0,45 m des données) : parement et dallage du quai, petite halle de
##     charpente sur dés de pierre, toit de tuiles ; sacs de grain, caisses, tonneaux.
## --bordures=0 : état P7.12.2 (blockout).

const Archi := preload("res://scenes/p7/archi_p77.gd")
const Refonte := preload("res://scenes/p7/forge_p7101.gd")
const DRAPERIE := "bat_commerce_e2"
const HALLE := "bat_echoppe_no_o"
const EP := 0.45
const N1 := 6.9                       # cordon : plancher de l'étage
const N2 := 9.5                       # corniche (= sommet du bloc des données)
const FAITAGE := 2.6
const RETRAIT_N := 0.45               # étage et toit en retrait de l'encorbellement de la boutique (y 88 -> 88,4)

var sc
var a
var fo
var ref
var m := {}
var actif := true


func _init(scene, archi, forge) -> void:
	sc = scene
	a = archi
	fo = forge
	actif = str(scene._cli.get("bordures", "1")) != "0"


func gere(id: String) -> bool:
	return actif and (id == DRAPERIE or id == HALLE or id.begins_with("etal_"))


func _mats() -> void:
	if not m.is_empty():
		return
	ref = Refonte.new(fo)
	ref._matieres()
	m = ref.m.duplicate()
	m["enduit"] = a.enduit(Color(0.88, 0.72, 0.63), N1, N2 + FAITAGE + 1.0)
	m["volet"] = a.plein(Color(0.27, 0.34, 0.43), 0.8)
	m["volet_c"] = a.plein(Color(0.33, 0.41, 0.51), 0.8)
	m["vitre"] = a.plein(Color(0.16, 0.18, 0.21), 0.25, 0.0, 0.3)
	m["vitre_chaude"] = a.plein(Color(0.95, 0.66, 0.36), 0.5, 0.7)
	m["chene"] = a.plein(Color(0.24, 0.17, 0.11), 0.9)
	m["chene_c"] = a.plein(Color(0.33, 0.23, 0.15), 0.9)
	m["planche"] = a.plein(Color(0.42, 0.31, 0.21), 0.9)
	m["or"] = a.plein(Color(0.80, 0.62, 0.26), 0.35, 0.0, 0.6)
	m["toile_c"] = a.plein(Color(0.86, 0.81, 0.69), 0.95)
	m["sac"] = a.plein(Color(0.72, 0.62, 0.45), 0.95)
	m["osier"] = a.plein(Color(0.55, 0.40, 0.24), 0.95)
	m["terre_cuite"] = a.plein(Color(0.66, 0.38, 0.25), 0.85)
	m["gres"] = a.plein(Color(0.52, 0.46, 0.38), 0.6)
	m["tuiles_t"] = a.macon("tuiles", Color(1.32, 1.1, 0.98), 0.0, "maillage")


## Bloc des données : collision inchangée (sauf le quai : celle du bloc aussi), puis habillage.
func construit(e: Dictionary) -> void:
	_mats()
	var id := str(e["id"])
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_OBST)
	if id == DRAPERIE:
		_draperie(r, h0)
	elif id == HALLE:
		_halle(r, h0, h1)
	else:
		var k := int(id.substr(5)) if id.substr(5).is_valid_int() else 0
		_etals.append([r, h0, k])                          # dessinés ensemble par finaliser() : une fusion par matière


var _etals := []


## Appelé par la ville en fin de décor : les étals sont construits d'un bloc (maillages fusionnés par matière pour les
## quatre étals : ≈ 4 fois moins d'appels de dessin qu'un étal par fusion).
func finaliser() -> void:
	if _etals.is_empty():
		return
	var d0: int = a.racine.get_child_count()
	for e in _etals:
		_etal(e[0], e[1], e[2])
	a.fusionner(d0, "bordures_etals")
	var d1: int = a.racine.get_child_count()
	for e in _etals:
		_etal_modeles(e[0], e[1], e[2])
		if _etals_modeles():
			_marchandises_modeles(e[0], e[1], e[2])
	fo._fusion_gltf(d1, "bordures_etals_modeles")
	_etals.clear()


func _b(f: Dictionary, u0: float, u1: float, v0: float, v1: float, d0: float, d1: float, mt: Material) -> MeshInstance3D:
	return a.boite(f, u0, u1, v0, v1, d0, d1, mt)


# ================================================================================================ draperie
func _draperie(r: Rect2, h0: float) -> void:
	var d0: int = a.racine.get_child_count()
	var fs := Archi.face(r, "s")
	var fo_ := Archi.face(r, "o")
	# volumes : rez-de-chaussée (derrière les murs maçonnés sud et ouest), étage en retrait de la boutique
	a.box(Vector3((r.position.x + EP + r.end.x) * 0.5, (h0 + N1) * 0.5, (r.position.y + r.end.y - EP) * 0.5),
		Vector3(r.size.x - EP, N1 - h0, r.size.y - EP), m["mur"])
	var re := Rect2(r.position.x, r.position.y + RETRAIT_N, r.size.x, r.size.y - RETRAIT_N)
	a.box(Vector3(re.get_center().x, (N1 + N2) * 0.5, re.get_center().y), Vector3(re.size.x, N2 - N1, re.size.y), m["enduit"])
	# rez-de-chaussée sud : porte cintrée (u 1,4 -> 2,6 : entrée décorative des données, x 82), ouvroir (u 3,6 -> 7)
	var porte := {"u0": 1.4, "u1": 2.6, "bas": h0, "spring": h0 + 2.3, "rise": 0.32}
	var ouv_s := {"u0": 3.7, "u1": 6.9, "bas": h0 + 0.85, "spring": h0 + 2.35, "rise": 0.3}
	ref._mur_perce(fs, 0.0, r.size.x, h0, N1, -EP, 0.0, [porte, ouv_s], m["mur"])
	for o in [porte, ouv_s]:
		var hs: float = (float(o["u1"]) - float(o["u0"])) * 0.5
		ref._claveaux(fs, float(o["u0"]) + hs, float(o["spring"]), hs, float(o["rise"]), 0.34, 9 if hs > 1.0 else 7, -EP + 0.02, 0.04)
	_porte(fs, porte)
	_ouvroir(fs, ouv_s, 0)
	# rez-de-chaussée ouest (sur la place) : deux ouvroirs
	var ouv_o := [{"u0": 1.6, "u1": 4.6, "bas": h0 + 0.85, "spring": h0 + 2.35, "rise": 0.3},
		{"u0": 6.6, "u1": 9.6, "bas": h0 + 0.85, "spring": h0 + 2.35, "rise": 0.3}]
	ref._mur_perce(fo_, EP, r.size.y, h0, N1, -EP, 0.0, ouv_o, m["mur"])
	for i in ouv_o.size():
		var o: Dictionary = ouv_o[i]
		var hs: float = (float(o["u1"]) - float(o["u0"])) * 0.5
		ref._claveaux(fo_, float(o["u0"]) + hs, float(o["spring"]), hs, float(o["rise"]), 0.34, 9, -EP + 0.02, 0.04)
		_ouvroir(fo_, o, i + 1)
	# soubassement, chaînes d'angle (sud-ouest), cordon de l'étage
	_b(fs, -0.02, float(porte["u0"]) - 0.06, h0, h0 + 0.42, 0.0, 0.09, m["socle"])            # interrompu à la porte
	_b(fs, float(porte["u1"]) + 0.06, r.size.x + 0.02, h0, h0 + 0.42, 0.0, 0.09, m["socle"])
	_b(fo_, EP + 0.02, r.size.y + 0.02, h0, h0 + 0.42, 0.0, 0.09, m["socle"])
	var v := h0 + 0.42
	var k := 0
	while v < N1 - 0.35:
		var lg := 0.55 if k % 2 == 0 else 0.32
		var mt: Material = m["taille_a"] if k % 2 == 0 else m["taille_b"]
		_b(fs, -0.03, lg, v, v + 0.33, 0.0, 0.035, mt)
		_b(fo_, r.size.y - (0.32 if k % 2 == 0 else 0.55), r.size.y + 0.03, v, v + 0.33, 0.0, 0.035, mt)
		v += 0.35
		k += 1
	var fe := Archi.face(re, "s")
	var feo := Archi.face(re, "o")
	_b(fe, -0.08, re.size.x + 0.08, N1 - 0.06, N1 + 0.16, 0.0, 0.15, m["taille_a"])
	_b(feo, -0.02, re.size.y + 0.08, N1 - 0.06, N1 + 0.16, 0.0, 0.15, m["taille_a"])
	# étage : croisées à volets (sud : 2 ; ouest : 3), corniche moulurée sur les deux façades
	for u: float in [2.0, 6.0]:
		_croisee(fe, u, N1 + 0.75, 0.95, 1.4)
	for u: float in [2.6, 6.0, 9.4]:
		_croisee(feo, u - RETRAIT_N, N1 + 0.75, 0.95, 1.4)
	for f in [fe, feo]:
		var L: float = f["L"]
		_b(f, -0.1, L + 0.1, N2 - 0.24, N2 - 0.12, 0.0, 0.12, m["taille_b"])
		_b(f, -0.16, L + 0.16, N2 - 0.12, N2, 0.0, 0.24, m["taille_a"])
	# enseigne aux ciseaux et au coupon (angle sud-ouest, sur la place), lanterne de la porte
	_enseigne(fo_, r.size.y - 1.0, h0 + 3.0)
	_lanterne(fs, 3.1, h0 + 2.05)
	a.fusionner(d0, "bordures_draperie")
	var d1: int = a.racine.get_child_count()
	a.toit(re, N2, FAITAGE, Color(0.88, 0.72, 0.63), "2p_y", Color(1.0, 0.94, 0.9))
	a.fusionner(d1, "bordures_draperie_toit")


## Porte cintrée de planches ferrées au fond de l'embrasure ; seuil.
func _porte(f: Dictionary, o: Dictionary) -> void:
	var u0: float = o["u0"]
	var u1: float = o["u1"]
	var bas: float = o["bas"]
	var sp: float = o["spring"]
	var dp := -EP + 0.12
	_b(f, u0, u1, bas, sp + float(o["rise"]), dp - 0.02, dp, m["sombre"])
	var n := 5
	for i in n:
		var ua := u0 + (u1 - u0) * i / n
		var ub := u0 + (u1 - u0) * (i + 1) / n
		var top := sp + float(o["rise"]) * (1.0 - pow(((ua + ub) * 0.5 - (u0 + u1) * 0.5) / ((u1 - u0) * 0.5), 2.0)) - 0.02
		_b(f, ua + 0.005, ub - 0.005, bas + 0.04, maxf(top, sp), dp, dp + 0.05, m["chene_c"] if i % 2 == 0 else m["chene"])
	for hv: float in [bas + 0.45, bas + 1.75]:
		_b(f, u0 + 0.06, u1 - 0.2, hv - 0.035, hv + 0.035, dp + 0.05, dp + 0.075, m["fer"])
	_b(f, u1 - 0.26, u1 - 0.18, bas + 1.0, bas + 1.12, dp + 0.05, dp + 0.09, m["fer"])
	_b(f, u0 - 0.04, u1 + 0.04, bas - 0.04, bas + 0.06, -EP, 0.3, m["seuil"])


## Ouvroir de boutique : tablette de pierre dans l'épaisseur du mur (ne dépasse pas : aucun relief traversable), volet
## haut relevé sur ses barres en auvent court, fond sombre éclairé ; étoffes pliées et rouleaux posés sur la tablette.
func _ouvroir(f: Dictionary, o: Dictionary, k: int) -> void:
	var u0: float = o["u0"]
	var u1: float = o["u1"]
	var bas: float = o["bas"]
	var sp: float = o["spring"]
	var top := sp + float(o["rise"])
	_b(f, u0, u1, bas, top, -EP, -EP + 0.02, m["sombre"])
	_b(f, u0 - 0.03, u1 + 0.03, bas - 0.1, bas + 0.03, -EP, 0.1, m["taille_a"])                       # tablette
	_b(f, u0, u1, bas - 0.62, bas - 0.1, -EP, -0.04, m["chene"])                                       # coffre sous la tablette
	# volet haut relevé (planches), barres de fer
	# (au-dessus de 2,3 m : aucun obstacle à hauteur de passage)
	var vb := top + 0.12
	var vol: MeshInstance3D = a.box(_pt(f, (u0 + u1) * 0.5, vb - 0.1, 0.28), _taille(f, u1 - u0 + 0.06, 0.05, 0.6), m["planche"])
	vol.basis = Basis(f["t"], 0.32)
	_b(f, u0 - 0.04, u1 + 0.04, vb - 0.05, vb + 0.07, 0.0, 0.08, m["chene"])                         # gond (traverse)
	for s: float in [-1.0, 1.0]:
		var ub := (u0 + 0.15) if s < 0.0 else (u1 - 0.15)
		var br: MeshInstance3D = a.box(_pt(f, ub, vb - 0.42, 0.28), _taille(f, 0.03, 0.03, 0.66), m["fer"])
		br.basis = Basis(f["t"], -0.75)
	# étoffes : piles de coupons et rouleaux (couleurs sourdes)
	var teintes := [Color(0.48, 0.18, 0.18), Color(0.22, 0.30, 0.44), Color(0.30, 0.40, 0.26), Color(0.70, 0.56, 0.32), Color(0.55, 0.40, 0.52)]
	var u := u0 + 0.25
	var i := 0
	while u < u1 - 0.35:
		var c: Color = teintes[(i + k * 2) % teintes.size()]
		var mt: Material = a.plein(c, 0.95)
		if i % 3 == 2:
			_cyl_f(f, u + 0.12, bas + 0.03 + 0.11, -0.16, 0.11, 0.5, mt)
			u += 0.36
		else:
			var hp := 0.12 + 0.05 * (i % 2)
			_b(f, u, u + 0.34, bas + 0.03, bas + 0.03 + hp, -0.36, 0.06, mt)
			_b(f, u + 0.03, u + 0.31, bas + 0.03 + hp, bas + 0.06 + hp, -0.33, 0.03, a.plein(teintes[(i + k * 2 + 1) % teintes.size()], 0.95))
			u += 0.42
		i += 1


## Croisée de pierre en retrait (0,2 m), meneau et traverse, vitres, appui, volets bleu ardoise ouverts.
func _croisee(f: Dictionary, u: float, ap: float, w: float, h: float) -> void:
	var u0 := u - w * 0.5
	var u1 := u + w * 0.5
	var v1 := ap + h
	_b(f, u0, u1, ap, v1, -0.01, 0.006, m["vitre"])
	_b(f, u - 0.035, u + 0.035, ap, v1, 0.006, 0.05, m["taille_a"])
	_b(f, u0, u1, ap + h * 0.62 - 0.035, ap + h * 0.62 + 0.035, 0.006, 0.05, m["taille_a"])
	_b(f, u0 - 0.13, u0, ap - 0.02, v1 + 0.02, 0.0, 0.08, m["taille_b"])
	_b(f, u1, u1 + 0.13, ap - 0.02, v1 + 0.02, 0.0, 0.08, m["taille_b"])
	_b(f, u0 - 0.13, u1 + 0.13, v1 + 0.02, v1 + 0.2, 0.0, 0.09, m["taille_a"])
	_b(f, u0 - 0.17, u1 + 0.17, ap - 0.12, ap - 0.02, 0.0, 0.15, m["taille_a"])
	for s: float in [-1.0, 1.0]:
		var a0 := u0 - 0.15 - w * 0.5 if s < 0.0 else u1 + 0.15
		_b(f, a0, a0 + w * 0.5, ap + 0.02, v1 - 0.02, 0.095, 0.13, m["volet"])
		_b(f, a0 + 0.06, a0 + w * 0.5 - 0.06, ap + 0.12, ap + h * 0.45, 0.13, 0.145, m["volet_c"])


## Enseigne pendante : potence de fer, panneau de chêne bordé d'or, ciseaux ouverts et coupon roulé en relief.
func _enseigne(f: Dictionary, u: float, v: float) -> void:
	_b(f, u - 0.06, u + 0.06, v - 0.6, v + 0.12, 0.0, 0.05, m["fer"])
	_b(f, u - 0.035, u + 0.035, v - 0.035, v + 0.035, 0.0, 1.25, m["fer"])
	var p: MeshInstance3D = a.box(_pt(f, u, v - 0.3, 0.42), _taille(f, 0.035, 0.035, 0.78), m["fer"])
	p.basis = Basis(f["t"], -0.62)
	var dc := 0.95
	_b(f, u - 0.012, u + 0.012, v - 0.2, v - 0.04, dc - 0.01, dc + 0.01, m["fer"])
	# panneau perpendiculaire à la façade (lisible depuis la place), bord doré
	var fp := {"o": _pt(f, u, 0.0, dc) - (f["n"] as Vector3) * 0.4, "t": f["n"], "n": f["t"], "L": 0.8}
	_b(fp, 0.0, 0.8, v - 0.82, v - 0.2, -0.025, 0.025, m["chene"])
	_b(fp, 0.04, 0.76, v - 0.78, v - 0.24, -0.032, 0.032, m["or"])
	_b(fp, 0.07, 0.73, v - 0.75, v - 0.27, -0.038, 0.038, m["chene_c"])
	# ciseaux (deux lames croisées, anneaux) et coupon (rouleau bordeaux)
	for s: float in [-1.0, 1.0]:
		a.boite_tournee(fp, 0.4, v - 0.5, 0.42, 0.05, -0.05, 0.05, s * 0.6, m["fer"])
		_b(fp, 0.4 + s * 0.16 - 0.05, 0.4 + s * 0.16 + 0.05, v - 0.72, v - 0.63, -0.05, 0.05, m["fer"])
	_b(fp, 0.12, 0.26, v - 0.42, v - 0.3, -0.06, 0.06, a.plein(Color(0.48, 0.18, 0.18), 0.9))


func _lanterne(f: Dictionary, u: float, v: float) -> void:
	_b(f, u - 0.05, u + 0.05, v + 0.25, v + 0.55, 0.0, 0.04, m["fer"])
	_b(f, u - 0.025, u + 0.025, v + 0.48, v + 0.53, 0.0, 0.36, m["fer"])
	_b(f, u - 0.11, u + 0.11, v - 0.05, v + 0.24, 0.2, 0.42, m["lanterne"])
	_b(f, u - 0.14, u + 0.14, v + 0.24, v + 0.3, 0.17, 0.45, m["fer"])


# ================================================================================================ étals
## Étal de marché sur la collision des données : tréteaux et plateau de planches (0,85 m), quatre poteaux, toile à deux
## pans rayée (faîtage le long du grand côté), marchandises.
const TOILES := [[Color(0.80, 0.62, 0.32), Color(0.88, 0.82, 0.68)], [Color(0.42, 0.50, 0.36), Color(0.86, 0.82, 0.70)],
	[Color(0.62, 0.32, 0.24), Color(0.86, 0.80, 0.68)], [Color(0.34, 0.42, 0.52), Color(0.87, 0.83, 0.72)]]


func _etal(r: Rect2, h0: float, k: int) -> void:
	var long_x := r.size.x >= r.size.y
	var L := r.size.x if long_x else r.size.y
	var P := r.size.y if long_x else r.size.x
	var c := r.get_center()
	# repère local : u le long du grand côté, w en travers
	var ax := Vector3(1, 0, 0) if long_x else Vector3(0, 0, 1)
	var aw := Vector3(0, 0, 1) if long_x else Vector3(1, 0, 0)
	var ctr := Vector3(c.x, h0, c.y)
	var hp := 0.85
	# plateau, ceinture, tréteaux
	_bx(ctr, ax, aw, 0.0, hp - 0.03, 0.0, L - 0.3, 0.06, P - 0.5, m["planche"])
	_bx(ctr, ax, aw, 0.0, hp - 0.13, 0.0, L - 0.4, 0.14, P - 0.6, m["chene_c"])
	for su: float in [-1.0, 1.0]:
		for sw: float in [-1.0, 1.0]:
			var pied := _bx(ctr, ax, aw, su * (L * 0.5 - 0.45), (hp - 0.1) * 0.5, sw * (P * 0.5 - 0.42), 0.07, hp - 0.1, 0.07, m["chene"])
			pied.rotate(ax, sw * 0.12)
	# poteaux et toile à deux pans
	var he := 2.15
	var hf := 2.6
	for su: float in [-1.0, 1.0]:
		for sw: float in [-1.0, 1.0]:
			_bx(ctr, ax, aw, su * (L * 0.5 - 0.08), he * 0.5, sw * (P * 0.5 - 0.08), 0.08, he, 0.08, m["chene"])
		_bx(ctr, ax, aw, su * (L * 0.5 - 0.08), (he + hf) * 0.5, 0.0, 0.07, hf - he, 0.07, m["chene"])
	_bx(ctr, ax, aw, 0.0, hf, 0.0, L, 0.06, 0.06, m["chene"])
	var t: Array = TOILES[k % TOILES.size()]
	var mt0: Material = a.plein(t[0], 0.95)
	var mt1: Material = a.plein(t[1], 0.95)
	var demi := P * 0.5 + 0.3
	var pente := atan2(hf - he, demi)
	var lg := sqrt(demi * demi + pow(hf - he, 2.0))
	var nb := int(round(L / 0.42))
	for sw: float in [-1.0, 1.0]:
		for i in nb:
			var uu := -L * 0.5 - 0.1 + (L + 0.2) * (i + 0.5) / nb
			# bandes alternées décalées de 4 mm : leur léger recouvrement n'est pas dans un même plan (pas de z-fighting)
			var b := _bx(ctr, ax, aw, uu, (he + hf) * 0.5 + 0.03 + (0.004 if i % 2 == 1 else 0.0), sw * demi * 0.5, (L + 0.2) / nb + 0.002, 0.02, lg, mt0 if i % 2 == 0 else mt1)
			b.rotate(ax, sw * pente if long_x else -sw * pente)
		# lambrequin (bord festonné)
		for i in nb:
			var uu := -L * 0.5 - 0.1 + (L + 0.2) * (i + 0.5) / nb
			_bx(ctr, ax, aw, uu, he - 0.08, sw * (demi + 0.0), (L + 0.2) / nb - 0.03, 0.16, 0.015, mt0 if i % 2 == 0 else mt1)
	if not _etals_modeles():
		_marchandises(ctr + Vector3.UP * hp, ax, aw, L - 0.5, P - 0.6, k)


## Caisse et tonneau au pied de l'étal (modèles Quaternius déjà importés).
func _etal_modeles(r: Rect2, h0: float, k: int) -> void:
	var long_x := r.size.x >= r.size.y
	var L := r.size.x if long_x else r.size.y
	var P := r.size.y if long_x else r.size.x
	var ax := Vector3(1, 0, 0) if long_x else Vector3(0, 0, 1)
	var aw := Vector3(0, 0, 1) if long_x else Vector3(1, 0, 0)
	var ctr := Vector3(r.get_center().x, h0, r.get_center().y)
	fo._modele("fp/Crate_Wooden", ctr + ax * (L * 0.5 - 0.55) + aw * (P * 0.5 - 0.35), 0.1 * k, Vector3.ONE * 0.75)
	fo._modele("fp/Barrel", ctr + ax * (-L * 0.5 + 0.5) + aw * (P * 0.5 - 0.35), 0.0, Vector3.ONE * 0.7)


## Boîte dans le repère local d'un étal (u le long, w en travers ; tailles su, sh, sw).
func _bx(ctr: Vector3, ax: Vector3, aw: Vector3, u: float, y: float, w: float, su: float, sh: float, sw: float, mt: Material) -> MeshInstance3D:
	var size := Vector3(absf(ax.x) * su + absf(aw.x) * sw, sh, absf(ax.z) * su + absf(aw.z) * sw)
	return a.box(ctr + ax * u + aw * w + Vector3.UP * y, size, mt)


func _marchandises(base: Vector3, ax: Vector3, aw: Vector3, L: float, P: float, k: int) -> void:
	var n := int(L / 0.55)
	for i in n:
		var u := -L * 0.5 + L * (i + 0.5) / n
		for sw: float in [-0.5, 0.5]:
			var p := base + ax * u + aw * (sw * P * 0.55)
			match k % 4:
				0:  # sacs d'épices et de grains, ouverts (cônes de couleur)
					_cyl(p + Vector3.UP * 0.14, 0.15, 0.17, 0.28, m["sac"])
					_cyl(p + Vector3.UP * 0.3, 0.0, 0.14, 0.1, a.plein([Color(0.78, 0.48, 0.16), Color(0.62, 0.22, 0.14), Color(0.86, 0.74, 0.40), Color(0.45, 0.30, 0.18)][(i * 2 + int(sw > 0)) % 4], 0.95))
				1:  # poteries : jarres, cruches, bols
					var hj := 0.24 + 0.08 * ((i + int(sw > 0)) % 3)
					_cyl(p + Vector3.UP * hj * 0.5, 0.09, 0.13, hj, m["terre_cuite"] if (i + int(sw > 0)) % 2 == 0 else m["gres"])
					_cyl(p + Vector3.UP * (hj + 0.03), 0.06, 0.07, 0.06, m["terre_cuite"])
				2:  # paniers de légumes et de fruits
					_cyl(p + Vector3.UP * 0.08, 0.2, 0.17, 0.16, m["osier"])
					var cf: Color = [Color(0.86, 0.46, 0.14), Color(0.34, 0.52, 0.20), Color(0.70, 0.16, 0.14), Color(0.88, 0.76, 0.30)][(i + int(sw > 0) * 2) % 4]
					_cyl(p + Vector3.UP * 0.19, 0.12, 0.17, 0.08, a.plein(cf, 0.8))
				_:  # fleurs en seaux
					_cyl(p + Vector3.UP * 0.12, 0.13, 0.11, 0.24, m["gres"])
					_cyl(p + Vector3.UP * 0.34, 0.17, 0.1, 0.22, a.plein(Color(0.30, 0.44, 0.22), 0.9))
					var cf2: Color = [Color(0.86, 0.30, 0.36), Color(0.92, 0.82, 0.38), Color(0.66, 0.46, 0.80), Color(0.95, 0.92, 0.86)][(i + int(sw > 0)) % 4]
					_cyl(p + Vector3.UP * 0.47, 0.13, 0.15, 0.06, a.plein(cf2, 0.85))


func _cyl(c: Vector3, r_haut: float, r_bas: float, h: float, mt: Material, seg := 10) -> MeshInstance3D:
	return a.cylindre(c, r_haut, r_bas, h, mt, seg)


## Cylindre couché le long d'une façade (rouleau d'étoffe), centre (u, v, d).
func _cyl_f(f: Dictionary, u: float, v: float, d: float, r: float, lg: float, mt: Material) -> MeshInstance3D:
	var mi := _cyl(_pt(f, u, v, d), r, r, lg, mt, 10)
	mi.basis = Basis(f["t"], PI * 0.5)                   # axe du rouleau perpendiculaire à la façade (vu par le bout)
	return mi


func _pt(f: Dictionary, u: float, v: float, d: float) -> Vector3:
	var p: Vector3 = f["o"] + (f["t"] as Vector3) * u + (f["n"] as Vector3) * d
	p.y = v
	return p


func _taille(f: Dictionary, su: float, sv: float, sd: float) -> Vector3:
	var t: Vector3 = f["t"]
	var n: Vector3 = f["n"]
	return Vector3(absf(t.x) * su + absf(n.x) * sd, sv, absf(t.z) * su + absf(n.z) * sd)


# ================================================================================================ halle sur quai
## Quai de 0,45 m (bloc des données) : parement de pierre, dallage, bordure ; petite halle de charpente sur dés de pierre
## (poteaux, sablières, aisseliers), toit de tuiles à deux versants (faîtage nord-sud) ; sacs, caisses et tonneaux.
func _halle(r: Rect2, h0: float, h1: float) -> void:
	var d0: int = a.racine.get_child_count()
	a.box(sc._rect_center(r, h0, h1 - 0.03), Vector3(r.size.x + 0.04, h1 - 0.03 - h0, r.size.y + 0.04), m["socle"])
	a.box(Vector3(r.get_center().x, h1 - 0.015, r.get_center().y), Vector3(r.size.x, 0.03, r.size.y), a.macon("dallage2", Archi.PIERRE_VILLE * 0.95, h1))
	for f in [Archi.face(r, "s"), Archi.face(r, "o"), Archi.face(r, "n")]:
		var L: float = f["L"]
		_b(f, -0.06, L + 0.06, h1 - 0.12, h1 + 0.05, 0.0, 0.14, m["taille_b"])
	var rh := r.grow(-0.6)
	var he := h1 + 2.55
	var xs := [rh.position.x, rh.end.x]
	var ys := [rh.position.y, rh.get_center().y, rh.end.y]
	for x: float in xs:
		for y: float in ys:
			a.box(Vector3(x, h1 + 0.12, y), Vector3(0.36, 0.24, 0.36), m["taille_a"])
			a.box(Vector3(x, (h1 + 0.24 + he) * 0.5, y), Vector3(0.2, he - h1 - 0.24, 0.2), m["chene"])
			for sx: float in [-1.0, 1.0]:
				if (x == rh.position.x and sx > 0.0) or (x == rh.end.x and sx < 0.0):
					var ai: MeshInstance3D = a.box(Vector3(x + sx * 0.3, he - 0.3, y), Vector3(0.62, 0.09, 0.09), m["chene"])
					ai.basis = Basis(Vector3(0, 0, 1), sx * 0.75)
		a.box(Vector3(x, he + 0.08, rh.get_center().y), Vector3(0.22, 0.18, rh.size.y + 0.4), m["chene"])        # sablières
	for y: float in ys:
		a.box(Vector3(rh.get_center().x, he + 0.24, y), Vector3(rh.size.x + 0.4, 0.16, 0.18), m["chene_c"])      # entraits
	a.fusionner(d0, "bordures_halle")
	var d1: int = a.racine.get_child_count()
	var rt := Rect2(rh.position.x - 0.3, rh.position.y - 0.3, rh.size.x + 0.6, rh.size.y + 0.6)
	a.toit(rt, he + 0.32, 1.7, Color(0.86, 0.80, 0.70), "2p_y", Color(1.0, 0.94, 0.9))
	a.fusionner(d1, "bordures_halle_toit")
	var d2: int = a.racine.get_child_count()
	# sacs de grain empilés, caisses, tonneaux (P8.1-A : sacs modélisés, cf. _marchandises_modeles)
	for i in (0 if _etals_modeles() else 6):
		var p := Vector3(rh.position.x + 0.7 + (i % 3) * 0.7, h1, rh.position.y + 1.0 + int(i / 3) * 0.55)
		_cyl(p + Vector3.UP * 0.2, 0.2, 0.24, 0.4, m["sac"], 8)
		if i % 2 == 0:
			_cyl(p + Vector3(0.1, 0.58, 0.05), 0.18, 0.22, 0.36, m["sac"], 8)
	a.fusionner(d2, "bordures_halle_sacs")
	var d3: int = a.racine.get_child_count()
	fo._modele("fp/Crate_Wooden", Vector3(rh.end.x - 0.6, h1, rh.get_center().y + 0.4), 0.2, Vector3.ONE * 0.8)
	fo._modele("fp/Crate_Wooden", Vector3(rh.end.x - 0.65, h1 + 0.62, rh.get_center().y + 0.4), 0.5, Vector3.ONE * 0.7)
	fo._modele("fp/Barrel", Vector3(rh.position.x + 0.7, h1, rh.end.y - 0.8), 0.0, Vector3.ONE * 0.75)
	fo._modele("fp/Barrel", Vector3(rh.position.x + 1.45, h1, rh.end.y - 0.7), 0.0, Vector3.ONE * 0.75)
	if _etals_modeles():
		for i in 5:
			var ps := Vector3(rh.position.x + 0.75 + (i % 3) * 0.72, h1 + (0.62 if i >= 3 else 0.0), rh.position.y + 1.05 + (0.2 if i >= 3 else 0.0))
			fo._modele("fp/Bag", ps, 0.4 * i, Vector3.ONE * 0.62)
		fo._modele("fp/Bucket_Wooden_1", Vector3(rh.position.x + 2.6, h1, rh.position.y + 1.6), 0.3, Vector3.ONE * 0.9)
	fo._fusion_gltf(d3, "bordures_halle_modeles")



## P8.1-A (L6) : marchandises en modèles reconnaissables (Fantasy Props CC0) au lieu des cylindres et cônes colorés ;
## peu d'objets, bien choisis, selon la gamme de l'étal. --f_etals=0 (ou --finition=0) : marchandises P7.13.
func _etals_modeles() -> bool:
	return str(sc._cli.get("finition", "1")) != "0" and str(sc._cli.get("f_etals", "1")) != "0"


func _marchandises_modeles(r: Rect2, h0: float, k: int) -> void:
	var long_x := r.size.x >= r.size.y
	var L := r.size.x if long_x else r.size.y
	var P := r.size.y if long_x else r.size.x
	var ax := Vector3(1, 0, 0) if long_x else Vector3(0, 0, 1)
	var aw := Vector3(0, 0, 1) if long_x else Vector3(1, 0, 0)
	var ctr := Vector3(r.get_center().x, h0 + 0.85, r.get_center().y)
	var sol := Vector3(r.get_center().x, h0, r.get_center().y)
	var lu := L - 0.7                                   # longueur utile du plateau
	var pos := func(f: float, w: float, base := ctr) -> Vector3: return base + ax * (lu * f) + aw * w
	match k % 4:
		0:  # épices et grains : sacs ouverts, bourses, seau de grain
			fo._modele("fp/Bag", pos.call(-0.38, -0.1), 0.3, Vector3.ONE * 0.5)
			fo._modele("fp/Bag", pos.call(-0.08, 0.05), -0.5, Vector3.ONE * 0.46)
			fo._modele("fp/Pouch_Large", pos.call(0.14, 0.15), 0.8, Vector3.ONE * 1.3)
			fo._modele("fp/Pouch_Large", pos.call(0.22, -0.05), -0.3, Vector3.ONE * 1.2)
			fo._modele("fp/Bucket_Wooden_1", pos.call(0.4, 0.0), 0.2, Vector3.ONE * 0.85)
			fo._modele("fp/Bag", pos.call(0.3, P * 0.5 + 0.1, sol), 1.1, Vector3.ONE * 0.62)
		1:  # poteries : jarres, vases, pot, bouteilles
			fo._modele("fp/Vase_2", pos.call(-0.36, 0.0), 0.0, Vector3.ONE * 0.5)
			fo._modele("fp/Vase_4", pos.call(-0.12, 0.1), 0.6, Vector3.ONE * 0.85)
			fo._modele("fp/Pot_1", pos.call(0.08, -0.1), 0.2, Vector3.ONE * 0.75)
			for b in 3:
				fo._modele("fp/Bottle_1", pos.call(0.26 + b * 0.05, 0.12 - b * 0.08), 0.0, Vector3.ONE * 0.9)
			fo._modele("fp/Vase_4", pos.call(0.42, -0.05), 1.4, Vector3.ONE * 0.75)
			fo._modele("fp/Vase_2", pos.call(-0.3, P * 0.5 + 0.15, sol), 0.4, Vector3.ONE * 0.75)
		2:  # fruits et légumes : cagettes de pommes et de carottes, tonneau de pommes au pied
			fo._modele("fp/FarmCrate_Apple", pos.call(-0.3, 0.0), 0.05, Vector3.ONE * 0.85)
			fo._modele("fp/FarmCrate_Carrot", pos.call(0.05, 0.0), -0.08, Vector3.ONE * 0.8)
			fo._modele("fp/FarmCrate_Apple", pos.call(0.36, 0.05), 0.12, Vector3.ONE * 0.8)
			fo._modele("fp/Barrel_Apples", pos.call(-0.15, P * 0.5 + 0.35, sol), 0.0, Vector3.ONE * 0.8)
		_:  # fleurs coupées en seaux de bois (fleurs du module végétal, s'il est actif)
			for i in 4:
				var pb: Vector3 = pos.call(-0.38 + i * 0.25, 0.08 * (1 if i % 2 == 0 else -1))
				fo._modele("fp/Bucket_Wooden_1", pb, 0.4 * i, Vector3.ONE * 0.8)
				if a.plantes != null:
					a.plantes._inst(a.plantes.NAT + ("Flower_3_Group" if i % 2 == 0 else "Flower_4_Group"), pb + Vector3.UP * 0.12, 0.7 * i, 0.2)
