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
const HOTEL := "bat_hotel_de_ville"        # P7.12.1 : pavillon de raccord ouest (flanc est de la porte) + reste en blockout pierre

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
	return actif and (id in TERRASSES or id in SOCLES or id in GARDE_CORPS or id == ADMIN or id == GARDE or id == HOTEL)


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
	# château lointain : pierre plus sombre et plus chaude (contraste sur le ciel clair), ardoise plus profonde
	m["chateau_loin"] = _pierre("chateau_loin", "contrefort", Color(0.98, 0.93, 0.88), {"salissure": 0.3, "coulures": 0.5, "assises": Vector3(0.7, 0.6, 0.65), "long_bloc": 1.5}, H2)
	m["ardoise_loin"] = a.plein(Color(0.22, 0.23, 0.28), 0.8)
	# P7.12.1 : calcaire clair et chaud des bâtiments de la porte (corps de garde, pavillon) ; vitrages ; bannières
	m["calcaire"] = _pierre("calcaire", "mur2", Color(1.56, 1.44, 1.24), {"assises": Vector3(0.46, 0.38, 0.42), "long_bloc": 1.0, "irregulier": 0.05, "rapieces": 0.03, "salissure": 0.22})
	m["bossage_c"] = _pierre("bossage_c", "socle2", Color(1.60, 1.49, 1.30), {"assises": Vector3(0.55, 0.55, 0.55), "long_bloc": 1.3, "salissure": 0.3})
	m["vitre"] = a.plein(Color(0.18, 0.21, 0.25), 0.2, 0.0, 0.3)
	m["vitre_chaude"] = a.plein(Color(0.95, 0.66, 0.36), 0.5, 0.7)
	m["chene_c"] = a.plein(Color(0.30, 0.21, 0.14), 0.9)


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
	elif id == HOTEL:
		sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_OBST)
		_hotel_raccord(r, h0, h1)


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
## P7.12.1 : façades MAÇONNÉES EN ÉPAISSEUR (baies en retrait de 0,45 m, croisées de pierre, appuis, claveaux).
func _administration(r: Rect2, h0: float, h1: float) -> void:
	var pal: Array = Archi.PALETTES["gris_chaud"]
	var porche := Rect2(r.position.x, 55.4, r.size.x, 4.2)
	var ra := Rect2(r.position.x, r.position.y, r.size.x, porche.position.y - r.position.y)
	var rb := Rect2(r.position.x, porche.end.y, r.size.x, r.end.y - porche.end.y)
	var d0: int = a.racine.get_child_count()
	var niv := [h0, 12.2, 15.4, h1]
	var lat := [[2.0, 1.0, "barreaux"], [5.6, 1.0, "barreaux"], [9.2, 1.0, "barreaux"]]
	var fe := func(us: Array) -> Array:
		var o := []
		for u0 in us:
			var u: float = u0
			o.append([u - 0.55, u + 0.55, h0 + 1.3, h0 + 3.0, 0.15, "croisee"])
			o.append([u - 0.6, u + 0.6, 12.6, 14.4, 0.6, "cintree"])
			o.append([u - 0.5, u + 0.5, 15.8, 17.1, 0.12, "croisee"])
		return o
	var us_s := []
	var u := 1.8
	while u < r.size.x - 1.0:
		if absf(u - 9.0) >= 1.4:
			us_s.append(u)
		u += 3.1
	_batiment_civique(ra, niv, {"e": fe.call([2.0, 5.6, 9.2])}, m["mur"], m["bossage"], true)
	var fs_s: Array = fe.call(us_s)
	fs_s.append([8.25, 9.75, h0, 10.9, 0.6, "porte"])                     # porte des données (x 49)
	_batiment_civique(rb, niv, {"e": fe.call([2.0, 5.6, 9.2]), "s": fs_s}, m["mur"], m["bossage"], true)
	# corps central : étages au-dessus du porche (porte-fenêtre sur balcon de pierre, croisée)
	_batiment_civique(porche, [12.2, 15.4, h1], {"e": [[1.45, 2.75, 12.3, 14.9, 0.5, "cintree"], [1.6, 2.6, 15.8, 17.1, 0.12, "croisee"]]}, m["mur"], m["mur"], false)
	a.balcon(Archi.face(porche, "e"), 0.7, 3.5, 12.2, 0.6, "pierre")
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


