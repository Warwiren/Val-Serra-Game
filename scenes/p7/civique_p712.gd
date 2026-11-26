extends RefCounted
## P7.12 — QUARTIER CIVIQUE ET PERSPECTIVE DU CHÂTEAU (lot 4 de la grande place : fond nord, montée civique, administration).
## Axe x 70 : place -> volée C -> palier -> volée D -> terrasse civique -> avenue -> PORTE FORTIFIÉE (y 40), centrée sur la
## silhouette lointaine du château (données « chateau », x 70). Pierre et volumes monumentaux, calcaire plus froid que la
## forge D (référence de qualité des raccords, pas d'architecture copiée) ; le château garde ses ardoises.
## Collisions : TOUTES celles des données (terrasses, volées, socles, garde-corps, administration, grille, guérites).
## L'affichage seul est ajouté ; rien de praticable n'est créé derrière la porte (château = instance future).
## Cadrage : la caméra de la ville ne montre que ≈ 4° au-dessus de l'horizon ; depuis la place (≈ 85 m), seule la bande
## 8 -> 14 m de la porte entre dans le cadre : arc, herse, meurtrières et blason y sont lisibles ; tours, mâchicoulis,
## créneaux et toits coniques se découvrent en montant (terrasse, avenue).

const Archi := preload("res://scenes/p7/archi_p77.gd")
const Refonte := preload("res://scenes/p7/forge_p7101.gd")
const H1 := 3.5
const H2 := 8.0
const AXE := 70.0
const ARDOISE := Color(0.30, 0.31, 0.35)

const TERRASSES := ["palier_2", "terrasse_haute", "avenue_chateau", "pied_volee_c", "pied_volee_d"]
const VOLEES := ["volee_c", "volee_d"]
const SOCLES := ["socle_palier_2", "socle_palier_2b", "bat_b_arriere_forge"]
const GARDE_CORPS := ["gc_terrasse_o", "gc_terrasse_e", "gc_palier_2_o"]
const ADMIN := "bat_administration"
const GARDE := "bat_b_terrasse_no"        # corps de garde du châtelet (flanc ouest de l'avenue)
const PORTES_DECO := {"bat_administration": "s", "bat_b_terrasse_no": "s"}

var sc
var vl                                  # ville (ville_v07b.gd)
var a                                   # Archi
var fo                                  # forge (helpers Quaternius)
var ref                                 # forge D (outils d'arcs : _mur_perce, _claveaux)
var m := {}
var actif := true


func _init(scene, ville, archi, forge) -> void:
	sc = scene
	vl = ville
	a = archi
	fo = forge
	actif = str(scene._cli.get("civique", "1")) != "0"
	if actif:
		ref = Refonte.new(forge)
		_matieres()
		ref.m = m


func gere(id: String) -> bool:
	return actif and (id in TERRASSES or id in SOCLES or id in GARDE_CORPS or id == ADMIN or id == GARDE)


# ------------------------------------------------------------------------------------------------ matières
func _pierre(nom: String, base: String, teinte: Color, regl: Dictionary, base_y := H2) -> ShaderMaterial:
	var cle := "p712|" + nom
	if a._mats.has(cle):
		return a._mats[cle]
	var mt := (a.macon(base, teinte, base_y) as ShaderMaterial).duplicate() as ShaderMaterial
	for k in regl:
		mt.set_shader_parameter(k, regl[k])
	a._mats[cle] = mt
	return mt


