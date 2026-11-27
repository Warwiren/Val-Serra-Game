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
	var varie := actif("coherence")                   # P8.1-A2 : travées variées (voir _travee_p81a2)
	if varie:
		fond = _pierre("colisee_fond2", "mur2", Color(0.95, 0.85, 0.72), {"assises": Vector3(0.52, 0.44, 0.48), "long_bloc": 1.2,
			"salissure": 0.5}, h0)
	var bois: Material = a.plein(Color(0.30, 0.20, 0.13), 0.9)
	var fer: Material = a.plein(Color(0.16, 0.15, 0.14), 0.6)
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
		if varie:
			_travee_p81a2(fm, k, h0, largeur, prof, mur, tl, bois, fer)
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


## P8.1-A2 — Travées du Colisée moins mécaniques, sans aplats noirs (affichage seul, silhouette et entrée inchangées) :
## l'étage reçoit partout un parapet plein à tablette (garde-corps de la galerie, comme aux amphithéâtres antiques) qui
## ferme le bas des arcs ; au fond de chaque travée du rez-de-chaussée, l'ouverture vers les escaliers est encadrée de
## pierre de taille. Une suite irrégulière (pas de motif répété à l'œil) distingue quelques travées : passage fermé par
## une GRILLE de fer, travée MURÉE en retrait avec petite porte de service en bois, NICHE à statue (socle et figure de
## pierre) au fond de la galerie de l'étage. Fond des galeries plus clair (la galerie reçoit la lumière du sud).
const TRAVEES_P81A2 := "..g.n..m...n.g...m..n...g..m.."   # g grille, m murée, n niche (étage), . ouverte


func _travee_p81a2(fm: Dictionary, k: int, h0: float, largeur: float, prof: float, mur: Material, tl: Material, bois: Material,
		fer: Material) -> void:
	var ouv := largeur - 0.72
	var R := ouv * 0.5
	var sorte := TRAVEES_P81A2[k % TRAVEES_P81A2.length()]
	# étage : parapet (h 0,95) entre les piles, en retrait du nu ; tablette de pierre de taille
	a.boite_tournee(fm, 0.0, h0 + 3.9 + 0.45, ouv + 0.02, 0.9, -0.62, -0.32, 0.0, mur)
	a.boite_tournee(fm, 0.0, h0 + 3.9 + 0.95, ouv + 0.06, 0.1, -0.68, -0.26, 0.0, tl)
	# rez-de-chaussée : encadrement de l'ouverture du fond (vers les escaliers)
	var lo := minf(1.5, ouv - 0.6)
	var ho := 2.5
	for s in [-1.0, 1.0]:
		a.boite_tournee(fm, s * (lo * 0.5 + 0.14), h0 + ho * 0.5, 0.28, ho, -prof - 0.02, -prof + 0.1, 0.0, tl)
	a.boite_tournee(fm, 0.0, h0 + ho + 0.16, lo + 0.56, 0.32, -prof - 0.02, -prof + 0.12, 0.0, tl)
	match sorte:
		"g":
			var nb := int(ouv / 0.22)
			for i in nb + 1:
				var u := -ouv * 0.5 + ouv * float(i) / nb
				a.boite_tournee(fm, u, h0 + 1.55, 0.05, 3.1, -0.3, -0.24, 0.0, fer)       # jusqu'à la clé (le haut passe dans l'écoinçon)
			for v in [0.12, 1.25, 3.15 - R]:
				a.boite_tournee(fm, 0.0, h0 + v, ouv, 0.07, -0.31, -0.23, 0.0, fer)
		"m":
			a.boite_tournee(fm, 0.0, h0 + 1.58, ouv + 0.02, 3.16, -0.75, -0.45, 0.0, mur)                # remplit l'arc (derrière l'écoinçon)
			a.boite_tournee(fm, 0.0, h0 + 1.05, 1.0, 2.1, -0.47, -0.42, 0.0, bois)                       # porte de service
			a.boite_tournee(fm, 0.0, h0 + 2.18, 1.24, 0.18, -0.46, -0.4, 0.0, tl)                         # linteau
			for v in [0.5, 1.6]:
				a.boite_tournee(fm, 0.0, h0 + v, 0.94, 0.05, -0.42, -0.4, 0.0, fer)                     # pentures
		"n":
			var b := h0 + 3.9
			a.boite_tournee(fm, 0.0, b + 0.5, 1.2, 1.0, -prof + 0.0, -prof + 0.55, 0.0, tl)               # socle
			a.boite_tournee(fm, 0.0, b + 1.75, 0.55, 1.5, -prof + 0.1, -prof + 0.45, 0.0, tl)             # figure (bloc)
			a.boite_tournee(fm, 0.0, b + 2.62, 0.36, 0.34, -prof + 0.17, -prof + 0.4, 0.0, tl)            # tête


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
## sc.root depuis l'indice `depuis` : teinte claire -> calcaire, moyenne -> pierre de taille (ou `pierre`, si fournie),
## sombre ou saturée (bois, fer, bannières) -> matière unie de la même couleur (sans quadrillage ni baies peintes) ; le
## jaune de chantier du blockout -> planches de bois. Sert aux éléments de la V0.7-A gardés tels quels.
func remplacer_blockout(depuis: int, pierre: Material = null) -> int:
	var n := 0
	for i in range(depuis, sc.root.get_child_count()):
		n += _remplacer(sc.root.get_child(i), pierre)
	return n