## P7.12.1 — Bâtiment civique maçonné en épaisseur : corps en retrait de 0,45 m derrière chaque façade listée, façade
## percée de ses baies [u0, u1, bas, naissance, flèche, style] (styles : croisee, cintree, porte, archere, barreaux),
## garnies (claveaux ou plate-bande à clef, appui, croisée de pierre, vitrage, vantaux) ; soubassement, bandeaux d'étage,
## corniche à consoles, chaînes d'angle. niv : [h0, plancher 1, …, sommet]. Le rez-de-chaussée prend `m_rdc`.
func _batiment_civique(r: Rect2, niv: Array, faces: Dictionary, m_mur: Material, m_rdc: Material, corniche := true) -> void:
	var h0: float = niv[0]
	var n1: float = niv[1]
	var top: float = niv[niv.size() - 1]
	var ep := 0.45
	var core := Rect2(r.position + Vector2(0.45 if faces.has("o") else 0.0, 0.45 if faces.has("n") else 0.0),
		r.size - Vector2((0.45 if faces.has("o") else 0.0) + (0.45 if faces.has("e") else 0.0), (0.45 if faces.has("n") else 0.0) + (0.45 if faces.has("s") else 0.0)))
	a.box(Archi.centre(core, h0, top), Vector3(core.size.x, top - h0, core.size.y), m_mur)
	for cote: String in faces:
		var f := Archi.face(r, cote)
		var L: float = f["L"]
		# les façades se recouvrent aux angles : chaque face couvre toute sa longueur, l'épaisseur s'emboîte
		var ouv_rdc := []
		var ouv_haut := []
		for o in faces[cote]:
			var d := {"u0": float(o[0]), "u1": float(o[1]), "bas": float(o[2]), "spring": float(o[3]), "rise": maxf(0.06, float(o[4]))}
			if float(o[2]) < n1 - 0.01:
				ouv_rdc.append(d)
			else:
				ouv_haut.append(d)
		ref._mur_perce(f, 0.0, L, h0, n1, -ep, 0.0, ouv_rdc, m_rdc)
		ref._mur_perce(f, 0.0, L, n1, top, -ep, 0.0, ouv_haut, m_mur)
		for o in faces[cote]:
			_garnir(f, float(o[0]), float(o[1]), float(o[2]), float(o[3]), maxf(0.06, float(o[4])), str(o[5]))
		a.boite(f, -0.12, L + 0.12, h0, h0 + 0.55, 0.0, 0.1, m["taille_b"])
		for i in range(1, niv.size() - 1):
			a.boite(f, -0.06, L + 0.06, float(niv[i]) - 0.1, float(niv[i]) + 0.12, 0.0, 0.08, m["taille_a"])
		if corniche:
			a.boite(f, -0.3, L + 0.3, top - 0.28, top, 0.0, 0.3, m["taille_a"])
			a.boite(f, -0.38, L + 0.38, top, top + 0.1, 0.0, 0.4, m["taille_a"])
			var xc := 0.45
			while xc < L - 0.3:
				a.boite(f, xc - 0.09, xc + 0.09, top - 0.62, top - 0.28, 0.0, 0.24, m["taille_b"])
				xc += 0.9
		var v := n1
		var k := 0
		while v < top - 0.7:
			var lg := 0.55 if k % 2 == 0 else 0.32
			for ua in [[0.0, lg], [L - lg, L]]:
				a.boite(f, float(ua[0]), float(ua[1]), v, v + 0.34, 0.0, 0.04, m["taille_a"] if k % 2 == 0 else m["taille_b"])
			v += 0.36
			k += 1