func _matieres() -> void:
	# calcaire civique : gros appareil régulier, plus froid et plus clair que la forge ; soutènements plus sombres et salis
	m["mur"] = _pierre("mur", "mur2", Color(1.30, 1.25, 1.16), {"assises": Vector3(0.48, 0.40, 0.44), "long_bloc": 1.1, "irregulier": 0.06, "rapieces": 0.03})
	m["soutenement"] = _pierre("soutenement", "contrefort", Color(1.16, 1.12, 1.06), {"salissure": 0.5, "coulures": 0.45}, H1)
	m["bossage"] = _pierre("bossage", "socle2", Color(1.36, 1.30, 1.20), {"assises": Vector3(0.55, 0.55, 0.55), "long_bloc": 1.3})
	var taille := {"assises": Vector3(3.0, 3.0, 3.0), "long_bloc": 4.0, "var_long": 0.0, "joint": 0.0, "salissure": 0.2,
		"coulures": 0.15, "mousse": 0.0, "fissures": 0.0, "rapieces": 0.0, "irregulier": 0.0, "usure": 0.35, "k_mousse": 0.0}
	m["taille_a"] = _pierre("taille_a", "mur2", Color(1.48, 1.40, 1.28), taille)
	m["taille_b"] = _pierre("taille_b", "mur2", Color(1.38, 1.31, 1.20), taille)
	m["chateau"] = _pierre("chateau", "contrefort", Color(1.24, 1.21, 1.17), {"salissure": 0.35, "coulures": 0.5, "assises": Vector3(0.6, 0.5, 0.55), "long_bloc": 1.3}, H2)
	m["dallage"] = _pierre("dallage", "dallage2", Color(1.22, 1.18, 1.12), {}, H2)
	m["dalle_axe"] = a.macon("dalle", Color(1.18, 1.14, 1.08), H2, "monde", false)
	m["joint"] = a.plein(Color(0.20, 0.18, 0.16))
	m["sombre"] = a.plein(Color(0.05, 0.045, 0.045), 0.9)
	m["fer"] = a.plein(Color(0.16, 0.16, 0.17), 0.5, 0.0, 0.6)
	m["chene"] = a.plein(Color(0.24, 0.17, 0.11), 0.9)
	m["ardoise"] = a.plein(ARDOISE, 0.8)
	m["ardoise_s"] = a.plein(ARDOISE.darkened(0.25), 0.8)
	m["blason"] = a.plein(Color(0.55, 0.14, 0.16), 0.7)
	m["or"] = a.plein(Color(0.80, 0.62, 0.26), 0.35, 0.0, 0.6)
	m["azur"] = a.plein(Color(0.16, 0.24, 0.52), 0.7)
	m["lanterne"] = a.plein(Color(1.0, 0.70, 0.36), 0.5, 1.4)
	m["enduit"] = a.enduit(Color(0.88, 0.82, 0.70), H2, 30.0)


# ------------------------------------------------------------------------------------------------ éléments des données
func construit(e: Dictionary) -> void:
	var id := str(e["id"])
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	if id in TERRASSES:
		sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_FLOOR)
		_terrasse(id, r, h0, h1)
	elif id in SOCLES:
		sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_OBST)
		_socle(id, r, h0, h1)
	elif id in GARDE_CORPS:
		sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_OBST)
		_balustrade(r, h0, h1)
	elif id == ADMIN:
		sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_OBST)
		_administration(r, h0, h1)
	elif id == GARDE:
		sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_OBST)
		_corps_de_garde(r, h0, h1)


## Terrasse (palier, terrasse civique, avenue, pieds de volées) : corps de pierre (murs de soutènement), dallage civique ;
## sur l'axe, voie processionnelle de longues dalles claires (prolonge celle de la place), bordure au bord sud.
func _terrasse(id: String, r: Rect2, h0: float, h1: float) -> void:
	var d0: int = a.racine.get_child_count()
	var mc: MeshInstance3D = a.box(Archi.centre(r, h0, h1 - 0.3), Vector3(r.size.x, h1 - 0.3 - h0, r.size.y), m["soutenement"])
	mc.name = "soutenement_" + id
	var md: MeshInstance3D = a.box(Archi.centre(r, h1 - 0.3, h1), Vector3(r.size.x, 0.3, r.size.y), m["dallage"])
	md.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if id in ["terrasse_haute", "avenue_chateau"]:
		var x0 := maxf(r.position.x, AXE - 2.0)
		var x1 := minf(r.end.x, AXE + 2.0)
		var y0 := r.position.y + (0.0 if id == "avenue_chateau" else 0.0)
		a.box(Vector3((x0 + x1) * 0.5, h1 + 0.004, (y0 + r.end.y) * 0.5), Vector3(x1 - x0, 0.008, r.end.y - y0), m["dalle_axe"])
		for xe: float in [x0 + 0.08, x1 - 0.08]:
			a.box(Vector3(xe, h1 + 0.006, (y0 + r.end.y) * 0.5), Vector3(0.14, 0.01, r.end.y - y0), m["joint"])
		var y := r.end.y - 1.2
		while y > y0 + 0.6:
			a.box(Vector3(AXE, h1 + 0.007, y), Vector3(x1 - x0 - 0.3, 0.01, 0.05), m["joint"])
			y -= 2.4
	if id == "terrasse_haute":
		a.box(Vector3(r.get_center().x, h1 + 0.005, r.end.y - 0.45), Vector3(r.size.x, 0.008, 0.9), m["taille_b"])
	a.fusionner(d0, "civique_" + id)


