extends RefCounted
## P7.10.1 — REFONTE ARTISTIQUE DE LA FORGE-ARMURERIE (variante D, base C+). Même emprise (x 44 -> 58, y 76 -> 88), mêmes
## murs (3,5 -> 7,5 m), même toit Quaternius (position, échelle), mêmes collisions (bloc des données et piédroits de l'entrée)
## et même interaction (examen « ex_forge »). Tout est de l'affichage.
##   * Façade sud MAÇONNÉE EN ÉPAISSEUR (0,45 m) : baies réellement en retrait (embrasures, appuis), arcs segmentaires
##     appareillés (claveaux alternés, clef saillante) ; entrée dans un avant-corps de pierre chaude dont la saillie est celle
##     des piédroits à collision (0,35 m) : embrasure de 0,8 m, porte de bois sombre à planches, pentures, gonds, clous,
##     anneaux ; seuil de pierre raccordé au dallage, pierre de franchissement du caniveau.
##   * Relief : soubassement chanfreiné, chaînes d'angle harpées, corniche sur corbeaux sous le débord du toit, pignons de
##     pierre sous les rives (les pignons de brique Quaternius sont retirés), toit à tuiles variées en coordonnées monde.
##   * Identité : foyer de forge à hotte de pierre en encorbellement adossé au pignon ouest, souche de cheminée qui en
##     sort et dépasse le faîtage (fumée légère), braises et lumière orangée, enclume sur billot face au foyer, bac de
##     trempe, soufflet, outils au mur, suie au sol, sur la hotte, la souche et les tuiles ; enseigne d'armurerie en fer
##     forgé (bouclier et épées croisées) ; vitrine éclairée graduée (plus chaude en bas), petits bois et barreaux.

const Archi := preload("res://scenes/p7/archi_p77.gd")
const TUILES_SH := preload("res://src/p7/tuiles_p7101.gdshader")
const R := Rect2(44.0, 76.0, 14.0, 12.0)
const H0 := 3.5
const H1 := 7.5
const COUR_H := 3.95
const EP := 0.45                     # épaisseur du mur de façade maçonné (le corps commence à y 87,55)
const SAILLIE := 0.35                # saillie de l'avant-corps = profondeur des piédroits à collision
const CORNICHE := 6.95

var fo                                # forge (helpers Quaternius)
var a                                 # Archi
var m := {}                           # matières


func _init(forge) -> void:
	fo = forge
	a = forge.a


func construire() -> void:
	_matieres()
	var depuis: int = a.racine.get_child_count()
	_corps()
	_facade_sud()
	_entree()
	_vitrine()
	_petite_fenetre()
	_facade_est()
	_facade_ouest()
	_corniches()
	_rives()
	_foyer()
	_atelier()
	_enseigne()
	for u: float in [4.95, 9.05]:
		_lanterne(u)
	a.fusionner(depuis, "forge_d")
	# pignons fusionnés à part (maillage triangulé : la fusion avec les boîtes le perdait)
	var dp: int = a.racine.get_child_count()
	_pignons()
	a.fusionner(dp, "forge_d_pignons")
	_modeles()
	_toit()
	_tuiles_appentis()
	_lumiere_et_fumee()


# ------------------------------------------------------------------------------------------------ matières
func _pierre(nom: String, base: String, teinte: Color, regl: Dictionary, base_y := H0) -> ShaderMaterial:
	var cle := "p7101|" + nom
	if a._mats.has(cle):
		return a._mats[cle]
	var mt := (a.macon(base, teinte, base_y) as ShaderMaterial).duplicate() as ShaderMaterial
	for k in regl:
		mt.set_shader_parameter(k, regl[k])
	a._mats[cle] = mt
	return mt


func _matieres() -> void:
	# mur courant : appareil du Colisée, plus chaud, assises un peu plus hautes et irrégulières
	m["mur"] = _pierre("mur", "mur2", Color(1.30, 1.15, 0.97), {"irregulier": 0.22, "var_teinte": 0.24, "rapieces": 0.08})
	# pierre de taille chaude (encadrements, claveaux, chaînes, corniche) : chaque pièce est une pierre (pas de joints
	# internes), deux tons alternés
	var taille := {"assises": Vector3(3.0, 3.0, 3.0), "long_bloc": 4.0, "var_long": 0.0, "joint": 0.0, "salissure": 0.25,
		"coulures": 0.2, "mousse": 0.0, "fissures": 0.0, "rapieces": 0.0, "irregulier": 0.0, "usure": 0.4, "k_mousse": 0.0}
	m["taille_a"] = _pierre("taille_a", "mur2", Color(1.52, 1.31, 1.04), taille)
	m["taille_b"] = _pierre("taille_b", "mur2", Color(1.42, 1.22, 0.97), taille)
	m["socle"] = _pierre("socle", "socle2", Color(1.32, 1.17, 0.98), {"salissure": 0.55, "k_terre": 0.8})
	m["seuil"] = _pierre("seuil", "dallage2", Color(1.24, 1.10, 0.94), {"usure": 0.8, "irregulier": 0.0, "fissures": 0.1}, H0)
	m["suie"] = a.plein(Color(0.09, 0.08, 0.075), 0.95)
	m["suie_claire"] = _pierre("suie_claire", "mur2", Color(0.62, 0.55, 0.50), {"salissure": 0.6, "k_mousse": 0.0, "mousse": 0.0})
	m["sombre"] = a.plein(Color(0.05, 0.045, 0.04), 0.9)
	m["bois1"] = a.plein(Color(0.31, 0.205, 0.13), 0.9)
	m["bois2"] = a.plein(Color(0.36, 0.24, 0.15), 0.9)
	m["bois3"] = a.plein(Color(0.27, 0.18, 0.115), 0.9)
	m["bois_clair"] = a.plein(Color(0.36, 0.25, 0.16), 0.9)
	m["cuir"] = a.plein(Color(0.30, 0.19, 0.12), 0.8)
	m["fer"] = a.plein(Color(0.17, 0.165, 0.16), 0.5, 0.0, 0.6)
	m["verre_vif"] = a.plein(Color(1.0, 0.56, 0.24), 0.5, 1.15)
	m["verre_moy"] = a.plein(Color(0.93, 0.56, 0.28), 0.5, 0.75)
	m["verre_doux"] = a.plein(Color(0.78, 0.46, 0.25), 0.5, 0.45)
	m["verre_froid"] = a.plein(Color(0.16, 0.17, 0.18), 0.25, 0.0, 0.3)
	m["braise"] = a.plein(Color(1.0, 0.36, 0.08), 0.8, 2.4)
	m["braise_vive"] = a.plein(Color(1.0, 0.72, 0.32), 0.8, 3.4)
	m["eau"] = a.plein(Color(0.07, 0.09, 0.10), 0.15, 0.0, 0.2)
	m["lanterne"] = a.plein(Color(1.0, 0.70, 0.36), 0.5, 1.6)
	m["sol_suie"] = _pierre("sol_suie", "dallage2", Color(0.62, 0.57, 0.52), {"k_mousse": 0.0, "mousse": 0.0}, COUR_H)