## Garniture d'une baie percée dans une façade de 0,45 m : arc (claveaux) ou plate-bande à clef, piédroits de taille,
## appui, fond sombre, vitrage et croisée de pierre ; porte : vantaux de chêne cloutés, seuil.
func _garnir(f: Dictionary, u0: float, u1: float, bas: float, sp: float, rise: float, style: String) -> void:
	var uc := (u0 + u1) * 0.5
	var hs := (u1 - u0) * 0.5
	var crown := sp + rise
	if rise > 0.2:
		ref._claveaux(f, uc, sp, hs, rise, 0.28 if style != "porte" else 0.4, 9 if style != "porte" else 11, -0.45, 0.06)
	else:
		var n := 5
		for i in n:
			var ua := u0 - 0.1 + (u1 - u0 + 0.2) * i / n
			var ub := u0 - 0.1 + (u1 - u0 + 0.2) * (i + 1) / n
			var cle := i == n / 2
			a.boite(f, ua + 0.005, ub - 0.005, crown, crown + (0.42 if cle else 0.34), -0.45, 0.06 if not cle else 0.1, m["taille_a"] if i % 2 == 0 else m["taille_b"])
	for s in [[u0 - 0.16, u0], [u1, u1 + 0.16]]:
		a.boite(f, float(s[0]), float(s[1]), bas, sp, 0.0, 0.05, m["taille_b"])
	a.boite(f, u0, u1, bas, crown, -0.45, -0.445, m["sombre"])
	match style:
		"porte":
			var n := 8
			for i in n:
				var ua := u0 + (u1 - u0) * i / n
				var ub := ua + (u1 - u0) / n
				var dx := maxf(absf(ua - uc), absf(ub - uc))
				var c := (sp + rise - (hs * hs + rise * rise) / (2.0 * rise)) if rise > 0.2 else sp
				var rr := (hs * hs + rise * rise) / (2.0 * rise)
				var hb := c + sqrt(maxf(0.0, rr * rr - dx * dx)) if rise > 0.2 else sp
				a.boite(f, ua + 0.005, ub - 0.01, bas + 0.03, hb, -0.44, -0.38, m["chene"] if i % 2 == 0 else m["chene_c"])
			for hb in [bas + 0.5, bas + 1.6, sp - 0.3]:
				a.boite(f, u0 + 0.06, u1 - 0.06, hb - 0.035, hb + 0.035, -0.38, -0.36, m["fer"])
			a.boite(f, u0 - 0.3, u1 + 0.3, bas - 0.04, bas + 0.06, -0.45, 0.4, m["taille_b"])
		"archere":
			pass
		_:
			a.boite(f, u0 - 0.22, u1 + 0.22, bas - 0.14, bas, -0.45, 0.16, m["taille_a"])
			a.boite(f, u0 + 0.04, u1 - 0.04, bas + 0.04, crown - 0.04, -0.44, -0.435, m["vitre_chaude"] if style.ends_with("_l") else m["vitre"])
			a.boite(f, uc - 0.05, uc + 0.05, bas, sp, -0.435, -0.36, m["taille_a"])
			if style.begins_with("croisee") or style == "barreaux":
				var yt := bas + (sp - bas) * 0.62
				a.boite(f, u0, u1, yt - 0.05, yt + 0.05, -0.435, -0.36, m["taille_a"])
			if style == "barreaux":
				var xb := u0 + 0.16
				while xb < u1 - 0.1:
					a.boite(f, xb - 0.015, xb + 0.015, bas, sp, -0.2, -0.17, m["fer"])
					xb += 0.2


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
	_rampe()
	_chateau()
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
	var top := 19.0                       # P7.12.1 : arc plus haut (fenêtre sur le château), châtelet relevé
	var uc := AXE - 65.6
	var hs := 3.2
	var sp := 12.8
	# P7.12.1 : PASSAGE OUVERT (piédroits et voûte du châtelet, y 31 -> 38,8) : l'arc encadre la rampe et le château au loin ;
	# la herse est relevée, l'accès reste fermé par la grille basse des données, les gardes et les guérites
	for xs in [[65.6, AXE - 3.2], [AXE + 3.2, 74.4]]:
		a.box(Vector3((xs[0] + xs[1]) * 0.5, (H2 + top) * 0.5, 34.9), Vector3(xs[1] - xs[0], top - H2, 7.8), m["chateau"])
	a.box(Vector3(AXE, (sp + hs + top) * 0.5, 34.9), Vector3(6.4, top - sp - hs, 7.8), m["chateau"])
	var pv: MeshInstance3D = a.box(Vector3(AXE, H2 + 0.012, 35.4), Vector3(6.4, 0.024, 9.6), m["dallage"])
	pv.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ref._mur_perce(f, 0.0, 8.8, H2, top, -1.2, 0.0, [{"u0": uc - hs, "u1": uc + hs, "bas": H2, "spring": sp, "rise": hs - 0.01}], m["chateau"])
	ref._claveaux(f, uc, sp, hs, hs - 0.01, 0.55, 15, -1.2, 0.1)
	# herse RELEVÉE dans la voûte : seules ses pointes dépassent sous l'arc (bas à 13,2 m)
	var hbas := 15.0
	var x := uc - hs + 0.25
	while x < uc + hs - 0.1:
		var hb := sp + sqrt(maxf(0.0, hs * hs - pow(x - uc, 2.0))) - 0.05
		if hb > hbas + 0.1:
			a.boite(f, x - 0.07, x + 0.07, hbas, hb, -0.75, -0.6, m["chene"])
			a.boite(f, x - 0.04, x + 0.04, hbas - 0.18, hbas + 0.05, -0.72, -0.63, m["fer"])
		x += 0.42
	var y := hbas + 0.3
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
	a.boite(f, -0.1, 8.9, 16.75, 16.95, 0.0, 0.14, m["taille_a"])
	_blason(f, uc, 17.85, 0.02)
	for ua: float in [1.0, 7.8]:
		a.boite(f, ua - 0.07, ua + 0.07, 13.2, 14.6, 0.0, 0.02, m["sombre"])
		a.boite(f, ua - 0.22, ua + 0.22, 13.8, 13.95, 0.0, 0.02, m["sombre"])
	# mâchicoulis sur consoles, parapet, créneaux
	_couronnement(f, -0.4, 9.2, top, 0.6)