## Murs de soutènement et socles (pierre) : soubassement, pilastres plats (saillie ≤ 0,1 m : pas de relief traversable),
## cordon, couronnement ; blason de la ville au centre du socle sur l'axe ; dessus dallé.
func _socle(id: String, r: Rect2, h0: float, h1: float) -> void:
	var d0: int = a.racine.get_child_count()
	a.box(Archi.centre(r, h0, h1 - 0.02), Vector3(r.size.x, h1 - h0 - 0.02, r.size.y), m["soutenement"])
	var md: MeshInstance3D = a.box(Archi.centre(r, h1 - 0.05, h1), Vector3(r.size.x - 0.02, 0.05, r.size.y - 0.02), m["dallage"])
	md.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var faces: Array = []
	match id:
		"socle_palier_2":
			faces = ["s", "o"]
		"socle_palier_2b":
			faces = ["s", "o"]
		"bat_b_arriere_forge":
			faces = ["e"]
	for cote: String in faces:
		var f := Archi.face(r, cote)
		var L: float = f["L"]
		a.boite(f, -0.06, L + 0.06, h0, h0 + 0.5, 0.0, 0.1, m["taille_b"])                # soubassement
		a.boite(f, -0.08, L + 0.08, h1 - 0.42, h1 - 0.3, 0.0, 0.1, m["taille_a"])         # cordon
		a.boite(f, -0.1, L + 0.1, h1 - 0.12, h1 + 0.06, 0.0, 0.14, m["taille_a"])         # couronnement
		var n := maxi(1, int(round(L / 3.2)))
		for i in range(1, n):
			var u := L * i / n
			a.boite(f, u - 0.32, u + 0.32, h0 + 0.5, h1 - 0.42, 0.0, 0.08, m["taille_b"])  # pilastre
	if id == "socle_palier_2":
		_blason(Archi.face(r, "s"), AXE - r.position.x, h0 + 1.25, 0.1)
	a.fusionner(d0, "civique_" + id)


## Blason de Val'Serra (relief) : écu de gueules, bande d'or, chef d'azur, couronne de pierre ; cartouche.
func _blason(f: Dictionary, u: float, v: float, d: float) -> void:
	a.boite(f, u - 0.75, u + 0.75, v - 0.85, v + 0.95, d - 0.04, d, m["taille_a"])          # cartouche
	for i in 6:
		var t := float(i) / 6.0
		var hw := 0.5 * (1.0 - pow(t, 2.2) * 0.85)
		a.boite(f, u - hw, u + hw, v + 0.45 - (i + 1) * 0.16, v + 0.45 - i * 0.16, d, d + 0.05, m["blason"])
	a.boite(f, u - 0.5, u + 0.5, v + 0.45, v + 0.7, d, d + 0.05, m["azur"])
	a.boite_tournee(f, u, v - 0.05, 1.05, 0.12, d + 0.05, d + 0.07, -0.75, m["or"])
	for k in 3:
		a.boite(f, u - 0.32 + k * 0.32 - 0.07, u - 0.32 + k * 0.32 + 0.07, v + 0.72, v + 0.92, d - 0.02, d + 0.06, m["taille_b"])


## Garde-corps (collision des données, 1 m) : balustrade de pierre : socle, balustres, main courante, dés tous les 3 m.
func _balustrade(r: Rect2, h0: float, h1: float) -> void:
	var d0: int = a.racine.get_child_count()
	var long_x := r.size.x >= r.size.y
	var L := r.size.x if long_x else r.size.y
	var c := r.get_center()
	var ep := minf(r.size.x, r.size.y)
	var bx := func(t0: float, t1: float, y0: float, y1: float, e: float, mt: Material) -> void:
		var tc := (t0 + t1) * 0.5
		var p := Vector3(r.position.x + tc, (y0 + y1) * 0.5, c.y) if long_x else Vector3(c.x, (y0 + y1) * 0.5, r.position.y + tc)
		var s := Vector3(t1 - t0, y1 - y0, e) if long_x else Vector3(e, y1 - y0, t1 - t0)
		a.box(p, s, mt)
	bx.call(0.0, L, h0, h0 + 0.18, ep, m["taille_b"])
	bx.call(-0.05, L + 0.05, h1 - 0.14, h1, ep + 0.1, m["taille_a"])
	var nd := maxi(1, int(round(L / 3.0)))
	for i in nd + 1:
		var t := L * i / nd
		bx.call(t - 0.2, t + 0.2, h0 + 0.18, h1 - 0.14, ep + 0.04, m["taille_a"])
	var t2 := 0.0
	while t2 < L:
		var tc := t2 + 0.15
		if fmod(tc, L / nd) > 0.32 and fmod(tc, L / nd) < L / nd - 0.32:
			bx.call(tc - 0.06, tc + 0.06, h0 + 0.18, h0 + 0.36, ep * 0.55, m["taille_b"])
			bx.call(tc - 0.085, tc + 0.085, h0 + 0.36, h0 + 0.56, ep * 0.6, m["taille_b"])
			bx.call(tc - 0.05, tc + 0.05, h0 + 0.56, h1 - 0.14, ep * 0.45, m["taille_b"])
		t2 += 0.3
	a.fusionner(d0, "civique_balustrade")