# ------------------------------------------------------------------------------------------------ outils géométriques
func _f(cote: String) -> Dictionary:
	return Archi.face(R, cote)


func _b(f: Dictionary, u0: float, u1: float, v0: float, v1: float, d0: float, d1: float, mt: Material) -> MeshInstance3D:
	return a.boite(f, u0, u1, v0, v1, d0, d1, mt)


## Arc segmentaire : centre du cercle, rayon. hs : demi-ouverture ; rise : flèche.
static func _cercle(spring: float, hs: float, rise: float) -> Vector2:
	var rr := (hs * hs + rise * rise) / (2.0 * rise)
	return Vector2(spring + rise - rr, rr)


## Claveaux d'un arc segmentaire, sur toute l'épaisseur [d0, d1] ; clef saillante et plus haute.
func _claveaux(f: Dictionary, uc: float, spring: float, hs: float, rise: float, ring: float, n: int, d0: float, d1: float) -> void:
	var c := _cercle(spring, hs, rise)
	var th := asin(hs / c.y)
	var rm := c.y + ring * 0.5
	for i in n:
		var ang := PI * 0.5 + th - 2.0 * th * (i + 0.5) / n
		var cle := i == n / 2
		var lg := 2.0 * th * rm / n + 0.006
		var e := ring + (0.1 if cle else 0.0)
		var r_c := c.y + e * 0.5
		a.boite_tournee(f, uc + cos(ang) * r_c, c.x + sin(ang) * r_c, lg if not cle else lg * 1.15, e, d0, d1 + (0.06 if cle else 0.0),
			ang - PI * 0.5, m["taille_a"] if (i % 2 == 0) else m["taille_b"])
	# sommiers (premiers blocs horizontaux à la naissance de l'arc)
	for s: float in [-1.0, 1.0]:
		_b(f, uc + s * hs - (0.0 if s > 0.0 else 0.22), uc + s * hs + (0.22 if s > 0.0 else 0.0), spring - 0.2, spring + 0.02, d0, d1, m["taille_b"])


## Mur plein percé d'ouvertures à arc segmentaire : bandes verticales découpées, écoinçons en gradins sous les claveaux.
## ouv : [{u0, u1, bas, spring, rise}]
func _mur_perce(f: Dictionary, u0: float, u1: float, v0: float, v1: float, d0: float, d1: float, ouv: Array, mt: Material) -> void:
	var xs := [u0, u1]
	for o in ouv:
		xs.append(float(o["u0"]))
		xs.append(float(o["u1"]))
	xs.sort()
	for i in xs.size() - 1:
		var xa: float = xs[i]
		var xb: float = xs[i + 1]
		if xb - xa < 0.001 or xa < u0 - 0.001 or xb > u1 + 0.001:
			continue
		var trous := []
		for o in ouv:
			if float(o["u0"]) <= xa + 0.001 and float(o["u1"]) >= xb - 0.001:
				trous.append([float(o["bas"]), float(o["spring"]) + float(o["rise"])])
		var y := v0
		trous.sort_custom(func(p, q): return p[0] < q[0])
		for t in trous:
			if t[0] > y + 0.001:
				# P7.13 : le pan sous une baie s'arrête 6 mm sous son bas : le dessus de l'appui (ou de la tablette) n'est plus
				# dans le même plan que le dessus du mur (z-fighting mesuré sur les appuis : tools/p7/scintillement_p713.gd)
				_b(f, xa, xb, y, t[0] - (0.006 if t[0] > v0 + 0.001 else 0.0), d0, d1, mt)
			y = maxf(y, t[1])
		if v1 > y + 0.001:
			_b(f, xa, xb, y, v1, d0, d1, mt)
	for o in ouv:
		var hs: float = (float(o["u1"]) - float(o["u0"])) * 0.5
		var uc: float = float(o["u0"]) + hs
		var sp: float = o["spring"]
		var rise: float = o["rise"]
		var c := _cercle(sp, hs, rise)
		var nb := 8
		for k in nb:
			var yb := sp + rise * k / nb
			var yt := sp + rise * (k + 1) / nb
			var hw := sqrt(maxf(0.0, c.y * c.y - pow(yb - c.x, 2.0)))
			if hs - hw > 0.005:
				_b(f, uc - hs, uc - hw, yb, yt, d0, d1, mt)
				_b(f, uc + hw, uc + hs, yb, yt, d0, d1, mt)


## Demi-largeur intérieure d'un arc à la hauteur v.
static func _hw(v: float, spring: float, hs: float, rise: float) -> float:
	if v <= spring:
		return hs
	var c := _cercle(spring, hs, rise)
	return sqrt(maxf(0.0, c.y * c.y - pow(v - c.x, 2.0)))


# ------------------------------------------------------------------------------------------------ corps et façades
## Ouvertures de la façade sud (u depuis x 44).
const PORTE := {"u0": 5.8, "u1": 8.2, "bas": 3.5, "spring": 5.7, "rise": 0.6}
const VITRINE := {"u0": 1.9, "u1": 4.1, "bas": 4.05, "spring": 5.5, "rise": 0.42}
const FENETRE := {"u0": 11.1, "u1": 12.1, "bas": 4.4, "spring": 5.45, "rise": 0.22}
const AVANT_CORPS := Vector2(5.35, 8.65)


func _corps() -> void:
	a.box(Vector3(R.get_center().x, (H0 + H1) * 0.5, (R.position.y + R.end.y - EP) * 0.5),
		Vector3(R.size.x, H1 - H0, R.size.y - EP), m["mur"])


func _facade_sud() -> void:
	var f := _f("s")
	_mur_perce(f, 0.0, R.size.x, H0, H1, -EP, 0.0, [PORTE, VITRINE, FENETRE], m["mur"])
	# soubassement chanfreiné (hors avant-corps)
	for seg in [[-0.12, AVANT_CORPS.x], [AVANT_CORPS.y, R.size.x + 0.12]]:
		_b(f, seg[0], seg[1], H0, 3.98, 0.0, 0.13, m["socle"])
		_b(f, seg[0], seg[1], 3.98, 4.06, 0.0, 0.065, m["taille_b"])
	# chaînes d'angle harpées (sud-ouest, sud-est), retour sur les faces latérales
	_chaines(f, 0.0, 1.0)
	_chaines(f, R.size.x, -1.0)