## Même remplacement dans tout un sous-arbre (volumes d'escamotage : les maillages y sont déplacés au classement).
func remplacer_blockout_sous(racine_n: Node, pierre: Material = null) -> int:
	var n := _remplacer(racine_n, pierre)
	for c in racine_n.get_children():
		n += remplacer_blockout_sous(c, pierre)
	return n


func _remplacer(nd: Node, pierre: Material) -> int:
	var mi := nd as MeshInstance3D
	if mi == null or not (mi.material_override is ShaderMaterial):
		return 0
	var sm := mi.material_override as ShaderMaterial
	if sm.shader == null or sm.shader.resource_path.get_file() != "blockout_p7.gdshader":
		return 0
	var c: Color = sm.get_shader_parameter("couleur")
	var lum := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
	var bas: float = (mi.global_transform * mi.get_aabb()).position.y
	if c.s > 0.6 and c.h > 0.08 and c.h < 0.17:
		mi.material_override = a.plein(Color(0.50, 0.37, 0.24), 0.9)          # jaune de chantier -> planches
	elif c.s > 0.25 or lum <= 0.38:
		mi.material_override = a.plein(c, 0.85)
	elif lum > 0.6:
		mi.material_override = calcaire(snappedf(bas, 0.5))
	else:
		mi.material_override = pierre if pierre != null else taille()
	return 1

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


## P8.1-A2 — Types d'immeubles (au lieu d'une seule distribution répétée) : chaque type a SA logique structurelle,
## constante sur tout le bâtiment ; seules les dimensions varient, dans une plage propre au type, selon la graine.
##   ordinaire : RDC de pierre, travées 2,6 à 2,9 m, fenêtres moyennes à volets pleins, soupiraux grillagés au RDC ;
##   aisee     : RDC à bossage, étage noble (1er) aux baies hautes, portes-fenêtres sur un balcon filant au centre de la
##               façade sur rue, étage supérieur plus bas, volets persiennés, corniche à consoles, enduit clair ;
##   commerce  : devantures et vitrines au RDC sur rue (faces libres), étages de maison ordinaire ;
##   service   : peu d'ouvertures (travées 3,4 à 3,8 m), petites fenêtres sans croisée aux volets fermés, soupiraux ;
##   civique, fond : inchangés (Guilde / hôtel de ville ; fonds lointains simplifiés).
const TYPES := {
	"ordinaire": {"pas": [2.6, 2.9], "w": 0.9, "h": 1.35, "rdc": "pierre", "volets": "pleins", "corniche": "simple", "pal": ["ocre", "gris_chaud", "rose", "terre"]},
	"aisee": {"pas": [3.0, 3.2], "w": 1.0, "h": 1.65, "rdc": "bossage", "volets": "persiennes", "corniche": "consoles", "pal": ["creme", "miel"]},
	"commerce": {"pas": [2.7, 3.0], "w": 0.9, "h": 1.35, "rdc": "pierre", "volets": "pleins", "corniche": "simple", "pal": ["miel", "ocre", "rose"]},
	"service": {"pas": [3.4, 3.8], "w": 0.7, "h": 0.95, "rdc": "pierre", "volets": "fermes", "corniche": "simple", "pal": ["gris_chaud", "terre"]},
}