# ------------------------------------------------------------------------------------------------ administration
## Administration (quartier haut, sur la terrasse) : deux pavillons et un corps central dont le rez-de-chaussée forme un
## PORCHE en retrait (arc appareillé, porte cochère au fond, 1 m d'embrasure) ; bossage au rez-de-chaussée, étages de
## calcaire, corniche à consoles, balcon de pierre au-dessus du porche, toit en croupe de tuiles. Collision : bloc des données.
func _administration(r: Rect2, h0: float, h1: float) -> void:
	var nv := [h0, 12.2, 15.4, h1]
	var pal: Array = Archi.PALETTES["gris_chaud"]
	var porche := Rect2(r.position.x, 55.4, r.size.x, 4.2)
	var ra := Rect2(r.position.x, r.position.y, r.size.x, porche.position.y - r.position.y)
	var rb := Rect2(r.position.x, porche.end.y, r.size.x, r.end.y - porche.end.y)
	var d0: int = a.racine.get_child_count()
	var desc := func(id: String, faces: Dictionary, balcons: Array) -> Dictionary:
		return {"id": id, "niveaux": nv, "enduit": pal[0], "volets": Color(0.22, 0.24, 0.27), "rdc": "bossage", "etages": "pierre",
			"corniche": "consoles", "toit_h": 4.0, "toit": "aucun", "volets_style": "aucun", "faces": faces, "balcons": balcons}
	# pavillon nord (fenêtres sur la terrasse)
	a.batiment(ra, h0, desc.call("admin_nord", {"e": [[[2.0, 1.1, 1.8, 1.4, "barreaux"], [5.6, 1.1, 1.8, 1.4, "barreaux"], [9.2, 1.1, 1.8, 1.4, "barreaux"]],
		[[2.0, 1.2, 2.1, 0.5, "fenetre_cintree"], [5.6, 1.2, 2.1, 0.5, "fenetre_cintree"], [9.2, 1.2, 2.1, 0.5, "fenetre_cintree"]],
		[[2.0, 1.0, 1.4, 0.5, "fenetre"], [5.6, 1.0, 1.4, 0.5, "fenetre"], [9.2, 1.0, 1.4, 0.5, "fenetre"]]]}, []))
	# pavillon sud (terrasse et façade sud vue de la place, au-dessus de la forge)
	var fen_s := []
	var fen_s1 := []
	var fen_s2 := []
	var u := 1.8
	while u < r.size.x - 1.0:
		if absf(u - 9.0) < 1.4:
			u += 3.1
			continue
		fen_s.append([u, 1.0, 1.6, 1.6, "barreaux"])
		fen_s1.append([u, 1.2, 2.1, 0.5, "fenetre_cintree"])
		fen_s2.append([u, 1.0, 1.4, 0.5, "fenetre"])
		u += 3.1
	a.batiment(rb, h0, desc.call("admin_sud", {"e": [[[2.0, 1.1, 1.8, 1.4, "barreaux"], [5.6, 1.1, 1.8, 1.4, "barreaux"], [9.2, 1.1, 1.8, 1.4, "barreaux"]],
		[[2.0, 1.2, 2.1, 0.5, "fenetre_cintree"], [5.6, 1.2, 2.1, 0.5, "fenetre_cintree"], [9.2, 1.2, 2.1, 0.5, "fenetre_cintree"]],
		[[2.0, 1.0, 1.4, 0.5, "fenetre"], [5.6, 1.0, 1.4, 0.5, "fenetre"], [9.2, 1.0, 1.4, 0.5, "fenetre"]]],
		"s": [fen_s, fen_s1, fen_s2]}, []))
	# corps central : étages au-dessus du porche (porte-fenêtre, balcon de pierre)
	a.batiment(Rect2(porche.position.x, porche.position.y, porche.size.x, porche.size.y), 12.2,
		{"id": "admin_centre", "niveaux": [12.2, 15.4, h1], "enduit": pal[0], "volets": Color(0.22, 0.24, 0.27), "rdc": "pierre",
		"etages": "pierre", "corniche": "consoles", "toit_h": 4.0, "toit": "aucun", "volets_style": "aucun", "chaines": false,
		"faces": {"e": [[[2.1, 1.3, 2.4, 0.0, "porte_fenetre"]], [[2.1, 1.0, 1.4, 0.5, "fenetre"]]]},
		"balcons": [["e", 0.7, 3.5, 0, 0.6, "pierre"]]})
	# porche : mur de façade percé d'un arc (embrasure), porte cochère en retrait, sol dallé, lanternes
	var fp := Archi.face(porche, "e")
	ref._mur_perce(fp, 0.0, porche.size.x, h0, 12.2, -0.45, 0.0, [{"u0": 0.6, "u1": 3.6, "bas": h0, "spring": 10.2, "rise": 1.4}], m["bossage"])
	ref._claveaux(fp, 2.1, 10.2, 1.5, 1.4, 0.36, 11, -0.45, 0.06)
	var fond := Rect2(porche.position.x, porche.position.y, porche.size.x - 1.0, porche.size.y)
	a.box(Archi.centre(fond, h0, 12.2), Vector3(fond.size.x, 12.2 - h0, fond.size.y), m["bossage"])
	a.baie(Archi.face(fond, "e"), 2.1, h0, 2.2, 2.5, "porte_cochere", Color(0.22, 0.24, 0.27), "aucun")
	var fs: MeshInstance3D = a.box(Vector3(r.end.x - 0.5, h0 + 0.01, porche.get_center().y), Vector3(1.0, 0.02, porche.size.y), m["dallage"])
	fs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for uu: float in [0.3, 3.9]:
		a.lanterne(fp, uu, 10.0)
	_blason(fp, 2.1, 12.75, 0.02)
	a.fusionner(d0, "civique_administration")
	# toit en croupe sur l'ensemble (tuiles de la ville)
	var dt: int = a.racine.get_child_count()
	a.toit(r, h1, 4.0, pal[0], "croupe", Color(1.0, 0.95, 0.92))
	a.fusionner(dt, "civique_administration_toit")