## Mâchicoulis (consoles en encorbellement), parapet et merlons, sur une face [u0, u1] au sommet `top`.
func _couronnement(f: Dictionary, u0: float, u1: float, top: float, saillie: float, mp: Material = null) -> void:
	if mp == null:
		mp = m["chateau"]
	var u := u0 + 0.3
	while u < u1 - 0.2:
		a.boite(f, u - 0.17, u + 0.17, top - 0.9, top - 0.45, 0.0, saillie * 0.5, m["taille_b"])
		a.boite(f, u - 0.17, u + 0.17, top - 0.45, top, 0.0, saillie, m["taille_b"])
		a.boite(f, u + 0.17, u + 0.55, top - 0.25, top, saillie - 0.15, saillie, m["sombre"])
		u += 0.72
	a.boite(f, u0, u1, top, top + 1.1, saillie - 0.45, saillie, mp)
	var um := u0 + 0.25
	while um < u1 - 0.5:
		a.boite(f, um, um + 0.75, top + 1.1, top + 1.85, saillie - 0.45, saillie, mp)
		a.boite(f, um - 0.03, um + 0.78, top + 1.85, top + 1.95, saillie - 0.5, saillie + 0.03, m["taille_a"])
		um += 1.25


## Tour ronde : talus, fût, corbeaux, parapet crénelé, archères (P7.12.1 : plus de toit d'ardoise, réservé au château).
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
## Corps de garde (flanc ouest de l'avenue, adossé au châtelet). P7.12.1 : corps de garde d'une grande cité (et non
## prison) : calcaire clair et chaud, façades maçonnées en épaisseur ; sur la terrasse, porte principale à arc appareillé
## sous le blason (la porte décorative des données, x 61), fenêtres variées (croisées, baies cintrées de l'étage noble,
## fenêtres d'attique), balconnet, bannières de la ville, lanternes ; sur l'avenue, croisées et archères ; échauguette à
## l'angle sud-est ; couronnement de corbeaux et de créneaux (même langage que la porte, plus clair).
const NIV_GARDE := [8.0, 12.4, 16.0, 18.0]