## Chaîne d'angle : blocs alternés longs / courts sur la face et sur le retour.
func _chaines(f: Dictionary, u_angle: float, sens: float) -> void:
	var cote := "o" if sens > 0.0 else "e"
	var fr := _f(cote)
	var u_retour := R.size.y if cote == "o" else 0.0          # angle sud sur la face latérale
	var sr := -1.0 if cote == "o" else 1.0
	var v := 4.06
	var k := 0
	while v < CORNICHE - 0.36:
		var lg := 0.62 if k % 2 == 0 else 0.36
		var lr := 0.36 if k % 2 == 0 else 0.62
		var mt: Material = m["taille_a"] if k % 2 == 0 else m["taille_b"]
		var ua := u_angle
		var ub := u_angle + sens * lg
		_b(f, minf(ua, ub) - (0.04 if sens > 0.0 else 0.0), maxf(ua, ub) + (0.04 if sens < 0.0 else 0.0), v, v + 0.33, 0.0, 0.04, mt)
		var ra := u_retour
		var rb := u_retour + sr * lr
		_b(fr, minf(ra, rb), maxf(ra, rb), v, v + 0.33, 0.0, 0.04, mt)
		v += 0.35
		k += 1


func _entree() -> void:
	var f := _f("s")
	var uc := 7.0
	var hs := 1.2
	var ac := AVANT_CORPS
	# avant-corps de pierre (même saillie que les piédroits à collision), percé du même arc
	var porte_ac := PORTE.duplicate()
	_mur_perce(f, ac.x, ac.y, H0, CORNICHE, 0.0, SAILLIE, [porte_ac], m["mur"])
	# socle de l'avant-corps et chaînes de ses arêtes
	for s in [[ac.x - 0.06, PORTE["u0"]], [PORTE["u1"], ac.y + 0.06]]:
		_b(f, s[0], s[1], H0, 3.92, SAILLIE - 0.02, SAILLIE + 0.08, m["socle"])
	var v := 3.92
	var k := 0
	while v < 5.55:
		var lg := 0.5 if k % 2 == 0 else 0.3
		var mt: Material = m["taille_a"] if k % 2 == 0 else m["taille_b"]
		_b(f, ac.x - 0.03, ac.x + lg, v, v + 0.32, SAILLIE - 0.02, SAILLIE + 0.03, mt)
		_b(f, ac.y - lg, ac.y + 0.03, v, v + 0.32, SAILLIE - 0.02, SAILLIE + 0.03, mt)
		# piédroits de l'embrasure : blocs en retour dans l'épaisseur
		_b(f, PORTE["u0"] - 0.02, PORTE["u0"] + 0.04, v, v + 0.32, -EP, SAILLIE, mt)
		_b(f, PORTE["u1"] - 0.04, PORTE["u1"] + 0.02, v, v + 0.32, -EP, SAILLIE, mt)
		v += 0.34
		k += 1
	_claveaux(f, uc, PORTE["spring"], hs, PORTE["rise"], 0.42, 11, -EP, SAILLIE + 0.04)
	# glacis de l'avant-corps sous la corniche
	_b(f, ac.x - 0.08, ac.y + 0.08, CORNICHE - 0.12, CORNICHE, 0.0, SAILLIE + 0.1, m["taille_b"])
	# --- porte : planches verticales de bois sombre suivant l'arc, joint central, pentures, gonds, clous, anneaux
	var dp0 := -EP
	var dp1 := -EP + 0.07
	_b(f, PORTE["u0"], PORTE["u1"], H0 + 0.05, PORTE["spring"] + PORTE["rise"], dp0 - 0.005, dp0, m["sombre"])
	var n := 12
	var lp := (2.0 * hs) / n
	for i in n:
		var ua: float = float(PORTE["u0"]) + lp * i
		var ub := ua + lp
		var haut := minf(_hw_top(ua, ub, uc), PORTE["spring"] + PORTE["rise"])
		var mt: Material = [m["bois1"], m["bois2"], m["bois3"], m["bois1"], m["bois3"], m["bois2"]][i % 6]
		var jeu := 0.012 if i != n / 2 - 1 else 0.02
		_b(f, ua + 0.006, ub - jeu, H0 + 0.07, haut, dp0, dp1 - (0.01 if i % 3 == 1 else 0.0), mt)
	for hb: float in [4.0, 4.85, 5.6]:
		for s: float in [-1.0, 1.0]:
			var u_ext := uc + s * (hs - 0.04)
			var u_int := uc + s * 0.12
			_b(f, minf(u_ext, u_int), maxf(u_ext, u_int), hb - 0.04, hb + 0.04, dp1, dp1 + 0.025, m["fer"])
			# extrémité en fleur (losange)
			a.boite_tournee(f, u_int, hb, 0.12, 0.12, dp1, dp1 + 0.03, PI * 0.25, m["fer"])
			# gonds dans le piédroit
			_b(f, uc + s * hs - 0.05 * s - 0.04, uc + s * hs - 0.05 * s + 0.04, hb - 0.07, hb + 0.07, dp1 - 0.02, dp1 + 0.06, m["fer"])
			var uu := u_int
			while absf(uu - u_ext) > 0.15:
				uu += s * 0.19
				_b(f, uu - 0.018, uu + 0.018, hb - 0.018, hb + 0.018, dp1 + 0.02, dp1 + 0.045, m["fer"])
	# anneaux (heurtoirs) et platines
	for s: float in [-1.0, 1.0]:
		var ua := uc + s * 0.3
		_b(f, ua - 0.07, ua + 0.07, 4.75, 4.93, dp1, dp1 + 0.02, m["fer"])
		var r := 0.1
		for j in 8:
			var an := TAU * j / 8.0
			a.boite_tournee(f, ua + cos(an) * r, 4.68 + sin(an) * r, 0.085, 0.022, dp1 + 0.02, dp1 + 0.05, an + PI * 0.5, m["fer"])
	# seuil dans l'embrasure, marche usée devant, pierre de franchissement du caniveau de la place
	_b(f, PORTE["u0"] - 0.02, PORTE["u1"] + 0.02, H0 - 0.05, H0 + 0.07, -EP, SAILLIE, m["seuil"])
	_b(f, PORTE["u0"] - 0.35, PORTE["u1"] + 0.35, H0 - 0.05, H0 + 0.045, SAILLIE, SAILLIE + 0.5, m["seuil"])
	_b(f, uc - 0.85, uc + 0.85, H0 - 0.05, H0 + 0.022, 0.88, 1.42, m["taille_b"])


## Hauteur utile d'une planche [ua, ub] sous l'intrados de la porte.
func _hw_top(ua: float, ub: float, uc: float) -> float:
	var c := _cercle(PORTE["spring"], 1.2, PORTE["rise"])
	var dx := maxf(absf(ua - uc), absf(ub - uc))
	if dx >= c.y:
		return PORTE["spring"]
	return c.x + sqrt(c.y * c.y - dx * dx)