# ------------------------------------------------------------------------------------------------ porte fortifiée
## Porte du château (y 40, au bout de l'avenue) : châtelet entre deux tours rondes, arc en plein cintre de 6,4 m sur la
## herse baissée (la grille basse des données reste devant), blason, mâchicoulis, créneaux ; courtines et tours d'angle ;
## toits de la ville haute derrière les remparts. Décor seul : la porte reste fermée (gardes, guérites, grille des données).
func decorer() -> void:
	if not actif:
		return
	var d0: int = a.racine.get_child_count()
	_chatelet()
	for x: float in [62.2, 77.8]:
		_tour_ronde(Vector3(x, H2, 35.2), 3.2, 22.0)
	_courtine(Rect2(40.0, 32.5, 19.2, 2.5), 20.5)
	_courtine(Rect2(80.8, 29.0, 25.2, 2.5), 20.5)
	_tour_carree(Rect2(44.0, 31.0, 5.0, 5.5), 23.0)
	_tour_carree(Rect2(98.0, 27.5, 5.0, 5.5), 23.0)
	_ville_haute()
	a.fusionner(d0, "civique_porte")
	_ecarter(d0)
	var d1: int = a.racine.get_child_count()
	for x: float in [62.2, 77.8]:
		fo._modele("fp/Banner_1_Cloth", Vector3(x, 15.2, 35.2 + 3.25), 0.0, Vector3.ONE * 1.6)
	fo._fusion_gltf(d1, "civique_bannieres")
	_ecarter(d1)


## Les décors au-delà de la porte ne rejoignent aucun volume d'escamotage (ils ne sont jamais entre la caméra et Aren).
func _ecarter(depuis: int) -> void:
	for i in range(depuis, a.racine.get_child_count()):
		var n: Node = a.racine.get_child(i)
		if n is GeometryInstance3D:
			n.set_meta("vol", "aucun")