func _corps_de_garde(r: Rect2, h0: float, h1: float) -> void:
	var d0: int = a.racine.get_child_count()
	var top: float = NIV_GARDE[3]
	var s := [[4.1, 5.9, h0, 10.6, 0.7, "porte"], [1.1, 2.3, 9.1, 10.9, 0.12, "croisee_l"], [7.7, 8.9, 9.1, 10.9, 0.12, "croisee"],
		[1.15, 2.45, 12.8, 14.7, 0.65, "cintree"], [4.35, 5.65, 12.8, 14.7, 0.65, "cintree_l"], [7.55, 8.85, 12.8, 14.7, 0.65, "cintree"],
		[1.4, 2.2, 16.35, 17.3, 0.1, "croisee"], [4.6, 5.4, 16.35, 17.3, 0.1, "croisee"], [7.8, 8.6, 16.35, 17.3, 0.1, "croisee"]]
	var e := [[1.6, 2.7, 9.0, 10.8, 0.12, "croisee"], [4.6, 4.8, 9.2, 10.9, 0.06, "archere"],
		[1.5, 2.8, 12.8, 14.7, 0.65, "cintree"], [5.4, 6.6, 12.8, 14.6, 0.12, "croisee"], [2.0, 2.3, 16.3, 17.4, 0.06, "archere"],
		[5.7, 6.3, 16.35, 17.3, 0.1, "croisee"]]
	_batiment_civique(r, NIV_GARDE, {"s": s, "e": e}, m["calcaire"], m["bossage_c"], false)
	var fs := Archi.face(r, "s")
	var fe := Archi.face(r, "e")
	# couronnement (corbeaux, parapet, créneaux) en calcaire, sur un attique plein
	for f2 in [fs, fe]:
		_couronnement(f2, -0.3, float(f2["L"]) + 0.3, h1 - 1.0, 0.45, m["calcaire"])
	# porte principale : blason sous fronton, lanternes, balconnet de l'étage noble au-dessus
	_blason(fs, 5.0, 11.75, 0.04)
	a.boite(fs, 3.9, 6.1, 12.25, 12.4, 0.0, 0.2, m["taille_a"])
	for uu: float in [3.3, 6.7]:
		a.lanterne(fs, uu, 10.2)
	a.balcon(fs, 3.9, 6.1, 12.4, 0.5, "pierre")
	# échauguette à l'angle sud-est (cul-de-lampe, fût, créneaux)
	var c := Vector3(r.end.x - 0.15, 0.0, r.end.y - 0.15)
	for k in 4:
		_cyl(Vector3(c.x, 14.6 + k * 0.25, c.z), 0.35 + k * 0.22, 0.2 + k * 0.22, 0.25, m["taille_b"], 12)
	_cyl(Vector3(c.x, 16.95, c.z), 1.05, 1.05, 2.1, m["calcaire"], 14)
	for i in 8:
		var an := TAU * i / 8.0
		var mb: MeshInstance3D = a.box(Vector3(c.x + cos(an) * 0.95, 18.3, c.z + sin(an) * 0.95), Vector3(0.45, 0.55, 0.22), m["calcaire"])
		mb.rotation.y = -an + PI * 0.5
	a.box(Vector3(c.x, 16.6, c.z + 1.04), Vector3(0.1, 0.9, 0.06), m["sombre"])
	a.fusionner(d0, "civique_corps_de_garde")
	_bannieres(fs, [3.35, 6.65], 15.6)


