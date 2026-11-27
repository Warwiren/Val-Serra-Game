extends RefCounted
## P8.1-A — FINITION DU QUARTIER (avant les PNJ) : remplacement des restes de blockout VISIBLES depuis les parcours, par
## lots (docs/P8_1A_FINITION.md). Affichage seulement : chaque collision est créée par les MÊMES appels que le blockout
## (mêmes boîtes, mêmes couches), seules les matières et le décor changent. Rien n'est ajouté au plan.
## Lots : « sols » (L1 : sols, terrasses, masses de terrain, garde-corps). Options : --finition=0 (tous les lots
## coupés : état P8.0-C), --f_<lot>=0 (un lot coupé).
## Matières : celles des références validées (dallage de la grande place P7.8, soutènement sali et taille du quartier
## civique P7.12), par la bibliothèque archi_p77 (cache commun).

const Archi := preload("res://scenes/p7/archi_p77.gd")
const TEINTE_DALLAGE := Color(1.12, 1.09, 1.04)          # = place_p78.TEINTE_DALLAGE (grande place)

var b                 # constructeur de la ville (scenes/p7/ville_v07b.gd)
var sc                # scène (colisee.gd)
var a                 # composants (Archi) : ceux de la tranche, maillages sous sc.root
var _m := {}


func _init(builder) -> void:
	b = builder
	sc = builder.sc
	a = builder._tr().a


## Le lot est-il actif ? (--finition=0 coupe tout ; --f_<lot>=0 coupe un lot)
func actif(lot: String) -> bool:
	return str(sc._cli.get("finition", "1")) != "0" and str(sc._cli.get("f_" + lot, "1")) != "0"


# ------------------------------------------------------------------------------------------------ matières
func _pierre(nom: String, base: String, teinte: Color, regl: Dictionary, base_y := 0.0, hole := true) -> ShaderMaterial:
	var cle := "p81|%s|%s" % [nom, base_y]
	if a._mats.has(cle):
		return a._mats[cle]
	var mt := (a.macon(base, teinte, base_y, "monde", hole) as ShaderMaterial).duplicate() as ShaderMaterial
	for k in regl:
		mt.set_shader_parameter(k, regl[k])
	a._mats[cle] = mt
	return mt


## Dallage des rues et des parvis : celui de la grande place, un peu plus sali et plus sombre au niveau bas (rues),
## plus clair sur les terrasses hautes (comme le dallage civique).
func dallage(h: float) -> ShaderMaterial:
	var t := TEINTE_DALLAGE * (0.96 if h < 1.0 else (1.0 if h < 6.0 else 1.06))
	t.a = 1.0
	return _pierre("dallage_%d" % int(round(h * 4.0)), "dallage2", t, {"salissure": 0.35 if h < 1.0 else 0.25}, h, false)


## Sol hors les murs (sol de décor sous toute la carte) : même dallage, sombre et sali (lecture d'un sol lointain).
func sol_loin(h: float) -> ShaderMaterial:
	return _pierre("sol_loin", "dallage2", Color(0.86, 0.82, 0.76), {"salissure": 0.6}, h, false)


## Soutènement : contrefort sali du quartier civique (P7.12), base au pied du mur.
func soutenement(base_y: float) -> ShaderMaterial:
	return _pierre("soutenement_%d" % int(round(base_y * 4.0)), "contrefort", Color(1.16, 1.12, 1.06), {"salissure": 0.5, "coulures": 0.45}, base_y)


## Pierre de taille des couronnements et chaperons (taille_b du quartier civique).
func taille() -> ShaderMaterial:
	return _pierre("taille", "mur2", Color(1.38, 1.31, 1.20), {"assises": Vector3(3.0, 3.0, 3.0), "long_bloc": 4.0, "var_long": 0.0,
		"joint": 0.0, "salissure": 0.2, "coulures": 0.15, "mousse": 0.0, "fissures": 0.0, "rapieces": 0.0, "irregulier": 0.0, "usure": 0.35,
		"k_mousse": 0.0})