func _chatelet() -> void:
	var f := {"o": Vector3(65.6, 0, 40.0), "t": Vector3(1, 0, 0), "n": Vector3(0, 0, 1), "L": 8.8}
	var top := 17.2
	var uc := AXE - 65.6
	var hs := 3.2
	var sp := 11.0
	# corps du châtelet derrière la façade (y 31 -> 38,8) et façade épaisse (1,2 m) percée de l'arc
	a.box(Vector3(AXE, (H2 + top) * 0.5, 34.9), Vector3(8.8, top - H2, 7.8), m["chateau"])
	ref._mur_perce(f, 0.0, 8.8, H2, top, -1.2, 0.0, [{"u0": uc - hs, "u1": uc + hs, "bas": H2, "spring": sp, "rise": hs - 0.01}], m["chateau"])
	ref._claveaux(f, uc, sp, hs, hs - 0.01, 0.55, 15, -1.2, 0.1)
	# fond sombre du passage et herse baissée (chêne ferré, pointes au sol)
	a.boite(f, uc - hs, uc + hs, H2, sp + hs, -1.2, -1.19, m["sombre"])
	var x := uc - hs + 0.25
	while x < uc + hs - 0.1:
		var hb := sp + sqrt(maxf(0.0, hs * hs - pow(x - uc, 2.0))) - 0.05
		a.boite(f, x - 0.07, x + 0.07, H2 + 0.05, hb, -0.75, -0.6, m["chene"])
		a.boite(f, x - 0.04, x + 0.04, H2 - 0.02, H2 + 0.12, -0.72, -0.63, m["fer"])
		x += 0.42
	var y := H2 + 0.55
	while y < sp + hs - 0.2:
		var hw := sqrt(maxf(0.0, hs * hs - pow(maxf(y - sp, 0.0), 2.0)))
		a.boite(f, uc - hw + 0.05, uc + hw - 0.05, y - 0.06, y + 0.06, -0.62, -0.5, m["chene"])
		y += 0.62
	# piédroits harpés (blocs de taille dans l'épaisseur), socle, cordon, blason, archères
	var v := H2
	var k := 0
	while v < sp - 0.3:
		for s: float in [-1.0, 1.0]:
			var ue := uc + s * hs
			a.boite(f, minf(ue, ue + s * (0.55 if k % 2 == 0 else 0.35)), maxf(ue, ue + s * (0.55 if k % 2 == 0 else 0.35)), v, v + 0.48, -1.2, 0.05, m["taille_a"] if k % 2 == 0 else m["taille_b"])
		v += 0.5
		k += 1
	a.boite(f, -0.1, 8.9, H2, H2 + 0.6, 0.0, 0.18, m["taille_b"])
	a.boite(f, -0.1, 8.9, 14.75, 14.95, 0.0, 0.14, m["taille_a"])
	_blason(f, uc, 15.9, 0.02)
	for ua: float in [1.0, 7.8]:
		a.boite(f, ua - 0.07, ua + 0.07, 12.0, 13.4, 0.0, 0.02, m["sombre"])
		a.boite(f, ua - 0.22, ua + 0.22, 12.6, 12.75, 0.0, 0.02, m["sombre"])
	# mâchicoulis sur consoles, parapet, créneaux
	_couronnement(f, -0.4, 9.2, top, 0.6)


## Mâchicoulis (consoles en encorbellement), parapet et merlons, sur une face [u0, u1] au sommet `top`.
func _couronnement(f: Dictionary, u0: float, u1: float, top: float, saillie: float) -> void:
	var u := u0 + 0.3
	while u < u1 - 0.2:
		a.boite(f, u - 0.17, u + 0.17, top - 0.9, top - 0.45, 0.0, saillie * 0.5, m["taille_b"])
		a.boite(f, u - 0.17, u + 0.17, top - 0.45, top, 0.0, saillie, m["taille_b"])
		a.boite(f, u + 0.17, u + 0.55, top - 0.25, top, saillie - 0.15, saillie, m["sombre"])
		u += 0.72
	a.boite(f, u0, u1, top, top + 1.1, saillie - 0.45, saillie, m["chateau"])
	var um := u0 + 0.25
	while um < u1 - 0.5:
		a.boite(f, um, um + 0.75, top + 1.1, top + 1.85, saillie - 0.45, saillie, m["chateau"])
		a.boite(f, um - 0.03, um + 0.78, top + 1.85, top + 1.95, saillie - 0.5, saillie + 0.03, m["taille_a"])
		um += 1.25