## Types imposés (logique de rue) : RDC commercial à l'entrée de la ville, sur la placette des Voyageurs
## (bat_b_o_placette : seul bâtiment habillé dont TOUTES les devantures donnent de plain-pied sur un sol praticable, sans
## obstacle ; essai systématique avec tools/p8/coherence_facades_p81a2.gd : les autres donnent sur le vide, la caravane,
## les piles du porche, un garde-corps ou l'enceinte du Colisée) ; pas deux maisons aisées accolées sur la terrasse est.
const TYPES_IMPOSES := {"bat_b_o_placette": "commerce", "bat_b_terrasse_e3": "ordinaire"}


## Type d'un bâtiment secondaire d'après sa catégorie (données) et sa taille ; la graine départage seulement.
func type_de(id: String, categorie: String, r: Rect2, h0: float, h1: float) -> String:
	if TYPES_IMPOSES.has(id):
		return TYPES_IMPOSES[id]
	var g := absi(id.hash())
	if categorie in ["guilde", "civique"]:
		return "civique"
	if categorie == "commerce":
		return "commerce"
	if categorie == "residentiel" and ((h1 - h0 >= 7.5 and r.size.x >= 14.0) or g % 3 == 0):
		return "aisee"
	if categorie == "residentiel_b" and g % 4 == 0:
		return "service"
	return "ordinaire"


## Fiche d'un bâtiment : `toit_max` = hauteur de toit admise par le volume d'escamotage (ville_v07b._classer_volumes).
func fiche(id: String, r: Rect2, h0: float, h1: float, genre: String, entrees: Array, toit_max: float) -> Dictionary:
	var g := absi(id.hash())
	if genre == "maison":
		genre = "ordinaire"
	var ty: Dictionary = TYPES.get(genre, TYPES["ordinaire"])
	var nv := [h0]
	var hh := h1 - h0
	var n_et := maxi(0, int(round((hh - NIVEAU_RDC) / NIVEAU_ETAGE)))
	if n_et == 0:
		nv.append(h1)
	else:
		var rdc := minf(NIVEAU_RDC, hh * 0.45)
		nv.append(h0 + rdc)
		# maison aisée : étage noble plus haut que les suivants
		var hauts := []
		for k in n_et:
			hauts.append(1.25 if genre == "aisee" and k == 0 and n_et > 1 else 1.0)
		var somme: float = hauts.reduce(func(x, y): return x + y, 0.0)
		var acc := h0 + rdc
		for k in n_et:
			acc += (hh - rdc) * hauts[k] / somme
			nv.append(acc)
	var noms_pal: Array = ty["pal"] if genre in TYPES else PALETTES_MAISONS
	var pal: Array = Archi.PALETTES[noms_pal[g % noms_pal.size()]]
	var d := {"id": id, "niveaux": nv, "enduit": pal[0], "volets": pal[1], "toit": "2p_x",
		"toit_h": clampf(minf(r.size.x, r.size.y) * 0.32, 1.2, minf(toit_max, 3.6)), "faces": {}, "balcons": [], "lanternes": []}
	if genre in TYPES:
		d["rdc"] = ty["rdc"]
		d["volets_style"] = ty["volets"]
		d["corniche"] = ty["corniche"]
	if genre == "civique":
		d["rdc"] = "bossage"
		d["etages"] = "pierre"
		d["corniche"] = "consoles"
		d["volets_style"] = "aucun"
		d["toit"] = "croupe"
	elif genre == "fond":
		d["chaines"] = false
	var pas_t: Array = ty["pas"] if genre in TYPES else ([3.2, 3.2] if genre == "civique" else [2.7, 2.7])
	var pas: float = lerpf(pas_t[0], pas_t[1], float(g % 7) / 6.0)
	for cote in ["s", "e", "o"]:
		var f := Archi.face(r, cote)
		var L: float = f["L"]
		var par_niveau := []
		var nb := int(floor((L - 1.6) / pas))
		var u0 := (L - (nb - 1) * pas) * 0.5
		for i in nv.size() - 1:
			var bas: float = nv[i]
			var hn: float = nv[i + 1] - bas
			var liste := []
			if nb < 1 or hn < 1.8:
				par_niveau.append(liste)
				continue
			for k in nb:
				var u := u0 + k * pas
				if i == 0 and cote == "s" and _devant_entree(f, u, entrees):
					continue
				liste.append(_baie_type(genre, i, k, nb, cote, u, hn, g, ty))
			par_niveau.append(liste)
		d["faces"][cote] = par_niveau
		# maison aisée : balcon filant sur les deux travées centrales de l'étage noble, côté rue
		if genre == "aisee" and cote == "s" and nb >= 3 and nv.size() > 2:
			var kc := int(nb / 2)
			d["balcons"].append(["s", u0 + (kc - 1) * pas - 0.75, u0 + kc * pas + 0.75, 1, 0.75, "fer"])
	return d