func _vitrine() -> void:
	var f := _f("s")
	var o := VITRINE
	var u0: float = o["u0"]
	var u1: float = o["u1"]
	var uc := (u0 + u1) * 0.5
	var hs := (u1 - u0) * 0.5
	var sp: float = o["spring"]
	var bas: float = o["bas"]
	var dv := -EP + 0.02
	_claveaux(f, uc, sp, hs, o["rise"], 0.32, 9, -EP, 0.07)
	# appui saillant sur deux corbeaux, retour d'appui dans l'embrasure
	_b(f, u0 - 0.2, u1 + 0.2, bas - 0.13, bas, -EP, 0.16, m["taille_a"])
	for s: float in [-1.0, 1.0]:
		_b(f, uc + s * (hs - 0.05) - 0.09, uc + s * (hs - 0.05) + 0.09, bas - 0.36, bas - 0.13, 0.0, 0.12, m["taille_b"])
	# fond sombre, carreaux gradués (plus chauds et plus vifs en bas : lueur de la forge), petits bois, barreaux
	_b(f, u0, u1, bas, sp + o["rise"], -EP, -EP + 0.005, m["sombre"])
	var nx := 4
	var rangs := [[bas, bas + 0.72], [bas + 0.72, sp]]
	var vifs := [[m["verre_vif"], m["verre_moy"], m["verre_vif"], m["verre_vif"]], [m["verre_moy"], m["verre_doux"], m["verre_moy"], m["verre_doux"]]]
	for j in rangs.size():
		for i in nx:
			var ua := u0 + (u1 - u0) * i / nx
			var ub := u0 + (u1 - u0) * (i + 1) / nx
			_b(f, ua + 0.03, ub - 0.03, rangs[j][0] + 0.03, rangs[j][1] - 0.03, dv, dv + 0.01, vifs[j][i])
	# imposte cintrée (gradins sous l'arc)
	var nb := 5
	for k in nb:
		var yb: float = sp + float(o["rise"]) * k / nb
		var yt: float = sp + float(o["rise"]) * (k + 1) / nb
		var hw := _hw(yt, sp, hs, o["rise"])
		if hw > 0.05:
			_b(f, uc - hw, uc + hw, yb, yt, dv, dv + 0.01, m["verre_doux"])
	# silhouette sombre d'un établi derrière les carreaux du bas (profondeur)
	_b(f, u0 + 0.25, u1 - 0.55, bas + 0.03, bas + 0.28, dv + 0.012, dv + 0.02, m["sombre"])
	# petits bois et traverse
	for i in range(1, nx):
		var xx := u0 + (u1 - u0) * i / nx
		_b(f, xx - 0.03, xx + 0.03, bas, sp + _hw_v(xx, uc, sp, hs, o["rise"]), dv + 0.01, dv + 0.06, m["bois1"])
	for yy: float in [bas + 0.72, sp]:
		_b(f, u0, u1, yy - 0.035, yy + 0.035, dv + 0.01, dv + 0.06, m["bois1"])
	_b(f, u0, u1, bas, bas + 0.06, dv, dv + 0.06, m["bois1"])
	# barreaux de fer dans l'embrasure
	for i in 5:
		var xb := u0 + 0.2 + (u1 - u0 - 0.4) * i / 4.0
		_b(f, xb - 0.018, xb + 0.018, bas, sp + _hw_v(xb, uc, sp, hs, o["rise"]) - 0.02, -0.22, -0.185, m["fer"])
	_b(f, u0, u1, sp - 0.02, sp + 0.02, -0.24, -0.17, m["fer"])


## Hauteur de l'intrados au-dessus de la naissance, à l'abscisse x.
func _hw_v(x: float, uc: float, sp: float, hs: float, rise: float) -> float:
	var c := _cercle(sp, hs, rise)
	var dx := absf(x - uc)
	if dx >= c.y:
		return 0.0
	return c.x + sqrt(c.y * c.y - dx * dx) - sp


func _petite_fenetre() -> void:
	var f := _f("s")
	var o := FENETRE
	var u0: float = o["u0"]
	var u1: float = o["u1"]
	var uc := (u0 + u1) * 0.5
	var hs := (u1 - u0) * 0.5
	var sp: float = o["spring"]
	var bas: float = o["bas"]
	_claveaux(f, uc, sp, hs, o["rise"], 0.26, 7, -EP, 0.05)
	_b(f, u0 - 0.14, u1 + 0.14, bas - 0.12, bas, -EP, 0.12, m["taille_a"])
	_b(f, u0, u1, bas, sp + o["rise"], -EP, -EP + 0.005, m["sombre"])
	_b(f, u0 + 0.05, u1 - 0.05, bas + 0.05, sp, -EP + 0.02, -EP + 0.03, m["verre_doux"])
	_b(f, uc - 0.03, uc + 0.03, bas, sp + _hw_v(uc, uc, sp, hs, o["rise"]), -EP + 0.03, -EP + 0.08, m["bois1"])
	for i in 3:
		var xb := u0 + 0.22 + (u1 - u0 - 0.44) * i / 2.0
		_b(f, xb - 0.016, xb + 0.016, bas, sp + _hw_v(xb, uc, sp, hs, o["rise"]) - 0.02, -0.16, -0.13, m["fer"])


## Fenêtre plaquée sur une face latérale (embrasure de 0,14 m) : arc segmentaire, appui, barreaux.
func _fenetre_plaquee(f: Dictionary, uc: float, bas: float, w: float, haut: float) -> void:
	var hs := w * 0.5
	var sp := bas + haut
	var rise := 0.2
	for s: float in [-1.0, 1.0]:
		_b(f, uc + s * hs - (0.18 if s < 0.0 else 0.0), uc + s * hs + (0.18 if s > 0.0 else 0.0), bas, sp, 0.0, 0.14, m["taille_b"])
	_claveaux(f, uc, sp, hs, rise, 0.24, 7, 0.0, 0.14)
	_b(f, uc - hs, uc + hs, bas, sp + rise, 0.0, 0.01, m["sombre"])
	_b(f, uc - hs - 0.24, uc + hs + 0.24, bas - 0.12, bas, 0.0, 0.2, m["taille_a"])
	for i in 4:
		var xb := uc - hs + 0.14 + (w - 0.28) * i / 3.0
		_b(f, xb - 0.016, xb + 0.016, bas, sp + _hw_v(xb, uc, sp, hs, rise) - 0.02, 0.06, 0.09, m["fer"])


func _facade_est() -> void:
	var f := _f("e")
	_b(f, -0.12, R.size.y, H0, 3.98, 0.0, 0.13, m["socle"])
	_b(f, -0.12, R.size.y, 3.98, 4.06, 0.0, 0.065, m["taille_b"])
	# P7.13 : les deux fenêtres plaquées de ce pignon (appui 4,4 m, y 85 et 80,5) étaient enterrées par la volée C (4,6 m)
	# et le palier 2 (5,75 m) qui longent ce mur : pignon aveugle, comme un mur d'échiffre