## Tour ronde : talus, fût, corbeaux, parapet crénelé, toit conique d'ardoise, archères.
func _tour_ronde(base: Vector3, rayon: float, top: float) -> void:
	_cyl(base + Vector3(0, 1.5, 0), rayon, rayon + 0.6, 3.0, m["chateau"])
	_cyl(Vector3(base.x, (base.y + 3.0 + top) * 0.5, base.z), rayon, rayon, top - base.y - 3.0, m["chateau"])
	_cyl(Vector3(base.x, top + 0.3, base.z), rayon + 0.5, rayon, 0.6, m["taille_b"])
	_cyl(Vector3(base.x, top + 1.15, base.z), rayon + 0.5, rayon + 0.5, 1.1, m["chateau"])
	for i in 12:
		var an := TAU * i / 12.0
		var p := Vector3(base.x + cos(an) * (rayon + 0.35), top + 2.05, base.z + sin(an) * (rayon + 0.35))
		var mb: MeshInstance3D = a.box(p, Vector3(0.8, 0.7, 0.3), m["chateau"])
		mb.rotation.y = -an + PI * 0.5
	_cyl(Vector3(base.x, top + 2.4 + 3.0, base.z), 0.0, rayon + 0.75, 6.0, m["ardoise"], 16)
	for hy: float in [12.2, 16.0, 19.5]:
		a.box(Vector3(base.x, hy, base.z + rayon - 0.02), Vector3(0.14, 1.3, 0.1), m["sombre"])


func _cyl(c: Vector3, r_haut: float, r_bas: float, h: float, mt: Material, seg := 20) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_haut
	cm.bottom_radius = r_bas
	cm.height = h
	cm.radial_segments = seg
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mt
	mi.position = c
	a.racine.add_child(mi)


func _courtine(r: Rect2, top: float) -> void:
	a.box(Archi.centre(r, H2, top), Vector3(r.size.x, top - H2, r.size.y), m["chateau"])
	_couronnement(Archi.face(r, "s"), 0.0, r.size.x, top, 0.35)


func _tour_carree(r: Rect2, top: float) -> void:
	a.box(Archi.centre(r, H2, top), Vector3(r.size.x, top - H2, r.size.y), m["chateau"])
	_couronnement(Archi.face(r, "s"), -0.3, r.size.x + 0.3, top, 0.45)
	var c := r.get_center()
	_cyl(Vector3(c.x, top + 1.1 + 2.6, c.y), 0.0, r.size.x * 0.75, 5.2, m["ardoise"], 4)


## Ville haute au-delà des remparts (affichage seul, jamais praticable) : quelques maisons de calcaire à toits de tuiles,
## dont seuls les toits dépassent des courtines ; elles donnent la profondeur de la perspective.
func _ville_haute() -> void:
	var maisons := [[Rect2(41.0, 14.0, 12.0, 9.0), 13.0], [Rect2(55.0, 18.0, 8.0, 10.0), 14.5], [Rect2(80.0, 12.0, 11.0, 9.0), 14.0],
		[Rect2(93.0, 16.0, 9.0, 8.0), 12.5], [Rect2(104.0, 10.0, 12.0, 10.0), 15.0], [Rect2(28.0, 18.0, 10.0, 9.0), 12.0]]
	for mm in maisons:
		var r: Rect2 = mm[0]
		var top := H2 + float(mm[1])
		a.box(Archi.centre(r, H2, top), Vector3(r.size.x, top - H2, r.size.y), m["enduit"])
		a.toit(r, top, minf(r.size.x, r.size.y) * 0.42, Color(0.88, 0.82, 0.70), "2p_x" if r.size.x >= r.size.y else "2p_y", Color(1.0, 0.96, 0.92))