## Baie d'un type d'immeuble : [u, largeur, hauteur, appui, style] au niveau i (0 = RDC) de la travée k sur nb.
func _baie_type(genre: String, i: int, k: int, nb: int, cote: String, u: float, hn: float, g: int, ty: Dictionary) -> Array:
	if genre == "civique":
		if i == 0:
			return [u, 1.0, minf(1.9, hn - 1.2), 0.9, "fenetre_simple"]
		return [u, 1.1, minf(2.0, hn - 0.8), minf(0.55, hn - 2.0 - 0.25), "fenetre_cintree"]
	if genre == "fond":
		if i == 0:
			return [u, 0.8, 0.9, minf(1.2, hn - 1.3), "barreaux"]
		return [u, 0.9, minf(1.45, hn - 0.9), minf(0.55, hn - 1.7), "fenetre_simple"]
	var w: float = ty["w"]
	var h: float = ty["h"]
	if i == 0:
		if genre == "commerce":
			# devantures sur rue (faces libres ; les faces mitoyennes sont omises), une vitrine sur deux travées
			return [u, minf(2.2, ty["pas"][0] - 0.5), 2.3, 0.0, "devanture" if k % 2 == 0 else "vitrine"]
		if genre == "service" or (k + g) % 3 == 0:
			return [u, 0.8, 0.8, minf(1.4, hn - 1.4), "barreaux"]
		return [u, w, minf(h, hn - 1.4), 0.9, "fenetre"]
	if genre == "aisee":
		var noble := i == 1
		var kc := int(nb / 2)
		if noble and cote == "s" and nb >= 3 and (k == kc - 1 or k == kc):
			return [u, 1.0, minf(2.1, hn - 0.5), 0.0, "porte_fenetre"]           # sur le balcon
		var hb := h if noble else h * 0.8
		return [u, w, minf(hb, hn - 0.9), minf(0.5, hn - hb - 0.4), "fenetre"]
	if genre == "service":
		return [u, w, h, minf(0.7, hn - h - 0.4), "fenetre_simple"]
	return [u, w, minf(h, hn - 0.9), minf(0.55, hn - h - 0.4), "fenetre"]


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
	# L4 : une vigne grimpante au pied de la façade sud d'une maison sur trois (angle, jamais devant une entrée)
	if genre == "maison" and a.plantes != null and absi(id.hash()) % 3 == 0 and r.size.x > 6.0:
		var g := absi(id.hash())
		var u := 1.1 if g % 2 == 0 else r.size.x - 1.1
		if not _devant_entree(Archi.face(r, "s"), u, entrees):
			a.plantes.vigne(Vector3(r.position.x + u, h0, r.end.y + 0.06), 0.0, g, 1.15)


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