func _facade_ouest() -> void:
	var f := _f("o")
	# soubassement au-dessus de la plate-forme de la cour
	_b(f, 0.0, R.size.y + 0.12, COUR_H, 4.3, 0.0, 0.12, m["socle"])
	# porte de service vers la cour (planches, arc segmentaire, piédroits)
	var uc := 8.6
	var hs := 0.75
	var sp := 5.5
	var rise := 0.3
	for s: float in [-1.0, 1.0]:
		_b(f, uc + s * hs - (0.22 if s < 0.0 else 0.0), uc + s * hs + (0.22 if s > 0.0 else 0.0), COUR_H, sp, 0.0, 0.14, m["taille_a"] if s < 0.0 else m["taille_b"])
	_claveaux(f, uc, sp, hs, rise, 0.3, 9, 0.0, 0.14)
	_b(f, uc - hs, uc + hs, COUR_H, sp + rise, 0.0, 0.008, m["sombre"])
	var n := 7
	for i in n:
		var ua := uc - hs + 2.0 * hs * i / n
		var ub := ua + 2.0 * hs / n
		var dx := maxf(absf(ua - uc), absf(ub - uc))
		var c := _cercle(sp, hs, rise)
		var top := c.x + sqrt(maxf(0.0, c.y * c.y - dx * dx))
		_b(f, ua + 0.005, ub - 0.012, COUR_H + 0.02, maxf(top, sp), 0.008, 0.06, [m["bois1"], m["bois2"], m["bois3"]][i % 3])
	for hb: float in [4.4, 5.3]:
		_b(f, uc - hs + 0.05, uc + 0.35, hb - 0.035, hb + 0.035, 0.06, 0.08, m["fer"])
	_b(f, uc - hs - 0.3, uc + hs + 0.3, COUR_H - 0.03, COUR_H + 0.04, 0.0, 0.45, m["seuil"])
	# outils de forge au mur, groupés près du foyer : latte, tenailles, marteaux, ringard
	var lt := 4.2
	_b(f, lt, lt + 1.5, 5.3, 5.38, 0.0, 0.06, m["bois_clair"])
	var outils := [[0.15, "tenaille"], [0.42, "marteau"], [0.66, "tenaille"], [0.92, "marteau"], [1.2, "ringard"]]
	for o in outils:
		var u: float = lt + float(o[0])
		match str(o[1]):
			"tenaille":
				a.boite_tournee(f, u - 0.04, 4.95, 0.025, 0.72, 0.03, 0.06, 0.08, m["fer"])
				a.boite_tournee(f, u + 0.04, 4.95, 0.025, 0.72, 0.03, 0.06, -0.08, m["fer"])
			"marteau":
				_b(f, u - 0.02, u + 0.02, 4.85, 5.3, 0.03, 0.06, m["bois_clair"])
				_b(f, u - 0.09, u + 0.09, 4.78, 4.88, 0.025, 0.08, m["fer"])
			"ringard":
				_b(f, u - 0.015, u + 0.015, 4.3, 5.32, 0.03, 0.055, m["fer"])
	# suie sur le mur, de part et d'autre de la hotte
	for s in [[1.45, 1.75], [3.85, 4.1]]:
		_b(f, s[0], s[1], 5.3, 6.6, 0.0, 0.006, m["suie_claire"])


func _corniches() -> void:
	# corniche sur corbeaux sous le débord du toit (sud, est, ouest), plus saillante au-dessus de l'avant-corps
	for cote: String in ["s", "e", "o"]:
		var f := _f(cote)
		var L: float = f["L"]
		# P7.10.1 (correctif) : angles d'équerre. Sud : 0,3 m de saillie, retourné jusqu'au nu des corniches latérales ;
		# est / ouest : 0,42 m (assise des pignons de pierre, qui débordent de 0,38 m), arrêtées au nu de la corniche sud.
		if cote == "s":
			_b(f, -0.42, L + 0.42, CORNICHE, CORNICHE + 0.13, 0.0, 0.3, m["taille_a"])
		else:
			_b(f, -0.3, L + 0.3, CORNICHE, CORNICHE + 0.13, 0.0, 0.42, m["taille_a"])
		_b(f, -0.16, L + 0.16, CORNICHE - 0.1, CORNICHE, 0.0, 0.16, m["taille_b"])
		var u := 0.45
		var k := 0
		while u < L - 0.3:
			var sur_ac: bool = cote == "s" and u > AVANT_CORPS.x - 0.2 and u < AVANT_CORPS.y + 0.2
			var cheminee: bool = cote == "o" and u > 1.4 and u < 4.2
			if not sur_ac and not cheminee:
				_b(f, u - 0.08, u + 0.08, CORNICHE - 0.36, CORNICHE - 0.1, 0.0, 0.13, m["taille_b"] if k % 2 == 0 else m["taille_a"])
				_b(f, u - 0.09, u + 0.09, CORNICHE - 0.1, CORNICHE, 0.13, 0.24, m["taille_a"])
			u += 0.85
			k += 1
	var fs := _f("s")
	_b(fs, AVANT_CORPS.x - 0.2, AVANT_CORPS.y + 0.2, CORNICHE, CORNICHE + 0.15, 0.0, SAILLIE + 0.16, m["taille_a"])


## Pignons de pierre sous les rives du toit (est, ouest) : triangle extrudé, mur courant.
func _pignons() -> void:
	# au nu des rives du toit (débord de 0,3 m) : le pignon reçoit la lumière comme le mur. P7.10.1 (correctif) : il est
	# ASSIS sur la corniche latérale (plus de pied flottant ni d'extrémité en porte-à-faux), sur toute la longueur de la
	# corniche ; rampants de pierre sous la rive des tuiles et sommiers aux pieds.
	var y0 := CORNICHE + 0.13
	var yp := 10.4
	var z0 := R.position.y - 0.3
	var z1 := R.end.y + 0.3
	for x0: float in [R.position.x - 0.38, R.end.x - 0.4]:
		_prisme_pignon(x0, x0 + 0.78, z0, z1, y0, yp)


## Rampants (finition de rive) et sommiers des pignons : pierre de taille, à l'aplomb du pignon, sous les tuiles.
func _rives() -> void:
	var y0 := CORNICHE + 0.13
	var yp := 10.4
	var z0 := R.position.y - 0.3
	var z1 := R.end.y + 0.3
	var zm := (z0 + z1) * 0.5
	var dz := zm - z0
	var dy := yp - y0
	var lg := sqrt(dz * dz + dy * dy)
	var th := atan2(dy, dz)
	for xc: float in [R.position.x - 0.26, R.end.x + 0.26]:
		for s: float in [-1.0, 1.0]:
			var ang := -th if s < 0.0 else th
			var c := Vector3(xc, (y0 + yp) * 0.5, (z0 + zm) * 0.5 if s < 0.0 else (zm + z1) * 0.5)
			var up := Vector3(0, cos(ang), sin(ang))
			var rp: MeshInstance3D = a.box(c + up * 0.07, Vector3(0.36, 0.14, lg + 0.06), m["taille_b"])
			rp.basis = Basis(Vector3(1, 0, 0), ang)
			var zs := z0 + 0.22 if s < 0.0 else z1 - 0.22
			a.box(Vector3(xc, y0 + 0.14, zs), Vector3(0.42, 0.28, 0.44), m["taille_a"])