## Bannières de la ville (modèles Quaternius déjà importés) suspendues à une façade, à la hauteur `v`.
func _bannieres(f: Dictionary, us: Array, v: float) -> void:
	var d1: int = a.racine.get_child_count()
	var t: Vector3 = f["t"]
	var n: Vector3 = f["n"]
	for u in us:
		var p: Vector3 = f["o"] + t * float(u) + n * 0.06
		fo._modele("fp/Banner_2_Cloth", Vector3(p.x, v, p.z), atan2(n.x, n.z), Vector3.ONE * 1.05)
	fo._fusion_gltf(d1, "civique_bannieres_facade")


## P7.12.1 — Raccord du flanc est de la porte, sans habiller l'hôtel de ville : pavillon de calcaire (x 74 -> 79,5), même
## langage que le corps de garde (symétrie de la porte), sur la partie ouest du bloc ; le reste du bloc garde le blockout,
## retinté en pierre (plus de grand volume bleu-vert à côté de la porte). Collision : bloc des données, inchangé.
func _hotel_raccord(r: Rect2, h0: float, h1: float) -> void:
	var d0: int = a.racine.get_child_count()
	var rp := Rect2(r.position.x, r.position.y, 5.5, r.size.y)
	var top: float = NIV_GARDE[3]
	# face ouest (u = y - 32) : seule la partie y > 40,4 est dégagée du châtelet
	var o := [[10.0, 11.2, 9.0, 10.8, 0.12, "croisee"], [13.2, 13.4, 9.2, 10.9, 0.06, "archere"], [15.6, 16.8, 9.0, 10.8, 0.12, "croisee"],
		[9.9, 11.3, 12.8, 14.7, 0.65, "cintree"], [15.5, 16.9, 12.8, 14.7, 0.65, "cintree"], [13.0, 13.6, 13.2, 14.6, 0.08, "archere"],
		[10.2, 11.0, 16.35, 17.3, 0.1, "croisee"], [15.8, 16.6, 16.35, 17.3, 0.1, "croisee"]]
	var s := [[2.15, 3.35, 9.0, 10.8, 0.12, "croisee"], [2.05, 3.45, 12.8, 14.7, 0.65, "cintree"], [2.35, 3.15, 16.35, 17.3, 0.1, "croisee"]]
	_batiment_civique(rp, NIV_GARDE, {"o": o, "s": s}, m["calcaire"], m["bossage_c"], false)
	a.box(Archi.centre(rp, top, top + 1.0), Vector3(rp.size.x, 1.0, rp.size.y), m["calcaire"])
	for cote: String in ["o", "s"]:
		var f2 := Archi.face(rp, cote)
		_couronnement(f2, -0.3, float(f2["L"]) + 0.3, top + 1.0, 0.45, m["calcaire"])
	var fo2 := Archi.face(rp, "o")
	_blason(fo2, 13.3, 16.9, 0.04)
	a.fusionner(d0, "civique_pavillon_hotel")
	# reste du bloc (lot de l'hôtel de ville, non habillé) : blockout retinté en pierre, même géométrie
	var rr := Rect2(rp.end.x, r.position.y, r.end.x - rp.end.x, r.size.y)
	var mi: MeshInstance3D = sc._box_mesh(sc._rect_center(rr, h0, h1), Vector3(rr.size.x, h1 - h0, rr.size.y), vl.mat(Color(0.74, 0.70, 0.63), 0.0, 1.0, h0, true))
	mi.name = HOTEL


## Porte décorative (données) d'un bâtiment du quartier civique : porte cloutée à encadrement de pierre (bibliothèque).
func porte_deco(e: Dictionary) -> bool:
	var bat := str(e["batiment"])
	if not actif or not PORTES_DECO.has(bat):
		return false
	if true:
		return true                              # P7.12.1 : la porte est une baie maçonnée de la façade (_garnir)
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
	_cyl(Vector3(r.get_center().x, top + 0.75, r.get_center().y), 0.0, r.size.x * 0.74, 1.5, m["taille_b"], 4)      # chapeau de pierre (ardoise : château)
	var dc: Node = a.racine.get_child(a.racine.get_child_count() - 1)
	(dc as Node3D).rotation.y = PI * 0.25