# ------------------------------------------------------------------------------------------------ L5 : limites
## Barrière de fin de carte (même collision que le blockout : boîte des données, couche OBST) : barrière de planches
## sur chevalets en bois, deux lisses et une planche oblique par travée, dans l'emprise de la collision.
func barriere(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_OBST)
	var d0: int = a.racine.get_child_count()
	var bois: Material = a.plein(Color(0.46, 0.34, 0.22), 0.9)
	var bois_c: Material = a.plein(Color(0.58, 0.45, 0.30), 0.9)
	var long_x := r.size.x >= r.size.y
	var L := r.size.x if long_x else r.size.y
	var c := r.get_center()
	var ax := Vector3(1, 0, 0) if long_x else Vector3(0, 0, 1)
	var n := maxi(1, int(round(L / 1.8)))
	for k in n + 1:
		var p := Vector3(c.x, 0.0, c.y) + ax * (-L * 0.5 + 0.1 + (L - 0.2) * float(k) / n)
		a.box(p + Vector3(0, h0 + (h1 - h0) * 0.5, 0), Vector3(0.12, h1 - h0, 0.12), bois)      # poteau
		a.box(p + Vector3(0, h0 + 0.12, 0), (Vector3(0.12, 0.1, 0.7) if long_x else Vector3(0.7, 0.1, 0.12)), bois)    # pied
	for hh in [0.45, 0.95]:
		var sz := Vector3(L, 0.14, 0.05) if long_x else Vector3(0.05, 0.14, L)
		a.box(Vector3(c.x, h0 + hh, c.y), sz, bois_c)
	a.fusionner(d0, "barriere_" + str(e.get("id", "")))


# ------------------------------------------------------------------------------------------------ P8.1-A2 : plateformes
## Annexes basses en appentis (bat_b_parvis_s, bat_b_parvis_o2 : blocs de 1,2 m entre le bord sud du parvis et les
## immeubles de fond) : la grande dalle claire, lue comme une esplanade interdite, devient les toits d'annexes adossées
## au mur aveugle du fond (égout bas côté parvis, faîtage contre le mur), séparés du parvis par un parapet de pierre.
## Même collision (bloc des données) : on comprend pourquoi on n'y marche pas, et la masse claire quitte le premier plan.
func annexes(e: Dictionary) -> void:
	var r: Rect2 = e["rect"]
	var h0: float = e["h0"]
	var h1: float = e["h1"]
	sc._static_box(sc._rect_center(r, h0, h1), Vector3(r.size.x, h1 - h0, r.size.y), sc.L_OBST)
	if str(sc._cli.get("annexes_a2", "0")) != "1":
		_jardins_a3(r, h0, h1, str(e.get("id", "")))
		return
	var d0: int = a.racine.get_child_count()
	# parapet au bord du parvis (nord) et mur arrière (sud), en pierre
	a.box(Vector3(r.get_center().x, h0 + 0.42, r.position.y + 0.18), Vector3(r.size.x, 0.84, 0.36), soutenement(h0))
	a.box(Vector3(r.get_center().x, h0 + 0.9, r.position.y + 0.18), Vector3(r.size.x + 0.04, 0.12, 0.44), taille())
	a.box(Vector3(r.get_center().x, h0 + (h1 - h0) * 0.5, r.end.y - 0.15), Vector3(r.size.x, h1 - h0, 0.3), soutenement(h0))
	# annexes : sections de 6 à 8 m, faîtage et teinte légèrement variés
	var n := maxi(1, int(round(r.size.x / 7.0)))
	var pt0: String = a.preset_tuiles
	a.preset_tuiles = "tuiles"
	for k in n:
		var x0 := r.position.x + r.size.x * float(k) / n
		var x1 := r.position.x + r.size.x * float(k + 1) / n
		var ha := h0 + 0.3                                  # égout, derrière le parapet
		var hf := h1 - 0.05 - 0.12 * float(k % 2)           # faîtage contre le mur du fond
		var y0 := r.position.y + 0.4
		var y1 := r.end.y - 0.3
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		a._pan(st, Vector3(x0, ha, y0), Vector3(x1, ha, y0), Vector3(x1, hf, y1), Vector3(x0, hf, y1), Vector3(0, y1 - y0, -(hf - ha)).normalized())
		a._commit_tuiles(st, ha, Color(1.32, 1.1, 0.98) * (1.0 - 0.06 * float(k % 3)))
		# séparation entre annexes : petit mur de refend sous le rampant
		if k > 0:
			a.box(Vector3(x0, (h0 + hf) * 0.5, (y0 + y1) * 0.5), Vector3(0.25, hf - h0, y1 - y0), soutenement(h0))
	a.preset_tuiles = pt0
	a.fusionner(d0, "annexes_" + str(e.get("id", "")))