func _prisme_pignon(x0: float, x1: float, z0: float, z1: float, yb: float, yp: float) -> void:
	var zm := (z0 + z1) * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tri := func(p: Vector3, q: Vector3, r: Vector3) -> void:
		var nrm := (q - p).cross(r - p).normalized()
		for v: Vector3 in [p, r, q]:
			st.set_normal(nrm)
			st.set_uv(Vector2(v.z, v.y))
			st.add_vertex(v)
	for x: float in [x0, x1]:
		var p := Vector3(x, yb, z0)
		var q := Vector3(x, yb, z1)
		var r := Vector3(x, yp, zm)
		if x == x0:
			tri.call(p, q, r)
		else:
			tri.call(q, p, r)
	# versants (sous les tuiles) : deux quads
	for pr in [[Vector3(0, yb, z0), Vector3(0, yp, zm)], [Vector3(0, yp, zm), Vector3(0, yb, z1)]]:
		var pa: Vector3 = pr[0]
		var pb: Vector3 = pr[1]
		var a0 := Vector3(x0, pa.y, pa.z)
		var a1 := Vector3(x1, pa.y, pa.z)
		var b0 := Vector3(x0, pb.y, pb.z)
		var b1 := Vector3(x1, pb.y, pb.z)
		tri.call(a0, b0, b1)
		tri.call(a0, b1, a1)
	st.generate_tangents()                                # même format que les boîtes (fusion par matière)
	var mi := MeshInstance3D.new()
	var mesh := st.commit()
	mi.mesh = mesh
	mi.material_override = m["mur"]
	a.racine.add_child(mi)


# ------------------------------------------------------------------------------------------------ foyer et atelier
## Foyer de forge adossé au pignon ouest : foyer maçonné à braises, hotte de pierre en encorbellement sur deux piles,
## souche de cheminée qui monte le long du pignon et dépasse le faîtage ; suie.
func _foyer() -> void:
	var xm := R.position.x
	var z0 := 77.9
	var z1 := 80.1
	var zc := (z0 + z1) * 0.5
	# foyer
	a.box(Vector3((41.8 + xm) * 0.5, (COUR_H + 4.78) * 0.5, zc), Vector3(xm - 41.8, 4.78 - COUR_H, z1 - z0), m["socle"])
	for bord in [[41.75, 41.95, z0, z1], [41.75, xm, z0 - 0.05, z0 + 0.15], [41.75, xm, z1 - 0.15, z1 + 0.05]]:
		a.box(Vector3((bord[0] + bord[1]) * 0.5, 4.85, (bord[2] + bord[3]) * 0.5), Vector3(bord[1] - bord[0], 0.14, bord[3] - bord[2]), m["taille_a"])
	a.box(Vector3(42.95, 4.81, zc), Vector3(1.9, 0.04, 1.9), m["braise"])
	for p in [[42.5, 78.6], [43.1, 79.3], [42.8, 79.0], [43.4, 78.5], [42.3, 79.5]]:
		a.box(Vector3(p[0], 4.84, p[1]), Vector3(0.24, 0.04, 0.2), m["braise_vive"])
	a.box(Vector3(43.6, 4.86, 78.4), Vector3(0.5, 0.06, 0.35), m["suie"])
	# piles et hotte en encorbellement (gradins), dessous noirci
	for zp: float in [z0 - 0.05, z1 + 0.05]:
		a.box(Vector3(41.82, (4.92 + 5.75) * 0.5, zp), Vector3(0.22, 5.75 - 4.92, 0.22), m["taille_b"])
	var gradins := [[41.6, 5.75, 6.0, 0.2, m["suie_claire"]], [41.85, 6.0, 6.42, 0.35, m["suie_claire"]], [42.15, 6.42, 6.92, 0.5, m["mur"]], [42.45, 6.92, 7.45, 0.65, m["mur"]]]
	for g in gradins:
		var gx0: float = g[0]
		a.box(Vector3((gx0 + xm) * 0.5, (float(g[1]) + float(g[2])) * 0.5, zc), Vector3(xm - gx0, float(g[2]) - float(g[1]), (z1 - z0) + 0.4 - float(g[3])), g[4])
	a.box(Vector3((41.62 + xm) * 0.5, 5.77, zc), Vector3(xm - 41.62 + 0.02, 0.06, z1 - z0 + 0.44), m["taille_a"])
	# souche
	var sx0 := 42.75
	var top := 12.2
	a.box(Vector3((sx0 + xm) * 0.5, (7.45 + top - 0.7) * 0.5, zc), Vector3(xm - sx0, top - 0.7 - 7.45, 1.5), m["mur"])
	a.box(Vector3((sx0 + xm) * 0.5, top - 0.35, zc), Vector3(xm - sx0, 0.7, 1.5), m["suie_claire"])
	for i in 6:
		var y := 7.7 + i * 0.75
		a.box(Vector3(sx0 - 0.02 + 0.0, y, zc - 0.75 + (0.25 if i % 2 == 0 else 0.15)), Vector3(0.06, 0.33, 0.5 if i % 2 == 0 else 0.3), m["taille_b"])
	a.box(Vector3((sx0 - 0.12 + xm + 0.12) * 0.5, top + 0.07, zc), Vector3(xm - sx0 + 0.24, 0.14, 1.74), m["taille_a"])
	for dz: float in [-0.38, 0.38]:
		a.box(Vector3(43.35, top + 0.32, zc + dz), Vector3(0.36, 0.36, 0.36), m["taille_b"])
		a.box(Vector3(43.35, top + 0.51, zc + dz), Vector3(0.22, 0.03, 0.22), m["suie"])
	# sol noirci autour du foyer et de l'enclume
	var ms: MeshInstance3D = a.box(Vector3(42.0, COUR_H + 0.034, 80.4), Vector3(3.9, 0.008, 4.6), m["sol_suie"])
	ms.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Atelier : billot de l'enclume, bac de trempe (eau sombre), soufflet, appentis de planches sur la zone de travail.