# ------------------------------------------------------------------------------------------------ P7.12.1 : château
## Rampe montante derrière la porte (affichage seul, jamais praticable) : chaussée dallée de 8 m (y 31 -> -115, 8 -> 12),
## parapets bas ; elle conduit l'œil, à travers l'arc, vers la porte du château.
const RAMPE := [31.0, -115.0, 8.0, 12.0]              # P7.12.1 : château à ≈ 150 m de la porte, sur un rocher


func _rampe() -> void:
	# sol du quartier haut derrière la porte (le dessus du massif était clair : il brillait à travers l'arc)
	var sol: MeshInstance3D = a.box(Vector3(AXE, H2 + 0.015, -60.0), Vector3(90.0, 0.03, 182.0), m["soutenement"])
	sol.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# maisons basses le long de la rampe (hors de la fenêtre de l'arc), toits de tuiles
	for mm in [[Rect2(52.0, -12.0, 9.0, 8.0), 6.5], [Rect2(79.0, -20.0, 10.0, 9.0), 7.0], [Rect2(50.0, -48.0, 11.0, 10.0), 7.5],
			[Rect2(80.0, -60.0, 9.0, 11.0), 6.5], [Rect2(53.0, -88.0, 8.0, 9.0), 7.0], [Rect2(79.0, -100.0, 11.0, 9.0), 8.0]]:
		var rr: Rect2 = mm[0]
		var hb := H2 + 0.6
		var tp := hb + float(mm[1])
		a.box(Archi.centre(rr, H2, tp), Vector3(rr.size.x, tp - H2, rr.size.y), m["enduit"])
		a.toit(rr, tp, minf(rr.size.x, rr.size.y) * 0.42, Color(0.88, 0.82, 0.70), "2p_x" if rr.size.x >= rr.size.y else "2p_y", Color(1.0, 0.96, 0.92))
	var y0: float = RAMPE[0]
	var y1: float = RAMPE[1]
	var h0: float = RAMPE[2]
	var h1: float = RAMPE[3]
	var lg := y0 - y1
	var ang := atan2(h1 - h0, lg)
	var c := Vector3(AXE, (h0 + h1) * 0.5 - 0.25, (y0 + y1) * 0.5)
	var ch: MeshInstance3D = a.box(c, Vector3(8.0, 0.5, sqrt(lg * lg + pow(h1 - h0, 2.0))), m["dallage"])
	ch.basis = Basis(Vector3(1, 0, 0), ang)
	for xp: float in [AXE - 4.15, AXE + 4.15]:
		var p: MeshInstance3D = a.box(Vector3(xp, (h0 + h1) * 0.5 + 0.35, c.z), Vector3(0.3, 1.2, lg), m["mur"])
		p.basis = Basis(Vector3(1, 0, 0), ang)
		var co: MeshInstance3D = a.box(Vector3(xp, (h0 + h1) * 0.5 + 0.98, c.z), Vector3(0.42, 0.1, lg), m["taille_a"])
		co.basis = Basis(Vector3(1, 0, 0), ang)