# ------------------------------------------------------------------------------------------------ L1 : sols et soutènements
## Entité « floor » des données (hors tranche) : même collision que le blockout (dalle de 0,3 m), dessus en dallage.
## Sol de décor (role « decor ») : même collision (couche NOWALK, débord de 80 m), sol lointain.
func sol(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var h: float = e["h"]
	if e.get("role", "") == "decor":
		var c := Vector3(r.get_center().x, h - 0.17, r.get_center().y)
		var size := Vector3(r.size.x + 80.0, 0.3, r.size.y + 80.0)
		sc._static_box(c, size, sc.L_NOWALK)
		var md: MeshInstance3D = a.box(c - Vector3(0, 0.02, 0), size, sol_loin(h))
		md.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		return
	var th := 0.3
	sc._static_box(sc._rect_center(r, h - th, h), Vector3(r.size.x, th, r.size.y), sc.L_FLOOR)
	var mi: MeshInstance3D = a.box(sc._rect_center(r, h - th, h), Vector3(r.size.x, th, r.size.y), dallage(h))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Bloc « terrasse » des données (hors tranche, place et civique) : même collision, corps en soutènement, dessus dallé,
## couronnement de pierre de taille sur la face sud (face caméra).
func terrasse(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_FLOOR)
	corps_terrasse(r, h0, h1 - 0.02)
	a.box(sc._rect_center(r, h1 - 0.02, h1), Vector3(r.size.x, 0.02, r.size.y), dallage(h1))


## Corps d'une terrasse (murs de soutènement) de h0 à h, couronnement au sommet de la face sud.
func corps_terrasse(r: Rect2, h0: float, h: float) -> void:
	a.box(sc._rect_center(r, h0, h), Vector3(r.size.x, h - h0, r.size.y), soutenement(h0))
	if h - h0 > 0.6:
		var cb: MeshInstance3D = a.box(Vector3(r.get_center().x, h - 0.11, r.end.y + 0.06), Vector3(r.size.x + 0.04, 0.22, 0.14), taille())
		cb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Masses de terrain (V0.7-A) : flancs en soutènement, dessus dallé, cordon de pierre de taille au sommet de la face sud.
## Mêmes boîtes que ville_v07a._masses (aucune collision : le relief praticable vient des sols et terrasses des données).
func masses(liste: Array) -> void:
	for m in liste:
		var q: Array = m[0]
		var h: float = float(m[1]) - 0.006
		var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
		a.box(sc._rect_center(r, -1.0, h), Vector3(r.size.x, h + 1.0, r.size.y), soutenement(0.0))
		a.box(Vector3(r.get_center().x, h - 0.005, r.get_center().y), Vector3(r.size.x, 0.01, r.size.y), dallage(h + 0.01))
		if r.size.x < 200.0:
			a.box(Vector3(r.get_center().x, h - 0.12, r.end.y + 0.12), Vector3(r.size.x, 0.24, 0.24), taille())


## Garde-corps « gc_ » des données non traités par le quartier civique : même collision ; parapet de soutènement plein et
## chaperon de pierre de taille (au lieu du muret gris et de la main courante claire du blockout).
func garde_corps(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_OBST)
	a.box(sc._rect_center(r, h0, h0 + 0.85), Vector3(r.size.x, 0.85, r.size.y), soutenement(h0))
	a.box(sc._rect_center(r.grow(0.06), h0 + 0.85, h0 + 1.0), Vector3(r.size.x + 0.12, 0.15, r.size.y + 0.12), taille())


# ------------------------------------------------------------------------------------------------ L2 : façade du Colisée
## Pierre du Colisée vu de la ville : calcaire ocre plus chaud que la ville (cohérent avec l'intérieur, P6.4).
func pierre_colisee(base_y: float) -> ShaderMaterial:
	return _pierre("colisee", "mur2", Color(1.26, 1.12, 0.94), {"assises": Vector3(0.52, 0.44, 0.48), "long_bloc": 1.2, "salissure": 0.4,
		"coulures": 0.35}, base_y)


## Fond des galeries (mur du tambour derrière les arcades) : même pierre, plus sombre (galerie couverte).
func fond_galerie(base_y: float) -> ShaderMaterial:
	return _pierre("colisee_fond", "mur2", Color(0.80, 0.71, 0.60), {"assises": Vector3(0.52, 0.44, 0.48), "long_bloc": 1.2, "salissure": 0.55}, base_y)


func taille_colisee() -> ShaderMaterial:
	return _pierre("colisee_taille", "mur2", Color(1.36, 1.22, 1.02), {"assises": Vector3(3.0, 3.0, 3.0), "long_bloc": 4.0, "var_long": 0.0,
		"joint": 0.0, "salissure": 0.3, "coulures": 0.25, "mousse": 0.0, "fissures": 0.0, "rapieces": 0.0, "irregulier": 0.0, "usure": 0.4,
		"k_mousse": 0.0})


## Façade extérieure du Colisée (remplace le tambour de blockout et ses 88 panneaux noirs) : tambour plein en retrait
## (fond des galeries), et sur la moitié sud (seule vue depuis la ville) deux registres d'ARCADES RÉELLES (piles,
## écoinçons, claveaux en saillie de 1,4 m), entablements, attique plein à pilastres et petites fenêtres, couronnement.
## Profondeur et ombres portées à la place des aplats noirs. Affichage seul : l'enceinte reste celle des données
## (colisee_tranche_*), le décor ne la déborde pas (piles sur l'ellipse des données). Entrée publique laissée libre.
## `pres_porte(p)` : le constructeur exclut les travées de l'entrée (même règle que la V0.7-A).
func colisee(cd: Dictionary, pres_porte: Callable) -> void:
	var c := Vector2(cd["centre"][0], cd["centre"][1])
	var rr := Vector2(cd["rayons"][0], cd["rayons"][1])
	var h0: float = cd["h"]
	var haut: float = cd["haut"]
	var prof := 1.4                                   # profondeur des arcades (galerie)
	var d0: int = a.racine.get_child_count()
	var mur := pierre_colisee(h0)
	var fond := fond_galerie(h0)
	var tl := taille_colisee()
	var sombre: Material = a.plein(Color(0.10, 0.09, 0.08), 0.95)
	# tambour (fond des galeries jusqu'au 2e entablement, puis attique plein), rayons réduits de la profondeur des arcades
	var kf := Vector2((rr.x - prof) / rr.x, (rr.y - prof) / rr.y)
	_ellipse(c, Vector2(rr.x * kf.x, rr.y * kf.y), h0, h0 + 9.5, fond, true)
	_ellipse(c, rr, h0 + 9.5, h0 + haut, mur, false)                  # attique au nu des arcades
	_ellipse(c, rr * 1.012, h0 + haut, h0 + haut + 0.7, tl, true)     # couronnement
	_ellipse(c, rr * 1.006, h0 + 3.4, h0 + 3.9, tl, false)            # entablement du rez-de-chaussée
	_ellipse(c, rr * 1.006, h0 + 9.0, h0 + 9.5, tl, false)            # entablement de l'étage
	_ellipse(c, rr * 1.015, h0 + haut - 0.5, h0 + haut, tl, false)    # corniche sous le couronnement
	# arcades : 28 travées sur la moitié sud (angles 0 -> PI, y croissant = sud)
	var n := 28
	for k in n + 1:
		var ang := PI * float(k) / n
		var f := _face_ellipse(c, rr, ang)
		var p2 := Vector2(f["o"].x, f["o"].z)
		# pile (pilier entre deux arcs) sur les deux registres, avec imposte et dosseret
		if not pres_porte.call(p2):
			for reg in [[0.0, 3.4], [3.9, 9.0]]:
				a.boite_tournee(f, 0.0, h0 + (reg[0] + reg[1]) * 0.5, 0.72, reg[1] - reg[0], -prof, 0.0, 0.0, mur)
				a.boite_tournee(f, 0.0, h0 + reg[0] + (reg[1] - reg[0]) * 0.62, 0.84, 0.16, -prof, 0.08, 0.0, tl)    # imposte
		# pilastres de l'attique (au nu du mur, légère saillie)
		a.boite_tournee(f, 0.0, h0 + (9.5 + haut - 0.5) * 0.5, 0.5, haut - 10.0, 0.0, 0.12, 0.0, tl)
		if k == n:
			continue
		# travée entre la pile k et la pile k+1 : milieu de l'arc
		var am := PI * (float(k) + 0.5) / n
		var fm := _face_ellipse(c, rr, am)
		var pm := Vector2(fm["o"].x, fm["o"].z)
		var largeur := _corde(c, rr, ang, PI * float(k + 1) / n)
		if pres_porte.call(pm):
			continue
		for reg in [[0.0, 3.4], [3.9, 9.0]]:
			_arcade(fm, h0 + reg[0], h0 + reg[1], largeur, prof, mur, tl)
		# fenêtre carrée de l'attique, en retrait sombre, avec appui
		a.boite_tournee(fm, 0.0, h0 + 12.6, 0.95, 1.1, -0.02, 0.02, 0.0, sombre)
		a.boite_tournee(fm, 0.0, h0 + 11.98, 1.15, 0.12, 0.0, 0.1, 0.0, tl)
	a.fusionner(d0, "colisee_facade")


## Arc en plein cintre d'une travée (registre v0 -> v1) : écoinçons en gradins au nu de la façade, bandeau de claveaux
## légèrement saillant, intrados (épaisseur de la galerie) en bas du cintre.
func _arcade(f: Dictionary, v0: float, v1: float, largeur: float, prof: float, mur: Material, tl: Material) -> void:
	var ouv := largeur - 0.72                        # ouverture entre piles
	var R := ouv * 0.5
	var naiss := v1 - 0.25 - R                       # naissance de l'arc (clé 0,25 m sous l'entablement)
	var pas := 6
	for i in pas:
		var y0 := naiss + R * float(i) / pas
		var y1 := naiss + R * float(i + 1) / pas
		var hw := R * sqrt(maxf(0.0, 1.0 - pow(float(i) / pas, 2.0)))       # demi-ouverture en bas du gradin
		var plein_w := largeur * 0.5 - hw
		if plein_w > 0.01:
			for s in [-1.0, 1.0]:
				a.boite_tournee(f, s * (hw + plein_w * 0.5), (y0 + y1) * 0.5, plein_w, y1 - y0, -0.35, 0.0, 0.0, mur)
	a.boite_tournee(f, 0.0, (naiss + R + v1) * 0.5, largeur, v1 - naiss - R, -0.35, 0.0, 0.0, mur)
	# claveaux (bandeau) : 9 voussoirs tournés autour de la normale
	var nc := 9
	for i in nc:
		var t := PI * (i + 0.5) / nc
		var pu := -cos(t) * (R + 0.12)
		var pv := naiss + sin(t) * (R + 0.12)
		a.boite_tournee(f, pu, pv, PI * (R + 0.12) / nc + 0.03, 0.26 if i == nc / 2 else 0.22, 0.0, 0.08, PI * 0.5 - t, tl)


## Façade locale tangente à l'ellipse au paramètre `ang` (point sur l'ellipse, normale sortante, tangente).
func _face_ellipse(c: Vector2, rr: Vector2, ang: float) -> Dictionary:
	var p := c + Vector2(cos(ang) * rr.x, sin(ang) * rr.y)
	var nrm := Vector2(cos(ang) / rr.x, sin(ang) / rr.y).normalized()
	var n := Vector3(nrm.x, 0.0, nrm.y)
	var t := Vector3(-nrm.y, 0.0, nrm.x)
	return {"o": Vector3(p.x, 0.0, p.y), "t": t, "n": n, "L": 0.0}


static func _corde(c: Vector2, rr: Vector2, a0: float, a1: float) -> float:
	var p0 := Vector2(cos(a0) * rr.x, sin(a0) * rr.y)
	var p1 := Vector2(cos(a1) * rr.x, sin(a1) * rr.y)
	return p0.distance_to(p1)


## Anneau elliptique (cylindre mis à l'échelle), de y0 à y1 ; couvercles seulement si `capot` (pas de ligne claire
## entre les facettes des cordons, cf. P7.6).
func _ellipse(c: Vector2, rr: Vector2, y0: float, y1: float, m: Material, capot: bool) -> void:
	var cy := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = y1 - y0
	cm.radial_segments = 112
	cm.rings = 1
	cm.cap_top = capot
	cm.cap_bottom = capot
	cy.mesh = cm
	cy.scale = Vector3(rr.x, 1.0, rr.y)
	cy.position = Vector3(c.x, (y0 + y1) * 0.5, c.y)
	cy.material_override = m
	cy.name = "Colisee_tambour"
	a.racine.add_child(cy)


# ------------------------------------------------------------------------------------------------ outil commun
## Pierre calcaire claire des édifices publics (calcaire du quartier civique P7.12.1).
func calcaire(base_y: float) -> ShaderMaterial:
	return _pierre("calcaire_%d" % int(round(base_y * 4.0)), "mur2", Color(1.56, 1.44, 1.24), {"assises": Vector3(0.46, 0.38, 0.42),
		"long_bloc": 1.0, "irregulier": 0.05, "rapieces": 0.03, "salissure": 0.22}, base_y)


## Remplace, sans toucher à la géométrie, la matière de blockout (blockout_p7.gdshader) des maillages ajoutés sous
## sc.root depuis l'indice `depuis` : teinte claire -> calcaire, moyenne -> pierre de taille, sombre (bois, fer) -> matière
## unie de la même couleur (sans quadrillage ni baies peintes). Sert aux éléments de la V0.7-A gardés tels quels.
func remplacer_blockout(depuis: int) -> int:
	var n := 0
	for i in range(depuis, sc.root.get_child_count()):
		var mi := sc.root.get_child(i) as MeshInstance3D
		if mi == null or not (mi.material_override is ShaderMaterial):
			continue
		var sm := mi.material_override as ShaderMaterial
		if sm.shader == null or sm.shader.resource_path.get_file() != "blockout_p7.gdshader":
			continue
		var c: Color = sm.get_shader_parameter("couleur")
		var lum := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
		var bas: float = (mi.global_transform * mi.get_aabb()).position.y
		if lum > 0.6:
			mi.material_override = calcaire(snappedf(bas, 0.5))
		elif lum > 0.38:
			mi.material_override = taille()
		else:
			mi.material_override = a.plein(c, 0.85)
		n += 1
	return n


# ------------------------------------------------------------------------------------------------ L3 : bâtiments secondaires
## Habillage des bâtiments encore en blockout (placette, parvis, terrasses, fonds) par une FICHE générée depuis
## l'emprise et la hauteur des données, construite par la bibliothèque archi_p77 (comme la tranche P7.6, approuvée) :
## RDC de pierre, étages enduits ou de pierre, bandeaux, corniche, chaînes d'angle, baies régulières à volets, toit de
## tuiles. Genres : « civique » (Guilde, hôtel de ville : calcaire, bossage, baies hautes sans volets, corniche à consoles),
## « maison » (palette de la ville selon une graine), « fond » (paysage lointain : face sud et flancs, sans détail fin).
## Les entrées des données (fonctionnelles et décoratives) gardent leur place : aucune baie de RDC devant elles.
## Aucune porte inventée (règle P7.12.2 : toute porte a un accès crédible) : RDC en fenêtres et soupiraux grillagés.
const NIVEAU_RDC := 3.3
const NIVEAU_ETAGE := 2.8
const PALETTES_MAISONS := ["miel", "ocre", "gris_chaud", "rose", "creme", "terre"]


## Fiche d'un bâtiment : `toit_max` = hauteur de toit admise par le volume d'escamotage (ville_v07b._classer_volumes).
func fiche(id: String, r: Rect2, h0: float, h1: float, genre: String, entrees: Array, toit_max: float) -> Dictionary:
	var g := absi(id.hash())
	var nv := [h0]
	var hh := h1 - h0
	var n_et := maxi(0, int(round((hh - NIVEAU_RDC) / NIVEAU_ETAGE)))
	if n_et == 0:
		nv.append(h1)
	else:
		var rdc := minf(NIVEAU_RDC, hh * 0.45)
		nv.append(h0 + rdc)
		var et := (hh - rdc) / n_et
		for i in n_et:
			nv.append(h0 + rdc + et * (i + 1))
	var pal: Array = Archi.PALETTES[PALETTES_MAISONS[g % PALETTES_MAISONS.size()]]
	var d := {"id": id, "niveaux": nv, "enduit": pal[0], "volets": pal[1], "toit": "2p_x",
		"toit_h": clampf(minf(r.size.x, r.size.y) * 0.32, 1.2, minf(toit_max, 3.6)), "faces": {}, "balcons": [], "lanternes": []}
	var cotes := ["s", "e", "o"]
	if genre == "civique":
		d["rdc"] = "bossage"
		d["etages"] = "pierre"
		d["corniche"] = "consoles"
		d["volets_style"] = "aucun"
		d["toit"] = "croupe"
	elif genre == "fond":
		d["chaines"] = false
	for cote in cotes:
		var f := Archi.face(r, cote)
		var L: float = f["L"]
		var par_niveau := []
		for i in nv.size() - 1:
			var bas: float = nv[i]
			var haut_n: float = nv[i + 1]
			var hn := haut_n - bas
			var liste := []
			var pas := 2.7 if genre != "civique" else 3.2
			var nb := int(floor((L - 1.6) / pas))
			if nb < 1 or hn < 1.8:
				par_niveau.append(liste)
				continue
			var u0 := (L - (nb - 1) * pas) * 0.5
			for k in nb:
				var u := u0 + k * pas
				if i == 0 and cote == "s" and _devant_entree(f, u, entrees):
					continue
				if i == 0:
					if genre == "civique":
						liste.append([u, 1.0, minf(1.9, hn - 1.2), 0.9, "fenetre_simple"])
					elif genre == "fond" or (g + k) % 3 == 0:
						liste.append([u, 0.8, 0.9, minf(1.2, hn - 1.3), "barreaux"])
					else:
						liste.append([u, 0.95, minf(1.4, hn - 1.3), 0.85, "fenetre"])
				else:
					var hw := minf(1.45, hn - 0.9) if genre != "civique" else minf(2.0, hn - 0.8)
					var style := "fenetre" if genre != "civique" else "fenetre_cintree"
					if genre == "fond":
						style = "fenetre_simple"
					liste.append([u, 0.9 if genre != "civique" else 1.1, hw, minf(0.55, hn - hw - 0.25), style])
			par_niveau.append(liste)
		d["faces"][cote] = par_niveau
	return d


## La baie d'abscisse u (face f) tombe-t-elle devant une entrée des données ?
func _devant_entree(f: Dictionary, u: float, entrees: Array) -> bool:
	for e in entrees:
		var p := Vector3(float(e["x"]), 0.0, float(e["y"]))
		var o: Vector3 = f["o"]
		var t: Vector3 = f["t"]
		var n: Vector3 = f["n"]
		if absf((p - o).dot(n)) > 0.6:
			continue
		var ue := (p - o).dot(t)
		if absf(ue - u) < float(e["largeur"]) * 0.5 + 1.3:
			return true
	return false


## Bâtiment secondaire des données (même collision que le blockout : boîte pleine, couche OBST).
func batiment(e: Dictionary, genre: String, entrees: Array, toit_max: float) -> void:
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	var id := str(e["id"])
	sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_OBST)
	a.batiment(r, h0, fiche(id, r, h0, h1, genre, entrees, toit_max))


## Socle bas (moins de 2,5 m : quais, murets, plates-formes) : même collision, corps de soutènement, dessus dallé et
## chaperon de pierre de taille.
func socle(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_OBST)
	a.box(sc._rect_center(r, h0, h1 - 0.12), Vector3(r.size.x, h1 - h0 - 0.12, r.size.y), soutenement(h0))
	a.box(sc._rect_center(r.grow(0.05), h1 - 0.12, h1), Vector3(r.size.x + 0.1, 0.12, r.size.y + 0.1), taille())


## Fond (paysage, sans collision : décor hors d'atteinte) : même emprise et même hauteur que le blockout.
func fond(p: Dictionary, i: int) -> void:
	var q: Array = p["rect"]
	var r := Rect2(q[0], q[1], q[2] - q[0], q[3] - q[1])
	var h0: float = p["h"]
	var h1: float = h0 + float(p["haut"])
	a.batiment(r, h0, fiche("paysage_%d" % i, r, h0, h1, "fond", [], 3.0))