## P8.1-A3 — Jardins en terrasse (remplacent les appentis de P8.1-A2, vus d'en haut comme des plates-formes rouges au premier
## plan du parvis) : potagers surélevés des maisons du fond, bordés côté parvis par le parapet de pierre, adossés au mur
## du fond ; terre à 0,75 m (sous l'arase du parapet), planches séparées par des bordures de pierre de taille, plantations
## BASSES seulement (feuillages, couvre-sol, fleurs : aucun arbuste) pour ne rien cacher du parvis. Même collision (bloc
## des données). --annexes_a2=1 : appentis de P8.1-A2.
func _jardins_a3(r: Rect2, h0: float, h1: float, id: String) -> void:
	var d0: int = a.racine.get_child_count()
	var ht := h0 + 0.75
	a.box(Vector3(r.get_center().x, h0 + 0.42, r.position.y + 0.18), Vector3(r.size.x, 0.84, 0.36), soutenement(h0))
	a.box(Vector3(r.get_center().x, h0 + 0.9, r.position.y + 0.18), Vector3(r.size.x + 0.04, 0.12, 0.44), taille())
	a.box(Vector3(r.get_center().x, h0 + (h1 - h0) * 0.5, r.end.y - 0.15), Vector3(r.size.x, h1 - h0, 0.3), soutenement(h0))
	a.box(Vector3(r.get_center().x, h1 + 0.05, r.end.y - 0.15), Vector3(r.size.x + 0.04, 0.1, 0.38), taille())
	for x in [r.position.x + 0.15, r.end.x - 0.15]:
		a.box(Vector3(x, h0 + 0.45, r.get_center().y), Vector3(0.3, 0.9, r.size.y), soutenement(h0))
	var terre: Material = a.plein(Color(0.30, 0.23, 0.17), 0.98)
	var ri := Rect2(r.position.x + 0.3, r.position.y + 0.36, r.size.x - 0.6, r.size.y - 0.66)
	a.box(Vector3(ri.get_center().x, (h0 + ht) * 0.5, ri.get_center().y), Vector3(ri.size.x, ht - h0, ri.size.y), terre)
	var n := maxi(1, int(round(ri.size.x / 4.5)))
	for k in range(1, n):
		var x := ri.position.x + ri.size.x * float(k) / n
		a.box(Vector3(x, ht + 0.06, ri.get_center().y), Vector3(0.22, 0.14, ri.size.y), taille())
	a.fusionner(d0, "jardins_" + id)
	if a.plantes != null:
		for k in n:
			var x0 := ri.position.x + ri.size.x * float(k) / n + 0.15
			var x1 := ri.position.x + ri.size.x * float(k + 1) / n - 0.15
			a.plantes.garnir(Rect2(x0, ri.position.y + 0.1, x1 - x0, ri.size.y - 0.2), ht, true)


## Quai de marchandises (bat_b_no_place : bande de 0,6 m le long de l'ouest de la grande place, dans le prolongement
## des quais de la halle et de la cour de la forge) : dallé, bordé de pierre de taille, avec quelques caisses, tonneaux
## et sacs entreposés. Pas de marches : la collision ne permet pas d'y monter. Même collision (bloc des données).
func quai(e: Dictionary) -> void:
	socle(e)
	var r: Rect2 = e["rect"]
	var h1: float = e["h1"]
	var fo = b._forge()
	var d0: int = a.racine.get_child_count()
	var x := r.get_center().x
	var y := r.position.y + 1.6
	var choix := [["fp/Crate_Wooden", 0.85], ["fp/Barrel", 0.8], ["fp/Bag", 0.6], ["fp/Crate_Wooden", 0.75], ["fp/Barrel_Apples", 0.8], ["fp/Bag", 0.55]]
	var i := 0
	while y < r.end.y - 1.0:
		var c: Array = choix[i % choix.size()]
		fo._modele(c[0], Vector3(x + (0.6 if i % 2 == 0 else -0.6), h1, y), 0.37 * i, Vector3.ONE * float(c[1]))
		if c[0] == "fp/Crate_Wooden" and i % 4 == 0:
			fo._modele("fp/Crate_Wooden", Vector3(x + 0.6, h1 + 0.62, y + 0.05), 0.6, Vector3.ONE * 0.7)
		y += 3.1 + 0.4 * float(i % 3)
		i += 1
	fo._fusion_gltf(d0, "quai_" + str(e.get("id", "")))