func _atelier() -> void:
	# plate-forme de la cour (bloc des données bat_echoppe_no, inchangé) : parement, dallage, bordure sur la place
	a.box(Vector3(40.0, (3.5 + COUR_H) * 0.5, 82.0), Vector3(8.04, COUR_H - 3.5 + 0.02, 12.04), m["socle"])
	a.box(Vector3(40.0, COUR_H + 0.015, 82.0), Vector3(8.0, 0.03, 12.0), a.macon("dallage2", Archi.PIERRE_VILLE * 0.95, COUR_H))
	a.box(Vector3(40.0, COUR_H + 0.05, 88.0), Vector3(8.1, 0.1, 0.3), m["taille_b"])
	# billot
	var bil := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.32
	cm.bottom_radius = 0.36
	cm.height = 0.42
	cm.radial_segments = 10
	cm.rings = 1
	bil.mesh = cm
	bil.material_override = m["bois2"]
	bil.position = Vector3(41.3, COUR_H + 0.21, 81.25)
	a.racine.add_child(bil)
	# eau du bac de trempe
	a.box(Vector3(42.65, COUR_H + 0.5, 81.95), Vector3(0.5, 0.02, 0.5), m["eau"])
	# soufflet (planches en coin, cuir), sur tréteau, buse vers le foyer
	a.box(Vector3(42.4, COUR_H + 0.45, 77.45), Vector3(1.0, 0.9, 0.12), m["bois3"])
	var p1: MeshInstance3D = a.box(Vector3(42.3, COUR_H + 1.02, 77.45), Vector3(1.1, 0.05, 0.6), m["bois_clair"])
	p1.basis = Basis(Vector3(0, 0, 1), 0.12)
	a.box(Vector3(42.25, COUR_H + 0.95, 77.45), Vector3(0.95, 0.1, 0.56), m["cuir"])
	a.box(Vector3(42.95, COUR_H + 0.93, 77.75), Vector3(0.06, 0.06, 0.55), m["fer"])
	# appentis (P7.10.1, correctif) : couverture de tuiles canal (demi-toiture Quaternius, faîtage noyé dans le mur de la
	# forge, même matière que le grand toit) en pente vers l'ouest, SOUS les corbeaux de la corniche ; poteaux, jambes de
	# force, sablière et chevrons visibles dessous.
	var za := 80.45
	var zb := 85.9
	var bas := 5.5                       # dessus de la sablière (rive basse x 39,6)
	var haut := 6.42                     # contre le mur, sous les corbeaux (6,59)
	var pente := (haut - bas) / (R.position.x - 39.6)
	for zp: float in [za + 0.25, zb - 0.25]:
		a.box(Vector3(39.75, (COUR_H + bas - 0.16) * 0.5, zp), Vector3(0.18, bas - 0.16 - COUR_H, 0.18), m["bois2"])
		var jf: MeshInstance3D = a.box(Vector3(39.95, bas - 0.42, zp), Vector3(0.5, 0.08, 0.08), m["bois2"])
		jf.basis = Basis(Vector3(0, 0, 1), 0.7)
	a.box(Vector3(39.75, bas - 0.08, (za + zb) * 0.5), Vector3(0.2, 0.16, zb - za), m["bois2"])
	var x := 39.65
	while x < R.position.x:
		var c: MeshInstance3D = a.box(Vector3(x, bas + (x - 39.6) * pente - 0.05, (za + zb) * 0.5), Vector3(0.06, 0.07, zb - za + 0.2), m["bois3"])
		c.basis = Basis(Vector3(0, 0, 1), atan(pente))
		x += 0.55


## Couverture de l'appentis : pan de tuiles canal procédurales (matière « tuiles » de la galerie B du Colisée, rangs de
## 32 cm, teintée sur la terre cuite de la forge), UV en mètres (rangs parallèles à l'égout) ; voligeage de planches
## dessous (épaisseur visible aux rives), planche d'égout et planches de rive. Maillage à part (hors fusion des boîtes).
func _tuiles_appentis() -> void:
	var za := 80.45
	var zb := 85.9
	var xe := 39.45
	var xf := R.position.x
	var ye := 5.56
	var yf := 6.5
	var dx := xf - xe
	var dy := yf - ye
	var lg := sqrt(dx * dx + dy * dy)
	var ang := atan2(dy, dx)
	var mt := (a.macon("tuiles", Color(1.32, 1.1, 0.98), ye, "maillage") as ShaderMaterial)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := Vector3(-dy, dx, 0.0).normalized()
	var pa := Vector3(xe, ye, za)
	var pb := Vector3(xe, ye, zb)
	var pc := Vector3(xf, yf, zb)
	var pd := Vector3(xf, yf, za)
	var uvs := {pa: Vector2(za, 0.0), pb: Vector2(zb, 0.0), pc: Vector2(zb, -lg), pd: Vector2(za, -lg)}
	for tri in [[pa, pc, pb], [pa, pd, pc]]:
		for v: Vector3 in tri:
			st.set_normal(n)
			st.set_uv(uvs[v])
			st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.name = "forge_d_appentis_tuiles"
	mi.mesh = st.commit()
	mi.material_override = mt
	a.racine.add_child(mi)
	var d0: int = a.racine.get_child_count()
	var c := Vector3((xe + xf) * 0.5, (ye + yf) * 0.5, (za + zb) * 0.5)
	var vol: MeshInstance3D = a.box(c - n * 0.045, Vector3(lg + 0.04, 0.07, zb - za), m["bois3"])
	vol.basis = Basis(Vector3(0, 0, 1), ang)
	a.box(Vector3(xe - 0.02, ye - 0.06, (za + zb) * 0.5), Vector3(0.05, 0.16, zb - za + 0.08), m["bois2"])          # égout
	for zr: float in [za - 0.03, zb + 0.03]:
		var rv: MeshInstance3D = a.box(c + Vector3(0, 0.01, zr - c.z), Vector3(lg + 0.06, 0.16, 0.05), m["bois2"])  # rives
		rv.basis = Basis(Vector3(0, 0, 1), ang)
	a.fusionner(d0, "forge_d_appentis_bois")


## Enseigne d'armurerie : potence de fer forgé (bras, jambe de force, volute), chaînes ; bouclier et épées (modèles).
func _enseigne() -> void:
	var f := _f("s")
	var u := 10.15
	var v := 6.28
	_b(f, u - 0.06, u + 0.06, v - 0.66, v + 0.12, 0.0, 0.05, m["fer"])                    # platine
	_b(f, u - 0.035, u + 0.035, v - 0.035, v + 0.035, 0.0, 1.4, m["fer"])                  # bras
	_b(f, u - 0.45, u + 0.45, v - 0.03, v + 0.03, 0.97, 1.03, m["fer"])                    # traverse
	_b(f, u - 0.05, u + 0.05, v - 0.05, v + 0.05, 1.38, 1.48, m["fer"])                    # bouton
	var jf: MeshInstance3D = a.box(Vector3(R.position.x + u, v - 0.32, R.end.y + 0.5), Vector3(0.035, 1.18, 0.035), m["fer"])
	jf.basis = Basis(Vector3(1, 0, 0), 1.016)                                              # jambe de force
	for s: float in [-1.0, 1.0]:
		_b(f, u + s * 0.3 - 0.012, u + s * 0.3 + 0.012, v - 0.36, v, 0.988, 1.012, m["fer"])   # chaînes