# ------------------------------------------------------------------------------------------------ corps de garde, guérites
## Corps de garde (flanc ouest de l'avenue, adossé au châtelet) : pierre du château, bossage, archères sur l'avenue,
## fenêtres à barreaux sur la terrasse, couronnement de mâchicoulis et de créneaux (même langage que la porte).
func _corps_de_garde(r: Rect2, h0: float, h1: float) -> void:
	var d0: int = a.racine.get_child_count()
	var nv := [h0, 12.0, 15.6, h1 - 1.9]
	var top: float = nv[nv.size() - 1]
	a.batiment(r, h0, {"id": "corps_de_garde", "niveaux": nv, "enduit": Color(0.8, 0.78, 0.74), "volets": Color(0.2, 0.2, 0.22),
		"rdc": "bossage", "etages": "pierre", "corniche": "simple", "toit_h": 3.0, "toit": "aucun", "volets_style": "aucun",
		"faces": {"s": [[[2.0, 0.9, 1.2, 1.8, "barreaux"], [8.0, 0.9, 1.2, 1.8, "barreaux"]],
			[[2.0, 0.9, 1.7, 0.6, "fenetre_cintree"], [5.0, 0.9, 1.7, 0.6, "fenetre_cintree"], [8.0, 0.9, 1.7, 0.6, "fenetre_cintree"]],
			[[3.5, 0.8, 1.2, 0.5, "fenetre"], [6.5, 0.8, 1.2, 0.5, "fenetre"]]],
			"e": [[[3.0, 0.16, 1.4, 1.6, "fenetre_simple"], [7.0, 0.16, 1.4, 1.6, "fenetre_simple"], [11.0, 0.16, 1.4, 1.6, "fenetre_simple"]],
			[[3.0, 0.16, 1.6, 0.8, "fenetre_simple"], [7.0, 0.16, 1.6, 0.8, "fenetre_simple"], [11.0, 0.16, 1.6, 0.8, "fenetre_simple"]], []]}})
	a.box(Archi.centre(r, top, h1), Vector3(r.size.x, h1 - top, r.size.y), m["chateau"])
	for cote: String in ["s", "e"]:
		var f := Archi.face(r, cote)
		_couronnement(f, -0.3, float(f["L"]) + 0.3, h1 - 0.95, 0.45)
	a.fusionner(d0, "civique_corps_de_garde")


## Porte décorative (données) d'un bâtiment du quartier civique : porte cloutée à encadrement de pierre (bibliothèque).
func porte_deco(e: Dictionary) -> bool:
	var bat := str(e["batiment"])
	if not actif or not PORTES_DECO.has(bat):
		return false
	var q: Rect2 = Rect2(40.0, 44.0, 16.0, 27.0) if bat == ADMIN else Rect2(56.0, 36.0, 10.0, 14.0)
	var f := Archi.face(q, str(PORTES_DECO[bat]))
	var d0: int = a.racine.get_child_count()
	a.baie(f, float(e["x"]) - q.position.x, float(e["h"]), float(e["largeur"]) + 0.2, float(e["hauteur"]), "porte_cloutee", Color(0.2, 0.2, 0.22), "aucun")
	a.boite(f, float(e["x"]) - q.position.x - 1.0, float(e["x"]) - q.position.x + 1.0, float(e["h"]) - 0.03, float(e["h"]) + 0.05, 0.0, 0.5, m["taille_b"])
	a.fusionner(d0, "civique_porte_" + bat)
	return true


## Guérite (collision des données) : loge de pierre à toit pyramidal d'ardoise, baie ouverte vers l'avenue, archère.
func guerite(r: Rect2, h0: float) -> void:
	var d0: int = a.racine.get_child_count()
	var top := h0 + 2.7
	a.box(Archi.centre(r, h0, top), Vector3(r.size.x, top - h0, r.size.y), m["chateau"])
	a.box(Archi.centre(r.grow(0.08), h0, h0 + 0.35), Vector3(r.size.x + 0.16, 0.35, r.size.y + 0.16), m["taille_b"])
	a.box(Archi.centre(r.grow(0.1), top - 0.2, top), Vector3(r.size.x + 0.2, 0.2, r.size.y + 0.2), m["taille_a"])
	var vers_axe := 1.0 if r.get_center().x < AXE else -1.0
	var cote := "e" if vers_axe > 0.0 else "o"
	var f := Archi.face(r, cote)
	var L: float = f["L"]
	a.boite(f, L * 0.5 - 0.42, L * 0.5 + 0.42, h0, h0 + 2.0, 0.0, 0.02, m["sombre"])
	a.boite(f, L * 0.5 - 0.56, L * 0.5 + 0.56, h0 + 2.0, h0 + 2.18, 0.0, 0.06, m["taille_a"])
	var fs := Archi.face(r, "s")
	a.boite(fs, float(fs["L"]) * 0.5 - 0.06, float(fs["L"]) * 0.5 + 0.06, h0 + 1.0, h0 + 1.8, 0.0, 0.02, m["sombre"])
	a.fusionner(d0, "civique_guerite")
	_cyl(Vector3(r.get_center().x, top + 0.9, r.get_center().y), 0.0, r.size.x * 0.78, 1.8, m["ardoise"], 4)
	var dc: Node = a.racine.get_child(a.racine.get_child_count() - 1)
	(dc as Node3D).rotation.y = PI * 0.25