## Château (décor lointain, non jouable, instance future) à 150-210 m derrière la porte, centré sur l'axe : socle rocheux,
## enceinte crénelée, porte à deux tours rondes coiffées d'ardoise, tours d'angle, logis, donjon. Dimensionné pour que,
## depuis la place, la fenêtre de l'arc cadre sa porte et ses tours ; depuis la terrasse (plongée
## adoucie), il se lit en entier avec ses toits d'ardoise.
func _chateau() -> void:
	var hb: float = RAMPE[3]
	var front: float = RAMPE[1]
	# socle rocheux (talus de pierre) et plate-forme
	var socle := Rect2(48.0, front - 62.0, 44.0, 62.0)
	a.box(Archi.centre(socle, H2, hb), Vector3(socle.size.x, hb - H2, socle.size.y), m["soutenement"])
	# enceinte avant
	var enc := Rect2(51.0, front - 3.0, 38.0, 2.6)
	a.box(Archi.centre(enc, hb, hb + 8.0), Vector3(enc.size.x, 8.0, enc.size.y), m["chateau_loin"])
	_couronnement(Archi.face(enc, "s"), 0.0, enc.size.x, hb + 8.0, 0.4, m["chateau_loin"])
	# porte du château : châtelet saillant, arc fermé de vantaux, mâchicoulis
	var pt := Rect2(AXE - 4.0, front - 3.6, 8.0, 4.0)
	a.box(Archi.centre(pt, hb, hb + 10.5), Vector3(pt.size.x, 10.5, pt.size.y), m["chateau_loin"])
	var fp := Archi.face(pt, "s")
	ref._claveaux(fp, 4.0, hb + 2.8, 1.8, 1.8, 0.45, 13, 0.0, 0.12)
	a.boite(fp, 2.2, 5.8, hb, hb + 2.8, 0.0, 0.03, m["chene"])
	var n := 10
	for i in n:
		var ang := PI * (i + 0.5) / n
		var xx := 4.0 - cos(ang) * 1.8
		a.boite(fp, xx - 0.19, xx + 0.19, hb + 2.8, hb + 2.8 + sin(ang) * 1.75, 0.0, 0.03, m["chene"])
	a.boite(fp, 3.97, 4.03, hb, hb + 4.5, 0.03, 0.06, m["sombre"])
	_blason(fp, 4.0, hb + 6.4, 0.03)
	_couronnement(fp, -0.3, 8.3, hb + 10.5, 0.55, m["chateau_loin"])
	# tours de la porte et d'angle (fûts, créneaux, toits coniques d'ardoise)
	for tp in [[AXE - 6.6, 3.0, 17.0], [AXE + 6.6, 3.0, 17.0], [50.5, 3.2, 13.5], [89.5, 3.2, 13.5]]:
		_tour_chateau(Vector3(float(tp[0]), hb, front - 1.8), float(tp[1]), hb + float(tp[2]))
	# logis (toit d'ardoise) et donjon
	var logis := Rect2(55.0, front - 40.0, 30.0, 16.0)
	a.box(Archi.centre(logis, hb, hb + 13.0), Vector3(logis.size.x, 13.0, logis.size.y), m["chateau_loin"])
	a.toit(logis, hb + 13.0, 6.0, Color(0.8, 0.78, 0.74), "2p_x", Color(0.42, 0.45, 0.54))
	var dj := Rect2(AXE - 4.5, front - 52.0, 9.0, 9.0)
	a.box(Archi.centre(dj, hb, hb + 26.0), Vector3(dj.size.x, 26.0, dj.size.y), m["chateau_loin"])
	_couronnement(Archi.face(dj, "s"), -0.3, dj.size.x + 0.3, hb + 26.0, 0.5, m["chateau_loin"])
	_cyl(Vector3(dj.get_center().x, hb + 26.0 + 1.1 + 4.5, dj.get_center().y), 0.0, 6.6, 9.0, m["ardoise_loin"], 4)
	for k in 3:
		a.box(Vector3(AXE, hb + 15.0 + k * 3.5, front - 42.98), Vector3(0.5, 1.6, 0.08), m["sombre"])


func _tour_chateau(base: Vector3, rayon: float, top: float) -> void:
	_cyl(Vector3(base.x, (base.y + top) * 0.5, base.z), rayon, rayon + 0.4, top - base.y, m["chateau_loin"], 18)
	_cyl(Vector3(base.x, top + 0.3, base.z), rayon + 0.45, rayon, 0.6, m["taille_b"], 18)
	_cyl(Vector3(base.x, top + 1.1, base.z), rayon + 0.45, rayon + 0.45, 1.0, m["chateau_loin"], 18)
	_cyl(Vector3(base.x, top + 1.6 + 3.6, base.z), 0.0, rayon + 0.8, 7.2, m["ardoise_loin"], 16)
	for hy: float in [base.y + 4.0, base.y + 8.0]:
		a.box(Vector3(base.x, hy, base.z + rayon + 0.1), Vector3(0.2, 1.4, 0.1), m["sombre"])