func _lanterne(u: float) -> void:
	var f := _f("s")
	var v := 5.55
	_b(f, u - 0.05, u + 0.05, v + 0.25, v + 0.55, 0.0, 0.04, m["fer"])
	_b(f, u - 0.025, u + 0.025, v + 0.48, v + 0.53, 0.0, 0.42, m["fer"])
	_b(f, u - 0.13, u + 0.13, v - 0.08, v + 0.26, 0.24, 0.5, m["lanterne"])
	_b(f, u - 0.16, u + 0.16, v + 0.26, v + 0.33, 0.21, 0.53, m["fer"])
	_b(f, u - 0.08, u + 0.08, v + 0.33, v + 0.42, 0.29, 0.45, m["fer"])
	_b(f, u - 0.15, u + 0.15, v - 0.12, v - 0.08, 0.22, 0.52, m["fer"])
	for s: float in [-1.0, 1.0]:
		for t: float in [0.24, 0.5]:
			_b(f, u + s * 0.13 - 0.015, u + s * 0.13 + 0.015, v - 0.08, v + 0.26, t - 0.015, t + 0.015, m["fer"])


# ------------------------------------------------------------------------------------------------ modèles, toit, lumière
func _modeles() -> void:
	var depuis: int = a.racine.get_child_count()
	var u := 10.15
	var x := R.position.x + u
	var y := R.end.y
	# enseigne : bouclier ×1,5 et deux épées croisées derrière
	for s: float in [-1.0, 1.0]:
		var ep: Node3D = fo._modele("fp/Sword_Bronze", Vector3(x + s * 0.05, 5.42, y + 0.95), 0.0, Vector3.ONE * 1.15)
		ep.rotation = Vector3(0, 0, s * 0.68)
	fo._modele("fp/Shield_Wooden", Vector3(x, 5.48, y + 1.0), 0.0, Vector3.ONE * 1.5)
	# atelier
	fo._modele("fp/Anvil", Vector3(41.3, COUR_H + 0.42, 81.25), 0.25, Vector3.ONE * 0.95)
	fo._modele("fp/Barrel", Vector3(42.65, COUR_H, 81.95), 0.0, Vector3(1.0, 0.55, 1.0))
	fo._modele("fp/Bucket_Metal", Vector3(41.95, COUR_H, 82.6), 0.4)
	fo._modele("fp/Whetstone", Vector3(38.9, COUR_H, 84.5), 0.5)
	fo._modele("fp/WeaponStand", Vector3(37.4, COUR_H, 86.4), 0.0)
	fo._modele("fp/Barrel", Vector3(37.2, COUR_H, 77.3), 0.0)
	fo._modele("fp/Crate_Wooden", Vector3(38.1, COUR_H, 77.25), 0.25)
	fo._modele("fp/Shield_Wooden", Vector3(R.position.x - 0.03, 5.15, 86.7), -PI * 0.5, Vector3.ONE * 1.05)
	fo._fusion_gltf(depuis, "forge_d_modeles")


## Toit Quaternius conservé (position, échelle), tuiles en matière variée (tuiles_p7101) ; suie autour de la souche.
func _toit() -> void:
	var kz := (R.size.y + 0.9) / 9.96
	var toit: Node3D = fo._modele("mv/Roof_RoundTiles_8x12", Vector3(R.get_center().x, H1, R.get_center().y), PI * 0.5, Vector3(kz, 0.55, (R.size.x + 0.6) / 14.14))
	_habiller_tuiles(toit, true)


## Matière des tuiles (tuiles_p7101) sur un toit Quaternius ; rives de bois assombries.
func _habiller_tuiles(toit: Node3D, suie: bool) -> void:
	for mi in toit.find_children("*", "MeshInstance3D", true, false):
		var mm := mi as MeshInstance3D
		for s in mm.mesh.get_surface_count():
			var m0: Material = mm.get_active_material(s)
			if not (m0 is StandardMaterial3D):
				continue
			var sm := m0 as StandardMaterial3D
			var chemin := str(sm.albedo_texture.resource_path if sm.albedo_texture else "")
			var cle := "p7101|tuiles|%s|%s" % [chemin, suie]
			if not a._mats.has(cle):
				if chemin.contains("RoundTiles"):
					var sh := ShaderMaterial.new()
					sh.shader = TUILES_SH
					sh.set_shader_parameter("albedo_tex", sm.albedo_texture)
					sh.set_shader_parameter("normal_tex", sm.normal_texture)
					sh.set_shader_parameter("uv_echelle", sm.uv1_scale)
					sh.set_shader_parameter("uv_decalage", sm.uv1_offset)
					if suie:
						sh.set_shader_parameter("suie_centre", Vector3(43.35, 0.0, 79.0))
						sh.set_shader_parameter("suie_rayon", 2.6)
					a._mats[cle] = sh
				else:
					var m1 := sm.duplicate() as StandardMaterial3D
					m1.albedo_color = Color(0.62, 0.52, 0.46)
					a._mats[cle] = m1
			mm.set_surface_override_material(s, a._mats[cle])


func _lumiere_et_fumee() -> void:
	var l := OmniLight3D.new()
	l.name = "forge_d_foyer"
	l.position = Vector3(42.7, 5.25, 79.0)
	l.light_color = Color(1.0, 0.52, 0.22)
	l.light_energy = 2.2
	l.omni_range = 5.0
	l.omni_attenuation = 1.2
	l.shadow_enabled = false
	a.racine.add_child(l)
	var p := CPUParticles3D.new()
	p.name = "forge_d_fumee"
	p.position = Vector3(43.35, 12.75, 79.0)
	p.amount = 14
	p.lifetime = 5.0
	p.preprocess = 5.0
	p.direction = Vector3(0.25, 1.0, 0.1)
	p.spread = 12.0
	p.initial_velocity_min = 0.35
	p.initial_velocity_max = 0.6
	p.gravity = Vector3(0.12, 0.08, 0.0)
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.1
	var courbe := Curve.new()
	courbe.add_point(Vector2(0.0, 0.45))
	courbe.add_point(Vector2(1.0, 1.6))
	p.scale_amount_curve = courbe
	var grad := Gradient.new()
	grad.set_color(0, Color(0.42, 0.40, 0.38, 0.45))
	grad.set_color(1, Color(0.62, 0.60, 0.58, 0.0))
	p.color_ramp = grad
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.9)
	var mq := StandardMaterial3D.new()
	mq.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mq.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mq.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mq.vertex_color_use_as_albedo = true
	mq.albedo_texture = _disque()
	q.material = mq
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	a.racine.add_child(p)


## Petite texture ronde et douce pour la fumée (générée, 32²).
func _disque() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length() / 15.5
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0) ** 1.6))
	return ImageTexture.create_from_image(img)
